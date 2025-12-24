# functions/data_structure.R
# Data structure definitions and initialization functions

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
        sub_systems = NULL
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
          notes = character(),
          stringsAsFactors = FALSE
        ),
        
        risks = data.frame(
          id = character(),
          date_identified = as.Date(character()),
          description = character(),
          likelihood = character(),
          severity = character(),
          mitigation_actions = character(),
          owner = character(),
          status = character(),
          stringsAsFactors = FALSE
        ),
        
        resources = data.frame(
          id = character(),
          type = character(),
          description = character(),
          quantity = numeric(),
          unit = character(),
          cost = numeric(),
          allocated_to = character(),
          notes = character(),
          stringsAsFactors = FALSE
        ),
        
        data_management = list(
          dmp_exists = FALSE,
          gdpr_compliant = FALSE,
          data_sources = data.frame(
            source_name = character(),
            type = character(),
            provider = character(),
            quality_rating = character(),
            last_updated = as.Date(character()),
            stringsAsFactors = FALSE
          )
        ),
        
        evaluation = list(
          process = data.frame(
            question = character(),
            response_type = character(),
            responses = character(),
            stringsAsFactors = FALSE
          ),
          outcome = data.frame(
            objective = character(),
            indicator = character(),
            baseline = numeric(),
            target = numeric(),
            current = numeric(),
            deadline = as.Date(character()),
            stringsAsFactors = FALSE
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
            value = numeric(),
            stringsAsFactors = FALSE
          ),
          ecosystem_services = data.frame(
            date = as.Date(character()),
            element_id = character(),
            value = numeric(),
            stringsAsFactors = FALSE
          ),
          marine_processes = data.frame(
            date = as.Date(character()),
            element_id = character(),
            value = numeric(),
            stringsAsFactors = FALSE
          ),
          pressures = data.frame(
            date = as.Date(character()),
            element_id = character(),
            value = numeric(),
            stringsAsFactors = FALSE
          ),
          activities = data.frame(
            date = as.Date(character()),
            element_id = character(),
            value = numeric(),
            stringsAsFactors = FALSE
          ),
          drivers = data.frame(
            date = as.Date(character()),
            element_id = character(),
            value = numeric(),
            stringsAsFactors = FALSE
          ),
          responses = data.frame(
            date = as.Date(character()),
            element_id = character(),
            value = numeric(),
            stringsAsFactors = FALSE
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
        scenarios = list()  # Scenario analysis results
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
    notes = character(),
    stringsAsFactors = FALSE
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
  
  edgelist <- data.frame()
  
  for (i in 1:nrow(adj_matrix)) {
    for (j in 1:ncol(adj_matrix)) {
      value <- adj_matrix[i, j]
      
      if (!is.na(value) && value != "") {
        edge <- data.frame(
          from = from_ids[i],
          to = to_ids[j],
          value = value,
          stringsAsFactors = FALSE
        )
        edgelist <- rbind(edgelist, edge)
      }
    }
  }
  
  return(edgelist)
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
  
  for (i in 1:nrow(edgelist)) {
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
#' @param project_data Project data list
#' @return List with valid (logical) and errors (character vector)
validate_project_data <- function(project_data) {
  
  errors <- c()
  
  # Check required top-level fields
  required_fields <- c("project_id", "project_name", "created_at", "data")
  missing_fields <- setdiff(required_fields, names(project_data))
  
  if (length(missing_fields) > 0) {
    errors <- c(errors, paste("Missing required fields:", 
                             paste(missing_fields, collapse = ", ")))
  }
  
  # Validate ISA data
  if (!is.null(project_data$data$isa_data)) {
    isa_errors <- validate_isa_structure(project_data$data$isa_data)
    errors <- c(errors, isa_errors)
  }
  
  # Validate PIMS data
  if (!is.null(project_data$data$pims)) {
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

  # Check GB-ES matrix (Goods & Benefits <- Ecosystem Services)
  # Matrix format: rows=GB, cols=ES (GB × ES)
  if (!is.null(isa_data$adjacency_matrices$gb_es)) {
    mat <- isa_data$adjacency_matrices$gb_es

    if (nrow(mat) != n_gb || ncol(mat) != n_es) {
      errors <- c(errors,
        sprintf("GB-ES matrix dimensions (%d rows × %d cols) don't match elements (%d GB × %d ES)",
                nrow(mat), ncol(mat), n_gb, n_es))
    }
  }

  # Check ES-MPF matrix (Ecosystem Services <- Marine Processes)
  # Matrix format: rows=ES, cols=MPF (ES × MPF)
  if (!is.null(isa_data$adjacency_matrices$es_mpf)) {
    mat <- isa_data$adjacency_matrices$es_mpf

    if (nrow(mat) != n_es || ncol(mat) != n_mpf) {
      errors <- c(errors,
        sprintf("ES-MPF matrix dimensions (%d rows × %d cols) don't match elements (%d ES × %d MPF)",
                nrow(mat), ncol(mat), n_es, n_mpf))
    }
  }

  # Check MPF-P matrix (Marine Processes <- Pressures)
  # Matrix format: rows=MPF, cols=P (MPF × P)
  if (!is.null(isa_data$adjacency_matrices$mpf_p)) {
    mat <- isa_data$adjacency_matrices$mpf_p

    if (nrow(mat) != n_mpf || ncol(mat) != n_p) {
      errors <- c(errors,
        sprintf("MPF-P matrix dimensions (%d rows × %d cols) don't match elements (%d MPF × %d P)",
                nrow(mat), ncol(mat), n_mpf, n_p))
    }
  }

  # Check P-A matrix (Pressures <- Activities)
  # Matrix format: rows=P, cols=A (P × A)
  if (!is.null(isa_data$adjacency_matrices$p_a)) {
    mat <- isa_data$adjacency_matrices$p_a

    if (nrow(mat) != n_p || ncol(mat) != n_a) {
      errors <- c(errors,
        sprintf("P-A matrix dimensions (%d rows × %d cols) don't match elements (%d P × %d A)",
                nrow(mat), ncol(mat), n_p, n_a))
    }
  }

  # Check A-D matrix (Activities <- Drivers)
  # Matrix format: rows=A, cols=D (A × D)
  if (!is.null(isa_data$adjacency_matrices$a_d)) {
    mat <- isa_data$adjacency_matrices$a_d

    if (nrow(mat) != n_a || ncol(mat) != n_d) {
      errors <- c(errors,
        sprintf("A-D matrix dimensions (%d rows × %d cols) don't match elements (%d A × %d D)",
                nrow(mat), ncol(mat), n_a, n_d))
    }
  }

  # Check D-GB matrix (Drivers <- Goods & Benefits)
  # Matrix format: rows=D, cols=GB (D × GB)
  if (!is.null(isa_data$adjacency_matrices$d_gb)) {
    mat <- isa_data$adjacency_matrices$d_gb

    if (nrow(mat) != n_d || ncol(mat) != n_gb) {
      errors <- c(errors,
        sprintf("D-GB matrix dimensions (%d rows × %d cols) don't match elements (%d D × %d GB)",
                nrow(mat), ncol(mat), n_d, n_gb))
    }
  }

  return(errors)
}

# ============================================================================
# DATA IMPORT/EXPORT FUNCTIONS
# ============================================================================

#' Import project from RDS file
#' 
#' @param file_path Path to RDS file
#' @return Project data list
import_project_rds <- function(file_path) {
  
  if (!file.exists(file_path)) {
    stop("File does not exist: ", file_path)
  }
  
  project_data <- readRDS(file_path)
  
  # Validate
  validation <- validate_project_data(project_data)
  
  if (!validation$valid) {
    warning("Project data validation errors:\n", 
           paste(validation$errors, collapse = "\n"))
  }
  
  return(project_data)
}

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
  
  message("Project saved to: ", file_path)
}

#' Import ISA data from Excel workbook
#' 
#' @param file_path Path to Excel file
#' @return ISA data list
import_isa_excel <- function(file_path) {
  
  if (!file.exists(file_path)) {
    stop("File does not exist: ", file_path)
  }
  
  wb <- loadWorkbook(file_path)
  sheets <- getSheetNames(file_path)
  
  isa_data <- list()
  
  # Read each element sheet
  if ("Goods_Benefits" %in% sheets) {
    isa_data$goods_benefits <- read.xlsx(wb, sheet = "Goods_Benefits")
  }
  
  if ("Ecosystem_Services" %in% sheets) {
    isa_data$ecosystem_services <- read.xlsx(wb, sheet = "Ecosystem_Services")
  }
  
  if ("Marine_Processes" %in% sheets) {
    isa_data$marine_processes <- read.xlsx(wb, sheet = "Marine_Processes")
  }
  
  if ("Pressures" %in% sheets) {
    isa_data$pressures <- read.xlsx(wb, sheet = "Pressures")
  }
  
  if ("Activities" %in% sheets) {
    isa_data$activities <- read.xlsx(wb, sheet = "Activities")
  }
  
  if ("Drivers" %in% sheets) {
    isa_data$drivers <- read.xlsx(wb, sheet = "Drivers")
  }
  
  # Read adjacency matrices
  isa_data$adjacency_matrices <- list()
  
  adj_sheets <- c("GB_ES", "ES_MPF", "MPF_P", "P_A", "A_D", "D_GB")
  adj_names <- c("gb_es", "es_mpf", "mpf_p", "p_a", "a_d", "d_gb")
  
  for (i in seq_along(adj_sheets)) {
    if (adj_sheets[i] %in% sheets) {
      mat_df <- read.xlsx(wb, sheet = adj_sheets[i], rowNames = TRUE)
      isa_data$adjacency_matrices[[adj_names[i]]] <- as.matrix(mat_df)
    }
  }
  
  return(isa_data)
}

#' Export ISA data to Excel workbook
#' 
#' @param isa_data ISA data list
#' @param file_path Output file path
#' @return NULL (side effect: saves file)
export_isa_excel <- function(isa_data, file_path) {
  
  wb <- createWorkbook()
  
  # Add element sheets
  if (!is.null(isa_data$goods_benefits)) {
    addWorksheet(wb, "Goods_Benefits")
    writeData(wb, "Goods_Benefits", isa_data$goods_benefits)
  }
  
  if (!is.null(isa_data$ecosystem_services)) {
    addWorksheet(wb, "Ecosystem_Services")
    writeData(wb, "Ecosystem_Services", isa_data$ecosystem_services)
  }
  
  if (!is.null(isa_data$marine_processes)) {
    addWorksheet(wb, "Marine_Processes")
    writeData(wb, "Marine_Processes", isa_data$marine_processes)
  }
  
  if (!is.null(isa_data$pressures)) {
    addWorksheet(wb, "Pressures")
    writeData(wb, "Pressures", isa_data$pressures)
  }
  
  if (!is.null(isa_data$activities)) {
    addWorksheet(wb, "Activities")
    writeData(wb, "Activities", isa_data$activities)
  }
  
  if (!is.null(isa_data$drivers)) {
    addWorksheet(wb, "Drivers")
    writeData(wb, "Drivers", isa_data$drivers)
  }
  
  # Add adjacency matrix sheets
  adj_names <- names(isa_data$adjacency_matrices)
  for (adj_name in adj_names) {
    mat <- isa_data$adjacency_matrices[[adj_name]]
    if (!is.null(mat)) {
      sheet_name <- toupper(gsub("_", "_", adj_name))
      addWorksheet(wb, sheet_name)
      writeData(wb, sheet_name, mat, rowNames = TRUE)
    }
  }
  
  saveWorkbook(wb, file_path, overwrite = TRUE)
  
  message("ISA data exported to: ", file_path)
}

# ============================================================================
# DATA MANIPULATION FUNCTIONS
# ============================================================================

#' Add element to ISA data
#' 
#' @param isa_data ISA data list
#' @param element_type Element type (e.g., "goods_benefits")
#' @param element_data Single row dataframe with element data
#' @return Updated ISA data list
add_element <- function(isa_data, element_type, element_data) {
  
  # Generate ID if not provided
  if (is.null(element_data$id) || element_data$id == "") {
    element_data$id <- generate_id(toupper(substr(element_type, 1, 2)))
  }
  
  # Add to appropriate dataframe
  if (is.null(isa_data[[element_type]]) || nrow(isa_data[[element_type]]) == 0) {
    isa_data[[element_type]] <- element_data
  } else {
    isa_data[[element_type]] <- rbind(isa_data[[element_type]], element_data)
  }
  
  return(isa_data)
}

#' Update element in ISA data
#' 
#' @param isa_data ISA data list
#' @param element_type Element type
#' @param element_id Element ID to update
#' @param element_data Updated element data
#' @return Updated ISA data list
update_element <- function(isa_data, element_type, element_id, element_data) {
  
  idx <- which(isa_data[[element_type]]$id == element_id)
  
  if (length(idx) == 0) {
    warning("Element not found: ", element_id)
    return(isa_data)
  }
  
  isa_data[[element_type]][idx, ] <- element_data
  
  return(isa_data)
}

#' Delete element from ISA data
#' 
#' @param isa_data ISA data list
#' @param element_type Element type
#' @param element_id Element ID to delete
#' @return Updated ISA data list
delete_element <- function(isa_data, element_type, element_id) {
  
  isa_data[[element_type]] <- isa_data[[element_type]] %>%
    filter(id != element_id)
  
  return(isa_data)
}
