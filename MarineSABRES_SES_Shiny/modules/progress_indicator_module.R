# modules/progress_indicator_module.R
# Progress indicator component for data entry workflows
# Shows current step, progress bar, and step title

# UI Component - Progress Indicator
progress_indicator_ui <- function(id) {
  ns <- NS(id)

  tags$div(
    id = ns("progress_container"),
    class = "progress-indicator-container",

    # CSS for progress indicator
    tags$style(HTML("
      .progress-indicator-container {
        background: #f8f9fa;
        border: 1px solid #dee2e6;
        border-radius: 8px;
        padding: 20px;
        margin-bottom: 20px;
        box-shadow: 0 2px 4px rgba(0,0,0,0.05);
      }

      .progress-header {
        display: flex;
        justify-content: space-between;
        align-items: center;
        margin-bottom: 15px;
      }

      .progress-step-info {
        font-size: 14px;
        color: #6c757d;
        font-weight: 500;
      }

      .progress-percentage {
        font-size: 18px;
        color: #007bff;
        font-weight: 600;
      }

      .progress-title {
        font-size: 16px;
        color: #333;
        font-weight: 600;
        margin-bottom: 10px;
        display: flex;
        align-items: center;
      }

      .progress-title-icon {
        margin-right: 8px;
        color: #007bff;
      }

      .progress-bar-container {
        width: 100%;
        height: 24px;
        background: #e9ecef;
        border-radius: 12px;
        overflow: hidden;
        position: relative;
      }

      .progress-bar-fill {
        height: 100%;
        background: linear-gradient(90deg, #007bff 0%, #0056b3 100%);
        border-radius: 12px;
        transition: width 0.5s ease;
        display: flex;
        align-items: center;
        justify-content: flex-end;
        padding-right: 10px;
      }

      .progress-bar-text {
        color: white;
        font-size: 12px;
        font-weight: 600;
      }

      .progress-steps-list {
        display: flex;
        justify-content: space-between;
        margin-top: 15px;
        padding: 0;
        list-style: none;
      }

      .progress-step-item {
        flex: 1;
        text-align: center;
        padding: 8px 5px;
        font-size: 11px;
        color: #6c757d;
        border-bottom: 3px solid #dee2e6;
        transition: all 0.3s ease;
        position: relative;
      }

      .progress-step-item.completed {
        color: #28a745;
        border-bottom-color: #28a745;
      }

      .progress-step-item.active {
        color: #007bff;
        border-bottom-color: #007bff;
        font-weight: 600;
      }

      .progress-step-item.pending {
        color: #adb5bd;
        border-bottom-color: #dee2e6;
      }

      .progress-step-number {
        display: inline-block;
        width: 24px;
        height: 24px;
        line-height: 24px;
        border-radius: 50%;
        background: #dee2e6;
        color: #6c757d;
        margin-bottom: 5px;
        font-weight: 600;
        font-size: 12px;
      }

      .progress-step-item.completed .progress-step-number {
        background: #28a745;
        color: white;
      }

      .progress-step-item.active .progress-step-number {
        background: #007bff;
        color: white;
      }

      .progress-navigation {
        display: flex;
        justify-content: space-between;
        margin-top: 20px;
        padding-top: 15px;
        border-top: 1px solid #dee2e6;
      }
    ")),

    # Progress indicator content (will be updated dynamically)
    uiOutput(ns("progress_content"))
  )
}

# Server Function
progress_indicator_server <- function(id, current_step_reactive, total_steps_reactive,
                                     step_titles_reactive, i18n) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # Reactive values for progress state
    progress_state <- reactiveValues(
      current_step = 1,
      total_steps = 7,
      step_titles = NULL,
      show_steps_list = TRUE,
      can_go_back = TRUE,
      can_go_next = TRUE
    )

    # Update progress state when inputs change
    observe({
      progress_state$current_step <- current_step_reactive()
      progress_state$total_steps <- total_steps_reactive()
      progress_state$step_titles <- step_titles_reactive()
    })

    # Calculate progress percentage
    calculate_percentage <- reactive({
      if (progress_state$total_steps == 0) return(0)
      round((progress_state$current_step / progress_state$total_steps) * 100)
    })

    # Get current step title
    get_current_title <- reactive({
      if (is.null(progress_state$step_titles)) {
        return(sprintf(i18n$t("Step %d"), progress_state$current_step))
      }

      if (length(progress_state$step_titles) >= progress_state$current_step) {
        return(progress_state$step_titles[[progress_state$current_step]])
      }

      return(sprintf(i18n$t("Step %d"), progress_state$current_step))
    })

    # Render progress indicator
    output$progress_content <- renderUI({
      current <- progress_state$current_step
      total <- progress_state$total_steps
      percentage <- calculate_percentage()
      title <- get_current_title()

      tags$div(
        # Header with step counter and percentage
        tags$div(
          class = "progress-header",
          tags$div(
            class = "progress-step-info",
            icon("tasks"),
            " ",
            sprintf(i18n$t("Step %d of %d"), current, total)
          ),
          tags$div(
            class = "progress-percentage",
            sprintf("%d%%", percentage)
          )
        ),

        # Current step title
        tags$div(
          class = "progress-title",
          tags$span(class = "progress-title-icon", icon("arrow-right")),
          title
        ),

        # Progress bar
        tags$div(
          class = "progress-bar-container",
          tags$div(
            class = "progress-bar-fill",
            style = sprintf("width: %d%%;", percentage),
            tags$span(
              class = "progress-bar-text",
              if (percentage >= 20) sprintf("%d%%", percentage) else ""
            )
          )
        ),

        # Optional: Steps list
        if (progress_state$show_steps_list && !is.null(progress_state$step_titles)) {
          tags$ul(
            class = "progress-steps-list",
            lapply(seq_len(total), function(i) {
              status <- if (i < current) {
                "completed"
              } else if (i == current) {
                "active"
              } else {
                "pending"
              }

              step_label <- if (length(progress_state$step_titles) >= i) {
                # Abbreviate long titles
                title_text <- progress_state$step_titles[[i]]
                if (nchar(title_text) > 15) {
                  paste0(substr(title_text, 1, 12), "...")
                } else {
                  title_text
                }
              } else {
                sprintf(i18n$t("Step %d"), i)
              }

              tags$li(
                class = paste("progress-step-item", status),
                tags$div(
                  class = "progress-step-number",
                  if (status == "completed") icon("check") else as.character(i)
                ),
                tags$div(step_label)
              )
            })
          )
        }
      )
    })

    # Return control functions
    list(
      set_current_step = function(step) {
        progress_state$current_step <- step
      },
      get_current_step = function() {
        progress_state$current_step
      },
      set_total_steps = function(total) {
        progress_state$total_steps <- total
      },
      set_step_titles = function(titles) {
        progress_state$step_titles <- titles
      },
      show_steps_list = function(show = TRUE) {
        progress_state$show_steps_list <- show
      },
      get_percentage = function() {
        calculate_percentage()
      }
    )
  })
}

# Navigation buttons component (Previous/Next)
navigation_buttons_ui <- function(id) {
  ns <- NS(id)

  tags$div(
    class = "progress-navigation",

    # CSS for navigation buttons
    tags$style(HTML("
      .progress-navigation {
        display: flex;
        justify-content: space-between;
        margin-top: 20px;
        padding-top: 15px;
        border-top: 1px solid #dee2e6;
      }

      .nav-button {
        min-width: 120px;
      }

      .nav-button-back {
        background-color: #6c757d;
        border-color: #6c757d;
      }

      .nav-button-back:hover {
        background-color: #5a6268;
        border-color: #545b62;
      }

      .nav-button-next {
        background-color: #007bff;
        border-color: #007bff;
      }

      .nav-button-next:hover {
        background-color: #0056b3;
        border-color: #004085;
      }

      .nav-button-finish {
        background-color: #28a745;
        border-color: #28a745;
      }

      .nav-button-finish:hover {
        background-color: #218838;
        border-color: #1e7e34;
      }
    ")),

    # Previous button
    actionButton(
      ns("btn_previous"),
      label = tagList(icon("arrow-left"), " Previous"),
      class = "btn btn-secondary nav-button nav-button-back"
    ),

    # Next/Finish button
    uiOutput(ns("next_button"))
  )
}

# Navigation buttons server
navigation_buttons_server <- function(id, current_step_reactive, total_steps_reactive,
                                     i18n, on_previous = NULL, on_next = NULL) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # Render next button (changes to "Finish" on last step)
    output$next_button <- renderUI({
      current <- current_step_reactive()
      total <- total_steps_reactive()

      is_last <- (current >= total)

      if (is_last) {
        actionButton(
          ns("btn_next"),
          label = tagList(i18n$t("Finish"), " ", icon("check")),
          class = "btn btn-success nav-button nav-button-finish"
        )
      } else {
        actionButton(
          ns("btn_next"),
          label = tagList(i18n$t("Next"), " ", icon("arrow-right")),
          class = "btn btn-primary nav-button nav-button-next"
        )
      }
    })

    # Enable/disable previous button
    observe({
      current <- current_step_reactive()
      if (current <= 1) {
        shinyjs::disable("btn_previous")
      } else {
        shinyjs::enable("btn_previous")
      }
    })

    # Handle previous button click
    observeEvent(input$btn_previous, {
      if (!is.null(on_previous)) {
        on_previous()
      }
    })

    # Handle next button click
    observeEvent(input$btn_next, {
      if (!is.null(on_next)) {
        on_next()
      }
    })

    # Return button click events
    list(
      previous_clicked = reactive(input$btn_previous),
      next_clicked = reactive(input$btn_next)
    )
  })
}
