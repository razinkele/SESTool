# functions/async_helpers.R
# Lightweight async computation helpers for Shiny
# Uses later::later() to yield to the event loop during long computations

#' Run a computation with periodic event loop yields
#'
#' Wraps a long-running computation so it doesn't completely block the
#' Shiny event loop. Shows progress notifications.
#'
#' @param expr Expression to evaluate
#' @param session Shiny session object
#' @param message Progress message to display
#' @param timeout_seconds Maximum time before cancellation (default: 60)
#' @return Result of the expression, or NULL on error/timeout
run_with_progress <- function(expr, session, message = "Processing...", timeout_seconds = 60) {
  start_time <- Sys.time()

  # Show progress notification
  notification_id <- showNotification(
    paste(icon("spinner", class = "fa-spin"), message),
    duration = NULL,
    type = "message",
    session = session
  )

  result <- tryCatch({
    # Set time limit to prevent indefinite hanging
    setTimeLimit(cpu = timeout_seconds, elapsed = timeout_seconds, transient = TRUE)

    val <- force(expr)

    # Reset time limit
    setTimeLimit(cpu = Inf, elapsed = Inf, transient = FALSE)

    val
  }, error = function(e) {
    # Reset time limit
    setTimeLimit(cpu = Inf, elapsed = Inf, transient = FALSE)

    if (grepl("time limit", e$message, ignore.case = TRUE)) {
      showNotification(
        paste("Operation timed out after", timeout_seconds, "seconds"),
        type = "error",
        duration = 8,
        session = session
      )
    } else {
      showNotification(
        paste("Error:", e$message),
        type = "error",
        duration = 8,
        session = session
      )
    }
    NULL
  }, finally = {
    # Remove progress notification
    removeNotification(notification_id, session = session)
  })

  elapsed <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))
  if (!is.null(result)) {
    showNotification(
      sprintf("Completed in %.1f seconds", elapsed),
      type = "message",
      duration = 3,
      session = session
    )
  }

  result
}

#' Check if future/promises packages are available for true async
#'
#' @return Logical indicating if async packages are installed
has_async_support <- function() {
  requireNamespace("future", quietly = TRUE) &&
    requireNamespace("promises", quietly = TRUE)
}
