#!/usr/bin/env Rscript
# Merge create_ses translations into translation.json

library(jsonlite)

cat("Loading existing translation.json...\n")
trans <- fromJSON("translations/translation.json", simplifyVector = FALSE)
cat("  - Existing translations:", length(trans$translation), "\n")

cat("\nLoading create_ses translations...\n")
new_trans <- fromJSON("create_ses_translations.json", simplifyVector = FALSE)
cat("  - New translations:", length(new_trans), "\n")

cat("\nMerging...\n")
trans$translation <- c(trans$translation, new_trans)
cat("  - Total after merge:", length(trans$translation), "\n")

cat("\nWriting back to translation.json...\n")
write(toJSON(trans, pretty = FALSE, auto_unbox = TRUE), "translations/translation.json")

cat("\n✓ SUCCESS! Create SES translations merged.\n")
cat("  Before:", length(trans$translation) - length(new_trans), "entries\n")
cat("  Added: ", length(new_trans), "entries\n")
cat("  After: ", length(trans$translation), "entries\n")
