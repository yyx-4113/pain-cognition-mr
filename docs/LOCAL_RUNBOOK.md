# 本机执行手册（LOCAL RUNBOOK）

> 目的：把 `README.md` 里"需用户本机执行"的 4 件事，转成**可直接照敲的命令序列**。
> 适用范围：有正常外网 + R ≥ 4.3 + Python 3 的工作站 / 笔记本 / HPC 登录节点。
> 沙箱里已经完成的（MCP 摘要统计下载、24 个 OpenGWAS ID 的 gwasinfo 实测快照）**不必重做**，本手册只补沙箱做不了的部分。

---

## 0. 必做 / 不能代做 总览

| # | 任务 | 是否需账号 | 是否已部分完成 | 本机动作 |
|---|------|-----------|----------------|----------|
| A | gwasinfo 元数据落盘 (`--metadata-only`) | 需 JWT（你已给） | ✅ 已用 v4 API 实测落盘 `mr_gwas_metadata_20260920.csv` | **可选复核**（见步骤 1） |
| B | CHARLS 提取 → `charls_clean.rds` | **需 charls.pku.edu.cn 账号** | ❌ 未下载 | 步骤 2 |
| C | NHANES 提取 → `nhanes_clean.rds` | 公开（无需账号） | ❌ 未下载 | 步骤 3 |
| D | CWP 全量统计（Rahman 2021） | 需 KP4CD / 作者 | ❌ 未下载 | 步骤 4（**非阻塞**：`03` 缺 CWP 文件也能跑 MR，只是少一个敏感性分析） |
| E | 跑完整管线 `00_run_all.R` | — | ❌ | 步骤 5（**前提是 B、C、JWT、MCP 已就位**） |

---

## 0.5 环境准备（一次性安装）

### R（≥ 4.3）包
```r
# 观测性分析 + 提取
install.packages(c("haven","dplyr","tidyr","stringr","here",
                   "lme4","survival","rms","mice","tableone",
                   "survey","foreign","ggplot2","nhanesA"))
# MR（注意：ieugwasr / TwoSampleMR 需 v4 兼容版，能识别 api.opengwas.io/api）
install.packages(c("TwoSampleMR","ieugwasr","dplyr","ggplot2"))
# MR-PRESSO（若 CRAN 版装不上，用 GitHub 版）
install.packages("MRPRESSO")   # 或 remotes::install_github("remlapmot/MRPRESSO")
```
> 装好后验证：`library(ieugwasr); options(ieugwasr.api_root="https://api.opengwas.io/api"); gwasinfo("ebi-a-GCST006572")` 能返回即 OK。

### Python（步骤 A1 用）
```bash
python3 --version          # 3.8+ 即可，纯标准库，无需 pip install
```
> `fetch_gwas_metadata.py` 只用 `urllib/csv/json`，不依赖 `requests`。

### JWT（步骤 A2 / E 需要）
- 已生成在 `孟德尔疼痛/JWT.txt`（约 2026-10-04 过期）。
- 持久化到 R：在 `~/.Renviron` 加一行 `OPENGWAS_JWT="粘贴你的JWT"`（重启 R 生效）；或每次运行前在 R 里 `Sys.setenv(OPENGWAS_JWT="...")`。
- **切勿提交进 git**（已在 `.gitignore`）。

---

## 1. 步骤 A（可选复核）：gwasinfo 元数据

沙箱已用 OpenGWAS **v4 API**（`https://api.opengwas.io/api`）实测拉取了全部 24 个 OpenGWAS ID，
落盘在 `data/derived/mr_gwas_metadata_20260920.csv`（missing=0）。**你本机只需复核或刷新**，二选一：

### 方法 A1（推荐，纯 Python，绕过 R 旧路由，最稳）
```bash
cd pain-cognition-mr
python3 analysis/fetch_gwas_metadata.py
# 输出：data/derived/mr_gwas_metadata_YYYYMMDD.csv
```
脚本会自动向上查找 `JWT.txt`（项目根 `孟德尔疼痛/JWT.txt`）。**JWT 约 2026-10-04 过期，过期后需重新生成。**

### 方法 A2（R，需装 TwoSampleMR/ieugwasr 且支持 v4）
```bash
cd pain-cognition-mr
# 在 R 里先设令牌（或用 ~/.Renviron 持久化 OPENGWAS_JWT=...）
Rscript -e 'Sys.setenv(OPENGWAS_JWT="粘贴你的JWT"); options(ieugwasr.api_root="https://api.opengwas.io/api"); source("analysis/03_mr_pain_cognition.R")' --metadata-only
# 等价于：Rscript analysis/03_mr_pain_cognition.R --metadata-only  （前提是脚本内能读到 OPENGWAS_JWT）
```
> 注意：`03_mr_pain_cognition.R` 已把 `ieugwasr.api_root` 指向 `https://api.opengwas.io/api`（v4 主机），
> 不要再设成已停用的 `gwas-api.mrcieu.ac.uk` 旧根。

---

## 2. 步骤 B：CHARLS 下载 + 提取（**需账号**）

### 2.1 申请与下载
1. 注册 / 登录 <https://charls.pku.edu.cn/> → 数据申请。
2. 下载 **waves 2011 / 2013 / 2015 / 2018 / 2020** 的问卷模块，重点是：
   - **健康与功能模块**（含疼痛 DA041/DA042、慢病、ADL）
   - **认知模块**（即时/延迟词语回忆 dc009s1–10、dc012s1–10；连线/画图 dc014；连续减 7 dc024；时间定向 dc003–006）
   - **基本信息 / 人口学**（年龄、性别、教育、城乡、婚姻）
   - **抑郁（CESD）模块**、**体检（身高体重→BMI）**
3. 文件格式通常是 **Stata `.dta`**（也有 SAS/SAV）。把每波的 `.dta` 放进：
   ```
   pain-cognition-mr/data/raw/charls/raw/<wave>/
   ```
   例如 `data/raw/charls/raw/2015/...dta`。

### 2.2 变量真相（务必对照码书核验）
本项目已查证的 CHARLS 真实字段结构（来源：多篇 CHARLS 方法学论文 + CHARLS harmonized 惯例）：

| 概念 | 原始分波变量（raw `.dta`） | Harmonized 名称 | 说明 |
|------|---------------------------|----------------|------|
| **疼痛："常被身体疼痛困扰？"** | `DA041`（2011/2013/2015/2018）或 `DA028`（2020）；5 点：None/A little/Somewhat/Quite a bit/Very much | — | **任何非 None = 有疼痛** |
| **疼痛部位（15 个）** | `DA042*` 系列（head/neck/shoulder/arm/wrist/finger/chest/stomach/back/waist/buttock/leg/knee/ankle/toe） | — | **计数部位数 → 多部位疼痛（MCP）**；≥2 或 ≥3 站点，按你方案定义 |
| 即时词语回忆 | `dc009s1`–`dc009s10`（各 0/1，求和 0–10） | `imrc` | 记忆 |
| 延迟词语回忆 | `dc012s1`–`dc012s10`（求和 0–10） | `dlrc` | 记忆 |
| 情景记忆 EM | (imrc+dlrc)/2 或求和 | — | 0–10 |
| 连续减 7（计算） | `dc024`（0–5） | `ser7` | 心智完整性 |
| 时间定向 | `dc003`–`dc007`（年/月/日/星期/季节，求和 0–5） | `orient` | 心智完整性 |
| 画图（五边形/图形） | `dc014`（0/1） | `draw` | 心智完整性 |
| 心智完整性 MS | ser7 + orient + draw | — | 0–11 |
| 总认知（标准 CHARLS 全局分） | im + de + ser7 + orient + draw | `cog_global` | 0–31，越高越好（文献主流约定） |
| 年龄 / 性别 / 教育 | 人口学模块（波次前缀 `r1`/`r2`/`r3`/`r4`/`r5`） | `age`/`gender`/`educ` | 协变量 |
| CESD-10 抑郁 | 抑郁模块 | `cesd` | 协变量 / 中介 |
| BMI | 体检模块身高体重 | `bmi` | 协变量 |

> ⚠️ **CHARLS 没有美式 TICS 总分**——它的认知来自改良版 TICS，组件就是上表的即时/延迟回忆 + 连线/画图 + 减 7 + 定向。脚本里已按此修正，请勿套用 "TICS 总分" 变量。
> ⚠️ 各波变量名前缀（`r1/r2/r3/r4/r5`）与模块命名**务必在下载后对照官方码书逐条确认**；脚本对缺失字段会直接报错并列出可用变量名。

### 2.3 提取
```bash
cd pain-cognition-mr
Rscript analysis/10_charls_extract.R
# 输出：data/raw/charls_clean.rds（长表：每受访者×波次）
# 列：id, wave, age, sex, edu, pain_sites, cog_im, cog_de, cog_draw, cog_ser7, cog_orient, bmi, cesd, ...
```
脚本逻辑：自动检测 raw 分波 `.dta` → 求和认知组件、计数疼痛部位 → 输出长表。`01_charls.R` 直接消费此文件。

---

## 3. 步骤 C：NHANES 下载 + 提取（公开）

### 3.1 自动下载（推荐）
```bash
cd pain-cognition-mr
Rscript analysis/download_nhanes.R
# 需 R 包 nhanesA（install.packages("nhanesa") 或 remotes::install_github(...)）
# 输出：data/raw/nhanes/<cycle>_<COMP>.XPT
```
脚本拉取 `DEMO / MCQ / DPQ / SLQ / PFQ / HSQ` 等组件（见下方变量表）。

### 3.2 变量真相（务必对照码书核验）
NHANES **没有跨周期一致的"慢性多部位疼痛"量表**，且**疼痛问卷与认知测评周期不重叠**——
因此本项目把 NHANES 定位为**辅助证据**（疼痛→主观记忆主诉 / 抑郁 / 睡眠 / 功能受限），
绝不把它当"疼痛→客观认知"的主证据（主证据是 CHARLS + MR）。已查证的组件：

| 组件文件 | 周期 | 关键变量 | 用途 |
|----------|------|----------|------|
| `DEMO` | 所有 | `SEQN`(主键), `SDMVSTRA`, `SDMVPSU`, `WTMEC2YR`/`WTINT2YR`, `RIDAGEYR`, `RIAGENDR`, `RIDRETH3`, `DMDEDUC` | 抽样权重 + 人口学 |
| `MCQ`（医疗状况） | 所有 | `MCQ160E`（记忆比同龄差？1是/2否）, `MCQ160F`（记忆问题干扰生活？）, `MCQ250A`（关节炎） | **主观记忆主诉 / 关节炎疼痛代理** |
| `DPQ`（抑郁筛查，PHQ-9 式） | 所有 | `DPQ010`–`DPQ090`（0–3 频率） | 抑郁（≥3 项 ≥"一半以上天数"≈阳性） |
| `SLQ`（睡眠障碍） | 所有 | `SLQ050`（睡眠困难 1是/2否） | 睡眠 |
| `PFQ`（功能受限） | 2007–2016 | `PFQ010`–`PFQ090`（困难 1是/2否） | 功能受限（疼痛后果） |
| `HSQ`（总体健康） | 所有 | `HSQ` 系列 | 总体健康自评 |

> NHANES 客观认知测评（NIH-Toolbox `COGN`/`CFQ`）仅在 **2011–2014** 有；而近周期无疼痛问卷。
> 故 `02_nhanes.R` 只用疼痛**代理**（关节炎/MCQ 主诉）→ 中介/受限，Methods 中必须声明此周期错配局限。
> 重新编码规则：NHANES 用 `7777/9999` = 拒答/未知 → 设为缺失；`1=是,2=否` 习惯翻成 `1/0`。

### 3.3 提取
```bash
cd pain-cognition-mr
Rscript analysis/11_nhanes_extract.R
# 输出：data/raw/nhanes_clean.rds（每行一名受访者，带 cycle 标签）
# 列：seqn, cycle, sdmvstra, sdmvpsu, wtmec2yr, age, sex, pain_proxy, mcq_memory_any, dpq_depressed, sleep_trouble, func_limitation
```

---

## 4. 步骤 D：CWP 全量统计（Rahman 2021）

- GWAS Catalog `GCST011779` 仅含 **top hits**（`fullPvalueSet=FALSE`），无全量摘要统计。
- 全量需从 **KP4CD 知识门户**（Dataset ID `Rahman2021_Chronic_Widespead_MSK_Pain_EU`）或联系作者获取。
- 下载后放入 `data/raw/`，并在 `03_mr_pain_cognition.R` 的 CWP 分支（现为占位）填入真实路径与列名。
- 与 MCP 同理：CWP **不在 OpenGWAS**，属本地文件、非 JWT 流程。

---

## 5. 步骤 E：跑完整管线

> ⚠️ **`00_run_all.R` 不会调用 `10_charls_extract.R` / `11_nhanes_extract.R`** —— 它只跑 `01→02→03→04`。
> 所以 **B（CHARLS 提取）和 C（NHANES 提取）必须在 E 之前手动跑完**，否则 `01`/`02` 会因缺 `charls_clean.rds` / `nhanes_clean.rds` 而优雅退出、不出结果。
>
> E 的前置硬条件：
> 1. `data/raw/charls_clean.rds`（来自步骤 B）✅ 必须有
> 2. `data/raw/nhanes_clean.rds`（来自步骤 C）✅ 必须有
> 3. `data/raw/chronic_pain-bgen.stats.gz`（沙箱已下载，已在位）
> 4. `OPENGWAS_JWT` 已设（步骤 A2 验证过）+ R 包装好 + `ieugwasr.api_root` 指向 v4

前置全部就位后：
```bash
cd pain-cognition-mr
Rscript analysis/00_run_all.R
# 内部顺序：03 --metadata-only（复核gwasinfo）→ 01 CHARLS 纵向(LMM+Cox+RCS)
#          → 02 NHANES 辅助 → 03 MR(双向+MVMR) → 04 两步中介
# 每个脚本输出 data/derived/ 下的带日期文件 + 打印 manifest。
```
输出核对要点（审计追踪，禁止无源数字进稿）：
- `01`：疼痛负担(0/1/2/≥3) × 认知下降 的 β/SE/p；认知障碍 Cox HR；RCS 剂量反应图。
- `03`：每个 MR 对的 IV 数、F、方向、IVW/加权中位数/Egger、leave-one-out、MR-PRESSO。
- `04`：MCP→中介→认知 的两步 β 与乘积项。

---

## 6. 安全与 hygiene

- **`JWT.txt` 是密钥**：已在 `.gitignore` 屏蔽，**切勿 `git add` / 外传**。约 2026-10-04 过期；用完可删除本地副本。
- **`data/raw/` 整目录被 `.gitignore` 忽略**（含 CHARLS/NHANES/MCP/CWP 原始文件）——只提交 `data/derived/` 的去标识聚合表。
- 所有"对照码书核验"字段若报错，按脚本打印的可用变量名修正 CONFIG 再跑。

---

## 7. 排错速查

| 现象 | 原因 / 解决 |
|------|-------------|
| `10_charls_extract.R` 报 `Missing ... Available: r1..., dc009s1...` | 该波变量名与 CONFIG 不符 → 按列出的可用名改 CONFIG 对应波次 |
| `11_nhanes_extract.R` 某 cycle 缺 `DEMO` | `download_nhanes.R` 没拉到该周期 → 检查网络 / 手动补 XPT |
| MR 脚本 `gwasinfo` 返回空 | JWT 过期或未设 `OPENGWAS_JWT`；或 `api_root` 没指向 `https://api.opengwas.io/api` |
| `ukb-*` 暴露与认知结局同源 UKB | 样本重叠 → 主 MR 结局改用 `ieu-a-297`(IGAP AD) / `finn-b-F5_DEMENTIA`，避免 `ukb-b-*` 配对 `ebi-a-GCST006572` |
| NHANES 无疼痛问卷报错 | 预期内——NHANES 用关节炎/MCQ 主诉作疼痛代理，不是直接疼痛量表 |
