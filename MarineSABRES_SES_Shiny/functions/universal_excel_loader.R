# functions/universal_excel_loader.R
# Universal loader for SES model Excel files with different structures
# Handles multiple formats: KUMU standard, Node/Edge pairs, single-sheet, etc.

# ============================================================================
# FORMAT DETECTION
# ============================================================================

#' Detect Excel file format and available model variants
#'
#' Analyzes an Excel file to determine its format and available models
#'
#' @param file_path Path to the Excel file
#' @return List with format info and available model variants
#' @export
detect_excel_format <- function(file_path) {
  debug_log(paste("Detecting format for:", basename(file_path)), "EXCEL_LOADER")

  result <- list(
    file_path = file_path,
    file_name = basename(file_path),
    format = "unknown",
    variants = list(),
    errors = character()
  )

  if (!file.exists(file_path)) {
    result$errors <- "File not found"
    return(result)
  }

  sheets <- tryCatch(
    readxl::excel_sheets(file_path),
    error = function(e) {
      result$errors <<- c(result$errors, paste("Cannot read Excel file:", e$message))
      character()
    }
  )

  if (length(sheets) == 0) {
    return(result)
  }

  debug_log(paste("Sheets found:", paste(sheets, collapse = ", ")), "EXCEL_LOADER")

  # Format 1: Standard KUMU (Elements + Connections)
  if ("Elements" %in% sheets && "Connections" %in% sheets) {
    debug_log("Detected Format: KUMU Standard (Elements/Connections)", "EXCEL_LOADER")
    result$format <- "kumu_standard"
    result$variants <- list(
      list(
        name = "Default Model",
        node_sheet = "Elements",
        edge_sheet = "Connections"
      )
    )
    return(result)
  }

  # Format 2 & 3: Multiple sheet pairs with node/edge data
  # Look for matching pairs

  sheets_lower <- tolower(sheets)
  variants <- list()

  # Pattern A: "*Node Labels*" + "*Kumu*Edges" or "*Edges"
  node_pattern_sheets <- sheets[grepl("node.*label", sheets_lower, ignore.case = TRUE)]
  for (node_sheet in node_pattern_sheets) {
    # Try to find matching edge sheet
    prefix <- gsub("\\s*node\\s*label.*", "", node_sheet, ignore.case = TRUE)
    prefix_clean <- trimws(prefix)

    # Look for matching edge sheet with same prefix
    matching_edges <- sheets[grepl(paste0("^", prefix_clean, ".*edge|^", prefix_clean, ".*kumu"), sheets, ignore.case = TRUE)]
    if (length(matching_edges) > 0) {
      variant_name <- if (nzchar(prefix_clean)) prefix_clean else "Default"
      variants[[length(variants) + 1]] <- list(
        name = variant_name,
        node_sheet = node_sheet,
        edge_sheet = matching_edges[1]
      )
      debug_log(paste("Found variant:", variant_name, "- Nodes:", node_sheet, ", Edges:", matching_edges[1]), "EXCEL_LOADER")
    }
  }

  # Pattern B: "*Edge Labels*" (actually nodes) + "*Node Data*" (actually edges)
  # This is the confusingly-named format
  edge_label_sheets <- sheets[grepl("edge.*label", sheets_lower, ignore.case = TRUE)]
  for (el_sheet in edge_label_sheets) {
    # Check if this sheet actually contains node data (Label, Type columns)
    cols <- tryCatch({
      data <- readxl::read_excel(file_path, sheet = el_sheet, n_max = 1)
      tolower(names(data))
    }, error = function(e) character())

    if ("label" %in% cols && ("type" %in% cols || "description" %in% cols)) {
      # This "Edge Labels" sheet is actually a node sheet
      prefix <- gsub("\\s*edge\\s*label.*", "", el_sheet, ignore.case = TRUE)
      prefix_clean <- trimws(prefix)

      # Look for matching "Node Data" sheet (which is actually edges)
      matching_node_data <- sheets[grepl(paste0("^", prefix_clean, ".*node.*data"), sheets, ignore.case = TRUE)]
      if (length(matching_node_data) > 0) {
        variant_name <- if (nzchar(prefix_clean)) prefix_clean else "Default"

        # Check if we already have this variant
        existing <- sapply(variants, function(v) identical(v$name, variant_name))
        if (length(existing) == 0 || !any(existing, na.rm = TRUE)) {
          variants[[length(variants) + 1]] <- list(
            name = variant_name,
            node_sheet = el_sheet,
            edge_sheet = matching_node_data[1],
            note = "Confusingly named: 'Edge Labels' = nodes, 'Node Data' = edges"
          )
          debug_log(paste("Found variant (confusing names):", variant_name), "EXCEL_LOADER")
        }
      }
    }
  }

  # Pattern C: "*Kumu*" sheets that contain edges (From/To columns)
  kumu_sheets <- sheets[grepl("kumu", sheets_lower, ignore.case = TRUE) & !grepl("edge", sheets_lower, ignore.case = TRUE)]
  for (kumu_sheet in kumu_sheets) {
    # Check if this is an edge sheet
    cols <- tryCatch({
      data <- readxl::read_excel(file_path, sheet = kumu_sheet, n_max = 1)
      tolower(names(data))
    }, error = function(e) character())

    if ("from" %in% cols && "to" %in% cols) {
      # Find corresponding node sheet
      prefix <- gsub("\\s*kumu.*", "", kumu_sheet, ignore.case = TRUE)
      prefix_clean <- trimws(prefix)

      # Look for node sheet with same prefix
      matching_nodes <- sheets[grepl(paste0("^", prefix_clean, ".*label|^", prefix_clean, ".*element"), sheets, ignore.case = TRUE)]

      if (length(matching_nodes) > 0) {
        variant_name <- if (nzchar(prefix_clean)) prefix_clean else "Default"
        # Check if we already have this variant
        existing <- sapply(variants, function(v) identical(v$name, variant_name))
        if (length(existing) == 0 || !any(existing, na.rm = TRUE)) {
          variants[[length(variants) + 1]] <- list(
            name = variant_name,
            node_sheet = matching_nodes[1],
            edge_sheet = kumu_sheet
          )
          debug_log(paste("Found variant (Kumu pattern):", variant_name), "EXCEL_LOADER")
        }
      }
    }
  }

  if (length(variants) > 0) {
    result$format <- "multi_variant"
    result$variants <- variants
    return(result)
  }

  # Format 4: Single sheet with edges only (infer nodes)
  for (sheet in sheets) {
    cols <- tryCatch({
      data <- readxl::read_excel(file_path, sheet = sheet, n_max = 1)
      tolower(names(data))
    }, error = function(e) character())

    if ("from" %in% cols && "to" %in% cols) {
      debug_log("Detected Format: Single sheet with edges (nodes will be inferred)", "EXCEL_LOADER")
      result$format <- "edges_only"
      result$variants <- list(
        list(
          name = sheet,
          node_sheet = NULL,
          edge_sheet = sheet,
          infer_nodes = TRUE
        )
      )
      return(result)
    }
  }

  # Format 5: Unknown/unsupported
  debug_log("WARNING: Could not detect a supported format", "EXCEL_LOADER")
  result$format <- "unsupported"
  result$errors <- "Could not detect node/edge sheets in this file"

  return(result)
}

# ============================================================================
# UNIVERSAL LOADING FUNCTION
# ============================================================================

#' Load SES model from Excel file using universal format detection
#'
#' @param file_path Path to the Excel file
#' @param variant_name Name of variant to load (if multiple exist). NULL for first/only variant.
#' @param validate Whether to validate the data
#' @return List with elements, connections, metadata, and errors
#' @export
load_ses_model_universal <- function(file_path, variant_name = NULL, validate = TRUE) {
  debug_log(paste("Loading:", basename(file_path)), "EXCEL_LOADER")

  result <- list(
    elements = NULL,
    connections = NULL,
    metadata = list(
      file_path = file_path,
      file_name = basename(file_path),
      format = NULL,
      variant = NULL,
      node_sheet = NULL,
      edge_sheet = NULL,
      nodes_inferred = FALSE
    ),
    errors = character(),
    warnings = character()
  )

  # Detect format
  format_info <- detect_excel_format(file_path)

  if (length(format_info$errors) > 0) {
    result$errors <- format_info$errors
    return(result)
  }

  if (format_info$format == "unsupported") {
    result$errors <- "Unsupported file format"
    return(result)
  }

  result$metadata$format <- format_info$format

  # Select variant
  if (length(format_info$variants) == 0) {
    result$errors <- "No model variants found in file"
    return(result)
  }

  variant <- NULL
  if (!is.null(variant_name)) {
    # Find requested variant
    for (v in format_info$variants) {
      if (v$name == variant_name) {
        variant <- v
        break
      }
    }
    if (is.null(variant)) {
      result$errors <- paste("Variant not found:", variant_name)
      return(result)
    }
  } else {
    # Use first variant
    variant <- format_info$variants[[1]]
  }

  result$metadata$variant <- variant$name
  result$metadata$node_sheet <- variant$node_sheet
  result$metadata$edge_sheet <- variant$edge_sheet

  debug_log(paste("Loading variant:", variant$name), "EXCEL_LOADER")
  debug_log(paste("Node sheet:", if(is.null(variant$node_sheet)) "N/A (will infer)" else variant$node_sheet), "EXCEL_LOADER")
  debug_log(paste("Edge sheet:", variant$edge_sheet), "EXCEL_LOADER")

  # Load edge data
  edges <- tryCatch({
    readxl::read_excel(file_path, sheet = variant$edge_sheet)
  }, error = function(e) {
    result$errors <<- c(result$errors, paste("Error reading edge sheet:", e$message))
    NULL
  })

  if (is.null(edges)) {
    return(result)
  }

  # Normalize edge column names
  edges <- normalize_column_names(edges)
  debug_log(paste("Edge columns after normalization:", paste(names(edges), collapse = ", ")), "EXCEL_LOADER")

  # Validate edge columns
  if (!("From" %in% names(edges)) || !("To" %in% names(edges))) {
    result$errors <- c(result$errors, "Edge sheet must have 'From' and 'To' columns")
    return(result)
  }

  result$connections <- edges

  # Load or infer node data
  if (!is.null(variant$node_sheet)) {
    nodes <- tryCatch({
      readxl::read_excel(file_path, sheet = variant$node_sheet)
    }, error = function(e) {
      result$errors <<- c(result$errors, paste("Error reading node sheet:", e$message))
      NULL
    })

    if (!is.null(nodes)) {
      nodes <- normalize_column_names(nodes)
      debug_log(paste("Node columns after normalization:", paste(names(nodes), collapse = ", ")), "EXCEL_LOADER")

      # Handle case where node sheet doesn't have 'type' but edge sheet does
      # This happens in some files where type is only in edge data
      if (!("type" %in% names(nodes)) && "type" %in% names(edges)) {
        debug_log("Node sheet missing 'type', trying to infer from edges...", "EXCEL_LOADER")
        nodes <- infer_node_types_from_edges(nodes, edges)
      }

      result$elements <- nodes
    }
  }

  # Infer nodes from edges if needed
  if (is.null(result$elements) || (isTRUE(variant$infer_nodes))) {
    debug_log("Inferring nodes from edge data...", "EXCEL_LOADER")
    result$elements <- infer_nodes_from_edges(edges)
    result$metadata$nodes_inferred <- TRUE
    result$warnings <- c(result$warnings, "Nodes were inferred from edge data")
  }

  # Check if types are missing and try to infer them
  if ("type" %in% names(result$elements)) {
    na_type_count <- sum(is.na(result$elements$type) | !nzchar(trimws(as.character(result$elements$type))))
    if (na_type_count > 0) {
      debug_log(paste("", na_type_count, " elements missing types, attempting inference...\n"), "EXCEL_LOADER")
      result$elements <- infer_missing_types(result$elements)
      result$metadata$types_inferred <- TRUE

      # Check how many still missing
      still_missing <- sum(is.na(result$elements$type) | !nzchar(trimws(as.character(result$elements$type))))
      if (still_missing > 0) {
        result$warnings <- c(result$warnings,
                            paste(still_missing, "elements could not have types inferred"))
      } else {
        result$warnings <- c(result$warnings, "All element types were inferred from names")
      }
    }
  } else {
    # No type column at all - add one and infer
    debug_log("No type column found, adding and inferring types...", "EXCEL_LOADER")
    result$elements$type <- NA_character_
    result$elements <- infer_missing_types(result$elements)
    result$metadata$types_inferred <- TRUE

    still_missing <- sum(is.na(result$elements$type) | !nzchar(trimws(as.character(result$elements$type))))
    if (still_missing > 0) {
      result$warnings <- c(result$warnings,
                          paste(still_missing, "elements could not have types inferred"))
    }
  }

  # Reconcile naming differences between node sheet and connection references
  # This handles whitespace, case differences, etc.
  debug_log("Checking for name mismatches between nodes and connections...", "EXCEL_LOADER")
  name_mapping_result <- create_name_mapping(result$elements, result$connections)

  if (length(name_mapping_result$mapping) > 0) {
    debug_log("Applying name corrections to connections...", "EXCEL_LOADER")
    result$connections <- apply_name_mapping(result$connections, name_mapping_result$mapping)
    result$metadata$name_corrections <- length(name_mapping_result$mapping)
    result$warnings <- c(result$warnings,
                        paste(length(name_mapping_result$mapping),
                              "connection references had naming mismatches (whitespace/case) that were corrected"))
  }

  # Report unmatched references
  all_unmatched <- unique(c(name_mapping_result$unmatched_from, name_mapping_result$unmatched_to))
  if (length(all_unmatched) > 0) {
    debug_log(paste("WARNING:", length(all_unmatched), "connection references could not be matched to any element:\n"), "EXCEL_LOADER")
    for (um in head(all_unmatched, 10)) {
      debug_log(paste("  - '", um, "'\n", sep = ""), "EXCEL_LOADER")
    }
    if (length(all_unmatched) > 10) {
      debug_log(paste("  ... and", length(all_unmatched) - 10, "more\n"), "EXCEL_LOADER")
    }
    result$warnings <- c(result$warnings,
                        paste(length(all_unmatched), "connection references could not be matched to any element"))
  }

  # Validate if requested
  if (validate && length(result$errors) == 0) {
    validation <- validate_universal_model(result$elements, result$connections)
    result$errors <- c(result$errors, validation$errors)
    result$warnings <- c(result$warnings, validation$warnings)
  }

  if (length(result$errors) == 0) {
    debug_log(paste("Successfully loaded:", nrow(result$elements), "nodes,", nrow(result$connections), "edges\n"), "EXCEL_LOADER")
  } else {
    debug_log(paste("Load completed with errors:", paste(result$errors, collapse = "; ")), "EXCEL_LOADER")
  }

  return(result)
}

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

#' Normalize element/node name for matching
#'
#' Trims whitespace, normalizes multiple spaces, replaces invisible/special characters,
#' and optionally lowercases for fuzzy matching between node sheet and connection sheet.
#'
#' @param name Character string to normalize
#' @param lowercase If TRUE, convert to lowercase for case-insensitive matching
#' @return Normalized string
normalize_element_name <- function(name, lowercase = FALSE) {
  if (is.na(name) || !is.character(name)) return(NA_character_)

  normalized <- name


  # Replace non-breaking space (Unicode 160, \u00A0) with regular space
  normalized <- gsub("\u00A0", " ", normalized)


  # Replace other common invisible/special characters
  normalized <- gsub("\u200B", "", normalized)  # Zero-width space
  normalized <- gsub("\u200C", "", normalized)  # Zero-width non-joiner
  normalized <- gsub("\u200D", "", normalized)  # Zero-width joiner
  normalized <- gsub("\uFEFF", "", normalized)  # BOM / zero-width no-break space

  # Replace en-dash and em-dash with regular hyphen
  normalized <- gsub("\u2013", "-", normalized)  # En-dash
  normalized <- gsub("\u2014", "-", normalized)  # Em-dash

  # Replace smart quotes with regular quotes
  normalized <- gsub("[\u2018\u2019]", "'", normalized)  # Smart single quotes
  normalized <- gsub("[\u201C\u201D]", "\"", normalized) # Smart double quotes

  # Trim leading/trailing whitespace
  normalized <- trimws(normalized)

  # Replace multiple spaces with single space
  normalized <- gsub("\\s+", " ", normalized)

  # Optionally lowercase for comparison
  if (lowercase) {
    normalized <- tolower(normalized)
  }

  return(normalized)
}

#' Create name mapping between node sheet and connection references
#'
#' Identifies and reconciles naming differences between element labels
#' and the From/To values in connections. Returns a mapping to fix mismatches.
#' Handles invisible characters (non-breaking spaces, etc.), case differences,
#' and whitespace issues.
#'
#' @param elements Data frame with element data (must have Label column)
#' @param connections Data frame with connection data (must have From/To columns)
#' @return List with mapping info and diagnostics
create_name_mapping <- function(elements, connections) {
  result <- list(
    mapping = list(),        # From connection name -> element name
    exact_matches = 0,
    normalized_matches = 0,
    unmatched_from = character(),
    unmatched_to = character()
  )

  if (!("Label" %in% names(elements))) return(result)
  if (!("From" %in% names(connections)) || !("To" %in% names(connections))) return(result)

  # Get unique node labels (original)
  node_labels_original <- unique(as.character(elements$Label))
  node_labels_original <- node_labels_original[!is.na(node_labels_original) & nzchar(node_labels_original)]

  # Create normalized lookup (handles invisible chars, case, whitespace)
  node_labels_normalized <- sapply(node_labels_original, normalize_element_name, lowercase = TRUE)
  names(node_labels_normalized) <- node_labels_original

  # Get unique From/To references (original)
  from_refs <- unique(as.character(connections$From))
  to_refs <- unique(as.character(connections$To))
  all_refs <- unique(c(from_refs, to_refs))
  all_refs <- all_refs[!is.na(all_refs) & nzchar(all_refs)]

  # Try to match each reference
  for (ref in all_refs) {
    # Try exact match first (no normalization)
    if (ref %in% node_labels_original) {
      result$exact_matches <- result$exact_matches + 1
      next
    }

    # Try normalized match (handles invisible chars, case, whitespace)
    ref_normalized <- normalize_element_name(ref, lowercase = TRUE)
    matches <- names(node_labels_normalized)[node_labels_normalized == ref_normalized]

    if (length(matches) > 0) {
      # Found a match - create mapping from original ref to original element name
      result$mapping[[ref]] <- matches[1]
      result$normalized_matches <- result$normalized_matches + 1

      # Check what kind of difference it was
      if (tolower(ref) == tolower(matches[1])) {
        diff_type <- "invisible chars"
      } else {
        diff_type <- "case/whitespace"
      }
      debug_log(sprintf("'%s' -> '%s' (%s)", ref, matches[1], diff_type), "NAME_MAPPING")
    } else {
      # No match found
      if (ref %in% from_refs) {
        result$unmatched_from <- c(result$unmatched_from, ref)
      }
      if (ref %in% to_refs) {
        result$unmatched_to <- c(result$unmatched_to, ref)
      }
    }
  }

  # Log summary
  debug_log(sprintf("Exact matches: %d, Normalized matches: %d, Unmatched: %d", result$exact_matches, result$normalized_matches, length(unique(c(result$unmatched_from, result$unmatched_to)))), "NAME_MAPPING")

  return(result)
}

#' Apply name mapping to connections
#'
#' Updates From/To values in connections to match element labels exactly.
#'
#' @param connections Data frame with connection data
#' @param mapping List mapping from connection names to element names
#' @return Updated connections data frame
apply_name_mapping <- function(connections, mapping) {
  if (length(mapping) == 0) return(connections)

  for (old_name in names(mapping)) {
    new_name <- mapping[[old_name]]
    connections$From[connections$From == old_name] <- new_name
    connections$To[connections$To == old_name] <- new_name
  }

  return(connections)
}

#' Normalize column names to standard format
#'
#' Handles case variations and common naming inconsistencies
#'
#' @param df Data frame to normalize
#' @return Data frame with normalized column names
normalize_column_names <- function(df) {
  cols <- names(df)
  cols_lower <- tolower(cols)

  # Standard mappings (case-insensitive)
  mappings <- list(
    "label" = "Label",
    "type" = "type",  # Keep lowercase for DAPSIWRM type
    "from" = "From",
    "to" = "To",
    "direction" = "Direction",
    "strength" = "Strength",
    "confidence" = "Confidence",
    "description" = "Description",
    "tags" = "Tags",
    "notes" = "Notes"
  )

  new_cols <- cols
  for (i in seq_along(cols)) {
    col_lower <- cols_lower[i]
    if (col_lower %in% names(mappings)) {
      new_cols[i] <- mappings[[col_lower]]
    }
  }

  names(df) <- new_cols
  return(df)
}

#' Infer nodes from edge data
#'
#' Creates a node list from unique From/To values in edges
#'
#' @param edges Edge data frame
#' @return Data frame with inferred nodes
infer_nodes_from_edges <- function(edges) {
  # Get unique node labels from From and To columns
  from_labels <- unique(as.character(edges$From))
  to_labels <- unique(as.character(edges$To))
  all_labels <- unique(c(from_labels, to_labels))
  all_labels <- all_labels[!is.na(all_labels) & nzchar(all_labels)]

  debug_log(paste("Inferred", length(all_labels), "unique nodes from edges\n"), "EXCEL_LOADER")

  # Try to get type information from edges if available
  nodes <- data.frame(
    Label = all_labels,
    type = NA_character_
    
  )

  # If edges have a 'type' column, try to map types to nodes
  if ("type" %in% names(edges)) {
    # Create mapping from labels to types (use first occurrence)
    type_map <- list()

    for (i in seq_len(nrow(edges))) {
      edge_type <- as.character(edges$type[i])
      if (!is.na(edge_type) && nzchar(edge_type)) {
        from_label <- as.character(edges$From[i])
        to_label <- as.character(edges$To[i])

        # The type in edge data might refer to the source or connection type
        # We'll need to analyze the pattern
        if (!from_label %in% names(type_map)) {
          type_map[[from_label]] <- edge_type
        }
      }
    }

    # Apply type map
    for (i in seq_len(nrow(nodes))) {
      label <- nodes$Label[i]
      if (label %in% names(type_map)) {
        nodes$type[i] <- type_map[[label]]
      }
    }
  }

  return(nodes)
}

#' Infer missing DAPSIWRM types from element names
#'
#' Uses keyword matching to guess types for elements with missing type values.
#' Requires dapsiwrm_type_inference.R to be sourced.
#'
#' @param elements Data frame with Label and type columns
#' @return Updated data frame with inferred types
infer_missing_types <- function(elements) {
  if (!("Label" %in% names(elements))) {
    debug_log("Cannot infer types: no Label column", "EXCEL_LOADER")
    return(elements)
  }

  if (!("type" %in% names(elements))) {
    elements$type <- NA_character_
  }

  # Check if inference function is available
  if (!exists("infer_dapsiwrm_type", mode = "function")) {
    debug_log("Type inference function not available, skipping", "EXCEL_LOADER")
    return(elements)
  }

  # Find elements needing type inference
  needs_type <- is.na(elements$type) | !nzchar(trimws(as.character(elements$type)))

  if (sum(needs_type) == 0) {
    return(elements)
  }

  debug_log(paste("Inferring types for", sum(needs_type), "elements...\n"), "EXCEL_LOADER")

  # Infer types
  for (i in which(needs_type)) {
    label <- elements$Label[i]
    if (!is.na(label) && nzchar(label)) {
      inferred <- infer_dapsiwrm_type(label, return_score = TRUE)
      if (!is.na(inferred$type)) {
        elements$type[i] <- inferred$type
        debug_log(sprintf("'%s' -> %s (keywords: %s)", substr(label, 1, 40), inferred$type, paste(head(inferred$matches, 2), collapse = ", ")), "EXCEL_LOADER")
      }
    }
  }

  inferred_count <- sum(needs_type) - sum(is.na(elements$type[needs_type]) |
                                           !nzchar(trimws(as.character(elements$type[needs_type]))))
  debug_log(paste("Successfully inferred", inferred_count, "types\n"), "EXCEL_LOADER")

  return(elements)
}

#' Infer node types from edge data
#'
#' When node sheet exists but lacks type column, try to get types from edges
#'
#' @param nodes Node data frame (without type)
#' @param edges Edge data frame (with type)
#' @return Updated node data frame with types
infer_node_types_from_edges <- function(nodes, edges) {
  if (!("Label" %in% names(nodes))) {
    return(nodes)
  }

  if (!("type" %in% names(edges))) {
    return(nodes)
  }

  # Build type mapping from edges
  # In many files, the edge 'type' column contains the DAPSIWRM type of the FROM node
  type_map <- list()

  for (i in seq_len(nrow(edges))) {
    from_label <- as.character(edges$From[i])
    edge_type <- as.character(edges$type[i])

    if (!is.na(from_label) && !is.na(edge_type) && nzchar(edge_type)) {
      if (!(from_label %in% names(type_map))) {
        type_map[[from_label]] <- edge_type
      }
    }
  }

  # Add type column to nodes
  nodes$type <- sapply(nodes$Label, function(lbl) {
    if (!is.na(lbl) && lbl %in% names(type_map)) type_map[[lbl]] else NA_character_
  })

  debug_log(paste("Inferred types for", sum(!is.na(nodes$type)), "of", nrow(nodes), "nodes\n"), "EXCEL_LOADER")

  return(nodes)
}

#' Validate universally loaded model data
#'
#' @param elements Element/node data frame
#' @param connections Connection/edge data frame
#' @return List with errors and warnings
validate_universal_model <- function(elements, connections) {
  result <- list(errors = character(), warnings = character())

  # Check elements
  if (is.null(elements) || !is.data.frame(elements)) {
    result$errors <- c(result$errors, "Elements data is invalid")
    return(result)
  }

  if (nrow(elements) == 0) {
    result$errors <- c(result$errors, "No elements/nodes found")
    return(result)
  }

  if (!("Label" %in% names(elements))) {
    result$errors <- c(result$errors, "Elements must have 'Label' column")
  }

  if (!("type" %in% names(elements))) {
    result$warnings <- c(result$warnings, "Elements missing 'type' column - DAPSIWRM classification unavailable")
  } else {
    # Check for known types
    valid_types <- c("Driver", "Activity", "Pressure", "State",
                     "Marine Process and Function", "Impact",
                     "Ecosystem Service", "Good and Benefit", "Welfare",
                     "Response", "Measure")
    actual_types <- unique(elements$type)
    actual_types <- actual_types[!is.na(actual_types)]

    unknown_types <- setdiff(actual_types, valid_types)
    if (length(unknown_types) > 0) {
      result$warnings <- c(result$warnings,
                          paste("Unknown element types found:", paste(unknown_types, collapse = ", ")))
    }

    debug_log(paste("Element types found:", paste(actual_types, collapse = ", ")), "EXCEL_LOADER")
  }

  # Check connections
  if (is.null(connections) || !is.data.frame(connections)) {
    result$errors <- c(result$errors, "Connections data is invalid")
    return(result)
  }

  if (nrow(connections) == 0) {
    result$warnings <- c(result$warnings, "No connections/edges found")
  }

  if (!("From" %in% names(connections)) || !("To" %in% names(connections))) {
    result$errors <- c(result$errors, "Connections must have 'From' and 'To' columns")
  }

  # Check for orphan connections (references to non-existent nodes)
  if ("Label" %in% names(elements) && "From" %in% names(connections) && "To" %in% names(connections)) {
    node_labels <- elements$Label
    from_labels <- unique(connections$From)
    to_labels <- unique(connections$To)

    missing_from <- setdiff(from_labels, node_labels)
    missing_to <- setdiff(to_labels, node_labels)
    missing_from <- missing_from[!is.na(missing_from)]
    missing_to <- missing_to[!is.na(missing_to)]

    if (length(missing_from) > 0 || length(missing_to) > 0) {
      all_missing <- unique(c(missing_from, missing_to))
      if (length(all_missing) <= 5) {
        result$warnings <- c(result$warnings,
                            paste("Connections reference unknown nodes:", paste(all_missing, collapse = ", ")))
      } else {
        result$warnings <- c(result$warnings,
                            paste("Connections reference", length(all_missing), "unknown nodes"))
      }
    }
  }

  return(result)
}

# ============================================================================
# GET AVAILABLE VARIANTS
# ============================================================================

#' Get available model variants in an Excel file
#'
#' @param file_path Path to the Excel file
#' @return List of variant names, or empty list if file unsupported
#' @export
get_model_variants <- function(file_path) {
  format_info <- detect_excel_format(file_path)

  if (format_info$format == "unsupported" || length(format_info$variants) == 0) {
    return(list())
  }

  variants <- lapply(format_info$variants, function(v) {
    list(
      name = v$name,
      node_sheet = v$node_sheet,
      edge_sheet = v$edge_sheet,
      note = if(!is.null(v$note)) v$note else NULL
    )
  })

  return(variants)
}

#' Get formatted choices for model variant selection
#'
#' @param file_path Path to the Excel file
#' @return Named list suitable for selectInput choices
#' @export
get_variant_choices <- function(file_path) {
  variants <- get_model_variants(file_path)

  if (length(variants) == 0) {
    return(list())
  }

  choices <- setNames(
    lapply(variants, function(v) v$name),
    sapply(variants, function(v) {
      if (!is.null(v$node_sheet)) {
        paste0(v$name, " (", v$node_sheet, " + ", v$edge_sheet, ")")
      } else {
        paste0(v$name, " (edges only)")
      }
    })
  )

  return(choices)
}
