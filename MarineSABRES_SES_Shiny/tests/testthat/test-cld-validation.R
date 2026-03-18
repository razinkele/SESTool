# tests/testthat/test-cld-validation.R
# Tests for CLD Validation Functions
# ==============================================================================

library(testthat)

source("../../functions/cld_validation.R", chdir = TRUE)

# ==============================================================================
# Test Data Fixtures
# ==============================================================================

create_valid_project_data <- function() {
  list(
    data = list(
      cld = list(
        nodes = data.frame(
          id = c("n1", "n2", "n3"),
          label = c("Climate change", "Fish stocks", "Fishing"),
          group = c("Driver", "State", "Activity"),
          stringsAsFactors = FALSE
        ),
        edges = data.frame(
          from = c("n1", "n3"),
          to = c("n2", "n2"),
          polarity = c("-", "-"),
          stringsAsFactors = FALSE
        )
      ),
      isa_data = list(
        drivers = data.frame(Name = "Climate change", stringsAsFactors = FALSE),
        activities = data.frame(Name = "Fishing", stringsAsFactors = FALSE),
        pressures = data.frame(Name = character(), stringsAsFactors = FALSE),
        marine_processes = data.frame(Name = character(), stringsAsFactors = FALSE),
        ecosystem_services = data.frame(Name = character(), stringsAsFactors = FALSE),
        goods_benefits = data.frame(Name = character(), stringsAsFactors = FALSE),
        responses = data.frame(Name = character(), stringsAsFactors = FALSE)
      )
    )
  )
}

# ==============================================================================
# Test: has_valid_cld
# ==============================================================================

test_that("has_valid_cld returns TRUE for valid project data", {
  pd <- create_valid_project_data()
  expect_true(has_valid_cld(pd))
})

test_that("has_valid_cld returns FALSE for NULL input", {
  expect_false(has_valid_cld(NULL))
})

test_that("has_valid_cld returns FALSE when data is NULL", {
  expect_false(has_valid_cld(list(data = NULL)))
})

test_that("has_valid_cld returns FALSE when cld is NULL", {
  expect_false(has_valid_cld(list(data = list(cld = NULL))))
})

test_that("has_valid_cld returns FALSE when nodes are empty", {
  pd <- create_valid_project_data()
  pd$data$cld$nodes <- data.frame(id = character(), label = character(),
                                   stringsAsFactors = FALSE)
  expect_false(has_valid_cld(pd))
})

test_that("has_valid_cld returns FALSE when edges are empty", {
  pd <- create_valid_project_data()
  pd$data$cld$edges <- data.frame(from = character(), to = character(),
                                   stringsAsFactors = FALSE)
  expect_false(has_valid_cld(pd))
})

test_that("has_valid_cld returns FALSE when nodes are NULL", {
  pd <- create_valid_project_data()
  pd$data$cld$nodes <- NULL
  expect_false(has_valid_cld(pd))
})

# ==============================================================================
# Test: has_valid_isa
# ==============================================================================

test_that("has_valid_isa returns TRUE when at least one element type has data", {
  pd <- create_valid_project_data()
  expect_true(has_valid_isa(pd))
})

test_that("has_valid_isa returns FALSE for NULL input", {
  expect_false(has_valid_isa(NULL))
})

test_that("has_valid_isa returns FALSE when isa_data is NULL", {
  pd <- list(data = list(isa_data = NULL))
  expect_false(has_valid_isa(pd))
})

test_that("has_valid_isa returns FALSE when all element types are empty", {
  pd <- list(
    data = list(
      isa_data = list(
        drivers = data.frame(Name = character(), stringsAsFactors = FALSE),
        activities = data.frame(Name = character(), stringsAsFactors = FALSE),
        pressures = data.frame(Name = character(), stringsAsFactors = FALSE),
        marine_processes = data.frame(Name = character(), stringsAsFactors = FALSE),
        ecosystem_services = data.frame(Name = character(), stringsAsFactors = FALSE),
        goods_benefits = data.frame(Name = character(), stringsAsFactors = FALSE),
        responses = data.frame(Name = character(), stringsAsFactors = FALSE)
      )
    )
  )
  expect_false(has_valid_isa(pd))
})

# ==============================================================================
# Test: validate_cld_nodes
# ==============================================================================

test_that("validate_cld_nodes passes for valid nodes", {
  nodes <- data.frame(id = c("n1", "n2"), label = c("A", "B"),
                      stringsAsFactors = FALSE)
  result <- validate_cld_nodes(nodes)
  expect_true(result$is_valid)
  expect_equal(length(result$errors), 0)
})

test_that("validate_cld_nodes fails for NULL input", {
  result <- validate_cld_nodes(NULL)
  expect_false(result$is_valid)
  expect_true(length(result$errors) > 0)
})

test_that("validate_cld_nodes fails for non-dataframe input", {
  result <- validate_cld_nodes(list(id = "n1"))
  expect_false(result$is_valid)
})

test_that("validate_cld_nodes fails for empty dataframe", {
  empty_nodes <- data.frame(id = character(), label = character(),
                            stringsAsFactors = FALSE)
  result <- validate_cld_nodes(empty_nodes)
  expect_false(result$is_valid)
  expect_true(any(grepl("empty", result$errors)))
})

test_that("validate_cld_nodes fails when required columns are missing", {
  nodes <- data.frame(name = c("A", "B"), stringsAsFactors = FALSE)
  result <- validate_cld_nodes(nodes)
  expect_false(result$is_valid)
  expect_true(any(grepl("Missing required columns", result$errors)))
})

test_that("validate_cld_nodes detects duplicate IDs", {
  nodes <- data.frame(id = c("n1", "n1", "n2"), label = c("A", "A2", "B"),
                      stringsAsFactors = FALSE)
  result <- validate_cld_nodes(nodes)
  expect_false(result$is_valid)
  expect_true(any(grepl("Duplicate", result$errors)))
})

test_that("validate_cld_nodes passes when id column missing but label present", {
  # Missing 'id' should be reported
  nodes <- data.frame(label = c("A", "B"), stringsAsFactors = FALSE)
  result <- validate_cld_nodes(nodes)
  expect_false(result$is_valid)
  expect_true(any(grepl("id", result$errors)))
})

# ==============================================================================
# Test: validate_cld_edges
# ==============================================================================

test_that("validate_cld_edges passes for valid edges", {
  edges <- data.frame(from = c("n1", "n2"), to = c("n2", "n3"),
                      stringsAsFactors = FALSE)
  result <- validate_cld_edges(edges)
  expect_true(result$is_valid)
  expect_equal(length(result$errors), 0)
})

test_that("validate_cld_edges passes for empty edges", {
  edges <- data.frame(from = character(), to = character(),
                      stringsAsFactors = FALSE)
  result <- validate_cld_edges(edges)
  expect_true(result$is_valid)
})

test_that("validate_cld_edges fails for NULL input", {
  result <- validate_cld_edges(NULL)
  expect_false(result$is_valid)
})

test_that("validate_cld_edges fails for non-dataframe", {
  result <- validate_cld_edges("not a dataframe")
  expect_false(result$is_valid)
})

test_that("validate_cld_edges fails when required columns missing", {
  edges <- data.frame(source = "n1", target = "n2", stringsAsFactors = FALSE)
  result <- validate_cld_edges(edges)
  expect_false(result$is_valid)
  expect_true(any(grepl("Missing required columns", result$errors)))
})

test_that("validate_cld_edges detects references to non-existent nodes", {
  edges <- data.frame(from = c("n1", "n2"), to = c("n2", "n99"),
                      stringsAsFactors = FALSE)
  valid_ids <- c("n1", "n2", "n3")
  result <- validate_cld_edges(edges, valid_node_ids = valid_ids)
  expect_false(result$is_valid)
  expect_true(any(grepl("non-existent", result$errors)))
})

test_that("validate_cld_edges passes when all references are valid", {
  edges <- data.frame(from = c("n1", "n2"), to = c("n2", "n3"),
                      stringsAsFactors = FALSE)
  valid_ids <- c("n1", "n2", "n3")
  result <- validate_cld_edges(edges, valid_node_ids = valid_ids)
  expect_true(result$is_valid)
})

test_that("validate_cld_edges skips node validation without valid_node_ids", {
  edges <- data.frame(from = c("n1"), to = c("n99"),
                      stringsAsFactors = FALSE)
  result <- validate_cld_edges(edges)
  # Without valid_node_ids, should still pass

  expect_true(result$is_valid)
})

# ==============================================================================
# Test: get_validated_cld
# ==============================================================================

test_that("get_validated_cld returns nodes and edges for valid data", {
  pd <- create_valid_project_data()
  result <- get_validated_cld(pd)
  expect_true(is.list(result))
  expect_true("nodes" %in% names(result))
  expect_true("edges" %in% names(result))
  expect_equal(nrow(result$nodes), 3)
})

test_that("get_validated_cld returns NULL for invalid data", {
  expect_null(get_validated_cld(NULL))
  expect_null(get_validated_cld(list(data = NULL)))
})

test_that("get_validated_cld returns NULL for empty CLD", {
  pd <- create_valid_project_data()
  pd$data$cld$nodes <- data.frame(id = character(), label = character(),
                                   stringsAsFactors = FALSE)
  expect_null(get_validated_cld(pd))
})

# ==============================================================================
# Test: count_elements_by_type
# ==============================================================================

test_that("count_elements_by_type counts groups correctly", {
  nodes <- data.frame(
    id = c("n1", "n2", "n3", "n4"),
    label = c("A", "B", "C", "D"),
    group = c("Driver", "Activity", "Driver", "State"),
    stringsAsFactors = FALSE
  )
  result <- count_elements_by_type(nodes)
  expect_equal(as.integer(result["Driver"]), 2)
  expect_equal(as.integer(result["Activity"]), 1)
  expect_equal(as.integer(result["State"]), 1)
})

test_that("count_elements_by_type returns empty for NULL input", {
  result <- count_elements_by_type(NULL)
  expect_equal(length(result), 0)
})

test_that("count_elements_by_type returns empty when group column missing", {
  nodes <- data.frame(id = c("n1"), label = c("A"), stringsAsFactors = FALSE)
  result <- count_elements_by_type(nodes)
  expect_equal(length(result), 0)
})

test_that("count_elements_by_type handles single-type nodes", {
  nodes <- data.frame(
    id = c("n1", "n2"),
    label = c("A", "B"),
    group = c("Driver", "Driver"),
    stringsAsFactors = FALSE
  )
  result <- count_elements_by_type(nodes)
  expect_equal(as.integer(result["Driver"]), 2)
  expect_equal(length(result), 1)
})
