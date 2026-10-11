# project_transactions.R
# Atomic transaction wrappers for project state management,
# cross-reference validation, and ISA modifier factories.
#
# P0 Fixes:
#   1. with_project_transaction / with_project_transaction_batch
#   2. create_isa_modifier
#   3. validate_matrix_alignment (replaced the earlier cross-reference
#      validator and repair function, 2026-10-11)

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
                                     event_bus = NULL,
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
          paste0("[Transaction Error] ", e$message),
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

  # NOTE: Stub implementation — returns identity modifier.
  # The modifier validates inputs but does not perform actual ISA modifications.
  # This scaffolding supports test infrastructure and will be extended when
  # ISA data entry modules adopt the transaction wrapper pattern.
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

#' Check that adjacency matrices line up with the element lists
#'
#' The CLD builder (create_edges_df -> process_adjacency_matrix) reads matrix
#' cells by POSITION: row i is the i-th element of the row category. If a
#' matrix has more or fewer rows/columns than there are elements, or its
#' row/column names are in a different order, links silently attach to the
#' wrong nodes. This reports such mismatches; it never changes the data.
#'
#' Row/column names may be element names (most load paths) or element IDs;
#' a position matches if it equals either.
#'
#' Replaces validate_cross_references()/repair_adjacency_matrices(), which
#' compared names against a lowercase `id` column that canonical frames do not
#' have and flagged every template (review 2026-10-07 N68 follow-up).
#'
#' @param isa_data ISA data list with element data frames and adjacency_matrices
#' @return character vector of findings (empty when aligned)
#' @export
validate_matrix_alignment <- function(isa_data) {
  am <- isa_data$adjacency_matrices
  if (is.null(am) || length(am) == 0) return(character(0))

  element_keys <- function(cat) {
    df <- isa_data[[cat]]
    if (!is.data.frame(df) || nrow(df) == 0) {
      return(list(n = 0L, name = NULL, id = NULL))
    }
    col_of <- function(cands) {
      hit <- intersect(cands, names(df))
      if (length(hit) == 0) NULL else trimws(as.character(df[[hit[1]]]))
    }
    list(n = nrow(df), name = col_of(c("Name", "name")), id = col_of(c("ID", "id")))
  }

  findings <- character(0)
  for (mat_name in names(am)) {
    mat <- am[[mat_name]]
    if (is.null(mat) || length(dim(mat)) != 2) next
    parts <- strsplit(mat_name, "_", fixed = TRUE)[[1]]
    if (length(parts) != 2 || !all(parts %in% names(.MATRIX_PREFIX_MAP))) next

    for (side in 1:2) {
      cat <- .MATRIX_PREFIX_MAP[[parts[side]]]
      el <- element_keys(cat)
      n_mat <- dim(mat)[side]
      what <- if (side == 1) "rows" else "columns"
      if (n_mat != el$n) {
        findings <- c(findings, sprintf("%s: %d %s for %d %s",
                                        mat_name, n_mat, what, el$n, cat))
        next
      }
      labels <- dimnames(mat)[[side]]
      if (is.null(labels) || el$n == 0) next
      labels <- trimws(as.character(labels))
      ok <- rep(FALSE, el$n)
      if (!is.null(el$name)) ok <- ok | labels == el$name
      if (!is.null(el$id))   ok <- ok | labels == el$id
      ok[is.na(ok)] <- FALSE
      if (!all(ok)) {
        findings <- c(findings, sprintf("%s: %s out of order or stale at position(s) %s",
                                        mat_name, what, paste(which(!ok), collapse = ", ")))
      }
    }
  }
  findings
}
