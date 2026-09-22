#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
_zenodo_deposit_local.py
========================
本机直连上传脚本 —— 用于把 pain-cognition-mr 复现包归档到 Zenodo 并拿到 DOI。

【为什么需要本脚本 / 为什么之前每次卡住】
  WorkBuddy 的 Agent 沙箱环境对 zenodo.org 返回 "502 CONNECT tunnel failed"，
  且无直连 DNS，因此**在沙箱内任何上传尝试都会卡死或失败**。
  Zenodo 上传必须在你自己的电脑（直连互联网）上运行本脚本，或在 zenodo.org 网页手动上传。
  本脚本只用 Python 标准库，无需 pip 安装任何包。

【前置条件】
  1. 在 https://zenodo.org/account/settings/applications/ 生成 Personal access token，
     必须**同时勾选** `deposit:write`（创建/上传）与 `deposit:actions`（发布），否则对应步骤报 403。
  2. 本机可直连 https://zenodo.org （公司代理若拦截 zenodo.org，请先放行或换网络）。
  3. 建议先用 --sandbox 在 https://sandbox.zenodo.org 试跑一遍（用 sandbox 的 token），确认流程无误再上生产。

【用法】
  # 1) 只列出将要打包的文件 + 元数据，不碰 API（先检查打包范围对不对）
  python _zenodo_deposit_local.py --list

  # 2) 校验 token 作用域是否够（创建 1 条测试查询，不建 deposition）
  python _zenodo_deposit_local.py --check-token
  #   生产：
  python _zenodo_deposit_local.py
  #   测试环境（sandbox）：
  python _zenodo_deposit_local.py --sandbox

  # 3) 若该复现包已有概念 DOI（之前传过一版），发新版本而不是新建：
  python _zenodo_deposit_local.py --new-version <父 deposition 的 id>

  token 读取优先级（避免每次手贴）：
    a) 环境变量 ZENODO_TOKEN        （推荐：在普通终端里 `set ZENODO_TOKEN=xxx` 后运行）
    b) --token-file <路径>           （token 存到仓库外的文本文件，如 D:/zenodo_token.txt）
    c) 运行时隐藏输入粘贴            （getpass，普通终端可用）
  注意：token 切勿写进仓库、聊天或命令行明文历史。

退出码：0 成功；非 0 失败（并打印可操作的中文报错）。
"""

import os
import sys
import json
import time
import base64
import getpass
import urllib.request
import urllib.error
import urllib.parse

# --------------------------------------------------------------------------- #
# 配置
# --------------------------------------------------------------------------- #
PROD_BASE = "https://zenodo.org/api"
SANDBOX_BASE = "https://sandbox.zenodo.org/api"

# 脚本位于仓库根目录（pain-cognition-mr/），以此为打包根
REPO_ROOT = os.path.dirname(os.path.abspath(__file__))

# 上传后回写的产物清单（可选，便于审计）
MANIFEST_OUT = os.path.join(REPO_ROOT, "ZENODO_DEPOSIT_MANIFEST.json")

# 元数据（按需修改；注意：作者名**不要**带 MD/PhD 等头衔）
# 稿件 DOI 占位符待正式接收后再替换；未接收时先删掉那条 related_identifier。
METADATA = {
    "upload_type": "software",
    "publication_date": "2026-09-22",
    "version": "v1.0.0",
    "title": ("pain-cognition-mr: reproducibility package for Mendelian randomization "
              "of multisite chronic pain and cognitive performance"),
    "creators": [
        {
            "name": "Yang, Yongxin",
            "affiliation": "The Second Affiliated Hospital of Fujian University of Traditional Chinese Medicine",
            "orcid": "0009-0004-9698-6552",
        }
    ],
    "description": (
        "Reproducibility package accompanying a single-author Mendelian randomization study on the "
        "causal association between genetically predicted multisite chronic pain (MCP) and cognitive "
        "performance, with cross-cohort corroboration from CHARLS (China) and descriptive context from "
        "NHANES (USA). Contains: (1) all analysis scripts (R and Python) for the two-sample MR, "
        "overlap-bias sensitivity, CHARLS longitudinal/LMM/Cox/RCS modelling, NHANES descriptive "
        "analysis, and figure generation; (2) derived analytic artifacts (CSV tables and key RDS "
        "objects) that every number in the manuscript traces to; (3) the manuscript draft, "
        "statistical analysis plan (SAP), STROBE-MR checklist, and supplementary note. Raw "
        "individual-level CHARLS/NHANES and GWAS summary statistics are access-agreement governed "
        "and are NOT included; they are cited with their public sources. Released under the MIT licence."
    ),
    "access_right": "open",
    "license": "mit",
    "keywords": [
        "Mendelian randomization",
        "chronic pain",
        "cognitive performance",
        "UK Biobank",
        "CHARLS",
        "NHANES",
        "reproducibility",
    ],
    "related_identifiers": [
        {"relation": "isSupplementTo",
         "identifier": "https://github.com/yyx-4113/pain-cognition-mr"},
        # 稿件正式接收并拿到 DOI 后，取消下一行注释并替换为真实 DOI：
        # {"relation": "isSupplementTo", "identifier": "https://doi.org/10.1038/s41598-0xxxxxxx"},
    ],
}

# 打包排除规则（相对仓库根的路径）
EXCLUDE_DIRS = {
    ".git", ".workbuddy", "data/raw", "__pycache__",
    "2询问", "xin",
    "docs/review_round4", "docs/review_round5",
    "docs/review_round6_20260922", "docs/review_round7_20260922",
    "docs/review_round8_20260922",
}
EXCLUDE_FILES_EXACT = {
    "STATUS.md", "JWT.txt", ".env", ".Renviron",
    "UnRAR.exe", "license.txt", "manuscript_draft.bak_20260922.md",
    "mr_bidirectional_results.csv",  # 已废弃/与正向结果矛盾的游离文件，不进公开包
}
EXCLUDE_SUFFIXES = (".stats.gz", ".bak_20260922.md", ".log", ".pyc", ".tmp")
EXCLUDE_PATH_PREFIX = ("analysis/_", "data/derived/_")
MAX_FILE_BYTES = 200 * 1024 * 1024  # 单文件上限 200MB（Zenodo 实际 50GB，留余量）


# --------------------------------------------------------------------------- #
# 打包
# --------------------------------------------------------------------------- #
def collect_files():
    files = []
    for dirpath, dirnames, filenames in os.walk(REPO_ROOT):
        rel_dir = os.path.relpath(dirpath, REPO_ROOT).replace(os.sep, "/")
        # 剪枝：整目录排除
        keep_dirs = []
        for d in dirnames:
            rel = (rel_dir + "/" + d) if rel_dir != "." else d
            if rel in EXCLUDE_DIRS or d in EXCLUDE_DIRS:
                continue
            keep_dirs.append(d)
        dirnames[:] = keep_dirs
        for fn in filenames:
            rel = (rel_dir + "/" + fn) if rel_dir != "." else fn
            if fn in EXCLUDE_FILES_EXACT:
                continue
            if rel in EXCLUDE_DIRS:
                continue
            if rel.startswith(EXCLUDE_PATH_PREFIX):
                continue
            # 备份文件（含 .rds.bak_20260922 这类非标准后缀的备份）
            if ".bak" in fn:
                continue
            # 内部审稿 / 编辑评审 / 本地运行手册：不进公开复现包
            if (rel.startswith("docs/REVIEW_round")
                    or rel.startswith("docs/EDITORIAL_REVIEW")
                    or rel == "docs/LOCAL_RUNBOOK.md"):
                continue
            if fn.endswith(EXCLUDE_SUFFIXES):
                continue
            full = os.path.join(dirpath, fn)
            try:
                sz = os.path.getsize(full)
            except OSError:
                continue
            if sz > MAX_FILE_BYTES:
                print(f"  [跳过] 超过单文件上限: {rel} ({sz/1024/1024:.1f} MB)")
                continue
            files.append((rel, full, sz))
    files.sort()
    return files


# --------------------------------------------------------------------------- #
# Zenodo HTTP 封装
# --------------------------------------------------------------------------- #
def api_call(base, path, token, method="GET", data=None, headers=None,
             timeout=120, retries=3):
    url = base + path
    if "?" in url:
        url += "&access_token=" + token
    else:
        url += "?access_token=" + token
    last_err = None
    for attempt in range(1, retries + 1):
        try:
            req = urllib.request.Request(url, data=data, method=method)
            if headers:
                for k, v in headers.items():
                    req.add_header(k, v)
            with urllib.request.urlopen(req, timeout=timeout) as resp:
                body = resp.read().decode("utf-8", "replace")
                return resp.status, body
        except urllib.error.HTTPError as e:
            body = e.read().decode("utf-8", "replace")
            return e.code, body
        except (urllib.error.URLError, OSError, TimeoutError) as e:
            last_err = e
            if attempt < retries:
                print(f"    [重试 {attempt}/{retries}] 网络错误: {e}")
                time.sleep(3 * attempt)
                continue
            raise
    if last_err:
        raise last_err


def create_deposition(base, token):
    status, body = api_call(base, "/deposit/depositions", token,
                            method="POST",
                            data=json.dumps({"metadata": METADATA}).encode("utf-8"),
                            headers={"Content-Type": "application/json"},
                            timeout=60)
    if status not in (200, 201):
        fail(f"创建 deposition 失败 (HTTP {status}):\n{body}", scope_hint=True)
    return json.loads(body)


def new_version(base, token, parent_id):
    status, body = api_call(
        base, f"/deposit/depositions/{parent_id}/actions/newversion",
        token, method="POST", timeout=60)
    if status not in (200, 201):
        fail(f"创建新版本失败 (HTTP {status}):\n{body}", scope_hint=True)
    draft = json.loads(body)
    # newversion 返回中含 links.latest_draft
    latest = draft.get("links", {}).get("latest_draft")
    if not latest:
        fail("newversion 响应缺少 latest_draft 链接，无法继续。")
    st, bd = api_call(latest, "", token, method="GET", timeout=60)
    if st != 200:
        fail(f"获取新版本草稿失败 (HTTP {st}):\n{bd}")
    return json.loads(bd)


def upload_file_via_bucket(bucket_url, token, rel, full, timeout=600):
    # 优先用 bucket PUT（单文件流式，支持大文件）
    url = bucket_url.rstrip("/") + "/" + urllib.parse.quote(rel)
    if "?" in url:
        url += "&access_token=" + token
    else:
        url += "?access_token=" + token
    last_err = None
    for attempt in range(1, 4):
        try:
            with open(full, "rb") as fh:
                req = urllib.request.Request(url, data=fh, method="PUT")
                req.add_header("Content-Type", "application/octet-stream")
                with urllib.request.urlopen(req, timeout=timeout) as resp:
                    return resp.status, resp.read().decode("utf-8", "replace")
        except urllib.error.HTTPError as e:
            return e.code, e.read().decode("utf-8", "replace")
        except (urllib.error.URLError, OSError, TimeoutError) as e:
            last_err = e
            print(f"    [重试 {attempt}/3] 上传 '{rel}' 网络错误: {e}")
            time.sleep(5 * attempt)
    if last_err:
        raise last_err


def upload_file_legacy(files_url, token, rel, full, timeout=600):
    # bucket 不可用时的兜底：multipart 上传（手动构造边界）
    import uuid
    boundary = "----zenodo%s" % uuid.uuid4().hex
    fname = os.path.basename(rel)
    with open(full, "rb") as fh:
        payload = fh.read()
    crlf = b"\r\n"
    body = (b"--" + boundary.encode() + crlf
            + ('Content-Disposition: form-data; name="file"; filename="%s"'
               % fname).encode() + crlf
            + b"Content-Type: application/octet-stream" + crlf + crlf
            + payload + crlf
            + b"--" + boundary.encode() + b"--" + crlf)
    url = files_url.rstrip("/")
    if "?" in url:
        url += "&access_token=" + token
    else:
        url += "?access_token=" + token
    req = urllib.request.Request(url, data=body, method="POST")
    req.add_header("Content-Type", "multipart/form-data; boundary=%s" % boundary)
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        return resp.status, resp.read().decode("utf-8", "replace")


def publish(base, token, deposition):
    pub_url = deposition.get("links", {}).get("actions", {}).get("publish")
    if not pub_url:
        # 兜底：用标准路径
        pub_url = base + f"/deposit/depositions/{deposition['id']}/actions/publish"
    status, body = api_call(pub_url, "", token, method="POST", timeout=60)
    if status not in (200, 201, 202):
        fail(f"发布失败 (HTTP {status}):\n{body}", scope_hint=True)
    return json.loads(body)


# --------------------------------------------------------------------------- #
# 工具
# --------------------------------------------------------------------------- #
def fail(msg, scope_hint=False):
    print("\n❌ 失败：", file=sys.stderr)
    print(msg, file=sys.stderr)
    if scope_hint:
        print("\n[常见原因] token 无效或作用域不足：必须在 zenodo.org 的 "
              "Personal access token 设置里**同时勾选** `deposit:write` 与 "
              "`deposit:actions`（只勾其一会在创建/发布步骤报 403）。", file=sys.stderr)
        print("[网络] 若提示无法连接 zenodo.org，请确认本机直连互联网；"
              "不要从 WorkBuddy Agent 沙箱运行（沙箱代理对 zenodo.org 返回 502）。",
              file=sys.stderr)
    sys.exit(1)


def human(n):
    return f"{n/1024/1024:.2f} MB" if n >= 1024 * 1024 else f"{n/1024:.1f} KB"


# --------------------------------------------------------------------------- #
# 主流程
# --------------------------------------------------------------------------- #
def main():
    args = sys.argv[1:]
    use_sandbox = "--sandbox" in args
    do_list = "--list" in args
    do_check = "--check-token" in args
    new_ver = None
    for i, a in enumerate(args):
        if a == "--new-version" and i + 1 < len(args):
            new_ver = args[i + 1]

    base = SANDBOX_BASE if use_sandbox else PROD_BASE
    print(f"[环境] API base = {base}  "
          f"({'SANDBOX 测试' if use_sandbox else '生产 zenodo.org'})")

    files = collect_files()
    total = sum(s for _, _, s in files)
    print(f"[打包] 共 {len(files)} 个文件，合计 {human(total)}")
    if do_list:
        for rel, _, sz in files:
            print(f"  {human(sz):>10}  {rel}")
        print("\n[元数据预览]")
        print(json.dumps(METADATA, ensure_ascii=False, indent=2))
        print("\n（--list 模式：未调用任何 API，未上传。）")
        return

    if not do_check and not new_ver:
        ans = input("确认创建新 deposition 并上传以上文件？(yes/no) ").strip().lower()
        if ans not in ("yes", "y"):
            print("已取消。")
            return

    token = os.environ.get("ZENODO_TOKEN", "").strip()
    if not token and "--token-file" in args:
        tfi = args[args.index("--token-file") + 1]
        try:
            with open(tfi, "r", encoding="utf-8") as fh:
                token = fh.read().strip()
        except OSError as e:
            fail(f"读取 token 文件失败: {e}")
    if not token:
        # 普通终端里 getpass 可正常隐藏输入；非交互环境会失败，此时改用明文输入兜底
        try:
            token = getpass.getpass("粘贴 Zenodo Personal access token（输入不显示）: ").strip()
        except (EOFError, OSError):
            token = input("粘贴 Zenodo Personal access token: ").strip()
    if not token:
        fail("未提供 token。可设环境变量 ZENODO_TOKEN，或用 --token-file <路径>。")

    # 预检 token 作用域
    if do_check:
        st, bd = api_call(base, "/deposit/depositions?size=1", token,
                          method="GET", timeout=30)
        if st == 200:
            print("✅ token 有效且具备 deposit:write 作用域。")
        elif st in (401, 403):
            fail(f"token 无效或作用域不足 (HTTP {st})。", scope_hint=True)
        else:
            fail(f"token 校验返回意外状态 (HTTP {st}):\n{bd}")
        return

    # 1) 建 deposition（或新版本）
    if new_ver:
        print(f"[1/3] 为父 deposition {new_ver} 创建新版本 ...")
        dep = new_version(base, token, new_ver)
    else:
        print("[1/3] 创建 deposition ...")
        dep = create_deposition(base, token)
    dep_id = dep["id"]
    links = dep.get("links", {})
    bucket = links.get("bucket")
    files_url = links.get("files")
    print(f"      deposition id = {dep_id}")

    # 2) 上传文件
    print(f"[2/3] 上传 {len(files)} 个文件 ...")
    uploaded = []
    for idx, (rel, full, sz) in enumerate(files, 1):
        sys.stdout.write(f"  ({idx}/{len(files)}) {rel}  {human(sz)} ... ")
        sys.stdout.flush()
        status = None
        if bucket:
            try:
                status, _ = upload_file_via_bucket(bucket, token, rel, full)
            except Exception as e:
                status = None
                print(f"\n    bucket 上传异常: {e}")
        if status not in (200, 201) and files_url:
            status, _ = upload_file_legacy(files_url, token, rel, full)
        if status in (200, 201):
            print("OK")
            uploaded.append(rel)
        else:
            print(f"失败(HTTP {status})")
            fail(f"文件上传失败：{rel}（HTTP {status}）。"
                 f"已上传 {len(uploaded)}/{len(files)} 个；"
                 f"可在 zenodo.org 的该 deposition 页面手动补传剩余文件后再 Publish。",
                 scope_hint=True)

    # 3) 发布
    print("[3/3] 发布（Publish）...")
    published = publish(base, token, dep)
    meta = published.get("metadata", {})
    doi = meta.get("doi") or published.get("doi")
    rec = published.get("links", {}).get("record")
    concept = published.get("links", {}).get("conceptdoi") or meta.get("conceptdoi")
    print("\n✅ 发布成功！")
    print(f"  Record:    {rec}")
    print(f"  DOI:       {doi}")
    print(f"  概念 DOI:  {concept}  （跨版本不变，引用此号）")

    # 回写清单
    manifest = {
        "base": base, "deposition_id": dep_id,
        "doi": doi, "concept_doi": concept, "record": rec,
        "uploaded_files": uploaded, "total_bytes": total,
    }
    try:
        with open(MANIFEST_OUT, "w", encoding="utf-8") as fh:
            json.dump(manifest, fh, ensure_ascii=False, indent=2)
        print(f"  清单已写入: {MANIFEST_OUT}")
    except OSError:
        pass


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n已中断。")
        sys.exit(130)
    except SystemExit:
        raise
    except Exception as e:  # 任何未预期错误都给可操作提示
        print(f"\n❌ 未预期错误: {e}", file=sys.stderr)
        print("若提示无法连接 zenodo.org / Could not resolve host / 502："
              "你正位于无法直连 Zenodo 的网络（如 WorkBuddy 沙箱或受限代理）。"
              "请在能直连互联网的电脑上运行本脚本，或改用 zenodo.org 网页手动上传。",
              file=sys.stderr)
        sys.exit(1)
