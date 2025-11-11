#!/usr/bin/env Rscript
# Diagnostic Script for i18n Issues
# Checks translation.json for specific tooltip texts

library(jsonlite)

cat("=== i18n Diagnostic Tool ===\n\n")

# Load translation file
cat("1. Loading translation.json...\n")
trans <- fromJSON("translations/translation.json")
cat("   Loaded", length(trans$translation), "translation entries\n\n")

# Tooltip texts we're looking for
tooltip_texts <- c(
  "Skip if you're not sure or want to see all options",
  "Proceed to identify your basic human needs",
  "Return to role selection",
  "Skip if multiple needs apply or you're unsure",
  "Proceed to specify activities and risks",
  "Return to basic needs",
  "Your role helps us recommend the most relevant tools and workflows for your marine management context.",
  "Understanding the fundamental human need behind your question helps identify relevant ecosystem services and management priorities.",
  "Select the human activities relevant to your marine management question. These represent the 'Drivers' and 'Activities' in the DAPSI(W)R(M) framework.",
  "Select the environmental pressures, risks, or hazards you're concerned about. These represent 'Pressures' and 'State changes' in the DAPSI(W)R(M) framework.",
  "Skip if you want to explore all activities and risks",
  "Proceed to select knowledge topics",
  "Select the knowledge domains and analytical approaches relevant to your question. This helps match you with appropriate analysis tools and frameworks.",
  "Return to activities and risks",
  "Skip to see all available tools",
  "Get personalized tool recommendations based on your pathway",
  "Your Pathway Summary"
)

cat("2. Checking tooltip translations...\n\n")

found_count <- 0
missing_count <- 0

for(text in tooltip_texts) {
  # Search for exact match
  idx <- which(sapply(trans$translation, function(x) {
    !is.null(x$en) && x$en == text
  }))

  if(length(idx) > 0) {
    found_count <- found_count + 1
    cat("   ✓ FOUND:", substr(text, 1, 60), "...\n")

    # Show Spanish translation as example
    es_text <- trans$translation[[idx[1]]]$es
    if(!is.null(es_text)) {
      cat("     ES: ", substr(es_text, 1, 60), "...\n")
    }
  } else {
    missing_count <- missing_count + 1
    cat("   ✗ MISSING:", substr(text, 1, 60), "...\n")

    # Try to find similar text
    similar <- sapply(trans$translation, function(x) {
      if(is.null(x$en)) return(FALSE)
      grepl(substr(text, 1, 20), x$en, fixed=TRUE)
    })

    if(any(similar)) {
      similar_idx <- which(similar)[1]
      cat("     SIMILAR: ", substr(trans$translation[[similar_idx]]$en, 1, 60), "...\n")
    }
  }
  cat("\n")
}

cat("\n=== Summary ===\n")
cat("Total tooltip texts checked:", length(tooltip_texts), "\n")
cat("Found in translation.json:", found_count, "\n")
cat("Missing from translation.json:", missing_count, "\n")

if(missing_count > 0) {
  cat("\n⚠ WARNING: Some tooltip texts are missing!\n")
  cat("These tooltips will NOT translate and will show the key text instead.\n")
} else {
  cat("\n✓ All tooltip texts found in translation.json!\n")
  cat("If tooltips still don't translate, the issue is likely that:\n")
  cat("  1. Tooltips are in static UI (not reactive)\n")
  cat("  2. Bootstrap tooltips need re-initialization after language change\n")
}

cat("\n3. Checking for duplicate translations...\n")
seen <- list()
duplicates <- 0

for(i in seq_along(trans$translation)) {
  en_text <- trans$translation[[i]]$en
  if(!is.null(en_text)) {
    if(!is.null(seen[[en_text]])) {
      duplicates <- duplicates + 1
      cat("   DUPLICATE at index", i, ":", substr(en_text, 1, 60), "...\n")
      cat("   First seen at index:", seen[[en_text]], "\n")
    } else {
      seen[[en_text]] <- i
    }
  }
}

if(duplicates > 0) {
  cat("\n⚠ WARNING:", duplicates, "duplicate translations found!\n")
  cat("This will cause 'duplicate row.names' error on app startup.\n")
} else {
  cat("\n✓ No duplicates found!\n")
}

cat("\n=== Diagnostic Complete ===\n")
