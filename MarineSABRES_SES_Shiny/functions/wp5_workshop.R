# functions/wp5_workshop.R
# =============================================================================
# WP5 WS-10 (spec 2026-10-18): workshop elicitation on Response-register
# measures — D5.2 ranking poll + D5.2 Annex 4 11-tenet rating. Storage in
# data$data$pims$workshops, summaries, write-back proposal with apply/undo
# records, import/template/export. Pure functions; the module is a thin shell.
# Import label matching reuses functions/wp5_readiness.R (.ready_key,
# readiness_value_map, readiness_translations, readiness_read_file).
# =============================================================================

.wp5_ws_env <- new.env(parent = emptyenv())

#' D5.2 Annex 4 guiding questions, or NULL. Only default-path loads are cached.
load_wp5_tenet_questions <- function(path = NULL, force_reload = FALSE) {
  default <- is.null(path)
  if (default && !force_reload && !is.null(.wp5_ws_env$questions)) return(.wp5_ws_env$questions)
  if (default) {
    path <- if (exists("get_project_file", mode = "function")) get_project_file("data", "wp5_tenet_guiding_questions.json")
            else file.path("data", "wp5_tenet_guiding_questions.json")
  }
  qs <- if (file.exists(path)) tryCatch(jsonlite::fromJSON(path, simplifyVector = FALSE), error = function(e) NULL) else NULL
  if (is.null(qs) && exists("debug_log", mode = "function")) debug_log(sprintf("WP5 workshop: could not load %s", path), "WP5")
  if (default) .wp5_ws_env$questions <- qs
  qs
}

#' English guiding question for one tenet ("" when unknown)
wp5_tenet_question <- function(qs, tenet) {
  q <- Find(function(x) identical(x$tenet, tenet), qs$questions %||% list())
  if (is.null(q)) "" else as.character(q$text_en)
}
