# tests/testthat/test-indicator-registry.R
# WS-4: WP5 indicator registry: data invariants, source-quote verification, loader, lookups.
library(testthat)

reg_path <- file.path(PROJECT_ROOT, "data", "wp5_indicators.json")
ext_path <- file.path(PROJECT_ROOT, "scripts", "wp5_kb_sources", "d5.2_v5_indicator_sources.md")
reg <- jsonlite::fromJSON(reg_path, simplifyVector = FALSE)
entries <- reg$entries
codes <- vapply(entries, function(e) e$code, character(1))
by_code <- setNames(entries, codes)
mac_fiche <- c("C_01","C_02","F_01","F_02","F_03","M_01","M_02","T_01","T_02","T_03","T_04")
mac_stubs <- c("C_02", "M_02", "T_02", "T_04")

squash <- function(x) gsub("\\s+", " ", trimws(x))
extract_lines <- function() {
  l <- readLines(ext_path, encoding = "UTF-8", warn = FALSE)
  m <- regmatches(l, regexec("^L([0-9]+): ?(.*)$", l))
  keep <- lengths(m) == 3
  setNames(vapply(m[keep], `[`, character(1), 3), vapply(m[keep], `[`, character(1), 2))
}

test_that("registry header and every entry carry the required fields", {
  expect_true(all(c("schema_version", "registry_version", "entries", "dapsiwrm_type_map") %in% names(reg)))
  req <- c("code", "annex_code", "name", "da", "source_set", "dapsiwrm_type", "unit", "scale_type",
           "data_sources", "provenance", "revision", "stub")
  for (e in entries) expect_true(all(req %in% names(e)), info = e$code)   # annex_code may be null
})

test_that("codes are unique and annex codes remap per A§5.1", {
  expect_false(anyDuplicated(codes) > 0)
  remap <- c(F_02 = "F_01", F_03 = "F_02", F_04 = "F_03", M_03 = "M_02")
  for (ac in names(remap)) {
    hit <- Filter(function(e) identical(e$annex_code, ac), entries)
    expect_length(hit, 1)
    expect_equal(hit[[1]]$code, remap[[ac]], info = ac)
  }
})

test_that("Macaronesia fiche set has the 11 canonical codes; C_02, M_02, T_02, T_04 are stubs with cited criteria", {
  fiche <- codes[vapply(entries, function(e) identical(e$source_set, "fiche"), logical(1))]
  expect_setequal(fiche, mac_fiche)
  stubs <- codes[vapply(entries, function(e) isTRUE(e$stub), logical(1))]
  expect_setequal(stubs, mac_stubs)
  for (s in mac_stubs) {
    e <- by_code[[s]]
    expect_length(e$baseline, 0)
    expect_equal(e$provenance, "provisional", info = s)
    expect_gte(length(e$criterion_roles), 1)                         # spec: "name and criterion role only"
    for (r in e$criterion_roles) {
      expect_null(r$role)                                            # D5.2 publishes no role for stubs
      expect_true(nzchar(r$role_text %||% ""), info = s)
    }
  }
})

test_that("T_03 records both meanings; the fiche meaning is canonical", {
  t3 <- by_code[["T_03"]]
  expect_match(t3$name, "tourism companies", ignore.case = TRUE)
  expect_match(t3$alt_meaning, "wildlife", ignore.case = TRUE)
})

test_that("vocabulary fields use valid codes", {
  for (e in entries) {
    expect_true(e$da %in% WP5_DA_CONTEXTS, info = e$code)
    expect_true(e$source_set %in% WP5_INDICATOR_SOURCE_SETS, info = e$code)
    expect_true(e$dapsiwrm_type %in% ISA_ELEMENT_KEYS, info = e$code)
    expect_true(e$scale_type %in% WP5_INDICATOR_SCALE_TYPES, info = e$code)
    expect_true(e$provenance %in% c("wp5_source", "wp5_derived", "toolbox_extension", "provisional"), info = e$code)
    if (!is.null(e$pathway_segment)) expect_true(e$pathway_segment %in% WP5_RUBRIC$pathway_segment, info = e$code)
    for (k in names(e$criterion_roles)) {
      expect_equal(wp5_criterion_code(k), k, info = paste(e$code, k))   # stored canonical (PI/FF, not PO/FI)
      r <- e$criterion_roles[[k]]
      if (!is.null(r$role)) expect_true(r$role %in% WP5_RUBRIC$indicator_role, info = paste(e$code, k))
    }
    for (s in names(e$scenario_projection)) {
      expect_true(s %in% c("S1", "S2", "S3", "S4"), info = e$code)
      expect_true(e$scenario_projection[[s]]$direction %in% WP5_RUBRIC$direction, info = paste(e$code, s))
    }
    expect_true(is.numeric(e$revision) && e$revision >= 1, info = e$code)
  }
})

test_that("source_set matches the code family", {
  for (e in entries) {
    want <- if (grepl("_A1_", e$code)) "annex1" else if (startsWith(e$code, "TUS_POS_")) "posidonia"
            else if (startsWith(e$code, "ARC_")) "arctic" else "fiche"
    expect_equal(e$source_set, want, info = e$code)
  }
})

test_that("provenance rules: cited entries have lines and quotes; wp5_derived has a derivation", {
  for (e in entries) {
    if (e$provenance %in% c("wp5_source", "wp5_derived", "provisional")) {
      expect_false(is.null(e$source_ref$lines), info = e$code)
      expect_true(length(e$source_quotes) >= 1, info = e$code)
    }
    if (e$provenance == "wp5_derived") expect_true(nzchar(e$derivation %||% ""), info = e$code)
  }
})

test_that("every source quote appears verbatim inside its cited line range", {
  ex <- extract_lines()
  for (e in entries) {
    if (is.null(e$source_ref$lines)) next
    rng <- as.character(seq(e$source_ref$lines[[1]], e$source_ref$lines[[2]]))
    expect_true(all(rng %in% names(ex)), info = paste(e$code, "range not in extract"))
    hay <- squash(paste(ex[intersect(rng, names(ex))], collapse = " "))
    for (q in e$source_quotes) expect_true(grepl(squash(q), hay, fixed = TRUE), info = paste(e$code, "quote:", q))
  }
})

test_that("F_01 baseline transcribes the published 2022-24 shares", {
  b <- by_code[["F_01"]]$baseline
  vals <- setNames(vapply(b, function(x) x$value, numeric(1)), vapply(b, function(x) x$area, character(1)))
  expect_equal(unname(vals[c("Madeira", "Azores", "Canaries")]), c(37.77, 45.48, 51.24))
})

test_that("F_01 scenario directions follow ruling 11 (↔ is stable)", {
  sp <- by_code[["F_01"]]$scenario_projection
  expect_equal(vapply(sp[c("S1", "S2", "S3", "S4")], function(x) x$direction, character(1), USE.NAMES = FALSE),
               c("no_change", "decrease", "decrease", "increase"))
})

test_that("F_02 (CPUE) publishes no baseline values and is flagged as a data gap", {
  f2 <- by_code[["F_02"]]
  expect_length(f2$baseline, 0)
  expect_true(isTRUE(f2$data_gap))
  expect_true(nzchar(f2$caveat %||% ""))
})
