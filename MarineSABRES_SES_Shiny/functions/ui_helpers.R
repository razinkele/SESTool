# functions/ui_helpers.R
# UI Helper Functions for MarineSABRES SES Shiny Application
# Reduces code duplication across modules

# ============================================================================
# MODULE HEADER CREATION
# ============================================================================

#' Create standardized module header with title, description, and help button
#'
#' @param ns Namespace function from the module
#' @param title Module title (string)
#' @param description Module description (string)
#' @param help_id ID for the help button (default: "help_main")
#' @param help_label Label for help button (default: "Help")
#' @param help_icon Icon for help button (default: "question-circle")
#' @return A fluidRow containing the formatted header
#'
#' @examples
#' create_module_header(ns, "PIMS Module", "Project Information Management")
create_module_header <- function(ns, title, description,
                                 help_id = "help_main",
                                 help_label = "Help",
                                 help_icon = "question-circle") {
  fluidRow(
    column(12,
      div(
        style = "display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px;",
        div(
          h3(title, style = "margin-top: 0;"),
          p(class = "text-muted", description)
        ),
        div(
          style = "margin-top: 10px;",
          actionButton(
            ns(help_id),
            help_label,
            icon = icon(help_icon),
            class = "btn btn-info btn-lg"
          )
        )
      )
    )
  )
}

# ============================================================================
# COMMON BUTTON CREATION
# ============================================================================

#' Create standardized save button
#'
#' @param ns Namespace function
#' @param id Button ID
#' @param label Button label (default: "Save")
#' @param icon_name Icon name (default: "save")
#' @param class Button CSS class (default: "btn-primary")
#' @return An actionButton
create_save_button <- function(ns, id, label = "Save",
                               icon_name = "save",
                               class = "btn-primary") {
  actionButton(
    ns(id),
    label,
    icon = icon(icon_name),
    class = class
  )
}

#' Create standardized cancel button
#'
#' @param ns Namespace function
#' @param id Button ID
#' @param label Button label (default: "Cancel")
#' @return An actionButton
create_cancel_button <- function(ns, id, label = "Cancel") {
  actionButton(
    ns(id),
    label,
    icon = icon("times"),
    class = "btn-default"
  )
}

#' Create standardized next button
#'
#' @param ns Namespace function
#' @param id Button ID
#' @param label Button label (default: "Next")
#' @return An actionButton
create_next_button <- function(ns, id, label = "Next") {
  actionButton(
    ns(id),
    label,
    icon = icon("arrow-right"),
    class = "btn-primary"
  )
}

#' Create standardized back button
#'
#' @param ns Namespace function
#' @param id Button ID
#' @param label Button label (default: "Back")
#' @return An actionButton
create_back_button <- function(ns, id, label = "Back") {
  actionButton(
    ns(id),
    label,
    icon = icon("arrow-left"),
    class = "btn-default"
  )
}

# ============================================================================
# INFO BOX CREATION
# ============================================================================

#' Create standardized info box with icon and message
#'
#' @param message Message text
#' @param type Type of alert: "info", "success", "warning", "danger"
#' @param icon_name Icon name (auto-selected based on type if NULL)
#' @return A div containing the formatted alert
create_info_box <- function(message, type = "info", icon_name = NULL) {
  # Auto-select icon based on type
  if (is.null(icon_name)) {
    icon_name <- switch(type,
      "info" = "info-circle",
      "success" = "check-circle",
      "warning" = "exclamation-triangle",
      "danger" = "times-circle",
      "info-circle"
    )
  }

  div(
    class = paste("alert alert", type, sep = "-"),
    icon(icon_name),
    " ",
    message
  )
}

# ============================================================================
# FORM HELPERS
# ============================================================================

#' Create a labeled text input with consistent styling
#'
#' @param ns Namespace function
#' @param id Input ID
#' @param label Input label
#' @param placeholder Placeholder text
#' @param value Initial value
#' @return A textInput with label
create_labeled_input <- function(ns, id, label, placeholder = "",
                                 value = "") {
  textInput(
    ns(id),
    tags$strong(label),
    placeholder = placeholder,
    value = value,
    width = "100%"
  )
}

#' Create a labeled text area with consistent styling
#'
#' @param ns Namespace function
#' @param id Input ID
#' @param label Input label
#' @param placeholder Placeholder text
#' @param rows Number of rows
#' @return A textAreaInput with label
create_labeled_textarea <- function(ns, id, label, placeholder = "",
                                    rows = 3) {
  textAreaInput(
    ns(id),
    tags$strong(label),
    placeholder = placeholder,
    rows = rows,
    width = "100%"
  )
}

# ============================================================================
# PROGRESS INDICATOR
# ============================================================================

#' Create a step progress indicator
#'
#' @param current_step Current step number
#' @param total_steps Total number of steps
#' @param step_labels Vector of step labels
#' @return A div containing the progress indicator
create_step_progress <- function(current_step, total_steps, step_labels = NULL) {
  if (is.null(step_labels)) {
    step_labels <- paste("Step", 1:total_steps)
  }

  tags$div(
    class = "step-progress",
    style = "margin: 20px 0;",
    lapply(1:total_steps, function(i) {
      step_class <- if (i < current_step) {
        "step-complete"
      } else if (i == current_step) {
        "step-active"
      } else {
        "step-pending"
      }

      tags$div(
        class = paste("step", step_class),
        style = "display: inline-block; margin-right: 10px; padding: 8px 15px; border-radius: 4px;",
        tags$span(
          class = "step-number",
          style = "font-weight: bold; margin-right: 5px;",
          i
        ),
        tags$span(class = "step-label", step_labels[i])
      )
    })
  )
}

# ============================================================================
# DATA TABLE HELPERS
# ============================================================================

#' Create a standardized DataTable with common options
#'
#' @param data Data frame to display
#' @param page_length Number of rows per page (default: 10)
#' @param dom DOM layout (default: "Bfrtip")
#' @param buttons Export buttons to include
#' @return A datatable object
create_standard_datatable <- function(data, page_length = 10,
                                     dom = "Bfrtip",
                                     buttons = c('copy', 'csv', 'excel')) {
  if (is.null(data) || nrow(data) == 0) {
    return(datatable(
      data.frame(Message = "No data available"),
      options = list(dom = 't', ordering = FALSE)
    ))
  }

  datatable(
    data,
    extensions = 'Buttons',
    options = list(
      pageLength = page_length,
      dom = dom,
      buttons = buttons,
      scrollX = TRUE,
      autoWidth = TRUE
    ),
    rownames = FALSE
  )
}

# ============================================================================
# SECTION DIVIDERS
# ============================================================================

#' Create a section divider with optional title
#'
#' @param title Optional section title
#' @return An hr element with optional title
create_section_divider <- function(title = NULL) {
  if (is.null(title)) {
    return(hr())
  }

  tagList(
    hr(),
    h4(title, style = "margin-top: 20px; margin-bottom: 15px;"),
    hr()
  )
}

# ============================================================================
# LOADING SPINNER
# ============================================================================

#' Create a loading spinner overlay
#'
#' @param message Loading message
#' @return A div containing the loading spinner
create_loading_spinner <- function(message = "Loading...") {
  div(
    style = "text-align: center; padding: 40px;",
    icon("spinner", class = "fa-spin fa-3x"),
    br(), br(),
    h4(message)
  )
}

# ============================================================================
# COLLAPSIBLE PANEL
# ============================================================================

#' Create a collapsible panel (accordion)
#'
#' @param ns Namespace function
#' @param id Panel ID
#' @param title Panel title
#' @param content Panel content (tagList or UI element)
#' @param collapsed Start collapsed (default: FALSE)
#' @return A bsCollapse panel
create_collapsible_panel <- function(ns, id, title, content,
                                     collapsed = FALSE) {
  bsCollapse(
    id = ns(id),
    open = if (!collapsed) paste0("panel_", id) else NULL,
    bsCollapsePanel(
      title,
      content,
      value = paste0("panel_", id)
    )
  )
}

# ============================================================================
# TOOLTIP WRAPPER
# ============================================================================

#' Wrap an element with a tooltip
#'
#' @param element UI element to wrap
#' @param tooltip Tooltip text
#' @param placement Tooltip placement ("top", "bottom", "left", "right")
#' @return The wrapped element with tooltip
add_tooltip <- function(element, tooltip, placement = "top") {
  element$attribs$`data-toggle` <- "tooltip"
  element$attribs$`data-placement` <- placement
  element$attribs$title <- tooltip
  element
}

# ============================================================================
# VALIDATION MESSAGE
# ============================================================================

#' Create a validation error/warning message
#'
#' @param errors Vector of error messages
#' @param type Type: "error" or "warning"
#' @return A div containing the validation messages
create_validation_message <- function(errors, type = "error") {
  if (length(errors) == 0) {
    return(NULL)
  }

  alert_type <- if (type == "error") "danger" else "warning"
  icon_name <- if (type == "error") "times-circle" else "exclamation-triangle"

  div(
    class = paste("alert alert", alert_type, sep = "-"),
    icon(icon_name),
    tags$strong(
      if (type == "error") " Validation Errors:" else " Warnings:"
    ),
    tags$ul(
      lapply(errors, function(err) tags$li(err))
    )
  )
}
