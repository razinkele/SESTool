#!/usr/bin/env Rscript
# Merge unique ISA translations into translation.json

library(jsonlite)

cat("Loading existing translation.json...\n")
trans <- fromJSON("translations/translation.json", simplifyVector = FALSE)
cat("  - Existing translations:", length(trans$translation), "\n")

cat("\nLoading unique ISA translations...\n")
new_trans <- fromJSON("isa_unique_translations.json", simplifyVector = FALSE)
cat("  - New unique translations:", length(new_trans), "\n")

cat("\nMerging...\n")
trans$translation <- c(trans$translation, new_trans)
cat("  - Total after merge:", length(trans$translation), "\n")

cat("\nWriting back to translation.json...\n")
write(toJSON(trans, pretty = FALSE, auto_unbox = TRUE), "translations/translation.json")

cat("\n✓ SUCCESS! Unique ISA translations merged.\n")
cat("  Before:", length(trans$translation) - length(new_trans), "entries\n")
cat("  Added: ", length(new_trans), "entries\n")
cat("  After: ", length(trans$translation), "entries\n")
