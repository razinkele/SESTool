# test-ai-isa-observer-leak.R
# Regression test for H3: stacking observeEvent(input$confirm_regional_sea_change)
# on re-selection of a regional sea after progress.
#
# Bug: Every time the user re-selected a regional sea after making progress, an
# inline observeEvent was created inside the per-selection handler.  On
# "Continue" all stacked copies fired → move_to_next_step() ran N times,
# appending N duplicate AI messages.
#
# Fix: The inline observeEvent is replaced by a single once-observer created at
# module setup (after nav_fns are bound).  The pending sea key is staged in
# rv$pending_sea_key; req(!is.null(sk)) makes a consumed/stray re-fire a no-op.
#
# Test approach: BEHAVIORAL via testServer() + structural guard.
# - Behavioral: drive the REAL server, simulate the confirm path TWICE in a row
#   (mimicking two stacked observers under old code), assert conversation grew by
#   exactly 1 "regional_sea_changed_to" message, not 2.
# - Structural: assert the inline observeEvent no longer exists inside the
#   step-builder block while the once-observer is present at setup level.

library(testthat)
library(shiny)

# ---------------------------------------------------------------------------
# Source the module and its sub-modules from the project root.
# The main module file has relative source() calls (e.g. source("modules/ai_isa/...",
# local=TRUE)) that require the working directory to be the project root.
# We temporarily change to project root before sourcing so those relative paths
# resolve correctly, then restore the original wd.
# ---------------------------------------------------------------------------
local({
  td   <- getwd()
  root <- if (basename(td) == "testthat") dirname(dirname(td)) else td
  old_wd <- setwd(root)
  on.exit(setwd(old_wd), add = TRUE)

  # Source each AI ISA sub-module explicitly into .GlobalEnv so they are
  # available both when the main module body runs its local source() calls
  # and when testServer() drives the server function.
  sub_modules <- c(
    "modules/ai_isa/connection_generator.R",
    "modules/ai_isa/ui_components.R",
    "modules/ai_isa/question_flow.R",
    "modules/ai_isa/answer_processor.R",
    "modules/ai_isa/data_persistence.R",
    "modules/ai_isa/ui_renderers.R",
    "modules/ai_isa/template_handlers.R",
    "modules/ai_isa/action_handlers.R",
    "modules/ai_isa/step_navigation.R"
  )
  for (sm in sub_modules) {
    tryCatch(
      sys.source(file.path(root, sm), envir = .GlobalEnv),
      error = function(e) message("source_for_test: could not source ", sm, ": ", e$message)
    )
  }

  # Now source the main module file (its inner source() calls are relative and
  # will resolve correctly because cwd is now the project root).
  tryCatch(
    sys.source(file.path(root, "modules/ai_isa_assistant_module.R"), envir = .GlobalEnv),
    error = function(e) message("source_for_test: could not source ai_isa_assistant_module.R: ", e$message)
  )
})

# Re-bind the real server from .GlobalEnv to override helper-stubs.R stub
# (see testServer stub-shadowing pattern documented in CLAUDE.md).
ai_isa_assistant_server <- get("ai_isa_assistant_server", envir = .GlobalEnv)

# Minimal i18n translator — returns its key verbatim for deterministic assertions
i18n <- list(
  t = function(key, ...) key,
  get_translation_language = function() "en"
)

# Minimal project_data_reactive stub
make_project_data <- function() {
  reactiveVal(list(
    project_id = "test_proj",
    name = "Test Project",
    data = list(isa_data = list())
  ))
}

# ============================================================================
# STRUCTURAL ASSERTION
# Guard: inline observeEvent(input$confirm_regional_sea_change inside step-builder
# must be ABSENT; the once-observer at setup level must be PRESENT.
# This test will FAIL if a developer re-introduces the stacking pattern.
# ============================================================================

test_that("inline observeEvent(input$confirm_regional_sea_change is absent from step-builder", {
  td  <- getwd()
  root <- if (basename(td) == "testthat") dirname(dirname(td)) else td
  module_file <- file.path(root, "modules", "ai_isa_assistant_module.R")
  skip_if_not(file.exists(module_file), "Module file not found")

  lines <- readLines(module_file, warn = FALSE)

  # Lines 1700-1820 cover the step-builder block (choice_regional_sea handler).
  # The inline observeEvent MUST NOT exist in this range.
  step_builder_lines <- lines[1700:min(1820, length(lines))]
  inline_leak <- grep(
    'observeEvent\\(input\\$confirm_regional_sea_change',
    step_builder_lines,
    value = TRUE
  )
  expect_equal(
    length(inline_leak), 0,
    info = "No inline observeEvent(input$confirm_regional_sea_change) in step-builder block"
  )

  # The once-observer MUST exist somewhere after line 2400 (after nav_fns setup).
  setup_lines <- lines[2400:length(lines)]
  once_observer <- grep(
    'observeEvent\\(input\\$confirm_regional_sea_change',
    setup_lines,
    value = TRUE
  )
  expect_true(length(once_observer) >= 1,
    label = "Once-observer for confirm_regional_sea_change exists at module setup level")
})

test_that("pending_sea_key is present in rv reactiveValues", {
  td   <- getwd()
  root <- if (basename(td) == "testthat") dirname(dirname(td)) else td
  module_file <- file.path(root, "modules", "ai_isa_assistant_module.R")
  skip_if_not(file.exists(module_file), "Module file not found")

  lines <- readLines(module_file, warn = FALSE)
  rv_block <- lines[150:200]
  has_pending <- any(grepl("pending_sea_key", rv_block))
  expect_true(has_pending,
    label = "pending_sea_key slot declared in rv reactiveValues block")
})

# ============================================================================
# BEHAVIORAL ASSERTION — drive the real server via testServer()
#
# Strategy:
#   1. Start module; seed rv with a "has-made-progress" state (ecosystem_type
#      set, regional_sea="baltic") at step 0.
#   2. Flush reactive graph so the step-builder observe fires and installs the
#      per-sea-key button observers for step 0.
#   3. Record conversation length baseline.
#   4. Click "regional_sea_mediterranean_s0" to trigger the modal path
#      (is_changing_selection=TRUE, has_made_progress=TRUE) → sets rv$pending_sea_key.
#   5. Fire confirm_regional_sea_change ONCE.
#   6. Assert conversation grew by exactly 1 "regional_sea_changed_to" message.
#   7. Assert rv$pending_sea_key was consumed (NULL).
#   Under the OLD (stacking) code, firing confirm ONCE would have fired both
#   copies (after two button clicks), appending 2 messages.  Under the FIX
#   only 1 message is appended regardless of how many times buttons were clicked.
# ============================================================================

test_that("confirm_regional_sea_change fires EXACTLY ONCE after multiple re-selections (no observer stack)", {
  # Skip if sub-modules failed to load (avoid false-failures on missing deps)
  skip_if_not(
    exists("setup_step_navigation", envir = .GlobalEnv, mode = "function"),
    "step_navigation.R sub-module not available"
  )
  skip_if_not(
    exists("ai_isa_assistant_server", envir = .GlobalEnv, mode = "function"),
    "ai_isa_assistant_server not available"
  )

  pd <- make_project_data()

  testServer(
    ai_isa_assistant_server,
    args = list(
      project_data_reactive = pd,
      i18n = i18n
    ),
    {
      # --- Seed "has made progress" state at step 0 ---
      # rv is accessible directly because testServer evaluates this block
      # inside the module server's execution environment.
      rv$current_step <- 0
      rv$context$regional_sea <- "baltic"
      rv$context$ecosystem_type <- "Open coast"  # triggers has_made_progress
      rv$render_counter <- 0

      # Flush so the step-builder observe runs and registers per-sea button handlers
      session$flushReact()

      # Capture baseline conversation length
      baseline_len <- length(rv$conversation)

      # --- Simulate user clicking "mediterranean" button TWICE ---
      # (Under old code each click would stack another confirm observer.
      #  Under the fix both clicks just overwrite rv$pending_sea_key — idempotent.)
      session$setInputs(`regional_sea_mediterranean_s0` = 1)
      session$flushReact()
      session$setInputs(`regional_sea_mediterranean_s0` = 2)
      session$flushReact()

      # pending_sea_key should now be "mediterranean"
      expect_equal(rv$pending_sea_key, "mediterranean",
        label = "pending_sea_key set to mediterranean after button clicks")

      # --- Fire confirm once ---
      session$setInputs(confirm_regional_sea_change = 1)
      session$flushReact()

      # Exactly ONE new "regional_sea_changed_to" AI message must be in conversation.
      new_messages <- rv$conversation[seq(baseline_len + 1, length(rv$conversation))]
      regional_sea_msgs <- Filter(function(m) {
        isTRUE(m$type == "ai") &&
          grepl("modules.isa.ai_assistant.regional_sea_changed_to", m$message, fixed = TRUE)
      }, new_messages)

      expect_equal(length(regional_sea_msgs), 1,
        label = paste0(
          "Exactly 1 'regional_sea_changed_to' message appended (got ",
          length(regional_sea_msgs), "); stacked observers would produce 2+"
        )
      )

      # pending_sea_key must be consumed (NULL) after confirm fires
      expect_null(rv$pending_sea_key,
        label = "pending_sea_key consumed (NULL) after confirm fires")

      # regional_sea context must be updated to the confirmed key
      expect_equal(rv$context$regional_sea, "mediterranean",
        label = "rv$context$regional_sea updated to confirmed sea")

      # ecosystem_type must be cleared (reset on change)
      expect_null(rv$context$ecosystem_type,
        label = "rv$context$ecosystem_type cleared on regional sea change")
    }
  )
})

test_that("confirm_regional_sea_change is a no-op when pending_sea_key is NULL (idempotency)", {
  skip_if_not(
    exists("setup_step_navigation", envir = .GlobalEnv, mode = "function"),
    "step_navigation.R sub-module not available"
  )
  skip_if_not(
    exists("ai_isa_assistant_server", envir = .GlobalEnv, mode = "function"),
    "ai_isa_assistant_server not available"
  )

  pd <- make_project_data()

  testServer(
    ai_isa_assistant_server,
    args = list(
      project_data_reactive = pd,
      i18n = i18n
    ),
    {
      session$flushReact()
      # pending_sea_key is NULL (no button clicked yet)
      expect_null(rv$pending_sea_key)
      baseline_sea <- rv$context$regional_sea  # NULL initially

      baseline_conv <- length(rv$conversation)

      # Fire confirm with no pending key — must be a complete no-op
      session$setInputs(confirm_regional_sea_change = 1)
      session$flushReact()

      # Conversation length unchanged
      expect_equal(length(rv$conversation), baseline_conv,
        label = "Conversation unchanged when confirm fires with NULL pending_sea_key")

      # regional_sea unchanged
      expect_equal(rv$context$regional_sea, baseline_sea,
        label = "regional_sea unchanged when confirm fires with NULL pending_sea_key")
    }
  )
})
