# MarineSABRES SES Application - Testing Framework

## Overview

This document describes the comprehensive testing framework for the MarineSABRES Social-Ecological Systems (SES) Shiny application, with special focus on network analysis functions and loop detection.

## Purpose

The testing framework was created to:
1. **Prevent regressions** - Ensure fixes for hanging issues remain fixed
2. **Validate performance** - Detect performance degradations early
3. **Document behavior** - Provide executable specifications
4. **Enable refactoring** - Allow confident code improvements
5. **Catch edge cases** - Test boundary conditions and error handling

## Test Structure

### Directory Layout

```
tests/
├── run_all_tests.R                      # Master test runner
├── test_loop_detection_comprehensive.R  # Loop detection tests
├── test_network_analysis_functions.R    # All network analysis functions
└── README.md                            # This file
```

### Test Categories

#### 1. **Loop Detection Tests** (`test_loop_detection_comprehensive.R`)

Tests the critical loop detection functionality that was prone to hanging.

**Test Cases:**
- ✅ Small networks complete quickly (<1s)
- ✅ Large sparse networks complete (<5s)
- ✅ Large dense components are skipped with warning
- ✅ Multiple small components work efficiently
- ✅ Empty networks handled gracefully
- ✅ Networks with no cycles return empty
- ✅ max_cycles limit is respected
- ✅ DFS optimizations provide O(1) performance
- ✅ Component size warnings are triggered

**Performance Benchmarks:**
- Small network (10 nodes, ring): < 0.5s
- Medium network (30 nodes, sparse): < 1.5s
- Large sparse (60 nodes, ring): < 3s

#### 2. **Network Analysis Functions Tests** (`test_network_analysis_functions.R`)

Tests all network analysis utilities used throughout the application.

**Test Cases:**

**Network Metrics:**
- ✅ Metrics calculation (nodes, edges, density, centrality)
- ✅ Empty network handling

**MICMAC Analysis:**
- ✅ Influence and exposure calculation
- ✅ Quadrant classification
- ✅ Empty edge handling

**Adjacency Matrix:**
- ✅ Matrix creation and structure
- ✅ Correct dimensions and values

**Loop Classification:**
- ✅ Reinforcing loop identification (even negatives)
- ✅ Balancing loop identification (odd negatives)
- ✅ Edge lookup table optimization

**Leverage Points:**
- ✅ Composite score calculation
- ✅ Top N selection
- ✅ Empty network handling

**Path Analysis:**
- ✅ Shortest path finding
- ✅ Unreachable node handling

**Neighborhood Analysis:**
- ✅ Neighbor identification
- ✅ Degree-based expansion

**Simplification:**
- ✅ Exogenous variable identification
- ✅ SISO variable identification

**Community Detection:**
- ✅ Cluster identification
- ✅ Multiple algorithms support

## Running Tests

### Quick Start

Run all tests:
```bash
cd tests
Rscript run_all_tests.R
```

### Run Individual Test Suites

Loop detection only:
```bash
cd tests
Rscript test_loop_detection_comprehensive.R
```

Network analysis only:
```bash
cd tests
Rscript test_network_analysis_functions.R
```

### Expected Output

Successful run:
```
═══════════════════════════════════════════════════════════════════
  MarineSABRES SES Application - Comprehensive Test Suite
═══════════════════════════════════════════════════════════════════

▶ Running: Loop Detection Tests
──────────────────────────────────────────────────────────────────
✅ Loop Detection Tests completed in 3.45s

▶ Running: Network Analysis Functions
──────────────────────────────────────────────────────────────────
✅ Network Analysis Functions completed in 2.12s

═══════════════════════════════════════════════════════════════════
  TEST SUMMARY
═══════════════════════════════════════════════════════════════════

Total Test Suites: 2
Passed:            2 ✅
Total Time:        5.57 seconds

✅ All tests passed successfully!
```

## Test Design Principles

### 1. **Fast Feedback**
- Most tests complete in <1 second
- Total suite runs in <10 seconds
- Use timeouts to prevent hanging

### 2. **Comprehensive Coverage**
- Test happy paths
- Test edge cases
- Test error conditions
- Test performance boundaries

### 3. **Clear Assertions**
- Each test has a single, clear purpose
- Descriptive test names
- Informative failure messages

### 4. **Isolated Tests**
- Tests don't depend on each other
- Each test creates its own data
- No shared mutable state

### 5. **Performance Validation**
- Benchmark critical functions
- Detect performance regressions
- Validate optimization effectiveness

## Critical Test Cases for Loop Detection

### Why Loop Detection Testing is Critical

Loop detection was prone to **indefinite hanging** with certain network structures. The test suite specifically validates:

#### 1. **Large Strongly Connected Components (SCCs)**

**Problem**: 40+ node SCCs with >4% density cause exponential path explosion

**Test**: Creates a 40-node ring with 120 edges (7.7% density)
```r
test_that("Large dense component is skipped with warning", {
  # 40 nodes, 7.7% density
  expect_warning(
    result <- find_all_cycles(nodes, edges, max_length = 8, max_cycles = 200),
    "Skipping large dense component"
  )
  expect_true(elapsed < 5)  # Must skip quickly, not hang
})
```

#### 2. **DFS Optimization Validation**

**Problem**: O(n²) data structures caused slowdowns

**Test**: Validates O(1) performance on moderately complex networks
```r
test_that("DFS uses O(1) data structures", {
  # 25 nodes with moderate density
  result <- find_all_cycles(nodes, edges, max_length = 8, max_cycles = 200)
  expect_true(elapsed < 2)  # With O(n²) this would take >10s
})
```

#### 3. **Cycle Limit Enforcement**

**Problem**: Without limits, detection could run indefinitely

**Test**: Ensures max_cycles is respected
```r
test_that("Detection respects max_cycles limit", {
  result <- find_all_cycles(nodes, edges, max_length = 8, max_cycles = 50)
  expect_true(length(result) <= 50)
})
```

## Adding New Tests

### Test Template

```r
test_that("Description of what this tests", {
  # Arrange: Set up test data
  nodes <- data.frame(...)
  edges <- data.frame(...)

  # Act: Run the function
  result <- function_to_test(nodes, edges)

  # Assert: Verify behavior
  expect_true(condition)
  expect_equal(result, expected)
})
```

### Performance Test Template

```r
test_that("Function completes within time limit", {
  start_time <- Sys.time()

  result <- function_to_test(large_input)

  elapsed <- as.numeric(Sys.time() - start_time, units = "secs")
  expect_true(elapsed < time_limit,
              info = sprintf("Took %.3f seconds", elapsed))
})
```

### Edge Case Template

```r
test_that("Function handles edge case gracefully", {
  # Empty input
  result1 <- function_to_test(empty_input)
  expect_equal(result1, expected_for_empty)

  # NULL input
  expect_error(function_to_test(NULL), "expected error message")

  # Single element
  result2 <- function_to_test(single_element)
  expect_true(valid_result(result2))
})
```

## Continuous Integration

### Pre-commit Checklist

Before committing changes to network analysis functions:

1. ✅ Run all tests: `Rscript tests/run_all_tests.R`
2. ✅ All tests pass
3. ✅ No new warnings introduced
4. ✅ Performance benchmarks within acceptable ranges

### When to Add Tests

Add tests when:
- **Fixing a bug**: Test should fail before fix, pass after
- **Adding a feature**: Test the new functionality
- **Optimizing performance**: Benchmark test to prevent regressions
- **Refactoring**: Ensure behavior unchanged

## Performance Regression Detection

### Baseline Performance

Critical functions and their maximum acceptable times:

| Function | Max Time | Input Size |
|----------|----------|------------|
| `find_all_cycles` (small) | 0.5s | 10 nodes, ring |
| `find_all_cycles` (medium) | 1.5s | 30 nodes, sparse |
| `find_all_cycles` (large sparse) | 3s | 60 nodes, ring |
| `calculate_network_metrics` | 0.5s | 10 nodes |
| `calculate_micmac` | 0.5s | 10 nodes |
| `identify_leverage_points` | 0.5s | 10 nodes |

### Detecting Regressions

If tests start failing with timeout errors:
1. Run tests multiple times to confirm (not just system load)
2. Compare performance against baseline
3. Use R profiler to identify bottleneck:
   ```r
   Rprof("profile.out")
   # Run slow function
   Rprof(NULL)
   summaryRprof("profile.out")
   ```
4. Review recent changes to the function
5. Check if new test case exposed an edge case

## Known Limitations

### Tests Don't Cover

1. **UI/Shiny Interactions**: Requires separate integration testing
2. **File I/O**: Save/load operations
3. **Large-scale Performance**: Tests use small networks for speed
4. **User Input Validation**: Form validation in Shiny modules
5. **Visualization**: Plot generation and rendering

### Future Test Additions

Potential areas for expansion:
- Integration tests with real SES datasets
- Stress tests with 1000+ node networks
- Memory usage tests
- Parallel execution tests
- API endpoint tests (if applicable)

## Troubleshooting

### Tests Hang

**Symptom**: Test runner freezes without output

**Solutions**:
1. Identify which test is hanging (add verbose output)
2. Add timeout to test:
   ```r
   setTimeLimit(elapsed = 10)
   result <- slow_function()
   setTimeLimit(elapsed = Inf)
   ```
3. Check if test creates problematic network structure
4. Review loop detection safeguards (SCC size limits)

### Tests Fail Intermittently

**Symptom**: Tests pass sometimes, fail others

**Common Causes**:
1. **Random data**: Use `set.seed()` for reproducibility
2. **Floating point comparison**: Use `expect_equal(x, y, tolerance = 1e-6)`
3. **System load**: Performance tests may timeout on busy systems
4. **File permissions**: Check write access for temp files

### Performance Tests Too Strict

**Symptom**: Tests fail on slower machines

**Solution**: Adjust time limits in tests based on machine capabilities
```r
# Instead of hardcoded limit
expect_true(elapsed < 1.0)

# Use environment variable or multiplier
time_limit <- as.numeric(Sys.getenv("TEST_TIME_MULTIPLIER", "1.0"))
expect_true(elapsed < 1.0 * time_limit)
```

## Test Maintenance

### When to Update Tests

- **Function signature changes**: Update test calls
- **Expected behavior changes**: Update assertions
- **Performance improvements**: Tighten time limits
- **New edge cases discovered**: Add test cases

### Test Review Checklist

Periodically review tests for:
- [ ] Outdated assertions
- [ ] Slow tests that could be optimized
- [ ] Missing coverage for new functions
- [ ] Overly strict performance limits
- [ ] Duplicate test logic

## References

- **testthat Documentation**: https://testthat.r-lib.org/
- **igraph Testing**: https://igraph.org/r/doc/
- **Loop Detection Fix**: See `LOOP_ANALYSIS_HANG_FIX_V2.md`
- **Network Analysis Functions**: `functions/network_analysis.R`

## Contact

For questions about the testing framework:
- Review test file comments
- Check related documentation (LOOP_ANALYSIS_HANG_FIX_V2.md)
- Examine function documentation in source files

---

**Last Updated**: 2025-11-10
**Version**: 1.0
**Test Coverage**: Loop Detection, Network Analysis Functions
**Total Tests**: 25+ test cases across 2 suites
