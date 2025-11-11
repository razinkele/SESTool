library(jsonlite)
trans <- fromJSON('translations/translation.json', simplifyDataFrame = FALSE)
translations <- trans$translation
expected_keys <- c("en", "es", "fr", "de", "lt", "pt", "it")
cat("Checking", length(translations), "translation entries...\n\n")
issues_found <- FALSE
for (i in seq_along(translations)) {
  entry <- translations[[i]]
  entry_keys <- names(entry)
  missing_keys <- setdiff(expected_keys, entry_keys)
  extra_keys <- setdiff(entry_keys, expected_keys)
  if (length(missing_keys) > 0 || length(extra_keys) > 0) {
    issues_found <- TRUE
    cat("Entry", i, "- English:", substr(entry$en, 1, 50), "\n")
    if (length(missing_keys) > 0) {
      cat("  Missing keys:", paste(missing_keys, collapse=", "), "\n")
    }
    if (length(extra_keys) > 0) {
      cat("  Extra keys:", paste(extra_keys, collapse=", "), "\n")
    }
    cat("\n")
  }
}
if (!issues_found) {
  cat("All translation entries have correct structure!\n")
  cat("Total entries:", length(translations), "\n")
}
