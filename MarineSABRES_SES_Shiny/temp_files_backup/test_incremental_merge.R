#!/usr/bin/env Rscript
# Test adding AI ISA translations incrementally to find problematic entries

library(jsonlite)
library(shiny.i18n)

cat("Loading working backup...\n")
base <- fromJSON('translations/translation_backup_20251103_232419.json', simplifyDataFrame = FALSE)
cat("  Loaded", length(base$translation), "entries\n")

cat("\nLoading Python translations...\n")
python_trans <- fromJSON('ai_isa_assistant_translations.json', simplifyDataFrame = FALSE)
cat("  Loaded", length(python_trans$translation), "entries\n")

# Get English keys from base for duplicate checking
base_en <- sapply(base$translation, function(x) x$en)

# Filter for unique entries
unique_entries <- Filter(function(x) !(x$en %in% base_en), python_trans$translation)
cat("\nUnique entries to add:", length(unique_entries), "\n")

# Test adding entries in batches
batch_size <- 10
successful_entries <- list()
failed_entry_idx <- NULL

for (i in seq_along(unique_entries)) {
  entry <- unique_entries[[i]]

  cat(sprintf("\n[%d/%d] Testing: %s\n", i, length(unique_entries), substr(entry$en, 1, 60)))

  # Create test file with base + entries so far
  test_trans <- list(translation = c(base$translation, successful_entries, list(entry)))

  # Save to temp file
  temp_file <- 'temp_test_translation.json'
  write_json(test_trans, temp_file, pretty = TRUE, auto_unbox = TRUE)

  # Try to load in shiny.i18n
  load_success <- tryCatch({
    test_i18n <- Translator$new(translation_json_path = temp_file)
    test_i18n$set_translation_language("en")
    TRUE
  }, error = function(e) {
    cat("  ✗ FAILED:", conditionMessage(e), "\n")
    FALSE
  })

  if (load_success) {
    cat("  ✓ Success!\n")
    successful_entries[[length(successful_entries) + 1]] <- entry
  } else {
    cat("\n=== FOUND PROBLEMATIC ENTRY ===\n")
    cat("English:", entry$en, "\n")
    cat("Spanish:", entry$es, "\n")
    cat("Structure:\n")
    str(entry)
    failed_entry_idx <- i
    break
  }
}

# Clean up
if (file.exists('temp_test_translation.json')) {
  file.remove('temp_test_translation.json')
}

if (is.null(failed_entry_idx)) {
  cat("\n✓ All entries loaded successfully!\n")
  cat("  Total successful entries:", length(successful_entries), "\n")

  # Save the complete merged file
  final_trans <- list(translation = c(base$translation, successful_entries))
  write_json(final_trans, 'translations/translation.json', pretty = TRUE, auto_unbox = TRUE)
  cat("\n✓ Saved to translations/translation.json\n")
  cat("  Total translations:", length(final_trans$translation), "\n")
} else {
  cat("\n✗ Stopped at entry", failed_entry_idx, "\n")
  cat("  Successfully added:", length(successful_entries), "entries before failure\n")
}
