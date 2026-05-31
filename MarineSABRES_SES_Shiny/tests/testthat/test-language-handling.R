# tests/testthat/test-language-handling.R
# Phase C Task 5 — language-change restore handler error surfacing

test_that("language_handling.R post-reload restore handler surfaces translated user notification on failure", {
  expect_context_key_in_file(
    "server/language_handling.R",
    "context_language_change_restore",
    info = "Restore error handler in setup_language_restore_handler must surface format_user_error(context_key='common.messages.context_language_change_restore') using session_i18n (function parameter at line 95). Was explicitly silent ('Don't show error to user' comment)."
  )
})
