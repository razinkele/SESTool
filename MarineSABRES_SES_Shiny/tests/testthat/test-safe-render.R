# tests/testthat/test-safe-render.R
# Tests for safe_renderUI error boundary wrapper

# Source safe_render.R if not already loaded (for standalone test runs)
if (!exists("safe_renderUI", mode = "function")) {
  source(file.path(
    dirname(dirname(dirname(testthat::test_path()))),
    "functions", "safe_render.R"
  ))
}

test_that("safe_renderUI function exists and is callable", {
  skip_if_not(exists("safe_renderUI", mode = "function"),
              "safe_renderUI not available")
  expect_true(is.function(safe_renderUI))
})

test_that("safe_renderUI accepts i18n parameter", {
  skip_if_not(exists("safe_renderUI", mode = "function"),
              "safe_renderUI not available")
  params <- names(formals(safe_renderUI))
  expect_true("i18n" %in% params,
              info = "safe_renderUI must accept i18n for translated fallback messages")
  expect_true("fallback_key" %in% params,
              info = "safe_renderUI must accept fallback_key for i18n lookup")
  expect_true("context" %in% params,
              info = "safe_renderUI must accept context for debug logging")
})

test_that("safe_renderUI signature is compatible with renderUI replacement", {
  skip_if_not(exists("safe_renderUI", mode = "function"),
              "safe_renderUI not available")
  params <- names(formals(safe_renderUI))
  expect_equal(params[1], "expr",
               info = "First parameter must be 'expr' (the render expression function)")
})
