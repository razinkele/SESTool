# functions/safe_render.R
# Safe wrapper for renderUI that catches errors and shows user-friendly fallback

safe_renderUI <- function(expr, i18n = NULL,
                          fallback_key = "common.messages.generic_error",
                          context = "renderUI") {
  renderUI({
    tryCatch(
      expr(),
      error = function(e) {
        debug_log(sprintf("safe_renderUI error in %s: %s", context, e$message), "ERROR")
        fallback_msg <- if (!is.null(i18n)) {
          tryCatch(i18n$t(fallback_key), error = function(e2) "An error occurred.")
        } else {
          "An error occurred. Please try again."
        }
        tags$div(
          class = "alert alert-warning",
          icon("exclamation-triangle"),
          fallback_msg
        )
      }
    )
  })
}
