# tests/testthat/test-feedback-analyzer.R
# Tests for functions/feedback_analyzer.R

# Ensure debug_log is available before sourcing feedback_analyzer.R
# (global.R defines it, but may fail to load in some test environments)
if (!exists("debug_log", mode = "function")) {
  debug_log <- function(msg, ctx = NULL) invisible(NULL)  # nolint
}

# Source feedback_analyzer.R directly if not already available
# (global.R loaded by helper-00-load-functions.R normally covers this)
if (!exists("load_feedback_log", mode = "function")) {
  pkg_root <- tryCatch(
    rprojroot::find_root(rprojroot::has_file("DESCRIPTION")),
    error = function(e) {
      normalizePath(file.path(testthat::test_path(), "..", ".."),
                    mustWork = FALSE)
    }
  )
  tryCatch(
    source(file.path(pkg_root, "functions", "feedback_analyzer.R"),
           local = FALSE),
    error = function(e) message("Could not load feedback_analyzer.R: ", e$message)
  )
}

# Resolve project root for file-system tests
.pkg_root <- tryCatch(
  rprojroot::find_root(rprojroot::has_file("DESCRIPTION")),
  error = function(e) {
    normalizePath(file.path(testthat::test_path(), "..", ".."),
                  mustWork = FALSE)
  }
)

# Helper: write lines to a temp file and return its path
.write_tmp_ndjson <- function(lines) {
  tmp <- tempfile(fileext = ".ndjson")
  writeLines(lines, tmp)
  tmp
}


# =============================================================================
# load_feedback_log tests
# =============================================================================

test_that("load_feedback_log parses valid NDJSON with correct columns", {
  skip_if_not(exists("load_feedback_log", mode = "function"),
              "load_feedback_log not available")

  line1 <- jsonlite::toJSON(list(
    type        = "bug",
    title       = "Crash on load",
    description = "App crashes immediately",
    steps       = "Open app",
    timestamp   = "2026-01-01T10:00:00Z",
    github_url  = NA_character_
  ), auto_unbox = TRUE)

  tmp <- .write_tmp_ndjson(line1)
  on.exit(unlink(tmp))

  df <- load_feedback_log(tmp)

  expect_s3_class(df, "data.frame")
  expected_cols <- c("line_num", "type", "title", "description",
                     "steps", "timestamp", "github_url", "duplicate_of")
  expect_true(all(expected_cols %in% names(df)),
              info = paste("Missing:", paste(setdiff(expected_cols, names(df)),
                                            collapse = ", ")))
  expect_equal(nrow(df), 1L)
  expect_equal(df$title[1L], "Crash on load")
  expect_equal(df$type[1L],  "bug")
  expect_equal(df$line_num[1L], 1L)
})

test_that("load_feedback_log returns empty data.frame for missing file", {
  skip_if_not(exists("load_feedback_log", mode = "function"),
              "load_feedback_log not available")

  df <- load_feedback_log(tempfile(fileext = ".ndjson"))

  expect_s3_class(df, "data.frame")
  expect_equal(nrow(df), 0L)
  expected_cols <- c("line_num", "type", "title", "description",
                     "steps", "timestamp", "github_url", "duplicate_of")
  expect_true(all(expected_cols %in% names(df)))
})

test_that("load_feedback_log skips malformed lines and tracks physical line numbers", {
  skip_if_not(exists("load_feedback_log", mode = "function"),
              "load_feedback_log not available")

  good1 <- jsonlite::toJSON(list(
    type = "bug", title = "Good1", description = "desc1",
    steps = "", timestamp = "2026-01-01T10:00:00Z", github_url = NA_character_
  ), auto_unbox = TRUE)

  bad2  <- "{ this is not valid json ]["

  good3 <- jsonlite::toJSON(list(
    type = "suggestion", title = "Good3", description = "desc3",
    steps = "", timestamp = "2026-01-02T10:00:00Z", github_url = NA_character_
  ), auto_unbox = TRUE)

  tmp <- .write_tmp_ndjson(c(good1, bad2, good3))
  on.exit(unlink(tmp))

  df <- load_feedback_log(tmp)

  expect_equal(nrow(df), 2L)
  expect_equal(df$line_num, c(1L, 3L))
  expect_equal(df$title, c("Good1", "Good3"))
})

test_that("load_feedback_log deduplicates corrected entries keeping last with github_url", {
  skip_if_not(exists("load_feedback_log", mode = "function"),
              "load_feedback_log not available")

  ts <- "2026-02-15T12:00:00Z"

  # First entry: no github_url (or NA)
  entry_original <- list(
    type = "bug", title = "Duplicate Title", description = "desc",
    steps = "", timestamp = ts, github_url = NA_character_
  )
  # Second entry: same title + timestamp, github_url filled in
  entry_corrected <- list(
    type = "bug", title = "Duplicate Title", description = "desc",
    steps = "", timestamp = ts,
    github_url = "https://github.com/org/repo/issues/42"
  )

  line1 <- jsonlite::toJSON(entry_original,  auto_unbox = TRUE)
  line2 <- jsonlite::toJSON(entry_corrected, auto_unbox = TRUE)

  tmp <- .write_tmp_ndjson(c(line1, line2))
  on.exit(unlink(tmp))

  df <- load_feedback_log(tmp)

  # Only one row should survive deduplication
  expect_equal(nrow(df), 1L)
  # It must be the corrected (last) entry
  expect_equal(df$github_url[1L], "https://github.com/org/repo/issues/42")
})

test_that("load_feedback_log defaults missing duplicate_of to NA_character_", {
  skip_if_not(exists("load_feedback_log", mode = "function"),
              "load_feedback_log not available")

  line <- jsonlite::toJSON(list(
    type = "general", title = "No dup field", description = "desc",
    steps = "", timestamp = "2026-03-01T09:00:00Z", github_url = NA_character_
  ), auto_unbox = TRUE)

  tmp <- .write_tmp_ndjson(line)
  on.exit(unlink(tmp))

  df <- load_feedback_log(tmp)

  expect_equal(nrow(df), 1L)
  expect_true(is.na(df$duplicate_of[1L]))
})


# =============================================================================
# compute_text_similarity tests
# =============================================================================

test_that("compute_text_similarity returns 1.0 for identical texts", {
  skip_if_not(exists("compute_text_similarity", mode = "function"),
              "compute_text_similarity not available")

  texts <- c("the quick brown fox jumps over the lazy dog",
             "the quick brown fox jumps over the lazy dog")
  mat   <- compute_text_similarity(texts)

  expect_equal(dim(mat), c(2L, 2L))
  expect_equal(mat[1L, 2L], 1.0, tolerance = 1e-9)
  expect_equal(mat[2L, 1L], 1.0, tolerance = 1e-9)
})

test_that("compute_text_similarity returns near 0 for unrelated texts", {
  skip_if_not(exists("compute_text_similarity", mode = "function"),
              "compute_text_similarity not available")

  texts <- c("marine ecology coral reef biodiversity",
             "software programming compiler binary tree")
  mat   <- compute_text_similarity(texts)

  expect_equal(dim(mat), c(2L, 2L))
  expect_lt(mat[1L, 2L], 0.3)
})

test_that("compute_text_similarity returns NxN matrix", {
  skip_if_not(exists("compute_text_similarity", mode = "function"),
              "compute_text_similarity not available")

  texts <- c("fish population decline",
             "overfishing impact assessment",
             "climate change ocean temperature")
  mat   <- compute_text_similarity(texts)

  expect_equal(dim(mat), c(3L, 3L))
  # Diagonal should be 1 (self-similarity)
  for (i in seq_len(3L)) {
    expect_equal(mat[i, i], 1.0, tolerance = 1e-9)
  }
})

test_that("compute_text_similarity returns 0-matrix for single entry", {
  skip_if_not(exists("compute_text_similarity", mode = "function"),
              "compute_text_similarity not available")

  mat <- compute_text_similarity("only one document here")

  expect_equal(dim(mat), c(1L, 1L))
  expect_equal(mat[1L, 1L], 0.0)
})

test_that("compute_text_similarity handles all-stopword text without NaN", {
  skip_if_not(exists("compute_text_similarity", mode = "function"),
              "compute_text_similarity not available")

  # Both texts consist only of common English stopwords
  texts <- c("the and or but a an",
             "is are was were be")
  mat   <- compute_text_similarity(texts)

  expect_equal(dim(mat), c(2L, 2L))
  expect_false(any(is.nan(mat)))
  expect_false(any(is.na(mat)))
})


# =============================================================================
# find_duplicate_pairs tests
# =============================================================================

test_that("find_duplicate_pairs finds known duplicates above threshold", {
  skip_if_not(exists("find_duplicate_pairs", mode = "function"),
              "find_duplicate_pairs not available")

  df <- data.frame(
    line_num     = 1:3,
    title        = c("App crashes on startup", "App crashes on startup", "Suggestion for UI"),
    description  = c("App crashes immediately when opened",
                     "App crashes immediately when opened",
                     "The interface could be improved"),
    github_url   = NA_character_,
    duplicate_of = NA_character_,
    stringsAsFactors = FALSE
  )

  pairs <- find_duplicate_pairs(df, threshold = 0.7)

  expect_s3_class(pairs, "data.frame")
  expect_true(nrow(pairs) >= 1L)

  # Lines 1 and 2 should be identified as duplicates
  found <- (pairs$line_num_a == 1L & pairs$line_num_b == 2L) |
           (pairs$line_num_a == 2L & pairs$line_num_b == 1L)
  expect_true(any(found))
})

test_that("find_duplicate_pairs returns empty data.frame with fewer than 2 entries", {
  skip_if_not(exists("find_duplicate_pairs", mode = "function"),
              "find_duplicate_pairs not available")

  df_empty <- data.frame(
    line_num = integer(0), title = character(0), description = character(0),
    github_url = character(0), duplicate_of = character(0),
    stringsAsFactors = FALSE
  )
  pairs0 <- find_duplicate_pairs(df_empty)
  expect_equal(nrow(pairs0), 0L)

  df_one <- data.frame(
    line_num = 1L, title = "Only entry", description = "desc",
    github_url = NA_character_, duplicate_of = NA_character_,
    stringsAsFactors = FALSE
  )
  pairs1 <- find_duplicate_pairs(df_one)
  expect_equal(nrow(pairs1), 0L)

  expected_cols <- c("line_num_a", "line_num_b", "similarity")
  expect_true(all(expected_cols %in% names(pairs0)))
  expect_true(all(expected_cols %in% names(pairs1)))
})

test_that("find_duplicate_pairs excludes already-marked duplicates", {
  skip_if_not(exists("find_duplicate_pairs", mode = "function"),
              "find_duplicate_pairs not available")

  df <- data.frame(
    line_num     = 1:3,
    title        = c("App crashes on startup", "App crashes on startup",
                     "Network error occurs"),
    description  = c("App crashes immediately when opened",
                     "App crashes immediately when opened",
                     "Network disconnects randomly"),
    github_url   = NA_character_,
    # Line 2 is already marked as duplicate of line 1
    duplicate_of = c(NA_character_, "1", NA_character_),
    stringsAsFactors = FALSE
  )

  pairs <- find_duplicate_pairs(df, threshold = 0.7)

  # Line 2 is excluded, so no pairs involving line 2 should appear
  if (nrow(pairs) > 0L) {
    expect_false(any(pairs$line_num_a == 2L | pairs$line_num_b == 2L))
  } else {
    # Acceptable: no pairs found after excluding line 2
    expect_equal(nrow(pairs), 0L)
  }
})


# =============================================================================
# mark_as_duplicate tests
# =============================================================================

test_that("mark_as_duplicate adds duplicate_of field to correct physical line", {
  skip_if_not(exists("mark_as_duplicate", mode = "function"),
              "mark_as_duplicate not available")

  entry1 <- list(type = "bug", title = "First",  description = "d1",
                 steps = "", timestamp = "2026-01-01T10:00:00Z",
                 github_url = NA_character_)
  entry2 <- list(type = "bug", title = "Second", description = "d2",
                 steps = "", timestamp = "2026-01-02T10:00:00Z",
                 github_url = NA_character_)

  line1 <- jsonlite::toJSON(entry1, auto_unbox = TRUE)
  line2 <- jsonlite::toJSON(entry2, auto_unbox = TRUE)

  tmp <- .write_tmp_ndjson(c(line1, line2))
  on.exit(unlink(tmp))

  result <- mark_as_duplicate(tmp, line_num = 2L,
                              duplicate_of_line = "https://github.com/org/repo/issues/1")

  expect_true(result)

  # Verify the file was updated
  raw <- readLines(tmp, warn = FALSE)
  expect_equal(length(raw), 2L)

  parsed2 <- jsonlite::fromJSON(raw[[2L]], simplifyVector = TRUE)
  expect_equal(parsed2$duplicate_of,
               "https://github.com/org/repo/issues/1")

  # Line 1 should be untouched
  parsed1 <- jsonlite::fromJSON(raw[[1L]], simplifyVector = TRUE)
  expect_equal(parsed1$title, "First")
  expect_null(parsed1$duplicate_of)
})

test_that("mark_as_duplicate returns FALSE for out-of-range line_num", {
  skip_if_not(exists("mark_as_duplicate", mode = "function"),
              "mark_as_duplicate not available")

  entry <- list(type = "bug", title = "Only line", description = "d",
                steps = "", timestamp = "2026-01-01T10:00:00Z",
                github_url = NA_character_)
  line  <- jsonlite::toJSON(entry, auto_unbox = TRUE)

  tmp <- .write_tmp_ndjson(line)
  on.exit(unlink(tmp))

  # Line 0 (below range)
  expect_false(mark_as_duplicate(tmp, line_num = 0L, duplicate_of_line = "ref"))
  # Line 5 (above range - only 1 line exists)
  expect_false(mark_as_duplicate(tmp, line_num = 5L, duplicate_of_line = "ref"))
})


# =============================================================================
# feedback_admin_module tests
# =============================================================================

test_that("feedback_admin_ui returns valid shiny tags when available", {
  skip_if_not(exists("feedback_admin_ui", mode = "function"), "not available")
  skip_if_not(exists("create_mock_i18n", mode = "function"), "create_mock_i18n not available")
  ui <- feedback_admin_ui("test_admin", i18n = create_mock_i18n())
  expect_true(inherits(ui, "shiny.tag") || inherits(ui, "shiny.tag.list"))
})

test_that("feedback_admin_server has correct signature", {
  skip_if_not(exists("feedback_admin_server", mode = "function"), "not available")
  params <- names(formals(feedback_admin_server))
  expect_true("id" %in% params)
  expect_true("i18n" %in% params)
})

test_that("admin sidebar item is conditional on ADMIN_MODE", {
  project_root <- normalizePath(file.path(testthat::test_path(), "..", ".."), mustWork = FALSE)
  sidebar_code <- paste(readLines(file.path(project_root, "functions/ui_sidebar.R")), collapse = "\n")
  expect_true(grepl("ADMIN_MODE", sidebar_code),
              info = "Sidebar must check ADMIN_MODE for admin menu item")
  expect_true(grepl("feedback_admin", sidebar_code),
              info = "Sidebar must contain feedback_admin tabName")
})

test_that("all feedback_admin i18n keys exist for all 9 languages", {
  project_root <- normalizePath(file.path(testthat::test_path(), "..", ".."), mustWork = FALSE)
  trans_path <- file.path(project_root, "translations/modules/feedback_admin.json")
  skip_if_not(file.exists(trans_path), "feedback_admin.json not found")

  trans <- jsonlite::fromJSON(trans_path, simplifyVector = FALSE)
  required_keys <- c(
    "modules.feedback_admin.menu_label", "modules.feedback_admin.dashboard_tab",
    "modules.feedback_admin.duplicates_tab", "modules.feedback_admin.total_reports",
    "modules.feedback_admin.bug_reports", "modules.feedback_admin.suggestions",
    "modules.feedback_admin.general_feedback", "modules.feedback_admin.last_7_days",
    "modules.feedback_admin.github_submitted", "modules.feedback_admin.local_only",
    "modules.feedback_admin.no_feedback", "modules.feedback_admin.similarity_threshold",
    "modules.feedback_admin.find_duplicates", "modules.feedback_admin.no_duplicates",
    "modules.feedback_admin.mark_duplicate", "modules.feedback_admin.marked_duplicate",
    "modules.feedback_admin.mark_error", "modules.feedback_admin.detail_title",
    "modules.feedback_admin.recalculate", "modules.feedback_admin.scale_note",
    "modules.feedback_admin.col_date", "modules.feedback_admin.col_type",
    "modules.feedback_admin.col_title", "modules.feedback_admin.col_description",
    "modules.feedback_admin.col_github", "modules.feedback_admin.col_report_a",
    "modules.feedback_admin.col_report_b", "modules.feedback_admin.col_similarity",
    "modules.feedback_admin.col_action"
  )
  langs <- c("en", "es", "fr", "de", "lt", "pt", "it", "no", "el")

  for (key in required_keys) {
    key_data <- trans$translation[[key]]
    expect_false(is.null(key_data), info = paste("Missing key:", key))
    if (!is.null(key_data)) {
      for (lang in langs) {
        expect_true(!is.null(key_data[[lang]]) && nchar(key_data[[lang]]) > 0,
                    info = paste("Missing", lang, "for", key))
      }
    }
  }
})
