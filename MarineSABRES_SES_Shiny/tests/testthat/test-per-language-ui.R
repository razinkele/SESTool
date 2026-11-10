# tests/testthat/test-per-language-ui.R
# The static page layout is built per language (from ?language=) and cached,
# instead of once in English at app start (root cause of the "German
# translation incomplete" feedback, 2026-10-13).

source_for_test("server/language_handling.R")

# A fake shiny.i18n translator: only the language get/set the UI factory uses.
fake_translator <- function(lang = "en") {
  env <- new.env()
  env$lang <- lang
  list(
    get_translation_language = function() env$lang,
    set_translation_language = function(l) env$lang <- l
  )
}

fake_request <- function(query = "") list(QUERY_STRING = query)

langs <- c("en", "es", "fr", "de", "lt", "pt", "it", "no", "el")

test_that("resolve_ui_language reads ?language= and falls back to the default", {
  expect_equal(resolve_ui_language("?language=de", langs), "de")
  expect_equal(resolve_ui_language("language=el&foo=1", langs), "el")
  expect_equal(resolve_ui_language("", langs), "en")
  expect_equal(resolve_ui_language(NULL, langs), "en")
  expect_equal(resolve_ui_language("?language=xx", langs), "en")
  expect_equal(resolve_ui_language("?language=../../etc", langs), "en")
})

test_that("has_bookmark_restore detects Shiny bookmark state in the query", {
  expect_false(has_bookmark_restore("?language=de"))
  expect_false(has_bookmark_restore(""))
  expect_false(has_bookmark_restore(NULL))
  expect_true(has_bookmark_restore("?_inputs_&language=de&x=1"))
  expect_true(has_bookmark_restore("?_state_id_=abc123"))
  expect_true(has_bookmark_restore("?_values_&foo=1"))
})

test_that("the layout is built in the requested language and the translator is restored", {
  tr <- fake_translator("en")
  ui <- make_per_language_ui(function() paste("built in", tr$get_translation_language()),
                             tr, langs)
  expect_equal(ui(fake_request("?language=de")), "built in de")
  expect_equal(tr$get_translation_language(), "en")
  expect_equal(ui(fake_request("")), "built in en")
  expect_equal(ui(fake_request("?language=fr")), "built in fr")
  expect_equal(tr$get_translation_language(), "en")
})

test_that("each language is built once, then served from the cache", {
  tr <- fake_translator("en")
  calls <- 0
  ui <- make_per_language_ui(function() { calls <<- calls + 1; tr$get_translation_language() },
                             tr, langs)
  ui(fake_request("?language=de")); ui(fake_request("?language=de")); ui(fake_request("?language=de"))
  expect_equal(calls, 1)
  ui(fake_request("?language=en")); ui(fake_request(""))
  expect_equal(calls, 2)
  expect_setequal(ls(attr(ui, "cache")), c("de", "en"))
})

test_that("nothing is built at creation time (all languages are lazy, English included)", {
  tr <- fake_translator("en")
  calls <- 0
  ui <- make_per_language_ui(function() { calls <<- calls + 1; "x" }, tr, langs)
  expect_equal(calls, 0)
})

test_that("a failed build restores the translator and is not cached", {
  tr <- fake_translator("en")
  fail <- TRUE
  ui <- make_per_language_ui(function() {
    if (fail) stop("boom")
    tr$get_translation_language()
  }, tr, langs)
  expect_error(ui(fake_request("?language=de")), "boom")
  expect_equal(tr$get_translation_language(), "en")
  expect_false(exists("de", envir = attr(ui, "cache"), inherits = FALSE))
  fail <- FALSE
  expect_equal(ui(fake_request("?language=de")), "de")
})

test_that("bookmark-restore requests get a fresh build that is never cached", {
  tr <- fake_translator("en")
  calls <- 0
  ui <- make_per_language_ui(function() { calls <<- calls + 1; paste0("v", calls) }, tr, langs)
  expect_equal(ui(fake_request("?_inputs_&language=de&x=1")), "v1")
  expect_false(exists("de", envir = attr(ui, "cache"), inherits = FALSE))
  # A plain German request afterwards must not receive the bookmark build.
  expect_equal(ui(fake_request("?language=de")), "v2")
  expect_equal(ui(fake_request("?language=de")), "v2")
})

test_that("a German build does not change the language another session sees", {
  tr <- fake_translator("en")
  ui <- make_per_language_ui(function() tr$get_translation_language(), tr, langs)
  ui(fake_request("?language=de"))
  s <- create_session_i18n(
    list(translator = tr, t = function(key) paste0(tr$get_translation_language(), ":", key)),
    function(...) invisible(NULL)
  )
  expect_equal(s$t("k"), "en:k")
})

test_that("app.R serves the UI through make_per_language_ui", {
  app <- paste(readLines(file.path(if (basename(getwd()) == "testthat") dirname(dirname(getwd())) else getwd(), "app.R"), warn = FALSE), collapse = "\n")
  expect_match(app, "build_app_ui <- function\\(\\)")
  expect_match(app, "make_per_language_ui\\(")
  expect_false(grepl("\nui <- bs4DashPage\\(", app))
})
