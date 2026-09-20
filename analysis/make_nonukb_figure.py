#!/usr/bin/env python3
# make_nonukb_figure.py
# Two-panel forest plot for the non-UKB cognitive-decline sensitivity analysis.
# Panel A: MCP -> cognitive performance (UKB, overlap-limited, primary)
# Panel B: MCP -> all-cause dementia (FinnGen, non-UKB) + MCP -> AD (IGAP, non-UKB)
# Units differ across panels (SD vs log-OR); axes are NOT directly comparable.

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

# (label, beta, se, sig_flag, prov)
A = ("MCP -> Cognitive performance\n(ebi-a-GCST006572, UKB; overlap-limited)", -0.4033, 0.0749, True, "UKB")
B = [
    ("MCP -> All-cause dementia\n(FinnGen F5_DEMENTIA, Finnish, non-UKB)", 0.2339, 0.2134, False, "non-UKB"),
    ("MCP -> Alzheimer's disease\n(ieu-a-298 IGAP, non-UKB consortium)", 0.4658, 0.1749, True, "non-UKB"),
]

def ci(b, se, z=1.96):
    return (b - z*se, b + z*se)

fig, (axA, axB) = plt.subplots(1, 2, figsize=(11, 3.6), gridspec_kw={"width_ratios":[1.15,1]})
fig.suptitle("Non-UKB sensitivity: genetically predicted multisite chronic pain -> cognitive/dementia outcomes",
             fontsize=11, fontweight="bold", y=1.02)

# ---- Panel A: cognitive performance (SD units) ----
labelA, b, se, sig, prov = A
lo, hi = ci(b, se)
axA.axvline(0, color="grey", lw=1, ls="--")
axA.errorbar(b, 0, xerr=[[b-lo],[hi-b]], fmt="o", color="#c0392b" if sig else "#7f8c8d",
             markersize=7, capsize=4, elinewidth=1.6)
axA.text(b, 0.18, f"{b:+.3f}\n[{lo:+.2f}, {hi:+.2f}]", ha="center", fontsize=8.5)
axA.set_ylim(-0.6, 0.6); axA.set_yticks([0]); axA.set_yticklabels([A[0]], fontsize=8.5)
axA.set_xlabel("MR effect on cognitive performance (SD units)\n← worse cognition | better cognition →", fontsize=8.5)
axA.set_title("A. Primary (UKB, overlap-limited)", fontsize=9.5, fontweight="bold")
axA.annotate("p = 3.6e-6", (hi+0.02, 0), fontsize=8, color="#c0392b", va="center")

# ---- Panel B: dementia / AD (log-OR units) ----
axB.axvline(0, color="grey", lw=1, ls="--")
for i, (lab, b, se, sig, prov) in enumerate(B):
    lo, hi = ci(b, se)
    y = len(B)-1-i
    col = "#c0392b" if sig else "#7f8c8d"
    axB.errorbar(b, y, xerr=[[b-lo],[hi-b]], fmt="o", color=col, markersize=7, capsize=4, elinewidth=1.6)
    axB.text(b, y+0.18, f"{b:+.3f} [{lo:+.2f}, {hi:+.2f}]", ha="center", fontsize=8.5)
    axB.text(-1.15, y, lab, ha="left", va="center", fontsize=8.3)
axB.set_ylim(-0.6, len(B)-0.3); axB.set_yticks([])
axB.set_xlim(-1.35, 1.0)
axB.set_xlabel("MR effect on dementia/AD risk (log-odds)\n← lower risk | higher risk →", fontsize=8.5)
axB.set_title("B. Non-UKB cognitive-decline sensitivity", fontsize=9.5, fontweight="bold")
# significance annotations
axB.annotate("p = 0.008 *", (0.47, len(B)-1-i+0.0), fontsize=8, color="#c0392b", va="center")
axB.annotate("p = 0.27 (ns)", (0.23, len(B)-1-0+0.0), fontsize=8, color="#7f8c8d", va="center")

fig.tight_layout()
out = "D:/2026.9/极速交付9月会员日优惠套路/03_观察性研究+孟德尔随机化双验证/孟德尔疼痛/pain-cognition-mr/docs/figures/fig_nonukb_sensitivity.png"
fig.savefig(out, dpi=150, bbox_inches="tight")
print("Wrote", out)
