# tests/testthat/test-standard-entry-excel-import.R
source_for_test("functions/standard_entry_excel_import.R")
library(openxlsx)

# Build an isa_data-like list, export it the way the VISIBLE button does
# (write_isa_element_sheets include_adjacency=TRUE), then read it back.
source_for_test("functions/isa_export_helpers.R")

make_isa <- function() {
  list(
    goods_benefits = data.frame(ID = "GB001", Name = "Food", Type = "", Description = "",
                                Stakeholder = "", Importance = "", Trend = "", stringsAsFactors = FALSE),
    ecosystem_services = data.frame(ID = "ES001", Name = "Fish", Type = "", Description = "",
                                    LinkedGB = "GB001", Mechanism = "", Confidence = "High", stringsAsFactors = FALSE),
    marine_processes = data.frame(ID = "MPF001", Name = "Prod", Type = "", Description = "",
                                  LinkedES = "ES001", Mechanism = "", Spatial = "", stringsAsFactors = FALSE),
    pressures = data.frame(ID = "P001", Name = "Fishing", Type = "", Description = "",
                           LinkedMPF = "MPF001", Intensity = "", Spatial = "", Temporal = "", stringsAsFactors = FALSE),
    activities = data.frame(ID = "A001", Name = "Trawl", Sector = "", Description = "",
                            LinkedP = "P001", Scale = "", Frequency = "", stringsAsFactors = FALSE),
    drivers = data.frame(ID = "D001", Name = "Demand", Type = "", Description = "",
                         LinkedA = "A001", Trend = "", Controllability = "", stringsAsFactors = FALSE),
    adjacency_matrices = list(
      es_gb = matrix("+Strong:High", 1, 1, dimnames = list("ES001", "GB001")),
      gb_d  = matrix("-Weak:Medium", 1, 1, dimnames = list("GB001", "D001"))
    )
  )
}

test_that("faithful round-trip: Matrix_* sheets reconstruct exact edge cells", {
  isa <- make_isa()
  wb <- openxlsx::createWorkbook()
  write_isa_element_sheets(wb, isa, include_adjacency = TRUE)
  tmp <- tempfile(fileext = ".xlsx")
  openxlsx::saveWorkbook(wb, tmp, overwrite = TRUE)

  out <- read_standard_entry_workbook(tmp)

  expect_equal(as.character(out$goods_benefits$ID), "GB001")
  expect_equal(as.character(out$drivers$ID), "D001")
  expect_equal(out$adjacency_matrices$es_gb["ES001", "GB001"], "+Strong:High")
  expect_equal(out$adjacency_matrices$gb_d["GB001", "D001"], "-Weak:Medium")
  # all element columns coerced to character
  expect_true(all(vapply(out$ecosystem_services, is.character, logical(1))))
})

test_that("faithful round-trip preserves dimnames + cells for a non-square matrix", {
  isa <- list(
    goods_benefits = data.frame(ID = c("GB001","GB002","GB003"), Name = c("A","B","C"),
                                Type = "", Description = "", Stakeholder = "", Importance = "", Trend = "",
                                stringsAsFactors = FALSE),
    ecosystem_services = data.frame(ID = c("ES001","ES002"), Name = c("X","Y"),
                                    Type = "", Description = "", LinkedGB = c("GB001","GB002"),
                                    Mechanism = "", Confidence = "Medium", stringsAsFactors = FALSE),
    marine_processes = data.frame(ID = character(), Name = character()),
    pressures = data.frame(ID = character(), Name = character()),
    activities = data.frame(ID = character(), Name = character()),
    drivers = data.frame(ID = character(), Name = character()),
    adjacency_matrices = list(
      es_gb = matrix(c("+Strong:High", "",            # ES001->GB001, ES002->GB001
                       "", "-Weak:Low",               # ES001->GB002, ES002->GB002
                       "+Medium:Medium", ""),         # ES001->GB003, ES002->GB003
                     nrow = 2, ncol = 3,
                     dimnames = list(c("ES001","ES002"), c("GB001","GB002","GB003")))
    )
  )
  wb <- openxlsx::createWorkbook()
  write_isa_element_sheets(wb, isa, include_adjacency = TRUE)
  tmp <- tempfile(fileext = ".xlsx")
  openxlsx::saveWorkbook(wb, tmp, overwrite = TRUE)

  out <- read_standard_entry_workbook(tmp)
  m <- out$adjacency_matrices$es_gb

  expect_equal(rownames(m), c("ES001","ES002"))
  expect_equal(colnames(m), c("GB001","GB002","GB003"))
  expect_equal(m["ES001","GB001"], "+Strong:High")
  expect_equal(m["ES002","GB002"], "-Weak:Low")
  expect_equal(m["ES001","GB003"], "+Medium:Medium")
  expect_equal(m["ES002","GB001"], "")   # empty cell round-trips to ""
})

test_that("rejects a non-Standard-Entry workbook (generic Elements/Connections)", {
  wb <- openxlsx::createWorkbook()
  openxlsx::addWorksheet(wb, "Elements");    openxlsx::writeData(wb, "Elements", data.frame(Label = "x", type = "Driver"))
  openxlsx::addWorksheet(wb, "Connections"); openxlsx::writeData(wb, "Connections", data.frame(From = "x", To = "y"))
  tmp <- tempfile(fileext = ".xlsx"); openxlsx::saveWorkbook(wb, tmp, overwrite = TRUE)

  expect_error(read_standard_entry_workbook(tmp), class = "se_import_not_recognized")
})

test_that("rejects an element sheet that lacks ID/Name columns", {
  wb <- openxlsx::createWorkbook()
  openxlsx::addWorksheet(wb, "Drivers"); openxlsx::writeData(wb, "Drivers", data.frame(Foo = 1, Bar = 2))
  tmp <- tempfile(fileext = ".xlsx"); openxlsx::saveWorkbook(wb, tmp, overwrite = TRUE)

  expect_error(read_standard_entry_workbook(tmp), class = "se_import_not_recognized")
})

test_that("missing file raises a clear error", {
  expect_error(read_standard_entry_workbook(tempfile(fileext = ".xlsx")), "file not found")
})

test_that("no Matrix_* sheets: reader returns elements with Linked* and no adjacency_matrices", {
  isa <- make_isa()
  wb <- openxlsx::createWorkbook()
  # Element sheets ONLY (mimic create_isa_analysis_workbook: no adjacency)
  write_isa_element_sheets(wb, isa, include_adjacency = FALSE)
  tmp <- tempfile(fileext = ".xlsx"); openxlsx::saveWorkbook(wb, tmp, overwrite = TRUE)

  out <- read_standard_entry_workbook(tmp)
  expect_null(out$adjacency_matrices)
  expect_equal(as.character(out$ecosystem_services$LinkedGB), "GB001")
})
