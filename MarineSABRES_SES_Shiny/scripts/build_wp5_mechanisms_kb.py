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


CANONICAL_INDICATORS = ["C_01", "C_02", "F_01", "F_02", "F_03", "M_01", "M_02", "T_01", "T_02", "T_03", "T_04"]
COST_GLYPHS = {"€", "€€", "€€€", "€€€€"}
DOC_DRAFTV5 = "MarineSABRES D5.2 v5 (Draftv5 docx; names verified against FINAL v5 PDF, 23 Jun 2026)"
DOC_TOOLKIT = "Blue Corridor financial toolkit, 17 Apr 2026 (Annex Table 2, long version; NOT part of FINAL D5.2)"

# Exact cleaned Table 9 phrases -> coded applicability (wp5_derived). Unknown phrase -> None.
ARCTIC_APPLICABILITY = {
    "Applicable across all scenarios; effectiveness increases under coordinated agreements":
        {"no_agreement": "applicable", "partial_agreement": "applicable", "full_agreement": "applicable"},
    "Essential under all scenarios; coordination efficiencies strongest under Full Agreement":
        {"no_agreement": "essential", "partial_agreement": "essential", "full_agreement": "essential"},
    "Most effective under Full Agreement": {"full_agreement": "most_effective"},
    "Most effective under Full Agreement; fragmented under No/Partial Agreement":
        {"full_agreement": "most_effective", "no_agreement": "fragmented", "partial_agreement": "fragmented"},
    "Applicable mainly under Full Agreement and stable RBM systems": {"full_agreement": "applicable"},
    "Strongest under Full Agreement": {"full_agreement": "most_effective"},
    "Complementary mechanism across scenarios":
        {"no_agreement": "complementary", "partial_agreement": "complementary", "full_agreement": "complementary"},
    "Complementary and currently limited":
        {"no_agreement": "complementary", "partial_agreement": "complementary", "full_agreement": "complementary"},
}


def clean_cell(s):
    s = s.replace("**", "")
    s = re.sub(r"<br\s*/?>", " ", s)
    s = re.sub(r"\\(.)", r"\1", s)
    return re.sub(r"\s+", " ", s).strip()


def split_row(line):
    return [p.strip() for p in re.split(r"(?<!\\)\|", line.strip())[1:-1]]


def parse_pipe_table(section):
    rows = [ln for ln in section.splitlines() if ln.lstrip().startswith("|")]
    if not rows:
        return []
    header = [clean_cell(c) for c in split_row(rows[0])]
    out = []
    for ln in rows[1:]:
        cells = split_row(ln)
        if all(re.fullmatch(r":?-{3,}:?", c.strip()) for c in cells if c.strip()):
            continue
        if len(cells) != len(header):
            raise ValueError(f"row has {len(cells)} cells, header has {len(header)}: {ascii(ln[:80])}")
        out.append(dict(zip(header, [clean_cell(c) for c in cells])))
    return out


def split_name_cost(cell):
    m = re.match(r"^\s*\*\*(.+?)\*\*\s*(.*)$", cell.strip())
    if not m:
        raise ValueError(f"cannot split name/cost: {ascii(cell[:60])}")
    return clean_cell(m.group(1)), clean_cell(m.group(2))


def parse_risks(cell):
    pairs = []
    for chunk in re.split(r"\bRisk:\s*", clean_cell(cell))[1:]:
        risk, _, guard = chunk.partition("Guardrail:")
        pairs.append({"risk": risk.strip(), "guardrail": guard.strip()})
    return pairs


def find_indicator_codes(text):
    found = []
    for code in re.findall(r"\b([CFMT]_0\d)\b", text):
        if code not in found:
            found.append(code)
    return (sorted(c for c in found if c in CANONICAL_INDICATORS),
            sorted(c for c in found if c not in CANONICAL_INDICATORS))


def ref_numbers(text):
    nums = []
    for grp in re.findall(r"\\?\[([0-9,\s]+)\\?\]", text):
        nums += [int(n) for n in re.findall(r"\d+", grp)]
    return sorted(set(nums))


def name_tokens_overlap(a, b):
    ta = set(re.findall(r"[a-z0-9]{4,}", a.lower()))
    tb = set(re.findall(r"[a-z0-9]{4,}", b.lower()))
    return len(ta & tb)


def code_arctic_applicability(text):
    return ARCTIC_APPLICABILITY.get(text)


def cost_band_parts(band):
    flagged = band.endswith("*")
    return [p.strip() for p in band.rstrip("*").split("–") if p.strip()], flagged


ARCTIC_CODES = {"No Agreement": "no_agreement", "Partial Agreement": "partial_agreement", "Full Agreement": "full_agreement"}


def parse_scenarios(section):
    sc = {"arctic": [], "macaronesia": [], "tuscan": []}
    for ln in section.splitlines():
        m = re.match(r"^### 5\.4\.(\d) Scenario (\d): (.+)$", ln)
        if m:
            sc["macaronesia"].append({"code": f"S{m.group(2)}", "name": m.group(3).strip(),
                                      "source_ref": {"document": DOC_DRAFTV5, "section": f"5.4.{m.group(1)}"}})
            continue
        m = re.match(r"^#### Scenario (\d): (.+)$", ln)
        if m and m.group(2).strip() in ARCTIC_CODES and len(sc["arctic"]) < 3:
            sc["arctic"].append({"code": ARCTIC_CODES[m.group(2).strip()], "name": m.group(2).strip(),
                                 "source_ref": {"document": DOC_DRAFTV5, "section": f"3 (Scenario {m.group(1)})"}})
    return sc


def _table_rows(sections):
    return {"arctic": parse_pipe_table(sections["table9_arctic"]),
            "tuscan": parse_pipe_table(sections["table20_tuscan"]),
            "macaronesia": parse_pipe_table(sections["table22_macaronesia"])}


def parse_mechanism_names(sections):
    rows = _table_rows(sections)
    return ([{"da": "arctic", "name": r["Financial mechanism"]} for r in rows["arctic"]] +
            [{"da": "tuscan", "name": r["Financial mechanism"]} for r in rows["tuscan"]] +
            [{"da": "macaronesia", "name": r["Mechanism (toolkit instrument)"]} for r in rows["macaronesia"]])


def _arctic_tuscan(da, prefix, table_label, rows, applic_col):
    mechs = []
    for i, r in enumerate(rows, 1):
        m = {"id": f"{prefix}_{i:02d}", "number": i, "da": da, "name": r["Financial mechanism"],
             "how_it_works": r[next(k for k in r if k.startswith("How it works"))],
             "who_pays": r["Who pays / finances it"],
             "governance_interface": r["Governance / delivery interface"],
             "applicability_text": r[applic_col],
             "provenance": "wp5_source",
             "source_ref": {"document": DOC_DRAFTV5, "table": table_label, "row": i}}
        canon, unmapped = find_indicator_codes(" ".join(r.values()))
        derived = {"provenance": "wp5_derived",
                   "derivation": {"success_metrics": "indicator codes found in the row text"},
                   "success_metrics": canon, "success_metrics_unmapped": unmapped}
        if da == "arctic":
            derived["scenario_applicability"] = code_arctic_applicability(r[applic_col])
            derived["derivation"]["scenario_applicability"] = \
                "exact-phrase map ARCTIC_APPLICABILITY over applicability_text (null = phrase not mapped)"
        m["derived"] = derived
        mechs.append(m)
    return mechs


def _macaronesia(rows, toolkit_section):
    tk_lines = toolkit_section.splitlines()
    tk_header = [clean_cell(c) for c in split_row(tk_lines[0])]
    toolkit = {}
    for ln in (l for l in tk_lines if re.match(r"^\| \d+ \|", l)):
        cells = split_row(ln)
        if len(cells) != len(tk_header):
            raise ValueError(f"toolkit row has {len(cells)} cells, header {len(tk_header)}")
        toolkit[int(clean_cell(cells[0]))] = dict(zip(tk_header, cells))
    mechs = []
    for r in rows:
        n = int(r["#"])
        t = toolkit[n]
        name_tk, cost_profile = split_name_cost(t["Mechanism & Cost profile"])
        if name_tokens_overlap(name_tk, r["Mechanism (toolkit instrument)"]) < 2:
            raise ValueError(f"toolkit row {n} name does not match Table 22 row {n}: {ascii(name_tk)}")
        success_txt = clean_cell(t["Success metrics (observable, indicator-aligned)"])
        canon, unmapped = find_indicator_codes(r["What success looks like (linked to indicators)"] + " " + success_txt)
        parts, flagged = cost_band_parts(r["Cost"])
        mechs.append({
            "id": f"mac_{n:02d}", "number": n, "da": "macaronesia",
            "name": r["Mechanism (toolkit instrument)"],
            "what_it_delivers": r["What it delivers in practice"],
            "finance_flow_text": r["Who pays → what it funds (finance flow)"],
            "cost_band": r["Cost"],
            "success_statement": r["What success looks like (linked to indicators)"],
            "provenance": "wp5_source",
            "source_ref": {"document": DOC_DRAFTV5, "table": "Table 22", "row": n},
            "toolkit": {
                "provenance": "wp5_prefinal",
                "source_ref": {"document": DOC_TOOLKIT, "table": "Annex Table 2", "row": n, "in_final_d52": False},
                "name": name_tk, "cost_profile": cost_profile,
                "what_it_funds": clean_cell(t["What it funds / how it works (sector-facing)"]),
                "finance_flow": clean_cell(t["Finance flow (sources → uses; payer/receiver)"]),
                "design_parameters": clean_cell(t["Key design parameters (choices that determine success vs failure)"]),
                "source_types": clean_cell(t["Source types"]),
                "analogues": clean_cell(t["Relevant project / analogue examples"]),
                "transferable_lessons": clean_cell(t["Transferable design lessons"]),
                "relevance": clean_cell(t["Macaronesia relevance notes"]),
                "success_metrics_text": success_txt,
                "risks_and_guardrails_text": clean_cell(t["Risks & guardrails (must-haves)"]),
                "reference_numbers": ref_numbers(t["Source types"] + " " + t["Relevant project / analogue examples"]),
            },
            "derived": {
                "provenance": "wp5_derived",
                "derivation": {
                    "success_metrics": "canonical indicator codes found in Table 22 success text + toolkit success metrics",
                    "risks_and_guardrails": "toolkit 'Risks & guardrails' cell split on 'Risk:' / 'Guardrail:' markers",
                    "cost_band_flagged": "Table 22 cost cell ends with '*' (meaning not stated in D5.2)",
                },
                "success_metrics": canon, "success_metrics_unmapped": unmapped,
                "risks_and_guardrails": parse_risks(t["Risks & guardrails (must-haves)"]),
                "cost_band_flagged": flagged,
            },
        })
    return mechs


def parse_references(section):
    return {m.group(1): clean_cell(m.group(2).strip("*"))
            for m in re.finditer(r"^(\d+)\.\s+(.+)$", section, flags=re.M)}


VALUATION_UNIT_VALUES = {
    "meta": {
        "provenance": "wp5_source",
        "source_ref": "D5.2 v5 Table 19 (Posidonia oceanica benefit-transfer values); restoration costs §4 (REE 2022; Bayraktarov et al. 2016)",
        "derivation": {"central": "wp5_derived: arithmetic midpoint of low/high; not a D5.2 value"},
    },
    "posidonia_oceanica": {
        "coastal_protection":   {"low": 3500, "central": 10350, "high": 17200, "unit": "EUR/ha/yr", "method": "avoided_cost"},
        "carbon_sequestration": {"low": 40,   "central": 140,   "high": 240,   "unit": "EUR/ha/yr", "method": "social_cost_of_carbon"},
        "recreation_tourism":   {"low": 400,  "central": 2500,  "high": 4600,  "unit": "EUR/ha/yr", "method": "travel_cost_or_WTP"},
        "food_provision":       {"low": 150,  "central": 975,   "high": 1800,  "unit": "EUR/ha/yr", "method": "market_pricing"},
        "water_purification":   {"low": 350,  "central": 1175,  "high": 2000,  "unit": "EUR/ha/yr", "method": "replacement_cost"},
    },
    "restoration_costs": {
        "posidonia_oceanica": {"low": 100000, "high": 500000, "unit": "EUR/ha", "early_survival_low": 0.38, "early_survival_high": 0.60},
    },
}


def build_kb(sections):
    rows = _table_rows(sections)
    hdr = sections.get("__header__", {})
    legend = next((ln for ln in sections["table22_macaronesia"].splitlines() if "Cost bands" in ln), "")
    return {
        "version": "2.0.0",
        "schema": 2,
        "description": "WP5 financial and implementation mechanisms parsed verbatim from FINAL D5.2 (v5) Tables 9, 20, 22; "
                       "Macaronesia toolkit details from the pre-final Blue Corridor toolkit (17 Apr 2026, not part of FINAL D5.2). "
                       "Built by scripts/build_wp5_mechanisms_kb.py from scripts/wp5_kb_sources/d5.2_v5_mechanism_sources.md.",
        "last_updated": hdr.get("generated", ""),
        "source_documents": [
            {"file": SOURCE_FILES["draftv5"], "sha256": hdr.get("draftv5_sha256", ""), "role": "Tables 9/20/22, scenario headings", "in_final_d52": True},
            {"file": SOURCE_FILES["toolkit"], "sha256": hdr.get("toolkit_sha256", ""), "role": "Macaronesia toolkit long table + references", "in_final_d52": False},
            {"file": SOURCE_FILES["final_pdf"], "sha256": hdr.get("final_pdf_sha256", ""), "role": "authority; mechanism-name verification", "in_final_d52": True},
        ],
        "cost_bands": {"legend": clean_cell(legend), "provenance": "wp5_source", "source_ref": {"document": DOC_DRAFTV5, "table": "Table 22"}},
        "scenarios": parse_scenarios(sections["scenario_headings"]),
        "demonstration_areas": {
            "arctic": {"mechanisms": _arctic_tuscan("arctic", "arc", "Table 9", rows["arctic"], "Applicability under scenarios")},
            "tuscan": {"mechanisms": _arctic_tuscan("tuscan", "tus", "Table 20", rows["tuscan"], "Applicability in Tuscan DA")},
            "macaronesia": {"mechanisms": _macaronesia(rows["macaronesia"], sections["toolkit_annex_table2"])},
        },
        "references": {"toolkit": parse_references(sections["toolkit_references"])},
        "valuation_unit_values": VALUATION_UNIT_VALUES,
    }


def kb_json_text(kb):
    return json.dumps(kb, ensure_ascii=False, indent=2) + "\n"


def main():
    sys.stdout.reconfigure(encoding="utf-8")
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--refresh-extract", action="store_true")
    ap.add_argument("--accept-new-sources", action="store_true")
    ap.add_argument("--wp5-dir", type=Path, default=APP_ROOT / "WP5")
    ap.add_argument("--pdftotext", default=None)
    args = ap.parse_args()
    if args.refresh_extract:
        refresh_extract(args.wp5_dir, args.accept_new_sources, args.pdftotext)
    kb = build_kb(read_extract(EXTRACT_PATH))
    OUT_PATH.write_text(kb_json_text(kb), encoding="utf-8", newline="\n")
    print(f"[build] wrote {OUT_PATH} ({sum(len(v['mechanisms']) for v in kb['demonstration_areas'].values())} mechanisms)")


if __name__ == "__main__":
    main()
