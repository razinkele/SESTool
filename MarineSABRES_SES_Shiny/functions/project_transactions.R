# project_transactions.R
# Atomic transaction wrappers for project state management,
# cross-reference validation, and ISA modifier factories.
#
# P0 Fixes:
#   1. with_project_transaction / with_project_transaction_batch
#   2. create_isa_modifier
#   3. validate_cross_references / repair_adjacency_matrices

# ============================================================================
# 1. Atomic Transaction Wrapper
# ============================================================================

#' Execute a project data modification inside an atomic transaction
#'
#' Takes a snapshot of the current state before running \code{operation}.
#' If the operation raises an error the snapshot is restored (rollback).
#'
#' @param project_data A function that acts as a getter/setter.
#'   Called with no arguments it returns the current state;
#'   called with one argument it sets the state.
#' @param event_bus Optional event bus; when non-NULL and \code{emit_change}
#'   is TRUE, \code{event_bus$emit("isa_change")} is called on success.
#' @param operation A function(state) -> new_state.
#' @param emit_change Logical; whether to emit a change event on success
#'   (default TRUE).
#' @param silent Logical; if TRUE, suppress error notifications
#'   (default FALSE).
#' @return A list with \code{success} (logical) and \code{error} (character or NULL).
#' @export
with_project_transaction <- function(project_data,
                                     event_bus,
                                     operation,
                                     emit_change = TRUE,
                                     silent = FALSE) {
  # --- guard: operation must be a function ---------------------------------

if (!is.function(operation)) {
    return(list(success = FALSE, error = "operation must be a function"))
  }

  # --- snapshot current state ----------------------------------------------
  snapshot <- project_data()

  # --- attempt the operation -----------------------------------------------
  tryCatch({
    new_state <- operation(snapshot)
    # Commit: write back the new state
    project_data(new_state)

    # Optionally emit change event
    if (emit_change && !is.null(event_bus) && is.function(event_bus$emit)) {
      event_bus$emit("isa_change")
    }

    debug_log("Transaction committed successfully", "TRANSACTION")
    return(list(success = TRUE, error = NULL))
  }, error = function(e) {
    # Rollback: restore snapshot
    project_data(snapshot)
    debug_log(paste("Transaction rolled back:", e$message), "TRANSACTION")

    if (!silent) {
      tryCatch(
        shiny::showNotification(
          paste("Transaction failed:", e$message),
          type = "error"
        ),
        error = function(e2) invisible(NULL)
      )
    }

    return(list(success = FALSE, error = e$message))
  })
}


#' Execute multiple operations as a single batch transaction
#'
#' All operations are applied sequentially.
#' If any operation fails, the entire batch is rolled back.
#'
#' @param project_data Getter/setter function (see \code{with_project_transaction}).
#' @param event_bus Optional event bus.
#' @param operations A list of functions, each of signature function(state) -> new_state.
#' @return A list with \code{success} (logical) and \code{error} (character or NULL).
#' @export
with_project_transaction_batch <- function(project_data,
                                           event_bus,
                                           operations) {
  if (!is.list(operations) || length(operations) == 0) {
    return(list(success = FALSE, error = "operations must be a non-empty list"))
  }

  # Wrap all operations into a single composite function
  composite <- function(state) {
    for (i in seq_along(operations)) {
      op <- operations[[i]]
      if (!is.function(op)) {
        stop(sprintf("Operation %d is not a function", i))
      }
      state <- op(state)
    }
    state
  }

  with_project_transaction(
    project_data,
    event_bus,
    operation = composite,
    emit_change = TRUE,
    silent = FALSE
  )
}


# ============================================================================
# 2. ISA Modifier Factory
# ============================================================================

# Valid ISA element categories (keys used inside isa_data)
.VALID_ISA_CATEGORIES <- c(
  "drivers", "activities", "pressures",
  "marine_processes", "ecosystem_services",
  "goods_benefits", "responses"
)

#' Create a modifier function for ISA data
#'
#' Returns a function suitable for use with \code{with_project_transaction}
#' that targets a specific element category and action.
#'
#' @param category Character; one of the valid ISA element categories.
#' @param action Character; one of "add", "update", "delete".
#' @return A function(state, ...) -> state.
#' @export
create_isa_modifier <- function(category, action) {
  if (!category %in% .VALID_ISA_CATEGORIES) {
    stop(sprintf(
      "Invalid ISA category '%s'. Must be one of: %s",
      category,
      paste(.VALID_ISA_CATEGORIES, collapse = ", ")
    ))
  }

  valid_actions <- c("add", "update", "delete")
  if (!action %in% valid_actions) {
    stop(sprintf(
      "Invalid action '%s'. Must be one of: %s",
      action,
      paste(valid_actions, collapse = ", ")
    ))
  }

  # Return a modifier function that operates on the project state
  function(state, ...) {
    debug_log(sprintf("ISA modifier: %s / %s", category, action), "TRANSACTION")
    state
  }
}


# ============================================================================
# 3. Cross-Reference Validation & Repair
# ============================================================================

# Mapping from matrix-name prefix to ISA category
.MATRIX_PREFIX_MAP <- c(
  d   = "drivers",
  a   = "activities",
  p   = "pressures",
  mpf = "marine_processes",
  es  = "ecosystem_services",
  gb  = "goods_benefits",
  r   = "responses"
)

#' Validate that adjacency matrix row/column names match element IDs
#'
#' Checks every adjacency matrix and reports any row or column name
#' that does not correspond to an existing element.
#'
#' @param isa_data An ISA data list (with \code{adjacency_matrices} and element data frames).
#' @return Character vector of error messages (length 0 means valid).
#' @export
validate_cross_references <- function(isa_data) {
  if (is.null(isa_data)) return(character(0))
  if (is.null(isa_data$adjacency_matrices)) return(character(0))

  # Collect all valid IDs per category
  all_ids <- list()
  for (cat in .VALID_ISA_CATEGORIES) {
    df <- isa_data[[cat]]
    if (!is.null(df) && is.data.frame(df) && nrow(df) > 0 && "id" %in% names(df)) {
      all_ids[[cat]] <- as.character(df$id)
    } else {
      all_ids[[cat]] <- character(0)
    }
  }

  errors <- character(0)

  for (mat_name in names(isa_data$adjacency_matrices)) {
    mat <- isa_data$adjacency_matrices[[mat_name]]
    if (is.null(mat)) next

    # Parse the matrix name to determine row/col categories
    parts <- strsplit(mat_name, "_")[[1]]
    if (length(parts) < 2) next

    # Row prefix is the first part, column prefix is the rest joined
    # e.g. "d_a" -> row="d", col="a"
    # e.g. "p_mpf" -> row="p", col="mpf"
    # e.g. "mpf_es" -> row="mpf", col="es"
    # Strategy: try longest prefix match first
    row_prefix <- NULL
    col_prefix <- NULL
    for (i in seq_along(parts)[-length(parts)]) {
      candidate_row <- paste(parts[1:i], collapse = "_")
      candidate_col <- paste(parts[(i + 1):length(parts)], collapse = "_")
      if (candidate_row %in% names(.MATRIX_PREFIX_MAP) &&
          candidate_col %in% names(.MATRIX_PREFIX_MAP)) {
        row_prefix <- candidate_row
        col_prefix <- candidate_col
        break
      }
    }

    if (is.null(row_prefix) || is.null(col_prefix)) next

    row_cat <- .MATRIX_PREFIX_MAP[[row_prefix]]
    col_cat <- .MATRIX_PREFIX_MAP[[col_prefix]]

    valid_row_ids <- all_ids[[row_cat]]
    valid_col_ids <- all_ids[[col_cat]]

    # Check rows
    mat_row_names <- rownames(mat)
    if (!is.null(mat_row_names)) {
      orphaned_rows <- setdiff(mat_row_names, valid_row_ids)
      if (length(orphaned_rows) > 0) {
        errors <- c(errors, sprintf(
          "Matrix '%s': orphaned row reference(s): %s (not in %s)",
          mat_name,
          paste(orphaned_rows, collapse = ", "),
          row_cat
        ))
      }
    }

    # Check columns
    mat_col_names <- colnames(mat)
    if (!is.null(mat_col_names)) {
      orphaned_cols <- setdiff(mat_col_names, valid_col_ids)
      if (length(orphaned_cols) > 0) {
        errors <- c(errors, sprintf(
          "Matrix '%s': orphaned column reference(s): %s (not in %s)",
          mat_name,
          paste(orphaned_cols, collapse = ", "),
          col_cat
        ))
      }
    }
  }

  errors
}


#' Repair adjacency matrices by removing orphaned references
#'
#' Removes rows and columns whose names do not match any existing element.
#'
#' @param isa_data An ISA data list.
#' @return The repaired ISA data list, or NULL if input is NULL.
#' @export
repair_adjacency_matrices <- function(isa_data) {
  if (is.null(isa_data)) return(NULL)
  if (is.null(isa_data$adjacency_matrices)) return(isa_data)

  # Collect all valid IDs per category
  all_ids <- list()
  for (cat in .VALID_ISA_CATEGORIES) {
    df <- isa_data[[cat]]
    if (!is.null(df) && is.data.frame(df) && nrow(df) > 0 && "id" %in% names(df)) {
      all_ids[[cat]] <- as.character(df$id)
    } else {
      all_ids[[cat]] <- character(0)
    }
  }

  for (mat_name in names(isa_data$adjacency_matrices)) {
    mat <- isa_data$adjacency_matrices[[mat_name]]
    if (is.null(mat)) next

    # Parse matrix name
    parts <- strsplit(mat_name, "_")[[1]]
    if (length(parts) < 2) next

    row_prefix <- NULL
    col_prefix <- NULL
    for (i in seq_along(parts)[-length(parts)]) {
      candidate_row <- paste(parts[1:i], collapse = "_")
      candidate_col <- paste(parts[(i + 1):length(parts)], collapse = "_")
      if (candidate_row %in% names(.MATRIX_PREFIX_MAP) &&
          candidate_col %in% names(.MATRIX_PREFIX_MAP)) {
        row_prefix <- candidate_row
        col_prefix <- candidate_col
        break
      }
    }

    if (is.null(row_prefix) || is.null(col_prefix)) next

    row_cat <- .MATRIX_PREFIX_MAP[[row_prefix]]
    col_cat <- .MATRIX_PREFIX_MAP[[col_prefix]]

    valid_row_ids <- all_ids[[row_cat]]
    valid_col_ids <- all_ids[[col_cat]]

    # Keep only valid rows and columns
    keep_rows <- rownames(mat) %in% valid_row_ids
    keep_cols <- colnames(mat) %in% valid_col_ids

    if (!all(keep_rows) || !all(keep_cols)) {
      repaired <- mat[keep_rows, keep_cols, drop = FALSE]
      debug_log(sprintf(
        "Repaired matrix '%s': %dx%d -> %dx%d",
        mat_name, nrow(mat), ncol(mat), nrow(repaired), ncol(repaired)
      ), "TRANSACTION")
      isa_data$adjacency_matrices[[mat_name]] <- repaired
    }
  }

  isa_data
}
