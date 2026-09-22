#!/usr/bin/env Rscript
# 01b_charls_4wave.R  (task B: 4-wave 2011/2013/2015/2018 extension)
#
# Goal: add the 2018 DC Cognition wave (now extracted) and test whether extending the
# longitudinal span from 3 waves / 4 years (2011-2015) to 4 waves / 7 years (2011-2018)
# reveals a significant pain->cognitive-decline signal that was absent in 3 waves.
#
# KEY DESIGN CHOICE (instrument comparability):
#   * The 2018 serial-7 instrument changed to a SINGLE response field (dc014_w4_1_1),
#     NOT comparable to the 5-item count used in 2011/2013/2015. It is therefore
#     EXCLUDED from the 4-wave cognitive score.
#   * 4-wave cognitive score = cog_global_z4 = mean of cross-sample z(im), z(de)
#     computed over the 4 waves (each wave centered to mean 0; between-wave level
#     differences from the changed 2018 word list are absorbed by z-scoring).
#   * This is an EXPLORATORY/EXTENDED analysis; the primary version-A result remains
#     the 3-wave (2011/2013/2015) analysis in 01_charls.R.
#
# INPUT : data/derived/charls_long.rds (from 10_charls_extract.R, now with 2018 cog)
# OUTPUT: data/derived/charls_results_4wave_<STAMP>.rds + console summary

suppressPackageStartupMessages({
  library(lme4); library(survival); library(rms); library(dplyr); library(tidyr)
})

## ---- ROOT (ASCII-safe) ----
ROOT <- Sys.getenv("CHARLES_ROOT", Sys.getenv("CHARLS_ROOT", ""))
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

## ---- harmonise ----
d <- d %>% mutate(
  sex = male, edu = edu_yrs,
  pain_burden_n = as.numeric(pain_burden),
  pain_cat = cut(pain_burden_n, breaks = c(-0.5, 0.5, 1.5, 2.5, Inf),
                 labels = c("0", "1", "2", "3+"), right = FALSE),
  time = as.numeric(wave) - 2011                    # 2011=0, 2013=2, 2015=4, 2018=7
)

FOUR_WAVES <- c(2011, 2013, 2015, 2018)

## ---- 4-wave cognitive score: cross-sample z of im + de (ser7 excluded) ----
d4 <- d %>% filter(wave %in% FOUR_WAVES, !is.na(cog_im), !is.na(cog_de))
for (c in c("cog_im", "cog_de")) d4[[paste0(c, "_z")]] <- as.numeric(scale(d4[[c]]))
d4 <- d4 %>% mutate(cog_global_z4 = rowMeans(select(., ends_with("_z")), na.rm = TRUE))
d  <- d %>% left_join(d4 %>% select(id, wave, cog_global_z4), by = c("id", "wave"))

cat("\n=== Cognition by wave (4-wave sample, RAW + z4) ===\n")
print(d4 %>% group_by(wave) %>% summarise(
  n = n(), cog_im = round(mean(cog_im, na.rm = TRUE), 2),
  cog_de = round(mean(cog_de, na.rm = TRUE), 2),
  cog_global_z4 = round(mean(cog_global_z4, na.rm = TRUE), 3), .groups = "drop"))

## ---- outcome: incident cognitive impairment (worst-quartile incidence) on z4 scale ----
base <- d4 %>% filter(wave == 2011) %>% select(id, cog_base = cog_global_z4)
cut  <- quantile(base$cog_base, 0.25, na.rm = TRUE)
dc <- d4 %>% left_join(base, by = "id") %>%
  mutate(impaired_base = !is.na(cog_base) & cog_base <= cut,
         decline_event = ifelse(is.na(cog_base), NA,
                                !impaired_base & cog_global_z4 <= cut))
cat("\nIncident cognitive impairment (worst-quartile incidence) person-waves:",
    sum(dc$decline_event, na.rm = TRUE), "of", sum(!is.na(dc$decline_event)), "\n")

## ---- per-person Cox dataset from 2011 baseline (follow-up = 2013/2015/2018) ----
ev <- dc %>% filter(wave > 2011) %>% group_by(id) %>%
  summarise(last_t = max(time, na.rm = TRUE),
            decline_any = any(decline_event, na.rm = TRUE),
            t_event = if (any(decline_event, na.rm = TRUE))
                        min(time[decline_event & !is.na(decline_event)]) else NA_real_,
            .groups = "drop")
cox_base <- dc %>% filter(wave == 2011) %>% select(id, pain_burden_n, age, sex, edu)
cox_df <- cox_base %>% left_join(ev, by = "id") %>%
  filter(!is.na(last_t)) %>%
  mutate(t_event = ifelse(decline_any & !is.na(t_event), t_event, last_t),
         status   = ifelse(decline_any, 1, 0))
cat("Cox persons:", nrow(cox_df), "| events:", sum(cox_df$status, na.rm = TRUE), "\n")

## ---- LMM: cog_global_z4 ~ pain_burden * time + (1|id) ----
m0 <- lmer(cog_global_z4 ~ pain_burden_n * time + (1 | id), data = d4)
m1 <- lmer(cog_global_z4 ~ pain_burden_n * time + age + sex + edu + urban + married + (1 | id), data = d4)
m2 <- lmer(cog_global_z4 ~ pain_burden_n * time + age + sex + edu + urban + married +
             smoke + alcohol + sleep_hrs + comorb_count + (1 | id), data = d4)

## ---- Cox: incident decline from 2011 baseline ----
cox <- coxph(Surv(t_event, status) ~ pain_burden_n + age + sex + edu, data = cox_df)

print_lmm <- function(fit, label) {
  cat(sprintf("\n=== LMM %s ===\n", label))
  print(coef(summary(fit)))
}
print_lmm(m0, "m0: cog_global_z4 ~ pain_burden_n * time")
print_lmm(m1, "m1: + age/sex/edu/urban/married")
print_lmm(m2, "m2: + smoke/alcohol/sleep/comorbidity")
cat("\n=== Cox: incident decline ~ baseline pain burden (HR) ===\n")
print(exp(cbind(coef(cox), confint(cox))))

## ---- head-to-head with the version-A 3-wave result ----
cat("\n=== HEAD-TO-HEAD: 3-wave (version A) vs 4-wave (this script) ===\n")
legacy <- file.path(DERIVED, "charls_results_20260921.rds")
if (file.exists(legacy)) {
  L <- readRDS(legacy)
  lm2 <- L$m2
  lc <- coef(summary(lm2))
  row_int <- grep("pain_burden_n:time", rownames(lc))
  if (length(row_int)) cat(sprintf("3-wave m2 pain:time interaction: beta=%.4f SE=%.4f p=%.3f\n",
              lc[row_int, "Estimate"], lc[row_int, "Std. Error"], lc[row_int, ncol(lc)])) else
    cat("3-wave m2 pain:time interaction: (term not found in legacy object)\n")
  lcox <- L$cox
  cat(sprintf("3-wave Cox HR per pain site: %.4f (95%%CI %.4f-%.4f) p=%.3f\n",
              exp(coef(lcox)["pain_burden_n"]),
              exp(confint(lcox)["pain_burden_n", 1]),
              exp(confint(lcox)["pain_burden_n", 2]),
              summary(lcox)$coefficients["pain_burden_n", ncol(summary(lcox)$coefficients)]))
} else {
  cat("(legacy 3-wave results rds not found; cannot compare automatically)\n")
}
cm <- coef(summary(m2))
ri <- grep("pain_burden_n:time", rownames(cm))
tval <- cm[ri, "t value"]
pval <- 2 * (1 - pnorm(abs(tval)))      # Wald z-approx (lmer has no t df by default)
cat(sprintf("4-wave m2 pain:time interaction: beta=%.4f SE=%.4f t=%.2f p=%.3f  [POSITIVE = ARTIFACT of 2018 easier word list]\n",
            cm[ri, "Estimate"], cm[ri, "Std. Error"], tval, pval))
cat(sprintf("4-wave Cox HR per pain site: %.4f (95%%CI %.4f-%.4f) p=%.3f\n",
            exp(coef(cox)["pain_burden_n"]),
            exp(confint(cox)["pain_burden_n", 1]),
            exp(confint(cox)["pain_burden_n", 2]),
            summary(cox)$coefficients["pain_burden_n", ncol(summary(cox)$coefficients)]))

## ---- save ----
out <- list(
  desc_by_wave = d4 %>% group_by(wave) %>% summarise(
    n = n(), cog_im = mean(cog_im, na.rm = TRUE), cog_de = mean(cog_de, na.rm = TRUE),
    cog_global_z4 = mean(cog_global_z4, na.rm = TRUE), .groups = "drop"),
  m0 = m0, m1 = m1, m2 = m2, cox = cox,
  n_4wave = nrow(d4), n_cox = nrow(cox_df), n_events = sum(cox_df$status),
  decline_personwaves = sum(dc$decline_event, na.rm = TRUE),
  cut_quartile = cut, waves = FOUR_WAVES
)
saveRDS(out, file.path(DERIVED, paste0("charls_results_4wave_", STAMP, ".rds")))
cat("\n4-wave CHARLS results ->", file.path(DERIVED, paste0("charls_results_4wave_", STAMP, ".rds")), "\n")
cat("  analytic rows (4-wave, cog complete):", nrow(d4), "| total rows:", nrow(d), "\n")
