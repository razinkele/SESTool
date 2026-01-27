# tests/testthat/test-performance.R
# Performance Regression Tests
# ==============================================================================
#
# These tests ensure that critical operations complete within acceptable
# time thresholds. They help prevent performance regressions.
#
# ==============================================================================

library(testthat)

# ==============================================================================
# Performance Thresholds (in seconds)
# ==============================================================================

# Template loading should be fast, especially with caching
TEMPLATE_LOAD_THRESHOLD <- 2.0        # First load
TEMPLATE_CACHE_THRESHOLD <- 0.1       # Cached load

# Network operations
NETWORK_BUILD_THRESHOLD <- 1.0        # Small network (<50 nodes)
NETWORK_BUILD_LARGE_THRESHOLD <- 5.0  # Large network (50-200 nodes)

# Data structure operations
DATA_STRUCTURE_THRESHOLD <- 0.5       # Project data creation
DATA_VALIDATION_THRESHOLD <- 0.5      # Project data validation

# Edge creation
EDGE_CREATION_THRESHOLD <- 0.5        # Per 100 edges

# ==============================================================================
# Helper Functions
# ==============================================================================

#' Measure execution time of an expression
#' @param expr Expression to measure
#' @return List with result and elapsed time
measure_time <- function(expr) {
  start_time <- Sys.time()
  result <- tryCatch(expr, error = function(e) NULL)
  end_time <- Sys.time()

  list(
    result = result,
    elapsed = as.numeric(difftime(end_time, start_time, units = "secs"))
  )
}

#' Create a test project data structure
create_test_project <- function(n_elements = 10) {
  list(
    project_id = paste0("PERF-", format(Sys.time(), "%Y%m%d%H%M%S")),
    project_name = "Performance Test Project",
    created_at = Sys.time(),
    last_modified = Sys.time(),
    data = list(
      metadata = list(
        da_site = "Test Site",
        focal_issue = "Performance Testing"
      ),
      isa_data = list(
        goods_benefits = data.frame(
          id = paste0("gb_", 1:n_elements),
          name = paste("Benefit", 1:n_elements),
          description = paste("Description", 1:n_elements),
          stringsAsFactors = FALSE
        ),
        ecosystem_services = data.frame(
          id = paste0("es_", 1:n_elements),
          name = paste("Service", 1:n_elements),
          description = paste("Description", 1:n_elements),
          stringsAsFactors = FALSE
        ),
        marine_processes = data.frame(
          id = paste0("mpf_", 1:n_elements),
          name = paste("Process", 1:n_elements),
          description = paste("Description", 1:n_elements),
          stringsAsFactors = FALSE
        ),
        pressures = data.frame(
          id = paste0("p_", 1:n_elements),
          name = paste("Pressure", 1:n_elements),
          description = paste("Description", 1:n_elements),
          stringsAsFactors = FALSE
        ),
        activities = data.frame(
          id = paste0("a_", 1:n_elements),
          name = paste("Activity", 1:n_elements),
          description = paste("Description", 1:n_elements),
          stringsAsFactors = FALSE
        ),
        drivers = data.frame(
          id = paste0("d_", 1:n_elements),
          name = paste("Driver", 1:n_elements),
          description = paste("Description", 1:n_elements),
          stringsAsFactors = FALSE
        )
      ),
      cld = list(
        nodes = data.frame(
          id = paste0("node_", 1:(n_elements * 6)),
          label = paste("Node", 1:(n_elements * 6)),
          type = rep(c("Drivers", "Activities", "Pressures",
                       "Marine Processes & Functioning",
                       "Ecosystem Services", "Goods & Benefits"),
                     each = n_elements),
          stringsAsFactors = FALSE
        ),
        edges = data.frame(
          from = paste0("node_", sample(1:(n_elements * 6), n_elements * 3, replace = TRUE)),
          to = paste0("node_", sample(1:(n_elements * 6), n_elements * 3, replace = TRUE)),
          polarity = sample(c("+", "-"), n_elements * 3, replace = TRUE),
          strength = sample(c("weak", "medium", "strong"), n_elements * 3, replace = TRUE),
          stringsAsFactors = FALSE
        )
      )
    )
  )
}

# ==============================================================================
# Test: Template Loading Performance
# ==============================================================================

test_that("Template loading completes within threshold", {
  skip_if_not(exists("load_all_templates"), "load_all_templates function not loaded")
  skip_if_not(dir.exists("data"), "data directory not found")

  # Clear cache if it exists
  if (exists(".template_cache", envir = globalenv())) {
    rm(list = ls(envir = .template_cache), envir = .template_cache)
  }

  # First load (uncached)
  timing <- measure_time({
    load_all_templates("data")
  })

  expect_true(
    timing$elapsed < TEMPLATE_LOAD_THRESHOLD,
    info = sprintf("Template loading took %.2fs (threshold: %.2fs)",
                   timing$elapsed, TEMPLATE_LOAD_THRESHOLD)
  )
})

test_that("Cached template loading is fast", {
  skip_if_not(exists("load_template_from_json"), "load_template_from_json function not loaded")
  skip_if_not(file.exists("data/Fisheries_SES_Template.json"), "Fisheries template not found")

  # First load to populate cache
  load_template_from_json("data/Fisheries_SES_Template.json", use_cache = TRUE)

  # Cached load
  timing <- measure_time({
    load_template_from_json("data/Fisheries_SES_Template.json", use_cache = TRUE)
  })

  expect_true(
    timing$elapsed < TEMPLATE_CACHE_THRESHOLD,
    info = sprintf("Cached template loading took %.3fs (threshold: %.3fs)",
                   timing$elapsed, TEMPLATE_CACHE_THRESHOLD)
  )
})

# ==============================================================================
# Test: Data Structure Performance
# ==============================================================================

test_that("Project data creation is fast", {
  skip_if_not(exists("create_empty_project_data"), "create_empty_project_data function not loaded")

  timing <- measure_time({
    for (i in 1:10) {
      create_empty_project_data()
    }
  })

  avg_time <- timing$elapsed / 10

  expect_true(
    avg_time < DATA_STRUCTURE_THRESHOLD,
    info = sprintf("Average project creation took %.3fs (threshold: %.3fs)",
                   avg_time, DATA_STRUCTURE_THRESHOLD)
  )
})

test_that("Project data validation is fast", {
  skip_if_not(exists("validate_project_data"), "validate_project_data function not loaded")

  project <- create_test_project(n_elements = 20)

  timing <- measure_time({
    for (i in 1:10) {
      validate_project_data(project)
    }
  })

  avg_time <- timing$elapsed / 10

  expect_true(
    avg_time < DATA_VALIDATION_THRESHOLD,
    info = sprintf("Average validation took %.3fs (threshold: %.3fs)",
                   avg_time, DATA_VALIDATION_THRESHOLD)
  )
})

# ==============================================================================
# Test: Network Building Performance
# ==============================================================================

test_that("Small network building is fast", {
  skip_if_not(exists("create_igraph_from_data"), "create_igraph_from_data function not loaded")

  project <- create_test_project(n_elements = 5)  # 30 nodes

  timing <- measure_time({
    create_igraph_from_data(
      project$data$cld$nodes,
      project$data$cld$edges
    )
  })

  expect_true(
    timing$elapsed < NETWORK_BUILD_THRESHOLD,
    info = sprintf("Small network build took %.3fs (threshold: %.3fs)",
                   timing$elapsed, NETWORK_BUILD_THRESHOLD)
  )
})

test_that("Large network building completes within threshold", {
  skip_if_not(exists("create_igraph_from_data"), "create_igraph_from_data function not loaded")

  project <- create_test_project(n_elements = 30)  # 180 nodes

  timing <- measure_time({
    create_igraph_from_data(
      project$data$cld$nodes,
      project$data$cld$edges
    )
  })

  expect_true(
    timing$elapsed < NETWORK_BUILD_LARGE_THRESHOLD,
    info = sprintf("Large network build took %.3fs (threshold: %.3fs)",
                   timing$elapsed, NETWORK_BUILD_LARGE_THRESHOLD)
  )
})

# ==============================================================================
# Test: Vectorized Operations Performance
# ==============================================================================

test_that("Vectorized string operations are efficient", {
  # Test that we're using vectorized operations, not sapply
  n <- 1000
  test_strings <- paste("Test String", 1:n)

  # Vectorized approach (should be fast)
  timing_vec <- measure_time({
    result <- tolower(trimws(test_strings))
  })

  # sapply approach (should be slower)
  timing_sapply <- measure_time({
    result <- sapply(test_strings, function(x) tolower(trimws(x)))
  })

  # Vectorized should be at least 2x faster
  expect_true(
    timing_vec$elapsed < timing_sapply$elapsed / 2,
    info = sprintf("Vectorized: %.4fs, sapply: %.4fs",
                   timing_vec$elapsed, timing_sapply$elapsed)
  )
})

# ==============================================================================
# Test: DataFrame Operations Performance
# ==============================================================================

test_that("DataFrame binding is efficient", {
  n_dfs <- 10
  n_rows <- 100

  # Create test dataframes
  df_list <- lapply(1:n_dfs, function(i) {
    data.frame(
      id = paste0("id_", ((i-1)*n_rows + 1):(i*n_rows)),
      value = runif(n_rows),
      label = paste("Label", 1:n_rows),
      stringsAsFactors = FALSE
    )
  })

  # Single bind_rows (efficient)
  timing_single <- measure_time({
    result <- do.call(dplyr::bind_rows, df_list)
  })

  # Repeated bind_rows in loop (inefficient)
  timing_loop <- measure_time({
    result <- df_list[[1]]
    for (i in 2:length(df_list)) {
      result <- dplyr::bind_rows(result, df_list[[i]])
    }
  })

  # Single bind should be faster
  expect_true(
    timing_single$elapsed <= timing_loop$elapsed * 1.5,  # Allow some variance
    info = sprintf("Single bind: %.4fs, Loop bind: %.4fs",
                   timing_single$elapsed, timing_loop$elapsed)
  )
})

# ==============================================================================
# Test: Memory Efficiency
# ==============================================================================

test_that("Large project data doesn't cause memory issues", {
  skip_on_cran()  # Skip on CRAN due to memory constraints

  # Create a large project
  project <- create_test_project(n_elements = 50)  # 300 nodes

  # Measure memory before
  gc()
  mem_before <- sum(gc()[, 2])

  # Perform operations
  for (i in 1:5) {
    copy <- project
    copy$data$metadata$iteration <- i
  }

  # Measure memory after
  gc()
  mem_after <- sum(gc()[, 2])

  # Memory increase should be reasonable (less than 50MB for test data)
  mem_increase <- mem_after - mem_before

  expect_true(
    mem_increase < 50,  # 50 MB threshold
    info = sprintf("Memory increased by %.1f MB", mem_increase)
  )
})

# ==============================================================================
# Summary
# ==============================================================================

cat("\n", strrep("=", 70), "\n", sep = "")
cat("Performance Regression Tests Complete\n")
cat(strrep("=", 70), "\n")
