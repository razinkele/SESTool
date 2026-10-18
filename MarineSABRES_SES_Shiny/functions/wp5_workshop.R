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

# ---- Storage (spec §4) ---------------------------------------------------------

workshop_rank_col <- function(m, crit) paste0("rank__", m, "__", crit)
workshop_tenet_col <- function(m, tenet) paste0("tenet__", m, "__", tenet)
workshop_valid_measure_id <- function(id) !is.na(id) & grepl("^[A-Za-z0-9]+$", as.character(id))

.ws_chr1 <- function(x, default = "") {
  v <- as.character(unlist(x))
  if (!length(v) || is.na(v[1])) default else v[1]
}
.ws_log <- function(msg) if (exists("debug_log", mode = "function")) debug_log(paste("WP5 workshop:", msg), "WARN")

workshop_answer_columns <- function(ws) {
  crit <- WORKSHOP_POLL_CRITERIA[WORKSHOP_POLL_CRITERIA %in% unlist(ws$poll$criteria)]
  unlist(lapply(as.character(unlist(ws$interventions)), function(m) {
    c(workshop_rank_col(m, crit), if (isTRUE(ws$tenets_on)) workshop_tenet_col(m, EBM_TENETS$code))
  })) %||% character(0)
}

# respondents: data.frame, or JSON list rows -> character data.frame
.ws_rows_df <- function(resp) {
  if (is.list(resp) && !is.data.frame(resp)) {
    rows <- Filter(is.list, resp)
    if (!length(rows)) return(data.frame())
    keys <- unique(unlist(lapply(rows, names)))
    return(as.data.frame(stats::setNames(lapply(keys, function(k) vapply(rows, function(r) .ws_chr1(r[[k]]), "")), keys),
                         stringsAsFactors = FALSE, check.names = FALSE))
  }
  if (is.data.frame(resp)) resp else data.frame()
}

.ws_norm_applied <- function(x, ivs) {
  allowed <- c(paste0("Tenet_", EBM_TENETS$code), "TenetSource")
  x <- Filter(is.list, x %||% list())
  ok <- Filter(function(e) {
    is.list(e$before) && is.list(e$after) && length(e$after) > 0 && .ws_chr1(e$measure) %in% ivs &&
      setequal(names(e$before), names(e$after)) && all(names(e$after) %in% allowed)
  }, x)
  if (length(ok) < length(x)) .ws_log(sprintf("dropped %d malformed apply record(s)", length(x) - length(ok)))
  # A written value is always a string: NULL/NA `after` keys are NA-fill from the JSON data.frame
  # round trip (records with different key sets), so drop them and their `before` (no phantom blanks).
  present <- function(v) !is.null(v) && length(v) > 0 && !is.na(unlist(v)[1])
  res <- lapply(ok, function(e) {
    keep <- names(e$after)[vapply(e$after, present, logical(1))]
    list(measure = .ws_chr1(e$measure), at = .ws_chr1(e$at),
         before = lapply(stats::setNames(e$before[keep], keep), .ws_chr1),
         after = lapply(stats::setNames(e$after[keep], keep), .ws_chr1))
  })
  Filter(function(r) length(r$after) > 0, res)
}

normalize_workshop <- function(ws) {
  if (!is.list(ws)) ws <- list()
  if (!is.list(ws$poll)) ws$poll <- list()       # a hand-edited "poll": "x" must not crash `$` below
  date <- .ws_chr1(ws$date)
  if (!grepl("^[0-9]{4}-[0-9]{2}-[0-9]{2}$", date)) date <- ""
  ivs <- unique(as.character(unlist(ws$interventions)))
  ivs <- ivs[workshop_valid_measure_id(ivs)]
  scale <- .ws_chr1(ws$poll$scale, "pm5")
  if (!scale %in% names(WORKSHOP_POLL_SCALES)) scale <- "pm5"
  crit <- WORKSHOP_POLL_CRITERIA[WORKSHOP_POLL_CRITERIA %in% as.character(unlist(ws$poll$criteria))]
  if (!length(crit)) crit <- "importance"
  out <- list(id = .ws_chr1(ws$id), title = .ws_chr1(ws$title), date = date, note = .ws_chr1(ws$note),
              interventions = ivs, poll = list(scale = scale, criteria = crit),
              tenets_on = if (is.null(ws$tenets_on)) TRUE else isTRUE(as.logical(unlist(ws$tenets_on))[1]),
              consent = isTRUE(as.logical(unlist(ws$consent))[1]))
  resp <- .ws_rows_df(ws$respondents)
  cols <- workshop_answer_columns(out)
  dropped <- setdiff(names(resp), c(WORKSHOP_META_COLUMNS, cols))
  if (length(dropped)) .ws_log(paste("dropped columns:", paste(dropped, collapse = ", ")))
  n <- nrow(resp)
  all_cols <- c(WORKSHOP_META_COLUMNS, cols)
  df <- as.data.frame(stats::setNames(lapply(all_cols, function(cl) {
    v <- if (cl %in% names(resp)) as.character(resp[[cl]]) else rep("", n)
    v[is.na(v)] <- ""
    v
  }), all_cols), stringsAsFactors = FALSE, check.names = FALSE)
  bad <- 0L
  for (cl in cols) {
    allowed <- if (startsWith(cl, "rank__")) WORKSHOP_POLL_SCALES[[scale]] else WORKSHOP_TENET_ANSWERS
    x <- nzchar(df[[cl]]) & !df[[cl]] %in% allowed
    bad <- bad + sum(x)
    df[[cl]][x] <- ""
  }
  if (bad > 0) .ws_log(sprintf("blanked %d out-of-range answer(s)", bad))
  out$counter <- as.integer(safe_counter(ws$counter, df$RespondentId, WORKSHOP_PARTICIPANT_PREFIX))
  out$respondents <- df
  out$applied <- .ws_norm_applied(ws$applied, ivs)
  out
}

normalize_workshops <- function(x) {
  items <- if (is.list(x)) x$items else NULL
  if (is.data.frame(items)) {          # fromJSON(simplifyVector = TRUE) shape (ruling 1)
    items <- tryCatch(jsonlite::fromJSON(jsonlite::toJSON(items, auto_unbox = TRUE, null = "null", na = "null"),
                                         simplifyVector = FALSE),
                      error = function(e) { .ws_log(paste("items conversion failed:", e$message)); list() })
  }
  items <- lapply(Filter(is.list, items %||% list()), normalize_workshop)
  items <- Filter(function(w) nzchar(w$id), items)
  ids <- vapply(items, `[[`, "", "id")
  if (any(duplicated(ids))) { .ws_log("dropped duplicate workshop ids"); items <- items[!duplicated(ids)]; ids <- ids[!duplicated(ids)] }
  list(version = 1L, counter = as.integer(safe_counter(if (is.list(x)) x$counter else 0, ids, WORKSHOP_ID_PREFIX)),
       items = items)
}

workshop_get <- function(store, id) Find(function(w) identical(w$id, id), normalize_workshops(store)$items)

workshop_set <- function(store, ws) {
  st <- normalize_workshops(store)
  ws <- normalize_workshop(ws)
  i <- match(ws$id, vapply(st$items, `[[`, "", "id"))
  if (is.na(i)) st$items[[length(st$items) + 1L]] <- ws else st$items[[i]] <- ws
  normalize_workshops(st)
}

workshop_remove <- function(store, id) {
  st <- normalize_workshops(store)
  st$items <- Filter(function(w) !identical(w$id, id), st$items)
  st
}

workshop_create <- function(store, title = "", date = as.character(Sys.Date())) {
  st <- normalize_workshops(store)
  st$counter <- st$counter + 1L
  st$items[[length(st$items) + 1L]] <- normalize_workshop(list(id = next_element_id(WORKSHOP_ID_PREFIX, st$counter),
                                                                title = title, date = date))
  st
}

workshop_duplicate <- function(store, id) {
  src <- workshop_get(store, id)
  if (is.null(src)) return(normalize_workshops(store))
  st <- workshop_create(store, title = src$title, date = as.character(Sys.Date()))
  new <- st$items[[length(st$items)]]
  new[c("interventions", "poll", "tenets_on", "note")] <- src[c("interventions", "poll", "tenets_on", "note")]
  workshop_set(st, new)
}

workshop_has_respondents <- function(ws) is.data.frame(ws$respondents) && nrow(ws$respondents) > 0

workshop_update_setup <- function(ws, fields) {
  ws <- normalize_workshop(ws)
  editable <- c("title", "date", "note", if (!workshop_has_respondents(ws)) c("interventions", "poll", "tenets_on"))
  for (k in intersect(names(fields), editable)) ws[[k]] <- fields[[k]]
  normalize_workshop(ws)
}

workshop_append <- function(ws, rows, source) {
  ws <- normalize_workshop(ws)
  if (!is.data.frame(rows) || nrow(rows) == 0) return(ws)
  start <- ws$counter
  rows$RespondentId <- vapply(seq_len(nrow(rows)), function(i) next_element_id(WORKSHOP_PARTICIPANT_PREFIX, start + i), "")
  rows$EnteredAt <- as.character(Sys.Date())
  rows$Source <- source
  tmp <- ws; tmp$respondents <- rows; tmp$applied <- list()     # never modifyList(): it merges data.frames column-wise
  new <- normalize_workshop(tmp)$respondents
  ws$respondents <- rbind(ws$respondents, new)
  ws$counter <- as.integer(start + nrow(rows))
  normalize_workshop(ws)
}

workshop_delete_respondents <- function(ws, ids) {
  ws <- normalize_workshop(ws)
  ws$respondents <- ws$respondents[!ws$respondents$RespondentId %in% ids, , drop = FALSE]
  rownames(ws$respondents) <- NULL
  ws
}

#' TRUE when the project needs 1.32.0: a workshop exists or a register row has TenetSource
workshops_need_version <- function(store, measures) {
  has_ws <- length(normalize_workshops(store)$items) > 0
  src <- if (is.data.frame(measures)) measures$TenetSource
         else if (is.list(measures)) vapply(Filter(is.list, measures), function(r) .ws_chr1(r$TenetSource), "")
         else NULL
  has_ws || any(nzchar(as.character(unlist(src))) & !is.na(unlist(src)))
}
