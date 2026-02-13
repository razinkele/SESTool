# =============================================================================
# WORKFLOW STEPPER MODULE
# Displays a horizontal stepper bar for beginner users showing the 5-stage
# SES analysis pipeline: Get Started -> Create SES -> Visualize -> Analyze -> Report
# =============================================================================

# --- UI ---
workflow_stepper_ui <- function(id) {
  ns <- NS(id)
  uiOutput(ns("stepper_bar"))
}

# --- Server ---
workflow_stepper_server <- function(id, project_data_reactive, i18n,
                                    parent_session, user_level_reactive,
                                    sidebar_input) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # Step definitions: label key and target sidebar tab
    STEPS <- list(
      list(key = "step_get_started", tab = "entry_point"),
      list(key = "step_create_ses",  tab = "create_ses_standard"),
      list(key = "step_visualize",   tab = "cld_viz"),
      list(key = "step_analyze",     tab = "analysis_loops"),
      list(key = "step_report",      tab = "prepare_report")
    )

    # Workflow state
    wf <- reactiveValues(
      completed = c(FALSE, FALSE, FALSE, FALSE, FALSE),
      enabled   = c(TRUE,  TRUE,  FALSE, FALSE, FALSE),
      visible   = TRUE,
      user_modified_ses = FALSE,
      notified  = c(FALSE, FALSE, FALSE, FALSE, FALSE),
      viz_enter_time = NULL
    )

    # --- Count total ISA elements ---
    count_isa_elements <- function(data) {
      isa <- data$data$isa_data
      if (is.null(isa)) return(0)
      categories <- c("drivers", "activities", "pressures",
                       "marine_processes", "ecosystem_services",
                       "goods_benefits", "responses")
      total <- 0
      for (cat in categories) {
        if (!is.null(isa[[cat]]) && is.data.frame(isa[[cat]])) {
          total <- total + nrow(isa[[cat]])
        }
      }
      total
    }

    # --- Determine current step (first non-completed enabled step) ---
    current_step <- reactive({
      for (i in seq_along(wf$completed)) {
        if (!wf$completed[i] && wf$enabled[i]) return(i)
      }
      5
    })

    # --- COMPLETION OBSERVERS ---

    # Step 1: Get Started — mark complete when user navigates away from entry_point
    observe({
      req(sidebar_input())
      if (sidebar_input() != "entry_point" && !wf$completed[1]) {
        wf$completed[1] <- TRUE
        debug_log("Workflow step 1 (Get Started) completed", "STEPPER")
      }
    })

    # Track user modification of SES data (skip initial load)
    observeEvent(project_data_reactive(), {
      if (!wf$user_modified_ses) {
        wf$user_modified_ses <- TRUE
        debug_log("SES data modification tracking enabled", "STEPPER")
      }
    }, ignoreInit = TRUE)

    # Step 2: Create SES — elements >= 2 and user has modified data
    observe({
      req(project_data_reactive())
      if (wf$completed[2]) return()
      if (!wf$user_modified_ses) return()
      n <- count_isa_elements(project_data_reactive())
      if (n >= 2) {
        wf$completed[2] <- TRUE
        wf$enabled[3] <- TRUE
        wf$enabled[4] <- TRUE
        wf$enabled[5] <- TRUE
        debug_log(sprintf("Workflow step 2 (Create SES) completed with %d elements", n), "STEPPER")

        if (!wf$notified[2]) {
          wf$notified[2] <- TRUE
          msg <- sprintf(i18n$t("modules.workflow_stepper.nudge_ses_created"), n)
          showNotification(
            tagList(
              msg, tags$br(),
              actionButton(ns("go_viz"), i18n$t("modules.workflow_stepper.btn_go_visualization"),
                           class = "btn-sm btn-primary mt-2")
            ),
            type = "message", duration = 15
          )
        }
      }
    })

    # Step 3: Visualize — CLD tab visited with data for 3 seconds
    observe({
      req(sidebar_input())
      if (wf$completed[3]) return()
      if (!wf$enabled[3]) return()

      if (sidebar_input() == "cld_viz") {
        n <- count_isa_elements(project_data_reactive())
        if (n >= 2 && is.null(wf$viz_enter_time)) {
          wf$viz_enter_time <- Sys.time()
        }
      } else {
        wf$viz_enter_time <- NULL
      }
    })

    observe({
      req(wf$viz_enter_time)
      if (wf$completed[3]) return()
      invalidateLater(3000)
      if (!is.null(wf$viz_enter_time) && difftime(Sys.time(), wf$viz_enter_time, units = "secs") >= 3) {
        wf$completed[3] <- TRUE
        debug_log("Workflow step 3 (Visualize) completed", "STEPPER")

        if (!wf$notified[3]) {
          wf$notified[3] <- TRUE
          showNotification(
            tagList(
              i18n$t("modules.workflow_stepper.nudge_visualized"), tags$br(),
              actionButton(ns("go_analysis"), i18n$t("modules.workflow_stepper.btn_go_analysis"),
                           class = "btn-sm btn-primary mt-2")
            ),
            type = "message", duration = 15
          )
        }
      }
    })

    # Step 4: Analyze — loop detection results exist
    observe({
      req(project_data_reactive())
      if (wf$completed[4]) return()
      if (!wf$enabled[4]) return()
      loops <- project_data_reactive()$data$analysis$loops
      if (!is.null(loops)) {
        wf$completed[4] <- TRUE
        debug_log("Workflow step 4 (Analyze) completed", "STEPPER")

        if (!wf$notified[4]) {
          wf$notified[4] <- TRUE
          showNotification(
            tagList(
              i18n$t("modules.workflow_stepper.nudge_analyzed"), tags$br(),
              actionButton(ns("go_report"), i18n$t("modules.workflow_stepper.btn_go_report"),
                           class = "btn-sm btn-primary mt-2")
            ),
            type = "message", duration = 15
          )
        }
      }
    })

    # Step 5: Report — user visits report tab with all prior steps done
    observe({
      req(sidebar_input())
      if (wf$completed[5]) return()
      if (!wf$enabled[5]) return()
      if (sidebar_input() == "prepare_report" && all(wf$completed[1:4])) {
        wf$completed[5] <- TRUE
        debug_log("Workflow step 5 (Report) completed", "STEPPER")

        if (!wf$notified[5]) {
          wf$notified[5] <- TRUE
          showNotification(
            i18n$t("modules.workflow_stepper.nudge_complete"),
            type = "message", duration = 10
          )
        }
      }
    })

    # --- Handle imported/restored projects ---
    observeEvent(project_data_reactive(), {
      data <- project_data_reactive()
      n <- count_isa_elements(data)
      has_loops <- !is.null(data$data$analysis$loops)

      if (n >= 2 && !wf$completed[2]) {
        wf$completed[1] <- TRUE
        wf$completed[2] <- TRUE
        wf$enabled[3] <- TRUE
        wf$enabled[4] <- TRUE
        wf$enabled[5] <- TRUE
        wf$user_modified_ses <- TRUE
        debug_log("Imported project detected - steps 1-2 auto-completed", "STEPPER")
      }

      if (has_loops && !wf$completed[4] && wf$completed[2]) {
        wf$completed[3] <- TRUE
        wf$completed[4] <- TRUE
        debug_log("Imported project with loops - steps 3-4 auto-completed", "STEPPER")
      }
    }, ignoreInit = TRUE)

    # --- Handle element deletion (revert) ---
    observe({
      req(project_data_reactive())
      if (!wf$completed[2]) return()
      n <- count_isa_elements(project_data_reactive())
      if (n < 2) {
        wf$completed[2] <- FALSE
        wf$completed[3] <- FALSE
        wf$completed[4] <- FALSE
        wf$completed[5] <- FALSE
        wf$enabled[3] <- FALSE
        wf$enabled[4] <- FALSE
        wf$enabled[5] <- FALSE
        wf$notified[2] <- FALSE
        wf$notified[3] <- FALSE
        wf$notified[4] <- FALSE
        wf$notified[5] <- FALSE
        debug_log("Elements deleted below threshold - steps 2-5 reverted", "STEPPER")
      }
    })

    # --- NAVIGATION BUTTON HANDLERS ---
    observeEvent(input$go_viz, {
      updateTabItems(parent_session, "sidebar_menu", "cld_viz")
    })

    observeEvent(input$go_analysis, {
      updateTabItems(parent_session, "sidebar_menu", "analysis_loops")
    })

    observeEvent(input$go_report, {
      updateTabItems(parent_session, "sidebar_menu", "prepare_report")
    })

    observeEvent(input$dismiss_stepper, {
      wf$visible <- FALSE
      debug_log("Stepper dismissed by user", "STEPPER")
    })

    # Step click handlers
    lapply(seq_along(STEPS), function(i) {
      observeEvent(input[[paste0("step_click_", i)]], {
        if (wf$enabled[i] || wf$completed[i]) {
          updateTabItems(parent_session, "sidebar_menu", STEPS[[i]]$tab)
        }
      })
    })

    # --- RENDER STEPPER BAR ---
    output$stepper_bar <- renderUI({
      req(user_level_reactive() == "beginner")
      req(wf$visible)

      cur <- current_step()

      step_items <- lapply(seq_along(STEPS), function(i) {
        step <- STEPS[[i]]
        label <- i18n$t(paste0("modules.workflow_stepper.", step$key))

        css_class <- if (wf$completed[i]) {
          "ws-step ws-completed"
        } else if (i == cur) {
          "ws-step ws-active"
        } else if (wf$enabled[i]) {
          "ws-step ws-enabled"
        } else {
          "ws-step ws-locked"
        }

        icon_content <- if (wf$completed[i]) {
          tags$i(class = "fa fa-check")
        } else {
          as.character(i)
        }

        tooltip <- if (!wf$enabled[i] && !wf$completed[i]) {
          i18n$t("modules.workflow_stepper.locked_tooltip")
        } else {
          NULL
        }

        aria_current <- if (i == cur) "step" else NULL
        aria_disabled <- if (!wf$enabled[i] && !wf$completed[i]) "true" else NULL

        step_tag <- if (wf$enabled[i] || wf$completed[i]) {
          tags$div(
            class = css_class,
            title = tooltip,
            `aria-current` = aria_current,
            tags$a(
              id = ns(paste0("step_click_", i)),
              href = "#",
              class = "action-button",
              style = "text-decoration: none; color: inherit; display: flex; align-items: center; gap: 8px;",
              tags$span(class = "ws-step-icon", icon_content),
              tags$span(class = "ws-step-label", label)
            )
          )
        } else {
          tags$div(
            class = css_class,
            title = tooltip,
            `aria-disabled` = aria_disabled,
            tags$span(class = "ws-step-icon", icon_content),
            tags$span(class = "ws-step-label", label)
          )
        }

        if (i < length(STEPS)) {
          connector_class <- if (wf$completed[i] && (wf$completed[i + 1] || i + 1 == cur)) {
            "ws-connector ws-connector-done"
          } else {
            "ws-connector"
          }
          tagList(step_tag, tags$div(class = connector_class))
        } else {
          step_tag
        }
      })

      tags$nav(
        class = "workflow-stepper-bar",
        role = "navigation",
        `aria-label` = i18n$t("modules.workflow_stepper.aria_label"),
        tags$div(class = "workflow-stepper-steps", step_items),
        tags$a(
          id = ns("dismiss_stepper"),
          href = "#",
          class = "action-button ws-dismiss",
          title = i18n$t("modules.workflow_stepper.dismiss"),
          tags$i(class = "fa fa-times")
        )
      )
    })
  })
}
