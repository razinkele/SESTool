# modules/scenario_builder_module.R
# Scenario Builder Module for MarineSABRES SES Shiny Application
# Implements what-if analysis, impact prediction, and scenario comparison

# ============================================================================
# SCENARIO BUILDER UI
# ============================================================================

scenario_builder_ui <- function(id, i18n) {
  ns <- NS(id)

  fluidPage(
    tags$head(
      tags$style(HTML("
        .scenario-card {
          border: 1px solid #ddd;
          border-radius: 4px;
          padding: 15px;
          margin-bottom: 15px;
          background-color: #f9f9f9;
        }
        .scenario-card:hover {
          background-color: #f0f0f0;
          box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        .scenario-active {
          border-left: 4px solid #3c8dbc;
          background-color: #e8f4f8;
        }
        .scenario-header {
          display: flex;
          justify-content: space-between;
          align-items: center;
          margin-bottom: 10px;
        }
        .scenario-title {
          font-weight: bold;
          font-size: 16px;
        }
        .scenario-description {
          color: #666;
          font-size: 14px;
          margin-bottom: 5px;
        }
        .scenario-meta {
          color: #999;
          font-size: 12px;
        }
        .modification-badge {
          display: inline-block;
          padding: 2px 8px;
          margin: 2px;
          border-radius: 3px;
          font-size: 11px;
          background-color: #e0e0e0;
        }
        .modification-badge.node-added {
          background-color: #d4edda;
          color: #155724;
        }
        .modification-badge.node-removed {
          background-color: #f8d7da;
          color: #721c24;
        }
        .modification-badge.link-added {
          background-color: #d1ecf1;
          color: #0c5460;
        }
        .modification-badge.link-removed {
          background-color: #fff3cd;
          color: #856404;
        }
        .impact-positive {
          color: #28a745;
          font-weight: bold;
        }
        .impact-negative {
          color: #dc3545;
          font-weight: bold;
        }
        .impact-neutral {
          color: #6c757d;
        }
      "))
    ),

    h2(icon("flask"), " ", i18n$t("scenario_builder_title")),
    p(i18n$t("scenario_builder_description")),
    hr(),

    # Check if CLD exists
    uiOutput(ns("cld_check_ui")),

    # Main scenario builder interface (shown only if CLD exists)
    uiOutput(ns("scenario_builder_main"))
  )
}

# ============================================================================
# SCENARIO BUILDER SERVER
# ============================================================================

scenario_builder_server <- function(id, project_data_reactive, i18n) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # Reactive values to store scenarios
    scenarios <- reactiveVal(list())
    active_scenario_id <- reactiveVal(NULL)

    # Initialize scenarios from project data
    observe({
      req(project_data_reactive())
      data <- project_data_reactive()

      if (!is.null(data$data$scenarios)) {
        scenarios(data$data$scenarios)
      }
    })

    # Check if CLD exists
    output$cld_check_ui <- renderUI({
      req(project_data_reactive())
      data <- project_data_reactive()

      if (is.null(data$data$cld$nodes) || nrow(data$data$cld$nodes) == 0) {
        div(
          class = "alert alert-warning",
          icon("exclamation-triangle"),
          tags$strong(" ", i18n$t("scenario_no_cld_found")),
          tags$p(i18n$t("scenario_need_cld_first")),
          tags$p(i18n$t("scenario_go_to_cld_module"))
        )
      } else {
        NULL
      }
    })

    # Main scenario builder interface
    output$scenario_builder_main <- renderUI({
      req(project_data_reactive())
      data <- project_data_reactive()

      # Only show if CLD exists
      if (is.null(data$data$cld$nodes) || nrow(data$data$cld$nodes) == 0) {
        return(NULL)
      }

      fluidRow(
        # Left panel: Scenario management
        column(4,
          wellPanel(
            h4(icon("list"), " ", i18n$t("scenario_scenarios")),
            actionButton(ns("create_scenario"), i18n$t("scenario_new_scenario"),
                        icon = icon("plus"), class = "btn-success btn-block"),
            br(), br(),
            uiOutput(ns("scenarios_list"))
          )
        ),

        # Right panel: Scenario editor
        column(8,
          conditionalPanel(
            condition = sprintf("output['%s']", ns("has_active_scenario")),
            ns = ns,

            tabsetPanel(id = ns("scenario_tabs"),
              # Tab 1: Configure
              tabPanel(i18n$t("scenario_configure"),
                icon = icon("cog"),
                br(),
                uiOutput(ns("configure_scenario_ui"))
              ),

              # Tab 2: Impact Analysis
              tabPanel(i18n$t("scenario_impact_analysis"),
                icon = icon("chart-line"),
                br(),
                uiOutput(ns("impact_analysis_ui"))
              ),

              # Tab 3: Compare
              tabPanel(i18n$t("scenario_compare_scenarios"),
                icon = icon("balance-scale"),
                br(),
                uiOutput(ns("compare_scenarios_ui"))
              )
            )
          ),

          # Message when no scenario is selected
          conditionalPanel(
            condition = sprintf("!output['%s']", ns("has_active_scenario")),
            ns = ns,
            div(
              class = "alert alert-info",
              style = "margin-top: 20px;",
              icon("info-circle"),
              " ", i18n$t("scenario_select_or_create")
            )
          )
        )
      )
    })

    # Helper output for conditional panel
    output$has_active_scenario <- reactive({
      !is.null(active_scenario_id())
    })
    outputOptions(output, "has_active_scenario", suspendWhenHidden = FALSE)

    # ========================================================================
    # SCENARIO MANAGEMENT
    # ========================================================================

    # Render scenarios list
    output$scenarios_list <- renderUI({
      scenario_list <- scenarios()
      active_id <- active_scenario_id()

      if (length(scenario_list) == 0) {
        return(p(class = "text-muted", i18n$t("scenario_no_scenarios_yet")))
      }

      lapply(seq_along(scenario_list), function(i) {
        scenario <- scenario_list[[i]]
        is_active <- !is.null(active_id) && scenario$id == active_id

        div(
          class = paste("scenario-card", if(is_active) "scenario-active" else ""),
          onclick = sprintf("Shiny.setInputValue('%s', '%s', {priority: 'event'})",
                          ns("select_scenario"), scenario$id),
          style = "cursor: pointer;",

          div(class = "scenario-header",
            span(class = "scenario-title", scenario$name),
            actionButton(ns(paste0("delete_scenario_", scenario$id)), "",
                        icon = icon("trash"),
                        class = "btn-xs btn-danger",
                        onclick = sprintf("event.stopPropagation(); Shiny.setInputValue('%s', '%s', {priority: 'event'})",
                                        ns("delete_scenario"), scenario$id))
          ),
          div(class = "scenario-description", scenario$description),
          div(class = "scenario-meta",
            icon("calendar"), format(scenario$created, "%Y-%m-%d %H:%M"),
            " | ",
            icon("edit"),
            length(scenario$modifications$nodes_added) +
            length(scenario$modifications$nodes_removed) +
            length(scenario$modifications$links_added) +
            length(scenario$modifications$links_removed),
            " ", i18n$t("scenario_changes")
          )
        )
      })
    })

    # Create new scenario
    observeEvent(input$create_scenario, {
      showModal(modalDialog(
        title = i18n$t("scenario_create_new_scenario"),
        size = "m",
        footer = tagList(
          modalButton(i18n$t("cancel")),
          actionButton(ns("confirm_create_scenario"), i18n$t("create"), class = "btn-primary")
        ),

        textInput(ns("new_scenario_name"), i18n$t("scenario_scenario_name"),
                 placeholder = i18n$t("scenario_name_placeholder")),
        textAreaInput(ns("new_scenario_description"), i18n$t("scenario_description"),
                     placeholder = i18n$t("scenario_description_placeholder"),
                     rows = 4)
      ))
    })

    # Confirm create scenario
    observeEvent(input$confirm_create_scenario, {
      req(input$new_scenario_name)

      new_scenario <- list(
        id = paste0("scenario_", as.integer(Sys.time())),
        name = input$new_scenario_name,
        description = input$new_scenario_description,
        created = Sys.time(),
        modified = Sys.time(),
        modifications = list(
          nodes_added = list(),
          nodes_removed = c(),
          nodes_modified = list(),
          links_added = list(),
          links_removed = c(),
          links_modified = list()
        ),
        results = NULL
      )

      scenario_list <- scenarios()
      scenario_list[[length(scenario_list) + 1]] <- new_scenario
      scenarios(scenario_list)

      # Set as active
      active_scenario_id(new_scenario$id)

      # Save to project data
      save_scenarios_to_project()

      removeModal()
      showNotification(i18n$t("scenario_created_successfully"), type = "message")
    })

    # Select scenario
    observeEvent(input$select_scenario, {
      active_scenario_id(input$select_scenario)
    })

    # Delete scenario
    observeEvent(input$delete_scenario, {
      scenario_id <- input$delete_scenario

      showModal(modalDialog(
        title = i18n$t("scenario_confirm_delete"),
        i18n$t("scenario_confirm_delete_message"),
        footer = tagList(
          modalButton(i18n$t("cancel")),
          actionButton(ns("confirm_delete_scenario"), i18n$t("delete"), class = "btn-danger")
        )
      ))

      # Store ID for confirmation
      session$userData$scenario_to_delete <- scenario_id
    })

    # Confirm delete
    observeEvent(input$confirm_delete_scenario, {
      scenario_id <- session$userData$scenario_to_delete

      scenario_list <- scenarios()
      scenario_list <- scenario_list[sapply(scenario_list, function(s) s$id != scenario_id)]
      scenarios(scenario_list)

      # Clear active if deleted
      if (!is.null(active_scenario_id()) && active_scenario_id() == scenario_id) {
        active_scenario_id(NULL)
      }

      save_scenarios_to_project()
      removeModal()
      showNotification(i18n$t("scenario_deleted"), type = "message")
    })

    # ========================================================================
    # CONFIGURE SCENARIO TAB
    # ========================================================================

    output$configure_scenario_ui <- renderUI({
      req(active_scenario_id())
      active_scenario <- get_active_scenario()
      req(active_scenario)

      tagList(
        h4(icon("cog"), " ", i18n$t("scenario_configure"), ": ", active_scenario$name),
        p(class = "text-muted", active_scenario$description),
        hr(),

        fluidRow(
          column(6,
            wellPanel(
              h5(icon("circle-plus"), " ", i18n$t("scenario_add_modify_nodes")),
              actionButton(ns("add_node"), i18n$t("scenario_add_new_node"),
                          icon = icon("plus"), class = "btn-success btn-sm"),
              br(), br(),
              uiOutput(ns("added_nodes_list"))
            ),

            wellPanel(
              h5(icon("circle-minus"), " ", i18n$t("scenario_remove_nodes")),
              selectInput(ns("node_to_remove"), i18n$t("scenario_select_node_to_remove"),
                         choices = NULL),
              actionButton(ns("remove_node"), i18n$t("scenario_remove_node"),
                          icon = icon("trash"), class = "btn-danger btn-sm")
            )
          ),

          column(6,
            wellPanel(
              h5(icon("arrow-right"), " ", i18n$t("scenario_add_modify_links")),
              actionButton(ns("add_link"), i18n$t("scenario_add_new_link"),
                          icon = icon("plus"), class = "btn-success btn-sm"),
              br(), br(),
              uiOutput(ns("added_links_list"))
            ),

            wellPanel(
              h5(icon("link-slash"), " ", i18n$t("scenario_remove_links")),
              selectInput(ns("link_to_remove"), i18n$t("scenario_select_link_to_remove"),
                         choices = NULL),
              actionButton(ns("remove_link"), i18n$t("scenario_remove_link"),
                          icon = icon("trash"), class = "btn-danger btn-sm")
            )
          )
        ),

        hr(),
        div(style = "text-align: center;",
          actionButton(ns("preview_scenario"), i18n$t("scenario_preview_network"),
                      icon = icon("eye"), class = "btn-primary"),
          actionButton(ns("run_impact_analysis"), i18n$t("scenario_run_impact_analysis"),
                      icon = icon("play"), class = "btn-success")
        )
      )
    })

    # Update node removal choices
    observe({
      req(project_data_reactive())
      data <- project_data_reactive()
      req(data$data$cld$nodes)

      active_scenario <- get_active_scenario()
      if (!is.null(active_scenario)) {
        # Get nodes not already removed
        available_nodes <- setdiff(data$data$cld$nodes$id,
                                   active_scenario$modifications$nodes_removed)

        choices <- setNames(available_nodes,
                          data$data$cld$nodes$label[match(available_nodes, data$data$cld$nodes$id)])

        updateSelectInput(session, "node_to_remove", choices = c(setNames("", i18n$t("select")), choices))
      }
    })

    # Update link removal choices
    observe({
      req(project_data_reactive())
      data <- project_data_reactive()
      req(data$data$cld$edges)

      active_scenario <- get_active_scenario()
      if (!is.null(active_scenario)) {
        # Get links not already removed
        removed_links <- active_scenario$modifications$links_removed
        available_links <- data$data$cld$edges

        if (length(removed_links) > 0) {
          available_links <- available_links[!available_links$id %in% removed_links, ]
        }

        if (nrow(available_links) > 0) {
          link_labels <- paste(available_links$from_label, "→", available_links$to_label)
          choices <- setNames(available_links$id, link_labels)
          updateSelectInput(session, "link_to_remove", choices = c(setNames("", i18n$t("select")), choices))
        }
      }
    })

    # Add node dialog
    observeEvent(input$add_node, {
      showModal(modalDialog(
        title = i18n$t("scenario_add_new_node"),
        size = "m",
        footer = tagList(
          modalButton(i18n$t("cancel")),
          actionButton(ns("confirm_add_node"), i18n$t("add"), class = "btn-primary")
        ),

        textInput(ns("new_node_label"), i18n$t("scenario_node_label"),
                 placeholder = i18n$t("scenario_node_label_placeholder")),
        selectInput(ns("new_node_dapsi"), i18n$t("scenario_dapsi_category"),
                   choices = c("", i18n$t("driver"), i18n$t("activity"), i18n$t("pressure"), i18n$t("state"),
                             i18n$t("impact"), i18n$t("welfare"), i18n$t("response"), i18n$t("management"))),
        textAreaInput(ns("new_node_description"), i18n$t("scenario_description"), rows = 3)
      ))
    })

    # Confirm add node
    observeEvent(input$confirm_add_node, {
      req(input$new_node_label)

      active_scenario <- get_active_scenario()
      req(active_scenario)

      new_node <- list(
        id = paste0("scenario_node_", as.integer(Sys.time() * 1000)),
        label = input$new_node_label,
        dapsi = input$new_node_dapsi,
        description = input$new_node_description
      )

      # Add to scenario modifications
      scenario_list <- scenarios()
      idx <- which(sapply(scenario_list, function(s) s$id == active_scenario$id))
      scenario_list[[idx]]$modifications$nodes_added[[length(scenario_list[[idx]]$modifications$nodes_added) + 1]] <- new_node
      scenario_list[[idx]]$modified <- Sys.time()
      scenarios(scenario_list)

      save_scenarios_to_project()
      removeModal()
      showNotification(i18n$t("scenario_node_added"), type = "message")
    })

    # Remove node
    observeEvent(input$remove_node, {
      req(input$node_to_remove)
      req(input$node_to_remove != "")

      active_scenario <- get_active_scenario()
      req(active_scenario)

      scenario_list <- scenarios()
      idx <- which(sapply(scenario_list, function(s) s$id == active_scenario$id))
      scenario_list[[idx]]$modifications$nodes_removed <- c(
        scenario_list[[idx]]$modifications$nodes_removed,
        input$node_to_remove
      )
      scenario_list[[idx]]$modified <- Sys.time()
      scenarios(scenario_list)

      save_scenarios_to_project()
      showNotification(i18n$t("scenario_node_marked_for_removal"), type = "message")
    })

    # Add link dialog
    observeEvent(input$add_link, {
      req(project_data_reactive())
      data <- project_data_reactive()
      req(data$data$cld$nodes)

      # Get all available nodes (baseline + added in scenario)
      active_scenario <- get_active_scenario()
      base_nodes <- data$data$cld$nodes$id
      added_nodes <- sapply(active_scenario$modifications$nodes_added, function(n) n$id)
      all_nodes <- c(base_nodes, added_nodes)

      base_labels <- setNames(data$data$cld$nodes$label, data$data$cld$nodes$id)
      added_labels <- setNames(
        sapply(active_scenario$modifications$nodes_added, function(n) n$label),
        sapply(active_scenario$modifications$nodes_added, function(n) n$id)
      )
      all_labels <- c(base_labels, added_labels)

      showModal(modalDialog(
        title = i18n$t("scenario_add_new_link"),
        size = "m",
        footer = tagList(
          modalButton(i18n$t("cancel")),
          actionButton(ns("confirm_add_link"), i18n$t("add"), class = "btn-primary")
        ),

        selectInput(ns("new_link_from"), i18n$t("scenario_from_node"),
                   choices = all_labels),
        selectInput(ns("new_link_to"), i18n$t("scenario_to_node"),
                   choices = all_labels),
        selectInput(ns("new_link_polarity"), i18n$t("scenario_polarity"),
                   choices = c(setNames("+", i18n$t("scenario_positive")), setNames("-", i18n$t("scenario_negative"))))
      ))
    })

    # Confirm add link
    observeEvent(input$confirm_add_link, {
      req(input$new_link_from, input$new_link_to)

      if (input$new_link_from == input$new_link_to) {
        showNotification(i18n$t("scenario_cannot_create_self_loop"), type = "error")
        return()
      }

      active_scenario <- get_active_scenario()
      req(active_scenario)

      new_link <- list(
        id = paste0("scenario_link_", as.integer(Sys.time() * 1000)),
        from = input$new_link_from,
        to = input$new_link_to,
        polarity = input$new_link_polarity
      )

      scenario_list <- scenarios()
      idx <- which(sapply(scenario_list, function(s) s$id == active_scenario$id))
      scenario_list[[idx]]$modifications$links_added[[length(scenario_list[[idx]]$modifications$links_added) + 1]] <- new_link
      scenario_list[[idx]]$modified <- Sys.time()
      scenarios(scenario_list)

      save_scenarios_to_project()
      removeModal()
      showNotification(i18n$t("scenario_link_added"), type = "message")
    })

    # Remove link
    observeEvent(input$remove_link, {
      req(input$link_to_remove)
      req(input$link_to_remove != "")

      active_scenario <- get_active_scenario()
      req(active_scenario)

      scenario_list <- scenarios()
      idx <- which(sapply(scenario_list, function(s) s$id == active_scenario$id))
      scenario_list[[idx]]$modifications$links_removed <- c(
        scenario_list[[idx]]$modifications$links_removed,
        input$link_to_remove
      )
      scenario_list[[idx]]$modified <- Sys.time()
      scenarios(scenario_list)

      save_scenarios_to_project()
      showNotification(i18n$t("scenario_link_marked_for_removal"), type = "message")
    })

    # Display added nodes
    output$added_nodes_list <- renderUI({
      active_scenario <- get_active_scenario()
      req(active_scenario)

      added_nodes <- active_scenario$modifications$nodes_added
      removed_nodes <- active_scenario$modifications$nodes_removed

      if (length(added_nodes) == 0 && length(removed_nodes) == 0) {
        return(p(class = "text-muted", style = "font-size: 12px;", i18n$t("scenario_no_modifications_yet")))
      }

      tagList(
        if (length(added_nodes) > 0) {
          lapply(added_nodes, function(node) {
            span(class = "modification-badge node-added",
                icon("plus"), " ", node$label)
          })
        },
        if (length(removed_nodes) > 0) {
          req(project_data_reactive())
          data <- project_data_reactive()
          lapply(removed_nodes, function(node_id) {
            label <- data$data$cld$nodes$label[data$data$cld$nodes$id == node_id]
            span(class = "modification-badge node-removed",
                icon("minus"), " ", label)
          })
        }
      )
    })

    # Display added links
    output$added_links_list <- renderUI({
      active_scenario <- get_active_scenario()
      req(active_scenario)

      added_links <- active_scenario$modifications$links_added
      removed_links <- active_scenario$modifications$links_removed

      if (length(added_links) == 0 && length(removed_links) == 0) {
        return(p(class = "text-muted", style = "font-size: 12px;", i18n$t("scenario_no_modifications_yet")))
      }

      req(project_data_reactive())
      data <- project_data_reactive()

      tagList(
        if (length(added_links) > 0) {
          lapply(added_links, function(link) {
            from_label <- get_node_label(link$from, data, active_scenario)
            to_label <- get_node_label(link$to, data, active_scenario)
            span(class = "modification-badge link-added",
                icon("arrow-right"), " ", from_label, " → ", to_label,
                " (", link$polarity, ")")
          })
        },
        if (length(removed_links) > 0) {
          lapply(removed_links, function(link_id) {
            edge <- data$data$cld$edges[data$data$cld$edges$id == link_id, ]
            if (nrow(edge) > 0) {
              span(class = "modification-badge link-removed",
                  icon("times"), " ", edge$from_label, " → ", edge$to_label)
            }
          })
        }
      )
    })

    # ========================================================================
    # IMPACT ANALYSIS TAB
    # ========================================================================

    output$impact_analysis_ui <- renderUI({
      req(active_scenario_id())
      active_scenario <- get_active_scenario()
      req(active_scenario)

      # Check if analysis has been run
      if (is.null(active_scenario$results)) {
        return(
          div(
            class = "alert alert-info",
            icon("info-circle"),
            tags$strong(" ", i18n$t("scenario_impact_analysis_not_run")),
            tags$p(i18n$t("scenario_click_run_impact_analysis"))
          )
        )
      }

      results <- active_scenario$results

      tagList(
        h4(icon("chart-line"), " ", i18n$t("scenario_impact_analysis"), ": ", active_scenario$name),
        hr(),

        # Summary metrics
        fluidRow(
          column(3,
            div(class = "info-box bg-aqua",
              div(class = "info-box-icon", icon("circle-nodes")),
              div(class = "info-box-content",
                span(class = "info-box-text", i18n$t("scenario_total_nodes")),
                span(class = "info-box-number", results$network_stats$total_nodes)
              )
            )
          ),
          column(3,
            div(class = "info-box bg-green",
              div(class = "info-box-icon", icon("arrow-right")),
              div(class = "info-box-content",
                span(class = "info-box-text", i18n$t("scenario_total_links")),
                span(class = "info-box-number", results$network_stats$total_links)
              )
            )
          ),
          column(3,
            div(class = "info-box bg-yellow",
              div(class = "info-box-icon", icon("arrows-spin")),
              div(class = "info-box-content",
                span(class = "info-box-text", i18n$t("scenario_feedback_loops")),
                span(class = "info-box-number", results$network_stats$total_loops)
              )
            )
          ),
          column(3,
            div(class = "info-box bg-red",
              div(class = "info-box-icon", icon("triangle-exclamation")),
              div(class = "info-box-content",
                span(class = "info-box-text", i18n$t("scenario_changed_nodes")),
                span(class = "info-box-number", results$impact_summary$nodes_affected)
              )
            )
          )
        ),

        br(),

        # Detailed impact analysis
        fluidRow(
          column(6,
            wellPanel(
              h5(icon("chart-bar"), " ", i18n$t("scenario_network_topology_changes")),
              DTOutput(ns("topology_changes_table"))
            )
          ),
          column(6,
            wellPanel(
              h5(icon("arrows-split-up-and-left"), " ", i18n$t("scenario_affected_feedback_loops")),
              uiOutput(ns("affected_loops_list"))
            )
          )
        ),

        br(),

        # Impact predictions
        wellPanel(
          h5(icon("lightbulb"), " ", i18n$t("scenario_predicted_impacts")),
          DTOutput(ns("impact_predictions_table"))
        )
      )
    })

    # Run impact analysis
    observeEvent(input$run_impact_analysis, {
      req(active_scenario_id())
      active_scenario <- get_active_scenario()
      req(active_scenario)
      req(project_data_reactive())

      withProgress(message = i18n$t("scenario_running_impact_analysis"), {

        # Apply scenario modifications to baseline CLD
        modified_network <- apply_scenario_modifications(
          project_data_reactive()$data$cld,
          active_scenario$modifications
        )

        setProgress(0.3, detail = i18n$t("scenario_analyzing_network_topology"))

        # Calculate network metrics
        network_stats <- calculate_network_stats(modified_network)

        setProgress(0.6, detail = i18n$t("scenario_detecting_feedback_loops"))

        # Detect loops
        loops <- detect_feedback_loops(modified_network)

        setProgress(0.8, detail = i18n$t("scenario_predicting_impacts"))

        # Predict impacts
        impact_predictions <- predict_impacts(
          baseline = project_data_reactive()$data$cld,
          scenario = modified_network,
          modifications = active_scenario$modifications
        )

        setProgress(1.0, detail = i18n$t("complete"))

        # Store results
        scenario_list <- scenarios()
        idx <- which(sapply(scenario_list, function(s) s$id == active_scenario$id))
        scenario_list[[idx]]$results <- list(
          network_stats = network_stats,
          loops = loops,
          impact_predictions = impact_predictions,
          impact_summary = list(
            nodes_affected = sum(impact_predictions$impact_magnitude != 0),
            positive_impacts = sum(impact_predictions$impact_direction == "positive"),
            negative_impacts = sum(impact_predictions$impact_direction == "negative")
          ),
          analyzed_at = Sys.time()
        )
        scenarios(scenario_list)

        save_scenarios_to_project()

        showNotification(i18n$t("scenario_impact_analysis_complete"), type = "message")
      })
    })

    # Render topology changes table
    output$topology_changes_table <- renderDT({
      req(active_scenario_id())
      active_scenario <- get_active_scenario()
      req(active_scenario$results)

      baseline <- project_data_reactive()$data$cld
      baseline_stats <- list(
        total_nodes = nrow(baseline$nodes),
        total_links = nrow(baseline$edges),
        total_loops = if (!is.null(project_data_reactive()$data$loop_detection)) {
          nrow(project_data_reactive()$data$loop_detection$loops)
        } else {
          0
        }
      )

      scenario_stats <- active_scenario$results$network_stats

      changes <- data.frame(
        Metric = c(i18n$t("scenario_nodes"), i18n$t("scenario_links"), i18n$t("scenario_feedback_loops")),
        Baseline = c(baseline_stats$total_nodes, baseline_stats$total_links, baseline_stats$total_loops),
        Scenario = c(scenario_stats$total_nodes, scenario_stats$total_links, scenario_stats$total_loops),
        Change = c(
          scenario_stats$total_nodes - baseline_stats$total_nodes,
          scenario_stats$total_links - baseline_stats$total_links,
          scenario_stats$total_loops - baseline_stats$total_loops
        )
      )

      datatable(changes,
                options = list(dom = 't', pageLength = 10),
                rownames = FALSE)
    })

    # Render affected loops
    output$affected_loops_list <- renderUI({
      req(active_scenario_id())
      active_scenario <- get_active_scenario()
      req(active_scenario$results)

      loops <- active_scenario$results$loops

      if (is.null(loops) || length(loops) == 0) {
        return(p(class = "text-muted", i18n$t("scenario_no_feedback_loops_detected")))
      }

      # Display first 5 loops
      loops_to_show <- head(loops, 5)

      tagList(
        lapply(loops_to_show, function(loop) {
          div(
            style = "padding: 8px; border-left: 3px solid #3c8dbc; margin-bottom: 8px; background: #f9f9f9;",
            tags$strong(loop$type, " ", i18n$t("scenario_loop"), " (", length(loop$nodes), " ", i18n$t("scenario_nodes_lowercase"), ")"),
            br(),
            tags$small(paste(loop$nodes, collapse = " → "))
          )
        }),
        if (length(loops) > 5) {
          p(class = "text-muted", style = "font-size: 12px;",
           "... ", i18n$t("scenario_and"), " ", length(loops) - 5, " ", i18n$t("scenario_more_loops"))
        }
      )
    })

    # Render impact predictions table
    output$impact_predictions_table <- renderDT({
      req(active_scenario_id())
      active_scenario <- get_active_scenario()
      req(active_scenario$results)

      predictions <- active_scenario$results$impact_predictions

      datatable(predictions,
                options = list(pageLength = 10, order = list(list(3, 'desc'))),
                rownames = FALSE) %>%
        formatStyle('impact_direction',
          color = styleEqual(c('positive', 'negative', 'neutral'),
                           c('#28a745', '#dc3545', '#6c757d')),
          fontWeight = 'bold'
        )
    })

    # ========================================================================
    # COMPARE SCENARIOS TAB
    # ========================================================================

    output$compare_scenarios_ui <- renderUI({
      scenario_list <- scenarios()

      if (length(scenario_list) < 2) {
        return(
          div(
            class = "alert alert-info",
            icon("info-circle"),
            tags$strong(" ", i18n$t("scenario_not_enough_scenarios")),
            tags$p(i18n$t("scenario_need_two_scenarios"))
          )
        )
      }

      # Only show scenarios that have been analyzed
      analyzed_scenarios <- Filter(function(s) !is.null(s$results), scenario_list)

      if (length(analyzed_scenarios) < 2) {
        return(
          div(
            class = "alert alert-warning",
            icon("exclamation-triangle"),
            tags$strong(" ", i18n$t("scenario_scenarios_not_analyzed")),
            tags$p(i18n$t("scenario_run_analysis_to_compare"))
          )
        )
      }

      scenario_choices <- setNames(
        sapply(analyzed_scenarios, function(s) s$id),
        sapply(analyzed_scenarios, function(s) s$name)
      )

      tagList(
        h4(icon("balance-scale"), " ", i18n$t("scenario_compare_scenarios")),
        hr(),

        fluidRow(
          column(6,
            selectInput(ns("compare_scenario_a"), i18n$t("scenario_scenario_a"),
                       choices = scenario_choices)
          ),
          column(6,
            selectInput(ns("compare_scenario_b"), i18n$t("scenario_scenario_b"),
                       choices = scenario_choices)
          )
        ),

        br(),

        uiOutput(ns("comparison_results"))
      )
    })

    # Render comparison results
    output$comparison_results <- renderUI({
      req(input$compare_scenario_a, input$compare_scenario_b)

      if (input$compare_scenario_a == input$compare_scenario_b) {
        return(
          div(class = "alert alert-warning",
             i18n$t("scenario_select_different_scenarios"))
        )
      }

      scenario_list <- scenarios()
      scenario_a <- Find(function(s) s$id == input$compare_scenario_a, scenario_list)
      scenario_b <- Find(function(s) s$id == input$compare_scenario_b, scenario_list)

      req(scenario_a, scenario_b)
      req(scenario_a$results, scenario_b$results)

      tagList(
        # Network stats comparison
        h5(icon("chart-bar"), " ", i18n$t("scenario_network_statistics_comparison")),
        fluidRow(
          column(6,
            wellPanel(
              h6(scenario_a$name),
              p(i18n$t("scenario_nodes"), ": ", scenario_a$results$network_stats$total_nodes),
              p(i18n$t("scenario_links"), ": ", scenario_a$results$network_stats$total_links),
              p(i18n$t("scenario_loops"), ": ", scenario_a$results$network_stats$total_loops)
            )
          ),
          column(6,
            wellPanel(
              h6(scenario_b$name),
              p(i18n$t("scenario_nodes"), ": ", scenario_b$results$network_stats$total_nodes),
              p(i18n$t("scenario_links"), ": ", scenario_b$results$network_stats$total_links),
              p(i18n$t("scenario_loops"), ": ", scenario_b$results$network_stats$total_loops)
            )
          )
        ),

        br(),

        # Impact comparison
        h5(icon("chart-line"), " ", i18n$t("scenario_impact_comparison")),
        DTOutput(ns("impact_comparison_table"))
      )
    })

    # Render impact comparison table
    output$impact_comparison_table <- renderDT({
      req(input$compare_scenario_a, input$compare_scenario_b)

      scenario_list <- scenarios()
      scenario_a <- Find(function(s) s$id == input$compare_scenario_a, scenario_list)
      scenario_b <- Find(function(s) s$id == input$compare_scenario_b, scenario_list)

      req(scenario_a$results, scenario_b$results)

      # Merge impact predictions
      impacts_a <- scenario_a$results$impact_predictions
      impacts_b <- scenario_b$results$impact_predictions

      comparison <- merge(
        impacts_a[, c("node", "impact_magnitude", "impact_direction")],
        impacts_b[, c("node", "impact_magnitude", "impact_direction")],
        by = "node",
        suffixes = c("_A", "_B"),
        all = TRUE
      )

      comparison[is.na(comparison)] <- 0

      colnames(comparison) <- c(i18n$t("scenario_node"),
                                paste(scenario_a$name, i18n$t("scenario_impact")),
                                paste(scenario_a$name, i18n$t("scenario_direction")),
                                paste(scenario_b$name, i18n$t("scenario_impact")),
                                paste(scenario_b$name, i18n$t("scenario_direction")))

      datatable(comparison,
                options = list(pageLength = 10),
                rownames = FALSE)
    })

    # ========================================================================
    # HELPER FUNCTIONS
    # ========================================================================

    # Get active scenario
    get_active_scenario <- function() {
      req(active_scenario_id())
      scenario_list <- scenarios()
      Find(function(s) s$id == active_scenario_id(), scenario_list)
    }

    # Get node label (from baseline or scenario additions)
    get_node_label <- function(node_id, project_data, scenario) {
      # Check baseline nodes
      base_node <- project_data$data$cld$nodes[project_data$data$cld$nodes$id == node_id, ]
      if (nrow(base_node) > 0) {
        return(base_node$label[1])
      }

      # Check scenario added nodes
      added_node <- Find(function(n) n$id == node_id, scenario$modifications$nodes_added)
      if (!is.null(added_node)) {
        return(added_node$label)
      }

      return(node_id)
    }

    # Save scenarios to project data
    save_scenarios_to_project <- function() {
      data <- project_data_reactive()
      data$data$scenarios <- scenarios()
      data$last_modified <- Sys.time()
      project_data_reactive(data)
    }

    # Apply scenario modifications to network
    apply_scenario_modifications <- function(baseline_cld, modifications) {
      # Copy baseline
      nodes <- baseline_cld$nodes
      edges <- baseline_cld$edges

      # Remove nodes
      if (length(modifications$nodes_removed) > 0) {
        nodes <- nodes[!nodes$id %in% modifications$nodes_removed, ]
        # Also remove connected edges
        edges <- edges[!edges$from %in% modifications$nodes_removed &
                      !edges$to %in% modifications$nodes_removed, ]
      }

      # Add nodes
      if (length(modifications$nodes_added) > 0) {
        new_nodes <- do.call(rbind, lapply(modifications$nodes_added, function(n) {
          data.frame(
            id = n$id,
            label = n$label,
            dapsi = n$dapsi,
            description = ifelse(is.null(n$description), "", n$description),
            stringsAsFactors = FALSE
          )
        }))
        nodes <- rbind(nodes, new_nodes)
      }

      # Remove links
      if (length(modifications$links_removed) > 0) {
        edges <- edges[!edges$id %in% modifications$links_removed, ]
      }

      # Add links
      if (length(modifications$links_added) > 0) {
        new_edges <- do.call(rbind, lapply(modifications$links_added, function(l) {
          from_label <- get_node_label_by_id(l$from, nodes)
          to_label <- get_node_label_by_id(l$to, nodes)

          data.frame(
            id = l$id,
            from = l$from,
            to = l$to,
            from_label = from_label,
            to_label = to_label,
            polarity = l$polarity,
            stringsAsFactors = FALSE
          )
        }))
        edges <- rbind(edges, new_edges)
      }

      list(nodes = nodes, edges = edges)
    }

    # Helper to get label by ID
    get_node_label_by_id <- function(node_id, nodes_df) {
      match_node <- nodes_df[nodes_df$id == node_id, ]
      if (nrow(match_node) > 0) {
        return(match_node$label[1])
      }
      return(node_id)
    }

    # Calculate network statistics
    calculate_network_stats <- function(network) {
      list(
        total_nodes = nrow(network$nodes),
        total_links = nrow(network$edges),
        total_loops = 0  # Will be updated by loop detection
      )
    }

    # Detect feedback loops (simplified version)
    detect_feedback_loops <- function(network) {
      # This is a placeholder - would need full loop detection algorithm
      # For now, return empty list
      list()
    }

    # Predict impacts
    predict_impacts <- function(baseline, scenario, modifications) {
      # Get all nodes in scenario
      all_nodes <- scenario$nodes$id

      # Calculate impact for each node
      impacts <- lapply(all_nodes, function(node_id) {
        # Check if node was directly modified
        is_added <- any(sapply(modifications$nodes_added, function(n) n$id == node_id))
        is_removed <- node_id %in% modifications$nodes_removed

        # Check if connected links were modified
        connected_links_added <- any(sapply(modifications$links_added,
                                           function(l) l$from == node_id || l$to == node_id))

        # Simple impact scoring
        impact_magnitude <- 0
        impact_direction <- "neutral"

        if (is_added) {
          impact_magnitude <- 3
          impact_direction <- "positive"
        } else if (connected_links_added) {
          impact_magnitude <- 2
          impact_direction <- "positive"
        }

        node_label <- get_node_label_by_id(node_id, scenario$nodes)

        data.frame(
          node = node_label,
          impact_magnitude = impact_magnitude,
          impact_direction = impact_direction,
          reason = ifelse(is_added, i18n$t("scenario_new_node_added"),
                         ifelse(connected_links_added, i18n$t("scenario_connected_to_new_links"), i18n$t("scenario_indirect_effect"))),
          stringsAsFactors = FALSE
        )
      })

      do.call(rbind, impacts)
    }

    # Return reactive project data
    return(reactive(project_data_reactive()))
  })
}
