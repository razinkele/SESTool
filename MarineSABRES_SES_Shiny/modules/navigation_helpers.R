# navigation_helpers.R
# Reusable navigation components for MarineSABRES DSS
# Created: 2025-11-08

# ============================================================================
# BREADCRUMB NAVIGATION
# ============================================================================

#' Create breadcrumb navigation
#'
#' @param items List of breadcrumb items, each with 'label', 'icon' (optional), and 'link' (optional)
#' @param i18n Translator object
#' @return HTML breadcrumb element
#' @examples
#' create_breadcrumb(list(
#'   list(label = "Home", icon = "home", link = "#"),
#'   list(label = "Create SES", icon = "layer-group"),
#'   list(label = "AI Assistant")
#' ), i18n)
create_breadcrumb <- function(items, i18n = NULL) {

  breadcrumb_items <- lapply(seq_along(items), function(i) {
    item <- items[[i]]
    is_last <- i == length(items)

    # Translate label if i18n is provided
    label <- if (!is.null(i18n)) i18n$t(item$label) else item$label

    # Create icon if provided
    icon_el <- if (!is.null(item$icon)) {
      icon(item$icon)
    } else {
      NULL
    }

    # Create link or plain text
    content <- if (!is.null(item$link) && !is_last) {
      tags$a(href = item$link, icon_el, label)
    } else {
      tagList(icon_el, label)
    }

    # Apply active class to last item
    class_name <- if (is_last) "breadcrumb-item active" else "breadcrumb-item"

    tags$li(class = class_name, content)
  })

  div(class = "breadcrumb-container",
    tags$nav(`aria-label` = "breadcrumb",
      tags$ol(class = "breadcrumb", breadcrumb_items)
    )
  )
}

# ============================================================================
# PROGRESS BAR
# ============================================================================

#' Create progress bar component
#'
#' @param current Current step number
#' @param total Total number of steps
#' @param title Progress title (optional)
#' @param i18n Translator object
#' @return HTML progress bar element
create_progress_bar <- function(current, total, title = NULL, i18n = NULL) {

  # Calculate percentage
  percentage <- round((current / total) * 100)

  # Determine progress level for styling
  progress_class <- if (percentage < 30) {
    "low"
  } else if (percentage < 70) {
    "medium"
  } else if (percentage < 100) {
    "high"
  } else {
    "complete"
  }

  # Default title
  if (is.null(title)) {
    title <- if (!is.null(i18n)) {
      i18n$t("common.misc.progress")
    } else {
      "Progress"
    }
  } else if (!is.null(i18n)) {
    title <- i18n$t(title)
  }

  # Stats text
  stats_text <- if (!is.null(i18n)) {
    sprintf(i18n$t("common.misc.step_d_of_d"), current, total)
  } else {
    sprintf("Step %d of %d", current, total)
  }

  div(class = "progress-container",
    div(class = "progress-header",
      span(class = "progress-title", title),
      span(class = "progress-stats", stats_text)
    ),
    div(class = "progress-bar-wrapper",
      div(
        class = paste("progress-bar-fill", progress_class),
        style = sprintf("width: %d%%;", percentage),
        sprintf("%d%%", percentage)
      )
    )
  )
}

# ============================================================================
# NAVIGATION BUTTONS
# ============================================================================

#' Create navigation buttons (Back, Next, Skip)
#'
#' @param ns Namespace function from module
#' @param show_back Show back button (default: TRUE)
#' @param show_next Show next button (default: TRUE)
#' @param show_skip Show skip button (default: FALSE)
#' @param back_enabled Enable back button (default: TRUE)
#' @param next_enabled Enable next button (default: TRUE)
#' @param next_label Custom label for next button (optional)
#' @param i18n Translator object
#' @return HTML navigation buttons element
create_nav_buttons <- function(ns,
                                show_back = TRUE,
                                show_next = TRUE,
                                show_skip = FALSE,
                                back_enabled = TRUE,
                                next_enabled = TRUE,
                                next_label = NULL,
                                i18n = NULL) {

  # Translate labels
  back_text <- if (!is.null(i18n)) i18n$t("common.buttons.back") else "Back"
  skip_text <- if (!is.null(i18n)) i18n$t("common.buttons.skip") else "Skip"

  if (is.null(next_label)) {
    next_text <- if (!is.null(i18n)) i18n$t("common.buttons.next") else "Next"
  } else {
    next_text <- if (!is.null(i18n)) i18n$t(next_label) else next_label
  }

  # Create buttons
  back_btn <- if (show_back) {
    actionButton(
      ns("nav_back"),
      tagList(icon("arrow-left"), " ", back_text),
      class = "btn btn-nav-back",
      disabled = if (!back_enabled) NA else NULL
    )
  } else {
    span()  # Empty placeholder
  }

  skip_btn <- if (show_skip) {
    actionButton(
      ns("nav_skip"),
      skip_text,
      class = "btn btn-nav-skip"
    )
  } else {
    NULL
  }

  next_btn <- if (show_next) {
    actionButton(
      ns("nav_next"),
      tagList(next_text, " ", icon("arrow-right")),
      class = "btn btn-nav-next",
      disabled = if (!next_enabled) NA else NULL
    )
  } else {
    span()  # Empty placeholder
  }

  div(class = "navigation-buttons",
    div(back_btn),
    div(skip_btn),
    div(next_btn)
  )
}

# ============================================================================
# STEP INDICATOR
# ============================================================================

#' Create step indicator badge
#'
#' @param current Current step number
#' @param total Total number of steps
#' @param i18n Translator object
#' @return HTML step indicator element
create_step_indicator <- function(current, total, i18n = NULL) {

  text <- if (!is.null(i18n)) {
    sprintf(i18n$t("common.misc.step_d_of_d"), current, total)
  } else {
    sprintf("Step %d of %d", current, total)
  }

  span(class = "step-indicator",
    icon("tasks"),
    text
  )
}

# ============================================================================
# RECOMMENDED ENTRY HIGHLIGHT
# ============================================================================

#' Add "recommended" styling to a UI element
#'
#' @param content UI content to wrap
#' @param i18n Translator object
#' @return HTML element with recommended styling
mark_as_recommended <- function(content, i18n = NULL) {

  div(class = "recommended-entry",
    content
  )
}

# ============================================================================
# START HERE BADGE
# ============================================================================

#' Add "Start Here" badge to a UI element
#'
#' @param content UI content to wrap
#' @param i18n Translator object
#' @return HTML element with start here badge
add_start_here_badge <- function(content, i18n = NULL) {

  badge_text <- if (!is.null(i18n)) {
    i18n$t("modules.entry_point.start_here")
  } else {
    "START HERE"
  }

  div(class = "start-here-highlight",
    span(class = "start-here-badge", badge_text),
    content
  )
}
