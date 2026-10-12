# tests/testthat/test-valuation-calculations.R
# WS-5: valuation calculator — source verification, pure functions, aggregate.
library(testthat)
load_wp5_mechanisms_kb(file.path(PROJECT_ROOT, "data", "ses_knowledge_db_wp5_mechanisms.json"),
                       force_reload = TRUE)

ext_path <- file.path(PROJECT_ROOT, "scripts", "wp5_kb_sources", "d5.2_v5_indicator_sources.md")
squash <- function(x) gsub("\\s+", " ", trimws(x))
extract_range <- function(from, to) {
  l <- readLines(ext_path, encoding = "UTF-8", warn = FALSE)
  m <- regmatches(l, regexec("^L([0-9]+): ?(.*)$", l))
  keep <- lengths(m) == 3
  txt <- setNames(vapply(m[keep], `[`, character(1), 3), vapply(m[keep], `[`, character(1), 2))
  rng <- as.character(seq(from, to))
  expect_true(all(rng %in% names(txt)), info = paste("extract lacks", from, "-", to))
  squash(paste(txt[intersect(rng, names(txt))], collapse = " "))
}
eur <- function(x) paste0("€", format(x, big.mark = ",", scientific = FALSE, trim = TRUE))

test_that("KB Table 19 bands are quoted verbatim in D5.2 Table 19 (L3287-3325)", {
  hay <- extract_range(3287, 3325)
  uv <- get_valuation_unit_values(WP5_VALUATION_HABITAT)
  expect_setequal(names(uv), WP5_VALUATION_SERVICES)
  for (s in WP5_VALUATION_SERVICES) {
    q <- paste(eur(uv[[s]]$low), "–", eur(uv[[s]]$high))       # "€3,500 – €17,200"
    expect_true(grepl(q, hay, fixed = TRUE), info = paste(s, q))
  }
  tot_low <- sum(vapply(uv, function(v) v$low, numeric(1)))
  tot_high <- sum(vapply(uv, function(v) v$high, numeric(1)))
  expect_true(grepl(paste(eur(tot_low), "-", eur(tot_high)), hay, fixed = TRUE))   # TOTAL row uses "-"
})

test_that("KB restoration costs and survival are quoted in D5.2 §4.8 (L3348-3362)", {
  hay <- extract_range(3348, 3362)
  rc <- get_restoration_costs(WP5_VALUATION_HABITAT)
  expect_false(is.null(rc))
  expect_true(grepl(paste("between", eur(rc$low), "and", eur(rc$high)), hay, fixed = TRUE))
  expect_true(grepl(sprintf("range from %d%% to %d%%", round(100 * rc$early_survival_low),
                            round(100 * rc$early_survival_high)), hay, fixed = TRUE))
  expect_true(grepl("€88,800 to over €500,000 per hectare", hay, fixed = TRUE))
})

test_that("get_restoration_costs returns NULL for an unknown habitat", {
  expect_null(get_restoration_costs("kelp"))
})
