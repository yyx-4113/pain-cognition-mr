#!/usr/bin/env python3
# run_nonukb_sensitivity.py
# Non-UKB cognitive-decline sensitivity analysis for MCP -> outcomes.
# Methodology mirrors analysis/_recompute_local.R EXACTLY (TwoSampleMR-equivalent
# local estimators), so numbers are directly comparable to
# data/derived/mr_forward_results_corrected.csv.
#
# Files are FORWARD (exposure = MCP, outcome = cognitive-decline trait):
#   mr_harmonized_cog.csv       -> ebi-a-GCST006572  Cognitive performance (UKB, N=257,841)  [OVERLAP]
#   mr_harmonized_dementia.csv  -> FinnGen F5_DEMENTIA All-cause dementia  (Finnish, NON-UKB)
#   mr_harmonized_ad_igap2.csv  -> ieu-a-297 IGAP AD  (international consortium, NON-UKB)
#
# Egger weight = 1/se_y^2 (TwoSampleMR mr_egger convention), NOT the IVW-ratio weight
# that the old make_figures.py mistakenly used.

import csv, math, json
import numpy as np

DER = "D:/2026.9/极速交付9月会员日优惠套路/03_观察性研究+孟德尔随机化双验证/孟德尔疼痛/pain-cognition-mr/data/derived"

def load(path):
    rows = []
    with open(path) as f:
        for r in csv.DictReader(f):
            rows.append(r)
    bx  = np.array([float(r["beta"]) for r in rows])          # MCP exposure
    sex = np.array([float(r["se"]) for r in rows])             # MCP SE
    by  = np.array([float(r["beta_out_adj"]) for r in rows])   # outcome (harmonized)
    sey = np.array([float(r["se_out"]) for r in rows])         # outcome SE
    return bx, sex, by, sey, len(rows)

def ivw_fixed(bx, by, sey):
    w = 1.0 / sey**2
    b = np.sum(w * bx * by) / np.sum(w * bx**2)
    se = 1.0 / math.sqrt(np.sum(w * bx**2))
    p = 2 * (1 - norm_cdf(abs(b / se)))
    return b, se, p

def norm_cdf(x):
    return 0.5 * (1 + math.erf(x / math.sqrt(2)))

def cochran_q(bx, by, sey, b):
    w = 1.0 / sey**2
    Q = np.sum(w * (by - b * bx)**2)
    df = len(bx) - 1
    p = 1 - chi2_cdf(Q, df)
    return Q, df, p

def chi2_cdf(x, df):
    # survival (p-value) = 1 - regularized lower incomplete gamma
    return 1 - lower_gamma(df/2, x/2)

def lower_gamma(a, x):
    # regularized lower incomplete gamma using series (a>0)
    # use math via continued fraction for robustness
    from math import exp
    def gser(a, x):
        gln = math.lgamma(a)
        if x <= 0: return 0.0
        ap = a; sum_ = 1.0/a; del_ = sum_
        for _ in range(200):
            ap += 1; del_ *= x/ap; sum_ += del_
            if abs(del_) < abs(sum_)*1e-12: break
        return sum_ * exp(-x + a*math.log(x) - gln)
    return gser(a, x)

def gammar(a, x):
    return 1 - lower_gamma(a, x)

def ivw_re(bx, by, sey, b_fixed):
    w = 1.0 / sey**2
    Q = np.sum(w * (by - b_fixed * bx)**2)
    df = len(bx) - 1
    tau2 = max(0.0, (Q - df) / (np.sum(w) - np.sum(w**2)/np.sum(w)))
    w2 = 1.0 / (1.0/w + tau2)
    b = np.sum(w2 * bx * by) / np.sum(w2 * bx**2)
    se = 1.0 / math.sqrt(np.sum(w2 * bx**2))
    return b, se, tau2

def egger(bx, by, sey):
    w = 1.0 / sey**2
    WX = np.sum(w*bx); WY = np.sum(w*by); WXX = np.sum(w*bx**2)
    WXY = np.sum(w*bx*by); W = np.sum(w)
    denom = W*WXX - WX**2
    b = (W*WXY - WX*WY)/denom
    a = (WY - b*WX)/W
    se_b = math.sqrt(W/denom)
    se_a = math.sqrt(WXX/denom)
    p_b = 2*(1-norm_cdf(abs(b/se_b)))
    p_a = 2*(1-norm_cdf(abs(a/se_a)))
    return b, se_b, a, se_a, p_a

def wmedian(bx, by, sex, sey):
    g = by / bx
    se_g = np.abs(g) * np.sqrt((sey/by)**2 + (sex/bx)**2)
    w = 1.0 / se_g**2
    ord_ = np.argsort(g)
    cum = np.cumsum(w[ord_]) / np.sum(w)
    idx = np.argmax(cum >= 0.5)
    b = g[ord_][idx]
    se = math.sqrt(1.0 / np.sum(w[ord_][:idx+1]))
    return b, se

def loo(bx, by, sey):
    n = len(bx); bs = np.zeros(n)
    for i in range(n):
        ii = [j for j in range(n) if j != i]
        b, _, _ = ivw_fixed(bx[ii], by[ii], sey[ii])
        bs[i] = b
    return bs.min(), bs.max(), int(np.sum(np.sign(bs) != np.sign(bs[0])))

def instrument_F(bx, sex):
    F = (bx**2) / (sex**2)
    return float(F.mean()), float(F.min())

def analyze(path, label, outcome_provenance):
    bx, sex, by, sey, n = load(path)
    ivb, ivse, ivp = ivw_fixed(bx, by, sey)
    Q, df, Qp = cochran_q(bx, by, sey, ivb)
    reb, rese, tau2 = ivw_re(bx, by, sey, ivb)
    eb, eseb, ea, esea, ep_int = egger(bx, by, sey)
    wb, wse = wmedian(bx, by, sex, sey)
    loo_min, loo_max, loo_flip = loo(bx, by, sey)
    Fmean, Fmin = instrument_F(bx, sex)
    I2 = (Q - df) / Q * 100 if Q > df else 0.0
    print(f"\n=== {label} (n_snps={n}) ===")
    print(f"  IVW fixed : b={ivb:.4f} se={ivse:.4f} p={ivp:.2e}")
    print(f"  IVW RE    : b={reb:.4f} se={rese:.4f} tau2={tau2:.5f}")
    print(f"  Egger     : b={eb:.4f} se={eseb:.4f} int={ea:.5f} int_p={ep_int:.3f}")
    print(f"  WMed      : b={wb:.4f} se={wse:.4f}")
    print(f"  Cochran Q : {Q:.2f} df={df} p={Qp:.2e}  I2={I2:.1f}%")
    print(f"  LOO range : [{loo_min:.4f}, {loo_max:.4f}] flips={loo_flip}")
    print(f"  Instrument F: mean={Fmean:.1f} min={Fmin:.1f}")
    return {
        "outcome": label,
        "provenance": outcome_provenance,
        "n_snps": n,
        "IVW_beta": round(ivb,4), "IVW_se_fixed": round(ivse,4), "IVW_p_fixed": round(ivp,3),
        "IVW_beta_RE": round(reb,4), "IVW_se_RE": round(rese,4),
        "Egger_beta": round(eb,4), "Egger_se": round(eseb,4),
        "Egger_int": round(ea,6), "Egger_int_p": round(ep_int,4),
        "WMed_beta": round(wb,4), "WMed_se": round(wse,4),
        "Cochran_Q": round(Q,2), "Cochran_df": df, "Cochran_p": round(Qp,3), "I2_pct": round(I2,1),
        "LOO_min": round(loo_min,4), "LOO_max": round(loo_max,4), "LOO_flips": loo_flip,
        "F_mean": round(Fmean,1), "F_min": round(Fmin,1),
    }

if __name__ == "__main__":
    results = []
    results.append(analyze(f"{DER}/mr_harmonized_cog.csv",
        "MCP->Cognitive_performance (UKB)", "ebi-a-GCST006572 | UKB | N=257,841 | OVERLAP with MCP"))
    results.append(analyze(f"{DER}/mr_harmonized_dementia.csv",
        "MCP->All_cause_dementia (FinnGen, non-UKB)", "finn-b-F5_DEMENTIA | Finnish | NON-UKB"))
    results.append(analyze(f"{DER}/mr_harmonized_ad_igap2.csv",
        "MCP->Alzheimer_disease (IGAP, non-UKB)", "ieu-a-297 | IGAP consortium | NON-UKB"))

    with open(f"{DER}/mr_nonukb_sensitivity_results.csv", "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=list(results[0].keys()))
        w.writeheader(); w.writerows(results)
    print("\nWrote data/derived/mr_nonukb_sensitivity_results.csv")
    print(json.dumps(results, indent=1))
