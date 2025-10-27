# Tests for Confidence Property Implementation
# Tests all confidence-related functionality across the application

library(testthat)
library(dplyr)

# ============================================================================
# GLOBAL CONSTANTS TESTS
# ============================================================================

test_that("confidence global constants are defined correctly", {

  # Test CONFIDENCE_LEVELS
  expect_true(exists("CONFIDENCE_LEVELS"))
  expect_equal(CONFIDENCE_LEVELS, 1:5)
  expect_length(CONFIDENCE_LEVELS, 5)

  # Test CONFIDENCE_DEFAULT
  expect_true(exists("CONFIDENCE_DEFAULT"))
  expect_equal(CONFIDENCE_DEFAULT, 3)
  expect_true(CONFIDENCE_DEFAULT %in% CONFIDENCE_LEVELS)

  # Test CONFIDENCE_LABELS
  expect_true(exists("CONFIDENCE_LABELS"))
  expect_length(CONFIDENCE_LABELS, 5)
  expect_equal(names(CONFIDENCE_LABELS), as.character(1:5))
  expect_equal(CONFIDENCE_LABELS["1"], c("1" = "Very Low"))
  expect_equal(CONFIDENCE_LABELS["2"], c("2" = "Low"))
  expect_equal(CONFIDENCE_LABELS["3"], c("3" = "Medium"))
  expect_equal(CONFIDENCE_LABELS["4"], c("4" = "High"))
  expect_equal(CONFIDENCE_LABELS["5"], c("5" = "Very High"))

  # Test CONFIDENCE_OPACITY
  expect_true(exists("CONFIDENCE_OPACITY"))
  expect_length(CONFIDENCE_OPACITY, 5)
  expect_equal(names(CONFIDENCE_OPACITY), as.character(1:5))
  expect_equal(CONFIDENCE_OPACITY["1"], c("1" = 0.3))
  expect_equal(CONFIDENCE_OPACITY["2"], c("2" = 0.5))
  expect_equal(CONFIDENCE_OPACITY["3"], c("3" = 0.7))
  expect_equal(CONFIDENCE_OPACITY["4"], c("4" = 0.85))
  expect_equal(CONFIDENCE_OPACITY["5"], c("5" = 1.0))

  # Test opacity values are in ascending order
  expect_true(all(diff(as.numeric(CONFIDENCE_OPACITY)) > 0))

  # Test opacity range (0-1)
  expect_true(all(CONFIDENCE_OPACITY >= 0))
  expect_true(all(CONFIDENCE_OPACITY <= 1))
})

test_that("confidence constants are consistent with each other", {

  # All constants should cover same range
  expect_equal(length(CONFIDENCE_LEVELS), length(CONFIDENCE_LABELS))
  expect_equal(length(CONFIDENCE_LEVELS), length(CONFIDENCE_OPACITY))

  # Labels and opacity should have keys matching CONFIDENCE_LEVELS
  expect_equal(names(CONFIDENCE_LABELS), as.character(CONFIDENCE_LEVELS))
  expect_equal(names(CONFIDENCE_OPACITY), as.character(CONFIDENCE_LEVELS))

  # Default should be in the middle
  expect_equal(CONFIDENCE_DEFAULT, median(CONFIDENCE_LEVELS))
})

# ============================================================================
# PARSE FUNCTION TESTS
# ============================================================================

test_that("parse_connection_value handles confidence correctly", {

  # Test 1: No confidence specified (should default to CONFIDENCE_DEFAULT)
  result1 <- parse_connection_value("+strong")
  expect_equal(result1$polarity, "+")
  expect_equal(result1$strength, "strong")
  expect_equal(result1$confidence, CONFIDENCE_DEFAULT)

  # Test 2: Valid confidence specified (max level)
  result2 <- parse_connection_value(paste0("+medium:", max(CONFIDENCE_LEVELS)))
  expect_equal(result2$polarity, "+")
  expect_equal(result2$strength, "medium")
  expect_equal(result2$confidence, max(CONFIDENCE_LEVELS))

  # Test 3: Minimum confidence
  result3 <- parse_connection_value(paste0("-weak:", min(CONFIDENCE_LEVELS)))
  expect_equal(result3$polarity, "-")
  expect_equal(result3$strength, "weak")
  expect_equal(result3$confidence, min(CONFIDENCE_LEVELS))

  # Test 4: Out of range confidence - too high (should default to CONFIDENCE_DEFAULT)
  result4 <- parse_connection_value("+strong:10")
  expect_equal(result4$confidence, CONFIDENCE_DEFAULT)

  # Test 5: Out of range confidence - zero (should default to CONFIDENCE_DEFAULT)
  result5 <- parse_connection_value("-medium:0")
  expect_equal(result5$confidence, CONFIDENCE_DEFAULT)

  # Test 6: Negative confidence (should default to CONFIDENCE_DEFAULT)
  result6 <- parse_connection_value("+weak:-1")
  expect_equal(result6$confidence, CONFIDENCE_DEFAULT)

  # Test 7: All confidence levels
  for (conf in CONFIDENCE_LEVELS) {
    result <- parse_connection_value(paste0("+medium:", conf))
    expect_equal(result$confidence, conf)
  }
})

# ============================================================================
# EDGE CREATION TESTS
# ============================================================================

test_that("process_adjacency_matrix includes confidence in edges", {

  # Create adjacency matrix with confidence
  a_d_matrix <- matrix("", nrow = 1, ncol = 1)
  rownames(a_d_matrix) <- "A_1"
  colnames(a_d_matrix) <- "D_1"
  a_d_matrix[1, 1] <- "+strong:4"

  # Process matrix (function signature: adj_matrix, from_prefix, to_prefix, expected_rows, expected_cols)
  edges <- process_adjacency_matrix(
    a_d_matrix,
    "A",
    "D",
    1,
    1
  )

  # Verify edge has confidence
  expect_true("confidence" %in% names(edges))
  expect_equal(edges$confidence[1], 4)
  expect_equal(edges$polarity[1], "+")
  expect_equal(edges$strength[1], "strong")
})

test_that("edges without confidence get default value of 3", {

  # Create adjacency matrix WITHOUT confidence
  a_d_matrix <- matrix("", nrow = 1, ncol = 1)
  rownames(a_d_matrix) <- "A_1"
  colnames(a_d_matrix) <- "D_1"
  a_d_matrix[1, 1] <- "+medium"  # No confidence

  # Process matrix
  edges <- process_adjacency_matrix(
    a_d_matrix,
    "A",
    "D",
    1,
    1
  )

  # Verify default confidence
  expect_equal(edges$confidence[1], 3)
})

# ============================================================================
# FILTER TESTS
# ============================================================================

test_that("filter_by_confidence filters edges correctly", {

  # Create sample edges with varying confidence
  edges <- data.frame(
    from = c("A", "B", "C", "D", "E"),
    to = c("B", "C", "D", "E", "A"),
    polarity = c("+", "-", "+", "-", "+"),
    strength = c("weak", "medium", "strong", "weak", "medium"),
    confidence = c(1, 2, 3, 4, 5),
    stringsAsFactors = FALSE
  )

  # Test 1: Filter for confidence >= 3
  filtered_3 <- filter_by_confidence(edges, 3)
  expect_equal(nrow(filtered_3), 3)
  expect_true(all(filtered_3$confidence >= 3))

  # Test 2: Filter for confidence >= 5 (only highest)
  filtered_5 <- filter_by_confidence(edges, 5)
  expect_equal(nrow(filtered_5), 1)
  expect_equal(filtered_5$confidence[1], 5)

  # Test 3: Filter for confidence >= 1 (all edges)
  filtered_1 <- filter_by_confidence(edges, 1)
  expect_equal(nrow(filtered_1), 5)

  # Test 4: Filter for confidence >= 4
  filtered_4 <- filter_by_confidence(edges, 4)
  expect_equal(nrow(filtered_4), 2)
  expect_true(all(filtered_4$confidence %in% c(4, 5)))
})

test_that("filter_by_confidence handles missing confidence column", {

  # Create edges WITHOUT confidence column
  edges <- data.frame(
    from = c("A", "B"),
    to = c("B", "C"),
    polarity = c("+", "-"),
    strength = c("weak", "medium"),
    stringsAsFactors = FALSE
  )

  # Should return all edges unchanged
  filtered <- filter_by_confidence(edges, 3)
  expect_equal(nrow(filtered), 2)
  expect_equal(filtered, edges)
})

# ============================================================================
# TEMPLATE TESTS
# ============================================================================

test_that("template adjacency matrices contain confidence values", {

  # Load templates
  source("../../modules/template_ses_module.R", local = TRUE)

  # Test Fisheries template - access directly from ses_templates list
  fisheries <- ses_templates$fisheries

  # Check that adjacency matrices have confidence format
  matrices <- fisheries$adjacency_matrices

  # Function to check if value has confidence
  has_confidence <- function(value) {
    if (value == "" || is.na(value)) return(TRUE)  # Empty is OK
    grepl(":", value)
  }

  # Check each matrix
  for (matrix_name in names(matrices)) {
    matrix <- matrices[[matrix_name]]
    if (!is.null(matrix) && length(matrix) > 0) {
      all_have_confidence <- all(sapply(as.vector(matrix), has_confidence))
      expect_true(all_have_confidence,
                  info = paste("Matrix", matrix_name, "should have confidence values"))
    }
  }
})

# ============================================================================
# GRAPH CREATION TESTS
# ============================================================================

test_that("create_igraph_from_data handles optional confidence column", {

  # Create sample nodes
  nodes <- data.frame(
    id = c("A", "B", "C"),
    label = c("Node A", "Node B", "Node C"),
    stringsAsFactors = FALSE
  )

  # Test 1: Edges WITH confidence
  edges_with_conf <- data.frame(
    from = c("A", "B"),
    to = c("B", "C"),
    polarity = c("+", "-"),
    strength = c("strong", "medium"),
    confidence = c(4, 3),
    stringsAsFactors = FALSE
  )

  graph1 <- create_igraph_from_data(nodes, edges_with_conf)
  expect_s3_class(graph1, "igraph")
  expect_true("confidence" %in% igraph::edge_attr_names(graph1))

  # Test 2: Edges WITHOUT confidence (backward compatibility)
  edges_without_conf <- data.frame(
    from = c("A", "B"),
    to = c("B", "C"),
    polarity = c("+", "-"),
    strength = c("strong", "medium"),
    stringsAsFactors = FALSE
  )

  graph2 <- create_igraph_from_data(nodes, edges_without_conf)
  expect_s3_class(graph2, "igraph")
  # Should still create graph successfully
})

# ============================================================================
# EDGE TOOLTIP TESTS
# ============================================================================

test_that("create_edge_tooltip includes confidence information", {

  # Test with different confidence levels
  tooltips <- list(
    create_edge_tooltip("Node A", "Node B", "+", "strong", 1),
    create_edge_tooltip("Node C", "Node D", "-", "medium", 3),
    create_edge_tooltip("Node E", "Node F", "+", "weak", 5)
  )

  # All tooltips should contain confidence info
  expect_true(all(sapply(tooltips, function(t) grepl("Confidence:", t))))

  # Check specific confidence levels
  expect_true(grepl("Very Low", tooltips[[1]]))
  expect_true(grepl("Medium", tooltips[[2]]))
  expect_true(grepl("Very High", tooltips[[3]]))

  # Check numeric values
  expect_true(grepl("1/5", tooltips[[1]]))
  expect_true(grepl("3/5", tooltips[[2]]))
  expect_true(grepl("5/5", tooltips[[3]]))
})

# ============================================================================
# EXPORT TESTS
# ============================================================================

test_that("Excel export includes confidence column for CLD edges", {

  skip_if_not_installed("openxlsx")

  # Create sample project data
  project_data <- list(
    project_id = "TEST001",
    project_name = "Confidence Test",
    created_at = Sys.time(),
    last_modified = Sys.time(),
    data = list(
      metadata = list(
        da_site = "Test Site",
        focal_issue = "Test Issue"
      ),
      cld = list(
        nodes = data.frame(
          id = c("A", "B", "C"),
          label = c("Node A", "Node B", "Node C"),
          stringsAsFactors = FALSE
        ),
        edges = data.frame(
          from = c("A", "B"),
          to = c("B", "C"),
          polarity = c("+", "-"),
          strength = c("strong", "medium"),
          confidence = c(4, 3),
          stringsAsFactors = FALSE
        )
      )
    )
  )

  # Create temporary file
  temp_file <- tempfile(fileext = ".xlsx")

  # Export
  tryCatch({
    export_project_excel(project_data, temp_file)

    # Verify file was created
    expect_true(file.exists(temp_file))

    # Read back the edges sheet
    if (file.exists(temp_file)) {
      wb <- openxlsx::loadWorkbook(temp_file)
      sheet_names <- openxlsx::sheets(wb)

      # Check that CLD_Edges sheet exists
      expect_true("CLD_Edges" %in% sheet_names)

      # Read edges data
      edges_data <- openxlsx::readWorkbook(wb, "CLD_Edges")

      # Verify confidence column exists
      expect_true("confidence" %in% names(edges_data))

      # Verify values
      expect_equal(edges_data$confidence, c(4, 3))
    }

  }, finally = {
    # Clean up
    if (file.exists(temp_file)) {
      unlink(temp_file)
    }
  })
})

# ============================================================================
# INTEGRATION TEST
# ============================================================================

test_that("Full workflow: ISA data -> CLD edges -> Filter -> Export", {

  skip_if_not_installed("openxlsx")

  # Step 1: Create adjacency matrix with varying confidence
  a_d_matrix <- matrix("", nrow = 2, ncol = 2)
  rownames(a_d_matrix) <- c("A_1", "A_2")
  colnames(a_d_matrix) <- c("D_1", "D_2")
  a_d_matrix[1, 1] <- "+strong:5"   # High confidence
  a_d_matrix[2, 2] <- "-weak:2"     # Low confidence

  # Step 2: Generate edges
  edges <- process_adjacency_matrix(
    a_d_matrix,
    "A",
    "D",
    2,
    2
  )

  # Verify edges have confidence
  expect_equal(nrow(edges), 2)
  expect_true("confidence" %in% names(edges))
  expect_equal(edges$confidence, c(5, 2))

  # Step 3: Filter by confidence >= 4
  filtered_edges <- filter_by_confidence(edges, 4)

  # Should only have the high-confidence edge
  expect_equal(nrow(filtered_edges), 1)
  expect_equal(filtered_edges$confidence[1], 5)

  # Step 4: Export and verify
  temp_file <- tempfile(fileext = ".xlsx")

  tryCatch({
    project_data <- list(
      project_id = "INTEGRATION_TEST",
      project_name = "Integration Test",
      created_at = Sys.time(),
      last_modified = Sys.time(),
      data = list(
        metadata = list(),
        cld = list(
          edges = edges
        )
      )
    )

    export_project_excel(project_data, temp_file)
    expect_true(file.exists(temp_file))

  }, finally = {
    if (file.exists(temp_file)) {
      unlink(temp_file)
    }
  })
})
