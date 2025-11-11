library(shiny.i18n)
cat("Testing AI ISA file alone...\n")
tryCatch({
  i18n <- Translator$new(translation_json_path = "ai_isa_assistant_translations.json")
  cat("✓ AI ISA file loaded!\n")
}, error = function(e) {
  cat("✗ Error:\n")
  print(e)
})
