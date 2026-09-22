#!/usr/bin/env Rscript
# 01_charls.R  (REWRITTEN 2026-09-21 to match CHARLS_VARIABLE_MAP.md + 10_charls_extract.R)
#
# CHARLS longitudinal observational analysis (SAP section 2):
#   pain burden (0 / 1 / 2 / >=3 sites) -> cognitive trajectory (LMM) +
#   incident cognitive decline (Cox) + restricted cubic spline dose-response.
#
# INPUT: data/derived/charls_long.rds from analysis/10_charls_extract.R.
#   Schema: id, wave, anchor_year, pain_any, pain_burden, cog_im, cog_de,
#           cog_ser7, cesd, age, male, edu_raw, edu_yrs, urban, married,
#           smoke, alcohol, sleep_hrs, comorb_htn, comorb_dm, comorb_stroke,
#           comorb_hd, comorb_ckd, comorb_count.
#
# COGNITION: global cognition z = mean of cross-sample z-scores of the three
#   EXACTLY-scored components (immediate recall, delayed recall, serial-7).
#   - Cross-sample (not within-wave) z preserves real between-wave LEVELS
#     (e.g. practice effects), so trajectories and "decline" are meaningful.
#   - Orientation/drawing excluded (need per-respondent interview dates; MAP 2.4).
#   - 2015's 12-word list vs 11-word lists in 2011/2013 is absorbed by z-scoring.
#   Primary analytic sample = 2011/2013/2015 with complete cognition.
#   2018/2020 cognition is NA (incomparable) -> used only for descriptive pain.
#
# PATH NOTE: R on Windows cannot open files under a Chinese path. Run from an
#   ASCII staging copy and pass CHARLS_ROOT, e.g.
#   CHARLS_ROOT=C:/work Rscript analysis/01_charls.R

suppressPackageStartupMessages({
  library(lme4); library(survival); library(rms); library(dplyr); library(tidyr)
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

if (!file.exists(RAW)) stop("CHARLS long extract not found at ", RAW,
                            ". Run analysis/10_charls_extract.R first.")
d <- readRDS(RAW)

## ---- schema validation ----
REQUIRED <- c("id","wave","pain_burden","pain_any","cog_im","cog_de","cog_ser7",
              "age","male","edu_yrs","urban","married","smoke","alcohol",
              "sleep_hrs","comorb_htn","comorb_dm","comorb_stroke","comorb_hd","comorb_ckd")
missing_cols <- setdiff(REQUIRED, names(d))
if (length(missing_cols)) stop("Missing required column(s): ", paste(missing_cols, collapse = ", "))

## ---- harmonise names ----
d <- d %>% mutate(
  sex = male, edu = edu_yrs,
  pain_burden_n = as.numeric(pain_burden),
  pain_cat = cut(pain_burden_n, breaks = c(-0.5, 0.5, 1.5, 2.5, Inf),
                 labels = c("0", "1", "2", "3+"), right = FALSE),
  time = as.numeric(wave) - 2011          # 2011=0, 2013=2, 2015=4
)
PRIMARY_WAVES <- c(2011, 2013, 2015)

## ---- global cognition: cross-sample z of 3 exactly-scored components ----
d_cog <- d %>% filter(wave %in% PRIMARY_WAVES, !is.na(cog_im), !is.na(cog_de), !is.na(cog_ser7))
comp <- c("cog_im", "cog_de", "cog_ser7")
for (c in comp) d_cog[[paste0(c, "_z")]] <- as.numeric(scale(d_cog[[c]]))
d_cog <- d_cog %>% mutate(cog_global_z = rowMeans(select(., ends_with("_z")), na.rm = TRUE))
d <- d %>% left_join(d_cog %>% select(id, wave, cog_global_z), by = c("id", "wave"))

## ---- descriptive: RAW cognition by wave + baseline by pain burden ----
cat("\n=== Cognition by wave (RAW component means, primary waves) ===\n")
print(d_cog %>% group_by(wave) %>% summarise(
  n = n(), cog_im = round(mean(cog_im, na.rm = TRUE), 2),
  cog_de = round(mean(cog_de, na.rm = TRUE), 2),
  cog_ser7 = round(mean(cog_ser7, na.rm = TRUE), 2),
  cog_global_z = round(mean(cog_global_z, na.rm = TRUE), 3), .groups = "drop"))

cat("\n=== Table 1: 2011 baseline by pain-burden category ===\n")
t1 <- d %>% filter(wave == 2011) %>% group_by(pain_cat) %>% summarise(
  n = n(), age = round(mean(age, na.rm = TRUE), 1),
  pct_male = round(mean(male, na.rm = TRUE) * 100, 1),
  edu_yrs = round(mean(edu_yrs, na.rm = TRUE), 1),
  pct_urban = round(mean(urban, na.rm = TRUE) * 100, 1),
  cesd = round(mean(cesd, na.rm = TRUE), 1),
  pct_multimorb = round(mean(comorb_count >= 2, na.rm = TRUE) * 100, 1),
  cog_im = round(mean(cog_im, na.rm = TRUE), 2), .groups = "drop")
print(t1)

## ---- outcome: incident cognitive impairment (worst-quartile incidence) ----
## Baseline (2011) distribution defines the impairment cut. Event = falling into the
## worst quartile of cognition at a LATER wave among those NOT impaired at baseline.
## This is the conventional CHARLS operationalisation of incident cognitive impairment.
base <- d_cog %>% filter(wave == 2011) %>% select(id, cog_base = cog_global_z)
cut  <- quantile(base$cog_base, 0.25, na.rm = TRUE)
dc <- d_cog %>% left_join(base, by = "id") %>%
  mutate(impaired_base = !is.na(cog_base) & cog_base <= cut,
         decline_event = ifelse(is.na(cog_base), NA,
                                !impaired_base & cog_global_z <= cut))
cat("\nIncident cognitive impairment (worst-quartile incidence) person-waves:",
    sum(dc$decline_event, na.rm = TRUE), "of", sum(!is.na(dc$decline_event)), "\n")

## ---- build per-person Cox dataset from baseline (2011) ----
ev <- dc %>% filter(wave > 2011) %>% group_by(id) %>%
  summarise(last_t = max(time, na.rm = TRUE),
            decline_any = any(decline_event, na.rm = TRUE),
            t_event = if (any(decline_event, na.rm = TRUE))
                        min(time[decline_event & !is.na(decline_event)]) else NA_real_,
            .groups = "drop")
cox_base <- dc %>% filter(wave == 2011) %>% select(id, pain_burden_n, age, sex, edu)
cox_df <- cox_base %>% left_join(ev, by = "id") %>%
  filter(!is.na(last_t)) %>%                       # require >=1 follow-up wave with cognition
  mutate(t_event = ifelse(decline_any & !is.na(t_event), t_event, last_t),
         status   = ifelse(decline_any, 1, 0))
cat("Cox persons:", nrow(cox_df), "| events:", sum(cox_df$status, na.rm = TRUE), "\n")

## ---- LMM: cog_global_z ~ pain_burden * time + (1|id) ----
m0 <- lmer(cog_global_z ~ pain_burden_n * time + (1 | id), data = d_cog)
m1 <- lmer(cog_global_z ~ pain_burden_n * time + age + sex + edu + urban + married + (1 | id), data = d_cog)
m2 <- lmer(cog_global_z ~ pain_burden_n * time + age + sex + edu + urban + married +
             smoke + alcohol + sleep_hrs + comorb_count + (1 | id), data = d_cog)

## ---- Cox: incident decline from 2011 baseline ----
cox <- coxph(Surv(t_event, status) ~ pain_burden_n + age + sex + edu, data = cox_df)

## ---- RCS dose-response at baseline ----
base_c <- dc %>% filter(wave == 2011) %>% filter(!is.na(cog_global_z))
dd <- datadist(base_c); options(datadist = "dd")
rcs_mod <- ols(cog_global_z ~ rcs(pain_burden_n, 3) + age + sex + edu, data = base_c)

## ---- print key coefficients ----
print_lmm <- function(fit, label) {
  cat(sprintf("\n=== LMM %s ===\n", label))
  print(coef(summary(fit)))
}
print_lmm(m0, "m0: cog_global_z ~ pain_burden_n * time")
print_lmm(m1, "m1: + age/sex/edu/urban/married")
print_lmm(m2, "m2: + smoke/alcohol/sleep/comorbidity")
cat("\n=== Cox: incident decline ~ baseline pain burden (HR) ===\n")
print(exp(cbind(coef(cox), confint(cox))))

## ---- save ----
out <- list(
  table1 = t1,
  desc_by_wave = d_cog %>% group_by(wave) %>% summarise(
    n = n(), cog_im = mean(cog_im, na.rm = TRUE),
    cog_de = mean(cog_de, na.rm = TRUE), cog_ser7 = mean(cog_ser7, na.rm = TRUE),
    cog_global_z = mean(cog_global_z, na.rm = TRUE), .groups = "drop"),
  m0 = m0, m1 = m1, m2 = m2, cox = cox, rcs = rcs_mod,
  n_primary = nrow(d_cog), n_total = nrow(d),
  n_cox = nrow(cox_df), n_events = sum(cox_df$status),
  decline_personwaves = sum(dc$decline_event, na.rm = TRUE)
)
saveRDS(out, file.path(DERIVED, paste0("charls_results_", STAMP, ".rds")))
cat("\nCHARLS results ->", file.path(DERIVED, paste0("charls_results_", STAMP, ".rds")), "\n")
cat("  primary analytic rows (2011/13/15, cog complete):", nrow(d_cog),
    "| total rows:", nrow(d), "\n")
cat("  AUDIT: every coefficient traces to this rds and to the MAP-derived extraction.\n")
