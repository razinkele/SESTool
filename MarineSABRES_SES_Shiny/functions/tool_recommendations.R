# =============================================================================
# functions/tool_recommendations.R
# Cross-tool recommendation engine for analysis modules
# All user-facing strings use i18n keys — translations in
#   translations/modules/tool_recommendations.json
# =============================================================================

#' Get next-step recommendations for a given analysis module
#'
#' @param current_module Character string. One of "analysis_loops",
#'   "analysis_leverage", or "analysis_metrics".
#' @return A list of recommendation objects, each with fields:
#'   label_key, tab_id, icon, description_key.
get_next_steps <- function(current_module) {
  recommendations <- list(
    analysis_loops = list(
      list(
        label_key       = "modules.tool_recommendations.loops.leverage_label",
        tab_id          = "analysis_leverage",
        icon            = "crosshairs",
        description_key = "modules.tool_recommendations.loops.leverage_desc"
      ),
      list(
        label_key       = "modules.tool_recommendations.loops.metrics_label",
        tab_id          = "analysis_metrics",
        icon            = "chart-bar",
        description_key = "modules.tool_recommendations.loops.metrics_desc"
      ),
      list(
        label_key       = "modules.tool_recommendations.loops.report_label",
        tab_id          = "prepare_report",
        icon            = "file-alt",
        description_key = "modules.tool_recommendations.loops.report_desc"
      )
    ),
    analysis_leverage = list(
      list(
        label_key       = "modules.tool_recommendations.leverage.loops_label",
        tab_id          = "analysis_loops",
        icon            = "sync-alt",
        description_key = "modules.tool_recommendations.leverage.loops_desc"
      ),
      list(
        label_key       = "modules.tool_recommendations.leverage.responses_label",
        tab_id          = "create_ses_standard",
        icon            = "shield-alt",
        description_key = "modules.tool_recommendations.leverage.responses_desc"
      ),
      list(
        label_key       = "modules.tool_recommendations.leverage.report_label",
        tab_id          = "prepare_report",
        icon            = "file-alt",
        description_key = "modules.tool_recommendations.leverage.report_desc"
      )
    ),
    analysis_metrics = list(
      list(
        label_key       = "modules.tool_recommendations.metrics.leverage_label",
        tab_id          = "analysis_leverage",
        icon            = "crosshairs",
        description_key = "modules.tool_recommendations.metrics.leverage_desc"
      ),
      list(
        label_key       = "modules.tool_recommendations.metrics.loops_label",
        tab_id          = "analysis_loops",
        icon            = "sync-alt",
        description_key = "modules.tool_recommendations.metrics.loops_desc"
      )
    )
  )

  recommendations[[current_module]] %||% list()
}

#' Build the Next Steps UI panel
#'
#' Constructs a tagList containing actionLinks for each recommendation.
#' All displayed text is passed through i18n$t().
#'
#' @param current_module Character string. Module name passed to get_next_steps().
#' @param ns Namespace function (session$ns) from the calling module.
#' @param i18n i18n object with a $t() method.
#' @return A Shiny tags object, or NULL if no recommendations exist.
build_next_steps_ui <- function(current_module, ns, i18n) {
  recs <- get_next_steps(current_module)
  if (length(recs) == 0) return(NULL)

  rec_buttons <- lapply(seq_along(recs), function(i) {
    rec <- recs[[i]]
    tags$div(
      class = "next-step-item",
      style = "padding: 10px; margin: 5px 0; border: 1px solid #e0e0e0; border-radius: 8px; cursor: pointer;",
      actionLink(
        ns(paste0("next_step_", i)),
        label = tagList(
          icon(rec$icon), " ", i18n$t(rec$label_key)
        ),
        style = "font-weight: bold; font-size: 14px;"
      ),
      tags$p(
        class = "text-muted small",
        style = "margin: 4px 0 0 24px;",
        i18n$t(rec$description_key)
      )
    )
  })

  tags$div(
    class = "next-steps-panel",
    style = "margin-top: 20px; padding: 15px; background: #f8f9fa; border-radius: 10px;",
    h5(icon("arrow-right"), " ", i18n$t("common.buttons.next_steps")),
    tags$div(rec_buttons)
  )
}
