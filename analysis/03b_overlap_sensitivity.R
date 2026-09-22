#!/usr/bin/env Rscript
# 03b_overlap_sensitivity.R
# Overlap-robustness sensitivity analysis for MCP -> cognitive performance MR.
#
# CONTEXT: Both the MCP exposure (Johnston et al. 2019, UKB, N=387,649) and the
# cognitive-performance outcome (Davies et al. 2018 COGENT/UKB meta; OpenGWAS
# ebi-a-GCST006572, N=257,841) are UK Biobank-derived => sample overlap.
#
# The canonical MRlap R package (n-mounier/MRlap; Mounier & Kutalik 2021) could
# NOT be executed in this compute environment (no compiler toolchain for its
# GenomicSEM/OpenMx dependencies; LD-score reference files unreachable). We
# therefore implement the overlap-bias estimator of Burgess, Davies & Thompson
# (2016, Genet Epidemiol 40:597-608, doi:10.1002/gepi.21998) -- the same
# theoretical basis as MRlap's overlap correction -- using the authors' own
# formula (verified from mglev1n/mrSampleOverlap estimate_overlap_bias.R):
#     expf = (N_exp - K - 1)/K * R2/(1-R2)
#     var  = var_y / (N_out * var_x * R2)            # continuous outcome
#     bias = ols_bias * overlap_prop * (1/expf)
#     type1 = 2 - pnorm(1.96 + bias/sqrt(var)) - pnorm(1.96 - bias/sqrt(var))
#
# Heritability inputs (literature-verified):
#   MCP h2_SNP = 0.102   (Johnston et al. 2019, PLOS Genet, PMID 31194737)
#   Cognition h2_SNP ~ 0.25 (Davies et al. 2018, COGENT/UKB meta, N=300,486)
# These are reported for context; the bias estimator itself uses R2 of the
# *instrument* (computed from the MR data) and the F-statistic.

suppressMessages({ library(data.table) })
ROOT <- "C:/work"
DER  <- file.path(ROOT, "data/derived")
h <- fread(file.path(DER, "mr_harmonized_cog.csv"))

# ---- IVW (fixed + multiplicative random effects), self-contained ----
bx <- h$beta; by <- h$beta_out_adj; sey <- h$se_out; sex <- h$se
K  <- nrow(h)
w  <- 1/sey^2
b_ivw <- sum(w*bx*by)/sum(w*bx^2)
se_fix <- sqrt(1/sum(w*bx^2))
Q <- sum(w*(by - b_ivw*bx)^2); df <- K - 1
pQ <- if (df>0) pchisq(Q, df, lower.tail=FALSE) else NA
se_re <- if (!is.na(Q) && Q > df && df > 0) se_fix*sqrt(Q/df) else se_fix
cat(sprintf("IVW fixed: beta=%.4f se=%.4f\n", b_ivw, se_fix))
cat(sprintf("IVW RE:    beta=%.4f se=%.4f  (Q=%.1f, df=%d, pQ=%.2e)\n", b_ivw, se_re, Q, df, pQ))

# ---- Instrument strength: F-statistic (Stock-Yogo, multiple instruments) ----
# F = (1/K) * sum( (beta_x / se_x)^2 )
Fstat <- sum((bx/sex)^2)/K
cat(sprintf("Instrument F-statistic = %.1f  (K=%d SNPs)\n", Fstat, K))

# ---- R2 of instrument (inverted from F for internal consistency) ----
N_exp <- 387649   # MCP Johnston 2019
N_out <- 257841   # cognition ebi-a-GCST006572
R2 <- Fstat*K / (Fstat*K + (N_exp - K - 1))
cat(sprintf("Instrument R2 (exposure variance explained) = %.4f\n", R2))

# ---- Burgess-Thompson overlap-bias estimator (verified formula) ----
bt_bias <- function(ols_bias, overlap_prop, expf, N_out, R2, var_x=1, var_y=1) {
  bias <- ols_bias * overlap_prop * (1/expf)
  var  <- var_y / (N_out * var_x * R2)
  type1 <- 2 - pnorm(1.96 + bias/sqrt(var)) - pnorm(1.96 - bias/sqrt(var))
  list(bias=bias, type1=type1)
}
# expf from the formula (equivalent to Fstat by construction)
expf <- (N_exp - K - 1)/K * R2/(1 - R2)
cat(sprintf("expf (from R2) = %.1f  (matches Fstat=%.1f by construction)\n", expf, Fstat))

# ---- Sensitivity grid ----
# ols_bias proxy: the observational (confounded) pain->cognition association.
# We do not know it exactly; present as a fraction of the observed causal effect
# and as a plausible empirical magnitude. Overlap bias is TINY because 1/expf ~ 1/F.
obs_eff <- b_ivw
grid <- expand.grid(
  overlap = c(0.3, 0.5, 0.7, 1.0),
  ols_frac = c(0.25, 0.5, 1.0)          # |ols_bias| as fraction of observed effect
)
rows <- list()
for (i in seq_len(nrow(grid))) {
  ov <- grid$overlap[i]; frac <- grid$ols_frac[i]
  ols_bias <- frac * abs(obs_eff) * sign(-1)   # observational association is negative (pain -> lower cog)
  r <- bt_bias(ols_bias, ov, expf, N_out, R2)
  corrected <- obs_eff - r$bias     # de-overlapped (true) effect
  rows[[length(rows)+1]] <- data.frame(
    overlap_prop = ov, ols_bias_as_frac_of_effect = frac,
    ols_bias = round(ols_bias,4),
    overlap_bias = round(r$bias,5),
    bias_pct_of_effect = round(100*r$bias/obs_eff,3),
    corrected_effect = round(corrected,4),
    type1_error_null = round(r$type1,4)
  )
}
tab <- do.call(rbind, rows)
cat("\n=== Overlap-bias sensitivity (Burgess-Thompson 2016) ===\n")
print(tab, row.names=FALSE)

# ---- Relative bias metric (authors' note: relative bias = 1/F) ----
rel_bias <- 1/Fstat
cat(sprintf("\nRelative bias (1/F) = %.4f  => overlap bias is ~%.2f%% of any observational bias\n",
            rel_bias, rel_bias*100))

# ---- Save ----
out <- list(
  ivw_fixed_beta = b_ivw, ivw_fixed_se = se_fix,
  ivw_re_beta = b_ivw, ivw_re_se = se_re,
  Fstat = Fstat, R2 = R2, K = K,
  N_exp = N_exp, N_out = N_out,
  h2_exp = 0.102, h2_out = 0.25,
  relative_bias = rel_bias,
  sensitivity_table = tab
)
saveRDS(out, file.path(DER, "mr_overlap_sensitivity_20260921.rds"))
fwrite(tab, file.path(DER, "mr_overlap_sensitivity_table.csv"))
cat("\nWrote mr_overlap_sensitivity_20260921.rds + mr_overlap_sensitivity_table.csv\n")
cat("DONE\n")
