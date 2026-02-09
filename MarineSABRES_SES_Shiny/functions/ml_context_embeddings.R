# functions/ml_context_embeddings.R
# Context Embedding Module - Phase 2 Enhancement 1
# ==============================================================================
#
# Replaces sparse one-hot context encodings (88 dims) with learned dense
# embeddings (36 dims) that capture correlations between:
# - Regional seas (12 categories → 8-dim embeddings)
# - Ecosystem types (25 categories → 12-dim embeddings)
# - Focal issues (52 categories → 16-dim embeddings)
#
# Benefits:
# - Dimensionality reduction: 88 → 36 dims (59% reduction)
# - Learned representations capture semantic relationships
# - Example: "Baltic + Open Coast + Overfishing" co-occurrence learned
#
# ==============================================================================

library(torch)

# ==============================================================================
# Context Embedding Layer (torch nn_module)
# ==============================================================================

#' Context Embeddings Neural Network Module
#'
#' Learns dense vector representations for regional seas, ecosystems, and issues.
#' Multi-hot encoding supported for ecosystems and issues (elements can have
#' multiple ecosystems/issues, embeddings are averaged).
#'
#' @export
context_embeddings <- nn_module(
  "ContextEmbeddings",

  initialize = function(
    n_seas = 12,
    n_ecosystems = 25,
    n_issues = 52,
    embed_dim_sea = 8,
    embed_dim_eco = 12,
    embed_dim_issue = 16
  ) {
    # Embedding layers
    self$sea_embed <- nn_embedding(n_seas, embed_dim_sea)
    self$eco_embed <- nn_embedding(n_ecosystems, embed_dim_eco)
    self$issue_embed <- nn_embedding(n_issues, embed_dim_issue)

    # Store dimensions for reference
    self$n_seas <- n_seas
    self$n_ecosystems <- n_ecosystems
    self$n_issues <- n_issues
    self$embed_dim_sea <- embed_dim_sea
    self$embed_dim_eco <- embed_dim_eco
    self$embed_dim_issue <- embed_dim_issue
    self$output_dim <- embed_dim_sea + embed_dim_eco + embed_dim_issue  # 36
  },

  forward = function(sea_idx, eco_idx, issue_idx) {
    # Regional sea embedding (single category)
    # nn_embedding returns (batch, seq_len, embed_dim)
    # When seq_len=1, we need to squeeze to get (batch, embed_dim)
    sea_vec <- self$sea_embed(sea_idx)
    if (length(dim(sea_vec)) == 3 && dim(sea_vec)[2] == 1) {
      sea_vec <- sea_vec$squeeze(2)  # (batch, 1, 8) -> (batch, 8)
    }

    # Ecosystem embeddings (multi-hot: average multiple ecosystems)
    eco_vec <- self$eco_embed(eco_idx)
    if (length(dim(eco_vec)) == 3) {
      if (dim(eco_vec)[2] > 1) {
        # Multiple ecosystems: average embeddings
        eco_vec <- eco_vec$mean(dim = 2)  # (batch, n_eco, 12) -> (batch, 12)
      } else {
        # Single ecosystem: squeeze
        eco_vec <- eco_vec$squeeze(2)  # (batch, 1, 12) -> (batch, 12)
      }
    }

    # Issue embeddings (multi-hot: average multiple issues)
    issue_vec <- self$issue_embed(issue_idx)
    if (length(dim(issue_vec)) == 3) {
      if (dim(issue_vec)[2] > 1) {
        # Multiple issues: average embeddings
        issue_vec <- issue_vec$mean(dim = 2)  # (batch, n_issue, 16) -> (batch, 16)
      } else {
        # Single issue: squeeze
        issue_vec <- issue_vec$squeeze(2)  # (batch, 1, 16) -> (batch, 16)
      }
    }

    # Concatenate: 8 + 12 + 16 = 36 dims
    # All vectors should now be (batch, embed_dim)
    return(torch_cat(list(sea_vec, eco_vec, issue_vec), dim = 2))
  }
)

# ==============================================================================
# Context Vocabulary Management
# ==============================================================================

#' Get Context Vocabularies
#'
#' Returns vocabulary mappings for regional seas, ecosystems, and focal issues.
#' Matches the vocabularies defined in ml_feature_engineering.R
#'
#' @return List with regional_seas, ecosystems, focal_issues vectors
#' @export
get_context_vocabularies <- function() {
  list(
    regional_seas = c(REGIONAL_SEA_CHOICES, "Global"),

    ecosystems = c(
      "Coastal", "Shelf", "Oceanic", "Open coast", "Archipelagos",
      "Estuaries", "Coastal lagoons", "Fjards and fjords",
      "Large shallow inlets and bays", "Moderately exposed sandy beaches",
      "Fully marine inlet/strait", "Coral reef", "Mangrove", "Seagrass",
      "Kelp forest", "Rocky shore", "Sandy beach", "Mudflat",
      "Salt marsh", "Deep sea", "Seamount", "Hydrothermal vent",
      "Polar", "Temperate", "Tropical"
    ),

    focal_issues = c(
      "Overfishing", "Bycatch", "Illegal fishing", "Destructive fishing",
      "Aquaculture development", "Coastal development", "Port expansion",
      "Offshore wind energy", "Oil and gas extraction",
      "Marine pollution", "Plastic pollution", "Nutrient pollution",
      "Chemical pollution", "Noise pollution", "Light pollution",
      "Eutrophication", "Harmful algal blooms", "Hypoxia",
      "Ocean acidification", "Sea level rise", "Sea temperature rise",
      "Ocean warming", "Marine heatwaves", "Storm intensity",
      "Habitat loss", "Habitat degradation", "Habitat fragmentation",
      "Invasive species", "Disease outbreaks", "Biodiversity loss",
      "Ecosystem regime shift", "Food web disruption",
      "Commercial fishing", "Recreational fishing", "Tourism impacts",
      "Shipping impacts", "Dredging", "Sand extraction",
      "Marine litter", "Ghost fishing", "Coral bleaching",
      "Mangrove loss", "Seagrass decline", "Kelp forest decline",
      "Fish stock decline", "Marine mammal decline", "Seabird decline",
      "Turtle conservation", "Shark conservation", "Cetacean conservation",
      "Climate change impacts", "Multiple stressors"
    )
  )
}

#' Convert Context Strings to Indices
#'
#' Converts context strings (regional sea name, ecosystem names, issue names)
#' to integer indices for embedding lookup.
#'
#' @param regional_sea String, regional sea name
#' @param ecosystem_types Character vector of ecosystem names
#' @param main_issues Character vector of focal issue names
#' @return List with sea_idx, eco_idx, issue_idx (torch tensors)
#' @export
context_to_indices <- function(regional_sea, ecosystem_types, main_issues) {
  vocabs <- get_context_vocabularies()

  # Regional sea index (single)
  # Handle NULL/empty input
  if (is.null(regional_sea) || length(regional_sea) == 0) {
    sea_idx <- 12L  # Default to "Global"
  } else {
    sea_match <- match(regional_sea, vocabs$regional_seas)
    sea_idx <- ifelse(is.na(sea_match), 12L, as.integer(sea_match))
  }

  # Ecosystem indices (multi-hot)
  # Handle NULL/empty input
  if (is.null(ecosystem_types) || length(ecosystem_types) == 0) {
    eco_idx <- 1L  # Default to "Coastal"
  } else {
    eco_matches <- match(ecosystem_types, vocabs$ecosystems)
    eco_idx <- eco_matches[!is.na(eco_matches)]
    if (length(eco_idx) == 0) eco_idx <- 1L  # Default to "Coastal"
  }

  # Issue indices (multi-hot)
  # Handle NULL/empty input
  if (is.null(main_issues) || length(main_issues) == 0) {
    issue_idx <- 1L  # Default to "Overfishing"
  } else {
    issue_matches <- match(main_issues, vocabs$focal_issues)
    issue_idx <- issue_matches[!is.na(issue_matches)]
    if (length(issue_idx) == 0) issue_idx <- 1L  # Default to "Overfishing"
  }

  return(list(
    sea_idx = torch_tensor(sea_idx, dtype = torch_long()),
    eco_idx = torch_tensor(eco_idx, dtype = torch_long()),
    issue_idx = torch_tensor(issue_idx, dtype = torch_long())
  ))
}

# ==============================================================================
# Utility Functions
# ==============================================================================

#' Initialize Context Embeddings with Pre-trained Values
#'
#' Optional: Initialize embeddings with meaningful starting points
#' (e.g., one-hot encodings, or pre-computed similarity matrices)
#'
#' @param model context_embeddings module
#' @param init_type Initialization type: "random" (default), "onehot", "similarity"
#' @export
initialize_context_embeddings <- function(model, init_type = "random") {
  if (init_type == "random") {
    # Default torch initialization (already done in nn_embedding)
    return(model)
  }

  if (init_type == "onehot") {
    # Initialize as one-hot compressed (for debugging/comparison)
    with_no_grad({
      # Regional seas: Compress 12-dim one-hot to 8-dim
      sea_init <- diag(model$n_seas)[, 1:model$embed_dim_sea]
      model$sea_embed$weight$copy_(torch_tensor(sea_init, dtype = torch_float()))

      # Similar for ecosystems and issues (truncated one-hot)
      eco_init <- diag(model$n_ecosystems)[, 1:model$embed_dim_eco]
      model$eco_embed$weight$copy_(torch_tensor(eco_init, dtype = torch_float()))

      issue_init <- diag(model$n_issues)[, 1:model$embed_dim_issue]
      model$issue_embed$weight$copy_(torch_tensor(issue_init, dtype = torch_float()))
    })
  }

  return(model)
}

#' Get Context Embedding Dimension
#'
#' Returns the total output dimension of context embeddings (36)
#'
#' @export
get_context_embedding_dim <- function() {
  8 + 12 + 16  # sea + ecosystem + issue
}

# ==============================================================================
# Initialization Message
# ==============================================================================

cat("✓ ML Context Embeddings module loaded\n")
cat(sprintf("  - Regional seas: 12 categories → 8-dim embeddings\n"))
cat(sprintf("  - Ecosystems: 25 categories → 12-dim embeddings\n"))
cat(sprintf("  - Focal issues: 52 categories → 16-dim embeddings\n"))
cat(sprintf("  - Total output: %d dims (vs 88 sparse one-hot)\n", get_context_embedding_dim()))
cat("  - context_embeddings(): Neural network module\n")
cat("  - context_to_indices(): Convert strings to embedding indices\n")
