# modules/graphical_ses_network_builder.R
# Network building logic for graphical SES creator
# Handles element suggestions, network state management, and ISA export

#' Suggest Connected Elements Based on DAPSIWRM Rules
#'
#' Main suggestion function that generates AI-powered element suggestions
#' for expanding the network from a selected node.
#'
#' @param node_id ID of node to expand from
#' @param node_data Data for the selected node (must include type and name)
#' @param existing_network Current network nodes dataframe
#' @param context User's context (regional_sea, ecosystem_type, main_issue)
#' @param max_suggestions Maximum number of suggestions to return
#' @return List of suggested elements with connection metadata
#' @export
suggest_connected_elements <- function(node_id, node_data, existing_network,
                                      context, max_suggestions = 5) {

  debug_log(paste0("Generating suggestions for node: ", node_data$name,
          " (", node_data$type, ")"), "NETWORK BUILDER")

  # Step 1: Get allowed target types based on DAPSIWRM rules
  allowed_targets <- get_allowed_targets(node_data$type)

  if (length(allowed_targets) == 0) {
    debug_log(paste0("No allowed targets for type: ", node_data$type), "NETWORK BUILDER")
    return(list())
  }

  debug_log(paste0("Allowed target types: ", paste(allowed_targets, collapse = ", ")), "NETWORK BUILDER")

  # Step 2: Get context-aware suggestions for each target type
  suggestions <- list()

  for (target_type in allowed_targets) {
    debug_log(paste0("Getting suggestions for target type: ", target_type), "NETWORK BUILDER")

    # Convert DAPSIWRM type to ISA category name
    category <- dapsiwrm_type_to_category(target_type)

    # Use existing knowledge base function to get context-aware suggestions
    context_suggestions <- tryCatch({
      get_context_suggestions(
        category = category,
        regional_sea = context$regional_sea %||% "",
        ecosystem_type = context$ecosystem_type %||% "",
        main_issue = context$main_issue %||% ""
      )
    }, error = function(e) {
      debug_log(paste0("Error getting suggestions: ", e$message), "NETWORK BUILDER")
      return(character(0))
    })

    # IMPROVEMENT 1: Add source-node-aware suggestions based on keywords
    source_aware_suggestions <- get_source_aware_suggestions(
      node_data$name,
      node_data$type,
      target_type,
      context
    )

    # Combine context suggestions with source-aware suggestions
    all_suggestions_for_type <- unique(c(context_suggestions, source_aware_suggestions))

    if (length(all_suggestions_for_type) == 0) {
      debug_log(paste0("No suggestions found for ", target_type), "NETWORK BUILDER")
      # IMPROVEMENT 2: Add generic fallbacks
      all_suggestions_for_type <- get_generic_fallback_suggestions(target_type)
      debug_log(paste0("Using ", length(all_suggestions_for_type), " generic fallbacks"), "NETWORK BUILDER")
    }

    # IMPROVEMENT 3: Smarter filtering - check both exact and semantic matches
    existing_names <- if (nrow(existing_network) > 0) existing_network$name else character(0)
    new_suggestions <- filter_existing_suggestions(all_suggestions_for_type, existing_names)

    if (length(new_suggestions) == 0) {
      debug_log(paste0("All suggestions already in network for ", target_type), "NETWORK BUILDER")
      next
    }

    debug_log(paste0("Found ", length(new_suggestions), " new suggestions for ", target_type), "NETWORK BUILDER")

    # IMPROVEMENT 4: Prioritize suggestions by relevance before taking top N
    prioritized_suggestions <- prioritize_suggestions_by_source(
      new_suggestions,
      node_data$name,
      node_data$type,
      target_type,
      context
    )

    # Take top 2-3 per target type (adaptive based on total suggestions)
    n_per_type <- min(3, max(2, ceiling(max_suggestions / length(allowed_targets))))
    top_suggestions <- head(prioritized_suggestions, n_per_type)

    for (suggestion_name in top_suggestions) {
      # Determine connection properties
      polarity <- infer_connection_polarity(
        node_data$name,
        suggestion_name,
        node_data$type,
        target_type
      )

      strength <- infer_connection_strength(
        node_data$name,
        suggestion_name,
        context
      )

      confidence <- get_connection_confidence(
        list(name = node_data$name, type = node_data$type),
        list(name = suggestion_name, type = target_type),
        context
      )

      suggestions[[length(suggestions) + 1]] <- list(
        name = suggestion_name,
        type = target_type,
        from_node = node_id,
        connection_polarity = polarity,
        connection_strength = strength,
        connection_confidence = confidence,
        reasoning = generate_suggestion_reasoning(
          node_data$name,
          suggestion_name,
          node_data$type,
          target_type,
          polarity,
          strength
        )
      )
    }
  }

  if (length(suggestions) == 0) {
    debug_log("No suggestions generated", "NETWORK BUILDER")
    return(list())
  }

  # Step 3: AI-POWERED ENHANCEMENTS

  # 3a. Analyze network topology and add strategic suggestions
  topology_suggestions <- analyze_network_topology_for_suggestions(
    node_id, node_data, existing_network, allowed_targets, context
  )
  suggestions <- c(suggestions, topology_suggestions)
  debug_log(paste0("Added ", length(topology_suggestions), " topology-based suggestions"), "NETWORK BUILDER")

  # 3b. Analyze causal chains and suggest completions
  chain_suggestions <- analyze_causal_chains_for_suggestions(
    node_id, node_data, existing_network, allowed_targets, context
  )
  suggestions <- c(suggestions, chain_suggestions)
  debug_log(paste0("Added ", length(chain_suggestions), " chain-completion suggestions"), "NETWORK BUILDER")

  # Step 3c: Deduplicate suggestions by element name
  # Keep the highest quality version of each element
  suggestions <- deduplicate_suggestion_objects(suggestions)
  debug_log(paste0("After deduplication: ", length(suggestions), " unique suggestions"), "NETWORK BUILDER")

  # Step 4: Rank suggestions by relevance (now with AI-enhanced scoring)
  ranked_suggestions <- rank_suggestions_by_relevance_advanced(
    suggestions, node_data, existing_network, context
  )

  # Step 5: Return top N
  final_suggestions <- head(ranked_suggestions, max_suggestions)

  debug_log(paste0("Returning ", length(final_suggestions), " suggestions"), "NETWORK BUILDER")

  return(final_suggestions)
}


#' Convert DAPSIWRM Type to ISA Category Name
#'
#' @param dapsiwrm_type DAPSIWRM type name
#' @return ISA category name for use with get_context_suggestions
dapsiwrm_type_to_category <- function(dapsiwrm_type) {
  mapping <- c(
    "Drivers" = "drivers",
    "Activities" = "activities",
    "Pressures" = "pressures",
    "Marine Processes & Functioning" = "states",  # Note: plural to match knowledge base
    "Ecosystem Services" = "impacts",  # Note: plural to match knowledge base
    "Goods & Benefits" = "welfare",
    "Responses" = "responses",
    "Management" = "management"
  )

  return(mapping[dapsiwrm_type] %||% tolower(dapsiwrm_type))
}


#' Generate Suggestion Reasoning
#'
#' Creates human-readable explanation for why an element was suggested
#'
#' @param from_name Source element name
#' @param to_name Suggested element name
#' @param from_type Source type
#' @param to_type Target type
#' @param polarity Connection polarity
#' @param strength Connection strength
#' @return Character string with reasoning
generate_suggestion_reasoning <- function(from_name, to_name, from_type,
                                         to_type, polarity, strength) {

  # Get connection description
  conn_desc <- get_connection_description(from_type, to_type)

  # Build reasoning
  polarity_word <- if (polarity == "+") "increases" else "decreases"
  strength_word <- if (strength == "strong") "strongly" else "moderately"

  reasoning <- paste0(
    from_type, " ", strength_word, " ", polarity_word, " ", to_type, ". ",
    "Suggested because ", conn_desc
  )

  return(reasoning)
}


#' Convert Graphical Network to ISA Data Structure
#'
#' Exports the graphical network into standard ISA format for integration
#' with the rest of the application.
#'
#' @param nodes Network nodes dataframe
#' @param edges Network edges dataframe
#' @param context User's context from wizard
#' @return ISA data structure
#' @export
convert_graphical_to_isa <- function(nodes, edges, context) {

  debug_log("Converting graphical network to ISA format", "ISA EXPORT")
  debug_log(paste0("Nodes: ", nrow(nodes), ", Edges: ", nrow(edges)), "ISA EXPORT")

  # Group nodes by DAPSIWRM type
  drivers <- nodes[nodes$type == "Drivers", ]
  activities <- nodes[nodes$type == "Activities", ]
  pressures <- nodes[nodes$type == "Pressures", ]
  marine_proc <- nodes[nodes$type == "Marine Processes & Functioning", ]
  eco_services <- nodes[nodes$type == "Ecosystem Services", ]
  goods_benefits <- nodes[nodes$type == "Goods & Benefits", ]
  responses <- nodes[nodes$type == "Responses", ]
  management <- nodes[nodes$type == "Management", ]

  # Create element dataframes for each category
  isa_data <- list(
    drivers = convert_nodes_to_element_df(drivers, "Drivers"),
    activities = convert_nodes_to_element_df(activities, "Activities"),
    pressures = convert_nodes_to_element_df(pressures, "Pressures"),
    state = convert_nodes_to_element_df(marine_proc, "State"),
    impact = convert_nodes_to_element_df(eco_services, "Impact"),
    welfare = convert_nodes_to_element_df(goods_benefits, "Welfare"),
    responses = convert_nodes_to_element_df(responses, "Responses"),
    management = convert_nodes_to_element_df(management, "Management")
  )

  # Create adjacency matrices from edges
  isa_data$adjacency_matrices <- create_adjacency_matrices_from_edges(
    edges, drivers, activities, pressures, marine_proc,
    eco_services, goods_benefits, responses, management
  )

  # Add metadata
  isa_data$metadata <- list(
    creation_method = "graphical_ses_creator",
    context = context,
    created_at = Sys.time(),
    node_count = nrow(nodes),
    edge_count = nrow(edges)
  )

  debug_log("Export complete", "ISA EXPORT")

  return(isa_data)
}


#' Convert Nodes to Element Dataframe
#'
#' Converts graphical network nodes to ISA element dataframe format
#'
#' @param nodes Subset of nodes for this type
#' @param type_name DAPSIWRM type name
#' @return Element dataframe
convert_nodes_to_element_df <- function(nodes, type_name) {

  if (nrow(nodes) == 0) {
    # Return empty dataframe with correct structure
    return(data.frame(
      id = character(0),
      name = character(0),
      indicator = character(0)
      
    ))
  }

  # Create element dataframe
  df <- data.frame(
    id = nodes$id,
    name = nodes$name,
    indicator = nodes$indicator %||% "",  # Optional indicator field
    
  )

  return(df)
}


#' Create Adjacency Matrices from Edges
#'
#' Converts edge list to adjacency matrices for each type pair
#'
#' @param edges Network edges dataframe
#' @param drivers, activities, ...: Node dataframes for each type
#' @return List of adjacency matrices
create_adjacency_matrices_from_edges <- function(edges, drivers, activities,
                                                 pressures, marine_proc,
                                                 eco_services, goods_benefits,
                                                 responses, management) {

  matrices <- list()

  # Helper function to create single matrix
  create_matrix <- function(source_nodes, target_nodes, source_type, target_type) {
    if (nrow(source_nodes) == 0 || nrow(target_nodes) == 0) {
      return(NULL)
    }

    # Filter edges for this type pair
    relevant_edges <- edges[
      edges$from %in% source_nodes$id &
      edges$to %in% target_nodes$id,
    ]

    if (nrow(relevant_edges) == 0) {
      return(NULL)
    }

    # Create empty matrix
    mat <- matrix(
      "",
      nrow = nrow(source_nodes),
      ncol = nrow(target_nodes),
      dimnames = list(source_nodes$name, target_nodes$name)
    )

    # Fill matrix with connection values
    for (i in seq_len(nrow(relevant_edges))) {
      edge <- relevant_edges[i, ]

      from_name <- source_nodes$name[source_nodes$id == edge$from]
      to_name <- target_nodes$name[target_nodes$id == edge$to]

      if (length(from_name) > 0 && length(to_name) > 0) {
        # Format: polarity|strength|confidence
        value <- paste0(
          edge$polarity, "|",
          edge$strength %||% "medium", "|",
          edge$confidence %||% "3"
        )

        mat[from_name, to_name] <- value
      }
    }

    return(mat)
  }

  # Create all standard DAPSIWRM matrices
  matrices$d_a <- create_matrix(drivers, activities, "Drivers", "Activities")
  matrices$a_p <- create_matrix(activities, pressures, "Activities", "Pressures")
  matrices$p_s <- create_matrix(pressures, marine_proc, "Pressures", "State")
  matrices$s_i <- create_matrix(marine_proc, eco_services, "State", "Impact")
  matrices$i_w <- create_matrix(eco_services, goods_benefits, "Impact", "Welfare")

  # Feedback loops
  matrices$w_d <- create_matrix(goods_benefits, drivers, "Welfare", "Drivers")
  matrices$w_r <- create_matrix(goods_benefits, responses, "Welfare", "Responses")

  # Response connections
  matrices$r_d <- create_matrix(responses, drivers, "Responses", "Drivers")
  matrices$r_a <- create_matrix(responses, activities, "Responses", "Activities")
  matrices$r_p <- create_matrix(responses, pressures, "Responses", "Pressures")
  matrices$r_s <- create_matrix(responses, marine_proc, "Responses", "State")

  # Management connections (if any)
  if (nrow(management) > 0) {
    matrices$m_r <- create_matrix(management, responses, "Management", "Responses")
  }

  # Remove NULL matrices
  matrices <- Filter(Negate(is.null), matrices)

  debug_log(paste0("Created ", length(matrices), " adjacency matrices"), "ISA EXPORT")

  return(matrices)
}


#' Validate Network Before Export
#'
#' Checks network for issues before converting to ISA
#'
#' @param nodes Network nodes
#' @param edges Network edges
#' @return List with is_valid flag and messages
#' @export
validate_network_for_export <- function(nodes, edges) {

  issues <- character(0)
  warnings <- character(0)

  # Check minimum network size
  if (nrow(nodes) < 2) {
    issues <- c(issues, "Network must have at least 2 nodes")
  }

  if (nrow(edges) < 1) {
    issues <- c(issues, "Network must have at least 1 connection")
  }

  # Check for isolated nodes
  connected_nodes <- unique(c(edges$from, edges$to))
  isolated <- setdiff(nodes$id, connected_nodes)

  if (length(isolated) > 0) {
    warnings <- c(warnings, paste0(
      "Warning: ", length(isolated), " isolated node(s) found"
    ))
  }

  # Check for invalid edges
  all_node_ids <- nodes$id
  invalid_from <- sum(!edges$from %in% all_node_ids)
  invalid_to <- sum(!edges$to %in% all_node_ids)

  if (invalid_from > 0 || invalid_to > 0) {
    issues <- c(issues, "Network has edges pointing to non-existent nodes")
  }

  # Check DAPSIWRM coverage
  types_present <- unique(nodes$type)
  dapsiwrm_types <- c("Drivers", "Activities", "Pressures",
                     "Marine Processes & Functioning", "Ecosystem Services",
                     "Goods & Benefits", "Responses")

  missing_types <- setdiff(dapsiwrm_types, types_present)

  if (length(missing_types) > 0) {
    warnings <- c(warnings, paste0(
      "Info: Network is missing types: ", paste(missing_types, collapse = ", ")
    ))
  }

  # Return validation result
  list(
    is_valid = length(issues) == 0,
    issues = issues,
    warnings = warnings
  )
}


#' Create Node ID
#'
#' Generates unique node ID based on type and index
#'
#' @param type DAPSIWRM type
#' @param index Node index (optional)
#' @return Unique node ID string
#' @export
create_graphical_node_id <- function(type, index = NULL) {
  prefix_map <- c(
    "Drivers" = "D",
    "Activities" = "A",
    "Pressures" = "P",
    "Marine Processes & Functioning" = "S",
    "Ecosystem Services" = "I",
    "Goods & Benefits" = "W",
    "Responses" = "R",
    "Management" = "M"
  )

  prefix <- prefix_map[type] %||% substr(type, 1, 1)

  if (is.null(index)) {
    # Generate random ID
    return(paste0(prefix, "_", format(Sys.time(), "%H%M%S"), "_",
                  sample(1000:9999, 1)))
  } else {
    return(paste0(prefix, "_", index))
  }
}


# ============================================================================
# IMPROVED SUGGESTION GENERATION FUNCTIONS
# ============================================================================

#' Get Source-Aware Suggestions
#'
#' Generate suggestions based on the source node's name and keywords
#'
#' @param source_name Name of source node
#' @param source_type Type of source node
#' @param target_type Type of target suggestions
#' @param context User context
#' @return Character vector of suggestions
get_source_aware_suggestions <- function(source_name, source_type, target_type, context) {
  suggestions <- character(0)
  source_lower <- tolower(source_name)

  # ACTIVITIES → PRESSURES mapping
  if (source_type == "Activities" && target_type == "Pressures") {
    # Fishing activities
    if (grepl("fish", source_lower)) {
      suggestions <- c(suggestions, "Overfishing", "Bycatch", "Seabed disturbance",
                      "Ghost fishing", "Habitat damage from trawling")
      # Add vessel-related pressures
      if (grepl("commercial|industrial", source_lower)) {
        suggestions <- c(suggestions, "Marine litter from fishing gear",
                        "Underwater noise from vessels", "Oil pollution from ships")
      }
    }
    # Aquaculture
    if (grepl("aquaculture|farm", source_lower)) {
      suggestions <- c(suggestions, "Nutrient enrichment", "Organic waste accumulation",
                      "Chemical contamination from treatments", "Genetic pollution",
                      "Disease transmission to wild populations")
    }
    # Shipping & maritime transport
    if (grepl("ship|transport|maritime|vessel|cargo", source_lower)) {
      suggestions <- c(suggestions, "Underwater noise pollution", "Oil spills",
                      "Marine litter", "Air pollution from ships", "Ballast water discharge",
                      "Ship strikes on marine mammals")
    }
    # Tourism & recreation
    if (grepl("tourism|recreation|diving|beach", source_lower)) {
      suggestions <- c(suggestions, "Physical disturbance to habitats",
                      "Marine litter", "Anchor damage", "Wildlife disturbance",
                      "Wastewater discharge")
    }
    # Coastal development & construction
    if (grepl("construction|development|dredg|reclaim", source_lower)) {
      suggestions <- c(suggestions, "Habitat loss", "Sedimentation",
                      "Physical disturbance", "Noise pollution", "Coastal squeeze")
    }
    # Energy (offshore wind, oil & gas)
    if (grepl("energy|wind|oil|gas|offshore|extract", source_lower)) {
      suggestions <- c(suggestions, "Underwater noise from construction",
                      "Electromagnetic fields", "Habitat modification",
                      "Chemical contamination", "Physical obstruction")
    }
    # Agriculture (coastal/watershed)
    if (grepl("agricult|farming|crop|livestock", source_lower)) {
      suggestions <- c(suggestions, "Nutrient enrichment from runoff",
                      "Pesticide contamination", "Sediment input", "Freshwater flow changes")
    }
  }

  # PRESSURES → STATE CHANGES mapping
  if (target_type == "Marine Processes & Functioning" || target_type == "Ecosystem Services") {
    # Common patterns for state changes
    if (grepl("fish", source_lower)) {
      suggestions <- c(suggestions, "Fish stock depletion", "Spawning habitat loss",
                      "Food web disruption", "Marine biodiversity loss")
    }
    if (grepl("nutrient|eutrophic|fertiliz|enrichment", source_lower)) {
      suggestions <- c(suggestions, "Algal blooms", "Oxygen depletion", "Water quality degradation",
                      "Seagrass decline", "Hypoxia")
    }
    if (grepl("pollution|waste|litter|contaminat", source_lower)) {
      suggestions <- c(suggestions, "Chemical contamination", "Plastic accumulation",
                      "Habitat degradation", "Species mortality", "Bioaccumulation of toxins")
    }
    if (grepl("habitat|physical|seabed|trawl", source_lower)) {
      suggestions <- c(suggestions, "Benthic habitat loss", "Seafloor damage",
                      "Ecosystem structure changes", "Loss of nursery grounds")
    }
    if (grepl("noise|acoustic|sound", source_lower)) {
      suggestions <- c(suggestions, "Marine mammal disturbance", "Fish behavior changes",
                      "Acoustic habitat degradation", "Disruption of communication")
    }
    if (grepl("climate|warming|acidif", source_lower)) {
      suggestions <- c(suggestions, "Coral bleaching", "Species range shifts",
                      "Phenology changes", "Ocean acidification impacts")
    }
    if (grepl("bycatch|species removal", source_lower)) {
      suggestions <- c(suggestions, "Non-target species decline", "Predator-prey imbalances",
                      "Population structure changes")
    }
  }

  return(unique(suggestions))
}


#' Get Generic Fallback Suggestions
#'
#' Provides generic fallback suggestions when context-specific ones aren't available
#'
#' @param target_type DAPSIWRM type for suggestions
#' @return Character vector of generic suggestions
get_generic_fallback_suggestions <- function(target_type) {
  fallbacks <- list(
    "Drivers" = c("Economic growth", "Population increase", "Food security", "Employment"),
    "Activities" = c("Fishing", "Shipping", "Coastal development", "Resource extraction"),
    "Pressures" = c("Habitat disturbance", "Species removal", "Contamination", "Physical changes"),
    "Marine Processes & Functioning" = c("Biodiversity changes", "Habitat quality decline",
                                         "Ecosystem function loss", "Species abundance changes"),
    "Ecosystem Services" = c("Provisioning services decline", "Regulating services loss",
                            "Cultural services degradation", "Supporting services changes"),
    "Goods & Benefits" = c("Income loss", "Food security impacts", "Recreation value decline",
                          "Cultural identity loss"),
    "Responses" = c("Management measures", "Policy interventions", "Restoration actions",
                   "Monitoring programs"),
    "Management" = c("Regulations", "Enforcement", "Stakeholder engagement", "Adaptive management")
  )

  return(fallbacks[[target_type]] %||% character(0))
}


#' Filter Existing Suggestions
#'
#' Smart filtering that checks both exact and semantic matches
#'
#' @param suggestions Character vector of suggestions
#' @param existing_names Character vector of existing node names
#' @return Filtered suggestions
filter_existing_suggestions <- function(suggestions, existing_names) {
  if (length(existing_names) == 0) {
    return(suggestions)
  }

  # Exact match filtering
  filtered <- setdiff(suggestions, existing_names)

  # Semantic similarity filtering (simple keyword overlap check)
  if (length(filtered) > 0 && length(existing_names) > 0) {
    filtered <- Filter(function(sug) {
      sug_words <- tolower(strsplit(sug, "[[:space:]]")[[1]])
      !any(sapply(existing_names, function(existing) {
        existing_words <- tolower(strsplit(existing, "[[:space:]]")[[1]])
        # Check if >70% of words overlap
        overlap <- sum(sug_words %in% existing_words)
        overlap / length(sug_words) > 0.7
      }))
    }, filtered)
  }

  return(filtered)
}


#' Deduplicate Suggestion Objects by Element Name
#'
#' When multiple suggestions have the same element name but different
#' connection properties (strength, polarity, etc.), this function keeps
#' only the highest quality version of each element.
#'
#' @param suggestions List of suggestion objects
#' @return Deduplicated list of suggestions
deduplicate_suggestion_objects <- function(suggestions) {
  if (length(suggestions) == 0) {
    return(suggestions)
  }

  # Group suggestions by element name
  names <- sapply(suggestions, function(s) s$name)
  unique_names <- unique(names)

  deduplicated <- lapply(unique_names, function(name) {
    # Get all suggestions for this element name
    same_name_suggestions <- suggestions[names == name]

    if (length(same_name_suggestions) == 1) {
      return(same_name_suggestions[[1]])
    }

    # Multiple suggestions for same name - pick the best one
    # Priority: highest confidence > highest strength > first occurrence
    best_idx <- 1
    best_confidence <- same_name_suggestions[[1]]$connection_confidence %||% 0
    best_strength <- same_name_suggestions[[1]]$connection_strength %||% "weak"

    for (i in seq_along(same_name_suggestions)[-1]) {
      curr_conf <- same_name_suggestions[[i]]$connection_confidence %||% 0
      curr_strength <- same_name_suggestions[[i]]$connection_strength %||% "weak"

      # Convert strength to numeric for comparison
      strength_to_num <- c("weak" = 1, "medium" = 2, "strong" = 3)
      best_strength_num <- strength_to_num[best_strength] %||% 1
      curr_strength_num <- strength_to_num[curr_strength] %||% 1

      # Pick suggestion with higher confidence, or higher strength if equal
      if (curr_conf > best_confidence ||
          (curr_conf == best_confidence && curr_strength_num > best_strength_num)) {
        best_idx <- i
        best_confidence <- curr_conf
        best_strength <- curr_strength
      }
    }

    return(same_name_suggestions[[best_idx]])
  })

  return(deduplicated)
}


#' Prioritize Suggestions by Source
#'
#' Ranks suggestions based on relevance to source node
#'
#' @param suggestions Character vector of suggestions
#' @param source_name Source node name
#' @param source_type Source node type
#' @param target_type Target type
#' @param context User context
#' @return Prioritized suggestions
prioritize_suggestions_by_source <- function(suggestions, source_name, source_type,
                                            target_type, context) {
  if (length(suggestions) == 0) {
    return(suggestions)
  }

  # Calculate relevance score for each suggestion
  scores <- sapply(suggestions, function(sug) {
    score <- 0
    source_lower <- tolower(source_name)
    sug_lower <- tolower(sug)

    # Keyword overlap boost
    source_words <- strsplit(source_lower, "[[:space:]]")[[1]]
    sug_words <- strsplit(sug_lower, "[[:space:]]")[[1]]
    common_words <- intersect(source_words, sug_words)
    score <- score + length(common_words) * 10

    # Context alignment boost
    if (!is.null(context$main_issue)) {
      issue_words <- tolower(strsplit(context$main_issue, "[[:space:]]")[[1]])
      issue_match <- sum(sug_words %in% issue_words)
      score <- score + issue_match * 15
    }

    # Specificity boost (prefer specific over generic)
    if (nchar(sug) > 20) score <- score + 5

    return(score)
  })

  # Sort by score descending
  ordered_indices <- order(scores, decreasing = TRUE)
  return(suggestions[ordered_indices])
}


# ============================================================================
# ADVANCED AI-POWERED SUGGESTION FUNCTIONS
# ============================================================================

#' Analyze Network Topology for Strategic Suggestions
#'
#' Identifies network gaps and suggests elements that would:
#' - Complete feedback loops
#' - Fill DAPSIWRM type gaps
#' - Create strategic connections
#'
#' @param node_id Current node ID
#' @param node_data Current node data
#' @param existing_network Existing nodes
#' @param allowed_targets Allowed target types
#' @param context User context
#' @return List of strategic suggestions
analyze_network_topology_for_suggestions <- function(node_id, node_data,
                                                     existing_network,
                                                     allowed_targets, context) {
  suggestions <- list()

  if (nrow(existing_network) == 0) {
    return(suggestions)  # Not enough network to analyze
  }

  # 1. COMPLETENESS ANALYSIS - Find missing DAPSIWRM types
  existing_types <- unique(existing_network$type)
  all_dapsiwrm_types <- c("Drivers", "Activities", "Pressures",
                          "Marine Processes & Functioning", "Ecosystem Services",
                          "Goods & Benefits", "Responses")

  missing_types <- setdiff(all_dapsiwrm_types, existing_types)

  # Prioritize missing types that are in allowed_targets
  priority_missing <- intersect(missing_types, allowed_targets)

  if (length(priority_missing) > 0) {
    debug_log(paste0("Detected missing types: ", paste(priority_missing, collapse = ", ")), "AI TOPOLOGY")

    for (missing_type in priority_missing) {
      # Get suggestions specifically for the missing type
      category <- dapsiwrm_type_to_category(missing_type)
      completeness_suggestions <- get_context_suggestions(
        category = category,
        regional_sea = context$regional_sea %||% "",
        ecosystem_type = context$ecosystem_type %||% "",
        main_issue = context$main_issue %||% ""
      )

      # Take top 2 for network completeness
      top_completeness <- head(completeness_suggestions, 2)

      for (sug_name in top_completeness) {
        suggestions[[length(suggestions) + 1]] <- list(
          name = sug_name,
          type = missing_type,
          from_node = node_id,
          connection_polarity = infer_connection_polarity(
            node_data$name, sug_name, node_data$type, missing_type
          ),
          connection_strength = "medium",
          connection_confidence = 0.75,
          reasoning = paste0("Completes network structure (adds missing ",
                           missing_type, " type)"),
          strategy_tag = "COMPLETENESS"
        )
      }
    }
  }

  # 2. FEEDBACK LOOP OPPORTUNITIES
  # Check if adding a connection to an existing node would create a feedback loop
  if (nrow(existing_network) >= 2) {
    loop_opportunities <- identify_loop_opportunities(
      node_data, existing_network, allowed_targets
    )

    for (loop_opp in loop_opportunities) {
      suggestions[[length(suggestions) + 1]] <- list(
        name = loop_opp$target_name,
        type = loop_opp$target_type,
        from_node = node_id,
        connection_polarity = loop_opp$polarity,
        connection_strength = "strong",
        connection_confidence = 0.85,
        reasoning = paste0("Creates ", loop_opp$loop_type, " feedback loop"),
        strategy_tag = "FEEDBACK_LOOP"
      )
    }
  }

  debug_log(paste0("Generated ", length(suggestions), " strategic suggestions"), "AI TOPOLOGY")
  return(suggestions)
}


#' Identify Feedback Loop Opportunities
#'
#' Detects potential feedback loops if current node connects to existing nodes
#'
#' @param node_data Current node data
#' @param existing_network Existing network
#' @param allowed_targets Allowed target types
#' @return List of loop opportunities
identify_loop_opportunities <- function(node_data, existing_network, allowed_targets) {
  opportunities <- list()

  # Simple heuristic: Suggest connecting to existing nodes of allowed types
  # that have a path back to the current node's type

  # DAPSIWRM cycle: D -> A -> P -> S -> I -> W -> R -> (D or A or P)
  cycle_map <- list(
    "Drivers" = c("Drivers"),  # Self-loop via R
    "Activities" = c("Activities", "Drivers"),  # Loop via R
    "Pressures" = c("Pressures", "Activities", "Drivers"),  # Loop via R
    "Marine Processes & Functioning" = c("Marine Processes & Functioning"),  # Via responses
    "Ecosystem Services" = c("Ecosystem Services"),
    "Goods & Benefits" = c("Drivers"),  # Strong feedback: Benefits drive new demands
    "Responses" = c("Drivers", "Activities", "Pressures")  # Responses affect multiple
  )

  # Check which existing nodes could create loops
  potential_loop_targets <- existing_network[existing_network$type %in% cycle_map[[node_data$type]], ]

  if (nrow(potential_loop_targets) > 0) {
    # Filter to only allowed target types
    valid_targets <- potential_loop_targets[potential_loop_targets$type %in% allowed_targets, ]

    if (nrow(valid_targets) > 0) {
      # Take top 1-2 for feedback loops
      for (i in seq_len(min(2, nrow(valid_targets)))) {
        target <- valid_targets[i, ]

        loop_type <- if (target$type == node_data$type) {
          "reinforcing"
        } else if (target$type %in% c("Responses", "Management")) {
          "balancing"
        } else {
          "reinforcing"
        }

        opportunities[[length(opportunities) + 1]] <- list(
          target_name = target$name,
          target_type = target$type,
          polarity = if (loop_type == "balancing") "-" else "+",
          loop_type = loop_type
        )
      }
    }
  }

  return(opportunities)
}


#' Analyze Causal Chains for Completion Suggestions
#'
#' Traces causal chains in the network and suggests elements that would
#' complete logical pathways through the DAPSIWRM framework
#'
#' @param node_id Current node ID
#' @param node_data Current node data
#' @param existing_network Existing network
#' @param allowed_targets Allowed target types
#' @param context User context
#' @return List of chain-completion suggestions
analyze_causal_chains_for_suggestions <- function(node_id, node_data,
                                                  existing_network,
                                                  allowed_targets, context) {
  suggestions <- list()

  if (nrow(existing_network) == 0) {
    return(suggestions)
  }

  # Analyze what types exist in the network
  existing_types <- unique(existing_network$type)

  # Define the ideal DAPSIWRM causal chain
  ideal_chain <- c("Drivers", "Activities", "Pressures",
                   "Marine Processes & Functioning", "Ecosystem Services",
                   "Goods & Benefits", "Responses")

  # Find the position of current node type in the chain
  current_position <- which(ideal_chain == node_data$type)

  if (length(current_position) == 0) {
    return(suggestions)
  }

  # 1. FORWARD CHAIN COMPLETION
  # Check if there are gaps in the forward chain
  if (current_position < length(ideal_chain)) {
    next_positions <- (current_position + 1):length(ideal_chain)
    forward_chain_types <- ideal_chain[next_positions]

    # Find missing types in forward chain that are in allowed targets
    missing_forward <- intersect(
      setdiff(forward_chain_types, existing_types),
      allowed_targets
    )

    if (length(missing_forward) > 0) {
      debug_log(paste0("Forward chain gaps detected: ", paste(missing_forward, collapse = ", ")), "AI CHAIN")

      # Suggest elements for the immediate next step
      immediate_next <- missing_forward[1]
      category <- dapsiwrm_type_to_category(immediate_next)

      # Get context-specific suggestions
      chain_suggestions <- get_context_suggestions(
        category = category,
        regional_sea = context$regional_sea %||% "",
        ecosystem_type = context$ecosystem_type %||% "",
        main_issue = context$main_issue %||% ""
      )

      # Also use source-aware suggestions for better alignment
      source_suggestions <- get_source_aware_suggestions(
        node_data$name, node_data$type, immediate_next, context
      )

      combined <- unique(c(chain_suggestions, source_suggestions))

      # Take top 2 chain-completion suggestions
      for (sug_name in head(combined, 2)) {
        suggestions[[length(suggestions) + 1]] <- list(
          name = sug_name,
          type = immediate_next,
          from_node = node_id,
          connection_polarity = infer_connection_polarity(
            node_data$name, sug_name, node_data$type, immediate_next
          ),
          connection_strength = "strong",
          connection_confidence = 0.80,
          reasoning = paste0("Completes causal chain (", node_data$type,
                           " → ", immediate_next, ")"),
          strategy_tag = "CHAIN_COMPLETION"
        )
      }
    }
  }

  # 2. MULTI-HOP REASONING
  # If there are elements several steps ahead, suggest intermediate connections
  if (current_position < length(ideal_chain) - 1) {
    # Check if there are nodes 2+ steps ahead
    future_positions <- (current_position + 2):length(ideal_chain)
    if (length(future_positions) > 0) {
      future_types <- ideal_chain[future_positions]
      existing_future <- intersect(future_types, existing_types)

      if (length(existing_future) > 0) {
        # There are nodes ahead - suggest bridge elements
        bridge_type <- ideal_chain[current_position + 1]

        if (bridge_type %in% allowed_targets) {
          debug_log(paste0("Multi-hop opportunity detected via ", bridge_type), "AI CHAIN")

          # Get bridge suggestions
          category <- dapsiwrm_type_to_category(bridge_type)
          bridge_suggestions <- get_context_suggestions(
            category = category,
            regional_sea = context$regional_sea %||% "",
            ecosystem_type = context$ecosystem_type %||% "",
            main_issue = context$main_issue %||% ""
          )

          for (sug_name in head(bridge_suggestions, 1)) {
            suggestions[[length(suggestions) + 1]] <- list(
              name = sug_name,
              type = bridge_type,
              from_node = node_id,
              connection_polarity = infer_connection_polarity(
                node_data$name, sug_name, node_data$type, bridge_type
              ),
              connection_strength = "medium",
              connection_confidence = 0.70,
              reasoning = paste0("Bridges gap to existing ", existing_future[1], " elements"),
              strategy_tag = "BRIDGE"
            )
          }
        }
      }
    }
  }

  debug_log(paste0("Generated ", length(suggestions), " chain-based suggestions"), "AI CHAIN")
  return(suggestions)
}


#' Advanced Ranking with AI-Powered Scoring
#'
#' Enhanced version of rank_suggestions_by_relevance with strategic scoring
#'
#' @param suggestions List of all suggestions
#' @param node_data Source node data
#' @param existing_network Existing network
#' @param context User context
#' @return Ranked suggestions
rank_suggestions_by_relevance_advanced <- function(suggestions, node_data,
                                                   existing_network, context) {
  if (length(suggestions) == 0) {
    return(suggestions)
  }

  # Calculate comprehensive relevance score
  scored_suggestions <- lapply(suggestions, function(sug) {
    score <- 50  # Base score

    # Strategy tag bonuses (AI-suggested get priority)
    if (!is.null(sug$strategy_tag)) {
      if (sug$strategy_tag == "FEEDBACK_LOOP") score <- score + 30
      if (sug$strategy_tag == "COMPLETENESS") score <- score + 25
      if (sug$strategy_tag == "CHAIN_COMPLETION") score <- score + 20
      if (sug$strategy_tag == "BRIDGE") score <- score + 15
    }

    # Connection confidence bonus
    if (!is.null(sug$connection_confidence)) {
      score <- score + (sug$connection_confidence * 20)
    }

    # Connection strength bonus
    if (!is.null(sug$connection_strength)) {
      if (sug$connection_strength == "strong") score <- score + 15
      if (sug$connection_strength == "medium") score <- score + 10
      if (sug$connection_strength == "weak") score <- score + 5
    }

    # Keyword overlap with source node
    source_words <- tolower(strsplit(node_data$name, "[[:space:]]")[[1]])
    sug_words <- tolower(strsplit(sug$name, "[[:space:]]")[[1]])
    common_words <- intersect(source_words, sug_words)
    score <- score + length(common_words) * 8

    # Context alignment
    if (!is.null(context$main_issue)) {
      issue_words <- tolower(strsplit(context$main_issue, "[[:space:]]")[[1]])
      issue_match <- sum(sug_words %in% issue_words)
      score <- score + issue_match * 12
    }

    # Specificity (prefer detailed over generic)
    if (nchar(sug$name) > 25) score <- score + 8

    # Diversity bonus (prefer variety in types)
    existing_types <- if (nrow(existing_network) > 0) {
      table(existing_network$type)
    } else {
      numeric(0)
    }

    if (length(existing_types) > 0 && sug$type %in% names(existing_types)) {
      # Penalize types already well-represented
      if (existing_types[sug$type] > 3) score <- score - 10
    }

    sug$ai_score <- score
    return(sug)
  })

  # Sort by AI score descending
  scores <- sapply(scored_suggestions, function(s) s$ai_score %||% 0)
  ordered_indices <- order(scores, decreasing = TRUE)

  return(scored_suggestions[ordered_indices])
}
