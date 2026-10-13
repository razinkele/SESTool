# WP5 WS-6c: Auto-drafted trade-off narrative + Word/Excel impact report — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Finish the WP5 impact-assessment module: step 6 gets a one-click, deterministic, 9-language draft of the trade-off narrative built from the criterion × scenario matrix, and step 7 gets "Download Word report" / "Download Excel report" buttons that export the whole assessment with a linked-mechanisms appendix and a provenance appendix.

**Architecture:** One new pure file, `functions/impact_assessment_report.R`, holds three things: `impact_narrative_draft(ia, i18n)` (templated sentences, the `build_decision_narrative()` pattern — every word comes from an i18n key, nothing is generated), `impact_report_data(project, ia, i18n)` (one data-preparation function that turns an assessment into translated data frames and text blocks), and two renderers that consume that data: `build_impact_report_docx()` (officer + flextable) and `build_impact_report_xlsx()` (openxlsx). The module (`modules/impact_assessment_module.R`) only adds a draft button on step 6 and two download handlers on step 7, all going through the existing `try_commit()` / hardening patterns. No new stored field: `trade_offs$auto_draft` already exists in the WS-6a schema.

**Tech Stack:** R ≥ 4.4.1, shiny, bs4Dash, shiny.i18n (9 languages), officer 0.7.x, flextable 0.9.x, openxlsx 4.2.x (all in DESCRIPTION and installed), jsonlite, testthat. WS-6a/6b code: `functions/impact_assessment_model.R`, `functions/impact_assessment_view.R`, `functions/impact_reference.R`, `functions/wp5_vocabulary.R`, `functions/wp5_kb_loader.R`, `functions/indicator_registry.R`.

**Spec:** `docs/superpowers/specs/2026-10-11-wp5-practical-integration-specs.md` §WS-6 (change 6 "Step 6 auto-draft", "Files and reports" L346-348) and principles P1–P7; roadmap `docs/superpowers/specs/2026-05-06-wp5-integration-roadmap-design.md` §8.6 (report sections) and §8.7 (report tests). Code facts for the module: `docs/superpowers/plans/2026-10-13-wp5-ws6b-code-map.md`.

## Global Constraints

- Store codes, translate on display (P2): rubric labels come from `wp5_vocab_label(<vocab>, code, i18n)` with vocabularies `criteria`, `direction`, `magnitude`, `timing`, `confidence`, `evidence`, `uncertainty_driver`, `indicator_role`, `subdimension`.
- Ordinal only (P4): the narrative and the report never count, weight, score or average cells. The only numbers are counts of scenarios and of unassessed cells.
- Published values verbatim (P3): copied reference cells are reproduced as stored; the report never re-reads D5.2 text for the body, only for the provenance appendix metadata.
- Provenance (P1/P5): the auto-draft is a `toolbox_extension` and is badged as such in the UI and labelled as such in the report; the provenance appendix lists every copied reference cell (with `ref_version`, and whether it was edited since the copy, via `impact_cell_edited_since_copy()`), every linked mechanism or indicator whose provenance is not `wp5_source`, and every toolbox extension used.
- Deviation from spec L347, recorded here: `generate_word_report()` in `modules/prepare_report_module.R:620` is one monolithic function for the whole project, not a set of helpers, so this plan does not call it. The new builder follows its officer + flextable style (`officer::read_docx()`, `body_add_par(style = "heading 2")`, `flextable::theme_vanilla`, `flextable::body_add_flextable`) and its hardening pattern (`tryCatch` + `stop(e)` in the download handler).
- NO new stored field. `IMPACT_SCHEMA_VERSION` (1) and `WP5_IMPACT_MIN_APP_VERSION` ("1.25.0") stay unchanged. `trade_offs$auto_draft` is already whitelisted by `IMPACT_TEXT_SECTIONS$trade_offs`.
- Every new `functions/*.R` file is `source()`d in `global.R` with a literal `source("functions/<file>.R", local = FALSE)` line (test-functions-sourced-in-app.R).
- Never emit `emit_isa_change` / `emit_cld_update` for assessment writes.
- i18n: every chrome key in all 9 languages (`en, es, fr, de, lt, pt, it, no, el`) in `translations/modules/impact_assessment.json`; `micromamba run -n shiny python scripts/_i18n_audit.py` must report `missing=0 hardcoded=0`; dynamic keys (built with `paste0`) need `# i18n-ref: <key>` sentinel lines next to the code; non-English values must not equal English for sentences ≥ 30 chars (test-i18n-english-fallback.R); placeholders are positional (`%1$s`, `%2$d`) and every language must keep them.
- Tests: `source_for_test()`, re-bind the real server from `.GlobalEnv`, never end a behaviour test in `expect_true(TRUE)` (P7). Run test files in batches of a few per Rscript; the full suite only in alphabetical chunks (one chunk per Rscript) or it is reaped for low memory. On this machine prefix the user library before loading anything: `Rscript -e ".libPaths(c('C:/Users/arturas.baziukas/AppData/Local/R/win-library/4.4', .libPaths())); testthat::test_dir('tests/testthat', filter='^(impact-assessment-report|impact-assessment-module)$')"`.
- Release: WS-6c ships as **1.26.0** (minor: new user-visible feature). Anything already under `## [Unreleased]` in CHANGELOG.md at release time (e.g. the navigation-handler fix from PR #109) ships in the same release.
- Branch: `feat/wp5-ws6c-narrative-report` from current `main`, in a worktree (superpowers:using-git-worktrees).

## Review Focus

1. An assessment with scenarios but no assessed cells, or a baseline-only assessment: the draft must say so (`narrative.scenario_unassessed` / `narrative.unassessed`) and the report must render "(not provided)" cells, never error. Tests in Tasks 1 and 3.
2. A translation that drops a placeholder (or the key-echo test stub): `.ia_fmt()` must fall back to appending the arguments instead of letting `sprintf` warn or error. Test in Task 1.
3. A cell linking a mechanism id or indicator code that is no longer in the KB/registry (ids changed in a KB rebuild): the appendix shows the id with an empty provenance; nothing errors. Test in Task 3.
4. An ISA whose element columns are canonical `ID`/`Name` (fresh ISA entry) vs lowercase (JSON load): scope element names resolve in both cases, via the existing `impact_element_choices()`. Test in Task 3.
5. User text with non-ASCII (Greek, "€", em dash) must survive into both files unchanged. Tests in Tasks 4 and 5.

---

## Task 0: Branch setup (not a code task)

- [ ] Create the worktree and branch from `main`:

```bash
git -C "C:/Users/arturas.baziukas/OneDrive - ku.lt/HORIZON_EUROPE/Marine-SABRES/SESToolbox" worktree add C:/Users/arturas.baziukas/wt-ws6c -b feat/wp5-ws6c-narrative-report main
```

The app lives in `MarineSABRES_SES_Shiny/` inside the worktree (git root is one level up). All paths below are relative to that app directory.

- [ ] Verify the baseline (user library first, see Global Constraints): `test-impact-assessment-module.R` and `test-impact-assessment-view.R` pass.
- [ ] `docs/` is gitignored: copy this plan into the worktree and force-add it (`git add -f docs/superpowers/plans/2026-10-13-wp5-ws6c-narrative-report.md`) as the branch's first commit, as WS-6b did.

---

### Task 1: Deterministic trade-off narrative (`impact_narrative_draft`) + narrative keys

**Files:**
- Create: `functions/impact_assessment_report.R`
- Modify: `global.R` (after the `source("functions/impact_assessment_model.R", local = FALSE)` line, ~L714)
- Modify: `translations/modules/impact_assessment.json` (add keys)
- Test: `tests/testthat/test-impact-assessment-report.R` (new)

**Interfaces:**
- Consumes: `impact_scenario_codes(ia)`, `impact_get_cell(ia, cr, cd)`, `impact_displacement_flagged(ia)`, `WP5_CRITERIA$code`, `wp5_vocab_label(vocab, code, i18n)`.
- Produces: `impact_narrative_draft(ia, i18n)` → `character(1)`, paragraphs separated by `"\n\n"`, plain text (no HTML; it is stored in `trade_offs$auto_draft` and rendered through `p()` and written into docx/xlsx). Also the two internal helpers `.ia_t(i18n)` and `.ia_fmt(fmt, ...)` and `.ia_scenario_order(ia)`, reused by Tasks 3–5.

- [ ] **Step 1: Write the failing tests**

```r
# tests/testthat/test-impact-assessment-report.R
library(testthat)
load_wp5_mechanisms_kb(file.path(PROJECT_ROOT, "data", "ses_knowledge_db_wp5_mechanisms.json"), force_reload = TRUE)
load_impact_reference(file.path(PROJECT_ROOT, "data", "wp5_impact_reference.json"), force_reload = TRUE)
source_for_test(c("functions/impact_assessment_view.R", "functions/impact_assessment_report.R"))
i18n <- make_test_i18n()   # echoes keys; wp5_vocab_label() then falls back to the code

# A real translator over the module + vocabulary files, one language at a time
real_t <- function(lang) {
  files <- file.path(PROJECT_ROOT, "translations", "modules", c("impact_assessment.json", "wp5_vocabulary.json", "wp5_mechanisms.json"))
  tr <- do.call(c, lapply(files, function(f) jsonlite::fromJSON(f, simplifyVector = FALSE)$translation))
  structure(list(t = function(key, ...) { v <- tr[[key]][[lang]]; if (is.null(v) || !nzchar(v)) key else v }, translator = NULL), class = "i18n_stub")
}
LANGS <- c("en", "es", "fr", "de", "lt", "pt", "it", "no", "el")

# Fixture: Macaronesia reference starters (S1 baseline), one copied cell, one assessed low-confidence cell,
# one no_change cell, one trade-off scenario (S2: EE up, FF down)
fixture_ia <- function() {
  ia <- impact_assessment_from_reference("macaronesia")
  ia <- impact_copy_reference_cell(ia, "EE", "S3")
  cl <- impact_get_cell(ia, "EQ", "S4")
  cl$direction <- "increase"; cl$magnitude <- "substantial"; cl$timing <- "long"
  cl$confidence <- "low"; cl$uncertainty_driver <- "implementation_dependency"
  cl$evidence <- c("literature", "stakeholder"); cl$rationale <- "Needs compensation – €0.25–1m/yr band"
  cl$indicator_roles <- list(C_01 = "primary"); cl$mechanism_ids <- "mac_01"
  ia <- impact_set_cell(ia, "EQ", "S4", cl)
  up <- new_impact_cell(); up$direction <- "increase"; up$magnitude <- "moderate"; up$confidence <- "high"
  dn <- new_impact_cell(); dn$direction <- "decrease"; dn$magnitude <- "incremental"; dn$timing <- "short"; dn$confidence <- "medium"
  nc <- new_impact_cell(); nc$direction <- "no_change"; nc$confidence <- "high"
  ia <- impact_set_cell(ia, "EE", "S2", up)
  ia <- impact_set_cell(ia, "FF", "S2", dn)
  ia <- impact_set_cell(ia, "PI", "S3", nc)
  ia <- impact_set_section(ia, "characterisation", list(focal_issue = "Migratory corridor", stakeholders = "Fishers; tour operators"))
  ia <- impact_set_section(ia, "uncertainty", list(notes = "Compliance in ABNJ — Δ unknown"))
  ia <- impact_set_section(ia, "recommendations", list(text = "Pilot S3 first (Πιλοτικό)"))
  ia <- impact_set_scope_items(ia, element_ids = c("P001", "C003"), indicator_codes = "C_01")
  impact_set_displacement(ia, "yes", "Effort may move to ABNJ waters")
}

test_that(".ia_fmt formats positional placeholders and falls back when the translation dropped them", {
  expect_identical(.ia_fmt("%1$s vs %2$s", "a", "b"), "a vs b")
  expect_identical(.ia_fmt("%2$s then %1$s", "a", "b"), "b then a")
  expect_identical(.ia_fmt("no placeholders", "a", 2L), "no placeholders a 2")
  expect_silent(.ia_fmt("one %1$s only", "a", "b"))
})

test_that(".ia_scenario_order ranks by ambition then code, unranked last", {
  ia <- new_impact_assessment("macaronesia")
  ia <- impact_add_scenario(ia, new_impact_scenario("B", "b", ambition_rank = 2L))
  ia <- impact_add_scenario(ia, new_impact_scenario("Z", "z"))                       # unranked
  ia <- impact_add_scenario(ia, new_impact_scenario("A", "a", ambition_rank = 2L))
  ia <- impact_add_scenario(ia, new_impact_scenario("C", "c", ambition_rank = 1L))
  expect_identical(.ia_scenario_order(ia), c("C", "A", "B", "Z"))
})

test_that("the draft is built only from keys and codes: every sentence type appears for the fixture", {
  txt <- impact_narrative_draft(fixture_ia(), i18n)
  K <- "modules.impact_assessment.narrative."
  # NOTE: scenario_unassessed is NOT in this list on purpose — every non-baseline fixture scenario has at
  # least one assessed cell (S2: EE/FF, S3: PI, S4: EQ), so that sentence never fires here. See the dedicated test below.
  for (k in c("intro", "scenario_lead", "increase", "decrease", "no_change",
              "trade_off", "low_confidence", "displacement", "unassessed", "closing"))
    expect_match(txt, paste0(K, k), fixed = TRUE, info = k)
  expect_false(grepl(paste0(K, "synergy"), txt, fixed = TRUE))         # no scenario with ≥2 increases and no decrease
  expect_false(grepl(paste0(K, "no_trade_offs"), txt, fixed = TRUE))
  expect_false(grepl("S1", strsplit(txt, "\n\n")[[1]][2], fixed = TRUE))  # baseline has no per-scenario paragraph
  expect_match(txt, "EE (moderate)", fixed = TRUE)                        # codes fall back when labels are missing
  expect_match(txt, "FF (incremental, short)", fixed = TRUE)
  expect_match(txt, "Effort may move to ABNJ waters", fixed = TRUE)
  expect_true(startsWith(strsplit(txt, "\n\n")[[1]][3], K))               # S3 before S4 (ambition rank order)
})

test_that("an empty assessment and a baseline-only assessment draft without error", {
  expect_match(impact_narrative_draft(new_impact_assessment("macaronesia"), i18n), "narrative.empty", fixed = TRUE)
  ia <- impact_add_scenario(new_impact_assessment(""), new_impact_scenario("BAU", "Business as usual"))
  ia <- impact_set_baseline(ia, "BAU")
  txt <- impact_narrative_draft(ia, i18n)
  expect_match(txt, "narrative.intro", fixed = TRUE)
  expect_match(txt, "narrative.closing", fixed = TRUE)
  expect_false(grepl("narrative.unassessed", txt, fixed = TRUE))
})

test_that("a scenario with no assessed cell gets the scenario_unassessed sentence and counts in the unassessed total", {
  ia <- impact_add_scenario(new_impact_assessment(""), new_impact_scenario("BAU", "Business as usual"))
  ia <- impact_add_scenario(ia, new_impact_scenario("ALT", "Alternative"))
  ia <- impact_set_baseline(ia, "BAU")
  txt <- impact_narrative_draft(ia, i18n)
  expect_match(txt, "narrative.scenario_unassessed", fixed = TRUE)
  expect_match(txt, "ALT (Alternative)", fixed = TRUE)
  expect_match(txt, paste0("narrative.unassessed ", nrow(WP5_CRITERIA), " ", nrow(WP5_CRITERIA)), fixed = TRUE)  # key-echo fallback appends args
  expect_false(grepl("narrative.scenario_lead", txt, fixed = TRUE))
})

test_that("in all 9 languages the draft has no raw key, no leftover placeholder, and real labels", {
  ia <- fixture_ia()
  for (l in LANGS) {
    txt <- impact_narrative_draft(ia, real_t(l))
    expect_false(grepl("modules.", txt, fixed = TRUE), info = l)
    expect_false(grepl("%[0-9]\\$", txt), info = l)
    expect_match(txt, "S2", fixed = TRUE, info = l)
    expect_false(grepl("\\bEE\\b", txt), info = paste(l, "criterion code leaked"))
  }
  en <- jsonlite::fromJSON(file.path(PROJECT_ROOT, "translations", "modules", "impact_assessment.json"), simplifyVector = FALSE)$translation
  txt <- impact_narrative_draft(ia, real_t("en"))
  expect_match(txt, sub("%1\\$s.*$", "", en[["modules.impact_assessment.narrative.low_confidence"]][["en"]]), fixed = TRUE)
  expect_match(txt, en[["modules.impact_assessment.narrative.closing"]][["en"]], fixed = TRUE)
})

test_that("the narrative keys exist in all 9 languages and keep their placeholders", {
  tr <- jsonlite::fromJSON(file.path(PROJECT_ROOT, "translations", "modules", "impact_assessment.json"), simplifyVector = FALSE)$translation
  ph <- list(intro = c("%1$d", "%2$s"), intro_no_baseline = "%1$d", scenario_lead = "%1$s", increase = "%1$s", decrease = "%1$s",
             no_change = "%1$s", uncertain = "%1$s", scenario_unassessed = "%1$s", trade_off = c("%1$s", "%2$s", "%3$s"),
             synergy = c("%1$s", "%2$s"), no_trade_offs = character(0), low_confidence = c("%1$s", "%2$s"), no_driver = character(0),
             displacement = "%1$s", no_note = character(0), unassessed = c("%1$d", "%2$d"), closing = character(0), empty = character(0))
  for (k in names(ph)) for (l in LANGS) {
    v <- tr[[paste0("modules.impact_assessment.narrative.", k)]][[l]]
    expect_true(!is.null(v) && nzchar(v), info = paste(k, l))
    for (p in ph[[k]]) expect_true(grepl(p, v, fixed = TRUE), info = paste(k, l, p))
  }
})
```

- [ ] **Step 2: Run them to verify they fail**

Run (from the app dir, user library first):
`Rscript -e ".libPaths(c('C:/Users/arturas.baziukas/AppData/Local/R/win-library/4.4', .libPaths())); testthat::test_dir('tests/testthat', filter='^impact-assessment-report$')"`
Expected: FAIL — `source_for_test` cannot find `functions/impact_assessment_report.R`.

- [ ] **Step 3: Create the file with the narrative builder**

```r
# functions/impact_assessment_report.R
# WP5 impact assessment, WS-6c: deterministic trade-off narrative and the
# Word/Excel report. Pure functions (no Shiny). Every sentence and heading is an
# i18n key; codes are translated at render time via wp5_vocab_label().
# The narrative is a toolbox_extension (spec P1): it is generated by the
# toolbox from the user's matrix, never WP5 text.

.ia_t <- function(i18n) if (!is.null(i18n) && is.function(i18n$t)) i18n$t else function(k, ...) k

#' sprintf only when the translation carries placeholders; a translation (or
#' the key-echo test stub) without them gets the arguments appended instead of
#' an sprintf warning/error.
.ia_fmt <- function(fmt, ...) {
  args <- list(...)
  fallback <- paste(c(fmt, unlist(lapply(args, as.character))), collapse = " ")
  if (!grepl("%", fmt, fixed = TRUE)) return(fallback)
  tryCatch(suppressWarnings(do.call(sprintf, c(list(fmt), args))), error = function(e) fallback)
}

#' Scenario codes ordered for prose and tables: by ambition_rank, then code; unranked (0) last
.ia_scenario_order <- function(ia) {
  codes <- impact_scenario_codes(ia)
  if (length(codes) == 0) return(character(0))
  rank <- vapply(codes, function(cd) as.integer(ia$scenarios[[cd]]$ambition_rank %||% 0L), integer(1))
  rank[is.na(rank) | rank <= 0L] <- .Machine$integer.max
  codes[order(rank, codes)]
}

# "S2 (Name)" or just the code when the name is empty or equals the code
.ia_scenario_ref <- function(ia, cd) {
  nm <- as.character(ia$scenarios[[cd]]$name %||% "")
  if (nzchar(nm) && !identical(nm, cd)) paste0(cd, " (", nm, ")") else cd
}

#' Deterministic trade-off narrative from the matrix (spec WS-6 change 6).
#' Plain text, paragraphs separated by a blank line. Baseline scenario gets no
#' paragraph of its own (IMPACT is the difference against it). Ordinal only:
#' the only numbers are counts of scenarios and of unassessed cells.
#' @return character(1)
impact_narrative_draft <- function(ia, i18n) {
  t <- .ia_t(i18n)
  K <- "modules.impact_assessment.narrative."
  # i18n-ref: modules.impact_assessment.narrative.intro
  # i18n-ref: modules.impact_assessment.narrative.intro_no_baseline
  # i18n-ref: modules.impact_assessment.narrative.scenario_lead
  # i18n-ref: modules.impact_assessment.narrative.increase
  # i18n-ref: modules.impact_assessment.narrative.decrease
  # i18n-ref: modules.impact_assessment.narrative.no_change
  # i18n-ref: modules.impact_assessment.narrative.uncertain
  # i18n-ref: modules.impact_assessment.narrative.scenario_unassessed
  # i18n-ref: modules.impact_assessment.narrative.trade_off
  # i18n-ref: modules.impact_assessment.narrative.synergy
  # i18n-ref: modules.impact_assessment.narrative.no_trade_offs
  # i18n-ref: modules.impact_assessment.narrative.low_confidence
  # i18n-ref: modules.impact_assessment.narrative.no_driver
  # i18n-ref: modules.impact_assessment.narrative.displacement
  # i18n-ref: modules.impact_assessment.narrative.no_note
  # i18n-ref: modules.impact_assessment.narrative.unassessed
  # i18n-ref: modules.impact_assessment.narrative.closing
  # i18n-ref: modules.impact_assessment.narrative.empty
  codes <- .ia_scenario_order(ia)
  if (length(codes) == 0) return(t(paste0(K, "empty")))
  base <- as.character(ia$baseline_code %||% "")
  others <- setdiff(codes, base)
  lbl <- function(vocab, code) wp5_vocab_label(vocab, code, i18n)

  paras <- if (nzchar(base)) .ia_fmt(t(paste0(K, "intro")), length(others), .ia_scenario_ref(ia, base))
           else .ia_fmt(t(paste0(K, "intro_no_baseline")), length(codes))
  tradeoffs <- character(0); low <- character(0); drivers <- character(0); n_unassessed <- 0L

  for (cd in others) {
    groups <- list(increase = character(0), decrease = character(0), no_change = character(0), uncertain = character(0))
    inc_cr <- character(0); dec_cr <- character(0)
    for (cr in WP5_CRITERIA$code) {
      cl <- impact_get_cell(ia, cr, cd)
      if (!nzchar(cl$direction) || !cl$direction %in% names(groups)) { n_unassessed <- n_unassessed + 1L; next }
      quals <- c(if (nzchar(cl$magnitude)) lbl("magnitude", cl$magnitude), if (nzchar(cl$timing)) lbl("timing", cl$timing))
      item <- if (length(quals)) paste0(lbl("criteria", cr), " (", paste(quals, collapse = ", "), ")") else lbl("criteria", cr)
      groups[[cl$direction]] <- c(groups[[cl$direction]], item)
      if (identical(cl$direction, "increase")) inc_cr <- c(inc_cr, lbl("criteria", cr))
      if (identical(cl$direction, "decrease")) dec_cr <- c(dec_cr, lbl("criteria", cr))
      if (identical(cl$confidence, "low")) {
        low <- c(low, paste0(lbl("criteria", cr), " / ", cd))
        if (nzchar(cl$uncertainty_driver)) drivers <- c(drivers, lbl("uncertainty_driver", cl$uncertainty_driver))
      }
    }
    clauses <- unlist(lapply(names(groups), function(g) {
      if (length(groups[[g]])) .ia_fmt(t(paste0(K, g)), paste(groups[[g]], collapse = ", "))
    }))
    paras <- c(paras, if (length(clauses)) paste0(.ia_fmt(t(paste0(K, "scenario_lead")), .ia_scenario_ref(ia, cd)), " ", paste(clauses, collapse = "; "), ".")
                      else .ia_fmt(t(paste0(K, "scenario_unassessed")), .ia_scenario_ref(ia, cd)))
    if (length(inc_cr) && length(dec_cr)) {
      tradeoffs <- c(tradeoffs, .ia_fmt(t(paste0(K, "trade_off")), .ia_scenario_ref(ia, cd), paste(inc_cr, collapse = ", "), paste(dec_cr, collapse = ", ")))
    } else if (length(inc_cr) >= 2 && !length(dec_cr)) {
      tradeoffs <- c(tradeoffs, .ia_fmt(t(paste0(K, "synergy")), .ia_scenario_ref(ia, cd), paste(inc_cr, collapse = ", ")))
    }
  }
  paras <- c(paras, if (length(tradeoffs)) tradeoffs else if (length(others)) t(paste0(K, "no_trade_offs")))
  if (length(low)) {
    paras <- c(paras, .ia_fmt(t(paste0(K, "low_confidence")), paste(unique(low), collapse = ", "),
                              if (length(drivers)) paste(unique(drivers), collapse = ", ") else t(paste0(K, "no_driver"))))
  }
  if (impact_displacement_flagged(ia)) {
    note <- as.character(ia$scope$displacement$note %||% "")
    paras <- c(paras, .ia_fmt(t(paste0(K, "displacement")), if (nzchar(note)) note else t(paste0(K, "no_note"))))
  }
  if (n_unassessed > 0L) {
    paras <- c(paras, .ia_fmt(t(paste0(K, "unassessed")), n_unassessed, length(others) * nrow(WP5_CRITERIA)))
  }
  paras <- c(paras, t(paste0(K, "closing")))
  paste(paras, collapse = "\n\n")
}
```

- [ ] **Step 4: Source it in global.R**

After the line `source("functions/impact_assessment_model.R", local = FALSE)` add:

```r
source("functions/impact_assessment_report.R", local = FALSE)
```

- [ ] **Step 5: Add the narrative keys (English below; translate into es, fr, de, lt, pt, it, no, el — natural wording, keep every `%n$` placeholder, non-English must differ from English)**

Add to `translations/modules/impact_assessment.json` under `"translation"`, key prefix `modules.impact_assessment.narrative.`:

| key | en |
|---|---|
| `intro` | `The assessment compares %1$d scenario(s) with the baseline %2$s. Impacts are differences against that baseline.` |
| `intro_no_baseline` | `The assessment covers %1$d scenario(s). No baseline has been set, so impacts are read as absolute ratings.` |
| `scenario_lead` | `Under %1$s:` |
| `increase` | `an increase in %1$s` |
| `decrease` | `a decrease in %1$s` |
| `no_change` | `no change in %1$s` |
| `uncertain` | `an uncertain effect on %1$s` |
| `scenario_unassessed` | `%1$s has no assessed criterion yet.` |
| `trade_off` | `%1$s involves a trade-off: gains in %2$s come with losses in %3$s.` |
| `synergy` | `%1$s shows synergies: %2$s improve together, with no recorded loss.` |
| `no_trade_offs` | `No trade-off between criteria is recorded in the matrix.` |
| `low_confidence` | `Confidence is low for %1$s; the main uncertainty drivers are %2$s.` |
| `no_driver` | `not stated` |
| `displacement` | `The scoping step flags possible displacement or leakage: %1$s` |
| `no_note` | `no note was given` |
| `unassessed` | `%1$d of %2$d criterion-scenario cells have no direction yet.` |
| `closing` | `This draft was generated by the toolbox from the matrix; it is not WP5 text. Review and edit it before use.` |
| `empty` | `No scenarios have been defined yet, so there is nothing to draft.` |

- [ ] **Step 6: Run the tests and the i18n audit**

Run the test command from Step 2. Expected: PASS (all 6 tests).
Run `micromamba run -n shiny python scripts/_i18n_audit.py`. Expected: `missing=0 hardcoded=0`.
Also run `testthat::test_dir('tests/testthat', filter='^(functions-sourced-in-app|i18n-enforcement|i18n-english-fallback|i18n-placeholders)$')`. Expected: 0 failures.

- [ ] **Step 7: Commit**

```bash
git add functions/impact_assessment_report.R global.R translations/modules/impact_assessment.json tests/testthat/test-impact-assessment-report.R
git commit -m "feat(wp5): deterministic trade-off narrative from the impact matrix (WS-6c task 1)"
```

---

### Task 2: Step 6 — "Draft from the matrix" button and "Use the draft" shortcut

**Files:**
- Modify: `modules/impact_assessment_module.R` (`step6_ui`, ~L393-405)
- Modify: `translations/modules/impact_assessment.json` (3 keys)
- Test: `tests/testthat/test-impact-assessment-module.R` (append)

**Interfaces:**
- Consumes: `impact_narrative_draft(ia, i18n)` (Task 1), `try_commit()`, `impact_set_section()`, `provenance_badge("toolbox_extension", i18n)`.
- Produces: inputs `draft_trade_offs`, `use_draft`; the stored `trade_offs$auto_draft`.

- [ ] **Step 1: Write the failing tests (append to test-impact-assessment-module.R)**

```r
# ---- WS-6c: step 6 draft -------------------------------------------------------
ia_with_matrix <- function() {
  ia <- impact_assessment_from_reference("macaronesia")
  up <- new_impact_cell(); up$direction <- "increase"; up$magnitude <- "moderate"; up$confidence <- "high"
  dn <- new_impact_cell(); dn$direction <- "decrease"; dn$magnitude <- "incremental"; dn$confidence <- "medium"
  ia <- impact_set_cell(ia, "EE", "S2", up)
  impact_set_cell(ia, "FF", "S2", dn)
}

test_that("step 6 drafts the narrative from the matrix, stores it, shows it with the toolbox badge, and can copy it into the text box", {
  p <- set_impact_assessment(mk_project("Macaronesia"), ia_with_matrix())
  args <- srv(p)
  testServer(impact_assessment_server, args = args, {
    session$flushReact()
    session$setInputs(goto_step_6 = 1); session$flushReact()
    html <- as.character(output$step_body$html)
    expect_match(html, "-draft_trade_offs\"", fixed = TRUE)
    expect_false(grepl("-use_draft\"", html, fixed = TRUE))              # no draft yet
    expect_identical(rv$ia$trade_offs$auto_draft, "")
    session$setInputs(to_text = "My own notes", draft_trade_offs = 1); session$flushReact()
    draft <- rv$ia$trade_offs$auto_draft
    expect_match(draft, "modules.impact_assessment.narrative.trade_off", fixed = TRUE)
    expect_identical(rv$ia$trade_offs$text, "My own notes")              # unsaved text box content is kept
    expect_identical(get_impact_assessment(args$project_data_reactive())$trade_offs$auto_draft, draft)
    html <- as.character(output$step_body$html)
    expect_match(html, "modules.impact_assessment.auto_draft_heading", fixed = TRUE)
    expect_match(html, "modules.wp5_mechanisms.provenance.toolbox_extension", fixed = TRUE)
    expect_match(html, "-use_draft\"", fixed = TRUE)
    session$setInputs(use_draft = 1); session$flushReact()                 # updateTextAreaInput is a no-op in tests;
    expect_identical(rv$ia$trade_offs$auto_draft, draft)                  # the button must not alter stored state
  })
})

test_that("drafting on an assessment without scenarios stores the 'empty' sentence and does not error", {
  args <- srv(mk_project(NULL))
  testServer(impact_assessment_server, args = args, {
    session$flushReact()
    session$setInputs(goto_step_6 = 1, draft_trade_offs = 1); session$flushReact()
    expect_match(rv$ia$trade_offs$auto_draft, "narrative.empty", fixed = TRUE)
  })
})
```

- [ ] **Step 2: Run to verify they fail**

`testthat::test_dir('tests/testthat', filter='^impact-assessment-module$')` — Expected: the two new tests FAIL (`draft_trade_offs` has no observer; `auto_draft` stays "").

- [ ] **Step 3: Replace `step6_ui` and add the two observers**

Replace the existing `step6_ui` (keep `observeEvent(input$save_uncertainty, ...)` and `observeEvent(input$save_trade_offs, ...)` as they are):

```r
    step6_ui <- function() {
      draft <- rv$ia$trade_offs$auto_draft %||% ""
      tagList(
        p(class = "text-muted", i18n$t("modules.impact_assessment.trade_offs_intro")),
        div(class = "mb-2",
          actionButton(ns("draft_trade_offs"), i18n$t("modules.impact_assessment.draft_button"), icon = icon("magic"), class = "btn-outline-primary btn-sm"),
          " ", provenance_badge("toolbox_extension", i18n),
          tags$small(class = "d-block text-muted", i18n$t("modules.impact_assessment.draft_hint"))),
        if (nzchar(draft))
          div(class = "alert alert-light border",
              strong(i18n$t("modules.impact_assessment.auto_draft_heading")), " ", provenance_badge("toolbox_extension", i18n),
              lapply(strsplit(draft, "\n\n", fixed = TRUE)[[1]], p),
              actionButton(ns("use_draft"), i18n$t("modules.impact_assessment.draft_use"), class = "btn-link btn-sm p-0")),
        text_section_ui("trade_offs", "text", "to_", "save_trade_offs", rows = 6)
      )
    }
    # The draft is regenerated on demand and stored next to the author's text. The current
    # text-box content is COMMITTED in the same write (so "Draft" also acts as "Save" for the
    # text): the step body re-renders on rv$ia change, which would otherwise wipe unsaved typing.
    observeEvent(input$draft_trade_offs, {
      vals <- list(text = input$to_text %||% rv$ia$trade_offs$text %||% "", auto_draft = impact_narrative_draft(rv$ia, i18n))
      if (isTRUE(try_commit(impact_set_section(rv$ia, "trade_offs", vals)))) {
        showNotification(i18n$t("modules.impact_assessment.draft_created"), type = "message", duration = 3)
      }
    })
    observeEvent(input$use_draft, {
      updateTextAreaInput(session, "to_text", value = rv$ia$trade_offs$auto_draft %||% "")
    })
```

- [ ] **Step 4: Add the keys (all 9 languages), prefix `modules.impact_assessment.`**

| key | en |
|---|---|
| `draft_button` | `Draft from the matrix` |
| `draft_hint` | `Generates templated sentences from the criterion × scenario matrix. It is a toolbox extension, not WP5 text.` |
| `draft_use` | `Use the draft as the starting point of my text` |
| `draft_created` | `Draft generated from the matrix` |

- [ ] **Step 5: Run the tests and the audit**

`testthat::test_dir('tests/testthat', filter='^impact-assessment-module$')` — Expected: PASS. `scripts/_i18n_audit.py` — `missing=0 hardcoded=0`.

- [ ] **Step 6: Commit**

```bash
git add modules/impact_assessment_module.R translations/modules/impact_assessment.json tests/testthat/test-impact-assessment-module.R
git commit -m "feat(wp5): step 6 'Draft from the matrix' with toolbox-extension badge (WS-6c task 2)"
```

---

### Task 3: Report data preparation (`impact_report_data`) + report keys

**Files:**
- Modify: `functions/impact_assessment_report.R` (append)
- Modify: `translations/modules/impact_assessment.json` (report keys)
- Test: `tests/testthat/test-impact-assessment-report.R` (append)

**Interfaces:**
- Consumes: `normalize_impact_assessment`, `impact_scenario_table_df(ia, i18n)`, `impact_element_choices(project)`, `list_indicators()`, `get_mechanism_by_id(id)`, `mechanism_provenance(id)`, `impact_cell_edited_since_copy(cell, da)`, `impact_direction_glyph`, `impact_reference_version()`, `.ia_scenario_order`, `.ia_t`.
- Produces: `impact_report_data(project, ia, i18n)` → a list:
  - `meta`: `project_name, da, da_label, generated, ref_version, n_scenarios, baseline` (character/integer scalars)
  - `characterisation`: `data.frame(field, label, value)`
  - `scenarios`: `data.frame(code, name, baseline, ambition, source, description)` (display strings; baseline = translated yes/no)
  - `scope_elements`: `data.frame(id, name)`
  - `scope_indicators`: `data.frame(code, name, provenance)`
  - `displacement`: `data.frame(label, value)` (3 rows: answer, note, displaced pressure)
  - `matrix_wide`: `data.frame(criterion, <one column per scenario code>)` with cell summaries
  - `cells_long`: `data.frame(criterion, scenario, direction, magnitude, timing, confidence, evidence, uncertainty_driver, rationale, subdimensions, indicators, mechanisms, reference)`; column names are codes, the renderers translate headers
  - `mechanisms`: `data.frame(id, name, provenance, provenance_label, source_ref, linked_to)`
  - `provenance`: `data.frame(kind, item, provenance, provenance_label, detail)`
  - `text`: `list(uncertainty, trade_offs_draft, trade_offs_text, recommendations)`
  - `labels`: named **list** of translated column headers for `cells_long`, `mechanisms`, `provenance`, `scenarios`, `scope_*` (so both renderers use the same words). It MUST be a list, not a character vector: the renderers do `labels[[n]] %||% n` and `matrix_wide` has scenario-code columns (`S1`…) that are not in `labels`; on a character vector `[[` throws "subscript out of bounds" before `%||%` runs.

- [ ] **Step 1: Write the failing tests (append)**

```r
# ---- impact_report_data ----------------------------------------------------------
report_project <- function(ia = fixture_ia(), canonical_cols = FALSE) {
  p <- create_empty_project("Corridor case"); p$data$metadata$project_name <- "Corridor case"; p$data$metadata$da_site <- "Macaronesia"
  el <- data.frame(id = c("P001", "C003"), name = c("Trawling pressure", "Seabird colony"), stringsAsFactors = FALSE)
  if (canonical_cols) names(el) <- c("ID", "Name")
  p$data$isa_data$pressures <- el[1, , drop = FALSE]; p$data$isa_data$marine_processes <- el[2, , drop = FALSE]
  set_impact_assessment(p, ia)
}

test_that("impact_report_data returns every block with the fixture's content", {
  r <- impact_report_data(report_project(), fixture_ia(), i18n)
  expect_identical(r$meta$project_name, "Corridor case")
  expect_identical(r$meta$da, "macaronesia"); expect_identical(r$meta$baseline, "S1"); expect_identical(r$meta$n_scenarios, 4L)
  expect_identical(r$characterisation$value[r$characterisation$field == "focal_issue"], "Migratory corridor")
  expect_identical(r$scenarios$code, c("S1", "S2", "S3", "S4"))
  expect_identical(r$scope_elements$name, c("Trawling pressure", "Seabird colony"))
  expect_identical(r$scope_indicators$code, "C_01"); expect_true(nzchar(r$scope_indicators$name))
  expect_identical(nrow(r$displacement), 3L)
  expect_match(r$displacement$value[2], "ABNJ", fixed = TRUE)
  expect_identical(names(r$matrix_wide), c("criterion", "S1", "S2", "S3", "S4"))
  expect_identical(nrow(r$matrix_wide), nrow(WP5_CRITERIA))
  expect_match(r$matrix_wide$S2[r$matrix_wide$criterion == "EE"], "\u2191", fixed = TRUE)      # glyph + magnitude code
  expect_identical(nrow(r$cells_long), nrow(WP5_CRITERIA) * 4L)
  eq_s4 <- r$cells_long[r$cells_long$criterion == "EQ" & r$cells_long$scenario == "S4", ]
  expect_identical(eq_s4$evidence, "literature, stakeholder")
  expect_match(eq_s4$indicators, "C_01 (primary)", fixed = TRUE)
  expect_match(eq_s4$mechanisms, "mac_01", fixed = TRUE)
  expect_match(eq_s4$rationale, "€0.25–1m/yr", fixed = TRUE)
  ee_s3 <- r$cells_long[r$cells_long$criterion == "EE" & r$cells_long$scenario == "S3", ]
  expect_match(ee_s3$reference, "Table 21", fixed = TRUE)
  expect_identical(r$mechanisms$id, "mac_01"); expect_identical(r$mechanisms$provenance, "wp5_source")
  expect_match(r$mechanisms$linked_to, "EQ / S4", fixed = TRUE)
  expect_true("reference_copy" %in% r$provenance$kind)                                        # copied EE/S3, unedited
  expect_false("reference_copy_edited" %in% r$provenance$kind)
  expect_false("toolbox_extension" %in% r$provenance$kind)                                     # no draft stored yet
  expect_identical(r$text$recommendations, "Pilot S3 first (Πιλοτικό)")
})

test_that("the provenance appendix records an edited copy and the toolbox draft", {
  ia <- fixture_ia()
  cl <- impact_get_cell(ia, "EE", "S3"); cl$rationale <- paste(cl$rationale, "(edited)"); ia <- impact_set_cell(ia, "EE", "S3", cl)
  ia <- impact_set_section(ia, "trade_offs", list(auto_draft = impact_narrative_draft(ia, i18n)))
  r <- impact_report_data(report_project(ia), ia, i18n)
  expect_true("reference_copy_edited" %in% r$provenance$kind)
  expect_true("toolbox_extension" %in% r$provenance$kind)
  expect_identical(r$provenance$provenance[r$provenance$kind == "reference_copy_edited"], "wp5_derived")
})

test_that("unknown mechanism ids / indicator codes and canonical ID/Name columns do not break the report data", {
  ia <- fixture_ia()
  cl <- impact_get_cell(ia, "EQ", "S4"); cl$mechanism_ids <- c("mac_01", "gone_99"); cl$indicator_roles <- list(NOPE_1 = "supporting")
  ia <- impact_set_cell(ia, "EQ", "S4", cl)
  ia <- impact_set_scope_items(ia, element_ids = c("P001", "C003", "X999"), indicator_codes = c("C_01", "NOPE_1"))
  r <- impact_report_data(report_project(ia, canonical_cols = TRUE), ia, i18n)
  expect_identical(r$scope_elements$name, c("Trawling pressure", "Seabird colony", "X999"))     # unknown id shown as id
  expect_identical(r$scope_indicators$name[r$scope_indicators$code == "NOPE_1"], "")
  gone <- r$mechanisms[r$mechanisms$id == "gone_99", ]
  expect_identical(gone$name, "gone_99"); expect_identical(gone$provenance, "")
})

test_that("an empty assessment yields empty tables and '(not provided)' text, not an error", {
  r <- impact_report_data(create_empty_project("x"), new_impact_assessment(""), i18n)
  expect_identical(nrow(r$scenarios), 0L); expect_identical(nrow(r$cells_long), 0L); expect_identical(nrow(r$provenance), 0L)
  expect_identical(names(r$matrix_wide), "criterion")
  expect_identical(r$text$recommendations, "")
  expect_identical(r$meta$da_label, "modules.impact_assessment.da.none")
})

test_that("the report keys exist in all 9 languages", {
  # The explicit contract (the Step 4 table), not a regex over the source: heading keys are built with
  # t(paste0(K, ...)) so a source scan only ever sees the sentinel comments.
  tr <- jsonlite::fromJSON(file.path(PROJECT_ROOT, "translations", "modules", "impact_assessment.json"), simplifyVector = FALSE)$translation
  REPORT_KEYS <- c("title", "subtitle", "project", "da", "generated", "ref_version", "baseline",
    paste0("section.", c("characterisation", "scenarios", "scope", "matrix", "uncertainty", "trade_offs", "recommendations")),
    "appendix_mechanisms", "appendix_provenance", "scope_elements", "scope_indicators", "displacement", "matrix_summary", "matrix_detail",
    "draft_label", "user_text_label", "empty", "none", "yes", "no", "stub", "narrative_item", "provenance_none", "provenance_intro",
    paste0("kind.", c("reference_copy", "reference_copy_edited", "mechanism", "indicator", "toolbox_extension")),
    paste0("col.", c("code", "name", "baseline", "ambition", "source", "description", "id", "provenance", "criterion", "scenario",
                     "direction", "magnitude", "timing", "confidence", "evidence", "uncertainty_driver", "rationale", "subdimensions",
                     "indicators", "mechanisms", "reference", "source_ref", "linked_to", "kind", "item", "detail", "label", "value")))
  expect_length(REPORT_KEYS, 64L)   # = the number of rows in the Step 4 table
  for (k in paste0("modules.impact_assessment.report.", REPORT_KEYS)) for (l in LANGS) expect_true(nzchar(tr[[k]][[l]] %||% ""), info = paste(k, l))
  expect_true(nzchar(jsonlite::fromJSON(file.path(PROJECT_ROOT, "translations", "modules", "wp5_mechanisms.json"), simplifyVector = FALSE)$translation[["modules.wp5_mechanisms.provenance.wp5_source"]][["el"]] %||% ""))
})
```

- [ ] **Step 2: Run to verify they fail** — Expected: `impact_report_data` not found.

- [ ] **Step 3: Append the data-preparation function**

```r
# ---- report data -----------------------------------------------------------------
.ia_yes_no <- function(x, t) if (isTRUE(x)) t("modules.impact_assessment.report.yes") else t("modules.impact_assessment.report.no")

# Cell summary as in the step-4 matrix: glyph, magnitude label, (confidence label)
.ia_cell_summary <- function(cell, i18n, t) {
  cell <- .impact_fill_cell(cell)
  s <- trimws(paste0(impact_direction_glyph(cell$direction), " ",
                     if (nzchar(cell$magnitude)) wp5_vocab_label("magnitude", cell$magnitude, i18n) else "",
                     if (nzchar(cell$confidence)) paste0(" (", wp5_vocab_label("confidence", cell$confidence, i18n), ")") else ""))
  if (nzchar(s)) s else t("modules.impact_assessment.report.empty")
}

# KB source_ref is a nested list (document, table, row); flatten to one string
.ia_source_ref <- function(x) {
  if (is.null(x)) return("")
  if (is.list(x)) return(paste(vapply(x, function(v) paste(as.character(unlist(v)), collapse = " "), character(1)), collapse = ", "))
  paste(as.character(x), collapse = ", ")
}

.ia_provenance_label <- function(p, t) {
  # i18n-ref: modules.wp5_mechanisms.provenance.wp5_source
  # i18n-ref: modules.wp5_mechanisms.provenance.wp5_prefinal
  # i18n-ref: modules.wp5_mechanisms.provenance.wp5_derived
  # i18n-ref: modules.wp5_mechanisms.provenance.toolbox_extension
  # i18n-ref: modules.wp5_mechanisms.provenance.provisional
  vapply(as.character(p), function(x) if (nzchar(x)) t(paste0("modules.wp5_mechanisms.provenance.", x)) else "", character(1), USE.NAMES = FALSE)
}

#' Everything the Word and Excel reports show, already translated. Pure; no file I/O.
#' @param project The project list (for the name and ISA element names)
#' @param ia The assessment (any load shape; normalised here)
impact_report_data <- function(project, ia, i18n) {
  t <- .ia_t(i18n)
  K <- "modules.impact_assessment.report."
  # i18n-ref: modules.impact_assessment.report.yes
  # i18n-ref: modules.impact_assessment.report.no
  # i18n-ref: modules.impact_assessment.report.empty
  # i18n-ref: modules.impact_assessment.report.narrative_item
  # i18n-ref: modules.impact_assessment.report.stub
  # i18n-ref: modules.impact_assessment.da.macaronesia
  # i18n-ref: modules.impact_assessment.da.tuscan
  # i18n-ref: modules.impact_assessment.da.arctic
  # i18n-ref: modules.impact_assessment.da.none
  # i18n-ref: modules.impact_assessment.displacement.yes
  # i18n-ref: modules.impact_assessment.displacement.no
  # i18n-ref: modules.impact_assessment.displacement.unsure
  ia <- normalize_impact_assessment(ia) %||% new_impact_assessment("")
  codes <- .ia_scenario_order(ia)
  empty_to_na <- function(x) if (nzchar(x)) x else t(paste0(K, "empty"))

  meta <- list(
    project_name = as.character(project$data$metadata$project_name %||% project$project_name %||% ""),
    da = ia$da,
    da_label = t(if (nzchar(ia$da)) paste0("modules.impact_assessment.da.", ia$da) else "modules.impact_assessment.da.none"),
    generated = format(Sys.time(), "%Y-%m-%d %H:%M"),
    ref_version = impact_reference_version(),
    n_scenarios = length(codes),
    baseline = as.character(ia$baseline_code %||% ""))

  fields <- IMPACT_TEXT_SECTIONS$characterisation
  # i18n-ref: modules.impact_assessment.field.focal_issue
  # i18n-ref: modules.impact_assessment.field.spatial_scope
  # i18n-ref: modules.impact_assessment.field.time_horizon
  # i18n-ref: modules.impact_assessment.field.stakeholders
  characterisation <- data.frame(field = fields,
    label = vapply(fields, function(f) t(paste0("modules.impact_assessment.field.", f)), character(1)),
    value = vapply(fields, function(f) as.character(ia$characterisation[[f]] %||% ""), character(1)),
    stringsAsFactors = FALSE, row.names = NULL)

  sc <- impact_scenario_table_df(ia, i18n)
  sc <- sc[match(codes, sc$code), , drop = FALSE]
  scenarios <- data.frame(code = codes, name = sc$name %||% character(0),
    baseline = vapply(sc$baseline %||% logical(0), .ia_yes_no, character(1), t = t),
    ambition = ifelse(is.na(sc$ambition_rank) | sc$ambition_rank <= 0L, "", as.character(sc$ambition_rank)),
    source = sc$source_label %||% character(0),
    description = vapply(codes, function(cd) as.character(ia$scenarios[[cd]]$description %||% ""), character(1)),
    stringsAsFactors = FALSE, row.names = NULL)

  choices <- impact_element_choices(project)                 # values = ids, names = "Name (ID) [element_type]"
  el_name <- function(id) { i <- match(id, choices); if (is.na(i)) id else sub(" \\([^)]*\\) \\[[^]]*\\]$", "", names(choices)[i]) }
  ids <- ia$scope$element_ids
  scope_elements <- data.frame(id = ids, name = vapply(ids, el_name, character(1)), stringsAsFactors = FALSE, row.names = NULL)

  reg <- tryCatch(list_indicators(), error = function(e) NULL)
  ind_row <- function(code) {
    r <- if (is.data.frame(reg)) reg[reg$code == code, , drop = FALSE] else NULL
    if (is.null(r) || nrow(r) == 0) return(data.frame(code = code, name = "", provenance = "", stub = FALSE, stringsAsFactors = FALSE))
    data.frame(code = code, name = as.character(r$name[1]), provenance = as.character(r$provenance[1]), stub = isTRUE(r$stub[1]), stringsAsFactors = FALSE)
  }
  scope_indicators <- do.call(rbind, c(list(data.frame(code = character(), name = character(), provenance = character(), stub = logical(), stringsAsFactors = FALSE)),
                                       lapply(ia$scope$indicator_codes, ind_row)))
  rownames(scope_indicators) <- NULL

  d <- ia$scope$displacement
  # i18n-ref: modules.impact_assessment.displacement_question
  # i18n-ref: modules.impact_assessment.displacement_note
  # i18n-ref: modules.impact_assessment.displaced_pressure
  displacement <- data.frame(
    label = c(t("modules.impact_assessment.displacement_question"), t("modules.impact_assessment.displacement_note"), t("modules.impact_assessment.displaced_pressure")),
    value = c(if (nzchar(d$answer)) t(paste0("modules.impact_assessment.displacement.", d$answer)) else t(paste0(K, "empty")),
              empty_to_na(d$note), if (nzchar(d$displaced_pressure_id)) el_name(d$displaced_pressure_id) else t(paste0(K, "empty"))),
    stringsAsFactors = FALSE)

  crits <- WP5_CRITERIA$code
  matrix_wide <- data.frame(criterion = crits, stringsAsFactors = FALSE)
  for (cd in codes) matrix_wide[[cd]] <- vapply(crits, function(cr) .ia_cell_summary(impact_get_cell(ia, cr, cd), i18n, t), character(1))

  lbl <- function(vocab, code) if (nzchar(code)) wp5_vocab_label(vocab, code, i18n) else ""
  mech_name <- function(id) { m <- get_mechanism_by_id(id); if (is.null(m)) id else as.character(m$name %||% id) }
  cell_rows <- list(); mech_links <- list(); prov_rows <- list()
  for (cr in crits) for (cd in codes) {
    cl <- impact_get_cell(ia, cr, cd)
    subs <- if (length(cl$subdimension_notes)) paste(paste0(vapply(names(cl$subdimension_notes), function(s) lbl("subdimension", s), character(1)), ": ", unlist(cl$subdimension_notes)), collapse = "; ") else ""
    inds <- if (length(cl$indicator_roles)) paste(paste0(names(cl$indicator_roles), " (", vapply(unlist(cl$indicator_roles), function(r) lbl("indicator_role", r), character(1)), ")"), collapse = ", ") else ""
    mechs <- if (length(cl$mechanism_ids)) paste(vapply(cl$mechanism_ids, mech_name, character(1)), collapse = ", ") else ""
    ref <- if (length(cl$reference)) paste0(cl$reference$table %||% "", " v", cl$reference$ref_version %||% "") else ""
    cell_rows[[length(cell_rows) + 1]] <- data.frame(criterion = cr, scenario = cd,
      direction = lbl("direction", cl$direction), magnitude = lbl("magnitude", cl$magnitude), timing = lbl("timing", cl$timing),
      confidence = lbl("confidence", cl$confidence),
      evidence = paste(vapply(cl$evidence, function(e) lbl("evidence", e), character(1)), collapse = ", "),
      uncertainty_driver = lbl("uncertainty_driver", cl$uncertainty_driver), rationale = cl$rationale,
      subdimensions = subs, indicators = inds, mechanisms = mechs, reference = ref, stringsAsFactors = FALSE)
    for (id in cl$mechanism_ids) mech_links[[id]] <- c(mech_links[[id]], paste(cr, "/", cd))
    if (length(cl$reference)) {
      edited <- impact_cell_edited_since_copy(cl, ia$da)
      prov_rows[[length(prov_rows) + 1]] <- data.frame(
        kind = if (edited) "reference_copy_edited" else "reference_copy", item = paste(cr, "/", cd),
        provenance = if (edited) "wp5_derived" else as.character(cl$reference$provenance %||% "wp5_source"),
        detail = ref, stringsAsFactors = FALSE)
    }
    for (code in names(cl$indicator_roles)) {
      r <- ind_row(code)
      if (isTRUE(r$stub) || (nzchar(r$provenance) && !identical(r$provenance, "wp5_source"))) {
        prov_rows[[length(prov_rows) + 1]] <- data.frame(kind = "indicator", item = code, provenance = r$provenance,
          detail = if (isTRUE(r$stub)) t(paste0(K, "stub")) else r$name, stringsAsFactors = FALSE)
      }
    }
  }
  cells_long <- do.call(rbind, c(list(data.frame(criterion = character(), scenario = character(), direction = character(), magnitude = character(),
    timing = character(), confidence = character(), evidence = character(), uncertainty_driver = character(), rationale = character(),
    subdimensions = character(), indicators = character(), mechanisms = character(), reference = character(), stringsAsFactors = FALSE)), cell_rows))
  rownames(cells_long) <- NULL

  mech_ids <- names(mech_links) %||% character(0)      # names(list()) is NULL, which would drop the id column
  mechanisms <- data.frame(id = mech_ids,
    name = vapply(mech_ids, mech_name, character(1)),
    provenance = vapply(mech_ids, function(id) { p <- mechanism_provenance(id); if (is.null(p)) "" else as.character(p$provenance %||% "") }, character(1)),
    source_ref = vapply(mech_ids, function(id) { p <- mechanism_provenance(id); if (is.null(p)) "" else .ia_source_ref(p$source_ref) }, character(1)),
    linked_to = vapply(mech_ids, function(id) paste(unique(mech_links[[id]]), collapse = ", "), character(1)),
    stringsAsFactors = FALSE, row.names = NULL)
  mechanisms$provenance_label <- .ia_provenance_label(mechanisms$provenance, t)
  for (i in seq_len(nrow(mechanisms))) if (nzchar(mechanisms$provenance[i]) && !identical(mechanisms$provenance[i], "wp5_source")) {
    prov_rows[[length(prov_rows) + 1]] <- data.frame(kind = "mechanism", item = mechanisms$id[i], provenance = mechanisms$provenance[i],
      detail = mechanisms$name[i], stringsAsFactors = FALSE)
  }
  for (i in seq_len(nrow(scope_indicators))) if (isTRUE(scope_indicators$stub[i]) || (nzchar(scope_indicators$provenance[i]) && !identical(scope_indicators$provenance[i], "wp5_source"))) {
    prov_rows[[length(prov_rows) + 1]] <- data.frame(kind = "indicator", item = scope_indicators$code[i], provenance = scope_indicators$provenance[i],
      detail = if (isTRUE(scope_indicators$stub[i])) t(paste0(K, "stub")) else scope_indicators$name[i], stringsAsFactors = FALSE)
  }
  if (nzchar(ia$trade_offs$auto_draft %||% "")) {
    prov_rows[[length(prov_rows) + 1]] <- data.frame(kind = "toolbox_extension", item = t(paste0(K, "narrative_item")),
      provenance = "toolbox_extension", detail = "", stringsAsFactors = FALSE)
  }
  provenance <- do.call(rbind, c(list(data.frame(kind = character(), item = character(), provenance = character(), detail = character(), stringsAsFactors = FALSE)), prov_rows))
  provenance <- provenance[!duplicated(provenance[, c("kind", "item")]), , drop = FALSE]
  rownames(provenance) <- NULL
  provenance$provenance_label <- .ia_provenance_label(provenance$provenance, t)
  scope_indicators$stub <- NULL

  # i18n-ref: modules.impact_assessment.report.col.code
  # i18n-ref: modules.impact_assessment.report.col.name
  # i18n-ref: modules.impact_assessment.report.col.baseline
  # i18n-ref: modules.impact_assessment.report.col.ambition
  # i18n-ref: modules.impact_assessment.report.col.source
  # i18n-ref: modules.impact_assessment.report.col.description
  # i18n-ref: modules.impact_assessment.report.col.id
  # i18n-ref: modules.impact_assessment.report.col.provenance
  # i18n-ref: modules.impact_assessment.report.col.criterion
  # i18n-ref: modules.impact_assessment.report.col.scenario
  # i18n-ref: modules.impact_assessment.report.col.direction
  # i18n-ref: modules.impact_assessment.report.col.magnitude
  # i18n-ref: modules.impact_assessment.report.col.timing
  # i18n-ref: modules.impact_assessment.report.col.confidence
  # i18n-ref: modules.impact_assessment.report.col.evidence
  # i18n-ref: modules.impact_assessment.report.col.uncertainty_driver
  # i18n-ref: modules.impact_assessment.report.col.rationale
  # i18n-ref: modules.impact_assessment.report.col.subdimensions
  # i18n-ref: modules.impact_assessment.report.col.indicators
  # i18n-ref: modules.impact_assessment.report.col.mechanisms
  # i18n-ref: modules.impact_assessment.report.col.reference
  # i18n-ref: modules.impact_assessment.report.col.source_ref
  # i18n-ref: modules.impact_assessment.report.col.linked_to
  # i18n-ref: modules.impact_assessment.report.col.kind
  # i18n-ref: modules.impact_assessment.report.col.item
  # i18n-ref: modules.impact_assessment.report.col.detail
  # i18n-ref: modules.impact_assessment.report.col.label
  # i18n-ref: modules.impact_assessment.report.col.value
  col_keys <- c("code", "name", "baseline", "ambition", "source", "description", "id", "provenance", "criterion", "scenario",
                "direction", "magnitude", "timing", "confidence", "evidence", "uncertainty_driver", "rationale", "subdimensions",
                "indicators", "mechanisms", "reference", "source_ref", "linked_to", "kind", "item", "detail", "label", "value")
  # A list, not a character vector: renderers look up scenario-code columns (S1…) that are absent here,
  # and `[[` on a character vector errors instead of returning NULL for `%||%`.
  labels <- as.list(stats::setNames(vapply(col_keys, function(k) t(paste0(K, "col.", k)), character(1)), col_keys))
  labels[["provenance_label"]] <- labels[["provenance"]]

  list(meta = meta, characterisation = characterisation, scenarios = scenarios, scope_elements = scope_elements,
       scope_indicators = scope_indicators, displacement = displacement, matrix_wide = matrix_wide, cells_long = cells_long,
       mechanisms = mechanisms, provenance = provenance,
       text = list(uncertainty = as.character(ia$uncertainty$notes %||% ""), trade_offs_draft = as.character(ia$trade_offs$auto_draft %||% ""),
                   trade_offs_text = as.character(ia$trade_offs$text %||% ""), recommendations = as.character(ia$recommendations$text %||% "")),
       labels = labels)
}
```

Note on `impact_element_choices()` (`functions/impact_assessment_view.R:144`): values are element ids, names are `paste0(name, " (", id, ") [", element_type, "]")`; the `sub()` in `el_name` strips the ` (ID) [type]` suffix. A mechanism's `source_ref` in the KB is a nested list (`document`, `table`, `row`), which is why `.ia_source_ref()` flattens it.

- [ ] **Step 4: Add the report keys (all 9 languages), prefix `modules.impact_assessment.report.`**

| key | en |
|---|---|
| `title` | `Impact assessment report` |
| `subtitle` | `WP5 seven-step impact assessment (D5.2 §1.4), exported from the MarineSABRES SES Toolbox` |
| `project` | `Project` |
| `da` | `Demonstration area` |
| `generated` | `Generated` |
| `ref_version` | `WP5 reference data version` |
| `baseline` | `Baseline scenario` |
| `section.characterisation` | `1. Characterisation` |
| `section.scenarios` | `2. Baseline and scenarios` |
| `section.scope` | `3. Impact scoping` |
| `section.matrix` | `4. Criterion × scenario assessment` |
| `section.uncertainty` | `5. Uncertainty` |
| `section.trade_offs` | `6. Trade-offs and synergies` |
| `section.recommendations` | `7. Recommendations` |
| `appendix_mechanisms` | `Appendix A. Linked financial mechanisms` |
| `appendix_provenance` | `Appendix B. Provenance of reference data and toolbox extensions` |
| `scope_elements` | `Elements in scope` |
| `scope_indicators` | `Indicators in scope` |
| `displacement` | `Displacement / leakage check` |
| `matrix_summary` | `Summary matrix (arrow = direction, then magnitude and confidence)` |
| `matrix_detail` | `Cell details` |
| `draft_label` | `Toolbox draft (generated from the matrix; not WP5 text)` |
| `user_text_label` | `Author's text` |
| `empty` | `(not provided)` |
| `none` | `None` |
| `yes` | `Yes` |
| `no` | `No` |
| `stub` | `Registry stub (no published definition)` |
| `narrative_item` | `Auto-drafted trade-off narrative (step 6)` |
| `provenance_none` | `No WP5 reference data was copied and no toolbox extension was used.` |
| `provenance_intro` | `Rows marked wp5_derived or toolbox_extension are not WP5 findings. Copied reference cells cite their D5.2 table and the reference data version.` |
| `kind.reference_copy` | `Copied WP5 reference cell` |
| `kind.reference_copy_edited` | `Copied WP5 reference cell, edited since the copy` |
| `kind.mechanism` | `Linked mechanism` |
| `kind.indicator` | `Linked indicator` |
| `kind.toolbox_extension` | `Toolbox extension` |
| `col.code` | `Code` |
| `col.name` | `Name` |
| `col.baseline` | `Baseline` |
| `col.ambition` | `Ambition rank` |
| `col.source` | `Source` |
| `col.description` | `Description` |
| `col.id` | `ID` |
| `col.provenance` | `Provenance` |
| `col.criterion` | `Criterion` |
| `col.scenario` | `Scenario` |
| `col.direction` | `Direction` |
| `col.magnitude` | `Magnitude` |
| `col.timing` | `Timing` |
| `col.confidence` | `Confidence` |
| `col.evidence` | `Evidence` |
| `col.uncertainty_driver` | `Uncertainty driver` |
| `col.rationale` | `Rationale` |
| `col.subdimensions` | `Sub-dimension notes` |
| `col.indicators` | `Linked indicators` |
| `col.mechanisms` | `Linked mechanisms` |
| `col.reference` | `WP5 reference` |
| `col.source_ref` | `Source reference` |
| `col.linked_to` | `Linked to (criterion / scenario)` |
| `col.kind` | `Kind` |
| `col.item` | `Item` |
| `col.detail` | `Detail` |
| `col.label` | `Field` |
| `col.value` | `Value` |

`translations/modules/wp5_mechanisms.json` has `modules.wp5_mechanisms.provenance.wp5_prefinal`, `.wp5_derived`, `.toolbox_extension` and `.provisional` but NOT `.wp5_source` (the badge helper never shows it). `.ia_provenance_label()` needs it for the appendix: add `modules.wp5_mechanisms.provenance.wp5_source` to that file in all 9 languages (en: `WP5 source`).

- [ ] **Step 5: Run tests + audit** — `filter='^impact-assessment-report$'` PASS; `_i18n_audit.py` `missing=0 hardcoded=0`.

- [ ] **Step 6: Commit**

```bash
git add functions/impact_assessment_report.R translations/modules/impact_assessment.json translations/modules/wp5_mechanisms.json tests/testthat/test-impact-assessment-report.R
git commit -m "feat(wp5): impact report data preparation with provenance appendix rows (WS-6c task 3)"
```

---

### Task 4: Word report builder (`build_impact_report_docx`)

**Files:**
- Modify: `functions/impact_assessment_report.R` (append)
- Test: `tests/testthat/test-impact-assessment-report.R` (append)

**Interfaces:**
- Consumes: the `impact_report_data()` list (Task 3).
- Produces: `build_impact_report_docx(report, i18n, file, writer = function(doc, target) print(doc, target = target))` → `invisible(file)`; raises on failure (the caller's `tryCatch` notifies).

- [ ] **Step 1: Write the failing tests (append)**

```r
# ---- docx ----------------------------------------------------------------------------
docx_text <- function(path) officer::docx_summary(officer::read_docx(path))$text

test_that("build_impact_report_docx writes every section, the matrix, both appendices and non-ASCII text", {
  skip_if_not_installed("officer"); skip_if_not_installed("flextable")
  ia <- fixture_ia(); ia <- impact_set_section(ia, "trade_offs", list(text = "S4: equity vs cost", auto_draft = impact_narrative_draft(ia, i18n)))
  r <- impact_report_data(report_project(ia), ia, i18n)
  f <- tempfile(fileext = ".docx")
  build_impact_report_docx(r, i18n, f)
  expect_true(file.exists(f) && file.info(f)$size > 0)
  txt <- paste(docx_text(f), collapse = "\n")
  for (k in c("report.title", "report.section.characterisation", "report.section.scenarios", "report.section.scope", "report.section.matrix",
              "report.section.uncertainty", "report.section.trade_offs", "report.section.recommendations",
              "report.appendix_mechanisms", "report.appendix_provenance", "report.draft_label", "report.user_text_label"))
    expect_match(txt, paste0("modules.impact_assessment.", k), fixed = TRUE, info = k)
  expect_match(txt, "Corridor case", fixed = TRUE)
  expect_match(txt, "Migratory corridor", fixed = TRUE)
  expect_match(txt, "Pilot S3 first (Πιλοτικό)", fixed = TRUE)
  expect_match(txt, "€0.25–1m/yr", fixed = TRUE)
  expect_match(txt, "mac_01", fixed = TRUE)
  expect_match(txt, "narrative.closing", fixed = TRUE)                     # the draft is in the document
  expect_match(txt, "report.kind.reference_copy", fixed = TRUE)
  expect_match(txt, "report.kind.toolbox_extension", fixed = TRUE)
})

test_that("an empty assessment still produces a valid document with the 'none' appendix line", {
  skip_if_not_installed("officer"); skip_if_not_installed("flextable")
  r <- impact_report_data(create_empty_project("x"), new_impact_assessment(""), i18n)
  f <- tempfile(fileext = ".docx")
  build_impact_report_docx(r, i18n, f)
  txt <- paste(docx_text(f), collapse = "\n")
  expect_match(txt, "report.provenance_none", fixed = TRUE)
  expect_match(txt, "report.empty", fixed = TRUE)
})

test_that("a forced writer failure propagates and leaves no file", {
  r <- impact_report_data(report_project(), fixture_ia(), i18n)
  f <- tempfile(fileext = ".docx")
  expect_error(build_impact_report_docx(r, i18n, f, writer = function(doc, target) stop("disk full")), "disk full")
  expect_false(file.exists(f))
})
```

- [ ] **Step 2: Run to verify they fail** — Expected: `build_impact_report_docx` not found.

- [ ] **Step 3: Append the docx builder**

```r
# ---- Word report -----------------------------------------------------------------
# Same officer + flextable style as generate_word_report() (prepare_report_module.R:620).
.ia_docx_table <- function(doc, df, labels, t) {
  if (!is.data.frame(df) || nrow(df) == 0) return(officer::body_add_par(doc, t("modules.impact_assessment.report.empty"), style = "Normal"))
  names(df) <- vapply(names(df), function(n) labels[[n]] %||% n, character(1))
  ft <- flextable::flextable(df)
  ft <- flextable::theme_vanilla(ft)
  ft <- flextable::fontsize(ft, size = 8, part = "all")
  ft <- flextable::autofit(ft)
  # cells_long has 13 columns: without this the table runs off the right edge of a portrait page
  ft <- flextable::set_table_properties(ft, width = 1, layout = "autofit")
  flextable::body_add_flextable(doc, ft)
}
.ia_docx_text <- function(doc, text, t) {
  if (!nzchar(text)) return(officer::body_add_par(doc, t("modules.impact_assessment.report.empty"), style = "Normal"))
  for (p in strsplit(text, "\n\n", fixed = TRUE)[[1]]) doc <- officer::body_add_par(doc, p, style = "Normal")
  doc
}

#' Word report (roadmap §8.6 structure). Raises on failure; the caller's tryCatch notifies.
#' @param writer Function(doc, target); override in tests to force failures.
build_impact_report_docx <- function(report, i18n, file, writer = function(doc, target) print(doc, target = target)) {
  t <- .ia_t(i18n)
  K <- "modules.impact_assessment.report."
  # Heading / label keys built with t(paste0(K, ...)) below and in build_impact_report_xlsx():
  # i18n-ref: modules.impact_assessment.report.title
  # i18n-ref: modules.impact_assessment.report.subtitle
  # i18n-ref: modules.impact_assessment.report.project
  # i18n-ref: modules.impact_assessment.report.da
  # i18n-ref: modules.impact_assessment.report.generated
  # i18n-ref: modules.impact_assessment.report.ref_version
  # i18n-ref: modules.impact_assessment.report.baseline
  # i18n-ref: modules.impact_assessment.report.none
  # i18n-ref: modules.impact_assessment.report.section.characterisation
  # i18n-ref: modules.impact_assessment.report.section.scenarios
  # i18n-ref: modules.impact_assessment.report.section.scope
  # i18n-ref: modules.impact_assessment.report.section.matrix
  # i18n-ref: modules.impact_assessment.report.section.uncertainty
  # i18n-ref: modules.impact_assessment.report.section.trade_offs
  # i18n-ref: modules.impact_assessment.report.section.recommendations
  # i18n-ref: modules.impact_assessment.report.appendix_mechanisms
  # i18n-ref: modules.impact_assessment.report.appendix_provenance
  # i18n-ref: modules.impact_assessment.report.scope_elements
  # i18n-ref: modules.impact_assessment.report.scope_indicators
  # i18n-ref: modules.impact_assessment.report.displacement
  # i18n-ref: modules.impact_assessment.report.matrix_summary
  # i18n-ref: modules.impact_assessment.report.matrix_detail
  # i18n-ref: modules.impact_assessment.report.draft_label
  # i18n-ref: modules.impact_assessment.report.user_text_label
  # i18n-ref: modules.impact_assessment.report.provenance_none
  # i18n-ref: modules.impact_assessment.report.provenance_intro
  r <- report; L <- r$labels
  h1 <- function(doc, key) officer::body_add_par(doc, t(paste0(K, key)), style = "heading 1")
  h2 <- function(doc, key) officer::body_add_par(doc, t(paste0(K, key)), style = "heading 2")
  par <- function(doc, text) officer::body_add_par(doc, text, style = "Normal")

  doc <- officer::read_docx()
  doc <- officer::body_add_par(doc, t(paste0(K, "title")), style = "heading 1")   # same style set as generate_word_report()
  doc <- par(doc, t(paste0(K, "subtitle")))
  doc <- par(doc, paste0(t(paste0(K, "project")), ": ", r$meta$project_name))
  doc <- par(doc, paste0(t(paste0(K, "da")), ": ", r$meta$da_label))
  doc <- par(doc, paste0(t(paste0(K, "baseline")), ": ", if (nzchar(r$meta$baseline)) r$meta$baseline else t(paste0(K, "none"))))
  doc <- par(doc, paste0(t(paste0(K, "ref_version")), ": ", if (nzchar(r$meta$ref_version)) r$meta$ref_version else t(paste0(K, "none"))))
  doc <- par(doc, paste0(t(paste0(K, "generated")), ": ", r$meta$generated))

  doc <- h1(doc, "section.characterisation")
  doc <- .ia_docx_table(doc, r$characterisation[, c("label", "value")], L, t)

  doc <- h1(doc, "section.scenarios")
  doc <- .ia_docx_table(doc, r$scenarios, L, t)

  doc <- h1(doc, "section.scope")
  doc <- h2(doc, "scope_elements");   doc <- .ia_docx_table(doc, r$scope_elements, L, t)
  doc <- h2(doc, "scope_indicators"); doc <- .ia_docx_table(doc, r$scope_indicators, L, t)
  doc <- h2(doc, "displacement");     doc <- .ia_docx_table(doc, r$displacement, L, t)

  doc <- h1(doc, "section.matrix")
  doc <- h2(doc, "matrix_summary")
  mw <- r$matrix_wide; mw$criterion <- wp5_vocab_label("criteria", mw$criterion, i18n)
  doc <- .ia_docx_table(doc, mw, L, t)
  doc <- h2(doc, "matrix_detail")
  cl <- r$cells_long
  if (nrow(cl)) cl$criterion <- wp5_vocab_label("criteria", cl$criterion, i18n)
  doc <- .ia_docx_table(doc, cl, L, t)

  doc <- h1(doc, "section.uncertainty");     doc <- .ia_docx_text(doc, r$text$uncertainty, t)
  doc <- h1(doc, "section.trade_offs")
  doc <- h2(doc, "draft_label");             doc <- .ia_docx_text(doc, r$text$trade_offs_draft, t)
  doc <- h2(doc, "user_text_label");         doc <- .ia_docx_text(doc, r$text$trade_offs_text, t)
  doc <- h1(doc, "section.recommendations"); doc <- .ia_docx_text(doc, r$text$recommendations, t)

  doc <- h1(doc, "appendix_mechanisms")
  mech <- r$mechanisms
  if (nrow(mech)) mech <- mech[, c("id", "name", "provenance_label", "source_ref", "linked_to")]
  doc <- .ia_docx_table(doc, mech, L, t)

  doc <- h1(doc, "appendix_provenance")
  doc <- par(doc, t(paste0(K, "provenance_intro")))
  pv <- r$provenance
  if (nrow(pv)) {
    # i18n-ref: modules.impact_assessment.report.kind.reference_copy
    # i18n-ref: modules.impact_assessment.report.kind.reference_copy_edited
    # i18n-ref: modules.impact_assessment.report.kind.mechanism
    # i18n-ref: modules.impact_assessment.report.kind.indicator
    # i18n-ref: modules.impact_assessment.report.kind.toolbox_extension
    pv$kind <- vapply(pv$kind, function(k) t(paste0(K, "kind.", k)), character(1))
    pv <- pv[, c("kind", "item", "provenance_label", "detail")]
    doc <- .ia_docx_table(doc, pv, L, t)
  } else doc <- par(doc, t(paste0(K, "provenance_none")))

  writer(doc, file)
  invisible(file)
}
```

- [ ] **Step 4: Run the tests** — `filter='^impact-assessment-report$'` Expected: PASS. Open one generated file manually once (`file.show` is not needed; just `officer::docx_summary`) — the test does this.

- [ ] **Step 5: Commit**

```bash
git add functions/impact_assessment_report.R tests/testthat/test-impact-assessment-report.R
git commit -m "feat(wp5): Word impact report with mechanism and provenance appendices (WS-6c task 4)"
```

---

### Task 5: Excel report builder (`build_impact_report_xlsx`)

**Files:**
- Modify: `functions/impact_assessment_report.R` (append)
- Test: `tests/testthat/test-impact-assessment-report.R` (append)

**Interfaces:**
- Consumes: the `impact_report_data()` list.
- Produces: `build_impact_report_xlsx(report, i18n, file, saver = openxlsx::saveWorkbook)` → `invisible(file)`. Sheet names are fixed technical ids (≤ 31 chars, not translated): `Overview`, `Scenarios`, `Scope`, `Matrix`, `Cells`, `Mechanisms`, `Provenance`, `Text`. Column headers are translated.

- [ ] **Step 1: Write the failing tests (append)**

```r
# ---- xlsx ----------------------------------------------------------------------------
test_that("build_impact_report_xlsx writes the eight sheets with translated headers and the data", {
  ia <- fixture_ia(); ia <- impact_set_section(ia, "trade_offs", list(auto_draft = impact_narrative_draft(ia, i18n)))
  r <- impact_report_data(report_project(ia), ia, i18n)
  f <- tempfile(fileext = ".xlsx")
  build_impact_report_xlsx(r, i18n, f)
  expect_identical(openxlsx::getSheetNames(f), c("Overview", "Scenarios", "Scope", "Matrix", "Cells", "Mechanisms", "Provenance", "Text"))
  cells <- openxlsx::read.xlsx(f, sheet = "Cells")
  expect_identical(names(cells)[1:2], c("modules.impact_assessment.report.col.criterion", "modules.impact_assessment.report.col.scenario"))
  expect_identical(nrow(cells), nrow(WP5_CRITERIA) * 4L)
  expect_true(any(grepl("€0.25–1m/yr", cells[[9]], fixed = TRUE)))
  ov <- openxlsx::read.xlsx(f, sheet = "Overview", colNames = FALSE)
  expect_true("Corridor case" %in% unlist(ov))
  mx <- openxlsx::read.xlsx(f, sheet = "Matrix")
  expect_identical(names(mx)[-1], c("S1", "S2", "S3", "S4"))
  pv <- openxlsx::read.xlsx(f, sheet = "Provenance")
  expect_true("toolbox_extension" %in% unlist(pv))
  tx <- openxlsx::read.xlsx(f, sheet = "Text")
  expect_true(any(grepl("Πιλοτικό", unlist(tx), fixed = TRUE)))
  sc <- openxlsx::read.xlsx(f, sheet = "Scope", colNames = FALSE)
  expect_true("Trawling pressure" %in% unlist(sc))
})

test_that("an empty assessment still writes all sheets; a forced saver failure leaves no file", {
  r <- impact_report_data(create_empty_project("x"), new_impact_assessment(""), i18n)
  f <- tempfile(fileext = ".xlsx")
  build_impact_report_xlsx(r, i18n, f)
  expect_length(openxlsx::getSheetNames(f), 8L)
  f2 <- tempfile(fileext = ".xlsx")
  expect_error(build_impact_report_xlsx(r, i18n, f2, saver = function(...) stop("disk full")), "disk full")
  expect_false(file.exists(f2))
})
```

- [ ] **Step 2: Run to verify they fail** — Expected: `build_impact_report_xlsx` not found.

- [ ] **Step 3: Append the xlsx builder**

```r
# ---- Excel report ----------------------------------------------------------------
#' Excel report: one sheet per block, translated headers, fixed sheet ids.
#' Raises on failure; the caller's tryCatch notifies.
#' @param saver Function(wb, file, overwrite); override in tests to force failures.
build_impact_report_xlsx <- function(report, i18n, file, saver = openxlsx::saveWorkbook) {
  t <- .ia_t(i18n)
  K <- "modules.impact_assessment.report."
  r <- report; L <- r$labels
  wb <- openxlsx::createWorkbook()
  add <- function(sheet, df, translate_headers = TRUE, start = 1) {
    if (!sheet %in% openxlsx::sheets(wb)) openxlsx::addWorksheet(wb, sheet)
    if (translate_headers && ncol(df)) names(df) <- vapply(names(df), function(n) L[[n]] %||% n, character(1))
    openxlsx::writeData(wb, sheet, df, startRow = start)
    if (ncol(df)) openxlsx::setColWidths(wb, sheet, cols = seq_len(ncol(df)), widths = pmin(60, pmax(12, nchar(names(df)) + 2)))
    start + nrow(df) + 2
  }
  add("Overview", data.frame(
    item = c(t(paste0(K, "project")), t(paste0(K, "da")), t(paste0(K, "baseline")), t(paste0(K, "ref_version")), t(paste0(K, "generated"))),
    value = c(r$meta$project_name, r$meta$da_label, if (nzchar(r$meta$baseline)) r$meta$baseline else t(paste0(K, "none")),
              if (nzchar(r$meta$ref_version)) r$meta$ref_version else t(paste0(K, "none")), r$meta$generated),
    stringsAsFactors = FALSE), translate_headers = FALSE)
  add("Scenarios", r$scenarios)
  nxt <- add("Scope", r$scope_elements)
  nxt <- add("Scope", r$scope_indicators, start = nxt)
  add("Scope", r$displacement, start = nxt)
  mw <- r$matrix_wide; mw$criterion <- wp5_vocab_label("criteria", mw$criterion, i18n)
  add("Matrix", mw)
  cl <- r$cells_long; if (nrow(cl)) cl$criterion <- wp5_vocab_label("criteria", cl$criterion, i18n)
  add("Cells", cl)
  mech <- r$mechanisms; if (nrow(mech)) mech <- mech[, c("id", "name", "provenance", "source_ref", "linked_to")]
  add("Mechanisms", mech)
  pv <- r$provenance; if (nrow(pv)) pv <- pv[, c("kind", "item", "provenance", "detail")]
  add("Provenance", pv)
  add("Text", data.frame(
    section = c(t(paste0(K, "section.uncertainty")), t(paste0(K, "draft_label")), t(paste0(K, "user_text_label")), t(paste0(K, "section.recommendations"))),
    text = c(r$text$uncertainty, r$text$trade_offs_draft, r$text$trade_offs_text, r$text$recommendations),
    stringsAsFactors = FALSE), translate_headers = FALSE)
  saver(wb, file, overwrite = TRUE)
  invisible(file)
}
```

(`Scope` keeps the three tables stacked with a blank row between them; the scope test reads the sheet without headers and checks a value, so stacking is fine. `Provenance` and `Mechanisms` keep the raw provenance CODE in Excel — the data file, not the prose; the Word report shows the label.)

- [ ] **Step 4: Run the tests** — Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add functions/impact_assessment_report.R tests/testthat/test-impact-assessment-report.R
git commit -m "feat(wp5): Excel impact report (WS-6c task 5)"
```

---

### Task 6: Step 7 — download buttons and handlers

**Files:**
- Modify: `modules/impact_assessment_module.R` (`step7_ui` ~L146-149; add two `downloadHandler`s next to the step-7 observer)
- Modify: `translations/modules/impact_assessment.json` (3 keys)
- Test: `tests/testthat/test-impact-assessment-module.R` (append)

**Interfaces:**
- Consumes: `impact_report_data`, `build_impact_report_docx`, `build_impact_report_xlsx`, `generate_export_filename(prefix, ext)`, keys `common.messages.word_export_failed` and `common.messages.excel_export_failed` (both exist in `translations/common/messages.json`).
- Produces: outputs `download_docx`, `download_xlsx`.

- [ ] **Step 1: Write the failing tests (append)**

```r
# ---- WS-6c: step 7 downloads -----------------------------------------------------------
test_that("step 7 offers Word and Excel downloads that contain the assessment", {
  skip_if_not_installed("officer"); skip_if_not_installed("flextable")
  p <- set_impact_assessment(mk_project("Macaronesia"), impact_set_section(ia_with_matrix(), "recommendations", list(text = "Pilot S2 (Πιλοτικό)")))
  args <- srv(p)
  testServer(impact_assessment_server, args = args, {
    session$flushReact()
    session$setInputs(goto_step_7 = 1); session$flushReact()
    html <- as.character(output$step_body$html)
    expect_match(html, "-download_docx\"", fixed = TRUE)
    expect_match(html, "-download_xlsx\"", fixed = TRUE)
    f <- output$download_docx
    expect_true(file.exists(f) && file.info(f)$size > 0)
    txt <- paste(officer::docx_summary(officer::read_docx(f))$text, collapse = "\n")
    expect_match(txt, "Pilot S2 (Πιλοτικό)", fixed = TRUE)
    expect_match(txt, "modules.impact_assessment.report.section.matrix", fixed = TRUE)
    x <- output$download_xlsx
    expect_identical(openxlsx::getSheetNames(x)[1], "Overview")
    expect_true(any(grepl("Pilot S2", unlist(openxlsx::read.xlsx(x, sheet = "Text")), fixed = TRUE)))
  })
})

test_that("the download handlers follow the hardening pattern (tryCatch, notification, stop(e))", {
  s <- paste(readLines(file.path(PROJECT_ROOT, "modules", "impact_assessment_module.R"), warn = FALSE), collapse = "\n")
  expect_match(s, "build_impact_report_docx(", fixed = TRUE)
  expect_match(s, "build_impact_report_xlsx(", fixed = TRUE)
  expect_match(s, "common.messages.word_export_failed", fixed = TRUE)
  expect_match(s, "common.messages.excel_export_failed", fixed = TRUE)
  expect_identical(lengths(regmatches(s, gregexpr("stop(e)", s, fixed = TRUE))), 2L)
})
```

- [ ] **Step 2: Run to verify they fail** — Expected: no `download_docx` output; `stop(e)` count is 0.

- [ ] **Step 3: Replace `step7_ui` and add the handlers**

```r
    step7_ui <- function() tagList(
      p(class = "text-muted", i18n$t("modules.impact_assessment.recommendations_intro")),
      text_section_ui("recommendations", IMPACT_TEXT_SECTIONS$recommendations, "rec_", "save_recommendations", rows = 6),
      hr(),
      h5(i18n$t("modules.impact_assessment.report_heading")),
      p(class = "text-muted", i18n$t("modules.impact_assessment.report_intro")),
      downloadButton(ns("download_docx"), i18n$t("modules.impact_assessment.download_docx"), class = "btn-outline-primary"),
      downloadButton(ns("download_xlsx"), i18n$t("modules.impact_assessment.download_xlsx"), class = "btn-outline-primary ms-2")
    )
```

Right after `observeEvent(input$save_recommendations, ...)`:

```r
    # Reports are built from the stored assessment (what the user saved), never from unsaved inputs.
    report_data <- function() impact_report_data(isolate(project_data_reactive()), rv$ia, i18n)
    output$download_docx <- downloadHandler(
      filename = function() generate_export_filename("Impact_Assessment", ".docx"),
      content = function(file) {
        req(rv$ia)
        tryCatch(build_impact_report_docx(report_data(), i18n, file), error = function(e) {
          debug_log(paste("Impact report (docx) failed:", e$message), "EXPORT")
          showNotification(paste0(i18n$t("common.messages.word_export_failed"), " (", e$message, ")"), type = "error", duration = NULL)
          stop(e)
        })
      })
    output$download_xlsx <- downloadHandler(
      filename = function() generate_export_filename("Impact_Assessment", ".xlsx"),
      content = function(file) {
        req(rv$ia)
        tryCatch(build_impact_report_xlsx(report_data(), i18n, file), error = function(e) {
          debug_log(paste("Impact report (xlsx) failed:", e$message), "EXPORT")
          showNotification(paste0(i18n$t("common.messages.excel_export_failed"), " (", e$message, ")"), type = "error", duration = NULL)
          stop(e)
        })
      })
```

- [ ] **Step 4: Add the keys (all 9 languages), prefix `modules.impact_assessment.`**

| key | en |
|---|---|
| `report_heading` | `Export the assessment` |
| `report_intro` | `The Word report follows the seven D5.2 steps and ends with the linked-mechanisms and provenance appendices. The Excel file holds the same content as tables.` |
| `download_docx` | `Download Word report` |
| `download_xlsx` | `Download Excel report` |

- [ ] **Step 5: Run tests + audit**

`filter='^(impact-assessment-module|impact-assessment-report|impact-assessment-view)$'` — Expected: PASS. `_i18n_audit.py` — `missing=0 hardcoded=0`. Also `filter='^(i18n-enforcement|i18n-english-fallback|i18n-duplicate-keys|functions-sourced-in-app)$'` — 0 failures.

- [ ] **Step 6: Commit**

```bash
git add modules/impact_assessment_module.R translations/modules/impact_assessment.json tests/testthat/test-impact-assessment-module.R
git commit -m "feat(wp5): Word/Excel impact report downloads on step 7 (WS-6c task 6)"
```

---

### Task 7: Release 1.26.0

**Files:**
- Modify: `CHANGELOG.md`, `VERSION`, `DESCRIPTION` (`Version:`), `VERSION_INFO.json`
- Modify: `CLAUDE.md` only if a count it states changed (module count is unchanged: 38; no edit expected)

- [ ] **Step 1: CHANGELOG**

Turn `## [Unreleased]` into `## [1.26.0] - <today>` (keep whatever Fixed entries are already there, e.g. the navigation-handler fix), add a fresh empty `## [Unreleased]` above it, and add:

```markdown
### Added (WP5 impact assessment — spec 2026-10-11 WS-6c)
- Step 6 "Draft from the matrix": a deterministic, templated trade-off narrative built from the criterion × scenario matrix (per-scenario direction/magnitude/timing clauses, trade-offs and synergies between criteria, low-confidence cells with their uncertainty drivers, the displacement flag, unassessed-cell count). Available in all 9 languages, stored with the assessment, badged and labelled as a toolbox extension (not WP5 text). No free-generated prose.
- Step 7 "Download Word report" / "Download Excel report": the full assessment following the seven D5.2 §1.4 steps, with Appendix A (linked financial mechanisms with provenance and source references) and Appendix B (provenance: every copied WP5 reference cell with its D5.2 table and reference-data version, whether it was edited since the copy, every linked mechanism/indicator that is not plain WP5 source, and every toolbox extension used). Excel keeps the provenance codes as data; Word shows the labels.
- Not included: re-scoring under alternative assumptions (step 5 stays notes only) and one-page-per-mechanism fiches in the appendix (a summary table instead).
```

- [ ] **Step 2: Version files**

`VERSION` → `1.26.0`; `DESCRIPTION` `Version: 1.26.0`; `VERSION_INFO.json`: `version`, `version_name` ("WP5 impact assessment: narrative and report"), `release_date`, `release_type: "minor"`, and append to `features`: `"WP5 impact assessment: deterministic trade-off narrative (step 6) and Word/Excel report with mechanism and provenance appendices (step 7) (WS-6c)."`.

`WP5_IMPACT_MIN_APP_VERSION` stays `"1.25.0"` (no new stored field). Check `tests/testthat/test-impact-assessment-storage.R` and any version-guard test still pass.

- [ ] **Step 3: Full verification**

- `micromamba run -n shiny python scripts/_i18n_audit.py` → `missing=0 hardcoded=0`.
- `Rscript deployment/pre-deploy-check.R` → passes.
- Full suite in alphabetical chunks (one Rscript each, user library first): `filter='^[a-c]'`, `'^[d-h]'`, `'^i'`, `'^[j-r]'`, `'^[s-z]'`. Expected: 0 failures (the known ml-graph-features timing flake may appear once; re-run that file alone).

- [ ] **Step 4: Commit**

```bash
git add CHANGELOG.md VERSION DESCRIPTION VERSION_INFO.json
git commit -m "chore(release): 1.26.0 — WP5 impact assessment narrative and report (WS-6c)"
```

- [ ] **Step 5: Hand-off** — push the branch, open the PR against `main` (title `feat(wp5): WS-6c trade-off narrative + Word/Excel impact report (1.26.0)`), and stop. Merge, tag `v1.26.0` and deploy (`deployment/deploy-remote.ps1 -Force`, then verify HTTP 200 and `VERSION` on laguna) only on the user's instruction.

---

## Self-review notes (written after drafting)

- Spec coverage: WS-6 change 6 (narrative: Task 1-2), "Files and reports" (docx reusing officer style: Task 4; provenance appendix listing every toolbox_extension: Task 3 rows + Tasks 4/5 rendering), roadmap §8.6 section list (cover, §1–§7, mechanisms appendix: Task 4), §8.7 report tests (end-to-end `.docx` and `.xlsx`, non-empty, headings present: Tasks 4-6). Dropped on purpose and recorded in CHANGELOG: per-mechanism one-pagers.
- Type consistency: `impact_report_data()` column names used by both renderers (`cells_long` 13 columns, `mechanisms` incl. `provenance_label`, `provenance` incl. `provenance_label`, `labels` keyed by column name) are identical in Tasks 3, 4, 5. `.ia_fmt`, `.ia_t`, `.ia_scenario_order` defined once in Task 1 and reused.
- Review Focus → tests: 1 (Task 1 "empty and baseline-only", Task 3 "empty assessment"), 2 (Task 1 `.ia_fmt` test), 3 (Task 3 "unknown mechanism ids"), 4 (Task 3 `canonical_cols = TRUE`), 5 (Tasks 4 and 5 Greek/€/– assertions).
- Placeholder scan: none. The only "check and adjust" note is the `el_name` label shape in Task 3, which depends on a one-line fact in `impact_assessment_view.R:127-146` that the implementer reads.

## Review patch (2026-10-13 23:45, in-loop review against main 997d432)

Every function, constant, translation key, KB record and package API the plan names was verified to exist with the assumed shape (`mac_01` is `wp5_source`; `impact_element_choices()` labels are `Name (ID) [type]`; `cell$reference` carries `table`/`provenance`/`ref_version`; officer 0.7.4 `print(doc, target=)`, `docx_summary`; openxlsx 4.2.8.1 `sheets()`; the module currently has zero `stop(e)`). Three defects that would have failed the plan's own PASS checkpoints were fixed in place:
1. `labels` was a named character vector; `labels[["S1"]]` errors before `%||%` runs, so the Matrix table crashed both renderers. Now a list (Task 3 code + interface note).
2. Task 1's "every sentence type" test required `scenario_unassessed`, which the fixture can never emit (S2/S3/S4 each have an assessed cell). Removed from the loop; dedicated test added.
3. Task 3's key test counted literal keys in the source (`> 40`); heading keys are built dynamically, so the count tops out at 38. Replaced with the explicit 64-key contract; heading sentinels added to Task 4.
Also: `mech_ids %||% character(0)` (empty assessment dropped the `id` column); `set_table_properties(width = 1)` so the 13-column cells table fits a portrait page; Task 2 comment now states that "Draft" also commits the text box.
