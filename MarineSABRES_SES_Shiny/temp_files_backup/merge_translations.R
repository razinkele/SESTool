#!/usr/bin/env Rscript
# Merge entry point translations into main translation.json

library(jsonlite)

cat("Loading existing translation.json...\n")
old <- fromJSON("translations/translation.json")
cat("  - Languages:", paste(old$languages, collapse=", "), "\n")
cat("  - Existing translations:", length(old$translation), "\n")

cat("\nLoading new entry point translations...\n")
new_entries <- fromJSON("entry_point_translations.json")
cat("  - New translations to add:", length(new_entries), "\n")

cat("\nMerging translations...\n")
combined <- c(old$translation, new_entries)
cat("  - Total translations after merge:", length(combined), "\n")

cat("\nCreating output structure...\n")
result <- list(
  languages = old$languages,
  translation = combined
)

cat("\nWriting to translations/translation.json...\n")
write(toJSON(result, pretty = FALSE, auto_unbox = TRUE), "translations/translation.json")

cat("\n✓ Translation merge complete!\n")
cat("  Old count: ", length(old$translation), "\n")
cat("  Added:     ", length(new_entries), "\n")
cat("  New total: ", length(combined), "\n")
