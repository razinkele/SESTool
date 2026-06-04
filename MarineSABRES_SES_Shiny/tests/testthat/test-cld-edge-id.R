# test-cld-edge-id.R
# Unit tests for edge ID allocation in create_new_edge_data()
# (functions/cld_interaction_helpers.R)
#
# Regression for H2: before the fix, new edge id = nrow(edges)+1, which
# collides after any delete (ids {1,3} -> nrow=2 -> next id=3, collision).

library(testthat)

source_for_test("functions/cld_interaction_helpers.R")

# ---------------------------------------------------------------------------
# Collision tests
# ---------------------------------------------------------------------------

test_that("new edge id is greater than every existing id (no collision after delete)", {
  skip_if_not(exists("create_new_edge_data", mode = "function"))

  # Simulate: edges with ids 1,2,3 then 2 deleted -> existing ids {1,3}, count=2.
  # The OLD code produced id = nrow+1 = 3, which collides with existing id 3.
  # The NEW code uses max_existing_id = max(c(0, 1, 3)) = 3, so new id = 4.
  existing_ids <- c(1L, 3L)
  max_id <- max(c(0L, suppressWarnings(as.numeric(existing_ids))), na.rm = TRUE)
  e <- create_new_edge_data("A", "B", max_id)

  expect_false(e$id %in% existing_ids,
    info = "New edge id must not collide with any existing id")
  expect_equal(e$id, 4L,
    info = "New id must be max(existing)+1 = 3+1 = 4")
})

test_that("new edge id is unique when existing ids are non-contiguous after multiple deletes", {
  skip_if_not(exists("create_new_edge_data", mode = "function"))

  # Worst case: original 1..10, then 2,4,6,8 deleted -> {1,3,5,7,9,10}
  # nrow=6 -> old code gives id=7, collision with 7.
  existing_ids <- c(1L, 3L, 5L, 7L, 9L, 10L)
  max_id <- max(c(0L, suppressWarnings(as.numeric(existing_ids))), na.rm = TRUE)
  e <- create_new_edge_data("X", "Y", max_id)

  expect_false(e$id %in% existing_ids,
    info = "New id must not collide with any existing id in {1,3,5,7,9,10}")
  expect_equal(e$id, 11L,
    info = "New id must be max(1,3,5,7,9,10)+1 = 11")
})

test_that("new edge id = 1 when edge table is empty", {
  skip_if_not(exists("create_new_edge_data", mode = "function"))

  max_id <- max(c(0L, suppressWarnings(as.numeric(integer(0)))), na.rm = TRUE)
  e <- create_new_edge_data("A", "B", max_id)

  expect_equal(e$id, 1L,
    info = "First edge in empty table must get id = 1")
})

# ---------------------------------------------------------------------------
# Well-formed row tests
# ---------------------------------------------------------------------------

test_that("create_new_edge_data returns a well-formed edge row", {
  skip_if_not(exists("create_new_edge_data", mode = "function"))

  e <- create_new_edge_data("A", "B", 0L)

  expect_equal(nrow(e), 1L)
  expect_equal(e$from, "A")
  expect_equal(e$to, "B")
  expect_true("polarity" %in% names(e),
    info = "Edge row must include 'polarity' column")
  expect_true("id" %in% names(e),
    info = "Edge row must include 'id' column")
  expect_true(is.numeric(e$id) || is.integer(e$id),
    info = "Edge id must be numeric")
})

test_that("create_new_edge_data polarity defaults to '+'", {
  skip_if_not(exists("create_new_edge_data", mode = "function"))

  e <- create_new_edge_data("A", "B", 5L)

  expect_equal(e$polarity, "+")
})
