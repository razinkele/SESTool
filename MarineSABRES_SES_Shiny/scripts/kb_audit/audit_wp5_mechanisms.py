#!/usr/bin/env python3
"""WP5 mechanism KB v2 audit (spec 2026-10-11 WS-2).

(a) committed JSON must EQUAL a fresh build from the committed extract
    (field-level diff -> catches hand edits, swapped columns, short-cell edits);
(b) independent invariants (counts, provenance, placeholders, canonical codes,
    no Tuscan scenarios, no use_in_impact_assessment, cost bands, header pins);
(c) per-section verbatim containment of every non-derived string.
There is deliberately NO completeness floor.

Usage (from MarineSABRES_SES_Shiny/):
    micromamba run -n shiny python -I scripts/kb_audit/audit_wp5_mechanisms.py
"""
import importlib.util
import json
import re
import sys
from pathlib import Path

APP = Path(__file__).resolve().parents[2]
KB_PATH = APP / "data" / "ses_knowledge_db_wp5_mechanisms.json"
_s = importlib.util.spec_from_file_location("bk", APP / "scripts" / "build_wp5_mechanisms_kb.py")
bk = importlib.util.module_from_spec(_s); _s.loader.exec_module(bk)

EXPECTED = {"arctic": 8, "tuscan": 7, "macaronesia": 16}
PLACEHOLDER = re.compile(r"§x\.x|\bTODO\b|\bTBD\b|POS_density")
SKIP = {"id", "da", "number", "provenance", "source_ref", "derived", "reference_numbers"}


def _diff(a, b, path, out):
    if isinstance(a, dict) and isinstance(b, dict):
        for k in sorted(set(a) | set(b)):
            _diff(a.get(k, "<missing>"), b.get(k, "<missing>"), f"{path}.{k}" if path else k, out)
    elif isinstance(a, list) and isinstance(b, list) and len(a) == len(b):
        for i, (x, y) in enumerate(zip(a, b)):
            _diff(x, y, f"{path}[{i}]", out)
    elif a != b:
        out.append(path)


def _strings(obj, path=""):
    if isinstance(obj, dict):
        for k, v in obj.items():
            if k not in SKIP:
                yield from _strings(v, f"{path}.{k}" if path else k)
    elif isinstance(obj, list):
        for i, v in enumerate(obj):
            yield from _strings(v, f"{path}[{i}]")
    elif isinstance(obj, str):
        yield path, obj


def audit(kb, sections):
    fails = []
    hdr = sections.get("__header__", {})
    for k in ["verified_against_final_pdf"] + bk.PIN_KEYS:
        if not hdr.get(k):
            fails.append(f"top.extract_header: missing {k}")
    fresh = bk.build_kb(sections)
    for da, want in EXPECTED.items():
        cm = kb["demonstration_areas"].get(da, {}).get("mechanisms", [])
        fm = fresh["demonstration_areas"][da]["mechanisms"]
        if len(cm) != want:
            fails.append(f"top.{da}: {len(cm)} mechanisms, FINAL D5.2 has {want}")
        for c, f in zip(cm, fm):
            diffs = []
            _diff(c, f, "", diffs)
            fails += [f"{c.get('id')}.{p}: differs from a fresh build of the extract" for p in diffs]
    top_diffs = []
    _diff({k: v for k, v in kb.items() if k != "demonstration_areas"},
          {k: v for k, v in fresh.items() if k != "demonstration_areas"}, "", top_diffs)
    fails += [f"top.{p}: differs from a fresh build of the extract" for p in top_diffs]

    norm = {k: bk.clean_cell(v) for k, v in sections.items() if k != "__header__"}
    hay = {"arctic": norm.get("table9_arctic", ""), "tuscan": norm.get("table20_tuscan", ""),
           "macaronesia": norm.get("table22_macaronesia", "")}
    ids = []
    for da in EXPECTED:
        for m in kb["demonstration_areas"].get(da, {}).get("mechanisms", []):
            mid = m.get("id"); ids.append(mid)
            if m.get("provenance") != "wp5_source" or not m.get("source_ref"):
                fails.append(f"{mid}.provenance: missing wp5_source/source_ref")
            d = m.get("derived", {})
            if d.get("provenance") != "wp5_derived" or not d.get("derivation"):
                fails.append(f"{mid}.derived: missing wp5_derived/derivation")
            tk = m.get("toolkit")
            if tk is not None:
                if tk.get("provenance") != "wp5_prefinal" or tk.get("source_ref", {}).get("in_final_d52") is not False:
                    fails.append(f"{mid}.toolkit: must be wp5_prefinal with in_final_d52=false")
                if "use_in_impact_assessment" in tk:
                    fails.append(f"{mid}.toolkit.use_in_impact_assessment: must not ship before partner Q1")
            if "use_in_impact_assessment" in m:
                fails.append(f"{mid}.use_in_impact_assessment: must not ship before partner Q1")
            for path, val in _strings({k: v for k, v in m.items() if k != "toolkit"}):
                if PLACEHOLDER.search(val):
                    fails.append(f"{mid}.{path}: placeholder text")
                elif val and bk.clean_cell(val) not in hay[da]:
                    fails.append(f"{mid}.{path}: not verbatim in its source table")
            for path, val in _strings(tk or {}):
                if val and bk.clean_cell(val) not in norm.get("toolkit_annex_table2", ""):
                    fails.append(f"{mid}.toolkit.{path}: not verbatim in toolkit Annex Table 2")
            for code in d.get("success_metrics", []):
                if code not in bk.CANONICAL_INDICATORS:
                    fails.append(f"{mid}.derived.success_metrics: non-canonical {code}")
            if da == "macaronesia":
                parts, _ = bk.cost_band_parts(m.get("cost_band", ""))
                if not parts or not all(p in bk.COST_GLYPHS for p in parts):
                    fails.append(f"{mid}.cost_band: not in the D5.2 legend")
    if len(ids) != len(set(ids)):
        fails.append("top.ids: duplicate mechanism ids")
    if kb.get("scenarios", {}).get("tuscan"):
        fails.append("top.scenarios.tuscan: must be empty (D5.2 defines no Tuscan scenarios)")
    for da, scs in kb.get("scenarios", {}).items():
        for sc in scs:
            if sc.get("name", "") not in norm.get("scenario_headings", ""):
                fails.append(f"top.scenarios.{da}.{sc.get('code')}: name not in scenario_headings")
    for svc, v in kb["valuation_unit_values"]["posidonia_oceanica"].items():
        if not (v["low"] <= v["central"] <= v["high"]):
            fails.append(f"top.valuation.{svc}: band order violated")
    return fails


def main():
    sys.stdout.reconfigure(encoding="utf-8")
    kb = json.loads(KB_PATH.read_text(encoding="utf-8"))
    fails = audit(kb, bk.read_extract(bk.EXTRACT_PATH))
    for f in fails:
        print("FAIL", f)
    print(f"[audit] {len(fails)} failure(s)")
    sys.exit(1 if fails else 0)


if __name__ == "__main__":
    main()
