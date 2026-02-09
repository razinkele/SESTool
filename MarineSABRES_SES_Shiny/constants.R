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

# Standard marine SES node groups (legacy naming)
MARINE_SES_CATEGORIES <- c(
  "Activities",
  "Pressures",
  "Drivers",
  "Societal Goods and Services",
  "Ecosystem Services",
  "Marine Processes"
)

# DAPSI(W)R(M) element types (MarineSABRES standard naming)
DAPSIWRM_ELEMENTS <- c(
  "Drivers",
  "Activities",
  "Pressures",
  "Marine Processes & Functioning",
  "Ecosystem Services",
  "Goods & Benefits",
  "Responses"
)

# DAPSI(W)R(M) element ID prefixes (for generating element IDs like "D001", "A002")
ELEMENT_ID_PREFIX <- list(
  drivers    = "D",
  activities = "A",
  pressures  = "P",
  states     = "MPF",   # Marine Processes & Functioning
  impacts    = "ES",    # Ecosystem Services
  welfare    = "GB",    # Goods & Benefits
  responses  = "R",
  measures   = "RM"     # Response Measures
)

# PIMS module ID prefixes
PIMS_ID_PREFIX <- list(
  stakeholder   = "SH",
  engagement    = "ENG",
  communication = "COMM"
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
DEFAULT_NODE_SIZE <- 40              # Standard node size for network visualizations
LARGE_NODE_SIZE <- 50                # Large node size for graphical SES creator
SMALL_NODE_SIZE <- 25                # Small node size for compact views
MEDIUM_NODE_SIZE <- 30               # Medium node size for moderate views
LEVERAGE_NODE_SIZE <- 45             # Node size for leverage points
MIN_NODE_SIZE <- 15                  # Minimum node size for scaling
MAX_NODE_SIZE <- 50                  # Maximum node size for scaling

DEFAULT_NODE_COLOR <- "lightgray"
LEVERAGE_NODE_COLOR <- "orange"

# Node borders
DEFAULT_BORDER_WIDTH <- 2            # Standard border width
SELECTED_BORDER_WIDTH <- 3           # Border width for selected nodes
GHOST_BORDER_WIDTH <- 3              # Border width for ghost/preview nodes

# Font sizes
FONT_SIZE_SMALL <- 10                # Small font for labels
FONT_SIZE_MEDIUM <- 12               # Medium font for labels
FONT_SIZE_STANDARD <- 14             # Standard font for most text
FONT_SIZE_LARGE <- 16                # Large font for prominent nodes

# Node opacity
NODE_OPACITY_NORMAL <- 1.0           # Full opacity for normal nodes
NODE_OPACITY_GHOST <- 0.4            # Semi-transparent for ghost/preview nodes

# Edge visualization
DEFAULT_EDGE_ARROW_SIZE <- 0.5
DEFAULT_EDGE_WIDTH <- 1
DEFAULT_BASE_EDGE_WIDTH <- 10          # Base edge width for strength scaling
EDGE_WIDTH_THIN <- 0.15              # Thin edge width for subtle connections

# Label configuration
LABEL_WRAP_WIDTH <- 20               # Maximum characters per line in wrapped labels
VERTEX_LABEL_CEX_SMALL <- 0.7        # Small vertex label size

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

# ============================================================================
# DAPSIWRM ELEMENT STYLING (Kumu-style colors and shapes)
# ============================================================================

# Color scheme for DAPSI(W)R(M) elements (following Kumu style guide)
ELEMENT_COLORS <- list(
  "Drivers" = "#776db3",                           # Purple (Kumu style)
  "Activities" = "#5abc67",                        # Green (Kumu style)
  "Pressures" = "#fec05a",                         # Orange (Kumu style)
  "Marine Processes & Functioning" = "#bce2ee",    # Light Blue (Kumu style)
  "Ecosystem Services" = "#313695",                # Dark Blue (Kumu style)
  "Goods & Benefits" = "#fff1a2",                  # Light Yellow (Kumu style)
  "Responses" = "#9C27B0",                         # Purple for management responses
  "Measures" = "#795548"                           # Brown for management measures/instruments
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
  "Goods & Benefits" = "triangle",               # Kumu: triangle (EXACT MATCH!)
  "Responses" = "triangleDown"                   # Inverted triangle for management responses
)

# Edge colors (following Kumu style guide)
EDGE_COLORS <- list(
  reinforcing = "#80b8d7",    # Light blue (positive from Kumu)
  opposing = "#dc131e"        # Red (negative from Kumu)
)

# ============================================================================
# LEGACY GROUP COLORS/SHAPES (for backward compatibility)
# ============================================================================

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
# EXPORT CONSTANTS
# ============================================================================

# Export filename date format
EXPORT_DATE_FORMAT <- "%Y%m%d"        # Date format for exported filenames (e.g. "20260208")

# PNG export dimensions
EXPORT_PNG_WIDTH <- 1200              # Default width for exported PNG images
EXPORT_PNG_HEIGHT <- 900              # Default height for exported PNG images

# Shadow effects
SHADOW_SIZE <- 5                      # Size of shadow effect for nodes

# ============================================================================
# VISUALIZATION CONSTANTS (APP-SPECIFIC)
# ============================================================================

# Plot parameters
VERTEX_LABEL_CEX <- 0.7                # Vertex label text size (used in static plots)
HISTOGRAM_BINS <- 15                   # Number of bins for histograms
HISTOGRAM_ALPHA <- 0.7                 # Transparency for histogram bars
MAX_BAR_LENGTH <- 30                   # Maximum bar length in text-based charts

# Risk level thresholds (for color coding)
RISK_LOW_THRESHOLD <- 30               # Below this = low risk (green)
RISK_HIGH_THRESHOLD <- 60              # Above this = high risk (red)

# ============================================================================
# UI LAYOUT CONSTANTS
# ============================================================================

# Box and panel heights (explicit CSS strings for clarity)
UI_BOX_HEIGHT_DEFAULT <- "400px"       # Standard box height for UI elements
UI_BOX_HEIGHT_LARGE <- "500px"         # Large box height for detailed views
UI_BOX_HEIGHT_SMALL <- "300px"         # Small box height for compact views

# Panel widths (explicit CSS strings for clarity)
UI_SIDEBAR_WIDTH <- "300px"            # Standard sidebar width
UI_CONTROLBAR_WIDTH <- "300px"         # Standard controlbar width

# Bootstrap grid column widths (numeric, out of 12 columns)
UI_BOX_WIDTH_FULL <- 12                # Full width (100%)
UI_BOX_WIDTH_HALF <- 6                 # Half width (50%)
UI_BOX_WIDTH_THIRD <- 4                # Third width (~33%)
UI_BOX_WIDTH_QUARTER <- 3              # Quarter width (25%)

# Plot dimensions (numeric for plotly/ggplot)
PLOT_HEIGHT_DEFAULT <- 500             # Default plot height
PLOT_WIDTH_DEFAULT <- 800              # Default plot width
PLOT_MARGINS <- c(0, 0, 2, 0)          # Plot margins: bottom, left, top, right

# UI plot height strings (for *Output() widgets and visNetwork)
PLOT_HEIGHT_XS  <- "200px"             # Compact distribution plots
PLOT_HEIGHT_SM  <- "300px"             # Small charts, histograms
PLOT_HEIGHT_MD  <- "400px"             # Standard charts and plots
PLOT_HEIGHT_LG  <- "500px"             # Large visualizations
PLOT_HEIGHT_XL  <- "600px"             # Full network views
PLOT_HEIGHT_XXL <- "700px"             # Main CLD visualization

# ============================================================================
# UI STYLING CONSTANTS
# ============================================================================

# Common module gradient colors (for card headers, icons, etc.)
UI_GRADIENT_PRIMARY <- list(
  start = "#667eea",
  end = "#764ba2"
)

# Import module colors
IMPORT_MODULE_COLORS <- list(
  gradient_start = "#667eea",
  gradient_end = "#764ba2",
  card_border = "#e0e0e0",
  card_hover = "#667eea",
  success_green = "#27ae60"
)

# Modal/Dialog animation delays (milliseconds - for shinyjs::delay)
MODAL_ANIMATION_DELAY_MS <- 100        # Delay before modal content shows (100ms)
MODAL_FADE_DURATION_MS <- 300          # Modal fade in/out duration (300ms)

# Spinner/Loading styles
SPINNER_BORDER_RADIUS <- "8px"
SPINNER_PADDING <- "15px"
SPINNER_MARGIN_TOP <- "10px"

# Reusable inline CSS style strings
CSS_TEXT_MUTED        <- "color: #666;"
CSS_TEXT_PRIMARY      <- "color: #007bff;"
CSS_TEXT_SUCCESS      <- "color: #28a745;"
CSS_LABEL_BOLD        <- "font-weight: bold; margin-bottom: 3px;"
CSS_LABEL_SEMIBOLD    <- "font-weight: 600; margin-bottom: 10px; display: block;"
CSS_META_ROW          <- "margin-bottom: 8px; font-size: 13px;"
CSS_HINT_TEXT         <- "font-size: 12px; color: #666;"

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
# AUTO-SAVE CONSTANTS
# ============================================================================

# ADAPTIVE DEBOUNCING - Adjusts save delay based on editing patterns
# During rapid editing (e.g., building a model), use longer debounce for performance
# During casual editing (e.g., tweaking a few elements), use shorter debounce for safety

# Debounce delays (milliseconds)
AUTOSAVE_DEBOUNCE_RAPID_MS <- 5000    # 5 seconds during rapid/active editing
AUTOSAVE_DEBOUNCE_CASUAL_MS <- 2000   # 2 seconds during casual/slow editing

# Pattern detection thresholds
AUTOSAVE_RAPID_THRESHOLD <- 3         # 3+ changes within time window = "rapid editing"
AUTOSAVE_PATTERN_WINDOW_SEC <- 10     # Time window for detecting rapid editing (seconds)

# Auto-save recovery window (hours)
# Maximum age of recovery file to offer for restoration
AUTOSAVE_RECOVERY_WINDOW_HOURS <- 24  # 24 hours

# Auto-save indicator update interval (milliseconds)
# How often to refresh the "last saved X seconds ago" display
AUTOSAVE_INDICATOR_UPDATE_MS <- 10000  # 10 seconds

# ============================================================================
# UI FILTER DEBOUNCING
# ============================================================================
# Debounce delays for UI filter controls to reduce unnecessary re-renders

# Slider input debounce (e.g., year ranges, window sizes)
UI_SLIDER_DEBOUNCE_MS <- 300          # 300ms - fast enough for responsive feel

# Text/search input debounce
UI_TEXT_INPUT_DEBOUNCE_MS <- 400      # 400ms - wait for user to stop typing

# Select input debounce (dropdowns)
UI_SELECT_DEBOUNCE_MS <- 200          # 200ms - minimal delay for selections

# Network visualization update debounce
UI_NETWORK_UPDATE_DEBOUNCE_MS <- 500  # 500ms - expensive network redraws

# ============================================================================
# MARINESABRES PROJECT-SPECIFIC CONSTANTS
# ============================================================================

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
# DTU DYNAMICS ANALYSIS CONSTANTS
# ============================================================================

DYNAMICS_MAX_BOOLEAN_NODES    <- 25L     # Hard limit for exhaustive Boolean analysis
DYNAMICS_DEFAULT_ITER         <- 500L    # Default simulation iterations
DYNAMICS_MIN_ITER             <- 50L     # Minimum iterations
DYNAMICS_MAX_ITER             <- 5000L   # Maximum iterations
DYNAMICS_DEFAULT_GREED        <- 100L    # Default Monte Carlo simulations
DYNAMICS_MAX_GREED            <- 2000L   # Maximum Monte Carlo simulations
DYNAMICS_DEFAULT_RF_TREES     <- 1000L   # Default random forest trees
DYNAMICS_DIVERGENCE_THRESHOLD <- 1e10    # Value above which simulation is considered diverged

# Weight mapping: polarity + strength -> numeric weight
DYNAMICS_WEIGHT_MAP <- list(
  "+strong"  =  1.00,
  "+medium"  =  0.50,
  "+weak"    =  0.25,
  "-strong"  = -1.00,
  "-medium"  = -0.50,
  "-weak"    = -0.25
)

# ============================================================================
# END OF CONSTANTS
# ============================================================================

message("Marine SES constants loaded successfully")