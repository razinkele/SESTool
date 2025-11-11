# Script to merge pims_stakeholder_module translations into translation.json
# This adds translations for the PIMS Stakeholder Management module

library(jsonlite)

# Read existing translation.json
translation_file <- "translations/translation.json"
main_translations <- fromJSON(translation_file, simplifyVector = FALSE)

# Read pims_stakeholder_module_translations.json
stakeholder_translations <- fromJSON("pims_stakeholder_module_translations.json", simplifyVector = FALSE)

# Merge translations
for (key in names(stakeholder_translations$translation)) {
  main_translations$translation[[key]] <- stakeholder_translations$translation[[key]]
}

# Write back to translation.json
write_json(main_translations, translation_file,
           pretty = TRUE, auto_unbox = TRUE)

cat("✓ Merged", length(stakeholder_translations$translation), "PIMS Stakeholder module translation keys into translation.json\n")
cat("✓ Total translation keys:", length(main_translations$translation), "\n")
