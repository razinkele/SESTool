#!/usr/bin/env Rscript
# Extract remaining missing translations from console output

library(jsonlite)

# Missing strings identified from console warnings
missing_strings <- c(
  "e.g., How can we reduce fishing impacts while maintaining livelihoods?",
  "Added",
  "Review each connection below and approve or reject them.",
  "Strength:"
)

cat("Found", length(missing_strings), "missing strings\n\n")

# Load current translations
trans <- fromJSON('translations/translation.json', simplifyDataFrame = FALSE)
existing_en <- sapply(trans$translation, function(x) x$en)

# Filter for truly missing ones
truly_missing <- setdiff(missing_strings, existing_en)

if (length(truly_missing) > 0) {
  cat("Confirmed missing translations:\n")
  for (s in truly_missing) {
    cat("  -", s, "\n")
  }

  # Save for Python translation
  writeLines(truly_missing, "remaining_missing_strings.txt")
  cat("\nSaved to remaining_missing_strings.txt\n")
} else {
  cat("All strings are already in translation.json\n")
}
