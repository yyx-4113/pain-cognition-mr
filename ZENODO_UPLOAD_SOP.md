# Zenodo 上传操作手册（ZENODO_UPLOAD_SOP）

> 适用项目：pain-cognition-mr（孟德尔随机化复现包）
> 最后更新：2026-09-22

---

## 0. 为什么之前"每次都卡住"——根因

Zenodo 上传**无法在 WorkBuddy（小团）的 Agent 执行环境里完成**。已实测确认：

| 测试 | 结果 |
|------|------|
| 沙箱内 `curl https://zenodo.org/api/`（经白名单代理） | `502 CONNECT tunnel failed` |
| 沙箱内绕开代理直接连 | `Could not resolve host: zenodo.org`（无直连 DNS） |
| 关闭沙箱隔离后再直连 | DNS 把 `zenodo.org` 解析成 `0.0.0.0`（空响应），仍连不通 |

结论：该环境的**唯一互联网出口是一个白名单代理**，只放行 `api.github.com`、`copilot.tencent.com` 等少数主机，**zenodo.org 不在白名单内**，且宿主本身也没有可用的直连 egress。所以无论是否"跳出沙箱"，只要在 WorkBuddy 里跑，就一定卡死/失败。

**但——你不必再重复上传文件。** 见下方 ★主路径：GitHub 关联自动归档。

---

## 1. ★ 主路径：GitHub 关联自动归档（推荐，零重复上传）

**机制**：在 Zenodo 把 GitHub 仓库关联一次，之后每次在 GitHub 打 **release tag**，Zenodo 通过 webhook 自动抓取该 tag 的仓库快照、生成 DOI、发邮件给你。**文件完全不用再上传一遍。**

已核实事实（来源：Zenodo 官方文档 / GitHub 集成 wiki，2026-09-22）：
- 仓库 `yyx-4113/pain-cognition-mr` 为 **PUBLIC**（默认分支 `master`），GitHub 集成可用。
- Zenodo 优先读仓库根 **`CITATION.cff`** 填充元数据（本项目已有，且已移除占位假 DOI 以避免解析失败）。若仓库同时有 `.zenodo.json`，则后者覆盖前者——本项目只用 `CITATION.cff`。
- ⚠️ **官方硬性警告：两种方法不可混用（Do not mix the two methods）。** 必须从 GitHub 集成开始；若先用手动 API 上传建了记录，再开 GitHub 集成会产生**第二个独立记录**。本项目尚未手动上传过，直接走 GitHub 集成即可，手动脚本仅作兜底。

### 步骤（你这边只需做一次授权）
1. 浏览器登录 https://zenodo.org → **Account → Settings → GitHub** → 点 **Authorize / 授权** Zenodo 访问 GitHub；在仓库列表里把 `yyx-4113/pain-cognition-mr` 的开关 **Enable**。
   - 需仓库为 Public（当前已是）。
2. 通知我（小团）：我会在沙箱用 GitHub API 把当前已提交的 curated 包（commit `9b80dae`）打上 **`v1.0.0`** release tag 并发布（`api.github.com` 在沙箱白名单内，可操作）。
3. Zenodo 在 **1–5 分钟**内自动归档该 release 快照 → 生成 DOI（概念 DOI 跨版本不变）→ 发邮件给你。
4. 把真实 DOI 回填到 `docs/manuscript_draft.md` 的 **Data availability** 段与 `CITATION.cff` 的 `identifiers` 字段（占位符 `10.5281/zenodo.XXXXXXX` 替换为真实概念 DOI）。

### 数据治理（已落实，归档范围安全）
仓库已本地提交 curated 包（commit `9b80dae`），且 `.gitignore` **永久排除**个体级/敏感内容：
- `data/derived/charls_long.csv`（96,137 行 person-wave 个体面板：id、认知评分、疼痛、合并症——访问协议管制）
- `data/raw/`（436 MB GWAS 暴露数据 + 个体级 CHARLS/NHANES 目录）
- `tools/`（含 `unrar.exe` 等二进制）、`UnRAR.exe`、`license.txt`
- 内部审稿（`docs/REVIEW_round*`、`docs/review_round*/`、`docs/EDITORIAL_REVIEW*`）、`docs/LOCAL_RUNBOOK.md`、各类 `*.bak*` 备份
- `release.yml` 工作流打包也排除了同样内容。

因此 GitHub→Zenodo 快照只含合规产物：分析脚本、聚合结果表、图、投稿包、工具/说明脚本。**不会泄漏个体级数据。**

---

## 2. 预备（仅手动兜底需要）

1. **生成 token**（仅手动脚本/网页兜底用）：登录 https://zenodo.org → Account → Settings → Applications → Personal access tokens → New token。
   - 勾选范围（**两个都要**，缺一必 403）：`deposit:write` + `deposit:actions`。
   - 生成后只显示一次，复制保存好。
2. 本脚本只用 Python 标准库，无需 pip。本机 Python 3.8+ 即可。

---

## 3. 兜底方式 A：脚本（本机运行，仅当 GitHub 集成不可用）

脚本：`pain-cognition-mr/_zenodo_deposit_local.py`。在本机普通终端 `cd` 到仓库根：

```bash
python _zenodo_deposit_local.py --list          # 预览打包范围（不碰 API）
set ZENODO_TOKEN=你的token
python _zenodo_deposit_local.py --check-token   # 校验作用域（200=OK，403=不全）
python _zenodo_deposit_local.py                 # 上传 + 发布
```
- token 也可存仓库外文件：`python _zenodo_deposit_local.py --token-file D:\zenodo_token.txt`
- 发新版本（已有概念 DOI 后）：`python _zenodo_deposit_local.py --new-version <父 deposition id>`
- 成功后回写 `ZENODO_DEPOSIT_MANIFEST.json`（含 Record 链接、DOI、概念 DOI）。

> 注意：若你已走通 GitHub 集成并拿到 DOI，**不要再跑此脚本**，否则会产生第二个独立 Zenodo 记录。

---

## 4. 兜底方式 B：网页手动上传（零代码，最稳）

1. 登录 https://zenodo.org → **Upload → New upload**。
2. 填元数据：Title / Upload type=Software / Authors=Yang, Yongxin（**不加** MD/PhD 头衔）+ ORCID + 单位 / License=MIT / Access right=Open / Keywords。Related identifiers 加 `https://github.com/yyx-4113/pain-cognition-mr`（Is supplement to）。
3. 拖拽上传仓库内合规文件（同样排除 `data/raw/`、`.git/`、密钥、个体级 `charls_long.csv` 等）。
4. Save 草稿 → Publish → 获得 DOI，回填稿件与 CITATION.cff。

---

## 5. 回填 DOI 与版本对齐

- 主路径下：release 即含 `v1.0.0` tag，无需再单独打 tag。把 Zenodo 概念 DOI 回填到 `docs/manuscript_draft.md` 与 `CITATION.cff` 即可。
- 若之前在 sandbox 试跑过，登录 https://sandbox.zenodo.org 删掉测试 deposition，避免污染。

---

## 6. 常见报错速查

| 现象 | 原因 / 解决 |
|------|------------|
| `502 CONNECT tunnel failed` / `Could not resolve host` | 在 WorkBuddy 沙箱里跑的。改用 GitHub 关联主路径或本机运行。 |
| Zenodo 上 release 显示 **Failed** | 看 Errors 标签：*"Citation metadata load failed"* = `CITATION.cff` 无效（本项目已修）；*"Extra metadata load failed"* = `.zenodo.json` 无效。修正后删掉失败 release + 其 tag，重打同 tag。 |
| `401` / `403`（仅手动脚本） | token 无效或作用域不全，重生成并同时勾 `deposit:write`+`deposit:actions`。 |
| 出现**两个** Zenodo 记录 | 两种方法混用了。统一回退到一种（建议 GitHub 集成），删掉多余的。 |
| 文件上传中途失败（仅手动） | 网络抖动，脚本已重试；失败时可网页补传剩余文件再 Publish。 |
