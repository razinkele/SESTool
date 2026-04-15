#!/usr/bin/env Rscript
# scripts/memory_profile.R
# Memory profiling and scaling analysis for MarineSABRES SES Toolbox
#
# Creates synthetic SES networks of increasing size and measures:
#   - Memory consumption for each network size
#   - CLD generation time (igraph creation + visNetwork data prep)
#   - Loop/cycle detection time
#   - Network metrics calculation time (centrality, betweenness, PageRank)
#   - MICMAC analysis time
#
# Usage:
#   Rscript scripts/memory_profile.R
#   Rscript scripts/memory_profile.R --sizes 10,50,100,200,500
#   Rscript scripts/memory_profile.R --csv memory_profile.csv
#
# Prerequisites:
#   - Packages: igraph, dplyr (already in project deps)
#   - Must run from project root or scripts/ directory
#
# Output:
#   - Console table with timing and memory for each network size
#   - Optional CSV export

# ============================================================================
# SETUP
# ============================================================================

suppressPackageStartupMessages({
  library(igraph)
  library(dplyr)
})

# ============================================================================
# ARGUMENT PARSING
# ============================================================================

parse_args <- function() {
  args <- commandArgs(trailingOnly = TRUE)
  config <- list(
    sizes   = c(10, 50, 100, 200),
    csv     = NULL,
    repeats = 3L,
    density = 0.25,
    verbose = FALSE
  )

  i <- 1
  while (i <= length(args)) {
    arg <- args[i]
    if (arg == "--sizes" && i < length(args)) {
      config$sizes <- as.integer(strsplit(args[i + 1], ",")[[1]])
      i <- i + 2
    } else if (arg == "--csv" && i < length(args)) {
      config$csv <- args[i + 1]
      i <- i + 2
    } else if (arg == "--repeats" && i < length(args)) {
      config$repeats <- as.integer(args[i + 1])
      i <- i + 2
    } else if (arg == "--density" && i < length(args)) {
      config$density <- as.numeric(args[i + 1])
      i <- i + 2
    } else if (arg %in% c("--verbose", "-v")) {
      config$verbose <- TRUE
      i <- i + 1
    } else if (arg %in% c("--help", "-h")) {
      cat("Usage: Rscript scripts/memory_profile.R [OPTIONS]\n\n")
      cat("Options:\n")
      cat("  --sizes N,N,N   Comma-separated node counts (default: 10,50,100,200)\n")
      cat("  --csv FILE      Write results to CSV file\n")
      cat("  --repeats N     Repetitions per measurement (default: 3)\n")
      cat("  --density D     Edge density 0-1 (default: 0.25)\n")
      cat("  --verbose       Print detailed per-operation output\n")
      cat("  --help          Show this help\n")
      quit(status = 0)
    } else {
      message("Unknown argument: ", arg)
      i <- i + 1
    }
  }

  config
}

config <- parse_args()

# ============================================================================
# WORKING DIRECTORY AND SOURCE FILES
# ============================================================================

if (!file.exists("global.R")) {
  if (file.exists("../global.R")) {
    setwd("..")
  } else {
    stop("Must run from project root or scripts/ directory.\n",
         "  cd MarineSABRES_SES_Shiny && Rscript scripts/memory_profile.R")
  }
}

# Source only what we need (avoid loading the full Shiny app)
cat("Loading project source files...\n")

# We need constants and the %||% operator
`%||%` <- function(a, b) if (is.null(a)) b else a
`%|||%` <- function(a, b) if (is.null(a) || (length(a) == 1 && is.na(a))) b else a

# Stub out debug_log if not defined
DEBUG_MODE <- FALSE
debug_log <- function(message, context = NULL) invisible(NULL)

# Source constants
source("constants.R")

# Source utility functions (provides generate_id, etc.)
tryCatch(source("functions/utils.R"), error = function(e) {
  # Provide minimal stub if utils.R has unresolvable deps
  if (!exists("generate_id")) {
    generate_id <<- function(prefix = "ID") {
      paste0(prefix, "_", format(Sys.time(), "%Y%m%d%H%M%S"), "_", sample(1000:9999, 1))
    }
  }
})

# Source data structure (provides create_empty_project, initialize_isa_data, etc.)
tryCatch(source("functions/data_structure.R"), error = function(e) {
  message("  Warning: Could not load data_structure.R: ", e$message)
})

# Source network analysis (provides all the functions we need to profile)
tryCatch(source("functions/network_analysis.R"), error = function(e) {
  message("  Warning: Could not load network_analysis.R: ", e$message)
})

# Source visnetwork helpers if available (for CLD-style data prep)
tryCatch(source("functions/visnetwork_helpers.R"), error = function(e) {
  message("  Note: visnetwork_helpers.R not loaded (OK for profiling)")
})

cat("Source files loaded.\n\n")

# ============================================================================
# HEADER
# ============================================================================

cat("========================================================================\n")
cat(" MarineSABRES SES Toolbox - Memory Profile\n")
cat("========================================================================\n")
cat(sprintf("  Date:        %s\n", format(Sys.time(), "%Y-%m-%d %H:%M:%S")))
cat(sprintf("  R version:   %s\n", R.version.string))
cat(sprintf("  Platform:    %s\n", R.version$platform))
cat(sprintf("  Sizes:       %s nodes\n", paste(config$sizes, collapse = ", ")))
cat(sprintf("  Density:     %.0f%%\n", config$density * 100))
cat(sprintf("  Repeats:     %d\n", config$repeats))
cat("========================================================================\n\n")

# ============================================================================
# MEMORY MEASUREMENT UTILITY
# ============================================================================

#' Get current memory usage in MB using gc()
get_memory_mb <- function() {
  gc_info <- gc(verbose = FALSE, reset = FALSE)
  sum(gc_info[, 2])  # Sum of Ncells and Vcells used (Mb)
}

#' Measure memory delta for an expression
#'
#' Forces garbage collection before and after to get a clean measurement.
#'
#' @param expr Expression to evaluate (as a quoted call)
#' @return List with result, memory_before, memory_after, delta_mb
measure_memory <- function(expr_fn) {
  gc(verbose = FALSE, reset = TRUE)
  mem_before <- get_memory_mb()

  result <- expr_fn()

  gc(verbose = FALSE, reset = FALSE)
  mem_after <- get_memory_mb()

  list(
    result       = result,
    memory_before = mem_before,
    memory_after  = mem_after,
    delta_mb     = mem_after - mem_before
  )
}

#' Time an expression over N repeats
#'
#' @param expr_fn Function to time
#' @param n Number of repetitions
#' @return List with mean_ms, median_ms, min_ms, max_ms
time_repeated <- function(expr_fn, n = 3) {
  times <- numeric(n)
  for (i in seq_len(n)) {
    start <- proc.time()["elapsed"]
    tryCatch(expr_fn(), error = function(e) NULL)
    times[i] <- (proc.time()["elapsed"] - start) * 1000
  }
  list(
    mean_ms   = mean(times),
    median_ms = median(times),
    min_ms    = min(times),
    max_ms    = max(times),
    raw_ms    = times
  )
}

# ============================================================================
# SYNTHETIC NETWORK GENERATOR
# ============================================================================

#' Generate a realistic DAPSIWRM network for profiling
#'
#' Creates nodes distributed across the 7 DAPSIWRM element types with
#' edges following realistic density patterns.
#'
#' @param n_nodes Total number of nodes
#' @param edge_density Proportion of possible edges (0-1)
#' @return List with nodes df, edges df, and ISA-style adjacency data
generate_profiling_network <- function(n_nodes, edge_density = 0.25) {
  set.seed(42)  # Reproducible

  dapsiwrm_types <- DAPSIWRM_ELEMENTS

  # Distribute nodes across types (roughly equal, with some variation)
  type_assignments <- sample(dapsiwrm_types, n_nodes, replace = TRUE)

  nodes <- data.frame(
    id    = paste0("node_", sprintf("%04d", seq_len(n_nodes))),
    label = paste("Element", seq_len(n_nodes)),
    type  = type_assignments,
    group = type_assignments,
    stringsAsFactors = FALSE
  )

  # Generate edges
  max_possible_edges <- n_nodes * (n_nodes - 1)
  target_edges <- min(floor(max_possible_edges * edge_density), n_nodes * 5)

  edges_from <- character(target_edges)
  edges_to <- character(target_edges)
  edges_polarity <- character(target_edges)
  edges_strength <- numeric(target_edges)
  edges_confidence <- integer(target_edges)

  used_pairs <- character(0)
  count <- 0
  attempts <- 0
  max_attempts <- target_edges * 20

  while (count < target_edges && attempts < max_attempts) {
    from_idx <- sample.int(n_nodes, 1)
    to_idx <- sample.int(n_nodes, 1)
    attempts <- attempts + 1

    if (from_idx != to_idx) {
      pair_key <- paste(from_idx, to_idx, sep = "_")
      if (!pair_key %in% used_pairs) {
        count <- count + 1
        edges_from[count] <- nodes$id[from_idx]
        edges_to[count] <- nodes$id[to_idx]
        edges_polarity[count] <- sample(c("+", "-"), 1, prob = c(0.6, 0.4))
        edges_strength[count] <- sample(c(1, 2, 3, 4, 5), 1)
        edges_confidence[count] <- sample(1:5, 1)
        used_pairs <- c(used_pairs, pair_key)
      }
    }
  }

  edges <- data.frame(
    from       = edges_from[seq_len(count)],
    to         = edges_to[seq_len(count)],
    polarity   = edges_polarity[seq_len(count)],
    strength   = edges_strength[seq_len(count)],
    confidence = edges_confidence[seq_len(count)],
    stringsAsFactors = FALSE
  )

  list(nodes = nodes, edges = edges)
}

# ============================================================================
# PROFILING FUNCTIONS
# ============================================================================

#' Profile a single network size
#'
#' Runs all operations and collects timing + memory data.
#'
#' @param n_nodes Number of nodes
#' @param edge_density Edge density
#' @param repeats Number of timing repetitions
#' @param verbose Print per-operation details
#' @return Data frame row with all metrics
profile_network_size <- function(n_nodes, edge_density, repeats, verbose = FALSE) {
  cat(sprintf("  [%d nodes] Generating network...\n", n_nodes))

  # Generate the network
  net <- generate_profiling_network(n_nodes, edge_density)
  n_edges <- nrow(net$edges)
  cat(sprintf("           Nodes: %d, Edges: %d\n", n_nodes, n_edges))

  # --- 1. Memory for raw data ---
  mem_data <- measure_memory(function() {
    generate_profiling_network(n_nodes, edge_density)
  })
  data_mem_mb <- mem_data$delta_mb
  if (verbose) cat(sprintf("           Data memory: %.2f MB\n", data_mem_mb))

  # --- 2. igraph creation ---
  cat(sprintf("           Timing igraph creation...\n"))
  igraph_time <- time_repeated(function() {
    create_igraph_from_data(net$nodes, net$edges)
  }, repeats)
  if (verbose) cat(sprintf("           igraph: %.1f ms (median)\n", igraph_time$median_ms))

  # Create the graph once for subsequent operations
  g <- create_igraph_from_data(net$nodes, net$edges)

  # Memory for igraph object
  mem_igraph <- measure_memory(function() {
    create_igraph_from_data(net$nodes, net$edges)
  })
  igraph_mem_mb <- mem_igraph$delta_mb

  # --- 3. Network metrics ---
  cat(sprintf("           Timing network metrics...\n"))
  metrics_time <- time_repeated(function() {
    calculate_network_metrics(g)
  }, repeats)
  if (verbose) cat(sprintf("           Metrics: %.1f ms (median)\n", metrics_time$median_ms))

  # --- 4. Loop/cycle detection ---
  cat(sprintf("           Timing loop detection...\n"))
  # Use safe version if available, with bounded length
  max_loop_len <- if (n_nodes > 100) 4 else if (n_nodes > 50) 5 else 6
  loop_time <- time_repeated(function() {
    if (exists("find_all_cycles", mode = "function")) {
      find_all_cycles(net$nodes, net$edges,
                      max_length = max_loop_len,
                      max_cycles = 50)
    } else if (exists("detect_feedback_loops", mode = "function")) {
      detect_feedback_loops(g, max_length = max_loop_len)
    } else {
      NULL  # Function not available
    }
  }, repeats)
  loop_available <- exists("find_all_cycles", mode = "function") ||
                    exists("detect_feedback_loops", mode = "function")
  if (verbose) cat(sprintf("           Loops: %.1f ms (median) [available: %s]\n",
                           loop_time$median_ms, loop_available))

  # --- 5. MICMAC analysis ---
  cat(sprintf("           Timing MICMAC analysis...\n"))
  micmac_time <- time_repeated(function() {
    if (exists("calculate_micmac", mode = "function")) {
      tryCatch(
        calculate_micmac(net$nodes, net$edges),
        error = function(e) NULL
      )
    }
  }, repeats)
  micmac_available <- exists("calculate_micmac", mode = "function")
  if (verbose) cat(sprintf("           MICMAC: %.1f ms (median)\n", micmac_time$median_ms))

  # --- 6. Centrality calculations ---
  cat(sprintf("           Timing centrality measures...\n"))
  centrality_time <- time_repeated(function() {
    list(
      degree      = degree(g, mode = "all"),
      betweenness = betweenness(g, directed = TRUE),
      closeness   = tryCatch(closeness(g, mode = "all"), error = function(e) NULL),
      pagerank    = page_rank(g)$vector,
      eigenvector = tryCatch(eigen_centrality(g, directed = TRUE)$vector,
                             error = function(e) NULL)
    )
  }, repeats)
  if (verbose) cat(sprintf("           Centrality: %.1f ms (median)\n", centrality_time$median_ms))

  # --- 7. Total peak memory ---
  gc(verbose = FALSE)
  total_mem <- get_memory_mb()

  # Return a single-row data frame
  data.frame(
    nodes            = n_nodes,
    edges            = n_edges,
    data_mem_mb      = round(data_mem_mb, 3),
    igraph_mem_mb    = round(igraph_mem_mb, 3),
    igraph_ms        = round(igraph_time$median_ms, 1),
    metrics_ms       = round(metrics_time$median_ms, 1),
    loop_ms          = round(loop_time$median_ms, 1),
    loop_available   = loop_available,
    micmac_ms        = round(micmac_time$median_ms, 1),
    micmac_available = micmac_available,
    centrality_ms    = round(centrality_time$median_ms, 1),
    total_mem_mb     = round(total_mem, 1),
    stringsAsFactors = FALSE
  )
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

main <- function() {
  cat("[1/3] Baseline memory measurement\n")
  cat(paste(rep("-", 50), collapse = ""), "\n")
  baseline_mem <- get_memory_mb()
  cat(sprintf("  Baseline R process memory: %.1f MB\n\n", baseline_mem))

  cat("[2/3] Profiling network sizes\n")
  cat(paste(rep("-", 50), collapse = ""), "\n")

  results <- vector("list", length(config$sizes))
  for (i in seq_along(config$sizes)) {
    results[[i]] <- tryCatch(
      profile_network_size(
        config$sizes[i],
        config$density,
        config$repeats,
        config$verbose
      ),
      error = function(e) {
        cat(sprintf("  [%d nodes] ERROR: %s\n", config$sizes[i], e$message))
        data.frame(
          nodes = config$sizes[i], edges = NA,
          data_mem_mb = NA, igraph_mem_mb = NA,
          igraph_ms = NA, metrics_ms = NA,
          loop_ms = NA, loop_available = FALSE,
          micmac_ms = NA, micmac_available = FALSE,
          centrality_ms = NA, total_mem_mb = NA,
          stringsAsFactors = FALSE
        )
      }
    )
    cat("\n")
  }

  results_df <- do.call(rbind, results)

  # --- Report ---
  cat("[3/3] Results summary\n")
  cat("========================================================================\n")
  cat(" Memory & Performance Profile\n")
  cat("========================================================================\n\n")

  # Print the timing table
  cat("  Timing (median ms, lower is better):\n\n")
  cat(sprintf("  %6s %6s %10s %10s %10s %10s %12s\n",
              "Nodes", "Edges", "igraph", "Metrics", "Loops", "MICMAC", "Centrality"))
  cat(paste(rep("-", 72), collapse = ""), "\n")

  for (i in seq_len(nrow(results_df))) {
    r <- results_df[i, ]
    cat(sprintf("  %6d %6s %8.1f ms %8.1f ms %8.1f ms %8.1f ms %10.1f ms\n",
                r$nodes,
                ifelse(is.na(r$edges), "N/A", as.character(r$edges)),
                ifelse(is.na(r$igraph_ms), 0, r$igraph_ms),
                ifelse(is.na(r$metrics_ms), 0, r$metrics_ms),
                ifelse(is.na(r$loop_ms), 0, r$loop_ms),
                ifelse(is.na(r$micmac_ms), 0, r$micmac_ms),
                ifelse(is.na(r$centrality_ms), 0, r$centrality_ms)))
  }

  cat("\n")

  # Print the memory table
  cat("  Memory (MB):\n\n")
  cat(sprintf("  %6s %6s %10s %10s %12s\n",
              "Nodes", "Edges", "Data", "igraph", "Total Process"))
  cat(paste(rep("-", 52), collapse = ""), "\n")

  for (i in seq_len(nrow(results_df))) {
    r <- results_df[i, ]
    cat(sprintf("  %6d %6s %8.3f MB %8.3f MB %10.1f MB\n",
                r$nodes,
                ifelse(is.na(r$edges), "N/A", as.character(r$edges)),
                ifelse(is.na(r$data_mem_mb), 0, r$data_mem_mb),
                ifelse(is.na(r$igraph_mem_mb), 0, r$igraph_mem_mb),
                ifelse(is.na(r$total_mem_mb), 0, r$total_mem_mb)))
  }

  cat("\n")

  # Scaling analysis
  cat("  Scaling Analysis:\n")
  if (nrow(results_df) >= 2) {
    valid <- results_df[!is.na(results_df$metrics_ms) & results_df$metrics_ms > 0, ]
    if (nrow(valid) >= 2) {
      # Compare smallest to largest
      smallest <- valid[1, ]
      largest <- valid[nrow(valid), ]
      node_ratio <- largest$nodes / smallest$nodes
      time_ratio <- largest$metrics_ms / smallest$metrics_ms

      cat(sprintf("    Node increase:    %dx (%d -> %d)\n",
                  round(node_ratio), smallest$nodes, largest$nodes))
      cat(sprintf("    Metrics scaling:  %.1fx (%.1fms -> %.1fms)\n",
                  time_ratio, smallest$metrics_ms, largest$metrics_ms))

      # Estimate complexity class
      if (time_ratio < node_ratio * 1.5) {
        cat("    Estimated complexity: ~ O(n) [linear]\n")
      } else if (time_ratio < node_ratio^2 * 1.5) {
        cat("    Estimated complexity: ~ O(n^2) [quadratic]\n")
      } else {
        cat("    Estimated complexity: > O(n^2) [super-quadratic]\n")
      }
    }

    # Loop detection scaling
    valid_loop <- results_df[!is.na(results_df$loop_ms) & results_df$loop_ms > 0, ]
    if (nrow(valid_loop) >= 2) {
      s <- valid_loop[1, ]
      l <- valid_loop[nrow(valid_loop), ]
      cat(sprintf("    Loop detection:   %.1fx (%d->%d nodes)\n",
                  l$loop_ms / s$loop_ms, s$nodes, l$nodes))
    }
  }

  # Feature availability
  cat("\n  Function Availability:\n")
  cat(sprintf("    create_igraph_from_data:    %s\n",
              if (exists("create_igraph_from_data", mode = "function")) "YES" else "NO"))
  cat(sprintf("    calculate_network_metrics:  %s\n",
              if (exists("calculate_network_metrics", mode = "function")) "YES" else "NO"))
  cat(sprintf("    find_all_cycles:            %s\n",
              if (exists("find_all_cycles", mode = "function")) "YES" else "NO"))
  cat(sprintf("    detect_feedback_loops:      %s\n",
              if (exists("detect_feedback_loops", mode = "function")) "YES" else "NO"))
  cat(sprintf("    calculate_micmac:           %s\n",
              if (exists("calculate_micmac", mode = "function")) "YES" else "NO"))
  cat(sprintf("    identify_leverage_points:   %s\n",
              if (exists("identify_leverage_points", mode = "function")) "YES" else "NO"))

  cat("\n========================================================================\n")

  # Write CSV if requested
  if (!is.null(config$csv)) {
    results_df$date <- Sys.Date()
    results_df$r_version <- paste(R.version$major, R.version$minor, sep = ".")
    results_df$baseline_mem_mb <- baseline_mem

    tryCatch({
      write.csv(results_df, config$csv, row.names = FALSE)
      cat(sprintf("Results saved to: %s\n", config$csv))
    }, error = function(e) {
      cat(sprintf("Warning: Could not write CSV: %s\n", e$message))
    })
  }

  cat("\nMemory profiling complete.\n")
}

# Run
tryCatch(
  main(),
  error = function(e) {
    cat(sprintf("\nFATAL ERROR: %s\n", e$message))
    quit(status = 1)
  },
  interrupt = function(e) {
    cat("\nInterrupted by user.\n")
    quit(status = 130)
  }
)
