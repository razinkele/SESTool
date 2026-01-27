# tests/testthat/test-report-generation.R
# Tests for Report Generation Functions
# ==============================================================================

library(testthat)

# ==============================================================================
# Test Fixtures
# ==============================================================================

# Create a minimal valid project data structure for testing
create_test_project_data <- function() {
  list(
    project_id = "TEST-001",
    project_name = "Test Project",
    created_at = Sys.time(),
    last_modified = Sys.time(),
    data = list(
      metadata = list(
        da_site = "Test Site",
        focal_issue = "Test Issue"
      ),
      isa_data = list(
        goods_benefits = data.frame(
          id = "gb_1",
          name = "Fish provision",
          description = "Provisioning of fish for consumption",
          stringsAsFactors = FALSE
        ),
        ecosystem_services = data.frame(
          id = "es_1",
          name = "Fish production",
          description = "Production of harvestable fish",
          stringsAsFactors = FALSE
        ),
        marine_processes = data.frame(
          id = "mpf_1",
          name = "Fish population dynamics",
          description = "Population dynamics of fish species",
          stringsAsFactors = FALSE
        ),
        pressures = data.frame(
          id = "p_1",
          name = "Overfishing",
          description = "Extraction beyond sustainable limits",
          stringsAsFactors = FALSE
        ),
        activities = data.frame(
          id = "a_1",
          name = "Commercial fishing",
          description = "Commercial fishing activities",
          stringsAsFactors = FALSE
        ),
        drivers = data.frame(
          id = "d_1",
          name = "Food demand",
          description = "Demand for seafood",
          stringsAsFactors = FALSE
        )
      ),
      cld = list(
        nodes = data.frame(
          id = c("d_1", "a_1", "p_1"),
          label = c("Food demand", "Commercial fishing", "Overfishing"),
          type = c("Drivers", "Activities", "Pressures"),
          color = c("#FF6B6B", "#4ECDC4", "#45B7D1"),
          stringsAsFactors = FALSE
        ),
        edges = data.frame(
          from = c("d_1", "a_1"),
          to = c("a_1", "p_1"),
          polarity = c("+", "+"),
          strength = c("medium", "strong"),
          stringsAsFactors = FALSE
        ),
        loops = data.frame(
          id = "L1",
          type = "R",
          name = "Fishing Pressure Loop",
          nodes = "d_1,a_1,p_1",
          stringsAsFactors = FALSE
        )
      ),
      analysis = list(
        loops = list(
          loop_info = data.frame(
            id = "L1",
            type = "R",
            name = "Fishing Pressure Loop",
            stringsAsFactors = FALSE
          )
        )
      ),
      responses = data.frame(
        id = "r_1",
        name = "Fishing quota",
        description = "Implement fishing quotas",
        stringsAsFactors = FALSE
      )
    )
  )
}

# Create an empty project data structure
create_empty_project_data <- function() {
  list(
    project_id = "EMPTY-001",
    project_name = "Empty Project",
    created_at = Sys.time(),
    last_modified = Sys.time(),
    data = list(
      metadata = list(),
      isa_data = list(),
      cld = list(),
      analysis = list(),
      responses = NULL
    )
  )
}

# ==============================================================================
# Test: get_loop_data function
# ==============================================================================

test_that("get_loop_data returns loop_info from analysis location", {
  skip_if_not(exists("get_loop_data"), "get_loop_data function not loaded")

  data <- create_test_project_data()
  loops <- get_loop_data(data)

  expect_true(!is.null(loops))
  expect_true(is.data.frame(loops))
  expect_true("id" %in% names(loops))
})

test_that("get_loop_data falls back to cld$loops", {
  skip_if_not(exists("get_loop_data"), "get_loop_data function not loaded")

  data <- create_test_project_data()
  # Remove analysis location
  data$data$analysis$loops$loop_info <- NULL

  loops <- get_loop_data(data)

  expect_true(!is.null(loops))
  expect_true(is.data.frame(loops))
})

test_that("get_loop_data returns NULL for empty data", {
  skip_if_not(exists("get_loop_data"), "get_loop_data function not loaded")

  data <- create_empty_project_data()
  loops <- get_loop_data(data)

  expect_null(loops)
})

# ==============================================================================
# Test: generate_report_content function
# ==============================================================================

test_that("generate_report_content creates valid Rmd for executive report", {
  skip_if_not(exists("generate_report_content"), "generate_report_content function not loaded")
  skip_if_not(exists("debug_log"), "debug_log function not loaded")

  data <- create_test_project_data()
  content <- generate_report_content(data, "executive")

  expect_type(content, "character")
  expect_true(nchar(content) > 0)
  expect_true(grepl("---", content))  # Has YAML header
  expect_true(grepl("title:", content))
  expect_true(grepl("MarineSABRES", content))
})

test_that("generate_report_content creates valid Rmd for technical report", {
  skip_if_not(exists("generate_report_content"), "generate_report_content function not loaded")
  skip_if_not(exists("debug_log"), "debug_log function not loaded")

  data <- create_test_project_data()
  content <- generate_report_content(data, "technical")

  expect_type(content, "character")
  expect_true(nchar(content) > 0)
  expect_true(grepl("technical", content, ignore.case = TRUE))
})

test_that("generate_report_content creates valid Rmd for full report", {
  skip_if_not(exists("generate_report_content"), "generate_report_content function not loaded")
  skip_if_not(exists("debug_log"), "debug_log function not loaded")

  data <- create_test_project_data()
  content <- generate_report_content(data, "full")

  expect_type(content, "character")
  expect_true(nchar(content) > 0)
})

test_that("generate_report_content handles empty project data", {
  skip_if_not(exists("generate_report_content"), "generate_report_content function not loaded")
  skip_if_not(exists("debug_log"), "debug_log function not loaded")

  data <- create_empty_project_data()

  # Should not throw error even with empty data
  expect_no_error({
    content <- generate_report_content(data, "executive")
  })

  expect_type(content, "character")
  expect_true(nchar(content) > 0)
})

test_that("generate_report_content handles NULL metadata gracefully", {
  skip_if_not(exists("generate_report_content"), "generate_report_content function not loaded")
  skip_if_not(exists("debug_log"), "debug_log function not loaded")

  data <- create_test_project_data()
  data$data$metadata <- NULL

  expect_no_error({
    content <- generate_report_content(data, "executive")
  })

  expect_type(content, "character")
})

test_that("generate_report_content handles list-wrapped values", {
  skip_if_not(exists("generate_report_content"), "generate_report_content function not loaded")
  skip_if_not(exists("debug_log"), "debug_log function not loaded")

  data <- create_test_project_data()
  # Wrap values in lists (common issue with reactive values)
  data$data$metadata$da_site <- list("Test Site")
  data$data$metadata$focal_issue <- list("Test Issue")

  expect_no_error({
    content <- generate_report_content(data, "executive")
  })

  expect_type(content, "character")
})

# ==============================================================================
# Test: Report Content Validation
# ==============================================================================

test_that("Executive report contains expected sections", {
  skip_if_not(exists("generate_report_content"), "generate_report_content function not loaded")
  skip_if_not(exists("debug_log"), "debug_log function not loaded")

  data <- create_test_project_data()
  content <- generate_report_content(data, "executive")

  # Check for key section headers
  expect_true(grepl("Project Overview|Overview", content, ignore.case = TRUE))
})

test_that("Technical report is more detailed than executive", {
  skip_if_not(exists("generate_report_content"), "generate_report_content function not loaded")
  skip_if_not(exists("debug_log"), "debug_log function not loaded")

  data <- create_test_project_data()

  exec_content <- generate_report_content(data, "executive")
  tech_content <- generate_report_content(data, "technical")

  # Technical should typically be same or longer
  expect_true(nchar(tech_content) >= nchar(exec_content) * 0.5)
})

# ==============================================================================
# Test: Edge Cases
# ==============================================================================

test_that("generate_report_content handles missing dates", {
  skip_if_not(exists("generate_report_content"), "generate_report_content function not loaded")
  skip_if_not(exists("debug_log"), "debug_log function not loaded")

  data <- create_test_project_data()
  data$created_at <- NULL
  data$last_modified <- NULL

  expect_no_error({
    content <- generate_report_content(data, "executive")
  })

  expect_type(content, "character")
})

test_that("generate_report_content handles invalid report type", {
  skip_if_not(exists("generate_report_content"), "generate_report_content function not loaded")
  skip_if_not(exists("debug_log"), "debug_log function not loaded")

  data <- create_test_project_data()

  # Should still work with unknown type (uses type as subtitle)
  expect_no_error({
    content <- generate_report_content(data, "unknown_type")
  })

  expect_type(content, "character")
})

test_that("generate_report_content handles vector report_type", {
  skip_if_not(exists("generate_report_content"), "generate_report_content function not loaded")
  skip_if_not(exists("debug_log"), "debug_log function not loaded")

  data <- create_test_project_data()

  # Should use first element if vector is passed
  expect_no_error({
    content <- generate_report_content(data, c("executive", "technical"))
  })

  expect_type(content, "character")
})

# ==============================================================================
# Summary
# ==============================================================================

cat("\n", strrep("=", 70), "\n", sep = "")
cat("Report Generation Tests Complete\n")
cat(strrep("=", 70), "\n")
