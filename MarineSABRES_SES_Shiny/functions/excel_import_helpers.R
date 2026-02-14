# functions/excel_import_helpers.R
# Shared functions for importing Excel data to ISA framework structure
# Used by both import_data_module.R and ses_models_module.R

# ============================================================================
# SHARED HELPERS
# ============================================================================

#' Normalize a name string by handling invisible characters and whitespace
#'
#' Replaces non-breaking spaces, removes zero-width characters,
#' normalizes dashes, trims and collapses whitespace.
#'
#' @param name Character string to normalize
#' @return Normalized character string, or NA_character_ if input is NA/non-character
normalize_name <- function(name) {
  if (is.na(name) || !is.character(name)) return(NA_character_)
  normalized <- name
  # Replace non-breaking space with regular space
  normalized <- gsub("\u00A0", " ", normalized)
  # Remove zero-width characters
  normalized <- gsub("[\u200B\u200C\u200D\uFEFF]", "", normalized)
  # Replace en/em dashes with hyphen
  normalized <- gsub("[\u2013\u2014]", "-", normalized)
  # Trim and normalize whitespace
  normalized <- trimws(normalized)
  normalized <- gsub("\\s+", " ", normalized)
  return(normalized)
}

# ============================================================================
# EXCEL TO ISA CONVERSION
# ============================================================================

#' Convert Excel data to ISA framework structure
#'
#' @param elements Data frame with Element data (Label and type columns)
#' @param connections Data frame with Connection data (From, To, Label columns)
#' @return List with ISA data structure
#' @export
convert_excel_to_isa <- function(elements, connections) {
  debug_log("Converting Excel data to ISA structure...", "EXCEL_IMPORT")
  debug_log(paste("Elements sheet:", nrow(elements), "rows"), "EXCEL_IMPORT")
  debug_log(paste("Connections sheet:", nrow(connections), "rows"), "EXCEL_IMPORT")

  # Validate inputs
  if (is.null(connections) || !is.data.frame(connections) || nrow(connections) == 0) {
    stop("Connections data is NULL, not a data frame, or empty")
  }

  if (!("From" %in% names(connections)) || !("To" %in% names(connections))) {
    stop("Connections must have 'From' and 'To' columns")
  }

  # ============================================================================
  # NEW APPROACH: Build network FROM connections, then align with elements
  # ============================================================================

  debug_log("=== NEW APPROACH: Building network from connections ===", "EXCEL_IMPORT")

  # Step 1: Normalize connection From/To values
  connections$From <- sapply(as.character(connections$From), normalize_name)
  connections$To <- sapply(as.character(connections$To), normalize_name)

  # Step 2: Extract all unique nodes from connections
  from_nodes <- unique(connections$From[!is.na(connections$From) & nzchar(connections$From)])
  to_nodes <- unique(connections$To[!is.na(connections$To) & nzchar(connections$To)])
  all_connection_nodes <- unique(c(from_nodes, to_nodes))
  debug_log(paste("Unique nodes in connections:", length(all_connection_nodes)), "EXCEL_IMPORT")

  # Step 3: Create element lookup from elements sheet
  element_lookup <- list()  # name -> list(type, description)

  if (!is.null(elements) && is.data.frame(elements) && nrow(elements) > 0 && "Label" %in% names(elements)) {
    # Normalize element labels
    elements$Label <- sapply(as.character(elements$Label), normalize_name)

    # Get type column
    type_col <- find_type_column(elements)
    debug_log(paste("Element type column:", if(is.null(type_col)) "NOT FOUND" else type_col), "EXCEL_IMPORT")

    # Build lookup: normalized_name -> type
    for (i in seq_len(nrow(elements))) {
      label <- elements$Label[i]
      if (!is.na(label) && nzchar(label)) {
        elem_type <- if (!is.null(type_col)) as.character(elements[[type_col]][i]) else NA_character_
        elem_desc <- if ("Description" %in% names(elements)) as.character(elements$Description[i]) else ""
        element_lookup[[label]] <- list(type = elem_type, description = elem_desc)
      }
    }
    debug_log(paste("Element lookup built with", length(element_lookup), "entries"), "EXCEL_IMPORT")
  }

  # Step 4: For each node in connections, find its type
  node_types <- data.frame(
    Name = all_connection_nodes,
    type = NA_character_,
    source = "unknown",
    stringsAsFactors = FALSE
  )

  matched_count <- 0
  inferred_count <- 0

  for (i in seq_len(nrow(node_types))) {
    node_name <- node_types$Name[i]

    # Try exact match in element lookup
    if (node_name %in% names(element_lookup)) {
      node_types$type[i] <- element_lookup[[node_name]]$type
      node_types$source[i] <- "elements_sheet"
      matched_count <- matched_count + 1
    } else {
      # Try case-insensitive match
      element_names_lower <- tolower(names(element_lookup))
      match_idx <- which(element_names_lower == tolower(node_name))
      if (length(match_idx) > 0) {
        matched_name <- names(element_lookup)[match_idx[1]]
        node_types$type[i] <- element_lookup[[matched_name]]$type
        node_types$source[i] <- "elements_sheet_fuzzy"
        matched_count <- matched_count + 1
      }
    }
  }

  debug_log(paste("Matched", matched_count, "of", nrow(node_types), "nodes to elements sheet"), "EXCEL_IMPORT")

  # Step 5: Try to infer types for unmatched nodes
  if (exists("infer_dapsiwrm_type", mode = "function")) {
    for (i in seq_len(nrow(node_types))) {
      if (is.na(node_types$type[i]) || !nzchar(node_types$type[i])) {
        inferred <- infer_dapsiwrm_type(node_types$Name[i])
        if (!is.na(inferred)) {
          node_types$type[i] <- inferred
          node_types$source[i] <- "inferred"
          inferred_count <- inferred_count + 1
        }
      }
    }
    debug_log(paste("Inferred types for", inferred_count, "additional nodes"), "EXCEL_IMPORT")
  }

  # Log nodes still without types
  missing_type <- node_types[is.na(node_types$type) | !nzchar(node_types$type), ]
  if (nrow(missing_type) > 0) {
    debug_log(paste("WARNING:", nrow(missing_type), "nodes have no type:"), "EXCEL_IMPORT")
    for (j in seq_len(min(10, nrow(missing_type)))) {
      debug_log(paste0("- '", missing_type$Name[j], "'"), "EXCEL_IMPORT")
    }
    if (nrow(missing_type) > 10) {
      debug_log(paste("... and", nrow(missing_type) - 10, "more"), "EXCEL_IMPORT")
    }
  }

  # ============================================================================
  # Build ISA data structure from node_types
  # ============================================================================

  # Map element types to ISA categories
  type_mapping <- list(
    "Driver" = "drivers",
    "Activity" = "activities",
    "Pressure" = "pressures",
    "Marine Process and Function" = "marine_processes",
    "Marine Process and Functioning" = "marine_processes",
    "State" = "marine_processes",
    "State Change" = "marine_processes",
    "Ecosystem Service" = "ecosystem_services",
    "Impact" = "ecosystem_services",
    "Good and Benefit" = "goods_benefits",
    "Goods and Benefits" = "goods_benefits",
    "Welfare" = "goods_benefits",
    "Response" = "responses",
    "Measure" = "responses"
  )

  # Initialize ISA data structure
  isa_data <- list(
    drivers = NULL,
    activities = NULL,
    pressures = NULL,
    marine_processes = NULL,
    ecosystem_services = NULL,
    goods_benefits = NULL,
    responses = NULL,
    adjacency_matrices = list()
  )

  # Group nodes by ISA category
  for (type_name in names(type_mapping)) {
    isa_key <- type_mapping[[type_name]]

    # Find nodes with this type (case-insensitive)
    type_match <- !is.na(node_types$type) & tolower(node_types$type) == tolower(type_name)
    type_nodes <- node_types[type_match, ]

    if (nrow(type_nodes) > 0) {
      # Check if category already has data
      if (!is.null(isa_data[[isa_key]]) && nrow(isa_data[[isa_key]]) > 0) {
        existing_count <- nrow(isa_data[[isa_key]])
        # Check for duplicates before adding
        new_names <- setdiff(type_nodes$Name, isa_data[[isa_key]]$Name)
        if (length(new_names) > 0) {
          new_df <- data.frame(
            ID = paste0(substr(isa_key, 1, 1), (existing_count + 1):(existing_count + length(new_names))),
            Name = new_names,
            Description = "",
            stringsAsFactors = FALSE
          )
          isa_data[[isa_key]] <- rbind(isa_data[[isa_key]], new_df)
        }
      } else {
        df <- data.frame(
          ID = paste0(substr(isa_key, 1, 1), 1:nrow(type_nodes)),
          Name = type_nodes$Name,
          Description = "",
          stringsAsFactors = FALSE
        )
        isa_data[[isa_key]] <- df
      }
    }
  }

  # Log element counts
  total_categorized <- 0
  for (category in names(isa_data)) {
    if (category != "adjacency_matrices" && !is.null(isa_data[[category]])) {
      debug_log(paste("ISA", category, ":", nrow(isa_data[[category]]), "elements"), "EXCEL_IMPORT")
      total_categorized <- total_categorized + nrow(isa_data[[category]])
    }
  }
  debug_log(paste("Total categorized nodes:", total_categorized, "of", length(all_connection_nodes)), "EXCEL_IMPORT")

  # ============================================================================
  # Build adjacency matrices from connections
  # ============================================================================

  debug_log(paste("Building adjacency matrices from", nrow(connections), "connections..."), "EXCEL_IMPORT")
  isa_data$adjacency_matrices <- build_adjacency_matrices_from_connections_v2(
    node_types, connections, type_mapping, isa_data
  )
  debug_log(paste("Created", length(isa_data$adjacency_matrices), "adjacency matrices"), "EXCEL_IMPORT")

  # Count total connections in matrices
  total_matrix_connections <- 0
  for (mat_name in names(isa_data$adjacency_matrices)) {
    mat <- isa_data$adjacency_matrices[[mat_name]]
    total_matrix_connections <- total_matrix_connections + sum(mat != "")
  }
  debug_log(paste("Total connections in matrices:", total_matrix_connections, "of", nrow(connections), "original"), "EXCEL_IMPORT")

  return(isa_data)
}

#' Find the type column in elements data
#'
#' Excel sometimes renames duplicate column headers with ...N suffix
#'
#' @param elements Data frame with element data
#' @return Column name containing type info or NULL
find_type_column <- function(elements) {
  col_names <- names(elements)

  # Check for common type column names
  candidates <- c("type", "Type", "TYPE",
                  "type...2", "Type...2",
                  "element_type", "ElementType",
                  "category", "Category")

  for (col in candidates) {
    if (col %in% col_names) {
      return(col)
    }
  }

  # Check for any column containing "type"
  type_cols <- col_names[grepl("type", col_names, ignore.case = TRUE)]
  if (length(type_cols) > 0) {
    return(type_cols[1])
  }

  return(NULL)
}

#' Build adjacency matrices from connections (V2 - Connection-first approach)
#'
#' This version builds matrices using nodes derived from connections,
#' ensuring all edges in the input data are represented in the output.
#'
#' @param node_types Data frame with Name, type, source columns (nodes from connections)
#' @param connections Data frame with From, To, Label columns
#' @param type_mapping Mapping from type names to ISA categories
#' @param isa_data ISA data structure with element data frames
#' @return List of adjacency matrices
build_adjacency_matrices_from_connections_v2 <- function(node_types, connections, type_mapping, isa_data) {
  debug_log(paste("Building matrices from", nrow(connections), "connections..."), "EXCEL_IMPORT")

  # Category abbreviation mapping (using shared normalize_name)
  category_abbrev <- list(
    "drivers" = "d",
    "activities" = "a",
    "pressures" = "p",
    "marine_processes" = "mpf",
    "ecosystem_services" = "es",
    "goods_benefits" = "gb",
    "responses" = "r"
  )

  # Create name -> ISA category lookup from node_types
  name_to_isa_category <- list()
  for (i in seq_len(nrow(node_types))) {
    node_name <- node_types$Name[i]
    node_type <- node_types$type[i]

    if (!is.na(node_name) && !is.na(node_type) && nzchar(node_type)) {
      # Map the type to ISA category
      isa_cat <- NA_character_
      for (type_name in names(type_mapping)) {
        if (tolower(node_type) == tolower(type_name)) {
          isa_cat <- type_mapping[[type_name]]
          break
        }
      }
      if (!is.na(isa_cat)) {
        name_to_isa_category[[node_name]] <- isa_cat
      }
    }
  }

  debug_log(paste("Created lookup for", length(name_to_isa_category), "categorized nodes"), "EXCEL_IMPORT")

  # Group elements by ISA category (from isa_data which was built from connections)
  elements_by_category <- list()
  for (cat_name in names(category_abbrev)) {
    if (!is.null(isa_data[[cat_name]]) && nrow(isa_data[[cat_name]]) > 0) {
      elements_by_category[[cat_name]] <- isa_data[[cat_name]]$Name
    } else {
      elements_by_category[[cat_name]] <- character(0)
    }
  }

  # Debug: log category element counts
  for (cat_name in names(elements_by_category)) {
    if (length(elements_by_category[[cat_name]]) > 0) {
      debug_log(paste("Category", cat_name, ":", length(elements_by_category[[cat_name]]), "elements"), "EXCEL_IMPORT")
    }
  }

  # First pass: Identify all unique category pairs from connections
  category_pairs <- list()
  valid_connection_count <- 0
  orphan_count <- 0

  for (j in seq_len(nrow(connections))) {
    from_label <- normalize_name(as.character(connections$From[j]))
    to_label <- normalize_name(as.character(connections$To[j]))

    if (is.na(from_label) || is.na(to_label) || !nzchar(from_label) || !nzchar(to_label)) {
      next
    }

    from_cat <- name_to_isa_category[[from_label]]
    to_cat <- name_to_isa_category[[to_label]]

    if (!is.null(from_cat) && !is.null(to_cat) && !is.na(from_cat) && !is.na(to_cat)) {
      pair_key <- paste0(from_cat, "->", to_cat)
      if (!(pair_key %in% names(category_pairs))) {
        category_pairs[[pair_key]] <- list(from = from_cat, to = to_cat)
      }
      valid_connection_count <- valid_connection_count + 1
    } else {
      orphan_count <- orphan_count + 1
      if (orphan_count <= 5) {
        debug_log(paste0("Orphan connection: '", from_label, "' -> '", to_label, "'"), "EXCEL_IMPORT")
        debug_log(paste0("from_cat=", if(is.null(from_cat)) "NULL" else from_cat,
            ", to_cat=", if(is.null(to_cat)) "NULL" else to_cat), "EXCEL_IMPORT")
      }
    }
  }

  debug_log(paste("Found", length(category_pairs), "unique category pairs"), "EXCEL_IMPORT")
  debug_log(paste("Valid connections:", valid_connection_count, ", Orphan connections:", orphan_count), "EXCEL_IMPORT")

  # Create matrices for each category pair
  adjacency_matrices <- list()

  for (pair_key in names(category_pairs)) {
    pair <- category_pairs[[pair_key]]
    from_category <- pair$from
    to_category <- pair$to

    from_elements <- elements_by_category[[from_category]]
    to_elements <- elements_by_category[[to_category]]

    if (length(from_elements) == 0 || length(to_elements) == 0) {
      debug_log(paste("WARNING: Empty category for pair", pair_key), "EXCEL_IMPORT")
      next
    }

    # Create matrix: rows=FROM elements, cols=TO elements
    mat <- matrix("", nrow = length(from_elements), ncol = length(to_elements))
    rownames(mat) <- from_elements
    colnames(mat) <- to_elements

    # Fill matrix from connections
    connections_in_matrix <- 0

    for (j in seq_len(nrow(connections))) {
      from_label <- normalize_name(as.character(connections$From[j]))
      to_label <- normalize_name(as.character(connections$To[j]))

      if (is.na(from_label) || is.na(to_label) || !nzchar(from_label) || !nzchar(to_label)) {
        next
      }

      # Check if this connection belongs to this matrix
      conn_from_cat <- name_to_isa_category[[from_label]]
      conn_to_cat <- name_to_isa_category[[to_label]]

      if (is.null(conn_from_cat) || is.null(conn_to_cat) ||
          conn_from_cat != from_category || conn_to_cat != to_category) {
        next
      }

      # Verify both endpoints exist in the matrix
      if (!(from_label %in% from_elements) || !(to_label %in% to_elements)) {
        debug_log(paste0("WARNING: Element not in matrix: '", from_label, "' or '", to_label, "'"), "EXCEL_IMPORT")
        next
      }

      # Extract polarity
      polarity <- as.character(connections$Label[j])
      polarity_sign <- "+"
      if (!is.na(polarity) && nzchar(polarity)) {
        if (polarity %in% c("-") || grepl("^-", polarity, perl = TRUE)) {
          polarity_sign <- "-"
        }
      }

      # Extract strength
      strength <- "medium"
      if ("Strength" %in% names(connections)) {
        strength_val <- connections$Strength[j]
        if (!is.na(strength_val)) {
          strength_val <- tolower(as.character(strength_val))
          if (grepl("strong", strength_val)) strength <- "strong"
          else if (grepl("weak", strength_val)) strength <- "weak"
        }
      }

      # Extract confidence
      confidence <- 3
      if ("Confidence" %in% names(connections)) {
        conf_val <- connections$Confidence[j]
        if (!is.na(conf_val) && is.numeric(conf_val)) {
          confidence <- as.integer(conf_val)
        }
      }

      # Format cell value: +strength:confidence or -strength:confidence
      cell_value <- paste0(polarity_sign, strength, ":", confidence)
      mat[from_label, to_label] <- cell_value
      connections_in_matrix <- connections_in_matrix + 1
    }

    # Build matrix key
    from_abbrev <- category_abbrev[[from_category]]
    to_abbrev <- category_abbrev[[to_category]]
    matrix_key <- paste0(from_abbrev, "_", to_abbrev)

    adjacency_matrices[[matrix_key]] <- mat
    debug_log(paste("Matrix", matrix_key, ":", nrow(mat), "x", ncol(mat),
        "with", connections_in_matrix, "connections"), "EXCEL_IMPORT")
  }

  debug_log(paste("Created", length(adjacency_matrices), "matrices total"), "EXCEL_IMPORT")
  return(adjacency_matrices)
}
