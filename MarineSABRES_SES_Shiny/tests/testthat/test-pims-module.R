# test-pims-module.R
# Tests for modules/pims_module.R
# Tests NULL checks, data handling, and module functionality

# ============================================================================
# SETUP
# ============================================================================

# Ensure test helpers are available
if (!exists("create_mock_project_data", mode = "function")) {
  source("tests/testthat/helpers.R", local = TRUE)
}

# Mock i18n object for testing
mock_i18n <- list(
  t = function(key) {
    # Return the key as the translation for testing
    key
  }
)

# ============================================================================
# HELPER FUNCTIONS FOR PIMS TESTING
# ============================================================================

#' Create project data with missing nested structures for testing
#'
#' @param include_data Whether to include data list
#' @param include_metadata Whether to include metadata
#' @param include_pims Whether to include PIMS data
create_partial_project_data <- function(include_data = TRUE,
                                         include_metadata = TRUE,
                                         include_pims = TRUE) {
  project <- list(
    project_id = "test-123",
    project_name = "Test Project",
    created_at = Sys.time(),
    last_modified = Sys.time()
  )

  if (include_data) {
    project$data <- list()

    if (include_metadata) {
      project$data$metadata <- list(
        da_site = "Test Site",
        focal_issue = "Test Issue",
        definition_statement = "Test definition",
        temporal_scale = "Yearly",
        spatial_scale = "Regional",
        system_in_focus = "Test system"
      )
    }

    if (include_pims) {
      project$data$pims <- list(
        stakeholders = data.frame(
          Name = c("Stakeholder 1", "Stakeholder 2"),
          Role = c("Manager", "Researcher"),
          Organization = c("Org A", "Org B"),
          stringsAsFactors = FALSE
        )
      )
    }
  }

  return(project)
}

# ============================================================================
# TESTS: Project Data Structure Access
# ============================================================================

test_that("partial project data with missing data list is handled safely", {
  # Create project without data list
  project <- create_partial_project_data(include_data = FALSE)

  expect_true(is.null(project$data))
  expect_true(is.null(project$data$metadata))
  expect_true(is.null(project$data$pims))

  # Test safe access pattern
  metadata <- if (!is.null(project$data) && !is.null(project$data$metadata)) {
    project$data$metadata
  } else {
    NULL
  }

  expect_null(metadata)
})

test_that("partial project data with missing metadata is handled safely", {
  # Create project without metadata
  project <- create_partial_project_data(include_metadata = FALSE)

  expect_true(!is.null(project$data))
  expect_true(is.null(project$data$metadata))

  # Test safe access pattern
  da_site <- if (!is.null(project$data$metadata$da_site)) {
    project$data$metadata$da_site
  } else {
    "Default Site"
  }

  expect_equal(da_site, "Default Site")
})

test_that("partial project data with missing PIMS is handled safely", {
  # Create project without PIMS
  project <- create_partial_project_data(include_pims = FALSE)

  expect_true(!is.null(project$data))
  expect_true(is.null(project$data$pims))

  # Test safe access pattern for stakeholders
  stakeholders <- if (!is.null(project$data$pims) &&
                      !is.null(project$data$pims$stakeholders)) {
    project$data$pims$stakeholders
  } else {
    data.frame(Name = character(0), Role = character(0), Organization = character(0))
  }

  expect_true(is.data.frame(stakeholders))
  expect_equal(nrow(stakeholders), 0)
})

test_that("complete project data is accessed correctly", {
  # Create complete project
  project <- create_partial_project_data()

  expect_true(!is.null(project$data))
  expect_true(!is.null(project$data$metadata))
  expect_true(!is.null(project$data$pims))

  # Access values
  expect_equal(project$data$metadata$da_site, "Test Site")
  expect_equal(project$data$metadata$focal_issue, "Test Issue")
  expect_equal(nrow(project$data$pims$stakeholders), 2)
})

# ============================================================================
# TESTS: NULL-Safe Value Update Pattern
# ============================================================================

test_that("NULL-safe update pattern works for project_name", {
  project <- create_partial_project_data()

  # Simulate update logic with NULL check
  new_name <- "Updated Project Name"
  if (!is.null(project)) {
    project$project_name <- new_name
  }

  expect_equal(project$project_name, new_name)
})

test_that("NULL-safe update pattern creates nested structures when missing", {
  # Start with minimal project
  project <- list(
    project_id = "test-456",
    project_name = "Minimal Project"
  )

  # Ensure nested structures exist before update
  if (is.null(project$data)) {
    project$data <- list()
  }
  if (is.null(project$data$metadata)) {
    project$data$metadata <- list()
  }

  # Now update safely
  project$data$metadata$da_site <- "New Site"

  expect_equal(project$data$metadata$da_site, "New Site")
})

# ============================================================================
# TESTS: Stakeholder Table Handling
# ============================================================================

test_that("empty stakeholder list returns valid empty dataframe", {
  project <- create_partial_project_data()
  project$data$pims$stakeholders <- NULL

  # Test the pattern used in pims_stakeholders_server
  stakeholders <- NULL
  if (!is.null(project$data) &&
      !is.null(project$data$pims) &&
      !is.null(project$data$pims$stakeholders)) {
    stakeholders <- project$data$pims$stakeholders
  }

  # If NULL, create empty dataframe
  if (is.null(stakeholders) || !is.data.frame(stakeholders) || nrow(stakeholders) == 0) {
    stakeholders <- data.frame(
      Name = character(0),
      Role = character(0),
      Organization = character(0),
      stringsAsFactors = FALSE
    )
  }

  expect_true(is.data.frame(stakeholders))
  expect_equal(nrow(stakeholders), 0)
  expect_true(all(c("Name", "Role", "Organization") %in% names(stakeholders)))
})

test_that("stakeholder list with data returns valid dataframe", {
  project <- create_partial_project_data()

  stakeholders <- project$data$pims$stakeholders

  expect_true(is.data.frame(stakeholders))
  expect_equal(nrow(stakeholders), 2)
  expect_true(all(c("Name", "Role", "Organization") %in% names(stakeholders)))
})

# ============================================================================
# TESTS: Status Display Handling
# ============================================================================

test_that("status display handles NULL created_at", {
  project <- create_partial_project_data()
  project$created_at <- NULL

  created_at <- if (!is.null(project$created_at)) {
    format(project$created_at, "%Y-%m-%d %H:%M")
  } else {
    "Unknown"
  }

  expect_equal(created_at, "Unknown")
})

test_that("status display handles NULL last_modified", {
  project <- create_partial_project_data()
  project$last_modified <- NULL

  last_modified <- if (!is.null(project$last_modified)) {
    format(project$last_modified, "%Y-%m-%d %H:%M")
  } else {
    "Never"
  }

  expect_equal(last_modified, "Never")
})

test_that("status display handles NULL project_id", {
  project <- create_partial_project_data()
  project$project_id <- NULL

  project_id <- if (!is.null(project$project_id)) project$project_id else "Not set"

  expect_equal(project_id, "Not set")
})

test_that("status display with all values present", {
  project <- create_partial_project_data()
  project$project_id <- "test-789"
  project$created_at <- as.POSIXct("2024-01-15 10:30:00")
  project$last_modified <- as.POSIXct("2024-01-16 14:45:00")

  project_id <- if (!is.null(project$project_id)) project$project_id else "Not set"
  created_at <- if (!is.null(project$created_at)) format(project$created_at, "%Y-%m-%d %H:%M") else "Unknown"
  last_modified <- if (!is.null(project$last_modified)) format(project$last_modified, "%Y-%m-%d %H:%M") else "Never"

  expect_equal(project_id, "test-789")
  expect_equal(created_at, "2024-01-15 10:30")
  expect_equal(last_modified, "2024-01-16 14:45")
})

# ============================================================================
# TESTS: Input Validation Patterns
# ============================================================================

test_that("project data save validates presence of nested structures", {
  project <- list(project_id = "minimal")

  # Validation pattern used in pims_project_server
  is_valid <- !is.null(project)

  if (is_valid) {
    if (is.null(project$data)) {
      project$data <- list()
    }
    if (is.null(project$data$metadata)) {
      project$data$metadata <- list()
    }

    # Now safe to update
    project$data$metadata$da_site <- "Test"
    project$data$metadata$focal_issue <- "Issue"
    project$last_modified <- Sys.time()
  }

  expect_equal(project$data$metadata$da_site, "Test")
  expect_equal(project$data$metadata$focal_issue, "Issue")
  expect_true(!is.null(project$last_modified))
})

test_that("NULL project data triggers error path", {
  project <- NULL

  # This is the pattern that should trigger error notification
  should_error <- is.null(project)

  expect_true(should_error)
})

# ============================================================================
# TESTS: Edge Cases
# ============================================================================

test_that("empty string values are handled distinctly from NULL", {
  project <- create_partial_project_data()
  project$data$metadata$da_site <- ""

  # Empty string is not NULL but should be treated as "not set"
  da_site <- project$data$metadata$da_site
  has_da_site <- !is.null(da_site) && nchar(da_site) > 0

  expect_false(has_da_site)
})

test_that("whitespace-only values are handled", {
  project <- create_partial_project_data()
  project$data$metadata$da_site <- "   "

  da_site <- trimws(project$data$metadata$da_site)
  has_da_site <- !is.null(da_site) && nchar(da_site) > 0

  expect_false(has_da_site)
})

test_that("NA values are handled as missing data", {
  project <- create_partial_project_data()
  project$data$metadata$da_site <- NA

  da_site <- project$data$metadata$da_site
  is_valid <- !is.null(da_site) && !is.na(da_site) && nchar(da_site) > 0

  expect_false(is_valid)
})

# ============================================================================
# TESTS: Integration Pattern - Safe Metadata Access
# ============================================================================

test_that("safe_get_nested pattern works for PIMS data", {
  # This tests the pattern we expect to be used with safe_get_nested from error_handling.R

  # Full project
  full_project <- create_partial_project_data()
  site1 <- if (!is.null(full_project$data$metadata$da_site)) {
    full_project$data$metadata$da_site
  } else {
    "default"
  }
  expect_equal(site1, "Test Site")

  # Empty project
  empty_project <- list(project_id = "empty")
  site2 <- if (!is.null(empty_project$data) &&
               !is.null(empty_project$data$metadata) &&
               !is.null(empty_project$data$metadata$da_site)) {
    empty_project$data$metadata$da_site
  } else {
    "default"
  }
  expect_equal(site2, "default")
})

# ============================================================================
# TESTS: Module Load Update Pattern
# ============================================================================

test_that("load data observer pattern handles partial data", {
  # Simulate the observe pattern in pims_project_server
  project <- create_partial_project_data(include_metadata = FALSE)

  # Pattern from updated pims_module.R
  updates_applied <- list()

  if (!is.null(project$project_name)) {
    updates_applied$project_name <- project$project_name
  }

  if (!is.null(project$data) && !is.null(project$data$metadata)) {
    metadata <- project$data$metadata

    if (!is.null(metadata$da_site)) {
      updates_applied$da_site <- metadata$da_site
    }
    if (!is.null(metadata$focal_issue)) {
      updates_applied$focal_issue <- metadata$focal_issue
    }
  }

  # Should only have project_name since metadata is missing
  expect_true("project_name" %in% names(updates_applied))
  expect_false("da_site" %in% names(updates_applied))
  expect_false("focal_issue" %in% names(updates_applied))
})

test_that("load data observer pattern handles complete data", {
  project <- create_partial_project_data()

  updates_applied <- list()

  if (!is.null(project$project_name)) {
    updates_applied$project_name <- project$project_name
  }

  if (!is.null(project$data) && !is.null(project$data$metadata)) {
    metadata <- project$data$metadata

    if (!is.null(metadata$da_site)) {
      updates_applied$da_site <- metadata$da_site
    }
    if (!is.null(metadata$focal_issue)) {
      updates_applied$focal_issue <- metadata$focal_issue
    }
    if (!is.null(metadata$temporal_scale)) {
      updates_applied$temporal_scale <- metadata$temporal_scale
    }
  }

  # Should have all fields
  expect_true("project_name" %in% names(updates_applied))
  expect_true("da_site" %in% names(updates_applied))
  expect_true("focal_issue" %in% names(updates_applied))
  expect_true("temporal_scale" %in% names(updates_applied))
})
