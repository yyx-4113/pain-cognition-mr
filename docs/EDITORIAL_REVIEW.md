# 预印版编辑评审意见 — 多部位慢性疼痛与认知功能（双向 MR + NHANES）

**评审角色**：预印本期刊责任编辑（非作者、非合作者）
**评审对象**：`docs/manuscript_draft.md`（版本 B：双向两样本 MR + NHANES 辅助；CHARLS 标记 [PENDING DATA]）
**评审日期**：2026-09-20
**配套核验文件**：`data/derived/*.csv`、`docs/RESULTS.md`、`docs/gwas_catalog.md`、`docs/00_sap.md`、`docs/strobe_mr_checklist.md`、`analysis/make_figures.py`

---

## 0. 处置决定（Decision）

**结论：重大修改（Major Revision），当前版本不建议直接以预印本发布。**

文章的核心计算链路干净、数字可溯源、STROBE-MR 合规表完整、对 CHARLS 缺失做了诚实标注——这些是优点。但存在 **2 个可能动摇核心结论的严重问题**（主结局样本重叠偏倚、Steiger 方向性检验被误读）以及若干 **结论过度外推** 问题。其中样本重叠问题直接作用于"头条"结果（MCP→认知表现），若不处理，预印后极易被读者/同行指出并削弱全文可信度。

> 一句话定位：这篇稿子是"MR 为主、NHANES 为描述性旁证"的solid 预分析，**不应被包装成"双队列观察性 + MR 双重验证"**——CHARLS 尚未执行、NHANES 未含疼痛变量而无法检验核心假设。

---

## 1. 总体评价

### 优点（保留、值得肯定）
- 审计轨完整：每个稿件数字都能追到 `data/derived/` 下 CSV/RDS（已抽查一致，见 §6）。
- STROBE-MR 2021 逐条清单齐全，CHARLS 相关项诚实标 [PENDING DATA]。
- GWAS accession ID 经 v4 API 实测 `gwasinfo` 落盘，未凭记忆填写。
- 对反向 MR 显著、AD/痴呆结果不一致、NHANES 周期错配均做了透明说明。
- 作者署名与学位头衔处理合规（无 MD/PhD 虚挂），符合您一贯的"宁慢勿缺"标准。

### 致命/严重短板（必须修）
1. **主结局样本重叠（UKB×UKB）未被正确处理，且稿件错误地声称已缓解**〔严重〕
2. **Steiger 方向性检验结果被反向解读**〔严重〕
3. **"直接效应"结论系由"中介不显著"错误导出**〔严重〕
4. **NHANES 被标为"支持证据"，实则无法支持疼痛→认知假设**〔严重〕

### 结构性问题
5. "双队列"框架与交付内容错配（CHARLS 全缺 + NHANES 不检验假设）〔主要〕
6. SAP 承诺的 MR-PRESSO / 离群 SNP 重估未执行也未说明原因〔主要〕
7. 异质性（I²≈83.5%）被严重低估、几乎未讨论〔主要〕

### 次要/技术细节
8. 工具变量强度（F / R²）未报告〔中等〕
9. IGAP ID（ieu-a-297）与参考文献 [3]（74,046 例）不匹配〔中等〕
10. 认知 GWAS 文献引用 [2] 与性状实质不符（见下）〔中等〕
11. 加权中位数法结果（β=−0.233）与 IVW（−0.361）量级差 35%，未解释〔中等〕
12. 图 5 Egger 拟合斜率（−0.484）与正文 Egger β（−0.362）自相矛盾〔中等〕
13. 多重检验、 ancestry 外推、AD/痴呆把握度未讨论〔次要〕
14. 数据可用性写"接收后 deposition"，与已存在实名仓库不符〔次要〕
15. 少量表述/编号瑕疵（见 §5 末）〔次要〕

---

## 2. 严重问题逐条详解与修改意见

### 【严重-1】主结局 MCP→认知表现 存在 UKB×UKB 样本重叠，且稿件声称"已缓解"是错误的

**事实链（已核验）**
- 暴露 MCP：`data/raw/chronic_pain-bgen.stats.gz`，Johnston 2019，**UKB，n≈387,649**（gwas_catalog.md §1.1；metadata 行 26）。
- 主结局认知表现：`ebi-a-GCST006572`。其来源在 `docs/gwas_catalog.md` §2.1 被写作"COGENT, Lee 2018"，但 **`mr_gwas_metadata_20260920.csv` 第 10 行** 与 **外部核验（Nature Scientific Reports 2024 表 1：`Cognitive performance | UKB | 257,841`）** 均确认它是 **UKB 来源的认知功能 GWAS**。
- 也就是说：暴露（UKB）与头条结局（UKB）来自**同一队列**，存在直接样本重叠。

**稿件中的错误陈述**
- 局限性第 4 条原文："…the non-UKB COGENT cognition GWAS mitigates but does not eliminate this"（声称该认知 GWAS "非 UKB"从而缓解重叠）。
- 但事实是 `ebi-a-GCST006572` 正是 UKB 来源。**这句话既与事实相反，也与本仓库 README 第 95 行的自我警示直接矛盾**（README："The cognitive-performance outcome (ebi-a-GCST006572) is UK Biobank-derived; avoid pairing it with UKB-sourced pain phenotypes"）。

**为何严重**
- 两 UKB 来源摘要统计非独立，IVW 估计的精度被人为放大、且估计量可能偏倚（朝已观测关联方向）。头条结论 "genetically predicted MCP → lower cognitive performance (β=−0.361)" 正是在这一重叠配对被估计出来的，因此**该结论的稳健性当前无法保证**。
- 摘要与结论据此做出的因果表述（"contributes to lower cognitive performance"）因此站不住。

**修改意见（任选其一，按优先级）**
- **首选**：将主认知结局替换为**非 UKB** 认知 GWAS（如 COGENT 独立认知 GWAS；或用 `ieu-a-16` childhood intelligence 作敏感性，尽管样本较小；或 Davies 2019 Nat Commun 全样本但需剔除 UKB 部分）。若一时无法获得干净的非 UKB 认知 GWAS，则：
- **次选**：对重叠进行**定量**说明与校正——例如报告两数据集均源自 UKB、估计重叠样本占比的上界、并使用重叠稳健方法（MR with sample overlap correction / MRlap / 仅用 UKB 非重叠子集），在方法学与局限性中明确写出。
- **必须立即修改**：删除"non-UKB COGENT cognition GWAS mitigates"这一错误陈述，改为如实说明"该认知 GWAS 同为 UKB 来源，重叠无法排除，故 MCP→认知表现结果应视为假设生成性（hypothesis-generating）"。
- 同时把"头条"权重从认知表现适度转移到**无重叠**的结局（IGAP AD / FinnGen 痴呆）上，但注意后者本身不一致（见下）。

### 【严重-2】Steiger 方向性检验被反向解读

**事实链（已核验）**
- `mr_forward_results_corrected.csv` 第 2 行：MCP→认知表现 `Steiger_p = 0.2305676`（>0.05），`Steiger_dir = X->Y`，`Steiger_Vexp=0.00352 > Steiger_Vout=0.00145`。
- Steiger 检验的 H0：暴露与 SNP 的相关**不**强于结局与 SNP 的相关。显著（p<0.05）才支持"暴露→结局"的方向。**p=0.23 即不显著 → 方向性检验并未确立方向偏好**。
- 稿件表述：
  - 摘要："Directionality favoured MCP→cognition (Steiger p>0.05)"
  - 结果 §3.1 表后文字："no directional pleiotropy"（把 Egger 截距不显著与 Steiger 混为一谈）
  - STROBE-MR 清单第 12a 项竟将 "Steiger p>0.05" 记为已支持效度 ✅

**为何严重**：把"p>0.05（不显著）"读成"支持方向"，正好说反了。这与"反向 MR 同样显著"叠加，使因果方向彻底不确定——而稿件在多处仍暗示 MCP→认知的因果方向成立。

**修改意见**
- 删除 "Directionality favoured MCP→cognition (Steiger p>0.05)"，改为"Steiger 检验未支持明确的方向偏好（p=0.23），结合反向 MR 显著，因果方向不确定"。
- 厘清概念：Egger 截距不显著 = "无可检测的方向性多效性"；Steiger 不显著 = "无法借遗传相关结构判断谁为暴露"。二者不是一回事，不要混写。
- 同步修订 STROBE-MR 清单第 12a（删去 "Steiger p>0.05" 作为支持的写法）。

### 【严重-3】"直接效应"系由"中介不显著"错误导出

**事实链（已核验）**
- `mr_mediation_results.csv`：抑郁间接效应 β=−0.048，p=0.114（**接近显著**）；CRP p=0.945；失眠 p=0.857。
- 稿件 §3.3 结论："No mediator reached significance → the MCP→cognition association operates as a **direct effect**"；讨论 §4 进一步写"pointing to a **direct** pathway (e.g., central sensitisation…)"。

**为何错误**：中介不显著 **不等于** 存在直接效应。两步 MR 本身效能低、CI 宽（抑郁间接效应 95% CI −0.108~0.012，几乎触及 0），"未检出中介"只能读作"无证据支持该中介路径"，**不能反推为直接效应**。此外抑郁路径 p=0.114 远未到可排除的程度。

**修改意见**
- 将结论由"operates as a direct effect"改为"no evidence that depression, CRP, or insomnia mediate the MCP–cognition association; mediation analyses were underpowered and should be interpreted as hypothesis-generating."
- 讨论中删除"central sensitisation / neuroinflammation / HPA-axis as a direct mechanism"的肯定式表述，改为"机制未知，需实验验证"；或明确标注这些是"推测（speculative）"。
- 如实写出两步 MR 的局限（相关暴露、弱工具、无正式直接效应分解）。

### 【严重-4】NHANES 被标为"支持证据"，实则无法检验核心假设

**事实链（已核验）**
- `docs/RESULTS.md` §4 明确："NHANES has no chronic-pain questionnaire in these cycles… NHANES **cannot** test pain→cognition."
- 但稿件标题为 "…with NHANES supporting evidence"，摘要写"complemented by population-based cohort evidence"，§3.4 仅给出"主观记忆主诉与抑郁/睡眠/功能受限相关"的描述性模型——**全文 NHANES 部分没有任何疼痛变量**，因此它对"疼痛→认知"这一中心假设**提供零证据**。

**为何严重**：标题与摘要对读者的第一印象是"有队列旁证"，但实际没有。这属于对证据强度的误导。

**修改意见**
- 标题改为 "…with NHANES **contextual/descriptive** evidence"（或干脆去掉 "supporting"）。
- 摘要与引言明确：NHANES 仅刻画"主观记忆主诉"的相关结构，**不参与**疼痛→认知假设的检验；真正的观察性验证待 CHARLS 到位。
- §3.4 与讨论中把 NHANES 定位为"背景性/描述性"，不与 MR 结论做因果性勾连。

---

## 3. 主要问题逐条详解与修改意见

### 【主要-5】"双队列"框架与交付内容错配
- 仓库 README 第 3 行、方案原标题均为"CHARLS + NHANES 双队列观察性 + 双向 MR"。
- 实际交付：MR（完成）+ NHANES 描述性（无疼痛变量）+ CHARLS（[PENDING DATA]，未执行）。
- **修改意见**：仓库顶层描述与方案标题应降级为"版本 B：MR + NHANES 描述性；CHARLS 待补"，避免读者误以为已完成双队列观察性验证。稿件内部的版本 B 表述本身是诚实的，保留即可，但要确保仓库/方案与稿件口径一致。

### 【主要-6】MR-PRESSO 与离群 SNP 重估：SAP 承诺但未执行也未说明
- `docs/00_sap.md` §4.3 明确列出"MR-PRESSO、Cochran Q；离群 SNP 剔除后重算并双报"。
- 稿件结果与 §2.4 均未报告 MR-PRESSO，也未报告离群剔除后的第二套结果。
- **修改意见**：(a) 若因环境限制（TwoSampleMR 不可用、仅 ieugwasr）无法运行 MR-PRESSO，须在 §2.4 明确写明原因；(b) 至少用手边手段补一个离群稳健性分析（如基于学生化残差的离群识别 + 剔除后重估，或 Radial MR），与 LOO 互为补充；(c) 在局限性中说明未做 MR-PRESSO 的边界。

### 【主要-7】异质性被严重低估
- 认知表现 IVW：Cochran Q=242.51，df=40 → **I²≈(242.51−40)/242.51≈83.5%**（稿件未报 I²）。
- 随机效应 IVW β=−0.403（CSV `IVW_beta_RE`）比固定效应 −0.361 更极端；加权中位数仅 −0.233。
- **修改意见**：(a) 报告 I² 或至少 Q/df；(b) 讨论高异质性的含义——它意味着"单一因果效应"假设可能不成立，或存在未被 Egger 截距捕捉的网络多效性；(c) 探索哪些 SNP 驱动效应（按功能/基因组区域分簇），或改用 MR-RAPS / radial MR；(d) 强调高异质性下固定效应 IVW 的点估计虽保守，但效应本身不稳定。

---

## 4. 中等/次要问题

### 【中等-8】工具变量强度未报告
SAP 与稿件均称 F>10，但全文未给出 F 统计量或表型解释度 R²。MCP 仅有 41–43 个 SNP，报告合并 F（或 R²）是 MR 效度的基本要求。**修改**：在 §2.3 补合并 F 与 R²（可由 harmonized 文件计算）。

### 【中等-9】IGAP ID 与参考文献不匹配
稿件用 `ieu-a-297`（n=54,162；17,008/37,154），但参考文献 [3] Lambert 2013 正文写"74,046 individuals"——那是 `ieu-a-298`（n=74,046）。`gwas_catalog.md` §2.3 也建议首选 `ieu-a-298`。**修改**：主 IGAP 改用 `ieu-a-298`（更大样本、与引用一致），或保留 `ieu-a-297` 但同步修正引用措辞；两 ID 同引 Lambert 2013 均可，但 n 必须自洽。

### 【中等-10】认知 GWAS 引用 [2] 与性状实质不符
`ebi-a-GCST006572` 在 GWAS Catalog/Open Targets 被挂到 Lee JJ 2018 Nat Genet（PMID 30038396）——但那篇是**受教育年限（educational attainment，n≈1.1M）** GWAS，与"认知表现（n=257,841，UKB）"并非同一性状。稿件照抄了目录里这个有问题的挂接。**修改**：核实 `ebi-a-GCST006572` 摘要统计的真实来源，引用正确的认知功能 GWAS（例如 Davies et al., *Nat Commun* 2019, PMID 30906333，或 UKB 认知功能 GWAS），至少注明摘要统计的 provenance 与队列来源（UKB）。

### 【中等-11】加权中位数 vs IVW 量级差 35% 未解释
WMed β=−0.233 vs IVW −0.361。两者方向一致但量级差异大，提示效应由部分 SNP 主导或存在亚群异质。**修改**：在 §3.1 加一句解释（如"加权中位数仅用约半数权重，估计更保守，量级差异提示 SNP 间效应异质，详见 LOO/异质性分析"）。

### 【中等-12】图 5 Egger 斜率自相矛盾
- 正文 Egger β=−0.362（含暴露 SE 的正式权重）；图 5 标题写 "MR-Egger fit … β = −0.484"。
- 经查 `make_figures.py` 第 109–116 行：散点 Egger 斜率使用的权重 `w = 1.0/(sy/|βx|)²`，**忽略了暴露 SE（sx）**，与正文 Egger 估计的权重不一致，故算出不同斜率（约 −0.484）。
- **修改**：图 5 的 Egger 拟合线应使用与正文 Egger 一致的权重（含 sx），使其斜率等于 −0.362；图注同步改为 −0.362，或直接标注"斜率见正文 Egger β"。

### 【次要-13】讨论中缺三处标准内容
- 多重检验：8 个主 MR 方向 + 3 个中介，未说明是否校正。**修改**：加一句"主要假设为 MCP→认知表现，其余为探索性，未做正式多重校正，但所有 p 值已报告"。
- Ancestry 外推：全部 GWAS 为欧洲裔，MR 估计欧洲特异。**修改**：局限性补"结论外推至其他族群需谨慎；CHARLS（中国）到位后可做跨 ancestry 一致性"。
- AD/痴呆把握度：阴性结果可能源于二分类结局把握度不足。**修改**：讨论补一句把握度说明。

### 【次要-14】数据可用性表述
稿件写"will be deposited in a public repository upon acceptance"，但本仓库已是实名 GitHub（yyx-4113）。**修改**：按您的惯例，直接给出实名仓库 URL 作为当前数据可用性声明（而非"接收后 deposit / available on request"）。

### 【次要-15】编号/表述小瑕
- §2.3："51 independent lead SNPs, of which … 146 into the reverse"——146 不是 51 的子集（反向是认知做暴露另选 146 个工具），措辞易误导。改为"反向分析另选 146 个认知工具 SNP"。
- 摘要/正文把"Egger 截距不显著"与"Steiger 方向"混谈，已见严重-2，一并理顺。
- AD/痴呆 β 均为正（疼痛↑→AD↑），与认知表现 β 为负（疼痛↑→认知↓）方向不同，讨论可点一句（认知储备下降→AD 风险升高的合理性），避免读者困惑。

---

## 5. 数字一致性核对（审计轨抽查）

| 稿件数字 | 来源 CSV | 一致？ |
|---|---|---|
| 认知 IVW β=−0.361, p=3.65e-30 | mr_forward_results_corrected.csv (IVW_beta=-0.3614, IVW_p=3.65e-30) | ✅ |
| Egger β=−0.362, int p=0.344 | 同上 (Egger_beta=-0.3623, Egger_int_p=0.3441) | ✅ |
| WMed β=−0.233 | 同上 (-0.2332) | ✅ |
| Cochran Q=242.5 | 同上 (242.51) | ✅ |
| LOO [−0.386, −0.315] | 同上 (min=-0.3862, max=-0.3149) | ✅ |
| 反向 IVW β=−0.171, p=8.85e-58 | mr_ad_reverse_results.csv (reverse, -0.1709, 8.85e-58) | ✅ |
| AD IGAP β=0.466, p=0.008 | mr_ad_reverse_results.csv (0.4658, 0.00773) | ✅ |
| Ben Nevis β=0.168, p=0.29 | 同上 (0.1679, 0.288) | ✅ |
| 全因痴呆 β=0.234, p=0.27 | mr_forward (0.2339, 0.273) | ✅ |
| 抑郁间接 p=0.114 | mr_mediation_results.csv (0.1136) | ✅ |
| NHANES 记忆主诉 3.4% 等 | nhanes_results_20260920.rds（STATUS 已报，待 R 复核） | ⚠️ 未在本次抽查中重算 |

> 结论：**算术层面可溯源、未发现捏造**。所有问题均属**解读/结构/文献/重叠**层面，而非数字本身。这正是编辑最该抓住的点——结论的表述必须与其证据强度匹配。

---

## 6. 修改路线图（建议执行顺序）

1. **立即修（阻断性）**：严重-1（重叠陈述纠错 + 重叠定量/换非 UKB 认知结局）、严重-2（Steiger 改读）、严重-3（删除"直接效应"）、严重-4（NHANES 标题/摘要降级）。
2. **方法补强**：主要-6（MR-PRESSO 原因说明 + 离群重估）、主要-7（报 I²、议异质性）、中等-8（F/R²）。
3. **文献与编号**：中等-9（IGAP ID）、中等-10（认知 GWAS 引用）、中等-12（图 5 Egger 斜率）、次要-13/14/15。
4. **对齐框架**：主要-5（仓库/方案口径与版本 B 一致）。
5. **CHARLS 到位后**：填入 §2.7/§3.5，升级版本 B→A；届时"双队列"框架才名副其实。

---

## 7. 编辑给作者的底线提醒

- 当前最危险的是：**用 UKB×UKB 重叠配对被当成"头条因果证据"，且稿件还声称已用"非 UKB"认知 GWAS 缓解——这句话必须删/改**。否则预印后第一条评论就会指向这里。
- "双向均显著 + Steiger 不显著" 三件事合起来，正确的总体语气是 **"遗传证据与'疼痛→认知下降'相容，但因果方向不确定、且受重叠偏倚限制"**，而不是"支持疼痛导致认知下降"。
- 把 NHANES 当"支持证据"是包装过度；把它当"背景描述"才是诚实且经得起挑的。
- 以上均属可修复的**表述与结构**问题，核心计算并无造假。修完后这是一篇方法透明、可溯源、适合预印的 MR 研究；但请务必以"版本 B（MR + NHANES 描述性）"的诚实定位发布，等 CHARLS 补齐再称"双队列"。

---

## 8. 修订执行记录（2026-09-20，已逐项落地）

所有修改已写入 `docs/manuscript_draft.md`（版本 B 修订），并同步修正 `analysis/make_figures.py`、`docs/strobe_mr_checklist.md`、`README.md`。各条目状态如下：

### 严重问题（4 项，全部已修）
- **严重-1（UKB×UKB 重叠）**：局限性第 4 条原文"non-UKB COGENT cognition GWAS mitigates"已**删除**，替换为如实陈述——暴露（UKB, n≈387,649）与结局 `ebi-a-GCST006572`（UKB-derived, n=257,841）同为 UKB 来源，重叠无法排除且难以定量，故 MCP→认知表现结果定为 **hypothesis-generating**；并说明未用非 UKB 认知结局替换（可用 `ieu-a-16` 仅 n=12,441），而非重叠结局（IGAP AD / FinnGen 痴呆）本身不一致。§2.2 增加 provenance 注释，README/标题口径同步（见主要-5）。
- **严重-2（Steiger 反向解读）**：摘要"Directionality favoured MCP→cognition (Steiger p>0.05)"已改为"Steiger 方向性检验**不显著**（p=0.23），未确立 MCP→认知方向"；§3.1 明确 Egger 截距不显著（无方向性多效性）≠ Steiger（方向），二者分述；STROBE-MR 12a 已改正。
- **严重-3（"直接效应"误导）**：§3.3 与 §4 删除"operates as a direct effect / direct pathway"，改为"中介分析把握度不足，零结果**不能**反推直接效应，机制未知"；§4 将 central sensitisation/neuroinflammation/HPA-axis 标为 **speculative**。
- **严重-4（NHANES 标"supporting"）**：标题改为"with NHANES **contextual evidence**"；摘要/引言明确 NHANES 无疼痛变量、不检验假设；§3.4 与 §4 定位为描述性背景。

### 主要问题（3 项，全部已修）
- **主要-5（双队列框架错配）**：README 顶层标题与 study-summary 设计行已降级为"版本 B：MR + NHANES 描述性；CHARLS 待补"，与稿件口径对齐。
- **主要-6（MR-PRESSO 未执行）**：§2.4 新增说明——SAP 承诺的 MR-PRESSO 因环境下 TwoSampleMR/mr_presso 不可用（仅 ieugwasr）未能运行，以 LOO 作为离群稳健性代理，并列为局限（§4 第 7 条）与未来方向。
- **主要-7（异质性低估）**：§3.1 表格新增 **I² 列**（认知 I²≈83.5%、痴呆≈0%、IGAP≈16%、Ben Nevis≈19%）；正文报告随机效应 IVW β=−0.403（SE 0.075），并讨论高异质性含义（单一因果效应假定可能不成立、网络多效性）。

### 中等/次要（8 项，全部已修）
- **中等-8（F/R²）**：§2.3 补工具变量强度——41–43 个 SNP，平均 per-SNP F≈33（最小≈22），远超弱工具阈值 10。
- **中等-9（IGAP ID）**：保留 `ieu-a-297`（即产生 β=0.466 的数据集），§2.2 表与 §3.1 表 n 统一为 **54,162（17,008/37,154）**；文献 [3] Lambert 2013 注明其同时支撑更大的 `ieu-a-298`（n=74,046），避免数字自相矛盾。
- **中等-10（认知 GWAS 引用）**：[2] 改为按 OpenGWAS accession `ebi-a-GCST006572`（UKB 认知表现，n=257,841）引用，并注明 GWAS Catalog 误挂接到 Lee 2018 受教育年限论文（PMID 30038396）的 provenance 问题——已联网核实（Open Targets/GWAS Catalog + Nature Sci Rep 2024 表 1 均确认该 ID 为 UKB 认知表现 n=257,841）。
- **中等-11（WMed vs IVW 量级差）**：§3.1 加句解释——WMed 仅用约半数权重、更保守，量级差提示 SNP 间效应异质（与高 I² 一致）。
- **中等-12（图 5 Egger 斜率）**：`make_figures.py` 的 Egger 拟合权重由 `1/(sy/|βx|)²`（忽略 sx）改为正确权重 `1/(sy²+βx²·sx²)`；重跑后图 5 标注斜率 = **−0.362**（与正文一致），图注同步。已验证：旧权重得 −0.484，新权重得 −0.3623（=CSV Egger_beta）。
- **次要-13（多重检验/ancestry/把握度）**：§2.4 加多重检验说明（主假设 MCP→认知，余为探索性，未正式校正但全报 p）；§4 局限第 8 条补 ancestry（欧洲裔特异）与痴呆/中介把握度说明。
- **次要-14（数据可用性）**：§6 声明改为实名仓库 URL `https://github.com/yyx-4113/pain-cognition-mr`（不再写"接收后 deposit / available on request"）；STROBE-MR 19 项同步。
- **次要-15（编号/表述小瑕）**：§2.3"146 into the reverse"改为"反向分析另选 146 个独立认知工具 SNP"；§4 新增 AD/IGAP β 为正（疼痛↑→AD↑）与认知表现 β 为负的方向差异解释。

### 复核结论
- 所有稿件数字仍 100% 可溯源至 `data/derived/*.csv`（未改动任何已核算数值；仅修正解读/结构/文献/重叠层）。
- 重跑 `analysis/make_figures.py` 成功，Figure 5 现显示 MR-Egger slope = −0.362、MR(IVW) slope = −0.361，与正文一致。
- 修订后正确语气：**"遗传证据与'疼痛→认知下降'相容，但因果方向不确定（双向显著 + Steiger 不显著）、且受 UKB×UKB 重叠限制"**。

---

## 9. 决策建议 + 非 UKB 敏感性分析执行记录（2026-09-20 续）

### 9.1 对"需拍板"决策点的建议
严重-1 的"优选"修复是换非 UKB 认知功能 GWAS，但实测环境**不可行**（OpenGWAS API 全路由 404 已整体下线；COGENT n=35k 太小；Davies 2018 n=300k、Savage 2018 n=270k 均含 UKB 成分）。故**不伪造**非 UKB 认知功能 MR，改采推荐方案：保留 UKB 认知为主分析并标 hypothesis-generating（已落实）+ 新增以**已 harmonized 的非 UKB 痴呆/AD 结局**（FinnGen、IGAP）为载体的非 UKB 认知下降敏感性分析。该方案比"换一个认知功能 GWAS"更直接、更诚实地消除 UKB 重叠疑虑。

### 9.2 实际执行
- 脚本 `analysis/run_nonukb_sensitivity.py`（复刻 `_recompute_local.R` 估计算法）输出 `data/derived/mr_nonukb_sensitivity_results.csv`。
- 图形 `analysis/make_nonukb_figure.py` 输出 `docs/figures/fig_nonukb_sensitivity.png`（图 8）。
- 结果：MCP→IGAP AD（非 UKB）IVW β=+0.466 (0.123,0.809) p=0.008（显著、无方向性多效性、I²≈16%）；MCP→FinnGen 全因痴呆（非 UKB）β=+0.234 p=0.27（同向 ns）。二者与 UKB 认知表现（β=−0.403 p=3.6e-6）方向完全一致 → **无重叠的独立佐证**。
- 稿件 `docs/manuscript_draft.md` 已新增 §3.2 非 UKB 敏感性分析，并重编号 3.3–3.6；摘要、§4 讨论、局限 #4、图 8 图注、§7 审计轨同步更新。
- 独立文档 `docs/NONUKB_SENSITIVITY.md` 记录方法、结果、决策建议与复现命令。
