#!/usr/bin/env Rscript
# Validation script for translation wrapper system

suppressPackageStartupMessages({
  library(shiny)
  library(shiny.i18n)
  library(jsonlite)
})

cat(strrep("=", 70), "\n")
cat("Translation Wrapper System Validation\n")
cat(strrep("=", 70), "\n\n")

# Source translation system
source("functions/translation_loader.R")

cat("[1/7] Initializing translation system with wrapper...\n")
system <- tryCatch({
  init_translation_system(
    base_path = "translations",
    mapping_path = "scripts/reverse_key_mapping.json",
    validate = TRUE,
    debug = FALSE,
    persistent = TRUE
  )
}, error = function(e) {
  cat("✗ FAILED:", e$message, "\n")
  quit(status = 1)
})

cat("✓ Translation system initialized\n")
cat("  Translator: ", class(system$translator)[1], "\n")
cat("  Wrapper: ", class(system$wrapper)[1], "\n")
cat("  File: ", basename(system$file), "\n\n")

cat("[2/7] Testing namespaced key lookups...\n")
test_keys <- list(
  list(key = "common.buttons.close", expected = "Close"),
  list(key = "common.buttons.add", expected = "Add"),
  list(key = "common.buttons.back", expected = "Back"),
  list(key = "ui.sidebar.getting_started", expected = "Getting Started"),
  list(key = "ui.sidebar.dashboard", expected = "Dashboard")
)

passed <- 0
failed <- 0

for (test in test_keys) {
  result <- system$wrapper(test$key)

  # Check if it returned the key itself (translation failed)
  if (result == test$key) {
    cat(sprintf("✗ Key '%s': returned key itself (not translated)\n", test$key))
    failed <- failed + 1
  } else if (nchar(result) == 0) {
    cat(sprintf("✗ Key '%s': empty result\n", test$key))
    failed <- failed + 1
  } else if (!is.null(test$expected) && result != test$expected) {
    cat(sprintf("✗ Key '%s': expected '%s', got '%s'\n", test$key, test$expected, result))
    failed <- failed + 1
  } else if (!is.null(test$expected_pattern) && !grepl(test$expected_pattern, result, ignore.case = TRUE)) {
    cat(sprintf("✗ Key '%s': doesn't match pattern '%s', got '%s'\n", test$key, test$expected_pattern, result))
    failed <- failed + 1
  } else {
    cat(sprintf("✓ Key '%s' → '%s'\n", test$key, result))
    passed <- passed + 1
  }
}

cat(sprintf("\nResults: %d passed, %d failed\n\n", passed, failed))

if (failed > 0) {
  cat("✗ Some translations not working\n\n")
}

cat("[3/7] Testing all 7 languages...\n")
langs <- c("en", "es", "fr", "de", "lt", "pt", "it")
test_key <- "common.buttons.close"

results <- list()
for (lang in langs) {
  system$translator$set_translation_language(lang)
  results[[lang]] <- system$wrapper(test_key)
  cat(sprintf("  %s: %s\n", lang, results[[lang]]))
}

# Check if all languages returned different text (proper translations)
unique_results <- length(unique(unlist(results)))
if (unique_results >= 5) {  # At least 5 different translations
  cat(sprintf("✓ Languages working (%d unique translations)\n\n", unique_results))
} else {
  cat(sprintf("⚠ Only %d unique translations (expected 7)\n\n", unique_results))
}

cat("[4/7] Testing wrapper performance (caching)...\n")
start_time <- Sys.time()
for (i in 1:1000) {
  system$wrapper("common.buttons.close")
}
end_time <- Sys.time()
lookup_time <- as.numeric(end_time - start_time) * 1000  # ms total

cat(sprintf("  1000 lookups: %.2f ms (%.3f ms per lookup)\n", lookup_time, lookup_time/1000))

if (lookup_time / 1000 < 1) {
  cat("✓ Performance excellent (<1ms per lookup)\n\n")
} else {
  cat("⚠ Performance degraded (>1ms per lookup)\n\n")
}

cat("[5/7] Testing fallback for missing keys...\n")
missing_key <- "nonexistent.key.that.does.not.exist"
result <- system$wrapper(missing_key)

if (result == missing_key) {
  cat(sprintf("✓ Missing key fallback works: '%s' → '%s'\n\n", missing_key, result))
} else {
  cat(sprintf("✗ Missing key returned unexpected: '%s'\n\n", result))
}

cat("[6/7] Checking reverse mapping coverage...\n")
reverse_mapping <- fromJSON("scripts/reverse_key_mapping.json")
cat(sprintf("  Reverse mapping entries: %d\n", length(reverse_mapping)))

# Sample some ISA keys
isa_keys <- names(reverse_mapping)[grepl("^modules\\.isa\\.", names(reverse_mapping))]
cat(sprintf("  ISA module keys: %d\n", length(isa_keys)))

# Test a few ISA keys
if (length(isa_keys) > 0) {
  sample_isa <- head(isa_keys, 3)
  isa_passed <- 0
  for (key in sample_isa) {
    result <- system$wrapper(key)
    if (result != key && nchar(result) > 0) {
      isa_passed <- isa_passed + 1
    }
  }
  cat(sprintf("  ISA key tests: %d/%d passed\n", isa_passed, length(sample_isa)))
}

cat("\n")

cat("[7/7] Verifying translation file structure...\n")
merged <- fromJSON(system$file, simplifyVector = FALSE)

# Check that we're using English text as keys (shiny.i18n requirement)
sample_entries <- head(merged$translation, 5)
has_key_field <- all(sapply(sample_entries, function(e) {
  if (is.list(e)) !is.null(e$key) else FALSE
}))
has_en_field <- all(sapply(sample_entries, function(e) {
  if (is.list(e)) !is.null(e$en) else FALSE
}))

cat(sprintf("  Has 'key' field: %s\n", has_key_field))
cat(sprintf("  Has 'en' field: %s\n", has_en_field))
cat(sprintf("  Total entries: %d\n", length(merged$translation)))
cat(sprintf("  Languages: %s\n", paste(merged$languages, collapse = ", ")))

cat("\n")

cat(strrep("=", 70), "\n")
cat("VALIDATION SUMMARY\n")
cat(strrep("=", 70), "\n")

all_good <- TRUE

if (passed < length(test_keys)) {
  cat("✗ Some translation keys not working\n")
  all_good <- FALSE
}

if (unique_results < 5) {
  cat("✗ Language switching issues detected\n")
  all_good <- FALSE
}

if (lookup_time / 1000 > 5) {
  cat("⚠ Performance concerns (>5ms per lookup)\n")
  all_good <- FALSE
}

if (all_good) {
  cat("\n✅ ALL VALIDATIONS PASSED!\n")
  cat("Translation wrapper system is working correctly.\n")
  cat("\nUsage in R code:\n")
  cat("  # Access wrapper function:\n")
  cat("  translation_system$wrapper(\"common.buttons.close\")\n")
  cat("  \n")
  cat("  # Switch language:\n")
  cat("  translation_system$translator$set_translation_language(\"es\")\n")
  cat("\n")
  quit(status = 0)
} else {
  cat("\n⚠ SOME ISSUES FOUND\n")
  cat("Review warnings above.\n\n")
  quit(status = 1)
}
