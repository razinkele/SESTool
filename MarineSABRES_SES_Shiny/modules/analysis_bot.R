# BOT (Behaviour Over Time) Analysis Module
# Extracted from analysis_tools_module.R
# Analyzes temporal patterns and trends in social-ecological system indicators

analysis_bot_ui <- function(id, i18n) {
  ns <- NS(id)
  tryCatch(shiny.i18n::usei18n(i18n$translator %||% i18n), error = function(e) NULL)  # Enable reactive translation updates

  fluidPage(
    uiOutput(ns("module_header")),

    fluidRow(
      # Left Panel: Data Input and Configuration
      column(4,
        wellPanel(
          h4(icon("database"), " ", i18n$t("modules.analysis.bot.time_series_data")),

          # Element Selection
          selectInput(ns("bot_element"), i18n$t("modules.analysis.bot.select_element"),
                     choices = setNames("", i18n$t("modules.analysis.bot.select_element_placeholder")),
                     width = "100%"),

          # Time Period
          sliderInput(ns("bot_years"), i18n$t("modules.analysis.bot.time_period"),
                     min = 1950, max = 2030, value = c(2000, 2024),
                     step = 1, sep = ""),

          # Data Input Method
          radioButtons(ns("data_input_method"), i18n$t("modules.analysis.bot.data_input_method"),
                      choices = setNames(
                        c("manual", "upload", "isa"),
                        c(i18n$t("modules.analysis.bot.manual_entry"),
                          i18n$t("modules.analysis.bot.upload_csv"),
                          i18n$t("modules.analysis.bot.use_isa_data"))
                      ),
                      selected = "isa"),

          conditionalPanel(
            condition = sprintf("input['%s'] == 'manual'", ns("data_input_method")),
            numericInput(ns("manual_year"), i18n$t("modules.analysis.bot.year"), value = 2024, min = 1950, max = 2030),
            numericInput(ns("manual_value"), i18n$t("modules.analysis.bot.value"), value = 100),
            actionButton(ns("add_datapoint"), i18n$t("modules.analysis.bot.add_data_point"), class = "btn-sm btn-primary")
          ),

          conditionalPanel(
            condition = sprintf("input['%s'] == 'upload'", ns("data_input_method")),
            fileInput(ns("upload_csv"), i18n$t("modules.analysis.bot.upload_csv_label"),
                     accept = c(".csv"))
          ),

          hr(),

          # Analysis Options
          h5(icon("sliders-h"), " ", i18n$t("modules.analysis.bot.analysis_options")),

          checkboxInput(ns("show_trend"), i18n$t("modules.analysis.bot.show_trend"), value = TRUE),
          checkboxInput(ns("show_moving_avg"), i18n$t("modules.analysis.bot.show_moving_avg"), value = FALSE),
          conditionalPanel(
            condition = sprintf("input['%s']", ns("show_moving_avg")),
            sliderInput(ns("moving_avg_window"), i18n$t("modules.analysis.bot.window_size"),
                       min = 2, max = 10, value = 3, step = 1)
          ),

          checkboxInput(ns("detect_patterns"), i18n$t("modules.analysis.bot.detect_patterns"), value = FALSE),

          hr(),
          actionButton(ns("help_bot"), i18n$t("modules.analysis.bot.help"), icon = icon("question-circle"), class = "btn-info btn-sm")
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
            h4(i18n$t("modules.analysis.bot.temporal_pattern_detection")),
            conditionalPanel(
              condition = sprintf("!input['%s']", ns("detect_patterns")),
              p(class = "text-muted", i18n$t("modules.analysis.bot.enable_detect_patterns"))
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
              downloadButton(ns("download_bot_data"), i18n$t("modules.analysis.bot.download_data"), class = "btn-sm"),
              actionButton(ns("clear_data"), i18n$t("modules.analysis.bot.clear_all_data"), class = "btn-sm btn-warning")
            )
          ),

          # Comparison
          tabPanel(icon("exchange-alt"), i18n$t("modules.analysis.bot.tab_scenario_comparison"),
            br(),
            h4(i18n$t("modules.analysis.bot.compare_scenarios")),
            p(i18n$t("modules.analysis.bot.compare_scenarios_desc")),
            p(class = "text-muted", i18n$t("modules.analysis.bot.coming_soon"))
          )
        )
      )
    )
  )
}

analysis_bot_server <- function(id, project_data_reactive, i18n, event_bus = NULL) {
  moduleServer(id, function(input, output, session) {

    ns <- session$ns

    # Reactive values for BOT data
    bot_rv <- reactiveValues(
      current_element = NULL,
      timeseries_data = data.frame(Year = integer(), Value = numeric())
    )

    # Listen for ISA changes via event bus to flag stale results
    observe({
      req(!is.null(event_bus))
      event_bus$on_isa_change()
      if (nrow(isolate(bot_rv$timeseries_data)) > 0) {
        showNotification(
          i18n$t("modules.analysis.common.data_changed_rerun"),
          type = "warning",
          duration = 5,
          id = ns("stale_data")
        )
      }
    })

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
        showNotification(format_user_error(e, i18n = i18n, context_key = "common.messages.context_loading_csv_data"), type = "error")
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
        actual_label <- i18n$t("modules.analysis.bot.chart.actual")
        trend_label <- i18n$t("modules.analysis.bot.chart.trend")
        names(combined) <- c(actual_label, trend_label)

        dg <- dygraph(combined) %>%
          dySeries(actual_label, color = "#2196F3", strokeWidth = 2, drawPoints = TRUE, pointSize = 4) %>%
          dySeries(trend_label, color = "#FF5722", strokeWidth = 2, strokePattern = "dashed") %>%
          dyRangeSelector() %>%
          dyHighlight(highlightCircleSize = 5)
      }

      # Add moving average if requested
      if(input$show_moving_avg && nrow(ts_data) > input$moving_avg_window) {
        ma_values <- stats::filter(ts_data$Value, rep(1/input$moving_avg_window, input$moving_avg_window), sides = 2)
        ma_xts <- xts::xts(ma_values, order.by = as.Date(paste0(ts_data$Year, "-01-01")))
        actual_label <- i18n$t("modules.analysis.bot.chart.actual")
        trend_label <- i18n$t("modules.analysis.bot.chart.trend")
        ma_label <- i18n$t("modules.analysis.bot.chart.moving_avg")

        if(input$show_trend) {
          combined <- merge(combined, ma_xts)
          names(combined) <- c(actual_label, trend_label, ma_label)
          dg <- dygraph(combined) %>%
            dySeries(actual_label, color = "#2196F3", strokeWidth = 2, drawPoints = TRUE, pointSize = 4) %>%
            dySeries(trend_label, color = "#FF5722", strokeWidth = 2, strokePattern = "dashed") %>%
            dySeries(ma_label, color = "#4CAF50", strokeWidth = 2) %>%
            dyRangeSelector()
        } else {
          combined <- merge(ts_xts, ma_xts)
          names(combined) <- c(actual_label, ma_label)
          dg <- dygraph(combined) %>%
            dySeries(actual_label, color = "#2196F3", strokeWidth = 2, drawPoints = TRUE, pointSize = 4) %>%
            dySeries(ma_label, color = "#4CAF50", strokeWidth = 2) %>%
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
        sprintf("%s: %d", i18n$t("modules.analysis.bot.stats.num_observations"), nrow(ts_data)),
        sprintf("%s: %d - %d", i18n$t("modules.analysis.bot.stats.time_period"), min(ts_data$Year), max(ts_data$Year)),
        sprintf("%s: %.2f", i18n$t("modules.analysis.bot.stats.mean_value"), mean(ts_data$Value, na.rm = TRUE)),
        sprintf("%s: %.2f", i18n$t("modules.analysis.bot.stats.std_deviation"), sd(ts_data$Value, na.rm = TRUE)),
        sprintf("%s: %.2f (%s %d)", i18n$t("modules.analysis.bot.stats.min_value"), min(ts_data$Value), i18n$t("modules.analysis.bot.stats.year"), ts_data$Year[which.min(ts_data$Value)]),
        sprintf("%s: %.2f (%s %d)", i18n$t("modules.analysis.bot.stats.max_value"), max(ts_data$Value), i18n$t("modules.analysis.bot.stats.year"), ts_data$Year[which.max(ts_data$Value)]),
        sep = "\n"
      )

      # Add trend info if enabled
      if(input$show_trend && nrow(ts_data) > 2) {
        lm_fit <- lm(Value ~ Year, data = ts_data)
        slope <- coef(lm_fit)[2]
        r_squared <- summary(lm_fit)$r.squared

        trend_direction <- if(slope > 0) i18n$t("modules.analysis.bot.stats.increasing") else if(slope < 0) i18n$t("modules.analysis.bot.stats.decreasing") else i18n$t("modules.analysis.bot.stats.stable")

        stats_text <- paste(
          stats_text,
          "",
          paste0(i18n$t("modules.analysis.bot.stats.trend_analysis"), ":"),
          sprintf("  %s: %s", i18n$t("modules.analysis.bot.stats.direction"), trend_direction),
          sprintf("  %s: %.2f %s", i18n$t("modules.analysis.bot.stats.rate_of_change"), slope, i18n$t("modules.analysis.bot.stats.units_per_year")),
          sprintf("  %s: %.3f", i18n$t("modules.analysis.bot.stats.r_squared"), r_squared),
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
              icon("arrow-up"), strong(paste0(" ", i18n$t("modules.analysis.bot.pattern.increasing_trend"))),
              p(sprintf(i18n$t("modules.analysis.bot.pattern.increasing_trend_desc"), slope))
            )))
          } else {
            patterns <- c(patterns, list(tags$div(
              class = "alert alert-warning",
              icon("arrow-down"), strong(paste0(" ", i18n$t("modules.analysis.bot.pattern.decreasing_trend"))),
              p(sprintf(i18n$t("modules.analysis.bot.pattern.decreasing_trend_desc"), abs(slope)))
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
            icon("exclamation-triangle"), strong(paste0(" ", i18n$t("modules.analysis.bot.pattern.high_volatility"))),
            p(sprintf(i18n$t("modules.analysis.bot.pattern.high_volatility_desc"), cv))
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
            icon("chart-line"), strong(paste0(" ", i18n$t("modules.analysis.bot.pattern.growth_phase"))),
            p(sprintf(i18n$t("modules.analysis.bot.pattern.growth_phase_desc"), growth_phases, decline_phases))
          )))
        } else if(decline_phases > growth_phases * 2) {
          patterns <- c(patterns, list(tags$div(
            class = "alert alert-warning",
            icon("chart-line"), strong(paste0(" ", i18n$t("modules.analysis.bot.pattern.decline_phase"))),
            p(sprintf(i18n$t("modules.analysis.bot.pattern.decline_phase_desc"), decline_phases, growth_phases))
          )))
        }
      }

      if(length(patterns) == 0) {
        return(tags$div(
          class = "alert alert-secondary",
          icon("info-circle"), " ", i18n$t("modules.analysis.bot.pattern.no_patterns")
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
        title = i18n$t("modules.analysis.bot.help_title"),
        size = "l",
        easyClose = TRUE,

        h4(icon("info-circle"), " ", i18n$t("modules.analysis.bot.help_what_is")),
        p(i18n$t("modules.analysis.bot.help_description")),

        h5(icon("chart-line"), " ", i18n$t("modules.analysis.bot.help_features")),
        tags$ul(
          tags$li(strong(i18n$t("modules.analysis.bot.help_feature_timeseries")), " ", i18n$t("modules.analysis.bot.help_feature_timeseries_desc")),
          tags$li(strong(i18n$t("modules.analysis.bot.help_feature_trend")), " ", i18n$t("modules.analysis.bot.help_feature_trend_desc")),
          tags$li(strong(i18n$t("modules.analysis.bot.help_feature_moving_avg")), " ", i18n$t("modules.analysis.bot.help_feature_moving_avg_desc")),
          tags$li(strong(i18n$t("modules.analysis.bot.help_feature_pattern")), " ", i18n$t("modules.analysis.bot.help_feature_pattern_desc")),
          tags$li(strong(i18n$t("modules.analysis.bot.help_feature_sources")), " ", i18n$t("modules.analysis.bot.help_feature_sources_desc"))
        ),

        h5(icon("lightbulb"), " ", i18n$t("modules.analysis.bot.help_interpreting")),
        tags$ul(
          tags$li(strong(i18n$t("modules.analysis.bot.help_increasing")), " ", i18n$t("modules.analysis.bot.help_increasing_desc")),
          tags$li(strong(i18n$t("modules.analysis.bot.help_decreasing")), " ", i18n$t("modules.analysis.bot.help_decreasing_desc")),
          tags$li(strong(i18n$t("modules.analysis.bot.help_volatility")), " ", i18n$t("modules.analysis.bot.help_volatility_desc")),
          tags$li(strong(i18n$t("modules.analysis.bot.help_phases")), " ", i18n$t("modules.analysis.bot.help_phases_desc"))
        ),

        h5(icon("book"), " ", i18n$t("modules.analysis.bot.help_best_practices")),
        tags$ol(
          tags$li(i18n$t("modules.analysis.bot.help_practice_1")),
          tags$li(i18n$t("modules.analysis.bot.help_practice_2")),
          tags$li(i18n$t("modules.analysis.bot.help_practice_3")),
          tags$li(i18n$t("modules.analysis.bot.help_practice_4")),
          tags$li(i18n$t("modules.analysis.bot.help_practice_5"))
        ),

        footer = modalButton(i18n$t("common.buttons.close"))
      ))
    })

  })
}
