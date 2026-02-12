#!/usr/bin/env Rscript
# Find duplicate keys across modular translation files

library(jsonlite)

# Get all modular translation files
json_files <- list.files(
  path = "translations",
  pattern = "\\.json$",
  full.names = TRUE,
  recursive = TRUE
)

# Exclude backup and merged files
json_files <- json_files[!grepl("backup|_merged|_backup", json_files, ignore.case = TRUE)]

# Track all keys and their sources
all_keys <- list()

for (file in json_files) {
  data <- fromJSON(file, simplifyVector = FALSE)
  if (!is.null(data$translation)) {
    file_keys <- names(data$translation)
    for (key in file_keys) {
      if (is.null(all_keys[[key]])) {
        all_keys[[key]] <- c()
      }
      all_keys[[key]] <- c(all_keys[[key]], basename(file))
    }
  }
}

# Find duplicates
duplicates <- all_keys[sapply(all_keys, length) > 1]

cat(sprintf("Found %d keys that appear in multiple files:\n\n", length(duplicates)))

# Show first 20 duplicates
for (key in head(names(duplicates), 20)) {
  files <- duplicates[[key]]
  cat(sprintf("\n'%s' appears in %d files:\n", key, length(files)))
  for (file in files) {
    cat(sprintf("  - %s\n", file))
  }
}
