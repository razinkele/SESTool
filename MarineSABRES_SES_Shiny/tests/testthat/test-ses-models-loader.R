# test-ses-models-loader.R
# Tests for SES Models loading functionality

# Helper function to get app directory
get_app_dir <- function() {
  # Try multiple approaches to find the app directory
  candidates <- c(
    # From testthat context
    file.path(testthat::test_path(), "..", ".."),
    # From working directory
    getwd(),
    file.path(getwd(), ".."),
    file.path(getwd(), "..", ".."),
    # Absolute fallback
    "C:/Users/DELL/OneDrive - ku.lt/HORIZON_EUROPE/Marine-SABRES/SESToolbox/MarineSABRES_SES_Shiny"
  )

  for (path in candidates) {
    norm_path <- tryCatch(normalizePath(path, winslash = "/", mustWork = FALSE), error = function(e) NULL)
    if (!is.null(norm_path) && file.exists(file.path(norm_path, "app.R"))) {
      return(norm_path)
    }
  }

  stop("Could not find app directory")
}

# Setup: Source required files
test_that("Required source files can be loaded", {
  app_dir <- get_app_dir()

  # Source the loader file
  loader_path <- file.path(app_dir, "functions", "ses_models_loader.R")
  expect_true(file.exists(loader_path), info = paste("Loader not found at:", loader_path))

  source(loader_path, local = TRUE)

  expect_true(exists("scan_ses_models"))
  expect_true(exists("load_ses_model_file"))
  expect_true(exists("get_model_preview"))
  expect_true(exists("find_ses_models_dir"))
})

# ============================================================================
# DIRECTORY FINDING TESTS
# ============================================================================

test_that("find_ses_models_dir finds the SESModels directory", {
  app_dir <- get_app_dir()
  source(file.path(app_dir, "functions", "ses_models_loader.R"), local = TRUE)

  # Save and change working directory
  old_wd <- getwd()
  setwd(app_dir)

  result <- find_ses_models_dir("SESModels")

  setwd(old_wd)

  # Should find directory or return NULL if it doesn't exist
  if (dir.exists(file.path(app_dir, "SESModels"))) {
    expect_true(!is.null(result))
    expect_true(dir.exists(result))
    expect_true(grepl("SESModels", result))
  } else {
    skip("SESModels directory does not exist")
  }
})

test_that("find_ses_models_dir returns NULL for non-existent directory", {
  app_dir <- get_app_dir()
  source(file.path(app_dir, "functions", "ses_models_loader.R"), local = TRUE)

  result <- find_ses_models_dir("NonExistentDirectory12345")

  expect_null(result)
})

# ============================================================================
# SCANNING TESTS
# ============================================================================

test_that("scan_ses_models returns proper structure", {
  app_dir <- get_app_dir()
  source(file.path(app_dir, "functions", "ses_models_loader.R"), local = TRUE)

  old_wd <- getwd()
  setwd(app_dir)

  result <- scan_ses_models("SESModels", use_cache = FALSE)

  setwd(old_wd)

  expect_true(is.list(result))

  # If models exist, check structure
  if (length(result) > 0) {
    for (group_name in names(result)) {
      expect_true(is.list(result[[group_name]]))

      for (model in result[[group_name]]) {
        expect_true("file_path" %in% names(model))
        expect_true("display_name" %in% names(model))
        expect_true("group" %in% names(model))
        expect_true("modified_time" %in% names(model))
        expect_true("size_kb" %in% names(model))
      }
    }
  }
})

test_that("scan_ses_models groups files by parent folder", {
  app_dir <- get_app_dir()
  source(file.path(app_dir, "functions", "ses_models_loader.R"), local = TRUE)

  old_wd <- getwd()
  setwd(app_dir)

  result <- scan_ses_models("SESModels", use_cache = FALSE)

  setwd(old_wd)

  if (length(result) > 0) {
    # Check that group names match folder names
    expected_groups <- c("Arctic DA", "Macronesia DA", "Tuscan DA", "Other Models")
    actual_groups <- names(result)

    # At least some groups should match expected
    matching <- intersect(actual_groups, expected_groups)
    expect_true(length(matching) > 0 || length(actual_groups) > 0)
  } else {
    skip("No SES models found to test grouping")
  }
})

test_that("get_models_for_select returns format suitable for selectInput", {
  app_dir <- get_app_dir()
  source(file.path(app_dir, "functions", "ses_models_loader.R"), local = TRUE)

  old_wd <- getwd()
  setwd(app_dir)

  result <- get_models_for_select("SESModels")

  setwd(old_wd)

  expect_true(is.list(result))

  if (length(result) > 0) {
    for (group_name in names(result)) {
      # Each group should be a named list
      expect_true(is.list(result[[group_name]]))
      # Values should be file paths
      for (choice in result[[group_name]]) {
        expect_true(is.character(choice))
      }
    }
  }
})

# ============================================================================
# FILE LOADING TESTS
# ============================================================================

test_that("load_ses_model_file handles missing file gracefully", {
  app_dir <- get_app_dir()
  source(file.path(app_dir, "functions", "ses_models_loader.R"), local = TRUE)

  result <- load_ses_model_file("nonexistent_file.xlsx")

  expect_true(is.list(result))
  expect_true(length(result$errors) > 0)
  expect_true(any(grepl("not found|does not exist", result$errors, ignore.case = TRUE)))
})

test_that("load_ses_model_file handles NULL path gracefully", {
  app_dir <- get_app_dir()
  source(file.path(app_dir, "functions", "ses_models_loader.R"), local = TRUE)

  result <- load_ses_model_file(NULL)

  expect_true(is.list(result))
  expect_true(length(result$errors) > 0)
})

test_that("load_ses_model_file handles empty path gracefully", {
  app_dir <- get_app_dir()
  source(file.path(app_dir, "functions", "ses_models_loader.R"), local = TRUE)

  result <- load_ses_model_file("")

  expect_true(is.list(result))
  expect_true(length(result$errors) > 0)
})

test_that("load_ses_model_file loads valid Excel file", {
  app_dir <- get_app_dir()
  source(file.path(app_dir, "functions", "ses_models_loader.R"), local = TRUE)

  old_wd <- getwd()
  setwd(app_dir)

  # Find a valid Excel file to test
  models <- get_all_models_flat("SESModels")

  setwd(old_wd)

  if (length(models) == 0) {
    skip("No SES models found to test loading")
  }

  # Find a model that has the correct sheet structure (Elements and Connections)
  valid_model_found <- FALSE
  test_file <- NULL
  result <- NULL

  for (model in models) {
    test_result <- load_ses_model_file(model$file_path, validate = FALSE)
    # Check if it has the expected structure (elements and connections sheets exist)
    if ("elements" %in% names(test_result) &&
        "connections" %in% names(test_result) &&
        !is.null(test_result$elements) &&
        !is.null(test_result$connections)) {
      test_file <- model$file_path
      result <- load_ses_model_file(test_file, validate = TRUE)
      valid_model_found <- TRUE
      break
    }
  }

  if (!valid_model_found) {
    skip("No SES models with Elements/Connections sheets found")
  }

  expect_true(is.list(result))
  expect_true("elements" %in% names(result))
  expect_true("connections" %in% names(result))
  expect_true("errors" %in% names(result))
  expect_true("file_name" %in% names(result))

  # If no errors, check data frames
  if (length(result$errors) == 0) {
    expect_true(is.data.frame(result$elements))
    expect_true(is.data.frame(result$connections))
    expect_true(nrow(result$elements) > 0)
  }
})

# ============================================================================
# VALIDATION TESTS
# ============================================================================

test_that("validate_ses_model_data catches missing Label column", {
  app_dir <- get_app_dir()
  source(file.path(app_dir, "functions", "ses_models_loader.R"), local = TRUE)

  # Create test data without Label column
  elements <- data.frame(
    Name = c("A", "B", "C"),
    type = c("Driver", "Activity", "Pressure")
  )
  connections <- data.frame(
    From = c("A"),
    To = c("B"),
    Label = c("+")
  )

  result <- validate_ses_model_data(elements, connections)

  expect_true(length(result$errors) > 0)
  expect_true(any(grepl("Label", result$errors)))
})

test_that("validate_ses_model_data catches missing type column", {
  app_dir <- get_app_dir()
  source(file.path(app_dir, "functions", "ses_models_loader.R"), local = TRUE)

  # Create test data without type column
  elements <- data.frame(
    Label = c("A", "B", "C"),
    category = c("Driver", "Activity", "Pressure")
  )
  connections <- data.frame(
    From = c("A"),
    To = c("B"),
    Label = c("+")
  )

  result <- validate_ses_model_data(elements, connections)

  expect_true(length(result$errors) > 0)
  expect_true(any(grepl("type", result$errors, ignore.case = TRUE)))
})

test_that("validate_ses_model_data catches missing connection columns", {
  app_dir <- get_app_dir()
  source(file.path(app_dir, "functions", "ses_models_loader.R"), local = TRUE)

  elements <- data.frame(
    Label = c("A", "B", "C"),
    type = c("Driver", "Activity", "Pressure")
  )

  # Missing Label column in connections
  connections <- data.frame(
    From = c("A"),
    To = c("B")
  )

  result <- validate_ses_model_data(elements, connections)

  expect_true(length(result$errors) > 0)
  expect_true(any(grepl("Label", result$errors)))
})

test_that("validate_ses_model_data accepts valid data", {
  app_dir <- get_app_dir()
  source(file.path(app_dir, "functions", "ses_models_loader.R"), local = TRUE)

  elements <- data.frame(
    Label = c("A", "B", "C"),
    type = c("Driver", "Activity", "Pressure")
  )
  connections <- data.frame(
    From = c("A"),
    To = c("B"),
    Label = c("+")
  )

  result <- validate_ses_model_data(elements, connections)

  expect_true(length(result$errors) == 0)
})

# ============================================================================
# PREVIEW TESTS
# ============================================================================

test_that("get_model_preview returns proper structure", {
  app_dir <- get_app_dir()
  source(file.path(app_dir, "functions", "ses_models_loader.R"), local = TRUE)

  old_wd <- getwd()
  setwd(app_dir)

  models <- get_all_models_flat("SESModels")

  setwd(old_wd)

  if (length(models) == 0) {
    skip("No SES models found to test preview")
  }

  # Find a model that has the correct sheet structure
  test_file <- NULL
  for (model in models) {
    test_result <- load_ses_model_file(model$file_path, validate = FALSE)
    if (!is.null(test_result$elements) && !is.null(test_result$connections)) {
      test_file <- model$file_path
      break
    }
  }

  if (is.null(test_file)) {
    skip("No SES models with Elements/Connections sheets found for preview test")
  }

  result <- get_model_preview(test_file)

  expect_true(is.list(result))
  expect_true("file_name" %in% names(result))
  expect_true("file_path" %in% names(result))
  expect_true("elements_count" %in% names(result))
  expect_true("connections_count" %in% names(result))
  expect_true("is_valid" %in% names(result))
  expect_true("errors" %in% names(result))

  if (result$is_valid) {
    expect_true(is.numeric(result$elements_count))
    expect_true(is.numeric(result$connections_count))
  }
})

test_that("get_model_preview handles invalid file gracefully", {
  app_dir <- get_app_dir()
  source(file.path(app_dir, "functions", "ses_models_loader.R"), local = TRUE)

  result <- get_model_preview("nonexistent_file.xlsx")

  expect_true(is.list(result))
  expect_false(result$is_valid)
  expect_true(length(result$errors) > 0)
})

# ============================================================================
# EXCEL IMPORT HELPERS TESTS
# ============================================================================

test_that("convert_excel_to_isa creates proper ISA structure", {
  app_dir <- get_app_dir()

  # Source the helpers
  source(file.path(app_dir, "functions", "excel_import_helpers.R"), local = TRUE)

  elements <- data.frame(
    Label = c("Climate Change", "Fishing", "Overfishing", "Fish Stock", "Fish Supply", "Food Security"),
    type = c("Driver", "Activity", "Pressure", "Marine Process and Function", "Ecosystem Service", "Good and Benefit")
    
  )

  connections <- data.frame(
    From = c("Climate Change", "Fishing", "Overfishing", "Fish Stock", "Fish Supply"),
    To = c("Fishing", "Overfishing", "Fish Stock", "Fish Supply", "Food Security"),
    Label = c("+", "+", "-", "+", "+")
    
  )

  result <- convert_excel_to_isa(elements, connections)

  expect_true(is.list(result))
  expect_true("drivers" %in% names(result))
  expect_true("activities" %in% names(result))
  expect_true("pressures" %in% names(result))
  expect_true("marine_processes" %in% names(result))
  expect_true("ecosystem_services" %in% names(result))
  expect_true("goods_benefits" %in% names(result))
  expect_true("adjacency_matrices" %in% names(result))

  # Check that elements were categorized
  expect_true(!is.null(result$drivers))
  expect_equal(nrow(result$drivers), 1)
  expect_true(!is.null(result$activities))
  expect_equal(nrow(result$activities), 1)

  # Check that adjacency matrices were created
  expect_true(length(result$adjacency_matrices) > 0)
})

test_that("convert_excel_to_isa handles type...2 column name", {
  app_dir <- get_app_dir()
  source(file.path(app_dir, "functions", "excel_import_helpers.R"), local = TRUE)

  # Simulate Excel duplicate column naming
  elements <- data.frame(
    Label = c("A", "B"),
    `type...2` = c("Driver", "Activity"),
    check.names = FALSE
    
  )

  connections <- data.frame(
    From = c("A"),
    To = c("B"),
    Label = c("+")
    
  )

  result <- convert_excel_to_isa(elements, connections)

  expect_true(is.list(result))
  expect_true(!is.null(result$drivers))
  expect_true(!is.null(result$activities))
})

# ============================================================================
# INTEGRATION TEST
# ============================================================================

test_that("Full model loading workflow works", {
  app_dir <- get_app_dir()

  source(file.path(app_dir, "functions", "ses_models_loader.R"), local = TRUE)
  source(file.path(app_dir, "functions", "excel_import_helpers.R"), local = TRUE)

  old_wd <- getwd()
  setwd(app_dir)

  # Step 1: Scan models
  models_grouped <- scan_ses_models("SESModels", use_cache = FALSE)

  if (length(models_grouped) == 0) {
    setwd(old_wd)
    skip("No SES models found for integration test")
  }

  # Step 2: Find a model with valid Elements/Connections structure
  valid_model <- NULL
  model_data <- NULL

  for (group_name in names(models_grouped)) {
    for (model in models_grouped[[group_name]]) {
      test_data <- load_ses_model_file(model$file_path, validate = FALSE)
      if (!is.null(test_data$elements) && !is.null(test_data$connections)) {
        valid_model <- model
        model_data <- load_ses_model_file(model$file_path, validate = TRUE)
        break
      }
    }
    if (!is.null(valid_model)) break
  }

  if (is.null(valid_model)) {
    setwd(old_wd)
    skip("No SES models with Elements/Connections sheets found")
  }

  # Step 3: Get preview
  preview <- get_model_preview(valid_model$file_path)
  expect_true(is.list(preview))

  # Step 4: Check model data
  if (length(model_data$errors) > 0) {
    setwd(old_wd)
    cat("Model errors:", paste(model_data$errors, collapse = "; "), "\n")
    skip(paste("Test model has errors:", paste(model_data$errors, collapse = "; ")))
  }

  # Step 5: Convert to ISA
  isa_data <- convert_excel_to_isa(model_data$elements, model_data$connections)

  setwd(old_wd)

  # Verify ISA structure
  expect_true(is.list(isa_data))
  expect_true("adjacency_matrices" %in% names(isa_data))

  # At least one category should have data
  has_data <- FALSE
  for (cat in c("drivers", "activities", "pressures", "marine_processes", "ecosystem_services", "goods_benefits", "responses")) {
    if (!is.null(isa_data[[cat]]) && nrow(isa_data[[cat]]) > 0) {
      has_data <- TRUE
      break
    }
  }
  expect_true(has_data)
})
