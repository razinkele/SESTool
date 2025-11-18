library(shiny)
library(shinyjs)

# modules/template_ses_module.R
# Template-Based SES Creation Module
# Purpose: Allow users to start from pre-built SES templates

# Source dependencies
source("modules/connection_review_tabbed.R", local = TRUE)
source("functions/template_loader.R", local = TRUE)

# ============================================================================
# TEMPLATE LIBRARY
# ============================================================================

# Load templates from JSON files in data/ directory
# Templates are automatically discovered and loaded from data/*_SES_Template.json files
# This approach allows:
# - Easy template maintenance (edit JSON instead of R code)
# - Dynamic template addition (just add new JSON file)
# - Comprehensive template data (JSON files contain full DAPSI(W)R(M) details)
#
# To add a new template:
# 1. Create a JSON file in data/ folder: YourTemplate_SES_Template.json
# 2. Follow the JSON structure (see existing templates for examples)
# 3. The template will be automatically loaded on next app start
#
# Supported JSON formats:
# - Format 1 (comprehensive): {"dapsiwrm_framework": {...}, "template_name": "...", ...}
# - Format 2 (simplified): {"elements": {...}, "template_info": {...}, ...}

cat("Loading SES templates from JSON files...\n")
ses_templates <- load_all_templates("data")
cat("Loaded", length(ses_templates), "templates:", paste(names(ses_templates), collapse=", "), "\n\n")


# ============================================================================
# UI FUNCTION
# ============================================================================

template_ses_ui <- function(id, i18n) {
  ns <- NS(id)

  fluidPage(
    useShinyjs(),
    shiny.i18n::usei18n(i18n),

    # Custom CSS
    tags$head(
      tags$style(HTML("
        .template-container {
          max-width: 1400px;
          margin: 0 auto;
          padding: 20px;
        }
        .template-card {
          background: white;
          border: 2px solid #e0e0e0;
          border-radius: 12px;
          padding: 15px;
          margin: 10px 0;
          cursor: pointer;
          transition: all 0.3s ease;
          box-shadow: 0 2px 8px rgba(0,0,0,0.1);
        }
        .template-card:hover {
          border-color: #667eea;
          box-shadow: 0 6px 16px rgba(102,126,234,0.2);
          transform: translateY(-3px);
        }
        .template-card.selected {
          border-color: #27ae60;
          background: linear-gradient(135deg, #f8fff9 0%, #e8f8f0 100%);
          box-shadow: 0 6px 20px rgba(39,174,96,0.3);
        }
        .template-icon-large {
          font-size: 32px;
          color: #667eea;
          text-align: center;
          margin-bottom: 10px;
        }
        .template-card.selected .template-icon-large {
          color: #27ae60;
        }
        .template-name {
          font-size: 18px;
          font-weight: 700;
          color: #2c3e50;
          margin-bottom: 8px;
        }
        .template-description {
          color: #34495e;
          font-size: 13px;
          line-height: 1.5;
        }
        .template-category-badge {
          display: inline-block;
          background: #667eea;
          color: white;
          padding: 4px 12px;
          border-radius: 12px;
          font-size: 11px;
          font-weight: 600;
          margin-top: 10px;
        }
        .template-preview {
          background: #f8f9fa;
          border-radius: 8px;
          padding: 20px;
          margin: 20px 0;
        }
        .preview-section {
          margin: 15px 0;
        }
        .preview-section h6 {
          color: #667eea;
          font-weight: 700;
          margin-bottom: 10px;
        }
        .element-tag {
          display: inline-block;
          background: white;
          border: 1px solid #ddd;
          padding: 5px 12px;
          border-radius: 15px;
          margin: 3px;
          font-size: 12px;
        }
      "))
    ),

    div(class = "template-container",
      # Header
      uiOutput(ns("template_header")),

      # Three-column layout: Template cards + Preview/Actions + Connection review
      fluidRow(
        # Column 1: Template cards (3 columns)
        column(3,
          uiOutput(ns("templates_heading")),
          uiOutput(ns("template_cards"))
        ),

        # Column 2: Template preview and action buttons (2 columns)
        column(2,
          uiOutput(ns("template_actions"))
        ),

        # Column 3: Connection review (7 columns)
        column(7,
          uiOutput(ns("connection_review_section"))
        )
      )
    )
  )
}

# ============================================================================
# SERVER FUNCTION
# ============================================================================

template_ses_server <- function(id, project_data_reactive, parent_session = NULL, event_bus = NULL, i18n) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # Reactive values
    rv <- reactiveValues(
      selected_template = NULL,
      show_connection_review = FALSE,
      template_connections = NULL,
      review_mode = NULL,  # "use" or "customize"
      pending_template_switch = NULL  # Stores template ID when awaiting confirmation to switch
    )

    # Render header
    output$template_header <- renderUI({
      create_module_header(
        ns = ns,
        title_key = "Template-Based SES Creation",
        subtitle_key = "Choose a pre-built template that matches your scenario and customize it to your needs",
        help_id = "help_template_ses",
        i18n = i18n
      )
    })

    # Render templates heading
    output$templates_heading <- renderUI({
      h4(icon("folder-open"), " ", i18n$t("Available Templates"))
    })

    # Render template actions
    output$template_actions <- renderUI({
      if (!is.null(rv$selected_template)) {
        div(
          wellPanel(
            style = "padding: 15px; margin-top: 0;",
            h6(icon("eye"), " ", i18n$t("Preview"), style = "margin-bottom: 10px; font-weight: bold;"),
            uiOutput(ns("template_preview_compact"))
          ),
          wellPanel(
            style = "padding: 15px;",
            h6(icon("cog"), " ", i18n$t("Actions"), style = "margin-bottom: 10px; font-weight: bold;"),
            tags$div(
              `data-toggle` = "tooltip",
              `data-placement` = "right",
              title = i18n$t("Preview all template connections before loading. Review connections to understand the causal links in the SES model."),
              actionButton(ns("review_connections"),
                           i18n$t("Review"),
                           icon = icon("search"),
                           class = "btn btn-info btn-block",
                           style = "margin-bottom: 8px; font-size: 13px; padding: 8px;")
            ),
            tags$div(
              `data-toggle` = "tooltip",
              `data-placement` = "right",
              title = i18n$t("Load the template as-is without reviewing connections. All predefined connections will be imported directly into your project."),
              actionButton(ns("load_template"),
                           i18n$t("Load"),
                           icon = icon("download"),
                           class = "btn btn-success btn-block",
                           style = "margin-bottom: 8px; font-size: 13px; padding: 8px;")
            ),
            tags$div(
              `data-toggle` = "tooltip",
              `data-placement` = "right",
              title = i18n$t("Review and customize template connections. Approve, reject, or modify individual connections before loading into your project."),
              actionButton(ns("customize_template"),
                           i18n$t("Customize"),
                           icon = icon("edit"),
                           class = "btn btn-primary btn-block",
                           style = "font-size: 13px; padding: 8px;")
            )
          )
        )
      }
    })

    # Render template cards
    output$template_cards <- renderUI({
      lapply(names(ses_templates), function(template_id) {
        template <- ses_templates[[template_id]]

        div(class = "template-card", id = ns(paste0("card_", template_id)),
            onclick = sprintf("Shiny.setInputValue('%s', '%s', {priority: 'event'})",
                            ns("template_selected"), template_id),
          fluidRow(
            column(3,
              div(class = "template-icon-large",
                icon(template$icon)
              )
            ),
            column(9,
              div(style = "display: flex; justify-content: space-between; align-items: center;",
                div(class = "template-name", i18n$t(template$name_key)),
                actionButton(ns(paste0("preview_", template_id)),
                            NULL,
                            icon = icon("eye"),
                            class = "btn btn-link btn-sm",
                            style = "padding: 2px 8px; color: #666;",
                            title = i18n$t("View detailed preview"),
                            onclick = "event.stopPropagation();")
              ),
              div(class = "template-description", i18n$t(template$description_key)),
              span(class = "template-category-badge", i18n$t(template$category_key))
            )
          )
        )
      })
    })

    # Track template selection with warning if switching templates
    observeEvent(input$template_selected, {
      new_template <- input$template_selected

      # Check if user is switching from an existing template with work in progress
      if (!is.null(rv$selected_template) &&
          rv$selected_template != new_template &&
          !is.null(rv$template_connections) &&
          length(rv$template_connections) > 0) {

        # Show confirmation modal
        showModal(modalDialog(
          title = tags$h4(icon("exclamation-triangle"), " ", i18n$t("Switch Template?")),
          size = "m",
          easyClose = FALSE,

          tags$div(
            style = "padding: 15px;",
            tags$p(
              tags$strong(i18n$t("Warning:")), " ",
              i18n$t("You are about to switch to a different template.")
            ),
            tags$p(
              i18n$t("All work on the current template will be lost, including:"),
              tags$ul(
                tags$li(i18n$t("Connection reviews and amendments")),
                tags$li(i18n$t("Approved and rejected connections")),
                tags$li(i18n$t("Any customizations made"))
              )
            ),
            tags$p(
              style = "color: #d9534f; font-weight: bold;",
              i18n$t("This action cannot be undone.")
            ),
            tags$p(
              i18n$t("Are you sure you want to start from scratch with the new template?")
            )
          ),

          footer = tagList(
            actionButton(ns("cancel_template_switch"),
                        i18n$t("Cancel"),
                        class = "btn-default"),
            actionButton(ns("confirm_template_switch"),
                        i18n$t("Yes, Switch Template"),
                        class = "btn-danger",
                        icon = icon("exchange-alt"))
          )
        ))

        # Store the pending template selection
        rv$pending_template_switch <- new_template

      } else {
        # No work in progress, switch immediately
        rv$selected_template <- new_template

        # Update card styling
        shinyjs::runjs(sprintf("
          $('.template-card').removeClass('selected');
          $('#%s').addClass('selected');
        ", ns(paste0("card_", new_template))))
      }
    })

    # Handle template switch confirmation
    observeEvent(input$confirm_template_switch, {
      # Clear all work in progress
      rv$template_connections <- NULL
      rv$show_connection_review <- FALSE
      rv$review_mode <- NULL

      # Switch to new template
      rv$selected_template <- rv$pending_template_switch
      rv$pending_template_switch <- NULL

      # Update card styling
      shinyjs::runjs(sprintf("
        $('.template-card').removeClass('selected');
        $('#%s').addClass('selected');
      ", ns(paste0("card_", rv$selected_template))))

      removeModal()

      showNotification(
        i18n$t("Template switched. Starting fresh."),
        type = "warning",
        duration = 3
      )
    })

    # Handle template switch cancellation
    observeEvent(input$cancel_template_switch, {
      rv$pending_template_switch <- NULL
      removeModal()
    })

    # Preview button observers for each template
    lapply(names(ses_templates), function(template_id) {
      observeEvent(input[[paste0("preview_", template_id)]], {
        template <- ses_templates[[template_id]]

        # Show detailed preview modal
        showModal(modalDialog(
          title = tags$h3(icon(template$icon), " ", i18n$t(template$name_key)),
          size = "l",
          easyClose = TRUE,

          tags$div(
            style = "padding: 20px;",

            # Description
            tags$div(
              style = "background: #f8f9fa; padding: 15px; border-radius: 8px; margin-bottom: 20px;",
              tags$p(
                style = "font-size: 15px; margin: 0;",
                tags$strong(i18n$t("Description:")), " ",
                i18n$t(template$description_key)
              ),
              tags$p(
                style = "font-size: 13px; margin: 10px 0 0 0; color: #666;",
                tags$span(class = "badge", style = "background: #667eea; color: white;",
                          i18n$t(template$category_key))
              )
            ),

            # Template contents in columns
            fluidRow(
              column(6,
                tags$div(
                  style = "background: white; border: 1px solid #ddd; border-radius: 8px; padding: 15px; margin-bottom: 15px;",
                  tags$h5(icon("arrow-down"), " ", i18n$t("Drivers"), " (", nrow(template$drivers), ")",
                          style = "color: #667eea; margin-top: 0;"),
                  if (nrow(template$drivers) > 0) {
                    lapply(1:min(5, nrow(template$drivers)), function(i) {
                      tags$div(
                        style = "padding: 5px 0; border-bottom: 1px solid #f0f0f0;",
                        tags$strong(template$drivers$Name[i]),
                        tags$br(),
                        tags$small(style = "color: #666;", template$drivers$Description[i])
                      )
                    })
                  } else {
                    tags$p(style = "color: #999; font-style: italic;", i18n$t("None defined"))
                  },
                  if (nrow(template$drivers) > 5) {
                    tags$small(style = "color: #666; font-style: italic;",
                              sprintf(i18n$t("... and %d more"), nrow(template$drivers) - 5))
                  }
                ),

                tags$div(
                  style = "background: white; border: 1px solid #ddd; border-radius: 8px; padding: 15px; margin-bottom: 15px;",
                  tags$h5(icon("exclamation-triangle"), " ", i18n$t("Pressures"), " (", nrow(template$pressures), ")",
                          style = "color: #dc3545; margin-top: 0;"),
                  if (nrow(template$pressures) > 0) {
                    lapply(1:min(5, nrow(template$pressures)), function(i) {
                      tags$div(
                        style = "padding: 5px 0; border-bottom: 1px solid #f0f0f0;",
                        tags$strong(template$pressures$Name[i]),
                        tags$br(),
                        tags$small(style = "color: #666;", template$pressures$Description[i])
                      )
                    })
                  } else {
                    tags$p(style = "color: #999; font-style: italic;", i18n$t("None defined"))
                  },
                  if (nrow(template$pressures) > 5) {
                    tags$small(style = "color: #666; font-style: italic;",
                              sprintf(i18n$t("... and %d more"), nrow(template$pressures) - 5))
                  }
                ),

                tags$div(
                  style = "background: white; border: 1px solid #ddd; border-radius: 8px; padding: 15px;",
                  tags$h5(icon("leaf"), " ", i18n$t("Ecosystem Services"), " (", nrow(template$ecosystem_services), ")",
                          style = "color: #28a745; margin-top: 0;"),
                  if (nrow(template$ecosystem_services) > 0) {
                    lapply(1:min(5, nrow(template$ecosystem_services)), function(i) {
                      tags$div(
                        style = "padding: 5px 0; border-bottom: 1px solid #f0f0f0;",
                        tags$strong(template$ecosystem_services$Name[i]),
                        tags$br(),
                        tags$small(style = "color: #666;", template$ecosystem_services$Description[i])
                      )
                    })
                  } else {
                    tags$p(style = "color: #999; font-style: italic;", i18n$t("None defined"))
                  },
                  if (nrow(template$ecosystem_services) > 5) {
                    tags$small(style = "color: #666; font-style: italic;",
                              sprintf(i18n$t("... and %d more"), nrow(template$ecosystem_services) - 5))
                  }
                )
              ),

              column(6,
                tags$div(
                  style = "background: white; border: 1px solid #ddd; border-radius: 8px; padding: 15px; margin-bottom: 15px;",
                  tags$h5(icon("running"), " ", i18n$t("Activities"), " (", nrow(template$activities), ")",
                          style = "color: #ffc107; margin-top: 0;"),
                  if (nrow(template$activities) > 0) {
                    lapply(1:min(5, nrow(template$activities)), function(i) {
                      tags$div(
                        style = "padding: 5px 0; border-bottom: 1px solid #f0f0f0;",
                        tags$strong(template$activities$Name[i]),
                        tags$br(),
                        tags$small(style = "color: #666;", template$activities$Description[i])
                      )
                    })
                  } else {
                    tags$p(style = "color: #999; font-style: italic;", i18n$t("None defined"))
                  },
                  if (nrow(template$activities) > 5) {
                    tags$small(style = "color: #666; font-style: italic;",
                              sprintf(i18n$t("... and %d more"), nrow(template$activities) - 5))
                  }
                ),

                tags$div(
                  style = "background: white; border: 1px solid #ddd; border-radius: 8px; padding: 15px;",
                  tags$h5(icon("fish"), " ", i18n$t("Marine Processes and Functions"), " (", nrow(template$marine_processes), ")",
                          style = "color: #17a2b8; margin-top: 0;"),
                  if (nrow(template$marine_processes) > 0) {
                    lapply(1:min(5, nrow(template$marine_processes)), function(i) {
                      tags$div(
                        style = "padding: 5px 0; border-bottom: 1px solid #f0f0f0;",
                        tags$strong(template$marine_processes$Name[i]),
                        tags$br(),
                        tags$small(style = "color: #666;", template$marine_processes$Description[i])
                      )
                    })
                  } else {
                    tags$p(style = "color: #999; font-style: italic;", i18n$t("None defined"))
                  },
                  if (nrow(template$marine_processes) > 5) {
                    tags$small(style = "color: #666; font-style: italic;",
                              sprintf(i18n$t("... and %d more"), nrow(template$marine_processes) - 5))
                  }
                ),

                tags$div(
                  style = "background: white; border: 1px solid #ddd; border-radius: 8px; padding: 15px;",
                  tags$h5(icon("heart"), " ", i18n$t("Welfare"), " (", nrow(template$goods_benefits), ")",
                          style = "color: #e83e8c; margin-top: 0;"),
                  if (nrow(template$goods_benefits) > 0) {
                    lapply(1:min(5, nrow(template$goods_benefits)), function(i) {
                      tags$div(
                        style = "padding: 5px 0; border-bottom: 1px solid #f0f0f0;",
                        tags$strong(template$goods_benefits$Name[i]),
                        tags$br(),
                        tags$small(style = "color: #666;", template$goods_benefits$Description[i])
                      )
                    })
                  } else {
                    tags$p(style = "color: #999; font-style: italic;", i18n$t("None defined"))
                  },
                  if (nrow(template$goods_benefits) > 5) {
                    tags$small(style = "color: #666; font-style: italic;",
                              sprintf(i18n$t("... and %d more"), nrow(template$goods_benefits) - 5))
                  }
                )
              )
            ),

            # Connection statistics
            tags$div(
              style = "background: #e3f2fd; padding: 15px; border-radius: 8px; margin-top: 20px;",
              tags$h5(icon("link"), " ", i18n$t("Connections"), style = "margin-top: 0; color: #1976d2;"),
              tags$p(
                style = "margin: 0;",
                sprintf(i18n$t("This template includes %d predefined connections between elements."),
                        length(parse_template_connections(template)))
              )
            )
          ),

          footer = tagList(
            actionButton(ns(paste0("select_from_preview_", template_id)),
                        i18n$t("Select This Template"),
                        class = "btn-primary",
                        icon = icon("check")),
            tags$button(
              type = "button",
              class = "btn btn-default",
              `data-dismiss` = "modal",
              i18n$t("Close")
            )
          )
        ))
      })

      # Handle selection from preview modal
      observeEvent(input[[paste0("select_from_preview_", template_id)]], {
        rv$selected_template <- template_id
        removeModal()

        # Update card styling
        shinyjs::runjs(sprintf("
          $('.template-card').removeClass('selected');
          $('#%s').addClass('selected');
        ", ns(paste0("card_", template_id))))

        showNotification(
          sprintf(i18n$t("Template '%s' selected"), i18n$t(ses_templates[[template_id]]$name_key)),
          type = "message",
          duration = 2
        )
      })
    })

    # Template preview (full version - not used in current layout)
    output$template_preview <- renderUI({
      req(rv$selected_template)

      template <- ses_templates[[rv$selected_template]]

      div(class = "template-preview",
        div(class = "preview-section",
          h6(icon("arrow-down"), " ", i18n$t("Drivers"), " (", nrow(template$drivers), ")"),
          lapply(template$drivers$Name, function(name) {
            span(class = "element-tag", name)
          })
        ),
        div(class = "preview-section",
          h6(icon("running"), " ", i18n$t("Activities"), " (", nrow(template$activities), ")"),
          lapply(template$activities$Name, function(name) {
            span(class = "element-tag", name)
          })
        ),
        div(class = "preview-section",
          h6(icon("exclamation-triangle"), " ", i18n$t("Pressures"), " (", nrow(template$pressures), ")"),
          lapply(template$pressures$Name, function(name) {
            span(class = "element-tag", name)
          })
        ),
        div(class = "preview-section",
          h6(icon("leaf"), " ", i18n$t("Ecosystem Services"), " (", nrow(template$ecosystem_services), ")"),
          lapply(template$ecosystem_services$Name, function(name) {
            span(class = "element-tag", name)
          })
        )
      )
    })

    # Compact template preview (used in side column)
    output$template_preview_compact <- renderUI({
      req(rv$selected_template)

      template <- ses_templates[[rv$selected_template]]

      div(style = "font-size: 11px;",
        div(style = "margin-bottom: 5px;",
          strong(icon("arrow-down"), " ", i18n$t("Drivers"), ": "), nrow(template$drivers)
        ),
        div(style = "margin-bottom: 5px;",
          strong(icon("running"), " ", i18n$t("Activities"), ": "), nrow(template$activities)
        ),
        div(style = "margin-bottom: 5px;",
          strong(icon("exclamation-triangle"), " ", i18n$t("Pressures"), ": "), nrow(template$pressures)
        ),
        div(style = "margin-bottom: 5px;",
          strong(icon("leaf"), " ", i18n$t("ES"), ": "), nrow(template$ecosystem_services)
        ),
        div(style = "margin-bottom: 0;",
          strong(icon("gift"), " ", i18n$t("G&B"), ": "), nrow(template$goods_benefits)
        )
      )
    })

    # Help Modal ----
    create_help_observer(
      input, "help_template_ses", "template_ses_guide_title",
      tagList(
        h4(i18n$t("template_ses_guide_what_is_title")),
        p(i18n$t("template_ses_guide_what_is_p1")),
        h4(i18n$t("template_ses_guide_how_to_use_title")),
        tags$ol(
          tags$li(i18n$t("template_ses_guide_step1")),
          tags$li(i18n$t("template_ses_guide_step2")),
          tags$li(i18n$t("template_ses_guide_step3"))
        )
      ),
      i18n
    )

    # Helper function to parse template adjacency matrices into connections
    parse_template_connections <- function(template) {
      connections <- list()

      if (is.null(template$adjacency_matrices)) return(connections)

      # Map matrix names to connection types
      # Matrix naming convention: [from]_[to] (e.g., a_d means Activity → Driver)
      matrix_type_map <- list(
        # Activities ↔ Drivers
        a_d = list(from = "activity", to = "driver"),
        d_a = list(from = "driver", to = "activity"),

        # Pressures ↔ Activities
        p_a = list(from = "pressure", to = "activity"),
        a_p = list(from = "activity", to = "pressure"),

        # Marine Processes ↔ Pressures
        mpf_p = list(from = "marine_process", to = "pressure"),
        p_mpf = list(from = "pressure", to = "marine_process"),

        # Ecosystem Services ↔ Marine Processes
        es_mpf = list(from = "ecosystem_service", to = "marine_process"),
        mpf_es = list(from = "marine_process", to = "ecosystem_service"),

        # Goods & Benefits ↔ Ecosystem Services
        gb_es = list(from = "goods_benefit", to = "ecosystem_service"),
        es_gb = list(from = "ecosystem_service", to = "goods_benefit"),

        # Drivers ↔ Goods & Benefits (feedback loops)
        d_gb = list(from = "driver", to = "goods_benefit"),
        gb_d = list(from = "goods_benefit", to = "driver"),

        # Responses - Management intervention matrices
        gb_r = list(from = "goods_benefit", to = "response"),  # Welfare triggers responses
        r_d = list(from = "response", to = "driver"),          # Responses regulate drivers
        r_a = list(from = "response", to = "activity"),        # Responses restrict activities
        r_p = list(from = "response", to = "pressure")         # Responses reduce pressures
      )

      # Process each adjacency matrix
      for (matrix_name in names(template$adjacency_matrices)) {
        mat <- template$adjacency_matrices[[matrix_name]]

        # Get connection types for this matrix
        type_info <- matrix_type_map[[matrix_name]]
        if (is.null(type_info)) {
          # Unknown matrix type, skip or use generic
          next
        }

        # Get row and column names
        from_names <- rownames(mat)
        to_names <- colnames(mat)

        # Parse each non-empty cell
        for (i in seq_len(nrow(mat))) {
          for (j in seq_len(ncol(mat))) {
            cell_value <- mat[i, j]

            # Skip empty cells
            if (is.na(cell_value) || cell_value == "") next

            # Parse format: "+strength:confidence" or "-strength:confidence"
            polarity <- substr(cell_value, 1, 1)
            rest <- substr(cell_value, 2, nchar(cell_value))
            parts <- strsplit(rest, ":")[[1]]

            strength <- if (length(parts) >= 1) parts[1] else "medium"
            confidence <- if (length(parts) >= 2) as.integer(parts[2]) else 3

            # Create rationale based on polarity
            rationale <- if (polarity == "+") "drives/increases" else "affects/reduces"

            # Add connection with type information
            connections[[length(connections) + 1]] <- list(
              from_type = type_info$from,
              to_type = type_info$to,
              from_name = from_names[i],
              to_name = to_names[j],
              polarity = polarity,
              strength = strength,
              confidence = confidence,
              rationale = paste(from_names[i], rationale, to_names[j])
            )
          }
        }
      }

      return(connections)
    }

    # Review connections button - shows connection review pane
    observeEvent(input$review_connections, {
      req(rv$selected_template)

      template <- ses_templates[[rv$selected_template]]

      # Parse connections for review
      rv$template_connections <- parse_template_connections(template)
      rv$review_mode <- "review"
      rv$show_connection_review <- TRUE

      debug_log(sprintf("Parsed %d connections for review", length(rv$template_connections)), "TEMPLATE")
    })

    # Load template button - loads template as-is without review
    observeEvent(input$load_template, {
      req(rv$selected_template)

      debug_log("Load button clicked", "TEMPLATE")

      template <- ses_templates[[rv$selected_template]]

      # Load template data directly into project without review
      project_data <- isolate(project_data_reactive())

      debug_log("Got project data", "TEMPLATE")

      # Clear all existing ISA data before loading template
      project_data$data$isa_data <- list(
        drivers = NULL,
        activities = NULL,
        pressures = NULL,
        marine_processes = NULL,
        ecosystem_services = NULL,
        goods_benefits = NULL,
        responses = NULL,
        measures = NULL,
        adjacency_matrices = NULL
      )

      # Populate ISA data with template
      project_data$data$isa_data$drivers <- template$drivers
      project_data$data$isa_data$activities <- template$activities
      project_data$data$isa_data$pressures <- template$pressures
      project_data$data$isa_data$marine_processes <- template$marine_processes
      project_data$data$isa_data$ecosystem_services <- template$ecosystem_services
      project_data$data$isa_data$goods_benefits <- template$goods_benefits
      project_data$data$isa_data$responses <- template$responses
      project_data$data$isa_data$adjacency_matrices <- template$adjacency_matrices

      # Update metadata
      project_data$data$metadata$template_used <- i18n$t(template$name_key)
      project_data$data$metadata$connections_reviewed <- FALSE
      project_data$data$metadata$source <- "template_direct_load"  # Flag to prevent AI ISA auto-save overwrite
      project_data$last_modified <- Sys.time()

      debug_log("Updated project data", "TEMPLATE")

      # Save the modified data back to the reactive value
      project_data_reactive(project_data)

      debug_log("Saved project data", "TEMPLATE")

      # Emit ISA change event to trigger CLD regeneration
      if (!is.null(event_bus)) {
        event_bus$emit_isa_change()
        debug_log("Emitted ISA change event for direct load", "TEMPLATE")
      }

      # Show success message
      showNotification(
        sprintf(i18n$t("Template %s loaded!"), i18n$t(template$name_key)),
        type = "message",
               duration = 5
      )

      debug_log("Notification shown", "TEMPLATE")

      # Navigate to dashboard
      if (!is.null(parent_session)) {
        debug_log("Navigating to dashboard", "TEMPLATE")
        updateTabItems(parent_session, "sidebar_menu", "dashboard")
      }

      debug_log("Load complete", "TEMPLATE")
    }, ignoreInit = TRUE, ignoreNULL = TRUE)

    # Customize template button - now shows connection review
    observeEvent(input$customize_template, {
      req(rv$selected_template)

      template <- ses_templates[[rv$selected_template]]

      # Parse connections for review
      rv$template_connections <- parse_template_connections(template)
      rv$review_mode <- "customize"
      rv$show_connection_review <- TRUE

      debug_log(sprintf("Parsed %d connections for customization review", length(rv$template_connections)), "TEMPLATE")
    })

    # Connection review section (displayed in right column)
    output$connection_review_section <- renderUI({
      if (!rv$show_connection_review) {
        return(
          div(style = "padding: 40px; text-align: center; color: #999;",
            icon("arrow-left", style = "font-size: 48px; margin-bottom: 20px;"),
            h5(i18n$t("Select a template and click 'Review' to preview connections")),
            p(i18n$t("Or click 'Load' to load it as-is without review"))
          )
        )
      }

      req(rv$selected_template)
      template <- ses_templates[[rv$selected_template]]

      div(
        # Compact header matching card width
        div(
          style = "max-width: 600px; padding: 15px; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; border-radius: 8px; margin-bottom: 15px;",
          h5(icon("link"), " ", i18n$t("Connection Review"), style = "margin: 0; font-weight: bold;"),
          p(style = "margin: 5px 0 0 0; font-size: 12px;",
            sprintf(i18n$t("%d connections from %s template"),
                    length(rv$template_connections),
                    i18n$t(template$name_key)))
        ),

        # Tabbed connection review component (organized by DAPSI(W)R(M) stages)
        connection_review_tabbed_ui(ns("template_conn_review"), i18n),

        br(),
        # Action buttons matching card width
        div(style = "max-width: 600px;",
          fluidRow(
            column(6,
              actionButton(ns("cancel_review"),
                          i18n$t("Cancel"),
                          icon = icon("times"),
                          class = "btn-secondary btn-lg btn-block")
            ),
            column(6,
              actionButton(ns("finalize_template"),
                          if (rv$review_mode == "customize") i18n$t("Customize Template") else i18n$t("Load Template"),
                          icon = icon("check-circle"),
                          class = "btn-success btn-lg btn-block")
            )
          )
        )
      )
    })

    # Connection review server (tabbed by DAPSI(W)R(M) stages)
    review_status <- connection_review_tabbed_server(
      "template_conn_review",
      connections_reactive = reactive({ rv$template_connections }),
      i18n = i18n,
      on_amend = function(idx, polarity, strength, confidence) {
        # Update the connection when user amends it
        debug_log(sprintf("Connection #%d amended: %s, %s, %d", idx, polarity, strength, confidence), "TEMPLATE")
        rv$template_connections[[idx]]$polarity <- polarity
        rv$template_connections[[idx]]$strength <- strength
        rv$template_connections[[idx]]$confidence <- confidence

        # Update rationale
        rationale <- if (polarity == "+") "drives/increases" else "affects/reduces"
        rv$template_connections[[idx]]$rationale <- paste(
          rv$template_connections[[idx]]$from_name,
          rationale,
          rv$template_connections[[idx]]$to_name
        )
      }
    )

    # Cancel review button
    observeEvent(input$cancel_review, {
      rv$show_connection_review <- FALSE
      rv$template_connections <- NULL
      rv$review_mode <- NULL
    })

    # Finalize template button
    observeEvent(input$finalize_template, {
      req(rv$selected_template, rv$template_connections)

      template <- ses_templates[[rv$selected_template]]

      # Get review status
      status <- review_status()
      approved_idx <- status$approved
      rejected_idx <- status$rejected
      amended_data <- status$amended_data

      # Filter connections: keep only approved (or non-rejected if nothing explicitly approved)
      if (length(approved_idx) > 0) {
        # User explicitly approved some - use only those
        final_connections <- rv$template_connections[approved_idx]
      } else if (length(rejected_idx) > 0) {
        # User rejected some but didn't approve others - keep non-rejected
        keep_idx <- setdiff(seq_along(rv$template_connections), rejected_idx)
        final_connections <- rv$template_connections[keep_idx]
      } else {
        # No approvals or rejections - keep all
        final_connections <- rv$template_connections
      }

      debug_log(sprintf("Finalizing with %d of %d connections (rejected: %d)",
                  length(final_connections),
                  length(rv$template_connections),
                  length(rejected_idx)), "TEMPLATE")

      # Load template data into project
      project_data <- project_data_reactive()

      # Clear all existing ISA data before loading template
      project_data$data$isa_data <- list(
        drivers = NULL,
        activities = NULL,
        pressures = NULL,
        marine_processes = NULL,
        ecosystem_services = NULL,
        goods_benefits = NULL,
        responses = NULL,
        measures = NULL,
        adjacency_matrices = NULL
      )

      # Populate ISA data with template
      project_data$data$isa_data$drivers <- template$drivers
      project_data$data$isa_data$activities <- template$activities
      project_data$data$isa_data$pressures <- template$pressures
      project_data$data$isa_data$marine_processes <- template$marine_processes
      project_data$data$isa_data$ecosystem_services <- template$ecosystem_services
      project_data$data$isa_data$goods_benefits <- template$goods_benefits
      project_data$data$isa_data$responses <- template$responses

      # Rebuild adjacency matrices from approved connections
      # Initialize empty matrices
      adj_matrices <- list(
        gb_es = matrix("", nrow = nrow(template$goods_benefits), ncol = nrow(template$ecosystem_services),
                      dimnames = list(template$goods_benefits$Name, template$ecosystem_services$Name)),
        es_mpf = matrix("", nrow = nrow(template$ecosystem_services), ncol = nrow(template$marine_processes),
                       dimnames = list(template$ecosystem_services$Name, template$marine_processes$Name)),
        mpf_p = matrix("", nrow = nrow(template$marine_processes), ncol = nrow(template$pressures),
                      dimnames = list(template$marine_processes$Name, template$pressures$Name)),
        p_a = matrix("", nrow = nrow(template$pressures), ncol = nrow(template$activities),
                    dimnames = list(template$pressures$Name, template$activities$Name)),
        a_d = matrix("", nrow = nrow(template$activities), ncol = nrow(template$drivers),
                    dimnames = list(template$activities$Name, template$drivers$Name)),
        d_gb = matrix("", nrow = nrow(template$drivers), ncol = nrow(template$goods_benefits),
                     dimnames = list(template$drivers$Name, template$goods_benefits$Name))
      )

      # Fill matrices with approved connections
      for (conn in final_connections) {
        from <- conn$from_name
        to <- conn$to_name
        value <- paste0(conn$polarity, conn$strength, ":", conn$confidence)

        # Find which matrix this connection belongs to
        for (matrix_name in names(adj_matrices)) {
          mat <- adj_matrices[[matrix_name]]
          if (from %in% rownames(mat) && to %in% colnames(mat)) {
            adj_matrices[[matrix_name]][from, to] <- value
            break
          }
        }
      }

      project_data$data$isa_data$adjacency_matrices <- adj_matrices

      # Update metadata
      project_data$data$metadata$template_used <- i18n$t(template$name_key)
      project_data$data$metadata$connections_reviewed <- TRUE
      project_data$data$metadata$connections_count <- length(final_connections)
      project_data$data$metadata$source <- "template_reviewed_load"  # Flag to prevent AI ISA auto-save overwrite
      project_data$last_modified <- Sys.time()

      # Save the modified data back to the reactive value
      project_data_reactive(project_data)

      # Emit ISA change event to trigger CLD regeneration
      if (!is.null(event_bus)) {
        event_bus$emit_isa_change()
        debug_log(sprintf("Emitted ISA change event with %d connections", length(final_connections)), "TEMPLATE")
      }

      # Show success message
      showNotification(
        sprintf(i18n$t("Template %s loaded with %d connections!"),
                i18n$t(template$name_key),
                length(final_connections)),
        type = "message",
        duration = 5
      )

      # Navigate based on mode (store mode before resetting)
      current_mode <- rv$review_mode

      # Reset review state
      rv$show_connection_review <- FALSE
      rv$template_connections <- NULL
      rv$review_mode <- NULL

      if (!is.null(parent_session)) {
        if (current_mode == "customize") {
          updateTabItems(parent_session, "sidebar_menu", "create_ses_standard")
        } else {
          updateTabItems(parent_session, "sidebar_menu", "dashboard")
        }
      }
    })
  })
}
