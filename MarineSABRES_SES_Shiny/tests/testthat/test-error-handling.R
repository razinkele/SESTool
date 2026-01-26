# test-error-handling.R
# Comprehensive tests for functions/error_handling.R
# Tests validation guards, safe wrappers, and logging functions

# ============================================================================
# SETUP
# ============================================================================

# Source error handling if not already available
if (!exists("safe_execute", mode = "function")) {
  source("functions/error_handling.R", local = TRUE)
}

# ============================================================================
# TESTS: validate_cld_data()
# ============================================================================

test_that("validate_cld_data accepts valid CLD structure", {
  valid_cld <- list(
    nodes = data.frame(
      id = c("N1", "N2", "N3"),
      label = c("Node 1", "Node 2", "Node 3"),
      stringsAsFactors = FALSE
    ),
    edges = data.frame(
      from = c("N1", "N2"),
      to = c("N2", "N3"),
      stringsAsFactors = FALSE
    )
  )

  expect_true(validate_cld_data(valid_cld))
})

test_that("validate_cld_data rejects NULL input", {
  expect_error(validate_cld_data(NULL), "CLD data is NULL")
})

test_that("validate_cld_data rejects non-list input", {
  expect_error(validate_cld_data("not a list"), "CLD data must be a list")
  expect_error(validate_cld_data(123), "CLD data must be a list")
  expect_error(validate_cld_data(c(1, 2, 3)), "CLD data must be a list")
})

test_that("validate_cld_data rejects missing nodes component", {
  cld <- list(edges = data.frame(from = "A", to = "B"))
  expect_error(validate_cld_data(cld), "missing 'nodes' component")
})

test_that("validate_cld_data rejects missing edges component", {
  cld <- list(nodes = data.frame(id = "N1", label = "Node 1"))
  expect_error(validate_cld_data(cld), "missing 'edges' component")
})

test_that("validate_cld_data rejects non-dataframe nodes", {
  cld <- list(
    nodes = list(id = "N1", label = "Node 1"),
    edges = data.frame(from = "N1", to = "N1")
  )
  expect_error(validate_cld_data(cld), "nodes must be a dataframe")
})

test_that("validate_cld_data rejects empty nodes", {
  cld <- list(
    nodes = data.frame(id = character(0), label = character(0)),
    edges = data.frame(from = character(0), to = character(0))
  )
  expect_error(validate_cld_data(cld), "CLD has no nodes")
})

test_that("validate_cld_data rejects nodes missing required columns", {
  cld <- list(
    nodes = data.frame(name = "Node 1", type = "Driver"),  # Missing 'id' and 'label'
    edges = data.frame(from = "N1", to = "N2")
  )
  expect_error(validate_cld_data(cld), "missing required columns")
})

test_that("validate_cld_data accepts empty edges", {
  cld <- list(
    nodes = data.frame(id = "N1", label = "Node 1"),
    edges = data.frame(from = character(0), to = character(0))
  )
  expect_true(validate_cld_data(cld))
})

test_that("validate_cld_data rejects edges missing required columns", {
  cld <- list(
    nodes = data.frame(id = "N1", label = "Node 1"),
    edges = data.frame(source = "N1", target = "N1")  # Missing 'from' and 'to'
  )
  expect_error(validate_cld_data(cld), "missing required columns")
})

# ============================================================================
# TESTS: validate_isa_data()
# ============================================================================

test_that("validate_isa_data accepts valid ISA structure", {
  valid_isa <- list(
    drivers = data.frame(ID = "D1", Name = "Driver 1"),
    activities = data.frame(ID = "A1", Name = "Activity 1"),
    pressures = data.frame(ID = "P1", Name = "Pressure 1"),
    marine_processes = data.frame(ID = "MP1", Name = "Process 1"),
    ecosystem_services = data.frame(ID = "ES1", Name = "Service 1"),
    goods_benefits = data.frame(ID = "GB1", Name = "Benefit 1"),
    responses = data.frame(ID = "R1", Name = "Response 1")
  )

  expect_true(validate_isa_data(valid_isa))
})

test_that("validate_isa_data rejects NULL input", {
  expect_error(validate_isa_data(NULL), "ISA data is NULL")
})

test_that("validate_isa_data rejects non-list input", {
  expect_error(validate_isa_data("not a list"), "ISA data must be a list")
})

test_that("validate_isa_data rejects missing DAPSIWRM components", {
  incomplete_isa <- list(
    drivers = data.frame(ID = "D1", Name = "Driver 1"),
    activities = data.frame(ID = "A1", Name = "Activity 1")
    # Missing: pressures, marine_processes, ecosystem_services, goods_benefits, responses
  )

  expect_error(validate_isa_data(incomplete_isa), "missing components")
})

test_that("validate_isa_data rejects non-dataframe components", {
  invalid_isa <- list(
    drivers = list(ID = "D1", Name = "Driver 1"),  # Should be dataframe
    activities = data.frame(ID = "A1", Name = "Activity 1"),
    pressures = data.frame(ID = "P1", Name = "Pressure 1"),
    marine_processes = data.frame(ID = "MP1", Name = "Process 1"),
    ecosystem_services = data.frame(ID = "ES1", Name = "Service 1"),
    goods_benefits = data.frame(ID = "GB1", Name = "Benefit 1"),
    responses = data.frame(ID = "R1", Name = "Response 1")
  )

  expect_error(validate_isa_data(invalid_isa), "must be a dataframe")
})

# ============================================================================
# TESTS: check_cld_readiness()
# ============================================================================

test_that("check_cld_readiness returns correct structure", {
  cld <- list(
    nodes = data.frame(id = "N1", label = "Node 1"),
    edges = data.frame(from = "N1", to = "N1")
  )

  result <- check_cld_readiness(cld)

  expect_type(result, "list")
  expect_true("has_data" %in% names(result))
  expect_true("has_edges" %in% names(result))
  expect_true("n_nodes" %in% names(result))
  expect_true("n_edges" %in% names(result))
  expect_true("message" %in% names(result))
})

test_that("check_cld_readiness detects valid CLD with data", {
  cld <- list(
    nodes = data.frame(id = c("N1", "N2"), label = c("Node 1", "Node 2")),
    edges = data.frame(from = "N1", to = "N2")
  )

  result <- check_cld_readiness(cld)

  expect_true(result$has_data)
  expect_true(result$has_edges)
  expect_equal(result$n_nodes, 2)
  expect_equal(result$n_edges, 1)
})

test_that("check_cld_readiness detects CLD with nodes but no edges", {
  cld <- list(
    nodes = data.frame(id = "N1", label = "Node 1"),
    edges = data.frame(from = character(0), to = character(0))
  )

  result <- check_cld_readiness(cld)

  expect_true(result$has_data)
  expect_false(result$has_edges)
  expect_true(grepl("no connections", result$message, ignore.case = TRUE))
})

test_that("check_cld_readiness handles invalid CLD gracefully", {
  result <- check_cld_readiness(NULL)

  expect_false(result$has_data)
  expect_false(result$has_edges)
  # Message will contain either "error" or "NULL" for invalid CLD
  expect_true(grepl("error|NULL", result$message, ignore.case = TRUE))
})

# ============================================================================
# TESTS: safe_execute()
# ============================================================================

test_that("safe_execute returns result for successful operations", {
  result <- safe_execute({
    1 + 1
  }, default = 0)

  expect_equal(result, 2)
})
test_that("safe_execute returns default for failed operations", {
  result <- safe_execute({
    stop("Deliberate error")
  }, default = -1, silent = TRUE)

  expect_equal(result, -1)
})

test_that("safe_execute returns NULL default when not specified", {
  result <- safe_execute({
    stop("Error")
  }, silent = TRUE)

  expect_null(result)
})

test_that("safe_execute handles complex expressions", {
  result <- safe_execute({
    x <- 10
    y <- 20
    x * y
  }, default = 0)

  expect_equal(result, 200)
})

test_that("safe_execute with silent=FALSE produces warning", {
  expect_warning(
    safe_execute({
      stop("Test error")
    }, default = NULL, silent = FALSE, error_msg = "Custom message"),
    "Custom message"
  )
})

# ============================================================================
# TESTS: safe_get_nested()
# ============================================================================

test_that("safe_get_nested retrieves existing nested values", {
  data <- list(
    level1 = list(
      level2 = list(
        level3 = "target_value"
      )
    )
  )

  result <- safe_get_nested(data, "level1", "level2", "level3")
  expect_equal(result, "target_value")
})

test_that("safe_get_nested returns default for missing paths", {
  data <- list(a = list(b = 1))

  result <- safe_get_nested(data, "a", "c", default = "missing")
  expect_equal(result, "missing")
})

test_that("safe_get_nested returns default for NULL data", {
  result <- safe_get_nested(NULL, "a", "b", default = "fallback")
  expect_equal(result, "fallback")
})

test_that("safe_get_nested returns default for NULL value in path", {
  data <- list(a = list(b = NULL))

  result <- safe_get_nested(data, "a", "b", default = "default_value")
  expect_equal(result, "default_value")
})

test_that("safe_get_nested handles single-level access", {
  data <- list(key = "value")

  result <- safe_get_nested(data, "key")
  expect_equal(result, "value")
})

test_that("safe_get_nested returns default for non-list intermediate", {
  data <- list(a = "not_a_list")

  result <- safe_get_nested(data, "a", "b", default = "error")
  expect_equal(result, "error")
})

# ============================================================================
# TESTS: safe_create_igraph()
# ============================================================================

test_that("safe_create_igraph creates valid graph from valid data", {
  nodes <- data.frame(
    id = c("N1", "N2", "N3"),
    label = c("Node 1", "Node 2", "Node 3"),
    stringsAsFactors = FALSE
  )
  edges <- data.frame(
    from = c("N1", "N2"),
    to = c("N2", "N3"),
    stringsAsFactors = FALSE
  )

  g <- safe_create_igraph(nodes, edges)

  expect_true(igraph::is.igraph(g))
  expect_equal(igraph::vcount(g), 3)
  expect_equal(igraph::ecount(g), 2)
})

test_that("safe_create_igraph handles empty edges", {
  nodes <- data.frame(
    id = c("N1", "N2"),
    label = c("Node 1", "Node 2"),
    stringsAsFactors = FALSE
  )
  edges <- data.frame(
    from = character(0),
    to = character(0),
    stringsAsFactors = FALSE
  )

  g <- safe_create_igraph(nodes, edges)

  expect_true(igraph::is.igraph(g))
  expect_equal(igraph::vcount(g), 2)
  expect_equal(igraph::ecount(g), 0)
})

test_that("safe_create_igraph returns NULL for invalid nodes", {
  g <- safe_create_igraph(NULL, data.frame(from = "A", to = "B"))
  expect_null(g)
})

test_that("safe_create_igraph returns NULL for empty nodes", {
  nodes <- data.frame(id = character(0), label = character(0))
  edges <- data.frame(from = character(0), to = character(0))

  g <- safe_create_igraph(nodes, edges)
  expect_null(g)
})

test_that("safe_create_igraph returns NULL for missing required columns", {
  nodes <- data.frame(name = "Node 1")  # Missing 'id'
  edges <- data.frame(from = "N1", to = "N2")

  g <- safe_create_igraph(nodes, edges)
  expect_null(g)
})

# ============================================================================
# TESTS: safe_numeric()
# ============================================================================

test_that("safe_numeric converts valid numeric strings", {
  expect_equal(safe_numeric("123"), 123)
  expect_equal(safe_numeric("3.14"), 3.14)
  expect_equal(safe_numeric("-5"), -5)
})

test_that("safe_numeric returns default for invalid input", {
  expect_equal(safe_numeric(NULL, default = 0), 0)
  expect_equal(safe_numeric(NA, default = -1), -1)
  expect_equal(safe_numeric("not a number", default = 99), 99)
})

test_that("safe_numeric handles already numeric input", {
  expect_equal(safe_numeric(42), 42)
  expect_equal(safe_numeric(3.14159), 3.14159)
})

test_that("safe_numeric handles Inf values", {
  expect_equal(safe_numeric(Inf, default = 0), 0)
  expect_equal(safe_numeric(-Inf, default = 0), 0)
})

# ============================================================================
# TESTS: safe_character()
# ============================================================================

test_that("safe_character converts valid input", {
  expect_equal(safe_character(123), "123")
  expect_equal(safe_character(TRUE), "TRUE")
  expect_equal(safe_character("text"), "text")
})

test_that("safe_character returns default for NULL", {
  expect_equal(safe_character(NULL, default = "empty"), "empty")
})

test_that("safe_character returns default for NA", {
  expect_equal(safe_character(NA, default = "missing"), "missing")
})

# ============================================================================
# TESTS: has_data()
# ============================================================================

test_that("has_data returns TRUE for valid dataframe with rows", {
  df <- data.frame(a = 1:3, b = c("x", "y", "z"))
  expect_true(has_data(df))
})

test_that("has_data returns FALSE for NULL", {
  expect_false(has_data(NULL))
})

test_that("has_data returns FALSE for empty dataframe", {
  df <- data.frame(a = integer(0), b = character(0))
  expect_false(has_data(df))
})

test_that("has_data returns FALSE for non-dataframe", {
  expect_false(has_data(list(a = 1, b = 2)))
  expect_false(has_data(c(1, 2, 3)))
  expect_false(has_data("string"))
})

# ============================================================================
# TESTS: log_error() and log_warning()
# ============================================================================

test_that("log_error produces output with context", {
  output <- capture.output(log_error("TEST_CONTEXT", "Test error message"))

  expect_true(length(output) > 0)
  expect_true(grepl("ERROR", output[1]))
  expect_true(grepl("TEST_CONTEXT", output[1]))
  expect_true(grepl("Test error message", output[1]))
})

test_that("log_error includes error object message", {
  err <- simpleError("Original error")
  output <- capture.output(log_error("CTX", "Wrapper message", err))

  expect_true(grepl("Original error", output[1]))
})

test_that("log_warning produces output with context", {
  output <- capture.output(log_warning("WARN_CONTEXT", "Test warning"))

  expect_true(length(output) > 0)
  expect_true(grepl("WARN", output[1]))
  expect_true(grepl("WARN_CONTEXT", output[1]))
  expect_true(grepl("Test warning", output[1]))
})

# ============================================================================
# TESTS: safe_source()
# ============================================================================

test_that("safe_source returns FALSE for non-existent file with required=FALSE", {
  result <- safe_source("non_existent_file_12345.R", required = FALSE)
  expect_false(result)
})

test_that("safe_source throws error for non-existent file with required=TRUE", {
  expect_error(
    safe_source("non_existent_file_12345.R", required = TRUE),
    "not found"
  )
})

test_that("safe_source successfully sources valid R file", {
  # Create a temporary R file
temp_file <- tempfile(fileext = ".R")
  writeLines("test_var_safe_source <- 42", temp_file)

  result <- safe_source(temp_file, local = FALSE, required = FALSE)

  expect_true(result)
  expect_true(exists("test_var_safe_source"))
  expect_equal(test_var_safe_source, 42)

  # Cleanup
  unlink(temp_file)
  rm(test_var_safe_source, envir = .GlobalEnv)
})

test_that("safe_source returns FALSE for file with syntax error when required=FALSE", {
  # Create a temporary R file with syntax error
  temp_file <- tempfile(fileext = ".R")
  writeLines("this is not valid R code {{{", temp_file)

  result <- safe_source(temp_file, required = FALSE)

  expect_false(result)

  # Cleanup
  unlink(temp_file)
})

# ============================================================================
# TESTS: safe_source_multiple()
# ============================================================================

test_that("safe_source_multiple returns results for each file", {
  # Create temporary files
  temp1 <- tempfile(fileext = ".R")
  temp2 <- tempfile(fileext = ".R")
  writeLines("multi_test_var1 <- 1", temp1)
  writeLines("multi_test_var2 <- 2", temp2)

  result <- safe_source_multiple(c(temp1, temp2), local = FALSE, stop_on_first_error = FALSE)

  expect_type(result, "list")
  expect_equal(length(result), 2)
  expect_true(all(unlist(result)))

  # Cleanup
  unlink(c(temp1, temp2))
  rm(multi_test_var1, multi_test_var2, envir = .GlobalEnv)
})

test_that("safe_source_multiple stops on first error when requested", {
  temp1 <- tempfile(fileext = ".R")
  temp2 <- tempfile(fileext = ".R")  # This exists but won't be reached
  writeLines("invalid syntax {{{", temp1)
  writeLines("valid_var <- 1", temp2)

  expect_error(
    safe_source_multiple(c(temp1, temp2), stop_on_first_error = TRUE)
  )

  # Cleanup
  unlink(c(temp1, temp2))
})

# ============================================================================
# TESTS: validate_module_dependencies()
# ============================================================================

test_that("validate_module_dependencies returns TRUE when no dependencies specified", {
  result <- validate_module_dependencies("some_module.R", dependencies = NULL)
  expect_true(result)
})

test_that("validate_module_dependencies returns TRUE when all dependencies exist", {
  # These functions should exist in base R
  result <- validate_module_dependencies("test.R", dependencies = c("sum", "mean", "max"))
  expect_true(result)
})

test_that("validate_module_dependencies returns FALSE when dependencies missing", {
  result <- validate_module_dependencies(
    "test.R",
    dependencies = c("sum", "non_existent_function_xyz_123")
  )
  expect_false(result)
})

# ============================================================================
# EDGE CASES AND INTEGRATION TESTS
# ============================================================================

test_that("safe_execute handles nested safe_execute calls", {
  result <- safe_execute({
    inner_result <- safe_execute({
      10 / 2
    }, default = 0)
    inner_result * 2
  }, default = -1)

  expect_equal(result, 10)
})

test_that("safe_get_nested works with real project data structure", {
  # Simulate real project data structure
  project <- list(
    project_id = "test-123",
    project_name = "Test Project",
    data = list(
      metadata = list(
        da_site = "Test Site",
        focal_issue = "Test Issue"
      ),
      isa_data = list(
        drivers = data.frame(ID = "D1", Name = "Driver")
      )
    )
  )

  # Test various access patterns
  expect_equal(safe_get_nested(project, "project_id"), "test-123")
  expect_equal(safe_get_nested(project, "data", "metadata", "da_site"), "Test Site")
  expect_equal(safe_get_nested(project, "data", "missing_key", default = "not found"), "not found")
})

test_that("validation functions work together for complete workflow", {
  # Create valid project with CLD
  cld <- list(
    nodes = data.frame(
      id = c("D1", "A1", "P1"),
      label = c("Driver 1", "Activity 1", "Pressure 1"),
      stringsAsFactors = FALSE
    ),
    edges = data.frame(
      from = c("D1", "A1"),
      to = c("A1", "P1"),
      stringsAsFactors = FALSE
    )
  )

  # Validate CLD
  expect_true(validate_cld_data(cld))

  # Check readiness
  readiness <- check_cld_readiness(cld)
  expect_true(readiness$has_data)
  expect_true(readiness$has_edges)

  # Create graph
  g <- safe_create_igraph(cld$nodes, cld$edges)
  expect_true(igraph::is.igraph(g))
})
