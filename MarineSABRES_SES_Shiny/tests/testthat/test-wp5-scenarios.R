# tests/testthat/test-wp5-scenarios.R
# WS-8 (spec 2026-10-16): the committed D5.1 data and the pure helpers.
source_for_test("functions/wp5_scenarios.R")

m <- load_wp5_worldview_matrix(force_reload = TRUE)
s <- load_wp5_scenarios(force_reload = TRUE)

test_that("the committed data has the D5.1 shape", {
  expect_false(is.null(m)); expect_false(is.null(s))
  expect_equal(vapply(s$scenarios, `[[`, "", "id"), c("ssp1_26", "ssp2_45", "ssp3_70", "ssp5_85"))
  expect_equal(unlist(s$pestle), PESTLE_CODES)
  expect_equal(unlist(s$slices), c("general", "hrmc", "sh", "lh"))
  expect_length(m$worldviews, 3L)
  expect_length(m$cells, 72L)
  expect_true(all(vapply(m$cells, `[[`, "", "transformation") %in% c("area", "europe", "none")))
  expect_true(all(nzchar(vapply(m$cells, `[[`, "", "rationale"))))
})

test_that("area-level cells are exactly D5.1 Table 5's blue cells", {
  area <- function(wv, ssp) sort(wp5_area_elements(m, wv, ssp))
  expect_equal(area("individualist", "ssp1_26"), sort(PESTLE_CODES))
  expect_equal(area("individualist", "ssp2_45"), sort(c("political", "economic", "social", "environmental")))
  expect_equal(area("hierarchy", "ssp1_26"), "social")
  expect_equal(area("hierarchy", "ssp2_45"), sort(c("political", "economic", "social", "technological")))
  for (ssp in c("ssp1_26", "ssp2_45", "ssp3_70", "ssp5_85")) expect_length(area("egalitarian", ssp), 0L)
})

test_that("heat-map match patterns reproduce D5.1's notation", {
  h <- wp5_heatmap_summary(m)
  pat <- function(wv, ssp) h$pattern[h$worldview == wv & h$ssp == ssp]
  expect_equal(pat("egalitarian", "ssp1_26"), "_ES___")
  expect_equal(pat("egalitarian", "ssp2_45"), "PES__E")
  expect_equal(pat("hierarchy", "ssp1_26"), "PE_TLE")
  expect_equal(pat("hierarchy", "ssp3_70"), "_EST__")
  expect_equal(pat("individualist", "ssp5_85"), "PESTLE")
  expect_equal(h$n_europe[h$worldview == "individualist" & h$ssp == "ssp3_70"], 6L)
})

test_that("matched responses follow the area elements of the cell (review focus 4)", {
  reg <- data.frame(ID = c("R1", "R2", "R3", "R4"), Name = c("a", "b", "c", "d"),
                    PestleTag = c("political;legal", "", "social", "legal"), stringsAsFactors = FALSE)
  hit <- wp5_matched_responses(reg, wp5_area_elements(m, "hierarchy", "ssp2_45"))
  expect_equal(hit$ID, c("R1", "R3"))
  expect_equal(hit$matched[[1]], "political")
  expect_equal(nrow(wp5_matched_responses(reg, wp5_area_elements(m, "hierarchy", "ssp1_26"))), 1L)   # social only
  expect_equal(nrow(wp5_matched_responses(reg, wp5_area_elements(m, "egalitarian", "ssp3_70"))), 0L)
  expect_equal(nrow(wp5_matched_responses(reg[, c("ID", "Name")], "social")), 0L)                     # legacy register
  expect_equal(nrow(wp5_matched_responses(NULL, "social")), 0L)
})

test_that("a missing or corrupt file gives NULL, not an error", {
  expect_null(load_wp5_worldview_matrix(path = tempfile(fileext = ".json"), force_reload = TRUE))
  bad <- tempfile(fileext = ".json"); writeLines("{ not json", bad)
  expect_null(load_wp5_scenarios(path = bad, force_reload = TRUE))
  load_wp5_scenarios(force_reload = TRUE); load_wp5_worldview_matrix(force_reload = TRUE)   # restore the cache
})
