#!/usr/bin/env Rscript
# Find AI ISA strings that are missing from translation.json

library(jsonlite)

cat("Finding missing AI ISA translations...\n\n")

# Load all extracted AI ISA strings
cat("Loading extracted strings from ai_isa_assistant_all_strings.json...\n")
all_strings_data <- fromJSON('ai_isa_assistant_all_strings.json')
all_extracted <- unique(unlist(all_strings_data))
cat("  Total unique extracted strings:", length(all_extracted), "\n")

# Load current translation file
cat("\nLoading translations/translation.json...\n")
trans <- fromJSON('translations/translation.json', simplifyDataFrame = FALSE)
existing_en <- sapply(trans$translation, function(x) x$en)
cat("  Total translations in file:", length(existing_en), "\n")

# Find missing strings
missing <- setdiff(all_extracted, existing_en)

if (length(missing) > 0) {
  cat("\n=== MISSING TRANSLATIONS ===\n")
  cat("Found", length(missing), "strings that need translation:\n\n")
  for (i in seq_along(missing)) {
    cat(sprintf("[%d] %s\n", i, missing[i]))
  }

  # Save missing strings to file
  writeLines(missing, "missing_ai_isa_strings.txt")
  cat("\n✓ Saved missing strings to missing_ai_isa_strings.txt\n")
} else {
  cat("\n✓ All extracted strings are in translation.json!\n")
}

# Also check if there are any strings in Python translations that didn't make it
cat("\n\nChecking Python-generated translations...\n")
python_trans <- fromJSON('ai_isa_assistant_translations.json', simplifyDataFrame = FALSE)
python_en <- sapply(python_trans$translation, function(x) x$en)
cat("  Python translations:", length(python_en), "\n")

python_missing <- setdiff(all_extracted, python_en)
if (length(python_missing) > 0) {
  cat("\n=== STRINGS NOT IN PYTHON TRANSLATIONS ===\n")
  cat("Found", length(python_missing), "strings:\n\n")
  for (i in seq_along(python_missing)) {
    cat(sprintf("[%d] %s\n", i, python_missing[i]))
  }
}
