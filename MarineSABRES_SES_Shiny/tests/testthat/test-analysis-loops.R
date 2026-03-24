# tests/testthat/test-analysis-loops.R
# Regression tests for Task 4: Loop Detection checkbox wiring + edge cases

# -- Structural test: checkbox values wired --
test_that("loop detection module reads include_self_loops and filter_trivial inputs", {
  module_path <- file.path(dirname(dirname(getwd())), "modules", "analysis_loops.R")
  if (!file.exists(module_path)) {
    # Fallback: resolve relative to project root via testthat helper
    module_path <- testthat::test_path("../../modules/analysis_loops.R")
  }
  module_code <- readLines(module_path)
  code_text <- paste(module_code, collapse = "\n")
  expect_true(grepl("input\\$include_self_loops", code_text),
              info = "Server must read input$include_self_loops")
  expect_true(grepl("input\\$filter_trivial", code_text),
              info = "Server must read input$filter_trivial")
})

# -- Behavioral test: find_all_cycles handles empty edges --
test_that("find_all_cycles returns empty list for empty edges", {
  skip_if_not(exists("find_all_cycles", mode = "function"),
              "find_all_cycles not available")
  nodes <- data.frame(id = c("D1", "A1"), label = c("Driver", "Activity"),
                      stringsAsFactors = FALSE)
  edges <- data.frame(from = character(), to = character(), polarity = character(),
                      stringsAsFactors = FALSE)
  result <- find_all_cycles(nodes, edges, max_length = 5, max_cycles = 100)
  expect_true(is.list(result))
  expect_equal(length(result), 0)
})

# -- Behavioral test: find_all_cycles handles NULL edges --
test_that("find_all_cycles returns empty list for NULL edges", {
  skip_if_not(exists("find_all_cycles", mode = "function"),
              "find_all_cycles not available")
  nodes <- data.frame(id = c("D1"), label = c("Driver"), stringsAsFactors = FALSE)
  result <- find_all_cycles(nodes, NULL, max_length = 5, max_cycles = 100)
  expect_true(is.list(result))
  expect_equal(length(result), 0)
})

# -- Behavioral test: find_all_cycles detects a simple 3-node cycle --
test_that("find_all_cycles detects a simple feedback loop", {
  skip_if_not(exists("find_all_cycles", mode = "function"),
              "find_all_cycles not available")
  nodes <- data.frame(id = c("D1", "A1", "P1"),
                      label = c("Driver", "Activity", "Pressure"),
                      stringsAsFactors = FALSE)
  edges <- data.frame(from = c("D1", "A1", "P1"),
                      to = c("A1", "P1", "D1"),
                      polarity = c("+", "+", "-"),
                      stringsAsFactors = FALSE)
  result <- find_all_cycles(nodes, edges, max_length = 5, max_cycles = 100)
  expect_true(length(result) >= 1, info = "Should detect at least one cycle in D1->A1->P1->D1")
})
