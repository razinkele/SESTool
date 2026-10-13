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
