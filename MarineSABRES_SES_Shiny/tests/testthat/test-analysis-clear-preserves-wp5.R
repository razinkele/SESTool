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

test_that("reactive pipeline invalidation keeps scenarios and the impact assessment", {
  pd <- reactiveVal(project_with_analysis())
  bus <- create_event_bus(session_id = "wipe")
  testServer(
    function(input, output, session) {
      setup_reactive_pipeline(pd, bus)
    },
    {
      # Observer 1 warns "CLD regeneration failed" on this ISA-less fixture; not under test here.
      expect_warning(
        {
          bus$emit_cld_update("reactive_pipeline")
          session$flushReact()
        },
        "CLD regeneration failed"
      )
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
