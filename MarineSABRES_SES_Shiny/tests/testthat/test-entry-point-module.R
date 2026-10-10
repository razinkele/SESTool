# test-entry-point-module.R
# Behavior tests for modules/entry_point_module.R
#
# Rewritten in v1.16.5 from a signature-only template to actually
# exercise the module's state-machine behavior (welcome → guided →
# recommendations + per-step EP0..EP4 toggle/continue/skip). The
# previous version asserted only that the functions existed with the
# right parameters; it would have passed even if every observer body
# were replaced with NULL. This file is the pattern the remaining
# 5 brittle module tests should follow.

library(testthat)
library(shiny)

# Source the real module under test (overrides any stub in helper-stubs.R).
source_for_test("modules/entry_point_module.R")

# Minimal translator that returns its input verbatim — enough for any
# i18n$t() call inside the module to produce a deterministic string.
i18n <- list(
  t = function(key) key,
  get_translation_language = function() "en"
)

# ============================================================================
# UI contract (kept lightweight — exhaustive structure is fragile)
# ============================================================================

test_that("entry_point_ui returns shiny tags and namespaces the id", {
  ui <- entry_point_ui("test_ep", i18n)
  expect_true(inherits(ui, "shiny.tag") || inherits(ui, "shiny.tag.list"))
  expect_true(grepl("test_ep", as.character(ui)))
})

# ============================================================================
# Server behavior — drives the REAL server with shiny::testServer() and
# asserts the module's reactive state.
#
# Review 2026-10-07 N45: these tests used to call testServer() on the bare
# symbol `entry_point_server`, which resolves to the helper-stubs.R stub (the
# helper env shadows the .GlobalEnv copy source_for_test() writes), and ended
# in expect_true(TRUE) -- so they passed with the module body deleted. Bind
# the real server explicitly and assert on rv.
# ============================================================================

real_entry_point_server <- get("entry_point_server", envir = .GlobalEnv)


test_that("the behaviour tests drive the real module, not the helper stub", {
  expect_true(any(grepl("current_screen", deparse(body(real_entry_point_server)), fixed = TRUE)))
})

test_that("initial state is the welcome screen at step 0", {
  testServer(real_entry_point_server,
             args = list(project_data_reactive = reactive(list()), i18n = i18n), {
    session$flushReact()
    expect_identical(rv$current_screen, "welcome")
    expect_equal(rv$current_step, 0)
  })
})

test_that("start_guided enters the guided flow; a chosen role lets EP0 continue", {
  testServer(real_entry_point_server,
             args = list(project_data_reactive = reactive(list()), i18n = i18n), {
    session$setInputs(start_guided = 1)
    expect_identical(rv$current_screen, "guided")
    expect_equal(rv$current_step, 0)
    session$setInputs(ep0_role_click = "researcher")
    expect_identical(rv$ep0_selected, "researcher")
    session$setInputs(ep0_continue = 1)
    expect_equal(rv$current_step, 1)
  })
})

test_that("clicking a role twice deselects it, and EP0 cannot continue empty", {
  testServer(real_entry_point_server,
             args = list(project_data_reactive = reactive(list()), i18n = i18n), {
    session$setInputs(start_guided = 1)
    session$setInputs(ep0_role_click = "researcher")
    session$setInputs(ep0_role_click = "policy")
    expect_setequal(rv$ep0_selected, c("researcher", "policy"))
    # same value twice does not re-fire an input, so toggle via a different
    # value first and then back
    session$setInputs(ep0_role_click = "researcher")
    expect_identical(rv$ep0_selected, "policy")
    session$setInputs(ep0_role_click = "policy")
    expect_length(rv$ep0_selected, 0)
    session$setInputs(ep0_continue = 1)
    expect_equal(rv$current_step, 0)   # stays on EP0 (warning shown instead)
  })
})

test_that("ep0_skip clears the selection and advances to EP1", {
  testServer(real_entry_point_server,
             args = list(project_data_reactive = reactive(list()), i18n = i18n), {
    session$setInputs(start_guided = 1)
    session$setInputs(ep0_role_click = "researcher")
    session$setInputs(ep0_skip = 1)
    expect_equal(rv$current_step, 1)
    expect_length(rv$ep0_selected, 0)
    session$setInputs(ep1_need_click = "fisheries")
    expect_identical(rv$ep1_selected, "fisheries")
  })
})

test_that("start_over from a guided step returns to welcome and clears selections", {
  testServer(real_entry_point_server,
             args = list(project_data_reactive = reactive(list()), i18n = i18n), {
    session$setInputs(start_guided = 1)
    session$setInputs(ep0_role_click = "researcher")
    session$setInputs(ep0_continue = 1)
    session$setInputs(ep1_need_click = "fisheries")
    expect_equal(rv$current_step, 1)
    session$setInputs(start_over = 1)
    expect_identical(rv$current_screen, "welcome")
    expect_equal(rv$current_step, 0)
    expect_length(rv$ep0_selected, 0)
    expect_length(rv$ep1_selected, 0)
  })
})

# ============================================================================
# Signature contract (kept for compatibility — these guard against
# accidental signature changes that would break callers in app.R)
# ============================================================================

test_that("entry_point_server has the conventional signature", {
  params <- names(formals(real_entry_point_server))
  for (p in c("id", "project_data_reactive", "i18n", "event_bus")) {
    expect_true(p %in% params, info = paste0("Missing parameter: ", p))
  }
  expect_true(is.null(formals(real_entry_point_server)$event_bus))
})
