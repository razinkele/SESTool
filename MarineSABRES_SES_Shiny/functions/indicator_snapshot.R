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

#' Badge + auto-fill for one panel's picker. The text fields are filled as soon
#' as an entry is picked (UX only; the authoritative snapshot runs on save in
#' apply_registry_snapshot()).
register_indicator_picker_observer <- function(input, output, session, prefix, current_id, i18n) {
  sel_id <- paste0(prefix, "_registry_", current_id)
  output[[paste0(prefix, "_regbadge_", current_id)]] <- shiny::renderUI(
    indicator_provenance_ui(input[[sel_id]], i18n))
  shiny::observeEvent(input[[sel_id]], {
    e <- get_indicator(input[[sel_id]])
    if (is.null(e)) return(invisible(NULL))
    shiny::updateTextInput(session, paste0(prefix, "_indicator_", current_id), value = as.character(e$name))
    shiny::updateTextInput(session, paste0(prefix, "_indunit_", current_id), value = as.character(e$unit %||% ""))
    shiny::updateTextInput(session, paste0(prefix, "_datasource_", current_id),
                           value = paste(unlist(e$data_sources), collapse = "; "))
  }, ignoreInit = TRUE)
}
