library(jsonlite)
cat("List-based merge...\n\n")

# Load as lists
base <- fromJSON('translations/translation_backup_20251103_232419.json', simplifyDataFrame = FALSE)
ai_isa <- fromJSON('ai_isa_assistant_translations.json', simplifyDataFrame = FALSE)

cat("Base:", length(base$translation), "entries\n")
cat("AI ISA:", length(ai_isa$translation), "entries\n")

# Get English keys from base
base_en <- sapply(base$translation, function(x) x$en)

# Filter AI ISA for unique entries
ai_isa_unique <- Filter(function(x) !(x$en %in% base_en), ai_isa$translation)
cat("AI ISA unique:", length(ai_isa_unique), "entries\n")

# Merge lists
merged <- list(translation = c(base$translation, ai_isa_unique))
cat("Merged:", length(merged$translation), "entries\n\n")

# Save
write_json(merged, 'translations/translation.json', pretty = TRUE, auto_unbox = TRUE)
cat("✓ Saved!\n")
