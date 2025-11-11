library(jsonlite)

cat("Converting AI ISA translations to R-compatible format...\n\n")

# Load the working backup to understand the exact structure
cat("Loading working translation structure...\n")
working <- fromJSON('translations/translation_backup_20251103_232419.json', simplifyDataFrame = FALSE)
cat("  Working file has", length(working$translation), "entries\n")

# Load Python-generated translations
cat("\nLoading Python-generated translations...\n")
python_trans <- fromJSON('ai_isa_assistant_translations.json', simplifyDataFrame = FALSE)
cat("  Python file has", length(python_trans$translation), "entries\n")

# Manually reconstruct each entry in the exact format as working file
cat("\nReconstructing translations in R format...\n")
r_format_translations <- list()

for (i in seq_along(python_trans$translation)) {
  entry <- python_trans$translation[[i]]
  
  # Create new entry with explicit structure matching working file
  new_entry <- list(
    en = as.character(entry$en),
    es = as.character(entry$es),
    fr = as.character(entry$fr),
    de = as.character(entry$de),
    lt = as.character(entry$lt),
    pt = as.character(entry$pt),
    it = as.character(entry$it)
  )
  
  r_format_translations[[i]] <- new_entry
}

cat("  Converted", length(r_format_translations), "entries\n")

# Create output in exact format as working file
output <- list(translation = r_format_translations)

# Save with exact same write_json parameters as backup
cat("\nSaving to ai_isa_r_format.json...\n")
write_json(output, 'ai_isa_r_format.json', pretty = TRUE, auto_unbox = TRUE)

# Test if it loads in shiny.i18n
cat("\nTesting shiny.i18n compatibility...\n")
library(shiny.i18n)
tryCatch({
  test_i18n <- Translator$new(translation_json_path = "ai_isa_r_format.json")
  test_i18n$set_translation_language("en")
  cat("✓ SUCCESS! File loads in shiny.i18n\n")
  cat("  Languages available:", paste(test_i18n$get_languages(), collapse=", "), "\n")
}, error = function(e) {
  cat("✗ Still fails:\n")
  print(e)
})
