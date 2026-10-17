# tests/testthat/test-wp5-governance.R
# WS-9a (spec 2026-10-17 §4-§5): stakeholder schema and governance helpers.
library(testthat)
source_for_test(c("functions/stakeholder_schema.R", "functions/wp5_governance.R"))

gp <- load_wp5_governance_profiles(force_reload = TRUE)
tus <- wp5_gov_profile_for_site(gp, "Tuscan Archipelago")
arc <- wp5_gov_profile_for_site(gp, "Arctic Northeast Atlantic")
i18n_echo <- make_test_i18n()

test_that("constants match the data", {
  expect_equal(WP5_GOV_DIMENSIONS, unlist(gp$dimensions))
  expect_equal(PIMS_STAKEHOLDER_COLUMNS[13:14], c("NERoles", "SourceId"))
  expect_equal(WP5_GOVERNANCE_MIN_APP_VERSION, "1.30.0")
})

test_that("normalize_stakeholders: NULL, legacy 12-column frame, list rows, bad roles (review focus 4)", {
  expect_equal(names(normalize_stakeholders(NULL)), PIMS_STAKEHOLDER_COLUMNS)
  expect_equal(nrow(normalize_stakeholders(NULL)), 0L)
  legacy <- data.frame(ID = "SH001", Name = "Fishers", Type = "x", Sector = "", Contact = "", Interests = "",
                       Role = "", Power = "HIGH", Interest = "", Attitude = "", EngagementLevel = "",
                       DateAdded = "2026-01-01", stringsAsFactors = FALSE)
  out <- normalize_stakeholders(legacy)
  expect_equal(names(out), PIMS_STAKEHOLDER_COLUMNS)
  expect_equal(c(out$NERoles, out$SourceId, out$Power), c("", "", "HIGH"))
  rows <- list(list(ID = "SH002", Name = "Park", NERoles = "Regulators;bogus;Inputters"))
  expect_equal(normalize_stakeholders(rows)$NERoles, "Inputters;Regulators")
  expect_equal(nrow(rbind(out, normalize_stakeholders(rows))), 2L)
})

test_that("stakeholders_use_governance_fields and the display view", {
  sh <- normalize_stakeholders(list(list(ID = "SH001", Name = "A", NERoles = "Regulators", SourceId = "d54:x")))
  expect_true(stakeholders_use_governance_fields(sh))
  expect_false(stakeholders_use_governance_fields(normalize_stakeholders(NULL)))
  v <- stakeholders_display_view(sh, i18n_echo)
  expect_false("SourceId" %in% names(v))
  expect_equal(v$NERoles, "modules.wp5_governance.role.regulators")
})

test_that("profile lookup and card filters (sub-area keeps DA-wide cards)", {
  expect_null(wp5_gov_profile_for_site(gp, ""))
  expect_null(wp5_gov_profile_for_site(gp, "Nowhere"))
  expect_null(wp5_gov_profile_for_site(NULL, "Tuscan Archipelago"))
  all_cards <- wp5_gov_filter_cards(tus)
  expect_equal(length(all_cards), length(tus$cards))
  b <- wp5_gov_filter_cards(tus, polarity = "barrier")
  expect_true(length(b) > 0 && all(vapply(b, `[[`, "", "polarity") == "barrier"))
  k <- wp5_gov_filter_cards(tus, dimension = "knowledge")
  expect_true(all(vapply(k, `[[`, "", "dimension") == "knowledge"))
  ic <- wp5_gov_filter_cards(arc, sub_area = "iceland")
  expect_true(all(vapply(ic, function(cd) is.null(cd$sub_area) || identical(cd$sub_area, "iceland"), logical(1))))
})

test_that("seed_da_actors: all actors once; second run adds nothing (review focus 2)", {
  r1 <- seed_da_actors(NULL, tus, NULL, i18n_echo, counter = 0)
  expect_equal(r1$added, length(tus$actors))
  expect_equal(nrow(r1$stakeholders), length(tus$actors))
  expect_equal(r1$stakeholders$ID[1], "SH001")
  expect_true(all(startsWith(r1$stakeholders$SourceId, "d54:tus_")))
  expect_true(all(r1$stakeholders$NERoles != ""))
  expect_true(any(r1$stakeholders$Power == "HIGH"))
  r2 <- seed_da_actors(r1$stakeholders, tus, NULL, i18n_echo, counter = r1$counter)
  expect_equal(r2$added, 0L)
  expect_equal(r2$skipped, length(tus$actors))
  expect_equal(nrow(r2$stakeholders), nrow(r1$stakeholders))
})

test_that("seed_da_actors skips a hand-typed actor with the same name (case/space-insensitive)", {
  a1 <- tus$actors[[1]]
  manual <- normalize_stakeholders(list(list(ID = "SH001", Name = paste0("  ", toupper(a1$name), " "))))
  r <- seed_da_actors(manual, tus, NULL, i18n_echo, counter = 1)
  expect_equal(r$skipped, 1L)
  expect_equal(nrow(r$stakeholders), length(tus$actors))
  expect_equal(r$stakeholders$ID[2], "SH002")
})

test_that("seed_da_actors sub-area filter; an empty selection adds DA-wide actors only (review focus 3)", {
  ice <- seed_da_actors(NULL, arc, "iceland", i18n_echo, 0)$stakeholders
  src <- sub("^d54:", "", ice$SourceId)
  subs <- vapply(arc$actors, function(a) a$sub_area %||% "", "")[match(src, vapply(arc$actors, `[[`, "", "id"))]
  expect_true(all(subs %in% c("", "iceland")))
  expect_true(any(subs == "iceland") && any(subs == ""))
  none <- seed_da_actors(NULL, arc, character(0), i18n_echo, 0)$stakeholders
  expect_true(nrow(none) > 0)
  expect_true(all(vapply(arc$actors, function(a) a$sub_area %||% "", "")[
    match(sub("^d54:", "", none$SourceId), vapply(arc$actors, `[[`, "", "id"))] == ""))
  expect_true(all(none$Power == "" & none$Interest == ""))      # Arctic: no published grid
})

test_that("recommendation -> register fields; implementing stakeholders linked only after seeding", {
  rec <- tus$recommendations[[1]]
  f <- wp5_gov_recommendation_measure(rec, NULL)
  expect_equal(f$Name, rec$title)
  expect_equal(c(f$Kind, f$Status, f$EbmCode, f$Type, f$Target), c("instrument", "proposed", rec$ebm_code, rec$rm_type, ""))
  expect_match(f$Description, "D5.4 recommendation", fixed = TRUE)
  expect_equal(f$ImplementingStakeholders, "")
  seeded <- seed_da_actors(NULL, tus, NULL, i18n_echo, 0)$stakeholders
  f2 <- wp5_gov_recommendation_measure(rec, seeded)
  want <- seeded$ID[seeded$SourceId %in% paste0("d54:", unlist(rec$implementing_actor_ids))]
  expect_equal(f2$ImplementingStakeholders, paste(want, collapse = ";"))
  reg <- normalize_response_measures(as.data.frame(c(list(ID = "RM001"), f2), stringsAsFactors = FALSE))
  expect_true(wp5_gov_in_register(reg, rec$title))
  expect_false(wp5_gov_in_register(reg, "something else"))
  expect_false(wp5_gov_in_register(NULL, rec$title))
})

test_that("a missing or corrupt profiles file gives NULL", {
  expect_null(load_wp5_governance_profiles(path = tempfile(fileext = ".json")))
  bad <- tempfile(fileext = ".json"); writeLines("{ nope", bad)
  expect_null(load_wp5_governance_profiles(path = bad))
  expect_false(is.null(load_wp5_governance_profiles()))       # default-path cache untouched
})

test_that("empty project and JSON load carry the new stakeholder columns", {
  expect_equal(names(create_empty_project("t")$data$pims$stakeholders), PIMS_STAKEHOLDER_COLUMNS)
  pd <- list(data = list(pims = list(stakeholders = list(list(ID = "SH001", Name = "A", NERoles = "Regulators")))))
  out <- normalize_json_project_data(pd)
  expect_equal(names(out$data$pims$stakeholders), PIMS_STAKEHOLDER_COLUMNS)
  expect_equal(out$data$pims$stakeholders$NERoles, "Regulators")
})
