# functions/wp5_vocabulary.R
# WP5 shared vocabulary helpers (spec 2026-10-11 WS-1).
# Codes are stored in project data; labels resolve via i18n at render time.

.wp5_vocab_table <- function() {
  list(
    criteria           = WP5_CRITERIA$code,
    subdimension       = unique(unlist(WP5_CRITERION_SUBDIMENSIONS, use.names = FALSE)),
    direction          = WP5_RUBRIC$direction,
    magnitude          = WP5_RUBRIC$magnitude,
    timing             = WP5_RUBRIC$timing,
    confidence         = WP5_RUBRIC$confidence,
    evidence           = WP5_RUBRIC$evidence,
    uncertainty_driver = WP5_RUBRIC$uncertainty_driver,
    indicator_role     = WP5_RUBRIC$indicator_role,
    pathway_segment    = WP5_RUBRIC$pathway_segment,
    instrument         = EBM_POLICY_INSTRUMENTS$code,
    measure            = EBM_MANAGEMENT_MEASURES$code,
    tenet              = EBM_TENETS$code,
    npg                = NPG_DIMENSIONS,
    graph_op           = GRAPH_EDIT_OPS
  )
}

#' All codes of a WP5 vocabulary
#' @param vocab Vocabulary name (see .wp5_vocab_table())
#' @return Character vector of codes
wp5_vocab_codes <- function(vocab) {
  tbl <- .wp5_vocab_table()
  if (!is.character(vocab) || length(vocab) != 1 || !vocab %in% names(tbl)) {
    stop("Unknown WP5 vocabulary: ", paste(vocab, collapse = ","))
  }
  tbl[[vocab]]
}

#' Normalise criterion codes, resolving D5.2 aliases (PO -> PI, FI -> FF)
#' @param x Character vector
#' @return Character vector of canonical codes, NA for unknown/empty
wp5_criterion_code <- function(x) {
  x <- toupper(trimws(as.character(x)))
  lookup <- setNames(WP5_CRITERIA$code, WP5_CRITERIA$code)
  for (i in seq_len(nrow(WP5_CRITERIA))) {
    for (a in WP5_CRITERIA$aliases[[i]]) lookup[[a]] <- WP5_CRITERIA$code[i]
  }
  out <- unname(lookup[x])
  out[is.na(x) | x == ""] <- NA_character_
  as.character(out)
}

#' i18n key for a vocabulary code
#' @return Character vector of keys
wp5_vocab_key <- function(vocab, code) {
  paste0("modules.wp5_vocabulary.", vocab, ".", gsub(".", "_", code, fixed = TRUE))
}

#' Translated label for vocabulary codes; falls back to the code itself
#' @param vocab Vocabulary name
#' @param code Character vector of codes
#' @param i18n Translator with $t(key)
#' @return Character vector of labels ("" for NA codes)
wp5_vocab_label <- function(vocab, code, i18n) {
  vapply(as.character(code), function(cd) {
    if (is.na(cd) || cd == "") return("")
    key <- wp5_vocab_key(vocab, cd)
    lbl <- tryCatch(as.character(i18n$t(key)), error = function(e) NA_character_)
    if (length(lbl) != 1 || is.na(lbl) || lbl == "" || identical(lbl, key)) cd else lbl
  }, character(1), USE.NAMES = FALSE)
}

# ------------------------------------------------------------------------------
# D5.3 intervention -> graph-operation table (data/wp5_intervention_ops.json)
# ------------------------------------------------------------------------------
.wp5_ops_env <- new.env(parent = emptyenv())
.wp5_ops_env$db <- NULL

#' Load the intervention->graph-operation table (cached)
#' @return Parsed list, or NULL (with a warning) if missing/corrupt
load_wp5_intervention_ops <- function(path = NULL, force_reload = FALSE) {
  if (!is.null(.wp5_ops_env$db) && !force_reload) return(invisible(.wp5_ops_env$db))
  if (is.null(path)) {
    path <- if (exists("get_project_file", mode = "function")) {
      get_project_file("data", "wp5_intervention_ops.json")
    } else file.path("data", "wp5_intervention_ops.json")
  }
  .wp5_ops_env$db <- NULL
  if (!file.exists(path)) {
    warning(sprintf("[WP5 vocab] intervention ops table not found at: %s", path))
    return(invisible(NULL))
  }
  db <- tryCatch(jsonlite::fromJSON(path, simplifyVector = FALSE), error = function(e) {
    warning(sprintf("[WP5 vocab] failed to parse intervention ops table: %s", e$message))
    NULL
  })
  .wp5_ops_env$db <- db
  if (!is.null(db) && exists("debug_log", mode = "function")) {
    debug_log(sprintf("WP5 intervention ops loaded: %d rows", length(db$interventions)), "WP5")
  }
  invisible(db)
}

#' Intervention types, optionally filtered by group
#' @return data.frame(id, group, provenance) (0 rows if table unavailable)
get_intervention_types <- function(group = NULL) {
  rows <- .wp5_ops_env$db$interventions %||% list()
  rows <- Filter(function(r) is.null(r$context), rows)
  if (!is.null(group)) rows <- Filter(function(r) identical(r$group, group), rows)
  data.frame(
    id = vapply(rows, function(r) r$id, character(1)),
    group = vapply(rows, function(r) r$group, character(1)),
    provenance = vapply(rows, function(r) r$provenance, character(1)),
    stringsAsFactors = FALSE
  )
}

#' Allowed graph-edit operations for an intervention type
#'
#' Union of xlsx and EBM operations, each tagged by source ("xlsx", "ebm",
#' or "xlsx+ebm"). A row whose `context` equals the requested DA overrides the
#' master row; unknown contexts fall back to master. (spec WS-1, Q4)
#' @return data.frame(op, source) ordered as GRAPH_EDIT_OPS; 0 rows if unknown
get_allowed_graph_ops <- function(id, context = NULL) {
  rows <- .wp5_ops_env$db$interventions %||% list()
  pick <- NULL
  if (!is.null(context)) {
    pick <- Find(function(r) identical(r$id, id) && identical(r$context, context), rows)
  }
  if (is.null(pick)) pick <- Find(function(r) identical(r$id, id) && is.null(r$context), rows)
  if (is.null(pick)) return(data.frame(op = character(), source = character(), stringsAsFactors = FALSE))
  x <- unlist(pick$ops_xlsx); e <- unlist(pick$ops_ebm)
  ops <- GRAPH_EDIT_OPS[GRAPH_EDIT_OPS %in% c(x, e)]
  src <- vapply(ops, function(o) paste(c(if (o %in% x) "xlsx", if (o %in% e) "ebm"), collapse = "+"),
                character(1), USE.NAMES = FALSE)
  data.frame(op = ops, source = src, stringsAsFactors = FALSE)
}

# Auto-load on source if data file present (mirrors wp5_kb_loader.R)
if (file.exists("data/wp5_intervention_ops.json")) {
  suppressWarnings(load_wp5_intervention_ops())
}
