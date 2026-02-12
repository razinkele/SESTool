#!/usr/bin/env Rscript
# Find translation keys with duplicate English text

source("functions/translation_loader.R")

# Load translations
merged <- load_translations("translations", debug = FALSE)

# Extract English texts and their keys
en_texts <- sapply(merged$translation, function(x) {
  if (!is.null(x$en)) x$en else ""
})

key_names <- names(merged$translation)

# Find duplicates
dup_texts <- en_texts[duplicated(en_texts) | duplicated(en_texts, fromLast = TRUE)]
dup_texts <- unique(dup_texts[dup_texts != ""])

cat("Found", length(dup_texts), "English texts that appear multiple times:\n\n")

# Show first 20 duplicates with their keys
for (text in head(dup_texts, 20)) {
  matching_keys <- key_names[en_texts == text]
  cat(sprintf("\n'%s' appears %d times:\n", text, length(matching_keys)))
  for (key in matching_keys) {
    cat(sprintf("  - %s\n", key))
  }
}
