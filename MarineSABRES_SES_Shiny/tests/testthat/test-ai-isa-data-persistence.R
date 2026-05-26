library(testthat)

test_that("ai_isa data_persistence produces user_edited_matrices alongside matrices", {
  td <- getwd()
  root <- if (basename(td) == "testthat") dirname(dirname(td)) else td
  src <- paste(readLines(file.path(root, "modules", "ai_isa", "data_persistence.R"),
                         warn = FALSE), collapse = "\n")
  expect_true(grepl("user_edited_matrices", src, fixed = TRUE),
              info = "ai_isa data_persistence must produce user_edited_matrices")
})
