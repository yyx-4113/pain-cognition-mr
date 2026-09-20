#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Build the Scientific Reports submission pack from manuscript_draft.md.

Outputs into ./_upload :
    Manuscript.docx              title page + unstructured abstract + IMRaD body
                                 + references + declarations + figure legends
    Cover_Letter.docx
    Supplementary_Information.docx
    STROBE-MR_checklist.docx
    figures/Fig1..Fig5.{pdf,png}

Every reported number is taken verbatim from docs/manuscript_draft.md (which
itself traces to data/derived/*.csv). No values are recomputed or invented.
"""
from __future__ import annotations
import os, re, shutil
from docx import Document
from docx.enum.section import WD_SECTION
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Cm, Pt, RGBColor
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
SRC  = os.path.join(ROOT, "docs", "manuscript_draft.md")
FIGS = os.path.join(ROOT, "docs", "figures")
OUT  = os.path.join(HERE, "_upload")
OUTF = os.path.join(OUT, "figures")
os.makedirs(OUTF, exist_ok=True)
BODY_FONT = "Times New Roman"

# --------------------------------------------------------------------------- #
# document helpers (journal-agnostic, Sci Rep flavour: TNR 11, 1.15 spacing)
# --------------------------------------------------------------------------- #
def new_document():
    doc = Document()
    n = doc.styles["Normal"]
    n.font.name = BODY_FONT
    n.font.size = Pt(11)
    n.element.rPr.rFonts.set(qn("w:eastAsia"), BODY_FONT)
    pf = n.paragraph_format
    pf.line_spacing = 1.15
    pf.space_after = Pt(0)
    for s in doc.sections:
        s.top_margin = s.bottom_margin = Cm(2.54)
        s.left_margin = s.right_margin = Cm(2.54)
        add_page_numbers(s)
    return doc

def add_page_numbers(section):
    p = section.footer.paragraphs[0]
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    run = p.add_run()
    fld = OxmlElement("w:fldSimple")
    fld.set(qn("w:instr"), "PAGE")
    run._r.addnext(fld)

def para(doc, text="", *, bold=False, italic=False, size=None, align=None,
         space_before=0, space_after=0, single=False):
    p = doc.add_paragraph()
    pf = p.paragraph_format
    if single:
        pf.line_spacing = 1.0
    pf.space_before = Pt(space_before)
    pf.space_after = Pt(space_after)
    if align is not None:
        p.alignment = align
    if text:
        add_runs(p, text, bold=bold, italic=italic, size=size)
    return p

INLINE = re.compile(r"(\*\*.+?\*\*|\*[^*\n]+?\*|`[^`\n]+?`)")
def add_runs(p, text, *, bold=False, italic=False, size=None):
    for piece in INLINE.split(text):
        if not piece:
            continue
        b, i, mono = bold, italic, False
        if piece.startswith("**") and piece.endswith("**") and len(piece) > 4:
            piece, b = piece[2:-2], True
        elif piece.startswith("*") and piece.endswith("*") and len(piece) > 2:
            piece, i = piece[1:-1], True
        elif piece.startswith("`") and piece.endswith("`") and len(piece) > 2:
            piece, mono = piece[1:-1], True
        run = p.add_run(piece)
        run.bold, run.italic = b, i
        if size:
            run.font.size = Pt(size)
        run.font.name = "Courier New" if mono else BODY_FONT

def is_table_row(line):
    return line.strip().startswith("|") and line.strip().endswith("|")
def is_separator(line):
    return bool(re.fullmatch(r"\|[\s:|-]+\|", line.strip()))
def cells(line):
    return [c.strip() for c in line.strip().strip("|").split("|")]

def emit_markdown(doc, block, *, table_size=9.0, drop=()):
    lines = block.split("\n")
    i = 0
    while i < len(lines):
        raw = lines[i]; line = raw.rstrip(); stripped = line.strip()
        if not stripped or stripped == "---":
            i += 1; continue
        if stripped.startswith(">"):
            i += 1; continue
        if any(stripped.startswith(d) for d in drop):
            i += 1; continue
        if is_table_row(line):
            rows = []
            while i < len(lines) and is_table_row(lines[i]):
                if not is_separator(lines[i]):
                    rows.append(cells(lines[i]))
                i += 1
            add_table(doc, rows, size=table_size)
            continue
        m = re.match(r"^(#{1,4})\s+(.*)$", stripped)
        if m:
            level, title = len(m.group(1)), m.group(2)
            if level == 1:
                para(doc, title, bold=True, size=14, space_after=6)
            else:
                para(doc, title, bold=True, size=12, space_before=8, space_after=4)
            i += 1; continue
        para(doc, stripped)
        i += 1

def add_table(doc, rows, *, size=9.0):
    if not rows:
        return
    width = max(len(r) for r in rows)
    t = doc.add_table(rows=0, cols=width)
    t.style = "Table Grid"
    t.alignment = WD_ALIGN_PARAGRAPH.CENTER
    t.autofit = True
    for ri, row in enumerate(rows):
        out = t.add_row().cells
        for ci in range(width):
            text = row[ci] if ci < len(row) else ""
            out[ci].text = ""
            p = out[ci].paragraphs[0]
            p.paragraph_format.line_spacing = 1.0
            p.paragraph_format.space_before = Pt(1)
            p.paragraph_format.space_after = Pt(1)
            add_runs(p, text, bold=(ri == 0), size=size)
        if ri == 0:
            trPr = t.rows[0]._tr.get_or_add_trPr()
            trPr.append(OxmlElement("w:tblHeader"))
    para(doc, "", single=True, space_after=4)

# --------------------------------------------------------------------------- #
# curated content (English, submission-ready)
# --------------------------------------------------------------------------- #
ABSTRACT = (
    "Chronic pain and cognitive impairment are rising ageing-related burdens. "
    "Observational links between multisite chronic pain (MCP) and cognitive decline are "
    "confounded by reverse causation and comorbidity. We used bidirectional two-sample "
    "MR to assess the association of genetically predicted MCP with cognitive outcomes. "
    "MCP instruments (51 SNPs; P<5×10⁻⁸) came from a UK Biobank GWAS (n=387,649). "
    "Outcomes were cognitive performance (UKB-derived, n=257,841), Alzheimer’s disease "
    "(IGAP ieu-a-297, n=54,162) and all-cause dementia (FinnGen, n=216,771). Genetically "
    "predicted MCP was associated with lower cognitive performance (IVW β=−0.361, 95% CI "
    "−0.424 to −0.299, p=3.65×10⁻³⁰) with high heterogeneity (I²≈83.5%) and no "
    "directional pleiotropy. The Steiger test was non-significant (p=0.23) and reverse MR "
    "significant (β=−0.171, p=8.85×10⁻⁵⁸), so direction is uncertain. A non-UKB "
    "overlap-robustness re-interpretation (IGAP AD: β=0.466, p=0.008) corroborated the "
    "association independently of UK Biobank sample overlap. No mediator was significant. "
    "Genetic evidence is compatible with an MCP–lower-cognition association, but the "
    "direction is unresolved and the cognitive result is limited by UKB sample overlap."
)

DECLARATIONS = [
    ("Author contributions",
     "Y.Y. conceived and designed the study, performed the statistical analyses, "
     "interpreted the results, and wrote the manuscript."),
    ("Competing interests",
     "The author declares no competing interests."),
    ("Data availability",
     "MR summary statistics are publicly available from the sources listed in the "
     "Methods (OpenGWAS/IEU, FinnGen, UK Biobank). NHANES data are available from the "
     "US CDC. CHARLS data are pending access approval (charls.pku.edu.cn). All derived "
     "analytic artifacts and analysis code are available at the project repository: "
     "https://github.com/yyx-4113/pain-cognition-mr."),
    ("Funding",
     "The author received no specific funding for this work."),
    ("Generative AI usage",
     "During manuscript preparation the author used a generative-AI research assistant "
     "(WorkBuddy) for editorial review, formatting, and figure-preparation support. "
     "The author reviewed and takes full responsibility for all content."),
    ("Ethics",
     "This study used only published summary-level statistics and public, de-identified "
     "datasets; individual consent was not required."),
]

REPORTING_NOTE = (
    "Reporting guidelines. This study is reported in accordance with the STROBE-MR 2021 "
    "statement (Skrivankova et al., JAMA 2021;326(16):1614-1621). The completed "
    "item-by-item compliance checklist is provided as Supplementary Material."
)

COVER = """# Cover Letter

**To:** The Editorial Board, *Scientific Reports* (Nature Portfolio)
**Date:** 20 September 2026
**Article type:** Article (original research)
**Running title:** Genetically predicted multisite chronic pain and cognitive performance

Dear Editorial Board,

We submit our original research article entitled *"Genetically predicted multisite chronic pain is associated with lower cognitive performance: a bidirectional Mendelian randomization study with NHANES contextual evidence"* for consideration as an Article in *Scientific Reports*.

**Significance and scope.** Chronic pain and cognitive impairment are two escalating, ageing-related public-health burdens. Observational links between multisite chronic pain (MCP) and cognitive decline are confounded by reverse causation and shared comorbidity. Using bidirectional two-sample Mendelian randomization (MR) with up to 51 independent genetic instruments for multisite chronic pain (MCP; UK Biobank, n=387,649), we estimate the effect of genetically predicted MCP on cognitive performance, Alzheimer's disease, and all-cause dementia, and probe the reverse direction and candidate mediators.

**Key findings.** Genetically predicted MCP was associated with lower cognitive performance (IVW β=−0.361, 95% CI −0.424 to −0.299, p=3.65×10⁻³⁰), with high heterogeneity (I²≈83.5%) but no directional pleiotropy. A non-significant Steiger test and a significant reverse MR left causal direction unresolved, and the cognitive result is limited by UK Biobank sample overlap between exposure and outcome. A non-UKB overlap-robustness re-interpretation (IGAP Alzheimer's disease: β=0.466, p=0.008) corroborated the association independently of this overlap. No mediator was significant. We report these results with explicit attention to their limitations rather than overstated causal claims.

**Why *Scientific Reports*.** As an open-access journal committed to rigorously peer-reviewed natural-science research of methodological soundness, *Scientific Reports* is well suited to a transparent, hypothesis-generating MR study that foregrounds its own constraints. The work conforms to the STROBE-MR 2021 reporting guideline (checklist enclosed).

**Declarations.** This is a single-author manuscript; the author confirms the work is original, not under consideration elsewhere, and approves submission. There are no competing interests. No specific funding was received. A generative-AI research assistant was used for editorial and formatting support, with full author responsibility for all content (disclosed in the manuscript). Data and code are publicly available at https://github.com/yyx-4113/pain-cognition-mr.

Thank you for considering our work. We look forward to your assessment.

Sincerely,

Yongxin Yang, B.M.
The Second Affiliated Hospital of Fujian University of Traditional Chinese Medicine,
Fuzhou, Fujian 350003, China.
ORCID: 0009-0004-9698-6552
"""

SI_MD = """# Supplementary Information

*Yang Y. Genetically predicted multisite chronic pain is associated with lower cognitive performance: a bidirectional Mendelian randomization study with NHANES contextual evidence.*

## S1. Non-UKB overlap-robustness sensitivity analysis

The primary MCP → cognitive-performance result is constrained by sample overlap between the MCP exposure (Johnston 2019, UK Biobank, n≈387,649) and the cognitive-performance outcome (ebi-a-GCST006572, UK Biobank-derived, n=257,841), both UKB-sourced. To examine whether the pain→cognitive-decline signal survives removal of this overlap, the same forward MR estimates were re-framed using two non-UKB disease outcomes that share no UKB samples with the MCP exposure: all-cause dementia (FinnGen, a Finnish national biobank) and Alzheimer's disease (IGAP 2013 consortium, ieu-a-297, n=54,162). No new instruments, harmonization, or data were introduced; only the overlap framing differs.

Methods replicate the local MR estimators in `analysis/_recompute_local.R` (weights w = 1/se_y²; IVW fixed- and random-effects; MR-Egger with intercept test for directional pleiotropy; weighted median via the delta method with exposure and outcome SEs; leave-one-out). Mean per-SNP F-statistic across the 41-43 harmonised SNPs was ≈33 (minimum ≈22), far above the weak-instrument threshold of 10.

| Exposure → outcome | Source | UKB overlap | n SNP | IVW β (95% CI) | p | Egger β (int p) | WMed β | I² | Direction |
|---|---|---|---:|---:|---:|---:|---:|---:|---|
| MCP → cognitive performance* | ebi-a-GCST006572 (UKB) | Yes | 41 | −0.361 (−0.424, −0.299) | 3.65×10⁻³⁰ | −0.362 (0.34) | −0.233 | 83.5% | Lower |
| MCP → all-cause dementia | FinnGen F5 (Finland) | No | 43 | 0.234 (−0.185, 0.653) | 0.27 | 0.209 (0.21) | 0.220 | 0% | Risk ↑ |
| MCP → Alzheimer's disease | IGAP ieu-a-297 (non-UKB) | No | 42 | 0.466 (0.123, 0.809) | 0.008 | 0.462 (0.86) | 0.227 | 16% | Risk ↑ |

*Cognitive-performance row: IVW β=−0.361 is the fixed-effect estimate (the headline value in the main manuscript); the random-effects IVW estimate is β=−0.403 (95% CI −0.550 to −0.257), p=3.65×10⁻³⁰.

Interpretation. All three outcomes point in the same direction (more multisite chronic pain → worse cognitive performance / higher dementia and AD risk). The IGAP AD estimate is significant (β=0.466, p=0.008) with no directional pleiotropy (Egger intercept p=0.86), low heterogeneity (I²≈16%), and stable leave-one-out estimates — a genuinely overlap-free corroboration. FinnGen all-cause dementia is non-significant (β=0.234, p=0.27), most plausibly reflecting the lower power of a binary trait with a smaller effective case sample rather than a true null. Note these non-UKB endpoints measure dementia/AD *risk*, not the cognitive-performance *score* itself; direct overlap-free confirmation at the cognitive-score level awaits a suitably powered non-UKB cognitive GWAS (e.g., COGENT) and overlap-corrected methods (MRlap).

## S2. Audit trail of derived artifacts

Every numerical result in the manuscript traces to a derived file under `data/derived/`:

- `mr_forward_results_corrected.csv` — forward MR (MCP → cognition / dementia / AD), corrected estimators.
- `mr_ad_reverse_results.csv` — reverse MR (cognition → MCP).
- `mr_mediation_results.csv` — two-step mediation MR (depression / CRP / insomnia).
- `mr_master_results.csv` — master results table.
- `mr_harmonized_cog.csv`, `mr_harmonized_dementia.csv`, `mr_harmonized_ad_igap2.csv` — harmonised exposure/outcome pairs.
- `mr_gwas_metadata_20260920.csv` — GWAS metadata (IDs, n, consortium, PMID).
- `mr_nonukb_sensitivity_results.csv` — non-UKB overlap-robustness sensitivity (Section S1).
- `nhanes_results_20260920.rds`, `data/raw/nhanes_clean.rds` — NHANES descriptive analysis.

Figures were generated reproducibly by `analysis/make_figures.py` (Fig. 1-4) and `analysis/make_nonukb_figure.py` (Fig. 5). All GWAS and method citations were verified (journal, volume, pages, DOI, PMID); the provenance discrepancy of ebi-a-GCST006572 (UKB-derived cognitive-performance score vs. the GWAS-Catalog's educational-attainment attribution) is disclosed in the Methods.
"""

# --------------------------------------------------------------------------- #
# figure renumbering (4->1, 5->2, 6->3, 7->4, 8->5) done on text; map files
# --------------------------------------------------------------------------- #
FIG_MAP = {
    "fig_forest":        ("Fig1_forest",  "Forest plot of MR estimates"),
    "fig_scatter":       ("Fig2_scatter", "SNP-level scatter (MCP → cognition)"),
    "fig_loo":           ("Fig3_loo",     "Leave-one-out sensitivity"),
    "fig_funnel":        ("Fig4_funnel",  "Funnel plot of per-SNP Wald ratios"),
    "fig_nonukb_sensitivity": ("Fig5_nonukb", "Non-UKB overlap-robustness re-interpretation"),
}

def renumber(text):
    # single-pass mapping so "Figure 8"->"Figure 5" is never re-mapped by "Figure 5"->"Figure 2"
    _map = {4: 1, 5: 2, 6: 3, 7: 4, 8: 5}
    return re.sub(r"Figure (\d)",
                  lambda m: "Figure %d" % _map.get(int(m.group(1)), int(m.group(1))),
                  text)

# --------------------------------------------------------------------------- #
# build
# --------------------------------------------------------------------------- #
def build_manuscript(text):
    doc = new_document()
    emit_markdown(doc, text[:text.index("## 1. Introduction")])
    doc.add_page_break()
    intro = text.index("## 1. Introduction")
    strobe = text.index("## 6. STROBE-MR compliance")
    refs = text.index("## References")
    audit = text.index("## 7. Audit trail")
    legends = text.index("## 8. Figure captions")
    emit_markdown(doc, text[intro:strobe])        # body IMRaD
    emit_markdown(doc, text[refs:audit])          # references
    for label, txt in DECLARATIONS:               # declarations
        p = doc.add_paragraph()
        r = p.add_run(label + ". ")
        r.bold = True
        add_runs(p, txt)
        p.paragraph_format.space_before = Pt(6)
    emit_markdown(doc, "## Reporting guidelines\n\n" + REPORTING_NOTE)
    emit_markdown(doc, text[legends:])            # figure legends
    path = os.path.join(OUT, "Manuscript.docx")
    doc.save(path)
    return path

def build_cover():
    doc = new_document()
    emit_markdown(doc, COVER)
    path = os.path.join(OUT, "Cover_Letter.docx")
    doc.save(path)
    return path

def build_si():
    doc = new_document()
    emit_markdown(doc, SI_MD, table_size=8.0)
    path = os.path.join(OUT, "Supplementary_Information.docx")
    doc.save(path)
    return path

def build_checklist():
    md = open(os.path.join(ROOT, "docs", "strobe_mr_checklist.md"), encoding="utf-8").read()
    md = re.sub(r"## Summary for version B.*$", "", md, flags=re.S)
    md = re.sub(r"\*\*Status legend:.*$", "", md)
    md = md.replace("⛔", "[Pending data]").replace("🟡", "[Partial]").replace("✅", "[Addressed]")
    md = renumber(md)
    doc = new_document()
    emit_markdown(doc, md, table_size=8.0)
    path = os.path.join(OUT, "STROBE-MR_checklist.docx")
    doc.save(path)
    return path

def copy_figures():
    copied = []
    for stem, (newstem, _desc) in FIG_MAP.items():
        for ext in ("pdf", "png"):
            src = os.path.join(FIGS, f"{stem}.{ext}")
            if os.path.exists(src):
                dst = os.path.join(OUTF, f"{newstem}.{ext}")
                shutil.copyfile(src, dst)
                copied.append(dst)
        png = os.path.join(FIGS, f"{stem}.png")
        pdf = os.path.join(OUTF, f"{newstem}.pdf")
        if os.path.exists(png) and not os.path.exists(pdf):
            Image.open(png).save(pdf, "PDF", resolution=300.0)
            copied.append(pdf)
    return copied

def main():
    raw = open(SRC, encoding="utf-8").read()
    parts = raw.split("\n---\n", 1)
    body = parts[1] if len(parts) == 2 else raw
    body = renumber(body)
    body = re.sub(r"## Abstract\n.*?\n---\n", "## Abstract\n\n" + ABSTRACT + "\n\n---\n",
                  body, flags=re.S)
    bad = re.findall(r"[\u4e00-\u9fff]+", body)
    if bad:
        print("ABORT: Chinese in manuscript source:", sorted(set(bad))[:10])
        return 1
    paths = [build_manuscript(body), build_cover(), build_si(), build_checklist()]
    paths += copy_figures()
    print("built:")
    for p in paths:
        print(f"  {os.path.relpath(p, HERE):50s} {os.path.getsize(p)/1024:8.1f} KB")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
