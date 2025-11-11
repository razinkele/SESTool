# Script to merge ai_isa_assistant_module translations into translation.json
# This adds translations for the AI-Assisted ISA Creation module

library(jsonlite)

# Read existing translation.json
translation_file <- "translations/translation.json"
main_translations <- fromJSON(translation_file, simplifyVector = FALSE)

# Read ai_isa_assistant_module_translations.json
ai_isa_translations <- fromJSON("ai_isa_assistant_module_translations.json", simplifyVector = FALSE)

# Merge translations
for (key in names(ai_isa_translations$translation)) {
  main_translations$translation[[key]] <- ai_isa_translations$translation[[key]]
}

# Write back to translation.json
write_json(main_translations, translation_file,
           pretty = TRUE, auto_unbox = TRUE)

cat("✓ Merged", length(ai_isa_translations$translation), "AI ISA Assistant module translation keys into translation.json\n")
cat("✓ Total translation keys:", length(main_translations$translation), "\n")
