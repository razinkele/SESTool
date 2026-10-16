# WP5 WS-8 Scenario × Worldview Reference Library Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship the D5.1 scenario × worldview reference library: two generated JSON datasets, a "WP5 scenarios (D5.1)" tab in the Scenario Builder page, and a PESTLE tag on Response register measures that links them to the cells needing area-level transformation.

**Architecture:** A Python build script reads the published D5.1 tables and the regionalisation table (local `WP5/` folder, not in git), cross-checks them against the working spreadsheet, and writes `data/wp5_scenarios_ssp.json` and `data/wp5_worldview_matrix.json` (committed). R loaders and pure helpers in `functions/wp5_scenarios.R` feed a new sub-module `modules/wp5_scenario_reference_module.R`, mounted as a tab of the Scenario Builder outside its CLD gate. The Response register gains a `PestleTag` column.

**Tech Stack:** R ≥ 4.4.1, Shiny + bs4Dash, shiny.i18n, jsonlite, testthat 3; Python (micromamba env `shiny`) with python-docx, openpyxl, pytest 8.4.2.

**Spec:** `MarineSABRES_SES_Shiny/docs/superpowers/specs/2026-10-16-wp5-ws8-scenario-library-design.md` (read it; it is the authority). Source audit: `docs/wp5-source-audit/2026-10-11/B_D5.1_scenarios.md`.

All paths below are relative to `MarineSABRES_SES_Shiny/` in the worktree `C:/Users/arturas.baziukas/wt-ws8` (branch `feat/wp5-ws8-scenario-library`). The git root is one level up: use `git -C C:/Users/arturas.baziukas/wt-ws8 ...`, never `cd <path> && git`.

## Global Constraints

- **D5.1 sources are not in the worktree or on CI.** `WP5/` is untracked in git. The only copy is in the main checkout: `C:/Users/arturas.baziukas/OneDrive - ku.lt/HORIZON_EUROPE/Marine-SABRES/SESToolbox/MarineSABRES_SES_Shiny/WP5/Task 5.1 Application of Scenarios`. Pass it with `--src`; Python tests that need it skip when it is absent (env var `WP5_D51_SRC` or that default path).
- Python only through `micromamba run -n shiny python ...` (no venv, no pip).
- R tests from the app dir, one file filter per process, user library first:
  `Rscript -e ".libPaths(c('C:/Users/arturas.baziukas/AppData/Local/R/win-library/4.4', .libPaths())); testthat::test_dir('tests/testthat', filter = '^wp5-scenarios$')"`
- `data/wp5_*.json` from this plan are generated: never edit them by hand; regenerate with the build script.
- PESTLE codes, in this order everywhere: `political, economic, social, technological, legal, environmental` (`PESTLE_CODES` in `constants.R`). Scenario ids `ssp1_26, ssp2_45, ssp3_70, ssp5_85`; worldview ids `egalitarian, individualist, hierarchy`; transformation states `area, europe, none`.
- Narrative, rationale and worldview description text is English source data (shown with a "Source text (English)" badge); every label, heading, state, note and strategy text goes through `i18n$t()` in 9 languages (en, es, fr, de, lt, pt, it, no, el). `micromamba run -n shiny python scripts/_i18n_audit.py` must report `missing=0`, `hardcoded=0`. Dynamic keys get `# i18n-ref:` sentinels. Never edit `translations/_merged_translations.json`.
- `PestleTag` is a `;`-joined set of PESTLE codes; empty string = not tagged; unknown codes dropped on normalise with `debug_log()`.
- Logging via `debug_log()`; user errors via `format_user_error(e, i18n = i18n, context_key = ...)`.
- Commits: write the message to a scratch file and `git -C <wt> commit -F <file>`; end every message with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. `docs/` is gitignored (`git add -f` for plan/spec).

## Rulings made while planning

1. **Appendix 1 `*` marks are not used.** The spec said they agree with Table 4's "X"; the prototype showed 8 cells where the Appendix omits the `*`. Table 4 is the only source for `wv_more_conducive`; the `*` is stripped from the rationale (spec §3.2/§7 amended in Task 1).
2. **The `general` slice is hidden when empty** (12 of 24 cells have no general text); it is not shown with a gap note. Gap notes apply to the three sector slices only.
3. **`PESTLE_CODES` lives in `constants.R`** and `functions/wp5_scenarios.R` uses it (one definition).
4. **The worldview text, the scenario narratives and the rationale are not translated** (spec decision 1); the strategy paragraphs and source notes are our wording and are translated.

## Review Focus

1. A project with no Response register, or a legacy register without `PestleTag`, opening the reference tab → the tab renders and the responses block shows the hint, never an error (Task 5 test).
2. The reference JSON missing or corrupt (e.g. a deploy without `data/wp5_*.json`) → the tab shows "reference data unavailable" and the Scenario Builder's own tab still works (Task 5 test).
3. A cell whose transformation is only Europe-wide or none (e.g. Egalitarian × SSP3) selected → the responses block explains why nothing is linked, it does not list responses (Task 5 test).
4. A measure tagged with an element that is area-level in one cell but not in another → it appears only for the cells where that element is area-level (Task 2 test on `wp5_matched_responses` with `wp5_area_elements`).
5. Saving a measure with no PESTLE elements selected → `PestleTag` is `""`, not `"NA"` or `"character(0)"` (Task 3 test).

---

## File map

| File | Task | Responsibility |
|---|---|---|
| `scripts/build_wp5_scenarios.py` | 1 | build + consistency checks |
| `scripts/tests/test_build_wp5_scenarios.py` | 1 | pytest |
| `data/wp5_scenarios_ssp.json`, `data/wp5_worldview_matrix.json` | 1 | generated, committed |
| `constants.R` | 2 | `PESTLE_CODES` |
| `functions/wp5_scenarios.R` | 2 | loaders + pure helpers |
| `global.R` | 2 | source it |
| `tests/testthat/test-wp5-scenarios.R` | 2 | R data tests |
| `functions/response_measures_schema.R`, `modules/response_module.R` | 3 | `PestleTag` |
| `translations/modules/wp5_scenarios.json` (new), `translations/modules/response_governance.json` | 4 | keys |
| `modules/wp5_scenario_reference_module.R` (new), `modules/scenario_builder_module.R`, `app.R` | 5 | tab |
| `VERSION`, `VERSION_INFO.json`, `DESCRIPTION`, `CHANGELOG.md` | 6 | release 1.29.0 |

---

### Task 1: Build script, its tests, and the generated data

**Files:**
- Create: `scripts/build_wp5_scenarios.py`, `scripts/tests/test_build_wp5_scenarios.py`, `data/wp5_scenarios_ssp.json`, `data/wp5_worldview_matrix.json`
- Modify (docs, force-add): `docs/superpowers/specs/2026-10-16-wp5-ws8-scenario-library-design.md` (§3.2 and §7: Appendix-`*` wording and source_ref format — ruling 1)

**Interfaces:**
- Produces: the two JSON files with exactly the structure in spec §3.1/§3.2 (`source_notes` ids: `summary_hierarchy_ssp`, `hierarchy_ssp2_misprint`, `conducive_row_label`, `ssp3_hierarchy_cells`, `generic_europe`; their `text_key` is `modules.wp5_scenarios.source_note.<id>`; `strategies`: `behavioural`, `accepted_instruments`, `limits_of_acceptable_change`; gap codes `ssp_not_in_futuremares`, `no_afmec_lines`, `no_source_text`).

The script below was run on the real sources while planning: all consistency checks pass with exactly the expected exceptions, 72 cells (15 area, 18 europe, 39 none), 12 cells with a `general` slice, gap notes on 5 conservation + 1 seafood + 10 tourism slices, all 18 worldview PESTLE texts present, every cell has a rationale, and a re-run is byte-identical.

- [ ] **Step 1: Write the pytest file** `scripts/tests/test_build_wp5_scenarios.py`:

```python
"""Tests for scripts/build_wp5_scenarios.py (spec 2026-10-16 WS-8 §3.3)."""
import collections
import importlib.util
import json
import os
from pathlib import Path

import pytest

APP = Path(__file__).resolve().parents[2]
DEFAULT_SRC = Path("C:/Users/arturas.baziukas/OneDrive - ku.lt/HORIZON_EUROPE/Marine-SABRES/SESToolbox/"
                   "MarineSABRES_SES_Shiny/WP5/Task 5.1 Application of Scenarios")
SRC = Path(os.environ.get("WP5_D51_SRC", DEFAULT_SRC))
needs_src = pytest.mark.skipif(not SRC.exists(), reason="D5.1 sources not available (WP5/ is not in git)")

spec = importlib.util.spec_from_file_location("build", APP / "scripts" / "build_wp5_scenarios.py")
build = importlib.util.module_from_spec(spec)
spec.loader.exec_module(build)


def test_split_slices_and_gap_codes():
    parts = build.split_slices("Intro text\nHABITAT RESTORATION AND MARINE CONSERVATION\nSSP not featured in Future MARES, "
                               "no specific lines in CERES.\nSEAFOOD HARVESTING\nFish\nTOURISM AND LEISURE\nNo specific lines in AFMEC")
    assert parts["general"] == "Intro text"
    assert build.gap_code(parts["hrmc"]) == "ssp_not_in_futuremares"
    assert build.gap_code(parts["sh"]) is None
    assert build.gap_code(parts["lh"]) == "no_afmec_lines"
    assert build.gap_code("No specific lines in AFMEC.") == "no_afmec_lines"
    assert build.gap_code("") == "no_source_text"


@needs_src
def test_build_real_sources(tmp_path):
    scen, matrix = build.build(SRC, tmp_path)
    assert [s["id"] for s in scen["scenarios"]] == build.SSPS
    assert len(matrix["cells"]) == 72
    assert collections.Counter(c["transformation"] for c in matrix["cells"]) == {"none": 39, "europe": 18, "area": 15}
    general = sum(1 for s in scen["scenarios"] for cell in s["cells"].values() if cell["general"]["text"])
    assert general == 12
    for s in scen["scenarios"]:
        for cell in s["cells"].values():
            for v in cell.values():
                assert (v["text"] is None) == (v["gap_note"] is not None)
    assert all(v for w in matrix["worldviews"] for v in w["pestle"].values())
    assert all(c["rationale"] for c in matrix["cells"])
    assert not any(c["rationale"].startswith("*") for c in matrix["cells"])


@needs_src
def test_rerun_is_byte_identical(tmp_path):
    build.build(SRC, tmp_path / "a")
    build.build(SRC, tmp_path / "b")
    for name in ("wp5_scenarios_ssp.json", "wp5_worldview_matrix.json"):
        assert (tmp_path / "a" / name).read_bytes() == (tmp_path / "b" / name).read_bytes()


@needs_src
def test_committed_json_matches_a_fresh_build(tmp_path):
    build.build(SRC, tmp_path)
    for name in ("wp5_scenarios_ssp.json", "wp5_worldview_matrix.json"):
        assert (APP / "data" / name).read_bytes() == (tmp_path / name).read_bytes()


def test_wingdings_and_expected_exceptions():
    assert (build.TICK, build.CROSS) == ("\u00fc", "\u00fd")
    assert build.EXPECTED_X_DIFF == {("hierarchy", "ssp3_70", "political")}
    assert build.EXPECTED_TRANSFORM_DIFF == {("hierarchy", "ssp3_70", "political"),
                                             ("hierarchy", "ssp3_70", "environmental")}


@needs_src
def test_spreadsheet_checks_pass(tmp_path):
    _, matrix = build.build(SRC, tmp_path)
    assert build.check_against_spreadsheet(SRC, matrix) == []


def test_committed_json_shape():
    m = json.loads((APP / "data" / "wp5_worldview_matrix.json").read_text(encoding="utf-8"))
    assert len(m["cells"]) == 72
    assert {c["transformation"] for c in m["cells"]} <= {"area", "europe", "none"}
```

- [ ] **Step 2: Run to verify it fails** — `micromamba run -n shiny python -m pytest scripts/tests -q`. Expected: error, `scripts/build_wp5_scenarios.py` not found.

- [ ] **Step 3: Create `scripts/build_wp5_scenarios.py`** with exactly this content:

```python
"""Build the WP5 D5.1 scenario x worldview reference data (spec 2026-10-16 WS-8).

Usage:
    micromamba run -n shiny python scripts/build_wp5_scenarios.py [--src DIR] [--out DIR]

Defaults: --src <app>/WP5/Task 5.1 Application of Scenarios, --out <app>/data.
The WP5 source folder is not in git; the generated JSON files are committed.
"""
import argparse
import json
import re
import sys
from pathlib import Path

import docx
import openpyxl
from docx.oxml.ns import qn

APP = Path(__file__).resolve().parents[1]
D51 = "Deliverable report T5.1/Marine SABRES D5.1 scenarios report_v2 final.docx"
RT = "Deliverable report T5.1/SSP-RCP regionalisation table.docx"
RB = "Scenarios vs worldviews paper/results breakdown.xlsx"

PESTLE = ["political", "economic", "social", "technological", "legal", "environmental"]
PESTLE_LABELS = ["Political", "Economic", "Social", "Technological", "Tecnological", "Legal", "Environmental"]
SSPS = ["ssp1_26", "ssp2_45", "ssp3_70", "ssp5_85"]
WVS = ["egalitarian", "individualist", "hierarchy"]
WV_NAME = {"EGA": "egalitarian", "IND": "individualist", "HIE": "hierarchy"}
SLICES = ["general", "hrmc", "sh", "lh"]
SLICE_HEADINGS = {
    "HABITAT RESTORATION AND MARINE CONSERVATION": "hrmc",
    "SEAFOOD HARVESTING": "sh",
    "TOURISM AND LEISURE": "lh",
}
# D5.1 Box 1 (fixed values, not parsed): warming cap by 2100 and EBM conduciveness
SSP_FIXED = {
    "ssp1_26": {"ssp": "SSP1", "rcp": "2.6", "warming_cap": "<=2", "ebm_conducive": "yes"},
    "ssp2_45": {"ssp": "SSP2", "rcp": "4.5", "warming_cap": "<=3", "ebm_conducive": "somewhat"},
    "ssp3_70": {"ssp": "SSP3", "rcp": "7.0", "warming_cap": "<=4", "ebm_conducive": "no"},
    "ssp5_85": {"ssp": "SSP5", "rcp": "8.5", "warming_cap": ">4", "ebm_conducive": "no"},
}
FILL_STATE = {"0070C0": "area", "808080": "europe", "D9D9D9": "none"}
# Cells where the working spreadsheet differs from the published D5.1 tables (spec 3.2)
EXPECTED_X_DIFF = {("hierarchy", "ssp3_70", "political")}
EXPECTED_TRANSFORM_DIFF = {("hierarchy", "ssp3_70", "political"), ("hierarchy", "ssp3_70", "environmental")}
TICK, CROSS = "ü", "ý"  # Wingdings 0xFC = needed, 0xFD = not needed


def clean(s):
    s = (s or "").replace(" ", " ")
    s = re.sub(r"[ \t]*\n[ \t]*", "\n", s)
    s = re.sub(r"\n{2,}", "\n", s)
    return re.sub(r"[ \t]+", " ", s).strip()


def fill(cell):
    pr = cell._tc.tcPr
    shd = pr.find(qn("w:shd")) if pr is not None else None
    val = shd.get(qn("w:fill")) if shd is not None else None
    return val.upper() if val else None


def wv_id(text):
    return WV_NAME.get(clean(text)[:3].upper())


# --- narratives: regionalisation table, table 2 ----------------------------------
def split_slices(text):
    out, current, buf = {}, "general", []
    for line in text.split("\n"):
        key = SLICE_HEADINGS.get(line.strip())
        if key:
            out[current] = "\n".join(buf).strip()
            current, buf = key, []
        else:
            buf.append(line)
    out[current] = "\n".join(buf).strip()
    return out


def gap_code(text):
    if text is None or not text.strip():
        return "no_source_text"
    if text.startswith("SSP not featured in Future MARES"):
        return "ssp_not_in_futuremares"
    if text.startswith("No specific lines in AFMEC"):
        return "no_afmec_lines"
    return None


def build_scenarios(src):
    t = docx.Document(str(src / RT)).tables[2]
    scenarios, questions = [], {}
    for k, sid in enumerate(SSPS):
        col = 2 + k
        sc = {"id": sid, **SSP_FIXED[sid],
              "name": clean(t.rows[0].cells[col].text).split("\n", 1)[-1],
              "global_summary": clean(t.rows[1].cells[col].text),
              "expanded_narrative": clean(t.rows[2].cells[col].text),
              "driver_mapping": None, "cells": {}}
        for p, pid in enumerate(PESTLE):
            row = 4 + p
            questions[pid] = clean(t.rows[row].cells[1].text)
            parts = split_slices(clean(t.rows[row].cells[col].text))
            cell = {}
            for sl in SLICES:
                txt = parts.get(sl)
                code = gap_code(txt)
                cell[sl] = {"text": None if code else txt, "gap_note": code,
                            "source_ref": f"table2:r{row}:c{col}"}
            sc["cells"][pid] = cell
        scenarios.append(sc)
    return {"version": "1.0", "source": "D5.1 (2024-02-26), SSP-RCP regionalisation table",
            "built_by": "scripts/build_wp5_scenarios.py", "pestle": PESTLE,
            "pestle_questions": questions, "slices": SLICES,
            "slice_da_focus": {"hrmc": "tuscany", "sh": "arctic", "lh": "macaronesia"},
            "scenarios": scenarios}


# --- worldview matrix: D5.1 Tables 3, 4, 5 and Appendix 1 ------------------------
def find_tables(d):
    t3 = t4 = t13 = None
    t5 = []
    for t in d.tables:
        cols = len(t.columns)
        fills = {fill(c) for r in t.rows for c in r.cells} - {None}
        if cols == 4 and clean(t.rows[0].cells[0].text).startswith("Worldview"):
            t3 = t
        elif cols == 26 and "92D050" in fills:
            t4 = t
        elif cols == 25 and {"0070C0", "D9D9D9"} <= fills:
            t5.append(t)
        elif cols == 6 and any(clean(r.cells[1].text) in PESTLE_LABELS for r in t.rows):
            t13 = t
    if not (t3 and t4 and t13 and len(t5) == 2):
        sys.exit(f"D5.1 tables not found: t3={bool(t3)} t4={bool(t4)} t5={len(t5)} appendix={bool(t13)}")
    return t3, t4, t5, t13


def table5_states(t):
    out = {}
    for r in t.rows:
        wv = wv_id(r.cells[0].text)
        if not wv:
            continue
        for s, sid in enumerate(SSPS):
            for p, pid in enumerate(PESTLE):
                out[(wv, sid, pid)] = FILL_STATE[fill(r.cells[1 + s * 6 + p])]
    return out


def build_matrix(src):
    d = docx.Document(str(src / D51))
    t3, t4, t5s, t13 = find_tables(d)
    states = table5_states(t5s[0])
    if states != table5_states(t5s[1]):
        sys.exit("check (d) failed: the two Table 5 copies differ")
    rows3 = list(t3.rows)
    wv_cols = {wv_id(rows3[0].cells[c].text): c for c in (1, 2, 3)}
    worldviews = []
    for wv in WVS:
        c = wv_cols[wv]
        get = lambda i, c=c: clean(rows3[i].cells[c].text)
        worldviews.append({"id": wv, "keywords": get(1), "problem": get(2), "solution": get(3),
                           "summary": get(4),
                           "pestle": {pid: (get(6 + i) or None) for i, pid in enumerate(PESTLE)},
                           "source_ref": f"D5.1 Table 3, column {c}"})
    t4rows = list(t4.rows)[2:]
    app_rows, cur = [], None
    for r in t13.rows:
        w = wv_id(r.cells[0].text) or cur
        if clean(r.cells[1].text) in PESTLE_LABELS:
            app_rows.append((w, r))
        cur = w
    cells = []
    for wv in WVS:
        r4s = [r for r in t4rows if wv_id(r.cells[0].text) == wv]
        ras = [r for w, r in app_rows if w == wv]
        for p, pid in enumerate(PESTLE):
            r4, ra = r4s[p], ras[p]
            for s, sid in enumerate(SSPS):
                c4 = r4.cells[2 + s * 6 + p]
                match = {"92D050": True, "FF0000": False}[fill(c4)]
                rat = clean(ra.cells[2 + s].text)
                cells.append({"worldview": wv, "ssp": sid, "pestle": pid,
                              "transformation": states[(wv, sid, pid)],
                              "match": match,
                              "wv_more_conducive": None if match else clean(c4.text) == "X",
                              # Appendix 1 marks some "worldview more conducive" cells with a leading '*',
                              # but not all of them (8 are missing); Table 4's "X" is the source, so strip it
                              "rationale": rat.lstrip("*").strip(),
                              "source_ref": {"table4": f"{wv}:{pid}:c{2 + s * 6 + p}",
                                             "table5": f"{wv}:c{1 + s * 6 + p}",
                                             "appendix1": f"{wv}:{pid}:c{2 + s}"}})
    return {"version": "1.0", "source": "D5.1 Tables 3, 4, 5 and Appendix 1",
            "built_by": "scripts/build_wp5_scenarios.py", "worldviews": worldviews, "cells": cells,
            "source_notes": [{"id": i, "text_key": f"modules.wp5_scenarios.source_note.{i}"} for i in
                             ("summary_hierarchy_ssp", "hierarchy_ssp2_misprint", "conducive_row_label",
                              "ssp3_hierarchy_cells", "generic_europe")],
            "strategies": ["behavioural", "accepted_instruments", "limits_of_acceptable_change"]}


# --- consistency checks against the working spreadsheet (spec 3.3) ---------------
def check_against_spreadsheet(src, matrix):
    ws = openpyxl.load_workbook(str(src / RB), data_only=True)["Sheet1"]
    rows = {"egalitarian": (5, 6, 7), "individualist": (9, 10, 11), "hierarchy": (13, 14, 15)}
    errors, x_diff, t_diff = [], set(), set()
    for c in matrix["cells"]:
        mr, xr, tr = rows[c["worldview"]]
        col = 3 + SSPS.index(c["ssp"]) * 6 + PESTLE.index(c["pestle"])
        key = (c["worldview"], c["ssp"], c["pestle"])
        if (ws.cell(mr, col).value == "Y") != c["match"]:
            errors.append(f"(a) match differs at {key}")
        if (ws.cell(xr, col).value == "Y") != bool(c["wv_more_conducive"]):
            x_diff.add(key)
        glyph = str(ws.cell(tr, col).value or "")[:1]
        if {TICK: True, CROSS: False}.get(glyph) != (c["transformation"] != "none"):
            t_diff.add(key)
    if x_diff != EXPECTED_X_DIFF:
        errors.append(f"(b) unexpected more-conducive differences: {sorted(x_diff ^ EXPECTED_X_DIFF)}")
    if t_diff != EXPECTED_TRANSFORM_DIFF:
        errors.append(f"(c) unexpected transformation differences: {sorted(t_diff ^ EXPECTED_TRANSFORM_DIFF)}")
    return errors


def build(src, out):
    scen = build_scenarios(src)
    matrix = build_matrix(src)
    errors = check_against_spreadsheet(src, matrix)
    if errors:
        print("\n".join(errors))
        sys.exit(1)
    out.mkdir(parents=True, exist_ok=True)
    for name, obj in (("wp5_scenarios_ssp.json", scen), ("wp5_worldview_matrix.json", matrix)):
        (out / name).write_text(json.dumps(obj, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
                                encoding="utf-8", newline="\n")
    return scen, matrix


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--src", default=str(APP / "WP5" / "Task 5.1 Application of Scenarios"))
    ap.add_argument("--out", default=str(APP / "data"))
    a = ap.parse_args(argv)
    build(Path(a.src), Path(a.out))
    print(f"wrote wp5_scenarios_ssp.json and wp5_worldview_matrix.json to {a.out}")


if __name__ == "__main__":
    main()
```

- [ ] **Step 4: Generate the data and run the tests**

```bash
micromamba run -n shiny python scripts/build_wp5_scenarios.py --src "C:/Users/arturas.baziukas/OneDrive - ku.lt/HORIZON_EUROPE/Marine-SABRES/SESToolbox/MarineSABRES_SES_Shiny/WP5/Task 5.1 Application of Scenarios"
micromamba run -n shiny python -m pytest scripts/tests -q
```
Expected: "wrote wp5_scenarios_ssp.json and wp5_worldview_matrix.json to …/data"; 7 passed (the source-dependent tests run locally because the default path points at the main checkout; on CI they skip).

- [ ] **Step 5: Amend the spec** (ruling 1 and the source-ref format): in §3.2 change "a leading `*` marks \"worldview more conducive\" and is stripped" to "a leading `*` (present on some, not all, worldview-more-conducive cells) is stripped; `wv_more_conducive` comes from Table 4 only", and change the matrix `source_ref` example to the label form the script writes: `{ "table4": "<worldview>:<pestle>:c<col>", "table5": "<worldview>:c<col>", "appendix1": "<worldview>:<pestle>:c<col>" }`. In §7 replace the clause "Appendix 1 `*` marks agree with Table 4 \"X\"" with "Appendix 1 `*` marks are incomplete (8 cells lack one) and are not used; Table 4's \"X\" is the source".

- [ ] **Step 6: Commit** exactly these files (pytest creates `__pycache__/` folders under `scripts/`, which are not gitignored — do not add them): `git -C C:/Users/arturas.baziukas/wt-ws8 add MarineSABRES_SES_Shiny/scripts/build_wp5_scenarios.py MarineSABRES_SES_Shiny/scripts/tests/test_build_wp5_scenarios.py MarineSABRES_SES_Shiny/data/wp5_scenarios_ssp.json MarineSABRES_SES_Shiny/data/wp5_worldview_matrix.json`, plus `git -C C:/Users/arturas.baziukas/wt-ws8 add -f MarineSABRES_SES_Shiny/docs/superpowers/specs/2026-10-16-wp5-ws8-scenario-library-design.md` — `feat(wp5): D5.1 scenario x worldview data build (WS-8)`.

---

### Task 2: R data layer

**Files:**
- Modify: `constants.R` (after the WP5 intervention constants block, ~line 925), `global.R` (after `source("functions/wp5_typing_lint.R", local = FALSE)`, ~line 711)
- Create: `functions/wp5_scenarios.R`, `tests/testthat/test-wp5-scenarios.R`

**Interfaces:**
- Consumes: Task 1 JSON.
- Produces: `PESTLE_CODES` (constants); `load_wp5_scenarios(path = NULL, force_reload = FALSE)`, `load_wp5_worldview_matrix(path = NULL, force_reload = FALSE)` (list or NULL); `wp5_cell_rows(matrix, worldview, ssp)` (6 cells, PESTLE order); `wp5_heatmap_summary(matrix)` → data.frame(worldview, ssp, n_area, n_europe, pattern); `wp5_area_elements(matrix, worldview, ssp)` → character; `wp5_matched_responses(register, elements)` → rows + list column `matched`.

- [ ] **Step 1: Write the failing tests** — `tests/testthat/test-wp5-scenarios.R`:

```r
# tests/testthat/test-wp5-scenarios.R
# WS-8 (spec 2026-10-16): the committed D5.1 data and the pure helpers.
source_for_test("functions/wp5_scenarios.R")

m <- load_wp5_worldview_matrix(force_reload = TRUE)
s <- load_wp5_scenarios(force_reload = TRUE)

test_that("the committed data has the D5.1 shape", {
  expect_false(is.null(m)); expect_false(is.null(s))
  expect_equal(vapply(s$scenarios, `[[`, "", "id"), c("ssp1_26", "ssp2_45", "ssp3_70", "ssp5_85"))
  expect_equal(unlist(s$pestle), PESTLE_CODES)
  expect_equal(unlist(s$slices), c("general", "hrmc", "sh", "lh"))
  expect_length(m$worldviews, 3L)
  expect_length(m$cells, 72L)
  expect_true(all(vapply(m$cells, `[[`, "", "transformation") %in% c("area", "europe", "none")))
  expect_true(all(nzchar(vapply(m$cells, `[[`, "", "rationale"))))
})

test_that("area-level cells are exactly D5.1 Table 5's blue cells", {
  area <- function(wv, ssp) sort(wp5_area_elements(m, wv, ssp))
  expect_equal(area("individualist", "ssp1_26"), sort(PESTLE_CODES))
  expect_equal(area("individualist", "ssp2_45"), sort(c("political", "economic", "social", "environmental")))
  expect_equal(area("hierarchy", "ssp1_26"), "social")
  expect_equal(area("hierarchy", "ssp2_45"), sort(c("political", "economic", "social", "technological")))
  for (ssp in c("ssp1_26", "ssp2_45", "ssp3_70", "ssp5_85")) expect_length(area("egalitarian", ssp), 0L)
})

test_that("heat-map match patterns reproduce D5.1's notation", {
  h <- wp5_heatmap_summary(m)
  pat <- function(wv, ssp) h$pattern[h$worldview == wv & h$ssp == ssp]
  expect_equal(pat("egalitarian", "ssp1_26"), "_ES___")
  expect_equal(pat("egalitarian", "ssp2_45"), "PES__E")
  expect_equal(pat("hierarchy", "ssp1_26"), "PE_TLE")
  expect_equal(pat("hierarchy", "ssp3_70"), "_EST__")
  expect_equal(pat("individualist", "ssp5_85"), "PESTLE")
  expect_equal(h$n_europe[h$worldview == "individualist" & h$ssp == "ssp3_70"], 6L)
})

test_that("matched responses follow the area elements of the cell (review focus 4)", {
  reg <- data.frame(ID = c("R1", "R2", "R3", "R4"), Name = c("a", "b", "c", "d"),
                    PestleTag = c("political;legal", "", "social", "legal"), stringsAsFactors = FALSE)
  hit <- wp5_matched_responses(reg, wp5_area_elements(m, "hierarchy", "ssp2_45"))
  expect_equal(hit$ID, c("R1", "R3"))
  expect_equal(hit$matched[[1]], "political")
  expect_equal(nrow(wp5_matched_responses(reg, wp5_area_elements(m, "hierarchy", "ssp1_26"))), 1L)   # social only
  expect_equal(nrow(wp5_matched_responses(reg, wp5_area_elements(m, "egalitarian", "ssp3_70"))), 0L)
  expect_equal(nrow(wp5_matched_responses(reg[, c("ID", "Name")], "social")), 0L)                     # legacy register
  expect_equal(nrow(wp5_matched_responses(NULL, "social")), 0L)
})

test_that("a missing or corrupt file gives NULL, not an error", {
  expect_null(load_wp5_worldview_matrix(path = tempfile(fileext = ".json"), force_reload = TRUE))
  bad <- tempfile(fileext = ".json"); writeLines("{ not json", bad)
  expect_null(load_wp5_scenarios(path = bad, force_reload = TRUE))
  load_wp5_scenarios(force_reload = TRUE); load_wp5_worldview_matrix(force_reload = TRUE)   # restore the cache
})
```

Note `wp5_matched_responses(NULL, …)` must return a zero-row result: implement it as `if (is.null(register)) return(data.frame())` before the other checks (the helper code below handles data frames; add that one line).

- [ ] **Step 2: Run to verify it fails** — filter `'^wp5-scenarios$'`. Expected: FAIL, cannot open `functions/wp5_scenarios.R`.

- [ ] **Step 3: Implement.** In `constants.R` add:

```r
# WP5 WS-8: PESTLE elements (D5.1), in this order everywhere
PESTLE_CODES <- c("political", "economic", "social", "technological", "legal", "environmental")
```

Create `functions/wp5_scenarios.R` with this content (verified against the generated JSON while planning), then make two edits: replace the line `WP5_PESTLE <- c(...)` by `WP5_PESTLE <- PESTLE_CODES`, and add `if (is.null(register)) return(data.frame())` as the first line of `wp5_matched_responses()`:

```r
# functions/wp5_scenarios.R
# =============================================================================
# WP5 WS-8: D5.1 scenario x worldview reference data (spec 2026-10-16).
# Loaders for the two generated JSON files and pure helpers for the reference
# tab. The JSON is built by scripts/build_wp5_scenarios.py; do not edit by hand.
# =============================================================================

.wp5_scen_env <- new.env(parent = emptyenv())

WP5_PESTLE <- c("political", "economic", "social", "technological", "legal", "environmental")
WP5_SSPS <- c("ssp1_26", "ssp2_45", "ssp3_70", "ssp5_85")
WP5_WORLDVIEWS <- c("egalitarian", "individualist", "hierarchy")

# Read one generated file (cached); NULL + log on missing or invalid JSON
.wp5_scen_read <- function(name, key, path, force_reload) {
  if (!is.null(.wp5_scen_env[[key]]) && !force_reload) return(.wp5_scen_env[[key]])
  if (is.null(path)) {
    path <- if (exists("get_project_file", mode = "function")) get_project_file("data", name)
            else file.path("data", name)
  }
  db <- if (file.exists(path)) {
    tryCatch(jsonlite::fromJSON(path, simplifyVector = FALSE), error = function(e) NULL)
  } else NULL
  if (is.null(db) && exists("debug_log", mode = "function")) {
    debug_log(sprintf("WP5 scenarios: could not load %s", path), "WP5")
  }
  .wp5_scen_env[[key]] <- db
  db
}

#' D5.1 scenarios (4 SSP-RCPs with PESTLE x slice narratives), or NULL
load_wp5_scenarios <- function(path = NULL, force_reload = FALSE) {
  .wp5_scen_read("wp5_scenarios_ssp.json", "scenarios", path, force_reload)
}

#' D5.1 worldview x scenario matrix (72 cells), or NULL
load_wp5_worldview_matrix <- function(path = NULL, force_reload = FALSE) {
  .wp5_scen_read("wp5_worldview_matrix.json", "matrix", path, force_reload)
}

#' The six cells (one per PESTLE element) of one worldview x scenario pair, PESTLE order
wp5_cell_rows <- function(matrix, worldview, ssp) {
  cells <- Filter(function(c) identical(c$worldview, worldview) && identical(c$ssp, ssp), matrix$cells)
  cells[order(match(vapply(cells, `[[`, "", "pestle"), WP5_PESTLE))]
}

#' Heat-map summary: one row per worldview x scenario
#' @return data.frame(worldview, ssp, n_area, n_europe, pattern) where pattern
#'   is D5.1's match notation (PESTLE letter where matched, "_" where not)
wp5_heatmap_summary <- function(matrix) {
  letters6 <- c("P", "E", "S", "T", "L", "E")
  rows <- list()
  for (wv in WP5_WORLDVIEWS) for (s in WP5_SSPS) {
    cs <- wp5_cell_rows(matrix, wv, s)
    st <- vapply(cs, `[[`, "", "transformation")
    m <- vapply(cs, function(c) isTRUE(c$match), logical(1))
    rows[[length(rows) + 1L]] <- data.frame(
      worldview = wv, ssp = s, n_area = sum(st == "area"), n_europe = sum(st == "europe"),
      pattern = paste(ifelse(m, letters6, "_"), collapse = ""), stringsAsFactors = FALSE)
  }
  do.call(rbind, rows)
}

#' PESTLE elements needing area-level transformation in one cell
wp5_area_elements <- function(matrix, worldview, ssp) {
  cs <- wp5_cell_rows(matrix, worldview, ssp)
  vapply(Filter(function(c) identical(c$transformation, "area"), cs), `[[`, "", "pestle")
}

#' Register measures whose PestleTag covers at least one of `elements`
#' @param register Response register data.frame (may lack PestleTag: legacy)
#' @return the matching rows, with a list column `matched` (the covered elements)
wp5_matched_responses <- function(register, elements) {
  if (is.null(register) || !is.data.frame(register) || nrow(register) == 0 ||
      !"PestleTag" %in% names(register) || length(elements) == 0) {
    return(register[0, , drop = FALSE])
  }
  tags <- strsplit(ifelse(is.na(register$PestleTag), "", register$PestleTag), ";", fixed = TRUE)
  hit <- lapply(tags, function(t) intersect(trimws(t), elements))
  keep <- lengths(hit) > 0
  out <- register[keep, , drop = FALSE]
  out$matched <- hit[keep]
  out
}
```

In `global.R` after `source("functions/wp5_typing_lint.R", local = FALSE)` add:

```r
source("functions/wp5_scenarios.R", local = FALSE)   # WS-8: D5.1 scenario x worldview reference data
```

- [ ] **Step 4: Run tests** — `'^wp5-scenarios$'`, `'^functions-sourced-in-app$'`. Expected: PASS.

- [ ] **Step 5: Commit** — `feat(wp5): D5.1 reference data loaders and helpers (WS-8)`.

---

### Task 3: `PestleTag` on Response register measures

**Files:**
- Modify: `constants.R:831-840` (`RM_REGISTER_COLUMNS`), `functions/response_measures_schema.R` (`normalize_response_measures()` ~line 49-83; `rm_display_label()` ~104-133; `rm_translate_for_display()` ~147-160), `modules/response_module.R` (governance section ~lines 131-160; `add_response` ~518-556; and `constants.R` `RM_DISPLAY_COLUMNS` ~843-845 for the register table)
- Test: `tests/testthat/test-response-measures-schema.R`, `tests/testthat/test-response-module.R` (append)

**Interfaces:**
- Consumes: `PESTLE_CODES` (Task 2). Translation keys `modules.wp5_scenarios.pestle.<code>`, `modules.response.governance.pestle`, `modules.response.governance.pestle_hint` (added in Task 4; until then `i18n$t()` returns the key).
- Produces: register column `PestleTag`; input `rm_pestle` (multi-select of codes).

- [ ] **Step 1: Append failing tests.** To `tests/testthat/test-response-measures-schema.R`:

```r
test_that("PestleTag: added to legacy registers, unknown codes dropped, order kept", {
  legacy <- data.frame(ID = "R1", Name = "a", Type = "regulatory", stringsAsFactors = FALSE)
  out <- normalize_response_measures(legacy)
  expect_true("PestleTag" %in% names(out))
  expect_equal(out$PestleTag, "")
  tagged <- data.frame(ID = "R2", Name = "b", PestleTag = "legal;bogus;political", stringsAsFactors = FALSE)
  expect_equal(normalize_response_measures(tagged)$PestleTag, "political;legal")   # PESTLE order, unknown dropped
})

test_that("PestleTag survives a JSON save/load round trip and is a register display column", {
  reg <- normalize_response_measures(data.frame(ID = c("R1", "R2"), Name = c("a", "b"),
                                                PestleTag = c("political;legal", ""), stringsAsFactors = FALSE))
  back <- normalize_response_measures(jsonlite::fromJSON(jsonlite::toJSON(reg), simplifyVector = FALSE))
  expect_equal(back$PestleTag, c("political;legal", ""))
  expect_true("PestleTag" %in% RM_DISPLAY_COLUMNS)
})

test_that("PestleTag is shown as translated labels", {
  df <- data.frame(PestleTag = c("political;legal", ""), stringsAsFactors = FALSE)
  out <- rm_translate_for_display(df, list(t = function(k) paste0("<", k, ">")))
  expect_equal(out$PestleTag, c("<modules.wp5_scenarios.pestle.political>, <modules.wp5_scenarios.pestle.legal>", ""))
})
```

To `tests/testthat/test-response-module.R` (uses the file's existing `rm_add()` helper):

```r
test_that("the PESTLE selection is saved as codes; none selected saves '' (review focus 5)", {
  base <- list(rm_name = "Quota cut", rm_type = "regulatory", rm_target = "pressures", rm_status = "planned",
               rm_description = "", rm_mechanism = "", rm_target_element = "", rm_effectiveness = "HIGH",
               rm_feasibility = "MEDIUM", rm_cost = 4, rm_stakeholders = "", rm_barriers = "")
  m1 <- rm_add(c(base, list(rm_pestle = c("legal", "political"))))
  expect_equal(m1$PestleTag, "political;legal")
  m2 <- rm_add(base)
  expect_equal(m2$PestleTag, "")
})

test_that("the governance section offers the PESTLE multi-select", {
  ui <- as.character(real_response_measures_ui("t", make_test_i18n()))
  expect_match(ui, "t-rm_pestle", fixed = TRUE)
  expect_match(ui, 'value="environmental"', fixed = TRUE)
})
```

- [ ] **Step 2: Run to verify they fail** — `'^response-measures-schema$'`, `'^response-module$'`.

- [ ] **Step 3: Implement.**

`constants.R`: append `"PestleTag"` to `RM_REGISTER_COLUMNS` (after `"PairedWith"`, before the `Tenet_` columns).

`functions/response_measures_schema.R`, in `normalize_response_measures()` just before the final `out` (after the `Status` mapping):

```r
  out$PestleTag <- vapply(strsplit(out$PestleTag, ";", fixed = TRUE), function(t) {
    t <- trimws(t)
    bad <- setdiff(t[nzchar(t)], PESTLE_CODES)
    if (length(bad) && exists("debug_log", mode = "function")) {
      debug_log(sprintf("normalize_response_measures: dropped unknown PESTLE code(s): %s",
                        paste(bad, collapse = ", ")), "WARN")
    }
    paste(PESTLE_CODES[PESTLE_CODES %in% t], collapse = ";")
  }, character(1))
```

In `rm_display_label()`'s `key_for` switch add:

```r
      pestle = if (cd %in% PESTLE_CODES) paste0("modules.wp5_scenarios.pestle.", cd),
```

In `rm_translate_for_display()`, after the `pairs` loop:

```r
  if ("PestleTag" %in% names(df)) {
    # i18n-ref: modules.wp5_scenarios.pestle.political
    # i18n-ref: modules.wp5_scenarios.pestle.economic
    # i18n-ref: modules.wp5_scenarios.pestle.social
    # i18n-ref: modules.wp5_scenarios.pestle.technological
    # i18n-ref: modules.wp5_scenarios.pestle.legal
    # i18n-ref: modules.wp5_scenarios.pestle.environmental
    df$PestleTag <- vapply(strsplit(ifelse(is.na(df$PestleTag), "", df$PestleTag), ";", fixed = TRUE),
                           function(t) paste(rm_display_label("pestle", t, i18n), collapse = ", "), character(1))
  }
```

`modules/response_module.R`:
- In the governance `tags$details`, after the stakeholder `fluidRow(...)`, add:

```r
                fluidRow(column(12,
                  selectizeInput(ns("rm_pestle"), i18n$t("modules.response.governance.pestle"),
                    choices = setNames(PESTLE_CODES, vapply(PESTLE_CODES, function(cd)
                      i18n$t(paste0("modules.wp5_scenarios.pestle.", cd)), character(1))),
                    multiple = TRUE),
                  tags$small(class = "text-muted", i18n$t("modules.response.governance.pestle_hint"))
                )),
```

- In `observeEvent(input$add_response, ...)`'s `data.frame(...)`, after `PairedWith = input$rm_paired_with %||% "",` add `PestleTag = paste(input$rm_pestle %||% character(0), collapse = ";"),`.
- In the "Clear inputs" block add `updateSelectizeInput(session, "rm_pestle", selected = character(0))`.
- The register table (`output$response_table`, via `display_view()`) shows only `RM_DISPLAY_COLUMNS`: in `constants.R` add `"PestleTag"` to `RM_DISPLAY_COLUMNS` after `"GovernanceLevel"` (do **not** touch the priority table's `visible_cols`).

- [ ] **Step 4: Run tests** — `'^response-measures-schema$'`, `'^response-module$'`, `'^isa-responses'`. Expected: PASS.

- [ ] **Step 5: Commit** — `feat(wp5): PESTLE tag on Response register measures (WS-8)`.

---

### Task 4: Translations

**Files:**
- Create: `translations/modules/wp5_scenarios.json` (same top-level shape as `translations/modules/intervention_designer.json`: `"languages": [...]`, `"translation": {...}`)
- Modify: `translations/modules/response_governance.json`

**Interfaces:** Produces every key below in all 9 languages. English is fixed (use verbatim); write the other 8 in the style of the existing WP5 files (`intervention_designer.json`, `scenario_builder.json`), consistent within each language. Keep `%s`/`%d` placeholders where the English has them.

`modules.wp5_scenarios.*`:

| key | en |
|---|---|
| `tab_my_scenarios` | My scenarios |
| `tab_reference` | WP5 scenarios (D5.1) |
| `title` | European scenarios and worldviews (WP5, D5.1) |
| `scope_note` | These results are generic for Europe and identical for all demonstration areas. They come from a panel of WP5 analysts (D5.1, 2024), not from a stakeholder survey. |
| `unavailable` | The WP5 scenario reference data is not available. |
| `english_source` | Source text (English) |
| `warming` | Warming by 2100 |
| `conducive` | Conducive to ecosystem-based management |
| `conducive.yes` | Yes |
| `conducive.somewhat` | Somewhat |
| `conducive.no` | No |
| `heatmap_title` | Where is transformation needed? |
| `heatmap_help` | Each cell counts the PESTLE elements where the worldview diverges from the scenario in a way that needs change. Click a cell for details. |
| `area_count` | in the area |
| `europe_count` | Europe-wide |
| `pattern` | Matching elements |
| `worldview.egalitarian` | Egalitarian |
| `worldview.individualist` | Individualist |
| `worldview.hierarchy` | Hierarchy |
| `pestle.political` | Political |
| `pestle.economic` | Economic |
| `pestle.social` | Social |
| `pestle.technological` | Technological |
| `pestle.legal` | Legal |
| `pestle.environmental` | Environmental |
| `col_match` | Worldview and scenario |
| `col_rationale` | Analysts' reasoning |
| `col_worldview_view` | Worldview |
| `col_scenario` | Scenario narrative |
| `match.yes` | Match |
| `match.no` | Mismatch |
| `more_conducive` | the worldview is more conducive to ecosystem-based management than the scenario |
| `state.area` | Needed in the area |
| `state.europe` | Needed Europe-wide (outside the project's reach) |
| `state.none` | Not needed |
| `slice.general` | General |
| `slice.hrmc` | Conservation and restoration |
| `slice.sh` | Seafood harvesting |
| `slice.lh` | Tourism and leisure |
| `focus.tuscany` | focus of the Tuscan Archipelago |
| `focus.arctic` | focus of the Arctic |
| `focus.macaronesia` | focus of Macaronesia |
| `gap.ssp_not_in_futuremares` | No source text: this scenario was not covered by the FutureMARES or CERES narratives. |
| `gap.no_afmec_lines` | No source text: the AFMEC tourism narratives have no lines for this element. |
| `gap.no_source_text` | No source text for this element. |
| `guiding_question` | Guiding question |
| `strategies_title` | Strategies where worldviews do not align |
| `strategy.behavioural` | Behavioural interventions: target the people whose worldview diverges, to bring their everyday behaviour closer to what the desirable scenario needs. |
| `strategy.accepted_instruments` | System change through instruments the worldview accepts, for example tax incentives rather than cooperative agreements for individualists. |
| `strategy.limits_of_acceptable_change` | Keep changes within each worldview's limits of acceptable change, so the path stays acceptable to all worldviews. |
| `strategies_provenance` | Our summary of the D5.1 journal draft |
| `source_notes_title` | Notes on the sources |
| `source_note.summary_hierarchy_ssp` | The D5.1 summary places the Hierarchy worldview's four transformation elements under SSP1; D5.1 Table 5, the working spreadsheet and the journal draft place them under SSP2. This page follows Table 5. |
| `source_note.hierarchy_ssp2_misprint` | D5.1 prints the Hierarchy × SSP2 match pattern as "__LE"; the full pattern is "____LE". |
| `source_note.conducive_row_label` | In the working spreadsheet, the row labelled "Worldview conducive to EBM?" holds the scenario's conduciveness; it is not used here. |
| `source_note.ssp3_hierarchy_cells` | For Hierarchy × SSP3 the working spreadsheet differs from the published tables in two cells (political: worldview more conducive; environmental: "?"). This page follows the published D5.1 tables (Europe-wide transformation). |
| `source_note.generic_europe` | The scenarios are regionalised to Europe, not to individual demonstration areas, and the worldviews are generic archetypes. |
| `responses_title` | Your project's responses for these elements |
| `responses_none` | No response in your register is tagged with these PESTLE elements. |
| `responses_hint` | Tag responses with the PESTLE elements they address in the Response register (governance section). |
| `responses_not_area` | No element of this cell needs transformation in the area, so no responses are linked. |
| `responses_no_project` | Open or create a project to see which of your responses address these elements. |
| `col_response` | Response |
| `col_tags` | PESTLE elements |
| `col_kind` | Kind |
| `col_ebm_code` | EBM code |

`modules.response.governance.*` (in `response_governance.json`):

| key | en |
|---|---|
| `pestle` | PESTLE elements addressed |
| `pestle_hint` | Links this response to the WP5 scenario and worldview results (Scenario Builder, WP5 scenarios tab). |

- [ ] **Step 1: Add the keys** (new file + append to `response_governance.json`). Validate both parse: `micromamba run -n shiny python -c "import json,sys; [json.load(open(f, encoding='utf-8')) for f in sys.argv[1:]]" translations/modules/wp5_scenarios.json translations/modules/response_governance.json`.
- [ ] **Step 2: Run** the i18n audit (`missing=0 hardcoded=0`) and `'^i18n-enforcement$'`, `'^response-module$'`.
- [ ] **Step 3: Commit** — `i18n(wp5): WS-8 scenario reference and PESTLE tag keys (9 languages)`.

---

### Task 5: The reference tab

**Files:**
- Create: `modules/wp5_scenario_reference_module.R`, `tests/testthat/test-wp5-scenario-reference-module.R`
- Modify: `modules/scenario_builder_module.R` (`scenario_builder_ui()` body ~lines 88-97; `scenario_builder_server()` start ~line 104), `app.R` (`OPTIONAL_MODULES`, next to `"modules/scenario_builder_module.R"` ~line 107)

**Interfaces:**
- Consumes: Task 2 helpers and loaders, Task 4 keys, `rm_display_label()` (Task 3), `provenance_badge(type, i18n)` (existing, used by the Designer).
- Produces: `wp5_scenario_reference_ui(id, i18n)`, `wp5_scenario_reference_server(id, project_data_reactive, i18n, event_bus = NULL)`; inputs `cell` (`"<worldview>|<ssp>"`); reactive `selected()` → list(worldview, ssp).

- [ ] **Step 1: Write the failing tests** — `tests/testthat/test-wp5-scenario-reference-module.R`:

```r
# tests/testthat/test-wp5-scenario-reference-module.R
source_for_test(c("functions/wp5_scenarios.R", "modules/wp5_scenario_reference_module.R",
                  "modules/scenario_builder_module.R"))
i18n_echo <- list(t = function(k, ...) k, translator = NULL)
real_ref_server <- get("wp5_scenario_reference_server", envir = .GlobalEnv)
real_sb_ui <- get("scenario_builder_ui", envir = .GlobalEnv)   # helper-stubs.R shadows it with a 1-argument stub

proj_with <- function(register) {
  p <- create_empty_project("t")
  p$data$response_measures$measures <- register
  p
}

test_that("UI contract: renders, namespaced", {
  ui <- wp5_scenario_reference_ui("ref", i18n_echo)
  expect_true(inherits(ui, "shiny.tag") || inherits(ui, "shiny.tag.list"))
  expect_true(grepl("ref-", as.character(ui), fixed = TRUE))
  expect_true(all(c("id", "project_data_reactive", "i18n", "event_bus") %in% names(formals(wp5_scenario_reference_server))))
})

test_that("Scenario Builder UI has both tabs; the reference tab is outside the CLD gate", {
  html <- as.character(real_sb_ui("sb", i18n_echo))
  expect_match(html, "modules.wp5_scenarios.tab_my_scenarios", fixed = TRUE)
  expect_match(html, "modules.wp5_scenarios.tab_reference", fixed = TRUE)
  expect_match(html, "sb-wp5_ref-", fixed = TRUE)
})

test_that("renders with no project; default cell has area-level elements (review focus 1)", {
  testServer(real_ref_server, args = list(project_data_reactive = shiny::reactiveVal(NULL), i18n = i18n_echo), {
    expect_true(length(wp5_area_elements(load_wp5_worldview_matrix(), selected()$worldview, selected()$ssp)) > 0)
    expect_error(output$heatmap, NA)
    expect_match(as.character(output$body$html), "modules.wp5_scenarios.strategy.behavioural", fixed = TRUE)
    expect_match(as.character(output$responses$html), "modules.wp5_scenarios.responses_no_project")
  })
})

test_that("selecting a cell fills the drill-down; an empty sector slice shows its gap note", {
  testServer(real_ref_server, args = list(project_data_reactive = shiny::reactiveVal(NULL), i18n = i18n_echo), {
    session$setInputs(cell = "hierarchy|ssp2_45")
    expect_equal(selected(), list(worldview = "hierarchy", ssp = "ssp2_45"))
    html <- as.character(output$drilldown$html)
    expect_match(html, "modules.wp5_scenarios.state.area", fixed = TRUE)
    expect_match(html, "modules.wp5_scenarios.gap.ssp_not_in_futuremares", fixed = TRUE)   # SSP2 conservation
  })
})

test_that("the responses block follows the selected cell (review focus 3)", {
  reg <- normalize_response_measures(data.frame(ID = c("R1", "R2"), Name = c("Quota rules", "Habitat plan"),
    PestleTag = c("legal", "social"), stringsAsFactors = FALSE))
  testServer(real_ref_server, args = list(project_data_reactive = shiny::reactiveVal(proj_with(reg)), i18n = i18n_echo), {
    session$setInputs(cell = "hierarchy|ssp1_26")            # area: social only
    html <- as.character(output$responses$html)
    expect_match(html, "Habitat plan", fixed = TRUE)
    expect_false(grepl("Quota rules", html, fixed = TRUE))
    session$setInputs(cell = "egalitarian|ssp3_70")          # nothing at area level
    expect_match(as.character(output$responses$html), "modules.wp5_scenarios.responses_not_area", fixed = TRUE)
  })
})

test_that("legacy register without PestleTag shows the hint (review focus 1)", {
  legacy <- data.frame(ID = "R1", Name = "Old", stringsAsFactors = FALSE)
  testServer(real_ref_server, args = list(project_data_reactive = shiny::reactiveVal(proj_with(legacy)), i18n = i18n_echo), {
    session$setInputs(cell = "individualist|ssp1_26")
    expect_match(as.character(output$responses$html), "modules.wp5_scenarios.responses_none", fixed = TRUE)
  })
})

test_that("missing reference data shows the notice (review focus 2)", {
  # The loader caches only successful loads, so stub it rather than poisoning the cache
  old <- get("load_wp5_worldview_matrix", envir = .GlobalEnv)
  assign("load_wp5_worldview_matrix", function(...) NULL, envir = .GlobalEnv)
  withr::defer(assign("load_wp5_worldview_matrix", old, envir = .GlobalEnv))
  testServer(real_ref_server, args = list(project_data_reactive = shiny::reactiveVal(NULL), i18n = i18n_echo), {
    expect_match(as.character(output$body$html), "modules.wp5_scenarios.unavailable", fixed = TRUE)
  })
})
```

- [ ] **Step 2: Run to verify they fail** — `'^wp5-scenario-reference-module$'`.

- [ ] **Step 3: Implement** `modules/wp5_scenario_reference_module.R`:

```r
# modules/wp5_scenario_reference_module.R
# =============================================================================
# WP5 WS-8 (spec 2026-10-16 §4): D5.1 scenario x worldview reference tab,
# shown inside the Scenario Builder page and not behind its CLD check.
# Depends on: functions/wp5_scenarios.R, functions/response_measures_schema.R
# =============================================================================

wp5_scenario_reference_ui <- function(id, i18n) {
  tryCatch(shiny.i18n::usei18n(i18n$translator %||% i18n), error = function(e) NULL)
  ns <- NS(id)
  tagList(
    h4(class = "mt-3", i18n$t("modules.wp5_scenarios.title")),
    uiOutput(ns("body"))
  )
}

wp5_scenario_reference_server <- function(id, project_data_reactive, i18n, event_bus = NULL) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    scen <- load_wp5_scenarios()
    mat <- load_wp5_worldview_matrix()
    ok <- !is.null(scen) && !is.null(mat)

    # i18n-ref: modules.wp5_scenarios.worldview.egalitarian
    # i18n-ref: modules.wp5_scenarios.worldview.individualist
    # i18n-ref: modules.wp5_scenarios.worldview.hierarchy
    # i18n-ref: modules.wp5_scenarios.pestle.political
    # i18n-ref: modules.wp5_scenarios.pestle.economic
    # i18n-ref: modules.wp5_scenarios.pestle.social
    # i18n-ref: modules.wp5_scenarios.pestle.technological
    # i18n-ref: modules.wp5_scenarios.pestle.legal
    # i18n-ref: modules.wp5_scenarios.pestle.environmental
    # i18n-ref: modules.wp5_scenarios.state.area
    # i18n-ref: modules.wp5_scenarios.state.europe
    # i18n-ref: modules.wp5_scenarios.state.none
    # i18n-ref: modules.wp5_scenarios.conducive.yes
    # i18n-ref: modules.wp5_scenarios.conducive.somewhat
    # i18n-ref: modules.wp5_scenarios.conducive.no
    # i18n-ref: modules.wp5_scenarios.slice.general
    # i18n-ref: modules.wp5_scenarios.slice.hrmc
    # i18n-ref: modules.wp5_scenarios.slice.sh
    # i18n-ref: modules.wp5_scenarios.slice.lh
    # i18n-ref: modules.wp5_scenarios.focus.tuscany
    # i18n-ref: modules.wp5_scenarios.focus.arctic
    # i18n-ref: modules.wp5_scenarios.focus.macaronesia
    # i18n-ref: modules.wp5_scenarios.gap.ssp_not_in_futuremares
    # i18n-ref: modules.wp5_scenarios.gap.no_afmec_lines
    # i18n-ref: modules.wp5_scenarios.gap.no_source_text
    # i18n-ref: modules.wp5_scenarios.strategy.behavioural
    # i18n-ref: modules.wp5_scenarios.strategy.accepted_instruments
    # i18n-ref: modules.wp5_scenarios.strategy.limits_of_acceptable_change
    # i18n-ref: modules.wp5_scenarios.source_note.summary_hierarchy_ssp
    # i18n-ref: modules.wp5_scenarios.source_note.hierarchy_ssp2_misprint
    # i18n-ref: modules.wp5_scenarios.source_note.conducive_row_label
    # i18n-ref: modules.wp5_scenarios.source_note.ssp3_hierarchy_cells
    # i18n-ref: modules.wp5_scenarios.source_note.generic_europe
    # i18n-ref: modules.wp5_scenarios.unavailable
    # i18n-ref: modules.wp5_scenarios.scope_note
    # i18n-ref: modules.wp5_scenarios.english_source
    # i18n-ref: modules.wp5_scenarios.warming
    # i18n-ref: modules.wp5_scenarios.conducive
    # i18n-ref: modules.wp5_scenarios.heatmap_title
    # i18n-ref: modules.wp5_scenarios.heatmap_help
    # i18n-ref: modules.wp5_scenarios.area_count
    # i18n-ref: modules.wp5_scenarios.europe_count
    # i18n-ref: modules.wp5_scenarios.pattern
    # i18n-ref: modules.wp5_scenarios.col_match
    # i18n-ref: modules.wp5_scenarios.match.yes
    # i18n-ref: modules.wp5_scenarios.match.no
    # i18n-ref: modules.wp5_scenarios.more_conducive
    # i18n-ref: modules.wp5_scenarios.col_rationale
    # i18n-ref: modules.wp5_scenarios.col_worldview_view
    # i18n-ref: modules.wp5_scenarios.col_scenario
    # i18n-ref: modules.wp5_scenarios.guiding_question
    # i18n-ref: modules.wp5_scenarios.strategies_title
    # i18n-ref: modules.wp5_scenarios.strategies_provenance
    # i18n-ref: modules.wp5_scenarios.source_notes_title
    # i18n-ref: modules.wp5_scenarios.responses_title
    # i18n-ref: modules.wp5_scenarios.responses_none
    # i18n-ref: modules.wp5_scenarios.responses_hint
    # i18n-ref: modules.wp5_scenarios.responses_not_area
    # i18n-ref: modules.wp5_scenarios.responses_no_project
    # i18n-ref: modules.wp5_scenarios.col_response
    # i18n-ref: modules.wp5_scenarios.col_tags
    # i18n-ref: modules.wp5_scenarios.col_kind
    # i18n-ref: modules.wp5_scenarios.col_ebm_code
    tr <- function(k) i18n$t(paste0("modules.wp5_scenarios.", k))
    src_badge <- function() span(class = "badge badge-light ml-1", tr("english_source"))
    ssp_label <- function(sid) {
      s <- Find(function(x) identical(x$id, sid), scen$scenarios)
      paste0(s$ssp, "-RCP", s$rcp)
    }

    # Default: the first worldview x scenario with any area-level element
    default_cell <- if (ok) {
      h <- wp5_heatmap_summary(mat)
      r <- h[h$n_area > 0, , drop = FALSE][1, ]
      list(worldview = r$worldview, ssp = r$ssp)
    } else NULL
    selected <- reactive({
      v <- input$cell
      if (is.null(v) || !nzchar(v)) return(default_cell)
      p <- strsplit(v, "|", fixed = TRUE)[[1]]
      list(worldview = p[1], ssp = p[2])
    })

    output$body <- renderUI({
      if (!ok) return(div(class = "alert alert-warning", tr("unavailable")))
      tagList(
        div(class = "alert alert-info small", tr("scope_note")),
        fluidRow(lapply(scen$scenarios, function(s) column(3, bs4Card(
          title = paste0(s$ssp, "-RCP", s$rcp), width = 12, collapsible = FALSE,
          p(strong(s$name), src_badge()),
          p(class = "small", tr("warming"), ": ", sub("^<=", "\u2264", s$warming_cap), " \u00b0C"),
          p(class = "small", tr("conducive"), ": ",
            span(class = paste("badge", switch(s$ebm_conducive, yes = "badge-success", somewhat = "badge-warning",
                                               "badge-danger")), tr(paste0("conducive.", s$ebm_conducive)))),
          p(class = "small", s$global_summary, src_badge()))))),
        h5(tr("heatmap_title")), p(class = "small text-muted", tr("heatmap_help")),
        uiOutput(ns("heatmap")),
        uiOutput(ns("drilldown")),
        uiOutput(ns("responses")),
        h5(class = "mt-3", tr("strategies_title")),
        p(class = "small text-muted", tr("strategies_provenance"), provenance_badge("toolbox_extension", i18n)),
        tags$ul(lapply(unlist(mat$strategies), function(s) tags$li(tr(paste0("strategy.", s))))),
        tags$details(class = "mt-3", tags$summary(strong(tr("source_notes_title"))),
          tags$ul(class = "small", lapply(mat$source_notes, function(n) tags$li(i18n$t(n$text_key)))))
      )
    })

    output$heatmap <- renderUI({
      req(ok)
      h <- wp5_heatmap_summary(mat)
      sel <- selected()
      col_for <- function(n) c("#f8f9fa", "#cfe2ff", "#9ec5fe", "#6ea8fe", "#3d8bfd", "#0d6efd", "#0a58ca")[n + 1]
      tags$table(class = "table table-sm table-bordered text-center",
        tags$thead(tags$tr(tags$th(""), lapply(WP5_SSPS, function(s) tags$th(ssp_label(s))))),
        tags$tbody(lapply(WP5_WORLDVIEWS, function(wv) tags$tr(
          tags$th(tr(paste0("worldview.", wv))),
          lapply(WP5_SSPS, function(s) {
            r <- h[h$worldview == wv & h$ssp == s, ]
            is_sel <- identical(sel$worldview, wv) && identical(sel$ssp, s)
            tags$td(style = sprintf("cursor:pointer;background:%s;%s", col_for(r$n_area),
                                    if (is_sel) "outline:3px solid #212529;" else ""),
                    onclick = sprintf("Shiny.setInputValue('%s', '%s|%s', {priority: 'event'})", ns("cell"), wv, s),
                    div(strong(r$n_area), " ", tr("area_count")),
                    if (r$n_europe > 0) div(class = "small", "+", r$n_europe, " ", tr("europe_count")),
                    div(class = "small text-monospace", title = tr("pattern"), r$pattern))
          }))))
      )
    })

    narrative_ui <- function(scell) {
      tabs <- lapply(unlist(scen$slices), function(sl) {
        v <- scell[[sl]]
        if (identical(sl, "general") && is.null(v$text)) return(NULL)   # no general text: hide the tab (ruling 2)
        focus <- scen$slice_da_focus[[sl]]
        tabPanel(paste0(tr(paste0("slice.", sl)), if (!is.null(focus)) paste0(" (", tr(paste0("focus.", focus)), ")")),
                 if (is.null(v$text)) p(class = "small text-muted", tr(paste0("gap.", v$gap_note)))
                 else p(class = "small", style = "white-space: pre-line;", v$text))
      })
      do.call(tabsetPanel, Filter(Negate(is.null), tabs))
    }

    output$drilldown <- renderUI({
      req(ok)
      sel <- selected(); req(sel)
      wv <- Find(function(x) identical(x$id, sel$worldview), mat$worldviews)
      s <- Find(function(x) identical(x$id, sel$ssp), scen$scenarios)
      rows <- wp5_cell_rows(mat, sel$worldview, sel$ssp)
      # paste, not sprintf: a translation stub that returns the key would make sprintf warn
      bs4Card(title = paste(tr(paste0("worldview.", sel$worldview)), "×", ssp_label(sel$ssp)),
              width = 12, collapsible = FALSE,
        lapply(rows, function(c) {
          div(class = "border-bottom pb-2 mb-2",
            h6(tr(paste0("pestle.", c$pestle)), " \u2014 ",
               span(class = paste("badge", switch(c$transformation, area = "badge-primary", europe = "badge-secondary",
                                                  "badge-light")), tr(paste0("state.", c$transformation)))),
            p(class = "small", strong(tr("col_match")), ": ",
              tr(if (isTRUE(c$match)) "match.yes" else "match.no"),
              if (isTRUE(c$wv_more_conducive)) paste0(" (", tr("more_conducive"), ")")),
            p(class = "small", strong(tr("col_rationale")), ": ", c$rationale, src_badge()),
            fluidRow(
              column(5, p(class = "small", strong(tr("col_worldview_view")), src_badge()),
                     p(class = "small", style = "white-space: pre-line;", wv$pestle[[c$pestle]])),
              column(7, p(class = "small", strong(tr("col_scenario")), src_badge(), br(),
                          em(tr("guiding_question"), ": ", scen$pestle_questions[[c$pestle]])),
                     narrative_ui(s$cells[[c$pestle]]))))
        }))
    })

    output$responses <- renderUI({
      req(ok)
      sel <- selected(); req(sel)
      pd <- project_data_reactive()
      if (is.null(pd)) return(div(class = "alert alert-light small", tr("responses_no_project")))
      elements <- wp5_area_elements(mat, sel$worldview, sel$ssp)
      if (!length(elements)) return(div(class = "alert alert-light small", tr("responses_not_area")))
      reg <- pd$data$response_measures$measures
      hit <- wp5_matched_responses(if (is.data.frame(reg)) reg else NULL, elements)
      if (!nrow(hit)) return(div(class = "alert alert-light small", tr("responses_none"), br(), tr("responses_hint")))
      bs4Card(title = tr("responses_title"), width = 12, collapsible = FALSE,
        tags$table(class = "table table-sm",
          tags$thead(tags$tr(tags$th(tr("col_response")), tags$th(tr("col_tags")),
                             tags$th(tr("col_kind")), tags$th(tr("col_ebm_code")))),
          tags$tbody(lapply(seq_len(nrow(hit)), function(i) {
            tags_i <- strsplit(hit$PestleTag[i], ";", fixed = TRUE)[[1]]
            tags$tr(tags$td(hit$Name[i]),
                    tags$td(lapply(tags_i, function(t) span(
                      class = paste("badge mr-1", if (t %in% hit$matched[[i]]) "badge-primary" else "badge-light"),
                      tr(paste0("pestle.", t))))),
                    tags$td(rm_display_label("kind", hit$Kind[i] %||% "", i18n)),
                    tags$td(rm_display_label("ebm_code", hit$EbmCode[i] %||% "", i18n)))
          }))))
    })

    list(selected = selected)
  })
}
```

`modules/scenario_builder_module.R` — in `scenario_builder_ui()`, replace the part after `hr(),` (the `cld_check_ui` and `scenario_builder_main` outputs) with:

```r
    tabsetPanel(
      id = ns("sb_tabs"),
      tabPanel(i18n$t("modules.wp5_scenarios.tab_my_scenarios"),
        # Check if CLD exists
        uiOutput(ns("cld_check_ui")),
        # Main scenario builder interface (shown only if CLD exists)
        uiOutput(ns("scenario_builder_main"))),
      tabPanel(i18n$t("modules.wp5_scenarios.tab_reference"),
        # WS-8: D5.1 reference library, readable without a CLD
        if (exists("wp5_scenario_reference_ui", mode = "function"))
          wp5_scenario_reference_ui(ns("wp5_ref"), i18n))
    )
```

and at the start of `scenario_builder_server()`'s `moduleServer` body:

```r
    if (exists("wp5_scenario_reference_server", mode = "function")) {
      wp5_scenario_reference_server("wp5_ref", project_data_reactive, i18n, event_bus = event_bus)
    }
```

`app.R` — in `OPTIONAL_MODULES` add `"modules/wp5_scenario_reference_module.R",   # WS-8 D5.1 reference tab (sub-module of the Scenario Builder)` immediately **before** `"modules/scenario_builder_module.R"`.

Check: `provenance_badge()` exists (`grep -rn "^provenance_badge <- function" functions`); if its first argument values differ from `"toolbox_extension"`, use the value the Designer uses.

- [ ] **Step 4: Run tests** — `'^wp5-scenario-reference-module$'`, `'^scenario-builder-module$'`, `'^analysis-modules-batch$'`, `'^wp5-scenarios$'`; i18n audit `missing=0 hardcoded=0`.

- [ ] **Step 5: Commit** — `feat(wp5): D5.1 scenario x worldview reference tab in the Scenario Builder (WS-8)`.

---

### Task 6: Release 1.29.0 and verification

**Files:** `VERSION`, `DESCRIPTION`, `VERSION_INFO.json`, `CHANGELOG.md`

- [ ] **Step 1: Release files.** `VERSION` → `1.29.0`; `DESCRIPTION` `Version: 1.29.0`; `VERSION_INFO.json`: version 1.29.0, release_date = today, release_type minor, previous_version 1.28.0, version name "WP5 scenario × worldview reference library (D5.1)", features = the items below. `CHANGELOG.md`: under `## [Unreleased]` add `## [1.29.0] - <today>` with `### Added (WP5 scenario x worldview library — spec 2026-10-16 WS-8)`: the "WP5 scenarios (D5.1)" tab in the Scenario Builder (scenario cards, heat map of where transformation is needed, PESTLE drill-down with the worldview's and the scenario's text, strategies, source notes); the reproducible build script and the two data files; the PESTLE tag on Response register measures and the link from a heat-map cell to tagged responses. `### Notes`: results are generic for Europe; two Hierarchy × SSP3 cells differ between the working spreadsheet and the published D5.1 tables (the app follows D5.1); apply-scenario-to-CLD and the worldview self-assessment wait on WP5 partner input (Q5).
- [ ] **Step 2: Full verification** (one Rscript per chunk, foreground, never in parallel): filters `'^[a-c]'`, `'^[d-h]'`, `'^[i-l]'`, `'^[m-o]'`, `'^[p-s]'`, `'^[t-z]'` → 0 failures each (record pass/fail/skip); `micromamba run -n shiny python -m pytest scripts/tests -q` → all pass; i18n audit `missing=0 hardcoded=0`; `Rscript deployment/pre-deploy-check.R` → all pass. (The deploy ships git-tracked files only via `git archive`: the committed `data/wp5_*.json` are deployed, the untracked `WP5/` sources are not — nothing to change.)
- [ ] **Step 3: Commit** — `chore(release): 1.29.0 — WP5 scenario x worldview reference library (WS-8)`.
