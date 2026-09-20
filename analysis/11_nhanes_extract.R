#!/usr/bin/env Rscript
# 11_nhanes_extract.R
# Build the CLEANED NHANES extract (data/raw/nhanes_clean.rds) that 02_nhanes.R consumes.
# Reads per-cycle XPT saved by analysis/download_nhanes.R (naming: <cycle>_<COMP>.XPT,
# e.g. 20172018_DEMO.XPT) from data/raw/nhanes/, merges by SEQN, and defines AUXILIARY proxies:
#   seqn, cycle, sdmvstra, sdmvpsu, wtmec2yr, age, sex,
#   pain_proxy (arthritis dx OR MCQ memory complaint), mcq_memory_any, dpq_depressed,
#   sleep_trouble, func_limitation
# Output: one row per respondent, with a `cycle` tag.
#
# !! NHANES has NO consistent chronic-pain questionnaire, and its objective cognition battery
#    (COGN/CFQ) only exists in 2011-2014 -> no overlap with pain. Therefore this file builds
#    PAIN PROXIES (arthritis diagnosis / subjective memory complaint) and MECHANISTIC MEDIATORS
#    (depression, sleep, functional limitation). It does NOT claim pain -> objective cognition.
#    Keep this limitation explicit in Methods.
# !! VERIFY variable names against the NHANES codebook for each cycle before a real run.

suppressPackageStartupMessages({ library(haven); library(dplyr); library(tidyr) })

ROOT <- tryCatch(here::here(), error = function(e) getwd())
# CJK-path workaround: on systems where R's low-level file ops fail on non-ASCII paths,
# set NHANES_SRC / NHANES_OUT to ASCII temp paths (e.g. copy XPTs there first). Defaults
# use the project-relative paths and work fine on ASCII filesystems.
SRC  <- Sys.getenv("NHANES_SRC", "data/raw/nhanes")
OUT  <- Sys.getenv("NHANES_OUT", "data/raw/nhanes_clean.rds")
dir.create(dirname(OUT), recursive = TRUE, showWarnings = FALSE)

CYCLES <- c("20112012", "20132014", "20152016", "20172018")
COMPONENTS <- c("DEMO", "MCQ", "DPQ", "SLQ", "PFQ", "HSQ")

# ---- Variable maps (CONFIRM per cycle against NHANES codebook) ----
DEMO_VARS <- c(seqn="SEQN", stra="SDMVSTRA", psu="SDMVPSU", wtmec="WTMEC2YR",
               age="RIDAGEYR", sex="RIAGENDR", eth="RIDRETH3")

# MCQ: subjective memory complaint. MCQ160E = "Ever had a period of confusion or trouble
# remembering?" 1 = YES, 2 = NO (verified in all 4 cycles: 1:~3.7%, 2:~96%). => "yes" => 1.
MCQ_MEMORY <- "MCQ160E"

# DPQ: PHQ-9 style depression screener. Variables are DPQ010, DPQ020, ... DPQ090 (NOT DPQ001-009).
# Each item 0=Not at all, 1=Several days, 2=More than half the days, 3=Nearly every day,
# 7=Refused, 9=Don't know (verified). PHQ-9 total = sum of raw 0-3; 7/9 treated as missing.
DPQ_ITEMS  <- paste0("DPQ0", 1:9, "0")   # DPQ010..DPQ090 (CONFIRM via codebook)

# SLQ: sleep trouble. SLQ050 = "Trouble sleeping?" 1 = YES, 2 = NO (verified: 1:~22%).
SLEEP_TRBL <- "SLQ050"

# PFQ: functional limitation. Items are PFQ0xx (first is PFQ020, NOT PFQ010); each difficulty
# item 1 = yes / 2 = no. func_limitation = any PFQ0xx item == 1 (verified: ~33%).

read_xpt <- function(p) if (file.exists(p)) as.data.frame(foreign::read.xport(p)) else NULL

extract_cycle <- function(code) {
  files <- file.path(SRC, paste0(code, "_", COMPONENTS, ".XPT"))
  present <- files[file.exists(files)]
  demo_f <- present[[grep("DEMO", present)[1]]]
  if (length(demo_f) == 0 || is.na(demo_f)) { warning("DEMO missing for ", code, "; skipped."); return(NULL) }
  demo <- read_xpt(demo_f)
  out <- demo[, intersect(names(demo), unname(DEMO_VARS))]
  names(out) <- c("seqn","sdmvstra","sdmvpsu","wtmec2yr","age","sex","eth")[
    match(names(out), unname(DEMO_VARS))]
  out$wtmec2yr <- as.numeric(out$wtmec2yr)
  out$age <- as.numeric(out$age); out$sex <- as.numeric(out$sex)

  # --- MCQ: subjective memory complaint (MCQ160E) --- join by SEQN
  # NOTE: no usable chronic-pain / arthritis exposure exists in these NHANES cycles
  # (MCQ250A absent); pain_proxy is therefore NOT constructed. NHANES is used only to
  # characterise the subjective-memory-complaint phenotype and its correlates.
  mcq_f <- present[[grep("MCQ", present)[1]]]
  if (length(mcq_f) && !is.na(mcq_f)) {
    m <- read_xpt(mcq_f)
    sub <- data.frame(seqn = as.numeric(m$SEQN))
    if (MCQ_MEMORY %in% names(m)) sub$mcq_memory_any <- as.numeric(as.numeric(m[[MCQ_MEMORY]]) == 1)
    out <- merge(out, sub, by = "seqn", all.x = TRUE)
  }
  # --- DPQ: PHQ-9 depression screener (DPQ010..DPQ090, 0-3; 7/9 = missing) --- join by SEQN
  dpq_f <- present[[grep("DPQ", present)[1]]]
  if (length(dpq_f) && !is.na(dpq_f)) {
    q <- read_xpt(dpq_f); items <- intersect(DPQ_ITEMS, names(q))
    sub <- data.frame(seqn = as.numeric(q$SEQN))
    if (length(items)) {
      m <- sapply(q[items], function(v) { v <- as.numeric(v); ifelse(v %in% c(7,9), NA_real_, v) })
      # PHQ-9 total (0-27), 7/9 set to missing
      sub$dpq_score <- as.numeric(rowSums(m, na.rm = TRUE))
      # Clinical depression: PHQ-9 total >= 10 (standard NHANES threshold; ~8% of US adults)
      sub$dpq_depressed <- as.numeric(sub$dpq_score >= 10)
    }
    out <- merge(out, sub, by = "seqn", all.x = TRUE)
  }
  # --- SLQ: sleep trouble --- join by SEQN
  slq_f <- present[[grep("SLQ", present)[1]]]
  if (length(slq_f) && !is.na(slq_f)) {
    s <- read_xpt(slq_f)
    sub <- data.frame(seqn = as.numeric(s$SEQN))
    if (SLEEP_TRBL %in% names(s)) sub$sleep_trouble <- as.numeric(as.numeric(s[[SLEEP_TRBL]]) == 1)
    out <- merge(out, sub, by = "seqn", all.x = TRUE)
  }
  # --- PFQ: any functional limitation (any PFQ0xx difficulty item == 1) --- join by SEQN
  pfq_f <- present[[grep("PFQ", present)[1]]]
  if (length(pfq_f) && !is.na(pfq_f)) {
    l <- read_xpt(pfq_f)
    sub <- data.frame(seqn = as.numeric(l$SEQN))
    pfq_items <- setdiff(grep("^PFQ0", names(l), value = TRUE), c("PFQ099","PFQ100"))
    if (length(pfq_items)) {
      anydiff <- rowSums(sapply(l[pfq_items], function(v) as.numeric(as.numeric(v) == 1)), na.rm = TRUE)
      sub$func_limitation <- as.numeric(anydiff >= 1)
    }
    out <- merge(out, sub, by = "seqn", all.x = TRUE)
  }

  # safety net: ensure all expected columns exist
  for (col in c("mcq_memory_any","dpq_depressed","dpq_score","sleep_trouble","func_limitation"))
    if (!col %in% names(out)) out[[col]] <- NA_real_

  out$cycle <- code
  out
}

clean <- bind_rows(Filter(Negate(is.null), lapply(CYCLES, extract_cycle)))
clean <- clean %>% mutate(across(where(is.numeric), ~ as.numeric(.)))
saveRDS(clean, OUT)
cat("Wrote NHANES clean extract ->", OUT, "\n")
cat("  rows:", nrow(clean), " cycles:", paste(sort(unique(clean$cycle)), collapse=", "), "\n")
cat("  columns:", paste(names(clean), collapse=", "), "\n")
cat("  >>> VERIFY MCQ/DPQ/SLQ/PFQ variable names per cycle against the NHANES codebook before modelling.\n")
cat("  >>> NHANES = auxiliary only (pain proxy + mediators); NOT pain->objective-cognition (cycle mismatch).\n")
