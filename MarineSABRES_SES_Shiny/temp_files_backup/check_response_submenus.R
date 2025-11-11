#!/usr/bin/env Rscript
# Check for Response & Validation submenu translations

library(jsonlite)

cat("Loading translation.json...\n")
trans <- fromJSON("translations/translation.json", simplifyVector = FALSE)
existing <- sapply(trans$translation, function(x) x$en)

cat("\nChecking submenu translations:\n")
submenus <- c("Response Measures", "Scenario Builder", "Validation")

for (submenu in submenus) {
  if (submenu %in% existing) {
    cat("  '", submenu, "': FOUND\n", sep = "")
  } else {
    cat("  '", submenu, "': MISSING\n", sep = "")
  }
}

cat("\nTotal translations:", length(existing), "\n")
