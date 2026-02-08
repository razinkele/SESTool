# BOT (Behaviour Over Time) Analysis Module
# Extracted from analysis_tools_module.R
# Analyzes temporal patterns and trends in social-ecological system indicators

analysis_bot_ui <- function(id, i18n) {
  ns <- NS(id)

  fluidPage(
    # Use i18n for language support
    # REMOVED: usei18n() - only called once in main UI (app.R)

    uiOutput(ns("module_header")),

    fluidRow(
      # Left Panel: Data Input and Configuration
      column(4,
        wellPanel(
          h4(icon("database"), " ", i18n$t("modules.analysis.bot.time_series_data")),

          # Element Selection
          selectInput(ns("bot_element"), "Select Element:",
                     choices = c("Select element..." = ""),
                     width = "100%"),

          # Time Period
          sliderInput(ns("bot_years"), "Time Period:",
                     min = 1950, max = 2030, value = c(2000, 2024),
                     step = 1, sep = ""),

          # Data Input Method
          radioButtons(ns("data_input_method"), "Data Input Method:",
                      choices = c("Manual Entry" = "manual",
                                 "Upload CSV" = "upload",
                                 "Use ISA BOT Data" = "isa"),
                      selected = "isa"),

          conditionalPanel(
            condition = sprintf("input['%s'] == 'manual'", ns("data_input_method")),
            numericInput(ns("manual_year"), "Year:", value = 2024, min = 1950, max = 2030),
            numericInput(ns("manual_value"), "Value:", value = 100),
            actionButton(ns("add_datapoint"), "Add Data Point", class = "btn-sm btn-primary")
          ),

          conditionalPanel(
            condition = sprintf("input['%s'] == 'upload'", ns("data_input_method")),
            fileInput(ns("upload_csv"), "Upload CSV (Year, Value):",
                     accept = c(".csv"))
          ),

          hr(),

          # Analysis Options
          h5(icon("sliders-h"), " ", i18n$t("modules.analysis.bot.analysis_options")),

          checkboxInput(ns("show_trend"), "Show Trend Line", value = TRUE),
          checkboxInput(ns("show_moving_avg"), "Show Moving Average", value = FALSE),
          conditionalPanel(
            condition = sprintf("input['%s']", ns("show_moving_avg")),
            sliderInput(ns("moving_avg_window"), "Window Size:",
                       min = 2, max = 10, value = 3, step = 1)
          ),

          checkboxInput(ns("detect_patterns"), "Detect Patterns", value = FALSE),

          hr(),
          actionButton(ns("help_bot"), "Help", icon = icon("question-circle"), class = "btn-info btn-sm")
        )
      ),

      # Right Panel: Visualizations and Analysis
      column(8,
        tabsetPanel(
          # Time Series Plot
          tabPanel(icon("chart-line"), i18n$t("modules.analysis.bot.tab_time_series"),
            br(),
            dygraphOutput(ns("bot_timeseries"), height = PLOT_HEIGHT_MD),
            br(),
            h5(icon("table"), " ", i18n$t("modules.analysis.bot.summary_statistics")),
            verbatimTextOutput(ns("bot_stats"))
          ),

          # Pattern Detection
          tabPanel(icon("search"), i18n$t("modules.analysis.bot.tab_pattern_analysis"),
            br(),
            h4("Temporal Pattern Detection"),
            conditionalPanel(
              condition = sprintf("!input['%s']", ns("detect_patterns")),
              p(class = "text-muted", "Enable 'Detect Patterns' to analyze temporal dynamics.")
            ),
            conditionalPanel(
              condition = sprintf("input['%s']", ns("detect_patterns")),
              uiOutput(ns("pattern_results"))
            )
          ),

          # Data Table
          tabPanel(icon("table"), i18n$t("modules.analysis.bot.tab_data"),
            br(),
            DTOutput(ns("bot_data_table")),
            br(),
            div(style = "margin-top: 10px;",
              downloadButton(ns("download_bot_data"), "Download Data", class = "btn-sm"),
              actionButton(ns("clear_data"), "Clear All Data", class = "btn-sm btn-warning")
            )
          ),

          # Comparison
          tabPanel(icon("exchange-alt"), i18n$t("modules.analysis.bot.tab_scenario_comparison"),
            br(),
            h4("Compare Multiple Scenarios"),
            p("Upload or create multiple time series to compare different scenarios."),
            p(class = "text-muted", "Feature coming soon...")
          )
        )
      )
    )
  )
}

analysis_bot_server <- function(id, project_data_reactive, i18n) {
  moduleServer(id, function(input, output, session) {

    ns <- session$ns

    # Reactive values for BOT data
    bot_rv <- reactiveValues(
      current_element = NULL,
      timeseries_data = data.frame(Year = integer(), Value = numeric())
    )

    # === REACTIVE MODULE HEADER ===
    output$module_header <- renderUI({
      tagList(
        h2(icon("chart-line"), " ", i18n$t("modules.analysis.bot.advanced_bot_analysis")),
        p(i18n$t("modules.analysis.bot.analyze_temporal_patterns"))
      )
    })

    # Update element choices from ISA data
    observe({
      req(project_data_reactive())
      data <- project_data_reactive()
      isa_data <- data$data$isa_data

      # Get all element names
      all_elements <- c()
      if (!is.null(isa_data$goods_benefits) && nrow(isa_data$goods_benefits) > 0) {
        gb_names <- if("Name" %in% names(isa_data$goods_benefits)) {
          isa_data$goods_benefits$Name
        } else if("name" %in% names(isa_data$goods_benefits)) {
          isa_data$goods_benefits$name
        } else {
          character(0)
        }
        all_elements <- c(all_elements, paste0("G&B: ", gb_names))
      }

      if (!is.null(isa_data$ecosystem_services) && nrow(isa_data$ecosystem_services) > 0) {
        es_names <- if("Name" %in% names(isa_data$ecosystem_services)) {
          isa_data$ecosystem_services$Name
        } else if("name" %in% names(isa_data$ecosystem_services)) {
          isa_data$ecosystem_services$name
        } else {
          character(0)
        }
        all_elements <- c(all_elements, paste0("ES: ", es_names))
      }

      if (!is.null(isa_data$pressures) && nrow(isa_data$pressures) > 0) {
        p_names <- if("Name" %in% names(isa_data$pressures)) {
          isa_data$pressures$Name
        } else if("name" %in% names(isa_data$pressures)) {
          isa_data$pressures$name
        } else {
          character(0)
        }
        all_elements <- c(all_elements, paste0("Pressure: ", p_names))
      }

      updateSelectInput(session, "bot_element",
                       choices = c("Select element..." = "", all_elements))
    })

    # Manual data point addition
    observeEvent(input$add_datapoint, {
      req(input$manual_year, input$manual_value)

      new_point <- data.frame(
        Year = input$manual_year,
        Value = input$manual_value
      )

      bot_rv$timeseries_data <- rbind(bot_rv$timeseries_data, new_point)
      bot_rv$timeseries_data <- bot_rv$timeseries_data[order(bot_rv$timeseries_data$Year), ]

      showNotification(i18n$t("modules.analysis.common.analysis_data_added"), type = "message")
    })

    # CSV upload
    observeEvent(input$upload_csv, {
      req(input$upload_csv)

      tryCatch({
        uploaded <- read.csv(input$upload_csv$datapath)
        if(has_required_columns(uploaded, c("Year", "Value"))) {
          bot_rv$timeseries_data <- uploaded[, c("Year", "Value")]
          bot_rv$timeseries_data <- bot_rv$timeseries_data[order(bot_rv$timeseries_data$Year), ]
          showNotification(i18n$t("modules.analysis.common.analysis_csv_loaded"), type = "message")
        } else {
          showNotification(i18n$t("modules.analysis.common.analysis_csv_columns_error"), type = "error")
        }
      }, error = function(e) {
        showNotification(paste(i18n$t("modules.analysis.common.analysis_error_loading_csv"), e$message), type = "error")
      })
    })

    # Load ISA BOT data
    observe({
      req(input$data_input_method == "isa")
      req(project_data_reactive())

      data <- project_data_reactive()
      if(!is.null(data$data$isa_data$bot_data) && nrow(data$data$isa_data$bot_data) > 0) {
        bot_data <- data$data$isa_data$bot_data
        if(has_required_columns(bot_data, c("Year", "Value"))) {
          bot_rv$timeseries_data <- bot_data[, c("Year", "Value")]
          bot_rv$timeseries_data <- bot_rv$timeseries_data[order(bot_rv$timeseries_data$Year), ]
        }
      }
    })

    # Clear data
    observeEvent(input$clear_data, {
      bot_rv$timeseries_data <- data.frame(Year = integer(), Value = numeric())
      showNotification(i18n$t("modules.analysis.common.analysis_data_cleared"), type = "warning")
    })

    # Time series plot with dygraphs
    output$bot_timeseries <- renderDygraph({
      req(nrow(bot_rv$timeseries_data) > 0)

      ts_data <- bot_rv$timeseries_data

      # Convert to xts for dygraphs
      ts_xts <- xts::xts(ts_data$Value, order.by = as.Date(paste0(ts_data$Year, "-01-01")))

      dg <- dygraph(ts_xts, main = paste("BOT Analysis:", input$bot_element),
                   xlab = "Year", ylab = "Value") %>%
        dyOptions(colors = "#2196F3", strokeWidth = 2, drawPoints = TRUE, pointSize = 4) %>%
        dyRangeSelector() %>%
        dyHighlight(highlightCircleSize = 5,
                   highlightSeriesBackgroundAlpha = 0.2,
                   hideOnMouseOut = FALSE)

      # Add trend line if requested
      if(input$show_trend && nrow(ts_data) > 2) {
        lm_fit <- lm(Value ~ Year, data = ts_data)
        trend_values <- predict(lm_fit, newdata = ts_data)
        trend_xts <- xts::xts(trend_values, order.by = as.Date(paste0(ts_data$Year, "-01-01")))

        combined <- merge(ts_xts, trend_xts)
        names(combined) <- c("Actual", "Trend")

        dg <- dygraph(combined) %>%
          dySeries("Actual", color = "#2196F3", strokeWidth = 2, drawPoints = TRUE, pointSize = 4) %>%
          dySeries("Trend", color = "#FF5722", strokeWidth = 2, strokePattern = "dashed") %>%
          dyRangeSelector() %>%
          dyHighlight(highlightCircleSize = 5)
      }

      # Add moving average if requested
      if(input$show_moving_avg && nrow(ts_data) > input$moving_avg_window) {
        ma_values <- stats::filter(ts_data$Value, rep(1/input$moving_avg_window, input$moving_avg_window), sides = 2)
        ma_xts <- xts::xts(ma_values, order.by = as.Date(paste0(ts_data$Year, "-01-01")))

        if(input$show_trend) {
          combined <- merge(combined, ma_xts)
          names(combined) <- c("Actual", "Trend", "Moving Avg")
          dg <- dygraph(combined) %>%
            dySeries("Actual", color = "#2196F3", strokeWidth = 2, drawPoints = TRUE, pointSize = 4) %>%
            dySeries("Trend", color = "#FF5722", strokeWidth = 2, strokePattern = "dashed") %>%
            dySeries("Moving Avg", color = "#4CAF50", strokeWidth = 2) %>%
            dyRangeSelector()
        } else {
          combined <- merge(ts_xts, ma_xts)
          names(combined) <- c("Actual", "Moving Avg")
          dg <- dygraph(combined) %>%
            dySeries("Actual", color = "#2196F3", strokeWidth = 2, drawPoints = TRUE, pointSize = 4) %>%
            dySeries("Moving Avg", color = "#4CAF50", strokeWidth = 2) %>%
            dyRangeSelector()
        }
      }

      dg
    })

    # Summary statistics
    output$bot_stats <- renderText({
      req(nrow(bot_rv$timeseries_data) > 0)

      ts_data <- bot_rv$timeseries_data

      stats_text <- paste(
        sprintf("Number of observations: %d", nrow(ts_data)),
        sprintf("Time period: %d - %d", min(ts_data$Year), max(ts_data$Year)),
        sprintf("Mean value: %.2f", mean(ts_data$Value, na.rm = TRUE)),
        sprintf("Std deviation: %.2f", sd(ts_data$Value, na.rm = TRUE)),
        sprintf("Min value: %.2f (Year %d)", min(ts_data$Value), ts_data$Year[which.min(ts_data$Value)]),
        sprintf("Max value: %.2f (Year %d)", max(ts_data$Value), ts_data$Year[which.max(ts_data$Value)]),
        sep = "\n"
      )

      # Add trend info if enabled
      if(input$show_trend && nrow(ts_data) > 2) {
        lm_fit <- lm(Value ~ Year, data = ts_data)
        slope <- coef(lm_fit)[2]
        r_squared <- summary(lm_fit)$r.squared

        trend_direction <- if(slope > 0) "Increasing" else if(slope < 0) "Decreasing" else "Stable"

        stats_text <- paste(
          stats_text,
          "",
          "Trend Analysis:",
          sprintf("  Direction: %s", trend_direction),
          sprintf("  Rate of change: %.2f units/year", slope),
          sprintf("  R-squared: %.3f", r_squared),
          sep = "\n"
        )
      }

      stats_text
    })

    # Pattern detection
    output$pattern_results <- renderUI({
      req(input$detect_patterns)
      req(nrow(bot_rv$timeseries_data) > 0)

      ts_data <- bot_rv$timeseries_data

      patterns <- list()

      # Trend pattern
      if(nrow(ts_data) > 2) {
        lm_fit <- lm(Value ~ Year, data = ts_data)
        slope <- coef(lm_fit)[2]
        p_value <- summary(lm_fit)$coefficients[2, 4]

        if(p_value < 0.05) {
          if(slope > 0) {
            patterns <- c(patterns, list(tags$div(
              class = "alert alert-info",
              icon("arrow-up"), strong(" Significant Increasing Trend Detected"),
              p(sprintf("The data shows a statistically significant upward trend (p < 0.05) with an average increase of %.2f units per year.", slope))
            )))
          } else {
            patterns <- c(patterns, list(tags$div(
              class = "alert alert-warning",
              icon("arrow-down"), strong(" Significant Decreasing Trend Detected"),
              p(sprintf("The data shows a statistically significant downward trend (p < 0.05) with an average decrease of %.2f units per year.", abs(slope)))
            )))
          }
        }
      }

      # Volatility pattern
      if(nrow(ts_data) > 3) {
        cv <- sd(ts_data$Value) / mean(ts_data$Value) * 100
        if(cv > 30) {
          patterns <- c(patterns, list(tags$div(
            class = "alert alert-danger",
            icon("exclamation-triangle"), strong(" High Volatility Detected"),
            p(sprintf("Coefficient of variation: %.1f%%. The system shows high variability, suggesting instability or external shocks.", cv))
          )))
        }
      }

      # Growth/decline phases
      if(nrow(ts_data) > 5) {
        diffs <- diff(ts_data$Value)
        growth_phases <- sum(diffs > 0)
        decline_phases <- sum(diffs < 0)

        if(growth_phases > decline_phases * 2) {
          patterns <- c(patterns, list(tags$div(
            class = "alert alert-success",
            icon("chart-line"), strong(" Predominantly Growth Phase"),
            p(sprintf("%d periods of growth vs %d periods of decline.", growth_phases, decline_phases))
          )))
        } else if(decline_phases > growth_phases * 2) {
          patterns <- c(patterns, list(tags$div(
            class = "alert alert-warning",
            icon("chart-line"), strong(" Predominantly Decline Phase"),
            p(sprintf("%d periods of decline vs %d periods of growth.", decline_phases, growth_phases))
          )))
        }
      }

      if(length(patterns) == 0) {
        return(tags$div(
          class = "alert alert-secondary",
          icon("info-circle"), " No significant patterns detected in the current time series."
        ))
      }

      do.call(tagList, patterns)
    })

    # Data table
    output$bot_data_table <- renderDT({
      datatable(bot_rv$timeseries_data,
               options = list(pageLength = 10, scrollY = "300px"),
               rownames = FALSE,
               editable = TRUE)
    })

    # Download handler
    output$download_bot_data <- downloadHandler(
      filename = function() {
        generate_export_filename(paste0("BOT_Data_", input$bot_element), ".csv")
      },
      content = function(file) {
        write.csv(bot_rv$timeseries_data, file, row.names = FALSE)
      }
    )

    # Help modal
    observeEvent(input$help_bot, {
      showModal(modalDialog(
        title = "Advanced BOT Analysis - Help",
        size = "l",
        easyClose = TRUE,

        h4(icon("info-circle"), " What is BOT Analysis?"),
        p("Behaviour Over Time (BOT) analysis examines how key system indicators change over time, revealing important dynamics such as trends, oscillations, and regime shifts."),

        h5(icon("chart-line"), " Features"),
        tags$ul(
          tags$li(strong("Interactive Time Series:"), " Zoom, pan, and explore temporal patterns with dygraphs"),
          tags$li(strong("Trend Analysis:"), " Automatically detect and visualize linear trends"),
          tags$li(strong("Moving Averages:"), " Smooth out short-term fluctuations"),
          tags$li(strong("Pattern Detection:"), " Identify significant trends, volatility, and phase changes"),
          tags$li(strong("Multiple Data Sources:"), " Manual entry, CSV upload, or ISA data import")
        ),

        h5(icon("lightbulb"), " Interpreting Patterns"),
        tags$ul(
          tags$li(strong("Increasing Trend:"), " System variable is growing over time"),
          tags$li(strong("Decreasing Trend:"), " System variable is declining"),
          tags$li(strong("High Volatility:"), " Large fluctuations suggest instability or external shocks"),
          tags$li(strong("Growth/Decline Phases:"), " Periods of consistent increase or decrease")
        ),

        h5(icon("book"), " Best Practices"),
        tags$ol(
          tags$li("Select meaningful time periods that capture system dynamics"),
          tags$li("Use multiple data points (5+ recommended) for reliable trend detection"),
          tags$li("Compare BOT graphs across different elements to understand relationships"),
          tags$li("Look for tipping points or regime shifts in the data"),
          tags$li("Validate patterns with stakeholder knowledge")
        ),

        footer = modalButton("Close")
      ))
    })

  })
}
