# Marine SES Network Analysis Constants
# Centralized configuration for all magic numbers and thresholds

# ============================================================================
# LOOP ANALYSIS CONSTANTS
# ============================================================================

# Performance thresholds for adaptive loop analysis
LOOP_LARGE_GRAPH_THRESHOLD <- 20      # Nodes count for "large" graph classification
LOOP_MEDIUM_GRAPH_THRESHOLD <- 15     # Nodes count for "medium" graph classification

# Loop detection limits
LOOP_DEFAULT_MIN_LENGTH <- 3          # Minimum meaningful loop length
LOOP_DEFAULT_MAX_LENGTH <- 6          # Default maximum loop length
LOOP_DEFAULT_MAX_LOOPS <- 50          # Default maximum loops to return

# Adaptive limits for large graphs
LOOP_LARGE_MAX_LENGTH <- 4            # Max loop length for large graphs
LOOP_LARGE_MAX_LOOPS <- 20            # Max loops to find in large graphs
LOOP_MEDIUM_MAX_LENGTH <- 5           # Max loop length for medium graphs
LOOP_MEDIUM_MAX_LOOPS <- 30           # Max loops to find in medium graphs

# Performance limits
LOOP_ANALYSIS_TIMEOUT_SECONDS <- 30   # Timeout for loop analysis
LOOP_SAMPLING_THRESHOLD <- 1000       # Max combinations before sampling

# ============================================================================
# NETWORK GENERATION CONSTANTS
# ============================================================================

# Default network sizes
DEFAULT_SIMPLE_LOOP_NODES <- 3
DEFAULT_MARINE_SES_NODES <- 18
DEFAULT_COMPREHENSIVE_SES_NODES <- 24
DEFAULT_RANDOM_NETWORK_NODES <- 15

# Network density targets
TARGET_NETWORK_DENSITY <- 0.15        # Target ~15% edge density
RANDOM_NETWORK_PROBABILITY <- 0.4     # Edge probability for random networks

# Edge attribute ranges
EDGE_WEIGHT_MIN <- 1.0
EDGE_WEIGHT_MAX <- 10.0
EDGE_STRENGTH_MIN <- -5.0
EDGE_STRENGTH_MAX <- 5.0
EDGE_CONFIDENCE_MIN <- 1
EDGE_CONFIDENCE_MAX <- 5

# Specific ranges for marine SES networks
MARINE_WEIGHT_MIN <- 3.0
MARINE_WEIGHT_MAX <- 8.0
MARINE_STRENGTH_MIN <- -2.0
MARINE_STRENGTH_MAX <- 4.0

# ============================================================================
# MARINE SES CATEGORIES
# ============================================================================

# Standard marine SES node groups
MARINE_SES_CATEGORIES <- c(
  "Activities",
  "Pressures",
  "Drivers",
  "Societal Goods and Services",
  "Ecosystem Services",
  "Marine Processes"
)

# Minimum nodes per category
MIN_NODES_PER_CATEGORY <- 1
DEFAULT_NODES_PER_CATEGORY <- 3

# Network size constraints
MIN_MARINE_SES_NODES <- 6             # 1 per category minimum
MAX_MARINE_SES_NODES <- 100           # Performance warning threshold

# ============================================================================
# CENTRALITY ANALYSIS CONSTANTS
# ============================================================================

# Default top N for leverage points
DEFAULT_TOP_N_LEVERAGE <- 10

# ============================================================================
# VISUALIZATION CONSTANTS
# ============================================================================

# Node visualization
DEFAULT_NODE_SIZE <- 40              # Increased from 20 (now 40) for much better visibility
LEVERAGE_NODE_SIZE <- 45             # Increased from 25 (now 45) for much better visibility
DEFAULT_NODE_COLOR <- "lightgray"
LEVERAGE_NODE_COLOR <- "orange"

# Edge visualization
DEFAULT_EDGE_ARROW_SIZE <- 0.5
DEFAULT_EDGE_WIDTH <- 1
DEFAULT_BASE_EDGE_WIDTH <- 10          # Base edge width for strength scaling

# NOTE: The following constants are defined for future use in edge visualization
# Currently not actively used in the app, but reserved for enhanced edge styling

# Confidence-based alpha values for edge transparency
# CONFIDENCE_ALPHA_LEVELS <- c(
#   0.2,   # Confidence 1 - very low
#   0.35,  # Confidence 2 - low
#   0.55,  # Confidence 3 - medium
#   0.75,  # Confidence 4 - high
#   1.0    # Confidence 5 - very high
# )

# Edge strength colors (for future color-coded edge visualization)
# STRONG_POSITIVE_COLOR <- "rgb(0, 100, 0)"      # Dark green
# MODERATE_POSITIVE_COLOR <- "rgb(34, 139, 34)"  # Medium green
# STRONG_NEGATIVE_COLOR <- "rgb(139, 0, 0)"      # Dark red
# MODERATE_NEGATIVE_COLOR <- "rgb(220, 20, 60)"  # Medium red

# Strength threshold for color differentiation
# EDGE_STRONG_THRESHOLD <- 3.0

# Group colors for marine SES visualization (including alternative names)
GROUP_COLORS <- list(
  "Activities" = "#FF9999",
  "Pressures" = "#99FF99",
  "Drivers" = "#9999FF",
  "Societal Goods and Services" = "#FFFF99",
  "Goods and benefits" = "#FFFF99",  # Alternative name
  "Ecosystem Services" = "#FF99FF",
  "Marine Processes" = "#99FFFF",
  "Marine Processes and Functioning" = "#99FFFF"  # Alternative name
)

# Group shapes for marine SES visualization (including alternative names)
GROUP_SHAPES <- list(
  "Activities" = "diamond",
  "Pressures" = "square",
  "Drivers" = "hexagon",
  "Societal Goods and Services" = "star",
  "Goods and benefits" = "star",  # Alternative name
  "Ecosystem Services" = "triangle",
  "Marine Processes" = "dot",
  "Marine Processes and Functioning" = "dot"  # Alternative name
)

# Default color/shape for unknown groups
DEFAULT_GROUP_COLOR <- "#95A5A6"
DEFAULT_GROUP_SHAPE <- "ellipse"

# ============================================================================
# NETWORK OPTIMIZATION CONSTANTS
# ============================================================================

# Edge optimization thresholds
MAX_EDGES_BEFORE_OPTIMIZATION <- 30    # Optimize networks with more than this many edges
EDGE_RETENTION_QUANTILE <- 0.7         # Keep top 30% of edges when optimizing (1 - 0.7 = 0.3)

# ============================================================================
# VISUALIZATION CONSTANTS (APP-SPECIFIC)
# ============================================================================

# Plot parameters
VERTEX_LABEL_CEX <- 0.7                # Vertex label text size
HISTOGRAM_BINS <- 15                   # Number of bins for histograms
HISTOGRAM_ALPHA <- 0.7                 # Transparency for histogram bars
MAX_BAR_LENGTH <- 30                   # Maximum bar length in text-based charts

# Risk level thresholds (for color coding)
RISK_LOW_THRESHOLD <- 30               # Below this = low risk (green)
RISK_HIGH_THRESHOLD <- 60              # Above this = high risk (red)

# ============================================================================
# UI LAYOUT CONSTANTS
# ============================================================================

# Box and panel heights
UI_BOX_HEIGHT_DEFAULT <- 400           # Standard box height for UI elements
UI_BOX_HEIGHT_LARGE <- 500             # Large box height for detailed views
UI_BOX_HEIGHT_SMALL <- 300             # Small box height for compact views

# Panel widths
UI_SIDEBAR_WIDTH <- 300                # Standard sidebar width

# Plot dimensions
PLOT_HEIGHT_DEFAULT <- 500             # Default plot height
PLOT_WIDTH_DEFAULT <- 800              # Default plot width
PLOT_MARGINS <- c(0, 0, 2, 0)          # Plot margins: bottom, left, top, right

# ============================================================================
# EXCEL I/O CONSTANTS
# ============================================================================

# Default sheet names
DEFAULT_EDGE_SHEET <- "edges"
DEFAULT_NODE_SHEET <- "nodes"

# Column name candidates for flexible parsing
FROM_COL_NAMES <- c("from", "source", "from_node", "node1", "start")
TO_COL_NAMES <- c("to", "target", "to_node", "node2", "end")
EDGE_SHEET_CANDIDATES <- c("edges", "network", "connections", "links")

# File upload limits
MAX_UPLOAD_SIZE_MB <- 100               # Maximum file size in megabytes (Shiny default)
MAX_UPLOAD_SIZE_BYTES <- MAX_UPLOAD_SIZE_MB * 1024^2  # Computed in bytes
ALLOWED_EXCEL_TYPES <- c("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",  # .xlsx
                          "application/vnd.ms-excel")                                            # .xls

# ============================================================================
# EXCEL SEMI-QUANTITATIVE STRENGTH MAPPING
# ============================================================================

# Mapping for semi-quantitative strength values to numerical values
STRENGTH_MAPPING <- list(
  "weak" = 1.5,
  "medium" = 3.0,
  "strong" = 4.5,
  "very weak" = 1.0,
  "very strong" = 5.0
)

# ============================================================================
# SEED MANAGEMENT
# ============================================================================

# Default seeds for reproducibility
DEFAULT_RANDOM_SEED <- 123
MARINE_SES_SEED <- 42

# ============================================================================
# MESSAGE CONSTANTS
# ============================================================================

MSG_LOOP_COMPLETE <- "Loop analysis complete. Found %d unique feedback loops"
MSG_LOOP_TIMEOUT <- "Loop analysis timeout reached, stopping early"
MSG_NETWORK_CREATED <- "Created %s network with %d nodes and %d edges"
MSG_GRAPH_CONVERTED <- "Graph converted to directed for loop analysis"
MSG_UNDIRECTED_CONVERTED <- "Converting undirected graph to directed for loop analysis"
MSG_LARGE_GRAPH_LIMIT <- "Large graph detected. Limiting search to loops of length %d or less, max %d loops"
MSG_MEDIUM_GRAPH_LIMIT <- "Medium graph detected. Limiting search to loops of length %d or less, max %d loops"

# ============================================================================
# END OF CONSTANTS
# ============================================================================

message("Marine SES constants loaded successfully")