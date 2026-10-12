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

# ---- Task 2: pure functions ---------------------------------------------------
source_for_test(c("functions/valuation_calculations.R"))
uv <- get_valuation_unit_values(WP5_VALUATION_HABITAT)
rc <- get_restoration_costs(WP5_VALUATION_HABITAT)
calc <- function(...) compute_valuation(..., unit_values = uv, restoration = rc)

test_that("1 ha, all services, 20 years reproduces D5.2 exactly (Table 19 total; §4.8 cumulative)", {
  r <- calc(area_ha = 1, services = WP5_VALUATION_SERVICES, horizon = 20)
  expect_true(r$ok)
  expect_equal(unname(r$total[c("low", "high")]), c(4440, 25840))
  expect_equal(unname(r$cumulative[c("low", "high")]), c(88800, 516800))    # "€88,800 to over €500,000"
  expect_equal(nrow(r$per_service), 5L)
  expect_equal(r$per_service$annual_low[r$per_service$service == "coastal_protection"], 3500)
})

test_that("roadmap §6.4 edge cases", {
  expect_equal(calculate_annual_value(0, list(low = 1, central = 2, high = 3)),
               list(low = 0, central = 0, high = 0))
  expect_equal(calculate_npv(100, 20, 0), 2000)
  expect_equal(calculate_npv(100, 0, 0.03), 0)
  expect_equal(calculate_npv(100000, 20, 0.03), 1487747.49, tolerance = 1e-6)
  expect_equal(calculate_break_even_horizon(4440, 100000, 0), 100000 / 4440)
  expect_equal(calculate_break_even_horizon(4440, 100000, 0.03), -log(1 - 3000 / 4440) / log(1.03))
})

test_that("restoration cost above the discounted perpetuity never breaks even", {
  expect_true(is.na(calculate_break_even_horizon(4440, 100000, 0.07)))     # 7000 > 4440 per year
  expect_true(is.na(calculate_break_even_horizon(0, 100000, 0)))
  expect_true(is.na(calculate_break_even_horizon(-5, 100000, 0.03)))
})

test_that("band ordering low <= central <= high holds for the totals, cumulative and every NPV row", {
  for (a in c(0, 0.5, 1, 37, 1e6)) for (h in c(0, 1, 20, 100)) {
    r <- calc(area_ha = a, services = WP5_VALUATION_SERVICES, horizon = h, discount_rate_pct = 4)
    expect_true(r$total[["low"]] <= r$total[["central"]] && r$total[["central"]] <= r$total[["high"]])
    expect_true(r$cumulative[["low"]] <= r$cumulative[["central"]] && r$cumulative[["central"]] <= r$cumulative[["high"]])
    expect_true(all(r$npv$low <= r$npv$central & r$npv$central <= r$npv$high))
  }
})

test_that("the NPV table always has 0/3/5/7%; a user rate is marked, not duplicated", {
  r <- calc(area_ha = 1, services = WP5_VALUATION_SERVICES, horizon = 20)
  expect_equal(r$npv$rate, c(0, 0.03, 0.05, 0.07))
  expect_false(any(r$npv$user))
  expect_true(is.na(r$user_rate))
  r3 <- calc(area_ha = 1, services = WP5_VALUATION_SERVICES, horizon = 20, discount_rate_pct = 3)
  expect_equal(r3$npv$rate, c(0, 0.03, 0.05, 0.07))
  expect_equal(r3$npv$user, c(FALSE, TRUE, FALSE, FALSE))
  r4 <- calc(area_ha = 1, services = WP5_VALUATION_SERVICES, horizon = 20, discount_rate_pct = 4)
  expect_equal(r4$npv$rate, c(0, 0.03, 0.04, 0.05, 0.07))
  expect_equal(r4$npv$user, c(FALSE, FALSE, TRUE, FALSE, FALSE))
  expect_equal(r4$npv$low[1], r4$cumulative[["low"]])                    # 0% NPV == undiscounted
})

test_that("restoration: cost, survival adjustment and break-even at both bands", {
  r <- calc(area_ha = 10, services = WP5_VALUATION_SERVICES, horizon = 20, restoration_area = 2, cost_bound = "low")
  x <- r$restoration
  expect_equal(x$cost, 200000)
  expect_equal(unname(x$survival_adjusted), c(200000 / 0.60, 200000 / 0.38))
  # review #1: break-even uses the survival-adjusted cost, consistent with the row above it.
  # Slowest case: lower service values vs cost / worst survival (0.38); fastest: higher values vs cost / 0.60.
  expect_equal(x$break_even_low, (200000 / 0.38) / (2 * 4440))
  expect_equal(x$break_even_high, (200000 / 0.60) / (2 * 25840))
  expect_true(x$beyond_horizon_low)                                         # 59.3 years > 20-year horizon
  expect_false(x$beyond_horizon_high)                                       # 6.5 years
  expect_false(isTRUE(calc(area_ha = 1, services = WP5_VALUATION_SERVICES, horizon = 20, restoration_area = 1,
                           cost_bound = "high", discount_rate_pct = 7)$restoration$beyond_horizon_low))  # NA: never
  expect_equal(x$rate, 0)
  expect_true(x$rate_is_fallback)
  rh <- calc(area_ha = 10, services = WP5_VALUATION_SERVICES, horizon = 20, restoration_area = 1,
             cost_bound = "high", discount_rate_pct = 7)
  expect_equal(rh$restoration$cost, 500000)
  expect_true(is.na(rh$restoration$break_even_low))                       # 35000/yr interest > 4440/yr
  expect_false(rh$restoration$rate_is_fallback)
  expect_null(calc(area_ha = 1, services = WP5_VALUATION_SERVICES, horizon = 20, restoration_area = 0)$restoration)
  expect_null(calc(area_ha = 1, services = WP5_VALUATION_SERVICES, horizon = 20, restoration_area = NA)$restoration)
})

test_that("break-even falls back to 0% when the rate is blank", {
  r <- calc(area_ha = 1, services = WP5_VALUATION_SERVICES, horizon = 20, restoration_area = 1,
            discount_rate_pct = NA)
  expect_equal(r$restoration$rate, 0)
  expect_true(r$restoration$rate_is_fallback)
})

test_that("invalid inputs return error keys and no numbers", {
  for (bad in list(NULL, NA, -1, "x", c(1, 2))) {
    r <- calc(area_ha = bad, services = WP5_VALUATION_SERVICES, horizon = 20)
    expect_false(r$ok)
    expect_true("invalid_area" %in% r$errors)
    expect_null(r$total)
  }
  expect_true("invalid_horizon" %in% calc(area_ha = 1, services = WP5_VALUATION_SERVICES, horizon = 101)$errors)
  expect_true("invalid_horizon" %in% calc(area_ha = 1, services = WP5_VALUATION_SERVICES, horizon = NA)$errors)
  expect_true("invalid_horizon" %in% calc(area_ha = 1, services = WP5_VALUATION_SERVICES, horizon = 20.5)$errors)
  expect_true("invalid_rate" %in% calc(area_ha = 1, services = WP5_VALUATION_SERVICES, horizon = 20,
                                       discount_rate_pct = 25)$errors)
  expect_true("invalid_rate" %in% calc(area_ha = 1, services = WP5_VALUATION_SERVICES, horizon = 20,
                                       discount_rate_pct = -1)$errors)
  expect_true("invalid_restoration_area" %in% calc(area_ha = 1, services = WP5_VALUATION_SERVICES, horizon = 20,
                                                   restoration_area = -2)$errors)
})

test_that("no services gives zero totals and a warning", {
  r <- calc(area_ha = 5, services = character(0), horizon = 20, restoration_area = 1)
  expect_true(r$ok)
  expect_equal(unname(r$total), c(0, 0, 0))
  expect_true("no_services" %in% r$warnings)
  expect_true(is.na(r$restoration$break_even_low))
  r2 <- calc(area_ha = 5, services = NULL, horizon = 20)
  expect_true("no_services" %in% r2$warnings)
})

test_that("missing unit values give data_unavailable", {
  r <- compute_valuation(area_ha = 1, services = WP5_VALUATION_SERVICES, horizon = 20,
                         unit_values = NULL, restoration = NULL)
  expect_false(r$ok)
  expect_equal(r$errors, "data_unavailable")
  r2 <- compute_valuation(area_ha = 1, services = WP5_VALUATION_SERVICES, horizon = 20, restoration_area = 1,
                          unit_values = uv, restoration = NULL)
  expect_true(r2$ok)
  expect_null(r2$restoration)                                           # no restoration data: block hidden
})

test_that("format_eur never uses scientific notation and groups with a no-break space", {
  expect_equal(format_eur(88800), "€88\u00a0800")
  expect_equal(format_eur(25840000000), "€25\u00a0840\u00a0000\u00a0000")
  expect_equal(format_eur(1234.6), "€1\u00a0235")
  expect_equal(format_eur(NA), "—")
  expect_equal(format_years(100000 / 4440), "22.5")
  expect_equal(format_years(NA), "—")
})

test_that("export rows carry codes, values and provenance per block", {
  r <- calc(area_ha = 1, services = WP5_VALUATION_SERVICES, horizon = 20, restoration_area = 1,
            discount_rate_pct = 4)
  x <- valuation_export_rows(r)
  expect_true(all(c("section", "item", "low", "high", "value", "unit", "provenance", "source") %in% names(x)))
  expect_true(all(x$provenance[x$section %in% c("annual", "cumulative", "restoration_cost")] == "wp5_source"))
  expect_true(all(x$provenance[x$section %in% c("central", "npv", "survival_adjusted", "break_even")] ==
                    "toolbox_extension"))
  tot <- x[x$section == "annual" & x$item == "total", ]
  expect_equal(c(tot$low, tot$high), c(4440, 25840))
  cum <- x[x$section == "cumulative", ]
  expect_equal(c(cum$low, cum$high), c(88800, 516800))
  expect_equal(sum(x$section == "npv"), 5L)                             # 0, 3, 4 (user), 5, 7
  expect_true(all(x$item[x$section == "annual"] %in% c(WP5_VALUATION_SERVICES, "total")))
})
