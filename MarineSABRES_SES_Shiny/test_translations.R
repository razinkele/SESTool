#!/usr/bin/env Rscript
# test_translations.R
# Quick test script to verify translation system fixes

cat("==========================================================\n")
cat("TRANSLATION SYSTEM VERIFICATION TEST\n")
cat("==========================================================\n\n")

# Source required files
cat("[1/5] Loading global environment...\n")
suppressPackageStartupMessages({
  library(shiny)
  library(shiny.i18n)
  library(jsonlite)
})

# Source translation loader
cat("[2/5] Loading translation loader...\n")
source("functions/translation_loader.R")

# Test 1: Initialize translation system
cat("[3/5] Testing translation initialization...\n")
translation_file <- init_modular_translations(
  base_path = "translations",
  validate = FALSE,
  debug = TRUE,
  persistent = TRUE
)

if (file.exists(translation_file)) {
  cat(sprintf("✅ Translation file created: %s\n", translation_file))
  file_size <- file.info(translation_file)$size
  cat(sprintf("   File size: %s bytes\n", format(file_size, big.mark = ",")))
} else {
  cat("❌ FAILED: Translation file not created\n")
  quit(status = 1)
}

# Test 2: Initialize translator
cat("[4/5] Testing translator initialization...\n")
tryCatch({
  i18n <- Translator$new(translation_json_path = translation_file)
  cat("✅ Translator initialized successfully\n")
}, error = function(e) {
  cat(sprintf("❌ FAILED: %s\n", e$message))
  quit(status = 1)
})

# Test 3: Test flat-key translations
cat("[5/5] Testing flat-key translations...\n")
test_keys <- c(
  "Getting Started",
  "Dashboard",
  "PIMS Module",
  "Create SES",
  "Analysis Tools",
  "Save Project",
  "Load Project",
  "Close",
  "Cancel"
)

results <- data.frame(
  Key = character(),
  EN = character(),
  ES = character(),
  FR = character(),
  Status = character(),
  stringsAsFactors = FALSE
)

for (key in test_keys) {
  i18n$set_translation_language("en")
  en_text <- i18n$t(key)

  i18n$set_translation_language("es")
  es_text <- i18n$t(key)

  i18n$set_translation_language("fr")
  fr_text <- i18n$t(key)

  # Check if translation worked
  # For flat keys, en_text may equal key (English is the key)
  # So we check if Spanish or French is different (translated)
  status <- if (es_text != en_text || fr_text != en_text) {
    "✅ OK"
  } else {
    "❌ FAIL"
  }

  results <- rbind(results, data.frame(
    Key = substr(key, 1, 20),
    EN = substr(en_text, 1, 20),
    ES = substr(es_text, 1, 20),
    FR = substr(fr_text, 1, 20),
    Status = status,
    stringsAsFactors = FALSE
  ))
}

cat("\nTranslation Test Results:\n")
cat("-------------------------\n")
print(results, row.names = FALSE)

# Summary
successful <- sum(results$Status == "✅ OK")
total <- nrow(results)
cat(sprintf("\nSummary: %d/%d translations working (%.0f%%)\n",
            successful, total, (successful/total)*100))

if (successful == total) {
  cat("\n✅ ALL TESTS PASSED!\n")
  cat("==========================================================\n")
  cat("Translation system is working correctly.\n")
  cat("You can now start the Shiny app.\n")
  cat("==========================================================\n")
} else {
  cat("\n❌ SOME TESTS FAILED!\n")
  cat("==========================================================\n")
  cat("Please check the translation files.\n")
  cat("==========================================================\n")
  quit(status = 1)
}
