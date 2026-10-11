# test-response-module.R
# Unit tests for modules/response_module.R

library(testthat)
library(shiny)

# Source the module under test (modules/ are not auto-loaded by global.R).
# Using sys.source(envir = .GlobalEnv) to override any outdated stub in
# helper-stubs.R (see also: test-entry-point-module.R commit 2757e05).
source_for_test("modules/response_module.R")
i18n <- list(t = function(key) key)

# ============================================================================
# UI FUNCTION TESTS
# ============================================================================

test_that("response_measures_ui function exists", {
  skip_if_not(exists("response_measures_ui", mode = "function"),
              "response_measures_ui not available")
  expect_true(is.function(response_measures_ui))
})

test_that("response_measures_ui returns valid shiny tags", {
  skip_if_not(exists("response_measures_ui", mode = "function"),
              "response_measures_ui not available")
  params <- names(formals(response_measures_ui))
  ui <- if ("i18n" %in% params) response_measures_ui("test_rm", i18n) else response_measures_ui("test_rm")
  expect_true(
    inherits(ui, "shiny.tag") || inherits(ui, "shiny.tag.list"),
    info = "response_measures_ui must return shiny.tag or shiny.tag.list"
  )
})

# ============================================================================
# SERVER FUNCTION TESTS
# ============================================================================

test_that("response_measures_server function exists", {
  skip_if_not(exists("response_measures_server", mode = "function"),
              "response_measures_server not available")
  expect_true(is.function(response_measures_server))
})

test_that("response_measures_server signature includes all required params", {
  skip_if_not(exists("response_measures_server", mode = "function"),
              "response_measures_server not available")
  params <- names(formals(response_measures_server))
  for (p in c("id", "project_data_reactive", "i18n", "event_bus")) {
    expect_true(p %in% params, info = paste0("Missing parameter: ", p))
  }
})

test_that("response_measures_server event_bus defaults to NULL", {
  skip_if_not(exists("response_measures_server", mode = "function"),
              "response_measures_server not available")
  default <- formals(response_measures_server)$event_bus
  expect_true(is.null(default) || identical(as.character(default), "NULL"),
              info = "event_bus must default to NULL for backward compatibility")
})

# ---- WS-2: WP5 reference pane renders KB v2 -------------------------------------
real_response_measures_server <- get("response_measures_server", envir = .GlobalEnv)
wp5_pane_html <- function(da_site) {
  proj <- create_empty_project("t"); proj$data$metadata$da_site <- da_site
  pd <- reactiveVal(proj); html <- NULL
  testServer(real_response_measures_server,
             args = list(project_data_reactive = pd, i18n = make_test_i18n()), {
    session$flushReact()
    html <<- as.character(output$wp5_reference_pane$html)
  })
  html
}

test_that("Macaronesia pane: cost band, toolkit block with pre-final badge, references, no guidance", {
  load_wp5_mechanisms_kb(force_reload = TRUE)
  h <- wp5_pane_html("Macaronesia")
  for (k in c("attr.cost_band", "attr.toolkit_details", "provenance.wp5_prefinal",
              "attr.references", "pane.english_only_note"))
    expect_match(h, paste0("modules.wp5_mechanisms.", k), fixed = TRUE)
  expect_match(h, "Corridor coordination", fixed = TRUE)
  expect_false(grepl("use_in_impact_assessment", h, fixed = TRUE))
})

test_that("Tuscan pane: applicability + source, no toolkit block, no scenario labels", {
  load_wp5_mechanisms_kb(force_reload = TRUE)
  h <- wp5_pane_html("Tuscan Archipelago")
  expect_match(h, "modules.wp5_mechanisms.attr.applicability", fixed = TRUE)
  expect_match(h, "modules.wp5_mechanisms.attr.source", fixed = TRUE)
  expect_match(h, "Biodiversity / blue-carbon credits", fixed = TRUE)
  expect_false(grepl("modules.wp5_mechanisms.attr.toolkit_details", h, fixed = TRUE))
  expect_false(grepl("S2 Light|S3 Coordinated|Light Designation", h))
})

test_that("legacy v1 KB shows the update warning", {
  on.exit(load_wp5_mechanisms_kb(force_reload = TRUE), add = TRUE)
  v1 <- tempfile(fileext = ".json")
  writeLines(jsonlite::toJSON(list(version = "1.0.0", demonstration_areas = list(
    tuscan = list(mechanisms = list(list(id = "tus_01", name = "PES")))), valuation_unit_values = list()),
    auto_unbox = TRUE), v1)
  suppressWarnings(load_wp5_mechanisms_kb(v1, force_reload = TRUE))
  expect_match(wp5_pane_html("Tuscan Archipelago"), "modules.wp5_mechanisms.pane.legacy_kb_warning", fixed = TRUE)
})
