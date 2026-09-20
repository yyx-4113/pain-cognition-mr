#!/usr/bin/env python3
"""
Fetch authoritative OpenGWAS gwasinfo metadata via the v4 REST API and write a
dated CSV snapshot. This is the network-executed equivalent of
`03_mr_pain_cognition.R --metadata-only` (which relies on TwoSampleMR's
gwasinfo()). We call the live v4 endpoint directly because:
  - the legacy gwas-api.mrcieu.ac.uk host is unreachable from some networks,
  - v4 routes moved to https://api.opengwas.io/api (POST /gwasinfo?id=...).

JWT is read from JWT.txt (never printed). Output: data/derived/mr_gwas_metadata_YYYYMMDD.csv
"""
import csv, json, os, sys, urllib.request, urllib.parse, datetime

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
# JWT.txt may live in pain-cognition-mr/ or its parent project dir; search upward.
def find_jwt(start):
    d = start
    for _ in range(4):
        cand = os.path.join(d, "JWT.txt")
        if os.path.exists(cand):
            return cand
        parent = os.path.dirname(d)
        if parent == d:
            break
        d = parent
    return None
RAW_JWT = find_jwt(ROOT)
OUT_DIR = os.path.join(ROOT, "data", "derived")
os.makedirs(OUT_DIR, exist_ok=True)

# OpenGWAS IDs verified in docs/gwas_catalog.md (MCP & CWP are local files, excluded)
IDS = [
    # exposure: UKB pain phenotypes (sensitivity/replication)
    "ukb-b-8463", "ukb-b-8906", "ukb-b-13092", "ukb-b-16118",
    "ukb-b-133", "ukb-b-19097", "ukb-d-2956", "ukb-d-4067",
    # cognitive outcomes
    "ebi-a-GCST006572", "ebi-a-GCST006250", "ieu-a-16",
    # AD / dementia
    "ieu-a-298", "ieu-a-297", "ieu-b-2", "ieu-b-5067", "finn-b-F5_DEMENTIA",
    # mediators
    "ieu-b-102", "ebi-a-GCST90029070", "ukb-b-3957", "ukb-b-4424", "ieu-a-1088",
    # MVMR covariates
    "ieu-a-755", "ieu-b-4877", "ukb-b-19953",
]

def main():
    try:
        with open(RAW_JWT, "r", encoding="utf-8") as f:
            token = f.read().strip()
    except FileNotFoundError:
        sys.exit("JWT.txt not found at " + RAW_JWT)
    if not token:
        sys.exit("JWT.txt is empty.")

    url = "https://api.opengwas.io/api/gwasinfo"
    data = urllib.parse.urlencode([("id", i) for i in IDS]).encode()
    req = urllib.request.Request(url, data=data, method="POST")
    req.add_header("Authorization", "Bearer " + token)
    req.add_header("Content-Type", "application/x-www-form-urlencoded")
    req.add_header("User-Agent", "pain-cognition-mr-metadata-fetch/1.0")
    try:
        with urllib.request.urlopen(req, timeout=60) as resp:
            payload = json.loads(resp.read().decode())
    except Exception as e:
        sys.exit("API request failed: " + str(e))

    rows = payload if isinstance(payload, list) else payload.get("results", [payload])
    # preserve the requested order
    by_id = {r.get("id"): r for r in rows}

    cols = ["id", "trait", "build", "population", "sex", "author", "year",
            "consortium", "pmid", "sample_size", "ncase", "ncontrol", "nsnp",
            "category", "unit", "mr", "note"]
    date_tag = datetime.date.today().strftime("%Y%m%d")
    out_csv = os.path.join(OUT_DIR, f"mr_gwas_metadata_{date_tag}.csv")

    # local-file exposures (not in OpenGWAS) appended as documented rows
    local_rows = [
        {"id": "MCP_Johnston2019", "trait": "Multisite chronic pain (local file)",
         "build": "NA", "population": "European (UKB)", "sex": "NA",
         "author": "Johnston KJA", "year": 2019, "consortium": "NA",
         "pmid": 31194737, "sample_size": 387649, "ncase": "", "ncontrol": "",
         "nsnp": "NA", "category": "Continuous", "unit": "sites count",
         "mr": 0, "note": "NOT IN OPENGWAS; local file chronic_pain-bgen.stats.gz (DOI 10.5525/gla.researchdata.822)"},
        {"id": "CWP_Rahman2021", "trait": "Chronic widespread pain (local file)",
         "build": "NA", "population": "European (UKB)", "sex": "NA",
         "author": "Rahman MS", "year": 2021, "consortium": "NA",
         "pmid": 33926923, "sample_size": 249843, "ncase": 6914, "ncontrol": 242929,
         "nsnp": "NA", "category": "Binary", "unit": "NA",
         "mr": 0, "note": "NOT IN OPENGWAS; GCST011779 fullPvalueSet=false; KP4CD/Rahman2021_Chronic_Widespead_MSK_Pain_EU"},
    ]

    found = [i for i in IDS if i in by_id]
    missing = [i for i in IDS if i not in by_id]
    with open(out_csv, "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=cols)
        w.writeheader()
        for i in IDS:
            r = by_id.get(i, {})
            w.writerow({c: r.get(c, "") for c in cols})
        for r in local_rows:
            w.writerow({c: r.get(c, "") for c in cols})

    print(f"OK wrote {out_csv}")
    print(f"queried={len(IDS)} found_in_opengwas={len(found)} missing={len(missing)}")
    if missing:
        print("MISSING: " + ", ".join(missing))
    # quick summary line for the user (no token leaked)
    print("sample of returned metadata:")
    for i in ["ebi-a-GCST006572", "ukb-b-8463", "ebi-a-GCST90029070", "ukb-b-19953"]:
        r = by_id.get(i)
        if r:
            print(f"  {i}: {r.get('trait')} | n={r.get('sample_size')} | nsnp={r.get('nsnp')} | year={r.get('year')}")

if __name__ == "__main__":
    main()
