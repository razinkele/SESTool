library(shiny.i18n)
cat("Testing shiny.i18n load...\n")
tryCatch({
  i18n <- Translator$new(translation_json_path = "translations/translation.json")
  i18n$set_translation_language("en")
  cat("✓ shiny.i18n loaded successfully!\n")
  cat("Languages:", paste(i18n$get_languages(), collapse=", "), "\n")
  cat("Key count:", i18n$get_key_translation() %>% nrow(), "\n")
}, error = function(e) {
  cat("✗ Error loading:\n")
  print(e)
})
