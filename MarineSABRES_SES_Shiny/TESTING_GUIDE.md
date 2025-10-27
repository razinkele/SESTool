# Comprehensive Testing Guide - MarineSABRES SES Shiny Application

## Table of Contents

1. [Overview](#overview)
2. [Quick Start](#quick-start)
3. [Testing Framework Architecture](#testing-framework-architecture)
4. [Test Categories](#test-categories)
5. [Running Tests](#running-tests)
6. [Writing Tests](#writing-tests)
7. [Test Utilities](#test-utilities)
8. [Best Practices](#best-practices)
9. [Continuous Integration](#continuous-integration)
10. [Troubleshooting](#troubleshooting)

## Overview

The MarineSABRES SES Shiny Application uses a comprehensive testing framework built on `testthat` to ensure code quality, reliability, and maintainability.

### Testing Stack

- **testthat**: Core testing framework
- **shinytest2**: Shiny-specific testing utilities
- **covr**: Code coverage analysis
- **R6**: Object-oriented utilities for mocks

### Coverage Goals

- **Unit Tests**: >80% coverage of utility functions
- **Module Tests**: All Shiny modules tested for UI and server
- **Integration Tests**: Key workflows validated end-to-end

## Quick Start

See [tests/QUICK_START.md](tests/QUICK_START.md) for a quick introduction to running tests.

**TL;DR:**

```r
# Install dependencies
install.packages(c("testthat", "shinytest2", "covr"))

# Run all tests
testthat::test_dir("tests/testthat")

# Or use the test runner
Rscript run_tests.R
```

## Testing Framework Architecture

```
MarineSABRES_SES_Shiny/
├── tests/
│   ├── testthat.R              # Main test runner
│   ├── testthat/
│   │   ├── setup.R             # Test environment setup
│   │   ├── helpers.R           # Test utilities
│   │   ├── .Rprofile           # Test-specific R profile
│   │   ├── test-global-utils.R # Global utility tests
│   │   ├── test-data-structure.R # Data structure tests
│   │   ├── test-network-analysis.R # Network analysis tests
│   │   ├── test-ui-helpers.R   # UI helper tests
│   │   ├── test-export-functions.R # Export function tests
│   │   ├── test-modules.R      # Shiny module tests
│   │   └── test-integration.R  # Integration tests
│   ├── README.md               # Detailed testing docs
│   └── QUICK_START.md          # Quick start guide
├── run_tests.R                 # Convenient test runner script
└── .github/
    └── workflows/
        └── test.yml            # CI/CD workflow
```

## Test Categories

### 1. Unit Tests

**Purpose**: Test individual functions in isolation

**Files**:
- `test-global-utils.R`: Global utility functions (validation, sanitization, etc.)
- `test-data-structure.R`: Data structure creation and manipulation
- `test-network-analysis.R`: Network analysis algorithms
- `test-ui-helpers.R`: UI helper functions
- `test-export-functions.R`: Export and reporting functions
- `test-confidence.R`: Confidence property implementation (87 tests)
- `test-network-metrics-module.R`: Network Metrics Module implementation (87 tests)

**Example**:
```r
test_that("sanitize_filename removes dangerous characters", {
  expect_equal(sanitize_filename("file/path"), "filepath")
  expect_equal(sanitize_filename("test<file>"), "testfile")
})
```

### 2. Module Tests

**Purpose**: Test Shiny module UI and server functions

**Files**:
- `test-modules.R`: Tests for all Shiny modules

**Example**:
```r
test_that("ISA data entry module UI renders correctly", {
  ui <- isaDataEntryUI("test")
  expect_shiny_tag(ui)
})

testServer(isaDataEntryServer, {
  session$setInputs(element_name = "Test Driver")
  expect_equal(reactive_data()$drivers$Name[1], "Test Driver")
})
```

### 3. Integration Tests

**Purpose**: Test end-to-end workflows and data flows

**Files**:
- `test-integration.R`: Complete workflow tests

**Example**:
```r
test_that("Complete ISA workflow succeeds", {
  # 1. Initialize project
  project <- init_session_data()

  # 2. Add ISA data
  project$data$isa_data <- create_mock_isa_data()

  # 3. Build network
  network <- build_network_from_isa(project)

  # 4. Verify
  expect_valid_network(network)
  expect_true(vcount(network) > 0)
})
```

### 4. Confidence Property Tests

**Purpose**: Comprehensive testing of confidence property implementation across all CLD functionality

**Files**:
- `test-confidence.R`: 87 tests covering all confidence-related code

**Test Coverage**:

#### Global Constants Tests (30 tests)
```r
test_that("confidence global constants are defined correctly", {
  # Verify CONFIDENCE_LEVELS
  expect_equal(CONFIDENCE_LEVELS, 1:5)

  # Verify CONFIDENCE_DEFAULT
  expect_equal(CONFIDENCE_DEFAULT, 3)
  expect_true(CONFIDENCE_DEFAULT %in% CONFIDENCE_LEVELS)

  # Verify CONFIDENCE_LABELS
  expect_length(CONFIDENCE_LABELS, 5)
  expect_equal(CONFIDENCE_LABELS["3"], c("3" = "Medium"))

  # Verify CONFIDENCE_OPACITY
  expect_length(CONFIDENCE_OPACITY, 5)
  expect_equal(CONFIDENCE_OPACITY["3"], c("3" = 0.7))

  # Verify opacity range and ascending order
  expect_true(all(CONFIDENCE_OPACITY >= 0 & CONFIDENCE_OPACITY <= 1))
  expect_true(all(diff(as.numeric(CONFIDENCE_OPACITY)) > 0))
})
```

#### Parse Function Tests (7 tests)
```r
test_that("parse_connection_value handles confidence correctly", {
  # Default confidence
  result <- parse_connection_value("+strong")
  expect_equal(result$confidence, CONFIDENCE_DEFAULT)

  # Valid confidence
  result <- parse_connection_value("+medium:5")
  expect_equal(result$confidence, 5)

  # Out of range defaults to CONFIDENCE_DEFAULT
  result <- parse_connection_value("+weak:10")
  expect_equal(result$confidence, CONFIDENCE_DEFAULT)

  # All confidence levels
  for (conf in CONFIDENCE_LEVELS) {
    result <- parse_connection_value(paste0("+medium:", conf))
    expect_equal(result$confidence, conf)
  }
})
```

#### Edge Creation Tests (2 tests)
```r
test_that("process_adjacency_matrix includes confidence in edges", {
  # Create matrix with confidence
  matrix <- matrix("+strong:4", nrow = 1, ncol = 1)
  edges <- process_adjacency_matrix(matrix, "A", "D", 1, 1)

  # Verify confidence column exists
  expect_true("confidence" %in% names(edges))
  expect_equal(edges$confidence[1], 4)

  # Verify opacity is applied
  expect_true("opacity" %in% names(edges))
  expect_equal(edges$opacity[1], CONFIDENCE_OPACITY["4"])
})
```

#### Filter Tests (2 tests)
```r
test_that("filter_by_confidence filters edges correctly", {
  edges <- data.frame(
    from = c("A", "B", "C"),
    to = c("B", "C", "A"),
    confidence = c(1, 3, 5)
  )

  # Filter for high confidence (>= 4)
  filtered <- filter_by_confidence(edges, 4)
  expect_equal(nrow(filtered), 1)
  expect_equal(filtered$confidence[1], 5)
})
```

#### Integration Tests (1 test)
```r
test_that("Full workflow: ISA data -> CLD edges -> Filter -> Export", {
  # Create adjacency matrix
  matrix <- matrix("", nrow = 2, ncol = 2)
  matrix[1, 1] <- "+strong:5"  # High confidence
  matrix[2, 2] <- "-weak:2"    # Low confidence

  # Generate edges
  edges <- process_adjacency_matrix(matrix, "A", "D", 2, 2)

  # Filter by confidence
  filtered <- filter_by_confidence(edges, 4)
  expect_equal(nrow(filtered), 1)  # Only high confidence

  # Export and verify
  project_data <- list(data = list(cld = list(edges = edges)))
  temp_file <- tempfile(fileext = ".xlsx")
  export_project_excel(project_data, temp_file)

  # Verify confidence column in export
  exported <- openxlsx::readWorkbook(temp_file, "CLD_Edges")
  expect_true("confidence" %in% names(exported))
})
```

**Example: Running Confidence Tests**
```r
# Run all confidence tests
testthat::test_file('tests/testthat/test-confidence.R')

# Expected output: [ FAIL 0 | WARN 0 | SKIP 0 | PASS 87 ]
```

### 5. Network Metrics Module Tests

**Purpose**: Comprehensive testing of Network Metrics Analysis Module implementation

**Files**:
- `test-network-metrics-module.R`: 87 tests covering complete Network Metrics functionality

**Test Coverage**:

#### Metrics Calculation Tests (7 tests)
```r
test_that("calculate_network_metrics works with nodes and edges", {
  test_data <- create_test_network_data()

  metrics <- calculate_network_metrics(test_data$nodes, test_data$edges)

  # Network-level metrics
  expect_true("nodes" %in% names(metrics))
  expect_true("edges" %in% names(metrics))
  expect_true("density" %in% names(metrics))
  expect_true("diameter" %in% names(metrics))

  # Node-level centrality metrics
  expect_true("degree" %in% names(metrics))
  expect_true("betweenness" %in% names(metrics))
  expect_true("pagerank" %in% names(metrics))
})

test_that("degree metrics are consistent", {
  # Total degree should equal in + out degree
  for (i in seq_along(metrics$degree)) {
    expect_equal(
      metrics$degree[i],
      metrics$indegree[i] + metrics$outdegree[i]
    )
  }
})

test_that("centrality metrics are in valid range", {
  # PageRank should sum to approximately 1
  expect_equal(sum(metrics$pagerank), 1, tolerance = 0.01)

  # Closeness between 0 and 1
  expect_true(all(metrics$closeness >= 0))
  expect_true(all(metrics$closeness <= 1))
})
```

#### Node Metrics Dataframe Tests (1 test)
```r
test_that("node metrics dataframe is created correctly", {
  node_metrics_df <- data.frame(
    ID = nodes$id,
    Label = nodes$label,
    Type = nodes$group,
    Degree = metrics$degree,
    Betweenness = round(metrics$betweenness, 2),
    PageRank = round(metrics$pagerank, 4)
  )

  # Check structure
  expect_equal(ncol(node_metrics_df), 10)
  expect_equal(nrow(node_metrics_df), 5)
})
```

#### Top Nodes Identification Tests (3 tests)
```r
test_that("top nodes by degree are identified correctly", {
  top_degree <- node_metrics_df %>%
    arrange(desc(Degree)) %>%
    head(3)

  # Check sorted descending
  expect_true(top_degree$Degree[1] >= top_degree$Degree[2])
})

test_that("top nodes by pagerank are identified correctly", {
  top_pagerank <- node_metrics_df %>%
    arrange(desc(PageRank)) %>%
    head(5)

  # PageRank values should sum to less than or equal 1
  expect_true(sum(node_metrics_df$PageRank) <= 1.01)
})
```

#### Network Connectivity Tests (1 test)
```r
test_that("network connectivity percentage is calculated correctly", {
  g <- create_igraph_from_data(nodes, edges)

  distances <- distances(g, mode = "out")
  reachable_pairs <- sum(is.finite(distances) & distances > 0)
  total_pairs <- vcount(g) * (vcount(g) - 1)
  connectivity_pct <- round((reachable_pairs / total_pairs) * 100, 1)

  expect_true(connectivity_pct >= 0 && connectivity_pct <= 100)
})
```

#### Error Handling Tests (3 tests)
```r
test_that("metrics calculation handles missing confidence column", {
  # Remove confidence column
  edges$confidence <- NULL

  # Should still work
  metrics <- calculate_network_metrics(nodes, edges)
  expect_type(metrics, "list")
})

test_that("metrics calculation handles invalid edges", {
  # Add invalid edge
  bad_edge <- data.frame(from = "INVALID", to = "A1")
  edges <- rbind(edges, bad_edge)

  # Should warn but continue
  expect_warning(
    calculate_network_metrics(nodes, edges),
    regexp = "Removed.*edges referencing non-existent nodes"
  )
})

test_that("metrics calculation handles disconnected components", {
  # Create disconnected network
  nodes <- data.frame(id = c("A", "B", "C", "D"))
  edges <- data.frame(from = c("A", "C"), to = c("B", "D"))

  metrics <- calculate_network_metrics(nodes, edges)

  # Should still calculate
  expect_equal(metrics$nodes, 4)
  expect_equal(metrics$edges, 2)
})
```

#### Performance Tests (1 test)
```r
test_that("metrics calculation handles large network", {
  # Create 50 node, 100 edge network
  n_nodes <- 50
  nodes <- data.frame(id = paste0("N", 1:n_nodes))
  edges <- data.frame(
    from = sample(nodes$id, 100, replace = TRUE),
    to = sample(nodes$id, 100, replace = TRUE)
  )

  # Should complete in under 5 seconds
  start_time <- Sys.time()
  metrics <- calculate_network_metrics(nodes, edges)
  time_taken <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))

  expect_true(time_taken < 5)
})
```

#### Integration Tests (2 tests)
```r
test_that("metrics work with project data structure", {
  project_data <- list(
    data = list(
      cld = list(
        nodes = test_nodes,
        edges = test_edges
      )
    )
  )

  nodes <- project_data$data$cld$nodes
  edges <- project_data$data$cld$edges
  metrics <- calculate_network_metrics(nodes, edges)

  expect_equal(metrics$nodes, 5)
})

test_that("metrics handle missing CLD data", {
  project_data <- list(
    data = list(cld = list(nodes = NULL, edges = NULL))
  )

  expect_null(project_data$data$cld$nodes)
})
```

#### Visualization Data Preparation Tests (2 tests)
```r
test_that("data is prepared correctly for bar plot", {
  plot_data <- node_metrics_df %>%
    arrange(desc(Degree)) %>%
    head(10)

  # Should be sorted descending
  for (i in seq_len(nrow(plot_data) - 1)) {
    expect_true(plot_data$Degree[i] >= plot_data$Degree[i + 1])
  }
})

test_that("data is prepared correctly for comparison plot", {
  plot_data <- data.frame(
    Label = nodes$label,
    Degree = metrics$degree,
    Betweenness = metrics$betweenness,
    PageRank = metrics$pagerank * 100
  )

  # Check all columns exist for scatter plot
  expect_true("Degree" %in% names(plot_data))
  expect_true("Betweenness" %in% names(plot_data))
  expect_true("PageRank" %in% names(plot_data))
})
```

**Test Summary:**
- **Total Tests:** 87
- **Categories:** 9 (calculation, dataframe, top nodes, connectivity, errors, performance, integration, visualization)
- **Status:** All passing ✅

**Example: Running Network Metrics Tests**
```r
# Run all network metrics tests
testthat::test_file('tests/testthat/test-network-metrics-module.R')

# Expected output: [ FAIL 0 | WARN 0 | SKIP 0 | PASS 87 ]
```

**Key Features Tested:**
- All 7 centrality metrics (degree, in/out-degree, betweenness, closeness, eigenvector, pagerank)
- Network-level statistics (density, diameter, connectivity)
- Data validation and edge cases
- Error handling (missing data, invalid edges, disconnected networks)
- Performance with large networks
- Integration with project data structure
- Visualization data preparation

## Running Tests

### Option 1: Test Runner Script

```bash
# Run all tests
Rscript run_tests.R

# Run with coverage
Rscript run_tests.R --coverage

# Run specific test
Rscript run_tests.R global-utils

# Show help
Rscript run_tests.R --help
```

### Option 2: R Console

```r
library(testthat)

# Run all tests
test_dir("tests/testthat")

# Run with specific reporter
test_dir("tests/testthat", reporter = "progress")
test_dir("tests/testthat", reporter = "location")
test_dir("tests/testthat", reporter = "summary")

# Run specific file
test_file("tests/testthat/test-global-utils.R")
```

### Option 3: RStudio

1. Open project in RStudio
2. **Build** > **Test Package** (or `Ctrl+Shift+T`)
3. View results in Build pane

### Option 4: Continuous Testing

```r
# Watch for changes and auto-run tests
testthat::auto_test(".", "tests/testthat")
```

## Writing Tests

### Test Structure

Follow the **Arrange-Act-Assert** pattern:

```r
test_that("descriptive test name", {
  # Arrange - Set up test data
  input_data <- create_test_data()

  # Act - Execute the function
  result <- my_function(input_data)

  # Assert - Verify results
  expect_equal(result$value, expected_value)
  expect_true("field" %in% names(result))
})
```

### Common Expectations

```r
# Equality
expect_equal(actual, expected)
expect_identical(actual, expected)

# Truth
expect_true(condition)
expect_false(condition)

# Type
expect_type(object, "list")
expect_s3_class(object, "data.frame")
expect_s4_class(object, "igraph")

# Errors and warnings
expect_error(dangerous_function())
expect_warning(problematic_function())
expect_message(informative_function())

# Matching
expect_match(string, regex)
expect_named(object, c("name1", "name2"))

# Length
expect_length(vector, 5)

# Custom
expect_shiny_tag(ui_element)
expect_valid_network(network)
expect_valid_project_data(project)
```

### Skipping Tests

```r
# Skip if function doesn't exist
test_that("optional feature works", {
  skip_if_not(exists("optional_function"))
  result <- optional_function()
  expect_true(result)
})

# Skip on specific platform
test_that("Linux-specific test", {
  skip_on_os("windows")
  # Test code
})

# Skip if package not available
test_that("requires special package", {
  skip_if_not_installed("specialpackage")
  # Test code
})
```

## Test Utilities

### Mock Data Generators

Located in `tests/testthat/helpers.R`:

```r
# Create mock ISA data
isa_data <- create_mock_isa_data()

# Create complete project
project <- create_mock_project_data(
  include_isa = TRUE,
  include_cld = TRUE
)

# Create network
network <- create_mock_network(n_nodes = 10, n_edges = 15)

# Create adjacency matrix
adj_matrix <- create_mock_adjacency_matrix(
  row_names = c("D1", "D2", "D3"),
  col_names = c("A1", "A2"),
  fill_percent = 50
)
```

### Custom Expectations

```r
# Verify Shiny UI
expect_shiny_tag(ui_element)

# Verify network
expect_valid_network(network)

# Verify project data
expect_valid_project_data(project)
```

### Test Fixtures

```r
# Create temporary test file
temp_file <- create_temp_test_file("content", ext = ".txt")

# Clean up files
cleanup_test_files(c(file1, file2, file3))

# Compare data frames ignoring order
compare_dfs_unordered(df1, df2)
```

## Best Practices

### 1. Test Independence

Each test should run independently:

```r
# Good - test creates its own data
test_that("function works", {
  data <- create_test_data()
  result <- my_function(data)
  expect_true(result)
})

# Bad - test depends on global state
data <- create_test_data()
test_that("function works", {
  result <- my_function(data)
  expect_true(result)
})
```

### 2. Descriptive Names

Use clear, descriptive test names:

```r
# Good
test_that("sanitize_filename removes path separators", {})
test_that("validate_email rejects addresses without @", {})

# Bad
test_that("test1", {})
test_that("it works", {})
```

### 3. One Concept Per Test

```r
# Good - tests one specific behavior
test_that("generate_id uses custom prefix", {
  id <- generate_id("CUSTOM")
  expect_true(grepl("^CUSTOM_", id))
})

# Bad - tests multiple unrelated things
test_that("generate_id works", {
  id1 <- generate_id()
  id2 <- generate_id("CUSTOM")
  expect_true(nchar(id1) > 0)
  expect_true(grepl("^CUSTOM_", id2))
  expect_true(id1 != id2)
})
```

### 4. Test Edge Cases

```r
test_that("function handles edge cases", {
  # Empty input
  expect_error(my_function(NULL))
  expect_error(my_function(data.frame()))

  # Extreme values
  expect_equal(my_function(0), expected_for_zero)
  expect_equal(my_function(Inf), expected_for_inf)

  # Special characters
  expect_equal(my_function(""), expected_for_empty)
  expect_equal(my_function("special!@#"), expected_for_special)
})
```

### 5. Use Setup and Teardown

```r
# In setup.R - runs before all tests
test_data_dir <- tempdir()

# In individual test file
withr::local_tempdir()  # Auto cleanup temp directory

# Manual cleanup
test_that("test with cleanup", {
  file <- tempfile()
  write.csv(data, file)

  # Test code

  # Cleanup
  unlink(file)
})
```

## Continuous Integration

### GitHub Actions

The project includes a GitHub Actions workflow ([.github/workflows/test.yml](.github/workflows/test.yml)) that:

- Runs tests on push/pull request
- Tests across multiple OS (Ubuntu, Windows, macOS)
- Tests across multiple R versions (4.2, 4.3, 4.4)
- Generates coverage reports
- Uploads test results on failure

### Local Pre-commit Hook

Create `.git/hooks/pre-commit`:

```bash
#!/bin/sh
echo "Running tests before commit..."
Rscript -e "testthat::test_dir('tests/testthat')" || exit 1
```

Make it executable:

```bash
chmod +x .git/hooks/pre-commit
```

## Coverage Analysis

### Generate Coverage Report

```r
library(covr)

# Calculate coverage
coverage <- package_coverage(type = "tests")

# View in browser
report(coverage)

# Print summary
print(coverage)

# Coverage for specific file
file_coverage("global.R", "tests/testthat/test-global-utils.R")
```

### Using Test Runner

```bash
Rscript run_tests.R --coverage
```

### Interpreting Results

- **Green lines**: Covered by tests
- **Red lines**: Not covered by tests
- **Yellow lines**: Partially covered

**Coverage Goals**:
- Critical functions: >90%
- Utility functions: >80%
- UI functions: >60%
- Overall: >75%

## Troubleshooting

### Tests Fail: Function Not Found

**Problem**: `Error: object 'my_function' not found`

**Solution**:
1. Check function is sourced in `setup.R`
2. Verify function file path is correct
3. Check for typos in function name

### Tests Fail: Package Not Available

**Problem**: `Error: there is no package called 'xyz'`

**Solution**:
```r
install.packages("xyz")
```

### Tests Pass Locally But Fail in CI

**Problem**: Tests pass on your machine but fail in GitHub Actions

**Possible causes**:
1. Platform-specific behavior (Windows vs Linux)
2. Different package versions
3. Missing system dependencies
4. Hardcoded file paths

**Solutions**:
- Use `file.path()` instead of hardcoded paths
- Add `skip_on_os()` for platform-specific tests
- Ensure all dependencies in CI workflow

### Slow Tests

**Problem**: Tests take too long to run

**Solutions**:
1. Use `skip_if_not()` for expensive tests
2. Mock external dependencies
3. Reduce test data size
4. Use parallel testing (advanced)

### Memory Issues

**Problem**: Tests crash with memory errors

**Solutions**:
1. Clean up large objects after tests
2. Use `gc()` to force garbage collection
3. Reduce mock data size
4. Run tests in batches

## Additional Resources

- [testthat Documentation](https://testthat.r-lib.org/)
- [R Packages - Testing](https://r-pkgs.org/testing-basics.html)
- [Shiny Testing Guide](https://shiny.rstudio.com/articles/testing-overview.html)
- [shinytest2 Package](https://rstudio.github.io/shinytest2/)
- [Code Coverage with covr](https://covr.r-lib.org/)

## Contributing

When contributing to the project:

1. **Write tests first** (TDD approach recommended)
2. **Ensure existing tests pass** before submitting PR
3. **Add tests for new features**
4. **Update tests when fixing bugs**
5. **Maintain coverage** above project goals
6. **Document complex tests** with comments

## Questions?

For questions about testing:
- Check [tests/README.md](tests/README.md)
- Check [tests/QUICK_START.md](tests/QUICK_START.md)
- Open an issue in the repository
- Contact the development team

---

*Last updated: 2025-01-25*
*Testing Framework Version: 1.0*
