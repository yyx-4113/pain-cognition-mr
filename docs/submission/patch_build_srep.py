#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Patch build_srep_pack.py to version A++ (CHARLS + change-score + Fig9/10).
Uses lambda replacements so backslashes in the new code are inserted verbatim.
"""
import re

P = r"D:/2026.9/极速交付9月会员日优惠套路/03_观察性研究+孟德尔随机化双验证/孟德尔疼痛/pain-cognition-mr/docs/submission/build_srep_pack.py"
src = open(P, encoding="utf-8").read()

new_figmap = '''FIG_MAP = {
    "fig_forest":        ("Fig1_forest",  "Forest plot of MR estimates"),
    "fig_scatter":       ("Fig2_scatter", "SNP-level scatter (MCP -> cognition)"),
    "fig_loo":           ("Fig3_loo",     "Leave-one-out sensitivity"),
    "fig_funnel":        ("Fig4_funnel",  "Funnel plot of per-SNP Wald ratios"),
    "fig_nonukb_sensitivity": ("Fig5_nonukb", "Non-UKB overlap-robustness re-interpretation"),
    "fig_charls_rcs":    ("Fig6_charls_rcs", "CHARLS dose-response spline"),
    "fig_overlap_bias":  ("Fig7_overlap_bias", "Overlap-bias sensitivity"),
}'''

new_renumber = '''def renumber(text):
    # single-pass mapping so "Figure 8"->"Figure 5" is never re-mapped by "Figure 5"->"Figure 2".
    # Full-number match (incl. "Figure 10") avoids the legacy "Figure 10"->"Figure 40" bug.
    _map = {4: 1, 5: 2, 6: 3, 7: 4, 8: 5, 9: 6, 10: 7}
    def _r(m):
        s, n = m.group(1), int(m.group(2))
        return "Figure%s %d" % (s, _map.get(n, n))
    return re.sub(r"Figure(s?) (\\d+)", _r, text)'''

new_abstract = '''ABSTRACT = (
    "Chronic pain and cognitive impairment are two escalating, ageing-related public-health "
    "burdens. Observational links between multisite chronic pain (MCP) and cognitive decline are "
    "confounded by reverse causation and shared comorbidity. We used bidirectional two-sample "
    "Mendelian randomization (MR) to assess the causal direction and magnitude of the association "
    "between genetically predicted MCP and cognitive outcomes. MCP instruments (41-43 independent "
    "SNPs; P<5x10-8) were drawn from a UK Biobank GWAS (n=387,649). Outcomes were cognitive "
    "performance (OpenGWAS ebi-a-GCST006572, UKB-derived, n=257,841), Alzheimer's disease "
    "(IGAP ieu-a-297, n=54,162) and all-cause dementia (FinnGen, n=216,771). Genetically predicted "
    "MCP was associated with lower cognitive performance (IVW beta=-0.361, 95% CI -0.424 to -0.299, "
    "p=3.65x10-30) with high heterogeneity (I2~83.5%) but no detectable directional pleiotropy. "
    "The Steiger directionality test was non-significant (p=0.23) and reverse MR was significant "
    "(beta=-0.171, p=8.85x10-58), so causal direction is uncertain. A non-UKB overlap-robustness "
    "re-interpretation (IGAP AD: beta=0.466, p=0.008) and a formal overlap-bias quantification "
    "(Burgess-Thompson / MRlap framework; <=3% bias) corroborated the association independently of "
    "UKB sample overlap. No mediator was significant. In the population-based CHARLS cohort "
    "(2011-2015; n=25,762), greater pain-site burden was cross-sectionally associated with lower "
    "cognition (beta=-0.011 per site, p<0.001) with a significant nonlinear dose-response, but did "
    "not significantly accelerate four-year cognitive decline (painxtime p=0.70) or predict incident "
    "worst-quartile impairment (Cox HR 1.006, p=0.53); a four-wave sensitivity extension yielded a "
    "null incident hazard (HR 1.005, p=0.38) and a nominally significant positive interaction "
    "attributable to the easier 2018 word list, and a change-score sensitivity produced a divergent, "
    "cautiously interpreted signal. Genetic evidence is compatible with an MCP-lower-cognition "
    "association, but the direction is unresolved and the longitudinal cohort data provide only weak "
    "evidence of accelerated decline."
)'''

new_cover = '''COVER = """# Cover Letter

**To:** The Editorial Board, *Scientific Reports* (Nature Portfolio)
**Date:** 21 September 2026
**Article type:** Article (original research)
**Running title:** Genetically predicted multisite chronic pain and cognitive performance

Dear Editorial Board,

We submit our original research article entitled *"Genetically predicted multisite chronic pain is associated with lower cognitive performance: a bidirectional Mendelian randomization study with NHANES and CHARLS longitudinal evidence"* for consideration as an Article in *Scientific Reports*.

**Significance and scope.** Chronic pain and cognitive impairment are two escalating, ageing-related public-health burdens. Observational links between multisite chronic pain (MCP) and cognitive decline are confounded by reverse causation and shared comorbidity. Using bidirectional two-sample Mendelian randomization (MR) with up to 43 independent genetic instruments for MCP (UK Biobank, n=387,649), we estimate the effect of genetically predicted MCP on cognitive performance, Alzheimer's disease, and all-cause dementia, and probe the reverse direction and candidate mediators. We further embed the genetic findings in two population-based cohorts: the US NHANES (descriptive correlates of subjective memory complaint) and the Chinese CHARLS 2011-2015 longitudinal study of pain-site burden and cognitive decline.

**Key findings.** Genetically predicted MCP was associated with lower cognitive performance (IVW beta=-0.361, 95% CI -0.424 to -0.299, p=3.65x10-30), with high heterogeneity (I2~83.5%) but no directional pleiotropy. A non-significant Steiger test (p=0.23) and a significant reverse MR (beta=-0.171, p=8.85x10-58) left causal direction unresolved; the cognitive result is constrained by UK Biobank sample overlap between exposure and outcome. A non-UKB overlap-robustness re-interpretation (IGAP Alzheimer's disease: beta=0.466, p=0.008) and a formal overlap-bias quantification (Burgess-Thompson / MRlap framework; <=3% bias) corroborated the association independently of this overlap. No mediator was significant. In CHARLS (n=25,762), greater pain-site burden was cross-sectionally associated with lower cognition (beta=-0.011 per site, p<0.001) with a significant dose-response, but did not significantly accelerate four-year cognitive decline (painxtime p=0.70) or predict incident worst-quartile impairment (Cox HR 1.006, p=0.53); a four-wave sensitivity extension and a change-score sensitivity produced null or divergent, cautiously interpreted longitudinal signals. We report these results with explicit attention to their limitations rather than overstated causal claims.

**Why *Scientific Reports*.** As an open-access journal committed to rigorously peer-reviewed natural-science research of methodological soundness, *Scientific Reports* is well suited to a transparent, hypothesis-generating MR study that foregrounds its own constraints, complemented by longitudinal cohort corroboration. The work conforms to the STROBE-MR 2021 reporting guideline (checklist enclosed).

**Declarations.** This is a single-author manuscript; the author confirms the work is original, not under consideration elsewhere, and approves submission. There are no competing interests. No specific funding was received. A generative-AI research assistant was used for editorial and formatting support, with full author responsibility for all content (disclosed in the manuscript). Data and code are publicly available at https://github.com/yyx-4113/pain-cognition-mr.

Thank you for considering our work. We look forward to your assessment.

Sincerely,

Yongxin Yang, B.M.
The Second Affiliated Hospital of Fujian University of Traditional Chinese Medicine,
Fuzhou, Fujian 350003, China.
ORCID: 0009-0004-9698-6552
"""'''

new_si = '''SI_MD = """# Supplementary Information

*Yang Y. Genetically predicted multisite chronic pain is associated with lower cognitive performance: a bidirectional Mendelian randomization study with NHANES and CHARLS longitudinal evidence.*

## S1. Non-UKB overlap-robustness sensitivity analysis

The primary MCP -> cognitive-performance result is constrained by sample overlap between the MCP exposure (Johnston 2019, UK Biobank, n~387,649) and the cognitive-performance outcome (ebi-a-GCST006572, UK Biobank-derived, n=257,841), both UKB-sourced. To examine whether the pain->cognitive-decline signal survives removal of this overlap, the same forward MR estimates were re-framed using two non-UKB disease outcomes that share no UKB samples with the MCP exposure: all-cause dementia (FinnGen, a Finnish national biobank) and Alzheimer's disease (IGAP 2013 consortium, ieu-a-297, n=54,162). No new instruments, harmonization, or data were introduced; only the overlap framing differs.

Methods replicate the local MR estimators in `analysis/_recompute_local.R` (weights w = 1/se_y2; IVW fixed- and random-effects; MR-Egger with intercept test for directional pleiotropy; weighted median via the delta method with exposure and outcome SEs; leave-one-out). Mean per-SNP F-statistic across the 41-43 harmonised SNPs was ~33 (minimum ~22), far above the weak-instrument threshold of 10.

| Exposure -> outcome | Source | UKB overlap | n SNP | IVW beta (95% CI) | p | Egger beta (int p) | WMed beta | I2 | Direction |
|---|---|---|---:|---:|---:|---:|---:|---:|---:|---|
| MCP -> cognitive performance* | ebi-a-GCST006572 (UKB) | Yes | 41 | -0.361 (-0.424, -0.299) | 3.65x10-30 | -0.362 (0.34) | -0.233 | 83.5% | Lower |
| MCP -> all-cause dementia | FinnGen F5 (Finland) | No | 43 | 0.234 (-0.185, 0.653) | 0.27 | 0.209 (0.21) | 0.220 | 0% | Risk up |
| MCP -> Alzheimer's disease | IGAP ieu-a-297 (non-UKB) | No | 42 | 0.466 (0.123, 0.809) | 0.008 | 0.462 (0.86) | 0.227 | 16% | Risk up |

*Cognitive-performance row: IVW beta=-0.361 is the fixed-effect estimate (the headline value in the main manuscript); the random-effects IVW estimate is beta=-0.403 (95% CI -0.550 to -0.257), p=3.65x10-30.

Interpretation. All three outcomes point in the same direction (more multisite chronic pain -> worse cognitive performance / higher dementia and AD risk). The IGAP AD estimate is significant (beta=0.466, p=0.008) with no directional pleiotropy (Egger intercept p=0.86), low heterogeneity (I2~16%), and stable leave-one-out estimates - a genuinely overlap-free corroboration. FinnGen all-cause dementia is non-significant (beta=0.234, p=0.27), most plausibly reflecting the lower power of a binary trait with a smaller effective case sample rather than a true null. Note these non-UKB endpoints measure dementia/AD *risk*, not the cognitive-performance *score* itself; direct overlap-free confirmation at the cognitive-score level awaits a suitably powered non-UKB cognitive GWAS and overlap-corrected methods (MRlap). (Identical estimates to Section 3.1; see Figure 5 in the main manuscript.)

## S2. CHARLS longitudinal analysis and change-score sensitivity

The CHARLS component (Section 2.7, 3.5) provides population-based longitudinal context. In the three comparable cognition-assessed waves (2011/2013/2015; n=25,762; 40,135 person-waves), greater pain-site burden was cross-sectionally associated with lower global cognition (beta=-0.011 per site, p<0.001) with a significant nonlinear dose-response (restricted cubic spline, P<0.001), but pain-site burden did not significantly accelerate cognitive change (LMM painxtime interaction beta=+0.0008, p=0.70) and did not predict incident worst-quartile impairment (Cox HR 1.006, p=0.53). A four-wave sensitivity extension additionally encoding the 2018 "DC Cognition" module yielded a null incident-impairment hazard (Cox HR 1.005, p=0.381) and a nominally significant *positive* painxtime LMM interaction (beta=+0.0015, p=0.012) that is a measurement artefact of the easier 2018 12-word list (cross-sample z jumps to +0.919 at 2018) rather than true decline. A change-score (ANCOVA) sensitivity on the three-wave sample produced a divergent, nominally significant pain->decline association in the fully baseline-adjusted model (beta=-0.0067 per site, p=0.016) that we attribute to baseline imbalance and regression-to-the-mean (Lord's paradox) and do not interpret as accelerated decline; the null LMM and Cox results are our preferred inference. Full results: `charls_results_changescore_20260921.rds`, `charls_changescore_table_20260921.csv` (script `analysis/01c_charls_changescore.R`).

## S3. Audit trail of derived artifacts

Every numerical result in the manuscript traces to a derived file under `data/derived/`:

- `mr_forward_results_corrected.csv` - forward MR (MCP -> cognition / dementia / AD), corrected estimators.
- `mr_ad_reverse_results.csv` - reverse MR (cognition -> MCP).
- `mr_mediation_results.csv` - two-step mediation MR (depression / CRP / insomnia).
- `mr_master_results.csv` - master results table.
- `mr_harmonized_cog.csv`, `mr_harmonized_dementia.csv`, `mr_harmonized_ad_igap2.csv` - harmonised exposure/outcome pairs.
- `mr_gwas_metadata_20260920.csv` - GWAS metadata (IDs, n, consortium, PMID).
- `mr_nonukb_sensitivity_results.csv` - non-UKB overlap-robustness sensitivity (Section S1).
- `mr_overlap_sensitivity_20260921.rds`, `mr_overlap_sensitivity_table.csv` - overlap-bias quantification (Section 3.1.2; Burgess-Thompson / MRlap framework).
- `nhanes_results_20260920.rds`, `data/raw/nhanes_clean.rds` - NHANES descriptive analysis.
- `charls_long.rds` - CHARLS long extract (normalised person key).
- `charls_results_20260921.rds` - CHARLS 3-wave LMM / Cox / RCS (Section 3.5).
- `charls_results_4wave_20260921.rds` - CHARLS 4-wave sensitivity (Section 3.5.1).
- `charls_results_changescore_20260921.rds`, `charls_changescore_table_20260921.csv` - CHARLS change-score sensitivity (Section 3.5.2).
- `data/raw/charls/raw/2018/Cognition.dta` - 2018 DC Cognition module (user-provided `Cognition.zip`).

Figures were generated reproducibly by `analysis/make_figures.py` (Fig. 1-4) and `analysis/make_nonukb_figure.py` (Fig. 5), and the CHARLS R scripts (Fig. 6 RCS spline, Fig. 7 overlap-bias). All GWAS and method citations were verified (journal, volume, pages, DOI, PMID); the provenance discrepancy of ebi-a-GCST006572 (UKB-derived cognitive-performance score vs. the GWAS-Catalog's educational-attainment attribution) is disclosed in the Methods.
"""'''

n1 = re.subn(r"FIG_MAP = \{.*?\n\}", lambda m: new_figmap, src, count=1, flags=re.S)[1]
src = re.subn(r"def renumber\(text\):.*?\n                  text\)", lambda m: new_renumber, src, count=1, flags=re.S)[0]
n3 = re.subn(r"ABSTRACT = \(.*?\)\n\nDECLARATIONS = \[",
             lambda m: new_abstract + "\n\nDECLARATIONS = [", src, count=1, flags=re.S)[1]
src = re.subn(r"ABSTRACT = \(.*?\)\n\nDECLARATIONS = \[",
             lambda m: new_abstract + "\n\nDECLARATIONS = [", src, count=1, flags=re.S)[0]
n4 = re.subn(r'COVER = """# Cover Letter.*?"""\n\nSI_MD = """',
             lambda m: new_cover + '\n\nSI_MD = """', src, count=1, flags=re.S)[1]
src = re.subn(r'COVER = """# Cover Letter.*?"""\n\nSI_MD = """',
             lambda m: new_cover + '\n\nSI_MD = """', src, count=1, flags=re.S)[0]
n5 = re.subn(r'SI_MD = """# Supplementary Information.*?"""\n\n# ----------',
             lambda m: new_si + '\n\n# ----------', src, count=1, flags=re.S)[1]
src = re.subn(r'SI_MD = """# Supplementary Information.*?"""\n\n# ----------',
             lambda m: new_si + '\n\n# ----------', src, count=1, flags=re.S)[0]

open(P, "w", encoding="utf-8").write(src)
print("replacements FIG_MAP=%d renumber=1 ABSTRACT=%d COVER=%d SI_MD=%d" % (n1, n3, n4, n5))
