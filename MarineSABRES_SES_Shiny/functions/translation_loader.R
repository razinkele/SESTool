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

  # Exclude backup files and generated merged files - be aggressive to avoid duplicates
  json_files <- json_files[!grepl("backup|translation\\.json$|_merged_translations\\.json$", json_files, ignore.case = TRUE)]

  # Exclude legacy flat-key files (ui_flat_keys.json) that don't have "key" fields
  json_files <- json_files[!grepl("ui_flat_keys\\.json$", json_files, ignore.case = TRUE)]

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

      # Handle regular translation files (support both array and object formats)
      if (!is.null(data$translation)) {
        # Detect format: array (has numeric indices) vs object (has character names)
        is_object_format <- !is.null(names(data$translation)) &&
                           all(names(data$translation) != "")

        if (is_object_format) {
          # Object-based format: {key: {en: "...", es: "..."}}
          # Merge by combining named lists
          for (key in names(data$translation)) {
            merged_translations[[key]] <- data$translation[[key]]
          }
          entry_count <- entry_count + length(data$translation)
        } else {
          # Array-based format: [{key: "...", en: "...", es: "..."}]
          # Merge by concatenating lists
          merged_translations <- c(merged_translations, data$translation)
          entry_count <- entry_count + length(data$translation)
        }
      }

      file_count <- file_count + 1

    }, error = function(e) {
      warning(sprintf("Error loading %s: %s", basename(file_path), e$message))
    })
  }

  # Pure modular system - no deduplication needed (all keys are unique namespaced)
  # Removed legacy flat-key deduplication logic (lines 97-120)

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

  # Handle both object-based and array-based formats
  is_object_format <- !is.null(names(translations$translation)) &&
                     all(names(translations$translation) != "")

  if (is_object_format) {
    # Object format: Convert to array format for shiny.i18n compatibility
    # shiny.i18n expects array format: [{key: "x", en: "...", es: "..."}]
    if (debug) {
      cat("[TRANSLATION LOADER] Converting object format to array for shiny.i18n\n")
    }

    # First, identify duplicate English texts
    en_texts <- sapply(translations$translation, function(entry) {
      if (!is.null(entry$en)) entry$en else ""
    })

    # Find which English texts are duplicated
    duplicated_en_texts <- unique(en_texts[duplicated(en_texts) & en_texts != ""])

    if (debug && length(duplicated_en_texts) > 0) {
      cat(sprintf("[TRANSLATION LOADER] Found %d duplicate English texts (will make unique for shiny.i18n)\n",
                  length(duplicated_en_texts)))
    }

    # Convert to array format, making English text unique where needed
    array_translation <- lapply(names(translations$translation), function(key) {
      entry <- translations$translation[[key]]
      # Create array entry with key field
      result <- list(key = key)

      # Add all language fields
      for (lang in translations$languages) {
        lang_text <- entry[[lang]]

        # For English language: if this text is duplicated, append key to make it unique
        # This ensures shiny.i18n can use it as row.names without conflicts
        if (lang == "en" && !is.null(lang_text) && lang_text %in% duplicated_en_texts) {
          # Append key in brackets to make unique
          # Example: "Other" becomes "Other [modules.isa.ai_assistant.other]"
          lang_text <- sprintf("%s [%s]", lang_text, key)
        }

        result[[lang]] <- lang_text
      }
      return(result)
    })

    translations$translation <- array_translation
  }

  # DISABLED: Deduplication by English text
  # In the pure modular/namespaced key system, different keys CAN have the same English text
  # (e.g., "Other", "Help", "Activities" appear in multiple contexts with different keys)
  # Deduplicating by English text removes legitimate translation keys!
  #
  # OLD LOGIC (INCORRECT for namespaced keys):
  # if (!is.null(translations$translation) && length(translations$translation) > 0) {
  #   en_values <- sapply(translations$translation, function(entry) {
  #     if (!is.null(entry$en)) entry$en else ""
  #   })
  #   duplicate_indices <- which(duplicated(en_values) & en_values != "")
  #   if (length(duplicate_indices) > 0) {
  #     translations$translation <- translations$translation[-duplicate_indices]
  #   }
  # }
  #
  # NEW LOGIC: No deduplication - each namespaced key is unique by definition
  # shiny.i18n will use the "key" field as the unique identifier, not English text

  if (debug && !is.null(translations$translation) && length(translations$translation) > 0) {
    cat(sprintf("[TRANSLATION LOADER] Skipping English text deduplication (namespaced keys allow duplicate English text)\n"))
    cat(sprintf("[TRANSLATION LOADER] Total entries to save: %d\n", length(translations$translation)))
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
                                      persistent = TRUE,
                                      enforce_namespaced = TRUE) {

  if (debug) {
    cat("[TRANSLATION SYSTEM] Initializing modular translation system...\n")
  }

  # Load and merge all translation files
  merged_translations <- load_translations(base_path, debug = debug)

  # Pure modular system - no legacy loading
  # Removed legacy translation merging logic (previously lines 321-365)

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

    # Warn if flat keys found (should be zero in pure modular system)
    if (stats$flat_keys > 0 && enforce_namespaced) {
      warning(sprintf("Found %d flat-key entries (expected 0 in pure modular system)", stats$flat_keys))
    }
  }

  # Save to file (persistent or temp)
  temp_file <- save_merged_translations(merged_translations, debug = debug, persistent = persistent)

  if (debug) {
    cat("[TRANSLATION SYSTEM] Initialization complete!\n")
  }

  return(temp_file)
}

#' Load Reverse Key Mapping
#'
#' Loads the reverse mapping from namespaced keys to English text
#' This enables the wrapper to convert namespaced keys to shiny.i18n lookups
#'
#' @param mapping_path Path to reverse key mapping JSON (default: "scripts/reverse_key_mapping.json")
#' @param debug Print debug information (default: FALSE)
#' @return Named list mapping namespaced keys to English text
#' @export
load_reverse_key_mapping <- function(mapping_path = "scripts/reverse_key_mapping.json", debug = FALSE) {

  if (!requireNamespace("jsonlite", quietly = TRUE)) {
    stop("Package 'jsonlite' is required but not installed")
  }

  if (!file.exists(mapping_path)) {
    stop(sprintf("Reverse key mapping not found: %s", mapping_path))
  }

  tryCatch({
    mapping <- jsonlite::fromJSON(mapping_path, simplifyVector = TRUE)

    if (debug) {
      cat(sprintf("[TRANSLATION WRAPPER] Loaded %d key mappings from %s\n",
                  length(mapping), mapping_path))
    }

    return(mapping)

  }, error = function(e) {
    stop(sprintf("Error loading reverse key mapping: %s", e$message))
  })
}

#' Create Translation Wrapper
#'
#' Creates a wrapper function that looks up translations by namespaced key.
#' Supports both legacy mode (with reverse_mapping) and new direct mode (with merged_translations).
#'
#' @param i18n_translator shiny.i18n Translator object
#' @param reverse_mapping Named list mapping namespaced keys to English text (legacy, optional)
#' @param merged_translations Merged translation data for direct lookup (new format, optional)
#' @param debug Print debug information (default: FALSE)
#' @return Wrapper function that accepts namespaced keys
#' @export
create_translation_wrapper <- function(i18n_translator,
                                     reverse_mapping = NULL,
                                     merged_translations = NULL,
                                     debug = FALSE) {

  # Cache for performance (keyed by language + key)
  cache <- new.env(parent = emptyenv())

  # Determine mode: direct lookup or legacy reverse mapping
  use_direct_lookup <- !is.null(merged_translations) &&
                      is.list(merged_translations) &&
                      length(names(merged_translations)) > 0

  if (debug) {
    if (use_direct_lookup) {
      cat("[TRANSLATION WRAPPER] Using direct key-based lookup (no reverse mapping needed)\n")
    } else {
      cat("[TRANSLATION WRAPPER] Using legacy reverse mapping mode\n")
    }
  }

  # Return wrapper function
  function(namespaced_key) {

    # Get current language from translator
    current_lang <- i18n_translator$get_translation_language()

    # Create cache key combining language and namespaced key
    cache_key <- paste0(current_lang, ":", namespaced_key)

    # Check cache first
    if (exists(cache_key, envir = cache)) {
      return(get(cache_key, envir = cache))
    }

    # NEW MODE: Direct key-based lookup
    if (use_direct_lookup) {
      translation_entry <- merged_translations[[namespaced_key]]

      if (is.null(translation_entry)) {
        # Key not found - warn and return key
        if (debug) {
          warning(sprintf("Translation key not found: '%s'", namespaced_key))
        }
        return(namespaced_key)
      }

      # Get translation for current language
      result <- translation_entry[[current_lang]]

      if (is.null(result) || result == "") {
        # Translation not available for this language - try English fallback
        result <- translation_entry[["en"]]
        if (is.null(result)) {
          return(namespaced_key)
        }
      }

      # Cache and return
      assign(cache_key, result, envir = cache)
      return(result)

    } else {
      # LEGACY MODE: Use reverse mapping to get English text, then call shiny.i18n
      english_text <- reverse_mapping[[namespaced_key]]

      if (is.null(english_text)) {
        # No mapping found - warn and return key
        if (debug) {
          warning(sprintf("No mapping found for key: '%s'", namespaced_key))
        }
        return(namespaced_key)
      }

      # Call shiny.i18n with English text
      tryCatch({
        result <- i18n_translator$t(english_text)

        # Cache the result with language-aware key
        assign(cache_key, result, envir = cache)

        return(result)

      }, error = function(e) {
        if (debug) {
          warning(sprintf("Translation error for '%s': %s", namespaced_key, e$message))
        }
        return(namespaced_key)
      })
    }
  }
}

#' Initialize Translation System with Wrapper
#'
#' Complete initialization function that:
#' 1. Loads and merges modular translation files
#' 2. Initializes shiny.i18n Translator
#' 3. Creates wrapper function for namespaced key lookups
#'
#' @param base_path Base path to translations directory (default: "translations")
#' @param mapping_path Path to reverse key mapping (default: "scripts/reverse_key_mapping.json")
#' @param validate Run validation checks (default: FALSE)
#' @param debug Print debug information (default: FALSE)
#' @param persistent Save to persistent file instead of temp (default: TRUE)
#' @param use_direct_lookup Use direct key-based lookup instead of reverse mapping (default: TRUE)
#' @return List with: translator (shiny.i18n object), wrapper (namespaced key function), file (JSON path)
#' @export
init_translation_system <- function(base_path = "translations",
                                    mapping_path = "scripts/reverse_key_mapping.json",
                                    validate = FALSE,
                                    debug = FALSE,
                                    persistent = TRUE,
                                    use_direct_lookup = TRUE) {

  if (debug) {
    cat("[TRANSLATION SYSTEM] Initializing complete translation system...\n")
  }

  # Step 1: Load and merge modular translations
  merged_translations <- load_translations(base_path = base_path, debug = debug)

  # Keep object format for wrapper (modular files are already in object format)
  # merged_translations$translation is already: list("key" = list(en="...", es="..."), ...)
  translation_obj <- merged_translations$translation

  if (debug) {
    cat(sprintf("[TRANSLATION SYSTEM] Object format for wrapper: %d entries\n",
                length(translation_obj)))
  }

  # Step 2: Save merged translations to file for shiny.i18n
  translation_file <- save_merged_translations(
    merged_translations,
    debug = debug,
    persistent = persistent
  )

  if (debug) {
    cat(sprintf("[TRANSLATION SYSTEM] Merged translation file: %s\n", translation_file))
  }

  # Step 3: Initialize shiny.i18n Translator (primarily for language management)
  if (!requireNamespace("shiny.i18n", quietly = TRUE)) {
    stop("Package 'shiny.i18n' is required but not installed")
  }

  i18n <- tryCatch({
    shiny.i18n::Translator$new(translation_json_path = translation_file)
  }, error = function(e) {
    stop(sprintf("Failed to initialize Translator: %s", e$message))
  })

  if (debug) {
    cat("[TRANSLATION SYSTEM] shiny.i18n Translator initialized\n")
  }

  # Step 4: Create wrapper function
  if (use_direct_lookup) {
    # NEW MODE: Use direct key-based lookup (no reverse mapping needed)
    if (debug) {
      cat("[TRANSLATION SYSTEM] Using direct key-based lookup mode\n")
    }

    # Use the object format we created earlier
    wrapper <- create_translation_wrapper(
      i18n_translator = i18n,
      merged_translations = translation_obj,
      debug = debug
    )
  } else {
    # LEGACY MODE: Use reverse mapping
    if (debug) {
      cat("[TRANSLATION SYSTEM] Using legacy reverse mapping mode\n")
    }
    reverse_mapping <- load_reverse_key_mapping(mapping_path = mapping_path, debug = debug)
    wrapper <- create_translation_wrapper(
      i18n_translator = i18n,
      reverse_mapping = reverse_mapping,
      debug = debug
    )
  }

  if (debug) {
    cat("[TRANSLATION SYSTEM] Translation wrapper created\n")
    cat("[TRANSLATION SYSTEM] Initialization complete!\n")
  }

  return(list(
    translator = i18n,     # Original shiny.i18n object (for language switching)
    wrapper = wrapper,      # Wrapper function for namespaced keys
    file = translation_file # Path to merged JSON
  ))
}
