# tests/testthat/test-linked-by-name.R
# Name-based recovery of legacy (v1.13.x) Standard Entry exports, where forward
# connections live in label-form LinkedX columns ("ID: Name") and element IDs
# may be duplicated (the old positional-ID bug). Resolving links by NAME keeps
# edges attached to the correct element after duplicate-ID repair.
source_for_test("functions/matrix_from_linked.R")

test_that("resolve_linked_to_target_ids prefers NAME match over a stale duplicate ID", {
  # marine_processes AFTER reconcile: the two original 'MPF005' rows now have
  # distinct IDs; the name "Biodiversity richness" belongs to MPF019.
  tgt <- data.frame(
    ID   = c("MPF005", "MPF019"),
    Name = c("Fish biomass", "Biodiversity richness"),
    stringsAsFactors = FALSE
  )
  # A pressure's label still says "MPF005: Biodiversity richness" (stale ID).
  expect_equal(resolve_linked_to_target_ids("MPF005: Biodiversity richness", tgt), "MPF019")
})

test_that("resolve_linked_to_target_ids falls back to bare-ID match", {
  tgt <- data.frame(ID = c("GB001", "GB002"), Name = c("Food", "Energy"),
                    stringsAsFactors = FALSE)
  expect_equal(resolve_linked_to_target_ids("GB001", tgt), "GB001")           # bare id
  expect_equal(resolve_linked_to_target_ids("GB002: Energy", tgt), "GB002")   # label, name+id agree
})

test_that("resolve_linked_to_target_ids handles multi-link, whitespace, case, and misses", {
  tgt <- data.frame(ID = c("GB001", "GB002"), Name = c("Food", "Energy"),
                    stringsAsFactors = FALSE)
  expect_equal(resolve_linked_to_target_ids("GB001: Food|GB002: Energy", tgt), c("GB001", "GB002"))
  expect_equal(resolve_linked_to_target_ids("ZZ9:  energy ", tgt), "GB002")   # name match wins despite junk id + ws/case
  expect_equal(resolve_linked_to_target_ids("ZZ999: Nope", tgt), character(0))# unresolvable
  expect_equal(resolve_linked_to_target_ids("", tgt), character(0))
  expect_equal(resolve_linked_to_target_ids(NA, tgt), character(0))
})

test_that("rebuild_forward_matrix_by_name builds an ID-keyed matrix from label-form links", {
  src <- data.frame(ID = c("P001", "P002"), Name = c("Overfishing", "Bycatch"),
                    LinkedMPF = c("MPF005: Biodiversity richness", "MPF005: Fish biomass"),
                    Confidence = c("High", NA), stringsAsFactors = FALSE)
  tgt <- data.frame(ID = c("MPF005", "MPF019"), Name = c("Fish biomass", "Biodiversity richness"),
                    stringsAsFactors = FALSE)
  m <- rebuild_forward_matrix_by_name(src, "LinkedMPF", tgt)

  expect_equal(dim(m), c(2, 2))
  expect_equal(rownames(m), c("P001", "P002"))
  expect_equal(colnames(m), c("MPF005", "MPF019"))
  # P001 -> "Biodiversity richness" = MPF019 (NOT the stale MPF005); conf High
  expect_equal(m["P001", "MPF019"], "+Medium:High")
  expect_equal(m["P001", "MPF005"], "")
  # P002 -> "Fish biomass" = MPF005; no Confidence -> default Medium
  expect_equal(m["P002", "MPF005"], "+Medium:Medium")
})
