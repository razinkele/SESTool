# tests/testthat/test-c3-hardening.R
# Task C3: Security hardening tests for L10 (filename injection) and L11 (i18n HTML escaping)

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

source_utils <- function() {
  utils_path <- testthat::test_path("../../functions/utils.R")
  if (file.exists(utils_path)) {
    source(utils_path, local = FALSE)
  }
}

# ---------------------------------------------------------------------------
# L10 — sanitize_filename contract + static assertion on analysis_bot.R
# ---------------------------------------------------------------------------

test_that("sanitize_filename strips header-injection chars (double-quote and newline)", {
  source_utils()
  skip_if_not(exists("sanitize_filename", mode = "function"),
              "sanitize_filename not found after sourcing utils.R")
  # Build a string with actual double-quote and actual newline characters
  evil_name <- paste0("evil", '"', "\nX-Inject: 1")
  out <- sanitize_filename(evil_name)
  expect_false(grepl('"', out, fixed = TRUE),
               info = paste("double-quote still present in output:", out))
  expect_false(grepl("\n", out, fixed = TRUE),
               info = paste("newline still present in output:", out))
  expect_false(grepl("\r", out, fixed = TRUE),
               info = paste("carriage-return still present in output:", out))
})

test_that("sanitize_filename strips carriage return", {
  source_utils()
  skip_if_not(exists("sanitize_filename", mode = "function"),
              "sanitize_filename not found")
  out <- sanitize_filename("name\rwith\rCR")
  expect_false(grepl("\r", out, fixed = TRUE),
               info = paste("CR still present in output:", out))
})

test_that("sanitize_filename returns non-empty string for empty/NULL input", {
  source_utils()
  skip_if_not(exists("sanitize_filename", mode = "function"),
              "sanitize_filename not found")
  expect_true(nchar(sanitize_filename("")) > 0)
  expect_true(nchar(sanitize_filename(NULL)) > 0)
})

test_that("bot download filename sanitizes the element name (static source check)", {
  bot_path <- testthat::test_path("../../modules/analysis_bot.R")
  skip_if_not(file.exists(bot_path), "modules/analysis_bot.R not found")
  src <- paste(readLines(bot_path, warn = FALSE), collapse = "\n")
  expect_true(
    grepl("sanitize_filename\\(input\\$bot_element", src) ||
      grepl("sanitize_filename\\([^)]*bot_element", src),
    label = "analysis_bot.R download filename must call sanitize_filename(input$bot_element)"
  )
})

# ---------------------------------------------------------------------------
# L11 — HTML(i18n$t) audit: assert leverage and simplify sites are intentional
# ---------------------------------------------------------------------------

# For the leverage and simplify modules, all HTML(i18n$t(...)) sites render
# translation strings that INTENTIONALLY contain HTML markup (<strong>, <em>).
# Escaping them would break rendered output for all 9 language users.
# These are authored strings in version-controlled JSON files, NOT user input.
# Therefore they are LEFT as HTML(i18n$t(...)) and documented here.
#
# This test asserts that:
# 1. The leverage module's HTML(i18n$t) sites are only for the known-markup keys.
# 2. The simplify module's HTML(i18n$t) sites are only for the known-markup keys.
# 3. No NEW HTML(i18n$t) sites have been added to these files without review.
# analysis_loops.R had no HTML(i18n$t) sites (confirmed by grep).

test_that("analysis_leverage.R HTML(i18n$t) sites are limited to known-markup keys", {
  leverage_path <- testthat::test_path("../../modules/analysis_leverage.R")
  skip_if_not(file.exists(leverage_path), "modules/analysis_leverage.R not found")

  src <- paste(readLines(leverage_path, warn = FALSE), collapse = "\n")
  # Extract all keys used in HTML(i18n$t("...")) calls
  matches <- gregexpr('HTML\\(i18n\\$t\\("([^"]+)"\\)', src, perl = TRUE)
  raw_matches <- regmatches(src, matches)[[1]]
  keys_used <- if (length(raw_matches) > 0) {
    sub('.*HTML\\(i18n\\$t\\("([^"]+)"\\).*', "\\1", raw_matches, perl = TRUE)
  } else {
    character(0)
  }

  known_markup_keys <- c(
    "modules.analysis.leverage.no_network_data",
    "modules.analysis.leverage.click_calculate"
  )

  unexpected <- setdiff(keys_used, known_markup_keys)
  expect_equal(
    length(unexpected), 0L,
    label = paste(
      "Unexpected HTML(i18n$t) site(s) found in analysis_leverage.R.",
      "If intentional (markup in translations), add the key to known_markup_keys.",
      "Keys:", paste(unexpected, collapse = ", ")
    )
  )
})

test_that("analysis_simplify.R HTML(i18n$t) sites are limited to known-markup keys", {
  simplify_path <- testthat::test_path("../../modules/analysis_simplify.R")
  skip_if_not(file.exists(simplify_path), "modules/analysis_simplify.R not found")

  src <- paste(readLines(simplify_path, warn = FALSE), collapse = "\n")
  matches <- gregexpr('HTML\\(i18n\\$t\\("([^"]+)"\\)', src, perl = TRUE)
  raw_matches <- regmatches(src, matches)[[1]]
  keys_used <- if (length(raw_matches) > 0) {
    sub('.*HTML\\(i18n\\$t\\("([^"]+)"\\).*', "\\1", raw_matches, perl = TRUE)
  } else {
    character(0)
  }

  known_markup_keys <- c(
    "modules.analysis.simplify.about_better_communication",
    "modules.analysis.simplify.about_focused_analysis",
    "modules.analysis.simplify.about_computational_efficiency",
    "modules.analysis.simplify.about_pattern_recognition",
    "modules.analysis.simplify.about_scenario_testing",
    "modules.analysis.simplify.about_bp_feedback",
    "modules.analysis.simplify.about_bp_causality",
    "modules.analysis.simplify.about_bp_document",
    "modules.analysis.simplify.about_bp_validate",
    "modules.analysis.simplify.about_bp_multiple",
    "modules.analysis.simplify.about_bp_iterate",
    "modules.analysis.simplify.about_rec_internal",
    "modules.analysis.simplify.about_rec_visual",
    "modules.analysis.simplify.about_rec_leverage",
    "modules.analysis.simplify.about_rec_sector",
    "modules.analysis.simplify.about_rec_maximum"
  )

  unexpected <- setdiff(keys_used, known_markup_keys)
  expect_equal(
    length(unexpected), 0L,
    label = paste(
      "Unexpected HTML(i18n$t) site(s) found in analysis_simplify.R.",
      "If intentional (markup in translations), add the key to known_markup_keys.",
      "Keys:", paste(unexpected, collapse = ", ")
    )
  )
})

test_that("analysis_loops.R has no HTML(i18n$t) sites", {
  loops_path <- testthat::test_path("../../modules/analysis_loops.R")
  skip_if_not(file.exists(loops_path), "modules/analysis_loops.R not found")

  src <- paste(readLines(loops_path, warn = FALSE), collapse = "\n")
  expect_false(
    grepl("HTML\\(i18n\\$t", src),
    label = "analysis_loops.R should have no HTML(i18n$t) calls (confirmed none existed)"
  )
})
