# modules/ai_isa/ui_components.R
# AI ISA UI Components Module
# Purpose: All visual components, styling, and rendering logic
#
# This module contains the UI definition, CSS styling, JavaScript handlers,
# and all output rendering functions for the AI ISA Assistant interface.
#
# Author: Refactored from ai_isa_assistant_module.R
# Date: 2026-01-04
# Dependencies: shiny, shinyjs, bs4Dash, i18n, connection_review_tabbed module

# Libraries loaded in global.R: shiny, shinyjs, bs4Dash

# ==============================================================================
# MAIN UI FUNCTION
# ==============================================================================

# NOTE: ai_isa_assistant_ui() is defined in ai_isa_assistant_module.R (the parent module).

# ==============================================================================
# SHARED ELEMENT SUMMARY RENDERING
# ==============================================================================

#' Render DAPSIWRM Element Summary UI
#'
#' Generates color-coded UI sections for each DAPSIWRM element type.
#' Used by both the preview modal and the question flow preview.
#'
#' @param elements List with named sublists: drivers, activities, pressures,
#'   states, impacts, welfare, responses. Each sublist contains items with
#'   a \code{name} field.
#' @param i18n shiny.i18n translator object
#'
#' @return tagList of div elements for non-empty element categories
#'
#' @export
render_element_summary_ui <- function(elements, i18n) {
  # Define the element types with their display properties
  element_types <- list(
    list(key = "drivers",    color = "#776db3;",                                  icon = "flag",                 title_key = "modules.isa.ai_assistant.drivers_societal_needs"),
    list(key = "activities", color = "#5abc67;",                                  icon = "running",              title_key = "modules.isa.ai_assistant.activities_human_actions"),
    list(key = "pressures",  color = "#fec05a;",                                  icon = "exclamation-triangle",  title_key = "modules.isa.ai_assistant.pressures_environmental_stressors"),
    list(key = "states",     color = "#bce2ee;",                                  icon = "water",                title_key = "modules.isa.ai_assistant.state_changes_ecosystem_effects"),
    list(key = "impacts",    color = "#313695;",                                  icon = "chart-line",           title_key = "modules.isa.ai_assistant.impacts_service_effects"),
    list(key = "welfare",    color = "#fff1a2; text-shadow: 1px 1px 2px #666;",   icon = "heart",                title_key = "modules.isa.ai_assistant.welfare_human_well_being"),
    list(key = "responses",  color = "#66c2a5;",                                  icon = "shield-alt",           title_key = "modules.isa.ai_assistant.response_measures_management_policy")
  )

  sections <- lapply(element_types, function(et) {
    items <- elements[[et$key]]
    if (length(items) > 0) {
      div(
        h4(style = paste0("color: ", et$color), icon(et$icon), " ", i18n$t(et$title_key)),
        tags$ul(lapply(items, function(item) tags$li(item$name)))
      )
    }
  })

  # Filter out NULLs from empty categories
  do.call(tagList, Filter(Negate(is.null), sections))
}

# ==============================================================================
# MODULE INITIALIZATION MESSAGE
# ==============================================================================

debug_log("AI ISA UI Components module loaded successfully", "INIT")
debug_log("Available functions: render_element_summary_ui", "INIT")

# (Review 2026-10-07 N66: get_ai_isa_css/get_ai_isa_js/highlight_keywords/
#  setup_ui_outputs were removed -- never called; the live copies are inline in
#  ai_isa_assistant_module.R. render_element_summary_ui() is used.)
