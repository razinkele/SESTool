# functions/reactive_pipeline.R
# Reactive Data Pipeline System
# Purpose: Event-based reactive architecture for automatic data flow ISA → CLD → Analysis

#' Create reactive event bus
#'
#' Creates a reactive event system for coordinating data updates across modules
#'
#' @return List with event triggers and handlers
create_event_bus <- function() {
  # Create reactive values first
  isa_changed_val <- reactiveVal(0)
  cld_changed_val <- reactiveVal(0)
  analysis_invalidated_val <- reactiveVal(0)
  last_isa_signature_val <- reactiveVal(NULL)
  last_cld_signature_val <- reactiveVal(NULL)
  skip_next_cld_regen_val <- reactiveVal(FALSE)

  list(
    # Event triggers (reactiveVal for each event type)
    isa_changed = isa_changed_val,
    cld_changed = cld_changed_val,
    analysis_invalidated = analysis_invalidated_val,

    # Event metadata
    last_isa_signature = last_isa_signature_val,
    last_cld_signature = last_cld_signature_val,
    skip_next_cld_regen = skip_next_cld_regen_val,

    # Helper: Emit ISA changed event
    emit_isa_change = function() {
      current_val <- isolate(isa_changed_val())
      isa_changed_val(current_val + 1)
      debug_log(sprintf("ISA changed event emitted (#%d)", current_val + 1), "EVENT BUS")
    },

    # Helper: Emit CLD changed event
    emit_cld_change = function() {
      current_val <- isolate(cld_changed_val())
      cld_changed_val(current_val + 1)
      debug_log(sprintf("CLD changed event emitted (#%d)", current_val + 1), "EVENT BUS")
    },

    # Helper: Emit analysis invalidation event
    emit_analysis_invalidation = function() {
      current_val <- isolate(analysis_invalidated_val())
      analysis_invalidated_val(current_val + 1)
      debug_log(sprintf("Analysis invalidated event emitted (#%d)", current_val + 1), "EVENT BUS")
    }
  )
}

#' Setup reactive pipeline coordinator
#'
#' Sets up observers that handle automatic data propagation:
#' - ISA changes → regenerate CLD
#' - CLD changes → invalidate analysis
#'
#' @param project_data Reactive value containing project data
#' @param event_bus Event bus created by create_event_bus()
#' @return NULL (side effects only - sets up observers)
setup_reactive_pipeline <- function(project_data, event_bus) {

  debug_log("Setting up reactive data pipeline...", "PIPELINE")
  debug_log(sprintf("ISA change debounce: %d ms", ISA_DEBOUNCE_MS), "PIPELINE")

  # ============================================================================
  # Observer 1: ISA changes → Regenerate CLD (with debouncing)
  # ============================================================================

  # Create debounced ISA change reactive
  # This delays CLD regeneration by ISA_DEBOUNCE_MS after the last ISA change
  # Prevents excessive regenerations during rapid consecutive edits
  isa_changed_debounced <- debounce(
    reactive({ event_bus$isa_changed() }),
    millis = ISA_DEBOUNCE_MS
  )

  observe({
    # Watch for debounced ISA change events
    isa_changed_debounced()

    data <- isolate(project_data())
    isa_data <- isolate(data$data$isa_data)
    data_source <- isolate(data$data$metadata$data_source)

    # Skip if flagged (e.g., after import that already generated CLD)
    if (isolate(event_bus$skip_next_cld_regen())) {
      debug_log("Skipping CLD regeneration (skip flag set)", "PIPELINE")
      event_bus$skip_next_cld_regen(FALSE)
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
    last_isa_sig <- isolate(event_bus$last_isa_signature())

    if (!is.null(current_isa_sig) && identical(current_isa_sig, last_isa_sig)) {
      debug_log("ISA data signature unchanged. Skipping CLD regeneration.", "PIPELINE")
      return()
    }

    debug_log("ISA change detected, regenerating CLD...", "PIPELINE")
    shinyjs::show("pipeline_status_indicator")

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

      # Update signature and emit CLD changed event
      event_bus$last_isa_signature(current_isa_sig)
      event_bus$emit_cld_change()

      debug_log("CLD regeneration complete", "PIPELINE")

    }, error = function(e) {
      debug_log(sprintf("CLD regeneration failed: %s", e$message), "PIPELINE ERROR")
      warning(sprintf("CLD regeneration failed: %s", e$message))
    }, finally = {
      shinyjs::hide("pipeline_status_indicator")
    })

  }) %>% bindEvent(isa_changed_debounced(), ignoreInit = TRUE)

  # ============================================================================
  # Observer 2: CLD/ISA changes → Invalidate analysis
  # ============================================================================
  observe({
    # Watch for ISA or CLD changes
    event_bus$isa_changed()
    event_bus$cld_changed()

    data <- isolate(project_data())

    # Check if analysis data exists
    has_analysis <- !is.null(data$data$analysis) &&
                    (length(data$data$analysis$loops) > 0 ||
                     length(data$data$analysis$metrics) > 0)

    if (has_analysis) {
      debug_log("Data changed, invalidating analysis results...", "PIPELINE")
      shinyjs::show("pipeline_status_indicator")

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

      # Emit analysis invalidation event
      event_bus$emit_analysis_invalidation()

      debug_log("Analysis invalidated", "PIPELINE")
      shinyjs::hide("pipeline_status_indicator")
    }

  }) %>% bindEvent(list(event_bus$isa_changed(), event_bus$cld_changed()), ignoreInit = TRUE)

  debug_log("Reactive pipeline setup complete", "PIPELINE")
  debug_log("- ISA changes will auto-regenerate CLD", "PIPELINE")
  debug_log("- Data changes will auto-invalidate analysis", "PIPELINE")
}

#' Helper: Create ISA data signature for change detection
#'
#' Creates a hash signature of ISA data to detect when it actually changes
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
#' Compares current ISA signature with last known signature
#'
#' @param project_data Current project data
#' @param last_signature Last known ISA signature
#' @return TRUE if changed, FALSE otherwise
detect_isa_change <- function(project_data, last_signature) {
  current_sig <- create_isa_signature(project_data$data$isa_data)

  if (is.null(current_sig)) {
    return(FALSE)
  }

  if (is.null(last_signature)) {
    return(TRUE)  # First time
  }

  !identical(current_sig, last_signature)
}
