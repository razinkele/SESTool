#!/usr/bin/env Rscript
# Check for missing menu translations

library(jsonlite)

cat("Loading translation.json...\n")
trans <- fromJSON("translations/translation.json", simplifyVector = FALSE)
existing <- sapply(trans$translation, function(x) x$en)

cat("\nChecking translations:\n")
if ("Response & Validation" %in% existing) {
  cat("  'Response & Validation': FOUND\n")
} else {
  cat("  'Response & Validation': MISSING\n")
}

if ("Choose Method" %in% existing) {
  cat("  'Choose Method': FOUND\n")
} else {
  cat("  'Choose Method': MISSING\n")
}

cat("\nTotal translations:", length(existing), "\n")
