# test-persistent-storage.R
# Unit tests for functions/persistent_storage.R

library(testthat)
library(shiny)

# ============================================================================
# CONSTANTS TESTS
# ============================================================================

test_that("persistent storage constants are defined", {
  skip_if_not(exists("MARINESABRES_PROJECTS_FOLDER"),
              "MARINESABRES_PROJECTS_FOLDER not available")

  expect_true(is.character(MARINESABRES_PROJECTS_FOLDER))
  expect_true(nchar(MARINESABRES_PROJECTS_FOLDER) > 0)
})

test_that("MAX_RECENT_PROJECTS is defined", {
  skip_if_not(exists("MAX_RECENT_PROJECTS"),
              "MAX_RECENT_PROJECTS not available")

  expect_true(is.numeric(MAX_RECENT_PROJECTS))
  expect_true(MAX_RECENT_PROJECTS > 0)
})

test_that("PROJECT_FILE_EXTENSION is .rds", {
  skip_if_not(exists("PROJECT_FILE_EXTENSION"),
              "PROJECT_FILE_EXTENSION not available")

  expect_equal(PROJECT_FILE_EXTENSION, ".rds")
})

test_that("STORAGE_CONFIG_FILE is defined", {
  skip_if_not(exists("STORAGE_CONFIG_FILE"),
              "STORAGE_CONFIG_FILE not available")

  expect_true(is.character(STORAGE_CONFIG_FILE))
  expect_true(grepl("\\.rds$", STORAGE_CONFIG_FILE))
})

# ============================================================================
# detect_deployment_mode TESTS
# ============================================================================

test_that("detect_deployment_mode function exists", {
  skip_if_not(exists("detect_deployment_mode", mode = "function"),
              "detect_deployment_mode not available")
  expect_true(is.function(detect_deployment_mode))
})

test_that("detect_deployment_mode returns valid mode", {
  skip_if_not(exists("detect_deployment_mode", mode = "function"),
              "detect_deployment_mode not available")

  mode <- detect_deployment_mode()
  expect_true(mode %in% c("local", "server"))
})

# ============================================================================
# get_user_documents_path TESTS
# ============================================================================

test_that("get_user_documents_path function exists", {
  skip_if_not(exists("get_user_documents_path", mode = "function"),
              "get_user_documents_path not available")
  expect_true(is.function(get_user_documents_path))
})

test_that("get_user_documents_path returns valid path or NULL", {
  skip_if_not(exists("get_user_documents_path", mode = "function"),
              "get_user_documents_path not available")

  result <- get_user_documents_path()
  if (!is.null(result)) {
    expect_true(is.character(result))
    expect_true(nchar(result) > 0)
    expect_true(dir.exists(result))
  }
})

# ============================================================================
# get_storage_config_path TESTS
# ============================================================================

test_that("get_storage_config_path function exists", {
  skip_if_not(exists("get_storage_config_path", mode = "function"),
              "get_storage_config_path not available")
  expect_true(is.function(get_storage_config_path))
})

test_that("get_storage_config_path returns path or NULL", {
  skip_if_not(exists("get_storage_config_path", mode = "function"),
              "get_storage_config_path not available")

  result <- get_storage_config_path()
  if (!is.null(result)) {
    expect_true(is.character(result))
    expect_true(grepl(STORAGE_CONFIG_FILE, result, fixed = TRUE))
  }
})

# ============================================================================
# get_suggested_projects_folder TESTS
# ============================================================================

test_that("get_suggested_projects_folder function exists", {
  skip_if_not(exists("get_suggested_projects_folder", mode = "function"),
              "get_suggested_projects_folder not available")
  expect_true(is.function(get_suggested_projects_folder))
})

test_that("get_suggested_projects_folder returns path containing folder name", {
  skip_if_not(exists("get_suggested_projects_folder", mode = "function"),
              "get_suggested_projects_folder not available")

  result <- get_suggested_projects_folder()
  if (!is.null(result)) {
    expect_true(is.character(result))
    expect_true(grepl(MARINESABRES_PROJECTS_FOLDER, result, fixed = TRUE))
  }
})

# ============================================================================
# is_storage_configured TESTS
# ============================================================================

test_that("is_storage_configured function exists", {
  skip_if_not(exists("is_storage_configured", mode = "function"),
              "is_storage_configured not available")
  expect_true(is.function(is_storage_configured))
})

test_that("is_storage_configured returns logical", {
  skip_if_not(exists("is_storage_configured", mode = "function"),
              "is_storage_configured not available")

  result <- is_storage_configured()
  expect_true(is.logical(result))
})

# ============================================================================
# list_saved_projects TESTS
# ============================================================================

test_that("list_saved_projects function exists", {
  skip_if_not(exists("list_saved_projects", mode = "function"),
              "list_saved_projects not available")
  expect_true(is.function(list_saved_projects))
})

test_that("list_saved_projects returns data frame for non-existent folder", {
  skip_if_not(exists("list_saved_projects", mode = "function"),
              "list_saved_projects not available")

  result <- list_saved_projects(folder_path = tempfile("nonexistent"))

  expect_true(is.data.frame(result))
  expect_equal(nrow(result), 0)
  expect_true("name" %in% names(result))
  expect_true("path" %in% names(result))
  expect_true("size_kb" %in% names(result))
  expect_true("modified" %in% names(result))
  expect_true("type" %in% names(result))
})

test_that("list_saved_projects returns data frame for empty folder", {
  skip_if_not(exists("list_saved_projects", mode = "function"),
              "list_saved_projects not available")

  empty_dir <- tempfile("empty_projects")
  dir.create(empty_dir)
  on.exit(unlink(empty_dir, recursive = TRUE), add = TRUE)

  result <- list_saved_projects(folder_path = empty_dir)

  expect_true(is.data.frame(result))
  expect_equal(nrow(result), 0)
})

test_that("list_saved_projects finds .rds files", {
  skip_if_not(exists("list_saved_projects", mode = "function"),
              "list_saved_projects not available")

  test_dir <- tempfile("projects_test")
  dir.create(test_dir)
  on.exit(unlink(test_dir, recursive = TRUE), add = TRUE)

  # Create test files
  saveRDS(list(test = TRUE), file.path(test_dir, "project1.rds"))
  saveRDS(list(test = TRUE), file.path(test_dir, "project2.rds"))
  writeLines("{}", file.path(test_dir, "project3.json"))
  writeLines("not a project", file.path(test_dir, "readme.txt"))

  result <- list_saved_projects(folder_path = test_dir)

  expect_true(is.data.frame(result))
  expect_equal(nrow(result), 3)  # 2 rds + 1 json, not txt
  expect_true(all(result$type %in% c("rds", "json")))
})

test_that("list_saved_projects returns NULL folder_path gracefully", {
  skip_if_not(exists("list_saved_projects", mode = "function"),
              "list_saved_projects not available")

  result <- list_saved_projects(folder_path = NULL)

  expect_true(is.data.frame(result))
  expect_equal(nrow(result), 0)
})

# ============================================================================
# save_project_persistent / load_project_persistent TESTS
# ============================================================================

test_that("save_project_persistent function exists", {
  skip_if_not(exists("save_project_persistent", mode = "function"),
              "save_project_persistent not available")
  expect_true(is.function(save_project_persistent))
})

test_that("load_project_persistent function exists", {
  skip_if_not(exists("load_project_persistent", mode = "function"),
              "load_project_persistent not available")
  expect_true(is.function(load_project_persistent))
})

test_that("save_project_persistent saves and load_project_persistent loads RDS", {
  skip_if_not(exists("save_project_persistent", mode = "function"),
              "save_project_persistent not available")
  skip_if_not(exists("load_project_persistent", mode = "function"),
              "load_project_persistent not available")

  test_dir <- tempfile("save_test")
  dir.create(test_dir)
  on.exit(unlink(test_dir, recursive = TRUE), add = TRUE)

  project_data <- list(
    project_id = "test_proj",
    metadata = list(project_name = "Test Save"),
    data = list(isa_data = list())
  )

  save_result <- save_project_persistent(project_data,
                                          project_name = "test_save",
                                          folder_path = test_dir,
                                          format = "rds")

  expect_true(save_result$success)
  expect_true(!is.null(save_result$path))
  expect_true(file.exists(save_result$path))

  # Load it back
  load_result <- load_project_persistent(save_result$path)
  expect_true(load_result$success)
  expect_equal(load_result$data$project_id, "test_proj")
  expect_equal(load_result$data$metadata$project_name, "Test Save")
})

test_that("save_project_persistent generates project name when missing", {
  skip_if_not(exists("save_project_persistent", mode = "function"),
              "save_project_persistent not available")

  test_dir <- tempfile("save_test2")
  dir.create(test_dir)
  on.exit(unlink(test_dir, recursive = TRUE), add = TRUE)

  project_data <- list(data = list())

  result <- save_project_persistent(project_data,
                                     project_name = NULL,
                                     folder_path = test_dir)

  expect_true(result$success)
  expect_true(grepl("project_", result$filename))
})

test_that("save_project_persistent sanitizes filename", {
  skip_if_not(exists("save_project_persistent", mode = "function"),
              "save_project_persistent not available")

  test_dir <- tempfile("save_test3")
  dir.create(test_dir)
  on.exit(unlink(test_dir, recursive = TRUE), add = TRUE)

  project_data <- list(data = list())

  result <- save_project_persistent(project_data,
                                     project_name = "my project/test<>file",
                                     folder_path = test_dir)

  expect_true(result$success)
  # Filename should not contain special characters
  expect_false(grepl("[/<>]", result$filename))
})

test_that("load_project_persistent handles missing file", {
  skip_if_not(exists("load_project_persistent", mode = "function"),
              "load_project_persistent not available")

  result <- load_project_persistent(tempfile("nonexistent.rds"))

  expect_false(result$success)
  expect_true(grepl("not found", result$error, ignore.case = TRUE))
  expect_null(result$data)
})

# ============================================================================
# delete_project_persistent TESTS
# ============================================================================

test_that("delete_project_persistent function exists", {
  skip_if_not(exists("delete_project_persistent", mode = "function"),
              "delete_project_persistent not available")
  expect_true(is.function(delete_project_persistent))
})

test_that("delete_project_persistent removes file", {
  skip_if_not(exists("delete_project_persistent", mode = "function"),
              "delete_project_persistent not available")

  test_file <- tempfile("delete_test", fileext = ".rds")
  saveRDS(list(test = TRUE), test_file)
  expect_true(file.exists(test_file))

  result <- delete_project_persistent(test_file)
  expect_true(result$success)
  expect_false(file.exists(test_file))
})

test_that("delete_project_persistent handles already-deleted file", {
  skip_if_not(exists("delete_project_persistent", mode = "function"),
              "delete_project_persistent not available")

  result <- delete_project_persistent(tempfile("already_gone.rds"))
  expect_true(result$success)
})

# ============================================================================
# get_display_path TESTS
# ============================================================================

test_that("get_display_path function exists", {
  skip_if_not(exists("get_display_path", mode = "function"),
              "get_display_path not available")
  expect_true(is.function(get_display_path))
})

test_that("get_display_path handles NULL", {
  skip_if_not(exists("get_display_path", mode = "function"),
              "get_display_path not available")

  result <- get_display_path(NULL)
  expect_equal(result, "Not configured")
})

test_that("get_display_path shortens home directory", {
  skip_if_not(exists("get_display_path", mode = "function"),
              "get_display_path not available")

  home <- Sys.getenv("HOME")
  if (home == "") home <- Sys.getenv("USERPROFILE")
  skip_if(home == "", "No home directory available")

  test_path <- file.path(home, "Documents", "test")
  result <- get_display_path(test_path)

  expect_true(grepl("~", result),
              info = "Home directory should be replaced with ~")
})

test_that("get_display_path returns path unchanged if no home match", {
  skip_if_not(exists("get_display_path", mode = "function"),
              "get_display_path not available")

  result <- get_display_path("/some/random/path")
  expect_equal(result, "/some/random/path")
})

# ============================================================================
# set_projects_folder TESTS
# ============================================================================

test_that("set_projects_folder function exists", {
  skip_if_not(exists("set_projects_folder", mode = "function"),
              "set_projects_folder not available")
  expect_true(is.function(set_projects_folder))
})

test_that("set_projects_folder rejects NULL path", {
  skip_if_not(exists("set_projects_folder", mode = "function"),
              "set_projects_folder not available")

  result <- set_projects_folder(NULL)
  expect_false(result$success)
})

test_that("set_projects_folder rejects empty string", {
  skip_if_not(exists("set_projects_folder", mode = "function"),
              "set_projects_folder not available")

  result <- set_projects_folder("")
  expect_false(result$success)
})

# ============================================================================
# find_recoverable_autosaves TESTS
# ============================================================================

test_that("find_recoverable_autosaves function exists", {
  skip_if_not(exists("find_recoverable_autosaves", mode = "function"),
              "find_recoverable_autosaves not available")
  expect_true(is.function(find_recoverable_autosaves))
})

test_that("find_recoverable_autosaves returns data frame", {
  skip_if_not(exists("find_recoverable_autosaves", mode = "function"),
              "find_recoverable_autosaves not available")

  result <- find_recoverable_autosaves()
  expect_true(is.data.frame(result))
})
