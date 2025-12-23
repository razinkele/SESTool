# Helpers for static analysis / linters (shiny imports & globalVariables)
#
# This file intentionally references shiny functions via `::` inside an `if (FALSE)` block
# so that static analysis tools (lintr / R CMD check / static checks) can find their source
# without affecting runtime behaviour.

# Declare commonly used globals to silence 'no visible binding for global variable' notes
if (getRversion() >= "2.15.1") {
  utils::globalVariables(
    c(
      "i18n", "input", "output", "session", "project_data",
      "user_level", "autosave_enabled", "event_bus", "template_path",
      "template", "save_project", "load_project", "confirm_save",
      "trigger_bookmark", "sidebar_menu",
      # Visual / grouping constants
      "GROUP_COLORS", "DEFAULT_GROUP_COLOR", "GROUP_SHAPES", "DEFAULT_GROUP_SHAPE",
      # Edge constants
      "EDGE_WEIGHT_MIN", "EDGE_WEIGHT_MAX", "EDGE_STRENGTH_MIN", "EDGE_STRENGTH_MAX",
      "EDGE_CONFIDENCE_MIN", "EDGE_CONFIDENCE_MAX",
      # Marine constants
      "MARINE_WEIGHT_MIN", "MARINE_WEIGHT_MAX", "MARINE_STRENGTH_MIN", "MARINE_STRENGTH_MAX",
      # Misc
      "DEFAULT_RANDOM_SEED", "MARINE_SES_CATEGORIES", "AVAILABLE_LANGUAGES"
    )
  )
}

# Reference Shiny functions by namespace so static checkers know exactly where they come from.
# These are not executed at runtime.
if (FALSE) {
  shiny::observe(NULL)
  shiny::observeEvent(NULL, NULL)
  shiny::isolate(NULL)
  shiny::setBookmarkExclude(NULL)
  shiny::reactiveVal()
  shiny::onBookmark(function(...) NULL)
  shiny::onBookmarked(function(...) NULL)
  shiny::onRestore(function(...) NULL)
  shiny::showModal(shiny::modalDialog())
  shiny::modalDialog()
  shiny::modalButton()
  shiny::showNotification("x")
  shiny::updateTabItems(NULL, NULL)
  shiny::parseQueryString("x")
  shiny::HTML("x")
  shiny::icon("bookmark")
  invisible(shiny::tags)

  # igraph functions used across utils.R and network code
  igraph::ecount(NULL)
  igraph::vcount(NULL)
  igraph::E(NULL)
  igraph::V(NULL)
  igraph::edge_attr_names(NULL)
  igraph::is_directed(NULL)
}
