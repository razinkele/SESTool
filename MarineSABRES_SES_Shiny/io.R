# Marine SES Network Input/Output Functions
# This file contains functions for creating and loading network data
# including Marine SES networks with feedback loops and Excel file reading

# Required libraries (to be loaded by the main application)
# library(igraph)
# library(readxl) - for Excel file reading
# library(openxlsx) - for Excel file writing (optional)

# Load constants (should be sourced by main app.R first)
# This is a fallback for standalone testing
if (!exists("MARINE_SES_CATEGORIES")) {
  if (file.exists("constants.R")) {
    source("constants.R")
  } else {
    stop("constants.R not found. Please ensure it is in the working directory.")
  }
}

# ============================================================================
# NETWORK CREATION FUNCTIONS
# ============================================================================

#' Create Simple 3-Node Feedback Loop
#'
#' Creates a minimal directed graph with 3 nodes forming a simple feedback loop
#' (Driver -> Pressure -> Response -> Driver).
#'
#' @return An igraph object with 3 nodes and 3 directed edges, including
#'   node attributes (name, group, label) and edge attributes (weight, strength, confidence)
#'
#' @examples
#' \dontrun{
#' g <- create_simple_loop()
#' plot(g)
#' }
#'
#' @export
create_simple_loop <- function() {
  # Create a directed graph with 3 nodes in a simple loop
  g <- make_empty_graph(n = 3, directed = TRUE)
  
  # Add edges to form a simple loop: 1 -> 2 -> 3 -> 1
  g <- add_edges(g, c(1, 2, 2, 3, 3, 1))
  
  # Add node attributes
  V(g)$name <- c("Driver", "Pressure", "Response")
  V(g)$group <- c("Drivers", "Pressures", "Activities")
  V(g)$label <- V(g)$name
  
  # Add edge attributes
  E(g)$weight <- c(5.0, 7.0, 6.0)  # Moderate to strong connections
  E(g)$strength <- c(3.0, 4.0, -2.0)  # Mix of positive and negative
  E(g)$confidence <- c(4, 5, 3)  # High confidence levels
  
  message("Created simple 3-node feedback loop: Driver -> Pressure -> Response -> Driver")
  return(g)
}

#' Create Marine SES Network with Feedback Loops
#'
#' Generates a realistic marine social-ecological system (SES) network with
#' scientifically-grounded connections and deliberate feedback loops representing
#' real marine system dynamics.
#'
#' @param n_nodes Total number of nodes in the network (default: 18, minimum: 12)
#' @param include_simple_loop Deprecated parameter, kept for backward compatibility
#'
#' @return An igraph object with directed edges, node groups (Activities, Pressures,
#'   Drivers, Societal Goods and Services, Ecosystem Services, Marine Processes),
#'   and edge attributes including:
#'   \item{weight}{Connection weight (3-8)}
#'   \item{strength}{Causal strength (-5 to 5, negative = inhibitory)}
#'   \item{confidence}{Evidence confidence level (1-5, 5 = high)}
#'
#' @details
#' The network balances nodes across 6 marine SES categories and includes:
#' - High-confidence connections (score 4-5) for well-established relationships
#' - Medium-confidence connections (score 3-4) for supported relationships
#' - Lower-confidence connections (score 1-3) for speculative relationships
#' - Feedback loops connecting societal outcomes back to drivers and activities
#'
#' @examples
#' \dontrun{
#' g <- create_marine_ses_with_loops(n_nodes = 18)
#' analyze_loops(g)
#' }
#'
#' @export
create_marine_ses_with_loops <- function(n_nodes = 18, include_simple_loop = TRUE) {
  # Input validation
  if (!is.numeric(n_nodes) || n_nodes < 6) {
    stop("n_nodes must be a number >= 6 (minimum 1 per category)")
  }
  if (n_nodes > 100) {
    warning("Large networks (>100 nodes) may have performance issues")
  }

  # Define realistic marine SES components with proper names
  realistic_components <- list(
    "Activities" = c("Commercial_Fishing", "Aquaculture", "Tourism", "Shipping", "Marine_Protected_Areas", "Coastal_Development"),
    "Pressures" = c("Overfishing", "Pollution", "Habitat_Destruction", "Ocean_Warming", "Ocean_Acidification", "Plastic_Waste"),
    "Drivers" = c("Climate_Change", "Economic_Growth", "Population_Growth", "Policy_Framework", "Global_Trade", "Technology_Development"),
    "Societal Goods and Services" = c("Food_Security", "Economic_Benefits", "Livelihoods", "Cultural_Values", "Recreation_Benefits", "Coastal_Protection"),
    "Ecosystem Services" = c("Fish_Provisioning", "Climate_Regulation", "Carbon_Storage", "Water_Purification", "Nutrient_Cycling", "Biodiversity_Maintenance"),
    "Marine Processes" = c("Primary_Production", "Ocean_Currents", "Seasonal_Upwelling", "Marine_Biodiversity", "Coral_Reef_Health", "Tidal_Systems")
  )
  
  # Create a balanced selection of nodes from each category
  selected_nodes <- c()
  selected_groups <- c()
  
  # Calculate nodes per category (ensure at least DEFAULT_NODES_PER_CATEGORY nodes per category for loops)
  nodes_per_category <- max(DEFAULT_NODES_PER_CATEGORY, floor(n_nodes / length(MARINE_SES_CATEGORIES)))
  remaining_nodes <- n_nodes - (nodes_per_category * length(MARINE_SES_CATEGORIES))

  set.seed(MARINE_SES_SEED)  # For reproducibility
  for (category in names(realistic_components)) {
    available_components <- realistic_components[[category]]
    
    # Select nodes for this category
    n_select <- nodes_per_category
    if (remaining_nodes > 0) {
      n_select <- n_select + 1
      remaining_nodes <- remaining_nodes - 1
    }
    
    n_select <- min(n_select, length(available_components))
    selected_components <- sample(available_components, n_select, replace = FALSE)
    
    selected_nodes <- c(selected_nodes, selected_components)
    selected_groups <- c(selected_groups, rep(category, length(selected_components)))
  }
  
  # Truncate to exact number if needed
  if (length(selected_nodes) > n_nodes) {
    selected_nodes <- selected_nodes[1:n_nodes]
    selected_groups <- selected_groups[1:n_nodes]
  }
  
  # Create graph
  g <- make_empty_graph(n = length(selected_nodes), directed = TRUE)
  V(g)$name <- selected_nodes
  V(g)$group <- selected_groups
  V(g)$label <- selected_nodes
  
  # Define realistic connections with confidence levels based on scientific knowledge
  realistic_connections <- list(
    # High confidence connections (4-5)
    list("Climate_Change", "Ocean_Warming", 6.0, 4.0, 5),
    list("Climate_Change", "Ocean_Acidification", 7.0, 4.5, 5),
    list("Ocean_Warming", "Marine_Biodiversity", 5.5, -3.5, 5),
    list("Overfishing", "Fish_Provisioning", 8.0, -4.0, 5),
    list("Commercial_Fishing", "Fish_Provisioning", 7.5, 3.5, 5),
    list("Fish_Provisioning", "Food_Security", 8.5, 4.5, 5),
    list("Economic_Growth", "Commercial_Fishing", 6.5, 3.0, 4),
    list("Population_Growth", "Coastal_Development", 7.0, 3.5, 4),
    list("Tourism", "Economic_Benefits", 7.5, 4.0, 4),
    
    # Medium confidence connections (3-4)
    list("Policy_Framework", "Marine_Protected_Areas", 6.0, 3.0, 4),
    list("Marine_Protected_Areas", "Marine_Biodiversity", 5.5, 2.5, 3),
    list("Coastal_Development", "Habitat_Destruction", 6.5, 3.0, 4),
    list("Habitat_Destruction", "Marine_Biodiversity", 5.0, -3.0, 4),
    list("Primary_Production", "Fish_Provisioning", 6.0, 3.5, 3),
    list("Ocean_Currents", "Primary_Production", 5.0, 2.5, 3),
    list("Seasonal_Upwelling", "Primary_Production", 7.0, 4.0, 4),
    list("Pollution", "Ocean_Acidification", 4.5, 2.0, 3),
    list("Shipping", "Pollution", 5.5, 2.5, 4),
    
    # Lower confidence connections (2-3) - more speculative or indirect
    list("Global_Trade", "Shipping", 5.0, 3.0, 3),
    list("Technology_Development", "Aquaculture", 4.5, 2.0, 2),
    list("Cultural_Values", "Tourism", 4.0, 2.5, 2),
    list("Recreation_Benefits", "Tourism", 6.0, 3.5, 3),
    list("Carbon_Storage", "Climate_Regulation", 5.5, 3.0, 3),
    list("Water_Purification", "Marine_Biodiversity", 4.0, 2.0, 2),
    list("Coral_Reef_Health", "Tourism", 5.0, 2.5, 3),
    list("Tidal_Systems", "Coastal_Protection", 4.5, 2.5, 3),
    
    # Feedback loop connections
    list("Food_Security", "Policy_Framework", 5.5, 3.0, 3),
    list("Economic_Benefits", "Economic_Growth", 7.0, 3.5, 4),
    list("Livelihoods", "Commercial_Fishing", 6.0, 3.0, 3),
    list("Marine_Biodiversity", "Climate_Regulation", 5.0, 2.5, 3)
  )
  
  # Add edges that exist in the network
  edges_added <- 0
  for (connection in realistic_connections) {
    from_name <- connection[[1]]
    to_name <- connection[[2]]
    weight <- connection[[3]]
    strength <- connection[[4]]
    confidence <- connection[[5]]
    
    # Find indices in the current network
    from_idx <- which(V(g)$name == from_name)
    to_idx <- which(V(g)$name == to_name)
    
    if (length(from_idx) > 0 && length(to_idx) > 0) {
      # Check if edge doesn't already exist
      if (!are_adjacent(g, from_idx, to_idx)) {
        g <- add_edges(g, c(from_idx, to_idx))
        edges_added <- edges_added + 1
        
        # Set edge attributes for the new edge
        E(g)$weight[edges_added] <- weight
        E(g)$strength[edges_added] <- strength
        E(g)$confidence[edges_added] <- confidence
      }
    }
  }
  
  # Add some additional random connections to increase network density if needed
  current_density <- edge_density(g)

  if (current_density < TARGET_NETWORK_DENSITY) {
    additional_edges_needed <- round((TARGET_NETWORK_DENSITY * vcount(g) * (vcount(g) - 1)) - ecount(g))
    additional_edges_needed <- max(0, additional_edges_needed)

    set.seed(DEFAULT_RANDOM_SEED)
    attempts <- 0
    max_attempts <- additional_edges_needed * 3
    target_edges <- ecount(g) + additional_edges_needed
    
    while (ecount(g) < target_edges && attempts < max_attempts) {
      from_node <- sample(1:vcount(g), 1)
      to_node <- sample(1:vcount(g), 1)
      
      # Avoid self-loops and duplicate edges
      if (from_node != to_node && !are_adjacent(g, from_node, to_node)) {
        g <- add_edges(g, c(from_node, to_node))
        # Assign realistic but lower confidence attributes for random edges
        current_edge_index <- ecount(g)
        E(g)$weight[current_edge_index] <- runif(1, MARINE_WEIGHT_MIN, MARINE_WEIGHT_MAX - 1)
        E(g)$strength[current_edge_index] <- runif(1, MARINE_STRENGTH_MIN, MARINE_STRENGTH_MAX - 1)
        E(g)$confidence[current_edge_index] <- sample(EDGE_CONFIDENCE_MIN:3, 1, prob = c(0.5, 0.3, 0.2))  # Lower confidence for random edges
      }
      attempts <- attempts + 1
    }
  }
  
  # Ensure all edges have attributes using utility function
  g <- ensure_edge_attributes(g, use_marine_ranges = TRUE)
  
  message(paste("Created realistic Marine SES network with", vcount(g), "nodes and", ecount(g), "edges"))
  message(paste("Network density:", round(edge_density(g), 3)))
  message("Confidence distribution:", paste(table(E(g)$confidence), collapse = ", "))
  
  return(g)
}

# Function to create a comprehensive Marine SES network based on real systems
create_comprehensive_marine_ses <- function() {
  # Create nodes representing a comprehensive marine SES
  node_data <- data.frame(
    id = 1:24,
    name = c(
      # Drivers (1-4)
      "Climate_Change", "Economic_Growth", "Population_Growth", "Policy_Framework",
      
      # Pressures (5-8)  
      "Overfishing", "Pollution", "Coastal_Development", "Ocean_Acidification",
      
      # Marine Processes (9-12)
      "Ocean_Warming", "Sea_Level_Rise", "Biodiversity_Loss", "Habitat_Destruction", 
      
      # Activities (13-16)
      "Commercial_Fishing", "Tourism", "Shipping", "Aquaculture",
      
      # Ecosystem Services (17-20)
      "Fish_Provisioning", "Climate_Regulation", "Tourism_Recreation", "Carbon_Storage",
      
      # Societal Goods and Services (21-24)
      "Food_Security", "Economic_Benefits", "Cultural_Values", "Coastal_Protection"
    ),
    group = c(
      rep("Drivers", 4),
      rep("Pressures", 4), 
      rep("Marine Processes", 4),
      rep("Activities", 4),
      rep("Ecosystem Services", 4),
      rep("Societal Goods and Services", 4)
    ),
    stringsAsFactors = FALSE
  )
  
  # Create the graph
  g <- make_empty_graph(n = nrow(node_data), directed = TRUE)
  
  # Add node attributes
  V(g)$name <- node_data$name
  V(g)$group <- node_data$group
  V(g)$label <- node_data$name
  
  # Define strategic connections to create meaningful loops
  connections <- list(
    # Major feedback loops
    
    # Climate-Ocean Feedback Loop
    c("Climate_Change", "Ocean_Warming"),
    c("Ocean_Warming", "Ocean_Acidification"),
    c("Ocean_Acidification", "Biodiversity_Loss"),
    c("Biodiversity_Loss", "Climate_Regulation"),
    c("Climate_Regulation", "Climate_Change"),
    
    # Economic-Fishing Loop
    c("Economic_Growth", "Commercial_Fishing"),
    c("Commercial_Fishing", "Overfishing"),
    c("Overfishing", "Fish_Provisioning"),
    c("Fish_Provisioning", "Economic_Benefits"),
    c("Economic_Benefits", "Economic_Growth"),
    
    # Tourism-Development Loop  
    c("Tourism", "Economic_Benefits"),
    c("Economic_Benefits", "Coastal_Development"),
    c("Coastal_Development", "Habitat_Destruction"),
    c("Habitat_Destruction", "Tourism_Recreation"),
    c("Tourism_Recreation", "Tourism"),
    
    # Policy-Management Loop
    c("Policy_Framework", "Commercial_Fishing"),
    c("Commercial_Fishing", "Fish_Provisioning"), 
    c("Fish_Provisioning", "Food_Security"),
    c("Food_Security", "Policy_Framework"),
    
    # Additional realistic connections
    c("Population_Growth", "Coastal_Development"),
    c("Pollution", "Ocean_Acidification"),
    c("Sea_Level_Rise", "Coastal_Protection"),
    c("Shipping", "Pollution"),
    c("Aquaculture", "Fish_Provisioning"),
    c("Carbon_Storage", "Climate_Regulation"),
    c("Cultural_Values", "Tourism_Recreation")
  )
  
  # Add edges
  for (connection in connections) {
    from_idx <- which(V(g)$name == connection[1])
    to_idx <- which(V(g)$name == connection[2])
    
    if (length(from_idx) > 0 && length(to_idx) > 0) {
      g <- add_edges(g, c(from_idx, to_idx))
    }
  }
  
  # Add edge attributes (comprehensive network has higher confidence)
  E(g)$weight <- runif(ecount(g), MARINE_WEIGHT_MIN, MARINE_WEIGHT_MAX + 1)  # Slightly higher range
  E(g)$strength <- runif(ecount(g), MARINE_STRENGTH_MIN - 1, MARINE_STRENGTH_MAX + 1)  # Wider range
  E(g)$confidence <- sample(3:EDGE_CONFIDENCE_MAX, ecount(g), replace = TRUE)  # High confidence only
  
  # Optimize for loop analysis - remove some edges to reduce complexity
  if (ecount(g) > MAX_EDGES_BEFORE_OPTIMIZATION) {
    message("Optimizing network for loop analysis by reducing edge density")
    # Keep only the strongest edges
    edge_weights <- E(g)$weight
    cutoff <- quantile(edge_weights, EDGE_RETENTION_QUANTILE)  # Keep top edges
    edges_to_keep <- which(edge_weights >= cutoff)
    g <- subgraph.edges(g, edges_to_keep, delete.vertices = FALSE)
  }
  
  message(paste("Created comprehensive Marine SES network with", vcount(g), "nodes and", ecount(g), "edges"))
  message("Network includes 4 major feedback loops representing real marine system dynamics")
  
  return(g)
}

# ============================================================================
# EXCEL FILE I/O FUNCTIONS
# ============================================================================

# Function to read network from Excel file
read_network_from_excel <- function(file_path,
                                   sheet_name = NULL,
                                   node_sheet = "nodes",
                                   edge_sheet = "edges") {

  # Validate file exists
  if (!file.exists(file_path)) {
    stop("File not found: ", file_path)
  }

  # Validate file type (Excel)
  if (!grepl("\\.xlsx?$", file_path, ignore.case = TRUE)) {
    stop("File must be Excel format (.xlsx or .xls), got: ", basename(file_path))
  }

  # Check if required packages are available
  if (!requireNamespace("readxl", quietly = TRUE)) {
    stop("Package 'readxl' is required but not installed. Please install it with: install.packages('readxl')")
  }
  
  tryCatch({
    # Get sheet names
    sheet_names <- readxl::excel_sheets(file_path)
    message("Available sheets: ", paste(sheet_names, collapse = ", "))
    
    # Determine edge sheet
    if (is.null(sheet_name)) {
      # Look for common edge sheet names
      edge_candidates <- c("edges", "network", "connections", "links")
      edge_sheet_found <- intersect(tolower(sheet_names), edge_candidates)

      if (length(edge_sheet_found) > 0) {
        edge_sheet <- sheet_names[tolower(sheet_names) == edge_sheet_found[1]]
      } else {
        edge_sheet <- sheet_names[1]  # Use first sheet
      }
    } else {
      edge_sheet <- sheet_name
    }

    # Validate that the determined edge sheet exists
    if (!edge_sheet %in% sheet_names) {
      stop(sprintf("Edge sheet '%s' not found in Excel file. Available sheets: %s",
                   edge_sheet, paste(sheet_names, collapse = ", ")))
    }

    message("Reading edges from sheet: ", edge_sheet)

    # Read edge data
    edges_df <- readxl::read_excel(file_path, sheet = edge_sheet)
    
    # Clean column names
    colnames(edges_df) <- tolower(gsub("[^a-zA-Z0-9]", "_", colnames(edges_df)))
    
    # Find from/to columns (flexible naming)
    from_col <- NULL
    to_col <- NULL
    
    from_candidates <- c("from", "source", "from_node", "node1", "start")
    to_candidates <- c("to", "target", "to_node", "node2", "end")
    
    for (candidate in from_candidates) {
      if (candidate %in% colnames(edges_df)) {
        from_col <- candidate
        break
      }
    }
    
    for (candidate in to_candidates) {
      if (candidate %in% colnames(edges_df)) {
        to_col <- candidate
        break
      }
    }
    
    if (is.null(from_col) || is.null(to_col)) {
      stop("Could not find 'from' and 'to' columns. Expected names: ", 
           paste(c(from_candidates, to_candidates), collapse = ", "))
    }
    
    message("Using columns: ", from_col, " -> ", to_col)
    
    # Create node list from edge data
    all_nodes <- unique(c(edges_df[[from_col]], edges_df[[to_col]]))
    all_nodes <- all_nodes[!is.na(all_nodes)]
    
    # Try to read node data from separate sheet
    node_data <- NULL
    if (node_sheet %in% sheet_names) {
      tryCatch({
        node_data <- readxl::read_excel(file_path, sheet = node_sheet)
        colnames(node_data) <- tolower(gsub("[^a-zA-Z0-9]", "_", colnames(node_data)))
        message("Node data found in sheet: ", node_sheet)
      }, error = function(e) {
        message("Could not read node sheet, using edge-derived nodes")
      })
    }
    
    # Create igraph object
    g <- graph_from_data_frame(
      d = edges_df[, c(from_col, to_col)],
      directed = TRUE,
      vertices = if (!is.null(node_data)) node_data else data.frame(name = all_nodes)
    )
    
    # Add edge attributes
    edge_attrs <- setdiff(colnames(edges_df), c(from_col, to_col))
    for (attr in edge_attrs) {
      if (!all(is.na(edges_df[[attr]]))) {
        E(g)[[attr]] <- edges_df[[attr]]
      }
    }
    
    # Set default edge attributes if missing using utility function
    # Use non-random defaults for loaded data
    g <- ensure_edge_attributes(g, use_random = FALSE)

    # Set default node attributes if missing
    if (!"group" %in% vertex_attr_names(g)) {
      # Use utility function for consistent group assignment
      V(g)$group <- assign_default_groups(g)
    }
    
    if (!"label" %in% vertex_attr_names(g)) {
      V(g)$label <- V(g)$name
    }
    
    message(paste("Successfully loaded network with", vcount(g), "nodes and", ecount(g), "edges"))
    return(g)
    
  }, error = function(e) {
    stop("Error reading Excel file: ", e$message)
  })
}

# Function to save network to Excel file
save_network_to_excel <- function(g, file_path, 
                                 include_node_sheet = TRUE) {
  
  # Check if required packages are available
  if (!requireNamespace("openxlsx", quietly = TRUE)) {
    warning("Package 'openxlsx' not available. Cannot save to Excel format.")
    return(FALSE)
  }
  
  tryCatch({
    # Create workbook
    wb <- openxlsx::createWorkbook()
    
    # Create edges sheet
    edges_df <- as_data_frame(g, what = "edges")
    openxlsx::addWorksheet(wb, "edges")
    openxlsx::writeData(wb, "edges", edges_df)
    
    # Create nodes sheet if requested
    if (include_node_sheet) {
      nodes_df <- as_data_frame(g, what = "vertices")
      openxlsx::addWorksheet(wb, "nodes") 
      openxlsx::writeData(wb, "nodes", nodes_df)
    }
    
    # Save workbook
    openxlsx::saveWorkbook(wb, file_path, overwrite = TRUE)
    message("Network saved to: ", file_path)
    return(TRUE)
    
  }, error = function(e) {
    warning("Error saving Excel file: ", e$message)
    return(FALSE)
  })
}

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

# Function to list available sample networks
list_sample_networks <- function() {
  networks <- list(
    "simple_loop" = "3-node feedback loop (Driver -> Pressure -> Response)",
    "marine_ses_basic" = "18-node Marine SES with basic loops",
    "marine_ses_comprehensive" = "24-node comprehensive Marine SES system",
    "random_directed" = "Random directed network (from network_analysis_functions.R)"
  )
  
  cat("Available sample networks:\n")
  for (name in names(networks)) {
    cat("  ", name, ": ", networks[[name]], "\n")
  }
  
  return(networks)
}

# Function to create sample network by name
create_sample_network <- function(type = "simple_loop", ...) {
  tryCatch({
    result <- switch(type,
      "simple_loop" = create_simple_loop(),
      "marine_ses_basic" = create_marine_ses_with_loops(n_nodes = 18, include_simple_loop = TRUE),
      "marine_ses_comprehensive" = create_comprehensive_marine_ses(),
      "random_directed" = {
        # Create simple random directed graph with consistent seed
        set.seed(DEFAULT_RANDOM_SEED)
        g <- sample_gnp(n = DEFAULT_RANDOM_NETWORK_NODES, p = RANDOM_NETWORK_PROBABILITY, directed = TRUE)

        # Use utility functions for attributes
        g <- ensure_edge_attributes(g)
        V(g)$group <- assign_default_groups(g, seed = DEFAULT_RANDOM_SEED)
        V(g)$label <- paste("Node", 1:vcount(g))
        V(g)$name <- V(g)$label
        g
      },
      stop("Unknown network type: ", type, ". Use list_sample_networks() to see available types.")
    )
    return(result)
  }, error = function(e) {
    message("Error creating network of type '", type, "': ", e$message)
    # Fallback to simple loop
    return(create_simple_loop())
  })
}

# ============================================================================
# END OF I/O FUNCTIONS
# ============================================================================

message("Marine SES I/O Functions loaded successfully")
message("Available functions: create_simple_loop, create_marine_ses_with_loops, create_comprehensive_marine_ses, read_network_from_excel, save_network_to_excel, list_sample_networks, create_sample_network")