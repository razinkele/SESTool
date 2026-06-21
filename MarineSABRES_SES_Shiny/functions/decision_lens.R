# =============================================================================
# DECISION LENS — QSEM-inspired interpretation helpers
# File: functions/decision_lens.R
# =============================================================================
# Pure, Shiny-free helpers composing existing network analysis functions.
# Phase 1 (shipping): classify_factors_micmac() — factor classification
#   (impact-vs-control axis), surfacing the dormant MICMAC analysis.
# Archetype detection + fused narrative are DEFERRED pending re-derivation
# against valid DAPSIWRM loop topology + scientific validation.
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

#' Build a deterministic "why this matters" narrative for one node
#'
#' Fuses the node's MICMAC quadrant role, loop participation, and (when the
#' archetype layer ships) archetype leverage membership into one HTML block.
#' All text is emitted via i18n keys — deterministic, translatable, reviewable;
#' never ML-generated. While archetype detection is deferred, callers pass
#' `archetypes = list()` and only the quadrant + loop lines render.
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
  t <- if (!is.null(i18n) && is.function(i18n$t)) i18n$t else function(k, ...) k

  row <- micmac[micmac$id == node_id, , drop = FALSE]
  label <- if (nrow(row) > 0 && !is.na(row$label[1])) row$label[1] else node_id
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

  # 3. Archetype leverage (deferred: archetypes is list() for now)
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
