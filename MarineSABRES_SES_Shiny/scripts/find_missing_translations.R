#!/usr/bin/env Rscript
# scripts/find_missing_translations.R
# Find translation keys used in code but not defined in translation files

# Load translation system
source("functions/translation_loader.R")

# Get all defined translations
cat("Loading translations...\n")
merged <- load_translations("translations", debug = FALSE)

# Extract English keys (used as the primary identifier)
defined_keys <- sapply(merged$translation, function(x) {
  if (!is.null(x$en)) x$en else ""
})
defined_keys <- defined_keys[defined_keys != ""]

cat(sprintf("Defined translations: %d\n", length(defined_keys)))

# Find all i18n$t() calls in code
cat("\nScanning code for i18n$t() calls...\n")

scan_dir <- function(dir) {
  r_files <- list.files(dir, pattern = "\\.R$", full.names = TRUE, recursive = TRUE)

  all_keys <- character()

  for (file in r_files) {
    content <- tryCatch({
      readLines(file, warn = FALSE)
    }, error = function(e) {
      character(0)
    })

    if (length(content) == 0) next

    # Combine all content to search
    full_content <- paste(content, collapse = "\n")

    # Find patterns like i18n$t("key") or i18n$t('key')
    pattern <- 'i18n\\$t\\(["\']([^"\']+)["\']'
    matches <- gregexpr(pattern, full_content, perl = TRUE)

    if (matches[[1]][1] != -1) {
      matched_text <- regmatches(full_content, matches)[[1]]
      for (match in matched_text) {
        # Extract the key
        key <- gsub('i18n\\$t\\(["\']([^"\']+)["\'].*', '\\1', match)
        all_keys <- c(all_keys, key)
      }
    }
  }

  unique(all_keys)
}

# Scan main directories
used_keys <- c()
for (dir in c(".", "modules", "functions", "server")) {
  if (dir.exists(dir)) {
    keys <- scan_dir(dir)
    used_keys <- c(used_keys, keys)
  }
}

used_keys <- unique(used_keys)

cat(sprintf("Keys used in code: %d\n", length(used_keys)))

# Find missing
missing <- setdiff(used_keys, defined_keys)
unused <- setdiff(defined_keys, used_keys)

cat("\n=== RESULTS ===\n\n")

if (length(missing) > 0) {
  cat(sprintf("MISSING TRANSLATIONS: %d keys used in code but not in translation files\n\n",
              length(missing)))

  # Group by likely category
  common_buttons <- missing[grepl("^(Save|Cancel|Close|Delete|Edit|Add|Remove|Apply|OK|Yes|No|Back|Next|Submit|Update|Create|Export|Import|Load|Download|Upload)$", missing)]
  common_messages <- missing[grepl("(success|error|warning|info|message|notification)", missing, ignore.case = TRUE)]
  framework <- missing[grepl("(driver|activity|pressure|state|impact|response|measure|welfare|ecosystem|marine)", missing, ignore.case = TRUE)]

  if (length(common_buttons) > 0) {
    cat("Common Buttons/Actions:\n")
    for (key in head(common_buttons, 20)) {
      cat(sprintf("  - %s\n", key))
    }
    if (length(common_buttons) > 20) {
      cat(sprintf("  ... and %d more\n", length(common_buttons) - 20))
    }
    cat("\n")
  }

  if (length(common_messages) > 0) {
    cat("Messages/Notifications:\n")
    for (key in head(common_messages, 20)) {
      cat(sprintf("  - %s\n", key))
    }
    if (length(common_messages) > 20) {
      cat(sprintf("  ... and %d more\n", length(common_messages) - 20))
    }
    cat("\n")
  }

  if (length(framework) > 0) {
    cat("Framework Terms:\n")
    for (key in head(framework, 20)) {
      cat(sprintf("  - %s\n", key))
    }
    if (length(framework) > 20) {
      cat(sprintf("  ... and %d more\n", length(framework) - 20))
    }
    cat("\n")
  }

  # Show others
  others <- setdiff(missing, c(common_buttons, common_messages, framework))
  if (length(others) > 0) {
    cat("Other Missing Keys:\n")
    for (key in head(others, 30)) {
      cat(sprintf("  - %s\n", key))
    }
    if (length(others) > 30) {
      cat(sprintf("  ... and %d more\n", length(others) - 30))
    }
    cat("\n")
  }

  # Save to file for batch processing
  writeLines(missing, "missing_translations.txt")
  cat(sprintf("Full list saved to: missing_translations.txt\n\n"))

} else {
  cat("✓ No missing translations found!\n")
  cat("All keys used in code are defined in translation files.\n\n")
}

if (length(unused) > 10) {
  cat(sprintf("Note: %d translation keys are defined but not used in code.\n", length(unused)))
  cat("Run 'Rscript scripts/translation_workflow.R find_unused' for details.\n\n")
}

# Exit
if (length(missing) > 0) {
  cat("Next steps:\n")
  cat("  1. Review missing_translations.txt\n")
  cat("  2. Use: Rscript scripts/add_translation_auto.R missing_translations.txt\n")
  cat("  3. Or add them manually with: Rscript scripts/add_translation.R\n")
}
