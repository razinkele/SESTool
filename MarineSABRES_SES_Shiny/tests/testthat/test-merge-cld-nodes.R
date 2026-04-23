# test-merge-cld-nodes.R
# Tests for merge_cld_nodes() — the pure logic behind the
# "merge selected elements" feature on the SES diagram.

library(testthat)

source_for_test("functions/cld_interaction_helpers.R")

make_fixture <- function() {
  nodes <- data.frame(
    id = c("D_1", "D_2", "A_1", "A_2"),
    label = c("Overfishing", "Industrial fishing", "Trawl fisheries", "Pelagic fisheries"),
    group = c("Drivers", "Drivers", "Activities", "Activities"),
    stringsAsFactors = FALSE
  )
  edges <- data.frame(
    id = 1:4,
    from = c("D_1", "D_2", "A_1", "A_2"),
    to   = c("A_1", "A_1", "D_1", "D_2"),
    label = c("+", "+", "-", "-"),
    stringsAsFactors = FALSE
  )
  list(nodes = nodes, edges = edges)
}

test_that("merge_cld_nodes exists", {
  skip_if_not(exists("merge_cld_nodes", mode = "function"),
              "merge_cld_nodes not available")
  expect_true(is.function(merge_cld_nodes))
})

test_that("merge_cld_nodes errors on fewer than 2 ids", {
  skip_if_not(exists("merge_cld_nodes", mode = "function"),
              "merge_cld_nodes not available")
  fx <- make_fixture()
  result <- merge_cld_nodes(fx$nodes, fx$edges, "D_1", "D_1")
  expect_true(!is.null(result$error))
})

test_that("merge_cld_nodes errors when primary_id not in node_ids", {
  skip_if_not(exists("merge_cld_nodes", mode = "function"),
              "merge_cld_nodes not available")
  fx <- make_fixture()
  result <- merge_cld_nodes(fx$nodes, fx$edges, c("D_1", "D_2"), "A_1")
  expect_true(!is.null(result$error))
})

test_that("merge_cld_nodes refuses cross-group merges", {
  skip_if_not(exists("merge_cld_nodes", mode = "function"),
              "merge_cld_nodes not available")
  fx <- make_fixture()
  result <- merge_cld_nodes(fx$nodes, fx$edges, c("D_1", "A_1"), "D_1")
  expect_true(!is.null(result$error))
  expect_true(grepl("different element types", result$error))
})

test_that("merge_cld_nodes removes secondary and keeps primary label", {
  skip_if_not(exists("merge_cld_nodes", mode = "function"),
              "merge_cld_nodes not available")
  fx <- make_fixture()
  result <- merge_cld_nodes(fx$nodes, fx$edges, c("D_1", "D_2"), "D_1")
  expect_null(result$error)
  expect_equal(nrow(result$nodes), 3)  # D_1 + A_1 + A_2
  expect_true("D_1" %in% result$nodes$id)
  expect_false("D_2" %in% result$nodes$id)
  expect_equal(result$removed_ids, "D_2")
})

test_that("merge_cld_nodes rewires edges and deduplicates", {
  skip_if_not(exists("merge_cld_nodes", mode = "function"),
              "merge_cld_nodes not available")
  fx <- make_fixture()
  # Before: 4 edges. After merging D_1 + D_2 (primary=D_1):
  #   edge 1: D_1 -> A_1  (+)  kept
  #   edge 2: D_2 -> A_1  (+)  rewired to D_1 -> A_1 (+) - DUPE, dropped
  #   edge 3: A_1 -> D_1  (-)  kept
  #   edge 4: A_2 -> D_2  (-)  rewired to A_2 -> D_1 (-) - kept (unique from+to)
  # So result has 3 edges.
  result <- merge_cld_nodes(fx$nodes, fx$edges, c("D_1", "D_2"), "D_1")
  expect_equal(nrow(result$edges), 3)
  # None of the remaining edges reference D_2
  expect_false(any(result$edges$from == "D_2"))
  expect_false(any(result$edges$to == "D_2"))
})

test_that("merge_cld_nodes drops self-loops from merged pairs", {
  skip_if_not(exists("merge_cld_nodes", mode = "function"),
              "merge_cld_nodes not available")
  # If there's a D_1 -> D_2 edge and we merge them, the rewired
  # edge would be D_1 -> D_1 (self-loop) - should drop.
  nodes <- data.frame(
    id = c("D_1", "D_2", "A_1"),
    label = c("a", "b", "c"),
    group = c("Drivers", "Drivers", "Activities"),
    stringsAsFactors = FALSE
  )
  edges <- data.frame(
    id = 1:2,
    from = c("D_1", "D_1"),
    to   = c("D_2", "A_1"),
    label = c("+", "+"),
    stringsAsFactors = FALSE
  )
  result <- merge_cld_nodes(nodes, edges, c("D_1", "D_2"), "D_1")
  # Expect: D_1 -> D_1 dropped (self-loop), D_1 -> A_1 kept
  expect_equal(nrow(result$edges), 1)
  expect_equal(result$edges$from, "D_1")
  expect_equal(result$edges$to, "A_1")
})

test_that("merge_cld_nodes handles 3-way merge (primary + 2 secondaries)", {
  skip_if_not(exists("merge_cld_nodes", mode = "function"),
              "merge_cld_nodes not available")
  nodes <- data.frame(
    id = c("P_1", "P_2", "P_3", "S_1"),
    label = c("p1", "p2", "p3", "state1"),
    group = c("Pressures", "Pressures", "Pressures", "Marine Processes & Functioning"),
    stringsAsFactors = FALSE
  )
  edges <- data.frame(
    id = 1:3,
    from = c("P_1", "P_2", "P_3"),
    to   = c("S_1", "S_1", "S_1"),
    label = c("+", "+", "+"),
    stringsAsFactors = FALSE
  )
  result <- merge_cld_nodes(nodes, edges, c("P_1", "P_2", "P_3"), "P_1")
  expect_equal(nrow(result$nodes), 2)  # P_1 + S_1
  # 3 edges all become P_1 -> S_1 (+), deduped to 1
  expect_equal(nrow(result$edges), 1)
  expect_equal(result$removed_ids, c("P_2", "P_3"))
})

test_that("merge_cld_nodes distinguishes edges with NA labels from polarity-matched edges", {
  # REGRESSION: original dedupe built key via paste(..., NA, sep='|') which
  # converts NA to the string 'NA', wrongly collapsing two semantically-
  # distinct NA-polarity edges into one.
  skip_if_not(exists("merge_cld_nodes", mode = "function"),
              "merge_cld_nodes not available")
  nodes <- data.frame(
    id = c("D_1", "D_2", "A_1", "A_2"),
    label = c("d1", "d2", "a1", "a2"),
    group = c("Drivers", "Drivers", "Activities", "Activities"),
    stringsAsFactors = FALSE
  )
  # Two edges both with NA label but DIFFERENT targets after rewiring — must
  # NOT be collapsed.  D_1 -> A_1 (NA) and D_2 -> A_2 (NA). After merging
  # D_1 + D_2 to D_1, you get D_1 -> A_1 (NA) and D_1 -> A_2 (NA). Both
  # should survive dedupe.
  edges <- data.frame(
    id = 1:2,
    from = c("D_1", "D_2"),
    to = c("A_1", "A_2"),
    label = c(NA, NA),
    stringsAsFactors = FALSE
  )
  result <- merge_cld_nodes(nodes, edges, c("D_1", "D_2"), "D_1")
  expect_equal(nrow(result$edges), 2)  # both preserved
})
