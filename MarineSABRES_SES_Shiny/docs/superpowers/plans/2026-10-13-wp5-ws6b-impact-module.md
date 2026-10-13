# WP5 WS-6b: Impact-assessment module (UI) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship the user-facing 7-step impact-assessment wizard (D5.2 §1.4) on top of the WS-6a data layer, so a partner can characterise a case, define scenarios, scope elements and indicators, fill the criterion × scenario matrix with the ordinal rubric, record uncertainty, trade-offs and recommendations, and have it all saved in the project.

**Architecture:** One Shiny module (`modules/impact_assessment_module.R`) owns the wizard and writes project data only through the pure WS-6a model (`set_impact_assessment()`); every rendering decision that can be pure lives in a new `functions/impact_assessment_view.R` so the matrix, glyphs, problem messages and reference tables are unit-tested without Shiny. Part A (Tasks 1–6) ships a usable wizard for steps 1, 2, 3 and 7 plus the prerequisite fix that stops other modules wiping the assessment; Part B (Tasks 7–10) adds the matrix, the reference panels, step gating and the 1.25.0 release. Nothing is stubbed: a step that is not implemented yet is not shown in the step bar until its task lands.

**Tech Stack:** R ≥ 4.4.1, shiny, bs4Dash, shiny.i18n (9 languages), jsonlite, testthat; WS-6a model (`functions/impact_assessment_model.R`, `functions/impact_reference.R`), WS-1 vocabulary (`functions/wp5_vocabulary.R`), WS-2 mechanism KB (`functions/wp5_kb_loader.R`), WS-4 indicator registry (`functions/indicator_registry.R`).

**Spec:** `docs/superpowers/specs/2026-10-11-wp5-practical-integration-specs.md` §WS-6 and principles P1–P7; roadmap `docs/superpowers/specs/2026-05-06-wp5-integration-roadmap-design.md` §8; decisions in `docs/superpowers/plans/2026-10-13-wp5-ws6b-handoff.md`; code facts in `docs/superpowers/plans/2026-10-13-wp5-ws6b-code-map.md`.

## Global Constraints

- Module signature `(id, project_data_reactive, i18n, event_bus = NULL)`; UI starts with `tryCatch(shiny.i18n::usei18n(i18n$translator %||% i18n), error = function(e) NULL)` (spec P6).
- Store codes, translate on display (P2). Rubric labels come from `wp5_vocab_label(<vocab>, code, i18n)`, vocabularies: `criteria`, `direction`, `magnitude`, `timing`, `confidence`, `evidence`, `uncertainty_driver`, `indicator_role`, `subdimension`.
- Ordinal values only (P4); the one ordinal→numeric map (fill intensity) is `impact_fill_level()` and is marked `toolbox_extension` in its roxygen and badged in the UI.
- Published values are shown, never recomputed (P3): Arctic revenue tables are read-only with the partner-question-2 note.
- Reference data is not project data (P5): copying a reference cell goes through `impact_copy_reference_cell()`, which records `reference$ref_version`.
- Provenance badges (P1) via `provenance_badge(provenance, i18n)` wherever reference text, copied cells or toolbox-extension values appear.
- Every new `functions/*.R` file is `source()`d in `global.R` with a literal `source("functions/<file>.R", local = FALSE)` line (test-functions-sourced-in-app.R).
- Any NEW stored field needs `.impact_fill_*` + `normalize_impact_assessment()` changes AND raising `IMPACT_SCHEMA_VERSION` and `WP5_IMPACT_MIN_APP_VERSION` together. This plan adds NO stored fields; `displaced_pressure_id` already exists.
- Never emit `emit_isa_change` / `emit_cld_update` for assessment writes (they regenerate the CLD and invalidate analysis).
- i18n: every chrome key in all 9 languages (`en, es, fr, de, lt, pt, it, no, el`); `micromamba run -n shiny python scripts/_i18n_audit.py` must report `missing=0 hardcoded=0`; dynamic keys need `# i18n-ref: <key>` sentinels; non-English values must not equal English for sentences ≥ 30 chars (test-i18n-english-fallback.R).
- Tests: `source_for_test()`, re-bind the real server from `.GlobalEnv`, never end a behaviour test in `expect_true(TRUE)` (P7). Each `testthat::test_file()` bootstraps the app (~2 min); run several files in one Rscript; the full suite only in alphabetical chunks (one chunk per Rscript) or it is reaped for low memory.
- Release: WS-6a + WS-6b ship together as **1.25.0** (`WP5_IMPACT_MIN_APP_VERSION` is already "1.25.0").
- Menu placement (decision): sub-item of "Response & Validation", `tabName = "response_impact"`, after Scenario Builder. Reason: WS-5 (valuation) already sits there, the Response menu is the WP5 home, and the assessment evaluates Responses/scenarios, not the network structure.
- Displaced pressure (decision): Part A stores a reference to an EXISTING P element chosen from a list (`displaced_pressure_id`); creating a new P element from this module is descoped because of the ISA module's local-copy overwrite hazard (code map §5). Record in CHANGELOG.

## Review Focus

1. A project whose `da_site` is free text such as "Azores (Macaronesia)" or a list — `wp5_da_for_project()` must still resolve "macaronesia"; a project with no DA must get an empty assessment, not an error. Test in Task 2.
2. An ISA with canonical `ID`/`Name` columns (fresh ISA entry) versus lowercase `id`/`name` (JSON load) — the element picker must list both. Test in Task 6.
3. Loading a project saved by 1.24.0 (no assessment block) and then a 1.25.0 project with one — the module must create/replace its state on `project_loaded` and never write an empty assessment into a project the user never touched (no `min_app_version` stamp without user action). Test in Task 3.
4. A scenario code typed with spaces or symbols ("S 1!") — the model raises `invalid_scenario_code`; the UI must show the translated message and keep the form. Test in Task 5.
5. Clicking "Copy from WP5 reference" twice, or for a user-added scenario that reuses the code "S1" — the model raises `cell_not_empty` / `scenario_not_reference`; both must surface as notifications, never as a crash. Test in Task 7.

---

## Task 0: Branch setup (not a code task)

- [ ] In the worktree `C:/Users/arturas.baziukas/wt-ws6`, on `feat/wp5-ws6b-impact-module`, merge current `main` (it carries PRs #105–#107 since 80c61f6):

```bash
git -C C:/Users/arturas.baziukas/wt-ws6 fetch origin
git -C C:/Users/arturas.baziukas/wt-ws6 merge origin/main
```

Expected: a clean merge, or a CHANGELOG-only conflict (keep both `[Unreleased]` blocks).

- [ ] Verify the baseline: `Rscript -e "testthat::test_file('tests/testthat/test-impact-assessment-storage.R')"` passes.

---

## Part A — prerequisite fix, helpers, wizard shell, steps 1, 2, 3, 7

### Task 1: Stop wholesale `data$analysis` wipes

**Files:**
- Modify: `functions/data_structure.R` (append after `create_empty_project`, ~line 126 block end)
- Modify: `functions/reactive_pipeline.R:236-244`
- Modify: `modules/import_data_module.R:573`
- Modify: `modules/ses_models_module.R:777`
- Test: `tests/testthat/test-analysis-clear-preserves-wp5.R`

**Interfaces:**
- Produces: `clear_analysis_results(project, reason = NULL)` → the same project list with `data$analysis$loops` and `data$analysis$metrics` set to NULL, `cleared_at`/`reason` set only when `reason` is given, and every other `data$analysis` key (notably `scenarios`, `impact_assessment`) untouched.

- [ ] **Step 1: Write the failing unit test**

```r
# tests/testthat/test-analysis-clear-preserves-wp5.R
library(testthat)
library(shiny)
source_for_test(c("server/event_bus_setup.R", "functions/reactive_pipeline.R"))

project_with_analysis <- function() {
  p <- create_empty_project("wipe test")
  p$data$analysis <- list(
    loops = data.frame(LoopID = 1L),
    metrics = list(density = 0.1),
    scenarios = list(list(id = "sc1", name = "Scenario 1")),
    impact_assessment = new_impact_assessment("macaronesia")
  )
  p
}

test_that("clear_analysis_results drops loops and metrics but keeps WS-0 scenarios and the WS-6a assessment", {
  p <- clear_analysis_results(project_with_analysis(), reason = "Data changed")
  expect_null(p$data$analysis$loops)
  expect_null(p$data$analysis$metrics)
  expect_identical(p$data$analysis$reason, "Data changed")
  expect_true(inherits(p$data$analysis$cleared_at, "POSIXct"))
  expect_identical(p$data$analysis$scenarios[[1]]$id, "sc1")
  expect_identical(p$data$analysis$impact_assessment$da, "macaronesia")
})

test_that("clear_analysis_results tolerates a missing or non-list analysis block and omits reason fields when none given", {
  p <- create_empty_project("empty")
  p$data$analysis <- NULL
  out <- clear_analysis_results(p)
  expect_true(is.list(out$data$analysis))
  expect_false("reason" %in% names(out$data$analysis))
  p$data$analysis <- "garbage"
  expect_true(is.list(clear_analysis_results(p)$data$analysis))
})
```

- [ ] **Step 2: Run it to verify it fails**

Run: `Rscript -e "testthat::test_file('tests/testthat/test-analysis-clear-preserves-wp5.R')"`
Expected: FAIL with `could not find function "clear_analysis_results"`.

- [ ] **Step 3: Implement the helper in `functions/data_structure.R`**

Append after `create_empty_project()`:

```r
#' Drop recomputable analysis results, keep user work
#'
#' Loops and metrics are recomputed from the CLD and must be cleared when it
#' changes. Everything else under data$analysis is user work (WS-0 scenarios,
#' WS-6 impact assessment) and survives. Replaces the three former wholesale
#' `data$analysis <- list(loops = NULL, metrics = NULL)` writes, which silently
#' destroyed those blocks (WS-6a final review).
#'
#' @param project Project list (the value of project_data_reactive())
#' @param reason Optional character; when given, cleared_at and reason are recorded
#' @return The project list
clear_analysis_results <- function(project, reason = NULL) {
  a <- project$data$analysis
  if (!is.list(a)) a <- list()
  a$loops <- NULL
  a$metrics <- NULL
  if (!is.null(reason)) {
    a$cleared_at <- Sys.time()
    a$reason <- as.character(reason)
  }
  project$data$analysis <- a
  project
}
```

- [ ] **Step 4: Replace the three wipe sites**

`functions/reactive_pipeline.R:236-244` — replace

```r
      data$data$analysis <- list(
        loops = NULL,
        metrics = NULL,
        cleared_at = Sys.time(),
        reason = "Data changed"
      )
```
with
```r
      data <- clear_analysis_results(data, reason = "Data changed")
```

`modules/import_data_module.R:573` — replace `project_data$data$analysis <- list(loops = NULL, metrics = NULL)` with `project_data <- clear_analysis_results(project_data)`.

`modules/ses_models_module.R:777` — the same replacement (`project_data <- clear_analysis_results(project_data)`).

- [ ] **Step 5: Add the pipeline regression test (real Observer 2)**

Append to the test file:

```r
test_that("reactive pipeline invalidation keeps scenarios and the impact assessment", {
  pd <- reactiveVal(project_with_analysis())
  testServer(
    function(input, output, session) {
      bus <- create_event_bus(session_id = "wipe")
      setup_reactive_pipeline(pd, bus)
      bus
    },
    {
      bus <- session$getReturned()
      bus$emit_cld_update("reactive_pipeline")
      session$flushReact()
      a <- pd()$data$analysis
      expect_null(a$loops)
      expect_identical(a$reason, "Data changed")
      expect_identical(a$scenarios[[1]]$id, "sc1")
      expect_identical(a$impact_assessment$da, "macaronesia")
    }
  )
})

test_that("no wholesale analysis assignment remains in the three former sites", {
  files <- c("functions/reactive_pipeline.R", "modules/import_data_module.R", "modules/ses_models_module.R")
  for (f in files) {
    src <- readLines(file.path(PROJECT_ROOT, f), warn = FALSE)
    expect_false(any(grepl("analysis <- list(loops = NULL", src, fixed = TRUE)), label = f)
  }
})
```

Note: `setup_reactive_pipeline(project_data, event_bus)` installs observers in the calling reactive domain; `testServer` provides one. If Observer 2 uses `shinyjs::show`, it is already wrapped in `tryCatch` and is harmless without the JS side.

- [ ] **Step 6: Run the file, then the pipeline and import tests**

Run: `Rscript -e "for (f in c('tests/testthat/test-analysis-clear-preserves-wp5.R','tests/testthat/test-reactive-pipeline.R','tests/testthat/test-import-data-module.R','tests/testthat/test-ses-models-module.R')) testthat::test_file(f)"`
Expected: all pass.

- [ ] **Step 7: Commit**

```bash
git add functions/data_structure.R functions/reactive_pipeline.R modules/import_data_module.R modules/ses_models_module.R tests/testthat/test-analysis-clear-preserves-wp5.R
git commit -m "fix(analysis): clear only loops/metrics on CLD change; keep WS-0 scenarios and the impact assessment (WS-6b task 1)"
```

---

### Task 2: `wp5_da_for_project()` helper

**Files:**
- Modify: `functions/wp5_vocabulary.R` (append after `wp5_vocab_label`)
- Modify: `modules/response_module.R:994-1000` (use the helper)
- Test: `tests/testthat/test-wp5-vocabulary.R` (append)

**Interfaces:**
- Produces: `wp5_da_for_project(project)` → `""` or one of `WP5_DA_CONTEXTS` (`"macaronesia"`, `"tuscan"`, `"arctic"`). Reads `project$data$metadata$da_site`, falling back to `project$metadata$da_site`; accepts character or list; case-insensitive; `grepl("macaron")`, `grepl("tuscan|toscan")`, `grepl("arctic|nordic|northeast atlantic")`.

- [ ] **Step 1: Failing tests** (append to `tests/testthat/test-wp5-vocabulary.R`)

```r
test_that("wp5_da_for_project maps DA_SITES values and free text to WP5_DA_CONTEXTS", {
  mk <- function(site) { p <- create_empty_project("x"); p$data$metadata$da_site <- site; p }
  expect_identical(wp5_da_for_project(mk("Macaronesia")), "macaronesia")
  expect_identical(wp5_da_for_project(mk("Azores (Macaronesia)")), "macaronesia")
  expect_identical(wp5_da_for_project(mk("Tuscan Archipelago")), "tuscan")
  expect_identical(wp5_da_for_project(mk("Arcipelago Toscano")), "tuscan")
  expect_identical(wp5_da_for_project(mk("Arctic Northeast Atlantic")), "arctic")
  expect_identical(wp5_da_for_project(mk(list("Macaronesia"))), "macaronesia")
  expect_identical(wp5_da_for_project(mk("Baltic Sea")), "")
  expect_identical(wp5_da_for_project(mk(NULL)), "")
  expect_identical(wp5_da_for_project(NULL), "")
  legacy <- list(metadata = list(da_site = "Macaronesia"))
  expect_identical(wp5_da_for_project(legacy), "macaronesia")
})
```

- [ ] **Step 2: Run to verify it fails** — `Rscript -e "testthat::test_file('tests/testthat/test-wp5-vocabulary.R')"` → `could not find function "wp5_da_for_project"`.

- [ ] **Step 3: Implement**

```r
#' WP5 demonstration-area key for a project
#'
#' Reads data$metadata$da_site (PIMS module) or the legacy metadata$da_site and
#' maps it onto WP5_DA_CONTEXTS. Replaces the inline mapping that lived in
#' response_module.R. "" when the project has no recognised DA.
#' @param project Project list (may be NULL)
#' @return "" or one of WP5_DA_CONTEXTS
wp5_da_for_project <- function(project) {
  if (is.null(project)) return("")
  site <- project$data$metadata$da_site %||% project$metadata$da_site %||% NULL
  if (is.null(site) || length(site) == 0) return("")
  s <- tolower(paste(as.character(unlist(site)), collapse = " "))
  if (!nzchar(trimws(s))) return("")
  if (grepl("macaron", s)) return("macaronesia")
  if (grepl("tuscan|toscan", s)) return("tuscan")
  if (grepl("arctic|nordic|northeast atlantic", s)) return("arctic")
  ""
}
```

- [ ] **Step 4: Use it in `modules/response_module.R:994-1000`** — replace the `da`/`da_lc`/`da_key` block with:

```r
      da_key <- wp5_da_for_project(pd)
      if (!nzchar(da_key)) da_key <- NULL
```

- [ ] **Step 5: Run** `test-wp5-vocabulary.R` and `test-response-module.R` → pass.

- [ ] **Step 6: Commit**

```bash
git add functions/wp5_vocabulary.R modules/response_module.R tests/testthat/test-wp5-vocabulary.R
git commit -m "feat(wp5): wp5_da_for_project() shared DA resolver (WS-6b task 2)"
```

---

### Task 3: Module shell, persistence, wiring, Tuscan empty state

**Files:**
- Create: `modules/impact_assessment_module.R`
- Create: `functions/impact_assessment_view.R` (pure helpers; grows in Part B)
- Create: `translations/modules/impact_assessment.json`
- Modify: `global.R` (after line 714: `source("functions/impact_assessment_view.R", local = FALSE)`)
- Modify: `app.R:99` area (add `"modules/impact_assessment_module.R",   # WP5 impact assessment (WS-6b)` to the module source list), `app.R:517` (add `bs4TabItem(tabName = "response_impact", impact_assessment_ui("impact_assess", i18n)),` after the scenario builder tab), `app.R:1062` (add `impact_assessment_server("impact_assess", project_data, session_i18n, event_bus = event_bus)`)
- Modify: `functions/ui_sidebar.R:399-404` (add `bs4SidebarMenuSubItem(safe_t("ui.sidebar.impact_assessment", i18n_obj = i18n), tabName = "response_impact")` after the scenario builder item, inside `response_items`)
- Modify: `translations/ui/sidebar.json` (key `ui.sidebar.impact_assessment`, 9 languages)
- Test: `tests/testthat/test-impact-assessment-module.R`

**Interfaces:**
- Produces: `impact_assessment_ui(id, i18n)`, `impact_assessment_server(id, project_data_reactive, i18n, event_bus = NULL)` returning `reactive(rv$ia)`.
- Server internals used by later tasks: `rv <- reactiveValues(ia = NULL, step = 1L, dirty = FALSE)`; `commit(ia)` stores `rv$ia <- ia` and writes `project_data_reactive(set_impact_assessment(project_data_reactive(), ia))`; `da <- reactive(wp5_da_for_project(project_data_reactive()))`; steps are rendered by `output$step_body` switching on `rv$step`; the step bar is `impact_step_bar(active, available, i18n, ns)` from the view file.
- View helpers (pure, `functions/impact_assessment_view.R`): `impact_step_keys()` → named character vector `c("1"="characterisation", ...,"7"="recommendations")`; `impact_step_bar(active, available, i18n, ns)` → tag; `impact_da_banner(da, status, i18n)` → tag.

- [ ] **Step 1: Failing tests**

```r
# tests/testthat/test-impact-assessment-module.R
library(testthat)
library(shiny)
load_wp5_mechanisms_kb(file.path(PROJECT_ROOT, "data", "ses_knowledge_db_wp5_mechanisms.json"), force_reload = TRUE)
source_for_test(c("functions/ui_components.R", "functions/impact_assessment_view.R",
                  "modules/impact_assessment_module.R"))
impact_assessment_server <- get("impact_assessment_server", envir = .GlobalEnv)
impact_assessment_ui <- get("impact_assessment_ui", envir = .GlobalEnv)

mk_project <- function(da = "Macaronesia") { p <- create_empty_project("ia"); p$data$metadata$da_site <- da; p }
srv <- function(p) list(project_data_reactive = shiny::reactiveVal(p), i18n = make_test_i18n(), event_bus = NULL)

test_that("UI returns namespaced tags with the step bar and body outputs", {
  ui <- as.character(impact_assessment_ui("ia", make_test_i18n()))
  for (id in c("ia-step_bar", "ia-step_body", "ia-da_banner")) expect_match(ui, id, fixed = TRUE)
  expect_match(ui, "modules.impact_assessment.title", fixed = TRUE)
})

test_that("server has the conventional signature", {
  expect_equal(names(formals(impact_assessment_server)), c("id", "project_data_reactive", "i18n", "event_bus"))
})

test_that("a Macaronesia project starts from the WP5 reference scenarios without writing the project until the user acts", {
  args <- srv(mk_project("Macaronesia"))
  testServer(impact_assessment_server, args = args, {
    session$flushReact()
    expect_identical(impact_scenario_codes(rv$ia), c("S1", "S2", "S3", "S4"))
    expect_identical(rv$ia$baseline_code, "S1")
    expect_null(get_impact_assessment(args$project_data_reactive()))   # not stamped yet
    expect_match(as.character(output$da_banner$html), "modules.impact_assessment.da.macaronesia", fixed = TRUE)
  })
})

test_that("a Tuscan project shows the valuation-only empty state and no step body", {
  testServer(impact_assessment_server, args = srv(mk_project("Tuscan Archipelago")), {
    session$flushReact()
    html <- as.character(output$step_body$html)
    expect_match(html, "modules.impact_assessment.tuscan_empty", fixed = TRUE)
    expect_match(html, "response_valuation", fixed = TRUE)
  })
})

test_that("a project without a DA gets an empty assessment and the no-DA note", {
  testServer(impact_assessment_server, args = srv(mk_project(NULL)), {
    session$flushReact()
    expect_identical(rv$ia$da, "")
    expect_length(impact_scenario_codes(rv$ia), 0L)
    expect_match(as.character(output$da_banner$html), "modules.impact_assessment.da.none", fixed = TRUE)
  })
})

test_that("an existing assessment in the project is loaded, and reloaded on project_loaded", {
  p <- set_impact_assessment(mk_project("Macaronesia"), impact_set_section(new_impact_assessment("macaronesia"), "characterisation", list(focal_issue = "Corridor")))
  args <- srv(p); bus <- create_event_bus("ia-load"); args$event_bus <- bus
  testServer(impact_assessment_server, args = args, {
    session$flushReact()
    expect_identical(rv$ia$characterisation$focal_issue, "Corridor")
    p2 <- set_impact_assessment(mk_project("Macaronesia"), impact_set_section(new_impact_assessment("macaronesia"), "characterisation", list(focal_issue = "Other")))
    args$project_data_reactive(p2); bus$emit_project_loaded("test"); session$flushReact()
    expect_identical(rv$ia$characterisation$focal_issue, "Other")
  })
})

test_that("app.R and the sidebar wire the module under Response & Validation", {
  app <- paste(readLines(file.path(PROJECT_ROOT, "app.R"), warn = FALSE), collapse = "\n")
  expect_match(app, 'bs4TabItem(tabName = "response_impact", impact_assessment_ui("impact_assess", i18n))', fixed = TRUE)
  expect_match(app, 'impact_assessment_server("impact_assess", project_data, session_i18n', fixed = TRUE)
  sb <- paste(readLines(file.path(PROJECT_ROOT, "functions", "ui_sidebar.R"), warn = FALSE), collapse = "\n")
  expect_match(sb, 'tabName = "response_impact"', fixed = TRUE)
  g <- paste(readLines(file.path(PROJECT_ROOT, "global.R"), warn = FALSE), collapse = "\n")
  expect_match(g, 'source("functions/impact_assessment_view.R", local = FALSE)', fixed = TRUE)
})

test_that("every modules.impact_assessment.* key used in the module exists in all 9 languages", {
  src <- paste(readLines(file.path(PROJECT_ROOT, "modules", "impact_assessment_module.R"), warn = FALSE),
               readLines(file.path(PROJECT_ROOT, "functions", "impact_assessment_view.R"), warn = FALSE), collapse = "\n")
  keys <- unique(regmatches(src, gregexpr("modules\\.impact_assessment\\.[A-Za-z0-9_.]+", src))[[1]])
  tr <- jsonlite::fromJSON(file.path(PROJECT_ROOT, "translations", "modules", "impact_assessment.json"), simplifyVector = FALSE)$translation
  langs <- c("en", "es", "fr", "de", "lt", "pt", "it", "no", "el")
  for (k in keys) {
    expect_true(k %in% names(tr), label = k)
    for (l in langs) expect_true(nzchar(tr[[k]][[l]] %||% ""), label = paste(k, l))
  }
})
```

Note on `emit_project_loaded`: the event bus exposes `emit_project_loaded(source)` / `on_project_loaded()` (code map §2). If the emit function name differs, read `server/event_bus_setup.R` and use the exact name in both test and module.

- [ ] **Step 2: Run to verify failure** — `could not find function "impact_assessment_ui"`.

- [ ] **Step 3: Create `functions/impact_assessment_view.R` (shell part)**

```r
# functions/impact_assessment_view.R
# Pure rendering helpers for the WP5 impact-assessment module (WS-6b). No
# reactivity here so the matrix, glyphs and messages are unit-testable.

#' Step keys of the D5.2 §1.4 flow, named by step number
impact_step_keys <- function() {
  c("1" = "characterisation", "2" = "scenarios", "3" = "scoping", "4" = "matrix",
    "5" = "uncertainty", "6" = "trade_offs", "7" = "recommendations")
}

#' Step bar: one button per available step; the active one is highlighted.
#' @param active Integer step number
#' @param available Integer vector of steps that have a body (grows per task)
#' @param ns Namespace function
impact_step_bar <- function(active, available, i18n, ns) {
  keys <- impact_step_keys()
  # i18n-ref: modules.impact_assessment.step.characterisation
  # i18n-ref: modules.impact_assessment.step.scenarios
  # i18n-ref: modules.impact_assessment.step.scoping
  # i18n-ref: modules.impact_assessment.step.matrix
  # i18n-ref: modules.impact_assessment.step.uncertainty
  # i18n-ref: modules.impact_assessment.step.trade_offs
  # i18n-ref: modules.impact_assessment.step.recommendations
  items <- lapply(available, function(n) {
    cls <- if (n == active) "btn btn-primary btn-sm me-1 mb-1" else "btn btn-outline-primary btn-sm me-1 mb-1"
    actionButton(ns(paste0("goto_step_", n)), paste0(n, ". ", i18n$t(paste0("modules.impact_assessment.step.", keys[[as.character(n)]]))), class = cls)
  })
  div(class = "impact-step-bar", items)
}

#' DA banner: which demonstration area and whether WP5 reference data exists
impact_da_banner <- function(da, status, i18n) {
  # i18n-ref: modules.impact_assessment.da.macaronesia
  # i18n-ref: modules.impact_assessment.da.tuscan
  # i18n-ref: modules.impact_assessment.da.arctic
  # i18n-ref: modules.impact_assessment.da.none
  da_key <- if (nzchar(da)) paste0("modules.impact_assessment.da.", da) else "modules.impact_assessment.da.none"
  ref <- switch(status,
    available = i18n$t("modules.impact_assessment.reference_available"),
    valuation_only = i18n$t("modules.impact_assessment.reference_valuation_only"),
    i18n$t("modules.impact_assessment.reference_unavailable"))
  div(class = "alert alert-info py-2", icon("map-marker-alt"), " ", strong(i18n$t(da_key)), " — ", ref)
}
```

- [ ] **Step 4: Create `modules/impact_assessment_module.R` (shell)**

```r
# modules/impact_assessment_module.R
# WP5 impact-assessment wizard (spec 2026-10-11 WS-6; D5.2 §1.4 seven steps).
# All state changes go through the pure model in functions/impact_assessment_model.R
# and are persisted with set_impact_assessment(); rendering helpers live in
# functions/impact_assessment_view.R.

impact_assessment_ui <- function(id, i18n) {
  tryCatch(shiny.i18n::usei18n(i18n$translator %||% i18n), error = function(e) NULL)
  ns <- NS(id)
  tagList(
    fluidRow(column(12,
      create_module_header(ns, "modules.impact_assessment.title", "modules.impact_assessment.subtitle",
                           "help_impact", i18n),
      uiOutput(ns("da_banner")),
      uiOutput(ns("step_bar"))
    )),
    fluidRow(column(12, uiOutput(ns("step_body")))),
    fluidRow(column(12,
      div(class = "mt-3",
        actionButton(ns("prev_step"), i18n$t("modules.impact_assessment.prev"), icon = icon("arrow-left"), class = "btn-outline-secondary"),
        actionButton(ns("next_step"), i18n$t("modules.impact_assessment.next"), icon = icon("arrow-right"), class = "btn-primary ms-2")
      )
    ))
  )
}

impact_assessment_server <- function(id, project_data_reactive, i18n, event_bus = NULL) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    rv <- reactiveValues(ia = NULL, step = 1L, loaded_for = NULL)

    da <- reactive(wp5_da_for_project(project_data_reactive()))
    ref_status <- reactive(impact_reference_status(da()))
    available_steps <- function() 1L   # grows: Task 4 adds 7; Task 5 adds 2; Task 6 adds 3; Part B adds 4-6

    # Build the working copy from the project; a fresh one starts from the DA's
    # published scenarios (P5: nothing is written until the user acts).
    load_from_project <- function() {
      pd <- project_data_reactive()
      ia <- get_impact_assessment(pd)
      if (is.null(ia)) {
        d <- wp5_da_for_project(pd)
        ia <- if (identical(impact_reference_status(d), "available")) impact_assessment_from_reference(d) else new_impact_assessment(d)
      }
      rv$ia <- ia
      rv$step <- 1L
    }
    observe({ project_data_reactive(); isolate(if (is.null(rv$ia)) load_from_project()) })
    if (!is.null(event_bus)) observeEvent(event_bus$on_project_loaded(), load_from_project(), ignoreInit = TRUE)

    # Persist: the only write path. Never emits ISA/CLD events (code map §2).
    commit <- function(ia) {
      rv$ia <- ia
      project_data_reactive(set_impact_assessment(project_data_reactive(), ia))
    }
    # Translate a model error (class impact_error, $code) into a notification
    notify_impact_error <- function(e) {
      code <- if (inherits(e, "impact_error")) e$code else "unknown"
      # i18n-ref: modules.impact_assessment.error.unknown
      showNotification(i18n$t(paste0("modules.impact_assessment.error.", code)), type = "error", duration = 8)
    }
    try_commit <- function(expr) {
      tryCatch(commit(expr), error = function(e) { notify_impact_error(e); invisible(NULL) })
    }

    output$da_banner <- renderUI(impact_da_banner(da(), ref_status(), i18n))
    output$step_bar <- renderUI({ req(rv$ia); impact_step_bar(rv$step, available_steps(), i18n, ns) })
    lapply(1:7, function(n) observeEvent(input[[paste0("goto_step_", n)]], { rv$step <- n }))
    observeEvent(input$prev_step, { if (rv$step > 1L) rv$step <- rv$step - 1L })
    observeEvent(input$next_step, { if (rv$step < max(available_steps())) rv$step <- rv$step + 1L })

    output$step_body <- renderUI({
      req(rv$ia)
      if (identical(ref_status(), "valuation_only")) {
        return(tagList(
          ses_empty_state("modules.impact_assessment.tuscan_empty", "modules.impact_assessment.tuscan_empty_hint",
                          icon_name = "euro-sign", status = "info", i18n = i18n),
          div(class = "text-center", actionButton(ns("go_valuation"), i18n$t("modules.impact_assessment.go_valuation"),
                                                 class = "btn-outline-primary",
                                                 onclick = "Shiny.setInputValue('impact_nav_target', 'response_valuation', {priority: 'event'})"))
        ))
      }
      switch(as.character(rv$step), "1" = step1_ui(), div(i18n$t("modules.impact_assessment.step_not_available")))
    })
    step1_ui <- function() div(i18n$t("modules.impact_assessment.step.characterisation"))  # replaced in Task 4

    # Navigation to the valuation calculator (Tuscan empty state)
    observeEvent(input$go_valuation, {
      if (!is.null(event_bus) && is.function(event_bus$emit_navigation_request)) event_bus$emit_navigation_request("response_valuation")
    })

    create_help_observer(input, "help_impact", "modules.impact_assessment.help_title",
                         tagList(p(i18n$t("modules.impact_assessment.help_body"))), i18n)
    reactive(rv$ia)
  })
}
```

The `onclick` on the valuation button is a belt-and-braces fallback; the server observer uses the bus. If `emit_navigation_request(target_tab)` has a different name, read `server/event_bus_setup.R` and use it.

- [ ] **Step 5: Wiring edits** (`global.R`, `app.R` three places, `functions/ui_sidebar.R`) exactly as listed under **Files**.

- [ ] **Step 6: Translations — `translations/modules/impact_assessment.json`** with the file shape of `translations/modules/valuation_calculator.json` (`languages` array + `translation` object). English values for the Task 3 keys (provide all 8 other languages yourself; keep placeholders like `%1$s` identical in every language):

| key | en |
|---|---|
| modules.impact_assessment.title | Impact assessment |
| modules.impact_assessment.subtitle | Seven-step assessment of response scenarios against the WP5 criteria (D5.2 §1.4) |
| modules.impact_assessment.help_title | About the impact assessment |
| modules.impact_assessment.help_body | Work through the steps in order. Scenarios and ratings are stored in the project; WP5 reference values can be copied but never change by themselves. |
| modules.impact_assessment.prev | Previous step |
| modules.impact_assessment.next | Next step |
| modules.impact_assessment.step.characterisation | Characterisation |
| modules.impact_assessment.step.scenarios | Baseline and scenarios |
| modules.impact_assessment.step.scoping | Impact scoping |
| modules.impact_assessment.step.matrix | Criterion assessment |
| modules.impact_assessment.step.uncertainty | Uncertainty |
| modules.impact_assessment.step.trade_offs | Trade-offs and synergies |
| modules.impact_assessment.step.recommendations | Recommendations |
| modules.impact_assessment.step_not_available | This step is not available yet. |
| modules.impact_assessment.da.macaronesia | Macaronesia |
| modules.impact_assessment.da.tuscan | Tuscan Archipelago |
| modules.impact_assessment.da.arctic | Arctic Northeast Atlantic |
| modules.impact_assessment.da.none | No demonstration area set in the project (PIMS) |
| modules.impact_assessment.reference_available | WP5 reference scenarios and ratings are available for this area. |
| modules.impact_assessment.reference_valuation_only | D5.2 provides a valuation for this area, not scenarios. |
| modules.impact_assessment.reference_unavailable | No WP5 reference data for this area; define your own scenarios. |
| modules.impact_assessment.tuscan_empty | D5.2 gives a benefit-transfer valuation for the Tuscan Archipelago rather than response scenarios. |
| modules.impact_assessment.tuscan_empty_hint | Use the valuation calculator for the Posidonia oceanica figures, or set a different demonstration area in PIMS to assess scenarios. |
| modules.impact_assessment.go_valuation | Open the valuation calculator |
| modules.impact_assessment.error.unknown | The assessment could not be updated. |
| modules.impact_assessment.error.invalid_scenario_code | Scenario codes may only use letters, digits and underscores (1–40 characters). |
| modules.impact_assessment.error.invalid_scenario_source | Unknown scenario source. |
| modules.impact_assessment.error.unknown_scenario | That scenario no longer exists. |
| modules.impact_assessment.error.no_da | Set a demonstration area in PIMS before using WP5 reference values. |
| modules.impact_assessment.error.no_reference_cell | D5.2 has no reference rating for this criterion and scenario. |
| modules.impact_assessment.error.scenario_not_reference | Reference ratings can only be copied into WP5 reference scenarios. |
| modules.impact_assessment.error.cell_not_empty | This cell already has a rating; clear it before copying the reference. |
| modules.impact_assessment.error.invalid_displacement_answer | Choose yes, no or unsure. |
| modules.impact_assessment.error.malformed_assessment | The stored assessment is malformed and was not saved. |
| modules.impact_assessment.error.too_many_scenarios | At most %1$s scenarios can be compared. |
| modules.impact_assessment.error.duplicate_scenario | A scenario with that code already exists. |

Check the model's actual error codes with `grep -o '\.impact_error("[a-z_]*")' functions/impact_assessment_model.R | sort -u` and add a key for every code found (each with a `# i18n-ref:` line in the module next to `notify_impact_error`).

Sidebar: add `ui.sidebar.impact_assessment` ("Impact assessment") to `translations/ui/sidebar.json` in 9 languages.

- [ ] **Step 7: Run the module test, the sidebar/menu tests and the i18n audit**

```bash
Rscript -e "for (f in c('tests/testthat/test-impact-assessment-module.R','tests/testthat/test-ui-sidebar.R','tests/testthat/test-functions-sourced-in-app.R','tests/testthat/test-i18n-enforcement.R')) testthat::test_file(f)"
micromamba run -n shiny python scripts/_i18n_audit.py | grep Totals
```
Expected: all pass; `missing=0 hardcoded=0`. (If `test-ui-sidebar.R` has a different name, run `ls tests/testthat | grep -i sidebar`.)

- [ ] **Step 8: Commit**

```bash
git add modules/impact_assessment_module.R functions/impact_assessment_view.R translations/modules/impact_assessment.json translations/ui/sidebar.json global.R app.R functions/ui_sidebar.R tests/testthat/test-impact-assessment-module.R
git commit -m "feat(wp5): impact-assessment module shell, persistence, wiring and Tuscan empty state (WS-6b task 3)"
```

---

### Task 4: Step 1 (characterisation) and Step 7 (recommendations) text sections

**Files:**
- Modify: `modules/impact_assessment_module.R` (replace `step1_ui`; add `step7_ui`; `available_steps()` returns `c(1L, 7L)`)
- Test: `tests/testthat/test-impact-assessment-module.R` (append)

**Interfaces:**
- Consumes: `impact_set_section(ia, section, values)` with sections `characterisation` (fields `focal_issue, spatial_scope, time_horizon, stakeholders`) and `recommendations` (`text`); `IMPACT_TEXT_SECTIONS`.
- Produces: inputs `ns("char_focal_issue")`, `ns("char_spatial_scope")`, `ns("char_time_horizon")`, `ns("char_stakeholders")`, `ns("save_characterisation")`, `ns("rec_text")`, `ns("save_recommendations")`.

- [ ] **Step 1: Failing tests**

```r
test_that("step 1 saves the four characterisation fields into the project", {
  args <- srv(mk_project("Macaronesia"))
  testServer(impact_assessment_server, args = args, {
    session$flushReact()
    session$setInputs(char_focal_issue = "Migratory corridor", char_spatial_scope = "Azores EEZ",
                      char_time_horizon = "2030", char_stakeholders = "Fishers; NGOs")
    session$setInputs(save_characterisation = 1); session$flushReact()
    ch <- get_impact_assessment(args$project_data_reactive())$characterisation
    expect_identical(ch$focal_issue, "Migratory corridor")
    expect_identical(ch$stakeholders, "Fishers; NGOs")
    expect_identical(args$project_data_reactive()$min_app_version, WP5_IMPACT_MIN_APP_VERSION)
  })
})

test_that("step 7 saves recommendations and prefills from the stored text", {
  p <- set_impact_assessment(mk_project("Macaronesia"), impact_set_section(new_impact_assessment("macaronesia"), "recommendations", list(text = "Pilot S3")))
  args <- srv(p)
  testServer(impact_assessment_server, args = args, {
    session$flushReact(); rv$step <- 7L; session$flushReact()
    expect_match(as.character(output$step_body$html), "Pilot S3", fixed = TRUE)
    session$setInputs(rec_text = "Pilot S3, then S4", save_recommendations = 1); session$flushReact()
    expect_identical(get_impact_assessment(args$project_data_reactive())$recommendations$text, "Pilot S3, then S4")
  })
})
```

- [ ] **Step 2: Run → fails** (inputs have no observers; `output$step_body` lacks the text).

- [ ] **Step 3: Implement in the module**

```r
    available_steps <- function() c(1L, 7L)

    text_section_ui <- function(section, fields, prefix, save_id, rows = 3) {
      vals <- rv$ia[[section]]
      tagList(
        lapply(fields, function(f) {
          # i18n-ref: modules.impact_assessment.field.focal_issue
          # i18n-ref: modules.impact_assessment.field.spatial_scope
          # i18n-ref: modules.impact_assessment.field.time_horizon
          # i18n-ref: modules.impact_assessment.field.stakeholders
          # i18n-ref: modules.impact_assessment.field.text
          # i18n-ref: modules.impact_assessment.field.notes
          textAreaInput(ns(paste0(prefix, f)), i18n$t(paste0("modules.impact_assessment.field.", f)),
                        value = vals[[f]] %||% "", rows = rows, width = "100%")
        }),
        actionButton(ns(save_id), i18n$t("modules.impact_assessment.save_section"), icon = icon("save"), class = "btn-success")
      )
    }
    step1_ui <- function() tagList(
      p(class = "text-muted", i18n$t("modules.impact_assessment.characterisation_intro")),
      text_section_ui("characterisation", IMPACT_TEXT_SECTIONS$characterisation, "char_", "save_characterisation", rows = 2)
    )
    step7_ui <- function() tagList(
      p(class = "text-muted", i18n$t("modules.impact_assessment.recommendations_intro")),
      text_section_ui("recommendations", IMPACT_TEXT_SECTIONS$recommendations, "rec_", "save_recommendations", rows = 6)
    )
    save_section <- function(section, fields, prefix) {
      vals <- setNames(lapply(fields, function(f) input[[paste0(prefix, f)]] %||% ""), fields)
      try_commit(impact_set_section(rv$ia, section, vals))
      showNotification(i18n$t("modules.impact_assessment.saved"), type = "message", duration = 3)
    }
    observeEvent(input$save_characterisation, save_section("characterisation", IMPACT_TEXT_SECTIONS$characterisation, "char_"))
    observeEvent(input$save_recommendations, save_section("recommendations", IMPACT_TEXT_SECTIONS$recommendations, "rec_"))
```

and in `output$step_body`'s `switch`: `"1" = step1_ui(), "7" = step7_ui(),`.

- [ ] **Step 4: Translations** — add keys: `field.focal_issue` (Focal issue), `field.spatial_scope` (Spatial scope), `field.time_horizon` (Time horizon), `field.stakeholders` (Stakeholders involved), `field.text` (Text), `field.notes` (Notes), `save_section` (Save), `saved` (Saved to the project.), `characterisation_intro` (Describe the case: the focal issue, the area, the time horizon and the stakeholders. Some of this may already be in PIMS.), `recommendations_intro` (State what you recommend and why, drawing on the matrix, the uncertainty notes and the trade-offs.) — 9 languages each.

- [ ] **Step 5: Run the module test + i18n audit → pass.**

- [ ] **Step 6: Commit** — `git commit -am "feat(wp5): impact assessment steps 1 and 7 (text sections) (WS-6b task 4)"` after `git add` of the module, translations and test.

---

### Task 5: Step 2 — baseline and scenario editor

**Files:**
- Modify: `modules/impact_assessment_module.R` (`step2_ui`, observers; `available_steps()` → `c(1L, 2L, 7L)`)
- Modify: `functions/impact_assessment_view.R` (`impact_scenario_table_df(ia, i18n)`, `impact_problem_messages(problems, i18n)`)
- Test: `tests/testthat/test-impact-assessment-view.R` (new) and module test (append)

**Interfaces:**
- Consumes: `new_impact_scenario(code, name, description, ambition_rank, source, dimensions)`, `impact_add_scenario`, `impact_update_scenario`, `impact_remove_scenario`, `impact_set_baseline`, `impact_scenario_codes`, `impact_step_problems(ia, 2)`, `IMPACT_MAX_SCENARIOS`, `IMPACT_SCENARIO_DIMENSIONS`, `impact_reference_status(da)`, `impact_assessment_from_reference(da)`.
- Produces (pure): `impact_scenario_table_df(ia, i18n)` → data.frame(code, name, baseline (logical), ambition_rank, source_label); `impact_problem_messages(problems, i18n)` → character vector, one translated sentence per row of an `impact_step_problems()` frame, using keys `modules.impact_assessment.problem.<code>` and, for cell problems, prefixing `"<criterion label> / <scenario code>: "`.
- Produces (inputs): `ns("sc_code")`, `ns("sc_name")`, `ns("sc_description")`, `ns("sc_ambition")`, `ns(paste0("sc_dim_", <dimension>))`, `ns("sc_add")`, `ns("sc_table")` (DT), `ns("sc_remove")`, `ns("sc_baseline")` (radioButtons of codes), `ns("sc_load_reference")`.

- [ ] **Step 1: Failing pure tests** (`tests/testthat/test-impact-assessment-view.R`)

```r
library(testthat)
source_for_test("functions/impact_assessment_view.R")
i18n <- make_test_i18n()

test_that("impact_scenario_table_df lists scenarios with the baseline flag and a translated source label", {
  ia <- impact_assessment_from_reference("macaronesia")
  df <- impact_scenario_table_df(ia, i18n)
  expect_identical(df$code, c("S1", "S2", "S3", "S4"))
  expect_identical(df$baseline, c(TRUE, FALSE, FALSE, FALSE))
  expect_identical(unique(df$source_label), "modules.impact_assessment.source.wp5_reference")
  expect_identical(nrow(impact_scenario_table_df(new_impact_assessment(""), i18n)), 0L)
})

test_that("impact_problem_messages translates step problems, prefixing cell problems", {
  ia <- new_impact_assessment("macaronesia")
  msgs <- impact_problem_messages(impact_step_problems(ia, 2), i18n)
  expect_identical(msgs, "modules.impact_assessment.problem.no_scenarios")
  ia <- impact_add_scenario(ia, new_impact_scenario("S1", "One"))
  cl <- new_impact_cell(); cl$confidence <- "low"
  ia <- impact_set_cell(ia, "EE", "S1", cl)
  msgs4 <- impact_problem_messages(impact_step_problems(ia, 4), i18n)
  # wp5_vocab_label() falls back to the code when the stub translator returns the key
  expect_true(any(grepl("^EE / S1: modules.impact_assessment.problem.driver_required$", msgs4)))
  expect_length(impact_problem_messages(impact_step_problems(ia, 1), i18n), 0L)
})
```

- [ ] **Step 2: Run → fails** (functions missing).

- [ ] **Step 3: Implement the pure helpers** (append to the view file)

```r
#' Scenario table rows for step 2
impact_scenario_table_df <- function(ia, i18n) {
  codes <- impact_scenario_codes(ia)
  if (length(codes) == 0) {
    return(data.frame(code = character(), name = character(), baseline = logical(), ambition_rank = integer(),
                      source_label = character(), stringsAsFactors = FALSE))
  }
  # i18n-ref: modules.impact_assessment.source.user
  # i18n-ref: modules.impact_assessment.source.wp5_reference
  rows <- lapply(codes, function(cd) {
    s <- ia$scenarios[[cd]]
    data.frame(code = cd, name = s$name, baseline = identical(ia$baseline_code, cd),
               ambition_rank = as.integer(s$ambition_rank),
               source_label = i18n$t(paste0("modules.impact_assessment.source.", s$source)),
               stringsAsFactors = FALSE)
  })
  do.call(rbind, rows)
}

#' Translated sentences for an impact_step_problems() frame
impact_problem_messages <- function(problems, i18n) {
  if (is.null(problems) || nrow(problems) == 0) return(character(0))
  # i18n-ref: modules.impact_assessment.problem.no_scenarios
  # i18n-ref: modules.impact_assessment.problem.too_many_scenarios
  # i18n-ref: modules.impact_assessment.problem.baseline_missing
  # i18n-ref: modules.impact_assessment.problem.displacement_note_missing
  # i18n-ref: modules.impact_assessment.problem.direction_missing
  # i18n-ref: modules.impact_assessment.problem.confidence_missing
  # i18n-ref: modules.impact_assessment.problem.driver_required
  # i18n-ref: modules.impact_assessment.problem.invalid_direction
  # i18n-ref: modules.impact_assessment.problem.invalid_magnitude
  # i18n-ref: modules.impact_assessment.problem.invalid_timing
  # i18n-ref: modules.impact_assessment.problem.invalid_confidence
  # i18n-ref: modules.impact_assessment.problem.invalid_uncertainty_driver
  # i18n-ref: modules.impact_assessment.problem.invalid_evidence
  # i18n-ref: modules.impact_assessment.problem.invalid_indicator_role
  # i18n-ref: modules.impact_assessment.problem.invalid_subdimension
  vapply(seq_len(nrow(problems)), function(i) {
    msg <- i18n$t(paste0("modules.impact_assessment.problem.", problems$problem[i]))
    if (nzchar(problems$criterion[i])) {
      paste0(wp5_vocab_label("criteria", problems$criterion[i], i18n), " / ", problems$scenario[i], ": ", msg)
    } else msg
  }, character(1))
}
```

- [ ] **Step 4: Failing module tests** (append)

```r
test_that("step 2 adds, sets baseline, removes scenarios and enforces the maximum", {
  args <- srv(mk_project(NULL))   # no DA: starts empty
  testServer(impact_assessment_server, args = args, {
    session$flushReact(); rv$step <- 2L; session$flushReact()
    expect_match(as.character(output$step_body$html), "modules.impact_assessment.problem.no_scenarios", fixed = TRUE)
    for (i in 1:5) { session$setInputs(sc_code = paste0("U", i), sc_name = paste("User", i), sc_description = "", sc_ambition = i, sc_add = i); session$flushReact() }
    expect_identical(impact_scenario_codes(rv$ia), paste0("U", 1:5))
    session$setInputs(sc_code = "U6", sc_name = "Six", sc_ambition = 6, sc_add = 6); session$flushReact()
    expect_length(impact_scenario_codes(rv$ia), 5L)                      # refused: IMPACT_MAX_SCENARIOS
    session$setInputs(sc_baseline = "U2"); session$flushReact()
    expect_identical(rv$ia$baseline_code, "U2")
    session$setInputs(sc_table_rows_selected = 5L, sc_remove = 1); session$flushReact()
    expect_identical(impact_scenario_codes(rv$ia), paste0("U", 1:4))
    expect_identical(get_impact_assessment(args$project_data_reactive())$baseline_code, "U2")
  })
})

test_that("an invalid scenario code is reported, not fatal", {
  testServer(impact_assessment_server, args = srv(mk_project(NULL)), {
    session$flushReact(); rv$step <- 2L
    session$setInputs(sc_code = "S 1!", sc_name = "Bad", sc_ambition = 1, sc_add = 1); session$flushReact()
    expect_length(impact_scenario_codes(rv$ia), 0L)
  })
})

test_that("Load WP5 scenarios restores the published set for a DA with reference data", {
  args <- srv(mk_project("Macaronesia"))
  testServer(impact_assessment_server, args = args, {
    session$flushReact(); rv$step <- 2L
    session$setInputs(sc_table_rows_selected = 4L, sc_remove = 1); session$flushReact()
    expect_identical(impact_scenario_codes(rv$ia), c("S1", "S2", "S3"))
    session$setInputs(sc_load_reference = 1); session$flushReact()
    expect_identical(impact_scenario_codes(rv$ia), c("S1", "S2", "S3", "S4"))
  })
})
```

- [ ] **Step 5: Implement step 2 in the module**

```r
    available_steps <- function() c(1L, 2L, 7L)

    step2_ui <- function() {
      df <- impact_scenario_table_df(rv$ia, i18n)
      problems <- impact_problem_messages(impact_step_problems(rv$ia, 2), i18n)
      tagList(
        p(class = "text-muted", i18n$t("modules.impact_assessment.scenarios_intro")),
        if (length(problems)) div(class = "alert alert-warning py-2", tags$ul(lapply(problems, tags$li))),
        fluidRow(
          column(7,
            DT::DTOutput(ns("sc_table")),
            div(class = "mt-2",
              actionButton(ns("sc_remove"), i18n$t("modules.impact_assessment.scenario_remove"), icon = icon("trash"), class = "btn-outline-danger btn-sm"),
              if (identical(ref_status(), "available"))
                actionButton(ns("sc_load_reference"), i18n$t("modules.impact_assessment.scenario_load_reference"), icon = icon("download"), class = "btn-outline-primary btn-sm ms-2")
            ),
            if (nrow(df) > 0) radioButtons(ns("sc_baseline"), i18n$t("modules.impact_assessment.baseline_label"),
                                           choices = stats::setNames(df$code, paste(df$code, df$name, sep = " — ")),
                                           selected = if (nzchar(rv$ia$baseline_code)) rv$ia$baseline_code else character(0))
          ),
          column(5, wellPanel(
            h5(i18n$t("modules.impact_assessment.scenario_add_heading")),
            textInput(ns("sc_code"), i18n$t("modules.impact_assessment.scenario_code"), placeholder = "S5"),
            textInput(ns("sc_name"), i18n$t("modules.impact_assessment.scenario_name")),
            textAreaInput(ns("sc_description"), i18n$t("modules.impact_assessment.scenario_description"), rows = 2),
            numericInput(ns("sc_ambition"), i18n$t("modules.impact_assessment.scenario_ambition"), value = 0, min = 0, max = 10, step = 1),
            tags$details(tags$summary(i18n$t("modules.impact_assessment.scenario_dimensions")),
              lapply(IMPACT_SCENARIO_DIMENSIONS, function(d) {
                # i18n-ref: modules.impact_assessment.dimension.governance_form
                # i18n-ref: modules.impact_assessment.dimension.spatial_scope
                # i18n-ref: modules.impact_assessment.dimension.sectoral_activation
                # i18n-ref: modules.impact_assessment.dimension.monitoring_data
                # i18n-ref: modules.impact_assessment.dimension.compliance_credibility
                # i18n-ref: modules.impact_assessment.dimension.financing_capacity
                textInput(ns(paste0("sc_dim_", d)), i18n$t(paste0("modules.impact_assessment.dimension.", d)))
              })),
            actionButton(ns("sc_add"), i18n$t("modules.impact_assessment.scenario_add"), icon = icon("plus"), class = "btn-success")
          ))
        )
      )
    }
    output$sc_table <- DT::renderDT({
      req(rv$ia)
      df <- impact_scenario_table_df(rv$ia, i18n)
      names(df) <- c(i18n$t("modules.impact_assessment.scenario_code"), i18n$t("modules.impact_assessment.scenario_name"),
                     i18n$t("modules.impact_assessment.baseline_label"), i18n$t("modules.impact_assessment.scenario_ambition"),
                     i18n$t("modules.impact_assessment.scenario_source"))
      DT::datatable(df, selection = "single", options = list(pageLength = 6, dom = "t"), rownames = FALSE)
    })
    observeEvent(input$sc_add, {
      if (length(impact_scenario_codes(rv$ia)) >= IMPACT_MAX_SCENARIOS) {
        showNotification(sprintf(i18n$t("modules.impact_assessment.error.too_many_scenarios"), IMPACT_MAX_SCENARIOS), type = "warning")
        return()
      }
      code <- trimws(input$sc_code %||% "")
      if (code %in% impact_scenario_codes(rv$ia)) { showNotification(i18n$t("modules.impact_assessment.error.duplicate_scenario"), type = "warning"); return() }
      dims <- setNames(lapply(IMPACT_SCENARIO_DIMENSIONS, function(d) input[[paste0("sc_dim_", d)]] %||% ""), IMPACT_SCENARIO_DIMENSIONS)
      dims <- dims[vapply(dims, nzchar, logical(1))]
      tryCatch({
        sc <- new_impact_scenario(code, input$sc_name %||% code, input$sc_description %||% "",
                                  as.integer(input$sc_ambition %||% 0L), "user", if (length(dims)) dims else NULL)
        commit(impact_add_scenario(rv$ia, sc))
        updateTextInput(session, "sc_code", value = ""); updateTextInput(session, "sc_name", value = "")
      }, error = notify_impact_error)
    })
    observeEvent(input$sc_remove, {
      sel <- input$sc_table_rows_selected
      req(length(sel) == 1)
      code <- impact_scenario_table_df(rv$ia, i18n)$code[sel]
      try_commit(impact_remove_scenario(rv$ia, code))
    })
    observeEvent(input$sc_baseline, {
      req(input$sc_baseline %in% impact_scenario_codes(rv$ia))
      if (!identical(input$sc_baseline, rv$ia$baseline_code)) try_commit(impact_set_baseline(rv$ia, input$sc_baseline))
    })
    observeEvent(input$sc_load_reference, {
      ref <- impact_assessment_from_reference(da())
      ia <- rv$ia
      for (cd in impact_scenario_codes(ref)) if (!cd %in% impact_scenario_codes(ia)) ia <- impact_add_scenario(ia, ref$scenarios[[cd]])
      if (!nzchar(ia$baseline_code) && nzchar(ref$baseline_code)) ia <- impact_set_baseline(ia, ref$baseline_code)
      try_commit(ia)
    })
```

and `"2" = step2_ui(),` in the switch. If `impact_add_scenario` errors with `too_many_scenarios` itself, the pre-check stays (it avoids the exception path); if `impact_remove_scenario` of the baseline leaves `baseline_code` dangling, the model already handles it (check `impact_remove_scenario` body; if not, add `if (identical(ia$baseline_code, code)) ia$baseline_code <- ""` before commit).

- [ ] **Step 6: Translations** — keys (English): `scenarios_intro` (Define up to %1$s scenarios to compare, and mark the baseline. For Macaronesia and the Arctic, the published WP5 scenarios can be loaded.), `scenario_remove` (Remove selected), `scenario_load_reference` (Load WP5 scenarios), `baseline_label` (Baseline), `scenario_add_heading` (Add a scenario), `scenario_code` (Code), `scenario_name` (Name), `scenario_description` (Description), `scenario_ambition` (Ambition rank (0 = unranked)), `scenario_dimensions` (Optional description dimensions (D5.2)), `scenario_add` (Add scenario), `scenario_source` (Source), `source.user` (Your scenario), `source.wp5_reference` (WP5 reference), `dimension.*` six keys (Governance form; Spatial scope; Sectoral activation; Monitoring and data; Compliance credibility; Financing and capacity), `problem.no_scenarios` (Add at least one scenario.), `problem.too_many_scenarios` (Too many scenarios; remove some.), `problem.baseline_missing` (Mark one scenario as the baseline.), plus all `problem.*` keys listed in the sentinels of `impact_problem_messages` (direction_missing: Direction is missing.; confidence_missing: Confidence is missing.; driver_required: Low confidence needs an uncertainty driver.; displacement_note_missing: Explain the possible displacement.; invalid_*: "<Field> has an invalid value.").
  In `scenarios_intro`, use `sprintf(i18n$t(...), IMPACT_MAX_SCENARIOS)` in `step2_ui`.

- [ ] **Step 7: Run view + module tests + i18n audit → pass.** Commit:

```bash
git add functions/impact_assessment_view.R modules/impact_assessment_module.R translations/modules/impact_assessment.json tests/testthat/test-impact-assessment-view.R tests/testthat/test-impact-assessment-module.R
git commit -m "feat(wp5): impact assessment step 2 scenario editor with WP5 reference loading (WS-6b task 5)"
```

---

### Task 6: Step 3 — impact scoping (elements, indicators, displacement)

**Files:**
- Modify: `functions/impact_assessment_view.R` (`impact_element_choices(project)`, `impact_indicator_choices(da, i18n)`)
- Modify: `modules/impact_assessment_module.R` (`step3_ui`, observers; `available_steps()` → `c(1L, 2L, 3L, 7L)`)
- Test: view test + module test (append)

**Interfaces:**
- Consumes: `get_all_isa_elements(project)` (columns `id`/`name` OR `ID`/`Name`, plus `element_type`), `list_indicators(da = da)` (columns at least `code`, `name`; verify with `names(list_indicators(da = "macaronesia"))` and adapt), `impact_set_scope_items(ia, element_ids, indicator_codes)`, `impact_set_displacement(ia, answer, note, displaced_pressure_id)`, `IMPACT_DISPLACEMENT_ANSWERS`.
- Produces (pure): `impact_element_choices(project)` → named character vector `c("<name> (<ID>) [<type>]" = "<ID>")`, empty when no ISA; `impact_indicator_choices(da, i18n)` → named character vector of codes (name + code), empty for `""`.
- Produces (inputs): `ns("scope_elements")`, `ns("scope_indicators")`, `ns("scope_displacement")`, `ns("scope_displacement_note")`, `ns("scope_displaced_pressure")`, `ns("save_scope")`.

- [ ] **Step 1: Failing pure tests** (append to the view test)

```r
test_that("impact_element_choices lists canonical and lowercase ISA frames", {
  p <- create_empty_project("x")
  p$data$isa_data$drivers <- data.frame(ID = "D001", Name = "Food demand", stringsAsFactors = FALSE)
  p$data$isa_data$pressures <- data.frame(id = "P001", name = "Extraction", stringsAsFactors = FALSE)
  ch <- impact_element_choices(p)
  expect_setequal(unname(ch), c("D001", "P001"))
  expect_true(any(grepl("Food demand", names(ch))))
  expect_length(impact_element_choices(create_empty_project("empty")), 0L)
})

test_that("impact_indicator_choices returns registry codes for a DA and nothing without one", {
  ch <- impact_indicator_choices("macaronesia", i18n)
  expect_true(length(ch) > 0)
  expect_true(all(nzchar(unname(ch))))
  expect_length(impact_indicator_choices("", i18n), 0L)
})
```

- [ ] **Step 2: Run → fails.**

- [ ] **Step 3: Implement the pure helpers**

```r
#' Element picker choices from the ISA (both column cases, code map §5)
impact_element_choices <- function(project) {
  df <- tryCatch(get_all_isa_elements(project), error = function(e) data.frame())
  if (!is.data.frame(df) || nrow(df) == 0) return(character(0))
  id_col <- if ("id" %in% names(df)) "id" else if ("ID" %in% names(df)) "ID" else return(character(0))
  nm_col <- if ("name" %in% names(df)) "name" else if ("Name" %in% names(df)) "Name" else id_col
  ids <- as.character(df[[id_col]]); nms <- as.character(df[[nm_col]])
  keep <- !is.na(ids) & nzchar(ids)
  stats::setNames(ids[keep], paste0(nms[keep], " (", ids[keep], ") [", df$element_type[keep], "]"))
}

#' Indicator picker choices for a DA from the WS-4 registry
impact_indicator_choices <- function(da, i18n) {
  if (!nzchar(da)) return(character(0))
  rows <- tryCatch(list_indicators(da = da), error = function(e) NULL)
  if (!is.data.frame(rows) || nrow(rows) == 0) return(character(0))
  stats::setNames(as.character(rows$code), paste0(rows$name, " (", rows$code, ")"))
}
```

- [ ] **Step 4: Failing module test**

```r
test_that("step 3 saves scope elements, indicators and the displacement answer; a yes needs a note", {
  p <- mk_project("Macaronesia")
  p$data$isa_data$pressures <- data.frame(ID = c("P001", "P002"), Name = c("Extraction", "Noise"), stringsAsFactors = FALSE)
  args <- srv(p)
  testServer(impact_assessment_server, args = args, {
    session$flushReact(); rv$step <- 3L; session$flushReact()
    session$setInputs(scope_elements = "P001", scope_indicators = character(0), scope_displacement = "yes",
                      scope_displacement_note = "", scope_displaced_pressure = "P002", save_scope = 1)
    session$flushReact()
    expect_match(as.character(output$step_body$html), "modules.impact_assessment.problem.displacement_note_missing", fixed = TRUE)
    session$setInputs(scope_displacement_note = "Effort may move to ABNJ", save_scope = 2); session$flushReact()
    ia <- get_impact_assessment(args$project_data_reactive())
    expect_identical(ia$scope$element_ids, "P001")
    expect_identical(ia$scope$displacement$answer, "yes")
    expect_identical(ia$scope$displacement$displaced_pressure_id, "P002")
    expect_false(any(grepl("displacement_note_missing", as.character(output$step_body$html))))
  })
})
```

(Check the exact scope field names in `.impact_fill_scope` (`functions/impact_assessment_model.R:115`): if they are `element_ids`/`indicator_codes`, the test is right; otherwise use the model's names.)

- [ ] **Step 5: Implement step 3 in the module**

```r
    available_steps <- function() c(1L, 2L, 3L, 7L)

    step3_ui <- function() {
      sc <- rv$ia$scope
      pd <- project_data_reactive()
      el <- impact_element_choices(pd)
      pressures <- el[grepl("\\[pressures\\]$", names(el))]
      problems <- impact_problem_messages(impact_step_problems(rv$ia, 3), i18n)
      # i18n-ref: modules.impact_assessment.displacement.yes
      # i18n-ref: modules.impact_assessment.displacement.no
      # i18n-ref: modules.impact_assessment.displacement.unsure
      tagList(
        p(class = "text-muted", i18n$t("modules.impact_assessment.scoping_intro")),
        if (length(problems)) div(class = "alert alert-warning py-2", tags$ul(lapply(problems, tags$li))),
        if (length(el) == 0) div(class = "alert alert-secondary py-2", i18n$t("modules.impact_assessment.no_isa_elements")),
        selectizeInput(ns("scope_elements"), i18n$t("modules.impact_assessment.scope_elements"), choices = el,
                       selected = sc$element_ids, multiple = TRUE, width = "100%"),
        selectizeInput(ns("scope_indicators"), i18n$t("modules.impact_assessment.scope_indicators"),
                       choices = impact_indicator_choices(da(), i18n), selected = sc$indicator_codes, multiple = TRUE, width = "100%"),
        hr(),
        h5(i18n$t("modules.impact_assessment.displacement_heading")),
        p(class = "text-muted", i18n$t("modules.impact_assessment.displacement_question")),
        radioButtons(ns("scope_displacement"), NULL,
                     choices = stats::setNames(IMPACT_DISPLACEMENT_ANSWERS,
                                               vapply(IMPACT_DISPLACEMENT_ANSWERS, function(a) i18n$t(paste0("modules.impact_assessment.displacement.", a)), character(1))),
                     selected = if (nzchar(sc$displacement$answer %||% "")) sc$displacement$answer else "unsure", inline = TRUE),
        textAreaInput(ns("scope_displacement_note"), i18n$t("modules.impact_assessment.displacement_note"), value = sc$displacement$note %||% "", rows = 2, width = "100%"),
        selectizeInput(ns("scope_displaced_pressure"), i18n$t("modules.impact_assessment.displaced_pressure"),
                       choices = c(stats::setNames("", i18n$t("modules.impact_assessment.displaced_pressure_none")), pressures),
                       selected = sc$displacement$displaced_pressure_id %||% "", width = "100%"),
        tags$small(class = "text-muted", i18n$t("modules.impact_assessment.displaced_pressure_hint")),
        div(class = "mt-3", actionButton(ns("save_scope"), i18n$t("modules.impact_assessment.save_section"), icon = icon("save"), class = "btn-success"))
      )
    }
    observeEvent(input$save_scope, {
      ia <- impact_set_scope_items(rv$ia, element_ids = as.character(input$scope_elements %||% character(0)),
                                   indicator_codes = as.character(input$scope_indicators %||% character(0)))
      tryCatch({
        ia <- impact_set_displacement(ia, input$scope_displacement %||% "unsure", input$scope_displacement_note %||% "",
                                      input$scope_displaced_pressure %||% "")
        commit(ia)
        showNotification(i18n$t("modules.impact_assessment.saved"), type = "message", duration = 3)
      }, error = notify_impact_error)
    })
```

and `"3" = step3_ui(),` in the switch.

- [ ] **Step 6: Translations** — `scoping_intro` (Choose the DAPSI(W)R(M) elements and the indicators this assessment covers, then answer the displacement question (D5.2 §8.4).), `no_isa_elements` (The project has no ISA elements yet; enter them in ISA Data Entry first.), `scope_elements` (Elements in scope), `scope_indicators` (Indicators in scope), `displacement_heading` (Displacement and leakage), `displacement_question` (Could this intervention move the activity or pressure elsewhere?), `displacement.yes` (Yes), `displacement.no` (No), `displacement.unsure` (Unsure), `displacement_note` (Where and how could it move? (required for Yes)), `displaced_pressure` (Existing pressure element that represents the displaced pressure), `displaced_pressure_none` (None), `displaced_pressure_hint` (Add the displaced pressure as a Pressure in ISA Data Entry first; creating it from here is not supported.).

- [ ] **Step 7: Run tests + audit → pass. Commit:**

```bash
git add functions/impact_assessment_view.R modules/impact_assessment_module.R translations/modules/impact_assessment.json tests/testthat/test-impact-assessment-view.R tests/testthat/test-impact-assessment-module.R
git commit -m "feat(wp5): impact assessment step 3 scoping with displacement check (WS-6b task 6)"
```

**Part A checkpoint:** run `Rscript -e "for (f in list.files('tests/testthat', pattern='^test-(impact-|analysis-clear|wp5-vocab|response-module).*[.]R$', full.names=TRUE)) testthat::test_file(f)"` and the i18n audit. Open a draft PR titled "feat(wp5): impact-assessment module, part A (WS-6b tasks 1–6)" for an interim review; continue on the same branch.

---

## Part B — matrix, reference panels, gating, release

### Task 7: Step 4 — criterion × scenario matrix with per-cell editor

**Files:**
- Modify: `functions/impact_assessment_view.R` (`impact_direction_glyph`, `impact_fill_level`, `impact_cell_css_class`, `impact_matrix_table(ia, i18n, ns)`)
- Modify: `modules/impact_assessment_module.R` (`step4_ui`, cell modal, observers; `available_steps()` → `c(1:4, 7L)`)
- Modify: `www/css/custom.css` or the app's main stylesheet (find with `ls www/css`; add the `.ia-cell*` rules)
- Test: view test + module test (append)

**Interfaces:**
- Consumes: `impact_get_cell`, `impact_set_cell`, `impact_cell_problems`, `impact_copy_reference_cell`, `impact_reference_cell(da, criterion, code)`, `impact_mechanism_options(da, code)`, `impact_indicator_suggestions(criterion, da)`, `WP5_RUBRIC`, `WP5_CRITERIA$code`, `WP5_CRITERION_SUBDIMENSIONS`, `provenance_badge`.
- Produces (pure): `impact_direction_glyph(direction)` → `"↑"`, `"↓"`, `"~"`, `"?"`, `""`; `impact_fill_level(magnitude)` → integer 0–3 (**toolbox_extension**: incremental 1, moderate 2, substantial 3, "" 0); `impact_cell_css_class(cell)` → e.g. `"ia-cell ia-fill-2 ia-dir-increase ia-conf-low"`; `impact_matrix_table(ia, i18n, ns)` → `tags$table` with one `actionLink(ns(paste0("cell_", criterion, "_", code)))` per cell, header labels via `wp5_vocab_label("criteria", ...)`, baseline column marked, a legend row, and `provenance_badge("toolbox_extension", i18n)` next to the fill legend.
- Produces (inputs): `ns("cell_<CR>_<CODE>")` links; modal inputs `ns("cell_direction")`, `ns("cell_magnitude")`, `ns("cell_timing")`, `ns("cell_confidence")`, `ns("cell_evidence")`, `ns("cell_driver")`, `ns("cell_rationale")`, `ns(paste0("cell_sub_", <subdimension>))`, `ns("cell_indicators")`, `ns(paste0("cell_role_", <code>))`, `ns("cell_mechanisms")`, `ns("cell_save")`, `ns("cell_clear")`, `ns("cell_copy_reference")`.

- [ ] **Step 1: Failing pure tests**

```r
test_that("glyph, fill level and css class follow the ordinal rubric", {
  expect_identical(impact_direction_glyph(c("increase", "decrease", "no_change", "uncertain", "")), c("\u2191", "\u2193", "~", "?", ""))
  expect_identical(impact_fill_level(c("", "incremental", "moderate", "substantial", "bogus")), c(0L, 1L, 2L, 3L, 0L))
  cl <- new_impact_cell(); cl$direction <- "increase"; cl$magnitude <- "moderate"; cl$confidence <- "low"
  expect_identical(impact_cell_css_class(cl), "ia-cell ia-fill-2 ia-dir-increase ia-conf-low")
  expect_identical(impact_cell_css_class(new_impact_cell()), "ia-cell ia-fill-0 ia-dir-none ia-conf-none")
})

test_that("impact_matrix_table renders 5 criteria x N scenarios with one link per cell and marks the baseline", {
  ia <- impact_assessment_from_reference("macaronesia")
  ia <- impact_copy_reference_cell(ia, "EE", "S3")
  html <- as.character(impact_matrix_table(ia, i18n, shiny::NS("ia")))
  for (cr in WP5_CRITERIA$code) for (sc in c("S1", "S2", "S3", "S4")) expect_match(html, paste0("ia-cell_", cr, "_", sc), fixed = TRUE)
  expect_match(html, "modules.impact_assessment.baseline_label", fixed = TRUE)
  expect_match(html, "modules.wp5_mechanisms.provenance.toolbox_extension", fixed = TRUE)
  expect_match(html, "ia-ref", fixed = TRUE)   # the copied cell carries the reference marker
})
```

- [ ] **Step 2: Run → fails.**

- [ ] **Step 3: Implement the pure helpers**

```r
#' Arrow glyph for a direction code (empty for "")
impact_direction_glyph <- function(direction) {
  m <- c(increase = "\u2191", decrease = "\u2193", no_change = "~", uncertain = "?")
  out <- unname(m[as.character(direction)]); out[is.na(out)] <- ""; out
}

#' Fill intensity for a magnitude code.
#' toolbox_extension (spec P4): the ONLY ordinal->numeric map in the module;
#' used for colour intensity, never for aggregation. incremental=1, moderate=2,
#' substantial=3, anything else 0.
impact_fill_level <- function(magnitude) {
  m <- c(incremental = 1L, moderate = 2L, substantial = 3L)
  out <- unname(m[as.character(magnitude)]); out[is.na(out)] <- 0L; out
}

impact_cell_css_class <- function(cell) {
  cell <- .impact_fill_cell(cell)
  paste("ia-cell", paste0("ia-fill-", impact_fill_level(cell$magnitude)),
        paste0("ia-dir-", if (nzchar(cell$direction)) cell$direction else "none"),
        paste0("ia-conf-", if (nzchar(cell$confidence)) cell$confidence else "none"))
}

#' The criterion x scenario matrix (step 4). Each cell is an actionLink.
impact_matrix_table <- function(ia, i18n, ns) {
  codes <- impact_scenario_codes(ia)
  header <- tags$tr(tags$th(""), lapply(codes, function(cd) {
    s <- ia$scenarios[[cd]]
    tags$th(class = "text-center", cd, tags$br(), tags$small(s$name),
            if (identical(ia$baseline_code, cd)) tags$span(class = "badge bg-secondary ms-1", i18n$t("modules.impact_assessment.baseline_label")))
  }))
  rows <- lapply(WP5_CRITERIA$code, function(cr) {
    tags$tr(tags$th(wp5_vocab_label("criteria", cr, i18n)), lapply(codes, function(cd) {
      cl <- impact_get_cell(ia, cr, cd)
      has_ref <- length(cl$reference) > 0
      label <- paste0(impact_direction_glyph(cl$direction), " ",
                      if (nzchar(cl$magnitude)) wp5_vocab_label("magnitude", cl$magnitude, i18n) else "",
                      if (nzchar(cl$confidence)) paste0(" (", wp5_vocab_label("confidence", cl$confidence, i18n), ")") else "")
      tags$td(class = paste(impact_cell_css_class(cl), if (has_ref) "ia-ref"),
              actionLink(ns(paste0("cell_", cr, "_", cd)), if (nzchar(trimws(label))) label else i18n$t("modules.impact_assessment.cell_empty"),
                         class = "ia-cell-link d-block"))
    }))
  })
  legend <- div(class = "small text-muted mt-2",
    i18n$t("modules.impact_assessment.legend_glyph"), " · ", i18n$t("modules.impact_assessment.legend_fill"),
    provenance_badge("toolbox_extension", i18n), " · ", i18n$t("modules.impact_assessment.legend_hatch"))
  tagList(tags$table(class = "table table-bordered ia-matrix", tags$thead(header), tags$tbody(rows)), legend)
}
```

CSS (append to the main stylesheet):

```css
.ia-matrix td.ia-cell { min-width: 9rem; vertical-align: middle; text-align: center; }
.ia-fill-0 { background: #ffffff; } .ia-fill-1 { background: #e3f2fd; } .ia-fill-2 { background: #90caf9; } .ia-fill-3 { background: #42a5f5; }
.ia-dir-decrease.ia-fill-1 { background: #fdecea; } .ia-dir-decrease.ia-fill-2 { background: #f5b7b1; } .ia-dir-decrease.ia-fill-3 { background: #ec7063; }
.ia-conf-low { background-image: repeating-linear-gradient(45deg, rgba(0,0,0,0.08) 0 6px, transparent 6px 12px); }
td.ia-ref { outline: 2px dashed #6c757d; outline-offset: -3px; }
```

- [ ] **Step 4: Failing module tests**

```r
test_that("the cell modal saves a rating and the matrix reflects it; low confidence without a driver is listed as a problem", {
  args <- srv(mk_project("Macaronesia"))
  testServer(impact_assessment_server, args = args, {
    session$flushReact(); rv$step <- 4L; session$flushReact()
    session$setInputs(cell_EE_S2 = 1); session$flushReact()
    expect_identical(rv$editing, c(criterion = "EE", scenario = "S2"))
    session$setInputs(cell_direction = "increase", cell_magnitude = "moderate", cell_timing = "medium", cell_confidence = "low",
                      cell_evidence = c("literature"), cell_driver = "", cell_rationale = "Corridor closure", cell_indicators = character(0),
                      cell_mechanisms = character(0), cell_save = 1)
    session$flushReact()
    cl <- impact_get_cell(get_impact_assessment(args$project_data_reactive()), "EE", "S2")
    expect_identical(cl$direction, "increase")
    expect_match(as.character(output$step_body$html), "ia-fill-2 ia-dir-increase ia-conf-low", fixed = TRUE)
    expect_match(as.character(output$step_body$html), "modules.impact_assessment.problem.driver_required", fixed = TRUE)
  })
})

test_that("copy-from-reference fills a reference scenario cell once and reports cell_not_empty the second time", {
  args <- srv(mk_project("Macaronesia"))
  testServer(impact_assessment_server, args = args, {
    session$flushReact(); rv$step <- 4L
    session$setInputs(cell_EQ_S4 = 1); session$flushReact()
    session$setInputs(cell_copy_reference = 1); session$flushReact()
    cl <- impact_get_cell(rv$ia, "EQ", "S4")
    expect_true(nzchar(cl$rationale)); expect_identical(cl$reference$provenance, "wp5_source")
    session$setInputs(cell_copy_reference = 2); session$flushReact()   # must not crash; notification only
    expect_identical(impact_get_cell(rv$ia, "EQ", "S4")$rationale, cl$rationale)
  })
})

test_that("a user scenario reusing a reference code cannot receive reference text", {
  args <- srv(mk_project(NULL))
  testServer(impact_assessment_server, args = args, {
    session$flushReact()
    rv$ia$da <- "macaronesia"
    commit(impact_add_scenario(rv$ia, new_impact_scenario("S1", "Mine")))
    rv$step <- 4L; session$setInputs(cell_EE_S1 = 1); session$flushReact()
    session$setInputs(cell_copy_reference = 1); session$flushReact()
    expect_identical(impact_get_cell(rv$ia, "EE", "S1"), new_impact_cell())
  })
})
```

- [ ] **Step 5: Implement step 4 in the module**

```r
    available_steps <- function() c(1L, 2L, 3L, 4L, 7L)
    rv$editing <- NULL

    step4_ui <- function() {
      problems <- impact_problem_messages(impact_step_problems(rv$ia, 4), i18n)
      tagList(
        p(class = "text-muted", i18n$t("modules.impact_assessment.matrix_intro")),
        if (length(impact_scenario_codes(rv$ia)) == 0) div(class = "alert alert-warning py-2", i18n$t("modules.impact_assessment.problem.no_scenarios")),
        impact_matrix_table(rv$ia, i18n, ns),
        if (length(problems)) div(class = "alert alert-warning py-2", tags$ul(lapply(problems, tags$li)))
      )
    }
    # One observer per possible cell link (criteria x up to IMPACT_MAX_SCENARIOS codes are dynamic,
    # so observe the inputs by name when the step renders).
    observe({
      req(rv$ia); codes <- impact_scenario_codes(rv$ia)
      for (cr in WP5_CRITERIA$code) for (cd in codes) local({
        id <- paste0("cell_", cr, "_", cd); cr_ <- cr; cd_ <- cd
        if (is.null(rv$cell_obs[[id]])) {
          rv$cell_obs[[id]] <- observeEvent(input[[id]], { rv$editing <- c(criterion = cr_, scenario = cd_); show_cell_modal(cr_, cd_) }, ignoreInit = TRUE)
        }
      })
    })
    rubric_select <- function(id, vocab, key, selected, multiple = FALSE) {
      choices <- stats::setNames(WP5_RUBRIC[[vocab]], wp5_vocab_label(vocab, WP5_RUBRIC[[vocab]], i18n))
      if (!multiple) choices <- c(stats::setNames("", i18n$t("modules.impact_assessment.not_set")), choices)
      selectizeInput(ns(id), i18n$t(key), choices = choices, selected = selected, multiple = multiple, width = "100%")
    }
    show_cell_modal <- function(cr, cd) {
      cl <- impact_get_cell(rv$ia, cr, cd)
      d <- da()
      ref <- if (nzchar(d)) impact_reference_cell(d, cr, cd) else NULL
      is_ref_scenario <- identical(rv$ia$scenarios[[cd]]$source, "wp5_reference")
      subs <- WP5_CRITERION_SUBDIMENSIONS[[cr]] %||% character(0)
      ind <- impact_indicator_suggestions(cr, d)
      mech <- impact_mechanism_options(d, cd)
      mech_labels <- if (nrow(mech)) paste0(mech$name, ifelse(is.na(mech$applicability), "", paste0(" — ", mech$applicability))) else character(0)
      showModal(modalDialog(size = "l", easyClose = FALSE,
        title = paste0(wp5_vocab_label("criteria", cr, i18n), " × ", cd, " — ", rv$ia$scenarios[[cd]]$name),
        if (!is.null(ref)) div(class = "alert alert-light border py-2",
          strong(i18n$t("modules.impact_assessment.reference_cell_heading")), " ", provenance_badge(ref$provenance, i18n),
          p(class = "mb-1", if (nzchar(ref$rating_text)) tags$b(ref$rating_text), " ", ref$text),
          tags$small(class = "text-muted", ref$table),
          if (is_ref_scenario) actionButton(ns("cell_copy_reference"), i18n$t("modules.impact_assessment.copy_reference"), class = "btn-outline-primary btn-sm ms-2")),
        fluidRow(
          column(6, rubric_select("cell_direction", "direction", "modules.impact_assessment.cell_direction", cl$direction),
                    rubric_select("cell_magnitude", "magnitude", "modules.impact_assessment.cell_magnitude", cl$magnitude),
                    rubric_select("cell_timing", "timing", "modules.impact_assessment.cell_timing", cl$timing)),
          column(6, rubric_select("cell_confidence", "confidence", "modules.impact_assessment.cell_confidence", cl$confidence),
                    rubric_select("cell_driver", "uncertainty_driver", "modules.impact_assessment.cell_driver", cl$uncertainty_driver),
                    rubric_select("cell_evidence", "evidence", "modules.impact_assessment.cell_evidence", cl$evidence, multiple = TRUE))
        ),
        textAreaInput(ns("cell_rationale"), i18n$t("modules.impact_assessment.cell_rationale"), value = cl$rationale, rows = 3, width = "100%"),
        if (length(subs)) tagList(h6(i18n$t("modules.impact_assessment.cell_subdimensions")),
          lapply(subs, function(s) textInput(ns(paste0("cell_sub_", s)), wp5_vocab_label("subdimension", s, i18n), value = cl$subdimension_notes[[s]] %||% ""))),
        selectizeInput(ns("cell_indicators"), i18n$t("modules.impact_assessment.cell_indicators"),
                       choices = if (nrow(ind)) stats::setNames(ind$code, paste0(ind$name, " (", ind$code, ", ", wp5_vocab_label("indicator_role", ind$role, i18n), ")")) else character(0),
                       selected = names(cl$indicator_roles), multiple = TRUE, width = "100%"),
        selectizeInput(ns("cell_mechanisms"), i18n$t("modules.impact_assessment.cell_mechanisms"),
                       choices = stats::setNames(mech$id, mech_labels), selected = cl$mechanism_ids, multiple = TRUE, width = "100%"),
        footer = tagList(actionButton(ns("cell_clear"), i18n$t("modules.impact_assessment.cell_clear"), class = "btn-outline-danger"),
                         modalButton(i18n$t("common.buttons.cancel")),
                         actionButton(ns("cell_save"), i18n$t("modules.impact_assessment.save_section"), class = "btn-success"))
      ))
    }
    cell_from_inputs <- function(cr, cd) {
      cl <- impact_get_cell(rv$ia, cr, cd)
      cl$direction <- input$cell_direction %||% ""; cl$magnitude <- input$cell_magnitude %||% ""
      cl$timing <- input$cell_timing %||% ""; cl$confidence <- input$cell_confidence %||% ""
      cl$uncertainty_driver <- input$cell_driver %||% ""; cl$evidence <- as.character(input$cell_evidence %||% character(0))
      cl$rationale <- input$cell_rationale %||% ""
      subs <- WP5_CRITERION_SUBDIMENSIONS[[cr]] %||% character(0)
      notes <- setNames(lapply(subs, function(s) input[[paste0("cell_sub_", s)]] %||% ""), subs)
      cl$subdimension_notes <- notes[vapply(notes, nzchar, logical(1))]
      ind <- as.character(input$cell_indicators %||% character(0))
      sugg <- impact_indicator_suggestions(cr, da())
      cl$indicator_roles <- setNames(as.list(ifelse(ind %in% sugg$code, sugg$role[match(ind, sugg$code)], "supporting")), ind)
      cl$mechanism_ids <- as.character(input$cell_mechanisms %||% character(0))
      cl
    }
    observeEvent(input$cell_save, {
      req(rv$editing); cr <- rv$editing[["criterion"]]; cd <- rv$editing[["scenario"]]
      try_commit(impact_set_cell(rv$ia, cr, cd, cell_from_inputs(cr, cd)))
      removeModal()
    })
    observeEvent(input$cell_clear, {
      req(rv$editing); try_commit(impact_set_cell(rv$ia, rv$editing[["criterion"]], rv$editing[["scenario"]], new_impact_cell())); removeModal()
    })
    observeEvent(input$cell_copy_reference, {
      req(rv$editing)
      tryCatch({
        commit(impact_copy_reference_cell(rv$ia, rv$editing[["criterion"]], rv$editing[["scenario"]]))
        removeModal(); show_cell_modal(rv$editing[["criterion"]], rv$editing[["scenario"]])
      }, error = notify_impact_error)
    })
```

Declare `rv$cell_obs <- list()` in the `reactiveValues()` call (`cell_obs = list()`), and add `"4" = step4_ui(),` to the switch. In `testServer`, inputs for modal fields are set directly; the modal itself is not rendered, which is fine.

- [ ] **Step 6: Translations** — `matrix_intro`, `cell_empty` (not rated), `legend_glyph` (↑ increase · ↓ decrease · ~ no change · ? uncertain), `legend_fill` (Fill intensity = magnitude), `legend_hatch` (Hatched = low confidence), `not_set` (— not set —), `reference_cell_heading` (WP5 reference rating (D5.2)), `copy_reference` (Copy into this cell), `cell_direction` (Direction), `cell_magnitude` (Magnitude), `cell_timing` (Timing), `cell_confidence` (Confidence), `cell_driver` (Dominant uncertainty driver), `cell_evidence` (Evidence types), `cell_rationale` (Rationale), `cell_subdimensions` (Sub-dimension notes), `cell_indicators` (Linked indicators), `cell_mechanisms` (Linked financial mechanisms), `cell_clear` (Clear rating). Check `common.buttons.cancel` exists (it is used in `action_handlers.R`).

- [ ] **Step 7: Run view + module tests, `test-i18n-enforcement.R`, audit → pass. Commit:**

```bash
git add functions/impact_assessment_view.R modules/impact_assessment_module.R translations/modules/impact_assessment.json www/css tests/testthat/test-impact-assessment-view.R tests/testthat/test-impact-assessment-module.R
git commit -m "feat(wp5): impact assessment step 4 matrix and cell editor with reference copy (WS-6b task 7)"
```

---

### Task 8: Steps 5 and 6, Arctic read-only reference panels

**Files:**
- Modify: `functions/impact_assessment_view.R` (`impact_revenue_rows(revenue)`, `impact_feasibility_rows(da, i18n)`)
- Modify: `modules/impact_assessment_module.R` (`step5_ui`, `step6_ui`, Arctic panel in step 2; `available_steps()` → `1:7`)
- Test: view test + module test (append)

**Interfaces:**
- Consumes: `impact_reference_revenue("arctic")` (structure: `provenance, partner_question, data_quality_note, currency, unit, price_basis, countries[]` where each country has `country, baseline_year, baseline_table{table, source_lines}, scenario_table{...}, species[]` with `species, landings_t, landings_display, price_usd_per_t, price_display, baseline{display, usd_millions}, <scenario_code>{display, usd_millions}`); `impact_reference_cell("arctic", "PI", <code>)` for Table 8 political feasibility (the 3 Arctic cells); `impact_set_section(ia, "uncertainty", list(notes=))`, `impact_set_section(ia, "trade_offs", list(text=, auto_draft=))`.
- Produces (pure): `impact_revenue_rows(revenue)` → data.frame(country, species, landings_display, price_display, baseline, no_agreement, partial_agreement, full_agreement) using the `display` strings verbatim (P3), empty frame for NULL; `impact_feasibility_rows(da, i18n)` → data.frame(scenario, rating_text, text) from the DA's reference cells for criterion `PI`, empty when none.

- [ ] **Step 1: Failing pure tests**

```r
test_that("impact_revenue_rows shows the published Arctic displays verbatim and is empty elsewhere", {
  rows <- impact_revenue_rows(impact_reference_revenue("arctic"))
  expect_true(nrow(rows) > 0)
  expect_true(all(c("country", "species", "baseline", "full_agreement") %in% names(rows)))
  far <- rows[rows$country == "faroe_islands" & rows$species == "mackerel", ]
  expect_identical(far$baseline, "$332.85 million")
  expect_identical(far$full_agreement, "$285.6 million")
  expect_identical(nrow(impact_revenue_rows(NULL)), 0L)
})

test_that("impact_feasibility_rows returns the three Arctic Table 8 cells and nothing for Macaronesia's absent PI table", {
  ar <- impact_feasibility_rows("arctic", i18n)
  expect_identical(sort(ar$scenario), sort(c("no_agreement", "partial_agreement", "full_agreement")))
  expect_true(all(nzchar(ar$text)))
})
```

(For the Macaronesia half, check what `impact_reference_cell("macaronesia", "PI", "S1")` returns; Table 21 has PI cells too, so assert `nrow(impact_feasibility_rows("macaronesia", i18n)) == 4` instead if they exist, and `== 0` for `""`.)

- [ ] **Step 2: Run → fails.**

- [ ] **Step 3: Implement**

```r
#' Arctic revenue rows, published display strings only (spec P3)
impact_revenue_rows <- function(revenue) {
  empty <- data.frame(country = character(), species = character(), landings_display = character(), price_display = character(),
                      baseline = character(), no_agreement = character(), partial_agreement = character(), full_agreement = character(),
                      stringsAsFactors = FALSE)
  if (is.null(revenue) || length(revenue$countries) == 0) return(empty)
  disp <- function(x) as.character(x[["display"]] %||% "")
  rows <- lapply(revenue$countries, function(co) lapply(co$species, function(sp) {
    data.frame(country = as.character(co$country), species = as.character(sp$species),
               landings_display = as.character(sp$landings_display %||% ""), price_display = as.character(sp$price_display %||% ""),
               baseline = disp(sp$baseline), no_agreement = disp(sp$no_agreement),
               partial_agreement = disp(sp$partial_agreement), full_agreement = disp(sp$full_agreement),
               stringsAsFactors = FALSE)
  }))
  do.call(rbind, c(list(empty), unlist(rows, recursive = FALSE)))
}

#' Political-feasibility reference cells (criterion PI) for a DA
impact_feasibility_rows <- function(da, i18n) {
  empty <- data.frame(scenario = character(), rating_text = character(), text = character(), stringsAsFactors = FALSE)
  if (!nzchar(da)) return(empty)
  rows <- lapply(impact_reference_scenarios(da), function(s) {
    cl <- impact_reference_cell(da, "PI", s$code)
    if (is.null(cl)) NULL else data.frame(scenario = s$code, rating_text = cl$rating_text, text = cl$text, stringsAsFactors = FALSE)
  })
  do.call(rbind, c(list(empty), Filter(Negate(is.null), rows)))
}
```

- [ ] **Step 4: Module — steps 5 and 6, Arctic panel**

```r
    available_steps <- function() 1:7

    step5_ui <- function() tagList(
      p(class = "text-muted", i18n$t("modules.impact_assessment.uncertainty_intro")),
      text_section_ui("uncertainty", IMPACT_TEXT_SECTIONS$uncertainty, "unc_", "save_uncertainty", rows = 6)
    )
    step6_ui <- function() tagList(
      p(class = "text-muted", i18n$t("modules.impact_assessment.trade_offs_intro")),
      if (nzchar(rv$ia$trade_offs$auto_draft %||% "")) div(class = "alert alert-light border", strong(i18n$t("modules.impact_assessment.auto_draft_heading")), p(rv$ia$trade_offs$auto_draft)),
      text_section_ui("trade_offs", "text", "to_", "save_trade_offs", rows = 6)
    )
    observeEvent(input$save_uncertainty, save_section("uncertainty", IMPACT_TEXT_SECTIONS$uncertainty, "unc_"))
    observeEvent(input$save_trade_offs, {
      vals <- list(text = input$to_text %||% "", auto_draft = rv$ia$trade_offs$auto_draft %||% "")
      try_commit(impact_set_section(rv$ia, "trade_offs", vals))
      showNotification(i18n$t("modules.impact_assessment.saved"), type = "message", duration = 3)
    })

    arctic_panel <- function() {
      rev <- impact_reference_revenue(da()); if (is.null(rev)) return(NULL)
      rows <- impact_revenue_rows(rev)
      feas <- impact_feasibility_rows(da(), i18n)
      tagList(hr(), h5(i18n$t("modules.impact_assessment.arctic_revenue_heading"), " ", provenance_badge(rev$provenance, i18n)),
        div(class = "alert alert-warning py-2", icon("exclamation-triangle"), " ", i18n$t("modules.impact_assessment.arctic_revenue_note"),
            tags$small(class = "d-block text-muted", rev$data_quality_note)),
        DT::DTOutput(ns("arctic_revenue")),
        if (nrow(feas)) tagList(h6(i18n$t("modules.impact_assessment.arctic_feasibility_heading")),
          tags$table(class = "table table-sm", tags$tbody(lapply(seq_len(nrow(feas)), function(i) tags$tr(tags$td(feas$scenario[i]), tags$td(tags$b(feas$rating_text[i]), " ", feas$text[i])))))))
    }
    output$arctic_revenue <- DT::renderDT({ rows <- impact_revenue_rows(impact_reference_revenue(da())); DT::datatable(rows, options = list(pageLength = 10, dom = "t"), rownames = FALSE) })
```

Append `arctic_panel()` at the end of `step2_ui()`'s `tagList` (it returns NULL for other DAs). Add `"5" = step5_ui(), "6" = step6_ui(),` to the switch. The `data_quality_note` is English KB prose (spec P6: English with the note); keep it in `tags$small`.

- [ ] **Step 5: Failing module test**

```r
test_that("an Arctic project shows the read-only revenue table and feasibility cells on step 2", {
  args <- srv(mk_project("Arctic Northeast Atlantic"))
  testServer(impact_assessment_server, args = args, {
    session$flushReact(); rv$step <- 2L; session$flushReact()
    html <- as.character(output$step_body$html)
    expect_match(html, "modules.impact_assessment.arctic_revenue_note", fixed = TRUE)
    expect_match(html, "ia-arctic_revenue", fixed = TRUE)
    expect_identical(impact_scenario_codes(rv$ia), c("no_agreement", "partial_agreement", "full_agreement"))
  })
})

test_that("steps 5 and 6 persist their text", {
  args <- srv(mk_project("Macaronesia"))
  testServer(impact_assessment_server, args = args, {
    session$flushReact(); rv$step <- 5L; session$flushReact()
    session$setInputs(unc_notes = "Compliance in ABNJ", save_uncertainty = 1); session$flushReact()
    rv$step <- 6L; session$flushReact()
    session$setInputs(to_text = "S4: equity vs cost", save_trade_offs = 1); session$flushReact()
    ia <- get_impact_assessment(args$project_data_reactive())
    expect_identical(ia$uncertainty$notes, "Compliance in ABNJ")
    expect_identical(ia$trade_offs$text, "S4: equity vs cost")
  })
})
```

- [ ] **Step 6: Translations** — `uncertainty_intro` (Record the main uncertainties and how they could change the ratings. Re-scoring under alternative assumptions is not part of this version.), `trade_offs_intro` (Describe where scenarios gain on one criterion at the expense of another, and where they reinforce each other.), `auto_draft_heading` (Draft narrative), `arctic_revenue_heading` (Published revenue by scenario (D5.2 Tables 2–8)), `arctic_revenue_note` (Values are stored exactly as published and never recomputed; D5.2 itself notes inconsistencies with its scenario assumptions (partner question 2).), `arctic_feasibility_heading` (Political feasibility (D5.2 Table 8)).

- [ ] **Step 7: Run tests + audit → pass. Commit:**

```bash
git add functions/impact_assessment_view.R modules/impact_assessment_module.R translations/modules/impact_assessment.json tests/testthat/test-impact-assessment-view.R tests/testthat/test-impact-assessment-module.R
git commit -m "feat(wp5): impact assessment steps 5-6 and Arctic read-only reference panels (WS-6b task 8)"
```

---

### Task 9: Step gating and the next/previous flow

**Files:**
- Modify: `modules/impact_assessment_module.R` (replace the `next_step` observer; step bar shows a warning marker on gated steps)
- Modify: `functions/impact_assessment_view.R` (`impact_step_bar` gains `blocked` argument)
- Test: module test + view test (append)

**Interfaces:**
- Consumes: `impact_can_advance(ia, step)`, `impact_step_problems(ia, step)`, `impact_problem_messages`.
- Produces: `impact_step_bar(active, available, i18n, ns, blocked = integer(0))` adds class `btn-outline-warning` and a "!" suffix to blocked steps; `next_step` only advances when `impact_can_advance(rv$ia, rv$step)` is TRUE, otherwise notifies with the first three problem messages.

- [ ] **Step 1: Failing tests**

```r
# view test
test_that("impact_step_bar marks blocked steps", {
  html <- as.character(impact_step_bar(2L, 1:7, i18n, shiny::NS("ia"), blocked = c(2L, 4L)))
  expect_match(html, "btn-outline-warning", fixed = TRUE)
  expect_equal(lengths(regmatches(html, gregexpr("!</button>", html))), 2L)
})
# module test
test_that("next is blocked on step 2 without scenarios and on step 4 with a low-confidence cell lacking a driver", {
  args <- srv(mk_project(NULL))
  testServer(impact_assessment_server, args = args, {
    session$flushReact(); rv$step <- 2L; session$flushReact()
    session$setInputs(next_step = 1); session$flushReact()
    expect_identical(rv$step, 2L)
    commit(impact_set_baseline(impact_add_scenario(rv$ia, new_impact_scenario("U1", "One")), "U1"))
    session$setInputs(next_step = 2); session$flushReact()
    expect_identical(rv$step, 3L)
    session$setInputs(next_step = 3); session$flushReact()   # step 3 passes when displacement is not "yes"
    expect_identical(rv$step, 4L)
    cl <- new_impact_cell(); cl$direction <- "increase"; cl$confidence <- "low"
    commit(impact_set_cell(rv$ia, "EE", "U1", cl))
    session$setInputs(next_step = 4); session$flushReact()
    expect_identical(rv$step, 4L)
    cl$uncertainty_driver <- "data_gap"; commit(impact_set_cell(rv$ia, "EE", "U1", cl))
    session$setInputs(next_step = 5); session$flushReact()
    expect_identical(rv$step, 5L)
  })
})
```

- [ ] **Step 2: Run → fails.**

- [ ] **Step 3: Implement**

View file: change the signature to `impact_step_bar <- function(active, available, i18n, ns, blocked = integer(0))` and inside `items`: `cls <- if (n == active) "btn btn-primary btn-sm me-1 mb-1" else if (n %in% blocked) "btn btn-outline-warning btn-sm me-1 mb-1" else "btn btn-outline-primary btn-sm me-1 mb-1"`; label `paste0(n, ". ", <label>, if (n %in% blocked) " !" else "")`.

Module:

```r
    blocked_steps <- reactive({ req(rv$ia); Filter(function(s) !impact_can_advance(rv$ia, s), c(2L, 3L, 4L)) })
    output$step_bar <- renderUI({ req(rv$ia); impact_step_bar(rv$step, available_steps(), i18n, ns, blocked = blocked_steps()) })
    observeEvent(input$next_step, {
      if (rv$step >= max(available_steps())) return()
      if (!impact_can_advance(rv$ia, rv$step)) {
        msgs <- impact_problem_messages(impact_step_problems(rv$ia, rv$step), i18n)
        showNotification(tagList(strong(i18n$t("modules.impact_assessment.cannot_advance")), tags$ul(lapply(head(msgs, 3), tags$li))), type = "warning", duration = 8)
        return()
      }
      rv$step <- rv$step + 1L
    })
```

Keys: `cannot_advance` (Fix these before moving on:).

- [ ] **Step 4: Run tests + audit → pass. Commit:**

```bash
git add functions/impact_assessment_view.R modules/impact_assessment_module.R translations/modules/impact_assessment.json tests/testthat/test-impact-assessment-view.R tests/testthat/test-impact-assessment-module.R
git commit -m "feat(wp5): impact assessment step gating via impact_can_advance (WS-6b task 9)"
```

---

### Task 10: Translation completeness, docs and the 1.25.0 release

**Files:**
- Modify: `translations/modules/impact_assessment.json` (every key × 9 languages, reviewed)
- Modify: `CHANGELOG.md` (move the WS-6a `[Unreleased]` block and add WS-6b under a new `## [1.25.0] - <date>` section)
- Modify: `VERSION`, `DESCRIPTION` (`Version:`), `VERSION_INFO.json` (version + version name "WP5 impact assessment")
- Modify: `CLAUDE.md` (module count line; add the impact module to the architecture tree)
- Test: existing `test-i18n-english-fallback.R`, `test-i18n-placeholders.R`, `test-i18n-duplicate-keys.R`, `test-version-consistency.R` (if present: `ls tests/testthat | grep -i version`)

- [ ] **Step 1: Run the i18n test set**

```bash
Rscript -e "for (f in c('tests/testthat/test-i18n-enforcement.R','tests/testthat/test-i18n-english-fallback.R','tests/testthat/test-i18n-placeholders.R','tests/testthat/test-i18n-duplicate-keys.R','tests/testthat/test-i18n-key-arguments.R')) testthat::test_file(f)"
micromamba run -n shiny python scripts/_i18n_audit.py | grep Totals
```

Expected: pass, `missing=0 hardcoded=0`. Fix every non-English value that equals the English sentence (the fallback test lists them).

- [ ] **Step 2: CHANGELOG** — under `## [1.25.0] - YYYY-MM-DD` (today's date), heading "Minor release: WP5 impact-assessment module (WS-6a data layer + WS-6b wizard). Projects that contain an assessment require 1.25.0 or later." Move the WS-6a `### Added (WP5 impact assessment, data layer …)` block under it, then:

```markdown
### Added (WP5 impact-assessment module — spec 2026-10-11 WS-6b)
- New page under Response & Validation: a seven-step impact assessment (D5.2 §1.4). Steps: characterisation; baseline and up to 5 scenarios (Macaronesia and Arctic start from the published WP5 scenarios); impact scoping with the displacement/leakage question; the criterion × scenario matrix with the ordinal rubric (direction, magnitude, timing, confidence, evidence, uncertainty driver, rationale, EQ/PI sub-dimension notes, linked indicators and financial mechanisms); uncertainty notes; trade-offs; recommendations. Each step is gated by the model's problem checks (for example low confidence needs an uncertainty driver).
- WP5 reference ratings (Macaronesia Table 21) are shown read-only next to the cell and can be copied into WP5 reference scenarios only; the copy records the reference version. Arctic revenue tables (Tables 2–8) and political-feasibility ratings are shown read-only, exactly as published, with the partner-question-2 note. Tuscan projects get an empty state that points to the valuation calculator.
- Heat map: arrow = direction, fill intensity = magnitude (the only ordinal→numeric map, badged as a toolbox extension), hatching = low confidence.
- Not in this release: re-scoring under alternative assumptions (step 5 is notes only), the auto-drafted trade-off narrative and the Word/Excel report (WS-6c), and creating a new Pressure element for a displaced pressure (pick an existing one instead).

### Fixed
- Changing the ISA, importing Excel data or loading an SES model no longer wipes the whole analysis block: only loops and metrics are cleared, so WS-0 scenarios and the impact assessment survive (regression test added).
- `wp5_da_for_project()` is the single place that maps a project's demonstration area to the WP5 contexts (previously an inline mapping in the Response module).
```

- [ ] **Step 3: Version files** — `VERSION` → `1.25.0`; `DESCRIPTION` `Version: 1.25.0`; `VERSION_INFO.json` version `1.25.0`, name "WP5 impact assessment", status "stable". Run `ls tests/testthat | grep -iE "version"` and run those tests.

- [ ] **Step 4: Full suite in chunks** (fresh Rscript per chunk; a single run is reaped for memory):

```bash
for p in "^test-[a-c]" "^test-[d-i]" "^test-[j-m]" "^test-[n-r]" "^test-[s-z]"; do
  Rscript -e "testthat::test_dir('tests/testthat', filter = '${p#^test-}', reporter = 'summary')"
done
```

(`filter` is a regex on the file name without `test-`/`.R`; pass e.g. `'^[a-c]'`.) Expected: 0 failures besides the known ml-graph-features timing flake.

- [ ] **Step 5: Commit, push, PR**

```bash
git add translations/modules/impact_assessment.json CHANGELOG.md VERSION DESCRIPTION VERSION_INFO.json CLAUDE.md
git commit -m "chore(release): 1.25.0 — WP5 impact-assessment module (WS-6a + WS-6b)"
git push -u origin feat/wp5-ws6b-impact-module
gh pr create --title "feat(wp5): impact-assessment module and 1.25.0 release (WS-6b)" --body "<summary from CHANGELOG; test plan: chunked suite, i18n audit, CI>"
```

After CI: merge, `git tag v1.25.0 && git push origin v1.25.0`, deploy with `deployment/deploy-remote.ps1 -Force`, verify HTTP 200 and that `/srv/shiny-server/marinesabres/VERSION` reads 1.25.0.

---

## Self-review notes

- **Spec coverage.** WS-6 change 1 (ordinal cell schema) → Task 7 editor uses `WP5_RUBRIC` only. Change 2 (scenario axis with ambition rank + 6 dimensions) → Task 5. Change 3 (reference starters by DA; Tuscan empty state) → Tasks 3, 5, 7, 8. Change 4 (mechanism pre-filter by applicability; indicator suggestions by criterion role) → Task 7 (annotated, sorted, never hidden, per the WS-6a ruling). Change 5 (displacement check, optional linked P element) → Task 6 (existing P element only; creation descoped and documented). Change 6 (step 6 auto-draft) → WS-6c; Task 8 displays `auto_draft` when present. Change 7 (storage, min_app_version) → WS-6a, exercised in Task 4's stamp assertion. Heat map (glyph/fill/hatch, no radar) → Task 7. Tests listed in the spec: low confidence blocks advance (Task 9), Macaronesia reference cells = Table 21 (WS-6a tests + Task 7 copy test), Arctic values verbatim (Task 8), Tuscan empty state (Task 3), round trip incl. sub-dimension notes (WS-6a). Report builder and provenance appendix → WS-6c.
- **Placeholders.** None: every step has code or exact key tables. Two "verify the exact name" notes (event-bus emit names, scope field names, `list_indicators` columns) point to the file and line to read; they are not TODOs.
- **Type consistency.** `commit(ia)` / `try_commit(expr)` / `notify_impact_error(e)` defined in Task 3 and used unchanged afterwards; `text_section_ui(section, fields, prefix, save_id, rows)` and `save_section(section, fields, prefix)` defined in Task 4 and reused in Task 8; `impact_step_bar()` gains `blocked` in Task 9 with a default so Task 3's call still works; `rv$editing` is a named character vector `c(criterion=, scenario=)` in Task 7 and read with `[[ ]]`.
- **Review Focus** items are each pinned: 1 → Task 2 tests; 2 → Task 6 pure test; 3 → Task 3 "without writing the project until the user acts" + reload test; 4 → Task 5 invalid-code test; 5 → Task 7 double-copy and user-scenario tests.
