# functions/cld_validation.R
# Shared CLD (Causal Loop Diagram) validation utilities
# Used across analysis modules to validate CLD data before processing

#' Validate that CLD data exists and has content
#'
#' @param project_data The project data reactive value
#' @return TRUE if CLD data is valid, FALSE otherwise
has_valid_cld <- function(project_data) {
  if (is.null(project_data)) return(FALSE)
  if (is.null(project_data$data)) return(FALSE)
  if (is.null(project_data$data$cld)) return(FALSE)

  nodes <- project_data$data$cld$nodes
  edges <- project_data$data$cld$edges

  has_nodes <- !is.null(nodes) && is.data.frame(nodes) && nrow(nodes) > 0
  has_edges <- !is.null(edges) && is.data.frame(edges) && nrow(edges) > 0

  has_nodes && has_edges
}

#' Validate that ISA data exists and has content
#'
#' @param project_data The project data reactive value
#' @return TRUE if ISA data is valid, FALSE otherwise
has_valid_isa <- function(project_data) {
  if (is.null(project_data)) return(FALSE)
  if (is.null(project_data$data)) return(FALSE)
  if (is.null(project_data$data$isa_data)) return(FALSE)

  isa <- project_data$data$isa_data

  # Check if at least one element type has data
  element_types <- c("drivers", "activities", "pressures",
                     "marine_processes", "ecosystem_services",
                     "goods_benefits", "responses")

  any(sapply(element_types, function(et) {
    !is.null(isa[[et]]) && is.data.frame(isa[[et]]) && nrow(isa[[et]]) > 0
  }))
}

#' Validate CLD nodes dataframe structure
#'
#' @param nodes Nodes dataframe
#' @return List with is_valid (logical) and errors (character vector)
validate_cld_nodes <- function(nodes) {
  errors <- character(0)

  if (is.null(nodes) || !is.data.frame(nodes)) {
    return(list(is_valid = FALSE, errors = "Nodes must be a non-NULL data.frame"))
  }

  if (nrow(nodes) == 0) {
    return(list(is_valid = FALSE, errors = "Nodes dataframe is empty"))
  }

  # Check required columns
  required_cols <- c("id", "label")
  missing_cols <- setdiff(required_cols, names(nodes))
  if (length(missing_cols) > 0) {
    errors <- c(errors, paste("Missing required columns:", paste(missing_cols, collapse = ", ")))
  }

  # Check for duplicate IDs
  if ("id" %in% names(nodes) && any(duplicated(nodes$id))) {
    dup_ids <- nodes$id[duplicated(nodes$id)]
    errors <- c(errors, paste("Duplicate node IDs found:", paste(head(dup_ids, 5), collapse = ", ")))
  }

  list(is_valid = length(errors) == 0, errors = errors)
}

#' Validate CLD edges dataframe structure
#'
#' @param edges Edges dataframe
#' @param valid_node_ids Character vector of valid node IDs (optional)
#' @return List with is_valid (logical) and errors (character vector)
validate_cld_edges <- function(edges, valid_node_ids = NULL) {
  errors <- character(0)

  if (is.null(edges) || !is.data.frame(edges)) {
    return(list(is_valid = FALSE, errors = "Edges must be a non-NULL data.frame"))
  }

  # Empty edges is valid (graph with no connections)
  if (nrow(edges) == 0) {
    return(list(is_valid = TRUE, errors = character(0)))
  }

  # Check required columns
  required_cols <- c("from", "to")
  missing_cols <- setdiff(required_cols, names(edges))
  if (length(missing_cols) > 0) {
    errors <- c(errors, paste("Missing required columns:", paste(missing_cols, collapse = ", ")))
  }

  # Validate edge endpoints reference existing nodes
  if (!is.null(valid_node_ids) && all(c("from", "to") %in% names(edges))) {
    invalid_from <- !edges$from %in% valid_node_ids
    invalid_to <- !edges$to %in% valid_node_ids

    n_invalid <- sum(invalid_from | invalid_to)
    if (n_invalid > 0) {
      errors <- c(errors, sprintf("%d edges reference non-existent nodes", n_invalid))
    }
  }

  list(is_valid = length(errors) == 0, errors = errors)
}

#' Get CLD data from project data with validation
#'
#' @param project_data The project data (already extracted from reactive)
#' @return List with nodes and edges, or NULL if invalid
get_validated_cld <- function(project_data) {
  if (!has_valid_cld(project_data)) return(NULL)

  list(
    nodes = project_data$data$cld$nodes,
    edges = project_data$data$cld$edges
  )
}

#' Count elements by DAPSI(W)R(M) type
#'
#' @param nodes Nodes dataframe with group column
#' @return Named integer vector of counts per group
count_elements_by_type <- function(nodes) {
  if (is.null(nodes) || !is.data.frame(nodes) || !"group" %in% names(nodes)) {
    return(integer(0))
  }
  table(nodes$group)
}
