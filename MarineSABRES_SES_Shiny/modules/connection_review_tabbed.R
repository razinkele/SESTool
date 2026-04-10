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

# Libraries loaded in global.R: shiny, shinyWidgets

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

# Define connection batches based on framework transitions
# Labels use i18n keys - translations resolved at render time
get_connection_batches <- function() {
  list(
    list(
      id = "drivers_activities",
      label_key = "modules.connection_review.batch.drivers_activities",
      label_fallback = "Drivers → Activities",
      from_type = c("driver", "drivers"),
      to_type = c("activity", "activities"),
      description_key = "modules.connection_review.batch.drivers_activities_desc",
      description_fallback = "How societal drivers lead to human activities",
      icon = "arrow-right"
    ),
    list(
      id = "activities_pressures",
      label_key = "modules.connection_review.batch.activities_pressures",
      label_fallback = "Activities → Pressures",
      from_type = c("activity", "activities"),
      to_type = c("pressure", "pressures", "enmp"),
      description_key = "modules.connection_review.batch.activities_pressures_desc",
      description_fallback = "How activities create environmental pressures",
      icon = "arrow-right"
    ),
    list(
      id = "pressures_mpf",
      label_key = "modules.connection_review.batch.pressures_mpf",
      label_fallback = "Pressures → Marine Processes and Functions",
      from_type = c("pressure", "pressures", "enmp"),
      to_type = c("state", "states", "state change", "marine_process", "marine_processes", "mpf"),
      description_key = "modules.connection_review.batch.pressures_mpf_desc",
      description_fallback = "How pressures affect marine processes and functions",
      icon = "arrow-right"
    ),
    list(
      id = "mpf_services",
      label_key = "modules.connection_review.batch.mpf_services",
      label_fallback = "Marine Processes and Functions → Ecosystem Services",
      from_type = c("state", "states", "state change", "marine_process", "marine_processes", "mpf"),
      to_type = c("impact", "impacts", "ecosystem_service", "ecosystem_services", "es"),
      description_key = "modules.connection_review.batch.mpf_services_desc",
      description_fallback = "How marine processes affect ecosystem services",
      icon = "arrow-right"
    ),
    list(
      id = "services_welfare",
      label_key = "modules.connection_review.batch.services_welfare",
      label_fallback = "Ecosystem Services → Welfare",
      from_type = c("impact", "impacts", "ecosystem_service", "ecosystem_services", "es"),
      to_type = c("welfare", "goods_benefit", "goods_benefits", "gb", "wellbeing"),
      description_key = "modules.connection_review.batch.services_welfare_desc",
      description_fallback = "How ecosystem services affect human welfare",
      icon = "arrow-right"
    ),
    list(
      id = "welfare_responses",
      label_key = "modules.connection_review.batch.welfare_responses",
      label_fallback = "Welfare → Responses",
      from_type = c("welfare", "goods_benefit", "goods_benefits", "gb", "wellbeing"),
      to_type = c("response", "responses"),
      description_key = "modules.connection_review.batch.welfare_responses_desc",
      description_fallback = "How welfare issues trigger management responses",
      icon = "arrow-right"
    ),
    list(
      id = "responses_drivers",
      label_key = "modules.connection_review.batch.responses_drivers",
      label_fallback = "Responses → Drivers",
      from_type = c("response", "responses"),
      to_type = c("driver", "drivers"),
      description_key = "modules.connection_review.batch.responses_drivers_desc",
      description_fallback = "How management responses address drivers",
      icon = "arrow-right"
    ),
    list(
      id = "responses_activities",
      label_key = "modules.connection_review.batch.responses_activities",
      label_fallback = "Responses → Activities",
      from_type = c("response", "responses"),
      to_type = c("activity", "activities"),
      description_key = "modules.connection_review.batch.responses_activities_desc",
      description_fallback = "How management responses regulate activities",
      icon = "arrow-right"
    ),
    list(
      id = "responses_pressures",
      label_key = "modules.connection_review.batch.responses_pressures",
      label_fallback = "Responses → Pressures",
      from_type = c("response", "responses"),
      to_type = c("pressure", "pressures", "enmp"),
      description_key = "modules.connection_review.batch.responses_pressures_desc",
      description_fallback = "How management responses mitigate pressures",
      icon = "arrow-right"
    ),
    list(
      id = "welfare_drivers",
      label_key = "modules.connection_review.batch.welfare_drivers",
      label_fallback = "Welfare \u2192 Drivers (Feedback)",
      from_type = c("welfare", "goods_benefit", "goods_benefits", "gb", "wellbeing"),
      to_type = c("driver", "drivers"),
      description_key = "modules.connection_review.batch.welfare_drivers_desc",
      description_fallback = "Feedback loops showing how welfare outcomes reinforce or dampen societal drivers",
      icon = "recycle"
    ),
    list(
      id = "drivers_welfare",
      label_key = "modules.connection_review.batch.drivers_welfare",
      label_fallback = "Drivers → Welfare (Feedback)",
      from_type = c("driver", "drivers"),
      to_type = c("welfare", "goods_benefit", "goods_benefits", "gb", "wellbeing"),
      description_key = "modules.connection_review.batch.drivers_welfare_desc",
      description_fallback = "Feedback loops showing how drivers directly affect welfare outcomes",
      icon = "recycle"
    ),
    list(
      id = "pressures_pressures",
      label_key = "modules.connection_review.batch.pressures_pressures",
      label_fallback = "Pressures \u2192 Pressures (Cascading)",
      from_type = c("pressure", "pressures", "enmp"),
      to_type = c("pressure", "pressures", "enmp"),
      description_key = "modules.connection_review.batch.pressures_pressures_desc",
      description_fallback = "How one environmental pressure triggers or amplifies another",
      icon = "arrows-alt"
    ),
    list(
      id = "states_states",
      label_key = "modules.connection_review.batch.states_states",
      label_fallback = "States \u2192 States (Cascading)",
      from_type = c("state", "states", "state change", "marine_process", "marine_processes", "mpf"),
      to_type = c("state", "states", "state change", "marine_process", "marine_processes", "mpf"),
      description_key = "modules.connection_review.batch.states_states_desc",
      description_fallback = "How changes in one ecosystem component cascade to another",
      icon = "arrows-alt"
    ),
    list(
      id = "other",
      label_key = "modules.connection_review.batch.other",
      label_fallback = "Other Connections",
      from_type = NULL,
      to_type = NULL,
      description_key = "modules.connection_review.batch.other_desc",
      description_fallback = "Connections not matching standard framework transitions",
      icon = "question-circle"
    )
  )
}

# Helper function to get translated batch label
get_batch_label <- function(batch, i18n = NULL) {
  if (!is.null(i18n) && !is.null(batch$label_key)) {
    translated <- i18n$t(batch$label_key)
    # If translation returns the key itself, use fallback
    if (translated == batch$label_key && !is.null(batch$label_fallback)) {
      return(batch$label_fallback)
    }
    return(translated)
  }
  return(batch$label_fallback %||% batch$label %||% batch$id)
}

# Helper function to get translated batch description
get_batch_description <- function(batch, i18n = NULL) {
  if (!is.null(i18n) && !is.null(batch$description_key)) {
    translated <- i18n$t(batch$description_key)
    if (translated == batch$description_key && !is.null(batch$description_fallback)) {
      return(batch$description_fallback)
    }
    return(translated)
  }
  return(batch$description_fallback %||% batch$description %||% "")
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
  tryCatch(shiny.i18n::usei18n(i18n$translator %||% i18n), error = function(e) NULL)  # Enable reactive translation updates
  debug_log(sprintf("UI function called with id: %s", id), "CONN-REVIEW-TABBED")

  tagList(
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
    uiOutput(ns("dynamic_tabs")),

    # Initialize Bootstrap tooltips using native API (avoids jQuery UI conflict)
    tags$script(HTML("
      $(document).ready(function() {
        // Initialize tooltips on page load using Bootstrap native API
        // IMPORTANT: $.fn.tooltip is jQuery UI's, not Bootstrap's — use native class
        function initBootstrapTooltips() {
          document.querySelectorAll('[data-toggle=\"tooltip\"]').forEach(function(el) {
            if (!bootstrap.Tooltip.getInstance(el)) {
              new bootstrap.Tooltip(el, {
                container: 'body',
                trigger: 'hover click focus'
              });
            }
          });
        }

        initBootstrapTooltips();

        // Re-initialize tooltips when Shiny updates the DOM
        $(document).on('shiny:value shiny:recalculated', function(e) {
          setTimeout(initBootstrapTooltips, 300);
        });

        // Event delegation for dynamically added tooltips
        // Note: Do NOT call .show() manually — let trigger:'hover' handle it
        // to avoid racing with Bootstrap's internal event binding.
        // Use both BS4 ($.data) and BS5 (getInstance) checks for compatibility.
        $(document).on('mouseenter', '[data-toggle=\"tooltip\"]', function() {
          var el = this;
          var hasTooltip = $(el).data('bs.tooltip') ||
            (bootstrap.Tooltip.getInstance && bootstrap.Tooltip.getInstance(el));
          if (!hasTooltip) {
            new bootstrap.Tooltip(el, {
              container: 'body',
              trigger: 'hover focus'
            });
          }
        });
      });
    "))
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
      swapped = c(),   # Vector of connection indices with swapped direction
      amended_data = list(),  # Store amended connection data
      batches_info = list(),  # Store batch categorization info
      active_tab = NULL,  # Track the currently active tab to prevent unwanted navigation
      scroll_to = NULL,  # Target connection card ID to scroll to after re-render
      show_delay = FALSE,  # Whether to show delay inputs on connection cards
      last_action_time = NULL
    )

    # Delay toggle observer
    observeEvent(input$show_delay_toggle, {
      rv$show_delay <- isTRUE(input$show_delay_toggle)
    })

    # Observer: scroll to target card AFTER UI has re-rendered
    # If target card doesn't exist (last in batch), scroll to next-category button
    observe({
      req(rv$scroll_to)
      target_id <- rv$scroll_to
      # Invalidate immediately so this only fires once
      isolate(rv$scroll_to <- NULL)

      # Find fallback: if target card doesn't exist, find the next-category button
      # Extract the connection index from the target ID (format: ns-conn_card_N)
      # and find which batch it belongs to
      fallback_id <- NULL
      tryCatch({
        bc <- batched_connections()
        if (!is.null(bc$batches)) {
          for (batch in bc$batches) {
            if (length(batch$indices) > 0) {
              last_idx <- max(batch$indices)
              # If we're trying to scroll past the last card in this batch
              # (i.e., target is conn_card_{last_idx+1} which doesn't exist),
              # scroll to the next-category button instead
              expected_next <- ns(paste0("conn_card_", last_idx + 1))
              if (target_id == expected_next) {
                fallback_id <- ns(paste0("next_category_btn_", batch$info$id))
                break
              }
            }
          }
        }
      }, error = function(e) NULL)

      # Use retry loop to wait for DOM rebuild after renderUI re-render
      shinyjs::runjs(sprintf(
        "(function() {
          var targetId = '%s';
          var fallbackId = '%s';
          var attempts = 0;
          var maxAttempts = 20;
          function tryScroll() {
            attempts++;
            var el = document.getElementById(targetId);
            if (!el && fallbackId) { el = document.getElementById(fallbackId); }
            if (el) {
              el.scrollIntoView({behavior: 'smooth', block: 'center'});
            } else if (attempts < maxAttempts) {
              setTimeout(tryScroll, 100);
            }
          }
          setTimeout(tryScroll, 150);
        })();",
        target_id,
        fallback_id %||% ""
      ))
    })

    # Categorize connections into batches
    batched_connections <- reactive({
      req(connections_reactive())
      conns <- connections_reactive()

      debug_log(sprintf("Received %d connections", length(conns)), "CONN-REVIEW-TABBED")

      if (length(conns) == 0) {
        debug_log("No connections to display", "CONN-REVIEW-TABBED")
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
                  icon("info-circle"), " ", i18n$t("common.misc.no_connections_to_review")))
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
              span(class = "stat-label", i18n$t("common.misc.total_connections"))
            ),
            span(class = "stat-item",
              span(class = "stat-value", approved),
              span(class = "stat-label", i18n$t("common.misc.approved"), style = "color: #d4edda;")
            ),
            span(class = "stat-item",
              span(class = "stat-value", rejected),
              span(class = "stat-label", i18n$t("common.misc.rejected"), style = "color: #f8d7da;")
            ),
            span(class = "stat-item",
              span(class = "stat-value", pending),
              span(class = "stat-label", i18n$t("modules.response.measures.pending"))
            )
          ),
          div(style = "text-align: right;",
            div(style = "font-size: 2em; font-weight: bold;", paste0(progress_pct, "%")),
            div(style = "font-size: 0.9em; opacity: 0.9;", i18n$t("common.misc.reviewed"))
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
          get_batch_label(batch$info, i18n),
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
            get_batch_description(batch$info, i18n)
          ),

          # Batch-specific statistics and actions
          div(class = "batch-stats-box",
            div(style = "display: flex; justify-content: space-between; align-items: center;",
              div(
                span(class = "stat-item",
                  span(class = "stat-value", conn_count),
                  span(class = "stat-label", i18n$t("ui.dashboard.connections"))
                ),
                span(class = "stat-item",
                  span(class = "stat-value", batch_approved),
                  span(class = "stat-label", i18n$t("common.misc.approved"), style = "color: #d4edda;")
                ),
                span(class = "stat-item",
                  span(class = "stat-value", batch_rejected),
                  span(class = "stat-label", i18n$t("common.misc.rejected"), style = "color: #f8d7da;")
                ),
                span(class = "stat-item",
                  span(class = "stat-value", batch_pending),
                  span(class = "stat-label", i18n$t("modules.response.measures.pending"))
                )
              ),
              div(style = "text-align: right;",
                actionButton(ns(paste0("approve_all_", batch_id)),
                            i18n$t("modules.isa.ai_assistant.approve_all"),
                            icon = icon("check-circle"),
                            class = "btn-success btn-sm",
                            style = "margin-left: 5px;"),
                actionButton(ns(paste0("reject_all_", batch_id)),
                            i18n$t("common.misc.reject_all"),
                            icon = icon("times-circle"),
                            class = "btn-danger btn-sm",
                            style = "margin-left: 5px;")
              )
            )
          ),

          # Connection cards for this batch
          div(class = "conn-batch-content", style = "max-height: 600px; overflow-y: auto; padding: 10px;",
              `aria-live` = "polite", `aria-atomic` = "false",
            uiOutput(ns(paste0("batch_connections_", batch_id))),
            # Next Category button - appears at bottom when all connections in this batch are reviewed
            uiOutput(ns(paste0("next_category_btn_", batch_id)))
          )
        )
      })

      # Preserve the currently selected tab when re-rendering
      selected_tab <- if (!is.null(rv$active_tab)) rv$active_tab else names(batch_lists)[1]

      tagList(
        div(style = "margin-bottom: 10px; padding: 8px 12px; background: #f8f9fa; border-radius: 4px;",
          shinyWidgets::materialSwitch(
            inputId = ns("show_delay_toggle"),
            label = span(icon("clock"), " ", i18n$t("modules.connection_review.show_temporal_delay")),
            value = isolate(rv$show_delay),
            status = "warning",
            right = TRUE
          )
        ),
        do.call(tabsetPanel, c(list(id = ns("batch_tabs"), type = "pills", selected = selected_tab), tabs))
      )
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
        debug_log(sprintf("Batches changed: %d -> %d, incrementing session",
                    last_batch_count(), length(batch_lists)), "CONN-REVIEW-TABBED")
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

          debug_log(sprintf("Creating batch output: %s (session %d)", output_name, current_session), "CONN-REVIEW-TABBED")

          output[[output_name]] <- renderUI({
            show_delay <- rv$show_delay
            batch <- batch_lists[[local_batch_id]]
            conns <- batch$connections
            indices <- batch$indices

            if (length(conns) == 0) {
              return(div(class = "empty-batch-message",
                        div(class = "empty-batch-icon", icon("inbox")),
                        div(i18n$t("common.misc.no_connections_in_this_category"))))
            }

            # Create cards for each connection
            connection_cards <- lapply(seq_along(conns), function(i) {
              conn <- conns[[i]]
              conn_idx <- indices[i]  # Original index in full list

              render_connection_card(conn, conn_idx, ns, i18n, rv, indices, i, show_delay = show_delay)
            })

            do.call(tagList, connection_cards)
          })

          # Suspend when hidden to prevent unnecessary updates
          outputOptions(output, output_name, suspendWhenHidden = TRUE)

          # Next Category button - appears when all connections in this batch are reviewed
          next_btn_name <- paste0("next_category_btn_", local_batch_id)
          output[[next_btn_name]] <- renderUI({
            batch <- batch_lists[[local_batch_id]]
            indices <- batch$indices
            batch_reviewed <- length(intersect(indices, union(rv$approved, rv$rejected)))
            batch_total <- length(indices)

            # Only show if ALL connections in this batch have been reviewed
            if (batch_reviewed >= batch_total && batch_total > 0) {
              # Find next batch with connections
              batch_names <- names(batch_lists)
              current_idx <- which(batch_names == local_batch_id)

              if (current_idx < length(batch_names)) {
                next_batch_id <- batch_names[current_idx + 1]
                next_batch_label <- get_batch_label(batch_lists[[next_batch_id]]$info, i18n)

                div(style = "margin-top: 20px; padding: 15px; background: #e8f5e9; border-radius: 8px; text-align: center;",
                  p(style = "color: #2e7d32; margin-bottom: 10px;",
                    icon("check-circle"),
                    " ", i18n$t("common.misc.category_complete")),
                  actionButton(ns(paste0("goto_next_", local_batch_id)),
                              paste(i18n$t("common.buttons.next_category"), ":", next_batch_label),
                              icon = icon("arrow-right"),
                              class = "btn-success",
                              style = "min-width: 200px;")
                )
              } else {
                # This is the last batch - show completion message
                div(style = "margin-top: 20px; padding: 15px; background: #e3f2fd; border-radius: 8px; text-align: center;",
                  p(style = "color: #1565c0; margin-bottom: 10px;",
                    icon("flag-checkered"),
                    " ", i18n$t("common.misc.all_categories_reviewed")),
                  p(style = "color: #666;",
                    i18n$t("common.misc.you_can_now_finish_and_continue"))
                )
              }
            }
          })
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
              sprintf(i18n$t("common.misc.all_d_connections_in_s_approved"),
                     length(batch$indices),
                     get_batch_label(batch$info, i18n)),
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
              sprintf(i18n$t("common.misc.all_d_connections_in_s_rejected"),
                     length(batch$indices),
                     get_batch_label(batch$info, i18n)),
              type = "warning",
              duration = 3
            )
          })

          # Next Category button - switches to next tab
          observeEvent(input[[paste0("goto_next_", local_batch_id)]], {
            batch_names <- names(batch_lists)
            current_idx <- which(batch_names == local_batch_id)

            if (current_idx < length(batch_names)) {
              next_batch_id <- batch_names[current_idx + 1]
              # Update active tab
              rv$active_tab <- next_batch_id
              # Update tabsetPanel
              updateTabsetPanel(session, "batch_tabs", selected = next_batch_id)
              # Scroll to top of the new tab content
              shinyjs::runjs("setTimeout(function() { var el = document.querySelector('.conn-batch-content'); if (el) el.scrollTop = 0; }, 100);")
            }
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
        debug_log("WARNING: Connections are empty, skipping observer setup", "CONN-REVIEW-TABBED")
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
      debug_log(sprintf("Connections changed (count: %d), incrementing session to %d",
                  length(conns), observer_session() + 1), "CONN-REVIEW-TABBED")
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

            strength_labels <- c(
              i18n$t("common.labels.very_weak"),
              i18n$t("common.labels.weak"),
              i18n$t("common.labels.medium"),
              i18n$t("common.labels.strong"),
              i18n$t("common.labels.very_strong")
            )
            strength_labels[strength_value]
          })

          # Confidence label output
          output[[paste0("confidence_label_", local_idx)]] <- renderText({
            conf_value <- input[[paste0("confidence_", local_idx)]] %||% 3
            conf_labels <- c(
              i18n$t("common.labels.very_low"),
              i18n$t("common.labels.low"),
              i18n$t("common.labels.medium"),
              i18n$t("common.labels.high"),
              i18n$t("common.labels.very_high")
            )
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

          # From name output (reactive to swap direction)
          output[[paste0("from_name_", local_idx)]] <- renderUI({
            is_swapped <- local_idx %in% rv$swapped
            name <- if (is_swapped) (conn$to_name %|||% "Unknown") else (conn$from_name %|||% "Unknown")
            span(name)
          })

          # To name output (reactive to swap direction)
          output[[paste0("to_name_", local_idx)]] <- renderUI({
            is_swapped <- local_idx %in% rv$swapped
            name <- if (is_swapped) (conn$from_name %|||% "Unknown") else (conn$to_name %|||% "Unknown")
            span(name)
          })

          # Approve button - reads current slider values and applies them
          observeEvent(input[[paste0("approve_", local_idx)]], {
            # Read current slider values
            strength_value <- input[[paste0("strength_", local_idx)]]
            conf_value <- input[[paste0("confidence_", local_idx)]]
            polarity_value <- input[[paste0("polarity_switch_", local_idx)]]

            # Convert strength slider value to label
            strength_labels <- c("very weak", "weak", "medium", "strong", "very strong")
            strength_label <- strength_labels[strength_value]

            # Convert polarity switch (TRUE/FALSE) to +/-
            polarity <- if (is.null(polarity_value) || polarity_value) "+" else "-"

            # Read delay values
            delay_cat <- input[[paste0("delay_cat_", local_idx)]]
            delay_yrs <- input[[paste0("delay_years_", local_idx)]]

            # Normalize
            if (is.null(delay_cat) || delay_cat == "") delay_cat <- NA_character_
            if (is.null(delay_yrs) || is.na(delay_yrs)) delay_yrs <- NA_real_

            # If numeric was set but no category, derive it
            if (!is.na(delay_yrs) && is.na(delay_cat)) {
              delay_cat <- derive_delay_category(delay_yrs)
            }

            # Store amended data
            rv$amended_data[[as.character(local_idx)]] <- list(
              strength = strength_label,
              confidence = conf_value,
              polarity = polarity,
              delay = delay_cat,
              delay_years = delay_yrs
            )

            # Call amend callback if provided
            if (!is.null(on_amend)) {
              on_amend(local_idx, polarity, strength_label, conf_value, delay_cat, delay_yrs)
            }

            # Mark as approved
            rv$approved <- union(rv$approved, local_idx)
            rv$rejected <- setdiff(rv$rejected, local_idx)

            # Call approve callback if provided
            if (!is.null(on_approve)) {
              on_approve(local_idx, conn)
            }

            # Schedule scroll to next card (fires after re-render via observer)
            rv$scroll_to <- ns(paste0("conn_card_", local_idx + 1))
          })

          # Reject button
          observeEvent(input[[paste0("reject_", local_idx)]], {
            rv$rejected <- union(rv$rejected, local_idx)
            rv$approved <- setdiff(rv$approved, local_idx)

            if (!is.null(on_reject)) {
              on_reject(local_idx, conn)
            }

            # Schedule scroll to next card (fires after re-render via observer)
            rv$scroll_to <- ns(paste0("conn_card_", local_idx + 1))
          })

          # Swap direction button - toggle the from/to direction
          observeEvent(input[[paste0("swap_direction_", local_idx)]], {
            # Debounce: ignore if fired within 500ms of last action
            now <- as.numeric(Sys.time())
            if (!is.null(rv$last_action_time) && (now - rv$last_action_time) < 0.5) return()
            rv$last_action_time <- now

            # Toggle swapped state for this connection
            if (local_idx %in% rv$swapped) {
              rv$swapped <- setdiff(rv$swapped, local_idx)
            } else {
              rv$swapped <- union(rv$swapped, local_idx)
            }

            showNotification(
              i18n$t("common.misc.connection_direction_swapped"),
              type = "message",
              duration = 2
            )

            # Stay on the same card after swap (fires after re-render)
            rv$scroll_to <- ns(paste0("conn_card_", local_idx))
          }, ignoreInit = TRUE)
        })
      })
    })

    # Return reactive values for external access
    return(reactive({
      list(
        approved = rv$approved,
        rejected = rv$rejected,
        swapped = rv$swapped,  # Track which connections have swapped direction
        amended_data = rv$amended_data,
        batches = batched_connections()$batches
      )
    }))
  })
}

# ============================================================================
# HELPER FUNCTION: RENDER CONNECTION CARD
# ============================================================================

render_connection_card <- function(conn, conn_idx, ns, i18n, rv, batch_indices = NULL, pos_in_batch = NULL, show_delay = FALSE) {
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

  div(class = status_class, id = ns(paste0("conn_card_", conn_idx)),
    # Connection header with polarity display and switch
    div(class = "conn-header-tabbed", style = "display: flex; justify-content: space-between; align-items: center;",
      div(style = "flex: 1; display: flex; align-items: center; flex-wrap: wrap; gap: 5px;",
        # From element
        span(style = "font-weight: 500;", uiOutput(ns(paste0("from_name_", conn_idx)), inline = TRUE)),
        # Swap direction button
        actionButton(
          inputId = ns(paste0("swap_direction_", conn_idx)),
          label = icon("exchange-alt"),
          class = "btn-outline-secondary btn-xs",
          style = "padding: 2px 6px; font-size: 0.75rem; margin: 0 5px;",
          title = i18n$t("common.misc.swap_connection_direction")
        ),
        # Polarity indicator
        uiOutput(ns(paste0("polarity_text_", conn_idx)), inline = TRUE),
        # Rationale
        span(class = "conn-rationale",
             textOutput(ns(paste0("rationale_", conn_idx)), inline = TRUE)),
        # To element
        span(style = "font-weight: 500;", uiOutput(ns(paste0("to_name_", conn_idx)), inline = TRUE))
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
          icon("bolt"), " ", i18n$t("modules.isa.data_entry.common.strength"),
          span(
            icon("info-circle", style = "color: #17a2b8; cursor: help; margin-left: 5px; font-size: 0.9em;"),
            `data-toggle` = "tooltip",
            `data-placement` = "top",
            title = i18n$t("common.labels.strength_tooltip")
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
          icon("chart-bar"), " ", i18n$t("modules.isa.data_entry.common.confidence"),
          span(
            icon("info-circle", style = "color: #17a2b8; cursor: help; margin-left: 5px; font-size: 0.9em;"),
            `data-toggle` = "tooltip",
            `data-placement` = "top",
            title = i18n$t("common.labels.confidence_tooltip")
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

    # Delay input (visible when toggle is on)
    if (isTRUE(show_delay)) {
      amended <- rv$amended_data[[as.character(conn_idx)]]
      current_delay <- if (!is.null(amended$delay) && !is.na(amended$delay)) {
        amended$delay
      } else {
        conn$delay %||% ""
      }
      current_delay_years <- if (!is.null(amended$delay_years) && !is.na(amended$delay_years)) {
        amended$delay_years
      } else {
        conn$delay_years %||% NA_real_
      }

      delay_choices <- stats::setNames(
        c("", DELAY_CATEGORIES),
        c("(Not set)", sapply(DELAY_CATEGORIES, function(cat) {
          paste0(DELAY_LABELS[[cat]], " (", DELAY_RANGES[[cat]], ")")
        }))
      )

      tags$div(
        style = "border-top: 1px dashed #dee2e6; margin-top: 8px; padding-top: 8px;",
        tags$div(
          class = "conn-slider-container",
          style = "display: flex; align-items: center; gap: 8px; flex-wrap: wrap;",
          tags$span(
            style = "color: #f0c040; min-width: 60px;",
            icon("clock"), " ", i18n$t("modules.connection_review.temporal_delay"), ":"
          ),
          tags$div(
            style = "flex: 1; min-width: 140px;",
            selectInput(
              ns(paste0("delay_cat_", conn_idx)),
              label = NULL,
              choices = delay_choices,
              selected = current_delay,
              width = "100%"
            )
          ),
          tags$span(style = "color: #999;", "or"),
          tags$div(
            style = "width: 80px;",
            numericInput(
              ns(paste0("delay_years_", conn_idx)),
              label = NULL,
              value = if (!is.na(current_delay_years)) current_delay_years else NA,
              min = 0,
              step = 0.1,
              width = "100%"
            )
          ),
          tags$span(style = "color: #999; font-size: 0.85em;", "years")
        )
      )
    },

    # Control buttons (Approve/Reject only - sliders are used directly on approve)
    div(class = "conn-controls",
      # Approve button - uses current slider values
      div(style = "width: 140px;",
        tags$div(
          `data-toggle` = "tooltip",
          `data-placement` = "top",
          title = i18n$t("common.misc.approve_this_connection_with_current_slider_values"),
          actionButton(ns(paste0("approve_", conn_idx)),
                      i18n$t("common.misc.approve"),
                      icon = icon("check"),
                      class = "btn-success btn-sm",
                      style = "width: 100%; height: 32px; padding: 6px 8px;")
        )
      ),

      # Reject button - completely removes connection
      div(style = "width: 140px; margin-left: 10px;",
        tags$div(
          `data-toggle` = "tooltip",
          `data-placement` = "top",
          title = i18n$t("common.misc.reject_this_connection_and_exclude_it_from_your_model"),
          actionButton(ns(paste0("reject_", conn_idx)),
                      i18n$t("common.misc.reject"),
                      icon = icon("times"),
                      class = "btn-danger btn-sm",
                      style = "width: 100%; height: 32px; padding: 6px 8px;")
        )
      )
    )
  )
}
