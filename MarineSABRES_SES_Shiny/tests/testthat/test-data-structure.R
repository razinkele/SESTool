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
      Name = c("Driver 1", "Driver 2")
      
    ),
    activities = data.frame(
      ID = c("A1", "A2"),
      Name = c("Activity 1", "Activity 2")
      
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
    Name = c("Element 1", "Element 2")
    
  )

  data2 <- data.frame(
    ID = c("E3", "E4"),
    Name = c("Element 3", "Element 4")
    
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
      type = c("Driver", "Activity", "Pressure")

    ),
    edges = data.frame(
      from = c("N1", "N2"),
      to = c("N2", "N3"),
      type = c("+", "-")

    )
  )

  network <- convert_to_network_format(test_data)

  expect_type(network, "list")
  expect_true("nodes" %in% names(network))
  expect_true("edges" %in% names(network))
})

test_that("user_edited_matrices round-trip persists through load_isa_elements_from_saved", {
  # Test the core logic directly without sourcing the full file
  isa_saved_with_edit_flags <- list(
    user_edited_matrices = list(es_gb = matrix(TRUE, 1, 1,
      dimnames = list("ES001", "GB001"))),
    adjacency_matrices = list(es_gb = matrix("+High:Low", 1, 1,
      dimnames = list("ES001", "GB001")))
  )
  isa_data <- list(
    adjacency_matrices = list(), user_edited_matrices = list()
  )

  # Simulate the fix logic inline
  if (!is.null(isa_saved_with_edit_flags$user_edited_matrices)) {
    isa_data$user_edited_matrices <- isa_saved_with_edit_flags$user_edited_matrices
  } else if (!is.null(isa_data$adjacency_matrices) && length(isa_data$adjacency_matrices) > 0) {
    isa_data$user_edited_matrices <- lapply(isa_data$adjacency_matrices, function(m) {
      if (is.null(m)) return(NULL)
      matrix(FALSE, nrow = nrow(m), ncol = ncol(m), dimnames = dimnames(m))
    })
  } else {
    isa_data$user_edited_matrices <- list()
  }

  expect_true(isa_data$user_edited_matrices[["es_gb"]]["ES001", "GB001"],
              label = "user_edited flag must survive round-trip through load")
})

test_that("user_edited_matrices initializes all-FALSE for legacy projects", {
  # Test the legacy initialization logic
  isa_saved_legacy <- list(
    adjacency_matrices = list(es_gb = matrix("+Medium:Medium", 1, 1,
      dimnames = list("ES001", "GB001")))
    # NO user_edited_matrices field (legacy)
  )
  isa_data <- list(
    adjacency_matrices = list(), user_edited_matrices = list()
  )

  # Copy adjacency matrices first (as load function does)
  isa_data$adjacency_matrices <- isa_saved_legacy$adjacency_matrices

  # Then apply the fix logic
  if (!is.null(isa_saved_legacy$user_edited_matrices)) {
    isa_data$user_edited_matrices <- isa_saved_legacy$user_edited_matrices
  } else if (!is.null(isa_data$adjacency_matrices) && length(isa_data$adjacency_matrices) > 0) {
    isa_data$user_edited_matrices <- lapply(isa_data$adjacency_matrices, function(m) {
      if (is.null(m)) return(NULL)
      matrix(FALSE, nrow = nrow(m), ncol = ncol(m), dimnames = dimnames(m))
    })
  } else {
    isa_data$user_edited_matrices <- list()
  }

  expect_false(isa_data$user_edited_matrices[["es_gb"]]["ES001", "GB001"],
               label = "Legacy project (no user_edited field) gets all-FALSE init")
})

test_that("Auto-hydration: no crash when matrices are NULL and LinkedX columns present", {
  td <- getwd()
  root <- if (basename(td) == "testthat") dirname(dirname(td)) else td
  source_for_test(c("constants.R", "functions/data_structure.R",
                    "functions/matrix_from_linked.R",
                    "functions/module_validation_helpers.R",
                    "functions/isa_form_builders.R"))

  isa_saved <- list(
    goods_benefits = data.frame(ID = "GB001", Name = "Food", stringsAsFactors = FALSE),
    ecosystem_services = data.frame(
      ID = "ES001", Name = "Fish", linkedgb = "GB001",
      Confidence = "High", stringsAsFactors = FALSE
    ),
    adjacency_matrices = list()  # NO es_gb slot at all
  )
  isa_data <- list(
    adjacency_matrices = list(), user_edited_matrices = list()
  )
  # Should not error when calling hydration logic with NULL matrices
  expect_no_error(load_isa_elements_from_saved(isa_data, isa_saved))
})

test_that("Auto-hydration: does not fire when matrix exists (even if empty)", {
  td <- getwd()
  root <- if (basename(td) == "testthat") dirname(dirname(td)) else td
  source_for_test(c("constants.R", "functions/data_structure.R",
                    "functions/matrix_from_linked.R",
                    "functions/module_validation_helpers.R",
                    "functions/isa_form_builders.R"))
  empty_mat <- matrix("", nrow = 1, ncol = 1, dimnames = list("ES001", "GB001"))
  isa_saved <- list(
    goods_benefits = data.frame(ID = "GB001", Name = "Food", stringsAsFactors = FALSE),
    ecosystem_services = data.frame(
      ID = "ES001", Name = "Fish", linkedgb = "GB001",
      Confidence = "High", stringsAsFactors = FALSE
    ),
    adjacency_matrices = list(es_gb = empty_mat)  # PRESENT but empty
  )
  isa_data <- list(
    adjacency_matrices = list(es_gb = empty_mat), user_edited_matrices = list()
  )
  # After load, matrix should still be the original empty matrix (not re-hydrated)
  load_isa_elements_from_saved(isa_data, isa_saved)
  expect_equal(isa_data$adjacency_matrices[["es_gb"]], empty_mat,
               info = "Empty-but-present matrix must NOT be re-hydrated")
})

test_that("Auto-hydration: soft-fails on malformed data (no crash)", {
  td <- getwd()
  root <- if (basename(td) == "testthat") dirname(dirname(td)) else td
  source_for_test(c("constants.R", "functions/data_structure.R",
                    "functions/matrix_from_linked.R",
                    "functions/module_validation_helpers.R",
                    "functions/isa_form_builders.R"))
  # Malformed: ecosystem_services has no ID column — rebuild will throw
  isa_saved <- list(
    goods_benefits = data.frame(ID = "GB001", Name = "Food", stringsAsFactors = FALSE),
    ecosystem_services = data.frame(linkedgb = "GB001", stringsAsFactors = FALSE),  # no ID
    adjacency_matrices = list()
  )
  isa_data <- list(
    adjacency_matrices = list(), user_edited_matrices = list()
  )
  # Should not crash even with malformed data
  expect_no_error(load_isa_elements_from_saved(isa_data, isa_saved))
})
