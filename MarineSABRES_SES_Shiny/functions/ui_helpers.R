# functions/ui_helpers.R
# UI Helper Functions for MarineSABRES SES Shiny Application
# Reduces code duplication across modules

# ============================================================================
# MODULE HEADER CREATION
# ============================================================================

#' Create a standard module header
#'
#' @param ns The namespace function from the module's session.
#' @param title_key The translation key for the main title for the header.
#' @param subtitle_key The translation key for the short description to display below the title.
#' @param help_id The input ID for the help button.
#' @param i18n The translator object.
#' @return A Shiny UI tag list.
create_module_header <- function(ns, title_key, subtitle_key, help_id, i18n) {
  # Use the wrapper directly to translate namespaced keys
  # This gives correct translations but they won't update dynamically when language changes
  # User needs to refresh the page after changing language to see updated module headers
  tagList(
    div(style = "display: flex; justify-content: space-between; align-items: center;",
      div(
        h3(i18n$t(title_key)),
        p(i18n$t(subtitle_key))
      ),
      div(style = "margin-top: 10px;",
        actionButton(ns(help_id), i18n$t("ui.header.help"),
                    icon = icon("question-circle"),
                    class = "btn btn-info btn-lg")
      )
    ),
    hr()
  )
}

# ============================================================================
# REACTIVE MODULE HEADER
# ============================================================================

#' Create a reactive module header observer
#'
#' Call this in your module's server function to make the header reactive to language changes.
#'
#' @param output The output object from the module's server function.
#' @param ns The namespace function from the module's session.
#' @param header_id The output ID for the header (default: "module_header").
#' @param title_key The translation key for the main title.
#' @param subtitle_key The translation key for the subtitle.
#' @param help_id The input ID for the help button.
#' @param i18n The translator object.
#' @return None (sets up reactive output)
create_reactive_header <- function(output, ns, header_id = "module_header",
                                   title_key, subtitle_key, help_id, i18n) {
  output[[header_id]] <- renderUI({
    create_module_header(
      ns = ns,
      title_key = title_key,
      subtitle_key = subtitle_key,
      help_id = help_id,
      i18n = i18n
    )
  })
}

# ============================================================================
# HELP MODAL OBSERVER
# ============================================================================

#' Create an observer for a help modal
#'
#' @param input The input object from the module's server function.
#' @param input_id The ID of the help button.
#' @param title_key The translation key for the title of the modal dialog.
#' @param content A tagList or character vector for the modal's body.
#' @param i18n The translator object.
create_help_observer <- function(input, input_id, title_key, content, i18n) {
  observeEvent(input[[input_id]], {
    showModal(modalDialog(
      title = i18n$t(title_key),
      size = "l",
      easyClose = TRUE,
      content,
      footer = modalButton(i18n$t("common.buttons.close"))
    ))
  })
}
