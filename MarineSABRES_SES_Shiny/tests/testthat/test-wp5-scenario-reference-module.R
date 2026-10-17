# tests/testthat/test-wp5-scenario-reference-module.R
source_for_test(c("functions/wp5_scenarios.R", "modules/wp5_scenario_reference_module.R",
                  "modules/scenario_builder_module.R"))
i18n_echo <- list(t = function(k, ...) k, translator = NULL)
real_ref_server <- get("wp5_scenario_reference_server", envir = .GlobalEnv)
real_sb_ui <- get("scenario_builder_ui", envir = .GlobalEnv)   # helper-stubs.R shadows it with a 1-argument stub

proj_with <- function(register) {
  p <- create_empty_project("t")
  p$data$response_measures$measures <- register
  p
}

test_that("UI contract: renders, namespaced", {
  ui <- wp5_scenario_reference_ui("ref", i18n_echo)
  expect_true(inherits(ui, "shiny.tag") || inherits(ui, "shiny.tag.list"))
  expect_true(grepl("ref-", as.character(ui), fixed = TRUE))
  expect_true(all(c("id", "project_data_reactive", "i18n", "event_bus") %in% names(formals(wp5_scenario_reference_server))))
})

test_that("Scenario Builder UI has both tabs; the reference tab is outside the CLD gate", {
  html <- as.character(real_sb_ui("sb", i18n_echo))
  expect_match(html, "modules.wp5_scenarios.tab_my_scenarios", fixed = TRUE)
  expect_match(html, "modules.wp5_scenarios.tab_reference", fixed = TRUE)
  expect_match(html, "sb-wp5_ref-", fixed = TRUE)
})

test_that("renders with no project; default cell has area-level elements (review focus 1)", {
  testServer(real_ref_server, args = list(project_data_reactive = shiny::reactiveVal(NULL), i18n = i18n_echo), {
    expect_true(length(wp5_area_elements(load_wp5_worldview_matrix(), selected()$worldview, selected()$ssp)) > 0)
    expect_error(output$heatmap, NA)
    expect_match(as.character(output$body$html), "modules.wp5_scenarios.strategy.behavioural", fixed = TRUE)
    expect_match(as.character(output$responses$html), "modules.wp5_scenarios.responses_no_project", fixed = TRUE)
  })
})

test_that("selecting a cell fills the drill-down; an empty sector slice shows its gap note", {
  testServer(real_ref_server, args = list(project_data_reactive = shiny::reactiveVal(NULL), i18n = i18n_echo), {
    session$setInputs(cell = "hierarchy|ssp2_45")
    expect_equal(selected(), list(worldview = "hierarchy", ssp = "ssp2_45"))
    html <- as.character(output$drilldown$html)
    expect_match(html, "modules.wp5_scenarios.state.area", fixed = TRUE)
    expect_match(html, "modules.wp5_scenarios.gap.ssp_not_in_futuremares", fixed = TRUE)   # SSP2 conservation
  })
})

test_that("the responses block follows the selected cell (review focus 3)", {
  reg <- normalize_response_measures(data.frame(ID = c("R1", "R2"), Name = c("Quota rules", "Habitat plan"),
    PestleTag = c("legal", "social"), stringsAsFactors = FALSE))
  testServer(real_ref_server, args = list(project_data_reactive = shiny::reactiveVal(proj_with(reg)), i18n = i18n_echo), {
    session$setInputs(cell = "hierarchy|ssp1_26")            # area: social only
    html <- as.character(output$responses$html)
    expect_match(html, "Habitat plan", fixed = TRUE)
    expect_false(grepl("Quota rules", html, fixed = TRUE))
    session$setInputs(cell = "egalitarian|ssp3_70")          # nothing at area level
    expect_match(as.character(output$responses$html), "modules.wp5_scenarios.responses_not_area", fixed = TRUE)
  })
})

test_that("legacy register without PestleTag shows the hint (review focus 1)", {
  legacy <- data.frame(ID = "R1", Name = "Old", stringsAsFactors = FALSE)
  testServer(real_ref_server, args = list(project_data_reactive = shiny::reactiveVal(proj_with(legacy)), i18n = i18n_echo), {
    session$setInputs(cell = "individualist|ssp1_26")
    expect_match(as.character(output$responses$html), "modules.wp5_scenarios.responses_none", fixed = TRUE)
  })
})

test_that("missing reference data shows the notice (review focus 2)", {
  # The loader caches only successful loads, so stub it rather than poisoning the cache
  old <- get("load_wp5_worldview_matrix", envir = .GlobalEnv)
  assign("load_wp5_worldview_matrix", function(...) NULL, envir = .GlobalEnv)
  withr::defer(assign("load_wp5_worldview_matrix", old, envir = .GlobalEnv))
  testServer(real_ref_server, args = list(project_data_reactive = shiny::reactiveVal(NULL), i18n = i18n_echo), {
    expect_match(as.character(output$body$html), "modules.wp5_scenarios.unavailable", fixed = TRUE)
  })
})
