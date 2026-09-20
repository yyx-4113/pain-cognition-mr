#!/usr/bin/env Rscript
# 03_mr_ieugwasr.R
# Bidirectional two-sample MR: multisite chronic pain (MCP, local Johnston 2019) -> cognition / AD / dementia,
# plus reverse MR (cognition -> MCP).
#
# NOTE: TwoSampleMR is NOT installable in this environment (its current CRAN version requires R > 4.6.0,
# and no Rtools is present for source build). We therefore implement the MR pipeline with `ieugwasr`
# (installed) + base R, which is fully transparent and reproducible. Clumping and outcome extraction use
# the OpenGWAS v4 API (requires the user JWT). The MCP exposure is read locally (Johnston 2019, DOI
# 10.5525/gla.researchdata.822). All estimators are implemented explicitly and documented.
#
# Estimators: IVW (fixed + multiplicative random effects), MR-Egger (slope + intercept pleiotropy test),
# Weighted Median, Cochran Q (heterogeneity), Steiger directionality, leave-one-out (LOO).
#
# Usage: Rscript analysis/03_mr_ieugwasr.R

suppressMessages({
  library(data.table)
  library(ieugwasr)
})

ROOT <- getwd()
jwt_path <- file.path(ROOT, "JWT.txt"); if (!file.exists(jwt_path)) jwt_path <- file.path(ROOT, "..", "JWT.txt")
if (!file.exists(jwt_path)) stop("JWT.txt not found. Place it at project root or pain-cognition-mr/.")
Sys.setenv(OPENGWAS_JWT = trimws(readLines(jwt_path, n = 1)[1])
)
options(ieugwasr.api_root = "https://api.opengwas.io/api")

MCP_FILE  <- "data/raw/chronic_pain-bgen.stats.gz"
SIG_CACHE <- "data/derived/_mcp_sig.rds"
CL_CACHE  <- "data/derived/_mcp_clumped.rds"
DER       <- "data/derived"; dir.create(DER, recursive = TRUE, showWarnings = FALSE)

## ---- Outcome definitions (verified IDs, see docs/gwas_catalog.md) ----
OUTCOMES <- list(
  cog           = list(id = "ebi-a-GCST006572", label = "Cognitive performance (COGENT/UKB)", N = 257841),
  ad            = list(id = "ieu-a-298",        label = "Alzheimer's disease (IGAP)",          N = 74466),
  dementia      = list(id = "finn-b-F5_DEMENTIA", label = "All-cause dementia (FinnGen R5)",   N = 216771)
)
EXP_N <- 387649   # MCP Johnston 2019

## ---- helpers ----------------------------------------------------------------
get_assoc <- function(variants, id, align = 0, tries = 3) {
  for (i in seq_len(tries)) {
    a <- tryCatch(associations(variants, id, align_alleles = align, proxies = 0),
                  error = function(e) NULL)
    if (!is.null(a) && nrow(a) > 0) return(a)
    Sys.sleep(2)
  }
  NULL
}

norm_cols <- function(df, role) {
  # standardize column names to: snp, ea, oa, beta, se, p
  nm <- tolower(names(df))
  pick <- function(opts) {
    for (o in opts) { j <- which(nm == o)[1]; if (!is.na(j)) return(names(df)[j]) }
    NA_character_
  }
  snp <- pick(c("variant","rsid","snp","id"))
  ea  <- pick(c("ea","effect_allele","effectallele"))
  oa  <- pick(c("oa","nea","other_allele","non_effect_allele","otheraillele"))
  beta<- pick(c("beta","b"))
  se  <- pick(c("se","stderr","standard_error"))
  p   <- pick(c("p","pval","p_value"))
  list(snp = snp, ea = ea, oa = oa, beta = beta, se = se, p = p)
}

harmonize <- function(exp, out) {
  # exp: data.table with rsid, a1 (effect), a0 (other), beta, se, p
  # out: associations result (raw, align_alleles=0)
  c <- norm_cols(out)
  if (any(is.na(unlist(c)))) stop("Outcome columns not recognized: ", paste(names(c), unlist(c), collapse = "; "))
  o <- data.table(
    rsid = out[[c$snp]],
    oa_eff = out[[c$ea]], oa_oth = out[[c$oa]],
    beta_out = as.numeric(out[[c$beta]]), se_out = as.numeric(out[[c$se]]),
    p_out = as.numeric(out[[c$p]])
  )
  m <- merge(exp, o, by = "rsid", all = FALSE)
  keep <- m[!is.na(beta_out) & !is.na(se_out) & se_out > 0 & !is.na(beta) & !is.na(se) & se > 0]
  # align outcome to exposure effect allele (a1)
  flip <- function(dt) {
    s <- rep(0, nrow(dt))
    # same orientation
    s[dt$a1 == dt$oa_eff & dt$a0 == dt$oa_oth] <- 0
    # flipped
    s[dt$a1 == dt$oa_oth & dt$a0 == dt$oa_eff] <- 1
    dt$beta_out_adj <- ifelse(s == 1, -dt$beta_out, dt$beta_out)
    dt$orientation <- ifelse(s == 1, "flipped", "same")
    dt
  }
  keep <- flip(keep)
  keep
}

## ---- MR estimators ----------------------------------------------------------
ivw <- function(bx, by, sey, re = TRUE) {
  w <- 1 / sey^2
  b <- sum(w * bx * by) / sum(w * bx^2)
  se_fix <- sqrt(1 / sum(w * bx^2))
  Q <- sum(w * (by - b * bx)^2); df <- length(bx) - 1
  pQ <- if (df > 0) pchisq(Q, df, lower.tail = FALSE) else NA
  se_re <- if (re && Q > df && df > 0) se_fix * sqrt(Q / df) else se_fix
  list(b_ivw = b, se_fixed = se_fix, se_re = se_re, Q = Q, df = df, pQ = pQ)
}
mregger <- function(bx, by, sey) {
  w <- 1 / sey^2
  fit <- lm(by ~ bx, weights = w)
  cf <- coef(fit); vc <- sqrt(diag(vcov(fit)))
  list(slope = cf[2], se_slope = vc[2], intercept = cf[1], se_int = vc[1],
       p_int = 2 * pnorm(abs(cf[1] / vc[1]), lower.tail = FALSE))
}
wmedian <- function(bx, by, sey) {
  w <- 1 / sey^2; wt <- w * bx^2
  ord <- order(wt, decreasing = TRUE)
  cum <- cumsum(wt[ord]) / sum(wt)
  idx <- which(cum >= 0.5)[1]
  bmed <- (by / bx)[ord][idx]   # weighted median of per-SNP Wald ratios
  semed <- sqrt(1 / sum(w[ord][1:idx] * bx[ord][1:idx]^2))
  list(b_med = bmed, se_med = semed)
}
steiger <- function(bx, by, sex, sey, n_exp, n_out) {
  r_x <- bx / sqrt(bx^2 + (sex * sqrt(n_exp))^2)
  r_y <- by / sqrt(by^2 + (sey * sqrt(n_out))^2)
  Vx <- sum(r_x^2); Vy <- sum(r_y^2)
  # z-test on difference (approx)
  se_diff <- sqrt(2 * (length(bx) - 1) / length(bx) * (1 - cor(bx, by)^2)^2 / min(n_exp, n_out))
  z <- (Vy - Vx) / se_diff
  p <- 2 * pnorm(abs(z), lower.tail = FALSE)
  list(V_exp = Vx, V_out = Vy, direction_supported = if (Vx > Vy) "X->Y" else "Y->X (reverse?)", p = p)
}
loo <- function(bx, by, sey) {
  n <- length(bx); bs <- numeric(n); ses <- numeric(n)
  for (i in seq_len(n)) {
    ii <- setdiff(seq_len(n), i)
    r <- ivw(bx[ii], by[ii], sey[ii], re = FALSE)
    bs[i] <- r$b_ivw; ses[i] <- r$se_fixed
  }
  list(beta = bs, se = ses,
       beta_min = min(bs), beta_max = max(bs),
       n_sig = sum(abs(bs / ses) > 1.96))
}

## ---- load / clump exposure --------------------------------------------------
if (!file.exists(SIG_CACHE)) {
  cat("Reading MCP (full)...\n")
  dt <- fread(MCP_FILE, sep = "\t", select = c("SNP","CHR","BP","ALLELE1","ALLELE0","P_LINREG","BETA","SE"))
  sig <- dt[P_LINREG < 5e-8]
  sig <- sig[, .(rsid = SNP, chr = CHR, bp = BP, a1 = ALLELE1, a0 = ALLELE0, pval = P_LINREG, beta = BETA, se = SE)]
  saveRDS(sig, SIG_CACHE)
  cat("  cached", nrow(sig), "significant SNPs\n")
} else {
  sig <- readRDS(SIG_CACHE)
  cat("Loaded cached significant SNPs:", nrow(sig), "\n")
}

if (!file.exists(CL_CACHE)) {
  cat("Clumping MCP instruments (EUR)...\n")
  cl <- ld_clump(sig[, .(rsid, pval)], pop = "EUR")
  saveRDS(cl, CL_CACHE)
  cat("  clumped to", nrow(cl), "loci SNPs\n")
} else {
  cl <- readRDS(CL_CACHE)
  cat("Loaded cached clumped SNPs:", nrow(cl), "\n")
}
exp_dat <- sig[rsid %in% cl$rsid]
cat("Exposure instruments for MR:", nrow(exp_dat), "\n")

## ---- forward MR over outcomes ----------------------------------------------
results <- list()
harmonized_list <- list()
for (nm in names(OUTCOMES)) {
  cat("\n=== Forward: MCP ->", OUTCOMES[[nm]]$label, "===\n")
  out <- get_assoc(cl$rsid, OUTCOMES[[nm]]$id)
  if (is.null(out)) { cat("  ! no outcome data, skip\n"); next }
  h <- tryCatch(harmonize(exp_dat, out), error = function(e){ cat("  harmonize err:", conditionMessage(e), "\n"); NULL })
  if (is.null(h) || nrow(h) == 0) { cat("  ! 0 harmonized SNPs, skip\n"); next }
  harmonized_list[[nm]] <- h
  cat("  harmonized SNPs:", nrow(h), "\n")
  bx <- h$beta; by <- h$beta_out_adj; sex <- h$se; sey <- h$se_out
  iv <- ivw(bx, by, sey)
  eg <- mregger(bx, by, sey)
  wm <- wmedian(bx, by, sey)
  st <- steiger(bx, by, sex, sey, EXP_N, OUTCOMES[[nm]]$N)
  lo <- loo(bx, by, sey)
  results[[nm]] <- data.frame(
    outcome = nm,
    n_snps = nrow(h),
    IVW_beta = iv$b_ivw, IVW_se_fixed = iv$se_fixed, IVW_se_RE = iv$se_re,
    IVW_p_fixed = 2 * pnorm(-abs(iv$b_ivw / iv$se_fixed)),
    IVW_p_RE = 2 * pnorm(-abs(iv$b_ivw / iv$se_re)),
    Egger_beta = eg$slope, Egger_se = eg$se_slope, Egger_p = 2 * pnorm(-abs(eg$slope / eg$se_slope)),
    Egger_int = eg$intercept, Egger_int_p = eg$p_int,
    WMed_beta = wm$b_med, WMed_se = wm$se_med,
    Cochran_Q = iv$Q, Cochran_df = iv$df, Cochran_p = iv$pQ,
    Steiger_Vexp = st$V_exp, Steiger_Vout = st$V_out, Steiger_dir = st$direction_supported, Steiger_p = st$p,
    LOO_beta_min = lo$beta_min, LOO_beta_max = lo$beta_max,
    stringsAsFactors = FALSE
  )
  print(results[[nm]])
}

## ---- reverse MR: cognition -> MCP -------------------------------------------
cat("\n=== Reverse: Cognitive performance -> MCP ===\n")
res_rev <- tryCatch({
  cog_inst <- as.data.table(tophits("ebi-a-GCST006572", pval = 5e-8))
  cnm <- tolower(names(cog_inst))
  rs_col <- c("variant","rsid","snp")[which(c("variant","rsid","snp") %in% cnm)[1]]
  pv_col <- c("pval","p","pval.exposure")[which(c("pval","p","pval.exposure") %in% cnm)[1]]
  cog_cl <- ld_clump(cog_inst[, .(rsid = cog_inst[[rs_col]], pval = as.numeric(cog_inst[[pv_col]]))], pop = "EUR")
  cat("  cognitive instruments (clumped):", nrow(cog_cl), "\n")
  cog_exp0 <- get_assoc(cog_cl$rsid, "ebi-a-GCST006572", align = 0)
  cc <- norm_cols(cog_exp0)
  cog_exp <- data.table(rsid = cog_exp0[[cc$snp]], a1 = cog_exp0[[cc$ea]], a0 = cog_exp0[[cc$oa]],
                        beta = as.numeric(cog_exp0[[cc$beta]]), se = as.numeric(cog_exp0[[cc$se]]))
  cat("  reading MCP for cognitive instruments (one-time)...\n")
  mc <- fread(MCP_FILE, sep = "\t", select = c("SNP","ALLELE1","ALLELE0","P_LINREG","BETA","SE"))
  mc <- mc[SNP %in% cog_cl$rsid]
  mh <- data.table(rsid = mc$SNP, oa_eff = mc$ALLELE1, oa_oth = mc$ALLELE0,
                   beta_out = as.numeric(mc$BETA), se_out = as.numeric(mc$SE))
  mh <- merge(cog_exp, mh, by = "rsid")
  mh <- mh[(mh$a1 == mh$oa_eff & mh$a0 == mh$oa_oth) | (mh$a1 == mh$oa_oth & mh$a0 == mh$oa_eff)]
  mh$beta_out_adj <- ifelse(mh$a1 == mh$oa_oth, -mh$beta_out, mh$beta_out)
  cat("  reverse harmonized SNPs:", nrow(mh), "\n")
  if (nrow(mh) >= 3) {
    iv <- ivw(mh$beta, mh$beta_out_adj, mh$se_out)
    eg <- mregger(mh$beta, mh$beta_out_adj, mh$se_out)
    wm <- wmedian(mh$beta, mh$beta_out_adj, mh$se_out)
    st <- steiger(mh$beta, mh$beta_out_adj, mh$se, mh$se_out, OUTCOMES$cog$N, EXP_N)
    data.frame(
      outcome = "reverse_cog_pain", n_snps = nrow(mh),
      IVW_beta = iv$b_ivw, IVW_se_fixed = iv$se_fixed, IVW_se_RE = iv$se_re,
      IVW_p_fixed = 2 * pnorm(-abs(iv$b_ivw / iv$se_fixed)),
      IVW_p_RE = 2 * pnorm(-abs(iv$b_ivw / iv$se_re)),
      Egger_beta = eg$slope, Egger_se = eg$se_slope, Egger_p = 2 * pnorm(-abs(eg$slope / eg$se_slope)),
      Egger_int = eg$intercept, Egger_int_p = eg$p_int,
      WMed_beta = wm$b_med, WMed_se = wm$se_med,
      Cochran_Q = iv$Q, Cochran_df = iv$df, Cochran_p = iv$pQ,
      Steiger_Vexp = st$V_exp, Steiger_Vout = st$V_out, Steiger_dir = st$direction_supported, Steiger_p = st$p,
      stringsAsFactors = FALSE)
  } else NULL
}, error = function(e) { cat("  reverse MR error:", conditionMessage(e), "\n"); NULL })
if (!is.null(res_rev)) { results[["reverse_cog_pain"]] <- res_rev; print(res_rev) }

## ---- save -------------------------------------------------------------------
res_df <- do.call(rbind, results)
fwrite(res_df, file.path(DER, "mr_bidirectional_results.csv"))
for (nm in names(harmonized_list)) fwrite(harmonized_list[[nm]], file.path(DER, paste0("mr_harmonized_", nm, ".csv")))
cat("\nWrote data/derived/mr_bidirectional_results.csv (", nrow(res_df), " outcome rows )\n")
cat("DONE\n")
