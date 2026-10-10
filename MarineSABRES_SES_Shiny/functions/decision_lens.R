# =============================================================================
# DECISION LENS — QSEM-inspired interpretation helpers
# File: functions/decision_lens.R
# =============================================================================
# Pure, Shiny-free helpers composing existing network analysis functions.
# - classify_factors_micmac(): factor classification (impact-vs-control axis),
#   surfacing the dormant MICMAC analysis.
# - detect_archetypes(): candidate system archetypes (Tragedy of the Commons,
#   Limits to Growth); Fixes-that-Fail / Shifting-the-Burden are not
#   implemented. Results are flagged confidence = "candidate".
# - build_decision_narrative(): deterministic, i18n-keyed node narrative.
# See docs/superpowers/specs/2026-06-21-decision-lens-qsem.md (§0, §5, §6).
#
# DATA MODEL (verified against functions/visnetwork_helpers.R:71-225):
#   nodes$group holds FULL category names ("Drivers","Pressures",
#   "Marine Processes & Functioning",...) and ids are PREFIXED ("D_1","MPF_3").
#   Derive the short code with: sub("_[0-9]+$", "", id) -> D/A/P/MPF/ES/GB/R.
#   There is no "C" (State == MPF) and no "M" (Measures merged into Responses).
# =============================================================================

#' DAPSIWRM short code from a prefixed node id
#'
#' @param id character vector of node ids (e.g. "D_1", "MPF_3")
#' @return character vector of codes (e.g. "D", "MPF"); language-proof
#' @keywords internal
dl_code_from_id <- function(id) {
  sub("_[0-9]+$", "", as.character(id))
}

#' Factor classification via MICMAC (influence vs dependence)
#'
#' Surfaces calculate_micmac_safe() as a display-ready, labelled table. This is
#' the "impact vs control axis": influence (out-reach) vs dependence (in-reach),
#' with a structural quadrant classification. MICMAC is unsigned and discards
#' polarity/strength — the read is structural, not dynamical.
#'
#' @param nodes data.frame with id, label, group (full names)
#' @param edges data.frame with from, to, polarity
#' @return data.frame id,label,group,influence,dependence,quadrant
#'   (0 rows, same columns, when MICMAC is NULL/empty)
#' @export
classify_factors_micmac <- function(nodes, edges) {
  empty <- data.frame(
    id = character(0), label = character(0), group = character(0),
    influence = numeric(0), dependence = numeric(0), quadrant = character(0),
    stringsAsFactors = FALSE
  )

  micmac <- calculate_micmac_safe(nodes, edges)
  if (is.null(micmac) || nrow(micmac) == 0) return(empty)

  idx <- match(micmac$id, nodes$id)
  data.frame(
    id         = micmac$id,
    label      = nodes$label[idx],
    group      = nodes$group[idx],
    influence  = micmac$influence,
    dependence = micmac$dependence,
    quadrant   = micmac$quadrant,
    stringsAsFactors = FALSE
  )
}

# Internal: node ids of a loop row (NodeIDs is comma-joined)
.dl_loop_nodes <- function(node_ids_str) {
  if (is.null(node_ids_str) || is.na(node_ids_str) || !nzchar(node_ids_str)) {
    return(character(0))
  }
  trimws(strsplit(node_ids_str, ",")[[1]])
}

#' Detect candidate system archetypes from framework-valid loops
#'
#' Topology-correct, scientifically validated (2026-06-21; see spec §6/§6.1).
#' DAPSIWRM-valid cycles close via either GB->D (reinforcing "engine") or a
#' Response feedback R->{D,A,P,S} (balancing). This detects the two robust,
#' structurally distinguishable motifs:
#'   - Tragedy of the Commons: a shared State(MPF)/ES resource drawn on by >=2
#'     distinct Activities across >=2 loops -> govern the shared resource.
#'   - Limits to Growth: a Reinforcing engine (contains D/A) coupled to a
#'     Response-mediated Balancing loop -> leverage the Response.
#' Fixes-that-Fail and Shifting-the-Burden are intentionally NOT detected here
#' (the former is not separable from Limits-to-Growth without delay/temporal
#' data, which these CLDs lack; the latter has weak marine-SES support).
#'
#' All detections are candidates (confidence = "candidate") — confirm with
#' stakeholders. Element type is derived from the id prefix (dl_code_from_id).
#'
#' @param loop_info data.frame with LoopID, Type ("Reinforcing"/"Balancing"), NodeIDs
#' @param nodes optional; reserved for future use (types are derived from ids)
#' @return list of archetype records, each a list with archetype_key, loop_ids,
#'   node_ids, shared_node_ids, leverage_node_id, confidence. Empty list if none.
#' @export
detect_archetypes <- function(loop_info, nodes = NULL) {
  out <- list()
  if (is.null(loop_info) || nrow(loop_info) == 0) return(out)

  loop_nodes <- lapply(seq_len(nrow(loop_info)), function(i) .dl_loop_nodes(loop_info$NodeIDs[i]))
  loop_codes <- lapply(loop_nodes, dl_code_from_id)
  types <- as.character(loop_info$Type)

  # --- B. Tragedy of the Commons ----------------------------------------
  # Shared MPF/ES node in >=2 loops whose union has >=2 distinct Activities.
  # The common-pool resource is the shared State/stock, so PREFER MPF over ES,
  # and report each distinct loop-set once (downstream ES/GB reconverge and
  # would otherwise double-flag the same commons dynamic).
  commons_nodes <- sort(unique(unlist(lapply(seq_along(loop_nodes), function(i) {
    loop_nodes[[i]][loop_codes[[i]] %in% c("MPF", "ES")]
  }))))
  cand <- list()
  for (res in commons_nodes) {
    in_loops <- which(vapply(loop_nodes, function(s) res %in% s, logical(1)))
    if (length(in_loops) < 2) next
    activities <- unique(unlist(lapply(in_loops, function(i) {
      loop_nodes[[i]][loop_codes[[i]] == "A"]
    })))
    if (length(activities) < 2) next
    ids <- sort(loop_info$LoopID[in_loops])
    cand[[length(cand) + 1]] <- list(
      res = res, code = dl_code_from_id(res), in_loops = in_loops,
      loopkey = paste(ids, collapse = ",")
    )
  }
  # MPF candidates first, then ES; dedup by identical loop-set.
  if (length(cand) > 0) {
    cand <- cand[order(ifelse(vapply(cand, function(c) c$code, "") == "MPF", 0L, 1L))]
    seen <- character(0)
    for (c in cand) {
      if (c$loopkey %in% seen) next
      seen <- c(seen, c$loopkey)
      out[[length(out) + 1]] <- list(
        archetype_key    = "tragedy_of_the_commons",
        loop_ids         = sort(loop_info$LoopID[c$in_loops]),
        node_ids         = sort(unique(unlist(loop_nodes[c$in_loops]))),
        shared_node_ids  = c$res,
        leverage_node_id = c$res,
        confidence       = "candidate"
      )
    }
  }

  # --- A. Limits to Growth ----------------------------------------------
  # Reinforcing loop (engine; contains D or A) coupled (shares >=1 node) to a
  # Balancing loop that contains a Response (R). Leverage = the Response.
  # One record per leverage Response (review 2026-10-07 N17): in DAPSIWRM CLDs
  # almost every loop shares the core A->P->MPF->ES->GB chain, so one record
  # per (reinforcing x balancing) pair reached tens of thousands. The advice is
  # per Response anyway; the coupled loops are aggregated into that record.
  rein <- which(types == "Reinforcing")
  bal  <- which(types == "Balancing")
  ltg <- list()   # keyed by leverage Response id, in first-seen order
  for (ri in rein) {
    if (!any(loop_codes[[ri]] %in% c("D", "A"))) next
    for (bi in bal) {
      r_in_bal <- loop_nodes[[bi]][loop_codes[[bi]] == "R"]
      if (length(r_in_bal) == 0) next
      shared <- intersect(loop_nodes[[ri]], loop_nodes[[bi]])
      if (length(shared) == 0) next
      lev <- r_in_bal[1]   # the management Response (deterministic: first in loop order)
      cur <- ltg[[lev]]
      ltg[[lev]] <- list(
        loop_ids = c(cur$loop_ids, loop_info$LoopID[ri], loop_info$LoopID[bi]),
        node_ids = c(cur$node_ids, loop_nodes[[ri]], loop_nodes[[bi]]),
        shared   = c(cur$shared, shared)
      )
    }
  }
  for (lev in names(ltg)) {
    out[[length(out) + 1]] <- list(
      archetype_key    = "limits_to_growth",
      loop_ids         = sort(unique(ltg[[lev]]$loop_ids)),
      node_ids         = sort(unique(ltg[[lev]]$node_ids)),
      shared_node_ids  = sort(unique(ltg[[lev]]$shared)),
      leverage_node_id = lev,
      confidence       = "candidate"
    )
  }

  out
}

#' Build a deterministic "why this matters" narrative for one node
#'
#' Fuses the node's MICMAC quadrant role, loop participation, and (when the
#' node is an archetype's leverage node) archetype membership into one HTML block.
#' All text is emitted via i18n keys — deterministic, translatable, reviewable;
#' never ML-generated. Pass `archetypes = list()` to render only the quadrant
#' and loop lines.
#'
#' @param node_id character id (prefixed, e.g. "MPF_1")
#' @param micmac data.frame from classify_factors_micmac
#' @param loop_info data.frame with LoopID, Type, NodeIDs (or NULL)
#' @param archetypes list from detect_archetypes (or list())
#' @param i18n object with $t(key); falls back to identity if absent
#' @return character HTML
#' @export
build_decision_narrative <- function(node_id, micmac, loop_info, archetypes, i18n) {
  K <- "modules.analysis.decision_lens"
  # Keys built with paste0(K, ...) below, listed for the i18n enforcement
  # scan (review 2026-10-07 N46):
  # i18n-ref: modules.analysis.decision_lens.quad_influential
  # i18n-ref: modules.analysis.decision_lens.quad_relay
  # i18n-ref: modules.analysis.decision_lens.quad_dependent
  # i18n-ref: modules.analysis.decision_lens.quad_autonomous
  # i18n-ref: modules.analysis.decision_lens.narrative_in_loops
  # i18n-ref: modules.analysis.decision_lens.narrative_archetype_leverage
  # i18n-ref: modules.analysis.decision_lens.narrative_confirm
  # i18n-ref: modules.analysis.decision_lens.archetype.tragedy_of_the_commons.name
  # i18n-ref: modules.analysis.decision_lens.archetype.tragedy_of_the_commons.leverage
  # i18n-ref: modules.analysis.decision_lens.archetype.limits_to_growth.name
  # i18n-ref: modules.analysis.decision_lens.archetype.limits_to_growth.leverage
  t <- if (!is.null(i18n) && is.function(i18n$t)) i18n$t else function(k, ...) k

  row <- micmac[micmac$id == node_id, , drop = FALSE]
  label <- if (nrow(row) > 0 && !is.na(row$label[1])) row$label[1] else node_id
  # The narrative is rendered through HTML(); labels are user text from
  # imports/shared files (review 2026-10-07 N15).
  label <- htmltools::htmlEscape(label)
  parts <- character(0)

  # 1. Quadrant role (structural language — see spec §7)
  if (nrow(row) > 0) {
    quad_key <- switch(row$quadrant[1],
      "Influential" = paste0(K, ".quad_influential"),
      "Relay"       = paste0(K, ".quad_relay"),
      "Dependent"   = paste0(K, ".quad_dependent"),
      "Autonomous"  = paste0(K, ".quad_autonomous"),
      paste0(K, ".quad_autonomous")
    )
    parts <- c(parts, paste0("<p><strong>", label, "</strong> — ", t(quad_key), "</p>"))
  }

  # 2. Loop participation
  if (!is.null(loop_info) && nrow(loop_info) > 0) {
    in_loops <- vapply(seq_len(nrow(loop_info)),
                       function(i) node_id %in% .dl_loop_nodes(loop_info$NodeIDs[i]),
                       logical(1))
    if (any(in_loops)) {
      n_r <- sum(in_loops & loop_info$Type == "Reinforcing")
      n_b <- sum(in_loops & loop_info$Type == "Balancing")
      fmt <- t(paste0(K, ".narrative_in_loops"))
      # Defensive: real key contains "%d ... %d"; if a translation drops the
      # specifiers (or under a key-echo test stub), fall back to plain append
      # instead of letting sprintf warn/error.
      loop_line <- if (grepl("%d", fmt, fixed = TRUE)) {
        sprintf(fmt, n_r, n_b)
      } else {
        paste0(fmt, " (R: ", n_r, ", B: ", n_b, ")")
      }
      parts <- c(parts, paste0("<p>", loop_line, "</p>"))
    }
  }

  # 3. Archetype leverage (records from detect_archetypes())
  for (a in archetypes) {
    if (!is.null(a$leverage_node_id) && a$leverage_node_id == node_id) {
      parts <- c(parts, paste0(
        "<p>", t(paste0(K, ".narrative_archetype_leverage")),
        " <strong>", t(paste0(K, ".archetype.", a$archetype_key, ".name")), "</strong>: ",
        t(paste0(K, ".archetype.", a$archetype_key, ".leverage")), "</p>"
      ))
    }
  }

  # 4. Always: confirm with stakeholders
  parts <- c(parts, paste0("<p><em>", t(paste0(K, ".narrative_confirm")), "</em></p>"))

  paste(parts, collapse = "\n")
}

#' Format a loop-id list for display, truncating long lists
#'
#' Archetype records can aggregate hundreds of loops (review 2026-10-07 N17);
#' the card shows the first `max_show` ids and a "+N" count for the rest.
#' @param ids loop ids
#' @param max_show how many ids to show
#' @return character(1)
format_loop_ids <- function(ids, max_show = 20L) {
  ids <- sort(unique(ids))
  if (length(ids) <= max_show) return(paste(ids, collapse = ", "))
  paste0(paste(ids[seq_len(max_show)], collapse = ", "), " \u2026 (+", length(ids) - max_show, ")")
}

# =============================================================================
# DISPLAY LABELS (review 2026-10-07 N46)
# =============================================================================
# The factor table, plot legend and group column showed the internal English
# values. These map them to translated labels at display time; the stored
# values (used by the narrative and archetype logic) are unchanged.

.DL_QUADRANT_KEYS <- c(
  Influential = "modules.analysis.decision_lens.quad_name_influential",
  Relay       = "modules.analysis.decision_lens.quad_name_relay",
  Dependent   = "modules.analysis.decision_lens.quad_name_dependent",
  Autonomous  = "modules.analysis.decision_lens.quad_name_autonomous"
)
.DL_GROUP_KEYS <- c(
  "Drivers"                        = "modules.analysis.decision_lens.group_drivers",
  "Activities"                     = "modules.analysis.decision_lens.group_activities",
  "Pressures"                      = "modules.analysis.decision_lens.group_pressures",
  "Marine Processes & Functioning" = "modules.analysis.decision_lens.group_marine_processes",
  "Ecosystem Services"             = "modules.analysis.decision_lens.group_ecosystem_services",
  "Goods & Benefits"               = "modules.analysis.decision_lens.group_goods_benefits",
  "Responses"                      = "modules.analysis.decision_lens.group_responses"
)

.dl_translate_values <- function(x, keys, i18n) {
  out <- as.character(x)
  hit <- !is.na(out) & out %in% names(keys)
  if (any(hit) && !is.null(i18n) && is.function(i18n$t)) {
    out[hit] <- vapply(keys[out[hit]], function(k) as.character(i18n$t(k)), character(1))
  }
  out
}

#' Translated MICMAC quadrant names (Influential / Relay / Dependent / Autonomous)
dl_quadrant_label <- function(q, i18n) .dl_translate_values(q, .DL_QUADRANT_KEYS, i18n)

#' Translated DAPSIWRM category names for the group column
dl_group_label <- function(g, i18n) .dl_translate_values(g, .DL_GROUP_KEYS, i18n)

#' Factor table for display: translated headers and values, id column dropped
#' @param factors data.frame from classify_factors_micmac()
#' @return data.frame with translated column names
dl_display_factors <- function(factors, i18n) {
  t <- function(k) as.character(i18n$t(k))
  df <- data.frame(
    label      = factors$label,
    group      = dl_group_label(factors$group, i18n),
    influence  = round(factors$influence, 3),
    dependence = round(factors$dependence, 3),
    quadrant   = dl_quadrant_label(factors$quadrant, i18n),
    stringsAsFactors = FALSE, check.names = FALSE
  )
  names(df) <- c(t("modules.analysis.decision_lens.col_label"),
                 t("modules.analysis.decision_lens.col_group"),
                 t("modules.analysis.decision_lens.col_influence"),
                 t("modules.analysis.decision_lens.col_dependence"),
                 t("modules.analysis.decision_lens.col_quadrant"))
  df
}
