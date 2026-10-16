# modules/intervention_designer_module.R
# =============================================================================
# WP5 WS-7a Designer tab (spec 2026-10-14 §6): build a design (new node and/or
# new edges), run it in the background, show D5.3-ranked results.
# Depends on: functions/intervention_designer.R, functions/intervention_designer_job.R,
#             functions/wp5_vocabulary.R, functions/ses_dynamics.R
# =============================================================================

.DESIGNER_NEW <- ".NEW_NODE."

.designer_empty_edges <- function() {
  data.frame(from = character(), to = character(), kind = character(),
             min_level = numeric(), max_level = numeric(), stringsAsFactors = FALSE)
}

#' Payload for the worker; substitutes the node placeholder with `name`.
.designer_payload <- function(net, edges, name, objectives, sustain) {
  has_node <- any(edges$from == .DESIGNER_NEW | edges$to == .DESIGNER_NEW)
  edges$from[edges$from == .DESIGNER_NEW] <- name
  edges$to[edges$to == .DESIGNER_NEW] <- name
  list(base = net$matrix,
       design = list(new_node = if (has_node) name else NULL, edges = edges),
       levels = INTERVENTION_GRID_LEVELS,
       dependence_min_success = INTERVENTION_DEPENDENCE_MIN_SUCCESS,
       objectives = objectives, sustain = sustain %||% character(0),
       seed = INTERVENTION_DEFAULT_SEED, steps = INTERVENTION_N_STEPS,
       window = INTERVENTION_WINDOW, cap = INTERVENTION_GRID_CAP,
       chunk = INTERVENTION_CHUNK, top_k = INTERVENTION_TOP_K,
       max_boolean_nodes = DYNAMICS_MAX_BOOLEAN_NODES,
       stability_budget_s = INTERVENTION_STABILITY_BUDGET_FRACTION * INTERVENTION_JOB_TIMEOUT_S)
}

# TRUE when the level sets span more combinations than the engine accepts.
.designer_too_many <- function(level_sets) {
  prod(as.numeric(lengths(level_sets))) > SES_MAX_GRID_COMBINATIONS
}

intervention_designer_ui <- function(id, i18n) {
  tryCatch(shiny.i18n::usei18n(i18n$translator %||% i18n), error = function(e) NULL)
  ns <- NS(id)
  tagList(
    p(class = "text-muted mt-2", i18n$t("modules.intervention_designer.intro")),
    fluidRow(
      column(5, uiOutput(ns("design_ui"))),
      column(7, uiOutput(ns("results_ui")))
    )
  )
}

intervention_designer_server <- function(id, project_data_reactive, i18n, event_bus = NULL,
                                         job_api = designer_job_api()) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    rv <- reactiveValues(edges = .designer_empty_edges(), job = NULL, result = NULL,
                         progress = NULL, error = NULL, error_detail = NULL,
                         analysis_complete = FALSE, cmp_job = NULL, compare = NULL, stale = FALSE)

    lvl_label <- function(x) {
      # i18n-ref: modules.intervention_designer.level.strong_neg
      # i18n-ref: modules.intervention_designer.level.medium_neg
      # i18n-ref: modules.intervention_designer.level.weak_neg
      # i18n-ref: modules.intervention_designer.level.none
      # i18n-ref: modules.intervention_designer.level.weak_pos
      # i18n-ref: modules.intervention_designer.level.medium_pos
      # i18n-ref: modules.intervention_designer.level.strong_pos
      vapply(ses_level_code(x), function(cd) i18n$t(paste0("modules.intervention_designer.level.", cd)),
             character(1))
    }
    # Every stored min/max level is a member of INTERVENTION_GRID_LEVELS (evidence
    # priors are 0.25/0.5/1, sign shortcuts use 0), so as.character() matches a choice.
    level_choices <- function() setNames(as.character(INTERVENTION_GRID_LEVELS),
                                         lvl_label(INTERVENTION_GRID_LEVELS))
    # Re-weighted links keep the link's own sign: only sign(w) x {0.25, 0.5, 1} is offered.
    reweight_choices <- function(kind, max_level) {
      ch <- level_choices()
      if (identical(kind, "reweight")) {
        s <- sign(max_level)
        ch <- ch[as.numeric(ch) %in% (s * c(0.25, 0.5, 1))]
      }
      ch
    }
    node_name <- reactive(trimws(input$name %||% ""))
    show_name <- function(x) ifelse(x == .DESIGNER_NEW,
      if (nzchar(node_name())) node_name() else i18n$t("modules.intervention_designer.new_node_placeholder"), x)

    net <- reactive({
      data <- project_data_reactive()
      req(data, has_valid_cld(data))
      nodes <- data$data$cld$nodes
      mat <- cld_to_numeric_matrix(nodes, data$data$cld$edges, use_labels = TRUE)
      req(!is.null(mat))
      # cld_to_numeric_matrix names its dimnames by node id; drop those names so
      # choices and lookups use the labels themselves.
      dimnames(mat) <- lapply(dimnames(mat), unname)
      types <- if ("group" %in% names(nodes)) as.character(nodes$group) else rep(NA_character_, nrow(nodes))
      # labels MUST equal the matrix dimnames (make.unique'd on duplicate labels, id
      # fallback), so choices, lookups and the name-clash check match the matrix.
      # cld_to_numeric_matrix keeps the nodes' row order, so `types` stays aligned.
      list(labels = rownames(mat), types = types, matrix = mat)
    })

    # Mode C link list (spec 2026-10-15 §3.4, §4.1): ranked by dominant-eigenvalue
    # sensitivity; when no single dominant mode exists, listed unranked.
    link_rank <- reactive({
      m <- net()$matrix
      ranked <- tryCatch(ses_link_sensitivity(m), error = function(e) NULL)
      links <- if (!is.null(ranked)) ranked else {
        idx <- which(m != 0, arr.ind = TRUE)
        data.frame(from = rownames(m)[idx[, 1]], to = colnames(m)[idx[, 2]], weight = m[idx],
                   sensitivity = NA_real_, stringsAsFactors = FALSE)
      }
      list(ranked = ranked, links = links)
    })

    # The design panel is rebuilt only when the node set changes, not on every
    # project_data write (Quick compare and other analyses write it back).
    node_sig <- reactiveVal(NULL)
    observe({
      n <- net()
      s <- paste(n$labels, n$types, sep = "\t", collapse = "\r")
      if (!identical(s, isolate(node_sig()))) node_sig(s)
    })

    # Stale results after an ISA change (standard analysis pattern)
    observe({
      req(!is.null(event_bus))
      event_bus$on_isa_change()
      if (isolate(rv$analysis_complete)) {
        rv$stale <- TRUE
        showNotification(i18n$t("modules.analysis.common.data_changed_rerun"),
                         type = "warning", duration = 5, id = ns("stale_data"))
      }
    })

    # ── Design panel ───────────────────────────────────────────────────────
    output$design_ui <- renderUI({
      req(node_sig())
      n <- isolate(net())
      lab <- n$labels
      keep <- function(v) intersect(v %||% character(0), lab)   # drop picks that left the network
      types_df <- tryCatch({ load_wp5_intervention_ops(); get_intervention_types() },
                           error = function(e) data.frame(id = character(), group = character()))
      # i18n-ref: modules.intervention_designer.group.behavioural
      # i18n-ref: modules.intervention_designer.group.management
      # i18n-ref: modules.intervention_designer.group.economic
      # i18n-ref: modules.intervention_designer.group.governance
      # i18n-ref: modules.intervention_designer.type.nudge
      # i18n-ref: modules.intervention_designer.type.certification
      # i18n-ref: modules.intervention_designer.type.traceability
      # i18n-ref: modules.intervention_designer.type.norms_influence
      # i18n-ref: modules.intervention_designer.type.data_valuing
      # i18n-ref: modules.intervention_designer.type.change_in_accessibility
      # i18n-ref: modules.intervention_designer.type.participation_in_governance
      # i18n-ref: modules.intervention_designer.type.cascade_creation
      # i18n-ref: modules.intervention_designer.type.remote_market_access
      # i18n-ref: modules.intervention_designer.type.change_in_practices
      # i18n-ref: modules.intervention_designer.type.quota_license
      # i18n-ref: modules.intervention_designer.type.mpa_oecm
      # i18n-ref: modules.intervention_designer.type.subsidies
      # i18n-ref: modules.intervention_designer.type.incentives
      # i18n-ref: modules.intervention_designer.type.trade_agreements
      # i18n-ref: modules.intervention_designer.type.payment_goods_services
      # i18n-ref: modules.intervention_designer.type.payment_non_market_services
      # i18n-ref: modules.intervention_designer.type.externalities_in_prices
      # i18n-ref: modules.intervention_designer.type.one_off_recosting
      # i18n-ref: modules.intervention_designer.type.ongoing_recosting
      # i18n-ref: modules.intervention_designer.type.multi_level_governance
      # i18n-ref: modules.intervention_designer.type.change_power_dynamics
      # i18n-ref: modules.intervention_designer.type.cross_sector_coordination
      # i18n-ref: modules.intervention_designer.type.enhance_governance_capacity
      # i18n-ref: modules.intervention_designer.type.incorporate_society_values
      # i18n-ref: modules.intervention_designer.type.enhance_trust
      # i18n-ref: modules.intervention_designer.type.reduce_conflicts
      # i18n-ref: modules.intervention_designer.type.increase_collaboration
      # i18n-ref: modules.intervention_designer.type.increase_participation
      # i18n-ref: modules.intervention_designer.type.enhance_compliance_monitoring
      type_choices <- c(setNames("", i18n$t("modules.intervention_designer.type_none")),
        lapply(split(types_df$id, types_df$group), function(ids)
          setNames(ids, vapply(ids, function(x) i18n$t(paste0("modules.intervention_designer.type.", x)),
                               character(1)))))
      names(type_choices)[-1] <- vapply(names(type_choices)[-1], function(g)
        i18n$t(paste0("modules.intervention_designer.group.", g)), character(1))
      gb <- lab[!is.na(n$types) & n$types == "Goods & Benefits"]
      loops <- ses_self_loop_candidates(lab, n$types)
      sustain_now <- isolate(input$sustain)
      tagList(
        bs4Card(title = i18n$t("modules.intervention_designer.step_intervention"), width = 12,
                status = "primary", collapsible = FALSE,
          textInput(ns("name"), i18n$t("modules.intervention_designer.name"),
                    value = isolate(input$name) %||% "",
                    placeholder = i18n$t("modules.intervention_designer.name_placeholder")),
          # allowEmptyOption keeps "No type" selectable after a type was picked
          selectizeInput(ns("type"), i18n$t("modules.intervention_designer.type"), choices = type_choices,
                         selected = isolate(input$type) %||% "",
                         options = list(allowEmptyOption = TRUE)),
          uiOutput(ns("ops_ui"))),
        bs4Card(title = i18n$t("modules.intervention_designer.step_edges"), width = 12,
                status = "primary", collapsible = FALSE,
          h6(i18n$t("modules.intervention_designer.add_node_heading")),
          selectizeInput(ns("node_targets"), i18n$t("modules.intervention_designer.node_targets"),
                         choices = lab, selected = keep(isolate(input$node_targets)), multiple = TRUE),
          selectizeInput(ns("node_indicators"), i18n$t("modules.intervention_designer.node_indicators"),
                         choices = lab, selected = keep(isolate(input$node_indicators)), multiple = TRUE),
          actionButton(ns("add_node_edges"), i18n$t("modules.intervention_designer.add_node_edges"),
                       icon = icon("plus")),
          hr(),
          h6(i18n$t("modules.intervention_designer.add_edge_heading")),
          fluidRow(column(6, selectInput(ns("edge_from"), i18n$t("modules.intervention_designer.edge_from"), lab)),
                   column(6, selectInput(ns("edge_to"), i18n$t("modules.intervention_designer.edge_to"), lab))),
          actionButton(ns("add_edge"), i18n$t("modules.intervention_designer.add_edge"), icon = icon("plus")),
          if (length(loops)) tagList(
            selectInput(ns("self_loop_node"), i18n$t("modules.intervention_designer.self_loop_node"), loops),
            actionButton(ns("add_self_loop"), i18n$t("modules.intervention_designer.add_self_loop"),
                         icon = icon("redo"))),
          hr(),
          uiOutput(ns("reweight_ui")),
          hr(),
          tableOutput(ns("edges_table")),
          uiOutput(ns("edge_editor_ui"))),
        bs4Card(title = i18n$t("modules.intervention_designer.step_objectives"), width = 12,
                status = "primary", collapsible = FALSE,
          selectizeInput(ns("objectives"), i18n$t("modules.intervention_designer.objectives"),
                         choices = lab, selected = keep(isolate(input$objectives)), multiple = TRUE),
          selectizeInput(ns("sustain"), i18n$t("modules.intervention_designer.sustain"),
                         choices = lab, selected = if (is.null(sustain_now)) gb else keep(sustain_now),
                         multiple = TRUE)),
        bs4Card(title = i18n$t("modules.intervention_designer.step_run"), width = 12,
                status = "success", collapsible = FALSE,
          uiOutput(ns("grid_info")),
          # Rendered disabled when a reason already applies; the toggleState observer
          # below keeps it in sync between rebuilds of this panel.
          actionButton(ns("run"), i18n$t("modules.intervention_designer.run"),
                       icon = icon("play"), class = "btn-success",
                       disabled = !is.null(isolate(run_block_reason()))))
      )
    })

    output$reweight_ui <- renderUI({
      lr <- link_rank(); l <- lr$links
      if (!nrow(l)) return(NULL)
      top <- if (is.null(lr$ranked)) 1 else max(l$sensitivity, 1e-12)
      names_ui <- lapply(seq_len(nrow(l)), function(i) {
        bar <- if (is.na(l$sensitivity[i])) NULL else
          span(style = sprintf("display:inline-block;height:6px;width:%dpx;background:#3c8dbc;margin-left:6px;",
                               round(60 * l$sensitivity[i] / top)))
        tagList(paste0(l$from[i], " → ", l$to[i], " (", lvl_label(l$weight[i]), ")"), bar)
      })
      tagList(
        h6(i18n$t("modules.intervention_designer.reweight_heading")),
        p(class = "small text-muted", i18n$t("modules.intervention_designer.reweight_help")),
        if (is.null(lr$ranked)) div(class = "alert alert-secondary py-1 small",
                                    i18n$t("modules.intervention_designer.ranking_unavailable")),
        div(style = "max-height: 220px; overflow-y: auto;",
            checkboxGroupInput(ns("rw_links"), i18n$t("modules.intervention_designer.reweight_links"),
                               choiceNames = names_ui, choiceValues = paste(l$from, l$to, sep = "\r"),
                               selected = isolate(input$rw_links))),
        actionButton(ns("add_reweight"), i18n$t("modules.intervention_designer.add_reweight"), icon = icon("plus")),
        fluidRow(column(8, selectInput(ns("rw_node"), i18n$t("modules.intervention_designer.reweight_node"),
                                       net()$labels)),
                 column(4, actionButton(ns("add_node_links"), i18n$t("modules.intervention_designer.add_node_links"),
                                        class = "mt-4")))
      )
    })

    # ── Operations table (advisory, spec decision 2) ───────────────────────
    output$ops_ui <- renderUI({
      tp <- input$type %||% ""
      if (!nzchar(tp)) return(NULL)
      ops <- get_allowed_graph_ops(tp)
      used <- c(if (any(rv$edges$kind == "intervention")) "new_node",
                if (any(rv$edges$kind == "context")) "new_edge",
                if (any(rv$edges$kind == "reweight")) "reweight_edge")
      # i18n-ref: modules.intervention_designer.op.new_node
      # i18n-ref: modules.intervention_designer.op.new_edge
      # i18n-ref: modules.intervention_designer.op.reweight_edge
      # i18n-ref: modules.intervention_designer.ops_source_xlsx
      # i18n-ref: modules.intervention_designer.ops_source_ebm
      src_lbl <- function(s) paste(vapply(strsplit(s, "+", fixed = TRUE)[[1]], function(x)
        i18n$t(paste0("modules.intervention_designer.ops_source_", x)), character(1)), collapse = ", ")
      tagList(
        tags$small(strong(i18n$t("modules.intervention_designer.ops_heading")),
                   provenance_badge("provisional", i18n)),
        tags$ul(class = "small mb-1", lapply(seq_len(nrow(ops)), function(i)
          tags$li(i18n$t(paste0("modules.intervention_designer.op.", ops$op[i])), " (", src_lbl(ops$source[i]), ")"))),
        if (length(setdiff(used, ops$op)))
          div(class = "alert alert-warning py-1 small", i18n$t("modules.intervention_designer.ops_mismatch")),
        tags$small(class = "text-muted", i18n$t("modules.intervention_designer.prior_note"),
                   provenance_badge("toolbox_extension", i18n))
      )
    })

    # ── Adding and editing edges ──────────────────────────────────────────
    add_rows <- function(new) {
      cur <- rv$edges
      key <- paste(cur$from, cur$to, sep = "\r")
      new <- new[!paste(new$from, new$to, sep = "\r") %in% key, , drop = FALSE]
      rv$edges <- rbind(cur, new)
    }
    prior <- reactive(ses_evidence_prior_range(get_intervention_ebm_codes(input$type %||% ""),
                                               INTERVENTION_EVIDENCE_PRIORS))

    observeEvent(input$add_node_edges, {
      targets <- input$node_targets %||% character(0)
      inds <- input$node_indicators %||% character(0)
      if (!length(targets)) {
        showNotification(i18n$t("modules.intervention_designer.need_target"), type = "warning")
        return()
      }
      pr <- prior()
      mk <- function(from, to) data.frame(from = from, to = to, kind = "intervention",
        min_level = pr[["min"]], max_level = pr[["max"]], stringsAsFactors = FALSE)
      add_rows(rbind(mk(.DESIGNER_NEW, targets), if (length(inds)) mk(inds, .DESIGNER_NEW)))
    })

    add_context_edge <- function(from, to) {
      n <- net()
      # A stale pick (node renamed/deleted since the panel was built) is ignored
      req(from %in% n$labels, to %in% n$labels)
      # Covers self-loops too: an existing self-loop is re-weighting (mode C)
      if (n$matrix[from, to] != 0) {
        showNotification(i18n$t("modules.intervention_designer.edge_exists"), type = "warning")
        return(invisible(FALSE))
      }
      if (from != to && isTRUE(ses_check_new_edge(n$types[match(from, n$labels)],
                                                  n$types[match(to, n$labels)]))) {
        # Translated prefix + the user's own node labels (user data, not translated)
        showNotification(paste(i18n$t("modules.intervention_designer.edge_rule_warning"), from, "→", to),
                         type = "warning")
      }
      add_rows(data.frame(from = from, to = to, kind = "context", min_level = -1, max_level = 1,
                          stringsAsFactors = FALSE))
      invisible(TRUE)
    }
    observeEvent(input$add_edge, { req(input$edge_from, input$edge_to); add_context_edge(input$edge_from, input$edge_to) })
    observeEvent(input$add_self_loop, { req(input$self_loop_node); add_context_edge(input$self_loop_node, input$self_loop_node) })

    # Mode C rows: the link's own sign, weak..strong (spec §3.1)
    add_reweight_rows <- function(from, to) {
      m <- net()$matrix
      ok <- from %in% rownames(m) & to %in% colnames(m)
      from <- from[ok]; to <- to[ok]
      w <- m[cbind(from, to)]
      from <- from[w != 0]; to <- to[w != 0]; w <- w[w != 0]
      if (!length(w)) return(invisible(FALSE))
      s <- sign(w)
      add_rows(data.frame(from = from, to = to, kind = "reweight",
                          min_level = pmin(s * 0.25, s * 1), max_level = pmax(s * 0.25, s * 1),
                          stringsAsFactors = FALSE))
      invisible(TRUE)
    }
    observeEvent(input$add_reweight, {
      keys <- input$rw_links %||% character(0)
      if (!length(keys)) {
        showNotification(i18n$t("modules.intervention_designer.need_link"), type = "warning")
        return()
      }
      parts <- strsplit(keys, "\r", fixed = TRUE)
      add_reweight_rows(vapply(parts, `[`, "", 1), vapply(parts, `[`, "", 2))
    })
    observeEvent(input$add_node_links, {
      req(input$rw_node)
      l <- link_rank()$links
      hit <- l$from == input$rw_node | l$to == input$rw_node
      add_reweight_rows(l$from[hit], l$to[hit])
    })

    output$edges_table <- renderTable({
      e <- rv$edges
      if (!nrow(e)) return(data.frame(x = i18n$t("modules.intervention_designer.no_edges")) |>
                             setNames(" "))
      # i18n-ref: modules.intervention_designer.kind.intervention
      # i18n-ref: modules.intervention_designer.kind.context
      # i18n-ref: modules.intervention_designer.kind.reweight
      setNames(data.frame(
        seq_len(nrow(e)), show_name(e$from), show_name(e$to),
        vapply(e$kind, function(k) i18n$t(paste0("modules.intervention_designer.kind.", k)), character(1)),
        paste(lvl_label(e$min_level), "…", lvl_label(e$max_level)), stringsAsFactors = FALSE),
        c("#", i18n$t("modules.intervention_designer.col_from"), i18n$t("modules.intervention_designer.col_to"),
          i18n$t("modules.intervention_designer.col_kind"), i18n$t("modules.intervention_designer.col_range")))
    }, striped = TRUE, spacing = "xs")

    # Re-rendered when rv$edges changes; keeps the selected edge and shows its range.
    # The name is isolated so typing in the name field does not rebuild the editor.
    output$edge_editor_ui <- renderUI({
      e <- rv$edges
      if (!nrow(e)) return(NULL)
      lbl <- isolate(paste0(seq_len(nrow(e)), ": ", show_name(e$from), " → ", show_name(e$to)))
      choices <- setNames(as.character(seq_len(nrow(e))), lbl)
      prev <- isolate(input$edit_edge)
      sel <- if (!is.null(prev) && prev %in% choices) prev else tail(unname(choices), 1)
      i <- as.integer(sel)
      ch <- reweight_choices(e$kind[i], e$max_level[i])
      tagList(
        selectInput(ns("edit_edge"), i18n$t("modules.intervention_designer.edit_edge"), choices, selected = sel),
        fluidRow(column(6, selectInput(ns("min_level"), i18n$t("modules.intervention_designer.min_level"),
                                       ch, selected = as.character(e$min_level[i]))),
                 column(6, selectInput(ns("max_level"), i18n$t("modules.intervention_designer.max_level"),
                                       ch, selected = as.character(e$max_level[i])))),
        actionButton(ns("apply_range"), i18n$t("modules.intervention_designer.apply_range"), class = "btn-sm"),
        actionButton(ns("sign_nonpos"), i18n$t("modules.intervention_designer.sign_nonpos"), class = "btn-sm"),
        actionButton(ns("sign_nonneg"), i18n$t("modules.intervention_designer.sign_nonneg"), class = "btn-sm"),
        actionButton(ns("remove_edge"), i18n$t("modules.intervention_designer.remove_edge"),
                     class = "btn-sm btn-outline-danger")
      )
    })
    edit_row <- reactive(as.integer(input$edit_edge %||% NA))
    # The selected edge row, or stop the observer if it no longer exists
    req_edit_row <- function() {
      i <- edit_row(); req(!is.na(i), i <= nrow(rv$edges))
      i
    }
    # Picking another edge shows that edge's current range
    observeEvent(input$edit_edge, {
      i <- req_edit_row()
      ch <- reweight_choices(rv$edges$kind[i], rv$edges$max_level[i])
      updateSelectInput(session, "min_level", choices = ch, selected = as.character(rv$edges$min_level[i]))
      updateSelectInput(session, "max_level", choices = ch, selected = as.character(rv$edges$max_level[i]))
    }, ignoreInit = TRUE)
    observeEvent(input$apply_range, {
      i <- req_edit_row()
      e <- rv$edges; e$min_level[i] <- as.numeric(input$min_level); e$max_level[i] <- as.numeric(input$max_level)
      rv$edges <- e
    })
    observeEvent(input$sign_nonpos, {
      i <- req_edit_row()
      if (identical(rv$edges$kind[i], "reweight")) {
        showNotification(i18n$t("modules.intervention_designer.reweight_fixed_sign"), type = "message")
        return()
      }
      e <- rv$edges; e$min_level[i] <- min(e$min_level[i], 0); e$max_level[i] <- 0; rv$edges <- e
    })
    observeEvent(input$sign_nonneg, {
      i <- req_edit_row()
      if (identical(rv$edges$kind[i], "reweight")) {
        showNotification(i18n$t("modules.intervention_designer.reweight_fixed_sign"), type = "message")
        return()
      }
      e <- rv$edges; e$min_level[i] <- 0; e$max_level[i] <- max(e$max_level[i], 0); rv$edges <- e
    })
    observeEvent(input$remove_edge, {
      i <- req_edit_row()
      rv$edges <- rv$edges[-i, , drop = FALSE]
    })

    # ── Run gating ─────────────────────────────────────────────────────────
    level_sets <- reactive(ses_level_sets(rv$edges, INTERVENTION_GRID_LEVELS))
    # Returns an i18n key (translated by the callers) or NULL.
    # i18n-ref: modules.intervention_designer.job_running
    # i18n-ref: modules.intervention_designer.need_edges
    # i18n-ref: modules.intervention_designer.stale_edges
    # i18n-ref: modules.intervention_designer.edge_exists
    # i18n-ref: modules.intervention_designer.reweight_stale
    # i18n-ref: modules.intervention_designer.empty_range
    # i18n-ref: modules.intervention_designer.too_many_combinations
    # i18n-ref: modules.intervention_designer.need_name
    # i18n-ref: modules.intervention_designer.name_clash
    # i18n-ref: modules.intervention_designer.need_objective
    run_block_reason <- reactive({
      e <- rv$edges
      if (!is.null(rv$job) || !is.null(rv$cmp_job)) return("modules.intervention_designer.job_running")
      if (!nrow(e)) return("modules.intervention_designer.need_edges")
      # The CLD may have changed since the edges were added (renamed/deleted nodes,
      # or a designed edge that now exists): catch it here, not in the worker.
      lab <- net()$labels
      ends <- setdiff(c(e$from, e$to), .DESIGNER_NEW)
      if (!all(ends %in% lab)) return("modules.intervention_designer.stale_edges")
      ctx <- e[e$from != .DESIGNER_NEW & e$to != .DESIGNER_NEW & e$kind != "reweight", , drop = FALSE]
      if (nrow(ctx) && any(net()$matrix[cbind(ctx$from, ctx$to)] != 0)) {
        return("modules.intervention_designer.edge_exists")
      }
      rw_rows <- e[e$kind == "reweight", , drop = FALSE]
      if (nrow(rw_rows)) {
        w <- net()$matrix[cbind(rw_rows$from, rw_rows$to)]
        if (any(w == 0 | sign(w) != sign(rw_rows$max_level))) return("modules.intervention_designer.reweight_stale")
      }
      if (any(lengths(level_sets()) == 0)) return("modules.intervention_designer.empty_range")
      if (.designer_too_many(level_sets())) return("modules.intervention_designer.too_many_combinations")
      if (any(e$from == .DESIGNER_NEW | e$to == .DESIGNER_NEW)) {
        if (!nzchar(node_name())) return("modules.intervention_designer.need_name")
        if (node_name() %in% lab) return("modules.intervention_designer.name_clash")
      }
      if (!length(input$objectives)) return("modules.intervention_designer.need_objective")
      NULL
    })
    # Run is disabled while a reason applies or a job is active (spec §6); the
    # click guard in observeEvent(input$run) stays as a backstop.
    observe(shinyjs::toggleState("run", condition = is.null(run_block_reason())))

    output$grid_info <- renderUI({
      reason <- run_block_reason()
      if (!is.null(reason) && reason != "modules.intervention_designer.job_running") {
        return(div(class = "text-muted small mb-2", i18n$t(reason)))
      }
      # Edges stay editable while a job runs: never build an oversized grid here
      if (.designer_too_many(level_sets())) {
        return(div(class = "text-muted small mb-2", i18n$t("modules.intervention_designer.too_many_combinations")))
      }
      g <- ses_intervention_grid(level_sets(), cap = INTERVENTION_GRID_CAP, seed = INTERVENTION_DEFAULT_SEED)
      # i18n-ref: modules.intervention_designer.sampled
      # i18n-ref: modules.intervention_designer.exhaustive
      div(class = "small mb-2",
          format(g$n_total, big.mark = ",", scientific = FALSE), " ",
          i18n$t("modules.intervention_designer.combinations"), " — ",
          i18n$t(if (g$sampled) "modules.intervention_designer.sampled"
                 else "modules.intervention_designer.exhaustive"))
    })

    # ── Run, poll, cancel ──────────────────────────────────────────────────
    observeEvent(input$run, {
      reason <- run_block_reason()
      if (!is.null(reason)) { showNotification(i18n$t(reason), type = "warning"); return() }
      payload <- .designer_payload(net(), rv$edges, node_name(), input$objectives, input$sustain)
      rv$result <- NULL; rv$error <- NULL; rv$error_detail <- NULL
      rv$progress <- list(done = 0, total = NA_real_)
      rv$job <- tryCatch(job_api$start(payload), error = function(e) {
        rv$error <- format_user_error(e, i18n = i18n, context_key = "modules.intervention_designer.context_run")
        showNotification(rv$error, type = "error")
        NULL
      })
    })

    observe({
      job <- rv$job
      req(job)
      invalidateLater(1000)
      st <- tryCatch(job_api$poll(job),
                     error = function(e) list(state = "error", reason = "engine", message = conditionMessage(e)))
      if (identical(st$state, "running")) { rv$progress <- st; return() }
      rv$job <- NULL
      rv$progress <- NULL
      if (identical(st$state, "done")) {
        rv$result <- st$result
        rv$analysis_complete <- TRUE
        rv$stale <- FALSE; rv$compare <- NULL
      } else {
        # The raw worker text goes to the log (format_user_error logs it) and to
        # rv$error_detail; the page shows only the translated message (spec §7).
        rv$error_detail <- st$message %||% ""
        # i18n-ref: modules.intervention_designer.context_timeout
        # i18n-ref: modules.intervention_designer.context_job
        ctx <- if (identical(st$reason, "timeout")) "modules.intervention_designer.context_timeout"
               else "modules.intervention_designer.context_job"
        rv$error <- format_user_error(simpleError(rv$error_detail), i18n = i18n, context_key = ctx)
        showNotification(rv$error, type = "error")
      }
    })

    observeEvent(input$cancel, {
      if (is.null(rv$job)) return()              # stale click after the job finished
      job_api$cancel(rv$job)
      rv$job <- NULL; rv$progress <- NULL
      showNotification(i18n$t("modules.intervention_designer.cancelled"), type = "message")
    })

    session$onSessionEnded(function() {
      j <- isolate(rv$job)
      if (!is.null(j)) job_api$cancel(j)
      cj <- isolate(rv$cmp_job)
      if (!is.null(cj)) job_api$cancel(cj)
    })

    # ── Results ────────────────────────────────────────────────────────────
    precheck_alert <- function(status) {
      # i18n-ref: modules.intervention_designer.precheck.passed
      # i18n-ref: modules.intervention_designer.precheck.topology_change_needed
      # i18n-ref: modules.intervention_designer.precheck.skipped
      # i18n-ref: modules.intervention_designer.precheck.unavailable
      cls <- switch(status, passed = "alert-success", topology_change_needed = "alert-warning",
                    "alert-secondary")
      div(class = paste("alert py-2", cls), i18n$t(paste0("modules.intervention_designer.precheck.", status)))
    }

    # Pre-check (once known) and progress bar: re-rendered on every progress tick,
    # so it lives in its own output, away from the Cancel button.
    output$progress_ui <- renderUI({
      req(rv$job)
      pr <- rv$progress
      pct <- if (!is.null(pr) && is.finite(pr$total) && pr$total > 0) round(100 * pr$done / pr$total) else 0
      # Pre-check first (spec §6): on "topology change needed" the user can Cancel
      tagList(
        if (!is.null(pr$precheck)) precheck_alert(pr$precheck),
        div(class = "progress mb-2", div(class = "progress-bar", role = "progressbar",
                                         style = sprintf("width: %d%%", pct), sprintf("%d%%", pct))))
    })

    output$results_ui <- renderUI({
      if (!is.null(rv$job)) {
        # Static while the job runs (depends on rv$job only), so Cancel clicks are not lost
        return(bs4Card(title = i18n$t("modules.intervention_designer.running"), width = 12, collapsible = FALSE,
          uiOutput(ns("progress_ui")),
          actionButton(ns("cancel"), i18n$t("modules.intervention_designer.cancel"),
                       icon = icon("stop"), class = "btn-outline-danger")))
      }
      if (!is.null(rv$error)) return(div(class = "alert alert-danger", rv$error))
      r <- rv$result
      if (is.null(r)) return(div(class = "text-muted mt-4", i18n$t("modules.intervention_designer.help_designer")))
      fmt <- function(x) format(x, big.mark = ",", scientific = FALSE)
      # i18n-ref: modules.intervention_designer.sampled
      # i18n-ref: modules.intervention_designer.exhaustive
      tagList(
        precheck_alert(r$precheck$status),
        bs4Card(title = i18n$t("modules.intervention_designer.result_share"), width = 12, collapsible = FALSE,
          h4(sprintf("%s / %s (%.1f%%)", fmt(r$n_a), fmt(r$n_eval), 100 * r$share)),
          if (isTRUE(r$sampled)) p(class = "text-warning small", i18n$t("modules.intervention_designer.estimate_note")),
          tags$ul(class = "small",
            tags$li(i18n$t("modules.intervention_designer.result_pass_a"), ": ", fmt(r$n_a)),
            tags$li(i18n$t("modules.intervention_designer.result_pass_ab"), ": ", fmt(r$n_ab)),
            tags$li(i18n$t("modules.intervention_designer.result_pass_abc"), ": ", fmt(r$n_abc))),
          if (isTRUE(r$stability_partial))
            p(class = "text-warning small", i18n$t("modules.intervention_designer.stability_partial")),
          tags$small(class = "text-muted",
                     i18n$t("modules.intervention_designer.run_meta"), ": ",
                     r$seed, " / ", r$steps, " / ", r$window, " · ",
                     i18n$t("modules.intervention_designer.grid_size"), ": ", fmt(r$n_total), " (",
                     i18n$t(if (isTRUE(r$sampled)) "modules.intervention_designer.sampled"
                            else "modules.intervention_designer.exhaustive"), ") · ",
                     i18n$t("modules.intervention_designer.elapsed"), ": ", sprintf("%.1f s", r$elapsed_s))),
        bs4Card(title = i18n$t("modules.intervention_designer.top_heading"), width = 12, collapsible = FALSE,
          DT::DTOutput(ns("top_table")),
          p(class = "text-muted small mt-2", i18n$t("modules.intervention_designer.select_row_hint")),
          plotly::plotlyOutput(ns("compare_plot"), height = "350px")),
        uiOutput(ns("dependence_ui")),
        bs4Card(title = i18n$t("modules.intervention_designer.compare_heading"), width = 12, collapsible = FALSE,
          actionButton(ns("compare"), i18n$t("modules.intervention_designer.compare_structure"), icon = icon("project-diagram")),
          actionButton(ns("apply"), i18n$t("modules.intervention_designer.apply"), icon = icon("save"),
                       class = "btn-primary ml-2"),
          uiOutput(ns("compare_ui")))
      )
    })

    # The top table's data (a reactive so tests can read it: DT sends rows by ajax)
    top_df <- reactive({
      r <- rv$result; req(r)
      yn <- function(x) ifelse(x %in% TRUE, i18n$t("modules.intervention_designer.yes"),
                               i18n$t("modules.intervention_designer.no"))
      # (c) is only checked for rows that passed (a); NA means "not evaluated"
      yn_c <- function(x) ifelse(is.na(x), "\u2014", yn(x))
      e <- r$design_matrix$edges
      # One row per top configuration, one column per variable edge (also with a single edge,
      # where apply() would simplify to a vector)
      lv <- as.data.frame(t(matrix(lvl_label(r$top_levels), nrow = nrow(r$top_levels))),
                          stringsAsFactors = FALSE)
      names(lv) <- paste(e$from, "→", e$to)
      df <- cbind(data.frame(r$top$rank, yn(r$top$a), yn(r$top$b), yn_c(r$top$c), r$top$d,
                             stringsAsFactors = FALSE), lv)
      names(df)[1:5] <- c(i18n$t("modules.intervention_designer.col_rank"),
                          i18n$t("modules.intervention_designer.col_a"),
                          i18n$t("modules.intervention_designer.col_b"),
                          i18n$t("modules.intervention_designer.col_c"),
                          i18n$t("modules.intervention_designer.col_d"))
      df
    })
    output$top_table <- DT::renderDT({
      DT::datatable(top_df(), selection = "single", rownames = FALSE,
                    options = list(pageLength = 10, scrollX = TRUE, dom = "tip"))
    })

    # Uses the network, initial state and steps stored with the result (review
    # focus 3), stepped like the grid, so signs agree with criteria (a)/(b).
    selected_comparison <- reactive({
      r <- rv$result; i <- input$top_table_rows_selected
      req(r, length(i) == 1)
      nodes <- rownames(r$base)
      fo <- ses_config_final_state(r$base, r$x0[seq_along(nodes)], r$steps)
      fi <- ses_config_final_state(ses_apply_config(r$design_matrix, r$top_levels[, i]), r$x0, r$steps)
      data.frame(node = nodes, state_original = unname(fo[nodes]), state_intervention = unname(fi[nodes]),
                 delta = unname(fi[nodes] - fo[nodes]), stringsAsFactors = FALSE)
    })

    output$compare_plot <- plotly::renderPlotly({
      cmp <- selected_comparison()
      plotly::plot_ly(cmp, x = ~node) |>
        plotly::add_bars(y = ~state_original, name = i18n$t("modules.intervention_designer.compare_original")) |>
        plotly::add_bars(y = ~state_intervention, name = i18n$t("modules.intervention_designer.compare_selected")) |>
        plotly::layout(title = i18n$t("modules.intervention_designer.compare_title"), barmode = "group",
                       xaxis = list(title = ""),
                       yaxis = list(title = i18n$t("modules.intervention_designer.compare_state")))
    })

    # ── Dependence table, structure comparison, Apply to project (WS-7b) ───
    selected_levels <- reactive({
      r <- rv$result; i <- input$top_table_rows_selected
      req(r, length(i) == 1)
      r$top_levels[, i]
    })
    cld_now <- reactive(project_data_reactive()$data$cld)

    output$dependence_ui <- renderUI({
      dep <- rv$result$dependence
      if (is.null(dep)) return(NULL)
      pct <- function(x) sprintf("%.0f%%", 100 * x)
      rows <- lapply(seq_len(nrow(dep)), function(k) {
        shares <- paste(paste(lvl_label(dep$levels[[k]]), pct(dep$shares[[k]])), collapse = " · ")
        verdict <- if (isTRUE(dep$decisive[k])) {
          strong(i18n$t("modules.intervention_designer.dependence_needs"), " ",
                 dep$from[k], " → ", dep$to[k], " ", i18n$t("modules.intervention_designer.dependence_at"), " ",
                 paste(lvl_label(dep$needed_levels[[k]]), collapse = ", "))
        } else if (isFALSE(dep$decisive[k])) {
          span(class = "text-muted", i18n$t("modules.intervention_designer.dependence_any"))
        }
        tags$tr(tags$td(paste(dep$from[k], "→", dep$to[k])), tags$td(class = "small", shares), tags$td(verdict))
      })
      bs4Card(title = i18n$t("modules.intervention_designer.dependence_heading"), width = 12, collapsible = FALSE,
        if (anyNA(dep$decisive)) p(class = "text-warning small", i18n$t("modules.intervention_designer.dependence_few")),
        if (isTRUE(rv$result$sampled)) p(class = "text-muted small", i18n$t("modules.intervention_designer.dependence_estimated")),
        tags$table(class = "table table-sm",
          tags$thead(tags$tr(tags$th(i18n$t("modules.intervention_designer.col_link")),
                             tags$th(i18n$t("modules.intervention_designer.col_shares")), tags$th(""))),
          tags$tbody(rows)))
    })

    # i18n-ref: modules.intervention_designer.context_compare
    # Compare/Apply are disabled while the results are stale or a job is active (spec 4.5);
    # the click-time guards below stay as a backstop.
    observe({
      ok <- !isTRUE(rv$stale) && is.null(rv$job) && is.null(rv$cmp_job)
      shinyjs::toggleState("compare", condition = ok)
      shinyjs::toggleState("apply", condition = ok)
    })
    # A comparison belongs to one selected row: never show another row's
    observeEvent(input$top_table_rows_selected, { rv$compare <- NULL }, ignoreNULL = FALSE)
    observeEvent(input$compare, {
      if (isTRUE(rv$stale)) { showNotification(i18n$t("modules.intervention_designer.apply_stale"), type = "warning"); return() }
      if (!length(input$top_table_rows_selected)) {
        showNotification(i18n$t("modules.intervention_designer.need_row"), type = "warning"); return()
      }
      if (!is.null(rv$job) || !is.null(rv$cmp_job)) return()
      r <- rv$result; lv <- selected_levels()
      payload <- tryCatch(list(
        baseline = cld_now(), config = ses_config_network(r$design_matrix, lv, cld_now(), Sys.time()),
        base_matrix = r$base, config_matrix = ses_apply_config(r$design_matrix, lv),
        objectives = r$objectives, max_boolean_nodes = DYNAMICS_MAX_BOOLEAN_NODES), error = function(e) e)
      if (inherits(payload, "error")) {
        showNotification(format_user_error(payload, i18n = i18n, context_key = "modules.intervention_designer.context_compare"),
                         type = "error"); return()
      }
      rv$compare <- NULL
      rv$cmp_job <- tryCatch(job_api$start_compare(payload), error = function(e) {
        showNotification(format_user_error(e, i18n = i18n, context_key = "modules.intervention_designer.context_compare"),
                         type = "error"); NULL })
    })
    observe({
      job <- rv$cmp_job
      req(job)
      invalidateLater(1000)
      st <- tryCatch(job_api$poll(job), error = function(e) list(state = "error", message = conditionMessage(e)))
      if (identical(st$state, "running")) return()
      rv$cmp_job <- NULL
      if (identical(st$state, "done")) rv$compare <- st$result
      else showNotification(format_user_error(simpleError(st$message %||% ""), i18n = i18n,
                                              context_key = "modules.intervention_designer.context_compare"), type = "error")
    })

    output$compare_ui <- renderUI({
      if (!is.null(rv$cmp_job)) return(p(class = "text-muted mt-2", i18n$t("modules.intervention_designer.compare_running")))
      cmp <- rv$compare
      if (is.null(cmp)) return(NULL)
      cnt <- function(l, type) sum(vapply(l$loops, function(x) identical(x$type, type), logical(1)))
      loop_list <- function(x) if (!length(x)) i18n$t("modules.intervention_designer.none") else
        tags$ul(class = "small", lapply(x, function(n) tags$li(paste(n, collapse = " → "))))
      lev_b <- cmp$leverage$baseline$Name; lev_c <- cmp$leverage$config$Name
      at <- function(v, i) if (i > length(v) || is.na(v[i])) "" else as.character(v[i])   # NA / out of range -> ""
      att <- function(a) if (!identical(a$status, "passed") && !identical(a$status, "topology_change_needed"))
        i18n$t("modules.intervention_designer.attractors_skipped") else
        paste0(i18n$t("modules.intervention_designer.attractors_total"), ": ", a$n_attractors, " · ",
               i18n$t("modules.intervention_designer.attractors_desirable"), ": ", a$n_desirable)
      tagList(
        h6(class = "mt-3", i18n$t("modules.intervention_designer.loops_heading")),
        tags$table(class = "table table-sm",
          tags$thead(tags$tr(tags$th(""), tags$th(i18n$t("modules.intervention_designer.col_before")),
                             tags$th(i18n$t("modules.intervention_designer.col_after")))),
          tags$tbody(
            tags$tr(tags$td(i18n$t("modules.intervention_designer.loops_reinforcing")),
                    tags$td(cnt(cmp$loops$baseline, "Reinforcing")), tags$td(cnt(cmp$loops$config, "Reinforcing"))),
            tags$tr(tags$td(i18n$t("modules.intervention_designer.loops_balancing")),
                    tags$td(cnt(cmp$loops$baseline, "Balancing")), tags$td(cnt(cmp$loops$config, "Balancing"))))),
        if (isTRUE(cmp$loop_diff$truncated)) p(class = "text-warning small", i18n$t("modules.intervention_designer.loops_truncated")),
        strong(i18n$t("modules.intervention_designer.loops_gained")), loop_list(cmp$loop_diff$gained),
        strong(i18n$t("modules.intervention_designer.loops_lost")), loop_list(cmp$loop_diff$lost),
        strong(i18n$t("modules.intervention_designer.loops_changed")), loop_list(cmp$loop_diff$changed),
        h6(class = "mt-3", i18n$t("modules.intervention_designer.leverage_heading")),
        tags$table(class = "table table-sm",
          tags$thead(tags$tr(tags$th("#"), tags$th(i18n$t("modules.intervention_designer.col_before")),
                             tags$th(i18n$t("modules.intervention_designer.col_after")))),
          tags$tbody(lapply(seq_len(max(length(lev_b), length(lev_c))), function(i) {
            after <- at(lev_c, i)
            moved <- if (!nzchar(after)) "" else {
              j <- match(after, lev_b)
              if (is.na(j)) paste0(" (", i18n$t("modules.intervention_designer.leverage_new"), ")")
              else if (j > i) " ↑" else if (j < i) " ↓" else ""
            }
            tags$tr(tags$td(i), tags$td(at(lev_b, i)), tags$td(paste0(after, moved)))
          }))),
        h6(class = "mt-3", i18n$t("modules.intervention_designer.attractors_heading")),
        tags$ul(class = "small",
          tags$li(i18n$t("modules.intervention_designer.col_before"), ": ", att(cmp$attractors$baseline)),
          tags$li(i18n$t("modules.intervention_designer.col_after"), ": ", att(cmp$attractors$config)))
      )
    })

    observeEvent(input$apply, {
      if (isTRUE(rv$stale)) { showNotification(i18n$t("modules.intervention_designer.apply_stale"), type = "warning"); return() }
      if (!is.null(rv$job) || !is.null(rv$cmp_job)) return()
      if (!length(input$top_table_rows_selected)) {
        showNotification(i18n$t("modules.intervention_designer.need_row"), type = "warning"); return()
      }
      r <- rv$result; i <- input$top_table_rows_selected
      label <- r$design_matrix$new_node %||% i18n$t("modules.intervention_designer.reweight_heading")
      showModal(modalDialog(
        title = i18n$t("modules.intervention_designer.apply_title"),
        textInput(ns("apply_name"), i18n$t("modules.intervention_designer.apply_name"),
                  value = sprintf("%s — %s #%d", label, i18n$t("modules.intervention_designer.configuration"), r$top$rank[i])),
        textAreaInput(ns("apply_description"), i18n$t("modules.intervention_designer.apply_description"), rows = 3,
                      value = sprintf("%s: seed %s, %s/%s (%.1f%%), a=%s b=%s c=%s d=%s",
                                      i18n$t("modules.intervention_designer.apply_summary"), r$seed,
                                      format(r$n_a, big.mark = ","), format(r$n_eval, big.mark = ","), 100 * r$share,
                                      r$top$a[i], r$top$b[i], r$top$c[i], r$top$d[i])),
        footer = tagList(modalButton(i18n$t("common.buttons.cancel")),
                         actionButton(ns("confirm_apply"), i18n$t("modules.intervention_designer.apply_confirm"),
                                      class = "btn-primary"))))
    })
    # i18n-ref: modules.intervention_designer.context_apply
    observeEvent(input$confirm_apply, {
      if (isTRUE(rv$stale)) { showNotification(i18n$t("modules.intervention_designer.apply_stale"), type = "warning"); return() }
      if (!is.null(rv$job) || !is.null(rv$cmp_job)) return()
      req(length(input$top_table_rows_selected) == 1)
      r <- rv$result
      data <- project_data_reactive()
      if (exists("migrate_legacy_scenarios", mode = "function")) data <- migrate_legacy_scenarios(data)
      existing <- data$data$analysis$scenarios %||% list()
      tp <- input$type %||% ""
      sc <- tryCatch(ses_config_to_scenario(r$design_matrix, selected_levels(), data$data$cld, list(
        name = .scenario_unique_name(trimws(input$apply_name %||% ""), vapply(existing, function(s) s$name %||% "", "")),
        description = input$apply_description %||% "",
        intervention_type = tp,
        ebm_code = if (nzchar(tp)) paste(unlist(get_intervention_ebm_codes(tp)), collapse = ";") else NA_character_,
        now = Sys.time())), error = function(e) e)
      if (inherits(sc, "error")) {
        showNotification(format_user_error(sc, i18n = i18n, context_key = "modules.intervention_designer.context_apply"),
                         type = "error"); return()
      }
      if (!is.list(data$data$analysis)) data$data$analysis <- list()
      data$data$analysis$scenarios <- c(existing, list(sc))
      data$last_modified <- Sys.time()
      project_data_reactive(data)
      removeModal()
      showNotification(i18n$t("modules.intervention_designer.applied"), type = "message")
    })
  })
}
