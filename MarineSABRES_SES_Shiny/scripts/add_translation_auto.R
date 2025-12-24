#!/usr/bin/env Rscript
# scripts/add_translation_auto.R
# Automated translation addition tool with minimal interaction
# Intelligently determines file placement and can extract from legacy file

suppressPackageStartupMessages({
  library(jsonlite)
})

# ============================================================================
# CONFIGURATION
# ============================================================================

REQUIRED_LANGUAGES <- c("en", "es", "fr", "de", "lt", "pt", "it")
LEGACY_FILE <- "translations/translation.json.backup"

# ============================================================================
# SMART FILE SELECTION
# ============================================================================

#' Auto-detect which file a translation belongs to
detect_target_file <- function(key) {
  key_lower <- tolower(key)

  # Common buttons/actions
  if (grepl("^(save|cancel|close|delete|edit|add|remove|apply|ok|yes|no|back|next|submit|update|create|export|import|load|download|upload|refresh|reset|clear|confirm|accept|reject)$",
            key_lower)) {
    return("translations/common/buttons.json")
  }

  # Common labels
  if (grepl("(name|title|description|type|category|status|date|time|id|label|field)$", key_lower) &&
      !grepl("(error|warning|success)", key_lower)) {
    return("translations/common/labels.json")
  }

  # Messages (success, error, warning, info)
  if (grepl("(success|error|warning|info|message|notification|alert|saved|loaded|updated|deleted|failed|completed)", key_lower)) {
    return("translations/common/messages.json")
  }

  # Validation messages
  if (grepl("(required|invalid|must|cannot|should|please|enter|select|choose)", key_lower)) {
    return("translations/common/validation.json")
  }

  # Framework terms
  if (grepl("(driver|activity|pressure|state|impact|response|measure|welfare|ecosystem|marine|dapsiwrm?)", key_lower)) {
    return("translations/_framework.json")
  }

  # Navigation
  if (grepl("(dashboard|menu|tab|panel|section|page|home|about|help|settings)", key_lower)) {
    return("translations/common/navigation.json")
  }

  # Header elements
  if (grepl("(header|toolbar|project|language|user)", key_lower)) {
    return("translations/ui/header.json")
  }

  # Sidebar elements
  if (grepl("(sidebar|nav|navigation|tree|menu)", key_lower)) {
    return("translations/ui/sidebar.json")
  }

  # Modal elements
  if (grepl("(modal|dialog|popup|confirm)", key_lower)) {
    return("translations/ui/modals.json")
  }

  # Node types
  if (grepl("(node|element|component)", key_lower)) {
    return("translations/data/node_types.json")
  }

  # Default to messages for general text
  return("translations/common/messages.json")
}

#' Generate namespaced key from English text
generate_key <- function(text, target_file) {
  # Extract category from file path
  if (grepl("common/buttons", target_file)) {
    category <- "common.buttons"
  } else if (grepl("common/labels", target_file)) {
    category <- "common.labels"
  } else if (grepl("common/messages", target_file)) {
    category <- "common.messages"
  } else if (grepl("common/validation", target_file)) {
    category <- "common.validation"
  } else if (grepl("common/navigation", target_file)) {
    category <- "common.navigation"
  } else if (grepl("ui/header", target_file)) {
    category <- "ui.header"
  } else if (grepl("ui/sidebar", target_file)) {
    category <- "ui.sidebar"
  } else if (grepl("ui/modals", target_file)) {
    category <- "ui.modals"
  } else if (grepl("data/node_types", target_file)) {
    category <- "data.node_types"
  } else if (grepl("_framework", target_file)) {
    category <- "framework"
  } else {
    category <- "common.other"
  }

  # Generate key from text
  key_part <- tolower(text)
  key_part <- gsub("[^a-z0-9 ]", "", key_part)  # Remove special chars
  key_part <- gsub(" +", "_", key_part)          # Spaces to underscores
  key_part <- substr(key_part, 1, 50)            # Limit length

  paste0(category, ".", key_part)
}

# ============================================================================
# LEGACY FILE EXTRACTION
# ============================================================================

#' Extract translation from legacy file
extract_from_legacy <- function(english_key) {
  if (!file.exists(LEGACY_FILE)) {
    return(NULL)
  }

  tryCatch({
    legacy <- fromJSON(LEGACY_FILE, simplifyVector = FALSE)

    # Search for the English key
    for (entry in legacy$translation) {
      if (!is.null(entry$en) && entry$en == english_key) {
        # Found it! Return the entry
        result <- list()
        for (lang in REQUIRED_LANGUAGES) {
          if (!is.null(entry[[lang]])) {
            result[[lang]] <- entry[[lang]]
          } else {
            result[[lang]] <- paste0("[MISSING: ", lang, "]")
          }
        }
        return(result)
      }
    }

    return(NULL)
  }, error = function(e) {
    return(NULL)
  })
}

# ============================================================================
# TRANSLATION ADDITION
# ============================================================================

#' Add translation to file
add_to_file <- function(target_file, entry, verbose = TRUE) {
  # Ensure directory exists
  dir.create(dirname(target_file), showWarnings = FALSE, recursive = TRUE)

  # Load or create file
  if (file.exists(target_file)) {
    data <- fromJSON(target_file, simplifyVector = FALSE)
  } else {
    data <- list(
      languages = REQUIRED_LANGUAGES,
      translation = list()
    )
  }

  # Check for duplicate
  if (!is.null(data$translation)) {
    for (existing in data$translation) {
      if (!is.null(existing$en) && !is.null(entry$en) &&
          existing$en == entry$en) {
        if (verbose) {
          cat(sprintf("  ⚠ Skipped (duplicate): %s\n", substr(entry$en, 1, 50)))
        }
        return(FALSE)
      }
    }
  }

  # Add entry
  data$translation <- c(data$translation, list(entry))

  # Save
  tryCatch({
    write_json(data, target_file, pretty = TRUE, auto_unbox = TRUE)
    if (verbose) {
      cat(sprintf("  ✓ Added: %s\n", substr(entry$en, 1, 60)))
    }
    return(TRUE)
  }, error = function(e) {
    if (verbose) {
      cat(sprintf("  ✗ Error: %s\n", e$message))
    }
    return(FALSE)
  })
}

# ============================================================================
# BATCH PROCESSING
# ============================================================================

#' Process translations from file (one English key per line)
process_batch_file <- function(input_file, extract_from_legacy = TRUE,
                               auto_detect_file = TRUE, verbose = TRUE) {

  if (!file.exists(input_file)) {
    cat(sprintf("Error: File not found: %s\n", input_file))
    return(invisible(FALSE))
  }

  keys <- readLines(input_file, warn = FALSE)
  keys <- keys[keys != ""]  # Remove empty lines
  keys <- unique(keys)      # Remove duplicates

  cat(sprintf("\n=== Batch Processing: %d translations ===\n\n", length(keys)))

  success_count <- 0
  skipped_count <- 0
  error_count <- 0

  # Group by target file
  file_groups <- list()

  for (key in keys) {
    target_file <- if (auto_detect_file) {
      detect_target_file(key)
    } else {
      "translations/common/messages.json"
    }

    if (is.null(file_groups[[target_file]])) {
      file_groups[[target_file]] <- list()
    }

    file_groups[[target_file]] <- c(file_groups[[target_file]], key)
  }

  # Process each file group
  for (target_file in names(file_groups)) {
    cat(sprintf("\nProcessing %d entries for %s\n",
               length(file_groups[[target_file]]), basename(target_file)))

    for (key in file_groups[[target_file]]) {
      # Try to extract from legacy file first
      entry <- NULL

      if (extract_from_legacy) {
        entry <- extract_from_legacy(key)
      }

      if (!is.null(entry)) {
        # Found in legacy file
        entry_with_key <- list(
          key = generate_key(key, target_file),
          en = key
        )
        for (lang in REQUIRED_LANGUAGES) {
          if (lang != "en" && !is.null(entry[[lang]])) {
            entry_with_key[[lang]] <- entry[[lang]]
          }
        }

        # Remove missing markers
        for (lang in names(entry_with_key)) {
          if (is.character(entry_with_key[[lang]]) &&
              grepl("^\\[MISSING:", entry_with_key[[lang]])) {
            entry_with_key[[lang]] <- paste0("TODO: ", lang, " translation")
          }
        }

        if (add_to_file(target_file, entry_with_key, verbose)) {
          success_count <- success_count + 1
        } else {
          skipped_count <- skipped_count + 1
        }
      } else {
        # Not in legacy file - create placeholder
        entry_new <- list(
          key = generate_key(key, target_file),
          en = key
        )

        for (lang in setdiff(REQUIRED_LANGUAGES, "en")) {
          entry_new[[lang]] <- paste0("TODO: ", lang, " translation")
        }

        if (add_to_file(target_file, entry_new, verbose)) {
          success_count <- success_count + 1
        } else {
          skipped_count <- skipped_count + 1
        }
      }
    }
  }

  cat(sprintf("\n=== Summary ===\n"))
  cat(sprintf("Processed: %d\n", length(keys)))
  cat(sprintf("Added: %d\n", success_count))
  cat(sprintf("Skipped (duplicates): %d\n", skipped_count))
  cat(sprintf("Errors: %d\n", error_count))

  return(invisible(TRUE))
}

#' Interactive single translation (simplified)
add_single_interactive <- function() {
  cat("\n=== Quick Add Translation ===\n\n")

  # Get English text
  cat("Enter English text: ")
  english <- readLines("stdin", n = 1)

  if (english == "") {
    cat("Cancelled.\n")
    return(invisible(FALSE))
  }

  # Auto-detect file
  target_file <- detect_target_file(english)
  cat(sprintf("\nAuto-detected file: %s\n", basename(target_file)))

  cat("Use this file? (Y/n): ")
  response <- tolower(readLines("stdin", n = 1))

  if (response == "n" || response == "no") {
    cat("\nSelect file:\n")
    cat("1. common/buttons.json\n")
    cat("2. common/labels.json\n")
    cat("3. common/messages.json\n")
    cat("4. common/validation.json\n")
    cat("5. ui/header.json\n")
    cat("6. ui/sidebar.json\n")
    cat("7. ui/modals.json\n")
    cat("8. _framework.json\n")

    cat("\nEnter number (1-8): ")
    choice <- as.integer(readLines("stdin", n = 1))

    target_file <- switch(choice,
      "translations/common/buttons.json",
      "translations/common/labels.json",
      "translations/common/messages.json",
      "translations/common/validation.json",
      "translations/ui/header.json",
      "translations/ui/sidebar.json",
      "translations/ui/modals.json",
      "translations/_framework.json",
      target_file  # Default to auto-detected
    )
  }

  # Try to extract from legacy
  cat("\nSearching legacy file for existing translation...\n")
  legacy_entry <- extract_from_legacy(english)

  if (!is.null(legacy_entry)) {
    cat("✓ Found in legacy file!\n\n")
    cat("Translations:\n")
    for (lang in REQUIRED_LANGUAGES) {
      if (!is.null(legacy_entry[[lang]])) {
        cat(sprintf("  %s: %s\n", toupper(lang), legacy_entry[[lang]]))
      }
    }

    cat("\nUse these translations? (Y/n): ")
    response <- tolower(readLines("stdin", n = 1))

    if (response != "n" && response != "no") {
      entry <- list(
        key = generate_key(english, target_file),
        en = english
      )
      for (lang in setdiff(REQUIRED_LANGUAGES, "en")) {
        if (!is.null(legacy_entry[[lang]])) {
          entry[[lang]] <- legacy_entry[[lang]]
        } else {
          entry[[lang]] <- paste0("TODO: ", lang, " translation")
        }
      }

      if (add_to_file(target_file, entry, TRUE)) {
        cat("\n✓ Translation added successfully!\n")
        return(invisible(TRUE))
      } else {
        cat("\n✗ Failed to add translation\n")
        return(invisible(FALSE))
      }
    }
  }

  # Manual entry (minimal)
  cat("\nNot found in legacy file. Enter translations:\n")
  cat("(Press Enter to use placeholder)\n\n")

  entry <- list(
    key = generate_key(english, target_file),
    en = english
  )

  for (lang in setdiff(REQUIRED_LANGUAGES, "en")) {
    cat(sprintf("%s: ", toupper(lang)))
    translation <- readLines("stdin", n = 1)

    if (translation == "") {
      entry[[lang]] <- paste0("TODO: ", lang, " translation")
      cat(sprintf("  Using placeholder: TODO: %s translation\n", lang))
    } else {
      entry[[lang]] <- translation
    }
  }

  if (add_to_file(target_file, entry, TRUE)) {
    cat("\n✓ Translation added successfully!\n")
    return(invisible(TRUE))
  } else {
    cat("\n✗ Failed to add translation\n")
    return(invisible(FALSE))
  }
}

# ============================================================================
# MAIN
# ============================================================================

args <- commandArgs(trailingOnly = TRUE)

if (length(args) == 0) {
  # Interactive mode
  cat("\n╔═══════════════════════════════════════════╗\n")
  cat("║  Auto Translation Tool                   ║\n")
  cat("╚═══════════════════════════════════════════╝\n")

  add_single_interactive()

} else if (args[1] == "--help") {
  cat("Automated Translation Addition Tool\n\n")
  cat("Usage:\n")
  cat("  Rscript scripts/add_translation_auto.R                 # Interactive single\n")
  cat("  Rscript scripts/add_translation_auto.R FILE.txt        # Batch from file\n")
  cat("  Rscript scripts/add_translation_auto.R --no-legacy FILE.txt  # Don't use legacy\n\n")
  cat("File format (one English key per line):\n")
  cat("  Save\n")
  cat("  Cancel\n")
  cat("  Load Project\n")
  cat("  ...\n\n")
  cat("Features:\n")
  cat("  - Auto-detects target file based on key patterns\n")
  cat("  - Extracts translations from legacy file if available\n")
  cat("  - Generates namespaced keys automatically\n")
  cat("  - Minimal interaction required\n")

} else {
  # Batch mode
  use_legacy <- !("--no-legacy" %in% args)
  input_file <- args[length(args)]

  process_batch_file(input_file, extract_from_legacy = use_legacy)

  cat("\nNext steps:\n")
  cat("  1. Review added translations\n")
  cat("  2. Validate: Rscript scripts/validate_translations.R\n")
  cat("  3. Test: Rscript scripts/test_translations.R\n")
}
