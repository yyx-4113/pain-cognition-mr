# pain-cognition-mr

**Multisite chronic pain and cognitive decline / dementia: a bidirectional two-sample Mendelian randomization study (version B — MR + NHANES descriptive support; CHARLS longitudinal pending)**

A reproducible analysis package for the study protocol `方案二_多部位慢性疼痛与认知下降的双队列与双向MR.md`.

## Authors

- Yongxin Yang (ORCID: 0009-0004-9698-6552) — The Second Affiliated Hospital of Fujian University of Traditional Chinese Medicine, Fuzhou, Fujian 350003, China. GitHub: [@yyx-4113](https://github.com/yyx-4113)

## Study summary

| Item | Detail |
|---|---|
| Design | Bidirectional two-sample MR + two-step mediation (primary), with NHANES 2011–2018 **descriptive** correlates of subjective memory complaint; CHARLS China longitudinal component **pending data access** (version B) |
| Exposure | Number of chronic pain sites (0 / 1 / 2 / ≥3) — "pain burden" dose gradient; genetic proxy = multisite chronic pain (MCP) GWAS |
| Outcomes | Cognitive function / decline (CHARLS); cognitive performance GWAS & Alzheimer's / dementia GWAS (MR) |
| Mediators | Depression, C-reactive protein (CRP), insomnia / sleep duration |
| Status | Protocol + data-source verification complete; MR GWAS IDs closed (2026-09-20); MCP summary stats downloaded to `data/raw/`. **MR (forward/reverse/mediation) + NHANES auxiliary EXECUTED 2026-09-20** (results in `data/derived/` + `docs/RESULTS.md`). CHARLS longitudinal **pending user-downloaded `.dta`** in `data/raw/charls/raw/` (sandbox cannot log in to charls.pku.edu.cn). |

## Repository map

```
pain-cognition-mr/
├── README.md                        # this file
├── CITATION.cff                     # citation metadata
├── LICENSE                          # MIT
├── GITHUB_DEPOSIT_SOP.md            # Chinese deposit walkthrough
├── author_verification_statement.md  # author verification statement
├── .github/workflows/release.yml    # release artifact build
├── docs/
│   ├── gwas_catalog.md              # VERIFIED MR GWAS accession IDs (traceable)
│   └── 00_sap.md                    # Statistical Analysis Plan (SAP)
├── analysis/
│   ├── 00_run_all.R                 # master runner (ordered pipeline)
│   ├── 01_charls.R                  # CHARLS longitudinal: LMM/Cox/RCS on charls_clean.rds
│   ├── 02_nhanes.R                  # NHANES auxiliary (survey-weighted) on nhanes_clean.rds
│   ├── 03_mr_pain_cognition.R       # bidirectional MR + MVMR (TwoSampleMR, needs JWT)
│   ├── 04_mr_mediation.R            # two-step MR mediation (needs JWT)
│   ├── 10_charls_extract.R          # raw XPT/SAV -> data/raw/charls_clean.rds
│   ├── 11_nhanes_extract.R         # raw NHANES XPT -> data/raw/nhanes_clean.rds
│   ├── download_charls.R            # read locally-downloaded CHARLS modules (no network)
│   └── download_nhanes.R            # pull NHANES cycle files via nhanesA (needs network)
└── data/
    ├── raw/                         # raw inputs + *_clean.rds (NOT committed; see caveats)
    └── derived/                     # generated tables / figures
```

**Data flow (raw → clean → model):**
```
data/raw/charls/*.XPT|SAV  --10_charls_extract.R-->  data/raw/charls_clean.rds  --01_charls.R-->  data/derived/charls_results_*.rds
data/raw/nhanes/*.XPT      --11_nhanes_extract.R-->  data/raw/nhanes_clean.rds  --02_nhanes.R-->  data/derived/nhanes_results_*.rds
data/raw/chronic_pain-bgen.stats.gz (local) + OpenGWAS JWT  --03/04-->  data/derived/mr_*.rds
```
`10`/`11` carry the trait-definition logic (pain-site count, CHARLS cognition = immediate/delayed recall + drawing, NHANES pain/MCQ/DPQ/SLQ). **All variable names in `10`/`11` are placeholders — verify against the CHARLS / NHANES codebook before a real run** (the scripts stop with a clear message if a required variable is absent).

## Local runbook

Step-by-step commands for everything that must run on your own workstation (JWT metadata, CHARLS/NHANES/CWP downloads, full pipeline) are in **[`docs/LOCAL_RUNBOOK.md`](docs/LOCAL_RUNBOOK.md)**. README below is the short version.

## Reproduce

### Prerequisites
- R ≥ 4.3 with packages: `TwoSampleMR`, `ieugwasr`, `lme4`, `survival`, `rms`, `mice`, `tableone`, `ggplot2`, `clubSandwich` (or `fixest`). Python 3.9+ (standard library only) for the metadata fetch fallback.
- A valid OpenGWAS JWT token — **required since 2026** for all OpenGWAS reads.
  **How to get it (manual, most reliable):**
  1. Log in at <https://api.opengwas.io/profile/> with your OpenGWAS / IEU account.
  2. Copy the JWT token shown on the page.
  3. Set it in R (and/or add `OPENGWAS_JWT=...` to your `~/.Renviron` so it persists):
     ```r
     Sys.setenv(OPENGWAS_JWT = "paste_your_token_here")
     ```
- **OpenGWAS v4 API host (2026).** The data API moved to **`https://api.opengwas.io/api`** (Swagger at `/api/swagger.json`). The legacy `gwas-api.mrcieu.ac.uk` host is being deprecated/blocked in some networks. Make sure your `ieugwasr` is recent enough to use the v4 routes (`POST /gwasinfo?id=...`, `POST /associations`, `POST /ld/clump`); if `gwasinfo()` returns 404, your package is still on the old host. As a robust, host-independent fallback we ship `analysis/fetch_gwas_metadata.py`, which calls the v4 endpoint directly with your JWT.
- **JWT.txt is a secret — never commit it.** It is already git-ignored. Keep it only locally; do not add it to the repository or share it.
- CHARLS and NHANES data must be downloaded by the user under their own access agreements (see caveats). Place extracts under `data/raw/` (see `data/raw/README.md` for exact steps).

### Steps
```bash
# 1. GWAS metadata snapshot (ALREADY PRODUCED 2026-09-20: data/derived/mr_gwas_metadata_20260920.csv).
#    To regenerate with your own JWT:
python3 analysis/fetch_gwas_metadata.py        # v4 API direct (recommended, host-independent)
#  — or, if your TwoSampleMR/ieugwasr is v4-ready:
Rscript analysis/03_mr_pain_cognition.R --metadata-only

# 2. run the full pipeline (requires raw data + packages installed on a networked machine)
Rscript analysis/00_run_all.R
```

Each script writes dated, versioned outputs under `data/derived/` and prints a manifest. No number in the manuscript is reported without a corresponding derived file (audit trail).

## Caveats

- **MCP exposure is NOT in OpenGWAS.** The multisite chronic pain GWAS (Johnston et al., 2019, PMID 31194737) is hosted at the University of Glasgow repository. The correct download path is `https://researchdata.gla.ac.uk/822/1/chronic_pain-bgen.stats.gz` (NOT the bare `…/822/…` path). It has been downloaded to `data/raw/chronic_pain-bgen.stats.gz` (≈417 MB; gzip-verified). Its header columns are `SNP CHR BP GENPOS ALLELE1 ALLELE0 A1FREQ INFO CHISQ_LINREG P_LINREG BETA SE …`; the scripts map these explicitly.
- **CWP (Rahman 2021) is also NOT in OpenGWAS.** GWAS Catalog `GCST011779` exists but `fullPvalueSet = false` (only top hits, no full summary stats). Full stats must come from KP4CD (`Rahman2021_Chronic_Widespead_MSK_Pain_EU`) or the authors; save as `data/raw/cwp_rahman2021.stats.gz` for the optional sensitivity exposure.
- **Sample overlap.** The cognitive-performance outcome (`ebi-a-GCST006572`) is UK Biobank-derived; avoid pairing it with UKB-sourced pain phenotypes (`ukb-b-*`) and the UKB BMI covariate without quantifying overlap (use IGAP AD / FinnGen dementia as the primary MR outcomes; MVMR handles UKB-within-UKB overlap among exposures).
- **UKB phenotype ID renumbering.** `ukb-b-*` IDs change across UKB GWAS releases; always re-confirm with `gwasinfo()` before a run.
- **Raw data not included.** CHARLS / NHANES individual-level files are governed by access agreements and are intentionally omitted from this repository. Only derived, de-identified aggregate tables are committed.
- **Software versions.** Pinned in `00_run_all.R` session-info dump; re-run on R ≥ 4.3 with the package versions recorded there.

## Data availability

Derived tables, figures, and the analysis code are available at this repository (real named repo URL — see `CITATION.cff`). Individual-level cohort data are available from CHARLS (<https://charls.pku.edu.cn/>) and NHANES (<https://www.cdc.gov/nchs/nhanes/>) under their respective access policies. MCP summary statistics: <https://researchdata.gla.ac.uk/822/1/chronic_pain-bgen.stats.gz> (DOIs 10.5525/gla.researchdata.822).
