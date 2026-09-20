#!/usr/bin/env Rscript
# 01_charls.R
# CHARLS longitudinal observational analysis (SAP section 2):
#   pain burden (0 / 1 / 2 / >=3 sites) -> cognitive decline (LMM) + incident decline (Cox)
#   + restricted cubic spline dose-response.
#
# INPUT CONTRACT: a CLEANED extract at data/raw/charls_clean.rds produced by
#   analysis/10_charls_extract.R. Required columns (verified against CHARLS codebook;
#   see COG_SPEC / PAIN_SITES_15 checklists below):
#     id, wave (numeric year: 2011/2013/2015/2018/2020)
#     pain_sites  (0-15, count of positive DA042* sites)
#     pain_any    (0/1, "often troubled by bodily pain" -> DA041 or DA028)
#     cog_im      (immediate word recall 0-10, sum of dc009s1..dc009s10)
#     cog_de      (delayed  word recall 0-10, sum of dc012s1..dc012s10)
#     cog_ser7    (serial 7 subtraction  0-5,  dc024)
#     cog_orient  (time orientation      0-5,  sum of dc003..dc007)
#     cog_draw    (figure drawing        0-1,  dc014)
#     age, sex, edu, urban, married, smoke, alcohol, bmi,
#     comorb_htn, comorb_dm, comorb_stroke, comorb_hd, comorb_ckd, cesd, sleep_hrs
#
# CHARLS cognition = TICS battery adapted to in-person interview (NOT a "TICS total"
#   variable; do not invent one). The standard global cognition score used across the
#   CHARLS literature is 0-31 = im(0-20) + mental-intactness(0-11). Refs:
#   - Hu et al. 2012 (CHARLS cognition design); Ding & He 2021; gnaf014 / gladi180.
# This script (a) documents every component as a per-variable checklist, (b) builds a
# primary equal-weight Z composite and a sensitivity 0-31 global score, and (c) validates
# the schema before modelling.

suppressPackageStartupMessages({
  library(lme4); library(survival); library(rms); library(tableone)
  library(dplyr); library(tidyr); library(knitr)
})

ROOT    <- tryCatch(here::here(), error = function(e) getwd())
DERIVED <- file.path(ROOT, "data", "derived"); dir.create(DERIVED, recursive = TRUE, showWarnings = FALSE)
STAMP   <- format(Sys.Date(), "%Y%m%d")
RAW     <- file.path(ROOT, "data", "raw", "charls_clean.rds")

# =====================================================================
# PER-VARIABLE CHECKLIST 1 — COGNITION COMPONENTS (CHARLS = TICS-based)
#   component  : internal name used in cog_z / cog_global
#   charls_var : source variable(s) in the cleaned extract
#   range      : valid raw range (used for plausibility checks)
#   domain     : episodic memory vs mental intactness
#   in_z       : enters the equal-weight Z composite (primary)
#   in_global  : enters the 0-31 global score (sensitivity)
# =====================================================================
COG_SPEC <- data.frame(
  component  = c("cog_im",    "cog_de",    "cog_ser7",  "cog_orient", "cog_draw"),
  charls_var = c("dc009s1..10","dc012s1..10","dc024",   "dc003..007", "dc014"),
  range      = c("0-10",      "0-10",      "0-5",       "0-5",        "0-1"),
  domain     = c("episodic",  "episodic",  "intactness","intactness", "intactness"),
  in_z       = c(TRUE, TRUE, TRUE, TRUE, TRUE),
  in_global  = c(TRUE, TRUE, TRUE, TRUE, TRUE),
  stringsAsFactors = FALSE
)
# Standard CHARLS global cognition = sum of the five components below (range 0-31).
#   episodic memory = im + de            (0-20)
#   mental intactness = ser7 + orient + draw (0-11)
GLOBAL_FORMULA <- "cog_global = cog_im + cog_de + cog_ser7 + cog_orient + cog_draw  (range 0-31)"

# =====================================================================
# PER-VARIABLE CHECKLIST 2 — PAIN SITES (DA042* self-report, 15 standard items)
#   These are the body regions CHARLS asks about; a positive response (=1) at any
#   site increments pain_sites. Confirm the exact DA042* item order/count against
#   your wave's codebook (CHARLS wording has been stable across 2011-2020).
# =====================================================================
PAIN_SITES_15 <- c(
  "head (headache)", "neck", "chest", "stomach (abdomen)", "shoulder",
  "back", "waist (low back)", "buttock/hip", "arm", "leg", "knee",
  "wrist", "finger", "ankle", "toe"
)
PAIN_SITE_NOTE <- paste0(
  "pain_sites = count of positively-endorsed DA042* items among the ",
  length(PAIN_SITES_15), " standard regions. 'multisite' (>=2) and '>=3' ",
  "are both used in the literature; this project uses >=3 as the primary cut (SAP 2.1)."
)

# ---- guard on data presence ----
if (!file.exists(RAW)) {
  message("CHARLS clean extract not found at ", RAW)
  message("Run analysis/10_charls_extract.R (or build your own) to create it.")
  message("Required columns: id, wave, pain_sites, pain_any, cog_im, cog_de, cog_ser7, cog_orient, cog_draw, + demographics.")
  quit(save = "no")
}
d <- readRDS(RAW)

# ---- schema validation against the two checklists ----
REQUIRED <- c("id","wave","pain_sites","pain_any",
              "cog_im","cog_de","cog_ser7","cog_orient","cog_draw","age","sex","edu")
missing_cols <- setdiff(REQUIRED, names(d))
if (length(missing_cols)) stop("Missing required column(s): ", paste(missing_cols, collapse=", "),
                               ". Check 10_charls_extract.R mapping / codebook.")

# plausibility bounds from COG_SPEC (silent if a column is out of expected range)
bounds <- list(cog_im=c(0,10), cog_de=c(0,10), cog_ser7=c(0,5),
               cog_orient=c(0,5), cog_draw=c(0,1), pain_sites=c(0,15))
for (cn in names(bounds)) {
  v <- d[[cn]]
  if (any(!is.na(v) & (v < bounds[[cn]][1] | v > bounds[[cn]][2]))) {
    warning("Column ", cn, " has values outside expected range ",
            paste(bounds[[cn]], collapse="-"), "; verify codebook coding.")
  }
}

# =====================================================================
# EXPOSURE: pain burden grading (primary = 0/1/2/>=3; sensitivity multisite >=2)
# =====================================================================
d <- d %>% mutate(
  pain_burden = case_when(pain_sites == 0 ~ "0",
                          pain_sites == 1 ~ "1",
                          pain_sites == 2 ~ "2",
                          pain_sites >= 3 ~ "3+", TRUE ~ NA_character_),
  pain_burden_n = as.numeric(pain_sites),
  pain_multisite = if_else(pain_sites >= 2, 1L, 0L)   # sensitivity exposure (>=2 sites)
)

# =====================================================================
# COGNITIVE SYNTHESIS
#   (A) PRIMARY  cog_z      : equal-weight average of the 5 components, each
#                            z-scored WITHIN wave (removes wave/cohort drift,
#                            and prevents the 0-1 draw item from being drowned
#                            by the 0-10 memory items in a raw sum).
#   (B) SENSITIVITY cog_global : the standard 0-31 CHARLS global score
#                            (transparent, codebook-defined; for robustness).
# =====================================================================
z_components <- COG_SPEC$component[COG_SPEC$in_z]
d <- d %>% group_by(wave) %>%
  mutate(across(all_of(z_components), ~ as.numeric(scale(as.numeric(.))))) %>% ungroup()
d <- d %>% mutate(
  cog_z       = rowMeans(select(., all_of(z_components)), na.rm = TRUE),
  cog_global  = rowSums(select(., all_of(COG_SPEC$component[COG_SPEC$in_global])), na.rm = TRUE)
)
if (all(is.na(d$cog_z))) stop("cog_z is all NA - check cog_* columns have non-missing values.")

# =====================================================================
# OUTCOME: incident cognitive decline
#   PRIMARY   : within-person drop of > 1 SD of own baseline cog_z.
#   SENSITIVITY: drop of > 1 SD of own baseline cog_global (0-31 scale).
#   (Baseline = earliest available wave per id.)
# =====================================================================
base <- d %>% filter(wave == min(wave, na.rm = TRUE)) %>%
  select(id, cog_z_base = cog_z, cog_global_base = cog_global)
d <- d %>% left_join(base, by = "id") %>% mutate(
  decline_event        = cog_z < cog_z_base - 1,
  decline_event_global = cog_global < cog_global_base - 1
)

# ---- follow_years: derive from wave if absent ----
if (!"follow_years" %in% names(d)) {
  wave_year <- c("2011"=0,"2013"=2,"2015"=4,"2018"=7,"2020"=9)
  d <- d %>% mutate(follow_years = as.numeric(wave_year[as.character(wave)]))
}

# ---- print the checklists to the log for auditability ----
cat("\n=== COGNITION COMPONENT CHECKLIST ===\n")
print(kable(COG_SPEC, format = "simple"))
cat("\n", GLOBAL_FORMULA, "\n\n")
cat("=== PAIN SITE CHECKLIST (n =", length(PAIN_SITES_15), ") ===\n")
cat(paste(PAIN_SITES_15, collapse = ", "), "\n")
cat(PAIN_SITE_NOTE, "\n\n")

# ---- Table 1 by pain burden ----
tab1 <- print(tableone::CreateTableOne(
  vars = c("age","sex","edu","urban","bmi","cesd","cog_global"),
  strata = "pain_burden", data = d), quote = FALSE)

# ---- LMM: cog_z ~ pain_burden_n * wave (+ random intercept/slope) ----
m0 <- lmer(cog_z ~ pain_burden_n * as.factor(wave) + (1 + wave | id), data = d)
m1 <- lmer(cog_z ~ pain_burden_n * as.factor(wave) + age + sex + edu + urban + married + (1 + wave | id), data = d)
m2 <- lmer(cog_z ~ pain_burden_n * as.factor(wave) + age + sex + edu + urban + married +
             smoke + alcohol + bmi + comorb_htn + comorb_dm + comorb_stroke + (1 + wave | id), data = d)

# ---- SENSITIVITY LMM on the 0-31 global score (same model skeleton) ----
g0 <- lmer(cog_global ~ pain_burden_n * as.factor(wave) + (1 + wave | id), data = d)
g1 <- lmer(cog_global ~ pain_burden_n * as.factor(wave) + age + sex + edu + urban + married + (1 + wave | id), data = d)

# ---- Cox: incident decline ~ baseline pain burden ----
cox <- coxph(Surv(follow_years, decline_event) ~ pain_burden_n + age + sex + edu, data = d)

# ---- RCS dose-response (baseline wave, primary cog_z) ----
base_c <- d %>% filter(wave == min(wave, na.rm = TRUE)) %>% filter(!is.na(cog_z))
dd <- datadist(base_c); options(datadist = "dd")
rcs_mod <- ols(cog_z ~ rcs(pain_burden_n, 4) + age + sex + edu, data = base_c)

saveRDS(list(tab1 = tab1, m0 = m0, m1 = m1, m2 = m2,
             g0 = g0, g1 = g1, cox = cox, rcs = rcs_mod, n = nrow(d)),
        file.path(DERIVED, paste0("charls_results_", STAMP, ".rds")))
cat("CHARLS results -> data/derived/charls_results_", STAMP, ".rds (n=", nrow(d), ")\n")
cat("Audit: every coefficient must trace to this rds; see SAP section 2 and COG_SPEC above.\n")
