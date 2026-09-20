# GWAS 数据源核验表（MR 部分）

> 对应方案 `方案二_多部位慢性疼痛与认知下降的双队列与双向MR.md` §2.3「MR 数据源（需在平台检索确认 ID）」。
> 本表为**经核验**的真实 OpenGWAS / GWAS Catalog  accession ID，非凭记忆填写。
> 核验日期：2026-09-20（第二轮收口）。
> 核验方法：OpenGWAS 旧版 REST API（`gwas.mrcieu.ac.uk/api/...`）已于 2026 年下线；现行 v4 数据 API 部署在 **`https://api.opengwas.io/api`**（Swagger: `/api/swagger.json`），需 JWT。其数据为 `POST /gwasinfo?id=...`（`id` 为 multi 查询参数），等价于 TwoSampleMR `gwasinfo()`。
> ID 核验分两阶段：(1) 数据集页 `gwas.mrcieu.ac.uk/datasets/{id}` + 已发表 MR 论文 Table 1 / GWAS Catalog API（按 PMID）交叉确认；(2) **2026-09-20 第三轮：用 v4 API（携带用户 JWT）实测 `POST /gwasinfo`，全部 24 个 OpenGWAS ID 均解析成功，权威元数据已落盘 `data/derived/mr_gwas_metadata_20260920.csv`**——本表 ✅/📄 标记现已全部获实测 gwasinfo 复核。
> **MCP / CWP 为非 OpenGWAS 本地文件，不出现在 gwasinfo 中，见 §1.1 / §1.3。**

## 核验状态图例
- ✅ = 已在 `gwas.mrcieu.ac.uk/datasets/{id}` 页直接核验元数据（ID、样本量、人群、PMID 一致）
- 📄 = 经已发表 MR 论文 Table 1 / GWAS Catalog API 确认；ID 在数据集页 live resolve（页面存在），但 SSR 元数据需 `gwasinfo()` 落盘；样本量以文献/库为准，运行前勿硬编码
- 🔸 = **非 OpenGWAS**：须从原始库下载全量摘要统计到 `data/raw/` 本地处理（MCP、CWP）
- ❓ = 已关闭（见 §6 收口记录）

---

## 1. 暴露（Exposure）

### 1.1 主暴露：多部位慢性疼痛 MCP（必需）
| 项目 | 内容 |
|---|---|
| 性状 | Multisite chronic pain（疼痛部位数，定量性状） |
| 作者 / 年 | Johnston KJA et al., 2019（PLoS Genet, PMID 31194737） |
| 样本量 | N ≈ 387,649（欧洲 UK Biobank） |
| **是否在 OpenGWAS** | **否** —— 该 GWAS 未入库 OpenGWAS |
| 获取途径 | 格拉斯哥大学研究库 DOI **10.5525/gla.researchdata.822**；正确文件路径 `https://researchdata.gla.ac.uk/822/1/chronic_pain-bgen.stats.gz` |
| 2026-09-20 下载状态 | ✅ 已下载至 `data/raw/chronic_pain-bgen.stats.gz`（436,727,270 字节 ≈ 417 MB） |
| 分析方式 | 本地读入后通过 `TwoSampleMR::read_exposure_data()` / `ld_clump()` 自建工具变量 |
| 状态 | 🔸（来源：Johnston 2019 原文 + 多篇 MR 论文引用）；**非 OpenGWAS ID** |

> ⚠️ 方案原稿写「MCP GWAS（Johnston 2019, UKB, n≈387,649）」正确，但须明确它**不走 OpenGWAS 提取**，而须从格拉斯哥库下载后本地处理。这是本方案与多数「纯 OpenGWAS」MR 的关键差异，需在 Methods 透明说明。

### 1.2 复制/敏感性暴露：OpenGWAS 疼痛表型（备用，做重复验证）
| OpenGWAS ID | 性状 | 样本量（case/control） | 人群 | 年 | 状态 |
|---|---|---|---|---|---|
| `ukb-b-8463` | Back pain for 3+ months | 117,404（80,588 / 36,816） | European | 2018 | ✅ |
| `ukb-b-8906` | Knee pain for 3+ months | 97,889（76,910 / 20,979） | European | 2018 | 📄（ID live-confirmed；样本量据文献） |
| `ukb-b-13092` | Headaches for 3+ months | 91,269（41,719 / 49,550） | European | 2018 | ✅ |
| `ukb-b-16118` | Neck/shoulder pain | 105,396（72,887 / 32,509） | European | 2018 | 📄（ID live-confirmed；样本量据文献） |
| `ukb-b-133` | Hip pain for 3+ months | 51,516（40,152 / 11,364） | European | 2018 | 📄（ID live-confirmed；样本量据文献） |
| `ukb-b-19097` | Stomach/abdominal pain | 38,911 | European | 2018 | 📄（ID live-confirmed） |
| `ukb-d-2956` | General pain | 5,473 | European | 2018 | 📄（ID live-confirmed） |
| `ukb-d-4067` | Facial pain | 6,510 | European | 2018 | 📄（ID live-confirmed） |
| CWP（慢性广泛性疼痛） | Chronic widespread pain | 6,914 / 242,929 | European | 2021 (Rahman et al., PMID 33926923) | 🔸 **非 OpenGWAS**；见 §1.3 |

> ⚠️ **UKB 疼痛表型 ID 再编号警示**：不同年份/版本的 UKB GWAS 发布中 `ukb-b-*` 编号不统一（如某 2025 MR 论文将 back pain 记为 `ukb-b-9838`、knee `ukb-b-16254`）。本表所用 ID 为当前 OpenGWAS 分配（页面 resolve 已确认），正式运行前须以 `gwasinfo()` 复核样本量与 nsnp，避免使用过期编号。

### 1.3 敏感性暴露：CWP（慢性广泛性疼痛，本地文件）
| 项目 | 内容 |
|---|---|
| 性状 | Chronic widespread pain（自评"全身痛">3 月，或膝/肩/髋/背同时痛，或纤维肌痛） |
| 作者 / 年 | Rahman MS et al., 2021（Ann Rheum Dis, PMID 33926923） |
| 样本量 | 6,914 cases / 242,929 controls（UKB discovery）+ 6 个欧洲复制队列 |
| GWAS Catalog | `GCST011779` —— 但 **`fullPvalueSet = false`**（库内仅 top hits，**无全量摘要统计**） |
| **是否在 OpenGWAS** | **否** —— 与 MCP 同属"本地文件" |
| 全量统计获取 | KP4CD 知识门户 Dataset ID `Rahman2021_Chronic_Widespead_MSK_Pain_EU`（https://www.kp4cd.org/node/1687）或向作者索取 |
| 分析方式 | 下载后本地读入，作为 MCP 的"独立疼痛定义"敏感性暴露，验证 MCP→认知结论的稳健性 |
| 状态 | 🔸（GCST 编号确认于 GWAS Catalog API；全量统计须外部获取） |

---

## 2. 结局（Outcome）

### 2.1 主结局：认知表现（连续变量，效能最高）
| OpenGWAS ID | 性状 | 样本量 | 人群 | 作者 / 年 | PMID | 状态 |
|---|---|---|---|---|---|---|
| **`ebi-a-GCST006572`** | Cognitive performance (UK Biobank–derived)¹ | 257,841 | European | UK Biobank² | — | ✅ |

> 说明：本 ID 为 **UK Biobank 衍生的认知表现 GWAS（n=257,841），并非 COGENT**。其 OpenGWAS/GWAS Catalog 元数据误挂到 Lee et al. 2018（受教育年限，PMID 30038396），该文献非本性状来源；所用汇总统计为 UKB 衍生认知表现评分。因 MCP 暴露与本结局均为 UKB 来源，存在样本重叠（详见稿件 §2.2 与局限 #4）。已在 `gwas.mrcieu.ac.uk/datasets/ebi-a-GCST006572` 核验。

¹ 认知表现性状由 UK Biobank 衍生（汇总统计为该队列认知评分 GWAS），**非 COGENT**；OpenGWAS/GWAS Catalog 元数据误挂 Lee et al. 2018（受教育年限，PMID 30038396），该文献非本性状来源。
² UK Biobank 衍生；因 MCP 暴露与本结局均为 UKB 来源，样本重叠存在（详见稿件 §2.2 与局限 #4），结果与 IGAP/FinnGen 等非 UKB 结局须区别解读。

### 2.2 敏感性认知结局
| OpenGWAS ID | 性状 | 样本量 | 人群 | 状态 |
|---|---|---|---|---|
| `ebi-a-GCST006250` | Intelligence | 269,867（据文献） | European | 📄（ID live-confirmed） |
| `ieu-a-16` | Childhood intelligence | 12,441（据文献） | European | 📄 |

### 2.3 痴呆 / 阿尔茨海默病（AD）结局
| OpenGWAS ID | 性状 | 样本量（case/control） | 人群 | 作者 / 年 | 状态 |
|---|---|---|---|---|---|
| **`ieu-a-298`** | Alzheimer's disease | 74,046（25,580 / 48,466） | European | Lambert, 2013（IGAP, PMID 24162737） | ✅ |
| `ieu-a-297` | Alzheimer's disease | 54,162（17,008 / 37,154） | European | Lambert, 2013（IGAP） | ✅（上一轮） |
| `ieu-b-2` | Alzheimer's disease | 63,926（21,982 / 41,944） | European | Kunkle BK, 2019 | 📄 |
| `ieu-b-5067` | Alzheimer's disease | — | European | Woolf B, 2022 | 📄 |
| `finn-b-F5_DEMENTIA` | Dementia（全因，FinnGen R5） | 216,771（7,284 / 209,487） | European | FinnGen R5 | 📄（ID live-confirmed；nsnp=16,380,463） |

> 主 AD 结局建议优先 `ieu-a-298`（IGAP，样本量最大）；全因痴呆用 `finn-b-F5_DEMENTIA` 补充。注意 `ieu-a-297`/`ieu-a-298`（IGAP，均为非 UKB 联盟）与 UKB 认知结局（`ebi-a-GCST006572`，UK Biobank 衍生认知表现）**样本不重叠**；但 UKB 认知 GWAS 与 UKB 暴露 MCP 之间**存在样本重叠**，须警惕（见 §5）。本分析实际使用的 AD 结局为 `ieu-a-297`（n=54,162）；主 AD 结局应与稿件一致使用 `ieu-a-297`。

---

## 3. 中介（Mediators，两步 MR）

| 角色 | OpenGWAS ID | 性状 | 样本量 | 人群 | 作者 / 年 | 状态 |
|---|---|---|---|---|---|---|
| 抑郁 | **`ieu-b-102`** | Major depression | 500,199（170,756 / 329,443） | European | Howard DM / PGC, 2019 | ✅ |
| CRP（炎症） | **`ebi-a-GCST90029070`** | C-reactive protein levels | 575,531（CHARGE+UKB） | European | Said S et al., 2022（Nat Commun, PMID 35459240, GCST90029070） | ✅（页级核验：nsnp=10,713,245, build HG19/GRCh37） |
| 失眠/睡眠 | **`ukb-b-3957`** | Sleeplessness / insomnia | 462,341 | European | Elsworth, 2018 | ✅（上一轮） |
| 睡眠时长 | `ukb-b-4424` | Sleep duration | 460,099 | European | UKB, 2018 | ✅ |
| 睡眠时长（备） | `ieu-a-1088` | Sleep duration | 128,266（据文献） | European | — | 📄 |

> CRP 首选 **Said 2022（N≈575k，266 独立位点，`ebi-a-GCST90029070`）**，已于 2026-09-20 通过 GWAS Catalog API（PMID 35459240 → `GCST90029070`）与 `gwas.mrcieu.ac.uk/datasets/ebi-a-GCST90029070` 双重确认。`ieu-b-4763`（CRP N=20,623）仅作弱工具后备，**不推荐**作为主中介。

---

## 4. 反向 MR / MVMR 协变量

| 用途 | OpenGWAS ID | 性状 | 样本量 | 状态 |
|---|---|---|---|---|
| 反向 MR（认知→疼痛） | `ebi-a-GCST006572`（作暴露） | Cognitive performance | 257,841 | ✅ |
| MVMR：教育 | `ieu-a-755` | Years of schooling | 据 SSGAC（运行前 `gwasinfo()` 复核） | 📄（ID live-confirmed） |
| MVMR：吸烟 | `ieu-b-4877` | Smoking initiation | 据文献（Wootton/Tobacco Genetics） | 📄（ID live-confirmed） |
| MVMR：BMI | **`ukb-b-19953`** | Body mass index | 461,460 | ✅（页级核验：nsnp=9,851,867, build HG19/GRCh37, Elsworth 2018） |

> BMI 协变量已升级为 `ukb-b-19953`（N=461,460，当前 OpenGWAS 内最大的 BMI GWAS 之一），替代原 `ieu-a-2`（Locke 2015, N=152,893）。因 MVMR 暴露代理（`ukb-b-*` 疼痛表型）与 BMI 同为 UKB 来源，样本重叠由 MVMR 方法本身处理；反向 MR 与结局重叠仍需在 §5 框架内量化。

---

## 5. 关键偏倚与重叠警示（写入 Methods）
1. **MCP / CWP 均非 OpenGWAS**：须从格拉斯哥库（MCP: DOI 10.5525/gla.researchdata.822，路径 `822/1/chronic_pain-bgen.stats.gz`）与 KP4CD（CWP: `Rahman2021_Chronic_Widespead_MSK_Pain_EU`）下载后本地处理，明确说明。
2. **样本重叠**：`ebi-a-GCST006572`（UKB 认知）若与任一 UKB 来源暴露/协变量（`ukb-b-*`）配对，存在样本重叠风险→优先用非 UKB 认知结局或 IGAP AD；MVMR 中量化。
3. **JWT 强制**：2026 年起所有 OpenGWAS 读取端点需 JWT；分析脚本须 `Sys.setenv(OPENGWAS_JWT=...)` 并在 README 写明获取步骤（`api.opengwas.io/profile/`）。
4. **UKB 表型 ID 再编号**：`ukb-b-*` 编号随 UKB 发布版本变动，运行前以 `gwasinfo()` 复核。
5. **所有 ID 最终以 `gwasinfo()` 回显落盘**，附样本量/人群/nsnp 快照，保证可复现与溯源性。

---

## 6. 待办收口记录（2026-09-20 第二轮）

- [x] **CRP（Said 2022）GCST 确认** → `GCST90029070` → OpenGWAS `ebi-a-GCST90029070`（✅ 页级核验）。替换原 ❓。
- [x] **CWP（Rahman 2021）状态确认** → 非 OpenGWAS；GWAS Catalog `GCST011779` 但 `fullPvalueSet=false`（仅 top hits），全量统计须从 KP4CD 或作者获取。改为 🔸 本地文件类。原 ❓ 关闭。
- [x] **MVMR BMI 大样本确认** → `ukb-b-19953`（N=461,460）替代 `ieu-a-2`。原 ❓ 关闭。
- [x] **MCP 摘要统计下载** → `data/raw/chronic_pain-bgen.stats.gz`（~417 MB）已落盘。
- [x] 页级核验升格 ✅：ukb-b-8463、ukb-b-13092、ieu-a-298、ukb-b-4424、ebi-a-GCST90029070、ukb-b-19953。
- [x] **gwasinfo 实测落盘（2026-09-20 第三轮）** → 用 v4 API `POST https://api.opengwas.io/api/gwasinfo?id=...`（携带用户 JWT）实测全部 24 个 OpenGWAS ID，权威元数据已落盘 `data/derived/mr_gwas_metadata_20260920.csv`（脚本 `analysis/fetch_gwas_metadata.py`，等价于 `03_mr_pain_cognition.R --metadata-only`）。本沙箱此前对旧数据主机 `gwas-api.mrcieu.ac.uk` TLS 被拦，但 v4 主机 `api.opengwas.io` 可达，故改用 v4 直连。
- [ ] 下载 CWP 全量摘要统计（KP4CD / 作者）至 `data/raw/`。
- [ ] 下载 CHARLS / NHANES 提取至 `data/raw/`（见 `data/raw/README.md` 与 `analysis/download_*.R`；CHARLS 需账号登录，无法代下载）。
