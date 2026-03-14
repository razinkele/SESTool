# tests/testthat/test-module-signatures.R
# Tests for module signature compliance (P1 Maintainability)
#
# These tests verify:
# 1. All module servers use standard parameter names
# 2. Required parameters are present
# 3. Parameter order follows convention

library(testthat)

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

#' Extract module server function signatures from a file
#' @param file_path Path to the R file
#' @return List of function signatures found
extract_server_signatures <- function(file_path) {
  if (!file.exists(file_path)) {
    return(list())
  }

  content <- readLines(file_path, warn = FALSE)

  # Find lines with server function definitions
  server_pattern <- "([a-z_]+)_server\\s*(<-|=)\\s*function\\s*\\(([^)]+)\\)"

  signatures <- list()

  for (i in seq_along(content)) {
    line <- content[i]

    # Handle multi-line signatures
    if (grepl("_server\\s*(<-|=)\\s*function\\s*\\(", line) && !grepl("\\)\\s*\\{", line)) {
      # Read next lines to get full signature
      full_sig <- line
      j <- i + 1
      while (j <= length(content) && !grepl("\\)\\s*\\{", full_sig)) {
        full_sig <- paste(full_sig, content[j])
        j <- j + 1
      }
      line <- full_sig
    }

    match <- regmatches(line, regexec(server_pattern, line, perl = TRUE))

    if (length(match[[1]]) > 0) {
      func_name <- match[[1]][2]
      params_str <- match[[1]][4]

      # Clean up parameters
      params_str <- gsub("\\s+", " ", params_str)
      params <- trimws(strsplit(params_str, ",")[[1]])

      signatures[[func_name]] <- list(
        name = paste0(func_name, "_server"),
        params = params,
        file = basename(file_path),
        line = i
      )
    }
  }

  signatures
}

#' Check if signature is compliant with standard
#' @param sig Signature object from extract_server_signatures
#' @return List with compliant (logical) and issues (character vector)
check_signature_compliance <- function(sig) {
  issues <- c()

  # Required parameters
  params_lower <- tolower(sig$params)

  # Check for 'id' as first parameter
  if (length(sig$params) < 1 || !grepl("^id$", sig$params[1], ignore.case = TRUE)) {
    issues <- c(issues, "'id' must be first parameter")
  }

  # Check for project_data_reactive (not just 'project_data')
  has_project_data_reactive <- any(grepl("project_data_reactive", sig$params))
  has_project_data_only <- any(grepl("^project_data$", sig$params))

  if (has_project_data_only && !has_project_data_reactive) {
    issues <- c(issues, "Use 'project_data_reactive' instead of 'project_data'")
  }

  # Check for i18n
  has_i18n <- any(grepl("i18n", sig$params))
  if (!has_i18n) {
    issues <- c(issues, "Missing 'i18n' parameter")
  }

  # Check parameter order (id, project_data_reactive, i18n should be in that order)
  if (has_project_data_reactive && has_i18n) {
    project_idx <- which(grepl("project_data_reactive", sig$params))
    i18n_idx <- which(grepl("i18n", sig$params))

    if (length(project_idx) > 0 && length(i18n_idx) > 0) {
      if (project_idx > 2) {
        issues <- c(issues, "'project_data_reactive' should be second parameter")
      }
      if (i18n_idx < project_idx) {
        issues <- c(issues, "'i18n' should come after 'project_data_reactive'")
      }
    }
  }

  list(
    compliant = length(issues) == 0,
    issues = issues
  )
}

# ============================================================================
# SIGNATURE EXTRACTION TESTS
# ============================================================================

test_that("extract_server_signatures finds server functions", {
  # Create temp file with server function
  temp_file <- tempfile(fileext = ".R")
  writeLines(c(
    "my_module_server <- function(id, project_data_reactive, i18n, event_bus = NULL) {",
    "  moduleServer(id, function(input, output, session) {",
    "    # Server code",
    "  })",
    "}"
  ), temp_file)
  on.exit(unlink(temp_file))

  sigs <- extract_server_signatures(temp_file)

  expect_length(sigs, 1)
  expect_equal(sigs[[1]]$name, "my_module_server")
  expect_true("id" %in% sigs[[1]]$params)
})

test_that("extract_server_signatures handles multi-line signatures", {
  temp_file <- tempfile(fileext = ".R")
  writeLines(c(
    "complex_server <- function(id, project_data_reactive,",
    "                           i18n, parent_session = NULL,",
    "                           event_bus = NULL) {",
    "  # Server code",
    "}"
  ), temp_file)
  on.exit(unlink(temp_file))

  sigs <- extract_server_signatures(temp_file)

  expect_length(sigs, 1)
  expect_equal(sigs[[1]]$name, "complex_server")
})

# ============================================================================
# COMPLIANCE CHECK TESTS
# ============================================================================

test_that("check_signature_compliance detects missing id", {
  sig <- list(
    name = "test_server",
    params = c("data", "i18n"),
    file = "test.R",
    line = 1
  )

  result <- check_signature_compliance(sig)

  expect_false(result$compliant)
  expect_true(any(grepl("id", result$issues)))
})

test_that("check_signature_compliance detects project_data without _reactive", {
  sig <- list(
    name = "test_server",
    params = c("id", "project_data", "i18n"),
    file = "test.R",
    line = 1
  )

  result <- check_signature_compliance(sig)

  expect_false(result$compliant)
  expect_true(any(grepl("project_data_reactive", result$issues)))
})

test_that("check_signature_compliance detects missing i18n", {
  sig <- list(
    name = "test_server",
    params = c("id", "project_data_reactive"),
    file = "test.R",
    line = 1
  )

  result <- check_signature_compliance(sig)

  expect_false(result$compliant)
  expect_true(any(grepl("i18n", result$issues)))
})

test_that("check_signature_compliance accepts valid signature", {
  sig <- list(
    name = "test_server",
    params = c("id", "project_data_reactive", "i18n", "event_bus = NULL"),
    file = "test.R",
    line = 1
  )

  result <- check_signature_compliance(sig)

  expect_true(result$compliant)
  expect_length(result$issues, 0)
})

test_that("check_signature_compliance accepts extended signature", {
  sig <- list(
    name = "test_server",
    params = c("id", "project_data_reactive", "i18n", "event_bus = NULL", "parent_session = NULL"),
    file = "test.R",
    line = 1
  )

  result <- check_signature_compliance(sig)

  expect_true(result$compliant)
})

# ============================================================================
# ACTUAL MODULE COMPLIANCE TESTS
# ============================================================================

test_that("isa_data_entry_server has compliant signature", {
  skip_if_not(file.exists("modules/isa_data_entry_module.R"),
              "Module file not found")

  sigs <- extract_server_signatures("modules/isa_data_entry_module.R")

  expect_true(length(sigs) > 0)

  # Find the main server function
  main_sig <- sigs[["isa_data_entry"]]
  skip_if(is.null(main_sig), "isa_data_entry_server not found")

  result <- check_signature_compliance(main_sig)

  if (!result$compliant) {
    fail(paste("isa_data_entry_server issues:", paste(result$issues, collapse = "; ")))
  }

  expect_true(result$compliant)
})

test_that("analysis modules have event_bus parameter", {
  analysis_files <- c(
    "modules/analysis_loops.R",
    "modules/analysis_leverage.R",
    "modules/analysis_simplify.R"
  )

  for (file in analysis_files) {
    skip_if_not(file.exists(file), paste("File not found:", file))

    sigs <- extract_server_signatures(file)

    for (sig_name in names(sigs)) {
      sig <- sigs[[sig_name]]

      # These analysis modules should have event_bus
      has_event_bus <- any(grepl("event_bus", sig$params))

      if (!has_event_bus) {
        fail(paste(sig$name, "in", file, "is missing event_bus parameter"))
      }

      expect_true(has_event_bus,
                  info = paste(sig$name, "should have event_bus"))
    }
  }
})

test_that("all modules use project_data_reactive not project_data", {
  module_files <- list.files("modules", pattern = "\\.R$", full.names = TRUE)

  skip_if(length(module_files) == 0, "No module files found")

  issues_found <- character(0)

  for (file in module_files) {
    sigs <- extract_server_signatures(file)

    for (sig_name in names(sigs)) {
      sig <- sigs[[sig_name]]

      # Check for project_data without _reactive
      has_wrong_name <- any(grepl("^project_data$", sig$params))
      has_correct_name <- any(grepl("project_data_reactive", sig$params))

      if (has_wrong_name && !has_correct_name) {
        issues_found <- c(issues_found,
                          paste(sig$name, "in", basename(file),
                                "uses 'project_data' instead of 'project_data_reactive'"))
      }
    }
  }

  if (length(issues_found) > 0) {
    fail(paste("Non-compliant signatures found:\n",
               paste(issues_found, collapse = "\n")))
  }

  expect_length(issues_found, 0)
})

test_that("all modules have i18n parameter", {
  module_files <- list.files("modules", pattern = "\\.R$", full.names = TRUE)

  skip_if(length(module_files) == 0, "No module files found")

  missing_i18n <- character(0)

  for (file in module_files) {
    sigs <- extract_server_signatures(file)

    for (sig_name in names(sigs)) {
      sig <- sigs[[sig_name]]

      has_i18n <- any(grepl("i18n", sig$params))

      if (!has_i18n) {
        missing_i18n <- c(missing_i18n,
                          paste(sig$name, "in", basename(file)))
      }
    }
  }

  if (length(missing_i18n) > 0) {
    fail(paste("Modules missing i18n:\n",
               paste(missing_i18n, collapse = "\n")))
  }

  expect_length(missing_i18n, 0)
})

# ============================================================================
# DOCUMENTATION COMPLIANCE
# ============================================================================

test_that("MODULE_SIGNATURE_STANDARD.md exists", {
  doc_path <- "docs/MODULE_SIGNATURE_STANDARD.md"

  skip_if_not(file.exists(doc_path), "Standard document not found")

  content <- readLines(doc_path)

  # Check for key sections
  expect_true(any(grepl("project_data_reactive", content)),
              "Document should mention project_data_reactive")
  expect_true(any(grepl("i18n", content)),
              "Document should mention i18n")
  expect_true(any(grepl("event_bus", content)),
              "Document should mention event_bus")
})
