# Module Signature Standard - MarineSABRES SES Toolbox

## Overview

This document defines the standard conventions for Shiny modules in the MarineSABRES SES Toolbox. Following these conventions ensures consistency, maintainability, and proper i18n integration.

## File Structure

### File Header
```r
# =============================================================================
# MODULE: [Module Name]
# File: modules/[filename].R
# =============================================================================
#
# Purpose:
#   [Brief description of what this module does]
#
# Dependencies:
#   - [List required packages/modules]
#
# Exports:
#   - [module_name]_ui(id, i18n)
#   - [module_name]_server(id, ...)
#
# =============================================================================
```

## UI Function Signature

### Standard Pattern
```r
#' [Module Name] UI
#'
#' @param id Character. Module namespace ID
#' @param i18n Translator object for internationalization
#' @return A Shiny UI element
#' @export
module_name_ui <- function(id, i18n) {
  # REQUIRED: Enable reactive translations (defensive form)
  tryCatch(shiny.i18n::usei18n(i18n$translator %||% i18n), error = function(e) NULL)
  ns <- NS(id)

  # UI implementation
  fluidPage(
    # Use i18n$t() for ALL user-facing text
    h3(i18n$t("module.title")),
    # ...
  )
}
```

### Key Requirements
1. **Always use the defensive `usei18n()` wrapper** as the first line: `tryCatch(shiny.i18n::usei18n(i18n$translator %||% i18n), error = function(e) NULL)`
2. **Create namespace** with `ns <- NS(id)`
3. **Use `i18n$t()`** for all user-facing text
4. **Use `ns()`** for all input/output IDs

## Server Function Signature

### Standard Pattern
```r
#' [Module Name] Server
#'
#' @param id Character. Module namespace ID
#' @param project_data_reactive Reactive containing project data
#' @param i18n Translator object for internationalization
#' @param event_bus Optional EventBus for cross-module communication
#' @return NULL or list of reactive values
#' @export
module_name_server <- function(id, project_data_reactive, i18n, event_bus = NULL, ...) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # Reactive values
    rv <- reactiveValues()

    # Observers
    # ...

    # Outputs
    # ...

    return(NULL)  # or return(list(...))
  })
}
```

### Parameter Order
1. `id` - Module namespace ID (required)
2. `project_data_reactive` - Main data reactive (required)
3. `i18n` - Translator (required)
4. `event_bus` - Event bus (optional, default NULL)
5. Additional parameters as needed

## Naming Conventions

### Module Names
- Use `snake_case`: `analysis_metrics`, `create_ses`, `entry_point`
- Suffix with `_module` only for the filename: `analysis_metrics_module.R`

### Function Names
- UI: `module_name_ui()`
- Server: `module_name_server()`

### Internal Functions
- Prefix with `.` for private: `.validate_input()`
- Or define inside `moduleServer()` scope

## i18n Integration

### DO Translate
```r
# User-facing text
h4(i18n$t("section.title"))
actionButton(ns("save"), i18n$t("buttons.save"))
showNotification(i18n$t("messages.success"), type = "message")

# Dynamic messages
paste(i18n$t("found"), count, i18n$t("items"))
```

### DO NOT Translate
```r
# Technical IDs
ns("field_id")

# File paths
"data/file.csv"

# Log messages (debug output)
debug_log("Processing data", "INFO")

# R error messages (translate prefix only)
paste(i18n$t("error_prefix"), e$message)
```

## Event Bus Integration

```r
module_name_server <- function(id, project_data_reactive, i18n, event_bus = NULL) {
  moduleServer(id, function(input, output, session) {

    # Emit events
    if (!is.null(event_bus)) {
      event_bus$emit_isa_change()
    }

    # Listen for events
    if (!is.null(event_bus)) {
      observe({
        event_bus$on_isa_change()
        # Handle ISA data change
      })
    }
  })
}
```

## Error Handling

```r
output$result <- renderUI({
  tryCatch({
    # Risky operation
    validate_data(input$data)
    generate_output()
  }, error = function(e) {
    debug_log(paste("Error:", e$message), "ERROR")
    showNotification(
      paste(i18n$t("error_prefix"), e$message),
      type = "error"
    )
    NULL
  })
})
```

## Template

See `modules/_module_template.R` for a complete template.

## Validation

Run module signature tests:
```bash
Rscript -e "testthat::test_file('tests/testthat/test-module-signatures.R')"
```
