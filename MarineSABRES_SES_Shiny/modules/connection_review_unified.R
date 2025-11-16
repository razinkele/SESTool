# modules/connection_review_unified.R
# Unified Connection Review Module
# Purpose: Reusable UI/Server for reviewing, approving, editing, and amending SES connections
# Features: Combines best of import review and AI ISA review
#   - Green/red arrow visual indicators for polarity
#   - "drives/increases" / "affects/reduces" rationale text
#   - Editable sliders for strength and confidence
#   - Polarity switch toggle
#   - Approve/Reject/Amend buttons
#   - Filter and sort capabilities
#   - Reusable across import, AI assistant, and template creation

library(shiny)
library(shinyWidgets)

# ============================================================================
# UI FUNCTION
# ============================================================================

connection_review_unified_ui <- function(id, i18n, show_filters = TRUE) {
  ns <- NS(id)

  tagList(
    # Custom CSS and JavaScript
    tags$head(
      tags$style(HTML("
        .conn-card-unified {
          background: white;
          border: 2px solid #ddd;
          border-radius: 10px;
          padding: 18px;
          margin: 12px 0;
          transition: all 0.3s ease;
          max-width: 600px;
        }
        .conn-card-unified:hover {
          box-shadow: 0 4px 12px rgba(0,0,0,0.15);
          transform: translateY(-2px);
        }
        .conn-card-approved {
          border-color: #28a745;
          background: #d4edda;
          border-left-width: 5px;
        }
        .conn-card-rejected {
          border-color: #dc3545;
          background: #f8d7da;
          opacity: 0.7;
          border-left-width: 5px;
        }
        .conn-header-unified {
          font-size: 1.15em;
          font-weight: 600;
          margin-bottom: 12px;
          display: flex;
          align-items: center;
          gap: 8px;
        }
        .conn-arrow-positive {
          color: #28a745;
          font-size: 1.3em;
          font-weight: bold;
        }
        .conn-arrow-negative {
          color: #dc3545;
          font-size: 1.3em;
          font-weight: bold;
        }
        .conn-rationale {
          color: #666;
          font-weight: normal;
          font-style: italic;
          margin: 0 5px;
        }
        .conn-controls {
          display: flex;
          align-items: center;
          gap: 10px;
          margin-top: 15px;
        }
        .conn-slider-container {
          margin: 10px 0;
        }
        .conn-slider-label {
          font-weight: 600;
          margin-bottom: 5px;
          display: flex;
          justify-content: space-between;
        }
        .stats-box-unified {
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
          color: white;
          padding: 20px;
          border-radius: 10px;
          margin-bottom: 20px;
        }
        .stats-box-unified .stat-item {
          text-align: center;
        }
        .stats-box-unified .stat-value {
          font-size: 2em;
          font-weight: bold;
          margin: 5px 0;
        }
        .stats-box-unified .stat-label {
          font-size: 0.9em;
          opacity: 0.9;
        }
      ")),

      # JavaScript for tooltip initialization
      tags$script(HTML("
        $(document).ready(function() {
          // Initialize tooltips on page load
          $('[data-toggle=\"tooltip\"]').tooltip();
        });

        // Re-initialize tooltips after Shiny updates
        $(document).on('shiny:value', function(event) {
          setTimeout(function() {
            $('[data-toggle=\"tooltip\"]').tooltip();
          }, 100);
        });

        // Re-initialize tooltips when connections list updates
        Shiny.addCustomMessageHandler('reinit_conn_tooltips', function(message) {
          setTimeout(function() {
            $('[data-toggle=\"tooltip\"]').tooltip();
          }, 150);
        });
      "))
    ),

    # Header with controls
    fluidRow(
      column(8,
        h3(icon("link"), " ", i18n$t("Connection Review"), style = "margin-top: 10px;")
      ),
      column(4, align = "right",
        actionButton(ns("approve_all"),
                    i18n$t("Approve All"),
                    icon = icon("check-circle"),
                    class = "btn-success btn-sm",
                    style = "margin: 5px;"),
        actionButton(ns("reject_all"),
                    i18n$t("Reject All"),
                    icon = icon("times-circle"),
                    class = "btn-danger btn-sm",
                    style = "margin: 5px;")
      )
    ),

    hr(),

    # Summary stats
    uiOutput(ns("stats_summary")),

    # Filter controls (optional)
    if (show_filters) {
      div(
        fluidRow(
          column(4,
            selectInput(ns("filter_status"),
                       i18n$t("Filter by Status:"),
                       choices = c("All", "Approved", "Rejected", "Pending"),
                       selected = "All")
          ),
          column(4,
            selectInput(ns("filter_polarity"),
                       i18n$t("Filter by Polarity:"),
                       choices = c("All", "Positive (+)", "Negative (-)"),
                       selected = "All")
          ),
          column(4,
            selectInput(ns("sort_by"),
                       i18n$t("Sort by:"),
                       choices = c("Order", "From", "To", "Strength"),
                       selected = "Order")
          )
        ),
        hr()
      )
    },

    # Connection cards container
    div(id = ns("connections_container"),
        style = "max-height: 700px; overflow-y: auto; padding: 10px;",
        uiOutput(ns("connections_list"))
    )
  )
}

# ============================================================================
# SERVER FUNCTION
# ============================================================================

connection_review_unified_server <- function(id, connections_reactive, i18n,
                                             on_approve = NULL, on_reject = NULL, on_amend = NULL) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # Reactive values to track approval/rejection status
    rv <- reactiveValues(
      approved = c(),  # Vector of approved connection indices
      rejected = c(),  # Vector of rejected connection indices
      amended_data = list()  # Store amended connection data
    )

    # Get filtered and sorted connections
    filtered_connections <- reactive({
      req(connections_reactive())
      conns <- connections_reactive()

      if (length(conns) == 0) return(list())

      # Create indices for original positions
      indices <- seq_along(conns)

      # Apply status filter
      if (!is.null(input$filter_status) && input$filter_status != "All") {
        if (input$filter_status == "Approved") {
          mask <- indices %in% rv$approved
          conns <- conns[mask]
          indices <- indices[mask]
        } else if (input$filter_status == "Rejected") {
          mask <- indices %in% rv$rejected
          conns <- conns[mask]
          indices <- indices[mask]
        } else if (input$filter_status == "Pending") {
          pending_idx <- setdiff(indices, c(rv$approved, rv$rejected))
          mask <- indices %in% pending_idx
          conns <- conns[mask]
          indices <- indices[mask]
        }
      }

      # Apply polarity filter
      if (!is.null(input$filter_polarity) && input$filter_polarity != "All" && length(conns) > 0) {
        polarity_filter <- if (input$filter_polarity == "Positive (+)") "+" else "-"
        mask <- sapply(conns, function(x) x$polarity == polarity_filter)
        conns <- conns[mask]
        indices <- indices[mask]
      }

      # Apply sorting
      if (!is.null(input$sort_by) && length(conns) > 0 && input$sort_by != "Order") {
        if (input$sort_by == "From") {
          order_idx <- order(sapply(conns, function(x) x$from_name))
          conns <- conns[order_idx]
          indices <- indices[order_idx]
        } else if (input$sort_by == "To") {
          order_idx <- order(sapply(conns, function(x) x$to_name))
          conns <- conns[order_idx]
          indices <- indices[order_idx]
        } else if (input$sort_by == "Strength") {
          strength_order <- c("very weak" = 1, "weak" = 2, "medium" = 3, "strong" = 4, "very strong" = 5)
          order_idx <- order(-sapply(conns, function(x) strength_order[x$strength] %||% 3))
          conns <- conns[order_idx]
          indices <- indices[order_idx]
        }
      }

      list(connections = conns, indices = indices)
    })

    # Summary statistics
    output$stats_summary <- renderUI({
      req(connections_reactive())
      total <- length(connections_reactive())
      approved <- length(rv$approved)
      rejected <- length(rv$rejected)
      pending <- total - approved - rejected

      div(class = "stats-box-unified",
        fluidRow(
          column(3, class = "stat-item",
            div(class = "stat-value", total),
            div(class = "stat-label", i18n$t("Total"))
          ),
          column(3, class = "stat-item",
            div(class = "stat-value", approved),
            div(class = "stat-label", i18n$t("Approved"))
          ),
          column(3, class = "stat-item",
            div(class = "stat-value", rejected),
            div(class = "stat-label", i18n$t("Rejected"))
          ),
          column(3, class = "stat-item",
            div(class = "stat-value", pending),
            div(class = "stat-label", i18n$t("Pending"))
          )
        )
      )
    })

    # Render connection cards
    output$connections_list <- renderUI({
      filtered <- filtered_connections()
      conns <- filtered$connections
      indices <- filtered$indices

      if (length(conns) == 0) {
        return(div(class = "alert alert-warning",
                  icon("info-circle"), " ", i18n$t("No connections match the current filters.")))
      }

      # Create cards for each connection
      connection_cards <- lapply(seq_along(conns), function(i) {
        conn <- conns[[i]]
        conn_idx <- indices[i]  # Original index in full list

        # Determine status class
        status_class <- "conn-card-unified"
        if (conn_idx %in% rv$approved) {
          status_class <- paste(status_class, "conn-card-approved")
        } else if (conn_idx %in% rv$rejected) {
          status_class <- paste(status_class, "conn-card-rejected")
        }

        # Get amended values if they exist, otherwise use connection defaults
        amended <- rv$amended_data[[as.character(conn_idx)]]
        current_polarity <- if (!is.null(amended$polarity)) amended$polarity else conn$polarity
        current_strength <- if (!is.null(amended$strength)) amended$strength else conn$strength
        current_confidence <- if (!is.null(amended$confidence)) amended$confidence else (conn$confidence %||% 3)

        # Polarity arrow and text
        is_positive <- current_polarity == "+"
        arrow_class <- if (is_positive) "conn-arrow-positive" else "conn-arrow-negative"
        arrow_symbol <- if (is_positive) "\u2191" else "\u2193"  # Up/down arrows
        rationale_text <- if (is_positive) "drives/increases" else "affects/reduces"

        # Convert strength to slider value (1-5)
        strength_map <- c("very weak" = 1, "weak" = 2, "medium" = 3, "strong" = 4, "very strong" = 5)
        strength_value <- strength_map[current_strength] %||% 3

        div(class = status_class,
          # Connection header with arrow and rationale
          div(class = "conn-header-unified",
            span(conn$from_name),
            span(class = arrow_class, arrow_symbol, " ", current_polarity),
            span(class = "conn-rationale",
                 textOutput(ns(paste0("rationale_", conn_idx)), inline = TRUE)),
            span(conn$to_name)
          ),

          # Strength slider
          div(class = "conn-slider-container",
            div(class = "conn-slider-label",
              span(
                icon("bolt"), " ", i18n$t("Strength:"),
                span(
                  icon("info-circle", style = "color: #17a2b8; cursor: help; margin-left: 5px; font-size: 0.9em;"),
                  `data-toggle` = "tooltip",
                  `data-placement` = "top",
                  title = "1: Very Weak - Minimal influence
2: Weak - Small influence
3: Medium - Moderate influence
4: Strong - Significant influence
5: Very Strong - Major influence"
                )
              ),
              span(textOutput(ns(paste0("strength_label_", conn_idx)), inline = TRUE))
            ),
            sliderInput(
              ns(paste0("strength_", conn_idx)),
              label = NULL,
              min = 1,
              max = 5,
              value = strength_value,
              step = 1,
              ticks = TRUE,
              width = "100%"
            )
          ),

          # Confidence slider
          div(class = "conn-slider-container",
            div(class = "conn-slider-label",
              span(
                icon("chart-bar"), " ", i18n$t("Confidence:"),
                span(
                  icon("info-circle", style = "color: #17a2b8; cursor: help; margin-left: 5px; font-size: 0.9em;"),
                  `data-toggle` = "tooltip",
                  `data-placement` = "top",
                  title = "1: Very Low - Highly uncertain
2: Low - Uncertain with limited evidence
3: Medium - Moderately certain
4: High - Confident with good evidence
5: Very High - Highly confident, well-established"
                )
              ),
              span(textOutput(ns(paste0("confidence_label_", conn_idx)), inline = TRUE))
            ),
            sliderInput(
              ns(paste0("confidence_", conn_idx)),
              label = NULL,
              min = 1,
              max = 5,
              value = current_confidence,
              step = 1,
              ticks = TRUE,
              width = "100%"
            )
          ),

          # Control buttons and polarity switch
          div(class = "conn-controls",
            # Amend button
            div(style = "width: 110px;",
              tags$div(
                `data-toggle` = "tooltip",
                `data-placement` = "top",
                title = i18n$t("Save changes to strength, confidence, or polarity for this connection"),
                actionButton(ns(paste0("amend_", conn_idx)),
                            i18n$t("Amend"),
                            icon = icon("edit"),
                            class = "btn-warning btn-sm",
                            style = "width: 100%; height: 32px; padding: 6px 8px;")
              )
            ),

            # Approve/Reject/Reset button
            div(style = "width: 110px;",
              if (conn_idx %in% rv$approved) {
                tags$div(
                  `data-toggle` = "tooltip",
                  `data-placement` = "top",
                  title = i18n$t("Reject this connection - it will be excluded from the final model"),
                  actionButton(ns(paste0("reject_", conn_idx)),
                              i18n$t("Reject"),
                              icon = icon("times"),
                              class = "btn-danger btn-sm",
                              style = "width: 100%; height: 32px; padding: 6px 8px;")
                )
              } else if (conn_idx %in% rv$rejected) {
                tags$div(
                  `data-toggle` = "tooltip",
                  `data-placement` = "top",
                  title = i18n$t("Reset to pending status - neither approved nor rejected"),
                  actionButton(ns(paste0("reset_", conn_idx)),
                              i18n$t("Reset"),
                              icon = icon("undo"),
                              class = "btn-secondary btn-sm",
                              style = "width: 100%; height: 32px; padding: 6px 8px;")
                )
              } else {
                tags$div(
                  `data-toggle` = "tooltip",
                  `data-placement` = "top",
                  title = i18n$t("Approve this connection - it will be included in the final model"),
                  actionButton(ns(paste0("approve_", conn_idx)),
                              i18n$t("Approve"),
                              icon = icon("check"),
                              class = "btn-success btn-sm",
                              style = "width: 100%; height: 32px; padding: 6px 8px;")
                )
              }
            ),

            # Polarity switch - aligned with buttons
            div(style = "width: 110px; display: flex; align-items: center; justify-content: flex-end;",
              if (conn_idx %in% rv$approved) {
                span(style = "font-size: 0.85em; color: green; margin-right: 10px;",
                     icon("check-circle"), " ", i18n$t("Approved"))
              } else if (conn_idx %in% rv$rejected) {
                span(style = "font-size: 0.85em; color: red; margin-right: 10px;",
                     icon("times-circle"), " ", i18n$t("Rejected"))
              },
              tags$span(
                `data-toggle` = "tooltip",
                `data-placement` = "top",
                title = i18n$t("Toggle polarity: + = drives/increases (positive), - = affects/reduces (negative)"),
                switchInput(
                  inputId = ns(paste0("polarity_", conn_idx)),
                  value = is_positive,
                  onLabel = "+",
                  offLabel = "-",
                  onStatus = "success",
                  offStatus = "danger",
                  size = "small",
                  width = "60px"
                )
              )
            )
          )
        )
      })

      # Trigger tooltip re-initialization after rendering cards
      session$sendCustomMessage("reinit_conn_tooltips", list(timestamp = Sys.time()))

      tagList(connection_cards)
    })

    # Dynamic text outputs for each connection
    observe({
      filtered <- filtered_connections()
      indices <- filtered$indices

      if (length(indices) > 0) {
        lapply(indices, function(conn_idx) {
          local({
            idx <- conn_idx

            # Rationale text (changes with polarity switch)
            output[[paste0("rationale_", idx)]] <- renderText({
              polarity_val <- input[[paste0("polarity_", idx)]]
              if (is.null(polarity_val)) {
                # Use connection's default polarity
                conn_list <- connections_reactive()
                if (idx <= length(conn_list)) {
                  is_pos <- conn_list[[idx]]$polarity == "+"
                } else {
                  is_pos <- TRUE
                }
              } else {
                is_pos <- isTRUE(polarity_val)
              }
              if (is_pos) "drives/increases" else "affects/reduces"
            })

            # Strength label
            output[[paste0("strength_label_", idx)]] <- renderText({
              val <- input[[paste0("strength_", idx)]]
              if (is.null(val)) return("")
              strength_labels <- c("1" = "Very Weak", "2" = "Weak", "3" = "Medium",
                                  "4" = "Strong", "5" = "Very Strong")
              paste0("(", i18n$t(strength_labels[as.character(val)]), ")")
            })

            # Confidence label
            output[[paste0("confidence_label_", idx)]] <- renderText({
              val <- input[[paste0("confidence_", idx)]]
              if (is.null(val)) return("")
              paste0("(", val, "/5)")
            })
          })
        })
      }
    })

    # Approve all
    observeEvent(input$approve_all, {
      rv$approved <- seq_along(connections_reactive())
      rv$rejected <- c()
      if (!is.null(on_approve)) on_approve(rv$approved)
      showNotification(i18n$t("All connections approved!"), type = "message")
    })

    # Reject all
    observeEvent(input$reject_all, {
      rv$rejected <- seq_along(connections_reactive())
      rv$approved <- c()
      if (!is.null(on_reject)) on_reject(rv$rejected)
      showNotification(i18n$t("All connections rejected!"), type = "warning")
    })

    # Dynamic button handlers
    observe({
      req(connections_reactive())

      lapply(seq_along(connections_reactive()), function(i) {
        local({
          idx <- i

          # Approve button
          observeEvent(input[[paste0("approve_", idx)]], {
            rv$approved <- unique(c(rv$approved, idx))
            rv$rejected <- setdiff(rv$rejected, idx)
            if (!is.null(on_approve)) on_approve(rv$approved)
          }, ignoreInit = TRUE)

          # Reject button
          observeEvent(input[[paste0("reject_", idx)]], {
            rv$rejected <- unique(c(rv$rejected, idx))
            rv$approved <- setdiff(rv$approved, idx)
            if (!is.null(on_reject)) on_reject(rv$rejected)
          }, ignoreInit = TRUE)

          # Reset button
          observeEvent(input[[paste0("reset_", idx)]], {
            rv$approved <- setdiff(rv$approved, idx)
            rv$rejected <- setdiff(rv$rejected, idx)
          }, ignoreInit = TRUE)

          # Amend button
          observeEvent(input[[paste0("amend_", idx)]], {
            # Get current values from sliders and switch
            polarity_val <- input[[paste0("polarity_", idx)]]
            strength_val <- input[[paste0("strength_", idx)]]
            confidence_val <- input[[paste0("confidence_", idx)]]

            # Convert polarity (TRUE = +, FALSE = -)
            polarity <- if (isTRUE(polarity_val)) "+" else "-"

            # Convert strength value to label
            strength_labels <- c("1" = "very weak", "2" = "weak", "3" = "medium",
                                "4" = "strong", "5" = "very strong")
            strength <- strength_labels[as.character(strength_val)]

            # Store amended data
            rv$amended_data[[as.character(idx)]] <- list(
              polarity = polarity,
              strength = strength,
              confidence = confidence_val
            )

            # Call external callback if provided
            if (!is.null(on_amend)) {
              on_amend(idx, polarity, strength, confidence_val)
            }

            showNotification(
              paste0(i18n$t("Connection"), " #", idx, " ", i18n$t("updated successfully!")),
              type = "message",
              duration = 2
            )
          }, ignoreInit = TRUE)
        })
      })
    })

    # Return reactive status for external access
    return(reactive({
      list(
        approved = rv$approved,
        rejected = rv$rejected,
        pending = setdiff(seq_along(connections_reactive()), c(rv$approved, rv$rejected)),
        amended_data = rv$amended_data
      )
    }))
  })
}
