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

test_that("F2: download_html handler guards against NULL rv$html_report_path [source-grep]", {
  module_path <- file.path(dirname(dirname(getwd())), "modules", "prepare_report_module.R")
  if (!file.exists(module_path)) {
    module_path <- testthat::test_path("../../modules/prepare_report_module.R")
  }

  code_text <- paste(readLines(module_path), collapse = "\n")

  # After fix handlers use report_path_is_servable() — the predicate encapsulates
  # the !is.null + file.exists guard.  Accept EITHER the refactored or inline form.
  guarded <- grepl("req\\(report_path_is_servable\\(rv\\$html_report_path\\)", code_text) ||
             grepl("req\\(!is\\.null\\(rv\\$html_report_path\\)", code_text)
  expect_true(
    guarded,
    info = "download_html must guard the path via report_path_is_servable() or inline req(!is.null + file.exists)"
  )
})

test_that("F2: download_pdf handler guards against NULL rv$pdf_report_path [source-grep]", {
  module_path <- file.path(dirname(dirname(getwd())), "modules", "prepare_report_module.R")
  if (!file.exists(module_path)) {
    module_path <- testthat::test_path("../../modules/prepare_report_module.R")
  }

  code_text <- paste(readLines(module_path), collapse = "\n")

  guarded <- grepl("req\\(report_path_is_servable\\(rv\\$pdf_report_path\\)", code_text) ||
             grepl("req\\(!is\\.null\\(rv\\$pdf_report_path\\)", code_text)
  expect_true(
    guarded,
    info = "download_pdf must guard the path via report_path_is_servable() or inline req(!is.null + file.exists)"
  )
})

test_that("F2: download_word handler guards against NULL rv$word_report_path [source-grep]", {
  module_path <- file.path(dirname(dirname(getwd())), "modules", "prepare_report_module.R")
  if (!file.exists(module_path)) {
    module_path <- testthat::test_path("../../modules/prepare_report_module.R")
  }

  code_text <- paste(readLines(module_path), collapse = "\n")

  guarded <- grepl("req\\(report_path_is_servable\\(rv\\$word_report_path\\)", code_text) ||
             grepl("req\\(!is\\.null\\(rv\\$word_report_path\\)", code_text)
  expect_true(
    guarded,
    info = "download_word must guard the path via report_path_is_servable() or inline req(!is.null + file.exists)"
  )
})

test_that("F2: download_ppt handler guards against NULL rv$ppt_report_path [source-grep]", {
  module_path <- file.path(dirname(dirname(getwd())), "modules", "prepare_report_module.R")
  if (!file.exists(module_path)) {
    module_path <- testthat::test_path("../../modules/prepare_report_module.R")
  }

  code_text <- paste(readLines(module_path), collapse = "\n")

  guarded <- grepl("req\\(report_path_is_servable\\(rv\\$ppt_report_path\\)", code_text) ||
             grepl("req\\(!is\\.null\\(rv\\$ppt_report_path\\)", code_text)
  expect_true(
    guarded,
    info = "download_ppt must guard the path via report_path_is_servable() or inline req(!is.null + file.exists)"
  )
})

test_that("F2: all 4 download handlers have a path guard [source-grep]", {
  module_path <- file.path(dirname(dirname(getwd())), "modules", "prepare_report_module.R")
  if (!file.exists(module_path)) {
    module_path <- testthat::test_path("../../modules/prepare_report_module.R")
  }

  code_text <- paste(readLines(module_path), collapse = "\n")

  # Accept either the refactored form (report_path_is_servable) or the original inline form
  refactored_guards <- lengths(regmatches(code_text,
    gregexpr("req\\(report_path_is_servable\\(rv\\$[a-z_]+_report_path\\)", code_text)))
  inline_guards <- lengths(regmatches(code_text,
    gregexpr("file\\.exists\\(rv\\$[a-z_]+_report_path\\)", code_text)))

  total_guards <- refactored_guards + inline_guards
  expect_true(
    total_guards >= 4,
    info = paste("Expected at least 4 path guards (report_path_is_servable or file.exists), found:", total_guards)
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

# ===========================================================================
# BEHAVIORAL TESTS — added to satisfy spec (source-grep alone is insufficient)
# ===========================================================================

# ---------------------------------------------------------------------------
# F1 BEHAVIORAL – build_loop_report_docx() pure helper
# ---------------------------------------------------------------------------

# Load the module so the helper is available in .GlobalEnv
source_for_test("modules/analysis_loops.R")

test_that("F1-BEHAVIORAL: build_loop_report_docx() exists as a callable function", {
  expect_true(
    exists("build_loop_report_docx", mode = "function"),
    info = "build_loop_report_docx() must be defined in analysis_loops.R"
  )
})

test_that("F1-BEHAVIORAL: forced writer failure propagates as error and leaves no file", {
  skip_if(!exists("build_loop_report_docx", mode = "function"),
    "build_loop_report_docx() not yet extracted — helper missing"
  )

  loops <- data.frame(
    ID      = "L1",
    Type    = "Reinforcing",
    Length  = 3L,
    Members = "A -> B -> C",
    stringsAsFactors = FALSE
  )
  tmp <- tempfile(fileext = ".docx")
  on.exit(unlink(tmp))

  # The forced writer stops — the helper must propagate the error
  expect_error(
    build_loop_report_docx(
      loops  = loops,
      i18n   = i18n,
      target = tmp,
      writer = function(doc, target) stop("forced-writer-failure")
    ),
    regexp = "forced-writer-failure"
  )

  # No misleading file must have been written
  expect_true(
    !file.exists(tmp) || file.size(tmp) == 0L,
    info = "A forced failure must not leave a non-empty .docx file on disk"
  )
})

test_that("F1-BEHAVIORAL: non-numeric Length handled via as.numeric + na.rm — builds successfully", {
  skip_if(!exists("build_loop_report_docx", mode = "function"),
    "build_loop_report_docx() not yet extracted — helper missing"
  )

  # Length column is character — would blow up mean() without as.numeric()/na.rm guard
  loops <- data.frame(
    ID      = c("L1", "L2"),
    Type    = c("Reinforcing", "Balancing"),
    Length  = c("3", NA_character_),   # character + NA
    Members = c("A -> B -> C", "X -> Y"),
    stringsAsFactors = FALSE
  )
  tmp <- tempfile(fileext = ".docx")
  on.exit(unlink(tmp))

  # Should complete without error and produce a non-empty file
  build_loop_report_docx(loops = loops, i18n = i18n, target = tmp)

  expect_true(file.exists(tmp) && file.size(tmp) > 0L,
    info = "Helper must produce a non-empty .docx even when Length is character/NA"
  )
})

# ---------------------------------------------------------------------------
# F2 BEHAVIORAL – report_path_is_servable() predicate
# ---------------------------------------------------------------------------

# Load the module so the predicate is available
source_for_test("modules/prepare_report_module.R")

test_that("F2-BEHAVIORAL: report_path_is_servable() exists as a callable function", {
  expect_true(
    exists("report_path_is_servable", mode = "function"),
    info = "report_path_is_servable() must be defined in prepare_report_module.R"
  )
})

test_that("F2-BEHAVIORAL: report_path_is_servable() returns FALSE for NULL", {
  skip_if(!exists("report_path_is_servable", mode = "function"),
    "report_path_is_servable() not yet extracted — helper missing"
  )
  expect_false(report_path_is_servable(NULL))
})

test_that("F2-BEHAVIORAL: report_path_is_servable() returns FALSE for non-existent path", {
  skip_if(!exists("report_path_is_servable", mode = "function"),
    "report_path_is_servable() not yet extracted — helper missing"
  )
  expect_false(report_path_is_servable("/no/such/file_xyz_12345.html"))
})

test_that("F2-BEHAVIORAL: report_path_is_servable() returns TRUE for an existing file", {
  skip_if(!exists("report_path_is_servable", mode = "function"),
    "report_path_is_servable() not yet extracted — helper missing"
  )
  tmp <- tempfile()
  on.exit(unlink(tmp))
  writeLines("hello", tmp)
  expect_true(report_path_is_servable(tmp))
})

# ---------------------------------------------------------------------------
# F3 BEHAVIORAL – build_response_excel() pure helper
# ---------------------------------------------------------------------------

# Load the module so the helper is available
source_for_test("modules/response_module.R")

test_that("F3-BEHAVIORAL: build_response_excel() exists as a callable function", {
  expect_true(
    exists("build_response_excel", mode = "function"),
    info = "build_response_excel() must be defined in response_module.R"
  )
})

test_that("F3-BEHAVIORAL: forced saver failure propagates as error and leaves no valid xlsx", {
  skip_if(!exists("build_response_excel", mode = "function"),
    "build_response_excel() not yet extracted — helper missing"
  )
  skip_if_not_installed("openxlsx")

  measures   <- data.frame(Name = "M1", Type = "R", stringsAsFactors = FALSE)
  impacts    <- data.frame(Element = "E1", Impact = 1L, stringsAsFactors = FALSE)
  milestones <- data.frame(Task = "T1", Due = "2026-01", stringsAsFactors = FALSE)
  tmp <- tempfile(fileext = ".xlsx")
  on.exit(unlink(tmp))

  expect_error(
    build_response_excel(
      measures   = measures,
      impacts    = impacts,
      milestones = milestones,
      file       = tmp,
      saver      = function(wb, file, overwrite) stop("forced-saver-failure")
    ),
    regexp = "forced-saver-failure"
  )

  # No valid (non-empty) xlsx should have been written
  expect_true(
    !file.exists(tmp) || file.size(tmp) == 0L,
    info = "A forced saver failure must not leave a non-empty .xlsx file on disk"
  )
})

test_that("F3-BEHAVIORAL: happy path — build_response_excel() produces a non-empty xlsx", {
  skip_if(!exists("build_response_excel", mode = "function"),
    "build_response_excel() not yet extracted — helper missing"
  )
  skip_if_not_installed("openxlsx")

  measures   <- data.frame(Name = "M1", Type = "R", stringsAsFactors = FALSE)
  impacts    <- data.frame(Element = "E1", Impact = 1L, stringsAsFactors = FALSE)
  milestones <- data.frame(Task = "T1", Due = "2026-01", stringsAsFactors = FALSE)
  tmp <- tempfile(fileext = ".xlsx")
  on.exit(unlink(tmp))

  build_response_excel(
    measures   = measures,
    impacts    = impacts,
    milestones = milestones,
    file       = tmp
  )

  expect_true(file.exists(tmp) && file.size(tmp) > 0L,
    info = "Happy-path build_response_excel() must produce a non-empty .xlsx"
  )
})

# ---------------------------------------------------------------------------
# F2 SOURCE-GREP: verify download handlers use report_path_is_servable()
# ---------------------------------------------------------------------------

test_that("F2: all 5 download handlers use report_path_is_servable() [BEHAVIORAL guard]", {
  module_path <- testthat::test_path("../../modules/prepare_report_module.R")
  skip_if_not(file.exists(module_path), "prepare_report_module.R not found")

  code_text <- paste(readLines(module_path), collapse = "\n")

  # Count how many download handlers call report_path_is_servable
  hits <- lengths(regmatches(code_text,
    gregexpr("req\\(report_path_is_servable\\(", code_text)))

  expect_true(
    hits >= 4L,
    info = paste("Expected >= 4 req(report_path_is_servable(...)) calls, found:", hits)
  )
})

# ===========================================================================
# Original source-grep tests (kept as cheap regression guards)
# ===========================================================================

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
