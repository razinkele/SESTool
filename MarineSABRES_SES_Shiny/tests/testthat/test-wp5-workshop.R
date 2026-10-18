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

tenet_rows <- function(ws, m, tenet, codes) {        # one participant per code, rating only (m, tenet)
  do.call(rbind, lapply(codes, function(cd) { r <- row_of(ws); r[[workshop_tenet_col(m, tenet)]] <- cd; r }))
}
reg <- function(...) normalize_response_measures(data.frame(ID = c("RM001", "RM002"), Name = c("a", "b"), ...,
                                                           stringsAsFactors = FALSE))

test_that("poll summary: n, median, mean; sorted by the first criterion's median then mean", {
  ws <- ws_with()
  ws <- workshop_append(ws, rbind(row_of(ws, rank__RM001__importance = "1", rank__RM002__importance = "4"),
                                  row_of(ws, rank__RM001__importance = "2", rank__RM002__importance = "-1"),
                                  row_of(ws, rank__RM002__importance = "4")), "form")
  s <- workshop_poll_summary(ws)
  expect_equal(s$measure, c("RM002", "RM001"))
  expect_equal(s$n, c(3L, 2L))
  expect_equal(s$median, c(4, 1.5))
  expect_equal(s$mean, c(7 / 3, 1.5))
  ct <- workshop_poll_counts(ws)
  expect_equal(nrow(ct), 2 * 11)
  expect_equal(ct$n[ct$measure == "RM002" & ct$value == "4"], 2L)
  expect_equal(nrow(workshop_poll_summary(ws_with(interventions = character(0)))), 0L)
})

test_that("tenet summary: even-n median, dont_know excluded from median and n", {
  ws <- ws_with()
  ws <- workshop_append(ws, tenet_rows(ws, "RM001", "ecol_effective",
                                       c("agree", "neutral", "dont_know", "completely_agree", "neutral")), "form")
  s <- workshop_tenet_summary(ws)
  e <- s[s$measure == "RM001" & s$tenet == "ecol_effective", ]
  expect_equal(c(e$n_valid, e$n_dont_know), c(4L, 1L))
  expect_equal(e$median, 3.5)                               # 3, 3, 4, 5
  expect_equal(c(e$p3, e$p4, e$p5), c(2L, 1L, 1L))
  expect_true(is.na(s$median[s$measure == "RM002" & s$tenet == "ecol_effective"]))
  expect_equal(nrow(s), 2 * 11)
  expect_equal(nrow(workshop_tenet_summary(ws_with(tenets_on = FALSE))), 0L)
})

test_that("level mapping at the boundaries (spec §6)", {
  lv <- function(t, m) workshop_tenet_level(t, m)
  expect_equal(vapply(c(2.5, 3, 3.5, 4, 5), function(m) lv("ecol_effective", m), ""),
               c("minimal", "intermediate", "intermediate", "full", "full"))
  expect_equal(vapply(c(2.5, 3, 3.5, 4), function(m) lv("communicable", m), ""),
               c("minimal", "minimal", "minimal", "full"))
  expect_true(is.na(lv("communicable", NA_real_)))
})

test_that("proposal: n < 3 gives none; not-assessed counts as changed (review focus 4); equal is unchanged", {
  ws <- ws_with()
  ws <- workshop_append(ws, rbind(tenet_rows(ws, "RM001", "ecol_effective", c("agree", "agree", "completely_agree")),
                                  tenet_rows(ws, "RM001", "tech_feasible", c("agree", "agree"))), "form")
  p <- workshop_writeback_proposal(ws, reg(Tenet_ecol_effective = c("", "full")))
  e <- p[p$measure == "RM001" & p$tenet == "ecol_effective", ]
  expect_equal(c(e$current, e$proposed), c("", "full"))
  expect_true(e$changed)
  t <- p[p$measure == "RM001" & p$tenet == "tech_feasible", ]
  expect_true(is.na(t$proposed)); expect_false(t$changed)
  expect_equal(nrow(p), 2 * 11)
  same <- workshop_writeback_proposal(ws, reg(Tenet_ecol_effective = c("full", "")))
  expect_false(same$changed[same$measure == "RM001" & same$tenet == "ecol_effective"])
  gone <- workshop_writeback_proposal(ws, reg()[2, , drop = FALSE])
  expect_equal(unique(gone$measure), "RM002")
})

test_that("apply change, record, undo check, and an apply/undo round trip", {
  ws <- ws_with()
  ws <- workshop_append(ws, tenet_rows(ws, "RM001", "ecol_effective", c("agree", "agree", "agree", "agree")), "form")
  m <- reg()
  ch <- workshop_apply_change(ws, "RM001", m, "Workshop {id} ({date}, n = {n})")
  expect_equal(ch$after$Tenet_ecol_effective, "full")
  expect_equal(ch$after$TenetSource, "Workshop W001 (2026-10-18, n = 4)")
  expect_equal(ch$before, list(Tenet_ecol_effective = "", TenetSource = ""))
  expect_null(workshop_apply_change(ws, "RM002", m, "x"))                   # nothing to change
  expect_equal(workshop_source_text(ws_with(date = ""), 3, "{id} {date} {n}", today = as.Date("2026-01-02")),
               "W001 2026-01-02 3")
  ws <- workshop_record_apply(ws, "RM001", ch$before, ch$after, at = "2026-10-18T10:00:00")
  e <- workshop_last_apply(ws, "RM001")
  expect_equal(e$after$Tenet_ecol_effective, "full")
  applied <- m; applied$Tenet_ecol_effective[1] <- "full"; applied$TenetSource[1] <- ch$after$TenetSource
  expect_equal(workshop_undo_check(e, applied), "ok")
  expect_equal(workshop_undo_check(e, m), "changed")
  expect_equal(workshop_undo_check(e, m[2, , drop = FALSE]), "gone")
  restored <- applied
  for (cl in names(e$before)) restored[[cl]][1] <- e$before[[cl]]
  expect_equal(restored, m)                                                  # round trip
  expect_null(workshop_last_apply(workshop_drop_last_apply(ws, "RM001"), "RM001"))
  expect_equal(normalize_workshop(ws)$applied, ws$applied)                   # records survive normalisation
})

fake_tr <- list("modules.wp5_workshop.answer.agree" = list(en = "Agree", es = "De acuerdo"),
                "modules.wp5_workshop.answer.dont_know" = list(en = "Don't know", lt = "Nežinau"))

test_that("import: codes, labels in any language, accents, digits, numeric and typographic-minus ranks (focus 2, 3)", {
  ws <- ws_with(interventions = "RM003")
  df <- data.frame(`RANK__RM003__IMPORTANCE` = c(-5, 3, NA, 7), `tenet__RM003__ecol_effective` = c("de acuerdo", "4", "nezinau", "x"),
                   name = c("Ana", "", "", ""), stringsAsFactors = FALSE, check.names = FALSE)
  p <- workshop_parse_import(df, ws, fake_tr)
  expect_true(p$ok)
  expect_equal(p$rows$rank__RM003__importance, c("-5", "3", ""))   # row 4 (7, "x") becomes blank and is dropped
  expect_equal(p$rows$tenet__RM003__ecol_effective, c("agree", "agree", "dont_know"))
  expect_equal(p$blanked, 2L)                         # 7 off scale, "x" unknown
  expect_equal(p$dropped_empty, 1L)
  expect_equal(p$ignored, "name")
  minus <- workshop_parse_import(data.frame(rank__RM003__importance = "\u22123", stringsAsFactors = FALSE), ws, fake_tr)
  expect_equal(minus$rows$rank__RM003__importance, "-3")
})

test_that("import: refusals and blank rows", {
  ws <- ws_with(interventions = "RM003")
  f <- workshop_parse_import(data.frame(rank__RM009__importance = "1", stringsAsFactors = FALSE), ws, fake_tr)
  expect_false(f$ok); expect_equal(f$error, "foreign_columns"); expect_equal(f$expected, "rank__RM009__importance")
  n <- workshop_parse_import(data.frame(name = "a", stringsAsFactors = FALSE), ws, fake_tr)
  expect_equal(n$error, "no_answer_columns")
  b <- workshop_parse_import(data.frame(rank__RM003__importance = c("", NA), stringsAsFactors = FALSE), ws, fake_tr)
  expect_true(b$ok); expect_equal(nrow(b$rows), 0L); expect_equal(b$dropped_empty, 2L)
})

test_that("template -> import round trip; export sheets", {
  ws <- ws_with(interventions = "RM001")
  i18n <- list(t = function(k, ...) k)
  wb <- workshop_template_wb(ws, reg(), i18n)
  expect_equal(openxlsx::sheets(wb), c("answers", "measures", "scales"))
  row <- stats::setNames(as.list(rep("", length(workshop_answer_columns(ws)))), workshop_answer_columns(ws))
  row$rank__RM001__importance <- "-4"; row$tenet__RM001__ecol_effective <- "completely_agree"
  openxlsx::writeData(wb, "answers", as.data.frame(row, stringsAsFactors = FALSE, check.names = FALSE),
                      startRow = 2, colNames = FALSE)
  f <- tempfile(fileext = ".xlsx"); openxlsx::saveWorkbook(wb, f, overwrite = TRUE)
  p <- workshop_parse_import(readiness_read_file(f, "x.xlsx"), ws, fake_tr)
  expect_equal(c(p$rows$rank__RM001__importance, p$rows$tenet__RM001__ecol_effective), c("-4", "completely_agree"))
  ws <- workshop_append(ws, p$rows, "import")
  ex <- workshop_export_wb(ws, i18n)
  expect_equal(openxlsx::sheets(ex), c("setup", "respondents", "poll_summary", "tenet_summary"))
})

test_that("workshop_pick_selection: wanted wins, else current if valid, else last, else empty", {
  expect_equal(workshop_pick_selection(c("W001", "W002"), "W001", "W002"), "W002")
  expect_equal(workshop_pick_selection(c("W001", "W002"), "W001", NULL), "W001")
  expect_equal(workshop_pick_selection(c("W001", "W002"), "W009", NULL), "W002")
  expect_equal(workshop_pick_selection(c("W001", "W002"), NULL, "W009"), "W002")
  expect_equal(workshop_pick_selection(c("W001", "W002"), "", ""), "W002")
  expect_equal(workshop_pick_selection(character(0), "W001", "W002"), "")
})

test_that("follow-up: duplicate participant ids are renumbered, every row kept", {
  ws <- normalize_workshop(list(id = "W001", interventions = "RM001", counter = 2,
    respondents = data.frame(RespondentId = c("P001", "P002", "P002", ""),
                             rank__RM001__importance = c("1", "2", "3", "4"), stringsAsFactors = FALSE)))
  expect_equal(ws$respondents$RespondentId, c("P001", "P002", "P003", "P004"))   # duplicate and missing id
  expect_equal(ws$respondents$rank__RM001__importance, c("1", "2", "3", "4"))
  expect_equal(ws$counter, 4L)
  expect_equal(normalize_workshop(ws)$respondents$RespondentId, c("P001", "P002", "P003", "P004"))   # stable
})

test_that("follow-up: apply records survive removing the measure from the workshop; undo works after re-adding", {
  ws <- ws_with()
  ws <- workshop_record_apply(ws, "RM002", list(Tenet_ecol_effective = "", TenetSource = ""),
                              list(Tenet_ecol_effective = "full", TenetSource = "x"), at = "t")
  ws2 <- workshop_update_setup(ws, list(interventions = "RM001"))           # no participants -> editable
  expect_length(ws2$applied, 1)
  ws3 <- workshop_update_setup(ws2, list(interventions = c("RM001", "RM002")))
  expect_equal(workshop_last_apply(ws3, "RM002")$after$Tenet_ecol_effective, "full")
  ws_bad <- ws
  ws_bad$applied <- list(list(measure = "RM 9", at = "t", before = list(TenetSource = ""), after = list(TenetSource = "x")))
  expect_length(normalize_workshop(ws_bad)$applied, 0)                      # invalid id still dropped
})

test_that("follow-up: foreign-column refusal names the file's original headers", {
  ws <- ws_with(interventions = "RM003")
  f <- workshop_parse_import(data.frame(`Rank__RM009__Importance` = "1", stringsAsFactors = FALSE, check.names = FALSE), ws, list())
  expect_equal(f$expected, "Rank__RM009__Importance")
})

test_that("follow-up: workbook headers and labels translated; the answers sheet keeps import codes", {
  i18n <- list(t = function(k, ...) k)
  k <- function(x) paste0("modules.wp5_workshop.", x)
  ws <- ws_with(interventions = "RM001")
  ws <- workshop_append(ws, row_of(ws, rank__RM001__importance = "2", tenet__RM001__ecol_effective = "agree"), "form")
  wb <- workshop_template_wb(ws, reg(), i18n)
  expect_equal(names(openxlsx::read.xlsx(wb, "measures")), k(c("xl.id", "xl.name")))
  sc <- openxlsx::read.xlsx(wb, "scales")
  expect_equal(names(sc), k(c("xl.scale", "xl.value", "xl.label")))
  expect_setequal(unique(sc[[1]]), k(c("xl.scale_rank", "xl.scale_tenet")))
  ex <- workshop_export_wb(ws, i18n)
  st <- openxlsx::read.xlsx(ex, "setup")
  expect_equal(names(st), k(c("xl.field", "xl.value")))
  expect_true(all(k(c("workshop", "field_title", "field_scale", "field_tenets_on")) %in% st[[1]]))
  expect_true(k("scale.pm5") %in% st[[2]])
  r <- names(openxlsx::read.xlsx(ex, "respondents"))
  expect_equal(r[1:3], k(c("col_participant", "col_date", "col_source")))
  expect_true("rank__RM001__importance" %in% r)                                # answer codes kept
  ps <- openxlsx::read.xlsx(ex, "poll_summary")
  expect_equal(names(ps), k(c("col_measure", "col_criterion", "col_n", "col_median", "col_mean", "xl.rank")))
  expect_equal(ps[[2]][1], k("criterion.importance"))
  ts <- openxlsx::read.xlsx(ex, "tenet_summary")
  expect_equal(names(ts)[1:5], k(c("col_measure", "col_tenet", "xl.n_valid", "xl.n_dont_know", "col_median")))
  expect_equal(names(ts)[6:10], as.character(1:5))
})

test_that("follow-up: unknown participant Source values are cleared", {
  ws <- normalize_workshop(list(id = "W001", interventions = "RM001",
    respondents = data.frame(RespondentId = c("P001", "P002", "P003"), Source = c("form", "hacked", "import"),
                             stringsAsFactors = FALSE)))
  expect_equal(ws$respondents$Source, c("form", "", "import"))
})
