#!/usr/bin/env Rscript
# Validation script for pure modular translation system

suppressPackageStartupMessages({
  library(shiny)
  library(shiny.i18n)
  library(jsonlite)
})

cat(strrep("=", 70), "\n")
cat("Pure Modular Translation System Validation\n")
cat(strrep("=", 70), "\n\n")

# Source translation system
source("functions/translation_loader.R")

cat("[1/6] Testing translation system initialization...\n")
translation_file <- tryCatch({
  init_modular_translations(
    base_path = "translations",
    validate = TRUE,
    debug = FALSE,
    persistent = TRUE,
    enforce_namespaced = TRUE
  )
}, error = function(e) {
  cat("✗ FAILED:", e$message, "\n")
  quit(status = 1)
})

if (!file.exists(translation_file)) {
  cat("✗ FAILED: Translation file not created\n")
  quit(status = 1)
}

cat("✓ Translation file created:", translation_file, "\n")
cat("  Size:", round(file.info(translation_file)$size / 1024, 1), "KB\n\n")

cat("[2/6] Testing Translator initialization...\n")
i18n <- tryCatch({
  Translator$new(translation_json_path = translation_file)
}, error = function(e) {
  cat("✗ FAILED:", e$message, "\n")
  quit(status = 1)
})

cat("✓ Translator initialized successfully\n\n")

cat("[3/6] Testing sample namespaced keys...\n")
test_keys <- list(
  list(key = "common.buttons.close", expected = "Close"),
  list(key = "common.buttons.save", expected = "Save"),
  list(key = "ui.sidebar.getting_started", expected_pattern = "Getting|started"),
  list(key = "ui.sidebar.dashboard", expected_pattern = "Dashboard|Panel"),
  list(key = "modules.isa.data_entry.ex1", expected_pattern = ".*")  # Any ISA key
)

passed <- 0
failed <- 0

for (test in test_keys) {
  result <- i18n$t(test$key)

  # Check if it returned the key itself (translation failed)
  if (result == test$key) {
    cat(sprintf("✗ Key '%s': returned key itself (not translated)\n", test$key))
    failed <- failed + 1
  } else if (nchar(result) == 0) {
    cat(sprintf("✗ Key '%s': empty result\n", test$key))
    failed <- failed + 1
  } else {
    cat(sprintf("✓ Key '%s' → '%s'\n", test$key, substr(result, 1, 50)))
    passed <- passed + 1
  }
}

cat(sprintf("\nResults: %d passed, %d failed\n\n", passed, failed))

if (failed > 0) {
  cat("⚠ Some translations not working\n\n")
}

cat("[4/6] Testing all 7 languages...\n")
langs <- c("en", "es", "fr", "de", "lt", "pt", "it")
test_key <- "common.buttons.close"

results <- list()
for (lang in langs) {
  i18n$set_translation_language(lang)
  results[[lang]] <- i18n$t(test_key)
  cat(sprintf("  %s: %s\n", lang, results[[lang]]))
}

# Check if all languages returned different text (proper translations)
unique_results <- length(unique(unlist(results)))
if (unique_results >= 5) {  # At least 5 different translations
  cat(sprintf("✓ Languages working (%d unique translations)\n\n", unique_results))
} else {
  cat(sprintf("⚠ Only %d unique translations (expected 7)\n\n", unique_results))
}

cat("[5/6] Checking for flat-key entries...\n")
merged <- fromJSON(translation_file)
flat_keys <- 0
namespaced_keys <- 0

for (entry in merged$translation) {
  if (is.null(entry$key)) {
    flat_keys <- flat_keys + 1
  } else if (!grepl("\\.", entry$key)) {
    flat_keys <- flat_keys + 1
  } else {
    namespaced_keys <- namespaced_keys + 1
  }
}

cat(sprintf("  Namespaced keys: %d\n", namespaced_keys))
cat(sprintf("  Flat keys: %d\n", flat_keys))

if (flat_keys == 0) {
  cat("✓ Pure namespaced system (no flat keys)\n\n")
} else {
  cat(sprintf("⚠ Found %d flat-key entries (should be 0)\n\n", flat_keys))
}

cat("[6/6] Performance check...\n")
start_time <- Sys.time()
for (i in 1:1000) {
  i18n$t("common.buttons.close")
}
end_time <- Sys.time()
lookup_time <- as.numeric(end_time - start_time) * 1000 / 1000  # ms per lookup

cat(sprintf("  1000 lookups: %.2f ms (%.3f ms per lookup)\n", lookup_time, lookup_time/1000))

if (lookup_time / 1000 < 1) {
  cat("✓ Performance acceptable (<1ms per lookup)\n\n")
} else {
  cat("⚠ Performance degraded (>1ms per lookup)\n\n")
}

cat(strrep("=", 70), "\n")
cat("VALIDATION SUMMARY\n")
cat(strrep("=", 70), "\n")

all_good <- TRUE

if (passed < length(test_keys)) {
  cat("⚠ Some translation keys not working\n")
  all_good <- FALSE
}

if (unique_results < 5) {
  cat("⚠ Language switching issues detected\n")
  all_good <- FALSE
}

if (flat_keys > 0) {
  cat("⚠ Flat-key entries found (expected 0)\n")
  all_good <- FALSE
}

if (lookup_time / 1000 > 1) {
  cat("⚠ Performance concerns\n")
  all_good <- FALSE
}

if (all_good) {
  cat("\n✅ ALL VALIDATIONS PASSED!\n")
  cat("Pure modular translation system is working correctly.\n\n")
  quit(status = 0)
} else {
  cat("\n⚠ SOME ISSUES FOUND\n")
  cat("Review warnings above.\n\n")
  quit(status = 1)
}
