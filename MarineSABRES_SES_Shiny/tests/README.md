# Testing Framework for MarineSABRES SES Shiny Application

This directory contains the comprehensive testing framework for the MarineSABRES Social-Ecological Systems Shiny Application.

## Overview

The testing framework is built using the `testthat` package and includes:

- **Unit Tests**: Tests for individual functions and utilities
- **Module Tests**: Tests for Shiny modules (UI and server)
- **Integration Tests**: End-to-end workflow tests
- **Test Utilities**: Helper functions and mock data generators

## Directory Structure

```
tests/
├── testthat.R              # Main test runner
├── testthat/
│   ├── setup.R             # Test environment setup
│   ├── helpers.R           # Test utility functions
│   ├── test-global-utils.R # Tests for global.R utilities
│   ├── test-data-structure.R # Tests for data structure functions
│   ├── test-network-analysis.R # Tests for network analysis
│   ├── test-modules.R      # Tests for Shiny modules
│   └── test-integration.R  # Integration tests
└── README.md               # This file
```

## Running Tests

### Run All Tests

From the project root directory in R:

```r
# Load required packages
library(testthat)

# Run all tests
test_dir("tests/testthat")
```

Or from the command line:

```bash
# Run all tests (includes comprehensive test runner)
Rscript tests/run_all_tests.R

# Run testthat suite only
Rscript -e "testthat::test_dir('tests/testthat')"
```

### Run Specific Test Files

```r
# Run only global utils tests
test_file("tests/testthat/test-global-utils.R")

# Run only module tests
test_file("tests/testthat/test-modules.R")

# Run only integration tests
test_file("tests/testthat/test-integration.R")

# Run only connection review tests (NEW in v1.5.2)
test_file("tests/testthat/test-connection-review.R")
```

### Run Tests Automatically on File Changes

```r
# Watch for file changes and run tests
testthat::auto_test(".", "tests/testthat")
```

## Test Coverage

### Unit Tests (`test-global-utils.R`)

Tests for utility functions in `global.R`:
- `%||%` operator
- `generate_id()`
- `format_date_display()`
- `is_valid_email()`
- `parse_connection_value()`
- `sanitize_color()`
- `sanitize_filename()`
- `validate_project_structure()`
- `safe_get_nested()`
- `init_session_data()`
- `validate_element_data()`
- `validate_isa_data()`

### Data Structure Tests (`test-data-structure.R`)

Tests for functions in `functions/data_structure.R`:
- Empty ISA data creation
- Adjacency matrix creation
- Data export/import
- Element merging
- Data structure conversions

### Network Analysis Tests (`test-network-analysis.R`)

Tests for functions in `functions/network_analysis.R`:
- Network creation from ISA data
- Centrality calculations (degree, betweenness, closeness)
- Feedback loop detection
- Loop type classification (reinforcing/balancing)
- Network metrics (density, diameter, path length)
- Network simplification
- Pathway analysis
- Node importance ranking

### Connection Review Tests (`test-connection-review.R`) - NEW in v1.5.2

Tests for connection review module bug fixes:
- Core functionality (module initialization, batch categorization)
- Amendment application (polarity, strength, confidence)
- Regression tests for 4 critical bugs:
  - Bug #1: Amendment data not saved
  - Bug #2: Missing on_approve callback
  - Bug #3: Amendments lost during finalization
  - Bug #4: Unwanted auto-navigation
- Edge cases (empty lists, partial amendments, rejections)

### Module Tests (`test-modules.R`)

Tests for Shiny modules:
- ISA Data Entry module
- PIMS modules (Project, Stakeholders, Resources, Data, Evaluation)
- CLD Visualization module
- Analysis Tools modules (Metrics, Loops, BOT, Simplification)
- Entry Point module
- AI ISA Assistant module
- Response & Validation modules
- Scenario Builder module

### Integration Tests (`test-integration.R`)

End-to-end workflow tests:
- Complete ISA workflow (create, connect, visualize)
- PIMS to ISA data flow
- Save and load project workflow
- Network analysis workflow
- Export workflow (JSON, CSV, Excel)

## Test Utilities

The `helpers.R` file provides utility functions for testing:

### Mock Data Generators

- `create_mock_isa_data()`: Generate mock ISA data structure
- `create_mock_project_data()`: Generate complete project data
- `create_mock_cld_data()`: Generate CLD nodes and edges
- `create_mock_network()`: Generate igraph network
- `create_mock_adjacency_matrix()`: Generate adjacency matrix

### Custom Expectations

- `expect_shiny_tag()`: Verify Shiny UI elements
- `expect_valid_network()`: Verify network structure
- `expect_valid_project_data()`: Verify project data structure

### Helper Functions

- `create_temp_test_file()`: Create temporary files for testing
- `cleanup_test_files()`: Clean up test files
- `compare_dfs_unordered()`: Compare data frames ignoring row order
- `MockShinySession`: Mock session object for testing

## Writing New Tests

### Example: Unit Test

```r
test_that("my_function works correctly", {
  # Arrange
  input_data <- data.frame(x = 1:5)

  # Act
  result <- my_function(input_data)

  # Assert
  expect_equal(nrow(result), 5)
  expect_true("output" %in% names(result))
})
```

### Example: Module Test

```r
test_that("my_module server logic works", {
  testServer(my_module_server, {
    # Set up test inputs
    session$setInputs(input_name = "test_value")

    # Verify outputs
    expect_equal(output$result, expected_value)
  })
})
```

### Example: Integration Test

```r
test_that("complete workflow executes successfully", {
  # Step 1: Initialize
  project <- init_session_data()

  # Step 2: Add data
  project$data$isa_data <- create_mock_isa_data()

  # Step 3: Process
  result <- process_isa_data(project)

  # Step 4: Verify
  expect_true(validate_project_structure(result))
})
```

## Test Best Practices

1. **Isolation**: Each test should be independent and not rely on other tests
2. **Clarity**: Use descriptive test names that explain what is being tested
3. **AAA Pattern**: Arrange, Act, Assert - organize tests in three clear sections
4. **Mock Data**: Use helper functions to create consistent mock data
5. **Edge Cases**: Test boundary conditions and error cases
6. **Coverage**: Aim for high code coverage, but focus on critical paths
7. **Performance**: Keep tests fast - use `skip_if_not()` for optional features
8. **Cleanup**: Always clean up temporary files and resources

## Continuous Integration

### GitHub Actions (Example)

```yaml
name: R Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: r-lib/actions/setup-r@v2
      - name: Install dependencies
        run: |
          install.packages(c("testthat", "shiny", "igraph"))
      - name: Run tests
        run: |
          testthat::test_dir("tests/testthat")
```

## Troubleshooting

### Common Issues

**Issue**: Tests fail with "function not found"
- **Solution**: Ensure all required files are sourced in `setup.R`

**Issue**: Tests fail due to missing packages
- **Solution**: Install required packages: `testthat`, `shiny`, `shinytest2`, `igraph`

**Issue**: Tests pass locally but fail in CI
- **Solution**: Check for environment-specific dependencies (file paths, system libraries)

**Issue**: Module tests fail
- **Solution**: Ensure modules are properly sourced before testing

## Test Coverage Analysis

To analyze test coverage:

```r
# Install covr package
install.packages("covr")

# Generate coverage report
library(covr)
coverage <- package_coverage(".", type = "tests")

# View report
report(coverage)
```

## Contributing

When adding new features or fixing bugs:

1. Write tests first (TDD approach recommended)
2. Ensure all existing tests pass
3. Add tests for new functionality
4. Update this README if adding new test categories
5. Aim for >80% code coverage on critical functions

## Resources

- [testthat documentation](https://testthat.r-lib.org/)
- [shinytest2 documentation](https://rstudio.github.io/shinytest2/)
- [R Packages - Testing](https://r-pkgs.org/testing-basics.html)
- [Testing Shiny Apps](https://shiny.rstudio.com/articles/testing-overview.html)

## Contact

For questions about the testing framework, please contact the development team or open an issue in the project repository.
