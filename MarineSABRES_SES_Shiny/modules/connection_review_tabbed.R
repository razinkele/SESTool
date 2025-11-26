# modules/connection_review_tabbed.R
# Tabbed Connection Review Module
# Purpose: Review connections organized by DAPSI(W)R(M) transition stages
# Features:
#   - Tab-based interface for connection batches
#   - Drivers→Activities, Activities→Pressures, Pressures→States, etc.
#   - Progress tracking per batch
#   - Same approval/edit functionality as unified module
#   - Cleaner organization for large connection sets

# Robust NULL/NA coalescing operator for this module
utils::globalVariables(c('%|||%'))
`%|||%` <- function(a, b) {
  if (is.null(a) || (length(a) == 1 && is.na(a))) b else a
}

library(shiny)
library(shinyWidgets)

# Ensure %|||% operator is visible in this module (for R CMD check/lint)
`%|||%` <- function(a, b) {
  if (is.null(a) || (length(a) == 1 && is.na(a))) b else a
}

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

# Define connection batches based on framework transitions
get_connection_batches <- function() {
  list(
    list(
      id = "drivers_activities",
      label = "Drivers → Activities",
      from_type = c("driver", "drivers"),
      to_type = c("activity", "activities"),
      description = "How societal drivers lead to human activities",
      icon = "arrow-right"
    ),
    list(
      id = "activities_pressures",
      label = "Activities → Pressures",
      from_type = c("activity", "activities"),
      to_type = c("pressure", "pressures", "enmp"),
      description = "How activities create environmental pressures",
      icon = "arrow-right"
    ),
    list(
      id = "pressures_mpf",
      label = "Pressures → Marine Processes and Functions",
      from_type = c("pressure", "pressures", "enmp"),
      to_type = c("state", "states", "state change", "marine_process", "marine_processes", "mpf"),
      description = "How pressures affect marine processes and functions",
      icon = "arrow-right"
    ),
    list(
      id = "mpf_services",
      label = "Marine Processes and Functions → Ecosystem Services",
      from_type = c("state", "states", "state change", "marine_process", "marine_processes", "mpf"),
      to_type = c("impact", "impacts", "ecosystem_service", "ecosystem_services", "es"),
      description = "How marine processes affect ecosystem services",
      icon = "arrow-right"
    ),
    list(
      id = "services_welfare",
      label = "Ecosystem Services → Welfare",
      from_type = c("impact", "impacts", "ecosystem_service", "ecosystem_services", "es"),
      to_type = c("welfare", "goods_benefit", "goods_benefits", "gb", "wellbeing"),
      description = "How ecosystem services affect human welfare",
      icon = "arrow-right"
    ),
    list(
      id = "welfare_responses",
      label = "Welfare → Responses",
      from_type = c("welfare", "goods_benefit", "goods_benefits", "gb", "wellbeing"),
      to_type = c("response", "responses"),
      description = "How welfare issues trigger management responses",
      icon = "arrow-right"
    ),
    list(
      id = "responses_drivers",
      label = "Responses → Drivers",
      from_type = c("response", "responses"),
      to_type = c("driver", "drivers"),
      description = "How management responses address drivers",
      icon = "arrow-right"
    ),
    list(
      id = "responses_activities",
      label = "Responses → Activities",
      from_type = c("response", "responses"),
      to_type = c("activity", "activities"),
      description = "How management responses regulate activities",
      icon = "arrow-right"
    ),
    list(
      id = "responses_pressures",
      label = "Responses → Pressures",
      from_type = c("response", "responses"),
      to_type = c("pressure", "pressures", "enmp"),
      description = "How management responses mitigate pressures",
      icon = "arrow-right"
    ),
    list(
      id = "drivers_welfare",
      label = "Drivers → Welfare (Feedback)",
      from_type = c("driver", "drivers"),
      to_type = c("welfare", "goods_benefit", "goods_benefits", "gb", "wellbeing"),
      description = "Feedback loops showing how drivers directly affect welfare outcomes",
      icon = "recycle"
    ),
    list(
      id = "other",
      label = "Other Connections",
      from_type = NULL,
      to_type = NULL,
      description = "Connections not matching standard framework transitions",
      icon = "question-circle"
    )
  )
}

# Categorize a connection into a batch
categorize_connection <- function(conn, batches) {
  from_type <- tolower(trimws(conn$from_type %|||% ""))
  to_type <- tolower(trimws(conn$to_type %|||% ""))

  # Check all defined transitions (now includes Response→Driver/Activity/Pressure)
  # All batches except the last one (which is "other")
  for (batch in batches[1:(length(batches)-1)]) {
    if (!is.null(batch$from_type) && !is.null(batch$to_type)) {
      if (from_type %in% batch$from_type && to_type %in% batch$to_type) {
        return(batch$id)
      }
    }
  }

  # Otherwise, it's "other"
  return("other")
}

# ============================================================================
# UI FUNCTION
# ============================================================================

connection_review_tabbed_ui <- function(id, i18n) {
  ns <- NS(id)
  cat(sprintf("[CONN REVIEW TABBED UI] UI function called with id: %s\n", id))

  tagList(
    # Use i18n for language support
    shiny.i18n::usei18n(i18n),

    # Custom CSS
    tags$head(
      tags$style(HTML("
        .conn-card-tabbed {
          background: white;
          border: 2px solid #ddd;
          border-radius: 10px;
          padding: 18px;
          margin: 12px 0;
          transition: all 0.3s ease;
        }
        .conn-card-tabbed:hover {
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
        .conn-header-tabbed {
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
          flex-wrap: wrap;
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
        .batch-stats-box {
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
          color: white;
          padding: 15px 20px;
          border-radius: 10px;
          margin-bottom: 15px;
        }
        .batch-stats-box .stat-item {
          display: inline-block;
          margin-right: 20px;
        }
        .batch-stats-box .stat-value {
          font-size: 1.8em;
          font-weight: bold;
          display: inline;
        }
        .batch-stats-box .stat-label {
          font-size: 0.9em;
          opacity: 0.9;
          display: inline;
          margin-left: 5px;
        }
        .batch-description {
          color: #666;
          font-style: italic;
          padding: 10px;
          background: #f8f9fa;
          border-left: 4px solid #667eea;
          margin-bottom: 20px;
          border-radius: 5px;
        }
        .tab-badge {
          background: #17a2b8;
          color: white;
          padding: 2px 8px;
          border-radius: 10px;
          font-size: 0.85em;
          margin-left: 8px;
        }
        .empty-batch-message {
          text-align: center;
          padding: 40px 20px;
          color: #999;
        }
        .empty-batch-icon {
          font-size: 3em;
          margin-bottom: 15px;
          opacity: 0.3;
        }
      "))
    ),

    # Overall progress summary
    uiOutput(ns("overall_stats")),

    hr(),

    # Tabbed interface for connection batches (dynamically generated)
    uiOutput(ns("dynamic_tabs"))
  )
}

# ============================================================================
# SERVER FUNCTION
# ============================================================================

connection_review_tabbed_server <- function(id, connections_reactive, i18n,
                                           on_approve = NULL, on_reject = NULL, on_amend = NULL) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # Reactive values to track approval/rejection status
    rv <- reactiveValues(
      approved = c(),  # Vector of approved connection indices
      rejected = c(),  # Vector of rejected connection indices
      amended_data = list(),  # Store amended connection data
      batches_info = list(),  # Store batch categorization info
      active_tab = NULL  # Track the currently active tab to prevent unwanted navigation
    )

    # Categorize connections into batches
    batched_connections <- reactive({
      req(connections_reactive())
      conns <- connections_reactive()

      cat(sprintf("[CONN REVIEW TABBED] Received %d connections\n", length(conns)))

      if (length(conns) == 0) {
        cat("[CONN REVIEW TABBED] No connections to display\n")
        return(list(batches = list(), total = 0))
      }

      batches <- get_connection_batches()
      batch_lists <- lapply(batches, function(b) list(
        info = b,
        connections = list(),
        indices = c()
      ))
      names(batch_lists) <- sapply(batches, function(b) b$id)

      # Categorize each connection
      for (i in seq_along(conns)) {
        batch_id <- categorize_connection(conns[[i]], batches)
        batch_lists[[batch_id]]$connections <- c(batch_lists[[batch_id]]$connections, list(conns[[i]]))
        batch_lists[[batch_id]]$indices <- c(batch_lists[[batch_id]]$indices, i)
      }

      # Filter out empty batches
      batch_lists <- Filter(function(b) length(b$connections) > 0, batch_lists)

      list(
        batches = batch_lists,
        total = length(conns)
      )
    })

    # Overall statistics
    output$overall_stats <- renderUI({
      batched <- batched_connections()
      total <- batched$total

      if (total == 0) {
        return(div(class = "alert alert-info",
                  icon("info-circle"), " ", i18n$t("No connections to review.")))
      }

      approved <- length(rv$approved)
      rejected <- length(rv$rejected)
      pending <- total - approved - rejected
      progress_pct <- round((approved + rejected) / total * 100, 1)

      div(class = "batch-stats-box",
        div(style = "display: flex; justify-content: space-between; align-items: center;",
          div(
            span(class = "stat-item",
              span(class = "stat-value", total),
              span(class = "stat-label", i18n$t("Total Connections"))
            ),
            span(class = "stat-item",
              span(class = "stat-value", approved),
              span(class = "stat-label", i18n$t("Approved"), style = "color: #d4edda;")
            ),
            span(class = "stat-item",
              span(class = "stat-value", rejected),
              span(class = "stat-label", i18n$t("Rejected"), style = "color: #f8d7da;")
            ),
            span(class = "stat-item",
              span(class = "stat-value", pending),
              span(class = "stat-label", i18n$t("Pending"))
            )
          ),
          div(style = "text-align: right;",
            div(style = "font-size: 2em; font-weight: bold;", paste0(progress_pct, "%")),
            div(style = "font-size: 0.9em; opacity: 0.9;", i18n$t("Reviewed"))
          )
        )
      )
    })

    # Observe tab changes to track the active tab
    observeEvent(input$batch_tabs, {
      rv$active_tab <- input$batch_tabs
    }, ignoreNULL = FALSE, ignoreInit = TRUE)

    # Dynamic tab generation
    output$dynamic_tabs <- renderUI({
      batched <- batched_connections()
      batch_lists <- batched$batches

      if (length(batch_lists) == 0) {
        return(NULL)
      }

      # Create a tab for each non-empty batch
      tabs <- lapply(names(batch_lists), function(batch_id) {
        batch <- batch_lists[[batch_id]]
        conn_count <- length(batch$connections)

        # Count approved/rejected in this batch
        batch_approved <- sum(batch$indices %in% rv$approved)
        batch_rejected <- sum(batch$indices %in% rv$rejected)
        batch_pending <- conn_count - batch_approved - batch_rejected

        # Calculate approval percentage
        approval_pct <- if (conn_count > 0) round(batch_approved / conn_count * 100) else 0

        # Determine badge color based on approval percentage
        badge_color <- if (approval_pct == 100) {
          "#28a745"  # Green - all approved
        } else if (approval_pct >= 50) {
          "#ffc107"  # Yellow/Orange - partial approval
        } else if (approval_pct > 0) {
          "#fd7e14"  # Orange - some approved
        } else {
          "#6c757d"  # Gray - none approved
        }

        # Create tab label with colored badge showing approval status
        tab_label <- tags$span(
          icon(batch$info$icon),
          " ",
          i18n$t(batch$info$label),
          " ",
          tags$span(
            class = "tab-badge",
            style = sprintf("background-color: %s; color: white; padding: 2px 6px; border-radius: 10px; font-size: 0.85em; margin-left: 5px;", badge_color),
            sprintf("%d/%d", batch_approved, conn_count)
          )
        )

        tabPanel(
          title = tab_label,
          value = batch_id,

          br(),

          # Batch description
          div(class = "batch-description",
            icon("info-circle"), " ",
            i18n$t(batch$info$description)
          ),

          # Batch-specific statistics and actions
          div(class = "batch-stats-box",
            div(style = "display: flex; justify-content: space-between; align-items: center;",
              div(
                span(class = "stat-item",
                  span(class = "stat-value", conn_count),
                  span(class = "stat-label", i18n$t("Connections"))
                ),
                span(class = "stat-item",
                  span(class = "stat-value", batch_approved),
                  span(class = "stat-label", i18n$t("Approved"), style = "color: #d4edda;")
                ),
                span(class = "stat-item",
                  span(class = "stat-value", batch_rejected),
                  span(class = "stat-label", i18n$t("Rejected"), style = "color: #f8d7da;")
                ),
                span(class = "stat-item",
                  span(class = "stat-value", batch_pending),
                  span(class = "stat-label", i18n$t("Pending"))
                )
              ),
              div(style = "text-align: right;",
                actionButton(ns(paste0("approve_all_", batch_id)),
                            i18n$t("Approve All"),
                            icon = icon("check-circle"),
                            class = "btn-success btn-sm",
                            style = "margin-left: 5px;"),
                actionButton(ns(paste0("reject_all_", batch_id)),
                            i18n$t("Reject All"),
                            icon = icon("times-circle"),
                            class = "btn-danger btn-sm",
                            style = "margin-left: 5px;")
              )
            )
          ),

          # Connection cards for this batch
          div(style = "max-height: 600px; overflow-y: auto; padding: 10px;",
            uiOutput(ns(paste0("batch_connections_", batch_id)))
          )
        )
      })

      # Preserve the currently selected tab when re-rendering
      selected_tab <- if (!is.null(rv$active_tab)) rv$active_tab else names(batch_lists)[1]

      do.call(tabsetPanel, c(list(id = ns("batch_tabs"), type = "pills", selected = selected_tab), tabs))
    })

    # Render connections for each batch
    # Use a simple session counter approach
    batch_session <- reactiveVal(0)
    last_batch_count <- reactiveVal(-1)
    last_batch_names <- reactiveVal(character(0))

    observe({
      batched <- batched_connections()
      batch_lists <- batched$batches
      current_batches <- names(batch_lists)

      # Check if batches have actually changed (different count or names)
      if (length(batch_lists) != last_batch_count() ||
          !setequal(current_batches, last_batch_names())) {
        cat(sprintf("[CONN REVIEW TABBED] Batches changed: %d -> %d, incrementing session\n",
                    last_batch_count(), length(batch_lists)))
        last_batch_count(length(batch_lists))
        last_batch_names(current_batches)
        batch_session(batch_session() + 1)
      }

      # Create outputs for all batches in current session
      current_session <- batch_session()

      lapply(names(batch_lists), function(batch_id) {
        local({
          local_batch_id <- batch_id
          output_name <- paste0("batch_connections_", local_batch_id)

          cat(sprintf("[CONN REVIEW TABBED] Creating batch output: %s (session %d)\n", output_name, current_session))

          output[[output_name]] <- renderUI({
            batch <- batch_lists[[local_batch_id]]
            conns <- batch$connections
            indices <- batch$indices

            if (length(conns) == 0) {
              return(div(class = "empty-batch-message",
                        div(class = "empty-batch-icon", icon("inbox")),
                        div(i18n$t("No connections in this category"))))
            }

            # Create cards for each connection
            connection_cards <- lapply(seq_along(conns), function(i) {
              conn <- conns[[i]]
              conn_idx <- indices[i]  # Original index in full list

              render_connection_card(conn, conn_idx, ns, i18n, rv, indices, i)
            })

            do.call(tagList, connection_cards)
          })

          # Suspend when hidden to prevent unnecessary updates
          outputOptions(output, output_name, suspendWhenHidden = TRUE)
        })
      })
    })

    # Set up observers for batch-level approve/reject all buttons
    observe({
      batched <- batched_connections()
      batch_lists <- batched$batches

      lapply(names(batch_lists), function(batch_id) {
        local({
          local_batch_id <- batch_id
          batch <- batch_lists[[local_batch_id]]

          # Approve All button for this batch
          observeEvent(input[[paste0("approve_all_", local_batch_id)]], {
            # Approve all connections in this batch
            rv$approved <- union(rv$approved, batch$indices)
            # Remove any from rejected list
            rv$rejected <- setdiff(rv$rejected, batch$indices)

            if (!is.null(on_approve)) {
              lapply(batch$indices, function(idx) on_approve(idx, batch$connections[[which(batch$indices == idx)]]))
            }

            showNotification(
              sprintf(i18n$t("All %d connections in %s approved!"),
                     length(batch$indices),
                     i18n$t(batch$info$label)),
              type = "message",
              duration = 3
            )
          })

          # Reject All button for this batch
          observeEvent(input[[paste0("reject_all_", local_batch_id)]], {
            # Reject all connections in this batch
            rv$rejected <- union(rv$rejected, batch$indices)
            # Remove any from approved list
            rv$approved <- setdiff(rv$approved, batch$indices)

            if (!is.null(on_reject)) {
              lapply(batch$indices, function(idx) on_reject(idx, batch$connections[[which(batch$indices == idx)]]))
            }

            showNotification(
              sprintf(i18n$t("All %d connections in %s rejected!"),
                     length(batch$indices),
                     i18n$t(batch$info$label)),
              type = "warning",
              duration = 3
            )
          })
        })
      })
    })

    # Set up observers for all connection buttons
    # Use a simple session counter that increments each time connections change
    observer_session <- reactiveVal(0)
    last_generation_time <- reactiveVal(NULL)
    last_connections_signature <- reactiveVal(NULL)

    # Destroy and recreate all observers when connections actually change
    observe({
      req(connections_reactive())
      conns <- connections_reactive()

      # GUARD: Don't process if connections are empty - prevents infinite loop
      if (length(conns) == 0) {
        cat("[CONN REVIEW TABBED] WARNING: Connections are empty, skipping observer setup\n")
        return()
      }

      # Create a signature of the actual connection content to detect real changes
      # This prevents infinite loops when connections_reactive() invalidates but content is unchanged
      conn_signature <- digest::digest(lapply(conns, function(c) {
        list(
          from_type = c$from_type %|||% "",
          from_index = c$from_index %|||% 0,
          to_type = c$to_type %|||% "",
          to_index = c$to_index %|||% 0,
          polarity = c$polarity %|||% "+",
          strength = c$strength %|||% "medium"
        )
      }))

      # Check if connections have actually changed (by content, not just timestamp)
      if (!is.null(last_connections_signature()) &&
          identical(conn_signature, last_connections_signature())) {
        # Connections are identical - skip recreation to prevent infinite loop
        return()
      }

      # Check the generation timestamp to detect real changes
      generation_time <- attr(conns, "generated_at")

      # Connections have changed - update signature and increment session
      cat(sprintf("[CONN REVIEW TABBED] Connections changed (count: %d), incrementing session to %d\n",
                  length(conns), observer_session() + 1))
      last_connections_signature(conn_signature)
      last_generation_time(generation_time)
      observer_session(observer_session() + 1)

      # Create all observers for current session
      # Using session number ensures old observers are effectively ignored
      current_session <- observer_session()

      lapply(seq_along(conns), function(conn_idx) {
        local({
          local_idx <- conn_idx
          conn <- conns[[local_idx]]

          # Strength label output
          output[[paste0("strength_label_", local_idx)]] <- renderText({
            amended <- rv$amended_data[[as.character(local_idx)]]
            strength_value <- input[[paste0("strength_", local_idx)]] %||% 3

            strength_labels <- c("Very Weak", "Weak", "Medium", "Strong", "Very Strong")
            strength_labels[strength_value]
          })

          # Confidence label output
          output[[paste0("confidence_label_", local_idx)]] <- renderText({
            conf_value <- input[[paste0("confidence_", local_idx)]] %||% 3
            conf_labels <- c("Very Low", "Low", "Medium", "High", "Very High")
            conf_labels[conf_value]
          })

          # Polarity text output (reactive to switch)
          output[[paste0("polarity_text_", local_idx)]] <- renderUI({
            # Get current polarity from amended data or switch input
            amended <- rv$amended_data[[as.character(local_idx)]]
            if (!is.null(amended$polarity)) {
              polarity <- amended$polarity
            } else {
              switch_value <- input[[paste0("polarity_switch_", local_idx)]]
              polarity <- if (is.null(switch_value) || switch_value) "+" else "-"
            }

            # Determine arrow class and symbol
            is_positive <- polarity == "+"
            arrow_class <- if (is_positive) "conn-arrow-positive" else "conn-arrow-negative"

            span(class = arrow_class, polarity)
          })

          # Rationale text output (reactive to switch)
          output[[paste0("rationale_", local_idx)]] <- renderText({
            # Get current polarity from amended data or switch input
            amended <- rv$amended_data[[as.character(local_idx)]]
            if (!is.null(amended$polarity)) {
              current_polarity <- amended$polarity
            } else {
              switch_value <- input[[paste0("polarity_switch_", local_idx)]]
              current_polarity <- if (is.null(switch_value) || switch_value) "+" else "-"
            }

            if (current_polarity == "+") "drives/increases" else "affects/reduces"
          })

          # Approve button
          observeEvent(input[[paste0("approve_", local_idx)]], {
            rv$approved <- union(rv$approved, local_idx)
            rv$rejected <- setdiff(rv$rejected, local_idx)

            if (!is.null(on_approve)) {
              on_approve(local_idx, conn)
            }

            # Focus on next connection in the list
            if (local_idx < length(conns)) {
              next_idx <- local_idx + 1
              session$sendCustomMessage(
                type = "focusButton",
                message = list(id = session$ns(paste0("approve_", next_idx)))
              )
            }
          })

          # Reject button
          observeEvent(input[[paste0("reject_", local_idx)]], {
            rv$rejected <- union(rv$rejected, local_idx)
            rv$approved <- setdiff(rv$approved, local_idx)

            if (!is.null(on_reject)) {
              on_reject(local_idx, conn)
            }

            # Focus on next connection in the list
            if (local_idx < length(conns)) {
              next_idx <- local_idx + 1
              session$sendCustomMessage(
                type = "focusButton",
                message = list(id = session$ns(paste0("approve_", next_idx)))
              )
            }
          })

          # Amend button
          observeEvent(input[[paste0("amend_", local_idx)]], {
            strength_value <- input[[paste0("strength_", local_idx)]]
            conf_value <- input[[paste0("confidence_", local_idx)]]
            polarity_value <- input[[paste0("polarity_switch_", local_idx)]]

            # Convert strength slider value to label
            strength_labels <- c("very weak", "weak", "medium", "strong", "very strong")
            strength_label <- strength_labels[strength_value]

            # Convert polarity switch (TRUE/FALSE) to +/-
            polarity <- if (is.null(polarity_value) || polarity_value) "+" else "-"

            # Store amended data
            rv$amended_data[[as.character(local_idx)]] <- list(
              strength = strength_label,
              confidence = conf_value,
              polarity = polarity
            )

            if (!is.null(on_amend)) {
              on_amend(local_idx, polarity, strength_label, conf_value)
            }

            showNotification(
              i18n$t("Connection amended successfully"),
              type = "message",
              duration = 2
            )
          })
        })
      })
    })

    # Return reactive values for external access
    return(reactive({
      list(
        approved = rv$approved,
        rejected = rv$rejected,
        amended_data = rv$amended_data,
        batches = batched_connections()$batches
      )
    }))
  })
}

# ============================================================================
# HELPER FUNCTION: RENDER CONNECTION CARD
# ============================================================================

render_connection_card <- function(conn, conn_idx, ns, i18n, rv, batch_indices = NULL, pos_in_batch = NULL) {
  # Determine status class
  status_class <- "conn-card-tabbed"
  if (conn_idx %in% rv$approved) {
    status_class <- paste(status_class, "conn-card-approved")
  } else if (conn_idx %in% rv$rejected) {
    status_class <- paste(status_class, "conn-card-rejected")
  }

  # Get amended values if they exist, otherwise use connection defaults
  amended <- rv$amended_data[[as.character(conn_idx)]]
  current_polarity <- if (!is.null(amended$polarity) && !is.na(amended$polarity)) amended$polarity else (conn$polarity %|||% "+")
  current_strength <- if (!is.null(amended$strength) && !is.na(amended$strength)) amended$strength else (conn$strength %|||% "medium")
  current_confidence <- if (!is.null(amended$confidence) && !is.na(amended$confidence)) amended$confidence else (conn$confidence %|||% 3)

  # Convert strength to slider value (1-5)
  strength_map <- c("very weak" = 1, "weak" = 2, "medium" = 3, "strong" = 4, "very strong" = 5)
  strength_value <- strength_map[current_strength] %|||% 3

  # Polarity switch initial value
  polarity_initial <- isTRUE(current_polarity == "+")

  div(class = status_class,
    # Connection header with polarity display and switch
    div(class = "conn-header-tabbed", style = "display: flex; justify-content: space-between; align-items: center;",
      div(style = "flex: 1;",
  span(conn$from_name %|||% "Unknown"),
        span(" "),
        uiOutput(ns(paste0("polarity_text_", conn_idx)), inline = TRUE),
        span(" "),
        span(class = "conn-rationale",
             textOutput(ns(paste0("rationale_", conn_idx)), inline = TRUE)),
        span(" "),
  span(conn$to_name %|||% "Unknown")
      ),
      # Polarity switch in header
      div(style = "margin-left: 15px;",
        switchInput(
          inputId = ns(paste0("polarity_switch_", conn_idx)),
          label = NULL,
          value = polarity_initial,
          onLabel = "+",
          offLabel = "-",
          onStatus = "success",
          offStatus = "danger",
          size = "mini",
          width = "50px"
        )
      )
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
            title = "1: Very Weak - Minimal influence\n2: Weak - Small influence\n3: Medium - Moderate influence\n4: Strong - Significant influence\n5: Very Strong - Major influence"
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
            title = "1: Very Low - Highly uncertain\n2: Low - Uncertain with limited evidence\n3: Medium - Moderately certain\n4: High - Confident with good evidence\n5: Very High - Highly confident, well-established"
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

    # Control buttons
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

      # Approve button
      div(style = "width: 110px;",
        tags$div(
          `data-toggle` = "tooltip",
          `data-placement` = "top",
          title = i18n$t("Accept this connection as-is or with amendments"),
          actionButton(ns(paste0("approve_", conn_idx)),
                      i18n$t("Approve"),
                      icon = icon("check"),
                      class = "btn-success btn-sm",
                      style = "width: 100%; height: 32px; padding: 6px 8px;")
        )
      ),

      # Reject button
      div(style = "width: 110px;",
        tags$div(
          `data-toggle` = "tooltip",
          `data-placement` = "top",
          title = i18n$t("Reject this connection and exclude it from your model"),
          actionButton(ns(paste0("reject_", conn_idx)),
                      i18n$t("Reject"),
                      icon = icon("times"),
                      class = "btn-danger btn-sm",
                      style = "width: 100%; height: 32px; padding: 6px 8px;")
        )
      )
    )
  )
}
