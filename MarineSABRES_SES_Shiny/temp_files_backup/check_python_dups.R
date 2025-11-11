library(jsonlite)

python_trans <- fromJSON('ai_isa_assistant_translations.json', simplifyDataFrame = FALSE)
en_keys <- sapply(python_trans$translation, function(x) x$en)

cat("Total entries:", length(en_keys), "\n")
cat("Unique entries:", length(unique(en_keys)), "\n")

dups <- en_keys[duplicated(en_keys)]
if (length(dups) > 0) {
  cat("\nDuplicates found:\n")
  for (d in unique(dups)) {
    cat("  -", d, "\n")
  }
}
