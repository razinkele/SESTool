#!/usr/bin/env Rscript
# Check which template strings are missing from translations

library(jsonlite)

# Load template strings
template_strings <- readLines('template_strings.txt')
cat("Template strings:", length(template_strings), "\n")

# Load translation file
trans <- fromJSON('translations/translation.json', simplifyDataFrame = FALSE)
existing_en <- sapply(trans$translation, function(x) x$en)
cat("Existing translations:", length(existing_en), "\n")

# Find missing
missing <- setdiff(template_strings, existing_en)

if (length(missing) > 0) {
  cat("\n=== MISSING TEMPLATE TRANSLATIONS ===\n")
  cat("Found", length(missing), "template strings that need translation:\n\n")
  for (i in seq_along(missing)) {
    cat(sprintf("[%d] %s\n", i, missing[i]))
  }

  # Save to file
  writeLines(missing, "missing_template_strings.txt")
  cat("\n✓ Saved missing strings to missing_template_strings.txt\n")
} else {
  cat("\n✓ All template strings are already in translation.json!\n")
}

# Also check which are present
present <- intersect(template_strings, existing_en)
cat("\nTemplate strings already translated:", length(present), "\n")
