# tests/testthat/test-wp5-workshop.R
# WS-10 (spec 2026-10-18): workshop elicitation — storage, summaries, write-back, import/export.
library(testthat)
source_for_test(c("functions/wp5_readiness.R", "functions/wp5_workshop.R"))

test_that("guiding questions: 11, in EBM_TENETS order, non-empty English text", {
  qs <- load_wp5_tenet_questions(force_reload = TRUE)
  expect_false(is.null(qs))
  expect_equal(vapply(qs$questions, `[[`, "", "tenet"), EBM_TENETS$code)
  expect_true(all(nzchar(vapply(EBM_TENETS$code, function(t) wp5_tenet_question(qs, t), ""))))
  expect_equal(wp5_tenet_question(qs, "not_a_tenet"), "")
  expect_equal(unlist(qs$scale), c("completely_disagree", "disagree", "neutral", "agree", "completely_agree"))
})

test_that("a missing file gives NULL, not an error", {
  expect_null(load_wp5_tenet_questions(path = tempfile(fileext = ".json")))
})

ws_with <- function(...) {                          # a normalised workshop with fields overridden
  normalize_workshop(utils::modifyList(list(id = "W001", title = "T", date = "2026-10-18",
    interventions = c("RM001", "RM002"), poll = list(scale = "pm5", criteria = "importance"), tenets_on = TRUE,
    consent = TRUE), list(...)))
}
row_of <- function(ws, ...) {                       # one participant row with the given answers
  cols <- workshop_answer_columns(ws)
  r <- stats::setNames(as.list(rep("", length(cols))), cols)
  v <- list(...); r[names(v)] <- v
  as.data.frame(r, stringsAsFactors = FALSE, check.names = FALSE)
}

test_that("answer columns: per measure, rank columns then 11 tenet columns", {
  ws <- ws_with(poll = list(scale = "four", criteria = c("feasibility", "importance")))
  cols <- workshop_answer_columns(ws)
  expect_equal(cols[1:2], c("rank__RM001__importance", "rank__RM001__feasibility"))   # WORKSHOP_POLL_CRITERIA order
  expect_equal(cols[3], "tenet__RM001__ecol_effective")
  expect_length(cols, 2 * (2 + 11))
  expect_length(workshop_answer_columns(ws_with(tenets_on = FALSE)), 2)
})

test_that("normalize_workshop: defaults, bad values blanked, unknown columns and bad ids dropped", {
  expect_equal(normalize_workshop(list(id = "W009", poll = "x", applied = "junk"))$poll,
               list(scale = "pm5", criteria = "importance"))                    # malformed shapes do not crash
  ws <- normalize_workshop(list(id = "W001", date = "18/10/2026", interventions = c("RM001", "RM 2", "RM001"),
    poll = list(scale = "bogus", criteria = c("x")),
    respondents = data.frame(RespondentId = "P001", Name = "Ana", rank__RM001__importance = "7",
                             tenet__RM001__ecol_effective = "agree", tenet__RM001__tech_feasible = "maybe",
                             stringsAsFactors = FALSE, check.names = FALSE)))
  expect_equal(ws$date, "")
  expect_equal(ws$interventions, "RM001")
  expect_equal(ws$poll, list(scale = "pm5", criteria = "importance"))
  expect_true(ws$tenets_on)
  expect_false(ws$consent)
  r <- ws$respondents
  expect_false("Name" %in% names(r))
  expect_equal(r$rank__RM001__importance, "")              # 7 is off the -5..5 scale
  expect_equal(r$tenet__RM001__ecol_effective, "agree")
  expect_equal(r$tenet__RM001__tech_feasible, "")
  expect_equal(ws$counter, 1L)
  e <- normalize_workshop(NULL)
  expect_true(is.data.frame(e$respondents)); expect_equal(nrow(e$respondents), 0L)
  expect_equal(e$applied, list())
})

test_that("store: create, duplicate, get/set/remove; ids never reused", {
  st <- normalize_workshops(NULL)
  expect_equal(st$items, list())
  st <- workshop_create(workshop_create(st, title = "A"), title = "B")
  expect_equal(vapply(st$items, `[[`, "", "id"), c("W001", "W002"))
  st <- workshop_remove(st, "W002")
  st <- workshop_create(st)
  expect_equal(vapply(st$items, `[[`, "", "id"), c("W001", "W003"))
  w1 <- workshop_get(st, "W001"); w1$interventions <- "RM009"; w1$title <- "A2"
  st <- workshop_set(st, w1)
  expect_equal(workshop_get(st, "W001")$title, "A2")
  st <- workshop_duplicate(st, "W001")
  d <- workshop_get(st, "W004")
  expect_equal(d$interventions, "RM009")
  expect_equal(nrow(d$respondents), 0L)
  expect_null(workshop_get(st, "W999"))
})

test_that("participants: append P001.., delete never reuses ids", {
  ws <- ws_with()
  ws <- workshop_append(ws, row_of(ws, rank__RM001__importance = "3"), "form")
  ws <- workshop_append(ws, rbind(row_of(ws, rank__RM002__importance = "-5"), row_of(ws, rank__RM001__importance = "0")), "import")
  expect_equal(ws$respondents$RespondentId, c("P001", "P002", "P003"))
  expect_equal(ws$respondents$Source, c("form", "import", "import"))
  ws <- workshop_append(workshop_delete_respondents(ws, "P003"), row_of(ws, rank__RM001__importance = "1"), "form")
  expect_equal(ws$respondents$RespondentId, c("P001", "P002", "P004"))
  expect_equal(nrow(workshop_delete_respondents(ws, ws$respondents$RespondentId)$respondents), 0L)
})

test_that("set-up locks while participants exist; deleting them all unlocks", {
  ws <- ws_with()
  changed <- workshop_update_setup(ws, list(title = "New", interventions = "RM002", tenets_on = FALSE))
  expect_equal(c(changed$title, changed$interventions), c("New", "RM002"))
  ws <- workshop_append(ws, row_of(ws, rank__RM001__importance = "2"), "form")
  locked <- workshop_update_setup(ws, list(title = "New", interventions = "RM002",
                                           poll = list(scale = "four", criteria = "feasibility"), tenets_on = FALSE))
  expect_equal(locked$title, "New")
  expect_equal(locked$interventions, c("RM001", "RM002"))
  expect_equal(locked$poll$scale, "pm5")
  expect_true(locked$tenets_on)
  free <- workshop_update_setup(workshop_delete_respondents(ws, "P001"), list(interventions = "RM002"))
  expect_equal(free$interventions, "RM002")
})

test_that("JSON save/load round trip keeps the workshop (review focus 1)", {
  st <- workshop_create(normalize_workshops(NULL), title = "Arctic")
  ws <- workshop_update_setup(workshop_get(st, "W001"), list(interventions = "RM001"))   # one intervention -> auto-unboxed
  ws <- workshop_append(ws, row_of(ws, rank__RM001__importance = "-2", tenet__RM001__ecol_effective = "agree"), "form")
  st <- workshop_set(st, ws)
  json <- jsonlite::toJSON(list(data = list(pims = list(workshops = st))), pretty = TRUE, auto_unbox = TRUE)
  back <- jsonlite::fromJSON(json, simplifyVector = TRUE)$data$pims$workshops     # server/project_io.R:99 shape
  expect_equal(normalize_workshops(back), normalize_workshops(st))
})

test_that("version mark: any workshop, or a TenetSource left after the workshop is gone (review focus 5)", {
  m <- normalize_response_measures(data.frame(ID = "RM001", Name = "a", stringsAsFactors = FALSE))
  expect_false(workshops_need_version(NULL, m))
  expect_true(workshops_need_version(workshop_create(normalize_workshops(NULL)), m))
  m$TenetSource <- "Workshop W001 (2026-10-18, n = 4)"
  expect_true(workshops_need_version(normalize_workshops(NULL), m))
  expect_true(workshops_need_version(NULL, list(list(ID = "RM001", TenetSource = "x"))))   # JSON row lists
})

test_that("JSON load path normalises workshops and stamps 1.32.0", {
  p <- create_empty_project("t")
  p$data$pims$workshops <- list(items = list(list(id = "W001", interventions = "RM001")))
  out <- normalize_json_project_data(p)
  expect_equal(out$data$pims$workshops$items[[1]]$poll$scale, "pm5")
  expect_equal(out$min_app_version, WP5_WORKSHOP_MIN_APP_VERSION)
  # create_empty_project() carries a base min_app_version (1.12.0), so assert it is not raised to 1.32.0
  expect_false(identical(normalize_json_project_data(create_empty_project("t"))$min_app_version,
                         WP5_WORKSHOP_MIN_APP_VERSION))
})

test_that("JSON round trip keeps apply records with different key sets (no phantom blank keys)", {
  rec <- function(m, before, after) list(measure = m, at = "2026-10-18", before = before, after = after)
  mk <- function(id, recs) {
    w <- normalize_workshop(list(id = id, interventions = c("RM001", "RM002")))
    w$applied <- recs
    w
  }
  r1 <- rec("RM001", list(Tenet_ecol_effective = "", TenetSource = ""),
                     list(Tenet_ecol_effective = "5", TenetSource = "Workshop W001"))
  r2 <- rec("RM002", list(Tenet_tech_feasible = "2", Tenet_communicable = "", TenetSource = "old"),
                     list(Tenet_tech_feasible = "4", Tenet_communicable = "3", TenetSource = "Workshop W002"))
  st <- normalize_workshops(list(counter = 2L, items = list(mk("W001", list(r1, r2)), mk("W002", list(r2)))))
  expect_equal(st$items[[1]]$applied, list(r1, r2))                 # direct normalisation keeps them
  json <- jsonlite::toJSON(list(data = list(pims = list(workshops = st))), pretty = TRUE, auto_unbox = TRUE)
  back <- normalize_workshops(jsonlite::fromJSON(json, simplifyVector = TRUE)$data$pims$workshops)
  for (i in 1:2) for (k in seq_along(st$items[[i]]$applied)) {
    a <- back$items[[i]]$applied[[k]]; o <- st$items[[i]]$applied[[k]]
    srt <- function(x) x[order(names(x))]          # key order is not significant (data.frame union columns)
    expect_equal(sort(names(a$before)), sort(names(o$before)))
    expect_equal(sort(names(a$after)), sort(names(o$after)))
    expect_equal(srt(a$before), srt(o$before))
    expect_equal(srt(a$after), srt(o$after))
  }
  expect_identical(back$items[[1]]$applied[[1]]$before$Tenet_ecol_effective, "")   # blank before survives
})
