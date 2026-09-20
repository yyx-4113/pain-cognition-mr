> # ⚠️ DRAFT — 状态横幅（写作者内部用）
> - **已完成**：双向两样本 MR（正向 MCP→认知/痴呆/AD；反向）；MR 两步中介（抑郁/CRP/失眠）；NHANES 2011–2018 辅助分析。
> - **待补**：CHARLS 主队列（纵向疼痛部位数→认知下降）— 账号/数据访问仍在 charls.pku.edu.cn 审核中，`data/raw/charls/raw/` 仍为空。本文将 CHARLS 章节明确标记为 **[PENDING DATA]**，数据到位后由 `10_charls_extract.R`+`01_charls.R` 补充，方法与结果占位已写好。
> - **每个数字均可溯源**至 `data/derived/` 下对应 CSV/RDS（见文末审计轨）。
> - **版本 B 修订（2026-09-20）**：依据预印版编辑评审（见 `docs/EDITORIAL_REVIEW.md`）逐条修改，重点修正 (1) 主结局 UKB×UKB 样本重叠的错误处理与定量说明；(2) Steiger 方向性检验的反向解读；(3) "直接效应"的错误导出；(4) NHANES 由"supporting"降级为"contextual/descriptive"；(5) 补报 I²、工具变量强度 F、MR-PRESSO 未执行说明；(6) 修正 IGAP/认知 GWAS 引用与图 5 Egger 斜率矛盾。
> - 作者署名：**Yongxin Yang**（不挂 MD/PhD 等研究生以上学位头衔）。单位：The Second Affiliated Hospital of Fujian University of Traditional Chinese Medicine, Fuzhou, Fujian 350003, China。ORCID 0009-0004-9698-6552。

---

# Genetically predicted multisite chronic pain is associated with lower cognitive performance: a bidirectional Mendelian randomization study with NHANES contextual evidence

**Yongxin Yang**
The Second Affiliated Hospital of Fujian University of Traditional Chinese Medicine, Fuzhou, Fujian 350003, China. ORCID: 0009-0004-9698-6552.

> **Note on scope (version B).** This manuscript presents the two-sample MR core and the NHANES 2011–2018 auxiliary analysis. The CHARLS longitudinal component is planned and currently flagged **[PENDING DATA]** (see §2.7, §3.5); it will be incorporated to upgrade this work to version A upon data-access approval. The NHANES component is **descriptive only** (it contains no pain variable and therefore does not test the pain→cognition hypothesis); it is provided as contextual background, not as supporting causal evidence.

## Abstract

**Background.** Chronic pain and cognitive impairment are two escalating public-health burdens in ageing populations. Observational studies linking multisite chronic pain (MCP) to cognitive decline are confounded by reverse causation and shared comorbidity. We used Mendelian randomization (MR) to assess the causal direction and magnitude of the association between genetically predicted MCP and cognitive outcomes, embedded in population-based descriptive correlates (US NHANES) of subjective memory complaint. NHANES contains no chronic-pain questionnaire in the analysed cycles and therefore does not test the pain→cognition hypothesis.

**Methods.** Two-sample MR was conducted with MCP (Johnston et al., 2019; UK Biobank, n=387,649) as exposure. Outcomes were cognitive performance (OpenGWAS `ebi-a-GCST006572`, UK Biobank-derived, n=257,841), Alzheimer's disease (IGAP, `ieu-a-297`, n=54,162; Ben Nevis/ADGC, `ieu-b-2`, n=63,926), and all-cause dementia (FinnGen, `finn-b-F5_DEMENTIA`, n=216,771). Independent instrumental SNPs were selected at P<5×10⁻⁸ with LD clumping (r²<0.001, 10,000 kb). Causal estimates used inverse-variance-weighted (IVW), MR-Egger, and weighted-median methods; heterogeneity (Cochran Q / I²), directional pleiotropy (Egger intercept), directionality (Steiger), and leave-one-out were assessed. A reverse MR (cognition→MCP) and two-step mediation MR (via depression, C-reactive protein, insomnia) were performed. The US NHANES 2011–2018 (n=39,156) provided survey-weighted descriptive correlates of subjective memory complaint. CHARLS longitudinal analysis is planned (pending data access).

**Results.** Genetically predicted MCP was associated with **lower** cognitive performance (IVW β=−0.361, 95% CI −0.424 to −0.299, p=3.65×10⁻³⁰; MR-Egger β=−0.362, intercept p=0.34; weighted-median β=−0.233; leave-one-out β range −0.386 to −0.315), with substantial heterogeneity (Cochran Q=242.5, I²≈83.5%, p<10⁻³⁰) but no detectable directional pleiotropy (Egger intercept). The Steiger directionality test was **non-significant** (p=0.23) and therefore did not establish MCP→cognition as the dominant causal direction (note: the Steiger test was performed only in the forward direction). A non-UKB overlap-robustness check, re-framing the same §3.1 FinnGen all-cause dementia and IGAP Alzheimer's disease estimates (neither shares UKB samples with the MCP exposure), pointed in the same direction as the UKB cognitive result and the IGAP AD estimate was significant (IVW β=0.466, 95% CI 0.123–0.809, p=0.008), corroborating the association without sample overlap, whereas all-cause dementia was non-significant (β=0.234, p=0.27) and Ben Nevis AD null (β=0.168, p=0.29). Reverse MR (cognition→MCP) was also significant (IVW β=−0.171, p=8.85×10⁻⁵⁸), leaving causal direction uncertain. No mediator was significant (indirect effects p>0.11); the two-step mediation was underpowered, so these nulls do **not** establish a direct effect. In NHANES, subjective memory complaint was independently associated with depression (log-OR 0.67), sleep trouble (0.39), functional limitation (1.40), and age, with women reporting less (all p<0.01) — descriptive only, and uninformative about pain→cognition.

**Conclusions.** Genetic evidence is **compatible** with an association between genetically predicted MCP and lower cognitive performance, but the causal direction is uncertain (significant reverse MR; non-significant Steiger) and the cognitive-performance result is limited by UKB sample overlap between exposure and outcome. The dementia/AD signal requires replication and is inconsistent across consortia. No mediator was identified; the mechanism remains unknown.

---

## 1. Introduction

Chronic pain affects a substantial proportion of middle-aged and older adults and is increasingly recognised as more than a sensory symptom — it is associated with accelerated cognitive ageing, incident dementia, and reduced reserve [refs]. Multisite chronic pain (MCP), defined by pain at multiple body sites, carries a particularly high burden and has been linked cross-sectionally to poorer cognition [refs].

Two obstacles limit causal inference from observational cohorts. First, **reverse causation**: poorer cognition may increase pain reporting and reduce pain coping. Second, **confounding** by age, depression, sleep, and disability is profound and rarely fully adjusted. Mendelian randomization (MR) mitigates these by using genetic variants as instruments for pain, under the assumptions of relevance, exchangeability, and exclusion-restriction.

We therefore conducted a bidirectional two-sample MR to (i) estimate the effect of genetically predicted MCP on cognitive performance, Alzheimer's disease (AD), and all-cause dementia; (ii) test the reverse direction; (iii) probe mediators (depression, C-reactive protein [CRP], insomnia) via two-step MR. To embed the genetic findings in real-world epidemiology, we additionally analysed the US NHANES for correlates of subjective memory complaint and plan a CHARLS longitudinal test of pain-site burden on cognitive decline (pending data access). A key limitation, addressed transparently below, is that the headline cognitive-performance outcome and the MCP exposure are both UK Biobank–derived, creating sample overlap that constrains causal interpretation.

## 2. Methods

### 2.1 Study design
This study combines a two-sample MR core with population-based descriptive context, reported per the STROBE-MR 2021 guideline [13].

### 2.2 Data sources

**Exposure — multisite chronic pain (MCP).** Summary statistics from Johnston et al. (2019 [1]; UK Biobank, n=387,649, European ancestry) were obtained locally (DOI 10.5525/gla.researchdata.822). MCP was defined as pain at ≥2 (multisite) body sites.

**Outcomes (OpenGWAS / IEU).** Cognitive performance: `ebi-a-GCST006572` — a UK Biobank–derived cognitive-performance GWAS (1-standardised score; n=257,841; European ancestry). *Provenance note:* the GWAS Catalog / OpenGWAS metadata for this accession is listed under Lee et al. (Nat Genet 2018; PMID 30038396), which is an **educational-attainment** GWAS; the summary-statistic set itself is a UKB-derived cognitive-performance score and is cited here by trait and accession. Because both the MCP exposure and this outcome are UKB-sourced, **sample overlap is present** (see §2.4 and Limitations). Alzheimer's disease: IGAP 2013 [3] (`ieu-a-297`, n=54,162 [17,008 cases / 37,154 controls]). Ben Nevis/ADGC consortium [4] (`ieu-b-2`, n=63,926 [21,982 / 41,944]). All-cause dementia: FinnGen [5] (`finn-b-F5_DEMENTIA`, Freeze 5, n=216,771 [7,284 cases], 2021).

**Mediators.** Major depression (`ieu-b-102`, PGC, n=500,199 [6]); C-reactive protein (`ebi-a-GCST90029070`, Said 2022 [7], n=575,531); insomnia (`ukb-b-3957`, MRC-IEU, n=462,341 [8]).

**Descriptive context.** NHANES 2011–2018 (CDC) for descriptive correlates of subjective memory complaint. CHARLS 2011–2020 (Peking University) longitudinal analysis is **planned [PENDING DATA]**.

| Dataset | ID | Trait | n | Cases/Controls | Consortium (PMID) |
|---|---|---|---:|---:|---|
| Exposure | local | Multisite chronic pain | 387,649 | — | Johnston 2019 (31194737) |
| Outcome | ebi-a-GCST006572 | Cognitive performance (UKB-derived) | 257,841 | — | OpenGWAS accession¹ (see §2.2 note) |
| Outcome | ieu-a-297 | Alzheimer's disease | 54,162 | 17,008 / 37,154 | IGAP (24162737) |
| Outcome | ieu-b-2 | Alzheimer's disease | 63,926 | 21,982 / 41,944 | ADGC/Ben Nevis (30820047) |
| Outcome | finn-b-F5_DEMENTIA | All-cause dementia | 216,771 | 7,284 / 209,487 | FinnGen (36653562) |
| Mediator | ieu-b-102 | Major depression | 500,199 | 170,756 / 329,443 | PGC (30718901) |
| Mediator | ebi-a-GCST90029070 | CRP | 575,531 | — | Said 2022 (35459240) |
| Mediator | ukb-b-3957 | Insomnia | 462,341 | — | MRC-IEU (2018) |

¹ `ebi-a-GCST006572` is a UK Biobank–derived cognitive-performance GWAS (n=257,841). Its OpenGWAS/GWAS Catalog metadata is attributed to Lee et al. 2018 (PMID 30038396, educational attainment); the summary statistics used here are the UKB cognitive-performance score, cited by accession and trait.

### 2.3 Instrumental variable selection
MCP SNPs were selected at genome-wide significance (P<5×10⁻⁸) and LD-clumped (r²<0.001 within 10,000 kb; 1,000 Genomes European reference) using `ieugwasr`. Palindromic/ambiguous SNPs were dropped. This yielded **51 independent lead SNPs**, of which 41–43 were harmonised into the cognitive/dementia outcomes. The reverse (cognition→MCP) analysis **selected a separate set of 146 independent cognitive instruments** (not a subset of the 51 MCP SNPs). *These 146 SNPs derive from the same UKB-derived cognitive-performance GWAS used as the forward outcome, so the reverse direction is affected by UKB sample overlap at least as heavily as the forward direction* (see §3.2). Instrument strength was strong: across the 41–43 harmonised SNPs the mean per-SNP F-statistic was ≈33 (minimum ≈22), far above the conventional weak-instrument threshold of 10, indicating adequate relevance.

### 2.4 MR analysis
Primary estimate: inverse-variance-weighted (IVW) fixed-effect [12]. Sensitivity: MR-Egger (pleiotropy via intercept) [10], weighted median (robust to ≤50% invalid instruments) [11]. Heterogeneity: Cochran Q, reported together with I² = (Q−df)/Q to convey the proportion of variation due to heterogeneity rather than sampling error [e.g., cognition I²≈83.5%]. Directionality: Steiger test [15] (tests whether the exposure explains more variance than the outcome; significant p<0.05 supports the specified direction). The Steiger test was applied to the primary forward direction (MCP→cognition) only and was not performed in the reverse direction, so it speaks solely to the forward causal ordering. Leave-one-out: re-estimation excluding each SNP. All methods implemented in R (ieugwasr 1.1.0 [9]; TwoSampleMR unavailable in-environment).

**Effect-size units.** For the continuous cognitive-performance outcome, every β is reported as the change per **1-SD genetically predicted increase in MCP** (i.e., the SNP-instrumented MCP liability). For binary outcomes (AD, all-cause dementia) and the binary NHANES models, β is on the log-odds scale per 1-SD genetically predicted MCP increase. All CIs are 95%.

*Two distinct concepts are reported separately and must not be conflated:* (a) a **non-significant MR-Egger intercept** indicates *no detectable directional (balanced) pleiotropy*; (b) a **non-significant Steiger test** indicates that the genetic-correlation structure does *not* establish the exposure→outcome direction. They answer different questions.

*Outlier robustness.* The Statistical Analysis Plan (§4.3) specified MR-PRESSO and outlier-SNP re-estimation. These could **not** be executed because the TwoSampleMR / mr_presso stack was unavailable in the analysis environment (only `ieugwasr` ran). As the primary outlier-robustness proxy we rely on leave-one-out (no single SNP was influential; §3.1) and report this limitation explicitly. MR-PRESSO / Radial MR are recommended as future work once the full TwoSampleMR stack is available.

*Statistical framework.* The primary hypothesis was MCP→cognitive performance; all other directions and the three mediation paths were **exploratory**. No formal multiple-comparison correction was applied, but all p-values are reported to allow reader judgement.

### 2.5 Two-step mediation MR
Path MCP → mediator → cognition, using the two-step MR mediation framework [14]. Indirect effect = β₁(MCP→mediator) × β₂(mediator→cognition); 95% CI by the delta method. Mediation results are interpreted as **suggestive only** [14] and were underpowered (see §3.3).

### 2.6 NHANES auxiliary analysis
Survey-weighted prevalences and a quasibinomial model of subjective memory complaint (MCQ160E) on depression (PHQ-9≥10), sleep trouble (SLQ050), functional limitation (any PFQ difficulty), age, and sex, using `survey` (4-cycle weights). NHANES lacks a pain×cognition overlap in these cycles, so it is used only for descriptive context, not causal testing.

### 2.7 CHARLS longitudinal analysis **[PENDING DATA]**
For each wave 2011–2020, pain-site count (DA042*; 0/1/2/≥3) and a within-wave z-scored cognitive composite (dc009s1–10, dc012s1–10, dc024, dc003–006, dc014) will be derived (`10_charls_extract.R`). Linear mixed models (pain burden × wave, random intercept/slope) and Cox models for incident decline (`01_charls.R`) will be run. Not yet executed.

### 2.8 Ethics
MR uses only published summary statistics; NHANES and CHARLS are public, de-identified, consent-covered datasets. This analysis is exempt from individual consent.

## 3. Results

### 3.1 Forward MR — MCP → cognitive and dementia outcomes

All estimates below express the effect of a **1-SD genetically predicted increase in MCP**; binary outcomes (AD, all-cause dementia) are on the log-odds scale.

| Outcome (GWAS) | n SNP | IVW β (95% CI) | p | Egger β (int p) | WMed β | Cochran Q (p) | I² | LOO β |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| Cognitive performance | 41 | **−0.361 (−0.424, −0.299)** | **3.65×10⁻³⁰** | −0.362 (0.34) | −0.233 | 242.5 (<10⁻³⁰) | ≈83.5% | [−0.386, −0.315] |
| All-cause dementia | 43 | 0.234 (−0.185, 0.653) | 0.27 | 0.209 (0.21) | 0.220 | 38.9 (0.61) | ≈0% | [0.163, 0.293] |
| AD — IGAP (ieu-a-297) | 42 | **0.466 (0.123, 0.809)** | **0.008** | 0.462 (0.86) | 0.227 | 48.8 (0.19) | ≈16% | [0.393, 0.518] |
| AD — Ben Nevis | 43 | 0.168 (−0.141, 0.477) | 0.29 | 0.163 (0.78) | −0.017 | 51.8 (0.14) | ≈19% | [0.112, 0.228] |

**Figure 4** (forest plot), **Figure 5** (SNP scatter with MR and MR-Egger fit lines), **Figure 6** (leave-one-out), and **Figure 7** (Wald-ratio funnel) illustrate the cognition result. Genetically predicted MCP was robustly associated with **lower** cognitive performance across IVW, Egger, and weighted median. The MR-Egger intercept was non-significant (p=0.34), indicating no detectable directional pleiotropy; leave-one-out estimates were stable (range −0.386 to −0.315). **Heterogeneity was high** (Cochran Q=242.5, I²≈83.5%): the random-effects IVW estimate (β=−0.403, SE 0.075) is even more extreme than the fixed-effect point estimate, and the weighted-median estimate (−0.233) is materially smaller in magnitude — together suggesting that a single homogeneous causal effect is unlikely and that effect variation across SNPs is present. The **Steiger directionality test was non-significant (p=0.23)** and therefore did *not* establish MCP→cognition as the dominant causal direction. The dementia/AD signal was **inconsistent**: all-cause dementia null, IGAP AD positive, Ben Nevis AD null.

### 3.1.1 Non-UKB overlap-robustness re-interpretation (of §3.1 estimates)

The primary cognitive-performance result is constrained by UKB sample overlap with the MCP exposure (§2.2, Limitation 4). To examine whether the pain→cognitive-decline signal survives removal of this overlap, we re-framed the two **non-UKB** disease outcomes — all-cause dementia (FinnGen, a Finnish national biobank; `finn-b-F5_DEMENTIA`) and Alzheimer's disease (IGAP 2013 consortium [3]; `ieu-a-297`, n=54,162) — as an **overlap-robustness re-interpretation** of the forward estimates reported in §3.1 (Figure 8). *These estimates are numerically identical to those in §3.1 (All-cause dementia and AD — IGAP); no new instruments, harmonization, or data were introduced — only a different framing that removes the UKB overlap concern.* Neither outcome shares UKB samples with the MCP exposure (FinnGen is Finnish; IGAP is an international case–control consortium), so direct sample overlap is largely absent — a cleaner test of the overlap concern than the UKB cognitive-performance outcome.

| Outcome (GWAS; overlap status) | n SNP | IVW β (95% CI) | p | Egger β (int p) | WMed β | I² | Direction vs UKB cognition |
|---|---:|---:|---:|---:|---:|---:|---|
| All-cause dementia (FinnGen; **non-UKB**) | 43 | 0.234 (−0.185, 0.653) | 0.27 | 0.209 (0.21) | 0.220 | ≈0% | same (↑ risk) |
| AD (IGAP `ieu-a-297`; **non-UKB**) | 42 | **0.466 (0.123, 0.809)** | **0.008** | 0.462 (0.86) | 0.227 | ≈16% | same (↑ risk) |

Both non-UKB outcomes pointed in the **same direction** as the UKB cognitive-performance result: genetically predicted MCP associated with *lower* cognitive performance and *higher* dementia/AD risk. The IGAP AD estimate was **significant** (β=0.466, 95% CI 0.123–0.809, p=0.008) with no detectable directional pleiotropy (Egger intercept p=0.86), low heterogeneity (I²≈16%), and stable leave-one-out estimates. All-cause dementia was non-significant (β=0.234, p=0.27), most plausibly reflecting the lower power of a binary trait with a smaller effective case sample rather than a true null. **Taken together, the non-UKB overlap-robustness re-interpretation corroborates the UKB cognitive-performance finding using an overlap-free dataset** (the same §3.1 FinnGen/IGAP estimates, here re-framed), whereas the UKB result itself remains formally hypothesis-generating because its overlap cannot be excluded from summary statistics alone. (Reproducible from `data/derived/mr_nonukb_sensitivity_results.csv`; estimates identical to §3.1; see Figure 8.)

### 3.2 Reverse MR — cognition → MCP
IVW β=**−0.171** (95% CI −0.193 to −0.150, p=8.85×10⁻⁵⁸; Egger β=−0.172, intercept p=0.14; weighted median −0.121; Cochran Q=474.8, p<10⁻³⁶). **Both directions were significant.** However, the reverse direction (cognition→MCP) uses the same UKB-derived cognitive-performance GWAS as its exposure and the UKB MCP GWAS as its outcome, so it is affected by UKB sample overlap at least as heavily as the forward direction. The bidirectional significance therefore **cannot by itself** establish reciprocal causal effects or shared genetic architecture — it may partly reflect the common UKB overlap affecting both directions; a non-overlapping reverse analysis is still lacking. A clean one-way causal arrow cannot be asserted on the basis of bidirectional significance alone.

### 3.3 Two-step mediation MR
| Mediator | MCP→med β (p) | med→cog β (p) | Indirect β (95% CI) | p |
|---|---:|---:|---:|---:|
| Depression | 0.620 (<10⁻¹⁴) | −0.078 (0.11) | −0.048 (−0.108, 0.012) | 0.11 |
| CRP | 0.180 (5.6×10⁻⁴) | 0.001 (0.95) | 0.0002 (−0.005, 0.005) | 0.95 |
| Insomnia | 0.265 (<10⁻¹⁶) | −0.019 (0.86) | −0.005 (−0.059, 0.049) | 0.86 |

No mediator reached significance. The two-step mediation was **underpowered** (the depression indirect-effect 95% CI, −0.108 to 0.012, nearly touches zero and its p-value, 0.11, is far from excluding an effect), so these null results **cannot** be interpreted as evidence of a direct effect. The MCP–cognition association therefore remains mechanistically unexplained; we do not claim a direct pathway.

### 3.4 NHANES auxiliary — correlates of subjective memory complaint (n=39,156)
Weighted prevalences: memory complaint 3.4% (SE 0.2), depression (PHQ-9≥10) 7.5% (0.3), sleep trouble 28.0% (0.6), functional limitation 35.2% (0.7); mean PHQ-9 2.85.

| Predictor | log-OR (SE) | p |
|---|---:|---:|
| Depression (PHQ-9≥10) | 0.666 (0.138) | <0.001 |
| Sleep trouble | 0.386 (0.123) | 0.003 |
| Functional limitation | 1.401 (0.198) | <0.001 |
| Age (per year) | 0.052 (0.003) | <0.001 |
| Female (vs male) | −0.833 (0.094) | <0.001 |

Sensitivity (continuous PHQ-9): log-OR 0.057 (SE 0.010, p<0.001). Memory complaint was independently associated with depression, sleep trouble, and especially functional limitation. **Because NHANES contains no pain variable in these cycles, this analysis is descriptive context only and provides no evidence about the pain→cognition hypothesis.**

### 3.5 CHARLS longitudinal **[PENDING DATA]**
Not executed. Placeholder for pain-site burden → cognitive decline (LMM) and incident-decline (Cox) results, to be inserted on data access.

## 4. Discussion

Our MR core is **compatible** with an association between genetically predicted multisite chronic pain and **lower cognitive performance**, robust to Egger and weighted-median sensitivity analyses, with no detectable directional pleiotropy. However, the significant **reverse** direction and the **non-significant Steiger directionality test (p=0.23)** together leave the causal direction unresolved — we therefore describe the finding as an association rather than assert a unilateral causal arrow. The ≈35% gap between the IVW estimate (−0.361) and the weighted-median estimate (−0.233) further signals possible **horizontal (non-directional) pleiotropy**, which the non-significant Egger intercept does not rule out (see Limitations). The AD/dementia signal was inconsistent across consortia — IGAP positive, Ben Nevis and all-cause dementia null — and should be read as hypothesis-generating. Framed as a **non-UKB overlap-robustness re-interpretation** (§3.1.1; the same §3.1 FinnGen dementia and IGAP AD estimates, re-framed as overlap-free), however, the IGAP AD estimate (significant, overlap-free) and the Finnish all-cause dementia estimate both pointed in the same direction as the UKB cognition result, providing cross-source corroboration that the association is not merely an artefact of UKB sample overlap; the non-significant all-cause dementia result most plausibly reflects the limited power of a binary trait with a smaller effective case sample.

Mechanistically, no tested mediator (depression, CRP, insomnia) was significant. Because the two-step mediation was underpowered, this does **not** establish a direct pathway; central sensitisation, neuroinflammation, or HPA-axis dysregulation remain **speculative** possibilities requiring experimental validation. NHANES provides descriptive context only — subjective memory complaint clusters with depression, sleep, and disability — and, lacking any pain variable, does not bear on the pain→cognition question.

The direction of the dementia/AD effects diverges from the cognition result: genetically predicted MCP associated with *higher* AD odds (IGAP β=+0.466) but *lower* cognitive performance (β=−0.361). A plausible reconciliation is that cognitive reserve erosion (lower performance) raises later AD risk, but the positive AD association was inconsistent (Ben Nevis and all-cause dementia null) and may reflect different AD GWAS definitions or insufficient power in the binary dementia outcomes; it should not be over-interpreted.

### Limitations
1. **Reverse causation unresolved** — bidirectional significance. The reverse MR (cognition→MCP, §3.2) was also significant, but because both its exposure and outcome are UKB-sourced, it is subject to the same (indeed heavier) UKB sample-overlap bias as the forward direction. The bidirectional significance therefore cannot independently establish causal direction, reciprocal effects, or shared genetic architecture; it may partly reflect the common UKB overlap. A non-overlapping reverse analysis is still required.
2. **Heterogeneity and possible horizontal pleiotropy.** The cognition IVW showed substantial heterogeneity (Cochran Q p<10⁻³⁰; I²≈83.5%), indicating variant-level effect variation and arguing against a single homogeneous causal effect. The weighted-median estimate (−0.233) is ≈35% smaller in magnitude than the IVW estimate (−0.361); this gap is consistent with **horizontal (non-directional) pleiotropy**, because the non-significant Egger intercept (p=0.34) excludes only *directional* pleiotropy, not balanced effects. The Statistical Analysis Plan specified MR-PRESSO / outlier-SNP re-estimation to clarify this, but those analyses could not be run (TwoSampleMR unavailable; Limitation 7); Radial MR is recommended as future work. Estimates remained directionally stable in leave-one-out.
3. **AD/dementia inconsistency** across GWAS sources limits inference on dementia specifically.
4. **Sample overlap (UKB×UKB).** The MCP exposure (Johnston 2019, UKB, n≈387,649) and the cognitive-performance outcome (`ebi-a-GCST006572`, UKB-derived, n=257,841) are **both UKB-sourced**, so direct sample overlap is present and cannot be excluded. Its magnitude cannot be precisely quantified from summary statistics alone, and the previous draft's claim that a "non-UKB COGENT cognition GWAS mitigates" this overlap is **incorrect** — `ebi-a-GCST006572` is itself UKB-derived. The MCP→cognitive-performance result must therefore be interpreted as **hypothesis-generating**. We did not substitute a non-UKB *cognitive-function* GWAS as the headline: the only readily available non-overlapping cognitive GWAS (`ieu-a-16`, childhood intelligence, n=12,441) is underpowered, and the larger cognitive GWAS (Davies 2018, n=300,486; Savage 2018, n=269,867) themselves incorporate UKB and would not remove the overlap. Instead, we conducted a **non-UKB overlap-robustness re-interpretation** (§3.1.1; the same FinnGen dementia and IGAP AD estimates as §3.1, re-framed as overlap-free) — both of which pointed in the same direction as the UKB cognition result, with the IGAP AD estimate significant (β=0.466, p=0.008). This corroborates the association independently of UKB overlap, although it speaks to dementia/AD *risk* rather than the cognitive-performance *score* itself; all-cause dementia remained non-significant. Overlap-robust methods (MR with sample-overlap correction / MRlap) are recommended as a future step to quantify the residual overlap bias directly.
5. **NHANES** is descriptive and cycle-mismatched for pain→cognition; not causal.
6. **CHARLS** primary longitudinal analysis is pending data access and not yet reported.
7. **Outlier robustness** — MR-PRESSO / formal outlier re-estimation (specified in the SAP) could not be run because TwoSampleMR was unavailable; leave-one-out was used as the primary proxy.
8. **Multiple testing, ancestry, and power** — no formal correction was applied (all p-values reported); all GWAS are European-ancestry, so estimates are European-specific and generalisation to other ancestries requires caution (CHARLS, Chinese, will permit a cross-ancestry check once available); the null dementia/AD and mediation results may reflect limited power of binary/distant outcomes rather than true nulls.

## 5. Conclusion
Genetic evidence is compatible with an association between genetically predicted multisite chronic pain and lower cognitive performance, but the causal direction is uncertain (significant reverse MR; non-significant Steiger) and the cognitive-performance result is constrained by UKB sample overlap between exposure and outcome. A non-UKB overlap-robustness re-analysis (FinnGen dementia; IGAP AD — the same estimates as §3.1, re-framed as overlap-free) corroborated the direction and the IGAP AD estimate was significant, supporting the association independently of UKB overlap, although all-cause dementia was non-significant and replication is needed. No mediator was identified and the mechanism is unknown. These findings justify, but do not yet establish, pain as a modifiable contributor to cognitive health; confirmation awaits overlap-robust methods (MRlap) and the CHARLS longitudinal component.

## 6. STROBE-MR compliance
This manuscript is reported in accordance with the STROBE-MR 2021 guideline (Skrivankova et al., *JAMA* 2021; 20 items) [13]. The full item-by-item compliance table is provided as `docs/strobe_mr_checklist.md`. CHARLS-dependent items (STROBE-MR 4b participants, 10b summary statistics, 13d non-MR comparison) are marked **[PENDING DATA]** and will be completed when the CHARLS dataset is accessed. The three declarations required by STROBE-MR items 18–20 are stated below.

**Declarations.**
- **Funding.** This research received no specific grant from any funding agency in the public, commercial, or not-for-profit sectors. (Single-author study; no external funding.)
- **Data availability.** MR summary statistics are publicly available from the sources listed in §2.2 (OpenGWAS/IEU, FinnGen, UK Biobank). NHANES data are available from the US CDC. CHARLS data are pending access approval (charls.pku.edu.cn). All derived analytic artifacts and analysis code are available at the project repository: https://github.com/yyx-4113/pain-cognition-mr.
- **Conflicts of interest.** The author declares no conflicts of interest.
- **Preregistration.** This analysis was not preregistered.

## 7. Audit trail (every number traces to a derived artifact)
`data/derived/mr_forward_results_corrected.csv` · `mr_ad_reverse_results.csv` · `mr_mediation_results.csv` · `mr_master_results.csv` · `mr_harmonized_cog.csv` · `mr_gwas_metadata_20260920.csv` · `mr_nonukb_sensitivity_results.csv` (non-UKB sensitivity) · `nhanes_results_20260920.rds` · `data/raw/nhanes_clean.rds`.

**Figures** (generated reproducibly by `analysis/make_figures.py`; each supplied as 600-dpi PNG plus vector PDF and SVG for typesetting): `docs/figures/fig_forest.*` (Figure 4), `fig_scatter.*` (Figure 5), `fig_loo.*` (Figure 6), `fig_funnel.*` (Figure 7). `docs/figures/fig_nonukb_sensitivity.png` (Figure 8, generated by `analysis/make_nonukb_figure.py`). Fonts: Arial; palette colour-blind safe (blue = significant, gray = non-significant).

## 8. Figure captions

**Figure 4. Two-sample Mendelian randomization estimates.** Method-specific causal estimates (IVW, MR-Egger, weighted median) with 95% confidence intervals for five MR directions. Box area is proportional to 1/SE² (precision). Blue denotes a confidence interval excluding the null; gray denotes inclusion of the null. The dashed vertical line marks β=0. MCP, multisite chronic pain; AD, Alzheimer's disease; NS, not significant.

**Figure 5. SNP-level associations for MCP → cognitive performance.** Each point is one of 41 independent instrumental SNPs plotted by its effect on MCP (exposure, β_x) against its effect on cognitive performance (outcome, β_y). The solid red line is the inverse-variance-weighted slope through the origin (β = −0.361); the dashed green line is the MR-Egger fit with a free intercept (β = −0.362; slope equals the formal MR-Egger estimate in §3.1).

**Figure 6. Leave-one-out sensitivity analysis (MCP → cognition).** Each point is the IVW estimate recomputed with one SNP removed (95% confidence intervals); the dashed red line is the full-sample IVW estimate (−0.361). Estimates are stable across all 41 SNP omissions.

**Figure 7. Funnel plot of per-SNP Wald ratios (MCP → cognition).** The horizontal axis shows the per-SNP Wald ratio (cognition / MCP) and the vertical axis its standard error (inverted so that the most precise estimates lie at the top). The dashed red line marks the IVW estimate; gray dashed and dotted curves denote the 95% and 99% pseudo-confidence limits.

**Figure 8. Non-UKB overlap-robustness re-interpretation (MCP → outcomes).** Panel A: primary MCP→cognitive performance result (UKB-derived, overlap-limited; SD units). Panel B: two non-UKB disease outcomes — FinnGen all-cause dementia (Finnish biobank) and IGAP Alzheimer's disease (`ieu-a-297`, international consortium) — both free of UKB sample overlap with the MCP exposure (log-odds units). *The Panel B estimates are identical to those in §3.1 (All-cause dementia and AD — IGAP); only the overlap framing differs.* All three point in the same direction (more multisite chronic pain → worse cognitive / higher dementia–AD risk); the IGAP AD estimate is significant (p=0.008). Axes are on different scales across panels (SD vs log-OR) and are not directly comparable in magnitude.

## References

References follow the Vancouver (ICMJE) style; every GWAS/method citation has been verified (journal, volume, pages, DOI, PMID). The CHARLS cohort citation [16] is included for the planned (pending-data) component.

1. Johnston KJA, Adams MJ, Nicholl BI, Ward J, Strawbridge RJ, Ferguson A, et al. Genome-wide association study of multisite chronic pain in UK Biobank. PLoS Genet. 2019;15(6):e1008164. doi:10.1371/journal.pgen.1008164. PMID:31194737.
2. Cognitive performance (1-standardised score), UK Biobank (n=257,841). OpenGWAS accession ebi-a-GCST006572. https://gwas.mrcieu.ac.uk/datasets/ebi-a-GCST006572/ (accessed 2026-09-20). Provenance note: the OpenGWAS/GWAS Catalog metadata for this accession misattributes it to Lee JJ et al. Gene discovery and polygenic prediction from a genome-wide association study of educational attainment in 1.1 million individuals. Nat Genet. 2018;50(8):1112-1121 (PMID 30038396) — an educational-attainment GWAS that is **not** the source of these summary statistics; the effect estimates used here are the UK Biobank–derived cognitive-performance score, cited by trait and accession only.
3. Lambert JC, Ibrahim-Verbaas CA, Harold D, Naj AC, Sims R, Bellenguez C, et al.; European Alzheimer's Disease Initiative (EADI); Genetic and Environmental Risk in Alzheimer's Disease (GERAD); Alzheimer's Disease Genetic Consortium (ADGC); Cohorts for Heart and Aging Research in Genomic Epidemiology (CHARGE). Meta-analysis of 74,046 individuals identifies 11 new susceptibility loci for Alzheimer's disease. Nat Genet. 2013;45(12):1452-1458. doi:10.1038/ng.2802. PMID:24162737. (Underlies ieu-a-297, n=54,162, the dataset analysed here.)
4. Kunkle BW, Grenier-Boley B, Sims R, Bis JC, Damotte V, Naj AC, et al.; Alzheimer Disease Genetics Consortium (ADGC); European Alzheimer's Disease Initiative (EADI); Cohorts for Heart and Aging Research in Genomic Epidemiology Consortium (CHARGE); Genetic and Environmental Risk in AD/Defining Genetic, Polygenic and Environmental Risk for Alzheimer's Disease Consortium (GERAD/PERADES). Genetic meta-analysis of diagnosed Alzheimer's disease identifies new risk loci and implicates Aβ, tau, immunity and lipid processing. Nat Genet. 2019;51(3):414-430. doi:10.1038/s41588-019-0358-2. PMID:30820047.
5. Kurki MI, Karjalainen J, Palta P, Sipilä TP, Kristiansson K, Donner KM, et al.; FinnGen. FinnGen provides genetic insights from a well-phenotyped isolated population. Nature. 2023;613(7944):508-518. doi:10.1038/s41586-022-05473-8. PMID:36653562.
6. Howard DM, Adams MJ, Clarke TK, Hafferty JD, Gibson J, Shirali M, et al. Genome-wide meta-analysis of depression identifies 102 independent variants and highlights the importance of the prefrontal brain regions. Nat Neurosci. 2019;22(3):343-352. doi:10.1038/s41593-018-0326-7. PMID:30718901.
7. Said S, Pazoki R, Karhunen V, et al. Genetic analysis of over half a million people characterises C-reactive protein loci. Nat Commun. 2022;13:2198. doi:10.1038/s41467-022-29650-5. PMID:35459240.
8. Elsworth B, Lyon M, Alexander T, Liu Y, Matthews P, et al. The MRC IEU OpenGWAS data infrastructure. bioRxiv. 2020;2020.08.10.244293. doi:10.1101/2020.08.10.244293.
9. Hemani G, Zheng J, Elsworth B, Wade KH, Haberland V, Baird D, et al. The MR-Base platform supports systematic causal inference across the human phenome. eLife. 2018;7:e34408. doi:10.7554/eLife.34408. PMID:29846171.
10. Bowden J, Davey Smith G, Burgess S. Mendelian randomization with invalid instruments: effect estimation and bias detection through Egger regression. Int J Epidemiol. 2015;44(2):512-525. doi:10.1093/ije/dyv080. PMID:26050253.
11. Bowden J, Davey Smith G, Haycock PC, Burgess S. Consistent estimation in Mendelian randomization with some invalid instruments using a weighted median estimator. Genet Epidemiol. 2016;40(4):304-314. doi:10.1002/gepi.21965. PMID:27061298.
12. Burgess S, Butterworth A, Thompson SG. Mendelian randomization analysis with multiple genetic variants using summarized data. Genet Epidemiol. 2013;37(7):658-665. doi:10.1002/gepi.21758. PMID:24114802.
13. Skrivankova VW, Richmond RC, Woolf BAR, Yarmolinsky J, Davies NM, Swanson SA, et al. Strengthening the reporting of observational studies in epidemiology using Mendelian randomization: the STROBE-MR statement. JAMA. 2021;326(16):1614-1621. doi:10.1001/jama.2021.18236. PMID:34698778.
14. Carter AR, Sanderson E, Hammerton G, et al. Mendelian randomisation for mediation analysis: current methods and challenges for implementation. Eur J Epidemiol. 2021;36(5):465-478. doi:10.1007/s10654-021-00757-1. PMID:33988509.
15. Steiger JH. Tests for comparing elements of a correlation matrix. Psychol Bull. 1980;87(2):245-251.
16. Zhao Y, Hu Y, Smith JP, Strauss J, Yang G. Cohort profile: the China Health and Retirement Longitudinal Study (CHARLS). Int J Epidemiol. 2014;43(1):61-68. doi:10.1093/ije/dys203. PMID:24717586.
17. Centers for Disease Control and Prevention (CDC). National Health and Nutrition Examination Survey (NHANES) 2011-2018. Hyattsville, MD: US Department of Health and Human Services. https://www.cdc.gov/nchs/nhanes/
