# WP5 WS-4 Indicator Registry Implementation Plan (rev 2)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Revision:** rev 2 (2026-10-11). Applies the 5-lens workflow review `wf_5580622f-839` (48 confirmed findings, deduplicated). The "Rev 2 changes" appendix at the end maps each finding id to the change.

**Goal:** Give ISA elements an indicator (name, unit, data source) that users can type or pick from a WP5 indicator registry (D5.2), store the pick as a versioned snapshot, show the entry's provenance, and warn when the registry entry has changed since the snapshot.

**Architecture:** The registry is a hand-transcribed JSON file (`data/wp5_indicators.json`). Each WP5-sourced entry cites line ranges and short verbatim quotes from a committed text extract of D5.2 v5. A test checks every quote against the extract. A cached loader (`functions/indicator_registry.R`) serves lookups and picker choices. On the element side (`functions/indicator_snapshot.R`), pure functions copy registry values into five new element columns, render the provenance badge and detect drift. The ISA module wires these in at a single choke point, `merge_saved()` (six element categories only), stamps `min_app_version` when a snapshot is saved, and runs a project-load drift check modelled on the WS-3b typing lint, with a persistent "review updates" link.

**Tech Stack:** R 4.4.1, Shiny, testthat 3, jsonlite; Python (micromamba env `shiny`) for the source-extract script and the WS-2 audit extension.

**Spec:** `docs/superpowers/specs/2026-10-11-wp5-practical-integration-specs.md` §WS-4 (lines 253–294), P1–P7, WS-0 item 4 (`stamp_min_app_version`) and WS-2 "Audit" (success_metrics vs registry); roadmap `docs/superpowers/specs/2026-05-06-wp5-integration-roadmap-design.md` §7.6 (snapshot + drift) and §7.7 (tests). Source audit: `docs/wp5-source-audit/2026-10-11/A_D5.2_audit.md` §5.

## Global Constraints

- P1 provenance: every registry entry carries `provenance` ∈ `wp5_source | wp5_derived | toolbox_extension | provisional`. `wp5_source`, `wp5_derived` and `provisional` entries need `source_ref.lines` and at least one `source_quotes` item; `wp5_derived` also needs a `derivation`. The UI shows provenance in two places: a translated suffix on every picker label that is not `wp5_source` (stubs get a stub marker instead), and `provenance_badge()` beside the picker for the selected entry (plus a `toolbox_extension` badge when `classification_provenance` is `toolbox_extension`). Badge keys live under `modules.wp5_mechanisms.provenance.*` and each key is defined in exactly one file.
- P2 codes in data: `dapsiwrm_type`, `pathway_segment`, `source_set`, criterion keys and `da` are stored as codes and translated only on display.
- P3 publish, don't recompute: baselines are stored as published, including obvious caption errors, which get a `caveat` note. Names describe what the source publishes (e.g. Arctic prices are retail midpoints, not first-sale prices).
- P4 ordinal stays ordinal: C_01 is `scale_type: "ordinal_profile"` (0/+/++/+++ in its scenario table); no numeric invention.
- P5 reference ≠ project data: picking copies a snapshot and records `Registry_Id` and `Registry_Version`.
- P6: module signature `(id, project_data_reactive, i18n, event_bus = NULL)`; every new `functions/*.R` is `source()`d in `global.R` as `source("functions/<file>.R", local = FALSE)`; UI chrome in all 9 languages (`en es fr de lt pt it no el`); indicator names and long-form KB text stay English with a visible English-only note.
- P7: `source_for_test()` for module files; re-bind the real server from `.GlobalEnv` before `testServer()`; use `shiny::reactiveVal` in tests (helper-stubs shadows `reactiveVal`); never end a test in `expect_true(TRUE)`; every new project-data field gets a save/load round trip (JSON, both `simplifyVector` modes, with and without `na = "null"`, and RDS), including a case in `tests/testthat/test-json-project-loading.R`.
- WS-0: when a save records any non-empty `Registry_Id`, the module calls `stamp_min_app_version(project, WP5_INDICATOR_MIN_APP_VERSION)` (helper at `functions/data_structure.R:1181`, signature `(project, version)`; it sets top-level `project$min_app_version` and never lowers it).
- i18n gates: `micromamba run -n shiny python -I scripts/_i18n_audit.py` must report `missing=0` and `hardcoded=0`; `test-i18n-duplicate-keys.R` (each key defined in exactly one file); `test-i18n-english-fallback.R` (no English sentence of ≥30 chars in a non-English slot). Dynamic keys need `# i18n-ref:` sentinels.
- Release: WS-3/WS-4 map to 1.23 (spec §2); the CHANGELOG entry goes under `[Unreleased]`. Do not bump `VERSION` in this plan. Consequence to carry into the final report: until the release commit bumps `VERSION` to 1.23.0, a dev build (1.22.2) shows the sticky downgrade warning (`server/project_io.R:155-162`) when it loads a project it saved with a registry pick.
- Shell: `git -C <path>`, never `cd <path> && git`. Never stage `WP5/`. Docs are committed with `git add -f` (the root `.gitignore` ignores `docs/`). Python runs as `micromamba run -n shiny python -I …`.

## Design rulings (made at planning time; executor follows them)

These rulings settle points where the spec is silent or contradicts the code. The executor copies each into the ledger as `Plan: Ruling: …`.

1. **Hand transcription, not a parser.** The fiches are prose, and the `-layout` extract of Tables 6, 7 and 18 interleaves columns. The JSON is written by hand. Verification is mechanical: every `wp5_source`/`wp5_derived`/`provisional` entry lists `source_quotes`, and each quote must appear verbatim (whitespace-normalised) in the committed extract inside the entry's `source_ref.lines` range (Task 1 test). Line numbers are `\n` line numbers of the full `pdftotext -layout -enc UTF-8` output (13426 lines; `wc -l` and `grep -n` agree). Python's `str.splitlines()` also splits on the 317 form feeds and must not be used.
2. **Element column names: `Indicator`, `Indicator_Unit`, `Data_Source`, `Registry_Id`, `Registry_Version`** (constant `ISA_INDICATOR_COLUMNS`). `merge_collected_with_existing()` aligns columns by `tolower()`, and `normalize_json_project_data()` lowercases every element column on load (`data_structure.R:893`). These names lowercase to the legacy `indicator`/`indicator_unit`/`data_source` schema (`data_structure.R:456-458`), so old and new frames merge into a single column. CamelCase (`IndicatorUnit`) would create a second, orphaned column.
3. **Single choke point, six categories.** `merge_saved()` serves seven call sites: the six element categories (`gb es mpf p a d`) and Responses (`r`, module line ~1537). The WS-4 path (indicator inputs, extended column list, snapshot) runs only when `prefix %in% names(ISA_PREFIX_ELEMENT_KEY)`; Responses keep their original column set (ruling 9). The `merge_saved(..., col_names)` call sites stay untouched.
4. **Form placement.** `build_entry_panel_ui()` renders a third row of indicator fields automatically for the six element prefixes (`gb es mpf p a d`): the picker, the three text fields, a `uiOutput` for the provenance badge, and the English-only help line. The six `insertUI` call sites do not change.
5. **Drift surfaces on load, with a persistent entry point.** Loaded elements have no form panel (`live_panel_ids()`), so drift cannot sit beside a form field. Drift is a pure function (`indicator_drift()`); it returns nothing when the registry failed to load (no "everything is missing" false alarm). The module shows a sticky warning notification (`duration = NULL`) on new findings only (same dedup as `warn_if_mistyped`, reset on project change). Its text distinguishes entries that were *updated* in the registry from entries that are *missing* from it. While unresolved findings exist, a persistent link (`output$indicator_drift_bar`, under the module header) opens the same review modal, so dismissing the toast does not lose access. The modal shows, per updated element, the element's stored values next to the current registry values (roadmap §7.6 diff) with a checkbox; missing entries are listed separately as information with no checkbox. With only missing findings the modal has a Close button and no Update button. The user ticks which elements to update; nothing is rewritten silently. Dismissing leaves the data unchanged; the link stays while findings remain, and the toast re-surfaces on the next project load (project change or new session). Same-project writes (every save re-fires the load observer) do not re-toast.
6. **Per-entry `revision`, not file version, drives drift.** `Registry_Version` stores the entry's integer `revision` as a string, so editing one entry doesn't flag every snapshot. The file-level `registry_version` is metadata only.
7. **Criterion roles.** Fiche roles are normalised to `WP5_RUBRIC$indicator_role` (`primary`/`supporting`) by one rule: role text starting with "Primary" (e.g. "Primary", "Primary/Supporting", "Primary / strong supporting") → `primary`; every other text ("Supporting", "Strong supporting", "Secondary", "Secondary (triangulation only)", "Secondary / triangulation", "Limited supporting") → `supporting`. The verbatim text is kept in `role_text`. Fiche aliases PO/FI become PI/FF via `wp5_criterion_code()`. Stubs carry `criterion_roles` keys for the criteria whose main-text narrative cites them, with `role: null` (D5.2 publishes no primary/supporting role for them) and `role_text` quoting the citing phrase; no role is invented.
8. **Classification provenance.** D5.2 shows the Macaronesia pathway only in Figure 6, which is an image, so every fiche entry's `dapsiwrm_type` and `pathway_segment` are toolbox assignments: `classification_provenance: "toolbox_extension"`, listed in the partner gate. Annex 1 rows take their `dapsiwrm_type` from the source Type column through `dapsiwrm_type_map` (a `wp5_derived` mapping) and their `pathway_segment` by rule (drivers, activities, pressures → `pressure`; marine_processes → `state`; ecosystem_services, goods_benefits → `benefit`), so they also carry `classification_provenance: "toolbox_extension"`.
9. **Scope.** In scope: Macaronesia fiche set (11 entries, 4 of them stubs), Posidonia Table 17 (33) with Table 18 ranges (8), Annex 1 Tuscan Table 6 (28 rows) and Macaronesia Table 7 (18 rows), and Arctic (5, Faroe Islands tables). **MS5.1 tables are out of scope**: B§4.4 shows they overlap Annex 1 Table 6/7 (both "from WP4 / Borja et al. 2024"). Follow-up. **Responses (`isa_fields_r`) are out of scope**: separate form and loader path; ruling 3 keeps them untouched. Follow-up.
10. **Indicator names stay English** (P6 long-form precedent from WS-2 mechanisms). No `name_key`; the picker shows the English-only note.
11. **Scenario direction.** `direction_text` is kept verbatim (arrows survive `-enc UTF-8`). `direction` is derived from the direction-symbol cell only, never from rationale text (F_01 S4's rationale "often via ↓ non-tuna more than ↑ tuna" is not the direction cell). ↔ and → both mean stable. Rule: ↑ present and no ↓ → `increase`; ↓ present and no ↑ → `decrease`; only ↔/→ (or "0", "~0") → `no_change`; both ↑ and ↓, a ±, or no symbol → `uncertain`. Stable marks next to one arrow do not change the result ("↔ / slight ↓" → `decrease`). For C_01's ordinal Δ cells (Table 3 legend 0/+/++/+++): "0" alone → `no_change`; "+", "++" or "+++" alone → `increase`; a mixed cell such as "0/+" → `uncertain`. No `confidence` is invented; the fiche tables don't publish one.
12. **`source_set`.** Every entry carries `source_set` ∈ `fiche | annex1 | posidonia | arctic` (constant `WP5_INDICATOR_SOURCE_SETS`). `fiche` = the 11 Macaronesia canonical codes, including the 4 stubs awaiting a partner fiche; `annex1` = `TUS_A1_*`/`MAC_A1_*`; `posidonia` = `TUS_POS_*`; `arctic` = `ARC_*`. `list_indicators()` filters on it, so the Macaronesia fiche count (11; 7 without stubs) is not inflated by the Table 7 rows that share `da = "macaronesia"`.
13. **Annex 1 Type assignment counts stacked labels.** The `-layout` extract stacks Table 6/7 Type labels out of horizontal alignment with their rows. Types are assigned by counting the Type labels in source order and giving them to the rows in order, never by horizontal alignment. Table 6 (28 rows): Human needs ×4, Activity ×5, Pressures ×5, Marine Processes and Functions ×4, Ecosystem Services ×5, Goods and Benefits ×5 (rows 5–9 — Global CO2 emissions, Vessel anchorages, Artisanal fishing, Vessel movements, Recreational fishing — are Activity; rows 10–14 are the MSFD pressures). Table 7 (18 rows): Needs ×1, Activities ×2, Dominant Pressures ×4, Marine Process and Functioning ×3, Ecosystem Service ×3, Good and Benefit ×5. Hyphen-split labels are joined ("Ecosystem Ser-/vice" → "Ecosystem Service").

## Review Focus

1. **A project saved before WS-4 (no indicator columns) is loaded, then an exercise is saved.** Expected: the five columns appear empty (not NA strings, not "NA"). Existing legacy lowercase `indicator` values are kept under `Indicator` and the save does not error. (Task 3, test "legacy lowercase indicator columns merge into the canonical ones".)
2. **A JSON or RDS save/load round trip lowercases column names** (`registry_id`). Expected: values survive in both `simplifyVector` modes and with or without `na = "null"`; drift detection and snapshot still read them (case-insensitive access). (Task 3, `test-json-project-loading.R` "WS-4 indicator columns survive JSON and RDS round trips"; Task 5, "drift reads lowercased columns after JSON load".)
3. **A registry entry referenced by a project is later removed or renamed.** Expected: drift reports status `missing`, the modal lists it without a checkbox, the notification says "no longer in the registry" (not "older version"), and nothing crashes even when every finding is missing and the user submits a bogus pick. (Task 5, "missing registry ids are reported, not updated" and "a missing-only drift review opens and applies without error".)
4. **The user picks a registry entry, then overwrites a field by hand.** Expected: the hand value is kept and `Registry_Id` is still set; a re-save, and a save → RDS → reload → re-save, do not revert it. (Task 4, "user edits after picking survive re-save" and the testServer test "picking in the panel saves the snapshot; hand edits survive save, reload and re-save".)
5. **The registry file is missing or malformed at startup.** Expected: a warning, an empty picker (only "—"), saves still work, the indicator text fields still save, and drift is skipped entirely (no element is flagged missing). (Task 2, "missing registry file degrades to empty picker"; Task 5, "an unavailable registry reports no drift".)
6. **An auto-save backup with one element carrying an indicator and another without is recovered.** The backup omits NA keys. Expected: both elements load. Before this fix the strict `rbind` at `data_structure.R:882` silently dropped the whole category (verified 2026-10-11). (Task 3, "ragged list-of-lists rows … do not drop the category".)
7. **The user dismisses the drift toast.** Expected: data unchanged, the persistent link still opens the review, a same-project save does not re-toast, and a new session re-notifies. (Task 5, "dismissing keeps the data and the review link; a new session re-notifies".)
8. **Picker provenance.** Expected: stubs carry a stub marker, `wp5_derived`/`provisional` entries carry a translated provenance suffix, `wp5_source` entries carry none, and the badge beside the picker shows the selected entry's provenance (and `toolbox_extension` for toolbox-assigned classifications). No raw `modules.wp5_mechanisms.provenance.*` key reaches the UI in any language. (Task 2 picker label test; Task 4 badge test; Task 6 key test.)
9. **Responses stay untouched.** Expected: saving a Response adds no indicator column. (Task 4, "responses gain no indicator columns".)

---

## File Structure

| Path | Responsibility |
|---|---|
| `scripts/extract_wp5_indicator_sources.py` (create) | Regenerates the committed extract from the D5.2 v5 PDF (`pdftotext -layout -enc UTF-8`), splitting on `\n` only, keeping the listed line ranges, stripping form feeds and prefixing each line with its source line number. Hash-pinned like `build_wp5_mechanisms_kb.py`. Not run in CI. |
| `scripts/wp5_kb_sources/d5.2_v5_indicator_sources.md` (create, generated, committed) | Line-numbered excerpts that the transcription quotes are checked against. |
| `data/wp5_indicators.json` (create) | The registry. |
| `functions/indicator_registry.R` (create) | Cached loader + lookups + picker choices (with provenance/stub label suffixes). No element data. |
| `functions/indicator_snapshot.R` (create) | Pure element-side functions: read indicator inputs, apply snapshot, provenance badge UI, snapshot detection for the version stamp, drift detection, re-snapshot. |
| `constants.R` (modify) | `ISA_INDICATOR_COLUMNS`, `ISA_ELEMENT_KEYS`, `ISA_PREFIX_ELEMENT_KEY`, `WP5_INDICATOR_SCALE_TYPES`, `WP5_INDICATOR_SOURCE_SETS`, `WP5_INDICATOR_MIN_APP_VERSION`. |
| `global.R` (modify) | Source the two new function files after `wp5_typing_lint.R`. |
| `functions/isa_form_builders.R` (modify) | `isa_indicator_fields()`; `build_entry_panel_ui()` renders the third row for element prefixes. |
| `functions/data_structure.R` (modify) | `normalize_json_project_data()`: key-union bind of list-of-lists element rows. |
| `functions/ui_components.R` (modify) | `# i18n-ref:` sentinels for the two new provenance keys in `provenance_badge()`. |
| `modules/auto_save_module.R` (modify) | `na = "null"` in the auto-save `toJSON()` call. |
| `modules/isa_data_entry_module.R` (modify) | `merge_saved()` choke point (six categories); picker observers; `min_app_version` stamp in `sync_to_project_data()`; drift check on load, persistent link, review modal. |
| `translations/modules/indicator_registry.json` (create) | Chrome keys (9 languages). |
| `translations/modules/wp5_mechanisms.json` (modify) | Two new badge keys: `modules.wp5_mechanisms.provenance.toolbox_extension`, `.provisional`. |
| `scripts/kb_audit/audit_wp5_mechanisms.py` (modify) | Fail on `success_metrics` codes absent from `data/wp5_indicators.json` (spec WS-2 Audit). |
| `scripts/kb_audit/test_build_wp5_mechanisms_kb.py` (modify) | pytest for the new audit rule. |
| `tests/testthat/test-indicator-registry.R` (create) | Registry data invariants, quote verification, loader, lookups, picker labels. |
| `tests/testthat/test-indicator-snapshot.R` (create) | Snapshot, badge, drift, re-snapshot, merge round trip, module behaviour (testServer). |
| `tests/testthat/test-json-project-loading.R` (modify) | WS-4 JSON/RDS round-trip case (P7). |
| `tests/testthat/test-isa-form-builders-multiselect.R` (modify) | Narrow the blank-option assertion to the Linked select (the new picker legitimately has a blank first choice). |
| `tests/run_json_loading_tests.R` (modify) | Source the two new files (the WS-3a precedent: the standalone runner sources the files that the JSON tests depend on). |
| `CHANGELOG.md` (modify) | `[Unreleased]` entry. |

---

### Task 1: Source extract, registry schema and Macaronesia entries

**Files:**
- Create: `scripts/extract_wp5_indicator_sources.py`, `scripts/wp5_kb_sources/d5.2_v5_indicator_sources.md` (generated), `data/wp5_indicators.json`
- Modify: `constants.R` (append after the WS-3a block)
- Test: `tests/testthat/test-indicator-registry.R`

**Interfaces:**
- Consumes: `WP5_CRITERIA$code`, `wp5_criterion_code()`, `WP5_RUBRIC$indicator_role`, `WP5_RUBRIC$pathway_segment`, `WP5_RUBRIC$direction` (`increase decrease no_change uncertain`), `WP5_DA_CONTEXTS` (all WS-1, on main).
- Produces: `data/wp5_indicators.json` with top-level keys `schema_version`, `registry_version`, `last_updated`, `source_document`, `source_extract`, `dapsiwrm_type_map`, `entries` (JSON array). Constants `ISA_INDICATOR_COLUMNS`, `ISA_ELEMENT_KEYS <- c("drivers","activities","pressures","marine_processes","ecosystem_services","goods_benefits")`, `ISA_PREFIX_ELEMENT_KEY`, `WP5_INDICATOR_SCALE_TYPES <- c("numeric","ordinal_profile","count","categorical")`, `WP5_INDICATOR_SOURCE_SETS <- c("fiche","annex1","posidonia","arctic")`, `WP5_INDICATOR_MIN_APP_VERSION <- "1.23.0"`.

- [ ] **Step 1: Write the extract script**

`scripts/extract_wp5_indicator_sources.py`:

```python
"""Regenerate scripts/wp5_kb_sources/d5.2_v5_indicator_sources.md from the D5.2 v5 PDF.

Usage: micromamba run -n shiny python -I scripts/extract_wp5_indicator_sources.py [--wp5-dir DIR] [--accept-new-source]
Keeps only RANGES, prefixing every line with 'L<n>: ' where n is the line number
in the full pdftotext -layout -enc UTF-8 output, counted on '\n' only (this
matches `wc -l`, `grep -n` and the A_D5.2 audit citations). Do NOT use
str.splitlines(): it also splits on the 317 form feeds and shifts every number.
"""
import hashlib, pathlib, subprocess, sys, tempfile

ROOT = pathlib.Path(__file__).resolve().parents[1]
# Source docs are untracked and absent from worktrees: pass --wp5-dir <main checkout>/WP5
# (same convention as build_wp5_mechanisms_kb.py). Default: <app>/WP5.
_WP5 = pathlib.Path(sys.argv[sys.argv.index("--wp5-dir") + 1]) if "--wp5-dir" in sys.argv else ROOT / "WP5"
PDF = _WP5 / "D5.2" / "MarineSABRES_D5.2_Final.pdf"
OUT = ROOT / "scripts" / "wp5_kb_sources" / "d5.2_v5_indicator_sources.md"
PDFTOTEXT = "pdftotext"  # xpdf 4.00; on Windows use "C:/Program Files/Git/mingw64/bin/pdftotext.exe" if not on PATH
PDF_SHA256 = ""  # pin on first run (printed); --accept-new-source rewrites it
EXPECTED_LINES = 13426
RANGES = [  # (from, to, label)
    (885, 900, "Arctic: MSC certification lost"),
    (1120, 1130, "Arctic: WP3 'Agreements on Quotas'"),
    (1785, 1815, "Arctic: TAC vs advice, SSB/F vs reference points"),
    (1863, 1896, "Arctic: retail prices and landings table (Faroe Islands, 2024)"),
    (3112, 3330, "Tuscan: Tables 17 and 18 (Posidonia indicators)"),
    (4985, 5132, "Macaronesia: indicator citations in economic efficiency and equity"),
    (8285, 8440, "Annex 1 Table 6 (Tuscan DAPSIWRM indicators)"),
    (9015, 9142, "Annex 1 Table 7 (Macaronesia DAPSIWRM indicators)"),
    (10255, 13426, "Annex 8 indicator fiches"),
]


def split_lines(raw: str) -> list:
    """'\n'-only split: normalise CRLF, drop the empty string after the final newline."""
    lines = raw.replace("\r\n", "\n").split("\n")
    if lines and lines[-1] == "":
        lines.pop()
    return lines


def main():
    sys.stdout.reconfigure(encoding="utf-8")
    data = PDF.read_bytes()
    sha = hashlib.sha256(data).hexdigest()
    if PDF_SHA256 and sha != PDF_SHA256 and "--accept-new-source" not in sys.argv:
        sys.exit(f"PDF hash changed: {sha} (pass --accept-new-source after review)")
    with tempfile.TemporaryDirectory() as td:
        txt = pathlib.Path(td) / "final.txt"
        subprocess.run([PDFTOTEXT, "-layout", "-enc", "UTF-8", str(PDF), str(txt)], check=True)
        lines = split_lines(txt.read_bytes().decode("utf-8", errors="replace"))
    if len(lines) != EXPECTED_LINES:
        sys.exit(f"expected {EXPECTED_LINES} lines, got {len(lines)}: line citations would shift")
    out = ["# D5.2 v5 indicator source extract", "",
           f"Generated by scripts/extract_wp5_indicator_sources.py from {PDF.name} (sha256 {sha}).",
           "Each line is prefixed with its line number in the full pdftotext -layout -enc UTF-8 output",
           "(counted on newline only; form feeds stripped).", ""]
    for a, b, label in sorted(RANGES):
        out += [f"## L{a}-L{b}: {label}", ""]
        out += [f"L{n}: {lines[n - 1].replace(chr(12), '').rstrip()}" for n in range(a, b + 1)]
        out.append("")
    OUT.write_text("\n".join(out) + "\n", encoding="utf-8", newline="\n")
    print("ok", OUT, "sha256", sha)


if __name__ == "__main__":
    main()
```

- [ ] **Step 2: Run it and pin the hash**

Run from the app dir: `micromamba run -n shiny python -I scripts/extract_wp5_indicator_sources.py --wp5-dir "C:/Users/arturas.baziukas/OneDrive - ku.lt/HORIZON_EUROPE/Marine-SABRES/SESToolbox/MarineSABRES_SES_Shiny/WP5"` (the worktree has no `WP5/`; if `pdftotext` is not on PATH, set `PDFTOTEXT` to `C:/Program Files/Git/mingw64/bin/pdftotext.exe`).
Expected: `ok …d5.2_v5_indicator_sources.md sha256 <hex>`. Paste the printed hex into `PDF_SHA256`, re-run, and expect the same `ok` line. Then check the numbering: `grep -n "37.77%" scripts/wp5_kb_sources/d5.2_v5_indicator_sources.md` must show a line starting `L11147:`, and `grep -c $'\f' scripts/wp5_kb_sources/d5.2_v5_indicator_sources.md` must print `0`.

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
mac_fiche <- c("C_01","C_02","F_01","F_02","F_03","M_01","M_02","T_01","T_02","T_03","T_04")
mac_stubs <- c("C_02", "M_02", "T_02", "T_04")

squash <- function(x) gsub("\\s+", " ", trimws(x))
extract_lines <- function() {
  l <- readLines(ext_path, encoding = "UTF-8", warn = FALSE)
  m <- regmatches(l, regexec("^L([0-9]+): ?(.*)$", l))
  keep <- lengths(m) == 3
  setNames(vapply(m[keep], `[`, character(1), 3), vapply(m[keep], `[`, character(1), 2))
}

test_that("registry header and every entry carry the required fields", {
  expect_true(all(c("schema_version", "registry_version", "entries", "dapsiwrm_type_map") %in% names(reg)))
  req <- c("code", "annex_code", "name", "da", "source_set", "dapsiwrm_type", "unit", "scale_type",
           "data_sources", "provenance", "revision", "stub")
  for (e in entries) expect_true(all(req %in% names(e)), info = e$code)   # annex_code may be null
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

test_that("Macaronesia fiche set has the 11 canonical codes; C_02, M_02, T_02, T_04 are stubs with cited criteria", {
  fiche <- codes[vapply(entries, function(e) identical(e$source_set, "fiche"), logical(1))]
  expect_setequal(fiche, mac_fiche)
  stubs <- codes[vapply(entries, function(e) isTRUE(e$stub), logical(1))]
  expect_setequal(stubs, mac_stubs)
  for (s in mac_stubs) {
    e <- by_code[[s]]
    expect_length(e$baseline, 0)
    expect_equal(e$provenance, "provisional", info = s)
    expect_gte(length(e$criterion_roles), 1)                         # spec: "name and criterion role only"
    for (r in e$criterion_roles) {
      expect_null(r$role)                                            # D5.2 publishes no role for stubs
      expect_true(nzchar(r$role_text %||% ""), info = s)
    }
  }
})

test_that("T_03 records both meanings; the fiche meaning is canonical", {
  t3 <- by_code[["T_03"]]
  expect_match(t3$name, "tourism companies", ignore.case = TRUE)
  expect_match(t3$alt_meaning, "wildlife", ignore.case = TRUE)
})

test_that("vocabulary fields use valid codes", {
  for (e in entries) {
    expect_true(e$da %in% WP5_DA_CONTEXTS, info = e$code)
    expect_true(e$source_set %in% WP5_INDICATOR_SOURCE_SETS, info = e$code)
    expect_true(e$dapsiwrm_type %in% ISA_ELEMENT_KEYS, info = e$code)
    expect_true(e$scale_type %in% WP5_INDICATOR_SCALE_TYPES, info = e$code)
    expect_true(e$provenance %in% c("wp5_source", "wp5_derived", "toolbox_extension", "provisional"), info = e$code)
    if (!is.null(e$pathway_segment)) expect_true(e$pathway_segment %in% WP5_RUBRIC$pathway_segment, info = e$code)
    for (k in names(e$criterion_roles)) {
      expect_equal(wp5_criterion_code(k), k, info = paste(e$code, k))   # stored canonical (PI/FF, not PO/FI)
      r <- e$criterion_roles[[k]]
      if (!is.null(r$role)) expect_true(r$role %in% WP5_RUBRIC$indicator_role, info = paste(e$code, k))
    }
    for (s in names(e$scenario_projection)) {
      expect_true(s %in% c("S1", "S2", "S3", "S4"), info = e$code)
      expect_true(e$scenario_projection[[s]]$direction %in% WP5_RUBRIC$direction, info = paste(e$code, s))
    }
    expect_true(is.numeric(e$revision) && e$revision >= 1, info = e$code)
  }
})

test_that("source_set matches the code family", {
  for (e in entries) {
    want <- if (grepl("_A1_", e$code)) "annex1" else if (startsWith(e$code, "TUS_POS_")) "posidonia"
            else if (startsWith(e$code, "ARC_")) "arctic" else "fiche"
    expect_equal(e$source_set, want, info = e$code)
  }
})

test_that("provenance rules: cited entries have lines and quotes; wp5_derived has a derivation", {
  for (e in entries) {
    if (e$provenance %in% c("wp5_source", "wp5_derived", "provisional")) {
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

test_that("F_01 scenario directions follow ruling 11 (↔ is stable)", {
  sp <- by_code[["F_01"]]$scenario_projection
  expect_equal(vapply(sp[c("S1", "S2", "S3", "S4")], function(x) x$direction, character(1), USE.NAMES = FALSE),
               c("no_change", "decrease", "decrease", "increase"))
})

test_that("F_02 (CPUE) publishes no baseline values and is flagged as a data gap", {
  f2 <- by_code[["F_02"]]
  expect_length(f2$baseline, 0)
  expect_true(isTRUE(f2$data_gap))
  expect_true(nzchar(f2$caveat %||% ""))
})
```

- [ ] **Step 4: Run to see it fail**

Run: `"/c/Program Files/R/R-4.4.1/bin/Rscript.exe" -e "testthat::test_file('tests/testthat/test-indicator-registry.R')"`
Expected: an error at the top of the file from `jsonlite::fromJSON()` on the missing `data/wp5_indicators.json` (jsonlite treats a non-existent path as a JSON string, so the message is a `lexical error: invalid char in json text.`, not "cannot open file").

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
# The six Standard Entry element prefixes. Responses ("r") are deliberately
# absent: WS-4 leaves them untouched (plan ruling 9).
ISA_PREFIX_ELEMENT_KEY <- c(d = "drivers", a = "activities", p = "pressures", mpf = "marine_processes",
                            es = "ecosystem_services", gb = "goods_benefits")
WP5_INDICATOR_SCALE_TYPES <- c("numeric", "ordinal_profile", "count", "categorical")
WP5_INDICATOR_SOURCE_SETS <- c("fiche", "annex1", "posidonia", "arctic")
# A save that records a registry snapshot needs an app that keeps the
# Registry_Id/Registry_Version columns (WS-0 stamp_min_app_version()).
WP5_INDICATOR_MIN_APP_VERSION <- "1.23.0"
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
    "derivation": "Annex 1 Table 6/7 'Type' column (hyphen-split labels joined) -> ISA element key",
    "map": {
      "Human needs": "drivers", "Needs": "drivers",
      "Activity": "activities", "Activities": "activities",
      "Pressures": "pressures", "Dominant Pressures": "pressures",
      "Marine Processes and Functions": "marine_processes", "Marine Process and Functioning": "marine_processes",
      "Ecosystem Services": "ecosystem_services", "Ecosystem Service": "ecosystem_services",
      "Goods and Benefits": "goods_benefits", "Good and Benefit": "goods_benefits"
    }
  },
  "entries": [ ]
}
```

Worked entry 1 (full fiche entry; F_01 = annex F_02; fiche L10982–11586):

```json
{
  "code": "F_01", "annex_code": "F_02", "name": "Pelagic (tuna) landing share",
  "da": "macaronesia", "source_set": "fiche", "dapsiwrm_type": "activities", "pathway_segment": "pressure",
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
  "scenario_projection": {
    "S1": {"direction_text": "~0 (↔)", "direction": "no_change", "assumption_text": "S1 BAU", "magnitude_text": null},
    "S2": {"direction_text": "↔ / slight ↓", "direction": "decrease", "assumption_text": "S2 Light coordination", "magnitude_text": null},
    "S3": {"direction_text": "↓↓ (moderate)", "direction": "decrease", "assumption_text": "S3 Coordinated corridor (EEZ)", "magnitude_text": null},
    "S4": {"direction_text": "↔ / slight ↑", "direction": "increase", "assumption_text": "S4 Integrated corridor (EEZ+ABNJ)", "magnitude_text": null}
  },
  "early_warning": [
    {"lever": "Leakage and displacement management are the hinge.", "metric": null, "trigger": null},
    {"lever": "Dependency hotspots deserve targeted mitigation.", "metric": null, "trigger": null},
    {"lever": "Substitute fisheries must be part of the story.", "metric": null, "trigger": null},
    {"lever": "Financial feasibility differentiates scenarios.", "metric": null, "trigger": null}
  ],
  "reference_range": null,
  "data_sources": ["Regional fisheries landings statistics (Madeira, Azores, Canaries)"],
  "data_gap": false, "stub": false, "revision": 1,
  "caveat": "Scenario directions are the 'Expected ΔF_02' column of 'Table 1 Scenario-based assumptions' (L11271-11313); the prose below it (L11317) calls the same table 'Table 2'. The landings-bound columns interleave in the layout, so magnitude_text is left null.",
  "provenance": "wp5_source",
  "source_ref": {"document": "D5.2 v5", "section": "Annex 8, indicator F_02 (canonical F_01)", "lines": [10986, 11585]},
  "source_quotes": ["Pelagic landing share (tuna)", "37.77%", "45.48%", "51.24%", "Secondary (trian-",
                    "Table 1 Scenario-based assumptions", "~0 (↔)", "Corridor design implications (as indicated by F_02)",
                    "Leakage and displacement management are the hinge."]
}
```

Worked entry 2 (scenario + count baseline; M_01, lines 12584–12752):

```json
{
  "code": "M_01", "annex_code": null, "name": "Number of vessel movements between islands",
  "da": "macaronesia", "source_set": "fiche", "dapsiwrm_type": "activities", "pathway_segment": "pressure",
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

Note: the M_01 S2/S3 magnitude cells interleave in the layout. Before writing them, the executor re-reads L12731–12752 and confirms the row assignment against the PDF page. If it can't be confirmed, set that row's `magnitude_text` to `null` and extend the `caveat`. Each quote must survive whitespace squashing (the test squashes both sides). If a quote fails because of layout spacing, shorten it to a contiguous fragment.

Transcription checklist for the remaining Macaronesia fiche-set entries. Each needs fields as in the worked examples, `source_set: "fiche"`, `source_ref.lines` as listed, at least two `source_quotes`, `revision: 1`, `classification_provenance: "toolbox_extension"`. Roles follow ruling 7, directions follow ruling 11 (direction-symbol cell only).

| Code | annex_code | Name (source wording) | dapsiwrm_type / segment | Criteria (roles) | Baseline | Scenario / early warning | `source_ref.lines` |
|---|---|---|---|---|---|---|---|
| C_01 | null | Connectivity Index | marine_processes / state; `scale_type: "ordinal_profile"` | Table 1 L10358–10398 interleaves the role column; take roles from the interpretation bridge L10823–10835, which states them in prose: EE primary ("Primary"), PO→PI "strong supporting", FI→FF "supporting", EC "secondary", EQ "limited" (all four → `supporting`). Quote `"PO (strong supporting)"`. | Table 2 "Baseline evidence of corridor use and monitoring detectability" L10532–10685: one baseline row per taxon group × area, `value: null`, `value_text` = the recurrence/evidence cell verbatim (e.g. "Seasonal recurrent (spring; May–Jun)"); confirm each cell against PDF pp. 252–254. | Table 3 "Scenario-based connectivity implications (Δ relative to baseline)" L10730–10816: `direction_text` = the ordinal Δ (0, 0/+, +, ++, +++) for the near-island column, direction by ruling 11's ordinal rule. Early warning: Table 5 L10916–10980 (L10982 is the F_02 heading). | [10262, 10980] |
| F_02 | F_03 | CPUE | marine_processes / state | L11620–11651: EE "Primary", EC "Supporting", PO→PI "Supporting", FI→FF "Secondary", EQ "Secondary" (the EQ row is printed twice, L11648–11651; take it once and note it in `caveat`) | none published: `baseline: []`, `data_gap: true`, `caveat` "D5.2 describes the CPUE baseline method (L11653–11695) but publishes no CPUE values." | Table 1 "Scenario-to-CPUE expected pattern" L11728–11760: S1 "↔ (noise)" → no_change; S2 "↔ / ↑ (stabilisation)" → increase; S3 "± (local ↑; aggregate ↔/↓)" → uncertain; S4 "↔/↑ (more plausible)" → increase. No early-warning table. | [11587, 11760] |
| F_03 | F_04 | Fishing participation & fleet capacity (commercial F_04a, charter F_04b) | activities / pressure | L12024–12061 (one role string reads "Primary / strong supporting" → `primary`) | L12062–12158 and Table 3 L12104: record a and b as separate baseline rows with an `area` suffix (" (F_04a)", " (F_04b)") | Table 4 "Scenario-based assumptions" L12219–12264 has two direction columns (F_04a commercial, F_04b charter): `direction_text` = "F_04a: <cell>; F_04b: <cell>", `direction` = the common direction when both columns agree, else `uncertain`. Table 4 "Ex-ante corridor implications" L12303–12518 is criteria text, not directions. Early warning L12521–12583. | [11889, 12583] |
| T_01 | null | Total visitors | activities / pressure | L12876–12912 (header says "Use of F_04"; add caveat) | Table 7 L12913–12960 | L13018–13040 (S1 "↑", S2 "↔, slight ↑", S3/S4 "↔, then ↑" → all increase) | [12850, 13040] |
| T_03 | null | Number of marine tourism companies | goods_benefits / benefit | L13174–13202 | Table 9 L13209–13260 (Canaries n/a) | L13286–13309; `alt_meaning: "Shortlist meaning: wildlife-watch participation (A§5.1); fiche meaning is canonical pending partner Q3"` | [13148, 13309] |
| C_02 | null | Monitoring / implementation capacity | activities / governance_capacity; stub, `provisional` | `{"EC": {"role": null, "role_text": "cited in the EC narrative: \"C_02 (monitoring capacity) conditions whether coordination reduces inefficiency\""}, "EQ": {"role": null, "role_text": "cited in the EQ narrative: \"capacity to comply (C_02)\""}}`; quotes `"C_02 (monitoring capacity)"`, `"capacity to comply (C_02)"` | — | — | [4985, 5132] |
| M_02 | M_03 | Traffic / vessel interaction with sensitive areas | pressures / pressure; stub, `provisional` | `{"EQ": {"role": null, "role_text": "cited in the EQ narrative: \"where pressures concentrate and may be redistributed (M_01–M_02)\""}}`; quote `"M_01–M_02"` | — | — | [4985, 5132] |
| T_02 | null | Marine tourism revenue | goods_benefits / benefit; stub, `provisional` | `{"EC": {"role": null, "role_text": "cited in the EC narrative: \"T_02 (marine tourism revenue)\""}, "EQ": {"role": null, "role_text": "cited in the EQ narrative: \"T_01–T_04\""}}`; quotes `"T_02 (marine tourism revenue)"`, `"T_01–T_04"` | — | — | [4985, 5132] |
| T_04 | null | Marine tourism employment | goods_benefits / benefit; stub, `provisional` | `{"EC": {"role": null, "role_text": "cited in the EC narrative: \"T_04 (employment)\""}, "EQ": {"role": null, "role_text": "cited in the EQ narrative: \"T_01–T_04\""}}`; quotes `"T_04 (employment)"`, `"T_01–T_04"` | — | — | [4985, 5132] |

Before writing each row, `grep -n` the cited lines in the committed extract and confirm the boundaries; if a boundary moved by a line or two, use the extract's numbers and record that in the ledger. Stubs carry `baseline: []`, `scenario_projection: {}`, `early_warning: []`, `data_sources: []`, `unit: ""`, `scale_type: "numeric"`, `data_gap: true`.

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

### Task 2: Posidonia, Annex 1 and Arctic entries + loader, lookups and the WS-2 audit link

**Files:**
- Modify: `data/wp5_indicators.json`, `global.R` (after line `source("functions/wp5_typing_lint.R", local = FALSE)`), `scripts/kb_audit/audit_wp5_mechanisms.py`, `scripts/kb_audit/test_build_wp5_mechanisms_kb.py`
- Create: `functions/indicator_registry.R`
- Test: `tests/testthat/test-indicator-registry.R` (append), `scripts/kb_audit/test_build_wp5_mechanisms_kb.py` (append)

**Interfaces:**
- Consumes: Task 1 JSON + constants; `provenance_badge()` key namespace `modules.wp5_mechanisms.provenance.*` (keys added in Task 6).
- Produces:
  - `load_indicator_registry(path = NULL, force_reload = FALSE)` → list(`version`, `entries` named by code); on a missing or malformed file: `warning()` + empty `entries`
  - `get_indicator(code)` → entry list or `NULL`
  - `list_indicators(da = NULL, dapsiwrm_type = NULL, segment = NULL, source_set = NULL, include_stubs = TRUE)` → data.frame(`code, name, da, source_set, dapsiwrm_type, pathway_segment, unit, stub, revision, provenance`)
  - `search_indicators(query)` → same df, case-insensitive match on code/name/unit
  - `indicator_picker_choices(element_key, i18n)` → named list for `selectInput` (first element `""` labelled "—"); labels `"<code> · <English name> (<DA label>)"` plus `" [<stub marker>]"` for stubs or `" [<provenance label>]"` for non-stub entries whose provenance is not `wp5_source`
  - Python: `audit_wp5_mechanisms.registry_codes(path=REGISTRY_PATH)` → set of codes or `None`; `audit_wp5_mechanisms.success_metric_registry_fails(kb, codes)` → list of failure strings; `audit(kb, sections, registry=None)`

- [ ] **Step 1: Append the failing tests**

```r
# ---- Task 2: other DAs + loader ---------------------------------------------
source_for_test(c("functions/indicator_registry.R"))

test_that("Posidonia: 33 Table 17 indicators, 8 with Table 18 reference ranges", {
  pos <- Filter(function(e) identical(e$source_set, "posidonia"), entries)
  expect_length(pos, 33)
  expect_true(all(startsWith(vapply(pos, `[[`, "", "code"), "TUS_POS_")))
  with_rr <- Filter(function(e) !is.null(e$reference_range), pos)
  expect_length(with_rr, 8)
  for (e in with_rr) {
    rr <- e$reference_range
    expect_true(nzchar(rr$text), info = e$code)
    if (!is.null(rr$low) && !is.null(rr$high)) expect_lte(rr$low, rr$high)
  }
  expect_true(all(vapply(pos, function(e) e$provenance == "wp5_derived", logical(1))))  # codes are generated
  expect_true("TUS_POS_SEAGRASS_SHOOT_DENSITY" %in% codes)
  expect_equal(by_code[["TUS_POS_SEAGRASS_SHOOT_DENSITY"]]$name, "Seagrass meadow density")
})

test_that("Annex 1 rows: 28 Tuscan + 18 Macaronesia, typed through the map, data gaps flagged", {
  a1 <- Filter(function(e) identical(e$source_set, "annex1"), entries)
  a1_codes <- vapply(a1, `[[`, "", "code")
  expect_equal(sum(startsWith(a1_codes, "TUS_A1_")), 28L)
  expect_equal(sum(startsWith(a1_codes, "MAC_A1_")), 18L)
  for (e in a1) expect_true(e$source_type %in% names(reg$dapsiwrm_type_map$map), info = e$code)
  for (e in a1) expect_equal(e$dapsiwrm_type, reg$dapsiwrm_type_map$map[[e$source_type]], info = e$code)
  seg <- c(drivers = "pressure", activities = "pressure", pressures = "pressure", marine_processes = "state",
           ecosystem_services = "benefit", goods_benefits = "benefit")
  for (e in a1) expect_equal(e$pathway_segment, seg[[e$dapsiwrm_type]], info = e$code)
  expect_equal(by_code[["TUS_A1_POTENTIAL_ANCHORAGES"]]$source_type, "Activity")   # stacked-label count (ruling 13)
  gaps <- Filter(function(e) isTRUE(e$data_gap), a1)
  expect_gte(length(gaps), 2)                                  # energy dissipation capacity, natural habitats
})

test_that("Arctic has the five descriptive wp5_derived entries; prices are retail", {
  arc <- Filter(function(e) e$da == "arctic", entries)
  expect_setequal(vapply(arc, `[[`, "", "code"),
                  c("ARC_LANDINGS", "ARC_PRICE", "ARC_TAC_VS_ADVICE", "ARC_SSB_VS_REFPOINTS", "ARC_MSC_STATUS"))
  for (e in arc) expect_equal(e$provenance, "wp5_derived")
  expect_match(by_code[["ARC_PRICE"]]$name, "retail", ignore.case = TRUE)
  expect_false(grepl("first-sale", by_code[["ARC_PRICE"]]$name, ignore.case = TRUE))
})

test_that("loader caches and lookups filter", {
  r <- load_indicator_registry(force_reload = TRUE)
  expect_equal(r$version, reg$registry_version)
  expect_equal(get_indicator("F_01")$annex_code, "F_02")
  expect_null(get_indicator("NOPE"))
  mac <- list_indicators(da = "macaronesia", source_set = "fiche")
  expect_setequal(mac$code, mac_fiche)
  expect_equal(nrow(mac), 11L)
  expect_equal(nrow(list_indicators(da = "macaronesia", source_set = "fiche", include_stubs = FALSE)), 7L)
  expect_gt(nrow(list_indicators(da = "macaronesia")), 11L)     # Table 7 rows share the DA
  expect_true(all(list_indicators(dapsiwrm_type = "pressures")$dapsiwrm_type == "pressures"))
  expect_true("TUS_POS_SEAGRASS_SHOOT_DENSITY" %in% search_indicators("shoots")$code)
  expect_true("F_01" %in% search_indicators("f_01")$code)       # code match is case-insensitive
  expect_equal(nrow(search_indicators("")), 0L)
})

test_that("picker choices put the element's own type first and start with an empty choice", {
  ch <- indicator_picker_choices("pressures", make_test_i18n())
  expect_equal(unname(ch[[1]]), "")
  expect_true(length(ch) >= 3)
  first_group <- ch[[2]]
  expect_true(all(vapply(first_group, function(code) get_indicator(code)$dapsiwrm_type == "pressures", logical(1))))
})

test_that("picker labels mark stubs and non-wp5_source provenance; wp5_source has no marker", {
  ch <- indicator_picker_choices("activities", make_test_i18n())
  vals <- unlist(lapply(ch[-1], function(g) unlist(g)))
  labs <- unlist(lapply(ch[-1], names))
  lab <- function(code) labs[match(code, vals)]
  expect_match(lab("C_02"), "modules.indicator_registry.stub_marker", fixed = TRUE)
  expect_match(lab("TUS_POS_SEAGRASS_SHOOT_DENSITY"), "modules.wp5_mechanisms.provenance.wp5_derived", fixed = TRUE)
  expect_false(grepl("[", lab("F_01"), fixed = TRUE))
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
Expected: the data tests fail on the missing entries (`expect_length(pos, 33)` gets 0, and so on), and the loader tests error with `could not find function "load_indicator_registry"` (`source_for_test()` skips a missing file silently, so there is no "cannot open file" error).

- [ ] **Step 3: Transcribe the remaining entries**

Every entry in this step carries `source_set` as listed, `revision: 1`, `stub: false`, and `criterion_roles: {}`, `baseline: []`, `scenario_projection: {}`, `early_warning: []` unless stated.

**Posidonia** (`source_set: "posidonia"`, `da: "tuscan"`, `provenance: "wp5_derived"`, `source_ref.lines: [3116, 3280]`, section "Tables 17-18"). Worked entry:

```json
{
  "code": "TUS_POS_SEAGRASS_SHOOT_DENSITY", "annex_code": null, "name": "Seagrass meadow density",
  "table18_name": "Seagrass Shoot Density",
  "da": "tuscan", "source_set": "posidonia", "dapsiwrm_type": "marine_processes", "pathway_segment": "state",
  "classification_provenance": "toolbox_extension",
  "ecosystem_service": "Coastal Protection",
  "unit": "shoots/m2", "scale_type": "numeric",
  "criterion_roles": {}, "baseline": [], "scenario_projection": {}, "early_warning": [],
  "reference_range": {"low": 400, "high": 700, "unit": "shoots/m2",
    "text": "In the Balearic/Spanish Mediterranean, values range from ~400 to 700 shoots/m². (Data from several Mediterranean studies)",
    "comment": "Dense meadows (≥400 shoots/m²) are linked with enhanced coastal protection. Local variability is expected due to depth and hydrodynamic conditions.",
    "reference": "Olivé et al. (2007); Duarte (2002)"},
  "data_sources": ["Field survey (shoot counts)"],
  "data_gap": false, "stub": false, "revision": 1,
  "provenance": "wp5_derived",
  "derivation": "Code generated from D5.2 Table 17/18 row names (no code in source); values copied from Table 18.",
  "source_ref": {"document": "D5.2 v5", "section": "Tables 17-18", "lines": [3116, 3280]},
  "source_quotes": ["Seagrass meadow density", "Shoots/m²", "values range from ~400 to", "Dense meadows (≥400 shoots/m²)"]
}
```

Rules for all 33 Posidonia rows:
- `name` = the Table 17 indicator wording verbatim. `table18_name` only for the 8 Table 18 rows.
- Code = `TUS_POS_` + SNAKE_UPPER of the Table 18 name when the row is in Table 18, otherwise of the Table 17 name. SNAKE_UPPER: drop any parenthesised part, replace `&` with `AND`, uppercase, replace each run of non-alphanumerics with `_`, trim `_`. The resulting codes are listed below; use them as written.
- `ecosystem_service` = the Table 17 group heading verbatim.
- `unit` = the Table 17 unit with ASCII `m2`/`d13C` style (the quote keeps the original glyphs).
- `reference_range` only for the 8 Table 18 rows: `text` = the "Values from Other Areas/Sites" cell reassembled verbatim (hyphen breaks joined, original glyphs kept), `comment` = the "Comments on Reported Values" cell reassembled verbatim, `reference` = the "Academic Reference" cell. The reassembled cells usually span interleaved lines, so `source_quotes` hold only contiguous fragments as they appear on one extract line. Values: shoot density 400–700; canopy height 30–100 cm; root & rhizome biomass `low: null, high: 1500` ("up to approximately 1,500 g/m²"); nutrient uptake `low: null, high: null` (two nutrients, text only); denitrification `low = high = 1.8`; fish & invertebrate biomass 500–1000 g/m²; carbon sequestration 83–150 g C/m²/yr; sediment organic carbon `low: null, high: 10`.
- `pathway_segment`: `state` for `marine_processes`, `benefit` for `ecosystem_services`; all rows carry `classification_provenance: "toolbox_extension"`.

| # | Table 17 group | Table 17 indicator (`name`) | Code | dapsiwrm_type | Table 18 |
|---|---|---|---|---|---|
| 1 | Coastal Protection | Seagrass meadow density | TUS_POS_SEAGRASS_SHOOT_DENSITY | marine_processes | yes |
| 2 | Coastal Protection | Canopy height | TUS_POS_CANOPY_HEIGHT | marine_processes | yes |
| 3 | Coastal Protection | Root and rhizome biomass | TUS_POS_ROOT_AND_RHIZOME_BIOMASS | marine_processes | yes |
| 4 | Coastal Protection | Wave energy reduction | TUS_POS_WAVE_ENERGY_REDUCTION | ecosystem_services | |
| 5 | Coastal Protection | Sediment accretion rate | TUS_POS_SEDIMENT_ACCRETION_RATE | ecosystem_services | |
| 6 | Water Purification | Nutrient retention (N, P) | TUS_POS_NUTRIENT_UPTAKE_CAPACITY | ecosystem_services | yes |
| 7 | Water Purification | Water clarity (turbidity reduction) | TUS_POS_WATER_CLARITY | ecosystem_services | |
| 8 | Water Purification | Denitrification rate | TUS_POS_DENITRIFICATION_RATE | ecosystem_services | yes |
| 9 | Water Purification | Bacterial & pathogen filtration | TUS_POS_BACTERIAL_AND_PATHOGEN_FILTRATION | ecosystem_services | |
| 10 | Food Provision | Fish & invertebrate biomass | TUS_POS_FISH_AND_INVERTEBRATE_BIOMASS | marine_processes | yes |
| 11 | Food Provision | Juvenile fish density | TUS_POS_JUVENILE_FISH_DENSITY | marine_processes | |
| 12 | Food Provision | Species richness | TUS_POS_SPECIES_RICHNESS | marine_processes | |
| 13 | Food Provision | Habitat complexity (leaf area index) | TUS_POS_HABITAT_COMPLEXITY | marine_processes | |
| 14 | Food Provision | Export of organic matter | TUS_POS_EXPORT_OF_ORGANIC_MATTER | ecosystem_services | |
| 15 | Climate Regulation | Carbon sequestration rate | TUS_POS_CARBON_SEQUESTRATION_RATE | ecosystem_services | yes |
| 16 | Climate Regulation | Sediment organic carbon storage | TUS_POS_SEDIMENT_ORGANIC_CARBON_STORAGE | ecosystem_services | yes |
| 17 | Climate Regulation | Net Primary Production (NPP) | TUS_POS_NET_PRIMARY_PRODUCTION | marine_processes | |
| 18 | Climate Regulation | Blue carbon burial rate | TUS_POS_BLUE_CARBON_BURIAL_RATE | ecosystem_services | |
| 19 | Climate Regulation | Decomposition rate of seagrass biomass | TUS_POS_DECOMPOSITION_RATE_OF_SEAGRASS_BIOMASS | marine_processes | |
| 20 | Recreation & Tourism | Water transparency | TUS_POS_WATER_TRANSPARENCY | ecosystem_services | |
| 21 | Recreation & Tourism | Seagrass cover | TUS_POS_SEAGRASS_COVER | marine_processes | |
| 22 | Recreation & Tourism | Biodiversity index | TUS_POS_BIODIVERSITY_INDEX | ecosystem_services | |
| 23 | Recreation & Tourism | Presence of charismatic species | TUS_POS_PRESENCE_OF_CHARISMATIC_SPECIES | ecosystem_services | |
| 24 | Life Cycle Maintenance | Recruitment rate of juvenile fish | TUS_POS_RECRUITMENT_RATE_OF_JUVENILE_FISH | marine_processes | |
| 25 | Life Cycle Maintenance | Epiphyte biomass | TUS_POS_EPIPHYTE_BIOMASS | marine_processes | |
| 26 | Life Cycle Maintenance | Trophic linkages (unit: stable isotope ratios) | TUS_POS_TROPHIC_LINKAGES | marine_processes | |
| 27 | Life Cycle Maintenance | Extent of seagrass meadow | TUS_POS_EXTENT_OF_SEAGRASS_MEADOW | marine_processes | |
| 28 | Biotic Materials & Biofuels | Seagrass biomass production | TUS_POS_SEAGRASS_BIOMASS_PRODUCTION | ecosystem_services | |
| 29 | Biotic Materials & Biofuels | Cellulose & lignin content | TUS_POS_CELLULOSE_AND_LIGNIN_CONTENT | ecosystem_services | |
| 30 | Biotic Materials & Biofuels | Decomposability rate | TUS_POS_DECOMPOSABILITY_RATE | ecosystem_services | |
| 31 | Cognitive & Cultural Benefits | Number of endemic/rare species | TUS_POS_NUMBER_OF_ENDEMIC_RARE_SPECIES | ecosystem_services | |
| 32 | Cognitive & Cultural Benefits | Historical seagrass banquettes | TUS_POS_HISTORICAL_SEAGRASS_BANQUETTES | ecosystem_services | |
| 33 | Cognitive & Cultural Benefits | Seagrass meadow longevity | TUS_POS_SEAGRASS_MEADOW_LONGEVITY | marine_processes | |

The Table 18 names behind the codes in rows 1, 3, 6, 8, 10, 15 and 16 are "Seagrass Shoot Density", "Root & Rhizome Biomass", "Nutrient Uptake Capacity", "Denitrification Rate", "Fish & Invertebrate Biomass", "Carbon Sequestration Rate" and "Sediment Organic Carbon Storage"; row 2 is "Canopy Height". Group headings are verbatim from L3119–3194 (two of them wrap: "Biotic Materials & Biofu-/els", "Cognitive & Cultural Ben-/efits").

**Annex 1** (`source_set: "annex1"`, `provenance: "wp5_derived"`). Worked entry (Tuscan Table 6 L8291–8437):

```json
{
  "code": "TUS_A1_POTENTIAL_ANCHORAGES", "annex_code": null, "name": "Potential anchorages",
  "da": "tuscan", "source_set": "annex1", "source_type": "Activity", "dapsiwrm_type": "activities", "pathway_segment": "pressure",
  "classification_provenance": "toolbox_extension",
  "element": "Vessel anchorages",
  "definition": "Proportional to the density of leisure craft vessels in the TANP.",
  "unit": "anchorages (density)", "scale_type": "numeric",
  "criterion_roles": {}, "baseline": [], "scenario_projection": {}, "early_warning": [],
  "reference_range": null,
  "data_sources": ["EMODNET"], "data_gap": false, "stub": false, "revision": 1,
  "caveat": "Type assigned by counting the stacked Type labels in source order (row 6 of 28 → Activity); the layout prints 'Pressures' beside this row.",
  "provenance": "wp5_derived",
  "derivation": "Row of D5.2 Annex 1 Table 6 (Borja et al. 2024); dapsiwrm_type via dapsiwrm_type_map; pathway_segment by plan ruling 8.",
  "source_ref": {"document": "D5.2 v5", "section": "Annex 1 Table 6", "lines": [8291, 8437]},
  "source_quotes": ["Potential anchor-", "of leisure craft vessels in the"]
}
```

Rules for Annex 1 rows:
- Transcribe every row of Table 6 (L8291–8437, code prefix `TUS_A1_`, 28 rows) and Table 7 (L9020–9140, prefix `MAC_A1_`, 18 rows; L9143 is the Annex 2 heading).
- Types follow ruling 13 (stacked-label count): Table 6 = Human needs ×4, Activity ×5, Pressures ×5, Marine Processes and Functions ×4, Ecosystem Services ×5, Goods and Benefits ×5; Table 7 = Needs ×1, Activities ×2, Dominant Pressures ×4, Marine Process and Functioning ×3, Ecosystem Service ×3, Good and Benefit ×5. `source_type` = the joined label, which must be a key of `dapsiwrm_type_map.map`. Where the layout prints a different label beside a row, add a `caveat` like the worked entry's. To confirm, open the PDF (Table 6 is on pp. 186–188, Table 7 on pp. 202–204) or run `pdftotext -f 186 -l 188 -enc UTF-8` without `-layout`, which prints the labels in source order.
- `pathway_segment` by ruling 8 (drivers, activities, pressures → `pressure`; marine_processes → `state`; ecosystem_services, goods_benefits → `benefit`); `classification_provenance: "toolbox_extension"`.
- Code = prefix + SNAKE_UPPER of the indicator (same SNAKE_UPPER rule as Posidonia). When an indicator name occurs more than once in the same table (Table 6: "Resident population" ×2, "Quality of Bathing Waters" ×2), append `_` + SNAKE_UPPER of the row's element to every occurrence (e.g. `TUS_A1_RESIDENT_POPULATION_FOOD_SECURITY`).
- "Data Gap" in the source → `data_gap: true`, `data_sources: []`.
- Quotes must be contiguous fragments as they appear on one extract line (hyphenated breaks such as `"Potential anchor-"` are fine).

**Arctic** (`source_set: "arctic"`, `da: "arctic"`, `provenance: "wp5_derived"`, derivation "Descriptive indicator assembled from Arctic NEA chapter text; D5.2 defines no formal Arctic indicator set (A§5.5)"). Scope: the Faroe Islands 2024 table only; the Greenland (≈L1935) and Iceland (≈L2012) tables are a follow-up, listed in the partner gate.

| Code | Name | dapsiwrm_type / segment | Unit | lines | quotes | caveat |
|---|---|---|---|---|---|---|
| ARC_LANDINGS | Pelagic landings by species, Faroe Islands (2024) | activities / pressure | tonnes | [1863, 1880] | `"Landings (tons)"`, `"Estimated revenue (USD) for the Faroe Islands in 2024."` | — |
| ARC_PRICE | Average retail price by species (midpoint), Faroe Islands (2024) | goods_benefits / benefit | USD/t | [1863, 1896] | `"average retail prices"`, `"Avg. Price (USD/ton)"`, `"midpoint retail prices, not ex-vessel prices."` | "Retail midpoint prices, not first-sale/ex-vessel prices; ex-vessel prices are often 30–50% of final retail value (L1863–1865, L1894)." |
| ARC_TAC_VS_ADVICE | Catch vs TAC and ICES advice (overshoot %) | pressures / pressure | % | [1785, 1815] | `"herring, and 28% for blue whiting"` | — |
| ARC_SSB_VS_REFPOINTS | SSB vs MSY Btrigger/Bpa/Blim; F vs FMSY/Fpa | marine_processes / state | ratio to reference point | [1785, 1815] | `"MSY Btrigger"`, `"FMSY"` | — |
| ARC_MSC_STATUS | MSC certification status | goods_benefits / governance_capacity | categorical (certified/suspended) | [885, 900] | `"Marine Stewardship Council (MSC) certification"` | — |

`ARC_MSC_STATUS` uses `scale_type: "categorical"`. The others use `numeric`. All five carry `classification_provenance: "toolbox_extension"`. Check every quote against the extract; if the exact wording differs, use the extract's wording.

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
    return(data.frame(code = character(), name = character(), da = character(), source_set = character(),
                      dapsiwrm_type = character(), pathway_segment = character(), unit = character(),
                      stub = logical(), revision = integer(), provenance = character(), stringsAsFactors = FALSE))
  }
  g <- function(e, f, d = NA_character_) { v <- e[[f]]; if (is.null(v)) d else as.character(v) }
  data.frame(
    code = vapply(entries, g, "", "code"), name = vapply(entries, g, "", "name"),
    da = vapply(entries, g, "", "da"), source_set = vapply(entries, g, "", "source_set"),
    dapsiwrm_type = vapply(entries, g, "", "dapsiwrm_type"),
    pathway_segment = vapply(entries, g, "", "pathway_segment"), unit = vapply(entries, g, "", "unit"),
    stub = vapply(entries, function(e) isTRUE(e$stub), logical(1)),
    revision = vapply(entries, function(e) as.integer(e$revision %||% 1L), integer(1)),
    provenance = vapply(entries, g, "", "provenance"), stringsAsFactors = FALSE, row.names = NULL)
}

list_indicators <- function(da = NULL, dapsiwrm_type = NULL, segment = NULL, source_set = NULL,
                            include_stubs = TRUE) {
  df <- .indicator_rows(load_indicator_registry()$entries)
  if (!is.null(da)) df <- df[df$da %in% da, , drop = FALSE]
  if (!is.null(dapsiwrm_type)) df <- df[df$dapsiwrm_type %in% dapsiwrm_type, , drop = FALSE]
  if (!is.null(segment)) df <- df[!is.na(df$pathway_segment) & df$pathway_segment %in% segment, , drop = FALSE]
  if (!is.null(source_set)) df <- df[df$source_set %in% source_set, , drop = FALSE]
  if (!include_stubs) df <- df[!df$stub, , drop = FALSE]
  rownames(df) <- NULL
  df
}

search_indicators <- function(query) {
  df <- list_indicators()
  q <- tolower(trimws(as.character(query %||% "")))
  if (!nzchar(q)) return(df[0, , drop = FALSE])
  hit <- grepl(q, tolower(df$code), fixed = TRUE) |
    grepl(q, tolower(df$name), fixed = TRUE) | grepl(q, tolower(df$unit), fixed = TRUE)
  df[hit, , drop = FALSE]
}

#' Label suffix that keeps provenance visible in a plain-text select option
#' (selectize options cannot hold HTML badges). Stubs get the stub marker;
#' other non-wp5_source entries get the provenance_badge() label.
.indicator_label_suffix <- function(provenance, stub, i18n) {
  # i18n-ref: modules.indicator_registry.stub_marker
  # i18n-ref: modules.wp5_mechanisms.provenance.wp5_derived
  # i18n-ref: modules.wp5_mechanisms.provenance.toolbox_extension
  # i18n-ref: modules.wp5_mechanisms.provenance.provisional
  vapply(seq_along(provenance), function(i) {
    if (isTRUE(stub[i])) return(paste0(" [", i18n$t("modules.indicator_registry.stub_marker"), "]"))
    p <- provenance[i]
    if (is.na(p) || !nzchar(p) || identical(p, "wp5_source")) return("")
    paste0(" [", i18n$t(paste0("modules.wp5_mechanisms.provenance.", p)), "]")
  }, character(1))
}

#' Grouped choices for the per-element picker: the element's own type first.
#' Labels: "<code> · <English name> (<DA label>)[ <marker>]"; values: codes.
indicator_picker_choices <- function(element_key, i18n) {
  none <- stats::setNames(list(""), i18n$t("modules.indicator_registry.picker_none"))
  df <- list_indicators()
  if (nrow(df) == 0) return(none)
  # i18n-ref: modules.indicator_registry.da.macaronesia
  # i18n-ref: modules.indicator_registry.da.tuscan
  # i18n-ref: modules.indicator_registry.da.arctic
  da_lab <- vapply(df$da, function(d) i18n$t(paste0("modules.indicator_registry.da.", d)), character(1))
  labels <- paste0(df$code, " · ", df$name, " (", da_lab, ")",
                   .indicator_label_suffix(df$provenance, df$stub, i18n))
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

The picker tests call `make_test_i18n()`, which returns keys verbatim, so the label tests can match the key strings. The real labels arrive in Task 6.

- [ ] **Step 5: Run the registry tests**

Run: `"/c/Program Files/R/R-4.4.1/bin/Rscript.exe" -e "testthat::test_file('tests/testthat/test-indicator-registry.R')"` and `"/c/Program Files/R/R-4.4.1/bin/Rscript.exe" -e "testthat::test_file('tests/testthat/test-functions-sourced-in-app.R')"`
Expected: both `[ FAIL 0 | … ]`.

- [ ] **Step 6: Link the WS-2 audit to the registry (spec WS-2 "Audit")**

In `scripts/kb_audit/audit_wp5_mechanisms.py`, add below `KB_PATH`:

```python
REGISTRY_PATH = APP / "data" / "wp5_indicators.json"


def registry_codes(path=REGISTRY_PATH):
    """Codes of the WS-4 indicator registry, or None when the file is absent."""
    p = Path(path)
    if not p.exists():
        return None
    return {e["code"] for e in json.loads(p.read_text(encoding="utf-8"))["entries"]}


def success_metric_registry_fails(kb, codes):
    """Spec WS-2 Audit: every derived.success_metrics code must exist in the WS-4 registry."""
    if codes is None:
        return ["top.registry: data/wp5_indicators.json missing (WS-4)"]
    fails = []
    for da, block in kb.get("demonstration_areas", {}).items():
        for m in block.get("mechanisms", []):
            for code in m.get("derived", {}).get("success_metrics", []):
                if code not in codes:
                    fails.append(f"{m.get('id')}.derived.success_metrics: {code} not in data/wp5_indicators.json")
    return fails
```

Change the signature `def audit(kb, sections):` to `def audit(kb, sections, registry=None):` and add, directly before `return fails` at the end of `audit()`:

```python
    fails += success_metric_registry_fails(kb, registry_codes() if registry is None else registry)
```

Append to `scripts/kb_audit/test_build_wp5_mechanisms_kb.py`:

```python
def test_success_metrics_must_exist_in_ws4_registry():
    au = _load_audit()
    kb = {"demonstration_areas": {"macaronesia": {"mechanisms": [
        {"id": "mac_01", "derived": {"success_metrics": ["F_01", "ZZ_99"]}}]}}}
    fails = au.success_metric_registry_fails(kb, {"F_01", "C_02"})
    assert fails == ["mac_01.derived.success_metrics: ZZ_99 not in data/wp5_indicators.json"]
    assert au.success_metric_registry_fails(kb, None) == ["top.registry: data/wp5_indicators.json missing (WS-4)"]


def test_committed_kb_success_metrics_are_all_in_the_registry():
    au = _load_audit()
    kb = json.loads(KB_JSON.read_text(encoding="utf-8"))
    assert au.success_metric_registry_fails(kb, au.registry_codes()) == []
```

(`_load_audit` and `KB_JSON` already exist in that file; the two new tests need no extract, so they carry no `@needs_extract`.)

Run: `micromamba run -n shiny python -I -m pytest scripts/kb_audit/test_build_wp5_mechanisms_kb.py -q` and `micromamba run -n shiny python -I scripts/kb_audit/audit_wp5_mechanisms.py`
Expected: pytest all passed (or skipped where the extract is absent); audit prints `[audit] 0 failure(s)`. If a committed `success_metrics` code is missing, the registry transcription is wrong — fix the JSON, not the audit.

- [ ] **Step 7: Commit**

```bash
git -C /c/Users/arturas.baziukas/wt-ws4 add MarineSABRES_SES_Shiny/data/wp5_indicators.json MarineSABRES_SES_Shiny/functions/indicator_registry.R MarineSABRES_SES_Shiny/global.R MarineSABRES_SES_Shiny/tests/testthat/test-indicator-registry.R MarineSABRES_SES_Shiny/scripts/kb_audit/audit_wp5_mechanisms.py MarineSABRES_SES_Shiny/scripts/kb_audit/test_build_wp5_mechanisms_kb.py
git -C /c/Users/arturas.baziukas/wt-ws4 commit -m "feat(wp5): Posidonia, Annex 1 and Arctic indicators, registry loader, audit link to WS-2 (WS-4)"
```

---

### Task 3: Element indicator columns survive every save and load

**Files:**
- Create: `functions/indicator_snapshot.R` (first function only)
- Modify: `functions/data_structure.R` (the list-of-lists bind at ~line 882), `modules/auto_save_module.R` (line ~708), `global.R` (source after `indicator_registry.R`), `tests/run_json_loading_tests.R`, `tests/testthat/test-json-project-loading.R`
- Test: `tests/testthat/test-indicator-snapshot.R`, `tests/testthat/test-json-project-loading.R`

**Interfaces:**
- Consumes: `ISA_INDICATOR_COLUMNS`, `merge_collected_with_existing()` (unchanged), `normalize_json_project_data()`.
- Produces: `indicator_col(df, name)` → character vector, looked up case-insensitively ("" when absent; NA → ""). Used by Tasks 4–5.

- [ ] **Step 1: Write the failing tests**

`tests/testthat/test-indicator-snapshot.R`:

```r
# tests/testthat/test-indicator-snapshot.R
# WS-4: element indicator columns, registry snapshot, drift detection, module wiring.
library(testthat)
source_for_test(c("functions/isa_form_builders.R", "functions/ui_components.R",
                  "functions/indicator_registry.R", "functions/indicator_snapshot.R"))

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
  # auto_save_module.R serialised without na = "null", so a row with an empty
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

Append to `tests/testthat/test-json-project-loading.R` (end of file). It must also run under the standalone runner, which has no testthat helpers, so it sources `indicator_snapshot.R` the same way the file sources `data_structure.R`, and uses only `indicator_col()` (no registry lookup):

```r
# ============================================================================
# WS-4 (P7): indicator columns survive JSON and RDS round trips
# ============================================================================
if (!exists("indicator_col", mode = "function")) {
  source(file.path(project_root, "functions", "indicator_snapshot.R"), local = FALSE)
}

ws4_project <- function() list(project_id = "p_ws4", data = list(isa_data = list(
  activities = data.frame(ID = c("A001", "A002"), Name = c("Fishing", "Tourism"),
                          Indicator = c("Tuna share", NA), Indicator_Unit = c("%", NA),
                          Data_Source = c("Landings statistics", NA), Registry_Id = c("F_01", NA),
                          Registry_Version = c("1", NA), stringsAsFactors = FALSE))))

ws4_expect_columns <- function(pd, label) {
  a <- pd$data$isa_data$activities
  expect_true(is.data.frame(a), info = label)
  expect_equal(nrow(a), 2L, info = label)
  expect_equal(indicator_col(a, "Indicator"), c("Tuna share", ""), info = label)
  expect_equal(indicator_col(a, "Indicator_Unit"), c("%", ""), info = label)
  expect_equal(indicator_col(a, "Data_Source"), c("Landings statistics", ""), info = label)
  expect_equal(indicator_col(a, "Registry_Id"), c("F_01", ""), info = label)
  expect_equal(indicator_col(a, "Registry_Version"), c("1", ""), info = label)
}

test_that("WS-4 indicator columns survive JSON (both simplify modes, with/without na='null') and RDS round trips", {
  for (na_null in c(TRUE, FALSE)) {
    js <- if (na_null) jsonlite::toJSON(ws4_project(), auto_unbox = TRUE, null = "null", na = "null")
          else jsonlite::toJSON(ws4_project(), auto_unbox = TRUE, null = "null")
    for (sv in c(TRUE, FALSE)) {
      pd <- normalize_json_project_data(jsonlite::fromJSON(js, simplifyVector = sv))
      ws4_expect_columns(pd, sprintf("json na_null=%s simplifyVector=%s", na_null, sv))
    }
  }
  f <- tempfile(fileext = ".rds")
  saveRDS(ws4_project(), f)
  ws4_expect_columns(normalize_json_project_data(readRDS(f)), "rds")
})
```

- [ ] **Step 2: Run to see it fail**

Run: `"/c/Program Files/R/R-4.4.1/bin/Rscript.exe" -e "for (f in c('test-indicator-snapshot','test-json-project-loading')) testthat::test_file(file.path('tests/testthat', paste0(f, '.R')))"`
Expected: `could not find function "indicator_col"` errors (`source_for_test()` and the `exists()` guard skip the missing file silently, so the failure surfaces at the first call). The two merge tests and the normalisation test may already pass: they are regression guards for behaviour that exists today. Once `indicator_col()` exists, the ragged-row test and the `simplifyVector = FALSE` / no-`na` round-trip case still fail (the category becomes `NULL`) until the bind fix below.

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

`functions/data_structure.R` (~line 882, inside `normalize_json_project_data()`): replace the strict `do.call(rbind, lapply(el, function(x) as.data.frame(x, stringsAsFactors = FALSE)))` with a key-union bind, so rows with omitted or null fields still convert:

```r
          rows <- lapply(el, function(x) {
            x[vapply(x, is.null, logical(1))] <- NA   # JSON null -> NA, keep the key
            as.data.frame(x, stringsAsFactors = FALSE)
          })
          dplyr::bind_rows(rows)
```

(`dplyr` is already loaded by `global.R`; `bind_rows` fills missing columns with NA and treats all-NA logical columns as compatible with character. Keep the surrounding `tryCatch`.) Leave the `indicator` backfill at ~line 907 alone: names are lowercased at :893 before it runs, so it cannot add a duplicate (the normalisation test guards this).

`modules/auto_save_module.R:708`: add `na = "null"` to the `jsonlite::toJSON(...)` call, matching the other writers (`local_storage_module.R:694,764`, `server/modals.R:127`).

`global.R`: add `source("functions/indicator_snapshot.R", local = FALSE)` after the registry line.

`tests/run_json_loading_tests.R`: after the existing `source(file.path(project_root, "functions", "data_structure.R"), local = FALSE)` line, add

```r
source(file.path(project_root, "functions", "indicator_registry.R"), local = FALSE)
source(file.path(project_root, "functions", "indicator_snapshot.R"), local = FALSE)
```

- [ ] **Step 4: Run the tests, plus the load-integrity regressions**

Run: `"/c/Program Files/R/R-4.4.1/bin/Rscript.exe" -e "for (f in c('test-indicator-snapshot','test-isa-load-save-integrity','test-load-roundtrip-integrity','test-json-project-loading')) testthat::test_file(file.path('tests/testthat', paste0(f, '.R')))"`
Expected: every file `[ FAIL 0 | … ]`. Also run `"/c/Program Files/R/R-4.4.1/bin/Rscript.exe" tests/run_json_loading_tests.R` and expect its summary to report 0 failures.

- [ ] **Step 5: Commit**

```bash
git -C /c/Users/arturas.baziukas/wt-ws4 add MarineSABRES_SES_Shiny/functions/indicator_snapshot.R MarineSABRES_SES_Shiny/functions/data_structure.R MarineSABRES_SES_Shiny/modules/auto_save_module.R MarineSABRES_SES_Shiny/global.R MarineSABRES_SES_Shiny/tests/run_json_loading_tests.R MarineSABRES_SES_Shiny/tests/testthat/test-indicator-snapshot.R MarineSABRES_SES_Shiny/tests/testthat/test-json-project-loading.R
git -C /c/Users/arturas.baziukas/wt-ws4 commit -m "feat(isa): element indicator columns survive JSON and RDS save/load (WS-4)"
```

---

### Task 4: Form fields, picker with provenance, snapshot on save, version stamp

**Files:**
- Modify: `functions/isa_form_builders.R` (`build_entry_panel_ui`, new `isa_indicator_fields`), `functions/indicator_snapshot.R`, `modules/isa_data_entry_module.R` (`merge_saved` at ~line 341; `sync_to_project_data` at ~line 272; six `register_remove_observer` sites get a sibling call), `tests/testthat/test-isa-form-builders-multiselect.R`
- Test: `tests/testthat/test-indicator-snapshot.R` (append), `tests/testthat/test-isa-form-builders-multiselect.R`

**Interfaces:**
- Consumes: `indicator_picker_choices()`, `get_indicator()`, `indicator_col()`, `provenance_badge()` (`functions/ui_components.R:506`), `stamp_min_app_version()` (`functions/data_structure.R:1181`), `ISA_PREFIX_ELEMENT_KEY`, `ISA_ELEMENT_KEYS`, `WP5_INDICATOR_MIN_APP_VERSION`.
- Produces:
  - `isa_indicator_fields(i18n, element_key)` → list of 4 field defs (ids `registry`, `indicator`, `indunit`, `datasource`)
  - `collect_indicator_inputs(input, prefix, ids)` → df(`ID`, `Indicator`, `Indicator_Unit`, `Data_Source`, `Registry_Id`)
  - `apply_registry_snapshot(df, previous)` → df with blanks filled from the registry and `Registry_Version` set
  - `indicator_provenance_ui(code, i18n)` → badge tags for the selected entry, or `NULL`
  - `project_has_registry_snapshot(isa_data)` → `TRUE` when any element frame has a non-empty `Registry_Id`
  - `register_indicator_picker_observer(input, output, session, prefix, current_id, i18n)` → renders `output[[<prefix>_regbadge_<id>]]` and fills the text fields on pick

- [ ] **Step 1: Append the failing tests**

```r
# ---- Task 4: picker + snapshot ---------------------------------------------
fake_input <- function(...) list(...)

test_that("the entry panel renders a third row with the indicator fields, picker and badge slot for element prefixes", {
  ui <- as.character(build_entry_panel_ui(shiny::NS("m"), "p", "P001",
                     isa_fields_p(make_test_i18n(), c("")), make_test_i18n()))
  for (id in c("m-p_indicator_P001", "m-p_indunit_P001", "m-p_datasource_P001", "m-p_registry_P001",
               "m-p_regbadge_P001"))
    expect_match(ui, id, fixed = TRUE)
  # Non-element prefix with a real field list (an empty list errors in existing code at
  # isa_form_builders.R:59, unrelated to WS-4): no third row.
  ui_z <- as.character(build_entry_panel_ui(shiny::NS("m"), "zz", "Z1",
                       isa_fields_gb(make_test_i18n()), make_test_i18n()))
  expect_false(grepl("zz_registry_Z1", ui_z, fixed = TRUE))
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

test_that("the badge beside the picker shows the selected entry's provenance", {
  i18n <- make_test_i18n()
  pos <- as.character(indicator_provenance_ui("TUS_POS_SEAGRASS_SHOOT_DENSITY", i18n))
  expect_match(pos, "modules.wp5_mechanisms.provenance.wp5_derived", fixed = TRUE)
  expect_match(pos, "modules.wp5_mechanisms.provenance.toolbox_extension", fixed = TRUE)   # toolbox classification
  f1 <- as.character(indicator_provenance_ui("F_01", i18n))
  expect_false(grepl("wp5_derived", f1, fixed = TRUE))
  expect_match(f1, "modules.wp5_mechanisms.provenance.toolbox_extension", fixed = TRUE)
  stub <- as.character(indicator_provenance_ui("C_02", i18n))
  expect_match(stub, "modules.indicator_registry.stub_marker", fixed = TRUE)
  expect_match(stub, "modules.wp5_mechanisms.provenance.provisional", fixed = TRUE)
  expect_null(indicator_provenance_ui("", i18n))
})

test_that("project_has_registry_snapshot looks at the six element frames only", {
  expect_false(project_has_registry_snapshot(list()))
  expect_false(project_has_registry_snapshot(list(activities = data.frame(ID = "A001", Registry_Id = ""))))
  expect_true(project_has_registry_snapshot(list(activities = data.frame(ID = "A001", registry_id = "F_01"))))
  expect_false(project_has_registry_snapshot(list(responses = data.frame(ID = "R001", Registry_Id = "F_01"))))
})

test_that("merge_saved runs the snapshot for element prefixes only and the save path stamps the version (module source)", {
  s <- paste(readLines(file.path(PROJECT_ROOT, "modules", "isa_data_entry_module.R"), warn = FALSE), collapse = "\n")
  expect_match(s, "c(col_names, ISA_INDICATOR_COLUMNS)", fixed = TRUE)
  expect_match(s, "prefix %in% names(ISA_PREFIX_ELEMENT_KEY)", fixed = TRUE)
  expect_match(s, "apply_registry_snapshot(", fixed = TRUE)
  expect_match(s, "collect_indicator_inputs(input, prefix", fixed = TRUE)
  expect_match(s, "stamp_min_app_version(pd, WP5_INDICATOR_MIN_APP_VERSION)", fixed = TRUE)
  expect_equal(lengths(regmatches(s, gregexpr("register_indicator_picker_observer(input, output, session, ",
                                              s, fixed = TRUE))), 6L)
})

# ---- Task 4: module behaviour (testServer, real server) ----------------------
source_for_test(c("modules/isa_data_entry_module.R", "functions/data_structure.R", "functions/matrix_from_linked.R",
                  "functions/standard_entry_excel_import.R", "functions/project_transactions.R"))
# helper-stubs.R shadows the real server; re-bind it (P7 / test-isa-responses-entry.R pattern).
isa_data_entry_server <- get("isa_data_entry_server", envir = .GlobalEnv)

# setInputs for one panel's dynamically-suffixed inputs (setInputs does not
# interpolate names, so build them with paste0 + do.call).
set_panel <- function(session, prefix, sid, ...) {
  vals <- list(...)
  names(vals) <- paste0(prefix, "_", names(vals), "_", sid)
  do.call(session$setInputs, vals)
}
srv_args <- function(pdr) list(project_data_reactive = pdr, i18n = make_test_i18n(), event_bus = NULL)

test_that("picking in the panel saves the snapshot; hand edits survive save, reload and re-save", {
  f1 <- get_indicator("F_01"); rev1 <- as.character(f1$revision)
  pdr <- shiny::reactiveVal(list(project_id = "p1", data = list(isa_data = list())))
  testServer(isa_data_entry_server, args = srv_args(pdr), {
    session$flushReact()
    isa_data$pressures <- data.frame(ID = "P001", Name = "Overfishing", stringsAsFactors = FALSE)  # a_p target
    session$setInputs(add_a = 1)
    aid <- isa_data$a_panel_ids[[length(isa_data$a_panel_ids)]]
    set_panel(session, "a", aid, name = "Fishing", registry = "F_01")
    session$setInputs(save_ex4 = 1)
    a <- isa_data$activities
    expect_equal(indicator_col(a, "Registry_Id"), "F_01")
    expect_equal(indicator_col(a, "Registry_Version"), rev1)
    expect_equal(indicator_col(a, "Indicator"), f1$name)
    expect_equal(indicator_col(a, "Indicator_Unit"), f1$unit)
    expect_equal(indicator_col(pdr()$data$isa_data$activities, "Registry_Id"), "F_01")
    expect_equal(pdr()$min_app_version, WP5_INDICATOR_MIN_APP_VERSION)        # WS-0 stamp
    set_panel(session, "a", aid, indicator = "My share", indunit = "ratio")    # hand edits after the pick
    session$setInputs(save_ex4 = 2)
    a <- isa_data$activities
    expect_equal(indicator_col(a, "Indicator"), "My share")
    expect_equal(indicator_col(a, "Indicator_Unit"), "ratio")
    expect_equal(indicator_col(a, "Registry_Id"), "F_01")
    expect_equal(indicator_col(a, "Registry_Version"), rev1)
  })
  # save -> RDS -> load -> re-save in a fresh session: the row has no live panel and is carried over
  f <- tempfile(fileext = ".rds")
  saveRDS(shiny::isolate(pdr()), f)
  pdr2 <- shiny::reactiveVal(normalize_and_reconcile_project(readRDS(f)))
  testServer(isa_data_entry_server, args = srv_args(pdr2), {
    session$flushReact()
    session$setInputs(save_ex4 = 1)
    a <- isa_data$activities
    expect_equal(indicator_col(a, "Indicator"), "My share")
    expect_equal(indicator_col(a, "Indicator_Unit"), "ratio")
    expect_equal(indicator_col(a, "Registry_Id"), "F_01")
    expect_equal(indicator_col(a, "Registry_Version"), rev1)
  })
})

test_that("a save without a registry pick does not stamp min_app_version", {
  pdr <- shiny::reactiveVal(list(project_id = "p1", data = list(isa_data = list())))
  testServer(isa_data_entry_server, args = srv_args(pdr), {
    session$flushReact()
    isa_data$pressures <- data.frame(ID = "P001", Name = "Overfishing", stringsAsFactors = FALSE)  # a_p target
    session$setInputs(add_a = 1)
    aid <- isa_data$a_panel_ids[[length(isa_data$a_panel_ids)]]
    set_panel(session, "a", aid, name = "Fishing")
    session$setInputs(save_ex4 = 1)
    expect_equal(nrow(isa_data$activities), 1L)
    expect_null(pdr()$min_app_version)
  })
})

test_that("responses gain no indicator columns (ruling 9)", {
  pdr <- shiny::reactiveVal(list(project_id = "p1", data = list(isa_data = list())))
  testServer(isa_data_entry_server, args = srv_args(pdr), {
    isa_data$goods_benefits <- data.frame(ID = "GB001", Name = "Food", stringsAsFactors = FALSE)
    isa_data$drivers <- data.frame(ID = "D001", Name = "Demand", stringsAsFactors = FALSE)
    session$setInputs(add_response = 1)
    rid <- isa_data$r_panel_ids[[1]]
    set_panel(session, "r", rid, name = "MSP", linkedgb = "GB001", linkedd = "D001")
    session$setInputs(save_responses = 1)
    expect_equal(nrow(isa_data$responses), 1L)
    expect_false(any(tolower(names(isa_data$responses)) %in%
                     tolower(c("Indicator_Unit", "Data_Source", "Registry_Id", "Registry_Version"))))
  })
})
```

Update `tests/testthat/test-isa-form-builders-multiselect.R` (test "a Pressures panel renders its Linked-to-MPF field as a <select multiple>"): the Pressures panel now also renders the registry picker, whose first choice is `""` ("—"), so the whole-panel assertion at line 27 would fail. Replace

```r
  expect_false(grepl('<option value=""', html, fixed = TRUE))  # blank placeholder dropped
```

with

```r
  # Only the Linked select drops its blank placeholder; the WS-4 registry picker
  # in the same panel keeps its "—" choice on purpose.
  linked <- regmatches(html, regexpr('(?s)<select[^>]*id="isa-p_linkedmpf_P001".*?</select>', html, perl = TRUE))
  expect_length(linked, 1)
  expect_false(grepl('<option value=""', linked, fixed = TRUE))  # blank placeholder dropped
```

- [ ] **Step 2: Run to see it fail**

Run: `"/c/Program Files/R/R-4.4.1/bin/Rscript.exe" -e "testthat::test_file('tests/testthat/test-indicator-snapshot.R')"`
Expected: `could not find function "collect_indicator_inputs"` / `"apply_registry_snapshot"` / `"indicator_provenance_ui"` / `"project_has_registry_snapshot"`; the panel test fails because the ids are missing; the module-source test fails on the missing strings; the testServer tests fail because `Registry_Id` stays "" and `min_app_version` is NULL; the responses test still passes (it is a guard for the gate added below).

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
  # WS-4: indicator row for the six element prefixes only (not Responses).
  element_key <- if (exists("ISA_PREFIX_ELEMENT_KEY")) unname(ISA_PREFIX_ELEMENT_KEY[prefix]) else NA_character_
  row3 <- NULL
  if (length(element_key) == 1 && !is.na(element_key)) {
    row3 <- tagList(
      do.call(fluidRow, lapply(isa_indicator_fields(i18n, element_key), build_field)),
      fluidRow(column(12,
        uiOutput(ns(paste0(prefix, "_regbadge_", current_id))),
        tags$small(class = "text-muted", i18n$t("modules.indicator_registry.picker_help"))
      ))
    )
  }
```

and add `row3` as the last child of the returned `div(...)`. `build_field` renders a single select with grouped (named list) choices as is; `selectInput` accepts named lists, so nothing else changes.

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
  df <- df[, !(tolower(names(df)) %in% tolower(ISA_INDICATOR_COLUMNS)) | names(df) %in% ISA_INDICATOR_COLUMNS,
           drop = FALSE]
  ids <- indicator_col(df, "ID")
  prev_id <- indicator_col(previous, "ID")
  prev_reg <- indicator_col(previous, "Registry_Id"); prev_ver <- indicator_col(previous, "Registry_Version")
  for (i in seq_len(nrow(df))) {
    code <- df$Registry_Id[i]
    if (!nzchar(code)) { df$Registry_Version[i] <- ""; next }
    e <- get_indicator(code)
    if (is.null(e)) next                                   # unknown id: leave as-is; drift reports it
    if (!nzchar(df$Indicator[i])) df$Indicator[i] <- as.character(e$name)
    if (!nzchar(df$Indicator_Unit[i])) df$Indicator_Unit[i] <- as.character(e$unit %||% "")
    if (!nzchar(df$Data_Source[i])) df$Data_Source[i] <- paste(unlist(e$data_sources), collapse = "; ")
    j <- match(ids[i], prev_id)
    keep <- !is.na(j) && identical(prev_reg[j], code) && nzchar(prev_ver[j])
    df$Registry_Version[i] <- if (keep) prev_ver[j] else as.character(e$revision %||% 1L)
  }
  df
}

#' Provenance badges for the picked entry (spec P1), shown beside the picker.
indicator_provenance_ui <- function(code, i18n) {
  e <- get_indicator(code)
  if (is.null(e)) return(NULL)
  badge <- function(p) if (exists("provenance_badge", mode = "function")) provenance_badge(p, i18n) else NULL
  parts <- list(
    if (isTRUE(e$stub)) shiny::tags$span(class = "badge bg-secondary ms-1",
                                         i18n$t("modules.indicator_registry.stub_marker")),
    badge(e$provenance),
    if (identical(e$classification_provenance, "toolbox_extension") &&
        !identical(e$provenance, "toolbox_extension")) badge("toolbox_extension")
  )
  parts <- Filter(Negate(is.null), parts)
  if (length(parts) == 0) return(NULL)
  shiny::tags$div(class = "wp5-indicator-provenance mb-1", parts)
}

#' TRUE when any of the six element frames holds a non-empty Registry_Id.
project_has_registry_snapshot <- function(isa_data) {
  if (!is.list(isa_data)) return(FALSE)
  any(vapply(ISA_ELEMENT_KEYS, function(k) any(nzchar(indicator_col(isa_data[[k]], "Registry_Id"))),
             logical(1)))
}

#' Badge + auto-fill for one panel's picker. The text fields are filled as soon
#' as an entry is picked (UX only; the authoritative snapshot runs on save in
#' apply_registry_snapshot()).
register_indicator_picker_observer <- function(input, output, session, prefix, current_id, i18n) {
  sel_id <- paste0(prefix, "_registry_", current_id)
  output[[paste0(prefix, "_regbadge_", current_id)]] <- shiny::renderUI(
    indicator_provenance_ui(input[[sel_id]], i18n))
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
      # WS-4: only the six element categories carry indicator fields; Responses
      # (prefix "r") keep their original column set (plan rulings 3 and 9).
      is_el <- prefix %in% names(ISA_PREFIX_ELEMENT_KEY)
      cols <- if (is_el) c(col_names, ISA_INDICATOR_COLUMNS) else col_names
      # Indicator fields come from the third panel row for live rows; loaded
      # rows carry theirs over by ID inside merge_collected_with_existing().
      if (is_el && is.data.frame(collected) && nrow(collected) > 0 && "ID" %in% names(collected)) {
        ind <- collect_indicator_inputs(input, prefix, collected$ID)
        collected <- cbind(collected[, setdiff(names(collected), ISA_INDICATOR_COLUMNS), drop = FALSE],
                           ind[match(collected$ID, ind$ID), setdiff(names(ind), "ID"), drop = FALSE])
      }
      previous <- isa_data[[key]]
      df <- merge_collected_with_existing(previous, collected, pids, live, cols)
      if (is_el) df <- apply_registry_snapshot(df, previous)
      if (!is.null(linked_col) && !is.null(matrix_key)) {
        df <- fill_linked_from_matrix(df, linked_col,
                                      isa_data$adjacency_matrices[[matrix_key]], live)
      }
      df
    }
```

In `sync_to_project_data()`, directly before `project_data_reactive(pd)`, add:

```r
      # WS-0/WS-4: a project holding a registry snapshot needs an app that keeps
      # Registry_Id/Registry_Version (older apps drop unknown element columns).
      if (project_has_registry_snapshot(pd$data$isa_data)) {
        pd <- stamp_min_app_version(pd, WP5_INDICATOR_MIN_APP_VERSION)
      }
```

In each of the six `observeEvent(input$add_<prefix>, …)` handlers (`gb es mpf p a d`), directly after the `register_remove_observer(...)` call, add:

```r
      register_indicator_picker_observer(input, output, session, "<prefix>", current_id, i18n)
```

with `<prefix>` replaced by the handler's literal prefix (`"gb"`, `"es"`, `"mpf"`, `"p"`, `"a"`, `"d"`). Do not add it to `add_response`.

- [ ] **Step 6: Run the tests**

Run: `"/c/Program Files/R/R-4.4.1/bin/Rscript.exe" -e "for (f in c('test-indicator-snapshot','test-indicator-registry','test-isa-data-entry-module','test-isa-load-save-integrity','test-isa-form-builders-multiselect','test-isa-responses-entry','test-json-project-loading')) testthat::test_file(file.path('tests/testthat', paste0(f, '.R')))"`
Expected: all `[ FAIL 0 | … ]`.

- [ ] **Step 7: Commit**

```bash
git -C /c/Users/arturas.baziukas/wt-ws4 add MarineSABRES_SES_Shiny/functions/isa_form_builders.R MarineSABRES_SES_Shiny/functions/indicator_snapshot.R MarineSABRES_SES_Shiny/modules/isa_data_entry_module.R MarineSABRES_SES_Shiny/tests/testthat/test-indicator-snapshot.R MarineSABRES_SES_Shiny/tests/testthat/test-isa-form-builders-multiselect.R
git -C /c/Users/arturas.baziukas/wt-ws4 commit -m "feat(isa): indicator fields with WP5 registry picker and provenance; snapshot on save; min_app_version stamp (WS-4)"
```

---

### Task 5: Drift detection, persistent review link, diff modal and re-snapshot

**Files:**
- Modify: `functions/indicator_snapshot.R`, `modules/isa_data_entry_module.R` (UI header row; beside `warn_if_mistyped`; the project-change branch)
- Test: `tests/testthat/test-indicator-snapshot.R` (append)

**Interfaces:**
- Consumes: Task 4 functions; `load_indicator_registry()`; the `typing_state`-style reset point in the project observer.
- Produces:
  - `indicator_drift(isa_data)` → data.frame(`element_key, element_id, element_name, registry_id, snapshot_revision, current_revision, status, element_indicator, element_unit, element_source, registry_indicator, registry_unit, registry_source`), `status` ∈ `updated | missing`; zero rows when the registry is not loaded
  - `indicator_drift_keys(d)` → sorted `"<element_key>:<element_id>"` keys
  - `apply_registry_resnapshot(df, ids)` → df where rows whose ID is in `ids` get Indicator/Unit/Source/Version overwritten from the current entry
  - Module: `warn_if_indicator_drift()`, `drift_state` env (`last`, `notified`, `findings`), `drift_rv` reactiveVal, `output$indicator_drift_bar` (persistent link `input$indicator_drift_open`), toast action `input$indicator_drift_open_toast`, `show_drift_modal()`, `input$indicator_drift_ids` (checkbox group), `input$indicator_drift_apply` (button); notification id `ns("indicator_drift")`

- [ ] **Step 1: Append the failing tests**

```r
# ---- Task 5: drift ----------------------------------------------------------
cur_rev <- as.character(get_indicator("F_01")$revision)
isa_drift <- function(ver = "0", reg = "F_01") list(
  activities = data.frame(ID = c("A001", "A002"), Name = c("Fishing", "Tourism"),
                          Indicator = c("Tuna share", ""), Indicator_Unit = c("%", ""), Data_Source = c("", ""),
                          Registry_Id = c(reg, ""), Registry_Version = c(ver, ""), stringsAsFactors = FALSE))

test_that("an older registry revision is reported as drift with the value diff; current is not", {
  d <- indicator_drift(isa_drift("0"))
  expect_equal(d$element_id, "A001")
  expect_equal(d$status, "updated")
  expect_equal(d$current_revision, cur_rev)
  expect_equal(d$element_indicator, "Tuna share")                   # roadmap §7.6: snapshot value ...
  expect_equal(d$registry_indicator, get_indicator("F_01")$name)    # ... vs current registry value
  expect_equal(d$registry_unit, get_indicator("F_01")$unit)
  expect_equal(nrow(indicator_drift(isa_drift(cur_rev))), 0L)
})

test_that("missing registry ids are reported, not updated", {
  d <- indicator_drift(isa_drift("1", reg = "GONE_99"))
  expect_equal(d$status, "missing")
  df <- apply_registry_resnapshot(isa_drift("1", reg = "GONE_99")$activities, "A001")
  expect_equal(df$Indicator[1], "Tuna share")                      # untouched
})

test_that("an unavailable registry reports no drift (nothing is flagged missing)", {
  expect_warning(load_indicator_registry(path = tempfile(fileext = ".json"), force_reload = TRUE), "registry")
  expect_equal(nrow(indicator_drift(isa_drift("0"))), 0L)
  load_indicator_registry(force_reload = TRUE)                     # restore
  expect_equal(nrow(indicator_drift(isa_drift("0"))), 1L)
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
  expect_equal(indicator_drift_keys(indicator_drift(list())), character(0))
})

proj_with_snapshot <- function(ver, pid = "p1", reg = "F_01") list(project_id = pid, data = list(isa_data = list(
  activities = data.frame(ID = "A001", Name = "Fishing", Sector = "", Description = "", LinkedP = "",
                          Scale = "", Frequency = "", Indicator = "Tuna share", Indicator_Unit = "%",
                          Data_Source = "", Registry_Id = reg, Registry_Version = ver, stringsAsFactors = FALSE),
  adjacency_matrices = list(), user_edited_matrices = list())))

test_that("loading a stale snapshot notifies once, shows the review link; re-snapshot via the modal clears it", {
  pdr <- shiny::reactiveVal(proj_with_snapshot("0"))
  testServer(isa_data_entry_server, args = srv_args(pdr), {
    session$flushReact()
    expect_equal(drift_state$notified, 1L)
    expect_equal(drift_state$last, "activities:A001")
    expect_match(as.character(output$indicator_drift_bar$html), "indicator_drift_open", fixed = TRUE)
    pdr(modifyList(pdr(), list(metadata = list(saved_at = 2)))); session$flushReact()
    expect_equal(drift_state$notified, 1L)                         # same findings: silent
    session$setInputs(indicator_drift_open = 1)                     # persistent link opens the modal
    session$setInputs(indicator_drift_ids = "activities:A001")
    session$setInputs(indicator_drift_apply = 1)
    expect_equal(indicator_col(isa_data$activities, "Registry_Version"), cur_rev)
    expect_equal(indicator_col(isa_data$activities, "Indicator"), get_indicator("F_01")$name)
    expect_length(drift_state$last, 0)
    expect_equal(nrow(drift_rv()), 0L)                              # link disappears
  })
})

test_that("a missing-only drift review opens and applies without error and changes nothing", {
  pdr <- shiny::reactiveVal(proj_with_snapshot("1", reg = "GONE_99"))
  testServer(isa_data_entry_server, args = srv_args(pdr), {
    session$flushReact()
    expect_equal(drift_state$findings$status, "missing")
    expect_no_error(session$setInputs(indicator_drift_open = 1))
    expect_no_error(session$setInputs(indicator_drift_ids = ":", indicator_drift_apply = 1))   # bogus pick
    expect_equal(indicator_col(isa_data$activities, "Registry_Id"), "GONE_99")
    expect_equal(indicator_col(isa_data$activities, "Indicator"), "Tuna share")
    expect_equal(indicator_col(isa_data$activities, "Registry_Version"), "1")
  })
})

test_that("dismissing keeps the data and the review link; same-project writes stay silent; a new session re-notifies", {
  pdr <- shiny::reactiveVal(proj_with_snapshot("0"))
  testServer(isa_data_entry_server, args = srv_args(pdr), {
    session$flushReact()
    expect_equal(drift_state$notified, 1L)
    session$setInputs(indicator_drift_open = 1)                     # open, then close without applying
    pdr(modifyList(pdr(), list(metadata = list(saved_at = 3)))); session$flushReact()
    expect_equal(drift_state$notified, 1L)
    expect_equal(indicator_col(isa_data$activities, "Registry_Version"), "0")
    expect_equal(drift_state$findings$element_id, "A001")
    expect_match(as.character(output$indicator_drift_bar$html), "indicator_drift_open", fixed = TRUE)
  })
  pdr2 <- shiny::reactiveVal(proj_with_snapshot("0"))               # next load (new session)
  testServer(isa_data_entry_server, args = srv_args(pdr2), {
    session$flushReact()
    expect_equal(drift_state$notified, 1L)
  })
})

test_that("a current snapshot records no drift; switching project resets the dedup", {
  pdr <- shiny::reactiveVal(proj_with_snapshot(cur_rev))
  testServer(isa_data_entry_server, args = srv_args(pdr), {
    session$flushReact()
    expect_equal(drift_state$notified, 0L)
  })
  # Same stale element ID in two projects: only the project-change reset of
  # drift_state$last lets p2 notify again (this fails without that line).
  pdr2 <- shiny::reactiveVal(proj_with_snapshot("0", pid = "p1"))
  testServer(isa_data_entry_server, args = srv_args(pdr2), {
    session$flushReact()
    expect_equal(drift_state$notified, 1L)
    pdr2(proj_with_snapshot("0", pid = "p2")); session$flushReact()
    expect_equal(drift_state$notified, 2L)
  })
})
```

- [ ] **Step 2: Run to see it fail**

Run: `"/c/Program Files/R/R-4.4.1/bin/Rscript.exe" -e "testthat::test_file('tests/testthat/test-indicator-snapshot.R')"`
Expected: errors `could not find function "indicator_drift"` / `"apply_registry_resnapshot"` / `"indicator_drift_keys"`; the module tests fail with `object 'drift_state' not found`.

- [ ] **Step 3: Implement the pure functions** (append to `functions/indicator_snapshot.R`)

```r
#' Registry drift across element frames (pure). status: "updated" when the
#' entry's revision is newer than the snapshot, "missing" when the id is gone.
#' Returns zero rows when the registry itself is not loaded, so a missing or
#' malformed registry file never flags every linked element as missing.
indicator_drift <- function(isa_data) {
  empty <- data.frame(element_key = character(), element_id = character(), element_name = character(),
                      registry_id = character(), snapshot_revision = character(),
                      current_revision = character(), status = character(),
                      element_indicator = character(), element_unit = character(), element_source = character(),
                      registry_indicator = character(), registry_unit = character(), registry_source = character(),
                      stringsAsFactors = FALSE)
  if (!is.list(isa_data) || length(load_indicator_registry()$entries) == 0) return(empty)
  out <- list()
  for (key in ISA_ELEMENT_KEYS) {
    df <- isa_data[[key]]
    if (!is.data.frame(df) || nrow(df) == 0) next
    reg <- indicator_col(df, "Registry_Id"); ver <- indicator_col(df, "Registry_Version")
    ids <- indicator_col(df, "ID"); nms <- indicator_col(df, "Name")
    ind <- indicator_col(df, "Indicator"); unit <- indicator_col(df, "Indicator_Unit")
    src <- indicator_col(df, "Data_Source")
    for (i in which(nzchar(reg))) {
      e <- get_indicator(reg[i])
      cur <- if (is.null(e)) "" else as.character(e$revision %||% 1L)
      snap <- suppressWarnings(as.integer(ver[i]))
      status <- if (is.null(e)) "missing"
                else if (is.na(snap) || snap < as.integer(cur)) "updated" else NA_character_
      if (is.na(status)) next
      out[[length(out) + 1]] <- data.frame(
        element_key = key, element_id = ids[i], element_name = nms[i],
        registry_id = reg[i], snapshot_revision = ver[i], current_revision = cur, status = status,
        element_indicator = ind[i], element_unit = unit[i], element_source = src[i],
        registry_indicator = if (is.null(e)) "" else as.character(e$name),
        registry_unit = if (is.null(e)) "" else as.character(e$unit %||% ""),
        registry_source = if (is.null(e)) "" else paste(unlist(e$data_sources), collapse = "; "),
        stringsAsFactors = FALSE)
    }
  }
  if (length(out) == 0) empty else do.call(rbind, out)
}

#' Dedup keys for drift findings: sorted "<element_key>:<element_id>".
indicator_drift_keys <- function(d) {
  if (!is.data.frame(d) || nrow(d) == 0) return(character(0))
  sort(paste0(d$element_key, ":", d$element_id))
}

#' Overwrite the chosen rows from the current registry entry (user-confirmed).
apply_registry_resnapshot <- function(df, ids) {
  if (!is.data.frame(df) || nrow(df) == 0 || length(ids) == 0) return(df)
  idcol <- which(tolower(names(df)) == "id")[1]
  if (is.na(idcol)) return(df)
  for (i in which(as.character(df[[idcol]]) %in% ids)) {
    e <- get_indicator(indicator_col(df, "Registry_Id")[i])
    if (is.null(e)) next
    set <- function(col, val) {
      h <- which(tolower(names(df)) == tolower(col))
      if (!length(h)) { df[[col]] <<- ""; h <- ncol(df) }
      df[i, h[1]] <<- val
    }
    set("Indicator", as.character(e$name))
    set("Indicator_Unit", as.character(e$unit %||% ""))
    set("Data_Source", paste(unlist(e$data_sources), collapse = "; "))
    set("Registry_Version", as.character(e$revision %||% 1L))
  }
  df
}
```

- [ ] **Step 4: Wire the module**

In `isa_data_entry_ui()`, change the header row to carry the persistent link:

```r
    fluidRow(
      column(12,
        uiOutput(ns("isa_header")),
        uiOutput(ns("indicator_drift_bar"))   # WS-4: shown while registry drift is unresolved
      )
    ),
```

Directly after the `warn_if_mistyped` function definition, add:

```r
    # WS-4 registry drift: warn (never rewrite). Same dedup/reset pattern as the
    # typing lint (only NEW findings toast; reset on project change). A sticky
    # toast plus a persistent link under the header open the review modal, so
    # dismissing the toast never loses access (plan ruling 5).
    drift_state <- new.env(parent = emptyenv())
    drift_state$last <- character(0)
    drift_state$notified <- 0L
    drift_state$findings <- NULL
    drift_rv <- reactiveVal(NULL)            # drives output$indicator_drift_bar

    refresh_drift_findings <- function() {
      d <- indicator_drift(isolate(reactiveValuesToList(isa_data)))
      drift_state$findings <- d
      drift_rv(d)
      d
    }

    drift_count_msg <- function(key, n) {
      fmt <- i18n$t(key)
      if (grepl("%1$d", fmt, fixed = TRUE)) tryCatch(sprintf(fmt, n), error = function(e) fmt) else fmt
    }

    warn_if_indicator_drift <- function() {
      d <- refresh_drift_findings()
      keys <- indicator_drift_keys(d)
      new_keys <- setdiff(keys, drift_state$last)
      drift_state$last <- keys
      if (length(new_keys) == 0) return(invisible(NULL))
      drift_state$notified <- drift_state$notified + 1L
      n_upd <- sum(d$status == "updated")
      n_mis <- sum(d$status == "missing")
      msg <- paste(c(
        if (n_upd > 0) drift_count_msg("modules.indicator_registry.drift_found", n_upd),
        if (n_mis > 0) drift_count_msg("modules.indicator_registry.drift_found_missing", n_mis)
      ), collapse = " ")
      showNotification(msg, id = ns("indicator_drift"), type = "warning", duration = NULL, session = session,
                       action = actionLink(ns("indicator_drift_open_toast"),
                                           i18n$t("modules.indicator_registry.drift_review")))
    }

    output$indicator_drift_bar <- renderUI({
      d <- drift_rv()
      if (!is.data.frame(d) || nrow(d) == 0) return(NULL)
      div(class = "alert alert-warning py-1 px-2 mb-2",
          actionLink(ns("indicator_drift_open"),
                     paste0(i18n$t("modules.indicator_registry.drift_link"), " (", nrow(d), ")")))
    })

    drift_diff_table <- function(row) {
      tags$table(class = "table table-sm mb-2",
        tags$thead(tags$tr(tags$th(i18n$t("modules.indicator_registry.drift_col_field")),
                           tags$th(i18n$t("modules.indicator_registry.drift_col_element")),
                           tags$th(i18n$t("modules.indicator_registry.drift_col_registry")))),
        tags$tbody(
          tags$tr(tags$td(i18n$t("modules.indicator_registry.field_indicator")),
                  tags$td(row$element_indicator), tags$td(row$registry_indicator)),
          tags$tr(tags$td(i18n$t("modules.indicator_registry.field_unit")),
                  tags$td(row$element_unit), tags$td(row$registry_unit)),
          tags$tr(tags$td(i18n$t("modules.indicator_registry.field_data_source")),
                  tags$td(row$element_source), tags$td(row$registry_source))))
    }

    show_drift_modal <- function() {
      d <- drift_state$findings
      if (!is.data.frame(d) || nrow(d) == 0) return(invisible(NULL))
      upd <- d[d$status == "updated", , drop = FALSE]
      mis <- d[d$status == "missing", , drop = FALSE]
      showModal(modalDialog(
        title = i18n$t("modules.indicator_registry.drift_title"),
        if (nrow(upd) > 0) tagList(
          h5(i18n$t("modules.indicator_registry.drift_status_updated")),
          p(i18n$t("modules.indicator_registry.drift_explain")),
          checkboxGroupInput(ns("indicator_drift_ids"), NULL,
            choiceNames = lapply(seq_len(nrow(upd)), function(i) tagList(
              strong(paste0(upd$element_name[i], " (", upd$registry_id[i], ": ",
                            upd$snapshot_revision[i], " → ", upd$current_revision[i], ")")),
              drift_diff_table(upd[i, , drop = FALSE]))),
            choiceValues = paste0(upd$element_key, ":", upd$element_id))),
        if (nrow(mis) > 0) tagList(
          h5(i18n$t("modules.indicator_registry.drift_status_missing")),
          p(class = "text-muted", i18n$t("modules.indicator_registry.drift_missing_explain")),
          tags$ul(lapply(seq_len(nrow(mis)), function(i)
            tags$li(paste0(mis$element_name[i], " (", mis$registry_id[i], ")"))))),
        footer = if (nrow(upd) > 0) {
          tagList(modalButton(i18n$t("common.buttons.cancel")),
                  actionButton(ns("indicator_drift_apply"), i18n$t("modules.indicator_registry.drift_apply"),
                               class = "btn-primary"))
        } else {
          modalButton(i18n$t("common.buttons.close"))
        }))
    }
    observeEvent(input$indicator_drift_open, show_drift_modal())
    observeEvent(input$indicator_drift_open_toast, show_drift_modal())

    observeEvent(input$indicator_drift_apply, {
      d <- drift_state$findings
      valid <- if (is.data.frame(d) && nrow(d) > 0) {
        paste0(d$element_key, ":", d$element_id)[d$status == "updated"]
      } else character(0)
      picks <- intersect(as.character(input$indicator_drift_ids), valid)   # drops bogus and missing picks
      for (key in unique(sub(":.*$", "", picks))) {
        ids <- sub("^[^:]+:", "", picks[startsWith(picks, paste0(key, ":"))])
        isa_data[[key]] <- apply_registry_resnapshot(isa_data[[key]], ids)
      }
      removeModal()
      d <- refresh_drift_findings()
      drift_state$last <- indicator_drift_keys(d)
      if (nrow(d) == 0) removeNotification(ns("indicator_drift"), session = session)
      if (length(picks) > 0) sync_to_project_data()
    })
```

In the project-change branch, after `typing_state$last <- character(0)`, add:

```r
          drift_state$last <- character(0)     # WS-4: a new project is checked afresh
          drift_state$findings <- NULL
          drift_rv(NULL)
          removeNotification(ns("indicator_drift"), session = session)
```

After `warn_if_mistyped()` in the load branch, add `warn_if_indicator_drift()`.

`common.buttons.cancel` and `common.buttons.close` both exist in `translations/common/buttons.json` (lines 47 and 58); confirm with `grep -n '"common.buttons.c' translations/common/buttons.json` and record it in the ledger.

- [ ] **Step 5: Run the tests**

Run: `"/c/Program Files/R/R-4.4.1/bin/Rscript.exe" -e "for (f in c('test-indicator-snapshot','test-isa-load-save-integrity','test-wp5-typing-lint','test-matrix-alignment-on-load','test-isa-data-entry-module')) testthat::test_file(file.path('tests/testthat', paste0(f, '.R')))"`
Expected: all `[ FAIL 0 | … ]`. If `session$setInputs(indicator_drift_apply = 1)` does not trigger the observer inside `testServer`, check that the apply observer reads only inputs and `drift_state` (it must not depend on the modal having rendered). Fix the code, not the assertion. To confirm the project-switch test guards the reset, temporarily delete `drift_state$last <- character(0)` from the project-change branch, re-run, see `notified` stay 1, and restore it.

- [ ] **Step 6: Commit**

```bash
git -C /c/Users/arturas.baziukas/wt-ws4 add MarineSABRES_SES_Shiny/functions/indicator_snapshot.R MarineSABRES_SES_Shiny/modules/isa_data_entry_module.R MarineSABRES_SES_Shiny/tests/testthat/test-indicator-snapshot.R
git -C /c/Users/arturas.baziukas/wt-ws4 commit -m "feat(isa): WP5 indicator registry drift: persistent review link, value diff, user-confirmed re-snapshot (WS-4)"
```

---

### Task 6: Translations, provenance badge keys, CHANGELOG

**Files:**
- Create: `translations/modules/indicator_registry.json`
- Modify: `translations/modules/wp5_mechanisms.json` (two badge keys), `functions/ui_components.R` (two `# i18n-ref:` sentinels in `provenance_badge()`), `CHANGELOG.md` (under `[Unreleased]`, below the WS-3b entry)
- Test: `tests/testthat/test-indicator-snapshot.R` (append), i18n gates

**Interfaces:**
- Consumes: every `modules.indicator_registry.*` key used in Tasks 2–5, and `modules.wp5_mechanisms.provenance.{wp5_derived,toolbox_extension,provisional}` used by the picker labels and `indicator_provenance_ui()`.
- Produces: the translation file (same layout as `translations/modules/wp5_vocabulary.json`: `languages` array + `translation` object) and the two new badge keys in `wp5_mechanisms.json` (each key defined in exactly one file).

- [ ] **Step 1: Append the failing test**

```r
test_that("every indicator-registry and badge key used in code exists in all 9 languages, defined once", {
  langs <- c("en","es","fr","de","lt","pt","it","no","el")
  tr <- jsonlite::fromJSON(file.path(PROJECT_ROOT, "translations", "modules", "indicator_registry.json"),
                           simplifyVector = FALSE)$translation
  mech <- jsonlite::fromJSON(file.path(PROJECT_ROOT, "translations", "modules", "wp5_mechanisms.json"),
                             simplifyVector = FALSE)$translation
  keys <- c("picker_none", "picker_label", "picker_help", "picker_group_suggested", "picker_group_other",
            "field_indicator", "field_unit", "field_data_source", "da.macaronesia", "da.tuscan", "da.arctic",
            "stub_marker", "drift_found", "drift_found_missing", "drift_review", "drift_link", "drift_title",
            "drift_explain", "drift_missing_explain", "drift_apply", "drift_status_updated", "drift_status_missing",
            "drift_col_field", "drift_col_element", "drift_col_registry")
  for (k in paste0("modules.indicator_registry.", keys)) {
    expect_false(is.null(tr[[k]]), info = k)
    for (l in langs) expect_true(nzchar(tr[[k]][[l]] %||% ""), info = paste(k, l))
  }
  for (k in paste0("modules.wp5_mechanisms.provenance.", c("wp5_derived", "toolbox_extension", "provisional"))) {
    expect_false(is.null(mech[[k]]), info = k)
    expect_null(tr[[k]])                                            # defined in wp5_mechanisms.json only
    for (l in langs) expect_true(nzchar(mech[[k]][[l]] %||% ""), info = paste(k, l))
  }
  for (k in c("drift_found", "drift_found_missing"))
    for (l in langs)
      expect_true(grepl("%1$d", tr[[paste0("modules.indicator_registry.", k)]][[l]], fixed = TRUE), info = paste(k, l))
  ui <- paste(readLines(file.path(PROJECT_ROOT, "functions", "ui_components.R"), warn = FALSE), collapse = "\n")
  for (p in c("toolbox_extension", "provisional"))
    expect_match(ui, paste0("# i18n-ref: modules.wp5_mechanisms.provenance.", p), fixed = TRUE)
})
```

- [ ] **Step 2: Run to see it fail**

Run: `"/c/Program Files/R/R-4.4.1/bin/Rscript.exe" -e "testthat::test_file('tests/testthat/test-indicator-snapshot.R')"`
Expected: the new test fails with a `lexical error` from `jsonlite::fromJSON()` on the missing `indicator_registry.json` (a missing path is parsed as JSON text, not reported as "cannot open file").

- [ ] **Step 3: Write the translation files**

`translations/modules/indicator_registry.json` — English source strings (translate each into es, fr, de, lt, pt, it, no, el as genuine translations, never English copies; keep `%1$d` in the two count strings):

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
| stub_marker | Stub: awaiting partner fiche |
| drift_found | %1$d element indicator(s) were copied from an older version of the WP5 indicator registry. Nothing was changed. |
| drift_found_missing | %1$d element indicator(s) refer to entries that are no longer in the WP5 indicator registry. Nothing was changed. |
| drift_review | Review |
| drift_link | Review WP5 indicator registry updates |
| drift_title | WP5 indicator registry updates |
| drift_explain | The registry entries below have changed since they were copied into your elements. Tick the elements to update with the current registry values. |
| drift_missing_explain | These elements refer to registry entries that no longer exist. Their values are kept unchanged. |
| drift_apply | Update selected |
| drift_status_updated | Updated in the registry |
| drift_status_missing | No longer in the registry |
| drift_col_field | Field |
| drift_col_element | In your element |
| drift_col_registry | Current registry |

Write the file with the Write tool (never a shell heredoc). Mirror the structure of `translations/modules/wp5_vocabulary.json` exactly.

`translations/modules/wp5_mechanisms.json`: add, directly after the existing `"modules.wp5_mechanisms.provenance.wp5_derived"` object:

```json
    "modules.wp5_mechanisms.provenance.toolbox_extension": {
      "en": "Toolbox extension",
      "es": "Extensión de la herramienta",
      "fr": "Extension de l'outil",
      "de": "Toolbox-Erweiterung",
      "lt": "Įrankio papildinys",
      "pt": "Extensão da ferramenta",
      "it": "Estensione dello strumento",
      "no": "Verktøyutvidelse",
      "el": "Επέκταση εργαλείου"
    },
    "modules.wp5_mechanisms.provenance.provisional": {
      "en": "Provisional",
      "es": "Provisional",
      "fr": "Provisoire",
      "de": "Vorläufig",
      "lt": "Preliminarus",
      "pt": "Provisório",
      "it": "Provvisorio",
      "no": "Foreløpig",
      "el": "Προσωρινό"
    },
```

(First check `grep -rn "provenance.toolbox_extension\|provenance.provisional" translations/` returns nothing, so each key is defined once.)

`functions/ui_components.R`, in `provenance_badge()`, below the existing two sentinels, add:

```r
  # i18n-ref: modules.wp5_mechanisms.provenance.toolbox_extension
  # i18n-ref: modules.wp5_mechanisms.provenance.provisional
```

and update its roxygen `@param provenance` line to `"wp5_prefinal" | "wp5_derived" | "toolbox_extension" | "provisional"`.

- [ ] **Step 4: CHANGELOG**

Under `## [Unreleased]`, add:

```markdown
### Added (WP5 WS-4)
- WP5 indicator registry (`data/wp5_indicators.json`): 11 Macaronesia fiche-set indicators (4 stubs pending partner fiches), 33 Posidonia indicators with Table 18 reference ranges, 46 Annex 1 DAPSIWRM-typed indicators (28 Tuscan, 18 Macaronesia), 5 Arctic descriptive indicators (Faroe Islands). Every WP5 value cites D5.2 v5 line ranges, and tests check its quotes against a committed extract. The WS-2 mechanism audit now fails when a mechanism's success metric is not in the registry.
- Standard Entry: every element (not Responses) now has Indicator, Unit and Data source fields and a WP5 indicator picker that shows each entry's provenance. Picking copies the values (snapshot) and records the registry entry and revision; such projects are stamped `min_app_version` 1.23.0.
- On project load, a warning appears when a copied indicator has since changed in, or been removed from, the registry; a persistent link opens a review that compares the element's values with the registry's, and the user chooses which elements to update.
```

- [ ] **Step 5: Run the i18n gates**

Run:
`"/c/Program Files/R/R-4.4.1/bin/Rscript.exe" -e "for (f in c('test-indicator-snapshot','test-i18n-duplicate-keys','test-i18n-enforcement','test-i18n-english-fallback')) testthat::test_file(file.path('tests/testthat', paste0(f, '.R')))"`
and `micromamba run -n shiny python -I scripts/_i18n_audit.py`
Expected: all `[ FAIL 0 | … ]`; audit `Totals: … missing=0 … hardcoded=0`.

- [ ] **Step 6: Commit**

```bash
git -C /c/Users/arturas.baziukas/wt-ws4 add MarineSABRES_SES_Shiny/translations/modules/indicator_registry.json MarineSABRES_SES_Shiny/translations/modules/wp5_mechanisms.json MarineSABRES_SES_Shiny/functions/ui_components.R MarineSABRES_SES_Shiny/CHANGELOG.md MarineSABRES_SES_Shiny/tests/testthat/test-indicator-snapshot.R
git -C /c/Users/arturas.baziukas/wt-ws4 commit -m "feat(i18n): WP5 indicator registry strings and provenance badges in 9 languages; changelog (WS-4)"
```

---

## Partner gate (carried into the final report, not a task)

- Macaronesia partner: the 7 fiche extracts, the code remap (F_02→F_01, F_03→F_02, F_04→F_03, M_03→M_02), T_03's canonical meaning, the C_01 role reading (interpretation bridge L10823–10835 rather than the interleaved table), the stubs' criterion citations, and every `classification_provenance: toolbox_extension` assignment (dapsiwrm_type + pathway_segment).
- Tuscan partner: the Table 17/18 transcription, the Posidonia `marine_processes`/`ecosystem_services` split, and the Annex 1 Table 6/7 Type assignments by stacked-label count (with the `caveat`s where the layout disagrees).
- Release: bump `VERSION` to 1.23.0 in the release commit; until then a 1.22.2 dev build shows the downgrade warning on projects it saved with a registry pick.
- Follow-ups: indicators on Responses; MS5.1 typed tables; translated indicator names; Arctic Greenland/Iceland price and landings tables.

---

## Rev 2 changes (review `wf_5580622f-839`)

Findings are grouped by substance; every confirmed id appears once.

| Finding id(s) | What changed |
|---|---|
| source-fidelity-1, tests-executability-1 | Extract script splits on `\n` only (`split_lines()`: CRLF normalised, trailing empty dropped), keeps `EXPECTED_LINES = 13426`, strips `\f` from emitted lines; ruling 1 explains why `splitlines()` is wrong; Step 2 checks `37.77%` at `L11147` and zero form feeds. |
| code-integration-1, tests-executability-2, spec-coverage-1 | New `source_set` field (ruling 12, constant `WP5_INDICATOR_SOURCE_SETS`); `list_indicators(source_set=)`; required-field, vocabulary and code-family tests; loader test counts the fiche set (11; 7 without stubs) and asserts the DA-wide count is larger. |
| source-fidelity-2 | Worked Annex 1 entry is `source_type: "Activity"` / `activities` with a caveat; ruling 13 assigns Table 6/7 Types by stacked-label count (with the per-table counts); test asserts the anchorage type; Annex 1 row counts fixed at 28 + 18. |
| source-fidelity-3 | RANGES `(9015, 9142)`; Table 7 rule L9020–9140 (L9143 = Annex 2); `"Ecosystem Service"` added to `dapsiwrm_type_map`. |
| source-fidelity-4 | Ruling 11: ↔ and → mean stable; direction from the symbol cell only; ordinal rule for C_01; F_01 direction test. |
| source-fidelity-5 | F_01 scenarios from "Table 1 Scenario-based assumptions" L11271–11313 (with the "Table 2" caveat), early warning L11564–11585, lines `[10986, 11585]`; worked entry now carries the four directions and early-warning levers. |
| source-fidelity-6 | C_01: baseline from Table 2 L10532–10685 (`value_text`, `value: null`), scenario 0/+/++/+++ from Table 3 L10730–10816, early warning Table 5 L10916–10980. |
| source-fidelity-7 | ARC_PRICE renamed "Average retail price by species (midpoint), Faroe Islands (2024)" with the ex-vessel caveat and lines `[1863, 1896]`; ARC_LANDINGS scoped to the Faroe Islands; RANGES `(1863, 1896)`; Greenland/Iceland tables listed as follow-up; test asserts "retail". |
| source-fidelity-8 | Ruling 7: "starts with Primary → primary, else supporting" fallback; C_01 roles from the interpretation bridge L10823–10835. |
| source-fidelity-9 | F_02 (CPUE): `baseline: []`, `data_gap: true`, caveat; scenario directions from Table 1 L11728–11760; duplicated EQ row noted; test added. |
| source-fidelity-10 | Posidonia worked entry: code `TUS_POS_SEAGRASS_SHOOT_DENSITY` (Table 18 name rule; the spec's `TUS_POS_SHOOT_DENSITY` was an example), `name` verbatim from Table 17, verbatim `text` + separate `comment`, quotes as on-line fragments; explicit 33-row code/type table. |
| spec-coverage-11 | Explicit Posidonia classification table (leaf area index = Habitat complexity, stable isotopes = Trophic linkages, Fish & invertebrate biomass = `marine_processes`, Seagrass biomass production = `ecosystem_services`); Annex 1 `pathway_segment` rule (ruling 8) with a test. |
| spec-coverage-9 | Stubs carry `criterion_roles` with `role: null` and a quoted citing phrase (EC/EQ from L4993–5002 and L5122–5129); RANGES merged to `(4985, 5132)`; tests require ≥1 role key and null roles; vocabulary test reads `r$role`. |
| spec-coverage-10 | Required fields gain `annex_code`, `data_sources`, `source_set`; `source_ref.lines` + quotes required for `wp5_source`, `wp5_derived` and `provisional`. |
| code-integration-2, tests-executability-9 | `test-isa-form-builders-multiselect.R` narrowed to the Linked select; Task 4 run list names that file (no `file.exists` guard) plus `test-isa-responses-entry` and `test-json-project-loading`. |
| code-integration-3, tests-executability-3, spec-coverage-7, ux-i18n-04 | Negative panel test uses a real field list (`isa_fields_gb`) with prefix `zz`. |
| code-integration-4, tests-executability-4, ux-i18n-01 | Modal renders the checkbox group and Update button only when updated rows exist (Close otherwise); apply observer intersects picks with valid updated keys; testServer test with a missing-only project and a bogus `":"` pick. |
| code-integration-5, spec-coverage-4, ux-i18n-06 | `test-json-project-loading.R` case: JSON in both `simplifyVector` modes with and without `na = "null"`, plus RDS; testServer save → RDS → reload → re-save test. |
| spec-coverage-8 | testServer picker test with the real `isa_data_entry_server` re-bound from `.GlobalEnv`: add panel, pick F_01, save, assert snapshot + `Registry_Id`/`Registry_Version` in module and `project_data`. |
| code-integration-6, spec-coverage-2, ux-i18n-02 | Provenance in the picker (label suffix, stub marker) and `indicator_provenance_ui()` badge beside the picker (`register_indicator_picker_observer` now takes `output` and `i18n`); new keys `modules.wp5_mechanisms.provenance.{toolbox_extension,provisional}` in `wp5_mechanisms.json` (reusing the existing namespace and `wp5_derived` key) with sentinels in `ui_components.R`; `stub_marker` key; tests for labels, badge and key placement. |
| tests-executability-5, code-integration-7, ux-i18n-07 | `merge_saved` WS-4 path gated on `prefix %in% names(ISA_PREFIX_ELEMENT_KEY)` (ruling 3 corrected: seven call sites); testServer test that Responses gain no indicator columns; `project_has_registry_snapshot()` ignores Responses. |
| tests-executability-6, code-integration-8 | Project-switch test now uses the same stale element ID in p1 and p2 and expects `notified` 1 → 2, which fails without the reset line; Step 5 tells the executor to prove it. |
| spec-coverage-5 | `indicator_drift()` returns element vs registry values; the modal renders a per-element diff table; test asserts the diff columns. |
| spec-coverage-6 | `sync_to_project_data()` calls `stamp_min_app_version(pd, WP5_INDICATOR_MIN_APP_VERSION)` when a snapshot exists; tests for stamped and unstamped saves; Global Constraints note the VERSION consequence. |
| spec-coverage-13, ux-i18n-03 | Sticky toast (`duration = NULL`, id `ns("indicator_drift")`, removed after apply or project change); persistent `output$indicator_drift_bar` link with a distinct input id from the toast action; dismiss test (data unchanged, link kept, same-project write silent, new session re-notifies). |
| ux-i18n-05 | `indicator_drift()` returns nothing when the registry is not loaded (test); notification counts updated and missing separately (`drift_found`, new `drift_found_missing`). |
| spec-coverage-3 | Task 2 Step 6 extends `audit_wp5_mechanisms.py` (`registry_codes()`, `success_metric_registry_fails()`, `audit(..., registry=None)`) with two pytest cases; run via `micromamba run -n shiny python -I`. |
| code-integration-9, tests-executability-10 | Task 2 Files no longer list `tests/run_json_loading_tests.R`; Task 3 Files list `modules/auto_save_module.R` and `tests/testthat/test-json-project-loading.R`; Task 3 gives the exact runner lines. |
| tests-executability-8 | "Run to see it fail" expectations restated: `lexical error` for `fromJSON` on a missing file, `could not find function` where `source_for_test()` skips a missing file; Task 3 notes which tests pass immediately as regression guards. |
| ux-i18n-09 | Stale "Task 7" reference replaced ("Task 6"); `search_indicators()` matches codes case-insensitively, with a test. |

**Refuted findings, not applied:** `tests-executability-7` (no id mismatch; picker test coverage is nonetheless added for spec-coverage-8), `spec-coverage-12` (Responses columns harmless — superseded by the user's decision to gate Responses out anyway, so the gate is applied under tests-executability-5/code-integration-7/ux-i18n-07), `ux-i18n-08` (speculative `sprintf` failure; the existing `tryCatch` pattern is used regardless).

**Found while revising (not in the review):** F_03's scenario directions are in "Table 4 Scenario-based assumptions" L12219–12264 (two direction columns), not the criteria table L12303–12518 the rev 1 checklist cited; fiche `source_ref.lines` now start at each fiche heading (C_01 L10262, F_02 L11587, F_03 L11889, T_01 L12850, T_03 L13148); Table 6 repeats two indicator names, so Annex 1 codes get an element suffix on collision; the 1.22.2 dev build will show the downgrade warning for stamped projects until `VERSION` is bumped.
