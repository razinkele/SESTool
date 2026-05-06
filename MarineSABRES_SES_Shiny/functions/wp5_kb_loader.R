# functions/wp5_kb_loader.R
# WP5 Mechanism Knowledge Base Loader
# Purpose: Loads the JSON-based WP5 financial-mechanism KB and provides
#   lookup functions for the reference pane on Response/Measure ISA elements
#   (and, in later phases, the valuation calculator and impact-assessment
#   linked-mechanisms UI).
#
# Author: MarineSABRES SES Toolbox
# Date: 2026-05-06
# Dependencies: jsonlite (already loaded in global.R)

# ==============================================================================
# MODULE-LEVEL STATE
# ==============================================================================

.wp5_kb_env <- new.env(parent = emptyenv())
.wp5_kb_env$db <- NULL
.wp5_kb_env$loaded <- FALSE

# ==============================================================================
# DATABASE LOADING
# ==============================================================================

#' Load the WP5 Mechanism Knowledge Base from JSON
#'
#' @param db_path Path to the JSON database file (default: data/ses_knowledge_db_wp5_mechanisms.json)
#' @param force_reload If TRUE, reload even if already cached
#' @return The parsed database list, invisibly
#' @export
load_wp5_mechanisms_kb <- function(db_path = NULL, force_reload = FALSE) {
  if (.wp5_kb_env$loaded && !force_reload) {
    return(invisible(.wp5_kb_env$db))
  }

  if (is.null(db_path)) {
    if (exists("get_project_file", mode = "function")) {
      db_path <- get_project_file("data", "ses_knowledge_db_wp5_mechanisms.json")
    } else {
      db_path <- file.path("data", "ses_knowledge_db_wp5_mechanisms.json")
    }
  }

  if (!file.exists(db_path)) {
    warning(sprintf("[WP5 KB] Mechanism KB not found at: %s", db_path))
    .wp5_kb_env$db <- NULL
    .wp5_kb_env$loaded <- FALSE
    return(invisible(NULL))
  }

  tryCatch({
    raw <- jsonlite::fromJSON(db_path, simplifyDataFrame = FALSE)
    .wp5_kb_env$db <- raw
    .wp5_kb_env$loaded <- TRUE

    n_das <- length(raw$demonstration_areas %||% list())
    n_mechs <- sum(vapply(
      raw$demonstration_areas %||% list(),
      function(da) length(da$mechanisms %||% list()),
      integer(1)
    ))
    if (exists("debug_log", mode = "function")) {
      debug_log(sprintf("WP5 KB loaded: v%s, %d DAs, %d mechanisms",
                        raw$version %||% "unknown", n_das, n_mechs), "WP5 KB")
    }
    message(sprintf("[WP5 KB] Loaded mechanism KB v%s with %d DAs and %d mechanisms",
                    raw$version %||% "unknown", n_das, n_mechs))

    invisible(raw)
  }, error = function(e) {
    warning(sprintf("[WP5 KB] Failed to load mechanism KB: %s", e$message))
    .wp5_kb_env$db <- NULL
    .wp5_kb_env$loaded <- FALSE
    invisible(NULL)
  })
}

# ==============================================================================
# LOOKUP HELPERS
# ==============================================================================

#' Check whether the WP5 KB has been successfully loaded
#' @return Logical
#' @export
wp5_kb_available <- function() {
  isTRUE(.wp5_kb_env$loaded) && !is.null(.wp5_kb_env$db)
}

#' Return all mechanisms for a given Demonstration Area
#'
#' @param da Character. One of the values in `WP5_DA_CONTEXTS`
#' @return List of mechanism entries (possibly empty); errors on unknown DA
#' @export
get_mechanisms_for_da <- function(da) {
  valid <- if (exists("WP5_DA_CONTEXTS")) WP5_DA_CONTEXTS else c("macaronesia","tuscan","arctic")
  if (!da %in% valid) {
    stop(sprintf("Unknown DA '%s'; expected one of: %s",
                 da, paste(valid, collapse = ", ")))
  }
  if (!wp5_kb_available()) {
    warning("[WP5 KB] KB not loaded; call load_wp5_mechanisms_kb() first")
    return(list())
  }
  da_block <- .wp5_kb_env$db$demonstration_areas[[da]]
  if (is.null(da_block)) return(list())
  da_block$mechanisms %||% list()
}

#' Return a single mechanism by its `id` field
#'
#' @param id Character mechanism ID (e.g., "mac_01_blue_corridor_facility")
#' @return Mechanism entry list, or NULL if not found
#' @export
get_mechanism_by_id <- function(id) {
  if (!wp5_kb_available()) return(NULL)
  for (da_name in names(.wp5_kb_env$db$demonstration_areas)) {
    mechs <- .wp5_kb_env$db$demonstration_areas[[da_name]]$mechanisms %||% list()
    for (m in mechs) {
      if (!is.null(m$id) && identical(m$id, id)) return(m)
    }
  }
  NULL
}

#' Return the bundled valuation unit values for a given habitat
#'
#' @param habitat Character habitat key (e.g., "posidonia_oceanica")
#' @return Named list of services with low/central/high/unit/method, or NULL
#' @export
get_valuation_unit_values <- function(habitat) {
  if (!wp5_kb_available()) return(NULL)
  .wp5_kb_env$db$valuation_unit_values[[habitat]]
}

# Auto-load on source if data file present (mirrors ses_knowledge_db_loader.R)
if (file.exists("data/ses_knowledge_db_wp5_mechanisms.json")) {
  load_wp5_mechanisms_kb()
}
