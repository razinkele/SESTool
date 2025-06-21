# analysis.R - Loop Analysis Functions for SES Tool
# This file contains all functions related to causal loop analysis
# using the LoopAnalyst package for social-ecological systems

# Ensure LoopAnalyst is loaded
if (!require("LoopAnalyst")) {
  install.packages("LoopAnalyst")
  library(LoopAnalyst)
}

# Function to perform comprehensive loop analysis on the network
perform_loop_analysis <- function(edges_data, nodes_data = NULL) {
  # Validate input
  if (is.null(edges_data) || nrow(edges_data) == 0) {
    return(list(
      error = TRUE,
      message = "No edge data available for loop analysis"
    ))
  }
  
  # Ensure we have from and to columns
  if (!all(c("from", "to") %in% colnames(edges_data))) {
    return(list(
      error = TRUE,
      message = "Edge data must contain 'from' and 'to' columns"
    ))
  }
  
  tryCatch({
    # Create a unique node list
    all_nodes <- unique(c(edges_data$from, edges_data$to))
    n_nodes <- length(all_nodes)
    
    # Create adjacency matrix
    adj_matrix <- matrix(0, nrow = n_nodes, ncol = n_nodes)
    rownames(adj_matrix) <- colnames(adj_matrix) <- all_nodes
    
    # Fill the adjacency matrix
    for (i in 1:nrow(edges_data)) {
      from_idx <- which(all_nodes == edges_data$from[i])
      to_idx <- which(all_nodes == edges_data$to[i])
      
      # Set connection strength (1 for basic, or use weight if available)
      weight <- if ("weight" %in% colnames(edges_data)) {
        as.numeric(edges_data$weight[i])
      } else if ("width" %in% colnames(edges_data)) {
        as.numeric(edges_data$width[i])
      } else {
        1
      }
      
      adj_matrix[from_idx, to_idx] <- weight
    }
    
    # Make Loop Model
    loop_model <- make.cm(adj_matrix)
    
    # Perform various analyses
    results <- list(
      error = FALSE,
      adjacency_matrix = adj_matrix,
      n_nodes = n_nodes,
      n_edges = nrow(edges_data)
    )
    
    # 1. Find feedback loops
    tryCatch({
      loops <- enumerate.loops(loop_model)
      results$loops <- loops
      results$n_loops <- length(loops)
      
      # Categorize loops
      if (length(loops) > 0) {
        loop_lengths <- sapply(loops, length)
        results$loop_summary <- table(loop_lengths)
        names(results$loop_summary) <- paste(names(results$loop_summary), "nodes")
        
        # Identify positive and negative loops
        loop_types <- sapply(loops, function(loop) {
          loop_edges <- numeric()
          for (j in 1:(length(loop)-1)) {
            loop_edges <- c(loop_edges, adj_matrix[loop[j], loop[j+1]])
          }
          # Close the loop
          loop_edges <- c(loop_edges, adj_matrix[loop[length(loop)], loop[1]])
          
          # Count negative edges (if we had signed edges)
          # For now, assume all positive unless edge weight is negative
          neg_edges <- sum(loop_edges < 0)
          
          if (neg_edges == 0) {
            "reinforcing (R)"
          } else if (neg_edges %% 2 == 0) {
            "reinforcing (R)"
          } else {
            "balancing (B)"
          }
        })
        results$loop_types <- table(loop_types)
        
        # Store detailed loop information
        results$loop_details <- lapply(1:min(length(loops), 20), function(i) {
          loop_nodes <- all_nodes[loops[[i]]]
          loop_path <- paste(c(loop_nodes, loop_nodes[1]), collapse = " → ")
          list(
            id = i,
            length = length(loops[[i]]),
            type = loop_types[i],
            nodes = loop_nodes,
            path = loop_path
          )
        })
      }
    }, error = function(e) {
      results$loops_error <- paste("Loop enumeration failed:", e$message)
      results$n_loops <- 0
    })
    
    # 2. Calculate stability metrics
    tryCatch({
      # Check if system is stable
      results$stable <- stable.community(loop_model)
      
      # Get eigenvalues for stability analysis
      eigen_vals <- eigen(adj_matrix)$values
      results$max_eigenvalue <- max(Re(eigen_vals))
      results$stability_margin <- -results$max_eigenvalue
      
      # Additional stability metrics
      results$spectral_radius <- max(abs(eigen_vals))
      
    }, error = function(e) {
      results$stability_error <- paste("Stability analysis failed:", e$message)
    })
    
    # 3. Weighted Feedback Matrix
    tryCatch({
      W <- weighted.predictions(loop_model, method = "quasidet")
      results$weighted_feedback <- W
      
      # Find most influential connections
      if (!is.null(W)) {
        W_abs <- abs(W)
        diag(W_abs) <- 0  # Remove self-loops for this analysis
        
        # Get top influential pathways
        W_flat <- as.vector(W_abs)
        names(W_flat) <- as.vector(outer(rownames(W_abs), colnames(W_abs), paste, sep = " → "))
        W_sorted <- sort(W_flat, decreasing = TRUE)
        results$top_pathways <- head(W_sorted[W_sorted > 0], 20)
        
        # Calculate feedback importance for each node
        feedback_importance <- data.frame(
          node = rownames(W),
          outgoing_influence = rowSums(W_abs),
          incoming_influence = colSums(W_abs),
          total_influence = rowSums(W_abs) + colSums(W_abs),
          stringsAsFactors = FALSE
        )
        results$feedback_importance <- feedback_importance[order(feedback_importance$total_influence, decreasing = TRUE), ]
      }
    }, error = function(e) {
      results$feedback_error <- paste("Weighted feedback analysis failed:", e$message)
    })
    
    # 4. Node importance analysis using igraph
    tryCatch({
      # Create igraph object
      g <- graph_from_adjacency_matrix(adj_matrix, mode = "directed", weighted = TRUE)
      
      # Calculate various centrality measures
      results$node_metrics <- data.frame(
        node = all_nodes,
        in_degree = degree(g, mode = "in"),
        out_degree = degree(g, mode = "out"),
        total_degree = degree(g, mode = "all"),
        betweenness = round(betweenness(g), 2),
        closeness = round(closeness(g), 4),
        eigenvector = round(eigen_centrality(g)$vector, 3),
        page_rank = round(page_rank(g)$vector, 3),
        stringsAsFactors = FALSE
      )
      
      # Add loop participation
      if (!is.null(results$loops) && length(results$loops) > 0) {
        loop_participation <- sapply(1:n_nodes, function(i) {
          sum(sapply(results$loops, function(loop) i %in% loop))
        })
        results$node_metrics$loops_involved <- loop_participation
      } else {
        results$node_metrics$loops_involved <- 0
      }
      
      # Add group information if available
      if (!is.null(nodes_data) && "group" %in% colnames(nodes_data)) {
        results$node_metrics$group <- nodes_data$group[match(results$node_metrics$node, nodes_data$id)]
      }
      
      # Add confidence information if available
      if (!is.null(nodes_data) && "group_confidence" %in% colnames(nodes_data)) {
        results$node_metrics$group_confidence <- nodes_data$group_confidence[match(results$node_metrics$node, nodes_data$id)]
      }
      
      # Sort by eigenvector centrality
      results$node_metrics <- results$node_metrics[order(results$node_metrics$eigenvector, decreasing = TRUE), ]
      
    }, error = function(e) {
      results$metrics_error <- paste("Node metrics calculation failed:", e$message)
    })
    
    # 5. System-level metrics
    tryCatch({
      g <- graph_from_adjacency_matrix(adj_matrix, mode = "directed", weighted = TRUE)
      
      results$system_metrics <- list(
        nodes = n_nodes,
        edges = results$n_edges,
        density = round(edge_density(g), 3),
        reciprocity = round(reciprocity(g), 3),
        transitivity = round(transitivity(g), 3),
        mean_distance = round(mean_distance(g), 2),
        diameter = diameter(g),
        components = components(g)$no,
        largest_component_size = max(components(g)$csize)
      )
      
      # Add connectance (probability of connection)
      results$system_metrics$connectance <- round(results$n_edges / (n_nodes * (n_nodes - 1)), 3)
      
      # Add mean degree
      results$system_metrics$mean_degree <- round(mean(degree(g)), 2)
      
      # Add modularity if groups are available
      if (!is.null(nodes_data) && "group" %in% colnames(nodes_data)) {
        node_groups <- nodes_data$group[match(all_nodes, nodes_data$id)]
        if (!any(is.na(node_groups))) {
          membership <- as.numeric(factor(node_groups))
          results$system_metrics$modularity <- round(modularity(g, membership), 3)
        }
      }
      
    }, error = function(e) {
      results$system_error <- paste("System metrics calculation failed:", e$message)
    })
    
    # 6. SES-specific analysis
    if (!is.null(nodes_data) && "group" %in% colnames(nodes_data)) {
      tryCatch({
        # Analyze connections between SES groups
        group_connections <- analyze_group_connections(adj_matrix, nodes_data, all_nodes)
        results$group_connections <- group_connections
        
        # Find key bridges between groups
        results$key_bridges <- find_key_bridges(g, nodes_data, all_nodes)
        
      }, error = function(e) {
        results$ses_error <- paste("SES-specific analysis failed:", e$message)
      })
    }
    
    return(results)
    
  }, error = function(e) {
    return(list(
      error = TRUE,
      message = paste("Loop analysis failed:", e$message)
    ))
  })
}

# Helper function to analyze connections between SES groups
analyze_group_connections <- function(adj_matrix, nodes_data, all_nodes) {
  # Map nodes to groups
  node_groups <- nodes_data$group[match(all_nodes, nodes_data$id)]
  unique_groups <- unique(node_groups[!is.na(node_groups)])
  
  # Create group connection matrix
  n_groups <- length(unique_groups)
  group_matrix <- matrix(0, nrow = n_groups, ncol = n_groups)
  rownames(group_matrix) <- colnames(group_matrix) <- unique_groups
  
  # Count connections between groups
  for (i in 1:nrow(adj_matrix)) {
    for (j in 1:ncol(adj_matrix)) {
      if (adj_matrix[i, j] != 0) {
        from_group <- node_groups[i]
        to_group <- node_groups[j]
        
        if (!is.na(from_group) && !is.na(to_group)) {
          from_idx <- which(unique_groups == from_group)
          to_idx <- which(unique_groups == to_group)
          group_matrix[from_idx, to_idx] <- group_matrix[from_idx, to_idx] + 1
        }
      }
    }
  }
  
  # Calculate group-level metrics
  group_metrics <- data.frame(
    group = unique_groups,
    internal_connections = diag(group_matrix),
    outgoing_connections = rowSums(group_matrix) - diag(group_matrix),
    incoming_connections = colSums(group_matrix) - diag(group_matrix),
    total_connections = rowSums(group_matrix) + colSums(group_matrix) - 2 * diag(group_matrix),
    stringsAsFactors = FALSE
  )
  
  return(list(
    connection_matrix = group_matrix,
    metrics = group_metrics[order(group_metrics$total_connections, decreasing = TRUE), ]
  ))
}

# Helper function to find key bridges between groups
find_key_bridges <- function(g, nodes_data, all_nodes) {
  # Calculate edge betweenness
  edge_between <- edge_betweenness(g)
  
  # Get edge list with groups
  edges <- get.edgelist(g)
  edge_df <- data.frame(
    from = edges[, 1],
    to = edges[, 2],
    betweenness = edge_between,
    stringsAsFactors = FALSE
  )
  
  # Add group information
  node_groups <- nodes_data$group[match(all_nodes, nodes_data$id)]
  edge_df$from_group <- node_groups[match(edge_df$from, all_nodes)]
  edge_df$to_group <- node_groups[match(edge_df$to, all_nodes)]
  
  # Identify cross-group edges
  edge_df$cross_group <- edge_df$from_group != edge_df$to_group
  
  # Sort by betweenness
  edge_df <- edge_df[order(edge_df$betweenness, decreasing = TRUE), ]
  
  # Return top bridges
  bridges <- edge_df[edge_df$cross_group, ]
  return(head(bridges, 10))
}

# Function to create a comprehensive summary report of loop analysis
create_loop_report <- function(analysis_results) {
  if (analysis_results$error) {
    return(paste("Error:", analysis_results$message))
  }
  
  report <- c()
  report <- c(report, "🔄 CAUSAL LOOP ANALYSIS REPORT")
  report <- c(report, "==============================")
  report <- c(report, paste("Generated:", format(Sys.time(), "%Y-%m-%d %H:%M:%S")))
  report <- c(report, "")
  
  # Network overview
  report <- c(report, "📊 NETWORK OVERVIEW")
  report <- c(report, "-------------------")
  if (!is.null(analysis_results$system_metrics)) {
    sm <- analysis_results$system_metrics
    report <- c(report, paste("  • Nodes:", sm$nodes))
    report <- c(report, paste("  • Edges:", sm$edges))
    report <- c(report, paste("  • Density:", sm$density))
    report <- c(report, paste("  • Mean degree:", sm$mean_degree))
    report <- c(report, paste("  • Components:", sm$components))
    
    if (!is.null(sm$modularity)) {
      report <- c(report, paste("  • Modularity:", sm$modularity))
    }
  }
  report <- c(report, "")
  
  # Loop analysis
  report <- c(report, "🔁 FEEDBACK LOOPS")
  report <- c(report, "-----------------")
  if (!is.null(analysis_results$n_loops)) {
    report <- c(report, paste("  • Total loops found:", analysis_results$n_loops))
    
    if (analysis_results$n_loops > 0) {
      report <- c(report, "")
      report <- c(report, "  Loop size distribution:")
      for (i in 1:length(analysis_results$loop_summary)) {
        report <- c(report, paste("    -", names(analysis_results$loop_summary)[i], ":", 
                                analysis_results$loop_summary[i]))
      }
      
      if (!is.null(analysis_results$loop_types)) {
        report <- c(report, "")
        report <- c(report, "  Loop types:")
        for (type in names(analysis_results$loop_types)) {
          report <- c(report, paste("    -", type, ":", analysis_results$loop_types[type]))
        }
      }
      
      # Show first few loops
      if (!is.null(analysis_results$loop_details)) {
        report <- c(report, "")
        report <- c(report, "  Example loops (first 5):")
        for (i in 1:min(5, length(analysis_results$loop_details))) {
          loop <- analysis_results$loop_details[[i]]
          report <- c(report, paste("    ", i, ". [", loop$type, "] ", loop$path, sep = ""))
        }
      }
    }
  } else if (!is.null(analysis_results$loops_error)) {
    report <- c(report, paste("  ⚠️", analysis_results$loops_error))
  }
  report <- c(report, "")
  
  # Stability analysis
  report <- c(report, "📈 STABILITY ANALYSIS")
  report <- c(report, "--------------------")
  if (!is.null(analysis_results$stable)) {
    stability_status <- ifelse(analysis_results$stable, "✅ STABLE", "⚠️ UNSTABLE")
    report <- c(report, paste("  • System stability:", stability_status))
    
    if (!is.null(analysis_results$max_eigenvalue)) {
      report <- c(report, paste("  • Maximum eigenvalue:", round(analysis_results$max_eigenvalue, 3)))
      report <- c(report, paste("  • Stability margin:", round(analysis_results$stability_margin, 3)))
    }
    
    if (!is.null(analysis_results$spectral_radius)) {
      report <- c(report, paste("  • Spectral radius:", round(analysis_results$spectral_radius, 3)))
    }
    
    # Provide interpretation
    report <- c(report, "")
    if (analysis_results$stable) {
      report <- c(report, "  ℹ️ The system will return to equilibrium after small perturbations.")
    } else {
      report <- c(report, "  ⚠️ The system may exhibit unstable behavior or runaway dynamics.")
    }
  } else if (!is.null(analysis_results$stability_error)) {
    report <- c(report, paste("  ⚠️", analysis_results$stability_error))
  }
  report <- c(report, "")
  
  # Key pathways
  if (!is.null(analysis_results$top_pathways) && length(analysis_results$top_pathways) > 0) {
    report <- c(report, "🎯 MOST INFLUENTIAL PATHWAYS")
    report <- c(report, "---------------------------")
    for (i in 1:min(10, length(analysis_results$top_pathways))) {
      report <- c(report, paste("  ", i, ". ", names(analysis_results$top_pathways)[i], 
                              " (strength: ", round(analysis_results$top_pathways[i], 3), ")", sep = ""))
    }
    report <- c(report, "")
  }
  
  # Key nodes
  if (!is.null(analysis_results$node_metrics)) {
    report <- c(report, "⭐ MOST CENTRAL NODES")
    report <- c(report, "--------------------")
    top_nodes <- head(analysis_results$node_metrics, 10)
    for (i in 1:nrow(top_nodes)) {
      node_info <- paste(top_nodes$node[i])
      if (!is.null(top_nodes$group)) {
        node_info <- paste(node_info, paste0("[", top_nodes$group[i], "]"))
      }
      metrics <- paste("eigenvector:", top_nodes$eigenvector[i], 
                      "| betweenness:", top_nodes$betweenness[i],
                      "| loops:", top_nodes$loops_involved[i])
      report <- c(report, paste("  ", i, ". ", node_info, sep = ""))
      report <- c(report, paste("     ", metrics))
    }
    report <- c(report, "")
  }
  
  # SES group analysis
  if (!is.null(analysis_results$group_connections)) {
    report <- c(report, "🌊 SES GROUP INTERACTIONS")
    report <- c(report, "------------------------")
    
    gc <- analysis_results$group_connections$metrics
    for (i in 1:nrow(gc)) {
      report <- c(report, paste("  • ", gc$group[i], ":", sep = ""))
      report <- c(report, paste("    - Internal connections:", gc$internal_connections[i]))
      report <- c(report, paste("    - Outgoing connections:", gc$outgoing_connections[i]))
      report <- c(report, paste("    - Incoming connections:", gc$incoming_connections[i]))
    }
    report <- c(report, "")
    
    # Key bridges
    if (!is.null(analysis_results$key_bridges) && nrow(analysis_results$key_bridges) > 0) {
      report <- c(report, "  Key bridges between groups:")
      kb <- analysis_results$key_bridges
      for (i in 1:min(5, nrow(kb))) {
        report <- c(report, paste("    ", i, ". ", kb$from[i], " [", kb$from_group[i], "] → ",
                                kb$to[i], " [", kb$to_group[i], "]", 
                                " (importance: ", round(kb$betweenness[i], 1), ")", sep = ""))
      }
    }
  }
  
  return(paste(report, collapse = "\n"))
}

# Function to create detailed loop descriptions
describe_loops <- function(analysis_results, max_loops = 20) {
  if (is.null(analysis_results$loop_details) || length(analysis_results$loop_details) == 0) {
    return(data.frame(
      Loop_ID = integer(),
      Type = character(),
      Length = integer(),
      Path = character(),
      stringsAsFactors = FALSE
    ))
  }
  
  loop_descriptions <- do.call(rbind, lapply(1:min(max_loops, length(analysis_results$loop_details)), function(i) {
    loop <- analysis_results$loop_details[[i]]
    data.frame(
      Loop_ID = loop$id,
      Type = loop$type,
      Length = loop$length,
      Path = loop$path,
      stringsAsFactors = FALSE
    )
  }))
  
  return(loop_descriptions)
}

# Function to export analysis results to multiple formats
export_loop_analysis <- function(analysis_results, base_filename = "loop_analysis", format = "all") {
  timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
  
  # Export text report
  if (format %in% c("all", "txt")) {
    report_file <- paste0(base_filename, "_report_", timestamp, ".txt")
    report <- create_loop_report(analysis_results)
    writeLines(report, report_file)
    cat("Report exported to:", report_file, "\n")
  }
  
  # Export adjacency matrix
  if (format %in% c("all", "csv") && !is.null(analysis_results$adjacency_matrix)) {
    matrix_file <- paste0(base_filename, "_adjacency_", timestamp, ".csv")
    write.csv(analysis_results$adjacency_matrix, matrix_file)
    cat("Adjacency matrix exported to:", matrix_file, "\n")
  }
  
  # Export node metrics
  if (format %in% c("all", "csv") && !is.null(analysis_results$node_metrics)) {
    metrics_file <- paste0(base_filename, "_node_metrics_", timestamp, ".csv")
    write.csv(analysis_results$node_metrics, metrics_file, row.names = FALSE)
    cat("Node metrics exported to:", metrics_file, "\n")
  }
  
  # Export loop details
  if (format %in% c("all", "csv") && !is.null(analysis_results$loop_details)) {
    loops_file <- paste0(base_filename, "_loops_", timestamp, ".csv")
    loop_df <- describe_loops(analysis_results)
    write.csv(loop_df, loops_file, row.names = FALSE)
    cat("Loop details exported to:", loops_file, "\n")
  }
}

# Function to visualize loops on the network
create_loop_visualization_data <- function(analysis_results, loop_index = 1) {
  if (is.null(analysis_results$loops) || length(analysis_results$loops) < loop_index) {
    return(NULL)
  }
  
  loop <- analysis_results$loops[[loop_index]]
  loop_nodes <- rownames(analysis_results$adjacency_matrix)[loop]
  
  # Create edge list for the loop
  loop_edges <- data.frame(
    from = loop_nodes,
    to = c(loop_nodes[-1], loop_nodes[1]),
    color = "red",
    width = 5,
    stringsAsFactors = FALSE
  )
  
  return(list(
    nodes = loop_nodes,
    edges = loop_edges,
    description = analysis_results$loop_details[[loop_index]]
  ))
}

# Print initialization message
cat("✅ Loop analysis functions loaded successfully from analysis.R\n")
cat("   Available functions:\n")
cat("   - perform_loop_analysis(): Main analysis function\n")
cat("   - create_loop_report(): Generate text report\n")
cat("   - describe_loops(): Get loop descriptions\n")
cat("   - export_loop_analysis(): Export results to files\n")
cat("   - create_loop_visualization_data(): Prepare loop visualization\n")