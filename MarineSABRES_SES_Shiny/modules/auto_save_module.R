# modules/auto_save_module.R
# Auto-save functionality to prevent data loss
# Implements 30-second interval saves with localStorage backup and session recovery

# UI Component - Save Indicator
auto_save_indicator_ui <- function(id) {
  ns <- NS(id)

  tagList(
    # Use i18n for language support
    # REMOVED: usei18n() - only called once in main UI (app.R)

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

        // Control visibility based on setting
        if (message.visible === false) {
          container.hide();
        } else {
          container.show();
        }
      });

      // Handle editing mode indicator updates with toggle support
      Shiny.addCustomMessageHandler('update_editing_mode', function(message) {
        var modeBadge = $('#%s');
        var modeText = $('#%s');

        // Track if badge was previously hidden (for tutorial trigger)
        var wasHidden = modeBadge.hasClass('mode-hidden');

        // Store labels in data attributes for toggle functionality
        modeBadge.data('label-short', message.mode_label_short);
        modeBadge.data('label-full', message.mode_label_full);
        modeBadge.data('change-count', message.change_count);

        // Get current expanded state from localStorage (defaults to false/collapsed)
        var isExpanded = localStorage.getItem('marinesabres_mode_badge_expanded') === 'true';

        // Update text based on expanded state
        if (isExpanded) {
          modeText.text(message.mode_label_full);
          modeBadge.addClass('expanded');
        } else {
          modeText.text(message.mode_label_short);
          modeBadge.removeClass('expanded');
        }

        // Update badge styling
        modeBadge.removeClass('mode-casual mode-rapid mode-hidden');

        if (message.mode === 'casual') {
          modeBadge.addClass('mode-casual');
        } else if (message.mode === 'rapid') {
          modeBadge.addClass('mode-rapid');
        }

        // Show/hide badge
        if (message.show) {
          modeBadge.removeClass('mode-hidden');

          // Trigger generic tutorial if this is the first time badge appears
          if (wasHidden && message.show_tutorial) {
            Shiny.setInputValue('%s', Math.random(), {priority: 'event'});
          }
        } else {
          modeBadge.addClass('mode-hidden');
        }

        console.log('[AUTO-SAVE] Mode indicator updated:', message.mode,
                   isExpanded ? message.mode_label_full : message.mode_label_short);
      });

      // Toggle badge between expanded and collapsed on click
      $(document).on('click', '#%s', function(e) {
        e.preventDefault();
        e.stopPropagation();

        var badge = $(this);
        var modeText = badge.find('#%s');
        var isExpanded = badge.hasClass('expanded');

        // Toggle state
        if (isExpanded) {
          // Collapse
          modeText.text(badge.data('label-short'));
          badge.removeClass('expanded');
          localStorage.setItem('marinesabres_mode_badge_expanded', 'false');
          console.log('[AUTO-SAVE] Mode badge collapsed');
        } else {
          // Expand
          modeText.text(badge.data('label-full'));
          badge.addClass('expanded');
          localStorage.setItem('marinesabres_mode_badge_expanded', 'true');
          console.log('[AUTO-SAVE] Mode badge expanded');
        }
      });

      // Handle page reload after recovery
      Shiny.addCustomMessageHandler('reload_page', function(message) {
        console.log('[AUTO-SAVE] Reloading page in ' + message.delay + 'ms...');
        setTimeout(function() {
          location.reload();
        }, message.delay);
      });
    ", ns("status_icon"), ns("status_text"), ns("status_time"),
       ns("mode_badge"), ns("mode_text"), ns("show_mode_tutorial"),
       ns("mode_badge"), ns("mode_text")))),

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

        /* Editing mode badge - clickable and toggleable */
        .editing-mode-badge {
          display: inline-block;
          padding: 2px 8px;
          border-radius: 12px;
          font-size: 10px;
          font-weight: 600;
          text-transform: uppercase;
          margin-left: 8px;
          transition: all 0.3s ease;
          vertical-align: middle;
          cursor: pointer;
          user-select: none;
          white-space: nowrap;
        }

        /* Collapsed state (compact) */
        .editing-mode-badge {
          min-width: 35px;
          text-align: center;
        }

        /* Expanded state (shows full details) */
        .editing-mode-badge.expanded {
          min-width: auto;
          padding: 2px 10px;
        }

        .editing-mode-badge.mode-casual {
          background: #d1ecf1;
          color: #0c5460;
          border: 1px solid #bee5eb;
        }

        .editing-mode-badge.mode-rapid {
          background: #fff3cd;
          color: #856404;
          border: 1px solid #ffeaa7;
          animation: pulse-rapid 2s ease-in-out infinite;
        }

        .editing-mode-badge.mode-hidden {
          display: none;
        }

        /* Pulse animation for rapid mode */
        @keyframes pulse-rapid {
          0%, 100% {
            opacity: 1;
            transform: scale(1);
          }
          50% {
            opacity: 0.8;
            transform: scale(1.05);
          }
        }

        /* Hover effects */
        .editing-mode-badge:hover {
          opacity: 0.85;
          transform: scale(1.05);
        }

        /* Active/click effect */
        .editing-mode-badge:active {
          transform: scale(0.95);
        }

        /* Visual feedback for clickability */
        .editing-mode-badge::before {
          content: '';
          position: absolute;
          top: 0;
          left: 0;
          right: 0;
          bottom: 0;
          border-radius: 12px;
          background: rgba(255, 255, 255, 0.2);
          opacity: 0;
          transition: opacity 0.2s ease;
        }

        .editing-mode-badge:hover::before {
          opacity: 1;
        }

        /* Tooltip update for clickable badge */
        .editing-mode-badge {
          position: relative;
        }
      ")),

      # Save indicator content
      div(
        class = "save-indicator-content",
        div(
          style = "display: flex; align-items: center; justify-content: space-between;",
          div(
            span(class = "save-status-icon", id = ns("status_icon")),
            span(class = "save-status-text", id = ns("status_text"), "Initializing...")
          ),
          # Editing mode badge (clickable to toggle details)
          span(
            class = "editing-mode-badge mode-hidden",
            id = ns("mode_badge"),
            title = "Click to toggle details • Adaptive auto-save: adjusts delay based on editing speed",
            span(id = ns("mode_text"), "")
          )
        ),
        div(class = "save-status-time", id = ns("status_time"), "")
      )
    )
  )
}

# Server Function
auto_save_server <- function(id, project_data_reactive, i18n,
                             autosave_enabled_reactive = NULL,
                             event_bus = NULL,
                             autosave_delay_reactive = NULL,
                             autosave_notifications_reactive = NULL,
                             autosave_indicator_reactive = NULL,
                             autosave_triggers_reactive = NULL) {
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
      last_data_hash = NULL,  # Hash of last saved data to detect changes

      # Adaptive debouncing - track editing patterns
      change_timestamps = list(),  # List of recent change timestamps
      editing_mode = "casual",     # "casual" or "rapid"
      current_debounce_ms = AUTOSAVE_DEBOUNCE_CASUAL_MS,  # Current debounce delay

      # Tutorial state
      tutorial_triggered = FALSE,  # Track if tutorial has been triggered

      # Advanced settings (user-configurable)
      custom_delay_sec = NULL,  # Custom delay override (NULL = use adaptive debouncing)
      show_notifications = FALSE,  # Show notifications on save
      show_indicator = TRUE,  # Show visual indicator
      enabled_triggers = c("elements", "context", "connections", "steps")  # Active triggers
    )

    # Get temp directory for auto-saves
    temp_dir <- file.path(tempdir(), "marinesabres_autosave")
    if (!dir.exists(temp_dir)) {
      dir.create(temp_dir, recursive = TRUE)
    }

    # Debug: log temp directory location
    debug_log(sprintf("Using temp directory: %s", temp_dir), "AUTO-SAVE")

    # Sync internal is_enabled flag with external autosave_enabled reactive
    # This ensures the module respects the user's auto-save preference from settings
    if (!is.null(autosave_enabled_reactive)) {
      observeEvent(autosave_enabled_reactive(), {
        enabled <- autosave_enabled_reactive()
        auto_save$is_enabled <- enabled
        debug_log(sprintf("Settings updated - auto-save %s",
                   if(enabled) "ENABLED" else "DISABLED"), "AUTO-SAVE")
        # Update both mode indicator visibility AND save indicator text
        updateModeIndicator(show = enabled)
        updateSaveIndicator()  # FIXED: Update save indicator to show new enabled/disabled state
      })

      # Initialize with current value
      isolate({
        auto_save$is_enabled <- autosave_enabled_reactive()
        debug_log(sprintf("Initialized with auto-save %s",
                   if(auto_save$is_enabled) "ENABLED" else "DISABLED"), "AUTO-SAVE")
      })
    }

    # Sync advanced settings with external reactive values
    if (!is.null(autosave_delay_reactive)) {
      observeEvent(autosave_delay_reactive(), {
        delay <- autosave_delay_reactive()
        auto_save$custom_delay_sec <- delay
        debug_log(sprintf("Settings updated - custom delay: %s seconds", delay), "AUTO-SAVE")
      })

      isolate({
        auto_save$custom_delay_sec <- autosave_delay_reactive()
        debug_log(sprintf("Initialized with custom delay: %s seconds",
                   auto_save$custom_delay_sec), "AUTO-SAVE")
      })
    }

    if (!is.null(autosave_notifications_reactive)) {
      observeEvent(autosave_notifications_reactive(), {
        show_notif <- autosave_notifications_reactive()
        auto_save$show_notifications <- show_notif
        debug_log(sprintf("Settings updated - notifications %s",
                   if(show_notif) "ENABLED" else "DISABLED"), "AUTO-SAVE")
      })

      isolate({
        auto_save$show_notifications <- autosave_notifications_reactive()
      })
    }

    if (!is.null(autosave_indicator_reactive)) {
      observeEvent(autosave_indicator_reactive(), {
        show_ind <- autosave_indicator_reactive()
        auto_save$show_indicator <- show_ind
        debug_log(sprintf("Settings updated - indicator %s",
                   if(show_ind) "ENABLED" else "DISABLED"), "AUTO-SAVE")
        # Update indicator visibility
        updateSaveIndicator()
        updateModeIndicator(show = auto_save$is_enabled)
      })

      isolate({
        auto_save$show_indicator <- autosave_indicator_reactive()
      })
    }

    if (!is.null(autosave_triggers_reactive)) {
      observeEvent(autosave_triggers_reactive(), {
        triggers <- autosave_triggers_reactive()
        auto_save$enabled_triggers <- triggers
        debug_log(sprintf("Settings updated - triggers: %s",
                   paste(triggers, collapse = ", ")), "AUTO-SAVE")
      })

      isolate({
        auto_save$enabled_triggers <- autosave_triggers_reactive()
        debug_log(sprintf("Initialized with triggers: %s",
                   paste(auto_save$enabled_triggers, collapse = ", ")), "AUTO-SAVE")
      })
    }

    # Function to generate unique session ID
    session_id <- paste0("session_", format(Sys.time(), "%Y%m%d_%H%M%S"), "_",
                        sample(1000:9999, 1))

    # ========== ADAPTIVE DEBOUNCING HELPERS ==========

    #' Track a new change and update editing pattern
    #'
    #' Records the timestamp of a change and determines if editing is rapid or casual
    #' based on recent change frequency
    track_change <- function() {
      now <- Sys.time()

      # Add current timestamp to list
      auto_save$change_timestamps <- c(auto_save$change_timestamps, list(now))

      # Remove timestamps older than the pattern detection window
      cutoff_time <- now - AUTOSAVE_PATTERN_WINDOW_SEC
      auto_save$change_timestamps <- Filter(
        function(ts) ts > cutoff_time,
        auto_save$change_timestamps
      )

      # Determine editing mode based on recent change count
      recent_changes <- length(auto_save$change_timestamps)

      old_mode <- auto_save$editing_mode

      if (recent_changes >= AUTOSAVE_RAPID_THRESHOLD) {
        # Rapid editing detected
        auto_save$editing_mode <- "rapid"
        auto_save$current_debounce_ms <- AUTOSAVE_DEBOUNCE_RAPID_MS
      } else {
        # Casual editing
        auto_save$editing_mode <- "casual"
        auto_save$current_debounce_ms <- AUTOSAVE_DEBOUNCE_CASUAL_MS
      }

      # Log mode changes
      if (old_mode != auto_save$editing_mode) {
        debug_log(sprintf(
          "Editing mode changed: %s → %s (%d changes in %ds window, debounce: %dms)",
          old_mode,
          auto_save$editing_mode,
          recent_changes,
          AUTOSAVE_PATTERN_WINDOW_SEC,
          auto_save$current_debounce_ms
        ), "AUTO-SAVE ADAPTIVE")
      }

      # Always update visual mode indicator when tracking changes (ensures badge is visible)
      # Show tutorial on first time badge appears
      show_tutorial_now <- !auto_save$tutorial_triggered && auto_save$is_enabled
      updateModeIndicator(show = auto_save$is_enabled, show_tutorial = show_tutorial_now)

      # Mark tutorial as triggered
      if (show_tutorial_now) {
        auto_save$tutorial_triggered <- TRUE
      }

      return(auto_save$current_debounce_ms)
    }

    #' Get current adaptive debounce delay
    #'
    #' @return Current debounce delay in milliseconds
    get_current_debounce <- function() {
      # If custom delay is set, use it (override adaptive debouncing)
      if (!is.null(auto_save$custom_delay_sec)) {
        return(auto_save$custom_delay_sec * 1000)  # Convert seconds to milliseconds
      }
      # Otherwise use adaptive debouncing
      return(auto_save$current_debounce_ms)
    }

    # Function to perform auto-save
    perform_auto_save <- function() {
      if (!auto_save$is_enabled) return()

      # CRITICAL: Don't auto-save if recovery modal is pending
      # This prevents overwriting the good recovery file with empty data
      if (auto_save$recovery_pending) {
        debug_log("Skipping auto-save - recovery modal pending", "AUTO-SAVE")
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
          debug_log(sprintf("Saving ISA data with %d element types", length(isa)), "AUTO-SAVE")
          if (length(isa) > 0) {
            for (name in names(isa)) {
              if (is.data.frame(isa[[name]])) {
                debug_log(sprintf("  %s: %d rows", name, nrow(isa[[name]])), "AUTO-SAVE")
              }
            }
          } else {
            debug_log("  isa_data is EMPTY list", "AUTO-SAVE")
          }
        } else {
          debug_log("WARNING: isa_data is NULL or missing", "AUTO-SAVE")
        }

        # Add auto-save metadata
        current_data$autosave_metadata <- list(
          session_id = session_id,
          save_time = Sys.time(),
          save_count = auto_save$save_count + 1,
          version = APP_VERSION
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

        # Show notification if enabled
        if (auto_save$show_notifications) {
          showNotification(
            i18n$t("common.misc.all_changes_saved"),
            type = "message",
            duration = 2
          )
        }

        # Log save event
        debug_log(sprintf("Saved at %s (Count: %d) - data now clean",
                   format(Sys.time(), "%H:%M:%S"),
                   auto_save$save_count), "AUTO-SAVE")

      }, error = function(e) {
        auto_save$save_status <- "error"
        auto_save$error_message <- e$message
        updateSaveIndicator()
        debug_log(sprintf("ERROR: %s", e$message), "AUTO-SAVE")
      })
    }

    # Function to update save indicator UI
    updateSaveIndicator <- function() {
      status <- auto_save$save_status

      # Determine icon and text based on status
      if (status == "saving") {
        icon <- "🔄"
        text <- i18n$t("common.misc.saving")
        time_text <- ""
      } else if (status == "saved") {
        icon <- "✓"
        text <- i18n$t("common.misc.all_changes_saved")

        if (!is.null(auto_save$last_save_time)) {
          time_diff <- as.numeric(difftime(Sys.time(), auto_save$last_save_time, units = "secs"))

          if (time_diff < 60) {
            time_text <- sprintf(i18n$t("common.misc.last_saved_d_seconds_ago"), round(time_diff))
          } else if (time_diff < 3600) {
            time_text <- sprintf(i18n$t("common.misc.last_saved_d_minutes_ago"), round(time_diff / 60))
          } else {
            time_text <- format(auto_save$last_save_time, "%H:%M:%S")
          }
        } else {
          time_text <- ""
        }
      } else if (status == "error") {
        icon <- "⚠"
        text <- i18n$t("common.misc.save_failed")
        time_text <- auto_save$error_message
      } else {
        # Check if auto-save is actually enabled
        if (auto_save$is_enabled) {
          icon <- "💾"
          text <- i18n$t("common.misc.auto_save_enabled")
        } else {
          icon <- "💾"
          text <- i18n$t("common.misc.auto_save_disabled")
        }
        time_text <- ""
      }

      # Update UI via JavaScript
      session$sendCustomMessage(
        type = "update_save_indicator",
        message = list(
          icon = icon,
          text = text,
          time = time_text,
          status = status,
          visible = auto_save$show_indicator  # Control visibility based on setting
        )
      )
    }

    # Function to update editing mode indicator UI
    updateModeIndicator <- function(show = TRUE, show_tutorial = FALSE) {
      mode <- auto_save$editing_mode
      debounce_ms <- auto_save$current_debounce_ms
      change_count <- length(auto_save$change_timestamps)

      # Determine mode icon
      mode_icon <- if (mode == "rapid") "⚡" else "💤"

      # Determine mode label with change count
      # Compact version (collapsed)
      mode_label_short <- sprintf("%s %s", mode_icon, debounce_ms / 1000)

      # Expanded version (shows full details)
      if (mode == "rapid") {
        mode_label_full <- sprintf("⚡ Rapid • %ds • %d edits", debounce_ms / 1000, change_count)
      } else {
        mode_label_full <- sprintf("💤 Casual • %ds", debounce_ms / 1000)
      }

      # Only show mode indicator when autosave is enabled and indicator is enabled
      show_badge <- show && auto_save$is_enabled && !auto_save$recovery_pending && auto_save$show_indicator

      # Update UI via JavaScript
      session$sendCustomMessage(
        type = "update_editing_mode",
        message = list(
          mode = mode,
          mode_label_short = mode_label_short,
          mode_label_full = mode_label_full,
          change_count = change_count,
          show = show_badge,
          show_tutorial = show_tutorial
        )
      )
    }

    # ========== EVENT-DRIVEN AUTO-SAVE WITH ADAPTIVE DEBOUNCING ==========
    # Listen to SES structure changes via event bus instead of polling
    # This makes auto-save non-intrusive and efficient
    # Uses adaptive debouncing: 2s for casual edits, 5s for rapid edits

    if (!is.null(event_bus)) {
      # Adaptive debouncing state
      debounce_state <- reactiveValues(
        pending_save = FALSE,        # Is a save currently scheduled?
        last_change_time = NULL,     # When was the last change detected?
        timer_id = NULL              # invalidateLater timer reference
      )

      # Listen to ISA change events (non-debounced)
      observeEvent(event_bus$isa_changed(), {
        # Check if "elements" trigger is enabled (isa_changed represents element changes)
        # NOTE: For more granular control, event_bus would need specific events for:
        #       - context_changed (region/ecosystem changes)
        #       - connections_changed (connection approvals)
        #       - steps_changed (step progression)
        if (!"elements" %in% auto_save$enabled_triggers) {
          debug_log("ISA change detected but 'elements' trigger is disabled - skipping", "AUTO-SAVE ADAPTIVE")
          return()
        }

        # Track this change for pattern analysis
        track_change()

        # Record change time
        debounce_state$last_change_time <- Sys.time()

        # Mark that a save is pending (will be triggered after debounce delay)
        if (!debounce_state$pending_save) {
          debounce_state$pending_save <- TRUE
          debug_log(sprintf("Change detected, scheduling save with %dms debounce (%s mode)",
                     get_current_debounce(),
                     auto_save$editing_mode), "AUTO-SAVE ADAPTIVE")
        }
      })

      # Adaptive debounce timer - checks if enough time has passed since last change
      observe({
        # Re-check every 500ms
        invalidateLater(500)

        isolate({
          # Only process if a save is pending
          if (!debounce_state$pending_save) return()

          # Check if enough time has passed since last change
          if (!is.null(debounce_state$last_change_time)) {
            time_since_change <- as.numeric(difftime(Sys.time(),
                                                     debounce_state$last_change_time,
                                                     units = "secs")) * 1000  # Convert to ms

            current_debounce <- get_current_debounce()

            # If enough time has passed, trigger save
            if (time_since_change >= current_debounce) {
              # Reset pending flag
              debounce_state$pending_save <- FALSE
              debounce_state$last_change_time <- NULL

              # Only save if enabled and not in recovery mode
              if (auto_save$is_enabled && !auto_save$recovery_pending) {
                data <- project_data_reactive()

                # Calculate hash of current data
                if (!is.null(data)) {
                  current_hash <- digest::digest(data)

                  # Only save if hash has changed (prevents duplicate saves)
                  if (is.null(auto_save$last_data_hash) || current_hash != auto_save$last_data_hash) {
                    debug_log(sprintf("Debounce elapsed (%dms, %s mode), performing save",
                               current_debounce,
                               auto_save$editing_mode), "AUTO-SAVE ADAPTIVE")
                    perform_auto_save()
                  } else {
                    debug_log("Hash unchanged, skipping save", "AUTO-SAVE ADAPTIVE")
                  }
                }
              }
            }
          }
        })
      })

      debug_log("Event-driven auto-save with adaptive debouncing initialized", "AUTO-SAVE")
      debug_log(sprintf("Casual editing: %dms debounce | Rapid editing: %dms debounce",
                 AUTOSAVE_DEBOUNCE_CASUAL_MS,
                 AUTOSAVE_DEBOUNCE_RAPID_MS), "AUTO-SAVE")
    } else {
      debug_log("WARNING: Event bus not provided, auto-save will only work on manual triggers", "AUTO-SAVE")
    }

    # Fallback: Mark data as dirty when project_data changes directly (for compatibility)
    # This handles cases where event bus might not be available or data changes outside ISA
    observeEvent(project_data_reactive(), {
      data <- project_data_reactive()

      # Calculate hash of current data
      if (!is.null(data)) {
        current_hash <- digest::digest(data)

        # Only mark dirty if hash has changed
        if (is.null(auto_save$last_data_hash) || current_hash != auto_save$last_data_hash) {
          auto_save$data_dirty <- TRUE

          # Immediate save on first data load (when last_data_hash is NULL)
          # This ensures newly loaded/imported data is saved immediately
          if (is.null(auto_save$last_data_hash) && auto_save$is_enabled && !auto_save$recovery_pending) {
            debug_log("First data detected - performing immediate save", "AUTO-SAVE")
            perform_auto_save()
          }
        }
      }
    })

    # Update indicator display periodically to refresh "last saved X ago" text
    observe({
      invalidateLater(AUTOSAVE_INDICATOR_UPDATE_MS)
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

        # Only offer recovery if file is within recovery window
        if (time_diff < AUTOSAVE_RECOVERY_WINDOW_HOURS) {
          # CRITICAL: Set flag to prevent auto-save from overwriting recovery file
          auto_save$recovery_pending <- TRUE
          debug_log("Recovery file found - blocking auto-save until user decision", "AUTO-SAVE")

          # Show recovery modal
          showModal(modalDialog(
            title = tags$h4(icon("exclamation-triangle"), " ",
                          i18n$t("common.misc.unsaved_work_detected")),
            size = "m",
            easyClose = FALSE,

            tags$div(
              style = "padding: 15px;",
              tags$p(
                i18n$t("common.misc.we_found_an_auto_saved_version_of_your_work_from"),
                " ",
                tags$strong(format(file_time, "%Y-%m-%d %H:%M:%S"))
              ),
              tags$p(
                i18n$t("common.misc.would_you_like_to_recover_this_data")
              ),
              tags$br(),
              tags$p(
                style = "font-size: 12px; color: #666;",
                icon("info-circle"), " ",
                i18n$t("common.misc.auto_save_helps_prevent_data_loss_from_unexpected_disconnections")
              )
            ),

            footer = tagList(
              actionButton(ns("discard_recovery"),
                         i18n$t("common.misc.start_fresh"),
                         class = "btn-default"),
              actionButton(ns("confirm_recovery"),
                         i18n$t("common.misc.recover_data"),
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
      debug_log("Recovery confirmed - auto-save will resume after page reload", "AUTO-SAVE")

      latest_file <- file.path(temp_dir, "latest_autosave.rds")

      tryCatch({
        recovered_data <- readRDS(latest_file)

        # Remove auto-save metadata before returning
        recovered_data$autosave_metadata <- NULL

        # Update the project data reactiveVal
        project_data_reactive(recovered_data)

        # Log recovery
        debug_log(sprintf("Data recovered from %s", latest_file), "AUTO-SAVE")

        # Count total elements across all categories (use nrow for dataframes)
        total_recovered <- sum(
          nrow(recovered_data$data$isa_data$drivers %||% data.frame()),
          nrow(recovered_data$data$isa_data$activities %||% data.frame()),
          nrow(recovered_data$data$isa_data$pressures %||% data.frame()),
          nrow(recovered_data$data$isa_data$marine_processes %||% data.frame()),
          nrow(recovered_data$data$isa_data$ecosystem_services %||% data.frame()),
          nrow(recovered_data$data$isa_data$goods_benefits %||% data.frame()),
          nrow(recovered_data$data$isa_data$responses %||% data.frame())
        )
        debug_log(sprintf("Recovered %d total elements", total_recovered), "AUTO-SAVE")

        # Delete the recovery file to prevent infinite loop on reload
        if (file.exists(latest_file)) {
          file.remove(latest_file)
          debug_log("Recovery file deleted to prevent loop", "AUTO-SAVE")
        }

        showNotification(
          i18n$t("common.messages.data_recovered_successfully"),
          type = "message",
          duration = 3
        )

        removeModal()

        # NOTE: No page reload needed! Data is already in project_data_reactive()
        # and all module observers have already detected and loaded it.
        # Page reload would destroy the session we just recovered!

      }, error = function(e) {
        debug_log(sprintf("Recovery failed: %s", e$message), "AUTO-SAVE ERROR")
        showNotification(
          paste(i18n$t("common.misc.recovery_failed"), e$message),
          type = "error",
          duration = 10
        )
      })
    })

    # Handle recovery dismissal
    observeEvent(input$discard_recovery, {
      # Clear recovery pending flag to allow auto-save to resume
      auto_save$recovery_pending <- FALSE
      debug_log("Recovery discarded - auto-save resumed", "AUTO-SAVE")

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

    # Update indicator shortly after initialization to clear "Initializing..." message
    # Use a flag to ensure this only runs once
    indicator_initialized <- FALSE

    observe({
      if (!indicator_initialized) {
        invalidateLater(100)  # 100ms delay
        isolate({
          if (!indicator_initialized) {
            updateSaveIndicator()
            updateModeIndicator(show = auto_save$is_enabled)
            indicator_initialized <<- TRUE
          }
        })
      }
    })

    # ========== GENERIC TUTORIAL INTEGRATION ==========
    # Show tutorial when mode badge first appears (migrated from inline tutorial)
    observeEvent(input$show_mode_tutorial, {
      # Call the generic tutorial system from tutorial_system.R
      show_tutorial(
        session = session,
        feature_id = "autosave_mode_badge",
        title = i18n$t("common.misc.adaptive_auto_save"),
        message = HTML(sprintf(
          "<p>%s</p><p><strong>%s</strong></p><ul><li>%s</li><li>%s</li></ul>",
          i18n$t("common.misc.this_badge_shows_your_editing_mode"),
          i18n$t("common.misc.click_to_toggle"),
          i18n$t("common.misc.compact_view_shows_save_delay"),
          i18n$t("common.misc.detailed_view_shows_full_info")
        )),
        target_selector = paste0("#", ns("mode_badge")),
        position = "bottom",
        auto_dismiss_ms = 10000,
        show_confetti = FALSE
      )

      debug_log("Auto-save mode badge tutorial shown (generic system)", "TUTORIAL")
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

