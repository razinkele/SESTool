# Error Handling Guide

**Version:** 1.0
**Last Updated:** 2025-10-25
**Target Audience:** Developers working on MarineSABRES SES Tool

---

## Table of Contents

1. [Introduction](#introduction)
2. [Core Principles](#core-principles)
3. [Error Handling Patterns](#error-handling-patterns)
4. [Enhanced Functions Reference](#enhanced-functions-reference)
5. [Shiny-Specific Error Handling](#shiny-specific-error-handling)
6. [Common Scenarios](#common-scenarios)
7. [Testing Error Handling](#testing-error-handling)
8. [Troubleshooting](#troubleshooting)
9. [Best Practices Checklist](#best-practices-checklist)

---

## Introduction

### Purpose

This guide provides practical patterns and best practices for error handling in the MarineSABRES SES Tool. Following these patterns ensures:

- **Application stability** - No unhandled crashes
- **Better debugging** - Clear error messages
- **Graceful degradation** - Partial functionality preserved
- **User experience** - Informative feedback instead of cryptic errors

### When to Use This Guide

- Writing new functions
- Enhancing existing functions
- Handling user input in modules
- Implementing file operations
- Working with external packages
- Debugging production issues

---

## Core Principles

### 1. Validate Early, Fail Fast

**Always validate inputs at function entry:**

```r
# Good
my_function <- function(data, threshold) {
  # Validate immediately
  if (is.null(data)) {
    stop("data cannot be NULL")
  }

  if (!is.numeric(threshold)) {
    stop("threshold must be numeric, got: ", class(threshold)[1])
  }

  # Proceed with validated inputs
  result <- process_data(data, threshold)
  return(result)
}
```

**Why:** Catching errors early makes debugging easier and prevents cascading failures.

### 2. Never Silently Fail

**Always log errors, even if you handle them:**

```r
# Bad - Silent failure
result <- tryCatch({
  risky_operation()
}, error = function(e) {
  NULL  # User has no idea what happened
})

# Good - Log the error
result <- tryCatch({
  risky_operation()
}, error = function(e) {
  log_message(paste("Error in risky_operation:", e$message), "ERROR")
  return(NULL)
})
```

**Why:** Logs are essential for debugging production issues.

### 3. Return Consistent Values

**Functions should return predictable types:**

```r
# Good - Consistent return type
get_data_safe <- function(id) {
  tryCatch({
    # Return dataframe on success
    load_data(id)
  }, error = function(e) {
    log_message(paste("Failed to load data:", e$message), "ERROR")
    # Return NULL on error (documented behavior)
    return(NULL)
  })
}

# Usage
data <- get_data_safe("proj_123")
if (is.null(data)) {
  # Handle error case
  showNotification("Failed to load data", type = "error")
  return()
}
```

**Why:** Predictable return types make code easier to use and test.

### 4. Clean Up Resources

**Always clean up, even on error:**

```r
# Good - Cleanup guaranteed
process_file_safe <- function(file_path) {
  temp_file <- NULL

  tryCatch({
    temp_file <- tempfile()

    # ... do work ...

    # Normal cleanup
    unlink(temp_file)
    return(result)

  }, error = function(e) {
    # Error cleanup
    if (!is.null(temp_file) && file.exists(temp_file)) {
      tryCatch(unlink(temp_file), error = function(e2) {})
    }

    log_message(paste("Error:", e$message), "ERROR")
    return(NULL)
  })
}
```

**Why:** Resource leaks can cause serious problems over time.

### 5. Provide Context in Errors

**Error messages should be actionable:**

```r
# Bad - Vague error
stop("Invalid input")

# Good - Specific error with context
stop("Invalid input: expected dataframe with columns 'id' and 'name', got: ",
     paste(names(input), collapse = ", "))
```

**Why:** Good error messages save debugging time.

---

## Error Handling Patterns

### Pattern 1: Simple Input Validation

**Use Case:** Validate function parameters

```r
validate_and_process <- function(data, min_rows = 1) {
  tryCatch({

    # Type validation
    if (is.null(data)) {
      stop("data cannot be NULL")
    }

    if (!is.data.frame(data)) {
      stop("data must be dataframe, got: ", class(data)[1])
    }

    # Range validation
    if (nrow(data) < min_rows) {
      stop("data has ", nrow(data), " rows, minimum required: ", min_rows)
    }

    # Process validated data
    result <- process(data)
    return(result)

  }, error = function(e) {
    log_message(paste("Validation failed:", e$message), "ERROR")
    return(NULL)
  })
}
```

**Key Points:**
- Check NULL first
- Validate types before using
- Check ranges and constraints
- Return NULL on validation failure

### Pattern 2: Multi-Step Operation with Partial Success

**Use Case:** Operations where some steps can fail independently

```r
analyze_project_safe <- function(project_data) {

  results <- list()

  # Step 1: Network analysis (can fail independently)
  results$network <- tryCatch({
    calculate_network_metrics_safe(project_data$cld$nodes,
                                   project_data$cld$edges)
  }, error = function(e) {
    log_message(paste("Network analysis failed:", e$message), "WARNING")
    NULL  # Continue with other analyses
  })

  # Step 2: MICMAC analysis (can fail independently)
  results$micmac <- tryCatch({
    calculate_micmac_safe(project_data$cld$nodes,
                         project_data$cld$edges)
  }, error = function(e) {
    log_message(paste("MICMAC analysis failed:", e$message), "WARNING")
    NULL  # Continue with other analyses
  })

  # Step 3: Loop detection (can fail independently)
  results$loops <- tryCatch({
    find_all_cycles_safe(project_data$cld$nodes,
                        project_data$cld$edges)
  }, error = function(e) {
    log_message(paste("Loop detection failed:", e$message), "WARNING")
    NULL  # Continue with other analyses
  })

  # Return partial results
  return(results)
}
```

**Key Points:**
- Isolate each step in separate tryCatch
- Log warnings for partial failures
- Return partial results (don't fail completely)
- Let caller decide if partial results are acceptable

### Pattern 3: Resource Management

**Use Case:** Working with files, devices, or connections

```r
export_with_cleanup <- function(data, file_path) {

  # Track resources for cleanup
  wb <- NULL
  temp_dir <- NULL

  tryCatch({

    # Create resources
    wb <- createWorkbook()
    temp_dir <- tempdir()

    # Do work
    writeData(wb, "Sheet1", data)
    saveWorkbook(wb, file_path)

    # Success - normal cleanup
    cleanup_temp(temp_dir)

    log_message(paste("Export successful:", file_path), "INFO")
    return(TRUE)

  }, error = function(e) {

    # Error - cleanup resources
    if (!is.null(wb)) {
      tryCatch({
        # Close workbook if needed
      }, error = function(e2) {})
    }

    if (!is.null(temp_dir) && dir.exists(temp_dir)) {
      tryCatch({
        unlink(temp_dir, recursive = TRUE)
      }, error = function(e2) {})
    }

    log_message(paste("Export failed:", e$message), "ERROR")
    return(FALSE)
  })
}
```

**Key Points:**
- Initialize resource variables to NULL
- Clean up in both success and error paths
- Wrap cleanup in tryCatch (don't fail on cleanup errors)
- Return success indicator

### Pattern 4: Validation Functions

**Use Case:** Reusable validation logic

```r
# Validation function that throws errors
validate_project_inputs <- function(project_name, da_site) {

  # Project name validation
  if (is.null(project_name)) {
    stop("project_name is required")
  }

  if (!is.character(project_name)) {
    stop("project_name must be character string")
  }

  if (nchar(project_name) == 0) {
    stop("project_name cannot be empty")
  }

  if (nchar(project_name) > 200) {
    stop("project_name too long (max 200 characters)")
  }

  # DA site validation (optional parameter)
  if (!is.null(da_site)) {
    if (!is.character(da_site)) {
      stop("da_site must be character string if provided")
    }
  }

  return(TRUE)
}

# Usage in function
create_project_safe <- function(project_name, da_site = NULL) {
  tryCatch({

    # Use validation function
    validate_project_inputs(project_name, da_site)

    # Proceed with validated inputs
    project <- create_project_structure(project_name, da_site)
    return(project)

  }, error = function(e) {
    log_message(paste("Project creation failed:", e$message), "ERROR")
    return(NULL)
  })
}
```

**Key Points:**
- Create reusable validation functions
- Validation functions throw errors (don't return values)
- Wrap validation call in tryCatch
- Clear, specific error messages

### Pattern 5: Graceful Degradation with Defaults

**Use Case:** Non-critical operations that should have fallbacks

```r
load_config_safe <- function(config_file, defaults) {

  config <- defaults  # Start with defaults

  # Try to load custom config
  custom_config <- tryCatch({

    if (!file.exists(config_file)) {
      log_message(paste("Config file not found:", config_file,
                       "- using defaults"), "INFO")
      return(NULL)
    }

    jsonlite::fromJSON(config_file)

  }, error = function(e) {
    log_message(paste("Error loading config:", e$message,
                     "- using defaults"), "WARNING")
    return(NULL)
  })

  # Merge custom config with defaults (if loaded)
  if (!is.null(custom_config)) {
    config <- modifyList(defaults, custom_config)
  }

  return(config)
}
```

**Key Points:**
- Start with safe default values
- Try to load better values
- Fall back to defaults on error
- Log what happened

### Pattern 6: Error Context Accumulation

**Use Case:** Building detailed error reports

```r
validate_complete_project <- function(project_data) {

  errors <- c()
  warnings <- c()

  # Validate structure
  structure_result <- tryCatch({
    validate_project_structure(project_data)
    TRUE
  }, error = function(e) {
    errors <<- c(errors, paste("Structure:", e$message))
    FALSE
  })

  # Validate ISA data
  if (structure_result && !is.null(project_data$data$isa_data)) {
    isa_result <- tryCatch({
      isa_errors <- validate_isa_structure_safe(project_data$data$isa_data)
      if (length(isa_errors) > 0) {
        warnings <<- c(warnings, isa_errors)
      }
      TRUE
    }, error = function(e) {
      errors <<- c(errors, paste("ISA validation:", e$message))
      FALSE
    })
  }

  # Return comprehensive report
  list(
    valid = length(errors) == 0,
    errors = errors,
    warnings = warnings
  )
}
```

**Key Points:**
- Collect all errors, don't fail on first
- Distinguish between errors and warnings
- Return detailed report
- Useful for validation operations

---

## Enhanced Functions Reference

### Quick Reference Table

| Function Category | Enhanced Version | Original Version | Return on Error |
|-------------------|------------------|------------------|-----------------|
| **Network Analysis** |
| Network metrics | `calculate_network_metrics_safe()` | `calculate_network_metrics()` | NULL |
| Graph creation | `create_igraph_from_data_safe()` | `create_igraph_from_data()` | NULL |
| MICMAC | `calculate_micmac_safe()` | `calculate_micmac()` | NULL |
| Cycle detection | `find_all_cycles_safe()` | `find_all_cycles()` | Empty list |
| **Data Structures** |
| Project creation | `create_empty_project_safe()` | `create_empty_project()` | NULL |
| Element creation | `create_empty_element_df_safe()` | `create_empty_element_df()` | NULL |
| Matrix creation | `create_empty_adjacency_matrix_safe()` | `create_empty_adjacency_matrix()` | NULL |
| Project validation | `validate_project_data_safe()` | `validate_project_data()` | Error list |
| Add element | `add_element_safe()` | `add_element()` | Unchanged data |
| **Export Functions** |
| PNG export | `export_cld_png_safe()` | `export_cld_png()` | FALSE |
| HTML export | `export_cld_html_safe()` | `export_cld_html()` | FALSE |
| PDF export | `export_bot_pdf_safe()` | `export_bot_pdf()` | FALSE |
| Excel export | `export_project_excel_safe()` | `export_project_excel()` | FALSE |
| JSON export | `export_project_json_safe()` | `export_project_json()` | FALSE |

### Usage Examples

#### Network Analysis

```r
# Calculate metrics safely
metrics <- calculate_network_metrics_safe(nodes, edges)

if (is.null(metrics)) {
  showNotification("Failed to calculate network metrics", type = "error")
  return()
}

# Use metrics
output$density <- renderText(paste("Density:", metrics$density))
```

#### Data Structure Creation

```r
# Create project safely
project <- create_empty_project_safe(input$project_name, input$da_site)

if (is.null(project)) {
  showNotification("Failed to create project. Check project name.", type = "error")
  return()
}

# Store project
project_data(project)
```

#### Export Operations

```r
# Export to Excel
observeEvent(input$export_button, {
  req(project_data())

  success <- export_project_excel_safe(
    project_data(),
    file_path = input$output_path
  )

  if (success) {
    showNotification("Export successful!", type = "message")
  } else {
    showNotification(
      "Export failed. Check the log for details.",
      type = "error",
      duration = NULL
    )
  }
})
```

---

## Shiny-Specific Error Handling

### Module-Level Error Handling

```r
# Module server function
data_import_server <- function(id) {
  moduleServer(id, function(input, output, session) {

    # Reactive for imported data
    imported_data <- reactiveVal(NULL)

    # File upload handler with error handling
    observeEvent(input$file_upload, {
      req(input$file_upload)

      # Show progress
      withProgress(message = "Importing data...", {

        # Try to import
        data <- tryCatch({

          import_isa_excel_safe(input$file_upload$datapath)

        }, error = function(e) {

          # Show user-friendly error
          showNotification(
            paste("Import failed:", e$message),
            type = "error",
            duration = NULL
          )

          # Log detailed error
          log_message(paste("Import error:", e$message,
                           "- File:", input$file_upload$name), "ERROR")

          return(NULL)
        })

        # Check result
        if (is.null(data)) {
          # Error notification already shown
          return()
        }

        # Validate imported data
        validation <- validate_isa_structure_safe(data)

        if (length(validation) > 0) {
          showNotification(
            paste("Data validation warnings:",
                  paste(validation, collapse = "; ")),
            type = "warning",
            duration = 10
          )
        }

        # Store data
        imported_data(data)

        # Success notification
        showNotification("Data imported successfully!", type = "message")
      })
    })

    # Return reactive
    return(imported_data)
  })
}
```

**Key Points:**
- Use `req()` to ensure inputs are available
- Wrap operations in `withProgress()` for user feedback
- Show user-friendly notifications
- Log detailed errors
- Validate after import
- Return reactives for module communication

### Input Validation in Observers

```r
observeEvent(input$create_element, {

  # Validate required inputs
  if (is.null(input$element_name) || input$element_name == "") {
    showNotification("Element name is required", type = "warning")
    return()
  }

  if (is.null(input$element_type)) {
    showNotification("Element type is required", type = "warning")
    return()
  }

  # Validate value ranges
  if (!is.na(input$baseline_value) && input$baseline_value < 0) {
    showNotification("Baseline value cannot be negative", type = "warning")
    return()
  }

  # Create element safely
  new_element <- tryCatch({

    create_element_data(
      name = input$element_name,
      type = input$element_type,
      baseline = input$baseline_value
    )

  }, error = function(e) {
    showNotification(
      paste("Failed to create element:", e$message),
      type = "error"
    )
    log_message(paste("Element creation error:", e$message), "ERROR")
    return(NULL)
  })

  if (is.null(new_element)) {
    return()
  }

  # Add to project
  current_project <- project_data()
  updated_project <- add_element_safe(
    current_project$data$isa_data,
    input$element_type,
    new_element
  )

  project_data(updated_project)

  showNotification("Element created successfully!", type = "message")
})
```

**Key Points:**
- Validate inputs before processing
- Use early returns for validation failures
- Show specific validation messages
- Wrap creation in tryCatch
- Check results before updating state

### Reactive Expression Error Handling

```r
# Reactive with error handling
network_metrics <- reactive({

  req(project_data())
  req(project_data()$data$cld$nodes)
  req(project_data()$data$cld$edges)

  nodes <- project_data()$data$cld$nodes
  edges <- project_data()$data$cld$edges

  # Calculate metrics safely
  metrics <- calculate_network_metrics_safe(nodes, edges)

  if (is.null(metrics)) {
    # Return empty metrics on error
    return(list(
      density = 0,
      avg_degree = 0,
      components = 0,
      error = TRUE
    ))
  }

  metrics$error <- FALSE
  return(metrics)
})

# Use in output
output$metrics_display <- renderUI({

  metrics <- network_metrics()

  if (metrics$error) {
    div(
      class = "alert alert-warning",
      "Unable to calculate network metrics. Check data quality."
    )
  } else {
    div(
      h4("Network Metrics"),
      p("Density:", round(metrics$density, 3)),
      p("Average Degree:", round(metrics$avg_degree, 2)),
      p("Components:", metrics$components)
    )
  }
})
```

**Key Points:**
- Use `req()` to check dependencies
- Calculate safely in reactive
- Return safe default on error
- Include error flag in result
- Handle error state in UI

---

## Common Scenarios

### Scenario 1: File Upload and Processing

```r
observeEvent(input$upload_file, {
  req(input$upload_file)

  # Validate file type
  file_ext <- tools::file_ext(input$upload_file$name)

  if (!file_ext %in% c("xlsx", "xls")) {
    showNotification(
      "Invalid file type. Please upload Excel file (.xlsx or .xls)",
      type = "error"
    )
    return()
  }

  # Check file size (example: 10MB limit)
  file_size_mb <- input$upload_file$size / 1024 / 1024
  if (file_size_mb > 10) {
    showNotification(
      paste("File too large:", round(file_size_mb, 1),
            "MB. Maximum: 10 MB"),
      type = "error"
    )
    return()
  }

  # Process file
  withProgress(message = "Processing file...", {

    data <- tryCatch({

      # Try to read file
      import_isa_excel_safe(input$upload_file$datapath)

    }, error = function(e) {
      showNotification(
        paste("Failed to read file:", e$message),
        type = "error",
        duration = NULL
      )
      log_message(paste("File read error:", e$message), "ERROR")
      return(NULL)
    })

    if (is.null(data)) {
      return()
    }

    # Validate content
    validation <- validate_isa_structure_safe(data)

    if (length(validation) > 0) {
      showNotification(
        paste("File contains issues:",
              paste(head(validation, 3), collapse = "; "),
              if (length(validation) > 3) "..." else ""),
        type = "warning",
        duration = 15
      )
    }

    # Success
    imported_data(data)
    showNotification("File imported successfully!", type = "message")
  })
})
```

### Scenario 2: Network Analysis Pipeline

```r
perform_analysis <- function(project_data) {

  # Step 1: Validate input
  if (is.null(project_data$data$cld$nodes)) {
    log_message("No nodes available for analysis", "WARNING")
    return(list(success = FALSE, error = "No network data available"))
  }

  nodes <- project_data$data$cld$nodes
  edges <- project_data$data$cld$edges

  # Step 2: Calculate metrics
  metrics <- calculate_network_metrics_safe(nodes, edges)
  if (is.null(metrics)) {
    return(list(success = FALSE, error = "Metric calculation failed"))
  }

  # Step 3: MICMAC analysis
  micmac <- calculate_micmac_safe(nodes, edges)
  if (is.null(micmac)) {
    log_message("MICMAC analysis failed - continuing with other analyses", "WARNING")
    # Continue without MICMAC
  }

  # Step 4: Find loops
  loops <- find_all_cycles_safe(nodes, edges)
  if (is.null(loops) || length(loops) == 0) {
    log_message("No loops detected or detection failed", "INFO")
    loops <- list()
  }

  # Return results
  list(
    success = TRUE,
    metrics = metrics,
    micmac = micmac,
    loops = loops
  )
}
```

### Scenario 3: Batch Export with Progress

```r
observeEvent(input$export_all, {
  req(project_data())

  # Define exports
  exports <- list(
    list(name = "Excel", func = export_project_excel_safe, ext = ".xlsx"),
    list(name = "JSON", func = export_project_json_safe, ext = ".json"),
    list(name = "CSV", func = export_project_csv_zip_safe, ext = ".zip")
  )

  withProgress(message = "Exporting...", value = 0, {

    results <- list()

    for (i in seq_along(exports)) {
      export <- exports[[i]]

      # Update progress
      incProgress(1/length(exports), detail = export$name)

      # Construct file path
      file_path <- file.path(
        input$output_dir,
        paste0(project_data()$project_name, export$ext)
      )

      # Try export
      success <- tryCatch({

        export$func(project_data(), file_path)

      }, error = function(e) {
        log_message(paste(export$name, "export failed:", e$message), "ERROR")
        FALSE
      })

      results[[export$name]] <- success
    }

    # Summary notification
    successes <- sum(unlist(results))
    total <- length(results)

    if (successes == total) {
      showNotification("All exports completed successfully!", type = "message")
    } else if (successes > 0) {
      showNotification(
        paste(successes, "of", total, "exports completed successfully"),
        type = "warning"
      )
    } else {
      showNotification("All exports failed. Check the log.", type = "error")
    }
  })
})
```

---

## Testing Error Handling

### Unit Tests for Error Cases

```r
# Test file: tests/testthat/test-error-handling.R

test_that("create_empty_project_safe handles NULL project_name", {
  result <- create_empty_project_safe(NULL)
  expect_null(result)
})

test_that("create_empty_project_safe handles empty string", {
  result <- create_empty_project_safe("")
  expect_null(result)
})

test_that("create_empty_project_safe handles invalid type", {
  result <- create_empty_project_safe(123)  # Number instead of string
  expect_null(result)
})

test_that("create_empty_project_safe succeeds with valid input", {
  result <- create_empty_project_safe("Test Project")
  expect_false(is.null(result))
  expect_equal(result$project_name, "Test Project")
})

test_that("validate_nodes catches missing required columns", {
  bad_nodes <- data.frame(name = c("A", "B"))
  expect_error(
    validate_nodes(bad_nodes),
    "Missing required columns: id"
  )
})

test_that("calculate_network_metrics_safe handles empty graph", {
  nodes <- data.frame(id = character(), name = character())
  edges <- data.frame(from = character(), to = character())

  result <- calculate_network_metrics_safe(nodes, edges)
  expect_null(result)
})

test_that("export_project_excel_safe handles invalid path", {
  project <- create_empty_project_safe("Test")
  invalid_path <- "/nonexistent/directory/output.xlsx"

  result <- export_project_excel_safe(project, invalid_path)
  expect_false(result)
})
```

### Integration Tests

```r
test_that("Complete workflow with error recovery", {
  # Create project
  project <- create_empty_project_safe("Integration Test")
  expect_false(is.null(project))

  # Add invalid element (should fail gracefully)
  bad_element <- data.frame(name = "Test")  # Missing required columns
  result <- add_element_safe(project$data$isa_data, "drivers", bad_element)

  # Should return unchanged data
  expect_equal(result, project$data$isa_data)

  # Add valid element (should succeed)
  good_element <- create_empty_element_df_safe("Drivers")[1,]
  good_element$id <- "TEST_01"
  good_element$name <- "Test Driver"

  result <- add_element_safe(project$data$isa_data, "drivers", good_element)
  expect_true(nrow(result$drivers) == 1)
})
```

### Manual Testing Checklist

- [ ] Test with NULL inputs
- [ ] Test with wrong data types
- [ ] Test with empty dataframes
- [ ] Test with missing columns
- [ ] Test with invalid file paths
- [ ] Test with non-existent files
- [ ] Test with corrupted files
- [ ] Test with insufficient disk space
- [ ] Test with read-only directories
- [ ] Test with very large inputs
- [ ] Test with special characters in strings
- [ ] Test network timeout scenarios (if applicable)

---

## Troubleshooting

### Common Issues and Solutions

#### Issue 1: Function returns NULL unexpectedly

**Symptoms:** Enhanced function returns NULL even though input looks valid

**Debugging Steps:**
1. Check application log for error messages
2. Verify input types with `class()` and `typeof()`
3. Check for required columns with `names()`
4. Verify data ranges (no negatives where positive expected, etc.)

**Solution:**
```r
# Add temporary logging to see what's failing
result <- create_empty_project_safe(project_name)
if (is.null(result)) {
  cat("Project name:", project_name, "\n")
  cat("Type:", class(project_name), "\n")
  cat("Length:", nchar(project_name), "\n")
  # Check log file for specific error
}
```

#### Issue 2: Export fails silently

**Symptoms:** Export function returns FALSE but no clear error

**Debugging Steps:**
1. Check log file for detailed error message
2. Verify output directory exists and is writable
3. Check available disk space
4. Try exporting to different location

**Solution:**
```r
# Test directory writability
test_file <- file.path(output_dir, ".test")
can_write <- tryCatch({
  writeLines("test", test_file)
  file.remove(test_file)
  TRUE
}, error = function(e) FALSE)

if (!can_write) {
  showNotification("Output directory is not writable", type = "error")
}
```

#### Issue 3: Validation fails but error message unclear

**Symptoms:** Validation returns errors but message doesn't help

**Debugging Steps:**
1. Use validation function directly to see specific errors
2. Check each component separately
3. Print structure of problematic data

**Solution:**
```r
# Debug validation
validation <- validate_project_data_safe(project)

if (!validation$valid) {
  cat("Validation errors:\n")
  for (err in validation$errors) {
    cat("  -", err, "\n")
  }

  # Check structure
  str(project, max.level = 2)
}
```

#### Issue 4: Network analysis returns unexpected results

**Symptoms:** Metrics are 0 or NA when graph has data

**Debugging Steps:**
1. Check nodes and edges dataframes separately
2. Verify edge endpoints exist in nodes
3. Check for NA values in critical columns

**Solution:**
```r
# Validate network data
validate_nodes(nodes)  # Will throw error if invalid
validate_edges(edges, c("from", "to"))

# Check edge endpoints
invalid_edges <- edges[!(edges$from %in% nodes$id) |
                       !(edges$to %in% nodes$id), ]

if (nrow(invalid_edges) > 0) {
  cat("Found", nrow(invalid_edges), "edges with invalid endpoints\n")
  print(invalid_edges)
}
```

### Getting Help

**When Stuck:**

1. **Check the log file** - Most errors are logged with details
2. **Use validation functions** - Run validators separately to isolate issues
3. **Add temporary logging** - Insert `log_message()` calls to trace execution
4. **Test with minimal example** - Create smallest possible test case
5. **Check function documentation** - Review return values and error conditions

**Log File Locations:**
- Development: Console output
- Production: Check `global.R` for log configuration

---

## Best Practices Checklist

### For New Functions

- [ ] Validate all input parameters at function start
- [ ] Use appropriate validation functions
- [ ] Wrap operations in tryCatch
- [ ] Log errors with context
- [ ] Return consistent types (NULL, FALSE, or default on error)
- [ ] Clean up resources in error handler
- [ ] Include function name in error messages
- [ ] Document return values including error cases
- [ ] Write tests for error scenarios

### For Shiny Modules

- [ ] Use `req()` for reactive dependencies
- [ ] Validate user inputs before processing
- [ ] Show user-friendly notifications
- [ ] Log detailed errors separately
- [ ] Wrap long operations in `withProgress()`
- [ ] Handle NULL returns from enhanced functions
- [ ] Provide fallback UI for error states
- [ ] Test with invalid inputs

### For File Operations

- [ ] Validate file paths
- [ ] Check directory writability
- [ ] Verify disk space
- [ ] Use temporary files safely
- [ ] Clean up temp files in error handler
- [ ] Verify output file created
- [ ] Check file size after creation
- [ ] Return success indicator

### Code Review Checklist

- [ ] No silent failures (all errors logged)
- [ ] Error messages are actionable
- [ ] Resources are cleaned up
- [ ] Return values are consistent
- [ ] NULL checks before dereferencing
- [ ] Type checks before operations
- [ ] Input validation comprehensive
- [ ] Tests cover error cases

---

## Additional Resources

### Related Documentation

- `ERROR_HANDLING_IMPROVEMENTS_SUMMARY.md` - Detailed summary of enhanced functions
- `HIGH_PRIORITY_IMPROVEMENTS_STATUS.md` - Implementation progress tracker
- `TESTING_GUIDE.md` - Testing framework documentation

### Enhanced Function Files

- `functions/network_analysis_enhanced.R` - Network analysis with error handling
- `functions/data_structure_enhanced.R` - Data structures with error handling
- `functions/export_functions_enhanced.R` - Export operations with error handling

### Validation Utilities

Each enhanced file contains validation utilities:
- Network: `validate_nodes()`, `validate_edges()`, `validate_igraph()`
- Data: `validate_project_structure()`, `validate_element_type()`, `validate_element_data()`
- Export: `validate_output_path()`, `validate_visnetwork()`, `validate_export_project()`

---

## Appendix: Quick Reference

### Error Handling Quick Commands

```r
# Validate project
validation <- validate_project_data_safe(project_data)
if (!validation$valid) {
  print(validation$errors)
}

# Safe network analysis
metrics <- calculate_network_metrics_safe(nodes, edges)
if (is.null(metrics)) { /* handle error */ }

# Safe export
success <- export_project_excel_safe(project, "output.xlsx")
if (!success) { /* handle error */ }

# Check logs
log_message("Custom message", "INFO")  # INFO, WARNING, ERROR
```

### Common Validation Patterns

```r
# NULL check
if (is.null(x)) stop("x cannot be NULL")

# Type check
if (!is.data.frame(x)) stop("x must be dataframe")

# Column check
required <- c("id", "name")
missing <- setdiff(required, names(x))
if (length(missing) > 0) stop("Missing columns: ", paste(missing, collapse = ", "))

# Range check
if (x < 0) stop("x must be non-negative")
if (x < min || x > max) stop("x must be between ", min, " and ", max)
```

---

**Document Version:** 1.0
**Last Updated:** 2025-10-25
**Maintainer:** Development Team
**Next Review:** After Phase 2 (Input Validation)

