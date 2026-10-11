# WP5 Foundation (WS-0 + WS-1) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix the scenario-storage split and add the WP5 shared vocabulary (constants, translated labels, intervention→graph-operation table). Later WP5 workstreams (WS-2 to WS-10) build on both.

**Architecture:**
- **WS-0** makes `project$data$analysis$scenarios` the single canonical scenario location. Every load path already runs `normalize_and_reconcile_project()`, so a migration step there moves legacy `project$data$scenarios` into it. It also adds a monotonic `stamp_min_app_version()` helper.
- **WS-1** adds:
  - code-only vocabulary constants to `constants.R`;
  - a small pure helper file `functions/wp5_vocabulary.R` (code lookup and label resolution through `i18n$t()`);
  - a 9-language translation file;
  - a reference JSON `data/wp5_intervention_ops.json` with its loader.
- **No UI changes.** These are foundations only.

**Tech Stack:** R 4.4.1, shiny 1.11.1, testthat 3.3.2, jsonlite, shiny.i18n modular JSON translations.

**Spec:** `docs/superpowers/specs/2026-10-11-wp5-practical-integration-specs.md` (sections 1, WS-0 and WS-1). The evidence for vocabulary content is in `docs/wp5-source-audit/2026-10-11/C_D5.3_interventions.md` (§1.2, §1.3, §1.4, §2, §2.3) and `A_D5.2_audit.md` (§2.2, §2.3).

## Global Constraints

- **Codes in data, labels on display (spec P2).**
  - Constants hold stable ASCII codes only.
  - Labels resolve through `i18n$t("modules.wp5_vocabulary.<vocab>.<code_with_dots_as_underscores>")`.
  - No translated string is ever returned as a stored value.
- **Provenance (spec P1).** Every row of `data/wp5_intervention_ops.json` carries `provenance` ∈ {`wp5_source`, `wp5_derived`, `toolbox_extension`, `provisional`} and a `source_ref`.
- **Ordinal, not numeric (spec P4).** WS-1 introduces no numeric scales.
- **Translations.** Every new key has all 9 languages: `en`, `es`, `fr`, `de`, `lt`, `pt`, `it`, `no`, `el`. Write genuine translations, not English copies. The CI audit `micromamba run -n shiny python scripts/_i18n_audit.py` must report missing=0, hardcoded=0. Do **not** add `wp5_vocabulary` to `--allow-english-fallback`.
- **Sourcing.** Every new `functions/*.R` file is sourced from `global.R` with a literal `source("functions/<file>.R", local = FALSE)` line, so `tests/testthat/test-functions-sourced-in-app.R` passes.
- **Logging.** Use `debug_log(msg, "WP5")` for logging, never `cat()`/`print()`.
- **Tests.**
  - Never end a test in `expect_true(TRUE)`.
  - For module behaviour, re-bind the real server from `.GlobalEnv` before `testServer()` (`helper-stubs.R` shadows it; see `tests/testthat/test-entry-point-module.R:36-60`).
- **Shell.**
  - Use `git -C <path>` and never `cd <path> && git`.
  - Run R tests from the repo root with `Rscript -e "testthat::test_file('tests/testthat/<file>.R')"`.
  - Bare `Rscript -e` calls that source the whole app can segfault. Always go through `testthat::test_file()`.
- **Repo root:** `C:/Users/arturas.baziukas/OneDrive - ku.lt/HORIZON_EUROPE/Marine-SABRES/SESToolbox/MarineSABRES_SES_Shiny`. All paths below are relative to it.
- **Never stage `WP5/`.** It is untracked partner data and includes a 700 MB zip.

## Review Focus

1. A project carrying **both** legacy `data$scenarios` and canonical `data$analysis$scenarios`, e.g. an autosave from an older build edited in a newer one. It must merge by `id` with no duplicates, and canonical entries win. Pinned in Task 1.
2. A malformed legacy `scenarios` value (a character string, a data.frame from `jsonlite` simplification, or a list containing non-list items). Load must not crash; unusable items are dropped and logged. Pinned in Task 1.
3. A vocabulary lookup with an unknown, `NA`, `""` or lowercase alias code, such as `"po"`. Lookup must return `NA_character_`, or resolve the alias, without erroring. A label for an unknown code falls back to the code itself, never to an error or `NULL`. Pinned in Task 4.
4. A language switch. The stored code must not change, and the label must follow the active translator. Pinned in Task 4 by using two different i18n stubs.
5. A missing or corrupt `data/wp5_intervention_ops.json` at app start. This must give a warning and empty results, not a startup crash. Pinned in Task 6.

---

### Task 0: Branch and commit the spec documents

**Files:**
- Commit (already on disk, untracked):
  - `docs/superpowers/specs/2026-10-11-wp5-practical-integration-specs.md`
  - `docs/wp5-source-audit/2026-10-11/*.md`
  - this plan

- [ ] **Step 1: Create the branch from main**

```bash
git -C "<repo>" fetch origin
git -C "<repo>" switch -c feat/wp5-foundation origin/main
```

The untracked files carry over to the new branch automatically.

- [ ] **Step 2: Commit the docs only**

```bash
git -C "<repo>" add docs/superpowers/specs/2026-10-11-wp5-practical-integration-specs.md docs/wp5-source-audit/2026-10-11 docs/superpowers/plans/2026-10-11-wp5-ws0-ws1-foundation.md
git -C "<repo>" commit -m "docs(wp5): full-folder audit, integration specs WS-0..WS-10, foundation plan

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

Expected: 1 commit, 7 files. `git -C "<repo>" status --short` must show nothing under `docs/` and must not list `WP5/` as staged.

---

### Task 1: Legacy scenario migration (WS-0 part 1)

**Files:**
- Modify: `functions/data_structure.R`. Add `migrate_legacy_scenarios()` immediately above `normalize_and_reconcile_project()` (currently at line 1117), and call it from that function.
- Test: `tests/testthat/test-scenario-storage-migration.R` (new)

**Interfaces:**
- Produces: `migrate_legacy_scenarios(project) -> project`. It is pure and idempotent. Afterwards `project$data$analysis$scenarios` is a list and `project$data$scenarios` is `NULL`.
- Produces: `normalize_and_reconcile_project()` now applies the migration on every load path (`server/project_io.R:173,500`, `modules/auto_save_module.R:1115`, `functions/persistent_storage.R:503`).

- [ ] **Step 1: Write the failing tests**

```r
# tests/testthat/test-scenario-storage-migration.R
# WS-0: scenarios live at project$data$analysis$scenarios (functions/data_structure.R
# create_empty_project). The scenario builder historically wrote project$data$scenarios.
library(testthat)

sc <- function(id, name = id) list(id = id, name = name, modifications = list())

test_that("legacy-only scenarios move to analysis$scenarios", {
  p <- list(data = list(scenarios = list(sc("s1"), sc("s2")), analysis = list()))
  out <- migrate_legacy_scenarios(p)
  expect_null(out$data$scenarios)
  expect_equal(vapply(out$data$analysis$scenarios, `[[`, "", "id"), c("s1", "s2"))
})

test_that("both locations merge by id; canonical wins; no duplicates", {
  p <- list(data = list(
    scenarios = list(sc("s1", "legacy name"), sc("s3")),
    analysis  = list(scenarios = list(sc("s1", "canonical name"), sc("s2")))))
  out <- migrate_legacy_scenarios(p)
  ids <- vapply(out$data$analysis$scenarios, `[[`, "", "id")
  expect_equal(ids, c("s1", "s2", "s3"))
  expect_equal(out$data$analysis$scenarios[[1]]$name, "canonical name")
})

test_that("malformed legacy values do not crash and are dropped", {
  p1 <- list(data = list(scenarios = "garbage", analysis = list(scenarios = list(sc("a")))))
  out1 <- migrate_legacy_scenarios(p1)
  expect_null(out1$data$scenarios)
  expect_equal(length(out1$data$analysis$scenarios), 1L)

  p2 <- list(data = list(scenarios = list(sc("b"), "not-a-scenario", 42)))
  out2 <- migrate_legacy_scenarios(p2)
  expect_equal(vapply(out2$data$analysis$scenarios, `[[`, "", "id"), "b")

  p3 <- list(data = list(scenarios = data.frame(id = "x", name = "y")))
  expect_no_error(out3 <- migrate_legacy_scenarios(p3))
  expect_null(out3$data$scenarios)
})

test_that("no legacy key, NULL data, non-list project: unchanged, no error", {
  p <- list(data = list(analysis = list(scenarios = list(sc("s1")))))
  expect_identical(migrate_legacy_scenarios(p), p)
  expect_identical(migrate_legacy_scenarios(list(data = NULL)), list(data = NULL))
  expect_identical(migrate_legacy_scenarios("x"), "x")
})

test_that("migration is idempotent", {
  p <- list(data = list(scenarios = list(sc("s1")), analysis = list()))
  once <- migrate_legacy_scenarios(p)
  expect_identical(migrate_legacy_scenarios(once), once)
})

test_that("normalize_and_reconcile_project applies the migration", {
  p <- create_empty_project("t")
  p$data$scenarios <- list(sc("legacy1"))
  out <- normalize_and_reconcile_project(p)
  expect_null(out$data$scenarios)
  expect_equal(vapply(out$data$analysis$scenarios, `[[`, "", "id"), "legacy1")
})
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `Rscript -e "testthat::test_file('tests/testthat/test-scenario-storage-migration.R')"`
Expected: FAIL with `could not find function "migrate_legacy_scenarios"`.

If `create_empty_project` has a different required signature, check it with `grep -n "^create_empty_project" functions/data_structure.R` and adapt only that call.

- [ ] **Step 3: Implement**

In `functions/data_structure.R`, directly above `normalize_and_reconcile_project <- function(`:

```r
#' Move legacy project$data$scenarios into project$data$analysis$scenarios
#'
#' The scenario builder historically saved to data$scenarios while the schema
#' (create_empty_project) declares data$analysis$scenarios. Merge by id;
#' entries already at the canonical location win. Non-list items are dropped.
#' Pure and idempotent. (WP5 spec WS-0)
#' @param project Project list
#' @return Project list with data$scenarios removed
migrate_legacy_scenarios <- function(project) {
  if (!is.list(project) || !is.list(project$data)) return(project)
  if (!"scenarios" %in% names(project$data)) return(project)

  legacy <- project$data$scenarios
  canonical <- project$data$analysis$scenarios
  if (!is.list(canonical) || is.data.frame(canonical)) canonical <- list()

  sid <- function(s) {
    v <- s$id
    if (is.null(v) || length(v) != 1 || is.na(v)) NA_character_ else as.character(v)
  }
  ids <- vapply(canonical, function(s) if (is.list(s)) sid(s) else NA_character_, character(1))

  dropped <- 0L
  if (is.list(legacy) && !is.data.frame(legacy)) {
    for (s in legacy) {
      if (!is.list(s) || is.data.frame(s)) { dropped <- dropped + 1L; next }
      id <- sid(s)
      if (!is.na(id) && id %in% ids) next
      canonical[[length(canonical) + 1L]] <- s
      ids <- c(ids, id)
    }
  } else if (!is.null(legacy)) {
    dropped <- 1L
  }
  if (dropped > 0L && exists("debug_log", mode = "function")) {
    debug_log(sprintf("migrate_legacy_scenarios: dropped %d malformed legacy scenario item(s)", dropped), "WP5")
  }

  if (!is.list(project$data$analysis)) project$data$analysis <- list()
  project$data$analysis$scenarios <- canonical
  project$data$scenarios <- NULL
  project
}
```

In `normalize_and_reconcile_project()`, after the Step 1 line `project <- normalize_json_project_data(project)`, add:

```r
  # Step 1b: legacy scenario location -> data$analysis$scenarios (WP5 WS-0)
  project <- migrate_legacy_scenarios(project)
```

Note: `normalize_json_project_data()` returns `NULL` for non-lists. The existing guard at the top of `normalize_and_reconcile_project()` already handles that case.

- [ ] **Step 4: Run the tests to verify they pass**

Run: `Rscript -e "testthat::test_file('tests/testthat/test-scenario-storage-migration.R')"`
Expected: all PASS.

Then run the load-path regression: `Rscript -e "testthat::test_file('tests/testthat/test-json-project-loading.R')"`
Expected: same pass count as on main, 0 failures.

- [ ] **Step 5: Commit**

```bash
git -C "<repo>" add functions/data_structure.R tests/testthat/test-scenario-storage-migration.R
git -C "<repo>" commit -m "fix(scenarios): migrate legacy data\$scenarios to data\$analysis\$scenarios on load (WP5 WS-0)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2: Scenario builder reads and writes the canonical location (WS-0 part 2)

**Files:**
- Modify: `modules/scenario_builder_module.R:113-120` (init observer) and `:1164-1169` (`save_scenarios_to_project`)
- Test: `tests/testthat/test-scenario-builder-module.R` (append)

**Interfaces:**
- Consumes: Task 1 guarantees that loaded projects have `data$analysis$scenarios`.
- Produces: the builder never writes `data$scenarios` again.

- [ ] **Step 1: Write the failing tests** (append to `tests/testthat/test-scenario-builder-module.R`)

```r
# ============================================================================
# WS-0: canonical storage at project$data$analysis$scenarios
# ============================================================================
# helper-stubs.R defines a stub scenario_builder_server in testthat's helper env
# that shadows the .GlobalEnv copy written by source_for_test(); re-bind the real
# one (pattern: test-entry-point-module.R).
real_scenario_builder_server <- get("scenario_builder_server", envir = .GlobalEnv)

test_that("builder loads scenarios from data$analysis$scenarios", {
  proj <- create_empty_project("t")
  proj$data$analysis$scenarios <- list(list(id = "s_can", name = "Canonical",
                                            modifications = list(), results = NULL))
  pd <- reactiveVal(proj)
  testServer(real_scenario_builder_server,
             args = list(project_data_reactive = pd, i18n = make_test_i18n()), {
    session$flushReact()
    expect_equal(vapply(scenarios(), `[[`, "", "id"), "s_can")
  })
})

test_that("save_scenarios_to_project writes canonical location and clears legacy", {
  proj <- create_empty_project("t")
  proj$data$scenarios <- list(list(id = "old"))   # stale legacy key in memory
  pd <- reactiveVal(proj)
  testServer(real_scenario_builder_server,
             args = list(project_data_reactive = pd, i18n = make_test_i18n()), {
    scenarios(list(list(id = "s_new", name = "New", modifications = list())))
    save_scenarios_to_project()
    saved <- pd()
    expect_null(saved$data$scenarios)
    expect_equal(vapply(saved$data$analysis$scenarios, `[[`, "", "id"), "s_new")
  })
})
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `Rscript -e "testthat::test_file('tests/testthat/test-scenario-builder-module.R')"`
Expected:
- The first new test fails: `scenarios()` is empty, because the module reads `data$data$scenarios`.
- The second fails: the legacy key is still present.

- [ ] **Step 3: Implement**

Replace the init observer body (`modules/scenario_builder_module.R:113-120`):

```r
    # Initialize scenarios from project data (canonical: data$analysis$scenarios;
    # legacy data$scenarios is migrated on load by migrate_legacy_scenarios())
    observe({
      req(project_data_reactive())
      data <- project_data_reactive()
      stored <- data$data$analysis$scenarios %||% data$data$scenarios
      if (!is.null(stored)) {
        scenarios(stored)
      }
    })
```

Replace `save_scenarios_to_project` (`:1164-1169`):

```r
    # Save scenarios to project data (canonical location; WP5 WS-0)
    save_scenarios_to_project <- function() {
      data <- project_data_reactive()
      if (!is.list(data$data$analysis)) data$data$analysis <- list()
      data$data$analysis$scenarios <- scenarios()
      data$data$scenarios <- NULL
      data$last_modified <- Sys.time()
      project_data_reactive(data)
    }
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `Rscript -e "testthat::test_file('tests/testthat/test-scenario-builder-module.R')"`
Expected: all PASS.

Then confirm no other writer remains: `grep -rn 'data\$data\$scenarios' modules functions server`. Expected: only the `%||%` fallback line in the init observer.

- [ ] **Step 5: Commit**

```bash
git -C "<repo>" add modules/scenario_builder_module.R tests/testthat/test-scenario-builder-module.R
git -C "<repo>" commit -m "fix(scenario-builder): read/write data\$analysis\$scenarios (WP5 WS-0)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 3: Monotonic `stamp_min_app_version()` (WS-0 part 3)

**Files:**
- Modify: `functions/data_structure.R`. Add the function directly after `migrate_legacy_scenarios()`.
- Test: `tests/testthat/test-scenario-storage-migration.R` (append; same WS-0 file)

**Interfaces:**
- Produces: `stamp_min_app_version(project, version) -> project`. It raises `project$min_app_version` to `version` only if `version` is higher, or if the field is missing or invalid. WS-4 and WS-6 call it when they first write new project blocks.

- [ ] **Step 1: Write the failing tests** (append)

```r
test_that("stamp_min_app_version only ever raises the version", {
  p <- list(min_app_version = "1.12.0")
  expect_equal(stamp_min_app_version(p, "1.22.0")$min_app_version, "1.22.0")
  expect_equal(stamp_min_app_version(list(min_app_version = "1.24.0"), "1.22.0")$min_app_version, "1.24.0")
  expect_equal(stamp_min_app_version(list(), "1.22.0")$min_app_version, "1.22.0")
  expect_equal(stamp_min_app_version(list(min_app_version = "garbage"), "1.22.0")$min_app_version, "1.22.0")
  expect_equal(stamp_min_app_version(list(min_app_version = "1.22.0"), "1.22.0")$min_app_version, "1.22.0")
})

test_that("stamp_min_app_version rejects an invalid target version", {
  expect_error(stamp_min_app_version(list(), "not-a-version"), "version")
  expect_identical(stamp_min_app_version("x", "1.22.0"), "x")
})
```

- [ ] **Step 2: Run to verify fail**

Run: `Rscript -e "testthat::test_file('tests/testthat/test-scenario-storage-migration.R')"`
Expected: FAIL, `could not find function "stamp_min_app_version"`.

- [ ] **Step 3: Implement**

```r
#' Raise project$min_app_version to `version` if it is higher (never lowers)
#'
#' Used by WP5 features that add optional project blocks, so an older app
#' version shows the downgrade warning in server/project_io.R. (WP5 spec WS-0)
#' @param project Project list
#' @param version Character "major.minor.patch"
#' @return Project list
stamp_min_app_version <- function(project, version) {
  valid <- function(v) is.character(v) && length(v) == 1 && grepl("^[0-9]+(\\.[0-9]+){1,3}$", v)
  if (!valid(version)) stop("stamp_min_app_version: invalid version '", version, "'")
  if (!is.list(project)) return(project)
  current <- project$min_app_version
  if (!valid(current) || utils::compareVersion(version, current) > 0) {
    project$min_app_version <- version
  }
  project
}
```

- [ ] **Step 4: Run to verify pass**

Run: `Rscript -e "testthat::test_file('tests/testthat/test-scenario-storage-migration.R')"`
Expected: all PASS.

- [ ] **Step 5: Commit**

```bash
git -C "<repo>" add functions/data_structure.R tests/testthat/test-scenario-storage-migration.R
git -C "<repo>" commit -m "feat(project): monotonic stamp_min_app_version helper (WP5 WS-0)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 4: Vocabulary constants and lookup helpers (WS-1 part 1)

**Files:**
- Modify: `constants.R`. Insert a new section **before** the `# END OF CONSTANTS` banner, after `WP5_DA_CONTEXTS`.
- Create: `functions/wp5_vocabulary.R`
- Modify: `global.R`. Add `source("functions/wp5_vocabulary.R", local = FALSE)` on the line after `source("functions/wp5_kb_loader.R", local = FALSE)` (currently line 706).
- Test: `tests/testthat/test-wp5-vocabulary.R` (new)

**Interfaces:**
- Produces constants:
  - `WP5_CRITERIA` (data.frame: `code`, `aliases` list-column)
  - `WP5_CRITERION_SUBDIMENSIONS` (named list)
  - `WP5_RUBRIC` (named list of code vectors)
  - `WP5_TIME_HORIZON_YEARS`
  - `EBM_POLICY_INSTRUMENTS` (data.frame: `code`, `category`, `level` ∈ {category, type})
  - `EBM_MANAGEMENT_MEASURES` (data.frame: `code`, `category`, `dapsiwrm_target`)
  - `EBM_TENETS` (data.frame: `code`, `scope` ∈ {measure, intervention})
  - `NPG_DIMENSIONS`
  - `GRAPH_EDIT_OPS`
- Produces functions:
  - `wp5_vocab_codes(vocab) -> character`
  - `wp5_criterion_code(x) -> character` (vectorised; `NA` for unknown)
  - `wp5_vocab_key(vocab, code) -> character` (the i18n key)
  - `wp5_vocab_label(vocab, code, i18n) -> character` (vectorised; falls back to the code)
- Vocabulary names accepted by `vocab`: `"criteria"`, `"subdimension"`, `"direction"`, `"magnitude"`, `"timing"`, `"confidence"`, `"evidence"`, `"uncertainty_driver"`, `"indicator_role"`, `"pathway_segment"`, `"instrument"`, `"measure"`, `"tenet"`, `"npg"`, `"graph_op"`.

- [ ] **Step 1: Write the failing tests**

```r
# tests/testthat/test-wp5-vocabulary.R
# WS-1: WP5 shared vocabulary. Codes are stored; labels resolve via i18n at render.
library(testthat)

test_that("criteria codes are the five D5.2 criteria; aliases resolve", {
  expect_equal(WP5_CRITERIA$code, c("EE", "EC", "EQ", "PI", "FF"))
  expect_equal(wp5_criterion_code(c("PI", "PO", "po", "FI", "ee")), c("PI", "PI", "PI", "FF", "EE"))
  expect_equal(wp5_criterion_code(c("XX", NA, "")), c(NA_character_, NA_character_, NA_character_))
})

test_that("rubric is ordinal D5.2 Phase-3 vocabulary (no numeric scales)", {
  expect_equal(WP5_RUBRIC$magnitude, c("incremental", "moderate", "substantial"))
  expect_equal(WP5_RUBRIC$direction, c("increase", "decrease", "no_change", "uncertain"))
  expect_equal(WP5_RUBRIC$timing, c("short", "medium", "long"))
  expect_equal(WP5_TIME_HORIZON_YEARS$long, c(8, 15))
  for (v in WP5_RUBRIC) expect_type(v, "character")
})

test_that("EBM instrument vocabulary matches the source (3.5 absent)", {
  types <- EBM_POLICY_INSTRUMENTS$code[EBM_POLICY_INSTRUMENTS$level == "type"]
  expect_equal(length(types), 20L)
  expect_false("3.5" %in% types)
  expect_true(all(c("1.1", "2.5", "3.7", "4.3") %in% types))
  expect_equal(EBM_POLICY_INSTRUMENTS$code[EBM_POLICY_INSTRUMENTS$level == "category"], c("1", "2", "3", "4"))
  expect_false(anyDuplicated(EBM_POLICY_INSTRUMENTS$code) > 0)
})

test_that("management measures carry a valid DAPSIWRM target", {
  expect_equal(nrow(EBM_MANAGEMENT_MEASURES), 12L)
  parts <- unlist(strsplit(EBM_MANAGEMENT_MEASURES$dapsiwrm_target, "|", fixed = TRUE))
  expect_true(all(parts %in% c("A", "P", "C")))
  expect_equal(EBM_MANAGEMENT_MEASURES$dapsiwrm_target[EBM_MANAGEMENT_MEASURES$code == "output"], "P")
})

test_that("tenets: 3 measure-level + 8 intervention-level = 11", {
  expect_equal(nrow(EBM_TENETS), 11L)
  expect_equal(sum(EBM_TENETS$scope == "measure"), 3L)
})

test_that("every vocabulary has unique codes", {
  for (v in c("criteria", "subdimension", "direction", "magnitude", "timing", "confidence",
              "evidence", "uncertainty_driver", "indicator_role", "pathway_segment",
              "instrument", "measure", "tenet", "npg", "graph_op")) {
    codes <- wp5_vocab_codes(v)
    expect_gt(length(codes), 0)
    expect_false(anyDuplicated(codes) > 0, info = v)
  }
  expect_error(wp5_vocab_codes("nope"), "Unknown WP5 vocabulary")
})

test_that("i18n keys use the modules.wp5_vocabulary namespace with dots->underscores", {
  expect_equal(wp5_vocab_key("instrument", "1.1"), "modules.wp5_vocabulary.instrument.1_1")
  expect_equal(wp5_vocab_key("measure", "spatial.year_round"),
               "modules.wp5_vocabulary.measure.spatial_year_round")
})

test_that("labels follow the active translator; stored codes never change", {
  en <- list(t = function(k) paste0("EN:", k))
  lt <- list(t = function(k) paste0("LT:", k))
  code <- "1.1"
  expect_equal(wp5_vocab_label("instrument", code, en), "EN:modules.wp5_vocabulary.instrument.1_1")
  expect_equal(wp5_vocab_label("instrument", code, lt), "LT:modules.wp5_vocabulary.instrument.1_1")
  expect_equal(code, "1.1")
})

test_that("labels for unknown/NA codes fall back to the code, never error", {
  idt <- list(t = function(k) k)   # shiny.i18n returns the key when missing
  expect_equal(wp5_vocab_label("instrument", c("9.9", NA), idt), c("9.9", ""))
  broken <- list(t = function(k) stop("boom"))
  expect_equal(wp5_vocab_label("instrument", "1.1", broken), "1.1")
})
```

- [ ] **Step 2: Run to verify fail**

Run: `Rscript -e "testthat::test_file('tests/testthat/test-wp5-vocabulary.R')"`
Expected: FAIL, `object 'WP5_CRITERIA' not found`.

- [ ] **Step 3a: Add constants to `constants.R`** (before the `# END OF CONSTANTS` banner)

```r
# ============================================================================
# WP5 SHARED VOCABULARY (spec 2026-10-11 WS-1)
# ============================================================================
# Codes only. Labels resolve at render time via wp5_vocab_label() /
# i18n key modules.wp5_vocabulary.<vocab>.<code, dots -> underscores>.
# Sources: D5.2 final v5 §1.3-1.5 and Phase-3 rubric (audit A§2.2-2.3);
# EBM framework & implementation guidance (audit C§2, D§3.2-3.4);
# D5.4 NPG dimensions (audit D§1.2); D5.3 graph-change matrix (audit C§1.1).

WP5_CRITERIA <- data.frame(
  code = c("EE", "EC", "EQ", "PI", "FF"),
  stringsAsFactors = FALSE
)
# D5.2 uses PO/FI in the indicator fiches for PI/FF (audit A§2.2)
WP5_CRITERIA$aliases <- I(list(character(), character(), character(), "PO", "FI"))

WP5_CRITERION_SUBDIMENSIONS <- list(
  EQ = c("distributional", "procedural", "recognitional"),
  PI = c("credibility", "manageability", "contestation_risk")
)

WP5_RUBRIC <- list(
  direction          = c("increase", "decrease", "no_change", "uncertain"),
  magnitude          = c("incremental", "moderate", "substantial"),
  timing             = c("short", "medium", "long"),
  confidence         = c("high", "medium", "low"),
  evidence           = c("dataset", "literature", "stakeholder", "da_judgement", "triangulation"),
  uncertainty_driver = c("data_gap", "contested_assumption", "weak_causal_link", "implementation_dependency"),
  indicator_role     = c("primary", "supporting"),
  pathway_segment    = c("pressure", "state", "benefit", "governance_capacity")
)

WP5_TIME_HORIZON_YEARS <- list(short = c(1, 3), medium = c(4, 7), long = c(8, 15))

# EBM policy instruments (R). Source numbering skips 3.5 (audit C§2.1).
EBM_POLICY_INSTRUMENTS <- data.frame(
  code = c("1", "1.1", "1.2", "1.3", "1.4", "1.5", "1.6",
           "2", "2.1", "2.2", "2.3", "2.4", "2.5",
           "3", "3.1", "3.2", "3.3", "3.4", "3.6", "3.7",
           "4", "4.1", "4.2", "4.3"),
  category = c(rep("legal_regulatory", 7), rep("voluntary_information", 6),
               rep("economic_incentive", 7), rep("research_development", 4)),
  level = c("category", rep("type", 6), "category", rep("type", 5),
            "category", rep("type", 6), "category", rep("type", 3)),
  stringsAsFactors = FALSE
)

# EBM management measures (M) with DAPSIWRM target (audit C§2.2)
EBM_MANAGEMENT_MEASURES <- data.frame(
  code = c("spatial.year_round", "spatial.seasonal", "input.capacity", "input.effort",
           "input.technical", "output", "remediation", "restoration.species",
           "restoration.habitat", "nbs.enhance", "nbs.multi_use", "nbs.replace"),
  category = c("spatial", "spatial", "input", "input", "input", "output", "remediation",
               "restoration", "restoration", "nbs", "nbs", "nbs"),
  dapsiwrm_target = c("A|P|C", "A|P|C", "A", "A", "A", "P", "P", "C", "C", "C", "A", "A"),
  stringsAsFactors = FALSE
)

# 11 tenets: 3 measure-level + 8 whole-intervention (audit C§3.3, D§3.4)
EBM_TENETS <- data.frame(
  code = c("ecol_effective", "tech_feasible", "econ_efficient",
           "econ_viable", "socially_desirable", "ethically_defensible", "culturally_inclusive",
           "legally_permissible", "admin_achievable", "communicable", "politically_expedient"),
  scope = c(rep("measure", 3), rep("intervention", 8)),
  stringsAsFactors = FALSE
)

NPG_DIMENSIONS <- c("knowledge", "collaboration", "values_conflict", "legitimacy_equity", "cross_sectoral")

# D5.3 graph-change operations: (+/-) reweight existing edge, (---) new edge, (o) new node
GRAPH_EDIT_OPS <- c("reweight_edge", "new_edge", "new_node")
```

- [ ] **Step 3b: Create `functions/wp5_vocabulary.R`**

```r
# functions/wp5_vocabulary.R
# WP5 shared vocabulary helpers (spec 2026-10-11 WS-1).
# Codes are stored in project data; labels resolve via i18n at render time.

.wp5_vocab_table <- function() {
  list(
    criteria           = WP5_CRITERIA$code,
    subdimension       = unique(unlist(WP5_CRITERION_SUBDIMENSIONS, use.names = FALSE)),
    direction          = WP5_RUBRIC$direction,
    magnitude          = WP5_RUBRIC$magnitude,
    timing             = WP5_RUBRIC$timing,
    confidence         = WP5_RUBRIC$confidence,
    evidence           = WP5_RUBRIC$evidence,
    uncertainty_driver = WP5_RUBRIC$uncertainty_driver,
    indicator_role     = WP5_RUBRIC$indicator_role,
    pathway_segment    = WP5_RUBRIC$pathway_segment,
    instrument         = EBM_POLICY_INSTRUMENTS$code,
    measure            = EBM_MANAGEMENT_MEASURES$code,
    tenet              = EBM_TENETS$code,
    npg                = NPG_DIMENSIONS,
    graph_op           = GRAPH_EDIT_OPS
  )
}

#' All codes of a WP5 vocabulary
#' @param vocab Vocabulary name (see .wp5_vocab_table())
#' @return Character vector of codes
wp5_vocab_codes <- function(vocab) {
  tbl <- .wp5_vocab_table()
  if (!is.character(vocab) || length(vocab) != 1 || !vocab %in% names(tbl)) {
    stop("Unknown WP5 vocabulary: ", paste(vocab, collapse = ","))
  }
  tbl[[vocab]]
}

#' Normalise criterion codes, resolving D5.2 aliases (PO -> PI, FI -> FF)
#' @param x Character vector
#' @return Character vector of canonical codes, NA for unknown/empty
wp5_criterion_code <- function(x) {
  x <- toupper(trimws(as.character(x)))
  lookup <- setNames(WP5_CRITERIA$code, WP5_CRITERIA$code)
  for (i in seq_len(nrow(WP5_CRITERIA))) {
    for (a in WP5_CRITERIA$aliases[[i]]) lookup[[a]] <- WP5_CRITERIA$code[i]
  }
  out <- unname(lookup[x])
  out[is.na(x) | x == ""] <- NA_character_
  as.character(out)
}

#' i18n key for a vocabulary code
#' @return Character vector of keys
wp5_vocab_key <- function(vocab, code) {
  paste0("modules.wp5_vocabulary.", vocab, ".", gsub(".", "_", code, fixed = TRUE))
}

#' Translated label for vocabulary codes; falls back to the code itself
#' @param vocab Vocabulary name
#' @param code Character vector of codes
#' @param i18n Translator with $t(key)
#' @return Character vector of labels ("" for NA codes)
wp5_vocab_label <- function(vocab, code, i18n) {
  vapply(as.character(code), function(cd) {
    if (is.na(cd) || cd == "") return("")
    key <- wp5_vocab_key(vocab, cd)
    lbl <- tryCatch(as.character(i18n$t(key)), error = function(e) NA_character_)
    if (length(lbl) != 1 || is.na(lbl) || lbl == "" || identical(lbl, key)) cd else lbl
  }, character(1), USE.NAMES = FALSE)
}
```

- [ ] **Step 3c: Source it from `global.R`** (after the `wp5_kb_loader.R` line)

```r
source("functions/wp5_vocabulary.R", local = FALSE)
```

- [ ] **Step 4: Run to verify pass**

Run: `Rscript -e "testthat::test_file('tests/testthat/test-wp5-vocabulary.R')"` → all PASS.
Run: `Rscript -e "testthat::test_file('tests/testthat/test-functions-sourced-in-app.R')"` → PASS, now including `wp5_vocabulary.R`.

- [ ] **Step 5: Commit**

```bash
git -C "<repo>" add constants.R functions/wp5_vocabulary.R global.R tests/testthat/test-wp5-vocabulary.R
git -C "<repo>" commit -m "feat(wp5): shared vocabulary constants + code/label helpers (WS-1)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 5: Vocabulary translations in 9 languages (WS-1 part 2)

**Files:**
- Create: `translations/modules/wp5_vocabulary.json`. The format matches `translations/modules/wp5_mechanisms.json`: `{"languages": [...9], "translation": {key: {en,…,el}}}`.
- Test: `tests/testthat/test-wp5-vocabulary.R` (append)

**Interfaces:**
- Consumes: `wp5_vocab_codes()` and `wp5_vocab_key()` from Task 4.
- Produces: one key for every (vocab, code) pair, ≈ 100 keys. Labels and definitions for the 30 intervention-type rows of Task 6 are deferred to WS-7, the first UI that shows them. `translations/_merged_translations.json` is auto-generated by `functions/translation_loader.R` at startup and must not be edited by hand.

- [ ] **Step 1: Write the failing tests** (append)

```r
.wp5_root <- function() { wd <- getwd(); if (basename(wd) == "testthat") dirname(dirname(wd)) else wd }
WP5_VOCAB_I18N <- file.path(.wp5_root(), "translations", "modules", "wp5_vocabulary.json")
LANGS9 <- c("en", "es", "fr", "de", "lt", "pt", "it", "no", "el")

test_that("every vocabulary code has a 9-language translation", {
  tr <- jsonlite::fromJSON(WP5_VOCAB_I18N, simplifyVector = FALSE)$translation
  vocabs <- c("criteria", "subdimension", "direction", "magnitude", "timing", "confidence",
              "evidence", "uncertainty_driver", "indicator_role", "pathway_segment",
              "instrument", "measure", "tenet", "npg", "graph_op")
  for (v in vocabs) for (cd in wp5_vocab_codes(v)) {
    k <- wp5_vocab_key(v, cd)
    expect_true(k %in% names(tr), info = k)
    for (l in LANGS9) expect_true(nzchar(tr[[k]][[l]] %||% ""), info = paste(k, l))
  }
})

test_that("translations are genuine, not English copies (>=90% differ per language)", {
  tr <- jsonlite::fromJSON(WP5_VOCAB_I18N, simplifyVector = FALSE)$translation
  for (l in setdiff(LANGS9, "en")) {
    same <- vapply(tr, function(e) identical(e[[l]], e$en), logical(1))
    expect_lt(mean(same), 0.10, label = paste("share identical to English for", l))
  }
})

test_that("no orphan keys in wp5_vocabulary.json", {
  tr <- jsonlite::fromJSON(WP5_VOCAB_I18N, simplifyVector = FALSE)$translation
  expected <- unlist(lapply(c("criteria", "subdimension", "direction", "magnitude", "timing",
    "confidence", "evidence", "uncertainty_driver", "indicator_role", "pathway_segment",
    "instrument", "measure", "tenet", "npg", "graph_op"),
    function(v) wp5_vocab_key(v, wp5_vocab_codes(v))))
  expect_setequal(names(tr), expected)
})
```

- [ ] **Step 2: Run to verify fail**

Run: `Rscript -e "testthat::test_file('tests/testthat/test-wp5-vocabulary.R')"`
Expected: FAIL, cannot open `wp5_vocabulary.json`.

- [ ] **Step 3: Author the translation file**

Write `translations/modules/wp5_vocabulary.json`. The English labels are fixed below. Translate each into es, fr, de, lt, pt, it, no and el:
- Use established EU / marine-policy terminology for that language. "Total allowable catch" and "certification scheme" have standard EU-official renderings, which you can check in IATE.
- Keep codes such as "EE" out of labels. Labels are words.
- Short identical terms are acceptable (e.g. "Nudging" in some languages), but the ≥90%-differ test must pass.

| Key suffix | English label |
|---|---|
| `criteria.EE` / `EC` / `EQ` / `PI` / `FF` | Environmental effectiveness / Economic efficiency / Equity and fairness / Policy implementability / Financial feasibility |
| `subdimension.distributional` / `procedural` / `recognitional` | Distributional equity / Procedural equity / Recognitional equity |
| `subdimension.credibility` / `manageability` / `contestation_risk` | Credibility / Manageability / Contestation risk |
| `direction.increase` / `decrease` / `no_change` / `uncertain` | Increase / Decrease / No material change / Uncertain |
| `magnitude.incremental` / `moderate` / `substantial` | Incremental / Moderate / Substantial |
| `timing.short` / `medium` / `long` | Short term (1–3 years) / Medium term (4–7 years) / Long term (8–15 years) |
| `confidence.high` / `medium` / `low` | High confidence / Medium confidence / Low confidence |
| `evidence.dataset` / `literature` / `stakeholder` / `da_judgement` / `triangulation` | Dataset / Literature / Stakeholder elicitation / Demonstration-area judgement / Triangulation |
| `uncertainty_driver.data_gap` / `contested_assumption` / `weak_causal_link` / `implementation_dependency` | Data gap / Contested assumption / Weak causal link / Implementation dependency |
| `indicator_role.primary` / `supporting` | Primary indicator / Supporting indicator |
| `pathway_segment.pressure` / `state` / `benefit` / `governance_capacity` | Pressure / State / Benefit / Governance capacity |
| `instrument.1` … `1_6` | Legal and regulatory instruments; Standards, limits and requirements; Supervision and enforcement; Treaties; Targets and policy development; Monitoring systems; Bans |
| `instrument.2` … `2_5` | Voluntary agreements and information instruments; Codes of conduct; Certification schemes; Awareness campaigns and education; Labelling; Nudging |
| `instrument.3`, `3_1` … `3_4`, `3_6`, `3_7` | Economic incentive-based instruments; Subsidies and grants; Tariffs; Deposit-refund schemes; Taxes (relief) and charges; Liability schemes; Individual tradeable quotas / cap-and-trade |
| `instrument.4` … `4_3` | Research and development (knowledge base); Research, monitoring and investment programmes; Impact assessments; Evaluation |
| `measure.spatial_year_round` / `spatial_seasonal` | Year-round spatial restriction (MPA, no-take, OECM) / Seasonal closure or restriction |
| `measure.input_capacity` / `input_effort` / `input_technical` | Input control: capacity / Input control: effort / Input control: technical measures |
| `measure.output` / `remediation` | Output control (e.g. TAC/quota) / Remediation |
| `measure.restoration_species` / `restoration_habitat` | Species (stock) restoration / Habitat restoration |
| `measure.nbs_enhance` / `nbs_multi_use` / `nbs_replace` | Nature-based solution: enhance ecosystem state / Multi-use / Replace existing activities |
| `tenet.*` (11) | Ecologically effective; Technologically feasible; Economically efficient; Economically viable; Socially desirable or tolerable; Ethically defensible; Culturally inclusive; Legally permissible; Administratively achievable; Effectively communicable; Politically expedient |
| `npg.*` (5) | Incorporation of knowledge; Collaborative structures; Values, conflicts and decision-making; Democratic legitimacy and equitable outcomes; Cross-sectoral coordination |
| `graph_op.reweight_edge` / `new_edge` / `new_node` | Change sign or weight of an existing link / Add a new link / Add a new element |

The full key is `modules.wp5_vocabulary.<row key suffix>`. For example, `instrument.1_1` becomes `modules.wp5_vocabulary.instrument.1_1`. The instrument category rows use `instrument.1`, `instrument.2`, `instrument.3` and `instrument.4`.

- [ ] **Step 4: Run to verify pass**

Run each of the following:
- `Rscript -e "testthat::test_file('tests/testthat/test-wp5-vocabulary.R')"` → all PASS.
- `micromamba run -n shiny python scripts/_i18n_audit.py` → `missing=0`, `hardcoded=0`, and no `wp5_vocabulary` keys in the English-fallback report.
- `Rscript -e "testthat::test_file('tests/testthat/test-i18n-enforcement.R')"` → PASS.

- [ ] **Step 5: Commit**

```bash
git -C "<repo>" add translations/modules/wp5_vocabulary.json tests/testthat/test-wp5-vocabulary.R
git -C "<repo>" commit -m "feat(i18n): WP5 vocabulary labels in 9 languages (WS-1)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 6: Intervention → graph-operation reference table and loader (WS-1 part 3)

**Files:**
- Create: `data/wp5_intervention_ops.json`
- Modify: `functions/wp5_vocabulary.R` (append the loader and lookups)
- Test: `tests/testthat/test-wp5-intervention-ops.R` (new)

**Interfaces:**
- Consumes: `GRAPH_EDIT_OPS` and `EBM_POLICY_INSTRUMENTS` / `EBM_MANAGEMENT_MEASURES` codes from Task 4.
- Produces:
  - `load_wp5_intervention_ops(path = NULL, force_reload = FALSE) -> list | NULL`. Cached, and warns on a missing or corrupt file.
  - `get_intervention_types(group = NULL) -> data.frame(id, group, provenance)`
  - `get_allowed_graph_ops(id, context = NULL) -> data.frame(op, source)`. This returns the **union** of the xlsx and EBM operations, each tagged with its source. A row with `context` equal to the requested DA overrides the master row.
- Consumed later by WS-7 (intervention designer).

- [ ] **Step 1: Write the failing tests**

```r
# tests/testthat/test-wp5-intervention-ops.R
# WS-1: D5.3 intervention -> SES-graph-change table (audit C§1.2-1.4, C§2.3).
library(testthat)

.root <- function() { wd <- getwd(); if (basename(wd) == "testthat") dirname(dirname(wd)) else wd }
OPS_PATH <- file.path(.root(), "data", "wp5_intervention_ops.json")

test_that("table loads: 23 master rows + 7 T5.4 governance rows", {
  db <- load_wp5_intervention_ops(OPS_PATH, force_reload = TRUE)
  expect_false(is.null(db))
  src <- vapply(db$interventions, `[[`, "", "source")
  expect_equal(sum(src == "master"), 23L)
  expect_equal(sum(src == "T5.4"), 7L)
})

test_that("every row is valid: group, ops, ebm_code, provenance", {
  db <- load_wp5_intervention_ops(OPS_PATH, force_reload = TRUE)
  valid_codes <- c(EBM_POLICY_INSTRUMENTS$code, EBM_MANAGEMENT_MEASURES$code)
  for (r in db$interventions) {
    expect_true(r$group %in% c("behavioural", "management", "economic", "governance"), info = r$id)
    expect_true(all(unlist(r$ops_xlsx) %in% GRAPH_EDIT_OPS), info = r$id)
    expect_true(all(unlist(r$ops_ebm) %in% GRAPH_EDIT_OPS), info = r$id)
    expect_true(all(unlist(r$ebm_code) %in% valid_codes), info = r$id)
    expect_true(r$provenance %in% c("wp5_source", "wp5_derived", "toolbox_extension", "provisional"))
    expect_true(nzchar(r$source_ref %||% ""), info = r$id)
    if (length(unlist(r$ebm_code)) > 0) expect_equal(r$ebm_code_provenance, "provisional", info = r$id)
  }
  ids <- vapply(db$interventions, `[[`, "", "id")
  expect_false(anyDuplicated(ids) > 0)
})

test_that("allowed ops = union of xlsx and EBM, tagged by source", {
  load_wp5_intervention_ops(OPS_PATH, force_reload = TRUE)
  nudge <- get_allowed_graph_ops("nudge")
  expect_setequal(nudge$op, c("reweight_edge", "new_edge"))
  expect_equal(nudge$source[nudge$op == "new_edge"], "ebm")
  expect_true("xlsx" %in% strsplit(nudge$source[nudge$op == "reweight_edge"], "+", fixed = TRUE)[[1]])
  mpa <- get_allowed_graph_ops("mpa_oecm")
  expect_setequal(mpa$op, GRAPH_EDIT_OPS)
})

test_that("unknown id returns empty frame; unknown context falls back to master", {
  load_wp5_intervention_ops(OPS_PATH, force_reload = TRUE)
  expect_equal(nrow(get_allowed_graph_ops("does_not_exist")), 0L)
  expect_equal(get_allowed_graph_ops("nudge", context = "atlantis"), get_allowed_graph_ops("nudge"))
})

test_that("missing or corrupt file: warning + empty results, no error", {
  expect_warning(res <- load_wp5_intervention_ops(file.path(tempdir(), "nope.json"), force_reload = TRUE))
  expect_null(res)
  expect_equal(nrow(get_allowed_graph_ops("nudge")), 0L)
  bad <- tempfile(fileext = ".json"); writeLines("{not json", bad)
  expect_warning(load_wp5_intervention_ops(bad, force_reload = TRUE))
  expect_equal(nrow(get_intervention_types()), 0L)
  load_wp5_intervention_ops(OPS_PATH, force_reload = TRUE)   # restore for later tests
})
```

- [ ] **Step 2: Run to verify fail**

Run: `Rscript -e "testthat::test_file('tests/testthat/test-wp5-intervention-ops.R')"`
Expected: FAIL, `could not find function "load_wp5_intervention_ops"`.

- [ ] **Step 3a: Create `data/wp5_intervention_ops.json`**

The 29 rows come from audit C§1.2 / §1.3 (`ops_xlsx`, master sheet + Task 5.4 sheet), C§1.4 (`ops_ebm`, only where the EBM framework gives marks for the mapped code; otherwise `[]`) and C§2.3 (`ebm_code`, a toolbox proposal, so `ebm_code_provenance: "provisional"`).
- `definition_source` is the D5.3 line cited in C§1.2, or `null` where D5.3 gives no definition. Those rows get `"provenance": "provisional"`.
- Rows where the operations come from the source get `"provenance": "wp5_source"`.

```json
{
  "version": "1.0.0",
  "description": "D5.3 intervention typology mapped to SES-graph change operations. ops_xlsx: WP5 matrix xlsx (master + Task 5.4 sheets). ops_ebm: EBM framework marks for the mapped code where the source gives them. ebm_code: toolbox proposal pending WP5 confirmation (spec Q4).",
  "last_updated": "2026-10-11",
  "source_documents": [
    "WP5/Task 5.3 Societal Behaviour Change/intervention to SES modification/WP5 matrix of changes to SES graph associated with interventions.xlsx",
    "WP5/Task 5.3 Societal Behaviour Change/intervention to SES modification/Framework for EBM_link added.docx",
    "docs/wp5-source-audit/2026-10-11/C_D5.3_interventions.md"
  ],
  "open_issues": [
    "xlsx and EBM framework disagree for nudge, mpa_oecm, quota_license, externalities_in_prices (audit C§1.4)",
    "~12 rows undefined in D5.3 (audit C§0.3, CBG comment)",
    "EBM instrument code 3.5 missing in source",
    "CBG requests per-DA matrices; no restoration/State row in the xlsx"
  ],
  "interventions": [
    {"id": "nudge", "group": "behavioural", "source": "master", "ops_xlsx": ["reweight_edge"], "ops_ebm": ["reweight_edge", "new_edge"], "ebm_code": ["2.5"], "ebm_code_provenance": "provisional", "definition_source": "D5.3 final FIN:528", "provenance": "wp5_source", "source_ref": "matrix xlsx master row 'Nudge'; EBM:191-192"},
    {"id": "certification", "group": "behavioural", "source": "master", "ops_xlsx": ["reweight_edge"], "ops_ebm": ["reweight_edge"], "ebm_code": ["2.2"], "ebm_code_provenance": "provisional", "definition_source": "EBM:165", "provenance": "wp5_source", "source_ref": "matrix xlsx master row 'Certification'; EBM:167"},
    {"id": "traceability", "group": "behavioural", "source": "master", "ops_xlsx": ["reweight_edge"], "ops_ebm": [], "ebm_code": ["1.5", "2.4"], "ebm_code_provenance": "provisional", "definition_source": null, "provenance": "provisional", "source_ref": "matrix xlsx master row 'Traceability'"},
    {"id": "norms_influence", "group": "behavioural", "source": "master", "ops_xlsx": ["reweight_edge", "new_edge"], "ops_ebm": [], "ebm_code": ["2.3", "2.5"], "ebm_code_provenance": "provisional", "definition_source": "D5.3 final FIN:538", "provenance": "wp5_source", "source_ref": "matrix xlsx master row 'Norms influence'"},
    {"id": "data_valuing", "group": "behavioural", "source": "master", "ops_xlsx": ["new_edge", "new_node"], "ops_ebm": [], "ebm_code": ["4.1"], "ebm_code_provenance": "provisional", "definition_source": null, "provenance": "provisional", "source_ref": "matrix xlsx master row 'Data valuing'"},
    {"id": "change_in_accessibility", "group": "behavioural", "source": "master", "ops_xlsx": ["reweight_edge"], "ops_ebm": [], "ebm_code": [], "ebm_code_provenance": "provisional", "definition_source": null, "provenance": "provisional", "source_ref": "matrix xlsx master row 'Change in accessibility'"},
    {"id": "participation_in_governance", "group": "behavioural", "source": "master", "ops_xlsx": ["new_edge", "new_node"], "ops_ebm": [], "ebm_code": [], "ebm_code_provenance": "provisional", "definition_source": null, "provenance": "provisional", "source_ref": "matrix xlsx master row 'Change in participation in governance'"},
    {"id": "cascade_creation", "group": "behavioural", "source": "master", "ops_xlsx": ["new_edge"], "ops_ebm": [], "ebm_code": [], "ebm_code_provenance": "provisional", "definition_source": null, "provenance": "provisional", "source_ref": "matrix xlsx master row 'Cascade creation'"},
    {"id": "remote_market_access", "group": "behavioural", "source": "master", "ops_xlsx": ["new_edge"], "ops_ebm": [], "ebm_code": [], "ebm_code_provenance": "provisional", "definition_source": null, "provenance": "provisional", "source_ref": "matrix xlsx master row 'Remote market access'"},
    {"id": "change_in_practices", "group": "behavioural", "source": "master", "ops_xlsx": ["reweight_edge"], "ops_ebm": [], "ebm_code": [], "ebm_code_provenance": "provisional", "definition_source": null, "provenance": "provisional", "source_ref": "matrix xlsx master row 'change in practices'"},
    {"id": "quota_license", "group": "management", "source": "master", "ops_xlsx": ["new_edge"], "ops_ebm": ["reweight_edge"], "ebm_code": ["1.1", "output", "input.capacity"], "ebm_code_provenance": "provisional", "definition_source": null, "provenance": "provisional", "source_ref": "matrix xlsx master row 'quota/license'; EBM:107, EBM:341"},
    {"id": "mpa_oecm", "group": "management", "source": "master", "ops_xlsx": ["new_edge", "new_node"], "ops_ebm": ["reweight_edge", "new_edge", "new_node"], "ebm_code": ["1.1", "spatial.year_round"], "ebm_code_provenance": "provisional", "definition_source": "D5.3 final FIN:836; GUID:113-117", "provenance": "wp5_source", "source_ref": "matrix xlsx master row 'mpa/oecm'; EBM:301-309"},
    {"id": "subsidies", "group": "economic", "source": "master", "ops_xlsx": ["reweight_edge"], "ops_ebm": ["reweight_edge"], "ebm_code": ["3.1"], "ebm_code_provenance": "provisional", "definition_source": "EBM:196-198", "provenance": "wp5_source", "source_ref": "matrix xlsx master row 'subsidies'; EBM:199"},
    {"id": "incentives", "group": "economic", "source": "master", "ops_xlsx": ["reweight_edge", "new_edge"], "ops_ebm": ["reweight_edge", "new_edge"], "ebm_code": ["3"], "ebm_code_provenance": "provisional", "definition_source": "EBM:58-61", "provenance": "wp5_source", "source_ref": "matrix xlsx master row 'incentives'; EBM:63-64 (category 3)"},
    {"id": "trade_agreements", "group": "economic", "source": "master", "ops_xlsx": ["reweight_edge", "new_node"], "ops_ebm": [], "ebm_code": ["1.3", "3.2"], "ebm_code_provenance": "provisional", "definition_source": null, "provenance": "provisional", "source_ref": "matrix xlsx master row 'trade agreements'"},
    {"id": "payment_goods_services", "group": "economic", "source": "master", "ops_xlsx": ["reweight_edge", "new_edge"], "ops_ebm": [], "ebm_code": [], "ebm_code_provenance": "provisional", "definition_source": null, "provenance": "provisional", "source_ref": "matrix xlsx master row 'payment for goods and services'"},
    {"id": "payment_non_market_services", "group": "economic", "source": "master", "ops_xlsx": ["new_edge"], "ops_ebm": [], "ebm_code": [], "ebm_code_provenance": "provisional", "definition_source": null, "provenance": "provisional", "source_ref": "matrix xlsx master row 'payment for non-market goods and services'"},
    {"id": "externalities_in_prices", "group": "economic", "source": "master", "ops_xlsx": ["reweight_edge", "new_edge"], "ops_ebm": ["reweight_edge"], "ebm_code": ["3.4"], "ebm_code_provenance": "provisional", "definition_source": "EBM:221", "provenance": "wp5_source", "source_ref": "matrix xlsx master row 'introduce externalities in prices'; EBM:223"},
    {"id": "one_off_recosting", "group": "economic", "source": "master", "ops_xlsx": ["new_edge"], "ops_ebm": [], "ebm_code": [], "ebm_code_provenance": "provisional", "definition_source": null, "provenance": "provisional", "source_ref": "matrix xlsx master row 'one-off recosting'"},
    {"id": "ongoing_recosting", "group": "economic", "source": "master", "ops_xlsx": ["reweight_edge"], "ops_ebm": [], "ebm_code": [], "ebm_code_provenance": "provisional", "definition_source": null, "provenance": "provisional", "source_ref": "matrix xlsx master row 'ongoing recosting'"},
    {"id": "multi_level_governance", "group": "governance", "source": "master", "ops_xlsx": ["new_edge", "new_node"], "ops_ebm": [], "ebm_code": [], "ebm_code_provenance": "provisional", "definition_source": null, "provenance": "provisional", "source_ref": "matrix xlsx master row 'introduce multi-level governance'"},
    {"id": "change_power_dynamics", "group": "governance", "source": "master", "ops_xlsx": ["reweight_edge", "new_edge"], "ops_ebm": [], "ebm_code": [], "ebm_code_provenance": "provisional", "definition_source": null, "provenance": "provisional", "source_ref": "matrix xlsx master row 'change power dynamics'"},
    {"id": "cross_sector_coordination", "group": "governance", "source": "master", "ops_xlsx": ["new_edge"], "ops_ebm": [], "ebm_code": [], "ebm_code_provenance": "provisional", "definition_source": null, "provenance": "provisional", "source_ref": "matrix xlsx master row 'introduce cross-sector coordination'"},
    {"id": "enhance_governance_capacity", "group": "governance", "source": "T5.4", "ops_xlsx": ["reweight_edge"], "ops_ebm": [], "ebm_code": [], "ebm_code_provenance": "provisional", "definition_source": null, "provenance": "provisional", "source_ref": "matrix xlsx 'Task 5.4' sheet, preliminary proposals"},
    {"id": "incorporate_society_values", "group": "governance", "source": "T5.4", "ops_xlsx": ["new_edge"], "ops_ebm": [], "ebm_code": [], "ebm_code_provenance": "provisional", "definition_source": null, "provenance": "provisional", "source_ref": "matrix xlsx 'Task 5.4' sheet, preliminary proposals"},
    {"id": "enhance_trust", "group": "governance", "source": "T5.4", "ops_xlsx": ["new_edge"], "ops_ebm": [], "ebm_code": [], "ebm_code_provenance": "provisional", "definition_source": null, "provenance": "provisional", "source_ref": "matrix xlsx 'Task 5.4' sheet, preliminary proposals"},
    {"id": "reduce_conflicts", "group": "governance", "source": "T5.4", "ops_xlsx": ["reweight_edge", "new_edge"], "ops_ebm": [], "ebm_code": [], "ebm_code_provenance": "provisional", "definition_source": null, "provenance": "provisional", "source_ref": "matrix xlsx 'Task 5.4' sheet, preliminary proposals"},
    {"id": "increase_collaboration", "group": "governance", "source": "T5.4", "ops_xlsx": ["reweight_edge"], "ops_ebm": [], "ebm_code": [], "ebm_code_provenance": "provisional", "definition_source": null, "provenance": "provisional", "source_ref": "matrix xlsx 'Task 5.4' sheet, preliminary proposals"},
    {"id": "increase_participation", "group": "governance", "source": "T5.4", "ops_xlsx": ["reweight_edge"], "ops_ebm": [], "ebm_code": [], "ebm_code_provenance": "provisional", "definition_source": null, "provenance": "provisional", "source_ref": "matrix xlsx 'Task 5.4' sheet, preliminary proposals"},
    {"id": "enhance_compliance_monitoring", "group": "governance", "source": "T5.4", "ops_xlsx": ["reweight_edge", "new_edge"], "ops_ebm": [], "ebm_code": ["1.2", "1.5"], "ebm_code_provenance": "provisional", "definition_source": null, "provenance": "provisional", "source_ref": "matrix xlsx 'Task 5.4' sheet, preliminary proposals"}
  ]
}
```

Count check: the master sheet has **23** rows (10 behavioural, 2 management, 8 economic, 3 governance; audit C§1.2), plus 7 T5.4 rows, for 30 in total. The test in Step 1 asserts these counts.

- [ ] **Step 3b: Append the loader to `functions/wp5_vocabulary.R`**

```r
# ------------------------------------------------------------------------------
# D5.3 intervention -> graph-operation table (data/wp5_intervention_ops.json)
# ------------------------------------------------------------------------------
.wp5_ops_env <- new.env(parent = emptyenv())
.wp5_ops_env$db <- NULL

#' Load the intervention->graph-operation table (cached)
#' @return Parsed list, or NULL (with a warning) if missing/corrupt
load_wp5_intervention_ops <- function(path = NULL, force_reload = FALSE) {
  if (!is.null(.wp5_ops_env$db) && !force_reload) return(invisible(.wp5_ops_env$db))
  if (is.null(path)) {
    path <- if (exists("get_project_file", mode = "function")) {
      get_project_file("data", "wp5_intervention_ops.json")
    } else file.path("data", "wp5_intervention_ops.json")
  }
  .wp5_ops_env$db <- NULL
  if (!file.exists(path)) {
    warning(sprintf("[WP5 vocab] intervention ops table not found at: %s", path))
    return(invisible(NULL))
  }
  db <- tryCatch(jsonlite::fromJSON(path, simplifyVector = FALSE), error = function(e) {
    warning(sprintf("[WP5 vocab] failed to parse intervention ops table: %s", e$message))
    NULL
  })
  .wp5_ops_env$db <- db
  if (!is.null(db) && exists("debug_log", mode = "function")) {
    debug_log(sprintf("WP5 intervention ops loaded: %d rows", length(db$interventions)), "WP5")
  }
  invisible(db)
}

#' Intervention types, optionally filtered by group
#' @return data.frame(id, group, provenance) (0 rows if table unavailable)
get_intervention_types <- function(group = NULL) {
  rows <- .wp5_ops_env$db$interventions %||% list()
  rows <- Filter(function(r) is.null(r$context), rows)
  if (!is.null(group)) rows <- Filter(function(r) identical(r$group, group), rows)
  data.frame(
    id = vapply(rows, function(r) r$id, character(1)),
    group = vapply(rows, function(r) r$group, character(1)),
    provenance = vapply(rows, function(r) r$provenance, character(1)),
    stringsAsFactors = FALSE
  )
}

#' Allowed graph-edit operations for an intervention type
#'
#' Union of xlsx and EBM operations, each tagged by source ("xlsx", "ebm",
#' or "xlsx+ebm"). A row whose `context` equals the requested DA overrides the
#' master row; unknown contexts fall back to master. (spec WS-1, Q4)
#' @return data.frame(op, source) ordered as GRAPH_EDIT_OPS; 0 rows if unknown
get_allowed_graph_ops <- function(id, context = NULL) {
  rows <- .wp5_ops_env$db$interventions %||% list()
  pick <- NULL
  if (!is.null(context)) {
    pick <- Find(function(r) identical(r$id, id) && identical(r$context, context), rows)
  }
  if (is.null(pick)) pick <- Find(function(r) identical(r$id, id) && is.null(r$context), rows)
  if (is.null(pick)) return(data.frame(op = character(), source = character(), stringsAsFactors = FALSE))
  x <- unlist(pick$ops_xlsx); e <- unlist(pick$ops_ebm)
  ops <- GRAPH_EDIT_OPS[GRAPH_EDIT_OPS %in% c(x, e)]
  src <- vapply(ops, function(o) paste(c(if (o %in% x) "xlsx", if (o %in% e) "ebm"), collapse = "+"),
                character(1), USE.NAMES = FALSE)
  data.frame(op = ops, source = src, stringsAsFactors = FALSE)
}

# Auto-load on source if data file present (mirrors wp5_kb_loader.R)
if (file.exists("data/wp5_intervention_ops.json")) {
  suppressWarnings(load_wp5_intervention_ops())
}
```

- [ ] **Step 4: Run to verify pass**

Run each of the following:
- `Rscript -e "testthat::test_file('tests/testthat/test-wp5-intervention-ops.R')"` → all PASS.
- `Rscript -e "testthat::test_file('tests/testthat/test-wp5-vocabulary.R')"` → still PASS.

- [ ] **Step 5: Commit**

```bash
git -C "<repo>" add data/wp5_intervention_ops.json functions/wp5_vocabulary.R tests/testthat/test-wp5-intervention-ops.R
git -C "<repo>" commit -m "feat(wp5): D5.3 intervention->graph-operation table + loader (WS-1)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 7: Full-suite regression, CHANGELOG, PR

**Files:**
- Modify: `CHANGELOG.md` (add an entry under `[Unreleased]`)

- [ ] **Step 1: Run the full test suite**

Run: `Rscript -e "testthat::test_dir('tests/testthat')"`
Expected: 0 failures. The pass count is ≥ main's, plus the new tests. If the suite has known flakes, list any failure that also fails on `origin/main` (check with `git -C "<repo>" stash; …`) and do not count it.

- [ ] **Step 2: Run the i18n audit**

Run: `micromamba run -n shiny python scripts/_i18n_audit.py`
Expected: missing=0, hardcoded=0.

- [ ] **Step 3: Add the CHANGELOG entry**

```markdown
### Added (WP5 foundation — spec 2026-10-11 WS-0/WS-1)
- WP5 shared vocabulary: D5.2 criteria (EE/EC/EQ/PI/FF with PO/FI aliases), ordinal impact rubric, time horizons, EBM policy-instrument and management-measure typologies, 11 tenets, NPG governance dimensions, D5.3 graph-edit operations (`constants.R`, `functions/wp5_vocabulary.R`, `translations/modules/wp5_vocabulary.json`, 9 languages).
- `data/wp5_intervention_ops.json`: D5.3 intervention typology → SES-graph change operations with per-row provenance; EBM-code mapping marked provisional pending WP5 confirmation.
- `stamp_min_app_version()` helper (never lowers the stamped version).

### Fixed
- Scenario Builder now stores scenarios at `data$analysis$scenarios` (the schema location); legacy `data$scenarios` is migrated on every load path.
```

- [ ] **Step 4: Commit and open the PR**

```bash
git -C "<repo>" add CHANGELOG.md
git -C "<repo>" commit -m "docs(changelog): WP5 foundation WS-0/WS-1

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
git -C "<repo>" push -u origin feat/wp5-foundation
gh pr create --repo razinkele/MarineSABRES_SES_Shiny --base main --head feat/wp5-foundation \
  --title "WP5 foundation: scenario storage fix + shared vocabulary (WS-0/WS-1)" \
  --body "Implements WS-0 and WS-1 of docs/superpowers/specs/2026-10-11-wp5-practical-integration-specs.md. No UI changes. See plan docs/superpowers/plans/2026-10-11-wp5-ws0-ws1-foundation.md.

🤖 Generated with [Claude Code](https://claude.com/claude-code)"
```

Pushing and opening the PR is outward-facing, so confirm with the user before running this step.
