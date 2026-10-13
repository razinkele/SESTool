# tests/testthat/test-level-config-toggles-wired.R
# The User Experience Level modal offers "Scenario Builder" and "Show advanced
# CLD controls (edit mode, filters)" checkboxes, but no module read
# show_scenario_builder / show_advanced_cld_controls, so ticking them did
# nothing. These tests pin each setting to a visible effect.

source_for_test(c("config/user_level_config.R",
                  "functions/ui_sidebar.R",
                  "modules/cld_visualization_module.R"))
i18n <- list(t = function(key) key)

sidebar_html <- function(level, overrides = NULL) {
  s <- shiny::MockShinySession$new()
  shiny::withReactiveDomain(s, {
    set_active_level_config(level, overrides)
    as.character(generate_sidebar_menu(level, i18n))
  })
}

# ---------------------------------------------------------------------------
# show_scenario_builder -> sidebar entry
# ---------------------------------------------------------------------------

test_that("Scenario Builder entry is shown at intermediate by default", {
  expect_true(grepl("response_scenarios", sidebar_html("intermediate"), fixed = TRUE))
})

test_that("show_scenario_builder = FALSE removes only the Scenario Builder entry", {
  html <- sidebar_html("intermediate", list(show_scenario_builder = FALSE))
  expect_false(grepl("response_scenarios", html, fixed = TRUE))
  # the rest of the Response & Validation menu stays
  expect_true(grepl("response_measures", html, fixed = TRUE))
  expect_true(grepl("response_valuation", html, fixed = TRUE))
  expect_true(grepl("response_validation", html, fixed = TRUE))
})

# ---------------------------------------------------------------------------
# show_advanced_cld_controls -> CLD edit-mode block
# ---------------------------------------------------------------------------

test_that("CLD edit-mode controls sit inside a toggleable container", {
  real_ui <- get("cld_viz_ui", envir = .GlobalEnv)
  html <- as.character(real_ui("cldt", i18n))
  container <- regexpr('id="cldt-advanced_edit_controls"', html, fixed = TRUE)
  switch_pos <- regexpr('id="cldt-enable_manipulation"', html, fixed = TRUE)
  merge_pos <- regexpr('id="cldt-merge_selected"', html, fixed = TRUE)
  expect_true(container > 0)
  expect_true(switch_pos > container)
  expect_true(merge_pos > container)
})

real_cld_server <- get("cld_viz_server", envir = .GlobalEnv)
empty_project <- shiny::reactiveVal(list(data = list(isa_data = list())))

run_cld <- function(level_rv) {
  visible <- NULL
  shiny::testServer(real_cld_server,
    args = list(project_data_reactive = empty_project, i18n = i18n,
                user_level_reactive = level_rv), {
      session$flushReact()
      visible <<- rv$edit_controls_visible
    })
  visible
}

test_that("beginner hides CLD edit controls (show_advanced_cld_controls = FALSE)", {
  expect_false(run_cld(shiny::reactiveVal("beginner")))
})

test_that("intermediate and expert show CLD edit controls", {
  expect_true(run_cld(shiny::reactiveVal("intermediate")))
  expect_true(run_cld(shiny::reactiveVal("expert")))
})

test_that("without a level reactive the CLD edit controls stay visible", {
  expect_true(run_cld(NULL))
})
