# test-data-structure-enhanced.R (retained)
# Tests for enhanced data structure functions with error handling

library(testthat)

# Source enhanced functions
source("../../functions/data_structure_enhanced.R", local = TRUE)

# ============================================================================
# VALIDATION UTILITIES TESTS
# ============================================================================

test_that("validate_project_structure catches NULL input", {
  expect_error(
    validate_project_structure(NULL),
    "Project data is NULL"
  )
})

test_that("validate_project_structure catches non-list input", {
  expect_error(
    validate_project_structure("not a list"),
    "Project data must be a list"
  )
})

test_that("validate_project_structure catches missing required fields", {
  project <- list(project_id = "test")  # Missing project_name and data
  expect_error(
    validate_project_structure(project),
    "Missing required project fields"
  )
})

test_that("validate_project_structure accepts valid structure", {
  project <- list(
    project_id = "TEST_001",
    project_name = "Test",
    data = list()
  )
  expect_true(validate_project_structure(project))
})

test_that("validate_element_type catches NULL input", {
  expect_error(
    validate_element_type(NULL),
    "Element type is NULL"
  )
})

test_that("validate_element_type catches invalid type", {
  expect_error(
    validate_element_type("Invalid Type"),
    "Invalid element type"
  )
})

test_that("validate_element_type accepts valid types", {
  valid_types <- c(
    "Goods & Benefits",
    "Ecosystem Services",
    "Marine Processes & Functioning",
    "Pressures",
    "Activities",
    "Drivers"
  )

  for (type in valid_types) {
    expect_true(validate_element_type(type))
  }
})

test_that("validate_element_data catches NULL input", {
  expect_error(
    validate_element_data(NULL),
    "Element dataframe is NULL"
  )
})

test_that("validate_element_data catches non-dataframe", {
  expect_error(
    validate_element_data(list(a = 1)),
    "Element data must be dataframe"
  )
})

test_that("validate_element_data catches missing columns", {
  df <- data.frame(value = 1)  # Missing id and name
  expect_error(
    validate_element_data(df),
    "Missing required columns"
  )
})

test_that("validate_element_data accepts valid dataframe", {
  df <- data.frame(
    id = "TEST_01",
    name = "Test Element",
    stringsAsFactors = FALSE
  )
  expect_true(validate_element_data(df))
})

test_that("validate_adjacency_dimensions catches NULL inputs", {
  expect_error(
    validate_adjacency_dimensions(NULL, c("A")),
    "from_elements is NULL"
  )

  expect_error(
    validate_adjacency_dimensions(c("A"), NULL),
    "to_elements is NULL"
  )
})

test_that("validate_adjacency_dimensions accepts valid vectors", {
  expect_true(validate_adjacency_dimensions(c("A", "B"), c("C", "D")))
})

test_that("validate_adjacency_matrix catches NULL input", {
  expect_error(
    validate_adjacency_matrix(NULL),
    "Adjacency matrix is NULL"
  )
})

test_that("validate_adjacency_matrix catches non-matrix input", {
  expect_error(
    validate_adjacency_matrix(data.frame(a = 1)),
    "Adjacency matrix must be matrix"
  )
})

test_that("validate_adjacency_matrix catches matrix without names", {
  mat <- matrix(1:4, nrow = 2)
  expect_error(
    validate_adjacency_matrix(mat),
    "must have row and column names"
  )
})

test_that("validate_adjacency_matrix accepts valid matrix", {
  mat <- matrix("", nrow = 2, ncol = 2)
  rownames(mat) <- c("A", "B")
  colnames(mat) <- c("C", "D")
  expect_true(validate_adjacency_matrix(mat))
})

# ============================================================================
# CREATE EMPTY PROJECT - ERROR HANDLING TESTS
# ============================================================================

test_that("create_empty_project_safe handles NULL project_name", {
  result <- create_empty_project_safe(NULL)
  expect_null(result)
})

test_that("create_empty_project_safe handles empty string project_name", {
  result <- create_empty_project_safe("")
  expect_null(result)
})

test_that("create_empty_project_safe handles invalid type project_name", {
  result <- create_empty_project_safe(123)  # Number instead of string
  expect_null(result)
})

test_that("create_empty_project_safe truncates very long project_name", {
  long_name <- paste(rep("A", 250), collapse = "")
  result <- create_empty_project_safe(long_name)

  expect_false(is.null(result))
  expect_true(nchar(result$project_name) <= 200)
})

test_that("create_empty_project_safe succeeds with valid input", {
  result <- create_empty_project_safe("Test Project")

  expect_false(is.null(result))
  expect_equal(result$project_name, "Test Project")
  expect_true("project_id" %in% names(result))
  expect_true("data" %in% names(result))
  expect_true("isa_data" %in% names(result$data))
  expect_true("pims" %in% names(result$data))
})

test_that("create_empty_project_safe handles NULL da_site gracefully", {
  result <- create_empty_project_safe("Test", NULL)

  expect_false(is.null(result))
  expect_null(result$data$metadata$da_site)
})

test_that("create_empty_project_safe validates da_site type", {
  result <- create_empty_project_safe("Test", 123)  # Invalid type

  # Should succeed but da_site should be NULL
  expect_false(is.null(result))
  expect_null(result$data$metadata$da_site)
})

# ============================================================================
# CREATE EMPTY ELEMENT - ERROR HANDLING TESTS
# ============================================================================

test_that("create_empty_element_df_safe handles NULL element_type", {
  result <- create_empty_element_df_safe(NULL)
  expect_null(result)
})

test_that("create_empty_element_df_safe handles invalid element_type", {
  result <- create_empty_element_df_safe("Invalid Type")
  expect_null(result)
})

test_that("create_empty_element_df_safe succeeds with valid types", {
  types <- c(
    "Goods & Benefits",
    "Ecosystem Services",
    "Marine Processes & Functioning",
    "Pressures",
    "Activities",
    "Drivers"
  )

  for (type in types) {
    result <- create_empty_element_df_safe(type)

    expect_false(is.null(result), info = paste("Failed for:", type))
    expect_true(is.data.frame(result))
    expect_true("id" %in% names(result))
    expect_true("name" %in% names(result))
  }
})

test_that("create_empty_element_df_safe adds type-specific columns", {
  # Ecosystem Services should have category column
  result <- create_empty_element_df_safe("Ecosystem Services")
  expect_true("category" %in% names(result))

  # Pressures should have type and spatial_scale columns
  result <- create_empty_element_df_safe("Pressures")
  expect_true("type" %in% names(result))
  expect_true("spatial_scale" %in% names(result))

  # Drivers should have needs_category column
  result <- create_empty_element_df_safe("Drivers")
  expect_true("needs_category" %in% names(result))
})

# ============================================================================
# ADJACENCY MATRIX - ERROR HANDLING TESTS
# ============================================================================

test_that("create_empty_adjacency_matrix_safe handles NULL inputs", {
  result <- create_empty_adjacency_matrix_safe(NULL, c("A"))
  expect_null(result)

  result <- create_empty_adjacency_matrix_safe(c("A"), NULL)
  expect_null(result)
})

test_that("create_empty_adjacency_matrix_safe handles empty vectors", {
  result <- create_empty_adjacency_matrix_safe(character(), c("A"))
  expect_true(is.matrix(result))
  expect_equal(nrow(result), 0)
})

test_that("create_empty_adjacency_matrix_safe removes duplicates", {
  result <- create_empty_adjacency_matrix_safe(
    c("A", "A", "B"),
    c("C", "C", "D")
  )

  expect_false(is.null(result))
  expect_equal(nrow(result), 2)  # A and B (duplicate A removed)
  expect_equal(ncol(result), 2)  # C and D (duplicate C removed)
})

test_that("create_empty_adjacency_matrix_safe succeeds with valid inputs", {
  result <- create_empty_adjacency_matrix_safe(
    c("A", "B"),
    c("C", "D")
  )

  expect_false(is.null(result))
  expect_true(is.matrix(result))
  expect_equal(dim(result), c(2, 2))
  expect_equal(rownames(result), c("A", "B"))
  expect_equal(colnames(result), c("C", "D"))
})

test_that("adjacency_to_edgelist_safe handles NULL matrix", {
  result <- adjacency_to_edgelist_safe(NULL, c("A"), c("B"))
  expect_null(result)
})

test_that("adjacency_to_edgelist_safe handles mismatched dimensions", {
  mat <- matrix("", nrow = 2, ncol = 2)
  rownames(mat) <- c("A", "B")
  colnames(mat) <- c("C", "D")

  # IDs don't match matrix dimensions
  result <- adjacency_to_edgelist_safe(mat, c("X"), c("Y", "Z"))
  expect_null(result)
})

test_that("adjacency_to_edgelist_safe converts matrix successfully", {
  mat <- matrix("", nrow = 2, ncol = 2)
  rownames(mat) <- c("A", "B")
  colnames(mat) <- c("C", "D")
  mat[1, 1] <- "+"
  mat[2, 2] <- "-"

  result <- adjacency_to_edgelist_safe(mat, c("A", "B"), c("C", "D"))

  expect_false(is.null(result))
  expect_true(is.data.frame(result))
  expect_equal(nrow(result), 2)
  expect_true(all(c("from", "to", "value") %in% names(result)))
})

test_that("edgelist_to_adjacency_safe handles NULL edgelist", {
  result <- edgelist_to_adjacency_safe(NULL, c("A"), c("B"))
  expect_null(result)
})

test_that("edgelist_to_adjacency_safe handles missing columns", {
  edgelist <- data.frame(source = "A", target = "B")  # Wrong column names
  result <- edgelist_to_adjacency_safe(edgelist, c("A"), c("B"))
  expect_null(result)
})

test_that("edgelist_to_adjacency_safe converts edgelist successfully", {
  edgelist <- data.frame(
    from = c("A", "B"),
    to = c("C", "D"),
    value = c("+", "-"),
    stringsAsFactors = FALSE
  )

  result <- edgelist_to_adjacency_safe(edgelist, c("A", "B"), c("C", "D"))

  expect_false(is.null(result))
  expect_true(is.matrix(result))
  expect_equal(result["A", "C"], "+")
  expect_equal(result["B", "D"], "-")
})

test_that("edgelist_to_adjacency_safe skips invalid edges", {
  edgelist <- data.frame(
    from = c("A", "X"),  # X doesn't exist
    to = c("C", "Y"),    # Y doesn't exist
    value = c("+", "-"),
    stringsAsFactors = FALSE
  )

  result <- edgelist_to_adjacency_safe(edgelist, c("A", "B"), c("C", "D"))

  expect_false(is.null(result))
  expect_equal(result["A", "C"], "+")
  expect_equal(result[2, 2], "")  # Invalid edge should be skipped
})

# ============================================================================
# PROJECT VALIDATION - ERROR HANDLING TESTS
# ============================================================================

test_that("validate_project_data_safe handles NULL input", {
  result <- validate_project_data_safe(NULL)

  expect_false(result$valid)
  expect_true(length(result$errors) > 0)
})

test_that("validate_project_data_safe handles invalid structure", {
  project <- list(bad = "structure")

  result <- validate_project_data_safe(project)

  expect_false(result$valid)
  expect_true(length(result$errors) > 0)
})

test_that("validate_project_data_safe succeeds with valid project", {
  project <- create_empty_project_safe("Test Project")

  result <- validate_project_data_safe(project)

  expect_true(result$valid)
  expect_length(result$errors, 0)
})

test_that("validate_isa_structure_safe handles NULL input", {
  result <- validate_isa_structure_safe(NULL)

  expect_true(length(result) > 0)
  expect_true(any(grepl("NULL", result)))
})

test_that("validate_isa_structure_safe handles invalid element types", {
  isa_data <- list(
    drivers = data.frame(bad = "structure")  # Missing required columns
  )

  result <- validate_isa_structure_safe(isa_data)

  expect_true(length(result) > 0)
})

test_that("validate_pims_data_safe handles invalid stakeholder values", {
  pims_data <- list(
    stakeholders = data.frame(
      id = "S1",
      name = "Test",
      power = 15,  # Out of range (0-10)
      interest = 5
    )
  )

  result <- validate_pims_data_safe(pims_data)

  expect_true(length(result) > 0)
  expect_true(any(grepl("power", result)))
})

# ============================================================================
# ELEMENT MANIPULATION - ERROR HANDLING TESTS
# ============================================================================

test_that("add_element_safe handles NULL isa_data", {
  element <- data.frame(id = "TEST", name = "Test")
  result <- add_element_safe(NULL, "drivers", element)
  expect_null(result)
})

test_that("add_element_safe handles invalid element_type", {
  isa_data <- list(drivers = data.frame())
  element <- data.frame(id = "TEST", name = "Test")

  result <- add_element_safe(isa_data, "invalid_type", element)

  # Should return unchanged
  expect_equal(result, isa_data)
})

test_that("add_element_safe handles NULL element_data", {
  isa_data <- list(drivers = data.frame())

  result <- add_element_safe(isa_data, "drivers", NULL)

  # Should return unchanged
  expect_equal(result, isa_data)
})

test_that("add_element_safe succeeds with valid input", {
  isa_data <- create_empty_isa_structure_safe()
  element <- data.frame(
    id = "TEST_01",
    name = "Test Driver",
    indicator = "Count",
    indicator_unit = "Number",
    data_source = "Survey",
    time_horizon_start = as.Date("2020-01-01"),
    time_horizon_end = as.Date("2025-01-01"),
    baseline_value = 100,
    current_value = 120,
    notes = "Test note",
    needs_category = "Social",
    trends = "Increasing",
    stringsAsFactors = FALSE
  )

  result <- add_element_safe(isa_data, "drivers", element)

  expect_false(is.null(result))
  expect_equal(nrow(result$drivers), 1)
  expect_equal(result$drivers$id[1], "TEST_01")
})

test_that("update_element_safe handles non-existent element", {
  isa_data <- create_empty_isa_structure_safe()
  element <- data.frame(id = "TEST", name = "Updated")

  result <- update_element_safe(isa_data, "drivers", "NONEXISTENT", element)

  # Should return unchanged
  expect_equal(result, isa_data)
})

test_that("update_element_safe succeeds with valid element", {
  # Create ISA data with one element
  isa_data <- create_empty_isa_structure_safe()
  element <- data.frame(
    id = "TEST_01",
    name = "Original Name",
    indicator = "",
    indicator_unit = "",
    data_source = "",
    time_horizon_start = as.Date(NA),
    time_horizon_end = as.Date(NA),
    baseline_value = NA_real_,
    current_value = NA_real_,
    notes = "",
    needs_category = "",
    trends = "",
    stringsAsFactors = FALSE
  )

  isa_data <- add_element_safe(isa_data, "drivers", element)

  # Update the element
  updated_element <- element
  updated_element$name <- "Updated Name"

  result <- update_element_safe(isa_data, "drivers", "TEST_01", updated_element)

  expect_equal(result$drivers$name[1], "Updated Name")
})

test_that("delete_element_safe handles non-existent element", {
  isa_data <- create_empty_isa_structure_safe()

  result <- delete_element_safe(isa_data, "drivers", "NONEXISTENT")

  # Should return unchanged
  expect_equal(result, isa_data)
})

test_that("delete_element_safe succeeds with valid element", {
  # Create ISA data with one element
  isa_data <- create_empty_isa_structure_safe()
  element <- data.frame(
    id = "TEST_01",
    name = "Test",
    indicator = "",
    indicator_unit = "",
    data_source = "",
    time_horizon_start = as.Date(NA),
    time_horizon_end = as.Date(NA),
    baseline_value = NA_real_,
    current_value = NA_real_,
    notes = "",
    needs_category = "",
    trends = "",
    stringsAsFactors = FALSE
  )

  isa_data <- add_element_safe(isa_data, "drivers", element)
  expect_equal(nrow(isa_data$drivers), 1)

  # Delete the element
  result <- delete_element_safe(isa_data, "drivers", "TEST_01")

  expect_equal(nrow(result$drivers), 0)
})

# ============================================================================
# INTEGRATION TESTS
# ============================================================================

test_that("Complete project workflow with error handling", {
  # Create project
  project <- create_empty_project_safe("Integration Test", "Test Site")
  expect_false(is.null(project))

  # Validate project
  validation <- validate_project_data_safe(project)
  expect_true(validation$valid)

  # Add element
  element <- data.frame(
    id = "TEST_D01",
    name = "Test Driver",
    indicator = "Population",
    indicator_unit = "People",
    data_source = "Census",
    time_horizon_start = as.Date("2020-01-01"),
    time_horizon_end = as.Date("2025-12-31"),
    baseline_value = 1000,
    current_value = 1200,
    notes = "Test driver element",
    needs_category = "Economic",
    trends = "Increasing",
    stringsAsFactors = FALSE
  )

  project$data$isa_data <- add_element_safe(
    project$data$isa_data,
    "drivers",
    element
  )

  expect_equal(nrow(project$data$isa_data$drivers), 1)

  # Create adjacency matrix
  matrix <- create_empty_adjacency_matrix_safe(
    c("TEST_D01"),
    c("GB01", "GB02")
  )

  expect_false(is.null(matrix))
  expect_equal(dim(matrix), c(1, 2))
})

test_that("Error recovery in element operations", {
  isa_data <- create_empty_isa_structure_safe()

  # Try to add invalid element (should fail gracefully)
  bad_element <- data.frame(bad = "data")
  result <- add_element_safe(isa_data, "drivers", bad_element)

  # Should handle error and return unchanged data
  # (Implementation might add it or reject it depending on validation level)
  expect_false(is.null(result))

  # Add valid element
  good_element <- data.frame(
    id = "TEST_01",
    name = "Valid Element",
    indicator = "",
    indicator_unit = "",
    data_source = "",
    time_horizon_start = as.Date(NA),
    time_horizon_end = as.Date(NA),
    baseline_value = NA_real_,
    current_value = NA_real_,
    notes = "",
    needs_category = "",
    trends = "",
    stringsAsFactors = FALSE
  )

  result <- add_element_safe(isa_data, "drivers", good_element)
  expect_true(nrow(result$drivers) >= 1)
})

test_that("Validation catches multiple errors", {
  # Create project with intentional issues
  project <- create_empty_project_safe("Test")
  expect_false(is.null(project))

  # Add stakeholder with invalid power value
  project$data$pims$stakeholders <- data.frame(
    id = "S1",
    name = "Test Stakeholder",
    organization = "Test Org",
    type = "Public",
    power = 20,  # Out of range
    interest = 5,
    contact_email = "invalid_email",  # Invalid format
    contact_phone = "",
    communication_preference = "",
    notes = "",
    stringsAsFactors = FALSE
  )

  # Validate
  validation <- validate_project_data_safe(project)

  # Should catch power range issue
  expect_false(validation$valid)
  expect_true(length(validation$errors) > 0)
})
