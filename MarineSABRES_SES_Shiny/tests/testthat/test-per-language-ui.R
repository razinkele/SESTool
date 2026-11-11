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

# Shiny calls ui(request) inside the request's restore context, so with a
# function ui, bookmarked values (incl. actionButton click counts, which would
# re-fire observeEvent handlers) would flow into the static inputs. The static
# app never did that; the layout must be built outside any bookmark context.
# shiny:::RestoreContext / withRestoreContext are what uiHttpHandler uses.
in_bookmark_context <- function(query, expr) {
  shiny:::withRestoreContext(shiny:::RestoreContext$new(query), expr)
}

test_that("bookmarked input values never flow into the static layout", {
  tr <- fake_translator("en")
  ui <- make_per_language_ui(function() shiny::restoreInput("btn", 0), tr, langs)
  q <- "_inputs_&language=de&btn=3"
  expect_equal(in_bookmark_context(q, ui(fake_request(paste0("?", q)))), 0)
  # Guard that the fixture really is a bookmark context:
  expect_equal(in_bookmark_context(q, shiny::restoreInput("btn", 0)), 3)
})

test_that("bookmark links share the cached layout of their language", {
  tr <- fake_translator("en")
  calls <- 0
  ui <- make_per_language_ui(function() { calls <<- calls + 1; shiny::restoreInput("x", "default") }, tr, langs)
  q <- "_inputs_&language=de&x=%22from_bookmark%22"
  expect_equal(in_bookmark_context(q, ui(fake_request(paste0("?", q)))), "default")
  expect_equal(ui(fake_request("?language=de")), "default")
  expect_equal(calls, 1)
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

test_that("the skip link and main-content label are translated (CodeRabbit, PR #143)", {
  app <- paste(readLines(file.path(if (basename(getwd()) == "testthat") dirname(dirname(getwd())) else getwd(), "app.R"), warn = FALSE), collapse = "\n")
  expect_false(grepl('"Skip to main content"', app, fixed = TRUE))
  expect_false(grepl('`aria-label` = "Main content"', app, fixed = TRUE))
  expect_match(app, 'i18n$t("ui.header.skip_to_main_content")', fixed = TRUE)
  expect_match(app, 'i18n$t("ui.header.main_content_label")', fixed = TRUE)
})

# shiny.i18n 0.3.0's input binding subscribes with $(el).on('change', callback),
# so Shiny receives the jQuery event object as the "priority" argument; newer
# Shiny (>= 1.13 on laguna) rejects it: "Unexpected input value mode:
# '[object Object]'" in the console on every ?language= load. update_lang()
# had no effect here anyway: the page has no shiny.i18n `.i18n` elements, no
# code reads session$userData$shiny.i18n$lang, and the language switch reloads
# the page so the layout is rebuilt in the new language (make_per_language_ui).
test_that("the app never calls shiny.i18n::update_lang() (console error, no effect)", {
  root <- if (basename(getwd()) == "testthat") dirname(dirname(getwd())) else getwd()
  files <- c(file.path(root, "app.R"),
             list.files(file.path(root, c("server", "modules", "functions")),
                        pattern = "[.]R$", full.names = TRUE, recursive = TRUE))
  hits <- character()
  for (f in files) {
    code <- sub("#.*$", "", readLines(f, warn = FALSE))
    if (any(grepl("update_lang[[:space:]]*[(]", code))) hits <- c(hits, basename(f))
  }
  expect_equal(hits, character(), info = paste("update_lang() still called in:", paste(hits, collapse = ", ")))
})
