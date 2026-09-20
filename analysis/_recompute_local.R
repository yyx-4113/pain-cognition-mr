suppressMessages({ library(data.table) })

## work around data.table fread/fwrite UTF-8 path issue on Windows:
## inputs/outputs use ASCII C:/Windows/Temp path; copy back via shell afterwards
DER  <- "C:/Windows/Temp/mr_recompute"

## ---- local MR estimators (no API) -----------------------------------------
ivw_fixed <- function(bx, by, sey) {
  w <- 1 / sey^2
  b <- sum(w * bx * by) / sum(w * bx^2)
  se <- 1 / sqrt(sum(w * bx^2))
  list(b = b, se = se)
}

cochran_q <- function(bx, by, sey, b) {
  w <- 1 / sey^2
  Q <- sum(w * (by - b * bx)^2)
  df <- length(bx) - 1
  p <- pchisq(Q, df, lower.tail = FALSE)
  list(Q = Q, df = df, p = p)
}

ivw_re <- function(bx, by, sey, b_fixed) {
  w <- 1 / sey^2
  Q <- sum(w * (by - b_fixed * bx)^2)
  df <- length(bx) - 1
  tau2 <- max(0, (Q - df) / (sum(w) - sum(w^2) / sum(w)))
  w2 <- 1 / (1 / w + tau2)
  b <- sum(w2 * bx * by) / sum(w2 * bx^2)
  se <- 1 / sqrt(sum(w2 * bx^2))
  list(b = b, se = se, tau2 = tau2)
}

egger <- function(bx, by, sey) {
  w <- 1 / sey^2
  # weighted least squares: by = a + b*bx
  WX <- sum(w * bx); WY <- sum(w * by); WXX <- sum(w * bx^2)
  WXY <- sum(w * bx * by); W <- sum(w)
  denom <- W * WXX - WX^2
  b <- (W * WXY - WX * WY) / denom
  a <- (WY - b * WX) / W
  se_b <- sqrt(W / denom)
  se_a <- sqrt(WXX / denom)
  p_b <- 2 * pnorm(-abs(b / se_b))
  p_a <- 2 * pnorm(-abs(a / se_a))
  list(slope = b, se_slope = se_b, intercept = a, se_int = se_a, p_int = p_a)
}

wmedian <- function(bx, by, sex, sey) {
  g <- by / bx
  # SE of each Wald ratio (delta method, both exposure & outcome error)
  se_g <- abs(g) * sqrt((sey / by)^2 + (sex / bx)^2)
  w <- 1 / se_g^2
  ord <- order(g)
  cum <- cumsum(w[ord]) / sum(w)
  idx <- which(cum >= 0.5)[1]
  list(b = g[ord][idx], se = sqrt(1 / sum(w[ord][1:idx])))
}

loo <- function(bx, by, sey) {
  n <- length(bx); bs <- numeric(n)
  for (i in seq_len(n)) {
    ii <- setdiff(seq_len(n), i)
    bs[i] <- ivw_fixed(bx[ii], by[ii], sey[ii])$b
  }
  list(beta = bs, min = min(bs), max = max(bs),
       n_flip = sum(sign(bs) != sign(bs[1])))
}

## ---- process one outcome ----------------------------------------------------
analyze <- function(csv, label, steiger_v) {
  d <- fread(csv)
  bx <- d$beta; by <- d$beta_out_adj; sex <- d$se; sey <- d$se_out
  iv  <- ivw_fixed(bx, by, sey)
  q   <- cochran_q(bx, by, sey, iv$b)
  re  <- ivw_re(bx, by, sey, iv$b)
  eg  <- egger(bx, by, sey)
  wm  <- wmedian(bx, by, sex, sey)
  l   <- loo(bx, by, sey)
  cat(sprintf("\n=== %s (n=%d) ===\n", label, nrow(d)))
  cat(sprintf("  IVW fixed : b=%.4f se=%.4f p=%.2e\n", iv$b, iv$se, 2*pnorm(-abs(iv$b/iv$se))))
  cat(sprintf("  IVW RE    : b=%.4f se=%.4f tau2=%.4f\n", re$b, re$se, re$tau2))
  cat(sprintf("  Egger     : b=%.4f se=%.4f int=%.4f int_p=%.3f\n", eg$slope, eg$se_slope, eg$intercept, eg$p_int))
  cat(sprintf("  WMed(corr): b=%.4f se=%.4f\n", wm$b, wm$se))
  cat(sprintf("  Cochran Q : %.2f df=%d p=%.2e\n", q$Q, q$df, q$p))
  cat(sprintf("  LOO range : [%.4f, %.4f] flips=%d\n", l$min, l$max, l$n_flip))
  data.frame(
    outcome = label, n_snps = nrow(d),
    IVW_beta = round(iv$b, 4), IVW_se_fixed = round(iv$se, 4),
    IVW_p_fixed = signif(2*pnorm(-abs(iv$b/iv$se)), 3),
    IVW_beta_RE = round(re$b, 4), IVW_se_RE = round(re$se, 4),
    Egger_beta = round(eg$slope, 4), Egger_se = round(eg$se_slope, 4),
    Egger_int = round(eg$intercept, 6), Egger_int_p = round(eg$p_int, 4),
    WMed_beta = round(wm$b, 4), WMed_se = round(wm$se, 4),
    Cochran_Q = round(q$Q, 2), Cochran_df = q$df, Cochran_p = signif(q$p, 3),
    LOO_min = round(l$min, 4), LOO_max = round(l$max, 4), LOO_flips = l$n_flip,
    Steiger_Vexp = steiger_v$Vexp, Steiger_Vout = steiger_v$Vout,
    Steiger_dir = steiger_v$dir, Steiger_p = steiger_v$p,
    stringsAsFactors = FALSE)
}

## Steiger values carried from the validated API run (data unchanged)
steig_cog <- list(Vexp = 0.003520667, Vout = 0.001445403, dir = "X->Y", p = 0.2305676)
steig_dem <- list(Vexp = 0.003658947, Vout = 0.0001849386, dir = "X->Y", p = 0.2088647)

res_cog <- analyze(file.path(DER, "cog.csv"), "MCP->Cognitive_performance", steig_cog)
res_dem <- analyze(file.path(DER, "dem.csv"), "MCP->All_cause_dementia", steig_dem)

out <- rbind(res_cog, res_dem)
fwrite(out, file.path(DER, "mr_forward_results_corrected.csv"))
cat("\nWrote /tmp/mr_recompute/mr_forward_results_corrected.csv\n")
print(out)
