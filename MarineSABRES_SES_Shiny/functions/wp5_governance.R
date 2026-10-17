# functions/wp5_governance.R
# =============================================================================
# WP5 WS-9a: D5.4 governance profiles (spec 2026-10-17). Loader and pure
# helpers for actor seeding (PIMS) and the governance-context tab (Response).
# data/wp5_governance_profiles.json is curated and verified against D5.4 by
# scripts/tests/test_wp5_governance_profiles.py; do not edit it casually.
# =============================================================================

.wp5_gov_env <- new.env(parent = emptyenv())

#' D5.4 governance profiles, or NULL. Only default-path loads are cached.
load_wp5_governance_profiles <- function(path = NULL, force_reload = FALSE) {
  default <- is.null(path)
  if (default && !force_reload && !is.null(.wp5_gov_env$profiles)) return(.wp5_gov_env$profiles)
  if (default) {
    path <- if (exists("get_project_file", mode = "function")) get_project_file("data", "wp5_governance_profiles.json")
            else file.path("data", "wp5_governance_profiles.json")
  }
  db <- if (file.exists(path)) {
    tryCatch(jsonlite::fromJSON(path, simplifyVector = FALSE), error = function(e) NULL)
  } else NULL
  if (is.null(db) && exists("debug_log", mode = "function")) {
    debug_log(sprintf("WP5 governance: could not load %s", path), "WP5")
  }
  if (default) .wp5_gov_env$profiles <- db
  db
}

#' The profile whose da_site equals the project's DA, or NULL
wp5_gov_profile_for_site <- function(profiles, da_site) {
  if (is.null(profiles) || is.null(da_site) || length(da_site) != 1 || !nzchar(da_site)) return(NULL)
  hit <- Filter(function(p) identical(p$da_site, da_site), profiles$das)
  if (length(hit)) hit[[1]] else NULL
}

#' Cards of a profile filtered by dimension / polarity / sub-area ("" = all).
#' The sub-area filter keeps cards that have no sub-area (DA-wide findings).
wp5_gov_filter_cards <- function(profile, dimension = "", polarity = "", sub_area = "") {
  cards <- profile$cards %||% list()
  keep <- vapply(cards, function(cd) {
    (!nzchar(dimension) || identical(cd$dimension, dimension)) &&
      (!nzchar(polarity) || identical(cd$polarity, polarity)) &&
      (!nzchar(sub_area) || is.null(cd$sub_area) || identical(cd$sub_area, sub_area))
  }, logical(1))
  cards[keep]
}

.wp5_name_key <- function(x) gsub("\\s+", " ", trimws(tolower(as.character(x))))

#' Add a profile's actors to a stakeholder register (pure, idempotent).
#' @param sub_areas NULL = no filter; a character vector (possibly empty) keeps
#'   actors in those sub-areas plus actors without a sub-area
#' @param counter the register's current stakeholder counter
#' @return list(stakeholders, added, skipped, counter)
seed_da_actors <- function(stakeholders, profile, sub_areas = NULL, i18n, counter) {
  sh <- normalize_stakeholders(stakeholders)
  actors <- profile$actors %||% list()
  if (!is.null(sub_areas)) {
    actors <- Filter(function(a) is.null(a$sub_area) || a$sub_area %in% sub_areas, actors)
  }
  added <- 0L; skipped <- 0L; rows <- list()
  # i18n-ref: modules.response.governance.level.local
  # i18n-ref: modules.response.governance.level.island
  # i18n-ref: modules.response.governance.level.regional
  # i18n-ref: modules.response.governance.level.national
  # i18n-ref: modules.response.governance.level.eu
  # i18n-ref: modules.response.governance.level.regional_sea
  # i18n-ref: modules.response.governance.level.international
  for (a in actors) {
    sid <- paste0("d54:", a$id)
    known <- .wp5_name_key(c(sh$Name, vapply(rows, `[[`, "", "Name")))
    if (sid %in% sh$SourceId || .wp5_name_key(a$name) %in% known) {
      skipped <- skipped + 1L
      next
    }
    counter <- counter + 1
    rows[[length(rows) + 1L]] <- list(
      ID = next_element_id(PIMS_ID_PREFIX$stakeholder, counter),
      Name = a$name,
      Type = as.character(i18n$t(PIMS_STAKEHOLDER_TYPE_KEYS[[a$pims_type]])),
      Role = if (is.null(a$level)) "" else as.character(i18n$t(paste0("modules.response.governance.level.", a$level))),
      Power = a$power %||% "", Interest = a$interest %||% "",
      NERoles = paste(unlist(a$ne_roles), collapse = ";"),
      SourceId = sid, DateAdded = as.character(Sys.Date()))
    added <- added + 1L
  }
  if (length(rows)) sh <- rbind(sh, normalize_stakeholders(rows))
  list(stakeholders = sh, added = added, skipped = skipped, counter = counter)
}

#' Register fields (no ID) for a D5.4 recommendation; implementing stakeholders
#' are the project's stakeholders seeded from the recommendation's actors.
wp5_gov_recommendation_measure <- function(rec, stakeholders = NULL) {
  sh <- normalize_stakeholders(stakeholders)
  want <- paste0("d54:", unlist(rec$implementing_actor_ids))
  list(Name = rec$title,
       Description = paste0(rec$text, " (D5.4 recommendation, ", rec$source_ref, ")"),
       Kind = "instrument", EbmCode = rec$ebm_code %||% "", GovernanceLevel = rec$governance_level %||% "",
       Type = rec$rm_type %||% "", Status = "proposed", Target = "",
       ImplementingStakeholders = encode_ids(sh$ID[sh$SourceId %in% want]),
       DateAdded = as.character(Sys.Date()))
}

#' TRUE when the register already holds a measure with this name
wp5_gov_in_register <- function(register, title) {
  if (!is.data.frame(register) || nrow(register) == 0 || !"Name" %in% names(register)) return(FALSE)
  any(trimws(as.character(register$Name)) == trimws(title))
}
