# tests/testthat/test-tool-recommendations.R
# Tests for the cross-tool recommendation engine (functions/tool_recommendations.R)

# Source the file directly if not available in the test environment
if (!exists("get_next_steps", mode = "function")) {
  tryCatch(
    source(file.path(dirname(dirname(dirname(testthat::test_path()))),
                     "functions", "tool_recommendations.R")),
    error = function(e) NULL
  )
}

test_that("get_next_steps returns valid recommendations for loop analysis", {
  skip_if_not(exists("get_next_steps", mode = "function"), "get_next_steps not available")
  recs <- get_next_steps("analysis_loops")
  expect_true(is.list(recs))
  expect_true(length(recs) > 0)
  expect_true(all(c("label_key", "tab_id", "description_key") %in% names(recs[[1]])))
})

test_that("get_next_steps returns valid recommendations for leverage analysis", {
  skip_if_not(exists("get_next_steps", mode = "function"), "get_next_steps not available")
  recs <- get_next_steps("analysis_leverage")
  expect_true(is.list(recs))
  expect_true(length(recs) > 0)
  expect_true(all(c("label_key", "tab_id", "description_key") %in% names(recs[[1]])))
})

test_that("get_next_steps returns valid recommendations for metrics analysis", {
  skip_if_not(exists("get_next_steps", mode = "function"), "get_next_steps not available")
  recs <- get_next_steps("analysis_metrics")
  expect_true(is.list(recs))
  expect_true(length(recs) > 0)
})

test_that("all recommendation keys use i18n key format, not raw English", {
  skip_if_not(exists("get_next_steps", mode = "function"), "get_next_steps not available")
  for (module in c("analysis_loops", "analysis_leverage", "analysis_metrics")) {
    recs <- get_next_steps(module)
    for (rec in recs) {
      expect_true(
        grepl("\\.", rec$label_key),
        info = paste("label_key must be i18n dotted key for", module)
      )
      expect_true(
        grepl("\\.", rec$description_key),
        info = paste("description_key must be i18n dotted key for", module)
      )
    }
  }
})

test_that("all recommendations have non-empty tab_id and icon", {
  skip_if_not(exists("get_next_steps", mode = "function"), "get_next_steps not available")
  for (module in c("analysis_loops", "analysis_leverage", "analysis_metrics")) {
    recs <- get_next_steps(module)
    for (rec in recs) {
      expect_true(nchar(rec$tab_id) > 0,
                  info = paste("tab_id must be non-empty for", module))
      expect_true(nchar(rec$icon) > 0,
                  info = paste("icon must be non-empty for", module))
    }
  }
})

test_that("get_next_steps returns empty list for unknown module", {
  skip_if_not(exists("get_next_steps", mode = "function"), "get_next_steps not available")
  recs <- get_next_steps("nonexistent_module")
  expect_true(is.list(recs))
  expect_equal(length(recs), 0)
})

test_that("analysis_loops recommendations include leverage and report links", {
  skip_if_not(exists("get_next_steps", mode = "function"), "get_next_steps not available")
  recs <- get_next_steps("analysis_loops")
  tab_ids <- vapply(recs, function(r) r$tab_id, character(1))
  expect_true("analysis_leverage" %in% tab_ids)
  expect_true("prepare_report" %in% tab_ids)
})

test_that("analysis_leverage recommendations include loops and report links", {
  skip_if_not(exists("get_next_steps", mode = "function"), "get_next_steps not available")
  recs <- get_next_steps("analysis_leverage")
  tab_ids <- vapply(recs, function(r) r$tab_id, character(1))
  expect_true("analysis_loops" %in% tab_ids)
  expect_true("prepare_report" %in% tab_ids)
})

test_that("translation file for tool_recommendations exists and is valid JSON", {
  # Resolve path relative to the package root (works from testthat and standalone)
  pkg_root <- tryCatch(
    rprojroot::find_root(rprojroot::has_file("DESCRIPTION")),
    error = function(e) {
      # Fallback: walk up from this file
      d <- dirname(sys.frame(1)$filename %||% normalizePath(".", winslash = "/"))
      for (i in 1:5) {
        if (file.exists(file.path(d, "DESCRIPTION"))) return(d)
        d <- dirname(d)
      }
      getwd()
    }
  )
  json_path <- file.path(pkg_root, "translations", "modules", "tool_recommendations.json")
  expect_true(file.exists(json_path))
  parsed <- tryCatch(jsonlite::fromJSON(json_path), error = function(e) NULL)
  expect_false(is.null(parsed))
  expect_true("languages" %in% names(parsed))
  expect_true("translation" %in% names(parsed))
})

test_that("tool_recommendations translation file has all 9 languages for every key", {
  pkg_root <- tryCatch(
    rprojroot::find_root(rprojroot::has_file("DESCRIPTION")),
    error = function(e) getwd()
  )
  json_path <- file.path(pkg_root, "translations", "modules", "tool_recommendations.json")
  skip_if_not(file.exists(json_path), "translation file not found")
  parsed <- jsonlite::fromJSON(json_path, simplifyVector = FALSE)
  expected_langs <- c("en", "es", "fr", "de", "lt", "pt", "it", "no", "el")
  for (key in names(parsed$translation)) {
    actual_langs <- names(parsed$translation[[key]])
    missing <- setdiff(expected_langs, actual_langs)
    expect_equal(length(missing), 0L,
                 info = paste("Key", key, "is missing languages:", paste(missing, collapse = ", ")))
  }
})
