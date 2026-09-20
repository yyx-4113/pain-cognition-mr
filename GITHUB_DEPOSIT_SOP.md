# GitHub 仓库发布与归档操作手册（中文）

适用仓库：`pain-cognition-mr`（复现包）
作者：Yongxin Yang ｜ GitHub：`yyx-4113`

## 一、首次创建仓库
1. 登录 GitHub，点 **New repository**。
2. Repository name 用 kebab-case：`pain-cognition-mr`。
3. 可见性选 **Public**（便于期刊审稿与数据可用性声明引用实名 URL）。
4. 不勾选自动生成 README（本仓库已自带）。
5. 本地仓库根目录即本复现包，推送：
   ```bash
   git init
   git add -A
   git commit -m "init: pain-cognition-mr reproduction package"
   git branch -M main
   git remote add origin https://github.com/yyx-4113/pain-cognition-mr.git
   git push -u origin main
   ```

## 二、版本与 Release
- 每个稿件轮次对应一个 git tag，格式 `vX.Y.Z`（与稿件版本标签一致）。
- 打 tag 即触发 `.github/workflows/release.yml`，自动打包（排除 `data/raw/`）并上传 artifact。
- 发布 Release 后，把 **实名仓库 URL** 写进稿件 Data availability 声明，禁止写 "available on request"。

## 三、敏感与合规
- `data/raw/` 含 CHARLS / NHANES 个体级数据，**严禁提交**（已写入 `.gitignore` 思路：本仓库约定不纳入 raw）。
- 不在仓库、commit message、issue 中写入 OpenGWAS JWT 令牌；令牌仅在本地 `.Renviron` 或环境变量配置。
- 作者署名头衔只写姓名，不附 MD / PhD 等研究生以上学位（作者仅为医学学士）。

## 四、长期维护
- 每完成一轮修订，commit 并打新 tag，保持 `CITATION.cff` 与稿件版本同步。
- 若 GWAS accession 有更新（如 CRP 的 GCST 编号确认），同步更新 `docs/gwas_catalog.md` 并追加 changelog。
