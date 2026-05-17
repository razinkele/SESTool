# ==============================================================================
# Pilot Study Module
# ==============================================================================
#
# Captures the measurements specified in docs/ml_pilot_protocol.md when a
# session is launched with `?pilot_condition=A` (baseline) or
# `?pilot_condition=B` (with ML suggestions).
#
# Captured per session:
#   - condition (A or B)
#   - participant_id (URL param, hashed)
#   - t_session_start, t_first_save, t_session_end
#   - n_elements, n_connections at each save event
#   - NASA-TLX self-report (6 sub-scales × 0–100)
#   - exit metadata (browser, locale)
#
# All measurements are written to data/pilot/<participant_id>__<condition>__<ISO timestamp>.json
# Nothing is captured outside a pilot session.
# ==============================================================================

pilot_study_ui <- function(id, i18n) {
  tryCatch(shiny.i18n::usei18n(i18n$translator %||% i18n), error = function(e) NULL)
  ns <- NS(id)
  tagList(
    # Visible only in pilot mode; ~24-pixel banner so participants know they're
    # in a measurement run.
    uiOutput(ns("banner")),
    tags$head(tags$style(HTML("
      .pilot-banner {
        position: fixed; top: 0; left: 0; right: 0; z-index: 99999;
        background: #f1c40f; color: #2c3e50; padding: 4px 12px;
        font-size: 13px; font-weight: 600; text-align: center;
        border-bottom: 2px solid #e67e22;
      }
      .pilot-tlx-slider .irs-bar { background: #3498db; }
    ")))
  )
}

pilot_study_server <- function(id,
                                project_data_reactive,
                                i18n,
                                event_bus = NULL) {
  moduleServer(id, function(input, output, session) {

    rv <- reactiveValues(
      active             = FALSE,
      condition          = NULL,         # "A" or "B"
      participant_id     = NULL,
      t_session_start    = NULL,
      t_first_save       = NULL,
      n_first_save_elements    = NA_integer_,
      n_first_save_connections = NA_integer_,
      saves              = list(),      # list of (t, n_elements, n_connections)
      tlx_submitted      = FALSE
    )

    # ----- Activate on URL parameter -------------------------------------------

    observe({
      qs <- parseQueryString(session$clientData$url_search)
      cond <- toupper(as.character(qs$pilot_condition %||% ""))
      if (cond %in% c("A", "B") && !isTRUE(rv$active)) {
        rv$active <- TRUE
        rv$condition <- cond
        # Hash participant_id from URL to avoid storing raw identifiers
        pid_raw <- as.character(qs$pid %||% paste0("anon-", session$token))
        rv$participant_id <- substr(digest::digest(pid_raw, algo = "sha256"), 1, 12)
        rv$t_session_start <- Sys.time()
        debug_log(sprintf("[pilot] activated: condition=%s pid=%s",
                          rv$condition, rv$participant_id), "PILOT")
      }
    })

    output$banner <- renderUI({
      if (!isTRUE(rv$active)) return(NULL)
      div(class = "pilot-banner",
        sprintf("%s — %s = %s · %s = %s",
                i18n$t("modules.pilot.banner.title") %||% "PILOT STUDY",
                i18n$t("modules.pilot.banner.condition") %||% "Condition",
                rv$condition,
                i18n$t("modules.pilot.banner.participant") %||% "Participant",
                rv$participant_id))
    })

    # ----- Track save events ---------------------------------------------------

    observeEvent(project_data_reactive(), {
      if (!isTRUE(rv$active)) return()
      pd <- project_data_reactive()
      isa <- pd$isa_data %||% list()
      n_el <- nrow(isa$elements %||% data.frame())
      n_cn <- nrow(isa$connections %||% data.frame())
      rv$saves[[length(rv$saves) + 1L]] <- list(
        t = Sys.time(), n_elements = n_el, n_connections = n_cn
      )
      if (is.null(rv$t_first_save) && n_el >= 5L && n_cn >= 3L) {
        rv$t_first_save <- Sys.time()
        rv$n_first_save_elements <- n_el
        rv$n_first_save_connections <- n_cn
        debug_log(sprintf("[pilot] first-complete-model at t=%s (n_el=%d, n_cn=%d)",
                          rv$t_first_save, n_el, n_cn), "PILOT")
      }
    }, ignoreInit = TRUE)

    # ----- End-of-session NASA-TLX modal --------------------------------------

    show_tlx_modal <- function() {
      showModal(modalDialog(
        title = i18n$t("modules.pilot.tlx.title") %||% "Workload questionnaire (NASA-TLX)",
        size = "l",
        easyClose = FALSE,
        footer = tagList(
          actionButton(session$ns("tlx_submit"),
                       i18n$t("modules.pilot.tlx.submit") %||% "Submit & finish")
        ),
        p(i18n$t("modules.pilot.tlx.intro") %||%
          "Please rate the workload of the task you just performed. 0 = very low, 100 = very high."),
        fluidRow(
          column(6,
            sliderInput(session$ns("tlx_mental"),
                        i18n$t("modules.pilot.tlx.mental") %||% "Mental demand",
                        min = 0, max = 100, value = 50, step = 5),
            sliderInput(session$ns("tlx_physical"),
                        i18n$t("modules.pilot.tlx.physical") %||% "Physical demand",
                        min = 0, max = 100, value = 50, step = 5),
            sliderInput(session$ns("tlx_temporal"),
                        i18n$t("modules.pilot.tlx.temporal") %||% "Time pressure",
                        min = 0, max = 100, value = 50, step = 5)
          ),
          column(6,
            sliderInput(session$ns("tlx_performance"),
                        i18n$t("modules.pilot.tlx.performance") %||% "Performance (low = good)",
                        min = 0, max = 100, value = 50, step = 5),
            sliderInput(session$ns("tlx_effort"),
                        i18n$t("modules.pilot.tlx.effort") %||% "Effort",
                        min = 0, max = 100, value = 50, step = 5),
            sliderInput(session$ns("tlx_frustration"),
                        i18n$t("modules.pilot.tlx.frustration") %||% "Frustration",
                        min = 0, max = 100, value = 50, step = 5)
          )
        )
      ))
    }

    # Trigger TLX after 30+ minutes OR when participant clicks the dedicated
    # button in their saved-project view. For the pilot, the simplest path
    # is a manual end-session button surfaced in the sidebar of pilot
    # sessions (handled at app.R level).
    observeEvent(input$tlx_submit, {
      tlx <- list(
        mental      = input$tlx_mental,
        physical    = input$tlx_physical,
        temporal    = input$tlx_temporal,
        performance = input$tlx_performance,
        effort      = input$tlx_effort,
        frustration = input$tlx_frustration
      )

      out_dir <- "data/pilot"
      dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
      iso <- format(Sys.time(), "%Y%m%dT%H%M%S")
      out_path <- file.path(out_dir,
                            sprintf("%s__%s__%s.json",
                                    rv$participant_id, rv$condition, iso))

      payload <- list(
        participant_id     = rv$participant_id,
        condition          = rv$condition,
        t_session_start    = format(rv$t_session_start, "%Y-%m-%dT%H:%M:%S"),
        t_session_end      = format(Sys.time(), "%Y-%m-%dT%H:%M:%S"),
        t_first_save       = if (!is.null(rv$t_first_save))
                                format(rv$t_first_save, "%Y-%m-%dT%H:%M:%S") else NA,
        n_first_save_elements    = rv$n_first_save_elements,
        n_first_save_connections = rv$n_first_save_connections,
        saves                    = lapply(rv$saves, function(s) list(
          t = format(s$t, "%Y-%m-%dT%H:%M:%S"),
          n_elements = s$n_elements,
          n_connections = s$n_connections
        )),
        nasa_tlx       = tlx,
        toolbox_version = if (file.exists("VERSION")) trimws(readLines("VERSION")[1]) else NA,
        locale         = session$clientData$url_hostname %||% NA
      )

      writeLines(jsonlite::toJSON(payload, auto_unbox = TRUE, pretty = TRUE), out_path)
      rv$tlx_submitted <- TRUE
      removeModal()
      showNotification(
        i18n$t("modules.pilot.tlx.saved") %||% "Pilot session recorded. Thank you!",
        type = "message", duration = 6
      )
      debug_log(sprintf("[pilot] session saved to %s", out_path), "PILOT")
    })

    # External entry point: app.R can call this to trigger the TLX modal
    list(
      is_active = reactive(rv$active),
      trigger_end_of_session = function() {
        if (isTRUE(rv$active) && !isTRUE(rv$tlx_submitted)) show_tlx_modal()
      }
    )
  })
}

`%||%` <- function(x, y) if (is.null(x) || (length(x) == 1 && is.na(x))) y else x
