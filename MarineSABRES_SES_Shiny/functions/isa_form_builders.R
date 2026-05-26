# functions/isa_form_builders.R
# Extracted from modules/isa_data_entry_module.R
# Reusable form builders and entry collection helpers for ISA DAPSI(W)R(M) elements

# ============================================================================
# ELEMENT ENTRY FORM PANEL BUILDERS
# ============================================================================

#' Build a dynamic ISA entry panel for insertUI
#'
#' Each element type (GB, ES, MPF, P, A, D) follows the same structure:
#' a styled div with two fluidRows of form inputs and a remove button.
#'
#' @param ns Shiny namespace function
#' @param prefix Short prefix for input IDs (e.g. "gb", "es", "mpf", "p", "a", "d")
#' @param current_id Numeric counter for this entry
#' @param fields List of field definitions. Each is a list with:
#'   \itemize{
#'     \item \code{id} - suffix for the input ID (appended to prefix)
#'     \item \code{type} - "text" or "select"
#'     \item \code{label} - translated label string
#'     \item \code{width} - column width (1-12)
#'     \item \code{choices} - (for select) vector of choices
#'     \item \code{placeholder} - (for text) placeholder string
#'   }
#' @param i18n Translation object (used for remove button label)
#' @return A shiny div tag suitable for insertUI
build_entry_panel_ui <- function(ns, prefix, current_id, fields, i18n) {
  # Split fields into two rows roughly evenly
  # First row: first 3 fields, Second row: remaining fields + remove button
  row1_fields <- fields[seq_len(min(3, length(fields)))]
  row2_fields <- if (length(fields) > 3) fields[4:length(fields)] else list()

  build_field <- function(field) {
    input_id <- ns(paste0(prefix, "_", field$id, "_", current_id))
    if (identical(field$type, "select")) {
      # Forward `selected = field$selected` so the field-definition default
      # actually applies in the rendered HTML. Without this, the explicit
      # `selected = "Medium"` etc. on each isa_fields_* select field were
      # inert and Shiny defaulted to first-choice. Closes the second leg of
      # the race-window protection (the first being null-coalesce in
      # validate_and_collect_*). 2026-05-21 fix.
      column(field$width, selectInput(
        input_id, field$label,
        choices  = field$choices,
        selected = if (!is.null(field$selected)) field$selected else field$choices[[1]]
      ))
    } else if (identical(field$type, "select_multi")) {
      column(field$width, selectizeInput(
        input_id, field$label,
        choices  = field$choices,
        selected = if (!is.null(field$selected)) field$selected else character(0),
        multiple = TRUE,
        options  = list(
          plugins = list("remove_button"),
          placeholder = i18n$t("modules.isa.data_entry.common.select_one_or_more")
        )
      ))
    } else {
      column(field$width, textInput(input_id, field$label,
                                     placeholder = if (!is.null(field$placeholder)) field$placeholder else ""))
    }
  }

  row1_cols <- lapply(row1_fields, build_field)
  row2_cols <- lapply(row2_fields, build_field)

  # Calculate remaining width for remove button in row 2
  used_width <- sum(sapply(row2_fields, function(f) f$width))
  remove_width <- max(1, 12 - used_width)

  row2_cols[[length(row2_cols) + 1]] <- column(
    remove_width,
    actionButton(
      ns(paste0(prefix, "_remove_", current_id)),
      i18n$t("common.buttons.remove"),
      class = "btn-danger btn-sm"
    )
  )

  div(
    id = ns(paste0(prefix, "_panel_", current_id)),
    class = "isa-entry-panel",
    style = "background-color: #ffffff !important; border: 1px solid #dee2e6 !important; border-radius: 8px; padding: 20px; margin-bottom: 15px;",
    do.call(fluidRow, row1_cols),
    do.call(fluidRow, row2_cols)
  )
}

#' Register a remove-button observer for an ISA entry panel
#'
#' @param input Shiny input object
#' @param ns Shiny namespace function
#' @param prefix Element prefix
#' @param current_id Entry ID
#' @param i18n Translation object
register_remove_observer <- function(input, ns, prefix, current_id, i18n, isa_data = NULL) {
  # Map UI prefix → (isa_data slot name, ELEMENT_ID_PREFIX value).
  # Used to drop the matching row from the reactive table data when the
  # user clicks Remove, so the table view updates immediately rather than
  # waiting for the next Save (2026-05-20 user-reported UX bug).
  prefix_map <- list(
    gb  = list(slot = "goods_benefits",     id_prefix = "GB"),
    es  = list(slot = "ecosystem_services", id_prefix = "ES"),
    mpf = list(slot = "marine_processes",   id_prefix = "MPF"),
    p   = list(slot = "pressures",          id_prefix = "P"),
    a   = list(slot = "activities",         id_prefix = "A"),
    d   = list(slot = "drivers",            id_prefix = "D")
  )

  observeEvent(input[[paste0(prefix, "_remove_", current_id)]], {
    # Drop the matching row from the reactive table data (if isa_data is
    # provided and prefix is recognized). The row ID is derived from
    # generate_element_id so it matches whatever validate_and_collect_*
    # wrote on the most recent Save.
    if (!is.null(isa_data) && !is.null(prefix_map[[prefix]])) {
      meta <- prefix_map[[prefix]]
      row_id <- generate_element_id(meta$id_prefix, current_id)
      current_df <- isa_data[[meta$slot]]
      if (is.data.frame(current_df) && nrow(current_df) > 0) {
        # Some loaders lowercase column names (load_isa_elements_from_saved
        # at line ~251); accept either casing for the ID column.
        id_col <- if ("ID" %in% names(current_df)) "ID"
                  else if ("id" %in% names(current_df)) "id"
                  else NULL
        if (!is.null(id_col)) {
          isa_data[[meta$slot]] <- current_df[current_df[[id_col]] != row_id, , drop = FALSE]
        }
      }
    }

    removeUI(selector = paste0("#", ns(paste0(prefix, "_panel_", current_id))))
    showNotification(i18n$t("modules.isa.data_entry.common.entry_removed"), type = "message", duration = 2)
  }, ignoreInit = TRUE, once = TRUE)
}

# ============================================================================
# FIELD DEFINITIONS PER ELEMENT TYPE
# ============================================================================

#' Get field definitions for Goods & Benefits entry form
#' @param i18n Translation object
#' @return List of field definitions
isa_fields_gb <- function(i18n) {
  # NOTE: every select-type field MUST declare an explicit `selected` default.
  # Without it, there is a brief race window after insertUI where the
  # server-side input[[gb_<id>_X]] reads NULL before the client reports its
  # initial value. A quick Save click during that window feeds NULLs into
  # validate_and_collect_gb's data.frame construction, throws
  # "arguments imply differing number of rows: 1, 0", and breaks the
  # downstream DT renderDT with a "DataTables ajax error".
  list(
    list(id = "name", type = "text", label = i18n$t("common.labels.name"),
         width = 3, placeholder = i18n$t("modules.isa.data_entry.common.eg_fish_catch")),
    list(id = "type", type = "select", label = i18n$t("common.labels.type"),
         width = 3, choices = c("Provisioning", "Regulating", "Cultural", "Supporting"),
         selected = "Provisioning"),
    list(id = "desc", type = "text", label = i18n$t("common.labels.description"),
         width = 6),
    list(id = "stakeholder", type = "text", label = i18n$t("modules.isa.data_entry.common.stakeholder"),
         width = 3),
    list(id = "importance", type = "select", label = i18n$t("modules.isa.data_entry.common.importance"),
         width = 3, choices = c("High", "Medium", "Low"),
         selected = "Medium"),
    list(id = "trend", type = "select", label = i18n$t("modules.isa.data_entry.common.trend"),
         width = 3, choices = c("Increasing", "Stable", "Decreasing", "Unknown"),
         selected = "Unknown")
  )
}

#' Get field definitions for Ecosystem Services entry form
#' @param i18n Translation object
#' @param linked_choices Character vector of linked GB choices
#' @return List of field definitions
isa_fields_es <- function(i18n, linked_choices) {
  # See isa_fields_gb for the race-window rationale: every select-type field
  # MUST declare an explicit `selected` default so the server never sees
  # NULL between insertUI and the first client-side report.
  list(
    list(id = "name", type = "text", label = i18n$t("common.labels.name"),
         width = 3, placeholder = i18n$t("modules.isa.data_entry.common.eg_fish_production")),
    list(id = "type", type = "select", label = i18n$t("common.labels.es_type"),
         width = 3, choices = c("Provisioning", "Regulating", "Cultural", "Supporting"),
         selected = "Provisioning"),
    list(id = "desc", type = "text", label = i18n$t("common.labels.description"),
         width = 6),
    list(id = "linkedgb", type = "select_multi", label = i18n$t("modules.isa.data_entry.common.linked_to_gb"),
         width = 3, choices = linked_choices,
         selected = character(0)),
    list(id = "mechanism", type = "text", label = i18n$t("modules.isa.data_entry.common.mechanism"),
         width = 3),
    list(id = "confidence", type = "select", label = i18n$t("modules.isa.data_entry.common.confidence"),
         width = 4, choices = c("High", "Medium", "Low"),
         selected = "Medium")
  )
}

#' Get field definitions for Marine Processes entry form
#' @param i18n Translation object
#' @param linked_choices Character vector of linked ES choices
#' @return List of field definitions
isa_fields_mpf <- function(i18n, linked_choices) {
  list(
    list(id = "name", type = "text", label = i18n$t("common.labels.name"),
         width = 3, placeholder = i18n$t("modules.isa.data_entry.common.eg_primary_production")),
    list(id = "type", type = "select", label = i18n$t("common.labels.process_type"),
         width = 3, choices = c("Biological", "Chemical", "Physical", "Ecological"),
         selected = "Biological"),
    list(id = "desc", type = "text", label = i18n$t("common.labels.description"),
         width = 6),
    list(id = "linkedes", type = "select_multi", label = i18n$t("modules.isa.data_entry.common.linked_to_es"),
         width = 3, choices = linked_choices,
         selected = character(0)),
    list(id = "mechanism", type = "text", label = i18n$t("modules.isa.data_entry.common.mechanism"),
         width = 3),
    list(id = "spatial", type = "text", label = i18n$t("modules.isa.data_entry.common.spatial_scale"),
         width = 4)
  )
}

#' Get field definitions for Pressures entry form
#' @param i18n Translation object
#' @param linked_choices Character vector of linked MPF choices
#' @return List of field definitions
isa_fields_p <- function(i18n, linked_choices) {
  list(
    list(id = "name", type = "text", label = i18n$t("common.labels.name"),
         width = 3, placeholder = i18n$t("modules.isa.data_entry.common.eg_nutrient_enrichment")),
    list(id = "type", type = "select", label = i18n$t("common.labels.pressure_type"),
         width = 3, choices = c("Physical", "Chemical", "Biological", "Multiple"),
         selected = "Physical"),
    list(id = "desc", type = "text", label = i18n$t("common.labels.description"),
         width = 6),
    list(id = "linkedmpf", type = "select_multi", label = i18n$t("modules.isa.data_entry.common.linked_to_mpf"),
         width = 3, choices = linked_choices,
         selected = character(0)),
    list(id = "intensity", type = "select", label = i18n$t("modules.isa.data_entry.common.intensity"),
         width = 3, choices = c("High", "Medium", "Low", "Unknown"),
         selected = "Medium"),
    list(id = "spatial", type = "text", label = i18n$t("modules.isa.data_entry.common.spatial"),
         width = 2),
    list(id = "temporal", type = "text", label = i18n$t("modules.isa.data_entry.common.temporal"),
         width = 2)
  )
}

#' Get field definitions for Activities entry form
#' @param i18n Translation object
#' @param linked_choices Character vector of linked Pressure choices
#' @return List of field definitions
isa_fields_a <- function(i18n, linked_choices) {
  list(
    list(id = "name", type = "text", label = i18n$t("common.labels.name"),
         width = 3, placeholder = i18n$t("modules.isa.data_entry.common.eg_commercial_fishing")),
    list(id = "sector", type = "select", label = i18n$t("modules.isa.data_entry.common.sector"),
         width = 3, choices = c("Fisheries", "Aquaculture", "Tourism", "Shipping", "Energy", "Mining", "Other"),
         selected = "Fisheries"),
    list(id = "desc", type = "text", label = i18n$t("common.labels.description"),
         width = 6),
    list(id = "linkedp", type = "select_multi", label = i18n$t("modules.isa.data_entry.common.linked_to_pressure"),
         width = 3, choices = linked_choices,
         selected = character(0)),
    list(id = "scale", type = "select", label = i18n$t("modules.isa.data_entry.common.scale"),
         width = 3, choices = c("Local", "Regional", "National", "International"),
         selected = "Regional"),
    list(id = "frequency", type = "select", label = i18n$t("modules.isa.data_entry.common.frequency"),
         width = 4, choices = c("Continuous", "Seasonal", "Occasional", "One-time"),
         selected = "Continuous")
  )
}

#' Get field definitions for Drivers entry form
#' @param i18n Translation object
#' @param linked_choices Character vector of linked Activity choices
#' @return List of field definitions
isa_fields_d <- function(i18n, linked_choices) {
  list(
    list(id = "name", type = "text", label = i18n$t("common.labels.name"),
         width = 3, placeholder = i18n$t("modules.isa.data_entry.common.eg_economic_growth")),
    list(id = "type", type = "select", label = i18n$t("common.labels.driver_type"),
         width = 3, choices = c("Economic", "Social", "Technological", "Political", "Environmental", "Demographic"),
         selected = "Economic"),
    list(id = "desc", type = "text", label = i18n$t("common.labels.description"),
         width = 6),
    list(id = "linkeda", type = "select_multi", label = i18n$t("modules.isa.data_entry.common.linked_to_activity"),
         width = 3, choices = linked_choices,
         selected = character(0)),
    list(id = "trend", type = "select", label = i18n$t("modules.isa.data_entry.common.trend"),
         width = 3, choices = c("Increasing", "Stable", "Decreasing", "Cyclical", "Uncertain"),
         selected = "Stable"),
    list(id = "control", type = "select", label = i18n$t("modules.isa.data_entry.common.controllability"),
         width = 4, choices = c("High", "Medium", "Low", "None"),
         selected = "Medium")
  )
}

# ============================================================================
# DATA LOADING HELPERS
# ============================================================================

#' Load saved ISA data from a project into module reactive values
#'
#' Transfers element data frames and counters from a saved project structure
#' into the module's reactiveValues, logging each step.
#'
#' @param isa_data Module reactiveValues to populate
#' @param isa_saved Saved ISA data list from project$data$isa_data
#' @return Invisible NULL; modifies isa_data by side effect
load_isa_elements_from_saved <- function(isa_data, isa_saved) {
  # Map of element key -> (counter field, display label)
  element_map <- list(
    drivers            = list(counter = "d_counter",   label = "drivers"),
    activities         = list(counter = "a_counter",   label = "activities"),
    pressures          = list(counter = "p_counter",   label = "pressures"),
    marine_processes   = list(counter = "mpf_counter", label = "marine processes"),
    ecosystem_services = list(counter = "es_counter",  label = "ecosystem services"),
    goods_benefits     = list(counter = "gb_counter",  label = "goods/benefits")
  )

  for (key in names(element_map)) {
    saved_df <- isa_saved[[key]]
    if (is.data.frame(saved_df) && nrow(saved_df) > 0) {
      # Normalize column names to lowercase for consistency
      names(saved_df) <- tolower(names(saved_df))
      debug_log(sprintf("Loading %d %s", nrow(saved_df), element_map[[key]]$label), "ISA Module")
      isa_data[[key]] <- saved_df
      isa_data[[element_map[[key]]$counter]] <- nrow(saved_df)
    }
  }

  # Load adjacency matrices if they exist
  if (!is.null(isa_saved$adjacency_matrices)) {
    debug_log("Loading adjacency matrices", "ISA Module")
    isa_data$adjacency_matrices <- isa_saved$adjacency_matrices

    n_connections <- 0
    for (matrix_name in names(isa_saved$adjacency_matrices)) {
      mat <- isa_saved$adjacency_matrices[[matrix_name]]
      if (!is.null(mat) && is.matrix(mat)) {
        n_connections <- n_connections + sum(mat != "", na.rm = TRUE)
      }
    }
    debug_log(sprintf("Loaded %d connections from adjacency matrices", n_connections), "ISA Module")
  }

  # N:M redesign: user_edited_matrices round-trip.
  if (!is.null(isa_saved$user_edited_matrices)) {
    isa_data$user_edited_matrices <- isa_saved$user_edited_matrices
  } else if (!is.null(isa_data$adjacency_matrices) && length(isa_data$adjacency_matrices) > 0) {
    # Legacy project (no field): initialize as all-FALSE matching adjacency dims.
    isa_data$user_edited_matrices <- lapply(isa_data$adjacency_matrices, function(m) {
      if (is.null(m)) return(NULL)
      matrix(FALSE, nrow = nrow(m), ncol = ncol(m), dimnames = dimnames(m))
    })
  } else {
    isa_data$user_edited_matrices <- list()
  }

  # N:M redesign: one-time hydration for legacy projects. ONLY fires when
  # adjacency_matrices[[mat]] is NULL (matrix never existed). Cleared-but-
  # present matrices are left alone. Each pair wrapped in tryCatch —
  # malformed legacy data soft-fails (debug_log WARN), load completes.
  hydrate_pairs <- list(
    list(mat = "es_gb",  source = "ecosystem_services", target = "goods_benefits",   linked = "linkedgb",  conf = "confidence"),
    list(mat = "mpf_es", source = "marine_processes",  target = "ecosystem_services", linked = "linkedES",  conf = "confidence"),
    list(mat = "p_mpf",  source = "pressures",         target = "marine_processes",   linked = "linkedMPF", conf = NULL),
    list(mat = "a_p",    source = "activities",        target = "pressures",          linked = "linkedp",   conf = NULL),
    list(mat = "d_a",    source = "drivers",           target = "activities",         linked = "linkeda",   conf = NULL)
  )
  for (p in hydrate_pairs) {
    tryCatch({
      src_df <- isa_data[[p$source]]
      tgt_df <- isa_data[[p$target]]
      if (is.null(src_df) || nrow(src_df) == 0 || is.null(tgt_df) || nrow(tgt_df) == 0) next
      # ONLY hydrate when slot is NULL (never existed). Empty-but-present
      # matrices are NOT re-hydrated.
      if (!is.null(isa_data$adjacency_matrices[[p$mat]])) next
      has_linked <- p$linked %in% colnames(src_df) &&
                    any(nzchar(as.character(src_df[[p$linked]])), na.rm = TRUE)
      if (!has_linked) next

      rebuilt <- rebuild_matrix_from_linked(
        element_df = src_df, linked_col = p$linked,
        source_ids = src_df$ID, target_ids = tgt_df$ID,
        element_confidence_col = if (is.null(p$conf)) "Confidence" else p$conf,
        existing_matrix    = isa_data$adjacency_matrices[[p$mat]],
        user_edited_matrix = isa_data$user_edited_matrices[[p$mat]]
      )
      isa_data$adjacency_matrices[[p$mat]] <- rebuilt$matrix
      isa_data$user_edited_matrices[[p$mat]] <- rebuilt$user_edited
    }, error = function(e) {
      if (exists("debug_log", mode = "function")) {
        debug_log(sprintf("load: auto-hydration failed for %s: %s",
                          p$mat, e$message), "WARN")
      }
    })
  }

  invisible(NULL)
}

# ============================================================================
# ENTRY COLLECTION HELPERS
# ============================================================================

#' Collect entries from dynamic form inputs for a given element type
#'
#' Reads all dynamically-created inputs for a given prefix/counter and
#' builds a data.frame. Skips removed entries (NULL name) and empty names.
#'
#' @param input Shiny input object
#' @param prefix Element prefix (e.g. "gb", "es", "mpf", "p", "a", "d")
#' @param counter Number of entries created (max ID)
#' @param id_prefix Element ID prefix from ELEMENT_ID_PREFIX (e.g. "GB", "ES")
#' @param field_ids Character vector of field ID suffixes to collect (e.g. c("name", "type", "desc"))
#' @param col_names Character vector of column names for the resulting data.frame (same order as field_ids)
#' @return A data.frame with an ID column plus columns for each field, or an empty data.frame
collect_element_entries <- function(input, prefix, counter, id_prefix, field_ids, col_names) {
  if (counter == 0) return(data.frame())

  rows <- list()
  for (i in seq_len(counter)) {
    name_val <- input[[paste0(prefix, "_name_", i)]]

    # Skip removed entries (NULL) and blank names
    if (is.null(name_val) || name_val == "") next

    # Collect all field values
    vals <- list()
    vals[["ID"]] <- generate_element_id(id_prefix, i)
    for (j in seq_along(field_ids)) {
      raw <- input[[paste0(prefix, "_", field_ids[j], "_", i)]]
      vals[[col_names[j]]] <- if (!is.null(raw)) raw else ""
    }
    rows[[length(rows) + 1]] <- as.data.frame(vals, stringsAsFactors = FALSE)
  }

  if (length(rows) == 0) return(data.frame())
  do.call(rbind, rows)
}

#' Show validation error modal for ISA entry save
#'
#' @param validation_errors Character vector of error messages
#' @param i18n Translation object
show_validation_error_modal <- function(validation_errors, i18n) {
  showModal(modalDialog(
    title = tags$div(icon("exclamation-triangle"), i18n$t("modules.isa.data_entry.common.validation_errors")),
    tags$div(
      tags$p(strong(i18n$t("modules.isa.data_entry.common.please_fix_the_following_issues_before_saving"))),
      tags$ul(
        lapply(validation_errors, function(err) tags$li(err))
      )
    ),
    easyClose = TRUE,
    footer = modalButton(i18n$t("common.buttons.ok"))
  ))
}

#' Validate and collect Goods & Benefits entries with full validation
#'
#' @param input Shiny input object
#' @param counter Number of GB entries created
#' @param session Shiny session (for notifications)
#' @param i18n Translation object
#' @return List with \code{df} (data.frame or NULL on error) and \code{errors} (character vector)
validate_and_collect_gb <- function(input, counter, session, i18n) {
  # Diagnostic snapshot of which Importance/Trend inputs are NULL at call
  # time — produces a single ISA_VALIDATE log line that exposes the
  # selectInput race window if it reoccurs. Gated on MARINESABRES_DEBUG.
  if (exists("debug_log", mode = "function")) {
    null_importance <- sum(vapply(seq_len(counter),
      function(i) is.null(input[[paste0("gb_importance_", i)]]),
      logical(1)))
    null_trend <- sum(vapply(seq_len(counter),
      function(i) is.null(input[[paste0("gb_trend_", i)]]),
      logical(1)))
    debug_log(paste0("validate_and_collect_gb: counter=", counter,
                     " null_importance=", null_importance,
                     " null_trend=", null_trend), "ISA_VALIDATE")
  }

  gb_rows <- list()
  validation_errors <- c()

  for (i in seq_len(counter)) {
    name_val <- input[[paste0("gb_name_", i)]]
    type_val <- input[[paste0("gb_type_", i)]]
    desc_val <- input[[paste0("gb_desc_", i)]]
    stakeholder_val <- input[[paste0("gb_stakeholder_", i)]]
    importance_val <- input[[paste0("gb_importance_", i)]]
    trend_val <- input[[paste0("gb_trend_", i)]]

    if (is.null(name_val)) next
    if (name_val == "") next

    entry_validations <- list(
      validate_text_input(name_val, paste0("G&B ", i, " Name"),
                         required = TRUE, min_length = 2, max_length = 200,
                         session = NULL),
      validate_select_input(type_val, paste0("G&B ", i, " Type"),
                           required = TRUE,
                           valid_choices = c("Provisioning", "Regulating", "Cultural", "Supporting"),
                           session = NULL),
      validate_text_input(desc_val, paste0("G&B ", i, " Description"),
                         required = FALSE, max_length = 500,
                         session = NULL),
      validate_text_input(stakeholder_val, paste0("G&B ", i, " Stakeholder"),
                         required = FALSE, max_length = 200,
                         session = NULL)
    )

    for (v in entry_validations) {
      if (!v$valid) {
        validation_errors <- c(validation_errors, v$message)
      }
    }

    if (all(sapply(entry_validations, function(v) v$valid))) {
      # Null-coalesce Importance/Trend: when the gb_importance_X / gb_trend_X
      # selectInputs have not yet reported back to the server (race between
      # insertUI render and a quick Save click), input[[...]] returns NULL.
      # data.frame() with a NULL column has nrow=0, which collides with
      # nrow=1 from the other args and throws
      # "arguments imply differing number of rows: 1, 0".
      # That uncaught throw is what corrupts the websocket session state
      # and produces the DataTables ajax-error after Save Exercise 1.
      gb_rows[[length(gb_rows) + 1]] <- data.frame(
        ID = generate_element_id(ELEMENT_ID_PREFIX$welfare, i),
        Name = entry_validations[[1]]$value,
        Type = entry_validations[[2]]$value,
        Description = if (!is.null(entry_validations[[3]]$value)) entry_validations[[3]]$value else "",
        Stakeholder = if (!is.null(entry_validations[[4]]$value)) entry_validations[[4]]$value else "",
        Importance = if (!is.null(importance_val)) importance_val else "",
        Trend = if (!is.null(trend_val)) trend_val else "",
        stringsAsFactors = FALSE
      )
    }
  }

  df <- if (length(gb_rows) > 0) do.call(rbind, gb_rows) else data.frame()
  list(df = df, errors = validation_errors, n_rows = length(gb_rows))
}

#' Validate and collect Ecosystem Services entries with full validation
#'
#' @param input Shiny input object
#' @param counter Number of ES entries created
#' @param session Shiny session
#' @param i18n Translation object
#' @return List with \code{df}, \code{errors}, \code{n_rows}
validate_and_collect_es <- function(input, counter, session, i18n) {
  es_rows <- list()
  validation_errors <- c()

  for (i in seq_len(counter)) {
    name_val <- input[[paste0("es_name_", i)]]
    type_val <- input[[paste0("es_type_", i)]]
    desc_val <- input[[paste0("es_desc_", i)]]
    linkedgb_val <- input[[paste0("es_linkedgb_", i)]]
    mechanism_val <- input[[paste0("es_mechanism_", i)]]
    confidence_val <- input[[paste0("es_confidence_", i)]]

    if (is.null(name_val)) next
    if (name_val == "") next

    entry_validations <- list(
      validate_text_input(name_val, paste0("ES ", i, " Name"),
                         required = TRUE, min_length = 2, max_length = 200,
                         session = NULL),
      validate_select_input(type_val, paste0("ES ", i, " Type"),
                           required = TRUE,
                           valid_choices = c("Provisioning", "Regulating", "Cultural", "Supporting"),
                           session = NULL),
      validate_text_input(desc_val, paste0("ES ", i, " Description"),
                         required = FALSE, max_length = 500,
                         session = NULL),
      validate_text_input(mechanism_val, paste0("ES ", i, " Mechanism"),
                         required = FALSE, max_length = 300,
                         session = NULL)
    )

    for (v in entry_validations) {
      if (!v$valid) {
        validation_errors <- c(validation_errors, v$message)
      }
    }

    if (all(sapply(entry_validations, function(v) v$valid))) {
      # Null-coalesce LinkedGB and Confidence: same race-window bug as the
      # 2026-05-20 G&B incident. When the es_linkedgb_X / es_confidence_X
      # selectInputs have not yet reported back, input[[...]] returns NULL.
      # data.frame() with a NULL column has nrow=0, which collides with
      # nrow=1 from the other args and throws "arguments imply differing
      # number of rows: 1, 0". That uncaught throw corrupts the websocket
      # session state and produces the DataTables ajax-error after Save Ex 2a.
      es_rows[[length(es_rows) + 1]] <- data.frame(
        ID = generate_element_id(ELEMENT_ID_PREFIX$impacts, i),
        Name = entry_validations[[1]]$value,
        Type = entry_validations[[2]]$value,
        Description = if (!is.null(entry_validations[[3]]$value)) entry_validations[[3]]$value else "",
        LinkedGB = serialize_linked(linkedgb_val),
        Mechanism = if (!is.null(entry_validations[[4]]$value)) entry_validations[[4]]$value else "",
        Confidence = if (!is.null(confidence_val)) confidence_val else "",
        stringsAsFactors = FALSE
      )
    }
  }

  df <- if (length(es_rows) > 0) do.call(rbind, es_rows) else data.frame()
  list(df = df, errors = validation_errors, n_rows = length(es_rows))
}

#' Validate and collect Marine Processes/Functions entries with full validation
#'
#' @param input Shiny input object
#' @param counter Number of MPF entries created
#' @param session Shiny session
#' @param i18n Translation object
#' @return List with \code{df}, \code{errors}, \code{n_rows}
validate_and_collect_mpf <- function(input, counter, session, i18n) {
  mpf_rows <- list()
  validation_errors <- c()

  for (i in seq_len(counter)) {
    name_val <- input[[paste0("mpf_name_", i)]]
    type_val <- input[[paste0("mpf_type_", i)]]
    desc_val <- input[[paste0("mpf_desc_", i)]]
    linkedes_val <- input[[paste0("mpf_linkedes_", i)]]
    mechanism_val <- input[[paste0("mpf_mechanism_", i)]]
    spatial_val <- input[[paste0("mpf_spatial_", i)]]

    if (is.null(name_val)) next
    if (name_val == "") next

    entry_validations <- list(
      validate_text_input(name_val, paste0("MPF ", i, " Name"),
                         required = TRUE, min_length = 2, max_length = 200,
                         session = NULL),
      validate_select_input(type_val, paste0("MPF ", i, " Type"),
                           required = TRUE,
                           valid_choices = c("Biological", "Chemical", "Physical", "Ecological"),
                           session = NULL),
      validate_text_input(desc_val, paste0("MPF ", i, " Description"),
                         required = FALSE, max_length = 500,
                         session = NULL),
      validate_text_input(mechanism_val, paste0("MPF ", i, " Mechanism"),
                         required = FALSE, max_length = 300,
                         session = NULL),
      validate_text_input(spatial_val, paste0("MPF ", i, " Spatial"),
                         required = FALSE, max_length = 200,
                         session = NULL)
    )

    for (v in entry_validations) {
      if (!v$valid) {
        validation_errors <- c(validation_errors, v$message)
      }
    }

    if (all(sapply(entry_validations, function(v) v$valid))) {
      mpf_rows[[length(mpf_rows) + 1]] <- data.frame(
        ID = generate_element_id(ELEMENT_ID_PREFIX$marine_processes, i),
        Name = entry_validations[[1]]$value,
        Type = entry_validations[[2]]$value,
        Description = if (!is.null(entry_validations[[3]]$value)) entry_validations[[3]]$value else "",
        LinkedES = serialize_linked(linkedes_val),
        Mechanism = if (!is.null(entry_validations[[4]]$value)) entry_validations[[4]]$value else "",
        Spatial = if (!is.null(entry_validations[[5]]$value)) entry_validations[[5]]$value else "",
        stringsAsFactors = FALSE
      )
    }
  }

  df <- if (length(mpf_rows) > 0) do.call(rbind, mpf_rows) else data.frame()
  list(df = df, errors = validation_errors, n_rows = length(mpf_rows))
}

#' Validate and collect Pressures entries with full validation
#'
#' @param input Shiny input object
#' @param counter Number of P entries created
#' @param session Shiny session
#' @param i18n Translation object
#' @return List with \code{df}, \code{errors}, \code{n_rows}
validate_and_collect_p <- function(input, counter, session, i18n) {
  p_rows <- list()
  validation_errors <- c()

  for (i in seq_len(counter)) {
    name_val <- input[[paste0("p_name_", i)]]
    type_val <- input[[paste0("p_type_", i)]]
    desc_val <- input[[paste0("p_desc_", i)]]
    linkedmpf_val <- input[[paste0("p_linkedmpf_", i)]]
    intensity_val <- input[[paste0("p_intensity_", i)]]
    spatial_val <- input[[paste0("p_spatial_", i)]]
    temporal_val <- input[[paste0("p_temporal_", i)]]

    if (is.null(name_val)) next
    if (name_val == "") next

    entry_validations <- list(
      validate_text_input(name_val, paste0("P ", i, " Name"),
                         required = TRUE, min_length = 2, max_length = 200,
                         session = NULL),
      validate_select_input(type_val, paste0("P ", i, " Type"),
                           required = TRUE,
                           valid_choices = c("Physical", "Chemical", "Biological", "Multiple"),
                           session = NULL),
      validate_text_input(desc_val, paste0("P ", i, " Description"),
                         required = FALSE, max_length = 500,
                         session = NULL),
      validate_text_input(spatial_val, paste0("P ", i, " Spatial"),
                         required = FALSE, max_length = 200,
                         session = NULL),
      validate_text_input(temporal_val, paste0("P ", i, " Temporal"),
                         required = FALSE, max_length = 200,
                         session = NULL)
    )

    for (v in entry_validations) {
      if (!v$valid) {
        validation_errors <- c(validation_errors, v$message)
      }
    }

    if (all(sapply(entry_validations, function(v) v$valid))) {
      p_rows[[length(p_rows) + 1]] <- data.frame(
        ID = generate_element_id(ELEMENT_ID_PREFIX$pressures, i),
        Name = entry_validations[[1]]$value,
        Type = entry_validations[[2]]$value,
        Description = if (!is.null(entry_validations[[3]]$value)) entry_validations[[3]]$value else "",
        LinkedMPF = serialize_linked(linkedmpf_val),
        Intensity = if (!is.null(intensity_val)) intensity_val else "",
        Spatial = if (!is.null(entry_validations[[4]]$value)) entry_validations[[4]]$value else "",
        Temporal = if (!is.null(entry_validations[[5]]$value)) entry_validations[[5]]$value else "",
        stringsAsFactors = FALSE
      )
    }
  }

  df <- if (length(p_rows) > 0) do.call(rbind, p_rows) else data.frame()
  list(df = df, errors = validation_errors, n_rows = length(p_rows))
}

#' Validate and collect Activities entries with full validation
#'
#' @param input Shiny input object
#' @param counter Number of A entries created
#' @param session Shiny session
#' @param i18n Translation object
#' @return List with \code{df}, \code{errors}, \code{n_rows}
validate_and_collect_a <- function(input, counter, session, i18n) {
  a_rows <- list()
  validation_errors <- c()

  for (i in seq_len(counter)) {
    name_val <- input[[paste0("a_name_", i)]]
    sector_val <- input[[paste0("a_sector_", i)]]
    desc_val <- input[[paste0("a_desc_", i)]]
    linkedp_val <- input[[paste0("a_linkedp_", i)]]
    scale_val <- input[[paste0("a_scale_", i)]]
    frequency_val <- input[[paste0("a_frequency_", i)]]

    if (is.null(name_val)) next
    if (name_val == "") next

    entry_validations <- list(
      validate_text_input(name_val, paste0("A ", i, " Name"),
                         required = TRUE, min_length = 2, max_length = 200,
                         session = NULL),
      validate_select_input(sector_val, paste0("A ", i, " Sector"),
                           required = TRUE,
                           valid_choices = c("Fisheries", "Aquaculture", "Tourism", "Shipping", "Energy", "Mining", "Other"),
                           session = NULL),
      validate_text_input(desc_val, paste0("A ", i, " Description"),
                         required = FALSE, max_length = 500,
                         session = NULL)
    )

    for (v in entry_validations) {
      if (!v$valid) {
        validation_errors <- c(validation_errors, v$message)
      }
    }

    if (all(sapply(entry_validations, function(v) v$valid))) {
      a_rows[[length(a_rows) + 1]] <- data.frame(
        ID = generate_element_id(ELEMENT_ID_PREFIX$activities, i),
        Name = entry_validations[[1]]$value,
        Sector = entry_validations[[2]]$value,
        Description = if (!is.null(entry_validations[[3]]$value)) entry_validations[[3]]$value else "",
        LinkedP = serialize_linked(linkedp_val),
        Scale = if (!is.null(scale_val)) scale_val else "",
        Frequency = if (!is.null(frequency_val)) frequency_val else "",
        stringsAsFactors = FALSE
      )
    }
  }

  df <- if (length(a_rows) > 0) do.call(rbind, a_rows) else data.frame()
  list(df = df, errors = validation_errors, n_rows = length(a_rows))
}

#' Validate and collect Drivers entries with full validation
#'
#' @param input Shiny input object
#' @param counter Number of D entries created
#' @param session Shiny session
#' @param i18n Translation object
#' @return List with \code{df}, \code{errors}, \code{n_rows}
validate_and_collect_d <- function(input, counter, session, i18n) {
  d_rows <- list()
  validation_errors <- c()

  for (i in seq_len(counter)) {
    name_val <- input[[paste0("d_name_", i)]]
    type_val <- input[[paste0("d_type_", i)]]
    desc_val <- input[[paste0("d_desc_", i)]]
    linkeda_val <- input[[paste0("d_linkeda_", i)]]
    trend_val <- input[[paste0("d_trend_", i)]]
    control_val <- input[[paste0("d_control_", i)]]

    if (is.null(name_val)) next
    if (name_val == "") next

    entry_validations <- list(
      validate_text_input(name_val, paste0("D ", i, " Name"),
                         required = TRUE, min_length = 2, max_length = 200,
                         session = NULL),
      validate_select_input(type_val, paste0("D ", i, " Type"),
                           required = TRUE,
                           valid_choices = c("Economic", "Social", "Technological", "Political", "Environmental", "Demographic"),
                           session = NULL),
      validate_text_input(desc_val, paste0("D ", i, " Description"),
                         required = FALSE, max_length = 500,
                         session = NULL)
    )

    for (v in entry_validations) {
      if (!v$valid) {
        validation_errors <- c(validation_errors, v$message)
      }
    }

    if (all(sapply(entry_validations, function(v) v$valid))) {
      d_rows[[length(d_rows) + 1]] <- data.frame(
        ID = generate_element_id(ELEMENT_ID_PREFIX$drivers, i),
        Name = entry_validations[[1]]$value,
        Type = entry_validations[[2]]$value,
        Description = if (!is.null(entry_validations[[3]]$value)) entry_validations[[3]]$value else "",
        LinkedA = serialize_linked(linkeda_val),
        Trend = if (!is.null(trend_val)) trend_val else "",
        Control = if (!is.null(control_val)) control_val else "",
        stringsAsFactors = FALSE
      )
    }
  }

  df <- if (length(d_rows) > 0) do.call(rbind, d_rows) else data.frame()
  list(df = df, errors = validation_errors, n_rows = length(d_rows))
}
