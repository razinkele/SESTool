# test-p3-fixes.R
# Verification tests for P3 (Priority 3) fixes from IMPROVEMENT_PLAN.md
#
# P3 Issues:
#   Issue #13: Server Function Extraction
#   Issue #14: Performance Optimization
#   Issue #15: Documentation Updates

# Helper to get project root
project_root <- if (exists("PROJECT_ROOT") && !is.null(PROJECT_ROOT)) {
  PROJECT_ROOT
} else {
  test_dir <- getwd()
  if (grepl("testthat$", test_dir)) {
    normalizePath(file.path(test_dir, "..", ".."), mustWork = FALSE)
  } else {
    test_dir
  }
}

# ============================================================================
# Issue #13: Server Function Extraction
# ============================================================================

test_that("P3 - session lifecycle lives in app.R; the unused session_management.R is gone", {
  # Review 2026-10-07 N70: server/session_management.R had zero call sites (app.R
  # carries the live inline code) and its clear_server_autosaves() targeted the
  # wrong folder ("autosave" instead of ".autosave"). It was deleted.
  expect_false(file.exists(file.path(project_root, "server/session_management.R")))
  app_src <- paste(readLines(file.path(project_root, "app.R"), warn = FALSE), collapse = "
")
  expect_false(grepl("session_management.R", app_src, fixed = TRUE))
  expect_true(grepl('file.path(persistent_folder, ".autosave")', app_src, fixed = TRUE))
  expect_true(file.exists(file.path(project_root, "functions/session_isolation.R")))
})

test_that("P3 - server/language_handling.R exists and has required functions", {
  file_path <- file.path(project_root, "server/language_handling.R")
  expect_true(file.exists(file_path), info = "language_handling.R should exist")

  content <- readLines(file_path, warn = FALSE)
  content_text <- paste(content, collapse = "\n")

  # Check for key functions
  expect_true(grepl("create_session_i18n", content_text),
              info = "Should have create_session_i18n function")
  expect_true(grepl("setup_language_restore_handler", content_text),
              info = "Should have setup_language_restore_handler function")
  expect_true(grepl("get_supported_languages", content_text),
              info = "Should have get_supported_languages function")
  expect_true(grepl("is_valid_language", content_text),
              info = "Should have is_valid_language function")
})

test_that("P3 - server/event_bus_setup.R exists and has required functions", {
  file_path <- file.path(project_root, "server/event_bus_setup.R")
  expect_true(file.exists(file_path), info = "event_bus_setup.R should exist")

  content <- readLines(file_path, warn = FALSE)
  content_text <- paste(content, collapse = "\n")

  # Check for key functions
  expect_true(grepl("create_event_bus", content_text),
              info = "Should have create_event_bus function")
  expect_true(grepl("is_event_bus", content_text),
              info = "Should have is_event_bus function")
  expect_true(grepl("safe_emit_isa_change", content_text),
              info = "Should have safe_emit_isa_change function")
  expect_true(grepl("safe_emit_cld_update", content_text),
              info = "Should have safe_emit_cld_update function")
  expect_true(grepl("setup_navigation_handler", content_text),
              info = "Should have setup_navigation_handler function")
})

test_that("P3 - app.R includes new server files in critical_sources", {
  file_path <- file.path(project_root, "app.R")
  expect_true(file.exists(file_path), info = "app.R should exist")

  content <- readLines(file_path, warn = FALSE)
  content_text <- paste(content, collapse = "\n")

  # Check that critical_sources includes the new files
  # (server/session_management.R was deleted as dead code -- review 2026-10-07 N70)
  expect_true(grepl("server/language_handling\\.R", content_text),
              info = "app.R should include language_handling.R in critical_sources")
  expect_true(grepl("server/event_bus_setup\\.R", content_text),
              info = "app.R should include event_bus_setup.R in critical_sources")
})

# ============================================================================
# Issue #14: Performance Optimization (Lazy Loading) - REMOVED
# Lazy loading infrastructure was removed as all modules are eagerly loaded.
# The lazy_loading.R file and its source line in global.R have been removed.
# ============================================================================

test_that("P3 - lazy_loading.R has been removed (modules are eagerly loaded)", {
  file_path <- file.path(project_root, "functions/lazy_loading.R")
  expect_false(file.exists(file_path),
               info = "lazy_loading.R should no longer exist - modules are eagerly loaded")

  # global.R should have a comment explaining removal
  global_content <- paste(readLines(file.path(project_root, "global.R"), warn = FALSE), collapse = "
")
  expect_true(grepl("Lazy loading infrastructure removed", global_content),
              info = "global.R should have comment about lazy loading removal")
})

# ============================================================================
# Issue #15: Documentation Updates
# ============================================================================
# (Review 2026-10-07 N75: tests that only checked that gitignored docs/ or
#  scripts/ files exist and contain certain headings were removed -- they
#  skipped in every CI run and asserted nothing about the app.)

# ============================================================================
# Server Function Tests (Functional)
# ============================================================================

test_that("P3 - language_handling functions are syntactically correct", {
  file_path <- file.path(project_root, "server/language_handling.R")
  skip_if_not(file.exists(file_path), "language_handling.R not found")

  # Try to parse the file - will error if syntax is invalid
  result <- tryCatch({
    parse(file_path)
    TRUE
  }, error = function(e) {
    FALSE
  })

  expect_true(result, info = "language_handling.R should have valid R syntax")
})

test_that("P3 - event_bus_setup functions are syntactically correct", {
  file_path <- file.path(project_root, "server/event_bus_setup.R")
  skip_if_not(file.exists(file_path), "event_bus_setup.R not found")

  # Try to parse the file - will error if syntax is invalid
  result <- tryCatch({
    parse(file_path)
    TRUE
  }, error = function(e) {
    FALSE
  })

  expect_true(result, info = "event_bus_setup.R should have valid R syntax")
})

# lazy_loading syntax test removed - file no longer exists (modules are eagerly loaded)

# ============================================================================
# Event Bus Functional Tests
# ============================================================================

# server/event_bus_setup.R is not in global.R's chain, so load it here. These
# tests used to skip when it was absent, which meant they never ran.
source_for_test("server/event_bus_setup.R")

test_that("P3 - Event bus can be created and used", {

  # Create event bus
  event_bus <- create_event_bus(session_id = "test_session")

  # Verify structure - basic requirements for any event bus implementation
  expect_true(is.list(event_bus), info = "Event bus should be a list")
  expect_true("emit_isa_change" %in% names(event_bus),
              info = "Should have emit_isa_change")

  # Check for at least one of the CLD-related functions
  # (different implementations may use different names)
  has_cld_function <- "emit_cld_update" %in% names(event_bus) ||
                      "emit_cld_change" %in% names(event_bus) ||
                      "cld_changed" %in% names(event_bus)
  expect_true(has_cld_function,
              info = "Should have some CLD-related function")
})

test_that("P3 - is_event_bus correctly identifies event bus (if available)", {
  # This function is in the new event_bus_setup.R, may not be loaded
  # if the old reactive_pipeline.R is used

  event_bus <- create_event_bus()

  expect_true(is_event_bus(event_bus))
  expect_false(is_event_bus(list()))
  expect_false(is_event_bus(NULL))
  expect_false(is_event_bus("not an event bus"))
})

# (Lazy-loading registry and ML feature-cache tests removed 2026-10-11: those
#  functions no longer exist anywhere in the app -- lazy_loading.R was removed,
#  see the test above -- so the tests could only ever skip.)

# ============================================================================
# Integration Tests
# ============================================================================

test_that("P3 - All P3 files are valid R code", {
  # (server/session_management.R was deleted in N70; leaving it here made the
  #  skip below abort the whole loop, so the other files were never parsed)
  p3_files <- c(
    "server/language_handling.R",
    "server/event_bus_setup.R"
  )

  for (rel_path in p3_files) {
    file_path <- file.path(project_root, rel_path)
    expect_true(file.exists(file_path), info = rel_path)

    result <- tryCatch({
      parse(file_path)
      TRUE
    }, error = function(e) {
      message(sprintf("Parse error in %s: %s", rel_path, e$message))
      FALSE
    })

    expect_true(result, info = sprintf("%s should parse without errors", rel_path))
  }
})

