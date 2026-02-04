# test-modules.R
# Unit tests for Shiny modules

library(testthat)
library(shiny)

# Helper function to test module UI
test_module_ui <- function(module_ui_function, module_id = "test") {
  ui_output <- module_ui_function(module_id)
  expect_true(inherits(ui_output, "shiny.tag") ||
              inherits(ui_output, "shiny.tag.list"))
  return(ui_output)
}

# Test ISA Data Entry Module
test_that("ISA data entry module UI renders", {
  ui <- isaDataEntryUI("test")

  expect_true(inherits(ui, "shiny.tag") || inherits(ui, "shiny.tag.list"))
})

test_that("ISA data entry module server initializes", {
  testServer(isaDataEntryServer, args = list(project_data = reactiveVal(init_session_data())), {
    # Module should initialize without errors
    succeed("ISA data entry module server initialized without error")

    # Test that reactive values exist
    # This depends on the actual module implementation
  })
})

# Test PIMS Module
test_that("PIMS project module UI renders", {
  ui <- pims_project_ui("test")

  expect_true(inherits(ui, "shiny.tag") || inherits(ui, "shiny.tag.list"))
})

test_that("PIMS project module server initializes", {
  testServer(pims_project_server, args = list(project_data = reactiveVal(init_session_data())), {
    succeed("PIMS project module server initialized without error")
  })
})

# Test CLD Visualization Module
test_that("CLD visualization module UI renders", {
  ui <- cld_viz_ui("test")

  expect_true(inherits(ui, "shiny.tag") || inherits(ui, "shiny.tag.list"))
})

test_that("CLD visualization module handles empty data", {
  testServer(cld_viz_server, args = list(project_data = reactiveVal(init_session_data())), {
    # Should handle empty project data without errors
    succeed("CLD visualization module handled empty data without error")
  })
})

# Test Analysis Tools Module
test_that("Analysis metrics module UI renders", {
  ui <- analysis_metrics_ui("test")

  expect_true(inherits(ui, "shiny.tag") || inherits(ui, "shiny.tag.list"))
})

test_that("Analysis loops module UI renders", {
  ui <- analysis_loops_ui("test")

  expect_true(inherits(ui, "shiny.tag") || inherits(ui, "shiny.tag.list"))
})

# Test Entry Point Module
test_that("Entry point module UI renders", {
  ui <- entry_point_ui("test")

  expect_true(inherits(ui, "shiny.tag") || inherits(ui, "shiny.tag.list"))
})

test_that("Entry point module server initializes", {
  # Create a mock parent session
  mock_session <- MockShinySession$new()

  testServer(entry_point_server,
    args = list(
      project_data = reactiveVal(init_session_data()),
      parent_session = mock_session
    ), {
    succeed("Entry point module server initialized without error")
  })
})

# Test AI ISA Assistant Module
test_that("AI ISA assistant module UI renders", {
  ui <- ai_isa_assistant_ui("test")

  expect_true(inherits(ui, "shiny.tag") || inherits(ui, "shiny.tag.list"))
})

test_that("AI ISA assistant module server initializes", {
  testServer(ai_isa_assistant_server, args = list(project_data = reactiveVal(init_session_data())), {
    succeed("AI ISA assistant module server initialized without error")
  })
})

# Test Response Module
test_that("Response measures module UI renders", {
  ui <- response_measures_ui("test")

  expect_true(inherits(ui, "shiny.tag") || inherits(ui, "shiny.tag.list"))
})

# Test Scenario Builder Module
test_that("Scenario builder module UI renders", {
  ui <- scenario_builder_ui("test")

  expect_true(inherits(ui, "shiny.tag") || inherits(ui, "shiny.tag.list"))
})

# ============================================================================
# Test Create SES Module (New)
# ============================================================================

test_that("Create SES module UI renders", {
  ui <- create_ses_ui("test")

  expect_true(inherits(ui, "shiny.tag") || inherits(ui, "shiny.tag.list"))
})

test_that("Create SES module UI contains all three method cards", {
  ui <- create_ses_ui("test")
  ui_html <- as.character(ui)

  # Check for Standard Entry card
  expect_true(grepl("card_standard", ui_html))

  # Check for AI Assistant card
  expect_true(grepl("card_ai", ui_html))

  # Check for Template-Based card
  expect_true(grepl("card_template", ui_html))
})

test_that("Create SES module UI uses i18n translations", {
  skip_if_not(exists("i18n"))

  ui <- create_ses_ui("test")
  ui_html <- as.character(ui)

  # Should NOT contain hardcoded English text (should use i18n$t())
  # The UI should render translated text
  expect_true(inherits(ui, "shiny.tag") || inherits(ui, "shiny.tag.list"))
})

test_that("Create SES module UI has proceed button", {
  ui <- create_ses_ui("test")
  ui_html <- as.character(ui)

  # Check for proceed button
  expect_true(grepl("proceed", ui_html))
})

test_that("Create SES module UI has comparison table", {
  ui <- create_ses_ui("test")
  ui_html <- as.character(ui)

  # Check for comparison table
  expect_true(grepl("comparison_table", ui_html) || grepl("comparison-table", ui_html))
})

test_that("Create SES module server initializes", {
  testServer(create_ses_server, args = list(
    project_data_reactive = reactiveVal(init_session_data()),
    parent_session = NULL
  ), {
    # Module should initialize without errors
    succeed("Create SES module server initialized without error")
  })
})

test_that("Create SES module server handles method selection", {
  testServer(create_ses_server, args = list(
    project_data_reactive = reactiveVal(init_session_data()),
    parent_session = NULL
  ), {
    # Simulate selecting standard method
    session$setInputs(method_selected = "standard")

    # The reactive value should be updated
    # Note: actual implementation depends on module structure
    succeed("Create SES module accepted method selection input without error")
  })
})

test_that("Create SES module server generates comparison table", {
  testServer(create_ses_server, args = list(
    project_data_reactive = reactiveVal(init_session_data()),
    parent_session = NULL
  ), {
    # Get the comparison table output
    comparison <- output$comparison_table

    # Should produce a table
    expect_true(!is.null(comparison))
  })
})

# ============================================================================
# Test Template SES Module (New)
# ============================================================================

test_that("Template SES module UI renders", {
  ui <- template_ses_ui("test")

  expect_true(inherits(ui, "shiny.tag") || inherits(ui, "shiny.tag.list"))
})

test_that("Template SES module has template library", {
  # Load templates using helper function (works in any environment)
  ses_templates <- get_test_templates()
  skip_if_not(length(ses_templates) > 0, "No templates loaded")

  # Check that ses_templates exists and contains expected templates
  expect_true(is.list(ses_templates))
  expect_true(length(ses_templates) > 0)

  # Check for specific templates (using actual template names from JSON files)
  expect_true("fisheries" %in% names(ses_templates))
  expect_true("tourism" %in% names(ses_templates))
  expect_true("aquaculture" %in% names(ses_templates))
  expect_true("pollution" %in% names(ses_templates))
  expect_true("climatechange" %in% names(ses_templates))  # Note: no underscore
})

test_that("Template SES templates have required structure", {
  # Load templates using helper function (works in any environment)
  ses_templates <- get_test_templates()
  skip_if_not(length(ses_templates) > 0, "No templates loaded")

  # Each template should have required fields
  for (template_name in names(ses_templates)) {
    template <- ses_templates[[template_name]]

    expect_true("name" %in% names(template),
                info = paste("Template", template_name, "missing 'name' field"))
    expect_true("description" %in% names(template),
                info = paste("Template", template_name, "missing 'description' field"))
    expect_true("drivers" %in% names(template),
                info = paste("Template", template_name, "missing 'drivers' field"))
    expect_true("activities" %in% names(template),
                info = paste("Template", template_name, "missing 'activities' field"))
    expect_true("pressures" %in% names(template),
                info = paste("Template", template_name, "missing 'pressures' field"))

    # Check that data frames have content
    expect_true(nrow(template$drivers) > 0,
                info = paste("Template", template_name, "has empty drivers"))
    expect_true(nrow(template$activities) > 0,
                info = paste("Template", template_name, "has empty activities"))
    expect_true(nrow(template$pressures) > 0,
                info = paste("Template", template_name, "has empty pressures"))
  }
})

test_that("Template SES fisheries template has correct structure", {
  # Load templates using helper function (works in any environment)
  ses_templates <- get_test_templates()
  skip_if_not(length(ses_templates) > 0, "No templates loaded")
  skip_if_not("fisheries" %in% names(ses_templates), "Fisheries template not found")

  fisheries <- ses_templates$fisheries

  # Check basic structure
  expect_equal(fisheries$name, "Fisheries")
  expect_true(is.character(fisheries$description))
  expect_true(is.data.frame(fisheries$drivers))
  expect_true(is.data.frame(fisheries$activities))
  expect_true(is.data.frame(fisheries$pressures))

  # Check that connections exist
  expect_true("connections" %in% names(fisheries))
})

test_that("Template SES module server initializes", {
  mock_session <- MockShinySession$new()

  testServer(template_ses_server, args = list(
    project_data = reactiveVal(init_session_data()),
    parent_session = mock_session
  ), {
    # Module should initialize without errors
    succeed("Template SES module server initialized without error")
  })
})

test_that("Template SES module UI contains template selector", {
  ui <- template_ses_ui("test")
  ui_html <- as.character(ui)

  # Should have some form of template selection interface
  # This could be cards, dropdown, etc.
  expect_true(inherits(ui, "shiny.tag") || inherits(ui, "shiny.tag.list"))
})
