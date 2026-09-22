#!/usr/bin/env Rscript
# 01c_charls_changescore.R  (task A-line: change-score sensitivity for CHARLS)
#
# Complements the primary 3-wave LMM (pain x time interaction, §3.5) and the
# incident-impairment Cox model (§3.5) with a CHANGE-SCORE (ANCOVA) sensitivity
# analysis on the comparable 2011/2013/2015 cognition-assessed waves.
#
# Design:
#   * For each participant with cognition at baseline (2011) and a follow-up wave,
#     compute the raw change  dCog = cog_global_z(fu) - cog_global_z(2011).
#   * cog_global_z = cross-sample z of the 3 exactly-scored components
#     (immediate recall, delayed recall, serial-7) -- identical to 01_charls.R,
#     so the change score is on the same scale as the primary LMM.
#   * Regress dCog on baseline pain_burden with three specifications:
#       M1 unadjusted:        dCog ~ pain_base
#       M2 cov-adjusted:      dCog ~ pain_base + age/sex/edu/urban/married/smoke/alcohol/sleep/comorb
#       M3 full ANCOVA:       dCog ~ pain_base + cog_base + (same covariates)
#     Robust (HC1) SEs are computed manually (no lmtest dependency).
#   * Primary window = 2011 -> 2015 (4-year, matches the LMM time span);
#     secondary window = 2011 -> 2013 reported for completeness.
#
# NOTE: 2018 is intentionally EXCLUDED (incomparable instrument; see §3.5.1).
#
# INPUT : data/derived/charls_long.rds
# OUTPUT: data/derived/charls_results_changescore_<STAMP>.rds  (+ .csv audit)

suppressPackageStartupMessages({
  library(dplyr); library(tidyr); library(sandwich)
})

## ---- ROOT (ASCII-safe) ----
ROOT <- Sys.getenv("CHARLS_ROOT", "")
if (ROOT == "" || !dir.exists(file.path(ROOT, "data", "derived"))) {
  d <- getwd()
  for (i in 1:6) {
    if (file.exists(file.path(d, "data", "derived"))) { ROOT <- d; break }
    p <- dirname(d); if (p == d) break; d <- p
  }
  if (ROOT == "") stop("Cannot locate project root; set CHARLS_ROOT.")
}
DERIVED <- file.path(ROOT, "data", "derived"); dir.create(DERIVED, recursive = TRUE, showWarnings = FALSE)
STAMP   <- format(Sys.Date(), "%Y%m%d")
RAW     <- file.path(DERIVED, "charls_long.rds")
if (!file.exists(RAW)) stop("CHARLS long extract not found at ", RAW, ". Run 10_charls_extract.R first.")
d <- readRDS(RAW)

## ---- replicate the 3-component cross-sample z global cognition (cf. 01_charls.R) ----
PRIMARY_WAVES <- c(2011, 2013, 2015)
d_cog <- d %>% filter(wave %in% PRIMARY_WAVES, !is.na(cog_im), !is.na(cog_de), !is.na(cog_ser7))
comp <- c("cog_im", "cog_de", "cog_ser7")
for (c in comp) d_cog[[paste0(c, "_z")]] <- as.numeric(scale(d_cog[[c]]))
d_cog <- d_cog %>% mutate(cog_global_z = rowMeans(select(., ends_with("_z")), na.rm = TRUE))

## ---- reshape: baseline 2011 + follow-up 2013/2015 ----
base <- d_cog %>% filter(wave == 2011) %>%
  select(id, pain_base = pain_burden, cog_base = cog_global_z,
         age, male, edu_yrs, urban, married, smoke, alcohol, sleep_hrs, comorb_count)
fu13 <- d_cog %>% filter(wave == 2013) %>% select(id, cog_2013 = cog_global_z)
fu15 <- d_cog %>% filter(wave == 2015) %>% select(id, cog_2015 = cog_global_z)
m <- base %>%
  left_join(fu13, by = "id") %>%
  left_join(fu15, by = "id") %>%
  mutate(dCog_2013 = cog_2013 - cog_base,
         dCog_2015 = cog_2015 - cog_base)

cat("Change-score sample:\n")
cat("  baseline (2011) n =", nrow(base), "\n")
cat("  with 2013 follow-up n =", sum(!is.na(m$dCog_2013)), "\n")
cat("  with 2015 follow-up n =", sum(!is.na(m$dCog_2015)), "\n")

## ---- robust (HC1) coefficient extractor ----
robust_coef <- function(fit, term = "pain_base") {
  cf  <- coef(fit)[term]
  se  <- sqrt(diag(vcovHC(fit, type = "HC1")))[term]
  tval<- cf / se
  p   <- 2 * (1 - pt(abs(tval), df = fit$df.residual))
  data.frame(term = term, estimate = cf, se_robust = se,
             t = tval, p = p, n = nobs(fit), row.names = NULL)
}

## ---- 2011 -> 2015 primary window ----
fit1_15 <- lm(dCog_2015 ~ pain_base, data = m)
fit2_15 <- lm(dCog_2015 ~ pain_base + age + male + edu_yrs + urban + married +
                smoke + alcohol + sleep_hrs + comorb_count, data = m)
fit3_15 <- lm(dCog_2015 ~ pain_base + cog_base + age + male + edu_yrs + urban + married +
                smoke + alcohol + sleep_hrs + comorb_count, data = m)

## ---- 2011 -> 2013 secondary window ----
fit1_13 <- lm(dCog_2013 ~ pain_base, data = m)
fit3_13 <- lm(dCog_2013 ~ pain_base + cog_base + age + male + edu_yrs + urban + married +
                smoke + alcohol + sleep_hrs + comorb_count, data = m)

res15 <- rbind(
  cbind(model = "M1_unadj",            robust_coef(fit1_15)),
  cbind(model = "M2_covadj",           robust_coef(fit2_15)),
  cbind(model = "M3_ANCOVA_full",      robust_coef(fit3_15))
)
res13 <- rbind(
  cbind(model = "M1_unadj",            robust_coef(fit1_13)),
  cbind(model = "M3_ANCOVA_full",      robust_coef(fit3_13))
)

cat("\n=== Change-score (2011->2015), pain_base coefficient (robust HC1) ===\n")
print(res15)
cat("\n=== Change-score (2011->2013), pain_base coefficient (robust HC1) ===\n")
print(res13)

## ---- also: mean change by pain category (descriptive) ----
m <- m %>% mutate(pain_cat = cut(pain_base, breaks = c(-0.5, 0.5, 1.5, 2.5, Inf),
                                 labels = c("0","1","2","3+"), right = FALSE))
desc <- m %>% group_by(pain_cat) %>% summarise(
  n = n(), mean_dCog15 = round(mean(dCog_2015, na.rm = TRUE), 4),
  mean_dCog13 = round(mean(dCog_2013, na.rm = TRUE), 4), .groups = "drop")
cat("\n=== Mean cognitive change by baseline pain sites (descriptive) ===\n")
print(as.data.frame(desc))

## ---- save ----
out <- list(
  res_2015 = res15, res_2013 = res13,
  desc_by_pain = desc,
  n_base = nrow(base), n_fu2013 = sum(!is.na(m$dCog_2013)), n_fu2015 = sum(!is.na(m$dCog_2015)),
  note = "Change-score (ANCOVA) sensitivity on 3-wave comparable CHARLS sample; 2018 excluded (incomparable instrument)."
)
saveRDS(out, file.path(DERIVED, paste0("charls_results_changescore_", STAMP, ".rds")))

## ---- CSV audit (long format, tidy) ----
csv_rows <- rbind(
  cbind(window = "2011->2015", res15),
  cbind(window = "2011->2013", res13)
)
write.csv(csv_rows, file.path(DERIVED, paste0("charls_changescore_table_", STAMP, ".csv")),
          row.names = FALSE)

cat("\nChange-score results ->",
    file.path(DERIVED, paste0("charls_results_changescore_", STAMP, ".rds")), "\n")
cat("Audit CSV ->",
    file.path(DERIVED, paste0("charls_changescore_table_", STAMP, ".csv")), "\n")
