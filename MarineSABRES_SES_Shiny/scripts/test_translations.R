#!/usr/bin/env Rscript
# scripts/test_translations.R
# Automated testing routine for translations
# Tests the modular translation system end-to-end

# ============================================================================
# SETUP
# ============================================================================

suppressPackageStartupMessages({
  library(jsonlite)
})

test_count <- 0
pass_count <- 0
fail_count <- 0

# ============================================================================
# TEST FRAMEWORK
# ============================================================================

test_that <- function(description, code) {
  test_count <<- test_count + 1
  cat(sprintf("\n[Test %d] %s\n", test_count, description))

  result <- tryCatch({
    code
    TRUE
  }, error = function(e) {
    cat("  ✗ FAIL:", e$message, "\n")
    FALSE
  })

  if (result) {
    cat("  ✓ PASS\n")
    pass_count <<- pass_count + 1
  } else {
    fail_count <<- fail_count + 1
  }

  invisible(result)
}

expect_true <- function(condition, message = "Condition is FALSE") {
  if (!condition) {
    stop(message)
  }
}

expect_equal <- function(actual, expected, message = NULL) {
  if (!identical(actual, expected)) {
    if (is.null(message)) {
      message <- sprintf("Expected '%s', got '%s'", expected, actual)
    }
    stop(message)
  }
}

expect_no_error <- function(code) {
  tryCatch({
    code
  }, error = function(e) {
    stop(paste("Unexpected error:", e$message))
  })
}

# ============================================================================
# TEST SUITE: JSON FILES
# ============================================================================

test_json_files <- function() {
  cat("\n╔═══════════════════════════════════════╗\n")
  cat("║  Test Suite: JSON File Validation    ║\n")
  cat("╚═══════════════════════════════════════╝\n")

  test_that("All JSON files are valid syntax", {
    json_files <- list.files("translations", pattern = "\\.json$",
                            full.names = TRUE, recursive = TRUE)
    json_files <- json_files[!grepl("backup", json_files, ignore.case = TRUE)]

    expect_true(length(json_files) > 0, "No JSON files found")

    for (file in json_files) {
      data <- fromJSON(file, simplifyVector = FALSE)
      expect_true(!is.null(data), paste("Failed to parse", basename(file)))
    }
  })

  test_that("All translation files have required structure", {
    json_files <- list.files("translations", pattern = "\\.json$",
                            full.names = TRUE, recursive = TRUE)
    json_files <- json_files[!grepl("backup", json_files, ignore.case = TRUE)]

    for (file in json_files) {
      data <- fromJSON(file, simplifyVector = FALSE)

      expect_true("languages" %in% names(data),
                 paste(basename(file), "missing 'languages' field"))

      has_content <- ("translation" %in% names(data) &&
                     length(data$translation) > 0) ||
                    ("glossary" %in% names(data) &&
                     length(data$glossary) > 0)

      expect_true(has_content,
                 paste(basename(file), "has no translation or glossary"))
    }
  })

  test_that("All translation entries have all 7 languages", {
    json_files <- list.files("translations", pattern = "\\.json$",
                            full.names = TRUE, recursive = TRUE)
    json_files <- json_files[!grepl("backup", json_files, ignore.case = TRUE)]

    required_langs <- c("en", "es", "fr", "de", "lt", "pt", "it")

    for (file in json_files) {
      data <- fromJSON(file, simplifyVector = FALSE)

      if (!is.null(data$translation)) {
        for (i in seq_along(data$translation)) {
          entry <- data$translation[[i]]

          for (lang in required_langs) {
            expect_true(lang %in% names(entry) && entry[[lang]] != "",
                       paste(basename(file), "entry", i, "missing", lang))
          }
        }
      }
    }
  })
}

# ============================================================================
# TEST SUITE: TRANSLATION LOADER
# ============================================================================

test_translation_loader <- function() {
  cat("\n╔═══════════════════════════════════════╗\n")
  cat("║  Test Suite: Translation Loader      ║\n")
  cat("╚═══════════════════════════════════════╝\n")

  test_that("Translation loader script exists", {
    expect_true(file.exists("functions/translation_loader.R"),
               "translation_loader.R not found")
  })

  test_that("Translation loader can be sourced", {
    expect_no_error({
      source("functions/translation_loader.R")
    })
  })

  test_that("load_translations() function works", {
    source("functions/translation_loader.R")

    result <- load_translations("translations", debug = FALSE)

    expect_true(is.list(result), "Result is not a list")
    expect_true("languages" %in% names(result), "Missing languages field")
    expect_true("translation" %in% names(result), "Missing translation field")
  })

  test_that("Merged translations contain expected number of entries", {
    source("functions/translation_loader.R")

    result <- load_translations("translations", debug = FALSE)

    expect_true(length(result$translation) > 50,
               sprintf("Too few translations: %d", length(result$translation)))
  })

  test_that("init_modular_translations() creates temp file", {
    source("functions/translation_loader.R")

    temp_file <- init_modular_translations("translations", debug = FALSE)

    expect_true(file.exists(temp_file), "Temp file not created")
    expect_true(grepl("\\.json$", temp_file), "Temp file is not JSON")

    # Verify temp file is valid JSON
    data <- fromJSON(temp_file)
    expect_true("languages" %in% names(data))
    expect_true("translation" %in% names(data))

    # Cleanup
    unlink(temp_file)
  })
}

# ============================================================================
# TEST SUITE: TRANSLATION SYSTEM INTEGRATION
# ============================================================================

test_integration <- function() {
  cat("\n╔═══════════════════════════════════════╗\n")
  cat("║  Test Suite: Integration Tests       ║\n")
  cat("╚═══════════════════════════════════════╝\n")

  test_that("shiny.i18n package is available", {
    expect_true(requireNamespace("shiny.i18n", quietly = TRUE),
               "shiny.i18n package not installed")
  })

  test_that("Can initialize Translator with modular translations", {
    source("functions/translation_loader.R")
    library(shiny.i18n)

    temp_file <- init_modular_translations("translations", debug = FALSE)

    translator <- Translator$new(translation_json_path = temp_file)

    expect_true(!is.null(translator), "Translator not created")

    unlink(temp_file)
  })

  test_that("Framework translations are accessible", {
    source("functions/translation_loader.R")
    library(shiny.i18n)

    temp_file <- init_modular_translations("translations", debug = FALSE)
    translator <- Translator$new(translation_json_path = temp_file)

    # Test framework keys
    test_keys <- c(
      "Driver",  # framework.drivers.singular
      "Drivers",  # framework.drivers.plural
      "Pressure",  # framework.pressures.singular
      "Response"  # framework.responses.singular
    )

    for (key in test_keys) {
      translation <- translator$t(key)
      expect_true(!is.null(translation) && translation != "",
                 paste("Cannot translate:", key))
    }

    unlink(temp_file)
  })

  test_that("Common button translations are accessible", {
    source("functions/translation_loader.R")
    library(shiny.i18n)

    temp_file <- init_modular_translations("translations", debug = FALSE)
    translator <- Translator$new(translation_json_path = temp_file)

    # Test common button keys
    test_keys <- c("Save", "Cancel", "Apply", "Close")

    for (key in test_keys) {
      translation <- translator$t(key)
      expect_true(!is.null(translation) && translation != "",
                 paste("Cannot translate:", key))
    }

    unlink(temp_file)
  })

  test_that("Language switching works", {
    source("functions/translation_loader.R")
    library(shiny.i18n)

    temp_file <- init_modular_translations("translations", debug = FALSE)
    translator <- Translator$new(translation_json_path = temp_file)

    # Test in English
    translator$set_translation_language("en")
    en_text <- translator$t("Save")
    expect_equal(en_text, "Save", "English translation incorrect")

    # Test in Spanish
    translator$set_translation_language("es")
    es_text <- translator$t("Save")
    expect_equal(es_text, "Guardar", "Spanish translation incorrect")

    # Test in French
    translator$set_translation_language("fr")
    fr_text <- translator$t("Save")
    expect_equal(fr_text, "Enregistrer", "French translation incorrect")

    unlink(temp_file)
  })

  test_that("Glossary terms are loaded", {
    source("functions/translation_loader.R")

    result <- load_translations("translations", debug = FALSE)

    expect_true("glossary" %in% names(result),
               "Glossary not loaded")
    expect_true(length(result$glossary) > 0,
               "Glossary is empty")
    expect_true("ses" %in% names(result$glossary),
               "SES term not in glossary")
  })
}

# ============================================================================
# TEST SUITE: VALIDATION FUNCTIONS
# ============================================================================

test_validation_functions <- function() {
  cat("\n╔═══════════════════════════════════════╗\n")
  cat("║  Test Suite: Validation Functions    ║\n")
  cat("╚═══════════════════════════════════════╝\n")

  test_that("validate_translations() detects missing translations", {
    source("functions/translation_loader.R")

    # Create test data with missing translation
    test_data <- list(
      languages = c("en", "es", "fr", "de", "lt", "pt", "it"),
      translation = list(
        list(en = "Test", es = "Prueba", fr = "Test", de = "Test",
             lt = "Testas", pt = "Teste", it = ""),  # Missing Italian
        list(en = "Valid", es = "Válido", fr = "Valide", de = "Gültig",
             lt = "Galioja", pt = "Válido", it = "Valido")
      )
    )

    issues <- validate_translations(test_data, debug = FALSE)

    expect_true(length(issues) > 0, "Should detect missing translation")
    expect_true(any(sapply(issues, function(i) i$language == "it")),
               "Should detect missing Italian")
  })

  test_that("get_translation_stats() returns correct structure", {
    source("functions/translation_loader.R")

    result <- load_translations("translations", debug = FALSE)
    stats <- get_translation_stats(result)

    expect_true("total_entries" %in% names(stats))
    expect_true("languages" %in% names(stats))
    expect_true("namespaced_keys" %in% names(stats))
    expect_true("flat_keys" %in% names(stats))

    expect_true(stats$total_entries > 0)
    expect_true(length(stats$languages) == 7)
  })
}

# ============================================================================
# MAIN TEST RUNNER
# ============================================================================

run_all_tests <- function() {
  cat("\n")
  cat("╔═══════════════════════════════════════════════════╗\n")
  cat("║                                                   ║\n")
  cat("║  Translation System - Automated Test Suite       ║\n")
  cat("║                                                   ║\n")
  cat("╚═══════════════════════════════════════════════════╝\n")

  start_time <- Sys.time()

  # Run test suites
  test_json_files()
  test_translation_loader()
  test_integration()
  test_validation_functions()

  # Summary
  end_time <- Sys.time()
  duration <- as.numeric(difftime(end_time, start_time, units = "secs"))

  cat("\n")
  cat("╔═══════════════════════════════════════════════════╗\n")
  cat("║  Test Summary                                     ║\n")
  cat("╚═══════════════════════════════════════════════════╝\n")
  cat(sprintf("\nTotal tests:  %d\n", test_count))
  cat(sprintf("Passed:       %d (%d%%)\n", pass_count,
             round(100 * pass_count / test_count)))
  cat(sprintf("Failed:       %d (%d%%)\n", fail_count,
             round(100 * fail_count / test_count)))
  cat(sprintf("Duration:     %.2f seconds\n", duration))

  if (fail_count == 0) {
    cat("\n✓ ALL TESTS PASSED!\n\n")
    return(invisible(TRUE))
  } else {
    cat(sprintf("\n✗ %d TEST(S) FAILED\n\n", fail_count))
    return(invisible(FALSE))
  }
}

# ============================================================================
# SCRIPT ENTRY POINT
# ============================================================================

# Check required packages
required_packages <- c("jsonlite", "shiny.i18n")
missing_packages <- required_packages[!sapply(required_packages, requireNamespace,
                                              quietly = TRUE)]

if (length(missing_packages) > 0) {
  cat("Missing required packages:", paste(missing_packages, collapse = ", "), "\n")
  cat("Install with: install.packages(c('", paste(missing_packages, collapse = "', '"), "'))\n", sep = "")
  quit(status = 1)
}

# Run tests
result <- run_all_tests()

# Exit with appropriate status
if (result) {
  quit(status = 0)
} else {
  quit(status = 1)
}
