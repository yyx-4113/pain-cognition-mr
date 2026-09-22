# 预印本上传指南（Research Square · 版本 1）

目标平台：**Research Square**（Springer Nature 旗下，与 *Scientific Reports* 同源，支持一键 transfer 到期刊；无编辑筛选、上传即获 DOI）。

> 注意：发预印本需用**你本人 ORCID** 登录 Research Square 操作，本指南仅把文件准备到位 + 给出分步指引。我无法代替你登录上传。

## 一、本包文件清单（`docs/submission/_upload_preprint/`）

| 文件 | 用途 | 上传位置 |
|---|---|---|
| `Preprint_Manuscript.docx` | 主稿件（含预印本横幅 + 版本说明） | Manuscript |
| `Supplementary_Information.docx` | S1 非 UKB 敏感性 + S2 审计轨 | Supplementary material |
| `STROBE-MR_checklist.docx` | STROBE-MR 2021 合规清单 | Supplementary material |
| `figures/Fig1_forest.pdf` … `Fig5_nonukb.pdf` | 5 张图（PDF 优先，PNG 备选） | Figures（逐张上传） |

## 二、分步上传

1. 打开 https://www.researchsquare.com ，用 **ORCID** 登录（首次需关联 ORCID 0009-0004-9698-6552）。
2. 点 **"Publish a preprint" / "Start new preprint"**。
3. **Manuscript**：上传 `Preprint_Manuscript.docx`。
4. **Figures**：逐张上传 `figures/` 下 5 个 PDF（或 PNG）。系统会自动编号 Fig 1–5。
5. **Supplementary material**：上传 `Supplementary_Information.docx` 与 `STROBE-MR_checklist.docx`。
6. **Title / Abstract / Authors / Keywords / Subject area**：照抄 `Preprint_Metadata.md` 对应字段。
   - Author：Yongxin Yang, **B.M.**（勿填 MD/PhD）；单位写全称。
   - Keywords 选 5–6 个。
7. **Comments to readers**：粘贴 `Preprint_Metadata.md` 中 "Author comments to readers" 段落（说明 CHARLS [PENDING DATA] 为前瞻性、因果方向未定、UKB 重叠限制）。
8. 确认 **License**（默认 CC BY 4.0，预印本推荐），提交。

## 三、版本与后续

- 上传后系统给 **DOI**，可引用为 "Yang Y. *Preprint.* Research Square. DOI:xxx"。
- **CHARLS 数据到位后**：用 `10_charls_extract.R` + `01_charls.R` 补全 §2.7/§3.5，升版本 A，在本稿基础上**再发版本 2**（Research Square 支持版本迭代，旧版本保留）。
- **版本 2 发布后**：在 Research Square 点 **"Transfer to journal"** → 选 *Scientific Reports*（或届时直接用 `docs/submission/_upload/` 的期刊投稿包走 Editorial Manager）。Springer Nature 期刊认可 Research Square 预印本，不视为既发。
- 数据可用性声明中的 `github.com/yyx-4113/pain-cognition-mr` 仓库请**先建好并含全部衍生数据 + 代码**，再上传预印本（否则声明失真）。

## 四、诚实性提醒（务必保留）

- 稿件中 `[PENDING DATA]` 段是**前瞻性计划**，不是结果；请勿在上传时改为"已完成"。
- 因果方向**未定**（反向 MR 显著、Steiger 不显著）；主认知结局受 UKB×UKB 重叠限制——这些限制已在正文与 Comments 中写明，上传前勿弱化。
