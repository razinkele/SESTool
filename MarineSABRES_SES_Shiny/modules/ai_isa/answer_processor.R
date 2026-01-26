# modules/ai_isa/answer_processor.R
# AI ISA Assistant - Answer Processing Sub-Module
# Purpose: Process user answers and generate appropriate AI responses
#
# This module handles:
# - Processing user input for different question types
# - Context setting (regional sea, ecosystem, issue)
# - Element addition to DAPSI(W)R(M) framework
# - Polarity detection for connections
# - Relevance calculation for intelligent suggestions

# ============================================================================
# ANSWER PROCESSING
# ============================================================================

#' Process User Answer
#'
#' Main answer processing function that handles different types of user input
#' based on the current step in the question flow
#'
#' @param answer User's text input
#' @param step_info Current step information from QUESTION_FLOW
#' @param rv Reactive values object containing conversation, elements, context
#' @param i18n Translation object
#' @param move_to_next_step_fn Function to move to next step
#' @param REGIONAL_SEAS Regional seas constant
#'
#' @return NULL (modifies rv in place)
process_answer <- function(answer, step_info, rv, i18n, move_to_next_step_fn, REGIONAL_SEAS) {
  cat(sprintf("[AI ISA PROCESS] process_answer called with: '%s'\n", answer))
  cat(sprintf("[AI ISA PROCESS] Step type: %s, target: %s\n", step_info$type, step_info$target))

  # === Handle context-setting steps (regional_sea, ecosystem, issue) ===

  # Regional sea (text input fallback)
  if (step_info$target == "regional_sea") {
    # Try to match input to a regional sea
    matched_sea <- NULL
    for (sea_key in names(REGIONAL_SEAS)) {
      if (grepl(answer, REGIONAL_SEAS[[sea_key]]$name_en, ignore.case = TRUE) ||
          grepl(answer, REGIONAL_SEAS[[sea_key]]$name_i18n, ignore.case = TRUE)) {
        matched_sea <- sea_key
        break
      }
    }

    if (!is.null(matched_sea)) {
      rv$context$regional_sea <- matched_sea
      cat(sprintf("[AI ISA] Regional sea set to: %s (text input)\n", REGIONAL_SEAS[[matched_sea]]$name_en))

      ai_response <- paste0(
        i18n$t("modules.isa.ai_assistant.great_you_selected"), " ", REGIONAL_SEAS[[matched_sea]]$name_i18n, ". ",
        i18n$t("modules.isa.this_will_help_me_suggest_relevant_activities_and_")
      )
    } else {
      # Couldn't match, use "other"
      rv$context$regional_sea <- "other"
      cat("[AI ISA] Regional sea set to: other (text input not matched)\n")
      ai_response <- i18n$t("I'll use general marine suggestions for your area.")
    }

    rv$conversation <- c(rv$conversation, list(
      list(type = "ai", message = ai_response, timestamp = Sys.time())
    ))

    move_to_next_step_fn()
    return()
  }

  # Ecosystem type (text input fallback)
  else if (step_info$target == "ecosystem_type") {
    rv$context$ecosystem_type <- answer
    cat(sprintf("[AI ISA] Ecosystem type set to: %s (text input)\n", answer))

    ai_response <- paste0(
      i18n$t("modules.isa.ai_assistant.perfect"), " ", answer, " ",
      i18n$t("ecosystems have unique characteristics that I'll consider in my suggestions.")
    )

    rv$conversation <- c(rv$conversation, list(
      list(type = "ai", message = ai_response, timestamp = Sys.time())
    ))

    move_to_next_step_fn()
    return()
  }

  # Main issue (text input)
  else if (step_info$target == "main_issue") {
    rv$context$main_issue <- answer
    cat(sprintf("[AI ISA] Main issue set to: %s\n", answer))

    ai_response <- paste0(
      i18n$t("Understood. I'll focus suggestions on"), " ", tolower(answer), "-related issues. ",
      i18n$t("Now let's start building your DAPSI(W)R(M) framework!")
    )

    rv$conversation <- c(rv$conversation, list(
      list(type = "ai", message = ai_response, timestamp = Sys.time())
    ))

    move_to_next_step_fn()
    return()
  }

  # === Handle DAPSI(W)R(M) element addition ===

  if (step_info$type == "multiple") {
    cat(sprintf("[AI ISA PROCESS] Adding element to %s\n", step_info$target))

    # Add to list
    current_list <- rv$elements[[step_info$target]]
    new_element <- list(
      name = answer,
      description = "",
      timestamp = Sys.time()
    )
    rv$elements[[step_info$target]] <- c(current_list, list(new_element))

    # Count current elements in this category
    element_count <- length(rv$elements[[step_info$target]])
    cat(sprintf("[AI ISA PROCESS] Element added! Total %s: %d\n", step_info$target, element_count))

    # Hide text input and show continue button again
    rv$show_text_input <- FALSE

    # AI response with count
    ai_response <- paste0(
      i18n$t("modules.isa.ai_assistant.added"), " '", answer, "' (",
      element_count, " ", step_info$target, " ",
      i18n$t("modules.isa.ai_assistant.total"), "). ",
      i18n$t("modules.isa.click_quick_options_to_add_more_or_click_the_green")
    )

    # Add AI response
    rv$conversation <- c(rv$conversation, list(
      list(type = "ai", message = ai_response, timestamp = Sys.time())
    ))

  } else {
    # Store single value
    rv$context[[step_info$target]] <- answer

    # Add AI response BEFORE moving to next step
    rv$conversation <- c(rv$conversation, list(
      list(type = "ai", message = i18n$t("modules.isa.ai_assistant.thank_you_moving_to_the_next_question"), timestamp = Sys.time())
    ))

    move_to_next_step_fn()
  }
}

# NOTE: detect_polarity() and calculate_relevance() are in connection_generator.R
