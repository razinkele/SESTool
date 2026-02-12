#!/usr/bin/env Rscript
# Merge modular translation files into _merged_translations.json

source("functions/translation_loader.R")

cat("=== Merging Translation Files ===\n\n")

# Load and merge all modular translation files
merged <- load_translations(
  base_path = "translations",
  debug = TRUE
)

cat("\n=== Saving Merged Translations ===\n\n")

# Save to persistent file
result <- save_merged_translations(
  merged,
  debug = TRUE,
  persistent = TRUE
)

cat("\n=== Complete! ===\n")
cat(sprintf("Merged %d translation keys\n", length(merged$translation)))
cat(sprintf("Saved to: %s\n", result))
cat("\nYou can now restart the Shiny app to use the updated translations.\n")
