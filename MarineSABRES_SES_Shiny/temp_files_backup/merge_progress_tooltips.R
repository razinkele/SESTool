#!/usr/bin/env Rscript
# Merge progress and tooltip translations

library(jsonlite)

cat("Loading existing translation.json...\n")
trans <- fromJSON("translations/translation.json", simplifyVector = FALSE)
cat("  - Languages:", paste(trans$languages, collapse=", "), "\n")
cat("  - Existing translations:", length(trans$translation), "\n")

cat("\nLoading progress and tooltip translations...\n")
new_trans <- fromJSON("progress_and_tooltip_translations.json", simplifyVector = FALSE)
cat("  - New translations to add:", length(new_trans), "\n")

cat("\nMerging...\n")
trans$translation <- c(trans$translation, new_trans)
cat("  - Total after merge:", length(trans$translation), "\n")

cat("\nWriting back to translation.json...\n")
write(toJSON(trans, pretty = FALSE, auto_unbox = TRUE), "translations/translation.json")

cat("\n✓ SUCCESS!\n")
cat("  Before:", length(trans$translation) - length(new_trans), "entries\n")
cat("  Added: ", length(new_trans), "entries\n")
cat("  After: ", length(trans$translation), "entries\n")

cat("\nVerifying file structure...\n")
verify <- fromJSON("translations/translation.json", simplifyVector = FALSE)
cat("  - Can read back: YES\n")
cat("  - Total translations:", length(verify$translation), "\n")
cat("  - Languages:", paste(verify$languages, collapse=", "), "\n")
