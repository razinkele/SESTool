# tests/testthat/test-language-path-containment.R
# Task C1 (M6) — security regression tests for the language-selector RCE fix.
#
# Two independent defences are tested:
#  1. resolve_guidebook_rmd() path-containment (behavioral, directly callable)
#  2. modals.R language-modal handler validates against AVAILABLE_LANGUAGES
#     before calling set_translation_language (static source assertion — a
#     testServer() approach is not practical here because setup_language_modal_only
#     is shadowed by helper-stubs.R and needs heavy session wiring; the static
#     assertion proves the guard is in the live source without running the server).

# Load the guidebook module so resolve_guidebook_rmd is available.
# source_for_test() is defined in helper-00-load-functions.R (always loaded
# before test files by testthat's helper-file discovery).
source_for_test("modules/guidebook_module.R")

# ---------------------------------------------------------------------------
# Minimal fake i18n: only get_translation_language() is needed by
# resolve_guidebook_rmd.
# ---------------------------------------------------------------------------
fake_i18n <- function(lang) {
  list(get_translation_language = function() lang)
}

# ---------------------------------------------------------------------------
# 1. Path-containment tests for resolve_guidebook_rmd()
# ---------------------------------------------------------------------------

test_that("resolve_guidebook_rmd contains traversal language codes to the guidebook dir", {
  skip_if_not(exists("resolve_guidebook_rmd", mode = "function"),
              "resolve_guidebook_rmd not sourced")

  # Simulate a path-traversal attack: language = "../modules/cld_visualization_module"
  res <- resolve_guidebook_rmd(fake_i18n("../modules/cld_visualization_module"))

  # The result must be a path inside guidebook/ and must look like a guidebook_ file.
  expect_true(
    grepl("guidebook[/\\\\]guidebook_", res, perl = TRUE),
    info = paste("Expected path inside guidebook/guidebook_*, got:", res)
  )

  # It must NOT contain 'modules' — that would mean the traversal succeeded.
  expect_false(
    grepl("modules", res, ignore.case = TRUE),
    info = paste("Path must not escape into modules/, got:", res)
  )
})

test_that("resolve_guidebook_rmd blocks double-dot traversal with Windows separators", {
  skip_if_not(exists("resolve_guidebook_rmd", mode = "function"),
              "resolve_guidebook_rmd not sourced")

  res <- resolve_guidebook_rmd(fake_i18n("..\\server\\project_io"))

  expect_true(
    grepl("guidebook[/\\\\]guidebook_", res, perl = TRUE),
    info = paste("Expected path inside guidebook/guidebook_*, got:", res)
  )
  expect_false(
    grepl("server", res, ignore.case = TRUE),
    info = paste("Path must not escape into server/, got:", res)
  )
})

test_that("resolve_guidebook_rmd returns the English guidebook for a valid language with no language file", {
  skip_if_not(exists("resolve_guidebook_rmd", mode = "function"),
              "resolve_guidebook_rmd not sourced")

  # "en" always has a file (if guidebook/ is present); any valid code with no
  # file also falls back to en.  Either way, path must be guidebook_en.Rmd.
  res <- resolve_guidebook_rmd(fake_i18n("en"))

  expect_true(
    grepl("guidebook_en\\.Rmd$", res, perl = TRUE),
    info = paste("Expected guidebook_en.Rmd, got:", res)
  )
})

test_that("resolve_guidebook_rmd result always stays inside the guidebook directory", {
  skip_if_not(exists("resolve_guidebook_rmd", mode = "function"),
              "resolve_guidebook_rmd not sourced")

  # A broad set of adversarial inputs — all must resolve inside guidebook/
  adversarial_langs <- c(
    "../modules/evil",
    "../../etc/passwd",
    "../server/project_io",
    "en/../../../etc/shadow",
    "/absolute/path/injected"
  )

  td <- getwd()
  root <- if (basename(td) == "testthat") dirname(dirname(td)) else td
  guidebook_base <- normalizePath(file.path(root, "guidebook"), mustWork = FALSE)

  for (lang in adversarial_langs) {
    res <- resolve_guidebook_rmd(fake_i18n(lang))
    # Resolve the returned path relative to project root
    res_abs <- normalizePath(file.path(root, res), mustWork = FALSE)
    expect_true(
      startsWith(res_abs, guidebook_base),
      info = paste0("Adversarial lang='", lang, "' escaped to: ", res_abs)
    )
  }
})

# ---------------------------------------------------------------------------
# 2. Static assertion: modals.R validates against AVAILABLE_LANGUAGES
#    before calling set_translation_language
# ---------------------------------------------------------------------------

test_that("language modal validates input against AVAILABLE_LANGUAGES before setting", {
  # This is a source-level regression test (see helper-source-grep.R for rationale).
  # It asserts that BOTH the guard and the call to set_translation_language are
  # present in the same file, proving the validation was not accidentally removed.
  td <- getwd()
  root <- if (basename(td) == "testthat") dirname(dirname(td)) else td
  src <- paste(readLines(file.path(root, "server", "modals.R"), warn = FALSE),
               collapse = "\n")

  expect_true(
    grepl("AVAILABLE_LANGUAGES", src, fixed = TRUE) &&
      grepl("set_translation_language", src, fixed = TRUE),
    info = "modals.R must reference AVAILABLE_LANGUAGES and set_translation_language"
  )
})

test_that("language modal guard appears BEFORE set_translation_language in source order", {
  td <- getwd()
  root <- if (basename(td) == "testthat") dirname(dirname(td)) else td
  lines <- readLines(file.path(root, "server", "modals.R"), warn = FALSE)

  guard_line  <- which(grepl("AVAILABLE_LANGUAGES", lines, fixed = TRUE))
  setter_line <- which(grepl("set_translation_language", lines, fixed = TRUE))

  expect_true(length(guard_line)  >= 1, info = "AVAILABLE_LANGUAGES check not found in modals.R")
  expect_true(length(setter_line) >= 1, info = "set_translation_language not found in modals.R")

  # The first occurrence of the guard must precede the setter call.
  expect_true(
    min(guard_line) < min(setter_line),
    info = paste0(
      "AVAILABLE_LANGUAGES guard (line ", min(guard_line), ") must appear ",
      "BEFORE set_translation_language (line ", min(setter_line), ")"
    )
  )
})

test_that("language modal guard returns early on invalid code", {
  # Source-level check: the validation block must have both the guard condition
  # and a return() — proving the handler bails out before set_translation_language.
  td <- getwd()
  root <- if (basename(td) == "testthat") dirname(dirname(td)) else td
  lines <- readLines(file.path(root, "server", "modals.R"), warn = FALSE)

  # Match the guard line: `if (!(new_lang %in% names(AVAILABLE_LANGUAGES)))`
  # Use a broad pattern to survive whitespace/style variation.
  guard_start <- which(grepl("new_lang.*AVAILABLE_LANGUAGES", lines, perl = TRUE))
  expect_true(length(guard_start) >= 1,
              info = "modals.R must contain a guard checking new_lang against AVAILABLE_LANGUAGES")

  # Look for return() within 20 lines of the guard (the if-block body)
  block_end   <- min(guard_start[1] + 20L, length(lines))
  guard_block <- lines[seq(guard_start[1], block_end)]
  expect_true(
    any(grepl("return\\(\\)", guard_block, perl = TRUE)),
    info = "The validation guard must return() early to prevent set_translation_language from executing"
  )
})
