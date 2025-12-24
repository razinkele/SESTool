# functions/data_structure_enhanced.R
# Enhanced wrappers for data structure validation and safe creation

# Validate project structure with informative errors
validate_project_structure <- function(data) {
  if (is.null(data)) stop("Project data is NULL")
  if (!is.list(data)) stop("Project data must be a list")

  required <- c("project_id", "project_name", "data")
  missing <- setdiff(required, names(data))
  if (length(missing) > 0) stop("Missing required project fields")

  TRUE
}

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

validate_element_data <- function(df) {
  if (is.null(df)) stop("Element dataframe is NULL")
  if (!is.data.frame(df)) stop("Element data must be dataframe")
  required_cols <- c("id", "name")
  if (!all(required_cols %in% names(df))) stop("Missing required columns")
  TRUE
}

validate_adjacency_dimensions <- function(from_elements, to_elements) {
  if (is.null(from_elements)) stop("from_elements is NULL")
  if (is.null(to_elements)) stop("to_elements is NULL")
  TRUE
}

validate_adjacency_matrix <- function(mat) {
  if (is.null(mat)) stop("Adjacency matrix is NULL")
  if (!is.matrix(mat)) stop("Adjacency matrix must be matrix")
  if (is.null(rownames(mat)) || is.null(colnames(mat))) stop("Adjacency matrix must have row and column names")
  TRUE
}

# Safe create empty project wrapper
create_empty_project_safe <- function(project_name = "New Project", da_site = NULL) {
  # Validate project_name
  if (is.null(project_name) || !is.character(project_name) || nchar(trimws(project_name)) == 0) return(NULL)
  # Truncate if too long
  if (nchar(project_name) > 200) project_name <- substr(project_name, 1, 200)

  # Validate da_site: must be character or NULL
  if (!is.null(da_site) && !is.character(da_site)) {
    da_site <- NULL
  }

  # Use existing create_empty_project if available
  if (exists("create_empty_project")) {
    proj <- tryCatch({
      create_empty_project(project_name, da_site)
    }, error = function(e) {
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

  # Fallback minimal structure
  list(
    project_id = paste0("PROJ_", format(Sys.time(), "%Y%m%d%H%M%S")),
    project_name = project_name,
    created_at = Sys.time(),
    last_modified = Sys.time(),
    user = Sys.info()["user"],
    data = list(
      metadata = list(da_site = da_site),
      pims = list(stakeholders = data.frame(), risks = data.frame()),
      isa_data = list(),
      cld = list(nodes = data.frame(), edges = data.frame()),
      responses = list()
    )
  )
}

# Helper to safely add an element to isa_data lists
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
  if (!is.data.frame(elem_row)) elem_row <- as.data.frame(elem_row, stringsAsFactors = FALSE)
  isa_data[[elem_name]] <- rbind(isa_data[[elem_name]], elem_row)

  return(isa_data)
}

# Create empty element df safe wrapper
create_empty_element_df_safe <- function(element_type) {
  if (is.null(element_type) || !is.character(element_type)) return(NULL)
  # Use existing implementation
  if (!element_type %in% c(
    "Goods & Benefits","Ecosystem Services","Marine Processes & Functioning",
    "Pressures","Activities","Drivers","Responses"
  )) return(NULL)
  create_empty_element_df(element_type)
}

# Safe adjacency matrix and conversion helpers
create_empty_adjacency_matrix_safe <- function(from_elements, to_elements) {
  if (is.null(from_elements) || is.null(to_elements)) return(NULL)
  # Remove duplicates and preserve order
  from_u <- unique(from_elements)
  to_u <- unique(to_elements)
  # If either vector empty, return empty matrix with 0 rows
  if (length(from_u) == 0 || length(to_u) == 0) return(matrix(nrow = 0, ncol = 0))
  create_empty_adjacency_matrix(from_u, to_u)
}

adjacency_to_edgelist_safe <- function(mat, from_ids, to_ids) {
  if (is.null(mat)) return(NULL)
  if (!is.matrix(mat)) return(NULL)
  if (is.null(rownames(mat)) || is.null(colnames(mat))) return(NULL)
  if (length(from_ids) != nrow(mat) || length(to_ids) != ncol(mat)) return(NULL)
  adjacency_to_edgelist(mat, from_ids, to_ids)
}

edgelist_to_adjacency_safe <- function(edgelist, from_names, to_names) {
  if (is.null(edgelist)) return(NULL)
  if (!is.data.frame(edgelist)) return(NULL)
  if (!all(c("from", "to", "value") %in% names(edgelist))) return(NULL)
  edgelist_to_adjacency(edgelist, from_names, to_names)
}

# Project validation safe wrappers
validate_project_data_safe <- function(project_data) {
  if (is.null(project_data)) return(list(valid = FALSE, errors = c("Project is NULL")))
  # Use existing validator if available
  if (exists("validate_project_data")) {
    res <- validate_project_data(project_data)
    return(res)
  }
  # Basic validation
  errors <- c()
  required_fields <- c("project_id", "project_name", "data")
  missing <- setdiff(required_fields, names(project_data))
  if (length(missing) > 0) errors <- c(errors, paste("Missing fields:", paste(missing, collapse = ", ")))
  list(valid = length(errors) == 0, errors = errors)
}

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

# Helpers for ISA structure creation and element updates
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

update_element_safe <- function(isa_data, elem_name, id, new_element) {
  if (is.null(isa_data) || is.null(isa_data[[elem_name]])) return(isa_data)
  df <- isa_data[[elem_name]]
  idx <- which(df$id == id)
  if (length(idx) == 0) return(isa_data)
  df[idx, names(new_element)] <- new_element
  isa_data[[elem_name]] <- df
  isa_data
}

delete_element_safe <- function(isa_data, elem_name, id) {
  if (is.null(isa_data) || is.null(isa_data[[elem_name]])) return(isa_data)
  df <- isa_data[[elem_name]]
  df <- df[df$id != id, , drop = FALSE]
  isa_data[[elem_name]] <- df
  isa_data
}
