# tests/testthat/test-analysis-leverage-clarity.R
# Regression tests for Task 8: Leverage point explanations and actionability

# Helper: resolve a file path relative to the project root
leverage_project_path <- function(...) {
  # Walk up from the test directory to the project root
  test_dir <- tryCatch(testthat::test_path("."), error = function(e) getwd())
  project_root <- normalizePath(file.path(test_dir, "..", ".."), mustWork = FALSE)
  file.path(project_root, ...)
}

test_that("leverage analysis module UI returns valid shiny tags", {
  skip_if_not(exists("analysis_leverage_ui", mode = "function"),
              "analysis_leverage_ui not available")
  ui <- analysis_leverage_ui("test_id", i18n = create_mock_i18n())
  expect_true(inherits(ui, "shiny.tag") || inherits(ui, "shiny.tag.list"))
})

test_that("leverage interpretation i18n keys exist in translation file", {
  trans_path <- leverage_project_path("translations", "modules", "analysis_leverage.json")
  skip_if_not(file.exists(trans_path), "Translation file not found")

  trans_raw <- readLines(trans_path, warn = FALSE)
  trans_text <- paste(trans_raw, collapse = "\n")

  required_keys <- c(
    "interp_top_leverage", "interp_above_avg", "interp_moderate",
    "what_to_do", "step1_identify", "step1_detail",
    "step2_assess", "step2_detail", "step3_design", "step3_detail",
    "step4_validate", "step4_detail",
    "note_framework_bias_title", "note_framework_bias_detail"
  )
  for (key in required_keys) {
    expect_true(grepl(key, trans_text, fixed = TRUE),
                info = paste("Missing i18n key:", key))
  }
})

test_that("leverage module source contains actionable guidance UI", {
  module_path <- leverage_project_path("modules", "analysis_leverage.R")
  skip_if_not(file.exists(module_path), "Module file not found")

  module_code <- paste(readLines(module_path, warn = FALSE), collapse = "\n")
  expect_true(grepl("what_to_do", module_code, fixed = TRUE),
              info = "Module must contain 'what_to_do' actionable guidance section")
  expect_true(grepl("note_framework_bias", module_code, fixed = TRUE),
              info = "Module must contain framework bias warning")
  expect_true(grepl("interp_top_leverage", module_code, fixed = TRUE),
              info = "Interpretation column must use i18n key interp_top_leverage")
})

test_that("leverage translation file has all 9 languages for new keys", {
  trans_path <- leverage_project_path("translations", "modules", "analysis_leverage.json")
  skip_if_not(file.exists(trans_path), "Translation file not found")

  trans_data <- tryCatch(
    jsonlite::fromJSON(trans_path),
    error = function(e) NULL
  )
  skip_if(is.null(trans_data), "Could not parse translation file as JSON")

  expected_langs <- c("en", "es", "fr", "de", "lt", "pt", "it", "no", "el")
  new_keys <- c(
    "modules.analysis.leverage.interp_top_leverage",
    "modules.analysis.leverage.interp_above_avg",
    "modules.analysis.leverage.interp_moderate",
    "modules.analysis.leverage.what_to_do",
    "modules.analysis.leverage.note_framework_bias_title",
    "modules.analysis.leverage.note_framework_bias_detail"
  )

  for (key in new_keys) {
    if (!is.null(trans_data$translation[[key]])) {
      present_langs <- names(trans_data$translation[[key]])
      for (lang in expected_langs) {
        expect_true(lang %in% present_langs,
                    info = paste("Missing language", lang, "for key", key))
      }
    }
  }
})

test_that("leverage module interpretation column uses Composite_Score not composite_score", {
  module_path <- leverage_project_path("modules", "analysis_leverage.R")
  skip_if_not(file.exists(module_path), "Module file not found")

  module_code <- paste(readLines(module_path, warn = FALSE), collapse = "\n")
  # Must use capitalized column name consistent with data frame construction
  expect_true(grepl("results\\$Composite_Score", module_code),
              info = "Interpretation column must use 'results$Composite_Score' (matching actual column name)")
})
