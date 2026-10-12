# functions/impact_assessment_model.R
# WP5 impact assessment: pure data model (spec 2026-10-11 WS-6; WS-6a).
# Stored at project$data$analysis$impact_assessment. No Shiny code here.
# Errors (class "impact_error", field $code) and problems are codes;
# the module (WS-6b) translates them.
#
# Shape: scenarios and cells are named lists (JSON objects), so a JSON load
# with simplifyVector = TRUE never turns them into data frames:
#   list(schema, da,
#        characterisation = list(focal_issue, spatial_scope, time_horizon, stakeholders),  # step 1
#        baseline_code, scenarios = list(<code> = scenario, ...),                           # step 2
#        scope = list(element_ids, indicator_codes,                                         # step 3
#                     displacement = list(answer, note, displaced_pressure_id)),
#        cells = list(<criterion> = list(<scenario code> = cell, ...), ...),                # step 4
#        uncertainty = list(notes), trade_offs = list(text, auto_draft),                   # steps 5-6
#        recommendations = list(text))                                                      # step 7
# The normaliser is a whitelist: a new stored field must be added to the
# matching .impact_fill_* helper and to normalize_impact_assessment().

.impact_error <- function(code) {
  stop(structure(class = c("impact_error", "error", "condition"),
                 list(message = paste0("impact_assessment: ", code), call = NULL, code = code)))
}

# ---- scalar coercion (shared with the normaliser) ----------------------------
.imp_empty_named <- function() setNames(list(), character(0))
.imp_str <- function(v) {
  if (is.null(v) || length(v) == 0) return("")
  v <- v[[1]]
  # Takes the first element of a vector/list. A nested object that reaches here after the
  # JSON round trip may be flattened to its first leaf; !is.atomic keeps lists out of is.na().
  if (is.null(v) || !is.atomic(v) || length(v) != 1 || is.na(v)) "" else as.character(v)
}
.imp_chr <- function(v) {
  v <- unlist(v, use.names = FALSE)
  if (is.null(v)) return(character(0))
  v <- as.character(v)
  v[!is.na(v) & nzchar(v)]
}
.imp_int <- function(v) {
  i <- suppressWarnings(as.integer(.imp_str(v)))
  if (is.na(i)) 0L else i
}
.imp_named_str <- function(v) {
  if (is.null(v) || length(v) == 0 || is.null(names(v))) return(.imp_empty_named())
  v <- as.list(v)
  nm <- names(v)
  keep <- !is.na(nm) & nzchar(nm)
  out <- lapply(v[keep], .imp_str)
  names(out) <- nm[keep]
  out
}

# ---- constructors ------------------------------------------------------------
.impact_fill_cell <- function(x) {
  x <- if (is.list(x)) x else list()
  list(direction = .imp_str(x[["direction"]]),
       magnitude = .imp_str(x[["magnitude"]]),
       timing = .imp_str(x[["timing"]]),
       confidence = .imp_str(x[["confidence"]]),
       evidence = .imp_chr(x[["evidence"]]),
       uncertainty_driver = .imp_str(x[["uncertainty_driver"]]),
       rationale = .imp_str(x[["rationale"]]),
       subdimension_notes = .imp_named_str(x[["subdimension_notes"]]),
       indicator_roles = .imp_named_str(x[["indicator_roles"]]),   # code -> primary|supporting
       mechanism_ids = .imp_chr(x[["mechanism_ids"]]),
       reference = .imp_named_str(x[["reference"]]))               # set when copied from WP5 reference
}

#' An empty criterion x scenario cell (ordinal rubric, spec WS-6 change 1)
new_impact_cell <- function() .impact_fill_cell(list())

.impact_fill_scenario <- function(x) {
  dims <- .imp_named_str(x[["dimensions"]])
  src <- .imp_str(x[["source"]])
  list(code = .imp_str(x[["code"]]),
       name = .imp_str(x[["name"]]),
       description = .imp_str(x[["description"]]),
       ambition_rank = .imp_int(x[["ambition_rank"]]),      # 0 = unranked
       dimensions = setNames(lapply(IMPACT_SCENARIO_DIMENSIONS, function(d) .imp_str(dims[[d]])),
                             IMPACT_SCENARIO_DIMENSIONS),
       source = if (src %in% IMPACT_SCENARIO_SOURCES) src else "user")
}

.impact_valid_code <- function(code) {
  is.character(code) && length(code) == 1 && !is.na(code) && grepl("^[A-Za-z0-9_]{1,40}$", code)
}

#' A scenario on the assessment's scenario axis (spec WS-6 change 2)
new_impact_scenario <- function(code, name, description = "", ambition_rank = 0L, source = "user",
                                dimensions = NULL) {
  if (!.impact_valid_code(code)) .impact_error("invalid_scenario_code")
  if (!source %in% IMPACT_SCENARIO_SOURCES) .impact_error("invalid_scenario_source")
  .impact_check_dimensions(dimensions)
  .impact_fill_scenario(list(code = code, name = name %||% code, description = description,
                             ambition_rank = ambition_rank, source = source, dimensions = dimensions))
}

# Dimension names must come from IMPACT_SCENARIO_DIMENSIONS (NULL = none given)
.impact_check_dimensions <- function(dimensions) {
  if (is.null(dimensions)) return(invisible(NULL))
  nm <- names(dimensions)
  if (length(dimensions) > 0 && (is.null(nm) || any(is.na(nm) | !nm %in% IMPACT_SCENARIO_DIMENSIONS))) {
    .impact_error("unknown_field")
  }
  invisible(NULL)
}

.impact_fill_section <- function(x, fields) {
  x <- .imp_named_str(x)
  setNames(lapply(fields, function(f) .imp_str(x[[f]])), fields)
}

# Step 3: selected ISA elements / registry indicators + displacement check (A§8.4)
.impact_fill_scope <- function(x) {
  x <- if (is.list(x)) x else list()
  d <- x[["displacement"]]
  if (!is.list(d)) d <- list()
  ans <- .imp_str(d[["answer"]])
  if (!ans %in% IMPACT_DISPLACEMENT_ANSWERS) ans <- ""
  list(element_ids = .imp_chr(x[["element_ids"]]),
       indicator_codes = .imp_chr(x[["indicator_codes"]]),
       displacement = list(answer = ans, note = .imp_str(d[["note"]]),
                           displaced_pressure_id = .imp_str(d[["displaced_pressure_id"]])))
}

#' An empty assessment, optionally for a WP5 DA
new_impact_assessment <- function(da = "") {
  if (!identical(da, "") && !(is.character(da) && length(da) == 1 && da %in% WP5_DA_CONTEXTS)) {
    .impact_error("unknown_da")
  }
  list(schema = IMPACT_SCHEMA_VERSION, da = da,
       characterisation = .impact_fill_section(list(), IMPACT_TEXT_SECTIONS$characterisation),
       baseline_code = "",
       scenarios = .imp_empty_named(),
       scope = .impact_fill_scope(list()),
       cells = .imp_empty_named(),
       uncertainty = .impact_fill_section(list(), IMPACT_TEXT_SECTIONS$uncertainty),
       trade_offs = .impact_fill_section(list(), IMPACT_TEXT_SECTIONS$trade_offs),
       recommendations = .impact_fill_section(list(), IMPACT_TEXT_SECTIONS$recommendations))
}

#' Set free-text fields of a section (characterisation, uncertainty, trade_offs, recommendations)
#' @param values Named list/character of field = text; unknown fields are an error
impact_set_section <- function(ia, section, values) {
  if (!is.character(section) || length(section) != 1 || !section %in% names(IMPACT_TEXT_SECTIONS)) {
    .impact_error("unknown_section")
  }
  values <- .imp_named_str(values)
  if (any(!names(values) %in% IMPACT_TEXT_SECTIONS[[section]])) .impact_error("unknown_field")
  for (f in names(values)) ia[[section]][[f]] <- values[[f]]
  ia
}

#' Step 3 scope: ISA element IDs and registry indicator codes in scope
impact_set_scope_items <- function(ia, element_ids = character(0), indicator_codes = character(0)) {
  ia$scope$element_ids <- .imp_chr(element_ids)
  ia$scope$indicator_codes <- .imp_chr(indicator_codes)
  ia
}

# ---- scenarios ---------------------------------------------------------------
impact_scenario_codes <- function(ia) names(ia$scenarios) %||% character(0)

impact_add_scenario <- function(ia, scenario) {
  scenario <- .impact_fill_scenario(if (is.list(scenario)) scenario else list())
  if (!.impact_valid_code(scenario$code)) .impact_error("invalid_scenario_code")
  if (scenario$code %in% impact_scenario_codes(ia)) .impact_error("duplicate_scenario_code")
  if (length(ia$scenarios) >= IMPACT_MAX_SCENARIOS) .impact_error("too_many_scenarios")
  ia$scenarios[[scenario$code]] <- scenario
  ia
}

#' Edit a scenario in place. The code is immutable; NULL arguments leave a field unchanged.
#' @param dimensions Named list/character of IMPACT_SCENARIO_DIMENSIONS entries to set
impact_update_scenario <- function(ia, code, name = NULL, description = NULL, ambition_rank = NULL,
                                   dimensions = NULL) {
  if (!(is.character(code) && length(code) == 1 && code %in% impact_scenario_codes(ia))) {
    .impact_error("unknown_scenario")
  }
  .impact_check_dimensions(dimensions)
  s <- ia$scenarios[[code]]
  if (!is.null(name)) s$name <- name
  if (!is.null(description)) s$description <- description
  if (!is.null(ambition_rank)) s$ambition_rank <- ambition_rank
  if (!is.null(dimensions)) {
    d <- .imp_named_str(dimensions)
    for (k in names(d)) s$dimensions[[k]] <- d[[k]]
  }
  ia$scenarios[[code]] <- .impact_fill_scenario(s)
  ia
}

impact_remove_scenario <- function(ia, code) {
  if (!code %in% impact_scenario_codes(ia)) return(ia)
  ia$scenarios[[code]] <- NULL
  for (cr in names(ia$cells)) ia$cells[[cr]][[code]] <- NULL
  ia$cells <- ia$cells[lengths(ia$cells) > 0]
  if (identical(ia$baseline_code, code)) ia$baseline_code <- ""
  ia
}

#' IMPACT is the difference against the baseline (D5.2 L609-611)
impact_set_baseline <- function(ia, code) {
  if (!(is.character(code) && length(code) == 1 && code %in% impact_scenario_codes(ia))) {
    .impact_error("unknown_scenario")
  }
  ia$baseline_code <- code
  ia
}

# ---- cells -------------------------------------------------------------------
.impact_criterion <- function(criterion) {
  cr <- wp5_criterion_code(criterion)
  if (length(cr) != 1 || is.na(cr)) .impact_error("unknown_criterion")
  cr
}

impact_get_cell <- function(ia, criterion, scenario_code) {
  cr <- .impact_criterion(criterion)
  ia$cells[[cr]][[scenario_code]] %||% new_impact_cell()
}

impact_set_cell <- function(ia, criterion, scenario_code, cell) {
  cr <- .impact_criterion(criterion)
  if (!scenario_code %in% impact_scenario_codes(ia)) .impact_error("unknown_scenario")
  if (is.null(ia$cells[[cr]])) ia$cells[[cr]] <- .imp_empty_named()
  ia$cells[[cr]][[scenario_code]] <- .impact_fill_cell(cell)
  ia
}

# ---- problems ----------------------------------------------------------------
#' Problem codes for one cell. "invalid_*" and "driver_required" block step
#' advance; "direction_missing"/"confidence_missing" only mark it incomplete.
impact_cell_problems <- function(cell, criterion) {
  cr <- .impact_criterion(criterion)
  cell <- .impact_fill_cell(cell)
  p <- character(0)
  for (f in c("direction", "magnitude", "timing", "confidence", "uncertainty_driver")) {
    v <- cell[[f]]
    if (nzchar(v) && !v %in% WP5_RUBRIC[[f]]) p <- c(p, paste0("invalid_", f))
  }
  if (any(!cell$evidence %in% WP5_RUBRIC$evidence)) p <- c(p, "invalid_evidence")
  if (any(!unlist(cell$indicator_roles) %in% WP5_RUBRIC$indicator_role)) p <- c(p, "invalid_indicator_role")
  allowed_sub <- WP5_CRITERION_SUBDIMENSIONS[[cr]] %||% character(0)
  if (any(!names(cell$subdimension_notes) %in% allowed_sub)) p <- c(p, "invalid_subdimension")
  if (identical(cell$confidence, "low") && !nzchar(cell$uncertainty_driver)) p <- c(p, "driver_required")
  if (!nzchar(cell$direction)) p <- c(p, "direction_missing")
  if (!nzchar(cell$confidence)) p <- c(p, "confidence_missing")
  p
}

impact_problem_blocks <- function(code) {
  startsWith(code, "invalid_") |
    code %in% c("driver_required", "no_scenarios", "too_many_scenarios", "baseline_missing",
                "displacement_note_missing")
}

#' Problems that gate a step of the 7-step flow (D5.2 §1.4)
#' @return data.frame(criterion, scenario, problem); "" where not cell-specific
impact_step_problems <- function(ia, step) {
  mk <- function(problem = character(), criterion = "", scenario = "") {
    data.frame(criterion = rep(criterion, length(problem)), scenario = rep(scenario, length(problem)),
               problem = problem, stringsAsFactors = FALSE)
  }
  codes <- impact_scenario_codes(ia)
  if (step == 2) {
    p <- character(0)
    if (length(codes) == 0) p <- c(p, "no_scenarios")
    if (length(codes) > IMPACT_MAX_SCENARIOS) p <- c(p, "too_many_scenarios")
    if (length(codes) > 0 && !ia$baseline_code %in% codes) p <- c(p, "baseline_missing")
    return(mk(p))
  }
  if (step == 3) {
    d <- ia$scope$displacement
    return(mk(if (identical(d$answer, "yes") && !nzchar(d$note)) "displacement_note_missing" else character(0)))
  }
  if (step == 4) {
    out <- mk()
    for (cr in WP5_CRITERIA$code) for (sc in codes) {
      out <- rbind(out, mk(impact_cell_problems(impact_get_cell(ia, cr, sc), cr), cr, sc))
    }
    return(out)
  }
  mk()
}

impact_can_advance <- function(ia, step) !any(impact_problem_blocks(impact_step_problems(ia, step)$problem))

# ---- displacement / leakage (audit A§8.4) ------------------------------------
#' @param displaced_pressure_id Optional ID of a P element created for the displaced
#'   pressure (spec WS-6 change 5; WS-6b creates the element)
impact_set_displacement <- function(ia, answer, note = "", displaced_pressure_id = "") {
  if (!(is.character(answer) && length(answer) == 1 && answer %in% IMPACT_DISPLACEMENT_ANSWERS)) {
    .impact_error("invalid_displacement_answer")
  }
  ia$scope$displacement <- list(answer = answer, note = .imp_str(note),
                                displaced_pressure_id = .imp_str(displaced_pressure_id))
  ia
}

impact_displacement_flagged <- function(ia) identical(ia$scope$displacement$answer, "yes")

# ---- WP5 reference starters (spec WS-6 change 3) -----------------------------
#' A new assessment pre-filled with the DA's published scenarios and baseline
#' (no cells: reference cells stay read-only until copied)
impact_assessment_from_reference <- function(da) {
  ia <- new_impact_assessment(da)
  for (s in impact_reference_scenarios(da)) {
    ia <- impact_add_scenario(ia, new_impact_scenario(s$code, s$name, ambition_rank = s$ambition_rank,
                                                      source = "wp5_reference"))
  }
  b <- impact_reference_baseline(da)
  if (nzchar(b) && b %in% impact_scenario_codes(ia)) ia$baseline_code <- b
  ia
}

#' Copy a read-only WP5 reference cell into the editable assessment.
#' Table 21 states one confidence per scenario; it is copied only when it is a
#' single level (a published range such as Medium–High leaves the choice to
#' the user). Direction, magnitude and timing stay empty: D5.2 gives text.
impact_copy_reference_cell <- function(ia, criterion, scenario_code, overwrite = FALSE) {
  cr <- .impact_criterion(criterion)
  if (!nzchar(ia$da)) .impact_error("no_da")
  ref <- impact_reference_cell(ia$da, cr, scenario_code)
  if (is.null(ref)) .impact_error("no_reference_cell")
  # A user scenario that merely reuses a reference code must not receive D5.2 text as wp5_source
  own <- ia$scenarios[[scenario_code]]
  if (!is.null(own) && !identical(own$source, "wp5_reference")) .impact_error("scenario_not_reference")
  if (!overwrite && !identical(impact_get_cell(ia, cr, scenario_code), new_impact_cell())) {
    .impact_error("cell_not_empty")
  }
  sc <- Find(function(s) identical(s$code, scenario_code), impact_reference_scenarios(ia$da))
  conf <- sc$confidence_codes %||% character(0)
  cell <- new_impact_cell()
  cell$rationale <- if (nzchar(ref$rating_text)) paste0(ref$rating_text, " — ", ref$text) else ref$text
  cell$confidence <- if (length(conf) == 1) conf else ""
  # P5 snapshot: provenance + reference version, so later corrections are detectable
  cell$reference <- list(da = ia$da, table = ref$table, criterion = cr, scenario = scenario_code,
                         provenance = ref$provenance, ref_version = impact_reference_version())
  impact_set_cell(ia, cr, scenario_code, cell)
}

# ---- linking helpers (spec WS-6 change 4) ------------------------------------
#' All mechanisms of a DA for a scenario, annotated and sorted by WS-2
#' scenario_applicability. Nothing is hidden: D5.2 Table 9 often names only the
#' scenario where a mechanism is strongest, which is not a statement that it is
#' inapplicable elsewhere. applicability is NA where D5.2 says nothing for this
#' scenario (always for Tuscan/Macaronesia and for user-defined scenarios).
#' Order: essential, most_effective, applicable, complementary, not stated, fragmented.
impact_mechanism_options <- function(da, scenario_code) {
  empty <- data.frame(id = character(), name = character(), applicability = character(),
                      applicability_text = character(), stringsAsFactors = FALSE)
  if (identical(da, "")) return(empty)                # new assessment without a DA
  rows <- lapply(get_mechanisms_for_da(da), function(m) {
    v <- m[["derived"]][["scenario_applicability"]][[scenario_code]]
    data.frame(id = m$id, name = m$name,
               applicability = if (is.null(v)) NA_character_ else as.character(v),
               applicability_text = .imp_str(m[["applicability_text"]]), stringsAsFactors = FALSE)
  })
  out <- do.call(rbind, c(list(empty), rows))
  rank <- match(out$applicability, c("essential", "most_effective", "applicable", "complementary"))
  rank[is.na(out$applicability)] <- 5L
  rank[is.na(rank)] <- 6L                          # fragmented (or any unknown code) last
  out <- out[order(rank), , drop = FALSE]
  rownames(out) <- NULL
  out
}

#' Registry indicators with a role for this criterion in this DA (WS-4
#' criterion_roles), primary before supporting
impact_indicator_suggestions <- function(criterion, da) {
  cr <- .impact_criterion(criterion)
  empty <- data.frame(code = character(), name = character(), role = character(), stub = logical(),
                      stringsAsFactors = FALSE)
  entries <- load_indicator_registry()$entries %||% list()
  rows <- lapply(entries, function(e) {
    # Some fiche citations carry only role_text ("role": null), e.g. C_02 EC/EQ: no suggestion
    role <- .imp_str(e[["criterion_roles"]][[cr]][["role"]])
    if (!identical(e$da, da) || !role %in% WP5_RUBRIC$indicator_role) return(NULL)
    data.frame(code = e$code, name = e$name, role = role, stub = isTRUE(e$stub),
               stringsAsFactors = FALSE)
  })
  out <- do.call(rbind, c(list(empty), rows))
  out <- out[order(match(out$role, WP5_RUBRIC$indicator_role)), , drop = FALSE]
  rownames(out) <- NULL
  out
}

# ---- storage (spec WS-6 change 7) --------------------------------------------
get_impact_assessment <- function(project) {
  if (!is.list(project) || !is.list(project$data) || !is.list(project$data$analysis)) return(NULL)
  project$data$analysis[["impact_assessment"]]
}

#' Store the assessment; stamps min_app_version (never lowers). NULL removes it.
#' A malformed (non-NULL) assessment is an error ("malformed_assessment") and the
#' project, including any existing block, is left untouched.
set_impact_assessment <- function(project, ia) {
  if (!is.list(project$data$analysis)) project$data$analysis <- list()
  if (is.null(ia)) {
    project$data$analysis$impact_assessment <- NULL
    return(project)
  }
  norm <- normalize_impact_assessment(ia)
  if (is.null(norm)) .impact_error("malformed_assessment")
  project$data$analysis$impact_assessment <- norm
  stamp_min_app_version(project, WP5_IMPACT_MIN_APP_VERSION)
}

#' Canonical impact-assessment block from any load path, or NULL if malformed.
#' Converts through JSON with simplifyVector = FALSE first, so data frames from
#' a simplifyVector = TRUE load become plain lists. Drops cells whose scenario
#' does not exist and maps criterion aliases (PO -> PI, FI -> FF).
normalize_impact_assessment <- function(x) {
  if (is.null(x)) return(NULL)
  x <- tryCatch(
    jsonlite::fromJSON(jsonlite::toJSON(x, auto_unbox = TRUE, null = "null", na = "null", digits = NA),
                       simplifyVector = FALSE),
    error = function(e) NULL)
  if (!is.list(x) || is.null(names(x))) {
    if (exists("debug_log", mode = "function")) debug_log("impact_assessment block malformed; dropped", "WP5")
    return(NULL)
  }
  # Any field-level surprise drops the block, never the project load
  tryCatch(.impact_normalize_body(x), error = function(e) {
    if (exists("debug_log", mode = "function")) {
      debug_log(paste("impact_assessment block dropped:", conditionMessage(e)), "WP5")
    }
    NULL
  })
}

.impact_normalize_body <- function(x) {
  da <- .imp_str(x[["da"]])
  if (!da %in% c("", WP5_DA_CONTEXTS)) da <- ""

  scenarios <- .imp_empty_named()
  for (s in if (is.list(x[["scenarios"]])) x[["scenarios"]] else list()) {
    if (!is.list(s)) next
    sc <- .impact_fill_scenario(s)
    if (!.impact_valid_code(sc$code) || sc$code %in% names(scenarios)) next
    if (length(scenarios) >= IMPACT_MAX_SCENARIOS) break
    scenarios[[sc$code]] <- sc
  }

  cells <- .imp_empty_named()
  xc <- x[["cells"]]
  if (is.list(xc) && !is.null(names(xc))) {
    for (raw_cr in names(xc)) {
      cr <- wp5_criterion_code(raw_cr)
      row <- xc[[raw_cr]]
      if (is.na(cr)) next
      if (cr %in% names(cells)) {                  # canonical key and its alias both present: first wins
        if (exists("debug_log", mode = "function")) {
          debug_log(paste0("impact_assessment: duplicate criterion '", raw_cr, "' (", cr, ") dropped"), "WP5")
        }
        next
      }
      if (!is.list(row) || is.null(names(row))) next
      kept <- .imp_empty_named()
      allowed_sub <- WP5_CRITERION_SUBDIMENSIONS[[cr]] %||% character(0)
      for (sc in names(row)) if (sc %in% names(scenarios)) {
        cell <- .impact_fill_cell(row[[sc]])
        # positional keys ("2") from partially named lists and other criteria's sub-dimensions
        cell$subdimension_notes <- cell$subdimension_notes[names(cell$subdimension_notes) %in% allowed_sub]
        kept[[sc]] <- cell
      }
      if (length(kept) > 0) cells[[cr]] <- kept
    }
  }

  baseline <- .imp_str(x[["baseline_code"]])
  if (!baseline %in% names(scenarios)) baseline <- ""
  sec <- function(s) .impact_fill_section(if (is.list(x[[s]])) x[[s]] else list(), IMPACT_TEXT_SECTIONS[[s]])

  # Same field order as new_impact_assessment(), so identical() holds after a round trip
  list(schema = IMPACT_SCHEMA_VERSION, da = da,
       characterisation = sec("characterisation"),
       baseline_code = baseline,
       scenarios = scenarios,
       scope = .impact_fill_scope(x[["scope"]]),            # guards non-list scope/displacement
       cells = cells,
       uncertainty = sec("uncertainty"),
       trade_offs = sec("trade_offs"),
       recommendations = sec("recommendations"))
}
