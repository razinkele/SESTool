library(jsonlite)
library(shiny.i18n)

# Load working backup
working <- fromJSON('translations/translation_backup_20251103_232419.json', simplifyDataFrame = FALSE)

# Load one Python entry
python_trans <- fromJSON('ai_isa_assistant_translations.json', simplifyDataF

rame = FALSE)
one_entry <- python_trans$translation[[1]]

cat("Testing adding ONE Python entry to working file...\n")
cat("Python entry EN:", one_entry$en, "\n\n")

# Add it to working
test_trans <- list(translation = c(working$translation, list(one_entry)))

# Save
write_json(test_trans, 'test_one_add.json', pretty = TRUE, auto_unbox = TRUE)

# Test
cat("Testing load...\n")
tryCatch({
  test_i18n <- Translator$new(translation_json_path = "test_one_add.json")
  cat("✓ SUCCESS! One Python entry added successfully\n")
}, error = function(e) {
  cat("✗ FAIL with one entry:\n")
  print(e)
})
