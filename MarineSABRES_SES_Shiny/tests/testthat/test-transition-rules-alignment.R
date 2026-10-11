# tests/testthat/test-transition-rules-alignment.R
# Review 2026-10-07:
#   N26 - P -> MPF seeds "-" everywhere (polarity from DAPSIWRM_ADJACENCY_RULES),
#         and existing cells never have their polarity rewritten.
#   N61 - DAPSIWRM_ADJACENCY_RULES, is_valid_dapsirwrm_transition() and
#         DAPSIWRM_FRAMEWORK_RULES.md accept the same transitions.
#   N62 - the Responses form edits R -> MPF (Rule 12) and R -> R (Rule 14).
source_for_test(c("functions/dapsiwrm_connection_rules.R",
                  "functions/network_analysis.R",
                  "functions/data_structure.R",
                  "functions/matrix_from_linked.R",
                  "functions/standard_entry_excel_import.R",
                  "functions/isa_form_builders.R"))

# ---------------------------------------------------------------------------
# N26: P -> MPF default polarity
# ---------------------------------------------------------------------------

rule_p_mpf <- function() {
  DAPSIWRM_ADJACENCY_RULES$Pressures$target_polarities[["Marine Processes & Functioning"]]
}

test_that("N26: the rule table says P -> MPF is '-' and the matrix lookup agrees", {
  expect_equal(rule_p_mpf(), "-")
  expect_equal(default_polarity_for_matrix("p_mpf"), rule_p_mpf())
})

test_that("N26: every Standard Entry matrix key seeds the rule-table default", {
  expected <- c(d_a = "+", a_p = "+", p_mpf = "-", mpf_es = "+", es_gb = "+",
                gb_d = "+", gb_r = "+", r_d = "-", r_a = "-", r_p = "-",
                r_mpf = "+", r_r = "+")
  got <- vapply(names(expected), default_polarity_for_matrix, character(1))
  expect_equal(got, expected)
  # and each one is read from the table, not hard-coded
  for (k in names(DAPSIWRM_MATRIX_KEY_TYPES)) {
    ty <- DAPSIWRM_MATRIX_KEY_TYPES[[k]]
    expect_equal(default_polarity_for_matrix(k),
                 unname(DAPSIWRM_ADJACENCY_RULES[[ty[1]]]$target_polarities[[ty[2]]]),
                 info = k)
  }
})

p_mpf_saved <- function(adjacency_matrices = list()) {
  list(
    pressures = data.frame(ID = "P001", Name = "Overfishing", LinkedMPF = "MPF001|MPF002",
                           stringsAsFactors = FALSE),
    marine_processes = data.frame(ID = c("MPF001", "MPF002"), Name = c("Fish biomass", "Seagrass"),
                                  stringsAsFactors = FALSE),
    adjacency_matrices = adjacency_matrices
  )
}

test_that("N26: recover_isa_data seeds an unsigned P -> MPF link with the rule default", {
  rec <- recover_isa_data(p_mpf_saved())
  m <- rec$adjacency_matrices$p_mpf
  expect_true(is.matrix(m))
  expect_equal(substr(m["P001", "MPF001"], 1, 1), rule_p_mpf())
  expect_equal(substr(m["P001", "MPF002"], 1, 1), rule_p_mpf())
})

test_that("N26: recover_isa_data keeps an existing explicit '+' P -> MPF cell", {
  existing <- matrix(c("+strong:4", ""), 1, 2, dimnames = list("P001", c("MPF001", "MPF002")))
  rec <- recover_isa_data(p_mpf_saved(list(p_mpf = existing)))
  expect_equal(rec$adjacency_matrices$p_mpf["P001", "MPF001"], "+strong:4")
})

test_that("N26: the Standard Entry rebuild seeds new P -> MPF cells '-' but never flips an existing '+'", {
  el <- data.frame(ID = "P001", LinkedMPF = "MPF001|MPF002", stringsAsFactors = FALSE)
  # an old save: the '+' edge exists, user_edited flags absent (all FALSE)
  existing <- matrix(c("+medium:3", ""), 1, 2, dimnames = list("P001", c("MPF001", "MPF002")))
  res <- rebuild_matrix_from_linked(
    el, "LinkedMPF", "P001", c("MPF001", "MPF002"),
    existing_matrix = existing, user_edited_matrix = NULL,
    default_polarity = default_polarity_for_matrix("p_mpf"))
  expect_equal(res$matrix["P001", "MPF001"], "+medium:3")   # preserved sign
  expect_equal(res$matrix["P001", "MPF002"], "-medium:3")   # new cell: rule default
})

# ---------------------------------------------------------------------------
# N61: the three transition-rule sources agree
# ---------------------------------------------------------------------------

# Table type -> one synonym the validator recognises. The validator's Measures
# group has no table entry (Measures are merged into Responses in the 7-type
# Standard Entry model), so it is out of scope for this comparison.
validator_name <- c(
  "Drivers" = "drivers", "Activities" = "activities", "Pressures" = "pressures",
  "Marine Processes & Functioning" = "mpf", "Ecosystem Services" = "es",
  "Goods & Benefits" = "gb", "Responses" = "responses"
)

test_that("N61: every table type is mapped for the comparison", {
  expect_setequal(names(DAPSIWRM_ADJACENCY_RULES), names(validator_name))
})

test_that("N61: is_valid_dapsirwrm_transition() and DAPSIWRM_ADJACENCY_RULES accept the same transitions", {
  types <- names(validator_name)
  pairs <- expand.grid(from = types, to = types, stringsAsFactors = FALSE)
  key <- paste(pairs$from, "->", pairs$to)

  by_validator <- key[mapply(function(f, t) {
    is_valid_dapsirwrm_transition(validator_name[[f]], validator_name[[t]])
  }, pairs$from, pairs$to)]
  by_table <- key[mapply(function(f, t) {
    t %in% get_allowed_targets(f, include_extensions = TRUE)
  }, pairs$from, pairs$to)]

  # non-vacuous: forward chain (5) + GB->D, GB->R + R->D/A/P/MPF (4)
  # + R->R, MPF->MPF, P->P, A->A + D->P (ExUP) = 16
  expect_gte(length(by_validator), 16L)
  expect_setequal(by_table, by_validator)
  expect_length(setdiff(by_validator, by_table), 0L)
  expect_length(setdiff(by_table, by_validator), 0L)
  # the transitions this finding added are present in both
  for (k in c("Responses -> Responses", "Pressures -> Pressures",
              "Marine Processes & Functioning -> Marine Processes & Functioning",
              "Activities -> Activities", "Drivers -> Pressures")) {
    expect_true(k %in% by_table, info = k)
    expect_true(k %in% by_validator, info = k)
  }
})

test_that("N61: every table transition has a default polarity in target_polarities", {
  for (f in names(DAPSIWRM_ADJACENCY_RULES)) {
    rule <- DAPSIWRM_ADJACENCY_RULES[[f]]
    for (t in unique(c(rule$targets, rule$extension_targets))) {
      expect_true(t %in% names(rule$target_polarities), info = paste(f, "->", t))
      expect_true(rule$target_polarities[[t]] %in% c("+", "-"), info = paste(f, "->", t))
    }
  }
})

test_that("N61: extension transitions validate in strict mode but are not suggested", {
  expect_true(validate_connection("Responses", "Responses", strict = TRUE))
  expect_true(validate_connection("Drivers", "Pressures", strict = TRUE))
  expect_true(validate_connection_with_feedback("Pressures", "Pressures", strict = TRUE)$valid)
  expect_false(validate_connection("Drivers", "Goods & Benefits", strict = TRUE))
  # canonical suggestion list unchanged (graphical builder)
  expect_equal(get_allowed_targets("Drivers"), "Activities")
  expect_equal(get_allowed_targets("Pressures"), "Marine Processes & Functioning")
})

test_that("N61: infer_connection_polarity uses per-target defaults for extensions", {
  expect_equal(infer_connection_polarity("Nutrient enrichment", "Cyanobacteria bloom",
                                         "Pressures", "Pressures"), "+")
  expect_equal(infer_connection_polarity("MPA", "Monitoring programme",
                                         "Responses", "Responses"), "+")
  # R -> MPF: the graphical builder and Standard Entry seed the same sign
  expect_equal(infer_connection_polarity("Marine protected area", "Fish stocks",
                                         "Responses", "Marine Processes & Functioning"),
               default_polarity_for_matrix("r_mpf"))
})

# ---------------------------------------------------------------------------
# N62: R -> MPF and R -> R in the Responses form
# ---------------------------------------------------------------------------

resp_isa <- function(linked_mpf = c("MPF002", ""), linked_r = c("R002", "")) {
  list(
    goods_benefits   = data.frame(ID = "GB001", Name = "Food", stringsAsFactors = FALSE),
    drivers          = data.frame(ID = "D001", Name = "Demand", stringsAsFactors = FALSE),
    activities       = data.frame(ID = character(), Name = character(), stringsAsFactors = FALSE),
    pressures        = data.frame(ID = character(), Name = character(), stringsAsFactors = FALSE),
    marine_processes = data.frame(ID = c("MPF001", "MPF002"), Name = c("Fish", "Seagrass"),
                                  stringsAsFactors = FALSE),
    responses        = data.frame(ID = c("R001", "R002"), Name = c("MPA", "Monitoring"),
                                  LinkedGB = c("GB001", ""), LinkedD = "", LinkedA = "", LinkedP = "",
                                  LinkedMPF = linked_mpf, LinkedR = linked_r,
                                  stringsAsFactors = FALSE),
    adjacency_matrices = list(), user_edited_matrices = list()
  )
}

test_that("N62: isa_fields_r offers linkedmpf and linkedr as advanced multi-selects", {
  i18n <- list(t = function(x) x)
  flds <- isa_fields_r(i18n, "GB001", "D001", character(), character(),
                       mpf_choices = c("", "MPF001: Fish"), r_choices = c("", "R002: Monitoring"))
  by_id <- setNames(flds, vapply(flds, function(f) f$id, character(1)))
  for (id in c("linkedmpf", "linkedr")) {
    expect_true(id %in% names(by_id), info = id)
    expect_true(isTRUE(by_id[[id]]$multiple), info = id)
    expect_true(isTRUE(by_id[[id]]$advanced), info = id)
  }
  expect_equal(by_id$linkedmpf$label, "modules.isa.data_entry.responses.linked_mpf")
  expect_equal(by_id$linkedr$label, "modules.isa.data_entry.responses.linked_r")
  html <- as.character(build_response_panel_ui(function(x) paste0("m-", x), "R001", flds, i18n))
  expect_true(grepl("m-r_linkedmpf_R001", html, fixed = TRUE))
  expect_true(grepl("m-r_linkedr_R001", html, fixed = TRUE))
})

test_that("N62: R -> MPF and R -> R round-trip form -> matrix -> form without loss", {
  out <- build_response_matrices(resp_isa())
  am <- out$adjacency_matrices
  expect_equal(dimnames(am$r_mpf), list(c("R001", "R002"), c("MPF001", "MPF002")))
  expect_equal(dimnames(am$r_r), list(c("R001", "R002"), c("R001", "R002")))
  expect_equal(am$r_mpf["R001", "MPF002"], paste0(default_polarity_for_matrix("r_mpf"), "medium:3"))
  expect_equal(am$r_mpf["R001", "MPF001"], "")
  expect_equal(am$r_r["R001", "R002"], paste0(default_polarity_for_matrix("r_r"), "medium:3"))
  expect_equal(sum(nzchar(am$r_r)), 1L)
  # matrix -> form (the load path re-derives Linked* from the matrices)
  expect_equal(rederive_linked_from_matrix(am$r_mpf, "R001", "row"), "MPF002")
  expect_equal(rederive_linked_from_matrix(am$r_r, "R001", "row"), "R002")
  expect_equal(rederive_linked_from_matrix(am$r_mpf, "R002", "row"), "")
})

test_that("N62: removing an R -> MPF / R -> R link clears the matrix cell", {
  isa <- resp_isa()
  first <- build_response_matrices(isa)
  isa$adjacency_matrices   <- first$adjacency_matrices
  isa$user_edited_matrices <- first$user_edited_matrices
  isa$responses$LinkedMPF <- c("", "")
  isa$responses$LinkedR   <- c("", "")
  second <- build_response_matrices(isa)
  expect_equal(second$adjacency_matrices$r_mpf["R001", "MPF002"], "")
  expect_equal(second$adjacency_matrices$r_r["R001", "R002"], "")
})

test_that("N62: an existing (template) R -> MPF sign survives a Responses re-save", {
  isa <- resp_isa()
  isa$adjacency_matrices$r_mpf <- matrix(c("-strong:4", "", "", ""), 2, 2,
                                         dimnames = list(c("R001", "R002"), c("MPF001", "MPF002")))
  isa$responses$LinkedMPF <- c("MPF001", "")
  out <- build_response_matrices(isa)
  expect_equal(substr(out$adjacency_matrices$r_mpf["R001", "MPF001"], 1, 1), "-")
})

test_that("N62: recover_isa_data rebuilds r_mpf / r_r from LinkedMPF / LinkedR (Excel import fallback)", {
  saved <- resp_isa()
  saved$adjacency_matrices <- list()
  saved$responses$LinkedMPF <- c("MPF002: Seagrass", "")
  saved$responses$LinkedR   <- c("R002: Monitoring", "")
  rec <- recover_isa_data(saved)
  expect_equal(rec$adjacency_matrices$r_mpf["R001", "MPF002"],
               paste0(default_polarity_for_matrix("r_mpf"), "medium:3"))
  expect_equal(rec$adjacency_matrices$r_r["R001", "R002"],
               paste0(default_polarity_for_matrix("r_r"), "medium:3"))
})

test_that("N62: r_mpf / r_r survive the Standard Entry Excel export + import", {
  skip_if_not_installed("openxlsx")
  isa <- resp_isa()
  built <- build_response_matrices(isa)
  isa$adjacency_matrices <- built$adjacency_matrices
  f <- tempfile(fileext = ".xlsx"); on.exit(unlink(f))
  wb <- openxlsx::createWorkbook()
  write_isa_element_sheets(wb, isa)
  openxlsx::saveWorkbook(wb, f, overwrite = TRUE)
  saved <- read_standard_entry_workbook(f)
  rec <- recover_isa_data(saved)
  expect_equal(rec$adjacency_matrices$r_mpf["R001", "MPF002"], built$adjacency_matrices$r_mpf["R001", "MPF002"])
  expect_equal(rec$adjacency_matrices$r_r["R001", "R002"], built$adjacency_matrices$r_r["R001", "R002"])
})

test_that("N62: JSON project round trip restores r_mpf / r_r (incl. sidecar-less files)", {
  isa <- resp_isa()
  built <- build_response_matrices(isa)
  pd <- create_empty_project("T")
  for (k in c("goods_benefits", "drivers", "marine_processes", "responses")) pd$data$isa_data[[k]] <- isa[[k]]
  pd$data$isa_data$adjacency_matrices <- built$adjacency_matrices[c("r_mpf", "r_r")]
  for (sidecar in c(TRUE, FALSE)) {
    obj <- if (sidecar) with_matrix_dimnames_sidecar(pd) else pd
    js <- as.character(jsonlite::toJSON(obj, auto_unbox = TRUE, null = "null", na = "null"))
    back <- normalize_json_project_data(jsonlite::fromJSON(js, simplifyVector = TRUE))$data$isa_data
    expect_equal(back$adjacency_matrices$r_mpf["R001", "MPF002"],
                 built$adjacency_matrices$r_mpf["R001", "MPF002"], info = sidecar)
    expect_equal(back$adjacency_matrices$r_r["R001", "R002"],
                 built$adjacency_matrices$r_r["R001", "R002"], info = sidecar)
  }
  expect_true(all(c("r_mpf", "r_r") %in% unname(ISA_MATRIX_REVIEW_CHOICES)))
})
