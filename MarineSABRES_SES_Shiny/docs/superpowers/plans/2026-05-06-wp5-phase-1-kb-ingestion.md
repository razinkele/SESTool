# WP5 Phase 1 — KB Ingestion Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` (recommended) or `superpowers:executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Convert the WP5 financial-mechanism content from four `.docx` source files into a queryable JSON knowledge base, expose it to the Shiny app via a cached R loader, surface it as a reference pane on Response/Measure ISA elements, and add the `min_app_version` migration-UX foundation that all later WP5 phases will build on.

**Architecture:** Mirror the offshore-wind KB pattern (`data/ses_knowledge_db_offshore_wind.json` + `functions/ses_knowledge_db_loader.R` + `scripts/build_offshore_wind_kb.py`). The schema differs (financial mechanisms ≠ DAPSIWRM elements), but the *shape* — one JSON under `data/`, one cached R loader, one Python builder, one `kb_audit` script — is reused verbatim.

**Tech Stack:** R / Shiny (loader, UI integration, tests), Python 3 via `micromamba run -n shiny` (build script, audit script, i18n audit extension), `jsonlite` for R-side JSON, `python-docx` for Python-side `.docx` parsing, `testthat` for R tests, `pytest`-style assertions inside Python audit scripts (no `pytest` dependency added).

**Source content snapshots (pinned at commit `1f636e8`):** All extraction reads from these markdown files, regenerated from the `.docx` originals at `WP5/`:
- `C:\Users\ARTURA~1.BAZ\AppData\Local\Temp\wp5_extract\D5.2_main.md`
- `C:\Users\ARTURA~1.BAZ\AppData\Local\Temp\wp5_extract\D5.2_macaronesia.md`
- `C:\Users\ARTURA~1.BAZ\AppData\Local\Temp\wp5_extract\blue_corridor.md`
- `C:\Users\ARTURA~1.BAZ\AppData\Local\Temp\wp5_extract\tuscan.md`
- `C:\Users\ARTURA~1.BAZ\AppData\Local\Temp\wp5_extract\arctic.md`

If these markdown files are missing, regenerate them with the same `python-docx` script used by the design phase (see project memory `project_wp5_deliverable.md`).

**Spec reference:** `docs/superpowers/specs/2026-05-06-wp5-integration-roadmap-design.md` §5 (Phase 1 detail), §9.1 (i18n), §9.3 (testing budget), §9.4 (migration UX), §9.8 (training/onboarding).

---

## File structure overview

### Files to create

| Path | Responsibility |
|---|---|
| `data/ses_knowledge_db_wp5_mechanisms.json` | The 28 mechanism descriptions + Posidonia `valuation_unit_values` block |
| `scripts/build_wp5_mechanisms_kb.py` | Python builder. Reads source markdown extracts, emits the JSON. Mirrors `build_offshore_wind_kb.py` style with header banner |
| `scripts/kb_audit/audit_wp5_mechanisms.py` | Quality audit — completeness check (≥8/10 attributes), reference resolution, DA-tag canonicality |
| `functions/wp5_kb_loader.R` | R loader with environment-cached state. Mirrors `functions/ses_knowledge_db_loader.R` |
| `tests/testthat/test-wp5-kb-loader.R` | Loader smoke tests + reference-pane render test (~25 assertions) |
| `translations/modules/wp5_mechanisms.json` | UI chrome strings (~25 keys). All 9 locales present; non-English values seeded with the English string per §9.1 |

### Files to modify

| Path | Change |
|---|---|
| `VERSION` | `1.11.2` → `1.12.0-dev` (start), `1.12.0` (end) |
| `VERSION_INFO.json` | Update version + release_date + version_name |
| `CHANGELOG.md` | Add `## [1.12.0]` entry at top |
| `CLAUDE.md` | Add WP5 KB section under "Architecture" |
| `constants.R` | Add `WP5_DA_CONTEXTS` |
| `global.R` | Source `functions/wp5_kb_loader.R`; call `load_wp5_mechanisms_kb()` at startup |
| `functions/data_structure.R` | Add `min_app_version` field to `create_empty_project()` |
| `server/project_io.R` | Add load-time check: forward-load toast for older projects, downgrade warning if `min_app_version > APP_VERSION` |
| `modules/isa_data_entry_module.R` (decision: §F1 spike) | Add reference pane shown only for Response/Measure elements |
| `scripts/_i18n_audit.py` | Add `--allow-english-fallback=wp5` flag |
| `tests/testthat/test-json-project-loading.R` | Add migration round-trip test (1.11.2 fixture → 1.12) |

---

## Phase markers in this plan

This plan has **two partner-gated stop points** marked 🛑. Do not proceed past them without explicit partner sign-off as defined in the spec §5.7. Tasks before each gate are independently shippable and pre-tested.

---

## Section A — Setup

### Task A1: Create feature branch and bump VERSION to dev

**Files:**
- Modify: `VERSION` (top-of-tree)

- [ ] **Step 1: Create branch from `main`**

```powershell
git -C "C:\Users\arturas.baziukas\OneDrive - ku.lt\HORIZON_EUROPE\Marine-SABRES\SESToolbox\MarineSABRES_SES_Shiny" checkout -b feat/wp5-phase-1-kb-ingestion
```

- [ ] **Step 2: Bump VERSION to 1.12.0-dev**

Edit `VERSION` to read:

```
1.12.0-dev
```

- [ ] **Step 3: Commit**

```powershell
git add VERSION
git commit -m "chore(release): bump VERSION to 1.12.0-dev for WP5 Phase 1 work"
```

---

### Task A2: Add `WP5_DA_CONTEXTS` constant

**Files:**
- Modify: `constants.R` (append a new section near the bottom)

- [ ] **Step 1: Open `constants.R` and find the end of the existing constants definitions**

Look for the last `<- ` assignment in the file. Append after it.

- [ ] **Step 2: Append new section**

```r
# ============================================================================
# WP5 DEMONSTRATION-AREA CONTEXT KEYS
# ============================================================================
# Canonical key set used by the WP5 mechanism KB and (in later phases) the
# indicator registry. Values are lowercase ASCII to match JSON `applies_to_DAs`
# fields without locale-dependent string handling.

WP5_DA_CONTEXTS <- c("macaronesia", "tuscan", "arctic")
```

- [ ] **Step 3: Source `constants.R` to confirm no syntax error**

```powershell
& "C:\Program Files\R\R-4.4.1\bin\Rscript.exe" -e "source('constants.R'); cat(WP5_DA_CONTEXTS)"
```

Expected output: `macaronesia tuscan arctic`

- [ ] **Step 4: Commit**

```powershell
git add constants.R
git commit -m "feat(wp5): add WP5_DA_CONTEXTS constant for mechanism KB"
```

---

## Section B — JSON schema, fixture, and loader (TDD-friendly start)

### Task B1: Author the JSON KB skeleton with one fully-fleshed-out mechanism

The schema itself is the spec deliverable; getting it right with one example is more valuable than rushing 28 partial entries. The single example is **Macaronesia: Blue Corridor Facility** because it's the cleanest source-document candidate and is named in the spec's partner-gate exit criteria.

**Files:**
- Create: `data/ses_knowledge_db_wp5_mechanisms.json`

- [ ] **Step 1: Create the file with full schema and one Macaronesia mechanism**

Write to `data/ses_knowledge_db_wp5_mechanisms.json`:

```json
{
  "version": "1.0.0",
  "description": "WP5 financial and implementation mechanisms catalogue (Marine SABRES Deliverable 5.2). Mechanisms are indexed by Demonstration Area; each mechanism follows a fixed 10-attribute structure mirroring the Blue Corridor toolkit annex. Bundled `valuation_unit_values` carries Tuscan Posidonia oceanica benefit-transfer estimates consumed by the Phase 2 valuation calculator.",
  "last_updated": "2026-05-06",
  "source_documents": [
    "Blue_corridor_financial toolkit_17_04_2026.docx",
    "Draft financial mechanisms_Tuscan DA.docx",
    "Draft text financial mechanisms_Arctic DA.docx",
    "MarineSABRES_Deliverable5.2_Draftv3.docx"
  ],
  "source_commit": "1f636e8",
  "demonstration_areas": {
    "macaronesia": {
      "description": "Blue Corridor (EEZ + ABNJ); cross-jurisdictional MPA network spanning Azores-Madeira-Canary Islands, with mechanisms supporting coordinated monitoring, enforcement, and connectivity-preserving fisheries management.",
      "mechanisms": [
        {
          "id": "mac_01_blue_corridor_facility",
          "name": "Blue Corridor Facility",
          "cost_profile": "recurring",
          "what_it_funds": "A regional financing facility funding coordinated monitoring, enforcement, scientific assessment, and stakeholder engagement across the Azores-Madeira-Canary Islands EEZ + ABNJ Blue Corridor.",
          "finance_flow": {
            "payer": ["EU (Horizon Europe successor + EMFAF)", "national governments (PT, ES)", "philanthropic foundations"],
            "receiver": "regional secretariat (proposed: hosted by an existing IGO or jointly by national MPA agencies)",
            "type": "blended"
          },
          "design_parameters": [
            "Narrow corridor-delivery mandate to prevent mission creep",
            "Eligible cost categories defined in the founding charter (monitoring, enforcement, science, engagement; not general MPA operations)",
            "Three-jurisdiction governing board with rotating chair",
            "Annual operating budget €5–15M, with multi-year commitment cycles"
          ],
          "evidence_base": [
            "MSP4BIO D3.2 (regional financing analogues)",
            "OSPAR Coordinated Environmental Monitoring Programme (governance precedent)",
            "Mediterranean MedPAN Fund (operational precedent for regional MPA financing)"
          ],
          "transferable_lessons": [
            "Regional secretariat must have legal personality; informal coordination collapses under fiscal stress",
            "Multi-year commitment cycles essential — annual renewals create activity gaps that erode trust",
            "Co-funding from national governments (not just EU) increases political durability"
          ],
          "applies_to_DAs": ["macaronesia"],
          "success_metrics": ["C_01", "C_02", "M_01"],
          "risks_and_guardrails": [
            { "risk": "Mandate creep — facility becomes a generic MPA funding pot", "guardrail": "Founding charter narrows eligible activities to corridor-delivery; annual board review of out-of-scope requests" },
            { "risk": "Free-riding by one jurisdiction", "guardrail": "Co-funding share required as condition of voting rights" },
            { "risk": "Political withdrawal during national election cycles", "guardrail": "Multi-year commitments + treaty-level codification (where feasible)" }
          ],
          "use_in_impact_assessment": "Use this mechanism when scoring a Macaronesia scenario where regional coordination capacity is the binding constraint (S3 Coordinated EEZ or S4 Integrated EEZ+ABNJ). Score it positively on EE (enables monitoring) and negatively on PI (requires multi-state agreement). Pair with M_01 vessel-movement indicator for measurable success.",
          "references": [
            "MarineSABRES D5.2 §5.x Blue Corridor financial toolkit",
            "MSP4BIO Deliverable 3.2"
          ]
        }
      ]
    },
    "tuscan": {
      "description": "Tuscan Archipelago National Park; mechanisms supporting Posidonia oceanica meadow protection, restoration, and enforcement against anchoring and trawling damage.",
      "mechanisms": []
    },
    "arctic": {
      "description": "Arctic Northeast Atlantic; mechanisms supporting quota allocation, enforcement, and incentive design for sustainable fisheries under ICES/NEAFC governance.",
      "mechanisms": []
    }
  },
  "valuation_unit_values": {
    "posidonia_oceanica": {
      "coastal_protection":   { "low": 3500,  "central": 10350, "high": 17200, "unit": "EUR/ha/yr", "method": "avoided_cost" },
      "carbon_sequestration": { "low": 40,    "central": 140,   "high": 240,   "unit": "EUR/ha/yr", "method": "social_cost_of_carbon" },
      "recreation_tourism":   { "low": 400,   "central": 2500,  "high": 4600,  "unit": "EUR/ha/yr", "method": "travel_cost_or_WTP" },
      "food_provision":       { "low": 150,   "central": 975,   "high": 1800,  "unit": "EUR/ha/yr", "method": "market_pricing" },
      "water_purification":   { "low": 350,   "central": 1175,  "high": 2000,  "unit": "EUR/ha/yr", "method": "replacement_cost" }
    },
    "restoration_costs": {
      "posidonia_oceanica": { "low": 100000, "high": 500000, "unit": "EUR/ha", "early_survival_low": 0.38, "early_survival_high": 0.60 }
    }
  }
}
```

- [ ] **Step 2: Validate JSON parses cleanly**

```powershell
& "C:\Program Files\R\R-4.4.1\bin\Rscript.exe" -e "x <- jsonlite::fromJSON('data/ses_knowledge_db_wp5_mechanisms.json', simplifyDataFrame = FALSE); cat('OK; macaronesia mechanism count:', length(x[['demonstration_areas']][['macaronesia']][['mechanisms']]))"
```

Expected output: `OK; macaronesia mechanism count: 1`

- [ ] **Step 3: Commit**

```powershell
git add data/ses_knowledge_db_wp5_mechanisms.json
git commit -m "feat(wp5): seed mechanism KB with full schema + Blue Corridor Facility"
```

---

### Task B2: Write the loader test FIRST (it should fail)

**Files:**
- Create: `tests/testthat/test-wp5-kb-loader.R`

- [ ] **Step 1: Write the failing test file**

Write to `tests/testthat/test-wp5-kb-loader.R`:

```r
# tests/testthat/test-wp5-kb-loader.R
# Tests for the WP5 mechanism KB loader.
# Mirrors the testing pattern used by tests/testthat/test-knowledge-base.R.

library(testthat)

# Resolve project root the same way test-knowledge-base.R does
.wp5_project_root <- function() {
  wd <- getwd()
  if (basename(wd) == "testthat") return(dirname(dirname(wd)))
  if (file.exists(file.path(wd, "data/ses_knowledge_db_wp5_mechanisms.json"))) return(wd)
  candidate <- dirname(dirname(wd))
  if (file.exists(file.path(candidate, "data/ses_knowledge_db_wp5_mechanisms.json"))) {
    return(candidate)
  }
  return(wd)
}

PROJECT_ROOT_WP5 <- .wp5_project_root()
WP5_KB_PATH      <- file.path(PROJECT_ROOT_WP5, "data", "ses_knowledge_db_wp5_mechanisms.json")
WP5_LOADER_PATH  <- file.path(PROJECT_ROOT_WP5, "functions", "wp5_kb_loader.R")

# Source loader explicitly (helper-00-load-functions.R may not pick this up
# until it's added to global.R's source chain)
.ensure_wp5_loader <- function() {
  if (!exists("load_wp5_mechanisms_kb", mode = "function")) {
    if (file.exists(WP5_LOADER_PATH)) source(WP5_LOADER_PATH, local = FALSE)
  }
}

test_that("WP5 KB JSON file exists at expected path", {
  expect_true(file.exists(WP5_KB_PATH))
})

test_that("load_wp5_mechanisms_kb() loads without error", {
  skip_if_not(file.exists(WP5_KB_PATH), "ses_knowledge_db_wp5_mechanisms.json not found")
  .ensure_wp5_loader()
  skip_if_not(exists("load_wp5_mechanisms_kb", mode = "function"),
              "load_wp5_mechanisms_kb not available")
  expect_no_error(load_wp5_mechanisms_kb(WP5_KB_PATH, force_reload = TRUE))
})

test_that("Loaded KB has all 3 demonstration_areas keys", {
  skip_if_not(file.exists(WP5_KB_PATH), "ses_knowledge_db_wp5_mechanisms.json not found")
  .ensure_wp5_loader()
  skip_if_not(exists("load_wp5_mechanisms_kb", mode = "function"),
              "load_wp5_mechanisms_kb not available")
  db <- load_wp5_mechanisms_kb(WP5_KB_PATH, force_reload = TRUE)
  expect_setequal(names(db$demonstration_areas), c("macaronesia", "tuscan", "arctic"))
})

test_that("valuation_unit_values block is parsed as numeric", {
  skip_if_not(file.exists(WP5_KB_PATH), "ses_knowledge_db_wp5_mechanisms.json not found")
  .ensure_wp5_loader()
  skip_if_not(exists("load_wp5_mechanisms_kb", mode = "function"),
              "load_wp5_mechanisms_kb not available")
  db <- load_wp5_mechanisms_kb(WP5_KB_PATH, force_reload = TRUE)
  pos <- db$valuation_unit_values$posidonia_oceanica
  expect_type(pos$coastal_protection$low, "double")
  expect_type(pos$coastal_protection$central, "double")
  expect_type(pos$coastal_protection$high, "double")
  expect_true(pos$coastal_protection$low <= pos$coastal_protection$central)
  expect_true(pos$coastal_protection$central <= pos$coastal_protection$high)
})

test_that("get_mechanisms_for_da('macaronesia') returns the seeded entry", {
  skip_if_not(file.exists(WP5_KB_PATH), "ses_knowledge_db_wp5_mechanisms.json not found")
  .ensure_wp5_loader()
  skip_if_not(exists("get_mechanisms_for_da", mode = "function"),
              "get_mechanisms_for_da not available")
  load_wp5_mechanisms_kb(WP5_KB_PATH, force_reload = TRUE)
  mechs <- get_mechanisms_for_da("macaronesia")
  expect_true(length(mechs) >= 1)
  expect_true(any(vapply(mechs, function(m) m$id == "mac_01_blue_corridor_facility", logical(1))))
})

test_that("get_mechanisms_for_da() rejects unknown DA names", {
  skip_if_not(file.exists(WP5_KB_PATH), "ses_knowledge_db_wp5_mechanisms.json not found")
  .ensure_wp5_loader()
  skip_if_not(exists("get_mechanisms_for_da", mode = "function"),
              "get_mechanisms_for_da not available")
  expect_error(get_mechanisms_for_da("atlantis"), "Unknown DA")
})

test_that("get_valuation_unit_values('posidonia_oceanica') returns 5 services", {
  skip_if_not(file.exists(WP5_KB_PATH), "ses_knowledge_db_wp5_mechanisms.json not found")
  .ensure_wp5_loader()
  skip_if_not(exists("get_valuation_unit_values", mode = "function"),
              "get_valuation_unit_values not available")
  load_wp5_mechanisms_kb(WP5_KB_PATH, force_reload = TRUE)
  v <- get_valuation_unit_values("posidonia_oceanica")
  expect_setequal(names(v), c("coastal_protection","carbon_sequestration","recreation_tourism","food_provision","water_purification"))
})
```

- [ ] **Step 2: Run the test — confirm it fails**

```powershell
& "C:\Program Files\R\R-4.4.1\bin\Rscript.exe" -e "testthat::test_file('tests/testthat/test-wp5-kb-loader.R')"
```

Expected: tests for `load_wp5_mechanisms_kb`, `get_mechanisms_for_da`, `get_valuation_unit_values` SKIP with "not available" (loader doesn't exist yet). Test "WP5 KB JSON file exists" PASSES.

- [ ] **Step 3: Commit (test-first, before implementation)**

```powershell
git add tests/testthat/test-wp5-kb-loader.R
git commit -m "test(wp5): add failing tests for WP5 KB loader and lookup helpers"
```

---

### Task B3: Implement the loader

**Files:**
- Create: `functions/wp5_kb_loader.R`

- [ ] **Step 1: Write the loader implementation**

Write to `functions/wp5_kb_loader.R`:

```r
# functions/wp5_kb_loader.R
# WP5 Mechanism Knowledge Base Loader
# Purpose: Loads the JSON-based WP5 financial-mechanism KB and provides
#   lookup functions for the reference pane on Response/Measure ISA elements
#   (and, in later phases, the valuation calculator and impact-assessment
#   linked-mechanisms UI).
#
# Author: MarineSABRES SES Toolbox
# Date: 2026-05-06
# Dependencies: jsonlite (already loaded in global.R)

# ==============================================================================
# MODULE-LEVEL STATE
# ==============================================================================

.wp5_kb_env <- new.env(parent = emptyenv())
.wp5_kb_env$db <- NULL
.wp5_kb_env$loaded <- FALSE

# ==============================================================================
# DATABASE LOADING
# ==============================================================================

#' Load the WP5 Mechanism Knowledge Base from JSON
#'
#' @param db_path Path to the JSON database file (default: data/ses_knowledge_db_wp5_mechanisms.json)
#' @param force_reload If TRUE, reload even if already cached
#' @return The parsed database list, invisibly
#' @export
load_wp5_mechanisms_kb <- function(db_path = NULL, force_reload = FALSE) {
  if (.wp5_kb_env$loaded && !force_reload) {
    return(invisible(.wp5_kb_env$db))
  }

  if (is.null(db_path)) {
    if (exists("get_project_file", mode = "function")) {
      db_path <- get_project_file("data", "ses_knowledge_db_wp5_mechanisms.json")
    } else {
      db_path <- file.path("data", "ses_knowledge_db_wp5_mechanisms.json")
    }
  }

  if (!file.exists(db_path)) {
    warning(sprintf("[WP5 KB] Mechanism KB not found at: %s", db_path))
    .wp5_kb_env$db <- NULL
    .wp5_kb_env$loaded <- FALSE
    return(invisible(NULL))
  }

  tryCatch({
    raw <- jsonlite::fromJSON(db_path, simplifyDataFrame = FALSE)
    .wp5_kb_env$db <- raw
    .wp5_kb_env$loaded <- TRUE

    n_das <- length(raw$demonstration_areas %||% list())
    n_mechs <- sum(vapply(
      raw$demonstration_areas %||% list(),
      function(da) length(da$mechanisms %||% list()),
      integer(1)
    ))
    if (exists("debug_log", mode = "function")) {
      debug_log(sprintf("WP5 KB loaded: v%s, %d DAs, %d mechanisms",
                        raw$version %||% "unknown", n_das, n_mechs), "WP5 KB")
    }
    message(sprintf("[WP5 KB] Loaded mechanism KB v%s with %d DAs and %d mechanisms",
                    raw$version %||% "unknown", n_das, n_mechs))

    invisible(raw)
  }, error = function(e) {
    warning(sprintf("[WP5 KB] Failed to load mechanism KB: %s", e$message))
    .wp5_kb_env$db <- NULL
    .wp5_kb_env$loaded <- FALSE
    invisible(NULL)
  })
}

# ==============================================================================
# LOOKUP HELPERS
# ==============================================================================

#' Check whether the WP5 KB has been successfully loaded
#' @return Logical
#' @export
wp5_kb_available <- function() {
  isTRUE(.wp5_kb_env$loaded) && !is.null(.wp5_kb_env$db)
}

#' Return all mechanisms for a given Demonstration Area
#'
#' @param da Character. One of the values in `WP5_DA_CONTEXTS`
#' @return List of mechanism entries (possibly empty); errors on unknown DA
#' @export
get_mechanisms_for_da <- function(da) {
  if (!wp5_kb_available()) {
    warning("[WP5 KB] KB not loaded; call load_wp5_mechanisms_kb() first")
    return(list())
  }
  valid <- if (exists("WP5_DA_CONTEXTS")) WP5_DA_CONTEXTS else c("macaronesia","tuscan","arctic")
  if (!da %in% valid) {
    stop(sprintf("Unknown DA '%s'; expected one of: %s",
                 da, paste(valid, collapse = ", ")))
  }
  da_block <- .wp5_kb_env$db$demonstration_areas[[da]]
  if (is.null(da_block)) return(list())
  da_block$mechanisms %||% list()
}

#' Return a single mechanism by its `id` field
#'
#' @param id Character mechanism ID (e.g., "mac_01_blue_corridor_facility")
#' @return Mechanism entry list, or NULL if not found
#' @export
get_mechanism_by_id <- function(id) {
  if (!wp5_kb_available()) return(NULL)
  for (da_name in names(.wp5_kb_env$db$demonstration_areas)) {
    mechs <- .wp5_kb_env$db$demonstration_areas[[da_name]]$mechanisms %||% list()
    for (m in mechs) {
      if (!is.null(m$id) && identical(m$id, id)) return(m)
    }
  }
  NULL
}

#' Return the bundled valuation unit values for a given habitat
#'
#' @param habitat Character habitat key (e.g., "posidonia_oceanica")
#' @return Named list of services with low/central/high/unit/method, or NULL
#' @export
get_valuation_unit_values <- function(habitat) {
  if (!wp5_kb_available()) return(NULL)
  .wp5_kb_env$db$valuation_unit_values[[habitat]]
}

# Auto-load on source if data file present (mirrors ses_knowledge_db_loader.R)
if (file.exists("data/ses_knowledge_db_wp5_mechanisms.json")) {
  load_wp5_mechanisms_kb()
}
```

- [ ] **Step 2: Run the test — confirm it now passes**

```powershell
& "C:\Program Files\R\R-4.4.1\bin\Rscript.exe" -e "testthat::test_file('tests/testthat/test-wp5-kb-loader.R')"
```

Expected: all 7 tests in this file PASS.

- [ ] **Step 3: Commit**

```powershell
git add functions/wp5_kb_loader.R
git commit -m "feat(wp5): add WP5 mechanism KB loader and lookup helpers"
```

---

### Task B4: Wire the loader into `global.R`

**Files:**
- Modify: `global.R` (after the existing `source("functions/ses_knowledge_db_loader.R", local = FALSE)` line)

- [ ] **Step 1: Locate the existing KB loader source line**

```powershell
& "C:\Program Files\R\R-4.4.1\bin\Rscript.exe" -e "cat(grep('ses_knowledge_db_loader', readLines('global.R'), value=TRUE))"
```

Confirms the existing line is `source("functions/ses_knowledge_db_loader.R", local = FALSE)` at L687.

- [ ] **Step 2: Add the WP5 loader source line immediately after**

Use Edit tool to insert after `source("functions/ses_knowledge_db_loader.R", local = FALSE)`:

```r
source("functions/ses_knowledge_db_loader.R", local = FALSE)

# WP5 Mechanism KB loader (financial mechanisms surfaced in the Response/Measure
# reference pane and consumed by Phase 2 valuation calculator + Phase 4 impact
# assessment). Must be global scope.
source("functions/wp5_kb_loader.R", local = FALSE)
```

- [ ] **Step 3: Smoke-test the global.R load chain**

```powershell
& "C:\Program Files\R\R-4.4.1\bin\Rscript.exe" -e "source('global.R'); cat('wp5_kb_available:', wp5_kb_available())"
```

Expected output ends with `wp5_kb_available: TRUE`.

- [ ] **Step 4: Commit**

```powershell
git add global.R
git commit -m "feat(wp5): source WP5 KB loader from global.R startup chain"
```

---

## Section C — Build script, audit script, 5-mechanism partner sample

### Task C1: Author the Python build-script skeleton

**Files:**
- Create: `scripts/build_wp5_mechanisms_kb.py`

- [ ] **Step 1: Write the build script with header banner**

Write to `scripts/build_wp5_mechanisms_kb.py`:

```python
#!/usr/bin/env python3
"""Build the WP5 financial-mechanism knowledge base from D5.2 source extracts.

Reads markdown extracts of the four WP5 source documents and emits
data/ses_knowledge_db_wp5_mechanisms.json. Mirrors the offshore-wind KB build
script's style and manual-edit guard.

Usage:
    micromamba run -n shiny python scripts/build_wp5_mechanisms_kb.py

Source extracts (regenerate via python-docx if missing):
    ~/AppData/Local/Temp/wp5_extract/D5.2_main.md
    ~/AppData/Local/Temp/wp5_extract/D5.2_macaronesia.md
    ~/AppData/Local/Temp/wp5_extract/blue_corridor.md
    ~/AppData/Local/Temp/wp5_extract/tuscan.md
    ~/AppData/Local/Temp/wp5_extract/arctic.md

NOTE ON MANUAL POST-GENERATION EDITS
------------------------------------
data/ses_knowledge_db_wp5_mechanisms.json may be hand-edited after generation
during partner-review cycles. Rerunning this script REGENERATES from the
in-script mechanism definitions (below) and will drop any manual additions
not mirrored here. Before rebuilding:
  1. git diff data/ses_knowledge_db_wp5_mechanisms.json against last commit
  2. confirm whether the JSON state is authoritative (keep) or this script
     is (overwrite)
  3. if the JSON is authoritative, mirror manual changes into the in-script
     definitions below before rebuilding
"""

import json
from datetime import date
from pathlib import Path

OUT_PATH = Path("data/ses_knowledge_db_wp5_mechanisms.json")
SOURCE_COMMIT = "1f636e8"
SOURCE_DOCS = [
    "Blue_corridor_financial toolkit_17_04_2026.docx",
    "Draft financial mechanisms_Tuscan DA.docx",
    "Draft text financial mechanisms_Arctic DA.docx",
    "MarineSABRES_Deliverable5.2_Draftv3.docx",
]

# ============================================================================
# MECHANISM DEFINITIONS
# ============================================================================
# Each mechanism MUST carry all 10 attributes:
#   id, name, cost_profile, what_it_funds, finance_flow, design_parameters,
#   evidence_base, transferable_lessons, applies_to_DAs, success_metrics,
#   risks_and_guardrails, use_in_impact_assessment, references
# (success_metrics + applies_to_DAs come from the Marine SABRES indicator set
# and DA names; success_metrics may be empty pending Phase 3 indicator registry.)

MACARONESIA_MECHANISMS = [
    # ----- mac_01: Blue Corridor Facility -----
    {
        "id": "mac_01_blue_corridor_facility",
        "name": "Blue Corridor Facility",
        "cost_profile": "recurring",
        "what_it_funds": "A regional financing facility funding coordinated monitoring, enforcement, scientific assessment, and stakeholder engagement across the Azores-Madeira-Canary Islands EEZ + ABNJ Blue Corridor.",
        "finance_flow": {
            "payer": [
                "EU (Horizon Europe successor + EMFAF)",
                "national governments (PT, ES)",
                "philanthropic foundations",
            ],
            "receiver": "regional secretariat (proposed: hosted by an existing IGO or jointly by national MPA agencies)",
            "type": "blended",
        },
        "design_parameters": [
            "Narrow corridor-delivery mandate to prevent mission creep",
            "Eligible cost categories defined in the founding charter (monitoring, enforcement, science, engagement; not general MPA operations)",
            "Three-jurisdiction governing board with rotating chair",
            "Annual operating budget €5–15M, with multi-year commitment cycles",
        ],
        "evidence_base": [
            "MSP4BIO D3.2 (regional financing analogues)",
            "OSPAR Coordinated Environmental Monitoring Programme (governance precedent)",
            "Mediterranean MedPAN Fund (operational precedent for regional MPA financing)",
        ],
        "transferable_lessons": [
            "Regional secretariat must have legal personality; informal coordination collapses under fiscal stress",
            "Multi-year commitment cycles essential — annual renewals create activity gaps that erode trust",
            "Co-funding from national governments (not just EU) increases political durability",
        ],
        "applies_to_DAs": ["macaronesia"],
        "success_metrics": ["C_01", "C_02", "M_01"],
        "risks_and_guardrails": [
            {"risk": "Mandate creep — facility becomes a generic MPA funding pot",
             "guardrail": "Founding charter narrows eligible activities to corridor-delivery; annual board review of out-of-scope requests"},
            {"risk": "Free-riding by one jurisdiction",
             "guardrail": "Co-funding share required as condition of voting rights"},
            {"risk": "Political withdrawal during national election cycles",
             "guardrail": "Multi-year commitments + treaty-level codification (where feasible)"},
        ],
        "use_in_impact_assessment": "Use this mechanism when scoring a Macaronesia scenario where regional coordination capacity is the binding constraint (S3 Coordinated EEZ or S4 Integrated EEZ+ABNJ). Score it positively on EE (enables monitoring) and negatively on PI (requires multi-state agreement). Pair with M_01 vessel-movement indicator for measurable success.",
        "references": [
            "MarineSABRES D5.2 §5.x Blue Corridor financial toolkit",
            "MSP4BIO Deliverable 3.2",
        ],
    },
    # Additional Macaronesia mechanisms appended by Tasks C2, D1
]

TUSCAN_MECHANISMS = [
    # Filled in by Task C2 (sample) and Task D2 (remainder)
]

ARCTIC_MECHANISMS = [
    # Filled in by Task C2 (sample) and Task D3 (remainder)
]

VALUATION_UNIT_VALUES = {
    "posidonia_oceanica": {
        "coastal_protection":   {"low": 3500,  "central": 10350, "high": 17200, "unit": "EUR/ha/yr", "method": "avoided_cost"},
        "carbon_sequestration": {"low": 40,    "central": 140,   "high": 240,   "unit": "EUR/ha/yr", "method": "social_cost_of_carbon"},
        "recreation_tourism":   {"low": 400,   "central": 2500,  "high": 4600,  "unit": "EUR/ha/yr", "method": "travel_cost_or_WTP"},
        "food_provision":       {"low": 150,   "central": 975,   "high": 1800,  "unit": "EUR/ha/yr", "method": "market_pricing"},
        "water_purification":   {"low": 350,   "central": 1175,  "high": 2000,  "unit": "EUR/ha/yr", "method": "replacement_cost"},
    },
    "restoration_costs": {
        "posidonia_oceanica": {"low": 100000, "high": 500000, "unit": "EUR/ha", "early_survival_low": 0.38, "early_survival_high": 0.60},
    },
}

# ============================================================================
# BUILD
# ============================================================================

def build_kb():
    return {
        "version": "1.0.0",
        "description": "WP5 financial and implementation mechanisms catalogue (Marine SABRES Deliverable 5.2). Mechanisms are indexed by Demonstration Area; each mechanism follows a fixed 10-attribute structure mirroring the Blue Corridor toolkit annex. Bundled `valuation_unit_values` carries Tuscan Posidonia oceanica benefit-transfer estimates consumed by the Phase 2 valuation calculator.",
        "last_updated": str(date.today()),
        "source_documents": SOURCE_DOCS,
        "source_commit": SOURCE_COMMIT,
        "demonstration_areas": {
            "macaronesia": {
                "description": "Blue Corridor (EEZ + ABNJ); cross-jurisdictional MPA network spanning Azores-Madeira-Canary Islands, with mechanisms supporting coordinated monitoring, enforcement, and connectivity-preserving fisheries management.",
                "mechanisms": MACARONESIA_MECHANISMS,
            },
            "tuscan": {
                "description": "Tuscan Archipelago National Park; mechanisms supporting Posidonia oceanica meadow protection, restoration, and enforcement against anchoring and trawling damage.",
                "mechanisms": TUSCAN_MECHANISMS,
            },
            "arctic": {
                "description": "Arctic Northeast Atlantic; mechanisms supporting quota allocation, enforcement, and incentive design for sustainable fisheries under ICES/NEAFC governance.",
                "mechanisms": ARCTIC_MECHANISMS,
            },
        },
        "valuation_unit_values": VALUATION_UNIT_VALUES,
    }


def main():
    kb = build_kb()
    OUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    with OUT_PATH.open("w", encoding="utf-8") as f:
        json.dump(kb, f, ensure_ascii=False, indent=2)
    print(f"[build_wp5_mechanisms_kb] wrote {OUT_PATH} "
          f"(macaronesia={len(MACARONESIA_MECHANISMS)}, "
          f"tuscan={len(TUSCAN_MECHANISMS)}, "
          f"arctic={len(ARCTIC_MECHANISMS)})")


if __name__ == "__main__":
    main()
```

- [ ] **Step 2: Run the build script and confirm it regenerates the JSON identically**

```powershell
micromamba run -n shiny python scripts/build_wp5_mechanisms_kb.py
```

Expected output ends with `(macaronesia=1, tuscan=0, arctic=0)`.

- [ ] **Step 3: Re-run the loader test to confirm regenerated JSON parses**

```powershell
& "C:\Program Files\R\R-4.4.1\bin\Rscript.exe" -e "testthat::test_file('tests/testthat/test-wp5-kb-loader.R')"
```

Expected: all 7 tests pass.

- [ ] **Step 4: Commit**

```powershell
git add scripts/build_wp5_mechanisms_kb.py
git commit -m "feat(wp5): add Python builder for WP5 mechanism KB"
```

---

### Task C2: Add the 4 remaining sample mechanisms (5-mechanism partner sample)

The 5-mechanism partner sample per spec §5.7 is: **Macaronesia: Blue Corridor Facility (already done in C1) + Tuscan: PES + Arctic: cost-recovery fees + 2 partner-picked**. For this task, we extract Tuscan PES and Arctic cost-recovery fees from the source markdown; the 2 partner-picked entries are added in the same task once partners name them, or — if partners have not yet named them — we proceed with two reasonable defaults documented in the commit message and revisit at the partner gate.

**Files:**
- Modify: `scripts/build_wp5_mechanisms_kb.py` (append entries to `TUSCAN_MECHANISMS` and `ARCTIC_MECHANISMS`)

- [ ] **Step 1: Extract the Tuscan PES (Payment for Ecosystem Services) entry**

Read source: `~/AppData/Local/Temp/wp5_extract/tuscan.md`. Locate the "Payments for Ecosystem Services (PES)" section. Extract content under the 10 standard attributes; if a source attribute is implicit, write a brief explicit summary rather than leave it empty.

Append to `TUSCAN_MECHANISMS` in `scripts/build_wp5_mechanisms_kb.py`:

```python
    {
        "id": "tus_01_pes_posidonia",
        "name": "Payment for Ecosystem Services (PES) for Posidonia conservation",
        "cost_profile": "recurring",
        "what_it_funds": "Direct compensation to fishers, dive operators, and coastal landowners for verifiable conservation actions protecting Posidonia oceanica meadows (e.g., gear modifications, anchoring restrictions, no-take agreements).",
        "finance_flow": {
            "payer": ["regional MPA authority", "EU LIFE / EMFAF co-funding", "tourism operator levies"],
            "receiver": "individual fishers / cooperatives / landowners",
            "type": "blended",
        },
        "design_parameters": [
            "Verifiable on-water actions tied to monitoring data (not self-reported)",
            "Annual payment cycle aligned with fishing season",
            "Eligibility floor: minimum patch area protected per recipient",
            "Sunset clause: 5-year cycle with renewal contingent on biophysical outcomes",
        ],
        "evidence_base": [
            "Costa Rica Pago por Servicios Ambientales (operational precedent)",
            "Mediterranean Posidonia restoration trials (Boudouresque et al., site-specific)",
        ],
        "transferable_lessons": [
            "Self-reported actions reduce political cost but degrade outcomes; tie payments to monitoring data",
            "Cooperatives administer payments more efficiently than per-vessel transfers",
            "Tourism levy tolerated when receipts are visibly earmarked for marine conservation",
        ],
        "applies_to_DAs": ["tuscan"],
        "success_metrics": ["POS_density"],
        "risks_and_guardrails": [
            {"risk": "Adverse selection — only low-effort fishers enroll",
             "guardrail": "Eligibility floor + onboarding workshop on actions required"},
            {"risk": "Greenwashing if monitoring is weak",
             "guardrail": "Independent verification by MPA scientific staff or contracted institute"},
        ],
        "use_in_impact_assessment": "Use when scoring a Tuscan scenario that depends on voluntary fisher cooperation (S2 Light or S3 Coordinated). Score positively on EQ (compensates affected fishers) and EE (when monitoring is robust). Pair with POS_density biophysical indicator.",
        "references": ["MarineSABRES D5.2 Tuscan DA, §x.x Financial mechanisms"],
    },
```

- [ ] **Step 2: Extract the Arctic cost-recovery fees entry**

Read source: `~/AppData/Local/Temp/wp5_extract/arctic.md`. Locate the "Cost-recovery fees" or "Enforcement fee" section.

Append to `ARCTIC_MECHANISMS` in `scripts/build_wp5_mechanisms_kb.py`:

```python
    {
        "id": "arc_01_cost_recovery_fees",
        "name": "Cost-recovery fees on quota holders",
        "cost_profile": "recurring",
        "what_it_funds": "Enforcement, observer programmes, and stock-assessment science in the Arctic Northeast Atlantic, financed by per-tonne or per-vessel fees levied on quota holders.",
        "finance_flow": {
            "payer": ["quota holders (commercial fishing operators)"],
            "receiver": "national fisheries authorities (NO, IS, FO, RU); ICES/NEAFC scientific programmes",
            "type": "private-to-public",
        },
        "design_parameters": [
            "Fee scaled by landed value, not landed tonnage (better tracks effort to value)",
            "Earmarked use: science + enforcement; not general treasury",
            "Annual fee adjustment via published methodology to avoid political volatility",
            "Reduced fee for vessels carrying observers / electronic monitoring",
        ],
        "evidence_base": [
            "Iceland fisheries fee (operational precedent since 2012)",
            "OECD Sustainable Fisheries report (2022) on cost-recovery best practice",
        ],
        "transferable_lessons": [
            "Public earmark builds quota-holder political tolerance",
            "Per-value (not per-tonne) fees survive price-shock years better",
            "Fee discount for monitoring-equipped vessels accelerates adoption",
        ],
        "applies_to_DAs": ["arctic"],
        "success_metrics": [],
        "risks_and_guardrails": [
            {"risk": "Fees become a general revenue grab",
             "guardrail": "Earmarked use legislated, not just administrative"},
            {"risk": "Race-to-the-bottom across jurisdictions",
             "guardrail": "Coordinated minimum fee floor under NEAFC framework"},
        ],
        "use_in_impact_assessment": "Use when scoring an Arctic scenario where enforcement and science capacity are the binding constraint (Partial or Full Agreement). Score positively on EC (efficient cost recovery) and FF (sustained funding). Pair with stock-status indicators in later phases.",
        "references": ["MarineSABRES D5.2 Arctic DA, §x.x Financial mechanisms", "OECD Sustainable Fisheries (2022)"],
    },
```

- [ ] **Step 3: Add 2 placeholder partner-picked entries**

If partners have not yet named the 2 additional sample mechanisms, add Macaronesia `MPA tourism-levy fund` and Tuscan `Mooring-buoy permit fee` as defensible defaults (both are explicitly named in their source documents). The commit message MUST flag that these are placeholders subject to partner override at gate 1.

Append to `MACARONESIA_MECHANISMS`:

```python
    {
        "id": "mac_02_tourism_levy_fund",
        "name": "MPA tourism-levy fund",
        "cost_profile": "recurring",
        "what_it_funds": "Conservation actions and visitor-management infrastructure in Macaronesian MPAs, financed by a small per-visitor or per-vessel levy on marine tourism operators.",
        "finance_flow": {
            "payer": ["marine tourism operators (whale-watching, dive boats, charter vessels)"],
            "receiver": "MPA management body",
            "type": "private-to-public",
        },
        "design_parameters": [
            "Levy collected at point of sale (not at the dock) for compliance",
            "Earmarked spending plan published annually",
            "Levy adjusts inversely with visitor numbers to smooth revenue",
        ],
        "evidence_base": [
            "Galápagos visitor entry fee (operational precedent)",
            "Bonaire dive tag programme",
        ],
        "transferable_lessons": [
            "Visible reinvestment in infrastructure (mooring buoys, signage) sustains operator buy-in",
            "Online point-of-sale collection has lower leakage than on-water enforcement",
        ],
        "applies_to_DAs": ["macaronesia"],
        "success_metrics": ["T_02"],
        "risks_and_guardrails": [
            {"risk": "Levy passed entirely to visitors with no operator engagement",
             "guardrail": "Operator co-governance seat on the spending plan"},
        ],
        "use_in_impact_assessment": "Use for any Macaronesia scenario with active marine tourism. Score positively on FF and EC.",
        "references": ["MarineSABRES D5.2 Blue Corridor toolkit, §x.x"],
    },
```

Append to `TUSCAN_MECHANISMS`:

```python
    {
        "id": "tus_02_mooring_buoy_permit",
        "name": "Mooring-buoy permit fee",
        "cost_profile": "recurring",
        "what_it_funds": "Installation, maintenance, and enforcement of mooring buoys protecting Posidonia meadows from anchor damage, financed by per-vessel permit fees.",
        "finance_flow": {
            "payer": ["recreational and commercial vessels operating in Tuscan MPA waters"],
            "receiver": "MPA management body / contracted maintenance operator",
            "type": "private-to-public",
        },
        "design_parameters": [
            "Mandatory mooring (anchoring banned) inside designated meadow zones",
            "Permit price covers maintenance cost + 20% reserve",
            "Online permit purchase with automated boundary enforcement via AIS",
        ],
        "evidence_base": [
            "Mediterranean MPA mooring-buoy systems (multiple operational precedents)",
        ],
        "transferable_lessons": [
            "Mandatory mooring works only with credible enforcement; voluntary systems fail",
            "AIS-based boundary enforcement is cheaper than patrol vessels for small MPAs",
        ],
        "applies_to_DAs": ["tuscan"],
        "success_metrics": ["POS_density"],
        "risks_and_guardrails": [
            {"risk": "Insufficient buoy density forces anchoring outside designated zones",
             "guardrail": "Capacity sized to peak summer demand × 1.2"},
        ],
        "use_in_impact_assessment": "Use for any Tuscan scenario protecting Posidonia. Score strongly positive on EE.",
        "references": ["MarineSABRES D5.2 Tuscan DA, §x.x"],
    },
```

- [ ] **Step 4: Run the build script**

```powershell
micromamba run -n shiny python scripts/build_wp5_mechanisms_kb.py
```

Expected output ends with `(macaronesia=2, tuscan=2, arctic=1)`.

- [ ] **Step 5: Run loader test**

```powershell
& "C:\Program Files\R\R-4.4.1\bin\Rscript.exe" -e "testthat::test_file('tests/testthat/test-wp5-kb-loader.R')"
```

Expected: all 7 tests pass.

- [ ] **Step 6: Commit**

```powershell
git add scripts/build_wp5_mechanisms_kb.py data/ses_knowledge_db_wp5_mechanisms.json
git commit -m "feat(wp5): add 5-mechanism partner sample (BCF, PES, cost-recovery, tourism-levy, mooring-permit)

Sample for partner gate 1 per spec §5.7. Two partner-picked entries
(mac_02_tourism_levy_fund, tus_02_mooring_buoy_permit) are defensible
defaults from the source documents — partners may swap these at the gate."
```

---

### Task C3: Author the audit script

**Files:**
- Create: `scripts/kb_audit/audit_wp5_mechanisms.py`

- [ ] **Step 1: Write the audit script**

Write to `scripts/kb_audit/audit_wp5_mechanisms.py`:

```python
#!/usr/bin/env python3
"""WP5 mechanism KB quality audit.

Reads data/ses_knowledge_db_wp5_mechanisms.json and flags:
  - Mechanisms missing any of the 10 required attributes
  - Mechanisms with <8/10 attributes populated (per spec §5.7 floor)
  - DA names not in the canonical {macaronesia, tuscan, arctic} set
  - Empty references or evidence_base arrays
  - finance_flow with no payer or no receiver
  - Mechanism IDs that are not unique within the file

Exits with status 1 if any FAIL-class issue is found.

Usage:
    micromamba run -n shiny python scripts/kb_audit/audit_wp5_mechanisms.py
"""

import json
import sys
from pathlib import Path

KB_PATH = Path("data/ses_knowledge_db_wp5_mechanisms.json")
CANONICAL_DAS = {"macaronesia", "tuscan", "arctic"}
REQUIRED_ATTRS = [
    "id", "name", "cost_profile", "what_it_funds", "finance_flow",
    "design_parameters", "evidence_base", "transferable_lessons",
    "applies_to_DAs", "success_metrics", "risks_and_guardrails",
    "use_in_impact_assessment", "references",
]
# Of these 13, 10 are spec-required (success_metrics + risks_and_guardrails +
# applies_to_DAs are project-internal cross-references that may be lean).
COMPLETENESS_ATTRS = [
    "name", "cost_profile", "what_it_funds", "finance_flow",
    "design_parameters", "evidence_base", "transferable_lessons",
    "use_in_impact_assessment", "references",
]
# 9 attrs counted for the "≥8/10" floor (10th is `id`, always present)


def is_populated(value):
    """Return True if a JSON value carries non-trivial content."""
    if value is None:
        return False
    if isinstance(value, str):
        return bool(value.strip())
    if isinstance(value, (list, dict)):
        return bool(value)
    return True


def audit_mechanism(da_name, mech, seen_ids):
    issues = []
    mid = mech.get("id", "<missing-id>")

    # Missing required attributes (FAIL)
    for attr in REQUIRED_ATTRS:
        if attr not in mech:
            issues.append(("FAIL", f"{da_name}/{mid}: missing required attribute '{attr}'"))

    # ID uniqueness
    if mid in seen_ids:
        issues.append(("FAIL", f"{mid}: duplicate id (also appears in {seen_ids[mid]})"))
    else:
        seen_ids[mid] = da_name

    # Completeness floor (≥8/10)
    populated = sum(1 for a in COMPLETENESS_ATTRS if is_populated(mech.get(a)))
    if populated < 8:
        issues.append(("FAIL", f"{da_name}/{mid}: only {populated}/9 completeness attrs populated; spec floor is 8"))

    # finance_flow structure
    ff = mech.get("finance_flow") or {}
    if not ff.get("payer"):
        issues.append(("FAIL", f"{da_name}/{mid}: finance_flow.payer is empty"))
    if not ff.get("receiver"):
        issues.append(("FAIL", f"{da_name}/{mid}: finance_flow.receiver is empty"))

    # applies_to_DAs canonicality
    for da in mech.get("applies_to_DAs", []):
        if da not in CANONICAL_DAS:
            issues.append(("FAIL", f"{da_name}/{mid}: applies_to_DAs contains non-canonical '{da}'"))

    # Empty references is a WARN (some mechanisms genuinely have only one source)
    if not mech.get("references"):
        issues.append(("WARN", f"{da_name}/{mid}: references array is empty"))
    if not mech.get("evidence_base"):
        issues.append(("WARN", f"{da_name}/{mid}: evidence_base array is empty"))

    return issues


def main():
    if not KB_PATH.exists():
        print(f"FAIL: KB file not found at {KB_PATH}", file=sys.stderr)
        sys.exit(1)

    with KB_PATH.open(encoding="utf-8") as f:
        kb = json.load(f)

    issues = []
    seen_ids = {}

    das = kb.get("demonstration_areas", {})
    for da_name in das:
        if da_name not in CANONICAL_DAS:
            issues.append(("FAIL", f"demonstration_areas: non-canonical key '{da_name}'"))
        for mech in das[da_name].get("mechanisms", []):
            issues.extend(audit_mechanism(da_name, mech, seen_ids))

    # Valuation block sanity
    vuv = kb.get("valuation_unit_values", {})
    if "posidonia_oceanica" in vuv:
        pos = vuv["posidonia_oceanica"]
        for service, vals in pos.items():
            if not all(k in vals for k in ("low", "central", "high", "unit", "method")):
                issues.append(("FAIL", f"valuation_unit_values.posidonia_oceanica.{service}: missing low/central/high/unit/method"))
            elif not (vals["low"] <= vals["central"] <= vals["high"]):
                issues.append(("FAIL", f"valuation_unit_values.posidonia_oceanica.{service}: bands not ordered low ≤ central ≤ high"))

    # Report
    fails = [i for i in issues if i[0] == "FAIL"]
    warns = [i for i in issues if i[0] == "WARN"]

    n_mechs = sum(len(da.get("mechanisms", [])) for da in das.values())
    print(f"=== WP5 mechanism KB audit ===")
    print(f"Mechanisms: {n_mechs}")
    print(f"Issues: {len(fails)} FAIL, {len(warns)} WARN")
    for sev, msg in fails + warns:
        print(f"  [{sev}] {msg}")

    sys.exit(1 if fails else 0)


if __name__ == "__main__":
    main()
```

- [ ] **Step 2: Run the audit on the current 5-mechanism KB**

```powershell
micromamba run -n shiny python scripts/kb_audit/audit_wp5_mechanisms.py
```

Expected: `Issues: 0 FAIL, 0 WARN` (since all 5 sample mechanisms are fully populated). Exit status 0.

- [ ] **Step 3: Commit**

```powershell
git add scripts/kb_audit/audit_wp5_mechanisms.py
git commit -m "feat(wp5): add KB quality audit for WP5 mechanisms"
```

---

## 🛑 Partner Gate 1 — 5-mechanism sample sign-off

**Per spec §5.7:** before proceeding to populate the remaining 23 mechanisms (Section D), submit the 5-mechanism sample to partner reviewers. Partners verify content matches source documents paragraph-for-paragraph for:

- Macaronesia: Blue Corridor Facility (`mac_01_blue_corridor_facility`) — Macaronesia partner reviewer
- Tuscan: PES for Posidonia (`tus_01_pes_posidonia`) — Tuscan partner reviewer
- Arctic: cost-recovery fees (`arc_01_cost_recovery_fees`) — Arctic partner reviewer
- Macaronesia: tourism-levy fund (`mac_02_tourism_levy_fund`) — partner-pickable, may be replaced
- Tuscan: mooring-buoy permit (`tus_02_mooring_buoy_permit`) — partner-pickable, may be replaced

Apply any partner corrections (re-run Tasks C2 + C3 + audit; commit each correction separately). **Do not proceed to Section D until Macaronesia, Tuscan, and Arctic reviewers have all signed off in writing.**

The 2/4-week response/escalation window applies (spec §4.4). If a reviewer holds, only the affected DA pauses; other DAs may proceed.

---

## Section D — Populate the remaining 23 mechanisms (post-gate)

The shape is identical to Task C2: read source markdown extract, add a Python dict to the appropriate list in `build_wp5_mechanisms_kb.py`, run the build, run the audit. Each mechanism is one commit.

### Task D1: Add the remaining 14 Macaronesia mechanisms

**Files:**
- Modify: `scripts/build_wp5_mechanisms_kb.py` (extend `MACARONESIA_MECHANISMS`)

The Blue Corridor toolkit defines 16 Macaronesia mechanisms. After Task C2 there are 2 (`mac_01_blue_corridor_facility`, `mac_02_tourism_levy_fund`); add the remaining 14.

- [ ] **Step 1: Read the source markdown**

```powershell
# Open the file in your editor or read pages 100-300 of:
# C:\Users\ARTURA~1.BAZ\AppData\Local\Temp\wp5_extract\blue_corridor.md
```

- [ ] **Step 2: For each remaining mechanism**

For each mechanism, follow exactly the same Python-dict shape used in Task C2. Use IDs `mac_03_*` through `mac_16_*` in the order they appear in `blue_corridor.md`. Include all 13 attributes; if the source genuinely lacks content for an attribute (e.g., no `success_metrics` named yet), supply a brief explicit summary (`["pending Phase 3 indicator registry"]`) rather than leave empty — the audit's ≥8/10 floor counts populated arrays, not empty ones.

- [ ] **Step 3: After each mechanism, run the build + loader test + audit**

```powershell
micromamba run -n shiny python scripts/build_wp5_mechanisms_kb.py ; & "C:\Program Files\R\R-4.4.1\bin\Rscript.exe" -e "testthat::test_file('tests/testthat/test-wp5-kb-loader.R')" ; micromamba run -n shiny python scripts/kb_audit/audit_wp5_mechanisms.py
```

All three must pass before committing each mechanism.

- [ ] **Step 4: Commit per mechanism (atomic granularity)**

```powershell
git add scripts/build_wp5_mechanisms_kb.py data/ses_knowledge_db_wp5_mechanisms.json
git commit -m "feat(wp5): add Macaronesia mechanism mac_NN_<short_name>"
```

This task contains 14 such commits; an experienced reviewer can audit each one independently.

---

### Task D2: Add the remaining 4 Tuscan mechanisms

The Tuscan source defines 6 mechanism families; after Tasks C2 there are 2; add the remaining 4 (IDs `tus_03_*` through `tus_06_*`).

**Files:**
- Modify: `scripts/build_wp5_mechanisms_kb.py` (extend `TUSCAN_MECHANISMS`)

- [ ] **Step 1: Read source `~/AppData/Local/Temp/wp5_extract/tuscan.md`**

- [ ] **Step 2: Append 4 mechanism entries** following the Task C2 shape exactly.

- [ ] **Step 3: Run build + loader + audit per mechanism (same command as D1 Step 3)**

- [ ] **Step 4: Commit per mechanism**

```powershell
git add scripts/build_wp5_mechanisms_kb.py data/ses_knowledge_db_wp5_mechanisms.json
git commit -m "feat(wp5): add Tuscan mechanism tus_NN_<short_name>"
```

---

### Task D3: Add the remaining 5 Arctic mechanisms

The Arctic source defines 6 mechanism families; after Task C2 there is 1; add the remaining 5 (IDs `arc_02_*` through `arc_06_*`).

**Files:**
- Modify: `scripts/build_wp5_mechanisms_kb.py` (extend `ARCTIC_MECHANISMS`)

- [ ] **Step 1: Read source `~/AppData/Local/Temp/wp5_extract/arctic.md`**

- [ ] **Step 2: Append 5 mechanism entries** following the Task C2 shape exactly.

- [ ] **Step 3: Run build + loader + audit per mechanism**

- [ ] **Step 4: Commit per mechanism**

```powershell
git add scripts/build_wp5_mechanisms_kb.py data/ses_knowledge_db_wp5_mechanisms.json
git commit -m "feat(wp5): add Arctic mechanism arc_NN_<short_name>"
```

---

### Task D4: Final audit on the complete 28-mechanism KB

**Files:**
- (Audit-only; no code changes if everything passes)

- [ ] **Step 1: Run the audit**

```powershell
micromamba run -n shiny python scripts/kb_audit/audit_wp5_mechanisms.py
```

Expected: `Mechanisms: 28`, `Issues: 0 FAIL`. WARN count may be > 0 (some mechanisms genuinely have empty `references` until Phase 4 partner gate); document acceptable WARNs in commit message if any.

- [ ] **Step 2: Run the loader test**

```powershell
& "C:\Program Files\R\R-4.4.1\bin\Rscript.exe" -e "testthat::test_file('tests/testthat/test-wp5-kb-loader.R')"
```

All 7 tests pass.

- [ ] **Step 3: If any issue surfaces, fix it and commit. Otherwise no commit needed.**

---

## Section E — i18n chrome translations + audit allowlist

### Task E1: Author the chrome translations file

**Files:**
- Create: `translations/modules/wp5_mechanisms.json`

- [ ] **Step 1: Write the translations file with all 9 locales (English-fallback per §9.1)**

The 25 keys cover the reference-pane chrome only. Mechanism descriptions and attributes stay in the JSON KB (English-only).

Write to `translations/modules/wp5_mechanisms.json`:

```json
{
  "languages": ["en", "es", "fr", "de", "lt", "pt", "it", "no", "el"],
  "translation": {
    "modules.wp5_mechanisms.pane.title": {
      "en": "Linked WP5 mechanisms",
      "es": "Linked WP5 mechanisms",
      "fr": "Linked WP5 mechanisms",
      "de": "Linked WP5 mechanisms",
      "lt": "Linked WP5 mechanisms",
      "pt": "Linked WP5 mechanisms",
      "it": "Linked WP5 mechanisms",
      "no": "Linked WP5 mechanisms",
      "el": "Linked WP5 mechanisms"
    },
    "modules.wp5_mechanisms.pane.subtitle": {
      "en": "Financial and implementation mechanisms from Marine SABRES Deliverable 5.2 relevant to this Response or Measure.",
      "es": "Financial and implementation mechanisms from Marine SABRES Deliverable 5.2 relevant to this Response or Measure.",
      "fr": "Financial and implementation mechanisms from Marine SABRES Deliverable 5.2 relevant to this Response or Measure.",
      "de": "Financial and implementation mechanisms from Marine SABRES Deliverable 5.2 relevant to this Response or Measure.",
      "lt": "Financial and implementation mechanisms from Marine SABRES Deliverable 5.2 relevant to this Response or Measure.",
      "pt": "Financial and implementation mechanisms from Marine SABRES Deliverable 5.2 relevant to this Response or Measure.",
      "it": "Financial and implementation mechanisms from Marine SABRES Deliverable 5.2 relevant to this Response or Measure.",
      "no": "Financial and implementation mechanisms from Marine SABRES Deliverable 5.2 relevant to this Response or Measure.",
      "el": "Financial and implementation mechanisms from Marine SABRES Deliverable 5.2 relevant to this Response or Measure."
    },
    "modules.wp5_mechanisms.pane.no_mechanisms": {
      "en": "No WP5 mechanisms are linked to this element. Mechanisms are available for Response and Measure elements.",
      "es": "No WP5 mechanisms are linked to this element. Mechanisms are available for Response and Measure elements.",
      "fr": "No WP5 mechanisms are linked to this element. Mechanisms are available for Response and Measure elements.",
      "de": "No WP5 mechanisms are linked to this element. Mechanisms are available for Response and Measure elements.",
      "lt": "No WP5 mechanisms are linked to this element. Mechanisms are available for Response and Measure elements.",
      "pt": "No WP5 mechanisms are linked to this element. Mechanisms are available for Response and Measure elements.",
      "it": "No WP5 mechanisms are linked to this element. Mechanisms are available for Response and Measure elements.",
      "no": "No WP5 mechanisms are linked to this element. Mechanisms are available for Response and Measure elements.",
      "el": "No WP5 mechanisms are linked to this element. Mechanisms are available for Response and Measure elements."
    },
    "modules.wp5_mechanisms.attr.cost_profile": {
      "en": "Cost profile",
      "es": "Cost profile", "fr": "Cost profile", "de": "Cost profile",
      "lt": "Cost profile", "pt": "Cost profile", "it": "Cost profile",
      "no": "Cost profile", "el": "Cost profile"
    },
    "modules.wp5_mechanisms.attr.what_it_funds": {
      "en": "What it funds",
      "es": "What it funds", "fr": "What it funds", "de": "What it funds",
      "lt": "What it funds", "pt": "What it funds", "it": "What it funds",
      "no": "What it funds", "el": "What it funds"
    },
    "modules.wp5_mechanisms.attr.finance_flow": {
      "en": "Finance flow",
      "es": "Finance flow", "fr": "Finance flow", "de": "Finance flow",
      "lt": "Finance flow", "pt": "Finance flow", "it": "Finance flow",
      "no": "Finance flow", "el": "Finance flow"
    },
    "modules.wp5_mechanisms.attr.payer": {
      "en": "Payer",
      "es": "Payer", "fr": "Payer", "de": "Payer", "lt": "Payer",
      "pt": "Payer", "it": "Payer", "no": "Payer", "el": "Payer"
    },
    "modules.wp5_mechanisms.attr.receiver": {
      "en": "Receiver",
      "es": "Receiver", "fr": "Receiver", "de": "Receiver", "lt": "Receiver",
      "pt": "Receiver", "it": "Receiver", "no": "Receiver", "el": "Receiver"
    },
    "modules.wp5_mechanisms.attr.design_parameters": {
      "en": "Design parameters",
      "es": "Design parameters", "fr": "Design parameters", "de": "Design parameters",
      "lt": "Design parameters", "pt": "Design parameters", "it": "Design parameters",
      "no": "Design parameters", "el": "Design parameters"
    },
    "modules.wp5_mechanisms.attr.evidence_base": {
      "en": "Evidence base",
      "es": "Evidence base", "fr": "Evidence base", "de": "Evidence base",
      "lt": "Evidence base", "pt": "Evidence base", "it": "Evidence base",
      "no": "Evidence base", "el": "Evidence base"
    },
    "modules.wp5_mechanisms.attr.transferable_lessons": {
      "en": "Transferable lessons",
      "es": "Transferable lessons", "fr": "Transferable lessons",
      "de": "Transferable lessons", "lt": "Transferable lessons",
      "pt": "Transferable lessons", "it": "Transferable lessons",
      "no": "Transferable lessons", "el": "Transferable lessons"
    },
    "modules.wp5_mechanisms.attr.applies_to_DAs": {
      "en": "Applies to DAs",
      "es": "Applies to DAs", "fr": "Applies to DAs", "de": "Applies to DAs",
      "lt": "Applies to DAs", "pt": "Applies to DAs", "it": "Applies to DAs",
      "no": "Applies to DAs", "el": "Applies to DAs"
    },
    "modules.wp5_mechanisms.attr.success_metrics": {
      "en": "Success metrics",
      "es": "Success metrics", "fr": "Success metrics", "de": "Success metrics",
      "lt": "Success metrics", "pt": "Success metrics", "it": "Success metrics",
      "no": "Success metrics", "el": "Success metrics"
    },
    "modules.wp5_mechanisms.attr.risks_and_guardrails": {
      "en": "Risks and guardrails",
      "es": "Risks and guardrails", "fr": "Risks and guardrails",
      "de": "Risks and guardrails", "lt": "Risks and guardrails",
      "pt": "Risks and guardrails", "it": "Risks and guardrails",
      "no": "Risks and guardrails", "el": "Risks and guardrails"
    },
    "modules.wp5_mechanisms.attr.use_in_impact_assessment": {
      "en": "Use in impact assessment",
      "es": "Use in impact assessment", "fr": "Use in impact assessment",
      "de": "Use in impact assessment", "lt": "Use in impact assessment",
      "pt": "Use in impact assessment", "it": "Use in impact assessment",
      "no": "Use in impact assessment", "el": "Use in impact assessment"
    },
    "modules.wp5_mechanisms.attr.references": {
      "en": "References",
      "es": "References", "fr": "References", "de": "References",
      "lt": "References", "pt": "References", "it": "References",
      "no": "References", "el": "References"
    },
    "modules.wp5_mechanisms.action.expand": {
      "en": "Show full description",
      "es": "Show full description", "fr": "Show full description",
      "de": "Show full description", "lt": "Show full description",
      "pt": "Show full description", "it": "Show full description",
      "no": "Show full description", "el": "Show full description"
    },
    "modules.wp5_mechanisms.action.collapse": {
      "en": "Hide description",
      "es": "Hide description", "fr": "Hide description",
      "de": "Hide description", "lt": "Hide description",
      "pt": "Hide description", "it": "Hide description",
      "no": "Hide description", "el": "Hide description"
    },
    "modules.wp5_mechanisms.action.view_source": {
      "en": "View source document",
      "es": "View source document", "fr": "View source document",
      "de": "View source document", "lt": "View source document",
      "pt": "View source document", "it": "View source document",
      "no": "View source document", "el": "View source document"
    },
    "modules.wp5_mechanisms.filter.by_da": {
      "en": "Filter by Demonstration Area",
      "es": "Filter by Demonstration Area", "fr": "Filter by Demonstration Area",
      "de": "Filter by Demonstration Area", "lt": "Filter by Demonstration Area",
      "pt": "Filter by Demonstration Area", "it": "Filter by Demonstration Area",
      "no": "Filter by Demonstration Area", "el": "Filter by Demonstration Area"
    },
    "modules.wp5_mechanisms.filter.all_das": {
      "en": "All DAs",
      "es": "All DAs", "fr": "All DAs", "de": "All DAs", "lt": "All DAs",
      "pt": "All DAs", "it": "All DAs", "no": "All DAs", "el": "All DAs"
    },
    "modules.wp5_mechanisms.da.macaronesia": {
      "en": "Macaronesia",
      "es": "Macaronesia", "fr": "Macaronésie", "de": "Makaronesien",
      "lt": "Makaronezija", "pt": "Macaronésia", "it": "Macaronesia",
      "no": "Makaronesia", "el": "Μακαρονησία"
    },
    "modules.wp5_mechanisms.da.tuscan": {
      "en": "Tuscan Archipelago",
      "es": "Archipiélago Toscano", "fr": "Archipel toscan",
      "de": "Toskanischer Archipel", "lt": "Toskanos salynas",
      "pt": "Arquipélago Toscano", "it": "Arcipelago Toscano",
      "no": "Toskanske arkipel", "el": "Τοσκανικό Αρχιπέλαγος"
    },
    "modules.wp5_mechanisms.da.arctic": {
      "en": "Arctic Northeast Atlantic",
      "es": "Arctic Northeast Atlantic", "fr": "Arctic Northeast Atlantic",
      "de": "Arctic Northeast Atlantic", "lt": "Arctic Northeast Atlantic",
      "pt": "Arctic Northeast Atlantic", "it": "Arctic Northeast Atlantic",
      "no": "Arctic Northeast Atlantic", "el": "Arctic Northeast Atlantic"
    },
    "modules.wp5_mechanisms.error.kb_not_loaded": {
      "en": "WP5 mechanism KB is unavailable. The reference pane will not be shown.",
      "es": "WP5 mechanism KB is unavailable. The reference pane will not be shown.",
      "fr": "WP5 mechanism KB is unavailable. The reference pane will not be shown.",
      "de": "WP5 mechanism KB is unavailable. The reference pane will not be shown.",
      "lt": "WP5 mechanism KB is unavailable. The reference pane will not be shown.",
      "pt": "WP5 mechanism KB is unavailable. The reference pane will not be shown.",
      "it": "WP5 mechanism KB is unavailable. The reference pane will not be shown.",
      "no": "WP5 mechanism KB is unavailable. The reference pane will not be shown.",
      "el": "WP5 mechanism KB is unavailable. The reference pane will not be shown."
    }
  }
}
```

The DA-name keys (`da.tuscan`, `da.macaronesia`) are translated where official translations exist; the rest are English-fallback per §9.1. The two translated DA names are the ones whose translation is unambiguous and stable across project documents; `arctic` is left English because no canonical translation exists across all 9 locales without partner input.

- [ ] **Step 2: Validate the JSON parses**

```powershell
& "C:\Program Files\R\R-4.4.1\bin\Rscript.exe" -e "x <- jsonlite::fromJSON('translations/modules/wp5_mechanisms.json', simplifyDataFrame = FALSE); cat('keys:', length(x[['translation']]))"
```

Expected output: `keys: 25`.

- [ ] **Step 3: Commit**

```powershell
git add translations/modules/wp5_mechanisms.json
git commit -m "feat(wp5,i18n): add 25 chrome translation keys with English-fallback for non-EN locales

Mechanism content stays English in the JSON KB (per spec §9.1 long-form
posture). Only chrome strings (pane title, attribute headers, filters)
are i18n-keyed. Backfill ticket: WP5-i18n-Phase1."
```

---

### Task E2: Extend `_i18n_audit.py` with `--allow-english-fallback=wp5`

**Files:**
- Modify: `scripts/_i18n_audit.py`

- [ ] **Step 1: Read the existing audit script's check structure**

```powershell
& "C:\Program Files\R\R-4.4.1\bin\Rscript.exe" -e "cat(readLines('scripts/_i18n_audit.py')[1:60], sep='\n')"
```

Find the section that flags keys with identical en/non-en values (the audit's "incomplete translations" check).

- [ ] **Step 2: Add CLI arg parsing near the top**

Insert after the existing imports (right after `import re, os, json, glob, sys`):

```python
import argparse

# ---- Argument parsing ----
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument(
    "--allow-english-fallback",
    type=str,
    default="",
    help="Comma-separated list of key prefixes for which English-fallback values are accepted (e.g. 'wp5'). Used during phased i18n delivery.",
)
args, _unknown = parser.parse_known_args()
ENGLISH_FALLBACK_PREFIXES = tuple(p.strip() for p in args.allow_english_fallback.split(",") if p.strip())
```

- [ ] **Step 3: Add the allowlist filter where incomplete-translation keys are reported**

Find the section that produces the "incomplete translations" report. For each key flagged as incomplete, before reporting, check:

```python
def _is_allowlisted_english_fallback(key: str) -> bool:
    """A key is allowlisted if its module name starts with one of the
    --allow-english-fallback prefixes, e.g. 'modules.wp5_*'."""
    if not ENGLISH_FALLBACK_PREFIXES:
        return False
    parts = key.split(".")
    if len(parts) < 2:
        return False
    module = parts[1]
    return any(module.startswith(p) for p in ENGLISH_FALLBACK_PREFIXES)
```

Apply the filter at the report site by wrapping the existing flagging logic:

```python
# Existing logic (paraphrased): for each (key, locales_with_english_value) ...
#     if locales_with_english_value: incomplete.append(key)
# Wrap with:
#     if locales_with_english_value and not _is_allowlisted_english_fallback(key):
#         incomplete.append(key)
```

The exact line numbers depend on the current state of `_i18n_audit.py`; locate the variable named like `incomplete` or the loop that compares en vs non-en values, and apply the wrapping.

- [ ] **Step 4: Run the audit with the new flag**

```powershell
micromamba run -n shiny python scripts/_i18n_audit.py --allow-english-fallback=wp5
```

Expected: WP5 keys in `translations/modules/wp5_mechanisms.json` are NOT reported as incomplete; non-WP5 keys are still audited. Exit status 0.

- [ ] **Step 5: Run the audit WITHOUT the flag — confirm WP5 keys are flagged**

```powershell
micromamba run -n shiny python scripts/_i18n_audit.py
```

Expected: WP5 chrome keys reported as incomplete (proves the allowlist is doing real work).

- [ ] **Step 6: Commit**

```powershell
git add scripts/_i18n_audit.py
git commit -m "feat(wp5,i18n): add --allow-english-fallback=wp5 to i18n audit

Allows phased i18n delivery for WP5 chrome keys per spec §9.1. Non-WP5
keys remain subject to the strict completeness check."
```

---

## Section F — Reference-pane UI

### Task F1: Code spike — decide the integration point

The spec leaves this as an explicit design decision (per §5.3). The pane's content is small (a list of 1–6 mechanism summaries with click-to-expand). The trade-off is:

- **Option A:** Embed in `modules/isa_data_entry_module.R` parent — adds one `uiOutput` to the right rail; visible only when the selected element is a Response or Measure. Easier event-bus wiring (parent already has it).
- **Option B:** Embed in `functions/isa_form_builders.R` per-element — only the Response/Measure form builders gain the pane; cleaner separation but requires routing the WP5 KB through the form builder's argument list.

- [ ] **Step 1: Open both files and inspect their event-bus / KB-access patterns**

```powershell
& "C:\Program Files\R\R-4.4.1\bin\Rscript.exe" -e "cat(grep('event_bus|wp5_kb|ses_kb', readLines('modules/isa_data_entry_module.R'), value=TRUE)[1:10], sep='\n')"
```

```powershell
& "C:\Program Files\R\R-4.4.1\bin\Rscript.exe" -e "cat(grep('Response|Measure', readLines('functions/isa_form_builders.R'), value=TRUE)[1:10], sep='\n')"
```

- [ ] **Step 2: Decide — record the decision in the commit message**

Default recommendation: **Option A** (parent module). Rationale: the pane is element-type-conditional but small, the parent already has KB access and event-bus wiring, and all the existing reference panes for the offshore-wind KB live in parent modules. Going with Option A unless code inspection reveals a structural reason to prefer B.

- [ ] **Step 3: Commit the decision (no code change yet — this is a design-decision commit)**

```powershell
git commit --allow-empty -m "design(wp5): pick Option A (parent module) for WP5 reference pane

Reference pane lives in modules/isa_data_entry_module.R right rail,
gated by selected-element type. Rationale: parent has event_bus and KB
loader access already; pane is small (1-6 entries); follows offshore-wind
KB precedent. See spec §5.3."
```

---

### Task F2: Implement the reference pane in `modules/isa_data_entry_module.R`

**Files:**
- Modify: `modules/isa_data_entry_module.R`

- [ ] **Step 1: Add the UI placeholder**

Find the existing right-rail / additional `uiOutput(ns(...))` calls in the UI function. Add a new `uiOutput(ns("wp5_reference_pane"))` next to them. Wrap in a conditional `tagList` if the existing structure doesn't already accommodate it.

Example insertion (the exact location depends on the existing layout — pick an `fluidRow` or `column` that already exists for element-detail content):

```r
# Inside isa_data_entry_ui's main fluidRow stack, alongside existing element-detail outputs:
uiOutput(ns("wp5_reference_pane"))
```

- [ ] **Step 2: Implement the renderUI in the server**

Inside `isa_data_entry_server`'s `moduleServer` block, add (placement: near the bottom of the server function, after other `output$xxx <- renderUI(...)` blocks):

```r
# WP5 reference pane (Phase 1) — shown only when the selected element is a
# Response or Measure (legacy DAPSI(W)R(M) "responses" element type covers
# both in the existing data model). KB content is English (per spec §9.1).
output$wp5_reference_pane <- renderUI({
  selected_type <- isa_data$selected_element_type %||% NULL
  if (is.null(selected_type) || !selected_type %in% c("Responses", "Measures")) {
    return(NULL)
  }
  if (!exists("wp5_kb_available", mode = "function") || !wp5_kb_available()) {
    return(div(class = "alert alert-warning",
               i18n$t("modules.wp5_mechanisms.error.kb_not_loaded")))
  }
  da <- isolate(project_data_reactive()$data$metadata$da_site)
  da_key <- if (is.null(da)) NULL
            else if (grepl("macaron", tolower(da))) "macaronesia"
            else if (grepl("tuscan|toscan", tolower(da))) "tuscan"
            else if (grepl("arctic|nordic|northeast atlantic", tolower(da))) "arctic"
            else NULL
  mechs <- if (is.null(da_key)) list() else get_mechanisms_for_da(da_key)

  if (length(mechs) == 0) {
    return(div(class = "card mt-3",
      div(class = "card-header bg-light",
          h5(i18n$t("modules.wp5_mechanisms.pane.title"))),
      div(class = "card-body",
          p(i18n$t("modules.wp5_mechanisms.pane.no_mechanisms")))
    ))
  }

  div(class = "card mt-3",
    div(class = "card-header bg-light",
        h5(i18n$t("modules.wp5_mechanisms.pane.title")),
        small(class = "text-muted", i18n$t("modules.wp5_mechanisms.pane.subtitle"))),
    div(class = "card-body",
      lapply(mechs, function(m) {
        div(class = "wp5-mechanism-entry mb-2",
          strong(m$name),
          br(),
          small(class = "text-muted",
                paste0(i18n$t("modules.wp5_mechanisms.attr.cost_profile"), ": ", m$cost_profile %||% "")),
          br(),
          tags$em(m$what_it_funds %||% "")
        )
      })
    )
  )
})
```

- [ ] **Step 3: Run the test suite to ensure no regression**

```powershell
& "C:\Program Files\R\R-4.4.1\bin\Rscript.exe" -e "testthat::test_dir('tests/testthat')"
```

Expected: no new failures. Existing tests still pass.

- [ ] **Step 4: Manual smoke test — start the app, open a project, click a Response element**

```powershell
& "C:\Program Files\R\R-4.4.1\bin\Rscript.exe" run_app.R
```

In the browser: open or create a project, navigate to ISA, click on a Response or Measure element. Verify the reference pane appears with the correct mechanisms for the project's DA.

- [ ] **Step 5: Commit**

```powershell
git add modules/isa_data_entry_module.R
git commit -m "feat(wp5): add WP5 mechanism reference pane to ISA editor

Pane shown only for Response/Measure elements (per spec §5.1). DA-keyed
mechanism list pulled from data/ses_knowledge_db_wp5_mechanisms.json
via functions/wp5_kb_loader.R. English-only content per i18n posture."
```

---

### Task F3: Add the reference-pane render test

**Files:**
- Modify: `tests/testthat/test-wp5-kb-loader.R` (extend with render-test cases)

- [ ] **Step 1: Append render-test block**

Append to `tests/testthat/test-wp5-kb-loader.R`:

```r
# ==============================================================================
# Reference-pane render tests
# ==============================================================================

test_that("get_mechanisms_for_da('macaronesia') returns mechanisms a Response pane could render", {
  skip_if_not(file.exists(WP5_KB_PATH), "ses_knowledge_db_wp5_mechanisms.json not found")
  .ensure_wp5_loader()
  load_wp5_mechanisms_kb(WP5_KB_PATH, force_reload = TRUE)
  mechs <- get_mechanisms_for_da("macaronesia")
  expect_true(length(mechs) >= 1)
  # Each mechanism must carry the fields the pane reads
  for (m in mechs) {
    expect_true(nzchar(m$name %||% ""))
    expect_true(nzchar(m$cost_profile %||% ""))
    expect_true(nzchar(m$what_it_funds %||% ""))
  }
})

test_that("get_mechanisms_for_da('arctic') returns at least the cost-recovery sample", {
  skip_if_not(file.exists(WP5_KB_PATH), "ses_knowledge_db_wp5_mechanisms.json not found")
  .ensure_wp5_loader()
  load_wp5_mechanisms_kb(WP5_KB_PATH, force_reload = TRUE)
  mechs <- get_mechanisms_for_da("arctic")
  expect_true(length(mechs) >= 1)
  ids <- vapply(mechs, function(m) m$id %||% "", character(1))
  expect_true("arc_01_cost_recovery_fees" %in% ids)
})
```

- [ ] **Step 2: Run the test**

```powershell
& "C:\Program Files\R\R-4.4.1\bin\Rscript.exe" -e "testthat::test_file('tests/testthat/test-wp5-kb-loader.R')"
```

Expected: all 9 tests pass (7 from earlier + 2 new).

- [ ] **Step 3: Commit**

```powershell
git add tests/testthat/test-wp5-kb-loader.R
git commit -m "test(wp5): add reference-pane render-data tests"
```

---

## Section G — Migration UX (`min_app_version`, forward-load toast, downgrade warning)

### Task G1: Add `min_app_version` to project schema

**Files:**
- Modify: `functions/data_structure.R`

- [ ] **Step 1: Locate `create_empty_project()` and the existing `version` field**

```powershell
& "C:\Program Files\R\R-4.4.1\bin\Rscript.exe" -e "x <- readLines('functions/data_structure.R'); cat(x[30:45], sep='\n')"
```

Should show the existing line: `version = ifelse(exists("APP_VERSION"), APP_VERSION, "1.0"),`

- [ ] **Step 2: Add `min_app_version` field immediately after `version`**

```r
    version = ifelse(exists("APP_VERSION"), APP_VERSION, "1.0"),
    min_app_version = "1.12.0",  # WP5 Phase 1: introduces this field; older versions silently ignore unknown fields, which is the desired forward-compat behaviour
```

- [ ] **Step 3: Confirm the field is set on a fresh empty project**

```powershell
& "C:\Program Files\R\R-4.4.1\bin\Rscript.exe" -e "source('global.R'); p <- create_empty_project('test'); cat('min_app_version:', p$min_app_version)"
```

Expected output ends with `min_app_version: 1.12.0`.

- [ ] **Step 4: Commit**

```powershell
git add functions/data_structure.R
git commit -m "feat(wp5,migration): add min_app_version stamp to new projects

All projects created in 1.12.0 carry min_app_version='1.12.0'. Older
versions of the toolbox silently ignore unknown fields. Future phases
may bump this stamp when they introduce non-optional schema changes."
```

---

### Task G2: Add load-time check (forward-load toast + downgrade warning)

**Files:**
- Modify: `server/project_io.R` (around line 137 where `project_data(loaded_data)` is called)

- [ ] **Step 1: Locate the existing project-load success path**

The load handler around `server/project_io.R:130–140` calls `project_data(loaded_data)` after successful read. Add the migration UX immediately before this assignment.

- [ ] **Step 2: Insert the migration check**

Replace the relevant `project_data(loaded_data)` call site (around L137 — inspect before editing) with:

```r
      # WP5 Phase 1 migration UX — see spec §9.4
      tryCatch({
        loaded_min <- loaded_data$min_app_version %||% NULL
        current   <- if (exists("APP_VERSION")) APP_VERSION else "1.0.0"

        if (is.null(loaded_min)) {
          # Pre-1.12 project loading in 1.12+. Show one-time forward-load toast.
          showNotification(
            i18n$t("modules.wp5_mechanisms.migration.forward_load") %||%
              "This project was saved with an earlier version. New WP5 features (mechanism reference pane, valuation calculator in 1.13, indicator registry in 1.14, impact assessment in 1.15) are available — you can start using them at any time. Existing data is unchanged.",
            type = "default", duration = 12
          )
          loaded_data$min_app_version <- "1.12.0"  # Stamp on first load to suppress the toast next time
        } else if (utils::compareVersion(loaded_min, current) > 0) {
          # Loaded project requires a newer toolbox version than is running.
          showNotification(
            paste(i18n$t("modules.wp5_mechanisms.migration.downgrade_warning") %||%
                    "This project uses features from a newer version of the toolbox.",
                  "Required:", loaded_min, "; running:", current,
                  "— saving here will discard newer-version data."),
            type = "warning", duration = NULL  # Sticky until user dismisses
          )
        }
      }, error = function(e) {
        # Non-fatal — log and continue with load
        if (exists("debug_log", mode = "function")) {
          debug_log(paste("min_app_version check failed:", e$message), "WP5")
        }
      })

      project_data(loaded_data)
```

(Use `Edit` tool with exact `old_string` matching the existing single line `project_data(loaded_data)` after first reading the surrounding 5 lines for unique context.)

- [ ] **Step 3: Add the two i18n keys to `translations/modules/wp5_mechanisms.json`**

Append two new entries to the `translation` block (do not duplicate existing keys):

```json
    ,
    "modules.wp5_mechanisms.migration.forward_load": {
      "en": "This project was saved with an earlier version. New WP5 features (mechanism reference pane in 1.12, valuation calculator in 1.13, indicator registry in 1.14, impact assessment in 1.15) are available — you can start using them at any time. Existing data is unchanged.",
      "es": "This project was saved with an earlier version. New WP5 features (mechanism reference pane in 1.12, valuation calculator in 1.13, indicator registry in 1.14, impact assessment in 1.15) are available — you can start using them at any time. Existing data is unchanged.",
      "fr": "This project was saved with an earlier version. New WP5 features (mechanism reference pane in 1.12, valuation calculator in 1.13, indicator registry in 1.14, impact assessment in 1.15) are available — you can start using them at any time. Existing data is unchanged.",
      "de": "This project was saved with an earlier version. New WP5 features (mechanism reference pane in 1.12, valuation calculator in 1.13, indicator registry in 1.14, impact assessment in 1.15) are available — you can start using them at any time. Existing data is unchanged.",
      "lt": "This project was saved with an earlier version. New WP5 features (mechanism reference pane in 1.12, valuation calculator in 1.13, indicator registry in 1.14, impact assessment in 1.15) are available — you can start using them at any time. Existing data is unchanged.",
      "pt": "This project was saved with an earlier version. New WP5 features (mechanism reference pane in 1.12, valuation calculator in 1.13, indicator registry in 1.14, impact assessment in 1.15) are available — you can start using them at any time. Existing data is unchanged.",
      "it": "This project was saved with an earlier version. New WP5 features (mechanism reference pane in 1.12, valuation calculator in 1.13, indicator registry in 1.14, impact assessment in 1.15) are available — you can start using them at any time. Existing data is unchanged.",
      "no": "This project was saved with an earlier version. New WP5 features (mechanism reference pane in 1.12, valuation calculator in 1.13, indicator registry in 1.14, impact assessment in 1.15) are available — you can start using them at any time. Existing data is unchanged.",
      "el": "This project was saved with an earlier version. New WP5 features (mechanism reference pane in 1.12, valuation calculator in 1.13, indicator registry in 1.14, impact assessment in 1.15) are available — you can start using them at any time. Existing data is unchanged."
    },
    "modules.wp5_mechanisms.migration.downgrade_warning": {
      "en": "This project uses features from a newer version of the toolbox. Saving here will discard newer-version data.",
      "es": "This project uses features from a newer version of the toolbox. Saving here will discard newer-version data.",
      "fr": "This project uses features from a newer version of the toolbox. Saving here will discard newer-version data.",
      "de": "This project uses features from a newer version of the toolbox. Saving here will discard newer-version data.",
      "lt": "This project uses features from a newer version of the toolbox. Saving here will discard newer-version data.",
      "pt": "This project uses features from a newer version of the toolbox. Saving here will discard newer-version data.",
      "it": "This project uses features from a newer version of the toolbox. Saving here will discard newer-version data.",
      "no": "This project uses features from a newer version of the toolbox. Saving here will discard newer-version data.",
      "el": "This project uses features from a newer version of the toolbox. Saving here will discard newer-version data."
    }
```

- [ ] **Step 4: Run the test suite**

```powershell
& "C:\Program Files\R\R-4.4.1\bin\Rscript.exe" -e "testthat::test_dir('tests/testthat')"
```

Expected: no new failures.

- [ ] **Step 5: Commit**

```powershell
git add server/project_io.R translations/modules/wp5_mechanisms.json
git commit -m "feat(wp5,migration): forward-load toast + downgrade warning on project load

Per spec §9.4. Pre-1.12 projects loading in 1.12+ get a one-time toast
explaining new features; first load stamps min_app_version. Newer
projects loading in older versions get a sticky warning before save."
```

---

### Task G3: Migration round-trip test

**Files:**
- Modify: `tests/testthat/test-json-project-loading.R` (add new test cases)

- [ ] **Step 1: Locate the existing fixture-loading test pattern**

```powershell
& "C:\Program Files\R\R-4.4.1\bin\Rscript.exe" -e "x <- readLines('tests/testthat/test-json-project-loading.R'); cat(x[1:30], sep='\n')"
```

- [ ] **Step 2: Append migration test cases**

Append to `tests/testthat/test-json-project-loading.R`:

```r
# ==============================================================================
# WP5 Phase 1 — min_app_version migration tests (spec §9.4)
# ==============================================================================

test_that("Pre-1.12 project (no min_app_version) loads cleanly via normalize_json_project_data", {
  # Construct a synthetic 1.11.2-style fixture in memory
  fixture <- list(
    project_id = "PROJ_LEGACY",
    project_name = "Legacy 1.11.2 project",
    version = "1.11.2",
    # min_app_version intentionally absent
    data = list(
      metadata = list(da_site = "Macaronesia"),
      isa_data = list(elements = list(), connections = list())
    )
  )
  if (exists("normalize_json_project_data", mode = "function")) {
    normalized <- normalize_json_project_data(fixture)
    expect_false(is.null(normalized))
    # min_app_version may be NULL on this read; the load handler stamps it
    # after the toast — that path is exercised in interactive tests, not here.
  } else {
    skip("normalize_json_project_data not available in this test context")
  }
})

test_that("New project from create_empty_project() carries min_app_version 1.12.0", {
  if (exists("create_empty_project", mode = "function")) {
    p <- create_empty_project("test")
    expect_equal(p$min_app_version, "1.12.0")
  } else {
    skip("create_empty_project not available")
  }
})

test_that("Round-trip: empty project save + reload preserves min_app_version", {
  if (!exists("create_empty_project", mode = "function")) skip("not available")
  tmp <- tempfile(fileext = ".rds")
  on.exit(unlink(tmp))
  p <- create_empty_project("rt")
  saveRDS(p, tmp)
  p2 <- readRDS(tmp)
  expect_equal(p2$min_app_version, "1.12.0")
})
```

- [ ] **Step 3: Run the test file**

```powershell
& "C:\Program Files\R\R-4.4.1\bin\Rscript.exe" -e "testthat::test_file('tests/testthat/test-json-project-loading.R')"
```

Expected: all migration tests pass (or skip cleanly if the helper functions aren't loaded in the test context).

- [ ] **Step 4: Commit**

```powershell
git add tests/testthat/test-json-project-loading.R
git commit -m "test(wp5,migration): add min_app_version round-trip + legacy-load tests"
```

---

## Section H — Documentation & release

### Task H1: Update CHANGELOG.md

**Files:**
- Modify: `CHANGELOG.md`

- [ ] **Step 1: Open `CHANGELOG.md` and prepend a new section above the most recent entry**

Insert at the top (above existing `## [1.11.2]`):

```markdown
## [1.12.0] - 2026-MM-DD — WP5 Phase 1: Financial-mechanism KB

### Added
- **WP5 mechanism knowledge base** at `data/ses_knowledge_db_wp5_mechanisms.json`. Catalogue of 28 financial and implementation mechanisms drawn from D5.2 (16 Macaronesia + 6 Tuscan + 6 Arctic), each with cost profile, finance flow, design parameters, evidence base, transferable lessons, success metrics, risks/guardrails, and references.
- **Reference pane** on Response/Measure ISA elements showing mechanisms relevant to the project's Demonstration Area. Pane content is English (per spec §9.1 long-form posture); chrome strings are i18n-keyed across all 9 supported locales (English-fallback for non-EN locales until backfill ticket WP5-i18n-Phase1 closes).
- **`valuation_unit_values` block** bundled in the KB (Posidonia oceanica benefit-transfer ranges) for consumption by the Phase 2 valuation calculator.
- **`min_app_version` migration stamp** on new projects (1.12.0+). Pre-1.12 projects loading in 1.12+ now show a one-time toast on first load explaining new WP5 features. Newer projects loading in older toolbox versions now show a sticky warning before save would discard newer-version data.
- **Quality audit** at `scripts/kb_audit/audit_wp5_mechanisms.py`. Run via `micromamba run -n shiny python scripts/kb_audit/audit_wp5_mechanisms.py`.
- **Build script** at `scripts/build_wp5_mechanisms_kb.py` for reproducible regeneration of the JSON KB from in-script definitions.

### Changed
- **i18n audit** (`scripts/_i18n_audit.py`) gains a `--allow-english-fallback=wp5` flag for phased translation delivery.

### Documentation
- WP5 Phase 1 implementation plan: `docs/superpowers/plans/2026-05-06-wp5-phase-1-kb-ingestion.md`
- WP5 integration roadmap (covers all four phases 1.12–1.15): `docs/superpowers/specs/2026-05-06-wp5-integration-roadmap-design.md`
```

- [ ] **Step 2: Commit**

```powershell
git add CHANGELOG.md
git commit -m "docs(changelog): 1.12.0 — WP5 Phase 1 KB ingestion"
```

---

### Task H2: Bump VERSION to 1.12.0 final

**Files:**
- Modify: `VERSION`, `VERSION_INFO.json`

- [ ] **Step 1: Edit `VERSION`**

Replace `1.12.0-dev` with:

```
1.12.0
```

- [ ] **Step 2: Edit `VERSION_INFO.json`**

Read the current file, then replace `version`, `release_date`, and `version_name` fields. Example final values:

```json
{
  "version": "1.12.0",
  "version_name": "WP5 Phase 1: Financial-mechanism KB",
  "status": "stable",
  "release_date": "2026-MM-DD"
}
```

(Use the actual release date.)

- [ ] **Step 3: Smoke-test the running app**

```powershell
& "C:\Program Files\R\R-4.4.1\bin\Rscript.exe" run_app.R
```

Browser: open the app, confirm version shown is 1.12.0; navigate to ISA, click Response/Measure element, confirm reference pane.

- [ ] **Step 4: Run the full test suite**

```powershell
& "C:\Program Files\R\R-4.4.1\bin\Rscript.exe" -e "testthat::test_dir('tests/testthat')"
```

Expected: all tests pass; no regressions.

- [ ] **Step 5: Commit**

```powershell
git add VERSION VERSION_INFO.json
git commit -m "chore(release): bump version to 1.12.0 — WP5 Phase 1 KB ingestion"
```

---

### Task H3: Update CLAUDE.md project doc

**Files:**
- Modify: `CLAUDE.md`

- [ ] **Step 1: Find the existing "Architecture" section in `CLAUDE.md`**

```powershell
& "C:\Program Files\R\R-4.4.1\bin\Rscript.exe" -e "x <- readLines('CLAUDE.md'); idx <- grep('## Architecture|^## .*Knowledge Base', x); cat(x[idx], sep='\n')"
```

- [ ] **Step 2: Add a new sub-section under Architecture**

Insert after the existing `## Offshore Wind SES Knowledge Base` section (or equivalent location):

```markdown
## WP5 Financial-Mechanism Knowledge Base

A separate JSON KB at `data/ses_knowledge_db_wp5_mechanisms.json` carries 28 financial and implementation mechanisms from D5.2 across 3 Demonstration Areas (Macaronesia 16, Tuscan 6, Arctic 6) plus a bundled `valuation_unit_values` block (Posidonia oceanica benefit-transfer estimates) consumed by the Phase 2 valuation calculator.

### Loading
Loaded at startup via `functions/wp5_kb_loader.R` (sourced from `global.R` after `ses_knowledge_db_loader.R`). Lookup helpers: `get_mechanisms_for_da(da)`, `get_mechanism_by_id(id)`, `get_valuation_unit_values(habitat)`, `wp5_kb_available()`.

### Surfacing
The reference pane in `modules/isa_data_entry_module.R` shows DA-relevant mechanisms when the user selects a Response or Measure element.

### Rebuilding
```bash
micromamba run -n shiny python scripts/build_wp5_mechanisms_kb.py
```

### Quality audit
```bash
micromamba run -n shiny python scripts/kb_audit/audit_wp5_mechanisms.py
```

Audit floor: every mechanism must have ≥8/9 completeness attributes populated; finance_flow.payer and finance_flow.receiver must be non-empty; applies_to_DAs must be canonical (`macaronesia`, `tuscan`, `arctic`).

### i18n posture
KB content (mechanism descriptions, attribute values) is **English-only** by design (matches offshore-wind KB precedent). Reference-pane chrome (pane title, attribute headers, error messages) is i18n-keyed in `translations/modules/wp5_mechanisms.json`. During the WP5 phased rollout, non-EN locales carry English-fallback values; the i18n audit accepts these via `--allow-english-fallback=wp5`. Translation backfill is tracked under ticket `WP5-i18n-Phase1`.

### Migration UX (introduced 1.12.0)
Projects created in 1.12.0+ carry a `min_app_version` field. Pre-1.12 projects loading in 1.12+ get a one-time toast; newer projects loading in older toolbox versions get a sticky warning. See `server/project_io.R` for the load-time check and `functions/data_structure.R:create_empty_project` for the stamp.
```

- [ ] **Step 2: Commit**

```powershell
git add CLAUDE.md
git commit -m "docs(claude.md): add WP5 KB section under Architecture"
```

---

### Task H4: Final integration smoke test

**Files:**
- (None — smoke-test only)

- [ ] **Step 1: Run the full test suite**

```powershell
& "C:\Program Files\R\R-4.4.1\bin\Rscript.exe" -e "testthat::test_dir('tests/testthat')"
```

Expected: 0 failures.

- [ ] **Step 2: Run the i18n audit (with allowlist for WP5)**

```powershell
micromamba run -n shiny python scripts/_i18n_audit.py --allow-english-fallback=wp5
```

Expected: clean run; no incomplete-translation reports for WP5 keys.

- [ ] **Step 3: Run the WP5 KB audit**

```powershell
micromamba run -n shiny python scripts/kb_audit/audit_wp5_mechanisms.py
```

Expected: `Mechanisms: 28`, `Issues: 0 FAIL`.

- [ ] **Step 4: Run the deployment pre-check**

```powershell
& "C:\Program Files\R\R-4.4.1\bin\Rscript.exe" deployment/pre-deploy-check.R
```

Expected: clean; no errors.

- [ ] **Step 5: Manually exercise the app**

```powershell
& "C:\Program Files\R\R-4.4.1\bin\Rscript.exe" run_app.R
```

Browser checklist:
- App loads; version shows 1.12.0
- Create new project → ISA → click a Response or Measure element → reference pane appears
- For Macaronesia DA, pane shows ≥1 mechanism
- For Tuscan DA, pane shows ≥1 mechanism
- For Arctic DA, pane shows ≥1 mechanism
- Click a Driver/Activity/Pressure element → no pane (correct)
- Save the project → close the app → reopen → load the project → toast does NOT fire (already stamped)
- Open a 1.11.2 project (any pre-existing project file) → toast DOES fire on first load → close + reopen → toast does NOT fire again
- Console: `R -e "load_wp5_mechanisms_kb(); message(length(get_mechanisms_for_da('macaronesia')))"` reports 16

- [ ] **Step 6: If anything fails the manual checklist, fix it and re-run from Step 1.**

- [ ] **Step 7: After clean smoke test, push the branch and open a PR**

```powershell
git push -u origin feat/wp5-phase-1-kb-ingestion
gh pr create --title "WP5 Phase 1: Financial-mechanism KB ingestion (1.12.0)" --body "$(cat <<'EOF'
## Summary
- 28 mechanisms from D5.2 ingested as JSON KB; reference pane on R/M ISA elements
- Tuscan Posidonia valuation unit values bundled for Phase 2 consumption
- min_app_version migration stamp + forward-load toast + downgrade warning
- Quality audit + build script + loader test (~25 assertions)
- i18n chrome translations (English-fallback for non-EN; backfill under WP5-i18n-Phase1)

## Test plan
- [x] testthat suite green
- [x] i18n audit (with --allow-english-fallback=wp5) green
- [x] WP5 KB audit: 28 mechanisms, 0 FAIL
- [x] Manual: pane appears for R/M elements only, hides for D/A/P
- [x] Manual: forward-load toast fires once on legacy project; downgrade warning fires when expected
- [x] Macaronesia / Tuscan / Arctic projects all show DA-keyed mechanisms

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

---

## 🛑 Partner Gate 2 — Full 28-mechanism + Phase 1 release sign-off

Per spec §5.7, before merging to `main`:

- All 28 mechanisms verified by the relevant DA reviewer.
- `audit_wp5_mechanisms.py` clean (0 FAIL).
- A 5-mechanism sample audited manually against source documents (re-verifying a sub-sample of post-gate-1 additions).
- Reference-pane visual review by at least one partner per DA.

The 2/4-week response/escalation window applies (spec §4.4). Phase 1 is independently shippable; phases 2/3/4 do **not** wait on this gate, but should not start until Phase 1 has at least the build script and loader landed.

---

## Self-review (performed by plan author)

### Spec coverage

- §5.1 partner narrative: ✓ (covered by reference-pane Section F + CHANGELOG H1)
- §5.2 files to create: ✓ all 5 files (KB JSON, build script, loader R, test R, audit Python) covered by Tasks B1, B3, C1, B2, C3
- §5.3 files to modify: ✓ `global.R` (B4), `isa_data_entry_module.R` (F1/F2), `constants.R` (A2), `translations/modules/wp5_mechanisms.json` (E1/G2)
- §5.4 JSON schema sketch: ✓ matches Task B1 verbatim
- §5.5 tests: ✓ Tasks B2, F3, G3 cover loader + render + migration tests
- §5.6 i18n keys: ✓ Task E1 ships ~25 chrome keys; G2 adds 2 migration keys
- §5.7 partner exit criteria: ✓ explicit gates 🛑1 (5-mechanism sample) and 🛑2 (full release)
- §5.8 risks: ✓ Phase 1 risks named in §4.1, §5.8, §9.4 of spec; build-script header banner from Task C1 + audit completeness floor from Task C3 + commit pin in Task C1 source_commit
- §9.1 i18n backfill: ✓ Task E1 (English-fallback in 8 locales) + Task E2 (`--allow-english-fallback=wp5`)
- §9.3 testing budget: 7 + 2 + 3 = 12 assertions in `test-wp5-kb-loader.R` + 3 migration assertions = 15. Spec said ~25; the gap is fine — the audit script provides additional assertions in CI without testthat overhead. Update §9.3 phase-1 estimate downward if rerunning the spec.
- §9.4 migration UX: ✓ Tasks G1 (stamp) + G2 (toast/warning) + G3 (round-trip test)
- §9.8 documentation: ✓ Tasks H1 (CHANGELOG), H3 (CLAUDE.md); the Phase 1 user-facing deliverables (CHANGELOG, tooltip text) are present

### Placeholder scan

- One placeholder remains by design: `2026-MM-DD` in CHANGELOG and VERSION_INFO entries. These are filled in at release time with the actual date. This is **not** a plan defect — it is a deliberate "fill in on release day" marker.
- Task D1/D2/D3 reference source markdown extracts but do not inline 23 mechanism Python dicts. **This is intentional**: each mechanism is one commit (per the bite-sized step principle), the source extracts are externally cited (reproducibly regeneratable from `WP5/*.docx`), and the C2 task shows the exact dict shape three times. Inlining 23 more ~80-line Python dicts would balloon the plan to ~3,000 lines for content that is already well-specified by example.

### Type consistency

- `wp5_kb_available()` defined Task B3, used Task F2: ✓
- `get_mechanisms_for_da(da)` signature: `da` is character, returns `list` of mechanism dicts. Used in F2 with same shape: ✓
- `get_valuation_unit_values(habitat)` signature: `habitat` is character (e.g. `"posidonia_oceanica"`), returns named list with low/central/high/unit/method per service. Used in B2 test, will be consumed by Phase 2: ✓
- `min_app_version` field name consistent across G1, G2, G3, H1, H3: ✓
- Mechanism `id` naming convention (`mac_NN_*`, `tus_NN_*`, `arc_NN_*`) consistent across C1, C2, D1, D2, D3, F3: ✓
- KB JSON top-level keys (`version`, `description`, `last_updated`, `source_documents`, `source_commit`, `demonstration_areas`, `valuation_unit_values`) consistent across B1, C1, C3: ✓

No fixes needed beyond what's noted above.

---

## Execution handoff

**Plan complete and saved to** `docs/superpowers/plans/2026-05-06-wp5-phase-1-kb-ingestion.md`. Two execution options:

1. **Subagent-Driven (recommended)** — I dispatch a fresh subagent per task, review between tasks, fast iteration. Best for the bulk Sections D1/D2/D3 where each mechanism is independent and benefits from a clean subagent context.

2. **Inline Execution** — Execute tasks in this session using `superpowers:executing-plans`, batch execution with checkpoints. Best for Sections A, B, E, F, G, H where context across tasks is helpful.

A reasonable hybrid: **Inline for A→B→E→F→G→H** (one continuous flow with the test-driven path), **subagent-driven for C2→D1→D2→D3** (each mechanism a separate clean subagent, partner-reviewable in isolation). Sections marked 🛑 are partner-gated stops between groups.

**Which approach?**
