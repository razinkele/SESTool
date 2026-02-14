# modules/graphical_ses_ai_classifier.R
# AI-powered element classification for graphical SES creator
# Uses keyword matching and context awareness to classify elements into DAPSIWRM types
# Enhanced with ML-based predictions (blended approach)

# Try to load ML inference if available
.ml_classifier_available <- tryCatch({
  source("functions/ml_inference.R", local = TRUE)
  load_ml_model()
  TRUE
}, error = function(e) {
  FALSE
})

#' Classify Element to DAPSIWRM Type Using Knowledge-Based AI
#'
#' Main classification function that analyzes an element name and suggests
#' the most likely DAPSIWRM type along with alternatives.
#'
#' @param element_name User-provided element name
#' @param context List with regional_sea, ecosystem_type, main_issue
#' @param i18n Internationalization object (optional)
#' @return List with primary suggestion and alternatives
#' @export
classify_element_with_ai <- function(element_name, context, i18n = NULL) {

  # Validate inputs
  validate(need(
    !is.null(element_name) && nchar(trimws(element_name)) > 0,
    "Element name cannot be empty"
  ))


  element_name <- trimws(element_name)

  # Step 1: Keyword matching against knowledge base
  debug_log(paste0("Matching keywords for: ", element_name), "AI CLASSIFIER")
  keyword_scores <- match_keywords_to_types(element_name)

  # Step 2: Context refinement
  if (!is.null(context) && !is.null(context$main_issue)) {
    debug_log(paste0("Adjusting scores based on context: ", context$main_issue), "AI CLASSIFIER")
    keyword_scores <- adjust_scores_by_context(keyword_scores, context)
  }

  # Step 3: Pattern recognition
  debug_log("Applying pattern recognition", "AI CLASSIFIER")
  pattern_scores <- apply_pattern_recognition(element_name)

  # Step 4: Combine scores (weighted average)
  final_scores <- combine_classification_scores(
    keyword_scores = keyword_scores,
    pattern_scores = pattern_scores,
    weights = c(keyword = 0.65, pattern = 0.35)
  )

  # Step 5: Rank and return top 3
  ranked_types <- rank_dapsiwrm_types(final_scores)

  # Generate result
  result <- list(
    primary = list(
      type = ranked_types[[1]]$type,
      confidence = ranked_types[[1]]$score,
      reasoning = generate_classification_reasoning(
        ranked_types[[1]],
        element_name,
        context,
        i18n
      )
    ),
    alternatives = list(
      list(
        type = ranked_types[[2]]$type,
        confidence = ranked_types[[2]]$score,
        reasoning = generate_classification_reasoning(
          ranked_types[[2]],
          element_name,
          context,
          i18n
        )
      ),
      list(
        type = ranked_types[[3]]$type,
        confidence = ranked_types[[3]]$score,
        reasoning = generate_classification_reasoning(
          ranked_types[[3]],
          element_name,
          context,
          i18n
        )
      )
    ),
    element_name = element_name,
    all_scores = final_scores
  )

  debug_log(paste0("Classification complete - Primary: ",
          result$primary$type, " (", round(result$primary$confidence * 100, 1), "%)"), "AI CLASSIFIER")

  return(result)
}


#' Match Keywords to DAPSIWRM Types
#'
#' Scores each DAPSIWRM type based on keyword matching
#'
#' @param element_name Element name to classify
#' @return Named list of scores (0-1) for each type
match_keywords_to_types <- function(element_name) {

  element_lower <- tolower(element_name)
  element_words <- strsplit(element_lower, "[\\s,.-]+")[[1]]

  scores <- list()

  for (type in names(DAPSIWRM_KEYWORDS)) {
    keywords <- DAPSIWRM_KEYWORDS[[type]]

    # Exact keyword matches (full words)
    exact_matches <- sum(keywords$primary %in% element_words)

    # Partial keyword matches (substring)
    partial_matches <- sum(sapply(keywords$primary, function(kw) {
      kw_lower <- tolower(kw)
      # Check if keyword is contained in element name
      grepl(kw_lower, element_lower, fixed = TRUE)
    }))

    # Pattern matches (regex)
    pattern_matches <- sum(sapply(keywords$patterns, function(pat) {
      grepl(pat, element_lower, ignore.case = TRUE)
    }))

    # Calculate score (0-1 scale)
    # Weighted: exact > partial > pattern
    raw_score <- (exact_matches * 2.0 +
                  partial_matches * 1.0 +
                  pattern_matches * 0.5)

    # Normalize to 0-1 range (max possible is ~10 for well-matching elements)
    scores[[type]] <- min(1.0, raw_score / 5.0)
  }

  return(scores)
}


#' Adjust Scores Based on Context
#'
#' Boosts scores for types that are commonly associated with the context
#'
#' @param scores Current scores for each type
#' @param context User's context (regional sea, ecosystem, main issue)
#' @return Adjusted scores
adjust_scores_by_context <- function(scores, context) {

  if (is.null(context) || is.null(context$main_issue)) {
    return(scores)
  }

  # Extract issue keywords
  issue_keywords <- extract_issue_keywords(context$main_issue)

  if (length(issue_keywords) == 0) {
    return(scores)
  }

  debug_log(paste0("Detected issue keywords: ", paste(issue_keywords, collapse = ", ")), "AI CLASSIFIER")

  # Apply context boosts
  for (type in names(scores)) {
    keywords_def <- DAPSIWRM_KEYWORDS[[type]]

    if (!is.null(keywords_def$context_boost)) {
      for (issue_kw in issue_keywords) {
        if (issue_kw %in% names(keywords_def$context_boost)) {
          # Boost score by 20%
          scores[[type]] <- min(1.0, scores[[type]] * 1.2)
          debug_log(paste0("Boosted ", type, " for context: ", issue_kw), "AI CLASSIFIER")
        }
      }
    }
  }

  # Context-specific adjustments
  main_issue_lower <- tolower(context$main_issue)

  # Eutrophication context
  if (grepl("eutroph|nutrient", main_issue_lower)) {
    scores$Pressures <- min(1.0, scores$Pressures * 1.3)
    scores$`Marine Processes & Functioning` <- min(1.0, scores$`Marine Processes & Functioning` * 1.1)
  }

  # Fishing context
  if (grepl("fish", main_issue_lower)) {
    scores$Activities <- min(1.0, scores$Activities * 1.2)
    scores$Pressures <- min(1.0, scores$Pressures * 1.1)
  }

  # Tourism context
  if (grepl("tourism|recreation", main_issue_lower)) {
    scores$Activities <- min(1.0, scores$Activities * 1.2)
    scores$Drivers <- min(1.0, scores$Drivers * 1.1)
  }

  # Normalize scores back to 0-1 range
  max_score <- max(unlist(scores))
  if (max_score > 1.0) {
    scores <- lapply(scores, function(s) s / max_score)
  }

  return(scores)
}


#' Apply Pattern Recognition
#'
#' Uses linguistic patterns to infer DAPSIWRM type
#'
#' @param element_name Element name to analyze
#' @return Named list of pattern-based scores
apply_pattern_recognition <- function(element_name) {

  element_lower <- tolower(element_name)
  scores <- list()

  # Initialize all types to 0
  for (type in names(DAPSIWRM_KEYWORDS)) {
    scores[[type]] <- 0.0
  }

  # Drivers patterns: "demand", "need", "growth", "security"
  if (grepl("demand|need|requirement|growth|security", element_lower)) {
    scores$Drivers <- scores$Drivers + 0.6
  }

  # Activities patterns: action verbs, "-ing" forms
  if (grepl("fishing|farming|shipping|construction|extraction|development|tourism", element_lower)) {
    scores$Activities <- scores$Activities + 0.7
  }

  # Pressures patterns: negative impacts, "pollution", "loss", "damage"
  if (grepl("pollution|contamination|enrichment|damage|loss|disturbance|erosion", element_lower)) {
    scores$Pressures <- scores$Pressures + 0.7
  }

  # State patterns: "population", "habitat", "water quality", "biodiversity"
  if (grepl("population|habitat|biodiversity|quality|abundance|biomass", element_lower)) {
    scores$`Marine Processes & Functioning` <- scores$`Marine Processes & Functioning` + 0.6
  }

  # Ecosystem Services patterns: "provision", "service", "function", "regulation"
  if (grepl("provision|service|function|regulation|sequestration|protection", element_lower)) {
    scores$`Ecosystem Services` <- scores$`Ecosystem Services` + 0.6
  }

  # Goods & Benefits patterns: "income", "welfare", "benefit", "health"
  if (grepl("income|welfare|benefit|revenue|employment|health|wellbeing", element_lower)) {
    scores$`Goods & Benefits` <- scores$`Goods & Benefits` + 0.6
  }

  # Responses patterns: "regulation", "policy", "MPA", "quota", "management"
  if (grepl("regulation|policy|management|MPA|quota|restriction|ban|limit|protection", element_lower)) {
    scores$Responses <- scores$Responses + 0.7
  }

  return(scores)
}


#' Combine Classification Scores
#'
#' Weighted combination of keyword and pattern scores
#'
#' @param keyword_scores Scores from keyword matching
#' @param pattern_scores Scores from pattern recognition
#' @param weights Named vector of weights (must sum to 1)
#' @return Combined scores
combine_classification_scores <- function(keyword_scores, pattern_scores,
                                          weights = c(keyword = 0.65, pattern = 0.35)) {

  if (abs(sum(weights) - 1.0) > 0.01) {
    debug_log(paste0("Weights do not sum to 1.0 (sum=", round(sum(weights), 3), "). Normalizing."), "AI CLASSIFIER")
    weights <- weights / sum(weights)
  }


  combined <- list()

  for (type in names(DAPSIWRM_KEYWORDS)) {
    combined[[type]] <- (keyword_scores[[type]] * weights["keyword"] +
                        pattern_scores[[type]] * weights["pattern"])
  }

  return(combined)
}


#' Rank DAPSIWRM Types by Score
#'
#' Sorts types by score and returns top candidates
#'
#' @param scores Named list of scores for each type
#' @param top_n Number of top types to return (default 3)
#' @return List of ranked types with scores
rank_dapsiwrm_types <- function(scores, top_n = 3) {

  # Convert to data frame for sorting
  df <- data.frame(
    type = names(scores),
    score = unlist(scores),
    stringsAsFactors = FALSE
  )

  # Sort by score descending
  df <- df[order(df$score, decreasing = TRUE), ]

  # Return top N as list
  result <- list()
  for (i in 1:min(top_n, nrow(df))) {
    result[[i]] <- list(
      type = df$type[i],
      score = df$score[i]
    )
  }

  return(result)
}


#' Generate Classification Reasoning
#'
#' Creates human-readable explanation for why element was classified as a type
#'
#' @param ranked_item List with type and score
#' @param element_name Original element name
#' @param context User's context
#' @param i18n Internationalization object
#' @return Character string with reasoning
generate_classification_reasoning <- function(ranked_item, element_name, context, i18n = NULL) {

  type <- ranked_item$type
  score <- ranked_item$score
  element_lower <- tolower(element_name)

  # Get keywords for this type
  keywords <- DAPSIWRM_KEYWORDS[[type]]

  # Find which keywords matched
  matched_keywords <- keywords$primary[sapply(keywords$primary, function(kw) {
    grepl(tolower(kw), element_lower, fixed = TRUE)
  })]

  # Build reasoning
  if (length(matched_keywords) > 0) {
    reason <- paste0(
      "Contains keywords associated with ", type, ": '",
      paste(head(matched_keywords, 2), collapse = "', '"), "'"
    )
  } else {
    # Pattern match
    reason <- paste0("Pattern matches ", type, " category")
  }

  # Add context if relevant
  if (!is.null(context) && !is.null(context$main_issue)) {
    issue_keywords <- extract_issue_keywords(context$main_issue)
    if (length(issue_keywords) > 0) {
      reason <- paste0(reason, ". Relevant to ", issue_keywords[1], " context")
    }
  }

  # Add confidence note
  if (score < 0.3) {
    reason <- paste0(reason, ". (Low confidence - consider alternatives)")
  } else if (score > 0.7) {
    reason <- paste0(reason, ". (High confidence)")
  }

  return(reason)
}


#' Suggest Alternative Types for Manual Override
#'
#' When user doesn't agree with primary classification, suggest relevant alternatives
#'
#' @param element_name Element name
#' @param exclude_type Type to exclude (the rejected suggestion)
#' @param context User's context
#' @return Character vector of alternative types
suggest_alternative_types <- function(element_name, exclude_type = NULL, context = NULL) {

  # Re-run classification
  result <- classify_element_with_ai(element_name, context)

  # Get all types sorted by score
  all_types <- names(sort(unlist(result$all_scores), decreasing = TRUE))

  # Remove excluded type
  if (!is.null(exclude_type)) {
    all_types <- setdiff(all_types, exclude_type)
  }

  # Return top 5
  return(head(all_types, 5))
}


#' Validate Classification Result
#'
#' Checks if classification result meets minimum confidence threshold
#'
#' @param classification_result Result from classify_element_with_ai
#' @param min_confidence Minimum confidence threshold (default 0.2)
#' @return TRUE if valid, FALSE otherwise
validate_classification <- function(classification_result, min_confidence = 0.2) {

  if (is.null(classification_result$primary)) {
    return(FALSE)
  }

  if (classification_result$primary$confidence < min_confidence) {
    debug_log(paste0("Warning: Low confidence classification (",
            round(classification_result$primary$confidence * 100, 1), "%)"), "AI CLASSIFIER")
    return(FALSE)
  }

  return(TRUE)
}


#' Get Confidence Level Label
#'
#' Converts numeric confidence to human-readable label
#'
#' @param confidence Confidence score (0-1)
#' @param i18n Internationalization object
#' @return Character string: "Very High", "High", "Medium", "Low", "Very Low"
get_confidence_label <- function(confidence, i18n = NULL) {

  if (confidence >= 0.8) {
    return("Very High")
  } else if (confidence >= 0.6) {
    return("High")
  } else if (confidence >= 0.4) {
    return("Medium")
  } else if (confidence >= 0.2) {
    return("Low")
  } else {
    return("Very Low")
  }
}
