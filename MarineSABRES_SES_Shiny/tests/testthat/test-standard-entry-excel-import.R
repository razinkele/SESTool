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
