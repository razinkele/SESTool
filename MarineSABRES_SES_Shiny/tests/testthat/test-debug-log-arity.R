test_that("no debug_log call passes a 3rd severity arg", {
  files <- c("server/export_handlers.R", "modules/template_ses_module.R")
  hit <- function(f) grep('debug_log\\(.*,\\s*"(ERROR|WARN|INFO)"\\)\\s*$',
                          readLines(testthat::test_path("..", "..", f), warn = FALSE), perl = TRUE)
  for (f in files) expect_length(hit(f), 0)
})
