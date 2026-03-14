# functions/reactive_pipeline.R
# ============================================================================
# Reactive Data Pipeline System
# ============================================================================
#
# Purpose: Automatic data flow propagation: ISA -> CLD -> Analysis
#
# Architecture:
#   This module provides setup_reactive_pipeline() which wires observers to
#   the event bus created by server/event_bus_setup.R. The event bus is the
#   SINGLE source of truth for cross-module communication:
#
#     Modules emit:   event_bus$emit_isa_change(source)
#     Pipeline hears: event_bus$on_isa_change()
#     Pipeline emits: event_bus$emit_cld_update(source)
#     Modules hear:   event_bus$on_cld_update()
#
#   The pipeline adds debounced ISA->CLD regeneration and automatic analysis
#   invalidation on top of the event bus. Without this pipeline, modules would
#   need to manually regenerate the CLD and invalidate analysis after each
#   ISA change.
#
# Dependencies:
#   - server/event_bus_setup.R  (create_event_bus, event bus API)
#   - functions/error_handling.R (safe_execute, safe_get_nested)
#   - functions/data_structure.R (validate_isa_data, create_nodes_df, create_edges_df)
#   - constants.R               (ISA_DEBOUNCE_MS)
#   - digest package            (for ISA signature hashing)
# ============================================================================

#' Setup reactive pipeline coordinator
#'
#' Sets up observers that handle automatic data propagation:
#' - ISA changes -> regenerate CLD (debounced)
#' - CLD/ISA changes -> invalidate analysis
#'
#' This function wires into the event bus from server/event_bus_setup.R.
#' The event bus uses emit_isa_change()/on_isa_change() and
#' emit_cld_update()/on_cld_update() methods.
#'
#' @param project_data Reactive value containing project data
#' @param event_bus Event bus created by create_event_bus() in server/event_bus_setup.R
#' @return NULL (side effects only - sets up observers)
setup_reactive_pipeline <- function(project_data, event_bus) {

  debug_log("Setting up reactive data pipeline...", "PIPELINE")
  debug_log(sprintf("ISA change debounce: %d ms", ISA_DEBOUNCE_MS), "PIPELINE")

  # Private state for signature-based change detection
  last_isa_signature <- reactiveVal(NULL)

  # ============================================================================
  # Observer 1: ISA changes -> Regenerate CLD (with debouncing)
  # ============================================================================

  # Create debounced ISA change reactive using the new event bus API.
  # event_bus$on_isa_change() returns the reactive trigger value.
  # Debouncing prevents excessive CLD regenerations during rapid edits.
  isa_changed_debounced <- debounce(
    reactive({ event_bus$on_isa_change() }),
    millis = ISA_DEBOUNCE_MS
  )

  observe({
    # Watch for debounced ISA change events
    isa_changed_debounced()

    data <- isolate(project_data())
    # Use safe_get_nested for defensive data access
    isa_data <- safe_get_nested(data, "data", "isa_data", default = NULL)

    # Skip if flagged (e.g., after import that already generated CLD).
    # The flag is set by modules via event_bus$skip_next_cld_regen(TRUE)
    # and consumed (reset to FALSE) here by get_skip_cld_regen(consume=TRUE).
    if (isolate(event_bus$get_skip_cld_regen(consume = TRUE))) {
      debug_log("Skipping CLD regeneration (skip flag set by module)", "PIPELINE")
      return()
    }

    # Validate ISA data exists
    if (is.null(isa_data) || length(isa_data) == 0) {
      debug_log("No ISA data to process", "PIPELINE")
      return()
    }

    # Validate ISA data structure
    validation_result <- safe_execute({
      validate_isa_data(isa_data)
      TRUE
    }, default = FALSE, error_msg = "ISA data validation")

    if (!validation_result) {
      debug_log("ISA data validation failed, skipping CLD regeneration", "PIPELINE")
      return()
    }

    # Signature-based change detection
    current_isa_sig <- create_isa_signature(isa_data)
    last_isa_sig <- isolate(last_isa_signature())

    if (!is.null(current_isa_sig) && identical(current_isa_sig, last_isa_sig)) {
      debug_log("ISA data signature unchanged. Skipping CLD regeneration.", "PIPELINE")
      return()
    }

    debug_log("ISA change detected, regenerating CLD...", "PIPELINE")
    tryCatch(shinyjs::show("pipeline_status_indicator"), error = function(e) NULL)

    tryCatch({
      # Generate CLD from ISA with error handling
      cld_nodes <- safe_execute({
        create_nodes_df(isa_data)
      }, default = data.frame(), error_msg = "CLD nodes generation")

      cld_edges <- safe_execute({
        create_edges_df(isa_data, isa_data$adjacency_matrices)
      }, default = data.frame(), error_msg = "CLD edges generation")

      # Validate generated CLD
      if (!has_data(cld_nodes)) {
        stop("Failed to generate CLD nodes")
      }

      debug_log(sprintf("Generated CLD: %d nodes, %d edges",
                  nrow(cld_nodes), nrow(cld_edges)), "PIPELINE")

      # Update CLD in project data
      data$data$cld <- list(
        nodes = cld_nodes,
        edges = cld_edges,
        loops = NULL,
        metrics = NULL,
        simplified = FALSE,
        simplification_history = list()
      )

      data$last_modified <- Sys.time()

      # Save back to reactive
      project_data(data)

      # Update signature and emit CLD update event via the event bus
      last_isa_signature(current_isa_sig)
      event_bus$emit_cld_update("reactive_pipeline")

      debug_log("CLD regeneration complete", "PIPELINE")

    }, error = function(e) {
      debug_log(sprintf("CLD regeneration failed: %s", e$message), "PIPELINE ERROR")
      warning(sprintf("CLD regeneration failed: %s", e$message))
    }, finally = {
      tryCatch(shinyjs::hide("pipeline_status_indicator"), error = function(e) NULL)
    })

  })

  # ============================================================================
  # Observer 2: CLD/ISA changes -> Invalidate analysis
  # ============================================================================
  observe({
    # Watch for ISA or CLD changes using the new event bus API
    event_bus$on_isa_change()
    event_bus$on_cld_update()

    data <- isolate(project_data())

    # Check if analysis data exists
    has_analysis <- !is.null(data$data$analysis) &&
                    (length(data$data$analysis$loops) > 0 ||
                     length(data$data$analysis$metrics) > 0)

    if (has_analysis) {
      debug_log("Data changed, invalidating analysis results...", "PIPELINE")
      tryCatch(shinyjs::show("pipeline_status_indicator"), error = function(e) NULL)

      # Clear analysis data
      data$data$analysis <- list(
        loops = NULL,
        metrics = NULL,
        cleared_at = Sys.time(),
        reason = "Data changed"
      )

      data$last_modified <- Sys.time()

      # Save back to reactive
      project_data(data)

      # Emit analysis request event via the event bus
      event_bus$emit_analysis_request("invalidation", "reactive_pipeline")

      debug_log("Analysis invalidated", "PIPELINE")
      tryCatch(shinyjs::hide("pipeline_status_indicator"), error = function(e) NULL)
    }

  })

  debug_log("Reactive pipeline setup complete", "PIPELINE")
  debug_log("- ISA changes will auto-regenerate CLD (debounced)", "PIPELINE")
  debug_log("- Data changes will auto-invalidate analysis", "PIPELINE")
  debug_log("- Modules can call event_bus$skip_next_cld_regen() before emit_isa_change()", "PIPELINE")

  invisible(NULL)
}

#' Helper: Create ISA data signature for change detection
#'
#' Creates a hash signature of ISA data to detect when it actually changes.
#' Used by the pipeline to avoid redundant CLD regenerations.
#'
#' @param isa_data ISA data structure
#' @return String signature or NULL if isa_data is invalid
create_isa_signature <- function(isa_data) {
  if (is.null(isa_data) || length(isa_data) == 0) {
    return(NULL)
  }

  tryCatch({
    # Create signature from key ISA components
    sig_data <- list(
      drivers = isa_data$drivers,
      activities = isa_data$activities,
      pressures = isa_data$pressures,
      marine_processes = isa_data$marine_processes,
      ecosystem_services = isa_data$ecosystem_services,
      goods_benefits = isa_data$goods_benefits,
      responses = isa_data$responses,
      adjacency_matrices = isa_data$adjacency_matrices
    )

    # Use digest to create hash (faster than serializing)
    digest::digest(sig_data, algo = "xxhash64")

  }, error = function(e) {
    debug_log(sprintf("Failed to create ISA signature: %s", e$message), "PIPELINE WARNING")
    NULL
  })
}

#' Helper: Detect if ISA data has changed
#'
#' Compares current ISA signature with last known signature.
#' Uses safe_get_nested for defensive data access.
#'
#' @param project_data Current project data
#' @param last_signature Last known ISA signature
#' @return TRUE if changed, FALSE otherwise
detect_isa_change <- function(project_data, last_signature) {
  # Use safe_get_nested for defensive access
  isa_data <- safe_get_nested(project_data, "data", "isa_data", default = NULL)
  current_sig <- create_isa_signature(isa_data)

  if (is.null(current_sig)) {
    return(FALSE)
  }

  if (is.null(last_signature)) {
    return(TRUE)  # First time
  }

  !identical(current_sig, last_signature)
}
