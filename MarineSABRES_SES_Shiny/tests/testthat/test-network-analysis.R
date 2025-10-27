# test-network-analysis.R
# Unit tests for network analysis functions

library(testthat)
library(igraph)
library(tidygraph)

# Source the network analysis functions
source("../../functions/network_analysis.R", local = TRUE)

test_that("network creation from ISA data works", {
  skip_if_not(exists("build_network_from_isa"))

  # Create test ISA data
  test_isa <- list(
    nodes = data.frame(
      id = c("N1", "N2", "N3", "N4"),
      label = c("Node 1", "Node 2", "Node 3", "Node 4"),
      type = c("Driver", "Activity", "Pressure", "Ecosystem Service"),
      stringsAsFactors = FALSE
    ),
    edges = data.frame(
      from = c("N1", "N2", "N3"),
      to = c("N2", "N3", "N4"),
      link_type = c("positive", "negative", "positive"),
      stringsAsFactors = FALSE
    )
  )

  network <- build_network_from_isa(test_isa)

  expect_true(is.igraph(network) || is.tbl_graph(network))
})

test_that("centrality calculations work", {
  skip_if_not(exists("calculate_centrality"))

  # Create a simple test graph
  test_graph <- make_ring(5)
  V(test_graph)$name <- paste0("N", 1:5)

  centrality_results <- calculate_centrality(test_graph)

  expect_type(centrality_results, "list")
  expect_true("degree" %in% names(centrality_results) ||
              "betweenness" %in% names(centrality_results) ||
              "closeness" %in% names(centrality_results))

  # Check that results have same length as vertices
  for (metric in names(centrality_results)) {
    expect_equal(length(centrality_results[[metric]]), vcount(test_graph))
  }
})

test_that("feedback loop detection works", {
  skip_if_not(exists("detect_feedback_loops"))

  # Create a simple graph with cycles
  edges <- data.frame(
    from = c("A", "B", "C", "D"),
    to = c("B", "C", "A", "A"),
    stringsAsFactors = FALSE
  )

  test_graph <- graph_from_data_frame(edges, directed = TRUE)

  loops <- detect_feedback_loops(test_graph, max_length = 5)

  expect_true(is.data.frame(loops) || is.list(loops))

  # Should detect the A -> B -> C -> A loop
  if (is.data.frame(loops) && nrow(loops) > 0) {
    expect_true(any(grepl("A", loops$path) & grepl("B", loops$path) & grepl("C", loops$path)))
  }
})

test_that("loop type classification works", {
  skip_if_not(exists("classify_loop_type"))

  # Test reinforcing loop (even number of negative links)
  loop_info1 <- list(
    path = c("A", "B", "C", "A"),
    edge_types = c("+", "-", "-")
  )

  type1 <- classify_loop_type(loop_info1)
  expect_equal(type1, "reinforcing")

  # Test balancing loop (odd number of negative links)
  loop_info2 <- list(
    path = c("A", "B", "C", "A"),
    edge_types = c("+", "-", "+")
  )

  type2 <- classify_loop_type(loop_info2)
  expect_equal(type2, "balancing")
})

test_that("network metrics calculation works", {
  skip_if_not(exists("calculate_network_metrics"))

  # Create test graph
  test_graph <- make_graph(~ A-+B-+C-+A, D-+B)

  metrics <- calculate_network_metrics(test_graph)

  expect_type(metrics, "list")

  # Check for expected metrics
  expected_metrics <- c("nodes", "edges", "density", "diameter", "avg_path_length")

  for (metric in expected_metrics) {
    if (metric %in% names(metrics)) {
      expect_true(is.numeric(metrics[[metric]]) || is.integer(metrics[[metric]]))
    }
  }
})

test_that("network simplification works", {
  skip_if_not(exists("simplify_network"))

  # Create test graph with some low-centrality nodes
  test_graph <- make_star(10, mode = "undirected")
  V(test_graph)$name <- paste0("N", 1:10)

  simplified <- simplify_network(test_graph, threshold = 0.5)

  expect_true(is.igraph(simplified))
  expect_true(vcount(simplified) <= vcount(test_graph))
})

test_that("pathway analysis works", {
  skip_if_not(exists("find_pathways"))

  # Create test graph
  edges <- data.frame(
    from = c("A", "B", "C", "D", "E"),
    to = c("B", "C", "D", "E", "F"),
    stringsAsFactors = FALSE
  )

  test_graph <- graph_from_data_frame(edges, directed = TRUE)

  pathways <- find_pathways(test_graph, from = "A", to = "F")

  expect_true(is.list(pathways) || is.data.frame(pathways))
})

test_that("node importance ranking works", {
  skip_if_not(exists("rank_node_importance"))

  # Create test graph
  test_graph <- make_graph(~ A-+B-+C-+D, A-+D, B-+D)

  ranking <- rank_node_importance(test_graph)

  expect_true(is.data.frame(ranking) || is.vector(ranking))

  if (is.data.frame(ranking)) {
    expect_true("node" %in% names(ranking) || "importance" %in% names(ranking))
  }
})
