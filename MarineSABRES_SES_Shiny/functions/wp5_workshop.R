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
    # any valid measure id: a record outlives removing its measure from the workshop, so
    # Undo still works if the measure is put back (WS-10 follow-up)
    is.list(e$before) && is.list(e$after) && length(e$after) > 0 && workshop_valid_measure_id(.ws_chr1(e$measure)) &&
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
  cnt <- safe_counter(ws$counter, df$RespondentId, WORKSHOP_PARTICIPANT_PREFIX)
  # duplicate participant ids (hand-edited files): keep every row, renumber the repeats so
  # "Delete selected" never removes two participants at once (WS-10 follow-up)
  dup <- which(duplicated(df$RespondentId) | !nzchar(df$RespondentId))
  if (length(dup)) {
    df$RespondentId[dup] <- vapply(seq_along(dup), function(i) next_element_id(WORKSHOP_PARTICIPANT_PREFIX, cnt + i), "")
    cnt <- cnt + length(dup)
    .ws_log(sprintf("renumbered %d duplicate or missing participant id(s)", length(dup)))
  }
  out$counter <- as.integer(cnt)
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

# ---- Summaries (spec §5) -------------------------------------------------------

.ws_bind <- function(rows, empty) if (length(rows)) do.call(rbind, rows) else empty

workshop_poll_summary <- function(ws) {
  ws <- normalize_workshop(ws); r <- ws$respondents
  empty <- data.frame(measure = character(), criterion = character(), n = integer(), median = numeric(),
                      mean = numeric(), order = integer(), stringsAsFactors = FALSE)
  out <- .ws_bind(unlist(lapply(ws$interventions, function(m) lapply(ws$poll$criteria, function(cr) {
    v <- as.character(r[[workshop_rank_col(m, cr)]] %||% character(0))
    x <- suppressWarnings(as.numeric(v[nzchar(v)]))
    data.frame(measure = m, criterion = cr, n = length(x), median = if (length(x)) stats::median(x) else NA_real_,
               mean = if (length(x)) mean(x) else NA_real_, order = NA_integer_, stringsAsFactors = FALSE)
  })), recursive = FALSE), empty)
  if (!nrow(out)) return(empty)
  first <- out[out$criterion == ws$poll$criteria[1], ]
  pos <- match(first$measure, ws$interventions)
  ranked <- first$measure[order(-ifelse(is.na(first$median), -Inf, first$median),
                                -ifelse(is.na(first$mean), -Inf, first$mean), pos)]
  out$order <- match(out$measure, ranked)
  out <- out[order(out$order, match(out$criterion, ws$poll$criteria)), ]
  rownames(out) <- NULL
  out
}

workshop_poll_counts <- function(ws) {
  ws <- normalize_workshop(ws); r <- ws$respondents
  vals <- WORKSHOP_POLL_SCALES[[ws$poll$scale]]
  .ws_bind(unlist(lapply(ws$interventions, function(m) lapply(ws$poll$criteria, function(cr) {
    v <- as.character(r[[workshop_rank_col(m, cr)]] %||% character(0))
    data.frame(measure = m, criterion = cr, value = vals, n = vapply(vals, function(x) sum(v == x), integer(1)),
               stringsAsFactors = FALSE, row.names = NULL)
  })), recursive = FALSE),
  data.frame(measure = character(), criterion = character(), value = character(), n = integer()))
}

workshop_tenet_summary <- function(ws) {
  ws <- normalize_workshop(ws); r <- ws$respondents
  empty <- data.frame(measure = character(), tenet = character(), n_valid = integer(), n_dont_know = integer(),
                      median = numeric(), p1 = integer(), p2 = integer(), p3 = integer(), p4 = integer(), p5 = integer(),
                      stringsAsFactors = FALSE)
  if (!isTRUE(ws$tenets_on)) return(empty)
  .ws_bind(unlist(lapply(ws$interventions, function(m) lapply(EBM_TENETS$code, function(t) {
    v <- as.character(r[[workshop_tenet_col(m, t)]] %||% character(0))
    pts <- match(v, WORKSHOP_TENET_CODES); pts <- pts[!is.na(pts)]
    cnt <- vapply(1:5, function(k) sum(pts == k), integer(1))
    data.frame(measure = m, tenet = t, n_valid = length(pts), n_dont_know = sum(v == "dont_know"),
               median = if (length(pts)) stats::median(pts) else NA_real_,
               p1 = cnt[1], p2 = cnt[2], p3 = cnt[3], p4 = cnt[4], p5 = cnt[5], stringsAsFactors = FALSE)
  })), recursive = FALSE), empty)
}

# ---- Write-back (spec §6) ------------------------------------------------------

workshop_tenet_level <- function(tenet, median) {
  if (length(median) != 1 || is.na(median)) return(NA_character_)
  if (median >= 4) "full" else if (median >= 3 && identical(tenet, "ecol_effective")) "intermediate" else "minimal"
}

workshop_writeback_proposal <- function(ws, measures) {
  ws <- normalize_workshop(ws); measures <- normalize_response_measures(measures)
  sm <- workshop_tenet_summary(ws)
  empty <- data.frame(measure = character(), tenet = character(), current = character(), median = numeric(),
                      n_valid = integer(), proposed = character(), changed = logical(), stringsAsFactors = FALSE)
  .ws_bind(unlist(lapply(intersect(ws$interventions, measures$ID), function(m) {
    i <- match(m, measures$ID)
    lapply(EBM_TENETS$code, function(t) {
      s <- sm[sm$measure == m & sm$tenet == t, , drop = FALSE]
      med <- if (nrow(s)) s$median[1] else NA_real_
      nv <- if (nrow(s)) s$n_valid[1] else 0L
      prop <- if (nv >= WORKSHOP_MIN_VALID) workshop_tenet_level(t, med) else NA_character_
      cur <- measures[[paste0("Tenet_", t)]][i]
      data.frame(measure = m, tenet = t, current = cur, median = med, n_valid = as.integer(nv), proposed = prop,
                 changed = !is.na(prop) && !identical(prop, cur), stringsAsFactors = FALSE)
    })
  }), recursive = FALSE), empty)
}

workshop_source_text <- function(ws, n, template, today = Sys.Date()) {
  date <- if (nzchar(ws$date %||% "")) ws$date else as.character(today)
  out <- gsub("{id}", ws$id, template, fixed = TRUE)
  out <- gsub("{date}", date, out, fixed = TRUE)
  gsub("{n}", as.character(n), out, fixed = TRUE)
}

#' The fields an Apply would write for one measure (changed tenets + TenetSource), or NULL
workshop_apply_change <- function(ws, measure, measures, template) {
  measures <- normalize_response_measures(measures)
  pr <- workshop_writeback_proposal(ws, measures)
  pr <- pr[pr$measure == measure & pr$changed, , drop = FALSE]
  if (!nrow(pr)) return(NULL)
  i <- match(measure, measures$ID)
  after <- c(stats::setNames(as.list(pr$proposed), paste0("Tenet_", pr$tenet)),
             list(TenetSource = workshop_source_text(normalize_workshop(ws), max(pr$n_valid), template)))
  before <- stats::setNames(lapply(names(after), function(cl) measures[[cl]][i]), names(after))
  list(after = after, before = before)
}

workshop_record_apply <- function(ws, measure, before, after, at = format(Sys.time(), "%Y-%m-%dT%H:%M:%S")) {
  ws <- normalize_workshop(ws)
  ws$applied[[length(ws$applied) + 1L]] <- list(measure = measure, at = at, before = before, after = after)
  normalize_workshop(ws)
}

workshop_last_apply <- function(ws, measure) {
  hits <- Filter(function(e) identical(e$measure, measure), normalize_workshop(ws)$applied)
  if (length(hits)) hits[[length(hits)]] else NULL
}

workshop_drop_last_apply <- function(ws, measure) {
  ws <- normalize_workshop(ws)
  idx <- which(vapply(ws$applied, function(e) identical(e$measure, measure), logical(1)))
  if (length(idx)) ws$applied[[max(idx)]] <- NULL
  ws
}

workshop_undo_check <- function(entry, measures) {
  measures <- normalize_response_measures(measures)
  i <- match(entry$measure, measures$ID)
  if (is.na(i)) return("gone")
  same <- vapply(names(entry$after), function(cl) identical(as.character(measures[[cl]][i]), entry$after[[cl]]), logical(1))
  if (all(same)) "ok" else "changed"
}

# ---- Import / template / export (spec §7) --------------------------------------

workshop_translations <- function() {
  path <- if (exists("get_project_file", mode = "function")) get_project_file("translations", "modules", "wp5_workshop.json")
          else file.path("translations", "modules", "wp5_workshop.json")
  readiness_translations(path)
}

workshop_parse_import <- function(df, ws, tr = workshop_translations()) {
  ws <- normalize_workshop(ws)
  if (!is.data.frame(df)) df <- data.frame()
  cols <- workshop_answer_columns(ws)
  original <- names(df)
  keyed <- .ready_key(original)
  names(df) <- keyed
  if (nrow(df) > 1000) return(list(ok = FALSE, error = "too_many_rows", expected = NULL))
  foreign <- original[grepl("^(rank|tenet)__", keyed) & !keyed %in% tolower(cols)]   # as written in the file
  if (length(foreign)) return(list(ok = FALSE, error = "foreign_columns", expected = foreign))
  if (!any(keyed %in% tolower(cols))) return(list(ok = FALSE, error = "no_answer_columns", expected = cols))
  scale_vals <- WORKSHOP_POLL_SCALES[[ws$poll$scale]]
  tmap <- c(readiness_value_map(WORKSHOP_TENET_ANSWERS, "modules.wp5_workshop.answer.", tr),
            stats::setNames(WORKSHOP_TENET_CODES, as.character(1:5)))
  blanked <- 0L
  out <- as.data.frame(stats::setNames(lapply(cols, function(cl) {
    k <- tolower(cl)
    if (!k %in% keyed) return(rep("", nrow(df)))
    v <- as.character(df[[k]]); v[is.na(v)] <- ""
    v <- trimws(gsub("\u2212", "-", v, fixed = TRUE))
    res <- if (startsWith(cl, "rank__")) {
      num <- suppressWarnings(as.numeric(v))
      s <- ifelse(is.na(num), "", as.character(num))
      ifelse(s %in% scale_vals, s, "")
    } else {
      r <- unname(tmap[.ready_key(v)]); r[is.na(r)] <- ""; r
    }
    blanked <<- blanked + sum(nzchar(v) & !nzchar(res))
    res
  }), cols), stringsAsFactors = FALSE, check.names = FALSE)
  keep <- if (nrow(out) && ncol(out)) rowSums(out != "") > 0 else rep(FALSE, nrow(out))
  list(ok = TRUE, rows = out[keep, , drop = FALSE], blanked = as.integer(blanked),
       ignored = setdiff(keyed, tolower(cols)), dropped_empty = as.integer(sum(!keep)))
}

workshop_template_wb <- function(ws, measures, i18n) {
  ws <- normalize_workshop(ws); measures <- normalize_response_measures(measures)
  cols <- workshop_answer_columns(ws)
  lab <- function(key) as.character(i18n$t(key))
  wb <- openxlsx::createWorkbook()
  openxlsx::addWorksheet(wb, "answers")
  openxlsx::writeData(wb, "answers", as.data.frame(stats::setNames(rep(list(character(0)), length(cols)), cols),
                                                   check.names = FALSE))
  openxlsx::addWorksheet(wb, "measures")
  openxlsx::writeData(wb, "measures", data.frame(id = ws$interventions,
    name = measures$Name[match(ws$interventions, measures$ID)] %||% "", stringsAsFactors = FALSE))
  openxlsx::addWorksheet(wb, "scales")
  openxlsx::writeData(wb, "scales", data.frame(
    scale = c(rep("rank", length(WORKSHOP_POLL_SCALES[[ws$poll$scale]])), rep("tenet", length(WORKSHOP_TENET_ANSWERS))),
    value = c(WORKSHOP_POLL_SCALES[[ws$poll$scale]], WORKSHOP_TENET_ANSWERS),
    label = c(WORKSHOP_POLL_SCALES[[ws$poll$scale]],
              paste0(c(as.character(1:5), ""), ifelse(seq_along(WORKSHOP_TENET_ANSWERS) <= 5, " = ", ""),
                     vapply(WORKSHOP_TENET_ANSWERS, function(cd) lab(paste0("modules.wp5_workshop.answer.", cd)), ""))),
    stringsAsFactors = FALSE))
  wb
}

workshop_export_wb <- function(ws, i18n) {
  ws <- normalize_workshop(ws)
  wb <- openxlsx::createWorkbook()
  openxlsx::addWorksheet(wb, "setup")
  openxlsx::writeData(wb, "setup", data.frame(
    field = c("id", "title", "date", "note", "measures", "scale", "criteria", "tenets_on"),
    value = c(ws$id, ws$title, ws$date, ws$note, paste(ws$interventions, collapse = "; "), ws$poll$scale,
              paste(ws$poll$criteria, collapse = "; "), as.character(ws$tenets_on)), stringsAsFactors = FALSE))
  openxlsx::addWorksheet(wb, "respondents"); openxlsx::writeData(wb, "respondents", ws$respondents)
  openxlsx::addWorksheet(wb, "poll_summary"); openxlsx::writeData(wb, "poll_summary", workshop_poll_summary(ws))
  openxlsx::addWorksheet(wb, "tenet_summary"); openxlsx::writeData(wb, "tenet_summary", workshop_tenet_summary(ws))
  wb
}

# Which workshop the selector should show after the list changes: the just-created one (wanted) wins when
# present, else the current selection if still valid, else the last workshop, "" when there are none.
workshop_pick_selection <- function(ids, current = NULL, wanted = NULL) {
  ids <- as.character(ids)
  if (!is.null(wanted) && length(wanted) == 1L && wanted %in% ids) return(wanted)
  if (!is.null(current) && length(current) == 1L && current %in% ids) return(current)
  if (length(ids)) ids[length(ids)] else ""
}
