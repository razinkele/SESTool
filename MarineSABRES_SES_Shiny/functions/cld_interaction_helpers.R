# functions/cld_interaction_helpers.R
# Helper functions for CLD visualization network interaction handlers
# Extracted from modules/cld_visualization_module.R to reduce module size

# ============================================================================
# MANIPULATION MODE (EDIT MODE) JAVASCRIPT GENERATION
# ============================================================================

#' Generate JavaScript to enable visNetwork manipulation mode
#'
#' Creates the JS code that sets up add/edit/delete handlers for nodes and edges
#' in the visNetwork instance. This includes custom callbacks for each operation
#' that communicate back to Shiny via setInputValue.
#'
#' @param network_id Character. The module ID used to namespace window variables.
#' @param ns Function. The Shiny namespace function (session$ns).
#' @return Character string containing JavaScript code to execute via shinyjs::runjs.
generate_manipulation_enable_js <- function(network_id, ns) {
  sprintf("
    if (window.network_%s) {
      window.addNodeCallback_%s = null;

      // Store manipulation config for re-enabling after operations
      window.manipulationConfig_%s = {
        enabled: true,
        initiallyActive: true,
        addNode: function(nodeData, callback) {
          // Store callback and node data for later use
          window.addNodeCallback_%s = callback;
          window.pendingNodeData_%s = nodeData;
          Shiny.setInputValue('%s', {
            x: nodeData.x,
            y: nodeData.y,
            nonce: Math.random()
          });
        },
        addEdge: function(edgeData, callback) {
          // Allow edge addition directly
          edgeData.arrows = 'to';
          edgeData.color = '#80b8d7';
          edgeData.width = 2;
          callback(edgeData);
          // Notify Shiny about the new edge
          Shiny.setInputValue('%s', {
            from: edgeData.from,
            to: edgeData.to,
            nonce: Math.random()
          });
        },
        editNode: function(nodeData, callback) {
          // Use native prompt for node label editing
          var newLabel = prompt('Edit element name:', nodeData.label);
          if (newLabel !== null && newLabel.trim() !== '') {
            nodeData.label = newLabel.trim();
            callback(nodeData);
            // Notify Shiny about the edit
            Shiny.setInputValue('%s', {
              id: nodeData.id,
              label: newLabel.trim(),
              nonce: Math.random()
            });
          } else {
            callback(null);
          }
        },
        editEdge: {
          editWithoutDrag: function(edgeData, callback) {
            // Store callback for later use after modal confirmation
            window.editEdgeCallback_%s = callback;
            window.pendingEdgeData_%s = edgeData;
            // Trigger Shiny to show edge properties modal
            Shiny.setInputValue('%s', {
              id: edgeData.id,
              from: edgeData.from,
              to: edgeData.to,
              nonce: Math.random()
            });
          }
        },
        deleteNode: function(nodeData, callback) {
          if (confirm('Delete this element?')) {
            callback(nodeData);
            Shiny.setInputValue('%s', {
              nodes: nodeData.nodes,
              nonce: Math.random()
            });
          } else {
            callback(null);
          }
        },
        deleteEdge: function(edgeData, callback) {
          if (confirm('Delete this connection?')) {
            callback(edgeData);
            Shiny.setInputValue('%s', {
              edges: edgeData.edges,
              nonce: Math.random()
            });
          } else {
            callback(null);
          }
        }
      };

      // Helper function to re-enable manipulation mode
      window.reEnableManipulation_%s = function() {
        if (window.network_%s && window.manipulationConfig_%s) {
          window.network_%s.setOptions({ manipulation: window.manipulationConfig_%s });
          console.log('[CLD VIZ] Manipulation mode re-enabled');
        }
      };

      // Apply initial config
      window.network_%s.setOptions({ manipulation: window.manipulationConfig_%s });
      console.log('[CLD VIZ] Manipulation mode enabled');
    }",
    network_id, network_id, network_id, network_id, network_id,
    ns("add_node_triggered"),
    ns("edge_added"),
    ns("node_edited"),
    network_id, network_id, ns("edit_edge_triggered"),
    ns("nodes_deleted"),
    ns("edges_deleted"),
    network_id, network_id, network_id, network_id, network_id, network_id, network_id
  )
}


#' Generate JavaScript to disable visNetwork manipulation mode
#'
#' @param network_id Character. The module ID used to namespace window variables.
#' @return Character string containing JavaScript code.
generate_manipulation_disable_js <- function(network_id) {
  sprintf("
    if (window.network_%s) {
      window.network_%s.setOptions({
        manipulation: {
          enabled: false
        }
      });
      console.log('[CLD VIZ] Manipulation mode disabled');
    }",
    network_id, network_id
  )
}


#' Generate JavaScript to re-enable manipulation mode after an operation
#'
#' @param network_id Character. The module ID used to namespace window variables.
#' @param context Character. Description of the operation for logging (e.g. "node add").
#' @return Character string containing JavaScript code.
generate_reenable_manipulation_js <- function(network_id, context = "operation") {
  sprintf("
    setTimeout(function() {
      if (window.network_%s) {
        window.reEnableManipulation_%s();
        console.log('[CLD VIZ] Manipulation mode re-enabled after %s');
      }
    }, 100);",
    network_id, network_id, context
  )
}


# ============================================================================
# NODE CREATION HELPERS
# ============================================================================

#' Create a new node data frame row for adding to the CLD
#'
#' Generates the data frame row with all required columns for a new node,
#' including styling from ELEMENT_COLORS and ELEMENT_SHAPES constants.
#'
#' @param node_type Character. DAPSIWRM element type (e.g. "Drivers", "Activities").
#' @param node_label Character. User-provided label for the node.
#' @param existing_node_ids Character vector. IDs of existing nodes (for generating unique ID).
#' @param position List with x, y coordinates from the canvas click. Can be NULL.
#' @return List with: node_df (data.frame row), new_id (character), level (integer),
#'   node_color (character), node_shape (character).
create_new_node_data <- function(node_type, node_label, existing_node_ids, position = NULL) {
  # Get styling from constants
  node_color <- ELEMENT_COLORS[[node_type]]
  node_shape <- ELEMENT_SHAPES[[node_type]]

  # Generate unique ID based on type
  prefix <- switch(node_type,
    "Drivers" = "D",
    "Activities" = "A",
    "Pressures" = "P",
    "Marine Processes & Functioning" = "MPF",
    "Ecosystem Services" = "ES",
    "Goods & Benefits" = "GB",
    "Responses" = "R",
    "X"
  )

  # Find next available number for this type
  existing_ids <- existing_node_ids[grepl(paste0("^", prefix, "_"), existing_node_ids)]
  if (length(existing_ids) > 0) {
    nums <- as.numeric(gsub(paste0("^", prefix, "_"), "", existing_ids))
    next_num <- max(nums, na.rm = TRUE) + 1
  } else {
    next_num <- 1
  }
  new_id <- paste0(prefix, "_", next_num)

  # Get level for hierarchical layout
  level <- switch(node_type,
    "Goods & Benefits" = 0,
    "Ecosystem Services" = 1,
    "Marine Processes & Functioning" = 2,
    "Pressures" = 3,
    "Activities" = 4,
    "Drivers" = 5,
    "Responses" = 3,
    3
  )

  # Create tooltip HTML
  tooltip_html <- paste0(
    "<div style='padding: 8px;'>",
    "<b>", htmltools::htmlEscape(node_label), "</b><br>",
    "<i>", htmltools::htmlEscape(node_type), "</i><br>",
    "<hr style='margin: 5px 0;'>",
    "Indicator: No indicator",
    "</div>"
  )

  # Create data frame row
  node_df <- data.frame(
    id = new_id,
    label = node_label,
    title = paste0("<b>", htmltools::htmlEscape(node_label), "</b><br><i>", htmltools::htmlEscape(node_type), "</i>"),
    group = node_type,
    level = level,
    shape = node_shape,
    image = NA_character_,
    color = node_color,
    size = 25,
    font.size = 12,
    indicator = "No indicator",
    leverage_score = NA_real_,
    x = if (!is.null(position)) position$x else NA_real_,
    originalColor = node_color,
    stringsAsFactors = FALSE
  )

  list(
    node_df = node_df,
    new_id = new_id,
    level = level,
    node_color = node_color,
    node_shape = node_shape,
    tooltip_html = tooltip_html
  )
}


#' Generate JavaScript to add a node via visNetwork callback
#'
#' @param network_id Character. The module ID.
#' @param new_id Character. The new node's ID.
#' @param node_label Character. The node label.
#' @param node_type Character. The DAPSIWRM element type.
#' @param node_color Character. Hex color.
#' @param node_shape Character. visNetwork shape name.
#' @param level Integer. Hierarchical level.
#' @param tooltip_html Character. HTML tooltip content.
#' @return Character string containing JavaScript code.
generate_add_node_js <- function(network_id, new_id, node_label, node_type,
                                  node_color, node_shape, level, tooltip_html) {
  # Escape for JavaScript using JSON encoding for safety against XSS
  tooltip_js_safe <- jsonlite::toJSON(as.character(tooltip_html), auto_unbox = TRUE)
  label_js_safe <- jsonlite::toJSON(as.character(node_label), auto_unbox = TRUE)

  sprintf("
    if (window.addNodeCallback_%s && window.pendingNodeData_%s) {
      var nodeData = window.pendingNodeData_%s;
      nodeData.id = '%s';
      nodeData.label = %s;
      nodeData.group = '%s';
      nodeData.color = '%s';
      nodeData.shape = '%s';
      nodeData.level = %d;
      nodeData.size = 25;
      nodeData.font = {size: 12};
      nodeData.title = %s;
      nodeData.originalColor = '%s';

      // Call the callback - visNetwork will handle adding the node properly
      window.addNodeCallback_%s(nodeData);
      window.addNodeCallback_%s = null;
      window.pendingNodeData_%s = null;
      console.log('[CLD VIZ] Node added via callback:', nodeData);
    }
    %s",
    network_id, network_id, network_id, new_id,
    label_js_safe,
    node_type, node_color, node_shape, level, tooltip_js_safe, node_color,
    network_id, network_id, network_id,
    generate_reenable_manipulation_js(network_id, "node add")
  )
}


#' Generate JavaScript to cancel a node addition
#'
#' @param network_id Character. The module ID.
#' @return Character string containing JavaScript code.
generate_cancel_add_node_js <- function(network_id) {
  sprintf("
    if (window.addNodeCallback_%s) {
      window.addNodeCallback_%s(null);
      window.addNodeCallback_%s = null;
      window.pendingNodeData_%s = null;
      console.log('[CLD VIZ] Node addition cancelled');
    }
    %s",
    network_id, network_id, network_id, network_id,
    generate_reenable_manipulation_js(network_id, "cancel")
  )
}


# ============================================================================
# EDGE CREATION HELPERS
# ============================================================================

#' Create a new edge data frame row
#'
#' @param from_id Character. Source node ID.
#' @param to_id Character. Target node ID.
#' @param max_existing_id Numeric. The maximum id currently present in the edge
#'   table (pass \code{max(c(0, suppressWarnings(as.numeric(rv$edges$id))), na.rm = TRUE)}).
#'   The new edge receives \code{max_existing_id + 1}, which is guaranteed to be
#'   unique even when the id sequence is sparse (e.g., after deletes).
#' @return Data frame with one row of edge data.
create_new_edge_data <- function(from_id, to_id, max_existing_id) {
  data.frame(
    id = max_existing_id + 1,
    from = from_id,
    to = to_id,
    arrows = "to",
    color = EDGE_COLORS$reinforcing,
    width = 2,
    opacity = 1,
    title = paste0(htmltools::htmlEscape(from_id), " \u2192 ", htmltools::htmlEscape(to_id)),
    polarity = "+",
    strength = "medium",
    confidence = 3,
    label = "+",
    font.size = 10,
    originalColor = EDGE_COLORS$reinforcing,
    originalWidth = 2,
    stringsAsFactors = FALSE
  )
}


#' Compute updated edge properties from user input
#'
#' @param new_polarity Character. "+" or "-".
#' @param new_strength Character. "weak", "medium", or "strong".
#' @param new_confidence Integer. 1-5 confidence value.
#' @return List with: color (character), width (integer).
compute_edge_properties <- function(new_polarity, new_strength, new_confidence) {
  new_color <- if (new_polarity == "+") EDGE_COLORS$reinforcing else EDGE_COLORS$opposing
  new_width <- switch(new_strength,
    "weak" = 1,
    "medium" = 2,
    "strong" = 3,
    2
  )
  list(color = new_color, width = new_width)
}


#' Generate JavaScript to update an edge in visNetwork
#'
#' @param network_id Character. The module ID.
#' @param edge_id The edge ID (numeric or character).
#' @param new_color Character. Hex color string.
#' @param new_width Integer. Edge width.
#' @param new_polarity Character. "+" or "-" label for edge.
#' @return Character string containing JavaScript code.
generate_update_edge_js <- function(network_id, edge_id, new_color, new_width, new_polarity) {
  sprintf("
    if (window.network_%s) {
      var edges = window.network_%s.body.data.edges;
      edges.update({
        id: %s,
        color: '%s',
        width: %d,
        label: '%s'
      });
      console.log('[CLD VIZ] Edge %s updated');
    }",
    network_id, network_id, edge_id, new_color, new_width, new_polarity, edge_id
  )
}


#' Generate JavaScript to confirm or cancel an edge edit via visNetwork callback
#'
#' @param network_id Character. The module ID.
#' @param confirm Logical. TRUE to confirm, FALSE to cancel.
#' @return Character string containing JavaScript code.
generate_edge_edit_callback_js <- function(network_id, confirm = TRUE) {
  if (confirm) {
    sprintf("
      if (window.editEdgeCallback_%s && window.pendingEdgeData_%s) {
        window.editEdgeCallback_%s(window.pendingEdgeData_%s);
        window.editEdgeCallback_%s = null;
        window.pendingEdgeData_%s = null;
      }
      %s",
      network_id, network_id, network_id, network_id, network_id, network_id,
      generate_reenable_manipulation_js(network_id, "edge edit")
    )
  } else {
    sprintf("
      if (window.editEdgeCallback_%s) {
        window.editEdgeCallback_%s(null);
        window.editEdgeCallback_%s = null;
        window.pendingEdgeData_%s = null;
        console.log('[CLD VIZ] Edge edit cancelled');
      }
      %s",
      network_id, network_id, network_id, network_id,
      generate_reenable_manipulation_js(network_id, "cancel")
    )
  }
}


# ============================================================================
# HIGHLIGHT HELPERS
# ============================================================================

#' Build node/edge data frames for leverage point highlighting
#'
#' @param nodes Data frame. All CLD nodes (must have leverage_score column).
#' @param edges Data frame. All CLD edges.
#' @param top_n Integer. Number of top leverage points to show (default 10).
#' @return List with: top_leverage (character vector of IDs),
#'   highlighted_nodes (data frame for visUpdateNodes),
#'   highlighted_edges (data frame for visUpdateEdges).
#'   Returns NULL if no leverage scores found.
build_leverage_highlight_data <- function(nodes, edges, top_n = 10) {
  if (!"leverage_score" %in% names(nodes)) return(NULL)

  leverage_nodes <- nodes %>%
    dplyr::filter(!is.na(leverage_score) & leverage_score > 0) %>%
    dplyr::arrange(dplyr::desc(leverage_score))

  if (nrow(leverage_nodes) == 0) return(NULL)

  top_leverage <- utils::head(leverage_nodes$id, top_n)

  highlighted_nodes <- data.frame(
    id = nodes$id,
    hidden = !(nodes$id %in% top_leverage),
    borderWidth = ifelse(nodes$id %in% top_leverage, 10, 2),
    font.size = ifelse(nodes$id %in% top_leverage, 18, 14),
    color.border = ifelse(nodes$id %in% top_leverage, "#4CAF50", "#2B7CE9"),
    color.background = nodes$color,
    stringsAsFactors = FALSE
  )

  highlighted_edges <- data.frame(
    id = seq_len(nrow(edges)),
    hidden = !(edges$from %in% top_leverage | edges$to %in% top_leverage),
    stringsAsFactors = FALSE
  )

  list(
    top_leverage = top_leverage,
    highlighted_nodes = highlighted_nodes,
    highlighted_edges = highlighted_edges
  )
}


#' Build node/edge data frames for resetting leverage highlighting
#'
#' @param nodes Data frame. All CLD nodes.
#' @param edges Data frame. All CLD edges.
#' @return List with: reset_nodes, reset_edges data frames for visUpdate.
build_leverage_reset_data <- function(nodes, edges) {
  reset_nodes <- data.frame(
    id = nodes$id,
    hidden = FALSE,
    color.border = "#2B7CE9",
    color.background = nodes$color,
    borderWidth = 2,
    font.size = as.integer(nodes$font.size),
    stringsAsFactors = FALSE
  )

  reset_edges <- data.frame(
    id = seq_len(nrow(edges)),
    hidden = FALSE,
    stringsAsFactors = FALSE
  )

  list(reset_nodes = reset_nodes, reset_edges = reset_edges)
}


#' Generate JavaScript to highlight a feedback loop in the CLD
#'
#' @param network_id Character. The module ID.
#' @param loop_node_ids Character vector. Node IDs in the loop.
#' @return Character string containing JavaScript code.
generate_loop_highlight_js <- function(network_id, loop_node_ids) {
  sprintf("
    window.selectedLoopNodes_%s = %s;
    console.log('[CLD VIZ] Selected loop nodes:', window.selectedLoopNodes_%s);

    if (window.network_%s && window.network_%s.body) {
      var allNodes = window.network_%s.body.data.nodes.get();
      var allEdges = window.network_%s.body.data.edges.get();

      // Highlight selected loop nodes
      allNodes.forEach(function(node) {
        if (window.selectedLoopNodes_%s.includes(node.id)) {
          // Loop node - restore original appearance with thick black border
          node.color = node.originalColor;
          node.opacity = 1.0;
          node.borderWidth = 3;
          node.borderColor = '#000000';
        } else {
          // Non-loop node - fade using opacity (works for both color and image nodes)
          node.color = 'rgba(200,200,200,0.3)';
          node.opacity = 0.3;
          node.borderWidth = 1;
        }
      });

      // Highlight loop edges
      allEdges.forEach(function(edge) {
        var isLoopEdge = false;
        for (var i = 0; i < window.selectedLoopNodes_%s.length; i++) {
          var currentNode = window.selectedLoopNodes_%s[i];
          var nextNode = window.selectedLoopNodes_%s[(i + 1) %% window.selectedLoopNodes_%s.length];
          if (edge.from === currentNode && edge.to === nextNode) {
            isLoopEdge = true;
            break;
          }
        }

        if (isLoopEdge) {
          // Keep original edge color and make loop edges 5x thicker for visibility
          edge.color = edge.originalColor;
          edge.width = (edge.originalWidth || 1) * 5;
        } else {
          edge.color = 'rgba(200,200,200,0.3)';
          edge.width = 1;
        }
      });

      window.network_%s.body.data.nodes.update(allNodes);
      window.network_%s.body.data.edges.update(allEdges);
    }",
    network_id, jsonlite::toJSON(loop_node_ids), network_id,
    network_id, network_id, network_id, network_id, network_id,
    network_id, network_id, network_id, network_id,
    network_id, network_id
  )
}


#' Generate JavaScript to reset loop highlighting
#'
#' @param network_id Character. The module ID.
#' @return Character string containing JavaScript code.
generate_loop_reset_js <- function(network_id) {
  sprintf("
    window.selectedLoopNodes_%s = [];
    if (window.network_%s && window.network_%s.body) {
      var allNodes = window.network_%s.body.data.nodes.get();
      var allEdges = window.network_%s.body.data.edges.get();

      allNodes.forEach(function(node) {
        node.color = node.originalColor;
        node.opacity = 1.0;
        node.borderWidth = 1;
      });

      allEdges.forEach(function(edge) {
        edge.color = edge.originalColor;
        edge.width = edge.originalWidth || 1;
      });

      window.network_%s.body.data.nodes.update(allNodes);
      window.network_%s.body.data.edges.update(allEdges);
    }",
    network_id, network_id, network_id, network_id, network_id, network_id, network_id
  )
}

# ============================================================================
# CLD <-> ISA SYNC
# ============================================================================

#' Rebuild isa_data elements + adjacency_matrices from the current CLD state
#'
#' Bridges the gap between the CLD editor (which writes project_data$data$cld$*)
#' and the analysis modules (which read project_data$data$isa_data$*). Call this
#' after any direct-graph edit so Loop detection, Leverage points, etc. see the
#' user's latest changes.
#'
#' Conversion:
#'   cld$nodes$group   -> isa_data$<drivers|activities|...>   (one DF per type)
#'   cld$nodes$label   -> name
#'   cld$nodes$id      -> id  (preserves D_1, A_2, ... prefix convention)
#'   existing indicator metadata is preserved by name-match when possible
#'
#'   cld$edges         -> isa_data$adjacency_matrices (6 SOURCE x TARGET matrices)
#'   edge label (+/-) -> cell value
#'
#' @param project_data full project reactiveValues list
#' @return project_data with isa_data regenerated from cld (last_modified bumped)
#' @export
sync_cld_to_isa_data <- function(project_data) {
  if (is.null(project_data) || is.null(project_data$data) ||
      is.null(project_data$data$cld) ||
      is.null(project_data$data$cld$nodes) ||
      is.null(project_data$data$cld$edges)) {
    return(project_data)
  }

  nodes <- project_data$data$cld$nodes
  edges <- project_data$data$cld$edges
  if (!is.data.frame(edges)) edges <- data.frame()
  # Malformed CLD (no id/group columns): nothing to sync, return unchanged.
  if (!is.data.frame(nodes) || !all(c("id", "group") %in% names(nodes))) return(project_data)
  if (!"label" %in% names(nodes)) nodes$label <- as.character(nodes$id)
  # Drop rows that cannot be placed (NA id or group) before resolving.
  nodes <- nodes[!is.na(nodes$id) & nzchar(as.character(nodes$id)) & !is.na(nodes$group), , drop = FALSE]

  # Review 2026-10-07 N3. This sync used to (a) replace element IDs with the
  # positional node ids ("GB_1") and names with the wrapped labels, (b) rebuild
  # every matrix from the edge label alone (bare polarity: strength /
  # confidence / delay lost), (c) drop user_edited_matrices and (d) lowercase
  # the frames. It now resolves every node back to its ISA element ID (carried
  # element_id -> positional -> name match -> fresh id), keeps the previous
  # matrix cell and only updates its polarity, carries user_edited flags over,
  # and preserves the previous frame's columns.

  group_to_key <- c(
    "Drivers" = "drivers",
    "Activities" = "activities",
    "Pressures" = "pressures",
    "Marine Processes & Functioning" = "marine_processes",
    "Ecosystem Services" = "ecosystem_services",
    "Goods & Benefits" = "goods_benefits",
    "Responses" = "responses"
  )
  # node-id prefix used by create_nodes_df() / create_new_node_data()
  group_to_prefix <- c(
    "Drivers" = "D", "Activities" = "A", "Pressures" = "P",
    "Marine Processes & Functioning" = "MPF", "Ecosystem Services" = "ES",
    "Goods & Benefits" = "GB", "Responses" = "R"
  )
  # matrix-key prefix (SOURCE x TARGET naming)
  group_to_mat <- c(
    "Drivers" = "d", "Activities" = "a", "Pressures" = "p",
    "Marine Processes & Functioning" = "mpf", "Ecosystem Services" = "es",
    "Goods & Benefits" = "gb", "Responses" = "r"
  )

  isa     <- project_data$data$isa_data %||% list()
  prev_am <- isa$adjacency_matrices   %||% list()
  prev_ue <- isa$user_edited_matrices %||% list()

  col_of <- function(df, candidates) {
    if (!is.data.frame(df)) return(NULL)
    hit <- candidates[candidates %in% names(df)]
    if (length(hit)) hit[1] else NULL
  }
  unwrap <- function(x) gsub("\\s*\n\\s*", " ", as.character(x))
  next_free_id <- function(prefix, taken) {
    nums <- suppressWarnings(as.integer(sub(paste0("^", prefix), "", taken[grepl(paste0("^", prefix, "[0-9]+$"), taken)])))
    n <- if (length(nums) && any(!is.na(nums))) max(nums, na.rm = TRUE) + 1L else 1L
    repeat {
      cand <- sprintf("%s%03d", prefix, n)
      if (!(cand %in% taken)) return(cand)
      n <- n + 1L
    }
  }

  node_elem <- character(0)   # node id -> element id

  for (grp in names(group_to_key)) {
    key    <- group_to_key[[grp]]
    prefix <- group_to_prefix[[grp]]
    subset <- nodes[nodes$group == grp, , drop = FALSE]
    prev   <- isa[[key]]
    id_col   <- col_of(prev, c("ID", "id"))
    name_col <- col_of(prev, c("Name", "name"))
    prev_ids   <- if (!is.null(id_col))   as.character(prev[[id_col]])   else character(0)
    prev_names <- if (!is.null(name_col)) as.character(prev[[name_col]]) else character(0)

    # Canonical output columns: the previous frame's (so Type/Description/... and
    # their case survive), else ID / Name / Indicator.
    if (is.data.frame(prev) && !is.null(id_col)) {
      out_cols <- names(prev)
      out_id <- id_col; out_name <- name_col %||% "Name"
      if (!(out_name %in% out_cols)) out_cols <- c(out_cols, out_name)
    } else {
      out_cols <- c("ID", "Name", "Indicator"); out_id <- "ID"; out_name <- "Name"
      prev <- NULL
    }

    if (nrow(subset) == 0) {
      empty <- lapply(out_cols, function(cn) {
        if (is.data.frame(prev) && cn %in% names(prev)) prev[[cn]][0] else character(0)
      })
      names(empty) <- out_cols
      isa[[key]] <- as.data.frame(empty, stringsAsFactors = FALSE)
      next
    }

    # Element name: the carried raw name wins only while its wrapped form still
    # equals the node label; a label edited in the CLD (rename) takes over.
    labels <- as.character(subset$label)
    carried_names <- if ("name_raw" %in% names(subset)) as.character(subset$name_raw) else rep(NA_character_, nrow(subset))
    raw_names <- vapply(seq_len(nrow(subset)), function(i) {
      nr <- carried_names[i]; lb <- labels[i]
      if (!is.na(nr) && nzchar(nr)) {
        wrapped <- if (exists("wrap_label", mode = "function")) tryCatch(wrap_label(nr), error = function(e) nr) else nr
        if (identical(as.character(wrapped), lb) || identical(nr, lb)) return(nr)
      }
      unwrap(lb)
    }, character(1))
    carried <- if ("element_id" %in% names(subset)) as.character(subset$element_id) else rep(NA_character_, nrow(subset))

    used <- character(0)
    rows <- vector("list", nrow(subset))
    for (i in seq_len(nrow(subset))) {
      nid <- as.character(subset$id[i])
      eid <- NA_character_
      # (a) element id carried on the node
      if (!is.na(carried[i]) && nzchar(carried[i]) && !(carried[i] %in% used)) eid <- carried[i]
      # (b) name match against the previous frame. Comes BEFORE positional so
      #     a legacy CLD (no element_id) stays correct across repeated syncs
      #     after a deletion, when node numbers no longer equal frame rows.
      if (is.na(eid) && length(prev_names)) {
        m <- which(tolower(trimws(prev_names)) == tolower(trimws(raw_names[i])) & !(prev_ids %in% used))
        if (length(m)) eid <- prev_ids[m[1]]
      }
      # (c) positional: create_nodes_df numbers nodes by row within the group
      #     (covers a renamed legacy node)
      if (is.na(eid)) {
        k <- suppressWarnings(as.integer(sub(paste0("^", prefix, "_"), "", nid)))
        if (grepl(paste0("^", prefix, "_[0-9]+$"), nid) && !is.na(k) && k >= 1 && k <= length(prev_ids) &&
            !(prev_ids[k] %in% used)) eid <- prev_ids[k]
      }
      # (d) brand-new element (added in the CLD)
      if (is.na(eid) || !nzchar(eid)) eid <- next_free_id(prefix, c(prev_ids, used))
      used <- c(used, eid)
      node_elem[nid] <- eid

      j <- if (length(prev_ids)) match(eid, prev_ids) else NA_integer_
      row <- lapply(out_cols, function(cn) {
        if (!is.na(j) && is.data.frame(prev) && cn %in% names(prev)) prev[[cn]][j]
        else if (is.data.frame(prev) && cn %in% names(prev)) prev[[cn]][NA_integer_]
        else NA_character_
      })
      names(row) <- out_cols
      row[[out_id]]   <- eid
      row[[out_name]] <- raw_names[i]
      rows[[i]] <- as.data.frame(row, stringsAsFactors = FALSE)
    }
    new_df <- do.call(rbind, rows)
    rownames(new_df) <- NULL
    isa[[key]] <- new_df
  }

  # ---- adjacency matrices, keyed by ELEMENT ids ------------------------------------
  group_ids <- lapply(names(group_to_key), function(grp) {
    nid <- as.character(nodes$id[nodes$group == grp])
    unname(node_elem[nid])
  })
  names(group_ids) <- names(group_to_key)
  id_to_group <- if (nrow(nodes) > 0) setNames(nodes$group, nodes$id) else character(0)

  norm_pol <- function(x) {
    x <- as.character(x)
    if (length(x) == 0 || is.na(x) || !nzchar(x)) return("+")
    x <- trimws(x)
    if (x %in% c("+", "-")) return(x)
    if (exists("debug_log", mode = "function")) {
      debug_log(sprintf("sync_cld_to_isa_data: unknown polarity '%s'; coercing to '+'", x), "CLD SYNC")
    }
    "+"
  }
  pick <- function(df, col, i, default) {
    if (col %in% names(df)) { v <- df[[col]][i]; if (!is.null(v) && !is.na(v) && nzchar(as.character(v))) return(as.character(v)) }
    default
  }
  blank_matrix <- function(src_grp, tgt_grp, fill) {
    r <- group_ids[[src_grp]]; c <- group_ids[[tgt_grp]]
    matrix(fill, nrow = length(r), ncol = length(c), dimnames = list(r, c))
  }

  adj <- list(); ue <- list()
  if (nrow(edges) > 0) {
    for (i in seq_len(nrow(edges))) {
      from_id <- as.character(edges$from[i]); to_id <- as.character(edges$to[i])
      src_grp <- id_to_group[from_id]; tgt_grp <- id_to_group[to_id]
      if (is.na(src_grp) || is.na(tgt_grp)) next
      src_e <- node_elem[from_id]; tgt_e <- node_elem[to_id]
      if (is.na(src_e) || is.na(tgt_e)) next
      mat_name <- paste0(group_to_mat[[src_grp]], "_", group_to_mat[[tgt_grp]])
      if (is.null(adj[[mat_name]])) {
        adj[[mat_name]] <- blank_matrix(src_grp, tgt_grp, "")
        ue[[mat_name]]  <- blank_matrix(src_grp, tgt_grp, FALSE)
      }
      lbl_pol <- if ("label" %in% names(edges)) trimws(as.character(edges$label[i])) else NA_character_
      pol <- if (!is.na(lbl_pol) && lbl_pol %in% c("+", "-")) lbl_pol
             else norm_pol(if ("polarity" %in% names(edges)) edges$polarity[i] else lbl_pol)
      prev_m <- prev_am[[mat_name]]
      prev_cell <- if (is.matrix(prev_m) && src_e %in% rownames(prev_m) && tgt_e %in% colnames(prev_m)) prev_m[src_e, tgt_e] else ""
      if (!is.na(prev_cell) && nzchar(prev_cell)) {
        # keep strength / confidence / delay; update only the polarity character
        cell <- if (substr(prev_cell, 1, 1) %in% c("+", "-")) paste0(pol, substr(prev_cell, 2, nchar(prev_cell))) else paste0(pol, prev_cell)
      } else {
        # New edge: defaults by matrix family (the R arm keys DYNAMICS_WEIGHT_MAP
        # with lowercase strength + integer confidence, see build_response_matrices)
        r_arm <- mat_name %in% c("r_d", "r_a", "r_p", "gb_r")
        cell <- paste0(pol,
                       pick(edges, "strength", i, if (r_arm) "medium" else "Medium"), ":",
                       pick(edges, "confidence", i, if (r_arm) "3" else "Medium"))
      }
      adj[[mat_name]][src_e, tgt_e] <- cell
    }
  }

  # Carry user_edited flags over by dimname (prunes removed elements), then
  # mark every cell the CLD changed (new, altered or cleared edge) as user
  # edited: a CLD edit IS a user edit, and rebuild_matrix_from_linked() only
  # respects cells that disagree with LinkedX when they are flagged.
  for (mat_name in names(adj)) {
    pu <- prev_ue[[mat_name]]
    if (is.matrix(pu) && is.logical(pu)) {
      rr <- intersect(rownames(pu), rownames(ue[[mat_name]])); cc <- intersect(colnames(pu), colnames(ue[[mat_name]]))
      if (length(rr) && length(cc)) ue[[mat_name]][rr, cc] <- pu[rr, cc]
    }
    pm <- prev_am[[mat_name]]
    cur <- adj[[mat_name]]
    for (rn in rownames(cur)) for (cn in colnames(cur)) {
      before <- if (is.matrix(pm) && rn %in% rownames(pm) && cn %in% colnames(pm)) pm[rn, cn] else ""
      if (is.na(before)) before <- ""
      if (!identical(as.character(before), as.character(cur[rn, cn]))) ue[[mat_name]][rn, cn] <- TRUE
    }
  }

  # Always ensure the 6 primary-chain matrices exist (even if 0x0)
  canonical_pairs <- list(
    d_a = c("Drivers", "Activities"),
    a_p = c("Activities", "Pressures"),
    p_mpf = c("Pressures", "Marine Processes & Functioning"),
    mpf_es = c("Marine Processes & Functioning", "Ecosystem Services"),
    es_gb = c("Ecosystem Services", "Goods & Benefits"),
    gb_d = c("Goods & Benefits", "Drivers")
  )
  for (mat_name in names(canonical_pairs)) {
    if (is.null(adj[[mat_name]])) {
      adj[[mat_name]] <- blank_matrix(canonical_pairs[[mat_name]][1], canonical_pairs[[mat_name]][2], "")
      ue[[mat_name]]  <- blank_matrix(canonical_pairs[[mat_name]][1], canonical_pairs[[mat_name]][2], FALSE)
    }
  }

  isa$adjacency_matrices   <- adj
  isa$user_edited_matrices <- ue
  # Write the resolved element ids / raw names back onto the CLD nodes so the
  # next sync (the module re-reads cld$nodes from project_data) maps directly.
  nid_all <- as.character(nodes$id)
  nodes$element_id <- unname(node_elem[nid_all])
  resolved_name <- character(length(nid_all))
  for (grp in names(group_to_key)) {
    key <- group_to_key[[grp]]; df <- isa[[key]]
    idc <- col_of(df, c("ID", "id")); nmc <- col_of(df, c("Name", "name"))
    if (is.null(idc) || is.null(nmc)) next
    sel <- which(nodes$group == grp)
    resolved_name[sel] <- as.character(df[[nmc]])[match(nodes$element_id[sel], as.character(df[[idc]]))]
  }
  nodes$name_raw <- ifelse(is.na(resolved_name) | !nzchar(resolved_name), unwrap(nodes$label), resolved_name)
  project_data$data$cld$nodes <- nodes
  project_data$data$isa_data <- isa
  project_data$last_modified <- Sys.time()
  project_data
}

# ============================================================================
# MERGE NODES (pure logic, UI triggers this)
# ============================================================================

#' Merge a set of nodes into a single primary node
#'
#' All edges pointing to/from a secondary node are rewired to point to/from
#' the primary. Duplicate edges after rewiring (same from+to+polarity) are
#' collapsed to a single edge. Secondary nodes are removed.
#'
#' Validation: all node_ids must share the same group (element type).
#' You cannot merge a Driver with an Activity - use convert instead.
#'
#' @param nodes current rv\$nodes data.frame
#' @param edges current rv\$edges data.frame
#' @param node_ids character vector of 2+ ids to merge
#' @param primary_id character - which id's label/metadata to keep. Must be in node_ids.
#' @return list(nodes = new_nodes, edges = new_edges, removed_ids = character)
#'         on success, or list(error_key = "...", error_detail = ...) on
#'         validation failure. error_key is an i18n-lookup code (one of
#'         "merge_need_two", "merge_primary_not_in_selection",
#'         "merge_unknown_ids", "merge_cross_type"); error_detail carries any
#'         data the UI should sprintf into the translated message.
#' @export
merge_cld_nodes <- function(nodes, edges, node_ids, primary_id) {
  if (length(node_ids) < 2) {
    return(list(error_key = "merge_need_two"))
  }
  if (!primary_id %in% node_ids) {
    return(list(error_key = "merge_primary_not_in_selection"))
  }

  # Validate all rows exist
  missing <- setdiff(node_ids, nodes$id)
  if (length(missing) > 0) {
    return(list(error_key = "merge_unknown_ids", error_detail = missing))
  }

  # Validate same group (element type)
  groups <- unique(nodes$group[nodes$id %in% node_ids])
  if (length(groups) > 1) {
    return(list(error_key = "merge_cross_type", error_detail = groups))
  }

  secondary_ids <- setdiff(node_ids, primary_id)

  # Rewire edges: any reference to a secondary becomes a reference to primary
  new_edges <- edges
  for (sid in secondary_ids) {
    new_edges$from[new_edges$from == sid] <- primary_id
    new_edges$to[new_edges$to == sid] <- primary_id
  }

  # Drop self-loops created by rewiring (A->B where A and B are merged)
  new_edges <- new_edges[new_edges$from != new_edges$to, , drop = FALSE]

  # Deduplicate edges by (from, to, label/polarity).
  # ifelse(is.na(...)) swap is critical: paste(NA, ...) produces "NA" string,
  # which would collide with "|NA" for every NA-labeled edge and wrongly
  # collapse semantically-distinct edges. Use a sentinel that cannot appear
  # in real polarity values.
  if (nrow(new_edges) > 0) {
    pol_col <- if ("label" %in% names(new_edges)) "label" else NULL
    dedupe_key <- if (!is.null(pol_col)) {
      pol_vals <- new_edges[[pol_col]]
      pol_vals <- ifelse(is.na(pol_vals), "__NA_POL__", as.character(pol_vals))
      paste(new_edges$from, new_edges$to, pol_vals, sep = "|")
    } else {
      paste(new_edges$from, new_edges$to, sep = "|")
    }
    new_edges <- new_edges[!duplicated(dedupe_key), , drop = FALSE]
    # Renumber edge ids to keep them sequential after dedupe
    if ("id" %in% names(new_edges)) {
      new_edges$id <- seq_len(nrow(new_edges))
    }
  }

  # Drop secondary nodes
  new_nodes <- nodes[!nodes$id %in% secondary_ids, , drop = FALSE]

  list(
    nodes = new_nodes,
    edges = new_edges,
    removed_ids = secondary_ids,
    primary_id = primary_id
  )
}

# ============================================================================
# EVENT BUS NOTIFICATION FOR CLD EDITS (review 2026-10-07 N22)
# ============================================================================

#' Tell the event bus that the CLD was edited, without forcing a CLD rebuild
#'
#' CLD edits already hold the authoritative diagram, so the reactive pipeline
#' must NOT regenerate the CLD from the synced ISA data (that would re-layout
#' the diagram and bake in the lossy CLD->ISA sync). The skip flag is set first,
#' then isa_change is emitted so autosave and the analysis modules' stale-data
#' notices fire. Pure apart from the bus calls; tolerant of NULL/partial buses.
#'
#' @param event_bus the app event bus (or NULL)
#' @param source short source tag, e.g. "cld_edit_add_node"
#' @return invisible TRUE when an event was emitted, FALSE otherwise
notify_cld_edit <- function(event_bus, source) {
  if (is.null(event_bus) || !is.function(event_bus$emit_isa_change)) return(invisible(FALSE))
  if (is.function(event_bus$skip_next_cld_regen)) event_bus$skip_next_cld_regen(TRUE)
  event_bus$emit_isa_change(source)
  invisible(TRUE)
}

#' Node ids of a detected loop, for CLD highlighting (review 2026-10-07 N32)
#'
#' Prefers loop_info$NodeIDs (stable node ids written by
#' process_cycles_to_loops) and keeps only ids present in the current CLD;
#' falls back to the legacy positional indices into the CLD's node order.
#' @param loop_info data.frame from the Loops tab (may be NULL)
#' @param loop_idx selected loop row
#' @param indices legacy positional node indices of that loop
#' @param current_ids ids of the nodes currently in the CLD
#' @return character vector of node ids
loop_highlight_node_ids <- function(loop_info, loop_idx, indices, current_ids) {
  if (is.data.frame(loop_info) && "NodeIDs" %in% names(loop_info) &&
      loop_idx >= 1 && loop_idx <= nrow(loop_info)) {
    ids <- trimws(strsplit(as.character(loop_info$NodeIDs[loop_idx]), "[,;|]")[[1]])
    ids <- ids[nzchar(ids) & ids %in% current_ids]
    if (length(ids) > 0) return(ids)
  }
  idx <- suppressWarnings(as.integer(indices))
  idx <- idx[!is.na(idx) & idx >= 1 & idx <= length(current_ids)]
  as.character(current_ids[idx])
}
