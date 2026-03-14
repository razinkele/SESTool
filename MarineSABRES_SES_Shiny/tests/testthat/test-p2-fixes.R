# tests/testthat/test-p2-fixes.R
# ============================================================================
# P2 (Medium Priority) Fix Tests
#
# This file validates the P2 fixes implemented from IMPROVEMENT_PLAN.md:
# - Issue #9: i18n System Cleanup (9 languages standardization)
# - Issue #10: Module Signature Standardization
# - Issue #11: Testing Infrastructure Gaps (module integration)
# - Issue #12: Deep Reactive Value Nesting (data accessors)
# ============================================================================

# Helper to get project root path - use PROJECT_ROOT if available
project_root <- if (exists("PROJECT_ROOT") && !is.null(PROJECT_ROOT)) {
  PROJECT_ROOT
} else {
  # Fallback: navigate from testthat directory
  test_dir <- getwd()
  if (grepl("testthat$", test_dir)) {
    normalizePath(file.path(test_dir, "..", ".."), mustWork = FALSE)
  } else {
    test_dir
  }
}

# ============================================================================
# Issue #9: i18n System - 9 Languages Support
# ============================================================================

context("P2 Fixes: i18n System Cleanup")

test_that("translation directories exist", {
  dirs <- c("translations/common", "translations/modules", "translations/ui")
  for (d in dirs) {
    full_path <- file.path(project_root, d)
    expect_true(dir.exists(full_path), info = sprintf("%s should exist", d))
  }
})

test_that("common labels translation file exists with required keys", {
  labels_file <- file.path(project_root, "translations/common/labels.json")
  skip_if(!file.exists(labels_file), "labels.json not found")

  content <- jsonlite::fromJSON(labels_file, simplifyVector = FALSE)

  # The JSON structure has translations under a "translation" key
  translations <- if ("translation" %in% names(content)) content$translation else content

  # Check that some translation keys exist (using actual keys from the file)
  required_keys <- c("Activities", "Drivers", "Pressures")

  for (key in required_keys) {
    expect_true(
      key %in% names(translations),
      info = sprintf("Translation key '%s' should exist in labels.json", key)
    )

    # Check the key has at least English translation
    if (key %in% names(translations)) {
      expect_true(
        "en" %in% names(translations[[key]]),
        info = sprintf("Key '%s' should have English (en) translation", key)
      )
    }
  }

  # Also verify the common.labels.error key we added exists
  expect_true(
    "common.labels.error" %in% names(translations),
    info = "common.labels.error should exist in labels.json"
  )
})

# ============================================================================
# Issue #10: Module Signature Standardization
# ============================================================================

context("P2 Fixes: Module Signature Standardization")

test_that("module signature standard document exists", {
  standard_file <- file.path(project_root, "docs/MODULE_SIGNATURE_STANDARD.md")
  expect_true(file.exists(standard_file), info = "MODULE_SIGNATURE_STANDARD.md should exist")

  content <- readLines(standard_file, warn = FALSE)
  content_text <- paste(content, collapse = "\n")

  # Check key content exists
  expect_true(grepl("project_data_reactive", content_text),
              info = "Standard should document project_data_reactive parameter")
  expect_true(grepl("i18n", content_text),
              info = "Standard should document i18n parameter")
})

test_that("module signature validation script exists", {
  script_file <- file.path(project_root, "scripts/validate_module_signatures.R")
  expect_true(file.exists(script_file), info = "validate_module_signatures.R should exist")

  content <- readLines(script_file, warn = FALSE)
  content_text <- paste(content, collapse = "\n")

  expect_true(grepl("validate_module_signatures", content_text),
              info = "Script should define validate_module_signatures function")
})

# ============================================================================
# Issue #12: Data Accessor Functions
# ============================================================================

context("P2 Fixes: Data Accessor Functions")

test_that("data accessor file exists", {
  accessor_file <- file.path(project_root, "functions/data_accessors.R")
  expect_true(file.exists(accessor_file), info = "data_accessors.R should exist")

  content <- readLines(accessor_file, warn = FALSE)
  content_text <- paste(content, collapse = "\n")

  # Check key functions are defined
  expect_true(grepl("get_isa_data\\s*<-\\s*function", content_text),
              info = "get_isa_data function should be defined")
  expect_true(grepl("get_isa_elements\\s*<-\\s*function", content_text),
              info = "get_isa_elements function should be defined")
  expect_true(grepl("get_project_summary\\s*<-\\s*function", content_text),
              info = "get_project_summary function should be defined")
})

test_that("get_isa_data function works correctly", {
  skip_if_not(exists("get_isa_data", mode = "function"),
              "get_isa_data not available")

  # Test with nested project structure
  project_data <- list(
    data = list(
      isa_data = list(
        drivers = data.frame(id = "d1", name = "Test"),
        activities = data.frame(id = "a1", name = "Test")
      )
    )
  )

  result <- get_isa_data(project_data)

  expect_true(!is.null(result))
  expect_true("drivers" %in% names(result))
  expect_true("activities" %in% names(result))
})

test_that("get_isa_elements function works correctly", {
  skip_if_not(exists("get_isa_elements", mode = "function"),
              "get_isa_elements not available")

  project_data <- list(
    data = list(
      isa_data = list(
        drivers = data.frame(id = "d1", name = "Driver1"),
        activities = data.frame(id = "a1", name = "Activity1")
      )
    )
  )

  drivers <- get_isa_elements(project_data, "drivers")
  expect_true(is.data.frame(drivers))
  expect_equal(nrow(drivers), 1)
  expect_equal(drivers$id[1], "d1")
})

test_that("get_project_summary function works correctly", {
  skip_if_not(exists("get_project_summary", mode = "function"),
              "get_project_summary not available")

  project_data <- list(
    data = list(
      isa_data = list(
        drivers = data.frame(id = "d1", name = "Driver1"),
        activities = data.frame(id = "a1", name = "Activity1"),
        pressures = data.frame(id = character(0), name = character(0)),
        marine_processes = data.frame(id = character(0), name = character(0)),
        ecosystem_services = data.frame(id = character(0), name = character(0)),
        goods_benefits = data.frame(id = character(0), name = character(0)),
        adjacency_matrices = list(
          d_a = matrix(1, nrow = 1, ncol = 1, dimnames = list("d1", "a1"))
        )
      )
    ),
    metadata = list(project_name = "Test Project")
  )

  summary <- get_project_summary(project_data)

  expect_true(is.list(summary))
  expect_equal(summary$total_elements, 2)
  expect_equal(summary$total_connections, 1)
  expect_true("element_counts" %in% names(summary))
})

test_that("safe_get_nested handles missing paths gracefully", {
  skip_if_not(exists("safe_get_nested", mode = "function"),
              "safe_get_nested not available")

  data <- list(a = list(b = list(c = "value")))

  # Valid path
  expect_equal(safe_get_nested(data, "a", "b", "c"), "value")

  # Invalid path returns default
  expect_null(safe_get_nested(data, "a", "x", "y"))
  expect_equal(safe_get_nested(data, "a", "x", "y", default = "fallback"), "fallback")
})

# ============================================================================
# Issue #11: Testing Infrastructure - Module Integration
# ============================================================================

context("P2 Fixes: Testing Infrastructure")

test_that("module integration test file exists", {
  test_file <- file.path(project_root, "tests/testthat/test-module-integration.R")
  expect_true(file.exists(test_file), info = "test-module-integration.R should exist")

  content <- readLines(test_file, warn = FALSE)
  content_text <- paste(content, collapse = "\n")

  # Check key test contexts exist
  expect_true(grepl("ISA.*CLD|CLD.*ISA", content_text, ignore.case = TRUE),
              info = "Integration tests should cover ISA-CLD data flow")
  expect_true(grepl("Event Bus|event_bus", content_text, ignore.case = TRUE),
              info = "Integration tests should cover event bus")
})

# ============================================================================
# Cross-cutting Concerns
# ============================================================================

context("P2 Fixes: Cross-cutting Validation")

test_that("global.R sources data_accessors.R", {
  global_file <- file.path(project_root, "global.R")
  expect_true(file.exists(global_file))

  content <- readLines(global_file, warn = FALSE)
  content_text <- paste(content, collapse = "\n")

  expect_true(
    grepl("data_accessors\\.R", content_text),
    info = "global.R should source data_accessors.R"
  )
})

test_that("CLAUDE.md exists and documents i18n", {
  claude_file <- file.path(project_root, "CLAUDE.md")
  skip_if(!file.exists(claude_file), "CLAUDE.md not found")

  content <- readLines(claude_file, warn = FALSE)
  content_text <- paste(content, collapse = "\n")

  # Should mention supported languages
  expect_true(
    grepl("i18n|[Ll]anguage", content_text),
    info = "CLAUDE.md should document i18n/language support"
  )
})

# ============================================================================
# Summary Test
# ============================================================================

context("P2 Fixes: Summary")

test_that("all P2 fix components are in place", {
  components <- c(
    "Data accessors" = file.exists(file.path(project_root, "functions/data_accessors.R")),
    "Module standard" = file.exists(file.path(project_root, "docs/MODULE_SIGNATURE_STANDARD.md")),
    "Validation script" = file.exists(file.path(project_root, "scripts/validate_module_signatures.R")),
    "Integration tests" = file.exists(file.path(project_root, "tests/testthat/test-module-integration.R")),
    "Translation common" = dir.exists(file.path(project_root, "translations/common"))
  )

  # All components should exist
  for (name in names(components)) {
    expect_true(components[[name]], info = sprintf("%s should exist", name))
  }

  # Summary
  complete_count <- sum(components)
  total_count <- length(components)

  expect_equal(complete_count, total_count,
               info = sprintf("P2 components: %d/%d complete", complete_count, total_count))
})
