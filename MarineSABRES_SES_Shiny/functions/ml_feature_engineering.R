# ==============================================================================
# ML Feature Engineering Functions
# ==============================================================================
# Functions to convert SES elements and context into numeric features
# for the Deep Learning Connection Predictor model.
#
# Feature vector composition (~400 dimensions):
#   - Element embeddings: 2 × 128 dim (source + target text)
#   - Type encodings: 2 × 7 dim (source + target DAPSI(W)R(M) types)
#   - Context encoding: ~100 dim (regional sea + ecosystem + issue)
# ==============================================================================

if (!requireNamespace("stringr", quietly = TRUE)) {
  stop("Package 'stringr' is required. Install with: install.packages('stringr')")
}
if (!requireNamespace("dplyr", quietly = TRUE)) {
  stop("Package 'dplyr' is required. Install with: install.packages('dplyr')")
}

# ==============================================================================
# Constants
# ==============================================================================

# DAPSI(W)R(M) type list (ordered)
DAPSIWRM_TYPES <- c(
  "Drivers",
  "Activities",
  "Pressures",
  "Marine Processes & Functioning",
  "Ecosystem Services",
  "Goods & Benefits",
  "Responses"
)

# Regional seas (from knowledge base)
REGIONAL_SEAS <- c(
  "Baltic Sea", "North Sea", "Mediterranean", "Irish Sea", "East Atlantic",
  "Black Sea", "Arctic Ocean", "Caribbean", "Pacific Ocean",
  "Indian Ocean", "Atlantic Ocean", "Other"
)

# Common ecosystem types
ECOSYSTEM_TYPES <- c(
  "Open coast", "Estuary", "Coastal lagoon", "Archipelago", "Offshore waters",
  "Coral reef", "Mangrove", "Seagrass meadow", "Sandy beach", "Rocky shore",
  "Continental shelf", "Deep sea", "Upwelling zone", "Fjord", "Delta",
  "Salt marsh", "Mudflat", "Kelp forest", "Seamount", "Hydrothermal vent",
  "Ice-covered", "Transitional waters", "Coastal wetland", "Lagoon", "Other"
)

# Common focal issues (top 50)
FOCAL_ISSUES <- c(
  "Overfishing", "Eutrophication", "Climate change", "Pollution",
  "Marine litter", "Coastal development", "Invasive species",
  "Ocean acidification", "Habitat loss", "Sargassum blooms",
  "Bycatch", "IUU fishing", "Aquaculture", "Shipping", "Tourism",
  "Oil spills", "Plastic pollution", "Nutrient pollution",
  "Chemical contamination", "Noise pollution", "Light pollution",
  "Marine debris", "Ghost fishing", "Dredging", "Sand extraction",
  "Offshore wind", "Oil and gas", "Coastal erosion", "Sea level rise",
  "Ocean warming", "Hypoxia", "Harmful algal blooms", "Biodiversity loss",
  "Ecosystem degradation", "Fish stock depletion", "Coral bleaching",
  "Mangrove loss", "Seagrass decline", "Kelp forest loss",
  "Marine protected areas", "Sustainable fishing", "Blue economy",
  "Marine spatial planning", "Coastal management", "Water quality",
  "Seafood safety", "Livelihood", "Food security", "Recreation",
  "Cultural heritage", "Other"
)

# Marine-specific vocabulary for text embeddings
MARINE_VOCABULARY <- c(
  # Activities
  "fishing", "trawling", "aquaculture", "farming", "shipping", "navigation",
  "tourism", "recreation", "diving", "construction", "dredging", "extraction",
  "drilling", "mining", "dumping", "discharge", "shipping", "transport",

  # Pressures
  "overfishing", "bycatch", "pollution", "nutrient", "enrichment", "eutrophication",
  "contamination", "toxic", "oil", "spill", "plastic", "litter", "debris",
  "noise", "acoustic", "disturbance", "physical", "habitat", "destruction",
  "loss", "degradation", "sedimentation", "erosion", "warming", "acidification",
  "hypoxia", "anoxia", "algal", "bloom", "invasive", "species", "introduction",

  # State changes
  "decline", "depletion", "reduction", "loss", "degradation", "mortality",
  "abundance", "biomass", "productivity", "quality", "health", "integrity",
  "diversity", "richness", "coverage", "extent", "structure", "function",

  # Impacts
  "fish", "stock", "catch", "yield", "seafood", "food", "security",
  "livelihood", "income", "employment", "tourism", "recreation", "aesthetic",
  "cultural", "heritage", "regulation", "protection", "carbon", "oxygen",

  # Responses
  "quota", "regulation", "ban", "restriction", "mpa", "protected", "area",
  "reserve", "sanctuary", "management", "plan", "monitoring", "enforcement",
  "restoration", "conservation", "mitigation", "adaptation", "treatment",
  "control", "reduction", "policy", "legislation", "agreement", "convention",

  # Ecosystems
  "coral", "reef", "mangrove", "seagrass", "kelp", "forest", "estuary",
  "lagoon", "wetland", "marsh", "mudflat", "beach", "coast", "offshore",
  "deep", "sea", "shelf", "slope", "seamount", "vent",

  # Species
  "fish", "cod", "herring", "tuna", "salmon", "shark", "whale", "dolphin",
  "seal", "turtle", "bird", "seabird", "plankton", "zooplankton", "phytoplankton",
  "benthos", "bivalve", "crustacean", "mollusc", "algae", "bacteria"
)

# ==============================================================================
# Type Encoding Functions
# ==============================================================================

#' One-hot encode DAPSI(W)R(M) type
#'
#' @param type_name Character. Type name (e.g., "Activities", "Pressures")
#' @return Numeric vector of length 7 (one-hot encoded)
#' @examples
#' encode_dapsiwrm_type("Activities")  # Returns c(0, 1, 0, 0, 0, 0, 0)
encode_dapsiwrm_type <- function(type_name) {
  if (is.null(type_name) || is.na(type_name) || type_name == "") {
    return(rep(0, length(DAPSIWRM_TYPES)))
  }

  # Find index
  idx <- match(type_name, DAPSIWRM_TYPES)

  if (is.na(idx)) {
    # Unknown type - return all zeros
    warning(sprintf("Unknown DAPSI(W)R(M) type: %s", type_name))
    return(rep(0, length(DAPSIWRM_TYPES)))
  }

  # One-hot encoding
  encoding <- rep(0, length(DAPSIWRM_TYPES))
  encoding[idx] <- 1

  return(encoding)
}

# ==============================================================================
# Context Encoding Functions
# ==============================================================================

#' One-hot encode regional sea
#'
#' @param regional_sea Character. Regional sea name
#' @return Numeric vector (one-hot encoded)
encode_regional_sea <- function(regional_sea) {
  if (is.null(regional_sea) || is.na(regional_sea) || regional_sea == "") {
    regional_sea <- "Other"
  }

  # Fuzzy matching
  idx <- match(regional_sea, REGIONAL_SEAS)

  if (is.na(idx)) {
    # Try partial matching
    matches <- grep(regional_sea, REGIONAL_SEAS, ignore.case = TRUE, value = FALSE)
    if (length(matches) > 0) {
      idx <- matches[1]
    } else {
      idx <- match("Other", REGIONAL_SEAS)
    }
  }

  encoding <- rep(0, length(REGIONAL_SEAS))
  encoding[idx] <- 1

  return(encoding)
}

#' Multi-hot encode ecosystem types (can have multiple)
#'
#' @param ecosystem_types Character. Semicolon-separated ecosystem types
#' @return Numeric vector (multi-hot encoded)
encode_ecosystem_types <- function(ecosystem_types) {
  if (is.null(ecosystem_types) || is.na(ecosystem_types) || ecosystem_types == "") {
    ecosystem_types <- "Other"
  }

  # Split by semicolon
  types <- str_split(ecosystem_types, ";")[[1]]
  types <- str_trim(types)

  encoding <- rep(0, length(ECOSYSTEM_TYPES))

  for (type in types) {
    idx <- match(type, ECOSYSTEM_TYPES)

    if (is.na(idx)) {
      # Try partial matching
      matches <- grep(type, ECOSYSTEM_TYPES, ignore.case = TRUE, value = FALSE)
      if (length(matches) > 0) {
        idx <- matches[1]
      } else {
        idx <- match("Other", ECOSYSTEM_TYPES)
      }
    }

    encoding[idx] <- 1
  }

  return(encoding)
}

#' Multi-hot encode focal issues (can have multiple)
#'
#' @param main_issues Character. Semicolon-separated issues
#' @return Numeric vector (multi-hot encoded, top 50 issues)
encode_focal_issues <- function(main_issues) {
  if (is.null(main_issues) || is.na(main_issues) || main_issues == "") {
    main_issues <- "Other"
  }

  # Split by semicolon
  issues <- str_split(main_issues, ";")[[1]]
  issues <- str_trim(issues)

  encoding <- rep(0, length(FOCAL_ISSUES))

  for (issue in issues) {
    idx <- match(issue, FOCAL_ISSUES)

    if (is.na(idx)) {
      # Try partial matching
      matches <- grep(issue, FOCAL_ISSUES, ignore.case = TRUE, value = FALSE)
      if (length(matches) > 0) {
        encoding[matches] <- 1  # Can match multiple
      } else {
        encoding[match("Other", FOCAL_ISSUES)] <- 1
      }
    } else {
      encoding[idx] <- 1
    }
  }

  return(encoding)
}

#' Combine all context features (Phase 1 - One-hot encoding)
#'
#' @param regional_sea Character. Regional sea name
#' @param ecosystem_types Character. Ecosystem types (semicolon-separated)
#' @param main_issues Character. Focal issues (semicolon-separated)
#' @return Numeric vector (combined context encoding)
encode_context <- function(regional_sea, ecosystem_types, main_issues) {
  sea_enc <- encode_regional_sea(regional_sea)
  eco_enc <- encode_ecosystem_types(ecosystem_types)
  issue_enc <- encode_focal_issues(main_issues)

  # Combine: 12 (seas) + 25 (ecosystems) + 50 (issues) = 87 dimensions
  return(c(sea_enc, eco_enc, issue_enc))
}

#' Prepare context indices for embedding lookup (Phase 2)
#'
#' Converts context strings to integer indices for learned embeddings.
#' Used in Phase 2 models with ContextEmbeddings layer.
#'
#' @param regional_sea Character. Regional sea name
#' @param ecosystem_types Character. Ecosystem types (semicolon-separated)
#' @param main_issues Character. Focal issues (semicolon-separated)
#' @return List with sea_idx, eco_idx, issue_idx (integer vectors)
prepare_context_indices <- function(regional_sea, ecosystem_types, main_issues) {
  # Parse ecosystem types and main issues
  ecosystems <- if (!is.null(ecosystem_types) && !is.na(ecosystem_types) && ecosystem_types != "") {
    str_split(ecosystem_types, ";")[[1]] %>% str_trim()
  } else {
    "Coastal"  # Default
  }

  issues <- if (!is.null(main_issues) && !is.na(main_issues) && main_issues != "") {
    str_split(main_issues, ";")[[1]] %>% str_trim()
  } else {
    "Overfishing"  # Default
  }

  # Regional sea index (single)
  sea_match <- match(regional_sea, REGIONAL_SEAS)
  sea_idx <- if (is.na(sea_match)) 12L else as.integer(sea_match)  # Default to "Global"

  # Ecosystem indices (multi-hot)
  eco_matches <- match(ecosystems, ECOSYSTEM_TYPES)
  eco_idx <- eco_matches[!is.na(eco_matches)]
  if (length(eco_idx) == 0) eco_idx <- 1L  # Default to "Coastal"

  # Issue indices (multi-hot)
  issue_matches <- match(issues, FOCAL_ISSUES)
  issue_idx <- issue_matches[!is.na(issue_matches)]
  if (length(issue_idx) == 0) issue_idx <- 1L  # Default to "Overfishing"

  return(list(
    sea_idx = sea_idx,
    eco_idx = eco_idx,
    issue_idx = issue_idx
  ))
}

# ==============================================================================
# Text Embedding Functions
# ==============================================================================

#' Tokenize element name into words
#'
#' @param element_name Character. Element name (e.g., "Commercial fishing")
#' @return Character vector of lowercase words
tokenize_element_name <- function(element_name) {
  if (is.null(element_name) || is.na(element_name) || element_name == "") {
    return(character(0))
  }

  # Convert to lowercase and split by word boundaries
  words <- str_to_lower(element_name)
  words <- str_split(words, "\\s+")[[1]]

  # Remove punctuation and numbers
  words <- str_replace_all(words, "[^a-z]", "")

  # Remove empty strings
  words <- words[words != ""]

  return(words)
}

#' Create element embedding using simple word averaging
#'
#' This is a simplified approach (Option A from plan):
#' - Tokenize element name into words
#' - Check if words are in marine vocabulary
#' - Create binary presence vector
#' - Add TF-IDF-like weighting
#'
#' @param element_name Character. Element name
#' @param embedding_dim Integer. Output dimension (default 128)
#' @return Numeric vector of fixed dimension
create_element_embedding <- function(element_name, embedding_dim = 128) {
  words <- tokenize_element_name(element_name)

  if (length(words) == 0) {
    return(rep(0, embedding_dim))
  }

  # Method 1: Vocabulary-based binary features (first 100 dims)
  vocab_features <- rep(0, min(100, length(MARINE_VOCABULARY)))
  for (i in 1:length(vocab_features)) {
    if (any(words %in% MARINE_VOCABULARY[i])) {
      vocab_features[i] <- 1
    }
    # Partial matching
    if (any(grepl(MARINE_VOCABULARY[i], words))) {
      vocab_features[i] <- 0.5
    }
  }

  # Method 2: Word count features (28 dims)
  word_count_features <- c(
    length(words),  # Total words
    mean(nchar(words)),  # Avg word length
    max(nchar(words)),  # Max word length
    sum(grepl("ing$", words)),  # Gerund count
    sum(grepl("tion$", words)),  # Noun suffix count
    sum(grepl("^over", words)),  # "over-" prefix
    sum(grepl("^de", words)),  # "de-" prefix
    sum(grepl("pollution|contamination", words)),  # Pollution-related
    sum(grepl("fish|catch|stock", words)),  # Fisheries-related
    sum(grepl("habitat|ecosystem|coral|mangrove", words)),  # Habitat-related
    sum(grepl("nutrient|nitrogen|phosphorus", words)),  # Nutrient-related
    sum(grepl("climate|warming|acidification", words)),  # Climate-related
    sum(grepl("tourism|recreation|visitor", words)),  # Tourism-related
    sum(grepl("shipping|vessel|transport", words)),  # Shipping-related
    sum(grepl("aquaculture|farm|culture", words)),  # Aquaculture-related
    sum(grepl("regulation|quota|ban|mpa", words)),  # Management-related
    sum(grepl("loss|decline|reduction|depletion", words)),  # Negative trends
    sum(grepl("increase|growth|abundance", words)),  # Positive trends
    sum(grepl("quality|health|integrity", words)),  # Quality indicators
    sum(grepl("biodiversity|species|richness", words)),  # Biodiversity
    sum(grepl("coastal|offshore|marine", words)),  # Spatial
    sum(grepl("commercial|industrial|artisanal", words)),  # Economic
    sum(grepl("food|security|livelihood|income", words)),  # Welfare
    sum(grepl("cultural|heritage|aesthetic", words)),  # Cultural
    sum(grepl("carbon|oxygen|nutrient|cycling", words)),  # Regulating services
    sum(grepl("noise|acoustic|light|visual", words)),  # Sensory pollution
    sum(grepl("invasive|alien|introduced", words)),  # Invasive species
    sum(grepl("oil|chemical|plastic|heavy|metal", words))  # Pollutant types
  )

  # Normalize word count features
  word_count_features <- word_count_features / max(1, length(words))

  # Combine features (100 vocab + 28 count = 128 dims)
  embedding <- c(vocab_features, word_count_features)

  # Ensure exactly embedding_dim dimensions
  if (length(embedding) < embedding_dim) {
    embedding <- c(embedding, rep(0, embedding_dim - length(embedding)))
  } else if (length(embedding) > embedding_dim) {
    embedding <- embedding[1:embedding_dim]
  }

  return(embedding)
}

# ==============================================================================
# Combined Feature Vector Creation
# ==============================================================================

#' Create complete feature vector for element pair
#'
#' Combines source element, target element, and context features
#'
#' @param source_name Character. Source element name
#' @param source_type Character. Source DAPSI(W)R(M) type
#' @param target_name Character. Target element name
#' @param target_type Character. Target DAPSI(W)R(M) type
#' @param regional_sea Character. Regional sea
#' @param ecosystem_types Character. Ecosystem types
#' @param main_issues Character. Focal issues
#' @param embedding_dim Integer. Embedding dimension per element (default 128)
#' @return Numeric vector (feature vector for model input)
#'
#' @details
#' Feature vector composition (~400 dimensions):
#'   - Source element embedding: 128 dim
#'   - Source type one-hot: 7 dim
#'   - Target element embedding: 128 dim
#'   - Target type one-hot: 7 dim
#'   - Context encoding: 87 dim (12 seas + 25 ecosystems + 50 issues)
#'   Total: 128 + 7 + 128 + 7 + 87 = 357 dimensions
create_feature_vector <- function(source_name, source_type,
                                   target_name, target_type,
                                   regional_sea, ecosystem_types, main_issues,
                                   embedding_dim = 128) {
  # Source element features
  source_embedding <- create_element_embedding(source_name, embedding_dim)
  source_type_enc <- encode_dapsiwrm_type(source_type)

  # Target element features
  target_embedding <- create_element_embedding(target_name, embedding_dim)
  target_type_enc <- encode_dapsiwrm_type(target_type)

  # Context features
  context_enc <- encode_context(regional_sea, ecosystem_types, main_issues)

  # Combine all features
  feature_vector <- c(
    source_embedding,
    source_type_enc,
    target_embedding,
    target_type_enc,
    context_enc
  )

  return(feature_vector)
}

#' Batch process feature vectors from dataframe
#'
#' @param data Dataframe with columns: source_name, source_type, target_name, target_type,
#'             regional_sea, ecosystem_types, main_issues
#' @param embedding_dim Integer. Embedding dimension (default 128)
#' @return Matrix where each row is a feature vector
create_feature_matrix <- function(data, embedding_dim = 128) {
  n_examples <- nrow(data)

  # Create first feature vector to determine dimension
  first_fv <- create_feature_vector(
    source_name = data$source_name[1],
    source_type = data$source_type[1],
    target_name = data$target_name[1],
    target_type = data$target_type[1],
    regional_sea = data$regional_sea[1],
    ecosystem_types = data$ecosystem_types[1],
    main_issues = data$main_issues[1],
    embedding_dim = embedding_dim
  )

  feature_dim <- length(first_fv)

  # Pre-allocate matrix
  feature_matrix <- matrix(0, nrow = n_examples, ncol = feature_dim)
  feature_matrix[1, ] <- first_fv

  # Progress indicator
  debug_log(sprintf("Creating feature vectors for %d examples (dim=%d)...", n_examples, feature_dim), "ML_FEATURES")
  pb <- txtProgressBar(min = 0, max = n_examples, style = 3)

  # Start from 2 since we already created the first one
  if (n_examples > 1) {
    for (i in 2:n_examples) {
      feature_matrix[i, ] <- create_feature_vector(
        source_name = data$source_name[i],
        source_type = data$source_type[i],
        target_name = data$target_name[i],
        target_type = data$target_type[i],
        regional_sea = data$regional_sea[i],
        ecosystem_types = data$ecosystem_types[i],
        main_issues = data$main_issues[i],
        embedding_dim = embedding_dim
      )

      setTxtProgressBar(pb, i)
    }
  }

  close(pb)
  debug_log("Feature matrix created", "ML_FEATURES")

  return(feature_matrix)
}

# ==============================================================================
# Utility Functions
# ==============================================================================

#' Get feature dimension
#'
#' @param embedding_dim Integer. Embedding dimension per element
#' @return Integer. Total feature vector dimension
get_feature_dim <- function(embedding_dim = 128) {
  # Actual dimensions: 2 * embedding + 2 * 7 (types) + context
  # Context = 12 (seas) + 25 (ecosystems) + 51 (issues) = 88
  return(2 * embedding_dim + 2 * 7 + 88)
}

#' Print feature vector summary
#'
#' @param feature_vector Numeric vector
print_feature_summary <- function(feature_vector) {
  cat(sprintf("Feature vector dimension: %d\n", length(feature_vector)))
  cat(sprintf("Non-zero elements: %d (%.1f%%)\n",
              sum(feature_vector != 0),
              100 * sum(feature_vector != 0) / length(feature_vector)))
  cat(sprintf("Range: [%.3f, %.3f]\n", min(feature_vector), max(feature_vector)))
  cat(sprintf("Mean: %.3f, SD: %.3f\n", mean(feature_vector), sd(feature_vector)))
}

# Export all functions
debug_log("ML Feature Engineering functions loaded", "ML_FEATURES")
debug_log(sprintf("DAPSI(W)R(M) types: %d", length(DAPSIWRM_TYPES)), "ML_FEATURES")
debug_log(sprintf("Regional seas: %d", length(REGIONAL_SEAS)), "ML_FEATURES")
debug_log(sprintf("Ecosystem types: %d", length(ECOSYSTEM_TYPES)), "ML_FEATURES")
debug_log(sprintf("Focal issues: %d", length(FOCAL_ISSUES)), "ML_FEATURES")
debug_log(sprintf("Marine vocabulary: %d terms", length(MARINE_VOCABULARY)), "ML_FEATURES")
debug_log(sprintf("Default feature dimension: %d", get_feature_dim()), "ML_FEATURES")
