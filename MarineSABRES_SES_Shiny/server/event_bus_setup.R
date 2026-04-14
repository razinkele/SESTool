# server/event_bus_setup.R
# ============================================================================
# Event Bus Setup and Configuration
#
# Creates and configures the reactive event bus for cross-module communication.
# The event bus enables loose coupling between modules while maintaining
# proper reactive invalidation.
# ============================================================================

#' Create Event Bus
#'
#' Creates a reactive event bus for cross-module communication.
#' The event bus provides named reactive triggers that modules can emit and observe.
#'
#' @param session_id Optional session ID for debugging
#' @return Event bus object with emit and observe functions
#' @export
create_event_bus <- function(session_id = NULL) {
  # Private storage for reactive triggers
  triggers <- new.env(parent = emptyenv())

  # Create reactive values for each event type
  triggers$isa_change <- shiny::reactiveVal(0)
  triggers$cld_update <- shiny::reactiveVal(0)
  triggers$analysis_request <- shiny::reactiveVal(0)
  triggers$template_loaded <- shiny::reactiveVal(0)
  triggers$project_saved <- shiny::reactiveVal(0)
  triggers$project_loaded <- shiny::reactiveVal(0)
  triggers$navigation_request <- shiny::reactiveVal(NULL)
  triggers$language_changed <- shiny::reactiveVal(0)

  # Per-session event metadata stored as reactiveVals for proper isolation
  last_event_val <- shiny::reactiveVal(NULL)
  event_count_val <- shiny::reactiveVal(0)
  bus_session_id <- session_id

  # Pipeline control flag: when TRUE, the reactive pipeline will skip
  # the next CLD regeneration (used by import/load modules that already
  # build CLD from connection data). Read and reset by setup_reactive_pipeline().
  skip_cld_regen_val <- shiny::reactiveVal(FALSE)

  # Shared cached igraph built from ISA data. Set by the reactive pipeline

  # after ISA changes; consumed by analysis modules to avoid redundant builds.
  cached_isa_igraph_val <- shiny::reactiveVal(NULL)

  # Create the event bus object
  event_bus <- list(
    # ========== ISA Change Events ==========
    # Emitted when ISA data is modified (elements added/removed/updated)
    emit_isa_change = function(source = "unknown") {
      current <- triggers$isa_change()
      triggers$isa_change(current + 1)
      last_event_val(list(type = "isa_change", source = source, time = Sys.time()))
      event_count_val(event_count_val() + 1)
      debug_log(sprintf("Event: isa_change emitted by %s (count: %d)", source, current + 1), "EVENT_BUS")
    },

    on_isa_change = function() {
      triggers$isa_change()
    },

    # ========== CLD Update Events ==========
    # Emitted when CLD visualization needs refresh
    emit_cld_update = function(source = "unknown") {
      current <- triggers$cld_update()
      triggers$cld_update(current + 1)
      last_event_val(list(type = "cld_update", source = source, time = Sys.time()))
      event_count_val(event_count_val() + 1)
      debug_log(sprintf("Event: cld_update emitted by %s (count: %d)", source, current + 1), "EVENT_BUS")
    },

    on_cld_update = function() {
      triggers$cld_update()
    },

    # ========== Analysis Request Events ==========
    # Emitted when an analysis should be run
    emit_analysis_request = function(analysis_type = "all", source = "unknown") {
      current <- triggers$analysis_request()
      triggers$analysis_request(current + 1)
      last_event_val(list(type = "analysis_request", analysis_type = analysis_type,
                          source = source, time = Sys.time()))
      event_count_val(event_count_val() + 1)
      debug_log(sprintf("Event: analysis_request (%s) emitted by %s", analysis_type, source), "EVENT_BUS")
    },

    on_analysis_request = function() {
      triggers$analysis_request()
    },

    # ========== Template Loaded Events ==========
    # Emitted when a template is loaded
    emit_template_loaded = function(template_name = "unknown", source = "unknown") {
      current <- triggers$template_loaded()
      triggers$template_loaded(current + 1)
      last_event_val(list(type = "template_loaded", template = template_name,
                          source = source, time = Sys.time()))
      event_count_val(event_count_val() + 1)
      debug_log(sprintf("Event: template_loaded (%s) emitted by %s", template_name, source), "EVENT_BUS")
    },

    on_template_loaded = function() {
      triggers$template_loaded()
    },

    # ========== Project Save/Load Events ==========
    emit_project_saved = function(project_name = "unknown", source = "unknown") {
      current <- triggers$project_saved()
      triggers$project_saved(current + 1)
      last_event_val(list(type = "project_saved", project = project_name,
                          source = source, time = Sys.time()))
      event_count_val(event_count_val() + 1)
      debug_log(sprintf("Event: project_saved (%s) emitted by %s", project_name, source), "EVENT_BUS")
    },

    on_project_saved = function() {
      triggers$project_saved()
    },

    emit_project_loaded = function(project_name = "unknown", source = "unknown") {
      current <- triggers$project_loaded()
      triggers$project_loaded(current + 1)
      last_event_val(list(type = "project_loaded", project = project_name,
                          source = source, time = Sys.time()))
      event_count_val(event_count_val() + 1)
      debug_log(sprintf("Event: project_loaded (%s) emitted by %s", project_name, source), "EVENT_BUS")
    },

    on_project_loaded = function() {
      triggers$project_loaded()
    },

    # ========== Navigation Request Events ==========
    # Emitted to request navigation to a specific tab
    emit_navigation_request = function(target_tab, source = "unknown") {
      triggers$navigation_request(list(tab = target_tab, time = Sys.time()))
      last_event_val(list(type = "navigation_request", target = target_tab,
                          source = source, time = Sys.time()))
      event_count_val(event_count_val() + 1)
      debug_log(sprintf("Event: navigation_request to %s emitted by %s", target_tab, source), "EVENT_BUS")
    },

    on_navigation_request = function() {
      triggers$navigation_request()
    },

    # ========== Language Changed Events ==========
    # Emitted after the session translator's language is changed.
    # Modules with cached i18n in reactive() or renderUI() blocks can
    # observe this and re-render with the new language.
    emit_language_changed = function(new_lang = "unknown", source = "unknown") {
      current <- triggers$language_changed()
      triggers$language_changed(current + 1)
      last_event_val(list(type = "language_changed", new_lang = new_lang,
                          source = source, time = Sys.time()))
      event_count_val(event_count_val() + 1)
      debug_log(sprintf("Event: language_changed to %s emitted by %s (count: %d)", new_lang, source, current + 1), "EVENT_BUS")
    },

    on_language_changed = function() {
      triggers$language_changed()
    },

    # ========== Pipeline Control ==========
    # Signal the reactive pipeline to skip the next CLD regeneration.
    # Used by modules that import data with pre-built CLD (e.g., import, ses_models).
    skip_next_cld_regen = function(value = TRUE) {
      skip_cld_regen_val(value)
      if (value) {
        debug_log("Pipeline: skip_next_cld_regen flag set", "EVENT_BUS")
      }
    },

    # Read (and optionally consume) the skip flag. Called by setup_reactive_pipeline().
    get_skip_cld_regen = function(consume = TRUE) {
      val <- skip_cld_regen_val()
      if (consume && val) {
        skip_cld_regen_val(FALSE)
      }
      val
    },

    # ========== Cached ISA igraph ==========
    # Shared igraph built from ISA data by the reactive pipeline.
    # Analysis modules should use get_isa_igraph() instead of building
    # their own graph from ISA data.
    set_isa_igraph = function(g) {
      cached_isa_igraph_val(g)
    },

    get_isa_igraph = function() {
      cached_isa_igraph_val()
    },

    # ========== Utility Functions ==========
    get_event_count = function() {
      event_count_val()
    },

    get_last_event = function() {
      last_event_val()
    },

    get_session_id = function() {
      bus_session_id
    }
  )

  # Add class for type checking
  class(event_bus) <- c("event_bus", "list")

  debug_log(sprintf("Event bus created for session: %s", session_id %||% "unknown"), "EVENT_BUS")

  event_bus
}

#' Check if Object is Event Bus
#'
#' @param x Object to check
#' @return TRUE if x is an event bus, FALSE otherwise
#' @export
is_event_bus <- function(x) {
  inherits(x, "event_bus")
}

#' Safely Emit ISA Change
#'
#' Safely emits an ISA change event if event_bus is available.
#' This is a convenience function for modules that may or may not have event_bus.
#'
#' @param event_bus The event bus (can be NULL)
#' @param source The source module name
#' @export
safe_emit_isa_change <- function(event_bus, source = "unknown") {
  if (!is.null(event_bus) && is_event_bus(event_bus)) {
    event_bus$emit_isa_change(source)
  }
}

#' Safely Emit CLD Update
#'
#' Safely emits a CLD update event if event_bus is available.
#'
#' @param event_bus The event bus (can be NULL)
#' @param source The source module name
#' @export
safe_emit_cld_update <- function(event_bus, source = "unknown") {
  if (!is.null(event_bus) && is_event_bus(event_bus)) {
    event_bus$emit_cld_update(source)
  }
}

#' Setup Navigation Handler
#'
#' Creates an observer that handles navigation requests from the event bus.
#'
#' @param event_bus The event bus
#' @param session The Shiny session
#' @return The observer (for reference)
#' @export
setup_navigation_handler <- function(event_bus, session) {
  shiny::observe({
    nav_request <- event_bus$on_navigation_request()
    shiny::req(nav_request)

    target_tab <- nav_request$tab
    if (!is.null(target_tab) && nchar(target_tab) > 0) {
      bs4Dash::updateTabItems(session, "sidebar", target_tab)
      debug_log(sprintf("Navigated to tab: %s", target_tab), "EVENT_BUS")
    }
  })
}
