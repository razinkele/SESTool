library(jsonlite)
cat("Reformatting AI ISA translations...\n")

# Load AI ISA file
ai_isa <- fromJSON('ai_isa_assistant_translations.json', simplifyDataFrame = FALSE)

# Convert each entry to ensure proper structure
reformatted <- lapply(ai_isa$translation, function(entry) {
  # Ensure all values are character strings (no NULLs, factors, etc.)
  list(
    en = as.character(entry$en),
    es = as.character(entry$es),
    fr = as.character(entry$fr),
    de = as.character(entry$de),
    lt = as.character(entry$lt),
    pt = as.character(entry$pt),
    it = as.character(entry$it)
  )
})

output <- list(translation = reformatted)

# Save with same settings as backup file
write_json(output, 'ai_isa_assistant_translations_clean.json', 
           pretty = TRUE, auto_unbox = TRUE)

cat("✓ Reformatted! Testing load...\n")

# Test if it loads
library(shiny.i18n)
tryCatch({
  test <- Translator$new(translation_json_path = "ai_isa_assistant_translations_clean.json")
  cat("✓ SUCCESS - Clean file loads in shiny.i18n!\n")
}, error = function(e) {
  cat("✗ Still fails:\n")
  print(e)
})
