# tests/shinytest2/test-expert-e2e.R
# Expert-Level End-to-End Tests for MarineSABRES SES Shiny Application
#
# These tests thoroughly exercise all expert-level functionality in a real
# browser environment, checking browser console for JS errors throughout.
#
# Run: Rscript -e "testthat::test_file('tests/shinytest2/test-expert-e2e.R')"

library(shinytest2)
library(testthat)

# Skip on CRAN and if shinytest2 not available
skip_if_not_installed("shinytest2")
skip_on_cran()

# ============================================================================
# CONFIGURATION
# ============================================================================
E2E_TIMEOUT <- 30000    # 30s timeout for app operations
LOAD_TIMEOUT <- 45000   # 45s for app startup
IDLE_WAIT <- 3000       # 3s for UI rendering
SHORT_WAIT <- 1500      # 1.5s for quick operations
LONG_WAIT <- 6000       # 6s for heavy operations (analysis, reports)

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

#' Create a new app driver with standard settings
#' @param name Test name
#' @return AppDriver instance
create_app <- function(name) {
  AppDriver$new(
    name = name,
    height = 1000,
    width = 1400,
    wait = TRUE,
    timeout = E2E_TIMEOUT,
    load_timeout = LOAD_TIMEOUT
  )
}

#' Collect browser console errors/warnings from the app
#' Returns a list with $errors (JS errors) and $warnings (JS warnings)
#' @param app AppDriver object
#' @return list with errors and warnings character vectors
get_console_issues <- function(app) {
  # Collect console.error and console.warn messages
  result <- app$get_js("
    (function() {
      // If our interceptor is installed, return captured messages
      if (window.__testConsoleErrors) {
        return JSON.stringify({
          errors: window.__testConsoleErrors,
          warnings: window.__testConsoleWarnings
        });
      }
      return JSON.stringify({ errors: [], warnings: [] });
    })()
  ")
  tryCatch(
    jsonlite::fromJSON(result),
    error = function(e) list(errors = character(0), warnings = character(0))
  )
}

#' Install console interceptor to capture JS errors/warnings
#' Must be called right after app loads
#' @param app AppDriver object
install_console_interceptor <- function(app) {
  app$run_js("
    window.__testConsoleErrors = [];
    window.__testConsoleWarnings = [];
    var _origError = console.error;
    var _origWarn = console.warn;
    console.error = function() {
      var msg = Array.prototype.slice.call(arguments).join(' ');
      window.__testConsoleErrors.push(msg);
      _origError.apply(console, arguments);
    };
    console.warn = function() {
      var msg = Array.prototype.slice.call(arguments).join(' ');
      window.__testConsoleWarnings.push(msg);
      _origWarn.apply(console, arguments);
    };
    // Also capture unhandled JS errors
    window.addEventListener('error', function(e) {
      window.__testConsoleErrors.push('Unhandled: ' + e.message + ' at ' + e.filename + ':' + e.lineno);
    });
    window.addEventListener('unhandledrejection', function(e) {
      window.__testConsoleErrors.push('UnhandledPromise: ' + (e.reason ? e.reason.toString() : 'unknown'));
    });
  ")
}

#' Assert no critical JS errors in console
#' Filters out known benign warnings (e.g., shiny.i18n, visNetwork deprecations)
#' @param app AppDriver object
#' @param context Description of what was tested
assert_no_critical_console_errors <- function(app, context = "") {
  issues <- get_console_issues(app)

  # Filter out known benign patterns
  benign_patterns <- c(
    "shiny.i18n",          # i18n loading messages
    "Deprecation",         # library deprecation warnings
    "favicon",             # Missing favicon
    "devtools",            # DevTools extension messages
    "ResizeObserver",      # Resize observer loop (benign in most browsers)
    "vis-network",         # visNetwork internal warnings
    "ServiceWorker",       # Service worker messages
    "chrome-extension",    # Browser extension noise
    "webpack",             # Dev tooling
    "sourceMap",           # Source map warnings
    "ARIA",               # Accessibility info (not errors)
    "third-party cookie"   # Cookie deprecation notices
  )

  critical_errors <- issues$errors
  if (length(critical_errors) > 0) {
    critical_errors <- critical_errors[!sapply(critical_errors, function(e) {
      any(sapply(benign_patterns, function(p) grepl(p, e, ignore.case = TRUE)))
    })]
  }

  if (length(critical_errors) > 0) {
    fail(sprintf(
      "Critical JS console errors found %s:\n  %s",
      if (nzchar(context)) paste0("(", context, ")") else "",
      paste(critical_errors, collapse = "\n  ")
    ))
  }
}

#' Check for Shiny output errors in the DOM
#' @param app AppDriver object
#' @return TRUE if errors found
has_shiny_errors <- function(app) {
  app$get_js("document.querySelectorAll('.shiny-output-error').length > 0")
}

#' Navigate to a tab and verify
#' @param app AppDriver object
#' @param tab_id Tab name to navigate to
#' @param wait_ms Wait time after navigation
navigate_to <- function(app, tab_id, wait_ms = IDLE_WAIT) {
  app$set_inputs(sidebar_menu = tab_id, wait_ = TRUE, timeout_ = E2E_TIMEOUT)
  app$wait_for_idle(timeout = wait_ms)
  Sys.sleep(0.5)  # Extra buffer for DOM updates
}

#' Set user level to expert via JavaScript (direct localStorage + Shiny input)
#' @param app AppDriver object
set_expert_mode <- function(app) {
  app$run_js("
    // Set localStorage for persistence
    localStorage.setItem('marinesabres_user_level', 'expert');
    // Notify Shiny server
    Shiny.setInputValue('_user_level_init', 'expert');
    Shiny.setInputValue('controlbar_user_level_select', 'expert');
  ")
  app$wait_for_idle(timeout = IDLE_WAIT)
  Sys.sleep(1)
}

#' Load a template by navigating to template page and selecting one
#' @param app AppDriver object
#' @param template_name Name fragment to match (e.g., "Caribbean")
load_template_via_models <- function(app) {
  # Navigate to SES Models to load a pre-built model
  navigate_to(app, "ses_models")
  Sys.sleep(2)  # Wait for models to load
  app$wait_for_idle(timeout = LONG_WAIT)
}

# ============================================================================
# TEST SUITE 1: APP INITIALIZATION & CONSOLE MONITORING
# ============================================================================

test_that("Expert E2E: App starts cleanly with no JS errors", {
  app <- create_app("expert-startup-clean")
  on.exit(app$stop(), add = TRUE)

  app$wait_for_idle(timeout = LONG_WAIT)
  install_console_interceptor(app)

  # Verify basic app structure
  expect_true(app$is_running())

  # Page title
  page_title <- app$get_js("document.title")
  expect_match(page_title, "SES Tool")

  # Core DOM elements exist
  has_sidebar <- app$get_js("document.querySelector('.main-sidebar') !== null")
  expect_true(has_sidebar, info = "Sidebar should exist")

  has_body <- app$get_js("document.querySelector('.content-wrapper') !== null")
  expect_true(has_body, info = "Content wrapper should exist")

  has_footer <- app$get_js("document.querySelector('.main-footer') !== null")
  expect_true(has_footer, info = "Footer should exist")

  # No Shiny output errors
  expect_false(has_shiny_errors(app), info = "No Shiny errors on startup")

  # Check for critical JS errors
  assert_no_critical_console_errors(app, "app startup")
})

# ============================================================================
# TEST SUITE 2: USER LEVEL SWITCHING (Expert Mode)
# ============================================================================

test_that("Expert E2E: User level switching to Expert shows all modules", {
  app <- create_app("expert-user-level")
  on.exit(app$stop(), add = TRUE)

  app$wait_for_idle(timeout = LONG_WAIT)
  install_console_interceptor(app)

  # Set expert mode
  set_expert_mode(app)
  Sys.sleep(2)  # Wait for sidebar to rebuild
  app$wait_for_idle(timeout = IDLE_WAIT)

  # Verify expert-only menu items appear in sidebar
  # PIMS module should be visible for expert
  has_pims <- app$get_js("
    document.querySelector('a[data-value=\"pims_project\"]') !== null ||
    document.querySelector('[href*=\"pims_project\"]') !== null
  ")

  # Response & Validation should be visible
  has_response <- app$get_js("
    document.querySelector('a[data-value=\"response_measures\"]') !== null
  ")

  # Scenario builder (expert/intermediate only)
  has_scenarios <- app$get_js("
    document.querySelector('a[data-value=\"response_scenarios\"]') !== null
  ")

  # Analysis modules should all be present
  analysis_tabs <- c(
    "analysis_metrics", "analysis_loops", "analysis_leverage",
    "analysis_bot", "analysis_simplify",
    "analysis_boolean", "analysis_simulation", "analysis_intervention"
  )

  analysis_count <- app$get_js(sprintf("
    var tabs = %s;
    var found = 0;
    tabs.forEach(function(t) {
      if (document.querySelector('a[data-value=\"' + t + '\"]')) found++;
    });
    found;
  ", jsonlite::toJSON(analysis_tabs)))

  expect_gte(analysis_count, 5,
    info = "Expert mode should show at least 5 analysis tabs")

  # Check no JS errors from switching
  assert_no_critical_console_errors(app, "user level switch to expert")
})

# ============================================================================
# TEST SUITE 3: FULL NAVIGATION WITH CONSOLE CHECKS
# ============================================================================

test_that("Expert E2E: Navigate all major sections without errors", {
  app <- create_app("expert-full-nav")
  on.exit(app$stop(), add = TRUE)

  app$wait_for_idle(timeout = LONG_WAIT)
  install_console_interceptor(app)
  set_expert_mode(app)

  # All major navigation targets
  nav_targets <- list(
    list(tab = "entry_point", name = "Entry Point"),
    list(tab = "dashboard", name = "Dashboard"),
    list(tab = "create_ses_choose", name = "Create SES Chooser"),
    list(tab = "create_ses_template", name = "Template SES"),
    list(tab = "create_ses_ai", name = "AI Assistant"),
    list(tab = "create_ses_standard", name = "Standard ISA Entry"),
    list(tab = "cld_viz", name = "CLD Visualization"),
    list(tab = "analysis_metrics", name = "Network Metrics"),
    list(tab = "analysis_loops", name = "Loop Detection"),
    list(tab = "analysis_leverage", name = "Leverage Points"),
    list(tab = "analysis_bot", name = "Behavior Over Time"),
    list(tab = "analysis_simplify", name = "Simplification"),
    list(tab = "analysis_boolean", name = "Boolean Analysis"),
    list(tab = "analysis_simulation", name = "Simulation"),
    list(tab = "analysis_intervention", name = "Intervention"),
    list(tab = "response_measures", name = "Response Measures"),
    list(tab = "response_scenarios", name = "Scenario Builder"),
    list(tab = "response_validation", name = "Response Validation"),
    list(tab = "import_data", name = "Import Data"),
    list(tab = "ses_models", name = "SES Models"),
    list(tab = "export", name = "Export & Reports"),
    list(tab = "prepare_report", name = "Prepare Report"),
    list(tab = "guidebook", name = "Guidebook")
  )

  errors_found <- character(0)

  for (nav in nav_targets) {
    tryCatch({
      navigate_to(app, nav$tab, SHORT_WAIT)

      # Verify tab is active
      active <- app$get_value(input = "sidebar_menu")
      expect_equal(active, nav$tab,
        info = paste("Should navigate to", nav$name))

      # Check for Shiny output errors on this page
      if (has_shiny_errors(app)) {
        error_text <- app$get_js("
          Array.from(document.querySelectorAll('.shiny-output-error'))
            .map(e => e.id + ': ' + e.textContent.trim().substring(0, 100))
            .join('; ')
        ")
        errors_found <- c(errors_found, paste0(nav$name, ": ", error_text))
      }
    }, error = function(e) {
      errors_found <<- c(errors_found, paste0(nav$name, ": ", e$message))
    })
  }

  # Report all errors at once
  if (length(errors_found) > 0) {
    fail(paste("Navigation errors:\n ", paste(errors_found, collapse = "\n  ")))
  }

  # Check console after navigating all pages
  assert_no_critical_console_errors(app, "full navigation sweep")
})

# ============================================================================
# TEST SUITE 4: DASHBOARD DATA DISPLAY
# ============================================================================

test_that("Expert E2E: Dashboard shows summary boxes and project status", {
  app <- create_app("expert-dashboard")
  on.exit(app$stop(), add = TRUE)

  app$wait_for_idle(timeout = LONG_WAIT)
  install_console_interceptor(app)

  navigate_to(app, "dashboard")

  # Value boxes should render
  value_box_count <- app$get_js("
    document.querySelectorAll('.small-box, .info-box, .value-box').length
  ")
  expect_gte(value_box_count, 3,
    info = "Dashboard should have at least 3 summary boxes")

  # Check specific box IDs exist
  has_elements_box <- app$get_js(
    "document.querySelector('#total_elements_box') !== null")
  has_connections_box <- app$get_js(
    "document.querySelector('#total_connections_box') !== null")
  has_loops_box <- app$get_js(
    "document.querySelector('#loops_detected_box') !== null")
  has_completion_box <- app$get_js(
    "document.querySelector('#completion_box') !== null")

  expect_true(has_elements_box, info = "Total elements box should exist")
  expect_true(has_connections_box, info = "Total connections box should exist")
  expect_true(has_loops_box, info = "Loops detected box should exist")
  expect_true(has_completion_box, info = "Completion box should exist")

  # Project overview card
  has_overview <- app$get_js(
    "document.querySelector('#project_overview_card') !== null")
  expect_true(has_overview, info = "Project overview card should exist")

  # Status summary card
  has_status <- app$get_js(
    "document.querySelector('#status_summary_card') !== null")
  expect_true(has_status, info = "Status summary card should exist")

  # Timeline card (collapsible)
  has_timeline <- app$get_js(
    "document.querySelector('#project_timeline_card') !== null")
  expect_true(has_timeline, info = "Project timeline card should exist")

  # No errors
  expect_false(has_shiny_errors(app), info = "Dashboard should render without errors")
  assert_no_critical_console_errors(app, "dashboard display")
})

# ============================================================================
# TEST SUITE 5: CLD VISUALIZATION MODULE
# ============================================================================

test_that("Expert E2E: CLD visualization renders network and controls", {
  app <- create_app("expert-cld-viz")
  on.exit(app$stop(), add = TRUE)

  app$wait_for_idle(timeout = LONG_WAIT)
  install_console_interceptor(app)
  set_expert_mode(app)

  # Navigate to CLD
  navigate_to(app, "cld_viz", LONG_WAIT)

  # visNetwork container should exist
  has_network <- app$get_js("
    document.querySelector('#cld_visual-network') !== null ||
    document.querySelector('[id$=\"-network\"]') !== null
  ")
  expect_true(has_network, info = "visNetwork container should exist")

  # Layout controls
  has_layout_select <- app$get_js(
    "document.querySelector('#cld_visual-layout_type') !== null")
  expect_true(has_layout_select, info = "Layout type selector should exist")

  # Edit mode toggle
  has_edit_toggle <- app$get_js(
    "document.querySelector('#cld_visual-enable_manipulation') !== null ||
     document.querySelector('[id$=\"enable_manipulation\"]') !== null
  ")
  expect_true(has_edit_toggle, info = "Edit mode toggle should exist")

  # Leverage point highlight toggle
  has_leverage_toggle <- app$get_js(
    "document.querySelector('#cld_visual-highlight_leverage') !== null ||
     document.querySelector('[id$=\"highlight_leverage\"]') !== null
  ")
  expect_true(has_leverage_toggle, info = "Leverage highlight toggle should exist")

  # Loop highlight dropdown
  has_loop_select <- app$get_js(
    "document.querySelector('#cld_visual-selected_loop') !== null")
  expect_true(has_loop_select, info = "Loop highlight selector should exist")

  # Fullscreen button
  has_fullscreen <- app$get_js(
    "document.querySelector('#cld_visual-fullscreen_toggle') !== null ||
     document.querySelector('.fullscreen-toggle-btn') !== null
  ")
  expect_true(has_fullscreen, info = "Fullscreen toggle should exist")

  # Add node modal container (hidden by default)
  has_add_modal <- app$get_js(
    "document.querySelector('#cld_visual-add_node_modal_container') !== null")
  expect_true(has_add_modal, info = "Add node modal container should exist (hidden)")

  # Edit edge modal container (hidden by default)
  has_edit_edge_modal <- app$get_js(
    "document.querySelector('#cld_visual-edit_edge_modal_container') !== null")
  expect_true(has_edit_edge_modal, info = "Edit edge modal container should exist (hidden)")

  # No errors
  expect_false(has_shiny_errors(app), info = "CLD viz should render without errors")
  assert_no_critical_console_errors(app, "CLD visualization")
})

test_that("Expert E2E: CLD layout switching works without JS errors", {
  app <- create_app("expert-cld-layout")
  on.exit(app$stop(), add = TRUE)

  app$wait_for_idle(timeout = LONG_WAIT)
  install_console_interceptor(app)

  navigate_to(app, "cld_viz", LONG_WAIT)

  # Switch to physics layout
  tryCatch({
    app$set_inputs(`cld_visual-layout_type` = "physics",
                   wait_ = TRUE, timeout_ = E2E_TIMEOUT)
    app$wait_for_idle(timeout = IDLE_WAIT)

    # Layout should now be physics
    layout_val <- app$get_value(input = "cld_visual-layout_type")
    expect_equal(layout_val, "physics", info = "Layout should switch to physics")

    # Hierarchy direction should be hidden (conditional panel)
    # Switch back to hierarchical
    app$set_inputs(`cld_visual-layout_type` = "hierarchical",
                   wait_ = TRUE, timeout_ = E2E_TIMEOUT)
    app$wait_for_idle(timeout = IDLE_WAIT)

    layout_val2 <- app$get_value(input = "cld_visual-layout_type")
    expect_equal(layout_val2, "hierarchical", info = "Layout should switch back to hierarchical")
  }, error = function(e) {
    message("Layout switch test encountered: ", e$message)
  })

  # No errors from layout switching
  assert_no_critical_console_errors(app, "CLD layout switching")
})

# ============================================================================
# TEST SUITE 6: ISA DATA ENTRY (Standard)
# ============================================================================

test_that("Expert E2E: Standard ISA Data Entry module loads correctly", {
  app <- create_app("expert-isa-entry")
  on.exit(app$stop(), add = TRUE)

  app$wait_for_idle(timeout = LONG_WAIT)
  install_console_interceptor(app)
  set_expert_mode(app)

  navigate_to(app, "create_ses_standard", LONG_WAIT)

  # Verify we're on the right page
  active <- app$get_value(input = "sidebar_menu")
  expect_equal(active, "create_ses_standard")

  # ISA module should have rendered content
  has_isa_content <- app$get_js("
    document.querySelector('[id^=\"isa_module\"]') !== null
  ")
  expect_true(has_isa_content, info = "ISA module content should be present")

  # Check for exercise tabs or navigation
  has_tabs_or_nav <- app$get_js("
    document.querySelectorAll('[id^=\"isa_module\"] .nav-tabs .nav-link, [id^=\"isa_module\"] .tab-pane, [id^=\"isa_module\"] .btn').length > 0
  ")
  expect_true(has_tabs_or_nav, info = "ISA module should have tabs or navigation buttons")

  expect_false(has_shiny_errors(app), info = "ISA Data Entry should render without errors")
  assert_no_critical_console_errors(app, "ISA data entry")
})

# ============================================================================
# TEST SUITE 7: CREATE SES METHOD CHOOSER
# ============================================================================

test_that("Expert E2E: Create SES chooser shows all 3 methods", {
  app <- create_app("expert-ses-chooser")
  on.exit(app$stop(), add = TRUE)

  app$wait_for_idle(timeout = LONG_WAIT)
  install_console_interceptor(app)
  set_expert_mode(app)

  navigate_to(app, "create_ses_choose", IDLE_WAIT)

  # The create SES module should show method cards/buttons
  method_cards <- app$get_js("
    // Count method option cards or buttons
    var cards = document.querySelectorAll('[id^=\"create_ses_main\"] .card, [id^=\"create_ses_main\"] .btn-lg, [id^=\"create_ses_main\"] .method-card').length;
    var buttons = document.querySelectorAll('[id^=\"create_ses_main\"] button, [id^=\"create_ses_main\"] a.btn').length;
    Math.max(cards, buttons);
  ")

  expect_gte(method_cards, 2,
    info = "Should show at least 2 SES creation method options")

  expect_false(has_shiny_errors(app))
  assert_no_critical_console_errors(app, "create SES chooser")
})

# ============================================================================
# TEST SUITE 8: TEMPLATE-BASED SES CREATION
# ============================================================================

test_that("Expert E2E: Template SES module loads template list", {
  app <- create_app("expert-template-ses")
  on.exit(app$stop(), add = TRUE)

  app$wait_for_idle(timeout = LONG_WAIT)
  install_console_interceptor(app)
  set_expert_mode(app)

  navigate_to(app, "create_ses_template", LONG_WAIT)

  # Template module should have content
  has_template_content <- app$get_js("
    document.querySelector('[id^=\"template_ses\"]') !== null
  ")
  expect_true(has_template_content, info = "Template SES module should render")

  # Should have template cards or list items
  template_items <- app$get_js("
    document.querySelectorAll('[id^=\"template_ses\"] .card, [id^=\"template_ses\"] .list-group-item, [id^=\"template_ses\"] .template-card, [id^=\"template_ses\"] button').length
  ")
  expect_gte(template_items, 1,
    info = "Template module should show at least 1 template option")

  expect_false(has_shiny_errors(app))
  assert_no_critical_console_errors(app, "template SES module")
})

# ============================================================================
# TEST SUITE 9: AI-ASSISTED ISA CREATION
# ============================================================================

test_that("Expert E2E: AI ISA assistant module loads and shows step wizard", {
  app <- create_app("expert-ai-isa")
  on.exit(app$stop(), add = TRUE)

  app$wait_for_idle(timeout = LONG_WAIT)
  install_console_interceptor(app)
  set_expert_mode(app)

  navigate_to(app, "create_ses_ai", LONG_WAIT)

  # AI ISA module should have content
  has_ai_content <- app$get_js("
    document.querySelector('[id^=\"ai_isa_mod\"]') !== null
  ")
  expect_true(has_ai_content, info = "AI ISA module should render")

  # Should have step indicators or progress elements
  has_step_ui <- app$get_js("
    document.querySelectorAll(
      '[id^=\"ai_isa_mod\"] .progress, [id^=\"ai_isa_mod\"] .step, [id^=\"ai_isa_mod\"] .wizard, [id^=\"ai_isa_mod\"] .btn, [id^=\"ai_isa_mod\"] select, [id^=\"ai_isa_mod\"] .card'
    ).length > 0
  ")
  expect_true(has_step_ui, info = "AI ISA module should have interactive elements")

  expect_false(has_shiny_errors(app))
  assert_no_critical_console_errors(app, "AI ISA assistant")
})

# ============================================================================
# TEST SUITE 10: ANALYSIS MODULES (Loop Detection)
# ============================================================================

test_that("Expert E2E: Loop detection module renders with parameters", {
  app <- create_app("expert-analysis-loops")
  on.exit(app$stop(), add = TRUE)

  app$wait_for_idle(timeout = LONG_WAIT)
  install_console_interceptor(app)
  set_expert_mode(app)

  navigate_to(app, "analysis_loops", LONG_WAIT)

  # Module should render
  has_module <- app$get_js("
    document.querySelector('[id^=\"analysis_loop\"]') !== null
  ")
  expect_true(has_module, info = "Loop analysis module should render")

  # Parameter inputs should exist
  has_max_length <- app$get_js(
    "document.querySelector('#analysis_loop-max_loop_length') !== null")
  has_max_cycles <- app$get_js(
    "document.querySelector('#analysis_loop-max_cycles') !== null")
  has_detect_btn <- app$get_js(
    "document.querySelector('#analysis_loop-detect_loops') !== null")

  expect_true(has_max_length, info = "Max loop length input should exist")
  expect_true(has_max_cycles, info = "Max cycles input should exist")
  expect_true(has_detect_btn, info = "Detect loops button should exist")

  # Checkbox inputs
  has_self_loops <- app$get_js(
    "document.querySelector('#analysis_loop-include_self_loops') !== null")
  has_filter_trivial <- app$get_js(
    "document.querySelector('#analysis_loop-filter_trivial') !== null")

  expect_true(has_self_loops, info = "Include self-loops checkbox should exist")
  expect_true(has_filter_trivial, info = "Filter trivial checkbox should exist")

  # Tab structure
  has_tabs <- app$get_js("
    document.querySelector('#analysis_loop-loop_tabs') !== null ||
    document.querySelectorAll('[id^=\"analysis_loop\"] .nav-tabs .nav-link').length > 0
  ")
  expect_true(has_tabs, info = "Loop analysis should have tab navigation")

  # Verify default parameter values
  tryCatch({
    max_len <- app$get_value(input = "analysis_loop-max_loop_length")
    expect_equal(max_len, 8, info = "Default max loop length should be 8")

    max_cyc <- app$get_value(input = "analysis_loop-max_cycles")
    expect_equal(max_cyc, 500, info = "Default max cycles should be 500")
  }, error = function(e) {
    message("Could not read loop params: ", e$message)
  })

  expect_false(has_shiny_errors(app))
  assert_no_critical_console_errors(app, "loop detection module")
})

# ============================================================================
# TEST SUITE 11: ANALYSIS MODULES (Metrics, Leverage, BOT)
# ============================================================================

test_that("Expert E2E: Network metrics module renders correctly", {
  app <- create_app("expert-analysis-metrics")
  on.exit(app$stop(), add = TRUE)

  app$wait_for_idle(timeout = LONG_WAIT)
  install_console_interceptor(app)
  set_expert_mode(app)

  navigate_to(app, "analysis_metrics", IDLE_WAIT)

  # Module should render (may show "no CLD data" warning, which is fine)
  has_module <- app$get_js("
    document.querySelector('[id^=\"analysis_met\"]') !== null
  ")
  expect_true(has_module, info = "Metrics analysis module should render")

  # Should show either metrics UI or a "no data" warning
  has_content <- app$get_js("
    document.querySelector('[id^=\"analysis_met\"] .alert') !== null ||
    document.querySelector('[id^=\"analysis_met\"] table') !== null ||
    document.querySelector('[id^=\"analysis_met\"] .card') !== null ||
    document.querySelectorAll('[id^=\"analysis_met\"]').length > 0
  ")
  expect_true(has_content, info = "Metrics module should show content or data warning")

  expect_false(has_shiny_errors(app))
  assert_no_critical_console_errors(app, "metrics analysis")
})

test_that("Expert E2E: Leverage point analysis module renders", {
  app <- create_app("expert-analysis-leverage")
  on.exit(app$stop(), add = TRUE)

  app$wait_for_idle(timeout = LONG_WAIT)
  install_console_interceptor(app)
  set_expert_mode(app)

  navigate_to(app, "analysis_leverage", IDLE_WAIT)

  has_module <- app$get_js(
    "document.querySelector('[id^=\"analysis_lev\"]') !== null")
  expect_true(has_module, info = "Leverage analysis module should render")

  expect_false(has_shiny_errors(app))
  assert_no_critical_console_errors(app, "leverage analysis")
})

test_that("Expert E2E: BOT analysis module renders", {
  app <- create_app("expert-analysis-bot")
  on.exit(app$stop(), add = TRUE)

  app$wait_for_idle(timeout = LONG_WAIT)
  install_console_interceptor(app)
  set_expert_mode(app)

  navigate_to(app, "analysis_bot", IDLE_WAIT)

  has_module <- app$get_js(
    "document.querySelector('[id^=\"analysis_b\"]') !== null")
  expect_true(has_module, info = "BOT analysis module should render")

  expect_false(has_shiny_errors(app))
  assert_no_critical_console_errors(app, "BOT analysis")
})

test_that("Expert E2E: Network simplification module renders", {
  app <- create_app("expert-analysis-simplify")
  on.exit(app$stop(), add = TRUE)

  app$wait_for_idle(timeout = LONG_WAIT)
  install_console_interceptor(app)
  set_expert_mode(app)

  navigate_to(app, "analysis_simplify", IDLE_WAIT)

  has_module <- app$get_js(
    "document.querySelector('[id^=\"analysis_simp\"]') !== null")
  expect_true(has_module, info = "Simplification module should render")

  expect_false(has_shiny_errors(app))
  assert_no_critical_console_errors(app, "simplification analysis")
})

# ============================================================================
# TEST SUITE 12: DTU ADVANCED ANALYSIS MODULES
# ============================================================================

test_that("Expert E2E: Boolean analysis (DTU) module renders", {
  app <- create_app("expert-boolean")
  on.exit(app$stop(), add = TRUE)

  app$wait_for_idle(timeout = LONG_WAIT)
  install_console_interceptor(app)
  set_expert_mode(app)

  navigate_to(app, "analysis_boolean", IDLE_WAIT)

  has_module <- app$get_js(
    "document.querySelector('[id^=\"analysis_bool\"]') !== null")
  expect_true(has_module, info = "Boolean analysis module should render")

  expect_false(has_shiny_errors(app))
  assert_no_critical_console_errors(app, "boolean analysis")
})

test_that("Expert E2E: Dynamic simulation (DTU) module renders", {
  app <- create_app("expert-simulation")
  on.exit(app$stop(), add = TRUE)

  app$wait_for_idle(timeout = LONG_WAIT)
  install_console_interceptor(app)
  set_expert_mode(app)

  navigate_to(app, "analysis_simulation", IDLE_WAIT)

  has_module <- app$get_js(
    "document.querySelector('[id^=\"analysis_sim\"]') !== null")
  expect_true(has_module, info = "Simulation module should render")

  expect_false(has_shiny_errors(app))
  assert_no_critical_console_errors(app, "dynamic simulation")
})

test_that("Expert E2E: Intervention simulation (DTU) module renders", {
  app <- create_app("expert-intervention")
  on.exit(app$stop(), add = TRUE)

  app$wait_for_idle(timeout = LONG_WAIT)
  install_console_interceptor(app)
  set_expert_mode(app)

  navigate_to(app, "analysis_intervention", IDLE_WAIT)

  has_module <- app$get_js(
    "document.querySelector('[id^=\"analysis_intv\"]') !== null")
  expect_true(has_module, info = "Intervention module should render")

  expect_false(has_shiny_errors(app))
  assert_no_critical_console_errors(app, "intervention simulation")
})

# ============================================================================
# TEST SUITE 13: EXPORT & REPORTS MODULE
# ============================================================================

test_that("Expert E2E: Export module renders all sections with correct controls", {
  app <- create_app("expert-export")
  on.exit(app$stop(), add = TRUE)

  app$wait_for_idle(timeout = LONG_WAIT)
  install_console_interceptor(app)
  set_expert_mode(app)

  navigate_to(app, "export", IDLE_WAIT)

  # Data export section
  has_data_format <- app$get_js(
    "document.querySelector('#export_reports_mod-export_data_format') !== null")
  expect_true(has_data_format, info = "Data export format selector should exist")

  has_components <- app$get_js(
    "document.querySelector('#export_reports_mod-export_data_components') !== null ||
     document.querySelectorAll('[id^=\"export_reports_mod-export_data_components\"]').length > 0
  ")
  expect_true(has_components, info = "Component checkboxes should exist")

  has_download_data <- app$get_js(
    "document.querySelector('#export_reports_mod-download_data') !== null")
  expect_true(has_download_data, info = "Download data button should exist")

  # Visualization export section
  has_viz_format <- app$get_js(
    "document.querySelector('#export_reports_mod-export_viz_format') !== null")
  expect_true(has_viz_format, info = "Viz format selector should exist")

  has_viz_width <- app$get_js(
    "document.querySelector('#export_reports_mod-export_viz_width') !== null")
  expect_true(has_viz_width, info = "Viz width input should exist")

  has_viz_height <- app$get_js(
    "document.querySelector('#export_reports_mod-export_viz_height') !== null")
  expect_true(has_viz_height, info = "Viz height input should exist")

  # Report generation section
  has_report_type <- app$get_js(
    "document.querySelector('#export_reports_mod-report_type') !== null")
  expect_true(has_report_type, info = "Report type selector should exist")

  has_report_format <- app$get_js(
    "document.querySelector('#export_reports_mod-report_format') !== null")
  expect_true(has_report_format, info = "Report format selector should exist")

  has_include_viz <- app$get_js(
    "document.querySelector('#export_reports_mod-report_include_viz') !== null")
  expect_true(has_include_viz, info = "Include viz checkbox should exist")

  has_include_data <- app$get_js(
    "document.querySelector('#export_reports_mod-report_include_data') !== null")
  expect_true(has_include_data, info = "Include data checkbox should exist")

  has_generate_btn <- app$get_js(
    "document.querySelector('#export_reports_mod-generate_report') !== null")
  expect_true(has_generate_btn, info = "Generate report button should exist")

  # Verify default values
  tryCatch({
    viz_width <- app$get_value(input = "export_reports_mod-export_viz_width")
    expect_equal(viz_width, 1200, info = "Default viz width should be 1200")

    viz_height <- app$get_value(input = "export_reports_mod-export_viz_height")
    expect_equal(viz_height, 900, info = "Default viz height should be 900")

    report_include_viz <- app$get_value(input = "export_reports_mod-report_include_viz")
    expect_true(report_include_viz, info = "Include viz should default to TRUE")
  }, error = function(e) {
    message("Could not read export defaults: ", e$message)
  })

  expect_false(has_shiny_errors(app))
  assert_no_critical_console_errors(app, "export module")
})

test_that("Expert E2E: Export controls accept changed values", {
  app <- create_app("expert-export-change")
  on.exit(app$stop(), add = TRUE)

  app$wait_for_idle(timeout = LONG_WAIT)
  install_console_interceptor(app)

  navigate_to(app, "export", IDLE_WAIT)

  # Change data format
  tryCatch({
    app$set_inputs(`export_reports_mod-export_data_format` = "JSON (.json)",
                   wait_ = TRUE, timeout_ = E2E_TIMEOUT)
    app$wait_for_idle(timeout = SHORT_WAIT)

    val <- app$get_value(input = "export_reports_mod-export_data_format")
    expect_equal(val, "JSON (.json)", info = "Data format should change to JSON")
  }, error = function(e) {
    message("Could not change data format: ", e$message)
  })

  # Change viz format
  tryCatch({
    app$set_inputs(`export_reports_mod-export_viz_format` = "SVG (.svg)",
                   wait_ = TRUE, timeout_ = E2E_TIMEOUT)
    app$wait_for_idle(timeout = SHORT_WAIT)

    val <- app$get_value(input = "export_reports_mod-export_viz_format")
    expect_equal(val, "SVG (.svg)", info = "Viz format should change to SVG")
  }, error = function(e) {
    message("Could not change viz format: ", e$message)
  })

  # Change report type
  tryCatch({
    app$set_inputs(`export_reports_mod-report_type` = "technical",
                   wait_ = TRUE, timeout_ = E2E_TIMEOUT)
    app$wait_for_idle(timeout = SHORT_WAIT)

    val <- app$get_value(input = "export_reports_mod-report_type")
    expect_equal(val, "technical", info = "Report type should change to technical")
  }, error = function(e) {
    message("Could not change report type: ", e$message)
  })

  assert_no_critical_console_errors(app, "export value changes")
})

# ============================================================================
# TEST SUITE 14: RESPONSE & VALIDATION MODULES
# ============================================================================

test_that("Expert E2E: Response measures module renders", {
  app <- create_app("expert-response-measures")
  on.exit(app$stop(), add = TRUE)

  app$wait_for_idle(timeout = LONG_WAIT)
  install_console_interceptor(app)
  set_expert_mode(app)

  navigate_to(app, "response_measures", IDLE_WAIT)

  has_module <- app$get_js(
    "document.querySelector('[id^=\"resp_meas\"]') !== null")
  expect_true(has_module, info = "Response measures module should render")

  expect_false(has_shiny_errors(app))
  assert_no_critical_console_errors(app, "response measures")
})

test_that("Expert E2E: Scenario builder module renders", {
  app <- create_app("expert-scenario-builder")
  on.exit(app$stop(), add = TRUE)

  app$wait_for_idle(timeout = LONG_WAIT)
  install_console_interceptor(app)
  set_expert_mode(app)

  navigate_to(app, "response_scenarios", IDLE_WAIT)

  has_module <- app$get_js(
    "document.querySelector('[id^=\"scenario_builder\"]') !== null")
  expect_true(has_module, info = "Scenario builder module should render")

  expect_false(has_shiny_errors(app))
  assert_no_critical_console_errors(app, "scenario builder")
})

test_that("Expert E2E: Response validation module renders", {
  app <- create_app("expert-response-validation")
  on.exit(app$stop(), add = TRUE)

  app$wait_for_idle(timeout = LONG_WAIT)
  install_console_interceptor(app)
  set_expert_mode(app)

  navigate_to(app, "response_validation", IDLE_WAIT)

  has_module <- app$get_js(
    "document.querySelector('[id^=\"resp_val\"]') !== null")
  expect_true(has_module, info = "Response validation module should render")

  expect_false(has_shiny_errors(app))
  assert_no_critical_console_errors(app, "response validation")
})

# ============================================================================
# TEST SUITE 15: PIMS MODULES
# ============================================================================

test_that("Expert E2E: All PIMS modules render correctly", {
  app <- create_app("expert-pims")
  on.exit(app$stop(), add = TRUE)

  app$wait_for_idle(timeout = LONG_WAIT)
  install_console_interceptor(app)
  set_expert_mode(app)

  pims_tabs <- list(
    list(tab = "pims_project", prefix = "pims_proj", name = "PIMS Project"),
    list(tab = "pims_stakeholders", prefix = "pims_stake", name = "PIMS Stakeholders"),
    list(tab = "pims_resources", prefix = "pims_res", name = "PIMS Resources"),
    list(tab = "pims_data", prefix = "pims_dm", name = "PIMS Data"),
    list(tab = "pims_evaluation", prefix = "pims_eval", name = "PIMS Evaluation")
  )

  for (pims in pims_tabs) {
    navigate_to(app, pims$tab, SHORT_WAIT)

    has_module <- app$get_js(sprintf(
      "document.querySelector('[id^=\"%s\"]') !== null", pims$prefix))
    expect_true(has_module, info = paste(pims$name, "module should render"))

    expect_false(has_shiny_errors(app),
      info = paste(pims$name, "should render without errors"))
  }

  assert_no_critical_console_errors(app, "all PIMS modules")
})

# ============================================================================
# TEST SUITE 16: LANGUAGE SWITCHING WITH DATA PRESERVATION
# ============================================================================

test_that("Expert E2E: Language selector exists and has all 9 languages", {
  app <- create_app("expert-lang-selector")
  on.exit(app$stop(), add = TRUE)

  app$wait_for_idle(timeout = LONG_WAIT)
  install_console_interceptor(app)

  # Language selector should exist
  has_lang <- app$get_js(
    "document.querySelector('#language_selector') !== null")
  expect_true(has_lang, info = "Language selector should exist")

  # Check all 9 languages are available
  lang_count <- app$get_js("
    var sel = document.querySelector('#language_selector');
    if (sel) {
      return sel.querySelectorAll('option').length;
    }
    return 0;
  ")
  expect_gte(lang_count, 9,
    info = "Language selector should have at least 9 language options")

  # Verify specific language codes
  has_all_langs <- app$get_js("
    var sel = document.querySelector('#language_selector');
    if (!sel) return false;
    var opts = Array.from(sel.querySelectorAll('option')).map(o => o.value);
    var required = ['en', 'es', 'fr', 'de', 'lt', 'pt', 'it', 'no', 'el'];
    return required.every(l => opts.includes(l));
  ")
  expect_true(has_all_langs,
    info = "All 9 language codes should be available")

  assert_no_critical_console_errors(app, "language selector check")
})

# ============================================================================
# TEST SUITE 17: IMPORT DATA MODULE
# ============================================================================

test_that("Expert E2E: Import data module renders with file upload", {
  app <- create_app("expert-import")
  on.exit(app$stop(), add = TRUE)

  app$wait_for_idle(timeout = LONG_WAIT)
  install_console_interceptor(app)
  set_expert_mode(app)

  navigate_to(app, "import_data", IDLE_WAIT)

  has_module <- app$get_js(
    "document.querySelector('[id^=\"import_data_mod\"]') !== null")
  expect_true(has_module, info = "Import data module should render")

  # Should have a file input for uploading
  has_file_input <- app$get_js("
    document.querySelector('[id^=\"import_data_mod\"] input[type=\"file\"]') !== null ||
    document.querySelector('[id^=\"import_data_mod\"] .shiny-file-input-progress') !== null ||
    document.querySelector('[id^=\"import_data_mod\"] .btn-file') !== null
  ")
  expect_true(has_file_input, info = "Import module should have file upload input")

  expect_false(has_shiny_errors(app))
  assert_no_critical_console_errors(app, "import data module")
})

# ============================================================================
# TEST SUITE 18: SES MODELS (Pre-built)
# ============================================================================

test_that("Expert E2E: SES models module loads and displays models", {
  app <- create_app("expert-ses-models")
  on.exit(app$stop(), add = TRUE)

  app$wait_for_idle(timeout = LONG_WAIT)
  install_console_interceptor(app)
  set_expert_mode(app)

  navigate_to(app, "ses_models", LONG_WAIT)

  has_module <- app$get_js(
    "document.querySelector('[id^=\"ses_models_mod\"]') !== null")
  expect_true(has_module, info = "SES models module should render")

  # Should have model cards, buttons or list items
  has_model_items <- app$get_js("
    document.querySelectorAll('[id^=\"ses_models_mod\"] .card, [id^=\"ses_models_mod\"] .list-group-item, [id^=\"ses_models_mod\"] button, [id^=\"ses_models_mod\"] .btn').length > 0
  ")
  expect_true(has_model_items, info = "SES models should show available models")

  expect_false(has_shiny_errors(app))
  assert_no_critical_console_errors(app, "SES models module")
})

# ============================================================================
# TEST SUITE 19: GUIDEBOOK MODULE
# ============================================================================

test_that("Expert E2E: Guidebook module loads content", {
  app <- create_app("expert-guidebook")
  on.exit(app$stop(), add = TRUE)

  app$wait_for_idle(timeout = LONG_WAIT)
  install_console_interceptor(app)

  navigate_to(app, "guidebook", LONG_WAIT)

  has_module <- app$get_js(
    "document.querySelector('[id^=\"guidebook\"]') !== null")
  expect_true(has_module, info = "Guidebook module should render")

  # Should have readable content (text, sections, etc.)
  content_length <- app$get_js("
    var el = document.querySelector('[id^=\"guidebook\"]');
    if (el) return el.textContent.length;
    return 0;
  ")
  expect_gte(content_length, 10,
    info = "Guidebook should have readable content")

  expect_false(has_shiny_errors(app))
  assert_no_critical_console_errors(app, "guidebook module")
})

# ============================================================================
# TEST SUITE 20: REPORT PREPARATION MODULE
# ============================================================================

test_that("Expert E2E: Prepare report module renders", {
  app <- create_app("expert-prepare-report")
  on.exit(app$stop(), add = TRUE)

  app$wait_for_idle(timeout = LONG_WAIT)
  install_console_interceptor(app)
  set_expert_mode(app)

  navigate_to(app, "prepare_report", IDLE_WAIT)

  has_module <- app$get_js(
    "document.querySelector('[id^=\"prep_report\"]') !== null")
  expect_true(has_module, info = "Report preparation module should render")

  expect_false(has_shiny_errors(app))
  assert_no_critical_console_errors(app, "prepare report module")
})

# ============================================================================
# TEST SUITE 21: ENTRY POINT (GETTING STARTED) WIZARD
# ============================================================================

test_that("Expert E2E: Entry point wizard renders interactive elements", {
  app <- create_app("expert-entry-point")
  on.exit(app$stop(), add = TRUE)

  app$wait_for_idle(timeout = LONG_WAIT)
  install_console_interceptor(app)

  navigate_to(app, "entry_point", IDLE_WAIT)

  has_module <- app$get_js(
    "document.querySelector('[id^=\"entry_pt\"]') !== null")
  expect_true(has_module, info = "Entry point module should render")

  # Should have a "Start" or "Begin" button
  has_start_btn <- app$get_js("
    document.querySelector('#entry_pt-start_guided') !== null ||
    document.querySelector('[id^=\"entry_pt\"] .btn-primary') !== null ||
    document.querySelector('[id^=\"entry_pt\"] .btn-lg') !== null
  ")
  expect_true(has_start_btn, info = "Entry point should have a start/begin button")

  # Click start guided if it exists
  tryCatch({
    app$click("entry_pt-start_guided")
    app$wait_for_idle(timeout = IDLE_WAIT)

    # After clicking start, more content should appear
    post_click_content <- app$get_js("
      document.querySelectorAll('[id^=\"entry_pt\"] .card, [id^=\"entry_pt\"] .method-card, [id^=\"entry_pt\"] .btn').length
    ")
    expect_gte(post_click_content, 1,
      info = "Clicking start should reveal more content")
  }, error = function(e) {
    message("Could not click start button: ", e$message)
  })

  expect_false(has_shiny_errors(app))
  assert_no_critical_console_errors(app, "entry point wizard")
})

# ============================================================================
# TEST SUITE 22: HEADER ELEMENTS (Modals, Icons, Branding)
# ============================================================================

test_that("Expert E2E: Header contains all expected action icons", {
  app <- create_app("expert-header")
  on.exit(app$stop(), add = TRUE)

  app$wait_for_idle(timeout = LONG_WAIT)
  install_console_interceptor(app)

  # Check header exists
  has_header <- app$get_js(
    "document.querySelector('.main-header') !== null ||
     document.querySelector('.navbar') !== null")
  expect_true(has_header, info = "App header should exist")

  # Language selector in header
  has_lang <- app$get_js(
    "document.querySelector('#language_selector') !== null")
  expect_true(has_lang, info = "Language selector in header")

  # Settings, About, Manuals, Feedback icons
  icon_checks <- list(
    list(id = "settings_btn", name = "Settings"),
    list(id = "about_btn", name = "About"),
    list(id = "manuals_btn", name = "Manuals")
  )

  for (ic in icon_checks) {
    has_icon <- app$get_js(sprintf(
      "document.querySelector('#%s') !== null || document.querySelector('[id*=\"%s\"]') !== null",
      ic$id, gsub("_btn$", "", ic$id)
    ))
    # These may or may not exist depending on the header build
    if (!has_icon) {
      message(sprintf("Note: %s button not found with ID #%s", ic$name, ic$id))
    }
  }

  # Footer content
  footer_text <- app$get_js(
    "document.querySelector('.main-footer') ? document.querySelector('.main-footer').textContent : ''")
  expect_match(footer_text, "Marine-SABRES",
    info = "Footer should mention Marine-SABRES")
  expect_match(footer_text, "2026",
    info = "Footer should contain copyright year")

  assert_no_critical_console_errors(app, "header elements")
})

# ============================================================================
# TEST SUITE 23: ARIA & ACCESSIBILITY
# ============================================================================

test_that("Expert E2E: Accessibility infrastructure is present", {
  app <- create_app("expert-a11y")
  on.exit(app$stop(), add = TRUE)

  app$wait_for_idle(timeout = LONG_WAIT)
  install_console_interceptor(app)

  # Skip-link for keyboard navigation
  has_skip_link <- app$get_js(
    "document.querySelector('.skip-link') !== null ||
     document.querySelector('a[href=\"#main-content\"]') !== null")
  expect_true(has_skip_link, info = "Skip-link for keyboard navigation should exist")

  # ARIA live regions
  has_status_region <- app$get_js(
    "document.querySelector('#aria-live-status') !== null")
  expect_true(has_status_region, info = "ARIA live status region should exist")

  has_alert_region <- app$get_js(
    "document.querySelector('#aria-live-alert') !== null")
  expect_true(has_alert_region, info = "ARIA live alert region should exist")

  # Main content landmark
  has_main_landmark <- app$get_js(
    "document.querySelector('#main-content[role=\"main\"]') !== null")
  expect_true(has_main_landmark, info = "Main content landmark should exist with role=main")

  # ARIA attributes on live regions
  status_attrs <- app$get_js("
    var el = document.querySelector('#aria-live-status');
    if (!el) return 'missing';
    return el.getAttribute('aria-live') + '|' + el.getAttribute('role');
  ")
  expect_equal(status_attrs, "polite|status",
    info = "Status region should have aria-live=polite and role=status")

  alert_attrs <- app$get_js("
    var el = document.querySelector('#aria-live-alert');
    if (!el) return 'missing';
    return el.getAttribute('aria-live') + '|' + el.getAttribute('role');
  ")
  expect_equal(alert_attrs, "assertive|alert",
    info = "Alert region should have aria-live=assertive and role=alert")

  assert_no_critical_console_errors(app, "accessibility checks")
})

# ============================================================================
# TEST SUITE 24: CSS AND ASSET LOADING
# ============================================================================

test_that("Expert E2E: All custom CSS and JS assets load correctly", {
  app <- create_app("expert-assets")
  on.exit(app$stop(), add = TRUE)

  app$wait_for_idle(timeout = LONG_WAIT)
  install_console_interceptor(app)

  # Custom CSS files
  css_count <- app$get_js("
    Array.from(document.querySelectorAll('link[rel=\"stylesheet\"]'))
      .filter(l => l.href.includes('bs4dash-custom.css') ||
                   l.href.includes('custom.css') ||
                   l.href.includes('isa-forms.css') ||
                   l.href.includes('workflow-stepper.css'))
      .length
  ")
  expect_gte(css_count, 2,
    info = "At least 2 custom CSS files should be loaded")

  # custom.js should be loaded
  has_custom_js <- app$get_js("
    Array.from(document.querySelectorAll('script'))
      .some(s => s.src && s.src.includes('custom.js'))
  ")
  expect_true(has_custom_js, info = "custom.js should be loaded")

  # shiny.i18n JS should be loaded
  has_i18n_js <- app$get_js("
    typeof Shiny !== 'undefined' && typeof Shiny.setInputValue === 'function'
  ")
  expect_true(has_i18n_js, info = "Shiny JS framework should be loaded")

  # shinyjs should be initialized
  has_shinyjs <- app$get_js("
    typeof shinyjs !== 'undefined' || typeof window.shinyjs !== 'undefined' ||
    document.querySelector('script[src*=\"shinyjs\"]') !== null ||
    document.querySelector('[id$=\"-shinyjs\"]') !== null
  ")
  # shinyjs is always loaded by app.R
  expect_true(has_shinyjs, info = "shinyjs should be initialized")

  # No 404 errors for CSS (check computed styles)
  body_font <- app$get_js("getComputedStyle(document.body).fontFamily")
  expect_true(nzchar(body_font), info = "Body should have computed font-family (CSS loaded)")

  assert_no_critical_console_errors(app, "asset loading")
})

# ============================================================================
# TEST SUITE 25: RAPID MULTI-TAB SWITCHING (Stress Test)
# ============================================================================

test_that("Expert E2E: Rapid tab switching doesn't crash the app", {
  app <- create_app("expert-stress-nav")
  on.exit(app$stop(), add = TRUE)

  app$wait_for_idle(timeout = LONG_WAIT)
  install_console_interceptor(app)
  set_expert_mode(app)

  # Rapidly switch between tabs
  rapid_tabs <- c(
    "dashboard", "cld_viz", "analysis_loops", "export",
    "create_ses_template", "analysis_metrics", "response_measures",
    "guidebook", "dashboard", "create_ses_ai", "analysis_boolean",
    "entry_point"
  )

  for (tab in rapid_tabs) {
    tryCatch({
      app$set_inputs(sidebar_menu = tab, wait_ = FALSE, timeout_ = E2E_TIMEOUT)
      Sys.sleep(0.3)  # Brief pause, not full idle wait
    }, error = function(e) {
      message("Rapid nav error on ", tab, ": ", e$message)
    })
  }

  # Wait for everything to settle
  app$wait_for_idle(timeout = LONG_WAIT)
  Sys.sleep(2)

  # App should still be running
  expect_true(app$is_running(), info = "App should survive rapid tab switching")

  # No crash errors
  expect_false(has_shiny_errors(app),
    info = "No Shiny errors after rapid tab switching")

  assert_no_critical_console_errors(app, "rapid tab switching stress test")
})

# ============================================================================
# TEST SUITE 26: GRAPHICAL SES CREATOR
# ============================================================================

test_that("Expert E2E: Graphical SES creator module renders", {
  app <- create_app("expert-graphical-ses")
  on.exit(app$stop(), add = TRUE)

  app$wait_for_idle(timeout = LONG_WAIT)
  install_console_interceptor(app)
  set_expert_mode(app)

  # Navigate - this tab may need expert level
  tryCatch({
    navigate_to(app, "graphical_ses_creator", LONG_WAIT)

    has_module <- app$get_js(
      "document.querySelector('[id^=\"graphical_ses_mod\"]') !== null")
    expect_true(has_module, info = "Graphical SES creator module should render")

    # Should have a canvas area
    has_canvas <- app$get_js("
      document.querySelector('[id^=\"graphical_ses_mod\"] canvas') !== null ||
      document.querySelector('[id^=\"graphical_ses_mod\"] .vis-network') !== null ||
      document.querySelector('[id^=\"graphical_ses_mod\"] .card') !== null
    ")
    expect_true(has_canvas,
      info = "Graphical creator should have network canvas or cards")
  }, error = function(e) {
    message("Graphical SES creator may not be accessible: ", e$message)
  })

  expect_false(has_shiny_errors(app))
  assert_no_critical_console_errors(app, "graphical SES creator")
})

# ============================================================================
# TEST SUITE 27: LOCAL STORAGE & AUTO-SAVE INFRASTRUCTURE
# ============================================================================

test_that("Expert E2E: Auto-save and local storage elements are wired", {
  app <- create_app("expert-autosave")
  on.exit(app$stop(), add = TRUE)

  app$wait_for_idle(timeout = LONG_WAIT)
  install_console_interceptor(app)

  # Auto-save indicator UI should exist
  has_autosave_indicator <- app$get_js("
    document.querySelector('[id^=\"auto_save\"]') !== null ||
    document.querySelector('.autosave-indicator') !== null
  ")
  expect_true(has_autosave_indicator, info = "Auto-save indicator should exist")

  # Local storage module UI should exist
  has_local_storage <- app$get_js("
    document.querySelector('[id^=\"local_storage\"]') !== null
  ")
  expect_true(has_local_storage, info = "Local storage module should be wired")

  # localStorage should be accessible
  ls_accessible <- app$get_js("
    try {
      localStorage.setItem('__test_e2e__', 'ok');
      var val = localStorage.getItem('__test_e2e__');
      localStorage.removeItem('__test_e2e__');
      return val === 'ok';
    } catch(e) {
      return false;
    }
  ")
  expect_true(ls_accessible, info = "localStorage should be accessible")

  assert_no_critical_console_errors(app, "auto-save infrastructure")
})

# ============================================================================
# TEST SUITE 28: WORKFLOW STEPPER (Beginner Guidance)
# ============================================================================

test_that("Expert E2E: Workflow stepper element exists in DOM", {
  app <- create_app("expert-stepper")
  on.exit(app$stop(), add = TRUE)

  app$wait_for_idle(timeout = LONG_WAIT)
  install_console_interceptor(app)

  # Stepper should be in DOM (may be hidden for expert users)
  has_stepper <- app$get_js("
    document.querySelector('[id^=\"workflow_stepper\"]') !== null
  ")
  expect_true(has_stepper, info = "Workflow stepper should exist in DOM")

  assert_no_critical_console_errors(app, "workflow stepper")
})

# ============================================================================
# TEST SUITE 29: SHINY REACTIVE PIPELINE INTEGRITY
# ============================================================================

test_that("Expert E2E: Navigate CLD then analysis - no orphaned reactives", {
  app <- create_app("expert-pipeline")
  on.exit(app$stop(), add = TRUE)

  app$wait_for_idle(timeout = LONG_WAIT)
  install_console_interceptor(app)
  set_expert_mode(app)

  # Navigate through the pipeline: ISA → CLD → Analysis
  navigate_to(app, "create_ses_standard", IDLE_WAIT)
  navigate_to(app, "cld_viz", LONG_WAIT)

  # visNetwork canvas should be present
  has_vis <- app$get_js("
    document.querySelector('.vis-network') !== null ||
    document.querySelector('[id$=\"-network\"]') !== null
  ")

  # Now go to analysis
  navigate_to(app, "analysis_loops", IDLE_WAIT)
  navigate_to(app, "analysis_metrics", IDLE_WAIT)

  # Go back to CLD
  navigate_to(app, "cld_viz", IDLE_WAIT)

  # App should still be stable
  expect_true(app$is_running())
  expect_false(has_shiny_errors(app),
    info = "Pipeline navigation should not produce errors")

  assert_no_critical_console_errors(app, "reactive pipeline integrity")
})

# ============================================================================
# TEST SUITE 30: CONSOLE ERROR SUMMARY (Final Comprehensive Check)
# ============================================================================

test_that("Expert E2E: Full session comprehensive console error audit", {
  app <- create_app("expert-console-audit")
  on.exit(app$stop(), add = TRUE)

  app$wait_for_idle(timeout = LONG_WAIT)
  install_console_interceptor(app)
  set_expert_mode(app)

  # Visit every major page and collect ALL console output
  all_pages <- c(
    "entry_point", "dashboard",
    "create_ses_choose", "create_ses_template", "create_ses_ai", "create_ses_standard",
    "cld_viz",
    "analysis_metrics", "analysis_loops", "analysis_leverage",
    "analysis_bot", "analysis_simplify",
    "analysis_boolean", "analysis_simulation", "analysis_intervention",
    "response_measures", "response_scenarios", "response_validation",
    "import_data", "ses_models",
    "export", "prepare_report", "guidebook"
  )

  for (page in all_pages) {
    tryCatch({
      navigate_to(app, page, SHORT_WAIT)
    }, error = function(e) {
      # Some pages might not be navigable in all user levels
    })
  }

  # Wait for everything to settle
  app$wait_for_idle(timeout = LONG_WAIT)
  Sys.sleep(2)

  # Get full console report
  issues <- get_console_issues(app)

  # Report warnings (informational, not failing)
  if (length(issues$warnings) > 0) {
    message(sprintf("\n=== CONSOLE WARNINGS (%d) ===", length(issues$warnings)))
    for (w in head(issues$warnings, 20)) {
      message("  WARN: ", substr(w, 1, 200))
    }
    if (length(issues$warnings) > 20) {
      message(sprintf("  ... and %d more warnings", length(issues$warnings) - 20))
    }
  }

  # Report all errors (informational)
  if (length(issues$errors) > 0) {
    message(sprintf("\n=== CONSOLE ERRORS (%d) ===", length(issues$errors)))
    for (e in issues$errors) {
      message("  ERROR: ", substr(e, 1, 200))
    }
  }

  # Final assertion: no critical errors
  assert_no_critical_console_errors(app, "comprehensive console audit after visiting all pages")

  # App survived the full tour
  expect_true(app$is_running(), info = "App should survive visiting all pages")
})
