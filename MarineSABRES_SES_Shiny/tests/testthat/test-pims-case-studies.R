# tests/testthat/test-pims-case-studies.R
# User feedback 2026-10-21 "Only three DA's in the DA selection in the PIMS
# module": the selector now lists every case study, grouped under its DA.
source_for_test(c("modules/pims_module.R", "server/bookmarking.R"))
pims_project_ui <- get("pims_project_ui", envir = .GlobalEnv)

case_studies <- c("Tuscan Archipelago", "Iceland", "Greenland", "Faroe Islands",
                  "Azores", "Madeira", "Canary Islands")

test_that("each DA lists its case studies", {
  expect_setequal(names(DA_CASE_STUDIES), DA_SITES)
  expect_setequal(unname(unlist(lapply(DA_CASE_STUDIES, names))), case_studies)
  expect_setequal(names(DA_CASE_STUDIES[["Arctic Northeast Atlantic"]]),
                  c("Iceland", "Greenland", "Faroe Islands"))
  expect_setequal(names(DA_CASE_STUDIES[["Macaronesia"]]),
                  c("Azores", "Madeira", "Canary Islands"))
})

test_that("every accepted DA value maps to its WP5 context", {
  ctx <- c("Tuscan Archipelago" = "tuscan", "Arctic Northeast Atlantic" = "arctic",
           "Macaronesia" = "macaronesia")
  for (da in names(DA_CASE_STUDIES)) {
    for (v in c(da, unname(DA_CASE_STUDIES[[da]]))) {
      p <- create_empty_project("x"); p$data$metadata$da_site <- v
      expect_identical(wp5_da_for_project(p), ctx[[da]], label = v)
    }
  }
})

test_that("the PIMS selector groups the case studies under their DA", {
  html <- as.character(pims_project_ui("p", list(t = function(k) k)))
  for (da in DA_SITES) {
    expect_match(html, sprintf('<optgroup label="%s">', da), fixed = TRUE)
    # Saved projects store the bare DA name; it must stay selectable.
    expect_match(html, sprintf('<option value="%s">', da), fixed = TRUE)
  }
  for (v in unlist(DA_CASE_STUDIES)) {
    expect_match(html, sprintf('<option value="%s">', v), fixed = TRUE)
  }
  expect_match(html, '<option value=""', fixed = TRUE)
})

test_that("bookmark restore accepts case-study values and still rejects others", {
  v <- DA_CASE_STUDIES[["Macaronesia"]][["Azores"]]
  expect_equal(sanitize_bookmark_values(list(metadata_da_site = v))$metadata_da_site, v)
  expect_equal(sanitize_bookmark_values(list(metadata_da_site = "Macaronesia"))$metadata_da_site,
               "Macaronesia")
  expect_null(sanitize_bookmark_values(list(metadata_da_site = "Atlantis"))$metadata_da_site)
})
