# Codebase Optimization - Action Plan

**Date**: 2024-12-24
**Priority**: Execute Phase 1 (Quick Wins) immediately
**Status**: Ready to implement

---

## 🎯 Immediate Actions (This Session)

### Quick Win #1: Remove Excessive Debug Logging
**Time**: 30 minutes
**Impact**: Immediate performance improvement, cleaner logs
**Risk**: LOW

#### Step 1: Update debug_log helper

**File**: `global.R:265-273`

Current:
```r
debug_log <- function(message, category = "INFO") {
  if (Sys.getenv("MARINESABRES_DEBUG") == "TRUE") {
    timestamp <- format(Sys.time(), "[%Y-%m-%d %H:%M:%S]")
    cat(sprintf("%s %s: %s\n", timestamp, category, message))
  }
}
```

**Action**: Already good! This helper exists but isn't used.

#### Step 2: Create utility script to wrap debug statements

**Create**: `scripts/wrap_debug_logging.R`

```r
#!/usr/bin/env Rscript
# Wraps all cat() and print() statements in debug_log()

library(stringr)

wrap_debug_in_file <- function(file_path) {
  if (!file.exists(file_path)) return(invisible())

  lines <- readLines(file_path)
  modified <- FALSE

  # Pattern: cat("message")
  # Replace: debug_log("message")
  for (i in seq_along(lines)) {
    # Skip if already using debug_log
    if (grepl("debug_log\\(", lines[i])) next

    # Match cat() calls
    if (grepl("^\\s*cat\\(", lines[i])) {
      # Extract message
      msg <- str_match(lines[i], 'cat\\("(.+)"')
      if (!is.na(msg[2])) {
        lines[i] <- str_replace(lines[i], 'cat\\("(.+)"', 'debug_log("\\1"')
        modified <- TRUE
      }
    }
  }

  if (modified) {
    writeLines(lines, file_path)
    message("Updated: ", file_path)
  }
}

# Files to process
files_to_update <- c(
  "functions/report_generation.R",
  "app.R",
  "modules/ai_isa_assistant_module.R"
  # Add more as needed
)

for (file in files_to_update) {
  wrap_debug_in_file(file)
}
```

**Execution**:
```r
source("scripts/wrap_debug_logging.R")
```

**Expected Result**: ~1,200 debug statements controlled by environment variable

---

### Quick Win #2: Extract Magic Numbers to Constants
**Time**: 20 minutes
**Impact**: Better maintainability
**Risk**: LOW

#### Add to constants.R

**File**: `constants.R`

**Add these constants**:
```r
# ==============================================================================
# UI CONSTANTS
# ==============================================================================

# Box and panel heights
UI_BOX_HEIGHT_DEFAULT <- 400
UI_BOX_HEIGHT_LARGE <- 500
UI_BOX_HEIGHT_SMALL <- 300

# Plot dimensions
PLOT_HEIGHT_DEFAULT <- 500
PLOT_WIDTH_DEFAULT <- 800
PLOT_MARGINS <- c(0, 0, 2, 0)  # bottom, left, top, right

# ==============================================================================
# FILE UPLOAD CONSTANTS
# ==============================================================================

# Maximum file upload size
MAX_UPLOAD_SIZE_MB <- 100
MAX_UPLOAD_SIZE_BYTES <- MAX_UPLOAD_SIZE_MB * 1024^2

# Allowed file extensions
ALLOWED_EXCEL_EXTENSIONS <- c(".xlsx", ".xls")
ALLOWED_JSON_EXTENSIONS <- c(".json")
ALLOWED_RDS_EXTENSIONS <- c(".rds")

# ==============================================================================
# VISUALIZATION CONSTANTS
# ==============================================================================

# Node sizes for network visualization
NODE_SIZE_SMALL <- 10
NODE_SIZE_MEDIUM <- 15
NODE_SIZE_LARGE <- 20

# Edge widths
EDGE_WIDTH_WEAK <- 1
EDGE_WIDTH_MEDIUM <- 2
EDGE_WIDTH_STRONG <- 3

# ==============================================================================
# ANALYSIS CONSTANTS
# ==============================================================================

# Threshold for significance
SIGNIFICANCE_THRESHOLD <- 0.05
CORRELATION_THRESHOLD <- 0.7

# Network analysis
MIN_LOOP_LENGTH <- 2
MAX_LOOP_LENGTH <- 10

# ==============================================================================
# TIMEOUT CONSTANTS
# ==============================================================================

# Processing timeouts (milliseconds)
TIMEOUT_SHORT <- 5000
TIMEOUT_MEDIUM <- 10000
TIMEOUT_LONG <- 30000
```

#### Update files to use constants

**Example**: Replace in `app.R:172`
```r
# Before
height = 400

# After
height = UI_BOX_HEIGHT_DEFAULT
```

**Files to update**:
1. `app.R` - UI heights
2. `global.R` - File upload size
3. `functions/report_generation.R` - Plot margins
4. `modules/*_module.R` - Various UI constants

---

### Quick Win #3: Fix Source Path Fragility
**Time**: 30 minutes
**Impact**: Reliable deployment
**Risk**: LOW

#### Step 1: Add project root helper to global.R

**File**: `global.R`

**Add at top** (after package loading):
```r
# ==============================================================================
# PROJECT ROOT ESTABLISHMENT
# ==============================================================================

# Establish project root for reliable file sourcing
if (!exists("PROJECT_ROOT")) {
  # Try to find project root by looking for app.R
  current_dir <- getwd()

  find_project_root <- function(start_dir = getwd()) {
    dir <- start_dir
    # Look up directory tree for app.R
    while (dir != dirname(dir)) {  # Not at filesystem root
      if (file.exists(file.path(dir, "app.R"))) {
        return(dir)
      }
      dir <- dirname(dir)
    }
    # Fallback to current directory
    return(start_dir)
  }

  PROJECT_ROOT <- find_project_root()
  message("Project root: ", PROJECT_ROOT)
}

# Helper to get project file path
get_project_file <- function(...) {
  file.path(PROJECT_ROOT, ...)
}
```

#### Step 2: Update modules to use helper

**Example**: `modules/template_ses_module.R:10-24`

**Before**:
```r
if (file.exists("modules/connection_review_tabbed.R")) {
  source("modules/connection_review_tabbed.R", local = TRUE)
} else if (file.exists("../modules/connection_review_tabbed.R")) {
  source("../modules/connection_review_tabbed.R", local = TRUE)
} else if (file.exists("../../modules/connection_review_tabbed.R")) {
  source("../../modules/connection_review_tabbed.R", local = TRUE)
}
```

**After**:
```r
source(get_project_file("modules/connection_review_tabbed.R"), local = TRUE)
```

**Files to update**:
- `modules/template_ses_module.R`
- `modules/ai_isa_assistant_module.R`
- `modules/import_data_module.R`
- Any other modules with path fallbacks

---

### Quick Win #4: Simplify Complex Conditionals
**Time**: 20 minutes
**Impact**: Better readability
**Risk**: LOW

#### Extract helper functions

**File**: `functions/data_structure.R` or `utils.R`

**Add helpers**:
```r
#' Check if ISA data structure is completely empty
#'
#' @param isa_data list ISA data structure
#' @return logical TRUE if all element types are empty
is_empty_isa_data <- function(isa_data) {
  if (is.null(isa_data)) return(TRUE)

  element_types <- c("drivers", "activities", "pressures",
                     "marine_processes", "ecosystem_services",
                     "goods_benefits", "responses")

  all(sapply(element_types, function(type) {
    is_empty(isa_data[[type]])
  }))
}

#' Check if a data frame is empty (NULL or 0 rows)
#'
#' @param df data.frame or NULL
#' @return logical TRUE if NULL or has 0 rows
is_empty <- function(df) {
  is.null(df) || (is.data.frame(df) && nrow(df) == 0)
}
```

#### Update app.R

**File**: `app.R:308-345`

**Before**:
```r
if (is_empty(isa$drivers) && is_empty(isa$activities) &&
    is_empty(isa$pressures) && is_empty(isa$marine_processes) &&
    is_empty(isa$ecosystem_services) && is_empty(isa$goods_benefits) &&
    is_empty(isa$responses)) {
  # Load template
}
```

**After**:
```r
if (is_empty_isa_data(isa)) {
  # Load template
}
```

**Much clearer!**

---

## 📋 Verification Checklist

After implementing quick wins:

### Debug Logging
- [ ] Run app with `MARINESABRES_DEBUG=FALSE` (default)
- [ ] Verify no debug output in console
- [ ] Run with `MARINESABRES_DEBUG=TRUE`
- [ ] Verify debug output appears
- [ ] Check CI/CD logs are cleaner

### Constants
- [ ] Search codebase for remaining magic numbers
- [ ] Verify all constants are used (no unused)
- [ ] Run app - all UI should look the same
- [ ] Check tests still pass

### Source Paths
- [ ] Run app from project root - works
- [ ] Run app from subdirectory - works
- [ ] Run tests - all pass
- [ ] Check no source() errors in logs

### Simplified Conditionals
- [ ] App behavior unchanged
- [ ] Code is more readable
- [ ] Tests pass
- [ ] No regressions

---

## 🧪 Testing Strategy

### Before Making Changes
```r
# Run full test suite
testthat::test_dir("tests/testthat")

# Capture baseline
baseline_results <- test_dir("tests/testthat", reporter = "summary")
```

### After Each Change
```r
# Run tests again
new_results <- test_dir("tests/testthat", reporter = "summary")

# Compare - should be identical
all.equal(baseline_results, new_results)
```

### Manual Testing
1. Launch app: `shiny::runApp()`
2. Test critical workflows:
   - Navigate to dashboard
   - Create SES element
   - View CLD visualization
   - Generate report
   - Save/load project
3. Verify no regressions

---

## 📊 Expected Impact

### Performance
- **Console I/O**: -95% (debug logging controlled)
- **App startup**: Same (constants are compile-time)
- **Reliability**: +100% (no source path failures)

### Code Quality
- **Magic numbers**: 0 (all extracted)
- **Complex conditionals**: -67% (simplified)
- **Path failures**: 0 (reliable sourcing)

### Maintainability
- **Readability**: Significantly improved
- **Debugging**: Much easier
- **Onboarding**: Faster for new developers

---

## 🚀 Execution Timeline

### Today (30 minutes - 2 hours)
- [ ] Quick Win #1: Debug logging (30 min)
- [ ] Quick Win #2: Extract constants (20 min)
- [ ] Quick Win #3: Source paths (30 min)
- [ ] Quick Win #4: Simplify conditionals (20 min)
- [ ] Run tests (10 min)
- [ ] Commit changes (10 min)

### This Week (Optional - More Improvements)
- [ ] Start Phase 2: Consolidate duplicate functions
- [ ] Begin server() refactoring
- [ ] Standardize naming conventions

### This Month
- [ ] Complete Phase 2
- [ ] Execute Phase 3 (testing)
- [ ] Plan Phase 4 (polish)

---

## 📝 Commit Message Template

After completing quick wins:

```
Codebase optimization: Quick wins for maintainability

## Changes

- Wrap debug logging in debug_log() helper (controlled by env var)
  * ~1,200 debug statements now controlled
  * Cleaner console output and CI/CD logs
  * Enable with: MARINESABRES_DEBUG=TRUE

- Extract magic numbers to constants.R
  * 30+ constants defined (UI heights, file limits, plot settings)
  * Improved maintainability and clarity
  * Easier to adjust settings

- Fix source path fragility
  * Add PROJECT_ROOT establishment in global.R
  * Update 10+ modules to use get_project_file()
  * Reliable file sourcing regardless of working directory

- Simplify complex conditionals
  * Extract is_empty_isa_data() helper
  * Improved readability
  * Easier to understand logic flow

## Impact

- Performance: -95% console I/O (debug logging)
- Reliability: +100% (no path failures)
- Code quality: Magic numbers eliminated
- Maintainability: Significantly improved

## Testing

- All 353+ tests pass
- Manual testing complete
- No regressions observed

Related to: CODEBASE_REVIEW_FINDINGS.md (Phase 1)
```

---

## 🎯 Success Criteria

Quick wins are successful if:

1. ✅ All tests pass (353+)
2. ✅ App launches and works normally
3. ✅ No console debug output (unless env var set)
4. ✅ Source paths work from any directory
5. ✅ Code is more readable
6. ✅ No performance regressions
7. ✅ CI/CD logs are cleaner

---

## 🚨 Rollback Plan

If something breaks:

```bash
# Immediate rollback
git reset --hard HEAD~1

# Or revert specific commit
git revert <commit-hash>

# Then investigate what went wrong
```

---

## 📞 Support

If you encounter issues:

1. **Check test results** - Which tests fail?
2. **Review changes** - Use git diff
3. **Test in isolation** - Comment out changes one by one
4. **Consult documentation** - CODEBASE_REVIEW_FINDINGS.md

---

**Status**: ✅ Ready to execute
**Estimated Time**: 30 minutes - 2 hours
**Risk Level**: LOW
**Expected Outcome**: Cleaner, more maintainable codebase

**Start now!** These are safe, high-impact improvements.
