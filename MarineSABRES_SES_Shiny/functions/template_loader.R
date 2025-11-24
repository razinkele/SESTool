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
    Name = sapply(elements, function(x) {
      # Prefer 'name' field, fallback to 'id' if name is missing
      name <- x$name
      if (is.null(name) || length(name) == 0 || name == "") {
        return(x$id)
      }
      return(name)
    }),
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

    # Handle responses and measures - merge them into a single responses category
    responses_list <- fw$responses %||% list()
    measures_list <- fw$measures %||% list()

    # Count original sizes BEFORE merging
    n_original_responses <- length(responses_list)
    n_measures <- length(measures_list)

    # Merge measures into responses
    all_responses <- c(responses_list, measures_list)
    responses_df <- json_elements_to_df(all_responses, "Response")
    n_total_responses <- nrow(responses_df)

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

      # Response matrices (if original responses exist - measures will be added later)
      if (n_original_responses > 0) {
        # Use only the original responses (not measures yet)
        original_response_ids <- responses_df$ID[1:n_original_responses]
        original_response_names <- responses_df$Name[1:n_original_responses]

        # GB → R (Goods & Benefits/Welfare to Responses)
        # This matrix has GB as rows, but we want ALL responses (including future measures) as columns
        if (nrow(goods_benefits_df) > 0) {
          adjacency_matrices$gb_r <- build_adjacency_matrix(
            connections, goods_benefits_df$ID, responses_df$ID,  # Use full responses_df for columns
            "welfare", "response", goods_benefits_df$Name, responses_df$Name
          )
        }

        # R → D (Responses to Drivers) - only original responses for now
        if (nrow(drivers_df) > 0) {
          adjacency_matrices$r_d <- build_adjacency_matrix(
            connections, original_response_ids, drivers_df$ID,
            "response", "driver", original_response_names, drivers_df$Name
          )
        }

        # R → A (Responses to Activities) - only original responses for now
        if (nrow(activities_df) > 0) {
          adjacency_matrices$r_a <- build_adjacency_matrix(
            connections, original_response_ids, activities_df$ID,
            "response", "activity", original_response_names, activities_df$Name
          )
        }

        # R → P (Responses to Pressures) - only original responses for now
        if (nrow(pressures_df) > 0) {
          adjacency_matrices$r_p <- build_adjacency_matrix(
            connections, original_response_ids, pressures_df$ID,
            "response", "pressure", original_response_names, pressures_df$Name
          )
        }

        # R → S (Responses to States) - direct restoration, only original responses for now
        if (nrow(marine_processes_df) > 0) {
          adjacency_matrices$r_mpf <- build_adjacency_matrix(
            connections, original_response_ids, marine_processes_df$ID,
            "response", "state", original_response_names, marine_processes_df$Name
          )
        }
      }
      
      # Process measure connections (they're now part of responses)
      # Measures are rows n_original_responses+1 to n_total_responses in responses_df
      if (n_measures > 0) {
        measure_ids <- responses_df$ID[(n_original_responses + 1):n_total_responses]
        measure_names <- responses_df$Name[(n_original_responses + 1):n_total_responses]

        # Build temporary matrices for measure connections, then insert into appropriate rows of response matrices
        # M → D (Measures to Drivers)
        if (nrow(drivers_df) > 0) {
          m_d_temp <- build_adjacency_matrix(
            connections, measure_ids, drivers_df$ID,
            "measure", "driver", measure_names, drivers_df$Name
          )

          # Create/expand r_d matrix to have n_total_responses rows
          if (!is.null(adjacency_matrices$r_d)) {
            # Ensure r_d has correct dimensions
            if (nrow(adjacency_matrices$r_d) != n_total_responses) {
              # Expand matrix to include measure rows
              full_matrix <- matrix("", nrow = n_total_responses, ncol = ncol(adjacency_matrices$r_d),
                                   dimnames = list(responses_df$Name, colnames(adjacency_matrices$r_d)))
              # Copy original response rows
              full_matrix[1:n_original_responses, ] <- adjacency_matrices$r_d
              # Insert measure rows
              full_matrix[(n_original_responses + 1):n_total_responses, ] <- m_d_temp
              adjacency_matrices$r_d <- full_matrix
            }
          } else {
            # Create new r_d with all response rows
            adjacency_matrices$r_d <- matrix("", nrow = n_total_responses, ncol = ncol(m_d_temp),
                                            dimnames = list(responses_df$Name, colnames(m_d_temp)))
            adjacency_matrices$r_d[(n_original_responses + 1):n_total_responses, ] <- m_d_temp
          }
        }

        # M → A (Measures to Activities)
        if (nrow(activities_df) > 0) {
          m_a_temp <- build_adjacency_matrix(
            connections, measure_ids, activities_df$ID,
            "measure", "activity", measure_names, activities_df$Name
          )

          if (!is.null(adjacency_matrices$r_a)) {
            if (nrow(adjacency_matrices$r_a) != n_total_responses) {
              full_matrix <- matrix("", nrow = n_total_responses, ncol = ncol(adjacency_matrices$r_a),
                                   dimnames = list(responses_df$Name, colnames(adjacency_matrices$r_a)))
              full_matrix[1:n_original_responses, ] <- adjacency_matrices$r_a
              full_matrix[(n_original_responses + 1):n_total_responses, ] <- m_a_temp
              adjacency_matrices$r_a <- full_matrix
            }
          } else {
            adjacency_matrices$r_a <- matrix("", nrow = n_total_responses, ncol = ncol(m_a_temp),
                                            dimnames = list(responses_df$Name, colnames(m_a_temp)))
            adjacency_matrices$r_a[(n_original_responses + 1):n_total_responses, ] <- m_a_temp
          }
        }

        # M → P (Measures to Pressures)
        if (nrow(pressures_df) > 0) {
          m_p_temp <- build_adjacency_matrix(
            connections, measure_ids, pressures_df$ID,
            "measure", "pressure", measure_names, pressures_df$Name
          )

          if (!is.null(adjacency_matrices$r_p)) {
            if (nrow(adjacency_matrices$r_p) != n_total_responses) {
              full_matrix <- matrix("", nrow = n_total_responses, ncol = ncol(adjacency_matrices$r_p),
                                   dimnames = list(responses_df$Name, colnames(adjacency_matrices$r_p)))
              full_matrix[1:n_original_responses, ] <- adjacency_matrices$r_p
              full_matrix[(n_original_responses + 1):n_total_responses, ] <- m_p_temp
              adjacency_matrices$r_p <- full_matrix
            }
          } else {
            adjacency_matrices$r_p <- matrix("", nrow = n_total_responses, ncol = ncol(m_p_temp),
                                            dimnames = list(responses_df$Name, colnames(m_p_temp)))
            adjacency_matrices$r_p[(n_original_responses + 1):n_total_responses, ] <- m_p_temp
          }
        }

        # M → MPF (Measures to States)
        if (nrow(marine_processes_df) > 0) {
          m_mpf_temp <- build_adjacency_matrix(
            connections, measure_ids, marine_processes_df$ID,
            "measure", "state", measure_names, marine_processes_df$Name
          )

          if (!is.null(adjacency_matrices$r_mpf)) {
            if (nrow(adjacency_matrices$r_mpf) != n_total_responses) {
              full_matrix <- matrix("", nrow = n_total_responses, ncol = ncol(adjacency_matrices$r_mpf),
                                   dimnames = list(responses_df$Name, colnames(adjacency_matrices$r_mpf)))
              full_matrix[1:n_original_responses, ] <- adjacency_matrices$r_mpf
              full_matrix[(n_original_responses + 1):n_total_responses, ] <- m_mpf_temp
              adjacency_matrices$r_mpf <- full_matrix
            }
          } else {
            adjacency_matrices$r_mpf <- matrix("", nrow = n_total_responses, ncol = ncol(m_mpf_temp),
                                              dimnames = list(responses_df$Name, colnames(m_mpf_temp)))
            adjacency_matrices$r_mpf[(n_original_responses + 1):n_total_responses, ] <- m_mpf_temp
          }
        }

        # M → R (Measures to Responses) - this becomes R→R (within responses)
        # Only process original responses as targets (rows 1 to n_original_responses)
        if (n_original_responses > 0) {
          original_response_ids <- responses_df$ID[1:n_original_responses]
          original_response_names <- responses_df$Name[1:n_original_responses]

          m_r_temp <- build_adjacency_matrix(
            connections, measure_ids, original_response_ids,
            "measure", "response", measure_names, original_response_names
          )

          # Create full R×R matrix (responses to responses)
          adjacency_matrices$r_r <- matrix("", nrow = n_total_responses, ncol = n_total_responses,
                                          dimnames = list(responses_df$Name, responses_df$Name))

          # Fill in measure→response connections (last n_measures rows, first n_original_responses cols)
          adjacency_matrices$r_r[(n_original_responses + 1):n_total_responses, 1:n_original_responses] <- m_r_temp
        }
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

    # Add responses (now includes both original responses and measures)
    if (nrow(responses_df) > 0) {
      template$responses <- responses_df
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
