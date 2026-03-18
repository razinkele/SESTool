# tests/testthat/test-isa-export-helpers.R
# Tests for ISA Export Helper Functions
# ==============================================================================

library(testthat)
library(openxlsx)

# Source the file under test
source("../../functions/isa_export_helpers.R", chdir = TRUE)

# ==============================================================================
# Test Data Fixtures
# ==============================================================================

create_mock_isa_data <- function() {
  list(
    goods_benefits = data.frame(
      ID = c("GB1", "GB2"),
      Name = c("Food provision", "Recreation"),
      stringsAsFactors = FALSE
    ),
    ecosystem_services = data.frame(
      ID = c("ES1"),
      Name = c("Fish nursery"),
      stringsAsFactors = FALSE
    ),
    marine_processes = data.frame(
      ID = c("MP1", "MP2"),
      Name = c("Primary production", "Nutrient cycling"),
      stringsAsFactors = FALSE
    ),
    pressures = data.frame(
      ID = c("P1"),
      Name = c("Overfishing"),
      stringsAsFactors = FALSE
    ),
    activities = data.frame(
      ID = c("A1"),
      Name = c("Commercial fishing"),
      stringsAsFactors = FALSE
    ),
    drivers = data.frame(
      ID = c("D1"),
      Name = c("Climate change"),
      stringsAsFactors = FALSE
    ),
    bot_data = data.frame(
      Element = c("Food provision"),
      Score = c(3),
      stringsAsFactors = FALSE
    ),
    adjacency_matrices = NULL
  )
}

create_mock_isa_data_with_matrices <- function() {
  isa <- create_mock_isa_data()
  isa$adjacency_matrices <- list(
    impact = matrix(c(1, 0, 0, 1), nrow = 2,
                    dimnames = list(c("A", "B"), c("A", "B")))
  )
  isa
}

# ==============================================================================
# Test: write_isa_element_sheets
# ==============================================================================

test_that("write_isa_element_sheets creates expected worksheets", {
  wb <- createWorkbook()
  isa <- create_mock_isa_data()

  write_isa_element_sheets(wb, isa, include_adjacency = FALSE)

  sheet_names <- names(wb)
  expect_true("Goods_Benefits" %in% sheet_names)
  expect_true("Ecosystem_Services" %in% sheet_names)
  expect_true("Marine_Processes" %in% sheet_names)
  expect_true("Pressures" %in% sheet_names)
  expect_true("Activities" %in% sheet_names)
  expect_true("Drivers" %in% sheet_names)
  expect_equal(length(sheet_names), 6)
})

test_that("write_isa_element_sheets returns the workbook invisibly", {
  wb <- createWorkbook()
  isa <- create_mock_isa_data()

  result <- write_isa_element_sheets(wb, isa, include_adjacency = FALSE)
  expect_s4_class(result, "Workbook")
})

test_that("write_isa_element_sheets includes adjacency matrices when requested", {
  wb <- createWorkbook()
  isa <- create_mock_isa_data_with_matrices()

  write_isa_element_sheets(wb, isa, include_adjacency = TRUE)

  sheet_names <- names(wb)
  expect_true(any(grepl("^Matrix_", sheet_names)))
  expect_equal(length(sheet_names), 7)  # 6 element sheets + 1 matrix
})

test_that("write_isa_element_sheets skips adjacency when NULL", {
  wb <- createWorkbook()
  isa <- create_mock_isa_data()  # adjacency_matrices = NULL

  write_isa_element_sheets(wb, isa, include_adjacency = TRUE)

  sheet_names <- names(wb)
  expect_false(any(grepl("^Matrix_", sheet_names)))
  expect_equal(length(sheet_names), 6)
})

test_that("write_isa_element_sheets data can be saved and read back", {
  wb <- createWorkbook()
  isa <- create_mock_isa_data()

  write_isa_element_sheets(wb, isa, include_adjacency = FALSE)

  tmp <- tempfile(fileext = ".xlsx")
  on.exit(unlink(tmp), add = TRUE)
  saveWorkbook(wb, tmp, overwrite = TRUE)

  # Read back and verify
  read_back <- read.xlsx(tmp, sheet = "Goods_Benefits")
  expect_equal(nrow(read_back), 2)
  expect_true("Name" %in% names(read_back))
})

# ==============================================================================
# Test: create_isa_analysis_workbook
# ==============================================================================

test_that("create_isa_analysis_workbook creates all expected sheets", {
  isa <- create_mock_isa_data()
  wb <- create_isa_analysis_workbook(isa)

  sheet_names <- names(wb)
  expected <- c("Case_Info", "Goods_Benefits", "Ecosystem_Services",
                "Marine_Processes", "Pressures", "Activities",
                "Drivers", "BOT_Data")

  for (s in expected) {
    expect_true(s %in% sheet_names, info = paste("Missing sheet:", s))
  }
  expect_equal(length(sheet_names), 8)
})

test_that("create_isa_analysis_workbook returns a Workbook object", {
  isa <- create_mock_isa_data()
  wb <- create_isa_analysis_workbook(isa)
  expect_s4_class(wb, "Workbook")
})

test_that("create_isa_analysis_workbook data round-trips correctly", {
  isa <- create_mock_isa_data()
  wb <- create_isa_analysis_workbook(isa)

  tmp <- tempfile(fileext = ".xlsx")
  on.exit(unlink(tmp), add = TRUE)
  saveWorkbook(wb, tmp, overwrite = TRUE)

  drivers <- read.xlsx(tmp, sheet = "Drivers")
  expect_equal(nrow(drivers), 1)
  expect_equal(drivers$Name, "Climate change")
})

# ==============================================================================
# Test: build_kumu_elements
# ==============================================================================

test_that("build_kumu_elements returns correct columns", {
  isa <- create_mock_isa_data()
  result <- build_kumu_elements(isa)

  expect_true(is.data.frame(result))
  expect_true("Label" %in% names(result))
  expect_true("Type" %in% names(result))
  expect_true("ID" %in% names(result))
})

test_that("build_kumu_elements combines all element types", {
  isa <- create_mock_isa_data()
  result <- build_kumu_elements(isa)

  # Total: 2 GB + 1 ES + 2 MP + 1 P + 1 A + 1 D = 8

  expect_equal(nrow(result), 8)
})

test_that("build_kumu_elements assigns correct types", {
  isa <- create_mock_isa_data()
  result <- build_kumu_elements(isa)

  expect_true("Goods & Benefits" %in% result$Type)
  expect_true("Ecosystem Service" %in% result$Type)
  expect_true("Marine Process" %in% result$Type)
  expect_true("Pressure" %in% result$Type)
  expect_true("Activity" %in% result$Type)
  expect_true("Driver" %in% result$Type)
})

test_that("build_kumu_elements preserves element names", {
  isa <- create_mock_isa_data()
  result <- build_kumu_elements(isa)

  expect_true("Food provision" %in% result$Label)
  expect_true("Climate change" %in% result$Label)
  expect_true("Fish nursery" %in% result$Label)
})

test_that("build_kumu_elements handles single-row element types", {
  isa <- create_mock_isa_data()
  result <- build_kumu_elements(isa)

  driver_rows <- result[result$Type == "Driver", ]
  expect_equal(nrow(driver_rows), 1)
  expect_equal(driver_rows$Label, "Climate change")
})

# ==============================================================================
# Test: create_kumu_export_zip
# ==============================================================================

test_that("create_kumu_export_zip creates a zip file", {
  isa <- create_mock_isa_data()
  tmp_zip <- tempfile(fileext = ".zip")
  on.exit(unlink(tmp_zip), add = TRUE)

  create_kumu_export_zip(isa, tmp_zip)

  expect_true(file.exists(tmp_zip))
  expect_gt(file.size(tmp_zip), 0)
})

test_that("create_kumu_export_zip contains expected CSV files", {
  isa <- create_mock_isa_data()
  tmp_zip <- tempfile(fileext = ".zip")
  on.exit(unlink(tmp_zip), add = TRUE)

  create_kumu_export_zip(isa, tmp_zip)

  contents <- unzip(tmp_zip, list = TRUE)$Name
  # Check that elements.csv and connections.csv are in the zip
  expect_true(any(grepl("elements\\.csv$", contents)))
  expect_true(any(grepl("connections\\.csv$", contents)))
})

test_that("create_kumu_export_zip elements.csv has correct data", {
  isa <- create_mock_isa_data()
  tmp_zip <- tempfile(fileext = ".zip")
  tmp_dir <- tempfile()
  dir.create(tmp_dir)
  on.exit({
    unlink(tmp_zip)
    unlink(tmp_dir, recursive = TRUE)
  }, add = TRUE)

  create_kumu_export_zip(isa, tmp_zip)

  unzip(tmp_zip, exdir = tmp_dir)

  # Find elements.csv in extracted files
  csv_files <- list.files(tmp_dir, pattern = "elements\\.csv$", recursive = TRUE, full.names = TRUE)
  expect_true(length(csv_files) > 0)

  elements <- read.csv(csv_files[1], stringsAsFactors = FALSE)
  expect_equal(nrow(elements), 8)
  expect_true("Label" %in% names(elements))
  expect_true("Type" %in% names(elements))
})

test_that("create_kumu_export_zip connections.csv has correct schema", {
  isa <- create_mock_isa_data()
  tmp_zip <- tempfile(fileext = ".zip")
  tmp_dir <- tempfile()
  dir.create(tmp_dir)
  on.exit({
    unlink(tmp_zip)
    unlink(tmp_dir, recursive = TRUE)
  }, add = TRUE)

  create_kumu_export_zip(isa, tmp_zip)
  unzip(tmp_zip, exdir = tmp_dir)

  csv_files <- list.files(tmp_dir, pattern = "connections\\.csv$", recursive = TRUE, full.names = TRUE)
  expect_true(length(csv_files) > 0)

  connections <- read.csv(csv_files[1], stringsAsFactors = FALSE, check.names = FALSE)
  expect_true("From" %in% names(connections))
  expect_true("To" %in% names(connections))
  expect_true("Type" %in% names(connections))
  expect_true("Strength" %in% names(connections))
})
