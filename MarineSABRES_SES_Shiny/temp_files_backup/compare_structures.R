#!/usr/bin/env Rscript
# Compare structure of working vs Python translations

library(jsonlite)

cat("Loading working backup...\n")
working <- fromJSON('translations/translation_backup_20251103_232419.json', simplifyDataFrame = FALSE)

cat("\nLoading Python translations...\n")
python <- fromJSON('ai_isa_assistant_translations.json', simplifyDataFrame = FALSE)

cat("\n=== WORKING ENTRY (first entry) ===\n")
cat("Structure:\n")
str(working$translation[[1]])
cat("\nClass of entry:", class(working$translation[[1]]), "\n")
cat("Names:", paste(names(working$translation[[1]]), collapse=", "), "\n")
cat("\nEach field class:\n")
for (field in names(working$translation[[1]])) {
  cat("  ", field, ":", class(working$translation[[1]][[field]]), "-",
      typeof(working$translation[[1]][[field]]), "\n")
}

cat("\n=== PYTHON ENTRY (first entry) ===\n")
cat("Structure:\n")
str(python$translation[[1]])
cat("\nClass of entry:", class(python$translation[[1]]), "\n")
cat("Names:", paste(names(python$translation[[1]]), collapse=", "), "\n")
cat("\nEach field class:\n")
for (field in names(python$translation[[1]])) {
  cat("  ", field, ":", class(python$translation[[1]][[field]]), "-",
      typeof(python$translation[[1]][[field]]), "\n")
}

cat("\n=== COMPARISON ===\n")
cat("Working entry length:", length(working$translation[[1]]), "\n")
cat("Python entry length:", length(python$translation[[1]]), "\n")

cat("\nTesting if we can manually create an identical entry:\n")
manual_entry <- list(
  en = "Test English",
  es = "Test Spanish",
  fr = "Test French",
  de = "Test German",
  lt = "Test Lithuanian",
  pt = "Test Portuguese",
  it = "Test Italian"
)

cat("Manual entry structure:\n")
str(manual_entry)

# Test loading with manual entry
test_trans <- list(translation = c(working$translation[1:5], list(manual_entry)))
write_json(test_trans, 'test_manual.json', pretty = TRUE, auto_unbox = TRUE)

library(shiny.i18n)
cat("\nTesting manual entry in shiny.i18n...\n")
tryCatch({
  test_i18n <- Translator$new(translation_json_path = "test_manual.json")
  cat("✓ Manual entry works!\n")
}, error = function(e) {
  cat("✗ Manual entry fails:", conditionMessage(e), "\n")
})

# Clean up
if (file.exists('test_manual.json')) file.remove('test_manual.json')
