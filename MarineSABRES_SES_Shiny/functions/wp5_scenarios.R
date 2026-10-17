# functions/wp5_scenarios.R
# =============================================================================
# WP5 WS-8: D5.1 scenario x worldview reference data (spec 2026-10-16).
# Loaders for the two generated JSON files and pure helpers for the reference
# tab. The JSON is built by scripts/build_wp5_scenarios.py; do not edit by hand.
# =============================================================================

.wp5_scen_env <- new.env(parent = emptyenv())

WP5_PESTLE <- PESTLE_CODES   # constants.R (sourced before functions/)
WP5_SSPS <- c("ssp1_26", "ssp2_45", "ssp3_70", "ssp5_85")
WP5_WORLDVIEWS <- c("egalitarian", "individualist", "hierarchy")

# Read one generated file (cached); NULL + log on missing or invalid JSON
.wp5_scen_read <- function(name, key, path, force_reload) {
  if (!is.null(.wp5_scen_env[[key]]) && !force_reload) return(.wp5_scen_env[[key]])
  if (is.null(path)) {
    path <- if (exists("get_project_file", mode = "function")) get_project_file("data", name)
            else file.path("data", name)
  }
  db <- if (file.exists(path)) {
    tryCatch(jsonlite::fromJSON(path, simplifyVector = FALSE), error = function(e) NULL)
  } else NULL
  if (is.null(db) && exists("debug_log", mode = "function")) {
    debug_log(sprintf("WP5 scenarios: could not load %s", path), "WP5")
  }
  .wp5_scen_env[[key]] <- db
  db
}

#' D5.1 scenarios (4 SSP-RCPs with PESTLE x slice narratives), or NULL
load_wp5_scenarios <- function(path = NULL, force_reload = FALSE) {
  .wp5_scen_read("wp5_scenarios_ssp.json", "scenarios", path, force_reload)
}

#' D5.1 worldview x scenario matrix (72 cells), or NULL
load_wp5_worldview_matrix <- function(path = NULL, force_reload = FALSE) {
  .wp5_scen_read("wp5_worldview_matrix.json", "matrix", path, force_reload)
}

#' The six cells (one per PESTLE element) of one worldview x scenario pair, PESTLE order
wp5_cell_rows <- function(matrix, worldview, ssp) {
  cells <- Filter(function(c) identical(c$worldview, worldview) && identical(c$ssp, ssp), matrix$cells)
  cells[order(match(vapply(cells, `[[`, "", "pestle"), WP5_PESTLE))]
}

#' Heat-map summary: one row per worldview x scenario
#' @return data.frame(worldview, ssp, n_area, n_europe, pattern) where pattern
#'   is D5.1's match notation (PESTLE letter where matched, "_" where not)
wp5_heatmap_summary <- function(matrix) {
  letters6 <- c("P", "E", "S", "T", "L", "E")
  rows <- list()
  for (wv in WP5_WORLDVIEWS) for (s in WP5_SSPS) {
    cs <- wp5_cell_rows(matrix, wv, s)
    st <- vapply(cs, `[[`, "", "transformation")
    m <- vapply(cs, function(c) isTRUE(c$match), logical(1))
    rows[[length(rows) + 1L]] <- data.frame(
      worldview = wv, ssp = s, n_area = sum(st == "area"), n_europe = sum(st == "europe"),
      pattern = paste(ifelse(m, letters6, "_"), collapse = ""), stringsAsFactors = FALSE)
  }
  do.call(rbind, rows)
}

#' PESTLE elements needing area-level transformation in one cell
wp5_area_elements <- function(matrix, worldview, ssp) {
  cs <- wp5_cell_rows(matrix, worldview, ssp)
  vapply(Filter(function(c) identical(c$transformation, "area"), cs), `[[`, "", "pestle")
}

#' Register measures whose PestleTag covers at least one of `elements`
#' @param register Response register data.frame (may lack PestleTag: legacy)
#' @return the matching rows, with a list column `matched` (the covered elements)
wp5_matched_responses <- function(register, elements) {
  if (is.null(register)) return(data.frame())   # NULL[0, ] would error
  if (!is.data.frame(register) || nrow(register) == 0 ||
      !"PestleTag" %in% names(register) || length(elements) == 0) {
    return(register[0, , drop = FALSE])
  }
  tags <- strsplit(ifelse(is.na(register$PestleTag), "", register$PestleTag), ";", fixed = TRUE)
  hit <- lapply(tags, function(t) intersect(trimws(t), elements))
  keep <- lengths(hit) > 0
  out <- register[keep, , drop = FALSE]
  out$matched <- hit[keep]
  out
}
