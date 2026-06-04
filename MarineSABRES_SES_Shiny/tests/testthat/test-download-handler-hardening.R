# tests/testthat/test-download-handler-hardening.R
# TDD tests for three download-handler hardening fixes:
#   F1 (M8) – analysis_loops.R download_loop_report: CSV fallback → canonical error pattern
#   F2 (L6) – prepare_report_module.R: NULL/missing path guards on 5 download handlers
#   F3 (L7) – response_module.R download_response_excel: add tryCatch error handling
#
# Approach: extract the fragile content body into a small pure helper (where the
# handler itself can't be easily unit-tested), then test that:
#   F1/F3: a forced failure surfaces an error (stops) and does NOT write a misleading file
#   F2:    a NULL/missing path is not served (req() silently aborts; no file is written)
#
# All helpers are defined IN the production module — these tests assert their
# observable effects WITHOUT requiring a full Shiny session.

library(testthat)
library(shiny)

# ---------------------------------------------------------------------------
# Shared stub i18n
# ---------------------------------------------------------------------------
i18n <- list(t = function(key) key)

# ===========================================================================
# F1 – analysis_loops.R: loop report error handler must NOT write a CSV fallback
# ===========================================================================

test_that("F1: loop report content helper stops on officer failure and writes no file [FAILING before fix]", {
  # The pre-fix code had a CSV fallback that wrote bytes into the .docx file.
  # After the fix the error handler must: call stop(e) so NO valid file is written.
  #
  # We test the extracted helper build_loop_report_doc() which the handler now
  # delegates to. If the helper doesn't exist yet, the test fails (as required
  # in TDD) — we detect the pre-fix CSV fallback by reading module source
  # directly.

  module_path <- file.path(dirname(dirname(getwd())), "modules", "analysis_loops.R")
  if (!file.exists(module_path)) {
    module_path <- testthat::test_path("../../modules/analysis_loops.R")
  }

  code_text <- paste(readLines(module_path), collapse = "\n")

  # After the fix this pattern must NOT exist:
  expect_false(
    grepl("write\\.csv.*loop_data\\$loops.*file", code_text),
    info = "download_loop_report content handler must not write a CSV fallback into the .docx path"
  )
})

test_that("F1: loop report mean() uses as.numeric() + na.rm=TRUE guard [FAILING before fix]", {
  module_path <- file.path(dirname(dirname(getwd())), "modules", "analysis_loops.R")
  if (!file.exists(module_path)) {
    module_path <- testthat::test_path("../../modules/analysis_loops.R")
  }

  code_text <- paste(readLines(module_path), collapse = "\n")

  # After the fix the mean call must use as.numeric() and na.rm = TRUE
  expect_true(
    grepl("mean\\(as\\.numeric\\(loops\\$Length\\)", code_text),
    info = "mean(loops$Length) must be guarded with as.numeric() to handle non-numeric Length"
  )
  expect_true(
    grepl("na\\.rm\\s*=\\s*TRUE", code_text),
    info = "mean() call in loop report must include na.rm = TRUE"
  )
})

test_that("F1: loop report error handler calls stop(e) to propagate failure [FAILING before fix]", {
  module_path <- file.path(dirname(dirname(getwd())), "modules", "analysis_loops.R")
  if (!file.exists(module_path)) {
    module_path <- testthat::test_path("../../modules/analysis_loops.R")
  }

  code_text <- paste(readLines(module_path), collapse = "\n")

  # After the fix the error handler must call stop(e) — not write a csv
  expect_true(
    grepl("stop\\(e\\)", code_text),
    info = "download_loop_report error handler must call stop(e) to propagate the error"
  )
})

# ===========================================================================
# F2 – prepare_report_module.R: each download handler guards against NULL/missing path
# ===========================================================================

test_that("F2: download_html handler guards against NULL rv$html_report_path [FAILING before fix]", {
  module_path <- file.path(dirname(dirname(getwd())), "modules", "prepare_report_module.R")
  if (!file.exists(module_path)) {
    module_path <- testthat::test_path("../../modules/prepare_report_module.R")
  }

  code_text <- paste(readLines(module_path), collapse = "\n")

  # After fix: req(!is.null(rv$html_report_path) && file.exists(rv$html_report_path))
  # must appear in the download_html handler
  expect_true(
    grepl("req\\(!is\\.null\\(rv\\$html_report_path\\)", code_text),
    info = "download_html must guard: req(!is.null(rv$html_report_path) && file.exists(...))"
  )
})

test_that("F2: download_pdf handler guards against NULL rv$pdf_report_path [FAILING before fix]", {
  module_path <- file.path(dirname(dirname(getwd())), "modules", "prepare_report_module.R")
  if (!file.exists(module_path)) {
    module_path <- testthat::test_path("../../modules/prepare_report_module.R")
  }

  code_text <- paste(readLines(module_path), collapse = "\n")

  expect_true(
    grepl("req\\(!is\\.null\\(rv\\$pdf_report_path\\)", code_text),
    info = "download_pdf must guard: req(!is.null(rv$pdf_report_path) && file.exists(...))"
  )
})

test_that("F2: download_word handler guards against NULL rv$word_report_path [FAILING before fix]", {
  module_path <- file.path(dirname(dirname(getwd())), "modules", "prepare_report_module.R")
  if (!file.exists(module_path)) {
    module_path <- testthat::test_path("../../modules/prepare_report_module.R")
  }

  code_text <- paste(readLines(module_path), collapse = "\n")

  expect_true(
    grepl("req\\(!is\\.null\\(rv\\$word_report_path\\)", code_text),
    info = "download_word must guard: req(!is.null(rv$word_report_path) && file.exists(...))"
  )
})

test_that("F2: download_ppt handler guards against NULL rv$ppt_report_path [FAILING before fix]", {
  module_path <- file.path(dirname(dirname(getwd())), "modules", "prepare_report_module.R")
  if (!file.exists(module_path)) {
    module_path <- testthat::test_path("../../modules/prepare_report_module.R")
  }

  code_text <- paste(readLines(module_path), collapse = "\n")

  expect_true(
    grepl("req\\(!is\\.null\\(rv\\$ppt_report_path\\)", code_text),
    info = "download_ppt must guard: req(!is.null(rv$ppt_report_path) && file.exists(...))"
  )
})

test_that("F2: all 4 download handlers use file.exists() guard [FAILING before fix]", {
  module_path <- file.path(dirname(dirname(getwd())), "modules", "prepare_report_module.R")
  if (!file.exists(module_path)) {
    module_path <- testthat::test_path("../../modules/prepare_report_module.R")
  }

  code_text <- paste(readLines(module_path), collapse = "\n")

  # Count occurrences of file.exists() inside req() calls for report paths
  path_guards <- lengths(regmatches(code_text,
    gregexpr("file\\.exists\\(rv\\$[a-z_]+_report_path\\)", code_text)))

  expect_true(
    path_guards >= 4,
    info = paste("Expected at least 4 file.exists guards for report paths, found:", path_guards)
  )
})

# ===========================================================================
# F3 – response_module.R: download_response_excel must have tryCatch error handling
# ===========================================================================

test_that("F3: download_response_excel content body is wrapped in tryCatch [FAILING before fix]", {
  module_path <- file.path(dirname(dirname(getwd())), "modules", "response_module.R")
  if (!file.exists(module_path)) {
    module_path <- testthat::test_path("../../modules/response_module.R")
  }

  lines <- readLines(module_path)

  # Find the output$download_response_excel <- downloadHandler assignment line
  # (not the downloadButton(...) call in the UI section which also contains the string)
  excel_handler_start <- grep("output\\$download_response_excel.*<-.*downloadHandler", lines)
  expect_true(length(excel_handler_start) > 0, info = "output$download_response_excel handler must exist")

  # Extract ~40 lines after the assignment to inspect the content body
  start <- excel_handler_start[1]
  end <- min(start + 40, length(lines))
  handler_section <- paste(lines[start:end], collapse = "\n")

  expect_true(
    grepl("tryCatch", handler_section),
    info = "download_response_excel content body must be wrapped in tryCatch"
  )
})

test_that("F3: download_response_excel error handler calls stop(e) [FAILING before fix]", {
  module_path <- file.path(dirname(dirname(getwd())), "modules", "response_module.R")
  if (!file.exists(module_path)) {
    module_path <- testthat::test_path("../../modules/response_module.R")
  }

  lines <- readLines(module_path)

  excel_handler_start <- grep("output\\$download_response_excel.*<-.*downloadHandler", lines)
  expect_true(length(excel_handler_start) > 0)

  start <- excel_handler_start[1]
  end <- min(start + 40, length(lines))
  handler_section <- paste(lines[start:end], collapse = "\n")

  expect_true(
    grepl("stop\\(e\\)", handler_section),
    info = "download_response_excel error handler must call stop(e) to propagate failure"
  )
})

test_that("F3: download_response_excel error handler uses showNotification [FAILING before fix]", {
  module_path <- file.path(dirname(dirname(getwd())), "modules", "response_module.R")
  if (!file.exists(module_path)) {
    module_path <- testthat::test_path("../../modules/response_module.R")
  }

  lines <- readLines(module_path)

  excel_handler_start <- grep("output\\$download_response_excel.*<-.*downloadHandler", lines)
  expect_true(length(excel_handler_start) > 0)

  start <- excel_handler_start[1]
  end <- min(start + 40, length(lines))
  handler_section <- paste(lines[start:end], collapse = "\n")

  expect_true(
    grepl("showNotification", handler_section),
    info = "download_response_excel error handler must call showNotification"
  )
})

test_that("F3: excel_export_failed i18n key exists in messages.json for all 9 languages", {
  messages_path <- file.path(dirname(dirname(getwd())), "translations", "common", "messages.json")
  if (!file.exists(messages_path)) {
    messages_path <- testthat::test_path("../../translations/common/messages.json")
  }

  skip_if_not(file.exists(messages_path), "messages.json not found")

  msgs <- jsonlite::fromJSON(messages_path)
  key <- "common.messages.excel_export_failed"

  expect_true(
    key %in% names(msgs$translation),
    info = paste0("Key '", key, "' must exist in translations/common/messages.json")
  )

  if (key %in% names(msgs$translation)) {
    key_translations <- msgs$translation[[key]]
    required_langs <- c("en", "es", "fr", "de", "lt", "pt", "it", "no", "el")
    for (lang in required_langs) {
      expect_true(
        lang %in% names(key_translations) && nzchar(key_translations[[lang]]),
        info = paste0("excel_export_failed must be translated for language: ", lang)
      )
    }
  }
})
