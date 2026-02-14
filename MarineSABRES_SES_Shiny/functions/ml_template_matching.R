# ==============================================================================
# Template Similarity Matching (Week 7)
# ==============================================================================
# Functions for calculating similarity between SES templates to guide
# transfer learning. Helps determine which pre-trained model to use
# when fine-tuning on a new template.
#
# Similarity factors:
# - Regional context overlap (shared seas)
# - Ecosystem type overlap (shared ecosystems)
# - Focal issue overlap (shared issues)
# - Vocabulary overlap (shared element names/types)
# - Template size similarity (number of elements/connections)
# - DAPSI(W)R(M) type distribution
#
# Author: Phase 2 ML Enhancement - Week 7
# Date: 2026-01-01
# ==============================================================================

# ==============================================================================
# Context Overlap Functions
# ==============================================================================

#' Calculate Regional Context Overlap
#'
#' Measures overlap in regional seas between two templates
#'
#' @param template1 List or dataframe. First template data
#' @param template2 List or dataframe. Second template data
#' @return Numeric. Jaccard similarity (0-1)
#' @export
regional_context_overlap <- function(template1, template2) {

  # Extract regional seas
  if (is.data.frame(template1)) {
    seas1 <- unique(template1$regional_sea)
  } else if (is.list(template1) && "regional_sea" %in% names(template1)) {
    seas1 <- unique(template1$regional_sea)
  } else {
    return(0)
  }

  if (is.data.frame(template2)) {
    seas2 <- unique(template2$regional_sea)
  } else if (is.list(template2) && "regional_sea" %in% names(template2)) {
    seas2 <- unique(template2$regional_sea)
  } else {
    return(0)
  }

  # Remove NA
  seas1 <- seas1[!is.na(seas1)]
  seas2 <- seas2[!is.na(seas2)]

  if (length(seas1) == 0 || length(seas2) == 0) return(0)

  # Jaccard similarity
  intersection <- length(intersect(seas1, seas2))
  union <- length(union(seas1, seas2))

  return(intersection / union)
}

#' Calculate Ecosystem Type Overlap
#'
#' Measures overlap in ecosystem types between templates
#'
#' @param template1 List or dataframe. First template data
#' @param template2 List or dataframe. Second template data
#' @return Numeric. Jaccard similarity (0-1)
#' @export
ecosystem_overlap <- function(template1, template2) {

  # Extract ecosystems (may be multi-valued, semicolon-separated)
  extract_ecosystems <- function(template) {
    if (is.data.frame(template)) {
      eco_str <- unique(template$ecosystem_types)
    } else if (is.list(template) && "ecosystem_types" %in% names(template)) {
      eco_str <- unique(template$ecosystem_types)
    } else {
      return(character(0))
    }

    # Split by semicolon and flatten
    eco_list <- unlist(strsplit(eco_str, ";"))
    eco_list <- trimws(eco_list)
    eco_list <- eco_list[eco_list != "" & !is.na(eco_list)]

    return(unique(eco_list))
  }

  eco1 <- extract_ecosystems(template1)
  eco2 <- extract_ecosystems(template2)

  if (length(eco1) == 0 || length(eco2) == 0) return(0)

  # Jaccard similarity
  intersection <- length(intersect(eco1, eco2))
  union <- length(union(eco1, eco2))

  return(intersection / union)
}

#' Calculate Focal Issue Overlap
#'
#' Measures overlap in focal issues between templates
#'
#' @param template1 List or dataframe. First template data
#' @param template2 List or dataframe. Second template data
#' @return Numeric. Jaccard similarity (0-1)
#' @export
issue_overlap <- function(template1, template2) {

  # Extract issues (may be multi-valued, semicolon-separated)
  extract_issues <- function(template) {
    if (is.data.frame(template)) {
      issue_str <- unique(template$main_issues)
    } else if (is.list(template) && "main_issues" %in% names(template)) {
      issue_str <- unique(template$main_issues)
    } else {
      return(character(0))
    }

    # Split by semicolon and flatten
    issue_list <- unlist(strsplit(issue_str, ";"))
    issue_list <- trimws(issue_list)
    issue_list <- issue_list[issue_list != "" & !is.na(issue_list)]

    return(unique(issue_list))
  }

  issue1 <- extract_issues(template1)
  issue2 <- extract_issues(template2)

  if (length(issue1) == 0 || length(issue2) == 0) return(0)

  # Jaccard similarity
  intersection <- length(intersect(issue1, issue2))
  union <- length(union(issue1, issue2))

  return(intersection / union)
}

# ==============================================================================
# Vocabulary Overlap Functions
# ==============================================================================

#' Calculate Vocabulary Overlap
#'
#' Measures overlap in element names and types between templates
#'
#' @param template1 List or dataframe. First template data
#' @param template2 List or dataframe. Second template data
#' @return Numeric. Jaccard similarity (0-1)
#' @export
vocabulary_overlap <- function(template1, template2) {

  # Extract element names
  extract_elements <- function(template) {
    if (is.data.frame(template)) {
      elements <- unique(c(template$source_name, template$target_name))
    } else if (is.list(template) && "elements" %in% names(template)) {
      if (is.data.frame(template$elements)) {
        elements <- unique(template$elements$name)
      } else {
        elements <- names(template$elements)
      }
    } else {
      return(character(0))
    }

    elements <- elements[!is.na(elements)]
    return(elements)
  }

  elem1 <- extract_elements(template1)
  elem2 <- extract_elements(template2)

  if (length(elem1) == 0 || length(elem2) == 0) return(0)

  # Jaccard similarity
  intersection <- length(intersect(elem1, elem2))
  union <- length(union(elem1, elem2))

  return(intersection / union)
}

#' Calculate DAPSI(W)R(M) Type Distribution Similarity
#'
#' Measures similarity in distribution of element types
#'
#' @param template1 List or dataframe. First template data
#' @param template2 List or dataframe. Second template data
#' @return Numeric. Cosine similarity (0-1)
#' @export
type_distribution_similarity <- function(template1, template2) {

  # Extract type distributions
  extract_type_dist <- function(template) {
    if (is.data.frame(template)) {
      types <- c(template$source_type, template$target_type)
    } else if (is.list(template) && "elements" %in% names(template)) {
      if (is.data.frame(template$elements)) {
        types <- template$elements$type
      } else {
        types <- sapply(template$elements, function(e) e$type %||% NA)
      }
    } else {
      return(NULL)
    }

    # Count types
    type_counts <- table(types)
    return(type_counts)
  }

  dist1 <- extract_type_dist(template1)
  dist2 <- extract_type_dist(template2)

  if (is.null(dist1) || is.null(dist2)) return(0)

  # Get all unique types
  all_types <- union(names(dist1), names(dist2))

  # Create vectors
  vec1 <- sapply(all_types, function(t) dist1[t] %||% 0)
  vec2 <- sapply(all_types, function(t) dist2[t] %||% 0)

  # Cosine similarity
  dot_product <- sum(vec1 * vec2)
  norm1 <- sqrt(sum(vec1^2))
  norm2 <- sqrt(sum(vec2^2))

  if (norm1 == 0 || norm2 == 0) return(0)

  return(dot_product / (norm1 * norm2))
}

# ==============================================================================
# Size Similarity Function
# ==============================================================================

#' Calculate Size Ratio
#'
#' Measures similarity in template size (number of elements/connections)
#'
#' @param template1 List or dataframe. First template data
#' @param template2 List or dataframe. Second template data
#' @return Numeric. Ratio similarity (0-1), 1 = same size
#' @export
size_ratio <- function(template1, template2) {

  # Extract sizes
  extract_size <- function(template) {
    if (is.data.frame(template)) {
      return(nrow(template))
    } else if (is.list(template) && "elements" %in% names(template)) {
      if (is.data.frame(template$elements)) {
        return(nrow(template$elements))
      } else {
        return(length(template$elements))
      }
    } else {
      return(0)
    }
  }

  size1 <- extract_size(template1)
  size2 <- extract_size(template2)

  if (size1 == 0 || size2 == 0) return(0)

  # Ratio similarity: min/max (symmetric)
  ratio <- min(size1, size2) / max(size1, size2)

  return(ratio)
}

# ==============================================================================
# Overall Template Similarity
# ==============================================================================

#' Calculate Overall Template Similarity
#'
#' Combines multiple similarity measures into overall score
#'
#' @param source_template List or dataframe. Source template (pre-trained)
#' @param target_template List or dataframe. Target template (to fine-tune)
#' @param weights List. Weights for each similarity component
#' @return List with overall similarity and component scores
#' @export
calculate_template_similarity <- function(source_template,
                                         target_template,
                                         weights = list(
                                           regional = 0.25,
                                           ecosystem = 0.25,
                                           issue = 0.20,
                                           vocabulary = 0.15,
                                           type_dist = 0.10,
                                           size = 0.05
                                         )) {

  # Calculate component similarities
  regional_sim <- regional_context_overlap(source_template, target_template)
  ecosystem_sim <- ecosystem_overlap(source_template, target_template)
  issue_sim <- issue_overlap(source_template, target_template)
  vocab_sim <- vocabulary_overlap(source_template, target_template)
  type_sim <- type_distribution_similarity(source_template, target_template)
  size_sim <- size_ratio(source_template, target_template)

  # Weighted combination
  overall <- (
    weights$regional * regional_sim +
    weights$ecosystem * ecosystem_sim +
    weights$issue * issue_sim +
    weights$vocabulary * vocab_sim +
    weights$type_dist * type_sim +
    weights$size * size_sim
  )

  return(list(
    overall = overall,
    components = list(
      regional_context = regional_sim,
      ecosystem = ecosystem_sim,
      focal_issue = issue_sim,
      vocabulary = vocab_sim,
      type_distribution = type_sim,
      size = size_sim
    ),
    weights = weights,
    recommendation = categorize_similarity(overall)
  ))
}

#' Categorize Similarity Score
#'
#' @param score Numeric. Similarity score (0-1)
#' @return Character. Category
categorize_similarity <- function(score) {
  if (score >= 0.7) {
    return("high_similarity")
  } else if (score >= 0.4) {
    return("medium_similarity")
  } else {
    return("low_similarity")
  }
}

# ==============================================================================
# Batch Similarity Calculation
# ==============================================================================

#' Calculate Similarities for All Template Pairs
#'
#' @param training_data List. Training data with templates
#' @return Dataframe with pairwise similarities
#' @export
calculate_all_template_similarities <- function(training_data) {

  # Extract unique templates
  if ("train" %in% names(training_data)) {
    train_df <- training_data$train
  } else {
    train_df <- training_data
  }

  template_names <- unique(train_df$template)
  n_templates <- length(template_names)

  debug_log(sprintf("Calculating similarities for %d templates...", n_templates), "ML_TEMPLATE")

  # Create results dataframe
  results <- data.frame(
    source_template = character(),
    target_template = character(),
    overall_similarity = numeric(),
    regional_sim = numeric(),
    ecosystem_sim = numeric(),
    issue_sim = numeric(),
    vocabulary_sim = numeric(),
    type_dist_sim = numeric(),
    size_sim = numeric(),
    recommendation = character(),
    stringsAsFactors = FALSE
  )

  # Calculate pairwise similarities
  for (i in 1:(n_templates - 1)) {
    for (j in (i + 1):n_templates) {
      source_name <- template_names[i]
      target_name <- template_names[j]

      # Filter to templates
      source_data <- train_df[train_df$template == source_name, ]
      target_data <- train_df[train_df$template == target_name, ]

      # Calculate similarity
      sim <- calculate_template_similarity(source_data, target_data)

      # Add to results (both directions)
      results <- rbind(results, data.frame(
        source_template = source_name,
        target_template = target_name,
        overall_similarity = sim$overall,
        regional_sim = sim$components$regional_context,
        ecosystem_sim = sim$components$ecosystem,
        issue_sim = sim$components$focal_issue,
        vocabulary_sim = sim$components$vocabulary,
        type_dist_sim = sim$components$type_distribution,
        size_sim = sim$components$size,
        recommendation = sim$recommendation,
        stringsAsFactors = FALSE
      ))

      # Reverse direction
      results <- rbind(results, data.frame(
        source_template = target_name,
        target_template = source_name,
        overall_similarity = sim$overall,
        regional_sim = sim$components$regional_context,
        ecosystem_sim = sim$components$ecosystem,
        issue_sim = sim$components$focal_issue,
        vocabulary_sim = sim$components$vocabulary,
        type_dist_sim = sim$components$type_distribution,
        size_sim = sim$components$size,
        recommendation = sim$recommendation,
        stringsAsFactors = FALSE
      ))
    }
  }

  debug_log(sprintf("Calculated %d pairwise similarities", nrow(results)), "ML_TEMPLATE")

  return(results)
}

#' Recommend Source Template for Transfer Learning
#'
#' @param target_template_name Character. Name of target template
#' @param similarity_matrix Dataframe. Pre-calculated similarities
#' @param min_similarity Numeric. Minimum similarity threshold (default: 0.3)
#' @return List with recommendations
#' @export
recommend_source_template <- function(target_template_name,
                                     similarity_matrix,
                                     min_similarity = 0.3) {

  # Filter to target template
  candidates <- similarity_matrix[
    similarity_matrix$target_template == target_template_name &
    similarity_matrix$overall_similarity >= min_similarity,
  ]

  if (nrow(candidates) == 0) {
    return(list(
      target = target_template_name,
      recommendation = "train_from_scratch",
      reason = "No sufficiently similar templates found",
      similarity = NA
    ))
  }

  # Sort by similarity
  candidates <- candidates[order(candidates$overall_similarity, decreasing = TRUE), ]

  # Top recommendation
  top <- candidates[1, ]

  return(list(
    target = target_template_name,
    recommended_source = top$source_template,
    similarity = top$overall_similarity,
    recommendation_category = top$recommendation,
    reason = sprintf("Similarity: %.2f (regional: %.2f, ecosystem: %.2f, issue: %.2f)",
                    top$overall_similarity,
                    top$regional_sim,
                    top$ecosystem_sim,
                    top$issue_sim),
    all_candidates = candidates
  ))
}

# ==============================================================================
# Startup Message
# ==============================================================================

debug_log("ML Template Matching module loaded", "ML_TEMPLATE")
debug_log("calculate_template_similarity(): Overall similarity score", "ML_TEMPLATE")
debug_log("calculate_all_template_similarities(): Pairwise similarity matrix", "ML_TEMPLATE")
debug_log("recommend_source_template(): Transfer learning recommendation", "ML_TEMPLATE")
debug_log("Component similarities: regional, ecosystem, issue, vocabulary, type, size", "ML_TEMPLATE")
