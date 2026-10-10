# tests/testthat/test-i18n-review-gaps.R
# Review 2026-10-07 i18n batch: N46 (Decision Lens table/plot/footer), N47
# (matrix cell-edit errors), N63 (SES models toasts), N64 (regional-sea labels).
source_for_test(c("functions/decision_lens.R", "functions/isa_form_builders.R",
                  "functions/ses_models_loader.R"))

tr_file <- function(rel) {
  for (root in c(file.path(getwd(), "../.."), getwd())) {
    p <- file.path(root, rel); if (file.exists(p)) return(p)
  }
  stop("not found: ", rel)
}
# A translator backed by the real modular translation file, so a key that is
# missing in `lang` shows up as the raw key (and fails the assertions).
make_translator <- function(rel, lang) {
  tr <- jsonlite::fromJSON(tr_file(rel), simplifyVector = FALSE)$translation
  list(t = function(k, ...) {
    v <- tr[[k]][[lang]]
    if (is.null(v)) k else v
  })
}

# ---- N46 -------------------------------------------------------------------
test_that("N46: the factor table has translated headers, categories and roles", {
  el <- make_translator("translations/modules/analysis_decision_lens.json", "el")
  f <- data.frame(id = c("D_1", "P_1"), label = c("Demand", "Bycatch"),
                  group = c("Drivers", "Pressures"), influence = c(0.81234, 0.2),
                  dependence = c(0.1, 0.7), quadrant = c("Influential", "Dependent"),
                  stringsAsFactors = FALSE)
  d <- dl_display_factors(f, el)
  expect_false(any(c("quadrant", "group", "label", "influence", "dependence", "id") %in% names(d)))
  expect_false(any(startsWith(names(d), "modules.")))
  expect_identical(names(d)[5], "Ρόλος")
  expect_identical(d[[5]], c("Επιδραστικό", "Εξαρτημένο"))
  expect_identical(d[[2]], c("Κινητήριες δυνάμεις", "Πιέσεις"))
  expect_equal(d[[3]][1], 0.812)
})

test_that("N46: unknown values pass through; every quadrant/group has a key in all languages", {
  en <- make_translator("translations/modules/analysis_decision_lens.json", "en")
  expect_identical(dl_quadrant_label(c("Relay", "Weird", NA), en), c("Relay", "Weird", NA))
  for (lang in c("en", "es", "fr", "de", "lt", "pt", "it", "no", "el")) {
    t <- make_translator("translations/modules/analysis_decision_lens.json", lang)
    labs <- c(dl_quadrant_label(c("Influential", "Relay", "Dependent", "Autonomous"), t),
              dl_group_label(c("Drivers", "Activities", "Pressures", "Marine Processes & Functioning",
                               "Ecosystem Services", "Goods & Benefits", "Responses"), t),
              t$t("modules.analysis.decision_lens.archetype_loops_label"))
    expect_false(any(startsWith(labs, "modules.")), info = lang)
  }
})

test_that("N46: module uses the translated table, legend and loops label", {
  s <- paste(readLines(tr_file("modules/analysis_decision_lens.R"), warn = FALSE), collapse = "\n")
  expect_true(grepl("dl_display_factors(rv$factors, i18n)", s, fixed = TRUE))
  expect_true(grepl("quadrant_label", s, fixed = TRUE))
  expect_false(grepl('"Loops: "', s, fixed = TRUE))
  expect_true(grepl("# i18n-ref: modules.analysis.decision_lens.archetype.limits_to_growth.name", s, fixed = TRUE))
})

# ---- N47 -------------------------------------------------------------------
test_that("N47: cell-edit errors carry an i18n key and are shown translated", {
  am <- list(d_a = matrix("", 2, 2, dimnames = list(c("D1", "D2"), c("A1", "A2"))))
  ue <- list()
  fr <- make_translator("translations/modules/isa_data_entry.json", "fr")

  bad <- apply_matrix_cell_edit(am, ue, "d_a", 1, 1, "strong")
  expect_identical(bad$error_key, "modules.isa.data_entry.matrix.cell_invalid")
  expect_identical(bad$error_value, "strong")
  msg <- matrix_cell_error_message(bad, fr)
  expect_true(startsWith(msg, "Cellule non valide"))
  expect_true(grepl("« strong »", msg, fixed = TRUE))

  expect_identical(apply_matrix_cell_edit(am, ue, "nope", 1, 1, "")$error_key,
                   "modules.isa.data_entry.matrix.cell_unknown_matrix")
  expect_identical(apply_matrix_cell_edit(am, ue, "d_a", 9, 1, "")$error_key,
                   "modules.isa.data_entry.matrix.cell_out_of_range")
  expect_null(matrix_cell_error_message(apply_matrix_cell_edit(am, ue, "d_a", 1, 1, "+strong:4"), fr))
  # user text with regex/backslash characters is inserted literally
  weird <- apply_matrix_cell_edit(am, ue, "d_a", 1, 1, "a\\1$&")
  expect_true(grepl("a\\1$&", matrix_cell_error_message(weird, fr), fixed = TRUE))
})

# ---- N63 -------------------------------------------------------------------
test_that("N63: known model errors are translated with their data; others pass through", {
  fr <- make_translator("translations/modules/ses_models.json", "fr")
  out <- translate_model_errors(c(
    "Missing 'Elements' sheet. Available: Sheet1, Data",
    "Connections sheet missing columns: From, To. Found: a, b",
    "3 edges reference non-existent nodes",
    "Elements sheet is empty",
    "Some technical detail"
  ), fr)
  expect_identical(out[1], "Le fichier n'a pas de feuille « Elements » (feuilles trouvées : Sheet1, Data).")
  expect_identical(out[2], "Il manque des colonnes dans la feuille Connections : From, To.")
  expect_true(startsWith(out[3], "3 connexion"))
  expect_identical(out[4], "Le modèle ne contient aucun élément.")
  expect_identical(out[5], "Some technical detail")
  expect_identical(translate_model_errors("x", NULL), "x")
})

test_that("N63: the SES models toasts use keys, not English literals", {
  s <- paste(readLines(tr_file("modules/ses_models_module.R"), warn = FALSE), collapse = "\n")
  expect_false(grepl('"SESModels directory not found:"', s, fixed = TRUE))
  expect_false(grepl('"-", length(rv$models_list), "models")', s, fixed = TRUE))
  expect_true(grepl("translate_model_errors(model_data$errors, i18n)", s, fixed = TRUE))
  fr <- make_translator("translations/modules/ses_models.json", "fr")
  expect_identical(sprintf(fr$t("modules.ses_models.models_reloaded_count"), 5L), "Modèles rechargés : 5 disponibles.")
})

# ---- N64 -------------------------------------------------------------------
test_that("N64: regional-sea dropdown labels are translated keys, one per sea", {
  s <- readLines(tr_file("server/dashboard.R"), warn = FALSE)
  keys <- regmatches(s, regexpr("modules\\.report_context\\.sea_[a-z_]+", s))
  expect_equal(length(unique(keys)), 12L)
  el <- make_translator("translations/modules/report_context.json", "el")
  labels <- vapply(unique(keys), el$t, character(1))
  expect_false(any(startsWith(labels, "modules.")))
  expect_identical(el$t("modules.report_context.sea_baltic_sea"), "Βαλτική Θάλασσα")
  expect_true(any(grepl("vapply(REGIONAL_SEA_LABEL_KEYS", s, fixed = TRUE)))
})
