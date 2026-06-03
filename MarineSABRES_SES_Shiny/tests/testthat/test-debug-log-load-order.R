test_that("debug_log is defined before it is first called in global.R", {
  src  <- readLines(testthat::test_path("..", "..", "global.R"), warn = FALSE)
  def  <- grep("^debug_log <- function", src)[1]
  uses <- grep("debug_log\\(", src)
  first_use <- min(setdiff(uses, def))
  expect_true(!is.na(def) && def < first_use,
              info = sprintf("def at %s, first use at %s", def, first_use))
})
