# Changelog

All notable changes to the MarineSABRES SES Toolbox will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.6.1] - 2026-01-06

### Stability and Consistency Improvements

This release focuses on fixing critical issues identified in codebase analysis and improving code consistency across the application. No user-facing functionality changes.

### Fixed
- **Critical**: Removed duplicate `sanitize_filename()` function in `global.R`
  - Second definition at lines 1305-1328 was overwriting first
  - Lost max_length parameter functionality
  - Preserved proper implementation at lines 416-464
- **Critical**: Fixed reactive value initialization race condition in `app.R`
  - `project_data` reactive was used in observe() blocks before initialization
  - Moved all reactive value declarations to line 387 (before any observe() blocks)
  - Prevents startup crashes from race condition
- **Critical**: Consolidated duplicate constant definitions
  - Removed DAPSIWRM_ELEMENTS, ELEMENT_COLORS, ELEMENT_SHAPES duplicates from `global.R`
  - Centralized all constants in `constants.R`
  - Single source of truth for configuration values
- **Consistency**: Standardized debug logging in `server/modals.R`
  - Replaced 6 `cat()` calls with `debug_log()` for settings messages
  - Consistent with debug logging pattern across application
  - Respects DEBUG_MODE configuration

### Changed
- **Consistency**: Standardized all `source()` calls with explicit `local` parameter
  - Updated 40+ source() calls in `global.R` and `app.R`
  - Explicit scoping improves code clarity
  - Documented rationale for `local = FALSE` usage
- **Consistency**: Completed internationalization (i18n) coverage
  - Added 6 new translation keys to `translations/ui/dashboard.json`:
    - `ui.dashboard.project_overview`
    - `ui.dashboard.status_summary`
    - `ui.dashboard.network_status`
    - `ui.dashboard.project_history`
    - `ui.dashboard.isa_data_status`
    - `ui.dashboard.analysis_status`
  - Added missing key to `translations/common/misc.json`:
    - `common.misc.approve_this_connection_with_current_slider_values`
  - All 7 keys have complete translations in 8 languages (EN, ES, FR, DE, LT, PT, IT, NO)
- **Consistency**: Applied UI dimension constants throughout dashboard
  - Used `UI_BOX_WIDTH_QUARTER`, `UI_BOX_WIDTH_HALF`, `UI_BOX_WIDTH_FULL` consistently
  - Replaced hard-coded width values in `app.R`

### Added
- **Constants**: Expanded `constants.R` with DAPSIWRM framework definitions
  - `DAPSIWRM_ELEMENTS`: 7 element types from framework
  - `ELEMENT_COLORS`: 8 Kumu-style colors for element types
  - `ELEMENT_SHAPES`: 7 visNetwork shapes for element types
  - `EDGE_COLORS`: Reinforcing and opposing connection colors
  - `DA_SITES`: 3 demonstration area identifiers
  - `STAKEHOLDER_TYPES`: 6 types from Newton & Elliott (2016)
  - `UI_BOX_WIDTH_*`: UI dimension constants
- **Documentation**: Created comprehensive refactoring documentation
  - `DEPLOYMENT_REVIEW_POST_REFACTORING.md`: Full deployment compatibility analysis
  - `TEST_FAILURE_DEEP_ANALYSIS.md`: Investigation of test failures (all pre-existing)
  - Pattern documentation in `functions/error_handling.R`

### Improved
- **Code Quality**: Eliminated duplicate function definitions
- **Code Quality**: Prevented startup race conditions
- **Code Quality**: Centralized configuration management
- **Code Consistency**: Uniform source() call patterns
- **Code Consistency**: Complete i18n coverage for UI strings
- **Code Consistency**: Standardized debug logging approach

### Technical Details
- **Files Modified**: 7 (global.R, constants.R, app.R, server/modals.R, functions/error_handling.R, translations/ui/dashboard.json, translations/common/misc.json)
- **Critical Issues Fixed**: 4
- **Consistency Issues Fixed**: 7
- **Translation Keys Added**: 7 (all with 8-language coverage)
- **Source Calls Standardized**: 40+
- **Lines Changed**: +910 insertions, -350 deletions
- **Tests Passing**: 3,729 (no regressions introduced)
- **Pre-existing Test Failures**: 8 (ML context embeddings - unrelated to changes)

### Testing
- All 3,729 tests passing after refactoring
- Zero regressions introduced by changes
- Comprehensive test failure analysis completed
- All failures confirmed as pre-existing (ML module issues)

### Deployment
- All deployment scripts verified compatible
- Pre-deployment checks validate all changes
- Translation cache clearing ensures new keys loaded
- Full server restart ensures reactive fix takes effect
- See `DEPLOYMENT_REVIEW_POST_REFACTORING.md` for details

### Migration Notes
- **No Breaking Changes**: All changes are internal refactoring
- **No User Impact**: Functionality preserved exactly
- **No Configuration Changes**: Existing settings work unchanged
- **Backward Compatible**: Existing project files load without modification
- **Translation Cache**: Will be automatically cleared on deployment

### Developer Notes
- Use `debug_log(message, category)` instead of `cat()` for debug output
- Always specify `local` parameter in `source()` calls for clarity
- Add magic numbers to `constants.R` with descriptive names
- Use `i18n$t()` for all user-facing strings
- Follow error handling patterns in `functions/error_handling.R`
- Initialize reactive values before any `observe()` blocks

---

## [1.6.0] - 2025-12-26

### Major Optimization Release

This release focuses on significant codebase optimizations, refactoring, and maintainability improvements without changing user-facing functionality.

### Added
- **Server Modularization**: Created 4 new server modules for better code organization
  - `server/project_io.R` - Project save/load handlers (151 lines)
  - `server/export_handlers.R` - Data and visualization export handlers (221 lines)
  - `server/dashboard.R` - Dashboard rendering (310 lines) [pre-existing, enhanced]
  - `server/modals.R` - Modal dialog handlers (649 lines) [pre-existing, enhanced]
- **Debug Logging Control**: Added `debug_log()` wrapper for controllable debug output
  - Enable with `MARINESABRES_DEBUG=TRUE` environment variable
  - Categorized logging: DIAGNOSTICS, SESSION, AUTOLOAD
  - Silent by default in production
- **Helper Functions**: New utility functions in `utils.R`
  - `is_empty()` - Check if data frame is empty
  - `is_empty_isa_data()` - Check if ISA data structure is empty
- **Path Helpers**: Reliable file sourcing regardless of working directory
  - `PROJECT_ROOT` - Established project root directory
  - `get_project_file()` - Generate project-relative file paths
- **Constants Expansion**: Added UI and file upload constants to `constants.R`
  - UI layout constants (BOX_HEIGHT, SIDEBAR_WIDTH, PLOT_MARGINS)
  - File upload constants (MAX_UPLOAD_SIZE_BYTES)
- **Documentation**: Comprehensive optimization documentation
  - `CODEBASE_REVIEW_FINDINGS.md` - Detailed code analysis (400+ lines)
  - `OPTIMIZATION_ACTION_PLAN.md` - Implementation guide (500+ lines)
  - `CI_CD_STATUS_CHECK.md` - CI/CD monitoring guide (560+ lines)

### Changed
- **Server Function Refactoring**: Reduced main server() function by 37%
  - **Before**: 772 lines (monolithic)
  - **After**: 486 lines (modular)
  - Extracted 286 lines into dedicated server modules
- **app.R Size Reduction**: Reduced total app.R size by 27%
  - **Before**: 1,045 lines
  - **After**: 757 lines
  - Net reduction: 288 lines
- **Debug Output**: 18+ debug statements now controlled by environment variable
  - Cleaner console output in production mode
  - Easier debugging when enabled
- **File Upload Configuration**: Consolidated and centralized
  - Updated MAX_UPLOAD_SIZE_MB from 30 to 100 (matches Shiny usage)
  - Single source of truth in constants.R
- **Error Handling**: Improved error messages in I/O functions
  - Added file type validation to `read_network_from_excel()`
  - Validates .xlsx/.xls extension before attempting read
  - Clearer error messages for invalid file types
- **Constants Loading**: Fixed initialization order
  - Constants now loaded early in global.R
  - Prevents "object not found" errors
- **Source Paths**: Eliminated fragile path fallback patterns
  - Replaced 15-line fallback logic with 2-line clean solution
  - Works reliably from any working directory

### Improved
- **Code Organization**: Clear separation of concerns
  - Server logic organized by functional area
  - Export handlers in dedicated module
  - Project I/O in dedicated module
- **Maintainability**: Significantly easier to understand and modify
  - Smaller, focused functions
  - Clear module boundaries
  - Consistent patterns throughout
- **Testability**: Modular code is easier to unit test
  - Each server module can be tested independently
  - Helper functions isolated and reusable
- **Readability**: Complex code simplified
  - Magic numbers replaced with named constants
  - Complex conditionals replaced with helper functions
  - Debug logging categorized and controllable

### Technical Details
- **Lines of Code Changes**:
  - Created: +494 lines (new modules and documentation)
  - Removed: -346 lines (refactored and consolidated)
  - Net: +148 lines (improved organization worth the small increase)
- **Files Changed**: 14 modified, 7 created
- **Commits**: 5 optimization commits (d59256f, cb7d251, 062465d, de1a042, + docs)
- **Server Modules**: 4 total (up from 2)
- **Debug Statements Controlled**: 18+ (DIAGNOSTICS, SESSION, AUTOLOAD categories)

### Performance
- **No Performance Degradation**: All changes are organizational
- **Improved Startup Reliability**: Proper constant initialization
- **Cleaner Console Output**: Debug logging controlled by environment variable

### Migration Notes
- **No Breaking Changes**: All changes are internal refactoring
- **No User Impact**: Functionality preserved exactly
- **Optional Debug Mode**: Set `MARINESABRES_DEBUG=TRUE` to see diagnostic output
- **Backward Compatible**: Existing project files load without modification

### Developer Notes
- **Server Module Pattern Established**: Clear pattern for future extractions
  ```r
  # In server/module_name.R
  setup_module_handlers <- function(input, output, session, project_data, i18n) {
    # Handler implementations
  }

  # In app.R server function
  setup_module_handlers(input, output, session, project_data, i18n)
  ```
- **Debug Logging Pattern**: Use `debug_log(message, category)` instead of `cat()`
- **Constants Pattern**: Add all magic numbers to constants.R with descriptive names
- **Path Pattern**: Use `get_project_file()` for all relative file paths

---

## [1.5.2] - 2024-12-24

### Connection Review Bug Fixes

### Fixed
- Connection review module bug fixes
- Translation system improvements
- ISA data entry enhancements

---

## [1.5.1] - 2024-12-23

### Translation Framework Improvements

### Added
- Comprehensive translation framework
- Multi-language support (EN, ES, FR, IT, NO)
- Translation automation system

---

## [1.5.0] - 2024-12-20

### E2E Testing and Coverage Tracking

### Added
- End-to-end testing with shinytest2 (5 comprehensive tests)
- Coverage tracking system with 70% minimum threshold
- Enhanced CI/CD workflow with multi-platform testing
- Comprehensive testing documentation

### Changed
- GitHub Actions workflow enhanced with coverage reporting
- Test suite expanded from 348 to 353+ tests

---

## Earlier Versions

See git history for earlier version details.

---

**Note**: This CHANGELOG started with version 1.6.0. Earlier versions can be found in git commit history.
