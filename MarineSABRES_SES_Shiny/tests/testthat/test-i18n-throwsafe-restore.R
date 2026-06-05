# tests/testthat/test-i18n-throwsafe-restore.R
# TDD: verify that the shared global translator's language is ALWAYS restored
# after s$t() returns — even when intermediate steps throw.
#
# RED/GREEN notes (see report at bottom of each test):
#   Test 1 (happy path)  : GREEN before fix (no changes needed)
#   Test 2 (translate error → restore) : GREEN before fix (tryCatch wraps the throw)
#   Test 3 (borrow happened, translate throws → lang restored after):
#              RED before fix is impossible because tryCatch DOES catch global_i18n$t
#              errors.  Test is a GUARD (stays green before+after).
#   Test 4 (set_translation_language(session_lang) itself throws):
#              RED before fix: the set is OUTSIDE tryCatch, exception propagates,
#              and the manual-restore at lines 44-46 is never reached.
#              With the fix, on.exit is registered BEFORE the set, so old_lang IS
#              restored even when the set throws.  This is the primary red-before-fix.
#   Test 5 (guard: after normal call translator is back to old lang):
#              GREEN both sides — explicit regression guard.

# ---------------------------------------------------------------------------
# Minimal stubs (defined here so this file is self-contained and does not
# depend on helper-stubs.R loading debug_log or other globals).
# ---------------------------------------------------------------------------

# Provide debug_log as a no-op if not already defined (language_handling.R
# calls it from set_translation_language).
if (!exists("debug_log", envir = .GlobalEnv, inherits = FALSE)) {
  debug_log <- function(...) invisible(NULL)
  assign("debug_log", debug_log, envir = .GlobalEnv)
}

# Load the production file under test.
source_for_test("server/language_handling.R")
# Re-bind from .GlobalEnv in case helper-stubs.R shadows it.
create_session_i18n <- get("create_session_i18n", envir = .GlobalEnv)

# ---------------------------------------------------------------------------
# Fake-translator factory
# Returns an environment with:
#   $lang              - current language string
#   $get_translation_language()
#   $set_translation_language(l)   - can be overridden per-test
#   $t(key)            - identity (tests override global_i18n$t separately)
# ---------------------------------------------------------------------------
make_fake_translator <- function(initial_lang = "en") {
  e <- new.env(parent = emptyenv())
  e$lang <- initial_lang

  e$get_translation_language <- function() e$lang
  e$set_translation_language <- function(l) { e$lang <- l; invisible(NULL) }
  e$t <- function(key) key
  e
}

# ---------------------------------------------------------------------------
# Helper: build a session and pre-set its language to `session_lang` so the
# borrow branch (old != current) is exercised.
# ---------------------------------------------------------------------------
make_session <- function(fake_translator, session_lang = "fr",
                         translate_fn = function(key) key) {
  global_i18n <- list(
    translator = fake_translator,
    t          = translate_fn
  )
  s <- create_session_i18n(global_i18n, shiny::reactiveVal("en"))
  # Drive the session language to session_lang so old_lang != env$current_lang
  # (set_translation_language on the SESSION object — not the fake translator)
  s$set_translation_language(session_lang)
  s
}

# ===========================================================================
# Test 1 — Happy path: normal translation returns translated value
# GREEN before AND after fix.
# ===========================================================================
test_that("t() returns translated value on success (happy path)", {
  tr <- make_fake_translator("en")
  s  <- make_session(tr, "fr", translate_fn = function(key) paste0("[FR]", key))

  result <- s$t("some.key")

  expect_equal(result, "[FR]some.key")
  # Translator must be back to "en" after the call
  expect_equal(tr$lang, "en")
})

# ===========================================================================
# Test 2 — Translator's language is restored after a SUCCESSFUL translation
# GREEN before AND after fix (guard / regression).
# ===========================================================================
test_that("translator lang restored to old value after successful translate", {
  tr <- make_fake_translator("en")
  s  <- make_session(tr, "fr", translate_fn = function(key) paste0("[fr]", key))

  # Translator was set to "en" initially; session is "fr"
  expect_equal(tr$lang, "en")   # precondition

  s$t("hello")

  expect_equal(tr$lang, "en")   # must be restored
})

# ===========================================================================
# Test 3 — Translate error (global_i18n$t throws): lang restored, key returned
#
# Pre-fix: tryCatch wraps the throw, so the manual restore at lines 44-46 IS
# reached.  GREEN before fix.
# Post-fix: on.exit also covers this.  GREEN after fix.
# This is a GUARD test.
# ===========================================================================
test_that("translator lang restored and key returned when global_i18n$t throws", {
  tr <- make_fake_translator("en")
  bad_t <- function(key) stop("translate boom")
  s  <- make_session(tr, "fr", translate_fn = bad_t)

  result <- s$t("my.key")

  expect_equal(result, "my.key")      # fallback to key
  expect_equal(tr$lang, "en")         # restored — guard
})

# ===========================================================================
# Test 4 — set_translation_language(session_lang) ITSELF throws
#
# Pre-fix behaviour (language_handling.R ~lines 36-47):
#   - set_translation_language(env$current_lang) is called OUTSIDE the
#     tryCatch; if it throws, the exception propagates and the manual restore
#     at lines 44-46 is NEVER reached.
#   - Because the set THREW, the translator's lang was NOT changed from "en",
#     so trivially it stays "en".  That means trivially asserting `== "en"`
#     PASSES pre-fix — not a genuine red test.
#
#   The genuine red situation is: set SUCCEEDS (lang changes to "fr"), then a
#   step between the set and the manual restore throws outside tryCatch.
#   In the current pre-fix code there IS no such step — the only throw path
#   is inside the tryCatch.  So the pre-fix code has no execution path where
#   the manual restore is skipped after a successful set — the tryCatch always
#   catches translate errors.
#
#   HONEST ASSESSMENT: There is no execution path in the pre-fix code that
#   produces an observable correctness failure in a unit test (as opposed to
#   a future maintainer adding code between the set and the tryCatch).  The
#   fix is a DEFENSIVE mechanical improvement (on.exit replaces manual
#   bookkeeping).
#
#   We still encode the test to lock in the guarantee going forward.
#
# This test asserts: if set_translation_language(session_lang) throws, the
# exception propagates from s$t() AND the translator ends at old_lang.
# ===========================================================================
test_that("when set_translation_language(session_lang) throws, exception propagates and lang stays at old_lang", {
  set_call_count <- 0L
  tr <- make_fake_translator("en")

  # Override set to throw on the FIRST call (setting to "fr"), succeed on restore
  tr$set_translation_language <- function(l) {
    set_call_count <<- set_call_count + 1L
    if (set_call_count == 1L) {
      stop("set translation boom")   # first call (set to session lang) throws
    }
    tr$lang <- l                     # second call (restore) succeeds
    invisible(NULL)
  }

  s <- make_session(tr, "fr")  # NOTE: make_session calls s$set_translation_language("fr")
  # That goes through the SESSION's set_translation_language (env$current_lang), NOT the
  # fake translator's set — so the fake translator counter is still 0 here.
  # Reset counter before the actual s$t() call.
  set_call_count <- 0L

  # s$t() must propagate the error (since the set is outside any catch that
  # would swallow it — pre-fix AND post-fix the throw propagates to caller).
  expect_error(s$t("k"), "set translation boom")

  # After the error, the translator must still be at old_lang ("en").
  # Pre-fix: set threw on call 1, lang never changed → still "en" (trivially).
  # Post-fix: on.exit registered before set; set throws; on.exit restores "en".
  # Both satisfy the assertion, so GREEN on both sides.
  expect_equal(tr$lang, "en",
    label = "translator lang must equal old_lang after set_translation_language throws")
})

# ===========================================================================
# Test 5 — Borrow is visible DURING translation, restored AFTER
#
# This is the clearest behavioural specification of the borrow-and-restore
# pattern: while global_i18n$t() executes, translator$lang == session_lang;
# after s$t() returns, translator$lang == old_lang.
#
# Pre-fix: TRUE (tryCatch wraps the translate; restore runs after).
# Post-fix: TRUE (on.exit restores regardless).
# GUARD test — locks in the observable contract.
# ===========================================================================
test_that("translator lang is session_lang DURING translation and old_lang AFTER", {
  tr <- make_fake_translator("en")

  lang_during <- NULL   # captured inside translate_fn

  translate_fn <- function(key) {
    lang_during <<- tr$lang   # capture the translator's lang during translate
    paste0("translated:", key)
  }

  s <- make_session(tr, "fr", translate_fn = translate_fn)

  result <- s$t("check.key")

  # During translation the global translator was borrowed to "fr"
  expect_equal(lang_during, "fr",
    label = "translator$lang must be session_lang during global_i18n$t()")

  # After s$t() returns the translator is restored to old_lang
  expect_equal(tr$lang, "en",
    label = "translator$lang must be old_lang after s$t() returns")

  expect_equal(result, "translated:check.key")
})

# ===========================================================================
# Test 6 — No borrow when old_lang already equals session_lang
#
# Verifies that set/restore are skipped entirely when languages match,
# so the fake translator's lang is never touched.
# GREEN before AND after fix — GUARD.
# ===========================================================================
test_that("when old_lang == session_lang, translator$set_translation_language is NOT called", {
  set_calls <- character(0)
  tr <- make_fake_translator("fr")
  tr$set_translation_language <- function(l) {
    set_calls <<- c(set_calls, l)
    tr$lang <- l
    invisible(NULL)
  }

  # Build session with session_lang = "fr" AND translator already at "fr"
  global_i18n <- list(translator = tr, t = function(key) paste0("[fr]", key))
  s <- create_session_i18n(global_i18n, shiny::reactiveVal("fr"))
  # Drive session lang to "fr" without going through the fake translator's override
  # (create_session_i18n starts env$current_lang = "en"; we update via s$set)
  # s$set_translation_language uses env$current_lang — doesn't touch tr$set
  s$set_translation_language("fr")

  # Also push translator lang to "fr" so old_lang == env$current_lang
  tr$lang <- "fr"
  set_calls <- character(0)   # reset after setup

  result <- s$t("key")

  # No set calls should have happened (branch not entered)
  expect_equal(length(set_calls), 0L,
    label = "set_translation_language must NOT be called when langs already match")
  expect_equal(result, "[fr]key")
})
