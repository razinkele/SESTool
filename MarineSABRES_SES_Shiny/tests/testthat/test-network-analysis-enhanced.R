# tests/testthat/test-network-analysis-enhanced.R
# Tests for enhanced network analysis functions with error handling

library(testthat)
library(igraph)

# Source enhanced functions
source("../../functions/network_analysis_enhanced.R", local = TRUE)

# ============================================================================
# VALIDATION UTILITIES TESTS
# ============================================================================

test_that("validate_nodes catches NULL input", {
  expect_error(
    validate_nodes(NULL),
    "nodes is NULL"
  )
})

test_that("validate_nodes catches non-dataframe input", {
  expect_error(
    validate_nodes(list(a = 1, b = 2)),
    "nodes must be dataframe"
  )
})

test_that("validate_nodes catches missing id column", {
  nodes <- data.frame(name = c("A", "B"), value = c(1, 2))
  expect_error(
    validate_nodes(nodes),
    "Missing required columns: id"
  )
})

test_that("validate_nodes catches missing name column", {
  nodes <- data.frame(id = c("A", "B"), value = c(1, 2))
  expect_error(
    validate_nodes(nodes),
    "Missing required columns: name"
  )
})

test_that("validate_nodes accepts valid nodes dataframe", {
  nodes <- data.frame(
    id = c("A", "B", "C"),
    name = c("Node A", "Node B", "Node C"),
    stringsAsFactors = FALSE
  )
  expect_true(validate_nodes(nodes))
})

test_that("validate_edges catches NULL input", {
  expect_error(
    validate_edges(NULL),
    "edges is NULL"
  )
})

test_that("validate_edges catches non-dataframe input", {
  expect_error(
    validate_edges(c("A", "B")),
    "edges must be dataframe"
  )
})

test_that("validate_edges catches missing required columns", {
  edges <- data.frame(source = c("A"), target = c("B"))
  expect_error(
    validate_edges(edges, c("from", "to")),
    "Missing required columns: from, to"
  )
})

test_that("validate_edges accepts valid edges dataframe", {
  edges <- data.frame(
    from = c("A", "B"),
    to = c("B", "C"),
    stringsAsFactors = FALSE
  )
  expect_true(validate_edges(edges, c("from", "to")))
})

test_that("validate_igraph catches NULL input", {
  expect_error(
    validate_igraph(NULL),
    "graph is NULL"
  )
})

test_that("validate_igraph catches non-igraph input", {
  expect_error(
    validate_igraph(list(nodes = 1, edges = 2)),
    "graph must be igraph object"
  )
})

test_that("validate_igraph accepts valid igraph", {
  g <- make_empty_graph(n = 3)
  expect_true(validate_igraph(g))
})

# ============================================================================
# CREATE IGRAPH FROM DATA - ERROR HANDLING TESTS
# ============================================================================

test_that("create_igraph_from_data_safe handles NULL nodes", {
  edges <- data.frame(from = "A", to = "B")
  result <- create_igraph_from_data_safe(NULL, edges)
  expect_null(result)
})

test_that("create_igraph_from_data_safe handles NULL edges", {
  nodes <- data.frame(id = "A", name = "Node A")
  result <- create_igraph_from_data_safe(nodes, NULL)
  expect_null(result)
})

test_that("create_igraph_from_data_safe handles invalid nodes structure", {
  nodes <- data.frame(bad_col = "A")
  edges <- data.frame(from = "A", to = "B")
  result <- create_igraph_from_data_safe(nodes, edges)
  expect_null(result)
})

test_that("create_igraph_from_data_safe handles invalid edges structure", {
  nodes <- data.frame(id = c("A", "B"), name = c("A", "B"))
  edges <- data.frame(source = "A", target = "B")
  result <- create_igraph_from_data_safe(nodes, edges)
  expect_null(result)
})

test_that("create_igraph_from_data_safe handles edges referencing non-existent nodes", {
  nodes <- data.frame(
    id = c("A", "B"),
    name = c("Node A", "Node B"),
    stringsAsFactors = FALSE
  )
  edges <- data.frame(
    from = c("A", "C"),  # C doesn't exist
    to = c("B", "D"),    # D doesn't exist
    polarity = c("+", "+"),
    strength = c(1, 1),
    stringsAsFactors = FALSE
  )

  result <- create_igraph_from_data_safe(nodes, edges)

  # Should still create graph, but with only valid edges
  expect_false(is.null(result))
  expect_s3_class(result, "igraph")
  expect_equal(vcount(result), 2)
  expect_equal(ecount(result), 1)  # Only A->B edge should remain
})

test_that("create_igraph_from_data_safe succeeds with valid data", {
  nodes <- data.frame(
    id = c("A", "B", "C"),
    name = c("Node A", "Node B", "Node C"),
    stringsAsFactors = FALSE
  )
  edges <- data.frame(
    from = c("A", "B"),
    to = c("B", "C"),
    polarity = c("+", "-"),
    strength = c(1, 2),
    stringsAsFactors = FALSE
  )

  result <- create_igraph_from_data_safe(nodes, edges)

  expect_false(is.null(result))
  expect_s3_class(result, "igraph")
  expect_equal(vcount(result), 3)
  expect_equal(ecount(result), 2)
})

test_that("create_igraph_from_data_safe handles empty graph", {
  nodes <- data.frame(
    id = character(),
    name = character(),
    stringsAsFactors = FALSE
  )
  edges <- data.frame(
    from = character(),
    to = character(),
    stringsAsFactors = FALSE
  )

  result <- create_igraph_from_data_safe(nodes, edges)
  expect_null(result)  # Empty graph should return NULL
})

# ============================================================================
# CALCULATE NETWORK METRICS - ERROR HANDLING TESTS
# ============================================================================

test_that("calculate_network_metrics_safe handles NULL nodes", {
  result <- calculate_network_metrics_safe(NULL, NULL)
  expect_null(result)
})

test_that("calculate_network_metrics_safe handles invalid nodes", {
  nodes <- data.frame(bad = "data")
  edges <- data.frame(from = "A", to = "B")
  result <- calculate_network_metrics_safe(nodes, edges)
  expect_null(result)
})

test_that("calculate_network_metrics_safe handles empty graph", {
  nodes <- data.frame(id = character(), name = character())
  edges <- data.frame(from = character(), to = character())
  result <- calculate_network_metrics_safe(nodes, edges)
  expect_null(result)
})

test_that("calculate_network_metrics_safe works with igraph input", {
  g <- make_ring(5)
  result <- calculate_network_metrics_safe(g)

  expect_false(is.null(result))
  expect_true(is.list(result))
  expect_true("density" %in% names(result))
  expect_true("avg_degree" %in% names(result))
})

test_that("calculate_network_metrics_safe works with nodes/edges input", {
  nodes <- data.frame(
    id = c("A", "B", "C"),
    name = c("Node A", "Node B", "Node C"),
    stringsAsFactors = FALSE
  )
  edges <- data.frame(
    from = c("A", "B"),
    to = c("B", "C"),
    polarity = c("+", "+"),
    strength = c(1, 1),
    stringsAsFactors = FALSE
  )

  result <- calculate_network_metrics_safe(nodes, edges)

  expect_false(is.null(result))
  expect_true(is.list(result))
  expect_true("density" %in% names(result))
  expect_true("avg_degree" %in% names(result))
  expect_true("num_nodes" %in% names(result))
  expect_true("num_edges" %in% names(result))

  expect_equal(result$num_nodes, 3)
  expect_equal(result$num_edges, 2)
})

test_that("calculate_network_metrics_safe handles disconnected graph", {
  nodes <- data.frame(
    id = c("A", "B", "C", "D"),
    name = c("A", "B", "C", "D"),
    stringsAsFactors = FALSE
  )
  edges <- data.frame(
    from = c("A"),
    to = c("B"),
    polarity = c("+"),
    strength = c(1),
    stringsAsFactors = FALSE
  )

  result <- calculate_network_metrics_safe(nodes, edges)

  expect_false(is.null(result))
  expect_true(result$components > 1)  # Should detect multiple components
})

test_that("calculate_network_metrics_safe returns defaults for failed individual metrics", {
  # Create minimal graph that might cause some metrics to fail
  nodes <- data.frame(
    id = c("A"),
    name = c("Node A"),
    stringsAsFactors = FALSE
  )
  edges <- data.frame(
    from = character(),
    to = character(),
    polarity = character(),
    strength = numeric(),
    stringsAsFactors = FALSE
  )

  result <- calculate_network_metrics_safe(nodes, edges)

  # Single node, no edges - some metrics should use defaults
  expect_false(is.null(result))
  expect_equal(result$num_nodes, 1)
  expect_equal(result$num_edges, 0)
})

# ============================================================================
# MICMAC ANALYSIS - ERROR HANDLING TESTS
# ============================================================================

test_that("calculate_micmac_safe handles NULL inputs", {
  result <- calculate_micmac_safe(NULL, NULL)
  expect_null(result)
})

test_that("calculate_micmac_safe handles invalid nodes", {
  nodes <- data.frame(bad = "data")
  edges <- data.frame(from = "A", to = "B")
  result <- calculate_micmac_safe(nodes, edges)
  expect_null(result)
})

test_that("calculate_micmac_safe handles empty graph", {
  nodes <- data.frame(id = character(), name = character())
  edges <- data.frame(from = character(), to = character())
  result <- calculate_micmac_safe(nodes, edges)
  expect_null(result)
})

test_that("calculate_micmac_safe succeeds with valid data", {
  nodes <- data.frame(
    id = c("A", "B", "C"),
    name = c("Node A", "Node B", "Node C"),
    stringsAsFactors = FALSE
  )
  edges <- data.frame(
    from = c("A", "B", "C"),
    to = c("B", "C", "A"),
    polarity = c("+", "+", "+"),
    strength = c(1, 1, 1),
    stringsAsFactors = FALSE
  )

  result <- calculate_micmac_safe(nodes, edges)

  expect_false(is.null(result))
  expect_true(is.data.frame(result))
  expect_true("id" %in% names(result))
  expect_true("influence" %in% names(result))
  expect_true("dependence" %in% names(result))
  expect_equal(nrow(result), 3)
})

test_that("create_numeric_adjacency_matrix_safe handles invalid inputs", {
  result <- create_numeric_adjacency_matrix_safe(NULL, NULL)
  expect_null(result)
})

test_that("create_numeric_adjacency_matrix_safe succeeds with valid data", {
  nodes <- data.frame(
    id = c("A", "B"),
    name = c("Node A", "Node B"),
    stringsAsFactors = FALSE
  )
  edges <- data.frame(
    from = c("A"),
    to = c("B"),
    polarity = c("+"),
    strength = c(2),
    stringsAsFactors = FALSE
  )

  result <- create_numeric_adjacency_matrix_safe(nodes, edges)

  expect_false(is.null(result))
  expect_true(is.matrix(result))
  expect_equal(dim(result), c(2, 2))
  expect_equal(result["A", "B"], 2)
})

# ============================================================================
# CYCLE DETECTION - ERROR HANDLING TESTS
# ============================================================================

test_that("find_all_cycles_safe handles NULL inputs", {
  result <- find_all_cycles_safe(NULL, NULL)
  expect_true(is.list(result))
  expect_length(result, 0)
})

test_that("find_all_cycles_safe handles invalid nodes", {
  nodes <- data.frame(bad = "data")
  edges <- data.frame(from = "A", to = "B")
  result <- find_all_cycles_safe(nodes, edges)
  expect_true(is.list(result))
  expect_length(result, 0)
})

test_that("find_all_cycles_safe handles graph with no cycles", {
  nodes <- data.frame(
    id = c("A", "B", "C"),
    name = c("A", "B", "C"),
    stringsAsFactors = FALSE
  )
  edges <- data.frame(
    from = c("A", "B"),
    to = c("B", "C"),
    polarity = c("+", "+"),
    strength = c(1, 1),
    stringsAsFactors = FALSE
  )

  result <- find_all_cycles_safe(nodes, edges)

  expect_true(is.list(result))
  expect_length(result, 0)
})

test_that("find_all_cycles_safe detects simple cycle", {
  nodes <- data.frame(
    id = c("A", "B", "C"),
    name = c("A", "B", "C"),
    stringsAsFactors = FALSE
  )
  edges <- data.frame(
    from = c("A", "B", "C"),
    to = c("B", "C", "A"),
    polarity = c("+", "+", "+"),
    strength = c(1, 1, 1),
    stringsAsFactors = FALSE
  )

  result <- find_all_cycles_safe(nodes, edges)

  expect_true(is.list(result))
  expect_true(length(result) > 0)

  # Check first cycle structure
  expect_true("nodes" %in% names(result[[1]]))
  expect_equal(length(result[[1]]$nodes), 3)
})

test_that("find_all_cycles_safe respects max_length parameter", {
  # Create a long chain: A->B->C->D->E->A
  nodes <- data.frame(
    id = c("A", "B", "C", "D", "E"),
    name = c("A", "B", "C", "D", "E"),
    stringsAsFactors = FALSE
  )
  edges <- data.frame(
    from = c("A", "B", "C", "D", "E"),
    to = c("B", "C", "D", "E", "A"),
    polarity = rep("+", 5),
    strength = rep(1, 5),
    stringsAsFactors = FALSE
  )

  # With max_length = 3, should not find the 5-node cycle
  result_short <- find_all_cycles_safe(nodes, edges, max_length = 3)
  expect_length(result_short, 0)

  # With max_length = 10, should find it
  result_long <- find_all_cycles_safe(nodes, edges, max_length = 10)
  expect_true(length(result_long) > 0)
})

test_that("classify_loop_type_safe handles NULL input", {
  result <- classify_loop_type_safe(NULL)
  expect_null(result)
})

test_that("classify_loop_type_safe handles invalid structure", {
  bad_loop <- list(bad = "structure")
  result <- classify_loop_type_safe(bad_loop)
  expect_null(result)
})

test_that("classify_loop_type_safe classifies reinforcing loop", {
  loop <- list(
    nodes = c("A", "B", "C"),
    polarities = c("+", "+", "+")  # All positive = reinforcing
  )

  edges <- data.frame(
    from = c("A", "B", "C"),
    to = c("B", "C", "A"),
    polarity = c("+", "+", "+"),
    stringsAsFactors = FALSE
  )

  result <- classify_loop_type_safe(loop, edges)
  expect_false(is.null(result))
  expect_equal(result, "R")
})

test_that("classify_loop_type_safe classifies balancing loop", {
  loop <- list(
    nodes = c("A", "B", "C"),
    polarities = c("+", "-", "+")  # Odd number of negatives = balancing
  )

  edges <- data.frame(
    from = c("A", "B", "C"),
    to = c("B", "C", "A"),
    polarity = c("+", "-", "+"),
    stringsAsFactors = FALSE
  )

  result <- classify_loop_type_safe(loop, edges)
  expect_false(is.null(result))
  expect_equal(result, "B")
})

# ============================================================================
# INTEGRATION TESTS
# ============================================================================

test_that("Complete network analysis workflow with error recovery", {
  # Start with valid data
  nodes <- data.frame(
    id = c("A", "B", "C", "D"),
    name = c("Driver", "Pressure", "State", "Response"),
    stringsAsFactors = FALSE
  )

  edges <- data.frame(
    from = c("A", "B", "C"),
    to = c("B", "C", "D"),
    polarity = c("+", "-", "+"),
    strength = c(1, 2, 1),
    stringsAsFactors = FALSE
  )

  # Calculate metrics
  metrics <- calculate_network_metrics_safe(nodes, edges)
  expect_false(is.null(metrics))
  expect_equal(metrics$num_nodes, 4)

  # MICMAC analysis
  micmac <- calculate_micmac_safe(nodes, edges)
  expect_false(is.null(micmac))
  expect_equal(nrow(micmac), 4)

  # Try with invalid edge added
  bad_edges <- rbind(
    edges,
    data.frame(from = "X", to = "Y", polarity = "+", strength = 1)
  )

  # Should still work, filtering bad edge
  result <- create_igraph_from_data_safe(nodes, bad_edges)
  expect_false(is.null(result))
  expect_equal(vcount(result), 4)
  expect_equal(ecount(result), 3)  # Only valid edges
})

test_that("Error handling preserves partial results in analysis pipeline", {
  nodes <- data.frame(
    id = c("A", "B"),
    name = c("Node A", "Node B"),
    stringsAsFactors = FALSE
  )

  # Valid edges for basic metrics
  edges <- data.frame(
    from = c("A"),
    to = c("B"),
    polarity = c("+"),
    strength = c(1),
    stringsAsFactors = FALSE
  )

  # Metrics should succeed
  metrics <- calculate_network_metrics_safe(nodes, edges)
  expect_false(is.null(metrics))

  # Cycle detection should succeed (no cycles)
  cycles <- find_all_cycles_safe(nodes, edges)
  expect_true(is.list(cycles))
  expect_length(cycles, 0)

  # Even if one analysis fails, others should complete
  expect_true(TRUE)  # Made it through without crashing
})
