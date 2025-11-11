#!/usr/bin/env Rscript
# Merge AI ISA translations with proper languages field

library(jsonlite)

cat("Merging AI ISA translations with proper structure...\n\n")

# Load working backup
cat("Loading working backup...\n")
base <- fromJSON('translations/translation_backup_20251103_232419.json', simplifyDataFrame = FALSE)
cat("  Current translations:", length(base$translation), "\n")
cat("  Languages field:", paste(base$languages, collapse=", "), "\n")

# Load Python translations
cat("\nLoading Python translations...\n")
python_trans <- fromJSON('ai_isa_assistant_translations.json', simplifyDataFrame = FALSE)
cat("  Python translations:", length(python_trans$translation), "\n")

# Get English keys from base for duplicate checking
base_en <- sapply(base$translation, function(x) x$en)
python_en <- sapply(python_trans$translation, function(x) x$en)

# Filter for unique entries
unique_entries <- Filter(function(x) !(x$en %in% base_en), python_trans$translation)
cat("  Unique entries to add:", length(unique_entries), "\n")

# Create merged structure with languages field
merged <- list(
  languages = base$languages,  # CRITICAL: Include languages field
  translation = c(base$translation, unique_entries)
)

cat("\n=== MERGED STRUCTURE ===\n")
cat("Languages:", paste(merged$languages, collapse=", "), "\n")
cat("Total translations:", length(merged$translation), "\n")

# Backup original file
backup_file <- sprintf('translations/translation_backup_%s.json',
                       format(Sys.time(), "%Y%m%d_%H%M%S"))
cat(sprintf("\nCreating backup: %s\n", backup_file))
file.copy('translations/translation.json', backup_file, overwrite = TRUE)

# Save merged translations
cat("\nSaving merged translations to translations/translation.json...\n")
write_json(merged, 'translations/translation.json',
           pretty = TRUE, auto_unbox = TRUE)

# Test loading
cat("\nTesting if merged file loads in shiny.i18n...\n")
library(shiny.i18n)
tryCatch({
  test_i18n <- Translator$new(translation_json_path = "translations/translation.json")
  test_i18n$set_translation_language("en")
  cat("✓ SUCCESS! Merged file loads correctly\n")
  cat("  Available languages:", paste(test_i18n$get_languages(), collapse=", "), "\n")
  cat("\n✓ Merge complete!\n")
  cat(sprintf("  Previous: %d translations\n", length(base$translation)))
  cat(sprintf("  Added: %d new translations\n", length(unique_entries)))
  cat(sprintf("  Total: %d translations\n", length(merged$translation)))
  cat(sprintf("  Backup saved: %s\n", backup_file))
}, error = function(e) {
  cat("✗ Loading failed:", conditionMessage(e), "\n")
  cat("\nRestoring backup...\n")
  file.copy(backup_file, 'translations/translation.json', overwrite = TRUE)
})
