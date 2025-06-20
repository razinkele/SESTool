# utils.R - Intelligent Node Group Assignment for SES Tool
# Complete AI-powered classification system for Social-Ecological Systems
# This file contains functions for automatically assigning nodes to SES groups
# based on intelligent keyword matching and marine science domain knowledge

# Load required libraries
if (!require("stringdist")) {
  install.packages("stringdist")
  library(stringdist)
}
if (!require("dplyr")) {
  install.packages("dplyr") 
  library(dplyr)
}

# Define SES Groups and their characteristics
SES_GROUPS <- c(
  "Marine processes",
  "Pressures", 
  "Ecosystem Services",
  "Societal Goods and Benefits",
  "Activities",
  "Drivers"
)

# Comprehensive keyword dictionaries for each SES group
# Based on marine science literature and expert knowledge
SES_KEYWORDS <- list(
  "Marine processes" = list(
    primary = c(
      # Physical oceanography
      "ocean", "marine", "sea", "coastal", "tide", "current", "wave", "circulation",
      "upwelling", "downwelling", "thermocline", "halocline", "pycnocline",
      "salinity", "temperature", "density", "stratification", "mixing",
      "ph", "acidity", "alkalinity", "oxygen", "hypoxia", "anoxia",
      
      # Biological processes
      "phytoplankton", "zooplankton", "bacterioplankton", "picoplankton",
      "primary production", "secondary production", "productivity",
      "photosynthesis", "respiration", "decomposition", "mineralization",
      "nutrient cycling", "nitrogen cycle", "carbon cycle", "phosphorus cycle",
      "food web", "food chain", "trophic", "predation", "grazing",
      "biodiversity", "species richness", "abundance", "biomass",
      "recruitment", "spawning", "reproduction", "larval", "juvenile",
      "migration", "dispersal", "connectivity", "gene flow",
      
      # Habitat and ecosystem processes
      "habitat", "ecosystem", "community", "population", "species",
      "coral reef", "kelp forest", "seagrass", "mangrove", "salt marsh",
      "estuary", "lagoon", "wetland", "intertidal", "subtidal",
      "benthic", "pelagic", "demersal", "epipelagic", "mesopelagic",
      "sedimentation", "erosion", "accretion", "bioturbation",
      "calcification", "dissolution", "bleaching", "succession"
    ),
    secondary = c(
      "biological", "ecological", "natural", "environmental", "biotic",
      "abiotic", "physical", "chemical", "geological", "hydrological",
      "biogeochemical", "ecosystem functioning", "ecological process"
    )
  ),
  
  "Pressures" = list(
    primary = c(
      # Pollution
      "pollution", "contamination", "toxic", "toxicity", "chemical pollution",
      "plastic", "microplastic", "nanoplastic", "marine litter", "debris",
      "oil spill", "petroleum", "hydrocarbon", "heavy metals", "pesticide",
      "sewage", "wastewater", "runoff", "effluent", "discharge",
      "eutrophication", "nutrient pollution", "algal bloom", "red tide",
      "hypoxia", "dead zone", "oxygen depletion",
      
      # Climate change
      "climate change", "global warming", "ocean warming", "sea level rise",
      "ocean acidification", "ph decline", "carbonate chemistry",
      "sea ice loss", "ice sheet melting", "thermal expansion",
      "extreme weather", "storm intensity", "hurricane", "cyclone",
      "heat wave", "marine heatwave", "temperature anomaly",
      
      # Fishing and harvesting
      "overfishing", "fishing pressure", "overexploitation", "overharvesting",
      "illegal fishing", "unreported fishing", "unregulated fishing",
      "bycatch", "discards", "ghost fishing", "fishing gear",
      "bottom trawling", "dredging", "destructive fishing",
      
      # Habitat destruction
      "habitat destruction", "habitat loss", "habitat degradation",
      "habitat fragmentation", "coastal development", "urbanization",
      "land reclamation", "dredging", "mining", "extraction",
      "deforestation", "mangrove loss", "wetland loss", "coral destruction",
      
      # Invasive species and disease
      "invasive species", "alien species", "non-native species", "introduced species",
      "biological invasion", "biofouling", "ballast water",
      "disease", "pathogen", "virus", "bacteria", "parasite",
      "epidemic", "epizootic", "mortality event", "mass mortality",
      
      # Physical disturbance
      "noise pollution", "acoustic pollution", "ship noise", "sonar",
      "light pollution", "artificial light", "boat strike", "ship strike",
      "anchor damage", "propeller damage", "trampling", "disturbance"
    ),
    secondary = c(
      "stress", "stressor", "impact", "threat", "risk", "damage", "harm",
      "degradation", "decline", "loss", "reduction", "depletion",
      "human impact", "anthropogenic", "human-induced", "man-made"
    )
  ),
  
  "Ecosystem Services" = list(
    primary = c(
      # Provisioning services
      "provisioning", "fish production", "seafood", "fisheries", "aquaculture",
      "food provision", "protein", "nutrition", "marine food",
      "raw materials", "bioprospecting", "pharmaceuticals", "biotechnology",
      "genetic resources", "ornamental resources", "aquarium trade",
      "salt production", "seaweed harvesting", "algae cultivation",
      
      # Regulating services
      "regulating", "climate regulation", "carbon sequestration", "carbon storage",
      "oxygen production", "air purification", "atmosphere regulation",
      "water purification", "water filtration", "detoxification", "bioremediation",
      "waste treatment", "nutrient cycling", "decomposition",
      "coastal protection", "erosion control", "storm protection", "wave attenuation",
      "flood control", "natural barriers", "shoreline stabilization",
      "disease control", "pest control", "biological control",
      
      # Supporting services
      "supporting", "primary production", "photosynthesis", "nutrient cycling",
      "habitat provision", "nursery areas", "breeding grounds", "spawning areas",
      "migration routes", "corridors", "connectivity", "dispersal",
      "biodiversity maintenance", "species conservation", "genetic diversity",
      "evolutionary processes", "adaptation", "resilience",
      
      # Cultural services
      "cultural", "recreational", "tourism", "ecotourism", "whale watching",
      "diving", "snorkeling", "fishing recreation", "boating", "sailing",
      "aesthetic", "scenic beauty", "landscape", "seascape", "natural beauty",
      "spiritual", "religious", "sacred sites", "cultural sites",
      "traditional", "indigenous", "cultural heritage", "traditional knowledge",
      "education", "research", "scientific value", "learning", "inspiration"
    ),
    secondary = c(
      "service", "function", "benefit", "provision", "regulation",
      "support", "maintenance", "production", "protection", "value",
      "natural capital", "ecosystem function", "ecological service"
    )
  ),
  
  "Societal Goods and Benefits" = list(
    primary = c(
      # Food security and nutrition
      "food security", "food safety", "nutrition", "protein source", "dietary",
      "malnutrition", "hunger", "food supply", "food system", "subsistence",
      "artisanal fishing", "small-scale fishing", "traditional fishing",
      
      # Economic benefits
      "livelihood", "income", "employment", "jobs", "occupation", "career",
      "economic value", "market value", "commercial value", "trade",
      "export", "import", "revenue", "profit", "economic growth",
      "poverty reduction", "economic development", "wealth", "prosperity",
      "cost-benefit", "economic efficiency", "productivity",
      
      # Social and cultural benefits
      "recreation", "tourism", "leisure", "entertainment", "hobby",
      "sport fishing", "recreational fishing", "beach tourism", "cruise tourism",
      "aesthetic value", "scenic value", "natural beauty", "landscape value",
      "cultural value", "spiritual value", "religious value", "sacred value",
      "traditional value", "indigenous value", "heritage value", "identity",
      "social cohesion", "community", "social capital", "cultural identity",
      "traditional knowledge", "local knowledge", "indigenous knowledge",
      
      # Health and wellbeing
      "health", "wellbeing", "mental health", "physical health", "therapeutic",
      "quality of life", "life satisfaction", "happiness", "stress relief",
      "air quality", "water quality", "environmental health", "public health",
      
      # Education and research
      "education", "research", "science", "knowledge", "learning", "teaching",
      "awareness", "environmental education", "marine education", "outreach",
      "capacity building", "training", "skill development",
      
      # Property and infrastructure
      "property value", "real estate", "coastal property", "waterfront property",
      "infrastructure", "coastal infrastructure", "port", "harbor", "marina"
    ),
    secondary = c(
      "human welfare", "social", "economic", "cultural", "benefit",
      "value", "good", "commodity", "resource", "capital", "asset",
      "human wellbeing", "social benefit", "economic benefit", "public good"
    )
  ),
  
  "Activities" = list(
    primary = c(
      # Fishing and aquaculture
      "fishing", "commercial fishing", "industrial fishing", "artisanal fishing",
      "recreational fishing", "sport fishing", "subsistence fishing",
      "aquaculture", "mariculture", "fish farming", "shellfish farming",
      "seaweed farming", "pearl cultivation", "cage farming", "pond culture",
      
      # Shipping and transport
      "shipping", "maritime transport", "cargo transport", "container shipping",
      "bulk shipping", "tanker transport", "ferry", "passenger transport",
      "navigation", "port operation", "harbor activity", "loading", "unloading",
      "ballast water", "ship maintenance", "vessel operation",
      
      # Tourism and recreation
      "tourism", "marine tourism", "coastal tourism", "cruise tourism",
      "ecotourism", "whale watching", "dolphin watching", "shark tourism",
      "diving", "scuba diving", "snorkeling", "underwater tourism",
      "recreational boating", "sailing", "yachting", "water sports",
      "surfing", "windsurfing", "kitesurfing", "jet skiing",
      "beach recreation", "coastal recreation", "swimming", "beach walking",
      
      # Coastal development
      "coastal development", "waterfront development", "marina development",
      "resort development", "hotel construction", "residential development",
      "commercial development", "infrastructure development",
      "port construction", "harbor construction", "breakwater construction",
      "seawall construction", "pier construction", "jetty construction",
      
      # Industrial activities
      "dredging", "sand mining", "gravel extraction", "mineral extraction",
      "offshore mining", "deep sea mining", "oil drilling", "gas drilling",
      "offshore oil", "offshore gas", "petroleum exploration",
      "renewable energy", "offshore wind", "wind farm", "tidal energy",
      "wave energy", "ocean thermal energy", "solar energy",
      
      # Water management
      "desalination", "water treatment", "wastewater treatment",
      "coastal engineering", "beach nourishment", "shoreline modification",
      "land reclamation", "artificial reef", "restoration project",
      
      # Military and security
      "military activity", "naval operation", "coast guard", "patrol",
      "surveillance", "security operation", "defense activity",
      
      # Research and monitoring
      "research activity", "monitoring", "survey", "sampling", "data collection",
      "scientific expedition", "oceanographic research", "marine research"
    ),
    secondary = c(
      "activity", "operation", "practice", "use", "utilization", "exploitation",
      "development", "management", "intervention", "action", "industry",
      "sector", "business", "enterprise", "human activity", "anthropogenic activity"
    )
  ),
  
  "Drivers" = list(
    primary = c(
      # Demographic drivers
      "population growth", "population increase", "demographic change",
      "urbanization", "migration", "rural-urban migration", "coastal migration",
      "population density", "demographic transition", "aging population",
      
      # Economic drivers
      "economic growth", "gdp", "gdp growth", "economic development",
      "industrialization", "economic expansion", "economic policy",
      "globalization", "global trade", "international trade", "free trade",
      "market liberalization", "economic integration", "financial crisis",
      "recession", "economic boom", "commodity prices", "fuel prices",
      
      # Technological drivers
      "technology", "technological change", "innovation", "technological development",
      "automation", "digitalization", "artificial intelligence", "robotics",
      "biotechnology", "genetic engineering", "nanotechnology",
      "communication technology", "information technology", "internet",
      "fishing technology", "aquaculture technology", "shipping technology",
      
      # Policy and governance drivers
      "policy", "government policy", "public policy", "environmental policy",
      "fisheries policy", "maritime policy", "coastal policy", "ocean policy",
      "governance", "regulation", "legislation", "law", "legal framework",
      "institutional change", "policy reform", "deregulation", "privatization",
      "international agreement", "treaty", "convention", "protocol",
      "management", "resource management", "ecosystem management",
      "integrated management", "adaptive management", "precautionary approach",
      
      # Social and cultural drivers
      "social change", "cultural change", "lifestyle change", "behavior change",
      "consumption patterns", "consumer demand", "market demand",
      "social values", "environmental awareness", "conservation awareness",
      "education", "knowledge", "capacity", "institutional capacity",
      "social capital", "cultural values", "traditional practices",
      
      # Environmental and climate drivers
      "climate change", "global warming", "natural variability",
      "environmental change", "ecosystem change", "habitat change",
      "species invasion", "disease outbreak", "natural disaster",
      "extreme events", "environmental degradation", "pollution",
      
      # Market and trade drivers
      "market", "market forces", "supply and demand", "price", "cost",
      "subsidies", "incentives", "economic incentives", "market mechanisms",
      "certification", "eco-labeling", "sustainable sourcing", "green markets",
      "investment", "financing", "funding", "capital", "credit"
    ),
    secondary = c(
      "driver", "driving force", "force", "factor", "influence", "pressure",
      "determinant", "cause", "underlying cause", "root cause",
      "change", "trend", "pattern", "dynamic", "process", "mechanism",
      "external factor", "internal factor", "socioeconomic factor"
    )
  )
)

# Weights for different matching methods
MATCHING_WEIGHTS <- list(
  exact_primary = 10,
  exact_secondary = 7,
  fuzzy_primary = 8,
  fuzzy_secondary = 5,
  partial_primary = 6,
  partial_secondary = 3
)

# Function to clean and normalize text for matching
normalize_text <- function(text) {
  if (is.na(text) || is.null(text)) return("")
  
  text %>%
    as.character() %>%
    tolower() %>%                    # Convert to lowercase
    gsub("[^a-z0-9\\s]", " ", .) %>%  # Remove special characters
    gsub("\\s+", " ", .) %>%          # Collapse multiple spaces
    trimws()                          # Trim whitespace
}

# Function to extract meaningful words (remove common stop words)
extract_keywords <- function(text) {
  stop_words <- c("the", "and", "or", "but", "in", "on", "at", "to", "for", 
                  "of", "with", "by", "from", "up", "about", "into", "through", 
                  "during", "before", "after", "above", "below", "between", "among",
                  "is", "are", "was", "were", "be", "been", "being", "have", "has",
                  "had", "do", "does", "did", "will", "would", "could", "should",
                  "may", "might", "can", "must", "shall", "a", "an", "this", "that",
                  "these", "those", "i", "you", "he", "she", "it", "we", "they",
                  "me", "him", "her", "us", "them", "my", "your", "his", "her",
                  "its", "our", "their")
  
  words <- unlist(strsplit(normalize_text(text), "\\s+"))
  words <- words[!words %in% stop_words & nchar(words) > 2]
  words[words != ""]
}

# Function to calculate fuzzy match score
fuzzy_match_score <- function(text1, text2, method = "jw") {
  if (is.na(text1) || is.na(text2) || text1 == "" || text2 == "") return(0)
  
  # Jaro-Winkler distance (returns similarity, not distance)
  similarity <- 1 - stringdist(normalize_text(text1), normalize_text(text2), method = method)
  return(max(0, min(1, similarity)))  # Ensure between 0 and 1
}

# Function to check for partial matches
partial_match <- function(text, keywords) {
  if (is.na(text) || text == "") return(character(0))
  
  normalized_text <- normalize_text(text)
  matches <- sapply(keywords, function(keyword) {
    normalized_keyword <- normalize_text(keyword)
    grepl(normalized_keyword, normalized_text, fixed = TRUE) ||
    grepl(normalized_text, normalized_keyword, fixed = TRUE)
  })
  keywords[matches]
}

# Main function to assign group to a single node
assign_node_group <- function(node_name, description = "", confidence_threshold = 0.6) {
  # Input validation
  if (is.na(node_name) || is.null(node_name)) {
    return(list(
      group = "Unclassified",
      confidence = 0,
      score = 0,
      all_scores = setNames(rep(0, length(SES_GROUPS)), SES_GROUPS)
    ))
  }
  
  # Combine node name and description for analysis
  full_text <- paste(as.character(node_name), as.character(description), sep = " ")
  
  # Initialize scoring matrix
  scores <- setNames(rep(0, length(SES_GROUPS)), SES_GROUPS)
  
  # Extract keywords from the node text
  node_keywords <- extract_keywords(full_text)
  
  if (length(node_keywords) == 0) {
    return(list(
      group = "Unclassified",
      confidence = 0,
      score = 0,
      all_scores = scores
    ))
  }
  
  # Score each group
  for (group in SES_GROUPS) {
    group_score <- 0
    primary_keywords <- SES_KEYWORDS[[group]]$primary
    secondary_keywords <- SES_KEYWORDS[[group]]$secondary
    
    # 1. Exact matches with primary keywords
    exact_primary <- intersect(node_keywords, normalize_text(primary_keywords))
    group_score <- group_score + length(exact_primary) * MATCHING_WEIGHTS$exact_primary
    
    # 2. Exact matches with secondary keywords
    exact_secondary <- intersect(node_keywords, normalize_text(secondary_keywords))
    group_score <- group_score + length(exact_secondary) * MATCHING_WEIGHTS$exact_secondary
    
    # 3. Fuzzy matches with primary keywords
    for (keyword in node_keywords) {
      fuzzy_scores_primary <- sapply(primary_keywords, function(pk) fuzzy_match_score(keyword, pk))
      best_fuzzy_primary <- max(fuzzy_scores_primary, na.rm = TRUE)
      if (!is.na(best_fuzzy_primary) && best_fuzzy_primary > 0.8) {
        group_score <- group_score + best_fuzzy_primary * MATCHING_WEIGHTS$fuzzy_primary
      }
    }
    
    # 4. Fuzzy matches with secondary keywords
    for (keyword in node_keywords) {
      fuzzy_scores_secondary <- sapply(secondary_keywords, function(sk) fuzzy_match_score(keyword, sk))
      best_fuzzy_secondary <- max(fuzzy_scores_secondary, na.rm = TRUE)
      if (!is.na(best_fuzzy_secondary) && best_fuzzy_secondary > 0.8) {
        group_score <- group_score + best_fuzzy_secondary * MATCHING_WEIGHTS$fuzzy_secondary
      }
    }
    
    # 5. Partial matches with primary keywords
    partial_primary <- partial_match(full_text, primary_keywords)
    group_score <- group_score + length(partial_primary) * MATCHING_WEIGHTS$partial_primary
    
    # 6. Partial matches with secondary keywords
    partial_secondary <- partial_match(full_text, secondary_keywords)
    group_score <- group_score + length(partial_secondary) * MATCHING_WEIGHTS$partial_secondary
    
    scores[group] <- group_score
  }
  
  # Find the best match
  best_score <- max(scores, na.rm = TRUE)
  best_group_idx <- which.max(scores)
  best_group <- names(scores)[best_group_idx]
  
  # Calculate confidence (normalize score by text complexity and max possible score)
  text_length <- length(node_keywords)
  max_possible_score <- text_length * MATCHING_WEIGHTS$exact_primary
  confidence <- if (max_possible_score > 0) {
    min(1, best_score / max_possible_score)
  } else {
    0
  }
  
  # Apply confidence boost for very specific matches
  if (best_score > 0) {
    # Boost confidence if there are multiple types of matches
    match_types <- sum(c(
      length(intersect(node_keywords, normalize_text(SES_KEYWORDS[[best_group]]$primary))) > 0,
      length(intersect(node_keywords, normalize_text(SES_KEYWORDS[[best_group]]$secondary))) > 0,
      length(partial_match(full_text, SES_KEYWORDS[[best_group]]$primary)) > 0,
      length(partial_match(full_text, SES_KEYWORDS[[best_group]]$secondary)) > 0
    ))
    
    confidence <- confidence + (match_types - 1) * 0.1
    confidence <- min(1, confidence)
  }
  
  # Return result with confidence
  list(
    group = if (confidence > confidence_threshold) best_group else "Unclassified",
    confidence = confidence,
    score = best_score,
    all_scores = scores
  )
}

# Function to assign groups to multiple nodes (vectorized)
assign_multiple_groups <- function(node_data, name_column = "id", description_column = NULL, 
                                 confidence_threshold = 0.6, add_confidence = FALSE) {
  
  # Validate input
  if (!is.data.frame(node_data)) {
    stop("node_data must be a data frame")
  }
  
  if (!name_column %in% colnames(node_data)) {
    stop(paste("Column", name_column, "not found in data"))
  }
  
  if (nrow(node_data) == 0) {
    warning("Empty data frame provided")
    return(node_data)
  }
  
  # Prepare description column
  descriptions <- if (!is.null(description_column) && description_column %in% colnames(node_data)) {
    node_data[[description_column]]
  } else {
    rep("", nrow(node_data))
  }
  
  # Apply group assignment to each node with progress tracking
  cat("Processing", nrow(node_data), "nodes for group assignment...\n")
  
  results <- mapply(function(name, desc) {
    assign_node_group(name, desc, confidence_threshold)
  }, node_data[[name_column]], descriptions, SIMPLIFY = FALSE)
  
  # Extract results
  groups <- sapply(results, function(r) r$group)
  confidences <- sapply(results, function(r) r$confidence)
  
  # Add to dataframe
  output_data <- node_data
  output_data$group <- groups
  
  if (add_confidence) {
    output_data$group_confidence <- round(confidences, 3)
  }
  
  # Report summary
  classified_count <- sum(groups != "Unclassified")
  avg_confidence <- round(mean(confidences), 3)
  
  cat("Assignment complete:\n")
  cat("- Classified:", classified_count, "nodes\n")
  cat("- Unclassified:", nrow(node_data) - classified_count, "nodes\n")
  cat("- Average confidence:", avg_confidence, "\n")
  
  return(output_data)
}

# Function to suggest improvements for low-confidence assignments
suggest_improvements <- function(node_name, description = "") {
  result <- assign_node_group(node_name, description, confidence_threshold = 0)
  
  if (result$confidence < 0.6) {
    # Get top 3 potential groups
    sorted_scores <- sort(result$all_scores, decreasing = TRUE)
    top_scores <- sorted_scores[1:min(3, length(sorted_scores))]
    top_groups <- names(top_scores)
    
    suggestions <- list(
      current_assignment = result$group,
      confidence = result$confidence,
      alternative_groups = top_groups,
      alternative_scores = top_scores,
      suggestions = c(
        "Consider adding more descriptive keywords to the node name",
        "Check if the node name accurately reflects its function in the SES",
        "Add a description field with more context about the node",
        paste("Top alternative groups based on scoring:", paste(top_groups[1:min(3, length(top_groups))], collapse = ", ")),
        "Consider manual assignment if the node represents a unique case"
      )
    )
    
    return(suggestions)
  } else {
    return(list(
      current_assignment = result$group,
      confidence = result$confidence,
      suggestions = "Assignment confidence is good - no improvements needed"
    ))
  }
}

# Function to add domain-specific keywords dynamically
add_custom_keywords <- function(group, keywords, type = "primary") {
  if (!group %in% SES_GROUPS) {
    stop(paste("Group", group, "not recognized. Valid groups:", paste(SES_GROUPS, collapse = ", ")))
  }
  
  if (!type %in% c("primary", "secondary")) {
    stop("Type must be 'primary' or 'secondary'")
  }
  
  # Add to global keyword list
  SES_KEYWORDS[[group]][[type]] <<- unique(c(SES_KEYWORDS[[group]][[type]], keywords))
  
  message(paste("Added", length(keywords), type, "keywords to", group, "group"))
}

# Function to analyze classification results
analyze_classification_results <- function(classified_data, group_column = "group", 
                                         confidence_column = "group_confidence") {
  
  if (!group_column %in% colnames(classified_data)) {
    stop(paste("Group column", group_column, "not found"))
  }
  
  group_counts <- table(classified_data[[group_column]])
  
  results <- list(
    total_nodes = nrow(classified_data),
    group_distribution = group_counts,
    group_percentages = round(prop.table(group_counts) * 100, 1),
    unclassified_count = sum(classified_data[[group_column]] == "Unclassified"),
    unclassified_percentage = round(sum(classified_data[[group_column]] == "Unclassified") / nrow(classified_data) * 100, 1)
  )
  
  if (confidence_column %in% colnames(classified_data)) {
    confidences <- classified_data[[confidence_column]]
    results$average_confidence <- round(mean(confidences, na.rm = TRUE), 3)
    results$median_confidence <- round(median(confidences, na.rm = TRUE), 3)
    results$low_confidence_nodes <- sum(confidences < 0.6, na.rm = TRUE)
    results$high_confidence_nodes <- sum(confidences >= 0.7, na.rm = TRUE)
    results$confidence_distribution <- list(
      high = sum(confidences >= 0.7, na.rm = TRUE),
      medium = sum(confidences >= 0.4 & confidences < 0.7, na.rm = TRUE),
      low = sum(confidences < 0.4, na.rm = TRUE)
    )
  }
  
  return(results)
}

# Function to export classification rules for review
export_classification_rules <- function(filename = "ses_classification_rules.txt") {
  sink(filename)
  
  cat("SES Node Classification Rules\n")
  cat("============================\n")
  cat("Generated:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n\n")
  
  for (group in SES_GROUPS) {
    cat(paste("GROUP:", group, "\n"))
    cat(paste(rep("-", nchar(group) + 7), collapse = ""), "\n")
    
    cat("Primary Keywords (", length(SES_KEYWORDS[[group]]$primary), " terms):\n")
    primary <- SES_KEYWORDS[[group]]$primary
    for (i in seq(1, length(primary), 5)) {
      chunk <- primary[i:min(i+4, length(primary))]
      cat(paste("  ", paste(chunk, collapse = ", "), "\n"))
    }
    
    cat("\nSecondary Keywords (", length(SES_KEYWORDS[[group]]$secondary), " terms):\n")
    secondary <- SES_KEYWORDS[[group]]$secondary
    for (i in seq(1, length(secondary), 5)) {
      chunk <- secondary[i:min(i+4, length(secondary))]
      cat(paste("  ", paste(chunk, collapse = ", "), "\n"))
    }
    
    cat("\n\n")
  }
  
  cat("Classification Algorithm:\n")
  cat("========================\n")
  cat("1. Exact keyword matching (primary: weight", MATCHING_WEIGHTS$exact_primary, ", secondary: weight", MATCHING_WEIGHTS$exact_secondary, ")\n")
  cat("2. Fuzzy text matching (primary: weight", MATCHING_WEIGHTS$fuzzy_primary, ", secondary: weight", MATCHING_WEIGHTS$fuzzy_secondary, ")\n")
  cat("3. Partial string matching (primary: weight", MATCHING_WEIGHTS$partial_primary, ", secondary: weight", MATCHING_WEIGHTS$partial_secondary, ")\n")
  cat("4. Confidence scoring based on match strength and diversity\n")
  cat("5. Threshold-based assignment (configurable, default: 0.6)\n")
  
  sink()
  message(paste("Classification rules exported to", filename))
}

# Function to validate and test the classification system
test_classification_system <- function() {
  # Test cases with known expected groups
  test_cases <- list(
    list(name = "Commercial fishing", expected = "Activities"),
    list(name = "Ocean acidification", expected = "Pressures"),
    list(name = "Fish production", expected = "Ecosystem Services"),
    list(name = "Tourism revenue", expected = "Societal Goods and Benefits"),
    list(name = "Primary productivity", expected = "Marine processes"),
    list(name = "Population growth", expected = "Drivers"),
    list(name = "Coral reef ecosystem", expected = "Marine processes"),
    list(name = "Plastic pollution", expected = "Pressures"),
    list(name = "Cultural heritage", expected = "Societal Goods and Benefits"),
    list(name = "Aquaculture operations", expected = "Activities"),
    list(name = "Climate change", expected = "Drivers"),
    list(name = "Coastal protection", expected = "Ecosystem Services"),
    list(name = "Marine protected area", expected = "Activities"),
    list(name = "Biodiversity", expected = "Marine processes"),
    list(name = "Overfishing", expected = "Pressures")
  )
  
  results <- data.frame(
    node_name = character(),
    expected_group = character(),
    assigned_group = character(),
    confidence = numeric(),
    correct = logical(),
    stringsAsFactors = FALSE
  )
  
  cat("Running classification system validation...\n")
  
  for (test_case in test_cases) {
    result <- assign_node_group(test_case$name)
    
    results <- rbind(results, data.frame(
      node_name = test_case$name,
      expected_group = test_case$expected,
      assigned_group = result$group,
      confidence = round(result$confidence, 3),
      correct = result$group == test_case$expected,
      stringsAsFactors = FALSE
    ))
  }
  
  accuracy <- sum(results$correct) / nrow(results)
  avg_confidence <- mean(results$confidence)
  
  cat("Classification System Test Results\n")
  cat("=================================\n")
  cat(paste("Accuracy:", round(accuracy * 100, 1), "%\n"))
  cat(paste("Average Confidence:", round(avg_confidence, 3), "\n"))
  cat(paste("Correct Classifications:", sum(results$correct), "out of", nrow(results), "\n\n"))
  
  # Show detailed results
  for (i in 1:nrow(results)) {
    status <- if (results$correct[i]) "✓" else "✗"
    cat(sprintf("%s %-25s: %s (conf: %.2f)\n", 
                status, results$node_name[i], results$assigned_group[i], results$confidence[i]))
  }
  
  return(list(
    accuracy = accuracy,
    average_confidence = avg_confidence,
    detailed_results = results
  ))
}

# Function to optimize confidence threshold based on data
optimize_threshold <- function(node_data, name_column = "id", description_column = NULL) {
  if (nrow(node_data) < 10) {
    warning("Need at least 10 nodes for threshold optimization")
    return(0.5)
  }
  
  # Test different thresholds
  thresholds <- seq(0.1, 0.9, 0.1)
  results <- data.frame(
    threshold = thresholds,
    classified_ratio = numeric(length(thresholds)),
    avg_confidence = numeric(length(thresholds))
  )
  
  descriptions <- if (!is.null(description_column) && description_column %in% colnames(node_data)) {
    node_data[[description_column]]
  } else {
    rep("", nrow(node_data))
  }
  
  for (i in seq_along(thresholds)) {
    thresh <- thresholds[i]
    
    # Get classifications for this threshold
    classifications <- mapply(function(name, desc) {
      assign_node_group(name, desc, thresh)
    }, node_data[[name_column]], descriptions, SIMPLIFY = FALSE)
    
    groups <- sapply(classifications, function(r) r$group)
    confidences <- sapply(classifications, function(r) r$confidence)
    
    results$classified_ratio[i] <- sum(groups != "Unclassified") / length(groups)
    results$avg_confidence[i] <- mean(confidences)
  }
  
  # Find optimal threshold (balance between classification rate and confidence)
  results$score <- results$classified_ratio * 0.7 + results$avg_confidence * 0.3
  optimal_idx <- which.max(results$score)
  optimal_threshold <- results$threshold[optimal_idx]
  
  cat("Threshold optimization results:\n")
  print(results)
  cat("\nOptimal threshold:", optimal_threshold, "\n")
  
  return(optimal_threshold)
}

# Example usage function
demo_classification <- function() {
  cat("SES Classification Demo\n")
  cat("======================\n")
  
  # Create sample data representing a marine SES
  sample_nodes <- data.frame(
    id = c("Commercial fishing", "Ocean warming", "Recreational diving", 
           "Coastal erosion", "Fish stocks", "Tourism employment",
           "Coral bleaching", "Desalination plant", "Carbon sequestration",
           "Economic development", "Marine protected area", "Plastic waste"),
    description = c("Large-scale commercial fishing operations", "Rising sea temperatures due to climate change",
                   "Recreational scuba diving and snorkeling activities", "Coastal habitat degradation and loss",
                   "Commercial fish populations and abundance", "Employment in marine tourism sector",
                   "Coral mortality events due to thermal stress", "Seawater desalination facility",
                   "Ocean carbon dioxide absorption and storage", "Regional economic growth and development",
                   "Government designated conservation area", "Marine plastic pollution and debris"),
    stringsAsFactors = FALSE
  )
  
  cat("\nSample marine SES network with", nrow(sample_nodes), "nodes:\n")
  for (i in 1:nrow(sample_nodes)) {
    cat(paste(i, ".", sample_nodes$id[i], "\n"))
  }
  
  # Apply classification
  cat("\nApplying intelligent classification...\n")
  classified <- assign_multiple_groups(sample_nodes, 
                                     name_column = "id", 
                                     description_column = "description",
                                     confidence_threshold = 0.5,
                                     add_confidence = TRUE)
  
  # Show results
  cat("\nClassification Results:\n")
  cat("======================\n")
  for (i in 1:nrow(classified)) {
    conf_level <- if (classified$group_confidence[i] >= 0.7) "High" else if (classified$group_confidence[i] >= 0.4) "Medium" else "Low"
    cat(sprintf("%-25s → %-30s (%.2f - %s confidence)\n", 
                classified$id[i], classified$group[i], classified$group_confidence[i], conf_level))
  }
  
  # Analyze results
  analysis <- analyze_classification_results(classified)
  
  cat("\nSummary Statistics:\n")
  cat("==================\n")
  cat("Total nodes:", analysis$total_nodes, "\n")
  cat("Classified:", analysis$total_nodes - analysis$unclassified_count, "\n")
  cat("Unclassified:", analysis$unclassified_count, "\n")
  cat("Average confidence:", analysis$average_confidence, "\n")
  
  if (!is.null(analysis$confidence_distribution)) {
    cat("\nConfidence Distribution:\n")
    cat("High (≥0.7):", analysis$confidence_distribution$high, "\n")
    cat("Medium (0.4-0.7):", analysis$confidence_distribution$medium, "\n")
    cat("Low (<0.4):", analysis$confidence_distribution$low, "\n")
  }
  
  cat("\nGroup Distribution:\n")
  for (group in names(analysis$group_distribution)) {
    cat(sprintf("%-30s: %d (%.1f%%)\n", group, analysis$group_distribution[group], analysis$group_percentages[group]))
  }
  
  return(classified)
}

# System information and initialization
get_system_info <- function() {
  info <- list(
    version = "1.0.0",
    keywords_total = sum(sapply(SES_KEYWORDS, function(x) length(x$primary) + length(x$secondary))),
    groups_count = length(SES_GROUPS),
    algorithm_types = c("Exact matching", "Fuzzy matching", "Partial matching", "Confidence scoring"),
    confidence_levels = c("High (≥0.7)", "Medium (0.4-0.7)", "Low (<0.4)"),
    created = "2025",
    description = "AI-powered SES node classification system for marine social-ecological networks"
  )
  
  return(info)
}

# Initialize the system by running tests if file is sourced directly
if (sys.nframe() == 0) {
  cat("SES Node Classification System\n")
  cat("==============================\n")
  
  system_info <- get_system_info()
  cat("Version:", system_info$version, "\n")
  cat("Total keywords:", system_info$keywords_total, "\n")
  cat("SES groups:", system_info$groups_count, "\n")
  cat("Algorithm types:", length(system_info$algorithm_types), "\n\n")
  
  cat("Available functions:\n")
  cat("- assign_node_group(node_name, description): Classify a single node\n")
  cat("- assign_multiple_groups(data, name_col, desc_col): Classify multiple nodes\n")
  cat("- suggest_improvements(node_name, description): Get classification suggestions\n")
  cat("- test_classification_system(): Run system validation tests\n")
  cat("- demo_classification(): See example usage with marine SES data\n")
  cat("- export_classification_rules(filename): Export rules to file\n")
  cat("- optimize_threshold(data): Find optimal confidence threshold\n")
  cat("- analyze_classification_results(data): Analyze classification quality\n")
  cat("\nRunning system validation...\n")
  
  # Run validation test
  test_results <- test_classification_system()
  
  if (test_results$accuracy >= 0.8) {
    cat("\n✅ System validation PASSED - Ready for use!\n")
  } else {
    cat("\n⚠️ System validation shows lower accuracy - Check keyword dictionaries\n")
  }
} else {
  cat("✅ SES intelligent classification system loaded successfully\n")
  cat("📊 Total keywords:", sum(sapply(SES_KEYWORDS, function(x) length(x$primary) + length(x$secondary))), "\n")
  cat("🏷️ SES groups:", length(SES_GROUPS), "\n")
}