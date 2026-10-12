# WP5 WS-6a: Impact-Assessment Data and Model Layer — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship everything below the UI of the WS-6 impact-assessment module: the D5.2 reference datasets (Macaronesia Table 21, Arctic Tables 2–8), a pure R data model for the criterion × scenario assessment, its validation rules, its linking helpers, and loss-free save/load under `data$analysis$impact_assessment`.

**Architecture:** A hand-authored `data/wp5_impact_reference.json` is checked by tests against the committed D5.2 line extract (the WS-4/WS-5 pattern). It is read by a cached loader, `functions/impact_reference.R`. A Shiny-free model, `functions/impact_assessment_model.R`, holds constructors, scenario and cell operations, problem codes, reference starters, linking helpers, storage and the JSON normaliser. `normalize_json_project_data()` calls the normaliser, so every load path (`.json`, `.rds`, local storage, language switch) yields the same canonical block.

**Tech Stack:** R 4.4.1, jsonlite, testthat 3.3.2; Python (micromamba `shiny`) only to regenerate the extract.

**Spec:** `docs/superpowers/specs/2026-10-11-wp5-practical-integration-specs.md` §WS-6 (lines 327–371), plus roadmap §8 (`docs/superpowers/specs/2026-05-06-wp5-integration-roadmap-design.md` L420–530) and audit `docs/wp5-source-audit/2026-10-11/A_D5.2_audit.md` §2–3.

## Scope of WS-6a (decided here; nothing else defines the split)

| Part | Contents | Status |
|---|---|---|
| **WS-6a (this plan)** | Reference data + loader; the full stored schema for all 7 steps (characterisation, scenarios + baseline, scope incl. element/indicator selection and displacement, cells, uncertainty notes, trade-offs, recommendations); problems; reference starters + copy; mechanism and indicator linking helpers; storage, normaliser, round trip | this plan |
| WS-6b | Module UI for all 7 steps, matrix + per-cell modal, criterion × scenario heat map, Arctic revenue tables view, Tuscan empty state, the optional "displaced pressure" P element (writes `scope$displacement$displaced_pressure_id`), ~120 i18n keys, `set_impact_assessment()` on first write. **Step 5 decision belongs here:** 6a stores free-text uncertainty notes only; re-scoring under alternative assumptions (roadmap §8.4 step 5) either extends the schema in 6b (bump `IMPACT_SCHEMA_VERSION`, extend `.impact_fill_*` and the normaliser) or is descoped as roadmap §8.10 allows | next plan |
| WS-6c | Step 6 deterministic narrative (9 languages) written to `trade_offs$auto_draft`, Word/Excel report with provenance appendix | after 6b |

**Schema rule for 6b/6c:** the normaliser keeps only the fields defined here (it is a whitelist, so malformed or foreign data can't get in). Any new stored field must be added to the matching `.impact_fill_*` helper and to `normalize_impact_assessment()` in the same commit, or it disappears on the next load.

WS-6a changes nothing a user can see. Release it together with WS-6b as **1.25.0**.

## Decisions recorded for the user (read before approving)

1. **Arctic revenue values are partner-gated (question 2).** The spec (§WS-6 change 3) says to ship the published tables. This plan follows the WS-2 precedent: the values are stored verbatim with `provenance: "wp5_source"`, `partner_question: 2` and the audit §3.1 inconsistency note. They are never recomputed from the stated assumptions. If the partners answer question 2 differently, only the JSON changes.
2. **Table 21 confidence is per scenario (one column), not per cell.** Copying a reference cell copies that scenario's confidence into the cell only when D5.2 gives a single level (S1 High, S3 Medium). For ranges (S2 Medium–High, S4 Low–Medium) the copied cell's confidence stays empty, so the user must choose.
3. **No genuine 1.21.1 fixture project exists in the repo** (the spec's cross-cutting section asks for round trips against one). This plan adds a minimal hand-authored project stamped `version` 1.21.1 with no WP5 blocks. That is a deviation: it tests "an older project without the block loads unchanged and can gain one", not the full 1.21.1 schema.
4. **No new WS-1 vocabulary codes.** `test-wp5-vocabulary.R` requires 9-language labels for every code in `.wp5_vocab_table()`. New code lists (scenario dimensions, displacement answers, problem codes) live in `constants.R` and in the model, outside the vocab table; WS-6b gives them i18n keys. WS-6a has no user-facing strings.
5. **Mechanism linking annotates and sorts; it does not hide.** D5.2 Table 9 often names only the scenario where a mechanism is strongest ("Most effective under Full Agreement"). Treating that as "not applicable elsewhere" would claim more than the source, so every DA mechanism is returned with its applicability code (`NA` = D5.2 does not say for this scenario) and its published `applicability_text`. Recommended mechanisms come first and "fragmented" ones last.
6. **Provenance (spec P1/P5).** Reference cell blocks carry `provenance: "wp5_source"` and a `source_ref`. A copied cell records `provenance` and `ref_version` (the reference file's `schema_version`), so a later correction (e.g. after partner question 2) can be detected in saved projects.
7. **`create_empty_project()` is not changed.** The block is optional (spec cross-cutting "Schema and migration"); it appears only when `set_impact_assessment()` writes it.

## Global Constraints

- R >= 4.4.1; no new packages (jsonlite, testthat already present).
- Storage location: `data$analysis$impact_assessment` (spec §WS-6 change 7, WS-0 convention).
- Writes go through `stamp_min_app_version(project, WP5_IMPACT_MIN_APP_VERSION)`, with `WP5_IMPACT_MIN_APP_VERSION <- "1.25.0"`. 1.24.0 is released without this block.
- Matrix cell schema, ordinal (spec change 1): `direction, magnitude, timing, confidence, evidence[], uncertainty_driver (required when confidence = low), rationale, subdimension_notes {…} (EQ/PI only), indicator_codes[] with role, mechanism_ids[]`. The 0–10 magnitude and 0–4 `governance_ambition` are not implemented. Codes come from `WP5_RUBRIC` and `WP5_CRITERION_SUBDIMENSIONS` (constants.R).
- Scenarios carry `code`, `name`, `description`, optional `ambition_rank`, and the six optional description dimensions (spec change 2). `IMPACT_MAX_SCENARIOS <- 5L` (roadmap §8.3).
- Criterion codes EE/EC/EQ/PI/FF; accept the aliases PO and FI through `wp5_criterion_code()`.
- Reference figures are stored as published, never recomputed (spec: "Arctic revenue values equal the published table values").
- Every new `functions/*.R` file is `source()`d in `global.R` (`test-functions-sourced-in-app.R` enforces it).
- Use `debug_log()` rather than `cat()`. Return errors and problems as codes, not English text (CLAUDE.md i18n rules; WS-6b translates them).
- Shell: use `git -C <path>`, never `cd <path> && git`.
- Tests: run single files with `"C:/Program Files/R/R-4.4.1/bin/Rscript.exe" -e "testthat::test_file('tests/testthat/<file>.R')"` from `C:/Users/arturas.baziukas/wt-ws6/MarineSABRES_SES_Shiny`. A single full-suite run is killed for low memory, so run the full suite in alphabetical chunks (Task 6).

## Review Focus

1. **A project whose block has cells for a scenario that no longer exists** (hand-edited, or saved mid-edit) should load with the orphan cells dropped, not crash. Pinned in Task 5 (`orphan cells are dropped`).
2. **Cells keyed by D5.2 aliases `PO`/`FI`** (from fiche-derived data) should load as `PI`/`FF`. Pinned in Task 5.
3. **A malformed block or field** (a string, a number, an unnamed list; or a valid block whose `scope`, `displacement`, a section or a cell field has the wrong type) must not stop the project loading. A bad block is dropped; a bad field falls back to its empty value and the rest of the block survives. The load hook also wraps the normaliser in `tryCatch`. Pinned in Task 5.
4. **The reference file missing on the server** must leave the app working: status `"unavailable"` (one warning, no re-read of the default path on every call), and a starter with the DA set and no scenarios. Pinned in Task 2 and Task 4.
5. **Copying a reference cell over a cell the user already edited** must not silently overwrite it (`cell_not_empty` unless `overwrite = TRUE`). A criterion with no reference cell (e.g. Arctic EE) must return `no_reference_cell`. Pinned in Task 4.
6. **Linking for any scenario or criterion**: indicator suggestions must not error for EC/EQ, where some registry citations have `role: null`; mechanism options must not come back empty for a user-defined scenario. Pinned in Task 4.

---

## File map

| Path | Action | Responsibility |
|---|---|---|
| `scripts/build_wp5_indicator_sources.py` | Modify `RANGES` | Widen the committed D5.2 extract to the Arctic Tables 2–8 and Table 21 |
| `scripts/wp5_kb_sources/d5.2_v5_indicator_sources.md` | Regenerate | Extract the tests read |
| `data/wp5_impact_reference.json` | Create | Read-only D5.2 reference data |
| `functions/impact_reference.R` | Create | Cached loader + getters |
| `functions/impact_assessment_model.R` | Create | Model, problems, starters, linking, storage, normaliser |
| `constants.R` | Modify (after the WS-5 block, ~L890) | `IMPACT_*` constants, `WP5_IMPACT_MIN_APP_VERSION` |
| `global.R` | Modify (after `source("functions/indicator_snapshot.R")`, ~L712) | Source the two new files |
| `functions/data_structure.R` | Modify (`normalize_json_project_data`, after `migrate_legacy_scenarios(data)`, ~L961) | Call the normaliser on every JSON/RDS load |
| `tests/testthat/test-impact-reference-data.R` | Create | Reference JSON vs extract |
| `tests/testthat/test-impact-reference.R` | Create | Loader/getters |
| `tests/testthat/test-impact-assessment-model.R` | Create | Model, problems, starters, linking |
| `tests/testthat/test-impact-assessment-storage.R` | Create | Stamp + three load paths + fixture |
| `tests/testthat/test-json-project-loading.R` | Modify (append) | WS-6 round trip block (spec P7) |
| `tests/testthat/fixtures/project_1_21_1_minimal.json` | Create | Older-project fixture (decision 3) |
| `CHANGELOG.md` | Modify `[Unreleased]` | Entry |

---

### Task 1: Widen the D5.2 extract and author the reference JSON

**Files:**
- Modify: `scripts/build_wp5_indicator_sources.py` (`RANGES`, lines 22–32)
- Regenerate: `scripts/wp5_kb_sources/d5.2_v5_indicator_sources.md`
- Create: `data/wp5_impact_reference.json`
- Test: `tests/testthat/test-impact-reference-data.R`

**Interfaces:**
- Consumes: the extract format `L<n>: <text>` (one PDF layout line per extract line); `get_scenarios_for_da()` (functions/wp5_kb_loader.R:155); `WP5_RUBRIC`.
- Produces: `data/wp5_impact_reference.json` with this shape, which Task 2 reads:
  - `demonstration_areas.<da>.status`: `"available"` | `"valuation_only"`
  - `.baseline_code`: string
  - `.scenarios[]`: `{code, short_label, ambition_rank, confidence_text?, confidence_codes?, verify_phrases?}`
  - `.cells[]`: `{criterion, scenario, text, rating_text?, verify_phrases[], rating_verify?}`
  - `.cell_source`: `{table, source_lines: [from, to]}`
  - `.revenue` (Arctic only)

- [ ] **Step 1: Widen the extract ranges**

In `scripts/build_wp5_indicator_sources.py`, replace the line

```python
    (1863, 1896, "Arctic: retail prices and landings table (Faroe Islands, 2024)"),
```

with

```python
    (1863, 2040, "Arctic: retail prices, landings and revenue by scenario (Tables 2-7)"),
    (2166, 2180, "Arctic: Table 8 political feasibility by scenario"),
    (4798, 4851, "Macaronesia: Table 21 cross-scenario assessment"),
```

- [ ] **Step 2: Regenerate the extract and check that nothing else moved**

The source PDF is untracked and absent from worktrees, so point at the main checkout:

```bash
micromamba run -n shiny python -I scripts/build_wp5_indicator_sources.py --wp5-dir "C:/Users/arturas.baziukas/OneDrive - ku.lt/HORIZON_EUROPE/Marine-SABRES/SESToolbox/MarineSABRES_SES_Shiny/WP5"
git -C "C:/Users/arturas.baziukas/wt-ws6" diff --stat
git -C "C:/Users/arturas.baziukas/wt-ws6" diff -U0 MarineSABRES_SES_Shiny/scripts/wp5_kb_sources/d5.2_v5_indicator_sources.md | grep '^-L' | head
```

Expected: `ok ... sha256 ab42fffd...`. The last command prints nothing: no existing `L` line is removed or changed, only added. The `## L1863-L1896` heading changes; that is fine, because tests read only `L` lines.

Then confirm that the existing consumers still pass:

```bash
"C:/Program Files/R/R-4.4.1/bin/Rscript.exe" -e "testthat::test_file('tests/testthat/test-indicator-registry.R')"
"C:/Program Files/R/R-4.4.1/bin/Rscript.exe" -e "testthat::test_file('tests/testthat/test-valuation-calculations.R')"
```

Expected: no failures.

- [ ] **Step 3: Write the failing verification test**

Create `tests/testthat/test-impact-reference-data.R`:

```r
# tests/testthat/test-impact-reference-data.R
# WS-6a: data/wp5_impact_reference.json is checked against the committed
# D5.2 v5 layout extract. Table 21 columns are interleaved in the layout, so
# each value carries verify_phrases copied from a single extract line.
library(testthat)

ref <- jsonlite::fromJSON(file.path(PROJECT_ROOT, "data", "wp5_impact_reference.json"),
                          simplifyVector = FALSE)
ext_path <- file.path(PROJECT_ROOT, "scripts", "wp5_kb_sources", "d5.2_v5_indicator_sources.md")
ext_lines <- function(from, to) {
  l <- readLines(ext_path, encoding = "UTF-8", warn = FALSE)
  m <- regmatches(l, regexec("^L([0-9]+): ?(.*)$", l))
  keep <- lengths(m) == 3
  txt <- setNames(vapply(m[keep], `[`, character(1), 3), vapply(m[keep], `[`, character(1), 2))
  rng <- as.character(seq(from, to))
  expect_true(all(rng %in% names(txt)), info = paste("extract lacks", from, "-", to))
  unname(txt[intersect(rng, names(txt))])
}
on_one_line <- function(phrase, lines) any(grepl(phrase, lines, fixed = TRUE))
da <- function(x) ref$demonstration_areas[[x]]
codes_of <- function(lst) vapply(lst, function(s) s$code, character(1))
load_wp5_mechanisms_kb(file.path(PROJECT_ROOT, "data", "ses_knowledge_db_wp5_mechanisms.json"),
                       force_reload = TRUE)

test_that("Macaronesia Table 21: 5 criteria x 4 scenarios, each anchored on one extract line", {
  mac <- da("macaronesia")
  lines <- ext_lines(mac$cell_source$source_lines[[1]], mac$cell_source$source_lines[[2]])
  keys <- vapply(mac$cells, function(c) paste(c$criterion, c$scenario), character(1))
  expect_setequal(keys, as.vector(outer(c("EE", "EC", "EQ", "PI", "FF"), paste0("S", 1:4), paste)))
  expect_identical(mac$provenance, "wp5_source")
  expect_identical(mac$source_ref$table, "Table 21")
  for (c in mac$cells) {
    # one anchor from the cell's first layout line, one from its last (catches dropped clauses)
    expect_gte(length(c$verify_phrases), 2)
    for (p in c$verify_phrases) {
      expect_true(on_one_line(p, lines), info = paste(c$criterion, c$scenario, "not in extract:", p))
      expect_true(grepl(p, c$text, fixed = TRUE), info = paste(c$criterion, c$scenario, "not in text:", p))
    }
  }
})

test_that("Macaronesia scenario confidence matches Table 21 and uses rubric codes", {
  mac <- da("macaronesia")
  lines <- ext_lines(4798, 4851)
  expect_identical(codes_of(mac$scenarios), paste0("S", 1:4))
  expect_identical(vapply(mac$scenarios, function(s) as.integer(s$ambition_rank), integer(1)), 1:4)
  for (s in mac$scenarios) {
    expect_gte(length(s$verify_phrases), 2)
    for (p in s$verify_phrases) {
      expect_true(on_one_line(p, lines), info = p)
      expect_true(grepl(p, s$confidence_text, fixed = TRUE), info = p)
    }
    expect_true(all(unlist(s$confidence_codes) %in% WP5_RUBRIC$confidence))
  }
  conf <- setNames(lapply(mac$scenarios, function(s) unlist(s$confidence_codes)), codes_of(mac$scenarios))
  expect_identical(conf, list(S1 = "high", S2 = c("medium", "high"), S3 = "medium", S4 = c("low", "medium")))
})

test_that("Arctic Table 8: political feasibility per scenario, anchored on extract lines", {
  arc <- da("arctic")
  lines <- ext_lines(2166, 2180)
  expect_identical(arc$cell_source$table, "Table 8")
  expect_identical(arc$provenance, "wp5_source")
  expect_setequal(vapply(arc$cells, function(c) c$scenario, ""), c("no_agreement", "partial_agreement", "full_agreement"))
  for (c in arc$cells) {
    expect_identical(c$criterion, "PI")
    expect_gte(length(c$verify_phrases), 2)
    expect_true(on_one_line(c$rating_verify, lines), info = c$rating_verify)
    for (p in c$verify_phrases) {
      expect_true(on_one_line(p, lines), info = p)
      expect_true(grepl(p, paste(c$rating_text, c$text), fixed = TRUE), info = p)
    }
  }
  rating <- setNames(vapply(arc$cells, function(c) c$rating_text, ""), vapply(arc$cells, function(c) c$scenario, ""))
  expect_identical(rating[["full_agreement"]], "Low to moderate")
  expect_identical(rating[["partial_agreement"]], "Moderate")
  expect_identical(rating[["no_agreement"]], "High")
})

usd_millions_of <- function(display) {
  n <- as.numeric(gsub("[^0-9.]", "", display))
  if (grepl("billion", display, fixed = TRUE)) n * 1000 else n
}

test_that("Arctic revenue figures are the published table strings, never recomputed", {
  rev <- da("arctic")$revenue
  expect_identical(rev$provenance, "wp5_source")
  expect_identical(as.integer(rev$partner_question), 2L)
  expect_setequal(vapply(rev$countries, function(c) c$country, ""), c("faroe_islands", "greenland", "iceland"))
  for (cty in rev$countries) {
    bl <- ext_lines(cty$baseline_table$source_lines[[1]], cty$baseline_table$source_lines[[2]])
    sl <- ext_lines(cty$scenario_table$source_lines[[1]], cty$scenario_table$source_lines[[2]])
    expect_setequal(vapply(cty$species, function(s) s$species, ""), c("mackerel", "herring", "blue_whiting"))
    for (s in cty$species) {
      tag <- paste(cty$country, s$species)
      expect_true(on_one_line(s$landings_display, bl), info = tag)
      expect_true(on_one_line(s$price_display, bl), info = tag)
      expect_equal(s$landings_t, as.numeric(gsub(",", "", s$landings_display)), info = tag)
      expect_equal(s$price_usd_per_t, as.numeric(gsub("[$,]", "", s$price_display)), info = tag)
      expect_true(on_one_line(s$baseline$display, bl), info = tag)
      expect_equal(s$baseline$usd_millions, usd_millions_of(s$baseline$display), info = tag)
      for (sc in c("no_agreement", "partial_agreement", "full_agreement")) {
        v <- s[[sc]]
        expect_true(on_one_line(v$display, sl), info = paste(tag, sc, v$display))
        expect_equal(v$usd_millions, usd_millions_of(v$display), info = paste(tag, sc))
      }
      # Tables 3 and 5 put one species per line in column order Full | Partial | No.
      # Locate the line by the Full value (Greenland "Blue Whiting" wraps). Iceland's
      # Table 7 is garbled in the text layer, so it keeps the presence-only check.
      if (cty$country %in% c("faroe_islands", "greenland")) {
        row <- sl[grepl(s$full_agreement$display, sl, fixed = TRUE)]
        expect_length(row, 1)
        pos <- vapply(c(s$full_agreement$display, s$partial_agreement$display, s$no_agreement$display),
                      function(d) as.integer(regexpr(d, row[1], fixed = TRUE)), integer(1))
        expect_true(all(pos > 0) && !is.unsorted(pos, strictly = TRUE), info = paste(tag, "column order"))
      }
    }
  }
  gl <- Filter(function(c) c$country == "greenland", rev$countries)[[1]]
  mack <- Filter(function(s) s$species == "mackerel", gl$species)[[1]]
  # Audit A§3.1: the stated assumptions would give ~75.8; D5.2 publishes 97.1
  expect_equal(mack$full_agreement$usd_millions, 97.1)
})

test_that("scenario codes match the WS-2 KB and baselines are scenarios", {
  for (d in c("macaronesia", "arctic")) {
    expect_identical(codes_of(da(d)$scenarios), codes_of(get_scenarios_for_da(d)), info = d)
    expect_true(da(d)$baseline_code %in% codes_of(da(d)$scenarios), info = d)
  }
  expect_identical(da("macaronesia")$baseline_code, "S1")
  expect_identical(da("arctic")$baseline_code, "partial_agreement")
  b <- da("arctic")$baseline_verify
  expect_true(on_one_line(b$phrase, ext_lines(b$source_lines[[1]], b$source_lines[[2]])))
})

test_that("Tuscan has no scenarios: valuation only", {
  tus <- da("tuscan")
  expect_identical(tus$status, "valuation_only")
  expect_length(tus$scenarios, 0)
  expect_length(tus$cells, 0)
})
```

- [ ] **Step 4: Run it and confirm that it fails**

Run: `"C:/Program Files/R/R-4.4.1/bin/Rscript.exe" -e "testthat::test_file('tests/testthat/test-impact-reference-data.R')"`
Expected: error, because `data/wp5_impact_reference.json` does not exist.

- [ ] **Step 5: Author `data/wp5_impact_reference.json`**

Transcriptions remove the line-end hyphenation of the PDF layout. Keep "–" (en dash) and "&" exactly as written. Write the file as UTF-8.

```json
{
  "schema_version": "1.0.0",
  "last_updated": "2026-10-12",
  "description": "WP5 impact-assessment reference data (D5.2 v5): Macaronesia Table 21 cross-scenario assessment; Arctic Tables 2-7 (revenue by scenario) and Table 8 (political feasibility). Read-only reference cells that users copy into an editable assessment. Tuscan has no scenarios in D5.2 (valuation chapter only).",
  "source_document": "MarineSABRES D5.2 Final v5 (23 Jun 2026)",
  "source_extract": "scripts/wp5_kb_sources/d5.2_v5_indicator_sources.md",
  "verification": "Cell text is a de-hyphenated transcription of one table column. Table 21 columns are interleaved in the pdftotext -layout extract, so each value carries verify_phrases copied from a single extract line inside its source_lines; tests match them against the extract and against the transcription. Figures carry their published display string, which tests find in the table's line range.",
  "demonstration_areas": {
    "macaronesia": {
      "status": "available",
      "baseline_code": "S1",
      "scenario_note": "S1-S4 are governance escalation pathways (D5.2 §5.4, L4533-4535); ambition_rank follows that order.",
      "scenarios": [
        {"code": "S1", "short_label": "S1 BAU", "ambition_rank": 1,
         "confidence_text": "High, based on observed current conditions and well-documented governance arrangements",
         "confidence_codes": ["high"], "verify_phrases": ["High, based on", "documented gov"]},
        {"code": "S2", "short_label": "S2 Light coordination", "ambition_rank": 2,
         "confidence_text": "Medium–High, effects are incremental and reasonably predictable, but uptake can vary",
         "confidence_codes": ["medium", "high"], "verify_phrases": ["Medium–High,", "take can vary"]},
        {"code": "S3", "short_label": "S3 Coordinated EEZ corridor", "ambition_rank": 3,
         "confidence_text": "Medium, positive impacts are plausible, but depend on governance design and compliance",
         "confidence_codes": ["medium"], "verify_phrases": ["Medium, positive", "and compliance"]},
        {"code": "S4", "short_label": "S4 Integrated EEZ + ABNJ corridor", "ambition_rank": 4,
         "confidence_text": "Low–Medium, outcomes depend heavily on political commitment, funding continuity & benefit-sharing mechanisms and sectoral responses",
         "confidence_codes": ["low", "medium"], "verify_phrases": ["Low–Medium,", "sectoral responses"]}
      ],
      "cell_source": {"table": "Table 21", "source_lines": [4798, 4851]},
      "provenance": "wp5_source",
      "source_ref": {"document": "MarineSABRES D5.2 Final v5 (23 Jun 2026)", "table": "Table 21", "section": "5.5"},
      "cells": [
        {"criterion": "EE", "scenario": "S1", "verify_phrases": ["No additional ecological", "managed in isolation"],
         "text": "No additional ecological impact beyond existing MPAs, migratory species remain exposed between MPAs, pressures from fisheries, shipping, and tourism continue to be managed in isolation"},
        {"criterion": "EC", "scenario": "S1", "verify_phrases": ["additional constraints", "continue/may arise"],
         "text": "High short-term efficiency as there are no additional constraints for companies, long-term inefficiencies continue/may arise from unmanaged ecological impacts"},
        {"criterion": "EQ", "scenario": "S1", "verify_phrases": ["Uneven outcomes persist", "transit shipping"],
         "text": "Uneven outcomes persist between regions and user groups; e.g. small-scale fisheries receive fewer benefits than larger operators and transit shipping"},
        {"criterion": "PI", "scenario": "S1", "verify_phrases": ["High, as no changes", "quired for fisheries, shipping"],
         "text": "High, as no changes are required for fisheries, shipping operators, or tourism businesses"},
        {"criterion": "FF", "scenario": "S1", "verify_phrases": ["High feasibility (no added", "isting budgets and"],
         "text": "High feasibility (no added cost), relies entirely on existing budgets and instruments"},
        {"criterion": "EE", "scenario": "S2", "verify_phrases": ["Minor ecological", "mulative corridor-wide"],
         "text": "Minor ecological improvements through voluntary alignment, e.g. shared guidelines for fisheries or tourism, but insufficient to reduce cumulative corridor-wide pressures"},
        {"criterion": "EC", "scenario": "S2", "verify_phrases": ["High economic", "for fisheries remains"],
         "text": "High economic efficiency due to low implementation costs and no major disruption e.g. to tourism demand, shipping routes, planning risks for fisheries remains"},
        {"criterion": "EQ", "scenario": "S2", "verify_phrases": ["Slight equity", "smaller actors"],
         "text": "Slight equity improvements through shared practices, but stronger regions and well-organized sectors benefit more than smaller actors"},
        {"criterion": "PI", "scenario": "S2", "verify_phrases": ["High, as measures remain", "eries, shipping, or tourism"],
         "text": "High, as measures remain voluntary and do not impose binding constraints on fisheries, shipping, or tourism sectors"},
        {"criterion": "FF", "scenario": "S2", "verify_phrases": ["High feasibility, low", "stakeholder engagement"],
         "text": "High feasibility, low additional costs, mainly administrative coordination and stakeholder engagement"},
        {"criterion": "EE", "scenario": "S3", "verify_phrases": ["Clear ecological gains", "of migratory routes"],
         "text": "Clear ecological gains from coordinated fisheries management, harmonized tourism standards, and improved protection of migratory routes"},
        {"criterion": "EC", "scenario": "S3", "verify_phrases": ["Moderate, higher", "ecological limits"],
         "text": "Moderate, higher costs (management, re-routing, etc.) need to be offset by better alignment between operator capacity and ecological limits"},
        {"criterion": "EQ", "scenario": "S3", "verify_phrases": ["More balanced", "for some operators."],
         "text": "More balanced distribution of costs and benefits across regions and stakeholder groups - if safeguards/transition support are built in; otherwise, adjustment burdens can concentrate. Small-scale fisheries and nature tourism benefit from healthier ecosystems, though adjustment costs likely arise for some operators."},
        {"criterion": "PI", "scenario": "S3", "verify_phrases": ["Medium: requires political", "igation/transition narrative"],
         "text": "Medium: requires political agreement among regional authorities and acceptance of clear rules, e.g. by fisheries and tourism operators, requires sustained stakeholder engagement and mitigation/transition narrative"},
        {"criterion": "FF", "scenario": "S3", "verify_phrases": ["Moderate feasibility", "port, but costs are shared"],
         "text": "Moderate feasibility requires dedicated funding for coordination, monitoring, and stakeholder support, but costs are shared across regions"},
        {"criterion": "EE", "scenario": "S4", "verify_phrases": ["High effectiveness:", "tem connectivity"],
         "text": "High effectiveness: fisheries effort, maritime traffic and tourism pressures are managed coherently across the corridor, maximizing ecosystem connectivity"},
        {"criterion": "EC", "scenario": "S4", "verify_phrases": ["High long-term", "may be significant"],
         "text": "High long-term efficiency based on long-term ecological improvements, but short-term adjustment costs for fisheries, shipping and some types of tourism may be significant"},
        {"criterion": "EQ", "scenario": "S4", "verify_phrases": ["High equity potential", "on small islands or specific"],
         "text": "High equity potential if redistribution and compensation mechanisms are included; otherwise risks disproportionate impacts on small islands or specific sectors"},
        {"criterion": "PI", "scenario": "S4", "verify_phrases": ["Lower to medium, it requires", "need to be locally visible"],
         "text": "Lower to medium, it requires binding agreements, shared governance structures, and strong political alignment, requires strong legitimacy, coalition-building, benefit-sharing mechanisms and transition support, benefits need to be locally visible"},
        {"criterion": "FF", "scenario": "S4", "verify_phrases": ["Challenging, high costs for", "for affected sectors"],
         "text": "Challenging, high costs for monitoring, enforcement, coordination, requires substantial and sustained financing, potentially including new EU or transnational funding instruments, potentially including compensation or transition support for affected sectors"}
      ]
    },
    "arctic": {
      "status": "available",
      "baseline_code": "partial_agreement",
      "baseline_verify": {"phrase": "(2024 baseline)", "source_lines": [1879, 1891]},
      "scenarios": [
        {"code": "no_agreement", "short_label": "No Agreement", "ambition_rank": 0},
        {"code": "partial_agreement", "short_label": "Partial Agreement", "ambition_rank": 0},
        {"code": "full_agreement", "short_label": "Full Agreement", "ambition_rank": 0}
      ],
      "cell_source": {"table": "Table 8", "source_lines": [2166, 2180]},
      "provenance": "wp5_source",
      "source_ref": {"document": "MarineSABRES D5.2 Final v5 (23 Jun 2026)", "table": "Table 8", "section": "3.5.4"},
      "cells": [
        {"criterion": "PI", "scenario": "full_agreement", "rating_text": "Low to moderate", "rating_verify": "Full Agree- Low to",
         "verify_phrases": ["Requires states to give up", "may resist if perceived as unequal"],
         "text": "Requires states to give up unilateral control; unlikely without clear gains for all; Iceland and Greenland may resist if perceived as unequal outcomes."},
        {"criterion": "PI", "scenario": "partial_agreement", "rating_text": "Moderate", "rating_verify": "Partial    Moderate",
         "verify_phrases": ["Moderate Reflects current state", "bilateral deals (e.g., UK–Faroes)", "politically more palatable"],
         "text": "Reflects current state; bilateral deals (e.g., UK–Faroes) persist; lacks system-wide enforcement, but politically more palatable."},
        {"criterion": "PI", "scenario": "no_agreement", "rating_text": "High", "rating_verify": "No Agree- High",
         "verify_phrases": ["Politically easy to maintain", "continued certification loss"],
         "text": "Politically easy to maintain; avoids difficult compromises; risks overfishing and continued certification loss."}
      ],
      "revenue": {
        "provenance": "wp5_source",
        "partner_question": 2,
        "data_quality_note": "D5.2 publishes these values, but they are inconsistent with its stated scenario assumptions and with the Annex 6 multipliers (audit A§3.1, partner question 2). They are stored verbatim and never recomputed.",
        "currency": "USD",
        "unit": "usd_millions",
        "price_basis": "retail_midpoint",
        "countries": [
          {"country": "faroe_islands", "baseline_year": 2024,
           "baseline_table": {"table": "Table 2", "source_lines": [1869, 1877]},
           "scenario_table": {"table": "Table 3", "source_lines": [1879, 1891]},
           "species": [
             {"species": "mackerel", "landings_t": 69489, "landings_display": "69,489", "price_usd_per_t": 4790, "price_display": "$4,790",
              "baseline": {"display": "$332.85 million", "usd_millions": 332.85},
              "full_agreement": {"display": "$285.6 million", "usd_millions": 285.6},
              "partial_agreement": {"display": "$332.9 million", "usd_millions": 332.9},
              "no_agreement": {"display": "$183.9 million", "usd_millions": 183.9}},
             {"species": "herring", "landings_t": 59426, "landings_display": "59,426", "price_usd_per_t": 17710, "price_display": "$17,710",
              "baseline": {"display": "$1.05 billion", "usd_millions": 1050},
              "full_agreement": {"display": "$1.19 billion", "usd_millions": 1190},
              "partial_agreement": {"display": "$1.05 billion", "usd_millions": 1050},
              "no_agreement": {"display": "$760.4 million", "usd_millions": 760.4}},
             {"species": "blue_whiting", "landings_t": 433281, "landings_display": "433,281", "price_usd_per_t": 6015, "price_display": "$6,015",
              "baseline": {"display": "$2.61 billion", "usd_millions": 2610},
              "full_agreement": {"display": "$2.71 billion", "usd_millions": 2710},
              "partial_agreement": {"display": "$2.61 billion", "usd_millions": 2610},
              "no_agreement": {"display": "$1.66 billion", "usd_millions": 1660}}
           ]},
          {"country": "greenland", "baseline_year": 2023,
           "baseline_table": {"table": "Table 4", "source_lines": [1933, 1941]},
           "scenario_table": {"table": "Table 5", "source_lines": [1946, 1957]},
           "note": "Faroese retail midpoints were used for herring and blue whiting as proxies (Table 4 note).",
           "species": [
             {"species": "mackerel", "landings_t": 29100, "landings_display": "29,100", "price_usd_per_t": 3035, "price_display": "$3,035",
              "baseline": {"display": "$88.32 million", "usd_millions": 88.32},
              "full_agreement": {"display": "$97.1 million", "usd_millions": 97.1},
              "partial_agreement": {"display": "$88.3 million", "usd_millions": 88.3},
              "no_agreement": {"display": "$56.4 million", "usd_millions": 56.4}},
             {"species": "herring", "landings_t": 7300, "landings_display": "7,300", "price_usd_per_t": 17710, "price_display": "$17,710",
              "baseline": {"display": "$129.28 million", "usd_millions": 129.28},
              "full_agreement": {"display": "$146.5 million", "usd_millions": 146.5},
              "partial_agreement": {"display": "$129.3 million", "usd_millions": 129.3},
              "no_agreement": {"display": "$93.4 million", "usd_millions": 93.4}},
             {"species": "blue_whiting", "landings_t": 26000, "landings_display": "26,000", "price_usd_per_t": 6015, "price_display": "$6,015",
              "baseline": {"display": "$156.39 million", "usd_millions": 156.39},
              "full_agreement": {"display": "$162.7 million", "usd_millions": 162.7},
              "partial_agreement": {"display": "$156.4 million", "usd_millions": 156.4},
              "no_agreement": {"display": "$99.7 million", "usd_millions": 99.7}}
           ]},
          {"country": "iceland", "baseline_year": 2024,
           "baseline_table": {"table": "Table 6", "source_lines": [2010, 2018]},
           "scenario_table": {"table": "Table 7", "source_lines": [2025, 2037]},
           "note": "Tables 6-7 are positionally garbled in the PDF text layer; values are verified by presence in the table's lines only.",
           "species": [
             {"species": "mackerel", "landings_t": 89615, "landings_display": "89,615", "price_usd_per_t": 9017, "price_display": "$9,017",
              "baseline": {"display": "$807.88 million", "usd_millions": 807.88},
              "full_agreement": {"display": "$693.2 million", "usd_millions": 693.2},
              "partial_agreement": {"display": "$807.9 million", "usd_millions": 807.9},
              "no_agreement": {"display": "$446.4 million", "usd_millions": 446.4}},
             {"species": "herring", "landings_t": 134552, "landings_display": "134,552", "price_usd_per_t": 6114, "price_display": "$6,114",
              "baseline": {"display": "$822.79 million", "usd_millions": 822.79},
              "full_agreement": {"display": "$932.2 million", "usd_millions": 932.2},
              "partial_agreement": {"display": "$822.8 million", "usd_millions": 822.8},
              "no_agreement": {"display": "$594.5 million", "usd_millions": 594.5}},
             {"species": "blue_whiting", "landings_t": 321047, "landings_display": "321,047", "price_usd_per_t": 5000, "price_display": "$5,000",
              "baseline": {"display": "$1.61 billion", "usd_millions": 1610},
              "full_agreement": {"display": "$1.67 billion", "usd_millions": 1670},
              "partial_agreement": {"display": "$1.61 billion", "usd_millions": 1610},
              "no_agreement": {"display": "$1.02 billion", "usd_millions": 1020}}
           ]}
        ]
      }
    },
    "tuscan": {
      "status": "valuation_only",
      "baseline_code": "",
      "note": "D5.2 chapter 4 is a valuation and benefit-transfer chapter with no scenario set (L2784-2793); use the valuation calculator (WS-5).",
      "scenarios": [],
      "cells": []
    }
  }
}
```

- [ ] **Step 6: Run the test and confirm that it passes**

Run: `"C:/Program Files/R/R-4.4.1/bin/Rscript.exe" -e "testthat::test_file('tests/testthat/test-impact-reference-data.R')"`
Expected: all tests pass. If a phrase fails, fix the JSON transcription (copy the phrase from the extract line); never loosen the test.

- [ ] **Step 7: Commit**

```bash
git -C "C:/Users/arturas.baziukas/wt-ws6" add MarineSABRES_SES_Shiny/scripts/build_wp5_indicator_sources.py MarineSABRES_SES_Shiny/scripts/wp5_kb_sources/d5.2_v5_indicator_sources.md MarineSABRES_SES_Shiny/data/wp5_impact_reference.json MarineSABRES_SES_Shiny/tests/testthat/test-impact-reference-data.R
git -C "C:/Users/arturas.baziukas/wt-ws6" commit -m "feat(wp5): D5.2 impact-assessment reference data (Table 21, Arctic Tables 2-8) checked against the extract (WS-6a)"
```

---

### Task 2: Reference loader and getters

**Files:**
- Create: `functions/impact_reference.R`
- Modify: `global.R` (after `source("functions/indicator_snapshot.R", local = FALSE)`)
- Test: `tests/testthat/test-impact-reference.R`

**Interfaces:**
- Consumes: `data/wp5_impact_reference.json` (Task 1); `get_scenarios_for_da(da)` → list of `list(code, name, source_ref)`; `wp5_criterion_code()`; `WP5_DA_CONTEXTS`.
- Produces:
  - `load_impact_reference(path = NULL, force_reload = FALSE)` → parsed list or NULL (warns)
  - `impact_reference_status(da)` → `"available"` | `"valuation_only"` | `"unavailable"`; errors on an unknown DA
  - `impact_reference_scenarios(da)` → list of `list(code, name, short_label, ambition_rank (int), confidence_text, confidence_codes (chr))`
  - `impact_reference_baseline(da)` → string (`""` if none)
  - `impact_reference_cell(da, criterion, scenario_code)` → `list(criterion, scenario, rating_text, text, table, source_lines (int[2]), provenance)` or NULL
  - `impact_reference_version()` → the reference file's `schema_version` (`""` when unavailable)
  - `impact_reference_revenue(da)` → the `revenue` list or NULL

- [ ] **Step 1: Write the failing test**

Create `tests/testthat/test-impact-reference.R`:

```r
# tests/testthat/test-impact-reference.R
# WS-6a: reference loader and getters.
library(testthat)

ref_file <- file.path(PROJECT_ROOT, "data", "wp5_impact_reference.json")
load_wp5_mechanisms_kb(file.path(PROJECT_ROOT, "data", "ses_knowledge_db_wp5_mechanisms.json"),
                       force_reload = TRUE)
load_impact_reference(ref_file, force_reload = TRUE)

test_that("status per DA", {
  expect_identical(impact_reference_status("macaronesia"), "available")
  expect_identical(impact_reference_status("arctic"), "available")
  expect_identical(impact_reference_status("tuscan"), "valuation_only")
  expect_error(impact_reference_status("baltic"), "Unknown DA")
})

test_that("scenarios take their names from the WS-2 KB and keep rank and confidence", {
  sc <- impact_reference_scenarios("macaronesia")
  kb <- get_scenarios_for_da("macaronesia")
  expect_identical(vapply(sc, `[[`, "", "code"), paste0("S", 1:4))
  expect_identical(vapply(sc, `[[`, "", "name"), vapply(kb, function(s) s$name, ""))
  expect_identical(vapply(sc, `[[`, 1L, "ambition_rank"), 1:4)
  expect_identical(sc[[2]]$confidence_codes, c("medium", "high"))
  expect_identical(sc[[1]]$short_label, "S1 BAU")
  arc <- impact_reference_scenarios("arctic")
  expect_identical(vapply(arc, `[[`, 1L, "ambition_rank"), c(0L, 0L, 0L))
  expect_identical(arc[[1]]$confidence_codes, character(0))
  expect_identical(impact_reference_scenarios("tuscan"), list())
})

test_that("baseline codes", {
  expect_identical(impact_reference_baseline("macaronesia"), "S1")
  expect_identical(impact_reference_baseline("arctic"), "partial_agreement")
  expect_identical(impact_reference_baseline("tuscan"), "")
})

test_that("reference cells resolve criterion aliases and carry their source", {
  c1 <- impact_reference_cell("macaronesia", "PO", "S4")      # PO = PI alias
  expect_identical(c1$criterion, "PI")
  expect_true(startsWith(c1$text, "Lower to medium"))
  expect_identical(c1$table, "Table 21")
  expect_identical(c1$source_lines, c(4798L, 4851L))
  expect_identical(c1$rating_text, "")
  expect_identical(c1$provenance, "wp5_source")
  expect_identical(impact_reference_version(), "1.0.0")
  a <- impact_reference_cell("arctic", "PI", "full_agreement")
  expect_identical(a$rating_text, "Low to moderate")
  expect_null(impact_reference_cell("arctic", "EE", "full_agreement"))
  expect_null(impact_reference_cell("macaronesia", "EE", "S9"))
})

test_that("Arctic revenue is exposed as published", {
  rev <- impact_reference_revenue("arctic")
  expect_identical(rev$unit, "usd_millions")
  expect_null(impact_reference_revenue("macaronesia"))
})

test_that("a missing reference file warns and degrades to 'unavailable'", {
  expect_warning(load_impact_reference(tempfile(fileext = ".json"), force_reload = TRUE), "reference data not loaded")
  # later getter calls must not silently re-read the default path (failed load is cached)
  expect_silent(expect_identical(impact_reference_status("macaronesia"), "unavailable"))
  expect_identical(impact_reference_scenarios("macaronesia"), list())
  expect_null(impact_reference_cell("macaronesia", "EE", "S1"))
  expect_identical(impact_reference_version(), "")
  load_impact_reference(ref_file, force_reload = TRUE)
  expect_identical(impact_reference_status("macaronesia"), "available")
})
```

- [ ] **Step 2: Run it and confirm that it fails**

Run: `"C:/Program Files/R/R-4.4.1/bin/Rscript.exe" -e "testthat::test_file('tests/testthat/test-impact-reference.R')"`
Expected: FAIL with `could not find function "load_impact_reference"`.

- [ ] **Step 3: Write the loader**

Create `functions/impact_reference.R`:

```r
# functions/impact_reference.R
# WP5 impact-assessment reference data (spec 2026-10-11 WS-6; WS-6a).
# Read-only D5.2 reference: Macaronesia Table 21, Arctic Tables 2-8
# (data/wp5_impact_reference.json). Users copy reference cells into an
# editable assessment (functions/impact_assessment_model.R).

.impact_ref_env <- new.env(parent = emptyenv())
.impact_ref_env$db <- NULL
.impact_ref_env$loaded <- FALSE   # TRUE after any attempt, failed or not

#' Load the impact-assessment reference data (cached)
#' A failed load is cached too: the data stays "unavailable" (one warning)
#' until force_reload = TRUE, instead of re-reading the default path on
#' every getter call.
#' @return Parsed list, or NULL (with a warning) if missing/corrupt
load_impact_reference <- function(path = NULL, force_reload = FALSE) {
  if (isTRUE(.impact_ref_env$loaded) && !force_reload) return(invisible(.impact_ref_env$db))
  if (is.null(path)) {
    path <- if (exists("get_project_file", mode = "function")) {
      get_project_file("data", "wp5_impact_reference.json")
    } else {
      file.path("data", "wp5_impact_reference.json")
    }
  }
  db <- tryCatch(jsonlite::fromJSON(path, simplifyVector = FALSE), error = function(e) {
    warning(sprintf("[WP5 impact] reference data not loaded (%s): %s", path, conditionMessage(e)),
            call. = FALSE)
    NULL
  })
  .impact_ref_env$db <- db
  .impact_ref_env$loaded <- TRUE
  invisible(db)
}

#' Version of the loaded reference data ("" when unavailable); stored on copied cells
impact_reference_version <- function() {
  db <- load_impact_reference()
  if (is.null(db)) return("")
  as.character(db$schema_version %||% "")
}

.impact_ref_da <- function(da) {
  if (!is.character(da) || length(da) != 1 || !da %in% WP5_DA_CONTEXTS) {
    stop("Unknown DA: ", paste(da, collapse = ","))
  }
  db <- load_impact_reference()
  if (is.null(db)) return(NULL)
  db$demonstration_areas[[da]]
}

#' Reference availability for a DA: "available", "valuation_only" or "unavailable"
impact_reference_status <- function(da) {
  b <- .impact_ref_da(da)
  if (is.null(b)) return("unavailable")
  as.character(b$status %||% "unavailable")
}

#' Reference scenarios for a DA; names come from the WS-2 mechanism KB
#' @return List of list(code, name, short_label, ambition_rank, confidence_text, confidence_codes)
impact_reference_scenarios <- function(da) {
  b <- .impact_ref_da(da)
  if (is.null(b)) return(list())
  kb <- get_scenarios_for_da(da)
  kb_names <- setNames(vapply(kb, function(s) as.character(s$name %||% ""), character(1)),
                       vapply(kb, function(s) as.character(s$code %||% ""), character(1)))
  lapply(b$scenarios %||% list(), function(s) {
    code <- as.character(s$code)
    short <- as.character(s$short_label %||% code)
    nm <- if (code %in% names(kb_names)) kb_names[[code]] else ""
    list(code = code,
         name = if (nzchar(nm)) nm else short,
         short_label = short,
         ambition_rank = as.integer(s$ambition_rank %||% 0L),
         confidence_text = as.character(s$confidence_text %||% ""),
         confidence_codes = as.character(unlist(s$confidence_codes %||% list())))
  })
}

#' Baseline scenario code published for a DA ("" when none)
impact_reference_baseline <- function(da) {
  b <- .impact_ref_da(da)
  if (is.null(b)) return("")
  as.character(b$baseline_code %||% "")
}

#' One read-only reference cell, or NULL
#' @return list(criterion, scenario, rating_text, text, table, source_lines)
impact_reference_cell <- function(da, criterion, scenario_code) {
  b <- .impact_ref_da(da)
  if (is.null(b)) return(NULL)
  crit <- wp5_criterion_code(criterion)
  src <- b$cell_source %||% list()
  for (cl in b$cells %||% list()) {
    if (identical(cl$criterion, crit) && identical(cl$scenario, scenario_code)) {
      return(list(criterion = crit, scenario = scenario_code,
                  rating_text = as.character(cl$rating_text %||% ""),
                  text = as.character(cl$text %||% ""),
                  table = as.character(src$table %||% ""),
                  source_lines = as.integer(unlist(src$source_lines %||% list())),
                  provenance = as.character(b$provenance %||% "wp5_source")))
    }
  }
  NULL
}

#' Published revenue tables (Arctic) or NULL
impact_reference_revenue <- function(da) {
  b <- .impact_ref_da(da)
  if (is.null(b)) return(NULL)
  b$revenue
}
```

In `global.R`, directly after `source("functions/indicator_snapshot.R", local = FALSE)`, add:

```r
source("functions/impact_reference.R", local = FALSE)
```

- [ ] **Step 4: Run the tests and confirm that they pass**

```bash
"C:/Program Files/R/R-4.4.1/bin/Rscript.exe" -e "testthat::test_file('tests/testthat/test-impact-reference.R')"
"C:/Program Files/R/R-4.4.1/bin/Rscript.exe" -e "testthat::test_file('tests/testthat/test-functions-sourced-in-app.R')"
```

Expected: both pass.

- [ ] **Step 5: Commit**

```bash
git -C "C:/Users/arturas.baziukas/wt-ws6" add MarineSABRES_SES_Shiny/functions/impact_reference.R MarineSABRES_SES_Shiny/global.R MarineSABRES_SES_Shiny/tests/testthat/test-impact-reference.R
git -C "C:/Users/arturas.baziukas/wt-ws6" commit -m "feat(wp5): impact-assessment reference loader and getters (WS-6a)"
```

---

### Task 3: Assessment model — scenarios, cells, problems, displacement

**Files:**
- Modify: `constants.R` (append after the WS-5 block, which ends with `WP5_DEFAULT_TIME_HORIZON <- 20L` and the lines that follow it)
- Create: `functions/impact_assessment_model.R`
- Modify: `global.R` (after the Task 2 line)
- Test: `tests/testthat/test-impact-assessment-model.R`

**Interfaces:**
- Consumes: `WP5_RUBRIC`, `WP5_CRITERIA`, `WP5_CRITERION_SUBDIMENSIONS`, `WP5_DA_CONTEXTS`, `wp5_criterion_code()`.
- Produces:
  - constants `IMPACT_SCHEMA_VERSION` (1L), `IMPACT_MAX_SCENARIOS` (5L), `IMPACT_SCENARIO_DIMENSIONS`, `IMPACT_SCENARIO_SOURCES`, `IMPACT_DISPLACEMENT_ANSWERS`, `WP5_IMPACT_MIN_APP_VERSION` ("1.25.0")
  - constant `IMPACT_TEXT_SECTIONS` (section → field names)
  - `new_impact_assessment(da = "")` → `list(schema, da, characterisation, baseline_code, scenarios = named list, scope = list(element_ids, indicator_codes, displacement = list(answer, note, displaced_pressure_id)), cells = named list, uncertainty, trade_offs, recommendations)`
  - `impact_set_section(ia, section, values)` (errors `unknown_section`, `unknown_field`); `impact_set_scope_items(ia, element_ids, indicator_codes)`
  - `new_impact_scenario(code, name, description = "", ambition_rank = 0L, source = "user")`
  - `new_impact_cell()`
  - `impact_scenario_codes(ia)`; `impact_add_scenario(ia, scenario)`; `impact_remove_scenario(ia, code)`; `impact_set_baseline(ia, code)`
  - `impact_get_cell(ia, criterion, scenario_code)`; `impact_set_cell(ia, criterion, scenario_code, cell)`
  - `impact_cell_problems(cell, criterion)` → character vector of problem codes
  - `impact_step_problems(ia, step)` → `data.frame(criterion, scenario, problem)`
  - `impact_problem_blocks(code)` → logical; `impact_can_advance(ia, step)` → logical
  - `impact_set_displacement(ia, answer, note = "", displaced_pressure_id = "")`; `impact_displacement_flagged(ia)`
  - Errors are conditions of class `impact_error` with `$code` (e.g. `"too_many_scenarios"`)
  - Internal helpers reused by Task 5: `.impact_fill_cell(x)`, `.impact_fill_scenario(x)`, `.impact_fill_scope(x)`, `.impact_fill_section(x, fields)`, `.imp_str`, `.imp_chr`, `.imp_int`, `.imp_named_str`

- [ ] **Step 1: Write the failing test**

Create `tests/testthat/test-impact-assessment-model.R`:

```r
# tests/testthat/test-impact-assessment-model.R
# WS-6a: pure impact-assessment model (no Shiny).
library(testthat)

err_code <- function(expr) tryCatch({ expr; NA_character_ }, impact_error = function(e) e$code)
two_scen <- function() {
  ia <- new_impact_assessment("macaronesia")
  ia <- impact_add_scenario(ia, new_impact_scenario("S1", "BAU"))
  impact_add_scenario(ia, new_impact_scenario("S2", "Light", ambition_rank = 2L))
}

test_that("constants: ordinal schema, scenario cap, release floor above 1.24.0", {
  expect_identical(IMPACT_MAX_SCENARIOS, 5L)
  expect_identical(IMPACT_SCHEMA_VERSION, 1L)
  expect_length(IMPACT_SCENARIO_DIMENSIONS, 6)
  # 1.24.0 shipped without the impact-assessment block, so it must not satisfy the stamp
  expect_gt(utils::compareVersion(WP5_IMPACT_MIN_APP_VERSION, "1.24.0"), 0)
  expect_gte(utils::compareVersion(WP5_IMPACT_MIN_APP_VERSION, WP5_INDICATOR_MIN_APP_VERSION), 0)
})

test_that("a new assessment is empty and only accepts known DAs", {
  ia <- new_impact_assessment()
  expect_identical(ia$da, "")
  expect_identical(impact_scenario_codes(ia), character(0))
  expect_identical(ia$baseline_code, "")
  expect_identical(err_code(new_impact_assessment("baltic")), "unknown_da")
})

test_that("scenarios: unique codes, valid codes, capped at IMPACT_MAX_SCENARIOS", {
  ia <- two_scen()
  expect_identical(impact_scenario_codes(ia), c("S1", "S2"))
  expect_identical(ia$scenarios$S2$ambition_rank, 2L)
  expect_identical(names(ia$scenarios$S1$dimensions), IMPACT_SCENARIO_DIMENSIONS)
  expect_identical(err_code(impact_add_scenario(ia, new_impact_scenario("S1", "again"))), "duplicate_scenario_code")
  expect_identical(err_code(new_impact_scenario("S 1", "bad")), "invalid_scenario_code")
  expect_identical(err_code(new_impact_scenario("S9", "x", source = "pdf")), "invalid_scenario_source")
  for (k in 3:5) ia <- impact_add_scenario(ia, new_impact_scenario(paste0("S", k), "x"))
  expect_identical(err_code(impact_add_scenario(ia, new_impact_scenario("S6", "x"))), "too_many_scenarios")
})

test_that("removing a scenario drops its cells and clears it as baseline", {
  ia <- impact_set_baseline(two_scen(), "S1")
  c1 <- new_impact_cell(); c1$direction <- "increase"
  ia <- impact_set_cell(ia, "EE", "S1", c1)
  ia <- impact_set_cell(ia, "EE", "S2", c1)
  ia <- impact_remove_scenario(ia, "S1")
  expect_identical(impact_scenario_codes(ia), "S2")
  expect_identical(names(ia$cells$EE), "S2")
  expect_identical(ia$baseline_code, "")
  ia <- impact_remove_scenario(ia, "S2")
  expect_identical(names(ia$cells), character(0))
  expect_identical(err_code(impact_set_baseline(ia, "S2")), "unknown_scenario")
})

test_that("cells: aliases resolve, unknown scenario or criterion is an error, unset cell is empty", {
  ia <- two_scen()
  cl <- new_impact_cell(); cl$direction <- "decrease"; cl$evidence <- c("dataset", "literature")
  ia <- impact_set_cell(ia, "FI", "S2", cl)             # FI = FF alias
  expect_identical(impact_get_cell(ia, "FF", "S2")$evidence, c("dataset", "literature"))
  expect_identical(impact_get_cell(ia, "EE", "S1"), new_impact_cell())
  expect_identical(err_code(impact_set_cell(ia, "EE", "S7", cl)), "unknown_scenario")
  expect_identical(err_code(impact_set_cell(ia, "XX", "S1", cl)), "unknown_criterion")
})

test_that("cell problems: invalid codes, the low-confidence driver rule, incompleteness", {
  expect_setequal(impact_cell_problems(new_impact_cell(), "EE"), c("direction_missing", "confidence_missing"))
  cl <- new_impact_cell()
  cl$direction <- "up"; cl$magnitude <- "huge"; cl$confidence <- "low"
  cl$evidence <- c("dataset", "rumour"); cl$indicator_roles <- list(C_01 = "main")
  cl$subdimension_notes <- list(credibility = "x")      # PI sub-dimension on an EQ cell
  p <- impact_cell_problems(cl, "EQ")
  expect_true(all(c("invalid_direction", "invalid_magnitude", "invalid_evidence",
                    "invalid_indicator_role", "invalid_subdimension", "driver_required") %in% p))
  ok <- new_impact_cell()
  ok$direction <- "increase"; ok$confidence <- "low"; ok$uncertainty_driver <- "data_gap"
  ok$subdimension_notes <- list(distributional = "Small islands")
  expect_identical(impact_cell_problems(ok, "EQ"), character(0))
  expect_identical(impact_cell_problems(ok, "EE"), "invalid_subdimension")  # EE has no sub-dimensions
})

test_that("step 2 blocks without scenarios or baseline; step 4 blocks low confidence without a driver", {
  ia <- new_impact_assessment("arctic")
  expect_identical(impact_step_problems(ia, 2)$problem, "no_scenarios")
  expect_false(impact_can_advance(ia, 2))
  ia <- two_scen()
  expect_identical(impact_step_problems(ia, 2)$problem, "baseline_missing")
  ia <- impact_set_baseline(ia, "S1")
  expect_true(impact_can_advance(ia, 2))
  # incomplete cells are reported but do not block
  expect_true(impact_can_advance(ia, 4))
  expect_true("direction_missing" %in% impact_step_problems(ia, 4)$problem)
  cl <- new_impact_cell(); cl$direction <- "increase"; cl$confidence <- "low"
  ia <- impact_set_cell(ia, "EC", "S2", cl)
  sp <- impact_step_problems(ia, 4)
  expect_identical(sp$criterion[sp$problem == "driver_required"], "EC")
  expect_identical(sp$scenario[sp$problem == "driver_required"], "S2")
  expect_false(impact_can_advance(ia, 4))
})

test_that("displacement/leakage prompt (A§8.4): a yes needs a note", {
  ia <- two_scen()
  expect_false(impact_displacement_flagged(ia))
  expect_identical(err_code(impact_set_displacement(ia, "maybe")), "invalid_displacement_answer")
  ia <- impact_set_displacement(ia, "yes")
  expect_true(impact_displacement_flagged(ia))
  expect_identical(impact_step_problems(ia, 3)$problem, "displacement_note_missing")
  expect_false(impact_can_advance(ia, 3))
  ia <- impact_set_displacement(ia, "yes", "Effort may move to ABNJ waters", displaced_pressure_id = "P012")
  expect_true(impact_can_advance(ia, 3))
  expect_identical(ia$scope$displacement$displaced_pressure_id, "P012")
})

test_that("steps 1, 3, 5, 6 and 7 have stored fields (roadmap §8.4)", {
  ia <- new_impact_assessment("macaronesia")
  expect_identical(names(ia), c("schema", "da", "characterisation", "baseline_code", "scenarios", "scope",
                                "cells", "uncertainty", "trade_offs", "recommendations"))
  expect_identical(names(ia$characterisation), IMPACT_TEXT_SECTIONS$characterisation)
  ia <- impact_set_section(ia, "characterisation", list(focal_issue = "Migratory corridor", time_horizon = "2035"))
  expect_identical(ia$characterisation$focal_issue, "Migratory corridor")
  expect_identical(ia$characterisation$stakeholders, "")
  ia <- impact_set_section(ia, "recommendations", list(text = "Start with S3"))
  expect_identical(ia$recommendations$text, "Start with S3")
  err <- function(expr) tryCatch({ expr; NA_character_ }, impact_error = function(e) e$code)
  expect_identical(err(impact_set_section(ia, "scenarios", list(text = "x"))), "unknown_section")
  expect_identical(err(impact_set_section(ia, "uncertainty", list(text = "x"))), "unknown_field")
  ia <- impact_set_scope_items(ia, element_ids = c("P001", "C003"), indicator_codes = "C_01")
  expect_identical(ia$scope$element_ids, c("P001", "C003"))
  expect_identical(ia$scope$indicator_codes, "C_01")
})
```

- [ ] **Step 2: Run it and confirm that it fails**

Run: `"C:/Program Files/R/R-4.4.1/bin/Rscript.exe" -e "testthat::test_file('tests/testthat/test-impact-assessment-model.R')"`
Expected: FAIL with `object 'IMPACT_MAX_SCENARIOS' not found` or `could not find function`.

- [ ] **Step 3: Add the constants**

Append to `constants.R`, after the WP5 VALUATION CALCULATOR block:

```r
# ============================================================================
# WP5 IMPACT ASSESSMENT (spec 2026-10-11 WS-6; data + model layer WS-6a)
# ============================================================================
# Stored at data$analysis$impact_assessment. Cell codes come from WP5_RUBRIC
# (WS-1). The lists below are not WS-1 vocabularies; WS-6b labels them.
IMPACT_SCHEMA_VERSION <- 1L
IMPACT_MAX_SCENARIOS <- 5L       # roadmap §8.3; D5.2 DAs use 3 (Arctic) and 4 (Macaronesia)
# D5.2 Macaronesia scenario description dimensions (audit A§3.3); optional free text
IMPACT_SCENARIO_DIMENSIONS <- c("governance_form", "spatial_scope", "sectoral_activation",
                                "monitoring_data", "compliance_credibility", "financing_capacity")
IMPACT_SCENARIO_SOURCES <- c("user", "wp5_reference")
IMPACT_DISPLACEMENT_ANSWERS <- c("yes", "no", "unsure")   # displacement/leakage prompt (audit A§8.4)
# Free-text sections of the 7-step flow (roadmap §8.4): step 1 characterisation,
# step 5 uncertainty, step 6 trade-offs (auto_draft = WS-6c narrative), step 7.
IMPACT_TEXT_SECTIONS <- list(
  characterisation = c("focal_issue", "spatial_scope", "time_horizon", "stakeholders"),
  uncertainty      = c("notes"),
  trade_offs       = c("text", "auto_draft"),
  recommendations  = c("text")
)
# 1.24.0 shipped without this block, so the first release carrying it is 1.25.0.
WP5_IMPACT_MIN_APP_VERSION <- "1.25.0"
```

- [ ] **Step 4: Write the model**

Create `functions/impact_assessment_model.R`:

```r
# functions/impact_assessment_model.R
# WP5 impact assessment: pure data model (spec 2026-10-11 WS-6; WS-6a).
# Stored at project$data$analysis$impact_assessment. No Shiny code here.
# Errors (class "impact_error", field $code) and problems are codes;
# the module (WS-6b) translates them.
#
# Shape: scenarios and cells are named lists (JSON objects), so a JSON load
# with simplifyVector = TRUE never turns them into data frames:
#   list(schema, da,
#        characterisation = list(focal_issue, spatial_scope, time_horizon, stakeholders),  # step 1
#        baseline_code, scenarios = list(<code> = scenario, ...),                           # step 2
#        scope = list(element_ids, indicator_codes,                                         # step 3
#                     displacement = list(answer, note, displaced_pressure_id)),
#        cells = list(<criterion> = list(<scenario code> = cell, ...), ...),                # step 4
#        uncertainty = list(notes), trade_offs = list(text, auto_draft),                   # steps 5-6
#        recommendations = list(text))                                                      # step 7
# The normaliser is a whitelist: a new stored field must be added to the
# matching .impact_fill_* helper and to normalize_impact_assessment().

.impact_error <- function(code) {
  stop(structure(class = c("impact_error", "error", "condition"),
                 list(message = paste0("impact_assessment: ", code), call = NULL, code = code)))
}

# ---- scalar coercion (shared with the normaliser) ----------------------------
.imp_empty_named <- function() setNames(list(), character(0))
.imp_str <- function(v) {
  if (is.null(v) || length(v) == 0) return("")
  v <- v[[1]]
  # !is.atomic first: a nested list from hand-edited JSON must not reach is.na()
  if (is.null(v) || !is.atomic(v) || length(v) != 1 || is.na(v)) "" else as.character(v)
}
.imp_chr <- function(v) {
  v <- unlist(v, use.names = FALSE)
  if (is.null(v)) return(character(0))
  v <- as.character(v)
  v[!is.na(v) & nzchar(v)]
}
.imp_int <- function(v) {
  i <- suppressWarnings(as.integer(.imp_str(v)))
  if (is.na(i)) 0L else i
}
.imp_named_str <- function(v) {
  if (is.null(v) || length(v) == 0 || is.null(names(v))) return(.imp_empty_named())
  v <- as.list(v)
  nm <- names(v)
  keep <- !is.na(nm) & nzchar(nm)
  out <- lapply(v[keep], .imp_str)
  names(out) <- nm[keep]
  out
}

# ---- constructors ------------------------------------------------------------
.impact_fill_cell <- function(x) {
  x <- if (is.list(x)) x else list()
  list(direction = .imp_str(x[["direction"]]),
       magnitude = .imp_str(x[["magnitude"]]),
       timing = .imp_str(x[["timing"]]),
       confidence = .imp_str(x[["confidence"]]),
       evidence = .imp_chr(x[["evidence"]]),
       uncertainty_driver = .imp_str(x[["uncertainty_driver"]]),
       rationale = .imp_str(x[["rationale"]]),
       subdimension_notes = .imp_named_str(x[["subdimension_notes"]]),
       indicator_roles = .imp_named_str(x[["indicator_roles"]]),   # code -> primary|supporting
       mechanism_ids = .imp_chr(x[["mechanism_ids"]]),
       reference = .imp_named_str(x[["reference"]]))               # set when copied from WP5 reference
}

#' An empty criterion x scenario cell (ordinal rubric, spec WS-6 change 1)
new_impact_cell <- function() .impact_fill_cell(list())

.impact_fill_scenario <- function(x) {
  dims <- .imp_named_str(x[["dimensions"]])
  src <- .imp_str(x[["source"]])
  list(code = .imp_str(x[["code"]]),
       name = .imp_str(x[["name"]]),
       description = .imp_str(x[["description"]]),
       ambition_rank = .imp_int(x[["ambition_rank"]]),      # 0 = unranked
       dimensions = setNames(lapply(IMPACT_SCENARIO_DIMENSIONS, function(d) .imp_str(dims[[d]])),
                             IMPACT_SCENARIO_DIMENSIONS),
       source = if (src %in% IMPACT_SCENARIO_SOURCES) src else "user")
}

.impact_valid_code <- function(code) {
  is.character(code) && length(code) == 1 && !is.na(code) && grepl("^[A-Za-z0-9_]{1,40}$", code)
}

#' A scenario on the assessment's scenario axis (spec WS-6 change 2)
new_impact_scenario <- function(code, name, description = "", ambition_rank = 0L, source = "user") {
  if (!.impact_valid_code(code)) .impact_error("invalid_scenario_code")
  if (!source %in% IMPACT_SCENARIO_SOURCES) .impact_error("invalid_scenario_source")
  .impact_fill_scenario(list(code = code, name = name %||% code, description = description,
                             ambition_rank = ambition_rank, source = source))
}

.impact_fill_section <- function(x, fields) {
  x <- .imp_named_str(x)
  setNames(lapply(fields, function(f) .imp_str(x[[f]])), fields)
}

# Step 3: selected ISA elements / registry indicators + displacement check (A§8.4)
.impact_fill_scope <- function(x) {
  x <- if (is.list(x)) x else list()
  d <- x[["displacement"]]
  if (!is.list(d)) d <- list()
  ans <- .imp_str(d[["answer"]])
  if (!ans %in% IMPACT_DISPLACEMENT_ANSWERS) ans <- ""
  list(element_ids = .imp_chr(x[["element_ids"]]),
       indicator_codes = .imp_chr(x[["indicator_codes"]]),
       displacement = list(answer = ans, note = .imp_str(d[["note"]]),
                           displaced_pressure_id = .imp_str(d[["displaced_pressure_id"]])))
}

#' An empty assessment, optionally for a WP5 DA
new_impact_assessment <- function(da = "") {
  if (!identical(da, "") && !(is.character(da) && length(da) == 1 && da %in% WP5_DA_CONTEXTS)) {
    .impact_error("unknown_da")
  }
  list(schema = IMPACT_SCHEMA_VERSION, da = da,
       characterisation = .impact_fill_section(list(), IMPACT_TEXT_SECTIONS$characterisation),
       baseline_code = "",
       scenarios = .imp_empty_named(),
       scope = .impact_fill_scope(list()),
       cells = .imp_empty_named(),
       uncertainty = .impact_fill_section(list(), IMPACT_TEXT_SECTIONS$uncertainty),
       trade_offs = .impact_fill_section(list(), IMPACT_TEXT_SECTIONS$trade_offs),
       recommendations = .impact_fill_section(list(), IMPACT_TEXT_SECTIONS$recommendations))
}

#' Set free-text fields of a section (characterisation, uncertainty, trade_offs, recommendations)
#' @param values Named list/character of field = text; unknown fields are an error
impact_set_section <- function(ia, section, values) {
  if (!is.character(section) || length(section) != 1 || !section %in% names(IMPACT_TEXT_SECTIONS)) {
    .impact_error("unknown_section")
  }
  values <- .imp_named_str(values)
  if (any(!names(values) %in% IMPACT_TEXT_SECTIONS[[section]])) .impact_error("unknown_field")
  for (f in names(values)) ia[[section]][[f]] <- values[[f]]
  ia
}

#' Step 3 scope: ISA element IDs and registry indicator codes in scope
impact_set_scope_items <- function(ia, element_ids = character(0), indicator_codes = character(0)) {
  ia$scope$element_ids <- .imp_chr(element_ids)
  ia$scope$indicator_codes <- .imp_chr(indicator_codes)
  ia
}

# ---- scenarios ---------------------------------------------------------------
impact_scenario_codes <- function(ia) names(ia$scenarios) %||% character(0)

impact_add_scenario <- function(ia, scenario) {
  if (scenario$code %in% impact_scenario_codes(ia)) .impact_error("duplicate_scenario_code")
  if (length(ia$scenarios) >= IMPACT_MAX_SCENARIOS) .impact_error("too_many_scenarios")
  ia$scenarios[[scenario$code]] <- scenario
  ia
}

impact_remove_scenario <- function(ia, code) {
  if (!code %in% impact_scenario_codes(ia)) return(ia)
  ia$scenarios[[code]] <- NULL
  for (cr in names(ia$cells)) ia$cells[[cr]][[code]] <- NULL
  ia$cells <- ia$cells[lengths(ia$cells) > 0]
  if (identical(ia$baseline_code, code)) ia$baseline_code <- ""
  ia
}

#' IMPACT is the difference against the baseline (D5.2 L609-611)
impact_set_baseline <- function(ia, code) {
  if (!code %in% impact_scenario_codes(ia)) .impact_error("unknown_scenario")
  ia$baseline_code <- code
  ia
}

# ---- cells -------------------------------------------------------------------
.impact_criterion <- function(criterion) {
  cr <- wp5_criterion_code(criterion)
  if (length(cr) != 1 || is.na(cr)) .impact_error("unknown_criterion")
  cr
}

impact_get_cell <- function(ia, criterion, scenario_code) {
  cr <- .impact_criterion(criterion)
  ia$cells[[cr]][[scenario_code]] %||% new_impact_cell()
}

impact_set_cell <- function(ia, criterion, scenario_code, cell) {
  cr <- .impact_criterion(criterion)
  if (!scenario_code %in% impact_scenario_codes(ia)) .impact_error("unknown_scenario")
  if (is.null(ia$cells[[cr]])) ia$cells[[cr]] <- .imp_empty_named()
  ia$cells[[cr]][[scenario_code]] <- .impact_fill_cell(cell)
  ia
}

# ---- problems ----------------------------------------------------------------
#' Problem codes for one cell. "invalid_*" and "driver_required" block step
#' advance; "direction_missing"/"confidence_missing" only mark it incomplete.
impact_cell_problems <- function(cell, criterion) {
  cr <- .impact_criterion(criterion)
  cell <- .impact_fill_cell(cell)
  p <- character(0)
  for (f in c("direction", "magnitude", "timing", "confidence", "uncertainty_driver")) {
    v <- cell[[f]]
    if (nzchar(v) && !v %in% WP5_RUBRIC[[f]]) p <- c(p, paste0("invalid_", f))
  }
  if (any(!cell$evidence %in% WP5_RUBRIC$evidence)) p <- c(p, "invalid_evidence")
  if (any(!unlist(cell$indicator_roles) %in% WP5_RUBRIC$indicator_role)) p <- c(p, "invalid_indicator_role")
  allowed_sub <- WP5_CRITERION_SUBDIMENSIONS[[cr]] %||% character(0)
  if (any(!names(cell$subdimension_notes) %in% allowed_sub)) p <- c(p, "invalid_subdimension")
  if (identical(cell$confidence, "low") && !nzchar(cell$uncertainty_driver)) p <- c(p, "driver_required")
  if (!nzchar(cell$direction)) p <- c(p, "direction_missing")
  if (!nzchar(cell$confidence)) p <- c(p, "confidence_missing")
  p
}

impact_problem_blocks <- function(code) {
  startsWith(code, "invalid_") |
    code %in% c("driver_required", "no_scenarios", "too_many_scenarios", "baseline_missing",
                "displacement_note_missing")
}

#' Problems that gate a step of the 7-step flow (D5.2 §1.4)
#' @return data.frame(criterion, scenario, problem); "" where not cell-specific
impact_step_problems <- function(ia, step) {
  mk <- function(problem = character(), criterion = "", scenario = "") {
    data.frame(criterion = rep(criterion, length(problem)), scenario = rep(scenario, length(problem)),
               problem = problem, stringsAsFactors = FALSE)
  }
  codes <- impact_scenario_codes(ia)
  if (step == 2) {
    p <- character(0)
    if (length(codes) == 0) p <- c(p, "no_scenarios")
    if (length(codes) > IMPACT_MAX_SCENARIOS) p <- c(p, "too_many_scenarios")
    if (length(codes) > 0 && !ia$baseline_code %in% codes) p <- c(p, "baseline_missing")
    return(mk(p))
  }
  if (step == 3) {
    d <- ia$scope$displacement
    return(mk(if (identical(d$answer, "yes") && !nzchar(d$note)) "displacement_note_missing" else character(0)))
  }
  if (step == 4) {
    out <- mk()
    for (cr in WP5_CRITERIA$code) for (sc in codes) {
      out <- rbind(out, mk(impact_cell_problems(impact_get_cell(ia, cr, sc), cr), cr, sc))
    }
    return(out)
  }
  mk()
}

impact_can_advance <- function(ia, step) !any(impact_problem_blocks(impact_step_problems(ia, step)$problem))

# ---- displacement / leakage (audit A§8.4) ------------------------------------
#' @param displaced_pressure_id Optional ID of a P element created for the displaced
#'   pressure (spec WS-6 change 5; WS-6b creates the element)
impact_set_displacement <- function(ia, answer, note = "", displaced_pressure_id = "") {
  if (!(is.character(answer) && length(answer) == 1 && answer %in% IMPACT_DISPLACEMENT_ANSWERS)) {
    .impact_error("invalid_displacement_answer")
  }
  ia$scope$displacement <- list(answer = answer, note = .imp_str(note),
                                displaced_pressure_id = .imp_str(displaced_pressure_id))
  ia
}

impact_displacement_flagged <- function(ia) identical(ia$scope$displacement$answer, "yes")
```

In `global.R`, after `source("functions/impact_reference.R", local = FALSE)`, add:

```r
source("functions/impact_assessment_model.R", local = FALSE)
```

- [ ] **Step 5: Run the tests and confirm that they pass**

```bash
"C:/Program Files/R/R-4.4.1/bin/Rscript.exe" -e "testthat::test_file('tests/testthat/test-impact-assessment-model.R')"
"C:/Program Files/R/R-4.4.1/bin/Rscript.exe" -e "testthat::test_file('tests/testthat/test-functions-sourced-in-app.R')"
```

Expected: both pass.

- [ ] **Step 6: Commit**

```bash
git -C "C:/Users/arturas.baziukas/wt-ws6" add MarineSABRES_SES_Shiny/constants.R MarineSABRES_SES_Shiny/functions/impact_assessment_model.R MarineSABRES_SES_Shiny/global.R MarineSABRES_SES_Shiny/tests/testthat/test-impact-assessment-model.R
git -C "C:/Users/arturas.baziukas/wt-ws6" commit -m "feat(wp5): impact-assessment model: scenarios, ordinal cells, step problems, displacement check (WS-6a)"
```

---

### Task 4: Reference starters, copy-to-editable, mechanism and indicator linking

**Files:**
- Modify: `functions/impact_assessment_model.R` (append)
- Test: `tests/testthat/test-impact-assessment-model.R` (append)

**Interfaces:**
- Consumes: Task 2 getters; `get_mechanisms_for_da(da)` (each mechanism has `id`, `name`, `derived$scenario_applicability` = named list, or NULL for Tuscan/Macaronesia); `load_indicator_registry()$entries` (named by code; entries have `code`, `name`, `da`, `stub`, `criterion_roles[[EE]]$role`).
- Produces:
  - `impact_assessment_from_reference(da)` → assessment with the published scenarios (`source = "wp5_reference"`) and baseline; no cells
  - `impact_copy_reference_cell(ia, criterion, scenario_code, overwrite = FALSE)` → assessment; errors `no_da`, `no_reference_cell`, `cell_not_empty`, `unknown_scenario`
  - `impact_mechanism_options(da, scenario_code)` → `data.frame(id, name, applicability, applicability_text)`, every DA mechanism, sorted; `NA` applicability where D5.2 says nothing for the scenario
  - `impact_indicator_suggestions(criterion, da)` → `data.frame(code, name, role, stub)`, primary first

- [ ] **Step 1: Append the failing tests**

Append to `tests/testthat/test-impact-assessment-model.R`:

```r
load_wp5_mechanisms_kb(file.path(PROJECT_ROOT, "data", "ses_knowledge_db_wp5_mechanisms.json"),
                       force_reload = TRUE)
load_impact_reference(file.path(PROJECT_ROOT, "data", "wp5_impact_reference.json"), force_reload = TRUE)

test_that("reference starters: Macaronesia S1-S4 with S1 baseline, Arctic 3, Tuscan none", {
  mac <- impact_assessment_from_reference("macaronesia")
  expect_identical(impact_scenario_codes(mac), paste0("S", 1:4))
  expect_identical(mac$baseline_code, "S1")
  expect_identical(mac$scenarios$S3$source, "wp5_reference")
  expect_identical(mac$scenarios$S4$ambition_rank, 4L)
  expect_identical(names(mac$cells), character(0))          # reference cells stay read-only
  arc <- impact_assessment_from_reference("arctic")
  expect_identical(impact_scenario_codes(arc), c("no_agreement", "partial_agreement", "full_agreement"))
  expect_identical(arc$baseline_code, "partial_agreement")
  tus <- impact_assessment_from_reference("tuscan")
  expect_identical(tus$da, "tuscan")
  expect_identical(impact_scenario_codes(tus), character(0))
  expect_identical(impact_step_problems(tus, 2)$problem, "no_scenarios")
})

test_that("copying a reference cell: text, single-level confidence only, provenance", {
  ia <- impact_assessment_from_reference("macaronesia")
  ia <- impact_copy_reference_cell(ia, "EE", "S3")
  cl <- impact_get_cell(ia, "EE", "S3")
  expect_true(startsWith(cl$rationale, "Clear ecological gains"))
  expect_identical(cl$confidence, "medium")                  # S3 = Medium
  expect_identical(cl$direction, "")                         # D5.2 gives text, not a direction
  expect_identical(cl$reference, list(da = "macaronesia", table = "Table 21", criterion = "EE", scenario = "S3",
                                      provenance = "wp5_source", ref_version = "1.0.0"))
  ia <- impact_copy_reference_cell(ia, "EE", "S2")
  expect_identical(impact_get_cell(ia, "EE", "S2")$confidence, "")   # S2 = Medium–High: user decides
  arc <- impact_copy_reference_cell(impact_assessment_from_reference("arctic"), "PI", "no_agreement")
  expect_identical(impact_get_cell(arc, "PI", "no_agreement")$rationale,
                   "High — Politically easy to maintain; avoids difficult compromises; risks overfishing and continued certification loss.")
})

test_that("copy guards: no reference cell, edited cell, no DA, missing reference file", {
  err <- function(expr) tryCatch({ expr; NA_character_ }, impact_error = function(e) e$code)
  arc <- impact_assessment_from_reference("arctic")
  expect_identical(err(impact_copy_reference_cell(arc, "EE", "full_agreement")), "no_reference_cell")
  ia <- impact_assessment_from_reference("macaronesia")
  edited <- new_impact_cell(); edited$rationale <- "my own view"
  ia <- impact_set_cell(ia, "EC", "S1", edited)
  expect_identical(err(impact_copy_reference_cell(ia, "EC", "S1")), "cell_not_empty")
  ia <- impact_copy_reference_cell(ia, "EC", "S1", overwrite = TRUE)
  expect_true(startsWith(impact_get_cell(ia, "EC", "S1")$rationale, "High short-term efficiency"))
  expect_identical(err(impact_copy_reference_cell(new_impact_assessment(), "EE", "S1")), "no_da")
  suppressWarnings(load_impact_reference(tempfile(fileext = ".json"), force_reload = TRUE))
  starter <- impact_assessment_from_reference("macaronesia")
  expect_identical(starter$da, "macaronesia")
  expect_identical(impact_scenario_codes(starter), character(0))
  load_impact_reference(file.path(PROJECT_ROOT, "data", "wp5_impact_reference.json"), force_reload = TRUE)
})

test_that("mechanism options annotate and sort by WS-2 applicability; nothing is hidden", {
  no <- impact_mechanism_options("arctic", "no_agreement")
  expect_identical(nrow(no), 8L)
  expect_identical(names(no), c("id", "name", "applicability", "applicability_text"))
  expect_identical(no$id[1], "arc_02")                                  # essential first
  expect_identical(no$applicability[no$id == "arc_04"], "fragmented")
  expect_identical(no$id[nrow(no)], "arc_04")                           # fragmented last
  expect_true(is.na(no$applicability[no$id == "arc_03"]))               # "Most effective under Full": silent on No
  expect_identical(no$applicability_text[no$id == "arc_03"], "Most effective under Full Agreement")
  full <- impact_mechanism_options("arctic", "full_agreement")
  expect_identical(nrow(full), 8L)
  expect_false(anyNA(full$applicability))
  mine <- impact_mechanism_options("arctic", "quota_swap")              # user-defined scenario
  expect_identical(nrow(mine), 8L)
  expect_true(all(is.na(mine$applicability)))
  mac <- impact_mechanism_options("macaronesia", "S2")                  # no applicability map in D5.2
  expect_identical(nrow(mac), length(get_mechanisms_for_da("macaronesia")))
  expect_true(all(is.na(mac$applicability)))
})

test_that("indicator suggestions use WS-4 criterion roles, primary first, for every criterion", {
  for (cr in WP5_CRITERIA$code) {
    s <- impact_indicator_suggestions(cr, "macaronesia")               # EC/EQ include null-role citations
    expect_identical(names(s), c("code", "name", "role", "stub"), info = cr)
    expect_true(all(s$role %in% WP5_RUBRIC$indicator_role), info = cr)
    expect_false(is.unsorted(match(s$role, WP5_RUBRIC$indicator_role)), info = cr)
  }
  s <- impact_indicator_suggestions("EE", "macaronesia")
  expect_identical(s$role[s$code == "C_01"], "primary")
  expect_false("C_02" %in% impact_indicator_suggestions("EC", "macaronesia")$code)   # role: null
  expect_identical(nrow(impact_indicator_suggestions("EE", "tuscan")), 0L)
})
```

- [ ] **Step 2: Run them and confirm that they fail**

Run: `"C:/Program Files/R/R-4.4.1/bin/Rscript.exe" -e "testthat::test_file('tests/testthat/test-impact-assessment-model.R')"`
Expected: the new tests FAIL with `could not find function "impact_assessment_from_reference"`; the Task 3 tests still pass.

- [ ] **Step 3: Implement**

Append to `functions/impact_assessment_model.R`:

```r
# ---- WP5 reference starters (spec WS-6 change 3) -----------------------------
#' A new assessment pre-filled with the DA's published scenarios and baseline
#' (no cells: reference cells stay read-only until copied)
impact_assessment_from_reference <- function(da) {
  ia <- new_impact_assessment(da)
  for (s in impact_reference_scenarios(da)) {
    ia <- impact_add_scenario(ia, new_impact_scenario(s$code, s$name, ambition_rank = s$ambition_rank,
                                                      source = "wp5_reference"))
  }
  b <- impact_reference_baseline(da)
  if (nzchar(b) && b %in% impact_scenario_codes(ia)) ia$baseline_code <- b
  ia
}

#' Copy a read-only WP5 reference cell into the editable assessment.
#' Table 21 states one confidence per scenario; it is copied only when it is a
#' single level (a published range such as Medium–High leaves the choice to
#' the user). Direction, magnitude and timing stay empty: D5.2 gives text.
impact_copy_reference_cell <- function(ia, criterion, scenario_code, overwrite = FALSE) {
  cr <- .impact_criterion(criterion)
  if (!nzchar(ia$da)) .impact_error("no_da")
  ref <- impact_reference_cell(ia$da, cr, scenario_code)
  if (is.null(ref)) .impact_error("no_reference_cell")
  if (!overwrite && !identical(impact_get_cell(ia, cr, scenario_code), new_impact_cell())) {
    .impact_error("cell_not_empty")
  }
  sc <- Find(function(s) identical(s$code, scenario_code), impact_reference_scenarios(ia$da))
  conf <- sc$confidence_codes %||% character(0)
  cell <- new_impact_cell()
  cell$rationale <- if (nzchar(ref$rating_text)) paste0(ref$rating_text, " — ", ref$text) else ref$text
  cell$confidence <- if (length(conf) == 1) conf else ""
  # P5 snapshot: provenance + reference version, so later corrections are detectable
  cell$reference <- list(da = ia$da, table = ref$table, criterion = cr, scenario = scenario_code,
                         provenance = ref$provenance, ref_version = impact_reference_version())
  impact_set_cell(ia, cr, scenario_code, cell)
}

# ---- linking helpers (spec WS-6 change 4) ------------------------------------
#' All mechanisms of a DA for a scenario, annotated and sorted by WS-2
#' scenario_applicability. Nothing is hidden: D5.2 Table 9 often names only the
#' scenario where a mechanism is strongest, which is not a statement that it is
#' inapplicable elsewhere. applicability is NA where D5.2 says nothing for this
#' scenario (always for Tuscan/Macaronesia and for user-defined scenarios).
#' Order: essential, most_effective, applicable, complementary, not stated, fragmented.
impact_mechanism_options <- function(da, scenario_code) {
  empty <- data.frame(id = character(), name = character(), applicability = character(),
                      applicability_text = character(), stringsAsFactors = FALSE)
  rows <- lapply(get_mechanisms_for_da(da), function(m) {
    v <- m[["derived"]][["scenario_applicability"]][[scenario_code]]
    data.frame(id = m$id, name = m$name,
               applicability = if (is.null(v)) NA_character_ else as.character(v),
               applicability_text = .imp_str(m[["applicability_text"]]), stringsAsFactors = FALSE)
  })
  out <- do.call(rbind, c(list(empty), rows))
  rank <- match(out$applicability, c("essential", "most_effective", "applicable", "complementary"))
  rank[is.na(out$applicability)] <- 5L
  rank[is.na(rank)] <- 6L                          # fragmented (or any unknown code) last
  out <- out[order(rank), , drop = FALSE]
  rownames(out) <- NULL
  out
}

#' Registry indicators with a role for this criterion in this DA (WS-4
#' criterion_roles), primary before supporting
impact_indicator_suggestions <- function(criterion, da) {
  cr <- .impact_criterion(criterion)
  empty <- data.frame(code = character(), name = character(), role = character(), stub = logical(),
                      stringsAsFactors = FALSE)
  entries <- load_indicator_registry()$entries %||% list()
  rows <- lapply(entries, function(e) {
    # Some fiche citations carry only role_text ("role": null), e.g. C_02 EC/EQ: no suggestion
    role <- .imp_str(e[["criterion_roles"]][[cr]][["role"]])
    if (!identical(e$da, da) || !role %in% WP5_RUBRIC$indicator_role) return(NULL)
    data.frame(code = e$code, name = e$name, role = role, stub = isTRUE(e$stub),
               stringsAsFactors = FALSE)
  })
  out <- do.call(rbind, c(list(empty), rows))
  out <- out[order(match(out$role, WP5_RUBRIC$indicator_role)), , drop = FALSE]
  rownames(out) <- NULL
  out
}
```

- [ ] **Step 4: Run the tests and confirm that they pass**

Run: `"C:/Program Files/R/R-4.4.1/bin/Rscript.exe" -e "testthat::test_file('tests/testthat/test-impact-assessment-model.R')"`
Expected: all pass.

- [ ] **Step 5: Commit**

```bash
git -C "C:/Users/arturas.baziukas/wt-ws6" add MarineSABRES_SES_Shiny/functions/impact_assessment_model.R MarineSABRES_SES_Shiny/tests/testthat/test-impact-assessment-model.R
git -C "C:/Users/arturas.baziukas/wt-ws6" commit -m "feat(wp5): impact-assessment reference starters, copy-to-editable, mechanism and indicator linking (WS-6a)"
```

---

### Task 5: Storage, normaliser and round trips

**Files:**
- Modify: `functions/impact_assessment_model.R` (append)
- Modify: `functions/data_structure.R` (`normalize_json_project_data`, directly after `data <- migrate_legacy_scenarios(data)`)
- Create: `tests/testthat/fixtures/project_1_21_1_minimal.json`
- Test: `tests/testthat/test-impact-assessment-storage.R` (create) and `tests/testthat/test-json-project-loading.R` (append the WS-6 block)

**Interfaces:**
- Consumes: Task 3/4 functions; `stamp_min_app_version()` (functions/data_structure.R:1193); `export_project_json()` (functions/export_functions.R:262); `normalize_json_project_data()`; `create_empty_project()`.
- Produces:
  - `get_impact_assessment(project)` → canonical assessment or NULL
  - `set_impact_assessment(project, ia)` → project with the block (normalised) and `min_app_version` ≥ 1.25.0; `ia = NULL` removes the block without stamping
  - `normalize_impact_assessment(x)` → canonical assessment or NULL; idempotent on canonical input

- [ ] **Step 1: Create the fixture**

Create `tests/testthat/fixtures/project_1_21_1_minimal.json` (hand-authored; see decision 3):

```json
{
  "project_id": "PROJ_FIXTURE_1_21_1",
  "project_name": "Fixture project saved by 1.21.1",
  "created_at": "2026-10-11 12:00:00",
  "last_modified": "2026-10-11 12:00:00",
  "user": "fixture",
  "version": "1.21.1",
  "min_app_version": "1.12.0",
  "data": {
    "metadata": {"da_site": "macaronesia", "focal_issue": "Migratory corridor"},
    "analysis": {"scenarios": []}
  }
}
```

- [ ] **Step 2: Write the failing test**

Create `tests/testthat/test-impact-assessment-storage.R`:

```r
# tests/testthat/test-impact-assessment-storage.R
# WS-6a: data$analysis$impact_assessment survives every load path unchanged.
library(testthat)

load_wp5_mechanisms_kb(file.path(PROJECT_ROOT, "data", "ses_knowledge_db_wp5_mechanisms.json"),
                       force_reload = TRUE)
load_impact_reference(file.path(PROJECT_ROOT, "data", "wp5_impact_reference.json"), force_reload = TRUE)

build_ia <- function() {
  ia <- impact_assessment_from_reference("macaronesia")
  ia <- impact_copy_reference_cell(ia, "EE", "S3")
  cl <- impact_get_cell(ia, "EQ", "S4")
  cl$direction <- "increase"; cl$magnitude <- "substantial"; cl$timing <- "long"
  cl$confidence <- "low"; cl$uncertainty_driver <- "implementation_dependency"
  cl$evidence <- c("literature", "stakeholder")
  cl$rationale <- "Needs compensation – €0.25–1m/yr band"
  cl$subdimension_notes <- list(distributional = "Small islands", recognitional = "")
  cl$indicator_roles <- list(C_01 = "primary", T_01 = "supporting")
  cl$mechanism_ids <- "mac_01"
  ia <- impact_set_cell(ia, "EQ", "S4", cl)
  one <- new_impact_cell(); one$evidence <- "dataset"; one$direction <- "no_change"
  ia <- impact_set_cell(ia, "FF", "S2", one)                 # length-1 arrays are unboxed by toJSON
  ia <- impact_set_section(ia, "characterisation", list(focal_issue = "Migratory corridor", stakeholders = "Fishers; tour operators"))
  ia <- impact_set_section(ia, "uncertainty", list(notes = "Compliance in ABNJ"))
  ia <- impact_set_section(ia, "trade_offs", list(text = "S4: equity vs cost"))
  ia <- impact_set_section(ia, "recommendations", list(text = "Pilot S3 first"))
  ia <- impact_set_scope_items(ia, element_ids = c("P001", "C003"), indicator_codes = "C_01")
  impact_set_displacement(ia, "yes", "Effort may move to ABNJ waters", displaced_pressure_id = "P012")
}
project_with_ia <- function() set_impact_assessment(create_empty_project("WS-6a round trip"), build_ia())

test_that("set stamps min_app_version 1.25.0 and never lowers it; NULL removes without stamping", {
  p <- project_with_ia()
  expect_identical(p$min_app_version, WP5_IMPACT_MIN_APP_VERSION)
  newer <- create_empty_project("newer"); newer$min_app_version <- "9.0.0"
  expect_identical(set_impact_assessment(newer, build_ia())$min_app_version, "9.0.0")
  plain <- create_empty_project("plain")
  cleared <- set_impact_assessment(plain, NULL)
  expect_null(get_impact_assessment(cleared))
  expect_identical(cleared$min_app_version, plain$min_app_version)
})

test_that("the normaliser is idempotent on the canonical form", {
  ia <- build_ia()
  expect_identical(normalize_impact_assessment(ia), ia)
})

test_that(".json load (simplifyVector = TRUE) round-trips exactly", {
  p <- project_with_ia()
  f <- tempfile(fileext = ".json")
  export_project_json(p, f)
  out <- normalize_json_project_data(jsonlite::fromJSON(f, simplifyVector = TRUE))
  expect_identical(get_impact_assessment(out), get_impact_assessment(p))
  expect_identical(out$min_app_version, WP5_IMPACT_MIN_APP_VERSION)
})

test_that("local-storage / language-switch load (simplifyVector = FALSE) round-trips exactly", {
  p <- project_with_ia()
  f <- tempfile(fileext = ".json")
  export_project_json(p, f)
  out <- normalize_json_project_data(jsonlite::fromJSON(f, simplifyVector = FALSE))
  expect_identical(get_impact_assessment(out), get_impact_assessment(p))
})

test_that(".rds save/load round-trips exactly", {
  p <- project_with_ia()
  f <- tempfile(fileext = ".rds")
  saveRDS(p, f)
  out <- normalize_json_project_data(readRDS(f))
  expect_identical(get_impact_assessment(out), get_impact_assessment(p))
})

test_that("an older project (1.21.1 fixture) loads unchanged and can gain an assessment", {
  fx <- test_path("fixtures", "project_1_21_1_minimal.json")
  old <- normalize_json_project_data(jsonlite::fromJSON(fx, simplifyVector = TRUE))
  expect_null(get_impact_assessment(old))
  expect_identical(old$version, "1.21.1")
  expect_identical(old$min_app_version, "1.12.0")
  upd <- set_impact_assessment(old, build_ia())
  f <- tempfile(fileext = ".json")
  export_project_json(upd, f)
  back <- normalize_json_project_data(jsonlite::fromJSON(f, simplifyVector = TRUE))
  expect_identical(get_impact_assessment(back), build_ia())
  expect_identical(back$min_app_version, WP5_IMPACT_MIN_APP_VERSION)
})

test_that("orphan cells are dropped and aliases resolve on load", {
  raw <- build_ia()
  raw$cells$EE$S9 <- raw$cells$EE$S3                         # scenario S9 does not exist
  raw$cells$PO <- raw$cells$EQ; raw$cells$EQ <- NULL          # alias key from fiche-derived data
  out <- normalize_impact_assessment(raw)
  expect_identical(names(out$cells$EE), "S3")
  expect_true("PI" %in% names(out$cells))
  expect_false("PO" %in% names(out$cells))
})

test_that("a malformed block is dropped and the project still loads", {
  for (bad in list("oops", 42, list(1, 2))) {
    p <- create_empty_project("bad")
    p$data$analysis$impact_assessment <- bad
    out <- normalize_json_project_data(p)
    expect_null(get_impact_assessment(out))
    expect_identical(out$project_name, "bad")
  }
  expect_identical(normalize_impact_assessment(list(da = "baltic", baseline_code = "S1"))$da, "")
})

test_that("a malformed field inside a valid block drops only that field", {
  for (bad_scope in list("x", 5, list(displacement = "yes"))) {
    p <- project_with_ia()
    p$data$analysis$impact_assessment$scope <- bad_scope
    out <- normalize_json_project_data(p)
    ia <- get_impact_assessment(out)
    expect_false(is.null(ia))
    expect_identical(ia$scope$displacement$answer, "")
    expect_identical(ia$scope$element_ids, character(0))
    expect_identical(impact_scenario_codes(ia), paste0("S", 1:4))   # the rest survives
  }
  p <- project_with_ia()
  p$data$analysis$impact_assessment$characterisation <- "not a section"
  p$data$analysis$impact_assessment$cells$EQ$S4$subdimension_notes <- "loose text"
  ia <- get_impact_assessment(normalize_json_project_data(p))
  expect_identical(ia$characterisation$focal_issue, "")
  expect_identical(ia$cells$EQ$S4$subdimension_notes, setNames(list(), character(0)))
  expect_identical(ia$cells$EQ$S4$direction, "increase")
})
```

Also append a WS-6 block to `tests/testthat/test-json-project-loading.R` (spec P7: every new project-data block gets its round trip in this file, which `tests/run_json_loading_tests.R` also runs). Follow the WS-4 block at the end of that file:

```r
# ============================================================================
# WS-6a (P7): data$analysis$impact_assessment survives JSON and RDS round trips
# ============================================================================
if (!exists("normalize_impact_assessment", mode = "function")) {
  source(file.path(project_root, "functions", "impact_reference.R"), local = FALSE)
  source(file.path(project_root, "functions", "impact_assessment_model.R"), local = FALSE)
}

ws6_project <- function() {
  ia <- new_impact_assessment("arctic")
  ia <- impact_add_scenario(ia, new_impact_scenario("no_agreement", "No Agreement"))
  ia <- impact_add_scenario(ia, new_impact_scenario("full_agreement", "Full Agreement", ambition_rank = 2L))
  ia <- impact_set_baseline(ia, "no_agreement")
  cl <- new_impact_cell()
  cl$direction <- "decrease"; cl$confidence <- "low"; cl$uncertainty_driver <- "contested_assumption"
  cl$evidence <- "dataset"; cl$subdimension_notes <- list(credibility = "Quota claims – contested")
  cl$indicator_roles <- list(ARC_TAC_VS_ADVICE = "primary"); cl$mechanism_ids <- c("arc_02", "arc_06")
  ia <- impact_set_cell(ia, "PI", "full_agreement", cl)
  ia <- impact_set_section(ia, "recommendations", list(text = "Seek a sharing arrangement"))
  set_impact_assessment(list(project_id = "p_ws6", data = list(analysis = list())), ia)
}

test_that("WS-6a impact assessment survives JSON (both simplify modes) and RDS round trips", {
  p <- ws6_project()
  js <- jsonlite::toJSON(p, auto_unbox = TRUE, null = "null", na = "null")
  for (sv in c(TRUE, FALSE)) {
    pd <- normalize_json_project_data(jsonlite::fromJSON(js, simplifyVector = sv))
    expect_identical(pd$data$analysis$impact_assessment, p$data$analysis$impact_assessment,
                     info = sprintf("simplifyVector=%s", sv))
  }
  f <- tempfile(fileext = ".rds")
  saveRDS(p, f)
  expect_identical(normalize_json_project_data(readRDS(f))$data$analysis$impact_assessment,
                   p$data$analysis$impact_assessment)
})
```

`stamp_min_app_version()` treats a missing `min_app_version` as lower than any version, so `set_impact_assessment()` works on this minimal project list.

- [ ] **Step 3: Run them and confirm that they fail**

```bash
"C:/Program Files/R/R-4.4.1/bin/Rscript.exe" -e "testthat::test_file('tests/testthat/test-impact-assessment-storage.R')"
"C:/Program Files/R/R-4.4.1/bin/Rscript.exe" -e "testthat::test_file('tests/testthat/test-json-project-loading.R')"
```

Expected: both FAIL with `could not find function "set_impact_assessment"` (in the loading file only the new WS-6 test fails; the model files from Tasks 3-4 already exist).

- [ ] **Step 4: Implement storage and the normaliser**

Append to `functions/impact_assessment_model.R`:

```r
# ---- storage (spec WS-6 change 7) --------------------------------------------
get_impact_assessment <- function(project) {
  if (!is.list(project) || !is.list(project$data) || !is.list(project$data$analysis)) return(NULL)
  project$data$analysis[["impact_assessment"]]
}

#' Store the assessment; stamps min_app_version (never lowers). NULL removes it.
set_impact_assessment <- function(project, ia) {
  if (!is.list(project$data$analysis)) project$data$analysis <- list()
  if (is.null(ia)) {
    project$data$analysis$impact_assessment <- NULL
    return(project)
  }
  project$data$analysis$impact_assessment <- normalize_impact_assessment(ia)
  stamp_min_app_version(project, WP5_IMPACT_MIN_APP_VERSION)
}

#' Canonical impact-assessment block from any load path, or NULL if malformed.
#' Converts through JSON with simplifyVector = FALSE first, so data frames from
#' a simplifyVector = TRUE load become plain lists. Drops cells whose scenario
#' does not exist and maps criterion aliases (PO -> PI, FI -> FF).
normalize_impact_assessment <- function(x) {
  if (is.null(x)) return(NULL)
  x <- tryCatch(
    jsonlite::fromJSON(jsonlite::toJSON(x, auto_unbox = TRUE, null = "null", na = "null", digits = NA),
                       simplifyVector = FALSE),
    error = function(e) NULL)
  if (!is.list(x) || is.null(names(x))) {
    if (exists("debug_log", mode = "function")) debug_log("impact_assessment block malformed; dropped", "WP5")
    return(NULL)
  }
  # Any field-level surprise drops the block, never the project load
  tryCatch(.impact_normalize_body(x), error = function(e) {
    if (exists("debug_log", mode = "function")) {
      debug_log(paste("impact_assessment block dropped:", conditionMessage(e)), "WP5")
    }
    NULL
  })
}

.impact_normalize_body <- function(x) {
  da <- .imp_str(x[["da"]])
  if (!da %in% c("", WP5_DA_CONTEXTS)) da <- ""

  scenarios <- .imp_empty_named()
  for (s in if (is.list(x[["scenarios"]])) x[["scenarios"]] else list()) {
    if (!is.list(s)) next
    sc <- .impact_fill_scenario(s)
    if (!.impact_valid_code(sc$code) || sc$code %in% names(scenarios)) next
    if (length(scenarios) >= IMPACT_MAX_SCENARIOS) break
    scenarios[[sc$code]] <- sc
  }

  cells <- .imp_empty_named()
  xc <- x[["cells"]]
  if (is.list(xc) && !is.null(names(xc))) {
    for (raw_cr in names(xc)) {
      cr <- wp5_criterion_code(raw_cr)
      row <- xc[[raw_cr]]
      if (is.na(cr) || cr %in% names(cells) || !is.list(row) || is.null(names(row))) next
      kept <- .imp_empty_named()
      for (sc in names(row)) if (sc %in% names(scenarios)) kept[[sc]] <- .impact_fill_cell(row[[sc]])
      if (length(kept) > 0) cells[[cr]] <- kept
    }
  }

  baseline <- .imp_str(x[["baseline_code"]])
  if (!baseline %in% names(scenarios)) baseline <- ""
  sec <- function(s) .impact_fill_section(if (is.list(x[[s]])) x[[s]] else list(), IMPACT_TEXT_SECTIONS[[s]])

  # Same field order as new_impact_assessment(), so identical() holds after a round trip
  list(schema = IMPACT_SCHEMA_VERSION, da = da,
       characterisation = sec("characterisation"),
       baseline_code = baseline,
       scenarios = scenarios,
       scope = .impact_fill_scope(x[["scope"]]),            # guards non-list scope/displacement
       cells = cells,
       uncertainty = sec("uncertainty"),
       trade_offs = sec("trade_offs"),
       recommendations = sec("recommendations"))
}
```

In `functions/data_structure.R`, inside `normalize_json_project_data()`, directly after `data <- migrate_legacy_scenarios(data)`, add:

```r
  # WP5 impact assessment (WS-6a): canonical block on every JSON/RDS load path
  # (tryCatch: a bug in the normaliser must drop the block, not fail the project load)
  if (is.list(data$data) && is.list(data$data$analysis) &&
      !is.null(data$data$analysis$impact_assessment) &&
      exists("normalize_impact_assessment", mode = "function")) {
    data$data$analysis$impact_assessment <- tryCatch(
      normalize_impact_assessment(data$data$analysis$impact_assessment),
      error = function(e) {
        debug_log(paste("impact_assessment dropped on load:", conditionMessage(e)), "WP5")
        NULL
      })
  }
```

- [ ] **Step 5: Run the tests and confirm that they pass**

```bash
"C:/Program Files/R/R-4.4.1/bin/Rscript.exe" -e "testthat::test_file('tests/testthat/test-impact-assessment-storage.R')"
"C:/Program Files/R/R-4.4.1/bin/Rscript.exe" -e "testthat::test_file('tests/testthat/test-json-project-loading.R')"
"C:/Program Files/R/R-4.4.1/bin/Rscript.exe" -e "testthat::test_file('tests/testthat/test-data-structure.R')"
```

Expected: all pass. If the fixture test errors inside `normalize_json_project_data()` (for example because it expects an `isa_data` block), add the missing empty block to the fixture the way `create_empty_project()` declares it. Keep `version` at 1.21.1 and keep the test strict. If the `.json` round trip differs only in one field, print `str()` of both values and fix the normaliser's coercion for that field (for example, a length-1 `evidence` read back as a scalar). Do not weaken `expect_identical`.

- [ ] **Step 6: Commit**

```bash
git -C "C:/Users/arturas.baziukas/wt-ws6" add MarineSABRES_SES_Shiny/functions/impact_assessment_model.R MarineSABRES_SES_Shiny/functions/data_structure.R MarineSABRES_SES_Shiny/tests/testthat/test-impact-assessment-storage.R MarineSABRES_SES_Shiny/tests/testthat/test-json-project-loading.R MarineSABRES_SES_Shiny/tests/testthat/fixtures/project_1_21_1_minimal.json
git -C "C:/Users/arturas.baziukas/wt-ws6" commit -m "feat(wp5): impact-assessment storage with min_app_version stamp and loss-free JSON/RDS round trip (WS-6a)"
```

---

### Task 6: Changelog and full verification

**Files:**
- Modify: `CHANGELOG.md` (under `## [Unreleased]`)

**Interfaces:**
- Consumes: everything above.
- Produces: a branch ready for review and merge.

- [ ] **Step 1: Add the changelog entry**

Under `## [Unreleased]` in `CHANGELOG.md`, add:

```markdown
### Added (WP5 impact assessment, data layer — spec 2026-10-11 WS-6a)
- D5.2 reference data for the impact-assessment module (`data/wp5_impact_reference.json`): Macaronesia Table 21 (5 criteria × S1–S4, with each scenario's confidence) and Arctic Tables 2–8 (revenue by scenario for the Faroe Islands, Greenland and Iceland; political feasibility per scenario). Tests check every value against the committed D5.2 extract. The Arctic revenue values are stored exactly as published, with a note that they conflict with D5.2's stated assumptions (partner question 2). Tuscany has no scenarios in D5.2.
- The data model behind the module (no screens yet): ordinal criterion × scenario cells, up to 5 scenarios with a baseline, the rule that low confidence needs an uncertainty driver, the displacement/leakage check, copying a D5.2 reference cell into an editable cell, and mechanism and indicator suggestions per scenario and criterion. Assessments are stored at `data$analysis$impact_assessment` and survive `.json` and `.rds` save/load unchanged. Projects that contain one require 1.25.0.
```

- [ ] **Step 2: Run the i18n audit (no new user-facing strings expected)**

Run: `micromamba run -n shiny python scripts/_i18n_audit.py`
Expected: `missing=0`, `hardcoded=0`.

- [ ] **Step 3: Run the full suite in chunks**

A single full run is killed for low memory, so run each chunk in a fresh R process, in sequence:

```bash
for c in a-c d-h i-l m-r s-z; do
  "C:/Program Files/R/R-4.4.1/bin/Rscript.exe" -e "res <- testthat::test_dir('tests/testthat', filter = '^[$c]', reporter = 'summary', stop_on_failure = FALSE); df <- as.data.frame(res); cat('CHUNK', '$c', 'pass', sum(df\$passed), 'fail', sum(df\$failed), 'error', sum(df\$error), '\n')"
done
```

Expected: `fail 0 error 0` in every chunk. The known flaky ML timing test (`test-ml-graph-features.R`) may fail once; re-run that file alone before treating it as a regression. Any untracked `*safeBackup*` test file in `tests/testthat` is not part of the repo; delete it.

- [ ] **Step 4: Commit**

```bash
git -C "C:/Users/arturas.baziukas/wt-ws6" add MarineSABRES_SES_Shiny/CHANGELOG.md
git -C "C:/Users/arturas.baziukas/wt-ws6" commit -m "docs(changelog): WP5 impact-assessment data layer (WS-6a)"
```
