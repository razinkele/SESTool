# test-module-integration.R
# ============================================================================
# Module Integration Tests
#
# Tests cross-module data flow and interaction patterns.
# Verifies that data flows correctly between modules:
#   - ISA entry → CLD generation
#   - Project metadata → Analysis modules
#   - Template loading → ISA population
# ============================================================================

# ============================================================================
# Test Setup
# ============================================================================

context("Module Integration: Data Flow")

test_that("setup: data accessor functions exist", {
  expect_true(exists("get_isa_data", mode = "function"))
  expect_true(exists("get_cld_data", mode = "function"))
  expect_true(exists("get_adjacency_matrix", mode = "function"))
  expect_true(exists("get_element_by_id", mode = "function"))
  expect_true(exists("get_project_summary", mode = "function"))
})

# ============================================================================
# ISA Data to CLD Conversion Tests
# ============================================================================

context("Module Integration: ISA to CLD")

test_that("ISA data generates valid CLD nodes", {
  # Create mock ISA data structure
  isa_data <- list(
    drivers = data.frame(
      id = c("d1", "d2"),
      name = c("Climate Change", "Economic Growth"),
      description = c("Climate change effects", "Economic pressures")
      
    ),
    activities = data.frame(
      id = c("a1", "a2"),
      name = c("Fishing", "Tourism"),
      description = c("Commercial fishing", "Coastal tourism")
      
    ),
    pressures = data.frame(
      id = "p1",
      name = "Overfishing",
      description = "Fish stock depletion"
      
    ),
    marine_processes = data.frame(
      id = character(0), name = character(0), description = character(0)
      
    ),
    ecosystem_services = data.frame(
      id = character(0), name = character(0), description = character(0)
      
    ),
    goods_benefits = data.frame(
      id = character(0), name = character(0), description = character(0)
      
    ),
    responses = data.frame(
      id = character(0), name = character(0), description = character(0)
      
    ),
    adjacency_matrices = list(
      d_a = matrix(c(0, 1, 0, 0), nrow = 2, ncol = 2,
                   dimnames = list(c("d1", "d2"), c("a1", "a2"))),
      a_p = matrix(c(1, 0), nrow = 2, ncol = 1,
                   dimnames = list(c("a1", "a2"), c("p1")))
    )
  )

  # Test create_nodes_df function
  skip_if_not(exists("create_nodes_df", mode = "function"),
              "create_nodes_df function not available")

  nodes <- create_nodes_df(isa_data)

  # Verify nodes structure

  expect_true(is.data.frame(nodes))
  expect_true(nrow(nodes) > 0)
  expect_true("id" %in% names(nodes))
  expect_true("label" %in% names(nodes))

  # Verify all elements are included (using PREFIX_NUMBER format)
  # The function generates IDs like D_1, A_1, P_1
  expect_true("D_1" %in% nodes$id || any(grepl("^D_", nodes$id)))
  expect_true("A_1" %in% nodes$id || any(grepl("^A_", nodes$id)))
  expect_true("P_1" %in% nodes$id || any(grepl("^P_", nodes$id)))
})

test_that("ISA adjacency matrices generate valid CLD edges", {
  # Create mock ISA data
  isa_data <- list(
    drivers = data.frame(id = "d1", name = "Driver1"),
    activities = data.frame(id = "a1", name = "Activity1"),
    pressures = data.frame(id = "p1", name = "Pressure1"),
    marine_processes = data.frame(id = character(0), name = character(0)),
    ecosystem_services = data.frame(id = character(0), name = character(0)),
    goods_benefits = data.frame(id = character(0), name = character(0)),
    responses = data.frame(id = character(0), name = character(0)),
    adjacency_matrices = list(
      d_a = matrix(1, nrow = 1, ncol = 1, dimnames = list("d1", "a1")),
      a_p = matrix(1, nrow = 1, ncol = 1, dimnames = list("a1", "p1"))
    )
  )

  skip_if_not(exists("create_edges_df", mode = "function"),
              "create_edges_df function not available")

  edges <- create_edges_df(isa_data, isa_data$adjacency_matrices)

  # Verify edges structure
  expect_true(is.data.frame(edges))
  expect_true("from" %in% names(edges))
  expect_true("to" %in% names(edges))

  # Verify edges are created
  expect_true(nrow(edges) >= 2)

  # Verify edge connections (using PREFIX_NUMBER format)
  # The function generates edge IDs like D_1, A_1, P_1
  d1_to_a1 <- any(edges$from == "D_1" & edges$to == "A_1")
  a1_to_p1 <- any(edges$from == "A_1" & edges$to == "P_1")

  expect_true(d1_to_a1)
  expect_true(a1_to_p1)
})

# ============================================================================
# Data Accessor Function Tests
# ============================================================================

context("Module Integration: Data Accessors")

test_that("get_isa_data extracts ISA data from project structure", {
  # Create mock project data structure
  project_data <- list(
    data = list(
      isa_data = list(
        drivers = data.frame(id = "d1", name = "Test Driver"),
        activities = data.frame(id = "a1", name = "Test Activity")
      )
    ),
    metadata = list(project_name = "Test Project")
  )

  result <- get_isa_data(project_data)

  expect_true(is.list(result))
  expect_true("drivers" %in% names(result))
  expect_true("activities" %in% names(result))
})

test_that("get_isa_elements returns correct element type", {
  project_data <- list(
    data = list(
      isa_data = list(
        drivers = data.frame(
          id = c("d1", "d2"),
          name = c("Driver 1", "Driver 2")
          
        ),
        activities = data.frame(
          id = "a1",
          name = "Activity 1"
          
        )
      )
    )
  )

  drivers <- get_isa_elements(project_data, "drivers")
  activities <- get_isa_elements(project_data, "activities")

  expect_equal(nrow(drivers), 2)
  expect_equal(nrow(activities), 1)
})

test_that("get_element_by_id finds correct element", {
  project_data <- list(
    data = list(
      isa_data = list(
        drivers = data.frame(
          id = c("d1", "d2"),
          name = c("Driver 1", "Driver 2")
          
        ),
        activities = data.frame(
          id = "a1",
          name = "Activity 1"
          
        ),
        pressures = data.frame(id = character(0), name = character(0)),
        marine_processes = data.frame(id = character(0), name = character(0)),
        ecosystem_services = data.frame(id = character(0), name = character(0)),
        goods_benefits = data.frame(id = character(0), name = character(0)),
        responses = data.frame(id = character(0), name = character(0))
      )
    )
  )

  element <- get_element_by_id(project_data, "d2")

  expect_true(!is.null(element))
  expect_equal(nrow(element), 1)
  expect_equal(element$id, "d2")
  expect_equal(element$name, "Driver 2")
})

test_that("get_adjacency_matrix returns correct matrix", {
  test_matrix <- matrix(c(0, 1, 1, 0), nrow = 2,
                        dimnames = list(c("d1", "d2"), c("a1", "a2")))

  project_data <- list(
    data = list(
      isa_data = list(
        adjacency_matrices = list(
          d_a = test_matrix
        )
      )
    )
  )

  result <- get_adjacency_matrix(project_data, "d_a")

  expect_true(is.matrix(result))
  expect_equal(dim(result), c(2, 2))
  expect_equal(rownames(result), c("d1", "d2"))
})

test_that("get_project_summary returns complete statistics", {
  project_data <- list(
    data = list(
      isa_data = list(
        drivers = data.frame(id = c("d1", "d2"), name = c("D1", "D2")),
        activities = data.frame(id = "a1", name = "A1"),
        pressures = data.frame(id = character(0), name = character(0)),
        marine_processes = data.frame(id = character(0), name = character(0)),
        ecosystem_services = data.frame(id = character(0), name = character(0)),
        goods_benefits = data.frame(id = character(0), name = character(0)),
        responses = data.frame(id = character(0), name = character(0)),
        adjacency_matrices = list(
          d_a = matrix(1, nrow = 2, ncol = 1, dimnames = list(c("d1", "d2"), "a1"))
        )
      ),
      cld = list(
        nodes = data.frame(id = c("d1", "d2", "a1"), label = c("D1", "D2", "A1")),
        edges = data.frame(from = c("d1", "d2"), to = c("a1", "a1"))
      )
    ),
    metadata = list(project_name = "Integration Test"),
    last_modified = Sys.time()
  )

  summary <- get_project_summary(project_data)

  expect_true(is.list(summary))
  expect_equal(summary$project_name, "Integration Test")
  expect_equal(summary$total_elements, 3)  # 2 drivers + 1 activity
  expect_equal(summary$cld_nodes, 3)
  expect_equal(summary$cld_edges, 2)
})

# ============================================================================
# Template Loading Integration Tests
# ============================================================================

context("Module Integration: Template Loading")

test_that("SES templates can be loaded and parsed", {
  skip_if_not(exists("load_ses_models", mode = "function"),
              "load_ses_models function not available")

  templates <- load_ses_models()

  expect_true(is.list(templates))
  expect_true(length(templates) > 0)
})

test_that("loaded templates have required ISA structure", {
  skip_if_not(exists("load_ses_models", mode = "function"),
              "load_ses_models function not available")

  templates <- load_ses_models()

  if (length(templates) > 0) {
    template <- templates[[1]]

    # Check for ISA data structure
    expect_true("isa_data" %in% names(template) || "data" %in% names(template))
  }
})

# ============================================================================
# Cross-Reference Validation Tests
# ============================================================================

context("Module Integration: Cross-Reference Validation")

test_that("validate_cross_references detects orphaned matrix references", {
  skip_if_not(exists("validate_cross_references", mode = "function"),
              "validate_cross_references function not available")

  # Create ISA data with orphaned reference
  isa_data <- list(
    drivers = data.frame(id = "d1", name = "Valid Driver"),
    activities = data.frame(id = "a1", name = "Valid Activity"),
    pressures = data.frame(id = character(0), name = character(0)),
    marine_processes = data.frame(id = character(0), name = character(0)),
    ecosystem_services = data.frame(id = character(0), name = character(0)),
    goods_benefits = data.frame(id = character(0), name = character(0)),
    responses = data.frame(id = character(0), name = character(0)),
    adjacency_matrices = list(
      d_a = matrix(c(1, 0), nrow = 2, ncol = 1,
                   dimnames = list(c("d1", "ORPHAN_REF"), c("a1")))
    )
  )

  errors <- validate_cross_references(isa_data)

  expect_true(length(errors) > 0)
  expect_true(any(grepl("ORPHAN", errors)))
})

test_that("validate_cross_references passes with valid references", {
  skip_if_not(exists("validate_cross_references", mode = "function"),
              "validate_cross_references function not available")

  # Create valid ISA data
  isa_data <- list(
    drivers = data.frame(id = "d1", name = "Driver"),
    activities = data.frame(id = "a1", name = "Activity"),
    pressures = data.frame(id = character(0), name = character(0)),
    marine_processes = data.frame(id = character(0), name = character(0)),
    ecosystem_services = data.frame(id = character(0), name = character(0)),
    goods_benefits = data.frame(id = character(0), name = character(0)),
    responses = data.frame(id = character(0), name = character(0)),
    adjacency_matrices = list(
      d_a = matrix(1, nrow = 1, ncol = 1, dimnames = list("d1", "a1"))
    )
  )

  errors <- validate_cross_references(isa_data)

  expect_equal(length(errors), 0)
})

# ============================================================================
# Transaction Wrapper Tests
# ============================================================================

context("Module Integration: State Management")

test_that("with_project_transaction handles successful operations", {
  skip_if_not(exists("with_project_transaction", mode = "function"),
              "with_project_transaction function not available")

  # Create mock reactive value
  project_data <- shiny::reactiveVal(list(
    data = list(isa_data = list(drivers = data.frame(id = "d1", name = "Test"))),
    last_modified = Sys.time()
  ))

  # Perform transaction
  result <- shiny::isolate({
    with_project_transaction(project_data, operation = function(state) {
      state$data$test_flag <- TRUE
      state
    })
  })

  expect_true(result$success)
  expect_true(shiny::isolate(project_data()$data$test_flag))
})

test_that("with_project_transaction rolls back on error", {
  skip_if_not(exists("with_project_transaction", mode = "function"),
              "with_project_transaction function not available")

  # Create mock reactive value
  initial_state <- list(
    data = list(isa_data = list(drivers = data.frame(id = "d1", name = "Original"))),
    last_modified = Sys.time()
  )
  project_data <- shiny::reactiveVal(initial_state)

  # Perform failing transaction
  result <- shiny::isolate({
    with_project_transaction(project_data, operation = function(state) {
      stop("Intentional error for testing")
    }, silent = TRUE)
  })

  expect_false(result$success)
  expect_true(!is.null(result$error))

  # Verify state was not modified
  current_state <- shiny::isolate(project_data())
  expect_equal(current_state$data$isa_data$drivers$name, "Original")
})

# ============================================================================
# Event Bus Integration Tests
# ============================================================================

context("Module Integration: Event Bus")

test_that("event bus can be created and emit events", {
  skip_if_not(exists("create_event_bus", mode = "function"),
              "create_event_bus function not available")

  bus <- create_event_bus()

  expect_true(is.list(bus))
  expect_true("emit_isa_change" %in% names(bus))
  expect_true(is.function(bus$emit_isa_change))
})

# ============================================================================
# End-to-End Data Flow Tests
# ============================================================================

context("Module Integration: End-to-End Flow")

test_that("complete data flow: empty -> ISA -> CLD -> analysis ready", {
  # Skip if the function is not available
  skip_if_not(exists("create_empty_isa_structure_safe", mode = "function"),
              "create_empty_isa_structure_safe not available")

  # Step 1: Initialize empty project
  project_data <- list(
    data = list(
      isa_data = create_empty_isa_structure_safe(),
      cld = list(nodes = data.frame(), edges = data.frame()),
      analysis = list()
    ),
    metadata = list(project_name = "E2E Test"),
    last_modified = Sys.time()
  )

  # Verify empty state
  summary1 <- get_project_summary(project_data)
  expect_equal(summary1$total_elements, 0)

  # Step 2: Add elements (simulating ISA entry)
  project_data$data$isa_data$drivers <- rbind(
    project_data$data$isa_data$drivers,
    data.frame(id = "d1", name = "Test Driver", description = "Test"
               )
  )
  project_data$data$isa_data$activities <- rbind(
    project_data$data$isa_data$activities,
    data.frame(id = "a1", name = "Test Activity", description = "Test"
               )
  )

  # Step 3: Add connection (simulating matrix entry)
  project_data$data$isa_data$adjacency_matrices$d_a <- matrix(
    1, nrow = 1, ncol = 1, dimnames = list("d1", "a1")
  )

  # Verify populated state
  summary2 <- get_project_summary(project_data)
  expect_equal(summary2$total_elements, 2)
  expect_equal(summary2$total_connections, 1)

  # Step 4: Generate CLD (simulating CLD module)
  skip_if_not(exists("create_nodes_df", mode = "function"),
              "create_nodes_df not available")

  nodes <- create_nodes_df(project_data$data$isa_data)
  edges <- create_edges_df(project_data$data$isa_data,
                           project_data$data$isa_data$adjacency_matrices)

  project_data$data$cld <- list(nodes = nodes, edges = edges)

  # Verify CLD state
  summary3 <- get_project_summary(project_data)
  expect_true(summary3$cld_nodes >= 2)
  expect_true(summary3$cld_edges >= 1)

  # Step 5: Verify analysis readiness
  expect_true(has_valid_cld_data(project_data, min_nodes = 2, require_edges = TRUE))
})
