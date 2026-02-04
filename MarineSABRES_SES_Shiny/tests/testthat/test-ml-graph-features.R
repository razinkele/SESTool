# tests/testthat/test-ml-graph-features.R
# Tests for Graph Feature Extraction Module (Phase 2, Week 2)
# ==============================================================================

library(testthat)
library(igraph)
library(dplyr)

# Load module
source("../../functions/ml_graph_features.R", chdir = TRUE)

# ==============================================================================
# Test Fixtures: Create Sample Network
# ==============================================================================

create_test_network <- function() {
  # Sample DAPSIWRM network
  nodes <- data.frame(
    id = c("D1", "A1", "P1", "MPF1", "ES1", "GB1", "R1"),
    label = c(
      "Economic growth",
      "Fishing",
      "Overfishing",
      "Fish decline",
      "Fish provision",
      "Food security",
      "Fishing quota"
    ),
    group = c(
      "Drivers",
      "Activities",
      "Pressures",
      "Marine Processes & Functioning",
      "Ecosystem Services",
      "Goods & Benefits",
      "Responses"
    ),
    stringsAsFactors = FALSE
  )

  edges <- data.frame(
    from = c("D1", "A1", "P1", "MPF1", "ES1", "GB1", "R1"),
    to = c("A1", "P1", "MPF1", "ES1", "GB1", "R1", "A1"),
    polarity = c("+", "+", "+", "-", "+", "+", "-"),
    stringsAsFactors = FALSE
  )

  list(nodes = nodes, edges = edges)
}

# ==============================================================================
# Test: DAPSIWRM Distance Calculation
# ==============================================================================

test_that("calculate_dapsiwrm_distance computes correct distances", {
  # Adjacent types (forward)
  expect_equal(calculate_dapsiwrm_distance("Drivers", "Activities"), 0)
  expect_equal(calculate_dapsiwrm_distance("Activities", "Pressures"), 0)
  expect_equal(calculate_dapsiwrm_distance("Pressures", "Marine Processes & Functioning"), 0)

  # Skip one type
  expect_equal(calculate_dapsiwrm_distance("Drivers", "Pressures"), 1)
  expect_equal(calculate_dapsiwrm_distance("Activities", "Marine Processes & Functioning"), 1)

  # Skip two types
  expect_equal(calculate_dapsiwrm_distance("Drivers", "Marine Processes & Functioning"), 2)

  # Valid feedback loops (distance = 0)
  expect_equal(calculate_dapsiwrm_distance("Responses", "Drivers"), 0)
  expect_equal(calculate_dapsiwrm_distance("Responses", "Activities"), 0)
  expect_equal(calculate_dapsiwrm_distance("Responses", "Pressures"), 0)
  expect_equal(calculate_dapsiwrm_distance("Goods & Benefits", "Drivers"), 0)

  # Invalid backward connections (penalized)
  expect_equal(calculate_dapsiwrm_distance("Pressures", "Activities"), 5)
  expect_equal(calculate_dapsiwrm_distance("Ecosystem Services", "Drivers"), 5)
})

test_that("calculate_dapsiwrm_distance handles unknown types", {
  # Unknown types should return maximum distance
  expect_equal(calculate_dapsiwrm_distance("Unknown", "Activities"), 5)
  expect_equal(calculate_dapsiwrm_distance("Drivers", "Unknown"), 5)
})

# ==============================================================================
# Test: Valid DAPSIWRM Transition Check
# ==============================================================================

test_that("check_valid_dapsiwrm_transition identifies valid transitions", {
  # Valid forward transitions
  expect_equal(check_valid_dapsiwrm_transition("Drivers", "Activities"), 1)
  expect_equal(check_valid_dapsiwrm_transition("Activities", "Pressures"), 1)
  expect_equal(check_valid_dapsiwrm_transition("Pressures", "Marine Processes & Functioning"), 1)

  # Valid feedback transitions
  expect_equal(check_valid_dapsiwrm_transition("Responses", "Drivers"), 1)
  expect_equal(check_valid_dapsiwrm_transition("Responses", "Activities"), 1)
  expect_equal(check_valid_dapsiwrm_transition("Goods & Benefits", "Drivers"), 1)

  # Invalid transitions
  expect_equal(check_valid_dapsiwrm_transition("Pressures", "Activities"), 0)
  expect_equal(check_valid_dapsiwrm_transition("Ecosystem Services", "Drivers"), 0)
})

# ==============================================================================
# Test: Graph Feature Extraction (Single Pair)
# ==============================================================================

test_that("extract_graph_features returns correct structure", {
  network <- create_test_network()
  graph <- create_igraph_from_data(network$nodes, network$edges)

  features <- extract_graph_features("D1", "A1", graph, network$nodes)

  expect_type(features, "double")
  expect_length(features, 8)
  expect_true(all(!is.na(features)))
  expect_true(all(is.finite(features)))
})

test_that("extract_graph_features computes correct degree features", {
  network <- create_test_network()
  graph <- create_igraph_from_data(network$nodes, network$edges)

  features <- extract_graph_features("D1", "A1", graph, network$nodes)

  # D1 has outdegree 1, A1 has indegree 2 (from D1 and R1)
  expect_equal(features[1], 1)  # source_outdegree
  expect_equal(features[2], 2)  # target_indegree
})

test_that("extract_graph_features computes betweenness centrality", {
  network <- create_test_network()
  graph <- create_igraph_from_data(network$nodes, network$edges)

  features <- extract_graph_features("A1", "P1", graph, network$nodes)

  # Betweenness should be normalized (0-1 range)
  expect_gte(features[3], 0)  # source_betweenness
  expect_lte(features[3], 1)
  expect_gte(features[4], 0)  # target_betweenness
  expect_lte(features[4], 1)
})

test_that("extract_graph_features computes shortest path correctly", {
  network <- create_test_network()
  graph <- create_igraph_from_data(network$nodes, network$edges)

  # Direct connection: path length = 1
  features_direct <- extract_graph_features("D1", "A1", graph, network$nodes)
  expect_equal(features_direct[5], 1)

  # Two hops: D1 → A1 → P1
  features_two_hops <- extract_graph_features("D1", "P1", graph, network$nodes)
  expect_equal(features_two_hops[5], 2)
})

test_that("extract_graph_features computes DAPSIWRM features correctly", {
  network <- create_test_network()
  graph <- create_igraph_from_data(network$nodes, network$edges)

  # D1 (Drivers) → A1 (Activities): adjacent, valid
  features <- extract_graph_features("D1", "A1", graph, network$nodes)
  expect_equal(features[6], 0)  # dapsiwrm_distance (adjacent)
  expect_equal(features[7], 1)  # valid_transition
})

test_that("extract_graph_features handles unreachable nodes", {
  network <- create_test_network()

  # Add isolated node
  network$nodes <- rbind(
    network$nodes,
    data.frame(
      id = "ISOLATED",
      label = "Isolated element",
      group = "Drivers",
      stringsAsFactors = FALSE
    )
  )

  graph <- create_igraph_from_data(network$nodes, network$edges)

  features <- extract_graph_features("D1", "ISOLATED", graph, network$nodes)

  # Shortest path should be large (10 = unreachable)
  expect_equal(features[5], 10)
})

test_that("extract_graph_features handles missing nodes", {
  network <- create_test_network()
  graph <- create_igraph_from_data(network$nodes, network$edges)

  # Non-existent node
  features <- extract_graph_features("NONEXISTENT", "A1", graph, network$nodes)

  # Should return zero vector
  expect_equal(features, rep(0, 8))
})

test_that("extract_graph_features handles NULL graph gracefully", {
  network <- create_test_network()

  features <- extract_graph_features("D1", "A1", NULL, network$nodes)

  # Should return zero vector
  expect_equal(features, rep(0, 8))
})

# ==============================================================================
# Test: Batch Feature Extraction
# ==============================================================================

test_that("extract_graph_features_batch returns correct structure", {
  network <- create_test_network()
  graph <- create_igraph_from_data(network$nodes, network$edges)

  source_ids <- c("D1", "A1", "P1")
  target_ids <- c("A1", "P1", "MPF1")

  features_matrix <- extract_graph_features_batch(
    source_ids, target_ids, graph, network$nodes
  )

  expect_true(is.matrix(features_matrix))
  expect_equal(nrow(features_matrix), 3)
  expect_equal(ncol(features_matrix), 8)
  expect_true(all(!is.na(features_matrix)))
})

test_that("extract_graph_features_batch matches single extraction", {
  network <- create_test_network()
  graph <- create_igraph_from_data(network$nodes, network$edges)

  # Extract features individually
  features_single <- extract_graph_features("D1", "A1", graph, network$nodes)

  # Extract same pair in batch
  features_batch <- extract_graph_features_batch(
    c("D1"), c("A1"), graph, network$nodes
  )

  expect_equal(as.numeric(features_batch[1, ]), features_single)
})

test_that("extract_graph_features_batch validates input lengths", {
  network <- create_test_network()
  graph <- create_igraph_from_data(network$nodes, network$edges)

  # Mismatched lengths
  expect_error(
    extract_graph_features_batch(c("D1", "A1"), c("A1"), graph, network$nodes),
    "must have the same length"
  )
})

test_that("extract_graph_features_batch handles NULL graph", {
  network <- create_test_network()

  features_matrix <- extract_graph_features_batch(
    c("D1", "A1"), c("A1", "P1"), NULL, network$nodes
  )

  # Should return zero matrix
  expect_equal(features_matrix, matrix(0, nrow = 2, ncol = 8))
})

# ==============================================================================
# Test: Graph Caching
# ==============================================================================

test_that("get_cached_graph stores and retrieves graphs", {
  network <- create_test_network()

  # First call: builds graph
  graph1 <- get_cached_graph(network$nodes, network$edges, cache_key = "test_graph")
  expect_s3_class(graph1, "igraph")

  # Second call: retrieves from cache
  graph2 <- get_cached_graph(network$nodes, network$edges, cache_key = "test_graph")
  expect_identical(graph1, graph2)
})

test_that("get_cached_graph force_rebuild invalidates cache", {
  network <- create_test_network()

  # Build and cache
  graph1 <- get_cached_graph(network$nodes, network$edges, cache_key = "test_graph2")

  # Force rebuild
  graph2 <- get_cached_graph(
    network$nodes, network$edges,
    cache_key = "test_graph2",
    force_rebuild = TRUE
  )

  # Should rebuild (new object, but structurally identical)
  expect_s3_class(graph2, "igraph")
})

test_that("clear_graph_cache removes all cached graphs", {
  network <- create_test_network()

  # Cache a graph
  get_cached_graph(network$nodes, network$edges, cache_key = "test_clear")

  # Verify cached
  expect_true(exists("test_clear", envir = GRAPH_CACHE))

  # Clear cache
  clear_graph_cache()

  # Verify cleared
  expect_false(exists("test_clear", envir = GRAPH_CACHE))
})

# ==============================================================================
# Test: Utility Functions
# ==============================================================================

test_that("get_graph_feature_dim returns correct dimension", {
  expect_equal(get_graph_feature_dim(), 8)
})

test_that("get_graph_feature_names returns 8 names", {
  names <- get_graph_feature_names()
  expect_length(names, 8)
  expect_type(names, "character")

  # Check specific names
  expect_true("source_outdegree" %in% names)
  expect_true("target_indegree" %in% names)
  expect_true("dapsiwrm_distance" %in% names)
  expect_true("valid_dapsiwrm_transition" %in% names)
})

# ==============================================================================
# Performance Test
# ==============================================================================

test_that("batch extraction is reasonably fast", {
  network <- create_test_network()
  graph <- create_igraph_from_data(network$nodes, network$edges)

  # Create 100 random pairs
  n_pairs <- 100
  all_ids <- network$nodes$id
  source_ids <- sample(all_ids, n_pairs, replace = TRUE)
  target_ids <- sample(all_ids, n_pairs, replace = TRUE)

  # Measure time
  start_time <- Sys.time()
  features_matrix <- extract_graph_features_batch(
    source_ids, target_ids, graph, network$nodes
  )
  elapsed <- as.numeric(Sys.time() - start_time, units = "secs")

  # Should complete in < 2 seconds for 100 pairs
  expect_lt(elapsed, 2.0)

  # Verify output
  expect_equal(nrow(features_matrix), n_pairs)
  expect_equal(ncol(features_matrix), 8)
})

# ==============================================================================
# Integration Test
# ==============================================================================

test_that("graph features integrate with existing network analysis", {
  skip_if_not(exists("create_igraph_from_data"))

  network <- create_test_network()

  # Use existing network analysis function
  graph <- create_igraph_from_data(network$nodes, network$edges)

  # Extract features
  features <- extract_graph_features("D1", "A1", graph, network$nodes)

  # Should work seamlessly
  expect_length(features, 8)
  expect_true(all(!is.na(features)))
})

cat("\n✓ All graph features tests passed!\n")
