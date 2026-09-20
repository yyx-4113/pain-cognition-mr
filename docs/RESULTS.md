# Consolidated Results — Multisite Chronic Pain & Cognitive Decline

**Project:** 方案二 — CHARLS + NHANES dual-cohort observational + bidirectional two-sample MR + mediation
**Generated:** 2026-09-20 · **Author:** Yongxin Yang
**Reproducibility:** every number below is traceable to a file under `data/derived/` (no manuscript figure is reported without a derived artifact).

---

## 0. Study components and status

| Component | Status | Output |
|---|---|---|
| Bidirectional MR (MCP → cognition / dementia / AD; reverse) | ✅ executed & corrected | `mr_master_results.csv`, `mr_harmonized_*.csv` |
| MR mediation (depression / CRP / insomnia) | ✅ executed | `mr_mediation_results.csv` |
| NHANES auxiliary (subjective memory complaint correlates) | ✅ executed & recoded | `nhanes_results_20260920.rds`, `data/raw/nhanes_clean.rds` |
| CHARLS longitudinal (primary cohort) | ⏸ **blocked — user data required** | `data/raw/charls/raw/` is empty; run `10_charls_extract.R` + `01_charls.R` after user downloads `.dta` |

> **Instrument note.** Exposure = multisite chronic pain (MCP) GWAS, Johnston et al. 2019, UKB, n≈387,649, local `data/raw/chronic_pain-bgen.stats.gz`. LD-clumped at P<5e-8 → 51 independent lead SNPs; 41–43 carried into cognition/dementia MR, 146 into reverse MR. Cognitive outcome = `ebi-a-GCST006572` (UK Biobank–derived cognitive performance, n≈257,841; **overlap-limited** — shares UKB samples with the MCP exposure). AD = `ieu-a-297` (IGAP) and `ieu-b-2` (Ben Nevis), dementia = `finn-b-F5_DEMENTIA`.

---

## 1. Forward MR — genetically predicted MCP → outcomes

| Outcome (GWAS ID) | n SNP | IVW β (SE) | p | Egger β (int p) | WMed β | Cochran Q (p) | LOO β range | Interpretation |
|---|---:|---:|---:|---:|---:|---:|---|---|
| Cognition (`ebi-a-GCST006572`) | 41 | **-0.361 (0.032)** | **<1e-29** | -0.362 (0.344) | -0.233 | 242.5 (<1e-30) | [-0.386, -0.315] | MCP lowers cognitive performance |
| All-cause dementia (`finn-b-F5_DEMENTIA`) | 43 | 0.234 (0.213) | 0.273 | 0.209 (0.206) | 0.220 | 38.9 (0.608) | [0.163, 0.293] | Null |
| AD — IGAP (`ieu-a-297`) | 42 | **0.466 (0.175)** | **0.008** | 0.462 (0.856) | 0.227 | 48.8 (0.189) | [0.393, 0.518] | Positive, needs replication |
| AD — Ben Nevis (`ieu-b-2`) | 43 | 0.168 (0.158) | 0.288 | 0.163 (0.777) | -0.017 | 51.8 (0.144) | [0.112, 0.228] | Null — does not replicate |

**Read:** MCP shows strong, robust evidence of *lower* cognitive performance (IVW, Egger, WMed all concordant; Egger intercept non-significant → no directional pleiotropy; LOO stable). The dementia/AD signal is **inconsistent across AD consortia** (IGAP positive, Ben Nevis null) — report as hypothesis-generating, not established.

---

## 2. Reverse MR — cognition → MCP

| n SNP | IVW β (SE) | p | Egger β (int p) | WMed β | Cochran Q (p) | LOO β range |
|---:|---:|---:|---:|---:|---:|---:|
| 146 | **-0.171 (0.011)** | **<1e-57** | -0.172 (0.139) | -0.121 | 474.8 (<1e-30) | [-0.176, -0.164] |

**Read:** Cognition → MCP is *also* strongly significant. **Both directions significant ⇒ causal direction is uncertain**; in the present data both the forward and reverse directions are UKB-sourced, so the bidirectional significance may partly reflect common UKB sample overlap rather than genuinely reciprocal effects — a non-overlapping reverse analysis is still needed. State this limitation explicitly.

---

## 3. MR mediation — MCP → mediator → cognition

Two-step MR, indirect effect = β₁(MCP→mediator) × β₂(mediator→cognition).

| Mediator (ID) | step-1 β (p) | step-2 β (p) | Indirect β (95% CI) | p | Conclusion |
|---|---:|---:|---:|---:|---|
| Depression (`ieu-b-102`) | 0.620 (<1e-14) | -0.078 (0.106) | -0.048 (-0.108, 0.012) | 0.114 | Null |
| CRP (`ebi-a-GCST90029070`) | 0.180 (5.6e-4) | 0.001 (0.945) | 0.0002 (-0.005, 0.005) | 0.945 | Null |
| Insomnia (`ukb-b-3957`) | 0.265 (<1e-16) | -0.019 (0.857) | -0.005 (-0.059, 0.049) | 0.857 | Null |

**Read:** No tested mediator was significant. Because the two-step mediation was underpowered, this **does not** establish a direct effect; label mediation as *suggestive only* and do not assert mechanism.

---

## 4. NHANES auxiliary — correlates of subjective memory complaint (2011–2018, n=39,156)

**Construct limitation (verified):** NHANES has no chronic-pain questionnaire in these cycles and its objective cognition battery (2011–2014) does not overlap the pain era → NHANES **cannot** test pain→cognition. It is used only to characterise the *subjective memory-complaint* phenotype (MCQ160E) and its correlates, as supporting context.

**Survey-weighted prevalences:**

| Variable | Definition | Prevalence (%, SE) |
|---|---|---:|
| Memory complaint | MCQ160E = "ever confused / trouble remembering" (yes) | 3.4 (0.2) |
| Depression | PHQ-9 total ≥ 10 (DPQ010–090) | 7.5 (0.3) |
| Sleep trouble | SLQ050 = trouble sleeping (yes) | 28.0 (0.6) |
| Functional limitation | any PFQ0xx difficulty | 35.2 (0.7) |
| PHQ-9 mean score | — | 2.85 |

**Primary model** — quasibinomial, survey-weighted: `memory_complaint ~ depression + sleep + function + age + sex`

| Predictor | log-OR (SE) | p |
|---|---:|---:|
| Depression (PHQ-9 ≥ 10) | 0.666 (0.138) | <0.001 |
| Sleep trouble | 0.386 (0.123) | 0.003 |
| Functional limitation | 1.401 (0.198) | <0.001 |
| Age (per year) | 0.052 (0.003) | <0.001 |
| Female (vs male) | -0.833 (0.094) | <0.001 |

**Sensitivity** (continuous PHQ-9 instead of binary): dpq_score log-OR 0.057 (SE 0.010, p<0.001) — dose–response consistent with the binary result.

**Read:** Among US adults, subjective memory complaint is independently associated with depression, sleep trouble, and especially functional limitation; the direction is descriptive (observational, no causal claim).

---

## 5. Synthesis for the manuscript

1. **MR primary signal:** genetically predicted multisite chronic pain → *lower* cognitive performance, robust across methods (IVW/Egger/WMed, LOO, no pleiotropy by Egger intercept). This is the headline.
2. **Causality direction uncertain:** reverse MR also significant, but both directions are UKB-sourced so the bidirectional signal may partly reflect common UKB overlap; frame as "genetic evidence is compatible with an association; causal direction is uncertain (significant reverse MR; non-significant Steiger), and the cognitive-performance result is overlap-limited."
3. **AD/dementia inconsistent:** IGAP positive, Ben Nevis null, all-cause dementia null → hypothesis-generating only.
4. **No MR mediation:** null mediators do **not** establish a direct effect (underpowered); mechanistic claims deferred.
5. **NHANES:** descriptive only (contains no pain variable); characterises comorbidity correlates of subjective memory complaint — explicitly auxiliary, and uninformative about the pain→cognition hypothesis.
6. **CHARLS (pending):** the planned primary longitudinal test of pain-site "burden" → cognitive decline is not yet run — requires user-downloaded `.dta` in `data/raw/charls/raw/`.

---

## 6. Audit trail (derived files)

`mr_forward_results_corrected.csv` · `mr_ad_reverse_results.csv` · `mr_mediation_results.csv` · `mr_master_results.csv` · `mr_harmonized_cog.csv` · `mr_harmonized_dementia.csv` · `mr_harmonized_ad_igap2.csv` · `mr_harmonized_ad_bennevis.csv` · `mr_gwas_metadata_20260920.csv` · `nhanes_results_20260920.rds` · `data/raw/nhanes_clean.rds`
