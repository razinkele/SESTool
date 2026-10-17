# functions/wp5_readiness.R
# =============================================================================
# WP5 WS-9b (spec 2026-10-17): D5.4 governance-readiness check. Item bank
# loader, anonymous answer storage (data$pims$readiness) and the toolbox
# indicator per NPG dimension. Pure functions; the module is a thin shell.
# The indicator is a toolbox construct, not a WP5 score (D5.4 has no index).
# =============================================================================

.wp5_ready_env <- new.env(parent = emptyenv())

#' D5.4 readiness item bank, or NULL. Only default-path loads are cached.
load_wp5_readiness_items <- function(path = NULL, force_reload = FALSE) {
  default <- is.null(path)
  if (default && !force_reload && !is.null(.wp5_ready_env$bank)) return(.wp5_ready_env$bank)
  if (default) {
    path <- if (exists("get_project_file", mode = "function")) get_project_file("data", "wp5_readiness_items.json")
            else file.path("data", "wp5_readiness_items.json")
  }
  db <- if (file.exists(path)) tryCatch(jsonlite::fromJSON(path, simplifyVector = FALSE), error = function(e) NULL) else NULL
  if (is.null(db) && exists("debug_log", mode = "function")) debug_log(sprintf("WP5 readiness: could not load %s", path), "WP5")
  if (default) .wp5_ready_env$bank <- db
  db
}

readiness_item_ids <- function(bank) vapply(bank$items, `[[`, "", "id")
readiness_item <- function(bank, id) Find(function(it) identical(it$id, id), bank$items)
readiness_scale_codes <- function(bank, scale) as.character(unlist(bank$scales[[scale]]$codes))

#' Normalise data$pims$readiness: NULL, list(respondents = data.frame) or JSON list rows.
#' Unknown answer codes become ""; unknown item columns are kept (future item banks).
normalize_readiness <- function(readiness, bank) {
  resp <- if (is.list(readiness)) readiness$respondents else NULL
  if (is.list(resp) && !is.data.frame(resp)) {
    rows <- Filter(is.list, resp)
    resp <- if (!length(rows)) NULL else {
      keys <- unique(unlist(lapply(rows, names)))
      as.data.frame(stats::setNames(lapply(keys, function(k) vapply(rows, function(r) {
        v <- r[[k]]
        if (is.null(v) || length(v) == 0 || all(is.na(unlist(v)))) "" else as.character(unlist(v))[1]
      }, character(1))), keys), stringsAsFactors = FALSE)
    }
  }
  if (!is.data.frame(resp)) resp <- data.frame()
  ids <- if (is.null(bank)) character(0) else readiness_item_ids(bank)
  cols <- union(c(READINESS_META_COLUMNS, ids), names(resp))
  n <- nrow(resp)
  out <- lapply(cols, function(cl) {
    v <- if (cl %in% names(resp)) as.character(resp[[cl]]) else rep("", n)
    v[is.na(v)] <- ""
    v
  })
  out <- as.data.frame(stats::setNames(out, cols), stringsAsFactors = FALSE)
  if (!is.null(bank)) {
    for (id in ids) out[[id]][!out[[id]] %in% readiness_scale_codes(bank, readiness_item(bank, id)$scale)] <- ""
    out$Role[!out$Role %in% unlist(bank$roles)] <- ""
  }
  cnt <- safe_counter(if (is.list(readiness)) readiness$counter else 0, out$RespondentId, READINESS_ID_PREFIX)
  list(version = "1.0", respondents = out, counter = as.integer(cnt))
}

readiness_has_respondents <- function(readiness) {
  r <- if (is.list(readiness)) readiness$respondents else NULL
  is.data.frame(r) && nrow(r) > 0
}

#' Points of answer codes for one item (NA = not scorable); reverse flips the sign
readiness_points <- function(bank, id, codes) {
  it <- readiness_item(bank, id)
  sc <- bank$scales[[it$scale]]
  pts <- vapply(sc$points %||% list(), function(p) if (is.null(p)) NA_real_ else as.numeric(p), numeric(1))
  if (!length(pts)) return(rep(NA_real_, length(codes)))
  v <- pts[match(as.character(codes), as.character(unlist(sc$codes)))]
  if (isTRUE(it$reverse)) -v else v
}

#' Toolbox indicator per NPG dimension (state items only)
readiness_score <- function(respondents, bank) {
  n <- if (is.data.frame(respondents)) nrow(respondents) else 0L
  state <- Filter(function(it) identical(it$kind, "state"), bank$items)
  do.call(rbind, lapply(NPG_DIMENSIONS, function(d) {
    its <- Filter(function(it) identical(it$dimension, d), state)
    m <- if (length(its) && n > 0) {
      matrix(vapply(its, function(it) readiness_points(bank, it$id, respondents[[it$id]] %||% rep("", n)),
                    numeric(n)), nrow = n)
    } else matrix(numeric(0), nrow = n, ncol = 0)
    n_ans <- sum(!is.na(m))
    data.frame(dimension = d,
               score = if (n_ans > 0) mean(m, na.rm = TRUE) else NA_real_,
               n_respondents = as.integer(sum(rowSums(!is.na(m)) > 0)),
               n_answers = as.integer(n_ans), n_items = length(its),
               coverage = if (length(its) == 0) "none" else if (length(its) == 1) "low" else "ok",
               stringsAsFactors = FALSE)
  }))
}

#' Answer-code counts per item of one kind ("state", "attitude")
readiness_item_counts <- function(respondents, bank, kind) {
  its <- Filter(function(it) identical(it$kind, kind), bank$items)
  rows <- lapply(its, function(it) {
    codes <- readiness_scale_codes(bank, it$scale)
    v <- as.character(respondents[[it$id]] %||% character(0))
    data.frame(item = it$id, code = codes, n = vapply(codes, function(cd) sum(v == cd), integer(1)),
               stringsAsFactors = FALSE, row.names = NULL)
  })
  if (!length(rows)) return(data.frame(item = character(), code = character(), n = integer()))
  do.call(rbind, rows)
}

#' Annex 7 priority areas: mean rank (1 = most important) and number of ranks
readiness_priority <- function(respondents, bank) {
  its <- Filter(function(it) identical(it$kind, "priority"), bank$items)
  do.call(rbind, lapply(its, function(it) {
    r <- suppressWarnings(as.numeric(respondents[[it$id]] %||% character(0)))
    r <- r[!is.na(r)]
    data.frame(item = it$id, mean_rank = if (length(r)) mean(r) else NA_real_, n = length(r), stringsAsFactors = FALSE)
  }))
}

#' Per-role indicator, only for roles with at least min_n respondents (anonymity)
readiness_role_breakdown <- function(respondents, bank, min_n = 5L) {
  roles <- setdiff(unique(as.character(respondents$Role)), "")
  out <- Filter(Negate(is.null), lapply(roles, function(r) {
    sub <- respondents[respondents$Role == r, , drop = FALSE]
    if (nrow(sub) < min_n) return(NULL)
    sc <- readiness_score(sub, bank)
    sc$score[sc$n_respondents < min_n] <- NA_real_  # a cell below min_n could expose one person
    cbind(role = r, sc, stringsAsFactors = FALSE)
  }))
  if (!length(out)) NULL else do.call(rbind, out)
}

#' Append respondents (rows: data.frame of Role + item answer codes)
readiness_append <- function(readiness, rows, source, bank) {
  rd <- normalize_readiness(readiness, bank)
  if (!is.data.frame(rows) || nrow(rows) == 0) return(rd)
  start <- rd$counter
  rows$RespondentId <- vapply(seq_len(nrow(rows)), function(i) next_element_id(READINESS_ID_PREFIX, start + i), character(1))
  rows$EnteredAt <- as.character(Sys.Date())
  rows$Source <- source
  new <- normalize_readiness(list(respondents = rows), bank)$respondents
  cols <- union(names(rd$respondents), names(new))
  fill <- function(df) {
    for (cl in setdiff(cols, names(df))) df[[cl]] <- rep("", nrow(df))
    df[, cols, drop = FALSE]
  }
  rd$respondents <- rbind(fill(rd$respondents), fill(new))
  rd$counter <- as.integer(start + nrow(rows))
  rd
}

readiness_delete <- function(readiness, ids, bank) {
  rd <- normalize_readiness(readiness, bank)
  rd$respondents <- rd$respondents[!rd$respondents$RespondentId %in% ids, , drop = FALSE]
  rownames(rd$respondents) <- NULL
  rd
}

# ---- Import / template / export (WS-9b Task 4) --------------------------------

.ready_key <- function(x) {
  x <- as.character(x)
  if (requireNamespace("stringi", quietly = TRUE)) x <- stringi::stri_trans_general(x, "Latin-ASCII")
  gsub("\\s+", " ", trimws(tolower(x)))
}

#' The readiness translation table: key -> list(lang -> text)
readiness_translations <- function(path = NULL) {
  if (is.null(path)) {
    path <- if (exists("get_project_file", mode = "function")) get_project_file("translations", "modules", "wp5_readiness.json")
            else file.path("translations", "modules", "wp5_readiness.json")
  }
  tryCatch(jsonlite::fromJSON(path, simplifyVector = FALSE)$translation, error = function(e) list())
}

#' Label -> code map for one set of codes: the code itself and its label in every
#' language; a label that maps to two codes is ambiguous (NA)
readiness_value_map <- function(codes, key_prefix, tr) {
  pairs <- do.call(rbind, lapply(codes, function(cd) {
    labs <- c(cd, as.character(unlist(tr[[paste0(key_prefix, cd)]])))
    data.frame(lab = .ready_key(labs), code = cd, stringsAsFactors = FALSE)
  }))
  pairs <- unique(pairs[nzchar(pairs$lab), , drop = FALSE])
  n_codes <- tapply(pairs$code, pairs$lab, function(z) length(unique(z)))
  m <- stats::setNames(pairs$code, pairs$lab)
  m <- m[!duplicated(names(m))]
  m[names(m) %in% names(n_codes)[n_codes > 1]] <- NA_character_
  m
}

#' Parse an imported answers table. Only `role` and item-id columns are read.
readiness_parse_import <- function(df, bank, tr = readiness_translations()) {
  if (!is.data.frame(df)) df <- data.frame()
  names(df) <- .ready_key(names(df))
  ids <- readiness_item_ids(bank)
  if (nrow(df) > 1000) return(list(ok = FALSE, error = "too_many_rows", expected = NULL))
  if (!length(intersect(names(df), ids))) return(list(ok = FALSE, error = "no_item_columns", expected = ids))
  blanked <- 0L
  conv <- function(v, map) {
    k <- .ready_key(v); k[is.na(v)] <- ""
    res <- unname(map[k])
    bad <- nzchar(k) & is.na(res)
    res[is.na(res)] <- ""
    blanked <<- blanked + sum(bad)
    res
  }
  out <- data.frame(Role = rep("", nrow(df)), stringsAsFactors = FALSE)
  if ("role" %in% names(df)) out$Role <- conv(df$role, readiness_value_map(unlist(bank$roles), "modules.wp5_readiness.role.", tr))
  for (id in ids) {
    out[[id]] <- if (id %in% names(df)) {
      conv(df[[id]], readiness_value_map(readiness_scale_codes(bank, readiness_item(bank, id)$scale),
                                         "modules.wp5_readiness.answer.", tr))
    } else rep("", nrow(df))
  }
  keep <- if (nrow(out)) (rowSums(out[, ids, drop = FALSE] != "") > 0) | out$Role != "" else logical(0)
  list(ok = TRUE, rows = out[keep, , drop = FALSE], blanked = as.integer(blanked),
       ignored = setdiff(names(df), c("role", ids)), dropped_empty = as.integer(sum(!keep)))
}

#' Read an uploaded xlsx (sheet "answers" if present) or csv as character data
readiness_read_file <- function(path, name = path) {
  ext <- tolower(tools::file_ext(name))
  df <- if (ext == "xlsx") {
    sheets <- openxlsx::getSheetNames(path)
    openxlsx::read.xlsx(path, sheet = if ("answers" %in% sheets) "answers" else 1, colNames = TRUE, skipEmptyRows = TRUE)
  } else if (ext == "csv") {
    rd <- function(sep) utils::read.csv(path, sep = sep, colClasses = "character", check.names = FALSE, encoding = "UTF-8", na.strings = c("", "NA"))
    d <- rd(",")
    if (ncol(d) == 1 && grepl(";", names(d)[1], fixed = TRUE)) d <- rd(";")  # Excel in non-English locales
    d
  } else stop("Unsupported file type: ", ext)
  if (is.null(df)) data.frame() else df
}

#' xlsx template: answers (header only), items (current language), roles
readiness_template_wb <- function(bank, i18n) {
  ids <- readiness_item_ids(bank)
  lab <- function(key) as.character(i18n$t(key))
  allowed <- function(it) {
    cds <- readiness_scale_codes(bank, it$scale)
    if (identical(it$scale, "rank5")) return(paste(cds, collapse = "; "))
    paste(paste0(cds, " = ", vapply(cds, function(cd) lab(paste0("modules.wp5_readiness.answer.", cd)), "")), collapse = "; ")
  }
  wb <- openxlsx::createWorkbook()
  openxlsx::addWorksheet(wb, "answers")
  openxlsx::writeData(wb, "answers", as.data.frame(stats::setNames(rep(list(character(0)), length(ids) + 1), c("role", ids))))
  openxlsx::addWorksheet(wb, "items")
  openxlsx::writeData(wb, "items", data.frame(
    id = ids, question = vapply(ids, function(id) lab(paste0("modules.wp5_readiness.item.", id)), ""),
    allowed = vapply(bank$items, allowed, ""), stringsAsFactors = FALSE))
  roles <- unlist(bank$roles)
  openxlsx::addWorksheet(wb, "roles")
  openxlsx::writeData(wb, "roles", data.frame(code = roles,
    label = vapply(roles, function(r) lab(paste0("modules.wp5_readiness.role.", r)), ""), stringsAsFactors = FALSE))
  wb
}

#' xlsx export: about (indicator caveat), anonymous answers, indicator, priorities
readiness_export_wb <- function(readiness, bank, i18n) {
  rd <- normalize_readiness(readiness, bank)
  sc <- readiness_score(rd$respondents, bank)
  sc$label <- vapply(sc$dimension, function(d) wp5_vocab_label("npg", d, i18n), "")
  wb <- openxlsx::createWorkbook()
  openxlsx::addWorksheet(wb, "about")
  openxlsx::writeData(wb, "about", data.frame(note = as.character(i18n$t("modules.wp5_readiness.indicator_label"))))
  openxlsx::addWorksheet(wb, "answers"); openxlsx::writeData(wb, "answers", rd$respondents)
  openxlsx::addWorksheet(wb, "indicator"); openxlsx::writeData(wb, "indicator", sc)
  openxlsx::addWorksheet(wb, "priorities"); openxlsx::writeData(wb, "priorities", readiness_priority(rd$respondents, bank))
  wb
}
