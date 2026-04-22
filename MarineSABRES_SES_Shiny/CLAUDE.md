# CLAUDE.md - MarineSABRES SES Toolbox

## Project Overview

R/Shiny application for Social-Ecological Systems (SES) analysis using the DAPSIWRM framework. Supports 9 languages with reactive i18n, network visualization, and ML-assisted element classification.

**Version**: 1.11.0 | **R Version**: >= 4.4.1 | **Framework**: bs4Dash + shiny.i18n

## Quick Commands

```bash
# Run the application
Rscript run_app.R
# Or in R: shiny::runApp()

# Run all tests
Rscript tests/run_all_tests.R

# Run testthat suite only
Rscript -e "testthat::test_dir('tests/testthat')"

# Run JSON project loading tests (standalone, no full app bootstrap needed)
Rscript tests/run_json_loading_tests.R

# Run specific test file
Rscript -e "testthat::test_file('tests/testthat/test-i18n-enforcement.R')"

# Validate translations before commit
Rscript scripts/translation_workflow.R check

# Pre-deployment validation
Rscript deployment/pre-deploy-check.R

# Add new translation interactively
Rscript scripts/add_translation.R
```

## Architecture

```
├── app.R                 # Main app entry, UI structure, server orchestration
├── global.R              # Package loading, PROJECT_ROOT, utility functions
├── constants.R           # DAPSIWRM_ELEMENTS, colors, shapes, site configs
├── DESCRIPTION           # Package dependency manifest
├── modules/              # Shiny modules (37 .R files in modules/ + 9 sub-modules in modules/ai_isa/)
│   ├── *_module.R        # Module pattern: module_name_ui() + module_name_server()
│   ├── analysis_*.R      # Analysis modules (loops, metrics, boolean, etc.)
│   └── ai_isa/           # AI-assisted ISA workflow
│       └── step_navigation.R  # Step flow logic for AI assistant
├── functions/            # Non-reactive helper functions
│   ├── data_structure.R  # ISA data manipulation
│   ├── network_analysis.R # igraph operations
│   ├── ml_*.R            # ML classification features
│   ├── error_handling.R  # Standardized error patterns
│   ├── ui_components.R   # Shared UI component library (8 reusable builders)
│   ├── cld_interaction_helpers.R  # CLD network interaction helpers
│   ├── isa_form_builders.R        # ISA form generation per element type
│   └── isa_export_helpers.R       # ISA Excel/Kumu export logic
├── server/               # Server-side components (8 files)
│   ├── bookmarking.R         # URL bookmarking + query params
│   ├── dashboard.R           # Dashboard observers
│   ├── event_bus_setup.R     # Event bus initialization
│   ├── export_handlers.R     # Export download handlers
│   ├── language_handling.R   # Language change observers
│   ├── modals.R              # Modal dialogs
│   ├── project_io.R          # Project save/load
│   └── session_management.R  # Session lifecycle
├── translations/         # Modular i18n system
│   ├── common/           # Shared translations (buttons, labels, messages)
│   ├── modules/          # Module-specific translations
│   └── ui/               # UI component translations
├── data/
│   ├── ses_knowledge_db.json                    # Main SES knowledge database (30+ contexts)
│   ├── ses_knowledge_db_offshore_wind.json      # Offshore wind parks KB (4 regional contexts)
│   └── ses_knowledge_db_offshore_wind_elements.md # Element reference table by DAPSIWRM category
├── docs/
│   └── ARCHITECTURE.md   # Architecture Decision Records
├── scripts/
│   └── build_offshore_wind_kb.py  # Reproducible KB builder from BibTeX (187 papers)
└── tests/testthat/       # 90 test files (21/21 *_module.R files covered)
```

## i18n System (CRITICAL)

This app uses **dual i18n** with `shiny.i18n`. All user-facing text MUST be internationalized.

### 9 Supported Languages
`en`, `es`, `fr`, `de`, `lt`, `pt`, `it`, `no`, `el`

(English, Spanish, French, German, Lithuanian, Portuguese, Italian, Norwegian, Greek)

### Required Patterns

```r
# EVERY module UI must start with the defensive usei18n wrapper:
my_module_ui <- function(id, i18n) {
  tryCatch(shiny.i18n::usei18n(i18n$translator %||% i18n), error = function(e) NULL)
  ns <- NS(id)
  # ... UI code
}

# ALL user-facing text:
h4(i18n$t("Section Title"))
actionButton(ns("save"), i18n$t("Save"))
showNotification(i18n$t("Data saved successfully!"), type = "message")

# Dynamic messages - translate ALL parts:
paste(i18n$t("Found"), count, i18n$t("errors"))
```

### DO NOT Translate
- Technical IDs: `ns("field_id")`
- File paths: `"data/file.csv"`
- Log messages: `debug_log("Processing", "INFO")`
- R error details (translate prefix only): `paste(i18n$t("Error:"), e$message)`

### Translation Files
- Add keys to `translations/common/` or `translations/modules/`
- All 9 languages required for each key
- CI validates translations on every PR

## Module Conventions

### Function Signatures

```r
# UI Function
module_name_ui <- function(id, i18n) {
  ns <- NS(id)
  # ...
}

# Server Function - Standard parameter order
module_name_server <- function(id, project_data_reactive, i18n, event_bus = NULL, ...) {
  moduleServer(id, function(input, output, session) {
    # ...
  })
}
```

### Naming
- Use `snake_case` for functions: `module_name_server()` not `moduleNameServer()`
- UI suffix: `_ui`, Server suffix: `_server`

### Analysis Module Pattern

```r
# All analysis modules should have event_bus parameter:
analysis_*_server <- function(id, project_data_reactive, i18n, event_bus = NULL)

# Stale data observer pattern:
observe({
  req(!is.null(event_bus))
  event_bus$on_isa_change()
  if (isolate(rv$analysis_complete)) {
    showNotification(i18n$t("modules.analysis.common.data_changed_rerun"), ...)
  }
})
```

## DAPSIWRM Framework

The core domain model for SES analysis. Components flow: **D → A → P → C → ES → GB → HW → D** (feedback loop)

| Code | Category | Description |
|------|----------|-------------|
| D | Drivers | Root causes (food security, economic needs) |
| A | Activities | Human actions (fishing, tourism) |
| P | Pressures | Environmental stressors |
| C | Components/State | Ecosystem elements |
| ES | Ecosystem Services | Benefits from ecosystem |
| GB | Goods & Benefits | Tangible human welfare |
| HW | Human Wellbeing | Overall welfare impacts |
| R | Responses | Policy interventions |
| M | Measures | Implementation actions |

See `DAPSIWRM_FRAMEWORK_RULES.md` for full connection rules and polarity logic.

## Key Constants (constants.R)

```r
DAPSIWRM_ELEMENTS  # 7 element types
ELEMENT_COLORS     # Kumu-style colors per type
ELEMENT_SHAPES     # visNetwork shapes
EDGE_COLORS        # Reinforcing (+) / Opposing (-)
DA_SITES           # 3 demonstration areas
STAKEHOLDER_TYPES  # 6 types (Newton & Elliott, 2016)
```

## Error Handling

```r
# Standard pattern from functions/error_handling.R
tryCatch({
  # risky operation
}, error = function(e) {
  debug_log(paste("Operation failed:", e$message), "ERROR")
  showNotification(
    paste(i18n$t("Error:"), e$message),
    type = "error"
  )
})

# Use debug_log() not cat() for all debug output
debug_log("Processing data", "INFO")

# User-facing error messages (use format_user_error, not raw e$message)
tryCatch({
  # risky operation
}, error = function(e) {
  showNotification(
    format_user_error(e, i18n = i18n, context = "saving project"),
    type = "error"
  )
})
```

## Testing

- **Unit tests**: `test-global-utils.R`, `test-data-structure.R`
- **Module signature-contract tests**: `test-<module-name>-module.R` for every `modules/*_module.R` file (21/21 covered). Each asserts UI returns valid shiny tags, namespaces IDs, server function exists with the conventional `(id, project_data_reactive, i18n, ..., event_bus = NULL)` signature.
- **Module integration tests**: `test-modules.R` (pre-existing `testServer()` exercises)
- **JSON loading**: `test-json-project-loading.R` (standalone runner: `tests/run_json_loading_tests.R`)
- **Integration**: `test-integration.R`
- **E2E**: `test-app-e2e.R` (requires Chrome, uses shinytest2)
- **i18n enforcement**: `test-i18n-enforcement.R` (runs in CI)
- **Visual regression**: `test-visual-regression.R`
- **Load testing**: `scripts/load_test.R`, `scripts/memory_profile.R`

### Helpers Available to New Tests

- `source_for_test(c("modules/x.R", "server/y.R"))` (defined in `tests/testthat/helper-00-load-functions.R`) — sources production files into `.GlobalEnv` using an absolute path derived from `getwd()`. Use this when your test targets a file NOT in global.R's auto-load chain (modules/*.R, server/*.R, some functions/*.R). See `test-entry-point-module.R` for a minimal example.
- `helper-stubs.R` provides minimal stubs for module UI/server functions. Stubs mirror the real module signatures (commit `f93135a` aligned them). When writing a new signature-assertion test, the real module source (via `source_for_test`) should override the stub.

### Running Tests

```r
# All tests
testthat::test_dir("tests/testthat")

# Single file
testthat::test_file("tests/testthat/test-network-analysis.R")

# With coverage
covr::package_coverage(".", type = "tests")
```

### Accessibility (Known Gap)

The `tests/testthat/test-accessibility.R` file was deleted on 2026-04-11
because it referenced ARIA helper functions that don't exist. ARIA
accessibility is a real feature that needs proper implementation:
- `add_aria_attributes()`, `aria_nav()`, `aria_button()`, `aria_status()`, `sr_only()`

This is tracked as a future task. Do NOT recreate the test file until
the helpers are implemented.

## Git Workflow

- CI runs i18n validation on all PRs
- Pre-commit: Run `Rscript deployment/pre-deploy-check.R`
- Commit messages: Follow conventional commits pattern

## Files to Avoid Editing Directly

- `translations/_merged_translations.json` - Auto-generated, edit source files in `translations/*/`
- `data/ses_knowledge_db_offshore_wind.json` - Generated by `scripts/build_offshore_wind_kb.py`, edit the script instead
- `*.RData` - Session data
- Lock files

## Offshore Wind SES Knowledge Base

A separate DAPSIWRM knowledge database for offshore wind parks SES, derived from 187 peer-reviewed papers (NID4OCEAN list). Located at `data/ses_knowledge_db_offshore_wind.json`.

### 4 Regional Contexts
| Context | Type | Elements | Connections |
|---------|------|----------|-------------|
| `north_sea_offshore_wind` | Fixed-bottom | 71 | 57 |
| `baltic_offshore_wind` | Fixed-bottom | 58 | 39 |
| `atlantic_floating_wind` | Floating | 40 | 21 |
| `mediterranean_floating_wind` | Floating | 54 | 39 |

### Rebuilding the KB
```bash
micromamba run -n shiny python scripts/build_offshore_wind_kb.py
```
Requires BibTeX export at `.playwright-mcp/export-2026-4-9.bib`. Same JSON schema as the main `ses_knowledge_db.json` — loads via `ses_knowledge_db_loader.R`.

## Common Patterns

### Reactive Data Access
```r
# Project data is a reactiveValues list
project_data$isa_data$elements  # ISA elements
project_data$isa_data$connections  # Connections
project_data$metadata  # Project metadata
```

### Navigation Between Modules
```r
# Use updateTabItems for sidebar navigation
updateTabItems(session, "sidebar", "cld_visualization")
```

### Network Visualization
```r
# Create network from ISA data (functions/network_analysis.R)
network <- create_network_from_isa(isa_data)
visNetworkOutput(ns("network"))
```

## Debugging

```r
# Enable debug mode
Sys.setenv(MARINESABRES_DEBUG = "TRUE")

# Debug logging (not cat())
debug_log("Message here", "CATEGORY")

# Check translation loading
i18n$get_translations()  # See loaded keys
```

## Key Documentation

- `CONTRIBUTING.md` - Full contribution guide with i18n requirements
- `DAPSIWRM_FRAMEWORK_RULES.md` - Domain model and connection rules
- `translations/README.md` - i18n system guide
- `tests/README.md` - Testing framework documentation
- `tests/E2E_TESTING.md` - Browser-based test setup
- `docs/ARCHITECTURE.md` - Architecture Decision Records

## Shell Commands

- Never use `cd <path> && git <cmd>`. Always use `git -C <path> <cmd>` instead.
- If you need to run multiple commands in a subdirectory, use separate tool calls rather than chaining with `&&`.
