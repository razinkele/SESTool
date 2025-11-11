#!/usr/bin/env Rscript
# Remove duplicate translation keys from translation.json

library(jsonlite)

cat("Loading translation.json...\n")
trans <- fromJSON("translations/translation.json", simplifyVector = FALSE)
cat("  - Initial count:", length(trans$translation), "\n")

# Deduplicate by English key (keep first occurrence)
seen_keys <- c()
deduplicated <- list()
duplicates_removed <- 0

for (i in seq_along(trans$translation)) {
  en_key <- trans$translation[[i]]$en

  if (is.null(en_key) || is.na(en_key)) {
    cat("WARNING: Skipping entry", i, "- no English key\n")
    next
  }

  if (!(en_key %in% seen_keys)) {
    deduplicated <- c(deduplicated, list(trans$translation[[i]]))
    seen_keys <- c(seen_keys, en_key)
  } else {
    duplicates_removed <- duplicates_removed + 1
  }
}

cat("  - Duplicates removed:", duplicates_removed, "\n")
cat("  - Final count:", length(deduplicated), "\n\n")

# Update translation list
trans$translation <- deduplicated

# Save back to file
cat("Writing deduplicated translation.json...\n")
write(toJSON(trans, pretty = FALSE, auto_unbox = TRUE), "translations/translation.json")

cat("\n✓ SUCCESS! Deduplication complete.\n")
cat("  Before:", length(trans$translation) + duplicates_removed, "entries\n")
cat("  Removed:", duplicates_removed, "duplicates\n")
cat("  After:", length(trans$translation), "entries\n")
