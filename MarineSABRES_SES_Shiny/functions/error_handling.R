# functions/error_handling.R
# Centralized Error Handling and Validation
# Purpose: Provide consistent error handling, validation, and safe fallbacks across the application

# ============================================================================
# VALIDATION GUARDS
# ============================================================================

#' Validate CLD data structure
#'
#' @param cld CLD data list with nodes and edges
#' @return TRUE if valid, throws error if invalid
#' @export
validate_cld_data <- function(cld) {
  if (is.null(cld)) {
    stop("CLD data is NULL")
  }

  if (!is.list(cld)) {
    stop("CLD data must be a list")
  }

  # Check for required components
  if (is.null(cld$nodes)) {
    stop("CLD data missing 'nodes' component")
  }

  if (is.null(cld$edges)) {
    stop("CLD data missing 'edges' component")
  }

  # Validate nodes dataframe
  if (!is.data.frame(cld$nodes)) {
    stop("CLD nodes must be a dataframe")
  }

  if (nrow(cld$nodes) == 0) {
    stop("CLD has no nodes")
  }

  # Validate edges dataframe
  if (!is.data.frame(cld$edges)) {
    stop("CLD edges must be a dataframe")
  }

  # Check required columns in nodes
  required_node_cols <- c("id", "label")
  missing_cols <- setdiff(required_node_cols, names(cld$nodes))
  if (length(missing_cols) > 0) {
    stop(sprintf("CLD nodes missing required columns: %s",
                 paste(missing_cols, collapse = ", ")))
  }

  # Check required columns in edges (if edges exist)
  if (nrow(cld$edges) > 0) {
    required_edge_cols <- c("from", "to")
    missing_cols <- setdiff(required_edge_cols, names(cld$edges))
    if (length(missing_cols) > 0) {
      stop(sprintf("CLD edges missing required columns: %s",
                   paste(missing_cols, collapse = ", ")))
    }
  }

  return(TRUE)
}

#' Validate ISA data structure
#'
#' @param isa_data ISA data list
#' @return TRUE if valid, throws error if invalid
#' @export
validate_isa_data <- function(isa_data) {
  if (is.null(isa_data)) {
    stop("ISA data is NULL")
  }

  if (!is.list(isa_data)) {
    stop("ISA data must be a list")
  }

  # Check for DAPSIWRM components
  required_components <- c("drivers", "activities", "pressures",
                          "marine_processes", "ecosystem_services",
                          "goods_benefits", "responses", "measures")

  missing_components <- setdiff(required_components, names(isa_data))
  if (length(missing_components) > 0) {
    stop(sprintf("ISA data missing components: %s",
                 paste(missing_components, collapse = ", ")))
  }

  # Check that all components are dataframes
  for (comp in required_components) {
    if (!is.null(isa_data[[comp]]) && !is.data.frame(isa_data[[comp]])) {
      stop(sprintf("ISA component '%s' must be a dataframe", comp))
    }
  }

  return(TRUE)
}

#' Check if CLD has sufficient data for analysis
#'
#' @param cld CLD data list
#' @return List with has_data, has_edges, n_nodes, n_edges, message
#' @export
check_cld_readiness <- function(cld) {
  result <- list(
    has_data = FALSE,
    has_edges = FALSE,
    n_nodes = 0,
    n_edges = 0,
    message = NULL
  )

  tryCatch({
    validate_cld_data(cld)

    result$n_nodes <- nrow(cld$nodes)
    result$n_edges <- nrow(cld$edges)
    result$has_data <- result$n_nodes > 0
    result$has_edges <- result$n_edges > 0

    if (!result$has_data) {
      result$message <- "No nodes in CLD. Please create or import SES data first."
    } else if (!result$has_edges) {
      result$message <- "CLD has nodes but no connections. Add connections to enable analysis."
    } else {
      result$message <- sprintf("CLD ready: %d nodes, %d edges",
                               result$n_nodes, result$n_edges)
    }

  }, error = function(e) {
    result$message <- sprintf("CLD validation error: %s", e$message)
  })

  return(result)
}

# ============================================================================
# SAFE WRAPPERS
# ============================================================================

#' Safely execute a function with error handling
#'
#' @param expr Expression to execute
#' @param default Default value to return on error
#' @param error_msg Custom error message prefix
#' @param silent If TRUE, suppress error messages
#' @return Result of expr or default on error
#' @export
safe_execute <- function(expr, default = NULL, error_msg = "Operation failed", silent = FALSE) {
  tryCatch(
    expr,
    error = function(e) {
      if (!silent) {
        warning(sprintf("%s: %s", error_msg, e$message))
        cat(sprintf("[ERROR] %s: %s\n", error_msg, e$message))
      }
      return(default)
    }
  )
}

#' Safely get nested list element
#'
#' @param data List or nested list
#' @param ... Names of nested elements
#' @param default Default value if element not found
#' @return Element value or default
#' @export
safe_get_nested <- function(data, ..., default = NULL) {
  path <- list(...)
  current <- data

  for (key in path) {
    if (is.null(current) || !is.list(current) || !key %in% names(current)) {
      return(default)
    }
    current <- current[[key]]
  }

  if (is.null(current)) {
    return(default)
  }

  return(current)
}

#' Safely create igraph from dataframes
#'
#' @param nodes Nodes dataframe
#' @param edges Edges dataframe
#' @return igraph object or NULL on error
#' @export
safe_create_igraph <- function(nodes, edges) {
  safe_execute({
    # Validate inputs
    if (is.null(nodes) || !is.data.frame(nodes) || nrow(nodes) == 0) {
      stop("Invalid or empty nodes dataframe")
    }

    if (is.null(edges) || !is.data.frame(edges)) {
      stop("Invalid edges dataframe")
    }

    # Handle empty edges case
    if (nrow(edges) == 0) {
      # Create graph with nodes only, no edges
      g <- igraph::graph_from_data_frame(
        d = data.frame(from = character(0), to = character(0)),
        vertices = nodes,
        directed = TRUE
      )
      return(g)
    }

    # Check required columns
    if (!all(c("from", "to") %in% names(edges))) {
      stop("Edges dataframe missing 'from' or 'to' columns")
    }

    if (!"id" %in% names(nodes)) {
      stop("Nodes dataframe missing 'id' column")
    }

    # Create graph
    g <- igraph::graph_from_data_frame(
      d = edges,
      vertices = nodes,
      directed = TRUE
    )

    return(g)

  }, default = NULL, error_msg = "Failed to create igraph")
}

# ============================================================================
# ERROR BOUNDARIES FOR SHINY OUTPUTS
# ============================================================================

#' Create safe render function wrapper
#'
#' @param render_func Render function to wrap
#' @param error_ui UI to display on error
#' @return Wrapped render function
#' @export
safe_render <- function(render_func, error_ui = NULL) {
  if (is.null(error_ui)) {
    error_ui <- function(e) {
      div(class = "alert alert-danger",
          icon("exclamation-triangle"), " ",
          strong("Error: "), e$message)
    }
  }

  function(...) {
    tryCatch(
      render_func(...),
      error = function(e) {
        cat(sprintf("[RENDER ERROR] %s\n", e$message))
        error_ui(e)
      }
    )
  }
}

# ============================================================================
# DATA VALIDATION HELPERS
# ============================================================================

#' Validate and coerce to numeric
#'
#' @param x Value to validate
#' @param default Default value if invalid
#' @return Numeric value or default
#' @export
safe_numeric <- function(x, default = 0) {
  if (is.null(x) || is.na(x) || !is.finite(as.numeric(x))) {
    return(default)
  }
  return(as.numeric(x))
}

#' Validate and coerce to character
#'
#' @param x Value to validate
#' @param default Default value if invalid
#' @return Character value or default
#' @export
safe_character <- function(x, default = "") {
  if (is.null(x) || is.na(x)) {
    return(default)
  }
  return(as.character(x))
}

#' Check if dataframe has data
#'
#' @param df Dataframe to check
#' @return TRUE if df is valid dataframe with rows
#' @export
has_data <- function(df) {
  !is.null(df) && is.data.frame(df) && nrow(df) > 0
}

# ============================================================================
# LOGGING HELPERS
# ============================================================================

#' Log error with context
#'
#' @param context Context string (e.g., "NETWORK_ANALYSIS")
#' @param message Error message
#' @param error Error object (optional)
#' @export
log_error <- function(context, message, error = NULL) {
  timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  if (!is.null(error)) {
    cat(sprintf("[%s] [ERROR] [%s] %s: %s\n",
                timestamp, context, message, error$message))
  } else {
    cat(sprintf("[%s] [ERROR] [%s] %s\n",
                timestamp, context, message))
  }
}

#' Log warning with context
#'
#' @param context Context string
#' @param message Warning message
#' @export
log_warning <- function(context, message) {
  timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  cat(sprintf("[%s] [WARN] [%s] %s\n",
              timestamp, context, message))
}
