#!/usr/bin/env python3
"""Build the WP5 financial-mechanism KB (v2) from the FINAL D5.2 tables.

Stage 1 (refresh; needs the WP5 source documents):
    micromamba run -n shiny python -I scripts/build_wp5_mechanisms_kb.py --refresh-extract --wp5-dir <.../MarineSABRES_SES_Shiny/WP5> [--accept-new-sources] [--pdftotext PATH]
  Runs pandoc on the pinned D5.2 Draftv5 docx and the Blue Corridor toolkit docx,
  cuts Tables 9/20/22, toolkit Annex Table 2 + core references and the scenario
  headings, verifies each mechanism name inside its own table region of the
  FINAL v5 PDF (xpdf pdftotext), pins sha256s + tool versions, and writes the
  committed extract scripts/wp5_kb_sources/d5.2_v5_mechanism_sources.md.
  Refuses to overwrite a pinned extract whose source hashes changed unless
  --accept-new-sources is given.

Stage 2 (default; CI-safe): parses ONLY the committed extract and writes
data/ses_knowledge_db_wp5_mechanisms.json, byte-stable (last_updated comes from
the extract header).

DO NOT hand-edit the JSON or the extract.
"""

import argparse
import hashlib
import json
import re
import shutil
import subprocess
import sys
from datetime import date
from pathlib import Path

APP_ROOT = Path(__file__).resolve().parents[1]
EXTRACT_PATH = APP_ROOT / "scripts" / "wp5_kb_sources" / "d5.2_v5_mechanism_sources.md"
OUT_PATH = APP_ROOT / "data" / "ses_knowledge_db_wp5_mechanisms.json"
PDFTOTEXT_FALLBACK = r"C:\Program Files\Git\mingw64\bin\pdftotext.exe"

SOURCE_FILES = {
    "draftv5": "D5.2/MarineSABRES_Deliverable5.2_Draftv5.docx",
    "toolkit": "Blue_corridor_financial toolkit_17_04_2026.docx",
    "final_pdf": "D5.2/MarineSABRES_D5.2_Final.pdf",
}
PIN_KEYS = ["draftv5_sha256", "toolkit_sha256", "final_pdf_sha256"]

SECTIONS = [
    ("table9_arctic", "draftv5", r"^\*Table 9\. Suggested financial mechanisms", r"^Financial feasibility in the Arctic"),
    ("table20_tuscan", "draftv5", r"^Table 20\. Suggested financial mechanisms", r"^Financial feasibility in the Tuscan"),
    ("table22_macaronesia", "draftv5", r"^\*Table 22: Finance and implementation toolkit", r"^## 5\.6 "),
    ("toolkit_annex_table2", "toolkit", r"^\| \\# \| Mechanism & Cost profile", r"^\s*$"),
    ("toolkit_references", "toolkit", r"^\*\*\*Core references for the financial toolkit",
     r"^\*\*\*Toolkit-supporting analytical references"),
]
SCENARIO_HEADING_RE = r"^#{3,4} (?:5\.4\.\d )?Scenario \d: "

# FINAL-PDF table regions: (caption regex, end regex = next table caption)
PDF_TABLE_REGIONS = {
    "arctic": (r"Table 9\.\s+Suggested financial mechanisms", r"Table 10\b"),
    "tuscan": (r"Table 20\.\s+Suggested financial mechanisms", r"Table 21\b"),
    "macaronesia": (r"Table 22:\s+Finance and implementation toolkit", r"Table 23\b"),
}
NAME_PREFIX = 40  # normalized chars; long names wrap across PDF cell lines


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with open(path, "rb") as fh:
        for chunk in iter(lambda: fh.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def cut_section(text, start_regex, end_regex):
    lines = text.splitlines()
    start = next((i for i, ln in enumerate(lines) if re.search(start_regex, ln)), None)
    if start is None:
        raise ValueError(f"section start not found: {start_regex}")
    end = next((j for j in range(start + 1, len(lines)) if re.search(end_regex, lines[j])), len(lines))
    return "\n".join(lines[start:end]) + "\n"


def normalize_for_match(s):
    return re.sub(r"[^a-z0-9]", "", s.lower())


def pdf_table_region(pdf_text, da):
    cap, end = PDF_TABLE_REGIONS[da]
    starts = [m.start() for m in re.finditer(cap, pdf_text)]
    if not starts:
        raise ValueError(f"FINAL PDF caption not found for {da}: {cap}")
    s = starts[-1]                       # last occurrence = body caption, not the list of tables
    m = re.search(end, pdf_text[s + 1:])
    return pdf_text[s: s + 1 + m.start()] if m else pdf_text[s:]


def verify_names_against_pdf(names_by_da, pdf_text):
    missing = []
    for da, names in names_by_da.items():
        region = normalize_for_match(pdf_table_region(pdf_text, da))
        for n in names:
            if normalize_for_match(n)[:NAME_PREFIX] not in region:
                missing.append(n)
    return missing


def find_pdftotext(override=None):
    for cand in (override, shutil.which("pdftotext"), PDFTOTEXT_FALLBACK):
        if cand and Path(cand).exists():
            return str(cand)
    sys.exit("[refresh] pdftotext not found (xpdf 4.00 ships with Git for Windows); pass --pdftotext PATH")


def pdftotext(path, exe):
    # xpdf writes Latin-1 by default and CESU-8 surrogates even with -enc UTF-8;
    # output is only used for normalized name matching, so replacement is harmless.
    out = subprocess.run([exe, "-enc", "UTF-8", "-raw", str(path), "-"], check=True, capture_output=True)
    return out.stdout.decode("utf-8", errors="replace")


def tool_version(argv):
    r = subprocess.run(argv, capture_output=True)
    txt = (r.stdout or b"").decode("utf-8", "replace") + (r.stderr or b"").decode("utf-8", "replace")
    return txt.strip().splitlines()[0] if txt.strip() else "unknown"


def check_pins(old_header, new_header, accept):
    if accept or not any(k in old_header for k in PIN_KEYS):
        return []
    return [k for k in PIN_KEYS if old_header.get(k) != new_header.get(k)]


def write_extract(sections, header, out_path):
    out_path.parent.mkdir(parents=True, exist_ok=True)
    parts = ["<!-- WP5 KB v2 source extract: GENERATED by scripts/build_wp5_mechanisms_kb.py --refresh-extract. Do not edit. -->"]
    parts += [f"<!-- {k}: {v} -->" for k, v in header.items()]
    for name, body in sections.items():
        parts += [f"<!-- wp5-extract: {name} -->", body.rstrip("\n"), "<!-- /wp5-extract -->"]
    out_path.write_text("\n".join(parts) + "\n", encoding="utf-8", newline="\n")


def read_extract(path):
    text = path.read_text(encoding="utf-8")
    header = dict(re.findall(r"^<!-- ([a-z0-9_]+): (.*?) -->$", text, flags=re.M))
    secs = {"__header__": header}
    for m in re.finditer(r"<!-- wp5-extract: (\w+) -->\n(.*?)\n<!-- /wp5-extract -->", text, flags=re.S):
        secs[m.group(1)] = m.group(2)
    return secs


def pandoc_md(path):
    out = subprocess.run(["pandoc", str(path), "-t", "gfm", "--wrap=none"], check=True, capture_output=True)
    return out.stdout.decode("utf-8", errors="strict")


def refresh_extract(wp5_dir, accept_new_sources=False, pdftotext_override=None):
    paths = {k: wp5_dir / v for k, v in SOURCE_FILES.items()}
    for k, p in paths.items():
        if not p.exists():
            sys.exit(f"[refresh] missing source {k}: {p}")
    exe = find_pdftotext(pdftotext_override)
    header = {
        "generated": date.today().isoformat(),
        "draftv5_sha256": sha256(paths["draftv5"]),
        "toolkit_sha256": sha256(paths["toolkit"]),
        "final_pdf_sha256": sha256(paths["final_pdf"]),
        "pandoc_version": tool_version(["pandoc", "--version"]),
        "pdftotext_version": tool_version([exe, "-v"]),
    }
    old = read_extract(EXTRACT_PATH)["__header__"] if EXTRACT_PATH.exists() else {}
    changed = check_pins(old, header, accept_new_sources)
    if changed:
        sys.exit("[refresh] source hashes changed (" + ", ".join(changed) +
                 "); review the new WP5 documents, then rerun with --accept-new-sources")
    md = {"draftv5": pandoc_md(paths["draftv5"]), "toolkit": pandoc_md(paths["toolkit"])}
    sections = {name: cut_section(md[src], s, e) for name, src, s, e in SECTIONS}
    sections["scenario_headings"] = "\n".join(
        ln for ln in md["draftv5"].splitlines() if re.match(SCENARIO_HEADING_RE, ln)) + "\n"
    names_by_da = {}
    for m in parse_mechanism_names(sections):
        names_by_da.setdefault(m["da"], []).append(m["name"])
    missing = verify_names_against_pdf(names_by_da, pdftotext(paths["final_pdf"], exe))
    if missing:
        sys.exit("[refresh] names absent from their FINAL PDF table region (stale docx?): " + "; ".join(missing))
    n = sum(len(v) for v in names_by_da.values())
    header["verified_against_final_pdf"] = f"{n} mechanism names found in their FINAL v5 table regions"
    write_extract(sections, header, EXTRACT_PATH)
    print(f"[refresh] wrote {EXTRACT_PATH} ({n} mechanisms verified)")
