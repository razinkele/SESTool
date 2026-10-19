# test-scenario-builder-module.R
# Unit tests for modules/scenario_builder_module.R

library(testthat)
library(shiny)

# Source the module under test (modules/ are not auto-loaded by global.R).
# Using sys.source(envir = .GlobalEnv) to override any outdated stub in
# helper-stubs.R (see also: test-entry-point-module.R commit 2757e05).
source_for_test(c("functions/network_analysis.R", "functions/scenario_network.R",
                  "modules/scenario_builder_module.R"))
i18n <- list(t = function(key) key)

# ============================================================================
# UI FUNCTION TESTS
# ============================================================================

test_that("scenario_builder_ui function exists", {
  skip_if_not(exists("scenario_builder_ui", mode = "function"),
              "scenario_builder_ui not available")
  expect_true(is.function(scenario_builder_ui))
})

test_that("scenario_builder_ui returns valid shiny tags", {
  skip_if_not(exists("scenario_builder_ui", mode = "function"),
              "scenario_builder_ui not available")
  params <- names(formals(scenario_builder_ui))
  ui <- if ("i18n" %in% params) scenario_builder_ui("test_sb", i18n) else scenario_builder_ui("test_sb")
  expect_true(
    inherits(ui, "shiny.tag") || inherits(ui, "shiny.tag.list"),
    info = "scenario_builder_ui must return shiny.tag or shiny.tag.list"
  )
})

# ============================================================================
# SERVER FUNCTION TESTS
# ============================================================================

test_that("scenario_builder_server function exists", {
  skip_if_not(exists("scenario_builder_server", mode = "function"),
              "scenario_builder_server not available")
  expect_true(is.function(scenario_builder_server))
})

test_that("scenario_builder_server signature includes all required params", {
  skip_if_not(exists("scenario_builder_server", mode = "function"),
              "scenario_builder_server not available")
  params <- names(formals(scenario_builder_server))
  for (p in c("id", "project_data_reactive", "i18n", "event_bus")) {
    expect_true(p %in% params, info = paste0("Missing parameter: ", p))
  }
})

test_that("scenario_builder_server event_bus defaults to NULL", {
  skip_if_not(exists("scenario_builder_server", mode = "function"),
              "scenario_builder_server not available")
  default <- formals(scenario_builder_server)$event_bus
  expect_true(is.null(default) || identical(as.character(default), "NULL"),
              info = "event_bus must default to NULL for backward compatibility")
})

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

# --- review fix C2: builder fallback when canonical slot is an empty list ----
test_that("builder shows legacy scenarios when canonical slot is an empty list (C2)", {
  proj <- create_empty_project("t")            # analysis$scenarios = list()
  proj$data$scenarios <- list(list(id = "legacy_only", name = "Legacy",
                                   modifications = list(), results = NULL))
  pd <- reactiveVal(proj)
  testServer(real_scenario_builder_server,
             args = list(project_data_reactive = pd, i18n = make_test_i18n()), {
    session$flushReact()
    expect_equal(vapply(scenarios(), `[[`, "", "id"), "legacy_only")
  })
})

test_that("predict_impacts reports re-weighted links and survives removed links", {
  cld <- list(nodes = data.frame(id = c("D_1", "A_1", "P_1"), label = c("Demand", "Boating", "Anchoring"),
                                 group = c("Drivers", "Activities", "Pressures"), stringsAsFactors = FALSE),
              edges = data.frame(id = 1:2, from = c("D_1", "A_1"), to = c("A_1", "P_1"),
                                 polarity = "+", strength = c("medium", "weak"), stringsAsFactors = FALSE))
  sc <- list(id = "s1", name = "s", description = "", created = Sys.time(), modified = Sys.time(),
             modifications = list(nodes_added = list(), nodes_removed = c(), nodes_modified = list(),
                                  links_added = list(), links_removed = c("1"),
                                  links_modified = list(list(from = "A_1", to = "P_1", polarity = "+",
                                                             strength = "strong", previous_strength = "weak"))),
             results = NULL)
  data <- list(data = list(cld = cld, analysis = list(scenarios = list(sc))))
  testServer(real_scenario_builder_server,
             args = list(project_data_reactive = shiny::reactiveVal(data), i18n = list(t = function(k, ...) k)), {
    net <- scenario_apply_modifications(cld, sc$modifications)
    imp <- predict_impacts(cld, net, sc$modifications)
    expect_equal(imp$reason[imp$node == "Anchoring"], "modules.scenario.builder.scenario_link_strength_changed")
    expect_equal(imp$impact_magnitude[imp$node == "Anchoring"], 2)    # weak -> strong = two steps
    expect_equal(imp$impact_direction[imp$node == "Demand"], "negative")  # touched by the removed link 1
  })
})

# --- feedback 2026-10-13 "Scenario Builder": creating a scenario on a project
# with connections ended the session ("attempt to set an attribute on NULL") --
test_that("activating a scenario on a CLD without edge ids does not crash", {
  cld <- list(nodes = data.frame(id = c("D_1", "A_1"), label = c("Demand", "Boating"),
                                 group = c("Drivers", "Activities"), stringsAsFactors = FALSE),
              edges = data.frame(from = "D_1", to = "A_1", polarity = "+", strength = "medium",
                                 stringsAsFactors = FALSE))     # create_edges_df() shape: no id
  sc <- list(id = "s1", name = "s", description = "", created = Sys.time(), modified = Sys.time(),
             modifications = list(nodes_added = list(), nodes_removed = c(), nodes_modified = list(),
                                  links_added = list(), links_removed = c(), links_modified = list()),
             results = NULL)
  data <- list(data = list(cld = cld, analysis = list(scenarios = list(sc))))
  testServer(real_scenario_builder_server,
             args = list(project_data_reactive = shiny::reactiveVal(data), i18n = list(t = function(k, ...) k)), {
    session$flushReact()
    active_scenario_id("s1")
    session$flushReact()
    # An observer error is not re-thrown here: Shiny closes the session, which
    # is what the user saw as being "kicked off the server".
    expect_false(session$isClosed())
  })
})
