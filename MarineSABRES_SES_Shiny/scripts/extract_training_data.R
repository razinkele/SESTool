# ==============================================================================
# Extract Training Data from DA Templates for ML Model
# ==============================================================================
# This script extracts training data from Demonstration Area (DA) templates
# for training the Deep Learning Connection Predictor model.
#
# Output: data/ml_training_data.rds containing:
#   - positive_examples: Existing connections from templates
#   - negative_examples: Random non-connected element pairs
#   - train_set: All templates (70% stratified split)
#   - val_set: All templates (15% stratified split)
#   - test_set: All templates (15% stratified split)
# ==============================================================================

library(jsonlite)
library(dplyr)
library(tidyr)
library(purrr)
library(igraph)

# Source ML feature modules (Phase 2)
if (file.exists("functions/network_analysis.R")) {
  source("functions/network_analysis.R")
}
if (file.exists("functions/ml_graph_features.R")) {
  source("functions/ml_graph_features.R")
}

# Set working directory to project root
# If running from scripts/ directory, go up one level
if (basename(getwd()) == "scripts") {
  setwd("..")
}

# Verify we're in the right directory (should have data/ folder)
if (!dir.exists("data")) {
  stop("Error: 'data' directory not found. Please run this script from the project root.")
}

cat(sprintf("Working directory: %s\n\n", getwd()))

# Constants
DATA_DIR <- "data"
OUTPUT_FILE <- file.path(DATA_DIR, "ml_training_data.rds")
SEED <- 42  # For reproducibility

# DAPSI(W)R(M) type normalization mapping
TYPE_MAPPING <- list(
  "drivers" = "Drivers",
  "activities" = "Activities",
  "pressures" = "Pressures",
  "enmp" = "Pressures",
  "marine_processes" = "Marine Processes & Functioning",
  "states" = "Marine Processes & Functioning",
  "ecosystem_services" = "Ecosystem Services",
  "impacts" = "Ecosystem Services",
  "goods_benefits" = "Goods & Benefits",
  "welfare" = "Goods & Benefits",
  "responses" = "Responses"
)

# ==============================================================================
# Helper Functions
# ==============================================================================

#' Normalize DAPSI(W)R(M) type name
normalize_type <- function(type_name) {
  type_lower <- tolower(gsub("_", "", gsub(" ", "", type_name)))

  # Try exact match first
  if (type_lower %in% names(TYPE_MAPPING)) {
    return(TYPE_MAPPING[[type_lower]])
  }

  # Fuzzy matching
  if (grepl("driver", type_lower)) return("Drivers")
  if (grepl("activit", type_lower)) return("Activities")
  if (grepl("pressure|enmp", type_lower)) return("Pressures")
  if (grepl("marine.*process|state|mpf", type_lower)) return("Marine Processes & Functioning")
  if (grepl("ecosystem.*service|impact", type_lower)) return("Ecosystem Services")
  if (grepl("goods|benefit|welfare", type_lower)) return("Goods & Benefits")
  if (grepl("response|measure", type_lower)) return("Responses")

  # Return original if no match
  return(type_name)
}

#' Parse a single JSON template file
parse_template <- function(json_file) {
  cat(sprintf("Parsing template: %s\n", basename(json_file)))

  # Read JSON
  data <- fromJSON(json_file, simplifyVector = FALSE)

  # Extract template metadata
  template_name <- data$template_name %||% basename(json_file)
  regional_context <- data$regional_context %||% list()

  # Determine structure format
  if ("dapsiwrm_framework" %in% names(data)) {
    framework <- data$dapsiwrm_framework
  } else if ("elements" %in% names(data)) {
    framework <- data$elements
  } else {
    stop(sprintf("Unknown template structure in %s", json_file))
  }

  # Extract elements
  elements_list <- list()
  for (type_key in names(framework)) {
    type_normalized <- normalize_type(type_key)
    elements <- framework[[type_key]]

    if (length(elements) > 0) {
      for (elem in elements) {
        elements_list[[length(elements_list) + 1]] <- list(
          id = elem$id %||% paste0(substr(type_normalized, 1, 1), "_", length(elements_list) + 1),
          name = elem$name %||% "",
          type = type_normalized,
          description = elem$description %||% "",
          template = template_name,
          regional_sea = regional_context$region %||% "Unknown",
          ecosystem_types = paste(regional_context$ecosystem_types %||% "Unknown", collapse = ";"),
          main_issues = paste(regional_context$main_issues %||% "Unknown", collapse = ";")
        )
      }
    }
  }

  elements_df <- bind_rows(elements_list)

  # Extract connections
  connections_list <- list()
  if ("connections" %in% names(data) && length(data$connections) > 0) {
    for (conn in data$connections) {
      # Normalize connection types
      from_type <- normalize_type(conn$from_type %||% "")
      to_type <- normalize_type(conn$to_type %||% "")

      connections_list[[length(connections_list) + 1]] <- list(
        from_id = conn$from_id %||% "",
        from_type = from_type,
        to_id = conn$to_id %||% "",
        to_type = to_type,
        polarity = conn$polarity %||% "+",
        strength = conn$strength %||% "medium",
        confidence = as.numeric(conn$confidence %||% 3),
        description = conn$description %||% "",
        template = template_name
      )
    }
  }

  connections_df <- if (length(connections_list) > 0) {
    bind_rows(connections_list)
  } else {
    data.frame()
  }

  cat(sprintf("  - Elements: %d, Connections: %d\n", nrow(elements_df), nrow(connections_df)))

  list(
    elements = elements_df,
    connections = connections_df,
    template_name = template_name,
    regional_context = regional_context
  )
}

#' Build igraph from template (Phase 2 - Graph Features)
build_template_graph <- function(elements_df, connections_df) {
  # Convert elements to nodes format
  nodes <- elements_df %>%
    transmute(
      id = id,
      label = name,
      group = type
    )

  # Convert connections to edges format
  if (nrow(connections_df) == 0) {
    # No connections: create graph with nodes only
    edges <- data.frame(
      from = character(0),
      to = character(0),
      
    )
  } else {
    edges <- connections_df %>%
      transmute(
        from = from_id,
        to = to_id,
        polarity = polarity
      )
  }

  # Build graph using network_analysis function
  tryCatch({
    if (exists("create_igraph_from_data")) {
      create_igraph_from_data(nodes, edges)
    } else {
      NULL
    }
  }, error = function(e) {
    warning(sprintf("Failed to build graph: %s", e$message))
    NULL
  })
}

#' Create positive training examples from connections
create_positive_examples <- function(parsed_templates) {
  positive_examples <- list()

  for (template in parsed_templates) {
    if (nrow(template$connections) == 0) next

    elements_df <- template$elements
    connections_df <- template$connections

    for (i in 1:nrow(connections_df)) {
      conn <- connections_df[i, ]

      # Find source and target elements
      source_elem <- elements_df %>% filter(id == conn$from_id)
      target_elem <- elements_df %>% filter(id == conn$to_id)

      if (nrow(source_elem) == 0 || nrow(target_elem) == 0) next

      positive_examples[[length(positive_examples) + 1]] <- list(
        source_id = source_elem$id[1],
        source_name = source_elem$name[1],
        source_type = source_elem$type[1],
        target_id = target_elem$id[1],
        target_name = target_elem$name[1],
        target_type = target_elem$type[1],
        connection_exists = 1,  # Label: connection exists
        polarity = conn$polarity,
        strength = conn$strength,
        confidence = conn$confidence,
        regional_sea = source_elem$regional_sea[1],
        ecosystem_types = source_elem$ecosystem_types[1],
        main_issues = source_elem$main_issues[1],
        template = conn$template
      )
    }
  }

  bind_rows(positive_examples)
}

#' Generate negative training examples (non-connected pairs)
create_negative_examples <- function(parsed_templates, n_negatives_per_positive = 2) {
  negative_examples <- list()

  for (template in parsed_templates) {
    elements_df <- template$elements
    connections_df <- template$connections

    if (nrow(elements_df) < 2) next

    # Get all existing connection pairs
    existing_pairs <- if (nrow(connections_df) > 0) {
      paste(connections_df$from_id, connections_df$to_id, sep = "->")
    } else {
      character(0)
    }

    # Number of negative examples to generate
    n_positive <- max(1, nrow(connections_df))
    n_negatives <- n_positive * n_negatives_per_positive

    # Generate random non-connected pairs
    attempts <- 0
    max_attempts <- n_negatives * 10

    while (length(negative_examples) < n_negatives && attempts < max_attempts) {
      attempts <- attempts + 1

      # Randomly sample two different elements
      idx <- sample(1:nrow(elements_df), 2, replace = FALSE)
      source_elem <- elements_df[idx[1], ]
      target_elem <- elements_df[idx[2], ]

      # Check if this pair already has a connection
      pair_key <- paste(source_elem$id, target_elem$id, sep = "->")
      if (pair_key %in% existing_pairs) next

      # Add negative example
      negative_examples[[length(negative_examples) + 1]] <- list(
        source_id = source_elem$id,
        source_name = source_elem$name,
        source_type = source_elem$type,
        target_id = target_elem$id,
        target_name = target_elem$name,
        target_type = target_elem$type,
        connection_exists = 0,  # Label: no connection
        polarity = NA,
        strength = NA,
        confidence = NA,
        regional_sea = source_elem$regional_sea,
        ecosystem_types = source_elem$ecosystem_types,
        main_issues = source_elem$main_issues,
        template = template$template_name
      )
    }
  }

  bind_rows(negative_examples)
}

# ==============================================================================
# Main Extraction Process
# ==============================================================================

cat("=================================================================\n")
cat("  ML Training Data Extraction from DA Templates\n")
cat("=================================================================\n\n")

set.seed(SEED)

# 1. Find all JSON template files
json_files <- list.files(DATA_DIR, pattern = "\\.json$", full.names = TRUE)
# Exclude backup files
json_files <- json_files[!grepl("backup", json_files, ignore.case = TRUE)]

cat(sprintf("Found %d JSON template files:\n", length(json_files)))
for (f in json_files) {
  cat(sprintf("  - %s\n", basename(f)))
}
cat("\n")

# 2. Parse all templates
parsed_templates <- list()
for (json_file in json_files) {
  tryCatch({
    parsed <- parse_template(json_file)
    parsed_templates[[length(parsed_templates) + 1]] <- parsed
  }, error = function(e) {
    cat(sprintf("ERROR parsing %s: %s\n", basename(json_file), e$message))
  })
}

cat(sprintf("\nSuccessfully parsed %d templates\n\n", length(parsed_templates)))

# 3. Create positive examples from existing connections
cat("Creating positive examples from connections...\n")
positive_examples <- create_positive_examples(parsed_templates)
cat(sprintf("  Generated %d positive examples\n\n", nrow(positive_examples)))

# 4. Generate negative examples
cat("Generating negative examples (non-connected pairs)...\n")
negative_examples <- create_negative_examples(parsed_templates, n_negatives_per_positive = 2)
cat(sprintf("  Generated %d negative examples\n\n", nrow(negative_examples)))

# 5. Combine positive and negative examples
all_examples <- bind_rows(positive_examples, negative_examples)
cat(sprintf("Total examples: %d (Positive: %d, Negative: %d)\n",
            nrow(all_examples),
            sum(all_examples$connection_exists == 1),
            sum(all_examples$connection_exists == 0)))
cat(sprintf("Positive:Negative ratio = 1:%.2f\n\n",
            sum(all_examples$connection_exists == 0) / sum(all_examples$connection_exists == 1)))

# 6. Split into train/validation/test sets
cat("Splitting data into train/val/test sets...\n")
cat("  Strategy: Stratified split across ALL templates (70% train, 15% val, 15% test)\n")
cat("  This ensures model learns from diverse examples and generalizes better\n\n")

# Use ALL templates for training (not just Caribbean)
# This will dramatically improve generalization to unseen templates

set.seed(SEED)

# Perform stratified split by template to ensure each split has examples from all templates
train_set <- data.frame()
val_set <- data.frame()
test_set <- data.frame()

for (template_name in unique(all_examples$template)) {
  template_examples <- all_examples %>% filter(template == template_name)
  n_examples <- nrow(template_examples)

  # Calculate split sizes (70/15/15)
  n_train <- floor(0.70 * n_examples)
  n_val <- floor(0.15 * n_examples)
  # Remaining goes to test (handles rounding)

  # Shuffle indices
  shuffled_indices <- sample(1:n_examples)

  # Split indices
  train_indices <- shuffled_indices[1:n_train]
  val_indices <- shuffled_indices[(n_train + 1):(n_train + n_val)]
  test_indices <- shuffled_indices[(n_train + n_val + 1):n_examples]

  # Assign to sets
  train_set <- rbind(train_set, template_examples[train_indices, ])
  val_set <- rbind(val_set, template_examples[val_indices, ])
  test_set <- rbind(test_set, template_examples[test_indices, ])

  cat(sprintf("  %s: %d examples → Train: %d, Val: %d, Test: %d\n",
              template_name, n_examples, length(train_indices),
              length(val_indices), length(test_indices)))
}

cat("\n")
cat(sprintf("  TOTAL Train set (70%% all templates): %d examples\n", nrow(train_set)))
cat(sprintf("    - Positive: %d, Negative: %d\n",
            sum(train_set$connection_exists == 1),
            sum(train_set$connection_exists == 0)))
cat(sprintf("    - Templates: %s\n", paste(unique(train_set$template), collapse = ", ")))

cat(sprintf("  TOTAL Validation set (15%% all templates): %d examples\n", nrow(val_set)))
cat(sprintf("    - Positive: %d, Negative: %d\n",
            sum(val_set$connection_exists == 1),
            sum(val_set$connection_exists == 0)))
cat(sprintf("    - Templates: %s\n", paste(unique(val_set$template), collapse = ", ")))

cat(sprintf("  TOTAL Test set (15%% all templates): %d examples\n", nrow(test_set)))
cat(sprintf("    - Positive: %d, Negative: %d\n",
            sum(test_set$connection_exists == 1),
            sum(test_set$connection_exists == 0)))
cat(sprintf("    - Templates: %s\n", paste(unique(test_set$template), collapse = ", ")))

cat("\n")
cat("✓ Stratified split complete - Model will now train on ALL templates!\n\n")

# Keep test_examples variable for backward compatibility
test_examples <- test_set

# 6.5. Extract Graph Features (Phase 2 - Week 2)
if (exists("extract_graph_features_batch")) {
  cat("=================================================================\n")
  cat("  PHASE 2: Extracting Graph Structural Features\n")
  cat("=================================================================\n\n")

  # Build graphs for each template
  template_graphs <- list()
  for (template in parsed_templates) {
    template_name <- template$template_name
    cat(sprintf("Building graph for template: %s\n", template_name))

    graph <- build_template_graph(template$elements, template$connections)
    template_graphs[[template_name]] <- list(
      graph = graph,
      nodes = template$elements %>%
        transmute(id = id, label = name, group = type)
    )
  }

  cat("\n")

  # Extract graph features for each dataset
  extract_features_for_set <- function(dataset, set_name) {
    cat(sprintf("Extracting graph features for %s set (%d examples)...\n",
                set_name, nrow(dataset)))

    feature_list <- list()

    for (template_name in unique(dataset$template)) {
      template_data <- dataset %>% filter(template == template_name)
      template_info <- template_graphs[[template_name]]

      if (is.null(template_info) || is.null(template_info$graph)) {
        # No graph available: use zero features
        n_examples <- nrow(template_data)
        template_features <- matrix(0, nrow = n_examples, ncol = 8)
      } else {
        # Extract graph features in batch
        template_features <- extract_graph_features_batch(
          source_ids = template_data$source_id,
          target_ids = template_data$target_id,
          graph = template_info$graph,
          nodes = template_info$nodes
        )
      }

      feature_list[[template_name]] <- template_features
    }

    # Combine all features (maintaining order)
    all_features <- do.call(rbind, feature_list)
    rownames(all_features) <- NULL

    cat(sprintf("  → Extracted %d x %d graph feature matrix\n",
                nrow(all_features), ncol(all_features)))

    return(all_features)
  }

  # Extract for all sets
  train_graph_features <- extract_features_for_set(train_set, "train")
  val_graph_features <- extract_features_for_set(val_set, "validation")
  test_graph_features <- extract_features_for_set(test_set, "test")

  cat("\n✓ Graph feature extraction complete!\n\n")
} else {
  cat("NOTICE: Graph feature extraction unavailable (ml_graph_features.R not loaded)\n")
  cat("  Proceeding without graph features...\n\n")
  train_graph_features <- NULL
  val_graph_features <- NULL
  test_graph_features <- NULL
}

# 7. Compile metadata
metadata <- list(
  extraction_date = Sys.time(),
  n_templates = length(parsed_templates),
  template_names = sapply(parsed_templates, function(x) x$template_name),
  n_total_examples = nrow(all_examples),
  n_positive = sum(all_examples$connection_exists == 1),
  n_negative = sum(all_examples$connection_exists == 0),
  n_train = nrow(train_set),
  n_val = nrow(val_set),
  n_test = nrow(test_examples),
  seed = SEED
)

# 8. Save to RDS
cat(sprintf("Saving training data to %s...\n", OUTPUT_FILE))

training_data <- list(
  train = train_set,
  validation = val_set,
  test = test_examples,
  all_examples = all_examples,
  metadata = metadata,
  parsed_templates = parsed_templates,  # Keep for reference
  # Phase 2: Graph features
  train_graph_features = train_graph_features,
  val_graph_features = val_graph_features,
  test_graph_features = test_graph_features
)

saveRDS(training_data, OUTPUT_FILE)

cat(sprintf("✓ Successfully saved training data (%s)\n",
            format(file.info(OUTPUT_FILE)$size, units = "auto")))

# 9. Summary statistics
cat("\n=================================================================\n")
cat("  Data Extraction Summary\n")
cat("=================================================================\n")
cat(sprintf("Total templates parsed: %d\n", metadata$n_templates))
cat(sprintf("Total examples: %d\n", metadata$n_total_examples))
cat(sprintf("  - Train: %d (%.1f%%)\n", metadata$n_train,
            100 * metadata$n_train / metadata$n_total_examples))
cat(sprintf("  - Validation: %d (%.1f%%)\n", metadata$n_val,
            100 * metadata$n_val / metadata$n_total_examples))
cat(sprintf("  - Test: %d (%.1f%%)\n", metadata$n_test,
            100 * metadata$n_test / metadata$n_total_examples))
cat(sprintf("\nClass distribution:\n"))
cat(sprintf("  - Positive (connections exist): %d (%.1f%%)\n",
            metadata$n_positive, 100 * metadata$n_positive / metadata$n_total_examples))
cat(sprintf("  - Negative (no connection): %d (%.1f%%)\n",
            metadata$n_negative, 100 * metadata$n_negative / metadata$n_total_examples))
cat("\n=================================================================\n")
cat("✓ Data extraction complete!\n")
cat("=================================================================\n")
