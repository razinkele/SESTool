# Input Validation Guide for Shiny Modules

**Version:** 1.0
**Last Updated:** 2025-10-25
**Target Audience:** Developers working on Shiny modules

---

## Table of Contents

1. [Introduction](#introduction)
2. [Validation Helper Functions](#validation-helper-functions)
3. [Basic Validation Patterns](#basic-validation-patterns)
4. [Advanced Patterns](#advanced-patterns)
5. [Complete Examples](#complete-examples)
6. [Testing Validation](#testing-validation)
7. [Best Practices](#best-practices)

---

## Introduction

### Purpose

This guide demonstrates how to validate user inputs in Shiny modules using the validation helper functions from `module_validation_helpers.R`. Proper validation ensures:

- **Data Quality** - Only valid data enters the system
- **User Experience** - Clear, immediate feedback on input errors
- **Application Stability** - Prevent errors from invalid data
- **Security** - Reject malicious or malformed inputs

### When to Validate

**Always validate:**
- Text inputs from users
- Numeric inputs (ensure range, type)
- Select/dropdown choices
- Date inputs
- File uploads
- Any user-provided data before processing

**Validation points:**
- Before saving data
- Before calculations
- Before database operations
- Before file operations
- Before API calls

---

## Validation Helper Functions

### Available Validators

Located in `functions/module_validation_helpers.R`:

| Function | Purpose | Returns |
|----------|---------|---------|
| `validate_text_input()` | Validate text for length, pattern | `list(valid, message, value)` |
| `validate_numeric_input()` | Validate numbers for range, type | `list(valid, message, value)` |
| `validate_select_input()` | Validate dropdown selections | `list(valid, message, value)` |
| `validate_date_input()` | Validate dates for range | `list(valid, message, value)` |
| `validate_file_upload()` | Validate uploaded files | `list(valid, message, name, path)` |
| `validate_all()` | Validate multiple inputs | `logical` |
| `validate_stakeholder_values()` | Domain-specific validation | `list(valid, message)` |
| `validate_element_entry()` | Domain-specific validation | `list(valid, message)` |
| `validate_email()` | Email format validation | `list(valid, message, value)` |

### Return Value Structure

All validators return a list with:

```r
list(
  valid = TRUE/FALSE,           # Validation passed?
  message = "Error message",    # NULL if valid
  value = cleaned_value         # Cleaned/converted value (optional)
)
```

---

## Basic Validation Patterns

### Pattern 1: Validate Text Input

```r
# In module server function
observeEvent(input$save_button, {

  # Validate project name
  name_validation <- validate_text_input(
    value = input$project_name,
    field_name = "Project name",
    required = TRUE,
    min_length = 3,
    max_length = 100,
    session = session
  )

  # Check if valid before proceeding
  if (!name_validation$valid) {
    return()  # Validation already showed notification
  }

  # Use cleaned value
  project_name <- name_validation$value

  # Proceed with valid data
  save_project(project_name)
})
```

**Key Points:**
- Validator shows notification automatically
- Return early if invalid
- Use cleaned value from validation result

### Pattern 2: Validate Numeric Input

```r
observeEvent(input$save_stakeholder, {

  # Validate power value (0-10)
  power_validation <- validate_numeric_input(
    value = input$power,
    field_name = "Power",
    required = TRUE,
    min = 0,
    max = 10,
    session = session
  )

  # Validate interest value (0-10)
  interest_validation <- validate_numeric_input(
    value = input$interest,
    field_name = "Interest",
    required = TRUE,
    min = 0,
    max = 10,
    session = session
  )

  # Check both validations
  if (!power_validation$valid || !interest_validation$valid) {
    return()
  }

  # Save stakeholder
  save_stakeholder(
    power = power_validation$value,
    interest = interest_validation$value
  )
})
```

### Pattern 3: Validate Select Input

```r
observeEvent(input$save_element, {

  # Validate element type selection
  type_validation <- validate_select_input(
    value = input$element_type,
    field_name = "Element type",
    required = TRUE,
    valid_choices = c("Drivers", "Activities", "Pressures",
                     "Marine Processes", "Ecosystem Services",
                     "Goods & Benefits"),
    session = session
  )

  if (!type_validation$valid) {
    return()
  }

  # Proceed with validated selection
  create_element(type = type_validation$value)
})
```

### Pattern 4: Validate File Upload

```r
observeEvent(input$upload_file, {

  # Validate uploaded file
  file_validation <- validate_file_upload(
    file_input = input$file_upload,
    field_name = "ISA data file",
    required = TRUE,
    allowed_extensions = c("xlsx", "xls", "csv"),
    max_size_mb = 10,
    session = session
  )

  if (!file_validation$valid) {
    return()
  }

  # Import file
  withProgress(message = "Importing file...", {
    import_isa_data(file_validation$path)
  })
})
```

---

## Advanced Patterns

### Pattern 5: Validate Multiple Inputs Together

```r
observeEvent(input$save_driver, {

  # Validate all inputs
  validations <- list(
    validate_text_input(input$name, "Driver name", required = TRUE,
                       min_length = 2, max_length = 200, session = session),
    validate_text_input(input$indicator, "Indicator", required = FALSE,
                       max_length = 200, session = session),
    validate_select_input(input$needs_category, "Needs category",
                         required = TRUE,
                         valid_choices = c("Economic", "Social", "Environmental"),
                         session = session),
    validate_numeric_input(input$baseline, "Baseline value",
                          required = FALSE, positive_only = TRUE,
                          session = session)
  )

  # Check all at once
  if (!validate_all(validations, session)) {
    return()  # Combined notification shown
  }

  # All valid - proceed
  save_driver(
    name = validations[[1]]$value,
    indicator = validations[[2]]$value,
    category = validations[[3]]$value,
    baseline = validations[[4]]$value
  )
})
```

**Benefits:**
- Validates all inputs
- Shows single combined error message
- Clean code structure

### Pattern 6: Reactive Validation with Button State

```r
# In module server function

# Create reactive validation
form_valid <- reactive({
  req(input$name, input$type)

  validations <- list(
    validate_text_input(input$name, "Name", required = TRUE,
                       min_length = 2, session = NULL),  # No notification
    validate_select_input(input$type, "Type", required = TRUE,
                         valid_choices = element_types, session = NULL)
  )

  validate_all(validations, session = NULL)
})

# Enable/disable save button
observe({
  if (form_valid()) {
    shinyjs::enable("save_button")
  } else {
    shinyjs::disable("save_button")
  }
})

# Save action (already validated)
observeEvent(input$save_button, {
  # Data is already valid, just save
  save_element(name = input$name, type = input$type)
})
```

**Benefits:**
- Real-time validation feedback
- Save button only enabled when valid
- Better UX - no "save then fail" experience

### Pattern 7: Domain-Specific Validation

```r
# Using pre-built domain validators

observeEvent(input$save_stakeholder, {

  # Validate stakeholder-specific values
  values_validation <- validate_stakeholder_values(
    power = input$power,
    interest = input$interest,
    session = session
  )

  # Validate email
  email_validation <- validate_email(
    email = input$email,
    field_name = "Contact email",
    required = FALSE,
    session = session
  )

  if (!values_validation$valid || !email_validation$valid) {
    return()
  }

  # Save stakeholder
  save_stakeholder(
    power = input$power,
    interest = input$interest,
    email = if (email_validation$valid) email_validation$value else NULL
  )
})
```

### Pattern 8: Custom Validation Logic

```r
# Create custom validator for your domain

validate_element_connections <- function(from_id, to_id, session = NULL) {
  tryCatch({

    # Custom validation logic
    if (from_id == to_id) {
      msg <- "Element cannot connect to itself"
      if (!is.null(session)) {
        showNotification(msg, type = "warning", session = session)
      }
      return(list(valid = FALSE, message = msg))
    }

    # Check if connection already exists
    if (connection_exists(from_id, to_id)) {
      msg <- "This connection already exists"
      if (!is.null(session)) {
        showNotification(msg, type = "warning", session = session)
      }
      return(list(valid = FALSE, message = msg))
    }

    # Valid
    return(list(valid = TRUE, message = NULL))

  }, error = function(e) {
    log_message(paste("Error validating connection:", e$message), "ERROR")
    return(list(valid = FALSE, message = "Validation error"))
  })
}

# Use in module
observeEvent(input$add_connection, {

  connection_validation <- validate_element_connections(
    from_id = input$from_element,
    to_id = input$to_element,
    session = session
  )

  if (!connection_validation$valid) {
    return()
  }

  # Add connection
  add_connection(input$from_element, input$to_element)
})
```

---

## Complete Examples

### Example 1: Form with Multiple Inputs

```r
# Module for adding a driver element

driver_entry_server <- function(id, project_data) {
  moduleServer(id, function(input, output, session) {

    # Form validation reactive
    form_valid <- reactive({
      req(input$name)  # Wait for inputs to exist

      validations <- list(
        # Name (required, 2-200 chars)
        validate_text_input(
          input$name,
          "Driver name",
          required = TRUE,
          min_length = 2,
          max_length = 200,
          session = NULL
        ),

        # Indicator (optional, max 200 chars)
        validate_text_input(
          input$indicator,
          "Indicator",
          required = FALSE,
          max_length = 200,
          session = NULL
        ),

        # Needs category (required, must be valid choice)
        validate_select_input(
          input$needs_category,
          "Needs category",
          required = TRUE,
          valid_choices = c("Economic", "Social", "Environmental",
                           "Cultural", "Institutional"),
          session = NULL
        ),

        # Baseline value (optional, must be positive)
        validate_numeric_input(
          input$baseline_value,
          "Baseline value",
          required = FALSE,
          positive_only = TRUE,
          session = NULL
        ),

        # Current value (optional, must be positive)
        validate_numeric_input(
          input$current_value,
          "Current value",
          required = FALSE,
          positive_only = TRUE,
          session = NULL
        )
      )

      validate_all(validations, session = NULL)
    })

    # Enable/disable save button based on validation
    observe({
      if (form_valid()) {
        shinyjs::enable("save_driver")
        shinyjs::removeClass("save_driver", "btn-secondary")
        shinyjs::addClass("save_driver", "btn-primary")
      } else {
        shinyjs::disable("save_driver")
        shinyjs::removeClass("save_driver", "btn-primary")
        shinyjs::addClass("save_driver", "btn-secondary")
      }
    })

    # Save action (full validation with notifications)
    observeEvent(input$save_driver, {

      validations <- list(
        validate_text_input(input$name, "Driver name", required = TRUE,
                           min_length = 2, max_length = 200, session = session),
        validate_text_input(input$indicator, "Indicator", required = FALSE,
                           max_length = 200, session = session),
        validate_select_input(input$needs_category, "Needs category",
                             required = TRUE, session = session),
        validate_numeric_input(input$baseline_value, "Baseline value",
                              required = FALSE, positive_only = TRUE,
                              session = session),
        validate_numeric_input(input$current_value, "Current value",
                              required = FALSE, positive_only = TRUE,
                              session = session)
      )

      # Validate all (shows combined notification if errors)
      if (!validate_all(validations, session)) {
        return()
      }

      # Create driver element
      driver <- data.frame(
        id = generate_id("D"),
        name = validations[[1]]$value,
        indicator = validations[[2]]$value %||% "",
        needs_category = validations[[3]]$value,
        baseline_value = validations[[4]]$value %||% NA_real_,
        current_value = validations[[5]]$value %||% NA_real_,
        stringsAsFactors = FALSE
      )

      # Add to project
      current_project <- project_data()
      updated_project <- add_element_safe(
        current_project$data$isa_data,
        "drivers",
        driver
      )

      project_data(updated_project)

      # Success notification
      showNotification("Driver added successfully!", type = "message")

      # Reset form
      reset("driver_form")
    })
  })
}
```

### Example 2: File Upload with Validation

```r
# Module for importing ISA data

isa_import_server <- function(id, project_data) {
  moduleServer(id, function(input, output, session) {

    observeEvent(input$upload_isa, {

      # Validate file upload
      file_validation <- validate_file_upload(
        file_input = input$file_upload,
        field_name = "ISA data file",
        required = TRUE,
        allowed_extensions = c("xlsx", "xls"),
        max_size_mb = 10,
        session = session
      )

      if (!file_validation$valid) {
        return()
      }

      # Show progress
      withProgress(message = "Importing ISA data...", {

        # Try to import
        imported_data <- tryCatch({

          import_isa_excel_safe(file_validation$path)

        }, error = function(e) {
          showNotification(
            paste("Import failed:", e$message),
            type = "error",
            duration = NULL
          )
          log_message(paste("ISA import error:", e$message), "ERROR")
          return(NULL)
        })

        if (is.null(imported_data)) {
          return()
        }

        # Validate imported data structure
        validation_errors <- validate_isa_structure_safe(imported_data)

        if (length(validation_errors) > 0) {
          showNotification(
            paste("Data validation issues:",
                  paste(head(validation_errors, 5), collapse = "\n"),
                  if (length(validation_errors) > 5) "\n... and more" else ""),
            type = "warning",
            duration = 15
          )
        }

        # Update project data
        current_project <- project_data()
        current_project$data$isa_data <- imported_data
        project_data(current_project)

        # Success notification
        showNotification(
          paste("ISA data imported successfully from", file_validation$name),
          type = "message"
        )
      })
    })
  })
}
```

---

## Testing Validation

### Unit Tests for Validators

```r
# tests/testthat/test-module-validation.R

test_that("validate_text_input catches NULL input", {
  result <- validate_text_input(NULL, "Test", required = TRUE)

  expect_false(result$valid)
  expect_true(grepl("required", result$message))
})

test_that("validate_text_input catches empty string", {
  result <- validate_text_input("", "Test", required = TRUE)

  expect_false(result$valid)
  expect_true(grepl("empty", result$message))
})

test_that("validate_text_input enforces min length", {
  result <- validate_text_input("ab", "Test", min_length = 3)

  expect_false(result$valid)
  expect_true(grepl("at least 3", result$message))
})

test_that("validate_text_input enforces max length", {
  long_text <- paste(rep("a", 101), collapse = "")
  result <- validate_text_input(long_text, "Test", max_length = 100)

  expect_false(result$valid)
  expect_true(grepl("at most 100", result$message))
})

test_that("validate_text_input trims whitespace", {
  result <- validate_text_input("  test  ", "Test", required = TRUE)

  expect_true(result$valid)
  expect_equal(result$value, "test")
})

test_that("validate_numeric_input catches non-numeric", {
  result <- validate_numeric_input("not a number", "Test")

  expect_false(result$valid)
  expect_true(grepl("must be a number", result$message))
})

test_that("validate_numeric_input enforces range", {
  result <- validate_numeric_input(15, "Test", min = 0, max = 10)

  expect_false(result$valid)
  expect_true(grepl("at most 10", result$message))
})
```

### Integration Tests with Modules

```r
test_that("Form validation prevents saving invalid data", {
  # Create test app
  testServer(driver_entry_server, {

    # Set invalid name (too short)
    session$setInputs(name = "a")

    # Try to save
    session$setInputs(save_driver = 1)

    # Should not save (no data added)
    expect_equal(nrow(project_data()$data$isa_data$drivers), 0)
  })
})

test_that("Form validation allows saving valid data", {
  testServer(driver_entry_server, {

    # Set valid inputs
    session$setInputs(
      name = "Test Driver",
      indicator = "Population",
      needs_category = "Economic",
      baseline_value = 100
    )

    # Save
    session$setInputs(save_driver = 1)

    # Should save
    expect_equal(nrow(project_data()$data$isa_data$drivers), 1)
  })
})
```

---

## Best Practices

### Checklist for Input Validation

**For Every Input:**
- [ ] Validate in observeEvent before processing
- [ ] Use appropriate validator function
- [ ] Pass session for automatic notifications
- [ ] Return early if validation fails
- [ ] Use cleaned value from validation result
- [ ] Log validation failures

**For Forms:**
- [ ] Create reactive validation for real-time feedback
- [ ] Enable/disable save button based on validation
- [ ] Validate again on save (belt and suspenders)
- [ ] Show combined error messages for multiple fields
- [ ] Reset form after successful save

**For File Uploads:**
- [ ] Validate file type (extension)
- [ ] Validate file size
- [ ] Check file exists at path
- [ ] Validate file contents after reading
- [ ] Show progress during import
- [ ] Handle import errors gracefully

**For Domain Data:**
- [ ] Use domain-specific validators when available
- [ ] Add custom validators for business logic
- [ ] Validate relationships (e.g., connections)
- [ ] Check for duplicates
- [ ] Validate against existing data

### Common Mistakes to Avoid

**❌ Don't:**
```r
# No validation - BAD
observeEvent(input$save, {
  save_data(input$name)  # Could be NULL, empty, too long, etc.
})

# Silent validation - BAD
observeEvent(input$save, {
  if (is.null(input$name)) {
    return()  # User has no idea why it didn't save
  }
})

# Vague error messages - BAD
if (!valid) {
  showNotification("Invalid input")  // Which input? What's wrong?
}
```

**✅ Do:**
```r
# Proper validation - GOOD
observeEvent(input$save, {
  validation <- validate_text_input(
    input$name,
    "Project name",
    required = TRUE,
    min_length = 3,
    max_length = 100,
    session = session  # Shows specific error
  )

  if (!validation$valid) {
    return()  # Clear notification shown
  }

  save_data(validation$value)  // Use cleaned value
})
```

### Performance Considerations

**Reactive Validation:**
- Use debounced reactives for expensive validation
- Don't validate on every keystroke for long text
- Cache validation results when possible

**Example:**
```r
# Debounce validation (wait for user to stop typing)
name_valid <- reactive({
  input$name  # Trigger on change
}) %>% debounce(500)  # Wait 500ms after last change

observe({
  result <- validate_text_input(name_valid(), "Name", ...)
  # Update UI based on result
})
```

---

## Summary

### Key Takeaways

1. **Always validate user inputs** - Never trust user data
2. **Use validation helpers** - Consistent, tested, user-friendly
3. **Validate early** - Fail fast with clear messages
4. **Show specific errors** - Help users fix problems
5. **Enable/disable buttons** - Prevent invalid submissions
6. **Log validation failures** - Aid debugging

### Quick Reference

**Basic Pattern:**
```r
observeEvent(input$save, {
  # 1. Validate
  validation <- validate_text_input(input$field, "Field name",
                                   required = TRUE, session = session)

  // 2. Check
  if (!validation$valid) return()

  // 3. Use cleaned value
  save_data(validation$value)
})
```

**Multi-Field Pattern:**
```r
observeEvent(input$save, {
  // 1. Validate all
  validations <- list(
    validate_text_input(input$field1, "Field 1", ...),
    validate_numeric_input(input$field2, "Field 2", ...)
  )

  // 2. Check all
  if (!validate_all(validations, session)) return()

  // 3. Save
  save_data(validations[[1]]$value, validations[[2]]$value)
})
```

---

**Document Version:** 1.0
**Last Updated:** 2025-10-25
**Related:** ERROR_HANDLING_GUIDE.md, TESTING_GUIDE.md
**Helper File:** functions/module_validation_helpers.R

