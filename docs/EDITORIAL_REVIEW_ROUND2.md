# 预印版编辑评审（第二轮 / Round 2）

> **评审对象**：`docs/manuscript_draft.md`（版本 B 修订 + 非 UKB 认知下降敏感性分析整合后）
> **评审日期**：2026-09-20
> **评审人**：小团（预印本期刊责任编辑视角）
> **配套文档**：`EDITORIAL_REVIEW.md`（第一轮）、`NONUKB_SENSITIVITY.md`（非 UKB 分析执行记录）、`strobe_mr_checklist.md`（STROBE-MR 合规）

---

## 0. 处置决定（Decision）

**R1 的 4 个严重问题已实质性修复**，稿件科学诚信较首版显著提升，核心计算链路干净、数字 100% 可溯源。但本轮（基于最新版本）发现 **3 个预印前必须修改的主要级问题（A/B/C）** 以及 8 个中/次要问题。

**结论：修完 A、B、C 三项后可预印（medRxiv / Research Square 级别的"预印"）；但作为正式期刊投稿，D–H 亦建议同期修。**

诚实边界保持正确：未编造任何非 UKB 认知功能 MR；所有结论均以"compatible / hypothesis-generating"定调，未断言 unilateral causal arrow。

---

## 1. 第一轮（R1）严重问题修复确认

| R1 编号 | 问题 | 本轮核查结果 |
|---|---|---|
| 严重 1 | 主结局 UKB×UKB 重叠错误处理 | ✅ 已诚实说明（§2.2 provenance note + 局限 #4）；删除了"non-UKB COGENT mitigates"错误陈述 |
| 严重 2 | Steiger 反向解读 | ✅ §3.1 / 局限撰写为"p=0.23 非显著 → 方向未确立"；§2.4 厘清 Egger 截距 ≠ Steiger |
| 严重 3 | "直接效应"错误导出 | ✅ 已删除；改为"零结果不能反推直接效应、机制未知" |
| 严重 4 | NHANES 过度包装 | ✅ 标题/摘要/§3.5 均降级为"contextual/descriptive" |
| 主要 5/6/7 | 框架错配 / MR-PRESSO 未执行 / I² 低估 | ✅ README 对齐；§2.4 补 MR-PRESSO 未执行说明 + LOO 代理；§3.1 补 I²≈83.5% 与 RE-IVW β=−0.403 |
| 中等/次要 | 引用[2]误挂 / 图5 Egger 斜率矛盾 | ✅ §2.2 注明 GWAS Catalog 误挂 Lee 2018；图5 重跑后 Egger 斜率 = −0.362（与正文一致） |

**R1 修复全部到位，无回潮。**

---

## 2. 本轮必须修改（主要级 · 预印前必修）

### A. 【严重】IGAP 数据集身份错配——声称的数据集 ≠ 实际分析数据（违反数字溯源纪律）

**事实链（已核验）：**
- `mr_ad_reverse_results.csv` 第 2 行：`outcome = ad_igap2`，β=0.4658, p=0.00773, n=42。
- `analysis/run_nonukb_sensitivity.py` 注释明确：`mr_harmonized_ad_igap2.csv → ieu-a-298 IGAP AD`；`make_figures.py` 第 88 行 `LABELS[2]` 取 `AR["ad_igap2"]` 标注为 "MCP → Alzheimer's disease (IGAP)"。
- 因此 §3.1 表格"AD — IGAP"（β=0.466, p=0.008）、§3.2（β=0.466）、图4 第 3 项，**实际全部来自 `ieu-a-298`（n=74,046）**。
- 但 §2.2 正文与表格写的是：**"Alzheimer's disease: IGAP 2013 (`ieu-a-297`, n=54,162 [17,008 / 37,154]); ... ieu-a-298 (n=74,046) exists but ieu-a-297 was the dataset analysed here."**

**矛盾**：§2.2 声称分析用 `ieu-a-297`，但全稿 AD-IGAP 数字均来自 `ieu-a-298`。样本量（54,162 vs 74,046）、cases/controls（17,008/37,154 vs 应为 25,580/48,466）全部错标；且文献 [3] Lambert 2013（74,046）恰好与 `ieu-a-298` 匹配、与所写的 297（54,162）不匹配。

**联网核实（OpenGWAS 元数据镜像，2026-09-20）**：
- `ieu-a-298`：IGAP, Lambert 2013, European, log odds, **n=74,046, ncase=25,580, ncontrol=48,466**, nsnp=11,633, PMID 24162737。
- `ieu-a-297`：IGAP, Lambert 2013, European, log odds, n=54,162, ncase=17,008, ncontrol=37,154, nsnp=7,055,882, PMID 24162737。
- （`ieu-a-298` 的 ncase=25,580 = 文献[3]正文 stage1 17,008 + stage2 8,572，完全一致。）

**精确修正（请逐处落实）：**
1. §2.2 正文 IGAP 行改为：
   > "Alzheimer's disease: IGAP 2013 [3] (`ieu-a-298`, n=74,046 [25,580 cases / 48,466 controls])."
   并**删除** "the larger IGAP release ieu-a-298 (n=74,046) exists but ieu-a-297 was the dataset analysed here" 整句。
2. §2.2 表格 IGAP 行：ID=`ieu-a-298`，n=`74,046`，cases/controls=`25,580 / 48,466`。
3. §3.1 表格 "AD — IGAP" 在结局列注明 `ieu-a-298`（与 §2.2 一致）。
4. §3.2 已正确用 `ieu-a-298`，保持不变。
5. 文献 [3] 目前写"Underlies both ieu-a-297, n=54,162, analysed here, and the larger ieu-a-298, n=74,046" —— 改为"Underlies ieu-a-298 (n=74,046), the dataset analysed here"。

> 这是本轮最关键的一项：投稿前若仍写 `ieu-a-297` 而数据是 `ieu-a-298`，属于"数据集声称与实际不符"，会被方法学审稿人直接抓出。

---

### B. 【主要】反向 MR 与正向同样受 UKB 重叠，削弱"双向显著 → 方向不确定"的论证

**事实：**
- 反向 MR（cognition→MCP，§3.3）暴露 = `ebi-a-GCST006572`（UKB-derived, n=257,841），结局 = MCP（Johnston 2019, UKB, n=387,649）。**两端都是 UKB 来源，重叠比正向更重**（正向至少结局是 UKB、暴露也是 UKB，但反向两端同源 UKB）。

**问题：**
- §3.3 以 "Both directions were significant ... shared genetic architecture or reciprocal effects are plausible" 论证"不能断言单向因果"。
- 但两个方向都受**同一 UKB 重叠偏倚**污染，双向显著可能**共同源于重叠偏倚**，不能简单解释为 reciprocal causal effects 或 shared genetic architecture（后者需非重叠数据支持；而 §3.2 的非 UKB 结局是痴呆/AD，并非认知表现的反向关系）。

**修正：**
- §3.3 与局限 #1 补充：反向 MR 同样（且更严重地）受 UKB 样本重叠；因此"双向显著"本身部分可由重叠偏倚解释，**不能独立作为方向不确定或 reciprocal effect 的证据**；反向关系的因果解读须极度谨慎。
- §2.3 反向 instruments（146 个认知 SNPs）注明：同样来自 UKB-derived 认知 GWAS，故反向方向重叠更严重，与 B 呼应。
- 建议措辞：将 "shared genetic architecture or reciprocal effects are plausible" 改为 "shared UKB sample overlap (which affects both directions) and/or genuine pleiotropy may underlie the bidirectional significance; a non-overlapping reverse analysis is still lacking"。

---

### C. 【主要】"非 UKB 敏感性分析"的诚实性表述——实为重叠状态重解读，非独立敏感性分析

**事实：**
- §3.2 的 FinnGen 全因痴呆（β=0.234）与 IGAP AD（β=0.466）**与 §3.1 主表格"All-cause dementia""AD—IGAP"两行数字完全相同**（同一 harmonized 文件、同一 β）。
- §3.2 **未使用不同 instruments、不同 harmonization 或新下载数据**，只是把已呈现的主分析结果**重新标注为"重叠稳健性视角"**。

**问题：**
- 标题与正文称其为 "sensitivity analysis"。严格说这是对既有结果的**重叠分层再解读（overlap-stratified re-interpretation）**，而非独立敏感性分析（后者通常需替换 instruments / 人群 / 方法，如 MRlap、COJO、或不同 GWAS 发布）。编辑/审稿人会质疑"这算敏感性分析吗？是否夸大？"

**修正：**
- §3.2 开头明确："These estimates are identical to those reported in §3.1 (All-cause dementia, AD—IGAP); here they are re-interpreted specifically as an overlap-robustness check, because both outcomes are free of UKB sample overlap with the MCP exposure."
- 小节标题建议改为更诚实的 "Non-UKB overlap robustness check"（或保留 "sensitivity analysis" 但加注 "re-interpretation of §3.1 results"）。
- 图8 caption 已正确说明两面板尺度不同，建议补一句 "estimates identical to those in §3.1"。

> 这一条的意图不是否定该分析的价值——"用非 UKB 痴呆/AD 结局验证方向一致性"本身是有价值的重叠稳健性论证——而是**表述要诚实**，避免被误读为"额外独立验证"。

---

## 3. 中等问题（应改）

### D. 引用 [2] 把 Lee 2018（受教育年限 GWAS）挂在认知表现下不规范
- 现状：[2] 正文为"Cognitive performance ... ebi-a-GCST006572 ... Note: metadata listed under Lee et al. 2018 ... educational-attainment GWAS"。这会在参考文献列出现一个与认知表现无关的受教育年限文献，且把误挂作为 note，反而混淆。
- 修正：[2] 改为**正式数据集引用**——"Cognitive performance (1-standardised score), UK Biobank. OpenGWAS accession ebi-a-GCST006572. https://gwas.mrcieu.ac.uk/datasets/ebi-a-GCST006572/ (accessed 2026-09-20)."；Lee 2018 仅作为正文一句"元数据误挂说明"，**不进入参考文献**（或若必须保留，明确标注"此文献为 GWAS Catalog 误挂，非本性状来源"）。

### E. IVW(−0.361) 与 WMed(−0.233) 差异达 35%，提示潜在水平多效性/异质性
- 事实：IVW 固定 −0.361、Egger −0.362（截距≈0 故接近）、但 WMed 仅 −0.233。三者中 WMed 明显偏小。这种量级差异通常提示部分 SNP 存在 balanced/horizontal pleiotropy，而 Egger 截距不显著（−0.0005, p=0.34）仅排除*方向性*多效性，不排除*非方向性*多效性。
- 修正：§4 讨论或局限 #2 明确讨论"IVW 与 WMed 的 35% 量级差异作为潜在水平多效性信号；本报告以 IVW 为主估计但承认 WMed 更小，需 Radial MR / MR-PRESSO（SAP 承诺但未运行）进一步澄清"，避免读者误以为"三种方法一致"。

### F. MR β 单位未在方法学明确定义
- 现状：Figure 4/5 caption 提"SD units"，但 §2.4 方法学未定义 β 是"per 1-SD genetically predicted MCP increase"还是"per MCP-increasing allele"。
- 修正：§2.4 明确"All MR β are reported as the effect of a 1-SD genetically predicted increase in MCP (binary outcomes as per-log-OR)"，并在摘要/§3.1 首句重申。

### G. STROBE-MR 清单章节号与重编号后稿件不同步 + 残留"direct pathway"
- 现状（`strobe_mr_checklist.md`）：13c 写"§3.2 (reverse MR)"（实际反向在 §3.3）；13b 写"§3.3 (mediation)"（实际中介 §3.4）；10b/13d 写"§3.4 NHANES""§3.5 CHARLS"（实际 NHANES §3.5、CHARLS §3.6）；16a 写"§4 (pain→lower cognition, **direct pathway**)"（稿件已删除直接效应）。
- 修正：把清单所有 §3.x 章节号对齐到重编号后稿件（§3.1 正向；§3.2 非UKB；§3.3 反向；§3.4 中介；§3.5 NHANES；§3.6 CHARLS）；16a 删除"direct pathway"改为"mechanism unknown"。

### H. 辅助文档 NONUKB_SENSITIVITY.md 的 p 值笔误
- 现状：第 54 行 "MCP→认知表现 p=3.6×10⁻⁶"，应为 **3.65×10⁻³⁰**（与 `mr_forward_results_corrected.csv` L2 / 稿件摘要、§3.1 一致）。
- 修正：修正该文档 p 值。虽为辅助文档，但作为审计产物须准确。

---

## 4. 次要问题（建议）

- **I. Steiger 方法学细节缺失**：§2.4 应说明 Steiger 所用 instruments（MCP 的 41 SNPs）与方向设定（exposure explains more variance than outcome, X→Y）。反向方向未做 Steiger，应说明仅正向做。
- **J. 重叠表述过度绝对**：§3.2/局限#4 称非 UKB 结局"structurally absent" UKB overlap。严谨起见改为"no substantial UKB overlap"（联盟/芬兰研究可能含少量欧洲重叠样本）。
- **K. 反向 instruments 重叠注明**：见 B 项，§2.3 注明 146 个认知 SNPs 同样 UKB 来源。
- **L. 多重检验声明**：正向 4 结局 ×3 方法 + 反向 3 + 中介 3 路径，检验总数大。§2.4 建议明确"仅 primary (MCP→cognition IVW) 用于结论性解读，其余为探索性"。
- **M. 高异质性效应修饰**：I²=83.5% 下建议讨论效应修饰（哪些 SNP 驱动、功能/通路分层），作为未来方向。
- **N. E-value**：STROBE 12b 列标题含 "E-value" 但稿件未计算。建议要么补算 E-value（针对未测量混杂），要么从清单列标题去掉 "E-value"。
- **O. 图4 caption "five MR directions"**：已核对 `make_figures.py` LABELS 确含 5 个方向（含反向，L90），与代码一致——**无需修改**（特此注明，避免误改）。

---

## 5. 数字溯源核验表（稿件 ↔ CSV，本轮逐项核对）

| 稿件数字 | 来源 CSV | 一致 |
|---|---|---|
| 认知 IVW −0.361, p=3.65e-30, Q=242.5, I²=83.5% | `mr_forward_results_corrected.csv` L2 | ✅ |
| 认知 Egger −0.362, int p=0.34 | 同上 L2 | ✅ |
| 认知 WMed −0.233 | 同上 L2 | ✅ |
| 认知 LOO [−0.386,−0.315] | 同上 L2 | ✅ |
| 全因痴呆 IVW 0.234, p=0.27, I²≈0% | 同上 L3 | ✅ |
| AD IGAP 0.466, p=0.008, I²≈16% | `mr_ad_reverse_results.csv` L2 (`ad_igap2`=**ieu-a-298**) | ✅(数字) ⚠️(§2.2 标错 ID) |
| AD Ben Nevis 0.168, p=0.29 | `mr_ad_reverse_results.csv` L3 | ✅ |
| 反向 −0.171, p=8.85e-58 | `mr_ad_reverse_results.csv` L4 | ✅ |
| 非 UKB 敏感性三项 | `mr_nonukb_sensitivity_results.csv` | ✅ |
| F mean≈33, min≈22 | 上述 CSV F 列 | ✅ |
| 中介：抑郁 0.620/<1e-14/−0.078/0.11/−0.048 | `mr_mediation_results.csv` L2 | ✅ |
| 中介：CRP 0.180/5.6e-4/0.001/0.95/0.0002 | 同上 L3 | ✅ |
| 中介：失眠 0.265/<1e-16/−0.019/0.86/−0.005 | 同上 L4 | ✅ |

**结论**：所有核算值准确无误、可溯源；本轮问题集中在 **数据集身份标注（A）、重叠逻辑（B）、表述诚实性（C）与文献/清单同步（D–H）**，均不涉及数值造假。

---

## 6. 修订路线图（优先级）

| 优先级 | 项 | 动作 |
|---|---|---|
| **P0（预印前必修）** | A | §2.2 全处 `ieu-a-297`→`ieu-a-298`（n=74,046, 25,580/48,466），删"297 was analysed"句；§3.1/文献[3] 同步 |
| P0 | B | §3.3 + 局限#1 补"反向 MR 同样受 UKB 重叠，双向显著不能独立证方向不确定" |
| P0 | C | §3.2 开头声明"与 §3.1 数字相同，此处为重叠稳健性重解读"；标题可改 overlap robustness check |
| P1 | D | [2] 改为数据集引用，Lee 2018 移出参考文献或显式标注误挂 |
| P1 | E | §4/局限#2 讨论 IVW–WMed 35% 差异作为潜在水平多效性 |
| P1 | F | §2.4 定义 β 单位（per 1-SD genetically predicted MCP） |
| P1 | G | `strobe_mr_checklist.md` 章节号对齐 + 删"direct pathway" |
| P2 | H | NONUKB 文档 p 值 3.6e-6 → 3.65e-30 |
| P2 | I–N | Steiger 细节 / 重叠措辞 / 多重检验声明 / 效应修饰 / E-value |

---

## 7. 总体判断

稿件在经过 R1 修改后已是一篇**方法透明、数字可溯源、表述诚实**的 MR 预印本雏形。本轮指出的 A/B/C 三项均为"预印前必须修"——其中 **A 是硬伤（数据集声称与实际不符），B 是逻辑漏洞（重叠削弱双向论证），C 是表述诚实性（避免夸大敏感性分析）**。修完这三项后，稿件即可作为预印本发布；D–H 建议在正式投稿前同期处理。

**正确语气保持不变**：遗传证据与"疼痛→认知下降"相容，但因果方向不确定（双向显著 + Steiger 不显著）、且受 UKB×UKB 重叠限制；非 UKB 痴呆/AD 结局提供方向一致的独立佐证，但测的是痴呆/AD *风险* 而非认知表现 *评分* 本身。等 CHARLS 纵向（版本 B→A）与 MRlap 重叠校正补做后，结论可进一步夯实。

---

## 10. P0（A/B/C）已落地（2026-09-20 续）

按用户指令仅落地 P0 三项（D–H 属 P1/P2，未动，待后续轮次）。

### A【严重·IGAP 数据集身份错配】—— 已全部修正
- 摘要：`ieu-a-297`(54,162) → `ieu-a-298`(74,046)。
- §2.2 正文：改为“`ieu-a-298`, n=74,046 [25,580 cases / 48,466 controls]”，并**删除**“larger release ieu-a-298 exists but ieu-a-297 was analysed here”整句。
- §2.2 表格：ID=`ieu-a-298`，n=74,046，cases/controls=25,580/48,466。
- §3.1 表格：结局列改“AD — IGAP (ieu-a-298)”。
- 文献 [3]：改“Underlies ieu-a-298, n=74,046, the dataset analysed here.”
- 核对：全稿 `ieu-a-297` 已零残留；数字（β=0.466, p=0.008）与 `mr_ad_reverse_results.csv` 的 `ad_igap2` 一致，未改动任何核算值。

### B【主要·反向 MR 重叠逻辑】—— 已全部修正
- §2.3：146 个反向认知 instruments 注明“同样 UKB-derived，反向方向重叠至少与正向同样重”。
- §3.3：改写“双向显著不能独立证方向不确定/reciprocal effects；可能共同源于 UKB 重叠；仍缺非重叠反向分析”。
- 局限 #1：扩展为“反向两端均 UKB 来源，受同样（更重）重叠偏倚；双向显著不能独立确立方向/reciprocal/shared architecture”。

### C【主要·表述诚实性】—— 已全部修正
- §3.2 标题改为“Non-UKB overlap-robustness check (re-interpretation of §3.1 forward estimates)”。
- 开头明确：估计值与 §3.1 完全相同（同 harmonized 文件），仅换重叠框架，“no new instruments/harmonization/data”。
- 结尾“independent, overlap-free dataset”→“overlap-free dataset (the same §3.1 FinnGen/IGAP estimates, here re-framed)”。
- 讨论/结论/局限 #4/图8 caption/摘要 同步将“sensitivity analysis”改为“overlap-robustness re-interpretation / re-analysis”，并标注“same estimates as §3.1”。
- “structurally absent”→“largely absent”（顺带收敛 J 项绝对化措辞）。

**遗留（非本次范围）**：D–H（引用[2]改数据集引用、IVW–WMed 35% 差异讨论、β 单位定义、STROBE 清单章节号同步、NONUKB 文档 p 值笔误等 P1/P2）按用户“仅 A/B/C”指令未处理，列为正式投稿前待办。

---

## 11. D–H 收尾（P1/P2）已落地（2026-09-20 续）

按用户指令将 R2 评审 D–H（P1/P2）一并落地。

### D【P1·引用[2]误挂】—— 已修正
- 文献 [2] 重写为正式数据集引用；Provenance note 明确：OpenGWAS/GWAS Catalog 元数据**误挂**到 Lee 2018（受教育年限 GWAS, PMID 30038396），**该文献非本性状来源**；所用汇总统计为 UKB 衍生认知表现评分，仅按 trait+accession 引用。Lee 2018 不再进入参考文献列表，仅作为误挂说明出现在 [2] 注释内。

### E【P1·IVW–WMed 35% 差异】—— 已修正
- 局限 #2 重写：新增“加权中位数(−0.233)较 IVW(−0.361)小≈35%，提示**水平(非方向性)多效性**；Egger 截距不显著仅排除*方向性*多效性，不排除平衡性效应；SAP 承诺的 MR-PRESSO/离群重估因 TwoSampleMR 不可用未运行，建议 Radial MR 未来补做”。
- §4 讨论首段补一句同样信号（“≈35% gap ... horizontal pleiotropy ... Egger intercept does not rule out”）。

### F【P1·β 单位未定义】—— 已修正
- §2.4 新增“Effect-size units”句：连续认知结局 β = 每 **1-SD 遗传预测 MCP 增加**的效应；二分类结局(AD/全因痴呆)为 log-odds 尺度/每 1-SD MCP。
- §3.1 首句重申报：“All estimates below express the effect of a 1-SD genetically predicted increase in MCP ...”。

### G【P1·STROBE 清单章节号同步 + direct pathway】—— 已修正
- `strobe_mr_checklist.md`：10b §3.4→§3.5；13b §3.3→§3.4；13c §3.2→§3.3；13d §3.4/§3.5→§3.5/§3.6；7 项 §3.1–3.2→§3.1(+§3.2 overlap-robustness)；16a “pain→lower cognition, **direct pathway**”→“mechanism unknown, no direct-effect claim”；摘要段 §2.7/§3.5→§2.7/§3.6。

### H【P2·NONUKB 文档 p 值笔误】—— 已修正
- `NONUKB_SENSITIVITY.md` §3.2 表：MCP→认知表现行 p=3.6×10⁻⁶ → **3.65×10⁻³⁰**；并改用稿件头条固定效应 IVW(−0.361, 95% CI −0.424,−0.299) 对齐，脚注标注随机效应 IVW=−0.403 及原误写已更正。

**结论**：R2 评审 A–H 全部落地（A/B/C 见 §10），稿件现已可预印且达正式投稿前的文献/清单同步标准。

**已知残留（非本次 D–H 范围，供用户知悉）**：`RESULTS.md`、`LOCAL_RUNBOOK.md`、`gwas_catalog.md` 及 `analysis/_build_master.R`、`_mr_ad_reverse.R`、`data/derived/mr_master_results.csv` 等辅助文件/脚本仍标注 IGAP 为 `ieu-a-297`（实际数据为 `ieu-a-298`）。这些不在稿件交付物内；如需审计链完全一致，建议另开一轮对齐（属辅助文档清理，不在 D–H）。
