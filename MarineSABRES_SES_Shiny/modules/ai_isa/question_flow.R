# modules/ai_isa/question_flow.R
# AI ISA Question Flow Module
# Purpose: Wizard navigation, session management, and flow control
#
# This module contains the question flow definition, session persistence,
# navigation logic, breadcrumb navigation, progress tracking, and modal dialogs.
#
# Author: Refactored from ai_isa_assistant_module.R
# Date: 2026-01-04
# Dependencies: shiny, i18n, knowledge_base (get_regional_seas_knowledge_base)

# Libraries loaded in global.R: shiny, shinyjs, bs4Dash

# ==============================================================================
# QUESTION FLOW DEFINITION
# ==============================================================================

#' Define AI ISA Question Flow
#'
#' Creates the step-by-step wizard flow for the AI ISA Assistant.
#'
#' @param i18n shiny.i18n translator object
#'
#' @return List of question steps with metadata
#'
#' @details
#' Each step contains:
#' - step: Numeric step index (0-11)
#' - title_key: Translation key for navigation
#' - title: Translated title text
#' - question: AI assistant question text
#' - type: Step type (choice_regional_sea, choice_ecosystem, multiple, connection_review)
#' - target: Target data field (regional_sea, ecosystem_type, drivers, etc.)
#' - use_context_examples: Whether to show context-aware suggestions
#'
#' @export
define_question_flow <- function(i18n) {
  list(
    list(
      step = 0,
      title_key = "regional_sea",
      title = i18n$t("modules.isa.ai_assistant.regional_sea_context"),
      question = i18n$t("modules.isa.ai_assistant.welcome_message"),
      type = "choice_regional_sea",
      target = "regional_sea"
    ),
    list(
      step = 1,
      title_key = "ecosystem",
      title = i18n$t("modules.isa.ai_assistant.ecosystem_type"),
      question = i18n$t("modules.isa.ai_assistant.what_type_of_marine_ecosystem_are_you_studying"),
      type = "choice_ecosystem",
      target = "ecosystem_type"
    ),
    list(
      step = 2,
      title_key = "countries",
      title = i18n$t("modules.isa.ai_assistant.country_selection"),
      question_key = "modules.isa.ai_assistant.question_countries",
      question = i18n$t("modules.isa.ai_assistant.question_countries"),
      type = "country_multiple",
      target = "countries"
    ),
    list(
      step = 3,
      title_key = "main_issue",
      title = i18n$t("modules.isa.ai_assistant.main_issue_identification"),
      question = i18n$t("modules.isa.ai_assistant.question_main_issues"),
      type = "choice_with_custom_multiple",  # Changed to support multiple selections
      target = "main_issue"
    ),
    list(
      step = 4,
      title_key = "drivers",
      title = i18n$t("modules.isa.ai_assistant.drivers_societal_needs"),
      question = i18n$t("modules.isa.ai_assistant.question_drivers"),
      type = "multiple",
      target = "drivers",
      use_context_examples = TRUE
    ),
    list(
      step = 5,
      title_key = "activities",
      title = i18n$t("modules.isa.ai_assistant.activities_human_actions"),
      question = i18n$t("modules.isa.ai_assistant.question_activities"),
      type = "multiple",
      target = "activities",
      use_context_examples = TRUE
    ),
    list(
      step = 6,
      title_key = "pressures",
      title = i18n$t("modules.isa.ai_assistant.pressures_environmental_stressors"),
      question = i18n$t("modules.isa.what_pressures_do_these_activities_put_on_the_mari"),
      type = "multiple",
      target = "pressures",
      use_context_examples = TRUE
    ),
    list(
      step = 7,
      title_key = "states",
      title = i18n$t("modules.isa.ai_assistant.state_changes_ecosystem_effects"),
      question = i18n$t("modules.isa.how_do_these_pressures_change_the_state_of_the_mar"),
      type = "multiple",
      target = "states",
      use_context_examples = TRUE
    ),
    list(
      step = 8,
      title_key = "impacts",
      title = i18n$t("modules.isa.ai_assistant.impacts_effects_on_ecosystem_services"),
      question = i18n$t("modules.isa.what_are_the_impacts_on_ecosystem_services_and_ben"),
      type = "multiple",
      target = "impacts",
      use_context_examples = TRUE
    ),
    list(
      step = 9,
      title_key = "welfare",
      title = i18n$t("modules.isa.ai_assistant.welfare_human_well_being_effects"),
      question = i18n$t("modules.isa.how_do_these_impacts_affect_human_welfare_and_well"),
      type = "multiple",
      target = "welfare",
      use_context_examples = TRUE
    ),
    list(
      step = 10,
      title_key = "responses",
      title = i18n$t("modules.isa.ai_assistant.response_measures_management_policy"),
      question = i18n$t("modules.isa.what_response_measures_management_actions_policies"),
      type = "multiple",
      target = "responses",
      use_context_examples = TRUE
    ),
    list(
      step = 11,
      title_key = "connection_review",
      title = i18n$t("modules.ses.creation.connection_review"),
      question = i18n$t("modules.isa.ai_assistant.connection_review_intro"),
      type = "connection_review",
      target = "connections"
    )
  )
}

# ==============================================================================
# SESSION PERSISTENCE FUNCTIONS
# ==============================================================================
# NOTE: get_session_data() and restore_session_data() are defined in
# modules/ai_isa/data_persistence.R to avoid duplication. They are available
# here because data_persistence.R is sourced in the same module context.

# ==============================================================================
# MODULE INITIALIZATION MESSAGE
# ==============================================================================

debug_log("AI ISA Question Flow module loaded successfully", "INIT")
debug_log("Available functions: define_question_flow", "INIT")

# (Review 2026-10-07 N66: nine setup_*/helper functions left over from an
#  unfinished extraction were removed. None was called -- the live versions
#  are inline in ai_isa_assistant_module.R or in ui_renderers.R -- and some had
#  already drifted from them. Only define_question_flow() is used from here.)
