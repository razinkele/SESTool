#!/usr/bin/env Rscript
# Merge Response & Validation translation into translation.json

library(jsonlite)

cat("Loading existing translation.json...\n")
trans <- fromJSON("translations/translation.json", simplifyVector = FALSE)
cat("  - Existing translations:", length(trans$translation), "\n")

cat("\nLoading Response & Validation translation...\n")
new_trans <- fromJSON("response_validation_translation.json", simplifyVector = FALSE)
cat("  - New translation to add:", length(new_trans), "\n")

cat("\nMerging...\n")
trans$translation <- c(trans$translation, new_trans)
cat("  - Total after merge:", length(trans$translation), "\n")

cat("\nWriting back to translation.json...\n")
write(toJSON(trans, pretty = FALSE, auto_unbox = TRUE), "translations/translation.json")

cat("\n✓ SUCCESS! Response & Validation translation merged.\n")
cat("  Before:", length(trans$translation) - length(new_trans), "entries\n")
cat("  Added: ", length(new_trans), "entry\n")
cat("  After: ", length(trans$translation), "entries\n")
