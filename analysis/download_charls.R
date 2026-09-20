#!/usr/bin/env Rscript
# download_charls.R
# Reads locally-downloaded CHARLS XPT/SAV files (account required at https://charls.pku.edu.cn/)
# and performs an initial ID-keyed merge. Does NOT download anything.
#
# Usage (after placing files under data/raw/charls/):  Rscript analysis/download_charls.R
#
# Variable DEFINITION (pain count 0/1/2/>=3 and cognition composite) lives in analysis/01_charls.R
# per SAP section 2.1 — this script only loads and stacks the raw modules.

suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
})

ROOT <- tryCatch(here::here(), error = function(e) getwd())
SRC  <- file.path(ROOT, "data", "raw", "charls")
DER  <- file.path(ROOT, "data", "derived")
dir.create(DER, recursive = TRUE, showWarnings = FALSE)
STAMP <- format(Sys.Date(), "%Y%m%d")

files <- list.files(SRC, pattern = "\\.(xpt|XPT|sav|SAV)$", full.names = TRUE)
if (length(files) == 0) {
  stop("No CHARLS files in ", SRC, ". Download from https://charls.pku.edu.cn/ first (account required).")
}

read_any <- function(f) {
  if (grepl("\\.sav$", f, ignore.case = TRUE)) haven::read_sav(f) else haven::read_xpt(f)
}

message("Loading ", length(files), " CHARLS module file(s)...")
raw_list <- lapply(files, function(f) {
  d <- read_any(f)
  attr(d, "src") <- basename(f)
  d
})
names(raw_list) <- basename(files)

# Report row/col counts and the guessed ID column for each module
id_hints <- c("ID", "communityID", "individualID", "hhID", "personID")
for (nm in names(raw_list)) {
  d <- raw_list[[nm]]
  idcol <- intersect(toupper(names(d)), id_hints)
  cat(sprintf("  %-40s %6d rows x %4d cols  id~%s\n", nm, nrow(d), ncol(d),
              if (length(idcol)) idcol[1] else "??"))
}

# Save the raw list for downstream definition in 01_charls.R
outf <- file.path(DER, paste0("charls_raw_modules_", STAMP, ".rds"))
saveRDS(raw_list, outf)
message("Saved raw modules -> ", outf)
message("Define pain-count and cognition variables, then build the analysis dataset in analysis/01_charls.R.")
