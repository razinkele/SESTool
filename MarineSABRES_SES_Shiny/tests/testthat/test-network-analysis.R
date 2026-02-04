# tests/testthat/test-network-analysis.R
# Edge-case tests for network analysis functions

# Helper: source network analysis if not already loaded
if (!exists("calculate_network_metrics")) {
  # Try to load necessary dependencies
  tryCatch({
    suppressPackageStartupMessages({
      library(igraph)
      library(dplyr)
    })
    source(file.path("..", "..", "functions", "network_analysis.R"), local = TRUE)
  }, error = function(e) {
    skip(paste("Cannot load network_analysis.R:", e$message))
  })
}

# ============================================================================
# create_numeric_adjacency_matrix tests
# ============================================================================

test_that("create_numeric_adjacency_matrix handles empty edges", {
  nodes <- data.frame(id = c("A", "B", "C"), stringsAsFactors = FALSE)
  edges <- data.frame(from = character(0), to = character(0), stringsAsFactors = FALSE)

  adj <- create_numeric_adjacency_matrix(nodes, edges)

  expect_equal(nrow(adj), 3)
  expect_equal(ncol(adj), 3)
  expect_equal(sum(adj), 0)
})

test_that("create_numeric_adjacency_matrix handles single node", {
  nodes <- data.frame(id = "A", stringsAsFactors = FALSE)
  edges <- data.frame(from = character(0), to = character(0), stringsAsFactors = FALSE)

  adj <- create_numeric_adjacency_matrix(nodes, edges)

  expect_equal(nrow(adj), 1)
  expect_equal(ncol(adj), 1)
  expect_equal(adj[1, 1], 0)
})

test_that("create_numeric_adjacency_matrix skips edges with non-existent nodes", {
  nodes <- data.frame(id = c("A", "B"), stringsAsFactors = FALSE)
  edges <- data.frame(
    from = c("A", "C"),
    to = c("B", "A"),
    stringsAsFactors = FALSE
  )

  expect_warning(
    adj <- create_numeric_adjacency_matrix(nodes, edges),
    "non-existent"
  )
  expect_equal(adj["A", "B"], 1)
})

test_that("create_numeric_adjacency_matrix handles self-loops", {
  nodes <- data.frame(id = c("A", "B"), stringsAsFactors = FALSE)
  edges <- data.frame(
    from = c("A", "A"),
    to = c("B", "A"),
    stringsAsFactors = FALSE
  )

  adj <- create_numeric_adjacency_matrix(nodes, edges)
  expect_equal(adj["A", "A"], 1)
  expect_equal(adj["A", "B"], 1)
})

# ============================================================================
# calculate_network_metrics tests
# ============================================================================

test_that("calculate_network_metrics handles disconnected graph", {
  # Create a graph with two disconnected components
  nodes <- data.frame(
    id = c("A", "B", "C", "D"),
    label = c("A", "B", "C", "D"),
    stringsAsFactors = FALSE
  )
  edges <- data.frame(
    from = c("A", "C"),
    to = c("B", "D"),
    polarity = c("+", "+"),
    stringsAsFactors = FALSE
  )

  metrics <- calculate_network_metrics(nodes, edges)

  expect_equal(metrics$nodes, 4)
  expect_equal(metrics$edges, 2)
  # Diameter should come from largest component, not crash
  expect_true(is.numeric(metrics$diameter))
  expect_true(metrics$diameter >= 0)
  # Closeness should not contain Inf
  expect_false(any(is.infinite(metrics$closeness)))
})

test_that("calculate_network_metrics handles graph with isolated nodes", {
  # Graph with some connected nodes and one isolated
  g <- igraph::make_graph(c("A", "B", "B", "C"), directed = TRUE)
  g <- g + igraph::vertices("D")  # Isolated node

  metrics <- calculate_network_metrics(g)

  expect_equal(metrics$nodes, 4)
  expect_false(any(is.infinite(metrics$closeness)))
})

test_that("calculate_network_metrics works on connected graph", {
  nodes <- data.frame(
    id = c("A", "B", "C"),
    label = c("A", "B", "C"),
    stringsAsFactors = FALSE
  )
  edges <- data.frame(
    from = c("A", "B", "C"),
    to = c("B", "C", "A"),
    polarity = c("+", "+", "+"),
    stringsAsFactors = FALSE
  )

  metrics <- calculate_network_metrics(nodes, edges)

  expect_equal(metrics$nodes, 3)
  expect_equal(metrics$edges, 3)
  expect_true(metrics$diameter > 0)
})

test_that("calculate_network_metrics errors on empty edge set", {
  nodes <- data.frame(
    id = c("A", "B"),
    label = c("A", "B"),
    stringsAsFactors = FALSE
  )
  edges <- data.frame(
    from = character(0),
    to = character(0),
    stringsAsFactors = FALSE
  )

  expect_error(
    calculate_network_metrics(nodes, edges),
    "No valid edges found"
  )
})

# ============================================================================
# classify_loop_type tests
# ============================================================================

test_that("classify_loop_type identifies reinforcing loops (even negatives)", {
  # Zero negatives = reinforcing
  result <- classify_loop_type(list(edge_types = c("+", "+", "+")))
  expect_equal(result, "Reinforcing")

  # Two negatives = reinforcing
  result <- classify_loop_type(list(edge_types = c("-", "-", "+")))
  expect_equal(result, "Reinforcing")
})

test_that("classify_loop_type identifies balancing loops (odd negatives)", {
  # One negative = balancing
  result <- classify_loop_type(list(edge_types = c("+", "-", "+")))
  expect_equal(result, "Balancing")

  # Three negatives = balancing
  result <- classify_loop_type(list(edge_types = c("-", "-", "-")))
  expect_equal(result, "Balancing")
})

test_that("classify_loop_type returns NA for NULL edge_types", {
  result <- classify_loop_type(list(edge_types = NULL))
  expect_true(is.na(result))
})

test_that("classify_loop_type works with node IDs and edge lookup", {
  edges <- data.frame(
    from = c("A", "B", "C"),
    to = c("B", "C", "A"),
    polarity = c("+", "-", "+"),
    stringsAsFactors = FALSE
  )
  lookup <- create_edge_lookup_table(edges)

  result <- classify_loop_type(c("A", "B", "C"), edge_lookup = lookup)
  expect_equal(result, "Balancing")
})

# ============================================================================
# normalize_cycle tests
# ============================================================================

test_that("normalize_cycle rotates to start from minimum", {
  cycle <- c(3, 1, 2)
  normalized <- normalize_cycle(cycle)
  expect_equal(normalized[1], 1)
})

test_that("normalize_cycle handles already-normalized cycle", {
  cycle <- c(1, 2, 3)
  normalized <- normalize_cycle(cycle)
  expect_equal(normalized, c(1, 2, 3))
})

test_that("normalize_cycle preserves order after rotation", {
  cycle <- c(4, 5, 2, 3)
  normalized <- normalize_cycle(cycle)
  expect_equal(normalized[1], 2)
  expect_equal(normalized, c(2, 3, 4, 5))
})

# ============================================================================
# find_all_cycles tests
# ============================================================================

test_that("find_all_cycles finds cycles in simple graph", {
  nodes <- data.frame(
    id = c("A", "B", "C"),
    label = c("A", "B", "C"),
    stringsAsFactors = FALSE
  )
  edges <- data.frame(
    from = c("A", "B", "C"),
    to = c("B", "C", "A"),
    polarity = c("+", "+", "+"),
    stringsAsFactors = FALSE
  )

  cycles <- find_all_cycles(nodes, edges, max_length = 5)
  expect_true(length(cycles) >= 1)
})

test_that("find_all_cycles returns empty for acyclic graph", {
  nodes <- data.frame(
    id = c("A", "B", "C"),
    label = c("A", "B", "C"),
    stringsAsFactors = FALSE
  )
  edges <- data.frame(
    from = c("A", "B"),
    to = c("B", "C"),
    polarity = c("+", "+"),
    stringsAsFactors = FALSE
  )

  cycles <- find_all_cycles(nodes, edges, max_length = 5)
  expect_equal(length(cycles), 0)
})

test_that("find_all_cycles respects max_cycles limit", {
  # Create a dense graph that has many cycles
  nodes <- data.frame(
    id = paste0("N", 1:6),
    label = paste0("Node", 1:6),
    stringsAsFactors = FALSE
  )
  # Create a complete directed graph (many cycles)
  edges <- expand.grid(from = nodes$id, to = nodes$id, stringsAsFactors = FALSE)
  edges <- edges[edges$from != edges$to, ]
  edges$polarity <- "+"

  cycles <- find_all_cycles(nodes, edges, max_length = 6, max_cycles = 5)
  expect_lte(length(cycles), 5)
})

test_that("find_all_cycles handles graph with self-loops only", {
  nodes <- data.frame(
    id = c("A", "B"),
    label = c("A", "B"),
    stringsAsFactors = FALSE
  )
  edges <- data.frame(
    from = c("A"),
    to = c("A"),
    polarity = c("+"),
    stringsAsFactors = FALSE
  )

  # Self-loops do not form strongly connected components of size > 1
  # so the cycle finder should return empty or handle gracefully
  cycles <- find_all_cycles(nodes, edges, max_length = 5)
  expect_true(is.list(cycles))
})

# ============================================================================
# create_igraph_from_data tests
# ============================================================================

test_that("create_igraph_from_data handles empty edges gracefully", {
  nodes <- data.frame(
    id = c("A", "B"),
    label = c("A", "B"),
    stringsAsFactors = FALSE
  )
  edges <- data.frame(
    from = character(0),
    to = character(0),
    stringsAsFactors = FALSE
  )

  g <- create_igraph_from_data(nodes, edges)
  expect_equal(igraph::vcount(g), 2)
  expect_equal(igraph::ecount(g), 0)
})

test_that("create_igraph_from_data warns about invalid edges", {
  nodes <- data.frame(
    id = c("A", "B"),
    label = c("A", "B"),
    stringsAsFactors = FALSE
  )
  edges <- data.frame(
    from = c("A", "X"),
    to = c("B", "Y"),
    stringsAsFactors = FALSE
  )

  expect_warning(
    g <- create_igraph_from_data(nodes, edges),
    "non-existent"
  )
  expect_equal(igraph::ecount(g), 1)
})

test_that("create_igraph_from_data preserves edge attributes", {
  nodes <- data.frame(
    id = c("A", "B"),
    label = c("A", "B"),
    stringsAsFactors = FALSE
  )
  edges <- data.frame(
    from = c("A"),
    to = c("B"),
    polarity = c("+"),
    strength = c("strong"),
    stringsAsFactors = FALSE
  )

  g <- create_igraph_from_data(nodes, edges)
  expect_equal(igraph::ecount(g), 1)
  expect_equal(igraph::edge_attr(g, "polarity"), "+")
  expect_equal(igraph::edge_attr(g, "strength"), "strong")
})

test_that("create_igraph_from_data creates directed graph", {
  nodes <- data.frame(
    id = c("A", "B"),
    label = c("A", "B"),
    stringsAsFactors = FALSE
  )
  edges <- data.frame(
    from = c("A"),
    to = c("B"),
    stringsAsFactors = FALSE
  )

  g <- create_igraph_from_data(nodes, edges)
  expect_true(igraph::is_directed(g))
})

# ============================================================================
# is_valid_dapsirwrm_transition tests
# ============================================================================

test_that("is_valid_dapsirwrm_transition accepts forward transitions", {
  expect_true(is_valid_dapsirwrm_transition("driver", "activity"))
  expect_true(is_valid_dapsirwrm_transition("activity", "pressure"))
  expect_true(is_valid_dapsirwrm_transition("pressure", "state"))
  expect_true(is_valid_dapsirwrm_transition("welfare", "response"))
})

test_that("is_valid_dapsirwrm_transition accepts feedback transitions", {
  expect_true(is_valid_dapsirwrm_transition("response", "driver"))
  expect_true(is_valid_dapsirwrm_transition("response", "activity"))
  expect_true(is_valid_dapsirwrm_transition("response", "pressure"))
})

test_that("is_valid_dapsirwrm_transition rejects invalid transitions", {
  expect_false(is_valid_dapsirwrm_transition("driver", "response"))
  expect_false(is_valid_dapsirwrm_transition("pressure", "driver"))
  expect_false(is_valid_dapsirwrm_transition("impact", "activity"))
})

test_that("is_valid_dapsirwrm_transition handles case and whitespace", {
  expect_true(is_valid_dapsirwrm_transition("Driver", "Activity"))
  expect_true(is_valid_dapsirwrm_transition("  driver  ", "  activity  "))
  expect_true(is_valid_dapsirwrm_transition("DRIVER", "ACTIVITY"))
})

# ============================================================================
# calculate_micmac tests
# ============================================================================

test_that("calculate_micmac handles empty edges", {
  nodes <- data.frame(
    id = c("A", "B", "C"),
    stringsAsFactors = FALSE
  )
  edges <- data.frame(
    from = character(0),
    to = character(0),
    stringsAsFactors = FALSE
  )

  result <- calculate_micmac(nodes, edges)
  expect_equal(nrow(result), 3)
  expect_true(all(result$influence == 0))
  expect_true(all(result$exposure == 0))
  expect_true(all(result$quadrant == "Autonomous"))
})

test_that("calculate_micmac computes influence and exposure", {
  nodes <- data.frame(
    id = c("A", "B", "C"),
    stringsAsFactors = FALSE
  )
  edges <- data.frame(
    from = c("A", "A", "B"),
    to = c("B", "C", "C"),
    stringsAsFactors = FALSE
  )

  result <- calculate_micmac(nodes, edges)
  expect_equal(nrow(result), 3)
  # A has outgoing edges to B and C, so influence > 0
  expect_true(result$influence[result$node_id == "A"] > 0)
  # C has incoming edges from A and B, so exposure > 0
  expect_true(result$exposure[result$node_id == "C"] > 0)
})

test_that("calculate_micmac errors on empty nodes", {
  nodes <- data.frame(id = character(0), stringsAsFactors = FALSE)
  edges <- data.frame(from = character(0), to = character(0), stringsAsFactors = FALSE)

  expect_error(calculate_micmac(nodes, edges))
})

# ============================================================================
# identify_leverage_points tests
# ============================================================================

test_that("identify_leverage_points returns correct structure", {
  nodes <- data.frame(
    id = c("A", "B", "C"),
    label = c("A", "B", "C"),
    stringsAsFactors = FALSE
  )
  edges <- data.frame(
    from = c("A", "B", "C"),
    to = c("B", "C", "A"),
    stringsAsFactors = FALSE
  )

  result <- identify_leverage_points(nodes, edges, top_n = 2)
  expect_true(is.data.frame(result))
  expect_lte(nrow(result), 2)
  expect_true("Composite_Score" %in% names(result))
  expect_true("Betweenness" %in% names(result))
  expect_true("PageRank" %in% names(result))
})

test_that("identify_leverage_points handles igraph input", {
  g <- igraph::make_ring(5, directed = TRUE)
  igraph::V(g)$name <- paste0("N", 1:5)
  igraph::V(g)$label <- paste0("Node", 1:5)

  result <- identify_leverage_points(g, top_n = 3)
  expect_true(is.data.frame(result))
  expect_lte(nrow(result), 3)
})

test_that("identify_leverage_points returns empty df for empty graph", {
  g <- igraph::make_empty_graph(0)
  result <- identify_leverage_points(g)
  expect_equal(nrow(result), 0)
})

# ============================================================================
# simplify_network tests
# ============================================================================

test_that("simplify_network returns graph unchanged when threshold is NULL", {
  g <- igraph::make_ring(5, directed = TRUE)
  result <- simplify_network(g, threshold = NULL)
  expect_equal(igraph::vcount(result), 5)
})

test_that("simplify_network removes low-degree nodes", {
  # Create a star graph where center has highest degree
  g <- igraph::make_star(6, mode = "undirected")
  igraph::V(g)$name <- paste0("N", 1:6)

  # With a high threshold, only the hub should remain
  result <- simplify_network(g, threshold = 0.9)
  expect_lt(igraph::vcount(result), igraph::vcount(g))
})

test_that("simplify_network handles non-igraph input", {
  result <- simplify_network("not a graph", threshold = 0.5)
  expect_equal(result, "not a graph")
})

# ============================================================================
# create_edge_lookup_table tests
# ============================================================================

test_that("create_edge_lookup_table creates correct lookup", {
  edges <- data.frame(
    from = c("A", "B"),
    to = c("B", "C"),
    polarity = c("+", "-"),
    stringsAsFactors = FALSE
  )

  lookup <- create_edge_lookup_table(edges)
  expect_equal(lookup[["A->B"]], "+")
  expect_equal(lookup[["B->C"]], "-")
  expect_null(lookup[["C->A"]])
})

# ============================================================================
# is_duplicate_cycle tests
# ============================================================================

test_that("is_duplicate_cycle detects duplicates with rotation", {
  existing <- list(c(1, 2, 3))

  # Same cycle, rotated
  expect_true(is_duplicate_cycle(c(2, 3, 1), existing))
  expect_true(is_duplicate_cycle(c(3, 1, 2), existing))

  # Different cycle
  expect_false(is_duplicate_cycle(c(1, 3, 2), existing))
})

test_that("is_duplicate_cycle returns FALSE for empty list", {
  expect_false(is_duplicate_cycle(c(1, 2, 3), list()))
})

# ============================================================================
# rank_node_importance tests
# ============================================================================

test_that("rank_node_importance returns dataframe with correct columns", {
  g <- igraph::make_ring(4, directed = TRUE)
  igraph::V(g)$name <- c("A", "B", "C", "D")

  result <- rank_node_importance(g)
  expect_true(is.data.frame(result))
  expect_true("node" %in% names(result))
  expect_true("importance" %in% names(result))
  expect_equal(nrow(result), 4)
})

test_that("rank_node_importance returns empty df for non-igraph", {
  result <- rank_node_importance("not a graph")
  expect_equal(nrow(result), 0)
})

# ============================================================================
# build_network_from_isa tests
# ============================================================================

test_that("build_network_from_isa returns NULL for NULL input", {
  expect_null(build_network_from_isa(NULL))
})

test_that("build_network_from_isa returns NULL when nodes/edges missing", {
  expect_null(build_network_from_isa(list(nodes = NULL, edges = NULL)))
  expect_null(build_network_from_isa(list(nodes = data.frame(id = "A"), edges = NULL)))
})

test_that("build_network_from_isa creates igraph from valid isa", {
  isa <- list(
    nodes = data.frame(
      id = c("A", "B"),
      label = c("A", "B"),
      stringsAsFactors = FALSE
    ),
    edges = data.frame(
      from = c("A"),
      to = c("B"),
      stringsAsFactors = FALSE
    )
  )

  g <- build_network_from_isa(isa)
  expect_true(inherits(g, "igraph"))
  expect_equal(igraph::vcount(g), 2)
  expect_equal(igraph::ecount(g), 1)
})
