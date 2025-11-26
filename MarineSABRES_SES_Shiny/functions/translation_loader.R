# functions/translation_loader.R
# Modular Translation Loading System for MarineSABRES SES Toolbox

#' Load and Merge Translation Files
#'
#' Recursively loads all JSON translation files from the translations directory
#' and merges them into a single translation object compatible with shiny.i18n
#'
#' @param base_path Base path to translations directory (default: "translations")
#' @param debug Print debug information (default: FALSE)
#' @return A merged translation list compatible with shiny.i18n
#' @export
load_translations <- function(base_path = "translations", debug = FALSE) {

  if (!requireNamespace("jsonlite", quietly = TRUE)) {
    stop("Package 'jsonlite' is required but not installed")
  }

  # Find all JSON files recursively (exclude backup files)
  json_files <- list.files(
    path = base_path,
    pattern = "\\.json$",
    full.names = TRUE,
    recursive = TRUE
  )

  # Exclude backup files - be aggressive to avoid duplicates
  json_files <- json_files[!grepl("backup|translation\\.json$", json_files, ignore.case = TRUE)]

  # Only include modular files (those with underscores or in subdirectories)
  # This excludes old monolithic translation.json files
  json_files <- json_files[grepl("(_[a-z]+\\.json$|/common/|/modules/|/ui/|/data/)", json_files)]

  if (length(json_files) == 0) {
    stop(sprintf("No translation files found in %s", base_path))
  }

  if (debug) {
    cat(sprintf("[TRANSLATION LOADER] Found %d translation files\n", length(json_files)))
  }

  # Initialize with language list from first file
  tryCatch({
    first_file <- jsonlite::fromJSON(json_files[1], simplifyVector = FALSE)
    languages <- first_file$languages
  }, error = function(e) {
    stop(sprintf("Error reading first file %s: %s", json_files[1], e$message))
  })

  # Initialize merged translation list
  merged_translations <- list()
  glossary <- list()

  # Track statistics
  file_count <- 0
  entry_count <- 0
  glossary_count <- 0

  # Load each file and merge
  for (file_path in json_files) {
    if (debug) {
      cat(sprintf("[TRANSLATION LOADER] Loading: %s\n", basename(file_path)))
    }

    tryCatch({
      data <- jsonlite::fromJSON(file_path, simplifyVector = FALSE)

      # Validate languages match
      if (!is.null(data$languages) && !identical(data$languages, languages)) {
        warning(sprintf(
          "Language mismatch in %s. Expected: %s, Found: %s",
          basename(file_path),
          paste(languages, collapse = ", "),
          paste(data$languages, collapse = ", ")
        ))
      }

      # Handle glossary files
      if (!is.null(data$glossary)) {
        glossary <- c(glossary, data$glossary)
        glossary_count <- glossary_count + length(data$glossary)
      }

      # Handle regular translation files
      if (!is.null(data$translation)) {
        merged_translations <- c(merged_translations, data$translation)
        entry_count <- entry_count + length(data$translation)
      }

      file_count <- file_count + 1

    }, error = function(e) {
      warning(sprintf("Error loading %s: %s", basename(file_path), e$message))
    })
  }

  # Deduplicate merged_translations BEFORE creating final structure
  # Keep first occurrence of each English text (files loaded in order)
  if (length(merged_translations) > 0) {
    en_values <- sapply(merged_translations, function(entry) {
      if (!is.null(entry$en)) entry$en else ""
    })

    # Find duplicates
    duplicate_indices <- which(duplicated(en_values) & en_values != "")

    if (length(duplicate_indices) > 0 && debug) {
      cat(sprintf("[TRANSLATION LOADER] Removing %d duplicate entries from modular files\n",
                  length(duplicate_indices)))
      for (idx in duplicate_indices) {
        cat(sprintf("  - Duplicate: '%s'\n", en_values[idx]))
      }
    }

    # Remove duplicates (keep first occurrence)
    if (length(duplicate_indices) > 0) {
      merged_translations <- merged_translations[-duplicate_indices]
      entry_count <- entry_count - length(duplicate_indices)
    }
  }

  # Create final structure compatible with shiny.i18n
  result <- list(
    languages = languages,
    translation = merged_translations
  )

  # Add glossary if present (optional metadata)
  if (length(glossary) > 0) {
    result$glossary <- glossary
  }

  if (debug) {
    cat(sprintf("[TRANSLATION LOADER] Summary:\n"))
    cat(sprintf("  - Loaded %d files\n", file_count))
    cat(sprintf("  - Total translation entries: %d\n", entry_count))
    cat(sprintf("  - Total glossary terms: %d\n", glossary_count))
    cat(sprintf("  - Languages: %s\n", paste(languages, collapse = ", ")))
  }

  return(result)
}

#' Save Merged Translations to File
#'
#' Saves merged translations to a JSON file for use by shiny.i18n
#'
#' @param translations Merged translation list
#' @param debug Print debug information (default: FALSE)
#' @param persistent Use persistent file in translations directory instead of temp (default: FALSE)
#' @return Path to JSON file
#' @export
save_merged_translations <- function(translations, debug = FALSE, persistent = FALSE) {

  if (!requireNamespace("jsonlite", quietly = TRUE)) {
    stop("Package 'jsonlite' is required but not installed")
  }

  # Create file path - persistent or temp
  if (persistent) {
    temp_file <- file.path("translations", "_merged_translations.json")
    if (debug) {
      cat(sprintf("[TRANSLATION LOADER] Using persistent file: %s\n", temp_file))
    }
  } else {
    temp_file <- tempfile(pattern = "marinesabres_translations_", fileext = ".json")
    if (debug) {
      cat(sprintf("[TRANSLATION LOADER] Using temp file: %s\n", temp_file))
    }
  }

  # Convert to JSON and write
  tryCatch({
    json_text <- jsonlite::toJSON(translations, pretty = TRUE, auto_unbox = TRUE)
    writeLines(json_text, temp_file)

    if (debug) {
      file_size <- file.info(temp_file)$size
      cat(sprintf("[TRANSLATION LOADER] Saved merged translations to: %s (%s bytes)\n",
                  temp_file, format(file_size, big.mark = ",")))
    }

    return(temp_file)

  }, error = function(e) {
    stop(sprintf("Error saving merged translations: %s", e$message))
  })
}

#' Validate Translation Completeness
#'
#' Checks that all translation entries have values for all languages
#'
#' @param translations Translation list
#' @param debug Print debug information (default: FALSE)
#' @return List of validation issues (empty if all valid)
#' @export
validate_translations <- function(translations, debug = FALSE) {

  languages <- translations$languages
  entries <- translations$translation

  if (is.null(entries) || length(entries) == 0) {
    return(list(error = "No translation entries found"))
  }

  issues <- list()

  for (i in seq_along(entries)) {
    entry <- entries[[i]]

    # Determine entry identifier (key or English text)
    if (!is.null(entry$key)) {
      key <- entry$key
    } else if (!is.null(entry$en)) {
      key <- entry$en  # Fallback to English for flat-key entries
    } else {
      key <- sprintf("Entry #%d", i)
    }

    # Check each language
    for (lang in languages) {
      if (is.null(entry[[lang]]) || entry[[lang]] == "") {
        issues[[length(issues) + 1]] <- list(
          entry_index = i,
          key = key,
          language = lang,
          problem = "missing translation"
        )
      }
    }

    # Check for very long translations (potential formatting issues)
    for (lang in languages) {
      if (!is.null(entry[[lang]]) && nchar(entry[[lang]]) > 500) {
        issues[[length(issues) + 1]] <- list(
          entry_index = i,
          key = key,
          language = lang,
          problem = sprintf("very long translation (%d chars)", nchar(entry[[lang]]))
        )
      }
    }
  }

  # Report results
  if (length(issues) > 0) {
    if (debug) {
      cat(sprintf("[TRANSLATION VALIDATOR] Found %d issues:\n", length(issues)))
      for (issue in head(issues, 10)) {
        cat(sprintf("  - Entry #%d (%s): %s in %s\n",
                    issue$entry_index,
                    substr(issue$key, 1, 50),
                    issue$problem,
                    issue$language))
      }
      if (length(issues) > 10) {
        cat(sprintf("  ... and %d more issues\n", length(issues) - 10))
      }
    }
  } else {
    if (debug) {
      cat("[TRANSLATION VALIDATOR] All translations are complete!\n")
    }
  }

  return(issues)
}

#' Get Translation Statistics
#'
#' Returns statistics about the translation system
#'
#' @param translations Translation list
#' @return List of statistics
#' @export
get_translation_stats <- function(translations) {

  languages <- translations$languages
  entries <- translations$translation

  # Count entries per language
  lang_counts <- sapply(languages, function(lang) {
    sum(sapply(entries, function(entry) {
      !is.null(entry[[lang]]) && entry[[lang]] != ""
    }))
  })

  # Count total characters per language
  char_counts <- sapply(languages, function(lang) {
    sum(sapply(entries, function(entry) {
      if (!is.null(entry[[lang]])) nchar(entry[[lang]]) else 0
    }))
  })

  # Count namespaced vs flat keys
  namespaced_count <- sum(sapply(entries, function(entry) {
    !is.null(entry$key) && grepl("\\.", entry$key)
  }))

  flat_key_count <- sum(sapply(entries, function(entry) {
    is.null(entry$key) || !grepl("\\.", entry$key)
  }))

  stats <- list(
    total_entries = length(entries),
    languages = languages,
    entries_per_language = as.list(lang_counts),
    characters_per_language = as.list(char_counts),
    namespaced_keys = namespaced_count,
    flat_keys = flat_key_count,
    glossary_terms = if (!is.null(translations$glossary)) length(translations$glossary) else 0
  )

  return(stats)
}

#' Initialize Modular Translation System
#'
#' Main function to initialize the modular translation system for use in global.R
#' Supports hybrid mode where both old flat keys and new namespaced keys work together
#'
#' @param base_path Base path to translations directory (default: "translations")
#' @param validate Run validation checks (default: FALSE)
#' @param debug Print debug information (default: FALSE)
#' @param include_legacy Include legacy translation.json.backup for backwards compatibility (default: TRUE)
#' @param persistent Save to persistent file instead of temp file (default: TRUE)
#' @return Path to merged translation JSON file
#' @export
init_modular_translations <- function(base_path = "translations",
                                      validate = FALSE,
                                      debug = FALSE,
                                      include_legacy = TRUE,
                                      persistent = TRUE) {

  if (debug) {
    cat("[TRANSLATION SYSTEM] Initializing modular translation system...\n")
  }

  # Load and merge all translation files
  merged_translations <- load_translations(base_path, debug = debug)

  # If include_legacy, also load the old translation.json.backup and merge
  if (include_legacy && file.exists(file.path(base_path, "translation.json.backup"))) {
    if (debug) {
      cat("[TRANSLATION SYSTEM] Loading legacy translations for backwards compatibility...\n")
    }

    tryCatch({
      legacy <- jsonlite::fromJSON(
        file.path(base_path, "translation.json.backup"),
        simplifyVector = FALSE
      )

      # Append legacy translations (modular takes precedence by being first)
      if (!is.null(legacy$translation)) {
        # Extract keys from modular translations (use "en" field as key for flat-key system)
        modular_keys <- sapply(merged_translations$translation, function(entry) {
          if (!is.null(entry$en)) entry$en else ""
        })

        # Filter out legacy entries that duplicate modular keys
        legacy_filtered <- Filter(function(entry) {
          key <- if (!is.null(entry$en)) entry$en else ""
          !(key %in% modular_keys)
        }, legacy$translation)

        # Append filtered legacy translations
        merged_translations$translation <- c(
          merged_translations$translation,
          legacy_filtered
        )

        if (debug) {
          cat(sprintf("[TRANSLATION SYSTEM] Added %d legacy translations (%d duplicates removed)\n",
                      length(legacy_filtered),
                      length(legacy$translation) - length(legacy_filtered)))
        }
      }
    }, error = function(e) {
      warning(sprintf("Could not load legacy translations: %s", e$message))
    })
  }

  # Validate if requested
  if (validate) {
    issues <- validate_translations(merged_translations, debug = debug)
    if (length(issues) > 0 && debug) {
      warning(sprintf("Found %d translation issues. See debug output for details.", length(issues)))
    }
  }

  # Get statistics if debug mode
  if (debug) {
    stats <- get_translation_stats(merged_translations)
    cat(sprintf("[TRANSLATION SYSTEM] Statistics:\n"))
    cat(sprintf("  - Total entries: %d\n", stats$total_entries))
    cat(sprintf("  - Namespaced keys: %d\n", stats$namespaced_keys))
    cat(sprintf("  - Flat keys: %d\n", stats$flat_keys))
  }

  # Save to file (persistent or temp)
  temp_file <- save_merged_translations(merged_translations, debug = debug, persistent = persistent)

  if (debug) {
    cat("[TRANSLATION SYSTEM] Initialization complete!\n")
  }

  return(temp_file)
}
