# tests/testthat/test-modals.R
# Phase C Task 5 — language-change save handler error surfacing

test_that("modals.R language-change save handler aborts reload and surfaces a translated user notification on save failure", {
  expect_context_key_in_file(
    "server/modals.R",
    "context_language_change_save",
    info = "Save error handler in setup_language_modal_only must surface format_user_error(context_key='common.messages.context_language_change_save'). MODAL_ANIMATION_DELAY_MS=100ms is too short for toast render+reload, so the fix must also ABORT the reload (early return on save failure) so the notification persists."
  )
  td <- getwd()
  root <- if (basename(td) == "testthat") dirname(dirname(td)) else td
  src <- paste(readLines(file.path(root, "server", "modals.R"), warn = FALSE), collapse = "\n")
  expect_true(
    grepl("save_success\\s*<-\\s*tryCatch", src, perl = TRUE),
    info = "Save handler must capture tryCatch result as save_success and early-return on FALSE — otherwise the reload destroys the notification before user can read it."
  )
})
