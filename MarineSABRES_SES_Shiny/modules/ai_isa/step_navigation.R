# modules/ai_isa/step_navigation.R
# AI ISA Assistant - Step Navigation
# Purpose: Handle forward and backward navigation through the DAPSI(W)R(M) wizard
#
# Extracted from ai_isa_assistant_module.R for better maintainability
# Dependencies: shinyjs (for runJs scroll), connection_generator.R (for generate_connections)

#' Setup Step Navigation Functions
#'
#' Creates and returns move_to_next_step and move_to_previous_step closures
#' that are bound to the module's reactive context.
#'
#' @param rv Reactive values containing AI ISA state
#' @param session Shiny session object
#' @param i18n i18n translator object
#' @param QUESTION_FLOW Question flow definition list
#'
#' @return List with two functions: move_to_next_step, move_to_previous_step
setup_step_navigation <- function(rv, session, i18n, QUESTION_FLOW) {

  # Move to previous step (Back button functionality)
  move_to_previous_step <- function() {
    # Check if we can move backward
    if (rv$current_step > 0) {
      rv$current_step <- rv$current_step - 1

      # Get the previous step info
      prev_step <- QUESTION_FLOW[[rv$current_step + 1]]

      # Add AI message indicating we're going back
      rv$conversation <- c(rv$conversation, list(
        list(type = "ai",
             message = paste0(i18n$t("modules.isa.ai_assistant.go_back_to_previous_step"), ": ", prev_step$title),
             timestamp = Sys.time())
      ))

      # Re-ask the previous question
      rv$conversation <- c(rv$conversation, list(
        list(type = "ai", message = prev_step$question, timestamp = Sys.time())
      ))

      # Force UI re-render
      rv$render_counter <- (rv$render_counter %||% 0) + 1

      # Scroll to bottom
      shinyjs::runjs(sprintf("document.getElementById('%s').scrollTop = document.getElementById('%s').scrollHeight",
                            session$ns("chat_container"), session$ns("chat_container")))
    }
  }

  # Move to next step
  move_to_next_step <- function() {
    # Temporary forced logging to diagnose country step skip
    message(sprintf("[STEP-NAV] move_to_next_step called: current_step=%d -> %d",
                    rv$current_step, rv$current_step + 1))
    message(sprintf("[STEP-NAV] call stack: %s",
                    paste(sapply(sys.calls(), function(x) deparse(x[[1]])), collapse=" > ")))

    # Check if we can move forward before incrementing
    if (rv$current_step < length(QUESTION_FLOW)) {
      rv$current_step <- rv$current_step + 1
      message(sprintf("[STEP-NAV] Step now = %d (target: %s)",
                      rv$current_step, QUESTION_FLOW[[rv$current_step + 1]]$target))
    }

    if (rv$current_step < length(QUESTION_FLOW)) {
      # Add next question
      next_step <- QUESTION_FLOW[[rv$current_step + 1]]

      # If moving to connection review step, generate connections first
      if (next_step$type == "connection_review") {
        # Check if we have any elements
        total_elements <- sum(
          length(rv$elements$drivers),
          length(rv$elements$activities),
          length(rv$elements$pressures),
          length(rv$elements$states),
          length(rv$elements$impacts),
          length(rv$elements$welfare),
          length(rv$elements$responses)
        )

        if (total_elements == 0) {
          # No elements - show helpful message
          message <- paste0(
            i18n$t("I notice you haven't added any elements yet!"), " ",
            i18n$t("modules.isa.to_create_connections_you_need_to_add_at_least_som"), " ",
            i18n$t("modules.isa.please_go_back_through_the_previous_steps_and_add_")
          )
        } else {
          # Generate connections with progress indicator
          conn_count <- 0
          too_many <- FALSE
          withProgress(message = i18n$t("modules.isa.ai_assistant.analyzing_your_elements_and_generating_connections"),
                      value = 0, {
            incProgress(0.3, detail = i18n$t("modules.isa.ai_assistant.this_may_take_a_moment"))

            # Generate connections (from connection_generator.R)
            debug_log("[AI ISA] About to call generate_connections()...\n")
            all_connections <- generate_connections(rv$elements)
            debug_log(sprintf("[AI ISA] generate_connections() returned %d connections\n", length(all_connections)))

            # Limit to 200 connections for tabbed display (distributed across tabs)
            max_connections <- 200
            if (length(all_connections) > max_connections) {
              rv$suggested_connections <- all_connections[1:max_connections]
              conn_count <<- max_connections
              too_many <<- TRUE
            } else {
              rv$suggested_connections <- all_connections
              conn_count <<- length(rv$suggested_connections)
              too_many <<- FALSE
            }

            # Add a generation timestamp to force UI refresh
            attr(rv$suggested_connections, "generated_at") <- Sys.time()

            debug_log(sprintf("[AI ISA] Generated %d connections for review at %s\n",
                       length(rv$suggested_connections), Sys.time()))
            if (length(rv$suggested_connections) > 0) {
              debug_log(sprintf("[AI ISA] First connection structure: %s\n",
                         paste(names(rv$suggested_connections[[1]]), collapse=", ")))
            }

            incProgress(0.7, detail = i18n$t("modules.isa.ai_assistant.finalizing_connections"))
          })

          if (conn_count == 0) {
            message <- paste0(
              i18n$t("I see you've added"), " ", total_elements, " ", i18n$t("elements, but I couldn't generate connections between them."), " ",
              i18n$t("modules.isa.try_adding_more_elements_to_different_categories_d")
            )
          } else {
            base_message <- paste0(next_step$question, " ", i18n$t("I've identified"), " ", conn_count,
                             " ", i18n$t("modules.isa.potential_connections_based_on_the_dapsiwrm_framew"), " ",
                             i18n$t("modules.isa.ai_assistant.review_each_connection_below_and_approve_or_reject_them"))

            if (too_many) {
              message <- paste0(base_message, " ",
                               i18n$t("modules.isa.ai_assistant.note_i_found_more_connections_but_limited_to"), " ", max_connections,
                               " ", i18n$t("modules.isa.distributed_across_tabs_to_keep_the_interface_resp"))
            } else {
              message <- base_message
            }
          }
        }

        rv$conversation <- c(rv$conversation, list(
          list(type = "ai", message = message, timestamp = Sys.time())
        ))
      } else {
        rv$conversation <- c(rv$conversation, list(
          list(type = "ai", message = next_step$question, timestamp = Sys.time())
        ))
      }
    } else {
      # All done
      rv$conversation <- c(rv$conversation, list(
        list(type = "ai",
             message = i18n$t("Excellent work! You've completed your DAPSI(W)R(M) model with connections. Review the summary on the right, and when ready, click 'Save to ISA Data Entry' to transfer your model to the main ISA module."),
             timestamp = Sys.time())
      ))
    }

    # Scroll to bottom
    shinyjs::runjs(sprintf("document.getElementById('%s').scrollTop = document.getElementById('%s').scrollHeight",
                          session$ns("chat_container"), session$ns("chat_container")))
  }

  return(list(
    move_to_next_step = move_to_next_step,
    move_to_previous_step = move_to_previous_step
  ))
}
