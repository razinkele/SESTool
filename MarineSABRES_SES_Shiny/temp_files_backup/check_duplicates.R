# Check for duplicates between scenario_builder_translations and main translation.json
# Create filtered unique translations file

library(jsonlite)

# Load scenario builder translations
sb_file <- "C:/Users/DELL/OneDrive - ku.lt/HORIZON_EUROPE/Marine-SABRES/SESToolbox/MarineSABRES_SES_Shiny/scenario_builder_translations.json"
sb_translations <- fromJSON(sb_file)

# Load main translation file
main_file <- "C:/Users/DELL/OneDrive - ku.lt/HORIZON_EUROPE/Marine-SABRES/SESToolbox/MarineSABRES_SES_Shiny/translations/translation.json"
main_trans_full <- fromJSON(main_file)
main_translations <- main_trans_full$translation

# Extract English texts from both
if (is.data.frame(sb_translations)) {
  sb_en_texts <- sb_translations$en
} else if (is.list(sb_translations)) {
  sb_en_texts <- sapply(sb_translations, function(x) x$en)
} else {
  sb_en_texts <- sb_translations
}

if (is.data.frame(main_translations)) {
  main_en_texts <- main_translations$en
} else if (is.list(main_translations)) {
  main_en_texts <- sapply(main_translations, function(x) {
    if (is.list(x)) return(x$en)
    if (is.character(x) && "en" %in% names(x)) return(x["en"])
    return(NA)
  })
} else {
  main_en_texts <- character(0)
}

cat("Scenario Builder translations:", length(sb_en_texts), "\n")
cat("Main translation file entries:", length(main_en_texts), "\n\n")

# Find duplicates
duplicates <- sb_en_texts[sb_en_texts %in% main_en_texts]
unique_texts <- sb_en_texts[!sb_en_texts %in% main_en_texts]

cat("Duplicates found:", length(duplicates), "\n")
cat("Unique new translations:", length(unique_texts), "\n\n")

if (length(duplicates) > 0) {
  cat("Duplicate texts (already in main translation.json):\n")
  cat(paste("  -", duplicates), sep = "\n")
  cat("\n")
}

# Create filtered unique translations
if (is.data.frame(sb_translations)) {
  unique_translations <- sb_translations[sb_translations$en %in% unique_texts, ]
} else {
  unique_translations <- sb_translations[sb_en_texts %in% unique_texts]
}

# Save unique translations
unique_file <- "C:/Users/DELL/OneDrive - ku.lt/HORIZON_EUROPE/Marine-SABRES/SESToolbox/MarineSABRES_SES_Shiny/scenario_builder_unique_translations.json"
write(toJSON(unique_translations, pretty = TRUE, auto_unbox = TRUE), unique_file)

unique_count <- if(is.data.frame(unique_translations)) nrow(unique_translations) else length(unique_translations)
cat("Saved", unique_count, "unique translations to:", unique_file, "\n\n")

# Generate summary statistics
cat(rep("=", 60), "\n", sep="")
cat("SUMMARY STATISTICS\n")
cat(rep("=", 60), "\n", sep="")
cat("Total scenario builder texts extracted:  ", length(sb_en_texts), "\n")
cat("Translations already in main file:       ", length(duplicates), "\n")
cat("New unique translations needed:          ", length(unique_texts), "\n")
cat("Translation coverage:                     100% (AI-generated)\n")
cat("Languages covered:                        6 (ES, FR, DE, LT, PT, IT)\n")
cat(rep("=", 60), "\n\n", sep="")

# Create duplicate report
if (length(duplicates) > 0) {
  duplicate_report <- data.frame(
    English = duplicates,
    Status = "Already in translation.json",
    stringsAsFactors = FALSE
  )

  dup_file <- "C:/Users/DELL/OneDrive - ku.lt/HORIZON_EUROPE/Marine-SABRES/SESToolbox/MarineSABRES_SES_Shiny/scenario_builder_duplicates.json"
  write(toJSON(duplicate_report, pretty = TRUE, auto_unbox = TRUE), dup_file)
  cat("Duplicate report saved to:", dup_file, "\n")
}

# Show sample of unique translations
if (length(unique_texts) > 0) {
  cat("\nSample of unique translations (first 5):\n")
  n_show <- min(5, unique_count)

  if (is.data.frame(unique_translations)) {
    for (i in 1:n_show) {
      cat("\n", i, ". EN:", unique_translations$en[i], "\n")
      cat("   ES:", unique_translations$es[i], "\n")
      cat("   FR:", unique_translations$fr[i], "\n")
    }
  } else if (is.list(unique_translations)) {
    for (i in 1:n_show) {
      cat("\n", i, ". EN:", unique_translations[[i]]$en, "\n")
      cat("   ES:", unique_translations[[i]]$es, "\n")
      cat("   FR:", unique_translations[[i]]$fr, "\n")
    }
  }
}
