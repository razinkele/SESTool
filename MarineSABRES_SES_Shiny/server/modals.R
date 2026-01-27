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

    # Log language change
    cat(paste0("[", Sys.time(), "] INFO: Language changed to: ", new_lang, "\n"))

    # Close the modal first
    removeModal()

    # Show loading overlay with translated message
    loading_messages <- list(
      en = "Changing Language",
      es = "Cambiando Idioma",
      fr = "Changement de Langue",
      de = "Sprache Ändern",
      lt = "Keičiama Kalba",
      pt = "Mudando Idioma",
      it = "Cambio Lingua",
      no = "Endrer Språk"
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
          cat(paste0("[", Sys.time(), "] INFO: Project data saved before language change reload\n"))
        }
      }, error = function(e) {
        cat(paste0("[", Sys.time(), "] WARNING: Could not save project data before reload: ", e$message, "\n"))
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

  # Set up shinyFiles directory chooser for SES models directory
  if (!is.null(volumes)) {
    shinyDirChoose(input, "ses_models_dir_select", roots = volumes, session = session)
  }

  # Handle directory selection from shinyDirButton
  observeEvent(input$ses_models_dir_select, {
    req(input$ses_models_dir_select)

    # Check if a directory was actually selected (not just initialized)
    if (!is.integer(input$ses_models_dir_select) && !is.null(volumes)) {
      # Parse the selected path
      selected_path <- parseDirPath(volumes, input$ses_models_dir_select)

      if (length(selected_path) > 0 && nzchar(selected_path)) {
        # Update the text input with the selected path
        updateTextInput(session, "ses_models_custom_path", value = as.character(selected_path))
      }
    }
  })

  # Show settings modal when button is clicked
  observeEvent(input$open_settings_modal, {
    showModal(modalDialog(
      title = tags$h3(icon("cog"), " ", i18n$t("ui.header.application_settings")),
      size = "l",  # Changed to large for more content
      easyClose = TRUE,
      footer = tagList(
        modalButton(i18n$t("common.buttons.cancel")),
        actionButton("apply_settings", i18n$t("common.buttons.apply"), class = "btn-primary", icon = icon("check"))
      ),

      tags$div(
        style = "padding: 20px;",

        # ========== AUTO-SAVE SECTION ==========
        tags$h4(icon("save"), " Auto-Save Settings"),
        tags$p(style = "color: #666; margin-bottom: 20px;",
          "Configure automatic saving behavior for the AI ISA Assistant module."
        ),

        # Main auto-save toggle
        shinyWidgets::switchInput(
          inputId = "autosave_enabled",
          label = tags$strong("Enable Auto-Save"),
          value = autosave_enabled(),
          onLabel = "ON",
          offLabel = "OFF",
          onStatus = "success",
          offStatus = "danger",
          size = "default",
          width = "100%"
        ),

        # Advanced options (conditional on autosave being enabled)
        conditionalPanel(
          condition = "input.autosave_enabled == true",

          tags$div(
            style = "margin-top: 20px; padding: 15px; background: #f8f9fa; border-radius: 5px;",

            tags$h5(icon("sliders-h"), " Advanced Auto-Save Options"),

            # Save interval
            tags$div(
              style = "margin-bottom: 15px;",
              tags$label(
                style = "font-weight: 600; margin-bottom: 5px; display: block;",
                icon("clock"), " Save Delay (seconds)"
              ),
              sliderInput(
                inputId = "autosave_delay",
                label = NULL,
                min = 1,
                max = 10,
                value = if (!is.null(autosave_delay)) autosave_delay() else 2,
                step = 0.5,
                width = "100%",
                ticks = TRUE
              ),
              tags$p(
                style = "font-size: 12px; color: #666; margin-top: -10px;",
                icon("info-circle"),
                " Delay before auto-save triggers after changes (prevents saving on every keystroke)"
              )
            ),

            # Notification settings
            tags$div(
              style = "margin-bottom: 15px;",
              tags$label(
                style = "font-weight: 600; margin-bottom: 10px; display: block;",
                icon("bell"), " Notifications"
              ),
              shinyWidgets::switchInput(
                inputId = "autosave_notifications",
                label = "Show save notifications",
                value = if (!is.null(autosave_notifications)) autosave_notifications() else FALSE,
                onLabel = "ON",
                offLabel = "OFF",
                onStatus = "info",
                offStatus = "secondary",
                size = "small",
                inline = TRUE
              ),
              tags$p(
                style = "font-size: 12px; color: #666; margin-top: 5px;",
                "Display a notification each time auto-save occurs (can be distracting)"
              )
            ),

            # Save indicator
            tags$div(
              style = "margin-bottom: 15px;",
              tags$label(
                style = "font-weight: 600; margin-bottom: 10px; display: block;",
                icon("check-circle"), " Visual Indicator"
              ),
              shinyWidgets::switchInput(
                inputId = "autosave_indicator",
                label = "Show save status indicator",
                value = if (!is.null(autosave_indicator)) autosave_indicator() else TRUE,
                onLabel = "ON",
                offLabel = "OFF",
                onStatus = "success",
                offStatus = "secondary",
                size = "small",
                inline = TRUE
              ),
              tags$p(
                style = "font-size: 12px; color: #666; margin-top: 5px;",
                "Display a small indicator showing when last auto-save occurred"
              )
            ),

            # What triggers autosave
            tags$div(
              style = "margin-bottom: 10px;",
              tags$label(
                style = "font-weight: 600; margin-bottom: 10px; display: block;",
                icon("sync"), " Auto-Save Triggers"
              ),
              checkboxGroupInput(
                inputId = "autosave_triggers",
                label = NULL,
                choices = list(
                  "Element added/modified" = "elements",
                  "Context changed (region, ecosystem)" = "context",
                  "Connections approved" = "connections",
                  "Step progression" = "steps"
                ),
                selected = if (!is.null(autosave_triggers)) autosave_triggers() else c("elements", "context", "connections", "steps"),
                width = "100%"
              ),
              tags$p(
                style = "font-size: 12px; color: #666; margin-top: -5px;",
                "Select which actions trigger auto-save"
              )
            )
          )
        ),

        # Info box
        tags$div(
          class = "alert alert-info",
          style = "margin-top: 20px;",
          icon("lightbulb"),
          tags$strong(" Tip: "),
          "Auto-save only works in the AI ISA Assistant module. Your work in other modules is saved manually using the Save Project button in the sidebar."
        ),

        tags$hr(),

        # ========== LOCAL STORAGE SETTINGS SECTION ==========
        tags$h4(icon("hdd"), " ", i18n$t("ui.modals.local_storage_settings")),
        
        tags$p(
          style = "color: #666; margin-bottom: 15px;",
          i18n$t("ui.modals.local_storage_description")
        ),
        
        # Connection status and controls
        tags$div(
          id = "local_storage_status_container",
          class = "local-storage-panel",
          
          # JavaScript-based rendering for File System API status
          tags$script(HTML("
            $(document).ready(function() {
              // Update local storage panel based on API availability
              function updateLocalStoragePanel() {
                var hasAPI = window.localStorageModule && window.localStorageModule.hasFileSystemAccess;
                var isConnected = window.localStorageModule && window.localStorageModule.directoryHandle !== null;
                
                if (!hasAPI) {
                  $('#local_storage_api_status').html(
                    '<div class=\"fallback-warning\" style=\"margin-bottom: 0;\">' +
                    '<i class=\"fa fa-exclamation-triangle\"></i> ' +
                    '<strong>Browser Not Fully Supported</strong><br>' +
                    '<small>Your browser does not support the File System Access API. ' +
                    'Please use Chrome, Edge, or Opera for direct folder access. ' +
                    'You can still use Download/Upload buttons to manually save and load projects.</small>' +
                    '</div>'
                  );
                  $('#local_storage_controls').hide();
                } else if (isConnected) {
                  var dirName = window.localStorageModule.directoryHandle.name;
                  $('#local_storage_api_status').html(
                    '<div class=\"directory-status connected\">' +
                    '<span class=\"directory-status-icon\">📁</span>' +
                    '<div><strong>Connected to:</strong> ' + dirName + '</div>' +
                    '</div>'
                  );
                  $('#btn_connect_local').hide();
                  $('#btn_disconnect_local').show();
                  $('#btn_save_to_local').show();
                  $('#local_storage_controls').show();
                } else {
                  $('#local_storage_api_status').html(
                    '<div class=\"directory-status\">' +
                    '<span class=\"directory-status-icon\">📂</span>' +
                    '<div>No folder selected. Click the button below to select a folder on your computer.</div>' +
                    '</div>'
                  );
                  $('#btn_connect_local').show();
                  $('#btn_disconnect_local').hide();
                  $('#btn_save_to_local').hide();
                  $('#local_storage_controls').show();
                }
              }
              
              // Initial update after a short delay
              setTimeout(updateLocalStoragePanel, 500);
              
              // Update when directory changes
              Shiny.addCustomMessageHandler('update_local_storage_panel', function(message) {
                updateLocalStoragePanel();
              });
            });
          ")),
          
          # Status display (updated by JavaScript)
          tags$div(id = "local_storage_api_status"),
          
          # Controls
          tags$div(
            id = "local_storage_controls",
            style = "margin-top: 15px;",
            
            # Connect button
            actionButton(
              inputId = "btn_connect_local",
              label = tagList(icon("folder-open"), " ", i18n$t("ui.modals.select_local_folder")),
              class = "btn-outline-primary",
              style = "margin-right: 10px;"
            ),
            
            # Disconnect button (hidden by default)
            actionButton(
              inputId = "btn_disconnect_local",
              label = tagList(icon("unlink"), " ", i18n$t("ui.modals.disconnect_local_folder")),
              class = "btn-outline-secondary",
              style = "display: none; margin-right: 10px;"
            ),
            
            # Save current project button (hidden by default)
            actionButton(
              inputId = "btn_save_to_local",
              label = tagList(icon("save"), " ", i18n$t("ui.modals.save_current_project")),
              class = "btn-success",
              style = "display: none;"
            )
          ),
          
          # Auto-save to local toggle (when connected)
          tags$div(
            id = "local_autosave_container",
            style = "margin-top: 15px; padding: 10px; background: #f0f7ff; border-radius: 6px; display: none;",
            
            shinyWidgets::switchInput(
              inputId = "local_autosave_enabled",
              label = i18n$t("ui.modals.auto_save_to_local"),
              value = FALSE,
              onLabel = "ON",
              offLabel = "OFF",
              onStatus = "success",
              offStatus = "secondary",
              size = "small",
              inline = TRUE
            ),
            tags$p(
              style = "font-size: 12px; color: #666; margin-top: 5px; margin-bottom: 0;",
              icon("info-circle"),
              " When enabled, changes will be automatically saved to your local folder in addition to server auto-save."
            )
          )
        ),

        tags$hr(),

        # ========== GENERAL SETTINGS SECTION ==========
        tags$h4(icon("tools"), " General Settings"),

        tags$div(
          style = "margin-top: 15px;",

          # Debug mode toggle
          shinyWidgets::switchInput(
            inputId = "debug_mode",
            label = tags$strong("Enable Debug Logging"),
            value = FALSE,
            onLabel = "ON",
            offLabel = "OFF",
            onStatus = "warning",
            offStatus = "secondary",
            size = "default",
            width = "100%"
          ),
          tags$p(
            style = "margin-top: 10px; font-size: 13px; color: #666;",
            icon("bug"),
            " Enable detailed logging to console (useful for troubleshooting, may slow down performance)"
          )
        ),

        tags$hr(),

        # ========== SES MODELS DIRECTORY SECTION ==========
        tags$h4(icon("folder-open"), " ", i18n$t("ui.modals.ses_models_directory")),

        tags$div(
          style = "margin-top: 15px;",

          # Directory source radio buttons
          radioButtons(
            inputId = "ses_models_source",
            label = i18n$t("ui.modals.ses_models_source_label"),
            choices = list(
              "Default (Application Directory)" = "default",
              "Custom Directory" = "custom"
            ),
            selected = if (!is.null(ses_models_directory) && !is.null(ses_models_directory()) && nzchar(ses_models_directory())) "custom" else "default",
            width = "100%"
          ),

          # Custom directory input (shown only when custom is selected)
          conditionalPanel(
            condition = "input.ses_models_source == 'custom'",
            tags$div(
              style = "margin-top: 10px; padding: 15px; background: #f8f9fa; border-radius: 8px;",
              fluidRow(
                column(9,
                  textInput(
                    inputId = "ses_models_custom_path",
                    label = i18n$t("ui.modals.ses_models_custom_path"),
                    value = if (!is.null(ses_models_directory)) ses_models_directory() else "",
                    width = "100%",
                    placeholder = i18n$t("ui.modals.ses_models_path_placeholder")
                  )
                ),
                column(3,
                  tags$div(style = "margin-top: 25px;",
                    shinyDirButton(
                      id = "ses_models_dir_select",
                      label = i18n$t("ui.modals.browse"),
                      title = i18n$t("ui.modals.select_ses_models_directory"),
                      icon = icon("folder-open"),
                      class = "btn-outline-primary"
                    )
                  )
                )
              ),
              tags$p(
                style = "font-size: 12px; color: #666; margin-top: 5px;",
                icon("info-circle"), " ",
                i18n$t("ui.modals.ses_models_directory_help")
              )
            )
          ),

          # Show current path info
          tags$div(
            id = "ses_models_path_info",
            style = "margin-top: 10px; padding: 10px; background: #e8f4f8; border-radius: 6px; font-size: 13px;",
            icon("check-circle", style = "color: #28a745;"), " ",
            tags$strong(i18n$t("ui.modals.current_directory")), ": ",
            tags$span(
              id = "current_ses_models_path",
              style = "font-family: monospace;",
              if (!is.null(ses_models_directory) && !is.null(ses_models_directory()) && nzchar(ses_models_directory()))
                ses_models_directory()
              else
                "SESModels (relative to app directory)"
            )
          )
        )
      )
    ))
  })

  # Handle Apply button click in settings modal
  observeEvent(input$apply_settings, {
    settings_changed <- FALSE

    # Update autosave setting
    if (!is.null(input$autosave_enabled)) {
      autosave_enabled(input$autosave_enabled)
      debug_log(sprintf("Auto-save %s", if(input$autosave_enabled) "enabled" else "disabled"), "SETTINGS")
      settings_changed <- TRUE
    }

    # Store advanced autosave settings
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

    # Debug mode
    if (!is.null(input$debug_mode)) {
      debug_log(sprintf("Debug mode %s", if(input$debug_mode) "enabled" else "disabled"), "SETTINGS")
      # Set environment variable for debug logging
      if (input$debug_mode) {
        Sys.setenv(MARINESABRES_DEBUG = "TRUE")
      } else {
        Sys.setenv(MARINESABRES_DEBUG = "FALSE")
      }
    }

    # SES Models directory
    if (!is.null(ses_models_directory) && !is.null(input$ses_models_source)) {
      if (input$ses_models_source == "default") {
        # Reset to default (empty string means use default)
        ses_models_directory("")
        debug_log("SES Models directory reset to default", "SETTINGS")
        settings_changed <- TRUE
      } else if (input$ses_models_source == "custom" && !is.null(input$ses_models_custom_path)) {
        custom_path <- input$ses_models_custom_path
        if (nzchar(custom_path)) {
          # Validate the directory exists
          if (dir.exists(custom_path)) {
            ses_models_directory(custom_path)
            debug_log(sprintf("SES Models directory set to: %s", custom_path), "SETTINGS")
            settings_changed <- TRUE

            # Clear the models cache to force rescan with new directory
            if (exists(".ses_models_cache", envir = globalenv())) {
              .ses_models_cache$models <- NULL
              .ses_models_cache$last_scan <- NULL
            }
          } else {
            showNotification(
              paste(i18n$t("ui.modals.directory_not_found"), custom_path),
              type = "error",
              duration = 5
            )
          }
        }
      }
    }

    removeModal()

    if (settings_changed || !is.null(input$autosave_delay)) {
      showNotification(
        i18n$t("ui.modals.settings_updated_successfully"),
        type = "message",
        duration = 3
      )
    }
  })

  # ========== LOCAL STORAGE BUTTON HANDLERS ==========
  
  # Handle connect button - request directory access via JavaScript
  observeEvent(input$btn_connect_local, {
    # Send message to JavaScript to request directory access
    session$sendCustomMessage("request_directory_access", list())
  })
  
  # Handle disconnect button
  observeEvent(input$btn_disconnect_local, {
    # Send message to JavaScript to clear directory handle
    session$sendCustomMessage("clear_directory_handle", list())
    # Update panel display
    session$sendCustomMessage("update_local_storage_panel", list())
  })
  
  # Handle save to local button
  observeEvent(input$btn_save_to_local, {
    # Send message to JavaScript to save project
    # The actual save is handled by the local_storage_module
    session$sendCustomMessage("trigger_local_save", list())
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
# USER LEVEL MODAL
# ============================================================================

#' Setup User Level Modal Handlers
#'
#' @param input Shiny input object
#' @param output Shiny output object
#' @param session Shiny session object
#' @param user_level reactiveVal for user experience level
#' @param i18n shiny.i18n translator object
setup_user_level_modal_handlers <- function(input, output, session, user_level, i18n) {

  # Show user level modal
  observeEvent(input$open_user_level_modal, {
    showModal(modalDialog(
      title = tags$h3(icon("user-cog"), " ", i18n$t("ui.header.user_experience_level")),
      size = "m",
      easyClose = FALSE,

      tags$div(
        style = "padding: 10px;",

        tags$p(
          style = "margin-bottom: 20px; font-size: 14px;",
          i18n$t("ui.modals.select_your_experience_level_with_marine_ecosystem_modeling")
        ),

        # Single radio button group with all choices
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
          selected = user_level(),
          width = "100%"
        ),

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

  # Apply user level changes
  observeEvent(input$apply_user_level, {
    req(input$user_level_selector)

    new_level <- input$user_level_selector

    # Log the change
    cat(sprintf("[USER-LEVEL] Changing from %s to %s\n", user_level(), new_level))

    # Save to localStorage and reload via JavaScript
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
              i18n$t("Beginner's Quick Start"),
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
    version_info <- jsonlite::fromJSON("VERSION_INFO.json")

    showModal(modalDialog(
      title = tags$h3(icon("info-circle"), " About MarineSABRES SES Toolbox"),
      size = "l",
      easyClose = TRUE,
      footer = modalButton(i18n$t("common.buttons.close")),

      tags$div(
        style = "padding: 20px;",

        # Application Info
        tags$div(
          class = "well",
          tags$h4(icon("cube"), " Application Information"),
          tags$table(
            class = "table table-condensed",
            style = "margin-bottom: 0;",
            tags$tr(
              tags$td(tags$strong("Version:")),
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
              tags$td(tags$strong("Release Name:")),
              tags$td(version_info$version_name)
            ),
            tags$tr(
              tags$td(tags$strong("Release Date:")),
              tags$td(version_info$release_date)
            ),
            tags$tr(
              tags$td(tags$strong("Release Type:")),
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
          tags$h4(icon("star"), " Key Features"),
          tags$ul(
            lapply(version_info$features, function(feature) {
              tags$li(feature)
            })
          )
        ),

        # Technical Info
        tags$div(
          class = "well",
          tags$h4(icon("cogs"), " Technical Information"),
          tags$table(
            class = "table table-condensed",
            style = "margin-bottom: 0;",
            tags$tr(
              tags$td(tags$strong("Minimum R Version:")),
              tags$td(version_info$minimum_r_version)
            ),
            tags$tr(
              tags$td(tags$strong("Current R Version:")),
              tags$td(paste(R.version$major, R.version$minor, sep = "."))
            ),
            tags$tr(
              tags$td(tags$strong("Platform:")),
              tags$td(R.version$platform)
            ),
            tags$tr(
              tags$td(tags$strong("Git Branch:")),
              tags$td(version_info$build_info$git_branch)
            )
          )
        ),

        # Contributors
        tags$div(
          class = "well",
          tags$h4(icon("users"), " Contributors"),
          tags$ul(
            lapply(version_info$contributors, function(contributor) {
              tags$li(contributor)
            })
          )
        ),

        # Links
        tags$div(
          class = "alert alert-info",
          icon("book"),
          tags$strong(" Documentation: "),
          tags$a(
            href = "#",
            onclick = "window.open('user_guide.html', '_blank'); return false;",
            "Quick Guide",
            style = "margin-right: 15px;"
          ),
          tags$a(
            href = "#",
            onclick = "window.open('docs/MarineSABRES_User_Manual_EN.html', '_blank'); return false;",
            "📘 Manual (EN HTML)",
            style = "margin-right: 15px;",
            title = "Comprehensive 75-page English manual - HTML version"
          ),
          tags$a(
            href = "#",
            onclick = "window.open('docs/MarineSABRES_User_Manual_EN.pdf', '_blank'); return false;",
            "📕 Manual (EN PDF)",
            style = "margin-right: 15px;",
            title = "Comprehensive 75-page English manual - PDF version"
          ),
          tags$a(
            href = "#",
            onclick = "window.open('docs/MarineSABRES_User_Manual_FR.html', '_blank'); return false;",
            "📗 Manuel (FR HTML)",
            style = "margin-right: 15px;",
            title = "Manuel français complet de 75 pages - version HTML"
          ),
          tags$a(
            href = "#",
            onclick = "window.open('docs/MarineSABRES_User_Manual_FR.pdf', '_blank'); return false;",
            "📙 Manuel (FR PDF)",
            style = "margin-right: 15px;",
            title = "Manuel français complet de 75 pages - version PDF"
          ),
          tags$a(
            href = "#",
            onclick = sprintf("window.open('%s', '_blank'); return false;", version_info$changelog_url),
            "Changelog"
          )
        )
      )
    ))
  })
}
