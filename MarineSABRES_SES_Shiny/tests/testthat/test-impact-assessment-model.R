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
