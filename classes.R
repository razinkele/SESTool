# optimize the code below
# outline for the code below
# 1. Load necessary libraries
# 2. Define the SES class
# 3. Define the public methods of the SES class
# 4. Example usage
# 5. Run the example code if the script is executed directly
# 6. Return the SES class
    



# Load necessary libraries
library(readxl)
library(R6)
library(visNetwork)
library(igraph)
groupname <- "Nothing so far"
# Setting colours and shapes for SES defined groups see SES guidance document 
# Should pass and return net parameter for use with visNetwork package for %>%  chaining
# 

set_VisGroups <- function(net) {
  net <- net %>%
    visGroups(groupname = "Marine processes", title = groupname, shape = "dot", color = list(border = "#2B7CE9",background ="lightblue")) %>%
    visGroups(groupname = "Pressures",title = groupname, shape = "square", color = list(border = "darkgreen",background="olive")) %>%
    visGroups(groupname = "Ecosystem Services", title = groupname, shape = "triangle", color = list(border = "#2B7CE9",background= "#D2E5FF")) %>%
    visGroups(groupname = "Societal Goods and Benefits", title = groupname, shape = "triangleDown", color = list(border = "#2B7CE9",background= "Teal")) %>%
    visGroups(groupname = "Actvities", shape = "diamond", title = groupname, color = list(border = "darkgrey",background="darkgrey")) %>%
    visGroups(groupname = "Drivers", shape = "hexagon", title = groupname, color = list(border = "darkseagreen",background ="lightseagreen")) %>% 
    return(net)
}

# Example terms list
terms_list <- list(
  "Marine processes" = c("", "banana", "cherry"),
  "Pressures"= c("dog", "cat", "horse"),
  "Ecosystem Services"= c("london", "paris", "new york"),
  "Societal Goods and Benefits" =c("clean water", "clean air", "food"),
  "Actvities" = c("car", "bike", "train"),
  "Drivers" = c("red", "green", "blue")
)
assign_group <- function(node_name, terms_list) {
  # Initialize the result as NULL
  assigned_keyword <- NULL
  
  # Iterate over each term in the list
  for (term in names(terms_list)) {
    # Get the associated keywords for the term
    keywords <- terms_list[[term]]
    
    # Check for partial matches
    match <- sapply(keywords, function(keyword) grepl(keyword, node_name, ignore.case = TRUE))
    
    # If a match is found, assign the keyword and break the loop
    if (any(match)) {
      assigned_keyword <- keywords[which(match)[1]]  # Take the first matching keyword
      break
    }
  }
  
  # Return the assigned keyword, or NULL if no match is found
  return(assigned_keyword)
}

  groups = c("Marine processes", "Pressures", "Ecosystem Services", "Societal Goods and Benefits", "Actvities", "Drivers")
  group_keywords <- c("Marine processes", "Pressures", "Ecosystem Services", "Societal Goods and Benefits", "Actvities", "Drivers")

# Function trying to guess the group of the node based on the string in the node name
# takes the data frame with nodes and the column name with the node names
# 


# function checking the strings in the columns by partial fit described in a char array and assigning a new column value
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
defaultGroups <- c("Marine processes", "Pressures", "Ecosystem Services", "Societal Goods and Benefits", "Actvities", "Drivers")
# All shapes available in visNetwork package for nodes with labels outside the nodes
shapes <- c("hexagon", "diamond", "ellipse", "square", "dot", "triangle", "triangleDown")

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
    initialize = function(file_path, nodes_sheet = 1, edges_sheet = 2) {

      # check whether the file contains one or twoo sheets
      # if one sheet, then the first sheet is the nodes
      # if two sheets, then the first sheet is the nodes and the second sheet is the edges
      if (length(readxl::excel_sheets(file_path)) == 1) 
        {   # read the file with one sheet
        self$nodes <- NULL
        self$edges <- read_excel(file_path)
        } 
      else 
        { # read the file with two sheets
        self$nodes <- read_excel(file_path, sheet = nodes_sheet)
        self$edges <- read_excel(file_path, sheet = edges_sheet)
      }
      # Check for the presence of "from" and "to" columns in the edges data frame
      print("Edges column names:")
      print(colnames(self$edges))
      # Ensure the column names in edges are "from" and "to"
      colnames(self$edges)[1:2] <- c("from", "to")
      # Calculate number of nodes and edges
      self$nnodes <- length(unique(c(self$edges$from, self$edges$to)))
      self$nedges <- nrow(self$edges)
      print("Edges column names:")
      print(colnames(self$edges))
      # Check for the presence of "strength","Strength"
      # or "Values" column and rename it to "width"
      if ("strength" %in% names(self$edges)) {
        self$edges$width <- self$edges$strength
        self$edges$strength <- NULL
      } else if ("Strength" %in% names(self$edges)) {
        self$edges$width <- self$edges$Strength
        self$edges$Strength <- NULL
      } 
      else if ("Width" %in% names(self$edges)) {
        self$edges$width <- self$edges$Width
        self$edges$Width <- NULL
      }
      else if ("Values" %in% names(self$edges)) {
        self$edges$width <- self$edges$Values
        self$edges$Values <- NULL
      }
      # Check if the "width" column is numeric
      if (!is.numeric(self$edges$width)) {
        if (all(is.na(as.numeric(self$edges$width)))) {
          # No numeric values in the "width" column
          if ("Weak Positive" %in% self$edges$width) {
            #  Looks like KUMU outputs
            weights <- unique(self$edges$width)
            print("________ These are weights ___________________")
            print(weights)
            # recode the weights to num values
            # self$edges$width<-1

            self$edges$width[self$edges$width == "Medium Negative"] <- (-.5)
            self$edges$width[self$edges$width == weights[2]] <- (-1)
            self$edges$width[self$edges$width == weights[3]] <- .5 # medium positive
            self$edges$width[self$edges$width == weights[4]] <- .25 # low positive
            self$edges$width[self$edges$width == weights[5]] <- (-.25)
            self$edges$width[self$edges$width == weights[6]] <- .25 # NAs
            self$edges$width[self$edges$width == weights[7]] <- .25 # typo in original data
            self$edges$width[self$edges$width == weights[8]] <- (-.25)
            print("________ These are widths after ___________________")
            print(self$edges$width)
          } else {
            # If no width column is present, set the edge width to 1
            print("Assigning all widths to 1")
            self$edges$width <- rep(1, self$nedges)
          }
        } else if (!all(is.na(as.numeric(self$edges$width)))) {
          print("convert all to numeric")
          self$edges$width <- as.numeric(self$edges$width)
        }
      }
      # Check for the presence of "sign" or "Sign" column and rename it to "color"
      print(self$edges$width)

      # Check for the sign of the edge width
      self$edges$color <- ifelse(self$edges$width > 0, "green", "red")

      # Recode the width column to values 1:10
      self$edges$width <- cut(as.numeric(self$edges$width), breaks = 10, labels = 1:10)

      # Convert the factor to numeric
      self$edges$width <- as.numeric(as.character(self$edges$width))
      
      # Nodes ----
      # Create nodes frame with unique node ids from edges
      nodes <- data.frame(id = unique(c(self$edges$from, self$edges$to)))
      # Find rows in elements where the first column values 
      # are not in elements read from the first sheet
      if (!is.null(self$nodes)) {
        self$nodes <- as.data.frame(self$nodes)
        nodes[, 1] <- as.character(nodes[, 1])
        #self$nodes[, 1] <- as.character(self$nodes[, 1])
        print("Calculated Nodes")
        print( nodes[, 1])
        print("Existing Nodes")
        print(self$nodes[, 1])
        print("End Existing Nodes")
        str(nodes[, 1])
        print("End Calculated Nodes structure")
        str(self$nodes[, 1])
        print("End Existing Nodes structure")
        # Find rows in elements where the first column values 
        # are not in elements read from the first sheet
        new_rows <- nodes[!nodes[, 1] %in% self$nodes[, 1], ]
        print("New rows:")
        print(new_rows)
        print("End New rows:")
      } 
      
      # if self$nodes is not null, merge it with the nodes frame
      if (!is.null(NULL)) {
        print("Merge nodes:")
        print(colnames(nodes))
        print(colnames(self$nodes))
        # print first column of dataframe self$nodes
        colnames(self$nodes[1]) <- id
        print(self$nodes$id)
        print(nodes$id)
        self$nodes <- merge(nodes, self$nodes, by = "id", all.x = TRUE)
        print(self$nodes)
      }
      else {
        self$nodes <- nodes
      }
      # if the title column is not present, create it
      self$nodes$title <- paste0("<p><b>", 1:self$nnodes, "</b><br>Node !</p>")
      
      
      # Assign groups to nodes based on the node names ----
      #### specific for Madeira
      if (file_path == "MadeiraImportant.xlsx") {
        print("assigning groups manually to 10 nodes :")
        # "Conservation" "Protected.Areas" "Large.scale.tourism""Pollution" "Sanitation""Disturbance""Economy"                    "Nature"       "Habitats" "Charismatic.landscape"
        self$nodes$group <- c("Drivers", "Marine processes", "Pressures", "Pressures", "Drivers", "Pressures", "Societal Goods and Benefits", "Marine processes", "Marine processes", "Ecosystem Services")
      } else {
        # random group assignment
        self$nodes$group <- sample(defaultGroups, self$nnodes, replace = TRUE)
      }


      self$nodes$title <- self$nodes$id
      print("Nodes column names:")

      print(colnames(self$nodes))
      print(self$nodes)
      # Create the iGraph graph object
      self$g <- graph_from_data_frame(d = self$edges, vertices = self$nodes, directed = TRUE)
      self$create_network()
    },
    create_network = function() {
      # arrows for the legend
      ledges <- data.frame(
        color = c("green", "red"),
        label = c("positive", "negative"), arrows = c("to", "to"),
        font.align = "top"
      )
      self$network <- visNetwork(self$nodes, self$edges) %>%
        visEdges(arrows = "to") %>%
        set_VisGroups() %>%
        visOptions(highlightNearest = TRUE, nodesIdSelection = TRUE) %>%
        visLegend( # addNodes = addNodes,
          addEdges = ledges, useGroups = self$groups
        )
    },
    net_indices = function() {
      V(self$g)$betweenness_centrality <- betweenness(self$g, v = V(self$g), directed = TRUE)
      V(self$g)$degree <- degree(self$g, v = V(self$g), mode = "in")
      V(self$g)$closeness <- closeness(self$g, vids = V(self$g), mode = "in")
      V(self$g)$eigen_centrality <- eigen_centrality(self$g, directed = TRUE, scale = FALSE, weights = NULL, options = NULL)
      V(self$g)$page_rank <- page_rank(self$g, vids = V(self$g), directed = TRUE, damping = 0.85, personalized = NULL, weights = NULL, options = NULL)
      # V(self$g)$hub_score <- hub_score(self$g, vids = V(self$g), weights = NULL, scale = TRUE)
      # V(self$g)$authority_score <- authority_score(self$g, vids = V(self$g), weights = NULL, scale = TRUE)
      V(self$g)$transitivity <- transitivity(self$g, type = c("local", "global", "average"))
      V(self$g)$clustering <- clustering(self$g, mode = "all")
      V(self$g)$diameter <- diameter(self$g, directed = TRUE, weights = NULL)
      V(self$g)$radius <- radius(self$g, directed = TRUE, weights = NULL)
      V(self$g)$avg_path_length <- average.path.length(self$g, directed = TRUE, unconnected = TRUE)
      V(self$g)$reciprocity <- reciprocity(self$g, mode = "all")
      V(self$g)$assortativity <- assortativity.degree(self$g, directed = TRUE)
      V(self$g)$density <- edge_density(self$g, loops = FALSE)
      V(self$g)$edge_count <- ecount(self$g)
      V(self$g)$node_count <- vcount(self$g)
      V(self$g)$edge_betweenness <- edge_betweenness(self$g, directed = TRUE)
    },
    plot_network = function() {
      if (is.null(self$network)) {
        stop("Network has not been created yet.")
      }
      print(self$network)
    }
  )
)

# test the class
if (sys.nframe() == 0) {
  
  # This code runs only if the script is executed directly.
  print("Executed directly.")
  # Define the data file path
  #data_filename <- "Simplified final map SES.xlsx"
  data_filename <- "Faroe_May2024.xlsx"
  #data_filename <- "Azores_V3_May2024.xlsx" # bad file
  file_path <- file.path(getwd(),"data",data_filename)
  print(file_path)
  # read and initialise the class SES object
  ses <- SES$new(file_path)
  
  # ses$net_indices()
  
  ses$plot_network()
} else {
  print("This script is being sourced.")
}
