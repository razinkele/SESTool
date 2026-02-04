# test-export-functions.R
# Unit tests for export and reporting functions

library(testthat)
library(jsonlite)
library(openxlsx)

# Source export functions if available
if (file.exists("../../functions/export_functions.R")) {
  source("../../functions/export_functions.R", local = TRUE)
}

test_that("export to JSON works correctly", {
  # Create test data
  test_data <- list(
    drivers = data.frame(ID = c("D1", "D2"), Name = c("Driver 1", "Driver 2")),
    activities = data.frame(ID = c("A1", "A2"), Name = c("Activity 1", "Activity 2"))
  )

  temp_file <- tempfile(fileext = ".json")

  export_to_json(test_data, temp_file)

  expect_true(file.exists(temp_file))

  # Read and verify
  loaded_data <- fromJSON(temp_file)
  expect_equal(loaded_data$drivers$Name, c("Driver 1", "Driver 2"))

  unlink(temp_file)
})

test_that("export to CSV works correctly", {
  test_df <- data.frame(
    ID = c("1", "2", "3"),
    Name = c("Item 1", "Item 2", "Item 3"),
    Value = c(10, 20, 30)
  )

  temp_file <- tempfile(fileext = ".csv")

  export_to_csv(test_df, temp_file)

  expect_true(file.exists(temp_file))

  # Read and verify
  loaded_df <- read.csv(temp_file, stringsAsFactors = FALSE)
  expect_equal(nrow(loaded_df), 3)
  expect_equal(loaded_df$Name, c("Item 1", "Item 2", "Item 3"))

  unlink(temp_file)
})

test_that("export to Excel works correctly", {
  test_data <- list(
    Sheet1 = data.frame(ID = c("1", "2"), Name = c("A", "B")),
    Sheet2 = data.frame(ID = c("3", "4"), Name = c("C", "D"))
  )

  temp_file <- tempfile(fileext = ".xlsx")

  export_to_excel(test_data, temp_file)

  expect_true(file.exists(temp_file))

  # Read and verify
  wb <- loadWorkbook(temp_file)
  sheets <- names(wb)
  expect_true("Sheet1" %in% sheets)
  expect_true("Sheet2" %in% sheets)

  unlink(temp_file)
})

test_that("format_report_data formats data correctly", {
  project_data <- create_mock_project_data(include_isa = TRUE)

  formatted <- format_report_data(project_data)

  expect_type(formatted, "list")
  expect_true(length(formatted) > 0)
})

test_that("generate_summary_statistics calculates stats correctly", {
  project_data <- create_mock_project_data(include_isa = TRUE, include_cld = TRUE)

  stats <- generate_summary_statistics(project_data)

  expect_type(stats, "list")

  # Check for expected statistics
  if ("total_elements" %in% names(stats)) {
    expect_true(is.numeric(stats$total_elements))
  }
})

test_that("export network visualization works", {
  # Create test network data
  cld_data <- create_mock_cld_data()

  temp_file <- tempfile(fileext = ".html")

  export_network_viz(cld_data, temp_file, format = "html")

  expect_true(file.exists(temp_file))

  unlink(temp_file)
})

test_that("create_data_tables creates formatted tables", {
  test_df <- data.frame(
    ID = 1:5,
    Name = paste("Item", 1:5),
    Value = runif(5)
  )

  table <- create_data_tables(test_df)

  expect_true(!is.null(table))
})

test_that("validate_export_data validates data before export", {
  # Valid data
  valid_data <- list(
    nodes = data.frame(id = c("N1", "N2"), label = c("Node 1", "Node 2")),
    edges = data.frame(from = "N1", to = "N2")
  )

  expect_true(validate_export_data(valid_data))

  # Invalid data
  expect_false(validate_export_data(NULL))
  expect_false(validate_export_data(list()))
})
