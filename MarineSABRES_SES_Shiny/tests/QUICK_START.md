# Quick Start Guide - Testing Framework

This guide will help you get started with testing the MarineSABRES SES Shiny Application.

## Prerequisites

Install required R packages:

```r
install.packages(c("testthat", "shinytest2", "covr", "R6"))
```

## Running Tests

### Option 1: Using the Test Runner Script

From the project root directory:

```bash
# Run all tests
Rscript run_tests.R

# Run tests with coverage analysis
Rscript run_tests.R --coverage

# Run specific test file
Rscript run_tests.R global-utils
```

### Option 2: Using R Console

```r
# Load testthat
library(testthat)

# Run all tests
test_dir("tests/testthat")

# Run specific test file
test_file("tests/testthat/test-global-utils.R")

# Run tests with detailed output
test_dir("tests/testthat", reporter = "progress")
```

### Option 3: Using RStudio

1. Open the project in RStudio
2. Go to **Build** > **Test Package** (or press `Ctrl+Shift+T`)
3. View results in the Build pane

## Understanding Test Results

### Successful Test Output

```
✓ |  OK F W S | Context
✓ |  25       | global-utils
✓ |  15       | data-structure
✓ |  20       | network-analysis
```

- ✓ = All tests passed
- OK = Number of successful tests
- F = Number of failed tests
- W = Number of warnings
- S = Number of skipped tests

### Failed Test Output

```
✗ | 1 2     | global-utils
──────────────────────────────────────────────────────
test-global-utils.R:45: failure: sanitize_color validates colors
Expected "#ffffff" but got "#cccccc"
──────────────────────────────────────────────────────
```

## Test Categories

### 1. Unit Tests

Test individual functions in isolation:

```r
# Example: Testing a utility function
test_that("generate_id generates unique IDs", {
  id1 <- generate_id()
  id2 <- generate_id()
  expect_true(id1 != id2)
})
```

**Files:**
- `test-global-utils.R` - Global utility functions
- `test-data-structure.R` - Data structure functions
- `test-network-analysis.R` - Network analysis functions
- `test-ui-helpers.R` - UI helper functions
- `test-export-functions.R` - Export functions

### 2. Module Tests

Test Shiny modules (UI and server):

```r
# Example: Testing module UI
test_that("ISA module UI renders", {
  ui <- isaDataEntryUI("test")
  expect_shiny_tag(ui)
})

# Example: Testing module server
test_that("ISA module server works", {
  testServer(isaDataEntryServer, {
    session$setInputs(input_name = "value")
    expect_equal(output$result, expected)
  })
})
```

**Files:**
- `test-modules.R` - All Shiny module tests

### 3. Integration Tests

Test complete workflows:

```r
# Example: Testing end-to-end workflow
test_that("ISA workflow completes successfully", {
  # Step 1: Initialize
  project <- init_session_data()

  # Step 2: Add data
  project$data$isa_data <- create_mock_isa_data()

  # Step 3: Build network
  network <- build_network(project)

  # Step 4: Verify
  expect_valid_network(network)
})
```

**Files:**
- `test-integration.R` - End-to-end workflow tests

## Using Test Helpers

The `helpers.R` file provides utilities for testing:

### Creating Mock Data

```r
# Create mock ISA data
isa_data <- create_mock_isa_data()

# Create complete project data
project <- create_mock_project_data(include_isa = TRUE, include_cld = TRUE)

# Create mock network
network <- create_mock_network(n_nodes = 10, n_edges = 15)

# Create mock adjacency matrix
adj_matrix <- create_mock_adjacency_matrix(
  row_names = c("D1", "D2"),
  col_names = c("A1", "A2"),
  fill_percent = 50
)
```

### Custom Expectations

```r
# Verify Shiny UI elements
expect_shiny_tag(ui_element)

# Verify network structure
expect_valid_network(network)

# Verify project data
expect_valid_project_data(project)
```

## Common Testing Patterns

### Testing Function Return Values

```r
test_that("function returns expected value", {
  result <- my_function(input)
  expect_equal(result, expected_value)
})
```

### Testing Data Structures

```r
test_that("data structure is correct", {
  data <- create_data()

  expect_type(data, "list")
  expect_true("field" %in% names(data))
  expect_equal(length(data$items), 5)
})
```

### Testing Error Handling

```r
test_that("function handles errors correctly", {
  expect_error(my_function(invalid_input))
  expect_warning(my_function(problematic_input))
  expect_message(my_function(info_input))
})
```

### Testing Shiny Reactivity

```r
test_that("reactive values update correctly", {
  testServer(my_server, {
    # Set input
    session$setInputs(slider = 50)

    # Check reactive
    expect_equal(reactive_value(), 50)

    # Check output
    expect_equal(output$display, "50")
  })
})
```

## Debugging Failed Tests

### 1. Run Test in Interactive Mode

```r
# Source the test file
source("tests/testthat/test-global-utils.R")

# Run specific test manually
test_that("my test", {
  # Add browser() to pause execution
  browser()

  result <- my_function(input)
  expect_equal(result, expected)
})
```

### 2. Check Test Environment

```r
# Verify functions are loaded
exists("my_function")

# Check current working directory
getwd()

# List loaded packages
(.packages())
```

### 3. Use Verbose Output

```r
# Run tests with detailed reporter
test_dir("tests/testthat", reporter = "location")
```

## Best Practices

1. **Keep tests independent** - Each test should run in isolation
2. **Use descriptive names** - Test names should explain what is being tested
3. **Test one thing at a time** - Each test should verify one specific behavior
4. **Use setup/teardown** - Clean up resources after tests
5. **Mock external dependencies** - Don't rely on external services
6. **Test edge cases** - Include boundary conditions and error scenarios

## Continuous Testing

### Watch Mode

Automatically run tests when files change:

```r
testthat::auto_test(".", "tests/testthat")
```

### Git Pre-commit Hook

Create `.git/hooks/pre-commit`:

```bash
#!/bin/sh
# Run tests before committing
Rscript -e "testthat::test_dir('tests/testthat')"
```

## Coverage Analysis

Generate and view coverage report:

```r
library(covr)

# Calculate coverage
coverage <- package_coverage(".", type = "tests")

# View in browser
report(coverage)

# Print summary
print(coverage)

# View specific file coverage
file_coverage("global.R")
```

## Getting Help

- **Test Documentation**: See `tests/README.md`
- **testthat Guide**: https://testthat.r-lib.org/
- **Shiny Testing**: https://shiny.rstudio.com/articles/testing-overview.html
- **Project Issues**: Open an issue in the project repository

## Example: Writing Your First Test

1. Create a new test file: `tests/testthat/test-my-feature.R`

```r
# test-my-feature.R
library(testthat)

test_that("my feature works correctly", {
  # Arrange - Set up test data
  input_data <- data.frame(x = 1:5, y = 6:10)

  # Act - Execute the function
  result <- my_feature_function(input_data)

  # Assert - Verify the results
  expect_equal(nrow(result), 5)
  expect_true("output" %in% names(result))
  expect_true(all(result$output > 0))
})
```

2. Run the test:

```r
test_file("tests/testthat/test-my-feature.R")
```

3. View results and iterate until all tests pass

That's it! You're ready to start testing. Happy testing! 🧪
