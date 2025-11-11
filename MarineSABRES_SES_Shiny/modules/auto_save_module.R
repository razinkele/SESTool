# modules/auto_save_module.R
# Auto-save functionality to prevent data loss
# Implements 30-second interval saves with localStorage backup and session recovery

# UI Component - Save Indicator
auto_save_indicator_ui <- function(id) {
  ns <- NS(id)

  tagList(
    # JavaScript handlers
    tags$script(HTML(sprintf("
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
        $('#%s').text(message.icon);
        $('#%s').text(message.text);
        $('#%s').text(message.time);

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

      // Handle page reload after recovery
      Shiny.addCustomMessageHandler('reload_page', function(message) {
        console.log('[AUTO-SAVE] Reloading page in ' + message.delay + 'ms...');
        setTimeout(function() {
          location.reload();
        }, message.delay);
      });
    ", ns("status_icon"), ns("status_text"), ns("status_time")))),

    # Save indicator div
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
      is_enabled = TRUE,
      recovery_pending = FALSE,  # Prevents auto-save until user handles recovery modal
      data_dirty = FALSE,  # Track if data has changed since last save
      last_data_hash = NULL  # Hash of last saved data to detect changes
    )

    # Get temp directory for auto-saves
    temp_dir <- file.path(tempdir(), "marinesabres_autosave")
    if (!dir.exists(temp_dir)) {
      dir.create(temp_dir, recursive = TRUE)
    }

    # Debug: log temp directory location
    cat(sprintf("[AUTO-SAVE] Using temp directory: %s\n", temp_dir))

    # Function to generate unique session ID
    session_id <- paste0("session_", format(Sys.time(), "%Y%m%d_%H%M%S"), "_",
                        sample(1000:9999, 1))

    # Function to perform auto-save
    perform_auto_save <- function() {
      if (!auto_save$is_enabled) return()

      # CRITICAL: Don't auto-save if recovery modal is pending
      # This prevents overwriting the good recovery file with empty data
      if (auto_save$recovery_pending) {
        cat("[AUTO-SAVE] Skipping auto-save - recovery modal pending\n")
        return()
      }

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

        # Debug: log what we're about to save
        if (!is.null(current_data$data) && !is.null(current_data$data$isa_data)) {
          isa <- current_data$data$isa_data
          cat(sprintf("[AUTO-SAVE] Saving ISA data with %d element types\n", length(isa)))
          if (length(isa) > 0) {
            for (name in names(isa)) {
              if (is.data.frame(isa[[name]])) {
                cat(sprintf("[AUTO-SAVE]   %s: %d rows\n", name, nrow(isa[[name]])))
              }
            }
          } else {
            cat("[AUTO-SAVE]   isa_data is EMPTY list\n")
          }
        } else {
          cat("[AUTO-SAVE] WARNING: isa_data is NULL or missing\n")
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

        # Update hash and clear dirty flag after successful save
        auto_save$last_data_hash <- digest::digest(current_data)
        auto_save$data_dirty <- FALSE

        updateSaveIndicator()

        # Log save event
        cat(sprintf("[AUTO-SAVE] Saved at %s (Count: %d) - data now clean\n",
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

    # Auto-save timer - checks every 30 seconds, only saves if data changed
    observe({
      invalidateLater(30000)  # 30 seconds
      isolate({
        # Only save if data has changed since last save
        if (auto_save$data_dirty && auto_save$is_enabled && !auto_save$recovery_pending) {
          perform_auto_save()
        }
      })
    })

    # Mark data as dirty when project_data changes (no infinite loop - just sets flag)
    observeEvent(project_data_reactive(), {
      data <- project_data_reactive()

      # Calculate hash of current data
      if (!is.null(data)) {
        current_hash <- digest::digest(data)

        # Only mark dirty if hash has changed
        if (is.null(auto_save$last_data_hash) || current_hash != auto_save$last_data_hash) {
          auto_save$data_dirty <- TRUE
          cat(sprintf("[AUTO-SAVE] Data changed, marked as dirty\n"))

          # Immediate save on first data load (when last_data_hash is NULL)
          if (is.null(auto_save$last_data_hash)) {
            cat("[AUTO-SAVE] First data detected - performing immediate save\n")
            perform_auto_save()
          }
        }
      }
    })

    # Update indicator display every 10 seconds
    observe({
      invalidateLater(10000)  # 10 seconds
      isolate({
        if (auto_save$save_status == "saved") {
          updateSaveIndicator()
        }
      })
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
          # CRITICAL: Set flag to prevent auto-save from overwriting recovery file
          auto_save$recovery_pending <- TRUE
          cat("[AUTO-SAVE] Recovery file found - blocking auto-save until user decision\n")

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
      # Clear recovery pending flag to allow auto-save to resume
      auto_save$recovery_pending <- FALSE
      cat("[AUTO-SAVE] Recovery confirmed - auto-save will resume after page reload\n")

      latest_file <- file.path(temp_dir, "latest_autosave.rds")

      tryCatch({
        recovered_data <- readRDS(latest_file)

        # Remove auto-save metadata before returning
        recovered_data$autosave_metadata <- NULL

        # Update the project data reactiveVal
        project_data_reactive(recovered_data)

        # Log recovery
        cat(sprintf("[AUTO-SAVE] Data recovered from %s\n", latest_file))

        # Count total elements across all categories (use nrow for dataframes)
        total_recovered <- sum(
          nrow(recovered_data$data$isa_data$drivers %||% data.frame()),
          nrow(recovered_data$data$isa_data$activities %||% data.frame()),
          nrow(recovered_data$data$isa_data$pressures %||% data.frame()),
          nrow(recovered_data$data$isa_data$marine_processes %||% data.frame()),
          nrow(recovered_data$data$isa_data$ecosystem_services %||% data.frame()),
          nrow(recovered_data$data$isa_data$goods_benefits %||% data.frame()),
          nrow(recovered_data$data$isa_data$responses %||% data.frame()),
          nrow(recovered_data$data$isa_data$measures %||% data.frame())
        )
        cat(sprintf("[AUTO-SAVE] Recovered %d total elements\n", total_recovered))

        # Delete the recovery file to prevent infinite loop on reload
        if (file.exists(latest_file)) {
          file.remove(latest_file)
          cat("[AUTO-SAVE] Recovery file deleted to prevent loop\n")
        }

        showNotification(
          i18n$t("Data recovered successfully!"),
          type = "message",
          duration = 3
        )

        removeModal()

        # NOTE: No page reload needed! Data is already in project_data_reactive()
        # and all module observers have already detected and loaded it.
        # Page reload would destroy the session we just recovered!

      }, error = function(e) {
        cat(sprintf("[AUTO-SAVE ERROR] Recovery failed: %s\n", e$message))
        showNotification(
          paste(i18n$t("Recovery failed:"), e$message),
          type = "error",
          duration = 10
        )
      })
    })

    # Handle recovery dismissal
    observeEvent(input$discard_recovery, {
      # Clear recovery pending flag to allow auto-save to resume
      auto_save$recovery_pending <- FALSE
      cat("[AUTO-SAVE] Recovery discarded - auto-save resumed\n")

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

