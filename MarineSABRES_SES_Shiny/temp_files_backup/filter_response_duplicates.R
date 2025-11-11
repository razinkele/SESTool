#!/usr/bin/env Rscript
# Filter out duplicate response module translations

library(jsonlite)

cat("Loading existing translation.json...\n")
trans <- fromJSON("translations/translation.json", simplifyVector = FALSE)
existing_keys <- sapply(trans$translation, function(x) x$en)
cat("  - Existing translations:", length(existing_keys), "\n")

cat("\nLoading response measures translations...\n")
new_trans <- fromJSON("response_measures_translations.json", simplifyVector = FALSE)
cat("  - Response translations loaded:", length(new_trans), "\n")

# Filter out duplicates
cat("\nFiltering duplicates...\n")
unique_trans <- list()
duplicates <- c()

for (i in seq_along(new_trans)) {
  en_key <- new_trans[[i]]$en
  if (!(en_key %in% existing_keys)) {
    unique_trans <- c(unique_trans, list(new_trans[[i]]))
  } else {
    duplicates <- c(duplicates, en_key)
  }
}

cat("  - Duplicates found:", length(duplicates), "\n")
if (length(duplicates) > 0) {
  cat("  - Duplicate keys:\n")
  for (dup in duplicates) {
    cat("    -", dup, "\n")
  }
}

cat("  - Unique translations:", length(unique_trans), "\n")

if (length(unique_trans) > 0) {
  cat("\nWriting filtered translations...\n")
  write(toJSON(unique_trans, pretty = TRUE, auto_unbox = TRUE), "response_measures_unique_translations.json")

  cat("\n✓ SUCCESS! Filtered translations saved.\n")
  cat("  Total Response: ", length(new_trans), "\n")
  cat("  Duplicates:     ", length(duplicates), "\n")
  cat("  Unique:         ", length(unique_trans), "\n")
} else {
  cat("\n⚠ WARNING: All translations are duplicates. No unique file created.\n")
}
