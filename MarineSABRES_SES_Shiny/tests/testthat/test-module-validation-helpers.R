# test-module-validation-helpers.R (validation helper tests)
# Tests for module validation helper functions

library(testthat)

# Source validation helpers
source("../../functions/module_validation_helpers.R", local = TRUE)

# ============================================================================
# TEXT INPUT VALIDATION TESTS
# ============================================================================

test_that("validate_text_input catches NULL input when required", {
  result <- validate_text_input(NULL, "Test field", required = TRUE)

  expect_false(result$valid)
  expect_true(grepl("required", result$message, ignore.case = TRUE))
})

test_that("validate_text_input accepts NULL when not required", {
  result <- validate_text_input(NULL, "Test field", required = FALSE)

  expect_true(result$valid)
  expect_null(result$message)
})

test_that("validate_text_input catches empty string when required", {
  result <- validate_text_input("", "Test field", required = TRUE)

  expect_false(result$valid)
  expect_true(grepl("empty|required", result$message, ignore.case = TRUE))
})

test_that("validate_text_input catches whitespace-only string when required", {
  result <- validate_text_input("   ", "Test field", required = TRUE)

  expect_false(result$valid)
  expect_true(grepl("empty", result$message, ignore.case = TRUE))
})

test_that("validate_text_input trims whitespace", {
  result <- validate_text_input("  test value  ", "Test field", required = TRUE)

  expect_true(result$valid)
  expect_equal(result$value, "test value")
})

test_that("validate_text_input enforces minimum length", {
  result <- validate_text_input("ab", "Test field", min_length = 3)

  expect_false(result$valid)
  expect_true(grepl("at least 3", result$message))
})

test_that("validate_text_input enforces maximum length", {
  long_text <- paste(rep("a", 101), collapse = "")
  result <- validate_text_input(long_text, "Test field", max_length = 100)

  expect_false(result$valid)
  expect_true(grepl("at most 100", result$message))
})

test_that("validate_text_input validates pattern", {
  # Test email pattern
  email_pattern <- "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$"

  result_invalid <- validate_text_input("not-an-email", "Email", pattern = email_pattern)
  expect_false(result_invalid$valid)

  result_valid <- validate_text_input("test@example.com", "Email", pattern = email_pattern)
  expect_true(result_valid$valid)
})

test_that("validate_text_input accepts valid text", {
  result <- validate_text_input("Valid text", "Test field",
                                required = TRUE, min_length = 5, max_length = 100)

  expect_true(result$valid)
  expect_null(result$message)
  expect_equal(result$value, "Valid text")
})

# ============================================================================
# NUMERIC INPUT VALIDATION TESTS
# ============================================================================

test_that("validate_numeric_input catches NULL when required", {
  result <- validate_numeric_input(NULL, "Test number", required = TRUE)

  expect_false(result$valid)
  expect_true(grepl("required", result$message, ignore.case = TRUE))
})

test_that("validate_numeric_input accepts NULL when not required", {
  result <- validate_numeric_input(NULL, "Test number", required = FALSE)

  expect_true(result$valid)
  expect_null(result$message)
})

test_that("validate_numeric_input catches NA when required", {
  result <- validate_numeric_input(NA, "Test number", required = TRUE)

  expect_false(result$valid)
})

test_that("validate_numeric_input catches non-numeric input", {
  result <- validate_numeric_input("not a number", "Test number", required = TRUE)

  expect_false(result$valid)
  expect_true(grepl("number", result$message, ignore.case = TRUE))
})

test_that("validate_numeric_input enforces minimum value", {
  result <- validate_numeric_input(5, "Test number", min = 10)

  expect_false(result$valid)
  expect_true(grepl("at least 10", result$message))
})

test_that("validate_numeric_input enforces maximum value", {
  result <- validate_numeric_input(15, "Test number", max = 10)

  expect_false(result$valid)
  expect_true(grepl("at most 10", result$message))
})

test_that("validate_numeric_input enforces integer_only", {
  result <- validate_numeric_input(5.5, "Test number", integer_only = TRUE)

  expect_false(result$valid)
  expect_true(grepl("whole number|integer", result$message, ignore.case = TRUE))
})

test_that("validate_numeric_input enforces positive_only", {
  result <- validate_numeric_input(-5, "Test number", positive_only = TRUE)

  expect_false(result$valid)
  expect_true(grepl("positive", result$message, ignore.case = TRUE))
})

test_that("validate_numeric_input accepts valid number in range", {
  result <- validate_numeric_input(5, "Test number", min = 0, max = 10)

  expect_true(result$valid)
  expect_null(result$message)
  expect_equal(result$value, 5)
})

test_that("validate_numeric_input accepts valid integer", {
  result <- validate_numeric_input(5, "Test number", integer_only = TRUE, positive_only = TRUE)

  expect_true(result$valid)
  expect_equal(result$value, 5)
})

# ============================================================================
# SELECT INPUT VALIDATION TESTS
# ============================================================================

test_that("validate_select_input catches NULL when required", {
  result <- validate_select_input(NULL, "Test selection", required = TRUE)

  expect_false(result$valid)
  expect_true(grepl("select|required", result$message, ignore.case = TRUE))
})

test_that("validate_select_input catches empty string when required", {
  result <- validate_select_input("", "Test selection", required = TRUE)

  expect_false(result$valid)
})

test_that("validate_select_input accepts NULL when not required", {
  result <- validate_select_input(NULL, "Test selection", required = FALSE)

  expect_true(result$valid)
})

test_that("validate_select_input validates against valid_choices", {
  valid_choices <- c("option1", "option2", "option3")

  result_invalid <- validate_select_input("invalid_option", "Test selection",
                                         valid_choices = valid_choices)
  expect_false(result_invalid$valid)
  expect_true(grepl("invalid", result_invalid$message, ignore.case = TRUE))

  result_valid <- validate_select_input("option2", "Test selection",
                                       valid_choices = valid_choices)
  expect_true(result_valid$valid)
})

test_that("validate_select_input accepts valid selection", {
  result <- validate_select_input("option1", "Test selection", required = TRUE)

  expect_true(result$valid)
  expect_equal(result$value, "option1")
})

# ============================================================================
# DATE INPUT VALIDATION TESTS
# ============================================================================

test_that("validate_date_input catches NULL when required", {
  result <- validate_date_input(NULL, "Test date", required = TRUE)

  expect_false(result$valid)
  expect_true(grepl("required", result$message, ignore.case = TRUE))
})

test_that("validate_date_input accepts NULL when not required", {
  result <- validate_date_input(NULL, "Test date", required = FALSE)

  expect_true(result$valid)
})

test_that("validate_date_input validates date format", {
  result_invalid <- validate_date_input("not-a-date", "Test date", required = TRUE)

  expect_false(result_invalid$valid)
  expect_true(grepl("valid date", result_invalid$message, ignore.case = TRUE))
})

test_that("validate_date_input enforces minimum date", {
  min_date <- as.Date("2020-01-01")
  test_date <- as.Date("2019-12-31")

  result <- validate_date_input(test_date, "Test date", min_date = min_date)

  expect_false(result$valid)
  expect_true(grepl("before", result$message, ignore.case = TRUE))
})

test_that("validate_date_input enforces maximum date", {
  max_date <- as.Date("2025-12-31")
  test_date <- as.Date("2026-01-01")

  result <- validate_date_input(test_date, "Test date", max_date = max_date)

  expect_false(result$valid)
  expect_true(grepl("after", result$message, ignore.case = TRUE))
})

test_that("validate_date_input converts valid date string", {
  result <- validate_date_input("2023-05-15", "Test date", required = TRUE)

  expect_true(result$valid)
  expect_equal(result$value, as.Date("2023-05-15"))
})

test_that("validate_date_input accepts valid Date object", {
  test_date <- as.Date("2023-05-15")
  result <- validate_date_input(test_date, "Test date", required = TRUE)

  expect_true(result$valid)
  expect_equal(result$value, test_date)
})

# ============================================================================
# FILE UPLOAD VALIDATION TESTS
# ============================================================================

test_that("validate_file_upload catches NULL when required", {
  result <- validate_file_upload(NULL, "Test file", required = TRUE)

  expect_false(result$valid)
  expect_true(grepl("upload|required", result$message, ignore.case = TRUE))
})

test_that("validate_file_upload accepts NULL when not required", {
  result <- validate_file_upload(NULL, "Test file", required = FALSE)

  expect_true(result$valid)
})

test_that("validate_file_upload validates file extension", {
  # Create mock file input
  mock_file <- data.frame(
    name = "test.pdf",
    size = 1000,
    type = "application/pdf",
    datapath = tempfile(),
    stringsAsFactors = FALSE
  )

  # Create the file so it exists
  file.create(mock_file$datapath)

  result <- validate_file_upload(mock_file, "Test file",
                                 allowed_extensions = c("xlsx", "csv"))

  expect_false(result$valid)
  expect_true(grepl("xlsx|csv", result$message, ignore.case = TRUE))

  # Cleanup
  unlink(mock_file$datapath)
})

test_that("validate_file_upload validates file size", {
  # Create mock file that's too large (20MB)
  mock_file <- data.frame(
    name = "test.xlsx",
    size = 20 * 1024 * 1024,
    type = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
    datapath = tempfile(),
    stringsAsFactors = FALSE
  )

  file.create(mock_file$datapath)

  result <- validate_file_upload(mock_file, "Test file", max_size_mb = 10)

  expect_false(result$valid)
  expect_true(grepl("large|size", result$message, ignore.case = TRUE))

  # Cleanup
  unlink(mock_file$datapath)
})

test_that("validate_file_upload accepts valid file", {
  # Create mock valid file
  mock_file <- data.frame(
    name = "test.xlsx",
    size = 1024 * 1024,  # 1MB
    type = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
    datapath = tempfile(),
    stringsAsFactors = FALSE
  )

  file.create(mock_file$datapath)

  result <- validate_file_upload(mock_file, "Test file",
                                 allowed_extensions = c("xlsx", "xls"),
                                 max_size_mb = 10)

  expect_true(result$valid)
  expect_null(result$message)
  expect_equal(result$name, "test.xlsx")
  expect_equal(result$path, mock_file$datapath)

  # Cleanup
  unlink(mock_file$datapath)
})

# ============================================================================
# MULTI-INPUT VALIDATION TESTS
# ============================================================================

test_that("validate_all returns TRUE when all validations pass", {
  validations <- list(
    list(valid = TRUE, message = NULL),
    list(valid = TRUE, message = NULL),
    list(valid = TRUE, message = NULL)
  )

  result <- validate_all(validations)
  expect_true(result)
})

test_that("validate_all returns FALSE when any validation fails", {
  validations <- list(
    list(valid = TRUE, message = NULL),
    list(valid = FALSE, message = "Error 1"),
    list(valid = TRUE, message = NULL)
  )

  result <- validate_all(validations)
  expect_false(result)
})

test_that("validate_all returns FALSE when all validations fail", {
  validations <- list(
    list(valid = FALSE, message = "Error 1"),
    list(valid = FALSE, message = "Error 2"),
    list(valid = FALSE, message = "Error 3")
  )

  result <- validate_all(validations)
  expect_false(result)
})

test_that("validate_all handles empty list", {
  result <- validate_all(list())
  expect_true(result)  # No validations means all valid
})

# ============================================================================
# DOMAIN-SPECIFIC VALIDATION TESTS
# ============================================================================

test_that("validate_stakeholder_values accepts valid power/interest", {
  result <- validate_stakeholder_values(power = 5, interest = 7)

  expect_true(result$valid)
  expect_null(result$message)
})

test_that("validate_stakeholder_values rejects power out of range", {
  result <- validate_stakeholder_values(power = 15, interest = 5)

  expect_false(result$valid)
})

test_that("validate_stakeholder_values rejects interest out of range", {
  result <- validate_stakeholder_values(power = 5, interest = 12)

  expect_false(result$valid)
})

test_that("validate_stakeholder_values rejects negative values", {
  result <- validate_stakeholder_values(power = -1, interest = 5)

  expect_false(result$valid)
})

test_that("validate_element_entry accepts valid element", {
  result <- validate_element_entry(name = "Test Element", indicator = "Test Indicator")

  expect_true(result$valid)
})

test_that("validate_element_entry rejects empty name", {
  result <- validate_element_entry(name = "", indicator = "Test Indicator")

  expect_false(result$valid)
})

test_that("validate_element_entry accepts NULL indicator when optional", {
  result <- validate_element_entry(name = "Test Element", indicator = NULL)

  expect_true(result$valid)
})

test_that("validate_email accepts valid email", {
  result <- validate_email("test@example.com", required = TRUE)

  expect_true(result$valid)
  expect_equal(result$value, "test@example.com")
})

test_that("validate_email rejects invalid email format", {
  result <- validate_email("not-an-email", required = TRUE)

  expect_false(result$valid)
  expect_true(grepl("invalid|format", result$message, ignore.case = TRUE))
})

test_that("validate_email accepts NULL when not required", {
  result <- validate_email(NULL, required = FALSE)

  expect_true(result$valid)
})

test_that("validate_email rejects NULL when required", {
  result <- validate_email(NULL, required = TRUE)

  expect_false(result$valid)
})

# ============================================================================
# EDGE CASES AND ERROR HANDLING
# ============================================================================

test_that("validation functions handle unusual input gracefully", {
  # Very long text
  very_long_text <- paste(rep("a", 10000), collapse = "")
  result <- validate_text_input(very_long_text, "Test", max_length = 100)
  expect_false(result$valid)

  # Extreme numeric values
  result <- validate_numeric_input(1e308, "Test", max = 1000)
  expect_false(result$valid)

  # Special characters in text
  result <- validate_text_input("Test<>&\"'", "Test", required = TRUE)
  expect_true(result$valid)  # Should accept special chars
})

test_that("validation functions are null-safe", {
  # All validators should handle NULL gracefully
  expect_no_error({
    validate_text_input(NULL, "Test", required = FALSE)
    validate_numeric_input(NULL, "Test", required = FALSE)
    validate_select_input(NULL, "Test", required = FALSE)
    validate_date_input(NULL, "Test", required = FALSE)
    validate_file_upload(NULL, "Test", required = FALSE)
  })
})

# ============================================================================
# INTEGRATION TESTS
# ============================================================================

test_that("Complete form validation workflow", {
  # Simulate form validation
  form_data <- list(
    name = "Test Project",
    description = "A test project",
    category = "Research",
    budget = 50000,
    start_date = as.Date("2024-01-01")
  )

  validations <- list(
    validate_text_input(form_data$name, "Name", required = TRUE, min_length = 3),
    validate_text_input(form_data$description, "Description", required = FALSE),
    validate_select_input(form_data$category, "Category", required = TRUE,
                         valid_choices = c("Research", "Development", "Operations")),
    validate_numeric_input(form_data$budget, "Budget", required = TRUE,
                          positive_only = TRUE),
    validate_date_input(form_data$start_date, "Start date", required = TRUE)
  )

  all_valid <- validate_all(validations)

  expect_true(all_valid)

  # Extract validated values
  validated_name <- validations[[1]]$value
  validated_budget <- validations[[4]]$value

  expect_equal(validated_name, "Test Project")
  expect_equal(validated_budget, 50000)
})

test_that("Form validation catches multiple errors", {
  form_data <- list(
    name = "",  # Invalid - empty
    category = "InvalidCategory",  # Invalid - not in choices
    budget = -1000,  # Invalid - negative
    start_date = "invalid-date"  # Invalid - bad format
  )

  validations <- list(
    validate_text_input(form_data$name, "Name", required = TRUE),
    validate_select_input(form_data$category, "Category", required = TRUE,
                         valid_choices = c("Research", "Development")),
    validate_numeric_input(form_data$budget, "Budget", positive_only = TRUE),
    validate_date_input(form_data$start_date, "Start date", required = TRUE)
  )

  all_valid <- validate_all(validations)

  expect_false(all_valid)

  # Check individual failures
  expect_false(validations[[1]]$valid)  # Name
  expect_false(validations[[2]]$valid)  # Category
  expect_false(validations[[3]]$valid)  # Budget
  expect_false(validations[[4]]$valid)  # Date
})
