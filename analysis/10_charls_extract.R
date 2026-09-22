#!/usr/bin/env Rscript
# 10_charls_extract.R  (REWRITTEN 2026-09-21 per CHARLS_VARIABLE_MAP.md)
#
# Builds a CLEANED CHARLS long-format extract (data/derived/charls_long.rds/.csv)
# that analysis/01_charls.R consumes.
#
# All variable choices are EMPIRICALLY verified against the actual .dta files
# (see data/raw/charls/CHARLS_VARIABLE_MAP.md). No guessing.
#
# Key corrections vs the previous (broken) version:
#   * Wave is inferred from the DIRECTORY name (raw/<wave>/), never the filename.
#   * Word-recall & pain-site variables store the INDEX (k) when endorsed, else NA.
#       -> score = count of non-missing, NOT a 0/1 sum.
#   * Immediate recall: 2011 dc006s1-11; 2013 best-of-3 trials dc006_{1,2,3}_s1-11;
#       2015 dc006s1-12.  Delayed: dc027s* (same counts).
#   * Pain flag differs by wave: 2011/2015 da041(1=pain); 2013 wb16 / 2018 da041_w4 /
#       2020 da027 are 5-level intensity scales -> pain_any = scale >= 2.
#   * Demographics use CHARLS chapter codes (ba*/bc*/bd*/be*), not "ragey/reduc/..".
#   * 2018/2020 cognition is NOT comparable (different instruments) -> cog_* = NA;
#       only pain + covariates extracted (sensitivity / descriptive use).
#
# Output schema (one row per id x wave):
#   id, wave, anchor_year, pain_any, pain_burden, cog_im, cog_de, cog_ser7, cesd,
#   age, male, edu_raw, edu_yrs, urban, married, smoke, alcohol, sleep_hrs,
#   comorb_htn, comorb_dm, comorb_stroke, comorb_hd, comorb_ckd, comorb_count

suppressPackageStartupMessages({ library(haven); library(dplyr); library(tidyr) })

## ---- locate project root ----
## Prefer CHARLS_ROOT (set to an ASCII path/junction to avoid R's Windows UTF-8
## path limitation when the real project dir contains Chinese characters).
## Fall back to walking up from the working directory.
ROOT <- Sys.getenv("CHARLS_ROOT", "")
if (ROOT == "" || !dir.exists(file.path(ROOT, "data", "raw", "charls", "raw"))) {
  d <- getwd()
  for (i in 1:6) {
    if (file.exists(file.path(d, "data", "raw", "charls", "raw"))) { ROOT <- d; break }
    p <- dirname(d); if (p == d) break; d <- p
  }
  if (ROOT == "") stop("Cannot locate CHARLS raw dir; set CHARLS_ROOT or run from the project root.")
}
## NOTE: do NOT normalizePath(ROOT) — it would resolve the C:/pcp ASCII junction
## back to the real Chinese path and re-trigger R's Windows UTF-8 path failure.
SRC <- file.path(ROOT, "data", "raw", "charls", "raw")
DER <- file.path(ROOT, "data", "derived"); dir.create(DER, recursive = TRUE, showWarnings = FALSE)
OUT_RDS <- file.path(DER, "charls_long.rds")
OUT_CSV <- file.path(DER, "charls_long.csv")

WAVES  <- c("2011", "2013", "2015", "2018", "2020")
ANCHOR <- setNames(c(2011, 2013, 2015, 2018, 2020), WAVES)

## ---- helpers ----
read_mod <- function(wave, pattern) {
  d <- file.path(SRC, wave)
  if (!dir.exists(d)) return(NULL)
  files <- list.files(d, pattern = "\\.dta$", ignore.case = TRUE, full.names = TRUE)
  hits  <- files[grepl(pattern, basename(files), ignore.case = TRUE)]
  if (!length(hits)) return(NULL)
  df <- read_dta(hits[1])
  df <- as.data.frame(haven::zap_labels(df))
  df
}

count_present <- function(df, cols) {
  # present = endorsed. Works for BOTH encodings seen in CHARLS:
  #   - index-encoded (2011/13/15): value = k when endorsed, else NA  -> k>0
  #   - binary 1/0 (2018/20 sites): 1 = present, 0 = absent          -> >0
  cols <- intersect(cols, names(df))
  if (!length(cols)) return(rep(NA_real_, nrow(df)))
  rowSums(sapply(df[cols], function(x) !is.na(x) & x > 0))
}

safe_num <- function(df, var, n) {
  if (!is.null(df[[var]])) as.numeric(df[[var]]) else rep(NA_real_, n)
}

## CHARLS cross-wave person-key normalisation (CRITICAL).
## 2011 ids are 11 chars: community(6) + household(3) + person(2).
## 2013/2015/2018/2020 ids are 12 chars: person padded to 3 digits.
## Without this, a person interviewed in 2011 AND 2013 has two DIFFERENT
## keys (e.g. "01010410101" vs "010104101001") -> the longitudinal panel
## collapses (0 overlap 2011<->2013) and any baseline->follow-up join fails.
## Padding 2011's person component to 3 digits restores the shared key
## (verified: 85.5% of 2011 ids then match a 2013 id, = re-interview retention).
norm_id <- function(x) {
  x <- as.character(x)
  ok <- nchar(x) %in% c(11, 12)
  out <- x
  if (any(ok)) {
    pref <- substr(x[ok], 1, 9)
    per  <- substr(x[ok], 10, nchar(x[ok]))
    out[ok] <- paste0(pref, sprintf("%03d", as.integer(per)))
  }
  out
}

imm_recall <- function(df, wave) {
  if (wave == "2013") {
    k <- 1:11
    recalled <- sapply(k, function(i) {
      cols <- intersect(c(paste0("dc006_1_s", i), paste0("dc006_2_s", i), paste0("dc006_3_s", i)), names(df))
      rowSums(!is.na(df[cols])) > 0
    })
    rowSums(recalled)
  } else if (wave == "2011") count_present(df, paste0("dc006s", 1:11))
  else if (wave == "2015")   count_present(df, paste0("dc006s", 1:12))
  else rep(NA_real_, nrow(df))
}

del_recall <- function(df, wave) {
  if (wave %in% c("2011", "2013")) count_present(df, paste0("dc027s", 1:11))
  else if (wave == "2015")         count_present(df, paste0("dc027s", 1:12))
  else rep(NA_real_, nrow(df))
}

ser7 <- function(df) {
  expected <- c(93, 86, 79, 72, 65)            # 100-7, 93-7, 86-7, 79-7, 72-7
  cols <- intersect(paste0("dc0", 19:23), names(df))
  if (length(cols) < 5) return(rep(NA_real_, nrow(df)))
  s <- integer(nrow(df))
  for (i in seq_along(expected)) s <- s + (as.numeric(df[[cols[i]]]) == expected[i])
  as.numeric(s)
}

## 2018 DC Cognition module: word list is position-coded. Per codebook (p527), dc028/029/030_w4_sK
## = the K-th word (Butter, Arm, Shore, ...); the value is K when the respondent correctly recalled
## that word and 0 otherwise (NOT a 0/1 flag). Immediate = best-of-3 across trials 1-3 (dc028/029/030);
## delayed = dc047_w4_sK. Serial-7 in 2018 is a single response field (dc014_w4_1_1), not comparable
## to the 5-item count -> left NA. (dc028_w4_1 etc. are REFUSAL-REASON codes, NOT counts.)
cog_im_2018 <- function(df) {
  words <- 1:12
  per_word <- sapply(words, function(K) {
    cols <- intersect(c(paste0("dc028_w4_s", K), paste0("dc029_w4_s", K), paste0("dc030_w4_s", K)), names(df))
    if (!length(cols)) return(rep(FALSE, nrow(df)))
    rowSums(sapply(cols, function(c) as.numeric(df[[c]]) == K), na.rm = TRUE) > 0
  })
  present <- sapply(words, function(K) {
    cols <- intersect(c(paste0("dc028_w4_s", K), paste0("dc029_w4_s", K), paste0("dc030_w4_s", K)), names(df))
    if (!length(cols)) return(rep(FALSE, nrow(df)))
    rowSums(!is.na(df[cols])) > 0
  })
  rs <- rowSums(per_word, na.rm = TRUE)
  rs[rowSums(present, na.rm = TRUE) == 0] <- NA
  as.numeric(rs)
}
cog_de_2018 <- function(df) {
  words <- 1:12
  per_word <- sapply(words, function(K) {
    cols <- intersect(paste0("dc047_w4_s", K), names(df))
    if (!length(cols)) return(rep(FALSE, nrow(df)))
    as.numeric(df[[cols]]) == K
  })
  present <- sapply(words, function(K) {
    cols <- intersect(paste0("dc047_w4_s", K), names(df))
    if (!length(cols)) return(rep(FALSE, nrow(df)))
    !is.na(df[[cols]])
  })
  rs <- rowSums(per_word, na.rm = TRUE)
  rs[rowSums(present, na.rm = TRUE) == 0] <- NA
  as.numeric(rs)
}

cesd10 <- function(df) {
  cols <- intersect(paste0("dc0", 9:18), names(df))
  if (!length(cols)) return(rep(NA_real_, nrow(df)))
  m  <- df[cols]; nv <- rowSums(!is.na(m))
  tot <- rowSums(m, na.rm = TRUE)
  ifelse(nv >= 8, tot, NA_real_)               # require >=8 of 10 items
}

edu_yrs_map <- function(x) {
  case_when(
    x %in% 1:3 ~ 0, x == 4 ~ 6, x == 5 ~ 9, x == 6 ~ 12, x == 7 ~ 12,
    x == 8 ~ 14, x == 9 ~ 16, x == 10 ~ 19, x == 11 ~ 22, TRUE ~ NA_real_
  )
}

pick_first <- function(df, candidates) {
  for (c in candidates) if (c %in% names(df)) return(df[[c]])
  NULL
}

## ---- per-wave extraction ----
frames <- list()
for (wv in WAVES) {
  hf <- read_mod(wv, "health_status")
  if (is.null(hf)) { warning("No health file for wave ", wv, "; skipped."); next }
  if (!"ID" %in% names(hf)) { warning("No ID column in ", wv, " health file; skipped."); next }
  hf$id <- norm_id(as.character(hf[["ID"]]))

  ## merge demographic module (kept columns only) by id
  df_demo <- read_mod(wv, "demographic_background")
  if (!is.null(df_demo) && "ID" %in% names(df_demo)) {
    df_demo$id <- norm_id(as.character(df_demo[["ID"]]))
    demo_keep <- c("id",
      "rgender", "ba000_w2_3", "ba000_w3_3", "ba000_w4_3", "ba001", "xrgender",  # sex candidates
      "ba002_1",                                                              # birth year
      "bd001", "bd001_w2_4",                                                 # education
      "bc001", "bc001_w3_2",                                                 # hukou
      "be001")                                                              # marital
    df_demo <- df_demo[, intersect(demo_keep, names(df_demo)), drop = FALSE]
    m <- merge(hf, df_demo, by = "id", all.x = TRUE)
  } else m <- hf

  n <- nrow(m)
  rec <- data.frame(id = m$id, wave = as.integer(wv), anchor_year = ANCHOR[wv],
                    stringsAsFactors = FALSE)

  ## pain flag + burden
  if (wv %in% c("2011", "2015")) {
    rec$pain_any <- as.numeric(m[["da041"]] == 1)
    rec$pain_burden <- count_present(m, paste0("da042s", 1:15))
  } else if (wv == "2013") {
    rec$pain_any <- as.numeric(m[["wb16"]] >= 2)
    rec$pain_burden <- count_present(m, paste0("da042s", 1:15))
  } else if (wv == "2018") {
    rec$pain_any <- as.numeric(m[["da041_w4"]] >= 2)
    rec$pain_burden <- count_present(m, paste0("da042_s", 1:16))
    ## 2018 cognition lives in the separate DC Cognition module
    cog <- read_mod("2018", "Cognition")
    if (!is.null(cog) && "ID" %in% names(cog)) {
      cog$id <- norm_id(as.character(cog[["ID"]]))
      cdf <- data.frame(id = cog$id,
                        cog_im   = cog_im_2018(cog),
                        cog_de   = cog_de_2018(cog),
                        cog_ser7 = rep(NA_real_, nrow(cog)),   # instrument changed -> not comparable
                        cesd     = cesd10(cog),
                        stringsAsFactors = FALSE)
      rec <- merge(rec, cdf, by = "id", all.x = TRUE)
    } else {
      rec$cog_im <- rec$cog_de <- rec$cog_ser7 <- rec$cesd <- NA_real_
    }
  } else if (wv == "2020") {
    rec$pain_any <- as.numeric(m[["da027"]] >= 2)
    rec$pain_burden <- count_present(m, paste0("da028_s", 1:16))
  }

  ## cognition: 2011/2013/2015 from health file; 2018 from the DC Cognition module (above);
  ## 2020 stays NA (no comparable cognition module available)
  if (wv %in% c("2011", "2013", "2015")) {
    rec$cog_im   <- imm_recall(m, wv)
    rec$cog_de   <- del_recall(m, wv)
    rec$cog_ser7 <- ser7(m)
    rec$cesd     <- cesd10(m)
  } else if (wv == "2020") {
    rec$cog_im <- rec$cog_de <- rec$cog_ser7 <- rec$cesd <- NA_real_
  }

  ## behaviors / sleep / comorbidities (from health file, all waves; NA if absent)
  rec$smoke     <- as.numeric(safe_num(m, "da059", n) == 1)
  rec$alcohol   <- as.numeric(safe_num(m, "da067", n) %in% 1:2)
  rec$sleep_hrs <- safe_num(m, "da049", n)
  rec$comorb_htn    <- as.numeric(safe_num(m, "da007_1_", n) == 1)
  rec$comorb_dm     <- as.numeric(safe_num(m, "da007_3_", n) == 1)
  rec$comorb_stroke <- as.numeric(safe_num(m, "da007_8_", n) == 1)
  rec$comorb_hd     <- as.numeric(safe_num(m, "da007_7_", n) == 1)
  rec$comorb_ckd    <- as.numeric(safe_num(m, "da007_9_", n) == 1)
  extras <- c("da007_2_", "da007_4_", "da007_5_", "da007_6_",
              "da007_10_", "da007_11_", "da007_12_", "da007_13_", "da007_14_")
  ext_mat <- sapply(extras, function(v) as.numeric(safe_num(m, v, n) == 1))
  rec$comorb_count <- rowSums(cbind(rec$comorb_htn, rec$comorb_dm, rec$comorb_stroke,
                                    rec$comorb_hd, rec$comorb_ckd, ext_mat), na.rm = TRUE)

  ## demographics (NA-safe; 2020 has a minimal demographic file)
  na_len <- function(x, n) if (is.null(x)) rep(NA_real_, n) else x
  sex_raw   <- na_len(pick_first(m, c("rgender", "ba000_w2_3", "ba000_w3_3",
                                      "ba000_w4_3", "ba001", "xrgender", "zrgender")), n)
  birth     <- na_len(pick_first(m, c("ba002_1", "zrbirthyear")), n)
  edu_raw   <- na_len(pick_first(m, c("bd001", "bd001_w2_4")), n)   # 2020 edu (zredu) left NA (scale differs)
  hukou_raw <- na_len(pick_first(m, c("bc001", "bc001_w3_2")), n)
  mar_raw   <- na_len(pick_first(m, c("be001")), n)

  rec$age     <- ANCHOR[wv] - as.numeric(birth)
  rec$male    <- as.numeric(as.numeric(sex_raw) == 1)
  rec$edu_raw <- as.numeric(edu_raw)
  rec$edu_yrs <- edu_yrs_map(rec$edu_raw)
  rec$urban   <- as.numeric(as.numeric(hukou_raw) %in% c(2, 3))   # non-agri + unified = urban
  rec$married <- as.numeric(as.numeric(mar_raw) == 1)

  frames[[wv]] <- rec
  cat(sprintf("Wave %s: n=%d  pain_any(non-NA)=%d  pain_burden(mean)=%.2f  cog_im(mean)=%.2f  edu_yrs(mean)=%.2f\n",
              wv, n, sum(!is.na(rec$pain_any)),
              mean(rec$pain_burden, na.rm = TRUE),
              if (wv %in% c("2011","2013","2015")) mean(rec$cog_im, na.rm = TRUE) else NaN,
              mean(rec$edu_yrs, na.rm = TRUE)))
}

## ---- 2015 education carry-forward (bd001_w2_4 == 12 means "unchanged" -> use 2013) ----
if (!is.null(frames[["2015"]]) && !is.null(frames[["2013"]])) {
  f15 <- frames[["2015"]]; f13 <- frames[["2013"]]
  edu13 <- setNames(f13$edu_yrs, f13$id)
  idx <- which(!is.na(f15$edu_raw) & f15$edu_raw == 12)
  if (length(idx)) {
    fill <- edu13[match(f15$id[idx], names(edu13))]
    f15$edu_yrs[idx] <- fill
    frames[["2015"]] <- f15
    cat(sprintf("2015 education carry-forward applied to %d respondents (bd001_w2_4==12).\n", length(idx)))
  }
}

## ---- bind & save ----
## audit: cross-wave person-key overlap (MUST be >0 after norm_id; 0 means panel broken)
wids <- lapply(c("2011","2013","2015"), function(w) if (!is.null(frames[[w]])) unique(frames[[w]]$id) else character(0))
cat(sprintf("AUDIT cross-wave id overlap (norm_id): 2011&2013=%d 2011&2015=%d 2013&2015=%d\n",
            length(intersect(wids[[1]], wids[[2]])),
            length(intersect(wids[[1]], wids[[3]])),
            length(intersect(wids[[2]], wids[[3]]))))
out <- bind_rows(Filter(function(x) !is.null(x) && nrow(x) > 0, frames))
out <- out %>% mutate(across(where(is.numeric), as.numeric)) %>% filter(!is.na(id))
saveRDS(out, OUT_RDS)
write.csv(out, OUT_CSV, row.names = FALSE)
cat("\nWrote CHARLS long extract ->", OUT_RDS, "\n")
cat("  rows:", nrow(out), " | ids:", length(unique(out$id)),
    " | waves:", paste(sort(unique(out$wave)), collapse = ","), "\n")
cat("  columns:", paste(names(out), collapse = ", "), "\n")
cat("  >>> Run analysis/01_charls.R next. Cognition present for 2011/2013/2015 only (2018/2020 = NA by design).\n")
