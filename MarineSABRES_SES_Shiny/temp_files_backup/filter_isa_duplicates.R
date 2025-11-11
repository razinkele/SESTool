#!/usr/bin/env Rscript
# Filter out duplicate ISA translations

library(jsonlite)

cat("Loading existing translation.json...\n")
trans <- fromJSON("translations/translation.json", simplifyVector = FALSE)
existing_keys <- sapply(trans$translation, function(x) x$en)
cat("  - Existing translations:", length(existing_keys), "\n")

cat("\nLoading ISA translations...\n")
new_trans <- fromJSON("isa_all_exercises_translations.json", simplifyVector = FALSE)
cat("  - ISA translations loaded:", length(new_trans), "\n")

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

cat("\nWriting filtered translations...\n")
write(toJSON(unique_trans, pretty = TRUE, auto_unbox = TRUE), "isa_unique_translations.json")

cat("\n✓ SUCCESS! Filtered translations saved.\n")
cat("  Total ISA: ", length(new_trans), "\n")
cat("  Duplicates:", length(duplicates), "\n")
cat("  Unique:    ", length(unique_trans), "\n")
