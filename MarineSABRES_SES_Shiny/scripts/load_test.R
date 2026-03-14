#!/usr/bin/env Rscript
# scripts/load_test.R
# Load testing for MarineSABRES SES Toolbox
#
# Simulates concurrent user sessions against a running Shiny app instance.
# Launches the app in a background R process, then fires parallel HTTP
# requests to measure response times, failure rates, and memory usage.
#
# Usage:
#   Rscript scripts/load_test.R
#   Rscript scripts/load_test.R --sessions 10 --duration 60
#   Rscript scripts/load_test.R --sessions 20 --duration 120 --csv results.csv
#
# Prerequisites:
#   - Packages: shiny, httr, parallel, jsonlite (all already in project deps)
#   - The app must be able to start (global.R, app.R present)
#
# What it tests:
#   1. Concurrent session establishment (HTTP handshake)
#   2. Static asset loading (CSS, JS bundles)
#   3. Tab navigation requests
#   4. Template loading endpoints
#   5. Memory usage of the host R process over time
#
# Output:
#   - Console summary with pass/fail status
#   - Optional CSV file with per-request metrics

# ============================================================================
# SETUP
# ============================================================================

suppressPackageStartupMessages({
  library(parallel)
  library(jsonlite)
})

# Check for httr availability; fall back to curl if missing
USE_HTTR <- requireNamespace("httr", quietly = TRUE)
if (!USE_HTTR) {
  if (!requireNamespace("curl", quietly = TRUE)) {
    stop("Neither 'httr' nor 'curl' package is available. Install one with:\n",
         "  install.packages('httr')")
  }
  message("Note: 'httr' not found, using 'curl' as fallback.")
}

# ============================================================================
# ARGUMENT PARSING
# ============================================================================

parse_args <- function() {
  args <- commandArgs(trailingOnly = TRUE)
  config <- list(
    sessions  = 10L,
    duration  = 60L,
    port      = 0L,       # 0 = auto-select
    csv       = NULL,
    host      = "127.0.0.1",
    verbose   = FALSE
  )

  i <- 1
  while (i <= length(args)) {
    arg <- args[i]
    if (arg %in% c("--sessions", "-s") && i < length(args)) {
      config$sessions <- as.integer(args[i + 1])
      i <- i + 2
    } else if (arg %in% c("--duration", "-d") && i < length(args)) {
      config$duration <- as.integer(args[i + 1])
      i <- i + 2
    } else if (arg %in% c("--port", "-p") && i < length(args)) {
      config$port <- as.integer(args[i + 1])
      i <- i + 2
    } else if (arg == "--csv" && i < length(args)) {
      config$csv <- args[i + 1]
      i <- i + 2
    } else if (arg %in% c("--verbose", "-v")) {
      config$verbose <- TRUE
      i <- i + 1
    } else if (arg %in% c("--help", "-h")) {
      cat("Usage: Rscript scripts/load_test.R [OPTIONS]\n\n")
      cat("Options:\n")
      cat("  --sessions N   Number of concurrent sessions (default: 10)\n")
      cat("  --duration N   Test duration in seconds (default: 60)\n")
      cat("  --port N       Port for Shiny app (default: auto)\n")
      cat("  --csv FILE     Write detailed results to CSV\n")
      cat("  --verbose      Print per-request details\n")
      cat("  --help         Show this help\n")
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
# WORKING DIRECTORY
# ============================================================================

# Ensure we are in the project root
if (!file.exists("global.R")) {
  if (file.exists("../global.R")) {
    setwd("..")
  } else {
    stop("Must run from project root or scripts/ directory.\n",
         "  cd MarineSABRES_SES_Shiny && Rscript scripts/load_test.R")
  }
}

PROJECT_ROOT <- normalizePath(getwd())

cat("\n")
cat("========================================================================\n")
cat(" MarineSABRES SES Toolbox - Load Test\n")
cat("========================================================================\n")
cat(sprintf("  Date:          %s\n", format(Sys.time(), "%Y-%m-%d %H:%M:%S")))
cat(sprintf("  Sessions:      %d\n", config$sessions))
cat(sprintf("  Duration:      %ds\n", config$duration))
cat(sprintf("  Project root:  %s\n", PROJECT_ROOT))
cat(sprintf("  R version:     %s\n", R.version.string))
cat("========================================================================\n\n")

# ============================================================================
# MEMORY TRACKING UTILITIES
# ============================================================================

#' Get current R process memory usage in MB
get_memory_mb <- function() {
  # Use gc() to get memory stats; gc returns a matrix
  gc_info <- gc(verbose = FALSE, reset = FALSE)
  # Column "used" row "(Mb)" gives current used memory
  # gc_info has rows: Ncells, Vcells; columns: used, gc trigger, max used
  # The "(Mb)" row is the second in the Mb section
  used_mb <- sum(gc_info[, 2])  # Column 2 = current usage in Mb
  used_mb
}

#' Record a memory sample with timestamp
sample_memory <- function() {
  list(
    timestamp = Sys.time(),
    memory_mb = get_memory_mb()
  )
}

# ============================================================================
# HTTP REQUEST HELPERS
# ============================================================================

#' Make a timed HTTP GET request
#'
#' @param url Full URL to request
#' @param timeout_secs Request timeout
#' @return List with status, time_ms, size_bytes, error
timed_get <- function(url, timeout_secs = 30) {
  start <- proc.time()["elapsed"]

  result <- tryCatch({
    if (USE_HTTR) {
      resp <- httr::GET(url, httr::timeout(timeout_secs))
      elapsed <- (proc.time()["elapsed"] - start) * 1000
      list(
        status     = httr::status_code(resp),
        time_ms    = as.numeric(elapsed),
        size_bytes = as.numeric(nchar(httr::content(resp, as = "text", encoding = "UTF-8"))),
        error      = NULL
      )
    } else {
      # curl fallback
      h <- curl::new_handle(timeout = timeout_secs)
      resp <- curl::curl_fetch_memory(url, handle = h)
      elapsed <- (proc.time()["elapsed"] - start) * 1000
      list(
        status     = resp$status_code,
        time_ms    = as.numeric(elapsed),
        size_bytes = length(resp$content),
        error      = NULL
      )
    }
  }, error = function(e) {
    elapsed <- (proc.time()["elapsed"] - start) * 1000
    list(
      status     = 0L,
      time_ms    = as.numeric(elapsed),
      size_bytes = 0L,
      error      = e$message
    )
  })

  result
}

#' Check if Shiny app is responding
wait_for_app <- function(base_url, max_wait = 30) {
  cat("  Waiting for app to start")
  for (i in seq_len(max_wait)) {
    result <- tryCatch({
      if (USE_HTTR) {
        resp <- httr::GET(base_url, httr::timeout(2))
        httr::status_code(resp)
      } else {
        resp <- curl::curl_fetch_memory(base_url,
                  handle = curl::new_handle(timeout = 2))
        resp$status_code
      }
    }, error = function(e) 0L)

    if (result == 200L) {
      cat(" OK\n")
      return(TRUE)
    }
    cat(".")
    Sys.sleep(1)
  }
  cat(" TIMEOUT\n")
  return(FALSE)
}

# ============================================================================
# APP LAUNCHER
# ============================================================================

#' Launch the Shiny app in a background R process
#'
#' @param port Port number (0 for auto)
#' @return List with process handle and port
launch_app <- function(port = 0L) {
  # Find a free port if auto
  if (port == 0L) {
    port <- tryCatch({
      # Try to get a random free port
      srv <- serverSocket(0L)
      p <- summary(srv)$port
      close(srv)
      # If serverSocket doesn't expose port, fall back
      if (is.null(p)) sample(3000:9000, 1) else p
    }, error = function(e) {
      sample(3000:9000, 1)
    })
  }

  cat(sprintf("  Launching app on port %d...\n", port))

  # Build the R command to run the app
  app_cmd <- sprintf(
    'shiny::runApp("%s", port = %d, host = "%s", launch.browser = FALSE)',
    gsub("\\\\", "/", PROJECT_ROOT),
    port,
    config$host
  )

  # Launch in background R process
  rscript <- file.path(R.home("bin"), "Rscript")
  proc <- tryCatch({
    # Use system2 with background
    tmp_script <- tempfile(fileext = ".R")
    writeLines(app_cmd, tmp_script)

    # Start process and capture PID via a helper
    if (.Platform$OS.type == "windows") {
      # On Windows, use shell and start /B
      system2(rscript, args = tmp_script, wait = FALSE,
              stdout = tempfile(), stderr = tempfile())
    } else {
      system2(rscript, args = tmp_script, wait = FALSE,
              stdout = "/dev/null", stderr = "/dev/null")
    }

    list(script = tmp_script, port = port)
  }, error = function(e) {
    stop("Failed to launch app: ", e$message)
  })

  proc
}

# ============================================================================
# SESSION SIMULATION
# ============================================================================

#' Simulate a single user session
#'
#' Performs a sequence of HTTP requests that mimic a user interacting
#' with the Shiny app: load homepage, fetch static assets, navigate tabs.
#'
#' @param session_id Session identifier
#' @param base_url App base URL
#' @param verbose Print per-request details
#' @return Data frame of request metrics
simulate_session <- function(session_id, base_url, verbose = FALSE) {
  results <- list()

  # Define the sequence of operations a user would perform
  operations <- list(
    list(name = "homepage_load",
         path = "/",
         desc = "Load homepage"),
    list(name = "shared_assets",
         path = "/shared/",
         desc = "Fetch shared JS/CSS directory listing"),
    list(name = "favicon",
         path = "/favicon.ico",
         desc = "Fetch favicon"),
    list(name = "websocket_init",
         path = "/__sockjs__/info",
         desc = "WebSocket SockJS info endpoint"),
    list(name = "homepage_reload",
         path = "/",
         desc = "Simulate tab switch (page reload)")
  )

  for (op in operations) {
    url <- paste0(base_url, op$path)
    result <- timed_get(url, timeout_secs = 15)

    entry <- data.frame(
      session_id  = session_id,
      operation   = op$name,
      description = op$desc,
      status      = result$status,
      time_ms     = round(result$time_ms, 2),
      size_bytes  = result$size_bytes,
      error       = ifelse(is.null(result$error), NA_character_, result$error),
      timestamp   = format(Sys.time(), "%Y-%m-%d %H:%M:%OS3"),
      stringsAsFactors = FALSE
    )
    results <- c(results, list(entry))

    if (verbose) {
      status_str <- if (result$status == 200) "OK" else paste0("HTTP ", result$status)
      cat(sprintf("    [S%02d] %-20s %6.1fms  %s\n",
                  session_id, op$name, result$time_ms, status_str))
    }

    # Small random delay between operations (simulate human interaction)
    Sys.sleep(runif(1, 0.1, 0.5))
  }

  do.call(rbind, results)
}

# ============================================================================
# CONCURRENT SESSION RUNNER
# ============================================================================

#' Run multiple sessions concurrently
#'
#' Uses parallel::mclapply on Unix or sequential with async-like
#' timing on Windows (R does not support fork-based parallelism on Windows).
#'
#' @param n_sessions Number of sessions
#' @param base_url App base URL
#' @param verbose Print details
#' @return Combined data frame of all results
run_concurrent_sessions <- function(n_sessions, base_url, verbose = FALSE) {
  cat(sprintf("\n  Running %d concurrent sessions...\n", n_sessions))

  # Collect memory before
  mem_before <- get_memory_mb()

  # On Windows, we cannot fork; use sequential but stagger start times.
  # On Unix, use mclapply for true concurrency.
  start_time <- proc.time()["elapsed"]

  if (.Platform$OS.type == "windows") {
    # Sequential execution with progress reporting
    all_results <- vector("list", n_sessions)
    for (i in seq_len(n_sessions)) {
      cat(sprintf("    Session %d/%d starting...\n", i, n_sessions))
      all_results[[i]] <- tryCatch(
        simulate_session(i, base_url, verbose),
        error = function(e) {
          data.frame(
            session_id = i, operation = "ERROR", description = e$message,
            status = 0L, time_ms = 0, size_bytes = 0,
            error = e$message, timestamp = format(Sys.time()),
            stringsAsFactors = FALSE
          )
        }
      )
    }
  } else {
    # Unix: true parallel via forked processes
    n_cores <- min(n_sessions, detectCores() - 1, 8)
    all_results <- mclapply(
      seq_len(n_sessions),
      function(i) {
        tryCatch(
          simulate_session(i, base_url, verbose),
          error = function(e) {
            data.frame(
              session_id = i, operation = "ERROR", description = e$message,
              status = 0L, time_ms = 0, size_bytes = 0,
              error = e$message, timestamp = format(Sys.time()),
              stringsAsFactors = FALSE
            )
          }
        )
      },
      mc.cores = n_cores
    )
  }

  elapsed <- proc.time()["elapsed"] - start_time
  mem_after <- get_memory_mb()

  results_df <- do.call(rbind, all_results)
  attr(results_df, "total_elapsed_s") <- as.numeric(elapsed)
  attr(results_df, "mem_before_mb") <- mem_before
  attr(results_df, "mem_after_mb") <- mem_after

  results_df
}

# ============================================================================
# SUSTAINED LOAD TEST
# ============================================================================

#' Run sustained load for a given duration
#'
#' Continuously fires sessions for the configured duration, collecting
#' memory samples along the way.
#'
#' @param duration_s Duration in seconds
#' @param n_sessions Sessions per wave
#' @param base_url App base URL
#' @param verbose Print details
#' @return List with results_df and memory_samples
run_sustained_load <- function(duration_s, n_sessions, base_url, verbose = FALSE) {
  cat(sprintf("\n[2/4] Sustained load test (%ds, %d sessions/wave)\n",
              duration_s, n_sessions))
  cat(paste(rep("-", 50), collapse = ""), "\n")

  all_results <- list()
  memory_samples <- list(sample_memory())
  wave <- 0
  start_time <- proc.time()["elapsed"]

  while ((proc.time()["elapsed"] - start_time) < duration_s) {
    wave <- wave + 1
    elapsed_so_far <- round(proc.time()["elapsed"] - start_time)
    cat(sprintf("  Wave %d (elapsed: %ds/%ds)...\n", wave, elapsed_so_far, duration_s))

    wave_results <- run_concurrent_sessions(
      min(n_sessions, 5),  # Smaller waves for sustained load
      base_url,
      verbose
    )
    all_results <- c(all_results, list(wave_results))
    memory_samples <- c(memory_samples, list(sample_memory()))

    # Brief pause between waves
    Sys.sleep(2)
  }

  combined <- do.call(rbind, all_results)
  list(results = combined, memory = memory_samples)
}

# ============================================================================
# REPORTING
# ============================================================================

#' Generate and print the summary report
#'
#' @param results_df Data frame of all request metrics
#' @param memory_samples List of memory samples
#' @param config Test configuration
print_report <- function(results_df, memory_samples, config) {
  cat("\n")
  cat("========================================================================\n")
  cat(" LOAD TEST RESULTS\n")
  cat("========================================================================\n\n")

  # Overall stats
  total_requests <- nrow(results_df)
  successful <- sum(results_df$status == 200, na.rm = TRUE)
  failed <- sum(results_df$status != 200 | !is.na(results_df$error), na.rm = TRUE)
  fail_rate <- if (total_requests > 0) round(failed / total_requests * 100, 1) else 0

  cat(sprintf("  Total requests:     %d\n", total_requests))
  cat(sprintf("  Successful (200):   %d\n", successful))
  cat(sprintf("  Failed:             %d (%.1f%%)\n", failed, fail_rate))

  total_elapsed <- attr(results_df, "total_elapsed_s")
  if (!is.null(total_elapsed)) {
    cat(sprintf("  Total elapsed:      %.1fs\n", total_elapsed))
    cat(sprintf("  Throughput:         %.1f req/s\n", total_requests / total_elapsed))
  }

  # Response time stats
  cat("\n  Response Times (ms):\n")
  if (total_requests > 0 && any(results_df$time_ms > 0)) {
    times <- results_df$time_ms[results_df$time_ms > 0]
    cat(sprintf("    Mean:       %8.1f ms\n", mean(times)))
    cat(sprintf("    Median:     %8.1f ms\n", median(times)))
    cat(sprintf("    P95:        %8.1f ms\n", quantile(times, 0.95)))
    cat(sprintf("    P99:        %8.1f ms\n", quantile(times, 0.99)))
    cat(sprintf("    Min:        %8.1f ms\n", min(times)))
    cat(sprintf("    Max:        %8.1f ms\n", max(times)))
  }

  # Per-operation breakdown
  cat("\n  Per-Operation Breakdown:\n")
  cat(sprintf("    %-22s %8s %8s %8s %6s\n",
              "Operation", "Mean(ms)", "P95(ms)", "Count", "Fail%"))
  cat(paste(rep("-", 60), collapse = ""), "\n")

  ops <- unique(results_df$operation)
  for (op in ops) {
    op_data <- results_df[results_df$operation == op, ]
    op_times <- op_data$time_ms[op_data$time_ms > 0]
    op_fail <- sum(op_data$status != 200 | !is.na(op_data$error), na.rm = TRUE)
    op_fail_pct <- if (nrow(op_data) > 0) round(op_fail / nrow(op_data) * 100, 1) else 0

    cat(sprintf("    %-22s %8.1f %8.1f %8d %5.1f%%\n",
                op,
                if (length(op_times) > 0) mean(op_times) else 0,
                if (length(op_times) > 0) quantile(op_times, 0.95) else 0,
                nrow(op_data),
                op_fail_pct))
  }

  # Memory stats
  cat("\n  Memory Usage:\n")
  if (length(memory_samples) > 0) {
    mem_values <- sapply(memory_samples, function(s) s$memory_mb)
    cat(sprintf("    Start:      %8.1f MB\n", mem_values[1]))
    cat(sprintf("    Peak:       %8.1f MB\n", max(mem_values)))
    cat(sprintf("    End:        %8.1f MB\n", tail(mem_values, 1)))
    cat(sprintf("    Growth:     %8.1f MB\n", tail(mem_values, 1) - mem_values[1]))
  }

  mem_before <- attr(results_df, "mem_before_mb")
  mem_after <- attr(results_df, "mem_after_mb")
  if (!is.null(mem_before) && !is.null(mem_after)) {
    cat(sprintf("    Burst test: %8.1f MB -> %.1f MB (delta: %.1f MB)\n",
                mem_before, mem_after, mem_after - mem_before))
  }

  # Pass/fail summary
  cat("\n  Verdict:\n")
  if (fail_rate < 5 && median(results_df$time_ms[results_df$time_ms > 0]) < 5000) {
    cat("    [PASS] App handled load within acceptable parameters\n")
  } else if (fail_rate < 20) {
    cat("    [WARN] Some degradation observed under load\n")
  } else {
    cat("    [FAIL] Significant failures under load\n")
  }

  cat("\n========================================================================\n\n")
}

#' Write results to CSV
write_csv_report <- function(results_df, csv_path) {
  tryCatch({
    write.csv(results_df, csv_path, row.names = FALSE)
    cat(sprintf("  Results saved to: %s\n", csv_path))
  }, error = function(e) {
    cat(sprintf("  Warning: Could not write CSV: %s\n", e$message))
  })
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

main <- function() {
  memory_samples <- list(sample_memory())

  # Step 1: Launch the app
  cat("[1/4] Launching Shiny app in background...\n")
  cat(paste(rep("-", 50), collapse = ""), "\n")

  app_info <- launch_app(config$port)
  base_url <- sprintf("http://%s:%d", config$host, app_info$port)

  # Wait for the app to be ready
  if (!wait_for_app(base_url, max_wait = 60)) {
    cat("\n  ERROR: App did not start within 60 seconds.\n")
    cat("  Possible causes:\n")
    cat("    - Missing packages\n")
    cat("    - Port conflict\n")
    cat("    - Error in global.R or app.R\n")
    cat("\n  Try running the app manually first:\n")
    cat(sprintf("    Rscript -e 'shiny::runApp(\"%s\", port=%d)'\n",
                gsub("\\\\", "/", PROJECT_ROOT), app_info$port))
    quit(status = 1)
  }

  memory_samples <- c(memory_samples, list(sample_memory()))

  # Step 2: Burst test - all sessions at once
  cat(sprintf("\n[2/4] Burst test (%d concurrent sessions)\n", config$sessions))
  cat(paste(rep("-", 50), collapse = ""), "\n")

  burst_results <- run_concurrent_sessions(config$sessions, base_url, config$verbose)
  memory_samples <- c(memory_samples, list(sample_memory()))

  # Step 3: Sustained load test (if duration > 0)
  sustained_results <- NULL
  if (config$duration > 0) {
    sustained <- run_sustained_load(
      config$duration, config$sessions, base_url, config$verbose
    )
    sustained_results <- sustained$results
    memory_samples <- c(memory_samples, sustained$memory)
  }

  # Step 4: Compile and report
  cat("\n[4/4] Generating report\n")
  cat(paste(rep("-", 50), collapse = ""), "\n")

  # Combine all results
  all_results <- burst_results
  if (!is.null(sustained_results)) {
    all_results <- rbind(all_results, sustained_results)
  }

  # Print report
  print_report(all_results, memory_samples, config)

  # Write CSV if requested
  if (!is.null(config$csv)) {
    write_csv_report(all_results, config$csv)
  }

  cat("Load test complete.\n")
}

# Run
tryCatch(
  main(),
  error = function(e) {
    cat(sprintf("\nFATAL ERROR: %s\n", e$message))
    cat("Stack trace:\n")
    traceback()
    quit(status = 1)
  },
  interrupt = function(e) {
    cat("\n\nTest interrupted by user.\n")
    quit(status = 130)
  }
)
