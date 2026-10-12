# tests/run_json_loading_tests.R
# Standalone runner for JSON project loading tests.
# Uses source() to avoid testthat helper auto-loading which requires
# the full app environment (shinyFiles, etc.)
#
# Usage: Rscript tests/run_json_loading_tests.R

library(testthat)
library(jsonlite)

project_root <- normalizePath(".")

# Minimal stub — data_structure.R calls debug_log for warnings
debug_log <- function(msg, ctx = "") invisible(NULL)

source(file.path(project_root, "constants.R"), local = FALSE)
source(file.path(project_root, "functions", "utils.R"), local = FALSE)
source(file.path(project_root, "functions", "wp5_vocabulary.R"), local = FALSE)
source(file.path(project_root, "functions", "response_measures_schema.R"), local = FALSE)
source(file.path(project_root, "functions", "data_structure.R"), local = FALSE)
source(file.path(project_root, "functions", "indicator_registry.R"), local = FALSE)
source(file.path(project_root, "functions", "indicator_snapshot.R"), local = FALSE)

cat("Running JSON project loading tests...\n\n")
source(file.path(project_root, "tests", "testthat", "test-json-project-loading.R"))
cat("\nAll tests passed.\n")
