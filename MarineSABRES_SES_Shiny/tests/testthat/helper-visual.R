# helper-visual.R
# Helper functions for visual regression testing with shinytest2
#
# These utilities support screenshot-based visual regression tests.
# Baselines are stored in tests/visual-regression/ and compared against
# new screenshots taken during test runs.

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

VISUAL_BASELINE_DIR <- file.path(
  dirname(dirname(getwd())), "tests", "visual-regression"
)

# Fallback: resolve from project root if running from a different working dir
if (!dir.exists(VISUAL_BASELINE_DIR)) {
  VISUAL_BASELINE_DIR <- file.path(
    normalizePath(file.path(getwd(), "../.."), mustWork = FALSE),
    "tests", "visual-regression"
  )
}

VISUAL_SCREENSHOT_DIR <- file.path(tempdir(), "marinesabres_visual_tests")
if (!dir.exists(VISUAL_SCREENSHOT_DIR)) {
  dir.create(VISUAL_SCREENSHOT_DIR, recursive = TRUE)
}

# Default pixel-difference threshold (percent, 0-100)
VISUAL_THRESHOLD <- 3

# Default viewport for visual tests
VISUAL_WIDTH  <- 1280
VISUAL_HEIGHT <- 900

# Timeouts (ms)
VISUAL_APP_TIMEOUT  <- 15000
VISUAL_IDLE_TIMEOUT <- 5000

# ---------------------------------------------------------------------------
# setup_app_with_data
# ---------------------------------------------------------------------------

#' Launch the Shiny app and wait for it to reach a usable state
#'
#' The app auto-loads the Caribbean template on empty state so that
#' downstream pages (CLD, analysis) have data to render.
#'
#' @param name  A short label used for the shinytest2 session directory.
#' @param width  Viewport width in pixels (default 1280).
#' @param height Viewport height in pixels (default 900).
#' @param load_timeout Milliseconds to wait for the app to start.
#' @return An \code{AppDriver} object ready for interaction.
setup_app_with_data <- function(name = "visual-test",
                                width = VISUAL_WIDTH,
                                height = VISUAL_HEIGHT,
                                load_timeout = VISUAL_APP_TIMEOUT) {
  app_dir <- normalizePath(file.path(getwd(), "../.."), mustWork = FALSE)

  app <- shinytest2::AppDriver$new(
    app_dir      = app_dir,
    name         = name,
    width        = width,
    height       = height,
    wait         = TRUE,
    timeout      = VISUAL_APP_TIMEOUT,
    load_timeout = load_timeout
  )

  # Give the auto-loaded template time to settle

  app$wait_for_idle(timeout = VISUAL_IDLE_TIMEOUT)

  return(app)
}

# ---------------------------------------------------------------------------
# compare_screenshot
# ---------------------------------------------------------------------------

#' Take a screenshot and compare it to a stored baseline
#'
#' On the first run (no baseline exists) the screenshot is saved as the new
#' baseline and the test is skipped with a message.
#'
#' @param app        An \code{AppDriver} object.
#' @param test_name  A short, filesystem-safe identifier (e.g. "dashboard").
#' @param threshold  Maximum allowed pixel-difference percentage (0-100).
#' @param selector   Optional CSS selector to screenshot a specific element.
#'                   If \code{NULL} the full page is captured.
#' @return Invisibly returns the path to the new screenshot.
compare_screenshot <- function(app,
                               test_name,
                               threshold = VISUAL_THRESHOLD,
                               selector = NULL) {
  # Ensure directories exist
  if (!dir.exists(VISUAL_BASELINE_DIR)) {
    dir.create(VISUAL_BASELINE_DIR, recursive = TRUE)
  }

  baseline_path <- file.path(VISUAL_BASELINE_DIR,
                              paste0(test_name, "_baseline.png"))
  current_path  <- file.path(VISUAL_SCREENSHOT_DIR,
                              paste0(test_name, "_current.png"))

  # Capture current screenshot
  app$get_screenshot(current_path, selector = selector)

  if (!file.exists(baseline_path)) {
    # First run -- save as baseline, skip comparison
    file.copy(current_path, baseline_path)
    testthat::skip(paste0(
      "Baseline created for '", test_name,
      "'. Re-run to compare. Saved to: ", baseline_path
    ))
  }

  # Compare using shinytest2's built-in expect_screenshot when available,

  # otherwise fall back to a simple file-size heuristic.
  if (requireNamespace("png", quietly = TRUE)) {
    baseline_img <- png::readPNG(baseline_path)
    current_img  <- png::readPNG(current_path)

    # Resize check -- dimensions must match
    if (!identical(dim(baseline_img), dim(current_img))) {
      testthat::fail(paste0(
        "Screenshot dimensions changed for '", test_name, "'. ",
        "Baseline: ", paste(dim(baseline_img)[1:2], collapse = "x"),
        " vs Current: ", paste(dim(current_img)[1:2], collapse = "x"),
        ". Run update_baselines() to accept the new layout."
      ))
    }

    # Pixel-level comparison (mean absolute difference across all channels)
    diff_pct <- mean(abs(baseline_img - current_img)) * 100

    if (diff_pct > threshold) {
      diff_path <- file.path(VISUAL_SCREENSHOT_DIR,
                              paste0(test_name, "_diff.png"))
      # Save the current screenshot for manual inspection
      file.copy(current_path, diff_path, overwrite = TRUE)
      testthat::fail(paste0(
        "Visual regression detected for '", test_name, "': ",
        sprintf("%.2f", diff_pct), "% pixel difference ",
        "(threshold: ", threshold, "%). ",
        "Inspect: ", diff_path
      ))
    }
  } else {
    # Fallback: compare file sizes as a rough proxy
    baseline_size <- file.info(baseline_path)$size
    current_size  <- file.info(current_path)$size
    size_diff_pct <- abs(baseline_size - current_size) / baseline_size * 100

    if (size_diff_pct > (threshold * 5)) {
      testthat::fail(paste0(
        "Screenshot file size changed significantly for '", test_name, "': ",
        sprintf("%.1f", size_diff_pct), "% size difference. ",
        "Install the 'png' package for pixel-level comparison."
      ))
    }
  }

  invisible(current_path)
}

# ---------------------------------------------------------------------------
# update_baselines
# ---------------------------------------------------------------------------

#' Refresh all baseline screenshots by copying current screenshots over them
#'
#' Run this interactively after visually verifying that the current screenshots
#' are correct. Typically called from the R console, not from within tests.
#'
#' @param test_names Character vector of test names to update. If \code{NULL},
#'   all baselines that have a matching current screenshot are updated.
#' @return Invisibly returns the paths that were updated.
update_baselines <- function(test_names = NULL) {
  current_files <- list.files(VISUAL_SCREENSHOT_DIR,
                               pattern = "_current\\.png$",
                               full.names = TRUE)

  if (length(current_files) == 0) {
    message("No current screenshots found in ", VISUAL_SCREENSHOT_DIR)
    message("Run the visual regression tests first to generate screenshots.")
    return(invisible(character(0)))
  }

  if (!dir.exists(VISUAL_BASELINE_DIR)) {
    dir.create(VISUAL_BASELINE_DIR, recursive = TRUE)
  }

  updated <- character(0)

  for (current_path in current_files) {
    name <- sub("_current\\.png$", "", basename(current_path))

    if (!is.null(test_names) && !name %in% test_names) {
      next
    }

    baseline_path <- file.path(VISUAL_BASELINE_DIR,
                                paste0(name, "_baseline.png"))
    file.copy(current_path, baseline_path, overwrite = TRUE)
    updated <- c(updated, baseline_path)
    message("Updated baseline: ", basename(baseline_path))
  }

  if (length(updated) == 0) {
    message("No baselines updated. Check test_names argument.")
  } else {
    message("Updated ", length(updated), " baseline(s) in ", VISUAL_BASELINE_DIR)
  }

  invisible(updated)
}

# ---------------------------------------------------------------------------
# navigate_and_wait
# ---------------------------------------------------------------------------

#' Navigate to a sidebar tab and wait for rendering to complete
#'
#' @param app      An \code{AppDriver} object.
#' @param tab_name The sidebar menu tab name.
#' @param wait_ms  Milliseconds to wait after navigation.
#' @return The app object (invisibly), for chaining.
navigate_and_wait <- function(app, tab_name, wait_ms = VISUAL_IDLE_TIMEOUT) {
  app$set_inputs(sidebar_menu = tab_name,
                 wait_ = TRUE,
                 timeout_ = VISUAL_APP_TIMEOUT)
  app$wait_for_idle(timeout = wait_ms)
  invisible(app)
}
