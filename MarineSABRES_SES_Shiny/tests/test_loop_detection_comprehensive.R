# Comprehensive Test Suite for Loop Detection
# Tests all scenarios that could cause hanging

library(testthat)
library(igraph)
library(dplyr)

# Source the functions
source("../functions/network_analysis.R")

context("Loop Detection - Comprehensive Tests")

# ==============================================================================
# TEST 1: Basic Functionality
# ==============================================================================

test_that("Small network completes quickly", {
  nodes <- data.frame(
    id = paste0("N", 1:10),
    label = paste("Node", 1:10),
    stringsAsFactors = FALSE
  )

  edges <- data.frame(
    from = c("N1", "N2", "N3", "N4", "N5"),
    to = c("N2", "N3", "N4", "N5", "N1"),
    polarity = c("+", "-", "+", "-", "+"),
    strength = "medium",
    stringsAsFactors = FALSE
  )

  start_time <- Sys.time()
  result <- find_all_cycles(nodes, edges, max_length = 8, max_cycles = 100)
  elapsed <- as.numeric(Sys.time() - start_time, units = "secs")

  expect_true(elapsed < 1, info = sprintf("Took %.3f seconds", elapsed))
  expect_true(length(result) > 0, info = "Should find at least one cycle")
  expect_true(length(result) <= 100, info = "Should respect max_cycles limit")
})

# ==============================================================================
# TEST 2: Large Sparse Network (Should Work)
# ==============================================================================

test_that("Large sparse network completes", {
  n <- 50
  nodes <- data.frame(
    id = paste0("N", 1:n),
    label = paste("Node", 1:n),
    stringsAsFactors = FALSE
  )

  # Sparse: only ring + few random edges (density ~3%)
  edges <- data.frame(
    from = c(paste0("N", 1:n), paste0("N", sample(1:n, 10))),
    to = c(paste0("N", c(2:n, 1)), paste0("N", sample(1:n, 10))),
    polarity = sample(c("+", "-"), n + 10, replace = TRUE),
    strength = "medium",
    stringsAsFactors = FALSE
  )

  start_time <- Sys.time()
  result <- find_all_cycles(nodes, edges, max_length = 8, max_cycles = 200)
  elapsed <- as.numeric(Sys.time() - start_time, units = "secs")

  expect_true(elapsed < 5, info = sprintf("Took %.3f seconds", elapsed))
  expect_true(length(result) >= 0, info = "Should complete without error")
})

# ==============================================================================
# TEST 3: Large Dense Component (Should Skip)
# ==============================================================================

test_that("Large dense component is skipped with warning", {
  n <- 40
  nodes <- data.frame(
    id = paste0("N", 1:n),
    label = paste("Node", 1:n),
    stringsAsFactors = FALSE
  )

  # Dense: each node connects to next 3 (7.7% density)
  from_nodes <- rep(paste0("N", 1:n), each = 3)
  to_nodes <- sapply(1:n, function(i) {
    paste0("N", ((i:(i+2)) %% n) + 1)
  }) %>% as.vector()

  edges <- data.frame(
    from = from_nodes,
    to = to_nodes,
    polarity = sample(c("+", "-"), length(from_nodes), replace = TRUE),
    strength = "medium",
    stringsAsFactors = FALSE
  )

  start_time <- Sys.time()
  expect_warning(
    result <- find_all_cycles(nodes, edges, max_length = 8, max_cycles = 200),
    "Skipping large dense component"
  )
  elapsed <- as.numeric(Sys.time() - start_time, units = "secs")

  expect_true(elapsed < 5, info = sprintf("Should skip quickly, took %.3f seconds", elapsed))
  expect_equal(length(result), 0, info = "Should skip and return 0 cycles")
})

# ==============================================================================
# TEST 4: Multiple Components (Should Work Well)
# ==============================================================================

test_that("Multiple small components work efficiently", {
  # Create 5 separate components of 7 nodes each (smaller than max_length=8)
  nodes <- data.frame(
    id = paste0("N", 1:35),
    label = paste("Node", 1:35),
    stringsAsFactors = FALSE
  )

  # Each component is a 7-node ring (will fit in max_length=8)
  edges_list <- lapply(0:4, function(comp) {
    base <- comp * 7
    data.frame(
      from = paste0("N", base + 1:7),
      to = paste0("N", base + c(2:7, 1)),
      polarity = sample(c("+", "-"), 7, replace = TRUE),
      strength = "medium",
      stringsAsFactors = FALSE
    )
  })

  edges <- bind_rows(edges_list)

  start_time <- Sys.time()
  result <- find_all_cycles(nodes, edges, max_length = 8, max_cycles = 500)
  elapsed <- as.numeric(Sys.time() - start_time, units = "secs")

  expect_true(elapsed < 3, info = sprintf("Took %.3f seconds", elapsed))
  expect_true(length(result) >= 5, info = sprintf("Should find cycles in multiple components, found %d", length(result)))
})

# ==============================================================================
# TEST 5: Edge Cases
# ==============================================================================

test_that("Empty network returns empty result", {
  nodes <- data.frame(id = character(0), label = character(0), stringsAsFactors = FALSE)
  edges <- data.frame(from = character(0), to = character(0), polarity = character(0),
                      strength = character(0), stringsAsFactors = FALSE)

  expect_error(
    result <- find_all_cycles(nodes, edges, max_length = 8, max_cycles = 100),
    "No valid edges"
  )
})

test_that("Network with no cycles returns empty", {
  nodes <- data.frame(
    id = paste0("N", 1:5),
    label = paste("Node", 1:5),
    stringsAsFactors = FALSE
  )

  # Tree structure - no cycles
  edges <- data.frame(
    from = c("N1", "N1", "N2", "N2"),
    to = c("N2", "N3", "N4", "N5"),
    polarity = rep("+", 4),
    strength = "medium",
    stringsAsFactors = FALSE
  )

  result <- find_all_cycles(nodes, edges, max_length = 8, max_cycles = 100)
  expect_equal(length(result), 0, info = "Tree structure should have no cycles")
})

test_that("Self-loop is detected", {
  nodes <- data.frame(
    id = c("N1"),
    label = c("Node 1"),
    stringsAsFactors = FALSE
  )

  edges <- data.frame(
    from = c("N1"),
    to = c("N1"),
    polarity = "+",
    strength = "medium",
    stringsAsFactors = FALSE
  )

  result <- find_all_cycles(nodes, edges, max_length = 8, max_cycles = 100)
  expect_true(length(result) >= 1, info = "Self-loop should be detected")
})

# ==============================================================================
# TEST 6: Timeout Behavior
# ==============================================================================

test_that("Detection respects max_cycles limit", {
  # Create a network that will generate many cycles
  n <- 20
  nodes <- data.frame(
    id = paste0("N", 1:n),
    label = paste("Node", 1:n),
    stringsAsFactors = FALSE
  )

  # Dense connections
  edges <- expand.grid(
    from = paste0("N", 1:n),
    to = paste0("N", 1:n)
  ) %>%
    filter(from != to) %>%
    sample_n(size = 100) %>%
    mutate(
      polarity = sample(c("+", "-"), n(), replace = TRUE),
      strength = "medium"
    )

  result <- find_all_cycles(nodes, edges, max_length = 8, max_cycles = 50)

  expect_true(length(result) <= 50,
              info = sprintf("Should stop at max_cycles, got %d", length(result)))
})

# ==============================================================================
# TEST 7: DFS Optimization Validation
# ==============================================================================

test_that("DFS uses O(1) data structures", {
  # This test verifies that the optimizations are in place
  # by checking performance on a moderately complex network

  n <- 25
  nodes <- data.frame(
    id = paste0("N", 1:n),
    label = paste("Node", 1:n),
    stringsAsFactors = FALSE
  )

  # Moderate density
  edges <- data.frame(
    from = c(paste0("N", 1:n), paste0("N", rep(1:(n/2), each = 2))),
    to = c(paste0("N", c(2:n, 1)), paste0("N", rep((n/2+1):n, each = 2))),
    polarity = sample(c("+", "-"), n + n/2*2, replace = TRUE),
    strength = "medium",
    stringsAsFactors = FALSE
  )

  start_time <- Sys.time()
  result <- find_all_cycles(nodes, edges, max_length = 8, max_cycles = 200)
  elapsed <- as.numeric(Sys.time() - start_time, units = "secs")

  # With O(n²) data structures, this would take >10s
  # With O(1) data structures, this should take <2s
  expect_true(elapsed < 2,
              info = sprintf("DFS optimization check: took %.3f seconds (should be <2s)", elapsed))
})

# ==============================================================================
# TEST 8: Component Size Limits
# ==============================================================================

test_that("Component size warnings are triggered", {
  n <- 55
  nodes <- data.frame(
    id = paste0("N", 1:n),
    label = paste("Node", 1:n),
    stringsAsFactors = FALSE
  )

  # Sparse ring (will trigger size warning but not density warning)
  edges <- data.frame(
    from = paste0("N", 1:n),
    to = paste0("N", c(2:n, 1)),
    polarity = sample(c("+", "-"), n, replace = TRUE),
    strength = "medium",
    stringsAsFactors = FALSE
  )

  expect_warning(
    result <- find_all_cycles(nodes, edges, max_length = 8, max_cycles = 200),
    "Large strongly connected component detected"
  )
})

# ==============================================================================
# PERFORMANCE BENCHMARKS
# ==============================================================================

cat("\n=== Performance Benchmarks ===\n\n")

benchmark_test <- function(name, nodes, edges, expected_time) {
  cat(sprintf("%-40s", name))

  start_time <- Sys.time()
  tryCatch({
    result <- find_all_cycles(nodes, edges, max_length = 8, max_cycles = 200)
    elapsed <- as.numeric(Sys.time() - start_time, units = "secs")

    status <- if (elapsed < expected_time) "✅ PASS" else "⚠️  SLOW"
    cat(sprintf("%s (%.3fs, found %d cycles)\n", status, elapsed, length(result)))

  }, warning = function(w) {
    elapsed <- as.numeric(Sys.time() - start_time, units = "secs")
    cat(sprintf("⚠️  WARN (%.3fs) - %s\n", elapsed, conditionMessage(w)))
  }, error = function(e) {
    elapsed <- as.numeric(Sys.time() - start_time, units = "secs")
    cat(sprintf("❌ ERROR (%.3fs) - %s\n", elapsed, conditionMessage(e)))
  })
}

# Small network
nodes_small <- data.frame(id = paste0("N", 1:10), label = paste("Node", 1:10), stringsAsFactors = FALSE)
edges_small <- data.frame(
  from = paste0("N", 1:10),
  to = paste0("N", c(2:10, 1)),
  polarity = rep("+", 10),
  strength = "medium",
  stringsAsFactors = FALSE
)
benchmark_test("Small network (10 nodes, ring)", nodes_small, edges_small, 0.5)

# Medium network
nodes_med <- data.frame(id = paste0("N", 1:30), label = paste("Node", 1:30), stringsAsFactors = FALSE)
edges_med <- data.frame(
  from = c(paste0("N", 1:30), paste0("N", 1:10)),
  to = c(paste0("N", c(2:30, 1)), paste0("N", 11:20)),
  polarity = sample(c("+", "-"), 40, replace = TRUE),
  strength = "medium",
  stringsAsFactors = FALSE
)
benchmark_test("Medium network (30 nodes, sparse)", nodes_med, edges_med, 1.5)

# Large sparse
nodes_large_sparse <- data.frame(id = paste0("N", 1:60), label = paste("Node", 1:60), stringsAsFactors = FALSE)
edges_large_sparse <- data.frame(
  from = paste0("N", 1:60),
  to = paste0("N", c(2:60, 1)),
  polarity = sample(c("+", "-"), 60, replace = TRUE),
  strength = "medium",
  stringsAsFactors = FALSE
)
benchmark_test("Large sparse (60 nodes, ring only)", nodes_large_sparse, edges_large_sparse, 3)

cat("\n")
