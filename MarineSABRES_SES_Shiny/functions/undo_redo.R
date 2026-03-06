# =============================================================================
# UNDO/REDO SYSTEM
# File: functions/undo_redo.R
# =============================================================================
#
# Purpose:
#   Implements a command pattern-based undo/redo system for the application.
#   Tracks user actions and allows reverting or replaying them.
#
# Design:
#   - Uses a stack-based history with configurable max depth
#   - Each command stores state delta (not full state) for efficiency
#   - Supports grouping multiple actions into a single undo unit
#   - Thread-safe for single-session Shiny applications
#
# Usage:
#   history <- create_undo_history()
#   history$push_action("add_node", old_state, new_state)
#   history$undo()  # Returns previous state
#   history$redo()  # Returns next state
#
# =============================================================================

# =============================================================================
# CONSTANTS
# =============================================================================

UNDO_MAX_HISTORY_SIZE <- 50           # Maximum number of undo steps
UNDO_GROUP_TIMEOUT_MS <- 1000         # Time window for auto-grouping actions

# =============================================================================
# UNDO ACTION CLASS
# =============================================================================

#' Create an Undo Action
#'
#' Represents a single undoable action with before/after states.
#'
#' @param action_type Character. Type of action (e.g., "add_node", "delete_edge")
#' @param description Character. Human-readable description
#' @param old_state List. State before the action
#' @param new_state List. State after the action
#' @param timestamp POSIXct. When the action occurred
#' @return An undo_action object
#' @export
create_undo_action <- function(action_type,
                                description = NULL,
                                old_state,
                                new_state,
                                timestamp = Sys.time()) {
  action <- list(
    action_type = action_type,
    description = description %||% action_type,
    old_state = old_state,
    new_state = new_state,
    timestamp = timestamp
  )
  class(action) <- c("undo_action", "list")
  action
}

#' Print Undo Action
#' @param x Undo action object
#' @param ... Additional arguments
#' @export
print.undo_action <- function(x, ...) {
  cat(sprintf("UndoAction: %s\n", x$description))
  cat(sprintf("  Type: %s\n", x$action_type))
  cat(sprintf("  Time: %s\n", format(x$timestamp, "%H:%M:%S")))
}

# =============================================================================
# UNDO HISTORY MANAGER
# =============================================================================

#' Create Undo History Manager
#'
#' Creates a history manager with undo/redo stacks and operations.
#'
#' @param max_size Integer. Maximum number of undo steps (default: 50)
#' @return An undo_history environment with methods
#' @export
create_undo_history <- function(max_size = UNDO_MAX_HISTORY_SIZE) {

  # Private state
  env <- new.env(parent = emptyenv())
  env$undo_stack <- list()
  env$redo_stack <- list()
  env$max_size <- max_size
  env$grouping <- FALSE
  env$current_group <- list()
  env$group_description <- NULL

  # ---------------------------------------------------------------------------
  # PUSH ACTION
  # ---------------------------------------------------------------------------

  #' Push an action onto the undo stack
  #'
  #' @param action_type Character. Type of action

  #' @param old_state List. State before action
  #' @param new_state List. State after action
  #' @param description Character. Optional description
  push_action <- function(action_type, old_state, new_state, description = NULL) {
    action <- create_undo_action(
      action_type = action_type,
      description = description,
      old_state = old_state,
      new_state = new_state
    )

    if (env$grouping) {
      # Add to current group
      env$current_group <- c(env$current_group, list(action))
    } else {
      # Add directly to undo stack
      add_to_undo_stack(action)
    }

    # Clear redo stack (new action invalidates redo history)
    env$redo_stack <- list()

    invisible(action)
  }

  # ---------------------------------------------------------------------------
  # STACK MANAGEMENT
  # ---------------------------------------------------------------------------

  add_to_undo_stack <- function(action) {
    env$undo_stack <- c(list(action), env$undo_stack)

    # Enforce max size
    if (length(env$undo_stack) > env$max_size) {
      env$undo_stack <- env$undo_stack[1:env$max_size]
    }
  }

  # ---------------------------------------------------------------------------
  # UNDO OPERATION
  # ---------------------------------------------------------------------------

  #' Undo the last action
  #'
  #' @return The old_state from the undone action, or NULL if nothing to undo
  undo <- function() {
    if (length(env$undo_stack) == 0) {
      return(NULL)
    }

    # Pop from undo stack
    action <- env$undo_stack[[1]]
    env$undo_stack <- env$undo_stack[-1]

    # Push to redo stack
    env$redo_stack <- c(list(action), env$redo_stack)

    # Return the old state (state before the action)
    action$old_state
  }

  # ---------------------------------------------------------------------------
  # REDO OPERATION
  # ---------------------------------------------------------------------------

  #' Redo the last undone action
  #'
  #' @return The new_state from the redone action, or NULL if nothing to redo
  redo <- function() {
    if (length(env$redo_stack) == 0) {
      return(NULL)
    }

    # Pop from redo stack
    action <- env$redo_stack[[1]]
    env$redo_stack <- env$redo_stack[-1]

    # Push back to undo stack
    add_to_undo_stack(action)

    # Return the new state (state after the action)
    action$new_state
  }

  # ---------------------------------------------------------------------------
  # ACTION GROUPING
  # ---------------------------------------------------------------------------

  #' Start grouping actions into a single undo unit
  #'
  #' @param description Character. Description for the grouped action
  start_group <- function(description = "Multiple changes") {
    env$grouping <- TRUE
    env$current_group <- list()
    env$group_description <- description
  }

  #' End action grouping and commit as single undo unit
  end_group <- function() {
    if (!env$grouping || length(env$current_group) == 0) {
      env$grouping <- FALSE
      return(invisible(NULL))
    }

    # Create combined action from group
    first_action <- env$current_group[[1]]
    last_action <- env$current_group[[length(env$current_group)]]

    combined <- create_undo_action(
      action_type = "group",
      description = env$group_description,
      old_state = first_action$old_state,  # State before first action
      new_state = last_action$new_state    # State after last action
    )

    add_to_undo_stack(combined)

    env$grouping <- FALSE
    env$current_group <- list()
    env$group_description <- NULL

    invisible(combined)
  }

  #' Cancel current grouping without committing
  cancel_group <- function() {
    env$grouping <- FALSE
    env$current_group <- list()
    env$group_description <- NULL
  }

  # ---------------------------------------------------------------------------
  # STATUS QUERIES
  # ---------------------------------------------------------------------------

  #' Check if undo is available
  #'
  #' @return Logical
  can_undo <- function() {
    length(env$undo_stack) > 0
  }

  #' Check if redo is available
  #'
  #' @return Logical
  can_redo <- function() {
    length(env$redo_stack) > 0
  }

  #' Get number of undo steps available
  #'
  #' @return Integer
  undo_count <- function() {
    length(env$undo_stack)
  }

  #' Get number of redo steps available
  #'
  #' @return Integer
  redo_count <- function() {
    length(env$redo_stack)
  }

  #' Get description of next undo action
  #'
  #' @return Character or NULL
  peek_undo <- function() {
    if (length(env$undo_stack) == 0) return(NULL)
    env$undo_stack[[1]]$description
  }

  #' Get description of next redo action
  #'
  #' @return Character or NULL
  peek_redo <- function() {
    if (length(env$redo_stack) == 0) return(NULL)
    env$redo_stack[[1]]$description
  }

  #' Get full history list (for debugging/display)
  #'
  #' @return List with undo and redo history
  get_history <- function() {
    list(
      undo_stack = lapply(env$undo_stack, function(a) {
        list(type = a$action_type, description = a$description, time = a$timestamp)
      }),
      redo_stack = lapply(env$redo_stack, function(a) {
        list(type = a$action_type, description = a$description, time = a$timestamp)
      })
    )
  }

  # ---------------------------------------------------------------------------
  # CLEAR HISTORY
  # ---------------------------------------------------------------------------

  #' Clear all undo/redo history
  clear <- function() {
    env$undo_stack <- list()
    env$redo_stack <- list()
    env$grouping <- FALSE
    env$current_group <- list()
    invisible(NULL)
  }

  # ---------------------------------------------------------------------------
  # RETURN PUBLIC INTERFACE
  # ---------------------------------------------------------------------------

  structure(
    list(
      # Core operations
      push_action = push_action,
      undo = undo,
      redo = redo,

      # Grouping
      start_group = start_group,
      end_group = end_group,
      cancel_group = cancel_group,

      # Status
      can_undo = can_undo,
      can_redo = can_redo,
      undo_count = undo_count,
      redo_count = redo_count,
      peek_undo = peek_undo,
      peek_redo = peek_redo,
      get_history = get_history,

      # Management
      clear = clear
    ),
    class = "undo_history"
  )
}

#' Print Undo History
#' @param x Undo history object
#' @param ... Additional arguments
#' @export
print.undo_history <- function(x, ...) {
  cat("Undo History Manager\n")
  cat(sprintf("  Undo steps: %d\n", x$undo_count()))
  cat(sprintf("  Redo steps: %d\n", x$redo_count()))
  if (x$can_undo()) {
    cat(sprintf("  Next undo: %s\n", x$peek_undo()))
  }
  if (x$can_redo()) {
    cat(sprintf("  Next redo: %s\n", x$peek_redo()))
  }
}

# =============================================================================
# SHINY INTEGRATION HELPERS
# =============================================================================

#' Create Undo/Redo Reactive Values
#'
#' Creates reactive values for Shiny integration with undo/redo.
#'
#' @param initial_state Initial application state
#' @return List with reactive values and history manager
#' @export
create_undo_reactive <- function(initial_state = NULL) {
  if (!requireNamespace("shiny", quietly = TRUE)) {
    stop("Shiny package required for reactive undo/redo")
  }

  # Create history manager
  history <- create_undo_history()

  # Create reactive values
  rv <- shiny::reactiveValues(
    state = initial_state,
    can_undo = FALSE,
    can_redo = FALSE,
    undo_description = NULL,
    redo_description = NULL
  )

  #' Update state with undo tracking
  #'
  #' @param new_state New state
  #' @param action_type Type of action
  #' @param description Action description
  update_state <- function(new_state, action_type, description = NULL) {
    old_state <- shiny::isolate(rv$state)
    history$push_action(action_type, old_state, new_state, description)

    rv$state <- new_state
    rv$can_undo <- history$can_undo()
    rv$can_redo <- history$can_redo()
    rv$undo_description <- history$peek_undo()
    rv$redo_description <- history$peek_redo()
  }

  #' Perform undo
  perform_undo <- function() {
    old_state <- history$undo()
    if (!is.null(old_state)) {
      rv$state <- old_state
      rv$can_undo <- history$can_undo()
      rv$can_redo <- history$can_redo()
      rv$undo_description <- history$peek_undo()
      rv$redo_description <- history$peek_redo()
    }
  }

  #' Perform redo
  perform_redo <- function() {
    new_state <- history$redo()
    if (!is.null(new_state)) {
      rv$state <- new_state
      rv$can_undo <- history$can_undo()
      rv$can_redo <- history$can_redo()
      rv$undo_description <- history$peek_undo()
      rv$redo_description <- history$peek_redo()
    }
  }

  list(
    rv = rv,
    history = history,
    update_state = update_state,
    perform_undo = perform_undo,
    perform_redo = perform_redo
  )
}

# =============================================================================
# ACTION TYPE CONSTANTS
# =============================================================================

# Standard action types for consistency
UNDO_ACTION_TYPES <- list(
  ADD_NODE = "add_node",
  DELETE_NODE = "delete_node",
  EDIT_NODE = "edit_node",
  ADD_EDGE = "add_edge",
  DELETE_EDGE = "delete_edge",
  EDIT_EDGE = "edit_edge",
  MOVE_NODE = "move_node",
  IMPORT_DATA = "import_data",
  CLEAR_DATA = "clear_data",
  APPLY_TEMPLATE = "apply_template",
  BATCH_EDIT = "batch_edit"
)
