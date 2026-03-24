# server/modals.R
# Modal dialog handlers for the MarineSABRES SES Toolbox
# Extracted from app.R for better maintainability

# ============================================================================
# LANGUAGE MODAL (Simplified)
# ============================================================================

#' Setup Language Modal Handlers
#'
#' @param input Shiny input object
#' @param output Shiny output object
#' @param session Shiny session object
#' @param i18n shiny.i18n translator object
#' @param AVAILABLE_LANGUAGES List of available languages
#' @param project_data reactiveVal containing the project data (optional, for preserving state during language change)
setup_language_modal_only <- function(input, output, session, i18n, AVAILABLE_LANGUAGES, project_data = NULL) {

  # Show language modal when button is clicked
  observeEvent(input$open_language_modal, {
    current_lang <- if(!is.null(i18n$get_translation_language())) {
      i18n$get_translation_language()
    } else {
      "en"
    }

    showModal(modalDialog(
      title = tags$h3(icon("globe"), " ", i18n$t("ui.header.change_language")),
      size = "m",
      easyClose = TRUE,
      footer = tagList(
        modalButton(i18n$t("common.buttons.cancel")),
        actionButton("apply_language_only", i18n$t("common.buttons.apply"), class = "btn-primary", icon = icon("check"))
      ),

      tags$div(
        style = "padding: 20px;",

        tags$p(
          style = "font-size: 15px; margin-bottom: 20px;",
          i18n$t("ui.modals.select_your_preferred_language_for_the_application_interface")
        ),

        selectInput(
          "language_selector",
          label = tags$strong(i18n$t("ui.modals.interface_language")),
          choices = setNames(
            names(AVAILABLE_LANGUAGES),
            sapply(AVAILABLE_LANGUAGES, function(x) paste(x$flag, x$name))
          ),
          selected = current_lang,
          width = "100%"
        ),

        tags$div(
          class = "alert alert-info",
          style = "margin-top: 20px;",
          icon("info-circle"),
          tags$strong(" ", i18n$t("common.labels.note"), " "),
          i18n$t("ui.modals.the_application_will_reload_to_apply_the_language_change")
        )
      )
    ))
  })

  # Handle Apply button click in language modal
  observeEvent(input$apply_language_only, {
    req(input$language_selector)

    new_lang <- input$language_selector

    debug_log(paste("Language changed to:", new_lang), "LANGUAGE")

    # Close the modal first
    removeModal()

    # Show loading overlay with translated message.
    # NOTE: These messages are intentionally hardcoded per-language rather than using
    # i18n$t(). This code runs during a language switch: the overlay is shown via JS
    # (showLanguageLoading handler) and must display the TARGET language's text
    # immediately, before the page reloads and i18n re-initializes with the new
    # language. Using i18n$t() here would show the OLD language's text instead.
    loading_messages <- list(
      en = "Changing Language",
      es = "Cambiando Idioma",
      fr = "Changement de Langue",
      de = "Sprache \u00c4ndern",
      lt = "Kei\u010diama Kalba",
      pt = "Mudando Idioma",
      it = "Cambio Lingua",
      no = "Endrer Spr\u00e5k",
      el = "\u0391\u03bb\u03bb\u03b1\u03b3\u03ae \u0393\u03bb\u03ce\u03c3\u03c3\u03b1\u03c2"
    )

    session$sendCustomMessage(
      type = "showLanguageLoading",
      message = list(text = loading_messages[[new_lang]])
    )

    # Update the translator language
    shiny.i18n::update_lang(new_lang, session)
    i18n$set_translation_language(new_lang)

    # IMPORTANT: Save project data to sessionStorage before reload to preserve user's work
    # This ensures SES creation progress is not lost during language changes
    if (!is.null(project_data)) {
      tryCatch({
        data <- project_data()
        if (!is.null(data)) {
          # Convert to JSON and send to JavaScript for sessionStorage
          data_json <- jsonlite::toJSON(data, auto_unbox = TRUE, null = "null", na = "null")
          session$sendCustomMessage(
            type = "saveProjectDataBeforeReload",
            message = list(data = as.character(data_json))
          )
          debug_log("Project data saved before language change reload", "LANGUAGE")
        }
      }, error = function(e) {
        debug_log(paste("Could not save project data before reload:", e$message), "LANGUAGE")
      })
    }

    # Save language to localStorage and reload with URL parameter
    # This ensures the language persists across reloads
    # Note: saveLanguageAndReload will be called after a short delay to ensure data is saved
    shinyjs::delay(MODAL_ANIMATION_DELAY_MS, {
      session$sendCustomMessage(type = "saveLanguageAndReload", message = new_lang)
    })
  })
}

# ============================================================================
# SETTINGS MODAL (Auto-Save Only)
# ============================================================================

# ---------------------------------------------------------------------------
# Settings Modal UI builder helpers (decomposed from setup_settings_modal_handlers)
# ---------------------------------------------------------------------------

.build_autosave_ui <- function(i18n, autosave_enabled, autosave_delay,
                               autosave_notifications, autosave_indicator,
                               autosave_triggers) {
  tagList(
    tags$h4(icon("save"), " ", i18n$t("ui.modals.autosave_title")),
    tags$p(style = "color: #666; margin-bottom: 20px;",
      i18n$t("ui.modals.autosave_description")
    ),

    shinyWidgets::switchInput(
      inputId = "autosave_enabled",
      label = tags$strong(i18n$t("ui.modals.autosave_enable")),
      value = autosave_enabled(),
      onLabel = i18n$t("ui.modals.autosave_on"),
      offLabel = i18n$t("ui.modals.autosave_off"),
      onStatus = "success",
      offStatus = "danger",
      size = "default",
      width = "100%"
    ),

    conditionalPanel(
      condition = "input.autosave_enabled == true",
      tags$div(
        style = "margin-top: 20px; padding: 15px; background: #f8f9fa; border-radius: 5px;",
        tags$h5(icon("sliders-h"), " ", i18n$t("ui.modals.autosave_advanced")),

        # Save interval
        tags$div(
          style = "margin-bottom: 15px;",
          tags$label(
            style = "font-weight: 600; margin-bottom: 5px; display: block;",
            icon("clock"), " ", i18n$t("ui.modals.autosave_delay_label")
          ),
          sliderInput(
            inputId = "autosave_delay", label = NULL,
            min = 1, max = 10,
            value = if (!is.null(autosave_delay)) autosave_delay() else 2,
            step = 0.5, width = "100%", ticks = TRUE
          ),
          tags$p(style = "font-size: 12px; color: #666; margin-top: -10px;",
            icon("info-circle"), " ", i18n$t("ui.modals.autosave_delay_help")
          )
        ),

        # Notification settings
        tags$div(
          style = "margin-bottom: 15px;",
          tags$label(style = CSS_LABEL_SEMIBOLD,
            icon("bell"), " ", i18n$t("ui.modals.autosave_notifications_label")
          ),
          shinyWidgets::switchInput(
            inputId = "autosave_notifications",
            label = i18n$t("ui.modals.autosave_show_notifications"),
            value = if (!is.null(autosave_notifications)) autosave_notifications() else FALSE,
            onLabel = i18n$t("common.labels.on"), offLabel = i18n$t("common.labels.off"),
            onStatus = "info", offStatus = "secondary",
            size = "small", inline = TRUE
          ),
          tags$p(style = "font-size: 12px; color: #666; margin-top: 5px;",
            i18n$t("ui.modals.autosave_notifications_help")
          )
        ),

        # Save indicator
        tags$div(
          style = "margin-bottom: 15px;",
          tags$label(style = CSS_LABEL_SEMIBOLD,
            icon("check-circle"), " ", i18n$t("ui.modals.autosave_indicator_label")
          ),
          shinyWidgets::switchInput(
            inputId = "autosave_indicator",
            label = i18n$t("ui.modals.autosave_show_indicator"),
            value = if (!is.null(autosave_indicator)) autosave_indicator() else TRUE,
            onLabel = i18n$t("common.labels.on"), offLabel = i18n$t("common.labels.off"),
            onStatus = "success", offStatus = "secondary",
            size = "small", inline = TRUE
          ),
          tags$p(style = "font-size: 12px; color: #666; margin-top: 5px;",
            i18n$t("ui.modals.autosave_indicator_help")
          )
        ),

        # What triggers autosave
        tags$div(
          style = "margin-bottom: 10px;",
          tags$label(style = CSS_LABEL_SEMIBOLD,
            icon("sync"), " ", i18n$t("ui.modals.autosave_triggers_label")
          ),
          checkboxGroupInput(
            inputId = "autosave_triggers", label = NULL,
            choices = setNames(
              c("elements", "context", "connections", "steps"),
              c(i18n$t("ui.modals.autosave_trigger_element"),
                i18n$t("ui.modals.autosave_trigger_context"),
                i18n$t("ui.modals.autosave_trigger_connections"),
                i18n$t("ui.modals.autosave_trigger_step"))
            ),
            selected = if (!is.null(autosave_triggers)) autosave_triggers() else c("elements", "context", "connections", "steps"),
            width = "100%"
          ),
          tags$p(style = "font-size: 12px; color: #666; margin-top: -5px;",
            i18n$t("ui.modals.autosave_triggers_help")
          )
        )
      )
    ),

    tags$div(
      class = "alert alert-info", style = "margin-top: 20px;",
      icon("lightbulb"),
      tags$strong(" ", i18n$t("ui.modals.autosave_tip"), " "),
      i18n$t("ui.modals.autosave_tip_text")
    )
  )
}

.build_local_storage_ui <- function(i18n) {
  tagList(
    tags$h4(icon("hdd"), " ", i18n$t("ui.modals.local_storage_settings")),
    tags$p(style = "color: #666; margin-bottom: 15px;",
      i18n$t("ui.modals.local_storage_description")
    ),

    tags$div(
      id = "local_storage_status_container",
      class = "local-storage-panel",

      # JavaScript-based rendering for File System API status
      local({
        js_safe <- function(txt) {
          raw <- jsonlite::toJSON(txt, auto_unbox = TRUE)
          substr(raw, 2, nchar(raw) - 1)
        }
        js_browser_not_supported <- js_safe(i18n$t("ui.modals.browser_not_supported"))
        js_browser_warning       <- js_safe(i18n$t("ui.modals.browser_warning"))
        js_connected_to          <- js_safe(i18n$t("ui.modals.connected_to"))
        js_no_folder_selected    <- js_safe(i18n$t("ui.modals.no_folder_selected"))

        tags$script(HTML(paste0("
        $(document).ready(function() {
          var i18n_browserNotSupported = '", js_browser_not_supported, "';
          var i18n_browserWarning = '", js_browser_warning, "';
          var i18n_connectedTo = '", js_connected_to, "';
          var i18n_noFolderSelected = '", js_no_folder_selected, "';

          function updateLocalStoragePanel() {
            var hasAPI = window.localStorageModule && window.localStorageModule.hasFileSystemAccess;
            var isConnected = window.localStorageModule && window.localStorageModule.directoryHandle !== null;

            if (!hasAPI) {
              $('#local_storage_api_status').html(
                '<div class=\"fallback-warning\" style=\"margin-bottom: 0;\">' +
                '<i class=\"fa fa-exclamation-triangle\"></i> ' +
                '<strong>' + i18n_browserNotSupported + '</strong><br>' +
                '<small>' + i18n_browserWarning + '</small>' +
                '</div>'
              );
              $('#local_storage_controls').hide();
            } else if (isConnected) {
              var dirName = window.localStorageModule.directoryHandle.name;
              // Sanitize directory name to prevent XSS
              var escDiv = document.createElement('div');
              escDiv.appendChild(document.createTextNode(dirName));
              var safeDirName = escDiv.innerHTML;
              $('#local_storage_api_status').html(
                '<div class=\"directory-status connected\">' +
                '<span class=\"directory-status-icon\">\U0001F4C1</span>' +
                '<div><strong>' + i18n_connectedTo + '</strong> ' + safeDirName + '</div>' +
                '</div>'
              );
              $('#btn_connect_local').hide();
              $('#btn_disconnect_local').show();
              $('#btn_save_to_local').show();
              $('#local_storage_controls').show();
            } else {
              $('#local_storage_api_status').html(
                '<div class=\"directory-status\">' +
                '<span class=\"directory-status-icon\">\U0001F4C2</span>' +
                '<div>' + i18n_noFolderSelected + '</div>' +
                '</div>'
              );
              $('#btn_connect_local').show();
              $('#btn_disconnect_local').hide();
              $('#btn_save_to_local').hide();
              $('#local_storage_controls').show();
            }
          }

          setTimeout(updateLocalStoragePanel, 500);

          Shiny.addCustomMessageHandler('update_local_storage_panel', function(message) {
            updateLocalStoragePanel();
          });
        });")))
      }),

      tags$div(id = "local_storage_api_status"),

      tags$div(
        id = "local_storage_controls", style = "margin-top: 15px;",
        actionButton("btn_connect_local",
          tagList(icon("folder-open"), " ", i18n$t("ui.modals.select_local_folder")),
          class = "btn-outline-primary", style = "margin-right: 10px;"
        ),
        actionButton("btn_disconnect_local",
          tagList(icon("unlink"), " ", i18n$t("ui.modals.disconnect_local_folder")),
          class = "btn-outline-secondary", style = "display: none; margin-right: 10px;"
        ),
        actionButton("btn_save_to_local",
          tagList(icon("save"), " ", i18n$t("ui.modals.save_current_project")),
          class = "btn-success", style = "display: none;"
        )
      ),

      tags$div(
        id = "local_autosave_container",
        style = "margin-top: 15px; padding: 10px; background: #f0f7ff; border-radius: 6px; display: none;",
        shinyWidgets::switchInput(
          inputId = "local_autosave_enabled",
          label = i18n$t("ui.modals.auto_save_to_local"),
          value = FALSE, onLabel = i18n$t("common.labels.on"), offLabel = i18n$t("common.labels.off"),
          onStatus = "success", offStatus = "secondary",
          size = "small", inline = TRUE
        ),
        tags$p(
          style = "font-size: 12px; color: #666; margin-top: 5px; margin-bottom: 0;",
          icon("info-circle"), " ", i18n$t("ui.modals.autosave_local_sync_help")
        )
      )
    )
  )
}

.build_general_settings_ui <- function(i18n) {
  tagList(
    tags$h4(icon("tools"), " ", i18n$t("ui.modals.general_settings")),
    tags$div(
      style = "margin-top: 15px;",
      shinyWidgets::switchInput(
        inputId = "debug_mode",
        label = tags$strong(i18n$t("ui.modals.debug_logging")),
        value = FALSE, onLabel = i18n$t("common.labels.on"), offLabel = i18n$t("common.labels.off"),
        onStatus = "warning", offStatus = "secondary",
        size = "default", width = "100%"
      ),
      tags$p(
        style = "margin-top: 10px; font-size: 13px; color: #666;",
        icon("bug"), " ", i18n$t("ui.modals.debug_logging_help")
      )
    )
  )
}

.build_ses_models_ui <- function(i18n, ses_models_directory) {
  tagList(
    tags$h4(icon("folder-open"), " ", i18n$t("ui.modals.ses_models_directory")),
    tags$div(
      style = "margin-top: 15px;",
      radioButtons(
        inputId = "ses_models_source",
        label = i18n$t("ui.modals.ses_models_source_label"),
        choices = setNames(
          c("default", "custom"),
          c(i18n$t("ui.modals.ses_models_default_directory"), i18n$t("ui.modals.ses_models_custom_directory"))
        ),
        selected = if (!is.null(ses_models_directory) && !is.null(ses_models_directory()) && nzchar(ses_models_directory())) "custom" else "default",
        width = "100%"
      ),
      conditionalPanel(
        condition = "input.ses_models_source == 'custom'",
        tags$div(
          style = "margin-top: 10px; padding: 15px; background: #f8f9fa; border-radius: 8px;",
          fluidRow(
            column(9,
              textInput("ses_models_custom_path",
                label = i18n$t("ui.modals.ses_models_custom_path"),
                value = if (!is.null(ses_models_directory)) ses_models_directory() else "",
                width = "100%",
                placeholder = i18n$t("ui.modals.ses_models_path_placeholder")
              )
            ),
            column(3,
              tags$div(style = "margin-top: 25px;",
                shinyDirButton("ses_models_dir_select",
                  label = i18n$t("ui.modals.browse"),
                  title = i18n$t("ui.modals.select_ses_models_directory"),
                  icon = icon("folder-open"), class = "btn-outline-primary"
                )
              )
            )
          ),
          tags$p(style = "font-size: 12px; color: #666; margin-top: 5px;",
            icon("info-circle"), " ", i18n$t("ui.modals.ses_models_directory_help")
          )
        )
      ),
      tags$div(
        id = "ses_models_path_info",
        style = "margin-top: 10px; padding: 10px; background: #e8f4f8; border-radius: 6px; font-size: 13px;",
        icon("check-circle", style = "color: #28a745;"), " ",
        tags$strong(i18n$t("ui.modals.current_directory")), ": ",
        tags$span(
          id = "current_ses_models_path", style = "font-family: monospace;",
          if (!is.null(ses_models_directory) && !is.null(ses_models_directory()) && nzchar(ses_models_directory()))
            ses_models_directory()
          else
            i18n$t("ui.modals.ses_models_default_path")
        )
      )
    )
  )
}

.build_reset_settings_ui <- function(i18n) {
  tagList(
    tags$h4(icon("redo"), " ", i18n$t("ui.modals.reset_settings")),
    tags$div(
      style = "margin-top: 15px; padding: 20px; background: #fff3cd; border: 1px solid #ffc107; border-radius: 8px;",
      tags$p(
        style = "margin-bottom: 15px; color: #856404;",
        icon("exclamation-triangle"), " ",
        i18n$t("ui.modals.reset_settings_warning")
      ),
      tags$p(
        style = "font-size: 13px; color: #666; margin-bottom: 15px;",
        i18n$t("ui.modals.reset_settings_description")
      ),
      tags$ul(
        style = "font-size: 13px; color: #666; margin-bottom: 15px;",
        tags$li(i18n$t("ui.modals.reset_item_storage")),
        tags$li(i18n$t("ui.modals.reset_item_autosave")),
        tags$li(i18n$t("ui.modals.reset_item_preferences"))
      ),
      actionButton(
        "btn_reset_all_settings",
        i18n$t("ui.modals.start_from_scratch"),
        icon = icon("trash-alt"),
        class = "btn-warning"
      )
    )
  )
}

.apply_settings <- function(input, i18n, autosave_enabled, autosave_delay,
                            autosave_notifications, autosave_indicator,
                            autosave_triggers, ses_models_directory) {
  settings_changed <- FALSE

  if (!is.null(input$autosave_enabled)) {
    autosave_enabled(input$autosave_enabled)
    debug_log(sprintf("Auto-save %s", if(input$autosave_enabled) "enabled" else "disabled"), "SETTINGS")
    settings_changed <- TRUE
  }

  if (!is.null(input$autosave_delay)) {
    autosave_delay(input$autosave_delay)
    debug_log(sprintf("Auto-save delay: %s seconds", input$autosave_delay), "SETTINGS")
    settings_changed <- TRUE
  }

  if (!is.null(input$autosave_notifications)) {
    autosave_notifications(input$autosave_notifications)
    debug_log(sprintf("Auto-save notifications: %s", input$autosave_notifications), "SETTINGS")
    settings_changed <- TRUE
  }

  if (!is.null(input$autosave_indicator)) {
    autosave_indicator(input$autosave_indicator)
    debug_log(sprintf("Auto-save indicator: %s", input$autosave_indicator), "SETTINGS")
    settings_changed <- TRUE
  }

  if (!is.null(input$autosave_triggers)) {
    autosave_triggers(input$autosave_triggers)
    debug_log(sprintf("Auto-save triggers: %s", paste(input$autosave_triggers, collapse = ", ")), "SETTINGS")
    settings_changed <- TRUE
  }

  if (!is.null(input$debug_mode)) {
    debug_log(sprintf("Debug mode %s", if(input$debug_mode) "enabled" else "disabled"), "SETTINGS")
    Sys.setenv(MARINESABRES_DEBUG = if (input$debug_mode) "TRUE" else "FALSE")
  }

  if (!is.null(ses_models_directory) && !is.null(input$ses_models_source)) {
    if (input$ses_models_source == "default") {
      ses_models_directory("")
      debug_log("SES Models directory reset to default", "SETTINGS")
      settings_changed <- TRUE
    } else if (input$ses_models_source == "custom" && !is.null(input$ses_models_custom_path)) {
      custom_path <- input$ses_models_custom_path
      if (nzchar(custom_path)) {
        if (dir.exists(custom_path)) {
          ses_models_directory(custom_path)
          debug_log(sprintf("SES Models directory set to: %s", custom_path), "SETTINGS")
          settings_changed <- TRUE
          invalidate_ses_models_cache()
        } else {
          showNotification(
            paste(i18n$t("ui.modals.directory_not_found"), custom_path),
            type = "error", duration = 5
          )
        }
      }
    }
  }

  removeModal()

  if (settings_changed || !is.null(input$autosave_delay)) {
    showNotification(
      i18n$t("ui.modals.settings_updated_successfully"),
      type = "message", duration = 3
    )
  }
}

# ---------------------------------------------------------------------------
#' Setup Settings Modal Handlers (Without Language)
#'
#' @param input Shiny input object
#' @param output Shiny output object
#' @param session Shiny session object
#' @param i18n shiny.i18n translator object
#' @param autosave_enabled reactiveVal for autosave setting
#' @param autosave_delay reactiveVal for autosave delay setting
#' @param autosave_notifications reactiveVal for autosave notifications setting
#' @param autosave_indicator reactiveVal for autosave indicator setting
#' @param autosave_triggers reactiveVal for autosave triggers setting
#' @param ses_models_directory reactiveVal for custom SES models directory
#' @param volumes Named vector of root volumes for shinyFiles directory chooser
setup_settings_modal_handlers <- function(input, output, session, i18n, autosave_enabled,
                                          autosave_delay = NULL,
                                          autosave_notifications = NULL,
                                          autosave_indicator = NULL,
                                          autosave_triggers = NULL,
                                          ses_models_directory = NULL,
                                          volumes = NULL) {

  if (!is.null(volumes)) {
    shinyDirChoose(input, "ses_models_dir_select", roots = volumes, session = session)
  }

  observeEvent(input$ses_models_dir_select, {
    req(input$ses_models_dir_select)
    if (!is.integer(input$ses_models_dir_select) && !is.null(volumes)) {
      selected_path <- parseDirPath(volumes, input$ses_models_dir_select)
      if (length(selected_path) > 0 && nzchar(selected_path)) {
        updateTextInput(session, "ses_models_custom_path", value = as.character(selected_path))
      }
    }
  })

  observeEvent(input$open_settings_modal, {
    showModal(modalDialog(
      title = tags$h3(icon("cog"), " ", i18n$t("ui.header.application_settings")),
      size = "l", easyClose = TRUE,
      footer = tagList(
        modalButton(i18n$t("common.buttons.cancel")),
        actionButton("apply_settings", i18n$t("common.buttons.apply"), class = "btn-primary", icon = icon("check"))
      ),
      tags$div(
        style = "padding: 20px;",
        .build_autosave_ui(i18n, autosave_enabled, autosave_delay,
                           autosave_notifications, autosave_indicator, autosave_triggers),
        tags$hr(),
        .build_local_storage_ui(i18n),
        tags$hr(),
        .build_general_settings_ui(i18n),
        tags$hr(),
        .build_ses_models_ui(i18n, ses_models_directory),
        tags$hr(),
        .build_reset_settings_ui(i18n)
      )
    ))
  })

  observeEvent(input$apply_settings, {
    .apply_settings(input, i18n, autosave_enabled, autosave_delay,
                    autosave_notifications, autosave_indicator,
                    autosave_triggers, ses_models_directory)
  })

  # Local storage button handlers
  observeEvent(input$btn_connect_local, {
    session$sendCustomMessage("request_directory_access", list())
  })
  observeEvent(input$btn_disconnect_local, {
    session$sendCustomMessage("clear_directory_handle", list())
    session$sendCustomMessage("update_local_storage_panel", list())
  })
  observeEvent(input$btn_save_to_local, {
    session$sendCustomMessage("trigger_local_save", list())
  })

  # Reset all settings handler
  observeEvent(input$btn_reset_all_settings, {
    # Show confirmation modal
    showModal(modalDialog(
      title = tags$h4(icon("exclamation-triangle", style = "color: #dc3545;"), " ",
                      i18n$t("ui.modals.confirm_reset_title")),
      size = "m",
      easyClose = FALSE,

      tags$div(
        style = "padding: 15px;",
        tags$p(
          style = "font-size: 15px;",
          i18n$t("ui.modals.confirm_reset_message")
        ),
        tags$p(
          style = "font-size: 13px; color: #666; margin-top: 15px;",
          i18n$t("ui.modals.confirm_reset_note")
        )
      ),

      footer = tagList(
        modalButton(i18n$t("common.buttons.cancel")),
        actionButton(
          "btn_confirm_reset",
          i18n$t("ui.modals.yes_reset_everything"),
          icon = icon("trash-alt"),
          class = "btn-danger"
        )
      )
    ))
  })

  # Execute reset when confirmed
  observeEvent(input$btn_confirm_reset, {
    tryCatch({
      # Clear storage configuration
      clear_storage_config()

      # Clear localStorage via JavaScript
      session$sendCustomMessage("clear_all_local_storage", list())

      # Reset autosave settings to defaults
      autosave_enabled(TRUE)
      if (!is.null(autosave_delay)) autosave_delay(2)
      if (!is.null(autosave_notifications)) autosave_notifications(FALSE)
      if (!is.null(autosave_indicator)) autosave_indicator(TRUE)
      if (!is.null(autosave_triggers)) autosave_triggers(c("elements", "context", "connections", "steps"))

      # Reset SES models directory
      if (!is.null(ses_models_directory)) ses_models_directory("")

      removeModal()

      showNotification(
        i18n$t("ui.modals.reset_complete"),
        type = "warning",
        duration = 5
      )

      # Suggest page reload for clean state
      showModal(modalDialog(
        title = i18n$t("ui.modals.reset_complete_title"),
        size = "s",
        easyClose = TRUE,

        tags$div(
          style = "text-align: center; padding: 20px;",
          icon("check-circle", style = "font-size: 48px; color: #28a745;"),
          tags$h4(style = "margin-top: 15px;", i18n$t("ui.modals.reset_complete")),
          tags$p(i18n$t("ui.modals.reset_reload_suggestion"))
        ),

        footer = tagList(
          modalButton(i18n$t("common.buttons.close")),
          actionButton(
            "btn_reload_page",
            i18n$t("ui.modals.reload_now"),
            icon = icon("sync"),
            class = "btn-primary",
            onclick = "location.reload();"
          )
        )
      ))

    }, error = function(e) {
      showNotification(
        paste(i18n$t("ui.modals.reset_failed"), e$message),
        type = "error",
        duration = 5
      )
    })
  })
}

# ============================================================================
# LEGACY: Combined Language/Settings Modal (Keep for compatibility)
# ============================================================================

#' Setup Language Settings Modal Handlers (Legacy)
#'
#' @param input Shiny input object
#' @param output Shiny output object
#' @param session Shiny session object
#' @param i18n shiny.i18n translator object
#' @param autosave_enabled reactiveVal for autosave setting
#' @param autosave_delay reactiveVal for autosave delay setting
#' @param autosave_notifications reactiveVal for autosave notifications setting
#' @param autosave_indicator reactiveVal for autosave indicator setting
#' @param autosave_triggers reactiveVal for autosave triggers setting
#' @param AVAILABLE_LANGUAGES List of available languages
#' @param ses_models_directory reactiveVal for custom SES models directory
#' @param volumes Named vector of root volumes for shinyFiles directory chooser
setup_language_modal_handlers <- function(input, output, session, i18n, autosave_enabled, AVAILABLE_LANGUAGES,
                                          autosave_delay = NULL,
                                          autosave_notifications = NULL,
                                          autosave_indicator = NULL,
                                          autosave_triggers = NULL,
                                          ses_models_directory = NULL,
                                          volumes = NULL,
                                          project_data = NULL) {
  # Call the new separate handlers
  # Pass project_data to language modal so it can save state before reload
  setup_language_modal_only(input, output, session, i18n, AVAILABLE_LANGUAGES, project_data)
  setup_settings_modal_handlers(input, output, session, i18n, autosave_enabled,
                                 autosave_delay, autosave_notifications,
                                 autosave_indicator, autosave_triggers,
                                 ses_models_directory, volumes)
}

# ============================================================================
# USER LEVEL MODAL (with per-level feature configuration)
# ============================================================================

# ---------------------------------------------------------------------------
# Helper: build the feature-configuration panel shown below the level picker
# ---------------------------------------------------------------------------
.build_level_features_ui <- function(i18n, level, config) {
  # config is the effective config (defaults + overrides) for this level

  # Max elements slider (unlimited = 0, shown as toggle + slider)
  max_elem_val <- config$max_elements_per_category
  max_elem_unlimited <- (max_elem_val == 0)
  max_elem_slider_val <- if (max_elem_unlimited) BEGINNER_MAX_ELEMENTS_DEFAULT else max_elem_val

  tags$div(
    id = "level_features_panel",
    style = "margin-top: 18px; padding: 16px; background: #f8f9fa; border-radius: 8px; border: 1px solid #dee2e6;",

    # --- Section: Elements ---
    tags$h5(
      style = "margin-bottom: 12px; color: #495057;",
      icon("cubes"), " ", i18n$t("ui.modals.level_section_elements")
    ),
    tags$div(
      style = "margin-bottom: 8px;",
      checkboxInput(
        "level_unlimited_elements",
        label = tags$span(style = "font-weight: 500;", i18n$t("ui.modals.level_unlimited_elements")),
        value = max_elem_unlimited,
        width = "100%"
      )
    ),
    conditionalPanel(
      condition = "!input.level_unlimited_elements",
      tags$div(
        style = "padding: 0 8px;",
        sliderInput(
          "level_max_elements",
          label = i18n$t("ui.modals.max_elements_per_category"),
          min = BEGINNER_MAX_ELEMENTS_MIN,
          max = BEGINNER_MAX_ELEMENTS_MAX,
          value = max_elem_slider_val,
          step = 1,
          width = "100%"
        )
      )
    ),

    tags$hr(style = "margin: 14px 0;"),

    # --- Section: Menu Items ---
    tags$h5(
      style = "margin-bottom: 12px; color: #495057;",
      icon("bars"), " ", i18n$t("ui.modals.level_section_menu_items")
    ),
    tags$div(
      style = "padding-left: 4px;",
      checkboxInput("level_show_pims",
        label = i18n$t("ui.modals.level_show_pims"),
        value = config$show_pims, width = "100%"),
      checkboxInput("level_show_graphical_ses_creator",
        label = i18n$t("ui.modals.level_show_graphical_ses"),
        value = config$show_graphical_ses_creator, width = "100%"),
      checkboxInput("level_show_response_validation",
        label = i18n$t("ui.modals.level_show_response_validation"),
        value = config$show_response_validation, width = "100%"),
      checkboxInput("level_show_scenario_builder",
        label = i18n$t("ui.modals.level_show_scenario_builder"),
        value = config$show_scenario_builder, width = "100%"),
      checkboxInput("level_show_all_analysis_tools",
        label = i18n$t("ui.modals.level_show_all_analysis"),
        value = config$show_all_analysis_tools, width = "100%"),
      checkboxInput("level_show_create_ses_method_chooser",
        label = i18n$t("ui.modals.level_show_method_chooser"),
        value = config$show_create_ses_method_chooser, width = "100%")
    ),

    tags$hr(style = "margin: 14px 0;"),

    # --- Section: Guidance ---
    tags$h5(
      style = "margin-bottom: 12px; color: #495057;",
      icon("info-circle"), " ", i18n$t("ui.modals.level_section_guidance")
    ),
    tags$div(
      style = "padding-left: 4px;",
      checkboxInput("level_show_workflow_stepper",
        label = i18n$t("ui.modals.level_show_stepper"),
        value = config$show_workflow_stepper, width = "100%"),
      checkboxInput("level_show_advanced_cld_controls",
        label = i18n$t("ui.modals.level_show_advanced_cld"),
        value = config$show_advanced_cld_controls, width = "100%")
    ),

    tags$hr(style = "margin: 14px 0;"),

    # --- Section: Templates ---
    tags$h5(
      style = "margin-bottom: 12px; color: #495057;",
      icon("file-alt"), " ", i18n$t("ui.modals.level_section_templates")
    ),
    radioButtons(
      "level_template_filter",
      label = NULL,
      choices = setNames(
        c("all", "simple"),
        c(i18n$t("ui.modals.level_templates_all"), i18n$t("ui.modals.level_templates_simple"))
      ),
      selected = config$template_filter,
      inline = TRUE,
      width = "100%"
    ),

    tags$hr(style = "margin: 14px 0;"),

    # --- Reset to defaults button ---
    tags$div(
      style = "text-align: right;",
      actionButton(
        "reset_level_defaults",
        tagList(icon("undo"), " ", i18n$t("ui.modals.level_reset_defaults")),
        class = "btn-outline-secondary btn-sm"
      )
    )
  )
}

# ---------------------------------------------------------------------------
# Collect overrides from modal inputs (only those differing from defaults)
# ---------------------------------------------------------------------------
.collect_level_overrides <- function(input, level) {
  defaults <- USER_LEVEL_DEFAULTS[[level]]
  if (is.null(defaults)) return(list())

  overrides <- list()

  # Max elements
  if (isTRUE(input$level_unlimited_elements)) {
    if (defaults$max_elements_per_category != 0L) {
      overrides$max_elements_per_category <- 0L
    }
  } else {
    val <- as.integer(input$level_max_elements %||% defaults$max_elements_per_category)
    if (val != defaults$max_elements_per_category) {
      overrides$max_elements_per_category <- val
    }
  }

  # Boolean toggles
  bool_keys <- c(
    "show_pims", "show_graphical_ses_creator", "show_response_validation",
    "show_scenario_builder", "show_all_analysis_tools",
    "show_create_ses_method_chooser", "show_workflow_stepper",
    "show_advanced_cld_controls"
  )
  input_names <- c(
    "level_show_pims", "level_show_graphical_ses_creator", "level_show_response_validation",
    "level_show_scenario_builder", "level_show_all_analysis_tools",
    "level_show_create_ses_method_chooser", "level_show_workflow_stepper",
    "level_show_advanced_cld_controls"
  )

  for (i in seq_along(bool_keys)) {
    val <- input[[input_names[i]]]
    if (!is.null(val) && as.logical(val) != defaults[[bool_keys[i]]]) {
      overrides[[bool_keys[i]]] <- as.logical(val)
    }
  }

  # Template filter
  tf <- input$level_template_filter
  if (!is.null(tf) && tf != defaults$template_filter) {
    overrides$template_filter <- tf
  }

  overrides
}

#' Setup User Level Modal Handlers
#'
#' Provides a comprehensive settings modal with level selector at the top
#' and per-level feature configuration below.
#'
#' @param input Shiny input object
#' @param output Shiny output object
#' @param session Shiny session object
#' @param user_level reactiveVal for user experience level
#' @param i18n shiny.i18n translator object
setup_user_level_modal_handlers <- function(input, output, session, user_level, i18n) {

  # ------ JavaScript for localStorage persistence of level config ------
  # Register custom message handlers once (idempotent on client)
  observe({
    shinyjs::runjs("
      // --- Level config localStorage helpers ---
      if (!window._levelConfigHandlersRegistered) {
        window._levelConfigHandlersRegistered = true;

        Shiny.addCustomMessageHandler('save_level_config', function(message) {
          try {
            var key = 'marinesabres_level_config_' + message.level;
            localStorage.setItem(key, JSON.stringify(message.overrides || {}));
            console.log('[LEVEL_CONFIG] Saved overrides for', message.level);
          } catch(e) {
            console.error('[LEVEL_CONFIG] Save failed:', e);
          }
        });

        Shiny.addCustomMessageHandler('load_level_config', function(message) {
          try {
            var level = message.level || 'beginner';
            var key = 'marinesabres_level_config_' + level;
            var raw = localStorage.getItem(key);
            var overrides = raw ? JSON.parse(raw) : {};
            Shiny.setInputValue('_level_config_loaded', {
              level: level,
              overrides: overrides
            }, {priority: 'event'});
          } catch(e) {
            console.error('[LEVEL_CONFIG] Load failed:', e);
            Shiny.setInputValue('_level_config_loaded', {level: message.level, overrides: {}}, {priority: 'event'});
          }
        });

        Shiny.addCustomMessageHandler('clear_level_config', function(message) {
          try {
            var key = 'marinesabres_level_config_' + message.level;
            localStorage.removeItem(key);
            console.log('[LEVEL_CONFIG] Cleared overrides for', message.level);
          } catch(e) {
            console.error('[LEVEL_CONFIG] Clear failed:', e);
          }
        });
      }
    ")
  }) |> bindEvent(session$clientData$url_search, once = TRUE)

  # ------ Load config from localStorage on startup ------
  observe({
    level <- user_level()
    session$sendCustomMessage("load_level_config", list(level = level))
  }) |> bindEvent(user_level(), once = TRUE)

  # Apply loaded config
  observeEvent(input$`_level_config_loaded`, {
    data <- input$`_level_config_loaded`
    if (!is.null(data)) {
      parsed <- parse_level_config_from_js(data)
      set_active_level_config(parsed$level, parsed$overrides)
      debug_log(sprintf("Level config restored from localStorage: level=%s, overrides=%d",
                         parsed$level, length(parsed$overrides)), "LEVEL_CONFIG")
    }
  })

  # ------ Show user level modal ------
  observeEvent(input$open_user_level_modal, {
    current_level <- user_level()
    config <- get_level_config(current_level)

    showModal(modalDialog(
      title = tags$h3(icon("user-cog"), " ", i18n$t("ui.header.user_experience_level")),
      size = "l",
      easyClose = FALSE,

      tags$div(
        style = "padding: 10px;",

        tags$p(
          style = "margin-bottom: 20px; font-size: 14px;",
          i18n$t("ui.modals.select_your_experience_level_with_marine_ecosystem_modeling")
        ),

        # Level radio buttons
        radioButtons(
          "user_level_selector",
          label = NULL,
          choices = setNames(
            c("beginner", "intermediate", "expert"),
            c(
              paste("\U0001F7E2", i18n$t("modules.ses.creation.beginner"), "-", i18n$t("ui.modals.simplified_interface_for_first_time_users_shows_essential_tools_only")),
              paste("\U0001F7E1", i18n$t("modules.ses.creation.intermediate"), "-", i18n$t("ui.modals.standard_interface_for_regular_users_shows_most_tools_and_features")),
              paste("\U0001F534", i18n$t("ui.modals.expert"), "-", i18n$t("ui.modals.advanced_interface_showing_all_tools_technical_ter"))
            )
          ),
          selected = current_level,
          width = "100%"
        ),

        # Dynamic feature configuration panel
        uiOutput("level_features_container"),

        tags$hr(),

        tags$p(
          style = "font-size: 12px; color: #666; margin-top: 15px;",
          icon("info-circle"), " ",
          i18n$t("ui.modals.the_application_will_reload_to_apply_the_new_user_experience_level")
        )
      ),

      footer = tagList(
        actionButton("cancel_user_level", i18n$t("common.buttons.cancel"), class = "btn-default"),
        actionButton("apply_user_level", i18n$t("ui.modals.apply_changes"), class = "btn-primary", icon = icon("check"))
      )
    ))
  })

  # ------ Dynamic feature panel (re-renders when level selector changes) ------
  output$level_features_container <- renderUI({
    selected_level <- input$user_level_selector
    req(selected_level)

    # Get config for the newly selected level (with any stored overrides)
    # When switching levels, show that level's defaults + its stored overrides
    config <- get_level_config(selected_level)

    .build_level_features_ui(i18n, selected_level, config)
  })

  # ------ Reset to defaults button ------
  observeEvent(input$reset_level_defaults, {
    selected_level <- input$user_level_selector
    req(selected_level)

    # Clear stored overrides for this level
    session$sendCustomMessage("clear_level_config", list(level = selected_level))
    reset_level_config(selected_level)

    # Re-show the modal with fresh defaults
    removeModal()

    # Small delay then re-open
    shinyjs::delay(MODAL_ANIMATION_DELAY_MS + 50, {
      # Trigger the modal open handler again
      shinyjs::click("open_user_level_modal")
    })

    showNotification(
      i18n$t("ui.modals.level_defaults_restored"),
      type = "message", duration = 3
    )
  })

  # ------ Apply user level changes ------
  observeEvent(input$apply_user_level, {
    req(input$user_level_selector)

    new_level <- input$user_level_selector
    overrides <- .collect_level_overrides(input, new_level)
    effective_config <- get_level_config(new_level, overrides)

    debug_log(sprintf("Applying level: %s -> %s (overrides: %d)", user_level(), new_level, length(overrides)), "USER-LEVEL")

    # Persist overrides to localStorage
    session$sendCustomMessage(
      type = "save_level_config",
      message = list(level = new_level, overrides = overrides)
    )

    # Also save max_elements for backward compatibility with existing JS handler
    max_elements <- effective_config$max_elements_per_category
    if (max_elements == 0L) max_elements <- BEGINNER_MAX_ELEMENTS_DEFAULT
    session$sendCustomMessage(
      type = "save_beginner_max_elements",
      message = list(value = max_elements)
    )

    # Update the in-memory config
    set_active_level_config(new_level, overrides)

    # Save to URL and reload via JavaScript (same as before)
    session$sendCustomMessage(
      type = "save_user_level",
      message = list(level = new_level)
    )

    removeModal()

    showNotification(
      i18n$t("ui.modals.applying_new_user_experience_level"),
      type = "message",
      duration = 2
    )
  })

  # Cancel user level changes
  observeEvent(input$cancel_user_level, {
    removeModal()
  })
}

# ============================================================================
# DOWNLOAD MANUALS MODAL
# ============================================================================

#' Setup Download Manuals Modal Handlers
#'
#' @param input Shiny input object
#' @param output Shiny output object
#' @param session Shiny session object
#' @param i18n shiny.i18n translator object
setup_manuals_modal_handlers <- function(input, output, session, i18n) {

  # Show manuals modal when button is clicked
  observeEvent(input$open_manuals_modal, {
    showModal(modalDialog(
      title = tags$h3(icon("download"), " ", i18n$t("ui.modals.download_user_manuals_guides")),
      size = "l",
      easyClose = TRUE,
      footer = modalButton(i18n$t("common.buttons.close")),

      tags$div(
        style = "padding: 20px;",

        # Beginner-Friendly Guides Section
        tags$div(
          class = "well",
          style = "background: #e8f5e9; border-left: 4px solid #4caf50;",
          tags$h4(
            icon("graduation-cap"),
            " ",
            i18n$t("ui.modals.beginner_friendly_guides"),
            tags$span(
              class = "label label-success",
              style = "margin-left: 10px;",
              i18n$t("ui.modals.recommended_for_new_users")
            )
          ),
          tags$p(i18n$t("ui.modals.simple_practical_guides_with_step_by_step_instruct")),
          tags$div(
            style = "margin-top: 15px;",
            tags$a(
              href = "#",
              onclick = "window.open('beginner_guide.html', '_blank'); return false;",
              class = "btn btn-success btn-lg",
              style = "margin: 5px;",
              icon("graduation-cap"),
              " ",
              i18n$t("ui.modals.beginners_quick_start"),
              tags$br(),
              tags$small(i18n$t("ui.modals.5_minute_introduction"))
            ),
            tags$a(
              href = "#",
              onclick = "window.open('step_by_step_tutorial.html', '_blank'); return false;",
              class = "btn btn-success btn-lg",
              style = "margin: 5px;",
              icon("list-ol"),
              " ",
              i18n$t("ui.header.step_by_step_tutorial"),
              tags$br(),
              tags$small(i18n$t("ui.modals.20_minute_hands_on_walkthrough"))
            )
          )
        ),

        tags$hr(style = "margin: 25px 0;"),

        # Quick Reference
        tags$div(
          class = "well",
          tags$h4(icon("book"), " ", i18n$t("ui.modals.quick_reference_guide")),
          tags$p(i18n$t("ui.modals.compact_reference_for_experienced_users_who_need_a_quick_reminder")),
          tags$div(
            style = "margin-top: 15px;",
            tags$a(
              href = "#",
              onclick = "window.open('user_guide.html', '_blank'); return false;",
              class = "btn btn-primary btn-lg",
              style = "margin: 5px;",
              icon("book"),
              " ",
              i18n$t("ui.modals.quick_reference_guide"),
              tags$br(),
              tags$small(i18n$t("ui.modals.open_in_browser"))
            )
          )
        ),

        tags$hr(style = "margin: 25px 0;"),

        # Complete Manuals Section
        tags$div(
          class = "well",
          tags$h4(icon("file-alt"), " ", i18n$t("ui.modals.complete_user_manuals")),
          tags$p(i18n$t("ui.modals.comprehensive_documentation_with_detailed_explanat")),

          tags$h5(style = "margin-top: 20px; color: #337ab7;",
                 icon("globe"),
                 " ",
                 i18n$t("ui.modals.english_manual")),
          tags$div(
            style = "margin: 10px 0;",
            tags$a(
              href = "#",
              onclick = "window.open('docs/MarineSABRES_User_Manual_EN.html', '_blank'); return false;",
              class = "btn btn-info",
              style = "margin: 5px;",
              icon("file-code"),
              " ",
              i18n$t("ui.modals.html_version"),
              tags$br(),
              tags$small(i18n$t("ui.modals.view_online"))
            ),
            tags$a(
              href = "#",
              onclick = "window.open('docs/MarineSABRES_User_Manual_EN.pdf', '_blank'); return false;",
              class = "btn btn-info",
              style = "margin: 5px;",
              icon("file-pdf"),
              " ",
              i18n$t("ui.modals.pdf_version"),
              tags$br(),
              tags$small(i18n$t("ui.modals.downloadprint"))
            )
          ),

          tags$h5(style = "margin-top: 20px; color: #337ab7;",
                 icon("globe"),
                 " ",
                 i18n$t("ui.modals.french_manual")),
          tags$div(
            style = "margin: 10px 0;",
            tags$a(
              href = "#",
              onclick = "window.open('docs/MarineSABRES_User_Manual_FR.html', '_blank'); return false;",
              class = "btn btn-info",
              style = "margin: 5px;",
              icon("file-code"),
              " ",
              i18n$t("ui.modals.html_version"),
              tags$br(),
              tags$small(i18n$t("ui.modals.view_online"))
            ),
            tags$a(
              href = "#",
              onclick = "window.open('docs/MarineSABRES_User_Manual_FR.pdf', '_blank'); return false;",
              class = "btn btn-info",
              style = "margin: 5px;",
              icon("file-pdf"),
              " ",
              i18n$t("ui.modals.pdf_version"),
              tags$br(),
              tags$small(i18n$t("ui.modals.downloadprint"))
            )
          ),

          tags$div(
            class = "alert alert-info",
            style = "margin-top: 20px;",
            icon("info-circle"),
            " ",
            i18n$t("ui.modals.the_complete_manual_contains_approximately_75_page")
          )
        ),

        tags$hr(style = "margin: 25px 0;"),

        # Additional Resources
        tags$div(
          class = "well",
          tags$h4(icon("link"), " ", i18n$t("ui.modals.additional_resources")),
          tags$ul(
            tags$li(
              tags$strong(i18n$t("ui.modals.video_tutorials")),
              " ",
              i18n$t("ui.modals.coming_soon_check_back_later")
            ),
            tags$li(
              tags$strong(i18n$t("ui.modals.example_projects")),
              " ",
              i18n$t("ui.modals.available_in_the_template_library")
            ),
            tags$li(
              tags$strong(i18n$t("ui.modals.technical_documentation")),
              " ",
              i18n$t("ui.modals.for_developers_and_advanced_users")
            )
          )
        )
      )
    ))
  })
}

# ============================================================================
# ABOUT MODAL
# ============================================================================

#' Setup About Modal Handlers
#'
#' @param input Shiny input object
#' @param output Shiny output object
#' @param session Shiny session object
#' @param i18n shiny.i18n translator object
setup_about_modal_handlers <- function(input, output, session, i18n) {

  # Show about modal when button is clicked
  observeEvent(input$show_about_modal, {
    # Read version info
    version_info <- tryCatch(
      jsonlite::fromJSON("VERSION_INFO.json"),
      error = function(e) {
        debug_log(sprintf("Could not load VERSION_INFO.json: %s", e$message), "MODALS")
        list(version = "unknown", build_date = "unknown", r_version = "unknown")
      }
    )

    showModal(modalDialog(
      title = tags$h3(icon("info-circle"), " ", i18n$t("ui.modals.about_title")),
      size = "l",
      easyClose = TRUE,
      footer = modalButton(i18n$t("common.buttons.close")),

      tags$div(
        style = "padding: 20px;",

        # Application Info
        tags$div(
          class = "well",
          tags$h4(icon("cube"), " ", i18n$t("ui.modals.app_info")),
          tags$table(
            class = "table table-condensed",
            style = "margin-bottom: 0;",
            tags$tr(
              tags$td(tags$strong(i18n$t("ui.modals.version_label"))),
              tags$td(
                tags$span(
                  style = "font-size: 18px; color: #3c8dbc; font-weight: bold;",
                  version_info$version
                ),
                tags$span(
                  class = "label label-success",
                  style = "margin-left: 10px;",
                  version_info$status
                )
              )
            ),
            tags$tr(
              tags$td(tags$strong(i18n$t("ui.modals.release_name"))),
              tags$td(version_info$version_name)
            ),
            tags$tr(
              tags$td(tags$strong(i18n$t("ui.modals.release_date"))),
              tags$td(version_info$release_date)
            ),
            tags$tr(
              tags$td(tags$strong(i18n$t("ui.modals.release_type"))),
              tags$td(
                tags$span(
                  class = if(version_info$release_type == "major") "label label-danger"
                        else if(version_info$release_type == "minor") "label label-warning"
                        else "label label-info",
                  version_info$release_type
                )
              )
            )
          )
        ),

        # Features
        tags$div(
          class = "well",
          tags$h4(icon("star"), " ", i18n$t("ui.modals.key_features")),
          tags$ul(
            lapply(version_info$features, function(feature) {
              tags$li(feature)
            })
          )
        ),

        # Technical Info
        tags$div(
          class = "well",
          tags$h4(icon("cogs"), " ", i18n$t("ui.modals.technical_info")),
          tags$table(
            class = "table table-condensed",
            style = "margin-bottom: 0;",
            tags$tr(
              tags$td(tags$strong(i18n$t("ui.modals.min_r_version"))),
              tags$td(version_info$minimum_r_version)
            ),
            tags$tr(
              tags$td(tags$strong(i18n$t("ui.modals.current_r_version"))),
              tags$td(paste(R.version$major, R.version$minor, sep = "."))
            ),
            tags$tr(
              tags$td(tags$strong(i18n$t("ui.modals.platform_label"))),
              tags$td(R.version$platform)
            ),
            tags$tr(
              tags$td(tags$strong(i18n$t("ui.modals.git_branch"))),
              tags$td(version_info$build_info$git_branch)
            )
          )
        ),

        # Contributors
        tags$div(
          class = "well",
          tags$h4(icon("users"), " ", i18n$t("ui.modals.contributors")),
          tags$ul(
            lapply(version_info$contributors, function(contributor) {
              tags$li(contributor)
            })
          )
        ),

        # Links - use light background with dark text/links for readability
        tags$div(
          class = "alert",
          style = "background-color: var(--foam-white, #f8fbfd); border: 1px solid var(--mist-light, #e8f1f8); color: var(--ocean-deep, #0f2744);",
          icon("book", style = "color: var(--ocean-shallow, #2d5a7b);"),
          tags$strong(" ", i18n$t("ui.modals.documentation_label"), " "),
          tags$br(),
          tags$a(
            href = "#",
            onclick = "window.open('user_guide.html', '_blank'); return false;",
            i18n$t("ui.modals.quick_guide"),
            style = "margin-right: 15px; color: #1a5276; text-decoration: underline; font-weight: 500;"
          ),
          tags$a(
            href = "#",
            onclick = "window.open('docs/MarineSABRES_User_Manual_EN.html', '_blank'); return false;",
            i18n$t("ui.modals.manual_en_html"),
            style = "margin-right: 15px; color: #1a5276; text-decoration: underline; font-weight: 500;",
            title = i18n$t("ui.modals.manual_en_html_tooltip")
          ),
          tags$a(
            href = "#",
            onclick = "window.open('docs/MarineSABRES_User_Manual_EN.pdf', '_blank'); return false;",
            i18n$t("ui.modals.manual_en_pdf"),
            style = "margin-right: 15px; color: #1a5276; text-decoration: underline; font-weight: 500;",
            title = i18n$t("ui.modals.manual_en_pdf_tooltip")
          ),
          tags$a(
            href = "#",
            onclick = "window.open('docs/MarineSABRES_User_Manual_FR.html', '_blank'); return false;",
            i18n$t("ui.modals.manual_fr_html"),
            style = "margin-right: 15px; color: #1a5276; text-decoration: underline; font-weight: 500;",
            title = i18n$t("ui.modals.manual_fr_html_tooltip")
          ),
          tags$a(
            href = "#",
            onclick = "window.open('docs/MarineSABRES_User_Manual_FR.pdf', '_blank'); return false;",
            i18n$t("ui.modals.manual_fr_pdf"),
            style = "margin-right: 15px; color: #1a5276; text-decoration: underline; font-weight: 500;",
            title = i18n$t("ui.modals.manual_fr_pdf_tooltip")
          ),
          tags$a(
            href = "#",
            onclick = sprintf("window.open('%s', '_blank'); return false;", version_info$changelog_url),
            i18n$t("ui.modals.changelog"),
            style = "color: #1a5276; text-decoration: underline; font-weight: 500;"
          )
        )
      )
    ))
  })
}

# ============================================================================
# KB REFERENCES MODAL
# ============================================================================

#' Setup KB References Modal Handler
#'
#' Shows the knowledge base bibliography in a scrollable modal.
#'
#' @param input Shiny input
#' @param output Shiny output
#' @param session Shiny session
#' @param i18n Translator object
setup_kb_references_modal_handlers <- function(input, output, session, i18n) {

  observeEvent(input$show_kb_references_modal, {

    # Parse top references from KB JSON
    kb_refs <- tryCatch({
      kb_path <- file.path(PROJECT_ROOT %||% ".", "data", "ses_knowledge_db.json")
      if (file.exists(kb_path)) {
        kb <- jsonlite::fromJSON(kb_path, simplifyVector = FALSE)
        all_refs <- c()
        for (ctx in kb$contexts) {
          for (conn in ctx$connections) {
            if (!is.null(conn$references)) {
              all_refs <- c(all_refs, unlist(conn$references))
            }
          }
        }
        ref_counts <- sort(table(all_refs), decreasing = TRUE)
        list(top = head(ref_counts, 25), total = length(unique(all_refs)))
      } else {
        NULL
      }
    }, error = function(e) NULL)

    top_refs <- if (!is.null(kb_refs)) kb_refs$top else NULL
    total_refs <- if (!is.null(kb_refs)) kb_refs$total else 0

    # Build top references table
    top_refs_ui <- if (!is.null(top_refs) && length(top_refs) > 0) {
      rows <- lapply(seq_along(top_refs), function(i) {
        tags$tr(
          tags$td(style = "padding: 4px 8px; text-align: center;", i),
          tags$td(style = "padding: 4px 8px;", names(top_refs)[i]),
          tags$td(style = "padding: 4px 8px; text-align: center;", as.integer(top_refs[i]))
        )
      })
      tags$div(
        tags$p(style = "color: #555; margin-bottom: 10px;",
          paste0(total_refs, " ", i18n$t("ui.modals.unique_references_found"))),
        tags$div(style = "max-height: 500px; overflow-y: auto;",
          tags$table(
            class = "table table-sm table-striped",
            tags$thead(
              tags$tr(
                tags$th("#"),
                tags$th(i18n$t("ui.modals.reference")),
                tags$th(i18n$t("ui.modals.citations"))
              )
            ),
            tags$tbody(rows)
          )
        )
      )
    } else {
      tags$p(class = "text-muted", i18n$t("ui.modals.no_references_available"))
    }

    showModal(modalDialog(
      title = tags$h3(icon("book-open"), " ", i18n$t("ui.modals.kb_references_title")),
      size = "l",
      easyClose = TRUE,
      footer = modalButton(i18n$t("common.buttons.close")),
      tags$div(
        style = "padding: 10px;",
        tags$p(
          style = "color: #666; font-style: italic; margin-bottom: 15px;",
          i18n$t("ui.modals.kb_references_description")
        ),
        tags$h5(icon("star"), " ", i18n$t("ui.modals.top_cited_references")),
        top_refs_ui
      )
    ))
  })
}

# ============================================================================
# FEEDBACK MODAL
# ============================================================================

#' Setup Feedback Modal Handlers
#'
#' @param input Shiny input object
#' @param output Shiny output object
#' @param session Shiny session object
#' @param i18n shiny.i18n translator object
#' @param project_data Project data (reactive value or NULL)
#' @param user_level User level reactive value (or NULL)
setup_feedback_modal_handlers <- function(input, output, session, i18n,
                                          project_data = NULL, user_level = NULL) {

  # Server-side rate limiting
  last_submit_time <- reactiveVal(NULL)

  observeEvent(input$show_feedback_modal, {
    showModal(modalDialog(
      title = tags$h3(icon("comment-dots"), " ", i18n$t("ui.modals.feedback.modal_title")),
      size = "l",
      easyClose = TRUE,
      footer = tagList(
        modalButton(i18n$t("common.buttons.cancel")),
        actionButton("feedback_submit", i18n$t("ui.modals.feedback.submit"),
                     class = "btn-primary", icon = icon("paper-plane"))
      ),

      # JS to collect browser info
      tags$script("Shiny.setInputValue('feedback_browser_info', navigator.userAgent);"),

      tags$div(
        style = "padding: 10px;",

        # Report type (i18n-translated labels)
        radioButtons("feedback_type",
                     i18n$t("ui.modals.feedback.type_label"),
                     choices = setNames(
                       c("bug", "suggestion", "general"),
                       c(i18n$t("ui.modals.feedback.type_bug"),
                         i18n$t("ui.modals.feedback.type_suggestion"),
                         i18n$t("ui.modals.feedback.type_general"))
                     ),
                     selected = "bug"),

        # Title
        textInput("feedback_title",
                  i18n$t("ui.modals.feedback.title_label"),
                  placeholder = i18n$t("ui.modals.feedback.title_placeholder"),
                  width = "100%"),
        tags$script(HTML("document.getElementById('feedback_title').maxLength = 200;")),

        # Description
        textAreaInput("feedback_description",
                      i18n$t("ui.modals.feedback.description_label"),
                      placeholder = i18n$t("ui.modals.feedback.description_placeholder"),
                      rows = 5, width = "100%"),
        tags$script(HTML("document.getElementById('feedback_description').maxLength = 5000;")),

        # Steps to reproduce (bug only)
        conditionalPanel(
          condition = "input.feedback_type == 'bug'",
          textAreaInput("feedback_steps",
                        i18n$t("ui.modals.feedback.steps_label"),
                        placeholder = i18n$t("ui.modals.feedback.steps_placeholder"),
                        rows = 3, width = "100%")
          # Note: maxlength for steps enforced server-side (substr to 2000) since
          # this field is inside conditionalPanel and JS getElementById may fail
        ),

        # Collapsible system info
        tags$details(
          style = "margin-top: 15px; padding: 10px; background: #f8f9fa; border-radius: 5px;",
          tags$summary(style = "cursor: pointer; font-weight: bold;",
                       icon("info-circle"), " ", i18n$t("ui.modals.feedback.context_label")),
          tags$div(
            style = "margin-top: 10px; font-size: 12px; color: #666;",
            uiOutput("feedback_context_display")
          )
        )
      )
    ))
  })

  # Render system context in modal
  output$feedback_context_display <- renderUI({
    pd <- if (!is.null(project_data)) {
      tryCatch(isolate(project_data()), error = function(e) NULL)
    } else NULL
    ul <- if (!is.null(user_level)) tryCatch(isolate(user_level()), error = function(e) "unknown") else "unknown"
    lang <- tryCatch(i18n$get_translation_language(), error = function(e) "en")
    ctx <- collect_system_context(session, input, pd, user_level = ul, language = lang)
    tags$pre(style = "font-size: 11px; white-space: pre-wrap;",
      paste(
        sprintf("%s: %s", i18n$t("ui.modals.feedback.ctx_version"), ctx$app_version),
        sprintf("%s: %s", i18n$t("ui.modals.feedback.ctx_level"), ctx$user_level),
        sprintf("%s: %s", i18n$t("ui.modals.feedback.ctx_page"), ctx$current_tab),
        sprintf("%s: %s", i18n$t("ui.modals.feedback.ctx_language"), ctx$language),
        sprintf("%s: %d", i18n$t("ui.modals.feedback.ctx_elements"), ctx$element_count),
        sprintf("%s: %d", i18n$t("ui.modals.feedback.ctx_connections"), ctx$connection_count),
        sprintf("%s: %s", i18n$t("ui.modals.feedback.ctx_browser"), ctx$browser_info),
        sep = "\n"
      )
    )
  })

  # Submit handler
  observeEvent(input$feedback_submit, {
    # Disable button immediately
    shinyjs::disable("feedback_submit")

    # Server-side rate limit
    if (!is.null(last_submit_time()) &&
        difftime(Sys.time(), last_submit_time(), units = "secs") < 30) {
      showNotification(i18n$t("ui.modals.feedback.rate_limited"), type = "warning")
      shinyjs::enable("feedback_submit")
      return()
    }

    # Validate
    title <- trimws(input$feedback_title %||% "")
    desc <- trimws(input$feedback_description %||% "")

    if (nchar(title) == 0) {
      showNotification(i18n$t("ui.modals.feedback.error_empty_title"), type = "error")
      shinyjs::enable("feedback_submit")
      return()
    }
    if (nchar(desc) == 0) {
      showNotification(i18n$t("ui.modals.feedback.error_empty_desc"), type = "error")
      shinyjs::enable("feedback_submit")
      return()
    }

    # Enforce server-side length limits
    title <- substr(title, 1, 200)
    desc <- substr(desc, 1, 5000)
    steps <- substr(trimws(input$feedback_steps %||% ""), 1, 2000)

    # Collect context
    pd <- if (!is.null(project_data)) {
      tryCatch(isolate(project_data()), error = function(e) NULL)
    } else NULL
    ul <- if (!is.null(user_level)) tryCatch(isolate(user_level()), error = function(e) "unknown") else "unknown"
    lang <- tryCatch(i18n$get_translation_language(), error = function(e) "en")
    ctx <- collect_system_context(session, input, pd, user_level = ul, language = lang)

    # Submit
    result <- submit_feedback(title, desc, input$feedback_type, steps, ctx)

    # Update rate limit
    last_submit_time(Sys.time())

    # Show result — 3-way check: both failed, github success, or local-only success
    if (!result$local_success && !result$github_success) {
      showNotification(i18n$t("ui.modals.feedback.error_save_failed"), type = "error", duration = 8)
    } else if (result$github_success) {
      showNotification(
        tagList(
          i18n$t("ui.modals.feedback.success_github"),
          if (!is.null(result$github_url)) tags$a(href = result$github_url, target = "_blank", i18n$t("common.buttons.view"))
        ),
        type = "message", duration = 8
      )
    } else {
      if (!result$github_success && nchar(Sys.getenv("MARINESABRES_GITHUB_TOKEN", "")) > 0) {
        showNotification(i18n$t("ui.modals.feedback.github_failed"), type = "warning", duration = 8)
      }
      showNotification(i18n$t("ui.modals.feedback.success_local"), type = "message", duration = 5)
    }

    # Close modal
    removeModal()

    # Re-enable after 30s (for if user reopens modal)
    shinyjs::delay(30000, shinyjs::enable("feedback_submit"))
  })
}
