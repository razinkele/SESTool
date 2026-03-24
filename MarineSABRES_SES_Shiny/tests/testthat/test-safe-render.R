# tests/testthat/test-safe-render.R
# Tests for safe_renderUI error boundary wrapper (factory-based, from error_handling.R)

test_that("safe_renderUI function exists and is callable", {
  skip_if_not(exists("safe_renderUI", mode = "function"),
              "safe_renderUI not available")
  expect_true(is.function(safe_renderUI))
})

test_that("safe_renderUI has standard Shiny render signature", {
  skip_if_not(exists("safe_renderUI", mode = "function"),
              "safe_renderUI not available")
  params <- names(formals(safe_renderUI))
  expect_equal(params[1], "expr",
               info = "First parameter must be 'expr'")
  expect_true("env" %in% params,
              info = "safe_renderUI must accept env parameter for Shiny compatibility")
  expect_true("quoted" %in% params,
              info = "safe_renderUI must accept quoted parameter for Shiny compatibility")
})

test_that("safe_renderUI is used in critical analysis modules", {
  # Verify the 3 critical modules use safe_renderUI for error boundaries
  project_root <- normalizePath(file.path(testthat::test_path(), "..", ".."), mustWork = FALSE)
  for (module_name in c("modules/analysis_leverage.R",
                        "modules/analysis_loops.R",
                        "modules/analysis_metrics.R")) {
    module_file <- file.path(project_root, module_name)
    skip_if_not(file.exists(module_file), paste("Module file not found:", module_name))
    code <- paste(readLines(module_file), collapse = "\n")
    expect_true(grepl("safe_renderUI", code),
                info = paste(module_file, "must use safe_renderUI for error boundaries"))
  }
})
