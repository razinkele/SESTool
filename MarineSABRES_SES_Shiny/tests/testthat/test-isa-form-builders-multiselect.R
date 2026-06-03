# tests/testthat/test-isa-form-builders-multiselect.R
# N:M forward links: the per-element "Linked to..." field must render as a
# multi-select so one element can declare many forward edges in a single panel
# — removing the need to duplicate a node to express multiple edges.
source_for_test("functions/isa_form_builders.R")

test_that("every forward Linked field def is marked multiple = TRUE", {
  i18n <- make_test_i18n()
  ch <- c("", "X001: A", "X002: B")
  linked_of <- function(fields, id) Filter(function(f) f$id == id, fields)[[1]]

  expect_true(isTRUE(linked_of(isa_fields_es(i18n, ch),  "linkedgb")$multiple))
  expect_true(isTRUE(linked_of(isa_fields_mpf(i18n, ch), "linkedes")$multiple))
  expect_true(isTRUE(linked_of(isa_fields_p(i18n, ch),   "linkedmpf")$multiple))
  expect_true(isTRUE(linked_of(isa_fields_a(i18n, ch),   "linkedp")$multiple))
  expect_true(isTRUE(linked_of(isa_fields_d(i18n, ch),   "linkeda")$multiple))
})

test_that("a Pressures panel renders its Linked-to-MPF field as a <select multiple>", {
  i18n <- make_test_i18n()
  ns <- shiny::NS("isa")
  fields <- isa_fields_p(i18n, c("", "MPF001: A", "MPF002: B"))
  html <- as.character(build_entry_panel_ui(ns, "p", "P001", fields, i18n))

  expect_match(html, "<select[^>]*multiple", perl = TRUE)      # is a multi-select
  expect_match(html, 'value="MPF001: A"', fixed = TRUE)        # real choice present
  expect_false(grepl('<option value=""', html, fixed = TRUE))  # blank placeholder dropped
})

test_that("a panel with no multiple field renders only single-selects (unchanged)", {
  i18n <- make_test_i18n()
  ns <- shiny::NS("isa")
  fields <- isa_fields_gb(i18n)   # Goods & Benefits has no forward Linked field
  html <- as.character(build_entry_panel_ui(ns, "gb", "GB001", fields, i18n))
  expect_false(grepl("<select[^>]*multiple", html, perl = TRUE))
})
