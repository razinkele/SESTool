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
  # !is.atomic first: a nested list from hand-edited JSON must not reach is.na()
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
new_impact_scenario <- function(code, name, description = "", ambition_rank = 0L, source = "user") {
  if (!.impact_valid_code(code)) .impact_error("invalid_scenario_code")
  if (!source %in% IMPACT_SCENARIO_SOURCES) .impact_error("invalid_scenario_source")
  .impact_fill_scenario(list(code = code, name = name %||% code, description = description,
                             ambition_rank = ambition_rank, source = source))
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
  if (scenario$code %in% impact_scenario_codes(ia)) .impact_error("duplicate_scenario_code")
  if (length(ia$scenarios) >= IMPACT_MAX_SCENARIOS) .impact_error("too_many_scenarios")
  ia$scenarios[[scenario$code]] <- scenario
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
  if (!code %in% impact_scenario_codes(ia)) .impact_error("unknown_scenario")
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
