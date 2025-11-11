#!/usr/bin/env Rscript
# Check for duplicate keys in translation.json

library(jsonlite)

cat("Loading translation.json...\n")
trans <- fromJSON("translations/translation.json", simplifyVector = FALSE)

cat("Languages:", paste(trans$languages, collapse=", "), "\n")
cat("Total translations:", length(trans$translation), "\n\n")

# Check for duplicate English keys
en_keys <- sapply(trans$translation, function(x) if(!is.null(x$en)) x$en else NA)
en_keys <- en_keys[!is.na(en_keys)]

dups <- en_keys[duplicated(en_keys)]
if (length(dups) > 0) {
  cat("DUPLICATE KEYS FOUND:", length(dups), "\n\n")
  unique_dups <- unique(dups)
  cat("Total unique duplicate keys:", length(unique_dups), "\n\n")
  cat("Duplicate keys:\n")
  for (dup in unique_dups) {
    cat("  -", dup, "\n")
  }
} else {
  cat("No duplicate keys found - all good!\n")
}
