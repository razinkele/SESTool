#!/usr/bin/env Rscript
# Merge missing app translations

library(jsonlite)

cat("Merging missing app translations...\n\n")

# Load files
main_trans <- fromJSON('translations/translation.json', simplifyDataFrame = FALSE)
missing_trans <- fromJSON('missing_app_translations.json', simplifyDataFrame = FALSE)

# Get existing English keys
existing_en <- sapply(main_trans$translation, function(x) x$en)

cat("Existing translations:", length(existing_en), "\n")
cat("Missing translations to add:", length(missing_trans$translation), "\n\n")

# Add new translations
new_count <- 0
for (entry in missing_trans$translation) {
  if (!entry$en %in% existing_en) {
    cat("Adding:", entry$en, "\n")
    main_trans$translation <- c(main_trans$translation, list(entry))
    new_count <- new_count + 1
  } else {
    cat("Skipping (already exists):", entry$en, "\n")
  }
}

if (new_count > 0) {
  # Save updated translations
  write_json(main_trans, 'translations/translation.json',
             pretty = TRUE, auto_unbox = TRUE)

  cat("\n✓ Added", new_count, "new translations\n")
  cat("✓ Total translations now:", length(main_trans$translation), "\n")
  cat("✓ Saved to translations/translation.json\n")
} else {
  cat("\n✓ No new translations to add - all already exist\n")
}
