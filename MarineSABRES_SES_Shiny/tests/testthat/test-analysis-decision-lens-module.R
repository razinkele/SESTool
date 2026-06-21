# tests/testthat/test-analysis-decision-lens-module.R
# Signature/contract test for the Decision Lens module.

test_that("analysis_decision_lens module has the conventional UI and server contract", {
  source_for_test("modules/analysis_decision_lens.R")
  i18n <- list(t = function(k, ...) k, translator = NULL)

  ui <- analysis_decision_lens_ui("dl", i18n)
  expect_true(inherits(ui, "shiny.tag") || inherits(ui, "shiny.tag.list"))
  # IDs must be namespaced under the module id
  expect_true(grepl("dl-", as.character(ui), fixed = TRUE))

  expect_true(is.function(analysis_decision_lens_server))
  fmls <- names(formals(analysis_decision_lens_server))
  expect_true(all(c("id", "project_data_reactive", "i18n") %in% fmls))
  expect_true("event_bus" %in% fmls)
})
