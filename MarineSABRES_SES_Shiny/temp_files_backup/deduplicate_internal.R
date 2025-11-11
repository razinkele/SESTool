#!/usr/bin/env Rscript
# Remove internal duplicates from response_measures_unique_translations.json

library(jsonlite)

cat("Loading response_measures_unique_translations.json...\n")
trans_list <- fromJSON("response_measures_unique_translations.json", simplifyVector = FALSE)
cat("  - Total entries:", length(trans_list), "\n")

# Track unique English keys
seen_keys <- c()
deduplicated <- list()

cat("\nRemoving internal duplicates...\n")
for (i in seq_along(trans_list)) {
  en_key <- trans_list[[i]]$en

  if (!(en_key %in% seen_keys)) {
    deduplicated <- c(deduplicated, list(trans_list[[i]]))
    seen_keys <- c(seen_keys, en_key)
  } else {
    cat("  - Removing duplicate:", en_key, "\n")
  }
}

cat("\n✓ Deduplication complete.\n")
cat("  Before:", length(trans_list), "entries\n")
cat("  After: ", length(deduplicated), "entries\n")
cat("  Removed:", length(trans_list) - length(deduplicated), "duplicates\n")

cat("\nWriting deduplicated file...\n")
write(toJSON(deduplicated, pretty = TRUE, auto_unbox = TRUE), "response_measures_deduplicated.json")

cat("\n✓ SUCCESS! Saved as response_measures_deduplicated.json\n")
