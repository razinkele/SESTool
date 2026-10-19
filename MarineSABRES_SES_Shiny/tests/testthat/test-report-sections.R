# test-report-sections.R
# Follow-up to PR #127: HTML, PDF and Word now share generate_report_content(),
# which ignored the Prepare Report "Include sections" checkboxes (only the
# PowerPoint builder used them). The full report now honours a section list;
# without one it is unchanged.

library(testthat)
library(shiny)

source_for_test(c("functions/report_generation.R", "modules/prepare_report_module.R"))
# helper-stubs.R defines a stub generate_report_content() that shadows the
# real one sourced into .GlobalEnv (see feedback_testserver_stub_shadowing)
real_generate_report_content <- get("generate_report_content", envir = .GlobalEnv)

report_project <- function() {
  list(data = list(
    isa_data = list(
      drivers = data.frame(id = "D001", name = "Food demand", description = "", stringsAsFactors = FALSE),
      activities = data.frame(id = "A001", name = "Trawling", description = "", stringsAsFactors = FALSE)
    ),
    cld = list(
      nodes = data.frame(id = c("D_1", "A_1"), label = c("Food demand", "Trawling"),
                         group = c("Drivers", "Activities"), leverage_score = c(0.4, 0.9),
                         in_degree = c(0L, 1L), out_degree = c(1L, 0L),   # set by leverage analysis
                         stringsAsFactors = FALSE),
      edges = data.frame(from = "D_1", to = "A_1", polarity = "+", stringsAsFactors = FALSE)
    ),
    analysis = list()
  ))
}

all_headings <- c("## Executive Summary", "## Feedback Loop Analysis", "## Leverage Point Analysis",
                  "## Network Structure", "## Stakeholder Analysis", "## Management Recommendations")

test_that("without a section list the full report keeps every section it had", {
  out <- generate_full_content(report_project())
  for (h in all_headings) expect_true(grepl(h, out, fixed = TRUE), info = h)
  expect_false(grepl("## DAPSI(W)R(M) Elements", out, fixed = TRUE))
})

test_that("the full report contains only the chosen sections", {
  out <- generate_full_content(report_project(), sections = c("summary", "loops"))
  expect_true(grepl("## Executive Summary", out, fixed = TRUE))
  expect_true(grepl("## Feedback Loop Analysis", out, fixed = TRUE))
  for (h in c("## Leverage Point Analysis", "## Network Structure", "## Management Recommendations")) {
    expect_false(grepl(h, out, fixed = TRUE), info = h)
  }
  expect_true(grepl("## Stakeholder Analysis", out, fixed = TRUE))   # no checkbox: always shown
})

test_that("the isa and cld sections list the elements and the diagram", {
  out <- generate_full_content(report_project(), sections = c("isa", "cld"))
  expect_true(grepl("## DAPSI(W)R(M) Elements", out, fixed = TRUE))
  expect_true(grepl("Food demand", out, fixed = TRUE))
  expect_true(grepl("Trawling", out, fixed = TRUE))
  expect_true(grepl("## Causal Loop Diagram", out, fixed = TRUE))
  expect_false(grepl("## Executive Summary", out, fixed = TRUE))
})

test_that("generate_report_content passes options$sections to the full report", {
  out <- real_generate_report_content(report_project(), "full", options = list(sections = "leverage",
                                                                         include_regional_context = FALSE))
  expect_true(grepl("## Leverage Point Analysis", out, fixed = TRUE))
  expect_false(grepl("## Feedback Loop Analysis", out, fixed = TRUE))
})

test_that("Prepare Report sends the ticked sections to the HTML report", {
  real <- get("prepare_report_server", envir = .GlobalEnv)
  ready <- reactiveVal(list(data = list(
    analysis = list(loops = list(list(1))),
    cld = list(nodes = data.frame(leverage_score = 0.5))
  )))
  seen <- NULL
  stubs <- list(
    generate_report_content = function(data, report_type, ..., options = list()) { seen <<- options$sections; "# R" },
    render_report_safely = function(md, file, ...) writeLines("x", file),
    register_session_report = function(session, path) "u"
  )
  saved <- mget(names(stubs), envir = globalenv(), ifnotfound = list(NULL))
  for (n in names(stubs)) assign(n, stubs[[n]], envir = globalenv())
  withr::defer(for (n in names(saved)) {
    if (is.null(saved[[n]])) rm(list = n, envir = globalenv()) else assign(n, saved[[n]], envir = globalenv())
  })
  local_mocked_bindings(showModal = function(...) NULL, .package = "shiny")
  testServer(real, args = list(project_data_reactive = ready, i18n = list(t = function(k, ...) k)), {
    session$setInputs(report_sections = c("summary", "leverage"), generate_html = 1)
    expect_identical(seen, c("summary", "leverage"))
  })
})

# CodeRabbit on #130
test_that("an empty section list gives only the title and stakeholders, not the full report", {
  out <- generate_full_content(report_project(), sections = character(0))
  for (h in setdiff(all_headings, "## Stakeholder Analysis")) expect_false(grepl(h, out, fixed = TRUE), info = h)
  expect_true(grepl("## Stakeholder Analysis", out, fixed = TRUE))
})

test_that("strategic recommendations follow the Recommendations checkbox", {
  without <- generate_full_content(report_project(), sections = "leverage")
  with    <- generate_full_content(report_project(), sections = c("leverage", "recommendations"))
  expect_true(grepl("## Leverage Point Analysis", without, fixed = TRUE))
  expect_false(grepl("### Strategic Recommendations", without, fixed = TRUE))
  expect_true(grepl("### Strategic Recommendations", with, fixed = TRUE))
  expect_true(grepl("### Strategic Recommendations", generate_full_content(report_project()), fixed = TRUE))
})
