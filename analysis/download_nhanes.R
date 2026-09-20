#!/usr/bin/env Rscript
# download_nhanes.R
# Pull NHANES cycle files and cache them as XPT under data/raw/nhanes/.
#
# NOTE: CDC restructured the NHANES file URLs at the end of 2024. The old
#   https://wwwn.cdc.gov/Nchs/NHANES/<cycle>/<COMP>_<suffix>.XPT
# pattern now returns a "Page Not Found" HTML page. The CURRENT pattern is
#   https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/<startYear>/DataFiles/<COMP>_<suffix>.xpt
# (note: lowercase .xpt, and the year is the CYCLE START year).
# This script uses the current pattern directly (no nhanesA, which still points
# at the obsolete 1999 path).
#
# Components pulled: DEMO (demographics+weights), MCQ (memory complaint + arthritis),
# DPQ (depression), SLQ (sleep), PFQ (functional limitation), HSQ (general health).
# CAVEAT: NHANES has no consistent "chronic multisite pain" questionnaire, and its
# objective cognition battery (COGN/CFQ) exists only in 2011-2014 -> cycle mismatch.
# NHANES is AUXILIARY only (pain proxy + mediators). See 02_nhanes.R / 11_nhanes_extract.R.
#
# Usage:  Rscript analysis/download_nhanes.R
# Env overrides (useful on filesystems where R cannot open non-ASCII paths):
#   NHANES_DL_OUT  directory to write XPTs into (default data/raw/nhanes)

suppressPackageStartupMessages(library(foreign))

ROOT <- tryCatch(here::here(), error = function(e) getwd())
OUT  <- Sys.getenv("NHANES_DL_OUT", file.path(ROOT, "data", "raw", "nhanes"))
dir.create(OUT, recursive = TRUE, showWarnings = FALSE)

# cycle start year + per-cycle component letter (DEMO_G/H/I/J)
cycles <- c("2011-2012" = 2011, "2013-2014" = 2013, "2015-2016" = 2015, "2017-2018" = 2017)
suffix <- c("2011-2012" = "G", "2013-2014" = "H", "2015-2016" = "I", "2017-2018" = "J")
components <- c("DEMO", "MCQ", "DPQ", "SLQ", "PFQ", "HSQ")
BASE <- "https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public"

pull_one <- function(cmp, cyc, start_year, suf) {
  dest <- file.path(OUT, paste0(gsub("-", "", cyc), "_", cmp, ".XPT"))
  if (file.exists(dest) && file.size(dest) > 0) { message("  skip (exists): ", basename(dest)); return(invisible(NULL)) }
  url <- sprintf("%s/%d/DataFiles/%s_%s.xpt", BASE, start_year, cmp, suf)
  ok <- tryCatch({
    download.file(url, dest, mode = "wb", quiet = TRUE,
                  method = if (capabilities("libcurl")) "libcurl" else "auto")
    file.size(dest) > 0
  }, error = function(e) FALSE)
  if (ok) message("  saved: ", basename(dest)) else message("  ! failed: ", url)
}

for (cyc in names(cycles)) {
  message("=== cycle ", cyc, " ===")
  for (cmp in components) pull_one(cmp, cyc, cycles[[cyc]], suffix[[cyc]])
}

cat("\nNHANES pull finished ->", OUT, "\n")
cat("Next: Rscript analysis/11_nhanes_extract.R  (merges by SEQN, defines proxies/mediators)\n")
