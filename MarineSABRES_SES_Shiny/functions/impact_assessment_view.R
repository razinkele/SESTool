# functions/impact_assessment_view.R
# Pure rendering helpers for the WP5 impact-assessment module (WS-6b). No
# reactivity here so the matrix, glyphs and messages are unit-testable.

#' Step keys of the D5.2 1.4 flow, named by step number
impact_step_keys <- function() {
  c("1" = "characterisation", "2" = "scenarios", "3" = "scoping", "4" = "matrix",
    "5" = "uncertainty", "6" = "trade_offs", "7" = "recommendations")
}

#' Step bar: one button per available step; the active one is highlighted.
#' @param active Integer step number
#' @param available Integer vector of steps that have a body (grows per task)
#' @param ns Namespace function
impact_step_bar <- function(active, available, i18n, ns) {
  keys <- impact_step_keys()
  # i18n-ref: modules.impact_assessment.step.characterisation
  # i18n-ref: modules.impact_assessment.step.scenarios
  # i18n-ref: modules.impact_assessment.step.scoping
  # i18n-ref: modules.impact_assessment.step.matrix
  # i18n-ref: modules.impact_assessment.step.uncertainty
  # i18n-ref: modules.impact_assessment.step.trade_offs
  # i18n-ref: modules.impact_assessment.step.recommendations
  items <- lapply(available, function(n) {
    cls <- if (n == active) "btn btn-primary btn-sm me-1 mb-1" else "btn btn-outline-primary btn-sm me-1 mb-1"
    actionButton(ns(paste0("goto_step_", n)), paste0(n, ". ", i18n$t(paste0("modules.impact_assessment.step.", keys[[as.character(n)]]))), class = cls)
  })
  div(class = "impact-step-bar", items)
}

#' DA banner: which demonstration area and whether WP5 reference data exists
impact_da_banner <- function(da, status, i18n) {
  # i18n-ref: modules.impact_assessment.da.macaronesia
  # i18n-ref: modules.impact_assessment.da.tuscan
  # i18n-ref: modules.impact_assessment.da.arctic
  # i18n-ref: modules.impact_assessment.da.none
  da_key <- if (nzchar(da)) paste0("modules.impact_assessment.da.", da) else "modules.impact_assessment.da.none"
  ref <- switch(status,
    available = i18n$t("modules.impact_assessment.reference_available"),
    valuation_only = i18n$t("modules.impact_assessment.reference_valuation_only"),
    i18n$t("modules.impact_assessment.reference_unavailable"))
  div(class = "alert alert-info py-2", icon("map-marker-alt"), " ", strong(i18n$t(da_key)), " — ", ref)
}

#' Scenario table rows for step 2
impact_scenario_table_df <- function(ia, i18n) {
  codes <- impact_scenario_codes(ia)
  if (length(codes) == 0) {
    return(data.frame(code = character(), name = character(), baseline = logical(), ambition_rank = integer(),
                      source_label = character(), stringsAsFactors = FALSE))
  }
  # i18n-ref: modules.impact_assessment.source.user
  # i18n-ref: modules.impact_assessment.source.wp5_reference
  rows <- lapply(codes, function(cd) {
    s <- ia$scenarios[[cd]]
    data.frame(code = cd, name = s$name, baseline = identical(ia$baseline_code, cd),
               ambition_rank = as.integer(s$ambition_rank),
               source_label = i18n$t(paste0("modules.impact_assessment.source.", s$source)),
               stringsAsFactors = FALSE)
  })
  do.call(rbind, rows)
}

#' Translated sentences for an impact_step_problems() frame
impact_problem_messages <- function(problems, i18n) {
  if (is.null(problems) || nrow(problems) == 0) return(character(0))
  # i18n-ref: modules.impact_assessment.problem.no_scenarios
  # i18n-ref: modules.impact_assessment.problem.too_many_scenarios
  # i18n-ref: modules.impact_assessment.problem.baseline_missing
  # i18n-ref: modules.impact_assessment.problem.displacement_note_missing
  # i18n-ref: modules.impact_assessment.problem.direction_missing
  # i18n-ref: modules.impact_assessment.problem.confidence_missing
  # i18n-ref: modules.impact_assessment.problem.driver_required
  # i18n-ref: modules.impact_assessment.problem.invalid_direction
  # i18n-ref: modules.impact_assessment.problem.invalid_magnitude
  # i18n-ref: modules.impact_assessment.problem.invalid_timing
  # i18n-ref: modules.impact_assessment.problem.invalid_confidence
  # i18n-ref: modules.impact_assessment.problem.invalid_uncertainty_driver
  # i18n-ref: modules.impact_assessment.problem.invalid_evidence
  # i18n-ref: modules.impact_assessment.problem.invalid_indicator_role
  # i18n-ref: modules.impact_assessment.problem.invalid_subdimension
  vapply(seq_len(nrow(problems)), function(i) {
    msg <- i18n$t(paste0("modules.impact_assessment.problem.", problems$problem[i]))
    if (nzchar(problems$criterion[i])) {
      paste0(wp5_vocab_label("criteria", problems$criterion[i], i18n), " / ", problems$scenario[i], ": ", msg)
    } else msg
  }, character(1))
}

#' Element picker choices from the ISA (both column cases, code map §5)
impact_element_choices <- function(project) {
  df <- tryCatch(get_all_isa_elements(project), error = function(e) data.frame())
  if (!is.data.frame(df) || nrow(df) == 0) return(character(0))
  # bind_rows over mixed-case frames yields BOTH id/ID (and name/Name) columns, each NA for the other
  # frames' rows, so coalesce across the cases instead of picking one column.
  pick <- function(cols) {
    out <- rep(NA_character_, nrow(df))
    for (cl in intersect(cols, names(df))) {
      v <- as.character(df[[cl]]); fill <- (is.na(out) | !nzchar(out)) & !is.na(v)
      out[fill] <- v[fill]
    }
    out
  }
  ids <- pick(c("id", "ID"))
  if (all(is.na(ids))) return(character(0))
  nms <- pick(c("name", "Name")); nms[is.na(nms)] <- ids[is.na(nms)]
  keep <- !is.na(ids) & nzchar(ids)
  stats::setNames(ids[keep], paste0(nms[keep], " (", ids[keep], ") [", df$element_type[keep], "]"))
}

#' Indicator picker choices for a DA from the WS-4 registry
impact_indicator_choices <- function(da, i18n) {
  if (!nzchar(da)) return(character(0))
  rows <- tryCatch(list_indicators(da = da), error = function(e) NULL)
  if (!is.data.frame(rows) || nrow(rows) == 0) return(character(0))
  stats::setNames(as.character(rows$code), paste0(rows$name, " (", rows$code, ")"))
}

#' Arrow glyph for a direction code (empty for "")
impact_direction_glyph <- function(direction) {
  m <- c(increase = "\u2191", decrease = "\u2193", no_change = "~", uncertain = "?")
  out <- unname(m[as.character(direction)]); out[is.na(out)] <- ""; out
}

#' Fill intensity for a magnitude code.
#' toolbox_extension (spec P4): the ONLY ordinal->numeric map in the module;
#' used for colour intensity, never for aggregation. incremental=1, moderate=2,
#' substantial=3, anything else 0.
impact_fill_level <- function(magnitude) {
  m <- c(incremental = 1L, moderate = 2L, substantial = 3L)
  out <- unname(m[as.character(magnitude)]); out[is.na(out)] <- 0L; out
}

impact_cell_css_class <- function(cell) {
  cell <- .impact_fill_cell(cell)
  paste("ia-cell", paste0("ia-fill-", impact_fill_level(cell$magnitude)),
        paste0("ia-dir-", if (nzchar(cell$direction)) cell$direction else "none"),
        paste0("ia-conf-", if (nzchar(cell$confidence)) cell$confidence else "none"))
}

#' The criterion x scenario matrix (step 4). Each cell is an actionLink.
impact_matrix_table <- function(ia, i18n, ns) {
  codes <- impact_scenario_codes(ia)
  header <- tags$tr(tags$th(""), lapply(codes, function(cd) {
    s <- ia$scenarios[[cd]]
    tags$th(class = "text-center", cd, tags$br(), tags$small(s$name),
            if (identical(ia$baseline_code, cd)) tags$span(class = "badge bg-secondary ms-1", i18n$t("modules.impact_assessment.baseline_label")))
  }))
  rows <- lapply(WP5_CRITERIA$code, function(cr) {
    tags$tr(tags$th(wp5_vocab_label("criteria", cr, i18n)), lapply(codes, function(cd) {
      cl <- impact_get_cell(ia, cr, cd)
      has_ref <- length(cl$reference) > 0
      label <- paste0(impact_direction_glyph(cl$direction), " ",
                      if (nzchar(cl$magnitude)) wp5_vocab_label("magnitude", cl$magnitude, i18n) else "",
                      if (nzchar(cl$confidence)) paste0(" (", wp5_vocab_label("confidence", cl$confidence, i18n), ")") else "")
      tags$td(class = paste(impact_cell_css_class(cl), if (has_ref) "ia-ref"),
              shiny::actionLink(ns(paste0("cell_", cr, "_", cd)), if (nzchar(trimws(label))) label else i18n$t("modules.impact_assessment.cell_empty"),
                                class = "ia-cell-link d-block"))
    }))
  })
  legend <- div(class = "small text-muted mt-2",
    i18n$t("modules.impact_assessment.legend_glyph"), " \u00b7 ", i18n$t("modules.impact_assessment.legend_fill"), " ",
    provenance_badge("toolbox_extension", i18n), " \u00b7 ", i18n$t("modules.impact_assessment.legend_hatch"))
  tagList(tags$table(class = "table table-bordered ia-matrix", tags$thead(header), tags$tbody(rows)), legend)
}
