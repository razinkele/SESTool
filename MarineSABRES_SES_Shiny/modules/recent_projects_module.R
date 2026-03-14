# modules/recent_projects_module.R
# Recent Projects Module - Easy access to saved projects
#
# PURPOSE: Provides a UI panel showing recently saved projects with
# one-click loading and clear visibility of where files are stored.

#' Recent Projects UI Component
#'
#' Creates a panel showing saved projects with load/delete actions
#'
#' @param id Module namespace ID
#' @param i18n Translation object
#' @return Shiny UI elements
#' @export
recent_projects_ui <- function(id, i18n) {
  ns <- NS(id)
  tryCatch(shiny.i18n::usei18n(i18n$translator %||% i18n), error = function(e) NULL)  # Enable reactive translation updates

  tagList(
    # CSS for recent projects panel
    tags$style(HTML("
      .recent-projects-container {
        padding: 15px;
      }

      .projects-folder-info {
        background: #e8f4f8;
        border: 1px solid #b8daff;
        border-radius: 8px;
        padding: 12px 15px;
        margin-bottom: 15px;
      }

      .projects-folder-info.connected {
        background: #d4edda;
        border-color: #c3e6cb;
      }

      .projects-folder-info.server-mode {
        background: #fff3cd;
        border-color: #ffeaa7;
      }

      .folder-path {
        font-family: 'Consolas', 'Monaco', monospace;
        font-size: 12px;
        color: #495057;
        background: rgba(255,255,255,0.7);
        padding: 4px 8px;
        border-radius: 4px;
        word-break: break-all;
        margin-top: 8px;
      }

      .project-list {
        max-height: 400px;
        overflow-y: auto;
      }

      .project-card {
        background: white;
        border: 1px solid #e0e0e0;
        border-radius: 8px;
        padding: 12px 15px;
        margin-bottom: 10px;
        transition: all 0.2s ease;
        cursor: pointer;
      }

      .project-card:hover {
        border-color: #007bff;
        box-shadow: 0 2px 8px rgba(0,123,255,0.15);
        transform: translateY(-1px);
      }

      .project-card.loading {
        opacity: 0.7;
        pointer-events: none;
      }

      .project-name {
        font-weight: 600;
        color: #333;
        font-size: 14px;
        margin-bottom: 4px;
      }

      .project-meta {
        font-size: 12px;
        color: #666;
      }

      .project-actions {
        margin-top: 8px;
        display: flex;
        gap: 8px;
      }

      .empty-projects {
        text-align: center;
        padding: 30px 20px;
        color: #666;
      }

      .empty-projects-icon {
        font-size: 48px;
        color: #ccc;
        margin-bottom: 15px;
      }

      .onboarding-tip {
        background: #e7f3ff;
        border-left: 4px solid #007bff;
        padding: 12px 15px;
        margin-top: 15px;
        border-radius: 0 6px 6px 0;
        font-size: 13px;
      }

      .onboarding-tip-title {
        font-weight: 600;
        color: #0056b3;
        margin-bottom: 5px;
      }

      .setup-panel {
        background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
        color: white;
        border-radius: 12px;
        padding: 30px;
        text-align: center;
        margin-bottom: 20px;
      }

      .setup-panel h3 {
        margin-bottom: 15px;
      }

      .setup-panel .folder-suggestion {
        background: rgba(255,255,255,0.2);
        border-radius: 8px;
        padding: 15px;
        margin: 20px 0;
        font-family: 'Consolas', 'Monaco', monospace;
        font-size: 13px;
        word-break: break-all;
      }

      .setup-panel .btn-confirm {
        background: white;
        color: #667eea;
        border: none;
        padding: 12px 30px;
        font-size: 16px;
        font-weight: 600;
        border-radius: 8px;
        margin: 5px;
      }

      .setup-panel .btn-confirm:hover {
        background: #f0f0f0;
      }

      .setup-panel .btn-change {
        background: transparent;
        color: white;
        border: 2px solid white;
        padding: 10px 20px;
        border-radius: 8px;
        margin: 5px;
      }

      .setup-panel .btn-change:hover {
        background: rgba(255,255,255,0.1);
      }
    ")),

    div(
      class = "recent-projects-container",

      # Setup panel (shows if not configured)
      uiOutput(ns("setup_panel")),

      # Folder info panel (shows if configured)
      uiOutput(ns("folder_info")),

      # Projects list
      uiOutput(ns("projects_list")),

      # Onboarding tip (shows once)
      uiOutput(ns("onboarding_tip"))
    )
  )
}

#' Recent Projects Server
#'
#' @param id Module namespace ID
#' @param project_data_reactive Reactive containing project data
#' @param i18n Translation object
#' @param event_bus Event bus for data updates
#' @return Module server outputs
#' @export
recent_projects_server <- function(id, project_data_reactive, i18n,
                                   event_bus = NULL) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # Reactive values for state
    state <- reactiveValues(
      deployment_mode = NULL,
      is_configured = FALSE,
      suggested_folder = NULL,
      projects_folder = NULL,
      projects = data.frame(),
      loading_project = NULL,
      show_onboarding = TRUE
    )

    # Initialize on startup
    observe({
      # Detect deployment mode
      state$deployment_mode <- detect_deployment_mode()

      # Check if storage is configured
      state$is_configured <- is_storage_configured()

      # Get suggested folder for display
      state$suggested_folder <- get_suggested_projects_folder()

      # Get configured projects folder (does NOT auto-create)
      state$projects_folder <- get_projects_folder()

      # Load projects list if configured
      if (!is.null(state$projects_folder)) {
        state$projects <- list_saved_projects(state$projects_folder)
      }

      debug_log(sprintf("Recent projects initialized - Mode: %s, Configured: %s, Folder: %s",
                 state$deployment_mode,
                 state$is_configured,
                 state$projects_folder %||% "NULL"), "RECENT_PROJECTS")
    })

    # Setup panel (shows when not configured in local mode)
    output$setup_panel <- renderUI({
      # Only show in local mode when not configured
      if (state$deployment_mode != "local" || state$is_configured) {
        return(NULL)
      }

      suggested <- state$suggested_folder

      div(
        class = "setup-panel",
        h3(icon("folder-open"), " ", i18n$t("ui.recent_projects.setup_title")),
        p(i18n$t("ui.recent_projects.setup_description")),

        div(
          class = "folder-suggestion",
          suggested %||% i18n$t("ui.recent_projects.no_folder_detected")
        ),

        div(
          style = "margin-top: 20px;",
          actionButton(
            ns("confirm_folder"),
            i18n$t("ui.recent_projects.use_this_folder"),
            icon = icon("check"),
            class = "btn-confirm"
          ),
          actionButton(
            ns("change_folder"),
            i18n$t("ui.recent_projects.choose_different"),
            icon = icon("folder"),
            class = "btn-change"
          )
        ),

        p(
          style = "margin-top: 15px; font-size: 12px; opacity: 0.8;",
          icon("info-circle"), " ",
          i18n$t("ui.recent_projects.setup_note")
        )
      )
    })

    # Handle folder confirmation
    observeEvent(input$confirm_folder, {
      suggested <- state$suggested_folder
      if (!is.null(suggested)) {
        result <- set_projects_folder(suggested)
        if (result$success) {
          state$is_configured <- TRUE
          state$projects_folder <- result$path
          state$projects <- list_saved_projects(result$path)

          showNotification(
            sprintf(i18n$t("ui.recent_projects.folder_configured"), get_display_path(result$path)),
            type = "message",
            duration = 5
          )
        } else {
          showNotification(
            paste(i18n$t("ui.recent_projects.folder_setup_failed"), result$error),
            type = "error",
            duration = 5
          )
        }
      }
    })

    # Handle folder change request
    observeEvent(input$change_folder, {
      showModal(modalDialog(
        title = i18n$t("ui.recent_projects.choose_folder_title"),
        size = "m",

        p(i18n$t("ui.recent_projects.choose_folder_description")),

        textInput(
          ns("custom_folder_path"),
          i18n$t("ui.recent_projects.folder_path"),
          value = state$suggested_folder %||% "",
          width = "100%"
        ),

        p(
          style = "font-size: 12px; color: #666;",
          icon("info-circle"), " ",
          i18n$t("ui.recent_projects.folder_path_hint")
        ),

        footer = tagList(
          modalButton(i18n$t("common.buttons.cancel")),
          actionButton(
            ns("save_custom_folder"),
            i18n$t("common.buttons.confirm"),
            class = "btn-primary"
          )
        )
      ))
    })

    # Handle custom folder save
    observeEvent(input$save_custom_folder, {
      custom_path <- input$custom_folder_path
      if (!is.null(custom_path) && custom_path != "") {
        result <- set_projects_folder(custom_path)
        if (result$success) {
          state$is_configured <- TRUE
          state$projects_folder <- result$path
          state$projects <- list_saved_projects(result$path)
          removeModal()

          showNotification(
            sprintf(i18n$t("ui.recent_projects.folder_configured"), get_display_path(result$path)),
            type = "message",
            duration = 5
          )
        } else {
          showNotification(
            paste(i18n$t("ui.recent_projects.folder_setup_failed"), result$error),
            type = "error",
            duration = 5
          )
        }
      }
    })

    # Folder info panel (only shows when configured)
    output$folder_info <- renderUI({
      mode <- state$deployment_mode
      folder <- state$projects_folder
      is_configured <- state$is_configured

      # Don't show if not configured (setup panel will show instead)
      if (mode == "local" && !is_configured) {
        return(NULL)
      }

      if (mode == "local" && !is.null(folder)) {
        # Local mode - show folder path
        div(
          class = "projects-folder-info connected",
          div(
            style = "display: flex; align-items: center; gap: 10px;",
            icon("folder-open", style = "font-size: 20px; color: #28a745;"),
            div(
              tags$strong(i18n$t("ui.recent_projects.projects_folder")),
              div(class = "folder-path", get_display_path(folder))
            )
          ),
          div(
            style = "margin-top: 10px;",
            actionButton(
              ns("open_folder"),
              i18n$t("ui.recent_projects.open_folder"),
              icon = icon("external-link-alt"),
              class = "btn-sm btn-outline-primary"
            ),
            actionButton(
              ns("refresh_list"),
              i18n$t("common.buttons.refresh"),
              icon = icon("sync"),
              class = "btn-sm btn-outline-secondary"
            ),
            actionButton(
              ns("change_folder"),
              i18n$t("ui.recent_projects.change_folder"),
              icon = icon("cog"),
              class = "btn-sm btn-outline-secondary"
            )
          )
        )
      } else {
        # Server mode - prompt for File System Access
        div(
          class = "projects-folder-info server-mode",
          div(
            style = "display: flex; align-items: center; gap: 10px;",
            icon("cloud", style = "font-size: 20px; color: #856404;"),
            div(
              tags$strong(i18n$t("ui.recent_projects.browser_storage")),
              tags$p(
                style = "margin: 5px 0 0 0; font-size: 13px;",
                i18n$t("ui.recent_projects.browser_storage_desc")
              )
            )
          ),
          div(
            style = "margin-top: 10px;",
            actionButton(
              ns("connect_folder"),
              i18n$t("ui.recent_projects.select_folder"),
              icon = icon("folder-open"),
              class = "btn-sm btn-primary"
            )
          )
        )
      }
    })

    # Projects list
    output$projects_list <- renderUI({
      projects <- state$projects

      if (is.null(projects) || nrow(projects) == 0) {
        # Empty state
        div(
          class = "empty-projects",
          div(class = "empty-projects-icon", icon("folder-open")),
          tags$h5(i18n$t("ui.recent_projects.no_projects")),
          tags$p(i18n$t("ui.recent_projects.no_projects_desc"))
        )
      } else {
        # Show projects
        div(
          class = "project-list",
          tags$h5(
            style = "margin-bottom: 15px;",
            sprintf("%s (%d)", i18n$t("ui.recent_projects.saved_projects"), nrow(projects))
          ),
          lapply(seq_len(min(nrow(projects), MAX_RECENT_PROJECTS)), function(i) {
            proj <- projects[i, ]
            div(
              class = "project-card",
              id = ns(paste0("project_", i)),
              onclick = sprintf("Shiny.setInputValue('%s', {index: %d, action: 'load'}, {priority: 'event'})",
                                ns("project_click"), i),

              div(class = "project-name", proj$name),
              div(
                class = "project-meta",
                sprintf("%s | %.1f KB | %s",
                        proj$type,
                        proj$size_kb,
                        format(proj$modified, "%Y-%m-%d %H:%M"))
              ),
              div(
                class = "project-actions",
                actionButton(
                  ns(paste0("load_", i)),
                  i18n$t("common.buttons.load"),
                  icon = icon("folder-open"),
                  class = "btn-xs btn-primary",
                  onclick = sprintf("event.stopPropagation(); Shiny.setInputValue('%s', {index: %d, action: 'load'}, {priority: 'event'})",
                                    ns("project_click"), i)
                ),
                actionButton(
                  ns(paste0("delete_", i)),
                  "",
                  icon = icon("trash"),
                  class = "btn-xs btn-outline-danger",
                  onclick = sprintf("event.stopPropagation(); Shiny.setInputValue('%s', {index: %d, action: 'delete'}, {priority: 'event'})",
                                    ns("project_click"), i)
                )
              )
            )
          })
        )
      }
    })

    # Onboarding tip
    output$onboarding_tip <- renderUI({
      if (!state$show_onboarding) return(NULL)
      if (state$deployment_mode != "local") return(NULL)

      div(
        class = "onboarding-tip",
        div(class = "onboarding-tip-title",
            icon("info-circle"), " ", i18n$t("ui.recent_projects.tip_title")),
        tags$p(
          style = "margin: 0;",
          sprintf(i18n$t("ui.recent_projects.tip_text"),
                  MARINESABRES_PROJECTS_FOLDER)
        ),
        actionButton(
          ns("dismiss_tip"),
          i18n$t("common.buttons.got_it"),
          class = "btn-xs btn-link",
          style = "padding: 0; margin-top: 8px;"
        )
      )
    })

    # Handle project click
    observeEvent(input$project_click, {
      req(input$project_click)
      index <- input$project_click$index
      action <- input$project_click$action
      projects <- state$projects

      if (index > nrow(projects)) return()

      project <- projects[index, ]

      if (action == "load") {
        # Load project
        state$loading_project <- project$path

        result <- load_project_persistent(project$path)

        if (result$success) {
          # Update project data
          project_data_reactive(result$data)

          # Emit event if bus available
          if (!is.null(event_bus)) {
            event_bus$emit_isa_change("recent_projects")
          }

          showNotification(
            sprintf(i18n$t("common.messages.project_loaded"), project$name),
            type = "message",
            duration = 3
          )
        } else {
          showNotification(
            paste(i18n$t("common.messages.project_load_failed"), result$error),
            type = "error",
            duration = 5
          )
        }

        state$loading_project <- NULL

      } else if (action == "delete") {
        # Confirm and delete
        showModal(modalDialog(
          title = i18n$t("ui.recent_projects.confirm_delete_title"),
          sprintf(i18n$t("ui.recent_projects.confirm_delete_message"), project$name),
          footer = tagList(
            modalButton(i18n$t("common.buttons.cancel")),
            actionButton(
              ns("confirm_delete"),
              i18n$t("common.buttons.delete"),
              class = "btn-danger",
              onclick = sprintf("Shiny.setInputValue('%s', %d, {priority: 'event'})",
                                ns("do_delete"), index)
            )
          )
        ))
      }
    })

    # Handle delete confirmation
    observeEvent(input$do_delete, {
      req(input$do_delete)
      index <- input$do_delete
      projects <- state$projects

      if (index > nrow(projects)) return()

      project <- projects[index, ]
      result <- delete_project_persistent(project$path)

      removeModal()

      if (result$success) {
        # Refresh list
        state$projects <- list_saved_projects(state$projects_folder)

        showNotification(
          sprintf(i18n$t("common.messages.project_deleted"), project$name),
          type = "warning",
          duration = 3
        )
      } else {
        showNotification(
          paste(i18n$t("common.messages.project_delete_failed"), result$error),
          type = "error",
          duration = 5
        )
      }
    })

    # Handle open folder button
    observeEvent(input$open_folder, {
      folder <- state$projects_folder
      if (!is.null(folder) && dir.exists(folder)) {
        # Open folder in file explorer
        if (.Platform$OS.type == "windows") {
          shell.exec(folder)
        } else if (Sys.info()["sysname"] == "Darwin") {
          system2("open", folder)
        } else {
          system2("xdg-open", folder)
        }
      }
    })

    # Handle refresh button
    observeEvent(input$refresh_list, {
      state$projects <- list_saved_projects(state$projects_folder)
    })

    # Handle connect folder button (server mode)
    observeEvent(input$connect_folder, {
      # Trigger File System Access API via local_storage module
      # This would integrate with the existing local_storage_module.R
      showNotification(
        i18n$t("ui.recent_projects.use_settings_to_connect"),
        type = "message",
        duration = 5
      )
    })

    # Dismiss onboarding tip
    observeEvent(input$dismiss_tip, {
      state$show_onboarding <- FALSE
    })

    # Return reactive for external access
    list(
      get_projects = reactive({ state$projects }),
      refresh = function() {
        state$projects <- list_saved_projects(state$projects_folder)
      },
      is_local_mode = reactive({ state$deployment_mode == "local" })
    )
  })
}
