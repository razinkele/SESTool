# setup.R
# Test setup and configuration
# This file runs before all tests

# Note: Only testthat is loaded here. All other packages (shiny, igraph, dplyr, etc.)
# are loaded via global.R below. Individual test files should NOT load packages
# that are already in global.R - this causes redundancy and slower test execution.
library(testthat)

# Suppress warnings during tests
options(warn = -1)

# Set random seed for reproducibility
set.seed(42)

# Determine project root directory
test_dir <- getwd()
if (basename(test_dir) == "testthat") {
  project_root <- file.path(dirname(dirname(test_dir)))
} else {
  project_root <- test_dir
}

# Change to project root for sourcing files
old_wd <- getwd()
setwd(project_root)

# Load global environment with error handling
tryCatch({
  if (file.exists("global.R")) {
    source("global.R", local = TRUE)
  }
}, error = function(e) {
  message("Warning: Could not fully load global.R: ", e$message)
  message("Some tests may be skipped. Loading minimal environment...")

  # Load essential packages
  suppressPackageStartupMessages({
    library(shiny)
    library(igraph)
  })

  # Define essential operators and functions
  `%||%` <<- function(a, b) if (is.null(a)) b else a

  # Create minimal init_session_data if not loaded
  if (!exists("init_session_data")) {
    init_session_data <<- function() {
      list(
        project_id = paste0("PROJ_", format(Sys.time(), "%Y%m%d%H%M%S")),
        project_name = "Test Project",  # Added this field
        created_at = Sys.time(),
        last_modified = Sys.time(),
        user = Sys.info()["user"],
        version = "1.0",
        data = list(
          metadata = list(),
          pims = list(),
          isa_data = list(),
          cld = list(),
          responses = list()
        )
      )
    }
  }

  # Create minimal validation functions
  if (!exists("validate_project_structure")) {
    validate_project_structure <<- function(data) {
      is.list(data) &&
        all(c("project_id", "project_name", "data") %in% names(data))
    }
  }

  if (!exists("safe_get_nested")) {
    safe_get_nested <<- function(data, ..., default = NULL) {
      keys <- list(...)
      result <- data
      for (key in keys) {
        if (is.null(result) || !is.list(result) || !key %in% names(result)) {
          return(default)
        }
        result <- result[[key]]
      }
      return(result)
    }
  }
})

# Load helper functions (from project root)
tryCatch({
  if (file.exists(file.path(project_root, "functions/data_structure.R"))) {
    source(file.path(project_root, "functions/data_structure.R"), local = TRUE)
  }
}, error = function(e) {
  message("Warning: Could not load data_structure.R")
})

tryCatch({
  if (file.exists(file.path(project_root, "functions/network_analysis.R"))) {
    source(file.path(project_root, "functions/network_analysis.R"), local = TRUE)
  }
}, error = function(e) {
  message("Warning: Could not load network_analysis.R")
})

tryCatch({
  if (file.exists(file.path(project_root, "functions/ui_helpers.R"))) {
    source(file.path(project_root, "functions/ui_helpers.R"), local = TRUE)
  }
}, error = function(e) {
  message("Warning: Could not load ui_helpers.R")
})

tryCatch({
  if (file.exists(file.path(project_root, "functions/visnetwork_helpers.R"))) {
    source(file.path(project_root, "functions/visnetwork_helpers.R"), local = TRUE)
  }
}, error = function(e) {
  message("Warning: Could not load visnetwork_helpers.R")
})

tryCatch({
  if (file.exists(file.path(project_root, "functions/export_functions.R"))) {
    source(file.path(project_root, "functions/export_functions.R"), local = TRUE)
  }
}, error = function(e) {
  message("Warning: Could not load export_functions.R")
})

tryCatch({
  if (file.exists(file.path(project_root, "functions/ml_feature_engineering.R"))) {
    source(file.path(project_root, "functions/ml_feature_engineering.R"), local = TRUE)
  }
}, error = function(e) {
  message("Warning: Could not load ml_feature_engineering.R")
})

# Load SES templates for integration tests
# NOTE: Templates are also loaded in helper-templates.R which runs automatically
# This is a backup in case helper files run in different order
tryCatch({
  if (file.exists(file.path(project_root, "functions/template_loader.R"))) {
    source(file.path(project_root, "functions/template_loader.R"), local = FALSE)
    # Load templates from data directory and assign to global environment
    # Use assign() for proper scoping - ensures exists("ses_templates") works in tests
    templates_loaded <- load_all_templates("data")
    assign("ses_templates", templates_loaded, envir = .GlobalEnv)
    if (length(templates_loaded) > 0) {
      message("Setup: Loaded ", length(templates_loaded), " SES templates for tests: ",
              paste(names(templates_loaded), collapse = ", "))
    } else {
      message("Setup: Warning - No templates loaded from data directory")
    }
  }
}, error = function(e) {
  message("Setup: Warning - Could not load SES templates: ", e$message)
  # Assign empty list to prevent exists() check failures
  assign("ses_templates", list(), envir = .GlobalEnv)
})

# NOTE: Module stubs are now in helper-stubs.R and loaded automatically by testthat

# Restore working directory
setwd(old_wd)

# Create temporary directory for test outputs
test_output_dir <- file.path(tempdir(), "marinesabres_tests")
if (!dir.exists(test_output_dir)) {
  dir.create(test_output_dir, recursive = TRUE)
}

# Store original working directory
original_wd <- getwd()

# Function to clean up after tests
cleanup_tests <- function() {
  # Remove temporary test files
  if (dir.exists(test_output_dir)) {
    unlink(test_output_dir, recursive = TRUE)
  }

  # Restore original working directory
  setwd(original_wd)
}

# Register cleanup function
reg.finalizer(environment(), function(e) cleanup_tests(), onexit = TRUE)

# Test configuration
Sys.setenv(TESTTHAT = "true")
Sys.setenv(MARINESABRES_TEST_MODE = "true")

message("Test environment initialized successfully")
