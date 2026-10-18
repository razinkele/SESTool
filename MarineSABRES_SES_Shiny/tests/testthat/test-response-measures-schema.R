# tests/testthat/test-response-measures-schema.R
# WS-3a: response register schema — codes in data, labels on display, scalar columns.
library(testthat)

test_that("empty register has exactly the schema columns, character except Cost", {
  df <- empty_measures_df()
  expect_equal(names(df), RM_REGISTER_COLUMNS)
  expect_equal(nrow(df), 0L)
  expect_type(df$Cost, "double")
  for (cl in setdiff(RM_REGISTER_COLUMNS, "Cost")) expect_type(df[[cl]], "character")
  expect_true(all(paste0("Tenet_", EBM_TENETS$code) %in% RM_REGISTER_COLUMNS))
})

test_that("reverse map resolves the label in every language to the code", {
  m <- rm_reverse_label_map(force = TRUE)
  tr <- jsonlite::fromJSON(file.path(PROJECT_ROOT, "translations", "modules", "response_measures.json"),
                           simplifyVector = FALSE)$translation
  for (l in c("en","es","fr","de","lt","pt","it","no","el")) {
    expect_equal(unname(m$type[tr[["modules.response.measures.regulatory"]][[l]]]), "regulatory", info = l)
    expect_equal(unname(m$target[tr[["modules.response.measures.multiple_levels"]][[l]]]), "multiple", info = l)
    expect_equal(unname(m$status[tr[["modules.response.measures.partially_implemented"]][[l]]]), "partially_implemented", info = l)
  }
})

test_that("normalize maps legacy labels to codes, keeps unresolvable text, is idempotent", {
  tr <- jsonlite::fromJSON(file.path(PROJECT_ROOT, "translations", "modules", "response_measures.json"),
                           simplifyVector = FALSE)$translation
  legacy <- data.frame(ID = c("RM_1", "RM_2"), Name = c("a", "b"),
                       Type = c(tr[["modules.response.measures.economic"]]$lt, "hand typed"),
                       Target = c(tr[["modules.response.measures.pressures"]]$de, ""),
                       Status = c(tr[["modules.response.measures.implemented"]]$el, "planned"),
                       Cost = c(5, 3), stringsAsFactors = FALSE)
  out <- normalize_response_measures(legacy)
  expect_equal(names(out), RM_REGISTER_COLUMNS)
  expect_equal(out$Type, c("economic", "hand typed"))
  expect_equal(out$Target, c("pressures", ""))
  expect_equal(out$Status, c("implemented", "planned"))
  expect_equal(out$Kind, c("", ""))
  expect_identical(normalize_response_measures(out), out)
})

test_that("normalize accepts NULL, empty list and list-of-rows (simplifyVector = FALSE)", {
  expect_equal(nrow(normalize_response_measures(NULL)), 0L)
  expect_equal(nrow(normalize_response_measures(list())), 0L)
  rows <- list(list(ID = "RM_1", Name = "x", Type = "regulatory", Cost = 2,
                    ImplementingStakeholders = "SH_1;SH_2", Tenet_ecol_effective = "full"))
  out <- normalize_response_measures(rows)
  expect_equal(out$ImplementingStakeholders, "SH_1;SH_2")
  expect_equal(out$Tenet_ecol_effective, "full")
  expect_equal(out$Cost, 2)
})

test_that("suggest_rm_target follows WS-1 dapsiwrm_target; instruments suggest nothing", {
  expect_equal(suggest_rm_target("output"), "pressures")
  expect_equal(suggest_rm_target("input.effort"), "activities")
  expect_equal(suggest_rm_target("restoration.habitat"), "state")
  expect_equal(suggest_rm_target("spatial.year_round"), "multiple")
  expect_equal(suggest_rm_target("1.1"), "")
  expect_equal(suggest_rm_target(""), "")
  expect_equal(suggest_rm_target(NULL), "")
})

test_that("ebm_code_choices: types only for instruments, all measures for measures, blank first", {
  idt <- list(t = function(k) k)
  ins <- ebm_code_choices("instrument", idt)
  expect_equal(unname(ins[1]), "")
  expect_setequal(unname(ins[-1]), EBM_POLICY_INSTRUMENTS$code[EBM_POLICY_INSTRUMENTS$level == "type"])
  expect_setequal(unname(ebm_code_choices("measure", idt)[-1]), EBM_MANAGEMENT_MEASURES$code)
  expect_equal(unname(ebm_code_choices("", idt)), "")
})

test_that("display labels translate codes and fall back to raw text", {
  lab <- list(t = function(k) paste0("T:", k))
  expect_equal(rm_display_label("type", c("regulatory", "hand typed", ""), lab),
               c("T:modules.response.measures.regulatory", "hand typed", ""))
  expect_equal(rm_display_label("target", "multiple", lab), "T:modules.response.measures.multiple_levels")
  expect_equal(rm_display_label("governance_level", "eu", lab), "T:modules.response.governance.level.eu")
  expect_equal(rm_display_label("ebm_code", "output", lab), "T:modules.wp5_vocabulary.measure.output")
  expect_equal(rm_display_label("ebm_code", "1.1", lab), "T:modules.wp5_vocabulary.instrument.1_1")
})

test_that("stakeholder id codec round-trips and drops blanks", {
  expect_equal(encode_ids(c("SH_1", "", "SH_2")), "SH_1;SH_2")
  expect_equal(encode_ids(NULL), "")
  expect_equal(decode_ids("SH_1;SH_2"), c("SH_1", "SH_2"))
  expect_equal(decode_ids(""), character(0))
})

test_that("governance translations exist in all 9 languages", {
  tr <- jsonlite::fromJSON(file.path(PROJECT_ROOT, "translations", "modules", "response_governance.json"),
                           simplifyVector = FALSE)$translation
  keys <- c(paste0("modules.response.governance.level.", GOVERNANCE_LEVELS),
            paste0("modules.response.governance.kind.", c("instrument", "measure")),
            paste0("modules.response.governance.tenet_level.", c(TENET_LEVELS, "not_assessed")))
  for (k in keys) for (l in c("en","es","fr","de","lt","pt","it","no","el"))
    expect_true(nzchar(tr[[k]][[l]] %||% ""), info = paste(k, l))
})

# ---- Task 2: every load path; JSON round-trips -----------------------------------
mk_project_with_register <- function() {
  p <- create_empty_project("t")
  p$data$response_measures$measures <- normalize_response_measures(data.frame(
    ID = c("RM_1", "RM_2"), Name = c("Quota", "Moorings"), Type = c("regulatory", "economic"),
    Target = c("pressures", "activities"), Status = c("planned", "proposed"), Cost = c(4, 7),
    Kind = c("measure", "instrument"), EbmCode = c("output", "3.4"), GovernanceLevel = c("national", "local"),
    ImplementingStakeholders = c("SH_1;SH_2", ""), PairedWith = c("RM_2", "RM_1"),
    Tenet_ecol_effective = c("intermediate", ""), Tenet_legally_permissible = c("full", "minimal"),
    stringsAsFactors = FALSE))
  p
}

test_that("create_empty_project uses the register schema", {
  expect_equal(names(create_empty_project("t")$data$response_measures$measures), RM_REGISTER_COLUMNS)
})

test_that("register survives JSON round-trip with simplifyVector = TRUE and FALSE", {
  p <- mk_project_with_register()
  js <- jsonlite::toJSON(p, auto_unbox = TRUE, null = "null", na = "null")
  for (sv in c(TRUE, FALSE)) {
    back <- normalize_json_project_data(jsonlite::fromJSON(js, simplifyVector = sv))
    m <- back$data$response_measures$measures
    expect_equal(names(m), RM_REGISTER_COLUMNS, info = sv)
    expect_equal(m$ImplementingStakeholders, c("SH_1;SH_2", ""), info = sv)
    expect_equal(m$Tenet_ecol_effective, c("intermediate", ""), info = sv)
    expect_equal(m$EbmCode, c("output", "3.4"), info = sv)
    expect_equal(m$Cost, c(4, 7), info = sv)
  }
})

test_that("legacy Lithuanian-label register is migrated on project load", {
  tr <- jsonlite::fromJSON(file.path(PROJECT_ROOT, "translations", "modules", "response_measures.json"),
                           simplifyVector = FALSE)$translation
  p <- create_empty_project("t")
  p$data$response_measures$measures <- data.frame(
    ID = "RM_1", Name = "x", Type = tr[["modules.response.measures.regulatory"]]$lt,
    Target = tr[["modules.response.measures.state"]]$lt, Status = tr[["modules.response.measures.planned"]]$lt,
    Cost = 5, stringsAsFactors = FALSE)
  out <- normalize_and_reconcile_project(p)$data$response_measures$measures
  expect_equal(c(out$Type, out$Target, out$Status), c("regulatory", "state", "planned"))
})

# ---- final-review fix C1: ragged list-of-rows must never empty the register --------
test_that("C1: local-storage-style JSON (no na='null') with an NA Cost keeps every row", {
  p <- create_empty_project("t")
  p$data$response_measures$measures <- normalize_response_measures(data.frame(
    ID = c("RM_1", "RM_2"), Name = c("a", "b"), Type = c("regulatory", "economic"), Cost = c(NA, 3),
    stringsAsFactors = FALSE))
  js <- jsonlite::toJSON(p, auto_unbox = TRUE, null = "null")   # as local_storage_module.R serialised before the fix
  m <- normalize_json_project_data(jsonlite::fromJSON(js, simplifyVector = FALSE))$data$response_measures$measures
  expect_equal(m$ID, c("RM_1", "RM_2"))
  expect_true(is.na(m$Cost[1]))
  expect_equal(m$Cost[2], 3)
})

test_that("C1: ragged legacy list-of-rows keeps every row", {
  out <- normalize_response_measures(list(list(ID = "RM_1", Name = "a", Type = "regulatory", Cost = 2),
                                          list(ID = "RM_2", Name = "b", Type = "economic")))
  expect_equal(out$ID, c("RM_1", "RM_2"))
  expect_true(is.na(out$Cost[2]))
})

test_that("C1: local storage serialises NA as null", {
  src <- readLines(file.path(PROJECT_ROOT, "modules", "local_storage_module.R"), warn = FALSE)
  tj <- grep("toJSON(", src, value = TRUE, fixed = TRUE)
  expect_gt(length(tj), 0)
  expect_true(all(grepl('na = "null"', tj, fixed = TRUE)))
})

# ---- final-review fixes I1/I2: display translation incl. tenets; curated columns ------
test_that("rm_translate_for_display translates codes and tenet levels; raw values pass through", {
  lab <- list(t = function(k) paste0("T:", k))
  df <- normalize_response_measures(data.frame(ID = "RM_1", Name = "x", Type = "regulatory", Status = "planned",
    Effectiveness = "HIGH", Tenet_ecol_effective = "intermediate", Tenet_communicable = "full",
    stringsAsFactors = FALSE))
  out <- rm_translate_for_display(df, lab)
  expect_equal(out$Type, "T:modules.response.measures.regulatory")
  expect_equal(out$Effectiveness, "T:modules.response.measures.high")
  expect_equal(out$Tenet_ecol_effective, "T:modules.response.governance.tenet_level.intermediate")
  expect_equal(out$Tenet_communicable, "T:modules.response.governance.tenet_level.full")
  expect_equal(out$Tenet_econ_viable, "")
})

test_that("register display/report column set excludes tenet, stakeholder-ID and pairing columns", {
  expect_false(any(startsWith(RM_DISPLAY_COLUMNS, "Tenet_")))
  expect_false(any(c("ImplementingStakeholders", "PairedWith") %in% RM_DISPLAY_COLUMNS))
  expect_true(all(c("ID", "Name", "Type", "Target", "Kind", "EbmCode", "GovernanceLevel", "Status") %in% RM_DISPLAY_COLUMNS))
})

# ---- final-review fix I3: stakeholder picker keeps the selection ---------------------
test_that("stakeholder_picker_update keeps current selection and skips no-op updates", {
  sh <- data.frame(ID = c("SH_1", "SH_2"), Name = c("Park", "Fishers"), stringsAsFactors = FALSE)
  u1 <- stakeholder_picker_update(sh, current = c("SH_2"), previous_choices = NULL)
  expect_false(u1$skip)
  expect_equal(unname(u1$choices), c("SH_1", "SH_2"))
  expect_equal(u1$selected, "SH_2")
  expect_true(stakeholder_picker_update(sh, current = "SH_2", previous_choices = u1$choices)$skip)
  u3 <- stakeholder_picker_update(sh[1, ], current = c("SH_1", "SH_2"), previous_choices = u1$choices)
  expect_equal(u3$selected, "SH_1")   # removed stakeholder dropped, kept one retained
  expect_false(stakeholder_picker_update(NULL, current = NULL, previous_choices = u1$choices)$skip)
})

test_that("PestleTag: added to legacy registers, unknown codes dropped, order kept", {
  legacy <- data.frame(ID = "R1", Name = "a", Type = "regulatory", stringsAsFactors = FALSE)
  out <- normalize_response_measures(legacy)
  expect_true("PestleTag" %in% names(out))
  expect_equal(out$PestleTag, "")
  tagged <- data.frame(ID = "R2", Name = "b", PestleTag = "legal;bogus;political", stringsAsFactors = FALSE)
  expect_equal(normalize_response_measures(tagged)$PestleTag, "political;legal")   # PESTLE order, unknown dropped
})

test_that("PestleTag survives a JSON save/load round trip and is a register display column", {
  reg <- normalize_response_measures(data.frame(ID = c("R1", "R2"), Name = c("a", "b"),
                                                PestleTag = c("political;legal", ""), stringsAsFactors = FALSE))
  back <- normalize_response_measures(jsonlite::fromJSON(jsonlite::toJSON(reg), simplifyVector = FALSE))
  expect_equal(back$PestleTag, c("political;legal", ""))
  expect_true("PestleTag" %in% RM_DISPLAY_COLUMNS)
})

test_that("PestleTag is shown as translated labels", {
  df <- data.frame(PestleTag = c("political;legal", ""), stringsAsFactors = FALSE)
  out <- rm_translate_for_display(df, list(t = function(k) paste0("<", k, ">")))
  expect_equal(out$PestleTag, c("<modules.wp5_scenarios.pestle.political>, <modules.wp5_scenarios.pestle.legal>", ""))
})

test_that("tenet levels: invalid values and intermediate outside ecol_effective are blanked (WS-10 follow-up)", {
  out <- normalize_response_measures(data.frame(
    ID = c("RM001", "RM002"), Name = c("a", "b"),
    Tenet_ecol_effective = c("intermediate", "great"),
    Tenet_communicable   = c("intermediate", "full"), stringsAsFactors = FALSE))
  expect_equal(out$Tenet_ecol_effective, c("intermediate", ""))
  expect_equal(out$Tenet_communicable, c("", "full"))
  expect_equal(normalize_response_measures(out), out)                       # idempotent
})
