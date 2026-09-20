# Statistical Analysis Plan (SAP)

**Study:** Multisite chronic pain (pain burden) and cognitive decline / dementia
**Protocol:** `方案二_多部位慢性疼痛与认知下降的双队列与双向MR.md`
**SAP version:** v1.0 ｜ **Date:** 2026-09-20
**Author:** Yongxin Yang

> 本 SAP 将方案框架 operationalize 为可运行步骤与脚本映射。所有脚本位于 `analysis/`，所有产出落于 `data/derived/` 并带日期+版本，保证每个稿件数字可溯源。

---

## 0. 分析管线总览
```
00_run_all.R
  ├─ 01_charls.R    CHARLS 纵向：暴露定义 → LMM → Cox → RCS → 亚组
  ├─ 02_nhanes.R    NHANES 横断面：辅助验证（认知子样本 + 主观认知抱怨全样本）
  ├─ 03_mr_pain_cognition.R   双向 MR + MVMR（正向 MCP→认知/AD；反向；Steiger）
  └─ 04_mr_mediation.R        两步 MR 中介（疼痛→抑郁/CRP/失眠→认知）
```

## 1. 暴露定义（观察性，"负担化"）
- **疼痛部位数**：0 / 1 / 2 / ≥3（CHARLS 自评 7–10 部位；对应 MCP GWAS 定义，便于与 MR 对仗）。
- **疼痛状态**：无 / 有（敏感性）。
- **困扰程度**：是否影响日常活动 / 工作（交叉验证，缓解回忆偏倚）。
- 产出：`data/derived/charls_exposure_table.rds` + Table 1（按暴露分层基线特征）。

## 2. CHARLS 纵向分析（01_charls.R）
### 2.1 结局
- 综合认知 Z 分（TICS-10 + 情景记忆 + 画图视觉空间，基线与各波标准化）。
- "认知下降事件"：随访较基线下降 > 1 SD，或处于最低四分位。

### 2.2 模型
| 模型 | 方法 | R 实现 | 输出 |
|---|---|---|---|
| A 粗模型 | 疼痛部位数 × 时间，随机截距+斜率 | `lme4::lmer` | Fig 3 轨迹 |
| B 模型1 | + 人口学（年龄/性别/教育/城乡/婚姻） | `lmer` | Table 2 |
| C 模型2 | + 生活方式 + 合并症 + 用药（NSAIDs/阿片） | `lmer` | Table 2 |
| D Cox | 认知下降事件 ~ 基线疼痛部位数 | `survival::coxph` | Table 3 |
| E 竞争风险 | Fine-Gray（死亡为竞争事件） | `cmprsk::crr` | 敏感性 |

### 2.3 剂量-反应
- 限制性立方样条 RCS（`rms::rcs`），3–5 节点；报告 P-overall 与 P-nonlinear。
- 产出：Fig 3（RCS 曲线）+ Table（OR/HR + 95%CI）。

### 2.4 缺失与失访
- 多重插补 `mice`（m=20）→ 逆概率加权 IPW 校正失访。
- 排除基线认知最低四分位者做反向因果敏感性。

### 2.5 亚组与交互
- 性别、年龄（<65 / ≥65）、教育、基线认知；交互项 P-interaction。
- 产出：Table 3 森林图。

## 3. NHANES 辅助分析（02_nhanes.R）
- **限制**：疼痛问卷周期（2019–2020）与认知测评周期（2011–2014）不重叠 → 不作为主认知结局。
- 用法：疼痛 → 主观认知抱怨（MCQ，全年龄可得）+ 日常活动受限 / 抑郁 / 睡眠（辅助验证）。
- 在 Discussion 明确周期限制，不做"痴呆诊断"断言。

## 4. 双向 MR（03_mr_pain_cognition.R）
### 4.1 数据获取
- 设 `Sys.setenv(OPENGWAS_JWT=...)`（2026 强制）。
- 暴露 MCP：本地读 `data/raw/chronic_pain-bgen.stats.gz`（格拉斯哥库 DOI 10.5525/gla.researchdata.822）→ `read_exposure_data` → `ld_clump`。
- 结局：OpenGWAS 提取 `ebi-a-GCST006572`（认知表现，UKB 衍生）、`ieu-a-297`（IGAP AD，n=54,162）/ `finn-b-F5_DEMENTIA`（全因痴呆）。
- **先跑 `--metadata-only`**：`gwasinfo()` 回显所有 ID 样本量/nsnp/build → `data/derived/mr_gwas_metadata.tsv`（溯源）。

### 4.2 工具变量
- P < 5×10⁻⁸；clumping r²<0.001 / 10,000 kb；F>10；剔除回文。

### 4.3 分析
- 正向：MCP → 认知表现 / AD / 痴呆（IVW 主 + MR-Egger + Weighted median + Weighted mode）。
- 反向：认知表现 → MCP（排除"认知下降者更易报告疼痛"）。
- 多效性：MR-Egger intercept、MR-PRESSO、Cochran Q；离群 SNP 剔除后重算并双报。
- 方向性：Steiger（双向）。
- 敏感性：leave-one-out、散点图、漏斗图、森林图（Fig 4 四联图）。
- MVMR：校正教育（`ieu-a-755`）、吸烟（`ieu-b-4877`）、BMI（大样本）、卒中。

### 4.4 重叠控制
- 认知表现（`ebi-a-GCST006572`）为 UKB 来源 → 不与 `ukb-b-*` 疼痛表型配对；主 MR 用 IGAP AD / FinnGen 痴呆。

## 5. 两步 MR 中介（04_mr_mediation.R）
- 路径：疼痛 → 抑郁（`ieu-b-102`）→ 认知；疼痛 → CRP（Said 2022）→ 认知；疼痛 → 失眠（`ukb-b-3957`）→ 认知。
- 间接效应 = β₁ × β₂；delta 法 / bootstrap 求 CI。
- **所有中介结果统一标注"提示性（suggestive）"，不做因果断言**。

## 6. 报告规范
- 观察性：STROBE + 流程图（Fig 1–2）。
- MR：STROBE-MR 2021 清单逐条落实（Supplementary）。
- 必备图件：Table 1–3、Fig 1–5、Supp（E-value、PSM/IPTW、插补敏感性、STROBE-MR 清单）。

## 7. 软件与版本
- R ≥ 4.3；TwoSampleMR、ieugwasr、lme4、survival、rms、mice、tableone、ggplot2、cmprsk、clubSandwich。
- 版本快照由 `00_run_all.R` 的 `sessionInfo()` dump 落盘。

## 8. 待关闭清单（执行前）
- [ ] 取得 OpenGWAS JWT 并本地配置。
- [ ] 下载 CHARLS / NHANES 提取至 `data/raw/`。
- [ ] 下载 MCP 摘要统计至 `data/raw/`。
- [ ] 确认 §4.4 重叠配对策略；确认 CRP（GCST）、CWP、BMI 的待定 ID（见 `gwas_catalog.md`）。
