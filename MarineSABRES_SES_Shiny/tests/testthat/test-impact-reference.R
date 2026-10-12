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
