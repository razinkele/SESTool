#!/usr/bin/env Rscript
# Merge template translations into main translation file

library(jsonlite)

cat("Merging template translations...\n\n")

# Load current translation file
cat("Loading translations/translation.json...\n")
base <- fromJSON('translations/translation.json', simplifyDataFrame = FALSE)
cat("  Current translations:", length(base$translation), "\n")

# Load template translations
cat("\nLoading template_translations.json...\n")
template_trans <- fromJSON('template_translations.json', simplifyDataFrame = FALSE)
cat("  Template translations:", length(template_trans$translation), "\n")

# Get English keys from base for duplicate checking
base_en <- sapply(base$translation, function(x) x$en)
template_en <- sapply(template_trans$translation, function(x) x$en)

# Find duplicates
duplicates <- template_en[template_en %in% base_en]
if (length(duplicates) > 0) {
  cat("\nFound", length(duplicates), "duplicates (will skip them):\n")
  for (dup in duplicates[1:min(5, length(duplicates))]) {
    cat("  -", dup, "\n")
  }
  if (length(duplicates) > 5) cat("  ... and", length(duplicates) - 5, "more\n")
}

# Filter for unique entries
unique_entries <- Filter(function(x) !(x$en %in% base_en), template_trans$translation)
cat("  Unique entries to add:", length(unique_entries), "\n")

# Create merged structure with languages field
merged <- list(
  languages = base$languages,
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
