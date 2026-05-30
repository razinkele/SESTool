# tests/testthat/test-functions-sourced-in-app.R
# Guard: every functions/*.R must be reachable from the global.R / app.R
# source() chain. A file that defines helpers but is never source()d is a
# runtime undefined-symbol risk — this is exactly the feedback-#1 bug, where
# functions/matrix_from_linked.R existed (v1.13.0) but was never sourced, so the
# N:M reconciler silently never ran.

test_that("every functions/*.R is reachable from the global.R/app.R source chain", {
  td <- getwd()
  proj <- if (basename(td) == "testthat") dirname(dirname(td)) else td

  fn_files <- list.files(file.path(proj, "functions"), pattern = "\\.R$",
                         recursive = TRUE)
  expect_gt(length(fn_files), 0)

  chain <- paste(c(readLines(file.path(proj, "global.R"), warn = FALSE),
                   readLines(file.path(proj, "app.R"),    warn = FALSE)),
                 collapse = "\n")

  for (f in fn_files) {
    expect_true(
      grepl(basename(f), chain, fixed = TRUE),
      info = paste0("functions/", f, " is never source()d in global.R/app.R ",
                    "— runtime undefined-symbol risk")
    )
  }
})
