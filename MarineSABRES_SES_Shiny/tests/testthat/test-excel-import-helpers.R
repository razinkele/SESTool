# tests/testthat/test-excel-import-helpers.R
# Tests for Excel Import Helper Functions
# ==============================================================================

library(testthat)

# Source the file under test
source("../../functions/excel_import_helpers.R", chdir = TRUE)

# ==============================================================================
# Test Data Fixtures
# ==============================================================================

create_test_elements <- function() {
  data.frame(
    Label = c("Climate change", "Fishing activity", "Water pollution",
              "Fish stock health", "Biodiversity", "Food provision"),
    Type = c("Driver", "Activity", "Pressure",
             "Marine Process and Function", "Ecosystem Service", "Good and Benefit"),
    Description = c("Global warming impacts", "Commercial fishing",
                    "Nutrient runoff", "Stock status", "Species richness",
                    "Seafood supply"),
    stringsAsFactors = FALSE
  )
}

create_test_connections <- function() {
  data.frame(
    From = c("Climate change", "Fishing activity", "Water pollution",
             "Fish stock health", "Biodiversity"),
    To = c("Fish stock health", "Fish stock health", "Biodiversity",
           "Biodiversity", "Food provision"),
    Label = c("+", "-", "-", "+", "+"),
    stringsAsFactors = FALSE
  )
}

# ==============================================================================
# Test: find_type_column
# ==============================================================================

test_that("find_type_column finds standard type column", {
  df <- data.frame(
    Label = c("A", "B"),
    Type = c("Driver", "Activity"),
    stringsAsFactors = FALSE
  )

  result <- find_type_column(df)
  expect_equal(result, "Type")
})

test_that("find_type_column finds lowercase type column", {
  df <- data.frame(
    label = c("A", "B"),
    type = c("Driver", "Activity"),
    stringsAsFactors = FALSE
  )

  result <- find_type_column(df)
  expect_equal(result, "type")
})

test_that("find_type_column finds type column with suffix", {
  df <- data.frame(
    Label = c("A", "B"),
    `type...2` = c("Driver", "Activity"),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )

  result <- find_type_column(df)
  expect_equal(result, "type...2")
})

test_that("find_type_column finds category column", {
  df <- data.frame(
    Label = c("A", "B"),
    category = c("Driver", "Activity"),
    stringsAsFactors = FALSE
  )

  result <- find_type_column(df)
  expect_equal(result, "category")
})

test_that("find_type_column returns NULL when no type column exists", {
  df <- data.frame(
    Label = c("A", "B"),
    Name = c("Driver", "Activity"),
    stringsAsFactors = FALSE
  )

  result <- find_type_column(df)
  expect_null(result)
})

test_that("find_type_column handles partial matches", {
  df <- data.frame(
    Label = c("A", "B"),
    element_type = c("Driver", "Activity"),
    stringsAsFactors = FALSE
  )

  result <- find_type_column(df)
  expect_equal(result, "element_type")
})

# ==============================================================================
# Test: convert_excel_to_isa - Input Validation
# ==============================================================================

test_that("convert_excel_to_isa throws error for NULL connections", {
  elements <- create_test_elements()

  expect_error(
    convert_excel_to_isa(elements, NULL),
    "Connections data is NULL"
  )
})

test_that("convert_excel_to_isa throws error for empty connections", {
  elements <- create_test_elements()
  connections <- data.frame(From = character(), To = character(), Label = character())

  expect_error(
    convert_excel_to_isa(elements, connections),
    "empty"
  )
})

test_that("convert_excel_to_isa throws error for missing From column", {
  elements <- create_test_elements()
  connections <- data.frame(
    Source = c("A", "B"),
    To = c("C", "D"),
    Label = c("+", "-")
  )

  expect_error(
    convert_excel_to_isa(elements, connections),
    "From.*To"
  )
})

test_that("convert_excel_to_isa throws error for missing To column", {
  elements <- create_test_elements()
  connections <- data.frame(
    From = c("A", "B"),
    Target = c("C", "D"),
    Label = c("+", "-")
  )

  expect_error(
    convert_excel_to_isa(elements, connections),
    "From.*To"
  )
})

# ==============================================================================
# Test: convert_excel_to_isa - Basic Functionality
# ==============================================================================

test_that("convert_excel_to_isa returns ISA data structure", {
  elements <- create_test_elements()
  connections <- create_test_connections()

  result <- convert_excel_to_isa(elements, connections)

  expect_type(result, "list")
  expect_true("drivers" %in% names(result))
  expect_true("activities" %in% names(result))
  expect_true("pressures" %in% names(result))
  expect_true("marine_processes" %in% names(result))
  expect_true("ecosystem_services" %in% names(result))
  expect_true("goods_benefits" %in% names(result))
  expect_true("responses" %in% names(result))
  expect_true("adjacency_matrices" %in% names(result))
})

test_that("convert_excel_to_isa correctly categorizes drivers", {
  elements <- create_test_elements()
  connections <- create_test_connections()

  result <- convert_excel_to_isa(elements, connections)

  expect_true(!is.null(result$drivers))
  expect_equal(nrow(result$drivers), 1)
  expect_equal(result$drivers$Name[1], "Climate change")
})

test_that("convert_excel_to_isa correctly categorizes activities", {
  elements <- create_test_elements()
  connections <- create_test_connections()

  result <- convert_excel_to_isa(elements, connections)

  expect_true(!is.null(result$activities))
  expect_equal(nrow(result$activities), 1)
  expect_equal(result$activities$Name[1], "Fishing activity")
})

test_that("convert_excel_to_isa correctly categorizes pressures", {
  elements <- create_test_elements()
  connections <- create_test_connections()

  result <- convert_excel_to_isa(elements, connections)

  expect_true(!is.null(result$pressures))
  expect_equal(nrow(result$pressures), 1)
  expect_equal(result$pressures$Name[1], "Water pollution")
})

test_that("convert_excel_to_isa correctly categorizes marine processes", {
  elements <- create_test_elements()
  connections <- create_test_connections()

  result <- convert_excel_to_isa(elements, connections)

  expect_true(!is.null(result$marine_processes))
  expect_equal(nrow(result$marine_processes), 1)
  expect_equal(result$marine_processes$Name[1], "Fish stock health")
})

test_that("convert_excel_to_isa correctly categorizes ecosystem services", {
  elements <- create_test_elements()
  connections <- create_test_connections()

  result <- convert_excel_to_isa(elements, connections)

  expect_true(!is.null(result$ecosystem_services))
  expect_equal(nrow(result$ecosystem_services), 1)
  expect_equal(result$ecosystem_services$Name[1], "Biodiversity")
})

test_that("convert_excel_to_isa correctly categorizes goods and benefits", {
  elements <- create_test_elements()
  connections <- create_test_connections()

  result <- convert_excel_to_isa(elements, connections)

  expect_true(!is.null(result$goods_benefits))
  expect_equal(nrow(result$goods_benefits), 1)
  expect_equal(result$goods_benefits$Name[1], "Food provision")
})

# ==============================================================================
# Test: convert_excel_to_isa - Adjacency Matrices
# ==============================================================================

test_that("convert_excel_to_isa creates adjacency matrices", {
  elements <- create_test_elements()
  connections <- create_test_connections()

  result <- convert_excel_to_isa(elements, connections)

  expect_true(length(result$adjacency_matrices) > 0)
})

test_that("adjacency matrices have correct dimensions", {
  elements <- create_test_elements()
  connections <- create_test_connections()

  result <- convert_excel_to_isa(elements, connections)

  # Check that matrices are properly dimensioned
  for (mat_name in names(result$adjacency_matrices)) {
    mat <- result$adjacency_matrices[[mat_name]]
    expect_true(is.matrix(mat))
    expect_true(nrow(mat) > 0)
    expect_true(ncol(mat) > 0)
  }
})

test_that("adjacency matrices contain polarity values", {
  elements <- create_test_elements()
  connections <- create_test_connections()

  result <- convert_excel_to_isa(elements, connections)

  # At least one matrix should have connections
  has_connections <- FALSE
  for (mat in result$adjacency_matrices) {
    if (any(mat != "")) {
      has_connections <- TRUE
      # Check format: polarity + strength + confidence
      non_empty <- mat[mat != ""]
      expect_true(all(grepl("^[+-](weak|medium|strong):[1-5]$", non_empty)))
      break
    }
  }
  expect_true(has_connections)
})

# ==============================================================================
# Test: convert_excel_to_isa - Edge Cases
# ==============================================================================

test_that("convert_excel_to_isa handles whitespace in names", {
  elements <- data.frame(
    Label = c("  Climate change  ", "Fishing activity "),
    Type = c("Driver", "Activity"),
    stringsAsFactors = FALSE
  )
  connections <- data.frame(
    From = c(" Climate change", "Fishing activity"),
    To = c("Fishing activity", "Climate change"),
    Label = c("+", "-"),
    stringsAsFactors = FALSE
  )

  result <- convert_excel_to_isa(elements, connections)

  expect_true(!is.null(result))
  expect_type(result, "list")
})

test_that("convert_excel_to_isa handles non-breaking spaces", {
  elements <- data.frame(
    Label = c("Climate\u00A0change", "Fishing activity"),
    Type = c("Driver", "Activity"),
    stringsAsFactors = FALSE
  )
  connections <- data.frame(
    From = c("Climate change"),
    To = c("Fishing activity"),
    Label = c("+"),
    stringsAsFactors = FALSE
  )

  result <- convert_excel_to_isa(elements, connections)

  expect_true(!is.null(result))
  expect_type(result, "list")
})

test_that("convert_excel_to_isa handles missing element types gracefully", {
  elements <- data.frame(
    Label = c("Unknown element", "Fishing activity"),
    Type = c(NA, "Activity"),
    stringsAsFactors = FALSE
  )
  connections <- data.frame(
    From = c("Unknown element"),
    To = c("Fishing activity"),
    Label = c("+"),
    stringsAsFactors = FALSE
  )

  # Should not throw error
  result <- convert_excel_to_isa(elements, connections)
  expect_type(result, "list")
})

test_that("convert_excel_to_isa handles case-insensitive type matching", {
  elements <- data.frame(
    Label = c("Climate change", "Fishing activity"),
    Type = c("DRIVER", "activity"),  # Different cases
    stringsAsFactors = FALSE
  )
  connections <- data.frame(
    From = c("Climate change"),
    To = c("Fishing activity"),
    Label = c("+"),
    stringsAsFactors = FALSE
  )

  result <- convert_excel_to_isa(elements, connections)

  # Both should be categorized despite case differences
  expect_true(!is.null(result$drivers) && nrow(result$drivers) == 1)
  expect_true(!is.null(result$activities) && nrow(result$activities) == 1)
})

test_that("convert_excel_to_isa works without elements sheet", {
  connections <- data.frame(
    From = c("Element A", "Element B"),
    To = c("Element B", "Element C"),
    Label = c("+", "-"),
    stringsAsFactors = FALSE
  )

  # Should work even without elements (will try to infer types)
  result <- convert_excel_to_isa(NULL, connections)
  expect_type(result, "list")
})

# ==============================================================================
# Test: Polarity Handling
# ==============================================================================

test_that("positive polarity is correctly parsed", {
  elements <- data.frame(
    Label = c("A", "B"),
    Type = c("Driver", "Activity"),
    stringsAsFactors = FALSE
  )
  connections <- data.frame(
    From = c("A"),
    To = c("B"),
    Label = c("+"),
    stringsAsFactors = FALSE
  )

  result <- convert_excel_to_isa(elements, connections)

  # Check adjacency matrix contains positive polarity
  if (length(result$adjacency_matrices) > 0) {
    mat <- result$adjacency_matrices[[1]]
    non_empty <- mat[mat != ""]
    if (length(non_empty) > 0) {
      expect_true(grepl("^\\+", non_empty[1]))
    }
  }
})

test_that("negative polarity is correctly parsed", {
  elements <- data.frame(
    Label = c("A", "B"),
    Type = c("Driver", "Activity"),
    stringsAsFactors = FALSE
  )
  connections <- data.frame(
    From = c("A"),
    To = c("B"),
    Label = c("-"),
    stringsAsFactors = FALSE
  )

  result <- convert_excel_to_isa(elements, connections)

  # Check adjacency matrix contains negative polarity
  if (length(result$adjacency_matrices) > 0) {
    mat <- result$adjacency_matrices[[1]]
    non_empty <- mat[mat != ""]
    if (length(non_empty) > 0) {
      expect_true(grepl("^-", non_empty[1]))
    }
  }
})

test_that("missing polarity defaults to positive", {
  elements <- data.frame(
    Label = c("A", "B"),
    Type = c("Driver", "Activity"),
    stringsAsFactors = FALSE
  )
  connections <- data.frame(
    From = c("A"),
    To = c("B"),
    Label = c(NA),
    stringsAsFactors = FALSE
  )

  result <- convert_excel_to_isa(elements, connections)

  # Check adjacency matrix defaults to positive
  if (length(result$adjacency_matrices) > 0) {
    mat <- result$adjacency_matrices[[1]]
    non_empty <- mat[mat != ""]
    if (length(non_empty) > 0) {
      expect_true(grepl("^\\+", non_empty[1]))
    }
  }
})

# ==============================================================================
# Test: Type Mapping Variations
# ==============================================================================

test_that("alternative type names are mapped correctly", {
  elements <- data.frame(
    Label = c("A", "B", "C", "D"),
    Type = c("State", "State Change", "Impact", "Welfare"),
    stringsAsFactors = FALSE
  )
  connections <- data.frame(
    From = c("A", "B", "C"),
    To = c("B", "C", "D"),
    Label = c("+", "+", "+"),
    stringsAsFactors = FALSE
  )

  result <- convert_excel_to_isa(elements, connections)

  # State and State Change should map to marine_processes
  expect_true(!is.null(result$marine_processes))
  expect_true(nrow(result$marine_processes) >= 2)

  # Impact should map to ecosystem_services
  expect_true(!is.null(result$ecosystem_services))

  # Welfare should map to goods_benefits
  expect_true(!is.null(result$goods_benefits))
})

test_that("Response and Measure types are handled", {
  elements <- data.frame(
    Label = c("Policy A", "Measure B"),
    Type = c("Response", "Measure"),
    stringsAsFactors = FALSE
  )
  connections <- data.frame(
    From = c("Policy A"),
    To = c("Measure B"),
    Label = c("+"),
    stringsAsFactors = FALSE
  )

  result <- convert_excel_to_isa(elements, connections)

  # Both should map to responses
  expect_true(!is.null(result$responses))
  expect_true(nrow(result$responses) >= 1)
})

# ==============================================================================
# Test: Strength and Confidence
# ==============================================================================

test_that("strength values are extracted when present", {
  elements <- data.frame(
    Label = c("A", "B"),
    Type = c("Driver", "Activity"),
    stringsAsFactors = FALSE
  )
  connections <- data.frame(
    From = c("A"),
    To = c("B"),
    Label = c("+"),
    Strength = c("strong"),
    stringsAsFactors = FALSE
  )

  result <- convert_excel_to_isa(elements, connections)

  if (length(result$adjacency_matrices) > 0) {
    mat <- result$adjacency_matrices[[1]]
    non_empty <- mat[mat != ""]
    if (length(non_empty) > 0) {
      expect_true(grepl("strong", non_empty[1]))
    }
  }
})

test_that("confidence values are extracted when present", {
  elements <- data.frame(
    Label = c("A", "B"),
    Type = c("Driver", "Activity"),
    stringsAsFactors = FALSE
  )
  connections <- data.frame(
    From = c("A"),
    To = c("B"),
    Label = c("+"),
    Confidence = c(5),
    stringsAsFactors = FALSE
  )

  result <- convert_excel_to_isa(elements, connections)

  if (length(result$adjacency_matrices) > 0) {
    mat <- result$adjacency_matrices[[1]]
    non_empty <- mat[mat != ""]
    if (length(non_empty) > 0) {
      expect_true(grepl(":5$", non_empty[1]))
    }
  }
})

# ==============================================================================
# Test: build_adjacency_matrices_from_connections_v2
# ==============================================================================

test_that("build_adjacency_matrices_from_connections_v2 creates proper matrices", {
  node_types <- data.frame(
    Name = c("Driver A", "Activity B"),
    type = c("Driver", "Activity"),
    source = c("test", "test"),
    stringsAsFactors = FALSE
  )

  connections <- data.frame(
    From = c("Driver A"),
    To = c("Activity B"),
    Label = c("+"),
    stringsAsFactors = FALSE
  )

  type_mapping <- list(
    "Driver" = "drivers",
    "Activity" = "activities"
  )

  isa_data <- list(
    drivers = data.frame(Name = "Driver A", stringsAsFactors = FALSE),
    activities = data.frame(Name = "Activity B", stringsAsFactors = FALSE)
  )

  result <- build_adjacency_matrices_from_connections_v2(
    node_types, connections, type_mapping, isa_data
  )

  expect_type(result, "list")
  expect_true(length(result) > 0)

  # Should have d_a matrix (drivers to activities)
  expect_true("d_a" %in% names(result))
})

cat("\n", strrep("=", 70), "\n", sep = "")
cat("Excel Import Helpers Tests Complete\n")
cat(strrep("=", 70), "\n")
