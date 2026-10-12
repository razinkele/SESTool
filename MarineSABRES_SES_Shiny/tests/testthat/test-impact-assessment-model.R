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
  on.exit(load_impact_reference(file.path(PROJECT_ROOT, "data", "wp5_impact_reference.json"), force_reload = TRUE), add = TRUE)
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

test_that("a user scenario that reuses a reference code cannot receive reference text (I3)", {
  ia <- impact_assessment_from_reference("macaronesia")
  ia$scenarios$S2 <- new_impact_scenario("S2", "My own S2")          # source "user"
  expect_identical(err_code(impact_copy_reference_cell(ia, "EE", "S2")), "scenario_not_reference")
  expect_identical(err_code(impact_copy_reference_cell(ia, "EE", "S3")), NA_character_)
  expect_identical(err_code(impact_copy_reference_cell(ia, "EE", "S9")), "no_reference_cell")
  gone <- impact_remove_scenario(impact_assessment_from_reference("macaronesia"), "S2")
  expect_identical(err_code(impact_copy_reference_cell(gone, "EE", "S2")), "unknown_scenario")
})

test_that("DA '' degrades like an unavailable reference; unknown DAs still error (I4)", {
  expect_identical(impact_reference_status(""), "unavailable")
  expect_identical(impact_reference_scenarios(""), list())
  expect_identical(impact_reference_baseline(""), "")
  expect_null(impact_reference_cell("", "EE", "S1"))
  expect_null(impact_reference_revenue(""))
  expect_identical(impact_assessment_from_reference(""), new_impact_assessment(""))
  mo <- impact_mechanism_options("", "S1")
  expect_identical(nrow(mo), 0L)
  expect_identical(names(mo), c("id", "name", "applicability", "applicability_text"))
  si <- impact_indicator_suggestions("EE", "")
  expect_identical(nrow(si), 0L)
  expect_identical(names(si), c("code", "name", "role", "stub"))
  expect_error(impact_reference_status("baltic"), "Unknown DA")
})

test_that("impact_update_scenario edits fields, keeps the code, and validates (I5)", {
  ia <- two_scen()
  up <- impact_update_scenario(ia, "S2", name = "Lighter", description = "Voluntary",
                               ambition_rank = 3L, dimensions = list(governance_form = "voluntary"))
  expect_identical(up$scenarios$S2$code, "S2")
  expect_identical(up$scenarios$S2$name, "Lighter")
  expect_identical(up$scenarios$S2$description, "Voluntary")
  expect_identical(up$scenarios$S2$ambition_rank, 3L)
  expect_identical(up$scenarios$S2$dimensions$governance_form, "voluntary")
  expect_identical(up$scenarios$S2$dimensions$spatial_scope, "")
  expect_identical(up$scenarios$S1, ia$scenarios$S1)
  expect_identical(impact_update_scenario(up, "S2"), up)               # NULL args change nothing
  part <- impact_update_scenario(up, "S2", name = "Renamed")
  expect_identical(part$scenarios$S2$description, "Voluntary")
  expect_identical(part$scenarios$S2$dimensions$governance_form, "voluntary")
  expect_identical(err_code(impact_update_scenario(ia, "S9", name = "x")), "unknown_scenario")
  expect_identical(err_code(impact_update_scenario(ia, "S1", dimensions = list(bogus = "x"))), "unknown_field")
  s <- new_impact_scenario("S7", "x", dimensions = list(financing_capacity = "EU funds"))
  expect_identical(s$dimensions$financing_capacity, "EU funds")
  expect_identical(err_code(new_impact_scenario("S7", "x", dimensions = list(bogus = "y"))), "unknown_field")
})

test_that("add_scenario and set_baseline reject malformed input with impact errors (M5)", {
  ia <- two_scen()
  expect_identical(err_code(impact_add_scenario(ia, "S3")), "invalid_scenario_code")
  expect_identical(err_code(impact_add_scenario(ia, list(code = "bad code"))), "invalid_scenario_code")
  expect_identical(err_code(impact_add_scenario(ia, NULL)), "invalid_scenario_code")
  expect_identical(err_code(impact_set_baseline(ia, c("S1", "S2"))), "unknown_scenario")
  expect_identical(err_code(impact_set_baseline(ia, NULL)), "unknown_scenario")
  expect_identical(err_code(impact_set_baseline(ia, NA_character_)), "unknown_scenario")
  ia <- impact_add_scenario(ia, list(code = "S3", name = "Third"))      # completed through the filler
  expect_identical(ia$scenarios$S3$dimensions, new_impact_scenario("S3", "x")$dimensions)
  expect_identical(ia$scenarios$S3$source, "user")
})

test_that("unnamed subdimension notes are dropped, not kept under positional keys (M3)", {
  ia <- two_scen()
  cl <- new_impact_cell()
  cl$subdimension_notes <- list(distributional = "a", "b")
  ia <- impact_set_cell(ia, "EQ", "S1", cl)
  expect_identical(names(ia$cells$EQ$S1$subdimension_notes), "distributional")
  expect_identical(impact_cell_problems(ia$cells$EQ$S1, "EQ"), c("direction_missing", "confidence_missing"))
  # a raw block (hand edit or older save) is cleaned by the normaliser: positional keys and
  # sub-dimensions that belong to another criterion are dropped
  raw <- ia
  raw$cells$EQ$S1$subdimension_notes <- list(distributional = "a", "b", credibility = "wrong criterion")
  out <- normalize_impact_assessment(raw)
  expect_identical(names(out$cells$EQ$S1$subdimension_notes), "distributional")
  expect_false("invalid_subdimension" %in% impact_cell_problems(out$cells$EQ$S1, "EQ"))
})
