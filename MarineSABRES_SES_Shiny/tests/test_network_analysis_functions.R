# Comprehensive Test Suite for All Network Analysis Functions
# Tests MICMAC, centrality, leverage points, path analysis, etc.

library(testthat)
library(igraph)
library(dplyr)

# Source the functions
source("../functions/network_analysis.R")

context("Network Analysis Functions - Complete Suite")

# ==============================================================================
# SETUP: Test Networks
# ==============================================================================

# Small test network
create_small_test_network <- function() {
  nodes <- data.frame(
    id = paste0("N", 1:10),
    label = paste("Node", 1:10),
    stringsAsFactors = FALSE
  )

  edges <- data.frame(
    from = c("N1", "N2", "N3", "N4", "N5", "N1", "N2", "N6"),
    to = c("N2", "N3", "N4", "N5", "N1", "N6", "N7", "N1"),
    polarity = c("+", "-", "+", "-", "+", "+", "-", "+"),
    strength = "medium",
    stringsAsFactors = FALSE
  )

  list(nodes = nodes, edges = edges)
}

# ==============================================================================
# TEST: Network Metrics
# ==============================================================================

test_that("calculate_network_metrics works correctly", {
  net <- create_small_test_network()

  metrics <- calculate_network_metrics(net$nodes, net$edges)

  expect_type(metrics, "list")
  expect_true("nodes" %in% names(metrics))
  expect_true("edges" %in% names(metrics))
  expect_true("density" %in% names(metrics))
  expect_true("degree" %in% names(metrics))
  expect_true("betweenness" %in% names(metrics))

  expect_equal(metrics$nodes, 10)
  expect_equal(metrics$edges, 8)
  expect_true(metrics$density >= 0 && metrics$density <= 1)
})

test_that("calculate_network_metrics handles empty network", {
  nodes <- data.frame(id = character(0), label = character(0), stringsAsFactors = FALSE)
  edges <- data.frame(from = character(0), to = character(0),
                      polarity = character(0), strength = character(0),
                      stringsAsFactors = FALSE)

  expect_error(
    calculate_network_metrics(nodes, edges),
    "No valid edges"
  )
})

# ==============================================================================
# TEST: MICMAC Analysis
# ==============================================================================

test_that("calculate_micmac works correctly", {
  net <- create_small_test_network()

  micmac <- calculate_micmac(net$nodes, net$edges)

  expect_s3_class(micmac, "data.frame")
  expect_true("node_id" %in% names(micmac))
  expect_true("influence" %in% names(micmac))
  expect_true("exposure" %in% names(micmac))
  expect_true("quadrant" %in% names(micmac))

  expect_equal(nrow(micmac), nrow(net$nodes))
  expect_true(all(micmac$influence >= 0))
  expect_true(all(micmac$exposure >= 0))
  expect_true(all(micmac$quadrant %in% c("Influential", "Relay", "Dependent", "Autonomous")))
})

test_that("calculate_micmac handles network with no edges", {
  nodes <- data.frame(
    id = paste0("N", 1:5),
    label = paste("Node", 1:5),
    stringsAsFactors = FALSE
  )

  edges <- data.frame(
    from = character(0),
    to = character(0),
    polarity = character(0),
    strength = character(0),
    stringsAsFactors = FALSE
  )

  expect_warning(
    micmac <- calculate_micmac(nodes, edges),
    "Edges dataframe is empty"
  )

  expect_equal(nrow(micmac), 5)
  expect_true(all(micmac$influence == 0))
  expect_true(all(micmac$exposure == 0))
})

# ==============================================================================
# TEST: Adjacency Matrix
# ==============================================================================

test_that("create_numeric_adjacency_matrix works correctly", {
  net <- create_small_test_network()

  adj <- create_numeric_adjacency_matrix(net$nodes, net$edges)

  expect_true(is.matrix(adj))
  expect_equal(nrow(adj), nrow(net$nodes))
  expect_equal(ncol(adj), nrow(net$nodes))
  expect_true(all(adj %in% c(0, 1)))
  expect_true(!is.null(rownames(adj)))
  expect_true(!is.null(colnames(adj)))
})

# ==============================================================================
# TEST: Loop Classification
# ==============================================================================

test_that("classify_loop_type correctly identifies reinforcing loops", {
  # Even number of negatives = Reinforcing
  loop_nodes <- c("N1", "N2", "N3", "N4", "N1")

  edges <- data.frame(
    from = c("N1", "N2", "N3", "N4"),
    to = c("N2", "N3", "N4", "N1"),
    polarity = c("+", "-", "+", "-"),  # 2 negatives = even
    strength = "medium",
    stringsAsFactors = FALSE
  )

  type <- classify_loop_type(loop_nodes, edges)
  expect_equal(type, "Reinforcing")
})

test_that("classify_loop_type correctly identifies balancing loops", {
  # Odd number of negatives = Balancing
  loop_nodes <- c("N1", "N2", "N3", "N1")

  edges <- data.frame(
    from = c("N1", "N2", "N3"),
    to = c("N2", "N3", "N1"),
    polarity = c("+", "-", "+"),  # 1 negative = odd
    strength = "medium",
    stringsAsFactors = FALSE
  )

  type <- classify_loop_type(loop_nodes, edges)
  expect_equal(type, "Balancing")
})

test_that("classify_loop_type works with edge lookup table", {
  loop_nodes <- c("N1", "N2", "N3", "N1")

  edges <- data.frame(
    from = c("N1", "N2", "N3"),
    to = c("N2", "N3", "N1"),
    polarity = c("+", "+", "+"),
    strength = "medium",
    stringsAsFactors = FALSE
  )

  edge_lookup <- create_edge_lookup_table(edges)
  type <- classify_loop_type(loop_nodes, edge_lookup = edge_lookup)

  expect_equal(type, "Reinforcing")
})

# ==============================================================================
# TEST: Leverage Points
# ==============================================================================

test_that("identify_leverage_points returns correct structure", {
  net <- create_small_test_network()

  leverage <- identify_leverage_points(net$nodes, net$edges, top_n = 5)

  expect_s3_class(leverage, "data.frame")
  expect_true("Composite_Score" %in% names(leverage))
  expect_true("Betweenness" %in% names(leverage))
  expect_true("Eigenvector" %in% names(leverage))
  expect_true("PageRank" %in% names(leverage))

  expect_true(nrow(leverage) <= 5)

  # Check that results are sorted by composite score
  if (nrow(leverage) > 1) {
    expect_true(all(diff(leverage$Composite_Score) <= 0))
  }
})

test_that("identify_leverage_points handles empty network", {
  nodes <- data.frame(id = character(0), label = character(0), stringsAsFactors = FALSE)

  # Create empty igraph
  g <- make_empty_graph(n = 0, directed = TRUE)

  leverage <- identify_leverage_points(g, top_n = 5)

  expect_equal(nrow(leverage), 0)
})

# ==============================================================================
# TEST: Path Analysis
# ==============================================================================

test_that("find_shortest_path works correctly", {
  net <- create_small_test_network()

  path <- find_shortest_path(net$nodes, net$edges, "N1", "N5")

  expect_type(path, "character")
  expect_true(length(path) >= 2)
  expect_equal(path[1], "N1")
  expect_equal(path[length(path)], "N5")
})

test_that("find_shortest_path returns NULL for unreachable nodes", {
  nodes <- data.frame(
    id = c("N1", "N2", "N3", "N4"),
    label = c("Node 1", "Node 2", "Node 3", "Node 4"),
    stringsAsFactors = FALSE
  )

  # N1->N2, N3->N4, but no path from N1 to N4
  edges <- data.frame(
    from = c("N1", "N3"),
    to = c("N2", "N4"),
    polarity = c("+", "+"),
    strength = "medium",
    stringsAsFactors = FALSE
  )

  path <- find_shortest_path(nodes, edges, "N1", "N4")
  expect_null(path)
})

# ==============================================================================
# TEST: Neighborhood Analysis
# ==============================================================================

test_that("get_neighborhood works correctly", {
  net <- create_small_test_network()

  # Get immediate neighbors of N1
  neighbors <- get_neighborhood(net$nodes, net$edges, "N1", degree = 1)

  expect_type(neighbors, "character")
  expect_true("N1" %in% neighbors)  # Node itself is included
  expect_true(length(neighbors) >= 1)
})

# ==============================================================================
# TEST: Simplification Functions
# ==============================================================================

test_that("identify_exogenous_variables works correctly", {
  nodes <- data.frame(
    id = c("N1", "N2", "N3", "N4"),
    label = paste("Node", 1:4),
    stringsAsFactors = FALSE
  )

  # N1 is exogenous (only outputs, no inputs)
  edges <- data.frame(
    from = c("N1", "N2", "N3"),
    to = c("N2", "N3", "N4"),
    polarity = c("+", "+", "+"),
    strength = "medium",
    stringsAsFactors = FALSE
  )

  exogenous <- identify_exogenous_variables(nodes, edges)

  expect_type(exogenous, "character")
  expect_true("N1" %in% exogenous)
  expect_false("N2" %in% exogenous)
})

test_that("identify_siso_variables works correctly", {
  nodes <- data.frame(
    id = c("N1", "N2", "N3"),
    label = paste("Node", 1:3),
    stringsAsFactors = FALSE
  )

  # N2 is SISO (single input from N1, single output to N3)
  edges <- data.frame(
    from = c("N1", "N2"),
    to = c("N2", "N3"),
    polarity = c("+", "+"),
    strength = "medium",
    stringsAsFactors = FALSE
  )

  siso <- identify_siso_variables(nodes, edges)

  expect_s3_class(siso, "data.frame")
  expect_true("N2" %in% siso$id)
})

# ==============================================================================
# TEST: Community Detection
# ==============================================================================

test_that("detect_communities works correctly", {
  net <- create_small_test_network()

  # Note: Some algorithms like louvain require undirected graphs
  # Use edge_betweenness which works with directed graphs
  nodes_with_clusters <- detect_communities(net$nodes, net$edges, method = "edge_betweenness")

  expect_s3_class(nodes_with_clusters, "data.frame")
  expect_true("cluster" %in% names(nodes_with_clusters))
  expect_true(all(nodes_with_clusters$cluster >= 1))
})

# ==============================================================================
# PERFORMANCE BENCHMARKS
# ==============================================================================

cat("\n=== Network Analysis Functions - Performance Benchmarks ===\n\n")

benchmark_function <- function(name, func, expected_time) {
  cat(sprintf("%-50s", name))

  start_time <- Sys.time()
  tryCatch({
    result <- func()
    elapsed <- as.numeric(Sys.time() - start_time, units = "secs")

    status <- if (elapsed < expected_time) "✅ PASS" else "⚠️  SLOW"
    cat(sprintf("%s (%.3fs)\n", status, elapsed))

  }, warning = function(w) {
    elapsed <- as.numeric(Sys.time() - start_time, units = "secs")
    cat(sprintf("⚠️  WARN (%.3fs) - %s\n", elapsed, conditionMessage(w)))
  }, error = function(e) {
    elapsed <- as.numeric(Sys.time() - start_time, units = "secs")
    cat(sprintf("❌ ERROR (%.3fs) - %s\n", elapsed, conditionMessage(e)))
  })
}

net <- create_small_test_network()

benchmark_function("Network metrics calculation",
                   function() calculate_network_metrics(net$nodes, net$edges), 0.5)

benchmark_function("MICMAC analysis",
                   function() calculate_micmac(net$nodes, net$edges), 0.5)

benchmark_function("Leverage points identification",
                   function() identify_leverage_points(net$nodes, net$edges), 0.5)

benchmark_function("Shortest path finding",
                   function() find_shortest_path(net$nodes, net$edges, "N1", "N5"), 0.2)

benchmark_function("Community detection",
                   function() detect_communities(net$nodes, net$edges, method = "edge_betweenness"), 0.5)

benchmark_function("Loop classification (with lookup)",
                   function() {
                     edge_lookup <- create_edge_lookup_table(net$edges)
                     classify_loop_type(c("N1", "N2", "N3", "N1"), edge_lookup = edge_lookup)
                   }, 0.1)

cat("\n")
