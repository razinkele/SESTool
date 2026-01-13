# Marine SES Network Utility Functions
# Helper functions for common operations

# Load constants (should be sourced by main app.R first)
# This is a fallback for standalone testing
if (!exists("GROUP_COLORS")) {
  if (file.exists("constants.R")) {
    source("constants.R")
  } else {
    stop("constants.R not found. Please ensure it is in the working directory.")
  }
}

#' Convert Semi-Quantitative Strength to Numerical Value
#'
#' Converts text-based strength descriptors (weak, medium, strong) to numerical
#' values and applies sign based on a separate direction indicator (+/-).
#'
#' @param strength_text Character vector of strength descriptors (weak/medium/strong)
#' @param direction_indicator Character vector of +/- indicators (optional)
#' @param strict_mode Logical; if TRUE, throws error for unrecognized values instead of warning and defaulting to 3.0 (default: FALSE)
#'
#' @return Numeric vector of strength values (positive or negative)
#'
#' @details
#' If strength_text is already numeric, it will be returned as-is.
#' If direction_indicator is provided, signs are applied based on +/- symbols.
#'
#' When strict_mode is FALSE (default), unrecognized values trigger a warning and default to 3.0 (medium).
#' When strict_mode is TRUE, unrecognized values throw an error, ensuring data quality validation.
#'
#' Mapping:
#' - "very weak" or "very low" -> 1.0
#' - "weak" or "low" -> 1.5
#' - "medium" or "moderate" -> 3.0
#' - "strong" or "high" -> 4.5
#' - "very strong" or "very high" -> 5.0
#'
#' @examples
#' \dontrun{
#' convert_strength_to_numeric(c("weak", "strong", "medium"), c("+", "-", "+"))
#' # Returns: c(1.5, -4.5, 3.0)
#'
#' # Strict mode example
#' convert_strength_to_numeric(c("weak", "invalid"), strict_mode = TRUE)
#' # Error: Unrecognized strength value 'invalid'
#' }
#'
#' @export
convert_strength_to_numeric <- function(strength_text, direction_indicator = NULL, strict_mode = FALSE) {
  if (is.null(strength_text)) {
    return(NULL)
  }

  # If already numeric, just apply sign if needed
  if (is.numeric(strength_text)) {
    if (!is.null(direction_indicator)) {
      signs <- ifelse(grepl("-", direction_indicator, fixed = TRUE), -1, 1)
      return(strength_text * signs)
    }
    return(strength_text)
  }

  # Convert to lowercase and trim whitespace
  strength_lower <- tolower(trimws(as.character(strength_text)))

  # Initialize result vector
  result <- numeric(length(strength_text))

  # Map text to numbers
  for (i in seq_along(strength_lower)) {
    val <- strength_lower[i]

    # Skip if NA
    if (is.na(val) || val == "") {
      result[i] <- NA
      next
    }

    # Try to convert to numeric first (in case it's already a number as text)
    num_val <- suppressWarnings(as.numeric(val))
    if (!is.na(num_val)) {
      result[i] <- num_val
      next
    }

    # Map semi-quantitative values
    if (grepl("very.*weak|very.*low", val)) {
      result[i] <- 1.0
    } else if (grepl("very.*strong|very.*high", val)) {
      result[i] <- 5.0
    } else if (grepl("weak|low", val)) {
      result[i] <- 1.5
    } else if (grepl("strong|high", val)) {
      result[i] <- 4.5
    } else if (grepl("medium|moderate|mod", val)) {
      result[i] <- 3.0
    } else {
      # Handle unrecognized values based on strict_mode
      msg <- sprintf("Unrecognized strength value '%s'", val)
      if (strict_mode) {
        stop(msg, ". Use strict_mode=FALSE to default to medium (3.0)")
      } else {
        warning(paste(msg, ", defaulting to medium (3.0)"))
        result[i] <- 3.0
      }
    }
  }

  # Apply sign based on direction indicator
  if (!is.null(direction_indicator)) {
    signs <- ifelse(grepl("-", as.character(direction_indicator), fixed = TRUE), -1, 1)
    result <- result * signs
  }

  return(result)
}

#' Get Node Colors from Groups
#'
#' Maps node group names to their corresponding colors using the centralized
#' GROUP_COLORS constant. Returns default color for unknown groups.
#'
#' @param groups Character vector of group names
#'
#' @return Character vector of hex color codes
#'
#' @examples
#' \dontrun{
#' groups <- c("Activities", "Pressures", "Unknown")
#' colors <- get_node_colors(groups)
#' # Returns: c("#FF9999", "#99FF99", "#95A5A6")
#' }
#'
#' @export
get_node_colors <- function(groups) {
  vapply(groups, function(grp) {
    if (grp %in% names(GROUP_COLORS)) GROUP_COLORS[[grp]] else DEFAULT_GROUP_COLOR
  }, character(1), USE.NAMES = FALSE)
}

#' Get Node Shapes from Groups
#'
#' Maps node group names to their corresponding visNetwork shapes using the
#' centralized GROUP_SHAPES constant. Returns default shape for unknown groups.
#'
#' @param groups Character vector of group names
#'
#' @return Character vector of shape names
#'
#' @examples
#' \dontrun{
#' groups <- c("Activities", "Pressures", "Unknown")
#' shapes <- get_node_shapes(groups)
#' # Returns: c("diamond", "square", "ellipse")
#' }
#'
#' @export
get_node_shapes <- function(groups) {
  vapply(groups, function(grp) {
    if (grp %in% names(GROUP_SHAPES)) GROUP_SHAPES[[grp]] else DEFAULT_GROUP_SHAPE
  }, character(1), USE.NAMES = FALSE)
}

#' Ensure Required Edge Attributes
#'
#' Adds default edge attributes (weight, strength, confidence) to a graph
#' if they are missing. Uses constants for consistent initialization.
#'
#' @param g An igraph object
#' @param weight_range Numeric vector of length 2: c(min, max) for weight
#' @param strength_range Numeric vector of length 2: c(min, max) for strength
#' @param confidence_range Numeric vector of length 2: c(min, max) for confidence
#' @param use_marine_ranges Logical; if TRUE, uses MARINE_* constants instead of generic EDGE_* constants
#' @param use_random Logical; if TRUE, uses random values in range; if FALSE, uses minimum values (for loaded data)
#'
#' @return Modified igraph object with guaranteed edge attributes
#'
#' @examples
#' \dontrun{
#' g <- make_ring(5, directed = TRUE)
#' g <- ensure_edge_attributes(g)  # Adds default attributes
#' }
#'
#' @export
ensure_edge_attributes <- function(g,
                                  weight_range = c(EDGE_WEIGHT_MIN, EDGE_WEIGHT_MAX),
                                  strength_range = c(EDGE_STRENGTH_MIN, EDGE_STRENGTH_MAX),
                                  confidence_range = c(EDGE_CONFIDENCE_MIN, EDGE_CONFIDENCE_MAX),
                                  use_marine_ranges = FALSE,
                                  use_random = TRUE) {
  if (!inherits(g, "igraph")) {
    stop("Input 'g' must be an igraph object")
  }

  # Use marine-specific ranges if requested
  if (use_marine_ranges) {
    weight_range <- c(MARINE_WEIGHT_MIN, MARINE_WEIGHT_MAX)
    strength_range <- c(MARINE_STRENGTH_MIN, MARINE_STRENGTH_MAX)
  }

  # Add weight if missing
  if (!"weight" %in% edge_attr_names(g)) {
    if (use_random) {
      E(g)$weight <- runif(ecount(g), weight_range[1], weight_range[2])
    } else {
      E(g)$weight <- rep(weight_range[1], ecount(g))
    }
  }

  # Add strength if missing
  if (!"strength" %in% edge_attr_names(g)) {
    if (use_random) {
      E(g)$strength <- runif(ecount(g), strength_range[1], strength_range[2])
    } else {
      E(g)$strength <- rep(weight_range[1], ecount(g))  # Use weight min as default
    }
  }

  # Add confidence if missing (weighted toward medium values)
  if (!"confidence" %in% edge_attr_names(g)) {
    if (use_random) {
      E(g)$confidence <- sample(confidence_range[1]:confidence_range[2],
                               ecount(g), replace = TRUE,
                               prob = c(0.1, 0.2, 0.3, 0.3, 0.1))
    } else {
      E(g)$confidence <- rep(3, ecount(g))  # Default to medium confidence
    }
  }

  return(g)
}

#' Validate igraph Object
#'
#' Validates that an input is a valid igraph object and optionally checks
#' additional constraints like minimum nodes or directedness.
#'
#' @param g Object to validate
#' @param min_nodes Minimum number of nodes required (default: 0)
#' @param max_nodes Maximum number of nodes allowed (default: Inf)
#' @param require_directed Logical; if TRUE, graph must be directed
#' @param allow_empty_graph Logical; if FALSE, graph must have at least 1 edge
#'
#' @return Invisible TRUE if validation passes, otherwise stops with error
#'
#' @examples
#' \dontrun{
#' g <- make_ring(5, directed = TRUE)
#' validate_igraph(g, min_nodes = 3, require_directed = TRUE)  # Passes
#' validate_igraph(g, min_nodes = 10)  # Stops with error
#' }
#'
#' @export
validate_igraph <- function(g,
                           min_nodes = 0,
                           max_nodes = Inf,
                           require_directed = FALSE,
                           allow_empty_graph = TRUE) {
  # Check if igraph
  if (!inherits(g, "igraph")) {
    stop("Input 'g' must be an igraph object")
  }

  # Check node count
  if (vcount(g) < min_nodes) {
    stop(sprintf("Graph must have at least %d nodes (has %d)", min_nodes, vcount(g)))
  }

  if (vcount(g) > max_nodes) {
    stop(sprintf("Graph cannot have more than %d nodes (has %d)", max_nodes, vcount(g)))
  }

  # Check directedness
  if (require_directed && !is_directed(g)) {
    stop("Graph must be directed")
  }

  # Check if empty
  if (!allow_empty_graph && ecount(g) == 0) {
    stop("Graph must have at least 1 edge")
  }

  invisible(TRUE)
}

#' Assign Default Groups to Nodes
#'
#' Assigns marine SES category groups to nodes that don't have a group attribute.
#' Uses seeded random assignment for reproducibility.
#'
#' @param g An igraph object
#' @param seed Random seed for reproducible assignment (default: DEFAULT_RANDOM_SEED)
#'
#' @return Character vector of group assignments (length = vcount(g))
#'
#' @examples
#' \dontrun{
#' g <- make_ring(10, directed = TRUE)
#' groups <- assign_default_groups(g)
#' V(g)$group <- groups
#' }
#'
#' @export
assign_default_groups <- function(g, seed = DEFAULT_RANDOM_SEED) {
  if (!is.null(V(g)$group)) {
    return(V(g)$group)
  }

  set.seed(seed)
  sample(MARINE_SES_CATEGORIES, vcount(g), replace = TRUE)
}

#' Safe Scaling Function with Zero-Variance Protection
#'
#' Wrapper around base::scale() that handles edge cases:
#' - Single-value vectors (returns 0)
#' - Zero-variance vectors (returns vector of 0s)
#' - Normal cases (applies standard scaling)
#'
#' This prevents NaN values that occur when scale() encounters zero variance.
#'
#' @param x Numeric vector to scale
#'
#' @return Numeric vector of scaled values (mean=0, sd=1), or zeros if variance is 0
#'
#' @details
#' The standard scale() function produces NaN when all values are equal (zero variance).
#' This causes crashes in composite score calculations when all nodes have identical
#' centrality values. safe_scale() returns 0 for all elements in such cases, which
#' correctly represents "no variance in importance" for downstream analyses.
#'
#' @examples
#' \dontrun{
#' # Normal case
#' safe_scale(c(1, 2, 3, 4, 5))  # Returns scaled values
#'
#' # Zero variance case (would crash with regular scale())
#' safe_scale(c(3, 3, 3, 3))     # Returns c(0, 0, 0, 0)
#'
#' # Single value case
#' safe_scale(5)                 # Returns 0
#' }
#'
#' @export
safe_scale <- function(x) {
  # Handle single value
  if (length(x) == 1) return(0)

  # Handle zero variance
  if (sd(x, na.rm = TRUE) == 0) {
    return(rep(0, length(x)))
  }

  # Normal scaling
  as.numeric(scale(x))
}

# ============================================================================
# END OF UTILITY FUNCTIONS
# ============================================================================

message("Marine SES Utility Functions loaded successfully")
message("Available functions: convert_strength_to_numeric, get_node_colors, get_node_shapes, ensure_edge_attributes, validate_igraph, assign_default_groups, safe_scale")
