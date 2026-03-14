# functions/data_accessors.R
# ============================================================================
# Data Accessor Functions for MarineSABRES SES Toolbox
#
# Purpose: Simplify access to deeply nested reactive data structures.
# The project_data() structure has 6+ levels of nesting which makes code
# verbose and error-prone. These accessors provide a cleaner API.
#
# Structure being simplified:
#   project_data()$data$isa_data$adjacency_matrices$a_p
#   project_data()$data$cld$nodes
#   project_data()$metadata$project_name
# ============================================================================

# ============================================================================
# ISA DATA ACCESSORS
# ============================================================================

#' Get ISA data from project_data
#'
#' @param project_data Reactive value or list containing project data
#' @param isolate_reactive If TRUE and project_data is reactive, use isolate()
#' @return ISA data list or NULL if not found
#' @export
get_isa_data <- function(project_data, isolate_reactive = FALSE) {
  data <- if (is.function(project_data)) {
    if (isolate_reactive) shiny::isolate(project_data()) else project_data()
  } else {
    project_data
  }

  safe_get_nested(data, "data", "isa_data", default = NULL)
}

#' Get elements of a specific DAPSIWRM type
#'
#' @param project_data Reactive value or list containing project data
#' @param element_type One of: "drivers", "activities", "pressures",
#'   "marine_processes", "ecosystem_services", "goods_benefits", "responses"
#' @param isolate_reactive If TRUE and project_data is reactive, use isolate()
#' @return Data frame of elements or empty data frame if not found
#' @export
get_isa_elements <- function(project_data, element_type, isolate_reactive = FALSE) {
  isa_data <- get_isa_data(project_data, isolate_reactive)

  if (is.null(isa_data)) {
    return(data.frame())
  }

  result <- isa_data[[element_type]]

  if (is.null(result) || !is.data.frame(result)) {
    return(data.frame())
  }

  result
}

#' Get all ISA elements combined into single data frame
#'
#' @param project_data Reactive value or list containing project data
#' @param isolate_reactive If TRUE and project_data is reactive, use isolate()
#' @return Combined data frame with 'type' column indicating element category
#' @export
get_all_isa_elements <- function(project_data, isolate_reactive = FALSE) {
  isa_data <- get_isa_data(project_data, isolate_reactive)

  if (is.null(isa_data)) {
    return(data.frame())
  }

  element_types <- c("drivers", "activities", "pressures", "marine_processes",
                     "ecosystem_services", "goods_benefits", "responses")

  combined <- lapply(element_types, function(type) {
    df <- isa_data[[type]]
    if (!is.null(df) && is.data.frame(df) && nrow(df) > 0) {
      df$element_type <- type
      df
    } else {
      NULL
    }
  })

  combined <- combined[!sapply(combined, is.null)]

  if (length(combined) == 0) {
    return(data.frame())
  }

  # Use dplyr::bind_rows if available, otherwise rbind with care
  if (requireNamespace("dplyr", quietly = TRUE)) {
    dplyr::bind_rows(combined)
  } else {
    do.call(rbind, combined)
  }
}

#' Get element by ID
#'
#' @param project_data Reactive value or list containing project data
#' @param element_id ID of the element to find
#' @param isolate_reactive If TRUE and project_data is reactive, use isolate()
#' @return Single-row data frame or NULL if not found
#' @export
get_element_by_id <- function(project_data, element_id, isolate_reactive = FALSE) {
  all_elements <- get_all_isa_elements(project_data, isolate_reactive)

  if (nrow(all_elements) == 0 || !"id" %in% names(all_elements)) {
    return(NULL)
  }

  match_idx <- which(all_elements$id == element_id)

  if (length(match_idx) == 0) {
    return(NULL)
  }

  all_elements[match_idx[1], , drop = FALSE]
}

#' Get element type for a given element ID
#'
#' @param project_data Reactive value or list containing project data
#' @param element_id ID of the element
#' @param isolate_reactive If TRUE and project_data is reactive, use isolate()
#' @return Element type string or NULL if not found
#' @export
get_element_type_by_id <- function(project_data, element_id, isolate_reactive = FALSE) {
  element <- get_element_by_id(project_data, element_id, isolate_reactive)

  if (is.null(element)) {
    return(NULL)
  }

  element$element_type
}

# ============================================================================
# ADJACENCY MATRIX ACCESSORS
# ============================================================================

#' Get adjacency matrix by name
#'
#' @param project_data Reactive value or list containing project data
#' @param matrix_name Name of the matrix (e.g., "d_a", "a_p", "p_mp")
#' @param isolate_reactive If TRUE and project_data is reactive, use isolate()
#' @return Matrix or NULL if not found
#' @export
get_adjacency_matrix <- function(project_data, matrix_name, isolate_reactive = FALSE) {
  isa_data <- get_isa_data(project_data, isolate_reactive)

  if (is.null(isa_data)) {
    return(NULL)
  }

  safe_get_nested(isa_data, "adjacency_matrices", matrix_name, default = NULL)
}

#' Get all adjacency matrices
#'
#' @param project_data Reactive value or list containing project data
#' @param isolate_reactive If TRUE and project_data is reactive, use isolate()
#' @return List of matrices or empty list
#' @export
get_all_adjacency_matrices <- function(project_data, isolate_reactive = FALSE) {
  isa_data <- get_isa_data(project_data, isolate_reactive)

  if (is.null(isa_data)) {
    return(list())
  }

  safe_get_nested(isa_data, "adjacency_matrices", default = list())
}

#' Set adjacency matrix value
#'
#' @param project_data Reactive value (must be a function)
#' @param matrix_name Name of the matrix
#' @param matrix New matrix value
#' @param event_bus Optional event bus to emit change notification
#' @return TRUE on success, FALSE on failure
#' @export
set_adjacency_matrix <- function(project_data, matrix_name, matrix, event_bus = NULL) {
  if (!is.function(project_data)) {
    warning("set_adjacency_matrix requires a reactive value function")
    return(FALSE)
  }

  tryCatch({
    current <- project_data()
    current$data$isa_data$adjacency_matrices[[matrix_name]] <- matrix
    current$last_modified <- Sys.time()
    project_data(current)

    if (!is.null(event_bus) && is.function(event_bus$emit_isa_change)) {
      event_bus$emit_isa_change()
    }

    TRUE
  }, error = function(e) {
    debug_log(paste("Failed to set adjacency matrix:", e$message), "DATA_ACCESSOR")
    FALSE
  })
}

# ============================================================================
# CLD DATA ACCESSORS
# ============================================================================

#' Get CLD data from project_data
#'
#' @param project_data Reactive value or list containing project data
#' @param isolate_reactive If TRUE and project_data is reactive, use isolate()
#' @return CLD data list or NULL if not found
#' @export
get_cld_data <- function(project_data, isolate_reactive = FALSE) {
  data <- if (is.function(project_data)) {
    if (isolate_reactive) shiny::isolate(project_data()) else project_data()
  } else {
    project_data
  }

  safe_get_nested(data, "data", "cld", default = NULL)
}

#' Get CLD nodes
#'
#' @param project_data Reactive value or list containing project data
#' @param isolate_reactive If TRUE and project_data is reactive, use isolate()
#' @return Nodes data frame or empty data frame
#' @export
get_cld_nodes <- function(project_data, isolate_reactive = FALSE) {
  cld <- get_cld_data(project_data, isolate_reactive)

  if (is.null(cld)) {
    return(data.frame())
  }

  nodes <- cld$nodes

  if (is.null(nodes) || !is.data.frame(nodes)) {
    return(data.frame())
  }

  nodes
}

#' Get CLD edges
#'
#' @param project_data Reactive value or list containing project data
#' @param isolate_reactive If TRUE and project_data is reactive, use isolate()
#' @return Edges data frame or empty data frame
#' @export
get_cld_edges <- function(project_data, isolate_reactive = FALSE) {
  cld <- get_cld_data(project_data, isolate_reactive)

  if (is.null(cld)) {
    return(data.frame())
  }

  edges <- cld$edges

  if (is.null(edges) || !is.data.frame(edges)) {
    return(data.frame())
  }

  edges
}

#' Check if CLD has valid data for analysis
#'
#' @param project_data Reactive value or list containing project data
#' @param min_nodes Minimum number of nodes required (default: 1)
#' @param require_edges If TRUE, also require at least one edge (default: FALSE)
#' @param isolate_reactive If TRUE and project_data is reactive, use isolate()
#' @return TRUE if CLD is valid for analysis
#' @export
has_valid_cld_data <- function(project_data, min_nodes = 1, require_edges = FALSE,
                                isolate_reactive = FALSE) {
  nodes <- get_cld_nodes(project_data, isolate_reactive)

  if (nrow(nodes) < min_nodes) {
    return(FALSE)
  }

  if (require_edges) {
    edges <- get_cld_edges(project_data, isolate_reactive)
    if (nrow(edges) == 0) {
      return(FALSE)
    }
  }

  TRUE
}

# ============================================================================
# METADATA ACCESSORS
# ============================================================================

#' Get project metadata
#'
#' @param project_data Reactive value or list containing project data
#' @param isolate_reactive If TRUE and project_data is reactive, use isolate()
#' @return Metadata list or empty list
#' @export
get_project_metadata <- function(project_data, isolate_reactive = FALSE) {
  data <- if (is.function(project_data)) {
    if (isolate_reactive) shiny::isolate(project_data()) else project_data()
  } else {
    project_data
  }

  safe_get_nested(data, "metadata", default = list())
}

#' Get project name
#'
#' @param project_data Reactive value or list containing project data
#' @param isolate_reactive If TRUE and project_data is reactive, use isolate()
#' @return Project name string or "Untitled Project"
#' @export
get_project_name <- function(project_data, isolate_reactive = FALSE) {
  metadata <- get_project_metadata(project_data, isolate_reactive)

  name <- metadata$project_name %||% metadata$name

  if (is.null(name) || nchar(trimws(name)) == 0) {
    return("Untitled Project")
  }

  name
}

#' Get last modified timestamp
#'
#' @param project_data Reactive value or list containing project data
#' @param isolate_reactive If TRUE and project_data is reactive, use isolate()
#' @return POSIXct timestamp or NULL
#' @export
get_last_modified <- function(project_data, isolate_reactive = FALSE) {
  data <- if (is.function(project_data)) {
    if (isolate_reactive) shiny::isolate(project_data()) else project_data()
  } else {
    project_data
  }

  data$last_modified
}

# ============================================================================
# ANALYSIS DATA ACCESSORS
# ============================================================================

#' Get analysis results
#'
#' @param project_data Reactive value or list containing project data
#' @param analysis_type Type of analysis (e.g., "loops", "metrics", "dynamics")
#' @param isolate_reactive If TRUE and project_data is reactive, use isolate()
#' @return Analysis results or NULL
#' @export
get_analysis_results <- function(project_data, analysis_type = NULL, isolate_reactive = FALSE) {
  data <- if (is.function(project_data)) {
    if (isolate_reactive) shiny::isolate(project_data()) else project_data()
  } else {
    project_data
  }

  analysis <- safe_get_nested(data, "data", "analysis", default = NULL)

  if (is.null(analysis)) {
    return(NULL)
  }

  if (!is.null(analysis_type)) {
    return(analysis[[analysis_type]])
  }

  analysis
}

#' Check if specific analysis has been run
#'
#' @param project_data Reactive value or list containing project data
#' @param analysis_type Type of analysis to check
#' @param isolate_reactive If TRUE and project_data is reactive, use isolate()
#' @return TRUE if analysis exists
#' @export
has_analysis <- function(project_data, analysis_type, isolate_reactive = FALSE) {
  results <- get_analysis_results(project_data, analysis_type, isolate_reactive)
  !is.null(results)
}

# ============================================================================
# MUTATION HELPERS (Use with transaction wrapper for safety)
# ============================================================================

#' Add ISA element to project data
#'
#' @param project_data Reactive value (must be a function)
#' @param element_type Type of element to add
#' @param element Data frame row or list to add
#' @param event_bus Optional event bus to emit change notification
#' @return TRUE on success, FALSE on failure
#' @export
add_isa_element <- function(project_data, element_type, element, event_bus = NULL) {
  if (!is.function(project_data)) {
    warning("add_isa_element requires a reactive value function")
    return(FALSE)
  }

  # Convert element to single-row data frame if needed
  if (is.list(element) && !is.data.frame(element)) {
    element <- as.data.frame(element)
  }

  tryCatch({
    current <- project_data()

    # Initialize if needed
    if (is.null(current$data$isa_data[[element_type]])) {
      current$data$isa_data[[element_type]] <- element
    } else {
      current$data$isa_data[[element_type]] <- dplyr::bind_rows(
        current$data$isa_data[[element_type]],
        element
      )
    }

    current$last_modified <- Sys.time()
    project_data(current)

    if (!is.null(event_bus) && is.function(event_bus$emit_isa_change)) {
      event_bus$emit_isa_change()
    }

    TRUE
  }, error = function(e) {
    debug_log(paste("Failed to add ISA element:", e$message), "DATA_ACCESSOR")
    FALSE
  })
}

#' Update ISA element by ID
#'
#' @param project_data Reactive value (must be a function)
#' @param element_type Type of element to update
#' @param element_id ID of element to update
#' @param updates Named list of field updates
#' @param event_bus Optional event bus to emit change notification
#' @return TRUE on success, FALSE on failure
#' @export
update_isa_element <- function(project_data, element_type, element_id, updates, event_bus = NULL) {
  if (!is.function(project_data)) {
    warning("update_isa_element requires a reactive value function")
    return(FALSE)
  }

  tryCatch({
    current <- project_data()

    elements <- current$data$isa_data[[element_type]]

    if (is.null(elements) || !is.data.frame(elements)) {
      warning(paste("Element type not found:", element_type))
      return(FALSE)
    }

    idx <- which(elements$id == element_id)

    if (length(idx) == 0) {
      warning(paste("Element not found:", element_id))
      return(FALSE)
    }

    # Apply updates
    for (field in names(updates)) {
      if (field %in% names(elements)) {
        elements[idx, field] <- updates[[field]]
      }
    }

    current$data$isa_data[[element_type]] <- elements
    current$last_modified <- Sys.time()
    project_data(current)

    if (!is.null(event_bus) && is.function(event_bus$emit_isa_change)) {
      event_bus$emit_isa_change()
    }

    TRUE
  }, error = function(e) {
    debug_log(paste("Failed to update ISA element:", e$message), "DATA_ACCESSOR")
    FALSE
  })
}

#' Delete ISA element by ID
#'
#' @param project_data Reactive value (must be a function)
#' @param element_type Type of element to delete
#' @param element_id ID of element to delete
#' @param event_bus Optional event bus to emit change notification
#' @return TRUE on success, FALSE on failure
#' @export
delete_isa_element <- function(project_data, element_type, element_id, event_bus = NULL) {
  if (!is.function(project_data)) {
    warning("delete_isa_element requires a reactive value function")
    return(FALSE)
  }

  tryCatch({
    current <- project_data()

    elements <- current$data$isa_data[[element_type]]

    if (is.null(elements) || !is.data.frame(elements)) {
      warning(paste("Element type not found:", element_type))
      return(FALSE)
    }

    idx <- which(elements$id == element_id)

    if (length(idx) == 0) {
      warning(paste("Element not found:", element_id))
      return(FALSE)
    }

    # Remove element
    current$data$isa_data[[element_type]] <- elements[-idx, , drop = FALSE]
    current$last_modified <- Sys.time()
    project_data(current)

    if (!is.null(event_bus) && is.function(event_bus$emit_isa_change)) {
      event_bus$emit_isa_change()
    }

    TRUE
  }, error = function(e) {
    debug_log(paste("Failed to delete ISA element:", e$message), "DATA_ACCESSOR")
    FALSE
  })
}

# ============================================================================
# CONVENIENCE FUNCTIONS
# ============================================================================
#' Get count of elements by type
#'
#' @param project_data Reactive value or list containing project data
#' @param isolate_reactive If TRUE and project_data is reactive, use isolate()
#' @return Named vector of counts by element type
#' @export
get_element_counts <- function(project_data, isolate_reactive = FALSE) {
  element_types <- c("drivers", "activities", "pressures", "marine_processes",
                     "ecosystem_services", "goods_benefits", "responses")

  counts <- sapply(element_types, function(type) {
    elements <- get_isa_elements(project_data, type, isolate_reactive)
    nrow(elements)
  })

  names(counts) <- element_types
  counts
}

#' Get total number of connections in all adjacency matrices
#'
#' @param project_data Reactive value or list containing project data
#' @param isolate_reactive If TRUE and project_data is reactive, use isolate()
#' @return Total connection count
#' @export
get_connection_count <- function(project_data, isolate_reactive = FALSE) {
  matrices <- get_all_adjacency_matrices(project_data, isolate_reactive)

  if (length(matrices) == 0) {
    return(0)
  }

  total <- 0
  for (mat in matrices) {
    if (!is.null(mat) && is.matrix(mat)) {
      total <- total + sum(mat != 0, na.rm = TRUE)
    }
  }

  total
}

#' Get project summary statistics
#'
#' @param project_data Reactive value or list containing project data
#' @param isolate_reactive If TRUE and project_data is reactive, use isolate()
#' @return List with summary statistics
#' @export
get_project_summary <- function(project_data, isolate_reactive = FALSE) {
  element_counts <- get_element_counts(project_data, isolate_reactive)

  list(
    project_name = get_project_name(project_data, isolate_reactive),
    total_elements = sum(element_counts),
    element_counts = element_counts,
    total_connections = get_connection_count(project_data, isolate_reactive),
    cld_nodes = nrow(get_cld_nodes(project_data, isolate_reactive)),
    cld_edges = nrow(get_cld_edges(project_data, isolate_reactive)),
    has_loops_analysis = has_analysis(project_data, "loops", isolate_reactive),
    has_metrics_analysis = has_analysis(project_data, "metrics", isolate_reactive),
    last_modified = get_last_modified(project_data, isolate_reactive)
  )
}
