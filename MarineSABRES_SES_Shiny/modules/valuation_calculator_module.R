# modules/valuation_calculator_module.R
# WS-5 valuation calculator (spec 2026-10-11 WS-5): Posidonia oceanica
# benefit-transfer values from D5.2 Table 19, with toolbox additions (central
# midpoint, NPV table, break-even, survival-adjusted cost) badged separately.
# Arithmetic lives in functions/valuation_calculations.R.

valuation_calculator_ui <- function(id, i18n) {
  tryCatch(shiny.i18n::usei18n(i18n$translator %||% i18n), error = function(e) NULL)
  ns <- NS(id)
  # i18n-ref: modules.valuation_calculator.service.coastal_protection
  # i18n-ref: modules.valuation_calculator.service.carbon_sequestration
  # i18n-ref: modules.valuation_calculator.service.recreation_tourism
  # i18n-ref: modules.valuation_calculator.service.food_provision
  # i18n-ref: modules.valuation_calculator.service.water_purification
  service_choices <- stats::setNames(WP5_VALUATION_SERVICES,
                                     vapply(WP5_VALUATION_SERVICES, function(s) i18n$t(paste0("modules.valuation_calculator.service.", s)),
                                            character(1)))
  tagList(
    fluidRow(column(12,
      create_module_header(ns, "modules.valuation_calculator.title", "modules.valuation_calculator.subtitle",
                           "help_valuation", i18n),
      div(class = "alert alert-warning py-2", icon("info-circle"), " ", i18n$t("modules.valuation_calculator.disclaimer"))
    )),
    fluidRow(
      column(4, wellPanel(
        p(strong(i18n$t("modules.valuation_calculator.habitat_label")), " ", i18n$t("modules.valuation_calculator.habitat_posidonia")),
        numericInput(ns("area_ha"), i18n$t("modules.valuation_calculator.area_label"), value = 1, min = 0, step = 0.1),
        checkboxGroupInput(ns("services"), i18n$t("modules.valuation_calculator.services_label"), choices = service_choices,
                           selected = WP5_VALUATION_SERVICES),
        numericInput(ns("horizon"), i18n$t("modules.valuation_calculator.horizon_label"), value = WP5_DEFAULT_TIME_HORIZON, min = 0,
                     max = WP5_VALUATION_MAX_HORIZON, step = 1),
        numericInput(ns("discount_rate"), i18n$t("modules.valuation_calculator.discount_rate_label"), value = NA, min = 0,
                     max = WP5_VALUATION_MAX_RATE_PCT, step = 0.5),
        tags$small(class = "text-muted", i18n$t("modules.valuation_calculator.discount_rate_help")),
        hr(),
        h5(i18n$t("modules.valuation_calculator.restoration_heading")),
        numericInput(ns("restoration_area"), i18n$t("modules.valuation_calculator.restoration_area_label"), value = NA, min = 0, step = 0.1),
        radioButtons(ns("cost_bound"), i18n$t("modules.valuation_calculator.cost_bound_label"),
                     choices = stats::setNames(c("low", "high"), c(i18n$t("modules.valuation_calculator.cost_bound_low"), i18n$t("modules.valuation_calculator.cost_bound_high"))),
                     selected = "low"),
        hr(),
        downloadButton(ns("download_xlsx"), i18n$t("modules.valuation_calculator.download_xlsx"))
      )),
      column(8, uiOutput(ns("results")))
    )
  )
}

valuation_calculator_server <- function(id, project_data_reactive, i18n, event_bus = NULL) {
  moduleServer(id, function(input, output, session) {
    # Formatted strings; keys listed as sentinels so the i18n audit sees them.
    # i18n-ref: modules.valuation_calculator.cumulative_label
    # i18n-ref: modules.valuation_calculator.central_cumulative
    # i18n-ref: modules.valuation_calculator.years_value
    # i18n-ref: modules.valuation_calculator.break_even_rate_note
    tfmt <- function(key, ...) {
      fmt <- i18n$t(key)
      if (grepl("%1$", fmt, fixed = TRUE)) tryCatch(sprintf(fmt, ...), error = function(e) fmt) else fmt
    }
    pct <- function(r) paste0(formatC(100 * r, format = "fg", digits = 3), "%")

    valuation <- reactive({
      compute_valuation(area_ha = input$area_ha, services = input$services, horizon = input$horizon,
                        discount_rate_pct = input$discount_rate, restoration_area = input$restoration_area,
                        cost_bound = input$cost_bound %||% "low")
    })

    primary_block <- function(r) {
      ps <- r$per_service
      # i18n-ref: modules.valuation_calculator.method.avoided_cost
      # i18n-ref: modules.valuation_calculator.method.social_cost_of_carbon
      # i18n-ref: modules.valuation_calculator.method.travel_cost_or_WTP
      # i18n-ref: modules.valuation_calculator.method.market_pricing
      # i18n-ref: modules.valuation_calculator.method.replacement_cost
      rows <- lapply(seq_len(nrow(ps)), function(i) tags$tr(
        tags$td(i18n$t(paste0("modules.valuation_calculator.service.", ps$service[i]))), tags$td(i18n$t(paste0("modules.valuation_calculator.method.", ps$method[i]))),
        tags$td(format_eur(ps$annual_low[i])), tags$td(format_eur(ps$annual_high[i]))))
      tagList(
        h4(i18n$t("modules.valuation_calculator.primary_heading")),
        tags$table(class = "table table-sm",
          tags$thead(tags$tr(tags$th(i18n$t("modules.valuation_calculator.col_service")), tags$th(i18n$t("modules.valuation_calculator.col_method")),
                             tags$th(i18n$t("modules.valuation_calculator.col_annual_low")), tags$th(i18n$t("modules.valuation_calculator.col_annual_high")))),
          tags$tbody(rows,
            tags$tr(class = "fw-bold", tags$td(i18n$t("modules.valuation_calculator.row_total")), tags$td(""),
                    tags$td(format_eur(r$total[["low"]])), tags$td(format_eur(r$total[["high"]]))),
            tags$tr(class = "fw-bold", tags$td(tfmt("modules.valuation_calculator.cumulative_label", as.integer(r$horizon))), tags$td(""),
                    tags$td(format_eur(r$cumulative[["low"]])), tags$td(format_eur(r$cumulative[["high"]]))))),
        tags$small(class = "text-muted", i18n$t("modules.valuation_calculator.source_note")))
    }

    secondary_block <- function(r) {
      npv_rows <- lapply(seq_len(nrow(r$npv)), function(i) tags$tr(
        class = if (r$npv$user[i]) "table-info" else NULL,
        tags$td(pct(r$npv$rate[i]), if (r$npv$user[i]) tags$em(paste0(" (", i18n$t("modules.valuation_calculator.your_rate"), ")"))),
        tags$td(format_eur(r$npv$low[i])), tags$td(format_eur(r$npv$central[i])),
        tags$td(format_eur(r$npv$high[i]))))
      rest <- r$restoration
      rest_ui <- if (!is.null(rest)) {
        # i18n-ref: modules.valuation_calculator.beyond_horizon
        yrs <- function(v, beyond) {
          if (is.na(v)) return(i18n$t("modules.valuation_calculator.never_breaks_even"))
          out <- tfmt("modules.valuation_calculator.years_value", format_years(v))
          if (isTRUE(beyond)) out <- paste(out, tfmt("modules.valuation_calculator.beyond_horizon", as.integer(r$horizon)))
          out
        }
        tagList(
          h5(i18n$t("modules.valuation_calculator.break_even_heading")),
          tags$table(class = "table table-sm", tags$tbody(
            tags$tr(tags$td(i18n$t("modules.valuation_calculator.restoration_cost")), tags$td(format_eur(rest$cost))),
            tags$tr(tags$td(i18n$t("modules.valuation_calculator.survival_adjusted")),
                    tags$td(paste(format_eur(rest$survival_adjusted[["low"]]), "–",
                                  format_eur(rest$survival_adjusted[["high"]])))),
            tags$tr(tags$td(i18n$t("modules.valuation_calculator.break_even_low")),
                    tags$td(yrs(rest$break_even_low, rest$beyond_horizon_low))),
            tags$tr(tags$td(i18n$t("modules.valuation_calculator.break_even_high")),
                    tags$td(yrs(rest$break_even_high, rest$beyond_horizon_high))))),
          p(class = "small text-muted mb-1", i18n$t("modules.valuation_calculator.break_even_assumption")),
          tags$small(class = "text-muted",
                     if (isTRUE(rest$rate_is_fallback)) i18n$t("modules.valuation_calculator.break_even_rate_fallback")
                     else tfmt("modules.valuation_calculator.break_even_rate_note", pct(rest$rate))))
      }
      tagList(
        h4(i18n$t("modules.valuation_calculator.secondary_heading"), provenance_badge("toolbox_extension", i18n)),
        p(i18n$t("modules.valuation_calculator.secondary_explain")),
        tags$table(class = "table table-sm", tags$tbody(
          tags$tr(tags$td(i18n$t("modules.valuation_calculator.central_annual")), tags$td(format_eur(r$total[["central"]]))),
          tags$tr(tags$td(tfmt("modules.valuation_calculator.central_cumulative", as.integer(r$horizon))),
                  tags$td(format_eur(r$cumulative[["central"]]))))),
        h5(i18n$t("modules.valuation_calculator.npv_heading")),
        tags$table(class = "table table-sm",
          tags$thead(tags$tr(tags$th(i18n$t("modules.valuation_calculator.col_rate")), tags$th(i18n$t("modules.valuation_calculator.col_npv_low")), tags$th(i18n$t("modules.valuation_calculator.col_npv_central")),
                             tags$th(i18n$t("modules.valuation_calculator.col_npv_high")))),
          tags$tbody(npv_rows)),
        rest_ui)
    }

    output$results <- renderUI({
      r <- valuation()
      if (!isTRUE(r$ok)) {
        # i18n-ref: modules.valuation_calculator.error.invalid_area
        # i18n-ref: modules.valuation_calculator.error.invalid_horizon
        # i18n-ref: modules.valuation_calculator.error.invalid_rate
        # i18n-ref: modules.valuation_calculator.error.invalid_restoration_area
        # i18n-ref: modules.valuation_calculator.error.data_unavailable
        return(div(class = "alert alert-danger",
                   tags$ul(lapply(r$errors, function(e) tags$li(i18n$t(paste0("modules.valuation_calculator.error.", e)))))))
      }
      tagList(
        # i18n-ref: modules.valuation_calculator.warn.no_services
        if (length(r$warnings)) div(class = "alert alert-info",
                                     lapply(r$warnings, function(w) p(i18n$t(paste0("modules.valuation_calculator.warn.", w))))),
        primary_block(r), hr(), secondary_block(r))
    })

    output$download_xlsx <- downloadHandler(
      filename = function() generate_export_filename("Valuation_Posidonia", ".xlsx"),
      content = function(file) {
        r <- valuation()
        req(isTRUE(r$ok))
        # Never "1e+06": format numbers in full (review #2).
        num_txt <- function(v) if (is.null(v) || length(v) == 0 || is.na(v[1])) "" else
          format(v[1], scientific = FALSE, trim = TRUE)
        inputs <- data.frame(
          parameter = c("habitat", "area_ha", "services", "horizon_years", "discount_rate_pct",
                        "restoration_area_ha", "cost_bound"),
          value = c(WP5_VALUATION_HABITAT, num_txt(input$area_ha),
                    paste(input$services %||% character(0), collapse = "; "), num_txt(input$horizon),
                    num_txt(input$discount_rate), num_txt(input$restoration_area),
                    input$cost_bound %||% "low"),
          stringsAsFactors = FALSE)
        tryCatch({
          build_valuation_excel(r, inputs, file)
        }, error = function(e) {
          debug_log(paste("Valuation Excel export failed:", e$message), "EXPORT")
          showNotification(paste0(i18n$t("common.messages.excel_export_failed"), " (", e$message, ")"),
                           type = "error", duration = NULL)
          stop(e)  # do not serve a partial file
        })
      }
    )

    create_help_observer(input, "help_valuation", "modules.valuation_calculator.help_title",
      tagList(p(i18n$t("modules.valuation_calculator.help_body_1")), p(i18n$t("modules.valuation_calculator.help_body_2")), p(i18n$t("modules.valuation_calculator.help_body_3"))), i18n)

    invisible(valuation)
  })
}

#' One-sheet xlsx: inputs, a blank row, then the long-format outputs with a
#' provenance column. Raises on failure; the caller's tryCatch notifies.
#' @param saver Function(wb, file, overwrite); override in tests to force failures.
build_valuation_excel <- function(result, inputs, file, saver = openxlsx::saveWorkbook) {
  wb <- openxlsx::createWorkbook()
  openxlsx::addWorksheet(wb, "Valuation")
  openxlsx::writeData(wb, "Valuation", inputs, startRow = 1)
  rows <- valuation_export_rows(result)
  start <- nrow(inputs) + 3
  openxlsx::writeData(wb, "Valuation", rows, startRow = start)
  # Whole-number format on the value columns so Excel never shows 1E+11 (review #2);
  # break-even years keep one decimal.
  if (nrow(rows) > 0) {
    cols <- match(c("low", "high", "value"), names(rows))
    data_rows <- start + seq_len(nrow(rows))
    yrs <- data_rows[rows$unit == "years"]
    eur <- data_rows[rows$unit != "years"]
    if (length(eur)) openxlsx::addStyle(wb, "Valuation", openxlsx::createStyle(numFmt = "#,##0"),
                                        rows = eur, cols = cols, gridExpand = TRUE)
    if (length(yrs)) openxlsx::addStyle(wb, "Valuation", openxlsx::createStyle(numFmt = "0.0"),
                                        rows = yrs, cols = cols, gridExpand = TRUE)
  }
  saver(wb, file, overwrite = TRUE)
  invisible(file)
}
