# helpers.R
# Test utilities and helper functions for testing

library(shiny)
library(igraph)

#' Create mock ISA data for testing
#'
#' @return A list containing mock ISA data structure
create_mock_isa_data <- function() {
  list(
    drivers = data.frame(
      ID = c("D1", "D2", "D3"),
      Name = c("Population Growth", "Economic Development", "Climate Change"),
      Indicator = c("Population change rate", "GDP growth", "Temperature increase"),
      Description = c("Increasing coastal population", "Growing blue economy", "Rising sea temperatures"),
      stringsAsFactors = FALSE
    ),
    activities = data.frame(
      ID = c("A1", "A2", "A3"),
      Name = c("Commercial Fishing", "Tourism", "Aquaculture"),
      Indicator = c("Fish catch volume", "Tourist numbers", "Farm production"),
      Description = c("Industrial fishing", "Coastal tourism", "Fish farming"),
      stringsAsFactors = FALSE
    ),
    pressures = data.frame(
      ID = c("P1", "P2", "P3"),
      Name = c("Overfishing", "Pollution", "Habitat Destruction"),
      Indicator = c("Fishing effort", "Pollutant levels", "Habitat loss"),
      Type = c("EnMP", "EnMP", "EnMP"),
      stringsAsFactors = FALSE
    ),
    marine_processes = data.frame(
      ID = c("MP1", "MP2"),
      Name = c("Fish Stock Decline", "Habitat Degradation"),
      Indicator = c("Stock biomass", "Habitat quality index"),
      stringsAsFactors = FALSE
    ),
    ecosystem_services = data.frame(
      ID = c("ES1", "ES2"),
      Name = c("Fish Provision", "Recreation"),
      Indicator = c("Fish availability", "Recreation opportunities"),
      Category = c("Provisioning", "Cultural"),
      stringsAsFactors = FALSE
    ),
    goods_benefits = data.frame(
      ID = c("GB1", "GB2"),
      Name = c("Food Security", "Coastal Livelihoods"),
      Indicator = c("Fish consumption", "Employment rate"),
      stringsAsFactors = FALSE
    )
  )
}

#' Create mock project data for testing
#'
#' @param include_isa Logical, whether to include ISA data
#' @param include_cld Logical, whether to include CLD data
#' @return A list containing mock project data structure
create_mock_project_data <- function(include_isa = TRUE, include_cld = FALSE) {
  project <- init_session_data()

  # Add metadata
  project$data$metadata <- list(
    da_site = "Tuscan Archipelago",
    focal_issue = "Sustainable fisheries management",
    description = "Testing the SES framework for marine management"
  )

  # Add PIMS data
  project$data$pims <- list(
    stakeholders = data.frame(
      ID = c("ST1", "ST2", "ST3"),
      Name = c("Local Fishers", "Environmental NGO", "Coastal Authority"),
      Type = c("Extractors", "Influencers", "Regulators"),
      Interest = c("High", "High", "Medium"),
      stringsAsFactors = FALSE
    )
  )

  # Add ISA data if requested
  if (include_isa) {
    project$data$isa_data <- create_mock_isa_data()
  }

  # Add CLD data if requested
  if (include_cld) {
    project$data$cld <- create_mock_cld_data()
  }

  return(project)
}

#' Create mock CLD (Causal Loop Diagram) data for testing
#'
#' @return A list containing nodes and edges for a CLD
create_mock_cld_data <- function() {
  nodes <- data.frame(
    id = c("N1", "N2", "N3", "N4", "N5"),
    label = c("Fishing Effort", "Fish Stock", "Fish Catch", "Fisher Income", "Investment"),
    type = c("Activity", "State", "Pressure", "Benefit", "Driver"),
    color = c("#5abc67", "#bce2ee", "#fec05a", "#fff1a2", "#776db3"),
    stringsAsFactors = FALSE
  )

  edges <- data.frame(
    from = c("N1", "N2", "N3", "N4", "N5"),
    to = c("N3", "N3", "N4", "N5", "N1"),
    link_type = c("positive", "positive", "positive", "positive", "positive"),
    strength = c("strong", "medium", "strong", "medium", "weak"),
    stringsAsFactors = FALSE
  )

  list(nodes = nodes, edges = edges)
}

#' Create a mock igraph network for testing
#'
#' @param n_nodes Number of nodes
#' @param n_edges Number of edges
#' @param directed Logical, whether graph is directed
#' @return An igraph object
create_mock_network <- function(n_nodes = 10, n_edges = 15, directed = TRUE) {
  # Create random graph
  g <- erdos.renyi.game(n_nodes, n_edges, type = "gnm", directed = directed)

  # Add node attributes
  V(g)$name <- paste0("Node_", 1:n_nodes)
  V(g)$type <- sample(c("Driver", "Activity", "Pressure", "State"), n_nodes, replace = TRUE)

  # Add edge attributes
  E(g)$link_type <- sample(c("positive", "negative"), n_edges, replace = TRUE)
  E(g)$strength <- sample(c("strong", "medium", "weak"), n_edges, replace = TRUE)

  return(g)
}

#' Create a mock adjacency matrix for testing
#'
#' @param row_names Character vector of row names
#' @param col_names Character vector of column names
#' @param fill_percent Percentage of cells to fill (0-100)
#' @return A matrix with random connection values
create_mock_adjacency_matrix <- function(row_names, col_names, fill_percent = 30) {
  n_rows <- length(row_names)
  n_cols <- length(col_names)

  # Initialize empty matrix
  adj_matrix <- matrix("", nrow = n_rows, ncol = n_cols)
  rownames(adj_matrix) <- row_names
  colnames(adj_matrix) <- col_names

  # Fill random cells
  n_cells <- n_rows * n_cols
  n_fill <- round(n_cells * fill_percent / 100)

  if (n_fill > 0) {
    fill_indices <- sample(1:n_cells, n_fill)

    # Generate random connection values
    polarities <- sample(c("+", "-"), n_fill, replace = TRUE)
    strengths <- sample(c("strong", "medium", "weak"), n_fill, replace = TRUE)
    values <- paste0(polarities, strengths)

    adj_matrix[fill_indices] <- values
  }

  return(adj_matrix)
}

#' Expect a Shiny tag or tag list
#'
#' @param object Object to test
expect_shiny_tag <- function(object) {
  expect_true(inherits(object, "shiny.tag") ||
              inherits(object, "shiny.tag.list") ||
              inherits(object, "html"))
}

#' Expect valid network structure
#'
#' @param network Network object to test
expect_valid_network <- function(network) {
  expect_true(is.igraph(network) || is.tbl_graph(network))

  if (is.igraph(network)) {
    expect_true(vcount(network) > 0)
  }
}

#' Expect valid project data structure
#'
#' @param project Project data object to test
expect_valid_project_data <- function(project) {
  expect_type(project, "list")
  expect_true("project_id" %in% names(project))
  expect_true("data" %in% names(project))
  expect_true(validate_project_structure(project))
}

#' Create a temporary test file
#'
#' @param content Content to write to file
#' @param ext File extension (default: ".txt")
#' @return Path to temporary file
create_temp_test_file <- function(content, ext = ".txt") {
  temp_file <- tempfile(fileext = ext)
  writeLines(content, temp_file)
  return(temp_file)
}

#' Mock Shiny session for testing
#'
#' @return A mock session object
MockShinySession <- R6::R6Class(
  "MockShinySession",
  public = list(
    ns = NULL,
    input = NULL,
    output = NULL,
    clientData = NULL,

    initialize = function() {
      self$ns <- NS("test")
      self$input <- list()
      self$output <- list()
      self$clientData <- list()
    },

    sendCustomMessage = function(type, message) {
      # Mock implementation
      invisible(NULL)
    },

    sendInputMessage = function(inputId, message) {
      # Mock implementation
      invisible(NULL)
    }
  )
)

#' Clean up test files
#'
#' @param file_paths Character vector of file paths to remove
cleanup_test_files <- function(file_paths) {
  for (file_path in file_paths) {
    if (file.exists(file_path)) {
      unlink(file_path)
    }
  }
}

#' Compare data frames ignoring row order
#'
#' @param df1 First data frame
#' @param df2 Second data frame
#' @return Logical indicating if data frames are equal
compare_dfs_unordered <- function(df1, df2) {
  if (nrow(df1) != nrow(df2)) return(FALSE)
  if (ncol(df1) != ncol(df2)) return(FALSE)
  if (!all(names(df1) %in% names(df2))) return(FALSE)

  # Sort both data frames by all columns
  df1_sorted <- df1[do.call(order, df1), ]
  df2_sorted <- df2[do.call(order, df2), ]

  # Compare
  all.equal(df1_sorted, df2_sorted, check.attributes = FALSE)
}
