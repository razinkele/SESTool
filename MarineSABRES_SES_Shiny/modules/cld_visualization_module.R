# modules/cld_visualization_module.R
# Main CLD visualization module using visNetwork

# ============================================================================
# UI FUNCTION
# ============================================================================

#' CLD Visualization Module UI
#'
#' Creates the user interface for the Causal Loop Diagram visualization module.
#' Includes a collapsible sidebar with controls for layout, filtering, search,
#' focus mode, and node sizing, along with a main panel for the network visualization.
#'
#' @param id Character string. Module namespace ID.
#' @param i18n Translator object for internationalization.
#'
#' @return A Shiny UI element containing the CLD visualization interface.
#'
#' @details
#' The UI features:
#' \itemize{
#'   \item Collapsible left sidebar with smooth CSS transitions
#'   \item Layout controls (hierarchical, physics-based, circular)
#'   \item Filters for element types, polarity, strength, and confidence
#'   \item Search and highlight functionality
#'   \item Focus mode to isolate nodes and their neighbors
#'   \item Node sizing based on centrality metrics
#'   \item Floating toggle button for sidebar visibility
#'   \item Frameless visNetwork canvas with legend
#' }
#'
#' @examples
#' \dontrun{
#' ui <- fluidPage(
#'   cld_viz_ui("cld_module", i18n)
#' )
#' }
#'
#' @export
cld_viz_ui <- function(id, i18n) {
  ns <- NS(id)
  tryCatch(shiny.i18n::usei18n(i18n$translator %||% i18n), error = function(e) NULL)  # Enable reactive translation updates

  tagList(
    tags$style(HTML("
      /* Remove all frames from visNetwork elements */
      .cld-network-container .vis-network {
        border: none !important;
        box-shadow: none !important;
        background: transparent !important;
      }
      .cld-network-container canvas {
        border: none !important;
        box-shadow: none !important;
      }
      /* Remove frame from legend and position it lower */
      .cld-network-container .vis-legend {
        border: none !important;
        box-shadow: none !important;
        background: transparent !important;
        padding: 0 !important;
        top: 40px !important;
        position: relative !important;
      }
      .cld-network-container .vis-legend-text {
        border: none !important;
        background: transparent !important;
      }
      /* Move legend wrapper down */
      .cld-network-container div.vis-network div.vis-legend {
        margin-top: 35px !important;
      }
      /* Auto-fit legend to window height so user doesn't manually
         resize when it overflows vertically with many DAPSIWRM groups.
         bottom:20px keeps clearance from the canvas border; overflow-y
         scrolls if still too tall (e.g., small laptop screens). */
      .cld-network-container .vis-legend,
      .cld-network-container div.vis-network div.vis-legend {
        max-height: calc(100vh - 150px) !important;
        overflow-y: auto !important;
        overflow-x: hidden !important;
      }
      /* In fullscreen mode the legend has more room */
      .network-fullscreen-container.is-fullscreen .vis-legend {
        max-height: calc(100vh - 80px) !important;
      }
      /* Scrollbar styling — subtle so it doesn't draw attention */
      .cld-network-container .vis-legend::-webkit-scrollbar {
        width: 6px;
      }
      .cld-network-container .vis-legend::-webkit-scrollbar-thumb {
        background: rgba(0, 0, 0, 0.2);
        border-radius: 3px;
      }
      .cld-network-container .vis-legend::-webkit-scrollbar-track {
        background: transparent;
      }
      /* Style control sections inside box */
      .cld-controls-box h5 {
        font-weight: 600;
        color: #333;
        margin-bottom: 10px;
        margin-top: 5px;
      }
      .cld-controls-box hr {
        margin-top: 20px;
        margin-bottom: 15px;
        border-top: 1px solid #e0e0e0;
      }
      .cld-controls-box .form-group {
        margin-bottom: 15px;
      }
      /* Compact card header */
      .compact-card .card-header {
        padding: 8px 12px !important;
        min-height: auto !important;
      }
      .compact-card .card-header .card-title {
        font-size: 13px !important;
        font-weight: 500 !important;
        margin: 0 !important;
      }
      .compact-card .card-body {
        padding: 10px !important;
      }
      /* Fullscreen toggle button */
      .fullscreen-toggle-btn {
        display: flex;
        align-items: center;
        gap: 5px;
        padding: 6px 12px;
        background: rgba(255, 255, 255, 0.9);
        border: 1px solid #dee2e6;
        border-radius: 4px;
        transition: all 0.2s ease;
      }
      .fullscreen-toggle-btn:hover {
        background: #f8f9fa;
        border-color: #007bff;
        color: #007bff;
      }
      .fullscreen-toggle-btn .fullscreen-label {
        font-size: 0.85rem;
      }
      /* Fullscreen mode styles */
      .network-fullscreen-container.is-fullscreen {
        position: fixed !important;
        top: 0 !important;
        left: 0 !important;
        right: 0 !important;
        bottom: 0 !important;
        width: 100vw !important;
        height: 100vh !important;
        z-index: 9999 !important;
        background: white !important;
        padding: 20px !important;
        margin: 0 !important;
      }
      .network-fullscreen-container.is-fullscreen .vis-network {
        height: calc(100vh - 40px) !important;
      }
      /* Exit fullscreen button (shown in fullscreen mode) */
      .fullscreen-exit-btn {
        position: fixed;
        top: 15px;
        right: 15px;
        z-index: 10000;
        display: none;
        padding: 8px 16px;
        background: #dc3545;
        color: white;
        border: none;
        border-radius: 4px;
        cursor: pointer;
        font-size: 0.9rem;
      }
      .fullscreen-exit-btn:hover {
        background: #c82333;
      }
      .network-fullscreen-container.is-fullscreen + .fullscreen-exit-btn,
      .is-fullscreen .fullscreen-exit-btn {
        display: flex;
        align-items: center;
        gap: 5px;
      }
    ")),

    # Compact inline popup for adding new nodes (similar to visNetwork native style)
    tags$style(HTML(sprintf("
      #%s {
        position: fixed;
        top: 50%%;
        left: 50%%;
        transform: translate(-50%%, -50%%);
        z-index: 10000;
        background: white;
        border: 1px solid #ccc;
        border-radius: 4px;
        box-shadow: 0 2px 10px rgba(0,0,0,0.2);
        padding: 10px;
        width: 280px;
        font-size: 12px;
      }
      #%s .form-group {
        margin-bottom: 8px;
      }
      #%s label {
        font-size: 11px;
        margin-bottom: 2px;
        font-weight: 500;
      }
      #%s .form-control {
        font-size: 12px;
        padding: 4px 8px;
        height: auto;
      }
      #%s .popup-header {
        font-weight: 600;
        font-size: 13px;
        margin-bottom: 10px;
        padding-bottom: 6px;
        border-bottom: 1px solid #eee;
      }
      #%s .popup-buttons {
        display: flex;
        gap: 6px;
        justify-content: flex-end;
        margin-top: 10px;
        padding-top: 8px;
        border-top: 1px solid #eee;
      }
      #%s .popup-buttons .btn {
        font-size: 11px;
        padding: 4px 12px;
      }
    ", ns("add_node_modal_container"), ns("add_node_modal_container"),
       ns("add_node_modal_container"), ns("add_node_modal_container"),
       ns("add_node_modal_container"), ns("add_node_modal_container"),
       ns("add_node_modal_container")))),

    shinyjs::hidden(
      div(
        id = ns("add_node_modal_container"),
        div(class = "popup-header", i18n$t("modules.cld.visualization.add_new_element")),
        selectInput(
          ns("new_node_type"),
          i18n$t("modules.cld.visualization.element_type"),
          choices = setNames(DAPSIWRM_ELEMENTS, DAPSIWRM_ELEMENTS),
          selected = "Activities",
          width = "100%"
        ),
        textInput(
          ns("new_node_label"),
          i18n$t("modules.cld.visualization.element_name"),
          placeholder = i18n$t("modules.cld.visualization.enter_element_name"),
          width = "100%"
        ),
        div(
          class = "popup-buttons",
          tags$button(
            type = "button",
            class = "btn btn-outline-secondary btn-sm",
            onclick = sprintf("Shiny.setInputValue('%s', {cancel: true, nonce: Math.random()});", ns("add_node_response")),
            i18n$t("common.buttons.cancel")
          ),
          tags$button(
            type = "button",
            class = "btn btn-primary btn-sm",
            onclick = sprintf("Shiny.setInputValue('%s', {confirm: true, nonce: Math.random()});", ns("add_node_response")),
            i18n$t("common.buttons.add")
          )
        )
      )
    ),

    # Edit Edge Modal - for editing edge properties
    tags$style(HTML(sprintf("
      #%s {
        position: fixed;
        top: 50%%;
        left: 50%%;
        transform: translate(-50%%, -50%%);
        z-index: 10000;
        background: white;
        border: 1px solid #ccc;
        border-radius: 4px;
        box-shadow: 0 2px 10px rgba(0,0,0,0.2);
        padding: 10px;
        width: 300px;
        font-size: 12px;
      }
      #%s .form-group {
        margin-bottom: 8px;
      }
      #%s label {
        font-size: 11px;
        margin-bottom: 2px;
        font-weight: 500;
      }
      #%s .form-control {
        font-size: 12px;
        padding: 4px 8px;
        height: auto;
      }
      #%s .popup-header {
        font-weight: 600;
        font-size: 13px;
        margin-bottom: 10px;
        padding-bottom: 6px;
        border-bottom: 1px solid #eee;
      }
      #%s .popup-buttons {
        display: flex;
        gap: 6px;
        justify-content: flex-end;
        margin-top: 10px;
        padding-top: 8px;
        border-top: 1px solid #eee;
      }
      #%s .popup-buttons .btn {
        font-size: 11px;
        padding: 4px 12px;
      }
      #%s .edge-info {
        background: #f8f9fa;
        padding: 8px;
        border-radius: 4px;
        margin-bottom: 10px;
        font-size: 11px;
      }
      #%s .edge-info strong {
        color: #495057;
      }
    ", ns("edit_edge_modal_container"), ns("edit_edge_modal_container"),
       ns("edit_edge_modal_container"), ns("edit_edge_modal_container"),
       ns("edit_edge_modal_container"), ns("edit_edge_modal_container"),
       ns("edit_edge_modal_container"), ns("edit_edge_modal_container"),
       ns("edit_edge_modal_container")))),

    shinyjs::hidden(
      div(
        id = ns("edit_edge_modal_container"),
        div(class = "popup-header", i18n$t("modules.cld.visualization.edit_connection")),
        div(
          class = "edge-info",
          id = ns("edit_edge_info"),
          tags$strong(i18n$t("modules.cld.visualization.connection")), ": ",
          span(id = ns("edit_edge_from_to"), "")
        ),
        selectInput(
          ns("edit_edge_polarity"),
          i18n$t("modules.cld.visualization.polarity"),
          choices = c(
            "Reinforcing (+)" = "+",
            "Opposing (-)" = "-"
          ),
          selected = "+",
          width = "100%"
        ),
        selectInput(
          ns("edit_edge_strength"),
          i18n$t("modules.cld.visualization.strength"),
          choices = c(
            "Weak" = "weak",
            "Medium" = "medium",
            "Strong" = "strong"
          ),
          selected = "medium",
          width = "100%"
        ),
        selectInput(
          ns("edit_edge_confidence"),
          i18n$t("modules.cld.visualization.confidence"),
          choices = c(
            "Very Low (1/5)" = 1,
            "Low (2/5)" = 2,
            "Medium (3/5)" = 3,
            "High (4/5)" = 4,
            "Very High (5/5)" = 5
          ),
          selected = 3,
          width = "100%"
        ),
        div(
          class = "popup-buttons",
          tags$button(
            type = "button",
            class = "btn btn-outline-secondary btn-sm",
            onclick = sprintf("Shiny.setInputValue('%s', {cancel: true, nonce: Math.random()});", ns("edit_edge_response")),
            i18n$t("common.buttons.cancel")
          ),
          tags$button(
            type = "button",
            class = "btn btn-primary btn-sm",
            onclick = sprintf("Shiny.setInputValue('%s', {confirm: true, nonce: Math.random()});", ns("edit_edge_response")),
            i18n$t("common.buttons.save")
          )
        )
      )
    ),

    # Single-screen layout: controls sidebar + full network canvas (no bs4Card wrappers)
    div(
      style = "display: flex; gap: 10px; height: calc(100vh - 120px); min-height: 600px;",

      # Left sidebar - controls panel (no card wrapper)
      div(
        style = "width: 240px; min-width: 240px; overflow-y: auto; padding: 12px; background: var(--foam-white, #f8fbfd); border-right: 1px solid var(--mist-light, #e8f1f8); border-radius: 8px 0 0 8px; font-size: 13px;",

        # Layout Controls
        h5(icon("cogs"), " ", i18n$t("modules.cld.visualization.layout"), style = "font-size: 14px; margin-bottom: 10px;"),
        selectInput(
          ns("layout_type"),
          NULL,
          choices = c(
            "Hierarchical (DAPSI)" = "hierarchical",
            "Physics-based (Manual)" = "physics"
          ),
          selected = "hierarchical"
        ),

        conditionalPanel(
          condition = sprintf("input['%s'] == 'hierarchical'", ns("layout_type")),
          ns = ns,
          selectInput(
            ns("hierarchy_direction"),
            i18n$t("modules.cld.visualization.direction"),
            choices = c("Down-Up" = "DU", "Up-Down" = "UD", "Left-Right" = "LR", "Right-Left" = "RL"),
            selected = "DU"
          ),
          sliderInput(
            ns("level_separation"),
            i18n$t("modules.cld.visualization.spacing"),
            min = 50, max = 300, value = 150, step = 10
          )
        ),

        # Edit Mode Controls
        hr(style = "margin: 8px 0;"),
        h5(icon("edit"), " ", i18n$t("modules.cld.visualization.edit_mode"), style = "font-size: 14px; margin-bottom: 8px;"),
        div(
          style = "padding: 4px 0;",
          shinyWidgets::materialSwitch(
            inputId = ns("enable_manipulation"),
            label = i18n$t("modules.cld.visualization.enable_editing"),
            value = FALSE, status = "primary", right = TRUE
          ),
          tags$small(class = "text-muted", style = "display: block; margin-top: 4px;",
            i18n$t("modules.cld.visualization.edit_mode_hint"))
        ),

        # Highlight Controls
        hr(style = "margin: 8px 0;"),
        h5(icon("lightbulb"), " ", i18n$t("modules.cld.visualization.highlight"), style = "font-size: 14px; margin-bottom: 8px;"),
        div(
          style = "padding: 4px 0;",
          shinyWidgets::materialSwitch(
            inputId = ns("highlight_leverage"),
            label = i18n$t("modules.isa.data_entry.common.leverage_points"),
            value = FALSE, status = "success", right = TRUE
          )
        ),
        div(
          style = "padding: 4px 0;",
          selectInput(
            inputId = ns("selected_loop"),
            label = i18n$t("modules.cld.visualization.highlight_loop"),
            choices = c("None" = "none"), selected = "none", width = "100%"
          ),
          htmlOutput(ns("loop_tooltip"))
        )
      ),

      # Network canvas - fills remaining space, no card wrapper
      div(
        id = ns("network_fullscreen_container"),
        class = "cld-network-container network-fullscreen-container",
        style = "flex: 1; position: relative; background: white; border-radius: 0 8px 8px 0; border: 1px solid var(--mist-light, #e8f1f8);",

        # Fullscreen toggle
        tags$button(
          id = ns("fullscreen_toggle"),
          class = "btn btn-outline-secondary btn-sm fullscreen-toggle-btn",
          style = "position: absolute; top: 5px; right: 5px; z-index: 1000; padding: 3px 6px; font-size: 10px;",
          title = i18n$t("common.misc.toggle_fullscreen"),
          onclick = sprintf("toggleVisualizationFullscreen('%s')", ns("network_fullscreen_container")),
          icon("expand"),
          span(class = "fullscreen-label", i18n$t("common.buttons.fullscreen"))
        ),
        visNetworkOutput(ns("network"), height = "100%")
      )
    )
  )  # Close tagList
}

# ============================================================================
# SERVER FUNCTION
# ============================================================================

#' CLD Visualization Module Server
#'
#' Server logic for the Causal Loop Diagram visualization module.
#' Handles network generation, filtering, layout, search, focus mode,
#' and interactive updates based on user controls.
#'
#' @param id Character string. Module namespace ID (must match UI function).
#' @param project_data_reactive Reactive expression returning project data structure
#'   containing ISA data. Expected structure:
#'   \code{list(data = list(isa_data = list(...)))}
#'
#' @return Server module (no return value, side effects only).
#'
#' @details
#' The server implements:
#' \itemize{
#'   \item CLD generation from ISA data with error handling
#'   \item Efficient network caching using ISA data signatures
#'   \item Real-time filtering by element type, polarity, strength, confidence
#'   \item Layout algorithms: hierarchical, physics-based, circular
#'   \item Node search and highlight functionality
#'   \item Focus mode to show node neighborhoods
#'   \item Dynamic node sizing based on centrality metrics
#'   \item Interactive network updates via visNetworkProxy
#' }
#'
#' Performance optimizations:
#' \itemize{
#'   \item Network only rebuilt when ISA data changes (signature-based caching)
#'   \item Metrics cached and invalidated only when network changes
#'   \item Proxy updates for filtering to avoid full re-renders
#' }
#'
#' @examples
#' \dontrun{
#' server <- function(input, output, session) {
#'   project_data <- reactiveVal(init_session_data())
#'   cld_viz_server("cld_module", project_data)
#' }
#' }
#'
#' @export
cld_viz_server <- function(id, project_data_reactive, i18n, event_bus = NULL) {
  moduleServer(id, function(input, output, session) {

    # === REACTIVE VALUES ===
    rv <- reactiveValues(
      nodes = NULL,
      edges = NULL,
      network_proxy = NULL,
      selected_node = NULL,
      selected_edge = NULL,
      loops = NULL,
      metrics = NULL,
      filtered_nodes = NULL,
      filtered_edges = NULL,
      isa_hash = NULL,  # Cache hash to track ISA data changes
      last_render_hash = NULL,  # Track last rendered network hash
      layout_render_trigger = 0  # Trigger to force re-render on layout changes
    )

    # === HELPER: Create network data signature ===
    # Uses digest for proper content-based hashing (not just row counts)
    create_network_signature <- function(isa_data, cld_data = NULL) {
      if (is.null(isa_data) || length(isa_data) == 0) {
        return(NULL)
      }
      tryCatch({
        sig_data <- list(
          # ISA element data (all columns, not just counts)
          drivers = isa_data$drivers,
          activities = isa_data$activities,
          pressures = isa_data$pressures,
          marine_processes = isa_data$marine_processes,
          ecosystem_services = isa_data$ecosystem_services,
          goods_benefits = isa_data$goods_benefits,
          # Connection data (adjacency matrices)
          adjacency_matrices = isa_data$adjacency_matrices,
          # CLD analysis state (leverage scores, etc.)
          cld_leverage = if (!is.null(cld_data$nodes) && "leverage_score" %in% names(cld_data$nodes)) {
            cld_data$nodes$leverage_score
          } else NULL
        )
        digest::digest(sig_data, algo = "xxhash64")
      }, error = function(e) {
        debug_log(sprintf("Failed to create network signature: %s", e$message), "CLD VIZ")
        NULL
      })
    }

    # === GENERATE CLD FROM ISA DATA ===
    # NOTE: Manual CLD generation removed - CLD is now automatically generated
    # when ISA data changes (see automatic observer below)

    # === CREATE NODES AND EDGES (WITH SMART CACHING) ===
    # Uses digest-based signature for proper content change detection
    # Only reloads when ISA data or CLD analysis results actually change
    observe({
      req(project_data_reactive())

      project_data <- project_data_reactive()
      isa_data <- project_data$data$isa_data

      if (!is.null(isa_data) && length(isa_data) > 0) {
        # Create proper content-based signature using digest
        full_signature <- create_network_signature(isa_data, project_data$data$cld)

        if (is.null(full_signature)) {
          debug_log("Failed to create signature, skipping cache check", "CLD VIZ")
          return()
        }

        debug_log(paste("Current signature:", substr(full_signature, 1, 16)), "CLD VIZ")
        debug_log(paste("Cached signature:", substr(rv$isa_hash %||% "NULL", 1, 16)), "CLD VIZ")

        # Only reload if signature changed
        if (is.null(rv$isa_hash) || rv$isa_hash != full_signature) {
          debug_log("Signature changed - reloading CLD data", "CLD VIZ")

          if (!is.null(project_data$data$cld$nodes) &&
              nrow(project_data$data$cld$nodes) > 0) {
            # Use existing CLD nodes (preserves leverage scores and other analysis results)
            debug_log("Using existing CLD nodes with analysis results", "CLD VIZ")
            rv$nodes <- project_data$data$cld$nodes
            # Store original colors for JavaScript-based highlighting
            if (!"originalColor" %in% names(rv$nodes)) {
              rv$nodes$originalColor <- rv$nodes$color
            }
            # Always rebuild edges from adjacency matrices (they are the source of truth)
            rv$edges <- create_edges_df(isa_data, isa_data$adjacency_matrices)
            # Add IDs to edges for reliable proxy updates
            rv$edges$id <- seq_len(nrow(rv$edges))
            # Store original edge properties for JavaScript-based highlighting
            rv$edges$originalColor <- rv$edges$color
            rv$edges$originalWidth <- rv$edges$width
            debug_log(sprintf("Rebuilt edges from adjacency matrices: %d edges", nrow(rv$edges)), "CLD VIZ")
          } else {
            # No CLD exists yet - build from ISA data
            debug_log("Building new CLD from ISA data", "CLD VIZ")
            rv$nodes <- create_nodes_df(isa_data)
            # Store original colors for JavaScript-based highlighting
            rv$nodes$originalColor <- rv$nodes$color
            rv$edges <- create_edges_df(isa_data, isa_data$adjacency_matrices)
            # Add IDs to edges for reliable proxy updates
            rv$edges$id <- seq_len(nrow(rv$edges))
            # Store original edge properties for JavaScript-based highlighting
            rv$edges$originalColor <- rv$edges$color
            rv$edges$originalWidth <- rv$edges$width

            # Save initial CLD to project_data (use isolate to prevent infinite loop)
            isolate({
              pd <- project_data_reactive()
              pd$data$cld$nodes <- rv$nodes
              pd$data$cld$edges <- rv$edges
              pd$last_modified <- Sys.time()
              project_data_reactive(pd)
              debug_log("Saved initial CLD to project_data", "CLD VIZ")
            })
          }

          rv$isa_hash <- full_signature
          rv$metrics <- NULL

          debug_log(paste("Loaded nodes:", nrow(rv$nodes)), "CLD VIZ")
          debug_log(paste("Loaded edges:", nrow(rv$edges)), "CLD VIZ")
          if ("leverage_score" %in% names(rv$nodes)) {
            debug_log(paste("rv$nodes has leverage scores >0:", sum(!is.na(rv$nodes$leverage_score) & rv$nodes$leverage_score > 0)), "CLD VIZ")

            # Update tooltips to include leverage scores
            rv$nodes <- rv$nodes %>%
              mutate(
                title = if_else(
                  !is.na(leverage_score),
                  paste0(
                    title,
                    sprintf("<br/><strong>Leverage Score:</strong> %.2f", leverage_score)
                  ),
                  title
                )
              )
            debug_log("Updated tooltips with leverage scores", "CLD VIZ")
          }

          # Update focus node choices
          if (!is.null(rv$nodes) && nrow(rv$nodes) > 0) {
            # Handle NA labels by using id as fallback
            node_labels <- ifelse(is.na(rv$nodes$label) | !nzchar(rv$nodes$label),
                                  rv$nodes$id,
                                  rv$nodes$label)
            updateSelectInput(
              session,
              "focus_node",
              choices = setNames(rv$nodes$id, node_labels)
            )
          }
        } else {
          debug_log("Signature unchanged - skipping reload", "CLD VIZ")
        }
      }
    })
    
    # === CACHED NETWORK DATA ===
    # Simplified reactive that returns nodes/edges with proper caching
    # Uses bindCache with digest-based signature for efficient cache invalidation
    network_data <- reactive({
      req(rv$nodes, rv$edges)

      # Only log on actual computation (not cache hits)
      debug_log(sprintf("network_data reactive: %d nodes, %d edges",
                        nrow(rv$nodes), nrow(rv$edges)), "CLD VIZ")

      # Update filtered references for other observers
      rv$filtered_nodes <- rv$nodes
      rv$filtered_edges <- rv$edges

      list(
        nodes = rv$nodes,
        edges = rv$edges
      )
    }) %>% bindCache(
      # Cache key: hash of ISA data stored in rv$isa_hash
      rv$isa_hash
    )

    # Backward compatibility aliases (some observers may still reference these)
    filtered_data <- network_data
    sized_nodes <- reactive({
      req(network_data())
      network_data()$nodes
    })

    # === MAIN NETWORK VISUALIZATION (WITH CACHING) ===
    # NOTE: Layout inputs are isolated to prevent re-renders on layout changes.
    # Layout updates are handled via proxy observers below for better performance.
    # The visNetwork output is cached by ISA data signature to avoid expensive re-renders.
    output$network <- renderVisNetwork({
      req(network_data())

      nodes <- network_data()$nodes
      edges <- network_data()$edges

      # Check if we already rendered this exact data
      current_hash <- rv$isa_hash
      if (!is.null(rv$last_render_hash) && identical(rv$last_render_hash, current_hash)) {
        debug_log("renderVisNetwork CACHE HIT - skipping render", "CLD VIZ PERF")
        # Return early - Shiny will use cached output
      } else {
        debug_log(sprintf("renderVisNetwork triggered: %d nodes, %d edges",
                          nrow(nodes), nrow(edges)), "CLD VIZ PERF")
        rv$last_render_hash <- current_hash
      }

      # Create visNetwork with standard styling
      vis <- visNetwork(nodes, edges, height = "100%", width = "100%") %>%
        apply_standard_styling()

      # Apply INITIAL layout using isolate() to prevent re-render on layout changes
      # Subsequent layout changes are handled by proxy observers below
      layout_type <- isolate(input$layout_type)
      if (layout_type == "hierarchical") {
        vis <- apply_hierarchical_layout(
          vis,
          isolate(input$hierarchy_direction),
          isolate(input$level_separation)
        )
      } else if (layout_type == "physics") {
        vis <- apply_physics_layout(vis)
      } else if (layout_type == "circular") {
        vis <- apply_circular_layout(vis)
      }

      # Add event handlers
      vis <- vis %>%
        visEvents(
          select = sprintf(
            "function(nodes) {
              Shiny.setInputValue('%s', nodes.nodes);
              Shiny.setInputValue('%s', nodes.edges);
            }",
            session$ns("node_selected"),
            session$ns("edge_selected")
          ),
          stabilizationIterationsDone = sprintf(
            "function() {
              this.setOptions({physics: false});
              window.network_%s = this;
              console.log('[CLD VIZ] Network stabilized and stored');
            }",
            id
          ),
          type = "once",
          stabilized = sprintf(
            "function() {
              window.network_%s = this;
              console.log('[CLD VIZ] Network stabilized and stored in window.network_%s');
            }",
            id, id
          )
        )

      return(vis)
    }) %>% bindCache(
      # Cache the entire visNetwork widget by ISA data hash
      # This prevents expensive physics calculations on unchanged data
      rv$isa_hash,
      # Include layout render trigger to force re-render when switching to hierarchical
      # or changing hierarchy direction/level separation
      rv$layout_render_trigger
    )

    # Store network proxy (IMPORTANT: Use session namespace in module)
    observe({
      rv$network_proxy <- visNetworkProxy(session$ns("network"))
    })

    # === PROXY-BASED LAYOUT UPDATES ===
    # These observers update layout without full re-render (50-80% faster)

    # Handle layout type changes
    # For hierarchical: trigger full re-render (proxy-based updates don't work due to vis.js limitations)
    # For physics: use proxy for fast update
    observeEvent(input$layout_type, {
      req(rv$nodes)
      debug_log(paste("Layout type changed to:", input$layout_type), "CLD VIZ")

      if (input$layout_type == "hierarchical") {
        # Trigger full re-render for hierarchical layout
        # This is necessary because vis.js proxy-based hierarchical updates fail
        # due to edge placeholder nodes lacking level properties
        debug_log("Triggering re-render for hierarchical layout", "CLD VIZ")
        rv$layout_render_trigger <- rv$layout_render_trigger + 1
      } else if (input$layout_type == "physics") {
        # Physics can be applied via proxy (fast update)
        visNetworkProxy(session$ns("network")) %>%
          visPhysics(
            enabled = TRUE,
            solver = "forceAtlas2Based",
            forceAtlas2Based = list(
              gravitationalConstant = -50,
              centralGravity = 0.01,
              springLength = 100,
              springConstant = 0.08
            ),
            stabilization = list(
              enabled = TRUE,
              iterations = 1000,
              updateInterval = 25
            )
          )
      }
    }, ignoreInit = TRUE)  # Don't run on initial load (already handled in render)

    # Handle hierarchy direction changes - trigger re-render
    observeEvent(input$hierarchy_direction, {
      req(rv$nodes, input$layout_type == "hierarchical")
      debug_log(paste("Hierarchy direction changed to:", input$hierarchy_direction), "CLD VIZ")
      # Trigger re-render for proper hierarchical layout
      rv$layout_render_trigger <- rv$layout_render_trigger + 1
    }, ignoreInit = TRUE)

    # Handle level separation changes - trigger re-render
    observeEvent(input$level_separation, {
      req(rv$nodes, input$layout_type == "hierarchical")
      debug_log(paste("Level separation changed to:", input$level_separation), "CLD VIZ")
      # Trigger re-render for proper hierarchical layout
      rv$layout_render_trigger <- rv$layout_render_trigger + 1
    }, ignoreInit = TRUE)

    # === EDIT MODE (MANIPULATION) ===
    # Reactive value to store pending node position from visNetwork
    rv$pending_node_position <- NULL

    # Toggle manipulation mode when switch changes
    observeEvent(input$enable_manipulation, {
      req(rv$nodes)
      debug_log(paste("Edit mode toggled:", input$enable_manipulation), "CLD VIZ")

      if (input$enable_manipulation) {
        # Enable manipulation mode with custom handlers
        runjs(generate_manipulation_enable_js(id, session$ns))

        showNotification(
          i18n$t("modules.cld.visualization.edit_mode_enabled"),
          type = "message",
          duration = 3
        )
      } else {
        # Disable manipulation mode
        runjs(generate_manipulation_disable_js(id))

        showNotification(
          i18n$t("modules.cld.visualization.edit_mode_disabled"),
          type = "message",
          duration = 3
        )
      }
    }, ignoreInit = TRUE)

    # Show modal when add node is triggered
    observeEvent(input$add_node_triggered, {
      req(input$add_node_triggered)
      debug_log("Add node triggered, showing type selection modal", "CLD VIZ")

      # Store the position
      rv$pending_node_position <- list(
        x = input$add_node_triggered$x,
        y = input$add_node_triggered$y
      )

      # Clear previous input
      updateTextInput(session, "new_node_label", value = "")

      # Show the modal
      shinyjs::show("add_node_modal_container")
    })

    # Handle modal response (confirm or cancel)
    observeEvent(input$add_node_response, {
      req(input$add_node_response)

      if (isTRUE(input$add_node_response$confirm)) {
        # User confirmed - add the node
        req(input$new_node_type, input$new_node_label)

        node_type <- input$new_node_type
        node_label <- trimws(input$new_node_label)

        if (nchar(node_label) == 0) {
          showNotification(
            i18n$t("modules.cld.visualization.enter_element_name"),
            type = "warning"
          )
          return()
        }

        # Use helper to create node data
        node_info <- create_new_node_data(
          node_type, node_label, rv$nodes$id, rv$pending_node_position
        )

        debug_log(sprintf("Adding node: id=%s, type=%s, label=%s",
                          node_info$new_id, node_type, node_label), "CLD VIZ")

        # Use the stored callback to properly add the node via visNetwork
        runjs(generate_add_node_js(
          id, node_info$new_id, node_label, node_type,
          node_info$node_color, node_info$node_shape,
          node_info$level, node_info$tooltip_html
        ))

        # Update internal state
        rv$nodes <- bind_rows(rv$nodes, node_info$node_df)

        # Sync to project_data for persistence + propagate to isa_data so
        # Loop detection / Leverage points see the change (the analyses read
        # project_data$data$isa_data, not $data$cld).
        isolate({
          pd <- project_data_reactive()
          pd$data$cld$nodes <- rv$nodes
          pd <- sync_cld_to_isa_data(pd)
          project_data_reactive(pd)
          if (!is.null(event_bus) && is.function(event_bus$emit_isa_change)) {
            event_bus$emit_isa_change("cld_edit_add_node")
          }
          debug_log(sprintf("Node '%s' added and synced to isa_data", node_label), "CLD VIZ")
        })

        showNotification(
          paste(i18n$t("modules.cld.visualization.element_added"), node_label),
          type = "message",
          duration = 3
        )
      } else {
        # User cancelled - call callback with null to cancel the operation
        runjs(generate_cancel_add_node_js(id))
      }

      # Hide modal
      shinyjs::hide("add_node_modal_container")
      rv$pending_node_position <- NULL
    })

    # Handle edge addition
    observeEvent(input$edge_added, {
      req(input$edge_added)
      debug_log(sprintf("Edge added: %s -> %s", input$edge_added$from, input$edge_added$to), "CLD VIZ")

      # Add to internal state using helper
      new_edge <- create_new_edge_data(input$edge_added$from, input$edge_added$to, nrow(rv$edges))
      rv$edges <- bind_rows(rv$edges, new_edge)

      # Sync to project_data + propagate to isa_data so analyses refresh.
      isolate({
        pd <- project_data_reactive()
        pd$data$cld$edges <- rv$edges
        pd <- sync_cld_to_isa_data(pd)
        project_data_reactive(pd)
        if (!is.null(event_bus) && is.function(event_bus$emit_isa_change)) {
          event_bus$emit_isa_change("cld_edit_add_edge")
        }
        debug_log(sprintf("Edge %s -> %s added and synced to isa_data",
                          input$edge_added$from, input$edge_added$to), "CLD VIZ")
      })

      # Re-enable manipulation mode after a short delay
      runjs(generate_reenable_manipulation_js(id, "edge add"))
    })

    # Handle node label edit
    observeEvent(input$node_edited, {
      req(input$node_edited)
      node_id <- input$node_edited$id
      new_label <- input$node_edited$label
      debug_log(sprintf("Node edited: id=%s, new label=%s", node_id, new_label), "CLD VIZ")

      # Update rv$nodes
      node_idx <- which(rv$nodes$id == node_id)
      if (length(node_idx) > 0) {
        rv$nodes$label[node_idx] <- new_label
        rv$nodes$title[node_idx] <- paste0("<b>", htmltools::htmlEscape(new_label), "</b><br><i>", htmltools::htmlEscape(rv$nodes$group[node_idx]), "</i>")

        # Sync to project_data + propagate to isa_data so analyses refresh.
        isolate({
          pd <- project_data_reactive()
          pd$data$cld$nodes <- rv$nodes
          pd <- sync_cld_to_isa_data(pd)
          project_data_reactive(pd)
          if (!is.null(event_bus) && is.function(event_bus$emit_isa_change)) {
            event_bus$emit_isa_change("cld_edit_rename_node")
          }
          debug_log(sprintf("Node '%s' label updated and synced to isa_data", new_label), "CLD VIZ")
        })

        showNotification(
          paste("Element renamed to:", new_label),
          type = "message",
          duration = 3
        )
      }

      # Re-enable manipulation mode after a short delay
      runjs(generate_reenable_manipulation_js(id, "node edit"))
    })

    # Handle edge edit triggered (show modal)
    rv$pending_edge_edit <- NULL

    observeEvent(input$edit_edge_triggered, {
      req(input$edit_edge_triggered)
      debug_log(sprintf("Edit edge triggered: id=%s", input$edit_edge_triggered$id), "CLD VIZ")

      edge_id <- input$edit_edge_triggered$id
      from_id <- input$edit_edge_triggered$from
      to_id <- input$edit_edge_triggered$to

      # Find the edge in rv$edges
      edge_row <- rv$edges[rv$edges$id == edge_id, ]

      if (nrow(edge_row) == 0) {
        # Edge might be new (not yet in our data), try to find by from/to
        edge_row <- rv$edges[rv$edges$from == from_id & rv$edges$to == to_id, ]
      }

      # Get node labels for display
      from_label <- rv$nodes$label[rv$nodes$id == from_id]
      to_label <- rv$nodes$label[rv$nodes$id == to_id]

      if (length(from_label) == 0) from_label <- from_id
      if (length(to_label) == 0) to_label <- to_id

      # Store the edge being edited
      rv$pending_edge_edit <- list(
        id = edge_id,
        from = from_id,
        to = to_id
      )

      # Update the info display (use JSON encoding for safe JS string injection)
      safe_from <- jsonlite::toJSON(as.character(from_label), auto_unbox = TRUE)
      safe_to <- jsonlite::toJSON(as.character(to_label), auto_unbox = TRUE)
      runjs(sprintf(
        "document.getElementById('%s').textContent = %s + ' \u2192 ' + %s;",
        session$ns("edit_edge_from_to"), safe_from, safe_to
      ))

      # Update form values with current edge properties
      if (nrow(edge_row) > 0) {
        updateSelectInput(session, "edit_edge_polarity", selected = edge_row$polarity[1])
        updateSelectInput(session, "edit_edge_strength", selected = edge_row$strength[1])
        updateSelectInput(session, "edit_edge_confidence", selected = as.character(edge_row$confidence[1]))
      } else {
        # Defaults for new/unknown edge
        updateSelectInput(session, "edit_edge_polarity", selected = "+")
        updateSelectInput(session, "edit_edge_strength", selected = "medium")
        updateSelectInput(session, "edit_edge_confidence", selected = "3")
      }

      # Show the modal
      shinyjs::show("edit_edge_modal_container")
    })

    # Handle edge edit response (confirm or cancel)
    observeEvent(input$edit_edge_response, {
      req(input$edit_edge_response)

      if (isTRUE(input$edit_edge_response$confirm) && !is.null(rv$pending_edge_edit)) {
        # User confirmed - update the edge
        edge_id <- rv$pending_edge_edit$id
        from_id <- rv$pending_edge_edit$from
        to_id <- rv$pending_edge_edit$to

        new_polarity <- input$edit_edge_polarity
        new_strength <- input$edit_edge_strength
        new_confidence <- as.integer(input$edit_edge_confidence)

        debug_log(sprintf("Updating edge %s: polarity=%s, strength=%s, confidence=%d",
                          edge_id, new_polarity, new_strength, new_confidence), "CLD VIZ")

        # Compute new visual properties using helper
        edge_props <- compute_edge_properties(new_polarity, new_strength, new_confidence)

        # Update rv$edges
        edge_idx <- which(rv$edges$id == edge_id)
        if (length(edge_idx) == 0) {
          # Try to find by from/to
          edge_idx <- which(rv$edges$from == from_id & rv$edges$to == to_id)
        }

        if (length(edge_idx) > 0) {
          rv$edges$polarity[edge_idx] <- new_polarity
          rv$edges$strength[edge_idx] <- new_strength
          rv$edges$confidence[edge_idx] <- new_confidence
          rv$edges$color[edge_idx] <- edge_props$color
          rv$edges$width[edge_idx] <- edge_props$width
          rv$edges$label[edge_idx] <- new_polarity
          rv$edges$originalColor[edge_idx] <- edge_props$color
          rv$edges$originalWidth[edge_idx] <- edge_props$width

          # Update the edge in visNetwork
          runjs(generate_update_edge_js(id, edge_id, edge_props$color, edge_props$width, new_polarity))

          # Sync to project_data + propagate to isa_data so analyses refresh.
          isolate({
            pd <- project_data_reactive()
            pd$data$cld$edges <- rv$edges
            pd <- sync_cld_to_isa_data(pd)
            project_data_reactive(pd)
            if (!is.null(event_bus) && is.function(event_bus$emit_isa_change)) {
              event_bus$emit_isa_change("cld_edit_edge_polarity")
            }
            debug_log("Edge updated and synced to isa_data", "CLD VIZ")
          })

          showNotification(
            i18n$t("modules.cld.visualization.connection_updated"),
            type = "message",
            duration = 3
          )
        }

        # Call the visNetwork callback to confirm the edit, then re-enable manipulation
        runjs(generate_edge_edit_callback_js(id, confirm = TRUE))

      } else {
        # User cancelled - call callback with null, then re-enable manipulation mode
        runjs(generate_edge_edit_callback_js(id, confirm = FALSE))
      }

      # Hide modal
      shinyjs::hide("edit_edge_modal_container")
      rv$pending_edge_edit <- NULL
    })

    # Handle node deletion
    observeEvent(input$nodes_deleted, {
      req(input$nodes_deleted$nodes)
      deleted_ids <- input$nodes_deleted$nodes
      debug_log(sprintf("Nodes deleted: %s", paste(deleted_ids, collapse = ", ")), "CLD VIZ")

      rv$nodes <- rv$nodes %>% filter(!(id %in% deleted_ids))
      rv$edges <- rv$edges %>% filter(!(from %in% deleted_ids | to %in% deleted_ids))

      # Sync to project_data + propagate to isa_data so analyses refresh.
      isolate({
        pd <- project_data_reactive()
        pd$data$cld$nodes <- rv$nodes
        pd$data$cld$edges <- rv$edges
        pd <- sync_cld_to_isa_data(pd)
        project_data_reactive(pd)
        if (!is.null(event_bus) && is.function(event_bus$emit_isa_change)) {
          event_bus$emit_isa_change("cld_edit_delete_nodes")
        }
        debug_log("Deleted nodes synced to isa_data", "CLD VIZ")
      })

      # Re-enable manipulation mode after a short delay
      runjs(generate_reenable_manipulation_js(id, "node delete"))
    })

    # Handle edge deletion
    observeEvent(input$edges_deleted, {
      req(input$edges_deleted$edges)
      deleted_ids <- as.numeric(input$edges_deleted$edges)
      debug_log(sprintf("Edges deleted: %s", paste(deleted_ids, collapse = ", ")), "CLD VIZ")

      rv$edges <- rv$edges %>% filter(!(id %in% deleted_ids))

      # Sync to project_data + propagate to isa_data so analyses refresh.
      isolate({
        pd <- project_data_reactive()
        pd$data$cld$edges <- rv$edges
        pd <- sync_cld_to_isa_data(pd)
        project_data_reactive(pd)
        if (!is.null(event_bus) && is.function(event_bus$emit_isa_change)) {
          event_bus$emit_isa_change("cld_edit_delete_edges")
        }
        debug_log("Deleted edges synced to isa_data", "CLD VIZ")
      })

      # Re-enable manipulation mode after a short delay
      runjs(generate_reenable_manipulation_js(id, "edge delete"))
    })

    # === HIGHLIGHT LEVERAGE POINTS ===
    observeEvent(input$highlight_leverage, {
      req(rv$network_proxy, rv$nodes)

      debug_log(paste("Highlight leverage switch triggered:", input$highlight_leverage), "CLD VIZ")
      debug_log(paste("rv$nodes count:", nrow(rv$nodes)), "CLD VIZ")
      debug_log(paste("Has leverage_score column:", "leverage_score" %in% names(rv$nodes)), "CLD VIZ")
      if ("leverage_score" %in% names(rv$nodes)) {
        debug_log(paste("Nodes with non-NA leverage scores:", sum(!is.na(rv$nodes$leverage_score))), "CLD VIZ")
        debug_log(paste("Nodes with leverage scores >0:", sum(!is.na(rv$nodes$leverage_score) & rv$nodes$leverage_score > 0)), "CLD VIZ")
      }

      if (input$highlight_leverage) {
        # Use helper to build highlight data
        highlight_data <- build_leverage_highlight_data(rv$nodes, rv$edges, top_n = 10)

        if (!is.null(highlight_data)) {
          debug_log(paste("Highlighting top", length(highlight_data$top_leverage), "leverage points"), "CLD VIZ")
          debug_log(paste("Top leverage nodes:", paste(highlight_data$top_leverage, collapse=", ")), "CLD VIZ")

          # IMPORTANT: Use session namespace for proxy in module context
          visNetworkProxy(session$ns("network")) %>%
            visUpdateNodes(highlight_data$highlighted_nodes) %>%
            visUpdateEdges(highlight_data$highlighted_edges) %>%
            visFit()

          showNotification(
            paste("Showing top", length(highlight_data$top_leverage), "leverage points only"),
            type = "message",
            duration = 3
          )
        } else {
          showNotification(
            "No leverage scores found. Run Leverage Point Analysis first.",
            type = "warning"
          )
          # Reset switch
          updateMaterialSwitch(session, "highlight_leverage", value = FALSE)
        }
      } else {
        # Reset highlighting - show all nodes/edges using helper
        reset_data <- build_leverage_reset_data(rv$nodes, rv$edges)
        debug_log("Resetting leverage highlighting - showing all nodes", "CLD VIZ")

        visNetworkProxy(session$ns("network")) %>%
          visUpdateNodes(reset_data$reset_nodes) %>%
          visUpdateEdges(reset_data$reset_edges) %>%
          visUnselectAll()
      }
    })

    # === UPDATE LOOP SELECTOR DROPDOWN ===
    observe({
      project_data <- project_data_reactive()

      if (!is.null(project_data$data$analysis$loops) &&
          !is.null(project_data$data$analysis$loops$loop_info)) {
        loop_info <- project_data$data$analysis$loops$loop_info

        if (nrow(loop_info) > 0) {
          # Create choices: Loop 1, Loop 2, etc.
          choices <- c("None" = "none", setNames(1:nrow(loop_info), paste("Loop", 1:nrow(loop_info))))
          updateSelectInput(session, "selected_loop", choices = choices)

          debug_log(paste("Updated loop selector with", nrow(loop_info), "loops"), "CLD VIZ")
        }
      }
    })

    # === DISPLAY LOOP TOOLTIP ===
    output$loop_tooltip <- renderUI({
      req(input$selected_loop)

      if (input$selected_loop == "none") {
        return(NULL)
      }

      project_data <- project_data_reactive()
      if (!is.null(project_data$data$analysis$loops$loop_info)) {
        loop_info <- project_data$data$analysis$loops$loop_info
        loop_idx <- as.integer(input$selected_loop)

        if (loop_idx > 0 && loop_idx <= nrow(loop_info)) {
          loop_row <- loop_info[loop_idx, ]

          div(
            style = "background-color: #f0f8ff; padding: 10px; margin-top: 5px; border-radius: 4px; border-left: 4px solid #2196F3; font-size: 12px;",
            tags$strong(paste0(loop_row$Type, " Loop")),
            tags$br(),
            tags$small(
              style = CSS_TEXT_MUTED,
              paste0("Length: ", loop_row$Length, " elements"),
              tags$br(),
              loop_row$Elements
            )
          )
        }
      }
    })

    # === HIGHLIGHT SELECTED LOOP ===
    observeEvent(input$selected_loop, {
      req(rv$edges, rv$nodes)

      debug_log(paste("Loop selector changed to:", input$selected_loop), "CLD VIZ")

      if (input$selected_loop != "none") {
        project_data <- project_data_reactive()

        if (!is.null(project_data$data$analysis$loops)) {
          loop_info <- project_data$data$analysis$loops$loop_info
          all_loops <- project_data$data$analysis$loops$all_loops
          loop_idx <- as.integer(input$selected_loop)

          if (loop_idx > 0 && loop_idx <= length(all_loops)) {
            selected_loop <- all_loops[[loop_idx]]

            # IMPORTANT: selected_loop contains node INDICES (1, 2, 3, ...), not IDs
            # Need to convert to actual node IDs (ES_1, P_1, MPF_2, etc.)
            loop_node_indices <- as.integer(selected_loop)

            # Convert indices to actual node IDs
            loop_node_ids <- rv$nodes$id[loop_node_indices]

            debug_log(paste("Loop indices from analysis:", paste(loop_node_indices, collapse=", ")), "CLD VIZ")
            debug_log(paste("Converted to node IDs:", paste(loop_node_ids, collapse=", ")), "CLD VIZ")
            debug_log(paste("Highlighting loop", loop_idx, "with", length(loop_node_ids), "nodes"), "CLD VIZ")

            # Use JavaScript to highlight loop
            runjs(generate_loop_highlight_js(id, loop_node_ids))
          }
        }
      } else {
        # Clear highlighting when no loop is selected
        debug_log("Resetting loop highlighting", "CLD VIZ")

        runjs(generate_loop_reset_js(id))
      }
    })

    # === HELP MODAL ===
    create_help_observer(
      input, "help_cld", "Causal Loop Diagram Guide",
      tagList(
        h4(i18n$t("modules.cld.visualization.what_is_a_causal_loop_diagram")),
        p(i18n$t("modules.cld.a_causal_loop_diagram_cld_is_a_visual_representati")),
        p(i18n$t("modules.cld.it_helps_you_understand_feedback_loops_leverage_po")),
        hr(),
        h4(i18n$t("modules.cld.visualization.how_to_read_the_diagram")),
        tags$ul(
          tags$li(strong(i18n$t("modules.cld.visualization.nodes")), i18n$t("modules.cld.represent_elements_in_your_system_drivers_activiti")),
          tags$li(strong(i18n$t("modules.cld.visualization.edges")), i18n$t("modules.cld.show_causal_connections_between_elements_arrow_dir")),
          tags$li(i18n$t("modules.cld.polarity_means_the_elements_change_in_the_same_dir"))
        ),
        hr(),
        h4(i18n$t("modules.cld.visualization.visualization_controls")),
        tags$ul(
          tags$li(strong(i18n$t("modules.cld.visualization.layout")), i18n$t("modules.cld.choose_between_hierarchical_physics_based_or_circu")),
          tags$li(strong(i18n$t("modules.cld.visualization.highlight_leverage_points")), i18n$t("modules.cld.toggle_to_highlight_the_most_influential_nodes_whe")),
          tags$li(strong(i18n$t("modules.cld.visualization.highlight_loop")), i18n$t("modules.cld.select_a_feedback_loop_to_visualize_circular_patte"))
        )
      ),
      i18n
    )

  })
}
