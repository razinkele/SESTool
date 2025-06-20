# classes.R - Modified to work with utils.R intelligent group assignment
# Fixed and optimized with AI-powered node classification integration

# Load necessary libraries
library(readxl)
library(R6)
library(visNetwork)
library(igraph)

# Source the intelligent group assignment utilities
if (file.exists("utils.R")) {
  source("utils.R")
  cat("✓ Intelligent group assignment system loaded from utils.R\n")
  UTILS_AVAILABLE <- TRUE
} else {
  warning("⚠ utils.R not found - using fallback group assignment")
  UTILS_AVAILABLE <- FALSE
}

groupname <- "Nothing so far"

# Setting colours and shapes for SES defined groups see SES guidance document 
# Should pass and return net parameter for use with visNetwork package for %>% chaining
set_VisGroups <- function(net) {
  net <- net %>%
    visGroups(groupname = "Marine processes", title = groupname, shape = "dot", 
             color = list(border = "#2B7CE9", background = "lightblue")) %>%
    visGroups(groupname = "Pressures", title = groupname, shape = "square", 
             color = list(border = "darkgreen", background = "olive")) %>%
    visGroups(groupname = "Ecosystem Services", title = groupname, shape = "triangle", 
             color = list(border = "#2B7CE9", background = "#D2E5FF")) %>%
    visGroups(groupname = "Societal Goods and Benefits", title = groupname, shape = "triangleDown", 
             color = list(border = "#2B7CE9", background = "Teal")) %>%
    visGroups(groupname = "Activities", shape = "diamond", title = groupname, 
             color = list(border = "darkgrey", background = "darkgrey")) %>%
    visGroups(groupname = "Drivers", shape = "hexagon", title = groupname, 
             color = list(border = "darkseagreen", background = "lightseagreen")) %>%
    visGroups(groupname = "Unclassified", shape = "star", title = groupname, 
             color = list(border = "orange", background = "lightyellow"))
  
  return(net)
}

# Legacy terms list for backward compatibility
terms_list <- list(
  "Marine processes" = c("ocean", "marine", "sea", "coastal", "biodiversity"),
  "Pressures" = c("pollution", "fishing", "climate", "pressure", "stress"),
  "Ecosystem Services" = c("service", "production", "provision", "regulation"),
  "Societal Goods and Benefits" = c("benefit", "goods", "welfare", "tourism", "food"),
  "Activities" = c("fishing", "shipping", "development", "activity", "operation"),
  "Drivers" = c("driver", "policy", "economic", "population", "technology")
)

# Legacy function for backward compatibility
assign_group <- function(node_name, terms_list) {
  # Use intelligent assignment if available
  if (UTILS_AVAILABLE && exists("assign_node_group")) {
    result <- assign_node_group(node_name)
    return(result$group)
  }
  
  # Fallback to original logic
  assigned_keyword <- NULL
  for (term in names(terms_list)) {
    keywords <- terms_list[[term]]
    match <- sapply(keywords, function(keyword) grepl(keyword, node_name, ignore.case = TRUE))
    if (any(match)) {
      assigned_keyword <- keywords[which(match)[1]]
      break
    }
  }
  return(assigned_keyword)
}

# Updated default groups (FIXED: "Actvities" -> "Activities")
defaultGroups <- c("Marine processes", "Pressures", "Ecosystem Services", 
                   "Societal Goods and Benefits", "Activities", "Drivers")

# All shapes available in visNetwork package for nodes
shapes <- c("hexagon", "diamond", "ellipse", "square", "dot", "triangle", "triangleDown", "star")

# Function checking the strings in the columns by partial fit
partial_fit <- function(data, column, char_array, new_column) {
  data[[new_column]] <- sapply(data[[column]], function(x) {
    if (any(grepl(paste(char_array, collapse = "|"), x))) {
      return(TRUE)
    } else {
      return(FALSE)
    }
  })
  return(data)
}

# Define the SES class ----
SES <- R6Class("SES",
  public = list(
    nodes = NULL,
    edges = NULL,
    nnodes = NULL,
    nedges = NULL,
    network = NULL,
    title = NULL,
    groups = FALSE,
    directed = TRUE, # Whether the network is directed
    bowtie = NULL, # Bowtie components
    dpsir = NULL, # DPSIR components
    dpsirwrm = NULL, # DPSIR-WRM components
    g = NULL,  # iGraph object
    file_path = NULL, # Store file path for intelligent assignment
    use_intelligent_groups = TRUE, # Flag for intelligent assignment
    
    initialize = function(file_path, nodes_sheet = 1, edges_sheet = 2, use_intelligent_groups = TRUE) {
      # Store configuration
      self$file_path <- file_path
      self$use_intelligent_groups <- use_intelligent_groups && UTILS_AVAILABLE
      
      # Validate file exists
      if (!file.exists(file_path)) {
        stop("File does not exist: ", file_path)
      }
      
      # Check number of sheets and read accordingly
      tryCatch({
        sheets <- readxl::excel_sheets(file_path)
        
        if (length(sheets) == 1) {   
          # Read the file with one sheet
          self$nodes <- NULL
          self$edges <- read_excel(file_path)
          print(paste("Read single sheet with", nrow(self$edges), "edges"))
        } else { 
          # Read the file with two sheets
          self$nodes <- read_excel(file_path, sheet = nodes_sheet)
          self$edges <- read_excel(file_path, sheet = edges_sheet)
          print(paste("Read two sheets:", nrow(self$nodes), "nodes,", nrow(self$edges), "edges"))
        }
      }, error = function(e) {
        stop("Error reading Excel file: ", e$message)
      })
      
      # Validate edges data
      if (is.null(self$edges) || nrow(self$edges) == 0) {
        stop("No edges data found in file")
      }
      
      # Check for the presence of "from" and "to" columns in the edges data frame
      print("Edges column names:")
      print(colnames(self$edges))
      
      # Ensure the column names in edges are "from" and "to"
      if (ncol(self$edges) >= 2) {
        colnames(self$edges)[1:2] <- c("from", "to")
      } else {
        stop("Edges data must have at least 2 columns")
      }
      
      # Calculate number of nodes and edges
      self$nnodes <- length(unique(c(self$edges$from, self$edges$to)))
      self$nedges <- nrow(self$edges)
      print("Edges column names after renaming:")
      print(colnames(self$edges))
      
      # Process width/strength column
      self$process_edge_weights()
      
      # Process edge colors based on sign
      if (is.numeric(self$edges$width)) {
        self$edges$color <- ifelse(self$edges$width > 0, "green", "red")
        
        # Recode the width column to values 1:10
        width_range <- range(self$edges$width, na.rm = TRUE)
        if (width_range[1] != width_range[2]) {
          self$edges$width <- cut(as.numeric(self$edges$width), breaks = 10, labels = 1:10)
          self$edges$width <- as.numeric(as.character(self$edges$width))
        } else {
          # All values are the same, assign middle value
          self$edges$width <- rep(5, length(self$edges$width))
        }
      }
      
      # Process nodes
      self$process_nodes()
      
      # Create the iGraph graph object
      tryCatch({
        self$g <- graph_from_data_frame(d = self$edges, vertices = self$nodes, directed = TRUE)
        print(paste("Created igraph object with", vcount(self$g), "nodes and", ecount(self$g), "edges"))
      }, error = function(e) {
        warning("Could not create igraph object: ", e$message)
      })
      
      self$create_network()
    },
    
    process_edge_weights = function() {
      # Check for various weight column names and standardize
      weight_columns <- c("strength", "Strength", "Width", "Values", "weight", "Weight")
      found_column <- NULL
      
      for (col in weight_columns) {
        if (col %in% names(self$edges)) {
          found_column <- col
          break
        }
      }
      
      if (!is.null(found_column)) {
        self$edges$width <- self$edges[[found_column]]
        self$edges[[found_column]] <- NULL
        print(paste("Found weight column:", found_column))
      } else {
        # No width column found, set default
        self$edges$width <- rep(1, self$nedges)
        print("No weight column found, using default width = 1")
      }
      
      # Process non-numeric width values
      if (!is.numeric(self$edges$width)) {
        if (all(is.na(as.numeric(self$edges$width)))) {
          # Check for KUMU-style categorical weights
          if (any(grepl("Positive|Negative", self$edges$width))) {
            self$process_kumu_weights()
          } else {
            # Default to 1 for all edges
            print("Setting all widths to 1")
            self$edges$width <- rep(1, self$nedges)
          }
        } else {
          # Some values can be converted to numeric
          self$edges$width <- as.numeric(self$edges$width)
          self$edges$width[is.na(self$edges$width)] <- 1  # Replace NAs with 1
        }
      }
    },
    
    process_kumu_weights = function() {
      # Process KUMU-style weight labels
      weights <- unique(self$edges$width)
      print("Processing KUMU weights:")
      print(weights)
      
      # Create a mapping for different weight types
      weight_map <- list(
        "Strong Negative" = -1,
        "Medium Negative" = -0.5,
        "Weak Negative" = -0.25,
        "Weak Positive" = 0.25,
        "Medium Positive" = 0.5,
        "Strong Positive" = 1
      )
      
      # Apply mapping or use generic conversion
      for (i in seq_along(self$edges$width)) {
        weight_val <- self$edges$width[i]
        if (weight_val %in% names(weight_map)) {
          self$edges$width[i] <- weight_map[[weight_val]]
        } else if (grepl("Negative", weight_val)) {
          self$edges$width[i] <- -0.25
        } else if (grepl("Positive", weight_val)) {
          self$edges$width[i] <- 0.25
        } else {
          self$edges$width[i] <- 0.25  # Default for unrecognized values
        }
      }
      
      # Convert to numeric
      self$edges$width <- as.numeric(self$edges$width)
      print("Processed widths:")
      print(summary(self$edges$width))
    },
    
    process_nodes = function() {
      # Create nodes frame with unique node ids from edges
      unique_ids <- unique(c(self$edges$from, self$edges$to))
      nodes <- data.frame(id = unique_ids, stringsAsFactors = FALSE)
      
      # Process existing nodes data if available
      if (!is.null(self$nodes)) {
        self$nodes <- as.data.frame(self$nodes)
        nodes[, 1] <- as.character(nodes[, 1])
        
        print("Calculated Nodes")
        print(head(nodes[, 1]))
        print("Existing Nodes")
        print(head(self$nodes[, 1]))
        
        # FIXED: Correct syntax for column name assignment
        colnames(self$nodes)[1] <- "id"
        
        # Find new rows not in existing nodes
        new_rows <- nodes[!nodes[, 1] %in% self$nodes[, 1], , drop = FALSE]
        print("New rows:")
        print(new_rows)
        
        # FIXED: Correct logic check
        if (nrow(self$nodes) > 0) {
          print("Merging nodes:")
          print(colnames(nodes))
          print(colnames(self$nodes))
          
          # Merge nodes data
          self$nodes <- merge(nodes, self$nodes, by = "id", all.x = TRUE)
          print("Merged nodes:")
          print(head(self$nodes))
        } else {
          self$nodes <- nodes
        }
      } else {
        self$nodes <- nodes
      }
      
      # Ensure title column exists
      if (!"title" %in% colnames(self$nodes)) {
        self$nodes$title <- paste0("<p><b>", seq_len(self$nnodes), "</b><br>Node</p>")
      }
      
      # Assign groups to nodes using intelligent assignment
      self$assign_node_groups()
      
      # Create enhanced tooltips
      self$create_node_tooltips()
      
      print("Final nodes column names:")
      print(colnames(self$nodes))
      print("Final nodes summary:")
      print(head(self$nodes))
    },
    
    assign_node_groups = function() {
      print("Starting group assignment...")
      
      # Use intelligent group assignment if available and enabled
      if (self$use_intelligent_groups && UTILS_AVAILABLE && exists("assign_multiple_groups")) {
        print("Using intelligent group assignment from utils.R")
        
        tryCatch({
          # Check if nodes already have groups
          existing_groups <- "group" %in% colnames(self$nodes)
          
          if (!existing_groups || all(is.na(self$nodes$group)) || all(self$nodes$group == "")) {
            # Apply intelligent assignment
            description_col <- if ("description" %in% colnames(self$nodes)) "description" else NULL
            
            classified_nodes <- assign_multiple_groups(
              self$nodes,
              name_column = "id",
              description_column = description_col,
              confidence_threshold = 0.4,  # Lower threshold for more assignments
              add_confidence = TRUE
            )
            
            # Update nodes with intelligent groups
            self$nodes$group <- classified_nodes$group
            self$nodes$group_confidence <- classified_nodes$group_confidence
            
            # Report results
            if (exists("analyze_classification_results")) {
              analysis <- analyze_classification_results(classified_nodes)
              print("Intelligent assignment complete:")
              print(paste("- Classified:", analysis$total_nodes - analysis$unclassified_count, "nodes"))
              print(paste("- Unclassified:", analysis$unclassified_count, "nodes"))
              print(paste("- Average confidence:", round(analysis$average_confidence, 3)))
            }
            
          } else {
            print("Nodes already have group assignments - keeping existing groups")
          }
          
        }, error = function(e) {
          print(paste("Error in intelligent assignment:", e$message))
          print("Falling back to default assignment...")
          self$fallback_group_assignment()
        })
        
      } else {
        if (!self$use_intelligent_groups) {
          print("Intelligent assignment disabled - using fallback")
        } else {
          print("utils.R not available - using fallback assignment")
        }
        self$fallback_group_assignment()
      }
    },
    
    fallback_group_assignment = function() {
      # Fallback group assignment method (original logic with improvements)
      file_path_name <- basename(self$file_path)
      
      if (grepl("MadeiraImportant.xlsx", file_path_name)) {
        print("Assigning groups manually for Madeira dataset:")
        if (self$nnodes == 10) {
          self$nodes$group <- c("Drivers", "Marine processes", "Pressures", "Pressures", "Drivers", 
                               "Pressures", "Societal Goods and Benefits", "Marine processes", 
                               "Marine processes", "Ecosystem Services")
        } else {
          # Fallback to random assignment if node count doesn't match
          self$nodes$group <- sample(defaultGroups, self$nnodes, replace = TRUE)
        }
      } else {
        # Random group assignment for other datasets
        print("Applying random group assignment")
        self$nodes$group <- sample(defaultGroups, self$nnodes, replace = TRUE)
      }
      
      # Add default confidence if not present
      if (!"group_confidence" %in% colnames(self$nodes)) {
        self$nodes$group_confidence <- 0.5  # Default medium confidence
      }
    },
    
    apply_intelligent_groups = function(confidence_threshold = 0.5) {
      # Method to manually trigger intelligent group assignment
      if (!UTILS_AVAILABLE || !exists("assign_multiple_groups")) {
        warning("utils.R not loaded - cannot apply intelligent groups")
        return(FALSE)
      }
      
      print("Manually applying intelligent group assignment...")
      
      tryCatch({
        description_col <- if ("description" %in% colnames(self$nodes)) "description" else NULL
        
        classified_nodes <- assign_multiple_groups(
          self$nodes,
          name_column = "id", 
          description_column = description_col,
          confidence_threshold = confidence_threshold,
          add_confidence = TRUE
        )
        
        # Update nodes
        self$nodes$group <- classified_nodes$group
        self$nodes$group_confidence <- classified_nodes$group_confidence
        
        # Update tooltips
        self$create_node_tooltips()
        
        # Recreate network with new groups
        self$create_network()
        
        # Return analysis
        if (exists("analyze_classification_results")) {
          analysis <- analyze_classification_results(classified_nodes)
          print("Manual intelligent assignment complete!")
          return(analysis)
        }
        
        return(TRUE)
        
      }, error = function(e) {
        warning(paste("Error applying intelligent groups:", e$message))
        return(FALSE)
      })
    },
    
    create_node_tooltips = function() {
      # Create enhanced tooltips with confidence information
      if ("group_confidence" %in% colnames(self$nodes)) {
        self$nodes$title <- paste0(
          "<p><b>", self$nodes$id, "</b><br>",
          "Group: ", self$nodes$group, "<br>",
          "Confidence: ", round(self$nodes$group_confidence, 2), "</p>"
        )
      } else if ("group" %in% colnames(self$nodes)) {
        self$nodes$title <- paste0(
          "<p><b>", self$nodes$id, "</b><br>",
          "Group: ", self$nodes$group, "</p>"
        )
      } else {
        self$nodes$title <- paste0("<p><b>", self$nodes$id, "</b><br>Node</p>")
      }
    },
    
    create_network = function() {
      # Validate data before creating network
      if (is.null(self$nodes) || is.null(self$edges)) {
        stop("Cannot create network: missing nodes or edges data")
      }
      
      print("Creating network visualization...")
      
      # Create arrows for the legend
      ledges <- data.frame(
        color = c("green", "red"),
        label = c("positive", "negative"), 
        arrows = c("to", "to"),
        font.align = "top"
      )
      
      tryCatch({
        self$network <- visNetwork(self$nodes, self$edges) %>%
          visEdges(arrows = "to") %>%
          set_VisGroups() %>%
          visOptions(highlightNearest = TRUE, nodesIdSelection = TRUE) %>%
          visLegend(addEdges = ledges, useGroups = self$groups)
        
        print("Network visualization created successfully")
      }, error = function(e) {
        warning("Error creating network visualization: ", e$message)
        self$network <- NULL
      })
    },
    
    get_group_analysis = function() {
      # Method to get group analysis results
      if (UTILS_AVAILABLE && exists("analyze_classification_results") && "group_confidence" %in% colnames(self$nodes)) {
        return(analyze_classification_results(self$nodes))
      } else {
        # Basic analysis without confidence
        group_counts <- table(self$nodes$group)
        return(list(
          total_nodes = nrow(self$nodes),
          group_distribution = group_counts,
          group_percentages = round(prop.table(group_counts) * 100, 1),
          unclassified_count = sum(self$nodes$group == "Unclassified"),
          unclassified_percentage = round(sum(self$nodes$group == "Unclassified") / nrow(self$nodes) * 100, 1)
        ))
      }
    },
    
    net_indices = function() {
      # Calculate network indices safely
      if (is.null(self$g)) {
        warning("No igraph object available for calculating indices")
        return(invisible(NULL))
      }
      
      print("Calculating network indices...")
      
      tryCatch({
        V(self$g)$betweenness_centrality <- betweenness(self$g, v = V(self$g), directed = TRUE)
        V(self$g)$degree <- degree(self$g, v = V(self$g), mode = "in")
        V(self$g)$closeness <- closeness(self$g, vids = V(self$g), mode = "in")
        
        eigen_result <- eigen_centrality(self$g, directed = TRUE, scale = FALSE, weights = NULL)
        V(self$g)$eigen_centrality <- eigen_result$vector
        
        pagerank_result <- page_rank(self$g, vids = V(self$g), directed = TRUE, damping = 0.85)
        V(self$g)$page_rank <- pagerank_result$vector
        
        # Graph-level metrics
        graph_transitivity <- transitivity(self$g, type = "global")
        graph_diameter <- diameter(self$g, directed = TRUE, weights = NULL)
        graph_radius <- radius(self$g, directed = TRUE, weights = NULL)
        graph_avg_path <- average.path.length(self$g, directed = TRUE, unconnected = TRUE)
        graph_reciprocity <- reciprocity(self$g, mode = "default")
        graph_assortativity <- assortativity.degree(self$g, directed = TRUE)
        graph_density <- edge_density(self$g, loops = FALSE)
        
        # Store graph-level metrics as attributes
        self$g$transitivity <- graph_transitivity
        self$g$diameter <- graph_diameter
        self$g$radius <- graph_radius
        self$g$avg_path_length <- graph_avg_path
        self$g$reciprocity <- graph_reciprocity
        self$g$assortativity <- graph_assortativity
        self$g$density <- graph_density
        self$g$edge_count <- ecount(self$g)
        self$g$node_count <- vcount(self$g)
        
        # Calculate edge betweenness
        edge_between <- edge_betweenness(self$g, directed = TRUE)
        E(self$g)$edge_betweenness <- edge_between
        
        print("Network indices calculated successfully")
      }, error = function(e) {
        warning("Error calculating network indices: ", e$message)
      })
    },
    
    plot_network = function() {
      if (is.null(self$network)) {
        warning("Network has not been created yet or creation failed.")
        return(invisible(NULL))
      }
      print(self$network)
    },
    
    summary = function() {
      cat("SES Network Summary\n")
      cat("==================\n")
      cat("File:", basename(self$file_path), "\n")
      cat("Nodes:", self$nnodes, "\n")
      cat("Edges:", self$nedges, "\n")
      cat("Intelligent assignment:", ifelse(self$use_intelligent_groups && UTILS_AVAILABLE, "Enabled", "Disabled"), "\n")
      
      if ("group" %in% colnames(self$nodes)) {
        cat("\nGroup Distribution:\n")
        group_counts <- table(self$nodes$group)
        for (i in seq_along(group_counts)) {
          cat("  ", names(group_counts)[i], ":", group_counts[i], "\n")
        }
      }
      
      if ("group_confidence" %in% colnames(self$nodes)) {
        avg_conf <- round(mean(self$nodes$group_confidence, na.rm = TRUE), 3)
        cat("Average Confidence:", avg_conf, "\n")
      }
    }
  )
)

# Test the class only if script is executed directly
if (sys.nframe() == 0) {
  print("Testing SES class directly")
  print("=========================")
  
  # Define the data file path
  data_filename <- "Faroe_May2024.xlsx"
  file_path <- file.path(getwd(), "data", data_filename)
  print(paste("Looking for file:", file_path))
  
  # Test if file exists before trying to load
  if (file.exists(file_path)) {
    tryCatch({
      # Read and initialise the class SES object with intelligent groups
      ses <- SES$new(file_path, use_intelligent_groups = TRUE)
      
      # Show summary
      ses$summary()
      
      # Show group analysis if intelligent assignment was used
      if (UTILS_AVAILABLE) {
        analysis <- ses$get_group_analysis()
        print("Group Analysis:")
        print(analysis)
      }
      
      # Calculate network indices
      ses$net_indices()
      
      # Plot the network
      ses$plot_network()
      
    }, error = function(e) {
      print(paste("Error testing SES class:", e$message))
    })
  } else {
    print(paste("Test file not found:", file_path))
    print("Available files in data directory:")
    if (dir.exists(file.path(getwd(), "data"))) {
      files <- list.files(file.path(getwd(), "data"), pattern = "\\.xlsx$")
      if (length(files) > 0) {
        for (f in files) print(paste("  -", f))
      } else {
        print("  No .xlsx files found")
      }
    } else {
      print("  Data directory does not exist")
    }
  }
} else {
  print("SES classes loaded and ready")
}