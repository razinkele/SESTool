# Changelog
All notable changes to the MarineSABRES SES Shiny Application will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Planned Features
- Stakeholder power-interest grid with drag-and-drop
- Interactive BOT graph editor
- Scenario comparison tool
- Real-time collaborative editing
- Mobile-responsive interface
- Integration with external modeling tools (Vensim, Stella)

---

## [1.4.0-beta] - 2025-11-05 - "AI Assistant & Navigation Overhaul"

### Added

#### Sprint 1: Navigation Components (Phase 1, Days 3-5)
- **Breadcrumb Navigation Module** - Track user position in multi-step workflows
  - Dynamic breadcrumb path based on current location
  - Clickable breadcrumbs for quick navigation
  - Automatic path updates
  - Customizable separator and home icon
- **Progress Indicator Module** - Visual step tracking for wizards
  - Numbered step circles with completion status
  - Vertical timeline layout
  - Active, completed, and pending states
  - Dynamic step title display
- **Navigation Buttons Component** - Consistent Previous/Next navigation
  - Dynamic button state management (disabled when at boundaries)
  - Customizable button labels via i18n
  - Step counter display
  - Finish button on last step

#### Sprint 2: AI Assistant Critical Fixes (Phase 1, Days 1-2)
- **Progress Bar** - Animated visual progress indicator
  - Shows percentage completion (0-100%)
  - Step counter "Step X of Y"
  - Updates in real-time as user progresses
  - Styled with CSS animation
- **Save Error Handling** - Comprehensive error feedback
  - Data structure initialization checks
  - Try-catch wrapper around save operations
  - User-friendly error messages via showNotification
  - Debug logging with [AI ISA] prefix
- **Data Initialization Observer** - ISA Data Entry module enhancement
  - Loads AI Assistant saved data on module start
  - Initializes all 6 DAPSI(W)R(M) categories
  - Updates element counters
  - Debug logging with [ISA Module] prefix

### Fixed

#### Critical Bugs (Sprint 2 Day 1-2)
- **🔴 CRITICAL: Multiple Observer Registration Bug** ([ai_isa_assistant_module.R:882-916](modules/ai_isa_assistant_module.R#L882-L916))
  - **Problem:** Quick option buttons created duplicate elements
  - **Root Cause:** Observer handlers created inside `observe()` block accumulated on every step change
  - **Impact:** Clicking "Add example" once added item multiple times (3-5 duplicates reported)
  - **Fix:**
    - Added `quick_observers_setup_for_step <- reactiveVal(-1)` to track setup state
    - Only create observers if current step differs from last setup
    - Used `local()` for proper closure variable capture
    - Added `once = TRUE` parameter to prevent re-triggering
    - Added step validation before processing answer
  - **User Impact:** Each quick option click now adds exactly one element

- **🔴 CRITICAL: Save to ISA Failing Silently** ([ai_isa_assistant_module.R:1787-2126](modules/ai_isa_assistant_module.R#L1787-L2126))
  - **Problem:** "Save to ISA Data Entry" button did nothing, no error messages
  - **Root Cause:** Code assumed `project_data` structure existed, failed silently if null
  - **Impact:** Users couldn't save AI Assistant work, thought feature was broken
  - **Fix:**
    - Added null/empty checks for `project_data`
    - Initialize `data$isa_data` structure if missing
    - Wrapped entire save in `tryCatch` with error handling
    - Added success/error notifications to user
    - Added comprehensive debug logging
  - **User Impact:** Save now works reliably with clear feedback

- **🔴 CRITICAL: ISA Standard Entry Tables Empty** ([isa_data_entry_module.R:142-205](modules/isa_data_entry_module.R#L142-L205))
  - **Problem:** After successful AI Assistant save, ISA tables showed no data
  - **Root Cause:** ISA module uses local `isa_data` reactiveValues, not connected to `project_data`
  - **Impact:** Users saw dashboard showing "112 elements, 70% complete" but empty tables
  - **Fix:**
    - Added observer to watch `project_data` changes
    - Initializes ISA tables from `project_data$data$isa_data` on module load
    - Loads all 6 categories: Drivers, Activities, Pressures, Marine Processes, Ecosystem Services, Goods/Benefits
    - Updates counters for each loaded category
  - **User Impact:** Tables now correctly display AI Assistant saved data

#### High Priority Bugs (Sprint 2 Day 2)
- **Step Counter Overflow** ([ai_isa_assistant_module.R:1125-1127](modules/ai_isa_assistant_module.R#L1125-L1127))
  - **Problem:** Progress showed "Step 12 of 11" and "109%"
  - **Root Cause:** `move_to_next_step()` incremented without bounds check
  - **Fix:** Added `if (rv$current_step < length(QUESTION_FLOW))` before incrementing
  - **User Impact:** Step counter stays within valid range (1-11)

- **Duplicate Progress Bar UI** ([ai_isa_assistant_module.R:182-192](modules/ai_isa_assistant_module.R#L182-L192))
  - **Problem:** Console errors about duplicate `output$progress_bar` definition
  - **Root Cause:** Progress bar rendered in both main content and sidebar
  - **Fix:** Removed duplicate from main content area, kept sidebar version
  - **User Impact:** Cleaner UI, no console errors

- **Connection Approval Button Closure Bug** ([ai_isa_assistant_module.R:743-760](modules/ai_isa_assistant_module.R#L743-L760))
  - **Problem:** Individual approve/reject buttons didn't work, only "Approve All"
  - **Root Cause:** Loop variable not captured properly in closure (same as quick options bug)
  - **Fix:**
    - Wrapped connection observer loop in `local()`
    - Captured `conn_idx` in local scope
    - Used `<<-` for parent scope assignment
  - **User Impact:** Each approve/reject button now works independently

#### Browser Cache Issue
- **LocalStorage Caching** - Documented workaround
  - **Problem:** Fixes not visible due to browser restoring old broken session (step=12)
  - **Root Cause:** AI Assistant saves session to localStorage, old state restored on load
  - **Solution:** Clear localStorage via console:
    ```javascript
    localStorage.removeItem('ai_isa_session');
    localStorage.removeItem('ai_isa_session_timestamp');
    location.reload();
    ```
  - **User Impact:** All fixes work correctly after cache clear

### Changed

#### Debugging and Logging
- **Enhanced Debug Output** - Added prefixed logging throughout
  - `[AI ISA]` prefix for AI Assistant operations
  - `[ISA Module]` prefix for ISA Data Entry operations
  - Logs element counts, save progress, data loading
  - Helps diagnose issues and confirm operations

#### Code Quality
- **Observer Pattern Improvements** - Better reactive programming practices
  - Proper closure capture with `local()`
  - State tracking with `reactiveVal` to prevent duplicate observers
  - Bounds checking before state mutations
  - `once = TRUE` parameter for single-execution observers

### Technical Details

#### Files Modified
- [modules/ai_isa_assistant_module.R](modules/ai_isa_assistant_module.R) - 6 critical fixes
  - Lines 182-192: Removed duplicate progress bar UI
  - Lines 392-400: Added progress UI to sidebar
  - Lines 743-760: Fixed connection button closures
  - Lines 882-916: Fixed observer accumulation bug
  - Lines 1125-1127: Fixed step counter bounds
  - Lines 1169-1183: Added progress bar renderer
  - Lines 1787-2126: Fixed save initialization and error handling

- [modules/isa_data_entry_module.R](modules/isa_data_entry_module.R) - Data loading fix
  - Lines 142-205: Added data initialization observer

- [modules/breadcrumb_nav_module.R](modules/breadcrumb_nav_module.R) - NEW (Sprint 1)
- [modules/progress_indicator_module.R](modules/progress_indicator_module.R) - NEW (Sprint 1)
- [modules/navigation_buttons_module.R](modules/navigation_buttons_module.R) - NEW (Sprint 1)

- [PHASE1_IMPLEMENTATION_GUIDE.md](PHASE1_IMPLEMENTATION_GUIDE.md) - Sprint 1 & 2 documentation
- [AI_ISA_BUG_ANALYSIS.md](AI_ISA_BUG_ANALYSIS.md) - NEW (Bug analysis and fix plan)
- [VERSION_INFO.json](VERSION_INFO.json) - Updated to v1.4.0-beta
- [CHANGELOG.md](CHANGELOG.md) - This file

#### Testing Protocol
From [AI_ISA_BUG_ANALYSIS.md:212-262](AI_ISA_BUG_ANALYSIS.md#L212-L262):

**Test Scenario 1: Quick Option Bug Fix**
- ✅ Each quick option click adds exactly one element (no duplicates)
- ✅ Behavior consistent across all 11 steps
- ✅ User confirmed: "Model saved successfully! 16 elements and 14 connections"

**Test Scenario 2: Progress Indicator**
- ✅ Progress bar shows 0% initially
- ✅ Updates correctly through all steps
- ✅ Step counter shows "Step X of Y" (stays within bounds)
- ✅ User confirmed: "now it is ok" after localStorage clear

**Test Scenario 3: Complete Model Creation**
- ✅ All elements save correctly to ISA Data Entry
- ✅ Dashboard shows accurate counts (112 elements, 14 connections, 70% complete)
- ✅ ISA tables display all saved data
- ✅ Connection approval works individually

**Test Scenario 4: Element Counts**
- ✅ Element counts match between AI Assistant and ISA Data Entry
- ✅ No data loss during save/load cycle

#### Commits Included
1. `2d4aa86` - Sprint 1 navigation components
2. `22722a9` - AI Assistant observer bug fix
3. `7f1da60` - AI Assistant save initialization
4. `fef2440` - ISA Data Entry display fix
5. `84bbbc7` - Implementation guide update
6. `6a8bbe5` - Step counter bounds check
7. `917d797` - Duplicate UI removal
8. `8372bfc` - Connection button closure fix

### Known Issues

#### Remaining Bugs (Sprint 2 Days 3-5 To Do)
- **Deleted nodes reappearing in reports** - Needs investigation
- **Intervention analysis inconsistency** - Requires fix

#### Not Yet Integrated
- Sprint 1 navigation components complete but not integrated into app.R
- Progress indicator module ready for other data entry workflows
- Breadcrumb module ready for multi-step interfaces

### Migration Notes
- **✅ Fully backward compatible** - No breaking changes
- **No migration required** - Existing projects work unchanged
- **Clear localStorage** if you see "Step 12 of 11" or other cached issues

### Performance
- **No performance impact** from fixes
- **Reduced memory usage** - Fixed observer leak (observers no longer accumulate)
- **Faster debugging** - Enhanced logging helps identify issues quickly

---

## [1.3.0] - 2025-11-05 - "Complete Internationalization Release"

### Added

#### Complete Internationalization
- **Full multi-language support** across entire application
  - 1,073 translations covering all user-facing text
  - 7 languages: English, Spanish, French, German, Lithuanian, Portuguese, Italian
  - Reactive UI pattern for instant language switching
  - No page reload required for language changes

#### Module Internationalization
- **AI ISA Assistant Module** - All 1,063 strings translated
  - Fixed sidebar namespace issue (ns() error)
  - Proper reactive UI implementation

- **Create SES Module** - Complete rewrite with reactive UI
  - All 3 method cards fully translated (Standard, AI Assistant, Template)
  - Method comparison table internationalized
  - Help section translated
  - Dynamic content updates on language change

- **Entry Point Module** - Navigation fully translated
  - Tool cards and descriptions in all languages
  - Navigation notifications translated
  - Guidance text internationalized

- **Response Measures & Validation** - Complete translation support
- **Scenario Builder Module** - All UI elements translated
- **Template & ISA Data Entry** - Full internationalization
- **Main Application** - Header, sidebar, and all modal dialogs

#### Translation Infrastructure
- **Settings modal** - Language selection interface translated
- **All modal dialogs** - Save/Load Project, About, Reports all translated
- **Notification messages** - Error messages, success messages internationalized
- **Button labels** - Cancel, Close, Apply, Load, Save all translated

### Fixed

#### Language Switching
- **Animation timing** - Removed artificial delay, instant language reload
- **Namespace errors** - Fixed AI Assistant sidebar `ns()` function access
- **Hardcoded strings** - Eliminated 13 hardcoded English strings in main app
  - Language settings modal text
  - Modal button labels (Cancel, Close, Load, Save)
  - Error messages and notifications
  - File chooser labels

#### Code Quality
- **Project cleanup** - Moved 107 temporary files to backup
  - Removed all temporary R scripts (test_, merge_, check_, etc.)
  - Removed intermediate JSON translation files
  - Removed temporary documentation files
  - Clean root directory with only core files

- **Module consistency** - Standardized i18n parameter passing
  - Consistent reactive UI pattern across modules
  - Proper namespace handling in server functions
  - Global i18n access where appropriate

### Technical Details

#### Translation System
- Total translations: 1,073 entries
- No duplicate keys in translation.json
- All translations complete (no empty entries)
- Consistent translation pattern throughout codebase

#### Files Modified
- `app.R` - Fixed 13 hardcoded strings, optimized language change handler
- `modules/create_ses_module.R` - Complete rewrite with reactive UI
- `modules/ai_isa_assistant_module.R` - Fixed namespace issue
- `modules/entry_point_module.R` - Added navigation translation
- `translations/translation.json` - Added 9 new translations (1,064 → 1,073)

#### Repository Cleanup
- Core files preserved: app.R, global.R, install_packages.R, run_app.R, version_manager.R, VERSION_INFO.json
- Temporary files backed up to: temp_files_backup/
- Clean, maintainable project structure

---

## [1.2.0] - 2025-10-27 - "Confidence & UI Enhancement Release"

### Added

#### UI Enhancements
- **About dialog** in application header with comprehensive version information
  - Application version and release details
  - Key features list
  - Technical system information (R version, platform, git branch)
  - Contributors list
  - Links to documentation and changelog
- **Collapsible sidebar** in CLD Visualization module
  - Toggle button in page header with hamburger menu icon
  - Smooth slide animation using shinyjs
  - Fixed positioning for better screen real estate
  - All controls remain accessible and functional
- **Streamlined CLD interface** - removed 258 lines of cluttered code
  - Removed 4 dashboard info value boxes
  - Removed 2 selected element info panes (tooltips provide same info)
  - Removed loop analysis section (belongs in Analysis Tools)
  - Better frame alignment for network diagram
  - Clean, focused visualization interface

#### Confidence Property Feature
- **Confidence property (1-5 scale)** for all CLD edges
- **Visual feedback** through edge opacity (30%-100% based on confidence level)
- **Interactive confidence filtering** in CLD visualization with slider control
- **Confidence input UI** in ISA Data Entry (Exercise 6) with descriptive labels
- **AI-generated confidence** values for all auto-created connections
- **Excel export** includes confidence column in CLD_Edges sheet
- **Tooltips display** confidence with labels (Very Low to Very High)
- **Edge info panel** shows confidence when edge is selected

#### Global Constants
- **CONFIDENCE_LEVELS** (1:5) - Valid confidence range
- **CONFIDENCE_LABELS** - Descriptive labels for each level
- **CONFIDENCE_OPACITY** - Visual opacity mapping for feedback
- **CONFIDENCE_DEFAULT** (3) - Default confidence value

#### Testing Framework Updates
- **87 confidence tests** in test-confidence.R
- **30 global constants tests** validating all confidence-related constants
- **2 consistency tests** ensuring constants work together
- **Test count** increased from 57 to 87 for confidence module
- **All 189 tests passing** (102 global-utils + 87 confidence)

#### Documentation
- **CONFIDENCE_IMPLEMENTATION_COMPLETE.md** - Complete implementation guide
- **CODEBASE_REVIEW_AND_OPTIMIZATIONS.md** - Optimization summary
- **Updated TESTING_GUIDE.md** with confidence testing section

### Changed

#### Code Quality Improvements
- **Replaced all hardcoded values** with global constants (15+ replacements)
- **Consistent opacity application** using adjustcolor() throughout
- **Single source of truth** for confidence-related values
- **Improved maintainability** with centralized configuration

#### Templates Updated
- **All 5 pre-built templates** now include confidence values (3-5 range):
  - Fisheries Management (20 connections)
  - Tourism Management (17 connections)
  - Aquaculture Management (13 connections)
  - Pollution Control (18 connections)
  - Climate Change Adaptation (21 connections)

#### Module Enhancements
- **parse_connection_value()** validates confidence using CONFIDENCE_LEVELS
- **create_edges_df()** includes confidence and opacity in initial structure
- **process_adjacency_matrix()** applies opacity to all edge colors
- **filter_by_confidence()** filters edges by minimum confidence level
- **BOT analysis** uses consistent confidence defaults with opacity

### Fixed

#### Critical Bugs
- **🔴 CRITICAL: Opacity not applied to edge colors** - Visual feedback was completely broken
  - Edge opacity was calculated but never applied using adjustcolor()
  - All edges appeared with same transparency regardless of confidence
  - Users couldn't visually distinguish between high/low confidence connections
  - **Impact:** High - Core feature was non-functional
  - **Fixed:** Applied opacity using adjustcolor(color, alpha.f = opacity) in visnetwork_helpers.R:374

#### Inconsistencies
- **Missing confidence/opacity columns** in initial edge dataframe structure
- **BOT edges opacity** not applied consistently with regular edges
- **Hardcoded magic numbers** scattered across 5+ files (now centralized)
- **Validation logic** now uses CONFIDENCE_LEVELS instead of hardcoded ranges

### Performance
- **No performance impact** - Constants loaded once at startup
- **Slightly faster** lookups with pre-defined constants vs array recreation
- **Memory efficient** - One integer column per edge (~4 bytes)

### Backward Compatibility
- **✅ Fully backward compatible** - All changes are drop-in replacements
- **Default values** maintain same behavior as before
- **Old data** without confidence continues to work (defaults to 3)
- **No breaking changes** to existing functionality

### Migration
- **No migration required** - Existing projects work unchanged
- **Auto-defaults** to confidence=3 for old connections
- **Auto-corrects** out-of-range values to default

---

## [1.1.0] - 2025-01-25 - "Create SES Release"

### Added

#### Create SES Interface
- **Create SES module** with 3 entry methods:
  - Standard Entry: Traditional form-based ISA data entry with guided exercises
  - AI Assistant: Intelligent question-based guidance for beginners
  - Template-Based: Quick start with pre-built SES templates
- **Method selection interface** with visual cards, comparison table, and interactive help
- **Template library** with 5 pre-built templates:
  - Fisheries Management
  - Tourism Management
  - Aquaculture Management
  - Pollution Control
  - Climate Change Adaptation
- **Entry Point module** for guided navigation through toolbox features

#### Internationalization
- **Complete i18n implementation** with 157 translation keys
- **7 language support**: English, Spanish, French, German, Lithuanian, Portuguese, Italian
- **44 new Create SES translation keys** added
- **Translation validation** in test suite (2269 translation tests)
- **Dynamic language switching** throughout entire application

#### Testing Framework
- **Comprehensive test suite** with 2417 tests (1626% increase)
- **Translation tests**: 2269 tests validating all language keys
- **Module tests**: 28 tests covering all modules including Create SES
- **Integration tests**: 13 end-to-end workflow tests
- **100% pass rate** across all test categories
- **New test files**: test-translations.R
- **Test execution time**: 11.3 seconds for entire suite

#### Versioning System
- **VERSION file** with semantic versioning (1.1.0)
- **VERSION_INFO.json** with detailed version metadata
- **version_manager.R** script for automated version management
- **VERSIONING_STRATEGY.md** documenting versioning workflow
- **Branch strategy** defined (main, develop, feature/*, hotfix/*, release/*)

#### Documentation
- **APPLICATION_ANALYSIS_REPORT.md**: Comprehensive application review
- **CREATE_SES_REFACTORING_SUMMARY.md**: Complete Create SES implementation details
- **CREATE_SES_TRANSLATIONS_COMPLETED.md**: Translation implementation summary
- **TESTING_FRAMEWORK_UPDATE_SUMMARY.md**: Test suite growth analysis
- **TEST_VERIFICATION_REPORT.md**: Complete test validation report
- **SESSION_2_COMPLETE_SUMMARY.md**: Session work summary
- **VERSIONING_STRATEGY.md**: Version management guide

### Changed

#### Menu Structure
- **Reorganized menu** to consolidate ISA entry under "Create SES"
- **Create SES parent menu** with 4 submenu items:
  - Choose Method
  - Standard Entry
  - AI Assistant
  - Template-Based
- **Improved menu tooltips** for better user guidance

#### Module Organization
- **create_ses_module.R**: New consolidated entry point for SES creation
- **template_ses_module.R**: New template-based creation workflow
- **Refactored ISA entry** to fit within Create SES structure
- **Updated module sourcing** in app.R

#### Code Quality
- **All Create SES code** uses i18n$t() for translations
- **Consistent naming** across new modules
- **Comprehensive inline documentation**
- **Improved error handling** in data validation functions

### Fixed
- **Translation consistency** across all Create SES components
- **Module navigation** bugs resolved
- **Test suite** updated to cover new modules
- **Regex validation** in sanitize_filename() (global.R:872)
- **Missing project_name** field in init_session_data()
- **Function naming conflicts** (validate_isa_data renamed to validate_isa_structure)

### Performance
- **Test execution optimized**: 11.3 seconds for 2417 tests
- **Translation loading**: Efficient with 157 entries
- **Module loading**: No performance impact from new modules

### Security
- **Input validation** maintained across new modules
- **No new security vulnerabilities** introduced
- **Test coverage** ensures data integrity

---

## [1.0.0] - 2024-10-19

### Added

#### Core Framework
- Initial release of MarineSABRES SES Shiny Application
- Modular architecture with separation of UI and server logic
- Comprehensive data structure for ISA and PIMS data
- Project save/load functionality (RDS format)

#### PIMS Module
- Project setup and metadata management
- Stakeholder identification framework (placeholder UI)
- Risk management template
- Resource allocation tracking
- Data management plan template
- Process and outcome evaluation framework

#### ISA Data Entry
- Structured workflow through DAPSI(W)R(M) framework
- Data entry forms for all element types:
  - Goods & Benefits
  - Ecosystem Services
  - Marine Processes & Functioning
  - Pressures
  - Activities
  - Drivers
- Adjacency matrix system for defining connections
- BOT (Behavior Over Time) data structure
- Data validation functions

#### CLD Visualization (visNetwork)
- Interactive network visualization
- Multiple layout algorithms:
  - Hierarchical (DAPSI(W)R(M) levels)
  - Physics-based (Force Atlas 2)
  - Circular
  - Manual positioning
- Element filtering by type, polarity, and strength
- Search and highlight functionality
- Focus mode for neighborhood exploration
- Dynamic node sizing by network metrics
- Color-coded DAPSI(W)R(M) elements
- Interactive tooltips with element details

#### Network Analysis
- Automated feedback loop detection
- Loop classification (Reinforcing/Balancing)
- Centrality metrics calculation:
  - Degree (in/out/total)
  - Betweenness centrality
  - Closeness centrality
  - Eigenvector centrality
- MICMAC analysis framework
- Simplification tools:
  - Endogenization (exogenous variable removal)
  - Encapsulation (SISO variable bridging)

#### Export & Reporting
- CLD export formats:
  - PNG (via webshot)
  - HTML (interactive)
  - SVG (planned)
- Data export formats:
  - Excel workbook
  - CSV (zipped collection)
  - JSON
  - RDS (native R format)
- Report generation:
  - Executive summary (R Markdown)
  - Technical report (planned)
  - Stakeholder presentation (planned)

#### Documentation
- Comprehensive README
- Quick Start Guide (5-minute setup)
- Installation Guide (all platforms)
- Technical Framework Documentation
- User Guide (in progress)
- In-code documentation and comments

#### Example Data
- Complete example ISA dataset
- Pre-configured adjacency matrices
- Sample DAPSI(W)R(M) structure

### Technical Details
- **R Version**: Requires 4.0.0+
- **Key Dependencies**: 
  - shiny, shinydashboard, visNetwork, igraph
  - tidyverse, DT, plotly
  - rmarkdown, htmlwidgets
- **Lines of Code**: ~8,000+
- **Modules**: 4 main modules
- **Helper Functions**: 50+ utility functions

### Known Limitations
- ISA data entry modules are placeholder implementations
- PIMS modules (stakeholders, risks, resources) have basic UI only
- Response measures module not fully implemented
- Scenario builder is placeholder
- No authentication/user management
- Limited error handling in some areas
- Performance not optimized for very large networks (>1000 nodes)

---

## [0.9.0] - 2024-10-15 (Beta)

### Added
- Initial beta release for internal testing
- Basic CLD visualization with visNetwork
- Core data structures
- Project save/load functionality

### Fixed
- Loop detection algorithm optimization
- Memory leaks in network rendering
- Data validation issues

---

## [0.5.0] - 2024-10-01 (Alpha)

### Added
- Proof of concept implementation
- Basic Shiny UI framework
- Simple network visualization
- Manual data entry

---

## Version History Summary

| Version | Date | Status | Key Features |
|---------|------|--------|--------------|
| 1.0.0 | 2024-10-19 | Release | Full CLD visualization, Loop detection, Export |
| 0.9.0 | 2024-10-15 | Beta | Internal testing |
| 0.5.0 | 2024-10-01 | Alpha | Proof of concept |

---

## Upgrade Guide

### From 0.9.0 to 1.0.0
- Data structure is compatible, no migration needed
- New export formats available
- Enhanced loop detection algorithm
- Updated visNetwork styling

---

## Contributing

To report bugs or request features:
1. Check existing issues
2. Create detailed bug report with reproducible example
3. For features, describe use case and expected behavior

Contact: gemma.smith@iecs.ltd

---

## License

[Specify License - e.g., GPL-3, MIT, etc.]

---

**Maintained by**: IECS Ltd for the MarineSABRES Project
**Project**: EU Horizon Europe MarineSABRES
**Website**: [Project Website]
