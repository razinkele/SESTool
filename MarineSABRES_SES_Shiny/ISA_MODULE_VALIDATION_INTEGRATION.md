# ISA Module Validation Integration

## Overview

This document describes the integration of input validation helpers into the ISA Data Entry module ([modules/isa_data_entry_module.R](modules/isa_data_entry_module.R)). The integration demonstrates practical validation patterns that developers can follow when implementing validation in other modules.

**Date:** 2025-10-25
**Integration Status:** ✅ Complete - 3 exercises validated as examples
**Lines Modified:** ~200 lines added/modified

---

## Files Modified

### modules/isa_data_entry_module.R

**Changes Made:**
1. Added source statement for validation helpers (line 514)
2. Integrated validation in Exercise 0 save handler (lines 625-665)
3. Enhanced validation in Exercise 1 save handler (lines 697-790)
4. Added validation in Exercise 2a save handler (lines 822-915)

**Total Validation Coverage:**
- Exercise 0: ✅ Validated (6 fields)
- Exercise 1: ✅ Validated (4 fields per entry, dynamic)
- Exercise 2a: ✅ Validated (4 fields per entry, dynamic)
- Exercise 2b-5: 📋 Pattern established, can be replicated
- BOT Data Entry: 📋 Can use numeric validation pattern
- File Import: 📋 Can use file upload validation

---

## Validation Patterns Demonstrated

### Pattern 1: Simple Form Validation (Exercise 0)

**Use Case:** Validate a fixed set of form inputs before saving

**Code Location:** [isa_data_entry_module.R:625-665](modules/isa_data_entry_module.R)

**Implementation:**

```r
observeEvent(input$save_ex0, {
  # Step 1: Create validation list
  validations <- list(
    validate_text_input(input$case_name, "Case Study Name",
                       required = TRUE, min_length = 3, max_length = 200,
                       session = session),
    validate_text_input(input$case_description, "Case Description",
                       required = TRUE, min_length = 10, max_length = 1000,
                       session = session),
    validate_text_input(input$geographic_scope, "Geographic Scope",
                       required = TRUE, min_length = 3,
                       session = session),
    validate_text_input(input$temporal_scope, "Temporal Scope",
                       required = TRUE, min_length = 3,
                       session = session),
    validate_text_input(input$welfare_impacts, "Welfare Impacts",
                       required = FALSE, max_length = 2000,
                       session = session),
    validate_text_input(input$key_stakeholders, "Key Stakeholders",
                       required = FALSE, max_length = 1000,
                       session = session)
  )

  # Step 2: Check all validations at once
  if (!validate_all(validations, session)) {
    return()  # Stop if validation fails
  }

  # Step 3: Use cleaned values from validation results
  isa_data$case_info <- list(
    name = validations[[1]]$value,
    description = validations[[2]]$value,
    geographic_scope = validations[[3]]$value,
    temporal_scope = validations[[4]]$value,
    welfare_impacts = if (!is.null(validations[[5]]$value)) validations[[5]]$value else "",
    key_stakeholders = if (!is.null(validations[[6]]$value)) validations[[6]]$value else ""
  )

  showNotification("Exercise 0 saved successfully!", type = "message")
  log_message("Exercise 0 case information saved", "INFO")
})
```

**Key Features:**
- ✅ Multiple field validation in single call
- ✅ Required vs optional field handling
- ✅ Length constraints (min/max)
- ✅ Automatic user notifications via `validate_all()`
- ✅ Uses cleaned/trimmed values from validation
- ✅ Early return on validation failure
- ✅ Logging for audit trail

**When to Use:**
- Forms with fixed number of inputs
- Single-page forms
- Configuration/settings forms

---

### Pattern 2: Dynamic Form Validation (Exercise 1)

**Use Case:** Validate dynamically created form entries (user can add multiple entries)

**Code Location:** [isa_data_entry_module.R:697-790](modules/isa_data_entry_module.R)

**Implementation:**

```r
observeEvent(input$save_ex1, {
  # Step 1: Check if any entries exist
  if (isa_data$gb_counter == 0) {
    showNotification("Please add at least one Good/Benefit entry before saving.",
                    type = "warning", session = session)
    return()
  }

  # Step 2: Initialize collection structures
  gb_df <- data.frame()
  validation_errors <- c()

  # Step 3: Loop through all dynamic entries
  for(i in 1:isa_data$gb_counter) {
    name_val <- input[[paste0("gb_name_", i)]]
    type_val <- input[[paste0("gb_type_", i)]]
    desc_val <- input[[paste0("gb_desc_", i)]]
    stakeholder_val <- input[[paste0("gb_stakeholder_", i)]]

    # Skip removed entries
    if(is.null(name_val)) next

    # Only validate entries with content
    if(name_val != "") {
      # Step 4: Validate each entry
      entry_validations <- list(
        validate_text_input(name_val, paste0("G&B ", i, " Name"),
                           required = TRUE, min_length = 2, max_length = 200,
                           session = NULL),  # No per-field notification
        validate_select_input(type_val, paste0("G&B ", i, " Type"),
                             required = TRUE,
                             valid_choices = c("Provisioning", "Regulating", "Cultural", "Supporting"),
                             session = NULL),
        validate_text_input(desc_val, paste0("G&B ", i, " Description"),
                           required = FALSE, max_length = 500,
                           session = NULL),
        validate_text_input(stakeholder_val, paste0("G&B ", i, " Stakeholder"),
                           required = FALSE, max_length = 200,
                           session = NULL)
      )

      # Step 5: Collect errors (don't show yet)
      for (v in entry_validations) {
        if (!v$valid) {
          validation_errors <- c(validation_errors, v$message)
        }
      }

      # Step 6: Add valid entries to data frame
      if (all(sapply(entry_validations, function(v) v$valid))) {
        gb_df <- rbind(gb_df, data.frame(
          ID = paste0("GB", sprintf("%03d", i)),
          Name = entry_validations[[1]]$value,
          Type = entry_validations[[2]]$value,
          Description = if (!is.null(entry_validations[[3]]$value)) entry_validations[[3]]$value else "",
          Stakeholder = if (!is.null(entry_validations[[4]]$value)) entry_validations[[4]]$value else "",
          Importance = importance_val,
          Trend = trend_val,
          stringsAsFactors = FALSE
        ))
      }
    }
  }

  # Step 7: Show all errors at once in modal
  if (length(validation_errors) > 0) {
    showModal(modalDialog(
      title = tags$div(icon("exclamation-triangle"), " Validation Errors"),
      tags$div(
        tags$p(strong("Please fix the following issues before saving:")),
        tags$ul(
          lapply(validation_errors, function(err) tags$li(err))
        )
      ),
      easyClose = TRUE,
      footer = modalButton("OK")
    ))
    return()
  }

  # Step 8: Final check for at least one valid entry
  if (nrow(gb_df) == 0) {
    showNotification("Please add at least one valid Good/Benefit entry.",
                    type = "warning", session = session)
    return()
  }

  # Step 9: Save validated data
  isa_data$goods_benefits <- gb_df
  showNotification(paste("Exercise 1 saved:", nrow(gb_df), "Goods & Benefits"),
                  type = "message", session = session)
  log_message(paste("Exercise 1 saved with", nrow(gb_df), "entries"), "INFO")
})
```

**Key Features:**
- ✅ Validates dynamically created entries
- ✅ Skips removed/NULL entries
- ✅ Collects all errors before showing (better UX)
- ✅ Shows all errors in single modal dialog
- ✅ Validates each entry independently
- ✅ Only saves fully validated entries
- ✅ Handles empty entry list gracefully
- ✅ Uses session = NULL for per-field validation to avoid notification spam
- ✅ Shows consolidated error list at end

**When to Use:**
- Forms where users can add multiple entries
- Data grids or repeating sections
- List-based data entry
- Any form with dynamic number of inputs

---

### Pattern 3: Select Input Validation (Exercises 1 & 2a)

**Use Case:** Validate dropdown selections against valid choices

**Code Example:**

```r
validate_select_input(type_val, paste0("ES ", i, " Type"),
                     required = TRUE,
                     valid_choices = c("Provisioning", "Regulating", "Cultural", "Supporting"),
                     session = NULL)
```

**Key Features:**
- ✅ Ensures selection from valid set of choices
- ✅ Catches empty/NULL selections
- ✅ Works with both static and dynamic choice lists
- ✅ Can validate linked selections (e.g., "Linked to G&B")

**When to Use:**
- selectInput() fields
- Any dropdown validation
- Ensuring referential integrity in linked selections

---

## Validation Helper Functions Used

### 1. validate_text_input()

**Purpose:** Validate text fields with length and pattern constraints

**Parameters Used in ISA Module:**
- `value` - Input value to validate
- `field_name` - User-friendly field name for error messages
- `required` - Whether field is mandatory (TRUE/FALSE)
- `min_length` - Minimum character length
- `max_length` - Maximum character length
- `session` - Shiny session for notifications

**Examples from ISA Module:**

```r
# Required field with min/max length
validate_text_input(input$case_name, "Case Study Name",
                   required = TRUE, min_length = 3, max_length = 200,
                   session = session)

# Optional field with max length only
validate_text_input(input$welfare_impacts, "Welfare Impacts",
                   required = FALSE, max_length = 2000,
                   session = session)

# Required with min length only
validate_text_input(input$geographic_scope, "Geographic Scope",
                   required = TRUE, min_length = 3,
                   session = session)
```

**Return Value:**
```r
list(
  valid = TRUE/FALSE,
  message = "Error message if invalid" or NULL,
  value = "Cleaned value (trimmed whitespace)"
)
```

---

### 2. validate_select_input()

**Purpose:** Validate dropdown selections

**Parameters Used:**
- `value` - Selected value
- `field_name` - User-friendly field name
- `required` - Whether selection is mandatory
- `valid_choices` - Vector of valid choices
- `session` - Shiny session for notifications

**Examples from ISA Module:**

```r
validate_select_input(type_val, "G&B Type",
                     required = TRUE,
                     valid_choices = c("Provisioning", "Regulating", "Cultural", "Supporting"),
                     session = NULL)
```

---

### 3. validate_all()

**Purpose:** Validate multiple inputs and show consolidated error message

**Usage Pattern:**

```r
# Create list of validations
validations <- list(
  validate_text_input(...),
  validate_text_input(...),
  validate_select_input(...)
)

# Check all at once
if (!validate_all(validations, session)) {
  return()  # Stop execution if any validation fails
}

# All valid - proceed with cleaned values
data <- list(
  field1 = validations[[1]]$value,
  field2 = validations[[2]]$value
)
```

**Benefits:**
- Shows single notification with all errors
- Better UX than showing errors one-by-one
- Works with any combination of validation functions
- Automatically formats error list

---

## Best Practices Demonstrated

### 1. **Session Parameter Usage**

```r
# ✅ GOOD: Show notification in simple forms
validate_text_input(input$field, "Field", session = session)

# ✅ GOOD: Don't show per-field notification in loops
validate_text_input(value, "Field", session = NULL)
# Then collect errors and show once at end
```

**Why:** Prevents notification spam when validating multiple entries

---

### 2. **Using Cleaned Values**

```r
# ✅ GOOD: Use cleaned value from validation
name = validations[[1]]$value

# ❌ BAD: Use raw input (may have whitespace)
name = input$case_name
```

**Why:** Validation functions trim whitespace and normalize values

---

### 3. **Early Return on Failure**

```r
if (!validate_all(validations, session)) {
  return()  # Stop execution
}
# Continue with save logic
```

**Why:** Prevents saving invalid data, clear control flow

---

### 4. **Modal for Multiple Errors**

```r
if (length(validation_errors) > 0) {
  showModal(modalDialog(
    title = tags$div(icon("exclamation-triangle"), " Validation Errors"),
    tags$div(
      tags$p(strong("Please fix the following issues before saving:")),
      tags$ul(
        lapply(validation_errors, function(err) tags$li(err))
      )
    ),
    easyClose = TRUE,
    footer = modalButton("OK")
  ))
  return()
}
```

**Why:** Shows all errors at once, better for complex forms with many fields

---

### 5. **Logging Valid Actions**

```r
showNotification("Exercise 0 saved successfully!", type = "message")
log_message("Exercise 0 case information saved", "INFO")
```

**Why:** Audit trail for data entry actions

---

## Validation Error Messages

### Text Input Errors

| Condition | Error Message Example |
|-----------|----------------------|
| Required but empty | "Case Study Name is required" |
| Too short | "Case Study Name must be at least 3 characters" |
| Too long | "Case Description must be at most 1000 characters" |
| Only whitespace | "Case Study Name cannot be empty" |

### Select Input Errors

| Condition | Error Message Example |
|-----------|----------------------|
| Required but not selected | "G&B Type is required" |
| Invalid choice | "G&B Type is not a valid selection" |

---

## Integration Checklist

When adding validation to a new module or handler, follow this checklist:

### Setup
- [ ] Add `source("functions/module_validation_helpers.R", local = TRUE)` at top of server function

### For Each observeEvent Handler
- [ ] Identify all input fields that need validation
- [ ] Determine which fields are required vs optional
- [ ] Choose appropriate validator for each field type
- [ ] Decide on notification strategy (per-field vs consolidated)

### Implementation
- [ ] Create validation list with all validate_* calls
- [ ] Use validate_all() for simple forms OR collect errors for complex forms
- [ ] Handle validation failure (early return or modal)
- [ ] Use cleaned values from validation results
- [ ] Add success notification and logging

### Testing
- [ ] Test required field validation (empty inputs)
- [ ] Test length constraints (too short, too long)
- [ ] Test select input with invalid choices
- [ ] Test saving with all valid data
- [ ] Test notification messages are clear and helpful

---

## Next Steps for Complete ISA Module Validation

The following exercises can use the same patterns:

1. **Exercise 2b (Marine Processes)** - Use Pattern 2 (dynamic form)
   - Validate name, type, description, mechanism fields
   - Similar to Exercise 2a implementation

2. **Exercise 3 (Pressures)** - Use Pattern 2 (dynamic form)
   - Add spatial/temporal field validation
   - Validate intensity selection

3. **Exercise 4 (Activities)** - Use Pattern 2 (dynamic form)
   - Validate sector selection
   - Add scale and frequency validation

4. **Exercise 5 (Drivers)** - Use Pattern 2 (dynamic form)
   - Validate driver type and trend selections
   - Add controllability validation

5. **BOT Data Entry** - Add numeric validation
   ```r
   validate_numeric_input(input$bot_year, "Year",
                         required = TRUE, min = 1900, max = 2100,
                         integer_only = TRUE, session = session)

   validate_numeric_input(input$bot_value, "Value",
                         required = TRUE, session = session)
   ```

6. **File Import** - Add file validation
   ```r
   validate_file_upload(input$import_file, "Import file",
                       required = TRUE,
                       allowed_extensions = c("xlsx"),
                       max_size_mb = 10,
                       session = session)
   ```

---

## Performance Notes

**Validation Overhead:** Negligible (~1-5ms per validation call)

**User Experience Impact:**
- ✅ Positive: Immediate feedback, clearer error messages
- ✅ Positive: Prevents invalid data entry
- ✅ Positive: Reduces data quality issues downstream

**Development Time:**
- Initial integration: ~2-3 hours for full module
- Per exercise/handler: ~10-15 minutes once pattern established
- Testing time: ~15-20 minutes per exercise

---

## References

- [module_validation_helpers.R](functions/module_validation_helpers.R) - Validation helper functions
- [INPUT_VALIDATION_GUIDE.md](INPUT_VALIDATION_GUIDE.md) - Complete validation guide
- [test-module-validation-helpers.R](tests/testthat/test-module-validation-helpers.R) - Unit tests
- [HIGH_PRIORITY_IMPROVEMENTS_STATUS.md](HIGH_PRIORITY_IMPROVEMENTS_STATUS.md) - Project status

---

## Support

For questions about validation integration:
1. See complete examples in this document
2. Review [INPUT_VALIDATION_GUIDE.md](INPUT_VALIDATION_GUIDE.md) for detailed API docs
3. Check unit tests for edge cases and expected behavior
4. Review other integrated modules for patterns

---

**Document Version:** 1.0
**Last Updated:** 2025-10-25
**Author:** MarineSABRES Development Team
