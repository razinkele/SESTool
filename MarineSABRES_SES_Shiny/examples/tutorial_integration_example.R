# examples/tutorial_integration_example.R
# Practical examples showing how to integrate tutorials into existing modules

# ============================================================================
# EXAMPLE 1: ISA Data Entry Module Integration
# ============================================================================

# Location: modules/isa_data_entry_module.R
# When to show: When user first navigates to ISA tab

isa_data_entry_server_EXAMPLE <- function(id, project_data, i18n, parent_session) {
  moduleServer(id, function(input, output, session) {

    # Track if tutorial has been shown in this session
    tutorial_shown <- reactiveVal(FALSE)

    # Show tutorial on first module load
    observe({
      # Only show once per session
      if (!tutorial_shown()) {
        tutorial_shown(TRUE)

        # Delay to let UI render first
        later::later(function() {
          tutorial <- get_tutorial_content("isa_data_entry")
          show_tutorial(
            session = parent_session,  # Use parent session for global overlay
            feature_id = "isa_data_entry",
            title = tutorial$title,
            message = tutorial$message,
            target_selector = "#isa_module_container",
            position = tutorial$position,
            auto_dismiss_ms = tutorial$auto_dismiss_ms
          )
        }, delay = 1)  # 1 second delay
      }
    })

    # Rest of module logic...
  })
}

# ============================================================================
# EXAMPLE 2: AI Assistant Integration
# ============================================================================

# Location: modules/ai_isa_assistant_module.R
# When to show: When AI assistant button is first clicked

ai_assistant_server_EXAMPLE <- function(id, project_data, i18n) {
  moduleServer(id, function(input, output, session) {

    # Track first-time modal open
    first_open <- TRUE

    # AI assistant button click
    observeEvent(input$open_ai_modal, {

      # Show modal
      showModal(modalDialog(
        title = "AI ISA Assistant",
        size = "l",
        easyClose = TRUE,
        # ... modal content
      ))

      # Show tutorial on first open
      if (first_open) {
        first_open <<- FALSE

        # Wait for modal to render
        later::later(function() {
          tutorial <- get_tutorial_content("ai_assistant")
          show_tutorial(
            session = session,
            feature_id = "ai_assistant",
            title = tutorial$title,
            message = tutorial$message,
            target_selector = ".modal-dialog",
            position = "center",
            auto_dismiss_ms = tutorial$auto_dismiss_ms
          )
        }, delay = 0.5)
      }
    })
  })
}

# ============================================================================
# EXAMPLE 3: CLD Generation with Celebration
# ============================================================================

# Location: app.R or reactive_pipeline.R
# When to show: When CLD is successfully generated for first time

observe({
  # Watch for CLD generation events
  event_bus$on_cld_update()

  # Check if CLD data exists
  data <- isolate(project_data())
  cld_data <- data$data$cld_data

  if (!is.null(cld_data) && !is.null(cld_data$nodes) && nrow(cld_data$nodes) > 0) {

    # Show celebratory tutorial
    tutorial <- get_tutorial_content("cld_generation")
    show_tutorial(
      session = session,
      feature_id = "cld_generation",
      title = tutorial$title,
      message = tutorial$message,
      target_selector = "#cld_visualization_plot",
      position = "top",
      auto_dismiss_ms = tutorial$auto_dismiss_ms,
      show_confetti = TRUE  # 🎉 Celebrate success!
    )
  }
})

# ============================================================================
# EXAMPLE 4: Loop Detection Results
# ============================================================================

# Location: modules/loop_analysis_module.R
# When to show: When loops are first detected

loop_analysis_server_EXAMPLE <- function(id, cld_data, i18n) {
  moduleServer(id, function(input, output, session) {

    # Reactive for detected loops
    detected_loops <- reactive({
      # ... loop detection logic
    })

    # Show tutorial when loops found
    observe({
      loops <- detected_loops()

      if (!is.null(loops) && nrow(loops) > 0) {
        tutorial <- get_tutorial_content("loop_detection")
        show_tutorial(
          session = session,
          feature_id = "loop_detection",
          title = tutorial$title,
          message = tutorial$message,
          target_selector = "#loop_results_table",
          position = "center",
          auto_dismiss_ms = tutorial$auto_dismiss_ms
        )
      }
    })
  })
}

# ============================================================================
# EXAMPLE 5: Template Import Tab
# ============================================================================

# Location: app.R server section
# When to show: When user navigates to template import tab

observeEvent(input$sidebar_menu, {
  if (input$sidebar_menu == "template_import") {

    # Delay to let tab content render
    later::later(function() {
      tutorial <- get_tutorial_content("template_import")
      show_tutorial(
        session = session,
        feature_id = "template_import",
        title = tutorial$title,
        message = tutorial$message,
        position = "center",
        auto_dismiss_ms = tutorial$auto_dismiss_ms
      )
    }, delay = 0.5)
  }
})

# ============================================================================
# EXAMPLE 6: File Upload (on Focus)
# ============================================================================

# Location: File upload module
# When to show: When user interacts with file upload input

observeEvent(input$file_upload_input, {
  tutorial <- get_tutorial_content("file_upload")
  show_tutorial(
    session = session,
    feature_id = "file_upload",
    title = tutorial$title,
    message = tutorial$message,
    target_selector = "#file_upload_container",
    position = "bottom",
    auto_dismiss_ms = tutorial$auto_dismiss_ms
  )
}, once = TRUE)  # Only once per session

# ============================================================================
# EXAMPLE 7: Network Analysis Tab
# ============================================================================

# Location: Network analysis module
# When to show: When network analysis results are displayed

observe({
  centrality_data <- centrality_measures()

  if (!is.null(centrality_data)) {
    tutorial <- get_tutorial_content("network_analysis")
    show_tutorial(
      session = session,
      feature_id = "network_analysis",
      title = tutorial$title,
      message = tutorial$message,
      target_selector = "#centrality_plot",
      position = "center",
      auto_dismiss_ms = tutorial$auto_dismiss_ms
    )
  }
})

# ============================================================================
# EXAMPLE 8: Export Report
# ============================================================================

# Location: Export module
# When to show: When export button is first shown/clicked

observeEvent(input$show_export_options, {
  tutorial <- get_tutorial_content("export_report")
  show_tutorial(
    session = session,
    feature_id = "export_report",
    title = tutorial$title,
    message = tutorial$message,
    target_selector = "#export_options_panel",
    position = "center",
    auto_dismiss_ms = tutorial$auto_dismiss_ms
  )
}, once = TRUE)

# ============================================================================
# EXAMPLE 9: SES Creation Tab
# ============================================================================

# Location: SES creation/dashboard tab
# When to show: On first visit to main creation interface

observeEvent(input$sidebar_menu, {
  if (input$sidebar_menu == "ses_creation" || input$sidebar_menu == "dashboard") {
    later::later(function() {
      tutorial <- get_tutorial_content("ses_creation")
      show_tutorial(
        session = session,
        feature_id = "ses_creation",
        title = tutorial$title,
        message = tutorial$message,
        position = "top",
        auto_dismiss_ms = tutorial$auto_dismiss_ms
      )
    }, delay = 1)
  }
}, once = TRUE)

# ============================================================================
# TESTING: Reset Tutorial for Development
# ============================================================================

# Add a hidden button for developers to reset tutorials during testing
# Location: Add to UI (can be hidden or only shown in dev mode)

# UI:
if (DEBUG_MODE) {
  actionButton("reset_all_tutorials", "Reset All Tutorials", class = "btn-warning")
}

# Server:
observeEvent(input$reset_all_tutorials, {
  reset_tutorial(session, "all")
  showNotification("All tutorials reset. Refresh page to see them again.", type = "message")
})

# ============================================================================
# CONDITIONAL TUTORIALS: Based on User Level
# ============================================================================

# Show different tutorials based on user experience level

show_tutorial_by_user_level <- function(session, feature_id, user_level, i18n) {

  # Beginners get full tutorial
  if (user_level == "beginner") {
    tutorial <- get_tutorial_content(feature_id)
    show_tutorial(
      session = session,
      feature_id = feature_id,
      title = tutorial$title,
      message = tutorial$message,
      position = tutorial$position,
      auto_dismiss_ms = tutorial$auto_dismiss_ms
    )
  }

  # Intermediate users get shorter version
  else if (user_level == "intermediate") {
    tutorial <- get_tutorial_content(feature_id)
    # Optionally show abbreviated version
    # Could create separate "feature_id_intermediate" content
  }

  # Experts get no tutorial (or very minimal)
  # No tutorial shown for expert level
}

# Usage:
observeEvent(once = TRUE, {
  later::later(function() {
    show_tutorial_by_user_level(
      session = session,
      feature_id = "isa_data_entry",
      user_level = user_level(),
      i18n = i18n
    )
  }, delay = 1)
})
