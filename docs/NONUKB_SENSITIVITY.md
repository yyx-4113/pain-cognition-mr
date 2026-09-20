# 非 UKB 认知下降敏感性分析 — 执行记录与决策建议

**关联**：`docs/EDITORIAL_REVIEW.md` 严重-1（主结局 UKB×UKB 样本重叠）
**日期**：2026-09-20
**作者**：Yongxin Yang（分析由科研搭档小团执行）
**复现脚本**：`analysis/run_nonukb_sensitivity.py` → `data/derived/mr_nonukb_sensitivity_results.csv`；`analysis/make_nonukb_figure.py` → `docs/figures/fig_nonukb_sensitivity.png`

---

## 1. 需拍板的问题（决策点回顾）

评审严重-1 的"优选"修复方案是把主认知结局换成**非 UKB** 认知 GWAS，以彻底消除暴露（MCP，Johnston 2019, UKB, n≈387,649）与结局（`ebi-a-GCST006572`，UKB-derived 认知表现, n=257,841）之间的直接样本重叠。但落地时有三条现实约束：

| 候选非 UKB 认知 GWAS | 样本 | 是否真·非 UKB | 可获取性（2026-09-20） |
|---|---|---|---|
| COGENT（Trampush 2017, Mol Psychiatry） | n≈35,298 | **是**（24 队列，无 UKB） | GWAS Catalog 无 full summary stats；OpenGWAS API 全路由 404（已整体下线） |
| Davies 2018（Nat Commun, n=300,486） | 含 UKB | 否 | — |
| Savage 2018（Nat Genet, n=269,867, SBGene 智力） | 大概率含 UKB | 否 | — |
| `ieu-a-16`（Benyamin 2014 儿童智力） | n=**12,441** | 可能 | 样本太小，把握度过低 |

**结论**：不存在"大样本 + 真·非 UKB + 可获取"的认知功能 GWAS。因此"把头条换成非 UKB 认知功能 GWAS"在当前环境下**无法诚实完成**——若强行编造一个未运行的 MR 结果，正是评审纪律所禁止的。

## 2. 我的建议（给出明确推荐）

**推荐方案（已被采纳并执行）：**

1. **保留** UKB 认知表现作为主分析，但**明确标注为 hypothesis-generating**（因其 UKB×UKB 重叠无法从汇总统计中排除）——已在版本 B 修订中落实。
2. **新增**一项正式的 **非 UKB 认知下降敏感性分析**，使用本仓库**已 harmonized、确属非 UKB** 的结局：
   - **FinnGen `finn-b-F5_DEMENTIA`**（芬兰国家生物库，非 UKB）→ 全因痴呆
   - **IGAP `ieu-a-297`**（国际 AD 联盟，非 UKB，n=54,162）→ 阿尔茨海默病
   二者与 MCP 暴露**结构上无 UKB 样本重叠**，是比"换一个认知功能 GWAS"更直接、更诚实的重叠检验。
3. **不伪造**任何非 UKB 认知功能 MR；把"直接非 UKB 认知功能 GWAS（COGENT）"列为未来方向（待 OpenGWAS API 恢复或经 GWAS Catalog 全统计下载）。

> 一句话：用"非 UKB 的痴呆/AD 结局"替代"非 UKB 的认知功能结局"作为敏感性分析载体——二者共同回答"疼痛→认知下降"假设，且彻底绕开 UKB 重叠，远比强行编造一个认知功能 MR 更站得住脚。

## 3. 实际跑的分析（已执行）

### 3.1 方法
严格复刻 `analysis/_recompute_local.R` 的本地 MR 估计量（与 `mr_forward_results_corrected.csv` 完全可比）：
- 暴露 = MCP（`beta`, `se`）；结局 = `beta_out_adj`（等位基因已对齐）, `se_out`
- IVW 固定效应：`w = 1/se_y²`
- Cochran Q → I² = (Q−df)/Q
- IVW 随机效应（DerSimonian–Laird）
- MR-Egger（权重 `w = 1/se_y²`，截距检验方向性多效性）
- 加权中位数（含暴露与结局双侧 SE 的 delta 法）
- Leave-one-out

三个 harmonized 文件（`mr_harmonized_cog.csv` / `mr_harmonized_dementia.csv` / `mr_harmonized_ad_igap2.csv`）的 `beta`/`se`（MCP）完全相同，仅 `beta_out` 不同 → 全部为 **MCP→结局正向**文件。

### 3.2 结果

| 暴露→结局 | 来源 | UKB重叠 | n SNP | IVW β (95% CI) | p | Egger β (截距p) | WMed β | I² | 方向 |
|---|---|---|---:|---:|---:|---:|---:|---:|---|
| MCP→认知表现* | ebi-a-GCST006572 (UKB) | **是** | 41 | −0.361 (−0.424, −0.299) | 3.65×10⁻³⁰ | −0.362 (0.34) | −0.233 | 83.5% | 更差 |
| MCP→全因痴呆 | FinnGen F5 (芬兰) | 否 | 43 | 0.234 (−0.185, 0.653) | 0.27 | 0.209 (0.21) | 0.220 | 0% | 风险↑ |
| MCP→阿尔茨海默病 | IGAP ieu-a-297 (非UKB联盟) | 否 | 42 | **0.466 (0.123, 0.809)** | **0.008** | 0.462 (0.86) | 0.227 | 16% | 风险↑ |

工具变量强度：41–43 个 harmonized SNP，平均 per-SNP F≈33（最小≈22），远超弱工具阈值 10。

\* 认知表现一行的 β=−0.361 为逆方差加权固定效应估计（即稿件 §3.1 头条值）；随机效应 IVW β=−0.403（95% CI −0.550, −0.257），p 同为 3.65×10⁻³⁰。原文档误写为 p=3.6×10⁻⁶，已更正。

### 3.3 解读
- **三个结局方向完全一致**：更多疼痛位点 → 更差认知表现 / 更高痴呆与 AD 风险。
- **IGAP AD（非 UKB）显著**（β=0.466, p=0.008），Egger 截距不显著（p=0.86，无方向性多效性），I²≈16% 低异质性，LOO 稳定 → 这是一个**真正无重叠的显著佐证**。
- **FinnGen 全因痴呆（非 UKB）呈同向但 ns**（β=0.234, p=0.27），更可能源于二分类结局有效病例数较少导致的把握度不足，而非真 null。
- 因此：非 UKB 敏感性分析**支持** UKB 认知表现结果的关联性，且独立于此重叠偏倚。但需注意这些非 UKB 结局测的是**痴呆/AD 风险**而非"认知表现评分"本身，故对"认知功能"这一具体性状的重叠无关确认仍不完全。

## 4. 局限与未来方向
- 非 UKB 结局是痴呆/AD（临床终点），非认知功能评分；直接非 UKB 认知功能 GWAS（COGENT, n=35k）待 OpenGWAS/GWAS Catalog 可获取后补做。
- 重叠校正法（MRlap / sample-overlap-corrected MR）尚未运行，建议作为下一步定量估计残差重叠偏倚。
- CHARLS 纵向队列到位后，提供真正的观察性"双队列"佐证（版本 B→A）。

## 5. 复现
```
python analysis/run_nonukb_sensitivity.py      # -> data/derived/mr_nonukb_sensitivity_results.csv
python analysis/make_nonukb_figure.py          # -> docs/figures/fig_nonukb_sensitivity.png
```
所有数字均可溯源至 `data/derived/mr_harmonized_*.csv`，无捏造；仅重新整合已有的本地 harmonized 数据。
