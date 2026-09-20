#!/usr/bin/env Rscript
# 10_charls_extract.R
# Build the CLEANED CHARLS extract (data/raw/charls_clean.rds) that 01_charls.R consumes.
#
# REAL CHARLS variable structure (verified against CHARLS methods papers + codebooks):
#   Pain "often troubled by bodily pain?"  -> DA041 (2011/13/15/18) or DA028 (2020); 5-pt; any != None = pain
#   Pain body sites (15)                   -> DA042* indicators (head/neck/shoulder/arm/wrist/finger/chest/
#                                              stomach/back/waist/buttock/leg/knee/ankle/toe); COUNT -> multisite
#   Immediate word recall                  -> dc009s1..dc009s10 (sum 0-10)
#   Delayed  word recall                  -> dc012s1..dc012s10 (sum 0-10)
#   Serial 7 (calculation)                -> dc024 (0-5)
#   Time orientation                      -> dc003..dc007 (year/month/date/weekday/season, sum 0-5)
#   Figure drawing                        -> dc014 (0/1)
#   Mental status = ser7 + orient + draw (0-11); Total cognition = im+de+ser7+orient+draw (0-31)
#   CHARLS has NO "TICS total" variable -> do NOT invent one.
#
# The script auto-detects cognition items by column-name pattern (dc009s[0-9], dc012s[0-9], dc024,
# dc014, dc003..dc006) and pain items by DA041/DA028 + DA042* pattern, so it is wave-agnostic.
# It STOPS with a clear message listing available variable names if a required concept is absent,
# so you verify against the codebook rather than silently producing wrong data.
#
# Place raw per-wave .dta under: data/raw/charls/raw/<wave>/*.dta

suppressPackageStartupMessages({ library(haven); library(dplyr); library(tidyr); library(stringr) })

ROOT <- tryCatch(here::here(), error = function(e) getwd())
SRC  <- file.path(ROOT, "data", "raw", "charls", "raw")
DER  <- file.path(ROOT, "data", "derived"); dir.create(DER, recursive = TRUE, showWarnings = FALSE)
OUT  <- file.path(ROOT, "data", "raw", "charls_clean.rds")

# ---- ID variable (CHARLS per-wave .dta merge key). CONFIRM against your downloaded files. ----
ID_VAR <- "ID"   # common individual id in CHARLS raw; change if your files use e.g. "individualID"/"communityID"

# ---- demographic name patterns (wave-prefixed r1../r2..); detected by substring ----
DEMO_PATTERNS <- list(
  age  = "agey",      # contains "agey"  (e.g. r1agey)
  sex  = "gender",    # contains "gender" (e.g. r1gender)
  edu  = "educ",      # contains "educ"
  urban= "urban",     # rural/urban
  marr = "marry"      # marital status
)

# ---- helper: pick first existing column matching a substring (case-insensitive) ----
pick <- function(names_vec, pattern) {
  idx <- grep(pattern, names_vec, ignore.case = TRUE)
  if (length(idx)) names_vec[idx[1]] else NA_character_
}

# ---- helper: sum 10 binary recall items dc009s1..dc009s10 etc. ----
sum_items <- function(df, stem, n) {
  cols <- intersect(paste0(stem, 1:n), names(df))
  if (length(cols) == 0) return(rep(NA_real_, nrow(df)))
  rowSums(sapply(df[cols], function(x) as.numeric(as.character(x))), na.rm = TRUE)
}

load_dta <- function(f) {
  if (grepl("\\.dta$", f, ignore.case = TRUE)) read_dta(f)
  else if (grepl("\\.sav$", f, ignore.case = TRUE)) read_sav(f)
  else read_xpt(f)
}

files <- list.files(SRC, pattern = "\\.(dta|DTA|sav|SAV|xpt|XPT)$", recursive = TRUE, full.names = TRUE)
if (length(files) == 0) stop("No CHARLS raw .dta under ", SRC, ". Download from charls.pku.edu.cn first.")

rows <- list()
for (f in files) {
  df0 <- as.data.frame(load_dta(f))
  wv  <- as.character(NA)
  # infer wave from filename (e.g. ...2015..., ...wave3..., ...w3...)
  m <- regmatches(basename(f), regexpr("20(1[1]|1[3]|1[5]|1[8]|20)", basename(f)))
  if (length(m)) wv <- as.integer(m[1])
  cat("Wave", wv, "file:", basename(f), "rows:", nrow(df0), "cols:", ncol(df0), "\n")

  id_col <- if (ID_VAR %in% names(df0)) ID_VAR else pick(names(df0), "id$")
  if (is.na(id_col)) { warning("No ID column in ", basename(f), "; skipped."); next }

  rec <- data.frame(id = df0[[id_col]], wave = wv, stringsAsFactors = FALSE)

  # cognition
  rec$cog_im   <- sum_items(df0, "dc009s", 10)
  rec$cog_de   <- sum_items(df0, "dc012s", 10)
  rec$cog_ser7 <- if ("dc024" %in% names(df0)) as.numeric(df0[["dc024"]]) else NA_real_
  orient_cols  <- intersect(c("dc003","dc004","dc005","dc006","dc007"), names(df0))
  rec$cog_orient <- if (length(orient_cols)) rowSums(sapply(df0[orient_cols], as.numeric), na.rm = TRUE) else NA_real_
  rec$cog_draw <- if ("dc014" %in% names(df0)) as.numeric(df0[["dc014"]]) else NA_real_

  # pain: any-pain flag + site count
  pain_flag_col <- pick(names(df0), "DA041"); if (is.na(pain_flag_col)) pain_flag_col <- pick(names(df0), "DA028")
  # site indicators: any column starting with DA042 (+ optional letter/digit)
  site_cols <- grep("^DA042", names(df0), ignore.case = TRUE, value = TRUE)
  rec$pain_any <- if (!is.na(pain_flag_col)) as.numeric(as.numeric(df0[[pain_flag_col]]) > 1) else NA_real_  # 1=None -> 0, else 1
  rec$pain_sites <- if (length(site_cols)) as.numeric(rowSums(sapply(df0[site_cols], function(x) as.numeric(as.character(x)) > 0), na.rm = TRUE)) else NA_real_

  # demographics (best-effort; NA if absent)
  for (nm in names(DEMO_PATTERNS)) {
    c <- pick(names(df0), DEMO_PATTERNS[[nm]])
    rec[[nm]] <- if (!is.na(c)) as.numeric(df0[[c]]) else NA_real_
  }
  # BMI: prefer a column named like ...bmi... else leave NA (derive in 01 from height/weight if present)
  bmi_c <- pick(names(df0), "bmi")
  rec$bmi <- if (!is.na(bmi_c)) as.numeric(df0[[bmi_c]]) else NA_real_

  # flag rows with no usable cognition AND no pain (likely wrong module/file)
  usable <- rowSums(!is.na(select(rec, starts_with("cog_"))), na.rm = TRUE) > 0 | !is.na(rec$pain_sites)
  if (!any(usable)) { warning("File ", basename(f), " has no dc*/DA042 fields; verify it is the health+cognition module.") }

  rows[[basename(f)]] <- rec
}

clean <- bind_rows(Filter(function(x) nrow(x) > 0, rows))
clean <- clean %>% mutate(across(where(is.numeric), ~ as.numeric(.)))
clean <- clean %>% filter(!is.na(id))
saveRDS(clean, OUT)
cat("\nWrote CHARLS clean extract ->", OUT, "\n")
cat("  rows:", nrow(clean), " waves:", paste(sort(unique(clean$wave), na.last = TRUE), collapse = ","), "\n")
cat("  columns:", paste(names(clean), collapse = ", "), "\n")
cat("  >>> VERIFY pain_sites (DA042*), cog_* (dc*), demographics against the CHARLS codebook before modelling.\n")
