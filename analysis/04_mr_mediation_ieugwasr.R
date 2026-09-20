#!/usr/bin/env Rscript
# 04_mr_mediation_ieugwasr.R
# Two-step MR mediation: MCP (multisite chronic pain) -> mediator -> cognitive performance.
# Mediators: depression (ieu-b-102), CRP (ebi-a-GCST90029070), insomnia (ukb-b-3957).
# Outcome: cognitive performance (ebi-a-GCST006572).
# Implemented with ieugwasr + base R (TwoSampleMR unavailable in this environment).
# All mediation results are labelled SUGGESTIVE (no causal claim), per SAP.
#
# Usage: Rscript analysis/04_mr_mediation_ieugwasr.R

suppressMessages({
  library(data.table)
  library(ieugwasr)
})
ROOT <- getwd()
jwt_path <- file.path(ROOT, "JWT.txt"); if (!file.exists(jwt_path)) jwt_path <- file.path(ROOT, "..", "JWT.txt")
if (!file.exists(jwt_path)) stop("JWT.txt not found.")
Sys.setenv(OPENGWAS_JWT = trimws(readLines(jwt_path, n = 1)[1])
)
options(ieugwasr.api_root = "https://api.opengwas.io/api")

MCP_FILE  <- "data/raw/chronic_pain-bgen.stats.gz"
SIG_CACHE <- "data/derived/_mcp_sig.rds"
CL_CACHE  <- "data/derived/_mcp_clumped.rds"
DER <- "data/derived"; dir.create(DER, recursive = TRUE, showWarnings = FALSE)

OUTCOME_ID <- "ebi-a-GCST006572"; OUTCOME_N <- 257841
MEDIATORS <- list(
  depression = list(id = "ieu-b-102",          N = 500199, label = "Major depression (PGC 2019)"),
  crp        = list(id = "ebi-a-GCST90029070", N = 575531, label = "C-reactive protein (Said 2022)"),
  insomnia   = list(id = "ukb-b-3957",         N = 462341, label = "Insomnia (Elsworth 2018)")
)

get_assoc <- function(variants, id, align = 0, tries = 3) {
  for (i in seq_len(tries)) {
    a <- tryCatch(associations(variants, id, align_alleles = align, proxies = 0), error = function(e) NULL)
    if (!is.null(a) && nrow(a) > 0) return(a)
    Sys.sleep(2)
  }
  NULL
}
norm_cols <- function(df) {
  nm <- tolower(names(df))
  pick <- function(opts) { for (o in opts) { j <- which(nm == o)[1]; if (!is.na(j)) return(names(df)[j]) }; NA_character_ }
  list(snp = pick(c("variant","rsid","snp","id")), ea = pick(c("ea","effect_allele")),
       oa = pick(c("oa","nea","other_allele","non_effect_allele")), beta = pick(c("beta","b")),
       se = pick(c("se","stderr","standard_error")), p = pick(c("p","pval","p_value")))
}
ivw <- function(bx, by, sey, re = TRUE) {
  w <- 1 / sey^2
  b <- sum(w * bx * by) / sum(w * bx^2)
  se_fix <- sqrt(1 / sum(w * bx^2))
  Q <- sum(w * (by - b * bx)^2); df <- length(bx) - 1
  pQ <- if (df > 0) pchisq(Q, df, lower.tail = FALSE) else NA
  se_re <- if (re && Q > df && df > 0) se_fix * sqrt(Q / df) else se_fix
  list(b = b, se_fix = se_fix, se_re = se_re, Q = Q, pQ = pQ, df = df)
}
mregger <- function(bx, by, sey) {
  w <- 1 / sey^2; fit <- lm(by ~ bx, weights = w)
  cf <- coef(fit); vc <- sqrt(diag(vcov(fit)))
  list(slope = cf[2], se_slope = vc[2], intercept = cf[1], se_int = vc[1],
       p_int = 2 * pnorm(abs(cf[1] / vc[1]), lower.tail = FALSE))
}
harmonize <- function(exp, out) {
  c <- norm_cols(out)
  o <- data.table(rsid = out[[c$snp]], oa_eff = out[[c$ea]], oa_oth = out[[c$oa]],
                  beta_out = as.numeric(out[[c$beta]]), se_out = as.numeric(out[[c$se]]))
  m <- merge(exp, o, by = "rsid")
  m <- m[!is.na(beta_out) & !is.na(se_out) & se_out > 0 & !is.na(beta) & !is.na(se) & se > 0]
  s <- rep(0, nrow(m))
  s[m$a1 == m$oa_eff & m$a0 == m$oa_oth] <- 0
  s[m$a1 == m$oa_oth & m$a0 == m$oa_eff] <- 1
  m$beta_out_adj <- ifelse(s == 1, -m$beta_out, m$beta_out)
  m
}

## ---- load clumped MCP exposure ----------------------------------------------
if (!file.exists(CL_CACHE)) stop("Run 03 first to produce clumped MCP instruments.")
cl <- readRDS(CL_CACHE)
sig <- readRDS(SIG_CACHE)
exp_dat <- sig[rsid %in% cl$rsid]
cat("MCP instruments:", nrow(exp_dat), "\n")

rows <- list()
for (md in names(MEDIATORS)) {
  cat("\n=== Mediator:", MEDIATORS[[md]]$label, "===\n")
  mid <- MEDIATORS[[md]]$id; mN <- MEDIATORS[[md]]$N
  ## STEP 1: MCP -> mediator
  a1 <- get_assoc(cl$rsid, mid)
  if (is.null(a1)) { cat("  ! step1 no data\n"); next }
  h1 <- tryCatch(harmonize(exp_dat, a1), error = function(e){ cat("  harm1 err:", conditionMessage(e), "\n"); NULL })
  if (is.null(h1) || nrow(h1) == 0) { cat("  ! step1 0 SNPs\n"); next }
  iv1 <- ivw(h1$beta, h1$beta_out_adj, h1$se_out)
  eg1 <- mregger(h1$beta, h1$beta_out_adj, h1$se_out)
  cat("  step1 (MCP->mediator): b=", round(iv1$b,4), " se=", round(iv1$se_re,4), " Egger_int_p=", round(eg1$p_int,3), " n=", nrow(h1), "\n")

  ## STEP 2: mediator -> cognition
  inst <- as.data.table(tophits(mid, pval = 5e-8))
  cnm <- tolower(names(inst))
  rs_col <- c("variant","rsid","snp")[which(c("variant","rsid","snp") %in% cnm)[1]]
  pv_col <- c("pval","p","pval.exposure")[which(c("pval","p","pval.exposure") %in% cnm)[1]]
  mcl <- ld_clump(inst[, .(rsid = inst[[rs_col]], pval = as.numeric(inst[[pv_col]]))], pop = "EUR")
  a_exp <- get_assoc(mcl$rsid, mid, align = 0)        # mediator as exposure
  a_out <- get_assoc(mcl$rsid, OUTCOME_ID, align = 0) # cognition as outcome
  if (is.null(a_exp) || is.null(a_out)) { cat("  ! step2 no data\n"); next }
  ce <- norm_cols(a_exp); co <- norm_cols(a_out)
  me <- data.table(rsid = a_exp[[ce$snp]], a1 = a_exp[[ce$ea]], a0 = a_exp[[ce$oa]],
                   beta = as.numeric(a_exp[[ce$beta]]), se = as.numeric(a_exp[[ce$se]]))
  mo <- data.table(rsid = a_out[[co$snp]], oa_eff = a_out[[co$ea]], oa_oth = a_out[[co$oa]],
                   beta_out = as.numeric(a_out[[co$beta]]), se_out = as.numeric(a_out[[co$se]]))
  mh <- merge(me, mo, by = "rsid")
  mh <- mh[(mh$a1 == mh$oa_eff & mh$a0 == mh$oa_oth) | (mh$a1 == mh$oa_oth & mh$a0 == mh$oa_eff)]
  mh$beta_out_adj <- ifelse(mh$a1 == mh$oa_oth, -mh$beta_out, mh$beta_out)
  if (nrow(mh) == 0) { cat("  ! step2 0 SNPs after harmonize\n"); next }
  iv2 <- ivw(mh$beta, mh$beta_out_adj, mh$se_out)
  eg2 <- mregger(mh$beta, mh$beta_out_adj, mh$se_out)
  cat("  step2 (mediator->cognition): b=", round(iv2$b,4), " se=", round(iv2$se_re,4), " Egger_int_p=", round(eg2$p_int,3), " n=", nrow(mh), "\n")

  ## indirect effect (delta method)
  ind <- iv1$b * iv2$b
  se_ind <- sqrt((iv2$b * iv1$se_re)^2 + (iv1$b * iv2$se_re)^2)
  rows[[md]] <- data.frame(
    mediator = md, mediator_id = mid,
    step1_n = nrow(h1), step1_beta = iv1$b, step1_se = iv1$se_re, step1_p = 2 * pnorm(-abs(iv1$b / iv1$se_re)),
    step1_Q = iv1$Q, step1_Qp = iv1$pQ, step1_Egger_int_p = eg1$p_int,
    step2_n = nrow(mh), step2_beta = iv2$b, step2_se = iv2$se_re, step2_p = 2 * pnorm(-abs(iv2$b / iv2$se_re)),
    step2_Q = iv2$Q, step2_Qp = iv2$pQ, step2_Egger_int_p = eg2$p_int,
    indirect = ind, indirect_se = se_ind,
    indirect_lo = ind - 1.96 * se_ind, indirect_hi = ind + 1.96 * se_ind,
    indirect_p = 2 * pnorm(-abs(ind / se_ind)),
    stringsAsFactors = FALSE)
}
if (length(rows) > 0) {
  res <- do.call(rbind, rows)
  fwrite(res, file.path(DER, "mr_mediation_results.csv"))
  print(res)
  cat("\nWrote data/derived/mr_mediation_results.csv\n")
} else cat("No mediation results produced.\n")
cat("DONE\n")
