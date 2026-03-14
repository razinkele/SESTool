# test-p0-fixes.R
# Tests for P0 critical fixes implemented 2026-03-06
#
# P0 Fixes:
# 1. Atomic transaction wrapper for state management
# 2. Cross-reference validation for adjacency matrices
# 3. ML dimension validation and model version detection
# 4. Critical module load failures - fail fast

# ============================================================================
# Test Setup
# ============================================================================

test_that("setup: required functions exist", {
  # Transaction wrapper
  expect_true(exists("with_project_transaction", mode = "function"))
  expect_true(exists("with_project_transaction_batch", mode = "function"))
  expect_true(exists("create_isa_modifier", mode = "function"))

  # Cross-reference validation
  expect_true(exists("validate_cross_references", mode = "function"))
  expect_true(exists("repair_adjacency_matrices", mode = "function"))
})

# ============================================================================
# 1. Transaction Wrapper Tests
# ============================================================================

context("P0 Fix 1: Atomic Transaction Wrapper")

test_that("with_project_transaction requires function parameter", {
  mock_project_data <- function() { list(test = TRUE) }

  result <- with_project_transaction(mock_project_data, NULL, "not a function")
  expect_false(result$success)
  expect_true(grepl("function", result$error, ignore.case = TRUE))
})

test_that("with_project_transaction commits successful operations", {
  # Create mock reactive-like function
  state <- list(value = 1, last_modified = Sys.time())
  mock_project_data <- function(new_state = NULL) {
    if (!is.null(new_state)) {
      state <<- new_state
    }
    return(state)
  }

  # Operation that modifies state
  result <- with_project_transaction(
    mock_project_data,
    event_bus = NULL,
    operation = function(s) {
      s$value <- s$value + 1
      return(s)
    },
    emit_change = FALSE
  )

  expect_true(result$success)
  expect_null(result$error)
  expect_equal(mock_project_data()$value, 2)
})

test_that("with_project_transaction rolls back on error", {
  # Create mock reactive-like function
  state <- list(value = 1, last_modified = Sys.time())
  mock_project_data <- function(new_state = NULL) {
    if (!is.null(new_state)) {
      state <<- new_state
    }
    return(state)
  }

  # Operation that fails
  result <- with_project_transaction(
    mock_project_data,
    event_bus = NULL,
    operation = function(s) {
      s$value <- s$value + 1
      stop("Simulated error")
    },
    emit_change = FALSE,
    silent = TRUE
  )

  expect_false(result$success)
  expect_true(grepl("Simulated error", result$error))
  # State should be unchanged (rolled back)
  expect_equal(mock_project_data()$value, 1)
})

test_that("with_project_transaction_batch executes multiple operations", {
  state <- list(value = 0, last_modified = Sys.time())
  mock_project_data <- function(new_state = NULL) {
    if (!is.null(new_state)) {
      state <<- new_state
    }
    return(state)
  }

  operations <- list(
    function(s) { s$value <- s$value + 1; s },
    function(s) { s$value <- s$value + 2; s },
    function(s) { s$value <- s$value + 3; s }
  )

  result <- with_project_transaction_batch(mock_project_data, NULL, operations)

  expect_true(result$success)
  expect_equal(mock_project_data()$value, 6)  # 0 + 1 + 2 + 3
})

test_that("with_project_transaction_batch rolls back all on single failure", {
  state <- list(value = 0, last_modified = Sys.time())
  mock_project_data <- function(new_state = NULL) {
    if (!is.null(new_state)) {
      state <<- new_state
    }
    return(state)
  }

  operations <- list(
    function(s) { s$value <- s$value + 1; s },
    function(s) { stop("Error in operation 2") },
    function(s) { s$value <- s$value + 3; s }
  )

  # Mock shiny::showNotification to avoid session-related errors in test
  with_mocked_bindings({
    result <- with_project_transaction_batch(mock_project_data, NULL, operations)

    expect_false(result$success)
    expect_equal(mock_project_data()$value, 0)  # Should be unchanged
  }, showNotification = function(...) invisible(NULL), .package = "shiny")
})

test_that("create_isa_modifier returns valid functions", {
  add_driver <- create_isa_modifier("drivers", "add")
  expect_true(is.function(add_driver))

  update_activity <- create_isa_modifier("activities", "update")
  expect_true(is.function(update_activity))

  delete_pressure <- create_isa_modifier("pressures", "delete")
  expect_true(is.function(delete_pressure))
})

test_that("create_isa_modifier rejects invalid element types", {
  expect_error(create_isa_modifier("invalid_type", "add"))
})

# ============================================================================
# 2. Cross-Reference Validation Tests
# ============================================================================

context("P0 Fix 2: Cross-Reference Validation")

test_that("validate_cross_references returns empty for valid data", {
  # Create valid ISA data structure
  isa_data <- list(
    drivers = data.frame(id = c("D001", "D002"), name = c("Driver 1", "Driver 2")),
    activities = data.frame(id = c("A001", "A002"), name = c("Activity 1", "Activity 2")),
    pressures = data.frame(id = character(0), name = character(0)),
    marine_processes = data.frame(id = character(0), name = character(0)),
    ecosystem_services = data.frame(id = character(0), name = character(0)),
    goods_benefits = data.frame(id = character(0), name = character(0)),
    responses = data.frame(id = character(0), name = character(0)),
    adjacency_matrices = list(
      d_a = matrix("", nrow = 2, ncol = 2, dimnames = list(c("D001", "D002"), c("A001", "A002")))
    )
  )

  errors <- validate_cross_references(isa_data)
  expect_equal(length(errors), 0)
})

test_that("validate_cross_references detects orphaned row references", {
  isa_data <- list(
    drivers = data.frame(id = c("D001"), name = c("Driver 1")),  # Only D001 exists
    activities = data.frame(id = c("A001", "A002"), name = c("Activity 1", "Activity 2")),
    pressures = data.frame(id = character(0), name = character(0)),
    marine_processes = data.frame(id = character(0), name = character(0)),
    ecosystem_services = data.frame(id = character(0), name = character(0)),
    goods_benefits = data.frame(id = character(0), name = character(0)),
    responses = data.frame(id = character(0), name = character(0)),
    adjacency_matrices = list(
      d_a = matrix("", nrow = 2, ncol = 2, dimnames = list(c("D001", "D002"), c("A001", "A002")))  # D002 is orphaned
    )
  )

  errors <- validate_cross_references(isa_data)
  expect_true(length(errors) > 0)
  expect_true(any(grepl("orphaned", errors, ignore.case = TRUE)))
  expect_true(any(grepl("D002", errors)))
})

test_that("validate_cross_references detects orphaned column references", {
  isa_data <- list(
    drivers = data.frame(id = c("D001", "D002"), name = c("Driver 1", "Driver 2")),
    activities = data.frame(id = c("A001"), name = c("Activity 1")),  # Only A001 exists
    pressures = data.frame(id = character(0), name = character(0)),
    marine_processes = data.frame(id = character(0), name = character(0)),
    ecosystem_services = data.frame(id = character(0), name = character(0)),
    goods_benefits = data.frame(id = character(0), name = character(0)),
    responses = data.frame(id = character(0), name = character(0)),
    adjacency_matrices = list(
      d_a = matrix("", nrow = 2, ncol = 2, dimnames = list(c("D001", "D002"), c("A001", "A002")))  # A002 is orphaned
    )
  )

  errors <- validate_cross_references(isa_data)
  expect_true(length(errors) > 0)
  expect_true(any(grepl("A002", errors)))
})

test_that("repair_adjacency_matrices removes orphaned references", {
  isa_data <- list(
    drivers = data.frame(id = c("D001"), name = c("Driver 1")),
    activities = data.frame(id = c("A001"), name = c("Activity 1")),
    pressures = data.frame(id = character(0), name = character(0)),
    marine_processes = data.frame(id = character(0), name = character(0)),
    ecosystem_services = data.frame(id = character(0), name = character(0)),
    goods_benefits = data.frame(id = character(0), name = character(0)),
    responses = data.frame(id = character(0), name = character(0)),
    adjacency_matrices = list(
      d_a = matrix(c("+", "-", "", ""), nrow = 2, ncol = 2,
                   dimnames = list(c("D001", "D002"), c("A001", "A002")))  # D002, A002 orphaned
    )
  )

  # Verify orphans exist before repair
  errors_before <- validate_cross_references(isa_data)
  expect_true(length(errors_before) > 0)

  # Repair
  repaired_data <- repair_adjacency_matrices(isa_data)

  # Verify no orphans after repair
  errors_after <- validate_cross_references(repaired_data)
  expect_equal(length(errors_after), 0)

  # Verify matrix was reduced correctly
  expect_equal(nrow(repaired_data$adjacency_matrices$d_a), 1)
  expect_equal(ncol(repaired_data$adjacency_matrices$d_a), 1)
  expect_equal(rownames(repaired_data$adjacency_matrices$d_a), "D001")
  expect_equal(colnames(repaired_data$adjacency_matrices$d_a), "A001")
})

test_that("validate_cross_references handles NULL input gracefully", {
  errors <- validate_cross_references(NULL)
  expect_equal(length(errors), 0)
})

test_that("repair_adjacency_matrices handles NULL input gracefully", {
  result <- repair_adjacency_matrices(NULL)
  expect_null(result)
})

# ============================================================================
# 3. ML Dimension Validation Tests
# ============================================================================

context("P0 Fix 3: ML Dimension Validation")

test_that("get_ml_model_input_dim returns default when no model loaded", {
  skip_if_not(exists("get_ml_model_input_dim", mode = "function"),
              "ML inference functions not available")

  # Ensure no model is loaded
  if (exists("unload_ml_model", mode = "function")) {
    unload_ml_model()
  }

  dim <- get_ml_model_input_dim()
  expect_true(is.numeric(dim))
  expect_equal(dim, 358)  # Default Phase 1 dimension
})

test_that("ML_MODEL_CONFIGS contains expected configurations", {
  skip_if_not(exists("ML_MODEL_CONFIGS"),
              "ML_MODEL_CONFIGS not available")

  expect_true("phase1" %in% names(ML_MODEL_CONFIGS))
  expect_true("phase2" %in% names(ML_MODEL_CONFIGS))

  expect_equal(ML_MODEL_CONFIGS$phase1$input_dim, 358)
  expect_equal(ML_MODEL_CONFIGS$phase2$input_dim, 314)
})

test_that("get_ml_model_metadata returns metadata structure when no model loaded", {
  skip_if_not(exists("get_ml_model_metadata", mode = "function"),
              "ML inference functions not available")

  if (exists("unload_ml_model", mode = "function")) {
    unload_ml_model()
  }

  metadata <- get_ml_model_metadata()
  # Function may return NULL or an empty/default metadata list depending on implementation
  expect_true(is.null(metadata) || is.list(metadata),
              info = "get_ml_model_metadata should return NULL or a list")
})

# ============================================================================
# 4. Critical Module Load Tests (can only be tested indirectly)
# ============================================================================

context("P0 Fix 4: Critical Module Configuration")

test_that("CRITICAL_MODULES is defined and non-empty", {
  skip_if_not(exists("CRITICAL_MODULES"),
              "CRITICAL_MODULES not defined (run from app.R context)")

  expect_true(is.character(CRITICAL_MODULES))
  expect_true(length(CRITICAL_MODULES) > 0)
})

test_that("OPTIONAL_MODULES is defined and non-empty", {
  skip_if_not(exists("OPTIONAL_MODULES"),
              "OPTIONAL_MODULES not defined (run from app.R context)")

  expect_true(is.character(OPTIONAL_MODULES))
  expect_true(length(OPTIONAL_MODULES) > 0)
})

test_that("Critical modules include essential functionality", {
  skip_if_not(exists("CRITICAL_MODULES"),
              "CRITICAL_MODULES not defined")

  # Check that key modules are marked as critical
  critical_basenames <- basename(CRITICAL_MODULES)

  expect_true("entry_point_module.R" %in% critical_basenames)
  expect_true("isa_data_entry_module.R" %in% critical_basenames)
  expect_true("cld_visualization_module.R" %in% critical_basenames)
})

# ============================================================================
# Integration Tests
# ============================================================================

context("P0 Fixes: Integration")

test_that("Transaction wrapper works with ISA data modifications", {
  # Create a realistic project data structure
  state <- create_empty_project("Test Project")
  mock_project_data <- function(new_state = NULL) {
    if (!is.null(new_state)) {
      state <<- new_state
    }
    return(state)
  }

  # Add a driver element using transaction
  new_driver <- data.frame(
    id = "D001",
    name = "Population Growth",
    indicator = "Growth rate",
    indicator_unit = "%",
    data_source = "Census",
    time_horizon_start = as.Date("2020-01-01"),
    time_horizon_end = as.Date("2025-12-31"),
    baseline_value = 1.2,
    current_value = 1.5,
    notes = "Test driver",
    needs_category = "Economic",
    trends = "Increasing"
    
  )

  result <- with_project_transaction(
    mock_project_data,
    event_bus = NULL,
    operation = function(s) {
      s$data$isa_data$drivers <- rbind(s$data$isa_data$drivers, new_driver)
      return(s)
    },
    emit_change = FALSE
  )

  expect_true(result$success)
  expect_equal(nrow(mock_project_data()$data$isa_data$drivers), 1)
  expect_equal(mock_project_data()$data$isa_data$drivers$id[1], "D001")
})

test_that("Cross-reference validation integrates with validation pipeline", {
  # Create project with potential issues
  isa_data <- list(
    drivers = data.frame(id = c("D001"), name = c("Driver 1"), indicator = c("Ind1")),
    activities = data.frame(id = c("A001"), name = c("Activity 1"), indicator = c("Ind1")),
    pressures = create_empty_element_df("Pressures"),
    marine_processes = create_empty_element_df("Marine Processes & Functioning"),
    ecosystem_services = create_empty_element_df("Ecosystem Services"),
    goods_benefits = create_empty_element_df("Goods & Benefits"),
    responses = create_empty_element_df("Responses"),
    adjacency_matrices = list(
      d_a = matrix("+", nrow = 1, ncol = 1, dimnames = list("D001", "A001"))
    )
  )

  # This should pass validation
  errors <- validate_isa_structure(isa_data)
  cross_ref_errors <- validate_cross_references(isa_data)

  expect_equal(length(errors), 0)
  expect_equal(length(cross_ref_errors), 0)
})
