# scripts/performance_benchmarks.R
# Performance Benchmarks for MarineSABRES SES Toolbox (P2 #27)
#
# Measures execution time and memory usage for critical operations.
# Run with: Rscript scripts/performance_benchmarks.R
#
# Output: Prints benchmark results and saves to benchmarks/results_YYYYMMDD.csv

# ============================================================================
# SETUP
# ============================================================================

suppressPackageStartupMessages({
  library(bench)
  library(dplyr)
  library(igraph)
})

# Set working directory to project root if needed
if (!file.exists("global.R")) {
  if (file.exists("../global.R")) {
    setwd("..")
  } else {
    stop("Must run from project root or scripts/ directory")
  }
}

# Source required files
source("constants.R")
source("functions/utils.R")
source("functions/data_structure.R")
source("functions/network_analysis.R")

cat("=" |> rep(70) |> paste(collapse = ""), "\n")
cat("MarineSABRES SES Toolbox - Performance Benchmarks\n")
cat("Date:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n")
cat("=" |> rep(70) |> paste(collapse = ""), "\n\n")

# ============================================================================
# BENCHMARK CONFIGURATION
# ============================================================================

BENCHMARK_CONFIG <- list(
  # Number of iterations for micro-benchmarks
  iterations = 100,

  # Network sizes to test
  network_sizes = c(10, 50, 100, 200),

  # Target execution times (ms) for performance gates
  targets = list(
    network_metrics_small = 50,    # <50ms for 50 nodes
    network_metrics_medium = 200,  # <200ms for 100 nodes
    network_metrics_large = 1000,  # <1s for 200 nodes
    data_structure_init = 10,      # <10ms for ISA init
    loop_detection_small = 100,    # <100ms for 50 nodes
    loop_detection_medium = 500    # <500ms for 100 nodes
  )
)

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

#' Generate synthetic network data for benchmarking
#'
#' @param n_nodes Number of nodes
#' @param edge_density Proportion of possible edges to create
#' @return List with nodes and edges dataframes
generate_test_network <- function(n_nodes, edge_density = 0.3) {
  # Generate nodes with DAPSIWRM types
  types <- c("D", "A", "P", "C", "ES", "GB", "HW")

  nodes <- data.frame(
    id = paste0("node_", seq_len(n_nodes)),
    label = paste("Element", seq_len(n_nodes)),
    type = sample(types, n_nodes, replace = TRUE),
    
  )

  # Generate edges based on density
  max_edges <- n_nodes * (n_nodes - 1)
  n_edges <- floor(max_edges * edge_density)

  # Create random edge pairs (avoiding self-loops)
  edges_list <- vector("list", n_edges)
  used_pairs <- character(0)
  i <- 1
  attempts <- 0
  max_attempts <- n_edges * 10

  while (i <= n_edges && attempts < max_attempts) {
    from_idx <- sample(n_nodes, 1)
    to_idx <- sample(n_nodes, 1)

    if (from_idx != to_idx) {
      pair_key <- paste(from_idx, to_idx, sep = "_")
      if (!pair_key %in% used_pairs) {
        edges_list[[i]] <- data.frame(
          from = nodes$id[from_idx],
          to = nodes$id[to_idx],
          polarity = sample(c("+", "-"), 1),
          confidence = runif(1, 0.5, 1.0),
          
        )
        used_pairs <- c(used_pairs, pair_key)
        i <- i + 1
      }
    }
    attempts <- attempts + 1
  }

  edges <- do.call(rbind, edges_list[seq_len(i - 1)])

  list(nodes = nodes, edges = edges)
}

#' Format benchmark results for display
#'
#' @param bench_result Result from bench::mark()
#' @return Formatted string
format_benchmark <- function(bench_result) {
  med <- bench_result$median
  mem <- bench_result$mem_alloc

  sprintf(
    "Median: %s | Memory: %s | Iterations: %d",
    format(med),
    format(mem),
    bench_result$n_itr
  )
}

#' Check if benchmark meets target
#'
#' @param bench_result Result from bench::mark()
#' @param target_ms Target time in milliseconds
#' @return Logical
meets_target <- function(bench_result, target_ms) {
  median_ms <- as.numeric(bench_result$median) * 1000
  median_ms < target_ms
}

# ============================================================================
# BENCHMARK: NETWORK METRICS
# ============================================================================

cat("\n[1] NETWORK METRICS BENCHMARKS\n")
cat("-" |> rep(50) |> paste(collapse = ""), "\n")

network_results <- list()

for (n_nodes in BENCHMARK_CONFIG$network_sizes) {
  cat(sprintf("\n  Testing with %d nodes...\n", n_nodes))

  # Generate test data
  test_data <- generate_test_network(n_nodes, edge_density = 0.2)

  # Skip if no edges generated
  if (is.null(test_data$edges) || nrow(test_data$edges) == 0) {
    cat("    Skipping - no edges generated\n")
    next
  }

  # Benchmark network metrics calculation
  bench_result <- tryCatch({
    bench::mark(
      calculate_network_metrics(test_data$nodes, test_data$edges),
      iterations = min(BENCHMARK_CONFIG$iterations, 50),
      check = FALSE,
      memory = TRUE
    )
  }, error = function(e) {
    cat(sprintf("    Error: %s\n", e$message))
    NULL
  })

  if (!is.null(bench_result)) {
    network_results[[as.character(n_nodes)]] <- bench_result
    cat(sprintf("    %s\n", format_benchmark(bench_result)))
  }
}

# ============================================================================
# BENCHMARK: IGRAPH CREATION
# ============================================================================

cat("\n[2] IGRAPH CREATION BENCHMARKS\n")
cat("-" |> rep(50) |> paste(collapse = ""), "\n")

igraph_results <- list()

for (n_nodes in BENCHMARK_CONFIG$network_sizes) {
  cat(sprintf("\n  Testing with %d nodes...\n", n_nodes))

  test_data <- generate_test_network(n_nodes, edge_density = 0.2)

  if (is.null(test_data$edges) || nrow(test_data$edges) == 0) {
    cat("    Skipping - no edges generated\n")
    next
  }

  bench_result <- tryCatch({
    bench::mark(
      create_igraph_from_data(test_data$nodes, test_data$edges),
      iterations = BENCHMARK_CONFIG$iterations,
      check = FALSE,
      memory = TRUE
    )
  }, error = function(e) {
    cat(sprintf("    Error: %s\n", e$message))
    NULL
  })

  if (!is.null(bench_result)) {
    igraph_results[[as.character(n_nodes)]] <- bench_result
    cat(sprintf("    %s\n", format_benchmark(bench_result)))
  }
}

# ============================================================================
# BENCHMARK: LOOP DETECTION
# ============================================================================

cat("\n[3] LOOP DETECTION BENCHMARKS\n")
cat("-" |> rep(50) |> paste(collapse = ""), "\n")

# Check if detect_all_loops exists
if (exists("detect_all_loops", mode = "function")) {
  loop_results <- list()

  for (n_nodes in BENCHMARK_CONFIG$network_sizes[1:3]) {  # Limit to smaller sizes
    cat(sprintf("\n  Testing with %d nodes...\n", n_nodes))

    test_data <- generate_test_network(n_nodes, edge_density = 0.25)

    if (is.null(test_data$edges) || nrow(test_data$edges) == 0) {
      cat("    Skipping - no edges generated\n")
      next
    }

    g <- create_igraph_from_data(test_data$nodes, test_data$edges)

    bench_result <- tryCatch({
      bench::mark(
        detect_all_loops(g, max_length = 5),
        iterations = min(BENCHMARK_CONFIG$iterations, 20),
        check = FALSE,
        memory = TRUE
      )
    }, error = function(e) {
      cat(sprintf("    Error: %s\n", e$message))
      NULL
    })

    if (!is.null(bench_result)) {
      loop_results[[as.character(n_nodes)]] <- bench_result
      cat(sprintf("    %s\n", format_benchmark(bench_result)))
    }
  }
} else {
  cat("  detect_all_loops function not available\n")
}

# ============================================================================
# BENCHMARK: DATA STRUCTURE INITIALIZATION
# ============================================================================

cat("\n[4] DATA STRUCTURE BENCHMARKS\n")
cat("-" |> rep(50) |> paste(collapse = ""), "\n")

# Check if initialization function exists
if (exists("initialize_isa_data", mode = "function")) {
  cat("\n  Testing ISA data initialization...\n")

  bench_result <- tryCatch({
    bench::mark(
      initialize_isa_data(),
      iterations = BENCHMARK_CONFIG$iterations,
      check = FALSE,
      memory = TRUE
    )
  }, error = function(e) {
    cat(sprintf("    Error: %s\n", e$message))
    NULL
  })

  if (!is.null(bench_result)) {
    cat(sprintf("    %s\n", format_benchmark(bench_result)))
  }
} else {
  cat("  initialize_isa_data function not available\n")
}

# ============================================================================
# BENCHMARK: CENTRALITY CALCULATIONS
# ============================================================================

cat("\n[5] CENTRALITY CALCULATION BENCHMARKS\n")
cat("-" |> rep(50) |> paste(collapse = ""), "\n")

centrality_results <- list()

for (n_nodes in c(50, 100)) {
  cat(sprintf("\n  Testing with %d nodes...\n", n_nodes))

  test_data <- generate_test_network(n_nodes, edge_density = 0.2)

  if (is.null(test_data$edges) || nrow(test_data$edges) == 0) {
    cat("    Skipping - no edges generated\n")
    next
  }

  g <- create_igraph_from_data(test_data$nodes, test_data$edges)

  # Benchmark individual centrality measures
  cat("    Degree centrality: ")
  deg_result <- bench::mark(
    degree(g, mode = "all"),
    iterations = BENCHMARK_CONFIG$iterations,
    check = FALSE
  )
  cat(format(deg_result$median), "\n")

  cat("    Betweenness centrality: ")
  btw_result <- bench::mark(
    betweenness(g, directed = TRUE),
    iterations = min(BENCHMARK_CONFIG$iterations, 30),
    check = FALSE
  )
  cat(format(btw_result$median), "\n")

  cat("    PageRank: ")
  pr_result <- bench::mark(
    page_rank(g)$vector,
    iterations = BENCHMARK_CONFIG$iterations,
    check = FALSE
  )
  cat(format(pr_result$median), "\n")

  centrality_results[[as.character(n_nodes)]] <- list(
    degree = deg_result,
    betweenness = btw_result,
    pagerank = pr_result
  )
}

# ============================================================================
# BENCHMARK: ML FEATURE ENGINEERING (if available)
# ============================================================================

cat("\n[6] ML FEATURE ENGINEERING BENCHMARKS\n")
cat("-" |> rep(50) |> paste(collapse = ""), "\n")

if (file.exists("functions/ml_feature_engineering.R")) {
  tryCatch({
    source("functions/ml_feature_engineering.R")

    if (exists("engineer_element_features", mode = "function")) {
      cat("\n  Testing feature engineering...\n")

      test_element <- list(
        id = "test_1",
        label = "Test Climate Change Driver",
        type = "D",
        description = "A driver related to climate change impacts on marine ecosystems"
      )

      bench_result <- bench::mark(
        engineer_element_features(test_element),
        iterations = min(BENCHMARK_CONFIG$iterations, 50),
        check = FALSE,
        memory = TRUE
      )

      cat(sprintf("    %s\n", format_benchmark(bench_result)))
    } else {
      cat("  engineer_element_features function not available\n")
    }
  }, error = function(e) {
    cat(sprintf("  Error loading ML features: %s\n", e$message))
  })
} else {
  cat("  ML feature engineering not available\n")
}

# ============================================================================
# PERFORMANCE GATE CHECK
# ============================================================================

cat("\n[7] PERFORMANCE GATE SUMMARY\n")
cat("=" |> rep(70) |> paste(collapse = ""), "\n")

gates_passed <- 0
gates_total <- 0

# Check network metrics gates
if (length(network_results) > 0) {
  if ("50" %in% names(network_results)) {
    gates_total <- gates_total + 1
    if (meets_target(network_results[["50"]], BENCHMARK_CONFIG$targets$network_metrics_small)) {
      cat("  [PASS] Network metrics (50 nodes) < 50ms\n")
      gates_passed <- gates_passed + 1
    } else {
      cat("  [FAIL] Network metrics (50 nodes) >= 50ms\n")
    }
  }

  if ("100" %in% names(network_results)) {
    gates_total <- gates_total + 1
    if (meets_target(network_results[["100"]], BENCHMARK_CONFIG$targets$network_metrics_medium)) {
      cat("  [PASS] Network metrics (100 nodes) < 200ms\n")
      gates_passed <- gates_passed + 1
    } else {
      cat("  [FAIL] Network metrics (100 nodes) >= 200ms\n")
    }
  }

  if ("200" %in% names(network_results)) {
    gates_total <- gates_total + 1
    if (meets_target(network_results[["200"]], BENCHMARK_CONFIG$targets$network_metrics_large)) {
      cat("  [PASS] Network metrics (200 nodes) < 1000ms\n")
      gates_passed <- gates_passed + 1
    } else {
      cat("  [FAIL] Network metrics (200 nodes) >= 1000ms\n")
    }
  }
}

cat(sprintf("\nGates passed: %d/%d\n", gates_passed, gates_total))

# ============================================================================
# SAVE RESULTS
# ============================================================================

# Create benchmarks directory if needed
if (!dir.exists("benchmarks")) {
  dir.create("benchmarks")
}

# Compile results
results_df <- data.frame(
  date = Sys.Date(),
  r_version = paste(R.version$major, R.version$minor, sep = "."),
  benchmark = character(0),
  nodes = integer(0),
  median_ms = numeric(0),
  mem_mb = numeric(0),
  
)

# Add network results
for (size in names(network_results)) {
  result <- network_results[[size]]
  results_df <- rbind(results_df, data.frame(
    date = Sys.Date(),
    r_version = paste(R.version$major, R.version$minor, sep = "."),
    benchmark = "network_metrics",
    nodes = as.integer(size),
    median_ms = as.numeric(result$median) * 1000,
    mem_mb = as.numeric(result$mem_alloc) / 1024 / 1024,
    
  ))
}

# Add igraph results
for (size in names(igraph_results)) {
  result <- igraph_results[[size]]
  results_df <- rbind(results_df, data.frame(
    date = Sys.Date(),
    r_version = paste(R.version$major, R.version$minor, sep = "."),
    benchmark = "igraph_creation",
    nodes = as.integer(size),
    median_ms = as.numeric(result$median) * 1000,
    mem_mb = as.numeric(result$mem_alloc) / 1024 / 1024,
    
  ))
}

# Save to CSV
output_file <- sprintf("benchmarks/results_%s.csv", format(Sys.Date(), "%Y%m%d"))
write.csv(results_df, output_file, row.names = FALSE)
cat(sprintf("\nResults saved to: %s\n", output_file))

cat("\n" |> rep(1) |> paste(collapse = ""), "=" |> rep(70) |> paste(collapse = ""), "\n")
cat("Benchmarks complete.\n")
