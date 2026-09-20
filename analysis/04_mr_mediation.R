#!/usr/bin/env Rscript
# 04_mr_mediation.R
# Two-step Mendelian randomization mediation:
#   pain (MCP) -> mediator (depression / CRP / insomnia) -> cognitive performance
# Indirect effect = beta_exposure->mediator * beta_mediator->outcome (delta method CI)
# All mediation results labelled "suggestive" only (no causal claim).
#
# Requires OPENGWAS_JWT. Verified IDs: docs/gwas_catalog.md

suppressPackageStartupMessages({
  library(TwoSampleMR)
  library(ieugwasr)
  library(dplyr)
})

ROOT    <- tryCatch(here::here(), error = function(e) getwd())
DERIVED <- file.path(ROOT, "data", "derived")
dir.create(DERIVED, recursive = TRUE, showWarnings = FALSE)
STAMP   <- format(Sys.Date(), "%Y%m%d")

EXP <- "ebi-a-GCST006572"   # cognitive performance (OUTCOME of mediation)
MEDIA <- list(
  depression = "ieu-b-102",              # Howard 2019 PGC MDD
  crp       = "ebi-a-GCST90029070",      # Said 2022 CRP (N=575,531); verified 2026-09-20
  insomnia  = "ukb-b-3957"               # Sleeplessness/insomnia
)
# MCP exposure is local (Glasgow). For mediation we need MCP as exposure in both steps:
MCP_FILE <- file.path(ROOT, "data", "raw", "chronic_pain-bgen.stats.gz")

if (Sys.getenv("OPENGWAS_JWT") == "") stop("Set OPENGWAS_JWT first (see README.md JWT section).")
options(ieugwasr.api_root = "https://gwas-api.mrcieu.ac.uk/")

ivw_pair <- function(exp_dat, out_id) {
  out <- extract_outcome_data(exp_dat$SNP, out_id)
  har <- harmonise_data(exp_dat, out)
  mr(har, method_list = "mr_ivw")
}

# Step 1: MCP -> mediator
# Header confirmed 2026-09-20: SNP CHR BP GENPOS ALLELE1 ALLELE0 ... BETA SE ... P_LINREG
exp_mcp <- read_exposure_data(MCP_FILE, sep = "\t", snp_col = "SNP", beta_col = "BETA",
                              se_col = "SE", effect_allele_col = "ALLELE1", other_allele_col = "ALLELE0",
                              pval_col = "P_LINREG", chr_col = "CHR", pos_col = "BP",
                              phenotype_col = "MCP", clump = FALSE) |>
  clump_data(r2 = 0.001, kb = 10000)

step1 <- list()
for (m in names(MEDIA)) {
  step1[[m]] <- ivw_pair(exp_mcp, MEDIA[[m]])
}

# Step 2: mediator -> cognitive performance
exp_med <- list()
step2   <- list()
for (m in names(MEDIA)) {
  exp_med[[m]] <- extract_instruments(MEDIA[[m]], p1 = 5e-8, clump = TRUE, r2 = 0.001, kb = 10000)
  step2[[m]] <- ivw_pair(exp_med[[m]], EXP)
}

# Delta-method indirect effect (placeholder; fill b1/se1/b2/se2 from step1/step2)
message("Two-step mediation framework ready. Fill indirect-effect delta CI after step1/step2 run.")
saveRDS(list(step1 = step1, step2 = step2),
        file.path(DERIVED, paste0("mr_mediation_", STAMP, ".rds")))
cat("Saved -> data/derived/mr_mediation_", STAMP, ".rds\n")
