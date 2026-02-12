#!/usr/bin/env Rscript
# Find all translation keys with English "Other"

source("functions/translation_loader.R")

# Load translations
merged <- load_translations("translations", debug = FALSE)

# Extract English texts and their keys
en_texts <- sapply(merged$translation, function(x) {
  if (!is.null(x$en)) x$en else ""
})

key_names <- names(merged$translation)

# Find "Other" keys
matching_keys <- key_names[en_texts == "Other"]

cat('Keys with English "Other":\n')
for (key in matching_keys) {
  cat(sprintf("  - %s\n", key))
}

cat(sprintf("\nTotal: %d keys\n", length(matching_keys)))
