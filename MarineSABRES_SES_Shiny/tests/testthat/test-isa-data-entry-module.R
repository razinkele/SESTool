# test-isa-data-entry-module.R
# Unit tests for modules/isa_data_entry_module.R

library(testthat)
library(shiny)

# Source the module under test (modules/ are not auto-loaded by global.R).
# Using sys.source(envir = .GlobalEnv) to override any outdated stub in
# helper-stubs.R (see also: test-entry-point-module.R commit 2757e05).
source_for_test("modules/isa_data_entry_module.R")
i18n <- list(t = function(key) key)

# ============================================================================
# UI FUNCTION TESTS
# ============================================================================

test_that("isa_data_entry_ui function exists", {
  skip_if_not(exists("isa_data_entry_ui", mode = "function"),
              "isa_data_entry_ui not available")
  expect_true(is.function(isa_data_entry_ui))
})

test_that("isa_data_entry_ui returns valid shiny tags", {
  skip_if_not(exists("isa_data_entry_ui", mode = "function"),
              "isa_data_entry_ui not available")
  params <- names(formals(isa_data_entry_ui))
  ui <- if ("i18n" %in% params) isa_data_entry_ui("test_isade", i18n) else isa_data_entry_ui("test_isade")
  expect_true(
    inherits(ui, "shiny.tag") || inherits(ui, "shiny.tag.list"),
    info = "isa_data_entry_ui must return shiny.tag or shiny.tag.list"
  )
})

# ============================================================================
# SERVER FUNCTION TESTS
# ============================================================================

test_that("isa_data_entry_server function exists", {
  skip_if_not(exists("isa_data_entry_server", mode = "function"),
              "isa_data_entry_server not available")
  expect_true(is.function(isa_data_entry_server))
})

test_that("isa_data_entry_server signature includes all required params", {
  skip_if_not(exists("isa_data_entry_server", mode = "function"),
              "isa_data_entry_server not available")
  params <- names(formals(isa_data_entry_server))
  for (p in c("id", "project_data_reactive", "i18n", "event_bus")) {
    expect_true(p %in% params, info = paste0("Missing parameter: ", p))
  }
})

test_that("isa_data_entry_server event_bus defaults to NULL", {
  skip_if_not(exists("isa_data_entry_server", mode = "function"),
              "isa_data_entry_server not available")
  default <- formals(isa_data_entry_server)$event_bus
  expect_true(is.null(default) || identical(as.character(default), "NULL"),
              info = "event_bus must default to NULL for backward compatibility")
})

# ============================================================================
# TASK 6: downloadHandler tryCatch error-handling tests
# ============================================================================

test_that("ISA downloadHandler content() bodies reference context_isa_download", {
  expect_context_key_in_file(
    "modules/isa_data_entry_module.R",
    "context_isa_download",
    info = "ISA downloadHandler content() bodies must emit format_user_error(context_key='common.messages.context_isa_download') in their error handler."
  )
})

test_that("ALL 4 ISA downloadHandlers wrap content in tryCatch + stop(e)", {
  td <- getwd()
  root <- if (basename(td) == "testthat") dirname(dirname(td)) else td
  src <- paste(readLines(file.path(root, "modules/isa_data_entry_module.R"),
                         warn = FALSE), collapse = "\n")
  stop_e_count <- length(gregexpr("stop\\(e\\)", src)[[1]])
  expect_true(
    stop_e_count >= 4,
    info = sprintf("Expected >= 4 stop(e) calls (one per downloadHandler catch). Found %d. After showNotification, each catch must re-throw via stop(e) so Shiny aborts the download cleanly.", stop_e_count)
  )
  context_key_count <- length(gregexpr("context_isa_download", src, fixed = TRUE)[[1]])
  expect_true(
    context_key_count >= 4,
    info = sprintf("Expected >= 4 context_isa_download references (one per downloadHandler catch). Found %d.", context_key_count)
  )
})

# ============================================================================
# TASK 7: withProgress wrapping tests
# ============================================================================

test_that("ISA download handlers wrap generation in withProgress (OUTSIDE tryCatch)", {
  td <- getwd()
  root <- if (basename(td) == "testthat") dirname(dirname(td)) else td
  src <- paste(readLines(file.path(root, "modules/isa_data_entry_module.R"),
                         warn = FALSE), collapse = "\n")
  # Assert withProgress comes BEFORE tryCatch in download handlers
  expect_true(
    grepl("withProgress\\([\\s\\S]{0,200}?tryCatch", src, perl = TRUE),
    info = "ISA download handlers must wrap content() generation in withProgress() AROUND the tryCatch (nesting matters: withProgress outer, tryCatch inner — codebase precedent in modules/analysis_*.R). Plan v2 Task 7."
  )
})

# ============================================================================
# TASK 7: adjacency_matrices + user_edited_matrices initialization tests
# ============================================================================

test_that("isa_data reactiveValues constructor pre-creates 6 named adjacency/user_edited slots", {
  td <- getwd()
  root <- if (basename(td) == "testthat") dirname(dirname(td)) else td
  src <- paste(readLines(file.path(root, "modules", "isa_data_entry_module.R"),
                         warn = FALSE), collapse = "\n")
  expect_true(grepl("adjacency_matrices\\s*=\\s*list\\(", src, perl = TRUE),
              info = "adjacency_matrices must be initialized as a list(...)")
  expect_true(grepl("user_edited_matrices\\s*=\\s*list\\(", src, perl = TRUE),
              info = "user_edited_matrices must be initialized as a list(...)")
  for (slot in c("es_gb", "mpf_es", "p_mpf", "a_p", "d_a", "gb_d")) {
    expect_true(grepl(sprintf("%s\\s*=\\s*NULL", slot), src, perl = TRUE),
                info = sprintf("Slot '%s' must be pre-created as NULL", slot))
  }
})

# ============================================================================
# TASK 8: es_gb matrix rebuild via rebuild_matrix_from_linked in save_ex2a
# ============================================================================

test_that("save_ex2a calls rebuild_matrix_from_linked for es_gb inside an isolated tryCatch", {
  td <- getwd()
  root <- if (basename(td) == "testthat") dirname(dirname(td)) else td
  src <- readLines(file.path(root, "modules", "isa_data_entry_module.R"), warn = FALSE)
  observer_starts <- grep("observeEvent\\(input\\$save_ex[0-9a-z]+", src)
  start_idx <- grep("observeEvent\\(input\\$save_ex2a\\b", src, perl = TRUE)[1]
  next_starts <- observer_starts[observer_starts > start_idx]
  end_idx <- if (length(next_starts) > 0) next_starts[1] - 1 else length(src)
  block <- paste(src[start_idx:end_idx], collapse = "\n")
  expect_true(grepl("rebuild_matrix_from_linked", block, fixed = TRUE),
              info = "save_ex2a must call rebuild_matrix_from_linked")
  expect_true(grepl("\"es_gb\"|'es_gb'", block, perl = TRUE),
              info = "save_ex2a must reference es_gb matrix slot")
  expect_true(grepl("context_matrix_rebuild", block, fixed = TRUE),
              info = "rebuild call must be in isolated tryCatch with context_matrix_rebuild i18n key")
})

test_that("save_ex2b/3/4/5 each call rebuild_matrix_from_linked inside isolated tryCatch", {
  td <- getwd()
  root <- if (basename(td) == "testthat") dirname(dirname(td)) else td
  src <- readLines(file.path(root, "modules", "isa_data_entry_module.R"), warn = FALSE)
  observer_starts <- grep("observeEvent\\(input\\$save_ex[0-9a-z]+", src)
  cases <- list(
    list(obs = "save_ex2b", mat = "mpf_es"),
    list(obs = "save_ex3",  mat = "p_mpf"),
    list(obs = "save_ex4",  mat = "a_p"),
    list(obs = "save_ex5",  mat = "d_a")
  )
  for (case in cases) {
    start_idx <- grep(sprintf("observeEvent\\(input\\$%s\\b", case$obs), src, perl = TRUE)[1]
    next_starts <- observer_starts[observer_starts > start_idx]
    end_idx <- if (length(next_starts) > 0) next_starts[1] - 1 else length(src)
    block <- paste(src[start_idx:end_idx], collapse = "\n")
    expect_true(grepl("rebuild_matrix_from_linked", block, fixed = TRUE),
                info = sprintf("%s must call rebuild_matrix_from_linked", case$obs))
    expect_true(grepl(sprintf("\"%s\"|'%s'", case$mat, case$mat), block, perl = TRUE),
                info = sprintf("%s must reference matrix slot '%s'", case$obs, case$mat))
    expect_true(grepl("context_matrix_rebuild", block, fixed = TRUE),
                info = sprintf("%s rebuild must use isolated tryCatch", case$obs))
  }
})

# ============================================================================
# TASK 9b: save_ex6 mirrors gb_d into user_edited_matrices
# ============================================================================

test_that("save_ex6 also writes user_edited_matrices[['gb_d']] for cells it sets", {
  td <- getwd()
  root <- if (basename(td) == "testthat") dirname(dirname(td)) else td
  src <- readLines(file.path(root, "modules", "isa_data_entry_module.R"), warn = FALSE)
  observer_starts <- grep("observeEvent\\(input\\$save_ex[0-9a-z]+", src)
  start_idx <- grep("observeEvent\\(input\\$save_ex6\\b", src, perl = TRUE)[1]
  next_starts <- observer_starts[observer_starts > start_idx]
  end_idx <- if (length(next_starts) > 0) next_starts[1] - 1 else length(src)
  block <- paste(src[start_idx:end_idx], collapse = "\n")
  expect_true(grepl("user_edited_matrices\\[\\[\"gb_d\"\\]\\]", block, perl = TRUE),
              info = "save_ex6 must initialize/update user_edited_matrices[['gb_d']] for cells it writes")
})
