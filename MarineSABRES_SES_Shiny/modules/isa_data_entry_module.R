# ISA Data Entry Module
# Implements the Integrated Systems Analysis (ISA) framework
# Based on MarineSABRES Simple SES DRAFT Guidance
# Follows the DAPSI(W)R(M) framework for marine ecosystem analysis

# Module UI ----
isa_data_entry_ui <- function(id, i18n) {
  # Enable reactive translation updates for this module
  tryCatch(shiny.i18n::usei18n(i18n$translator %||% i18n), error = function(e) NULL)
  ns <- NS(id)

  tagList(

    fluidRow(
      column(12,
        uiOutput(ns("isa_header"))
      )
    ),

    # Navigation: Breadcrumb and Progress Bar
    fluidRow(
      column(12,
        uiOutput(ns("navigation_ui"))
      )
    ),

    fluidRow(
      column(12,
        uiOutput(ns("isa_tabs_ui"))
      )
    ),

    # Navigation: Previous/Next Buttons
    fluidRow(
      column(12,
        uiOutput(ns("nav_buttons_ui"))
      )
    )
  )
}

# ── M12: user_edited_matrices persistence helpers ──────────────────────────────
#
# Pure (non-reactive) function exported at module-file scope so it is testable
# without instantiating a Shiny session.
#
# Restores user_edited_matrices from a previously-saved project into the
# shape of the current (post-reconcile) adjacency_matrices.  For each key:
#   - If saved_ue has the key AND dimnames have common rows/cols, TRUE cells
#     are projected into the new (possibly larger/smaller) matrix.
#   - If saved_ue is NULL / empty / missing a key, falls back to all-FALSE
#     (safe default for old saves that pre-date M12).
#
# @param saved_ue   Named list of logical matrices from saved project
#                   (project$data$isa_data$user_edited_matrices), or NULL.
# @param adj_matrices Named list of character matrices (adjacency_matrices),
#                   used to determine the required dims/dimnames for each key.
# @return Named list of logical matrices aligned to adj_matrices.
restore_user_edited_matrices <- function(saved_ue, adj_matrices) {
  result <- list()
  if (!is.list(adj_matrices) || length(adj_matrices) == 0) return(result)

  for (mk in names(adj_matrices)) {
    adj <- adj_matrices[[mk]]
    if (!is.matrix(adj)) {
      next
    }
    nr <- nrow(adj); nc <- ncol(adj)
    rn <- rownames(adj); cn <- colnames(adj)

    # Default: all-FALSE matrix with correct dims
    out_ue <- matrix(FALSE, nrow = nr, ncol = nc, dimnames = list(rn, cn))

    # Overlay from saved_ue where dimnames overlap (safe for size changes)
    if (is.list(saved_ue) && !is.null(saved_ue[[mk]]) &&
        is.matrix(saved_ue[[mk]]) && is.logical(saved_ue[[mk]])) {
      s <- saved_ue[[mk]]
      common_rows <- intersect(rownames(s), rn)
      common_cols <- intersect(colnames(s), cn)
      if (length(common_rows) > 0 && length(common_cols) > 0) {
        out_ue[common_rows, common_cols] <- s[common_rows, common_cols]
      }
    }

    result[[mk]] <- out_ue
  }
  result
}
# ──────────────────────────────────────────────────────────────────────────────

# Module Server ----
# Standardized signature: (id, project_data_reactive, i18n, event_bus)
isa_data_entry_server <- function(id, project_data_reactive, i18n, event_bus = NULL, parent_session = NULL) {
  # Legacy alias for backwards compatibility within module
  global_data <- project_data_reactive
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # Note: Module validation helpers are loaded in global.R

    # Reactive values to store all ISA data ----
    isa_data <- reactiveValues(
      # Exercise 0
      case_info = list(),

      # Exercise 1: Goods & Benefits
      goods_benefits = data.frame(
        ID = character(),
        Name = character(),
        Type = character(),
        Description = character(),
        Stakeholder = character(),
        Importance = character(),
        Trend = character()
        
      ),
      gb_counter = 0,

      # Exercise 2a: Ecosystem Services
      ecosystem_services = data.frame(
        ID = character(),
        Name = character(),
        Type = character(),
        Description = character(),
        LinkedGB = character(),
        Mechanism = character(),
        Confidence = character()
        
      ),
      es_counter = 0,

      # Exercise 2b: Marine Processes
      marine_processes = data.frame(
        ID = character(),
        Name = character(),
        Type = character(),
        Description = character(),
        LinkedES = character(),
        Mechanism = character(),
        Spatial = character()
        
      ),
      mpf_counter = 0,

      # Exercise 3: Pressures
      pressures = data.frame(
        ID = character(),
        Name = character(),
        Type = character(),
        Description = character(),
        LinkedMPF = character(),
        Intensity = character(),
        Spatial = character(),
        Temporal = character()
        
      ),
      p_counter = 0,

      # Exercise 4: Activities
      activities = data.frame(
        ID = character(),
        Name = character(),
        Sector = character(),
        Description = character(),
        LinkedP = character(),
        Scale = character(),
        Frequency = character()
        
      ),
      a_counter = 0,

      # Exercise 5: Drivers
      drivers = data.frame(
        ID = character(),
        Name = character(),
        Type = character(),
        Description = character(),
        LinkedA = character(),
        Trend = character(),
        Controllability = character()
        
      ),
      d_counter = 0,

      # Ordered stable-ID trackers (single source of truth for collection).
      # A row's ID is allocated once at panel creation and never renumbered,
      # so removing/reordering panels does not invalidate LinkedX refs or
      # ID-keyed matrices (fixes feedback #2/#3/#4).
      gb_panel_ids  = character(0),
      es_panel_ids  = character(0),
      mpf_panel_ids = character(0),
      p_panel_ids   = character(0),
      a_panel_ids   = character(0),
      d_panel_ids   = character(0),
      r_panel_ids   = character(0),
      r_counter     = 0,
      responses     = data.frame(
        ID = character(), Name = character(), Type = character(),
        Description = character(), Stakeholder = character(),
        Importance = character(), Trend = character(),
        LinkedGB = character(), LinkedD = character(),
        LinkedA = character(), LinkedP = character(),
        stringsAsFactors = FALSE
      ),

      # Exercise 6: Loop closure
      loop_connections = data.frame(
        DriverID = character(),
        GBID = character(),
        Effect = character(),
        Strength = character(),
        Confidence = integer(),
        Mechanism = character()
        
      ),

      # BOT data
      bot_data = data.frame(
        ElementType = character(),
        ElementID = character(),
        Year = numeric(),
        Value = numeric(),
        Unit = character()
        
      ),

      # Exercises 10-12
      clarification = list(),
      validation = list(),

      # ID-keyed connection matrices, rebuilt from the LinkedX columns on each
      # save_ex* (the N:M reconciler). user_edited_matrices marks cells the user
      # hand-edited so a rebuild preserves them.
      adjacency_matrices = list(),
      user_edited_matrices = list()
    )

    # Per-session stable-ID counter store. Isolated per moduleServer instance so
    # concurrent users never share an id sequence (the load path re-seeds it).
    id_store <- new_stable_id_store()

    # Initialize ISA data from project_data_reactive if it exists (e.g., from AI Assistant) ----
    # This observer loads saved data when the module starts or when project_data_reactive changes
    data_initialized <- reactiveVal(FALSE)

    # Navigation state ----
    # Define tab structure for navigation
    tab_names <- c(
      "Exercise 0: Complexity",
      "Exercise 1: Goods & Benefits",
      "Exercise 2a: Ecosystem Services",
      "Exercise 2b: Marine Processes",
      "Exercise 3: Pressures",
      "Exercise 4: Activities",
      "Exercise 5: Drivers",
      "Exercise 6: Closing Loop",
      "Responses & Measures",
      "Exercises 7-9: CLD",
      "Exercises 10-12: Analysis",
      "BOT Graphs",
      "Data Management"
    )

    # Track current exercise (1-indexed, 1 = Exercise 0)
    current_exercise <- reactiveVal(1)

    # Persist module state back into project_data_reactive. Called after every
    # save_exN observer and after each per-panel remove so ISA edits survive
    # session restarts and reach the project save file. Mirrors the v1.12.0
    # pims_stakeholder / response_module persistence pattern.
    sync_to_project_data <- function() {
      pd <- project_data_reactive()
      if (is.null(pd)) return(invisible(NULL))
      if (is.null(pd$data)) pd$data <- list()
      if (is.null(pd$data$isa_data)) pd$data$isa_data <- list()

      pd$data$isa_data$goods_benefits     <- isa_data$goods_benefits
      pd$data$isa_data$ecosystem_services <- isa_data$ecosystem_services
      pd$data$isa_data$marine_processes   <- isa_data$marine_processes
      pd$data$isa_data$pressures          <- isa_data$pressures
      pd$data$isa_data$activities         <- isa_data$activities
      pd$data$isa_data$drivers            <- isa_data$drivers

      if (!is.null(isa_data$adjacency_matrices)) {
        pd$data$isa_data$adjacency_matrices <- isa_data$adjacency_matrices
        # M12: persist user-edited-cell flags so they survive a save/reload cycle
        pd$data$isa_data$user_edited_matrices <- isa_data$user_edited_matrices
      }
      if (!is.null(isa_data$loop_connections)) {
        pd$data$isa_data$loop_connections <- isa_data$loop_connections
      }
      if (length(isa_data$case_info) > 0) {
        pd$data$isa_data$case_info <- isa_data$case_info
      }

      project_data_reactive(pd)
    }

    # Rebuild one source->target connection matrix from an element's LinkedX
    # column, preserving user-edited cells and surfacing stale/dropped edges.
    # Completes the N:M wiring for es_gb / mpf_es / p_mpf / a_p / d_a (gb_d keeps
    # its own closing-loop builder). Fixes the "no diagram" symptom (#4) where
    # only gb_d was ever built.
    rebuild_transition <- function(element_df, linked_col, target_ids, matrix_key) {
      tryCatch({
        rebuilt <- rebuild_matrix_from_linked(
          element_df = element_df, linked_col = linked_col,
          source_ids = element_df$ID, target_ids = target_ids,
          element_confidence_col = "Confidence",
          existing_matrix    = isa_data$adjacency_matrices[[matrix_key]],
          user_edited_matrix = isa_data$user_edited_matrices[[matrix_key]])
        isa_data$adjacency_matrices[[matrix_key]]   <- rebuilt$matrix
        isa_data$user_edited_matrices[[matrix_key]] <- rebuilt$user_edited
        if (length(rebuilt$stale_linked_ids) > 0) {
          showNotification(paste(i18n$t("modules.isa.data_entry.common.stale_linked_ids_skipped"),
                           paste(rebuilt$stale_linked_ids, collapse = ", ")),
                           type = "warning", duration = 6, session = session)
        }
        if (length(rebuilt$dropped_user_edits) > 0) {
          showNotification(paste(i18n$t("modules.isa.data_entry.common.dropped_user_edits"),
                           length(rebuilt$dropped_user_edits)),
                           type = "warning", duration = 8, session = session)
        }
      }, error = function(e) {
        debug_log(paste(matrix_key, "rebuild failed:", e$message), "ERROR")
        showNotification(format_user_error(e, i18n = i18n,
                         context_key = "common.messages.context_matrix_rebuild"),
                         type = "error", session = session)
      })
    }

    # Apply a saved/imported isa_data list into this module's reactiveValues.
    # = load_isa_elements_from_saved (copies element dfs, adjacency_matrices,
    #   loop_connections, case_info) + the L6-hardened id reconcile loop that
    #   canonicalizes IDs and sets *_panel_ids. Shared by the project-load
    #   observer and the Excel import handler. Caller sets data_initialized().
    apply_saved_isa <- function(saved_isa) {
      # Copies counters, loop_connections, case_info, bot_data, and the saved
      # matrices into the module reactiveValues (element dfs get lowercased here
      # for the table view, then overwritten below with the reconciled versions).
      load_isa_elements_from_saved(isa_data, saved_isa)

      # Reconcile element IDs (repairing legacy duplicates) and rebuild empty
      # forward matrices from label-form LinkedX (resolved BY NAME) via the
      # shared pure pipeline — the SAME recovery the sidebar Import Data menu
      # uses, so both import doors behave identically.
      # NB: recover_isa_data reconciles the RAW saved df (uppercase ID), NOT the
      # lowercased copy load_isa_elements_from_saved just wrote — keying on
      # lowercase 'id' was the L6 'no elements' bug.
      rec <- recover_isa_data(saved_isa, id_store)
      for (k in names(rec$elements)) {
        if (nrow(rec$elements[[k]]) > 0) isa_data[[k]] <- rec$elements[[k]]
      }
      for (p in names(rec$panel_ids)) isa_data[[p]] <- rec$panel_ids[[p]]
      isa_data$adjacency_matrices <- rec$adjacency_matrices
      # M12: restore saved user-edited flags (fall back to all-FALSE for old saves).
      # restore_user_edited_matrices() aligns dims to the post-reconcile adjacency_matrices,
      # then overlays saved TRUE cells by dimname intersection — safe for size changes.
      # rec$user_edited_matrices only holds all-FALSE entries for fell-back matrices;
      # the SAVED flags (from project$data$isa_data$user_edited_matrices, written by the
      # fixed sync_to_project_data) are the authoritative source for user edits.
      isa_data$user_edited_matrices <- restore_user_edited_matrices(
        saved_ue     = saved_isa$user_edited_matrices,
        adj_matrices = isa_data$adjacency_matrices
      )
      any_repaired      <- rec$repaired
      any_rows_in       <- rec$any_rows_in
      any_panel_ids_out <- rec$any_panel_ids_out
      fell_back         <- rec$fell_back

      if (any_repaired) {
        showNotification(i18n$t("modules.isa.data_entry.common.ids_repaired_on_load"),
                         type = "warning", duration = 8, session = session)
      }
      if (any_rows_in && !any_panel_ids_out) {
        showNotification(i18n$t("modules.isa.data_entry.common.no_elements_loaded"),
                         type = "warning", duration = 10, session = session)
      }
      invisible(list(fell_back = fell_back))
    }

    # Load saved ISA data when a (different) project becomes active. Keyed on
    # project_id so module saves don't re-trigger a load and clobber edits.
    observeEvent(project_data_reactive()$project_id, {
      project <- project_data_reactive()
      if (!is.null(project) && !is.null(project$data) && !is.null(project$data$isa_data)) {
        debug_log("Loading saved ISA data on project change", "ISA Module")
        apply_saved_isa(project$data$isa_data)
        data_initialized(TRUE)
      } else {
        debug_log("No saved ISA data found - starting fresh", "ISA Module")
      }
    }, ignoreNULL = FALSE)

    # Render ISA header ----
    output$isa_header <- renderUI({
      create_module_header(
        ns = ns,
        title_key = "modules.isa.data_entry.title",
        subtitle_key = "modules.isa.data_entry.subtitle",
        help_id = "help_main",
        i18n = i18n
      )
    })

    # Render tab panel UI with translated titles ----
    output$isa_tabs_ui <- renderUI({
      tabsetPanel(id = ns("isa_tabs"),
        tabPanel(i18n$t("modules.isa.data_entry.ex0.exercise_0_complexity"),
          uiOutput(ns("exercise_0_content"))
        ),
        tabPanel(i18n$t("modules.isa.data_entry.ex1.exercise_1_goods_benefits"),
          uiOutput(ns("exercise_1_content"))
        ),
        tabPanel(i18n$t("modules.isa.data_entry.ex2a.exercise_2a_ecosystem_services"),
          uiOutput(ns("exercise_2a_content"))
        ),
        tabPanel(i18n$t("modules.isa.data_entry.ex2b.exercise_2b_marine_processes"),
          uiOutput(ns("exercise_2b_content"))
        ),
        tabPanel(i18n$t("modules.isa.data_entry.ex3.exercise_3_pressures"),
          uiOutput(ns("exercise_3_content"))
        ),
        tabPanel(i18n$t("modules.isa.data_entry.ex4.exercise_4_activities"),
          uiOutput(ns("exercise_4_content"))
        ),
        tabPanel(i18n$t("modules.isa.data_entry.ex1.exercise_5_drivers"),
          uiOutput(ns("exercise_5_content"))
        ),
        tabPanel(i18n$t("modules.isa.data_entry.ex6.exercise_6_closing_loop"),
          uiOutput(ns("exercise_6_content"))
        ),
        tabPanel(i18n$t("modules.isa.data_entry.responses.tab_title"),
          uiOutput(ns("responses_content"))
        ),
        tabPanel(i18n$t("modules.isa.data_entry.common.exercises_7_9_cld"),
          uiOutput(ns("exercise_789_content"))
        ),
        tabPanel(i18n$t("modules.isa.data_entry.common.exercises_10_12_analysis"),
          uiOutput(ns("exercise_101112_content"))
        ),
        tabPanel(i18n$t("modules.isa.data_entry.common.bot_graphs"),
          uiOutput(ns("bot_graphs_content"))
        ),
        tabPanel(i18n$t("modules.isa.data_entry.common.data_management"),
          uiOutput(ns("data_management_content"))
        )
      )
    })

    # Render Navigation UI (breadcrumb + progress bar) ----
    output$navigation_ui <- renderUI({
      current <- current_exercise()
      total <- length(tab_names)

      tagList(
        # Breadcrumb
        create_breadcrumb(
          items = list(
            list(label = i18n$t("common.labels.home"), icon = "home"),
            list(label = i18n$t("modules.isa.data_entry.title"), icon = "clipboard"),
            list(label = tab_names[current])
          ),
          i18n = i18n
        ),

        # Progress Bar
        create_progress_bar(
          current = current,
          total = total,
          title = i18n$t("modules.isa.data_entry.exercise_progress"),
          i18n = i18n
        )
      )
    })

    # Render Navigation Buttons ----
    output$nav_buttons_ui <- renderUI({
      current <- current_exercise()
      total <- length(tab_names)

      create_nav_buttons(
        ns = ns,
        show_back = current > 1,
        show_next = current < total,
        back_enabled = current > 1,
        next_enabled = current < total,
        next_label = if (current == total - 1) "Finish" else "Next",
        i18n = i18n
      )
    })

    # Navigation Observers ----
    # Handle Back button click
    observeEvent(input$nav_back, {
      current <- current_exercise()
      if (current > 1) {
        new_index <- current - 1
        current_exercise(new_index)

        # Update tabsetPanel to show previous tab
        updateTabsetPanel(
          session = session,
          inputId = "isa_tabs",
          selected = i18n$t(tab_names[new_index])
        )
      }
    })

    # Handle Next button click
    observeEvent(input$nav_next, {
      current <- current_exercise()
      total <- length(tab_names)
      if (current < total) {
        new_index <- current + 1
        current_exercise(new_index)

        # Update tabsetPanel to show next tab
        updateTabsetPanel(
          session = session,
          inputId = "isa_tabs",
          selected = i18n$t(tab_names[new_index])
        )
      }
    })

    # Sync current_exercise when user manually clicks tabs
    observe({
      tab <- input$isa_tabs
      if (!is.null(tab)) {
        # Find which tab is selected based on translated name
        translated_names <- sapply(tab_names, function(name) i18n$t(name))
        index <- which(translated_names == tab)

        if (length(index) > 0) {
          current_exercise(index[1])
        }
      }
    })

    # Render Exercise 0 content ----
    output$exercise_0_content <- renderUI({
      tagList(
        div(style = "display: flex; justify-content: space-between; align-items: center;",
          h4(i18n$t("modules.isa.data_entry.ex4.unfolding_complexity_and_impacts_on_welfare")),
          actionButton(ns("help_ex0"), i18n$t("ui.header.help"), icon = icon("question-circle"), class = "btn-info btn-sm")
        ),
        wellPanel(
          p(strong(i18n$t("common.labels.purpose")), " ", i18n$t("modules.isa.understand_the_complexity_of_your_case_study_and_i")),
          p(i18n$t("modules.isa.this_preliminary_exercise_helps_you_explore_the_fu"))
        ),

        fluidRow(
          column(6,
            h5(i18n$t("modules.isa.data_entry.common.case_study_context")),
            textInput(ns("case_name"), i18n$t("common.labels.case_study_name"), placeholder = i18n$t("modules.isa.data_entry.common.eg_baltic_sea_fisheries")),
            textAreaInput(ns("case_description"), i18n$t("common.labels.brief_description"),
                         placeholder = i18n$t("modules.isa.data_entry.common.describe_your_marine_case_study_context"),
                         rows = 4),
            textInput(ns("geographic_scope"), i18n$t("modules.isa.data_entry.common.geographic_scope"), placeholder = i18n$t("modules.isa.data_entry.common.eg_baltic_sea_north_atlantic")),
            textInput(ns("temporal_scope"), i18n$t("modules.isa.data_entry.common.temporal_scope"), placeholder = i18n$t("modules.isa.data_entry.common.eg_2000_2024"))
          ),
          column(6,
            h5(i18n$t("modules.isa.data_entry.common.initial_complexity_mapping")),
            textAreaInput(ns("welfare_impacts"), i18n$t("modules.isa.data_entry.ex4.identified_welfare_impacts"),
                         placeholder = i18n$t("modules.isa.data_entry.welfare_impacts_prompt"),
                         rows = 4),
            textAreaInput(ns("key_stakeholders"), i18n$t("modules.isa.data_entry.common.key_stakeholders"),
                         placeholder = i18n$t("modules.isa.data_entry.common.who_is_affected_who_makes_decisions"),
                         rows = 4)
          )
        ),

        actionButton(ns("save_ex0"), i18n$t("modules.isa.data_entry.ex0.save_exercise_0"), class = "btn-primary"),
        hr()
      )
    })

    # Render Exercise 1 content ----
    output$exercise_1_content <- renderUI({
      tagList(
        div(style = "display: flex; justify-content: space-between; align-items: center;",
          h4(i18n$t("modules.isa.data_entry.ex789.specifying_goods_and_benefits_gb")),
          actionButton(ns("help_ex1"), i18n$t("ui.header.help"), icon = icon("question-circle"), class = "btn-info btn-sm")
        ),
        wellPanel(
          p(strong(i18n$t("common.labels.purpose")), " ", i18n$t("modules.isa.identify_and_classify_the_goods_and_benefits_deriv")),
          p(i18n$t("modules.isa.complete_columns_b_h_in_the_master_dat_sheet_each_"))
        ),

        fluidRow(
          column(12,
            h5(i18n$t("modules.isa.data_entry.ex789.add_goods_and_benefits")),
            actionButton(ns("add_gb"), i18n$t("modules.isa.data_entry.ex789.add_goodbenefit"), icon = icon("plus"), class = "btn-success"),
            hr(),
            uiOutput(ns("gb_entries"))
          )
        ),

        fluidRow(
          column(12,
            h5(i18n$t("modules.isa.data_entry.ex789.current_goods_and_benefits")),
            DTOutput(ns("gb_table"))
          )
        ),

        actionButton(ns("save_ex1"), i18n$t("modules.isa.data_entry.ex1.save_exercise_1"), class = "btn-primary"),
        hr()
      )
    })

    # Render Exercise 2a content ----
    output$exercise_2a_content <- renderUI({
      tagList(
        div(style = "display: flex; justify-content: space-between; align-items: center;",
          h4(i18n$t("modules.isa.data_entry.ex789.ecosystem_services_es_affecting_goods_and_benefits")),
          actionButton(ns("help_ex2a"), i18n$t("ui.header.help"), icon = icon("question-circle"), class = "btn-info btn-sm")
        ),
        wellPanel(
          p(strong(i18n$t("common.labels.purpose")), " ", i18n$t("modules.isa.identify_ecosystem_services_that_contribute_to_eac")),
          p(i18n$t("modules.isa.complete_columns_l_r_in_the_master_dat_sheet_link_"))
        ),

        fluidRow(
          column(12,
            h5(i18n$t("modules.isa.data_entry.ex789.add_ecosystem_services")),
            actionButton(ns("add_es"), i18n$t("modules.isa.data_entry.ex789.add_ecosystem_service"), icon = icon("plus"), class = "btn-success"),
            hr(),
            uiOutput(ns("es_entries"))
          )
        ),

        fluidRow(
          column(12,
            h5(i18n$t("modules.isa.data_entry.ex789.current_ecosystem_services")),
            DTOutput(ns("es_table"))
          )
        ),

        actionButton(ns("save_ex2a"), i18n$t("modules.isa.data_entry.ex2a.save_exercise_2a"), class = "btn-primary"),
        hr()
      )
    })

    # Render Exercise 2b content ----
    output$exercise_2b_content <- renderUI({
      tagList(
        div(style = "display: flex; justify-content: space-between; align-items: center;",
          h4(i18n$t("modules.isa.data_entry.common.marine_processes_and_functioning_mpf")),
          actionButton(ns("help_ex2b"), i18n$t("ui.header.help"), icon = icon("question-circle"), class = "btn-info btn-sm")
        ),
        wellPanel(
          p(strong(i18n$t("common.labels.purpose")), " ", i18n$t("modules.isa.identify_marine_processes_that_support_ecosystem_s")),
          p(i18n$t("modules.isa.complete_columns_u_aa_in_the_master_dat_sheet_link"))
        ),

        fluidRow(
          column(12,
            h5(i18n$t("modules.isa.data_entry.common.add_marine_processes_and_functioning")),
            actionButton(ns("add_mpf"), i18n$t("modules.isa.data_entry.common.add_marine_process"), icon = icon("plus"), class = "btn-success"),
            hr(),
            uiOutput(ns("mpf_entries"))
          )
        ),

        fluidRow(
          column(12,
            h5(i18n$t("modules.isa.data_entry.common.current_marine_processes")),
            DTOutput(ns("mpf_table"))
          )
        ),

        actionButton(ns("save_ex2b"), i18n$t("modules.isa.data_entry.ex2b.save_exercise_2b"), class = "btn-primary"),
        hr()
      )
    })

    # Render Exercise 3 content ----
    output$exercise_3_content <- renderUI({
      tagList(
        div(style = "display: flex; justify-content: space-between; align-items: center;",
          h4(i18n$t("modules.isa.data_entry.ex3.specifying_pressures_on_state_changes")),
          actionButton(ns("help_ex3"), i18n$t("ui.header.help"), icon = icon("question-circle"), class = "btn-info btn-sm")
        ),
        wellPanel(
          p(strong(i18n$t("common.labels.purpose")), " ", i18n$t("modules.isa.identify_pressures_that_affect_marine_processes_an")),
          p(i18n$t("modules.isa.complete_columns_ac_am_in_the_master_dat_sheet_lin"))
        ),

        fluidRow(
          column(12,
            h5(i18n$t("modules.isa.data_entry.common.add_pressures")),
            actionButton(ns("add_p"), i18n$t("modules.isa.data_entry.common.add_pressure"), icon = icon("plus"), class = "btn-success"),
            hr(),
            uiOutput(ns("p_entries"))
          )
        ),

        fluidRow(
          column(12,
            h5(i18n$t("modules.isa.data_entry.common.current_pressures")),
            DTOutput(ns("p_table"))
          )
        ),

        actionButton(ns("save_ex3"), i18n$t("modules.isa.data_entry.ex3.save_exercise_3"), class = "btn-primary"),
        hr()
      )
    })

    # Render Exercise 4 content ----
    output$exercise_4_content <- renderUI({
      tagList(
        div(style = "display: flex; justify-content: space-between; align-items: center;",
          h4(i18n$t("modules.isa.data_entry.common.specifying_activities_affecting_pressures")),
          actionButton(ns("help_ex4"), i18n$t("ui.header.help"), icon = icon("question-circle"), class = "btn-info btn-sm")
        ),
        wellPanel(
          p(strong(i18n$t("common.labels.purpose")), " ", i18n$t("modules.isa.identify_human_activities_that_generate_pressures_")),
          p(i18n$t("modules.isa.complete_columns_ao_ay_in_the_master_dat_sheet_lin"))
        ),

        fluidRow(
          column(12,
            h5(i18n$t("modules.isa.data_entry.common.add_activities")),
            actionButton(ns("add_a"), i18n$t("modules.isa.data_entry.common.add_activity"), icon = icon("plus"), class = "btn-success"),
            hr(),
            uiOutput(ns("a_entries"))
          )
        ),

        fluidRow(
          column(12,
            h5(i18n$t("modules.isa.data_entry.common.current_activities")),
            DTOutput(ns("a_table"))
          )
        ),

        actionButton(ns("save_ex4"), i18n$t("modules.isa.data_entry.ex4.save_exercise_4"), class = "btn-primary"),
        hr()
      )
    })

    # Render Exercise 5 content ----
    output$exercise_5_content <- renderUI({
      tagList(
        div(style = "display: flex; justify-content: space-between; align-items: center;",
          h4(i18n$t("modules.isa.data_entry.ex1.drivers_giving_rise_to_activities")),
          actionButton(ns("help_ex5"), i18n$t("ui.header.help"), icon = icon("question-circle"), class = "btn-info btn-sm")
        ),
        wellPanel(
          p(strong(i18n$t("common.labels.purpose")), " ", i18n$t("modules.isa.identify_the_underlying_drivers_that_motivate_huma")),
          p(i18n$t("modules.isa.complete_columns_bc_bk_in_the_master_dat_sheet_lin"))
        ),

        fluidRow(
          column(12,
            h5(i18n$t("modules.isa.data_entry.ex1.add_drivers")),
            actionButton(ns("add_d"), i18n$t("modules.isa.data_entry.ex1.add_driver"), icon = icon("plus"), class = "btn-success"),
            hr(),
            uiOutput(ns("d_entries"))
          )
        ),

        fluidRow(
          column(12,
            h5(i18n$t("modules.isa.data_entry.ex1.current_drivers")),
            DTOutput(ns("d_table"))
          )
        ),

        actionButton(ns("save_ex5"), i18n$t("modules.isa.data_entry.ex5.save_exercise_5"), class = "btn-primary"),
        hr()
      )
    })

    # Render Exercise 6 content ----
    output$exercise_6_content <- renderUI({
      tagList(
        div(style = "display: flex; justify-content: space-between; align-items: center;",
          h4(i18n$t("modules.isa.data_entry.ex1.closing_the_loop_drivers_to_goods_benefits")),
          actionButton(ns("help_ex6"), i18n$t("ui.header.help"), icon = icon("question-circle"), class = "btn-info btn-sm")
        ),
        wellPanel(
          p(strong(i18n$t("common.labels.purpose")), " ", i18n$t("modules.isa.complete_the_feedback_loop_by_linking_drivers_back")),
          p(i18n$t("modules.isa.this_creates_the_circular_dapsiwrm_framework_showi"))
        ),

        fluidRow(
          column(12,
            h5(i18n$t("modules.isa.data_entry.ex1.driver_to_goodsbenefits_connections")),
            p(i18n$t("modules.isa.select_drivers_and_the_goodsbenefits_they_influenc")),
            uiOutput(ns("loop_connections"))
          )
        ),

        fluidRow(
          column(12,
            h5(i18n$t("modules.isa.data_entry.common.loop_closure_summary")),
            plotOutput(ns("loop_diagram"), height = PLOT_HEIGHT_MD)
          )
        ),

        actionButton(ns("save_ex6"), i18n$t("modules.isa.data_entry.ex6.save_exercise_6"), class = "btn-primary"),
        hr()
      )
    })

    # Render Responses & Measures content ----
    output$responses_content <- renderUI({
      tagList(
        wellPanel(
          h4(i18n$t("modules.isa.data_entry.responses.tab_title"),
             actionButton(ns("help_responses"), label = NULL, icon = icon("circle-question"),
                          class = "btn-link", style = "padding:0 .4rem;")),
          p(i18n$t("modules.isa.data_entry.responses.purpose"))
        ),
        actionButton(ns("add_response"), i18n$t("modules.isa.data_entry.responses.add"),
                     class = "btn-primary"),
        tags$div(id = ns("r_entries")),
        actionButton(ns("save_responses"), i18n$t("modules.isa.data_entry.responses.save"),
                     class = "btn-success"),
        DT::DTOutput(ns("r_table"))
      )
    })

    output$r_table <- DT::renderDT({
      DT::datatable(isa_data$responses, options = list(pageLength = 10), rownames = FALSE)
    })

    # Render Exercises 7-9 content ----
    output$exercise_789_content <- renderUI({
      tagList(
        div(style = "display: flex; justify-content: space-between; align-items: center;",
          h4(i18n$t("modules.isa.data_entry.common.causal_loop_diagram_creation_and_export")),
          actionButton(ns("help_ex789"), i18n$t("ui.header.help"), icon = icon("question-circle"), class = "btn-info btn-sm")
        ),
        wellPanel(
          p(strong(i18n$t("modules.isa.data_entry.ex789.exercise_7")), " ", i18n$t("modules.isa.data_entry.ex4.creating_impact_based_cld_in_kumu")),
          p(strong(i18n$t("modules.isa.data_entry.ex789.exercise_8")), " ", i18n$t("modules.isa.data_entry.common.moving_from_causal_logic_chains_to_causal_loops")),
          p(strong(i18n$t("modules.isa.data_entry.ex789.exercise_9")), " ", i18n$t("modules.isa.data_entry.common.exporting_cld_for_further_analysis"))
        ),

        fluidRow(
          column(6,
            h5(i18n$t("modules.isa.data_entry.common.adjacency_matrix_review")),
            p(i18n$t("modules.isa.data_entry.ex101112.review_the_connections_between_dapsiwrm_elements")),
            selectInput(ns("adj_matrix_select"), i18n$t("common.labels.select_matrix_type"),
                       choices = c("Goods/Benefits to ES" = "gb_es",
                                 "ES to MPF" = "es_mpf",
                                 "MPF to Pressures" = "mpf_p",
                                 "Pressures to Activities" = "p_a",
                                 "Activities to Drivers" = "a_d",
                                 "Drivers to Goods/Benefits" = "d_gb",
                                 "Goods/Benefits to Responses" = "gb_r",
                                 "Responses to Drivers" = "r_d",
                                 "Responses to Activities" = "r_a",
                                 "Responses to Pressures" = "r_p")),
            DTOutput(ns("adj_matrix_view"))
          ),
          column(6,
            h5(i18n$t("modules.isa.data_entry.common.kumu_export_options")),
            p(i18n$t("modules.isa.prepare_dat_for_import_into_kumu_visualization_sof")),
            checkboxGroupInput(ns("export_options"), i18n$t("modules.isa.data_entry.common.include_in_export"),
                              choices = c("Elements (nodes)" = "elements",
                                        "Connections (edges)" = "connections",
                                        "Element attributes" = "attributes",
                                        "Loop identifiers" = "loops"),
                              selected = c("elements", "connections")),
            br(),
            downloadButton(ns("download_kumu"), i18n$t("modules.isa.data_entry.common.download_kumu_csv_files"), class = "btn-info"),
            br(), br(),
            downloadButton(ns("download_excel"), i18n$t("modules.isa.data_entry.common.download_complete_excel_workbook"), class = "btn-success")
          )
        ),

        actionButton(ns("save_ex789"), i18n$t("modules.isa.data_entry.common.save_exercises_7_9"), class = "btn-primary"),
        hr()
      )
    })

    # Render Exercises 10-12 content ----
    output$exercise_101112_content <- renderUI({
      tagList(
        div(style = "display: flex; justify-content: space-between; align-items: center;",
          h4(i18n$t("modules.isa.data_entry.common.clarifying_metrics_and_validation")),
          actionButton(ns("help_ex101112"), i18n$t("ui.header.help"), icon = icon("question-circle"), class = "btn-info btn-sm")
        ),
        wellPanel(
          p(strong(i18n$t("modules.isa.data_entry.ex1.exercise_10")), " ", i18n$t("modules.isa.data_entry.common.clarifying_endogenisation_and_encapsulation")),
          p(strong(i18n$t("modules.isa.data_entry.ex1.exercise_11")), " ", i18n$t("modules.isa.data_entry.common.metrics_root_causes_and_leverage_points")),
          p(strong(i18n$t("modules.isa.data_entry.ex1.exercise_12")), " ", i18n$t("modules.isa.data_entry.common.presenting_and_validating_results"))
        ),

        # Exercise 10: Clarifying
        h5(i18n$t("modules.isa.data_entry.ex1.exercise_10_clarifying_the_cld")),
        fluidRow(
          column(6,
            textAreaInput(ns("endogenisation_notes"), i18n$t("common.labels.endogenisation_notes"),
                         placeholder = i18n$t("modules.isa.what_external_factors_should_be_brought_inside_the"),
                         rows = 4)
          ),
          column(6,
            textAreaInput(ns("encapsulation_notes"), i18n$t("common.labels.encapsulation_notes"),
                         placeholder = i18n$t("modules.isa.what_detailed_processes_can_be_simplified_or_group"),
                         rows = 4)
          )
        ),

        hr(),

        # Exercise 11: Metrics and Leverage
        h5(i18n$t("modules.isa.data_entry.ex1.exercise_11_metrics_and_leverage_points")),
        fluidRow(
          column(6,
            h6(i18n$t("modules.isa.data_entry.common.root_causes_identified")),
            uiOutput(ns("root_causes_ui"))
          ),
          column(6,
            h6(i18n$t("modules.isa.data_entry.common.leverage_points")),
            uiOutput(ns("leverage_points_ui"))
          )
        ),

        hr(),

        # Exercise 12: Validation
        h5(i18n$t("modules.isa.data_entry.ex1.exercise_12_presenting_and_validating")),
        fluidRow(
          column(12,
            textAreaInput(ns("validation_notes"), i18n$t("common.labels.validation_notes"),
                         placeholder = i18n$t("modules.isa.record_stakeholder_feedback_validation_workshop_re"),
                         rows = 6),
            checkboxGroupInput(ns("validation_status"), i18n$t("modules.isa.data_entry.common.validation_completed"),
                              choices = c("Internal team review" = "internal",
                                        "Stakeholder workshop" = "stakeholder",
                                        "Expert peer review" = "expert",
                                        "Final approval" = "final"))
          )
        ),

        actionButton(ns("save_ex101112"), i18n$t("modules.isa.data_entry.common.save_exercises_10_12"), class = "btn-primary"),
        hr()
      )
    })

    # Render BOT Graphs content ----
    output$bot_graphs_content <- renderUI({
      tagList(
        div(style = "display: flex; justify-content: space-between; align-items: center;",
          h4(i18n$t("modules.isa.data_entry.common.behaviour_over_time_bot_graphs")),
          actionButton(ns("help_bot"), i18n$t("ui.header.help"), icon = icon("question-circle"), class = "btn-info btn-sm")
        ),
        wellPanel(
          p(strong(i18n$t("common.labels.purpose")), " ", i18n$t("modules.isa.visualize_how_indicators_change_over_time_to_under"))
        ),

        fluidRow(
          column(4,
            selectInput(ns("bot_element_type"), i18n$t("common.labels.element_type"),
                       choices = c("Goods & Benefits" = "gb",
                                 "Ecosystem Services" = "es",
                                 "Marine Processes" = "mpf",
                                 "Pressures" = "p",
                                 "Activities" = "a",
                                 "Drivers" = "d")),
            uiOutput(ns("bot_element_select")),
            br(),
            h6(i18n$t("modules.isa.data_entry.common.add_time_series_data")),
            numericInput(ns("bot_year"), i18n$t("modules.isa.data_entry.common.year"), value = 2024, min = 1900, max = 2100),
            numericInput(ns("bot_value"), i18n$t("common.labels.value"), value = 0),
            textInput(ns("bot_unit"), i18n$t("modules.isa.data_entry.common.unit"), placeholder = i18n$t("modules.isa.data_entry.common.eg_tonnes_index")),
            actionButton(ns("add_bot_point"), i18n$t("modules.isa.data_entry.common.add_data_point"), icon = icon("plus"))
          ),
          column(8,
            h5(i18n$t("modules.isa.data_entry.common.time_series_plot")),
            plotOutput(ns("bot_plot"), height = PLOT_HEIGHT_MD),
            br(),
            h6(i18n$t("modules.isa.data_entry.common.current_data")),
            DTOutput(ns("bot_data_table"))
          )
        ),

        actionButton(ns("save_bot"), i18n$t("modules.isa.data_entry.common.save_bot_data"), class = "btn-primary"),
        hr()
      )
    })

    # Render Data Management content ----
    output$data_management_content <- renderUI({
      tagList(
        h4(i18n$t("modules.isa.data_entry.common.importexport_and_data_management")),

        fluidRow(
          column(12,
            wellPanel(
              h5(i18n$t("modules.isa.data_entry.common.documentation")),
              p(i18n$t("modules.isa.comprehensive_guides_for_using_the_isa_dat_entry_m")),
              fluidRow(
                column(4,
                  tags$a(
                    class = "btn btn-info btn-block",
                    href = "ISA_User_Guide_en.md",
                    target = "_blank",
                    icon("book"),
                    " ", i18n$t("modules.isa.data_entry.common.open_user_guide")
                  )
                ),
                column(4,
                  downloadButton(ns("download_guidance_pdf"), i18n$t("modules.isa.data_entry.common.isa_guidance_document_pdf"), class = "btn-info btn-block")
                ),
                column(4,
                  tags$a(
                    class = "btn btn-info btn-block",
                    href = "Kumu_Code_Style.txt",
                    target = "_blank",
                    icon("code"),
                    " ", i18n$t("modules.isa.data_entry.common.kumu_styling_code")
                  )
                )
              )
            )
          )
        ),

        hr(),

        fluidRow(
          column(6,
            wellPanel(
              h5(i18n$t("modules.isa.data_entry.common.import_data")),
              p(i18n$t("modules.isa.data_entry.common.load_existing_isa_data_from_excel_workbook")),
              fileInput(ns("import_file"), i18n$t("modules.isa.data_entry.common.choose_excel_file_xlsx"),
                       accept = c(".xlsx")),
              actionButton(ns("import_data"), i18n$t("modules.isa.data_entry.common.import_data"), class = "btn-warning")
            )
          ),
          column(6,
            wellPanel(
              h5(i18n$t("modules.isa.data_entry.common.export_data")),
              p(i18n$t("modules.isa.data_entry.common.save_current_isa_analysis_to_excel_workbook")),
              textInput(ns("export_filename"), i18n$t("modules.isa.data_entry.common.filename"), value = "ISA_Export"),
              downloadButton(ns("export_data"), i18n$t("modules.isa.data_entry.common.export_to_excel"), class = "btn-success")
            )
          )
        ),

        hr(),

        fluidRow(
          column(12,
            wellPanel(
              h5(i18n$t("modules.isa.data_entry.common.reset_data")),
              p(strong(i18n$t("common.messages.warning")), " ", i18n$t("modules.isa.this_will_clear_all_entered_dat_this_action_cannot")),
              actionButton(ns("reset_confirm"), i18n$t("modules.isa.data_entry.common.reset_all_data"), class = "btn-danger")
            )
          )
        )
      )
    })

    # Exercise 0: Save case information ----
    observeEvent(input$save_ex0, {
      # Validate all Exercise 0 inputs
      validations <- list(
        validate_text_input(input$case_name, "Case Study Name",
                           required = TRUE, min_length = 3, max_length = 200,
                           session = session),
        validate_text_input(input$case_description, "Case Description",
                           required = TRUE, min_length = 10, max_length = 1000,
                           session = session),
        validate_text_input(input$geographic_scope, "Geographic Scope",
                           required = TRUE, min_length = 3,
                           session = session),
        validate_text_input(input$temporal_scope, "Temporal Scope",
                           required = TRUE, min_length = 3,
                           session = session),
        validate_text_input(input$welfare_impacts, "Welfare Impacts",
                           required = FALSE, max_length = 2000,
                           session = session),
        validate_text_input(input$key_stakeholders, "Key Stakeholders",
                           required = FALSE, max_length = 1000,
                           session = session)
      )

      # Check all validations
      if (!validate_all(validations, session)) {
        return()  # Stop if validation fails
      }

      # All valid - save data with cleaned values
      isa_data$case_info <- list(
        name = validations[[1]]$value,
        description = validations[[2]]$value,
        geographic_scope = validations[[3]]$value,
        temporal_scope = validations[[4]]$value,
        welfare_impacts = if (!is.null(validations[[5]]$value)) validations[[5]]$value else "",
        key_stakeholders = if (!is.null(validations[[6]]$value)) validations[[6]]$value else ""
      )
      sync_to_project_data()

      showNotification(i18n$t("modules.isa.data_entry.ex0.exercise_0_saved_successfully"), type = "message")
      debug_log("Exercise 0 case information saved", "INFO")
    })

    # Exercise 1: Goods & Benefits ----
    observeEvent(input$add_gb, {
      current_id <- generate_stable_element_id(ELEMENT_ID_PREFIX$welfare, id_store)
      isa_data$gb_panel_ids <- c(isa_data$gb_panel_ids, current_id)
      isa_data$gb_counter <- isa_data$gb_counter + 1

      insertUI(
        selector = paste0("#", ns("gb_entries")),
        where = "beforeEnd",
        ui = build_entry_panel_ui(ns, "gb", current_id, isa_fields_gb(i18n), i18n)
      )

      register_remove_observer(input, ns, "gb", current_id, i18n,
                              isa_data = isa_data, data_key = "goods_benefits",
                              id_prefix = ELEMENT_ID_PREFIX$welfare,
                              on_remove = sync_to_project_data)
    })

    output$gb_table <- renderDT({
      datatable(isa_data$goods_benefits, options = list(pageLength = 10), rownames = FALSE)
    })

    observeEvent(input$save_ex1, {
      if (length(isa_data$gb_panel_ids) == 0) {
        showNotification(i18n$t("modules.isa.please_add_at_least_one_goodbenefit_entry_before_s"),
                        type = "warning", session = session)
        return()
      }

      result <- validate_and_collect_gb(input, isa_data$gb_panel_ids, session, i18n)

      if (length(result$errors) > 0) {
        show_validation_error_modal(result$errors, i18n)
        return()
      }

      if (result$n_rows == 0) {
        showNotification(i18n$t("modules.isa.data_entry.ex789.please_add_at_least_one_valid_goodbenefit_entry"),
                        type = "warning", session = session)
        return()
      }

      isa_data$goods_benefits <- result$df
      sync_to_project_data()
      showNotification(paste(i18n$t("modules.isa.data_entry.ex1.exercise_1_saved"), nrow(result$df), i18n$t("modules.isa.data_entry.ex789.goods_benefits")),
                      type = "message", session = session)
      debug_log(paste("Exercise 1 saved with", nrow(result$df), "entries"), "INFO")
    })

    # Exercise 2a: Ecosystem Services ----
    observeEvent(input$add_es, {
      current_id <- generate_stable_element_id(ELEMENT_ID_PREFIX$impacts, id_store)
      isa_data$es_panel_ids <- c(isa_data$es_panel_ids, current_id)
      isa_data$es_counter <- isa_data$es_counter + 1

      linked_choices <- c("", paste0(isa_data$goods_benefits$ID, ": ", isa_data$goods_benefits$Name))
      insertUI(
        selector = paste0("#", ns("es_entries")),
        where = "beforeEnd",
        ui = build_entry_panel_ui(ns, "es", current_id, isa_fields_es(i18n, linked_choices), i18n)
      )

      register_remove_observer(input, ns, "es", current_id, i18n,
                              isa_data = isa_data, data_key = "ecosystem_services",
                              id_prefix = ELEMENT_ID_PREFIX$impacts,
                              on_remove = sync_to_project_data)
    })

    output$es_table <- renderDT({
      datatable(isa_data$ecosystem_services, options = list(pageLength = 10), rownames = FALSE)
    })

    observeEvent(input$save_ex2a, {
      if (length(isa_data$es_panel_ids) == 0) {
        showNotification(i18n$t("modules.isa.please_add_at_least_one_ecosystem_service_entry_be"),
                        type = "warning", session = session)
        return()
      }

      result <- validate_and_collect_es(input, isa_data$es_panel_ids, session, i18n)

      if (length(result$errors) > 0) {
        show_validation_error_modal(result$errors, i18n)
        return()
      }

      if (result$n_rows == 0) {
        showNotification(i18n$t("modules.isa.please_add_at_least_one_valid_ecosystem_service_en"),
                        type = "warning", session = session)
        return()
      }

      isa_data$ecosystem_services <- result$df
      rebuild_transition(isa_data$ecosystem_services, "LinkedGB",
                         isa_data$goods_benefits$ID, "es_gb")
      sync_to_project_data()
      showNotification(paste(i18n$t("modules.isa.data_entry.ex2a.exercise_2a_saved"), nrow(result$df), i18n$t("modules.ses.creation.ecosystem_services")),
                      type = "message", session = session)
      debug_log(paste("Exercise 2a saved with", nrow(result$df), "entries"), "INFO")
    })

    # Exercise 2b: Marine Processes and Functioning ----
    observeEvent(input$add_mpf, {
      current_id <- generate_stable_element_id(ELEMENT_ID_PREFIX$states, id_store)
      isa_data$mpf_panel_ids <- c(isa_data$mpf_panel_ids, current_id)
      isa_data$mpf_counter <- isa_data$mpf_counter + 1

      linked_choices <- c("", paste0(isa_data$ecosystem_services$ID, ": ", isa_data$ecosystem_services$Name))
      insertUI(
        selector = paste0("#", ns("mpf_entries")),
        where = "beforeEnd",
        ui = build_entry_panel_ui(ns, "mpf", current_id, isa_fields_mpf(i18n, linked_choices), i18n)
      )

      register_remove_observer(input, ns, "mpf", current_id, i18n,
                              isa_data = isa_data, data_key = "marine_processes",
                              id_prefix = ELEMENT_ID_PREFIX$states,
                              on_remove = sync_to_project_data)
    })

    output$mpf_table <- renderDT({
      datatable(isa_data$marine_processes, options = list(pageLength = 10), rownames = FALSE)
    })

    observeEvent(input$save_ex2b, {
      mpf_df <- collect_element_entries(
        input, "mpf", isa_data$mpf_panel_ids, ELEMENT_ID_PREFIX$states,
        field_ids = c("name", "type", "desc", "linkedes", "mechanism", "spatial"),
        col_names = c("Name", "Type", "Description", "LinkedES", "Mechanism", "Spatial")
      )
      isa_data$marine_processes <- mpf_df
      rebuild_transition(isa_data$marine_processes, "LinkedES",
                         isa_data$ecosystem_services$ID, "mpf_es")
      sync_to_project_data()
      showNotification(paste(i18n$t("modules.isa.data_entry.ex2b.exercise_2b_saved"), nrow(mpf_df), i18n$t("modules.isa.data_entry.common.marine_processes")), type = "message")
    })

    # Exercise 3: Pressures ----
    observeEvent(input$add_p, {
      current_id <- generate_stable_element_id(ELEMENT_ID_PREFIX$pressures, id_store)
      isa_data$p_panel_ids <- c(isa_data$p_panel_ids, current_id)
      isa_data$p_counter <- isa_data$p_counter + 1

      linked_choices <- c("", paste0(isa_data$marine_processes$ID, ": ", isa_data$marine_processes$Name))
      insertUI(
        selector = paste0("#", ns("p_entries")),
        where = "beforeEnd",
        ui = build_entry_panel_ui(ns, "p", current_id, isa_fields_p(i18n, linked_choices), i18n)
      )

      register_remove_observer(input, ns, "p", current_id, i18n,
                              isa_data = isa_data, data_key = "pressures",
                              id_prefix = ELEMENT_ID_PREFIX$pressures,
                              on_remove = sync_to_project_data)
    })

    output$p_table <- renderDT({
      datatable(isa_data$pressures, options = list(pageLength = 10), rownames = FALSE)
    })

    observeEvent(input$save_ex3, {
      p_df <- collect_element_entries(
        input, "p", isa_data$p_panel_ids, ELEMENT_ID_PREFIX$pressures,
        field_ids = c("name", "type", "desc", "linkedmpf", "intensity", "spatial", "temporal"),
        col_names = c("Name", "Type", "Description", "LinkedMPF", "Intensity", "Spatial", "Temporal")
      )
      isa_data$pressures <- p_df
      rebuild_transition(isa_data$pressures, "LinkedMPF",
                         isa_data$marine_processes$ID, "p_mpf")
      sync_to_project_data()
      showNotification(paste(i18n$t("modules.isa.data_entry.ex3.exercise_3_saved"), nrow(p_df), i18n$t("modules.response.measures.pressures")), type = "message")
    })

    # Exercise 4: Activities ----
    observeEvent(input$add_a, {
      current_id <- generate_stable_element_id(ELEMENT_ID_PREFIX$activities, id_store)
      isa_data$a_panel_ids <- c(isa_data$a_panel_ids, current_id)
      isa_data$a_counter <- isa_data$a_counter + 1

      linked_choices <- c("", paste0(isa_data$pressures$ID, ": ", isa_data$pressures$Name))
      insertUI(
        selector = paste0("#", ns("a_entries")),
        where = "beforeEnd",
        ui = build_entry_panel_ui(ns, "a", current_id, isa_fields_a(i18n, linked_choices), i18n)
      )

      register_remove_observer(input, ns, "a", current_id, i18n,
                              isa_data = isa_data, data_key = "activities",
                              id_prefix = ELEMENT_ID_PREFIX$activities,
                              on_remove = sync_to_project_data)
    })

    output$a_table <- renderDT({
      datatable(isa_data$activities, options = list(pageLength = 10), rownames = FALSE)
    })

    observeEvent(input$save_ex4, {
      a_df <- collect_element_entries(
        input, "a", isa_data$a_panel_ids, ELEMENT_ID_PREFIX$activities,
        field_ids = c("name", "sector", "desc", "linkedp", "scale", "frequency"),
        col_names = c("Name", "Sector", "Description", "LinkedP", "Scale", "Frequency")
      )
      isa_data$activities <- a_df
      rebuild_transition(isa_data$activities, "LinkedP",
                         isa_data$pressures$ID, "a_p")
      sync_to_project_data()
      showNotification(paste(i18n$t("modules.isa.data_entry.ex4.exercise_4_saved"), nrow(a_df), i18n$t("modules.response.measures.activities")), type = "message")
    })

    # Exercise 5: Drivers ----
    observeEvent(input$add_d, {
      current_id <- generate_stable_element_id(ELEMENT_ID_PREFIX$drivers, id_store)
      isa_data$d_panel_ids <- c(isa_data$d_panel_ids, current_id)
      isa_data$d_counter <- isa_data$d_counter + 1

      linked_choices <- c("", paste0(isa_data$activities$ID, ": ", isa_data$activities$Name))
      insertUI(
        selector = paste0("#", ns("d_entries")),
        where = "beforeEnd",
        ui = build_entry_panel_ui(ns, "d", current_id, isa_fields_d(i18n, linked_choices), i18n)
      )

      register_remove_observer(input, ns, "d", current_id, i18n,
                              isa_data = isa_data, data_key = "drivers",
                              id_prefix = ELEMENT_ID_PREFIX$drivers,
                              on_remove = sync_to_project_data)
    })

    output$d_table <- renderDT({
      datatable(isa_data$drivers, options = list(pageLength = 10), rownames = FALSE)
    })

    observeEvent(input$save_ex5, {
      d_df <- collect_element_entries(
        input, "d", isa_data$d_panel_ids, ELEMENT_ID_PREFIX$drivers,
        field_ids = c("name", "type", "desc", "linkeda", "trend", "control"),
        col_names = c("Name", "Type", "Description", "LinkedA", "Trend", "Controllability")
      )
      isa_data$drivers <- d_df
      rebuild_transition(isa_data$drivers, "LinkedA",
                         isa_data$activities$ID, "d_a")
      sync_to_project_data()
      showNotification(paste(i18n$t("modules.isa.data_entry.ex5.exercise_5_saved"), nrow(d_df), i18n$t("modules.response.measures.drivers")), type = "message")
    })

    # Exercise 6: Loop connections UI ----
    output$loop_connections <- renderUI({
      req(isa_data$drivers, isa_data$goods_benefits)

      if (nrow(isa_data$drivers) == 0 || nrow(isa_data$goods_benefits) == 0) {
        return(p(i18n$t("modules.isa.please_complete_exercises_1_and_5_first_to_create_")))
      }

      driver_choices <- setNames(isa_data$drivers$ID,
                                 paste0(isa_data$drivers$ID, ": ", isa_data$drivers$Name))
      gb_choices <- setNames(isa_data$goods_benefits$ID,
                            paste0(isa_data$goods_benefits$ID, ": ", isa_data$goods_benefits$Name))

      tagList(
        fluidRow(
          column(3,
            selectInput(ns("loop_driver"), i18n$t("modules.isa.data_entry.ex1.driver"), choices = driver_choices)
          ),
          column(1,
            div(style = "text-align: center; padding-top: 25px;", "→")
          ),
          column(3,
            selectInput(ns("loop_gb"), i18n$t("modules.isa.data_entry.ex789.goodsbenefit"), choices = gb_choices)
          ),
          column(2,
            selectInput(ns("loop_effect"), i18n$t("modules.isa.data_entry.common.effect"),
                       choices = c("Positive" = "+", "Negative" = "-"))
          ),
          column(2,
            selectInput(ns("loop_strength"), i18n$t("modules.isa.data_entry.common.strength"),
                       choices = c("Weak" = "weak", "Medium" = "medium", "Strong" = "strong"))
          ),
          column(1,
            br(),
            actionButton(ns("add_loop"), i18n$t("common.buttons.add"), icon = icon("plus"), class = "btn-success btn-sm")
          )
        ),
        fluidRow(
          column(12,
            sliderInput(ns("loop_confidence"), i18n$t("modules.isa.data_entry.common.confidence_level"),
                       min = 1, max = 5, value = 3, step = 1,
                       ticks = TRUE,
                       post = c(" - Very Low", " - Low", " - Medium", " - High", " - Very High")[3])
          )
        ),
        hr(),
        fluidRow(
          column(12,
            h5(i18n$t("modules.isa.data_entry.ex101112.current_loop_connections")),
            DTOutput(ns("loop_connections_table"))
          )
        )
      )
    })

    # Exercise 6: Loop closure visualization ----
    output$loop_diagram <- renderPlot({
      # Placeholder for loop closure diagram
      plot(1:10, 1:10, main = i18n$t("modules.isa_data_entry.loop_diagram_title"),
           xlab = i18n$t("modules.isa_data_entry.loop_diagram_xlab"),
           ylab = i18n$t("modules.isa_data_entry.loop_diagram_ylab"),
           type = "n")
      text(5, 5, i18n$t("modules.isa_data_entry.loop_diagram_placeholder"), cex = 1.5)
    })

    # Add loop connection ----
    observeEvent(input$add_loop, {
      req(input$loop_driver, input$loop_gb, input$loop_effect, input$loop_strength, input$loop_confidence)

      new_connection <- data.frame(
        DriverID = input$loop_driver,
        GBID = input$loop_gb,
        Effect = input$loop_effect,
        Strength = input$loop_strength,
        Confidence = input$loop_confidence,
        Mechanism = ""
        
      )

      isa_data$loop_connections <- rbind(isa_data$loop_connections, new_connection)
      sync_to_project_data()
      showNotification(i18n$t("modules.isa.data_entry.ex101112.loop_connection_added"), type = "message")
    })

    # Display loop connections table ----
    output$loop_connections_table <- renderDT({
      if (nrow(isa_data$loop_connections) == 0) {
        return(data.frame(Message = "No loop connections yet"))
      }

      isa_data$loop_connections %>%
        mutate(
          Connection = paste0(DriverID, " → ", GBID),
          Polarity = ifelse(Effect == "+", "Positive", "Negative"),
          ConfidenceLabel = c("Very Low", "Low", "Medium", "High", "Very High")[Confidence]
        ) %>%
        select(Connection, Polarity, Strength, ConfidenceLabel) %>%
        rename(`Confidence` = ConfidenceLabel)
    }, options = list(pageLength = 5, dom = 't'), rownames = FALSE)

    # Save Exercise 6 ----
    observeEvent(input$save_ex6, {
      # loop_connections already in isa_data (no need to copy from rv)

      # Convert loop_connections to gb_d adjacency matrix (NEW: forward causal flow)
      # GB→D represents how welfare perceptions feed back to drive societal drivers
      if (nrow(isa_data$loop_connections) > 0) {
        n_drivers <- nrow(isa_data$drivers)
        n_gb <- nrow(isa_data$goods_benefits)

        # Initialize empty matrix (SOURCE×TARGET: rows=GB, cols=Drivers)
        gb_d_matrix <- matrix("", nrow = n_gb, ncol = n_drivers)
        rownames(gb_d_matrix) <- isa_data$goods_benefits$ID
        colnames(gb_d_matrix) <- isa_data$drivers$ID

        # Fill matrix with connections
        for (i in seq_len(nrow(isa_data$loop_connections))) {
          conn <- isa_data$loop_connections[i, ]
          gb_idx <- which(isa_data$goods_benefits$ID == conn$GBID)
          d_idx <- which(isa_data$drivers$ID == conn$DriverID)

          if (length(gb_idx) > 0 && length(d_idx) > 0) {
            # Format: "effect+strength:confidence"
            value <- paste0(conn$Effect, conn$Strength, ":", conn$Confidence)
            gb_d_matrix[gb_idx, d_idx] <- value
          }
        }

        # Store in adjacency_matrices
        if (is.null(isa_data$adjacency_matrices)) {
          isa_data$adjacency_matrices <- list()
        }
        isa_data$adjacency_matrices$gb_d <- gb_d_matrix
      }
      sync_to_project_data()

      showNotification(paste(i18n$t("modules.isa.data_entry.ex6.exercise_6_saved"), nrow(isa_data$loop_connections), i18n$t("modules.isa.data_entry.ex101112.loop_connections")),
                      type = "message")
    })

    # BOT Graphs ----
    output$bot_element_select <- renderUI({
      element_type <- input$bot_element_type
      choices <- switch(element_type,
        "gb" = paste0(isa_data$goods_benefits$ID, ": ", isa_data$goods_benefits$Name),
        "es" = paste0(isa_data$ecosystem_services$ID, ": ", isa_data$ecosystem_services$Name),
        "mpf" = paste0(isa_data$marine_processes$ID, ": ", isa_data$marine_processes$Name),
        "p" = paste0(isa_data$pressures$ID, ": ", isa_data$pressures$Name),
        "a" = paste0(isa_data$activities$ID, ": ", isa_data$activities$Name),
        "d" = paste0(isa_data$drivers$ID, ": ", isa_data$drivers$Name),
        character(0)
      )
      selectInput(ns("bot_element"), i18n$t("modules.isa.data_entry.common.select_element"), choices = choices)
    })

    # Exercise 11: Root Causes UI ----
    output$root_causes_ui <- renderUI({
      p(i18n$t("modules.isa.root_causes_anlys_will_be_displayed_here_based_on_"))
    })

    # Exercise 11: Leverage Points UI ----
    output$leverage_points_ui <- renderUI({
      p(i18n$t("modules.isa.leverage_points_anlys_will_be_displayed_here_based"))
    })

    output$bot_plot <- renderPlot({
      if(nrow(isa_data$bot_data) == 0) {
        plot(1, 1, type = "n", main = "No BOT data available", xlab = "Year", ylab = "Value")
        return()
      }
      # Plot BOT data
      plot(1, 1, type = "n", main = "Behaviour Over Time", xlab = "Year", ylab = "Value")
      text(1, 1, "BOT plot will show time series\nof selected element", cex = 1.2)
    })

    output$bot_data_table <- renderDT({
      datatable(isa_data$bot_data, options = list(pageLength = 5), rownames = FALSE)
    })

    # Adjacency matrix viewer (read-only) ----
    output$adj_matrix_view <- renderDT({
      key <- input$adj_matrix_select
      mat <- isa_data$adjacency_matrices[[key]]
      if (is.null(mat)) {
        DT::datatable(data.frame(Message = "No data available for this matrix."),
                      options = list(dom = "t"), rownames = FALSE)
      } else {
        df <- as.data.frame(mat, stringsAsFactors = FALSE)
        DT::datatable(df, options = list(pageLength = 15, scrollX = TRUE), rownames = TRUE)
      }
    })

    # Data export handlers ----
    output$export_data <- downloadHandler(
      filename = function() {
        name <- if (!is.null(input$export_filename) && nchar(input$export_filename) > 0) {
          sanitize_filename(input$export_filename)
        } else {
          "ISA_Export"
        }
        paste0(name, ".xlsx")
      },
      content = function(file) {
        wb <- createWorkbook()
        write_isa_element_sheets(wb, isa_data, include_adjacency = TRUE)
        saveWorkbook(wb, file, overwrite = TRUE)
      }
    )

    output$download_excel <- downloadHandler(
      filename = function() {
        generate_export_filename("ISA_Analysis", ".xlsx")
      },
      content = function(file) {
        wb <- create_isa_analysis_workbook(isa_data)
        saveWorkbook(wb, file, overwrite = TRUE)
      }
    )

    output$download_kumu <- downloadHandler(
      filename = function() {
        generate_export_filename("Kumu_Export", ".zip")
      },
      content = function(file) {
        create_kumu_export_zip(isa_data, file)
      }
    )

   

    # ---- Excel import (Standard Entry round-trip) ----
    # Helper: does the module currently hold any elements?
    .isa_has_elements <- function() {
      any(vapply(list(isa_data$gb_panel_ids, isa_data$es_panel_ids, isa_data$mpf_panel_ids,
                      isa_data$p_panel_ids, isa_data$a_panel_ids, isa_data$d_panel_ids,
                      isa_data$r_panel_ids),
                 function(x) length(x) > 0 && any(nzchar(x)), logical(1)))
    }

    # Clear all editable ISA state so an IMPORT is a true replace — prevents a
    # fallback-style import (no Matrix_* sheets) from inheriting the previously
    # loaded project's matrices/elements (stale edges / orphan IDs).
    .reset_isa_state <- function() {
      for (k in c("goods_benefits","ecosystem_services","marine_processes",
                  "pressures","activities","drivers","responses")) {
        if (is.data.frame(isa_data[[k]])) isa_data[[k]] <- isa_data[[k]][0, , drop = FALSE]
      }
      for (p in c("gb_panel_ids","es_panel_ids","mpf_panel_ids",
                  "p_panel_ids","a_panel_ids","d_panel_ids","r_panel_ids")) {
        isa_data[[p]] <- character(0)
      }
      isa_data$adjacency_matrices   <- list()
      isa_data$user_edited_matrices <- list()
      if (is.data.frame(isa_data$loop_connections)) {
        isa_data$loop_connections <- isa_data$loop_connections[0, , drop = FALSE]
      }
    }

    # Core import: read file -> apply -> guard -> notify/navigate.
    do_import <- function(path) {
      saved <- tryCatch(
        read_standard_entry_workbook(path),
        se_import_not_recognized = function(e) {
          showNotification(i18n$t("modules.isa.data_entry.common.import_not_recognized"),
                           type = "error", duration = 8, session = session)
          NULL
        },
        error = function(e) {
          showNotification(format_user_error(e, i18n = i18n,
                           context_key = "common.messages.context_reading_excel_file"),
                           type = "error", session = session)
          NULL
        })
      if (is.null(saved)) return(invisible(NULL))

      .reset_isa_state()
      res <- apply_saved_isa(saved)

      n_elems <- sum(vapply(c("goods_benefits","ecosystem_services","marine_processes",
                              "pressures","activities","drivers"),
                            function(k) if (is.data.frame(isa_data[[k]])) nrow(isa_data[[k]]) else 0L,
                            integer(1)))
      n_edges <- sum(vapply(isa_data$adjacency_matrices,
                            function(m) if (is.matrix(m)) sum(nzchar(m) & !is.na(m)) else 0L,
                            integer(1)))

      if (n_elems == 0L) {
        showNotification(i18n$t("modules.isa.data_entry.common.import_not_recognized"),
                         type = "error", duration = 8, session = session)
        return(invisible(NULL))
      }

      data_initialized(TRUE)

      if (isTRUE(res$fell_back)) {
        showNotification(i18n$t("modules.isa.data_entry.common.import_links_defaulted"),
                         type = "warning", duration = 10, session = session)
      }

      if (n_edges == 0L) {
        showNotification(i18n$t("modules.isa.data_entry.common.import_no_connections"),
                         type = "warning", duration = 10, session = session)
        return(invisible(NULL))  # do not auto-navigate to an edgeless diagram
      }

      showNotification(i18n$t("modules.isa.data_entry.common.import_success"),
                       type = "message", duration = 6, session = session)
      if (!is.null(parent_session)) {
        updateTabItems(parent_session, "sidebar_menu", "cld_viz")
      }
      invisible(NULL)
    }

    observeEvent(input$import_data, {
      req(input$import_file)
      path <- input$import_file$datapath
      if (.isa_has_elements()) {
        showModal(modalDialog(
          title = i18n$t("modules.isa.data_entry.common.import_replace_title"),
          i18n$t("modules.isa.data_entry.common.import_replace_warning"),
          footer = tagList(
            modalButton(i18n$t("common.buttons.cancel")),
            actionButton(ns("import_confirm"), i18n$t("modules.isa.data_entry.common.import_data"),
                         class = "btn-warning")
          ),
          easyClose = TRUE
        ))
      } else {
        do_import(path)
      }
    }, ignoreInit = TRUE)

    observeEvent(input$import_confirm, {
      removeModal()
      req(input$import_file)
      do_import(input$import_file$datapath)
    })

    # Download PDF guidance document
    output$download_guidance_pdf <- downloadHandler(
      filename = function() {
        "MarineSABRES_Simple_SES_DRAFT_Guidance.pdf"
      },
      content = function(file) {
        file.copy("Documents/MarineSABRES_Simple_SES_DRAFT_Guidance.pdf", file)
      }
    )

    # Help Modals ----
    create_help_observer(
      input, "help_main", "isa_framework_guide_title",
      tagList(
        h4(i18n$t("modules.isa.data_entry.common.isa_guide_what_is_isa_title")),
        p(i18n$t("modules.isa.data_entry.common.isa_guide_what_is_isa_p1")),
        p(i18n$t("modules.isa.data_entry.common.isa_guide_what_is_isa_p2")),
        hr(),
        h4(i18n$t("modules.isa.data_entry.common.isa_guide_dapsiwr_title")),
        p(i18n$t("modules.isa.data_entry.common.isa_guide_dapsiwr_p1")),
        tags$ul(
          tags$li(strong(i18n$t("modules.isa.data_entry.ex1.drivers_label")), i18n$t("modules.isa.data_entry.ex1.isa_guide_dapsiwr_drivers")),
          tags$li(strong(i18n$t("modules.isa.data_entry.common.activities_label")), i18n$t("modules.isa.data_entry.common.isa_guide_dapsiwr_activities")),
          tags$li(strong(i18n$t("modules.isa.data_entry.common.pressures_label")), i18n$t("modules.isa.data_entry.common.isa_guide_dapsiwr_pressures")),
          tags$li(strong(i18n$t("modules.isa.data_entry.ex3.state_label")), i18n$t("modules.isa.data_entry.ex3.isa_guide_dapsiwr_state")),
          tags$li(strong(i18n$t("modules.isa.data_entry.ex4.impacts_label")), i18n$t("modules.isa.data_entry.ex4.isa_guide_dapsiwr_impacts")),
          tags$li(strong(i18n$t("modules.isa.data_entry.ex6.responses_label")), i18n$t("modules.isa.data_entry.ex6.isa_guide_dapsiwr_responses"))
        ),
        hr(),
        h4(i18n$t("modules.isa.data_entry.common.isa_guide_how_to_use_title")),
        p(i18n$t("modules.isa.data_entry.common.isa_guide_how_to_use_p1"))
      ),
      i18n
    )

    create_help_observer(input, "help_ex0", "ex0_help_title", p(i18n$t("modules.isa.data_entry.common.ex0_help_text")), i18n)
    create_help_observer(input, "help_ex1", "ex1_help_title", p(i18n$t("modules.isa.data_entry.common.ex1_help_text")), i18n)
    create_help_observer(input, "help_ex2a", "ex2a_help_title", p(i18n$t("modules.isa.data_entry.common.ex2a_help_text")), i18n)
    create_help_observer(input, "help_ex2b", "ex2b_help_title", p(i18n$t("modules.isa.data_entry.common.ex2b_help_text")), i18n)
    create_help_observer(input, "help_ex3", "ex3_help_title", p(i18n$t("modules.isa.data_entry.common.ex3_help_text")), i18n)
    create_help_observer(input, "help_ex4", "ex4_help_title", p(i18n$t("modules.isa.data_entry.common.ex4_help_text")), i18n)
    create_help_observer(input, "help_ex5", "ex5_help_title", p(i18n$t("modules.isa.data_entry.common.ex5_help_text")), i18n)
    create_help_observer(input, "help_ex6", "ex6_help_title", p(i18n$t("modules.isa.data_entry.common.ex6_help_text")), i18n)

    observeEvent(input$help_responses, {
      showModal(modalDialog(
        title = i18n$t("modules.isa.data_entry.responses.help_title"),
        i18n$t("modules.isa.data_entry.responses.help_body"),
        easyClose = TRUE
      ))
    })

    create_help_observer(input, "help_ex789", "ex789_help_title", p(i18n$t("modules.isa.data_entry.common.ex789_help_text")), i18n)
    create_help_observer(input, "help_ex101112", "ex101112_help_title", p(i18n$t("modules.isa.data_entry.common.ex101112_help_text")), i18n)
    create_help_observer(input, "help_bot", "bot_help_title", p(i18n$t("modules.isa.data_entry.common.bot_help_text")), i18n)

    # Return reactive data for use by other modules
    return(reactive({ isa_data }))
  })
}
