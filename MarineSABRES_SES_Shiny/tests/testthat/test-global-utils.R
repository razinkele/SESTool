# test-global-utils.R
# Unit tests for utility functions defined in global.R

library(testthat)
library(shiny)

# Test %||% operator
test_that("%||% operator works correctly", {
  expect_equal(NULL %||% "default", "default")
  expect_equal("value" %||% "default", "value")
  expect_equal(5 %||% 10, 5)
  expect_equal(0 %||% 10, 0)
  expect_equal(FALSE %||% TRUE, FALSE)
})

# Test generate_id function
test_that("generate_id generates unique IDs", {
  id1 <- generate_id()
  id2 <- generate_id()

  expect_type(id1, "character")
  expect_type(id2, "character")
  expect_true(nchar(id1) > 0)
  expect_true(id1 != id2)

  # Test with custom prefix
  custom_id <- generate_id("TEST")
  expect_true(grepl("^TEST_", custom_id))
})

# Test format_date_display function
test_that("format_date_display formats dates correctly", {
  test_date <- as.Date("2025-01-15")
  formatted <- format_date_display(test_date)

  expect_type(formatted, "character")
  expect_true(grepl("15", formatted))
  expect_true(grepl("January", formatted))
  expect_true(grepl("2025", formatted))
})

# Test is_valid_email function
test_that("is_valid_email validates emails correctly", {
  expect_true(is_valid_email("test@example.com"))
  expect_true(is_valid_email("user.name+tag@example.co.uk"))
  expect_true(is_valid_email("test123@domain-name.com"))

  expect_false(is_valid_email("invalid"))
  expect_false(is_valid_email("@example.com"))
  expect_false(is_valid_email("test@"))
  expect_false(is_valid_email("test @example.com"))
})

# Test parse_connection_value function
test_that("parse_connection_value parses connection values correctly", {
  # Valid connections without confidence (defaults to 3)
  result1 <- parse_connection_value("+strong")
  expect_equal(result1$polarity, "+")
  expect_equal(result1$strength, "strong")
  expect_equal(result1$confidence, 3)

  result2 <- parse_connection_value("-weak")
  expect_equal(result2$polarity, "-")
  expect_equal(result2$strength, "weak")
  expect_equal(result2$confidence, 3)

  # Valid connections with confidence
  result3 <- parse_connection_value("+strong:5")
  expect_equal(result3$polarity, "+")
  expect_equal(result3$strength, "strong")
  expect_equal(result3$confidence, 5)

  result4 <- parse_connection_value("-medium:2")
  expect_equal(result4$polarity, "-")
  expect_equal(result4$strength, "medium")
  expect_equal(result4$confidence, 2)

  # Invalid confidence (should default to 3)
  result5 <- parse_connection_value("+weak:10")  # Out of range
  expect_equal(result5$confidence, 3)

  # Invalid/empty connections
  expect_null(parse_connection_value(NA))
  expect_null(parse_connection_value(""))
})

# Test sanitize_color function
test_that("sanitize_color validates and sanitizes colors", {
  # Valid hex colors
  expect_equal(sanitize_color("#776db3"), "#776db3")
  expect_equal(sanitize_color("#FFFFFF"), "#FFFFFF")
  expect_equal(sanitize_color("#abc123"), "#abc123")

  # Valid RGB colors
  expect_equal(sanitize_color("rgb(255,0,0)"), "rgb(255,0,0)")
  expect_equal(sanitize_color("rgb(100, 150, 200)"), "rgb(100, 150, 200)")

  # Invalid inputs should return default
  expect_equal(sanitize_color("invalid"), "#cccccc")
  expect_equal(sanitize_color(NULL), "#cccccc")
  expect_equal(sanitize_color(c("#fff", "#000")), "#cccccc")
  expect_equal(sanitize_color("#zzzzzz"), "#cccccc")
})

# Test sanitize_filename function
test_that("sanitize_filename sanitizes filenames correctly", {
  # Valid filenames
  expect_equal(sanitize_filename("project_name"), "project_name")
  expect_equal(sanitize_filename("My Project 123"), "My Project 123")
  expect_equal(sanitize_filename("test-file"), "test-file")

  # Remove dangerous characters
  expect_equal(sanitize_filename("file/path"), "filepath")
  expect_equal(sanitize_filename("file\\path"), "filepath")
  expect_equal(sanitize_filename("file:name"), "filename")
  expect_equal(sanitize_filename("file*name?"), "filename")
  expect_equal(sanitize_filename("file<name>"), "filename")

  # Handle edge cases
  expect_equal(sanitize_filename(""), "project")
  expect_equal(sanitize_filename(NULL), "project")
  expect_equal(sanitize_filename("   "), "project")

  # Truncate long filenames
  long_name <- paste0(rep("a", 100), collapse = "")
  sanitized <- sanitize_filename(long_name)
  expect_true(nchar(sanitized) <= 50)
})

# Test validate_project_structure function
test_that("validate_project_structure validates project data", {
  # Valid project structure
  valid_project <- list(
    project_id = "PROJ_001",
    project_name = "Test Project",
    created_at = Sys.time(),
    last_modified = Sys.time(),
    data = list(
      metadata = list(),
      pims = list(),
      isa_data = list()
    )
  )

  # Valid project should return empty error vector
  expect_length(validate_project_structure(valid_project), 0)

  # Also test with 'created' field (backward compatibility)
  valid_project_alt <- valid_project
  valid_project_alt$created <- valid_project_alt$created_at
  valid_project_alt$created_at <- NULL
  expect_length(validate_project_structure(valid_project_alt), 0)

  # Invalid structures should return errors
  expect_true(length(validate_project_structure(NULL)) > 0)
  expect_true(length(validate_project_structure(list())) > 0)
  expect_true(length(validate_project_structure("not a list")) > 0)

  # Missing required fields
  invalid_project1 <- valid_project
  invalid_project1$project_id <- NULL
  errors1 <- validate_project_structure(invalid_project1)
  expect_true(length(errors1) > 0)
  expect_true(any(grepl("project_id", errors1)))

  invalid_project2 <- valid_project
  invalid_project2$data <- NULL
  errors2 <- validate_project_structure(invalid_project2)
  expect_true(length(errors2) > 0)
  expect_true(any(grepl("data", errors2)))

  # Wrong data types
  invalid_project3 <- valid_project
  invalid_project3$project_id <- c("id1", "id2")
  errors3 <- validate_project_structure(invalid_project3)
  expect_true(length(errors3) > 0)
  expect_true(any(grepl("project_id", errors3)))
})

# Test safe_get_nested function
test_that("safe_get_nested accesses nested data safely", {
  test_data <- list(
    level1 = list(
      level2 = list(
        level3 = "value"
      ),
      another = "data"
    )
  )

  # Successful access
  expect_equal(safe_get_nested(test_data, "level1", "level2", "level3"), "value")
  expect_equal(safe_get_nested(test_data, "level1", "another"), "data")

  # Missing keys should return default
  expect_null(safe_get_nested(test_data, "nonexistent"))
  expect_null(safe_get_nested(test_data, "level1", "nonexistent"))
  expect_equal(safe_get_nested(test_data, "nonexistent", default = "default"), "default")

  # Null data should return default
  expect_null(safe_get_nested(NULL, "key"))
  expect_equal(safe_get_nested(NULL, "key", default = "default"), "default")
})

# Test init_session_data function
test_that("init_session_data initializes session data correctly", {
  session_data <- init_session_data()

  expect_type(session_data, "list")
  expect_true("project_id" %in% names(session_data))
  expect_true("created_at" %in% names(session_data))
  expect_true("data" %in% names(session_data))

  expect_type(session_data$project_id, "character")
  expect_true(grepl("^PROJ_", session_data$project_id))

  expect_s3_class(session_data$created_at, "POSIXct")
  expect_s3_class(session_data$last_modified, "POSIXct")

  expect_type(session_data$data, "list")
  expect_true("metadata" %in% names(session_data$data))
  expect_true("pims" %in% names(session_data$data))
  expect_true("isa_data" %in% names(session_data$data))
})

# Test validate_element_data function
test_that("validate_element_data validates DAPSI(W)R(M) element data", {
  # Valid data
  valid_data <- data.frame(
    id = c("D1", "D2"),
    name = c("Driver 1", "Driver 2"),
    indicator = c("Indicator 1", "Indicator 2"),
    stringsAsFactors = FALSE
  )

  errors <- validate_element_data(valid_data, "Drivers")
  expect_length(errors, 0)

  # Missing required columns
  invalid_data1 <- data.frame(
    id = c("D1", "D2"),
    name = c("Driver 1", "Driver 2")
  )
  errors1 <- validate_element_data(invalid_data1, "Drivers")
  expect_true(length(errors1) > 0)
  expect_true(any(grepl("Missing required columns", errors1)))

  # Duplicate IDs
  invalid_data2 <- data.frame(
    id = c("D1", "D1"),
    name = c("Driver 1", "Driver 2"),
    indicator = c("Indicator 1", "Indicator 2"),
    stringsAsFactors = FALSE
  )
  errors2 <- validate_element_data(invalid_data2, "Drivers")
  expect_true(length(errors2) > 0)
  expect_true(any(grepl("Duplicate IDs", errors2)))

  # Empty names
  invalid_data3 <- data.frame(
    id = c("D1", "D2"),
    name = c("Driver 1", ""),
    indicator = c("Indicator 1", "Indicator 2"),
    stringsAsFactors = FALSE
  )
  errors3 <- validate_element_data(invalid_data3, "Drivers")
  expect_true(length(errors3) > 0)
  expect_true(any(grepl("Empty names", errors3)))
})

# Test validate_isa_dataframe function
test_that("validate_isa_dataframe validates ISA data frames", {
  # Valid data
  valid_data <- data.frame(
    ID = c("1", "2", "3"),
    Name = c("Item 1", "Item 2", "Item 3"),
    Description = c("Desc 1", "Desc 2", "Desc 3"),
    stringsAsFactors = FALSE
  )

  errors <- validate_isa_dataframe(valid_data, "Test Exercise")
  expect_length(errors, 0)

  # Not a data frame
  errors1 <- validate_isa_dataframe(list(), "Test Exercise")
  expect_true(length(errors1) > 0)
  expect_true(any(grepl("must be a data frame", errors1)))

  # Empty data frame
  errors2 <- validate_isa_dataframe(data.frame(), "Test Exercise")
  expect_true(length(errors2) > 0)
  expect_true(any(grepl("must have at least one entry", errors2)))

  # Missing required columns
  invalid_data1 <- data.frame(
    ID = c("1", "2"),
    Description = c("Desc 1", "Desc 2")
  )
  errors3 <- validate_isa_dataframe(invalid_data1, "Test Exercise")
  expect_true(length(errors3) > 0)
  expect_true(any(grepl("missing required columns", errors3)))

  # Empty names
  invalid_data2 <- data.frame(
    ID = c("1", "2"),
    Name = c("Item 1", ""),
    stringsAsFactors = FALSE
  )
  errors4 <- validate_isa_dataframe(invalid_data2, "Test Exercise")
  expect_true(length(errors4) > 0)
  expect_true(any(grepl("empty names", errors4)))

  # Duplicate names
  invalid_data3 <- data.frame(
    ID = c("1", "2"),
    Name = c("Item 1", "Item 1"),
    stringsAsFactors = FALSE
  )
  errors5 <- validate_isa_dataframe(invalid_data3, "Test Exercise")
  expect_true(length(errors5) > 0)
  expect_true(any(grepl("duplicate names", errors5)))
})
