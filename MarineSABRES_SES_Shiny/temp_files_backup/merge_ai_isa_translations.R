#!/usr/bin/env Rscript
# Merge AI ISA Assistant module translations into main translation.json

library(jsonlite)

cat("Merging AI ISA Assistant translations...\n\n")

# Load main translation file
cat("Loading main translations/translation.json...\n")
main_trans <- fromJSON('translations/translation.json', simplifyDataFrame = FALSE)
cat(sprintf("  Current translations: %d\n", length(main_trans$translation)))

# Load AI ISA translations
cat("\nLoading ai_isa_assistant_translations.json...\n")
ai_isa_trans <- fromJSON('ai_isa_assistant_translations.json', simplifyDataFrame = FALSE)
cat(sprintf("  AI ISA translations: %d\n", length(ai_isa_trans$translation)))

# Extract English keys from main translations for duplicate checking
main_keys <- sapply(main_trans$translation, function(x) x$en)
ai_isa_keys <- sapply(ai_isa_trans$translation, function(x) x$en)

# Check for duplicates
duplicates <- ai_isa_keys[ai_isa_keys %in% main_keys]
if (length(duplicates) > 0) {
  cat(sprintf("\nWARNING: Found %d duplicate keys:\n", length(duplicates)))
  for (dup in duplicates[1:min(10, length(duplicates))]) {
    cat(sprintf("  - %s\n", substr(dup, 1, 60)))
  }
  if (length(duplicates) > 10) {
    cat(sprintf("  ... and %d more\n", length(duplicates) - 10))
  }
  cat("\nRemoving duplicates from AI ISA translations (keeping existing entries)...\n")

  # Filter out duplicates from AI ISA translations
  ai_isa_trans$translation <- Filter(function(x) !(x$en %in% main_keys), ai_isa_trans$translation)
  cat(sprintf("  After removing duplicates: %d new translations\n", length(ai_isa_trans$translation)))
}

# Merge translations
cat("\nMerging translations...\n")
merged_trans <- list(
  translation = c(main_trans$translation, ai_isa_trans$translation)
)

cat(sprintf("  Total translations: %d\n", length(merged_trans$translation)))

# Backup original file
backup_file <- sprintf('translations/translation_backup_%s.json',
                       format(Sys.time(), "%Y%m%d_%H%M%S"))
cat(sprintf("\nCreating backup: %s\n", backup_file))
file.copy('translations/translation.json', backup_file)

# Save merged translations
cat("\nSaving merged translations to translations/translation.json...\n")
write_json(merged_trans, 'translations/translation.json',
           pretty = TRUE, auto_unbox = TRUE)

cat("\n✓ Merge complete!\n")
cat(sprintf("  Previous: %d translations\n", length(main_trans$translation)))
cat(sprintf("  Added: %d new translations\n", length(ai_isa_trans$translation)))
cat(sprintf("  Total: %d translations\n", length(merged_trans$translation)))
cat(sprintf("  Backup saved: %s\n", backup_file))
