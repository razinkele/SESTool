# global.R
# Global variables, package loading, and function sourcing for MarineSABRES SES Shiny App

# ============================================================================
# PACKAGE LOADING
# ============================================================================

# Suppress package startup messages
suppressPackageStartupMessages({
  
  # Core Shiny packages
  library(shiny)
  library(shinydashboard)
  library(shinyWidgets)
  library(shinyjs)
  
  # Data manipulation
  library(tidyverse)
  library(DT)
  library(openxlsx)
  library(jsonlite)
  
  # Network visualization and analysis
  library(igraph)
  library(visNetwork)
  library(ggraph)
  library(tidygraph)
  
  # Plotting
  library(ggplot2)
  library(plotly)
  library(dygraphs)
  library(xts)
  
  # Project management
  library(timevis)
  
  # Export/Reporting
  library(rmarkdown)
  library(htmlwidgets)
  
})

# ============================================================================
# SOURCE HELPER FUNCTIONS
# ============================================================================

# Data structure functions
source("functions/data_structure.R", local = TRUE)

# Network analysis functions
source("functions/network_analysis.R", local = TRUE)

# visNetwork helper functions
source("functions/visnetwork_helpers.R", local = TRUE)

# Export functions
source("functions/export_functions.R", local = TRUE)

# ============================================================================
# GLOBAL VARIABLES AND CONSTANTS
# ============================================================================

# DAPSI(W)R(M) element types
DAPSIWRM_ELEMENTS <- c(
  "Drivers",
  "Activities", 
  "Pressures",
  "Marine Processes & Functioning",
  "Ecosystem Services",
  "Goods & Benefits"
)

# Color scheme for DAPSI(W)R(M) elements
ELEMENT_COLORS <- list(
  "Drivers" = "#776db3",                           # Purple (Kumu style)
  "Activities" = "#5abc67",                        # Green (Kumu style)
  "Pressures" = "#fec05a",                         # Orange (Kumu style)
  "Marine Processes & Functioning" = "#bce2ee",    # Light Blue (Kumu style)
  "Ecosystem Services" = "#313695",                # Dark Blue (Kumu style)
  "Goods & Benefits" = "#fff1a2"                   # Light Yellow (Kumu style)
)

# Node shapes for each element type (following Kumu style guide)
# visNetwork available shapes: dot, diamond, square, triangle, triangleDown,
# star, hexagon, ellipse, database, text, circularImage, circle
# Note: hexagon is available! Octagon is not, using star as closest alternative
ELEMENT_SHAPES <- list(
  "Drivers" = "star",                            # Kumu: octagon → star (closest available)
  "Activities" = "hexagon",                      # Kumu: hexagon → hexagon (EXACT MATCH!)
  "Pressures" = "diamond",                       # Kumu: diamond (EXACT MATCH!)
  "Marine Processes & Functioning" = "dot",      # Kumu: pill → dot (circular, label outside)
  "Ecosystem Services" = "square",               # Kumu: square (EXACT MATCH!)
  "Goods & Benefits" = "triangle"                # Kumu: triangle (EXACT MATCH!)
)

# Edge colors (following Kumu style guide)
EDGE_COLORS <- list(
  reinforcing = "#80b8d7",    # Light blue (positive from Kumu)
  opposing = "#dc131e"        # Red (negative from Kumu)
)

# Demonstration Areas
DA_SITES <- c(
  "Tuscan Archipelago",
  "Arctic Northeast Atlantic",
  "Macaronesia"
)

# Stakeholder types (Newton & Elliott, 2016)
STAKEHOLDER_TYPES <- c(
  "Inputters",
  "Extractors",
  "Regulators",
  "Affectees",
  "Beneficiaries",
  "Influencers"
)

# Connection strength options
CONNECTION_STRENGTH <- c("strong", "medium", "weak")

# Connection polarity options
CONNECTION_POLARITY <- c("+", "-")

# Ecosystem service categories
ECOSYSTEM_SERVICE_CATEGORIES <- c(
  "Provisioning",
  "Regulating",
  "Cultural",
  "Supporting"
)

# Pressure types
PRESSURE_TYPES <- c(
  "Exogenic (ExP)",
  "Endogenic Managed (EnMP)"
)

# Spatial scales
SPATIAL_SCALES <- c(
  "Local",
  "Regional",
  "National",
  "International"
)

# Activity scales
ACTIVITY_SCALES <- c(
  "Individual",
  "Group/Sector",
  "National",
  "International"
)

# ============================================================================
# DEFAULT VALUES
# ============================================================================

# Default node size
DEFAULT_NODE_SIZE <- 25

# Default edge width
DEFAULT_EDGE_WIDTH <- 2

# Default hierarchy level separation
DEFAULT_LEVEL_SEPARATION <- 150

# Maximum loop length for detection
DEFAULT_MAX_LOOP_LENGTH <- 10

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

# Generate unique ID
generate_id <- function(prefix = "ID") {
  paste0(prefix, "_", format(Sys.time(), "%Y%m%d%H%M%S"), "_", 
         sample(1000:9999, 1))
}

# Format date for display
format_date_display <- function(date) {
  format(as.Date(date), "%d %B %Y")
}

# Validate email
is_valid_email <- function(email) {
  grepl("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", email)
}

# Convert adjacency matrix value to list
parse_connection_value <- function(value) {
  if (is.na(value) || value == "") {
    return(NULL)
  }
  
  polarity <- substr(value, 1, 1)
  strength <- substr(value, 2, nchar(value))
  
  list(polarity = polarity, strength = strength)
}

# ============================================================================
# DATA VALIDATION FUNCTIONS
# ============================================================================

# Validate DAPSI(W)R(M) element data
validate_element_data <- function(data, element_type) {
  errors <- c()
  
  # Check required columns
  required_cols <- c("id", "name", "indicator")
  missing_cols <- setdiff(required_cols, names(data))
  
  if (length(missing_cols) > 0) {
    errors <- c(errors, paste("Missing required columns:", 
                             paste(missing_cols, collapse = ", ")))
  }
  
  # Check for duplicate IDs
  if (any(duplicated(data$id))) {
    errors <- c(errors, "Duplicate IDs found")
  }
  
  # Check for empty names
  if (any(is.na(data$name) | data$name == "")) {
    errors <- c(errors, "Empty names found")
  }
  
  return(errors)
}

# Validate adjacency matrix
validate_adjacency_matrix <- function(adj_matrix) {
  errors <- c()
  
  # Check if matrix
  if (!is.matrix(adj_matrix)) {
    errors <- c(errors, "Not a valid matrix")
    return(errors)
  }
  
  # Check dimensions
  if (nrow(adj_matrix) == 0 || ncol(adj_matrix) == 0) {
    errors <- c(errors, "Matrix has zero dimensions")
  }
  
  # Check values
  valid_values <- c("", NA, 
                   paste0("+", CONNECTION_STRENGTH),
                   paste0("-", CONNECTION_STRENGTH))
  
  invalid_values <- !adj_matrix %in% valid_values
  if (any(invalid_values, na.rm = TRUE)) {
    errors <- c(errors, "Invalid connection values found")
  }
  
  return(errors)
}

# ============================================================================
# LOGGING FUNCTIONS
# ============================================================================

# Log message to console and file
log_message <- function(message, level = "INFO") {
  timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  log_entry <- sprintf("[%s] %s: %s", timestamp, level, message)
  
  # Print to console
  message(log_entry)
  
  # Optionally write to log file
  # log_file <- "logs/app.log"
  # if (!dir.exists("logs")) dir.create("logs")
  # write(log_entry, file = log_file, append = TRUE)
}

# ============================================================================
# SESSION MANAGEMENT
# ============================================================================

# Initialize session data
init_session_data <- function() {
  list(
    project_id = generate_id("PROJ"),
    created_at = Sys.time(),
    last_modified = Sys.time(),
    user = Sys.info()["user"],
    version = "1.0",
    data = list(
      metadata = list(),
      pims = list(),
      isa_data = list(),
      cld = list(),
      responses = list()
    )
  )
}

# ============================================================================
# APPLICATION SETTINGS
# ============================================================================

# Maximum file upload size (100 MB)
options(shiny.maxRequestSize = 100 * 1024^2)

# Enable bookmarking
enableBookmarking(store = "url")

# ============================================================================
# LOAD EXAMPLE DATA (if available)
# ============================================================================

if (file.exists("data/example_isa_data.R")) {
  source("data/example_isa_data.R", local = TRUE)
}

# ============================================================================
# INITIALIZATION MESSAGE
# ============================================================================

log_message("Global environment loaded successfully")
log_message(paste("Loaded", length(DAPSIWRM_ELEMENTS), "DAPSI(W)R(M) element types"))
log_message(paste("Application version:", "1.0"))
