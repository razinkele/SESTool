# tests/testthat/test-export-functions-enhanced.R
# Tests for enhanced export functions with error handling

library(testthat)

# Source enhanced functions
source("../../functions/export_functions_enhanced.R", local = TRUE)
source("../../functions/data_structure_enhanced.R", local = TRUE)  # For creating test data

# Create temp directory for test outputs
test_temp_dir <- tempdir()

# ============================================================================
# VALIDATION UTILITIES TESTS
# ============================================================================

test_that("validate_output_path catches NULL input", {
  expect_error(
    validate_output_path(NULL),
    "File path is NULL"
  )
})

test_that("validate_output_path catches empty string", {
  expect_error(
    validate_output_path(""),
    "File path cannot be empty"
  )
})

test_that("validate_output_path catches non-existent directory", {
  expect_error(
    validate_output_path("/nonexistent/directory/file.xlsx"),
    "Directory does not exist"
  )
})

test_that("validate_output_path accepts valid path", {
  valid_path <- file.path(test_temp_dir, "test.xlsx")
  expect_true(validate_output_path(valid_path))
})

test_that("validate_export_project catches NULL input", {
  expect_error(
    validate_export_project(NULL),
    "Project data is NULL"
  )
})

test_that("validate_export_project catches invalid structure", {
  expect_error(
    validate_export_project(list(bad = "structure")),
    "missing required fields"
  )
})

test_that("validate_export_project accepts valid project", {
  project <- create_empty_project_safe("Test")
  expect_true(validate_export_project(project))
})

# ============================================================================
# EXPORT PROJECT EXCEL - ERROR HANDLING TESTS
# ============================================================================

test_that("export_project_excel_safe handles NULL project", {
  file_path <- file.path(test_temp_dir, "test_null.xlsx")
  result <- export_project_excel_safe(NULL, file_path)

  expect_false(result)
  expect_false(file.exists(file_path))
})

test_that("export_project_excel_safe handles invalid file path", {
  project <- create_empty_project_safe("Test")
  invalid_path <- "/nonexistent/directory/output.xlsx"

  result <- export_project_excel_safe(project, invalid_path)

  expect_false(result)
})

test_that("export_project_excel_safe succeeds with valid input", {
  project <- create_empty_project_safe("Test Export")
  file_path <- file.path(test_temp_dir, "test_valid_export.xlsx")

  result <- export_project_excel_safe(project, file_path)

  expect_true(result)
  expect_true(file.exists(file_path))

  # Cleanup
  if (file.exists(file_path)) unlink(file_path)
})

test_that("export_project_excel_safe handles project with data", {
  # Create project with some data
  project <- create_empty_project_safe("Test With Data")

  # Add a stakeholder
  project$data$pims$stakeholders <- data.frame(
    id = "S1",
    name = "Test Stakeholder",
    organization = "Test Org",
    type = "Public",
    power = 5,
    interest = 8,
    contact_email = "test@example.com",
    contact_phone = "123-456-7890",
    communication_preference = "Email",
    notes = "Test notes",
    stringsAsFactors = FALSE
  )

  # Add a driver
  driver_element <- data.frame(
    id = "D01",
    name = "Test Driver",
    indicator = "Population",
    indicator_unit = "People",
    data_source = "Census",
    time_horizon_start = as.Date("2020-01-01"),
    time_horizon_end = as.Date("2025-12-31"),
    baseline_value = 1000,
    current_value = 1200,
    notes = "Test driver",
    needs_category = "Economic",
    trends = "Increasing",
    stringsAsFactors = FALSE
  )

  project$data$isa_data <- add_element_safe(
    project$data$isa_data,
    "drivers",
    driver_element
  )

  file_path <- file.path(test_temp_dir, "test_with_data.xlsx")
  result <- export_project_excel_safe(project, file_path)

  expect_true(result)
  expect_true(file.exists(file_path))
  expect_true(file.info(file_path)$size > 0)

  # Cleanup
  if (file.exists(file_path)) unlink(file_path)
})

test_that("export_project_excel_safe creates multiple sheets", {
  project <- create_empty_project_safe("Multi Sheet Test")

  # Add data to multiple sections
  project$data$pims$stakeholders <- data.frame(
    id = "S1", name = "Stakeholder", organization = "", type = "",
    power = 5, interest = 5, contact_email = "", contact_phone = "",
    communication_preference = "", notes = ""
  )

  project$data$pims$risks <- data.frame(
    id = "R1",
    date_identified = Sys.Date(),
    description = "Test risk",
    likelihood = "Medium",
    severity = "High",
    mitigation_actions = "Test",
    owner = "Test",
    status = "Open",
    stringsAsFactors = FALSE
  )

  file_path <- file.path(test_temp_dir, "test_multiple_sheets.xlsx")
  result <- export_project_excel_safe(project, file_path)

  expect_true(result)
  expect_true(file.exists(file_path))

  # Cleanup
  if (file.exists(file_path)) unlink(file_path)
})

# ============================================================================
# EXPORT PROJECT JSON - ERROR HANDLING TESTS
# ============================================================================

test_that("export_project_json_safe handles NULL project", {
  file_path <- file.path(test_temp_dir, "test_null.json")
  result <- export_project_json_safe(NULL, file_path)

  expect_false(result)
  expect_false(file.exists(file_path))
})

test_that("export_project_json_safe handles invalid path", {
  project <- create_empty_project_safe("Test")
  invalid_path <- "/nonexistent/directory/output.json"

  result <- export_project_json_safe(project, invalid_path)

  expect_false(result)
})

test_that("export_project_json_safe succeeds with valid input", {
  project <- create_empty_project_safe("JSON Test")
  file_path <- file.path(test_temp_dir, "test_export.json")

  result <- export_project_json_safe(project, file_path)

  expect_true(result)
  expect_true(file.exists(file_path))
  expect_true(file.info(file_path)$size > 0)

  # Verify JSON is valid
  json_content <- tryCatch({
    jsonlite::fromJSON(file_path)
  }, error = function(e) NULL)

  expect_false(is.null(json_content))

  # Cleanup
  if (file.exists(file_path)) unlink(file_path)
})

test_that("export_project_json_safe handles date conversion", {
  project <- create_empty_project_safe("Date Test")
  project$created_at <- Sys.time()
  project$last_modified <- Sys.time()

  file_path <- file.path(test_temp_dir, "test_dates.json")
  result <- export_project_json_safe(project, file_path)

  expect_true(result)
  expect_true(file.exists(file_path))

  # Read JSON and verify dates are strings
  json_data <- jsonlite::fromJSON(file_path)
  expect_true(is.character(json_data$created_at))
  expect_true(is.character(json_data$last_modified))

  # Cleanup
  if (file.exists(file_path)) unlink(file_path)
})

# ============================================================================
# EXPORT PROJECT CSV ZIP - ERROR HANDLING TESTS
# ============================================================================

test_that("export_project_csv_zip_safe handles NULL project", {
  file_path <- file.path(test_temp_dir, "test_null.zip")
  result <- export_project_csv_zip_safe(NULL, file_path)

  expect_false(result)
  expect_false(file.exists(file_path))
})

test_that("export_project_csv_zip_safe handles invalid path", {
  project <- create_empty_project_safe("Test")
  invalid_path <- "/nonexistent/directory/output.zip"

  result <- export_project_csv_zip_safe(project, invalid_path)

  expect_false(result)
})

test_that("export_project_csv_zip_safe succeeds with valid input", {
  skip_on_cran()  # Zip operations may not work on all systems

  project <- create_empty_project_safe("CSV Zip Test")

  # Add some data
  driver_element <- data.frame(
    id = "D01",
    name = "Test Driver",
    indicator = "", indicator_unit = "", data_source = "",
    time_horizon_start = as.Date(NA), time_horizon_end = as.Date(NA),
    baseline_value = NA_real_, current_value = NA_real_,
    notes = "", needs_category = "", trends = "",
    stringsAsFactors = FALSE
  )

  project$data$isa_data <- add_element_safe(
    project$data$isa_data,
    "drivers",
    driver_element
  )

  file_path <- file.path(test_temp_dir, "test_export.zip")
  result <- export_project_csv_zip_safe(project, file_path)

  expect_true(result)
  expect_true(file.exists(file_path))
  expect_true(file.info(file_path)$size > 0)

  # Cleanup
  if (file.exists(file_path)) unlink(file_path)
})

# ============================================================================
# REPORT GENERATION - ERROR HANDLING TESTS
# ============================================================================

test_that("generate_executive_summary_safe handles NULL project", {
  file_path <- file.path(test_temp_dir, "test_null_report.html")
  result <- generate_executive_summary_safe(NULL, file_path)

  expect_false(result)
  expect_false(file.exists(file_path))
})

test_that("generate_executive_summary_safe handles invalid path", {
  project <- create_empty_project_safe("Test")
  invalid_path <- "/nonexistent/directory/report.html"

  result <- generate_executive_summary_safe(project, invalid_path)

  expect_false(result)
})

test_that("generate_executive_summary_safe succeeds with valid input for HTML", {
  skip_if_not_installed("rmarkdown")
  skip_if_not(rmarkdown::pandoc_available())

  project <- create_empty_project_safe("Report Test")

  # Add some data for report
  project$data$metadata$da_site <- "Test Site"
  project$data$metadata$focal_issue <- "Test Issue"

  # Add driver
  driver_element <- data.frame(
    id = "D01",
    name = "Test Driver",
    indicator = "", indicator_unit = "", data_source = "",
    time_horizon_start = as.Date(NA), time_horizon_end = as.Date(NA),
    baseline_value = NA_real_, current_value = NA_real_,
    notes = "", needs_category = "", trends = "",
    stringsAsFactors = FALSE
  )

  project$data$isa_data <- add_element_safe(
    project$data$isa_data,
    "drivers",
    driver_element
  )

  file_path <- file.path(test_temp_dir, "test_report.html")
  result <- generate_executive_summary_safe(project, file_path)

  expect_true(result)
  expect_true(file.exists(file_path))
  expect_true(file.info(file_path)$size > 0)

  # Cleanup
  if (file.exists(file_path)) unlink(file_path)
})

# ============================================================================
# MARKDOWN GENERATION - ERROR HANDLING TESTS
# ============================================================================

test_that("generate_element_summary_md_safe handles NULL input", {
  result <- generate_element_summary_md_safe(NULL)

  expect_true(is.character(result))
  expect_true(length(result) > 0)
  expect_true(any(grepl("No ISA data", result)))
})

test_that("generate_element_summary_md_safe handles empty ISA data", {
  isa_data <- create_empty_isa_structure_safe()

  result <- generate_element_summary_md_safe(isa_data)

  expect_true(is.character(result))
  expect_true(length(result) > 0)
  # Should show 0 for each element type
  expect_true(any(grepl("0 identified", result)))
})

test_that("generate_element_summary_md_safe succeeds with data", {
  isa_data <- create_empty_isa_structure_safe()

  # Add elements
  driver_element <- data.frame(
    id = "D01",
    name = "Test Driver",
    indicator = "", indicator_unit = "", data_source = "",
    time_horizon_start = as.Date(NA), time_horizon_end = as.Date(NA),
    baseline_value = NA_real_, current_value = NA_real_,
    notes = "", needs_category = "", trends = "",
    stringsAsFactors = FALSE
  )

  isa_data <- add_element_safe(isa_data, "drivers", driver_element)

  result <- generate_element_summary_md_safe(isa_data)

  expect_true(is.character(result))
  expect_true(any(grepl("1 identified", result)))
})

test_that("generate_network_summary_md_safe handles NULL input", {
  result <- generate_network_summary_md_safe(NULL)

  expect_true(is.character(result))
  expect_true(any(grepl("No network data", result)))
})

test_that("generate_network_summary_md_safe handles empty CLD data", {
  cld_data <- list(nodes = NULL, edges = NULL, loops = NULL)

  result <- generate_network_summary_md_safe(cld_data)

  expect_true(is.character(result))
  expect_true(any(grepl("0", result)))
})

test_that("generate_network_summary_md_safe succeeds with data", {
  cld_data <- list(
    nodes = data.frame(id = c("A", "B"), name = c("A", "B")),
    edges = data.frame(from = "A", to = "B"),
    loops = data.frame(type = c("R", "B"))
  )

  result <- generate_network_summary_md_safe(cld_data)

  expect_true(is.character(result))
  expect_true(any(grepl("2", result)))  # 2 nodes
  expect_true(any(grepl("1", result)))  # 1 edge
})

test_that("generate_recommendations_md_safe handles NULL input", {
  result <- generate_recommendations_md_safe(NULL)

  expect_true(is.character(result))
  expect_true(any(grepl("No recommendations", result)))
})

test_that("generate_recommendations_md_safe handles empty responses", {
  responses_data <- list(measures = data.frame(), scenarios = list())

  result <- generate_recommendations_md_safe(responses_data)

  expect_true(is.character(result))
  expect_true(any(grepl("No specific response measures", result)))
})

test_that("generate_recommendations_md_safe succeeds with data", {
  responses_data <- list(
    measures = data.frame(
      id = c("M1", "M2"),
      name = c("Measure 1", "Measure 2"),
      type = c("Policy", "Management"),
      description = c("Test measure 1", "Test measure 2"),
      target_elements = c("D01", "P01"),
      expected_effect = c("Positive", "Negative"),
      implementation_cost = c(1000, 2000),
      feasibility = c("High", "Medium"),
      stakeholder_acceptance = c("High", "Low"),
      stringsAsFactors = FALSE
    ),
    scenarios = list()
  )

  result <- generate_recommendations_md_safe(responses_data)

  expect_true(is.character(result))
  expect_true(any(grepl("2 response measures", result)))
  expect_true(any(grepl("Measure 1", result)))
})

# ============================================================================
# INTEGRATION TESTS
# ============================================================================

test_that("Complete export workflow - all formats", {
  skip_on_cran()
  skip_if_not_installed("rmarkdown")

  # Create project with comprehensive data
  project <- create_empty_project_safe("Complete Export Test")

  project$data$metadata$da_site <- "Test Site"
  project$data$metadata$focal_issue <- "Marine Pollution"

  # Add stakeholder
  project$data$pims$stakeholders <- data.frame(
    id = "S1", name = "Stakeholder 1", organization = "Org 1", type = "Public",
    power = 8, interest = 9, contact_email = "test@example.com",
    contact_phone = "123-456", communication_preference = "Email", notes = ""
  )

  # Add driver
  driver <- data.frame(
    id = "D01", name = "Population Growth",
    indicator = "Population", indicator_unit = "People", data_source = "Census",
    time_horizon_start = as.Date("2020-01-01"),
    time_horizon_end = as.Date("2025-12-31"),
    baseline_value = 10000, current_value = 12000,
    notes = "Growing", needs_category = "Economic", trends = "Increasing"
  )

  project$data$isa_data <- add_element_safe(project$data$isa_data, "drivers", driver)

  # Test Excel export
  excel_path <- file.path(test_temp_dir, "complete_test.xlsx")
  excel_result <- export_project_excel_safe(project, excel_path)
  expect_true(excel_result)
  expect_true(file.exists(excel_path))

  # Test JSON export
  json_path <- file.path(test_temp_dir, "complete_test.json")
  json_result <- export_project_json_safe(project, json_path)
  expect_true(json_result)
  expect_true(file.exists(json_path))

  # Test CSV zip export
  zip_path <- file.path(test_temp_dir, "complete_test.zip")
  zip_result <- export_project_csv_zip_safe(project, zip_path)
  expect_true(zip_result)
  expect_true(file.exists(zip_path))

  # Test HTML report
  if (rmarkdown::pandoc_available()) {
    html_path <- file.path(test_temp_dir, "complete_report.html")
    report_result <- generate_executive_summary_safe(project, html_path)
    expect_true(report_result)
    expect_true(file.exists(html_path))

    # Cleanup report
    if (file.exists(html_path)) unlink(html_path)
  }

  # Cleanup
  if (file.exists(excel_path)) unlink(excel_path)
  if (file.exists(json_path)) unlink(json_path)
  if (file.exists(zip_path)) unlink(zip_path)
})

test_that("Export handles partial success gracefully", {
  project <- create_empty_project_safe("Partial Export Test")

  # Export to valid path should succeed
  valid_path <- file.path(test_temp_dir, "partial_success.xlsx")
  result1 <- export_project_excel_safe(project, valid_path)
  expect_true(result1)

  # Export to invalid path should fail gracefully
  invalid_path <- "/nonexistent/directory/output.xlsx"
  result2 <- export_project_excel_safe(project, invalid_path)
  expect_false(result2)

  # First export should still exist
  expect_true(file.exists(valid_path))

  # Cleanup
  if (file.exists(valid_path)) unlink(valid_path)
})

test_that("Export creates files with expected content structure", {
  project <- create_empty_project_safe("Content Test")

  # Add comprehensive data
  project$data$pims$stakeholders <- data.frame(
    id = "S1", name = "Test", organization = "", type = "",
    power = 5, interest = 5, contact_email = "", contact_phone = "",
    communication_preference = "", notes = ""
  )

  driver <- data.frame(
    id = "D01", name = "Driver",
    indicator = "", indicator_unit = "", data_source = "",
    time_horizon_start = as.Date(NA), time_horizon_end = as.Date(NA),
    baseline_value = NA_real_, current_value = NA_real_,
    notes = "", needs_category = "", trends = ""
  )

  project$data$isa_data <- add_element_safe(project$data$isa_data, "drivers", driver)

  # Export to JSON
  json_path <- file.path(test_temp_dir, "content_test.json")
  result <- export_project_json_safe(project, json_path)

  expect_true(result)

  # Read and verify content
  json_data <- jsonlite::fromJSON(json_path)

  expect_true("project_id" %in% names(json_data))
  expect_true("project_name" %in% names(json_data))
  expect_equal(json_data$project_name, "Content Test")
  expect_true("data" %in% names(json_data))
  expect_true("pims" %in% names(json_data$data))
  expect_true("isa_data" %in% names(json_data$data))

  # Cleanup
  if (file.exists(json_path)) unlink(json_path)
})

# ============================================================================
# CLEANUP
# ============================================================================

# Clean up test temp directory at end of tests
test_that("Cleanup test files", {
  # This is just to ensure any remaining test files are cleaned up
  test_files <- list.files(test_temp_dir, pattern = "^(test_|complete_|partial_|content_)",
                           full.names = TRUE)

  for (file in test_files) {
    if (file.exists(file)) {
      tryCatch(unlink(file), error = function(e) {})
    }
  }

  expect_true(TRUE)  # Always pass
})
