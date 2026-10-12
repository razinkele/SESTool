# functions/indicator_registry.R
# WP5 indicator registry (spec 2026-10-11 WS-4): cached loader, lookups and
# picker choices. Reference data only; element snapshots live in
# functions/indicator_snapshot.R.

.indicator_registry_env <- new.env(parent = emptyenv())

load_indicator_registry <- function(path = NULL, force_reload = FALSE) {
  if (!force_reload && is.null(path) && !is.null(.indicator_registry_env$reg)) return(.indicator_registry_env$reg)
  if (is.null(path)) {
    path <- if (exists("get_project_file", mode = "function")) get_project_file("data", "wp5_indicators.json")
            else file.path("data", "wp5_indicators.json")
  }
  raw <- if (file.exists(path)) tryCatch(jsonlite::fromJSON(path, simplifyVector = FALSE), error = function(e) NULL) else NULL
  if (is.null(raw) || !is.list(raw$entries)) {
    warning(sprintf("[WP5 indicator registry] could not load %s", path))
    if (exists("debug_log", mode = "function")) debug_log(paste("indicator registry not loaded:", path), "WARN")
    reg <- list(version = NA_character_, entries = list())
  } else {
    codes <- vapply(raw$entries, function(e) as.character(e$code), character(1))
    reg <- list(version = as.character(raw$registry_version), entries = stats::setNames(raw$entries, codes))
  }
  .indicator_registry_env$reg <- reg
  reg
}

get_indicator <- function(code) {
  if (is.null(code) || length(code) != 1 || is.na(code) || !nzchar(code)) return(NULL)
  load_indicator_registry()$entries[[code]]
}

.indicator_rows <- function(entries) {
  if (length(entries) == 0) {
    return(data.frame(code = character(), name = character(), da = character(), source_set = character(),
                      dapsiwrm_type = character(), pathway_segment = character(), unit = character(),
                      stub = logical(), revision = integer(), provenance = character(), stringsAsFactors = FALSE))
  }
  g <- function(e, f, d = NA_character_) { v <- e[[f]]; if (is.null(v)) d else as.character(v) }
  data.frame(
    code = vapply(entries, g, "", "code"), name = vapply(entries, g, "", "name"),
    da = vapply(entries, g, "", "da"), source_set = vapply(entries, g, "", "source_set"),
    dapsiwrm_type = vapply(entries, g, "", "dapsiwrm_type"),
    pathway_segment = vapply(entries, g, "", "pathway_segment"), unit = vapply(entries, g, "", "unit"),
    stub = vapply(entries, function(e) isTRUE(e$stub), logical(1)),
    revision = vapply(entries, function(e) as.integer(e$revision %||% 1L), integer(1)),
    provenance = vapply(entries, g, "", "provenance"), stringsAsFactors = FALSE, row.names = NULL)
}

list_indicators <- function(da = NULL, dapsiwrm_type = NULL, segment = NULL, source_set = NULL,
                            include_stubs = TRUE) {
  df <- .indicator_rows(load_indicator_registry()$entries)
  if (!is.null(da)) df <- df[df$da %in% da, , drop = FALSE]
  if (!is.null(dapsiwrm_type)) df <- df[df$dapsiwrm_type %in% dapsiwrm_type, , drop = FALSE]
  if (!is.null(segment)) df <- df[!is.na(df$pathway_segment) & df$pathway_segment %in% segment, , drop = FALSE]
  if (!is.null(source_set)) df <- df[df$source_set %in% source_set, , drop = FALSE]
  if (!include_stubs) df <- df[!df$stub, , drop = FALSE]
  rownames(df) <- NULL
  df
}

search_indicators <- function(query) {
  df <- list_indicators()
  q <- tolower(trimws(as.character(query %||% "")))
  if (!nzchar(q)) return(df[0, , drop = FALSE])
  hit <- grepl(q, tolower(df$code), fixed = TRUE) |
    grepl(q, tolower(df$name), fixed = TRUE) | grepl(q, tolower(df$unit), fixed = TRUE)
  df[hit, , drop = FALSE]
}

#' Label suffix that keeps provenance visible in a plain-text select option
#' (selectize options cannot hold HTML badges). Stubs get the stub marker;
#' other non-wp5_source entries get the provenance_badge() label.
.indicator_label_suffix <- function(provenance, stub, i18n) {
  # i18n-ref: modules.indicator_registry.stub_marker
  # i18n-ref: modules.wp5_mechanisms.provenance.wp5_derived
  # i18n-ref: modules.wp5_mechanisms.provenance.toolbox_extension
  # i18n-ref: modules.wp5_mechanisms.provenance.provisional
  vapply(seq_along(provenance), function(i) {
    if (isTRUE(stub[i])) return(paste0(" [", i18n$t("modules.indicator_registry.stub_marker"), "]"))
    p <- provenance[i]
    if (is.na(p) || !nzchar(p) || identical(p, "wp5_source")) return("")
    paste0(" [", i18n$t(paste0("modules.wp5_mechanisms.provenance.", p)), "]")
  }, character(1))
}

#' Grouped choices for the per-element picker: the element's own type first.
#' Labels: "<code> · <English name> (<DA label>)[ <marker>]"; values: codes.
indicator_picker_choices <- function(element_key, i18n) {
  none <- stats::setNames(list(""), i18n$t("modules.indicator_registry.picker_none"))
  df <- list_indicators()
  if (nrow(df) == 0) return(none)
  # i18n-ref: modules.indicator_registry.da.macaronesia
  # i18n-ref: modules.indicator_registry.da.tuscan
  # i18n-ref: modules.indicator_registry.da.arctic
  da_lab <- vapply(df$da, function(d) i18n$t(paste0("modules.indicator_registry.da.", d)), character(1))
  labels <- paste0(df$code, " · ", df$name, " (", da_lab, ")",
                   .indicator_label_suffix(df$provenance, df$stub, i18n))
  own <- df$dapsiwrm_type == element_key
  out <- none
  if (any(own)) out[[i18n$t("modules.indicator_registry.picker_group_suggested")]] <-
    as.list(stats::setNames(df$code[own], labels[own]))
  if (any(!own)) out[[i18n$t("modules.indicator_registry.picker_group_other")]] <-
    as.list(stats::setNames(df$code[!own], labels[!own]))
  out
}
