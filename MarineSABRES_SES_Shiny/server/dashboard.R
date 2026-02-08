# server/dashboard.R
# Dashboard rendering logic for the MarineSABRES SES Toolbox
# Extracted from app.R for better maintainability

# ============================================================================
# DASHBOARD RENDERING
# ============================================================================

#' Setup Dashboard Rendering
#'
#' Sets up all dashboard output handlers including value boxes,
#' project overview, and status summaries.
#'
#' @param input Shiny input object
#' @param output Shiny output object
#' @param session Shiny session object
#' @param project_data reactiveVal containing project data
#' @param i18n shiny.i18n translator object
setup_dashboard_rendering <- function(input, output, session, project_data, i18n) {

  # ========== CACHED STATS (shared by value boxes, status, and timeline) ==========
  dashboard_stats <- reactive({
    data <- project_data()
    isa_data <- safe_get_nested(data, "data", "isa_data", default = list())

    n_elements <- sum(
      nrow(isa_data$drivers %||% data.frame()),
      nrow(isa_data$activities %||% data.frame()),
      nrow(isa_data$pressures %||% data.frame()),
      nrow(isa_data$marine_processes %||% data.frame()),
      nrow(isa_data$ecosystem_services %||% data.frame()),
      nrow(isa_data$goods_benefits %||% data.frame()),
      nrow(isa_data$responses %||% data.frame())
    )

    adj_matrices <- safe_get_nested(data, "data", "isa_data", "adjacency_matrices", default = list())
    n_connections <- 0L
    if (length(adj_matrices) > 0) {
      for (mat_name in names(adj_matrices)) {
        mat <- adj_matrices[[mat_name]]
        if (!is.null(mat) && is.matrix(mat)) {
          n_connections <- n_connections + sum(!is.na(mat) & mat != "", na.rm = TRUE)
        }
      }
    }

    n_nodes <- if (!is.null(data$data$cld$nodes)) nrow(data$data$cld$nodes) else 0L
    n_edges <- if (!is.null(data$data$cld$edges)) nrow(data$data$cld$edges) else 0L
    loops <- safe_get_nested(data, "data", "cld", "loops", default = data.frame())
    n_loops <- if (is.data.frame(loops)) nrow(loops) else 0L
    has_leverage <- !is.null(data$data$cld$nodes) &&
      any(data$data$cld$nodes$leverage_score > 0, na.rm = TRUE)

    list(
      n_elements = n_elements,
      n_connections = n_connections,
      n_nodes = n_nodes,
      n_edges = n_edges,
      n_loops = n_loops,
      has_leverage = has_leverage
    )
  })

  # ========== DASHBOARD HEADER ==========
  output$dashboard_header <- renderUI({
    tagList(
      h2(i18n$t("ui.dashboard.title")),
      p(i18n$t("ui.dashboard.subtitle"))
    )
  })

  # ========== VALUE BOXES ==========

  # Total Elements Box
  output$total_elements_box <- renderValueBox({
    tryCatch({
      stats <- dashboard_stats()
      bs4ValueBox(stats$n_elements, i18n$t("ui.dashboard.total_elements"), icon = icon("circle"), color = "primary")
    }, error = function(e) {
      bs4ValueBox(0, "Error", icon = icon("times"), color = "danger")
    })
  })

  # Total Connections Box
  output$total_connections_box <- renderValueBox({
    tryCatch({
      stats <- dashboard_stats()
      bs4ValueBox(stats$n_connections, i18n$t("ui.dashboard.connections"), icon = icon("arrow-right"), color = "success")
    }, error = function(e) {
      bs4ValueBox(0, "Error", icon = icon("times"), color = "danger")
    })
  })

  # Loops Detected Box
  output$loops_detected_box <- renderValueBox({
    tryCatch({
      stats <- dashboard_stats()
      bs4ValueBox(stats$n_loops, i18n$t("ui.dashboard.loops_detected"), icon = icon("refresh"), color = "orange")
    }, error = function(e) {
      bs4ValueBox(0, "Error", icon = icon("times"), color = "danger")
    })
  })

  # Completion Box
  output$completion_box <- renderValueBox({
    tryCatch({
      data <- project_data()
      stats <- dashboard_stats()
      completion <- 0

      # Check if ISA data exists (6 components x 6.67% = 40%)
      isa_score <- 0
      if (!is.null(data$data$isa_data$goods_benefits) && nrow(data$data$isa_data$goods_benefits) > 0) isa_score <- isa_score + 6.67
      if (!is.null(data$data$isa_data$ecosystem_services) && nrow(data$data$isa_data$ecosystem_services) > 0) isa_score <- isa_score + 6.67
      if (!is.null(data$data$isa_data$marine_processes) && nrow(data$data$isa_data$marine_processes) > 0) isa_score <- isa_score + 6.67
      if (!is.null(data$data$isa_data$pressures) && nrow(data$data$isa_data$pressures) > 0) isa_score <- isa_score + 6.67
      if (!is.null(data$data$isa_data$activities) && nrow(data$data$isa_data$activities) > 0) isa_score <- isa_score + 6.67
      if (!is.null(data$data$isa_data$drivers) && nrow(data$data$isa_data$drivers) > 0) isa_score <- isa_score + 6.65
      completion <- completion + isa_score

      # Check if connections exist (30%)
      if (stats$n_connections > 0) completion <- completion + 30

      # Check if CLD generated (30%)
      if (stats$n_nodes > 0) {
        completion <- completion + 30
      }

      completion <- round(completion)

      bs4ValueBox(
        paste0(completion, "%"),
        i18n$t("ui.dashboard.completion"),
        icon = icon("check-circle"),
        color = if(completion >= 75) "success" else if(completion >= 40) "warning" else "secondary"
      )
    }, error = function(e) {
      bs4ValueBox("0%", "Error", icon = icon("times"), color = "danger")
    })
  })

  # ========== PROJECT OVERVIEW ==========

  output$project_overview_ui <- renderUI({
    tryCatch({
      data <- project_data()

      tagList(
      tags$div(style = "word-wrap: break-word; overflow-wrap: break-word;",
        tags$p(style = "margin-bottom: 8px; font-size: 13px;",
          tags$strong(i18n$t("ui.dashboard.project_id")), tags$br(),
          tags$span(style = "color: #666;", data$project_id)
        ),
        tags$p(style = "margin-bottom: 8px; font-size: 13px;",
          tags$strong(i18n$t("ui.dashboard.created")), " ",
          tags$span(style = "color: #666;", format_date_display(data$created_at))
        ),
        tags$p(style = "margin-bottom: 8px; font-size: 13px;",
          tags$strong(i18n$t("ui.dashboard.last_modified")), " ",
          tags$span(style = "color: #666;", format_date_display(data$last_modified))
        ),
        tags$p(style = "margin-bottom: 8px; font-size: 13px;",
          tags$strong(i18n$t("ui.dashboard.demonstration_area")), tags$br(),
          tags$span(style = "color: #666;", data$data$metadata$da_site %||% i18n$t("ui.dashboard.not_set"))
        ),
        tags$p(style = "margin-bottom: 8px; font-size: 13px;",
          tags$strong(i18n$t("ui.dashboard.focal_issue")), tags$br(),
          tags$span(style = "color: #666;", data$data$metadata$focal_issue %||% i18n$t("ui.dashboard.not_defined"))
        ),
        tags$hr(style = "margin: 10px 0;"),
        tags$h5(style = "margin-bottom: 8px; font-size: 14px;", i18n$t("ui.dashboard.dapsiwrm_elements")),
        tags$ul(style = "list-style-type: none; padding-left: 5px; margin-bottom: 5px; font-size: 12px;",
          tags$li(style = "margin-bottom: 3px;",
            icon(if(!is.null(data$data$isa_data$drivers) && nrow(data$data$isa_data$drivers) > 0) "check" else "times",
                 class = if(!is.null(data$data$isa_data$drivers) && nrow(data$data$isa_data$drivers) > 0) "text-success" else "text-muted"),
            " ", i18n$t("modules.response.measures.drivers"), " ",
            tags$strong(if(!is.null(data$data$isa_data$drivers)) nrow(data$data$isa_data$drivers) else 0)),
          tags$li(style = "margin-bottom: 3px;",
            icon(if(!is.null(data$data$isa_data$activities) && nrow(data$data$isa_data$activities) > 0) "check" else "times",
                 class = if(!is.null(data$data$isa_data$activities) && nrow(data$data$isa_data$activities) > 0) "text-success" else "text-muted"),
            " ", i18n$t("modules.response.measures.activities"), " ",
            tags$strong(if(!is.null(data$data$isa_data$activities)) nrow(data$data$isa_data$activities) else 0)),
          tags$li(style = "margin-bottom: 3px;",
            icon(if(!is.null(data$data$isa_data$pressures) && nrow(data$data$isa_data$pressures) > 0) "check" else "times",
                 class = if(!is.null(data$data$isa_data$pressures) && nrow(data$data$isa_data$pressures) > 0) "text-success" else "text-muted"),
            " ", i18n$t("modules.response.measures.pressures"), " ",
            tags$strong(if(!is.null(data$data$isa_data$pressures)) nrow(data$data$isa_data$pressures) else 0)),
          tags$li(style = "margin-bottom: 3px;",
            icon(if(!is.null(data$data$isa_data$marine_processes) && nrow(data$data$isa_data$marine_processes) > 0) "check" else "times",
                 class = if(!is.null(data$data$isa_data$marine_processes) && nrow(data$data$isa_data$marine_processes) > 0) "text-success" else "text-muted"),
            " ", i18n$t("ui.dashboard.states"), " ",
            tags$strong(if(!is.null(data$data$isa_data$marine_processes)) nrow(data$data$isa_data$marine_processes) else 0)),
          tags$li(style = "margin-bottom: 3px;",
            icon(if(!is.null(data$data$isa_data$ecosystem_services) && nrow(data$data$isa_data$ecosystem_services) > 0) "check" else "times",
                 class = if(!is.null(data$data$isa_data$ecosystem_services) && nrow(data$data$isa_data$ecosystem_services) > 0) "text-success" else "text-muted"),
            " ", i18n$t("ui.dashboard.ecosystem_services"), " ",
            tags$strong(if(!is.null(data$data$isa_data$ecosystem_services)) nrow(data$data$isa_data$ecosystem_services) else 0)),
          tags$li(style = "margin-bottom: 3px;",
            icon(if(!is.null(data$data$isa_data$goods_benefits) && nrow(data$data$isa_data$goods_benefits) > 0) "check" else "times",
                 class = if(!is.null(data$data$isa_data$goods_benefits) && nrow(data$data$isa_data$goods_benefits) > 0) "text-success" else "text-muted"),
            " ", i18n$t("ui.dashboard.goods_benefits"), " ",
            tags$strong(if(!is.null(data$data$isa_data$goods_benefits)) nrow(data$data$isa_data$goods_benefits) else 0)),
          tags$li(style = "margin-bottom: 3px;",
            icon(if(!is.null(data$data$isa_data$responses) && nrow(data$data$isa_data$responses) > 0) "check" else "times",
                 class = if(!is.null(data$data$isa_data$responses) && nrow(data$data$isa_data$responses) > 0) "text-success" else "text-muted"),
            " ", i18n$t("ui.dashboard.responses"), " ",
            tags$strong(if(!is.null(data$data$isa_data$responses)) nrow(data$data$isa_data$responses) else 0))
        ),
        tags$hr(style = "margin: 10px 0;"),
        tags$p(style = "margin-bottom: 5px; font-size: 13px;",
          tags$strong(i18n$t("ui.dashboard.cld_generated")), " ",
          tags$span(
            style = if(!is.null(data$data$cld$nodes)) "color: #28a745; font-weight: bold;" else "color: #dc3545;",
            if(!is.null(data$data$cld$nodes)) i18n$t("common.buttons.yes") else i18n$t("common.buttons.no")
          )
        ),
        tags$p(style = "margin-bottom: 5px; font-size: 13px;",
          tags$strong(i18n$t("ui.dashboard.pims_setup")), " ",
          tags$span(
            style = if(length(data$data$pims) > 0) "color: #28a745;" else "color: #dc3545;",
            if(length(data$data$pims) > 0) i18n$t("ui.dashboard.complete") else i18n$t("ui.dashboard.incomplete")
          )
        )
      )
    )
    }, error = function(e) {
      debug_log(paste("ERROR in project_overview_ui:", conditionMessage(e)), "DASHBOARD")
      # Return error message to UI
      tagList(
        p(style = "color: red;", i18n$t("ui.dashboard.error_rendering_dashboard"), " ", conditionMessage(e))
      )
    })
  })

  # ========== STATUS SUMMARY RENDERS ==========

  # ISA Elements Status
  output$status_isa_elements <- renderUI({
    stats <- dashboard_stats()
    tags$p(style = "margin-bottom: 5px; font-size: 13px;",
      icon(if(stats$n_elements > 0) "check-circle" else "circle",
           class = if(stats$n_elements > 0) "text-success" else "text-muted"),
      " ", strong(stats$n_elements), " ", i18n$t("ui.dashboard.elements_created")
    )
  })

  # ISA Connections Status
  output$status_isa_connections <- renderUI({
    stats <- dashboard_stats()
    tags$p(style = "margin-bottom: 5px; font-size: 13px;",
      icon(if(stats$n_connections > 0) "check-circle" else "circle",
           class = if(stats$n_connections > 0) "text-success" else "text-muted"),
      " ", strong(stats$n_connections), " ", i18n$t("ui.dashboard.connections_defined")
    )
  })

  # CLD Nodes Status
  output$status_cld_nodes <- renderUI({
    stats <- dashboard_stats()
    tags$p(style = "margin-bottom: 5px; font-size: 13px;",
      icon(if(stats$n_nodes > 0) "check-circle" else "circle",
           class = if(stats$n_nodes > 0) "text-success" else "text-muted"),
      " ", strong(stats$n_nodes), " ", i18n$t("ui.dashboard.nodes_in_cld")
    )
  })

  # CLD Edges Status
  output$status_cld_edges <- renderUI({
    stats <- dashboard_stats()
    tags$p(style = "margin-bottom: 5px; font-size: 13px;",
      icon(if(stats$n_edges > 0) "check-circle" else "circle",
           class = if(stats$n_edges > 0) "text-success" else "text-muted"),
      " ", strong(stats$n_edges), " ", i18n$t("ui.dashboard.edges_in_cld")
    )
  })

  # Analysis Status
  output$status_analysis_complete <- renderUI({
    stats <- dashboard_stats()
    tags$p(style = "margin-bottom: 5px; font-size: 13px;",
      icon(if(stats$has_leverage) "check-circle" else "circle",
           class = if(stats$has_leverage) "text-success" else "text-muted"),
      " ", i18n$t(if(stats$has_leverage) "ui.dashboard.leverage_analysis_complete" else "ui.dashboard.no_analysis_performed")
    )
  })

  # ========== PROJECT TIMELINE ==========
  output$dashboard_timeline <- renderUI({
    data <- project_data()
    stats <- dashboard_stats()

    # Gather timeline events
    events <- list()

    # Project creation (using metadata or current date)
    creation_date <- data$data$metadata$created %||% Sys.Date()
    events <- c(events, list(list(
      date = creation_date,
      title = i18n$t("ui.dashboard.timeline_project_created"),
      icon = "plus-circle",
      color = "success",
      description = paste(i18n$t("ui.dashboard.timeline_ses_initiated"), format(creation_date, "%B %d, %Y"))
    )))

    # Check if SES data exists
    if (stats$n_elements > 0) {
      events <- c(events, list(list(
        date = data$last_modified %||% Sys.Date(),
        title = i18n$t("ui.dashboard.timeline_ses_framework_created"),
        icon = "layer-group",
        color = "info",
        description = paste(i18n$t("ui.dashboard.timeline_dapsiwrm_established"), stats$n_elements,
                          i18n$t("ui.dashboard.timeline_elements"))
      )))
    }

    # Check if CLD was generated
    if (stats$n_nodes > 0) {
      events <- c(events, list(list(
        date = data$last_modified %||% Sys.Date(),
        title = i18n$t("ui.dashboard.timeline_network_visualization"),
        icon = "project-diagram",
        color = "primary",
        description = paste(i18n$t("ui.dashboard.timeline_cld_generated"), stats$n_nodes,
                          i18n$t("ui.dashboard.timeline_nodes_and"), stats$n_edges,
                          i18n$t("ui.dashboard.timeline_edges"))
      )))
    }

    # Check if analysis was performed
    if (stats$has_leverage) {
      events <- c(events, list(list(
        date = data$last_modified %||% Sys.Date(),
        title = i18n$t("ui.dashboard.timeline_analysis_complete"),
        icon = "chart-line",
        color = "warning",
        description = i18n$t("ui.dashboard.timeline_leverage_calculated")
      )))
    }

    # Build timeline
    if (length(events) == 0) {
      return(p(style = "text-align: center; padding: 20px; color: #999;",
        icon("calendar"), " ", i18n$t("ui.dashboard.timeline_no_events")))
    }

    # Create bs4Timeline
    timeline_items <- lapply(events, function(event) {
      # Ensure event is a list (defensive check)
      if (!is.list(event) || is.null(event)) {
        return(NULL)
      }

      # Extract fields safely with defaults
      event_date <- event[["date"]] %||% Sys.Date()
      event_title <- event[["title"]] %||% "Event"
      event_icon <- event[["icon"]] %||% "circle"
      event_color <- event[["color"]] %||% "gray"
      event_description <- event[["description"]] %||% ""

      bs4TimelineItem(
        elevation = 2,
        time = if(inherits(event_date, "Date") || inherits(event_date, "POSIXt"))
                 format(event_date, "%b %d, %Y") else as.character(event_date),
        title = event_title,
        icon = event_icon,
        color = event_color,
        event_description
      )
    })

    # Remove NULL items (from defensive check above)
    timeline_items <- Filter(Negate(is.null), timeline_items)

    bs4Timeline(
      reversed = FALSE,
      bs4TimelineEnd(color = "gray"),
      do.call(tagList, timeline_items),
      bs4TimelineStart(color = "gray")
    )
  })
}
