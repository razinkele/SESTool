# functions/error_handling.R
# Centralized Error Handling and Validation
# Purpose: Provide consistent error handling, validation, and safe fallbacks across the application
#
# STANDARDIZED ERROR HANDLING PATTERN:
# - Use safe_execute() for operations that might fail and need graceful fallbacks
# - Use validate_*() functions for data structure validation
# - Use safe_get_nested() for safely accessing nested list elements
# - All error handling functions use debug_log() for consistent logging (respects DEBUG_MODE)

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
                          "goods_benefits", "responses")

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

  error_msg <- tryCatch({
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

    NULL  # No error
  }, error = function(e) {
    sprintf("CLD validation error: %s", e$message)
  })

  # If there was an error, set the message
  if (!is.null(error_msg)) {
    result$message <- error_msg
  }

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
        debug_log(sprintf("%s: %s", error_msg, e$message), "ERROR")
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
# EVAL SAFETY GUARD
# ============================================================================

#' Validate that an expression is safe to eval
#'
#' INTERNAL ONLY - expressions must never contain user input.
#' Guards against accidental eval of character strings which could enable
#' code injection. Only call, expression, name, and { objects are permitted.
#'
#' @param expr The expression to validate
#' @param context Character. Caller context for logging
#' @return TRUE if safe, stops with error if not
#' @keywords internal
.assert_safe_expr <- function(expr, context = "eval") {

  if (is.character(expr)) {
    stop(sprintf("[%s] Refusing to eval() a character string - potential code injection risk", context))
  }
  if (!is.language(expr) && !is.expression(expr) && !is.function(expr) && !is.null(expr)) {
    stop(sprintf("[%s] eval() received unexpected type '%s' - only language objects are permitted",
                 context, class(expr)[1]))
  }
  invisible(TRUE)
}

# ============================================================================
# USER-FACING ERROR FORMATTING
# ============================================================================

#' Format an error for user display
#'
#' Converts a raw R error into a user-friendly notification message.
#' Technical details are logged server-side only; the user sees a clean message.
#' Use this in tryCatch blocks for showNotification() calls.
#'
#' @param error Error object from tryCatch
#' @param i18n Translation object (optional). If provided, uses i18n$t() for prefix.
#' @param context Character. Human-readable context (e.g., "saving project", "loading data")
#' @param show_details Logical. If TRUE, appends a sanitized version of the R error. Default FALSE.
#' @return Character string suitable for showNotification()
#' @export
format_user_error <- function(error, i18n = NULL, context = NULL, show_details = FALSE) {
  # Log full technical details server-side
  detail <- if (inherits(error, "error")) error$message else as.character(error)
  debug_log(sprintf("User-facing error [%s]: %s", context %||% "unknown", detail), "ERROR")

  # Build user message
  prefix <- if (!is.null(i18n) && is.function(i18n$t)) {
    i18n$t("common.messages.error_occurred")
  } else {
    "An error occurred"
  }

  msg <- if (!is.null(context)) {
    paste0(prefix, " ", context, ".")
  } else {
    paste0(prefix, ".")
  }

  # Optionally append sanitized detail (strip file paths, stack traces)
  if (show_details && nchar(detail) > 0) {
    # Remove file paths and line numbers from error messages
    clean_detail <- gsub("\\s*\\(.*?\\)\\s*$", "", detail)
    clean_detail <- gsub("[A-Z]:/[^ ]+", "[file]", clean_detail)
    clean_detail <- substr(clean_detail, 1, 150)  # Truncate long messages
    msg <- paste0(msg, " ", clean_detail)
  }

  msg
}

# ============================================================================
# ERROR BOUNDARIES FOR SHINY OUTPUTS
# ============================================================================

#' Safe renderUI wrapper with error handling
#'
#' Wraps renderUI to catch errors and display them gracefully
#'
#' @param expr Expression to render
#' @param env Environment for evaluation
#' @param quoted Whether expr is quoted
#' @return A renderUI output with error handling
#' @export
safe_renderUI <- function(expr, env = parent.frame(), quoted = FALSE) {
  # Standard Shiny quoting pattern: capture expression and forward to renderUI
  # which handles its own environment correctly
  installExprFunction <- get("installExprFunction", envir = asNamespace("shiny"), inherits = FALSE)

  func <- NULL
  if (!quoted) {
    expr <- substitute(expr)
  }
  .assert_safe_expr(expr, "safe_renderUI")

  # Wrap the user expression in tryCatch for error boundary
  wrapped_expr <- bquote(
    tryCatch({
      .(expr)
    }, error = function(e) {
      if (exists("debug_log", mode = "function")) {
        debug_log(sprintf("renderUI error: %s", e$message), "ERROR")
      }
      div(class = "alert alert-danger",
          icon("exclamation-triangle"), " ",
          strong("Error: "), e$message)
    })
  )

  renderUI(wrapped_expr, env = env, quoted = TRUE)
}

#' Safe renderDT wrapper with error handling
#'
#' Wraps DT::renderDT to catch errors and return empty table
#'
#' @param expr Expression to render
#' @param ... Additional arguments passed to renderDT
#' @param env Environment for evaluation
#' @param quoted Whether expr is quoted
#' @return A renderDT output with error handling
#' @export
safe_renderDT <- function(expr, ..., env = parent.frame(), quoted = FALSE) {
  if (!quoted) {
    expr <- substitute(expr)
  }
  .assert_safe_expr(expr, "safe_renderDT")

  wrapped_expr <- bquote(
    tryCatch({
      .(expr)
    }, error = function(e) {
      if (exists("debug_log", mode = "function")) debug_log(sprintf("renderDT error: %s", e$message), "ERROR")
      data.frame(Error = e$message)
    })
  )
  DT::renderDT(wrapped_expr, env = env, quoted = TRUE, ...)
}

#' Safe renderPlot wrapper with error handling
#'
#' Wraps renderPlot to catch errors and display them gracefully
#'
#' @param expr Expression to render
#' @param ... Additional arguments passed to renderPlot
#' @param env Environment for evaluation
#' @param quoted Whether expr is quoted
#' @return A renderPlot output with error handling
#' @export
safe_renderPlot <- function(expr, ..., env = parent.frame(), quoted = FALSE) {
  if (!quoted) {
    expr <- substitute(expr)
  }
  .assert_safe_expr(expr, "safe_renderPlot")

  wrapped_expr <- bquote(
    tryCatch({
      .(expr)
    }, error = function(e) {
      if (exists("debug_log", mode = "function")) debug_log(sprintf("renderPlot error: %s", e$message), "ERROR")
      plot.new()
      text(0.5, 0.5, paste("Error:", e$message), col = "red", cex = 1.2)
    })
  )
  renderPlot(wrapped_expr, env = env, quoted = TRUE, ...)
}

#' Safe renderTable wrapper with error handling
#'
#' Wraps renderTable to catch errors and return empty table
#'
#' @param expr Expression to render
#' @param ... Additional arguments passed to renderTable
#' @param env Environment for evaluation
#' @param quoted Whether expr is quoted
#' @return A renderTable output with error handling
#' @export
safe_renderTable <- function(expr, ..., env = parent.frame(), quoted = FALSE) {
  if (!quoted) {
    expr <- substitute(expr)
  }
  .assert_safe_expr(expr, "safe_renderTable")

  wrapped_expr <- bquote(
    tryCatch({
      .(expr)
    }, error = function(e) {
      if (exists("debug_log", mode = "function")) debug_log(sprintf("renderTable error: %s", e$message), "ERROR")
      data.frame(Error = e$message)
    })
  )
  renderTable(wrapped_expr, env = env, quoted = TRUE, ...)
}

#' Safe renderVisNetwork wrapper with error handling
#'
#' Wraps visNetwork::renderVisNetwork to catch errors
#'
#' @param expr Expression to render
#' @param env Environment for evaluation
#' @param quoted Whether expr is quoted
#' @return A renderVisNetwork output with error handling
#' @export
safe_renderVisNetwork <- function(expr, env = parent.frame(), quoted = FALSE) {
  if (!quoted) {
    expr <- substitute(expr)
  }
  .assert_safe_expr(expr, "safe_renderVisNetwork")

  wrapped_expr <- bquote(
    tryCatch({
      .(expr)
    }, error = function(e) {
      if (exists("debug_log", mode = "function")) debug_log(sprintf("renderVisNetwork error: %s", e$message), "ERROR")
      visNetwork::visNetwork(
        nodes = data.frame(id = 1, label = paste("Error:", e$message)),
        edges = data.frame()
      )
    })
  )
  visNetwork::renderVisNetwork(wrapped_expr, env = env, quoted = TRUE)
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
  if (!is.null(error)) {
    debug_log(sprintf("[ERROR] %s: %s", message, error$message), context)
  } else {
    debug_log(sprintf("[ERROR] %s", message), context)
  }
}

#' Log warning with context
#'
#' @param context Context string
#' @param message Warning message
#' @export
log_warning <- function(context, message) {
  debug_log(sprintf("[WARN] %s", message), context)
}

# ============================================================================
# SAFE SOURCE FUNCTIONS
# ============================================================================

#' Safely source an R file with error handling
#'
#' @param file Path to R file to source
#' @param local Logical or environment - same as source()
#' @param required If TRUE, stop on error. If FALSE, return FALSE on error.
#' @param context Context string for logging (default: extracted from file path)
#' @return TRUE if sourced successfully, FALSE if failed and required=FALSE
#' @export
safe_source <- function(file, local = FALSE, required = TRUE, context = NULL) {
  if (is.null(context)) {
    context <- toupper(gsub("[^a-zA-Z0-9]", "_", basename(file)))
  }

  # Check if file exists first

  if (!file.exists(file)) {
    msg <- sprintf("Source file not found: %s", file)
    log_error(context, msg)
    if (required) {
      stop(msg)
    }
    return(FALSE)
  }

  tryCatch({
    source(file, local = local)
    return(TRUE)
  }, error = function(e) {
    msg <- sprintf("Failed to source file: %s", file)
    log_error(context, msg, e)
    if (required) {
      stop(sprintf("%s - %s", msg, e$message))
    }
    return(FALSE)
  })
}

#' Safely source multiple R files with error handling
#'
#' @param files Character vector of file paths
#' @param local Logical or environment - same as source()
#' @param stop_on_first_error If TRUE, stop on first error. If FALSE, continue and return results.
#' @param context Context string for logging
#' @return Named list with success status for each file
#' @export
safe_source_multiple <- function(files, local = FALSE, stop_on_first_error = TRUE, context = "SOURCE") {
  results <- list()

  for (file in files) {
    file_name <- basename(file)
    success <- safe_source(
      file = file,
      local = local,
      required = stop_on_first_error,
      context = context
    )
    results[[file_name]] <- success

    if (!success && stop_on_first_error) {
      break
    }
  }

  return(results)
}

#' Validate module dependencies before loading
#'
#' @param module_file Path to module file
#' @param dependencies Character vector of required function names
#' @return TRUE if all dependencies available, FALSE otherwise
#' @export
validate_module_dependencies <- function(module_file, dependencies = NULL) {
  if (is.null(dependencies)) {
    return(TRUE)
  }

  missing <- c()
  for (dep in dependencies) {
    if (!exists(dep, mode = "function")) {
      missing <- c(missing, dep)
    }
  }

  if (length(missing) > 0) {
    log_warning("MODULE_DEPS", sprintf(
      "Module %s missing dependencies: %s",
      basename(module_file),
      paste(missing, collapse = ", ")
    ))
    return(FALSE)
  }

  return(TRUE)
}
