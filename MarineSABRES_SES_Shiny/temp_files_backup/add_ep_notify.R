#!/usr/bin/env Rscript
# Add missing navigation notification translation

library(jsonlite)

cat("Adding 'Navigating to %s...' translation...\n\n")

# Load files
main_trans <- fromJSON('translations/translation.json', simplifyDataFrame = FALSE)
ep_trans <- fromJSON('ep_notify_translation.json', simplifyDataFrame = FALSE)

# Get the new entry
new_entry <- ep_trans$translation[[1]]

# Check if it already exists
existing_en <- sapply(main_trans$translation, function(x) x$en)

if (!new_entry$en %in% existing_en) {
  # Add the new entry
  main_trans$translation <- c(main_trans$translation, list(new_entry))

  # Save
  write_json(main_trans, 'translations/translation.json',
             pretty = TRUE, auto_unbox = TRUE)

  cat("✓ Added translation\n")
  cat("✓ Total translations now:", length(main_trans$translation), "\n")
  cat("✓ Saved to translations/translation.json\n")
} else {
  cat("✓ Translation already exists\n")
}
