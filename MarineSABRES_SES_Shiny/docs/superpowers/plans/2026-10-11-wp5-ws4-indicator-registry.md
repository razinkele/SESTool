# WP5 WS-4 Indicator Registry Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Give ISA elements an indicator (name, unit, data source) that users can type or pick from a WP5 indicator registry (D5.2), store the pick as a versioned snapshot, and warn when the registry entry has changed since the snapshot.

**Architecture:** The registry is a hand-transcribed JSON file (`data/wp5_indicators.json`). Each WP5-sourced entry cites line ranges and short verbatim quotes from a committed text extract of D5.2 v5. A test checks every quote against the extract. A cached loader (`functions/indicator_registry.R`) serves lookups and picker choices. On the element side (`functions/indicator_snapshot.R`), pure functions copy registry values into five new element columns and detect drift. The ISA module wires these in at a single choke point, `merge_saved()`, and in a project-load check modelled on the WS-3b typing lint.

**Tech Stack:** R 4.4.1, Shiny, testthat 3, jsonlite; Python (micromamba env `shiny`) only for the source-extract script.

**Spec:** `docs/superpowers/specs/2026-10-11-wp5-practical-integration-specs.md` §WS-4 (lines 253–294), with roadmap `docs/superpowers/specs/2026-05-06-wp5-integration-roadmap-design.md` §7.6 (snapshot + drift). Source audit: `docs/wp5-source-audit/2026-10-11/A_D5.2_audit.md` §5.

## Global Constraints

- P1 provenance: every registry entry carries `provenance` ∈ `wp5_source | wp5_derived | toolbox_extension | provisional`. `wp5_source` needs a `source_ref`; `wp5_derived` needs a `derivation`. The UI shows `provenance_badge()` for anything other than `wp5_source`.
- P2 codes in data: `dapsiwrm_type`, `pathway_segment`, criterion keys and `da` are stored as codes and translated only on display.
- P3 publish, don't recompute: baselines are stored as published, including obvious caption errors, which get a `caveat` note.
- P4 ordinal stays ordinal: C_01 is `scale_type: "ordinal_profile"` (0/+/++/+++); no numeric invention.
- P5 reference ≠ project data: picking copies a snapshot and records `Registry_Id` and `Registry_Version`.
- P6: module signature `(id, project_data_reactive, i18n, event_bus = NULL)`; every new `functions/*.R` is `source()`d in `global.R` as `source("functions/<file>.R", local = FALSE)`; UI chrome in all 9 languages (`en es fr de lt pt it no el`); indicator names and long-form KB text stay English with a visible English-only note.
- P7: `source_for_test()` for module files; re-bind the real server from `.GlobalEnv` before `testServer()`; never end a test in `expect_true(TRUE)`; every new project-data field gets a save/load round trip.
- i18n gates: `micromamba run -n shiny python scripts/_i18n_audit.py` must report `missing=0` and `hardcoded=0`; `test-i18n-duplicate-keys.R` (each key defined in exactly one file); `test-i18n-english-fallback.R` (no English sentence of ≥30 chars in a non-English slot). Dynamic keys need `# i18n-ref:` sentinels.
- Release: WS-3/WS-4 map to 1.23 (spec §2); the CHANGELOG entry goes under `[Unreleased]`. Do not bump `VERSION` in this plan.
- Shell: `git -C <path>`, never `cd <path> && git`. Never stage `WP5/`. Docs are committed with `git add -f` (the root `.gitignore` ignores `docs/`).

## Design rulings (made at planning time; executor follows them)

These rulings settle points where the spec is silent or contradicts the code. The executor copies each into the ledger as `Plan: Ruling: …`.

1. **Hand transcription, not a parser.** The fiches are prose, and the `-layout` extract of Tables 6, 7 and 18 interleaves columns. The JSON is written by hand. Verification is mechanical: every `wp5_source`/`wp5_derived` entry lists `source_quotes`, and each quote must appear verbatim (whitespace-normalised) in the committed extract inside the entry's `source_ref.lines` range (Task 1 test).
2. **Element column names: `Indicator`, `Indicator_Unit`, `Data_Source`, `Registry_Id`, `Registry_Version`** (constant `ISA_INDICATOR_COLUMNS`). `merge_collected_with_existing()` aligns columns by `tolower()`, and `normalize_json_project_data()` lowercases every element column on load (`data_structure.R:893`). These names lowercase to the legacy `indicator`/`indicator_unit`/`data_source` schema (`data_structure.R:456-458`), so old and new frames merge into a single column. CamelCase (`IndicatorUnit`) would create a second, orphaned column.
3. **Single choke point.** All six Standard Entry categories already pass through the module-local `merge_saved()`. It gains the indicator columns, reads the indicator inputs for live panels, and applies the snapshot. The `merge_saved(..., col_names)` call sites stay untouched.
4. **Form placement.** `build_entry_panel_ui()` renders a third row of indicator fields automatically for the six element prefixes (`gb es mpf p a d`). The six `insertUI` call sites do not change.
5. **Drift surfaces on load, not next to a form field.** Loaded elements have no form panel (`live_panel_ids()`), so a badge beside a field could never appear for the rows that can drift. Drift is a pure function (`indicator_drift()`). The module shows a warning notification on new findings only (same pattern as `warn_if_mistyped`, reset on project change), with an action link that opens a modal listing the drifted elements. The user ticks which ones to update; nothing is rewritten silently.
6. **Per-entry `revision`, not file version, drives drift.** `Registry_Version` stores the entry's integer `revision` as a string, so editing one entry doesn't flag every snapshot. The file-level `registry_version` is metadata only.
7. **Criterion roles.** Fiche roles are normalised to `WP5_RUBRIC$indicator_role` (`primary`/`supporting`): "Primary" and "Primary/Supporting" → `primary`; "Supporting", "Secondary" and "Secondary (triangulation only)" → `supporting`. The verbatim text is kept in `role_text`. Fiche aliases PO/FI become PI/FF via `wp5_criterion_code()`.
8. **Macaronesia `dapsiwrm_type` and `pathway_segment` are toolbox assignments.** D5.2 shows the pathway only in Figure 6, which is an image. Every fiche entry carries `classification_provenance: "toolbox_extension"`, listed in the partner gate. Annex 1 rows take their type from the source table through the `dapsiwrm_type_map` (a `wp5_derived` mapping).
9. **Scope.** In scope: Macaronesia (11 entries, 4 of them stubs), Posidonia Table 17 (33) with Table 18 ranges (8), Annex 1 Tuscan Table 6 and Macaronesia Table 7 rows, and Arctic (5). **MS5.1 tables are out of scope**: B§4.4 shows they overlap Annex 1 Table 6/7 (both "from WP4 / Borja et al. 2024"). Follow-up. **Responses (`isa_fields_r`) are out of scope**: separate form and loader path. Follow-up.
10. **Indicator names stay English** (P6 long-form precedent from WS-2 mechanisms). No `name_key`; the picker shows the English-only note.
11. **Scenario direction.** `direction_text` is kept verbatim (arrows survive `-enc UTF-8`). `direction` is derived by rule: ↑ without ↓ → `increase`; ↓ without ↑ → `decrease`; only → → `no_change`; both arrows, or none → `uncertain`. No `confidence` is invented; the fiche tables don't publish one.

## Review Focus

1. **A project saved before WS-4 (no indicator columns) is loaded, then an exercise is saved.** Expected: the five columns appear empty (not NA strings, not "NA"). Existing legacy lowercase `indicator` values are kept under `Indicator` and the save does not error. (Task 3, test "legacy lowercase indicator columns merge into the canonical ones".)
2. **A JSON save/load round trip lowercases column names** (`registry_id`). Expected: drift detection and snapshot still read them (case-insensitive access). (Task 5, test "drift reads lowercased columns after JSON load".)
3. **A registry entry referenced by a project is later removed or renamed.** Expected: drift reports status `missing`, the modal offers no "update" for it, and nothing crashes. (Task 5, test "missing registry ids are reported, not updated".)
4. **The user picks a registry entry, then overwrites the unit by hand.** Expected: the hand value is kept and `Registry_Id` is still set; a later re-save does not revert it to the registry value. (Task 4, test "user edits after picking survive re-save".)
5. **The registry file is missing or malformed at startup.** Expected: a warning, an empty picker (only "—"), saves still work and the indicator text fields still save. (Task 2, test "missing registry file degrades to empty picker".)
6. **An auto-save backup with one element carrying an indicator and another without is recovered.** The backup omits NA keys. Expected: both elements load. Before this fix the strict `rbind` at `data_structure.R:882` silently dropped the whole category; this was verified on 2026-10-11 and was added to the plan in review. (Task 3, test "ragged list-of-lists rows … do not drop the category".)

---

## File Structure

| Path | Responsibility |
|---|---|
| `scripts/extract_wp5_indicator_sources.py` (create) | Regenerates the committed extract from the D5.2 v5 PDF (`pdftotext -layout -enc UTF-8`), keeping only the listed line ranges and prefixing each line with its source line number. Hash-pinned like `build_wp5_mechanisms_kb.py`. Not run in CI. |
| `scripts/wp5_kb_sources/d5.2_v5_indicator_sources.md` (create, generated, committed) | Line-numbered excerpts that the transcription quotes are checked against. |
| `data/wp5_indicators.json` (create) | The registry. |
| `functions/indicator_registry.R` (create) | Cached loader + lookups + picker choices. No element data. |
| `functions/indicator_snapshot.R` (create) | Pure element-side functions: read indicator inputs, apply snapshot, detect drift, re-snapshot. |
| `constants.R` (modify) | `ISA_INDICATOR_COLUMNS`, `ISA_PREFIX_ELEMENT_KEY`, `WP5_INDICATOR_SCALE_TYPES`. |
| `global.R` (modify) | Source the two new function files after `wp5_typing_lint.R`. |
| `functions/isa_form_builders.R` (modify) | `isa_indicator_fields()`; `build_entry_panel_ui()` renders the third row for element prefixes. |
| `functions/data_structure.R` (modify) | `normalize_json_project_data()`: make the `indicator` backfill case-insensitive (do not add a duplicate column). |
| `modules/isa_data_entry_module.R` (modify) | `merge_saved()` choke point; picker auto-fill observer; drift check on load + modal. |
| `translations/modules/indicator_registry.json` (create) | Chrome keys (9 languages). |
| `tests/testthat/test-indicator-registry.R` (create) | Registry data invariants, quote verification, loader, lookups. |
| `tests/testthat/test-indicator-snapshot.R` (create) | Snapshot, drift, re-snapshot, merge round trip, module wiring. |
| `tests/run_json_loading_tests.R` (modify) | Source the two new files (the WS-3a precedent: the standalone runner sources the files that `normalize_json_project_data()` depends on). |
| `CHANGELOG.md` (modify) | `[Unreleased]` entry. |

---

### Task 1: Source extract, registry schema and Macaronesia entries

**Files:**
- Create: `scripts/extract_wp5_indicator_sources.py`, `scripts/wp5_kb_sources/d5.2_v5_indicator_sources.md` (generated), `data/wp5_indicators.json`
- Modify: `constants.R` (append after the WS-3a block)
- Test: `tests/testthat/test-indicator-registry.R`

**Interfaces:**
- Consumes: `WP5_CRITERIA$code`, `wp5_criterion_code()`, `WP5_RUBRIC$indicator_role`, `WP5_RUBRIC$pathway_segment`, `WP5_RUBRIC$direction`, `WP5_DA_CONTEXTS` (all WS-1, on main).
- Produces: `data/wp5_indicators.json` with top-level keys `schema_version`, `registry_version`, `last_updated`, `source_document`, `source_extract`, `dapsiwrm_type_map`, `entries` (JSON array). Constants `ISA_ELEMENT_KEYS <- c("drivers","activities","pressures","marine_processes","ecosystem_services","goods_benefits")` and `WP5_INDICATOR_SCALE_TYPES <- c("numeric","ordinal_profile","count","categorical")`.

- [ ] **Step 1: Write the extract script**

`scripts/extract_wp5_indicator_sources.py`:

```python
"""Regenerate scripts/wp5_kb_sources/d5.2_v5_indicator_sources.md from the D5.2 v5 PDF.

Usage: micromamba run -n shiny python -I scripts/extract_wp5_indicator_sources.py [--accept-new-source]
Keeps only RANGES, prefixing every line with 'L<n>: ' (n = line in the full
pdftotext -layout -enc UTF-8 output, which matches the A_D5.2 audit citations).
"""
import hashlib, pathlib, subprocess, sys, tempfile

ROOT = pathlib.Path(__file__).resolve().parents[1]
# Source docs are untracked and absent from worktrees: pass --wp5-dir <main checkout>/WP5
# (same convention as build_wp5_mechanisms_kb.py). Default: <app>/WP5.
_WP5 = pathlib.Path(sys.argv[sys.argv.index("--wp5-dir") + 1]) if "--wp5-dir" in sys.argv else ROOT / "WP5"
PDF = _WP5 / "D5.2" / "MarineSABRES_D5.2_Final.pdf"
OUT = ROOT / "scripts" / "wp5_kb_sources" / "d5.2_v5_indicator_sources.md"
PDF_SHA256 = ""  # pin on first run (printed); --accept-new-source rewrites it
EXPECTED_LINES = 13426
RANGES = [  # (from, to, label)
    (1120, 1130, "Arctic: WP3 'Agreements on Quotas'"),
    (1785, 1815, "Arctic: TAC vs advice, SSB/F vs reference points"),
    (1865, 1880, "Arctic: landings and prices table (Faroe Islands)"),
    (885, 900, "Arctic: MSC certification lost"),
    (3112, 3330, "Tuscan: Tables 17 and 18 (Posidonia indicators)"),
    (4985, 5005, "Macaronesia: indicator roles in economic efficiency"),
    (5118, 5132, "Macaronesia: indicator roles in equity"),
    (8285, 8440, "Annex 1 Table 6 (Tuscan DAPSIWRM indicators)"),
    (9015, 9130, "Annex 1 Table 7 (Macaronesia DAPSIWRM indicators)"),
    (10255, 13426, "Annex 8 indicator fiches"),
]

def main():
    sys.stdout.reconfigure(encoding="utf-8")
    data = PDF.read_bytes()
    sha = hashlib.sha256(data).hexdigest()
    if PDF_SHA256 and sha != PDF_SHA256 and "--accept-new-source" not in sys.argv:
        sys.exit(f"PDF hash changed: {sha} (pass --accept-new-source after review)")
    with tempfile.TemporaryDirectory() as td:
        txt = pathlib.Path(td) / "final.txt"
        subprocess.run(["pdftotext", "-layout", "-enc", "UTF-8", str(PDF), str(txt)], check=True)
        lines = txt.read_bytes().decode("utf-8", errors="replace").splitlines()
    if len(lines) != EXPECTED_LINES:
        sys.exit(f"expected {EXPECTED_LINES} lines, got {len(lines)}: line citations would shift")
    out = ["# D5.2 v5 indicator source extract", "",
           f"Generated by scripts/extract_wp5_indicator_sources.py from {PDF.name} (sha256 {sha}).",
           "Each line is prefixed with its line number in the full pdftotext -layout -enc UTF-8 output.", ""]
    for a, b, label in sorted(RANGES):
        out += [f"## L{a}-L{b}: {label}", ""]
        out += [f"L{n}: {lines[n - 1].rstrip()}" for n in range(a, b + 1)]
        out.append("")
    OUT.write_text("\n".join(out) + "\n", encoding="utf-8", newline="\n")
    print("ok", OUT, "sha256", sha)

if __name__ == "__main__":
    main()
```

- [ ] **Step 2: Run it and pin the hash**

Run from the app dir: `micromamba run -n shiny python -I scripts/extract_wp5_indicator_sources.py --wp5-dir "C:/Users/arturas.baziukas/OneDrive - ku.lt/HORIZON_EUROPE/Marine-SABRES/SESToolbox/MarineSABRES_SES_Shiny/WP5"` (the worktree has no `WP5/`; `pdftotext` is xpdf 4.00 at `C:/Program Files/Git/mingw64/bin/pdftotext.exe` — if it is not on PATH, run from Git Bash or substitute that absolute path in the `subprocess.run` call)
Expected: `ok …d5.2_v5_indicator_sources.md sha256 <hex>`. Paste the printed hex into `PDF_SHA256`, re-run, and expect the same `ok` line. Check with `grep -c "^L1" scripts/wp5_kb_sources/d5.2_v5_indicator_sources.md` that the output is non-empty, and with `grep -n "37.77%" …` that the F_01 baseline row is present.

- [ ] **Step 3: Write the failing data-invariant tests**

`tests/testthat/test-indicator-registry.R`:

```r
# tests/testthat/test-indicator-registry.R
# WS-4: WP5 indicator registry: data invariants, source-quote verification, loader, lookups.
library(testthat)

reg_path <- file.path(PROJECT_ROOT, "data", "wp5_indicators.json")
ext_path <- file.path(PROJECT_ROOT, "scripts", "wp5_kb_sources", "d5.2_v5_indicator_sources.md")
reg <- jsonlite::fromJSON(reg_path, simplifyVector = FALSE)
entries <- reg$entries
codes <- vapply(entries, function(e) e$code, character(1))
by_code <- setNames(entries, codes)

squash <- function(x) gsub("\\s+", " ", trimws(x))
extract_lines <- function() {
  l <- readLines(ext_path, encoding = "UTF-8", warn = FALSE)
  m <- regmatches(l, regexec("^L([0-9]+): ?(.*)$", l))
  keep <- lengths(m) == 3
  setNames(vapply(m[keep], `[`, character(1), 3), vapply(m[keep], `[`, character(1), 2))
}

test_that("registry header and every entry carry the required fields", {
  expect_true(all(c("schema_version", "registry_version", "entries", "dapsiwrm_type_map") %in% names(reg)))
  req <- c("code", "name", "da", "dapsiwrm_type", "unit", "scale_type", "provenance", "revision", "stub")
  for (e in entries) expect_true(all(req %in% names(e)), info = e$code)
})

test_that("codes are unique and annex codes remap per A§5.1", {
  expect_false(anyDuplicated(codes) > 0)
  remap <- c(F_02 = "F_01", F_03 = "F_02", F_04 = "F_03", M_03 = "M_02")
  for (ac in names(remap)) {
    hit <- Filter(function(e) identical(e$annex_code, ac), entries)
    expect_length(hit, 1)
    expect_equal(hit[[1]]$code, remap[[ac]], info = ac)
  }
})

test_that("Macaronesia has the 11 canonical codes; C_02, M_02, T_02, T_04 are stubs", {
  mac <- c("C_01","C_02","F_01","F_02","F_03","M_01","M_02","T_01","T_02","T_03","T_04")
  expect_true(all(mac %in% codes))
  stubs <- codes[vapply(entries, function(e) isTRUE(e$stub), logical(1))]
  expect_setequal(intersect(stubs, mac), c("C_02", "M_02", "T_02", "T_04"))
  for (s in c("C_02", "M_02", "T_02", "T_04")) expect_length(by_code[[s]]$baseline, 0)
})

test_that("T_03 records both meanings; the fiche meaning is canonical", {
  t3 <- by_code[["T_03"]]
  expect_match(t3$name, "tourism companies", ignore.case = TRUE)
  expect_match(t3$alt_meaning, "wildlife", ignore.case = TRUE)
})

test_that("vocabulary fields use valid codes", {
  for (e in entries) {
    expect_true(e$da %in% WP5_DA_CONTEXTS, info = e$code)
    expect_true(e$dapsiwrm_type %in% ISA_ELEMENT_KEYS, info = e$code)
    expect_true(e$scale_type %in% WP5_INDICATOR_SCALE_TYPES, info = e$code)
    expect_true(e$provenance %in% c("wp5_source", "wp5_derived", "toolbox_extension", "provisional"), info = e$code)
    if (!is.null(e$pathway_segment)) expect_true(e$pathway_segment %in% WP5_RUBRIC$pathway_segment, info = e$code)
    for (k in names(e$criterion_roles)) {
      expect_equal(wp5_criterion_code(k), k, info = paste(e$code, k))   # stored canonical (PI/FF, not PO/FI)
      r <- e$criterion_roles[[k]]
      if (!is.null(r)) expect_true(r$role %in% WP5_RUBRIC$indicator_role, info = paste(e$code, k))
    }
    for (s in names(e$scenario_projection)) {
      expect_true(s %in% c("S1", "S2", "S3", "S4"), info = e$code)
      expect_true(e$scenario_projection[[s]]$direction %in% WP5_RUBRIC$direction, info = paste(e$code, s))
    }
    expect_true(is.numeric(e$revision) && e$revision >= 1, info = e$code)
  }
})

test_that("provenance rules: wp5_source has source_ref; wp5_derived has derivation", {
  for (e in entries) {
    if (e$provenance == "wp5_source") {
      expect_false(is.null(e$source_ref$lines), info = e$code)
      expect_true(length(e$source_quotes) >= 1, info = e$code)
    }
    if (e$provenance == "wp5_derived") expect_true(nzchar(e$derivation %||% ""), info = e$code)
  }
})

test_that("every source quote appears verbatim inside its cited line range", {
  ex <- extract_lines()
  for (e in entries) {
    if (is.null(e$source_ref$lines)) next
    rng <- as.character(seq(e$source_ref$lines[[1]], e$source_ref$lines[[2]]))
    expect_true(all(rng %in% names(ex)), info = paste(e$code, "range not in extract"))
    hay <- squash(paste(ex[intersect(rng, names(ex))], collapse = " "))
    for (q in e$source_quotes) expect_true(grepl(squash(q), hay, fixed = TRUE), info = paste(e$code, "quote:", q))
  }
})

test_that("F_01 baseline transcribes the published 2022-24 shares", {
  b <- by_code[["F_01"]]$baseline
  vals <- setNames(vapply(b, function(x) x$value, numeric(1)), vapply(b, function(x) x$area, character(1)))
  expect_equal(unname(vals[c("Madeira", "Azores", "Canaries")]), c(37.77, 45.48, 51.24))
})
```

- [ ] **Step 4: Run to see it fail**

Run: `"/c/Program Files/R/R-4.4.1/bin/Rscript.exe" -e "testthat::test_file('tests/testthat/test-indicator-registry.R')"`
Expected: an error at the top: `cannot open file '…/data/wp5_indicators.json'`.

- [ ] **Step 5: Add the constants**

Append to `constants.R` after the WS-3a response-measure block:

```r
# ============================================================================
# WP5 INDICATOR REGISTRY (spec 2026-10-11 WS-4)
# ============================================================================
# Element frames carry these columns. Names lowercase to the legacy
# create_empty_element_df() schema (indicator / indicator_unit / data_source),
# so merge_collected_with_existing() (tolower alignment) and the JSON loader
# (lowercases element columns) keep a single column per field.
ISA_INDICATOR_COLUMNS <- c("Indicator", "Indicator_Unit", "Data_Source", "Registry_Id", "Registry_Version")
ISA_ELEMENT_KEYS <- c("drivers", "activities", "pressures", "marine_processes",
                      "ecosystem_services", "goods_benefits")
ISA_PREFIX_ELEMENT_KEY <- c(d = "drivers", a = "activities", p = "pressures", mpf = "marine_processes",
                            es = "ecosystem_services", gb = "goods_benefits")
WP5_INDICATOR_SCALE_TYPES <- c("numeric", "ordinal_profile", "count", "categorical")
```

- [ ] **Step 6: Write `data/wp5_indicators.json`: header + the two worked entries + Macaronesia**

Header (verbatim):

```json
{
  "schema_version": "1.0.0",
  "registry_version": "1.0.0",
  "last_updated": "2026-10-11",
  "description": "WP5 indicator registry (D5.2 v5): Macaronesia fiches, Posidonia Tables 17-18, Annex 1 DAPSIWRM-typed tables, Arctic descriptive indicators.",
  "source_document": "MarineSABRES D5.2 Final v5 (23 Jun 2026)",
  "source_extract": "scripts/wp5_kb_sources/d5.2_v5_indicator_sources.md",
  "dapsiwrm_type_map": {
    "provenance": "wp5_derived",
    "derivation": "Annex 1 Table 6/7 'Type' column -> ISA element key",
    "map": {
      "Human needs": "drivers", "Needs": "drivers",
      "Activity": "activities", "Activities": "activities",
      "Pressures": "pressures", "Dominant Pressures": "pressures",
      "Marine Processes and Functions": "marine_processes", "Marine Process and Functioning": "marine_processes",
      "Ecosystem Services": "ecosystem_services",
      "Goods and Benefits": "goods_benefits", "Good and Benefit": "goods_benefits"
    }
  },
  "entries": [ ]
}
```

Worked entry 1 (full fiche entry; F_01 = annex F_02, lines 10986–11163):

```json
{
  "code": "F_01", "annex_code": "F_02", "name": "Pelagic (tuna) landing share",
  "da": "macaronesia", "dapsiwrm_type": "activities", "pathway_segment": "pressure",
  "classification_provenance": "toolbox_extension",
  "definition": "Share of tuna in total commercial landings per archipelago, from aggregated landings (t) of five highly migratory tuna species; 3-year rolling average.",
  "unit": "%", "scale_type": "numeric",
  "criterion_roles": {
    "EC": {"role": "primary", "role_text": "Primary"},
    "EQ": {"role": "primary", "role_text": "Primary/Supporting"},
    "PI": {"role": "supporting", "role_text": "Supporting"},
    "FF": {"role": "supporting", "role_text": "Supporting"},
    "EE": {"role": "supporting", "role_text": "Secondary (triangulation only)"}
  },
  "baseline": [
    {"area": "Madeira", "period": "2022-2024", "value": 37.77, "unit": "%"},
    {"area": "Azores", "period": "2022-2024", "value": 45.48, "unit": "%"},
    {"area": "Canaries", "period": "2022-2024", "value": 51.24, "unit": "%"}
  ],
  "scenario_projection": {},
  "early_warning": [],
  "reference_range": null,
  "data_sources": ["Regional fisheries landings statistics (Madeira, Azores, Canaries)"],
  "data_gap": false, "stub": false, "revision": 1,
  "provenance": "wp5_source",
  "source_ref": {"document": "D5.2 v5", "section": "Annex 8, indicator F_02 (canonical F_01)", "lines": [10986, 11163]},
  "source_quotes": ["Pelagic landing share (tuna)", "37.77%", "45.48%", "51.24%", "Secondary (trian-"]
}
```

Before finishing, fill F_01's `scenario_projection` from its Table 2 synthesis (L11317–11350) and `early_warning` from "Corridor design implications" (L11564–11590), widening `source_ref.lines` to `[10986, 11590]`. Add one quote from each.

Worked entry 2 (scenario + count baseline; M_01, lines 12584–12752):

```json
{
  "code": "M_01", "annex_code": null, "name": "Number of vessel movements between islands",
  "da": "macaronesia", "dapsiwrm_type": "activities", "pathway_segment": "pressure",
  "classification_provenance": "toolbox_extension",
  "definition": "Frequency of vessel transits between the Azores, Madeira and the Canary Islands over a year.",
  "unit": "vessels per year", "scale_type": "count",
  "criterion_roles": {
    "EQ": {"role": "primary", "role_text": "Primary"},
    "PI": {"role": "primary", "role_text": "Primary"},
    "EC": {"role": "supporting", "role_text": "Secondary"},
    "FF": {"role": "supporting", "role_text": "Secondary"},
    "EE": {"role": "primary", "role_text": "Primary"}
  },
  "baseline": [
    {"area": "Azores - Madeira or Canary Islands", "period": "2023", "value": 71, "unit": "vessels"},
    {"area": "Azores - Madeira or Canary Islands", "period": "2024", "value": 64, "unit": "vessels"}
  ],
  "caveat": "The baseline table caption in the source reads 'Number of marine tourism companies' (copy-paste error); the rows are vessel counts. The criteria table header reads 'Use of T_03' (A§5.1). Madeira-Canaries data not available.",
  "scenario_projection": {
    "S1": {"assumption_text": "Stable or gradually increasing vessel movements", "direction_text": "→, slight ↑", "direction": "increase", "magnitude_text": "Unmanaged overlap with migratory routes; persistent pressure"},
    "S2": {"assumption_text": "Branding activities leading to awareness effects", "direction_text": "→", "direction": "no_change", "magnitude_text": "Improved awareness improves, but quantity mainly unchanged"},
    "S3": {"assumption_text": "Routing adjustment, slow-down areas in limited areas", "direction_text": "→, slight ↓", "direction": "decrease", "magnitude_text": "Traffic influenced by routing and spatial management"},
    "S4": {"assumption_text": "Routing measures and potentially binding obligations in high-risk areas", "direction_text": "→, ↓", "direction": "decrease", "magnitude_text": "Strongest reduction in high-risk movements; structured connectivity"}
  },
  "early_warning": [],
  "reference_range": null,
  "data_sources": ["Inter-island vessel counts (Azores-Madeira/Canaries), 2023-2024"],
  "data_gap": true, "stub": false, "revision": 1,
  "provenance": "wp5_source",
  "source_ref": {"document": "D5.2 v5", "section": "Annex 8, vessel movements fiche", "lines": [12584, 12752]},
  "source_quotes": ["Number of vessel movements between islands", "n.d.   71    64", "→, slight ↑", "Strongest reduction in high-risk"]
}
```

Note: the S2/S3 magnitude cells interleave in the layout. Before writing them, the executor re-reads L12731–12752 and confirms the row assignment against the PDF page. If it can't be confirmed, set that row's `magnitude_text` to `null` and add a `caveat`. Each quote must survive whitespace squashing (the test squashes both sides). If a quote fails because of layout spacing, shorten it to a contiguous fragment.

Transcription checklist for the remaining Macaronesia entries. Each needs a fiche entry with fields as in the worked examples, `source_ref.lines` as listed, at least two `source_quotes`, `revision: 1`, `classification_provenance: "toolbox_extension"`:

| Code | annex_code | Name (source wording) | dapsiwrm_type / segment | Criteria table | Baseline | Scenario / early warning |
|---|---|---|---|---|---|---|
| C_01 | null | Connectivity Index | marine_processes / state | L10358–10400 | L10402–10515; `scale_type: "ordinal_profile"`, baseline values as published (0/+/++/+++) as strings in `value_text` with `value: null` | Table 3 near L10884; early warning Table 5 L10916–10985 |
| F_02 | F_03 | CPUE | marine_processes / state | L11620–11652 | L11653–11695 | Step 2 L11696–11765 (directions only where tabulated) |
| F_03 | F_04 | Fishing participation & fleet capacity (commercial F_04a, charter F_04b) | activities / pressure | L12024–12061 | L12062–12158 (record a and b as separate baseline rows with `area` suffix) | Table 4 L12303–12518; early warning L12521–12583 |
| T_01 | null | Total visitors | activities / pressure | L12876–12912 (header says "Use of F_04"; add caveat) | Table 7 L12913–12960 | L13018–13040 |
| T_03 | null | Number of marine tourism companies | goods_benefits / benefit | L13174–13202 | Table 9 L13209–13260 (Canaries n/a) | L13286–13309; `alt_meaning: "Shortlist meaning: wildlife-watch participation (A§5.1); fiche meaning is canonical pending partner Q3"` |
| C_02 | null | Monitoring / implementation capacity | activities / governance_capacity; stub, `provisional`, lines [4985, 5005], quote `"C_02 (monitoring capacity)"` (see C_02 ruling below) | — | — | — |
| M_02 | M_03 | Traffic / vessel interaction with sensitive areas | pressures / pressure; stub, `provisional`, lines [5118, 5132], quote `"M_01–M_02"` | — | — | — |
| T_02 | null | Marine tourism revenue | goods_benefits / benefit; stub, `provisional`, lines [4985, 5005], quote `"T_02 (marine tourism"` | — | — | — |
| T_04 | null | Marine tourism employment | goods_benefits / benefit; stub, `provisional`, lines [4985, 5005], quote `"T_04 (employment)"` | — | — | — |

C_02 ruling (record it in the ledger): C_02 is a governance-capacity indicator, and its natural home is Responses, which are out of scope (ruling 9). Its stub uses `activities` with segment `governance_capacity` so it still appears in the picker. Cost if wrong: one stub listed under Activities until the Responses follow-up.

- [ ] **Step 7: Run the registry test; expect pass for the Macaronesia subset**

Run: `"/c/Program Files/R/R-4.4.1/bin/Rscript.exe" -e "testthat::test_file('tests/testthat/test-indicator-registry.R')"`
Expected: `[ FAIL 0 | … ]`. A quote failure names the code and quote; fix the transcription, never the test.

- [ ] **Step 8: Commit**

```bash
git -C /c/Users/arturas.baziukas/wt-ws4 add MarineSABRES_SES_Shiny/scripts/extract_wp5_indicator_sources.py MarineSABRES_SES_Shiny/scripts/wp5_kb_sources/d5.2_v5_indicator_sources.md MarineSABRES_SES_Shiny/data/wp5_indicators.json MarineSABRES_SES_Shiny/constants.R MarineSABRES_SES_Shiny/tests/testthat/test-indicator-registry.R
git -C /c/Users/arturas.baziukas/wt-ws4 commit -m "feat(wp5): indicator registry schema, source extract and Macaronesia entries (WS-4)"
```

---

### Task 2: Posidonia, Annex 1 and Arctic entries + loader and lookups

**Files:**
- Modify: `data/wp5_indicators.json`, `global.R` (after line `source("functions/wp5_typing_lint.R", local = FALSE)`), `tests/run_json_loading_tests.R`
- Create: `functions/indicator_registry.R`
- Test: `tests/testthat/test-indicator-registry.R` (append)

**Interfaces:**
- Consumes: Task 1 JSON + constants.
- Produces:
  - `load_indicator_registry(path = NULL, force_reload = FALSE)` → list(`version`, `entries` named by code); on a missing or malformed file: `warning()` + empty `entries`
  - `get_indicator(code)` → entry list or `NULL`
  - `list_indicators(da = NULL, dapsiwrm_type = NULL, segment = NULL, include_stubs = TRUE)` → data.frame(`code, name, da, dapsiwrm_type, pathway_segment, unit, stub, revision, provenance`)
  - `search_indicators(query)` → same df, case-insensitive match on code/name/unit
  - `indicator_picker_choices(element_key, i18n)` → named list for `selectInput` (first element `""` labelled "—")

- [ ] **Step 1: Append the failing tests**

```r
# ---- Task 2: other DAs + loader ---------------------------------------------
source_for_test(c("functions/indicator_registry.R"))

test_that("Posidonia: 33 Table 17 indicators, 8 with Table 18 reference ranges", {
  pos <- Filter(function(e) startsWith(e$code, "TUS_POS_"), entries)
  expect_length(pos, 33)
  with_rr <- Filter(function(e) !is.null(e$reference_range), pos)
  expect_length(with_rr, 8)
  for (e in with_rr) {
    rr <- e$reference_range
    expect_true(nzchar(rr$text), info = e$code)
    if (!is.null(rr$low) && !is.null(rr$high)) expect_lte(rr$low, rr$high)
  }
  expect_true(all(vapply(pos, function(e) e$provenance == "wp5_derived", logical(1))))  # codes are generated
})

test_that("Annex 1 rows keep the source type through the type map and flag data gaps", {
  a1 <- Filter(function(e) grepl("_A1_", e$code), entries)
  expect_gte(length(a1), 30)
  for (e in a1) expect_true(e$source_type %in% names(reg$dapsiwrm_type_map$map), info = e$code)
  for (e in a1) expect_equal(e$dapsiwrm_type, reg$dapsiwrm_type_map$map[[e$source_type]], info = e$code)
  gaps <- Filter(function(e) isTRUE(e$data_gap), a1)
  expect_gte(length(gaps), 2)                                  # e.g. energy dissipation, natural habitats
})

test_that("Arctic has the five descriptive wp5_derived entries", {
  arc <- Filter(function(e) e$da == "arctic", entries)
  expect_setequal(vapply(arc, `[[`, "", "code"),
                  c("ARC_LANDINGS", "ARC_PRICE", "ARC_TAC_VS_ADVICE", "ARC_SSB_VS_REFPOINTS", "ARC_MSC_STATUS"))
  for (e in arc) expect_equal(e$provenance, "wp5_derived")
})

test_that("loader caches and lookups filter", {
  r <- load_indicator_registry(force_reload = TRUE)
  expect_equal(r$version, reg$registry_version)
  expect_equal(get_indicator("F_01")$annex_code, "F_02")
  expect_null(get_indicator("NOPE"))
  mac <- list_indicators(da = "macaronesia")
  expect_equal(nrow(mac), 11L)
  expect_true(all(list_indicators(dapsiwrm_type = "pressures")$dapsiwrm_type == "pressures"))
  expect_equal(nrow(list_indicators(da = "macaronesia", include_stubs = FALSE)), 7L)
  expect_true("TUS_POS_SHOOT_DENSITY" %in% search_indicators("shoots")$code)
  expect_equal(nrow(search_indicators("")), 0L)
})

test_that("picker choices put the element's own type first and start with an empty choice", {
  ch <- indicator_picker_choices("pressures", make_test_i18n())
  expect_equal(unname(ch[[1]]), "")
  expect_true(length(ch) >= 3)
  first_group <- ch[[2]]
  expect_true(all(vapply(first_group, function(code) get_indicator(code)$dapsiwrm_type == "pressures", logical(1))))
})

test_that("missing registry file degrades to empty picker with a warning", {
  expect_warning(r <- load_indicator_registry(path = tempfile(fileext = ".json"), force_reload = TRUE), "registry")
  expect_length(r$entries, 0)
  expect_length(indicator_picker_choices("drivers", make_test_i18n()), 1)
  load_indicator_registry(force_reload = TRUE)                  # restore the real registry for later tests
})
```

- [ ] **Step 2: Run to see it fail**

Run: `"/c/Program Files/R/R-4.4.1/bin/Rscript.exe" -e "testthat::test_file('tests/testthat/test-indicator-registry.R')"`
Expected: error `cannot open file '…functions/indicator_registry.R'`.

- [ ] **Step 3: Transcribe the remaining entries**

Worked Posidonia entry (Table 17 L3116–3196, Table 18 L3205–3290):

```json
{
  "code": "TUS_POS_SHOOT_DENSITY", "annex_code": null, "name": "Seagrass meadow (shoot) density",
  "da": "tuscan", "dapsiwrm_type": "marine_processes", "pathway_segment": "state",
  "ecosystem_service": "Coastal protection",
  "unit": "shoots/m2", "scale_type": "numeric",
  "criterion_roles": {}, "baseline": [], "scenario_projection": {}, "early_warning": [],
  "reference_range": {"low": 400, "high": 700, "unit": "shoots/m2",
    "text": "In the Balearic/Spanish Mediterranean, values range from ~400 to 700 shoots/m2 (several Mediterranean studies); dense meadows (>=400 shoots/m2) are linked with enhanced coastal protection.",
    "reference": "Olivé et al. (2007); Duarte (2002)"},
  "data_sources": ["Field survey (shoot counts)"],
  "data_gap": false, "stub": false, "revision": 1,
  "provenance": "wp5_derived",
  "derivation": "Code generated from D5.2 Table 17 row (no code in source); values copied from Table 18.",
  "source_ref": {"document": "D5.2 v5", "section": "Tables 17-18", "lines": [3116, 3290]},
  "source_quotes": ["Seagrass meadow density", "Shoots/m²", "values range from ~400 to"]
}
```

Rules for the other 32 Posidonia rows (Table 17, eight services as in A§5.4):
- Code `TUS_POS_<SNAKE_UPPER of indicator>`.
- `ecosystem_service` = the Table 17 group.
- `dapsiwrm_type`: `marine_processes` for biophysical state rows (density, canopy, biomass, NPP, decomposition, epiphytes, trophic linkages, extent, longevity, cover, species richness, recruitment, juvenile density, habitat complexity); `ecosystem_services` for service-flow rows (wave energy reduction, sediment accretion, nutrient retention, water clarity, denitrification, pathogen filtration, organic-matter export, carbon sequestration, carbon storage, blue-carbon burial, biomass production, cellulose/lignin, decomposability, transparency, biodiversity index, charismatic species, endemic/rare species, banquettes).
- `pathway_segment`: `state` for `marine_processes` rows, `benefit` for `ecosystem_services` rows.
- `unit` as in Table 17 (ASCII `m2` in `unit`; the quote keeps `m²`).
- `reference_range` only for the 8 Table 18 rows: shoot density, canopy height (30–100 cm), root & rhizome biomass (high 1500, low null, "up to approximately 1,500 g/m2"), nutrient uptake (text only, low/high null: two nutrients), denitrification (low = high = 1.8), fish & invertebrate biomass (500–1000 g/m2), carbon sequestration (83–150 g C/m2/yr), sediment organic carbon (high 10, low null).
- Keep each Table 18 sentence verbatim in `text`.

Worked Annex 1 entry (Tuscan Table 6 L8291–8437):

```json
{
  "code": "TUS_A1_POTENTIAL_ANCHORAGES", "annex_code": null, "name": "Potential anchorages",
  "da": "tuscan", "source_type": "Pressures", "dapsiwrm_type": "pressures", "pathway_segment": "pressure",
  "element": "Vessel anchorages",
  "definition": "Proportional to the density of leisure craft vessels in the TANP.",
  "unit": "anchorages (density)", "scale_type": "numeric",
  "criterion_roles": {}, "baseline": [], "scenario_projection": {}, "early_warning": [],
  "reference_range": null,
  "data_sources": ["EMODNET"], "data_gap": false, "stub": false, "revision": 1,
  "provenance": "wp5_derived",
  "derivation": "Row of D5.2 Annex 1 Table 6 (Borja et al. 2024); dapsiwrm_type via dapsiwrm_type_map.",
  "source_ref": {"document": "D5.2 v5", "section": "Annex 1 Table 6", "lines": [8291, 8437]},
  "source_quotes": ["Potential anchor-", "of leisure craft vessels in the"]
}
```

Rules for Annex 1 rows:
- Transcribe every row of Table 6 (L8291–8437, code prefix `TUS_A1_`) and Table 7 (L9020–9127, prefix `MAC_A1_`).
- `source_type` must be the exact key used in `dapsiwrm_type_map.map`. Rows whose Type cell is blank inherit the Type of the row above.
- When the layout interleaving makes a row's Type ambiguous, open the PDF page (Table 6 is on pp. 186–188, Table 7 on pp. 202–204) and decide there. Record the decision as a `caveat` on the entry.
- "Data Gap" in the source → `data_gap: true`, `data_sources: []`.
- Quotes must be contiguous fragments as they appear on one extract line (hyphenated breaks such as `"Potential anchor-"` are fine).

Arctic entries (`wp5_derived`; derivation "Descriptive indicator assembled from Arctic NEA chapter text; D5.2 defines no formal Arctic indicator set (A§5.5)"):

| Code | Name | dapsiwrm_type / segment | Unit | lines | quotes |
|---|---|---|---|---|---|
| ARC_LANDINGS | Pelagic landings by species and country | activities / pressure | tonnes | [1865, 1880] | `"Landings (tons)"` |
| ARC_PRICE | Average first-sale price by species | goods_benefits / benefit | USD/t | [1865, 1880] | `"Avg. Price (USD/ton)"` |
| ARC_TAC_VS_ADVICE | Catch vs TAC and ICES advice (overshoot %) | pressures / pressure | % | [1785, 1815] | `"herring, and 28% for blue whiting"` |
| ARC_SSB_VS_REFPOINTS | SSB vs MSY Btrigger/Bpa/Blim; F vs FMSY/Fpa | marine_processes / state | ratio to reference point | [1785, 1815] | `"MSY Btrigger"`, `"FMSY"` |
| ARC_MSC_STATUS | MSC certification status | goods_benefits / governance_capacity | categorical (certified/suspended) | [885, 900] | `"Marine Stewardship Council (MSC) certification"` |

`ARC_MSC_STATUS` uses `scale_type: "categorical"`. The others use `numeric`. Check the 1865–1880 and 885–900 quotes against the extract; if the exact wording differs, use the extract's wording.

- [ ] **Step 4: Write `functions/indicator_registry.R`**

```r
# functions/indicator_registry.R
# WP5 indicator registry (spec 2026-10-11 WS-4): cached loader, lookups and
# picker choices. Reference data only; element snapshots live in
# functions/indicator_snapshot.R.

.indicator_registry_env <- new.env(parent = emptyenv())

load_indicator_registry <- function(path = NULL, force_reload = FALSE) {
  if (!force_reload && is.null(path) && !is.null(.indicator_registry_env$reg)) return(.indicator_registry_env$reg)
  if (is.null(path)) {
    path <- if (exists("get_project_file", mode = "function")) get_project_file("data", "wp5_indicators.json")
            else file.path("data", "wp5_indicators.json")
  }
  raw <- if (file.exists(path)) tryCatch(jsonlite::fromJSON(path, simplifyVector = FALSE), error = function(e) NULL) else NULL
  if (is.null(raw) || !is.list(raw$entries)) {
    warning(sprintf("[WP5 indicator registry] could not load %s", path))
    if (exists("debug_log", mode = "function")) debug_log(paste("indicator registry not loaded:", path), "WARN")
    reg <- list(version = NA_character_, entries = list())
  } else {
    codes <- vapply(raw$entries, function(e) as.character(e$code), character(1))
    reg <- list(version = as.character(raw$registry_version), entries = stats::setNames(raw$entries, codes))
  }
  .indicator_registry_env$reg <- reg
  reg
}

get_indicator <- function(code) {
  if (is.null(code) || length(code) != 1 || is.na(code) || !nzchar(code)) return(NULL)
  load_indicator_registry()$entries[[code]]
}

.indicator_rows <- function(entries) {
  if (length(entries) == 0) {
    return(data.frame(code = character(), name = character(), da = character(), dapsiwrm_type = character(),
                      pathway_segment = character(), unit = character(), stub = logical(),
                      revision = integer(), provenance = character(), stringsAsFactors = FALSE))
  }
  g <- function(e, f, d = NA_character_) { v <- e[[f]]; if (is.null(v)) d else as.character(v) }
  data.frame(
    code = vapply(entries, g, "", "code"), name = vapply(entries, g, "", "name"),
    da = vapply(entries, g, "", "da"), dapsiwrm_type = vapply(entries, g, "", "dapsiwrm_type"),
    pathway_segment = vapply(entries, g, "", "pathway_segment"), unit = vapply(entries, g, "", "unit"),
    stub = vapply(entries, function(e) isTRUE(e$stub), logical(1)),
    revision = vapply(entries, function(e) as.integer(e$revision %||% 1L), integer(1)),
    provenance = vapply(entries, g, "", "provenance"), stringsAsFactors = FALSE, row.names = NULL)
}

list_indicators <- function(da = NULL, dapsiwrm_type = NULL, segment = NULL, include_stubs = TRUE) {
  df <- .indicator_rows(load_indicator_registry()$entries)
  if (!is.null(da)) df <- df[df$da %in% da, , drop = FALSE]
  if (!is.null(dapsiwrm_type)) df <- df[df$dapsiwrm_type %in% dapsiwrm_type, , drop = FALSE]
  if (!is.null(segment)) df <- df[!is.na(df$pathway_segment) & df$pathway_segment %in% segment, , drop = FALSE]
  if (!include_stubs) df <- df[!df$stub, , drop = FALSE]
  rownames(df) <- NULL
  df
}

search_indicators <- function(query) {
  df <- list_indicators()
  q <- trimws(as.character(query %||% ""))
  if (!nzchar(q)) return(df[0, , drop = FALSE])
  hit <- grepl(q, df$code, fixed = TRUE, ignore.case = FALSE) |
    grepl(tolower(q), tolower(df$name), fixed = TRUE) | grepl(tolower(q), tolower(df$unit), fixed = TRUE)
  df[hit, , drop = FALSE]
}

#' Grouped choices for the per-element picker: the element's own type first.
#' Labels: "<code> · <English name> (<DA label>)"; values: codes.
indicator_picker_choices <- function(element_key, i18n) {
  none <- stats::setNames(list(""), i18n$t("modules.indicator_registry.picker_none"))
  df <- list_indicators()
  if (nrow(df) == 0) return(none)
  # i18n-ref: modules.indicator_registry.da.macaronesia
  # i18n-ref: modules.indicator_registry.da.tuscan
  # i18n-ref: modules.indicator_registry.da.arctic
  da_lab <- vapply(df$da, function(d) i18n$t(paste0("modules.indicator_registry.da.", d)), character(1))
  labels <- paste0(df$code, " · ", df$name, " (", da_lab, ")")
  own <- df$dapsiwrm_type == element_key
  out <- none
  if (any(own)) out[[i18n$t("modules.indicator_registry.picker_group_suggested")]] <-
    as.list(stats::setNames(df$code[own], labels[own]))
  if (any(!own)) out[[i18n$t("modules.indicator_registry.picker_group_other")]] <-
    as.list(stats::setNames(df$code[!own], labels[!own]))
  out
}
```

Add to `global.R` directly after `source("functions/wp5_typing_lint.R", local = FALSE)`:

```r
source("functions/indicator_registry.R", local = FALSE)
```

The picker test calls `make_test_i18n()`, which returns keys verbatim. That is enough for these tests; the real labels arrive in Task 7.

- [ ] **Step 5: Run the registry tests**

Run: `"/c/Program Files/R/R-4.4.1/bin/Rscript.exe" -e "testthat::test_file('tests/testthat/test-indicator-registry.R')"` and `"/c/Program Files/R/R-4.4.1/bin/Rscript.exe" -e "testthat::test_file('tests/testthat/test-functions-sourced-in-app.R')"`
Expected: both `[ FAIL 0 | … ]`.

- [ ] **Step 6: Commit**

```bash
git -C /c/Users/arturas.baziukas/wt-ws4 add MarineSABRES_SES_Shiny/data/wp5_indicators.json MarineSABRES_SES_Shiny/functions/indicator_registry.R MarineSABRES_SES_Shiny/global.R MarineSABRES_SES_Shiny/tests/testthat/test-indicator-registry.R
git -C /c/Users/arturas.baziukas/wt-ws4 commit -m "feat(wp5): Posidonia, Annex 1 and Arctic indicators + registry loader and lookups (WS-4)"
```

---

### Task 3: Element indicator columns survive every save and load

**Files:**
- Create: `functions/indicator_snapshot.R` (first function only)
- Modify: `functions/data_structure.R` (the backfill at ~line 907), `global.R` (source after `indicator_registry.R`), `tests/run_json_loading_tests.R`
- Test: `tests/testthat/test-indicator-snapshot.R`

**Interfaces:**
- Consumes: `ISA_INDICATOR_COLUMNS`, `merge_collected_with_existing()` (unchanged), `normalize_json_project_data()`.
- Produces: `indicator_col(df, name)` → character vector, looked up case-insensitively ("" when absent; NA → ""). Used by Tasks 4–5.

- [ ] **Step 1: Write the failing tests**

`tests/testthat/test-indicator-snapshot.R`:

```r
# tests/testthat/test-indicator-snapshot.R
# WS-4: element indicator columns, registry snapshot, drift detection, module wiring.
library(testthat)
source_for_test(c("functions/isa_form_builders.R", "functions/indicator_registry.R", "functions/indicator_snapshot.R"))

gb_cols <- c("Name", "Type", "Description", "Stakeholder", "Importance", "Trend")

test_that("indicator columns of a carried-over (loaded) row survive an exercise save", {
  existing <- data.frame(ID = "GB001", Name = "Fish catch", Type = "Provisioning", Description = "",
                         Stakeholder = "", Importance = "High", Trend = "Stable",
                         Indicator = "Landings", Indicator_Unit = "t", Data_Source = "ISTAT",
                         Registry_Id = "", Registry_Version = "", stringsAsFactors = FALSE)
  out <- merge_collected_with_existing(existing, data.frame(), "GB001", character(0),
                                       c(gb_cols, ISA_INDICATOR_COLUMNS))
  expect_equal(out$Indicator, "Landings")
  expect_equal(out$Indicator_Unit, "t")
  expect_equal(out$Data_Source, "ISTAT")
})

test_that("legacy lowercase indicator columns merge into the canonical ones (no duplicates)", {
  legacy <- data.frame(id = "GB001", name = "Fish catch", type = "Provisioning", indicator = "Landings",
                       indicator_unit = "t", data_source = "ISTAT", stringsAsFactors = FALSE)
  out <- merge_collected_with_existing(legacy, data.frame(), "GB001", character(0),
                                       c(gb_cols, ISA_INDICATOR_COLUMNS))
  expect_equal(sum(tolower(names(out)) == "indicator"), 1L)
  expect_equal(out$Indicator, "Landings")
  expect_equal(out$Registry_Id, "")
})

test_that("indicator_col reads case-insensitively and blanks NA", {
  df <- data.frame(registry_id = c("F_01", NA), stringsAsFactors = FALSE)
  expect_equal(indicator_col(df, "Registry_Id"), c("F_01", ""))
  expect_equal(indicator_col(df, "Indicator"), c("", ""))
  expect_equal(indicator_col(NULL, "Indicator"), character(0))
})

test_that("JSON normalisation does not add a second indicator column next to Indicator", {
  pd <- list(data = list(isa_data = list(goods_benefits = data.frame(
    ID = "GB001", Name = "Fish catch", Indicator = "Landings", stringsAsFactors = FALSE))))
  out <- normalize_json_project_data(pd)
  nm <- names(out$data$isa_data$goods_benefits)
  expect_equal(sum(tolower(nm) == "indicator"), 1L)
})

test_that("ragged list-of-lists rows (NA fields omitted by toJSON) do not drop the category", {
  # auto_save_module.R serialises without na = "null", so a row with an empty
  # Indicator omits the key. Before WS-4 this made do.call(rbind, ...) error at
  # data_structure.R:882 and the whole category became NULL (verified 2026-10-11).
  df <- data.frame(ID = c("D1", "D2"), Name = c("a", "b"), Indicator = c("x", NA),
                   stringsAsFactors = FALSE)
  js <- jsonlite::toJSON(list(data = list(isa_data = list(drivers = df))),
                         auto_unbox = TRUE, null = "null")          # no na = "null"
  out <- normalize_json_project_data(jsonlite::fromJSON(js, simplifyVector = FALSE))
  d <- out$data$isa_data$drivers
  expect_equal(nrow(d), 2L)
  expect_equal(indicator_col(d, "Indicator"), c("x", ""))
})
```

- [ ] **Step 2: Run to see it fail**

Run: `"/c/Program Files/R/R-4.4.1/bin/Rscript.exe" -e "testthat::test_file('tests/testthat/test-indicator-snapshot.R')"`
Expected: error `cannot open file '…functions/indicator_snapshot.R'`. Once the file exists, the normalisation test may already pass (the loader lowercases first). Read `data_structure.R:885-912` before deciding: if that test passes with no change, leave line 907 alone and ledger `Task 3: Ruling: backfill already case-safe because names are lowercased at :893 — no change`.

- [ ] **Step 3: Implement**

`functions/indicator_snapshot.R` (initial content):

```r
# functions/indicator_snapshot.R
# WS-4 element side: element frames carry ISA_INDICATOR_COLUMNS. Picking a
# registry entry copies values (snapshot) and records Registry_Id/_Version;
# drift = the registry entry's revision moved on since the snapshot.

#' Column of an element frame by name, case-insensitive; "" for absent/NA.
indicator_col <- function(df, name) {
  if (!is.data.frame(df)) return(character(0))
  hit <- which(tolower(names(df)) == tolower(name))
  if (length(hit) == 0) return(rep("", nrow(df)))
  v <- as.character(df[[hit[1]]])
  v[is.na(v)] <- ""
  v
}
```

`functions/data_structure.R` (~line 882, inside `normalize_json_project_data()`): replace the strict `do.call(rbind, lapply(el, function(x) as.data.frame(x, stringsAsFactors = FALSE)))` with a key-union bind, so rows with omitted NA fields still convert:

```r
          rows <- lapply(el, function(x) {
            x[vapply(x, is.null, logical(1))] <- NA   # JSON null -> NA, keep the key
            as.data.frame(x, stringsAsFactors = FALSE)
          })
          dplyr::bind_rows(rows)
```

(`dplyr` is already loaded by `global.R`; `bind_rows` fills missing columns with NA. Keep the surrounding `tryCatch`.)

`modules/auto_save_module.R:708`: add `na = "null"` to the `jsonlite::toJSON(...)` call, matching the other writers (`local_storage_module.R:694,764`, `server/modals.R:127`, `persistent_storage.R:421`).

`global.R`: add `source("functions/indicator_snapshot.R", local = FALSE)` after the registry line.
`tests/run_json_loading_tests.R`: next to the existing WS-3a source lines, add `source(file.path(app_root, "functions", "indicator_registry.R"))` and the same for `indicator_snapshot.R`, using whatever root variable that file already uses.

- [ ] **Step 4: Run the tests, plus the load-integrity regressions**

Run: `"/c/Program Files/R/R-4.4.1/bin/Rscript.exe" -e "for (f in c('test-indicator-snapshot','test-isa-load-save-integrity','test-load-roundtrip-integrity','test-json-project-loading')) testthat::test_file(file.path('tests/testthat', paste0(f, '.R')))"`
Expected: every file `[ FAIL 0 | … ]`. Also run `"/c/Program Files/R/R-4.4.1/bin/Rscript.exe" tests/run_json_loading_tests.R` and expect its summary to report 0 failures.

- [ ] **Step 5: Commit**

```bash
git -C /c/Users/arturas.baziukas/wt-ws4 add MarineSABRES_SES_Shiny/functions/indicator_snapshot.R MarineSABRES_SES_Shiny/functions/data_structure.R MarineSABRES_SES_Shiny/modules/auto_save_module.R MarineSABRES_SES_Shiny/global.R MarineSABRES_SES_Shiny/tests/run_json_loading_tests.R MarineSABRES_SES_Shiny/tests/testthat/test-indicator-snapshot.R
git -C /c/Users/arturas.baziukas/wt-ws4 commit -m "feat(isa): element indicator columns survive save and load (WS-4)"
```

---

### Task 4: Form fields, picker and snapshot on save

**Files:**
- Modify: `functions/isa_form_builders.R` (`build_entry_panel_ui`, new `isa_indicator_fields`), `functions/indicator_snapshot.R`, `modules/isa_data_entry_module.R` (`merge_saved` at ~line 341; six `register_remove_observer` sites get a sibling call)
- Test: `tests/testthat/test-indicator-snapshot.R` (append)

**Interfaces:**
- Consumes: `indicator_picker_choices()`, `get_indicator()`, `indicator_col()`, `ISA_PREFIX_ELEMENT_KEY`.
- Produces:
  - `isa_indicator_fields(i18n, element_key)` → list of 4 field defs (ids `indicator`, `indunit`, `datasource`, `registry`)
  - `collect_indicator_inputs(input, prefix, ids)` → df(`ID`, `Indicator`, `Indicator_Unit`, `Data_Source`, `Registry_Id`)
  - `apply_registry_snapshot(df, previous)` → df with blanks filled from the registry and `Registry_Version` set
  - `register_indicator_picker_observer(input, session, prefix, current_id)`

- [ ] **Step 1: Append the failing tests**

```r
# ---- Task 4: picker + snapshot ---------------------------------------------
fake_input <- function(...) list(...)

test_that("the entry panel renders a third row with the indicator fields and picker for element prefixes", {
  ui <- as.character(build_entry_panel_ui(shiny::NS("m"), "p", "P001",
                     isa_fields_p(make_test_i18n(), c("")), make_test_i18n()))
  for (id in c("m-p_indicator_P001", "m-p_indunit_P001", "m-p_datasource_P001", "m-p_registry_P001"))
    expect_match(ui, id, fixed = TRUE)
  ui_r <- as.character(build_entry_panel_ui(shiny::NS("m"), "zz", "Z1", list(), make_test_i18n()))
  expect_false(grepl("zz_registry_Z1", ui_r, fixed = TRUE))       # only the six element prefixes
})

test_that("collect_indicator_inputs reads the four inputs for the given ids", {
  inp <- fake_input(p_indicator_P001 = "Anchorages", p_indunit_P001 = "n", p_datasource_P001 = "EMODnet",
                    p_registry_P001 = "TUS_A1_POTENTIAL_ANCHORAGES")
  out <- collect_indicator_inputs(inp, "p", c("P001", "P002"))
  expect_equal(nrow(out), 2L)
  expect_equal(out$Registry_Id, c("TUS_A1_POTENTIAL_ANCHORAGES", ""))
  expect_equal(out$Indicator_Unit, c("n", ""))
})

test_that("picking a registry entry fills blank fields and stamps the revision", {
  df <- data.frame(ID = "A001", Name = "Fishing", Indicator = "", Indicator_Unit = "", Data_Source = "",
                   Registry_Id = "F_01", Registry_Version = "", stringsAsFactors = FALSE)
  out <- apply_registry_snapshot(df, previous = NULL)
  f1 <- get_indicator("F_01")
  expect_equal(out$Indicator, f1$name)
  expect_equal(out$Indicator_Unit, f1$unit)
  expect_equal(out$Data_Source, paste(unlist(f1$data_sources), collapse = "; "))
  expect_equal(out$Registry_Version, as.character(f1$revision))
})

test_that("user edits after picking survive re-save", {
  df <- data.frame(ID = "A001", Name = "Fishing", Indicator = "My share", Indicator_Unit = "ratio",
                   Data_Source = "", Registry_Id = "F_01", Registry_Version = "", stringsAsFactors = FALSE)
  out1 <- apply_registry_snapshot(df, previous = NULL)
  expect_equal(out1$Indicator, "My share")
  expect_equal(out1$Indicator_Unit, "ratio")
  out2 <- apply_registry_snapshot(out1, previous = out1)
  expect_equal(out2$Indicator_Unit, "ratio")
})

test_that("an existing snapshot keeps its revision on re-save; clearing the pick clears the version", {
  prev <- data.frame(ID = "A001", Registry_Id = "F_01", Registry_Version = "0", stringsAsFactors = FALSE)
  df <- data.frame(ID = "A001", Indicator = "x", Indicator_Unit = "", Data_Source = "",
                   Registry_Id = "F_01", Registry_Version = "", stringsAsFactors = FALSE)
  expect_equal(apply_registry_snapshot(df, previous = prev)$Registry_Version, "0")   # older stays detectable
  df$Registry_Id <- ""
  expect_equal(apply_registry_snapshot(df, previous = prev)$Registry_Version, "")
})

test_that("merge_saved runs the snapshot and carries indicator columns (module source)", {
  s <- paste(readLines(file.path(PROJECT_ROOT, "modules", "isa_data_entry_module.R"), warn = FALSE), collapse = "\n")
  expect_match(s, "c(col_names, ISA_INDICATOR_COLUMNS)", fixed = TRUE)
  expect_match(s, "apply_registry_snapshot(", fixed = TRUE)
  expect_match(s, "collect_indicator_inputs(input, prefix", fixed = TRUE)
  expect_equal(lengths(regmatches(s, gregexpr("register_indicator_picker_observer(", s, fixed = TRUE))), 6L)
})
```

- [ ] **Step 2: Run to see it fail**

Run: `"/c/Program Files/R/R-4.4.1/bin/Rscript.exe" -e "testthat::test_file('tests/testthat/test-indicator-snapshot.R')"`
Expected: FAIL/ERROR on `isa_indicator_fields`/`collect_indicator_inputs`/`apply_registry_snapshot` not found, and the panel test failing because the ids are missing.

- [ ] **Step 3: Implement the form side** (`functions/isa_form_builders.R`)

Add above `build_entry_panel_ui`:

```r
#' Indicator fields shown as the third row of every element entry panel (WS-4)
isa_indicator_fields <- function(i18n, element_key) {
  list(
    list(id = "registry", type = "select", width = 4,
         label = i18n$t("modules.indicator_registry.picker_label"),
         choices = indicator_picker_choices(element_key, i18n)),
    list(id = "indicator", type = "text", width = 3, label = i18n$t("modules.indicator_registry.field_indicator")),
    list(id = "indunit", type = "text", width = 2, label = i18n$t("modules.indicator_registry.field_unit")),
    list(id = "datasource", type = "text", width = 3, label = i18n$t("modules.indicator_registry.field_data_source"))
  )
}
```

In `build_entry_panel_ui`, after `row2_cols[[length(row2_cols) + 1]] <- column(...)`, add:

```r
  element_key <- if (exists("ISA_PREFIX_ELEMENT_KEY")) unname(ISA_PREFIX_ELEMENT_KEY[prefix]) else NA_character_
  row3 <- NULL
  if (length(element_key) == 1 && !is.na(element_key)) {
    row3 <- tagList(
      do.call(fluidRow, lapply(isa_indicator_fields(i18n, element_key), build_field)),
      tags$small(class = "text-muted", i18n$t("modules.indicator_registry.picker_help"))
    )
  }
```

and add `row3` as the last child of the returned `div(...)`. `build_field` must render a select with grouped (list) choices; `selectInput` accepts named lists, so nothing else changes.

- [ ] **Step 4: Implement the snapshot side** (append to `functions/indicator_snapshot.R`)

```r
.IND_INPUT_IDS <- c(Indicator = "indicator", Indicator_Unit = "indunit", Data_Source = "datasource",
                    Registry_Id = "registry")

#' Indicator form values for live panels -> df(ID, Indicator, Indicator_Unit, Data_Source, Registry_Id)
collect_indicator_inputs <- function(input, prefix, ids) {
  ids <- as.character(ids)
  cols <- lapply(.IND_INPUT_IDS, function(f) vapply(ids, function(sid) {
    v <- input[[paste0(prefix, "_", f, "_", sid)]]
    if (is.null(v) || length(v) == 0 || is.na(v[1])) "" else as.character(v[1])
  }, character(1), USE.NAMES = FALSE))
  data.frame(ID = ids, cols, stringsAsFactors = FALSE, check.names = FALSE)
}

#' Snapshot registry values into element rows (pure).
#' Blank Indicator/Unit/Source are filled from the picked entry; user text is kept.
#' Registry_Version: kept from `previous` when the same entry was already linked
#' (so an older snapshot stays detectable), else the entry's current revision;
#' cleared when no entry is picked.
apply_registry_snapshot <- function(df, previous = NULL) {
  if (!is.data.frame(df) || nrow(df) == 0) return(df)
  for (cn in ISA_INDICATOR_COLUMNS) df[[cn]] <- indicator_col(df, cn)
  df <- df[, !(tolower(names(df)) %in% tolower(ISA_INDICATOR_COLUMNS)) | names(df) %in% ISA_INDICATOR_COLUMNS, drop = FALSE]
  prev_id <- indicator_col(previous, "ID"); if (!length(prev_id)) prev_id <- indicator_col(previous, "id")
  prev_reg <- indicator_col(previous, "Registry_Id"); prev_ver <- indicator_col(previous, "Registry_Version")
  for (i in seq_len(nrow(df))) {
    code <- df$Registry_Id[i]
    if (!nzchar(code)) { df$Registry_Version[i] <- ""; next }
    e <- get_indicator(code)
    if (is.null(e)) next                                   # unknown id: leave as-is; drift reports it
    if (!nzchar(df$Indicator[i])) df$Indicator[i] <- as.character(e$name)
    if (!nzchar(df$Indicator_Unit[i])) df$Indicator_Unit[i] <- as.character(e$unit %||% "")
    if (!nzchar(df$Data_Source[i])) df$Data_Source[i] <- paste(unlist(e$data_sources), collapse = "; ")
    j <- match(df[["ID"]][i] %||% NA, prev_id)
    keep <- !is.na(j) && identical(prev_reg[j], code) && nzchar(prev_ver[j])
    df$Registry_Version[i] <- if (keep) prev_ver[j] else as.character(e$revision %||% 1L)
  }
  df
}

#' Fill the three text fields as soon as a registry entry is picked (UX only;
#' the authoritative snapshot runs on save in apply_registry_snapshot()).
register_indicator_picker_observer <- function(input, session, prefix, current_id) {
  sel_id <- paste0(prefix, "_registry_", current_id)
  shiny::observeEvent(input[[sel_id]], {
    e <- get_indicator(input[[sel_id]])
    if (is.null(e)) return(invisible(NULL))
    shiny::updateTextInput(session, paste0(prefix, "_indicator_", current_id), value = as.character(e$name))
    shiny::updateTextInput(session, paste0(prefix, "_indunit_", current_id), value = as.character(e$unit %||% ""))
    shiny::updateTextInput(session, paste0(prefix, "_datasource_", current_id),
                           value = paste(unlist(e$data_sources), collapse = "; "))
  }, ignoreInit = TRUE)
}
```

- [ ] **Step 5: Wire the module** (`modules/isa_data_entry_module.R`)

Replace the body of `merge_saved` (~line 341) with:

```r
    merge_saved <- function(key, prefix, collected, col_names,
                            linked_col = NULL, matrix_key = NULL) {
      pids <- isa_data[[paste0(prefix, "_panel_ids")]]
      live <- live_panel_ids(input, prefix, pids)
      # WS-4: indicator fields come from the third panel row for live rows;
      # loaded rows carry theirs over by ID inside merge_collected_with_existing().
      if (is.data.frame(collected) && nrow(collected) > 0 && "ID" %in% names(collected)) {
        ind <- collect_indicator_inputs(input, prefix, collected$ID)
        collected <- cbind(collected[, setdiff(names(collected), ISA_INDICATOR_COLUMNS), drop = FALSE],
                           ind[match(collected$ID, ind$ID), setdiff(names(ind), "ID"), drop = FALSE])
      }
      previous <- isa_data[[key]]
      df <- merge_collected_with_existing(previous, collected, pids, live,
                                          c(col_names, ISA_INDICATOR_COLUMNS))
      df <- apply_registry_snapshot(df, previous)
      if (!is.null(linked_col) && !is.null(matrix_key)) {
        df <- fill_linked_from_matrix(df, linked_col,
                                      isa_data$adjacency_matrices[[matrix_key]], live)
      }
      df
    }
```

In each of the six `observeEvent(input$add_<prefix>, …)` handlers, directly after `register_remove_observer(...)`, add:

```r
      register_indicator_picker_observer(input, session, "<prefix>", current_id)
```

with `<prefix>` ∈ `gb es mpf p a d` respectively.

- [ ] **Step 6: Run the tests**

Run: `"/c/Program Files/R/R-4.4.1/bin/Rscript.exe" -e "for (f in c('test-indicator-snapshot','test-isa-data-entry-module','test-isa-load-save-integrity','test-isa-form-builders')) { p <- file.path('tests/testthat', paste0(f, '.R')); if (file.exists(p)) testthat::test_file(p) }"`
Expected: all `[ FAIL 0 | … ]`.

- [ ] **Step 7: Commit**

```bash
git -C /c/Users/arturas.baziukas/wt-ws4 add MarineSABRES_SES_Shiny/functions/isa_form_builders.R MarineSABRES_SES_Shiny/functions/indicator_snapshot.R MarineSABRES_SES_Shiny/modules/isa_data_entry_module.R MarineSABRES_SES_Shiny/tests/testthat/test-indicator-snapshot.R
git -C /c/Users/arturas.baziukas/wt-ws4 commit -m "feat(isa): indicator fields with WP5 registry picker; snapshot on save (WS-4)"
```

---

### Task 5: Drift detection, notification and re-snapshot

**Files:**
- Modify: `functions/indicator_snapshot.R`, `modules/isa_data_entry_module.R` (beside `warn_if_mistyped`, and in the project-change branch)
- Test: `tests/testthat/test-indicator-snapshot.R` (append)

**Interfaces:**
- Consumes: Task 4 functions; `typing_state`-style reset point in the project observer.
- Produces:
  - `indicator_drift(isa_data)` → data.frame(`element_key, element_id, element_name, registry_id, snapshot_revision, current_revision, status`), `status` ∈ `updated | missing`
  - `apply_registry_resnapshot(df, ids)` → df where rows whose ID is in `ids` get Indicator/Unit/Source/Version overwritten from the current entry
  - Module: `warn_if_indicator_drift()`, `drift_state` env (`last`, `notified`), `input$indicator_drift_review` (action link), `input$indicator_drift_ids` (checkbox group), `input$indicator_drift_apply` (button)

- [ ] **Step 1: Append the failing tests**

```r
# ---- Task 5: drift ----------------------------------------------------------
cur_rev <- as.character(get_indicator("F_01")$revision)
isa_drift <- function(ver = "0", reg = "F_01") list(
  activities = data.frame(ID = c("A001", "A002"), Name = c("Fishing", "Tourism"),
                          Indicator = c("Tuna share", ""), Indicator_Unit = c("%", ""), Data_Source = c("", ""),
                          Registry_Id = c(reg, ""), Registry_Version = c(ver, ""), stringsAsFactors = FALSE))

test_that("an older registry_version is reported as drift; current is not", {
  d <- indicator_drift(isa_drift("0"))
  expect_equal(d$element_id, "A001")
  expect_equal(d$status, "updated")
  expect_equal(d$current_revision, cur_rev)
  expect_equal(nrow(indicator_drift(isa_drift(cur_rev))), 0L)
})

test_that("missing registry ids are reported, not updated", {
  d <- indicator_drift(isa_drift("1", reg = "GONE_99"))
  expect_equal(d$status, "missing")
  df <- apply_registry_resnapshot(isa_drift("1", reg = "GONE_99")$activities, "A001")
  expect_equal(df$Indicator[1], "Tuna share")                      # untouched
})

test_that("re-snapshot overwrites only the chosen rows and clears their drift", {
  isa <- isa_drift("0")
  isa$activities <- apply_registry_resnapshot(isa$activities, "A001")
  expect_equal(isa$activities$Indicator[1], get_indicator("F_01")$name)
  expect_equal(isa$activities$Registry_Version[1], cur_rev)
  expect_equal(nrow(indicator_drift(isa)), 0L)
})

test_that("drift reads lowercased columns after JSON load", {
  isa <- isa_drift("0"); names(isa$activities) <- tolower(names(isa$activities))
  expect_equal(indicator_drift(isa)$element_id, "A001")
})

test_that("empty or indicator-free projects give zero drift without error", {
  expect_equal(nrow(indicator_drift(list())), 0L)
  expect_equal(nrow(indicator_drift(list(drivers = data.frame(ID = "D001", Name = "x")))), 0L)
})

source_for_test(c("modules/isa_data_entry_module.R", "functions/data_structure.R", "functions/matrix_from_linked.R",
                  "functions/standard_entry_excel_import.R", "functions/project_transactions.R"))
isa_data_entry_server <- get("isa_data_entry_server", envir = .GlobalEnv)

proj_with_snapshot <- function(ver, pid = "p1") list(project_id = pid, data = list(isa_data = list(
  activities = data.frame(ID = "A001", Name = "Fishing", Sector = "", Description = "", LinkedP = "",
                          Scale = "", Frequency = "", Indicator = "Tuna share", Indicator_Unit = "%",
                          Data_Source = "", Registry_Id = "F_01", Registry_Version = ver, stringsAsFactors = FALSE),
  adjacency_matrices = list(), user_edited_matrices = list())))

test_that("loading a stale snapshot notifies once; re-snapshot via the modal clears it", {
  pdr <- shiny::reactiveVal(proj_with_snapshot("0"))
  testServer(isa_data_entry_server,
             args = list(project_data_reactive = pdr, i18n = make_test_i18n(), event_bus = NULL), {
    session$flushReact()
    expect_equal(drift_state$notified, 1L)
    expect_equal(drift_state$last, "activities:A001")
    pdr(modifyList(pdr(), list(metadata = list(saved_at = 2)))); session$flushReact()
    expect_equal(drift_state$notified, 1L)                         # same findings: silent
    session$setInputs(indicator_drift_ids = "activities:A001")
    session$setInputs(indicator_drift_apply = 1)
    expect_equal(isa_data$activities$Registry_Version, cur_rev)
    expect_length(drift_state$last, 0)
  })
})

test_that("a current snapshot records no drift; switching project resets", {
  pdr <- shiny::reactiveVal(proj_with_snapshot(cur_rev))
  testServer(isa_data_entry_server,
             args = list(project_data_reactive = pdr, i18n = make_test_i18n(), event_bus = NULL), {
    session$flushReact()
    expect_equal(drift_state$notified, 0L)
    pdr(proj_with_snapshot("0", pid = "p2")); session$flushReact()
    expect_equal(drift_state$notified, 1L)
  })
})
```

- [ ] **Step 2: Run to see it fail**

Run: `"/c/Program Files/R/R-4.4.1/bin/Rscript.exe" -e "testthat::test_file('tests/testthat/test-indicator-snapshot.R')"`
Expected: errors `could not find function "indicator_drift"` / `"apply_registry_resnapshot"`; module tests fail with `object 'drift_state' not found`.

- [ ] **Step 3: Implement the pure functions** (append to `functions/indicator_snapshot.R`)

```r
#' Registry drift across element frames (pure). status: "updated" when the
#' entry's revision is newer than the snapshot, "missing" when the id is gone.
indicator_drift <- function(isa_data) {
  empty <- data.frame(element_key = character(), element_id = character(), element_name = character(),
                      registry_id = character(), snapshot_revision = character(),
                      current_revision = character(), status = character(), stringsAsFactors = FALSE)
  if (!is.list(isa_data)) return(empty)
  out <- list()
  for (key in ISA_ELEMENT_KEYS) {
    df <- isa_data[[key]]
    if (!is.data.frame(df) || nrow(df) == 0) next
    reg <- indicator_col(df, "Registry_Id"); ver <- indicator_col(df, "Registry_Version")
    ids <- indicator_col(df, "ID"); nms <- indicator_col(df, "Name")
    for (i in which(nzchar(reg))) {
      e <- get_indicator(reg[i])
      cur <- if (is.null(e)) "" else as.character(e$revision %||% 1L)
      snap <- suppressWarnings(as.integer(ver[i]))
      status <- if (is.null(e)) "missing"
                else if (is.na(snap) || snap < as.integer(cur)) "updated" else NA_character_
      if (is.na(status)) next
      out[[length(out) + 1]] <- data.frame(element_key = key, element_id = ids[i], element_name = nms[i],
        registry_id = reg[i], snapshot_revision = ver[i], current_revision = cur, status = status,
        stringsAsFactors = FALSE)
    }
  }
  if (length(out) == 0) empty else do.call(rbind, out)
}

#' Overwrite the chosen rows from the current registry entry (user-confirmed).
apply_registry_resnapshot <- function(df, ids) {
  if (!is.data.frame(df) || nrow(df) == 0 || length(ids) == 0) return(df)
  idcol <- which(tolower(names(df)) == "id")[1]
  for (i in which(as.character(df[[idcol]]) %in% ids)) {
    e <- get_indicator(indicator_col(df, "Registry_Id")[i])
    if (is.null(e)) next
    set <- function(col, val) { h <- which(tolower(names(df)) == tolower(col)); if (!length(h)) { df[[col]] <<- ""; h <- ncol(df) }; df[i, h[1]] <<- val }
    set("Indicator", as.character(e$name))
    set("Indicator_Unit", as.character(e$unit %||% ""))
    set("Data_Source", paste(unlist(e$data_sources), collapse = "; "))
    set("Registry_Version", as.character(e$revision %||% 1L))
  }
  df
}
```

- [ ] **Step 4: Wire the module**

Directly after the `warn_if_mistyped` function definition, add:

```r
    # WS-4 registry drift: warn (never rewrite). Same dedup/reset pattern as
    # the typing lint; the action link opens a modal where the user picks the
    # elements to update from the current registry.
    drift_state <- new.env(parent = emptyenv())
    drift_state$last <- character(0)
    drift_state$notified <- 0L
    drift_state$findings <- NULL
    warn_if_indicator_drift <- function() {
      d <- indicator_drift(isolate(reactiveValuesToList(isa_data)))
      keys <- sort(if (nrow(d) > 0) paste0(d$element_key, ":", d$element_id) else character(0))
      new_keys <- setdiff(keys, drift_state$last)
      drift_state$last <- keys
      drift_state$findings <- d
      if (length(new_keys) == 0) return(invisible(NULL))
      drift_state$notified <- drift_state$notified + 1L
      fmt <- i18n$t("modules.indicator_registry.drift_found")
      msg <- if (grepl("%1$d", fmt, fixed = TRUE)) sprintf(fmt, nrow(d)) else fmt
      showNotification(msg, type = "warning", duration = 15, session = session,
                       action = actionLink(ns("indicator_drift_review"), i18n$t("modules.indicator_registry.drift_review")))
    }

    observeEvent(input$indicator_drift_review, {
      d <- drift_state$findings
      req(is.data.frame(d), nrow(d) > 0)
      upd <- d[d$status == "updated", , drop = FALSE]
      # i18n-ref: modules.indicator_registry.drift_status_updated
      # i18n-ref: modules.indicator_registry.drift_status_missing
      showModal(modalDialog(
        title = i18n$t("modules.indicator_registry.drift_title"),
        p(i18n$t("modules.indicator_registry.drift_explain")),
        checkboxGroupInput(ns("indicator_drift_ids"), NULL,
          choiceNames = paste0(upd$element_name, " (", upd$registry_id, ": ",
                               upd$snapshot_revision, " → ", upd$current_revision, ")"),
          choiceValues = paste0(upd$element_key, ":", upd$element_id)),
        if (any(d$status == "missing")) p(class = "text-muted", paste(
          i18n$t("modules.indicator_registry.drift_status_missing"),
          paste(d$element_name[d$status == "missing"], collapse = ", "))),
        footer = tagList(modalButton(i18n$t("common.buttons.cancel")),
                         actionButton(ns("indicator_drift_apply"), i18n$t("modules.indicator_registry.drift_apply"),
                                      class = "btn-primary"))))
    })

    observeEvent(input$indicator_drift_apply, {
      picks <- input$indicator_drift_ids
      if (length(picks) > 0) {
        parts <- do.call(rbind, strsplit(picks, ":", fixed = TRUE))
        for (key in unique(parts[, 1])) {
          isa_data[[key]] <- apply_registry_resnapshot(isa_data[[key]], parts[parts[, 1] == key, 2])
        }
        sync_to_project_data()
      }
      removeModal()
      d <- indicator_drift(isolate(reactiveValuesToList(isa_data)))
      drift_state$findings <- d
      drift_state$last <- sort(if (nrow(d) > 0) paste0(d$element_key, ":", d$element_id) else character(0))
    })
```

In the project-change branch, after `typing_state$last <- character(0)`, add `drift_state$last <- character(0)`. After `warn_if_mistyped()` in the load branch, add `warn_if_indicator_drift()`.

If `common.buttons.cancel` does not exist, use the existing cancel key found by `grep -rn '"common.buttons.cancel' translations/`. Record the key actually used in the ledger.

- [ ] **Step 5: Run the tests**

Run: `"/c/Program Files/R/R-4.4.1/bin/Rscript.exe" -e "for (f in c('test-indicator-snapshot','test-wp5-typing-lint','test-matrix-alignment-on-load')) testthat::test_file(file.path('tests/testthat', paste0(f, '.R')))"`
Expected: all `[ FAIL 0 | … ]`. If `session$setInputs(indicator_drift_apply = 1)` does not trigger the observer inside `testServer`, check that the modal observer isn't required: the apply observer reads only inputs. Fix the code, not the assertion.

- [ ] **Step 6: Commit**

```bash
git -C /c/Users/arturas.baziukas/wt-ws4 add MarineSABRES_SES_Shiny/functions/indicator_snapshot.R MarineSABRES_SES_Shiny/modules/isa_data_entry_module.R MarineSABRES_SES_Shiny/tests/testthat/test-indicator-snapshot.R
git -C /c/Users/arturas.baziukas/wt-ws4 commit -m "feat(isa): warn on WP5 indicator registry drift; user-confirmed re-snapshot (WS-4)"
```

---

### Task 6: Translations, provenance note, CHANGELOG

**Files:**
- Create: `translations/modules/indicator_registry.json`
- Modify: `CHANGELOG.md` (under `[Unreleased]`, below the WS-3b entry)
- Test: `tests/testthat/test-indicator-snapshot.R` (append), i18n gates

**Interfaces:**
- Consumes: every `modules.indicator_registry.*` key used in Tasks 2–5.
- Produces: the translation file (same layout as `translations/modules/wp5_vocabulary.json`: `languages` array + `translation` object).

- [ ] **Step 1: Append the failing test**

```r
test_that("every indicator-registry key used in code exists in all 9 languages", {
  tr <- jsonlite::fromJSON(file.path(PROJECT_ROOT, "translations", "modules", "indicator_registry.json"),
                           simplifyVector = FALSE)$translation
  keys <- c("picker_none", "picker_label", "picker_help", "picker_group_suggested", "picker_group_other",
            "field_indicator", "field_unit", "field_data_source", "da.macaronesia", "da.tuscan", "da.arctic",
            "drift_found", "drift_review", "drift_title", "drift_explain", "drift_apply",
            "drift_status_updated", "drift_status_missing")
  for (k in paste0("modules.indicator_registry.", keys)) {
    expect_false(is.null(tr[[k]]), info = k)
    for (l in c("en","es","fr","de","lt","pt","it","no","el")) expect_true(nzchar(tr[[k]][[l]] %||% ""), info = paste(k, l))
  }
  for (l in c("en","es","fr","de","lt","pt","it","no","el"))
    expect_true(grepl("%1$d", tr[["modules.indicator_registry.drift_found"]][[l]], fixed = TRUE), info = l)
})
```

- [ ] **Step 2: Run to see it fail**

Run: `"/c/Program Files/R/R-4.4.1/bin/Rscript.exe" -e "testthat::test_file('tests/testthat/test-indicator-snapshot.R')"`
Expected: FAIL `cannot open file …indicator_registry.json`.

- [ ] **Step 3: Write the translation file**

English source strings (translate each into es, fr, de, lt, pt, it, no, el as genuine translations, never English copies):

| key | en |
|---|---|
| picker_none | — |
| picker_label | WP5 indicator (registry) |
| picker_help | Picking a WP5 indicator copies its name, unit and data source into this element; you can edit them afterwards. Indicator names are shown in English. |
| picker_group_suggested | Suggested for this element type |
| picker_group_other | Other WP5 indicators |
| field_indicator | Indicator |
| field_unit | Unit |
| field_data_source | Data source |
| da.macaronesia | Macaronesia |
| da.tuscan | Tuscan Archipelago |
| da.arctic | Arctic NEA |
| drift_found | %1$d element indicator(s) were copied from an older version of the WP5 indicator registry. Nothing was changed. |
| drift_review | Review |
| drift_title | WP5 indicator registry updates |
| drift_explain | The registry entries below have changed since they were copied into your elements. Tick the elements to update with the current registry values. |
| drift_apply | Update selected |
| drift_status_updated | Updated in the registry |
| drift_status_missing | No longer in the registry: |

Write the file with the Write tool (never a shell heredoc). Mirror the structure of `translations/modules/wp5_vocabulary.json` exactly.

- [ ] **Step 4: CHANGELOG**

Under `## [Unreleased]`, add:

```markdown
### Added (WP5 WS-4)
- WP5 indicator registry (`data/wp5_indicators.json`): 11 Macaronesia indicators (4 stubs pending partner fiches), 33 Posidonia indicators with Table 18 reference ranges, Annex 1 DAPSIWRM-typed indicators (Tuscan, Macaronesia), 5 Arctic descriptive indicators. Every WP5 value cites D5.2 v5 line ranges, and tests check its quotes against a committed extract.
- Standard Entry: every element now has Indicator, Unit and Data source fields and a WP5 indicator picker. Picking copies the values (snapshot) and records the registry entry and revision.
- On project load, a warning appears when a copied indicator has since changed in the registry; the user chooses which elements to update.
```

- [ ] **Step 5: Run the i18n gates**

Run:
`"/c/Program Files/R/R-4.4.1/bin/Rscript.exe" -e "for (f in c('test-indicator-snapshot','test-i18n-duplicate-keys','test-i18n-enforcement','test-i18n-english-fallback')) testthat::test_file(file.path('tests/testthat', paste0(f, '.R')))"`
and `micromamba run -n shiny python -I scripts/_i18n_audit.py`
Expected: all `[ FAIL 0 | … ]`; audit `Totals: … missing=0 … hardcoded=0`.

- [ ] **Step 6: Commit**

```bash
git -C /c/Users/arturas.baziukas/wt-ws4 add MarineSABRES_SES_Shiny/translations/modules/indicator_registry.json MarineSABRES_SES_Shiny/CHANGELOG.md MarineSABRES_SES_Shiny/tests/testthat/test-indicator-snapshot.R
git -C /c/Users/arturas.baziukas/wt-ws4 commit -m "feat(i18n): WP5 indicator registry strings in 9 languages; changelog (WS-4)"
```

---

## Partner gate (carried into the final report, not a task)

- Macaronesia partner: the 7 fiche extracts, the code remap (F_02→F_01, F_03→F_02, F_04→F_03, M_03→M_02), T_03's canonical meaning, and every `classification_provenance: toolbox_extension` assignment (dapsiwrm_type + pathway_segment).
- Tuscan partner: the Table 17/18 transcription and the Annex 1 Table 6 type assignments recorded in `caveat`.
- Follow-ups: indicators on Responses; MS5.1 typed tables; translated indicator names.
