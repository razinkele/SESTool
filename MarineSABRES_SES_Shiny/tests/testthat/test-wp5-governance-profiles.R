# tests/testthat/test-wp5-governance-profiles.R
# WS-9a (spec 2026-10-17 §3.4): schema of the curated D5.4 profiles.
library(testthat)

gp <- jsonlite::fromJSON(file.path(PROJECT_ROOT, "data", "wp5_governance_profiles.json"), simplifyVector = FALSE)
dims <- NPG_DIMENSIONS
pims_types <- c("resource_users", "industrybusiness", "governmentregulators", "ngocivil_society",
                "scientificacademic", "local_communities", "indigenous_groups", "other")
ebm_types <- EBM_POLICY_INSTRUMENTS$code[EBM_POLICY_INSTRUMENTS$level == "type"]
ids_of <- function(xs) vapply(xs, `[[`, "", "id")

test_that("top level: the five dimensions and one profile per DA site", {
  expect_equal(unlist(gp$dimensions), dims)
  expect_setequal(names(gp$das), c("tuscan_archipelago", "arctic_nea", "macaronesia"))
  expect_setequal(unname(vapply(gp$das, `[[`, "", "da_site")), DA_SITES)
  expect_equal(gp$source$doi, "10.48481/rifs.2026.011")
})

test_that("ids are unique and carry their DA prefix", {
  pre <- c(tuscan_archipelago = "tus_", arctic_nea = "arc_", macaronesia = "mac_")
  all_ids <- character(0)
  for (k in names(gp$das)) {
    d <- gp$das[[k]]
    ids <- c(ids_of(d$actors), ids_of(d$cards), ids_of(d$recommendations))
    expect_true(all(startsWith(ids, pre[[k]])), info = k)
    all_ids <- c(all_ids, ids)
  }
  expect_false(anyDuplicated(all_ids) > 0)
})

test_that("sub-areas per DA", {
  expect_length(gp$das$tuscan_archipelago$sub_areas, 0L)
  expect_equal(unlist(gp$das$arctic_nea$sub_areas), c("greenland", "iceland", "faroe_islands"))
  expect_equal(unlist(gp$das$macaronesia$sub_areas), c("azores", "madeira", "canaries"))
})

test_that("actors: roles, types, levels, grid values and source documents are valid", {
  for (k in names(gp$das)) {
    d <- gp$das[[k]]
    expect_gte(length(d$actors), 5L)
    for (a in d$actors) {
      info <- paste(k, a$id)
      expect_true(nzchar(a$name), info = info)
      expect_gte(length(a$ne_roles), 1L)
      expect_true(all(unlist(a$ne_roles) %in% STAKEHOLDER_TYPES), info = info)
      expect_true(a$pims_type %in% pims_types, info = info)
      expect_true(a$level %in% GOVERNANCE_LEVELS, info = info)
      expect_true(a$source_doc %in% c("d54", "char_tus", "char_mac"), info = info)
      expect_true(is.null(a$sub_area) || a$sub_area %in% unlist(d$sub_areas), info = info)
      for (f in c("power", "interest")) expect_true(is.null(a[[f]]) || a[[f]] %in% c("HIGH", "LOW"), info = info)
      expect_true(nzchar(a$source_ref), info = info)
    }
  }
})

test_that("grids: Tuscany has one, Madeira only in Macaronesia, none in the Arctic", {
  has_grid <- function(a) !is.null(a$power) || !is.null(a$interest)
  expect_true(any(vapply(gp$das$tuscan_archipelago$actors, has_grid, logical(1))))
  mac <- gp$das$macaronesia$actors
  expect_true(any(vapply(mac, has_grid, logical(1))))
  expect_true(all(vapply(Filter(has_grid, mac), function(a) identical(a$sub_area, "madeira"), logical(1))))
  expect_false(any(vapply(gp$das$arctic_nea$actors, has_grid, logical(1))))
  expect_true(isTRUE(gp$das$tuscan_archipelago$grid_available))
  expect_null(gp$das$tuscan_archipelago$grid_note)
  expect_false(isTRUE(gp$das$arctic_nea$grid_available))
  expect_equal(gp$das$arctic_nea$grid_note, "no_published_grid")
  expect_equal(gp$das$macaronesia$grid_note, "grid_madeira_only")
})

test_that("cards: every DA covers every dimension and both polarities, cited to its table", {
  tab <- c(arctic_nea = "D5.4 Table 5", macaronesia = "D5.4 Table 6", tuscan_archipelago = "D5.4 Table 7")
  for (k in names(gp$das)) {
    cards <- gp$das[[k]]$cards
    for (cd in cards) {
      expect_true(cd$dimension %in% dims, info = cd$id)
      expect_true(cd$polarity %in% c("enabler", "barrier"), info = cd$id)
      expect_gte(nchar(cd$text), 15L)
      expect_false(grepl("^\\s*[o•]\\s", cd$text), info = cd$id)       # no bullet glyph
      expect_true(startsWith(cd$source_ref, tab[[k]]), info = cd$id)
      expect_true(is.null(cd$sub_area) || cd$sub_area %in% unlist(gp$das[[k]]$sub_areas), info = cd$id)
    }
    # A table cell may be empty in the source, so require each dimension once and each polarity once
    expect_setequal(unique(vapply(cards, `[[`, "", "dimension")), dims)
    expect_setequal(unique(vapply(cards, `[[`, "", "polarity")), c("enabler", "barrier"))
  }
})

test_that("recommendations: 4 / 6 / 4 with valid codes and resolvable implementing actors", {
  expect_length(gp$das$arctic_nea$recommendations, 4L)
  expect_length(gp$das$macaronesia$recommendations, 6L)
  expect_length(gp$das$tuscan_archipelago$recommendations, 4L)
  for (k in names(gp$das)) {
    actor_ids <- ids_of(gp$das[[k]]$actors)
    for (r in gp$das[[k]]$recommendations) {
      expect_true(r$ebm_code %in% ebm_types && substr(r$ebm_code, 1, 1) %in% c("1", "2", "4"), info = r$id)
      expect_true(r$rm_type %in% names(RM_TYPE_CODES), info = r$id)
      expect_true(r$governance_level %in% GOVERNANCE_LEVELS, info = r$id)
      expect_true(all(unlist(r$target_roles) %in% STAKEHOLDER_TYPES), info = r$id)
      expect_gte(length(r$implementing_actor_ids), 1L)
      expect_true(all(unlist(r$implementing_actor_ids) %in% actor_ids), info = r$id)
      expect_true(nzchar(r$title) && nzchar(r$text) && nzchar(r$source_ref), info = r$id)
    }
  }
})

test_that("legal instruments and gaps are present for every DA", {
  for (k in names(gp$das)) {
    expect_gte(length(gp$das[[k]]$legal_instruments), 3L)
    expect_gte(length(gp$das[[k]]$gaps), 3L)
    for (li in gp$das[[k]]$legal_instruments) expect_true(li$level %in% GOVERNANCE_LEVELS, info = li$name)
  }
})

test_that("country DB: GL and FO, the seven bodies, both directions of membership", {
  db <- jsonlite::fromJSON(file.path(PROJECT_ROOT, "data", "country_governance_db.json"), simplifyVector = FALSE)
  expect_true(all(c("GL", "FO") %in% names(db$countries)))
  bodies <- c("neafc", "ices", "gfcm", "accobams", "pelagos", "medpan", "nordic_council")
  expect_true(all(bodies %in% names(db$regional_conventions)))
  for (b in bodies) {
    rc <- db$regional_conventions[[b]]
    expect_true(nzchar(rc$name) && nzchar(rc$full_name), info = b)
    expect_gte(length(rc$responses), 2L)
    for (cc in unlist(rc$member_codes)) {
      expect_true(cc %in% names(db$countries), info = paste(b, cc))
      expect_true(b %in% unlist(db$countries[[cc]]$regional_conventions), info = paste(b, cc))
    }
  }
  expect_true(all(c("GL", "FO") %in% unlist(db$countries_by_sea$arctic)))
})

test_that("get_countries_for_sea('arctic') now includes Greenland and the Faroe Islands", {
  load_country_governance_db(force_reload = TRUE)
  codes <- vapply(get_countries_for_sea("arctic"), function(r) r$code, character(1))
  expect_true(all(c("GL", "FO", "IS", "NO") %in% codes))
})
