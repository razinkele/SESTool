# functions/ses_models_loader.R
# Functions for scanning and loading SES models from Excel files
# in the SESModels directory
#
# This module uses the universal_excel_loader.R for format detection
# and loading of various Excel file formats.

# ============================================================================
# GLOBAL CACHE FOR MODEL LIST
# ============================================================================

# Cache for scanned models (avoids rescanning on every UI render)
.ses_models_cache <- new.env(parent = emptyenv())
.ses_models_cache$models <- NULL
.ses_models_cache$last_scan <- NULL

#' Invalidate the SES models cache
#'
#' Clears cached models so the next scan_ses_models() call rescans from disk.
#' Use this instead of directly mutating .ses_models_cache from other files.
invalidate_ses_models_cache <- function() {
  .ses_models_cache$models <- NULL
  .ses_models_cache$last_scan <- NULL
}

# Source universal loader if not already loaded
if (!exists("detect_excel_format", mode = "function")) {
  universal_loader_path <- file.path(dirname(sys.frame(1)$ofile %||% "."), "universal_excel_loader.R")
  if (file.exists(universal_loader_path)) {
    source(universal_loader_path, local = FALSE)
  } else if (file.exists("functions/universal_excel_loader.R")) {
    source("functions/universal_excel_loader.R", local = FALSE)
  }
}

# ============================================================================
# MODEL SCANNING FUNCTIONS
# ============================================================================

#' Scan SESModels directory for Excel files
#'
#' Recursively finds all .xlsx files in the SESModels directory and groups
#' them by their parent folder (Demonstration Area).
#'
#' @param base_dir Base directory to scan (default: "SESModels")
#' @param use_cache Whether to use cached results if available (default: TRUE)
#' @return Named list of model groups, each containing model metadata
#' @export
scan_ses_models <- function(base_dir = "SESModels", use_cache = TRUE) {

  cat("[SES_MODELS] scan_ses_models called with base_dir:", base_dir, "\n")

  # Find the SESModels directory relative to project root
  ses_models_path <- find_ses_models_dir(base_dir)

  if (is.null(ses_models_path)) {
    cat("[SES_MODELS] WARNING: SESModels directory not found\n")
    cat("[SES_MODELS] Current working directory:", getwd(), "\n")
    return(list())
  }

  # Check cache validity
  if (use_cache && !is.null(.ses_models_cache$models)) {
    cache_age <- difftime(Sys.time(), .ses_models_cache$last_scan, units = "secs")
    if (as.numeric(cache_age) < 60) {  # Cache valid for 60 seconds
      cat("[SES_MODELS] Using cached models list (age:", round(as.numeric(cache_age)), "s)\n")
      return(.ses_models_cache$models)
    }
  }

  cat("[SES_MODELS] Scanning directory:", ses_models_path, "\n")

  # Find all Excel files recursively
  excel_files <- list.files(
    ses_models_path,
    pattern = "\\.xlsx$",
    recursive = TRUE,
    full.names = TRUE,
    ignore.case = TRUE
  )

  if (length(excel_files) == 0) {
    cat("[SES_MODELS] WARNING: No Excel files found in SESModels directory\n")
    return(list())
  }

  cat("[SES_MODELS] Found", length(excel_files), "Excel files:\n")
  for (f in excel_files) {
    cat("[SES_MODELS]   -", basename(f), "\n")
  }

  # Group files by parent folder (Demonstration Area)
  models_grouped <- list()

  for (file_path in excel_files) {
    tryCatch({
      # Get relative path from SESModels directory
      norm_ses_path <- normalizePath(ses_models_path, winslash = "/")
      norm_file_path <- normalizePath(file_path, winslash = "/")
      rel_path <- sub(paste0("^", gsub("([.|()\\^{}+$*?]|\\[|\\])", "\\\\\\1", norm_ses_path), "/?"), "",
                      norm_file_path)

      # Extract group name (first level folder) and display name
      path_parts <- strsplit(rel_path, "/")[[1]]

      if (length(path_parts) == 1) {
        # File is directly in SESModels (no subfolder)
        group_name <- "Other Models"
        display_name <- tools::file_path_sans_ext(path_parts[1])
      } else {
        # File is in a subfolder
        group_name <- path_parts[1]
        # Include subfolder path in display name if nested deeper
        if (length(path_parts) > 2) {
          subfolder <- paste(path_parts[2:(length(path_parts)-1)], collapse = "/")
          display_name <- paste0("[", subfolder, "] ", tools::file_path_sans_ext(path_parts[length(path_parts)]))
        } else {
          display_name <- tools::file_path_sans_ext(path_parts[2])
        }
      }

      # Get file info
      file_info <- file.info(file_path)

      # Detect format and variants using universal loader
      format_info <- NULL
      if (exists("detect_excel_format", mode = "function")) {
        format_info <- tryCatch(
          detect_excel_format(norm_file_path),
          error = function(e) NULL
        )
      }

      # Create model entry
      model_entry <- list(
        file_path = norm_file_path,
        display_name = display_name,
        group = group_name,
        modified_time = file_info$mtime,
        size_kb = round(file_info$size / 1024, 1),
        format = if (!is.null(format_info)) format_info$format else "unknown",
        variant_count = if (!is.null(format_info)) length(format_info$variants) else 0,
        variants = if (!is.null(format_info)) format_info$variants else list(),
        is_supported = if (!is.null(format_info)) format_info$format != "unsupported" else FALSE
      )

      cat("[SES_MODELS] Added model:", display_name, "to group:", group_name, "\n")

      # Add to group
      if (is.null(models_grouped[[group_name]])) {
        models_grouped[[group_name]] <- list()
      }
      models_grouped[[group_name]] <- c(models_grouped[[group_name]], list(model_entry))

    }, error = function(e) {
      cat("[SES_MODELS] ERROR processing file:", file_path, "-", e$message, "\n")
    })
  }

  # Sort groups and models within groups
  if (length(models_grouped) > 0) {
    models_grouped <- models_grouped[order(names(models_grouped))]
    for (group_name in names(models_grouped)) {
      display_names <- sapply(models_grouped[[group_name]], function(m) m$display_name)
      models_grouped[[group_name]] <- models_grouped[[group_name]][order(display_names)]
    }
  }

  # Update cache
  .ses_models_cache$models <- models_grouped
  .ses_models_cache$last_scan <- Sys.time()

  cat("[SES_MODELS] Scan complete. Found", length(models_grouped), "groups with",
      sum(sapply(models_grouped, length)), "total models\n")

  return(models_grouped)
}

#' Find SESModels directory
#'
#' Searches for the SESModels directory in common locations
#'
#' @param base_dir Base directory name to look for
#' @return Full path to directory or NULL if not found
find_ses_models_dir <- function(base_dir = "SESModels") {
  # Candidate paths to check
  candidates <- c(
    base_dir,
    file.path(getwd(), base_dir),
    file.path("..", base_dir),
    file.path(dirname(getwd()), base_dir)
  )

  # Also check if PROJECT_ROOT is set
  if (exists("PROJECT_ROOT", envir = globalenv())) {
    candidates <- c(candidates, file.path(get("PROJECT_ROOT", envir = globalenv()), base_dir))
  }

  cat("[SES_MODELS] Searching for directory in candidates:\n")
  for (path in candidates) {
    exists <- dir.exists(path)
    cat("[SES_MODELS]   ", path, "->", if(exists) "FOUND" else "not found", "\n")
    if (exists) {
      return(normalizePath(path, winslash = "/"))
    }
  }

  return(NULL)
}

#' Reload SES models cache
#'
#' Forces a rescan of the SESModels directory
#'
#' @param base_dir Base directory to scan
#' @return Updated list of model groups
#' @export
reload_ses_models <- function(base_dir = "SESModels") {
  cat("[SES_MODELS] Reloading models cache...\n")

  # Clear cache
  .ses_models_cache$models <- NULL
  .ses_models_cache$last_scan <- NULL

  # Rescan
  return(scan_ses_models(base_dir, use_cache = FALSE))
}

#' Get models formatted for selectInput with optgroups
#'
#' Formats the scanned models for use in a Shiny selectInput widget
#' with optgroup support (grouped by Demonstration Area)
#'
#' @param base_dir Base directory to scan
#' @return Named list suitable for selectInput choices with optgroups
#' @export
get_models_for_select <- function(base_dir = "SESModels") {
  models_grouped <- scan_ses_models(base_dir)

  if (length(models_grouped) == 0) {
    cat("[SES_MODELS] No models found for select input\n")
    return(list())
  }

  # Format for selectInput with optgroups
  choices <- list()

  for (group_name in names(models_grouped)) {
    group_choices <- setNames(
      sapply(models_grouped[[group_name]], function(m) m$file_path),
      sapply(models_grouped[[group_name]], function(m) m$display_name)
    )
    choices[[group_name]] <- as.list(group_choices)
  }

  cat("[SES_MODELS] Prepared select choices:", length(choices), "groups\n")
  return(choices)
}

#' Get flat list of all models
#'
#' Returns all models as a flat list (not grouped)
#'
#' @param base_dir Base directory to scan
#' @return List of model metadata entries
#' @export
get_all_models_flat <- function(base_dir = "SESModels") {
  models_grouped <- scan_ses_models(base_dir)

  all_models <- list()
  for (group in models_grouped) {
    all_models <- c(all_models, group)
  }

  return(all_models)
}

# ============================================================================
# MODEL LOADING FUNCTIONS
# ============================================================================

#' Load SES model from Excel file
#'
#' Reads an Excel file using the universal loader which supports multiple formats.
#' Handles standard KUMU export, multi-variant files, and edges-only formats.
#'
#' @param file_path Path to the Excel file
#' @param validate Whether to validate the data structure (default: TRUE)
#' @param variant_name Name of variant to load (for multi-variant files). NULL for first/default.
#' @return List with elements, connections, metadata, and any errors
#' @export
load_ses_model_file <- function(file_path, validate = TRUE, variant_name = NULL) {
  # Check file exists first (before calling basename which fails on NULL)
  if (is.null(file_path) || !nzchar(file_path)) {
    cat("[SES_MODELS] Loading model file: (empty or NULL)\n")
    return(list(
      elements = NULL,
      connections = NULL,
      errors = "File path is empty or NULL",
      warnings = character(),
      file_path = file_path,
      file_name = NA_character_,
      sheets_available = character(),
      metadata = list()
    ))
  }

  cat("[SES_MODELS] Loading model file:", file_path, "\n")
  if (!is.null(variant_name)) {
    cat("[SES_MODELS] Requested variant:", variant_name, "\n")
  }

  # Use universal loader if available
  if (exists("load_ses_model_universal", mode = "function")) {
    cat("[SES_MODELS] Using universal loader...\n")
    universal_result <- load_ses_model_universal(file_path, variant_name = variant_name, validate = validate)

    # Convert to expected format
    result <- list(
      elements = universal_result$elements,
      connections = universal_result$connections,
      errors = universal_result$errors,
      warnings = universal_result$warnings,
      file_path = file_path,
      file_name = basename(file_path),
      sheets_available = tryCatch(readxl::excel_sheets(file_path), error = function(e) character()),
      metadata = universal_result$metadata
    )

    if (length(result$errors) == 0) {
      cat("[SES_MODELS] Model loaded successfully via universal loader\n")
    }

    return(result)
  }

  # Fallback to legacy loader (Elements/Connections sheets only)
  cat("[SES_MODELS] Universal loader not available, using legacy loader...\n")

  result <- list(
    elements = NULL,
    connections = NULL,
    errors = character(),
    warnings = character(),
    file_path = file_path,
    file_name = basename(file_path),
    sheets_available = character(),
    metadata = list()
  )

  if (!file.exists(file_path)) {
    result$errors <- c(result$errors, paste("File not found:", file_path))
    return(result)
  }

  # Read file with error handling (legacy method)
  load_result <- tryCatch({
    # Check sheets exist
    sheets <- readxl::excel_sheets(file_path)
    result$sheets_available <- sheets
    cat("[SES_MODELS] Available sheets:", paste(sheets, collapse = ", "), "\n")

    has_elements <- "Elements" %in% sheets
    has_connections <- "Connections" %in% sheets

    if (!has_elements) {
      result$errors <- c(result$errors, paste0("Missing 'Elements' sheet. Available: ", paste(sheets, collapse = ", ")))
    }

    if (!has_connections) {
      result$errors <- c(result$errors, paste0("Missing 'Connections' sheet. Available: ", paste(sheets, collapse = ", ")))
    }

    # If sheets are missing, return early
    if (length(result$errors) > 0) {
      return(list(success = FALSE))
    }

    # Read sheets
    cat("[SES_MODELS] Reading Elements sheet...\n")
    elements <- readxl::read_excel(file_path, sheet = "Elements")
    cat("[SES_MODELS] Elements sheet: ", nrow(elements), " rows, ", ncol(elements), " columns\n")
    cat("[SES_MODELS] Elements columns:", paste(names(elements), collapse = ", "), "\n")

    cat("[SES_MODELS] Reading Connections sheet...\n")
    connections <- readxl::read_excel(file_path, sheet = "Connections")
    cat("[SES_MODELS] Connections sheet: ", nrow(connections), " rows, ", ncol(connections), " columns\n")
    cat("[SES_MODELS] Connections columns:", paste(names(connections), collapse = ", "), "\n")

    list(success = TRUE, elements = elements, connections = connections)

  }, error = function(e) {
    cat("[SES_MODELS] ERROR reading Excel file:", e$message, "\n")
    list(success = FALSE, error = e$message)
  })

  # Handle read errors
  if (!load_result$success) {
    if (!is.null(load_result$error)) {
      result$errors <- c(result$errors, paste("Error reading file:", load_result$error))
    }
    return(result)
  }

  result$elements <- load_result$elements
  result$connections <- load_result$connections

  # Validate if requested
  if (validate && length(result$errors) == 0) {
    cat("[SES_MODELS] Validating data structure...\n")
    validation_result <- validate_ses_model_data(result$elements, result$connections)
    result$errors <- c(result$errors, validation_result$errors)
    result$warnings <- c(result$warnings, validation_result$warnings)
  }

  if (length(result$errors) == 0) {
    cat("[SES_MODELS] Model loaded successfully\n")
  } else {
    cat("[SES_MODELS] Model has errors:", paste(result$errors, collapse = "; "), "\n")
  }

  return(result)
}

#' Validate SES model data
#'
#' Checks that elements and connections data have required columns
#'
#' @param elements Elements dataframe
#' @param connections Connections dataframe
#' @return List with errors and warnings vectors
validate_ses_model_data <- function(elements, connections) {
  result <- list(errors = character(), warnings = character())

  # Check elements is valid

  if (is.null(elements)) {
    result$errors <- c(result$errors, "Elements data is NULL")
    return(result)
  }

  if (!is.data.frame(elements)) {
    result$errors <- c(result$errors, "Elements is not a data frame")
    return(result)
  }

  if (nrow(elements) == 0) {
    result$errors <- c(result$errors, "Elements sheet is empty")
    return(result)
  }

  # Check for Label column
  if (!("Label" %in% names(elements))) {
    result$errors <- c(result$errors, paste0("Elements sheet must have 'Label' column. Found: ",
                                             paste(names(elements), collapse = ", ")))
  }

  # Check for type column (might be type...2 due to duplicate names)
  type_col <- NULL
  type_col_candidates <- c("type", "Type", "TYPE", "type...2", "Type...2")
  for (col in type_col_candidates) {
    if (col %in% names(elements)) {
      type_col <- col
      break
    }
  }

  if (is.null(type_col)) {
    result$errors <- c(result$errors, paste0("Elements sheet must have 'type' column. Found: ",
                                             paste(names(elements), collapse = ", ")))
  } else {
    # Check element types
    unique_types <- unique(elements[[type_col]])
    cat("[SES_MODELS] Element types found:", paste(unique_types, collapse = ", "), "\n")
  }

  # Check connections
  if (is.null(connections)) {
    result$errors <- c(result$errors, "Connections data is NULL")
    return(result)
  }

  if (!is.data.frame(connections)) {
    result$errors <- c(result$errors, "Connections is not a data frame")
    return(result)
  }

  if (nrow(connections) == 0) {
    result$warnings <- c(result$warnings, "Connections sheet is empty - model will have no connections")
    return(result)
  }

  # Check required connection columns
  required_conn_cols <- c("From", "To", "Label")
  missing_cols <- setdiff(required_conn_cols, names(connections))
  if (length(missing_cols) > 0) {
    result$errors <- c(result$errors, paste0("Connections sheet missing columns: ",
                                             paste(missing_cols, collapse = ", "),
                                             ". Found: ", paste(names(connections), collapse = ", ")))
  }

  return(result)
}

#' Get model preview information
#'
#' Returns summary information about a model without fully loading it
#'
#' @param file_path Path to the Excel file
#' @return List with preview information (element count, connection count, etc.)
#' @export
get_model_preview <- function(file_path) {
  cat("[SES_MODELS] Getting preview for:", file_path, "\n")

  preview <- list(
    file_name = if (!is.null(file_path) && nzchar(file_path)) basename(file_path) else "Unknown",
    file_path = file_path,
    elements_count = NA_integer_,
    connections_count = NA_integer_,
    element_types = list(),
    modified_time = NA,
    size_kb = NA_real_,
    is_valid = FALSE,
    errors = character(),
    warnings = character()
  )

  # Validate file_path
  if (is.null(file_path) || !nzchar(file_path)) {
    preview$errors <- c(preview$errors, "File path is empty")
    return(preview)
  }

  # Get file info
  if (file.exists(file_path)) {
    file_info <- file.info(file_path)
    preview$modified_time <- file_info$mtime
    preview$size_kb <- round(file_info$size / 1024, 1)
  } else {
    preview$errors <- c(preview$errors, "File does not exist")
    return(preview)
  }

  # Try to load and get counts
  model_data <- load_ses_model_file(file_path, validate = TRUE)

  if (length(model_data$errors) > 0) {
    preview$errors <- model_data$errors
    preview$warnings <- model_data$warnings
    return(preview)
  }

  preview$is_valid <- TRUE
  preview$warnings <- model_data$warnings

  # Safely get counts
  if (!is.null(model_data$elements) && is.data.frame(model_data$elements)) {
    preview$elements_count <- nrow(model_data$elements)
  }

  if (!is.null(model_data$connections) && is.data.frame(model_data$connections)) {
    preview$connections_count <- nrow(model_data$connections)
  }

  # Get element type counts
  if (!is.null(model_data$elements) && is.data.frame(model_data$elements)) {
    type_col <- NULL
    for (col in c("type", "Type", "type...2", "Type...2")) {
      if (col %in% names(model_data$elements)) {
        type_col <- col
        break
      }
    }

    if (!is.null(type_col)) {
      type_counts <- table(model_data$elements[[type_col]])
      preview$element_types <- as.list(type_counts)
    }
  }

  # Run name mismatch diagnostic
  if (!is.null(model_data$elements) && !is.null(model_data$connections)) {
    name_diagnostic <- diagnose_name_mismatches(model_data$elements, model_data$connections)
    preview$name_diagnostic <- name_diagnostic

    if (length(name_diagnostic$mismatched_names) > 0) {
      preview$warnings <- c(preview$warnings,
        sprintf("%d connection references don't match any element name exactly",
                length(name_diagnostic$mismatched_names)))
    }
  }

  cat("[SES_MODELS] Preview complete: ", preview$elements_count, " elements, ",
      preview$connections_count, " connections, valid=", preview$is_valid, "\n")

  return(preview)
}

#' Diagnose name mismatches between elements and connections
#'
#' Compares node names in Elements sheet with From/To references in Connections sheet
#' to identify naming inconsistencies that would cause connections to be lost.
#'
#' @param elements Data frame with element data
#' @param connections Data frame with connection data
#' @return List with diagnostic information
#' @export
diagnose_name_mismatches <- function(elements, connections) {
  cat("\n[NAME_DIAGNOSTIC] ====== Analyzing name mismatches ======\n")

  result <- list(
    element_names = character(),
    connection_refs = character(),
    exact_matches = character(),
    mismatched_names = character(),
    potential_matches = list(),
    orphan_connections = 0
  )

  # Get element names
  if ("Label" %in% names(elements)) {
    result$element_names <- unique(trimws(as.character(elements$Label)))
    result$element_names <- result$element_names[!is.na(result$element_names) & nzchar(result$element_names)]
  } else {
    cat("[NAME_DIAGNOSTIC] ERROR: No 'Label' column in elements\n")
    return(result)
  }

  # Get connection references
  if ("From" %in% names(connections) && "To" %in% names(connections)) {
    from_refs <- unique(trimws(as.character(connections$From)))
    to_refs <- unique(trimws(as.character(connections$To)))
    result$connection_refs <- unique(c(from_refs, to_refs))
    result$connection_refs <- result$connection_refs[!is.na(result$connection_refs) & nzchar(result$connection_refs)]
  } else {
    cat("[NAME_DIAGNOSTIC] ERROR: No 'From'/'To' columns in connections\n")
    return(result)
  }

  cat("[NAME_DIAGNOSTIC] Element names in node sheet:", length(result$element_names), "\n")
  cat("[NAME_DIAGNOSTIC] Unique names in connections (From/To):", length(result$connection_refs), "\n")

  # Find exact matches and mismatches
  result$exact_matches <- intersect(result$connection_refs, result$element_names)
  result$mismatched_names <- setdiff(result$connection_refs, result$element_names)

  cat("[NAME_DIAGNOSTIC] Exact matches:", length(result$exact_matches), "\n")
  cat("[NAME_DIAGNOSTIC] Mismatched (in connections but not in elements):", length(result$mismatched_names), "\n")

  # For mismatched names, try to find potential matches
  if (length(result$mismatched_names) > 0) {
    cat("\n[NAME_DIAGNOSTIC] ====== MISMATCHED NAMES DETAIL ======\n")

    # Create lowercase lookup for fuzzy matching
    element_names_lower <- tolower(result$element_names)
    names(element_names_lower) <- result$element_names

    for (mismatch in result$mismatched_names) {
      cat(sprintf("[NAME_DIAGNOSTIC] Connection ref: '%s'\n", mismatch))

      # Show hex codes for debugging invisible characters
      mismatch_bytes <- paste(sprintf("%02X", as.integer(charToRaw(mismatch))), collapse = " ")
      cat(sprintf("  -> Hex bytes: %s\n", mismatch_bytes))

      # Try case-insensitive match
      mismatch_lower <- tolower(mismatch)
      case_matches <- names(element_names_lower)[element_names_lower == mismatch_lower]

      if (length(case_matches) > 0) {
        cat(sprintf("  -> Potential match (case difference): '%s'\n", case_matches[1]))
        # Show hex of the match for comparison
        match_bytes <- paste(sprintf("%02X", as.integer(charToRaw(case_matches[1]))), collapse = " ")
        cat(sprintf("  -> Match hex bytes: %s\n", match_bytes))
        result$potential_matches[[mismatch]] <- list(type = "case", match = case_matches[1])
      } else {
        # Try substring/partial match (fixed to avoid warning)
        partial_matches <- character()
        for (elem_name in result$element_names) {
          if (grepl(mismatch_lower, tolower(elem_name), fixed = TRUE) ||
              grepl(tolower(elem_name), mismatch_lower, fixed = TRUE)) {
            partial_matches <- c(partial_matches, elem_name)
          }
        }
        if (length(partial_matches) > 0) {
          cat(sprintf("  -> Potential partial matches: %s\n", paste(head(partial_matches, 3), collapse = ", ")))
          # Show hex comparison for first partial match
          match_bytes <- paste(sprintf("%02X", as.integer(charToRaw(partial_matches[1]))), collapse = " ")
          cat(sprintf("  -> First match hex bytes: %s\n", match_bytes))

          # Highlight character differences
          if (nchar(mismatch) == nchar(partial_matches[1])) {
            diff_positions <- which(strsplit(mismatch, "")[[1]] != strsplit(partial_matches[1], "")[[1]])
            if (length(diff_positions) > 0) {
              cat(sprintf("  -> CHARACTER DIFFERENCES at positions: %s\n", paste(diff_positions, collapse = ", ")))
              for (pos in diff_positions) {
                char1 <- substr(mismatch, pos, pos)
                char2 <- substr(partial_matches[1], pos, pos)
                cat(sprintf("     Position %d: '%s' (0x%02X) vs '%s' (0x%02X)\n",
                            pos, char1, as.integer(charToRaw(char1)),
                            char2, as.integer(charToRaw(char2))))
              }
            }
          }

          result$potential_matches[[mismatch]] <- list(type = "partial", matches = partial_matches)
        } else {
          cat("  -> NO MATCH FOUND in element names\n")
        }
      }
    }
  }

  # Count orphan connections (connections that will be lost)
  from_vals <- trimws(as.character(connections$From))
  to_vals <- trimws(as.character(connections$To))

  orphan_mask <- !(from_vals %in% result$element_names) | !(to_vals %in% result$element_names)
  result$orphan_connections <- sum(orphan_mask, na.rm = TRUE)

  cat(sprintf("\n[NAME_DIAGNOSTIC] Connections that will be LOST due to name mismatches: %d of %d (%.1f%%)\n",
              result$orphan_connections, nrow(connections),
              100 * result$orphan_connections / nrow(connections)))

  # Show which specific connections are orphaned
  if (result$orphan_connections > 0 && result$orphan_connections <= 20) {
    cat("[NAME_DIAGNOSTIC] Orphan connections:\n")
    orphan_indices <- which(orphan_mask)
    for (idx in orphan_indices) {
      from_ok <- from_vals[idx] %in% result$element_names
      to_ok <- to_vals[idx] %in% result$element_names
      cat(sprintf("  %s -> %s [From:%s, To:%s]\n",
                  from_vals[idx], to_vals[idx],
                  if(from_ok) "OK" else "MISSING",
                  if(to_ok) "OK" else "MISSING"))
    }
  }

  # Print all names for detailed comparison
  cat("\n[NAME_DIAGNOSTIC] ====== ALL ELEMENT NAMES (from node sheet) ======\n")
  for (i in seq_along(result$element_names)) {
    cat(sprintf("  [%2d] '%s'\n", i, result$element_names[i]))
  }

  cat("\n[NAME_DIAGNOSTIC] ====== ALL CONNECTION REFERENCES (From/To) ======\n")
  for (i in seq_along(result$connection_refs)) {
    in_elements <- result$connection_refs[i] %in% result$element_names
    status <- if (in_elements) "OK" else "MISSING"
    cat(sprintf("  [%2d] '%s' [%s]\n", i, result$connection_refs[i], status))
  }

  cat("[NAME_DIAGNOSTIC] ====== End diagnostic ======\n\n")

  return(result)
}

# ============================================================================
# DIAGNOSTIC FUNCTIONS
# ============================================================================

#' Run diagnostics on SES Models system
#'
#' Useful for debugging issues with model loading
#'
#' @param base_dir Base directory to scan
#' @return List with diagnostic information
#' @export
diagnose_ses_models <- function(base_dir = "SESModels") {
  cat("\n========== SES MODELS DIAGNOSTICS ==========\n\n")

  diagnostics <- list(
    working_dir = getwd(),
    project_root = if (exists("PROJECT_ROOT", envir = globalenv()))
      get("PROJECT_ROOT", envir = globalenv()) else "NOT SET",
    ses_models_dir = NULL,
    files_found = character(),
    models_by_group = list(),
    load_tests = list()
  )

  cat("Working directory:", diagnostics$working_dir, "\n")
  cat("PROJECT_ROOT:", diagnostics$project_root, "\n\n")

  # Find directory
  ses_dir <- find_ses_models_dir(base_dir)
  diagnostics$ses_models_dir <- ses_dir

  if (is.null(ses_dir)) {
    cat("ERROR: SESModels directory not found!\n")
    return(diagnostics)
  }

  cat("SESModels directory:", ses_dir, "\n\n")

  # List all files
  all_files <- list.files(ses_dir, pattern = "\\.xlsx$", recursive = TRUE, full.names = TRUE)
  diagnostics$files_found <- all_files
  cat("Excel files found:", length(all_files), "\n")
  for (f in all_files) {
    cat("  -", f, "\n")
  }
  cat("\n")

  # Scan models
  models <- scan_ses_models(base_dir, use_cache = FALSE)
  diagnostics$models_by_group <- models

  cat("Models by group:\n")
  for (group in names(models)) {
    cat("  ", group, ":", length(models[[group]]), "models\n")
    for (m in models[[group]]) {
      cat("    -", m$display_name, "\n")
    }
  }
  cat("\n")

  # Test loading first file from each group
  cat("Load tests:\n")
  for (group in names(models)) {
    if (length(models[[group]]) > 0) {
      test_file <- models[[group]][[1]]$file_path
      cat("  Testing:", basename(test_file), "...\n")

      result <- load_ses_model_file(test_file, validate = TRUE)

      if (length(result$errors) == 0) {
        cat("    SUCCESS: ", nrow(result$elements), " elements, ",
            nrow(result$connections), " connections\n")
        diagnostics$load_tests[[basename(test_file)]] <- "SUCCESS"
      } else {
        cat("    FAILED:", paste(result$errors, collapse = "; "), "\n")
        diagnostics$load_tests[[basename(test_file)]] <- result$errors
      }
    }
  }

  cat("\n========== END DIAGNOSTICS ==========\n\n")

  return(invisible(diagnostics))
}
