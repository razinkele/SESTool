# modules/entry_point_module.R
# Simplified Entry Point System for Marine Management DSS & Toolbox
# Purpose: Guide users through EP0-EP4 to find appropriate tools

# ============================================================================
# UI FUNCTION
# ============================================================================

entry_point_ui <- function(id) {
  ns <- NS(id)

  fluidPage(
    # Use i18n for language support
    shiny.i18n::usei18n(i18n),

    # Custom CSS
    tags$head(
      tags$style(HTML("
        .ep-card {
          border: 2px solid #3498db;
          border-radius: 8px;
          padding: 20px;
          margin: 15px 0;
          background: white;
          box-shadow: 0 4px 6px rgba(0,0,0,0.1);
          cursor: pointer;
          transition: all 0.3s ease;
        }
        .ep-card:hover {
          box-shadow: 0 6px 12px rgba(0,0,0,0.15);
          transform: translateY(-2px);
        }
        .ep-card.selected {
          border-color: #27ae60;
          background: #eafaf1;
        }
        .ep-progress {
          background: #ecf0f1;
          border-radius: 20px;
          padding: 15px;
          margin: 20px 0;
        }
        .ep-step {
          display: inline-block;
          padding: 8px 15px;
          margin: 0 5px;
          border-radius: 15px;
          background: white;
          border: 2px solid #bdc3c7;
          font-weight: 500;
        }
        .ep-step.active {
          background: #3498db;
          color: white;
          border-color: #3498db;
        }
        .ep-step.completed {
          background: #27ae60;
          color: white;
          border-color: #27ae60;
        }
      ")),
      # Initialize Bootstrap tooltips
      tags$script(HTML("
        $(document).ready(function() {
          // Initialize tooltips on page load
          $('[data-toggle=\"tooltip\"]').tooltip();

          // Re-initialize tooltips when content changes
          Shiny.addCustomMessageHandler('reinit_tooltips', function(message) {
            setTimeout(function() {
              $('[data-toggle=\"tooltip\"]').tooltip();
            }, 100);
          });
        });

        // Re-initialize tooltips after any Shiny update
        $(document).on('shiny:value', function(event) {
          setTimeout(function() {
            $('[data-toggle=\"tooltip\"]').tooltip();
          }, 100);
        });
      "))
    ),

    # Dynamic content area
    uiOutput(ns("main_content"))
  )
}

# ============================================================================
# SERVER FUNCTION
# ============================================================================

entry_point_server <- function(id, project_data_reactive, parent_session = NULL) {
  moduleServer(id, function(input, output, session) {

    # Reactive values to track state
    rv <- reactiveValues(
      current_screen = "welcome",  # welcome, guided, recommendations
      current_step = 0,            # 0=EP0, 1=EP1, 2=EP2-3, 4=EP4
      user_question = "",
      ep0_selected = NULL,
      ep1_selected = NULL,
      ep2_selected = c(),
      ep3_selected = c(),
      ep4_selected = c()
    )

    # ========== MAIN CONTENT RENDERER ==========
    output$main_content <- renderUI({
      # Add reactive dependency on current language to trigger re-render when language changes
      current_lang <- i18n$get_translation_language()

      if (rv$current_screen == "welcome") {
        render_welcome_screen(session$ns)
      } else if (rv$current_screen == "guided") {
        render_guided_screen(session$ns, rv, input)
      } else if (rv$current_screen == "recommendations") {
        render_recommendations_screen(session$ns, rv)
      }
    })

    # ========== WELCOME SCREEN ACTIONS ==========
    observeEvent(input$start_guided, {
      rv$user_question <- input$user_question %||% ""
      rv$current_screen <- "guided"
      rv$current_step <- 0
    })

    observeEvent(input$start_quick, {
      showNotification(i18n$t("ep_notify_use_main_menu"), type = "message")
    })

    # ========== EP0 ACTIONS ==========
    observeEvent(input$ep0_role_click, {
      rv$ep0_selected <- input$ep0_role_click
    })

    observeEvent(input$ep0_continue, {
      if (!is.null(rv$ep0_selected)) {
        rv$current_step <- 1
      } else {
        showNotification(i18n$t("ep_notify_select_role"), type = "warning")
      }
    })

    observeEvent(input$ep0_skip, {
      rv$ep0_selected <- NULL
      rv$current_step <- 1
    })

    # ========== EP1 ACTIONS ==========
    observeEvent(input$ep1_need_click, {
      rv$ep1_selected <- input$ep1_need_click
    })

    observeEvent(input$ep1_back, {
      rv$current_step <- 0
    })

    observeEvent(input$ep1_continue, {
      if (!is.null(rv$ep1_selected)) {
        rv$current_step <- 2
      } else {
        showNotification(i18n$t("ep_notify_select_need"), type = "warning")
      }
    })

    observeEvent(input$ep1_skip, {
      rv$ep1_selected <- NULL
      rv$current_step <- 2
    })

    # ========== EP2-3 ACTIONS ==========
    observe({
      rv$ep2_selected <- input$ep2_activities %||% c()
    })

    observe({
      rv$ep3_selected <- input$ep3_risks %||% c()
    })

    observeEvent(input$ep23_back, {
      rv$current_step <- 1
    })

    observeEvent(input$ep23_continue, {
      rv$current_step <- 4
    })

    observeEvent(input$ep23_skip, {
      rv$current_step <- 4
    })

    # ========== EP4 ACTIONS ==========
    observe({
      rv$ep4_selected <- input$ep4_topics %||% c()
    })

    observeEvent(input$ep4_back, {
      rv$current_step <- 2
    })

    observeEvent(input$ep4_get_recommendations, {
      rv$current_screen <- "recommendations"
    })

    observeEvent(input$ep4_skip, {
      rv$current_screen <- "recommendations"
    })

    # ========== START OVER ==========
    observeEvent(input$start_over, {
      rv$current_screen <- "welcome"
      rv$current_step <- 0
      rv$user_question <- ""
      rv$ep0_selected <- NULL
      rv$ep1_selected <- NULL
      rv$ep2_selected <- c()
      rv$ep3_selected <- c()
      rv$ep4_selected <- c()
    })

    # ========== TOOL NAVIGATION OBSERVERS ==========
    # These handle the "Go to [Tool]" buttons on the recommendations screen
    # Since the parent_session is needed to update the sidebar menu, we only
    # create these observers if parent_session is provided

    if (!is.null(parent_session)) {
      # Observe tool navigation buttons dynamically
      observe({
        if (rv$current_screen == "recommendations") {
          recommended_tools <- get_tool_recommendations(rv)

          lapply(recommended_tools, function(tool) {
            btn_id <- paste0("goto_", tool$id)

            observeEvent(input[[btn_id]], {
              # Navigate to the tool's menu using parent session
              updateTabItems(parent_session, "sidebar_menu", tool$menu_id)

              showNotification(
                sprintf(i18n$t("ep_notify_navigating_to"), tool$name),
                type = "message",
                duration = 2
              )
            }, ignoreInit = TRUE)
          })
        }
      })
    }

  })
}

# ============================================================================
# UI HELPER FUNCTIONS
# ============================================================================

render_welcome_screen <- function(ns) {
  fluidRow(
    column(12,
      div(
        class = "jumbotron",
        h1(icon("compass"), " ", i18n$t("Welcome to the MarineSABRES Toolbox")),
        p(class = "lead", i18n$t("This guidance system will help you find the right tools for your marine management needs.")),
        hr(),

        textAreaInput(
          ns("user_question"),
          h4(i18n$t("What is your main marine management question?")),
          placeholder = i18n$t("e.g., How can we reduce fishing impacts while maintaining livelihoods?"),
          rows = 3,
          width = "100%"
        ),

        br(),

        fluidRow(
          column(6,
            div(
              class = "ep-card",
              h3(icon("route"), " ", i18n$t("Guided Pathway")),
              p(i18n$t("Step-by-step guidance through the entry points")),
              actionButton(ns("start_guided"), i18n$t("Start Guided Journey"),
                          icon = icon("play"), class = "btn-primary btn-lg btn-block")
            )
          ),
          column(6,
            div(
              class = "ep-card",
              h3(icon("bolt"), " ", i18n$t("Quick Access")),
              p(i18n$t("I know what tool I need")),
              actionButton(ns("start_quick"), i18n$t("Browse Tools"),
                          icon = icon("tools"), class = "btn-success btn-lg btn-block")
            )
          )
        )
      )
    )
  )
}

render_guided_screen <- function(ns, rv, input) {
  tagList(
    # Progress tracker
    fluidRow(
      column(12,
        div(
          class = "ep-progress",
          h5(i18n$t("Your Progress:")),
          span(class = "ep-step completed", icon("check"), " ", i18n$t("Welcome")),
          span("→"),
          span(class = if(rv$current_step > 0) "ep-step completed" else "ep-step active", i18n$t("EP0: Role")),
          span("→"),
          span(class = if(rv$current_step > 1) "ep-step completed" else if(rv$current_step == 1) "ep-step active" else "ep-step", i18n$t("EP1: Need")),
          span("→"),
          span(class = if(rv$current_step > 2) "ep-step completed" else if(rv$current_step == 2) "ep-step active" else "ep-step", i18n$t("EP2-3: Context")),
          span("→"),
          span(class = if(rv$current_step >= 4) "ep-step active" else "ep-step", i18n$t("EP4: Topic")),
          span("→"),
          span(class = if(rv$current_screen == "recommendations") "ep-step completed" else "ep-step", icon("star"), " ", i18n$t("Tools"))
        )
      )
    ),

    hr(),

    # Render current step
    if (rv$current_step == 0) {
      render_ep0(ns, rv)
    } else if (rv$current_step == 1) {
      render_ep1(ns, rv)
    } else if (rv$current_step == 2) {
      render_ep23(ns, rv)
    } else if (rv$current_step == 4) {
      render_ep4(ns, rv)
    }
  )
}

render_ep0 <- function(ns, rv) {
  fluidRow(
    column(12,
      div(
        h2(icon("user"), " ", i18n$t("Entry Point 0: Who Are You?")),
        span(
          icon("info-circle", style = "color: #3498db; cursor: help; margin-left: 10px;"),
          `data-toggle` = "tooltip",
          `data-placement` = "right",
          title = i18n$t("Your role helps us recommend the most relevant tools and workflows for your marine management context.")
        )
      ),
      p(class = "text-muted", i18n$t("Select your role in marine management")),
      br(),

      lapply(EP0_MANAGER_ROLES, function(role) {
        div(
          class = if(!is.null(rv$ep0_selected) && rv$ep0_selected == role$id) "ep-card selected" else "ep-card",
          onclick = sprintf("Shiny.setInputValue('%s', '%s', {priority: 'event'})", ns("ep0_role_click"), role$id),
          `data-toggle` = "tooltip",
          `data-placement` = "top",
          title = if(!is.null(role$typical_tasks)) paste(i18n$t("Typical tasks:"), role$typical_tasks) else i18n$t(role$description),
          fluidRow(
            column(2, icon(role$icon, class = "fa-3x", style = "color: #3498db;")),
            column(10,
              h4(i18n$t(role$label)),
              p(i18n$t(role$description))
            )
          )
        )
      }),

      br(),
      fluidRow(
        column(6,
          actionButton(ns("ep0_skip"), i18n$t("Skip"), icon = icon("forward"), class = "btn-secondary btn-block",
                      `data-toggle` = "tooltip", title = i18n$t("Skip if you're not sure or want to see all options"))
        ),
        column(6,
          actionButton(ns("ep0_continue"), i18n$t("Continue to EP1"), icon = icon("arrow-right"), class = "btn-primary btn-block",
                      `data-toggle` = "tooltip", title = i18n$t("Proceed to identify your basic human needs"))
        )
      )
    )
  )
}

render_ep1 <- function(ns, rv) {
  fluidRow(
    column(12,
      div(
        h2(icon("heart"), " ", i18n$t("Entry Point 1: Why Do You Care?")),
        span(
          icon("info-circle", style = "color: #3498db; cursor: help; margin-left: 10px;"),
          `data-toggle` = "tooltip",
          `data-placement` = "right",
          title = i18n$t("Understanding the fundamental human need behind your question helps identify relevant ecosystem services and management priorities.")
        )
      ),
      p(class = "text-muted", i18n$t("What basic human need drives your question?")),
      br(),

      lapply(EP1_BASIC_NEEDS, function(need) {
        div(
          class = if(!is.null(rv$ep1_selected) && rv$ep1_selected == need$id) "ep-card selected" else "ep-card",
          onclick = sprintf("Shiny.setInputValue('%s', '%s', {priority: 'event'})", ns("ep1_need_click"), need$id),
          style = sprintf("border-left: 5px solid %s;", sanitize_color(need$color)),
          `data-toggle` = "tooltip",
          `data-placement` = "top",
          title = paste0(i18n$t(need$label), ": ", i18n$t(need$description)),
          h4(i18n$t(need$label)),
          p(i18n$t(need$description))
        )
      }),

      br(),
      fluidRow(
        column(4,
          actionButton(ns("ep1_back"), i18n$t("Back"), icon = icon("arrow-left"), class = "btn-secondary btn-block",
                      `data-toggle` = "tooltip", title = i18n$t("Return to role selection"))
        ),
        column(4,
          actionButton(ns("ep1_skip"), i18n$t("Skip"), icon = icon("forward"), class = "btn-warning btn-block",
                      `data-toggle` = "tooltip", title = i18n$t("Skip if multiple needs apply or you're unsure"))
        ),
        column(4,
          actionButton(ns("ep1_continue"), i18n$t("Continue"), icon = icon("arrow-right"), class = "btn-primary btn-block",
                      `data-toggle` = "tooltip", title = i18n$t("Proceed to specify activities and risks"))
        )
      )
    )
  )
}

render_ep23 <- function(ns, rv) {
  fluidRow(
    column(6,
      div(
        h3(icon("industry"), " ", i18n$t("EP2: Activity Sectors")),
        span(
          icon("info-circle", style = "color: #3498db; cursor: help; margin-left: 10px;"),
          `data-toggle` = "tooltip",
          `data-placement` = "right",
          title = i18n$t("Select the human activities relevant to your marine management question. These represent the 'Drivers' and 'Activities' in the DAPSI(W)R(M) framework.")
        )
      ),
      p(class = "text-muted", style = "font-size: 0.9em;", i18n$t("Select all that apply (multiple selection allowed)")),
      checkboxGroupInput(ns("ep2_activities"), NULL,
        choices = setNames(sapply(EP2_ACTIVITY_SECTORS, function(x) x$id),
                          sapply(EP2_ACTIVITY_SECTORS, function(x) i18n$t(x$label))),
        selected = rv$ep2_selected)
    ),
    column(6,
      div(
        h3(icon("exclamation-triangle"), " ", i18n$t("EP3: Risks & Hazards")),
        span(
          icon("info-circle", style = "color: #3498db; cursor: help; margin-left: 10px;"),
          `data-toggle` = "tooltip",
          `data-placement` = "right",
          title = i18n$t("Select the environmental pressures, risks, or hazards you're concerned about. These represent 'Pressures' and 'State changes' in the DAPSI(W)R(M) framework.")
        )
      ),
      p(class = "text-muted", style = "font-size: 0.9em;", i18n$t("Select all that apply (multiple selection allowed)")),
      checkboxGroupInput(ns("ep3_risks"), NULL,
        choices = setNames(sapply(EP3_RISKS_HAZARDS, function(x) x$id),
                          sapply(EP3_RISKS_HAZARDS, function(x) i18n$t(x$label))),
        selected = rv$ep3_selected)
    ),
    column(12,
      br(),
      fluidRow(
        column(4,
          actionButton(ns("ep23_back"), i18n$t("Back"), icon = icon("arrow-left"), class = "btn-secondary btn-block",
                      `data-toggle` = "tooltip", title = i18n$t("Return to basic needs"))
        ),
        column(4,
          actionButton(ns("ep23_skip"), i18n$t("Skip"), icon = icon("forward"), class = "btn-warning btn-block",
                      `data-toggle` = "tooltip", title = i18n$t("Skip if you want to explore all activities and risks"))
        ),
        column(4,
          actionButton(ns("ep23_continue"), i18n$t("Continue"), icon = icon("arrow-right"), class = "btn-primary btn-block",
                      `data-toggle` = "tooltip", title = i18n$t("Proceed to select knowledge topics"))
        )
      )
    )
  )
}

render_ep4 <- function(ns, rv) {
  fluidRow(
    column(12,
      div(
        h2(icon("book-open"), " ", i18n$t("Entry Point 4: Knowledge Domain")),
        span(
          icon("info-circle", style = "color: #3498db; cursor: help; margin-left: 10px;"),
          `data-toggle` = "tooltip",
          `data-placement` = "right",
          title = i18n$t("Select the knowledge domains and analytical approaches relevant to your question. This helps match you with appropriate analysis tools and frameworks.")
        )
      ),
      p(class = "text-muted", i18n$t("What topic areas are you interested in? (Select all that apply)")),
      br(),

      checkboxGroupInput(ns("ep4_topics"), NULL,
        choices = setNames(sapply(EP4_TOPICS, function(x) x$id),
                          sapply(EP4_TOPICS, function(x) i18n$t(x$label))),
        selected = rv$ep4_selected),

      br(),
      fluidRow(
        column(4,
          actionButton(ns("ep4_back"), i18n$t("Back"), icon = icon("arrow-left"), class = "btn-secondary btn-block",
                      `data-toggle` = "tooltip", title = i18n$t("Return to activities and risks"))
        ),
        column(4,
          actionButton(ns("ep4_skip"), i18n$t("Skip"), icon = icon("forward"), class = "btn-warning btn-block",
                      `data-toggle` = "tooltip", title = i18n$t("Skip to see all available tools"))
        ),
        column(4,
          actionButton(ns("ep4_get_recommendations"), i18n$t("Get Recommendations"),
                      icon = icon("magic"), class = "btn-success btn-lg btn-block",
                      `data-toggle` = "tooltip", title = i18n$t("Get personalized tool recommendations based on your pathway"))
        )
      )
    )
  )
}

render_recommendations_screen <- function(ns, rv) {
  # Get recommended tools based on pathway
  recommended_tools <- get_tool_recommendations(rv)

  fluidRow(
    column(12,
      h2(icon("star"), " ", i18n$t("Recommended Tools for Your Marine Management Question")),

      box(
        title = i18n$t("Your Pathway Summary"),
        status = "info",
        solidHeader = TRUE,
        width = 12,
        collapsible = TRUE,

        tags$ul(
          if (!is.null(rv$ep0_selected)) tags$li(strong(i18n$t("Role:"), " "),
            i18n$t(EP0_MANAGER_ROLES[[which(sapply(EP0_MANAGER_ROLES, function(x) x$id) == rv$ep0_selected)]]$label)),
          if (!is.null(rv$ep1_selected)) tags$li(strong(i18n$t("Need:"), " "),
            i18n$t(EP1_BASIC_NEEDS[[which(sapply(EP1_BASIC_NEEDS, function(x) x$id) == rv$ep1_selected)]]$label)),
          if (length(rv$ep2_selected) > 0) tags$li(strong(i18n$t("Activities:"), " "),
            paste(sapply(rv$ep2_selected, function(id)
              i18n$t(EP2_ACTIVITY_SECTORS[[which(sapply(EP2_ACTIVITY_SECTORS, function(x) x$id) == id)]]$label)), collapse = ", ")),
          if (length(rv$ep3_selected) > 0) tags$li(strong(i18n$t("Risks:"), " "),
            paste(sapply(rv$ep3_selected, function(id)
              i18n$t(EP3_RISKS_HAZARDS[[which(sapply(EP3_RISKS_HAZARDS, function(x) x$id) == id)]]$label)), collapse = ", ")),
          if (length(rv$ep4_selected) > 0) tags$li(strong(i18n$t("Topics:"), " "),
            paste(sapply(rv$ep4_selected, function(id)
              i18n$t(EP4_TOPICS[[which(sapply(EP4_TOPICS, function(x) x$id) == id)]]$label)), collapse = ", "))
        )
      ),

      h3(icon("tools"), " ", i18n$t("Recommended Workflow:")),
      p(class = "text-muted", i18n$t("Follow this sequence of tools to address your marine management question:")),

      # Render recommended tools in priority order
      lapply(seq_along(recommended_tools), function(i) {
        tool <- recommended_tools[[i]]
        priority_class <- if (i == 1) "success" else if (i == 2) "info" else "warning"
        priority_icon <- if (i == 1) "star" else if (i == 2) "check-circle" else "tools"
        priority_label <- if (i == 1) i18n$t("ep_priority_start_here")
                          else if (i == 2) i18n$t("ep_priority_next_step")
                          else i18n$t("ep_priority_also_relevant")

        div(
          class = paste0("alert alert-", priority_class),
          div(
            style = "display: flex; justify-content: space-between; align-items: center;",
            div(
              span(class = "badge badge-light", style = "font-size: 0.9em; margin-right: 10px;",
                   paste0(i, ". ", priority_label)),
              h4(style = "display: inline; margin: 0;", icon(priority_icon), " ", tool$name)
            )
          ),
          p(style = "margin-top: 10px; margin-bottom: 10px;", tool$description),
          div(
            style = "font-size: 0.85em; color: #666;",
            icon("clock"), " ", tool$time_required, " | ",
            icon("signal"), " ", i18n$t("Skill:"), " ", tool$skill_level, " | ",
            icon("graduation-cap"), " ", tool$use_case
          ),
          br(),
          actionButton(ns(paste0("goto_", tool$id)), paste(i18n$t("Go to"), tool$name),
                      class = paste0("btn-", priority_class),
                      icon = icon("arrow-right"))
        )
      }),

      hr(),
      div(
        style = "background: #f8f9fa; padding: 15px; border-radius: 5px;",
        h4(icon("lightbulb"), " ", i18n$t("Suggested Workflow:")),
        tags$ol(
          tags$li(strong(i18n$t("Start with PIMS:"), " "), i18n$t("Define your project goals, stakeholders, and timeline")),
          tags$li(strong(i18n$t("Quick start option:"), " "), i18n$t("Use Create SES with templates or AI assistant for rapid model building (beginner-friendly)")),
          tags$li(strong(i18n$t("Build your SES model:"), " "), i18n$t("Use ISA Data Entry to map DAPSI(W)R(M) elements with confidence levels (1-5) for each connection")),
          tags$li(strong(i18n$t("Visualize & Analyze:"), " "), i18n$t("Create CLD networks with confidence-based visual feedback, filter by confidence, and run analysis tools")),
          tags$li(strong(i18n$t("Refine & Communicate:"), " "), i18n$t("Simplify models and develop management scenarios"))
        ),
        tags$div(
          class = "alert alert-info",
          style = "margin-top: 15px; margin-bottom: 0;",
          icon("star"), " ",
          tags$strong(i18n$t("New in v1.2.0:"), " "),
          i18n$t("Confidence property system allows you to track data quality and certainty. Edges with low confidence appear more transparent, helping you identify areas needing more research.")
        )
      ),

      br(),
      fluidRow(
        column(6,
          actionButton(ns("start_over"), i18n$t("Start Over"), icon = icon("redo"), class = "btn-secondary btn-block",
                      `data-toggle` = "tooltip", title = i18n$t("ep_tooltip_begin_new_pathway"))
        ),
        column(6,
          actionButton(ns("export_pathway"), i18n$t("Export Pathway Report"), icon = icon("download"),
                      class = "btn-info btn-block",
                      `data-toggle` = "tooltip", title = i18n$t("ep_tooltip_download_pdf"))
        )
      )
    )
  )
}

# Helper function to recommend tools based on user pathway
get_tool_recommendations <- function(rv) {
  tools <- list()

  # PIMS - Recommended for project planning (especially for policy creators, advisors, educators)
  if (is.null(rv$ep0_selected) || rv$ep0_selected %in% c("policy_creator", "policy_advisor", "educator")) {
    tools[[length(tools) + 1]] <- list(
      id = "pims",
      name = "PIMS - Project Information Management",
      description = "Plan and track your marine management project. Define goals, stakeholders, timeline, and resources. Essential first step for structured project management.",
      time_required = "30-60 minutes",
      skill_level = "Beginner",
      use_case = "Project planning & stakeholder mapping",
      menu_id = "pims_project"
    )
  }

  # Create SES - Quick start with templates or AI
  tools[[length(tools) + 1]] <- list(
    id = "create_ses",
    name = "Create SES (Quick Start)",
    description = "Quickly build your SES model using pre-built templates (fisheries, tourism, aquaculture, pollution, climate) or AI-assisted creation. Perfect for getting started fast or learning the framework.",
    time_required = "15-45 minutes",
    skill_level = "Beginner",
    use_case = "Fast SES creation with templates or AI",
    menu_id = "create_ses"
  )

  # ISA Data Entry - Core tool for all pathways
  tools[[length(tools) + 1]] <- list(
    id = "isa",
    name = "ISA Data Entry (DAPSI(W)R(M) Framework)",
    description = "Build your social-ecological system model by entering Drivers, Activities, Pressures, State changes, Impacts, Welfare effects, Responses, and Measures. Now with confidence levels (1-5) for connections to track data quality and certainty. The foundation for all system analysis.",
    time_required = "1-3 hours",
    skill_level = "Intermediate",
    use_case = "Detailed SES model construction with confidence tracking",
    menu_id = "isa"
  )

  # CLD Visualization - Follows ISA
  tools[[length(tools) + 1]] <- list(
    id = "cld",
    name = "CLD Network Visualization",
    description = "Visualize your SES as an interactive causal loop diagram with collapsible controls and confidence-based visual feedback. Filter by confidence levels, explore connections, and identify feedback mechanisms. Clean, focused interface for maximum visualization space.",
    time_required = "15-30 minutes",
    skill_level = "Beginner-Intermediate",
    use_case = "Interactive system visualization with confidence filtering",
    menu_id = "cld_viz"
  )

  # Topics-based recommendations
  if (length(rv$ep4_selected) > 0) {
    topic_ids <- rv$ep4_selected

    # If Ecosystem Structure & Functioning selected → Loop Detection
    if (any(grepl("ecosystem_structure|basic_concepts", topic_ids))) {
      tools[[length(tools) + 1]] <- list(
        id = "loops",
        name = "Loop Detection Analysis",
        description = "Identify reinforcing and balancing feedback loops in your system. Understand system dynamics and potential tipping points.",
        time_required = "30-60 minutes",
        skill_level = "Intermediate-Advanced",
        use_case = "Feedback loop identification",
        menu_id = "analysis_loops"
      )
    }

    # If Methods/Tools selected → Network Metrics
    if (any(grepl("methods_tools|scientific_skills", topic_ids))) {
      tools[[length(tools) + 1]] <- list(
        id = "metrics",
        name = "Network Metrics Analysis",
        description = "Calculate centrality measures, identify key nodes, and analyze network structure. Advanced quantitative analysis of system connectivity.",
        time_required = "20-45 minutes",
        skill_level = "Advanced",
        use_case = "Quantitative network analysis",
        menu_id = "analysis_metrics"
      )
    }

    # If Climate Change or Other Anthropogenic Effects → BOT Analysis
    if (any(grepl("climate_change|anthropogenic_effects|ecosystem_recovery", topic_ids))) {
      tools[[length(tools) + 1]] <- list(
        id = "bot",
        name = "BOT - Behaviour Over Time Analysis",
        description = "Analyze temporal trends and patterns in your system. Identify long-term changes, seasonal patterns, and emerging issues.",
        time_required = "45-90 minutes",
        skill_level = "Intermediate-Advanced",
        use_case = "Temporal trend analysis",
        menu_id = "analysis_bot"
      )
    }

    # If Governance/Policy selected → Response & Validation
    if (any(grepl("policy_|governance|marine_planning", topic_ids))) {
      tools[[length(tools) + 1]] <- list(
        id = "response",
        name = "Response Measures & Validation",
        description = "Design management scenarios and validate responses. Evaluate effectiveness of different management measures using stakeholder input.",
        time_required = "1-2 hours",
        skill_level = "Advanced",
        use_case = "Management scenario development",
        menu_id = "response_validation"
      )
    }
  }

  # Model Simplification - Recommended for communication needs
  if (!is.null(rv$ep0_selected) && rv$ep0_selected %in% c("policy_creator", "educator", "engo")) {
    tools[[length(tools) + 1]] <- list(
      id = "simplification",
      name = "Model Simplification Tools",
      description = "Simplify complex networks for easier communication. Reduce cognitive load while retaining key system dynamics.",
      time_required = "30-45 minutes",
      skill_level = "Intermediate",
      use_case = "Model simplification & communication",
      menu_id = "analysis_simplify"
    )
  }

  # Ensure we have at least 3 recommendations
  if (length(tools) < 3) {
    # Add CLD if not already there
    if (!any(sapply(tools, function(t) t$id == "cld"))) {
      tools[[length(tools) + 1]] <- list(
        id = "cld",
        name = "CLD Network Visualization",
        description = "Visualize your SES as an interactive causal loop diagram.",
        time_required = "15-30 minutes",
        skill_level = "Beginner-Intermediate",
        use_case = "System visualization",
        menu_id = "cld_viz"
      )
    }
  }

  return(tools)
}
