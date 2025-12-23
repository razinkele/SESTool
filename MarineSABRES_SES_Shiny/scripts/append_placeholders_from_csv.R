# Append placeholders for missing translation keys from CSV to _merged_translations.json
library(jsonlite)

csv_path <- "missing_translation_keys.csv"
merged_path <- "translations/_merged_translations.json"
if (!file.exists(csv_path)) stop("missing_translation_keys.csv not found; run scripts/report_missing_keys.R first")
if (!file.exists(merged_path)) stop("merged translations not found")

missing <- read.csv(csv_path, stringsAsFactors = FALSE)$missing
if (length(missing) == 0) {
  cat("No missing keys to append\n")
  quit(status = 0)
}

merged <- fromJSON(merged_path, simplifyVector = FALSE)
langs <- merged$languages
if (is.null(langs) || length(langs) == 0) stop("No languages found in merged translations")

backup_path <- paste0(merged_path, ".backup.", format(Sys.time(), "%Y%m%d_%H%M%S"))
file.copy(merged_path, backup_path)
cat("Backed up merged translations to", backup_path, "\n")

existing_keys <- sapply(merged$translation, function(x) x$key)
new_count <- 0
for (k in missing) {
  if (k %in% existing_keys) next
  entry <- list(key = k)
  # Add placeholder for english and empty for rest
  for (lg in langs) {
    if (lg == "en") entry[[lg]] <- paste("[MISSING TRANSLATION]", k)
    else entry[[lg]] <- ""
  }
  merged$translation[[length(merged$translation) + 1]] <- entry
  new_count <- new_count + 1
}

if (new_count > 0) {
  write_json(merged, merged_path, pretty = TRUE, auto_unbox = TRUE)
  cat("Appended", new_count, "new placeholders to", merged_path, "\n")
} else {
  cat("No new placeholders appended (all keys already present)")
}
