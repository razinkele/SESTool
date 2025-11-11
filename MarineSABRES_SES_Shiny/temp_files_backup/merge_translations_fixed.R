#!/usr/bin/env Rscript
# Merge entry point translations into translation.json (FIXED VERSION)

library(jsonlite)

cat("Loading existing translation.json...\n")
# Read raw JSON
raw_json <- readLines("translations/translation.json", warn = FALSE)
cat("  - Total lines in file:", length(raw_json), "\n")

# Parse JSON
trans <- fromJSON("translations/translation.json", simplifyVector = FALSE)
cat("  - Languages:", paste(trans$languages, collapse=", "), "\n")
cat("  - Existing translations:", length(trans$translation), "\n")

cat("\nLoading new entry point translations...\n")
new_trans <- fromJSON("entry_point_translations.json", simplifyVector = FALSE)
cat("  - New entries to add:", length(new_trans), "\n")

# Show first few new entries as examples
cat("\nSample new translations:\n")
for(i in 1:min(3, length(new_trans))) {
  cat("  ", i, ". EN:", new_trans[[i]]$en, "\n")
  cat("      ES:", new_trans[[i]]$es, "\n")
}

cat("\nMerging...\n")
trans$translation <- c(trans$translation, new_trans)
cat("  - Total after merge:", length(trans$translation), "\n")

cat("\nWriting back to translation.json...\n")
write(toJSON(trans, pretty = FALSE, auto_unbox = TRUE), "translations/translation.json")

cat("\n✓ SUCCESS!\n")
cat("  Before: 2515 entries (approx)\n")
cat("  Added:  ", length(new_trans), "entries\n")
cat("  After:  ", length(trans$translation), "entries\n")
cat("\nVerifying file structure...\n")
verify <- fromJSON("translations/translation.json", simplifyVector = FALSE)
cat("  - Can read back: YES\n")
cat("  - Total translations:", length(verify$translation), "\n")
cat("  - Languages:", paste(verify$languages, collapse=", "), "\n")
