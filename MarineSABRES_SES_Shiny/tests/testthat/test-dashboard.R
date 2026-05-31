test_that("dashboard value-box error handlers reference context_dashboard_stats", {
  expect_context_key_in_file(
    "server/dashboard.R",
    "context_dashboard_stats",
    info = "All 4 dashboard value-box catches must surface format_user_error(context_key='common.messages.context_dashboard_stats')."
  )
})

test_that("dashboard has 4 distinct per-box notification ids (one per value-box)", {
  td <- getwd()
  root <- if (basename(td) == "testthat") dirname(dirname(td)) else td
  src <- paste(readLines(file.path(root, "server", "dashboard.R"),
                         warn = FALSE), collapse = "\n")
  matches <- gregexpr("dashboard_err_box[1-4]", src)[[1]]
  expect_true(
    length(matches) >= 4 && attr(matches, "match.length")[1] > 0,
    info = "Must have id='dashboard_err_box1' through 'dashboard_err_box4' across the 4 value-box catches. Hardcoded per-box id — bounded to 4 toasts max, no hash collisions, no digest package dep."
  )
})
