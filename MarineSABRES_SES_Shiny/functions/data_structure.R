# functions/data_structure.R
# Data structure definitions and initialization functions

# ============================================================================
# ELEMENT ID GENERATION
# ============================================================================

#' Generate element IDs from a prefix and numeric indices
#'
#' @param prefix ID prefix string (e.g., "D", "MPF") or element type name
#' @param n Numeric vector of indices, or length to generate 1:n
#' @return Character vector of IDs like "D001", "MPF002"
generate_element_id <- function(prefix, n) {
  if (length(n) == 1 && n >= 1) n <- seq_len(n)
  paste0(prefix, sprintf("%03d", n))
}

# ============================================================================
# DATA STRUCTURE TEMPLATES
# ============================================================================

#' Create empty project data structure
#' 
#' @param project_name Project name
#' @param da_site Demonstration area site
#' @return List with complete project structure
create_empty_project <- function(project_name = "New Project", da_site = NULL) {
  
  list(
    project_id = generate_id("PROJ"),
    project_name = project_name,
    created_at = Sys.time(),
    last_modified = Sys.time(),
    user = Sys.info()["user"],
    version = ifelse(exists("APP_VERSION"), APP_VERSION, "1.0"),
    
    data = list(
      # Project metadata
      metadata = list(
        da_site = da_site,
        focal_issue = NULL,
        definition_statement = NULL,
        time_horizon = NULL,
        spatial_scale = NULL,
        system_in_focus = NULL,
        meta_system = NULL,
        sub_systems = NULL,
        regional_sea = NULL,
        regional_sea_display = NULL,
        ecosystem_type = NULL
      ),
      
      # PIMS data
      pims = list(
        stakeholders = data.frame(
          id = character(),
          name = character(),
          organization = character(),
          type = character(),
          power = numeric(),
          interest = numeric(),
          contact_email = character(),
          contact_phone = character(),
          communication_preference = character(),
          notes = character()
        ),

        risks = data.frame(
          id = character(),
          date_identified = as.Date(character()),
          description = character(),
          likelihood = character(),
          severity = character(),
          mitigation_actions = character(),
          owner = character(),
          status = character()
        ),

        resources = data.frame(
          id = character(),
          type = character(),
          description = character(),
          quantity = numeric(),
          unit = character(),
          cost = numeric(),
          allocated_to = character(),
          notes = character()
        ),

        data_management = list(
          dmp_exists = FALSE,
          gdpr_compliant = FALSE,
          data_sources = data.frame(
            source_name = character(),
            type = character(),
            provider = character(),
            quality_rating = character(),
            last_updated = as.Date(character())
          )
        ),
        
        evaluation = list(
          process = data.frame(
            question = character(),
            response_type = character(),
            responses = character()
          ),
          outcome = data.frame(
            objective = character(),
            indicator = character(),
            baseline = numeric(),
            target = numeric(),
            current = numeric(),
            deadline = as.Date(character())
          )
        )
      ),
      
      # ISA data
      isa_data = list(
        goods_benefits = create_empty_element_df("Goods & Benefits"),
        ecosystem_services = create_empty_element_df("Ecosystem Services"),
        marine_processes = create_empty_element_df("Marine Processes & Functioning"),
        pressures = create_empty_element_df("Pressures"),
        activities = create_empty_element_df("Activities"),
        drivers = create_empty_element_df("Drivers"),
        responses = create_empty_element_df("Responses"),  # Management responses/measures (R/M in DAPSI(W)R(M))
        
        # BOT data
        bot_data = list(
          goods_benefits = data.frame(
            date = as.Date(character()),
            element_id = character(),
            value = numeric()
          ),
          ecosystem_services = data.frame(
            date = as.Date(character()),
            element_id = character(),
            value = numeric()
          ),
          marine_processes = data.frame(
            date = as.Date(character()),
            element_id = character(),
            value = numeric()
          ),
          pressures = data.frame(
            date = as.Date(character()),
            element_id = character(),
            value = numeric()
          ),
          activities = data.frame(
            date = as.Date(character()),
            element_id = character(),
            value = numeric()
          ),
          drivers = data.frame(
            date = as.Date(character()),
            element_id = character(),
            value = numeric()
          ),
          responses = data.frame(
            date = as.Date(character()),
            element_id = character(),
            value = numeric()
          )
        ),
        
        # Adjacency matrices - DAPSIWRM framework
        # MATRIX CONVENTION: All matrices use SOURCE×TARGET format (rows=SOURCE, cols=TARGET)
        # FORWARD CAUSAL FLOW: Drivers → Activities → Pressures → Marine Processes → Ecosystem Services → Welfare (Goods & Benefits)
        # FEEDBACK/RESPONSES: Welfare → Responses → (Drivers, Activities, Pressures)
        adjacency_matrices = list(
          # Forward causal chain
          d_a = NULL,      # Drivers → Activities
          a_p = NULL,      # Activities → Pressures
          p_mpf = NULL,    # Pressures → Marine Processes & Functions
          mpf_es = NULL,   # Marine Processes → Ecosystem Services
          es_gb = NULL,    # Ecosystem Services → Welfare (Goods & Benefits)
          
          # Feedback loop closure
          gb_d = NULL,     # Welfare → Drivers (perception/demand feedback)
          
          # Response measures (management interventions)
          gb_r = NULL,     # Welfare → Responses (problems drive responses)
          r_d = NULL,      # Responses → Drivers (policy targeting drivers)
          r_a = NULL,      # Responses → Activities (regulations on activities)
          r_p = NULL       # Responses → Pressures (direct pressure mitigation)
        )
      ),
      
      # CLD data
      cld = list(
        nodes = NULL,
        edges = NULL,
        loops = NULL,
        metrics = NULL,
        simplified = FALSE,
        simplification_history = list()
      ),

      # Analysis results
      analysis = list(
        loops = NULL,  # Loop detection results
        leverage_points = NULL,  # Leverage point analysis results
        scenarios = list(),  # Scenario analysis results

        # DTU dynamics analysis results
        dynamics = list(
          # Numeric adjacency matrix used for all dynamics analyses
          numeric_matrix = NULL,
          matrix_params = list(
            source = NULL,             # "cld" or "isa"
            weight_map = NULL,
            include_confidence = FALSE,
            timestamp = NULL
          ),

          # Qualitative: Laplacian stability
          laplacian = list(
            eigenvalues = NULL,        # named numeric vector
            direction = NULL,          # "rows" or "cols"
            fiedler_value = NULL,
            n_components = NULL,
            timestamp = NULL
          ),

          # Qualitative: Boolean network
          boolean = list(
            rules = NULL,              # data frame (targets, factors)
            n_states = NULL,
            n_attractors = NULL,
            attractors = NULL,         # list of data frames
            basins = NULL,             # numeric vector
            timestamp = NULL
          ),

          # Quantitative: deterministic simulation
          simulation = list(
            time_series = NULL,        # matrix (nodes x timesteps)
            n_iter = NULL,
            initial_state = NULL,
            diverged = FALSE,
            timestamp = NULL
          ),

          # Quantitative: participation ratio
          participation_ratio = NULL,   # data frame (node, PR)

          # Quantitative: Monte Carlo state-shift
          state_shift = list(
            final_states = NULL,       # matrix (nodes x simulations)
            n_simulations = NULL,
            randomization_type = NULL,
            target_nodes = NULL,
            success_rate = NULL,
            timestamp = NULL
          ),

          # Intervention scenarios
          interventions = list(),

          # ML: random forest importance
          rf_importance = list(
            importance = NULL,         # data frame
            top_variables = NULL,
            oob_error = NULL,
            timestamp = NULL
          )
        )
      )
    )
  )
}

#' Create empty element dataframe
#' 
#' @param element_type Type of DAPSI(W)R(M) element
#' @return Empty dataframe with appropriate columns
create_empty_element_df <- function(element_type) {
  
  base_cols <- data.frame(
    id = character(),
    name = character(),
    indicator = character(),
    indicator_unit = character(),
    data_source = character(),
    time_horizon_start = as.Date(character()),
    time_horizon_end = as.Date(character()),
    baseline_value = numeric(),
    current_value = numeric(),
    notes = character()
  )
  
  # Add element-specific columns
  if (element_type == "Ecosystem Services") {
    base_cols$category <- character()  # Provisioning, Regulating, etc.
  } else if (element_type == "Marine Processes & Functioning") {
    base_cols$process_type <- character()
  } else if (element_type == "Pressures") {
    base_cols$type <- character()  # ExP or EnMP
    base_cols$spatial_scale <- character()
    base_cols$relevant_policies <- character()
  } else if (element_type == "Activities") {
    base_cols$scale <- character()  # Individual, Group, etc.
    base_cols$relevant_policies <- character()
    base_cols$implementation_quality <- character()
  } else if (element_type == "Drivers") {
    base_cols$needs_category <- character()
    base_cols$trends <- character()
  } else if (element_type == "Responses") {
    # Response measures / policy instruments (R/M in DAPSI(W)R(M))
    base_cols$measure_type <- character()  # e.g., regulatory, economic, informational
    base_cols$target_elements <- character()  # Which DAPSI elements this targets
    base_cols$expected_effect <- character()  # Expected outcome
    base_cols$implementation_cost <- numeric()  # Cost estimate
    base_cols$feasibility <- character()  # Low, Medium, High
    base_cols$stakeholder_acceptance <- character()  # Acceptance level
  }

  return(base_cols)
}

# ============================================================================
# ADJACENCY MATRIX FUNCTIONS
# ============================================================================

#' Create empty adjacency matrix
#'
#' MATRIX CONVENTION: All matrices use SOURCE×TARGET format
#' - Matrix name: source_target (e.g., "es_gb" means ES→GB)
#' - Matrix structure: rows=SOURCE elements, cols=TARGET elements
#' - Cell [i,j]: Connection from SOURCE[i] to TARGET[j]
#' - This convention eliminates the need for matrix transpositions
#'
#' @param from_elements Vector of source element names
#' @param to_elements Vector of target element names
#' @return Matrix with empty cells, rows=from_elements, cols=to_elements
create_empty_adjacency_matrix <- function(from_elements, to_elements) {

  if (length(from_elements) == 0 || length(to_elements) == 0) {
    return(matrix(nrow = 0, ncol = 0))
  }

  mat <- matrix("", nrow = length(from_elements), ncol = length(to_elements))
  rownames(mat) <- from_elements
  colnames(mat) <- to_elements

  return(mat)
}

#' Create adjacency matrix (alias for create_empty_adjacency_matrix)
#'
#' @param row_names Vector of row names
#' @param col_names Vector of column names
#' @return Matrix with empty cells
create_adjacency_matrix <- function(row_names, col_names) {
  create_empty_adjacency_matrix(row_names, col_names)
}

#' Convert adjacency matrix to edge list
#' 
#' @param adj_matrix Adjacency matrix
#' @param from_ids Vector of source node IDs
#' @param to_ids Vector of target node IDs
#' @return Dataframe with from, to, and value columns
adjacency_to_edgelist <- function(adj_matrix, from_ids, to_ids) {

  if (is.null(adj_matrix) || nrow(adj_matrix) == 0 || ncol(adj_matrix) == 0) {
    return(data.frame(from = character(0), to = character(0), value = character(0)))
  }

  # Use list accumulation instead of incremental rbind (O(n) vs O(n^2))
  edges_list <- vector("list", nrow(adj_matrix) * ncol(adj_matrix))
  idx <- 0L

  for (i in seq_len(nrow(adj_matrix))) {
    for (j in seq_len(ncol(adj_matrix))) {
      value <- adj_matrix[i, j]

      if (!is.na(value) && value != "") {
        idx <- idx + 1L
        edges_list[[idx]] <- data.frame(
          from = from_ids[i],
          to = to_ids[j],
          value = value
        )
      }
    }
  }

  if (idx == 0L) {
    return(data.frame(from = character(0), to = character(0), value = character(0)))
  }

  do.call(rbind, edges_list[seq_len(idx)])
}

#' Convert edge list to adjacency matrix
#' 
#' @param edgelist Dataframe with from, to, value columns
#' @param from_names Vector of row names
#' @param to_names Vector of column names
#' @return Matrix
edgelist_to_adjacency <- function(edgelist, from_names, to_names) {
  
  mat <- matrix("", nrow = length(from_names), ncol = length(to_names))
  rownames(mat) <- from_names
  colnames(mat) <- to_names
  
  for (i in seq_len(nrow(edgelist))) {
    from_idx <- which(from_names == edgelist$from[i])
    to_idx <- which(to_names == edgelist$to[i])
    
    if (length(from_idx) > 0 && length(to_idx) > 0) {
      mat[from_idx, to_idx] <- edgelist$value[i]
    }
  }
  
  return(mat)
}

# ============================================================================
# DATA VALIDATION FUNCTIONS
# ============================================================================

#' Validate project data structure
#'
#' Wrapper around validate_project_structure() that returns list format
#' and includes ISA/PIMS validation.
#'
#' @param project_data Project data list
#' @return List with valid (logical) and errors (character vector)
validate_project_data <- function(project_data) {
  # Delegate structural validation to canonical validator
  errors <- validate_project_structure(project_data)

  # Add ISA validation if data is present and no structural errors
  if (length(errors) == 0 && !is.null(project_data$data$isa_data)) {
    isa_errors <- validate_isa_structure(project_data$data$isa_data)
    errors <- c(errors, isa_errors)
  }

  # Add PIMS validation if data is present and no structural errors
  if (length(errors) == 0 && !is.null(project_data$data$pims)) {
    pims_errors <- validate_pims_data(project_data$data$pims)
    errors <- c(errors, pims_errors)
  }

  list(
    valid = length(errors) == 0,
    errors = errors
  )
}

#' Validate ISA data structure
#'
#' @param isa_data ISA data list
#' @return Character vector of errors
validate_isa_structure <- function(isa_data) {

  errors <- c()

  # Check each element type
  element_types <- c("goods_benefits", "ecosystem_services",
                    "marine_processes", "pressures", "activities", "drivers")

  for (elem_type in element_types) {
    if (!is.null(isa_data[[elem_type]])) {
      elem_errors <- validate_element_data(isa_data[[elem_type]], elem_type)
      if (length(elem_errors) > 0) {
        errors <- c(errors, paste(elem_type, ":", elem_errors))
      }
    }
  }

  # Check adjacency matrices consistency
  if (!is.null(isa_data$adjacency_matrices)) {
    adj_errors <- validate_adjacency_matrices(isa_data)
    errors <- c(errors, adj_errors)
  }

  return(errors)
}

#' Validate PIMS data
#' 
#' @param pims_data PIMS data list
#' @return Character vector of errors
validate_pims_data <- function(pims_data) {
  
  errors <- c()
  
  # Validate stakeholders
  if (!is.null(pims_data$stakeholders) && nrow(pims_data$stakeholders) > 0) {
    stakeholders <- pims_data$stakeholders
    
    # Check power and interest values
    if (any(stakeholders$power < 0 | stakeholders$power > 10, na.rm = TRUE)) {
      errors <- c(errors, "Stakeholder power values must be between 0 and 10")
    }
    
    if (any(stakeholders$interest < 0 | stakeholders$interest > 10, na.rm = TRUE)) {
      errors <- c(errors, "Stakeholder interest values must be between 0 and 10")
    }
    
    # Check email format
    invalid_emails <- !sapply(stakeholders$contact_email, is_valid_email)
    if (any(invalid_emails, na.rm = TRUE)) {
      errors <- c(errors, "Some stakeholder emails are invalid")
    }
  }
  
  return(errors)
}

#' Validate adjacency matrices are consistent with elements
#' 
#' @param isa_data ISA data list
#' @return Character vector of errors
validate_adjacency_matrices <- function(isa_data) {
  
  errors <- c()
  
  # Get element counts
  n_gb <- if (!is.null(isa_data$goods_benefits)) nrow(isa_data$goods_benefits) else 0
  n_es <- if (!is.null(isa_data$ecosystem_services)) nrow(isa_data$ecosystem_services) else 0
  n_mpf <- if (!is.null(isa_data$marine_processes)) nrow(isa_data$marine_processes) else 0
  n_p <- if (!is.null(isa_data$pressures)) nrow(isa_data$pressures) else 0
  n_a <- if (!is.null(isa_data$activities)) nrow(isa_data$activities) else 0
  n_d <- if (!is.null(isa_data$drivers)) nrow(isa_data$drivers) else 0
  n_r <- if (!is.null(isa_data$responses)) nrow(isa_data$responses) else 0

  # MATRIX CONVENTION: SOURCE x TARGET (rows=SOURCE, cols=TARGET)
  # Forward causal chain: D -> A -> P -> MPF -> ES -> GB

  # Check d_a matrix (Drivers -> Activities)
  # Matrix format: rows=D, cols=A (D x A)
  if (!is.null(isa_data$adjacency_matrices$d_a)) {
    mat <- isa_data$adjacency_matrices$d_a

    if (nrow(mat) != n_d || ncol(mat) != n_a) {
      errors <- c(errors,
        sprintf("d_a matrix dimensions (%d rows x %d cols) don't match elements (%d D x %d A)",
                nrow(mat), ncol(mat), n_d, n_a))
    }
  }

  # Check a_p matrix (Activities -> Pressures)
  # Matrix format: rows=A, cols=P (A x P)
  if (!is.null(isa_data$adjacency_matrices$a_p)) {
    mat <- isa_data$adjacency_matrices$a_p

    if (nrow(mat) != n_a || ncol(mat) != n_p) {
      errors <- c(errors,
        sprintf("a_p matrix dimensions (%d rows x %d cols) don't match elements (%d A x %d P)",
                nrow(mat), ncol(mat), n_a, n_p))
    }
  }

  # Check p_mpf matrix (Pressures -> Marine Processes & Functions)
  # Matrix format: rows=P, cols=MPF (P x MPF)
  if (!is.null(isa_data$adjacency_matrices$p_mpf)) {
    mat <- isa_data$adjacency_matrices$p_mpf

    if (nrow(mat) != n_p || ncol(mat) != n_mpf) {
      errors <- c(errors,
        sprintf("p_mpf matrix dimensions (%d rows x %d cols) don't match elements (%d P x %d MPF)",
                nrow(mat), ncol(mat), n_p, n_mpf))
    }
  }

  # Check mpf_es matrix (Marine Processes -> Ecosystem Services)
  # Matrix format: rows=MPF, cols=ES (MPF x ES)
  if (!is.null(isa_data$adjacency_matrices$mpf_es)) {
    mat <- isa_data$adjacency_matrices$mpf_es

    if (nrow(mat) != n_mpf || ncol(mat) != n_es) {
      errors <- c(errors,
        sprintf("mpf_es matrix dimensions (%d rows x %d cols) don't match elements (%d MPF x %d ES)",
                nrow(mat), ncol(mat), n_mpf, n_es))
    }
  }

  # Check es_gb matrix (Ecosystem Services -> Goods & Benefits)
  # Matrix format: rows=ES, cols=GB (ES x GB)
  if (!is.null(isa_data$adjacency_matrices$es_gb)) {
    mat <- isa_data$adjacency_matrices$es_gb

    if (nrow(mat) != n_es || ncol(mat) != n_gb) {
      errors <- c(errors,
        sprintf("es_gb matrix dimensions (%d rows x %d cols) don't match elements (%d ES x %d GB)",
                nrow(mat), ncol(mat), n_es, n_gb))
    }
  }

  # Feedback loop closure

  # Check gb_d matrix (Goods & Benefits -> Drivers)
  # Matrix format: rows=GB, cols=D (GB x D)
  if (!is.null(isa_data$adjacency_matrices$gb_d)) {
    mat <- isa_data$adjacency_matrices$gb_d

    if (nrow(mat) != n_gb || ncol(mat) != n_d) {
      errors <- c(errors,
        sprintf("gb_d matrix dimensions (%d rows x %d cols) don't match elements (%d GB x %d D)",
                nrow(mat), ncol(mat), n_gb, n_d))
    }
  }

  # Response measures matrices

  # Check gb_r matrix (Goods & Benefits -> Responses)
  # Matrix format: rows=GB, cols=R (GB x R)
  if (!is.null(isa_data$adjacency_matrices$gb_r)) {
    mat <- isa_data$adjacency_matrices$gb_r

    if (nrow(mat) != n_gb || ncol(mat) != n_r) {
      errors <- c(errors,
        sprintf("gb_r matrix dimensions (%d rows x %d cols) don't match elements (%d GB x %d R)",
                nrow(mat), ncol(mat), n_gb, n_r))
    }
  }

  # Check r_d matrix (Responses -> Drivers)
  # Matrix format: rows=R, cols=D (R x D)
  if (!is.null(isa_data$adjacency_matrices$r_d)) {
    mat <- isa_data$adjacency_matrices$r_d

    if (nrow(mat) != n_r || ncol(mat) != n_d) {
      errors <- c(errors,
        sprintf("r_d matrix dimensions (%d rows x %d cols) don't match elements (%d R x %d D)",
                nrow(mat), ncol(mat), n_r, n_d))
    }
  }

  # Check r_a matrix (Responses -> Activities)
  # Matrix format: rows=R, cols=A (R x A)
  if (!is.null(isa_data$adjacency_matrices$r_a)) {
    mat <- isa_data$adjacency_matrices$r_a

    if (nrow(mat) != n_r || ncol(mat) != n_a) {
      errors <- c(errors,
        sprintf("r_a matrix dimensions (%d rows x %d cols) don't match elements (%d R x %d A)",
                nrow(mat), ncol(mat), n_r, n_a))
    }
  }

  # Check r_p matrix (Responses -> Pressures)
  # Matrix format: rows=R, cols=P (R x P)
  if (!is.null(isa_data$adjacency_matrices$r_p)) {
    mat <- isa_data$adjacency_matrices$r_p

    if (nrow(mat) != n_r || ncol(mat) != n_p) {
      errors <- c(errors,
        sprintf("r_p matrix dimensions (%d rows x %d cols) don't match elements (%d R x %d P)",
                nrow(mat), ncol(mat), n_r, n_p))
    }
  }


  return(errors)
}

# ============================================================================
# DATA IMPORT/EXPORT FUNCTIONS
# ============================================================================

#' Export project to RDS file
#' 
#' @param project_data Project data list
#' @param file_path Output file path
#' @return NULL (side effect: saves file)
export_project_rds <- function(project_data, file_path) {
  
  # Update last modified time
  project_data$last_modified <- Sys.time()
  
  # Save
  saveRDS(project_data, file_path)
  
  debug_log(paste("Project saved to:", file_path), "DATA")
}

# ============================================================================
# JSON PROJECT DATA NORMALIZATION
# ============================================================================

#' Normalize JSON-parsed project data to internal format
#'
#' When project data is loaded from JSON (via jsonlite::fromJSON), column names
#' may be uppercase (ID, Name, Type) and non-data-frame ISA fields (connections,
#' adjacency_matrices, bot_data) may be nested lists. This function normalizes
#' everything to the internal convention used by the app.
#'
#' @param data Project data list parsed from JSON
#' @return Normalized project data list, or NULL if input is invalid
#' @export
normalize_json_project_data <- function(data) {
  if (!is.list(data)) return(NULL)

  # ISA element categories that should be data frames with lowercase columns
  element_types <- c("drivers", "activities", "pressures", "marine_processes",
                     "ecosystem_services", "goods_benefits", "responses")

  isa <- data$data$isa_data
  if (!is.null(isa) && is.list(isa)) {
    for (etype in element_types) {
      el <- isa[[etype]]
      if (is.null(el)) next

      # Convert list-of-lists to data frame (happens with simplifyVector = FALSE)
      if (is.list(el) && !is.data.frame(el) && length(el) > 0) {
        el <- tryCatch({
          do.call(rbind, lapply(el, function(x) {
            as.data.frame(x, stringsAsFactors = FALSE)
          }))
        }, error = function(e) {
          debug_log(paste("Cannot convert", etype, "to data.frame:", e$message), "WARN")
          NULL
        })
      }

      if (is.data.frame(el)) {
        # Lowercase all column names
        names(el) <- tolower(names(el))

        # Ensure required columns exist with defaults
        if (!"id" %in% names(el) && nrow(el) > 0) {
          prefix <- switch(etype,
            drivers = "D", activities = "A", pressures = "P",
            marine_processes = "MPF", ecosystem_services = "ES",
            goods_benefits = "GB", responses = "R", "X"
          )
          el$id <- paste0(prefix, sprintf("%03d", seq_len(nrow(el))))
        }
        if (!"name" %in% names(el) && nrow(el) > 0) {
          el$name <- el$id
        }
        if (!"indicator" %in% names(el)) {
          el$indicator <- NA_character_
        }
      }

      isa[[etype]] <- el
    }

    # Normalize connections: keep as-is (list with suggested/approved)
    # Downstream code handles both formats

    data$data$isa_data <- isa
  }

  data
}

# ============================================================================
# PROJECT VALIDATION FUNCTIONS
# ============================================================================

#' Validate project data structure
#'
#' Validates that a project object has all required fields and correct types.
#' This is the canonical implementation - other duplicates have been removed.
#'
#' @param data Project data list
#' @return Character vector of error messages (empty if valid)
#' @export
validate_project_structure <- function(data) {
  errors <- c()

  # Check if data is a list
  if (!is.list(data)) {
    errors <- c(errors, "Project data must be a list")
    return(errors)
  }

  # Essential keys (must have)
  essential_keys <- c("project_id", "project_name", "data")
  missing_keys <- setdiff(essential_keys, names(data))

  if (length(missing_keys) > 0) {
    errors <- c(errors, paste("Missing required fields:",
                             paste(missing_keys, collapse = ", ")))
  }

  # Check that data is a list
  if (!"data" %in% names(data) || !is.list(data$data)) {
    errors <- c(errors, "Project data$data must be a list")
  }

  # Basic type validation
  if ("project_id" %in% names(data)) {
    if (!is.character(data$project_id) || length(data$project_id) != 1) {
      errors <- c(errors, "project_id must be a single character string")
    }
  }

  if ("project_name" %in% names(data)) {
    if (!is.character(data$project_name) || length(data$project_name) != 1) {
      errors <- c(errors, "project_name must be a single character string")
    }
  }

  # Date validation - accept both 'created' and 'created_at' field names
  has_created <- "created" %in% names(data)
  has_created_at <- "created_at" %in% names(data)

  if (!has_created && !has_created_at) {
    errors <- c(errors, "Missing creation date field (created or created_at)")
  } else {
    # Validate the date field that exists
    created_field <- if (has_created) data$created else data$created_at
    if (!inherits(created_field, "POSIXct") && !is.character(created_field)) {
      errors <- c(errors, "Creation date must be POSIXct or character")
    }
  }

  # Validate last_modified if present (optional for backward compatibility)
  if ("last_modified" %in% names(data)) {
    if (!inherits(data$last_modified, "POSIXct") && !is.character(data$last_modified)) {
      errors <- c(errors, "last_modified must be POSIXct or character")
    }
  }

  return(errors)
}

#' Validate DAPSI(W)R(M) element data
#'
#' Validates element data frame and returns any validation errors.
#' This is the canonical implementation - other duplicates have been removed.
#'
#' @param data Element data frame
#' @param element_type Element type name
#' @return Character vector of error messages (empty if valid)
#' @export
validate_element_data <- function(data, element_type) {
  errors <- c()

  # Check required columns
  required_cols <- c("id", "name", "indicator")
  missing_cols <- setdiff(required_cols, names(data))

  if (length(missing_cols) > 0) {
    errors <- c(errors, paste("Missing required columns:",
                             paste(missing_cols, collapse = ", ")))
  }

  # Check for duplicate IDs
  if (any(duplicated(data$id))) {
    errors <- c(errors, "Duplicate IDs found")
  }

  # Check for empty names
  if (any(is.na(data$name) | data$name == "")) {
    errors <- c(errors, "Empty names found")
  }

  return(errors)
}

#' Validate adjacency matrix
#'
#' Validates adjacency matrix format and values.
#' This is the canonical implementation - other duplicates have been removed.
#'
#' @param adj_matrix Adjacency matrix to validate
#' @return Character vector of error messages (empty if valid)
#' @export
validate_adjacency_matrix <- function(adj_matrix) {
  errors <- c()

  # Check if matrix
  if (!is.matrix(adj_matrix)) {
    errors <- c(errors, "Not a valid matrix")
    return(errors)
  }

  # Check dimensions
  if (nrow(adj_matrix) == 0 || ncol(adj_matrix) == 0) {
    errors <- c(errors, "Matrix has zero dimensions")
  }

  # Check values
  valid_values <- c("", NA,
                   paste0("+", CONNECTION_STRENGTH),
                   paste0("-", CONNECTION_STRENGTH))

  invalid_values <- !adj_matrix %in% valid_values
  if (any(invalid_values, na.rm = TRUE)) {
    errors <- c(errors, "Invalid connection values found")
  }

  return(errors)
}

# ============================================================================
# SAFE WRAPPER FUNCTIONS
# These add NULL checks and error handling before calling the core functions above.
# ============================================================================

#' Validate a DAPSI(W)R(M) element type string
#'
#' @param type Character string of element type to validate
#' @return TRUE if valid, otherwise stops with an error
#' @export
validate_element_type <- function(type) {
  if (is.null(type)) stop("Element type is NULL")
  valid_types <- c(
    "Goods & Benefits",
    "Ecosystem Services",
    "Marine Processes & Functioning",
    "Pressures",
    "Activities",
    "Drivers",
    "Responses"
  )
  if (!type %in% valid_types) stop("Invalid element type")
  TRUE
}

#' Validate that adjacency matrix dimension inputs are not NULL
#'
#' @param from_elements Vector of source element names
#' @param to_elements Vector of target element names
#' @return TRUE if valid, otherwise stops with an error
#' @export
validate_adjacency_dimensions <- function(from_elements, to_elements) {
  if (is.null(from_elements)) stop("from_elements is NULL")
  if (is.null(to_elements)) stop("to_elements is NULL")
  TRUE
}

#' Safe wrapper around create_empty_project with input validation
#'
#' Validates and sanitizes inputs before creating a project. Returns NULL on failure.
#'
#' @param project_name Character string for the project name (max 200 chars)
#' @param da_site Optional demonstration area site (character or NULL)
#' @return Project data list, or NULL if inputs are invalid
#' @export
create_empty_project_safe <- function(project_name = "New Project", da_site = NULL) {
  # Validate project_name
  if (is.null(project_name) || !is.character(project_name) || nchar(trimws(project_name)) == 0) return(NULL)
  # Truncate if too long
  if (nchar(project_name) > 200) project_name <- substr(project_name, 1, 200)

  # Validate da_site: must be character or NULL
  if (!is.null(da_site) && !is.character(da_site)) {
    da_site <- NULL
  }

  proj <- tryCatch({
    create_empty_project(project_name, da_site)
  }, error = function(e) {
    if (exists("debug_log", mode = "function")) {
      debug_log(sprintf("create_empty_project_safe failed: %s", e$message), "DATA_STRUCTURE")
    }
    NULL
  })

  # Ensure required fields are present
  if (is.null(proj) || !all(c("project_id", "project_name", "data") %in% names(proj))) return(NULL)

  # Ensure metadata da_site is character or NULL
  if (!is.null(proj$data$metadata$da_site) && !is.character(proj$data$metadata$da_site)) {
    proj$data$metadata$da_site <- NULL
  }

  return(proj)
}

#' Safely add an element row to an ISA data list
#'
#' Validates inputs and appends the row to the specified element type.
#'
#' @param isa_data ISA data list containing element data frames
#' @param elem_name Character key for the element type (e.g., "drivers")
#' @param elem_row Data frame row or list to append
#' @return Updated ISA data list, NULL if isa_data is NULL, or unchanged isa_data on invalid input
#' @export
add_element_safe <- function(isa_data, elem_name, elem_row) {
  # If isa_data is NULL, return NULL per tests
  if (is.null(isa_data)) return(NULL)
  if (!is.list(isa_data)) stop("isa_data must be a list")
  if (is.null(elem_name) || !nzchar(elem_name)) return(isa_data)
  if (is.null(elem_row)) return(isa_data)

  # Validate element type - must be one of expected keys or create if missing
  valid_elem_names <- c("goods_benefits", "ecosystem_services", "marine_processes", "pressures", "activities", "drivers", "responses")
  if (!elem_name %in% valid_elem_names) return(isa_data)

  # Ensure element list exists
  if (is.null(isa_data[[elem_name]])) {
    isa_data[[elem_name]] <- create_empty_element_df(gsub("_", " ", elem_name))
  }

  # Append row (coerce to data.frame if needed)
  if (!is.data.frame(elem_row)) elem_row <- as.data.frame(elem_row)
  isa_data[[elem_name]] <- rbind(isa_data[[elem_name]], elem_row)

  return(isa_data)
}

#' Safe wrapper around create_empty_element_df with type validation
#'
#' @param element_type Character string of DAPSI(W)R(M) element type
#' @return Empty data frame for the element type, or NULL if type is invalid
#' @export
create_empty_element_df_safe <- function(element_type) {
  if (is.null(element_type) || !is.character(element_type)) return(NULL)
  # Use existing implementation
  if (!element_type %in% c(
    "Goods & Benefits","Ecosystem Services","Marine Processes & Functioning",
    "Pressures","Activities","Drivers","Responses"
  )) return(NULL)
  create_empty_element_df(element_type)
}

#' Safe wrapper around create_empty_adjacency_matrix with NULL checks
#'
#' Deduplicates element names and returns NULL instead of erroring on bad input.
#'
#' @param from_elements Vector of source element names
#' @param to_elements Vector of target element names
#' @return Adjacency matrix, or NULL if inputs are NULL
#' @export
create_empty_adjacency_matrix_safe <- function(from_elements, to_elements) {
  if (is.null(from_elements) || is.null(to_elements)) {
    if (exists("debug_log", mode = "function")) {
      debug_log("create_empty_adjacency_matrix_safe: NULL from_elements or to_elements", "DATA_STRUCTURE")
    }
    return(NULL)
  }
  # Remove duplicates and preserve order
  from_u <- unique(from_elements)
  to_u <- unique(to_elements)
  # If either vector empty, return empty matrix with 0 rows
  if (length(from_u) == 0 || length(to_u) == 0) {
    if (exists("debug_log", mode = "function")) {
      debug_log("create_empty_adjacency_matrix_safe: empty from or to elements after deduplication", "DATA_STRUCTURE")
    }
    return(matrix(nrow = 0, ncol = 0))
  }
  create_empty_adjacency_matrix(from_u, to_u)
}

#' Safe wrapper around adjacency_to_edgelist with input validation
#'
#' @param mat Adjacency matrix with row and column names
#' @param from_ids Vector of source IDs matching matrix rows
#' @param to_ids Vector of target IDs matching matrix columns
#' @return Edge list data frame, or NULL on invalid input
#' @export
adjacency_to_edgelist_safe <- function(mat, from_ids, to_ids) {
  log_fn <- if (exists("debug_log", mode = "function")) debug_log else function(...) invisible(NULL)

  if (is.null(mat)) {
    log_fn("adjacency_to_edgelist_safe: mat is NULL", "DATA_STRUCTURE")
    return(NULL)
  }
  if (!is.matrix(mat)) {
    log_fn(sprintf("adjacency_to_edgelist_safe: mat is not a matrix (class: %s)", class(mat)[1]), "DATA_STRUCTURE")
    return(NULL)
  }
  if (is.null(rownames(mat)) || is.null(colnames(mat))) {
    log_fn("adjacency_to_edgelist_safe: mat missing rownames or colnames", "DATA_STRUCTURE")
    return(NULL)
  }
  if (length(from_ids) != nrow(mat) || length(to_ids) != ncol(mat)) {
    log_fn(sprintf("adjacency_to_edgelist_safe: dimension mismatch - from_ids(%d) vs rows(%d), to_ids(%d) vs cols(%d)",
                   length(from_ids), nrow(mat), length(to_ids), ncol(mat)), "DATA_STRUCTURE")
    return(NULL)
  }
  adjacency_to_edgelist(mat, from_ids, to_ids)
}

#' Safe wrapper around edgelist_to_adjacency with input validation
#'
#' @param edgelist Data frame with from, to, and value columns
#' @param from_names Vector of row names for the resulting matrix
#' @param to_names Vector of column names for the resulting matrix
#' @return Adjacency matrix, or NULL on invalid input
#' @export
edgelist_to_adjacency_safe <- function(edgelist, from_names, to_names) {
  log_fn <- if (exists("debug_log", mode = "function")) debug_log else function(...) invisible(NULL)

  if (is.null(edgelist)) {
    log_fn("edgelist_to_adjacency_safe: edgelist is NULL", "DATA_STRUCTURE")
    return(NULL)
  }
  if (!is.data.frame(edgelist)) {
    log_fn(sprintf("edgelist_to_adjacency_safe: edgelist is not a data.frame (class: %s)", class(edgelist)[1]), "DATA_STRUCTURE")
    return(NULL)
  }
  if (!all(c("from", "to", "value") %in% names(edgelist))) {
    log_fn(sprintf("edgelist_to_adjacency_safe: edgelist missing required columns. Has: %s", paste(names(edgelist), collapse = ", ")), "DATA_STRUCTURE")
    return(NULL)
  }
  edgelist_to_adjacency(edgelist, from_names, to_names)
}

#' Safe wrapper around validate_project_data that handles NULL input
#'
#' @param project_data Project data list, or NULL
#' @return List with valid (logical) and errors (character vector)
#' @export
validate_project_data_safe <- function(project_data) {
  if (is.null(project_data)) return(list(valid = FALSE, errors = c("Project is NULL")))
  validate_project_data(project_data)
}

#' Safe wrapper around validate_isa_structure with NULL and type checks
#'
#' @param isa_data ISA data list, or NULL
#' @return Character vector of error messages
#' @export
validate_isa_structure_safe <- function(isa_data) {
  if (is.null(isa_data)) return(c("ISA data is NULL"))
  if (!is.list(isa_data)) return(c("ISA data must be a list"))
  errs <- c()
  for (n in names(isa_data)) {
    df <- isa_data[[n]]
    if (!is.data.frame(df)) {
      errs <- c(errs, paste(n, "is not a dataframe"))
      next
    }
    # Require id and name columns
    if (!all(c("id", "name") %in% names(df))) {
      errs <- c(errs, paste(n, "missing id or name columns"))
    }
  }
  errs
}

#' Safe wrapper around validate_pims_data with NULL handling
#'
#' @param pims_data PIMS data list, or NULL
#' @return Character vector of error messages (empty if valid or NULL)
#' @export
validate_pims_data_safe <- function(pims_data) {
  errs <- c()
  if (is.null(pims_data)) return(errs)
  if (!is.null(pims_data$stakeholders) && nrow(pims_data$stakeholders) > 0) {
    if ("power" %in% names(pims_data$stakeholders)) {
      if (any(pims_data$stakeholders$power < 0 | pims_data$stakeholders$power > 10, na.rm = TRUE)) {
        errs <- c(errs, "power")
      }
    }
  }
  errs
}

#' Create a complete empty ISA data structure with all element types
#'
#' @return List of empty data frames for each DAPSI(W)R(M) element type
#' @export
create_empty_isa_structure_safe <- function() {
  list(
    goods_benefits = create_empty_element_df("Goods & Benefits"),
    ecosystem_services = create_empty_element_df("Ecosystem Services"),
    marine_processes = create_empty_element_df("Marine Processes & Functioning"),
    pressures = create_empty_element_df("Pressures"),
    activities = create_empty_element_df("Activities"),
    drivers = create_empty_element_df("Drivers")
  )
}

#' Safely update an element row in an ISA data list by ID
#'
#' @param isa_data ISA data list containing element data frames
#' @param elem_name Character key for the element type (e.g., "drivers")
#' @param id Character ID of the element to update
#' @param new_element Named list or data frame row with updated values
#' @return Updated ISA data list, or unchanged isa_data if element not found
#' @export
update_element_safe <- function(isa_data, elem_name, id, new_element) {
  if (is.null(isa_data) || is.null(isa_data[[elem_name]])) return(isa_data)
  df <- isa_data[[elem_name]]
  idx <- which(df$id == id)
  if (length(idx) == 0) return(isa_data)
  df[idx, names(new_element)] <- new_element
  isa_data[[elem_name]] <- df
  isa_data
}

#' Safely delete an element row from an ISA data list by ID
#'
#' @param isa_data ISA data list containing element data frames
#' @param elem_name Character key for the element type (e.g., "drivers")
#' @param id Character ID of the element to delete
#' @return Updated ISA data list with the element removed
#' @export
delete_element_safe <- function(isa_data, elem_name, id) {
  if (is.null(isa_data) || is.null(isa_data[[elem_name]])) return(isa_data)
  df <- isa_data[[elem_name]]
  df <- df[df$id != id, , drop = FALSE]
  isa_data[[elem_name]] <- df
  isa_data
}
