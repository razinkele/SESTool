# test-data-structure.R
# Unit tests for data structure functions

library(testthat)
library(shiny)

# Source the data structure functions
source("../../functions/data_structure.R", local = TRUE)

test_that("create_empty_isa_data creates proper structure", {
  isa_data <- create_empty_isa_data()

  expect_type(isa_data, "list")

  # Check expected components
  expected_components <- c("drivers", "activities", "pressures",
                          "marine_processes", "ecosystem_services", "goods_benefits")

  for (component in expected_components) {
    if (component %in% names(isa_data)) {
      expect_true(is.data.frame(isa_data[[component]]) || is.list(isa_data[[component]]))
    }
  }
})

test_that("adjacency matrix creation works correctly", {
  # Test with simple row and column names
  row_names <- c("A", "B", "C")
  col_names <- c("X", "Y")

  adj_matrix <- create_adjacency_matrix(row_names, col_names)

  expect_true(is.matrix(adj_matrix))
  expect_equal(nrow(adj_matrix), 3)
  expect_equal(ncol(adj_matrix), 2)
  expect_equal(rownames(adj_matrix), row_names)
  expect_equal(colnames(adj_matrix), col_names)
})

test_that("data export to data frame works", {
  # Create test ISA data
  test_data <- list(
    drivers = data.frame(
      ID = c("D1", "D2"),
      Name = c("Driver 1", "Driver 2"),
      stringsAsFactors = FALSE
    ),
    activities = data.frame(
      ID = c("A1", "A2"),
      Name = c("Activity 1", "Activity 2"),
      stringsAsFactors = FALSE
    )
  )

  df <- isa_to_dataframe(test_data)

  expect_true(is.data.frame(df))
  expect_true(nrow(df) > 0)
})

test_that("element merging works correctly", {
  # Create test data
  data1 <- data.frame(
    ID = c("E1", "E2"),
    Name = c("Element 1", "Element 2"),
    stringsAsFactors = FALSE
  )

  data2 <- data.frame(
    ID = c("E3", "E4"),
    Name = c("Element 3", "Element 4"),
    stringsAsFactors = FALSE
  )

  merged <- merge_isa_elements(data1, data2)

  expect_true(is.data.frame(merged))
  expect_equal(nrow(merged), 4)
  expect_true(all(c("E1", "E2", "E3", "E4") %in% merged$ID))
})

test_that("data structure conversion functions work", {
  # Create test ISA data with connections
  test_data <- list(
    nodes = data.frame(
      id = c("N1", "N2", "N3"),
      label = c("Node 1", "Node 2", "Node 3"),
      type = c("Driver", "Activity", "Pressure"),
      stringsAsFactors = FALSE
    ),
    edges = data.frame(
      from = c("N1", "N2"),
      to = c("N2", "N3"),
      type = c("+", "-"),
      stringsAsFactors = FALSE
    )
  )

  network <- convert_to_network_format(test_data)

  expect_type(network, "list")
  expect_true("nodes" %in% names(network))
  expect_true("edges" %in% names(network))
})
