# WP5 WS-8: Scenario × worldview reference library (D5.1) — design

**Date:** 2026-10-16
**Status:** design approved in brainstorming (sections 1-4, sections 1 and 4 amended after an in-loop review against the source files); written spec reviewed in-loop twice (2026-10-16); awaiting user approval
**Master spec:** `2026-10-11-wp5-practical-integration-specs.md` §WS-8 (and §WS-3 for `pestle_tag`)
**Source audit:** `docs/wp5-source-audit/2026-10-11/B_D5.1_scenarios.md`
**Sources** (under `WP5/Task 5.1 Application of Scenarios/`):
- `Deliverable report T5.1/Marine SABRES D5.1 scenarios report_v2 final.docx` (D5.1; Table 5 = per-cell transformation result)
- `Deliverable report T5.1/SSP-RCP regionalisation table.docx` (table 2 = global, expanded and merged EU narratives)
- `Scenarios vs worldviews paper/results breakdown.xlsx` (Sheet1 = 72-cell grid; Sheet2 = analyst rationale for every cell)
- `Deliverable report T5.1/WORLDVIEWS SCENARIOS FOR deliverable 5_1.xlsx` (worldview descriptions)
- `Scenarios vs worldviews paper/D5.1 Journal draft.docx` (strategies for non-aligned worldviews)

## 1. Purpose and scope

D5.1 is a qualitative congruence analysis: four SSP-RCP scenarios regionalised to Europe, described per PESTLE element and sector slice, crossed with three cultural-theory worldviews. Its output is where transformation is needed, by worldview × scenario × PESTLE element. It has no driver trends and is identical for all three DAs.

WS-8 makes this available inside the toolbox:

1. Two curated reference datasets, built reproducibly from the source files.
2. A "WP5 scenarios (D5.1)" tab in the Scenario Builder page: scenario cards, a worldview × scenario heat map, a PESTLE drill-down, the strategies for non-aligned worldviews, and source notes.
3. The `pestle_tag` attribute on Responses/Measures (specified in WS-3, never built), and a link from the selected heat-map cell to the project's responses that address the elements needing transformation.

Out of scope (master spec, partner question Q5): applying a scenario to the CLD (needs a WP5-endorsed narrative → DAPSIWRM mapping), and a worldview self-assessment (needs the WP5 questionnaire).

## 2. Decisions taken in brainstorming

1. **Narratives stay English source text.** The long scenario narratives are shown as quoted English source with a "source text (English)" badge; every label, heading, PESTLE name, state name, note and strategy text is translated in the 9 app languages.
2. **Build `pestle_tag` now**, as a manual multi-select (no inference from the EBM code).
3. **Reproducible build script** rather than hand-curated JSON: `scripts/build_wp5_scenarios.py` reads the source files and writes the two JSON files with cell-level provenance; the JSON is committed.
4. **Per-cell result = D5.1 Table 5** (in-loop review 2026-10-16). The spreadsheet's six decision rules do not map one-to-one to D5.1's four outcome classes, and its "transformation needed" tick mixes area-level and Europe-wide cases. D5.1's own per-cell answer is Table 5, which shades every cell as area-level transformation (blue `0070C0`), Europe-wide transformation (dark grey `808080`) or not needed (light grey `D9D9D9`). The dataset stores that three-state result as the primary field.

## 3. Data

### 3.1 `data/wp5_scenarios_ssp.json`

```
{ "version": "1.0", "source": "D5.1 (2024-02-26), SSP-RCP regionalisation table", "built_by": "scripts/build_wp5_scenarios.py",
  "pestle": ["political","economic","social","technological","legal","environmental"],
  "pestle_questions": { "political": "<English guiding question>", ... },
  "slices": ["general","hrmc","sh","lh"],
  "slice_da_focus": { "hrmc": "tuscany", "sh": "arctic", "lh": "macaronesia" },
  "scenarios": [
    { "id": "ssp1_26", "ssp": "SSP1", "rcp": "2.6", "name": "Sustainability: taking the green road",
      "warming_cap": "<=2", "ebm_conducive": "yes",
      "global_summary": "<English>", "expanded_narrative": "<English>",
      "driver_mapping": null,
      "cells": { "political": { "general": CELL, "hrmc": CELL, "sh": CELL, "lh": CELL }, ... } }, ... ] }
CELL = { "text": "<English>" | null, "gap_note": null | "<code>", "source_ref": "table2:r<row>:c<col>" }
```

- Scenario ids: `ssp1_26`, `ssp2_45`, `ssp3_70`, `ssp5_85`. `warming_cap`: `<=2`, `<=3`, `<=4`, `>4` (°C). `ebm_conducive`: `yes`, `somewhat`, `no`, `no` (D5.1 Box 1).
- Slices: `general` (text before the first sector heading in a cell; CERES generic), `hrmc` (habitat restoration and marine conservation), `sh` (seafood harvesting), `lh` (tourism and leisure). A cell's text is split on the uppercase sector headings.
- Sector headings in the source are exactly `HABITAT RESTORATION AND MARINE CONSERVATION`, `SEAFOOD HARVESTING`, `TOURISM AND LEISURE`; text before the first heading is the `general` slice (present in 12 of the 24 cells).
- `gap_note` codes: `ssp_not_in_futuremares` (text "SSP not featured in Future MARES, no specific lines in CERES."), `no_afmec_lines` ("No specific lines in AFMEC", with or without a final full stop), `no_source_text` (slice heading absent, or empty source cell). A slice with a gap note has `text: null`.
- Scenario name, global summary and expanded narrative come from table 2 rows 0-2; warming caps and EBM conduciveness are fixed values in the script from D5.1 Box 1 (not parsed), each with a comment citing Box 1.
- `driver_mapping: null` is an explicit curation placeholder (deferred, Q5).

### 3.2 `data/wp5_worldview_matrix.json`

```
{ "version": "1.0", "source": "D5.1 Table 5 + results breakdown.xlsx", "built_by": "scripts/build_wp5_scenarios.py",
  "worldviews": [ { "id": "egalitarian"|"individualist"|"hierarchy", "keywords": "<English>", "problem": "...",
                    "solution": "...", "summary": "...",
                    "pestle": { "political": "<English>"|null, ..., "legal": "<ideas of justice>", "environmental": "..." },
                    "source_ref": "WV description!<column>" } ],
  "cells": [ { "worldview": "...", "ssp": "ssp1_26", "pestle": "political",
               "transformation": "area"|"europe"|"none",
               "match": true|false, "wv_more_conducive": true|false|null,
               "rationale": "<English analyst justification>",
               "source_ref": { "table5": "r<row>:c<col>", "breakdown": "Sheet1!<cell>", "rationale": "Sheet2!<cell>" } } ],
  "source_notes": [ { "id": "...", "text_key": "<i18n key>" } ],
  "strategies": [ "behavioural", "accepted_instruments", "limits_of_acceptable_change" ] }
```

- 72 cells (3 × 4 × 6). `transformation` from Table 5 cell shading. `match` from Sheet1 row "WV & SSP match"; `wv_more_conducive` from row "WV more conducive to EBM" (`-` → `null`).
- `rationale` from Sheet2 (present for all 72 cells).
- Worldviews come from `WORLDVIEWS SCENARIOS FOR deliverable 5_1.xlsx`, sheet "WV description": rows Key words, Problem definition, Solution, Summary, then one row per PESTLE element (the Legal row is the worldview's justice principle). Rows are read by position, not label (the sheet spells "Tecnological"). Hierarchy × economic is blank in the source → `null`, shown with the `no_source_text` gap note. Worldview names are mapped from the source spellings (INDIVIDUALIST / HIERARCHY / EGALITARIAN in the sheet; "Hierarchical" in Table 5) to the three ids.
- `source_notes` (each rendered from a translated key):
  - `summary_hierarchy_ssp` — D5.1's Summary places Hierarchy's four PESTLE elements under SSP1; Table 5, the spreadsheet and the journal draft put them under SSP2.
  - `hierarchy_ssp2_misprint` — D5.1 prints the Hierarchy × SSP2 match pattern as `__LE`.
  - `conducive_row_label` — the spreadsheet row "Worldview conducive to EBM?" holds the scenario's conduciveness (SSP2 "somewhat" coded Y); not used.
  - `ssp3_block_europe` — Table 5 shades the whole SSP3 block Europe-wide, including Hierarchy × SSP3 × political, which the spreadsheet marks as not needing transformation; and the spreadsheet's "?" for Hierarchy × SSP3 × environmental.
  - `generic_europe` — results are generic for Europe and identical for all DAs; an analyst panel, not a stakeholder survey.
- `strategies`: ids of the journal draft's three strategies; their text is our translated wording (§4), with a provenance badge.

### 3.3 Build script and checks

`scripts/build_wp5_scenarios.py` (python-docx, openpyxl; run with `micromamba run -n shiny python`):
- reads the sources above (paths relative to the app dir), writes both JSON files with sorted keys and stable ordering (byte-identical on re-run);
- locates Table 5 by its layout (worldview rows × 24 PESTLE columns with cell shading); D5.1 contains two copies (main text and appendix) — the build requires both to agree and uses the first;
- decodes the spreadsheet's Wingdings glyphs (`0xFC` = needed, `0xFD` = not needed) only for the consistency check;
- **consistency check** (fails the build): for each cell, Table 5 says area or Europe-wide exactly when the spreadsheet ticks "transformation needed", except the cells listed in `ssp3_block_europe`; the check prints and exits non-zero on any other difference;
- counts: 4 scenarios, 6 PESTLE, 72 matrix cells, every null narrative has a gap note.

## 4. The reference tab

### 4.1 Placement

`scenario_builder_ui()` (`modules/scenario_builder_module.R`) wraps its body in a `tabsetPanel`:
- **"My scenarios"**: the existing builder, unchanged, still behind the CLD check.
- **"WP5 scenarios (D5.1)"**: the new sub-module, **not** behind the CLD check (readable in an empty project).

New sub-module `modules/wp5_scenario_reference_module.R`: `wp5_scenario_reference_ui(id, i18n)`, `wp5_scenario_reference_server(id, project_data_reactive, i18n, event_bus = NULL)`, mounted from `scenario_builder_server()`. Loaders in `functions/wp5_scenarios.R`: `load_wp5_scenarios()`, `load_wp5_worldview_matrix()` (read once per process, cached; NULL + `debug_log` on missing or invalid JSON).

### 4.2 Layout (top to bottom)

1. **Scope note** (translated): generic Europe-scale results, identical for all areas; from an analyst panel (D5.1, 2024), not a stakeholder survey.
2. **Scenario cards** (4): name, warming cap, EBM-conduciveness badge, global summary (English source badge).
3. **Heat map** (plain HTML table, translated headers): worldview rows × scenario columns, 12 cells. Each cell shows the number of PESTLE elements needing area-level transformation (colour scale on that count) and, as a secondary mark, the number needing Europe-wide transformation; plus the match pattern as letters (e.g. `PE_TLE`). Clicking a cell selects it.
4. **Drill-down** for the selected cell: six PESTLE rows, each with match / mismatch, the transformation state (translated: "area level", "Europe-wide (outside the project's reach)", "not needed"), the analyst rationale (English source), and side by side the worldview's view of that element and the scenario narrative for that element (slice tabs: general, conservation, seafood harvesting, tourism, each marked with its area focus), or the translated gap note.
   Cell selection: each heat-map cell has an `onclick` that sends `Shiny.setInputValue(ns("cell"), "<worldview>|<ssp>", {priority: "event"})` (the pattern the Scenario Builder already uses for scenario cards); the first cell with any area-level element is selected by default.
5. **Strategies for non-aligned worldviews**: three translated paragraphs (our wording of the journal draft), provenance badge.
6. **Source notes**: collapsible, rendering `source_notes`.

### 4.3 Your project's responses

Below the drill-down, when a project is loaded: the Response register measures whose `PestleTag` contains at least one element with `transformation = "area"` in the selected cell. Columns: name, tags (matching ones highlighted), kind, EBM code. No match: a translated note plus a hint to tag responses in the Response register. Cells with only Europe-wide or no transformation show a translated explanation instead of a list.

## 5. `pestle_tag` on Responses/Measures

- **Storage:** new register column `PestleTag` in `RM_REGISTER_COLUMNS` (`constants.R`), value = `;`-joined codes from new `PESTLE_CODES <- c("political","economic","social","technological","legal","environmental")`; empty = not tagged. `normalize_response_measures()` adds it to legacy registers (empty) and drops unknown codes (with `debug_log`).
- **Entry:** `modules/response_module.R`, WS-3 governance section: `selectizeInput(multiple = TRUE)` "PESTLE elements addressed", choices = translated PESTLE names, with a hint that it links the response to the WP5 scenario results. Saved and restored with the other governance fields.
- **Display:** `rm_translate_for_display()` gains a `PestleTag` case that splits on `;`, maps each code to its translated short label and joins with ", "; the register table shows that.

## 6. Components

| File | Kind | Contents |
|---|---|---|
| `scripts/build_wp5_scenarios.py` | new | build + consistency check |
| `data/wp5_scenarios_ssp.json`, `data/wp5_worldview_matrix.json` | new (generated, committed) | §3 |
| `functions/wp5_scenarios.R` | new | loaders, `wp5_matched_responses(register, cells)` (pure), heat-map summary helper |
| `modules/wp5_scenario_reference_module.R` | new | §4 |
| `modules/scenario_builder_module.R` | changed | tabsetPanel; mounts the sub-module |
| `modules/response_module.R`, `functions/response_measures_schema.R`, `constants.R` | changed | §5 |
| `global.R` / `app.R` | changed | `source("functions/wp5_scenarios.R")` in `global.R` (so `test-functions-sourced-in-app.R` passes); `modules/wp5_scenario_reference_module.R` added to `OPTIONAL_MODULES` in `app.R` next to the Scenario Builder. `scenario_builder_server()` mounts the sub-module only if `wp5_scenario_reference_server` exists, so a failed optional load leaves the builder working |
| `translations/modules/wp5_scenarios.json` (new), `translations/modules/response_governance.json` | new/changed | all new keys, 9 languages |
| `VERSION`, `VERSION_INFO.json`, `DESCRIPTION`, `CHANGELOG.md` | changed | release 1.29.0 |

## 7. Errors and tests

**Errors:**
- Missing/invalid reference JSON → translated "reference data unavailable" notice in the tab; the Scenario Builder keeps working.
- No project / empty register → the reference content shows; only §4.3 is replaced by a hint.
- Unknown `PestleTag` codes → dropped on normalise, logged.

**Tests:**
- Build script (pytest 8.4.2 in the micromamba `shiny` env, new `scripts/tests/test_build_wp5_scenarios.py`; scripts/ has no test folder yet): consistency check passes on the real sources; Wingdings decoding; 72 cells; null narrative ⇒ gap note; two runs give byte-identical JSON; both Table 5 copies agree; 12 cells carry a `general` slice; both spellings of the AFMEC gap phrase map to `no_afmec_lines`; Hierarchy × economic worldview text is null with a gap note.
- `tests/testthat/test-wp5-scenarios.R`: JSON integrity (4 scenarios, 6 PESTLE, 4 slices, 3 worldviews, 72 cells, states in {area, europe, none}); spot checks from D5.1 (not computed by the build): area-level cells are exactly Individualist × SSP1 (all six), Individualist × SSP2 (political, economic, social, environmental), Hierarchy × SSP1 (social), Hierarchy × SSP2 (political, economic, social, technological); Egalitarian has none; Individualist × SSP5 matches on all six elements; every cell has a rationale.
- `wp5_matched_responses()`: only `area` elements match; legacy registers without `PestleTag`; multiple tags.
- `tests/testthat/test-response-measures-schema.R` (extended): `PestleTag` added to legacy data, unknown codes dropped, save/load round trip; form round trip via `testServer()`.
- `tests/testthat/test-wp5-scenario-reference-module.R`: UI contract and namespacing; tab renders without a project/CLD; selecting a cell fills the drill-down; a null narrative shows its gap note; the responses list follows the selected cell.
- Existing Scenario Builder tests keep passing.
- i18n: `scripts/_i18n_audit.py` missing = 0, hardcoded = 0 (narrative/rationale/worldview description text is data).

**Release:** 1.29.0 (minor). Implementation subagent-driven (per-task reviews, final whole-branch review).

## 8. Open items

- Q5: WP5 questionnaire (self-assessment) and an endorsed narrative → DAPSIWRM mapping (apply-scenario-to-CLD).
- Confirm with D5.1 authors the summary error and the SSP3 block shading versus the spreadsheet (`source_notes`).
- Tourism narratives are UK-derived (AFMEC) and lack technological/legal lines.
