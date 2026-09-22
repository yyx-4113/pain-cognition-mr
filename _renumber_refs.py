import re, io

path = r"D:/2026.9/极速交付9月会员日优惠套路/03_观察性研究+孟德尔随机化双验证/孟德尔疼痛/pain-cognition-mr/docs/manuscript_draft.md"
with io.open(path, encoding="utf-8") as f:
    text = f.read()

# existing references 2..21 are shifted to 6..25 (Tian [1] stays)
m = {n: n + 4 for n in range(2, 22)}

# 1) in-text citations [N] everywhere (single pass; no cascading)
def repl(mo):
    n = int(mo.group(1))
    return "[%d]" % m.get(n, n)
text = re.sub(r"\[(\d+)\]", repl, text)

# 2) reference-list entry labels "N. " only AFTER the "## References" header
idx = text.find("## References")
if idx == -1:
    raise SystemExit("References header not found")
head = text[:idx]
tail = text[idx:]
def repl_list(mo):
    n = int(mo.group(1))
    return "%d. " % m.get(n, n)
tail = re.sub(r"^(\d+)\. ", repl_list, tail, flags=re.M)
text = head + tail

with io.open(path, "w", encoding="utf-8") as f:
    f.write(text)

# report
import collections
after = collections.Counter(re.findall(r"\[(\d+)\]", text))
print("in-text citation max token:", max(int(k) for k in after))
print("done")
