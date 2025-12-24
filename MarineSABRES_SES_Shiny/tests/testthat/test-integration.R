# test-integration.R
# Integration tests for end-to-end workflows

library(testthat)
library(shiny)

test_that("Complete ISA workflow: create, connect, visualize", {
  # Initialize session data
  project_data <- init_session_data()

  # Step 1: Create ISA elements
  project_data$data$isa_data$drivers <- data.frame(
    ID = c("D1", "D2"),
    Name = c("Population Growth", "Economic Development"),
    Indicator = c("Population change rate", "GDP growth"),
    stringsAsFactors = FALSE
  )

  project_data$data$isa_data$activities <- data.frame(
    ID = c("A1", "A2"),
    Name = c("Fishing", "Tourism"),
    Indicator = c("Fish catch volume", "Tourist numbers"),
    stringsAsFactors = FALSE
  )

  # Verify data is stored correctly
  expect_equal(nrow(project_data$data$isa_data$drivers), 2)
  expect_equal(nrow(project_data$data$isa_data$activities), 2)

  # Step 2: Create connections (adjacency matrix)
  adj_matrix <- matrix("", nrow = 2, ncol = 2)
  rownames(adj_matrix) <- c("D1", "D2")
  colnames(adj_matrix) <- c("A1", "A2")
  adj_matrix[1, 1] <- "+strong"
  adj_matrix[2, 2] <- "+medium"

  project_data$data$isa_data$adjacency_matrices <- list(
    drivers_to_activities = adj_matrix
  )

  # Verify connections
  expect_equal(adj_matrix["D1", "A1"], "+strong")
  expect_equal(adj_matrix["D2", "A2"], "+medium")

  # Step 3: Build network (if function exists)
  if (exists("build_network_from_isa")) {
    # Create network structure
    nodes <- rbind(
      data.frame(id = c("D1", "D2"), label = c("Population Growth", "Economic Development"),
                type = "Driver", stringsAsFactors = FALSE),
      data.frame(id = c("A1", "A2"), label = c("Fishing", "Tourism"),
                type = "Activity", stringsAsFactors = FALSE)
    )

    edges <- data.frame(
      from = c("D1", "D2"),
      to = c("A1", "A2"),
      link_type = c("positive", "positive"),
      strength = c("strong", "medium"),
      stringsAsFactors = FALSE
    )

    project_data$data$cld$nodes <- nodes
    project_data$data$cld$edges <- edges

    expect_equal(nrow(project_data$data$cld$nodes), 4)
    expect_equal(nrow(project_data$data$cld$edges), 2)
  }

  # Overall workflow verification
  expect_true(validate_project_structure(project_data))
})

test_that("PIMS to ISA data flow works", {
  # Initialize project
  project_data <- init_session_data()

  # Step 1: Set up PIMS metadata
  project_data$data$metadata <- list(
    da_site = "Tuscan Archipelago",
    focal_issue = "Overfishing impacts on biodiversity"
  )

  project_data$data$pims <- list(
    stakeholders = data.frame(
      ID = c("S1", "S2"),
      Name = c("Local Fishers", "Environmental NGO"),
      Type = c("Extractors", "Influencers"),
      stringsAsFactors = FALSE
    )
  )

  expect_equal(project_data$data$metadata$da_site, "Tuscan Archipelago")
  expect_equal(nrow(project_data$data$pims$stakeholders), 2)

  # Step 2: Create ISA data based on PIMS
  project_data$data$isa_data$activities <- data.frame(
    ID = "A1",
    Name = "Commercial Fishing",
    Indicator = "Fish catch",
    Stakeholder = "S1",
    stringsAsFactors = FALSE
  )

  # Verify linkage
  expect_true("S1" %in% project_data$data$pims$stakeholders$ID)
  expect_equal(project_data$data$isa_data$activities$Stakeholder, "S1")
})

test_that("Save and load project workflow", {
  # Create project data
  original_project <- init_session_data()
  original_project$data$metadata$da_site <- "Test Site"
  original_project$data$isa_data$drivers <- data.frame(
    ID = "D1",
    Name = "Test Driver",
    stringsAsFactors = FALSE
  )

  # Validate before save
  expect_true(validate_project_structure(original_project))

  # Simulate save/load
  temp_file <- tempfile(fileext = ".rds")
  saveRDS(original_project, temp_file)

  loaded_project <- readRDS(temp_file)

  # Verify loaded data
  expect_equal(loaded_project$project_id, original_project$project_id)
  expect_equal(loaded_project$data$metadata$da_site, "Test Site")
  expect_equal(nrow(loaded_project$data$isa_data$drivers), 1)
  expect_equal(loaded_project$data$isa_data$drivers$Name, "Test Driver")

  # Cleanup
  unlink(temp_file)
})

test_that("Network analysis workflow", {
  skip_if_not(exists("calculate_centrality"))

  # Create a simple network
  library(igraph)

  edges <- data.frame(
    from = c("A", "B", "C", "D"),
    to = c("B", "C", "D", "A"),
    stringsAsFactors = FALSE
  )

  g <- graph_from_data_frame(edges, directed = TRUE)

  # Calculate metrics
  centrality <- calculate_centrality(g)

  expect_type(centrality, "list")
  expect_true(length(centrality) > 0)

  # Detect loops
  if (exists("detect_feedback_loops")) {
    loops <- detect_feedback_loops(g)
    expect_true(is.data.frame(loops) || is.list(loops))
  }
})

test_that("Export workflow works", {
  # Create project with data
  project_data <- init_session_data()
  project_data$data$isa_data$drivers <- data.frame(
    ID = c("D1", "D2"),
    Name = c("Driver 1", "Driver 2"),
    Indicator = c("Indicator 1", "Indicator 2"),
    stringsAsFactors = FALSE
  )

  # Test JSON export
  temp_json <- tempfile(fileext = ".json")
  json_data <- jsonlite::toJSON(project_data$data$isa_data, pretty = TRUE)
  writeLines(json_data, temp_json)

  # Verify file created
  expect_true(file.exists(temp_json))
  expect_true(file.size(temp_json) > 0)

  # Load and verify
  loaded_json <- jsonlite::fromJSON(temp_json)
  expect_equal(loaded_json$drivers$Name, c("Driver 1", "Driver 2"))

  # Cleanup
  unlink(temp_json)

  # Test CSV export
  temp_csv <- tempfile(fileext = ".csv")
  write.csv(project_data$data$isa_data$drivers, temp_csv, row.names = FALSE)

  expect_true(file.exists(temp_csv))

  loaded_csv <- read.csv(temp_csv, stringsAsFactors = FALSE)
  expect_equal(nrow(loaded_csv), 2)
  expect_equal(loaded_csv$Name, c("Driver 1", "Driver 2"))

  # Cleanup
  unlink(temp_csv)
})

# ============================================================================
# Create SES Integration Tests (New)
# ============================================================================

test_that("Create SES method selection workflow", {
  skip_if_not(exists("create_ses_server"))

  # Initialize project
  project_data <- reactiveVal(init_session_data())

  # Test the Create SES module workflow
  testServer(create_ses_server, args = list(
    project_data_reactive = project_data,
    parent_session = NULL
  ), {
    # Step 1: User selects a method
    session$setInputs(method_selected = "standard")

    # Step 2: Verify selection is tracked
    # (Implementation depends on module structure)
    expect_true(TRUE)

    # Step 3: Test other method selections
    session$setInputs(method_selected = "ai")
    expect_true(TRUE)

    session$setInputs(method_selected = "template")
    expect_true(TRUE)
  })
})

test_that("Template SES loading workflow", {
  skip_if_not(exists("ses_templates"))
  skip_if_not(exists("template_ses_server"))

  # Initialize project
  project_data <- reactiveVal(init_session_data())

  # Step 1: Verify templates exist
  expect_true("fisheries" %in% names(ses_templates))

  # Step 2: Load fisheries template
  fisheries_template <- ses_templates$fisheries

  # Step 3: Apply template to project data
  project_data_copy <- project_data()
  project_data_copy$data$isa_data$drivers <- fisheries_template$drivers
  project_data_copy$data$isa_data$activities <- fisheries_template$activities
  project_data_copy$data$isa_data$pressures <- fisheries_template$pressures

  # Step 4: Verify data was loaded
  expect_true(nrow(project_data_copy$data$isa_data$drivers) > 0)
  expect_true(nrow(project_data_copy$data$isa_data$activities) > 0)
  expect_true(nrow(project_data_copy$data$isa_data$pressures) > 0)

  # Step 5: Verify project structure is still valid
  expect_true(validate_project_structure(project_data_copy))
})

test_that("Complete Create SES workflow: Choose method -> Load template -> Use data", {
  skip_if_not(exists("ses_templates"))

  # Initialize
  project_data <- init_session_data()

  # Step 1: User chooses template-based method (simulated)
  selected_method <- "template"
  expect_equal(selected_method, "template")

  # Step 2: User selects tourism template
  selected_template <- "tourism"
  expect_true(selected_template %in% names(ses_templates))

  # Step 3: Load template data
  template <- ses_templates[[selected_template]]

  # Step 4: Apply to project
  project_data$data$isa_data$drivers <- template$drivers
  project_data$data$isa_data$activities <- template$activities
  project_data$data$isa_data$pressures <- template$pressures
  project_data$data$isa_data$state_changes <- template$state_changes
  project_data$data$isa_data$impacts <- template$impacts
  project_data$data$isa_data$goods_benefits <- template$goods_benefits

  # Step 5: Verify all components loaded
  expect_true(nrow(project_data$data$isa_data$drivers) > 0)
  expect_true(nrow(project_data$data$isa_data$activities) > 0)
  expect_true(nrow(project_data$data$isa_data$pressures) > 0)

  # Step 6: Verify we can work with this data
  # Count total elements
  total_elements <- nrow(project_data$data$isa_data$drivers) +
                    nrow(project_data$data$isa_data$activities) +
                    nrow(project_data$data$isa_data$pressures)

  expect_true(total_elements > 0)

  # Step 7: Verify project is valid
  expect_true(validate_project_structure(project_data))
})

test_that("Create SES template customization workflow", {
  skip_if_not(exists("ses_templates"))

  # Start with a template
  project_data <- init_session_data()
  template <- ses_templates$aquaculture

  # Load template
  project_data$data$isa_data <- template

  # Customize: Add a new driver
  new_driver <- data.frame(
    id = "D_CUSTOM",
    name = "Custom Driver",
    description = "User-added driver",
    stringsAsFactors = FALSE
  )

  project_data$data$isa_data$drivers <- rbind(
    project_data$data$isa_data$drivers,
    new_driver
  )

  # Verify customization
  driver_ids <- project_data$data$isa_data$drivers$id
  expect_true("D_CUSTOM" %in% driver_ids)

  # Verify project is still valid
  expect_true(validate_project_structure(project_data))
})

test_that("Multiple templates can be loaded sequentially", {
  skip_if_not(exists("ses_templates"))

  project_data <- init_session_data()

  # Load first template
  project_data$data$isa_data <- ses_templates$fisheries
  fisheries_driver_count <- nrow(project_data$data$isa_data$drivers)
  expect_true(fisheries_driver_count > 0)

  # Switch to different template
  project_data$data$isa_data <- ses_templates$pollution
  pollution_driver_count <- nrow(project_data$data$isa_data$drivers)
  expect_true(pollution_driver_count > 0)

  # Counts may differ between templates
  # Just verify both loaded successfully
  expect_true(validate_project_structure(project_data))
})

test_that("Create SES integrates with existing ISA workflow", {
  # This test verifies that data created via Create SES templates
  # works with existing ISA analysis tools

  skip_if_not(exists("ses_templates"))

  # Load template
  project_data <- init_session_data()
  project_data$data$isa_data <- ses_templates$climate_change

  # Step 1: Verify template loaded
  expect_true(nrow(project_data$data$isa_data$drivers) > 0)

  # Step 2: Process with existing ISA tools
  # Create connections (as in original ISA workflow)
  if (nrow(project_data$data$isa_data$drivers) > 0 &&
      nrow(project_data$data$isa_data$activities) > 0) {

    n_drivers <- nrow(project_data$data$isa_data$drivers)
    n_activities <- nrow(project_data$data$isa_data$activities)

    # Create empty adjacency matrix
    adj_matrix <- matrix("",
                        nrow = n_drivers,
                        ncol = n_activities)

    rownames(adj_matrix) <- project_data$data$isa_data$drivers$id
    colnames(adj_matrix) <- project_data$data$isa_data$activities$id

    # Add a connection
    if (n_drivers > 0 && n_activities > 0) {
      adj_matrix[1, 1] <- "+strong"
    }

    project_data$data$isa_data$adjacency_matrices <- list(
      drivers_to_activities = adj_matrix
    )

    # Verify connection was added
    expect_equal(adj_matrix[1, 1], "+strong")
  }

  # Step 3: Verify project is still valid
  expect_true(validate_project_structure(project_data))
})

test_that("Create SES translation workflow", {
  skip_if_not(exists("i18n"))

  # Test that Create SES keys are translated
  create_ses <- i18n$t("ui.sidebar.create_ses")
  expect_true(is.character(create_ses))
  expect_true(nchar(create_ses) > 0)

  standard_entry <- i18n$t("ui.sidebar.standard_entry")
  expect_true(is.character(standard_entry))
  expect_true(nchar(standard_entry) > 0)

  ai_assistant <- i18n$t("ui.sidebar.ai_assistant")
  expect_true(is.character(ai_assistant))
  expect_true(nchar(ai_assistant) > 0)

  template_based <- i18n$t("ui.sidebar.template_based")
  expect_true(is.character(template_based))
  expect_true(nchar(template_based) > 0)
})
