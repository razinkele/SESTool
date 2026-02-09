# modules/template_ses_module.R
# Template-Based SES Creation Module
# Purpose: Allow users to start from pre-built SES templates

# Libraries loaded in global.R: shiny, shinyjs

# Source dependencies using project root (reliable from any working directory)
source(get_project_file("modules/connection_review_tabbed.R"), local = TRUE)
source(get_project_file("functions/template_loader.R"), local = TRUE)

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

debug_log("Loading SES templates from JSON files...", "TEMPLATE")
ses_templates <- tryCatch({
  result <- load_all_templates("data")
  if (is.null(result) || length(result) == 0) {
    debug_log("Warning: No templates loaded from data directory", "TEMPLATE", "WARN")
    list()  # Return empty list instead of NULL
  } else {
    result
  }
}, error = function(e) {
  debug_log(paste("Error loading templates:", e$message), "TEMPLATE", "ERROR")
  list()  # Return empty list on error
})
debug_log(sprintf("Loaded %d templates: %s", length(ses_templates), paste(names(ses_templates), collapse=", ")), "TEMPLATE")


# ============================================================================
# UI FUNCTION
# ============================================================================

template_ses_ui <- function(id, i18n) {
  ns <- NS(id)

  fluidPage(
    useShinyjs(),
    # REMOVED: usei18n() - only called once in main UI (app.R)

    # Custom CSS
    tags$head(
      tags$link(rel = "stylesheet", type = "text/css", href = "template-ses.css")
    ),

    div(class = "template-container",
      # Header
      uiOutput(ns("template_header")),

      # Three-column layout: Template cards + Preview/Actions + Connection review
      fluidRow(
        # Column 1: Template cards (3 columns - single column list)
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
        title_key = "modules.ses.template.title",
        subtitle_key = "modules.ses.template.subtitle",
        help_id = "help_template_ses",
        i18n = i18n
      )
    })

    # Render templates heading
    output$templates_heading <- renderUI({
      h4(icon("folder-open"), " ", i18n$t("modules.ses.creation.available_templates"))
    })

    # Render template actions
    output$template_actions <- renderUI({
      if (!is.null(rv$selected_template)) {
        tagList(
          div(
            wellPanel(
              style = "padding: 15px; margin-top: 0;",
              h6(icon("eye"), " ", i18n$t("modules.ses.creation.preview"), style = "margin-bottom: 10px; font-weight: bold;"),
              uiOutput(ns("template_preview_compact"))
            ),
            wellPanel(
              style = "padding: 15px;",
              h6(icon("cog"), " ", i18n$t("modules.ses.creation.actions"), style = "margin-bottom: 10px; font-weight: bold;"),
              tags$div(
                `data-toggle` = "tooltip",
                `data-placement` = "right",
                title = i18n$t("modules.ses.preview_all_template_connections_before_loading_re"),
                actionButton(ns("review_connections"),
                             i18n$t("modules.ses.creation.review"),
                             icon = icon("search"),
                             class = "btn btn-info btn-block",
                             style = "margin-bottom: 8px; font-size: 13px; padding: 8px;")
              ),
              tags$div(
                `data-toggle` = "tooltip",
                `data-placement` = "right",
                title = i18n$t("modules.ses.load_the_template_as_is_without_reviewing_connecti"),
                actionButton(ns("load_template"),
                             i18n$t("common.buttons.load"),
                             icon = icon("download"),
                             class = "btn btn-success btn-block",
                             style = "margin-bottom: 8px; font-size: 13px; padding: 8px;")
              ),
              tags$div(
                `data-toggle` = "tooltip",
                `data-placement` = "right",
                title = i18n$t("modules.ses.review_and_customize_template_connections_approve_"),
                actionButton(ns("customize_template"),
                             i18n$t("modules.ses.creation.customize"),
                             icon = icon("edit"),
                             class = "btn btn-primary btn-block",
                             style = "font-size: 13px; padding: 8px;")
              )
            )
          ),
          # Initialize Bootstrap tooltips after rendering
          tags$script(HTML("
            setTimeout(function() {
              $('[data-toggle=\"tooltip\"]').tooltip({
                container: 'body',
                trigger: 'hover'
              });
            }, 200);
          "))
        )
      }
    })

    # Render template cards - compact grid layout with tooltips
    output$template_cards <- renderUI({
      tagList(
        div(class = "template-cards-grid",
          lapply(names(ses_templates), function(template_id) {
            template <- ses_templates[[template_id]]

            # Card with tooltip data attributes
            tags$div(
              class = "template-card",
              id = ns(paste0("card_", template_id)),
              onclick = sprintf("Shiny.setInputValue('%s', '%s', {priority: 'event'})",
                                ns("template_selected"), template_id),
              `data-toggle` = "tooltip",
              `data-placement` = "right",
              `data-html` = "true",
              title = i18n$t(template$description_key),

              # Icon wrapper
              tags$div(class = "template-icon-wrapper",
                icon(template$icon)
              ),

              # Content
              tags$div(class = "template-content",
                tags$div(class = "template-name", i18n$t(template$name_key)),
                tags$span(class = "template-category-badge", i18n$t(template$category_key))
              ),

              # Preview button
              actionButton(ns(paste0("preview_", template_id)),
                          NULL,
                          icon = icon("eye"),
                          class = "template-preview-btn",
                          title = i18n$t("modules.ses.creation.view_detailed_preview"),
                          onclick = "event.stopPropagation();")
            )
          })
        ),
        # Initialize Bootstrap tooltips after rendering
        tags$script(HTML("
          setTimeout(function() {
            $('.template-card[data-toggle=\"tooltip\"]').tooltip({
              container: 'body',
              trigger: 'hover'
            });
          }, 200);
        "))
      )
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
          title = tags$h4(icon("exclamation-triangle"), " ", i18n$t("modules.ses.creation.switch_template")),
          size = "m",
          easyClose = FALSE,

          tags$div(
            style = "padding: 15px;",
            tags$p(
              tags$strong(i18n$t("common.messages.warning")), " ",
              i18n$t("modules.ses.creation.you_are_about_to_switch_to_a_different_template")
            ),
            tags$p(
              i18n$t("modules.ses.creation.all_work_on_the_current_template_will_be_lost_including"),
              tags$ul(
                tags$li(i18n$t("modules.ses.creation.connection_reviews_and_amendments")),
                tags$li(i18n$t("modules.ses.creation.approved_and_rejected_connections")),
                tags$li(i18n$t("modules.ses.creation.any_customizations_made"))
              )
            ),
            tags$p(
              style = "color: #d9534f; font-weight: bold;",
              i18n$t("modules.ses.creation.this_action_cannot_be_undone")
            ),
            tags$p(
              i18n$t("modules.ses.are_you_sure_you_want_to_start_from_scratch_with_t")
            )
          ),

          footer = tagList(
            actionButton(ns("cancel_template_switch"),
                        i18n$t("common.buttons.cancel"),
                        class = "btn-default"),
            actionButton(ns("confirm_template_switch"),
                        i18n$t("modules.ses.creation.yes_switch_template"),
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
        i18n$t("modules.ses.creation.template_switched_starting_fresh"),
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
                tags$strong(i18n$t("common.labels.description")), " ",
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
                  tags$h5(icon("arrow-down"), " ", i18n$t("modules.response.measures.drivers"), " (", nrow(template$drivers), ")",
                          style = "color: #667eea; margin-top: 0;"),
                  if (nrow(template$drivers) > 0) {
                    lapply(1:min(5, nrow(template$drivers)), function(i) {
                      tags$div(
                        style = "padding: 5px 0; border-bottom: 1px solid #f0f0f0;",
                        tags$strong(template$drivers$Name[i]),
                        tags$br(),
                        tags$small(style = CSS_TEXT_MUTED, template$drivers$Description[i])
                      )
                    })
                  } else {
                    tags$p(style = "color: #999; font-style: italic;", i18n$t("modules.ses.creation.none_defined"))
                  },
                  if (nrow(template$drivers) > 5) {
                    tags$small(style = "color: #666; font-style: italic;",
                              sprintf(i18n$t("modules.ses.creation.and_d_more"), nrow(template$drivers) - 5))
                  }
                ),

                tags$div(
                  style = "background: white; border: 1px solid #ddd; border-radius: 8px; padding: 15px; margin-bottom: 15px;",
                  tags$h5(icon("exclamation-triangle"), " ", i18n$t("modules.response.measures.pressures"), " (", nrow(template$pressures), ")",
                          style = "color: #dc3545; margin-top: 0;"),
                  if (nrow(template$pressures) > 0) {
                    lapply(1:min(5, nrow(template$pressures)), function(i) {
                      tags$div(
                        style = "padding: 5px 0; border-bottom: 1px solid #f0f0f0;",
                        tags$strong(template$pressures$Name[i]),
                        tags$br(),
                        tags$small(style = CSS_TEXT_MUTED, template$pressures$Description[i])
                      )
                    })
                  } else {
                    tags$p(style = "color: #999; font-style: italic;", i18n$t("modules.ses.creation.none_defined"))
                  },
                  if (nrow(template$pressures) > 5) {
                    tags$small(style = "color: #666; font-style: italic;",
                              sprintf(i18n$t("modules.ses.creation.and_d_more"), nrow(template$pressures) - 5))
                  }
                ),

                tags$div(
                  style = "background: white; border: 1px solid #ddd; border-radius: 8px; padding: 15px;",
                  tags$h5(icon("leaf"), " ", i18n$t("modules.ses.creation.ecosystem_services"), " (", nrow(template$ecosystem_services), ")",
                          style = "color: #28a745; margin-top: 0;"),
                  if (nrow(template$ecosystem_services) > 0) {
                    lapply(1:min(5, nrow(template$ecosystem_services)), function(i) {
                      tags$div(
                        style = "padding: 5px 0; border-bottom: 1px solid #f0f0f0;",
                        tags$strong(template$ecosystem_services$Name[i]),
                        tags$br(),
                        tags$small(style = CSS_TEXT_MUTED, template$ecosystem_services$Description[i])
                      )
                    })
                  } else {
                    tags$p(style = "color: #999; font-style: italic;", i18n$t("modules.ses.creation.none_defined"))
                  },
                  if (nrow(template$ecosystem_services) > 5) {
                    tags$small(style = "color: #666; font-style: italic;",
                              sprintf(i18n$t("modules.ses.creation.and_d_more"), nrow(template$ecosystem_services) - 5))
                  }
                )
              ),

              column(6,
                tags$div(
                  style = "background: white; border: 1px solid #ddd; border-radius: 8px; padding: 15px; margin-bottom: 15px;",
                  tags$h5(icon("running"), " ", i18n$t("modules.response.measures.activities"), " (", nrow(template$activities), ")",
                          style = "color: #ffc107; margin-top: 0;"),
                  if (nrow(template$activities) > 0) {
                    lapply(1:min(5, nrow(template$activities)), function(i) {
                      tags$div(
                        style = "padding: 5px 0; border-bottom: 1px solid #f0f0f0;",
                        tags$strong(template$activities$Name[i]),
                        tags$br(),
                        tags$small(style = CSS_TEXT_MUTED, template$activities$Description[i])
                      )
                    })
                  } else {
                    tags$p(style = "color: #999; font-style: italic;", i18n$t("modules.ses.creation.none_defined"))
                  },
                  if (nrow(template$activities) > 5) {
                    tags$small(style = "color: #666; font-style: italic;",
                              sprintf(i18n$t("modules.ses.creation.and_d_more"), nrow(template$activities) - 5))
                  }
                ),

                tags$div(
                  style = "background: white; border: 1px solid #ddd; border-radius: 8px; padding: 15px;",
                  tags$h5(icon("fish"), " ", i18n$t("modules.ses.creation.marine_processes_and_functions"), " (", nrow(template$marine_processes), ")",
                          style = "color: #17a2b8; margin-top: 0;"),
                  if (nrow(template$marine_processes) > 0) {
                    lapply(1:min(5, nrow(template$marine_processes)), function(i) {
                      tags$div(
                        style = "padding: 5px 0; border-bottom: 1px solid #f0f0f0;",
                        tags$strong(template$marine_processes$Name[i]),
                        tags$br(),
                        tags$small(style = CSS_TEXT_MUTED, template$marine_processes$Description[i])
                      )
                    })
                  } else {
                    tags$p(style = "color: #999; font-style: italic;", i18n$t("modules.ses.creation.none_defined"))
                  },
                  if (nrow(template$marine_processes) > 5) {
                    tags$small(style = "color: #666; font-style: italic;",
                              sprintf(i18n$t("modules.ses.creation.and_d_more"), nrow(template$marine_processes) - 5))
                  }
                ),

                tags$div(
                  style = "background: white; border: 1px solid #ddd; border-radius: 8px; padding: 15px;",
                  tags$h5(icon("heart"), " ", i18n$t("modules.ses.creation.welfare"), " (", nrow(template$goods_benefits), ")",
                          style = "color: #e83e8c; margin-top: 0;"),
                  if (nrow(template$goods_benefits) > 0) {
                    lapply(1:min(5, nrow(template$goods_benefits)), function(i) {
                      tags$div(
                        style = "padding: 5px 0; border-bottom: 1px solid #f0f0f0;",
                        tags$strong(template$goods_benefits$Name[i]),
                        tags$br(),
                        tags$small(style = CSS_TEXT_MUTED, template$goods_benefits$Description[i])
                      )
                    })
                  } else {
                    tags$p(style = "color: #999; font-style: italic;", i18n$t("modules.ses.creation.none_defined"))
                  },
                  if (nrow(template$goods_benefits) > 5) {
                    tags$small(style = "color: #666; font-style: italic;",
                              sprintf(i18n$t("modules.ses.creation.and_d_more"), nrow(template$goods_benefits) - 5))
                  }
                )
              )
            ),

            # Connection statistics
            tags$div(
              style = "background: #e3f2fd; padding: 15px; border-radius: 8px; margin-top: 20px;",
              tags$h5(icon("link"), " ", i18n$t("ui.dashboard.connections"), style = "margin-top: 0; color: #1976d2;"),
              tags$p(
                style = "margin: 0;",
                sprintf(i18n$t("modules.ses.this_template_includes_d_predefined_connections_be"),
                        length(parse_template_connections(template)))
              )
            )
          ),

          footer = tagList(
            actionButton(ns(paste0("select_from_preview_", template_id)),
                        i18n$t("modules.ses.creation.select_this_template"),
                        class = "btn-primary",
                        icon = icon("check")),
            tags$button(
              type = "button",
              class = "btn btn-default",
              `data-dismiss` = "modal",
              i18n$t("common.buttons.close")
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
          h6(icon("arrow-down"), " ", i18n$t("modules.response.measures.drivers"), " (", nrow(template$drivers), ")"),
          lapply(template$drivers$Name, function(name) {
            span(class = "element-tag", name)
          })
        ),
        div(class = "preview-section",
          h6(icon("running"), " ", i18n$t("modules.response.measures.activities"), " (", nrow(template$activities), ")"),
          lapply(template$activities$Name, function(name) {
            span(class = "element-tag", name)
          })
        ),
        div(class = "preview-section",
          h6(icon("exclamation-triangle"), " ", i18n$t("modules.response.measures.pressures"), " (", nrow(template$pressures), ")"),
          lapply(template$pressures$Name, function(name) {
            span(class = "element-tag", name)
          })
        ),
        div(class = "preview-section",
          h6(icon("leaf"), " ", i18n$t("modules.ses.creation.ecosystem_services"), " (", nrow(template$ecosystem_services), ")"),
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
          strong(icon("arrow-down"), " ", i18n$t("modules.response.measures.drivers"), ": "), nrow(template$drivers)
        ),
        div(style = "margin-bottom: 5px;",
          strong(icon("running"), " ", i18n$t("modules.response.measures.activities"), ": "), nrow(template$activities)
        ),
        div(style = "margin-bottom: 5px;",
          strong(icon("exclamation-triangle"), " ", i18n$t("modules.response.measures.pressures"), ": "), nrow(template$pressures)
        ),
        div(style = "margin-bottom: 5px;",
          strong(icon("leaf"), " ", i18n$t("modules.ses.creation.es"), ": "), nrow(template$ecosystem_services)
        ),
        div(style = "margin-bottom: 0;",
          strong(icon("gift"), " ", i18n$t("modules.ses.creation.gb"), ": "), nrow(template$goods_benefits)
        )
      )
    })

    # Help Modal ----
    create_help_observer(
      input, "help_template_ses", "template_ses_guide_title",
      tagList(
        h4(i18n$t("modules.ses.creation.template_ses_guide_what_is_title")),
        p(i18n$t("modules.ses.creation.template_ses_guide_what_is_p1")),
        h4(i18n$t("modules.ses.creation.template_ses_guide_how_to_use_title")),
        tags$ol(
          tags$li(i18n$t("modules.ses.creation.template_ses_guide_step1")),
          tags$li(i18n$t("modules.ses.creation.template_ses_guide_step2")),
          tags$li(i18n$t("modules.ses.creation.template_ses_guide_step3"))
        )
      ),
      i18n
    )

    # Helper function to parse template adjacency matrices into connections
    parse_template_connections <- function(template) {
      connections <- list()

      if (is.null(template$adjacency_matrices)) return(connections)

      # Map matrix names to connection types and SES element data frame names
      matrix_type_map <- list(
        a_d = list(from = "activities", to = "drivers"),
        d_a = list(from = "drivers", to = "activities"),
        p_a = list(from = "pressures", to = "activities"),
        a_p = list(from = "activities", to = "pressures"),
        mpf_p = list(from = "marine_processes", to = "pressures"),
        p_mpf = list(from = "pressures", to = "marine_processes"),
        es_mpf = list(from = "ecosystem_services", to = "marine_processes"),
        mpf_es = list(from = "marine_processes", to = "ecosystem_services"),
        gb_es = list(from = "goods_benefits", to = "ecosystem_services"),
        es_gb = list(from = "ecosystem_services", to = "goods_benefits"),
        d_gb = list(from = "drivers", to = "goods_benefits"),
        gb_d = list(from = "goods_benefits", to = "drivers"),
        gb_r = list(from = "goods_benefits", to = "responses"),
        r_d = list(from = "responses", to = "drivers"),
        r_a = list(from = "responses", to = "activities"),
        r_p = list(from = "responses", to = "pressures")
      )

      # Helper to get ID by name from SES element data frame
      get_id_by_name <- function(df, name) {
        idx <- which(trimws(as.character(df$Name)) == trimws(as.character(name)))
        if (length(idx) == 1) return(df$ID[idx])
        # Try case-insensitive match
        idx <- which(tolower(trimws(as.character(df$Name))) == tolower(trimws(as.character(name))))
        if (length(idx) == 1) return(df$ID[idx])
        # Try normalized match (remove whitespace, tolower)
        norm <- function(x) tolower(gsub("\\s+", "", x))
        idx <- which(norm(df$Name) == norm(name))
        if (length(idx) == 1) return(df$ID[idx])
        return(NA)
      }

      for (matrix_name in names(template$adjacency_matrices)) {
        mat <- template$adjacency_matrices[[matrix_name]]
        type_info <- matrix_type_map[[matrix_name]]
        if (is.null(type_info)) next

        from_df <- template[[type_info$from]]
        to_df <- template[[type_info$to]]
        from_names <- rownames(mat)
        to_names <- colnames(mat)

        for (i in seq_len(nrow(mat))) {
          for (j in seq_len(ncol(mat))) {
            cell_value <- mat[i, j]
            if (is.na(cell_value) || cell_value == "") next

            polarity <- substr(cell_value, 1, 1)
            rest <- substr(cell_value, 2, nchar(cell_value))
            parts <- strsplit(rest, ":")[[1]]
            strength <- if (length(parts) >= 1) parts[1] else "medium"
            confidence <- if (length(parts) >= 2) as.integer(parts[2]) else 3
            rationale <- if (polarity == "+") "drives/increases" else "affects/reduces"

            from_name <- from_names[i]
            to_name <- to_names[j]
            from_id <- get_id_by_name(from_df, from_name)
            to_id <- get_id_by_name(to_df, to_name)

            connections[[length(connections) + 1]] <- list(
              from_type = type_info$from,
              to_type = type_info$to,
              from_name = from_name,
              to_name = to_name,
              from_id = from_id,
              to_id = to_id,
              polarity = polarity,
              strength = strength,
              confidence = confidence,
              rationale = paste(from_name, rationale, to_name)
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
        sprintf(i18n$t("modules.ses.creation.template_s_loaded"), i18n$t(template$name_key)),
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
          h5(icon("link"), " ", i18n$t("modules.ses.creation.connection_review"), style = "margin: 0; font-weight: bold;"),
          p(style = "margin: 5px 0 0 0; font-size: 12px;",
            sprintf(i18n$t("modules.ses.creation.d_connections_from_s_template"),
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
                          i18n$t("common.buttons.cancel"),
                          icon = icon("times"),
                          class = "btn-secondary btn-lg btn-block")
            ),
            column(6,
              actionButton(ns("finalize_template"),
                          if (rv$review_mode == "customize") i18n$t("modules.ses.creation.customize_template") else i18n$t("modules.ses.creation.load_template"),
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
      connections_reactive = reactive({
        # For display, show names, but all logic uses IDs
        lapply(rv$template_connections, function(conn) {
          conn$display_from <- conn$from_name
          conn$display_to <- conn$to_name
          conn
        })
      }),
      i18n = i18n,
      on_amend = function(idx, polarity, strength, confidence) {
        # Update the connection by index (ID-based logic)
        debug_log(sprintf("Connection #%d amended: %s, %s, %d", idx, polarity, strength, confidence), "TEMPLATE")
        rv$template_connections[[idx]]$polarity <- polarity
        rv$template_connections[[idx]]$strength <- strength
        rv$template_connections[[idx]]$confidence <- confidence
        rationale <- if (polarity == "+") "drives/increases" else "affects/reduces"
        rv$template_connections[[idx]]$rationale <- paste(
          rv$template_connections[[idx]]$from_name,
          rationale,
          rv$template_connections[[idx]]$to_name
        )
      },
      on_approve = function(idx, conn) {
        # When approving, save the connection data (in case user didn't click Amend)
        # This is important because the user might change sliders and click Accept directly
        debug_log(sprintf("Connection #%d approved", idx), "TEMPLATE")
        # No additional action needed - amendments are already saved via on_amend
      },
      on_reject = function(idx, conn) {
        # When rejecting, just log it
        debug_log(sprintf("Connection #%d rejected", idx), "TEMPLATE")
        # No additional action needed - rejection is tracked in review_status
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

      # CRITICAL: Apply any amendments that were made in the review module
      # This ensures that changes to sliders/switches are saved even if user
      # clicked Accept without clicking Amend first
      if (length(amended_data) > 0) {
        debug_log(sprintf("Applying %d amendments to final connections", length(amended_data)), "TEMPLATE-CONN")
        for (amended_idx in names(amended_data)) {
          # Convert character index to numeric
          idx <- as.numeric(amended_idx)

          # Check if this connection is in our final list
          # Find position in original list
          original_position <- which(seq_along(rv$template_connections) == idx)
          if (length(original_position) > 0) {
            # Find position in final_connections list
            # We need to check which of the approved/kept indices this is
            if (length(approved_idx) > 0) {
              final_position <- which(approved_idx == idx)
            } else if (length(rejected_idx) > 0) {
              keep_idx <- setdiff(seq_along(rv$template_connections), rejected_idx)
              final_position <- which(keep_idx == idx)
            } else {
              final_position <- idx
            }

            if (length(final_position) > 0 && final_position <= length(final_connections)) {
              # Apply amendments
              amendment <- amended_data[[amended_idx]]
              if (!is.null(amendment$polarity)) {
                final_connections[[final_position]]$polarity <- amendment$polarity
                debug_log(sprintf("Applied polarity amendment to connection #%d: %s",
                           idx, amendment$polarity), "TEMPLATE-CONN")
              }
              if (!is.null(amendment$strength)) {
                final_connections[[final_position]]$strength <- amendment$strength
                debug_log(sprintf("Applied strength amendment to connection #%d: %s",
                           idx, amendment$strength), "TEMPLATE-CONN")
              }
              if (!is.null(amendment$confidence)) {
                final_connections[[final_position]]$confidence <- amendment$confidence
                debug_log(sprintf("Applied confidence amendment to connection #%d: %d",
                           idx, amendment$confidence), "TEMPLATE-CONN")
              }
            }
          }
        }
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
      # Initialize empty matrices with IDs as dimnames for robust assignment
      # Matrix naming convention: from_to (e.g., d_a = drivers to activities)
      adj_matrices <- list(
        # Main DPSIR flow (forward direction)
        d_a = matrix("", nrow = nrow(template$drivers), ncol = nrow(template$activities),
                    dimnames = list(template$drivers$ID, template$activities$ID)),
        a_p = matrix("", nrow = nrow(template$activities), ncol = nrow(template$pressures),
                    dimnames = list(template$activities$ID, template$pressures$ID)),
        p_mpf = matrix("", nrow = nrow(template$pressures), ncol = nrow(template$marine_processes),
                      dimnames = list(template$pressures$ID, template$marine_processes$ID)),
        mpf_es = matrix("", nrow = nrow(template$marine_processes), ncol = nrow(template$ecosystem_services),
                       dimnames = list(template$marine_processes$ID, template$ecosystem_services$ID)),
        es_gb = matrix("", nrow = nrow(template$ecosystem_services), ncol = nrow(template$goods_benefits),
                      dimnames = list(template$ecosystem_services$ID, template$goods_benefits$ID)),

        # Feedback loops
        gb_d = matrix("", nrow = nrow(template$goods_benefits), ncol = nrow(template$drivers),
                     dimnames = list(template$goods_benefits$ID, template$drivers$ID)),

        # Response/Management matrices
        gb_r = matrix("", nrow = nrow(template$goods_benefits), ncol = nrow(template$responses),
                     dimnames = list(template$goods_benefits$ID, template$responses$ID)),
        r_d = matrix("", nrow = nrow(template$responses), ncol = nrow(template$drivers),
                    dimnames = list(template$responses$ID, template$drivers$ID)),
        r_a = matrix("", nrow = nrow(template$responses), ncol = nrow(template$activities),
                    dimnames = list(template$responses$ID, template$activities$ID)),
        r_p = matrix("", nrow = nrow(template$responses), ncol = nrow(template$pressures),
                    dimnames = list(template$responses$ID, template$pressures$ID))
      )

      # Deep diagnostics: print number and structure of connections and matrix names
      debug_log(sprintf("Number of final connections: %d", length(final_connections)), "TEMPLATE-CONN")
      if (length(final_connections) > 0) {
        debug_log("Example connection:", "TEMPLATE-CONN")
        print(final_connections[[1]])
      }
      debug_log("Example matrix row/col names (first matrix):", "TEMPLATE-CONN")
      print(rownames(adj_matrices[[1]]))
      print(colnames(adj_matrices[[1]]))

      # Helper: normalize string (remove all whitespace, Unicode normalize, tolower)
      normalize_str <- function(x) {
        # Remove all whitespace, convert to lower, and normalize Unicode (if stringi available)
        x <- gsub("\\s+", "", x)
        x <- tolower(x)
        if (requireNamespace("stringi", quietly = TRUE)) {
          x <- stringi::stri_trans_general(x, "NFKC")
        }
        return(x)
      }

      for (conn in final_connections) {
        from_id <- as.character(conn$from_id)
        to_id <- as.character(conn$to_id)
        value <- paste0(conn$polarity, conn$strength, ":", conn$confidence)
        assigned <- FALSE
        for (matrix_name in names(adj_matrices)) {
          mat <- adj_matrices[[matrix_name]]
          if (!is.na(from_id) && !is.na(to_id) && from_id %in% rownames(mat) && to_id %in% colnames(mat)) {
            adj_matrices[[matrix_name]][from_id, to_id] <- value
            assigned <- TRUE
            break
          }
        }
        if (!assigned) {
          debug_log(sprintf("Could not assign connection by ID: '%s' -> '%s' (value: %s)", from_id, to_id, value), "TEMPLATE-CONN")
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
        sprintf(i18n$t("modules.ses.creation.template_s_loaded_with_d_connections"),
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
