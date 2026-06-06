# functions/standard_entry_excel_import.R
# Reader for the Standard Entry Excel export (per-category element sheets +
# Matrix_* adjacency sheets, as written by write_isa_element_sheets()).
# Returns a list shaped like project$data$isa_data. Pure / non-reactive.

# Sheet name -> isa_data element key
# Responses_Measures is the DAPSIWRM feedback arm (R/M). It is optional: older
# 6-category exports omit it, corrected models include it.
.SE_ELEMENT_SHEETS <- c(
  Goods_Benefits     = "goods_benefits",
  Ecosystem_Services = "ecosystem_services",
  Marine_Processes   = "marine_processes",
  Pressures          = "pressures",
  Activities         = "activities",
  Drivers            = "drivers",
  Responses_Measures = "responses"
)

# Returns TRUE when a data frame has the required Standard-Entry columns.
.se_qualifies <- function(df) {
  is.data.frame(df) && all(c("ID", "Name") %in% names(df))
}

#' Read a Standard-Entry-exported .xlsx into an isa_data-shaped list.
#' @param path path to an .xlsx file written by write_isa_element_sheets().
#' @return list with the six element data frames (all columns character),
#'   adjacency_matrices (from Matrix_* sheets), and bot_data when present.
read_standard_entry_workbook <- function(path) {
  if (!is.character(path) || length(path) != 1L || !file.exists(path)) {
    stop("read_standard_entry_workbook: file not found")
  }
  sheets <- openxlsx::getSheetNames(path)

  out <- list()

  # Element sheets -> character data frames
  for (sheet in names(.SE_ELEMENT_SHEETS)) {
    if (sheet %in% sheets) {
      df <- openxlsx::read.xlsx(path, sheet = sheet)
      if (is.null(df)) df <- data.frame()
      df <- as.data.frame(df, stringsAsFactors = FALSE)
      if (ncol(df) > 0) df[] <- lapply(df, as.character)
      out[[.SE_ELEMENT_SHEETS[[sheet]]]] <- df
    }
  }

  # Matrix_* sheets -> adjacency_matrices (faithful edges)
  matrix_sheets <- sheets[startsWith(sheets, "Matrix_")]
  if (length(matrix_sheets) > 0) {
    am <- list()
    for (sheet in matrix_sheets) {
      key <- sub("^Matrix_", "", sheet)
      m <- openxlsx::read.xlsx(path, sheet = sheet, rowNames = TRUE)
      mat <- as.matrix(m)
      storage.mode(mat) <- "character"
      # NA replacement must follow the character coercion above (numeric NA -> NA_character_, never the string "NA")
      mat[is.na(mat)] <- ""            # in-app empty-cell convention
      am[[key]] <- mat
    }
    out$adjacency_matrices <- am
  }

  # Format detection: at least one element sheet must have ID+Name columns,
  # OR at least one Matrix_* sheet must be present.
  has_qualified_elements <- any(vapply(
    .SE_ELEMENT_SHEETS,
    function(key) .se_qualifies(out[[key]]),
    logical(1)
  ))
  has_matrices <- !is.null(out$adjacency_matrices) && length(out$adjacency_matrices) > 0

  if (!has_qualified_elements && !has_matrices) {
    e <- simpleError("Not a Standard Entry export (no recognizable element or Matrix_* sheets).")
    class(e) <- c("se_import_not_recognized", class(e))
    stop(e)
  }

  # NOTE: Case_Info / loop_connections sheets are not imported (out of L5 scope:
  # elements + adjacency edges only). gb_d closing-loop survives via Matrix_gb_d.

  # Optional pass-through sheets
  if ("BOT_Data" %in% sheets) {
    bot <- openxlsx::read.xlsx(path, sheet = "BOT_Data")
    if (!is.null(bot)) out$bot_data <- as.data.frame(bot, stringsAsFactors = FALSE)
  }

  out
}

# ---------------------------------------------------------------------------
# recover_isa_data(): the pure recovery pipeline
# ---------------------------------------------------------------------------
# Turns a raw saved_isa (from read_standard_entry_workbook OR a saved project)
# into a clean, app-ready isa_data: reconciles each element category to unique
# IDs (repairing the old positional-ID duplicates), then for each forward
# transition rebuilds an absent/empty matrix from the per-category LinkedX
# column — resolving links BY NAME so edges survive duplicate-ID repair —
# while KEEPING faithful matrices that already carry edges (e.g. gb_d).
#
# Single source of truth shared by the Standard Entry module's apply_saved_isa()
# (in-page Import button + project-load) and the sidebar Import Data menu, so the
# two import doors recover identically. Pure: no Shiny/reactives. Requires the
# globals ELEMENT_ID_PREFIX (constants.R), reconcile_loaded_element_ids /
# new_stable_id_store (data_structure.R), rebuild_forward_matrix_by_name
# (matrix_from_linked.R).
#
# @return list(elements, panel_ids, adjacency_matrices, user_edited_matrices,
#   repaired, any_rows_in, any_panel_ids_out, fell_back)
recover_isa_data <- function(saved_isa, id_store = NULL) {
  if (is.null(id_store)) id_store <- new_stable_id_store()

  id_load_map <- list(
    goods_benefits     = list(prefix = ELEMENT_ID_PREFIX$welfare,    panel = "gb_panel_ids"),
    ecosystem_services = list(prefix = ELEMENT_ID_PREFIX$impacts,    panel = "es_panel_ids"),
    marine_processes   = list(prefix = ELEMENT_ID_PREFIX$states,     panel = "mpf_panel_ids"),
    pressures          = list(prefix = ELEMENT_ID_PREFIX$pressures,  panel = "p_panel_ids"),
    activities         = list(prefix = ELEMENT_ID_PREFIX$activities, panel = "a_panel_ids"),
    drivers            = list(prefix = ELEMENT_ID_PREFIX$drivers,    panel = "d_panel_ids"),
    # DAPSIWRM feedback arm. Faithful Matrix_r_d edges survive via `am` below
    # (no Linked* rebuild needed), but the response elements must be reconciled
    # here or recov$elements drops them and the r_d edges become orphaned.
    responses          = list(prefix = ELEMENT_ID_PREFIX$responses,  panel = "r_panel_ids")
  )

  elements <- list(); panel_ids <- list()
  repaired <- FALSE; any_rows_in <- FALSE; any_panel_ids_out <- FALSE
  for (k in names(id_load_map)) {
    df <- saved_isa[[k]]
    if (is.data.frame(df) && nrow(df) > 0) {
      any_rows_in <- TRUE
      rec <- reconcile_loaded_element_ids(df, id_load_map[[k]]$prefix, id_store)
      elements[[k]] <- rec$df
      pids <- as.character(rec$df$ID)
      panel_ids[[id_load_map[[k]]$panel]] <- pids
      if (length(pids) > 0 && any(nzchar(pids))) any_panel_ids_out <- TRUE
      if (isTRUE(rec$repaired)) repaired <- TRUE
    } else {
      elements[[k]] <- if (is.data.frame(df)) df else data.frame()
      panel_ids[[id_load_map[[k]]$panel]] <- character(0)
    }
  }

  am <- if (!is.null(saved_isa$adjacency_matrices)) saved_isa$adjacency_matrices else list()
  ue <- list()
  fell_back <- FALSE
  linked_map <- list(
    es_gb  = list(src = "ecosystem_services", col = "LinkedGB",  tgt = "goods_benefits"),
    mpf_es = list(src = "marine_processes",   col = "LinkedES",  tgt = "ecosystem_services"),
    p_mpf  = list(src = "pressures",          col = "LinkedMPF", tgt = "marine_processes"),
    a_p    = list(src = "activities",         col = "LinkedP",   tgt = "pressures"),
    d_a    = list(src = "drivers",            col = "LinkedA",   tgt = "activities")
  )
  for (mk in names(linked_map)) {
    m <- linked_map[[mk]]
    src_df <- elements[[m$src]]; tgt_df <- elements[[m$tgt]]
    existing <- am[[mk]]
    has_edges <- is.matrix(existing) && any(nzchar(existing) & !is.na(existing))
    if (!has_edges &&
        is.data.frame(src_df) && nrow(src_df) > 0 && m$col %in% names(src_df) &&
        is.data.frame(tgt_df) && nrow(tgt_df) > 0) {
      mat <- rebuild_forward_matrix_by_name(
        source_df = src_df, linked_col = m$col, target_df = tgt_df,
        element_confidence_col = "Confidence")
      if (any(nzchar(mat))) {
        am[[mk]] <- mat
        ue[[mk]] <- matrix(FALSE, nrow(mat), ncol(mat), dimnames = dimnames(mat))
        fell_back <- TRUE
      }
    }
  }

  list(
    elements = elements,
    panel_ids = panel_ids,
    adjacency_matrices = am,
    user_edited_matrices = ue,
    repaired = repaired,
    any_rows_in = any_rows_in,
    any_panel_ids_out = any_panel_ids_out,
    fell_back = fell_back
  )
}
