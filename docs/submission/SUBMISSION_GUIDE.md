# Scientific Reports 投稿指南与文件清单

> 目标期刊：**Scientific Reports**（Nature Portfolio，SCIE，2025 JCR JIF ≈ 4.9，OA 巨型刊）
> 文章类型：**Article**（原创研究）
> 生成日期：2026-09-20 ｜ 单作者：Yongxin Yang（B.M.，不挂 MD/PhD 头衔）
> 本目录 `docs/submission/_upload/` 下所有文件均为投稿就绪状态。

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
| `Manuscript.docx` | **主稿件** | 标题页 + 非结构化摘要（193 词，<200）+ IMRaD 正文 + 参考文献（编号 1–17）+ 声明（作者贡献/利益冲突/数据可用性/基金/生成式 AI 使用/伦理）+ 图注 |
| `Cover_Letter.docx` | 投稿信 | 致编辑部，含研究意义、关键发现、STROBE-MR 合规、单一作者声明、AI 使用披露、数据/代码可用性 |
| `Supplementary_Information.docx` | 补充材料 | S1 非 UKB 重叠稳健性敏感性分析（含 3 结局表）；S2 衍生数据审计轨 |
| `STROBE-MR_checklist.docx` | 报告规范清单 | STROBE-MR 2021 逐条合规表（从 `docs/strobe_mr_checklist.md` 生成，已剥离中文图例/小结、状态图标转文字） |
| `figures/Fig1_forest.pdf/.png` | 图 1 森林图 | 原 fig_forest |
| `figures/Fig2_scatter.pdf/.png` | 图 2 SNP 散点（MCP→认知） | 原 fig_scatter |
| `figures/Fig3_loo.pdf/.png` | 图 3 留一法 | 原 fig_loo |
| `figures/Fig4_funnel.pdf/.png` | 图 4 漏斗图 | 原 fig_funnel |
| `figures/Fig5_nonukb.pdf/.png` | 图 5 非 UKB 重叠稳健性 | 原 fig_nonukb_sensitivity（已补 PDF） |

> 图件格式：PDF（矢量）+ PNG（高分辨率）双份；Sci Rep 接受 TIFF/EPS/PDF/PNG，最低 300 dpi，本稿图表满足。
> 所有正文数字 100% 可溯源至 `data/derived/*.csv`（见 S2 审计轨）。

---

## 三、投稿前必办清单（请逐项确认后再点 Submit）

1. **⚠️ CHARLS 章节决策（关键）**：稿件 §2.7 与 §3.5 当前标记为 **[PENDING DATA]**（CHARLS 数据访问仍未获批，`data/raw/charls/raw/` 为空）。正式投稿前二选一：
   - **(A)** 待 CHARLS 数据到位后，用 `10_charls_extract.R` + `01_charls.R` 补全，升级为版本 A；或
   - **(B)** 本次先删除 §2.7 / §3.5 两段（及 STROBE-MR 清单中对应的 ⛔ 项），以"版本 B（MR + NHANES 描述性）"直接投稿。
   - 当前 `_upload/Manuscript.docx` 仍含 [PENDING DATA] 段落，**不建议**带着 pending 段落投稿。
2. **生成式 AI 使用披露**：已在稿件"Generative AI usage"声明与投稿信中如实披露（WorkBuddy 用于编辑审阅/排版/制图支持，作者对全部内容负责）。如期刊系统有独立 AI 声明字段，请照实勾选。
3. **数据可用性链接**：声明中使用了实名仓库 `https://github.com/yyx-4113/pain-cognition-mr`。**请确认该仓库已创建并含全部衍生数据与代码**（含 `CITATION.cff`、`LICENSE`、`README.md`、复现命令），否则数据可用性声明不成立。
4. **作者署名**：署名仅 **Yongxin Yang**（B.M.），系统若自动带出 "Yongxin Yang, MD" 必须删除 MD。
5. **图表上传**：5 张图按 Fig1–Fig5 分别上传，图注已置于稿件末尾；可选上传矢量 PDF 优先。
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
   - *Figure 1*…*Figure 5* ← 对应 `figures/FigN_*.pdf`（或 PNG）
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

脚本从 `docs/manuscript_draft.md` 读取并自动：剥离内部状态横幅、图号 4→1…8→5 重编号、摘要改写为非结构化、声明段重排、补充材料与清单生成、图表拷贝并补 Fig5 PDF。
