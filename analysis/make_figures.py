#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Publication-quality MR figures for the STROBE-MR manuscript.

Standard: high-resolution raster (600 dpi PNG) + vector (PDF/SVG) master;
Arial font; journal palette; weight-scaled forest boxes; IVW/Egger fit lines;
leave-one-out; Wald-ratio funnel. All numbers read from data/derived/*.csv
(single source of truth) so every plotted value is traceable.

Outputs -> docs/figures/
    fig_forest.png/.pdf/.svg   Figure 4  forest (5 directions x 3 methods)
    fig_scatter.png/.pdf/.svg  Figure 5  SNP scatter + MR & MR-Egger lines
    fig_loo.png/.pdf/.svg      Figure 6  leave-one-out
    fig_funnel.png/.pdf/.svg   Figure 7  Wald-ratio funnel
"""

import csv
import os
import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib import font_manager

# --------------------------------------------------------------------------- #
# 1. SCI-typographic / output configuration
# --------------------------------------------------------------------------- #
ROOT = r"D:/2026.9/极速交付9月会员日优惠套路/03_观察性研究+孟德尔随机化双验证/孟德尔疼痛/pain-cognition-mr"
DER = os.path.join(ROOT, "data", "derived")
FIG = os.path.join(ROOT, "docs", "figures")
os.makedirs(FIG, exist_ok=True)

# Register Arial explicitly (Windows ships arial.ttf)
_FONT = r"C:/Windows/Fonts/arial.ttf"
if os.path.exists(_FONT):
    font_manager.fontManager.addfont(_FONT)
    _FAMILY = font_manager.FontProperties(fname=_FONT).get_name()
else:
    _FAMILY = "DejaVu Sans"

matplotlib.rcParams.update({
    "font.family": _FAMILY,
    "font.size": 9,
    "axes.titlesize": 11,
    "axes.labelsize": 10,
    "xtick.labelsize": 8.5,
    "ytick.labelsize": 8.5,
    "axes.linewidth": 0.8,
    "xtick.major.width": 0.8,
    "ytick.major.width": 0.8,
    "xtick.major.size": 3.5,
    "ytick.major.size": 3.5,
    "legend.fontsize": 8.5,
    "legend.frameon": True,
    "legend.edgecolor": "#888888",
    "axes.unicode_minus": False,
    "figure.dpi": 100,          # on-screen; savefig overrides for PNG
})

# Journal-friendly palette
C_SIG   = "#1A4F8B"   # significant (CI excludes 0)  -- strong blue
C_NULL  = "#9AA0A6"   # non-significant             -- neutral gray
C_REF   = "#222222"   # null reference line
C_IVW   = "#B22222"   # MR (IVW) fit line          -- dark red
C_EGGER = "#2E7D32"   # MR-Egger fit line          -- dark green
GRID    = "#D7D7D7"

DPI_PNG = 600

# --------------------------------------------------------------------------- #
# 2. Data loaders
# --------------------------------------------------------------------------- #
def _csv_map(path, key):
    out = {}
    with open(path, newline="") as f:
        for r in csv.DictReader(f):
            out[r[key]] = r
    return out

FW = _csv_map(os.path.join(DER, "mr_forward_results_corrected.csv"), "outcome")
AR = _csv_map(os.path.join(DER, "mr_ad_reverse_results.csv"), "outcome")

# 5 MR directions in display order
LABELS = [
    ("MCP \u2192 Cognitive performance",          FW["MCP->Cognitive_performance"]),
    ("MCP \u2192 All-cause dementia",             FW["MCP->All_cause_dementia"]),
    ("MCP \u2192 Alzheimer\u2019s disease (IGAP)",  AR["ad_igap2"]),
    ("MCP \u2192 Alzheimer\u2019s disease (Ben Nevis)", AR["ad_bennevis"]),
    ("Cognitive performance \u2192 MCP (reverse)", AR["reverse_cog_pain"]),
]

METHODS = [("IVW", "IVW_beta", "IVW_se_fixed"),
           ("Egger", "Egger_beta", "Egger_se"),
           ("WMed", "WMed_beta", "WMed_se")]

# per-SNP harmonized data for scatter / LOO / funnel
xs, ys, sx, sy, rsid = [], [], [], [], []
with open(os.path.join(DER, "mr_harmonized_cog.csv")) as f:
    for r in csv.DictReader(f):
        xs.append(float(r["beta"]))                 # exposure effect
        ys.append(float(r["beta_out_adj"]))         # allele-aligned outcome effect
        sx.append(float(r["se"]))
        sy.append(float(r["se_out"]))
        rsid.append(r["rsid"])
xs = np.array(xs); ys = np.array(ys); sx = np.array(sx); sy = np.array(sy)
n_snp = len(xs)
# IVW ratio weights (precision of outcome / |beta_x|)
w = 1.0 / (sy / np.abs(xs)) ** 2
ivw = float(np.sum(w * (ys / xs)) / np.sum(w))
ivw_se = float(np.sqrt(1.0 / np.sum(w)))

# MR-Egger slope (weighted regression of y on x, intercept free).
# NB: Egger weights MUST include the exposure SE (sx); the IVW ratio weight
# w = 1/(sy/|beta_x|)^2 omits sx and yields a biased slope (~ -0.484 here).
# The correct MR-Egger weight is w_e = 1/(se_y^2 + beta_x^2 * se_x^2), which
# reproduces the formal MR-Egger estimate (beta = -0.362). See manuscript §3.1.
we = 1.0 / (sy ** 2 + (xs ** 2) * (sx ** 2))
xb = np.sum(we * xs) / np.sum(we)
yb = np.sum(we * ys) / np.sum(we)
egger_slope = float(np.sum(we * (xs - xb) * (ys - yb)) / np.sum(we * (xs - xb) ** 2))

# --------------------------------------------------------------------------- #
# 3. Figure 4 -- Forest plot
# --------------------------------------------------------------------------- #
def fmt_est(b, s):
    lo, hi = b - 1.96 * s, b + 1.96 * s
    return f"{b:+.3f} ({lo:+.3f}, {hi:+.3f})"

fig, ax = plt.subplots(figsize=(8.2, 8.2))
# relative precision (1/SE^2) across all method rows -> box size scaling
all_w = np.array([1.0 / float(r[scol]) ** 2
                 for _, r in LABELS for _, _, scol in METHODS])
wmin, wmax = all_w.min(), all_w.max()

y = 0.0
yticks, yticklabels = [], []
for lab, r in LABELS:
    group_base = y
    for mi, (mname, bcol, scol) in enumerate(METHODS):
        b = float(r[bcol]); s = float(r[scol])
        lo, hi = b - 1.96 * s, b + 1.96 * s
        sig = (lo > 0) or (hi < 0)
        col = C_SIG if sig else C_NULL
        yy = group_base - mi * 0.45
        ax.hlines(yy, lo, hi, color=col, lw=1.3, zorder=2)
        wt = 1.0 / s ** 2
        size = 22 + 240 * (wt - wmin) / (wmax - wmin)
        ax.scatter([b], [yy], s=size, color=col, zorder=3,
                   edgecolor="white", linewidth=0.4)
        # blended transform: x in axes coords (right margin), y in data coords
        ax.text(1.03, yy, fmt_est(b, s), transform=ax.get_yaxis_transform(),
                ha="left", va="center", fontsize=8, color="#333333",
                fontfamily=_FAMILY)
        yticks.append(yy)
        yticklabels.append(("   " + mname) if mi else lab)
    y = group_base - 0.45 * (len(METHODS) - 1) - 0.75

ax.axvline(0, color=C_REF, lw=1.0, ls="--", zorder=1)
ax.set_yticks(yticks)
ax.set_yticklabels(yticklabels)
ax.set_xlabel("MR causal estimate  \u03b2 (95% CI)")
ax.set_title("Figure 4. Two-sample Mendelian randomization estimates\n"
             "MCP = multisite chronic pain; box area proportional to 1/SE\u00b2",
             fontsize=11, loc="left")
# x-range with room for estimate text
xlo = min(min(float(r[METHODS[0][1]]) - 1.96 * float(r[METHODS[0][2]]) for _, r in LABELS),
          min(float(r[METHODS[2][1]]) - 1.96 * float(r[METHODS[2][2]]) for _, r in LABELS))
xhi = max(max(float(r[METHODS[0][1]]) + 1.96 * float(r[METHODS[0][2]]) for _, r in LABELS),
          max(float(r[METHODS[2][1]]) + 1.96 * float(r[METHODS[2][2]]) for _, r in LABELS))
ax.set_xlim(xlo - 0.06 * (xhi - xlo), xhi + 0.42 * (xhi - xlo))
ax.grid(axis="x", color=GRID, lw=0.6, zorder=0)

from matplotlib.lines import Line2D
leg = [Line2D([0], [0], color=C_SIG, lw=1.3, marker="s", markersize=7,
              markerfacecolor=C_SIG, label="CI excludes 0 (significant)"),
       Line2D([0], [0], color=C_NULL, lw=1.3, marker="s", markersize=7,
              markerfacecolor=C_NULL, label="CI includes 0 (NS)")]
ax.legend(handles=leg, loc="upper center", bbox_to_anchor=(0.5, -0.055),
          ncol=2, fontsize=8.5, framealpha=0.95)
for ext in ("png", "pdf", "svg"):
    dpi = DPI_PNG if ext == "png" else 100
    fig.savefig(os.path.join(FIG, f"fig_forest.{ext}"), dpi=dpi,
                bbox_inches="tight", pad_inches=0.04)
plt.close(fig)
print("wrote fig_forest.{png,pdf,svg}")

# --------------------------------------------------------------------------- #
# 4. Figure 5 -- SNP scatter + IVW & MR-Egger lines
# --------------------------------------------------------------------------- #
fig, ax = plt.subplots(figsize=(6.6, 5.4))
ax.scatter(xs, ys, s=34, color=C_SIG, alpha=0.78, edgecolor="white",
           linewidth=0.45, zorder=3, label=f"{n_snp} independent SNPs")
xr = np.linspace(xs.min(), xs.max(), 100)
ax.plot(xr, ivw * xr, color=C_IVW, lw=2.0, zorder=2,
        label=f"MR (IVW)  slope = {ivw:.3f}")
ax.plot(xr, (yb - egger_slope * xb) + egger_slope * xr, color=C_EGGER,
        lw=1.6, ls="--", zorder=2,
        label=f"MR-Egger  slope = {egger_slope:.3f}")
ax.axhline(0, color=C_REF, lw=0.7, ls=":")
ax.axvline(0, color=C_REF, lw=0.7, ls=":")
ax.set_xlabel("SNP effect on MCP (exposure  \u03b2_x)")
ax.set_ylabel("SNP effect on cognition (outcome  \u03b2_y)")
ax.set_title("Figure 5. SNP-level associations: MCP \u2192 cognition",
             fontsize=11, loc="left")
ax.legend(loc="upper right", fontsize=8.5, framealpha=0.95)
ax.grid(color=GRID, lw=0.6, zorder=0)
fig.tight_layout()
for ext in ("png", "pdf", "svg"):
    dpi = DPI_PNG if ext == "png" else 100
    fig.savefig(os.path.join(FIG, f"fig_scatter.{ext}"), dpi=dpi,
                bbox_inches="tight", pad_inches=0.04)
plt.close(fig)
print("wrote fig_scatter.{png,pdf,svg}")

# --------------------------------------------------------------------------- #
# 5. Figure 6 -- Leave-one-out
# --------------------------------------------------------------------------- #
loo_b, loo_s = [], []
for i in range(n_snp):
    m = np.ones(n_snp, bool); m[i] = False
    b = np.sum(w[m] * (ys[m] / xs[m])) / np.sum(w[m])
    se = np.sqrt(1.0 / np.sum(w[m]))
    loo_b.append(b); loo_s.append(se)
loo_b = np.array(loo_b); loo_s = np.array(loo_s)

fig, ax = plt.subplots(figsize=(8.0, 4.6))
ax.errorbar(np.arange(n_snp), loo_b, yerr=1.96 * loo_s, fmt="o", ms=4.5,
            color=C_SIG, ecolor="#9EC5E8", elinewidth=1.0, capsize=2.0,
            zorder=3, label="Leave-one-out IVW")
ax.axhline(ivw, color=C_IVW, lw=1.8, ls="--", zorder=2,
           label=f"Full IVW = {ivw:.3f}")
ax.set_xlabel(f"Left-out SNP (index, n = {n_snp})")
ax.set_ylabel("IVW \u03b2 leaving one SNP out")
ax.set_title("Figure 6. Leave-one-out sensitivity analysis (MCP \u2192 cognition)",
             fontsize=11, loc="left")
ax.set_xticks([])
ax.legend(loc="best", fontsize=8.5, framealpha=0.95)
ax.grid(axis="y", color=GRID, lw=0.6, zorder=0)
fig.tight_layout()
for ext in ("png", "pdf", "svg"):
    dpi = DPI_PNG if ext == "png" else 100
    fig.savefig(os.path.join(FIG, f"fig_loo.{ext}"), dpi=dpi,
                bbox_inches="tight", pad_inches=0.04)
plt.close(fig)
print(f"wrote fig_loo.{{png,pdf,svg}}  LOO range [{loo_b.min():.3f}, {loo_b.max():.3f}]")

# --------------------------------------------------------------------------- #
# 6. Figure 7 -- Wald-ratio funnel
# --------------------------------------------------------------------------- #
wal = ys / xs                              # per-SNP Wald ratio
wal_se = np.abs(wal) * np.sqrt((sx / xs) ** 2 + (sy / ys) ** 2)
overall = ivw
xr_f = np.linspace(wal.min(), wal.max(), 200)
fig, ax = plt.subplots(figsize=(6.6, 5.4))
# Standard funnel: y = SE (inverted, small SE at top), arms at
# overall +/- 1.96*SE (95% pseudo-CI) and overall +/- 3.29*SE (99% pseudo-CI)
se_grid = np.linspace(0, wal_se.max() * 1.05, 200)
ax.plot(overall + 1.96 * se_grid, se_grid, color=GRID, lw=1.0, ls="--")
ax.plot(overall - 1.96 * se_grid, se_grid, color=GRID, lw=1.0, ls="--")
ax.plot(overall + 3.29 * se_grid, se_grid, color=GRID, lw=0.8, ls=":")
ax.plot(overall - 3.29 * se_grid, se_grid, color=GRID, lw=0.8, ls=":")
ax.scatter(wal, wal_se, s=32, color=C_SIG, alpha=0.78, edgecolor="white",
           linewidth=0.45, zorder=3)
ax.axvline(0, color=C_REF, lw=0.7, ls=":")
ax.axvline(overall, color=C_IVW, lw=1.4, ls="--",
           label=f"IVW = {overall:.3f}")
ax.set_xlabel("Per-SNP Wald ratio (cognition / MCP)")
ax.set_ylabel("Standard error of Wald ratio")
ax.set_title("Figure 7. Funnel plot of per-SNP Wald ratios (MCP \u2192 cognition)",
             fontsize=11, loc="left")
ax.invert_yaxis()   # SE increases downward (classic funnel)
ax.legend(loc="upper right", fontsize=8.5, framealpha=0.95)
ax.grid(axis="x", color=GRID, lw=0.6, zorder=0)
fig.tight_layout()
for ext in ("png", "pdf", "svg"):
    dpi = DPI_PNG if ext == "png" else 100
    fig.savefig(os.path.join(FIG, f"fig_funnel.{ext}"), dpi=dpi,
                bbox_inches="tight", pad_inches=0.04)
plt.close(fig)
print("wrote fig_funnel.{png,pdf,svg}")
print("DONE")
