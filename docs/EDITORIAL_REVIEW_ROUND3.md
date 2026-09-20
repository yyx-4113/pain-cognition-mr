# 预印版编辑评审（第三轮 / Round 3）

> **评审对象**：`docs/manuscript_draft.md`（版本 B 修订 + 非 UKB 敏感性分析整合 + R2 评审 A–H 全部落地后）
> **评审日期**：2026-09-20
> **评审人**：小团（预印本期刊责任编辑视角）
> **配套文档**：`EDITORIAL_REVIEW.md`（第一轮）、`EDITORIAL_REVIEW_ROUND2.md`（第二轮）、`NONUKB_SENSITIVITY.md`、`strobe_mr_checklist.md`

---

## 0. 处置决定（Decision）

**好消息先说**：稿件的核心科学框架经本轮外部核验是**站得住的**——`ebi-a-GCST006572` 确为 UKB 衍生认知表现 GWAS（n=257,841），稿件"UKB 暴露 × UKB 结局"重叠前提成立；R1/R2 对严重问题（重叠诚实说明、Steiger、直接效应、NHANES 降级、I²/F、Egger 斜率、引用[2]、β 单位、STROBE 清单同步、p 值笔误）的修复也都在位、无回潮。

**但本轮发现一个必须立即修的 P0 级问题**：**R2 评审的"严重项 A"本身是一次错误修正**。R2 把 AD–IGAP 数据集从 `ieu-a-297` 改成了 `ieu-a-298`，理由是"联网核实 ieu-a-298 = IGAP, n=74,046 与文献[3]吻合"。但**实际分析的 harmonized 数据来自 `ieu-a-297`（n=54,162）**——生成该数据的脚本 `_mr_ad_reverse.R` 第 59 行清清楚楚写的是 `id="ieu-a-297"`，且 `mr_master_results.csv`、`_build_master.R`、原始 R1 评审（中等-9）一致指向 `ieu-a-297`。R2 仅凭元数据推断、未查生成脚本，把稿件改成了与真实数据**不符**的 `ieu-a-298`。这是数据溯源错误，必须回退。

此外 `RESULTS.md` / `gwas_catalog.md` 把认知 GWAS `ebi-a-GCST006572` 标为 **"COGENT, non-UKB"**——既与稿件前提直接冲突、又事实错误（COGENT 是 Trampush 2017、n≈35k；该 ID 实为 UKB 认知、n=257,841）。这是辅助文档里的**危险矛盾**，会与稿件重叠论证自相矛盾，必须改。

**结论**：修完本轮回退项 A'（297↔298）+ COGENT 误标（P0）后，稿件即达预印标准；其余为辅助文档一致性与表述收尾（P1/P2）。

---

## 1. 承重前提外部核验（好消息，已确认）

| 核验项 | 结论 | 来源 |
|---|---|---|
| `ebi-a-GCST006572` 是否为 UKB 衍生认知表现 GWAS | **是**，n=257,841，European | Nature Scientific Reports 2024 Table 1："Cognitive performance UKB 257,841 ... ebi-a-GCST006572"；Open Targets Platform GCST006572："Reported trait: Cognitive performance" |
| GWAS Catalog 为何把它挂到 Lee 2018（受教育年限） | 策展瑕疵：该 accession 在 GWAS Catalog 被关联到 Lee JJ 2018（Nat Genet, PMID 30038396，SSGAC 受教育年限 GWAS）的发表记录，但**性状本身是被用作认知表现** | Open Targets Platform 显示 "Publication: Lee JJ et al. 2018" 但 "Reported trait: Cognitive performance" |
| 稿件重叠前提（UKB 暴露 × UKB 结局）是否成立 | **成立** | 暴露 Johnston 2019 UKB n≈387,649；结局 ebi-a-GCST006572 UKB n=257,841，两端同源 UKB |

→ 稿件 §2.2 provenance note 与局限 #4 的重叠论证**正确**，无需改动。R2 评审"COGENT 误标"之外的所有科学判断保持有效。

---

## 2. P0 — R2 项 A 必须回退：AD–IGAP 实为 ieu-a-297（非 ieu-a-298）

### 2.1 证据链（已确凿）
- `analysis/_mr_ad_reverse.R` **第 59 行**：`ad_igap2 = list(id="ieu-a-297", label="AD (IGAP ieu-a-297)")`，并据此 `get_assoc(cl$rsid, "ieu-a-297")` 下载 → 写出 `mr_harmonized_ad_igap2.csv` → 算出 `mr_ad_reverse_results.csv` 第 2 行（`ad_igap2`, β=0.4658, p=0.00773）。
- `data/derived/mr_master_results.csv` **第 4 行**：`MCP -> AD (IGAP ieu-a-297),42,0.4658,...` —— 结果标签即 ieu-a-297。
- `analysis/_build_master.R` **第 13 行**：`if (o == "ad_igap2") return("MCP -> AD (IGAP ieu-a-297)")`。
- `mr_gwas_metadata_20260920.csv` **第 14 行**：`ieu-a-297,...,Lambert,2013,IGAP,24162737,54162,17008,37154,...`（n=54,162, 17,008/37,154）。
- 原始 R1 评审（中等-9）早已正确指出："保留 ieu-a-297（**即产生 β=0.466 的数据集**），§2.2 表与 §3.1 表 n 统一为 54,162（17,008/37,154）"。R2 改 298 反而背离了真实数据。

**结论**：AD–IGAP 的真实分析数据是 **ieu-a-297（n=54,162, 17,008/37,154）**。稿件当前所有 `ieu-a-298` 标注都是 R2 引入的错误。

### 2.2 R2 为何判错
R2 评审逻辑："ieu-a-298 元数据 = IGAP, n=74,046，与文献[3] Lambert 2013 正文 74,046 吻合 → 数据必为 ieu-a-298"。问题：文献[3] 是 IGAP 联盟的**母论文**，同时支撑 ieu-a-297（发布版 n=54,162）与 ieu-a-298（含 stage2 的更大 meta n=74,046）；R2 未查生成脚本，把"母论文样本量"等同于"实际下载的数据集"，导致误判。**β=0.466/p=0.008 本身没错（数据未变），错的是数据集 ID 与 n/cases。**

### 2.3 精确回退清单（请逐处把 ieu-a-298 → ieu-a-297，n 改为 54,162 / 17,008 / 37,154）

| # | 文件 | 位置 | 当前（错误） | 应改为（正确，匹配真实数据） |
|---|---|---|---|---|
| 1 | manuscript_draft.md | 摘要 L21 | `IGAP, ieu-a-298, n=74,046` | `IGAP, ieu-a-297, n=54,162` |
| 2 | manuscript_draft.md | §2.2 正文 L46 | `IGAP 2013 [3] (ieu-a-298, n=74,046 [25,580 cases / 48,466 controls])` | `IGAP 2013 [3] (ieu-a-297, n=54,162 [17,008 cases / 37,154 controls])` |
| 3 | manuscript_draft.md | §2.2 表格 L56 | `ieu-a-298 \| 74,046 \| 25,580 / 48,466` | `ieu-a-297 \| 54,162 \| 17,008 / 37,154` |
| 4 | manuscript_draft.md | §3.1 表格 L101 | `AD — IGAP (ieu-a-298)` | `AD — IGAP (ieu-a-297)`（β/CI/p 不变：0.466 (0.123,0.809), p=0.008） |
| 5 | manuscript_draft.md | §3.2 正文 L108 | `...IGAP 2013 consortium [3]; ieu-a-298, n=74,046...` | `...IGAP 2013 consortium [3]; ieu-a-297, n=54,162...` |
| 6 | manuscript_draft.md | §3.2 表格 L113 | `AD (IGAP ieu-a-298; non-UKB)` | `AD (IGAP ieu-a-297; non-UKB)` |
| 7 | manuscript_draft.md | 图 8 caption L190 | `IGAP Alzheimer's disease (ieu-a-298, international consortium)` | `IGAP Alzheimer's disease (ieu-a-297, international consortium)` |
| 8 | manuscript_draft.md | 文献 [3] L198 | `(Underlies ieu-a-298, n=74,046, the dataset analysed here.)` | `(Underlies ieu-a-297, n=54,162, the dataset analysed here; the larger ieu-a-298 release, n=74,046, is also from this consortium and may be used for replication.)` |
| 9 | NONUKB_SENSITIVITY.md | L30, L56 | `IGAP ieu-a-298` | `IGAP ieu-a-297` |
| 10 | analysis/run_nonukb_sensitivity.py | 注释 | `mr_harmonized_ad_igap2.csv → ieu-a-298 IGAP AD` | `→ ieu-a-297 IGAP AD` |

> **β / 95% CI / p 一律保持不变**（0.466, 0.123–0.809, 0.008）——这些来自真实数据，未受影响。仅 ID 与样本量回到与数据一致的状态。

### 2.4 回退后的连带收益
回退到 ieu-a-297 后，**稿件与全部辅助文件（RESULTS.md、gwas_catalog.md、mr_master_results.csv、_build_master.R、_mr_ad_reverse.R）的 297 标注自动一致**，R2 引入的"稿件 vs 审计轨"矛盾一笔勾销。

### 2.5 （可选，非必须）升级到 ieu-a-298
若希望用更大的 IGAP 发布版（n=74,046），需**重新运行** MR：`_mr_ad_reverse.R` 第 59 行改为 `id="ieu-a-298"` 并重跑，得到新的 harmonized 文件与 β/CI。这需要 R + OpenGWAS 访问（JWT，v4 API `api.opengwas.io`）+ 重算。属"增强"而非"纠错"，当前环境下优先级低于回退。

---

## 3. P0 — 辅助文档把认知 GWAS 误标为 "COGENT, non-UKB"（危险矛盾）

### 3.1 事实
- `docs/RESULTS.md` **L18**："Cognitive outcome = `ebi-a-GCST006572` (**COGENT, n≈257,841, non-UKB**)"。
- `docs/gwas_catalog.md` **L68 / L70 / L82 / L87**：多处称 `ebi-a-GCST006572` 为 "COGENT" 或 "COGENT + UKB meta"。

这两处有两个错误：(a) **COGENT** 是 Trampush 2017（Mol Psychiatry, n≈35,298，多队列、无 UKB），与 n=257,841 的 UKB 认知 GWAS 不是同一事物；(b) 称其 **non-UKB** 与稿件"UKB-derived、存在重叠"前提直接冲突——读者若信了 RESULTS.md，会误以为稿件的重叠论证建立在错误前提上。

### 3.2 修正
- `RESULTS.md` L18 改为："Cognitive outcome = `ebi-a-GCST006572` (**UK Biobank–derived cognitive performance, n=257,841, European**)；其与 MCP 暴露（同为 UKB）存在样本重叠，故主 MR 结局标为 hypothesis-generating。"
- `gwas_catalog.md` L68/L70 删去 "COGENT" 字样，改为 "UK Biobank–derived cognitive performance (n=257,841)；GWAS Catalog 将其发表记录误挂到 Lee 2018 受教育年限 GWAS，性状本身为认知表现"。L82/L87 同理去掉 "COGENT" 表述。
- 注意：稿件（manuscript_draft.md）此处**本就正确**（写 UK Biobank–derived），无需动稿件，只清辅助文档。

---

## 4. P1 — RESULTS.md 陈旧残留（与稿件自相矛盾）

`RESULTS.md` 在 R1/R2 修订时**未同步更新**，遗留三处与稿件冲突：

1. **"直接效应"残留**（L55）："No tested mediator was significant ⇒ the MCP→cognition association operates as a **direct effect**" —— 这正是 R1 严重-3 从稿件**删除**的错误结论。必须删除/改写。
2. **反向 MR 解读陈旧**（L41、L92）："Both directions significant ⇒ directional causality is uncertain; consistent with shared genetic architecture / pleiotropy" —— 稿件 §3.3 现已改为"双向显著可能共同源于 UKB 重叠，不能独立证方向/reciprocal"。RESULTS.md 须对齐。
3. **297/298**（L18/28/29）：回退到 ieu-a-297 后，RESULTS.md 的 297 标注反而**变正确**；但 L28/L29 的 AD–IGAP 行需确认 n 为 54,162/17,008/37,154（目前写 0.466/0.008 正确，n 若写 74,046 需改 54,162）。

---

## 5. P2 — 表述 / 清单收尾

- **I. §3.2 重复呈现 §3.1 数据**：§3.1（主表）+ §3.2（重叠稳健性）+ 图 4 + 图 8 四次出现同一 IGAP/FinnGen 估计。虽已诚实标注"与 §3.1 相同"，但作为"敏感性分析"呈现仍会放大证据观感。建议：(a) 将 §3.2 降为 §3.1 下的一个子段落（"Non-UKB overlap framing of the same estimates"），或 (b) 在 §3.2 开头加一句"本小节不含新估计，仅为同一结果的重叠框架重述，不增加独立证据"。
- **J. Steiger 仅正向**（R2 项 I）：§2.4 应说明 Steiger 只对正向（MCP→认知）做过，反向未做，避免读者假定双向都做过方向性检验。
- **K. E-value**（R2 项 N）：`strobe_mr_checklist.md` 列标题含 "E-value" 但稿件未算。要么补算针对未测量混杂的 E-value，要么从清单列标题去掉 "E-value"。
- **L. 重叠"largely absent"**：R2 已把 "structurally absent"→"largely absent"，措辞恰当，维持。
- **M. 多重检验 / 把握度**：§2.4 已声明仅 primary (MCP→cognition IVW) 用于结论性解读、余为探索性；一致，维持。

---

## 6. 数字溯源核验表（回退 ieu-a-297 后）

| 稿件数字 | 来源 CSV | 一致 |
|---|---|---|
| 认知 IVW −0.361, p=3.65e-30, Q=242.5, I²=83.5% | `mr_forward_results_corrected.csv` L2 | ✅ |
| 认知 Egger −0.362, int p=0.34 | 同上 | ✅ |
| 认知 WMed −0.233 | 同上 | ✅ |
| 全因痴呆 IVW 0.234, p=0.27, I²≈0% | 同上 L3 | ✅ |
| **AD IGAP 0.466, p=0.008, I²≈16%** | `mr_ad_reverse_results.csv` L2（`ad_igap2`，**真实来自 ieu-a-297**） | ✅(数字) ⚠️(**ID 须回退为 ieu-a-297，R2 误标 298**) |
| AD Ben Nevis 0.168, p=0.29 | 同上 L3 | ✅ |
| 反向 −0.171, p=8.85e-58 | 同上 L4 | ✅ |
| 非 UKB 敏感性三项 | `mr_nonukb_sensitivity_results.csv` | ✅（ID 随回退改为 297） |
| F mean≈33, min≈22 | 上述 CSV F 列 | ✅ |
| 中介三项 | `mr_mediation_results.csv` | ✅ |

**结论**：所有核算值准确无误、可溯源；本轮回退项 A'（297↔298）+ COGENT 误标均**不涉及数值造假**，纯属数据集 ID / 来源标注 / 辅助文档同步问题。

---

## 7. 修订路线图（优先级）

| 优先级 | 项 | 动作 |
|---|---|---|
| **P0（必须，预印前）** | A' | 稿件 10 处 + NONUKB 文档 + run_nonukb_sensitivity.py 注释：`ieu-a-298`→`ieu-a-297`，n 改 54,162 / 17,008 / 37,154（β/CI/p 不变） |
| **P0（必须，预印前）** | B' | RESULTS.md L18、gwas_catalog.md L68/70/82/87：删 "COGENT / non-UKB"，改 "UK Biobank–derived cognitive performance (n=257,841)" |
| P1 | C' | RESULTS.md L55 删 "direct effect"；L41/L92 反向 MR 解读对齐稿件重叠框架 |
| P2 | I | §2.4 注明 Steiger 仅正向 |
| P2 | J | §3.2 降为子段或加"非独立证据"声明 |
| P2 | K | E-value：补算或从 STROBE 清单列标题移除 |

---

## 8. 总体判断

稿件经过 R1、R2 后科学诚信与表述已显著提升；本轮**不需要推翻既有结论**，只需修正两处"数据集/来源标注"错误（均是 R2 与早期辅助文档留下的）：(1) AD–IGAP 真实为 ieu-a-297，回退即可同时消除"稿件 vs 审计轨"的所有 297/298 矛盾；(2) 认知 GWAS 的 "COGENT, non-UKB" 误标只存在于辅助文档，清掉即与稿件一致。修完 P0 两项，稿件即可作为预印本发布；P1/P2 可在正式投稿前同期收尾。

**正确语气维持不变**：遗传证据与"疼痛→认知下降"相容，但因果方向不确定（双向显著 + Steiger 不显著）、且受 UKB×UKB 重叠限制；非 UKB 痴呆/AD 结局提供方向一致的佐证，但测的是痴呆/AD *风险* 而非认知表现 *评分* 本身。

---

## 12. P0-1 + P0-2 + P1/P2 落地执行记录（2026-09-20 续）

按用户指令完成第三轮评审全部条目。

### P0-1：回退 R2 错误修正（ieu-a-298 → ieu-a-297）
证据：生成 `mr_harmonized_ad_igap2.csv` 的 `_mr_ad_reverse.R` L59 用 `id="ieu-a-297"`；`mr_master_results.csv` L4 标 `IGAP ieu-a-297`；`run_nonukb_sensitivity.py` 注释原写 ieu-a-298（R2 引入）。R2 仅凭文献[3]母论文 74,046 推断成 ieu-a-298，未查生成脚本，系错误修正。
- 稿件 `manuscript_draft.md` 10 处全部回退：摘要、§2.2 正文与表格、§3.1 表、§3.1.1（原§3.2）正文与表、图8 caption、文献[3] underlies 注。n 改为 **54,162 / 17,008 / 37,154**。
- β=0.466、95% CI (0.123,0.809)、p=0.008 **一律不变**（数据未改）。
- `NONUKB_SENSITIVITY.md` L30/L56、脚本注释与 label、辅助计划 `00_sap.md` L62 同步回退到 ieu-a-297。
- **验证**：重跑 `run_nonukb_sensitivity.py` 成功（exit 0）；IGAP AD I²≈15.9%、LOO [0.393,0.517]、F 均≈33（min 22.4），与稿件一致。
- 稿件与全部辅助文件/脚本现均一致标 ieu-a-297；文献[3]正文 "Meta-analysis of 74,046 individuals" 保留（Lambert 2013 母论文报告 N，正确）。

### P0-2：清除 COGENT / non-UKB 误标
- `RESULTS.md` L18：认知结局由 "(COGENT, n≈257,841, non-UKB)" 改为 "(UK Biobank–derived cognitive performance, n≈257,841; overlap-limited)"。
- `gwas_catalog.md` L68/L70/L87：删除 "COGENT / non-UKB" 表述，改 UK Biobank 衍生认知表现 + provenance 误挂说明；新增脚注 ¹²；L90 注明本分析实际用 ieu-a-297。（L84 仍列表 ieu-a-298 作为已核验 IGAP ID 之一，二者均为真实 ID，无矛盾。）

### P1：RESULTS.md 陈旧表述对齐重叠框架
- L41 反向 MR read：删 "shared genetic architecture"，改"双向显著可能部分源于共同 UKB 重叠"。
- L55 中介 read：删"operates as a direct effect"，改"零结果不能反推直接效应"。
- L92/L94/L95 综合：方向不确定措辞改重叠框架；NHANES 明确"无疼痛变量、仅描述性"。

### P2：结构 + 方法学收尾
- §3.2 降级为 **§3.1.1 Non-UKB overlap-robustness re-interpretation**（因其与 §3.1 数据完全相同，非独立证据）；后续顺延 §3.3→§3.2、§3.4→§3.3、§3.5→§3.4、§3.6→§3.5。
- 稿件与 `strobe_mr_checklist.md` 全部章节交叉引用同步更新（10b→§3.4、13b→§3.3、13c→§3.2、13d→§3.4/§3.5、7项→§3.1.1 等）。
- Steiger "仅正向（MCP→认知）"注明：§2.4 方法描述 + 局限#4 各加一句。
- E-value：清单 12b 列标题由 "I²/Q/E-value" 改为 "I²/Q"，并注"E-value not computed"，与稿件未算 E-value 一致。

**结论**：R1–R3 全部条目现已落地，稿件达预印 + 正式投稿前文献/清单同步标准；所有核算值未改动，100% 可溯源 CSV。
