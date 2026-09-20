#!/usr/bin/env Rscript
# 02_nhanes.R
# NHANES auxiliary analysis (SAP section 3).
#
# CAVEAT (verified against downloaded 2011-2018 XPTs):
#   * NHANES has NO chronic-multisite-pain questionnaire in these cycles, and its objective
#     cognition battery (COGN/CFQ) exists only in 2011-2014 -> no overlap with any pain measure.
#   * The MCQ arthritis item (MCQ250A) used previously as a pain proxy is ABSENT in 2011-2018 MCQ.
#   => NHANES CANNOT test pain -> cognition. It is used ONLY to characterise the
#      SUBJECTIVE-MEMORY-COMPLAINT phenotype and its correlates (depression, sleep trouble,
#      functional limitation) among US adults, as SUPPORTING (not causal) context for the MR findings.
#   => Disclose the period / construct limitation in Methods/Discussion.

suppressPackageStartupMessages({ library(dplyr); library(survey); library(ggplot2) })
ROOT    <- tryCatch(here::here(), error = function(e) getwd())
DERIVED <- "data/derived"; dir.create(DERIVED, recursive = TRUE, showWarnings = FALSE)
STAMP   <- format(Sys.Date(), "%Y%m%d")
RAW     <- Sys.getenv("NHANES_OUT", "data/raw/nhanes_clean.rds")

if (!file.exists(RAW)) {
  message("NHANES extract not found at ", RAW, ". Run 11_nhanes_extract.R first.")
  quit(save = "no")
}

d <- readRDS(RAW)
cat("NHANES clean extract rows:", nrow(d), " cycles:", paste(sort(unique(d$cycle)), collapse=", "), "\n")

des <- svydesign(ids = ~sdmvpsu, strata = ~sdmvstra, weights = ~wtmec2yr, nest = TRUE, data = d)

## descriptive prevalences (survey-weighted)
# NOTE: each correlate is already coded 0/1 with 1 = "yes/positive". We therefore take the
# weighted mean of the variable directly. (Using I(var == 1) inside a survey formula inverts
# the result due to a known I()/== parsing quirk, so we avoid it.)
prev <- function(x) svymean(as.formula(paste0("~", x)), des, na.rm = TRUE)
cat("\nWeighted prevalences (%, SE):\n")
for (v in c("mcq_memory_any","dpq_depressed","sleep_trouble","func_limitation")) {
  if (v %in% names(d)) { m <- prev(v); cat(sprintf("  %-18s %.1f (%.1f)\n", v, 100*coef(m)[1], 100*sqrt(diag(vcov(m))[1]))) }
}
cat(sprintf("  (dpq_score PHQ-9 mean: %.2f)\n", coef(svymean(~dpq_score, des, na.rm=TRUE))[1]))

## primary auxiliary model: subjective memory complaint ~ correlates + demographics
f <- tryCatch(
  svyglm(mcq_memory_any ~ dpq_depressed + sleep_trouble + func_limitation + age + factor(sex),
         design = des, family = quasibinomial()),
  error = function(e) { cat("model error:", conditionMessage(e), "\n"); NULL })
if (!is.null(f)) {
  sm <- summary(f)$coefficients
  cat("\nPrimary model: mcq_memory_any ~ depression + sleep + function + age + sex\n")
  print(round(sm[, c(1,2,4)], 4))
  # crude OR-style association of each correlate (unadjusted) for transparency
  crude <- list()
  for (v in c("dpq_depressed","sleep_trouble","func_limitation")) {
    m <- tryCatch(svyglm(as.formula(paste0("mcq_memory_any ~ ", v)), design = des, family = quasibinomial()),
                  error = function(e) NULL)
    if (!is.null(m)) crude[[v]] <- round(coef(summary(m))[2, c(1,4)], 4)
  }
  cat("\nCrude (unadjusted) log-OR [95% tail p] of memory complaint per correlate:\n")
  print(as.data.frame(crude))

  # sensitivity: continuous PHQ-9 total (dpq_score) instead of binary depression flag
  f_cont <- tryCatch(
    svyglm(mcq_memory_any ~ dpq_score + sleep_trouble + func_limitation + age + factor(sex),
           design = des, family = quasibinomial()),
    error = function(e) { cat("cont model error:", conditionMessage(e), "\n"); NULL })
  if (!is.null(f_cont)) {
    cat("\nSensitivity model: mcq_memory_any ~ PHQ-9(continuous) + sleep + function + age + sex\n")
    print(round(summary(f_cont)$coefficients[, c(1,2,4)], 4))
  }

  saveRDS(list(primary = f, crude = crude, sensitivity_continuous = f_cont, des = des),
          file.path(DERIVED, paste0("nhanes_results_", STAMP, ".rds")))
  cat("\nWrote data/derived/nhanes_results_", STAMP, ".rds (SUPPORTING ONLY; pain exposure unavailable in NHANES)\n")
} else cat("No NHANES model produced.\n")
cat("DONE\n")
