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

  # ========== VALUE BOXES ==========

  # Total Elements Box
  output$total_elements_box <- renderValueBox({
    tryCatch({
      data <- project_data()
      isa_data <- safe_get_nested(data, "data", "isa_data", default = list())

      # Count rows in each DAPSIWRM dataframe
      n_elements <- sum(
        nrow(isa_data$drivers %||% data.frame()),
        nrow(isa_data$activities %||% data.frame()),
        nrow(isa_data$pressures %||% data.frame()),
        nrow(isa_data$marine_processes %||% data.frame()),
        nrow(isa_data$ecosystem_services %||% data.frame()),
        nrow(isa_data$goods_benefits %||% data.frame()),
        nrow(isa_data$responses %||% data.frame()),
        nrow(isa_data$measures %||% data.frame())
      )

      valueBox(n_elements, i18n$t("Total Elements"), icon = icon("circle"), color = "blue")
    }, error = function(e) {
      valueBox(0, "Error", icon = icon("times"), color = "red")
    })
  })

  # Total Connections Box
  output$total_connections_box <- renderValueBox({
    tryCatch({
      data <- project_data()
      n_connections <- 0
      adj_matrices <- safe_get_nested(data, "data", "isa_data", "adjacency_matrices", default = list())

      if(length(adj_matrices) > 0) {
        for(mat_name in names(adj_matrices)) {
          mat <- adj_matrices[[mat_name]]
          if(!is.null(mat) && is.matrix(mat)) {
            n_connections <- n_connections + sum(!is.na(mat) & mat != "", na.rm = TRUE)
          }
        }
      }

      valueBox(n_connections, i18n$t("Connections"), icon = icon("arrow-right"), color = "green")
    }, error = function(e) {
      valueBox(0, "Error", icon = icon("times"), color = "red")
    })
  })

  # Loops Detected Box
  output$loops_detected_box <- renderValueBox({
    tryCatch({
      data <- project_data()
      loops <- safe_get_nested(data, "data", "cld", "loops", default = data.frame())
      n_loops <- if(is.data.frame(loops)) nrow(loops) else 0

      valueBox(n_loops, i18n$t("Loops Detected"), icon = icon("refresh"), color = "orange")
    }, error = function(e) {
      valueBox(0, "Error", icon = icon("times"), color = "red")
    })
  })

  # Completion Box
  output$completion_box <- renderValueBox({
    tryCatch({
      data <- project_data()
      completion <- 0

      # Check if ISA data exists (6 components × 6.67% = 40%)
      isa_score <- 0
      if (!is.null(data$data$isa_data$goods_benefits) && nrow(data$data$isa_data$goods_benefits) > 0) isa_score <- isa_score + 6.67
      if (!is.null(data$data$isa_data$ecosystem_services) && nrow(data$data$isa_data$ecosystem_services) > 0) isa_score <- isa_score + 6.67
      if (!is.null(data$data$isa_data$marine_processes) && nrow(data$data$isa_data$marine_processes) > 0) isa_score <- isa_score + 6.67
      if (!is.null(data$data$isa_data$pressures) && nrow(data$data$isa_data$pressures) > 0) isa_score <- isa_score + 6.67
      if (!is.null(data$data$isa_data$activities) && nrow(data$data$isa_data$activities) > 0) isa_score <- isa_score + 6.67
      if (!is.null(data$data$isa_data$drivers) && nrow(data$data$isa_data$drivers) > 0) isa_score <- isa_score + 6.65
      completion <- completion + isa_score

      # Check if connections exist (30%)
      adj_matrices <- safe_get_nested(data, "data", "isa_data", "adjacency_matrices", default = list())
      n_connections <- 0
      if (length(adj_matrices) > 0) {
        for (mat_name in names(adj_matrices)) {
          mat <- adj_matrices[[mat_name]]
          if (!is.null(mat) && is.matrix(mat)) {
            n_connections <- n_connections + sum(!is.na(mat) & mat != "", na.rm = TRUE)
          }
        }
      }
      if (n_connections > 0) completion <- completion + 30

      # Check if CLD generated (30%)
      if (!is.null(data$data$cld$nodes) && nrow(data$data$cld$nodes) > 0) {
        completion <- completion + 30
      }

      completion <- round(completion)

      valueBox(
        paste0(completion, "%"),
        i18n$t("Completion"),
        icon = icon("check-circle"),
        color = if(completion >= 75) "green" else if(completion >= 40) "yellow" else "purple"
      )
    }, error = function(e) {
      valueBox("0%", "Error", icon = icon("times"), color = "red")
    })
  })

  # ========== PROJECT OVERVIEW ==========

  output$project_overview_ui <- renderUI({
    tryCatch({
      data <- project_data()

      tagList(
      tags$div(style = "word-wrap: break-word; overflow-wrap: break-word;",
        tags$p(style = "margin-bottom: 8px; font-size: 13px;",
          tags$strong(i18n$t("Project ID:")), tags$br(),
          tags$span(style = "color: #666;", data$project_id)
        ),
        tags$p(style = "margin-bottom: 8px; font-size: 13px;",
          tags$strong(i18n$t("Created:")), " ",
          tags$span(style = "color: #666;", format_date_display(data$created_at))
        ),
        tags$p(style = "margin-bottom: 8px; font-size: 13px;",
          tags$strong(i18n$t("Last Modified:")), " ",
          tags$span(style = "color: #666;", format_date_display(data$last_modified))
        ),
        tags$p(style = "margin-bottom: 8px; font-size: 13px;",
          tags$strong(i18n$t("Demonstration Area:")), tags$br(),
          tags$span(style = "color: #666;", data$data$metadata$da_site %||% i18n$t("Not set"))
        ),
        tags$p(style = "margin-bottom: 8px; font-size: 13px;",
          tags$strong(i18n$t("Focal Issue:")), tags$br(),
          tags$span(style = "color: #666;", data$data$metadata$focal_issue %||% i18n$t("Not defined"))
        ),
        tags$hr(style = "margin: 10px 0;"),
        tags$h5(style = "margin-bottom: 8px; font-size: 14px;", i18n$t("DAPSI(W)R(M) Elements")),
        tags$ul(style = "list-style-type: none; padding-left: 5px; margin-bottom: 5px; font-size: 12px;",
          tags$li(style = "margin-bottom: 3px;",
            icon(if(!is.null(data$data$isa_data$drivers) && nrow(data$data$isa_data$drivers) > 0) "check" else "times",
                 class = if(!is.null(data$data$isa_data$drivers) && nrow(data$data$isa_data$drivers) > 0) "text-success" else "text-muted"),
            " ", i18n$t("Drivers:"), " ",
            tags$strong(if(!is.null(data$data$isa_data$drivers)) nrow(data$data$isa_data$drivers) else 0)),
          tags$li(style = "margin-bottom: 3px;",
            icon(if(!is.null(data$data$isa_data$activities) && nrow(data$data$isa_data$activities) > 0) "check" else "times",
                 class = if(!is.null(data$data$isa_data$activities) && nrow(data$data$isa_data$activities) > 0) "text-success" else "text-muted"),
            " ", i18n$t("Activities:"), " ",
            tags$strong(if(!is.null(data$data$isa_data$activities)) nrow(data$data$isa_data$activities) else 0)),
          tags$li(style = "margin-bottom: 3px;",
            icon(if(!is.null(data$data$isa_data$pressures) && nrow(data$data$isa_data$pressures) > 0) "check" else "times",
                 class = if(!is.null(data$data$isa_data$pressures) && nrow(data$data$isa_data$pressures) > 0) "text-success" else "text-muted"),
            " ", i18n$t("Pressures:"), " ",
            tags$strong(if(!is.null(data$data$isa_data$pressures)) nrow(data$data$isa_data$pressures) else 0)),
          tags$li(style = "margin-bottom: 3px;",
            icon(if(!is.null(data$data$isa_data$marine_processes) && nrow(data$data$isa_data$marine_processes) > 0) "check" else "times",
                 class = if(!is.null(data$data$isa_data$marine_processes) && nrow(data$data$isa_data$marine_processes) > 0) "text-success" else "text-muted"),
            " ", i18n$t("States:"), " ",
            tags$strong(if(!is.null(data$data$isa_data$marine_processes)) nrow(data$data$isa_data$marine_processes) else 0)),
          tags$li(style = "margin-bottom: 3px;",
            icon(if(!is.null(data$data$isa_data$ecosystem_services) && nrow(data$data$isa_data$ecosystem_services) > 0) "check" else "times",
                 class = if(!is.null(data$data$isa_data$ecosystem_services) && nrow(data$data$isa_data$ecosystem_services) > 0) "text-success" else "text-muted"),
            " ", i18n$t("Ecosystem Services:"), " ",
            tags$strong(if(!is.null(data$data$isa_data$ecosystem_services)) nrow(data$data$isa_data$ecosystem_services) else 0)),
          tags$li(style = "margin-bottom: 3px;",
            icon(if(!is.null(data$data$isa_data$goods_benefits) && nrow(data$data$isa_data$goods_benefits) > 0) "check" else "times",
                 class = if(!is.null(data$data$isa_data$goods_benefits) && nrow(data$data$isa_data$goods_benefits) > 0) "text-success" else "text-muted"),
            " ", i18n$t("Goods & Benefits:"), " ",
            tags$strong(if(!is.null(data$data$isa_data$goods_benefits)) nrow(data$data$isa_data$goods_benefits) else 0))
        ),
        tags$hr(style = "margin: 10px 0;"),
        tags$p(style = "margin-bottom: 5px; font-size: 13px;",
          tags$strong(i18n$t("CLD Generated:")), " ",
          tags$span(
            style = if(!is.null(data$data$cld$nodes)) "color: #28a745; font-weight: bold;" else "color: #dc3545;",
            if(!is.null(data$data$cld$nodes)) i18n$t("Yes") else i18n$t("No")
          )
        ),
        tags$p(style = "margin-bottom: 5px; font-size: 13px;",
          tags$strong(i18n$t("PIMS Setup:")), " ",
          tags$span(
            style = if(length(data$data$pims) > 0) "color: #28a745;" else "color: #dc3545;",
            if(length(data$data$pims) > 0) i18n$t("Complete") else i18n$t("Incomplete")
          )
        )
      )
    )
    }, error = function(e) {
      cat("\n!!! ERROR in project_overview_ui:\n")
      cat("Error message:", conditionMessage(e), "\n")
      cat("Call stack:\n")
      print(sys.calls())
      # Return error message to UI
      tagList(
        p(style = "color: red;", i18n$t("Error rendering dashboard:"), " ", conditionMessage(e))
      )
    })
  })

  # ========== STATUS SUMMARY RENDERS ==========

  # ISA Elements Status
  output$status_isa_elements <- renderUI({
    data <- project_data()
    n_elements <- sum(
      nrow(data$data$isa_data$drivers %||% data.frame()),
      nrow(data$data$isa_data$activities %||% data.frame()),
      nrow(data$data$isa_data$pressures %||% data.frame()),
      nrow(data$data$isa_data$marine_processes %||% data.frame()),
      nrow(data$data$isa_data$ecosystem_services %||% data.frame()),
      nrow(data$data$isa_data$goods_benefits %||% data.frame()),
      nrow(data$data$isa_data$responses %||% data.frame()),
      nrow(data$data$isa_data$measures %||% data.frame())
    )

    tags$p(style = "margin-bottom: 5px; font-size: 13px;",
      icon(if(n_elements > 0) "check-circle" else "circle",
           class = if(n_elements > 0) "text-success" else "text-muted"),
      " ", strong(n_elements), " ", i18n$t("elements created")
    )
  })

  # ISA Connections Status
  output$status_isa_connections <- renderUI({
    data <- project_data()
    n_connections <- 0
    if (!is.null(data$data$isa_data$adjacency_matrices)) {
      for (matrix_name in names(data$data$isa_data$adjacency_matrices)) {
        mat <- data$data$isa_data$adjacency_matrices[[matrix_name]]
        if (!is.null(mat) && is.matrix(mat)) {
          n_connections <- n_connections + sum(mat != "", na.rm = TRUE)
        }
      }
    }

    tags$p(style = "margin-bottom: 5px; font-size: 13px;",
      icon(if(n_connections > 0) "check-circle" else "circle",
           class = if(n_connections > 0) "text-success" else "text-muted"),
      " ", strong(n_connections), " ", i18n$t("connections defined")
    )
  })

  # CLD Nodes Status
  output$status_cld_nodes <- renderUI({
    data <- project_data()
    n_nodes <- if(!is.null(data$data$cld$nodes)) nrow(data$data$cld$nodes) else 0

    tags$p(style = "margin-bottom: 5px; font-size: 13px;",
      icon(if(n_nodes > 0) "check-circle" else "circle",
           class = if(n_nodes > 0) "text-success" else "text-muted"),
      " ", strong(n_nodes), " ", i18n$t("nodes in CLD")
    )
  })

  # CLD Edges Status
  output$status_cld_edges <- renderUI({
    data <- project_data()
    n_edges <- if(!is.null(data$data$cld$edges)) nrow(data$data$cld$edges) else 0

    tags$p(style = "margin-bottom: 5px; font-size: 13px;",
      icon(if(n_edges > 0) "check-circle" else "circle",
           class = if(n_edges > 0) "text-success" else "text-muted"),
      " ", strong(n_edges), " ", i18n$t("edges in CLD")
    )
  })

  # Analysis Status
  output$status_analysis_complete <- renderUI({
    data <- project_data()
    has_leverage <- !is.null(data$data$cld$nodes) &&
                    any(data$data$cld$nodes$leverage_score > 0, na.rm = TRUE)

    tags$p(style = "margin-bottom: 5px; font-size: 13px;",
      icon(if(has_leverage) "check-circle" else "circle",
           class = if(has_leverage) "text-success" else "text-muted"),
      " ", i18n$t(if(has_leverage) "Leverage analysis complete" else "No analysis performed")
    )
  })
}
