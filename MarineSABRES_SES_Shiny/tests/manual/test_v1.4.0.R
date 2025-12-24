# test_v1.4.0.R
# Automated validation tests for MarineSABRES v1.4.0

cat("\n")
cat("═══════════════════════════════════════════════════════════\n")
cat("  MarineSABRES v1.4.0 - Automated Test Suite\n")
cat("  Date:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n")
cat("═══════════════════════════════════════════════════════════\n\n")

# Test results tracker
tests_passed <- 0
tests_failed <- 0
failed_tests <- character()

# Helper function to run test
run_test <- function(test_name, test_expr) {
  cat(sprintf("Testing: %s ... ", test_name))
  result <- tryCatch({
    test_expr
    TRUE
  }, error = function(e) {
    message(sprintf("\n  ERROR: %s", e$message))
    FALSE
  })

  if (result) {
    cat("✓ PASS\n")
    tests_passed <<- tests_passed + 1
  } else {
    cat("✗ FAIL\n")
    tests_failed <<- tests_failed + 1
    failed_tests <<- c(failed_tests, test_name)
  }
  return(result)
}

# ============================================================================
# TEST CATEGORY 1: File Existence
# ============================================================================

cat("\n[Category 1] File Existence Tests\n")
cat("──────────────────────────────────────────────────────────\n")

run_test("Auto-save module exists", {
  if (!file.exists("modules/auto_save_module.R")) {
    stop("modules/auto_save_module.R not found")
  }
})

run_test("Navigation helpers exist", {
  if (!file.exists("modules/navigation_helpers.R")) {
    stop("modules/navigation_helpers.R not found")
  }
})

run_test("Bookmarking documentation exists", {
  if (!file.exists("BOOKMARKING_FEATURE.md")) {
    stop("BOOKMARKING_FEATURE.md not found")
  }
})

run_test("Compatibility analysis exists", {
  if (!file.exists("BOOKMARKING_AUTOSAVE_COMPATIBILITY.md")) {
    stop("BOOKMARKING_AUTOSAVE_COMPATIBILITY.md not found")
  }
})

run_test("Testing framework exists", {
  if (!file.exists("TESTING_FRAMEWORK_V1.4.0.md")) {
    stop("TESTING_FRAMEWORK_V1.4.0.md not found")
  }
})

# ============================================================================
# TEST CATEGORY 2: Module Loading
# ============================================================================

cat("\n[Category 2] Module Loading Tests\n")
cat("──────────────────────────────────────────────────────────\n")

run_test("Auto-save module loads", {
  source("modules/auto_save_module.R", local = TRUE)
  if (!exists("auto_save_server")) {
    stop("auto_save_server function not found")
  }
  if (!exists("auto_save_indicator_ui")) {
    stop("auto_save_indicator_ui function not found")
  }
})

run_test("Navigation helpers load", {
  source("modules/navigation_helpers.R", local = TRUE)
  required_functions <- c("create_breadcrumb", "create_progress_bar",
                          "create_nav_buttons", "create_step_indicator",
                          "mark_as_recommended", "add_start_here_badge")
  for (func in required_functions) {
    if (!exists(func)) {
      stop(sprintf("%s function not found", func))
    }
  }
})

# ============================================================================
# TEST CATEGORY 3: Configuration Checks
# ============================================================================

cat("\n[Category 3] Configuration Tests\n")
cat("──────────────────────────────────────────────────────────\n")

run_test("Bookmarking enabled in global.R", {
  global_content <- readLines("global.R")
  if (!any(grepl("enableBookmarking", global_content))) {
    stop("enableBookmarking not found in global.R")
  }
})

run_test("Bookmark button in app.R", {
  app_content <- readLines("app.R")
  if (!any(grepl("bookmark_btn", app_content))) {
    stop("bookmark_btn not found in app.R")
  }
})

run_test("Bookmark handlers in app.R", {
  app_content <- readLines("app.R")
  has_onbookmark <- any(grepl("onBookmark", app_content))
  has_onrestore <- any(grepl("onRestore", app_content))
  if (!has_onbookmark || !has_onrestore) {
    stop("Bookmark handlers (onBookmark/onRestore) not found")
  }
})

run_test("setBookmarkExclude configured", {
  app_content <- readLines("app.R")
  if (!any(grepl("setBookmarkExclude", app_content))) {
    stop("setBookmarkExclude not found in app.R")
  }
})

# ============================================================================
# TEST CATEGORY 4: Translation Checks
# ============================================================================

cat("\n[Category 4] Translation Tests\n")
cat("──────────────────────────────────────────────────────────\n")

run_test("Translation file is valid JSON", {
  translations <- jsonlite::fromJSON("translations/translation.json")
  if (is.null(translations)) {
    stop("Failed to parse translation.json")
  }
})

run_test("Bookmarking translations exist", {
  translations <- jsonlite::fromJSON("translations/translation.json")
  trans_df <- as.data.frame(translations$translation)

  bookmark_keys <- c("Bookmark", "Bookmark Created", "Copied!",
                     "Bookmark restored successfully!")
  missing_keys <- character()

  for (key in bookmark_keys) {
    if (!any(trans_df$en == key)) {
      missing_keys <- c(missing_keys, key)
    }
  }

  if (length(missing_keys) > 0) {
    stop(sprintf("Missing translation keys: %s",
                paste(missing_keys, collapse = ", ")))
  }
})

run_test("All 7 languages supported", {
  translations <- jsonlite::fromJSON("translations/translation.json")
  required_languages <- c("en", "es", "fr", "de", "lt", "pt", "it")

  if (!all(required_languages %in% translations$languages)) {
    stop("Not all 7 languages found in translation file")
  }
})

# ============================================================================
# TEST CATEGORY 5: CSS Styling
# ============================================================================

cat("\n[Category 5] CSS Styling Tests\n")
cat("──────────────────────────────────────────────────────────\n")

run_test("Bookmark CSS styling exists", {
  css_content <- readLines("www/custom.css")
  if (!any(grepl("#bookmark_btn", css_content))) {
    stop("Bookmark button styling not found in custom.css")
  }
})

run_test("Bookmark animation exists", {
  css_content <- readLines("www/custom.css")
  if (!any(grepl("bookmark-pulse", css_content))) {
    stop("Bookmark pulse animation not found in custom.css")
  }
})

run_test("Navigation CSS exists", {
  css_content <- readLines("www/custom.css")
  has_breadcrumb <- any(grepl("breadcrumb", css_content, ignore.case = TRUE))
  has_progress <- any(grepl("progress-bar", css_content, ignore.case = TRUE))

  if (!has_breadcrumb || !has_progress) {
    stop("Navigation CSS (breadcrumb/progress-bar) not found")
  }
})

# ============================================================================
# TEST CATEGORY 6: Code Quality
# ============================================================================

cat("\n[Category 6] Code Quality Tests\n")
cat("──────────────────────────────────────────────────────────\n")

run_test("No syntax errors in app.R", {
  tryCatch({
    parse("app.R")
  }, error = function(e) {
    stop(sprintf("Syntax error in app.R: %s", e$message))
  })
})

run_test("No syntax errors in global.R", {
  tryCatch({
    parse("global.R")
  }, error = function(e) {
    stop(sprintf("Syntax error in global.R: %s", e$message))
  })
})

run_test("AI Assistant module has workflow steps", {
  ai_content <- readLines("modules/ai_isa_assistant_module.R")
  # Check for workflow indicators - module uses numeric progress (1-11)
  # Look for evidence of multi-step workflow
  has_workflow <- any(grepl("current_step|step_count|total_steps", ai_content, ignore.case = TRUE)) ||
                  any(grepl("step.*11|11.*step", ai_content, ignore.case = TRUE))

  if (!has_workflow) {
    stop("AI Assistant does not appear to have multi-step workflow")
  }
})

# ============================================================================
# TEST CATEGORY 7: Version Info
# ============================================================================

cat("\n[Category 7] Version Information Tests\n")
cat("──────────────────────────────────────────────────────────\n")

run_test("VERSION_INFO.json exists and is valid", {
  if (!file.exists("VERSION_INFO.json")) {
    stop("VERSION_INFO.json not found")
  }
  version_info <- jsonlite::fromJSON("VERSION_INFO.json")
  if (is.null(version_info$version)) {
    stop("Version info missing version field")
  }
})

run_test("Completion status updated", {
  if (!file.exists("V1.4.0_COMPLETION_STATUS.md")) {
    stop("V1.4.0_COMPLETION_STATUS.md not found")
  }
  status_content <- readLines("V1.4.0_COMPLETION_STATUS.md")
  # Check for bookmarking mention
  if (!any(grepl("bookmarking", status_content, ignore.case = TRUE))) {
    warning("Bookmarking not mentioned in completion status")
  }
})

# ============================================================================
# RESULTS SUMMARY
# ============================================================================

cat("\n")
cat("═══════════════════════════════════════════════════════════\n")
cat("  TEST RESULTS SUMMARY\n")
cat("═══════════════════════════════════════════════════════════\n")
cat(sprintf("Total Tests:  %d\n", tests_passed + tests_failed))
cat(sprintf("Passed:       %d (%.1f%%)\n", tests_passed,
            100 * tests_passed / (tests_passed + tests_failed)))
cat(sprintf("Failed:       %d (%.1f%%)\n", tests_failed,
            100 * tests_failed / (tests_passed + tests_failed)))

if (tests_failed > 0) {
  cat("\n")
  cat("Failed Tests:\n")
  for (test in failed_tests) {
    cat(sprintf("  ✗ %s\n", test))
  }
  cat("\n")
  cat("STATUS: ⚠ ISSUES DETECTED - Review failed tests\n")
} else {
  cat("\n")
  cat("STATUS: ✓ ALL TESTS PASSED - Ready for manual testing\n")
}

cat("═══════════════════════════════════════════════════════════\n\n")

# Return status code
if (tests_failed > 0) {
  quit(status = 1)
} else {
  quit(status = 0)
}
