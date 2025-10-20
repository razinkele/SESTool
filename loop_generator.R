# loop_generator.R - Loop Network Generator Plugin for SES Tool
# This plugin generates pre-designed networks with obvious feedback loops for testing and demonstration

# Template Definitions
LOOP_TEMPLATES <- list(
  "simple_marine" = list(
    name = "Simple Marine Ecosystem",
    description = "Basic marine food web with fishing pressure feedback loop",
    nodes = c("Fish Population", "Fishing Pressure", "Fish Catch", "Fisher Income", 
             "Fishing Effort", "Marine Habitat", "Water Quality", "Tourism"),
    groups = c("Marine processes", "Pressures", "Ecosystem Services", "Societal Goods and Benefits",
              "Activities", "Marine processes", "Marine processes", "Activities"),
    loops = list(
      reinforcing = list(
        c("Fish Population", "Fish Catch", "Fisher Income", "Fishing Effort", "Fishing Pressure", "Fish Population")
      ),
      balancing = list(
        c("Marine Habitat", "Water Quality", "Fish Population", "Tourism", "Marine Habitat")
      )
    )
  ),
  
  "complex_fisheries" = list(
    name = "Complex Fisheries System",
    description = "Multi-stakeholder fisheries with economic and regulatory feedback",
    nodes = c("Fish Stock", "Fishing Fleet Size", "Market Demand", "Fish Price", "Fishing Investment",
             "Overfishing Risk", "Stock Recovery", "Fishing Regulation", "Employment", "Coastal Communities"),
    groups = c("Marine processes", "Activities", "Drivers", "Societal Goods and Benefits", "Drivers",
              "Pressures", "Marine processes", "Drivers", "Societal Goods and Benefits", "Societal Goods and Benefits"),
    loops = list(
      reinforcing = list(
        c("Market Demand", "Fish Price", "Fishing Investment", "Fishing Fleet Size", "Fish Stock", "Market Demand"),
        c("Employment", "Coastal Communities", "Fishing Investment", "Employment")
      ),
      balancing = list(
        c("Fish Stock", "Overfishing Risk", "Fishing Regulation", "Fishing Fleet Size", "Fish Stock"),
        c("Fish Stock", "Stock Recovery", "Fish Stock")
      )
    )
  ),
  
  "coastal_tourism" = list(
    name = "Coastal Tourism System",
    description = "Tourism-environment interaction with development pressure",
    nodes = c("Beach Quality", "Tourist Arrivals", "Tourism Revenue", "Coastal Development",
             "Marine Pollution", "Ecosystem Health", "Recreation Value", "Local Employment"),
    groups = c("Marine processes", "Activities", "Societal Goods and Benefits", "Pressures",
              "Pressures", "Marine processes", "Ecosystem Services", "Societal Goods and Benefits"),
    loops = list(
      reinforcing = list(
        c("Tourist Arrivals", "Tourism Revenue", "Coastal Development", "Marine Pollution", "Beach Quality", "Tourist Arrivals")
      ),
      balancing = list(
        c("Ecosystem Health", "Recreation Value", "Tourist Arrivals", "Local Employment", "Ecosystem Health"),
        c("Beach Quality", "Tourist Arrivals", "Tourism Revenue", "Beach Quality")
      )
    )
  ),
  
  "climate_ecosystem" = list(
    name = "Climate-Ecosystem Feedback",
    description = "Climate change impacts on marine ecosystems with feedback loops",
    nodes = c("Ocean Temperature", "Marine Biodiversity", "Carbon Sequestration", "Climate Change",
             "Ocean Acidification", "Coral Bleaching", "Fish Migration", "Ecosystem Services"),
    groups = c("Marine processes", "Marine processes", "Ecosystem Services", "Drivers",
              "Pressures", "Pressures", "Marine processes", "Ecosystem Services"),
    loops = list(
      reinforcing = list(
        c("Climate Change", "Ocean Temperature", "Coral Bleaching", "Marine Biodiversity", "Carbon Sequestration", "Climate Change"),
        c("Ocean Temperature", "Fish Migration", "Marine Biodiversity", "Ocean Temperature")
      ),
      balancing = list(
        c("Marine Biodiversity", "Ecosystem Services", "Carbon Sequestration", "Marine Biodiversity"),
        c("Ocean Acidification", "Marine Biodiversity", "Ocean Acidification")
      )
    )
  ),
  
  "pollution_chain" = list(
    name = "Pollution Impact Chain",
    description = "Industrial pollution impacts with regulatory response",
    nodes = c("Industrial Discharge", "Water Pollution", "Marine Life Health", "Food Web Integrity",
             "Human Health Risk", "Environmental Regulation", "Cleanup Costs", "Public Awareness"),
    groups = c("Activities", "Pressures", "Marine processes", "Marine processes",
              "Societal Goods and Benefits", "Drivers", "Societal Goods and Benefits", "Drivers"),
    loops = list(
      reinforcing = list(
        c("Water Pollution", "Marine Life Health", "Human Health Risk", "Public Awareness", "Environmental Regulation", "Industrial Discharge", "Water Pollution")
      ),
      balancing = list(
        c("Marine Life Health", "Food Web Integrity", "Marine Life Health"),
        c("Human Health Risk", "Cleanup Costs", "Environmental Regulation", "Human Health Risk")
      )
    )
  ),
  
  "multi_feedback" = list(
    name = "Multiple Feedback System",
    description = "Complex system with multiple interacting feedback loops",
    nodes = c("Population Growth", "Resource Demand", "Fishing Intensity", "Stock Depletion",
             "Economic Impact", "Policy Response", "Technology Innovation", "Sustainability Index",
             "Environmental Awareness", "Conservation Efforts"),
    groups = c("Drivers", "Drivers", "Activities", "Pressures",
              "Societal Goods and Benefits", "Drivers", "Drivers", "Ecosystem Services",
              "Drivers", "Activities"),
    loops = list(
      reinforcing = list(
        c("Population Growth", "Resource Demand", "Fishing Intensity", "Stock Depletion", "Economic Impact", "Population Growth"),
        c("Environmental Awareness", "Conservation Efforts", "Sustainability Index", "Environmental Awareness")
      ),
      balancing = list(
        c("Stock Depletion", "Policy Response", "Technology Innovation", "Sustainability Index", "Stock Depletion"),
        c("Economic Impact", "Policy Response", "Conservation Efforts", "Economic Impact"),
        c("Resource Demand", "Technology Innovation", "Resource Demand")
      )
    )
  )
)

#' Generate a loop-rich network based on template
#' 
#' @param template Template name from LOOP_TEMPLATES
#' @param size Number of nodes (will adjust template)
#' @param complexity Number of loops to include
#' @param add_noise Whether to add random connections
#' @return List with nodes and edges dataframes
generate_loop_network <- function(template = "simple_marine", size = 8, complexity = 2, add_noise = TRUE) {
  
  # Validate template
  if (!template %in% names(LOOP_TEMPLATES)) {
    stop("Unknown template. Available templates: ", paste(names(LOOP_TEMPLATES), collapse = ", "))
  }
  
  template_data <- LOOP_TEMPLATES[[template]]
  
  # Adjust nodes to requested size
  base_nodes <- template_data$nodes[1:min(size, length(template_data$nodes))]
  base_groups <- template_data$groups[1:length(base_nodes)]
  
  # Add generic nodes if needed
  if (size > length(base_nodes)) {
    n_additional <- size - length(base_nodes)
    additional_nodes <- paste("Additional Node", 1:n_additional)
    additional_groups <- sample(c("Marine processes", "Pressures", "Ecosystem Services", 
                                 "Societal Goods and Benefits", "Activities", "Drivers"), 
                               n_additional, replace = TRUE)
    base_nodes <- c(base_nodes, additional_nodes)
    base_groups <- c(base_groups, additional_groups)
  }
  
  # Create nodes dataframe
  nodes_df <- data.frame(
    id = base_nodes,
    group = base_groups,
    shape = "dot",
    Name = base_nodes,
    stringsAsFactors = FALSE
  )
  
  # Generate edges from loops
  edges_list <- list()
  loop_counter <- 0
  
  # Add reinforcing loops
  all_loops <- c(template_data$loops$reinforcing, template_data$loops$balancing)
  loop_types <- c(rep("reinforcing", length(template_data$loops$reinforcing)),
                 rep("balancing", length(template_data$loops$balancing)))
  
  for (i in 1:min(complexity, length(all_loops))) {
    loop <- all_loops[[i]]
    loop_type <- loop_types[i]
    
    # Filter loop to only include nodes we have
    valid_loop <- loop[loop %in% base_nodes]
    
    if (length(valid_loop) >= 3) {
      loop_counter <- loop_counter + 1
      
      # Create edges for this loop
      for (j in 1:length(valid_loop)) {
        from_node <- valid_loop[j]
        to_node <- valid_loop[ifelse(j == length(valid_loop), 1, j + 1)]
        
        # Add edge strength based on loop type
        edge_weight <- ifelse(loop_type == "reinforcing", 
                             runif(1, 0.6, 0.9),  # Stronger for reinforcing
                             runif(1, 0.4, 0.7))  # Moderate for balancing
        
        edges_list[[length(edges_list) + 1]] <- data.frame(
          from = from_node,
          to = to_node,
          weight = edge_weight,
          loop_id = loop_counter,
          loop_type = loop_type,
          arrows = "to",
          width = 2 + edge_weight,
          stringsAsFactors = FALSE
        )
      }
    }
  }
  
  # Add some random connections if requested
  if (add_noise && length(base_nodes) > 3) {
    n_random <- sample(2:min(5, length(base_nodes)), 1)
    
    for (i in 1:n_random) {
      from_node <- sample(base_nodes, 1)
      possible_to <- base_nodes[base_nodes != from_node]
      to_node <- sample(possible_to, 1)
      
      # Check if this edge already exists
      existing_edge <- any(sapply(edges_list, function(edge) {
        edge$from == from_node && edge$to == to_node
      }))
      
      if (!existing_edge) {
        edges_list[[length(edges_list) + 1]] <- data.frame(
          from = from_node,
          to = to_node,
          weight = runif(1, 0.2, 0.5),
          loop_id = NA,
          loop_type = "random",
          arrows = "to",
          width = 1,
          stringsAsFactors = FALSE
        )
      }
    }
  }
  
  # Combine edges and add colors
  if (length(edges_list) > 0) {
    edges_df <- do.call(rbind, edges_list)
    
    # Color coding: reinforcing = red, balancing = blue, random = gray
    edges_df$color <- ifelse(edges_df$loop_type == "reinforcing", "#ff6b6b",
                            ifelse(edges_df$loop_type == "balancing", "#4ecdc4", "#95a5a6"))
    
    # Add edge labels for loop edges
    edges_df$title <- ifelse(is.na(edges_df$loop_id), 
                            "Random connection",
                            paste("Loop", edges_df$loop_id, "-", edges_df$loop_type))
  } else {
    # Create minimal edges if no loops were created
    edges_df <- data.frame(
      from = base_nodes[1],
      to = base_nodes[2],
      weight = 0.5,
      loop_id = NA,
      loop_type = "minimal",
      arrows = "to",
      width = 1,
      color = "#95a5a6",
      title = "Minimal connection",
      stringsAsFactors = FALSE
    )
  }
  
  # Add enhanced tooltips to nodes
  nodes_df$title <- paste0(
    "<p><b>", nodes_df$id, "</b><br>",
    "Group: ", nodes_df$group, "<br>",
    "Type: SES Component</p>"
  )
  
  return(list(
    nodes = nodes_df,
    edges = edges_df,
    template_info = template_data,
    actual_loops = loop_counter,
    template_name = template_data$name
  ))
}

#' Get information about available templates
#' 
#' @return Dataframe with template information
get_template_info <- function() {
  info_list <- lapply(names(LOOP_TEMPLATES), function(name) {
    template <- LOOP_TEMPLATES[[name]]
    data.frame(
      Template = name,
      Name = template$name,
      Description = template$description,
      Nodes = length(template$nodes),
      `Reinforcing Loops` = length(template$loops$reinforcing),
      `Balancing Loops` = length(template$loops$balancing),
      stringsAsFactors = FALSE,
      check.names = FALSE
    )
  })
  
  do.call(rbind, info_list)
}

#' Add a random loop to existing network data
#' 
#' @param nodes_df Existing nodes dataframe
#' @param edges_df Existing edges dataframe
#' @param loop_size Size of loop to add (3-6 nodes)
#' @return Updated edges dataframe
add_random_loop <- function(nodes_df, edges_df, loop_size = NULL) {
  
  if (nrow(nodes_df) < 3) {
    stop("Need at least 3 nodes to create a loop")
  }
  
  if (is.null(loop_size)) {
    loop_size <- sample(3:min(6, nrow(nodes_df)), 1)
  }
  
  # Select random nodes for the loop
  loop_nodes <- sample(nodes_df$id, loop_size)
  
  # Create new edges for circular loop
  new_edges <- data.frame(
    from = loop_nodes,
    to = c(loop_nodes[-1], loop_nodes[1]),
    weight = runif(loop_size, 0.3, 0.8),
    arrows = "to",
    width = 2,
    color = paste0("#", paste(sample(c(0:9, letters[1:6]), 6, replace = TRUE), collapse = "")),
    title = paste("Added loop:", paste(loop_nodes, collapse = " → ")),
    stringsAsFactors = FALSE
  )
  
  # Remove any existing edges between these nodes to avoid duplicates
  existing_connections <- paste(edges_df$from, edges_df$to)
  new_connections <- paste(new_edges$from, new_edges$to)
  
  # Keep only edges that don't duplicate new ones
  filtered_edges <- edges_df[!existing_connections %in% new_connections, ]
  
  # Combine with new edges
  combined_edges <- rbind(filtered_edges, new_edges)
  
  return(combined_edges)
}

#' Analyze the loop structure of a network
#' 
#' @param edges_df Edges dataframe
#' @param nodes_df Nodes dataframe
#' @return Summary of network structure
analyze_network_structure <- function(edges_df, nodes_df) {
  
  n_nodes <- nrow(nodes_df)
  n_edges <- nrow(edges_df)
  
  # Calculate basic metrics
  density <- round(n_edges / (n_nodes * (n_nodes - 1)), 3)
  avg_degree <- round(2 * n_edges / n_nodes, 2)
  
  # Group distribution
  if ("group" %in% colnames(nodes_df)) {
    group_dist <- table(nodes_df$group)
    most_common_group <- names(group_dist)[which.max(group_dist)]
  } else {
    group_dist <- "No groups"
    most_common_group <- "Unknown"
  }
  
  # Edge type distribution
  if ("loop_type" %in% colnames(edges_df)) {
    loop_edges <- sum(!is.na(edges_df$loop_id))
    random_edges <- sum(is.na(edges_df$loop_id))
  } else {
    loop_edges <- "Unknown"
    random_edges <- "Unknown"
  }
  
  return(list(
    summary = paste(
      "Network Structure Analysis\n",
      "==========================\n",
      "Nodes:", n_nodes, "\n",
      "Edges:", n_edges, "\n",
      "Density:", density, "\n",
      "Average Degree:", avg_degree, "\n",
      "Most Common Group:", most_common_group, "\n",
      "Loop Edges:", loop_edges, "\n",
      "Random Edges:", random_edges
    ),
    metrics = list(
      nodes = n_nodes,
      edges = n_edges,
      density = density,
      avg_degree = avg_degree,
      group_distribution = group_dist,
      loop_edges = loop_edges,
      random_edges = random_edges
    )
  ))
}

# Print available templates on load
cat("🔄 Loop Generator Plugin Loaded\n")
cat("Available Templates:\n")
for (name in names(LOOP_TEMPLATES)) {
  template <- LOOP_TEMPLATES[[name]]
  cat(paste("  -", name, ":", template$name, "\n"))
}
cat("\n")
