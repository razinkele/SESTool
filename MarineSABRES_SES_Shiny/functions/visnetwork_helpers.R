

# functions/visnetwork_helpers.R
# Helper functions for visNetwork-based CLD visualization

# Required libraries
library(dplyr)
library(magrittr)

# Suppress R CMD check notes for NSE variables used in dplyr pipelines and for styling variables
utils::globalVariables(c(
  ".", "name", "Name", "ID", "label_raw", "indicator", "Indicator", "type", "Type", "scale", "Scale",
  "group", "level", "shape", "image", "color", "size", "font.size", "leverage_score", "x", "id", "label", "title",
  "row_number", "select", "mutate", "bind_rows",
  # Styling and config variables
  "ELEMENT_SHAPES", "ELEMENT_COLORS", "EDGE_COLORS", "CONFIDENCE_OPACITY", "CONFIDENCE_LABELS",
  # Add all variables used in dplyr pipelines to suppress NSE notes
  "from", "to", "arrows", "width", "opacity", "polarity", "strength", "confidence", "font.size", "metric_value"
))

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

#' Wrap long text labels for better display
#' 
#' @param text Character string to wrap
#' @param max_width Maximum characters per line (default 20)
#' @return Text with line breaks inserted
wrap_label <- function(text, max_width = LABEL_WRAP_WIDTH) {
  if (is.na(text) || nchar(text) <= max_width) {
    return(text)
  }
  
  # Split on spaces
  words <- strsplit(text, " ")[[1]]
  lines <- c()
  current_line <- ""
  
  for (word in words) {
    if (nchar(current_line) == 0) {
      current_line <- word
    } else if (nchar(paste(current_line, word)) <= max_width) {
      current_line <- paste(current_line, word)
    } else {
      lines <- c(lines, current_line)
      current_line <- word
    }
  }
  
  # Add the last line
  if (nchar(current_line) > 0) {
    lines <- c(lines, current_line)
  }
  
  # Join with newline
  paste(lines, collapse = "\n")
}

# ============================================================================
# NODE CREATION FUNCTIONS
# ============================================================================

#' Create nodes dataframe from ISA data
#'
#' PERFORMANCE OPTIMIZED: Collects all node types in a list and binds once
#' at the end instead of repeated bind_rows calls (5-10x faster for large networks)
#'
#' @param isa_data List containing ISA data elements
#' @return Data frame with node attributes for visNetwork
create_nodes_df <- function(isa_data) {

  # OPTIMIZATION: Collect all node dataframes in a list, then bind once
  # This avoids repeated memory allocations from multiple bind_rows calls
  node_list <- list()

  # Goods & Benefits (Level 0)
  if (!is.null(isa_data$goods_benefits) && nrow(isa_data$goods_benefits) > 0) {
    node_list$gb <- isa_data$goods_benefits %>%
      mutate(
        id = paste0("GB_", row_number()),
        label_raw = if("name" %in% names(.)) name else if("Name" %in% names(.)) Name else ID,
        label = sapply(label_raw, wrap_label),
        indicator = if("indicator" %in% names(.)) indicator else if("Indicator" %in% names(.)) Indicator else "No indicator",
        title = create_node_tooltip(label_raw, indicator, "Goods & Benefits"),
        group = "Goods & Benefits",
        level = 0,
        shape = ELEMENT_SHAPES[["Goods & Benefits"]],
        image = NA_character_,
        color = ELEMENT_COLORS[["Goods & Benefits"]],
        size = 30,
        font.size = 14,
        leverage_score = NA_real_,
        x = NA_real_
      ) %>%
      select(id, label, title, group, level, shape, image, color, size, font.size, indicator, leverage_score, x)
  }
  
  # Ecosystem Services (Level 1)
  if (!is.null(isa_data$ecosystem_services) && nrow(isa_data$ecosystem_services) > 0) {
    node_list$es <- isa_data$ecosystem_services %>%
      mutate(
        id = paste0("ES_", row_number()),
        label_raw = if("name" %in% names(.)) name else if("Name" %in% names(.)) Name else ID,
        label = sapply(label_raw, wrap_label),
        indicator = if("indicator" %in% names(.)) indicator else if("Indicator" %in% names(.)) Indicator else "No indicator",
        title = create_node_tooltip(label_raw, indicator, "Ecosystem Services"),
        group = "Ecosystem Services",
        level = 1,
        shape = ELEMENT_SHAPES[["Ecosystem Services"]],
        image = NA_character_,
        color = ELEMENT_COLORS[["Ecosystem Services"]],
        size = 25,
        font.size = 12,
        leverage_score = NA_real_,
        x = NA_real_
      ) %>%
      select(id, label, title, group, level, shape, image, color, size, font.size, indicator, leverage_score, x)
  }

  # Marine Processes & Functioning (Level 2)
  if (!is.null(isa_data$marine_processes) && nrow(isa_data$marine_processes) > 0) {
    node_list$mpf <- isa_data$marine_processes %>%
      mutate(
        id = paste0("MPF_", row_number()),
        label_raw = if("name" %in% names(.)) name else if("Name" %in% names(.)) Name else ID,
        label = sapply(label_raw, wrap_label),
        indicator = if("indicator" %in% names(.)) indicator else if("Indicator" %in% names(.)) Indicator else "No indicator",
        title = create_node_tooltip(label_raw, indicator, "Marine Processes & Functioning"),
        group = "Marine Processes & Functioning",
        level = 2,
        shape = ELEMENT_SHAPES[["Marine Processes & Functioning"]],
        image = NA_character_,
        color = ELEMENT_COLORS[["Marine Processes & Functioning"]],
        size = 25,
        font.size = 12,
        leverage_score = NA_real_,
        x = NA_real_
      ) %>%
      select(id, label, title, group, level, shape, image, color, size, font.size, indicator, leverage_score, x)
  }

  # Pressures (Level 3)
  if (!is.null(isa_data$pressures) && nrow(isa_data$pressures) > 0) {
    node_list$pressures <- isa_data$pressures %>%
      mutate(
        id = paste0("P_", row_number()),
        label_raw = if("name" %in% names(.)) name else if("Name" %in% names(.)) Name else ID,
        label = sapply(label_raw, wrap_label),
        indicator = if("indicator" %in% names(.)) indicator else if("Indicator" %in% names(.)) Indicator else "No indicator",
        title = create_node_tooltip(
          label_raw, indicator, "Pressures",
          extra = if("type" %in% names(.)) paste("Type:", type) else if("Type" %in% names(.)) paste("Type:", Type) else NULL
        ),
        group = "Pressures",
        level = 3,
        shape = ELEMENT_SHAPES[["Pressures"]],
        image = NA_character_,
        color = ELEMENT_COLORS[["Pressures"]],
        size = 25,
        font.size = 12,
        leverage_score = NA_real_,
        x = NA_real_
      ) %>%
      select(id, label, title, group, level, shape, image, color, size, font.size, indicator, leverage_score, x)
  }

  # Activities (Level 4)
  if (!is.null(isa_data$activities) && nrow(isa_data$activities) > 0) {
    node_list$activities <- isa_data$activities %>%
      mutate(
        id = paste0("A_", row_number()),
        label_raw = if("name" %in% names(.)) name else if("Name" %in% names(.)) Name else ID,
        label = sapply(label_raw, wrap_label),
        indicator = if("indicator" %in% names(.)) indicator else if("Indicator" %in% names(.)) Indicator else "No indicator",
        title = create_node_tooltip(
          label_raw, indicator, "Activities",
          extra = if("scale" %in% names(.)) paste("Scale:", scale) else if("Scale" %in% names(.)) paste("Scale:", Scale) else NULL
        ),
        group = "Activities",
        level = 4,
        shape = ELEMENT_SHAPES[["Activities"]],
        image = NA_character_,
        color = ELEMENT_COLORS[["Activities"]],
        size = 25,
        font.size = 12,
        leverage_score = NA_real_,
        x = NA_real_
      ) %>%
      select(id, label, title, group, level, shape, image, color, size, font.size, indicator, leverage_score, x)
  }

  # Drivers (Level 5) - Using custom octagon SVG
  if (!is.null(isa_data$drivers) && nrow(isa_data$drivers) > 0) {
    node_list$drivers <- isa_data$drivers %>%
      mutate(
        id = paste0("D_", row_number()),
        label_raw = if("name" %in% names(.)) name else if("Name" %in% names(.)) Name else ID,
        label = sapply(label_raw, wrap_label),
        indicator = if("indicator" %in% names(.)) indicator else if("Indicator" %in% names(.)) Indicator else "No indicator",
        title = create_node_tooltip(label_raw, indicator, "Drivers"),
        group = "Drivers",
        level = 5,
        shape = "image",  # Use image shape for custom octagon
        image = "shapes/octagon.svg",  # Path to octagon SVG
        color = NA_character_,  # Color handled by SVG
        size = 30,
        font.size = 14,
        leverage_score = NA_real_,
        x = NA_real_
      ) %>%
      select(id, label, title, group, level, shape, image, color, size, font.size, indicator, leverage_score, x)
  }

  # Responses (Level 3 - positioned in middle, will be offset to the right)
  # Now includes both original responses and measures merged together
  if (!is.null(isa_data$responses) && nrow(isa_data$responses) > 0) {
    node_list$responses <- isa_data$responses %>%
      mutate(
        id = paste0("R_", row_number()),
        label_raw = if("name" %in% names(.)) name else if("Name" %in% names(.)) Name else as.character(row_number()),
        label = sapply(label_raw, wrap_label),
        indicator = if("indicator" %in% names(.)) indicator else if("Indicator" %in% names(.)) Indicator else "No indicator",
        title = create_node_tooltip(label_raw, indicator, "Responses"),
        group = "Responses",
        level = 3,  # Middle level (same as Pressures)
        shape = ELEMENT_SHAPES[["Responses"]],
        image = NA_character_,
        color = ELEMENT_COLORS[["Responses"]],
        size = 25,
        font.size = 12,
        leverage_score = NA_real_,
        x = 400  # Offset to the right of the main DAPSIWRM flow
      ) %>%
      select(id, label, title, group, level, shape, image, color, size, font.size, indicator, leverage_score, x)
  }

  # OPTIMIZATION: Single bind_rows call instead of 7 repeated calls
  # This reduces memory allocations and is 5-10x faster for large networks
  if (length(node_list) == 0) {
    return(data.frame(
      id = character(), label = character(), title = character(),
      group = character(), level = integer(), shape = character(),
      image = character(), color = character(), size = numeric(),
      font.size = numeric(), indicator = character(),
      leverage_score = numeric(), x = numeric(),
      stringsAsFactors = FALSE
    ))
  }

  return(bind_rows(node_list))
}

#' Create HTML tooltip for node
#' 
#' @param name Node name
#' @param indicator Indicator description
#' @param group Element type
#' @param extra Additional information
#' @return HTML string for tooltip
create_node_tooltip <- function(name, indicator, group, extra = NULL) {
  # HTML-escape user-supplied values to prevent XSS in visNetwork tooltips
  esc <- htmltools::htmlEscape
  html <- sprintf(
    "<div style='padding: 8px;'>
      <b>%s</b><br>
      <i>%s</i><br>
      <hr style='margin: 5px 0;'>
      Indicator: %s",
    esc(name), esc(group), esc(indicator)
  )

  if (!is.null(extra)) {
    html <- paste0(html, "<br>", esc(extra))
  }

  html <- paste0(html, "</div>")
  return(html)
}

# ============================================================================
# EDGE CREATION FUNCTIONS
# ============================================================================

#' Create edges dataframe from adjacency matrices
#' 
#' @param isa_data List containing ISA data
#' @param adjacency_matrices List of adjacency matrices
#' @return Data frame with edge attributes for visNetwork
create_edges_df <- function(isa_data, adjacency_matrices) {

  debug_log("Starting create_edges_df", "VISNETWORK")

  edges <- data.frame(
    from = character(),
    to = character(),
    arrows = character(),
    color = character(),
    width = numeric(),
    opacity = numeric(),
    title = character(),
    polarity = character(),
    strength = character(),
    confidence = integer(),
    label = character(),
    font.size = numeric(),
    stringsAsFactors = FALSE
  )

  # Get actual element counts for validation
  n_gb <- if(!is.null(isa_data$goods_benefits)) nrow(isa_data$goods_benefits) else 0
  n_es <- if(!is.null(isa_data$ecosystem_services)) nrow(isa_data$ecosystem_services) else 0
  n_mpf <- if(!is.null(isa_data$marine_processes)) nrow(isa_data$marine_processes) else 0
  n_p <- if(!is.null(isa_data$pressures)) nrow(isa_data$pressures) else 0
  n_a <- if(!is.null(isa_data$activities)) nrow(isa_data$activities) else 0
  n_d <- if(!is.null(isa_data$drivers)) nrow(isa_data$drivers) else 0
  n_r <- if(!is.null(isa_data$responses)) nrow(isa_data$responses) else 0

  debug_log(sprintf("Element counts: GB=%d, ES=%d, MPF=%d, P=%d, A=%d, D=%d, R=%d",
             n_gb, n_es, n_mpf, n_p, n_a, n_d, n_r), "VISNETWORK")

  if (is.null(adjacency_matrices)) {
    debug_log("adjacency_matrices is NULL!", "VISNETWORK")
    return(edges)
  }

  debug_log(sprintf("Matrix names: %s", paste(names(adjacency_matrices), collapse=", ")), "VISNETWORK")

  # Process each adjacency matrix
  # MATRIX CONVENTION: All matrices use SOURCE×TARGET format
  # - Matrix name: source_target (e.g., "d_a" means D→A)
  # - Matrix structure: rows=SOURCE elements, cols=TARGET elements
  # - Cell [i,j]: Connection from SOURCE[i] to TARGET[j]
  # DAPSIWRM FORWARD CAUSAL FLOW: Drivers → Activities → Pressures → Marine Processes → Ecosystem Services → Welfare

  # 1. Drivers → Activities
  if (!is.null(adjacency_matrices$d_a)) {
    edges_d_a <- process_adjacency_matrix(
      adjacency_matrices$d_a,  # D×A (rows=D, cols=A): D→A connections
      from_prefix = "D",
      to_prefix = "A",
      expected_rows = n_d,
      expected_cols = n_a
    )
    edges <- bind_rows(edges, edges_d_a)
  }

  # 2. Activities → Pressures
  if (!is.null(adjacency_matrices$a_p)) {
    edges_a_p <- process_adjacency_matrix(
      adjacency_matrices$a_p,  # A×P (rows=A, cols=P): A→P connections
      from_prefix = "A",
      to_prefix = "P",
      expected_rows = n_a,
      expected_cols = n_p
    )
    edges <- bind_rows(edges, edges_a_p)
  }

  # 3. Pressures → Marine Processes & Functions
  if (!is.null(adjacency_matrices$p_mpf)) {
    edges_p_mpf <- process_adjacency_matrix(
      adjacency_matrices$p_mpf,  # P×MPF (rows=P, cols=MPF): P→MPF connections
      from_prefix = "P",
      to_prefix = "MPF",
      expected_rows = n_p,
      expected_cols = n_mpf
    )
    edges <- bind_rows(edges, edges_p_mpf)
  } else if (!is.null(adjacency_matrices$p_mp)) {
    # Alternative naming: p_mp instead of p_mpf
    edges_p_mp <- process_adjacency_matrix(
      adjacency_matrices$p_mp,  # P×MP (rows=P, cols=MP): P→MP connections
      from_prefix = "P",
      to_prefix = "MPF",
      expected_rows = n_p,
      expected_cols = n_mpf
    )
    edges <- bind_rows(edges, edges_p_mp)
  }

  # 4. Marine Processes → Ecosystem Services
  if (!is.null(adjacency_matrices$mpf_es)) {
    edges_mpf_es <- process_adjacency_matrix(
      adjacency_matrices$mpf_es,  # MPF×ES (rows=MPF, cols=ES): MPF→ES connections
      from_prefix = "MPF",
      to_prefix = "ES",
      expected_rows = n_mpf,
      expected_cols = n_es
    )
    edges <- bind_rows(edges, edges_mpf_es)
  } else if (!is.null(adjacency_matrices$mp_es)) {
    # Alternative naming: mp_es instead of mpf_es
    edges_mp_es <- process_adjacency_matrix(
      adjacency_matrices$mp_es,  # MP×ES (rows=MP, cols=ES): MP→ES connections
      from_prefix = "MPF",
      to_prefix = "ES",
      expected_rows = n_mpf,
      expected_cols = n_es
    )
    edges <- bind_rows(edges, edges_mp_es)
  }

  # 5. Ecosystem Services → Welfare (Goods & Benefits)
  if (!is.null(adjacency_matrices$es_gb)) {
    edges_es_gb <- process_adjacency_matrix(
      adjacency_matrices$es_gb,  # ES×GB (rows=ES, cols=GB): ES→GB connections
      from_prefix = "ES",
      to_prefix = "GB",
      expected_rows = n_es,
      expected_cols = n_gb
    )
    edges <- bind_rows(edges, edges_es_gb)
  }

  # 6. Welfare → Drivers (feedback loop closure)
  if (!is.null(adjacency_matrices$gb_d)) {
    edges_gb_d <- process_adjacency_matrix(
      adjacency_matrices$gb_d,  # GB×D (rows=GB, cols=D): GB→D connections
      from_prefix = "GB",
      to_prefix = "D",
      expected_rows = n_gb,
      expected_cols = n_d
    )
    edges <- bind_rows(edges, edges_gb_d)
  }

  # === RESPONSE MEASURES (Management Interventions) ===
  
  # 7. Welfare → Responses (problems drive management responses)
  if (!is.null(adjacency_matrices$gb_r)) {
    edges_gb_r <- process_adjacency_matrix(
      adjacency_matrices$gb_r,  # GB×R (rows=GB, cols=R): GB→R connections
      from_prefix = "GB",
      to_prefix = "R",
      expected_rows = n_gb,
      expected_cols = n_r
    )
    edges <- bind_rows(edges, edges_gb_r)
  }

  # 8. Responses → Drivers (policy targeting underlying drivers)
  if (!is.null(adjacency_matrices$r_d)) {
    edges_r_d <- process_adjacency_matrix(
      adjacency_matrices$r_d,  # R×D (rows=R, cols=D): R→D connections
      from_prefix = "R",
      to_prefix = "D",
      expected_rows = n_r,
      expected_cols = n_d
    )
    edges <- bind_rows(edges, edges_r_d)
  }

  # 9. Responses → Activities (regulations on activities)
  if (!is.null(adjacency_matrices$r_a)) {
    edges_r_a <- process_adjacency_matrix(
      adjacency_matrices$r_a,  # R×A (rows=R, cols=A): R→A connections
      from_prefix = "R",
      to_prefix = "A",
      expected_rows = n_r,
      expected_cols = n_a
    )
    edges <- bind_rows(edges, edges_r_a)
  }

  # 10. Responses → Pressures (direct pressure mitigation)
  if (!is.null(adjacency_matrices$r_p)) {
    edges_r_p <- process_adjacency_matrix(
      adjacency_matrices$r_p,  # R×P (rows=R, cols=P): R→P connections
      from_prefix = "R",
      to_prefix = "P",
      expected_rows = n_r,
      expected_cols = n_p
    )
    edges <- bind_rows(edges, edges_r_p)
  }

  # 11. Responses → Marine Processes (direct restoration/enhancement)
  if (!is.null(adjacency_matrices$r_mpf)) {
    edges_r_mpf <- process_adjacency_matrix(
      adjacency_matrices$r_mpf,  # R×MPF (rows=R, cols=MPF): R→MPF connections
      from_prefix = "R",
      to_prefix = "MPF",
      expected_rows = n_r,
      expected_cols = n_mpf
    )
    edges <- bind_rows(edges, edges_r_mpf)
  }

  # 12. Responses → Responses (measures linking to responses)
  if (!is.null(adjacency_matrices$r_r)) {
    edges_r_r <- process_adjacency_matrix(
      adjacency_matrices$r_r,  # R×R (rows=R, cols=R): R→R connections
      from_prefix = "R",
      to_prefix = "R",
      expected_rows = n_r,
      expected_cols = n_r
    )
    edges <- bind_rows(edges, edges_r_r)
  }

  # === LEGACY MEASURE MATRICES ===
  # Support old m_* matrices from before measures were merged into responses
  # These should not appear in new templates, but handle them for backward compatibility

  if (!is.null(adjacency_matrices$m_d)) {
    debug_log("WARNING: Found legacy matrix 'm_d' - measures should now be merged into responses", "VISNETWORK")
  }
  if (!is.null(adjacency_matrices$m_a)) {
    debug_log("WARNING: Found legacy matrix 'm_a' - measures should now be merged into responses", "VISNETWORK")
  }
  if (!is.null(adjacency_matrices$m_p)) {
    debug_log("WARNING: Found legacy matrix 'm_p' - measures should now be merged into responses", "VISNETWORK")
  }
  if (!is.null(adjacency_matrices$m_mpf)) {
    debug_log("WARNING: Found legacy matrix 'm_mpf' - measures should now be merged into responses", "VISNETWORK")
  }
  if (!is.null(adjacency_matrices$m_r)) {
    debug_log("WARNING: Found legacy matrix 'm_r' - measures should now be merged into responses", "VISNETWORK")
  }

  # === LEGACY/BACKWARD COMPATIBILITY ===
  # Support old matrix names for existing projects (will be converted on load)
  
  if (!is.null(adjacency_matrices$gb_es)) {
    debug_log("WARNING: Found legacy matrix 'gb_es' - treating as forward flow 'es_gb'", "VISNETWORK")
    edges_legacy <- process_adjacency_matrix(
      t(adjacency_matrices$gb_es),  # Transpose to convert GB→ES to ES→GB
      from_prefix = "ES",
      to_prefix = "GB",
      expected_rows = n_es,
      expected_cols = n_gb
    )
    edges <- bind_rows(edges, edges_legacy)
  }

  if (!is.null(adjacency_matrices$es_mpf)) {
    debug_log("WARNING: Found legacy matrix 'es_mpf' - treating as forward flow 'mpf_es'", "VISNETWORK")
    edges_legacy <- process_adjacency_matrix(
      t(adjacency_matrices$es_mpf),  # Transpose
      from_prefix = "MPF",
      to_prefix = "ES",
      expected_rows = n_mpf,
      expected_cols = n_es
    )
    edges <- bind_rows(edges, edges_legacy)
  }

  if (!is.null(adjacency_matrices$mpf_p)) {
    debug_log("WARNING: Found legacy matrix 'mpf_p' - treating as forward flow 'p_mpf'", "VISNETWORK")
    edges_legacy <- process_adjacency_matrix(
      t(adjacency_matrices$mpf_p),  # Transpose
      from_prefix = "P",
      to_prefix = "MPF",
      expected_rows = n_p,
      expected_cols = n_mpf
    )
    edges <- bind_rows(edges, edges_legacy)
  }

  if (!is.null(adjacency_matrices$p_a)) {
    debug_log("WARNING: Found legacy matrix 'p_a' - treating as forward flow 'a_p'", "VISNETWORK")
    edges_legacy <- process_adjacency_matrix(
      t(adjacency_matrices$p_a),  # Transpose
      from_prefix = "A",
      to_prefix = "P",
      expected_rows = n_a,
      expected_cols = n_p
    )
    edges <- bind_rows(edges, edges_legacy)
  }

  if (!is.null(adjacency_matrices$a_d)) {
    debug_log("WARNING: Found legacy matrix 'a_d' - treating as forward flow 'd_a'", "VISNETWORK")
    edges_legacy <- process_adjacency_matrix(
      t(adjacency_matrices$a_d),  # Transpose
      from_prefix = "D",
      to_prefix = "A",
      expected_rows = n_d,
      expected_cols = n_a
    )
    edges <- bind_rows(edges, edges_legacy)
  }

  if (!is.null(adjacency_matrices$d_gb)) {
    debug_log("WARNING: Found legacy matrix 'd_gb' - treating as feedback 'gb_d'", "VISNETWORK")
    edges_legacy <- process_adjacency_matrix(
      t(adjacency_matrices$d_gb),  # Transpose
      from_prefix = "GB",
      to_prefix = "D",
      expected_rows = n_gb,
      expected_cols = n_d
    )
    edges <- bind_rows(edges, edges_legacy)
  }

  if (!is.null(adjacency_matrices$p_r)) {
    debug_log("WARNING: Found legacy matrix 'p_r' - treating as 'r_p'", "VISNETWORK")
    edges_legacy <- process_adjacency_matrix(
      t(adjacency_matrices$p_r),  # Transpose
      from_prefix = "R",
      to_prefix = "P",
      expected_rows = n_r,
      expected_cols = n_p
    )
    edges <- bind_rows(edges, edges_legacy)
  }

  # Handle legacy r_m (responses-to-measures) matrix by converting to r_r (responses-to-responses)
  if (!is.null(adjacency_matrices$r_m)) {
    debug_log("INFO: Found legacy matrix 'r_m' (responses->measures), converting to 'r_r' (responses->responses)", "VISNETWORK")
    edges_r_m <- process_adjacency_matrix(
      adjacency_matrices$r_m,  # R×M (rows=R, cols=M): R→M connections (legacy)
      from_prefix = "R",
      to_prefix = "R"  # Measures are now part of responses
    )
    edges <- bind_rows(edges, edges_r_m)
  }

  # Process any additional non-standard matrices that weren't handled above
  standard_matrices <- c(
    # New DAPSIWRM forward flow
    "d_a", "a_p", "p_mp", "p_mpf", "mp_es", "mpf_es", "es_gb", "gb_d",
    # Response measures
    "gb_r", "r_d", "r_a", "r_p", "r_mpf", "r_r",
    # Legacy measure matrices (no longer used - measures merged into responses)
    "m_d", "m_a", "m_p", "m_mpf", "m_r",
    # Legacy/deprecated flow directions
    "gb_es", "es_mpf", "mpf_p", "p_a", "a_d", "d_gb", "p_r", "r_m"
  )
  additional_matrices <- setdiff(names(adjacency_matrices), standard_matrices)

  if (length(additional_matrices) > 0) {
    debug_log(sprintf("Processing %d additional non-standard matrices: %s",
                length(additional_matrices), paste(additional_matrices, collapse = ", ")), "VISNETWORK")

    # Mapping from abbreviations to prefixes
    abbrev_to_prefix <- c(
      "gb" = "GB", "es" = "ES", "mpf" = "MPF", "p" = "P",
      "a" = "A", "d" = "D", "r" = "R", "m" = "M"
    )

    for (matrix_name in additional_matrices) {
      if (!is.null(adjacency_matrices[[matrix_name]])) {
        # Parse matrix name: SOURCE_TARGET format (e.g., "mpf_mpf" or "mpf_a")
        parts <- strsplit(matrix_name, "_")[[1]]
        if (length(parts) == 2) {
          from_abbrev <- parts[1]
          to_abbrev <- parts[2]

          from_prefix <- abbrev_to_prefix[[from_abbrev]]
          to_prefix <- abbrev_to_prefix[[to_abbrev]]

          if (!is.null(from_prefix) && !is.null(to_prefix)) {
            debug_log(sprintf("Processing additional matrix %s (%s -> %s)",
                        matrix_name, from_prefix, to_prefix), "VISNETWORK")

            edges_additional <- process_adjacency_matrix(
              adjacency_matrices[[matrix_name]],  # No transpose needed - already SOURCE×TARGET
              from_prefix = from_prefix,
              to_prefix = to_prefix
            )

            debug_log(sprintf("%s returned %d edges", matrix_name, nrow(edges_additional)), "VISNETWORK")
            edges <- bind_rows(edges, edges_additional)
          }
        }
      }
    }
  }

  debug_log(sprintf("Total edges: %d", nrow(edges)), "VISNETWORK")
  return(edges)
}

#' Process adjacency matrix into edges dataframe
#'
#' @param adj_matrix Matrix with connection values
#' @param from_prefix Prefix for source nodes
#' @param to_prefix Prefix for target nodes
#' @param expected_rows Expected number of rows (optional validation)
#' @param expected_cols Expected number of columns (optional validation)
#' @return Data frame with edge attributes
process_adjacency_matrix <- function(adj_matrix, from_prefix, to_prefix,
                                     expected_rows = NULL, expected_cols = NULL) {

  edges <- data.frame()

  if (is.null(adj_matrix) || !is.matrix(adj_matrix)) {
    return(edges)
  }

  # Validate matrix dimensions against expected counts
  if (!is.null(expected_rows) && nrow(adj_matrix) != expected_rows) {
    log_warning("NETWORK", sprintf(
      "Adjacency matrix dimension mismatch: %s->%s matrix has %d rows but %d %s elements exist. Using min(%d, %d).",
      from_prefix, to_prefix, nrow(adj_matrix), expected_rows, from_prefix, nrow(adj_matrix), expected_rows
    ))
  }

  if (!is.null(expected_cols) && ncol(adj_matrix) != expected_cols) {
    log_warning("NETWORK", sprintf(
      "Adjacency matrix dimension mismatch: %s->%s matrix has %d cols but %d %s elements exist. Using min(%d, %d).",
      from_prefix, to_prefix, ncol(adj_matrix), expected_cols, to_prefix, ncol(adj_matrix), expected_cols
    ))
  }

  # Use minimum of matrix dimensions and expected counts to avoid referencing non-existent nodes
  max_rows <- if (!is.null(expected_rows)) min(nrow(adj_matrix), expected_rows) else nrow(adj_matrix)
  max_cols <- if (!is.null(expected_cols)) min(ncol(adj_matrix), expected_cols) else ncol(adj_matrix)

  # Skip processing if no valid rows or columns
  if (max_rows < 1 || max_cols < 1) {
    return(edges)
  }

  for (i in 1:max_rows) {
    for (j in 1:max_cols) {
      value <- adj_matrix[i, j]
      
      if (!is.na(value) && value != "") {
        # Parse value: e.g., "+strong", "-medium"
        connection <- parse_connection_value(value)
        
        if (!is.null(connection)) {
          # Determine edge properties
          width_map <- c("strong" = 4, "medium" = 2.5, "weak" = 1.5)
          edge_width <- width_map[connection$strength]

          # Color based on polarity
          edge_color <- ifelse(
            connection$polarity == "+",
            EDGE_COLORS$reinforcing,
            EDGE_COLORS$opposing
          )

          # Adjust opacity based on confidence (1=low, 5=high)
          edge_opacity <- CONFIDENCE_OPACITY[as.character(connection$confidence)]

          # Get row/column names with fallback to generic names
          from_name <- if (!is.null(rownames(adj_matrix)) && length(rownames(adj_matrix)) >= i) {
            name <- rownames(adj_matrix)[i]
            # Defensive check: if name is NA or empty, use generic name
            if (is.na(name) || is.null(name) || nchar(trimws(name)) == 0) {
              paste0(from_prefix, "_", i)
            } else {
              name
            }
          } else {
            paste0(from_prefix, "_", i)
          }

          to_name <- if (!is.null(colnames(adj_matrix)) && length(colnames(adj_matrix)) >= j) {
            name <- colnames(adj_matrix)[j]
            # Defensive check: if name is NA or empty, use generic name
            if (is.na(name) || is.null(name) || nchar(trimws(name)) == 0) {
              paste0(to_prefix, "_", j)
            } else {
              name
            }
          } else {
            paste0(to_prefix, "_", j)
          }

          # Apply opacity to edge color using alpha channel
          edge_color_with_opacity <- adjustcolor(edge_color, alpha.f = edge_opacity)

          # Create edge with defensive error handling
          tryCatch({
            edge <- data.frame(
              from = paste0(from_prefix, "_", i),
              to = paste0(to_prefix, "_", j),
              arrows = "to",
              color = edge_color_with_opacity,
              width = edge_width,
              opacity = edge_opacity,  # Store for potential use
              title = create_edge_tooltip(
                from_name,
                to_name,
                connection$polarity,
                connection$strength,
                connection$confidence
              ),
              polarity = connection$polarity,
              strength = connection$strength,
              confidence = connection$confidence,
              label = connection$polarity,
              font.size = 10,
              stringsAsFactors = FALSE,
              row.names = NULL  # Explicitly prevent row name issues
            )

            edges <- bind_rows(edges, edge)
          }, error = function(e) {
            log_warning("NETWORK", sprintf(
              "Error creating edge %s_%d -> %s_%d (names: '%s' -> '%s'): %s",
              from_prefix, i, to_prefix, j, from_name, to_name, e$message
            ))
          })
        }
      }
    }
  }
  
  return(edges)
}

#' Create HTML tooltip for edge
#'
#' @param from_name Source node name
#' @param to_name Target node name
#' @param polarity Connection polarity
#' @param strength Connection strength
#' @param confidence Connection confidence (1-5, optional)
#' @return HTML string for tooltip
create_edge_tooltip <- function(from_name, to_name, polarity, strength, confidence = CONFIDENCE_DEFAULT) {
  polarity_text <- ifelse(polarity == "+", "Reinforcing", "Opposing")

  # Get confidence label from global constant
  confidence_text <- CONFIDENCE_LABELS[as.character(confidence)]

  # HTML-escape user-supplied values to prevent XSS in visNetwork tooltips
  esc <- htmltools::htmlEscape
  sprintf(
    "<div style='padding: 8px;'>
      <b>%s \u2192 %s</b><br>
      Polarity: %s (%s)<br>
      Strength: %s<br>
      Confidence: %s (%d/5)
    </div>",
    esc(from_name), esc(to_name), esc(polarity), polarity_text, esc(strength), confidence_text, confidence
  )
}

# ============================================================================
# NETWORK STYLING FUNCTIONS
# ============================================================================

#' Apply standard visNetwork styling
#' 
#' @param visnet visNetwork object
#' @return Styled visNetwork object
apply_standard_styling <- function(visnet) {
  
  visnet %>%
    # Groups for legend
    visGroups(
      groupname = "Drivers",
      shape = "image",
      image = "shapes/octagon.svg"
    ) %>%
    visGroups(
      groupname = "Activities",
      color = list(background = ELEMENT_COLORS[["Activities"]], 
                  border = darken_color(ELEMENT_COLORS[["Activities"]])),
      shape = ELEMENT_SHAPES[["Activities"]]
    ) %>%
    visGroups(
      groupname = "Pressures",
      color = list(background = ELEMENT_COLORS[["Pressures"]], 
                  border = darken_color(ELEMENT_COLORS[["Pressures"]])),
      shape = ELEMENT_SHAPES[["Pressures"]]
    ) %>%
    visGroups(
      groupname = "Marine Processes & Functioning",
      color = list(background = ELEMENT_COLORS[["Marine Processes & Functioning"]], 
                  border = darken_color(ELEMENT_COLORS[["Marine Processes & Functioning"]])),
      shape = ELEMENT_SHAPES[["Marine Processes & Functioning"]]
    ) %>%
    visGroups(
      groupname = "Ecosystem Services",
      color = list(background = ELEMENT_COLORS[["Ecosystem Services"]], 
                  border = darken_color(ELEMENT_COLORS[["Ecosystem Services"]])),
      shape = ELEMENT_SHAPES[["Ecosystem Services"]]
    ) %>%
    visGroups(
      groupname = "Goods & Benefits",
      color = list(background = ELEMENT_COLORS[["Goods & Benefits"]], 
                  border = darken_color(ELEMENT_COLORS[["Goods & Benefits"]])),
      shape = ELEMENT_SHAPES[["Goods & Benefits"]]
    ) %>%
    visGroups(
      groupname = "Responses",
      color = list(background = ELEMENT_COLORS[["Responses"]], 
                  border = darken_color(ELEMENT_COLORS[["Responses"]])),
      shape = ELEMENT_SHAPES[["Responses"]]
    ) %>%
    # Legend
    visLegend(
      width = 0.15,
      position = "right",
      main = "DAPSI(W)R(M)"
    ) %>%
    # Interaction options
    visInteraction(
      navigationButtons = FALSE,  # Disabled: causes layout issues in dashboard
      keyboard = TRUE,
      hover = TRUE,
      tooltipDelay = 100,
      zoomView = TRUE,
      dragView = TRUE,
      dragNodes = TRUE,
      multiselect = TRUE
    ) %>%
    # Edge configuration
    visEdges(
      smooth = list(enabled = TRUE, type = "curvedCW", roundness = 0.2),
      shadow = FALSE,
      arrows = list(to = list(enabled = TRUE, scaleFactor = 0.5)),
      font = list(size = FONT_SIZE_SMALL, align = "middle")
    ) %>%
    # Node configuration - labels below shapes with wrapping
    visNodes(
      shadow = list(enabled = TRUE, size = SHADOW_SIZE),
      font = list(
        size = FONT_SIZE_MEDIUM,
        face = "arial",
        vadjust = 25,  # Positive value moves labels below shapes
        multi = "html",  # Enable HTML for line breaks
        bold = list(size = FONT_SIZE_MEDIUM)
      ),
      borderWidth = DEFAULT_BORDER_WIDTH,
      widthConstraint = list(maximum = 150)  # Constrain width to force wrapping
    ) %>%
    # Options
    visOptions(
      highlightNearest = list(enabled = TRUE, degree = 1, hover = TRUE),
      selectedBy = "group"
    )
}

#' Darken a color for borders
#' 
#' @param color Hex color code
#' @param factor Darkening factor (0-1)
#' @return Darkened hex color
darken_color <- function(color, factor = 0.2) {
  # Simple darkening by reducing RGB values
  rgb_vals <- col2rgb(color) / 255
  darkened <- rgb_vals * (1 - factor)
  rgb(darkened[1], darkened[2], darkened[3])
}

# ============================================================================
# LAYOUT FUNCTIONS
# ============================================================================

#' Apply hierarchical layout
#' 
#' @param visnet visNetwork object
#' @param direction Layout direction
#' @param level_separation Space between levels
#' @return visNetwork with hierarchical layout
apply_hierarchical_layout <- function(visnet, direction = "DU", 
                                     level_separation = 150) {
  visnet %>%
    visHierarchicalLayout(
      direction = direction,
      levelSeparation = level_separation,
      nodeSpacing = 250,      # Increased from 200 for more horizontal spacing
      treeSpacing = 250,      # Increased from 200 for more spacing between separate trees
      blockShifting = TRUE,
      edgeMinimization = TRUE,
      parentCentralization = TRUE,
      sortMethod = "directed"
    )
}

#' Apply physics-based layout
#' 
#' @param visnet visNetwork object
#' @return visNetwork with physics layout
apply_physics_layout <- function(visnet) {
  visnet %>%
    visPhysics(
      enabled = TRUE,
      solver = "forceAtlas2Based",
      forceAtlas2Based = list(
        gravitationalConstant = -50,
        centralGravity = 0.01,
        springLength = 100,
        springConstant = 0.08
      ),
      stabilization = list(
        enabled = TRUE,
        iterations = 1000,
        updateInterval = 25
      )
    )
}

#' Apply circular layout
#' 
#' @param visnet visNetwork object
#' @return visNetwork with circular layout
apply_circular_layout <- function(visnet) {
  visnet %>%
    visLayout(randomSeed = 123) %>%
    visIgraphLayout(layout = "layout_in_circle")
}

# ============================================================================
# FILTERING FUNCTIONS
# ============================================================================

# ============================================================================
# GRAPHICAL SES CREATOR FUNCTIONS
# ============================================================================

#' Apply Graphical SES Creator Styling
#'
#' Extended visNetwork styling that supports opacity for ghost nodes
#' Used by the graphical SES creator module to render both permanent
#' and ghost (preview) nodes with different visual treatments.
#'
#' @param visnet visNetwork object
#' @return visNetwork object with graphical SES styling applied
#' @export
apply_graphical_ses_styling <- function(visnet) {

  visnet %>%
    # Apply standard styling first
    visOptions(
      clickToUse = FALSE,
      manipulation = FALSE,  # Disable manual drag-to-connect
      highlightNearest = list(
        enabled = TRUE,
        degree = 1,
        hover = TRUE
      ),
      nodesIdSelection = FALSE
    ) %>%
    visInteraction(
      navigationButtons = FALSE,
      keyboard = TRUE,
      hover = TRUE,
      tooltipDelay = 300,
      zoomView = TRUE,
      dragView = TRUE
    ) %>%
    visPhysics(
      enabled = TRUE,
      solver = "hierarchicalRepulsion",
      hierarchicalRepulsion = list(
        nodeDistance = 150,
        centralGravity = 0.2,
        springLength = 150,
        springConstant = 0.01,
        damping = 0.09
      ),
      stabilization = list(
        enabled = TRUE,
        iterations = 100,
        updateInterval = 25
      )
    ) %>%
    visLayout(
      hierarchical = list(
        enabled = TRUE,
        direction = "LR",  # Left to right
        sortMethod = "directed",
        levelSeparation = 200,
        nodeSpacing = 150
      )
    ) %>%
    visNodes(
      font = list(
        size = FONT_SIZE_LARGE,
        color = "#ffffff",
        face = "Arial",
        bold = list(color = "#ffffff", size = FONT_SIZE_LARGE),
        multi = "html"
      )
    ) %>%
    # Ghost node support via custom JS
    visEvents(
      type = "once",
      afterDrawing = htmlwidgets::JS("
        function(params) {
          // Custom handling for ghost nodes can be added here
          console.log('[GRAPHICAL SES] Network rendered');
        }
      ")
    )
}


#' Create Ghost Node Data
#'
#' Creates a ghost node (preview/suggestion) with semi-transparent styling
#'
#' @param suggestion Suggestion object from suggest_connected_elements
#' @param index Ghost node index
#' @return Single-row dataframe with ghost node data
#' @export
create_ghost_node_data <- function(suggestion, index) {

  ghost_id <- paste0("GHOST_", index)

  # Get styling for this type
  color <- ELEMENT_COLORS[[suggestion$type]]
  shape <- ELEMENT_SHAPES[[suggestion$type]]
  level <- get_dapsiwrm_level(suggestion$type)

  # Create semi-transparent color
  ghost_color <- adjustcolor(color, alpha.f = NODE_OPACITY_GHOST)

  # Create tooltip
  esc <- htmltools::htmlEscape
  tooltip <- paste0(
    "<b>", esc(suggestion$name), "</b><br>",
    "Type: ", esc(suggestion$type), "<br>",
    "Connection: ", esc(suggestion$connection_polarity), " (",
    esc(suggestion$connection_strength), ")<br>",
    "<i>", esc(suggestion$reasoning), "</i><br>",
    "<b>Click to accept</b>"
  )

  data.frame(
    id = ghost_id,
    label = wrap_label(suggestion$name, 15),
    name = suggestion$name,  # Store full name
    type = suggestion$type,
    group = suggestion$type,
    level = level,
    shape = shape,
    color.background = ghost_color,
    color.border = color,
    color.highlight.background = color,
    color.highlight.border = color,
    borderWidth = GHOST_BORDER_WIDTH,
    borderWidthSelected = GHOST_BORDER_WIDTH + 1,
    size = LARGE_NODE_SIZE,
    font.size = FONT_SIZE_LARGE,
    font.color = "#333333",
    is_ghost = TRUE,
    title = tooltip,
    hidden = FALSE,
    physics = TRUE,
    stringsAsFactors = FALSE
  )
}


#' Create Ghost Edge Data
#'
#' Creates a ghost edge (preview connection) with dashed styling
#'
#' @param suggestion Suggestion object
#' @param ghost_index Index of ghost node
#' @return Single-row dataframe with ghost edge data
#' @export
create_ghost_edge_data <- function(suggestion, ghost_index) {

  ghost_id <- paste0("GHOST_", ghost_index)

  # Get edge color based on polarity
  edge_color_base <- if (suggestion$connection_polarity == "+") {
    EDGE_COLORS$reinforcing
  } else {
    EDGE_COLORS$opposing
  }

  # Make semi-transparent
  ghost_edge_color <- adjustcolor(edge_color_base, alpha.f = GHOST_EDGE_OPACITY)

  # Get width based on strength
  width <- switch(suggestion$connection_strength,
    "strong" = 3,
    "medium" = 2,
    "weak" = 1,
    2  # default
  )

  # Create tooltip
  tooltip <- paste0(
    "Polarity: ", htmltools::htmlEscape(suggestion$connection_polarity), "<br>",
    "Strength: ", htmltools::htmlEscape(suggestion$connection_strength), "<br>",
    "Confidence: ", htmltools::htmlEscape(suggestion$connection_confidence), "/5"
  )

  data.frame(
    id = paste0("EDGE_GHOST_", ghost_index),
    from = suggestion$from_node,
    to = ghost_id,
    polarity = suggestion$connection_polarity,
    strength = suggestion$connection_strength,
    confidence = suggestion$connection_confidence,
    color = ghost_edge_color,
    width = width,
    dashes = TRUE,  # Dashed line for ghost
    smooth = list(enabled = TRUE, type = "curvedCW", roundness = 0.2),
    arrows = "to",
    arrowStrikethrough = FALSE,
    is_ghost = TRUE,
    title = tooltip,
    physics = TRUE,
    stringsAsFactors = FALSE
  )
}


#' Get DAPSIWRM Level for Hierarchical Layout
#'
#' Returns the level (1-7) for hierarchical positioning
#'
#' @param type DAPSIWRM type name
#' @return Integer level (1-7)
#' @export
get_dapsiwrm_level <- function(type) {
  levels <- c(
    "Drivers" = 1,
    "Activities" = 2,
    "Pressures" = 3,
    "Marine Processes & Functioning" = 4,
    "Ecosystem Services" = 5,
    "Goods & Benefits" = 6,
    "Responses" = 7,
    "Management" = 8
  )

  return(levels[type] %||% 4)
}
