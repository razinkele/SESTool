# test-app-e2e.R
# End-to-End tests for the MarineSABRES SES Shiny application using shinytest2.
#
# These launch the real app in a headless browser and verify core navigation and
# rendering. They are intentionally scoped to behaviour that is reliably
# observable through AppDriver:
#
#   * User-LEVEL changes (beginner -> expert) and LANGUAGE changes both trigger a
#     full client-side page reload (server/modals.R), which orphans AppDriver's
#     WebSocket session (the old session 404s). They therefore cannot be driven
#     here. The default session is "beginner", so we navigate only among the tabs
#     the beginner sidebar actually exposes. Expert-only tabs and language
#     switching are covered at the unit level (test-language-handling.R,
#     test-i18n-enforcement.R, and the per-level menu logic in functions/ui_sidebar.R).

library(testthat)
library(shinytest2)

skip_if_not_installed("shinytest2")
skip_on_cran()

E2E_TIMEOUT <- 20000   # ms, per AppDriver operation
SETTLE      <- 1.3     # s, buffer for client-side tab switch + Shiny round-trip

# Launch the app and wait until Shiny is connected and the sidebar menu input
# binding is registered — the first set_inputs otherwise races startup
# ("Unable to find input binding for element with id sidebar_menu").
launch_app <- function(name) {
  app <- AppDriver$new(
    app_dir = "../..", name = name, height = 1000, width = 1200,
    load_timeout = 60000, timeout = E2E_TIMEOUT
  )
  for (i in seq_len(40)) {
    ready <- tryCatch(
      isTRUE(app$get_js(
        "typeof Shiny !== 'undefined' && !!Shiny.shinyapp && document.querySelector('#sidebar_menu') !== null"
      )),
      error = function(e) FALSE
    )
    if (ready) break
    Sys.sleep(0.5)
  }
  Sys.sleep(1)
  app
}

# Switch to a sidebar tab, retrying to absorb the startup/round-trip race. Returns
# TRUE once the server-side input reflects the requested tab.
nav_to <- function(app, tab) {
  for (i in seq_len(4)) {
    tryCatch(app$set_inputs(sidebar_menu = tab, wait_ = FALSE), error = function(e) NULL)
    Sys.sleep(SETTLE)
    if (identical(as.character(app$get_value(input = "sidebar_menu")), tab)) return(TRUE)
    Sys.sleep(0.8)
  }
  FALSE
}

qs_exists <- function(app, sel) {
  isTRUE(app$get_js(sprintf("document.querySelector('%s') !== null", sel)))
}
qs_count <- function(app, sel) {
  as.numeric(app$get_js(sprintf("document.querySelectorAll('%s').length", sel)))
}

# ==============================================================================
# TEST 1: App launch + dashboard
# ==============================================================================
test_that("E2E: App launches and the dashboard renders", {
  app <- launch_app("app-launch"); on.exit(app$stop(), add = TRUE)

  expect_match(app$get_html("head title"), "MarineSABRES",
               info = "Page title should identify the app")

  expect_true(nav_to(app, "dashboard"), info = "Should navigate to the dashboard")
  expect_gt(qs_count(app, ".small-box"), 0)            # value boxes rendered
  expect_true(qs_exists(app, "#total_elements_box"),
              info = "Dashboard total-elements box should be present")
})

# ==============================================================================
# TEST 2: Create-SES navigation (beginner-accessible methods)
# ==============================================================================
test_that("E2E: Create SES method pages are reachable", {
  app <- launch_app("create-ses"); on.exit(app$stop(), add = TRUE)

  expect_true(nav_to(app, "create_ses_template"),
              info = "Should reach template-based creation")
  expect_true(qs_exists(app, ".content-wrapper"))

  expect_true(nav_to(app, "create_ses_ai"),
              info = "Should reach AI-assistant creation")
  expect_true(qs_exists(app, ".content-wrapper"))
})

# ==============================================================================
# TEST 3: CLD visualization
# ==============================================================================
test_that("E2E: CLD visualization page renders", {
  app <- launch_app("cld-viz"); on.exit(app$stop(), add = TRUE)

  expect_true(nav_to(app, "cld_viz"), info = "Should reach CLD visualization")
  expect_true(qs_exists(app, ".content-wrapper"))

  # The CLD module renders several elements whose id starts with "cld_visual";
  # get_html returns a character vector, so collapse with any().
  cld <- app$get_html("[id^='cld_visual']")
  expect_true(any(nzchar(cld)), info = "CLD module content should be rendered")
})

# ==============================================================================
# TEST 4: Navigation across major sections (beginner sidebar)
# ==============================================================================
test_that("E2E: Navigation across major sections works", {
  app <- launch_app("navigation"); on.exit(app$stop(), add = TRUE)

  sections <- c("entry_point", "dashboard", "create_ses_template",
                "cld_viz", "import_data", "ses_models", "export", "guidebook")
  for (s in sections) {
    expect_true(nav_to(app, s), info = paste("Should navigate to", s))
    expect_true(qs_exists(app, ".content-wrapper"),
                info = paste(s, "content should render"))
  }

  expect_true(nav_to(app, "dashboard"), info = "Should return to the dashboard")
})
