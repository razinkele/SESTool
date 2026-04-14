# =============================================================================
# MODULE: [Module Name]
# File: modules/[filename].R
# =============================================================================
#
# Purpose:
#   [Brief description of what this module does]
#
# Dependencies:
#   - [List required packages/modules]
#
# Exports:
#   - template_example_ui(id, i18n)   - Module UI function
#   - template_example_server(id, ...) - Module server function
#
# =============================================================================

# =============================================================================
# UI FUNCTION
# =============================================================================

#' [Module Name] UI
#'
#' @description
#' [Longer description of the UI component]
#'
#' @param id Character. Module namespace ID
#' @param i18n Translator object for internationalization (shiny.i18n)
#'
#' @return A Shiny UI element
#'
#' @details
#' Key features:
#' \itemize{
#'   \item [Feature 1]
#'   \item [Feature 2]
#' }
#'
#' @examples
#' \dontrun{
#' ui <- fluidPage(template_example_ui("my_module", i18n))
#' }
#'
#' @export
template_example_ui <- function(id, i18n) {
  # REQUIRED: Enable reactive translations
  tryCatch(shiny.i18n::usei18n(i18n$translator %||% i18n), error = function(e) NULL)
  ns <- NS(id)

  # UI implementation
  fluidPage(
    # ...
  )
}

# =============================================================================
# SERVER FUNCTION
# =============================================================================

#' [Module Name] Server
#'
#' @description
#' [Longer description of the server logic]
#'
#' @param id Character. Module namespace ID (must match UI id)
#' @param project_data_reactive Reactive containing project data (reactiveVal or reactive)
#' @param i18n Translator object for internationalization
#' @param event_bus Optional EventBus for cross-module communication
#' @param ... Additional parameters
#'
#' @return A list of reactive values or NULL (side effects only)
#'
#' @details
#' This module:
#' \itemize{
#'   \item [Behavior 1]
#'   \item [Behavior 2]
#' }
#'
#' Events emitted (if event_bus provided):
#' \itemize{
#'   \item \code{[event_name]}: [When and what data]
#' }
#'
#' @export
template_example_server <- function(id, project_data_reactive, i18n, event_bus = NULL, ...) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # ---------------------------------------------------------------------------
    # Reactive Values
    # ---------------------------------------------------------------------------
    rv <- reactiveValues(
      # state variables here
    )

    # ---------------------------------------------------------------------------
    # Observers
    # ---------------------------------------------------------------------------

    # ---------------------------------------------------------------------------
    # Outputs
    # ---------------------------------------------------------------------------

    # ---------------------------------------------------------------------------
    # Return Values (optional)
    # ---------------------------------------------------------------------------
    return(NULL)  # or return(list(...))
  })
}
