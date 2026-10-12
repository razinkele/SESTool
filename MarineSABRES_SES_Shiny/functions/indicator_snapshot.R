# functions/indicator_snapshot.R
# WS-4 element side: element frames carry ISA_INDICATOR_COLUMNS. Picking a
# registry entry copies values (snapshot) and records Registry_Id/_Version;
# drift = the registry entry's revision moved on since the snapshot.

#' Column of an element frame by name, case-insensitive; "" for absent/NA.
indicator_col <- function(df, name) {
  if (!is.data.frame(df)) return(character(0))
  hit <- which(tolower(names(df)) == tolower(name))
  if (length(hit) == 0) return(rep("", nrow(df)))
  v <- as.character(df[[hit[1]]])
  v[is.na(v)] <- ""
  v
}

.IND_INPUT_IDS <- c(Indicator = "indicator", Indicator_Unit = "indunit", Data_Source = "datasource",
                    Registry_Id = "registry")

#' Indicator form values for live panels -> df(ID, Indicator, Indicator_Unit, Data_Source, Registry_Id)
collect_indicator_inputs <- function(input, prefix, ids) {
  ids <- as.character(ids)
  cols <- lapply(.IND_INPUT_IDS, function(f) vapply(ids, function(sid) {
    v <- input[[paste0(prefix, "_", f, "_", sid)]]
    if (is.null(v) || length(v) == 0 || is.na(v[1])) "" else as.character(v[1])
  }, character(1), USE.NAMES = FALSE))
  data.frame(ID = ids, cols, stringsAsFactors = FALSE, check.names = FALSE)
}

#' Snapshot registry values into element rows (pure).
#' Blank Indicator/Unit/Source are filled from the picked entry; user text is kept.
#' Registry_Version: kept from `previous` when the same entry was already linked
#' (so an older snapshot stays detectable), else the entry's current revision;
#' cleared when no entry is picked.
apply_registry_snapshot <- function(df, previous = NULL) {
  if (!is.data.frame(df) || nrow(df) == 0) return(df)
  for (cn in ISA_INDICATOR_COLUMNS) df[[cn]] <- indicator_col(df, cn)
  df <- df[, !(tolower(names(df)) %in% tolower(ISA_INDICATOR_COLUMNS)) | names(df) %in% ISA_INDICATOR_COLUMNS,
           drop = FALSE]
  ids <- indicator_col(df, "ID")
  prev_id <- indicator_col(previous, "ID")
  prev_reg <- indicator_col(previous, "Registry_Id"); prev_ver <- indicator_col(previous, "Registry_Version")
  for (i in seq_len(nrow(df))) {
    code <- df$Registry_Id[i]
    if (!nzchar(code)) { df$Registry_Version[i] <- ""; next }
    e <- get_indicator(code)
    if (is.null(e)) next                                   # unknown id: leave as-is; drift reports it
    if (!nzchar(df$Indicator[i])) df$Indicator[i] <- as.character(e$name)
    if (!nzchar(df$Indicator_Unit[i])) df$Indicator_Unit[i] <- as.character(e$unit %||% "")
    if (!nzchar(df$Data_Source[i])) df$Data_Source[i] <- paste(unlist(e$data_sources), collapse = "; ")
    j <- match(ids[i], prev_id)
    keep <- !is.na(j) && identical(prev_reg[j], code) && nzchar(prev_ver[j])
    df$Registry_Version[i] <- if (keep) prev_ver[j] else as.character(e$revision %||% 1L)
  }
  df
}

#' Provenance badges for the picked entry (spec P1), shown beside the picker.
indicator_provenance_ui <- function(code, i18n) {
  e <- get_indicator(code)
  if (is.null(e)) return(NULL)
  badge <- function(p) if (exists("provenance_badge", mode = "function")) provenance_badge(p, i18n) else NULL
  parts <- list(
    if (isTRUE(e$stub)) shiny::tags$span(class = "badge bg-secondary ms-1",
                                         i18n$t("modules.indicator_registry.stub_marker")),
    badge(e$provenance),
    if (identical(e$classification_provenance, "toolbox_extension") &&
        !identical(e$provenance, "toolbox_extension")) badge("toolbox_extension")
  )
  parts <- Filter(Negate(is.null), parts)
  if (length(parts) == 0) return(NULL)
  shiny::tags$div(class = "wp5-indicator-provenance mb-1", parts)
}

#' TRUE when any of the six element frames holds a non-empty Registry_Id.
project_has_registry_snapshot <- function(isa_data) {
  if (!is.list(isa_data)) return(FALSE)
  any(vapply(ISA_ELEMENT_KEYS, function(k) any(nzchar(indicator_col(isa_data[[k]], "Registry_Id"))),
             logical(1)))
}

#' Field updates for a picker change (pure). A field is replaced only when it is
#' blank or still holds the previously picked entry's value, so text the user
#' typed is never overwritten; switching entries (or picking "—") replaces or
#' clears what the old entry put there. Same "fill, don't overwrite" rule as
#' apply_registry_snapshot() on save.
#' @param current named list(indicator, indunit, datasource) of current field values
#' @return named list of field -> new value, only for fields that change
indicator_picker_updates <- function(current, old_code, new_code) {
  vals <- function(code) {
    e <- get_indicator(code)
    if (is.null(e)) return(list(indicator = "", indunit = "", datasource = ""))
    list(indicator = as.character(e$name), indunit = as.character(e$unit %||% ""),
         datasource = paste(unlist(e$data_sources), collapse = "; "))
  }
  old <- vals(old_code); new <- vals(new_code)
  out <- list()
  for (f in c("indicator", "indunit", "datasource")) {
    cur <- as.character(current[[f]] %||% "")
    if (length(cur) == 0 || is.na(cur[1])) cur <- ""
    if ((!nzchar(cur[1]) || identical(cur[1], old[[f]])) && !identical(cur[1], new[[f]])) out[[f]] <- new[[f]]
  }
  out
}

#' Badge + auto-fill for one panel's picker. The text fields are filled as soon
#' as an entry is picked (UX only; the authoritative snapshot runs on save in
#' apply_registry_snapshot()).
register_indicator_picker_observer <- function(input, output, session, prefix, current_id, i18n) {
  sel_id <- paste0(prefix, "_registry_", current_id)
  output[[paste0(prefix, "_regbadge_", current_id)]] <- shiny::renderUI(
    indicator_provenance_ui(input[[sel_id]], i18n))
  prev_code <- ""
  shiny::observeEvent(input[[sel_id]], {
    new_code <- as.character(input[[sel_id]] %||% "")
    fid <- function(f) paste0(prefix, "_", f, "_", current_id)
    current <- lapply(stats::setNames(nm = c("indicator", "indunit", "datasource")),
                      function(f) shiny::isolate(input[[fid(f)]]))
    ups <- indicator_picker_updates(current, prev_code, new_code)
    for (f in names(ups)) shiny::updateTextInput(session, fid(f), value = ups[[f]])
    prev_code <<- new_code
  }, ignoreInit = TRUE)
}

#' Registry drift across element frames (pure). status: "updated" when the
#' entry's revision is newer than the snapshot, "missing" when the id is gone.
#' Returns zero rows when the registry itself is not loaded, so a missing or
#' malformed registry file never flags every linked element as missing.
indicator_drift <- function(isa_data) {
  empty <- data.frame(element_key = character(), element_id = character(), element_name = character(),
                      registry_id = character(), snapshot_revision = character(),
                      current_revision = character(), status = character(),
                      element_indicator = character(), element_unit = character(), element_source = character(),
                      registry_indicator = character(), registry_unit = character(), registry_source = character(),
                      stringsAsFactors = FALSE)
  if (!is.list(isa_data) || length(load_indicator_registry()$entries) == 0) return(empty)
  out <- list()
  for (key in ISA_ELEMENT_KEYS) {
    df <- isa_data[[key]]
    if (!is.data.frame(df) || nrow(df) == 0) next
    reg <- indicator_col(df, "Registry_Id"); ver <- indicator_col(df, "Registry_Version")
    ids <- indicator_col(df, "ID"); nms <- indicator_col(df, "Name")
    ind <- indicator_col(df, "Indicator"); unit <- indicator_col(df, "Indicator_Unit")
    src <- indicator_col(df, "Data_Source")
    for (i in which(nzchar(reg))) {
      e <- get_indicator(reg[i])
      cur <- if (is.null(e)) "" else as.character(e$revision %||% 1L)
      snap <- suppressWarnings(as.integer(ver[i]))
      status <- if (is.null(e)) "missing"
                else if (is.na(snap) || snap < as.integer(cur)) "updated" else NA_character_
      if (is.na(status)) next
      out[[length(out) + 1]] <- data.frame(
        element_key = key, element_id = ids[i], element_name = nms[i],
        registry_id = reg[i], snapshot_revision = ver[i], current_revision = cur, status = status,
        element_indicator = ind[i], element_unit = unit[i], element_source = src[i],
        registry_indicator = if (is.null(e)) "" else as.character(e$name),
        registry_unit = if (is.null(e)) "" else as.character(e$unit %||% ""),
        registry_source = if (is.null(e)) "" else paste(unlist(e$data_sources), collapse = "; "),
        stringsAsFactors = FALSE)
    }
  }
  if (length(out) == 0) empty else do.call(rbind, out)
}

#' Dedup keys for drift findings: sorted "<element_key>:<element_id>".
indicator_drift_keys <- function(d) {
  if (!is.data.frame(d) || nrow(d) == 0) return(character(0))
  sort(paste0(d$element_key, ":", d$element_id))
}

#' Overwrite the chosen rows from the current registry entry (user-confirmed).
apply_registry_resnapshot <- function(df, ids) {
  if (!is.data.frame(df) || nrow(df) == 0 || length(ids) == 0) return(df)
  idcol <- which(tolower(names(df)) == "id")[1]
  if (is.na(idcol)) return(df)
  for (i in which(as.character(df[[idcol]]) %in% ids)) {
    e <- get_indicator(indicator_col(df, "Registry_Id")[i])
    if (is.null(e)) next
    set <- function(col, val) {
      h <- which(tolower(names(df)) == tolower(col))
      if (!length(h)) { df[[col]] <<- ""; h <- ncol(df) }
      df[i, h[1]] <<- val
    }
    set("Indicator", as.character(e$name))
    set("Indicator_Unit", as.character(e$unit %||% ""))
    set("Data_Source", paste(unlist(e$data_sources), collapse = "; "))
    set("Registry_Version", as.character(e$revision %||% 1L))
  }
  df
}
