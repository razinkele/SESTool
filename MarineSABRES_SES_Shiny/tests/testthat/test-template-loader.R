library(testthat)

test_that("template_loader produces user_edited_matrices alongside matrices for non-empty cells", {
  # Check that the template_loader.R source contains user_edited_matrices logic
  root <- getwd()
  if (basename(root) == "testthat") root <- dirname(dirname(root))

  src <- paste(readLines(file.path(root, "functions", "template_loader.R"),
                         warn = FALSE), collapse = "\n")

  expect_true(
    grepl("user_edited_matrices", src, fixed = TRUE),
    info = "template_loader must build user_edited_matrices alongside matrices"
  )
})

test_that("load_template_from_json returns user_edited_matrices field in result", {
  root <- getwd()
  if (basename(root) == "testthat") root <- dirname(dirname(root))

  # Source the template loader functions
  source(file.path(root, "functions", "template_loader.R"), local = FALSE)

  # Create a minimal test template with required structure
  test_template <- list(
    template_name = "Test Template",
    template_description = "Test",
    dapsiwrm_framework = list(
      drivers = list(list(id = "D1", name = "Driver 1")),
      activities = list(list(id = "A1", name = "Activity 1")),
      pressures = list(list(id = "P1", name = "Pressure 1")),
      marine_processes = list(list(id = "S1", name = "State 1")),
      ecosystem_services = list(list(id = "ES1", name = "Service 1")),
      goods_benefits = list(list(id = "GB1", name = "Benefit 1")),
      responses = list(list(id = "R1", name = "Response 1"))
    ),
    connections = list(
      list(from_type = "driver", to_type = "activity", from_id = "D1", to_id = "A1", polarity = "+")
    )
  )

  # Write test template to temp file
  tmp_template <- tempfile(fileext = ".json")
  jsonlite::write_json(test_template, tmp_template, pretty = TRUE)
  on.exit(unlink(tmp_template))

  # Load the template
  result <- load_template_from_json(tmp_template, use_cache = FALSE)

  # Verify structure
  expect_type(result, "list")
  expect_true("user_edited_matrices" %in% names(result),
              info = "load_template_from_json must return user_edited_matrices field")
  expect_type(result$user_edited_matrices, "list")
})
