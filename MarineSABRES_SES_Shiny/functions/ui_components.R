# functions/ui_components.R
# =============================================================================
# Shared UI Component Library for MarineSABRES SES Shiny Application
#
# Provides reusable UI builder functions to reduce code duplication across
# modules. All functions accept an i18n parameter for internationalization.
#
# Depends on: shiny, bs4Dash
# =============================================================================

# =============================================================================
# ANALYSIS BOX
# =============================================================================

#' Create a standard analysis box (bs4Card wrapper)
#'
#' Wraps bs4Card with consistent defaults used across analysis modules.
#' Replaces the repeated pattern of bs4Card() with icon title, status,
#' solidHeader, and width = NULL found in 9+ modules.
#'
#' @param title Character. The box title text (already translated or raw).
#' @param ... UI elements to place inside the card body.
#' @param icon_name Character. FontAwesome icon name (without "fa-" prefix).
#'   NULL to omit the icon. Default "chart-bar".
#' @param status Character. bs4Dash status color. Default "primary".
#' @param solid_header Logical. Use solid-colored header. Default TRUE.
#' @param collapsible Logical. Allow collapsing. Default TRUE.
#' @param collapsed Logical. Start collapsed. Default FALSE.
#' @param width Integer or NULL. Column width (NULL = full width). Default NULL.
#' @param i18n Translator object. If provided and title is a key, will translate.
#'   Pass NULL to use title as-is.
#' @return A bs4Card tag.
#'
#' @examples
#' ses_analysis_box("Settings", icon_name = "cogs", status = "primary",
#'   sliderInput("n", "Top nodes", 5, 20, 10),
#'   actionButton("run", "Calculate", class = "btn-primary btn-block")
#' )
ses_analysis_box <- function(title, ..., icon_name = "chart-bar", status = "primary",
                             solid_header = TRUE, collapsible = TRUE,
                             collapsed = FALSE, width = NULL, i18n = NULL) {
  # Translate title if i18n is provided
  display_title <- if (!is.null(i18n)) i18n$t(title) else title

  # Build title with optional icon

  title_tag <- if (!is.null(icon_name)) {
    tagList(icon(icon_name), " ", display_title)
  } else {
    display_title
  }

  bs4Card(
    title = title_tag,
    status = status,
    solidHeader = solid_header,
    collapsible = collapsible,
    collapsed = collapsed,
    width = width,
    ...
  )
}


# =============================================================================
# EMPTY STATE / NO-DATA PLACEHOLDER
# =============================================================================

#' Create an empty state placeholder
#'
#' Displays a centered message with icon when no data is available.
#' Replaces the repeated div(class = "alert alert-warning/info", ...)
#' pattern found across 10+ modules for "no data" or "run analysis first"
#' states.
#'
#' @param message Character. The message to display (already translated or key).
#' @param subtitle Character or NULL. Optional secondary text below the main
#'   message. Default NULL.
#' @param icon_name Character. FontAwesome icon name. Default "inbox".
#' @param status Character. One of "info", "warning", "success", "danger".
#'   Maps to Bootstrap alert classes. Default "info".
#' @param i18n Translator object. If provided, message and subtitle are
#'   treated as i18n keys. Pass NULL to use as-is.
#' @return A div tag with alert styling.
#'
#' @examples
#' ses_empty_state("modules.analysis.common.no_cld_data_found",
#'   subtitle = "modules.analysis.network.please_generate_a_cld_network_first_using",
#'   icon_name = "exclamation-triangle", status = "warning", i18n = i18n)
ses_empty_state <- function(message, subtitle = NULL, icon_name = "inbox",
                            status = "info", i18n = NULL) {
  display_msg <- if (!is.null(i18n)) i18n$t(message) else message
  display_sub <- if (!is.null(subtitle) && !is.null(i18n)) {
    i18n$t(subtitle)
  } else {
    subtitle
  }

  alert_class <- paste0("alert alert-", status)

  div(
    class = alert_class,
    style = "margin: 20px; padding: 15px;",
    icon(icon_name), " ",
    strong(display_msg),
    if (!is.null(display_sub)) p(display_sub, style = "margin-top: 10px;")
  )
}


# =============================================================================
# ACTION BUTTON ROW
# =============================================================================

#' Create a standard action button row
#'
#' Generates a row of one or two buttons with consistent styling, replacing
#' the repeated pattern of primary actionButton + optional secondary button
#' found in 14+ modules.
#'
#' @param ns Namespace function from the module's session.
#' @param primary_id Character. Input ID for the primary button.
#' @param primary_label Character. Label for the primary button (key or text).
#' @param primary_icon Character. FontAwesome icon name for primary button.
#'   Default "play".
#' @param primary_class Character. CSS class(es) for primary button.
#'   Default "btn-primary btn-lg btn-block".
#' @param secondary_id Character or NULL. Input ID for secondary button.
#'   Default NULL (no secondary button).
#' @param secondary_label Character or NULL. Label for the secondary button.
#' @param secondary_icon Character. Icon for secondary button. Default "undo".
#' @param secondary_class Character. CSS class for secondary button.
#'   Default "btn-default btn-block".
#' @param i18n Translator object. If provided, labels are treated as i18n keys.
#' @return A fluidRow containing the button(s).
#'
#' @examples
#' ses_action_buttons(ns, "run_analysis", "modules.analysis.run",
#'   primary_icon = "calculator",
#'   secondary_id = "reset", secondary_label = "common.buttons.reset",
#'   i18n = i18n)
ses_action_buttons <- function(ns, primary_id, primary_label,
                               primary_icon = "play",
                               primary_class = "btn-primary btn-lg btn-block",
                               secondary_id = NULL, secondary_label = NULL,
                               secondary_icon = "undo",
                               secondary_class = "btn-default btn-block",
                               i18n = NULL) {
  p_label <- if (!is.null(i18n)) i18n$t(primary_label) else primary_label
  s_label <- if (!is.null(secondary_label) && !is.null(i18n)) {
    i18n$t(secondary_label)
  } else {
    secondary_label
  }

  has_secondary <- !is.null(secondary_id) && !is.null(s_label)
  primary_width <- if (has_secondary) 8 else 12

  fluidRow(
    column(primary_width,
      actionButton(ns(primary_id), p_label,
                   icon = icon(primary_icon),
                   class = primary_class)
    ),
    if (has_secondary) {
      column(4,
        actionButton(ns(secondary_id), s_label,
                     icon = icon(secondary_icon),
                     class = secondary_class)
      )
    }
  )
}


# =============================================================================
# STATUS BADGE
# =============================================================================

#' Create a data status badge
#'
#' Generates a small inline badge indicating the state of data or analysis.
#' Useful for prerequisite checks and analysis status displays found in
#' prepare_report_module.R, analysis modules, and scenario_builder_module.R.
#'
#' @param status Character. One of "ready", "stale", "empty", "error",
#'   "running". Default "empty".
#' @param label Character or NULL. Custom label text. If NULL, uses a default
#'   label for the status. Default NULL.
#' @param i18n Translator object. If provided and label is a key, will translate.
#'   Default labels are translated if i18n is provided.
#' @return A span tag with badge styling.
#'
#' @examples
#' ses_status_badge("ready", i18n = i18n)
#' ses_status_badge("error", label = "modules.analysis.failed", i18n = i18n)
ses_status_badge <- function(status = c("ready", "stale", "empty", "error", "running"),
                             label = NULL, i18n = NULL) {
  status <- match.arg(status)

  # Default labels and their i18n keys
  defaults <- list(
    ready   = list(icon = "check-circle",   color = "success", key = "Ready"),
    stale   = list(icon = "exclamation-triangle", color = "warning", key = "Stale"),
    empty   = list(icon = "minus-circle",   color = "secondary", key = "No data"),
    error   = list(icon = "times-circle",   color = "danger",  key = "Error"),
    running = list(icon = "spinner",        color = "info",    key = "Running...")
  )

  cfg <- defaults[[status]]

  display_label <- if (!is.null(label)) {
    if (!is.null(i18n)) i18n$t(label) else label
  } else {
    cfg$key
  }

  badge_class <- paste0("badge badge-", cfg$color)
  icon_tag <- if (status == "running") {
    icon(cfg$icon, class = "fa-spin")
  } else {
    icon(cfg$icon)
  }

  tags$span(
    class = badge_class,
    style = "font-size: 0.85em; padding: 5px 10px;",
    icon_tag, " ", display_label
  )
}


# =============================================================================
# INFO CALLOUT
# =============================================================================

#' Create an info callout box with accent border
#'
#' Generates a styled div with background color and left border accent, replacing
#' the repeated inline-style div pattern (background, padding, border-radius,
#' border-left) used in analysis_leverage.R, entry_point_module.R,
#' template_ses_module.R, and others.
#'
#' @param ... UI elements (text, icons, lists) to place inside the callout.
#' @param status Character. One of "info", "warning", "success", "danger".
#'   Determines the color scheme. Default "info".
#' @return A styled div tag.
#'
#' @examples
#' ses_info_callout(
#'   h5(icon("info-circle"), " ", i18n$t("About leverage points")),
#'   p(i18n$t("Leverage points are...")),
#'   status = "info"
#' )
ses_info_callout <- function(..., status = "info") {
  # Color mappings matching the project's existing inline styles
  colors <- list(
    info    = list(bg = "#e8f4f8", border = "#17a2b8"),
    warning = list(bg = "#fff3cd", border = "#ffc107"),
    success = list(bg = "#d4edda", border = "#28a745"),
    danger  = list(bg = "#f8d7da", border = "#dc3545")
  )

  cfg <- colors[[status]] %||% colors[["info"]]

  div(
    style = paste0(
      "background: ", cfg$bg, "; ",
      "padding: 12px; ",
      "border-radius: 5px; ",
      "border-left: 4px solid ", cfg$border, "; ",
      "margin-bottom: 15px;"
    ),
    ...
  )
}


# =============================================================================
# WELL PANEL WITH HEADER
# =============================================================================

#' Create a wellPanel with a title and optional description
#'
#' Wraps the common pattern of wellPanel(h5(...), p(class = "text-muted", ...),
#' <content>) found 77 times across 12 modules. Provides a consistent
#' section container with header.
#'
#' @param title Character. Section title (key or text).
#' @param ... UI elements for the panel body.
#' @param subtitle Character or NULL. Muted description below the title.
#' @param icon_name Character or NULL. FontAwesome icon for the title.
#'   Default NULL.
#' @param i18n Translator object. If provided, title and subtitle are treated
#'   as i18n keys.
#' @return A wellPanel tag.
#'
#' @examples
#' ses_well_section("modules.analysis.loops.type_distribution",
#'   plotOutput(ns("loop_type_plot"), height = "300px"),
#'   icon_name = "chart-pie", i18n = i18n)
ses_well_section <- function(title, ..., subtitle = NULL, icon_name = NULL,
                             i18n = NULL) {
  display_title <- if (!is.null(i18n)) i18n$t(title) else title
  display_sub <- if (!is.null(subtitle) && !is.null(i18n)) {
    i18n$t(subtitle)
  } else {
    subtitle
  }

  title_content <- if (!is.null(icon_name)) {
    h5(icon(icon_name), " ", display_title)
  } else {
    h5(display_title)
  }

  wellPanel(
    title_content,
    if (!is.null(display_sub)) p(class = "text-muted", display_sub),
    ...
  )
}


# =============================================================================
# DOWNLOAD BUTTON ROW
# =============================================================================

#' Create a row of download buttons
#'
#' Generates evenly-spaced download buttons for export tabs, replacing
#' the repeated fluidRow(column(4, downloadButton(...)), ...) pattern
#' in analysis_loops.R, analysis_bot.R, export_reports_module.R, etc.
#'
#' @param ns Namespace function from the module's session.
#' @param buttons A named list where each element is a list with:
#'   \itemize{
#'     \item \code{id}: Character. The download button output ID.
#'     \item \code{label}: Character. Button label (key or text).
#'     \item \code{class}: Character. CSS class. Default "btn-success btn-block".
#'     \item \code{icon_name}: Character or NULL. Optional icon.
#'   }
#' @param i18n Translator object. If provided, labels are i18n keys.
#' @return A fluidRow containing evenly-spaced download buttons.
#'
#' @examples
#' ses_download_buttons(ns, list(
#'   list(id = "download_excel", label = "Download Excel", class = "btn-success btn-block"),
#'   list(id = "download_pdf",   label = "Download PDF",   class = "btn-info btn-block"),
#'   list(id = "download_zip",   label = "Download ZIP",   class = "btn-warning btn-block")
#' ), i18n = i18n)
ses_download_buttons <- function(ns, buttons, i18n = NULL) {
  n <- length(buttons)
  col_width <- floor(12 / n)

  cols <- lapply(buttons, function(btn) {
    btn_label <- if (!is.null(i18n)) i18n$t(btn$label) else btn$label
    btn_class <- btn$class %||% "btn-success btn-block"

    column(col_width,
      downloadButton(ns(btn$id), btn_label, class = btn_class)
    )
  })

  do.call(fluidRow, cols)
}


# =============================================================================
# ML PREDICTION FEEDBACK BUTTONS
# =============================================================================

#' Create inline thumbs up/down buttons for ML prediction feedback
#'
#' Generates a small button pair that allows users to flag ML predictions
#' as correct or incorrect. Used alongside ML-suggested connections and
#' classifications in the graphical SES creator.
#'
#' @param ns Namespace function from the module's session.
#' @param prediction_id Character. A unique identifier for this prediction,
#'   used to distinguish feedback events when multiple suggestions are visible.
#' @param i18n Translator object. If provided, tooltips are translated.
#'   Default NULL.
#' @return A span tag containing two small icon buttons (thumbs-up, thumbs-down).
#'
#' @examples
#' ses_ml_feedback_buttons(ns, prediction_id = "ghost_1", i18n = i18n)
ses_ml_feedback_buttons <- function(ns, prediction_id, i18n = NULL) {
  thumbs_up_title <- if (!is.null(i18n)) {
    i18n$t("modules.graphical_ses_creator.feedback_correct")
  } else {
    "Correct prediction"
  }
  thumbs_down_title <- if (!is.null(i18n)) {
    i18n$t("modules.graphical_ses_creator.feedback_incorrect")
  } else {
    "Incorrect prediction"
  }

  tags$span(
    class = "ml-feedback-buttons",
    style = "display: inline-flex; gap: 4px; margin-left: 6px; vertical-align: middle;",
    tags$button(
      type = "button",
      class = "btn btn-xs btn-outline-success ml-feedback-btn",
      style = "padding: 1px 5px; font-size: 11px; line-height: 1.2; border-radius: 3px;",
      title = thumbs_up_title,
      onclick = sprintf(
        "Shiny.setInputValue('%s', {id: '%s', vote: 'up', nonce: Math.random()});",
        ns("ml_feedback"), prediction_id
      ),
      icon("thumbs-up")
    ),
    tags$button(
      type = "button",
      class = "btn btn-xs btn-outline-danger ml-feedback-btn",
      style = "padding: 1px 5px; font-size: 11px; line-height: 1.2; border-radius: 3px;",
      title = thumbs_down_title,
      onclick = sprintf(
        "Shiny.setInputValue('%s', {id: '%s', vote: 'down', nonce: Math.random()});",
        ns("ml_feedback"), prediction_id
      ),
      icon("thumbs-down")
    )
  )
}


# =============================================================================
# STALE DATA OBSERVER
# =============================================================================

#' Set up a stale-data notification observer for event bus
#'
#' Creates the common observer pattern that listens for ISA changes via
#' event_bus and shows a "data changed, re-run" warning notification.
#' This exact pattern is duplicated in analysis_loops.R, analysis_metrics.R,
#' analysis_boolean.R, analysis_intervention.R, analysis_leverage.R, and
#' analysis_simulation.R.
#'
#' @param event_bus The event bus object (or NULL if not available).
#' @param has_results_fn A function (no arguments) that returns TRUE/FALSE
#'   indicating whether the module has computed results that would be stale.
#'   Will be called inside isolate().
#' @param ns Namespace function for creating a unique notification ID.
#' @param i18n Translator object for the notification message.
#' @return An observe() handle (invisible). Call in module server scope.
#'
#' @examples
#' # In a module server:
#' setup_stale_data_observer(event_bus,
#'   has_results_fn = function() !is.null(rv$results),
#'   ns = session$ns, i18n = i18n)
setup_stale_data_observer <- function(event_bus, has_results_fn, ns, i18n) {
  observe({
    req(!is.null(event_bus))
    event_bus$on_isa_change()
    if (isolate(has_results_fn())) {
      showNotification(
        i18n$t("modules.analysis.common.data_changed_rerun"),
        type = "warning",
        duration = 5,
        id = ns("stale_data")
      )
    }
  })
}
