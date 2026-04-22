# tests/testthat/test-reactive-pipeline.R
# Tests for the reactive data pipeline system (P0 Critical)
#
# These tests verify:
# 1. Event bus creation and configuration (server/event_bus_setup.R)
# 2. ISA change signature generation (functions/reactive_pipeline.R)
# 3. Signature comparison (detect changes vs no-changes)
# 4. Debounce configuration
# 5. Event emission and observation via the unified event bus API
# 6. Skip CLD regen flag
# 7. Edge cases: empty data, NULL inputs, missing fields
#
# Architecture note: The event bus is created by server/event_bus_setup.R and
# provides the emit_*/on_* API. The reactive pipeline (functions/reactive_pipeline.R)
# wires ISA->CLD->Analysis propagation on top of this event bus.

library(testthat)

# Source the files under test (global.R doesn't auto-source server/ or
# functions/reactive_pipeline.R in all test environments). Follows the same
# absolute-path helper pattern as test-entry-point-module.R.
source_for_test(c(
  "server/event_bus_setup.R",
  "functions/reactive_pipeline.R"
))
# ============================================================================
# EVENT BUS CREATION TESTS
# ============================================================================

test_that("create_event_bus returns a list with all expected components", {
  skip_if_not(exists("create_event_bus", mode = "function"),
              "create_event_bus function not available")

  bus <- create_event_bus(session_id = "test_structure")

  expect_true(is.list(bus))

  # Check key components from the unified event bus API (server/event_bus_setup.R)
  expected_names <- c(
    "emit_isa_change", "on_isa_change",
    "emit_cld_update", "on_cld_update",
    "emit_analysis_request", "on_analysis_request",
    "skip_next_cld_regen", "get_skip_cld_regen",
    "get_event_count", "get_last_event", "get_session_id"
  )
  for (nm in expected_names) {
    expect_true(nm %in% names(bus),
                info = paste("Missing component:", nm))
  }
})

test_that("create_event_bus stores the provided session_id", {
  skip_if_not(exists("create_event_bus", mode = "function"),
              "create_event_bus function not available")

  bus <- create_event_bus(session_id = "my_session_123")
  expect_equal(bus$get_session_id(), "my_session_123")
})

test_that("create_event_bus defaults session_id to NULL when not provided", {
  skip_if_not(exists("create_event_bus", mode = "function"),
              "create_event_bus function not available")

  bus <- create_event_bus()
  # Session ID is NULL when not provided
  expect_null(bus$get_session_id())
})

test_that("create_event_bus reactive triggers start at 0", {
  skip_if_not(exists("create_event_bus", mode = "function"),
              "create_event_bus function not available")

  bus <- create_event_bus(session_id = "defaults_test")

  # Counters start at 0
  expect_equal(shiny::isolate(bus$on_isa_change()), 0)
  expect_equal(shiny::isolate(bus$on_cld_update()), 0)
  expect_equal(shiny::isolate(bus$on_analysis_request()), 0)

  # Skip flag starts as FALSE
  expect_false(shiny::isolate(bus$get_skip_cld_regen(consume = FALSE)))
})

test_that("create_event_bus emit functions are callable functions", {
  skip_if_not(exists("create_event_bus", mode = "function"),
              "create_event_bus function not available")

  bus <- create_event_bus(session_id = "callable_test")

  expect_true(is.function(bus$emit_isa_change))
  expect_true(is.function(bus$emit_cld_update))
  expect_true(is.function(bus$emit_analysis_request))
})

test_that("is_event_bus correctly identifies event bus objects", {
  skip_if_not(exists("create_event_bus", mode = "function"),
              "create_event_bus function not available")
  skip_if_not(exists("is_event_bus", mode = "function"),
              "is_event_bus function not available")

  bus <- create_event_bus(session_id = "type_check_test")
  expect_true(is_event_bus(bus))
  expect_false(is_event_bus(list()))
  expect_false(is_event_bus(NULL))
})

# ============================================================================
# EVENT EMISSION TESTS
# ============================================================================

test_that("emit_isa_change increments on_isa_change counter by 1", {
  skip_if_not(exists("create_event_bus", mode = "function"),
              "create_event_bus function not available")

  bus <- create_event_bus(session_id = "isa_emit_test")

  initial <- shiny::isolate(bus$on_isa_change())
  bus$emit_isa_change()
  expect_equal(shiny::isolate(bus$on_isa_change()), initial + 1)
})

test_that("emit_cld_update increments on_cld_update counter by 1", {
  skip_if_not(exists("create_event_bus", mode = "function"),
              "create_event_bus function not available")

  bus <- create_event_bus(session_id = "cld_emit_test")

  initial <- shiny::isolate(bus$on_cld_update())
  bus$emit_cld_update()
  expect_equal(shiny::isolate(bus$on_cld_update()), initial + 1)
})

test_that("emit_analysis_request increments on_analysis_request counter by 1", {
  skip_if_not(exists("create_event_bus", mode = "function"),
              "create_event_bus function not available")

  bus <- create_event_bus(session_id = "analysis_emit_test")

  initial <- shiny::isolate(bus$on_analysis_request())
  bus$emit_analysis_request()
  expect_equal(shiny::isolate(bus$on_analysis_request()), initial + 1)
})

test_that("multiple ISA emissions accumulate correctly", {
  skip_if_not(exists("create_event_bus", mode = "function"),
              "create_event_bus function not available")

  bus <- create_event_bus(session_id = "multi_isa_test")

  initial <- shiny::isolate(bus$on_isa_change())
  for (i in 1:5) {
    bus$emit_isa_change()
  }
  expect_equal(shiny::isolate(bus$on_isa_change()), initial + 5)
})

test_that("multiple CLD emissions accumulate correctly", {
  skip_if_not(exists("create_event_bus", mode = "function"),
              "create_event_bus function not available")

  bus <- create_event_bus(session_id = "multi_cld_test")

  initial <- shiny::isolate(bus$on_cld_update())
  for (i in 1:3) {
    bus$emit_cld_update()
  }
  expect_equal(shiny::isolate(bus$on_cld_update()), initial + 3)
})

test_that("emissions on different event types are independent", {
  skip_if_not(exists("create_event_bus", mode = "function"),
              "create_event_bus function not available")

  bus <- create_event_bus(session_id = "independence_test")

  bus$emit_isa_change()
  bus$emit_isa_change()
  bus$emit_cld_update()

  expect_equal(shiny::isolate(bus$on_isa_change()), 2)
  expect_equal(shiny::isolate(bus$on_cld_update()), 1)
  expect_equal(shiny::isolate(bus$on_analysis_request()), 0)
})

test_that("rapid emissions (100x) are all counted", {
  skip_if_not(exists("create_event_bus", mode = "function"),
              "create_event_bus function not available")

  bus <- create_event_bus(session_id = "rapid_test")

  for (i in 1:100) {
    bus$emit_isa_change()
  }

  expect_equal(shiny::isolate(bus$on_isa_change()), 100)
})

test_that("emit_isa_change accepts source parameter", {
  skip_if_not(exists("create_event_bus", mode = "function"),
              "create_event_bus function not available")

  bus <- create_event_bus(session_id = "source_test")

  bus$emit_isa_change("test_module")
  last <- shiny::isolate(bus$get_last_event())
  expect_equal(last$source, "test_module")
  expect_equal(last$type, "isa_change")
})

test_that("get_event_count tracks total events", {
  skip_if_not(exists("create_event_bus", mode = "function"),
              "create_event_bus function not available")

  bus <- create_event_bus(session_id = "count_test")

  expect_equal(shiny::isolate(bus$get_event_count()), 0)

  bus$emit_isa_change()
  bus$emit_cld_update()
  expect_equal(shiny::isolate(bus$get_event_count()), 2)
})

# ============================================================================
# SKIP FLAG TESTS
# ============================================================================

test_that("skip_next_cld_regen starts as FALSE", {
  skip_if_not(exists("create_event_bus", mode = "function"),
              "create_event_bus function not available")

  bus <- create_event_bus(session_id = "skip_init_test")
  expect_false(shiny::isolate(bus$get_skip_cld_regen(consume = FALSE)))
})

test_that("skip_next_cld_regen can be set to TRUE and read back", {
  skip_if_not(exists("create_event_bus", mode = "function"),
              "create_event_bus function not available")

  bus <- create_event_bus(session_id = "skip_toggle_test")

  bus$skip_next_cld_regen(TRUE)
  expect_true(shiny::isolate(bus$get_skip_cld_regen(consume = FALSE)))
})

test_that("get_skip_cld_regen with consume=TRUE resets the flag", {
  skip_if_not(exists("create_event_bus", mode = "function"),
              "create_event_bus function not available")

  bus <- create_event_bus(session_id = "skip_consume_test")

  bus$skip_next_cld_regen(TRUE)
  # First read with consume should return TRUE and reset
  val <- shiny::isolate(bus$get_skip_cld_regen(consume = TRUE))
  expect_true(val)
  # Second read should return FALSE (consumed)
  expect_false(shiny::isolate(bus$get_skip_cld_regen(consume = FALSE)))
})

test_that("skip_next_cld_regen can be set multiple times", {
  skip_if_not(exists("create_event_bus", mode = "function"),
              "create_event_bus function not available")

  bus <- create_event_bus(session_id = "skip_multi_test")

  bus$skip_next_cld_regen(TRUE)
  bus$skip_next_cld_regen(TRUE)
  expect_true(shiny::isolate(bus$get_skip_cld_regen(consume = FALSE)))

  bus$skip_next_cld_regen(FALSE)
  expect_false(shiny::isolate(bus$get_skip_cld_regen(consume = FALSE)))
})

# ============================================================================
# ISA SIGNATURE GENERATION TESTS
# ============================================================================

test_that("create_isa_signature returns NULL for NULL input", {
  skip_if_not(exists("create_isa_signature", mode = "function"),
              "create_isa_signature function not available")

  result <- create_isa_signature(NULL)
  expect_null(result)
})

test_that("create_isa_signature returns NULL for empty list", {
  skip_if_not(exists("create_isa_signature", mode = "function"),
              "create_isa_signature function not available")

  result <- create_isa_signature(list())
  expect_null(result)
})

test_that("create_isa_signature returns a character string for valid data", {
  skip_if_not(exists("create_isa_signature", mode = "function"),
              "create_isa_signature function not available")

  isa_data <- list(
    drivers = data.frame(id = "D1", name = "Test Driver"),
    activities = data.frame(id = "A1", name = "Test Activity")
  )

  sig <- create_isa_signature(isa_data)

  expect_true(is.character(sig))
  expect_equal(length(sig), 1)
  expect_true(nchar(sig) > 0)
})

test_that("create_isa_signature is deterministic for same data", {
  skip_if_not(exists("create_isa_signature", mode = "function"),
              "create_isa_signature function not available")

  isa_data <- list(
    drivers = data.frame(id = "D1", name = "Driver One"),
    activities = data.frame(id = "A1", name = "Activity One"),
    pressures = data.frame(id = "P1", name = "Pressure One")
  )

  sig1 <- create_isa_signature(isa_data)
  sig2 <- create_isa_signature(isa_data)

  expect_identical(sig1, sig2)
})

test_that("create_isa_signature produces different signatures for different data", {
  skip_if_not(exists("create_isa_signature", mode = "function"),
              "create_isa_signature function not available")

  isa_data1 <- list(
    drivers = data.frame(id = "D1", name = "Driver One")
  )

  isa_data2 <- list(
    drivers = data.frame(id = "D1", name = "Driver Two")
  )

  sig1 <- create_isa_signature(isa_data1)
  sig2 <- create_isa_signature(isa_data2)

  expect_false(identical(sig1, sig2))
})

test_that("create_isa_signature detects added elements", {
  skip_if_not(exists("create_isa_signature", mode = "function"),
              "create_isa_signature function not available")

  isa_data_before <- list(
    drivers = data.frame(id = "D1", name = "Driver")
  )

  isa_data_after <- list(
    drivers = data.frame(id = c("D1", "D2"), name = c("Driver", "New Driver")
                         )
  )

  sig_before <- create_isa_signature(isa_data_before)
  sig_after <- create_isa_signature(isa_data_after)

  expect_false(identical(sig_before, sig_after))
})

test_that("create_isa_signature detects removed elements", {
  skip_if_not(exists("create_isa_signature", mode = "function"),
              "create_isa_signature function not available")

  isa_data_before <- list(
    drivers = data.frame(id = c("D1", "D2"), name = c("A", "B")
                         )
  )

  isa_data_after <- list(
    drivers = data.frame(id = "D1", name = "A")
  )

  sig_before <- create_isa_signature(isa_data_before)
  sig_after <- create_isa_signature(isa_data_after)

  expect_false(identical(sig_before, sig_after))
})

test_that("create_isa_signature includes adjacency_matrices in hash", {
  skip_if_not(exists("create_isa_signature", mode = "function"),
              "create_isa_signature function not available")

  base_data <- list(
    drivers = data.frame(id = "D1", name = "Driver"),
    activities = data.frame(id = "A1", name = "Activity")
  )

  isa_no_adj <- base_data
  isa_no_adj$adjacency_matrices <- NULL

  isa_with_adj <- base_data
  isa_with_adj$adjacency_matrices <- list(
    D_A = matrix(1, nrow = 1, ncol = 1, dimnames = list("D1", "A1"))
  )

  sig_no_adj <- create_isa_signature(isa_no_adj)
  sig_with_adj <- create_isa_signature(isa_with_adj)

  expect_false(identical(sig_no_adj, sig_with_adj))
})

test_that("create_isa_signature detects adjacency matrix value changes", {
  skip_if_not(exists("create_isa_signature", mode = "function"),
              "create_isa_signature function not available")

  make_isa <- function(val) {
    list(
      drivers = data.frame(id = "D1", name = "Driver"),
      activities = data.frame(id = "A1", name = "Activity"),
      adjacency_matrices = list(
        D_A = matrix(val, nrow = 1, ncol = 1, dimnames = list("D1", "A1"))
      )
    )
  }

  sig1 <- create_isa_signature(make_isa(1))
  sig2 <- create_isa_signature(make_isa(-1))

  expect_false(identical(sig1, sig2))
})

test_that("create_isa_signature handles data with only partial DAPSIWRM fields", {
  skip_if_not(exists("create_isa_signature", mode = "function"),
              "create_isa_signature function not available")

  # Only drivers and pressures, missing activities etc.
  isa_data <- list(
    drivers = data.frame(id = "D1", name = "Driver"),
    pressures = data.frame(id = "P1", name = "Pressure")
  )

  sig <- create_isa_signature(isa_data)
  # Should still produce a valid signature (missing fields become NULL in the list)
  expect_true(is.character(sig))
  expect_true(nchar(sig) > 0)
})

test_that("create_isa_signature handles all DAPSIWRM fields", {
  skip_if_not(exists("create_isa_signature", mode = "function"),
              "create_isa_signature function not available")

  isa_data <- list(
    drivers = data.frame(id = "D1", name = "D"),
    activities = data.frame(id = "A1", name = "A"),
    pressures = data.frame(id = "P1", name = "P"),
    marine_processes = data.frame(id = "C1", name = "C"),
    ecosystem_services = data.frame(id = "ES1", name = "ES"),
    goods_benefits = data.frame(id = "GB1", name = "GB"),
    responses = data.frame(id = "R1", name = "R"),
    adjacency_matrices = list()
  )

  sig <- create_isa_signature(isa_data)

  expect_true(is.character(sig))
  expect_true(nchar(sig) > 0)
})

test_that("create_isa_signature ignores non-DAPSIWRM fields", {
  skip_if_not(exists("create_isa_signature", mode = "function"),
              "create_isa_signature function not available")

  isa_base <- list(
    drivers = data.frame(id = "D1", name = "Driver")
  )

  isa_with_extra <- isa_base
  isa_with_extra$some_random_field <- "extra data"
  isa_with_extra$another_field <- 42

  sig_base <- create_isa_signature(isa_base)
  sig_extra <- create_isa_signature(isa_with_extra)

  # Extra non-DAPSIWRM fields should not affect the signature
  expect_identical(sig_base, sig_extra)
})

# ============================================================================
# detect_isa_change TESTS
# ============================================================================

test_that("detect_isa_change returns FALSE for NULL ISA data", {
  skip_if_not(exists("detect_isa_change", mode = "function"),
              "detect_isa_change function not available")
  skip_if_not(exists("safe_get_nested", mode = "function"),
              "safe_get_nested function not available")

  project_data <- list(data = list(isa_data = NULL))

  result <- detect_isa_change(project_data, "some_signature")
  expect_false(result)
})

test_that("detect_isa_change returns FALSE for empty ISA data", {
  skip_if_not(exists("detect_isa_change", mode = "function"),
              "detect_isa_change function not available")

  project_data <- list(data = list(isa_data = list()))

  result <- detect_isa_change(project_data, "some_signature")
  expect_false(result)
})

test_that("detect_isa_change returns TRUE when last_signature is NULL (first time)", {
  skip_if_not(exists("detect_isa_change", mode = "function"),
              "detect_isa_change function not available")

  project_data <- list(
    data = list(
      isa_data = list(
        drivers = data.frame(id = "D1", name = "Driver")
      )
    )
  )

  result <- detect_isa_change(project_data, NULL)
  expect_true(result)
})

test_that("detect_isa_change returns FALSE when data has not changed", {
  skip_if_not(exists("detect_isa_change", mode = "function"),
              "detect_isa_change function not available")
  skip_if_not(exists("create_isa_signature", mode = "function"),
              "create_isa_signature function not available")

  isa_data <- list(
    drivers = data.frame(id = "D1", name = "Driver")
  )

  project_data <- list(data = list(isa_data = isa_data))

  # Generate the "last" signature from the same data
  last_sig <- create_isa_signature(isa_data)

  result <- detect_isa_change(project_data, last_sig)
  expect_false(result)
})

test_that("detect_isa_change returns TRUE when data has changed", {
  skip_if_not(exists("detect_isa_change", mode = "function"),
              "detect_isa_change function not available")
  skip_if_not(exists("create_isa_signature", mode = "function"),
              "create_isa_signature function not available")

  isa_data_old <- list(
    drivers = data.frame(id = "D1", name = "Old Driver")
  )
  isa_data_new <- list(
    drivers = data.frame(id = "D1", name = "New Driver")
  )

  last_sig <- create_isa_signature(isa_data_old)
  project_data <- list(data = list(isa_data = isa_data_new))

  result <- detect_isa_change(project_data, last_sig)
  expect_true(result)
})

test_that("detect_isa_change handles missing 'data' key in project_data", {
  skip_if_not(exists("detect_isa_change", mode = "function"),
              "detect_isa_change function not available")

  project_data <- list(metadata = list(name = "Test"))

  result <- detect_isa_change(project_data, "some_sig")
  expect_false(result)
})

test_that("detect_isa_change handles completely empty project_data", {
  skip_if_not(exists("detect_isa_change", mode = "function"),
              "detect_isa_change function not available")

  result <- detect_isa_change(list(), "some_sig")
  expect_false(result)
})

test_that("detect_isa_change handles NULL project_data", {
  skip_if_not(exists("detect_isa_change", mode = "function"),
              "detect_isa_change function not available")

  result <- detect_isa_change(NULL, "some_sig")
  expect_false(result)
})

# ============================================================================
# DEBOUNCE CONFIGURATION TESTS
# ============================================================================

test_that("ISA_DEBOUNCE_MS constant is defined and numeric", {
  skip_if_not(exists("ISA_DEBOUNCE_MS"),
              "ISA_DEBOUNCE_MS constant not defined")

  expect_true(is.numeric(ISA_DEBOUNCE_MS))
  expect_equal(length(ISA_DEBOUNCE_MS), 1)
})

test_that("ISA_DEBOUNCE_MS is within a reasonable range", {
  skip_if_not(exists("ISA_DEBOUNCE_MS"),
              "ISA_DEBOUNCE_MS constant not defined")

  expect_true(ISA_DEBOUNCE_MS >= 0,
              info = "Debounce must not be negative")
  expect_true(ISA_DEBOUNCE_MS <= 10000,
              info = "Debounce should not exceed 10 seconds")
})

test_that("ISA_DEBOUNCE_MS defaults to 500 unless overridden", {
  skip_if_not(exists("ISA_DEBOUNCE_MS"),
              "ISA_DEBOUNCE_MS constant not defined")

  # If no environment variable override was set, expect default
  env_override <- Sys.getenv("MARINESABRES_ISA_DEBOUNCE_MS", "")
  if (env_override == "") {
    expect_equal(ISA_DEBOUNCE_MS, 500)
  } else {
    # If overridden, just verify it matches the env var
    expect_equal(ISA_DEBOUNCE_MS, as.numeric(env_override))
  }
})

# ============================================================================
# SESSION ISOLATION (MULTIPLE EVENT BUSES)
# ============================================================================

test_that("multiple event buses have independent counters", {
  skip_if_not(exists("create_event_bus", mode = "function"),
              "create_event_bus function not available")

  bus_a <- create_event_bus(session_id = "user_a")
  bus_b <- create_event_bus(session_id = "user_b")

  # Emit on bus_a only
  bus_a$emit_isa_change()
  bus_a$emit_isa_change()
  bus_a$emit_isa_change()

  # Emit on bus_b only
  bus_b$emit_cld_update()

  expect_equal(shiny::isolate(bus_a$on_isa_change()), 3)
  expect_equal(shiny::isolate(bus_a$on_cld_update()), 0)
  expect_equal(shiny::isolate(bus_b$on_isa_change()), 0)
  expect_equal(shiny::isolate(bus_b$on_cld_update()), 1)
})

test_that("multiple event buses have independent skip flags", {
  skip_if_not(exists("create_event_bus", mode = "function"),
              "create_event_bus function not available")

  bus_a <- create_event_bus(session_id = "iso_skip_a")
  bus_b <- create_event_bus(session_id = "iso_skip_b")

  bus_a$skip_next_cld_regen(TRUE)

  expect_true(shiny::isolate(bus_a$get_skip_cld_regen(consume = FALSE)))
  expect_false(shiny::isolate(bus_b$get_skip_cld_regen(consume = FALSE)))
})

test_that("five concurrent event buses are all independent", {
  skip_if_not(exists("create_event_bus", mode = "function"),
              "create_event_bus function not available")

  buses <- lapply(1:5, function(i) {
    create_event_bus(session_id = paste0("concurrent_", i))
  })

  # Emit different counts on each bus
  for (i in seq_along(buses)) {
    for (j in seq_len(i)) {
      buses[[i]]$emit_isa_change()
    }
  }

  # Verify each bus has the expected count
  for (i in seq_along(buses)) {
    expect_equal(shiny::isolate(buses[[i]]$on_isa_change()), i,
                 info = paste("Bus", i, "should have count", i))
  }
})

# ============================================================================
# WORKFLOW INTEGRATION TESTS
# ============================================================================

test_that("full event bus workflow: ISA -> CLD -> Analysis", {
  skip_if_not(exists("create_event_bus", mode = "function"),
              "create_event_bus function not available")

  bus <- create_event_bus(session_id = "workflow_test")

  # Step 1: User edits ISA data
  bus$emit_isa_change()
  expect_equal(shiny::isolate(bus$on_isa_change()), 1)

  # Step 2: Pipeline regenerates CLD
  bus$emit_cld_update("reactive_pipeline")
  expect_equal(shiny::isolate(bus$on_cld_update()), 1)

  # Step 3: Analysis is invalidated
  bus$emit_analysis_request("invalidation", "reactive_pipeline")
  expect_equal(shiny::isolate(bus$on_analysis_request()), 1)
})

test_that("skip flag workflow: import sets skip, pipeline reads and clears it", {
  skip_if_not(exists("create_event_bus", mode = "function"),
              "create_event_bus function not available")

  bus <- create_event_bus(session_id = "skip_workflow_test")

  # Import sets the skip flag
  bus$skip_next_cld_regen(TRUE)
  expect_true(shiny::isolate(bus$get_skip_cld_regen(consume = FALSE)))

  # Pipeline reads the flag with consume=TRUE (simulating observer behavior)
  val <- shiny::isolate(bus$get_skip_cld_regen(consume = TRUE))
  expect_true(val)
  # After consumption, flag should be FALSE
  expect_false(shiny::isolate(bus$get_skip_cld_regen(consume = FALSE)))
})

# ============================================================================
# HELPER FUNCTION TESTS
# ============================================================================

test_that("safe_get_nested retrieves deeply nested values", {
  skip_if_not(exists("safe_get_nested", mode = "function"),
              "safe_get_nested function not available")

  data <- list(
    data = list(
      isa_data = list(
        drivers = data.frame(id = "D1")
      ),
      metadata = list(
        data_source = "excel"
      )
    )
  )

  isa_result <- safe_get_nested(data, "data", "isa_data")
  expect_true(is.list(isa_result))
  expect_true("drivers" %in% names(isa_result))

  source_result <- safe_get_nested(data, "data", "metadata", "data_source")
  expect_equal(source_result, "excel")
})

test_that("safe_get_nested returns default for missing path", {
  skip_if_not(exists("safe_get_nested", mode = "function"),
              "safe_get_nested function not available")

  data <- list(a = 1)

  result <- safe_get_nested(data, "nonexistent", "path", default = "fallback")
  expect_equal(result, "fallback")
})

test_that("safe_get_nested returns default for NULL input", {
  skip_if_not(exists("safe_get_nested", mode = "function"),
              "safe_get_nested function not available")

  result <- safe_get_nested(NULL, "any", "path", default = "default_val")
  expect_equal(result, "default_val")
})

test_that("safe_get_nested returns default for partially valid path", {
  skip_if_not(exists("safe_get_nested", mode = "function"),
              "safe_get_nested function not available")

  data <- list(data = list(isa_data = NULL))

  result <- safe_get_nested(data, "data", "isa_data", "drivers", default = "nope")
  expect_equal(result, "nope")
})

test_that("safe_execute returns result on success", {
  skip_if_not(exists("safe_execute", mode = "function"),
              "safe_execute function not available")

  result <- safe_execute({
    1 + 1
  }, default = 0, error_msg = "Addition")

  expect_equal(result, 2)
})

test_that("safe_execute catches errors and returns default", {
  skip_if_not(exists("safe_execute", mode = "function"),
              "safe_execute function not available")

  result <- safe_execute({
    stop("Intentional error")
  }, default = "error_caught", error_msg = "Test error")

  expect_equal(result, "error_caught")
})

test_that("safe_execute handles warnings without crashing", {
  skip_if_not(exists("safe_execute", mode = "function"),
              "safe_execute function not available")

  result <- safe_execute({
    warning("Test warning")
    42
  }, default = 0, error_msg = "Warning test")

  expect_equal(result, 42)
})

# ============================================================================
# SAFE EMIT HELPER TESTS
# ============================================================================

test_that("safe_emit_isa_change works with valid event bus", {
  skip_if_not(exists("safe_emit_isa_change", mode = "function"),
              "safe_emit_isa_change function not available")
  skip_if_not(exists("create_event_bus", mode = "function"),
              "create_event_bus function not available")

  bus <- create_event_bus(session_id = "safe_emit_test")
  safe_emit_isa_change(bus, "test_source")
  expect_equal(shiny::isolate(bus$on_isa_change()), 1)
})

test_that("safe_emit_isa_change is a no-op with NULL event bus", {
  skip_if_not(exists("safe_emit_isa_change", mode = "function"),
              "safe_emit_isa_change function not available")

  # Should not throw an error
  expect_silent(safe_emit_isa_change(NULL, "test_source"))
})

test_that("safe_emit_cld_update works with valid event bus", {
  skip_if_not(exists("safe_emit_cld_update", mode = "function"),
              "safe_emit_cld_update function not available")
  skip_if_not(exists("create_event_bus", mode = "function"),
              "create_event_bus function not available")

  bus <- create_event_bus(session_id = "safe_cld_test")
  safe_emit_cld_update(bus, "test_source")
  expect_equal(shiny::isolate(bus$on_cld_update()), 1)
})

# ============================================================================
# EDGE CASES
# ============================================================================

test_that("create_isa_signature handles ISA data with empty data frames", {
  skip_if_not(exists("create_isa_signature", mode = "function"),
              "create_isa_signature function not available")

  isa_data <- list(
    drivers = data.frame(id = character(0), name = character(0)
                         ),
    activities = data.frame(id = character(0), name = character(0)
                            )
  )

  sig <- create_isa_signature(isa_data)
  # Should produce a valid signature even with empty data frames
  expect_true(is.character(sig))
  expect_true(nchar(sig) > 0)
})

test_that("create_isa_signature handles ISA data with NULL fields", {
  skip_if_not(exists("create_isa_signature", mode = "function"),
              "create_isa_signature function not available")

  isa_data <- list(
    drivers = NULL,
    activities = NULL,
    pressures = NULL,
    marine_processes = NULL,
    ecosystem_services = NULL,
    goods_benefits = NULL,
    responses = NULL,
    adjacency_matrices = NULL
  )

  sig <- create_isa_signature(isa_data)
  expect_true(is.character(sig))
})

test_that("create_isa_signature handles very large ISA data", {
  skip_if_not(exists("create_isa_signature", mode = "function"),
              "create_isa_signature function not available")

  # Generate large data
  n <- 500
  isa_data <- list(
    drivers = data.frame(
      id = paste0("D", 1:n),
      name = paste("Driver", 1:n)

    ),
    activities = data.frame(
      id = paste0("A", 1:n),
      name = paste("Activity", 1:n)

    )
  )

  sig <- create_isa_signature(isa_data)
  expect_true(is.character(sig))
  expect_true(nchar(sig) > 0)
})

test_that("detect_isa_change with mismatched project structure", {
  skip_if_not(exists("detect_isa_change", mode = "function"),
              "detect_isa_change function not available")

  # Project data with unexpected structure
  weird_data <- list(
    foo = "bar",
    data = "not_a_list"
  )

  result <- detect_isa_change(weird_data, "any_sig")
  expect_false(result)
})

test_that("event bus session_id with special characters", {
  skip_if_not(exists("create_event_bus", mode = "function"),
              "create_event_bus function not available")

  bus <- create_event_bus(session_id = "session/with-special_chars.123")
  expect_equal(bus$get_session_id(), "session/with-special_chars.123")

  # Should still function normally
  bus$emit_isa_change()
  expect_equal(shiny::isolate(bus$on_isa_change()), 1)
})

test_that("event bus session_id with empty string", {
  skip_if_not(exists("create_event_bus", mode = "function"),
              "create_event_bus function not available")

  bus <- create_event_bus(session_id = "")
  expect_equal(bus$get_session_id(), "")

  bus$emit_isa_change()
  expect_equal(shiny::isolate(bus$on_isa_change()), 1)
})

# ============================================================================
# CLD GENERATION HELPER TESTS
# ============================================================================

test_that("create_nodes_df generates nodes from ISA data", {
  skip_if_not(exists("create_nodes_df", mode = "function"),
              "create_nodes_df function not available")

  isa_data <- list(
    drivers = data.frame(
      id = "D1", name = "Test Driver", indicator = "Test"

    ),
    activities = data.frame(
      id = "A1", name = "Test Activity", indicator = "Test"

    )
  )

  nodes <- create_nodes_df(isa_data)

  expect_true(is.data.frame(nodes))
  expect_true(nrow(nodes) >= 2)
  expect_true("id" %in% names(nodes) || "ID" %in% names(nodes))
})

test_that("create_edges_df generates edges from adjacency matrices", {
  skip_if_not(exists("create_edges_df", mode = "function"),
              "create_edges_df function not available")
  skip_if_not(exists("create_empty_isa_structure_safe", mode = "function"),
              "create_empty_isa_structure_safe function not available")

  isa_data <- create_empty_isa_structure_safe()

  skip_if(is.null(isa_data$adjacency_matrices),
          "ISA structure doesn't have adjacency_matrices")

  edges <- create_edges_df(isa_data, isa_data$adjacency_matrices)

  expect_true(is.data.frame(edges))
})

# ============================================================================
# ISA VALIDATION TESTS
# ============================================================================

test_that("validate_isa_data accepts valid ISA structure", {
  skip_if_not(exists("validate_isa_data", mode = "function"),
              "validate_isa_data function not available")
  skip_if_not(exists("create_empty_isa_structure_safe", mode = "function"),
              "create_empty_isa_structure_safe function not available")

  isa_data <- create_empty_isa_structure_safe()

  # Add responses if missing
  if (!"responses" %in% names(isa_data)) {
    isa_data$responses <- data.frame(
      id = character(0), name = character(0), indicator = character(0)

    )
  }

  expect_silent(validate_isa_data(isa_data))
})

# ============================================================================
# setup_reactive_pipeline EXISTENCE TEST
# ============================================================================

test_that("setup_reactive_pipeline function exists and is callable", {
  skip_if_not(exists("setup_reactive_pipeline", mode = "function"),
              "setup_reactive_pipeline function not available")

  # Verify it has the expected parameters
  params <- names(formals(setup_reactive_pipeline))
  expect_true("project_data" %in% params)
  expect_true("event_bus" %in% params)
})
