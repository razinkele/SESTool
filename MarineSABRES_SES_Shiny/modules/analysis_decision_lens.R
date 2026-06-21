# =============================================================================
# MODULE: Decision Lens (QSEM interpretation layer)
# File: modules/analysis_decision_lens.R
# =============================================================================
# Surfaces the dormant MICMAC factor classification (impact-vs-control axis) and
# a deterministic "why this matters" narrative. Composes functions/decision_lens.R.
#
# Phase 1 scope: Factor Classification + Why This Matters tabs.
# Archetype detection is DEFERRED (see the design spec §0/§6) pending
# re-derivation against valid DAPSIWRM topology + scientific validation; the
# Archetypes tab is intentionally omitted until that lands.
# =============================================================================

analysis_decision_lens_ui <- function(id, i18n) {
  tryCatch(shiny.i18n::usei18n(i18n$translator %||% i18n), error = function(e) NULL)
  ns <- NS(id)

  tagList(
    uiOutput(ns("module_header")),
    fluidRow(column(12,
      tabsetPanel(id = ns("dl_tabs"),

        # Tab 1: Factor Classification (impact vs control) ----
        tabPanel(i18n$t("modules.analysis.decision_lens.tab_factors"),
          wellPanel(
            p(i18n$t("modules.analysis.decision_lens.factors_intro")),
            actionButton(ns("analyze"), i18n$t("modules.analysis.decision_lens.btn_analyze"),
                         icon = icon("calculator"), class = "btn-primary")
          ),
          uiOutput(ns("factors_status")),
          plotOutput(ns("factors_plot"), height = PLOT_HEIGHT_MD),
          DT::dataTableOutput(ns("factors_table"))
        ),

        # Tab 2: System Archetypes ----
        tabPanel(i18n$t("modules.analysis.decision_lens.tab_archetypes"),
          div(class = "alert alert-info",
              icon("info-circle"), " ",
              i18n$t("modules.analysis.decision_lens.archetype_candidate_caveat")),
          uiOutput(ns("archetypes_ui"))
        ),

        # Tab 3: Why This Matters ----
        tabPanel(i18n$t("modules.analysis.decision_lens.tab_why"),
          p(i18n$t("modules.analysis.decision_lens.why_intro")),
          selectInput(ns("why_node"), NULL, choices = NULL),
          htmlOutput(ns("why_narrative"))
        )
      )
    )),
    uiOutput(ns("next_steps_ui"))
  )
}

analysis_decision_lens_server <- function(id, project_data_reactive, i18n, event_bus = NULL) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    rv <- reactiveValues(factors = NULL, loop_info = NULL, archetypes = NULL)

    # Stale-data observer
    observe({
      req(!is.null(event_bus))
      event_bus$on_isa_change()
      if (!is.null(isolate(rv$factors))) {
        showNotification(i18n$t("modules.analysis.common.data_changed_rerun"),
                         type = "warning", duration = 5, id = ns("stale_data"))
      }
    })

    create_reactive_header(
      output = output, ns = ns,
      title_key = "modules.analysis.decision_lens.title",
      subtitle_key = "modules.analysis.decision_lens.subtitle",
      help_id = "help_decision_lens", i18n = i18n
    )

    # Resolve nodes/edges/graph, reusing the cached igraph when available
    resolve_graph <- function() {
      cached <- if (!is.null(event_bus)) event_bus$get_isa_igraph() else NULL
      if (!is.null(cached)) {
        return(list(nodes = cached$nodes, edges = cached$edges, graph = cached$graph))
      }
      pd <- project_data_reactive()
      isa <- pd$data$isa_data
      if (is.null(isa)) return(NULL)
      nodes <- create_nodes_df(isa)
      edges <- create_edges_df(isa, isa$adjacency_matrices)
      list(nodes = nodes, edges = edges, graph = NULL)
    }

    observeEvent(input$analyze, {
      g <- resolve_graph()
      if (is.null(g) || is.null(g$edges) || nrow(g$edges) == 0) {
        showNotification(i18n$t("modules.analysis.decision_lens.no_network_data"),
                         type = "warning", duration = 5)
        return()
      }
      tryCatch({
        rv$factors <- classify_factors_micmac(g$nodes, g$edges)

        # Loops feed the narrative's loop-participation line (archetypes deferred)
        gph <- g$graph
        if (is.null(gph)) {
          gph <- graph_from_data_frame(g$edges %>% select(from, to, polarity),
                                       directed = TRUE,
                                       vertices = g$nodes %>% select(id, label, group))
        }
        loops <- find_all_cycles(g$nodes, g$edges, max_length = 8, max_cycles = 500,
                                 timeout_seconds = LOOP_ANALYSIS_TIMEOUT_SECONDS)
        rv$loop_info <- process_cycles_to_loops(loops, g$nodes, g$edges, gph)
        rv$archetypes <- detect_archetypes(rv$loop_info, g$nodes)

        updateSelectInput(session, "why_node",
                          choices = setNames(rv$factors$id, rv$factors$label))
      }, error = function(e) {
        showNotification(
          format_user_error(e, i18n = i18n,
                            context_key = "common.messages.context_analyzing_decision_lens"),
          type = "error", duration = 10)
      })
    })

    output$factors_status <- renderUI({
      if (is.null(rv$factors)) {
        div(class = "alert alert-info", icon("info-circle"), " ",
            i18n$t("modules.analysis.decision_lens.click_analyze"))
      } else NULL
    })

    output$factors_plot <- renderPlot({
      req(rv$factors); req(nrow(rv$factors) > 0)
      df <- rv$factors
      # Quadrant dual-encoded (color + shape) so it does not rely on colour alone
      ggplot(df, aes(x = dependence, y = influence, color = quadrant, shape = quadrant)) +
        geom_vline(xintercept = median(df$dependence), linetype = "dashed", color = "grey60") +
        geom_hline(yintercept = median(df$influence),  linetype = "dashed", color = "grey60") +
        geom_point(size = 4, alpha = 0.85) +
        geom_text(aes(label = label), size = 3.5, vjust = -1, check_overlap = TRUE,
                  show.legend = FALSE) +
        labs(x = i18n$t("modules.analysis.decision_lens.factors_x_axis"),
             y = i18n$t("modules.analysis.decision_lens.factors_y_axis")) +
        theme_minimal(base_size = 13)
    })

    output$factors_table <- DT::renderDataTable({
      req(rv$factors)
      DT::datatable(rv$factors, options = list(pageLength = 15, scrollX = TRUE),
                    rownames = FALSE)
    })

    output$archetypes_ui <- renderUI({
      req(!is.null(rv$archetypes))
      if (length(rv$archetypes) == 0) {
        return(div(class = "alert alert-secondary",
                   i18n$t("modules.analysis.decision_lens.archetypes_none")))
      }
      label_of <- function(id) {
        m <- rv$factors$label[match(id, rv$factors$id)]
        if (length(m) == 0 || is.na(m)) id else m
      }
      tagList(
        p(i18n$t("modules.analysis.decision_lens.archetypes_intro")),
        lapply(rv$archetypes, function(a) {
          k <- paste0("modules.analysis.decision_lens.archetype.", a$archetype_key)
          wellPanel(
            h4(i18n$t(paste0(k, ".name"))),
            p(i18n$t(paste0(k, ".desc"))),
            p(strong(i18n$t("modules.analysis.decision_lens.narrative_archetype_leverage")), ": ",
              label_of(a$leverage_node_id)),
            p(em(i18n$t(paste0(k, ".leverage")))),
            tags$small(class = "text-muted",
                       paste0("Loops: ", paste(a$loop_ids, collapse = ", ")))
          )
        })
      )
    })

    output$why_narrative <- renderUI({
      req(input$why_node, rv$factors)
      HTML(build_decision_narrative(input$why_node, rv$factors, rv$loop_info,
                                    rv$archetypes %||% list(), i18n))
    })

    output$next_steps_ui <- renderUI({
      req(!is.null(rv$factors))
      build_next_steps_ui("analysis_decision_lens", ns, i18n)
    })

    local({
      recs <- get_next_steps("analysis_decision_lens")
      lapply(seq_along(recs), function(i) {
        observeEvent(input[[paste0("next_step_", i)]], {
          if (!is.null(event_bus) && is.function(event_bus$emit_navigation_request)) {
            event_bus$emit_navigation_request(recs[[i]]$tab_id, "analysis_decision_lens")
          }
        })
      })
    })

    create_help_observer(
      input = input, input_id = "help_decision_lens",
      title_key = "modules.analysis.decision_lens.help_title",
      content = tagList(
        p(i18n$t("modules.analysis.decision_lens.factors_intro")),
        p(i18n$t("modules.analysis.decision_lens.why_intro"))
      ),
      i18n = i18n
    )

    return(reactive({ rv }))
  })
}
