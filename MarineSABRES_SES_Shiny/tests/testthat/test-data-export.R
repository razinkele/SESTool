# tests/testthat/test-data-export.R
# Regression for feedback #8 "data export": the Export-page Download Data button
# was a placeholder that wrote a TEXT file with a .xlsx/.csv/.json/.RData name,
# so the downloaded file could not be opened. write_data_export() must produce a
# real, openable file for each format — including on the EXTENSION-LESS temp path
# that Shiny's downloadHandler passes (the same trap that broke #7).
source_for_test("functions/export_functions.R")

make_list <- function() list(
  goods_benefits = data.frame(ID = c("GB001", "GB002"), Name = c("Fish", "Energy"),
                              stringsAsFactors = FALSE),
  project_info = list(project_name = "Demo", project_id = "P1")
)

test_that("write_data_export writes a real, readable XLSX to an extension-less path", {
  skip_if_not_installed("openxlsx")
  f <- tempfile(); on.exit(unlink(f), add = TRUE)
  expect_error(write_data_export(make_list(), "Excel (.xlsx)", f), NA)
  expect_true(file.exists(f) && file.size(f) > 0)
  # XLSX is a ZIP: first two bytes are "PK"
  expect_equal(readBin(f, "raw", 2), as.raw(c(0x50, 0x4B)))
  # openxlsx READ requires a .xlsx name (the WRITE to an extension-less path is
  # what matters; Shiny serves it with the .xlsx filename). Copy to read back.
  fx <- paste0(f, ".xlsx"); on.exit(unlink(fx), add = TRUE)
  file.copy(f, fx, overwrite = TRUE)
  sheets <- openxlsx::getSheetNames(fx)
  expect_true("goods_benefits" %in% sheets)
  df <- openxlsx::read.xlsx(fx, sheet = "goods_benefits")
  expect_equal(nrow(df), 2L)
})

test_that("write_data_export writes valid JSON and reloadable RData", {
  fj <- tempfile(); on.exit(unlink(fj), add = TRUE)
  write_data_export(make_list(), "JSON (.json)", fj)
  parsed <- jsonlite::fromJSON(fj)
  expect_true("goods_benefits" %in% names(parsed))

  fr <- tempfile(); on.exit(unlink(fr), add = TRUE)
  write_data_export(make_list(), "R Data (.RData)", fr)
  e <- new.env(); load(fr, envir = e)
  expect_true("export_list" %in% ls(e))
  expect_equal(e$export_list$project_info$project_name, "Demo")
})

test_that("write_data_export CSV produces a readable table", {
  fc <- tempfile(); on.exit(unlink(fc), add = TRUE)
  write_data_export(make_list(), "CSV (.csv)", fc)
  df <- read.csv(fc, stringsAsFactors = FALSE)
  expect_true(nrow(df) >= 1)
})
