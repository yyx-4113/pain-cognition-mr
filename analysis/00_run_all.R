#!/usr/bin/env Rscript
# 00_run_all.R  -- master orchestrator for pain-cognition-mr
#
# Ordered pipeline (SAP section 0):
#   01_charls.R   -> CHARLS longitudinal (needs data/raw/charls_clean.rds)
#   02_nhanes.R   -> NHANES auxiliary (needs data/raw/nhanes_clean.rds)
#   03_mr_pain_cognition.R -> bidirectional MR + MVMR (needs JWT + MCP file)
#   04_mr_mediation.R     -> two-step mediation (needs JWT)
#
# Each sub-script guards on its data dependency and exits cleanly if absent,
# so this runner never fails solely because raw data is not yet staged.

ROOT <- tryCatch(here::here(), error = function(e) getwd())
run <- function(script) {
  cat("\n==== Running", script, "====\n")
  system2("Rscript", args = c(file.path(ROOT, "analysis", script)), wait = TRUE)
}

# 1) MR metadata verification is cheap and JWT-gated -> do first
cat("\n==== MR GWAS metadata verification (--metadata-only) ====\n")
system2("Rscript", args = c(file.path(ROOT, "analysis", "03_mr_pain_cognition.R"), "--metadata-only"), wait = TRUE)

# 2) Observational cohorts (graceful if raw data absent)
run("01_charls.R")
run("02_nhanes.R")

# 3) MR (requires JWT + MCP local file)
run("03_mr_pain_cognition.R")
run("04_mr_mediation.R")

cat("\nPipeline dispatch complete. Inspect data/derived/ for dated outputs.\n")
cat("Every reported number must trace to a derived artifact (audit trail).\n")
