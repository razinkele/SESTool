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
#' @param edge_count Integer. Current number of edges (for generating new ID).
#' @return Data frame with one row of edge data.
create_new_edge_data <- function(from_id, to_id, edge_count) {
  data.frame(
    id = edge_count + 1,
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

  # DAPSIWRM group name -> isa_data element-list key
  group_to_key <- c(
    "Drivers" = "drivers",
    "Activities" = "activities",
    "Pressures" = "pressures",
    "Marine Processes & Functioning" = "marine_processes",
    "Ecosystem Services" = "ecosystem_services",
    "Goods & Benefits" = "goods_benefits",
    "Responses" = "responses"
  )

  isa <- project_data$data$isa_data %||% list()

  # Rebuild each element-type data frame from CLD nodes of that group.
  # Preserve indicator/description metadata by name-matching against the
  # pre-sync isa_data where possible.
  for (grp in names(group_to_key)) {
    key <- group_to_key[[grp]]
    subset <- nodes[nodes$group == grp, , drop = FALSE]

    if (nrow(subset) == 0) {
      isa[[key]] <- data.frame(
        id = character(0), name = character(0), indicator = character(0),
        stringsAsFactors = FALSE
      )
      next
    }

    # Preserve indicators by matching on name
    indicator <- rep(NA_character_, nrow(subset))
    prev <- isa[[key]]
    if (is.data.frame(prev) && "name" %in% names(prev) && "indicator" %in% names(prev)) {
      for (i in seq_len(nrow(subset))) {
        match_idx <- which(tolower(trimws(prev$name)) == tolower(trimws(subset$label[i])))
        if (length(match_idx) > 0) indicator[i] <- as.character(prev$indicator[match_idx[1]])
      }
    }

    isa[[key]] <- data.frame(
      id = as.character(subset$id),
      name = as.character(subset$label),
      indicator = indicator,
      stringsAsFactors = FALSE
    )
  }

  # Rebuild adjacency matrices from edges
  # Matrix naming: SOURCE x TARGET (per constants.R + DAPSIWRM_FRAMEWORK_RULES.md)
  matrix_pairs <- list(
    d_a = c("Drivers", "Activities"),
    a_p = c("Activities", "Pressures"),
    p_mpf = c("Pressures", "Marine Processes & Functioning"),
    mpf_es = c("Marine Processes & Functioning", "Ecosystem Services"),
    es_gb = c("Ecosystem Services", "Goods & Benefits"),
    gb_d = c("Goods & Benefits", "Drivers")
  )

  adj <- list()
  for (mat_name in names(matrix_pairs)) {
    src_grp <- matrix_pairs[[mat_name]][1]
    tgt_grp <- matrix_pairs[[mat_name]][2]
    src_nodes <- nodes[nodes$group == src_grp, , drop = FALSE]
    tgt_nodes <- nodes[nodes$group == tgt_grp, , drop = FALSE]

    if (nrow(src_nodes) == 0 || nrow(tgt_nodes) == 0) {
      adj[[mat_name]] <- matrix("", nrow = nrow(src_nodes), ncol = nrow(tgt_nodes),
                                dimnames = list(
                                  if (nrow(src_nodes) > 0) src_nodes$id else character(0),
                                  if (nrow(tgt_nodes) > 0) tgt_nodes$id else character(0)
                                ))
      next
    }

    mat <- matrix("", nrow = nrow(src_nodes), ncol = nrow(tgt_nodes),
                  dimnames = list(src_nodes$id, tgt_nodes$id))

    for (i in seq_len(nrow(edges))) {
      from_id <- as.character(edges$from[i])
      to_id <- as.character(edges$to[i])
      if (from_id %in% src_nodes$id && to_id %in% tgt_nodes$id) {
        # Edge label holds polarity ("+" or "-"); default to "+" if missing
        pol <- edges$label[i]
        if (is.null(pol) || is.na(pol) || !nzchar(as.character(pol))) pol <- "+"
        mat[from_id, to_id] <- as.character(pol)
      }
    }
    adj[[mat_name]] <- mat
  }

  isa$adjacency_matrices <- adj
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
#'         on success, or list(error = "message") on validation failure
#' @export
merge_cld_nodes <- function(nodes, edges, node_ids, primary_id) {
  if (length(node_ids) < 2) {
    return(list(error = "Need at least 2 nodes to merge"))
  }
  if (!primary_id %in% node_ids) {
    return(list(error = "primary_id must be one of node_ids"))
  }

  # Validate all rows exist
  missing <- setdiff(node_ids, nodes$id)
  if (length(missing) > 0) {
    return(list(error = paste0("Unknown node id(s): ", paste(missing, collapse = ", "))))
  }

  # Validate same group (element type)
  groups <- unique(nodes$group[nodes$id %in% node_ids])
  if (length(groups) > 1) {
    return(list(error = paste0(
      "Cannot merge different element types: ", paste(groups, collapse = ", ")
    )))
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

  # Deduplicate edges by (from, to, label/polarity)
  if (nrow(new_edges) > 0) {
    pol_col <- if ("label" %in% names(new_edges)) "label" else NULL
    dedupe_key <- if (!is.null(pol_col)) {
      paste(new_edges$from, new_edges$to, new_edges[[pol_col]], sep = "|")
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
