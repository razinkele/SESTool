# Test Coverage Tracking Guide

## Overview

This document describes the test coverage tracking system for the MarineSABRES SES Shiny application. Coverage tracking ensures code quality by measuring what percentage of the codebase is exercised by automated tests.

---

## Coverage Standards

### Minimum Requirements

| Category | Threshold | Status |
|----------|-----------|--------|
| **Overall Coverage** | 70% | ⚠️ Required |
| **Critical Functions** | 80% | ✅ Recommended |
| **UI Functions** | 60% | ✅ Acceptable |
| **Helper Functions** | 90% | ✅ Recommended |

### Coverage Levels

- **90-100%**: 🟢 Excellent
- **80-89%**: 🟢 Good
- **70-79%**: 🟡 Acceptable
- **60-69%**: 🟡 Needs Improvement
- **<60%**: 🔴 Critical

---

## Generating Coverage Reports

### Method 1: Local Script (Recommended)

```r
# From R console
source("tests/generate_coverage.R")
```

This will:
1. Generate test coverage
2. Create HTML report (`coverage-report.html`)
3. Export detailed CSV (`coverage-details.csv`)
4. Display summary in console
5. Automatically open report in browser (if interactive)

### Method 2: Using covr Package Directly

```r
library(covr)

# Generate coverage
coverage <- package_coverage(type = "tests")

# View in browser
report(coverage)

# Print summary
print(coverage)

# Get percentage
percent_coverage(coverage)
```

### Method 3: CI/CD Automatic Generation

Coverage is automatically generated in GitHub Actions:
- Runs on Linux with R 4.3
- Triggered on push/PR to main/develop
- Reports uploaded as artifacts
- Summary added to GitHub step summary

---

## Understanding Coverage Reports

### HTML Report Structure

The `coverage-report.html` file provides:

1. **Overall Summary**
   - Total coverage percentage
   - Number of functions covered
   - Coverage by file

2. **File-by-File Breakdown**
   - Click any file to see line-by-line coverage
   - Green lines: Covered by tests
   - Red lines: Not covered
   - Gray lines: Non-executable (comments, etc.)

3. **Function Coverage**
   - Coverage for each function
   - Number of times each line was executed

### CSV Report Structure

The `coverage-details.csv` contains:

| Column | Description |
|--------|-------------|
| filename | Source file path |
| functions | Function name |
| first_line | Starting line number |
| last_line | Ending line number |
| value | Coverage indicator (0 = uncovered, >0 = covered) |

---

## Coverage in CI/CD

### Automatic Coverage Generation

Every push/PR triggers:

1. **Test Execution**: All tests run first
2. **Coverage Calculation**: covr analyzes code execution
3. **Report Generation**:
   - HTML report
   - CSV details
   - Markdown summary
4. **Artifact Upload**: All reports saved
5. **Threshold Check**: Fails if <70%
6. **Step Summary**: Coverage displayed in GitHub UI

### Viewing CI/CD Coverage

1. Go to **Actions** tab in GitHub
2. Click latest workflow run
3. Scroll to **Test coverage** step
4. View console output for summary
5. Download **coverage-report** artifact for HTML report

### Coverage Summary in GitHub

The CI/CD workflow adds a coverage summary to the GitHub step summary:

```
## Test Coverage Report

**Overall Coverage**: 75.23%

![Coverage](https://img.shields.io/badge/coverage-75.2%25-yellow)

### Coverage by File (Top 10)

| File | Coverage |
|------|----------|
| data_structure.R | 85.3% |
| network_analysis.R | 78.9% |
...

### Coverage Threshold

- **Required**: 70%
- **Actual**: 75.23%
- **Status**: ✅ PASS
```

---

## Coverage Thresholds

### Enforcement

The CI/CD pipeline enforces a **70% minimum coverage** threshold:

```r
threshold <- 70  # Minimum required
if (pct < threshold) {
  # CI/CD fails
  quit(status = 1)
}
```

### Rationale

- **70%**: Minimum acceptable for production
- **80%**: Target for critical functions
- **90%**: Ideal for well-tested codebases

### Exceptions

Some code is intentionally excluded from coverage:
- UI rendering code (difficult to test)
- Error handling for edge cases
- Deprecated functions
- Platform-specific code

---

## Improving Coverage

### Step 1: Identify Gaps

```r
# Generate coverage report
source("tests/generate_coverage.R")

# Look for "Files Needing Attention" section
# These are files with <70% coverage
```

### Step 2: Analyze Uncovered Code

Open `coverage-report.html` and:
1. Click on low-coverage file
2. Red lines are not covered
3. Identify why:
   - Missing test case?
   - Edge case not tested?
   - Dead code?

### Step 3: Write Tests

For each uncovered line, ask:
- Is this code reachable?
- What inputs trigger this path?
- Is there a test for this scenario?

Example:
```r
# Uncovered code
if (is.null(data)) {
  stop("Data cannot be NULL")
}

# Add test
test_that("function handles NULL data", {
  expect_error(my_function(NULL), "Data cannot be NULL")
})
```

### Step 4: Verify Improvement

```r
# Re-run coverage
source("tests/generate_coverage.R")

# Check if coverage increased
# Target: +5-10% per iteration
```

---

## Coverage Best Practices

### DO ✅

1. **Focus on Critical Paths**
   - Test main workflows thoroughly
   - Cover error handling
   - Test boundary conditions

2. **Test Behavior, Not Implementation**
   ```r
   # Good: Test what it does
   test_that("function returns valid network", {
     result <- build_network(data)
     expect_true(is.igraph(result))
   })

   # Bad: Test how it does it
   test_that("function calls specific internal method", {
     # Too implementation-specific
   })
   ```

3. **Use Helper Functions**
   ```r
   # Reusable mock data
   mock_data <- create_mock_isa_data()
   ```

4. **Test Edge Cases**
   - Empty inputs
   - NULL values
   - Very large datasets
   - Invalid data types

### DON'T ❌

1. **Don't Chase 100% Coverage**
   - Some code is hard to test meaningfully
   - Focus on valuable tests, not just coverage

2. **Don't Write Tests Just for Coverage**
   ```r
   # Bad: Meaningless test
   test_that("function exists", {
     expect_true(exists("my_function"))
   })
   ```

3. **Don't Ignore Low-Value Code**
   - Even simple getters/setters should be tested
   - They might have bugs

4. **Don't Test External Libraries**
   - Trust that shiny, dplyr, etc. are tested
   - Test YOUR usage of them

---

## Coverage Metrics

### Overall Coverage

**Formula**: `(Lines Covered / Total Lines) × 100`

**Interpretation**:
- Includes all R code in the project
- Excludes comments and blank lines
- Weighted by function importance

### Function Coverage

**Formula**: `(Functions with >0% coverage / Total Functions) × 100`

**Interpretation**:
- Percentage of functions that have at least one test
- Useful for finding completely untested functions

### Line Coverage

**Formula**: `(Lines executed / Total executable lines) × 100`

**Interpretation**:
- Most granular metric
- Shows exactly which lines are tested

---

## Coverage Tracking Over Time

### Manual Tracking

Create a coverage log:

```
Date       | Coverage | Change | Notes
-----------|----------|--------|------------------
2024-12-24 | 75.2%    | +0.0%  | Initial baseline
2024-12-25 | 77.1%    | +1.9%  | Added network tests
2024-12-26 | 78.5%    | +1.4%  | Added module tests
```

### Automated Tracking (Future Enhancement)

Potential improvements:
1. **Coverage History Graph**: Plot coverage over time
2. **Per-PR Coverage Delta**: Show coverage change in PRs
3. **Coverage Badges**: Auto-update badge in README
4. **Regression Detection**: Alert if coverage drops

---

## Troubleshooting

### Issue: Coverage Report Empty

**Symptoms**: Report shows 0% or no data

**Solutions**:
```r
# Ensure tests are in correct location
tests/testthat/test-*.R

# Verify tests run successfully
testthat::test_dir("tests/testthat")

# Check that global.R loads properly
source("global.R")
```

### Issue: Coverage Lower Than Expected

**Symptoms**: Coverage unexpectedly low

**Possible Causes**:
1. Tests using `skip_if_not()` too liberally
2. Module stubs not exercising real code
3. Error paths not tested
4. Dead code in codebase

**Solutions**:
```r
# Review skip conditions
grep -r "skip_if_not" tests/

# Check test execution
testthat::test_dir("tests/testthat", reporter = "summary")

# Identify skipped tests
# Look for "SKIP" in output
```

### Issue: Coverage Calculation Slow

**Symptoms**: Takes >5 minutes to generate

**Solutions**:
```r
# Use parallel processing
options(covr.fix_parallel_error = TRUE)
coverage <- package_coverage(type = "tests", quiet = TRUE)

# Exclude slow tests from coverage
# Add to test file:
skip_on_covr()
```

### Issue: CI/CD Coverage Fails

**Symptoms**: CI/CD fails at coverage step

**Check**:
1. View GitHub Actions logs
2. Look for error messages
3. Verify coverage < 70% threshold
4. Check for missing dependencies

---

## Integration with Development Workflow

### Daily Development

```bash
# 1. Write code
# 2. Write tests
# 3. Check coverage
Rscript -e "source('tests/generate_coverage.R')"

# 4. If coverage drops, add more tests
# 5. Commit when coverage is acceptable
git add .
git commit -m "Add feature X (coverage: 76.2%)"
```

### Pre-Commit Checks

Consider adding a pre-commit hook:

```bash
#!/bin/bash
# .git/hooks/pre-commit

# Run tests
Rscript -e "testthat::test_dir('tests/testthat')" || exit 1

# Check coverage
coverage=$(Rscript -e "cat(covr::percent_coverage(covr::package_coverage(type='tests', quiet=TRUE)))")

if (( $(echo "$coverage < 70" | bc -l) )); then
  echo "ERROR: Coverage $coverage% is below 70%"
  exit 1
fi

echo "✓ Tests passed, coverage: $coverage%"
```

### Pull Request Workflow

1. **Create PR**
2. **CI/CD runs automatically**
3. **Review coverage report in artifacts**
4. **Ensure coverage meets threshold**
5. **Merge if coverage acceptable**

---

## Resources

- [covr package documentation](https://covr.r-lib.org/)
- [Testing R Code](https://r-pkgs.org/testing-basics.html)
- [Test Coverage Best Practices](https://testing.googleblog.com/2020/08/code-coverage-best-practices.html)

---

## Contact

For questions about coverage tracking:
- Review this document
- Check `tests/generate_coverage.R` script
- See CI/CD workflow in `.github/workflows/test.yml`
- Open an issue if problems persist

---

**Last Updated**: 2024-12-24
**Coverage Threshold**: 70% minimum
**Target Coverage**: 80%+
