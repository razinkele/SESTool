library(jsonlite)
trans <- fromJSON('translations/translation.json', simplifyDataFrame = FALSE)
translations <- trans$translation
expected_keys <- c("en", "es", "fr", "de", "lt", "pt", "it")
cat("Checking for empty or NULL values...\n\n")
issues_found <- FALSE
for (i in seq_along(translations)) {
  entry <- translations[[i]]
  for (key in expected_keys) {
    if (is.null(entry[[key]]) || is.na(entry[[key]]) || entry[[key]] == "") {
      issues_found <- TRUE
      cat("Entry", i, "- Key:", key, "is empty/NULL\n")
      cat("  English:", substr(entry$en, 1, 60), "\n\n")
    }
  }
}
if (!issues_found) {
  cat("No empty or NULL values found!\n")
}
