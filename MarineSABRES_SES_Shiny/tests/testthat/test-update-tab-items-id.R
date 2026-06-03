test_that("no updateTabItems call uses the non-existent 'tabs' id", {
  root  <- testthat::test_path("..", "..")
  files <- list.files(root, pattern = "\\.R$", recursive = TRUE, full.names = TRUE)
  files <- files[grepl("/(modules|server)/", files)]
  bad <- unlist(lapply(files, function(f)
    grep('updateTabItems\\([^)]*"tabs"', readLines(f, warn = FALSE), value = TRUE)))
  expect_length(bad, 0)
})
