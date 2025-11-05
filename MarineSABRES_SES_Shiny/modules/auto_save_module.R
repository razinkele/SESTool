# modules/auto_save_module.R
# Auto-save functionality to prevent data loss
# Implements 30-second interval saves with localStorage backup and session recovery

# UI Component - Save Indicator
auto_save_indicator_ui <- function(id) {
  ns <- NS(id)

  tags$div(
    id = ns("save_indicator_container"),
    class = "auto-save-indicator",
    style = "position: fixed; bottom: 20px; right: 20px; z-index: 9999;",

    # CSS for the indicator
    tags$style(HTML("
      .auto-save-indicator {
        background: white;
        border: 1px solid #ddd;
        border-radius: 8px;
        padding: 10px 15px;
        box-shadow: 0 2px 8px rgba(0,0,0,0.1);
        transition: all 0.3s ease;
      }

      .auto-save-indicator.saving {
        background: #fff3cd;
        border-color: #ffc107;
      }

      .auto-save-indicator.saved {
        background: #d4edda;
        border-color: #28a745;
      }

      .auto-save-indicator.error {
        background: #f8d7da;
        border-color: #dc3545;
      }

      .save-status-icon {
        margin-right: 8px;
        font-size: 16px;
      }

      .save-status-text {
        font-size: 13px;
        color: #333;
      }

      .save-status-time {
        font-size: 11px;
        color: #666;
        margin-top: 3px;
      }
    ")),

    # Save indicator content
    div(
      class = "save-indicator-content",
      span(class = "save-status-icon", id = ns("status_icon")),
      span(class = "save-status-text", id = ns("status_text"), "Initializing..."),
      div(class = "save-status-time", id = ns("status_time"), "")
    )
  )
}

# Server Function
auto_save_server <- function(id, project_data_reactive, i18n) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # Reactive values for auto-save state
    auto_save <- reactiveValues(
      last_save_time = NULL,
      save_status = "initialized",  # initialized, saving, saved, error
      error_message = NULL,
      save_count = 0,
      is_enabled = TRUE
    )

    # Get temp directory for auto-saves
    temp_dir <- file.path(tempdir(), "marinesabres_autosave")
    if (!dir.exists(temp_dir)) {
      dir.create(temp_dir, recursive = TRUE)
    }

    # Function to generate unique session ID
    session_id <- paste0("session_", format(Sys.time(), "%Y%m%d_%H%M%S"), "_",
                        sample(1000:9999, 1))

    # Function to perform auto-save
    perform_auto_save <- function() {
      if (!auto_save$is_enabled) return()

      tryCatch({
        # Update status to saving
        auto_save$save_status <- "saving"
        updateSaveIndicator()

        # Get current project data
        current_data <- project_data_reactive()

        if (is.null(current_data) || length(current_data) == 0) {
          # No data to save yet
          auto_save$save_status <- "initialized"
          updateSaveIndicator()
          return()
        }

        # Add auto-save metadata
        current_data$autosave_metadata <- list(
          session_id = session_id,
          save_time = Sys.time(),
          save_count = auto_save$save_count + 1,
          version = "1.4.0"
        )

        # Save to temp directory
        save_file <- file.path(temp_dir, paste0(session_id, ".rds"))
        saveRDS(current_data, save_file)

        # Also save as "latest" for easy recovery
        latest_file <- file.path(temp_dir, "latest_autosave.rds")
        saveRDS(current_data, latest_file)

        # Save to localStorage via JavaScript (as JSON backup)
        json_data <- jsonlite::toJSON(current_data, auto_unbox = TRUE, null = "null")
        session$sendCustomMessage(
          type = "autosave_to_localstorage",
          message = list(
            session_id = session_id,
            data = as.character(json_data),
            timestamp = as.numeric(Sys.time())
          )
        )

        # Update status to saved
        auto_save$save_status <- "saved"
        auto_save$last_save_time <- Sys.time()
        auto_save$save_count <- auto_save$save_count + 1
        updateSaveIndicator()

        # Log save event
        cat(sprintf("[AUTO-SAVE] Saved at %s (Count: %d)\n",
                   format(Sys.time(), "%H:%M:%S"),
                   auto_save$save_count))

      }, error = function(e) {
        auto_save$save_status <- "error"
        auto_save$error_message <- e$message
        updateSaveIndicator()
        cat(sprintf("[AUTO-SAVE ERROR] %s\n", e$message))
      })
    }

    # Function to update save indicator UI
    updateSaveIndicator <- function() {
      status <- auto_save$save_status

      # Determine icon and text based on status
      if (status == "saving") {
        icon <- "🔄"
        text <- i18n$t("Saving...")
        time_text <- ""
      } else if (status == "saved") {
        icon <- "✓"
        text <- i18n$t("All changes saved")

        if (!is.null(auto_save$last_save_time)) {
          time_diff <- as.numeric(difftime(Sys.time(), auto_save$last_save_time, units = "secs"))

          if (time_diff < 60) {
            time_text <- sprintf(i18n$t("Last saved: %d seconds ago"), round(time_diff))
          } else if (time_diff < 3600) {
            time_text <- sprintf(i18n$t("Last saved: %d minutes ago"), round(time_diff / 60))
          } else {
            time_text <- format(auto_save$last_save_time, "%H:%M:%S")
          }
        } else {
          time_text <- ""
        }
      } else if (status == "error") {
        icon <- "⚠"
        text <- i18n$t("Save failed")
        time_text <- auto_save$error_message
      } else {
        icon <- "💾"
        text <- i18n$t("Auto-save enabled")
        time_text <- ""
      }

      # Update UI via JavaScript
      session$sendCustomMessage(
        type = "update_save_indicator",
        message = list(
          icon = icon,
          text = text,
          time = time_text,
          status = status
        )
      )
    }

    # Auto-save timer - triggers every 30 seconds
    observe({
      invalidateLater(30000)  # 30 seconds
      perform_auto_save()
    })

    # Also save on any data change (debounced)
    observeEvent(project_data_reactive(), {
      # Debounce: only save if last save was > 5 seconds ago
      if (!is.null(auto_save$last_save_time)) {
        time_since_save <- as.numeric(difftime(Sys.time(), auto_save$last_save_time, units = "secs"))
        if (time_since_save < 5) {
          return()
        }
      }
      perform_auto_save()
    }, ignoreInit = TRUE)

    # Update indicator display every 10 seconds
    observe({
      invalidateLater(10000)  # 10 seconds
      if (auto_save$save_status == "saved") {
        updateSaveIndicator()
      }
    })

    # Check for recoverable session on startup
    check_for_recovery <- function() {
      latest_file <- file.path(temp_dir, "latest_autosave.rds")

      if (file.exists(latest_file)) {
        # Get file modification time
        file_time <- file.mtime(latest_file)
        time_diff <- as.numeric(difftime(Sys.time(), file_time, units = "hours"))

        # Only offer recovery if file is less than 24 hours old
        if (time_diff < 24) {
          # Show recovery modal
          showModal(modalDialog(
            title = tags$h4(icon("exclamation-triangle"), " ",
                          i18n$t("Unsaved Work Detected")),
            size = "m",
            easyClose = FALSE,

            tags$div(
              style = "padding: 15px;",
              tags$p(
                i18n$t("We found an auto-saved version of your work from"),
                " ",
                tags$strong(format(file_time, "%Y-%m-%d %H:%M:%S"))
              ),
              tags$p(
                i18n$t("Would you like to recover this data?")
              ),
              tags$br(),
              tags$p(
                style = "font-size: 12px; color: #666;",
                icon("info-circle"), " ",
                i18n$t("Auto-save helps prevent data loss from unexpected disconnections.")
              )
            ),

            footer = tagList(
              actionButton(ns("discard_recovery"),
                         i18n$t("Start Fresh"),
                         class = "btn-default"),
              actionButton(ns("confirm_recovery"),
                         i18n$t("Recover Data"),
                         class = "btn-primary",
                         icon = icon("history"))
            )
          ))
        }
      }
    }

    # Handle recovery confirmation
    observeEvent(input$confirm_recovery, {
      latest_file <- file.path(temp_dir, "latest_autosave.rds")

      tryCatch({
        recovered_data <- readRDS(latest_file)

        # Remove auto-save metadata before returning
        recovered_data$autosave_metadata <- NULL

        # Update the project data
        # This assumes project_data_reactive is a reactiveVal that can be updated
        # You'll need to adjust this based on your actual implementation
        showNotification(
          i18n$t("Data recovered successfully!"),
          type = "message",
          duration = 5
        )

        removeModal()

        # Return recovered data (you'll need to handle this in your main app)
        session$userData$recovered_data <- recovered_data

      }, error = function(e) {
        showNotification(
          paste(i18n$t("Recovery failed:"), e$message),
          type = "error",
          duration = 10
        )
      })
    })

    # Handle recovery dismissal
    observeEvent(input$discard_recovery, {
      removeModal()
      # Delete the recovery file
      latest_file <- file.path(temp_dir, "latest_autosave.rds")
      if (file.exists(latest_file)) {
        file.remove(latest_file)
      }
    })

    # Initialize - check for recovery on module load
    isolate({
      check_for_recovery()
    })

    # Return control functions
    list(
      enable_autosave = function() {
        auto_save$is_enabled <- TRUE
      },
      disable_autosave = function() {
        auto_save$is_enabled <- FALSE
      },
      force_save = function() {
        perform_auto_save()
      },
      get_save_count = function() {
        auto_save$save_count
      }
    )
  })
}

# JavaScript handlers for localStorage and UI updates
auto_save_js <- function() {
  tags$script(HTML("
    // Handle auto-save to localStorage
    Shiny.addCustomMessageHandler('autosave_to_localstorage', function(message) {
      try {
        localStorage.setItem('marinesabres_autosave_session', message.session_id);
        localStorage.setItem('marinesabres_autosave_data', message.data);
        localStorage.setItem('marinesabres_autosave_timestamp', message.timestamp);
        console.log('[AUTO-SAVE] Saved to localStorage at', new Date(message.timestamp * 1000));
      } catch(e) {
        console.error('[AUTO-SAVE] localStorage save failed:', e);
      }
    });

    // Handle save indicator updates
    Shiny.addCustomMessageHandler('update_save_indicator', function(message) {
      $('#status_icon').text(message.icon);
      $('#status_text').text(message.text);
      $('#status_time').text(message.time);

      // Update indicator styling
      var container = $('.auto-save-indicator');
      container.removeClass('saving saved error');

      if (message.status === 'saving') {
        container.addClass('saving');
      } else if (message.status === 'saved') {
        container.addClass('saved');
      } else if (message.status === 'error') {
        container.addClass('error');
      }
    });

    // Clear localStorage on explicit user logout/close
    window.addEventListener('beforeunload', function(e) {
      // Note: Don't clear here - we want to keep the backup
      // localStorage will be cleared only on successful recovery or user choice
    });
  "))
}
