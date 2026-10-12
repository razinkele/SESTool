# tests/testthat/test-impact-reference-data.R
# WS-6a: data/wp5_impact_reference.json is checked against the committed
# D5.2 v5 layout extract. Table 21 columns are interleaved in the layout, so
# each value carries verify_phrases copied from a single extract line.
library(testthat)

ref <- jsonlite::fromJSON(file.path(PROJECT_ROOT, "data", "wp5_impact_reference.json"),
                          simplifyVector = FALSE)
ext_path <- file.path(PROJECT_ROOT, "scripts", "wp5_kb_sources", "d5.2_v5_indicator_sources.md")
ext_lines <- function(from, to) {
  l <- readLines(ext_path, encoding = "UTF-8", warn = FALSE)
  m <- regmatches(l, regexec("^L([0-9]+): ?(.*)$", l))
  keep <- lengths(m) == 3
  txt <- setNames(vapply(m[keep], `[`, character(1), 3), vapply(m[keep], `[`, character(1), 2))
  rng <- as.character(seq(from, to))
  expect_true(all(rng %in% names(txt)), info = paste("extract lacks", from, "-", to))
  unname(txt[intersect(rng, names(txt))])
}
# Table 21 row ranges (checked against the extract): each scenario's cells and
# confidence phrases must sit inside that scenario's own rows, not just the table
S21_ROWS <- list(S1 = c(4808, 4815), S2 = c(4817, 4824), S3 = c(4826, 4840), S4 = c(4842, 4851))
on_one_line <- function(phrase, lines) any(grepl(phrase, lines, fixed = TRUE))
da <- function(x) ref$demonstration_areas[[x]]
codes_of <- function(lst) vapply(lst, function(s) s$code, character(1))
load_wp5_mechanisms_kb(file.path(PROJECT_ROOT, "data", "ses_knowledge_db_wp5_mechanisms.json"),
                       force_reload = TRUE)

test_that("Macaronesia Table 21: 5 criteria x 4 scenarios, each anchored on one extract line", {
  mac <- da("macaronesia")
  lines <- ext_lines(mac$cell_source$source_lines[[1]], mac$cell_source$source_lines[[2]])
  keys <- vapply(mac$cells, function(c) paste(c$criterion, c$scenario), character(1))
  expect_setequal(keys, as.vector(outer(c("EE", "EC", "EQ", "PI", "FF"), paste0("S", 1:4), paste)))
  expect_identical(mac$provenance, "wp5_source")
  expect_identical(mac$source_ref$table, "Table 21")
  for (c in mac$cells) {
    rows <- ext_lines(S21_ROWS[[c$scenario]][1], S21_ROWS[[c$scenario]][2])
    for (p in c$verify_phrases) {
      expect_true(on_one_line(p, rows), info = paste(c$criterion, c$scenario, "not in its own scenario rows:", p))
    }
    # one anchor from the cell's first layout line, one from its last (catches dropped clauses)
    expect_gte(length(c$verify_phrases), 2)
    for (p in c$verify_phrases) {
      expect_true(on_one_line(p, lines), info = paste(c$criterion, c$scenario, "not in extract:", p))
      expect_true(grepl(p, c$text, fixed = TRUE), info = paste(c$criterion, c$scenario, "not in text:", p))
    }
  }
})

test_that("Macaronesia scenario confidence matches Table 21 and uses rubric codes", {
  mac <- da("macaronesia")
  lines <- ext_lines(4798, 4851)
  expect_identical(codes_of(mac$scenarios), paste0("S", 1:4))
  expect_identical(vapply(mac$scenarios, function(s) as.integer(s$ambition_rank), integer(1)), 1:4)
  for (s in mac$scenarios) {
    srows <- ext_lines(S21_ROWS[[s$code]][1], S21_ROWS[[s$code]][2])
    for (p in s$verify_phrases) {
      expect_true(on_one_line(p, srows), info = paste(s$code, "confidence phrase not in its own rows:", p))
    }
    expect_gte(length(s$verify_phrases), 2)
    for (p in s$verify_phrases) {
      expect_true(on_one_line(p, lines), info = p)
      expect_true(grepl(p, s$confidence_text, fixed = TRUE), info = p)
    }
    expect_true(all(unlist(s$confidence_codes) %in% WP5_RUBRIC$confidence))
  }
  conf <- setNames(lapply(mac$scenarios, function(s) unlist(s$confidence_codes)), codes_of(mac$scenarios))
  expect_identical(conf, list(S1 = "high", S2 = c("medium", "high"), S3 = "medium", S4 = c("low", "medium")))
})

test_that("Arctic Table 8: political feasibility per scenario, anchored on extract lines", {
  arc <- da("arctic")
  lines <- ext_lines(2166, 2180)
  expect_identical(arc$cell_source$table, "Table 8")
  expect_identical(arc$provenance, "wp5_source")
  expect_setequal(vapply(arc$cells, function(c) c$scenario, ""), c("no_agreement", "partial_agreement", "full_agreement"))
  for (c in arc$cells) {
    expect_identical(c$criterion, "PI")
    expect_gte(length(c$verify_phrases), 2)
    expect_true(on_one_line(c$rating_verify, lines), info = c$rating_verify)
    for (p in c$verify_phrases) {
      expect_true(on_one_line(p, lines), info = p)
      expect_true(grepl(p, paste(c$rating_text, c$text), fixed = TRUE), info = p)
    }
  }
  rating <- setNames(vapply(arc$cells, function(c) c$rating_text, ""), vapply(arc$cells, function(c) c$scenario, ""))
  expect_identical(rating[["full_agreement"]], "Low to moderate")
  expect_identical(rating[["partial_agreement"]], "Moderate")
  expect_identical(rating[["no_agreement"]], "High")
})

usd_millions_of <- function(display) {
  n <- as.numeric(gsub("[^0-9.]", "", display))
  if (grepl("billion", display, fixed = TRUE)) n * 1000 else n
}

test_that("Arctic revenue figures are the published table strings, never recomputed", {
  rev <- da("arctic")$revenue
  expect_identical(rev$provenance, "wp5_source")
  expect_identical(as.integer(rev$partner_question), 2L)
  expect_setequal(vapply(rev$countries, function(c) c$country, ""), c("faroe_islands", "greenland", "iceland"))
  for (cty in rev$countries) {
    bl <- ext_lines(cty$baseline_table$source_lines[[1]], cty$baseline_table$source_lines[[2]])
    sl <- ext_lines(cty$scenario_table$source_lines[[1]], cty$scenario_table$source_lines[[2]])
    expect_setequal(vapply(cty$species, function(s) s$species, ""), c("mackerel", "herring", "blue_whiting"))
    for (s in cty$species) {
      tag <- paste(cty$country, s$species)
      expect_true(on_one_line(s$landings_display, bl), info = tag)
      expect_true(on_one_line(s$price_display, bl), info = tag)
      expect_equal(s$landings_t, as.numeric(gsub(",", "", s$landings_display)), info = tag)
      expect_equal(s$price_usd_per_t, as.numeric(gsub("[$,]", "", s$price_display)), info = tag)
      expect_true(on_one_line(s$baseline$display, bl), info = tag)
      # landings x price must reproduce the published baseline within 1% (catches species swaps)
      expect_lt(abs(as.numeric(s$landings_t) * as.numeric(s$price_usd_per_t) / 1e6 / s$baseline$usd_millions - 1), 0.01, label = tag)
      expect_equal(s$baseline$usd_millions, usd_millions_of(s$baseline$display), info = tag)
      for (sc in c("no_agreement", "partial_agreement", "full_agreement")) {
        v <- s[[sc]]
        expect_true(on_one_line(v$display, sl), info = paste(tag, sc, v$display))
        expect_equal(v$usd_millions, usd_millions_of(v$display), info = paste(tag, sc))
      }
      # Tables 3 and 5 put one species per line in column order Full | Partial | No.
      # Locate the line by the Full value (Greenland "Blue Whiting" wraps). Iceland's
      # Table 7 is garbled in the text layer, so it keeps the presence-only check.
      if (cty$country %in% c("faroe_islands", "greenland")) {
        row <- sl[grepl(s$full_agreement$display, sl, fixed = TRUE)]
        expect_length(row, 1)
        pos <- vapply(c(s$full_agreement$display, s$partial_agreement$display, s$no_agreement$display),
                      function(d) as.integer(regexpr(d, row[1], fixed = TRUE)), integer(1))
        expect_true(all(pos > 0) && !is.unsorted(pos, strictly = TRUE), info = paste(tag, "column order"))
      }
    }
  }
  gl <- Filter(function(c) c$country == "greenland", rev$countries)[[1]]
  mack <- Filter(function(s) s$species == "mackerel", gl$species)[[1]]
  # Audit A§3.1: the stated assumptions would give ~75.8; D5.2 publishes 97.1
  expect_equal(mack$full_agreement$usd_millions, 97.1)
})

test_that("scenario codes match the WS-2 KB and baselines are scenarios", {
  for (d in c("macaronesia", "arctic")) {
    expect_identical(codes_of(da(d)$scenarios), codes_of(get_scenarios_for_da(d)), info = d)
    expect_true(da(d)$baseline_code %in% codes_of(da(d)$scenarios), info = d)
  }
  expect_identical(da("macaronesia")$baseline_code, "S1")
  expect_identical(da("arctic")$baseline_code, "partial_agreement")
  b <- da("arctic")$baseline_verify
  expect_true(on_one_line(b$phrase, ext_lines(b$source_lines[[1]], b$source_lines[[2]])))
})

test_that("Tuscan has no scenarios: valuation only", {
  tus <- da("tuscan")
  expect_identical(tus$status, "valuation_only")
  expect_length(tus$scenarios, 0)
  expect_length(tus$cells, 0)
})
