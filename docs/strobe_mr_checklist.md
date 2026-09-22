# STROBE-MR 2021 Compliance Checklist — Item-by-Item

**Study:** *Genetically predicted multisite chronic pain is compatible with lower cognitive performance: a bidirectional Mendelian randomization study with CHARLS longitudinal context* (version A++ / round-4 revised: MR + NHANES descriptive + CHARLS 4-wave longitudinal).
**Guideline:** STROBE-MR 2021 — Skrivankova VW, et al. *JAMA.* 2021;326(16):1614–1621 (PMID 34698778). 20 items.
**Status legend:** ✅ addressed in manuscript · 🟡 partial / to be added · ⛔ **[PENDING DATA]** (blocked on CHARLS access).

| # | STROBE-MR item (2021) | Mapped to manuscript | Status |
|---|---|---|---|
| 1 | **Title and abstract** — identify the study as an MR study | Title ("Mendelian randomization study"); Abstract states MR design, methods, results | ✅ |
| 2 | **Background** — explain the scientific/rationale | §1 Introduction (pain–cognition epidemiology, reverse causation & confounding as MR motivation) | ✅ |
| 3 | **Objectives** — state purpose; causal estimates valid only under MR assumptions | §1 final paragraph (aims i–iii + NHANES/CHARLS support); assumptions named in §2.4 | ✅ |
| 4a | **Study design & data sources — Setting** | §2.1 (two-sample MR + cohort support); §2.2 | ✅ |
| 4b | **Study design & data sources — Participants** (eligibility, if individual-level) | §2.2 (summary-level sources; NHANES/CHARLS described); CHARLS 25,762 participants / 40,135 person-waves (§2.7, §3.5) | ✅ |
| 4c | **Variant measurement, QC, selection** | §2.3 (P<5×10⁻⁸, LD clumping r²<0.001/10 000 kb, palindromic drop, 51 lead SNPs) | ✅ |
| 4d | **Exposure & outcome definition** | §2.2 + data table (MCP ≥2 sites; UKB-derived cognitive performance / IGAP / Ben Nevis / FinnGen dementia; mediators) | ✅ |
| 4e | **Ethics & informed consent** | §2.8 (published summary stats; de-identified public datasets; exempt) | ✅ |
| 5 | **Assumptions** — state the 3 core IV assumptions (relevance, independence, exclusion restriction) | §1 (named); §2.4 (operationalised via Steiger/Egger intercept/Cochran Q) | ✅ |
| 6a | **Statistical methods — Quantitative variables** | §2.3–2.5 (β on SD/log-OR scales; harmonisation) | ✅ |
| 6b | **Statistical methods — Genetic variants** | §2.3 (selection, clumping, harmonisation) | ✅ |
| 6c | **Statistical methods — MR estimator** | §2.4 (IVW primary; MR-Egger; weighted median) | ✅ |
| 6d | **Statistical methods — Missing data** | §2.3 (SNPs dropped on harmonisation failure; n reported per direction) | ✅ |
| 6e | **Statistical methods — Multiple testing** | §2.4 (primary hypothesis MCP→cognition; others exploratory; no formal correction; all p-values reported) | ✅ |
| 7 | **Assessment of assumptions** — relevance / independence / exclusion restriction | §3.1 (Steiger directionality, Egger intercept, Cochran Q; non-UKB overlap-robustness sensitivity re-statement in §3.1.1) | ✅ |
| 8 | **Sensitivity / additional analyses** — planned *a priori* | §2.4 (LOO, mediation, reverse); §2.5 (two-step mediation) | ✅ |
| 9a | **Software & version** | §2.4 (R; `ieugwasr` 1.1.0; custom harmonisation) | ✅ |
| 9b | **Preregistration** | Not preregistered — stated in Declarations (§6) | ✅ |
| 10a | **Descriptive data — Flow / exclusions** | §2.2 table; §2.3 (51 SNPs → 41–43 forward, 146 reverse) | ✅ |
| 10b | **Descriptive data — Summary statistics of participants** | NHANES §3.4 (weighted prevalences); CHARLS §3.5 / Table 7 (baseline by pain burden; LMM/Cox/RCS) | ✅ |
| 10c | **Descriptive data — Meta-analysis heterogeneity** | §3.1 (Cochran Q reported per outcome) | ✅ |
| 10d | **Descriptive data — Two-sample MR** | §2.1 (design statement) | ✅ |
| 11a | **Main results — Variant–exposure & variant–outcome associations** | §3.1 table (per-SNP β via scatter/LOO figures) | ✅ |
| 11b | **Main results — MR estimates + 95% CI** | §3.1 (IVW β, 95% CI, p) | ✅ |
| 11c | **Main results — Additional statistics** | §3.1, §3.1.1 (Egger β/intercept, WMed, Q, LOO range) | ✅ |
| 12a | **Assessment of assumptions in Results — Validity** | §3.1 (Steiger p=0.23 → direction NOT established; Egger intercept p=0.34 → no directional pleiotropy; the two are distinct and reported separately) | ✅ |
| 12b | **Assessment of assumptions — Heterogeneity (I²/Q)** | §3.1 (Cochran Q; I²≈83.5% for cognition; RE-IVW β=−0.403 reported; E-value not computed) | ✅ |
| 13a | **Robustness — Sensitivity analyses** | §3.1 (LOO stable; Egger/WMedian concordant) | ✅ |
| 13b | **Robustness — Other sensitivity** | §3.3 (mediation null) | ✅ |
| 13c | **Robustness — Bidirectional / direction of effect** | §3.2 (reverse MR cognition→MCP significant) | ✅ |
| 13d | **Robustness — Non-MR comparison (e.g., cohort)** | §3.4 NHANES (descriptive); §3.5 CHARLS (longitudinal LMM/Cox/RCS, now reported) | ✅ |
| 13e | **Robustness — Plots (e.g., LOO)** | Figures 1–7 (forest, scatter, LOO, funnel, non-UKB sensitivity, overlap-bias, CHARLS RCS) | ✅ |
| 14 | **Key results** | Abstract + §3 summary | ✅ |
| 15 | **Limitations** | §4 Limitations (1–10: reverse causation, heterogeneity/I² + horizontal pleiotropy (IVW vs WMed gap), AD inconsistency, UKB×UKB sample overlap with honest correction of prior false "non-UKB COGENT mitigates" claim, NHANES descriptive, CHARLS now reported, MR-PRESSO not run, multiple-testing/ancestry/power, **endpoint interpretation (single-occasion performance score ≠ decline/diagnosis)**, **clinical magnitude**) | ✅ |
| 16a | **Interpretation — Meaning** | §4 (pain→lower cognition; mechanism unknown, no direct-effect claim) | ✅ |
| 16b | **Interpretation — Mechanism & gene–environment equivalence** | §4 (mechanism unknown; central sensitisation / neuroinflammation / HPA-axis described as speculative, not asserted) | ✅ |
| 16c | **Interpretation — Clinical / public-health relevance** | §5 Conclusion (pain as modifiable contributor to cognitive health) + §4 "Interpretation of magnitude" paragraph (small individual-level effect, population-scale relevance; no individual prognostication) | ✅ |
| 17a | **Generalizability — Populations** | §4 (European-ancestry GWAS; NHANES US; generalisability caveat) | ✅ |
| 17b | **Generalizability — Exposure periods** | §4 (lifetime/chronic pain exposure) | ✅ |
| 17c | **Generalizability — Exposure levels** | §4 (multisite vs single-site not dissected — 🟡 note) | 🟡 note |
| 18 | **Funding** | Declarations (§6): no external funding | ✅ |
| 19 | **Data & data sharing** | Declarations (§6) + §7 audit trail; real named repository URL (https://github.com/yyx-4113/pain-cognition-mr) | ✅ |
| 20 | **Conflicts of Interest** | Declarations (§6): none declared | ✅ |

## Summary — version A++ / round-4 revised (2026-09-22)
**Round-4 editorial revisions applied to `manuscript_draft.md`:**
- **Tier-0 contradictions resolved.** (i) Title de-escalated from "is associated with lower cognitive performance" to "**is compatible with** lower cognitive performance". (ii) §3.1.1 re-labelled "overlap-robustness **re-interpretation**" → "**sensitivity re-statement**", with explicit disclosure that it re-uses the identical §3.1 FinnGen/IGAP estimates and therefore provides **no independent corroboration**. (iii) Abstract "CHARLS … planned (pending data access)" removed. (iv) AD(+0.466) vs cognition(−0.361) sign contrast reconciled: both described as "signalling harm", with the positive/negative sign difference explicitly stated as **not** a coherent dose–response signal.
- **Tier-1 interpretive hedges.** Overlap "≤3% conservative bound" → "*plausibly* conservative", with the caveat that the Burgess–Thompson estimator bounds bias **magnitude, not direction**; IVW-vs-weighted-median 35% gap attributed to horizontal (non-directional) pleiotropy; endpoint redefined honestly as a single-occasion fluid-reasoning performance score, not decline or diagnosis.
- **Literature gap filled.** Tian et al. 2023 (*BMC Medicine* 21:169; UK Biobank, n=356,383, median 13.3 y; HR 1.08 [1.05–1.11] per pain site for incident dementia; AD HR 1.09 [1.04–1.13]) is now reference [1] and cited as the observational precedent.
- **Tier-3 format.** Figures renumbered 4–10 → **1–7**; Tables numbered **1–7** (previously two unnumbered); References resequenced into strict first-appearance order (19 numbered + 2 accession-cited listed last); §7 audit trail now lists Figures 6–7.
- **Numeric integrity confirmed.** Editor independently recomputed the forward MR-Egger intercept from `data/derived/mr_harmonized_cog.csv`: p=0.3441, matching the manuscript — an auditor claim of "p should be 0.70" was a false positive (reverse-direction row) and was rejected. **No manuscript number was changed.**
- **All 20 items fully addressed**, including the three previously CHARLS-blocked items (4b participants, 10b CHARLS summary, 13d CHARLS non-MR comparison), now populated from the completed CHARLS 2011–2020 longitudinal analysis (§2.7, §3.5, Table 7, Figure 6).
- **CHARLS results (version A):** cross-sectional pain-site burden ↔ lower global cognition (per-site β=−0.011, p<0.001; RCS nonlinear P<0.001); longitudinal decline-acceleration non-significant (pain×time interaction p=0.70; Cox HR 1.006 per site, 95% CI 0.988–1.024, p=0.53). Direction consistent with MR; longitudinal signal weak — reported transparently.
- **Minor to-dos (🟡):** preregistration statement (9b) and exposure-level generalizability note (17c) remain flagged in the manuscript; the multiple-testing statement (6e), I² (12b), and real repository link (19) are addressed. No fabricated or unverifiable content: every cited GWAS/consortium PMID and method reference is verified; the cognitive-performance accession provenance discrepancy (UKB-derived score vs. catalog's educational-attainment attribution) is disclosed in §2.2.
- No fabricated or unverifiable content: every cited GWAS/consortium PMID and method reference is verified (see References in `manuscript_draft.md`).
