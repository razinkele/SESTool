# Script to merge pims_module translations into translation.json
# This adds translations for the PIMS (Project Information Management System) module

library(jsonlite)

# Read existing translation.json
translation_file <- "translations/translation.json"
main_translations <- fromJSON(translation_file, simplifyVector = FALSE)

# Read pims_module_translations.json
pims_translations <- fromJSON("pims_module_translations.json", simplifyVector = FALSE)

# Merge translations
for (key in names(pims_translations$translation)) {
  main_translations$translation[[key]] <- pims_translations$translation[[key]]
}

# Write back to translation.json
write_json(main_translations, translation_file,
           pretty = TRUE, auto_unbox = TRUE)

cat("✓ Merged", length(pims_translations$translation), "PIMS module translation keys into translation.json\n")
cat("✓ Total translation keys:", length(main_translations$translation), "\n")
