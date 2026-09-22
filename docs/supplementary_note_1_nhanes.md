# Supplementary Note 1 — NHANES 2011–2018 auxiliary analysis: descriptive correlates of subjective memory complaint

**Status: descriptive context only.** The NHANES 2011–2018 cycles analysed here contain **no chronic-pain questionnaire variable** that overlaps with the cognitive-assessment module in the same respondents. This analysis therefore does **not** test the pain → cognition hypothesis and is provided as contextual background only (referenced from §2.6 and §3.4 of the main manuscript). All numerical results in this Note trace to `data/derived/nhanes_table.csv` and `data/raw/nhanes_clean.rds` (extraction script `analysis/02_nhanes.R`; survey model object `data/derived/nhanes_results_20260920.rds`).

## S.1 Data source and sample

- **Source:** US National Health and Nutrition Examination Survey (NHANES), combined 2011–2012, 2013–2014, 2015–2016 and 2017–2018 cycles (US CDC).
- **Outcome:** subjective memory complaint, `MCQ160a` (`mcq_memory_any`, binary: 0 = no, 1 = yes — "Have you experienced a serious problem with memory?").
- **Survey design:** `svydesign(ids = ~sdmvpsu, strata = ~sdmvstra, weights = ~wtmec2yr, nest = TRUE)` (2-year-meeting-exam weights; 121 PSUs, nested strata).
- **Sample sizes:** `n = 39,156` respondents in the design frame (after survey linkage); `n = 21,645` with complete data on the outcome and all adjusted covariates entered the primary model (1,754 omitted for missing covariates; a further 16,540 had missing `mcq_memory_any` before covariate restriction and are excluded by design-complete-case survey modelling).
- **Predictors entered:** depressive symptoms (`dpq_depressed`, binary from PHQ-8/9 ≥ threshold), sleep trouble (`sleep_trouble`, binary), functional limitation (`func_limitation`, binary), age (years), and sex (`factor(sex)`, 1 = male, 2 = female).

## S.2 Weighted prevalence of subjective memory complaint

Survey-weighted prevalence of `mcq_memory_any = 1` overall and by stratum (SE in parentheses):

| Stratum | Weighted prevalence | SE |
|---|---:|---:|
| Overall | 3.39% | 0.18 |
| Male (sex = 1) | 4.41% | 0.30 |
| Female (sex = 2) | 2.45% | 0.18 |
| No depressive symptoms | 3.13% | 0.18 |
| Depressive symptoms present | 6.65% | 0.76 |
| No sleep trouble | 2.68% | 0.17 |
| Sleep trouble present | 5.15% | 0.45 |
| No functional limitation | 0.55% | 0.09 |
| Functional limitation present | 7.31% | 0.34 |

The prevalence gradient is consistent with the direction of the adjusted associations below: memory complaint is markedly more common with depressive symptoms, sleep trouble, and especially functional limitation, and is reported more often by men than women in this US sample.

## S.3 Survey-weighted correlates (primary adjusted model)

Quasi-binomial survey GLM (`svyglm`, logit link) adjusting for all predictors simultaneously. Estimates are **log-odds ratios (log-OR) per 1-unit increase** in the predictor (binary predictors: 0 → 1).

| Predictor | log-OR | SE | p |
|---|---:|---:|---:|
| Depressive symptoms (dpq_depressed) | 0.666 | 0.138 | 1.3×10⁻⁶ |
| Sleep trouble | 0.386 | 0.123 | 0.0016 |
| Functional limitation | 1.401 | 0.198 | 1.3×10⁻¹² |
| Age (per year) | 0.052 | 0.0031 | 2.3×10⁻⁶³ |
| Female (vs male) | −0.833 | 0.094 | 5.3×10⁻¹⁹ |
| Intercept | −7.169 | 0.208 | — |

Functional limitation carries the largest independent association (≈ e¹·⁴ = 4.1-fold higher modelled odds), followed by depressive symptoms (≈ e⁰·⁶⁶ = 1.9-fold) and sleep trouble (≈ e⁰·³⁹ = 1.5-fold). Sex and age remain strongly associated after adjustment.

## S.4 Crude (unadjusted) and continuous-sensitivity models

**Crude single-predictor models** (each predictor entered alone; all p < 0.001):

| Predictor | Crude log-OR |
|---|---:|
| Depressive symptoms | 0.791 |
| Sleep trouble | 0.680 |
| Functional limitation | 2.658 |

**Sensitivity — continuous depressive-score model:** replacing the binary `dpq_depressed` with the continuous PHQ-8/9 total score (`dpq_score`) leaves the depression association intact and directionally unchanged:

| Predictor | log-OR | SE | p |
|---|---:|---:|---:|
| Depressive score (dpq_score, per point) | 0.057 | 0.0099 | 7.1×10⁻⁹ |
| Sleep trouble | 0.315 | 0.121 | 0.0093 |
| Functional limitation | 1.341 | 0.196 | 7.0×10⁻¹² |
| Age (per year) | 0.054 | 0.0031 | 2.7×10⁻⁶⁹ |
| Female (vs male) | −0.856 | 0.093 | 3.7×10⁻²⁰ |

## S.5 Interpretation and limitations

- The NHANES component is **purely descriptive**. It quantifies how subjective memory complaint co-varies with depression, sleep trouble, functional limitation, age and sex in a representative US sample, but it cannot speak to chronic pain because no pain-exposure variable is available in these cycles.
- All associations are cross-sectional and observational; no causal claim is intended.
- The outcome is a single self-reported item on "serious memory problems", which is a subjective complaint rather than a performance-based cognitive measure and is not comparable to the MR cognitive-performance GWAS or the CHARLS neuropsychological battery.
- Reported prevalences are computed via `svymean` on `data/raw/nhanes_clean.rds` (§S.1); reported log-ORs are reproduced exactly from `data/derived/nhanes_table.csv`; the survey design object `data/derived/nhanes_results_20260920.rds` underlies every model.
