#!/usr/bin/env Rscript
# 03_mr_pain_cognition.R
# Bidirectional two-sample MR + MVMR: multisite chronic pain (MCP) -> cognitive performance / AD / dementia
# Verified GWAS IDs: docs/gwas_catalog.md  (do NOT edit IDs without re-verifying)
#
# Usage:
#   Rscript analysis/03_mr_pain_cognition.R --metadata-only   # prints gwasinfo for all IDs
#   Rscript analysis/03_mr_pain_cognition.R                  # full MR (needs JWT + MCP file)
#
# Requires OpenGWAS JWT (since 2026): Sys.setenv(OPENGWAS_JWT = "...")

suppressPackageStartupMessages({
  library(TwoSampleMR)
  library(ieugwasr)
  library(MRPRESSO)
  library(dplyr)
  library(ggplot2)
})

ROOT    <- tryCatch(here::here(), error = function(e) getwd())
DERIVED <- file.path(ROOT, "data", "derived")
dir.create(DERIVED, recursive = TRUE, showWarnings = FALSE)
STAMP   <- format(Sys.Date(), "%Y%m%d")
ARGS    <- commandArgs(trailingOnly = TRUE)

# ---- Verified IDs (source: docs/gwas_catalog.md, cross-checked 2026-09-20) ----
# Column-mapping for the LOCAL Glasgow MCP file (header confirmed 2026-09-20):
#   SNP CHR BP GENPOS ALLELE1 ALLELE0 A1FREQ INFO CHISQ_LINREG P_LINREG BETA SE ...
ID_COG     <- "ebi-a-GCST006572"                 # cognitive performance (Lee/COGENT 2018, N=257,841)
ID_AD      <- c("ieu-a-298", "finn-b-F5_DEMENTIA")# AD (IGAP 2013) + all-cause dementia (FinnGen R5)
ID_PAIN_UKB<- c("ukb-b-8463","ukb-b-8906","ukb-b-13092","ukb-b-16118","ukb-b-133") # sensitivity pain phenotypes
ID_MVMR    <- c("ieu-a-755" = "education",        # years of schooling (SSGAC)
               "ieu-b-4877" = "smoking",          # smoking initiation
               "ukb-b-19953"= "bmi")              # BMI (Elsworth 2018, N=461,460; upgraded from ieu-a-2)
ID_CRP     <- "ebi-a-GCST90029070"               # CRP (Said 2022, N=575,531) -- mediator
MCP_FILE   <- file.path(ROOT, "data", "raw", "chronic_pain-bgen.stats.gz")   # Johnston 2019 (local, NOT OpenGWAS)
CWP_FILE   <- file.path(ROOT, "data", "raw", "cwp_rahman2021.stats.gz")      # Rahman 2021 (local, NOT OpenGWAS; get from KP4CD)

# ---- metadata-only mode ----
if ("--metadata-only" %in% ARGS) {
  ids <- c(ID_COG, ID_AD, ID_PAIN_UKB, "ieu-b-102", ID_CRP, "ukb-b-3957",
           "ukb-b-4424", "ieu-a-1088", names(ID_MVMR), "ebi-a-GCST006250", "ieu-a-16")
  meta <- gwasinfo(ids)
  outf <- file.path(DERIVED, paste0("mr_gwas_metadata_", STAMP, ".csv"))
  write.csv(meta, outf, row.names = FALSE)
  cat("Wrote metadata for", nrow(meta), "datasets ->", outf, "\n")
  cat("Verify ncase/ncontrol/sample_size/nsnp match gwas_catalog.md before proceeding.\n")
  quit(save = "no")
}

# ---- JWT gate ----
if (Sys.getenv("OPENGWAS_JWT") == "") {
  stop("OPENGWAS_JWT not set. Generate at https://api.opengwas.io/profile/ then Sys.setenv(OPENGWAS_JWT=...). See README.md (JWT section).")
}
# OpenGWAS v4 API root (2026): data API moved to api.opengwas.io/api. The legacy
# gwas-api.mrcieu.ac.uk host is deprecated/blocked in some networks. Ensure your
# ieugwasr is v4-aware; if gwasinfo()/extract_* return 404, your package is still
# on the old host. Host-independent fallback for metadata:
#   python3 analysis/fetch_gwas_metadata.py   (validated 2026-09-20)
options(ieugwasr.api_root = "https://api.opengwas.io/api")

# ---- MCP exposure (local Glasgow file; NOT in OpenGWAS) ----
# Header confirmed 2026-09-20: SNP CHR BP GENPOS ALLELE1 ALLELE0 A1FREQ INFO CHISQ_LINREG P_LINREG BETA SE ...
if (!file.exists(MCP_FILE)) {
  stop("MCP summary stats missing. Download from https://researchdata.gla.ac.uk/822/1/chronic_pain-bgen.stats.gz into data/raw/.")
}
exp_mcp <- read_exposure_data(
  filename = MCP_FILE, sep = "\t",
  snp_col = "SNP", beta_col = "BETA", se_col = "SE",
  effect_allele_col = "ALLELE1", other_allele_col = "ALLELE0",
  pval_col = "P_LINREG", chr_col = "CHR", pos_col = "BP",
  phenotype_col = "MCP", clump = FALSE)
exp_mcp <- clump_data(exp_mcp, clump_r2 = 0.001, clump_kb = 10000)
message("MCP instruments after clumping: ", nrow(exp_mcp))

# ---- CWP exposure (local Rahman 2021 file; NOT in OpenGWAS; optional sensitivity) ----
exp_cwp <- NULL
if (file.exists(CWP_FILE)) {
  exp_cwp <- read_exposure_data(
    filename = CWP_FILE, sep = "\t",
    snp_col = "SNP", beta_col = "BETA", se_col = "SE",
    effect_allele_col = "ALLELE1", other_allele_col = "ALLELE0",
    pval_col = "P_LINREG", chr_col = "CHR", pos_col = "BP",
    phenotype_col = "CWP", clump = FALSE) |>
    clump_data(r2 = 0.001, kb = 10000)
  message("CWP instruments after clumping: ", nrow(exp_cwp))
} else {
  message("CWP file not present (optional sensitivity). Get full stats from KP4CD Rahman2021_Chronic_Widespead_MSK_Pain_EU.")
}

#' Run one exposure->outcome MR with full sensitivity suite
run_mr_pair <- function(exp_dat, outcome_id, label) {
  out_dat <- extract_outcome_data(snps = exp_dat$SNP, outcomes = outcome_id)
  har <- harmonise_data(exp_dat, out_dat)
  if (nrow(har) < 3) { warning("Too few harmonised SNPs for ", label); return(NULL) }
  res <- mr(har, method_list = c("mr_ivw","mr_egger","mr_weighted_median","mr_weighted_mode"))
  hetero <- mr_heterogeneity(har)
  pleio  <- mr_pleiotropy_test(har)
  steiger<- directionality_test(har)
  loo    <- mr_leaveoneout(har)
  # MR-PRESSO (requires >= 3 SNPs)
  presso <- tryCatch(
    MRPRESSO::mr_presso(BetaOutcome = "beta.outcome", BetaExposure = "beta.exposure",
                        SdOutcome = "se.outcome", SdExposure = "se.exposure",
                        OUTLIERtest = TRUE, DISTORTIONtest = TRUE, data = har,
                        NbDistribution = 1000, seed = 12345),
    error = function(e) NULL)
  # plots
  p_scatter <- mr_scatter_plot(res, har)[[1]] + ggtitle(paste("Scatter:", label))
  p_funnel  <- mr_funnel_plot(har) + ggtitle(paste("Funnel:", label))
  p_forest  <- mr_forest_plot(res) + ggtitle(paste("Forest:", label))
  p_loo     <- mr_leaveoneout_plot(loo) + ggtitle(paste("LOO:", label))
  list(result = res, heterogeneity = hetero, pleiotropy = pleio,
       steiger = steiger, leaveoneout = loo, presso = presso,
       plots = list(scatter = p_scatter, funnel = p_funnel, forest = p_forest, loo = p_loo))
}

# ---- Forward MR: MCP -> cognition / AD ----
forward <- list()
forward[[paste0("MCP->", ID_COG)]] <-
  run_mr_pair(exp_mcp, ID_COG, "MCP -> cognitive performance")
for (oid in ID_AD) {
  forward[[paste0("MCP->", oid)]] <-
    run_mr_pair(exp_mcp, oid, paste0("MCP -> ", oid))
}

# ---- Reverse MR: cognitive performance -> MCP (uses OpenGWAS cog as exposure) ----
exp_cog <- extract_instruments(ID_COG, p1 = 5e-8, clump = TRUE, r2 = 0.001, kb = 10000)
reverse <- run_mr_pair(exp_cog, "LOCAL_MCP", "cognitive performance -> MCP (manual)")
# (outcome = MCP read locally; harmonise step below handles local outcome)
out_mcp <- read_outcome_data(MCP_FILE, sep = "\t", snp_col = "SNP", beta_col = "BETA",
                             se_col = "SE", effect_allele_col = "ALLELE1", other_allele_col = "ALLELE0",
                             pval_col = "P_LINREG", chr_col = "CHR", pos_col = "BP")
har_rev <- harmonise_data(exp_cog, out_mcp)
res_rev <- mr(har_rev, method_list = c("mr_ivw","mr_egger","mr_weighted_median","mr_weighted_mode"))

# ---- MVMR: MCP (proxied by pain phenotypes) adjusted for education/smoking/BMI ----
# Note: MCP is local; for MVMR use OpenGWAS pain phenotypes as exposure proxies.
mvmr_res <- list()
for (pid in ID_PAIN_UKB) {
  exp_p <- extract_instruments(pid, p1 = 5e-8, clump = TRUE, r2 = 0.001, kb = 10000)
  mv <- mv_multiple(gene = c(pid, names(ID_MVMR)),
                    outcomes = ID_COG, proxies = FALSE)
  mvmr_res[[pid]] <- mv
}

# ---- Save everything ----
saveRDS(list(forward = forward, reverse = res_rev, mvmr = mvmr_res),
        file.path(DERIVED, paste0("mr_results_", STAMP, ".rds")))
message("MR results saved -> data/derived/mr_results_", STAMP, ".rds")

# ---- Session info for reproducibility ----
sink(file.path(DERIVED, paste0("sessionInfo_mr_", STAMP, ".txt")))
print(sessionInfo())
sink()

cat("DONE. Check forward/reverse/MVMR objects; generate Fig 4 (four-panel) from $plots.\n")
