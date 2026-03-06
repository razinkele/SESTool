# tests/testthat/test-undo-redo.R
# Tests for Undo/Redo System (P2 #29)

library(testthat)

# Source the undo/redo module
if (file.exists("functions/undo_redo.R")) {
  source("functions/undo_redo.R")
}

# ============================================================================
# BASIC FUNCTIONALITY TESTS
# ============================================================================

test_that("create_undo_history returns proper structure", {
  skip_if_not(exists("create_undo_history", mode = "function"),
              "create_undo_history function not available")

  history <- create_undo_history()

  expect_true(is.list(history))
  expect_true("undo_history" %in% class(history))

  # Check required methods
  expect_true(is.function(history$push_action))
  expect_true(is.function(history$undo))
  expect_true(is.function(history$redo))
  expect_true(is.function(history$can_undo))
  expect_true(is.function(history$can_redo))
})

test_that("create_undo_action creates valid action", {
  skip_if_not(exists("create_undo_action", mode = "function"),
              "create_undo_action function not available")

  old_state <- list(value = 1)
  new_state <- list(value = 2)

  action <- create_undo_action(
    action_type = "test_action",
    description = "Test description",
    old_state = old_state,
    new_state = new_state
  )

  expect_true(is.list(action))
  expect_true("undo_action" %in% class(action))
  expect_equal(action$action_type, "test_action")
  expect_equal(action$description, "Test description")
  expect_equal(action$old_state$value, 1)
  expect_equal(action$new_state$value, 2)
  expect_true(!is.null(action$timestamp))
})

# ============================================================================
# UNDO/REDO OPERATION TESTS
# ============================================================================

test_that("push_action adds to undo stack", {
  skip_if_not(exists("create_undo_history", mode = "function"),
              "create_undo_history function not available")

  history <- create_undo_history()

  # Initially no undo available
  expect_false(history$can_undo())
  expect_equal(history$undo_count(), 0)

  # Push an action
  history$push_action("add", list(n = 0), list(n = 1), "Added item")

  # Now undo should be available
  expect_true(history$can_undo())
  expect_equal(history$undo_count(), 1)
  expect_equal(history$peek_undo(), "Added item")
})

test_that("undo returns previous state", {
  skip_if_not(exists("create_undo_history", mode = "function"),
              "create_undo_history function not available")

  history <- create_undo_history()

  state1 <- list(value = 1)
  state2 <- list(value = 2)
  state3 <- list(value = 3)

  # Push two actions
  history$push_action("step1", state1, state2, "Step 1")
  history$push_action("step2", state2, state3, "Step 2")

  expect_equal(history$undo_count(), 2)

  # Undo should return state2 (before step2)
  result <- history$undo()
  expect_equal(result$value, 2)

  # Undo again should return state1 (before step1)
  result <- history$undo()
  expect_equal(result$value, 1)

  # No more undos
  expect_false(history$can_undo())
  result <- history$undo()
  expect_null(result)
})

test_that("redo restores undone state", {
  skip_if_not(exists("create_undo_history", mode = "function"),
              "create_undo_history function not available")

  history <- create_undo_history()

  state1 <- list(value = 1)
  state2 <- list(value = 2)

  history$push_action("edit", state1, state2, "Edit")

  # Initially no redo available
  expect_false(history$can_redo())

  # Undo
  history$undo()

  # Now redo should be available
  expect_true(history$can_redo())
  expect_equal(history$redo_count(), 1)

  # Redo should return state2
  result <- history$redo()
  expect_equal(result$value, 2)

  # No more redos
  expect_false(history$can_redo())
})

test_that("new action clears redo stack", {
  skip_if_not(exists("create_undo_history", mode = "function"),
              "create_undo_history function not available")

  history <- create_undo_history()

  # Push and undo
  history$push_action("a1", list(v = 1), list(v = 2), "Action 1")
  history$undo()

  expect_true(history$can_redo())

  # Push new action
  history$push_action("a2", list(v = 1), list(v = 3), "Action 2")

  # Redo should be cleared
  expect_false(history$can_redo())
  expect_equal(history$redo_count(), 0)
})

# ============================================================================
# GROUPING TESTS
# ============================================================================

test_that("action grouping works", {
  skip_if_not(exists("create_undo_history", mode = "function"),
              "create_undo_history function not available")

  history <- create_undo_history()

  state1 <- list(a = 1, b = 1)
  state2 <- list(a = 2, b = 1)
  state3 <- list(a = 2, b = 2)
  state4 <- list(a = 3, b = 3)

  # Start group
  history$start_group("Multiple edits")

  # Push multiple actions within group
  history$push_action("edit_a", state1, state2)
  history$push_action("edit_b", state2, state3)
  history$push_action("edit_both", state3, state4)

  # End group
  history$end_group()

  # Should only count as one undo action
  expect_equal(history$undo_count(), 1)
  expect_equal(history$peek_undo(), "Multiple edits")

  # Single undo should restore to state1
  result <- history$undo()
  expect_equal(result$a, 1)
  expect_equal(result$b, 1)
})

test_that("cancel_group discards grouped actions", {
  skip_if_not(exists("create_undo_history", mode = "function"),
              "create_undo_history function not available")

  history <- create_undo_history()

  history$start_group("Test group")
  history$push_action("a1", list(x = 1), list(x = 2))
  history$push_action("a2", list(x = 2), list(x = 3))
  history$cancel_group()

  # Group was cancelled, no undo should be available
  expect_equal(history$undo_count(), 0)
})

# ============================================================================
# HISTORY LIMIT TESTS
# ============================================================================

test_that("history respects max size", {
  skip_if_not(exists("create_undo_history", mode = "function"),
              "create_undo_history function not available")

  # Create history with small max
  history <- create_undo_history(max_size = 5)

  # Push more than max
  for (i in 1:10) {
    history$push_action(
      paste0("action_", i),
      list(v = i - 1),
      list(v = i)
    )
  }

  # Should only have 5 items
  expect_equal(history$undo_count(), 5)
})

test_that("clear removes all history", {
  skip_if_not(exists("create_undo_history", mode = "function"),
              "create_undo_history function not available")

  history <- create_undo_history()

  history$push_action("a1", list(x = 1), list(x = 2))
  history$push_action("a2", list(x = 2), list(x = 3))
  history$undo()  # Create redo item

  expect_true(history$can_undo())
  expect_true(history$can_redo())

  history$clear()

  expect_false(history$can_undo())
  expect_false(history$can_redo())
  expect_equal(history$undo_count(), 0)
  expect_equal(history$redo_count(), 0)
})

# ============================================================================
# GET_HISTORY TESTS
# ============================================================================

test_that("get_history returns history lists", {
  skip_if_not(exists("create_undo_history", mode = "function"),
              "create_undo_history function not available")

  history <- create_undo_history()

  history$push_action("add", list(n = 0), list(n = 1), "Added")
  history$push_action("edit", list(n = 1), list(n = 2), "Edited")
  history$undo()

  result <- history$get_history()

  expect_true(is.list(result))
  expect_true("undo_stack" %in% names(result))
  expect_true("redo_stack" %in% names(result))
  expect_equal(length(result$undo_stack), 1)
  expect_equal(length(result$redo_stack), 1)
})

# ============================================================================
# ACTION TYPE CONSTANTS TESTS
# ============================================================================

test_that("UNDO_ACTION_TYPES constants exist", {
  skip_if_not(exists("UNDO_ACTION_TYPES"),
              "UNDO_ACTION_TYPES not defined")

  expect_true(is.list(UNDO_ACTION_TYPES))
  expect_true("ADD_NODE" %in% names(UNDO_ACTION_TYPES))
  expect_true("DELETE_NODE" %in% names(UNDO_ACTION_TYPES))
  expect_true("EDIT_NODE" %in% names(UNDO_ACTION_TYPES))
})
