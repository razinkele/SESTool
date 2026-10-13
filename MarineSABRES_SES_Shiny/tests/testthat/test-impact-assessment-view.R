# tests/testthat/test-impact-assessment-view.R
library(testthat)
load_wp5_mechanisms_kb(file.path(PROJECT_ROOT, "data", "ses_knowledge_db_wp5_mechanisms.json"), force_reload = TRUE)
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
