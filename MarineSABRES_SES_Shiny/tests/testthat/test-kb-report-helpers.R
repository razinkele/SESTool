test_that("create_empty_project includes regional_sea and ecosystem_type in metadata", {
  skip_if_not(exists("create_empty_project", mode = "function"), "not available")
  proj <- create_empty_project("Test")
  expect_true("regional_sea" %in% names(proj$data$metadata),
              info = "Metadata must include regional_sea field")
  expect_true("ecosystem_type" %in% names(proj$data$metadata),
              info = "Metadata must include ecosystem_type field")
  expect_null(proj$data$metadata$regional_sea)
  expect_null(proj$data$metadata$ecosystem_type)
})
