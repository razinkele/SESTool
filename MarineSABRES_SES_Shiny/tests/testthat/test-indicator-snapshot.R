# tests/testthat/test-indicator-snapshot.R
# WS-4: element indicator columns, registry snapshot, drift detection, module wiring.
library(testthat)
source_for_test(c("functions/isa_form_builders.R", "functions/ui_components.R",
                  "functions/indicator_registry.R", "functions/indicator_snapshot.R"))

gb_cols <- c("Name", "Type", "Description", "Stakeholder", "Importance", "Trend")

test_that("indicator columns of a carried-over (loaded) row survive an exercise save", {
  existing <- data.frame(ID = "GB001", Name = "Fish catch", Type = "Provisioning", Description = "",
                         Stakeholder = "", Importance = "High", Trend = "Stable",
                         Indicator = "Landings", Indicator_Unit = "t", Data_Source = "ISTAT",
                         Registry_Id = "", Registry_Version = "", stringsAsFactors = FALSE)
  out <- merge_collected_with_existing(existing, data.frame(), "GB001", character(0),
                                       c(gb_cols, ISA_INDICATOR_COLUMNS))
  expect_equal(out$Indicator, "Landings")
  expect_equal(out$Indicator_Unit, "t")
  expect_equal(out$Data_Source, "ISTAT")
})

test_that("legacy lowercase indicator columns merge into the canonical ones (no duplicates)", {
  legacy <- data.frame(id = "GB001", name = "Fish catch", type = "Provisioning", indicator = "Landings",
                       indicator_unit = "t", data_source = "ISTAT", stringsAsFactors = FALSE)
  out <- merge_collected_with_existing(legacy, data.frame(), "GB001", character(0),
                                       c(gb_cols, ISA_INDICATOR_COLUMNS))
  expect_equal(sum(tolower(names(out)) == "indicator"), 1L)
  expect_equal(out$Indicator, "Landings")
  expect_equal(out$Registry_Id, "")
})

test_that("indicator_col reads case-insensitively and blanks NA", {
  df <- data.frame(registry_id = c("F_01", NA), stringsAsFactors = FALSE)
  expect_equal(indicator_col(df, "Registry_Id"), c("F_01", ""))
  expect_equal(indicator_col(df, "Indicator"), c("", ""))
  expect_equal(indicator_col(NULL, "Indicator"), character(0))
})

test_that("JSON normalisation does not add a second indicator column next to Indicator", {
  pd <- list(data = list(isa_data = list(goods_benefits = data.frame(
    ID = "GB001", Name = "Fish catch", Indicator = "Landings", stringsAsFactors = FALSE))))
  out <- normalize_json_project_data(pd)
  nm <- names(out$data$isa_data$goods_benefits)
  expect_equal(sum(tolower(nm) == "indicator"), 1L)
})

test_that("ragged list-of-lists rows (NA fields omitted by toJSON) do not drop the category", {
  # auto_save_module.R serialised without na = "null", so a row with an empty
  # Indicator omits the key. Before WS-4 this made do.call(rbind, ...) error at
  # data_structure.R:882 and the whole category became NULL (verified 2026-10-11).
  df <- data.frame(ID = c("D1", "D2"), Name = c("a", "b"), Indicator = c("x", NA),
                   stringsAsFactors = FALSE)
  js <- jsonlite::toJSON(list(data = list(isa_data = list(drivers = df))),
                         auto_unbox = TRUE, null = "null")          # no na = "null"
  out <- normalize_json_project_data(jsonlite::fromJSON(js, simplifyVector = FALSE))
  d <- out$data$isa_data$drivers
  expect_equal(nrow(d), 2L)
  expect_equal(indicator_col(d, "Indicator"), c("x", ""))
})
