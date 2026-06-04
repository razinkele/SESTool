test_that("project_io and autosave recovery normalize the loaded project", {
  for (f in c("server/project_io.R", "modules/auto_save_module.R")) {
    src <- paste(readLines(testthat::test_path("..","..",f), warn = FALSE), collapse = "\n")
    expect_true(grepl("normalize_and_reconcile_project", src, fixed = TRUE),
                info = paste(f, "must call normalize_and_reconcile_project on load"))
  }
})
