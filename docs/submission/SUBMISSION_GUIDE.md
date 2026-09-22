# Scientific Reports 投稿指南与文件清单

> 目标期刊：**Scientific Reports**（Nature Portfolio，ISSN 2045-2322，SCIE 收录；**2025 JCR JIF = 4.9 / JCR Q1**，2024 JCR JIF 3.9；OA 巨型刊）— 指标已于 2026-09-21 联网核实
> 文章类型：**Article**（原创研究）
> 生成日期：2026-09-20 ｜ 单作者：Yongxin Yang（B.M.，不挂 MD/PhD 头衔）
> 本目录 `docs/submission/_upload/` 下所有文件均为投稿就绪状态。

---

## 零、期刊指标核实（已联网验证，2026-09-21）

| 指标 | 数值 | 来源 / 年份 |
|---|---|---|
| 收录状态 | **SCIE 收录**（Web of Science / JCR）；另被 PubMed、PMC、Scopus、DOAJ 收录；2022–2026 连续收录 | 武汉大学图书馆投稿指南系统、东北农业大学图书馆收录汇总、nature.com（2026-09-21 核验） |
| 2025 JCR JIF | **4.9**（5 年 JIF 4.8） | nature.com/srep 官方 "About Scientific Reports" 页；JCR 2025 数据表（Clarivate，2026 发布） |
| 2025 JCR 分区 | **Q1**（MULTIDISCIPLINARY SCIENCES，rank 21/140，85.4 百分位；JCI 1.13，Q1，rank 23/140） | JCR 2025 数据表（Clarivate，2026） |
| 2024 JCR JIF | **3.9**（5 年 JIF 4.3），JCR Q1 | Nature Scientific Reports 指标图、武汉大学图书馆（2025） |
| 中科院分区（CAS） | 综合性期刊 **3 区**（小类 MULTIDISCIPLINARY SCIENCES 3 区）；有二手来源称 2 区，**未单独核实**，以官方分区表为准 | 武汉大学图书馆 / 东北农业大学图书馆（2025）；biocloudy 二手源称 2 区，存疑 |
| 接受率 | ~33% | Nature 官方指标图 |

> 注：2025 JCR 为当前最新（Clarivate 2026 年发布）；个别二手源（biocloudy）称 2025 JIF=4.8（按剔除撤稿引用新规则），与 Nature 官方 4.9 略有出入，本稿采用 Nature 官方值 4.9。Scientific Reports 为真实存在、SCIE 收录期刊，符合投稿推荐纪律。本刊 IF 已高于此前版本 A 评稿时"≈4.5 天花板"的估计，对本文方法学透明、假设生成型的 MR 研究适配度高。

---

## 一、投稿网站（投稿门户）

- **期刊主页**：https://www.nature.com/srep/
- **投稿系统**：Editorial Manager — https://www.editorialmanager.com/srep/
  - 点击期刊主页的 **"Submit manuscript"** 按钮会跳转至此；以跳转后的实际地址为准。
- **首次投稿需注册账号**（Editorial Manager 账号，建议用 960856791@qq.com 注册，与 ORCID 绑定）。
- 投稿免费（无稿件处理费提交），录用后需支付 **APC（文章处理费）**：2025 年约 **£2,090 / $2,590**（金额以投稿系统内显示及官网当年公告为准，本文未单独核实，请在付款前确认）。

---

## 二、已生成的投稿包文件（`docs/submission/_upload/`）

| 文件 | 用途 | 说明 |
|---|---|---|
| `Manuscript.docx` | **主稿件（版本 A++）** | 标题页 + 非结构化摘要（<200 词）+ IMRaD 正文（含 §2.7/§3.5 CHARLS 纵向 + §3.5.2 变化分敏感性）+ 参考文献 + 声明（作者贡献/利益冲突/数据可用性/基金/生成式 AI 使用/伦理）+ 图注 |
| `Cover_Letter.docx` | 投稿信 | 致编辑部，含研究意义、关键发现（含 CHARLS 纵向 null、四波伪影、变化分 Lord's paradox）、STROBE-MR 合规、单一作者声明、AI 使用披露、数据/代码可用性 |
| `Supplementary_Information.docx` | 补充材料 | S1 非 UKB 重叠稳健性敏感性分析（含 3 结局表）；S2 CHARLS 纵向与变化分敏感性；S3 衍生数据审计轨（含 `charls_results_changescore_20260921.rds` 等） |
| `STROBE-MR_checklist.docx` | 报告规范清单 | STROBE-MR 2021 逐条合规表（从 `docs/strobe_mr_checklist.md` 生成，已剥离中文图例/小结、状态图标转文字） |
| `figures/Fig1_forest.pdf/.png` | 图 1 森林图 | 原 fig_forest |
| `figures/Fig2_scatter.pdf/.png` | 图 2 SNP 散点（MCP→认知） | 原 fig_scatter |
| `figures/Fig3_loo.pdf/.png` | 图 3 留一法 | 原 fig_loo |
| `figures/Fig4_funnel.pdf/.png` | 图 4 漏斗图 | 原 fig_funnel |
| `figures/Fig5_nonukb.pdf/.png` | 图 5 非 UKB 重叠稳健性 | 原 fig_nonukb_sensitivity |
| `figures/Fig6_charls_rcs.pdf/.png` | 图 6 CHARLS 剂量-反应样条 | 原 fig_charls_rcs（版本 A++ 新增） |
| `figures/Fig7_overlap_bias.pdf/.png` | 图 7 重叠偏倚敏感性 | 原 fig_overlap_bias（版本 A++ 新增） |

> 图件格式：PDF（矢量）+ PNG（高分辨率）双份；Sci Rep 接受 TIFF/EPS/PDF/PNG，最低 300 dpi，本稿图表满足。
> 所有正文数字 100% 可溯源至 `data/derived/*.csv`（见 S2 审计轨）。

---

## 三、投稿前必办清单（请逐项确认后再点 Submit）

1. **CHARLS 章节（已完成，版本 A++）**：CHARLS 数据已于 2026-09-21 到位并跑通纵向分析（三波 2011/13/15 + 四波 2018 敏感性 + 变化分 ANCOVA 敏感性），§2.7/§3.5（含 §3.5.1/§3.5.2）均为**真实估计**，无 [PENDING DATA] 占位。稿件当前为**版本 A++**，可直接投稿。核心结论：横断面疼痛部位负担↔较低认知（剂量-反应 P<0.001）；纵向 7 年（含 2018 四波）未检出疼痛加速认知下降（Cox HR 1.005, p=0.38；LMM pain×time p=0.70）；变化分 ANCOVA 全模型 β=−0.0067 (p=0.016) 因 Lord's paradox 矛盾、不推翻主结论。投稿前仅需确认数据可用性仓库 `github.com/yyx-4113/pain-cognition-mr` 已就绪（见第 3 项）。
2. **生成式 AI 使用披露**：已在稿件"Generative AI usage"声明与投稿信中如实披露（WorkBuddy 用于编辑审阅/排版/制图支持，作者对全部内容负责）。如期刊系统有独立 AI 声明字段，请照实勾选。
3. **数据可用性链接**：声明中使用了实名仓库 `https://github.com/yyx-4113/pain-cognition-mr`。**请确认该仓库已创建并含全部衍生数据与代码**（含 `CITATION.cff`、`LICENSE`、`README.md`、复现命令），否则数据可用性声明不成立。
4. **作者署名**：署名仅 **Yongxin Yang**（B.M.），系统若自动带出 "Yongxin Yang, MD" 必须删除 MD。
5. **图表上传**：7 张图按 Fig1–Fig7 分别上传（Fig6 CHARLS 剂量-反应样条、Fig7 重叠偏倚敏感性为版本 A++ 新增），图注已置于稿件末尾；可选上传矢量 PDF 优先。
6. **STROBE-MR 清单**：作为补充文件上传（Reporting Summary / Checklist 环节）。
7. **利益/基金/伦理声明**：已写入稿件声明段，系统对应字段照抄即可（无基金、无利益冲突、豁免知情同意）。

---

## 四、Editorial Manager 上传步骤（概览）

1. 登录 https://www.editorialmanager.com/srep/ → **"Submit New Manuscript"**。
2. **Article Type** 选 **"Article"**。
3. **Title / Abstract**：复制 `Manuscript.docx` 标题页与摘要（摘要为单段、<200 词、无参考文献）。
4. **Keywords**：建议 4–6 个（Mendelian randomization; chronic pain; cognitive decline; Alzheimer's disease; UK Biobank; overlap bias）。
5. **Authors**：添加 Yongxin Yang，绑定 ORCID 0009-0004-9698-6552；确认无 MD/PhD 后缀。
6. **Files 上传**（按系统角色拖入）：
   - *Main Document* ← `Manuscript.docx`
   - *Cover Letter* ← `Cover_Letter.docx`
   - *Supplementary Material* ← `Supplementary_Information.docx`
   - *Other* / *Reporting Summary* ← `STROBE-MR_checklist.docx`
   - *Figure 1*…*Figure 7* ← 对应 `figures/FigN_*.pdf`（或 PNG）
7. **Comments to Editor**：可附投稿信要点；如实勾选 AI 使用、预注册状态（未预注册）、重叠偏倚说明。
8. **Review & Submit** → 确认后生成稿号，系统发送确认邮件至 960856791@qq.com。

---

## 五、重要诚实性提示（与评审纪律一致）

- 主结局 MCP→认知表现受 **UKB×UKB 样本重叠**限制，稿件已明确标为 **hypothesis-generating**；非 UKB 重叠稳健性（IGAP AD β=0.466, p=0.008）为独立佐证，但测的是痴呆/AD *风险*而非认知评分本身。
- 双向 MR 均显著 + Steiger 不显著 → **因果方向未定**，稿件表述为"关联"而非单边因果。
- 未运行 MR-PRESSO（环境无 TwoSampleMR 栈），以留一法为替代并如实说明；MRlap 重叠校正列为未来工作。
- 所有 GWAS/方法文献引用均已核实（PMID/DOI 见稿件参考文献 1–17），认知表现 accession `ebi-a-GCST006572` 的元数据归属差异（UKB 认知评分 vs. Catalog 误标教育程度）已在方法学 §2.2 披露。

---

## 六、复现命令

```bash
cd docs/submission
python build_srep_pack.py        # 重新生成 _upload/ 下全部文件
```

脚本从 `docs/manuscript_draft.md` 读取并自动：剥离内部状态横幅（首个 `---` 之前的中文状态块）、图号 4→1…10→7 重编号（含 2 位数 "Figure 10"→"Figure 7" 修正，新增 Fig6 CHARLS RCS、Fig7 重叠偏倚）、摘要改写为非结构化、声明段重排、补充材料与清单生成、图表拷贝（并自动 PNG→PDF 补图）。
