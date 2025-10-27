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
