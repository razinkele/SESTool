# End-to-End Testing Guide

## Overview

This document describes the end-to-end (E2E) testing framework for the MarineSABRES SES Shiny application using `shinytest2`.

## What are E2E Tests?

End-to-end tests verify complete user workflows in a real browser environment. Unlike unit tests that test individual functions, E2E tests simulate actual user interactions with the application.

## Test Coverage

We have implemented 5 critical E2E tests covering the most important user workflows:

### Test 1: App Launch and Dashboard Navigation
**File**: `test-app-e2e.R`, Line ~20
**Purpose**: Verifies that the app launches successfully and the dashboard is accessible
**What it tests**:
- App initialization
- Default Caribbean template auto-loading
- Sidebar menu rendering
- Dashboard value boxes display
- Basic navigation

### Test 2: Language Switching Workflow
**File**: `test-app-e2e.R`, Line ~77
**Purpose**: Verifies the i18n system and dynamic UI updates
**What it tests**:
- Language selector presence and functionality
- Switching between English, Spanish, and French
- UI persistence after language changes
- Translation system reliability

### Test 3: Create SES Method Selection
**File**: `test-app-e2e.R`, Line ~123
**Purpose**: Verifies navigation through different SES creation methods
**What it tests**:
- Navigation to Create SES chooser
- Template-based creation navigation
- AI assistant navigation
- Standard entry navigation
- Module initialization

### Test 4: CLD Visualization
**File**: `test-app-e2e.R`, Line ~164
**Purpose**: Verifies network visualization rendering with auto-loaded data
**What it tests**:
- CLD module initialization
- Visualization container rendering
- Auto-loaded template data integration

### Test 5: Complete Navigation Flow
**File**: `test-app-e2e.R`, Line ~194
**Purpose**: Verifies navigation across all major application sections
**What it tests**:
- Entry point
- Dashboard
- PIMS modules
- Create SES
- CLD visualization
- Analysis tools
- Response measures
- Export/reports
- Circular navigation back to dashboard

## Running E2E Tests Locally

### Prerequisites

1. **Install Chrome/Chromium**
   - The tests require a Chromium-based browser
   - Chrome or Chromium must be installed and accessible

2. **Install R packages**
   ```r
   install.packages("shinytest2")
   install.packages("testthat")
   ```

3. **Install ChromeDriver** (if not already installed)
   ```r
   # shinytest2 can install it automatically
   shinytest2::install_chromote()
   ```

### Running the Tests

#### Option 1: Run all E2E tests
```r
# From R console in project root
library(testthat)
test_file("tests/testthat/test-app-e2e.R")
```

#### Option 2: Run specific test
```r
library(testthat)
# Run with filter
test_file("tests/testthat/test-app-e2e.R",
          filter = "App launches successfully")
```

#### Option 3: Run from command line
```bash
# From project root
Rscript -e "testthat::test_file('tests/testthat/test-app-e2e.R')"
```

#### Option 4: Run all tests (including E2E)
```r
# This runs ALL tests including unit and E2E
testthat::test_dir("tests/testthat")
```

### Interactive Mode

For debugging, you can run the tests interactively:

```r
library(shinytest2)

# Create an app driver
app <- AppDriver$new(
  app_dir = ".",
  name = "debug-session",
  height = 1000,
  width = 1200
)

# The browser window will stay open
# You can interact with it manually
app$view()

# Get current values
app$get_values()

# Interact with app
app$set_inputs(sidebar_menu = "dashboard")

# When done
app$stop()
```

## CI/CD Integration

The E2E tests run automatically in GitHub Actions:

- **Trigger**: On push/PR to `main` or `develop` branches
- **When**: Only runs on R version 4.3
- **Platforms**: Linux, macOS, Windows
- **Browser**: Chromium in headless mode
- **Timeout**: 30 seconds per operation

### Viewing CI/CD Results

1. Go to the **Actions** tab in GitHub
2. Click on the latest workflow run
3. Expand the "Run shinytest2 E2E tests" step
4. If tests fail, download the screenshots artifact

## Test Configuration

### Timeouts
```r
E2E_TIMEOUT <- 10000      # 10 seconds for app operations
E2E_WAIT_TIME <- 2000     # 2 seconds for UI rendering
```

### Environment Variables (CI/CD)
- `CHROMOTE_CHROME=chromium-browser`: Use Chromium instead of Chrome
- `SHINYTEST2_TIMEOUT=30000`: Increase timeout for slow CI environments

## Debugging Failed Tests

### 1. Check Screenshots
When tests fail, screenshots are automatically saved to `tests/testthat/screenshots/`

### 2. Run in Interactive Mode
```r
# Use AppDriver$new() interactively (see above)
# This lets you see what's happening in the browser
```

### 3. Increase Timeouts
```r
# In test-app-e2e.R, increase these values:
E2E_TIMEOUT <- 30000      # 30 seconds
E2E_WAIT_TIME <- 5000     # 5 seconds
```

### 4. Check Browser Logs
```r
app <- AppDriver$new(...)
logs <- app$get_logs()
print(logs)
```

### 5. Inspect Current State
```r
# Get all current input/output values
app$get_values()

# Get HTML of specific element
app$get_html(".content-wrapper")

# Get screenshot
app$get_screenshot("debug.png")
```

## Writing New E2E Tests

### Test Template
```r
test_that("E2E: Your test description", {
  # 1. Launch app
  app <- AppDriver$new(
    app_dir = "../..",
    name = "your-test-name",
    height = 1000,
    width = 1200,
    wait = TRUE,
    timeout = E2E_TIMEOUT,
    load_timeout = E2E_TIMEOUT
  )

  # 2. Wait for initialization
  app$wait_for_idle(timeout = E2E_WAIT_TIME)

  # 3. Interact with app
  app$set_inputs(sidebar_menu = "your_tab",
                 wait_ = TRUE,
                 timeout_ = E2E_TIMEOUT)

  # 4. Verify results
  active_tab <- app$get_value(input = "sidebar_menu")
  expect_equal(active_tab, "your_tab")

  # 5. Clean up
  app$stop()
})
```

### Best Practices

1. **Always wait for idle** after interactions
   ```r
   app$set_inputs(...)
   app$wait_for_idle(timeout = E2E_WAIT_TIME)
   ```

2. **Use descriptive test names** with "E2E:" prefix
   ```r
   test_that("E2E: User can export project to Excel", { ... })
   ```

3. **Clean up** by stopping the app
   ```r
   app$stop()
   expect_false(app$is_running())
   ```

4. **Verify state changes** explicitly
   ```r
   # Before
   initial_value <- app$get_value(input = "x")

   # Change
   app$set_inputs(x = "new_value")

   # After
   new_value <- app$get_value(input = "x")
   expect_equal(new_value, "new_value")
   ```

5. **Use meaningful wait times**
   - Fast operations: 1-2 seconds
   - Network/render operations: 2-5 seconds
   - Complex workflows: 5-10 seconds

## Troubleshooting

### "Chrome not found" Error
```r
# Install Chrome/Chromium
# Linux: sudo apt-get install chromium-browser
# macOS: brew install --cask google-chrome
# Windows: choco install googlechrome

# Or specify Chrome path
Sys.setenv(CHROMOTE_CHROME = "/path/to/chrome")
```

### "App failed to start" Error
- Check that `app.R` exists in the root directory
- Verify all dependencies are installed
- Run the app manually first: `shiny::runApp()`

### "Timeout waiting for app" Error
- Increase `load_timeout` in `AppDriver$new()`
- Check app console for startup errors
- Verify test fixtures are in place

### "Element not found" Error
- Use `app$wait_for_idle()` after navigation
- Check CSS selector is correct
- Verify element exists: `app$get_html(".your-selector")`

### Tests Pass Locally but Fail in CI
- Increase timeouts for CI environment
- Check for race conditions
- Verify all dependencies installed in CI
- Check for platform-specific issues

## Performance Considerations

E2E tests are slower than unit tests:

- **Unit test**: ~0.01 seconds
- **E2E test**: ~5-15 seconds

To maintain fast test suite:
- Keep E2E tests focused on critical workflows
- Run E2E tests only on specific R version in CI (4.3)
- Use unit tests for detailed function testing
- Reserve E2E for integration verification

## Future Enhancements

Potential additions to the E2E test suite:

1. **Data Entry Workflow**: Test complete ISA data entry
2. **File Upload**: Test Excel import functionality
3. **Export Workflows**: Test JSON/Excel/CSV exports
4. **Analysis Tools**: Test network metrics calculations
5. **Response Measures**: Test scenario builder
6. **Project Save/Load**: Test complete save and restore cycle

## Resources

- [shinytest2 Documentation](https://rstudio.github.io/shinytest2/)
- [Testing Shiny Apps](https://mastering-shiny.org/scaling-testing.html)
- [Chromote Package](https://github.com/rstudio/chromote)

## Visual Regression Testing

Visual regression tests capture full-page screenshots and compare them
pixel-by-pixel against stored baselines to detect unintended UI changes.

### Overview

- **Test file**: `tests/testthat/test-visual-regression.R`
- **Helper utilities**: `tests/testthat/helper-visual.R`
- **Baseline storage**: `tests/visual-regression/` (PNG files)
- **Comparison engine**: pixel-level diff via the `png` R package

The tests are skipped on CI (`skip_on_ci()`) because baselines are
platform-dependent and need manual review before acceptance.

### Pages Covered

| Test | Sidebar Tab | Threshold |
|------|-------------|-----------|
| Dashboard | `dashboard` | 3% |
| CLD Visualization | `cld_viz` | 5% |
| ISA Data Entry | `create_ses_standard` | 3% |
| Analysis Metrics | `analysis_metrics` | 4% |
| Analysis Loops | `analysis_loops` | 4% |
| Report Generation | `prepare_report` | 3% |
| Export | `export` | 3% |
| Create SES Chooser | `create_ses_choose` | 3% |

CLD visualization uses a higher threshold (5%) because the network layout
engine introduces minor non-deterministic positioning.

### Prerequisites

```r
install.packages("shinytest2")
install.packages("png")        # For pixel-level comparison
install.packages("testthat")
```

Chrome or Chromium must be installed (same requirement as the functional
E2E tests).

### Running Visual Tests

```r
# Run all visual regression tests
testthat::test_file("tests/testthat/test-visual-regression.R")

# Run a single visual test
testthat::test_file("tests/testthat/test-visual-regression.R",
                    filter = "dashboard")
```

On the **first run**, each test creates a baseline screenshot and skips
with a message. Re-run to perform the actual comparison.

### Updating Baselines

After an intentional UI change, update baselines to accept the new
appearance:

```r
# Source the helper to get update_baselines()
source("tests/testthat/helper-visual.R")

# Update all baselines
update_baselines()

# Update specific baselines only
update_baselines(test_names = c("dashboard", "cld_visualization"))
```

Then commit the updated PNG files in `tests/visual-regression/`.

### Helper Functions

`helper-visual.R` provides three main utilities:

- **`setup_app_with_data(name)`** -- Launches the app with a
  consistent viewport (1280x900) and waits for the auto-loaded Caribbean
  template to settle.
- **`compare_screenshot(app, test_name, threshold)`** -- Takes a
  screenshot, compares to the stored baseline, and fails if the
  pixel difference exceeds the threshold.
- **`update_baselines(test_names)`** -- Copies current screenshots
  over the baselines after manual verification.

### Troubleshooting

#### "Baseline created ... Re-run to compare"
This is expected on the first run. The baseline has been saved; run the
test again to perform the comparison.

#### Pixel difference exceeds threshold
1. Check the `_current.png` file in the temp directory shown in the
   failure message.
2. If the change is intentional, run `update_baselines("test_name")`.
3. If not, investigate the UI change that caused the regression.

#### "Screenshot dimensions changed"
The viewport size has changed or the page layout shifted significantly.
Review the current screenshot, then either fix the layout or update the
baseline.

#### Tests fail on a different machine
Baselines are platform- and font-dependent. Each developer should
generate their own baselines on first run. Consider keeping baselines
out of version control if the team uses mixed OS environments.

## Support

For issues with E2E tests:
1. Check this documentation
2. Review test output and screenshots
3. Run tests interactively for debugging
4. Check GitHub Actions logs for CI failures
5. Create an issue with full error message and screenshots
