# Test Mocking Strategy - MarineSABRES SES Toolbox

## Overview

This document describes the mocking strategies used in the test suite to isolate components and ensure reliable, fast tests.

## Mock Categories

### 1. Shiny Session Mocks

```r
# Create mock Shiny session
create_mock_session <- function() {
  session <- new.env()
  session$ns <- NS("test")
  session$userData <- list(
    session_id = "test_session_123",
    session_temp_dir = tempdir()
  )
  session$input <- reactiveValues()
  session$output <- list()
  class(session) <- c("ShinySession", "R6")
  session
}
```

### 2. i18n Translator Mocks

```r
# Simple pass-through translator
create_mock_i18n <- function() {
  list(
    t = function(key) key,  # Return key as-is
    set_translation_language = function(lang) NULL,
    get_translation_language = function() "en"
  )
}

# Translator with actual translations
create_mock_i18n_with_translations <- function(translations) {
  list(
    t = function(key) translations[[key]] %||% key
  )
}
```

### 3. Project Data Mocks

```r
# Create minimal project data structure
create_mock_project_data <- function(with_elements = TRUE) {
  data <- list(
    project_id = "TEST_001",
    project_name = "Test Project",
    data = list(
      isa_data = if (with_elements) create_mock_isa_data() else NULL,
      cld = list(nodes = data.frame(), edges = data.frame())
    ),
    metadata = list(
      created = Sys.time(),
      modified = Sys.time()
    )
  )

  if (requireNamespace("shiny", quietly = TRUE)) {
    shiny::reactiveVal(data)
  } else {
    function() data
  }
}

# Create mock ISA data with sample elements
create_mock_isa_data <- function() {
  list(
    drivers = data.frame(
      ID = c("D001", "D002"),
      Label = c("Climate Change", "Economic Growth"),
      Type = rep("Drivers", 2),
      stringsAsFactors = FALSE
    ),
    activities = data.frame(
      ID = c("A001"),
      Label = c("Fishing"),
      Type = rep("Activities", 1),
      stringsAsFactors = FALSE
    ),
    pressures = data.frame(),
    marine_processes = data.frame(),
    ecosystem_services = data.frame(),
    goods_benefits = data.frame(),
    responses = data.frame(),
    adjacency_matrices = list()
  )
}
```

### 4. Event Bus Mocks

```r
# Create mock event bus
create_mock_event_bus <- function() {
  events_emitted <- list()

  list(
    emit_isa_change = function() {
      events_emitted <<- c(events_emitted, list(
        list(type = "isa_change", time = Sys.time())
      ))
    },
    on_isa_change = function() NULL,
    get_emitted_events = function() events_emitted,
    clear_events = function() { events_emitted <<- list() }
  )
}
```

### 5. ML Model Mocks

```r
# Create mock ML ensemble
create_mock_ensemble <- function(n_models = 3) {
  ensemble_env$models <- list()
  ensemble_env$loaded <- TRUE
  ensemble_env$n_models <- 0

  for (i in 1:n_models) {
    # Create minimal mock model
    mock_model <- list(
      forward = function(x, ...) {
        list(
          existence = torch_tensor(matrix(0.5, nrow = 1)),
          polarity = torch_tensor(matrix(0.5, nrow = 1)),
          strength = torch_tensor(matrix(c(0.33, 0.34, 0.33), nrow = 1)),
          confidence = torch_tensor(matrix(0.7, nrow = 1))
        )
      },
      eval = function() invisible(self)
    )
    ensemble_env$models[[i]] <- mock_model
  }

  ensemble_env$n_models <- n_models
  ensemble_env$metadata <- list(
    n_models = n_models,
    seeds = c(42, 123, 456)[1:n_models]
  )
}
```

## Testing Patterns

### Testing Module UI

```r
test_that("module UI renders correctly", {
  i18n <- create_mock_i18n()

  ui <- module_name_ui("test", i18n)

  expect_true(inherits(ui, "shiny.tag") || inherits(ui, "shiny.tag.list"))
  expect_true(length(ui) > 0)
})
```

### Testing Module Server (with shinytest2)

```r
test_that("module server handles input", {
  testServer(module_name_server, args = list(
    project_data = create_mock_project_data(),
    i18n = create_mock_i18n(),
    event_bus = create_mock_event_bus()
  ), {
    # Set inputs
    session$setInputs(element_type = "drivers")

    # Check outputs
    expect_true(!is.null(output$result))
  })
})
```

### Testing Without Shiny Context

```r
test_that("helper function works standalone", {
  # Use isolated functions that don't require Shiny
  result <- calculate_network_metrics(mock_nodes, mock_edges)

  expect_true(is.list(result))
  expect_true("degree" %in% names(result))
})
```

## Skip Patterns

```r
# Skip if dependency not available
test_that("ML prediction works", {
  skip_if_not_installed("torch")
  skip_if_not(torch::torch_is_installed())

  # Test code
})

# Skip if function not available (feature not loaded)
test_that("ensemble predictions work", {
  skip_if_not(exists("predict_connection_ensemble", mode = "function"),
              "Ensemble functions not available")

  # Test code
})

# Skip in CI environment
test_that("heavy computation test", {
  skip_on_ci()

  # Expensive test
})
```

## File Organization

```
tests/testthat/
├── helper-mocks.R           # Shared mock creation functions
├── helper-test-data.R       # Test data generators
├── setup.R                  # Test environment setup
├── test-*.R                 # Individual test files
└── fixtures/
    ├── sample_project.rds   # Sample project data
    └── mock_model.pt        # Mock ML model
```

## Best Practices

1. **Isolate tests** - Each test should be independent
2. **Use skip patterns** - Skip tests when dependencies unavailable
3. **Mock external services** - Don't rely on network/files
4. **Clean up after tests** - Use `on.exit()` for temp files
5. **Use fixtures** - Store complex test data in fixtures/
6. **Test behavior, not implementation** - Focus on outputs
