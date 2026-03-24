# tests/testthat/test-guidebook-module.R
# Regression tests for Task 9: Standalone guidebook infrastructure

# Helper: resolve a file path relative to the project root
guidebook_project_path <- function(...) {
  test_dir <- tryCatch(testthat::test_path("."), error = function(e) getwd())
  project_root <- normalizePath(file.path(test_dir, "..", ".."), mustWork = FALSE)
  file.path(project_root, ...)
}

# Helper: minimal mock i18n object (may already be defined by helpers.R)
if (!exists("create_mock_i18n", mode = "function")) {
  create_mock_i18n <- function() {
    list(
      t = function(key) key,
      get_key_translation = function(key) key,
      set_translation_language = function(lang) invisible(NULL)
    )
  }
}

test_that("guidebook_ui returns valid shiny tags", {
  skip_if_not(exists("guidebook_ui", mode = "function"),
              "guidebook_ui not available")
  ui <- guidebook_ui("test_guidebook", i18n = create_mock_i18n())
  expect_true(inherits(ui, "shiny.tag") || inherits(ui, "shiny.tag.list"))
})

test_that("guidebook_server has correct parameter signature", {
  skip_if_not(exists("guidebook_server", mode = "function"),
              "guidebook_server not available")
  params <- names(formals(guidebook_server))
  expect_true("id" %in% params)
  expect_true("i18n" %in% params)
})

test_that("guidebook.Rmd exists and is valid R Markdown", {
  rmd_path <- guidebook_project_path("guidebook", "guidebook.Rmd")
  expect_true(file.exists(rmd_path),
              info = "guidebook/guidebook.Rmd must exist")
  content <- readLines(rmd_path)
  expect_equal(content[1], "---", info = "Must start with YAML frontmatter")
  expect_true(any(grepl("title:", content)), info = "Must have title in frontmatter")
  expect_true(any(grepl("output:", content)), info = "Must have output format")
})

test_that("guidebook translation keys exist for all 9 languages", {
  trans_path <- guidebook_project_path("translations", "modules", "guidebook.json")
  skip_if_not(file.exists(trans_path),
              "guidebook translation file not found")
  trans_text <- paste(readLines(trans_path), collapse = "\n")

  required_keys <- c("menu_item", "title", "subtitle", "download_pdf",
                     "download_html", "fallback_message")
  for (key in required_keys) {
    expect_true(grepl(key, trans_text), info = paste("Missing key:", key))
  }
})

test_that("guidebook translation file covers all 9 required languages", {
  trans_path <- guidebook_project_path("translations", "modules", "guidebook.json")
  skip_if_not(file.exists(trans_path),
              "guidebook translation file not found")

  trans_data <- jsonlite::fromJSON(trans_path)
  declared_languages <- trans_data$languages
  required_languages <- c("en", "es", "fr", "de", "lt", "pt", "it", "no", "el")

  for (lang in required_languages) {
    expect_true(lang %in% declared_languages,
                info = paste("Missing language in guidebook.json:", lang))
  }
})

test_that("guidebook menu item is registered in sidebar", {
  sidebar_path <- guidebook_project_path("functions", "ui_sidebar.R")
  skip_if_not(file.exists(sidebar_path), "ui_sidebar.R not found")
  sidebar_code <- paste(readLines(sidebar_path), collapse = "\n")
  expect_true(grepl("guidebook", sidebar_code),
              info = "Sidebar must contain guidebook menu item")
})

test_that("guidebook tab item is registered in app.R", {
  app_path <- guidebook_project_path("app.R")
  skip_if_not(file.exists(app_path), "app.R not found")
  app_code <- paste(readLines(app_path), collapse = "\n")
  expect_true(grepl('tabName = "guidebook"', app_code),
              info = "app.R must register guidebook tab item")
})

test_that("guidebook module is sourced in app.R optional modules", {
  app_path <- guidebook_project_path("app.R")
  skip_if_not(file.exists(app_path), "app.R not found")
  app_code <- paste(readLines(app_path), collapse = "\n")
  expect_true(grepl("guidebook_module", app_code),
              info = "app.R must include guidebook_module.R in OPTIONAL_MODULES")
})

test_that("guidebook server is called in app.R server section", {
  app_path <- guidebook_project_path("app.R")
  skip_if_not(file.exists(app_path), "app.R not found")
  app_code <- paste(readLines(app_path), collapse = "\n")
  expect_true(grepl("guidebook_server", app_code),
              info = "app.R server section must call guidebook_server()")
})
