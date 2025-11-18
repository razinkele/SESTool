# functions/template_loader.R
# JSON Template Loader for SES Templates
# Purpose: Load and convert JSON templates to R data structures

library(jsonlite)

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

#' Convert JSON element array to data frame
#' @param elements List of elements from JSON
#' @param element_type Type of element (for Type column)
#' @return Data frame with standardized columns
json_elements_to_df <- function(elements, element_type) {
  if (is.null(elements) || length(elements) == 0) {
    return(data.frame(
      ID = character(0),
      Name = character(0),
      Type = character(0),
      Description = character(0),
      Stakeholder = character(0),
      Importance = character(0),
      Trend = character(0),
      stringsAsFactors = FALSE
    ))
  }

  # Handle case where element_type might be empty/NULL
  if (is.null(element_type) || length(element_type) == 0) {
    element_type <- "Unknown"
  }

  df <- data.frame(
    ID = sapply(elements, function(x) if (!is.null(x$id)) x$id else ""),
    Name = sapply(elements, function(x) if (!is.null(x$name)) x$name else ""),
    Type = element_type,
    Description = sapply(elements, function(x) if (!is.null(x$description)) x$description else ""),
    Stakeholder = sapply(elements, function(x) if (!is.null(x$stakeholder)) x$stakeholder else ""),
    Importance = "",
    Trend = "",
    stringsAsFactors = FALSE
  )

  return(df)
}

#' Build adjacency matrix from connections
#' @param connections List of connection objects from JSON
#' @param from_elements Vector of element IDs for rows
#' @param to_elements Vector of element IDs for columns
#' @param from_type Type of source elements
#' @param to_type Type of target elements
#' @return Matrix with connection strengths
build_adjacency_matrix <- function(connections, from_elements, to_elements,
                                   from_type, to_type, from_names, to_names) {
  # Initialize empty matrix
  mat <- matrix("", nrow = length(from_elements), ncol = length(to_elements),
                dimnames = list(from_names, to_names))

  # Normalize type names to handle different conventions
  normalize_type <- function(type) {
    type_lower <- tolower(type)
    # Map variations to canonical names
    if (type_lower %in% c("state", "marineprocess", "marine_process")) return("state")
    if (type_lower %in% c("impact", "ecosystemservice", "ecosystem_service")) return("impact")
    if (type_lower %in% c("goodsbenefit", "goods_benefit", "welfare")) return("welfare")
    if (type_lower %in% c("enmp", "pressure")) return("pressure")
    return(type_lower)
  }
  
  # Filter connections for this matrix (normalized comparison)
  relevant_connections <- Filter(function(conn) {
    normalize_type(conn$from_type) == normalize_type(from_type) &&
    normalize_type(conn$to_type) == normalize_type(to_type)
  }, connections)

  # Fill matrix
  for (conn in relevant_connections) {
    from_idx <- which(from_elements == conn$from_id)
    to_idx <- which(to_elements == conn$to_id)

    if (length(from_idx) > 0 && length(to_idx) > 0) {
      polarity <- conn$polarity %||% "+"
      strength <- conn$strength %||% "medium"
      confidence <- conn$confidence %||% 3

      mat[from_idx, to_idx] <- paste0(polarity, strength, ":", confidence)
    }
  }

  return(mat)
}

#' Null-coalescing operator
#' @param x Value to check
#' @param y Default value if x is NULL
`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

# ============================================================================
# MAIN LOADER FUNCTION
# ============================================================================

#' Load template from JSON file
#' @param json_path Path to JSON template file
#' @return List with template data in R format
load_template_from_json <- function(json_path) {
  tryCatch({
    # Read JSON file
    json_data <- jsonlite::fromJSON(json_path, simplifyVector = FALSE)

    # Detect JSON format and extract framework data
    # Format 1: dapsiwrm_framework wrapper (Caribbean, Fisheries, etc.)
    # Format 2: elements wrapper (OffshoreWind)
    if (!is.null(json_data$dapsiwrm_framework)) {
      fw <- json_data$dapsiwrm_framework
      template_name <- json_data$template_name %||% "Unknown Template"
      template_desc <- json_data$template_description %||% ""
    } else if (!is.null(json_data$elements)) {
      fw <- json_data$elements
      template_name <- json_data$template_info$name %||% "Unknown Template"
      template_desc <- json_data$template_info$description %||% ""
    } else {
      stop("Unknown JSON format - neither dapsiwrm_framework nor elements found")
    }

    # Convert elements to data frames
    drivers_df <- json_elements_to_df(fw$drivers, "Driver")
    activities_df <- json_elements_to_df(fw$activities, "Activity")
    pressures_df <- json_elements_to_df(fw$pressures, "EnMP")

    # Handle marine_processes (could be called "states" in some templates)
    mpf_list <- fw$marine_processes %||% fw$states
    marine_processes_df <- json_elements_to_df(mpf_list, "State Change")

    # Handle ecosystem_services (could be called "impacts" in some templates)
    es_list <- fw$ecosystem_services %||% fw$impacts

    # Determine type from first element if available
    es_type <- "Provisioning"
    if (!is.null(es_list) && length(es_list) > 0 && !is.null(es_list[[1]]$type)) {
      es_type <- es_list[[1]]$type
    } else if (!is.null(fw$impacts)) {
      es_type <- "Impact"
    }

    ecosystem_services_df <- json_elements_to_df(es_list, es_type)

    # Handle goods_benefits (could be called "welfare" in some templates)
    gb_list <- fw$goods_benefits %||% fw$welfare
    goods_benefits_df <- json_elements_to_df(gb_list, "Welfare")

    # Handle responses
    responses_df <- json_elements_to_df(fw$responses, "Response")
    
    # Handle measures
    measures_df <- json_elements_to_df(fw$measures, "Measure")

    # Extract connections
    connections <- json_data$connections %||% list()

    # Build adjacency matrices
    adjacency_matrices <- list()

    # Only build matrices if we have elements and connections
    if (nrow(drivers_df) > 0 && nrow(activities_df) > 0 && length(connections) > 0) {
      # D → A (Drivers to Activities)
      adjacency_matrices$d_a <- build_adjacency_matrix(
        connections, drivers_df$ID, activities_df$ID,
        "driver", "activity", drivers_df$Name, activities_df$Name
      )

      # A → P (Activities to Pressures)
      if (nrow(pressures_df) > 0) {
        adjacency_matrices$a_p <- build_adjacency_matrix(
          connections, activities_df$ID, pressures_df$ID,
          "activity", "pressure", activities_df$Name, pressures_df$Name
        )
      }

      # P → MPF (Pressures to Marine Processes/States)
      if (nrow(marine_processes_df) > 0 && nrow(pressures_df) > 0) {
        adjacency_matrices$p_mpf <- build_adjacency_matrix(
          connections, pressures_df$ID, marine_processes_df$ID,
          "pressure", "state", pressures_df$Name, marine_processes_df$Name
        )
      }

      # MPF → ES (Marine Processes/States to Ecosystem Services/Impacts)
      if (nrow(ecosystem_services_df) > 0 && nrow(marine_processes_df) > 0) {
        adjacency_matrices$mpf_es <- build_adjacency_matrix(
          connections, marine_processes_df$ID, ecosystem_services_df$ID,
          "state", "impact", marine_processes_df$Name, ecosystem_services_df$Name
        )
      }

      # ES → GB (Ecosystem Services/Impacts to Goods & Benefits/Welfare)
      if (nrow(goods_benefits_df) > 0 && nrow(ecosystem_services_df) > 0) {
        adjacency_matrices$es_gb <- build_adjacency_matrix(
          connections, ecosystem_services_df$ID, goods_benefits_df$ID,
          "impact", "welfare", ecosystem_services_df$Name, goods_benefits_df$Name
        )
      }

      # GB → D (Goods & Benefits/Welfare to Drivers - feedback)
      if (nrow(goods_benefits_df) > 0 && nrow(drivers_df) > 0) {
        adjacency_matrices$gb_d <- build_adjacency_matrix(
          connections, goods_benefits_df$ID, drivers_df$ID,
          "welfare", "driver", goods_benefits_df$Name, drivers_df$Name
        )
      }

      # Response matrices (if responses exist)
      if (nrow(responses_df) > 0) {
        # GB → R (Goods & Benefits/Welfare to Responses)
        if (nrow(goods_benefits_df) > 0) {
          adjacency_matrices$gb_r <- build_adjacency_matrix(
            connections, goods_benefits_df$ID, responses_df$ID,
            "welfare", "response", goods_benefits_df$Name, responses_df$Name
          )
        }

        # R → D (Responses to Drivers)
        if (nrow(drivers_df) > 0) {
          adjacency_matrices$r_d <- build_adjacency_matrix(
            connections, responses_df$ID, drivers_df$ID,
            "response", "driver", responses_df$Name, drivers_df$Name
          )
        }

        # R → A (Responses to Activities)
        if (nrow(activities_df) > 0) {
          adjacency_matrices$r_a <- build_adjacency_matrix(
            connections, responses_df$ID, activities_df$ID,
            "response", "activity", responses_df$Name, activities_df$Name
          )
        }

        # R → P (Responses to Pressures)
        if (nrow(pressures_df) > 0) {
          adjacency_matrices$r_p <- build_adjacency_matrix(
            connections, responses_df$ID, pressures_df$ID,
            "response", "pressure", responses_df$Name, pressures_df$Name
          )
        }
        
        # R → S (Responses to States) - direct restoration
        if (nrow(marine_processes_df) > 0) {
          adjacency_matrices$r_mpf <- build_adjacency_matrix(
            connections, responses_df$ID, marine_processes_df$ID,
            "response", "state", responses_df$Name, marine_processes_df$Name
          )
        }
      }
      
      # Measure matrices (if measures exist)
      if (nrow(measures_df) > 0 && nrow(responses_df) > 0) {
        # M → R (Measures to Responses)
        adjacency_matrices$m_r <- build_adjacency_matrix(
          connections, measures_df$ID, responses_df$ID,
          "measure", "response", measures_df$Name, responses_df$Name
        )
      }
    }

    # Determine category from metadata or main issues
    category <- "General"
    if (!is.null(json_data$regional_context$main_issues)) {
      issues <- json_data$regional_context$main_issues
      if (length(issues) > 1) {
        category <- "Multi-Stressor"
      } else if (any(grepl("fish", issues, ignore.case = TRUE))) {
        category <- "Extraction"
      } else if (any(grepl("touris", issues, ignore.case = TRUE))) {
        category <- "Recreation"
      } else if (any(grepl("aqua|farm", issues, ignore.case = TRUE))) {
        category <- "Production"
      } else if (any(grepl("pollut|contamin", issues, ignore.case = TRUE))) {
        category <- "Pollution"
      } else if (any(grepl("climat|warm|sea level", issues, ignore.case = TRUE))) {
        category <- "Climate"
      } else if (any(grepl("wind|energy", issues, ignore.case = TRUE))) {
        category <- "Energy"
      }
    }

    # Determine icon
    icon <- "globe"
    if (grepl("fish", template_name, ignore.case = TRUE)) {
      icon <- "fish"
    } else if (grepl("touris|beach", template_name, ignore.case = TRUE)) {
      icon <- "umbrella-beach"
    } else if (grepl("aqua", template_name, ignore.case = TRUE)) {
      icon <- "shrimp"
    } else if (grepl("pollut", template_name, ignore.case = TRUE)) {
      icon <- "smog"
    } else if (grepl("climat", template_name, ignore.case = TRUE)) {
      icon <- "temperature-high"
    } else if (grepl("wind", template_name, ignore.case = TRUE)) {
      icon <- "wind"
    } else if (grepl("caribbean|island", template_name, ignore.case = TRUE)) {
      icon <- "globe-americas"
    }

    # Return template in R format
    template <- list(
      name_key = template_name,
      description_key = template_desc,
      icon = icon,
      category_key = category,
      drivers = drivers_df,
      activities = activities_df,
      pressures = pressures_df,
      marine_processes = marine_processes_df,
      ecosystem_services = ecosystem_services_df,
      goods_benefits = goods_benefits_df,
      adjacency_matrices = adjacency_matrices
    )

    # Add responses if they exist
    if (nrow(responses_df) > 0) {
      template$responses <- responses_df
    }
    
    # Add measures if they exist
    if (nrow(measures_df) > 0) {
      template$measures <- measures_df
    }

    return(template)

  }, error = function(e) {
    warning(paste("Error loading template from", json_path, ":", e$message))
    return(NULL)
  })
}

# ============================================================================
# BATCH LOADER
# ============================================================================

#' Load all templates from data directory
#' @param data_dir Directory containing JSON template files
#' @return Named list of templates
load_all_templates <- function(data_dir = "data") {
  # Find all JSON template files
  json_files <- list.files(data_dir, pattern = "_Template\\.json$", full.names = TRUE)

  templates <- list()

  for (json_file in json_files) {
    # Extract template key from filename
    template_key <- tolower(gsub("_SES_Template\\.json$", "", basename(json_file)))
    template_key <- gsub("_", "", template_key)  # Remove underscores

    # Load template
    template <- load_template_from_json(json_file)

    if (!is.null(template)) {
      templates[[template_key]] <- template
      cat("✓ Loaded template:", template_key, "\n")
    } else {
      cat("✗ Failed to load:", json_file, "\n")
    }
  }

  return(templates)
}
