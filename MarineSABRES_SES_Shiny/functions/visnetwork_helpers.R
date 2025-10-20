# functions/visnetwork_helpers.R
# Helper functions for visNetwork-based CLD visualization

# ============================================================================
# NODE CREATION FUNCTIONS
# ============================================================================

#' Create nodes dataframe from ISA data
#' 
#' @param isa_data List containing ISA data elements
#' @return Data frame with node attributes for visNetwork
create_nodes_df <- function(isa_data) {
  
  # Initialize empty nodes dataframe
  nodes <- data.frame(
    id = character(),
    label = character(),
    title = character(),
    group = character(),
    level = integer(),
    shape = character(),
    image = character(),
    color = character(),
    size = numeric(),
    font.size = numeric(),
    indicator = character(),
    stringsAsFactors = FALSE
  )
  
  # Goods & Benefits (Level 0)
  if (!is.null(isa_data$goods_benefits) && nrow(isa_data$goods_benefits) > 0) {
    gb_nodes <- isa_data$goods_benefits %>%
      mutate(
        id = paste0("GB_", row_number()),
        label = if("name" %in% names(.)) name else if("Name" %in% names(.)) Name else ID,
        indicator = if("indicator" %in% names(.)) indicator else if("Indicator" %in% names(.)) Indicator else "No indicator",
        title = create_node_tooltip(label, indicator, "Goods & Benefits"),
        group = "Goods & Benefits",
        level = 0,
        shape = ELEMENT_SHAPES[["Goods & Benefits"]],
        image = NA_character_,
        color = ELEMENT_COLORS[["Goods & Benefits"]],
        size = 30,
        font.size = 14
      ) %>%
      select(id, label, title, group, level, shape, image, color, size, font.size, indicator)

    nodes <- bind_rows(nodes, gb_nodes)
  }
  
  # Ecosystem Services (Level 1)
  if (!is.null(isa_data$ecosystem_services) && nrow(isa_data$ecosystem_services) > 0) {
    es_nodes <- isa_data$ecosystem_services %>%
      mutate(
        id = paste0("ES_", row_number()),
        label = if("name" %in% names(.)) name else if("Name" %in% names(.)) Name else ID,
        indicator = if("indicator" %in% names(.)) indicator else if("Indicator" %in% names(.)) Indicator else "No indicator",
        title = create_node_tooltip(label, indicator, "Ecosystem Services"),
        group = "Ecosystem Services",
        level = 1,
        shape = ELEMENT_SHAPES[["Ecosystem Services"]],
        image = NA_character_,
        color = ELEMENT_COLORS[["Ecosystem Services"]],
        size = 25,
        font.size = 12,
      ) %>%
      select(id, label, title, group, level, shape, image, color, size, font.size, indicator)

    nodes <- bind_rows(nodes, es_nodes)
  }

  # Marine Processes & Functioning (Level 2)
  if (!is.null(isa_data$marine_processes) && nrow(isa_data$marine_processes) > 0) {
    mpf_nodes <- isa_data$marine_processes %>%
      mutate(
        id = paste0("MPF_", row_number()),
        label = if("name" %in% names(.)) name else if("Name" %in% names(.)) Name else ID,
        indicator = if("indicator" %in% names(.)) indicator else if("Indicator" %in% names(.)) Indicator else "No indicator",
        title = create_node_tooltip(label, indicator, "Marine Processes & Functioning"),
        group = "Marine Processes & Functioning",
        level = 2,
        shape = ELEMENT_SHAPES[["Marine Processes & Functioning"]],
        image = NA_character_,
        color = ELEMENT_COLORS[["Marine Processes & Functioning"]],
        size = 25,
        font.size = 12,
      ) %>%
      select(id, label, title, group, level, shape, image, color, size, font.size, indicator)

    nodes <- bind_rows(nodes, mpf_nodes)
  }

  # Pressures (Level 3)
  if (!is.null(isa_data$pressures) && nrow(isa_data$pressures) > 0) {
    pressure_nodes <- isa_data$pressures %>%
      mutate(
        id = paste0("P_", row_number()),
        label = if("name" %in% names(.)) name else if("Name" %in% names(.)) Name else ID,
        indicator = if("indicator" %in% names(.)) indicator else if("Indicator" %in% names(.)) Indicator else "No indicator",
        title = create_node_tooltip(
          label, indicator, "Pressures",
          extra = if("type" %in% names(.)) paste("Type:", type) else if("Type" %in% names(.)) paste("Type:", Type) else NULL
        ),
        group = "Pressures",
        level = 3,
        shape = ELEMENT_SHAPES[["Pressures"]],
        image = NA_character_,
        color = ELEMENT_COLORS[["Pressures"]],
        size = 25,
        font.size = 12,
      ) %>%
      select(id, label, title, group, level, shape, image, color, size, font.size, indicator)

    nodes <- bind_rows(nodes, pressure_nodes)
  }

  # Activities (Level 4)
  if (!is.null(isa_data$activities) && nrow(isa_data$activities) > 0) {
    activity_nodes <- isa_data$activities %>%
      mutate(
        id = paste0("A_", row_number()),
        label = if("name" %in% names(.)) name else if("Name" %in% names(.)) Name else ID,
        indicator = if("indicator" %in% names(.)) indicator else if("Indicator" %in% names(.)) Indicator else "No indicator",
        title = create_node_tooltip(
          label, indicator, "Activities",
          extra = if("scale" %in% names(.)) paste("Scale:", scale) else if("Scale" %in% names(.)) paste("Scale:", Scale) else NULL
        ),
        group = "Activities",
        level = 4,
        shape = ELEMENT_SHAPES[["Activities"]],
        image = NA_character_,
        color = ELEMENT_COLORS[["Activities"]],
        size = 25,
        font.size = 12,
      ) %>%
      select(id, label, title, group, level, shape, image, color, size, font.size, indicator)

    nodes <- bind_rows(nodes, activity_nodes)
  }

  # Drivers (Level 5) - Using custom octagon SVG
  if (!is.null(isa_data$drivers) && nrow(isa_data$drivers) > 0) {
    driver_nodes <- isa_data$drivers %>%
      mutate(
        id = paste0("D_", row_number()),
        label = if("name" %in% names(.)) name else if("Name" %in% names(.)) Name else ID,
        indicator = if("indicator" %in% names(.)) indicator else if("Indicator" %in% names(.)) Indicator else "No indicator",
        title = create_node_tooltip(label, indicator, "Drivers"),
        group = "Drivers",
        level = 5,
        shape = "image",  # Use image shape for custom octagon
        image = "shapes/octagon.svg",  # Path to octagon SVG
        color = NA_character_,  # Color handled by SVG
        size = 30,
        font.size = 14,
      ) %>%
      select(id, label, title, group, level, shape, image, color, size, font.size, indicator)

    nodes <- bind_rows(nodes, driver_nodes)
  }
  
  return(nodes)
}

#' Create HTML tooltip for node
#' 
#' @param name Node name
#' @param indicator Indicator description
#' @param group Element type
#' @param extra Additional information
#' @return HTML string for tooltip
create_node_tooltip <- function(name, indicator, group, extra = NULL) {
  html <- sprintf(
    "<div style='padding: 8px;'>
      <b>%s</b><br>
      <i>%s</i><br>
      <hr style='margin: 5px 0;'>
      Indicator: %s",
    name, group, indicator
  )
  
  if (!is.null(extra)) {
    html <- paste0(html, "<br>", extra)
  }
  
  html <- paste0(html, "</div>")
  return(html)
}

# ============================================================================
# EDGE CREATION FUNCTIONS
# ============================================================================

#' Create edges dataframe from adjacency matrices
#' 
#' @param isa_data List containing ISA data
#' @param adjacency_matrices List of adjacency matrices
#' @return Data frame with edge attributes for visNetwork
create_edges_df <- function(isa_data, adjacency_matrices) {
  
  edges <- data.frame(
    from = character(),
    to = character(),
    arrows = character(),
    color = character(),
    width = numeric(),
    title = character(),
    polarity = character(),
    strength = character(),
    label = character(),
    font.size = numeric(),
    stringsAsFactors = FALSE
  )
  
  # Process each adjacency matrix
  if (!is.null(adjacency_matrices$gb_es)) {
    edges_gb_es <- process_adjacency_matrix(
      adjacency_matrices$gb_es,
      from_prefix = "ES",
      to_prefix = "GB"
    )
    edges <- bind_rows(edges, edges_gb_es)
  }
  
  if (!is.null(adjacency_matrices$es_mpf)) {
    edges_es_mpf <- process_adjacency_matrix(
      adjacency_matrices$es_mpf,
      from_prefix = "MPF",
      to_prefix = "ES"
    )
    edges <- bind_rows(edges, edges_es_mpf)
  }
  
  if (!is.null(adjacency_matrices$mpf_p)) {
    edges_mpf_p <- process_adjacency_matrix(
      adjacency_matrices$mpf_p,
      from_prefix = "P",
      to_prefix = "MPF"
    )
    edges <- bind_rows(edges, edges_mpf_p)
  }
  
  if (!is.null(adjacency_matrices$p_a)) {
    edges_p_a <- process_adjacency_matrix(
      adjacency_matrices$p_a,
      from_prefix = "A",
      to_prefix = "P"
    )
    edges <- bind_rows(edges, edges_p_a)
  }
  
  if (!is.null(adjacency_matrices$a_d)) {
    edges_a_d <- process_adjacency_matrix(
      adjacency_matrices$a_d,
      from_prefix = "D",
      to_prefix = "A"
    )
    edges <- bind_rows(edges, edges_a_d)
  }
  
  if (!is.null(adjacency_matrices$d_gb)) {
    edges_d_gb <- process_adjacency_matrix(
      adjacency_matrices$d_gb,
      from_prefix = "GB",
      to_prefix = "D"
    )
    edges <- bind_rows(edges, edges_d_gb)
  }
  
  return(edges)
}

#' Process adjacency matrix into edges dataframe
#' 
#' @param adj_matrix Matrix with connection values
#' @param from_prefix Prefix for source nodes
#' @param to_prefix Prefix for target nodes
#' @return Data frame with edge attributes
process_adjacency_matrix <- function(adj_matrix, from_prefix, to_prefix) {
  
  edges <- data.frame()
  
  if (is.null(adj_matrix) || !is.matrix(adj_matrix)) {
    return(edges)
  }
  
  for (i in 1:nrow(adj_matrix)) {
    for (j in 1:ncol(adj_matrix)) {
      value <- adj_matrix[i, j]
      
      if (!is.na(value) && value != "") {
        # Parse value: e.g., "+strong", "-medium"
        connection <- parse_connection_value(value)
        
        if (!is.null(connection)) {
          # Determine edge properties
          width_map <- c("strong" = 4, "medium" = 2.5, "weak" = 1.5)
          edge_width <- width_map[connection$strength]
          
          # Color based on polarity
          edge_color <- ifelse(
            connection$polarity == "+",
            EDGE_COLORS$reinforcing,
            EDGE_COLORS$opposing
          )
          
          # Create edge
          edge <- data.frame(
            from = paste0(from_prefix, "_", i),
            to = paste0(to_prefix, "_", j),
            arrows = "to",
            color = edge_color,
            width = edge_width,
            title = create_edge_tooltip(
              rownames(adj_matrix)[i],
              colnames(adj_matrix)[j],
              connection$polarity,
              connection$strength
            ),
            polarity = connection$polarity,
            strength = connection$strength,
            label = connection$polarity,
            font.size = 10,
            stringsAsFactors = FALSE
          )
          
          edges <- bind_rows(edges, edge)
        }
      }
    }
  }
  
  return(edges)
}

#' Create HTML tooltip for edge
#' 
#' @param from_name Source node name
#' @param to_name Target node name
#' @param polarity Connection polarity
#' @param strength Connection strength
#' @return HTML string for tooltip
create_edge_tooltip <- function(from_name, to_name, polarity, strength) {
  polarity_text <- ifelse(polarity == "+", "Reinforcing", "Opposing")
  
  sprintf(
    "<div style='padding: 8px;'>
      <b>%s → %s</b><br>
      Polarity: %s (%s)<br>
      Strength: %s
    </div>",
    from_name, to_name, polarity, polarity_text, strength
  )
}

# ============================================================================
# NETWORK STYLING FUNCTIONS
# ============================================================================

#' Apply standard visNetwork styling
#' 
#' @param visnet visNetwork object
#' @return Styled visNetwork object
apply_standard_styling <- function(visnet) {
  
  visnet %>%
    # Groups for legend
    visGroups(
      groupname = "Drivers",
      shape = "image",
      image = "shapes/octagon.svg"
    ) %>%
    visGroups(
      groupname = "Activities",
      color = list(background = ELEMENT_COLORS[["Activities"]], 
                  border = darken_color(ELEMENT_COLORS[["Activities"]])),
      shape = ELEMENT_SHAPES[["Activities"]]
    ) %>%
    visGroups(
      groupname = "Pressures",
      color = list(background = ELEMENT_COLORS[["Pressures"]], 
                  border = darken_color(ELEMENT_COLORS[["Pressures"]])),
      shape = ELEMENT_SHAPES[["Pressures"]]
    ) %>%
    visGroups(
      groupname = "Marine Processes & Functioning",
      color = list(background = ELEMENT_COLORS[["Marine Processes & Functioning"]], 
                  border = darken_color(ELEMENT_COLORS[["Marine Processes & Functioning"]])),
      shape = ELEMENT_SHAPES[["Marine Processes & Functioning"]]
    ) %>%
    visGroups(
      groupname = "Ecosystem Services",
      color = list(background = ELEMENT_COLORS[["Ecosystem Services"]], 
                  border = darken_color(ELEMENT_COLORS[["Ecosystem Services"]])),
      shape = ELEMENT_SHAPES[["Ecosystem Services"]]
    ) %>%
    visGroups(
      groupname = "Goods & Benefits",
      color = list(background = ELEMENT_COLORS[["Goods & Benefits"]], 
                  border = darken_color(ELEMENT_COLORS[["Goods & Benefits"]])),
      shape = ELEMENT_SHAPES[["Goods & Benefits"]]
    ) %>%
    # Legend
    visLegend(
      width = 0.15,
      position = "right",
      main = "DAPSI(W)R(M)"
    ) %>%
    # Interaction options
    visInteraction(
      navigationButtons = TRUE,
      keyboard = TRUE,
      hover = TRUE,
      tooltipDelay = 100,
      zoomView = TRUE,
      dragView = TRUE,
      dragNodes = TRUE,
      multiselect = TRUE
    ) %>%
    # Edge configuration
    visEdges(
      smooth = list(enabled = TRUE, type = "curvedCW", roundness = 0.2),
      shadow = FALSE,
      arrows = list(to = list(enabled = TRUE, scaleFactor = 0.5)),
      font = list(size = 10, align = "middle")
    ) %>%
    # Node configuration - labels outside shapes
    visNodes(
      shadow = list(enabled = TRUE, size = 5),
      font = list(size = 12, face = "arial", vadjust = -20),
      borderWidth = 2
    ) %>%
    # Options
    visOptions(
      highlightNearest = list(enabled = TRUE, degree = 1, hover = TRUE),
      selectedBy = "group"
    )
}

#' Darken a color for borders
#' 
#' @param color Hex color code
#' @param factor Darkening factor (0-1)
#' @return Darkened hex color
darken_color <- function(color, factor = 0.2) {
  # Simple darkening by reducing RGB values
  rgb_vals <- col2rgb(color) / 255
  darkened <- rgb_vals * (1 - factor)
  rgb(darkened[1], darkened[2], darkened[3])
}

# ============================================================================
# LAYOUT FUNCTIONS
# ============================================================================

#' Apply hierarchical layout
#' 
#' @param visnet visNetwork object
#' @param direction Layout direction
#' @param level_separation Space between levels
#' @return visNetwork with hierarchical layout
apply_hierarchical_layout <- function(visnet, direction = "DU", 
                                     level_separation = 150) {
  visnet %>%
    visHierarchicalLayout(
      direction = direction,
      levelSeparation = level_separation,
      nodeSpacing = 200,
      treeSpacing = 200,
      blockShifting = TRUE,
      edgeMinimization = TRUE,
      parentCentralization = TRUE,
      sortMethod = "directed"
    )
}

#' Apply physics-based layout
#' 
#' @param visnet visNetwork object
#' @return visNetwork with physics layout
apply_physics_layout <- function(visnet) {
  visnet %>%
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

#' Apply circular layout
#' 
#' @param visnet visNetwork object
#' @return visNetwork with circular layout
apply_circular_layout <- function(visnet) {
  visnet %>%
    visLayout(randomSeed = 123) %>%
    visIgraphLayout(layout = "layout_in_circle")
}

# ============================================================================
# FILTERING FUNCTIONS
# ============================================================================

#' Filter nodes and edges by element types
#' 
#' @param nodes Nodes dataframe
#' @param edges Edges dataframe
#' @param element_types Vector of element types to keep
#' @return List with filtered nodes and edges
filter_by_element_type <- function(nodes, edges, element_types) {
  
  nodes_filtered <- nodes %>%
    filter(group %in% element_types)
  
  edges_filtered <- edges %>%
    filter(from %in% nodes_filtered$id, to %in% nodes_filtered$id)
  
  list(nodes = nodes_filtered, edges = edges_filtered)
}

#' Filter edges by polarity
#' 
#' @param edges Edges dataframe
#' @param polarity Vector of polarities to keep
#' @return Filtered edges dataframe
filter_by_polarity <- function(edges, polarity) {
  edges %>% filter(polarity %in% polarity)
}

#' Filter edges by strength
#' 
#' @param edges Edges dataframe
#' @param strength Vector of strengths to keep
#' @return Filtered edges dataframe
filter_by_strength <- function(edges, strength) {
  edges %>% filter(strength %in% strength)
}

# ============================================================================
# NODE SIZING FUNCTIONS
# ============================================================================

#' Apply metric-based node sizing
#' 
#' @param nodes Nodes dataframe
#' @param metric_values Named vector of metric values
#' @param min_size Minimum node size
#' @param max_size Maximum node size
#' @return Nodes dataframe with updated sizes
apply_metric_sizing <- function(nodes, metric_values, 
                               min_size = 15, max_size = 50) {
  
  # Match metric values to nodes
  nodes$metric_value <- metric_values[nodes$id]
  
  # Normalize to size range
  min_val <- min(metric_values, na.rm = TRUE)
  max_val <- max(metric_values, na.rm = TRUE)
  
  if (max_val > min_val) {
    nodes$size <- min_size + (max_size - min_size) * 
      (nodes$metric_value - min_val) / (max_val - min_val)
  }
  
  # Remove temporary column
  nodes$metric_value <- NULL
  
  return(nodes)
}

# ============================================================================
# EXPORT FUNCTIONS
# ============================================================================

#' Export visNetwork as standalone HTML
#' 
#' @param visnet visNetwork object
#' @param file Output file path
#' @return NULL (side effect: saves file)
export_visnetwork_html <- function(visnet, file) {
  htmlwidgets::saveWidget(
    visnet %>% visInteraction(navigationButtons = TRUE),
    file,
    selfcontained = TRUE
  )
}

#' Export visNetwork as PNG
#' 
#' @param visnet visNetwork object
#' @param file Output file path
#' @param width Image width in pixels
#' @param height Image height in pixels
#' @return NULL (side effect: saves file)
export_visnetwork_png <- function(visnet, file, width = 1200, height = 900) {
  require(webshot)
  
  # Save as HTML first
  temp_html <- tempfile(fileext = ".html")
  export_visnetwork_html(visnet, temp_html)
  
  # Convert to PNG
  webshot::webshot(temp_html, file, vwidth = width, vheight = height)
  
  # Clean up
  unlink(temp_html)
}

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

#' Check if node ID exists
#' 
#' @param nodes Nodes dataframe
#' @param node_id Node ID to check
#' @return Logical
node_exists <- function(nodes, node_id) {
  node_id %in% nodes$id
}

#' Get node by ID
#' 
#' @param nodes Nodes dataframe
#' @param node_id Node ID
#' @return Single row dataframe or NULL
get_node <- function(nodes, node_id) {
  node <- nodes %>% filter(id == node_id)
  if (nrow(node) == 0) return(NULL)
  return(node)
}

#' Get edges connected to node
#' 
#' @param edges Edges dataframe
#' @param node_id Node ID
#' @param direction "in", "out", or "both"
#' @return Dataframe of connected edges
get_connected_edges <- function(edges, node_id, direction = "both") {
  if (direction == "in") {
    return(edges %>% filter(to == node_id))
  } else if (direction == "out") {
    return(edges %>% filter(from == node_id))
  } else {
    return(edges %>% filter(from == node_id | to == node_id))
  }
}
