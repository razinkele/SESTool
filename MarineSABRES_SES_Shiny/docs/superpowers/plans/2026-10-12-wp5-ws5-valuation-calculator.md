# WP5 WS-5 Valuation Calculator Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A Posidonia oceanica valuation calculator under the Response menu that reproduces D5.2's benefit-transfer figures (annual value per service and undiscounted cumulative value) and, clearly badged as toolbox additions, shows a central midpoint, NPV at 0/3/5/7%, break-even horizon and survival-adjusted restoration cost, with an xlsx export carrying provenance.

**Architecture:** All arithmetic lives in pure functions in `functions/valuation_calculations.R`; one aggregate, `compute_valuation()`, turns raw inputs into a result list (or validation error keys). The module `modules/valuation_calculator_module.R` is a thin Shiny layer: inputs → `compute_valuation()` → rendered tables → export. Unit values and restoration costs are read from the WS-2 mechanism KB (`valuation_unit_values`), whose Table 19 and §4.8 figures this plan verifies against the committed D5.2 extract.

**Tech Stack:** R 4.4.1, Shiny/bs4Dash, testthat 3, openxlsx, jsonlite; Python (micromamba env `shiny`) to regenerate the D5.2 extract.

**Spec:** `docs/superpowers/specs/2026-10-11-wp5-practical-integration-specs.md` §WS-5 (lines 296–326) and Principles P1–P7 (§1); roadmap `docs/superpowers/specs/2026-05-06-wp5-integration-roadmap-design.md` §6.4 (pure functions and edge cases) and §6.5 (UX guardrails); source audit `docs/wp5-source-audit/2026-10-11/A_D5.2_audit.md` §4.

## Global Constraints

- Module signature `valuation_calculator_ui(id, i18n)` / `valuation_calculator_server(id, project_data_reactive, i18n, event_bus = NULL)`; UI starts with `tryCatch(shiny.i18n::usei18n(i18n$translator %||% i18n), error = function(e) NULL)`.
- Location: "under the Response menu (next to `response_measures`)" — a sub-item of the "Response & Validation" sidebar group, tabName `response_valuation`.
- Primary output is `wp5_source`: annual value low–high per service and total, and the cumulative **undiscounted** value over the horizon; at area 1 ha, all five services, 20 years it must equal D5.2's €88,800 (low) and €516,800 (high; D5.2 prose: "over €500,000").
- Secondary output carries the `toolbox_extension` badge (`provenance_badge("toolbox_extension", i18n)`): central midpoint, NPV at 0/3/5/7% **as a table, never a single rate**, break-even horizon against restoration cost, survival-adjusted restoration cost = cost ÷ survival rate (38–60%).
- Disclaimer text (partner gate, Tuscan lead): "Benefit-transfer estimate; not a site valuation".
- Export: one xlsx sheet with inputs, outputs and a provenance column.
- P2: services and methods are stored and exported as codes; labels come from i18n on display.
- P6: every new `functions/*.R` is `source()`d in `global.R` (`test-functions-sourced-in-app.R`); UI chrome in all 9 languages (`en es fr de lt pt it no el`); dynamic keys carry `# i18n-ref:` sentinels.
- P7: `source_for_test()` for module files; re-bind the real server from `.GlobalEnv` before `testServer()`; never end a test in `expect_true(TRUE)`.
- Download handlers follow `test-download-handler-hardening.R`: the content body calls a pure `build_*_excel(..., saver = openxlsx::saveWorkbook)` inside `tryCatch`, the error branch shows a notification and calls `stop(e)`.
- i18n gates: `micromamba run -n shiny python -I scripts/_i18n_audit.py` reports `missing=0` and `hardcoded=0`; `test-i18n-duplicate-keys.R`, `test-i18n-english-fallback.R`, `test-i18n-enforcement.R` pass.
- Release: WS-5 ships with WS-4 in 1.24.0 (spec §2 groups WS-5/6 as 1.24; 1.23.0 is already released without WS-4). CHANGELOG under `[Unreleased]`; do not bump `VERSION`.
- Shell: `git -C <path>`, never `cd <path> && git`. Never stage `WP5/`. Docs need `git add -f`. Python runs as `micromamba run -n shiny python -I …`.

## Design rulings (made at planning time; executor copies each into the ledger as `Plan: Ruling: …`)

1. **One data source.** Unit values and restoration costs come from the WS-2 KB (`get_valuation_unit_values()`, new `get_restoration_costs()`); the calculator never hard-codes €-figures. Task 1 adds the missing source verification: every Table 19 band and the §4.8 restoration figures are checked against the committed D5.2 extract, which is widened to include §4.8 (L3348–3362).
2. **Central is a toolbox addition.** The KB's `central` values are arithmetic midpoints (audit §4). They appear only in the badged secondary block, never in the primary table.
3. **Cumulative = annual × horizon**, undiscounted (D5.2 §4.8 L3359–3361). NPV is computed separately (roadmap §6.4 formula) and shown only in the secondary block, at the four fixed rates plus the user's own rate when given (no duplicate row when the user picks 0, 3, 5 or 7%).
4. **Restoration.** Inputs: restoration area (ha, optional; 0 or blank hides the block) and cost bound (`low` €100,000/ha or `high` €500,000/ha, from D5.2 §4.8). Restoration cost = restoration area × bound. Benefits for break-even are the restored area's annual value (sum of the selected services' unit values × restoration area) at the low and at the high band, giving two horizons. Break-even uses the user's discount rate, or 0% (undiscounted, D5.2's framing) when the rate is blank; the UI states which rate it used. Survival-adjusted cost = cost ÷ 0.60 (low) to cost ÷ 0.38 (high), read from the KB.
5. **Number format.** Euro amounts are rounded to whole euros and grouped with a no-break space (`€88 800`), never in scientific notation. A comma or point separator would read as a decimal mark in half of the 9 languages. Years show one decimal.
6. **Session-only inputs.** Calculator inputs are not stored in the project (the spec does not ask for it, and storing them would need a schema field, a save/load round trip and a `min_app_version` stamp). Follow-up if partners want saved calculations.
7. **Validation.** Area must be a number ≥ 0; horizon a whole number of years, 0–100; discount rate blank or 0–20%; restoration area blank or ≥ 0. Invalid inputs give translated messages and no numbers (no NaN, negatives or "Inf" on screen), and the download button is disabled via `req()`.
8. **Habitat.** One habitat (Posidonia oceanica), as in roadmap §6.5; the habitat is shown as fixed text, not a picker.

## Review Focus

1. **Area left blank, negative or not a number.** Expected: a translated validation message, no numbers, no `NaN`/`-€…`, and no file served by the download button. (Task 2 "invalid inputs return error keys and no numbers"; Task 3 testServer "invalid area shows the message and computes nothing".)
2. **All services unticked.** Expected: totals of €0, a translated "select at least one service" note, break-even "does not break even" rather than an error. (Task 2 "no services gives zero totals and a warning"; Task 3 testServer.)
3. **Discount rate left blank or set to 3%.** Expected: the NPV table always lists 0/3/5/7%; a 3% entry marks the existing row instead of adding a duplicate; break-even falls back to 0% and says so. (Task 2 "user rate is marked, not duplicated" and "break-even falls back to 0% when the rate is blank".)
4. **Restoration cost larger than the discounted value of benefits for ever.** Expected: "does not break even", not negative or `NaN` years. (Task 2 roadmap edge case "restoration cost above the discounted perpetuity never breaks even".)
5. **Mechanism KB missing or without a valuation block.** Expected: the page shows "valuation data not available" and does not crash. (Task 2 "missing unit values give data_unavailable"; Task 3 testServer "unavailable data shows the message".)
6. **Very large area (1,000,000 ha).** Expected: full grouped numbers, never `1e+10`. (Task 2 "format_eur never uses scientific notation".)

---

## File Structure

| Path | Responsibility |
|---|---|
| `scripts/build_wp5_indicator_sources.py` (modify) | Widen the Posidonia range to `(3112, 3372)` so §4.8 (restoration cost, survival, 20-year figure) is in the extract. |
| `scripts/wp5_kb_sources/d5.2_v5_indicator_sources.md` (regenerate) | Committed extract the source tests read. |
| `functions/wp5_kb_loader.R` (modify) | New `get_restoration_costs(habitat)`. |
| `constants.R` (modify) | `WP5_VALUATION_HABITAT`, `WP5_VALUATION_SERVICES`, `WP5_VALUATION_DISCOUNT_RATES`, `WP5_DEFAULT_TIME_HORIZON`, `WP5_VALUATION_MAX_HORIZON`, `WP5_VALUATION_MAX_RATE_PCT`. |
| `functions/valuation_calculations.R` (create) | Pure arithmetic, validation, the `compute_valuation()` aggregate, number formatting, export rows. |
| `global.R` (modify) | Source `functions/valuation_calculations.R` after `functions/wp5_kb_loader.R`. |
| `modules/valuation_calculator_module.R` (create) | UI, server, help modal, xlsx download (`build_valuation_excel()`). |
| `app.R` (modify) | Load the module (OPTIONAL_MODULES), tab item, server call. |
| `functions/ui_sidebar.R` (modify) | Sidebar sub-item under "Response & Validation". |
| `translations/modules/valuation_calculator.json` (create) | Module chrome, 9 languages. |
| `translations/ui/sidebar.json` (modify) | `ui.sidebar.valuation_calculator`. |
| `tests/testthat/test-valuation-calculations.R` (create) | Source checks, pure functions, aggregate, formatting, export rows. |
| `tests/testthat/test-valuation-calculator-module.R` (create) | Signature contract, testServer behaviour, export builder, i18n key coverage. |
| `CHANGELOG.md` (modify) | `[Unreleased]` entry. |

---

### Task 1: Verify the valuation figures against D5.2 and expose restoration costs

**Files:**
- Modify: `scripts/build_wp5_indicator_sources.py` (RANGES), `scripts/wp5_kb_sources/d5.2_v5_indicator_sources.md` (regenerated), `functions/wp5_kb_loader.R`, `constants.R` (append after the WS-4 block)
- Test: `tests/testthat/test-valuation-calculations.R` (create)

**Interfaces:**
- Consumes: `load_wp5_mechanisms_kb()`, `get_valuation_unit_values(habitat)` (existing), the extract format `L<n>: <text>`.
- Produces: `get_restoration_costs(habitat)` → list(`low`, `high`, `unit`, `early_survival_low`, `early_survival_high`) or `NULL`; constants `WP5_VALUATION_HABITAT <- "posidonia_oceanica"`, `WP5_VALUATION_SERVICES <- c("coastal_protection", "carbon_sequestration", "recreation_tourism", "food_provision", "water_purification")`, `WP5_VALUATION_DISCOUNT_RATES <- c(0, 0.03, 0.05, 0.07)`, `WP5_DEFAULT_TIME_HORIZON <- 20L`, `WP5_VALUATION_MAX_HORIZON <- 100L`, `WP5_VALUATION_MAX_RATE_PCT <- 20`.

- [ ] **Step 1: Write the failing tests**

`tests/testthat/test-valuation-calculations.R`:

```r
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
```

- [ ] **Step 2: Run to see it fail**

Run (from the app dir): `"/c/Program Files/R/R-4.4.1/bin/Rscript.exe" -e "testthat::test_file('tests/testthat/test-valuation-calculations.R')"`
Expected: errors — `WP5_VALUATION_HABITAT` not found, `could not find function "get_restoration_costs"`, and the §4.8 test's `extract lacks 3348 - 3362` failure.

- [ ] **Step 3: Widen the extract**

In `scripts/build_wp5_indicator_sources.py`, replace the RANGES line
`    (3112, 3330, "Tuscan: Tables 17 and 18 (Posidonia indicators)"),`
with
`    (3112, 3372, "Tuscan: Tables 17-19 (Posidonia indicators and valuation) and §4.8 restoration costs"),`
and regenerate:
`micromamba run -n shiny python -I scripts/build_wp5_indicator_sources.py --wp5-dir "C:/Users/arturas.baziukas/OneDrive - ku.lt/HORIZON_EUROPE/Marine-SABRES/SESToolbox/MarineSABRES_SES_Shiny/WP5"`
Expected: `ok … sha256 ab42fffd…` (same pinned hash). Check `grep -n "88,800" scripts/wp5_kb_sources/d5.2_v5_indicator_sources.md` shows a line starting `L3360:`.

- [ ] **Step 4: Add the constants and the getter**

Append to `constants.R` after the WS-4 block (before `END OF CONSTANTS`):

```r
# ============================================================================
# WP5 VALUATION CALCULATOR (spec 2026-10-11 WS-5)
# ============================================================================
# Benefit-transfer unit values and restoration costs come from the WS-2 KB
# (valuation_unit_values); these constants only fix order, defaults and limits.
WP5_VALUATION_HABITAT <- "posidonia_oceanica"
WP5_VALUATION_SERVICES <- c("coastal_protection", "carbon_sequestration", "recreation_tourism",
                            "food_provision", "water_purification")
# NPV sensitivity table (roadmap §6.5: never a single rate). A toolbox addition;
# D5.2 publishes no discount rate or NPV.
WP5_VALUATION_DISCOUNT_RATES <- c(0, 0.03, 0.05, 0.07)
WP5_DEFAULT_TIME_HORIZON <- 20L      # D5.2 §4.8: "a 20-year lifespan for restored meadows"
WP5_VALUATION_MAX_HORIZON <- 100L
WP5_VALUATION_MAX_RATE_PCT <- 20
```

Add to `functions/wp5_kb_loader.R`, directly after `get_valuation_unit_values()`:

```r
#' Restoration cost bounds and early survival for a habitat (D5.2 §4.8)
#'
#' @param habitat Character habitat key (e.g., "posidonia_oceanica")
#' @return list(low, high, unit, early_survival_low, early_survival_high), or NULL
#' @export
get_restoration_costs <- function(habitat) {
  if (!wp5_kb_available()) return(NULL)
  .wp5_kb_env$db$valuation_unit_values$restoration_costs[[habitat]]
}
```

- [ ] **Step 5: Run the tests, plus the WS-4 registry test that reads the same extract**

Run: `"/c/Program Files/R/R-4.4.1/bin/Rscript.exe" -e "for (f in c('test-valuation-calculations','test-indicator-registry','test-functions-sourced-in-app')) testthat::test_file(file.path('tests/testthat', paste0(f, '.R')))"`
Expected: all `[ FAIL 0 | … ]`. A quote failure means the KB disagrees with D5.2: stop and report it; do not edit the test.

- [ ] **Step 6: Commit**

```bash
git -C /c/Users/arturas.baziukas/wt-ws5 add MarineSABRES_SES_Shiny/scripts/build_wp5_indicator_sources.py MarineSABRES_SES_Shiny/scripts/wp5_kb_sources/d5.2_v5_indicator_sources.md MarineSABRES_SES_Shiny/functions/wp5_kb_loader.R MarineSABRES_SES_Shiny/constants.R MarineSABRES_SES_Shiny/tests/testthat/test-valuation-calculations.R
git -C /c/Users/arturas.baziukas/wt-ws5 commit -m "feat(wp5): verify valuation figures against D5.2 and expose restoration costs (WS-5)"
```

---

### Task 2: Pure valuation functions and the `compute_valuation()` aggregate

**Files:**
- Create: `functions/valuation_calculations.R`
- Modify: `global.R` (source after `functions/wp5_kb_loader.R`)
- Test: `tests/testthat/test-valuation-calculations.R` (append)

**Interfaces:**
- Consumes: Task 1 constants, `get_valuation_unit_values()`, `get_restoration_costs()`.
- Produces:
  - `calculate_annual_value(area_ha, unit_values)` → list(`low`, `central`, `high`)
  - `calculate_npv(annual_value, horizon_years, discount_rate)` → numeric
  - `calculate_break_even_horizon(annual_value, restoration_cost, discount_rate)` → numeric years or `NA_real_`
  - `survival_adjusted_cost(cost, survival_low, survival_high)` → c(`low` = cost / survival_high, `high` = cost / survival_low)
  - `valuation_unit_table(unit_values)` → data.frame(`service, method, unit, low, central, high`) in `WP5_VALUATION_SERVICES` order
  - `validate_valuation_inputs(area_ha, horizon, discount_rate_pct, restoration_area)` → character vector of error codes ⊆ `c("invalid_area", "invalid_horizon", "invalid_rate", "invalid_restoration_area")`
  - `compute_valuation(area_ha, services, horizon, discount_rate_pct = NA, restoration_area = NA, cost_bound = "low", unit_values = get_valuation_unit_values(WP5_VALUATION_HABITAT), restoration = get_restoration_costs(WP5_VALUATION_HABITAT))` → on error `list(ok = FALSE, errors = <codes>)`; else `list(ok = TRUE, errors = character(0), warnings, per_service (df: service, method, annual_low, annual_central, annual_high), total (named low/central/high), horizon, cumulative (named low/central/high), user_rate (NA or fraction), npv (df: rate, low, central, high, user), restoration (NULL or list: area, cost_bound, cost_per_ha, cost, survival_adjusted (named low/high), rate, rate_is_fallback, benefit_low, benefit_high, break_even_low, break_even_high))`
  - `format_eur(x)` → "€88 800" (no-break space, whole euros, "—" for NA); `format_years(x)` → "22.5"
  - `valuation_export_rows(result)` → data.frame(`section, item, low, high, value, unit, provenance, source`) with codes, not labels

- [ ] **Step 1: Append the failing tests**

```r
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
  expect_equal(x$break_even_low, 200000 / (2 * 4440))                     # slowest: low band
  expect_equal(x$break_even_high, 200000 / (2 * 25840))
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
```

- [ ] **Step 2: Run to see it fail**

Run: `"/c/Program Files/R/R-4.4.1/bin/Rscript.exe" -e "testthat::test_file('tests/testthat/test-valuation-calculations.R')"`
Expected: `could not find function "compute_valuation"` (and the other new functions); `source_for_test()` skips the missing file silently.

- [ ] **Step 3: Implement `functions/valuation_calculations.R`**

```r
# functions/valuation_calculations.R
# WS-5 valuation calculator: pure arithmetic over the D5.2 Table 19
# benefit-transfer unit values (read from the WS-2 KB). No Shiny here.
#
# Provenance (spec P1): annual values and the undiscounted cumulative value are
# D5.2 methods (wp5_source). The central midpoint, NPV, break-even horizon and
# survival-adjusted cost are toolbox additions (toolbox_extension).

calculate_annual_value <- function(area_ha, unit_values) {
  list(low = area_ha * unit_values$low,
       central = area_ha * unit_values$central,
       high = area_ha * unit_values$high)
}

calculate_npv <- function(annual_value, horizon_years, discount_rate) {
  if (discount_rate == 0) return(annual_value * horizon_years)
  annual_value * (1 - (1 + discount_rate)^-horizon_years) / discount_rate
}

calculate_break_even_horizon <- function(annual_value, restoration_cost, discount_rate) {
  if (is.na(annual_value) || annual_value <= 0) return(NA_real_)
  if (discount_rate == 0) return(restoration_cost / annual_value)
  ratio <- 1 - (restoration_cost * discount_rate / annual_value)
  if (ratio <= 0) return(NA_real_)          # cost exceeds the discounted value of benefits for ever
  -log(ratio) / log(1 + discount_rate)
}

#' Cost per surviving hectare: low = cost / best survival, high = cost / worst survival
survival_adjusted_cost <- function(cost, survival_low, survival_high) {
  c(low = cost / survival_high, high = cost / survival_low)
}

#' KB unit values as a data frame in WP5_VALUATION_SERVICES order.
#' central falls back to the midpoint when the KB omits it.
valuation_unit_table <- function(unit_values) {
  svc <- intersect(WP5_VALUATION_SERVICES, names(unit_values))
  num <- function(s, f) as.numeric(unit_values[[s]][[f]] %||% NA_real_)
  low <- vapply(svc, num, numeric(1), f = "low")
  high <- vapply(svc, num, numeric(1), f = "high")
  central <- vapply(svc, num, numeric(1), f = "central")
  central[is.na(central)] <- (low[is.na(central)] + high[is.na(central)]) / 2
  data.frame(service = svc,
             method = vapply(svc, function(s) as.character(unit_values[[s]]$method %||% ""), character(1)),
             unit = vapply(svc, function(s) as.character(unit_values[[s]]$unit %||% "EUR/ha/yr"), character(1)),
             low = unname(low), central = unname(central), high = unname(high),
             stringsAsFactors = FALSE, row.names = NULL)
}

.is_number <- function(x) is.numeric(x) && length(x) == 1 && !is.na(x) && is.finite(x)
.is_blank <- function(x) is.null(x) || length(x) == 0 || (length(x) == 1 && is.na(x))

validate_valuation_inputs <- function(area_ha, horizon, discount_rate_pct, restoration_area) {
  e <- character(0)
  if (!.is_number(area_ha) || area_ha < 0) e <- c(e, "invalid_area")
  if (!.is_number(horizon) || horizon < 0 || horizon > WP5_VALUATION_MAX_HORIZON || horizon != round(horizon))
    e <- c(e, "invalid_horizon")
  if (!.is_blank(discount_rate_pct) &&
      (!.is_number(discount_rate_pct) || discount_rate_pct < 0 || discount_rate_pct > WP5_VALUATION_MAX_RATE_PCT))
    e <- c(e, "invalid_rate")
  if (!.is_blank(restoration_area) && (!.is_number(restoration_area) || restoration_area < 0))
    e <- c(e, "invalid_restoration_area")
  e
}

compute_valuation <- function(area_ha, services, horizon, discount_rate_pct = NA,
                              restoration_area = NA, cost_bound = "low",
                              unit_values = get_valuation_unit_values(WP5_VALUATION_HABITAT),
                              restoration = get_restoration_costs(WP5_VALUATION_HABITAT)) {
  errors <- validate_valuation_inputs(area_ha, horizon, discount_rate_pct, restoration_area)
  if (is.null(unit_values) || length(unit_values) == 0) errors <- c(errors, "data_unavailable")
  if (length(errors) > 0) return(list(ok = FALSE, errors = unique(errors)))

  tab <- valuation_unit_table(unit_values)
  tab <- tab[tab$service %in% as.character(services %||% character(0)), , drop = FALSE]
  per_service <- data.frame(service = tab$service, method = tab$method,
                            annual_low = area_ha * tab$low, annual_central = area_ha * tab$central,
                            annual_high = area_ha * tab$high, stringsAsFactors = FALSE)
  total <- c(low = sum(per_service$annual_low), central = sum(per_service$annual_central),
             high = sum(per_service$annual_high))
  cumulative <- total * horizon

  user_rate <- if (.is_blank(discount_rate_pct)) NA_real_ else discount_rate_pct / 100
  rates <- sort(unique(round(c(WP5_VALUATION_DISCOUNT_RATES, if (!is.na(user_rate)) user_rate), 10)))
  npv <- data.frame(
    rate = rates,
    low = vapply(rates, function(r) calculate_npv(total[["low"]], horizon, r), numeric(1)),
    central = vapply(rates, function(r) calculate_npv(total[["central"]], horizon, r), numeric(1)),
    high = vapply(rates, function(r) calculate_npv(total[["high"]], horizon, r), numeric(1)),
    user = if (is.na(user_rate)) rep(FALSE, length(rates)) else abs(rates - user_rate) < 1e-9)

  rest <- NULL
  if (!.is_blank(restoration_area) && restoration_area > 0 && !is.null(restoration)) {
    bound <- if (identical(cost_bound, "high")) "high" else "low"
    per_ha <- as.numeric(restoration[[bound]])
    cost <- restoration_area * per_ha
    rate <- if (is.na(user_rate)) 0 else user_rate
    benefit_low <- restoration_area * sum(tab$low)
    benefit_high <- restoration_area * sum(tab$high)
    rest <- list(area = restoration_area, cost_bound = bound, cost_per_ha = per_ha, cost = cost,
                 survival_adjusted = survival_adjusted_cost(cost, as.numeric(restoration$early_survival_low),
                                                            as.numeric(restoration$early_survival_high)),
                 rate = rate, rate_is_fallback = is.na(user_rate),
                 benefit_low = benefit_low, benefit_high = benefit_high,
                 break_even_low = calculate_break_even_horizon(benefit_low, cost, rate),
                 break_even_high = calculate_break_even_horizon(benefit_high, cost, rate))
  }

  list(ok = TRUE, errors = character(0),
       warnings = if (nrow(tab) == 0) "no_services" else character(0),
       per_service = per_service, total = total, horizon = horizon, cumulative = cumulative,
       user_rate = user_rate, npv = npv, restoration = rest)
}

#' "€88 800": whole euros, grouped with a no-break space (unambiguous in all 9
#' languages; a comma or point reads as a decimal mark in half of them).
format_eur <- function(x) {
  vapply(x, function(v) {
    if (is.null(v) || is.na(v)) return("—")
    paste0("€", format(round(v), big.mark = "\u00a0", scientific = FALSE, trim = TRUE))
  }, character(1), USE.NAMES = FALSE)
}

format_years <- function(x) {
  vapply(x, function(v) if (is.na(v)) "—" else formatC(v, format = "f", digits = 1), character(1),
         USE.NAMES = FALSE)
}

#' Long-format rows for the xlsx export: codes (not labels), values, provenance.
valuation_export_rows <- function(result) {
  if (!isTRUE(result$ok)) return(data.frame())
  row <- function(section, item, low = NA_real_, high = NA_real_, value = NA_real_, unit, provenance, source)
    data.frame(section = section, item = item, low = low, high = high, value = value, unit = unit,
               provenance = provenance, source = source, stringsAsFactors = FALSE)
  t19 <- "D5.2 v5 Table 19"
  s48 <- "D5.2 v5 §4.8"
  ps <- result$per_service
  out <- list()
  for (i in seq_len(nrow(ps)))
    out[[length(out) + 1]] <- row("annual", ps$service[i], ps$annual_low[i], ps$annual_high[i],
                                  unit = "EUR/yr", provenance = "wp5_source", source = t19)
  out[[length(out) + 1]] <- row("annual", "total", result$total[["low"]], result$total[["high"]],
                                unit = "EUR/yr", provenance = "wp5_source", source = t19)
  out[[length(out) + 1]] <- row("cumulative", paste0("undiscounted_", result$horizon, "y"),
                                result$cumulative[["low"]], result$cumulative[["high"]],
                                unit = "EUR", provenance = "wp5_source", source = paste(s48, "(annual x years)"))
  out[[length(out) + 1]] <- row("central", "annual_total", value = result$total[["central"]],
                                unit = "EUR/yr", provenance = "toolbox_extension", source = "midpoint of low/high")
  out[[length(out) + 1]] <- row("central", paste0("cumulative_", result$horizon, "y"),
                                value = result$cumulative[["central"]], unit = "EUR",
                                provenance = "toolbox_extension", source = "midpoint of low/high")
  for (i in seq_len(nrow(result$npv)))
    out[[length(out) + 1]] <- row("npv", sprintf("rate_%g%%%s", 100 * result$npv$rate[i],
                                                 if (result$npv$user[i]) "_user" else ""),
                                  result$npv$low[i], result$npv$high[i], result$npv$central[i],
                                  unit = "EUR", provenance = "toolbox_extension",
                                  source = "annuity formula (not in D5.2)")
  r <- result$restoration
  if (!is.null(r)) {
    out[[length(out) + 1]] <- row("restoration_cost", paste0("bound_", r$cost_bound), value = r$cost,
                                  unit = "EUR", provenance = "wp5_source",
                                  source = paste(s48, "(REE 2022; Bayraktarov et al. 2016)"))
    out[[length(out) + 1]] <- row("survival_adjusted", "cost_per_surviving_area",
                                  r$survival_adjusted[["low"]], r$survival_adjusted[["high"]],
                                  unit = "EUR", provenance = "toolbox_extension",
                                  source = paste(s48, "survival 38-60%; cost / survival"))
    out[[length(out) + 1]] <- row("break_even", sprintf("years_at_%g%%", 100 * r$rate),
                                  r$break_even_low, r$break_even_high, unit = "years",
                                  provenance = "toolbox_extension", source = "annuity formula (not in D5.2)")
  }
  do.call(rbind, out)
}
```

Add to `global.R` directly after the `source(...)` line for `functions/wp5_kb_loader.R` (find it with `grep -n "wp5_kb_loader" global.R`; keep the same call form that line uses):

```r
source("functions/valuation_calculations.R", local = FALSE)
```

- [ ] **Step 4: Run the tests**

Run: `"/c/Program Files/R/R-4.4.1/bin/Rscript.exe" -e "for (f in c('test-valuation-calculations','test-functions-sourced-in-app')) testthat::test_file(file.path('tests/testthat', paste0(f, '.R')))"`
Expected: both `[ FAIL 0 | … ]`.

- [ ] **Step 5: Commit**

```bash
git -C /c/Users/arturas.baziukas/wt-ws5 add MarineSABRES_SES_Shiny/functions/valuation_calculations.R MarineSABRES_SES_Shiny/global.R MarineSABRES_SES_Shiny/tests/testthat/test-valuation-calculations.R
git -C /c/Users/arturas.baziukas/wt-ws5 commit -m "feat(wp5): valuation calculations: D5.2 annual and cumulative values, NPV table, break-even, survival-adjusted cost (WS-5)"
```

---

### Task 3: The calculator module, menu wiring and xlsx export

**Files:**
- Create: `modules/valuation_calculator_module.R`
- Modify: `app.R` (OPTIONAL_MODULES list, tab items next to `response_measures`, server calls next to `response_measures_server`), `functions/ui_sidebar.R` (Response & Validation group)
- Test: `tests/testthat/test-valuation-calculator-module.R` (create)

**Interfaces:**
- Consumes: Task 2 `compute_valuation()`, `format_eur()`, `format_years()`, `valuation_export_rows()`; `provenance_badge()` (`functions/ui_components.R`), `create_module_header()`, `create_help_observer()` (`functions/ui_helpers.R`), `generate_export_filename()`.
- Produces: `valuation_calculator_ui(id, i18n)`, `valuation_calculator_server(id, project_data_reactive, i18n, event_bus = NULL)` (inside: reactive `valuation()` returning the `compute_valuation()` result), `build_valuation_excel(result, inputs, file, saver = openxlsx::saveWorkbook)`; tabName `response_valuation`; module id `"valuation_calc"`.

- [ ] **Step 1: Write the failing tests**

`tests/testthat/test-valuation-calculator-module.R`:

```r
# tests/testthat/test-valuation-calculator-module.R
# WS-5: valuation calculator module — signature, behaviour (real server), export.
library(testthat)
library(shiny)
load_wp5_mechanisms_kb(file.path(PROJECT_ROOT, "data", "ses_knowledge_db_wp5_mechanisms.json"),
                       force_reload = TRUE)
source_for_test(c("functions/valuation_calculations.R", "functions/ui_components.R",
                  "modules/valuation_calculator_module.R"))
# helper-stubs.R may shadow module functions in the helper env; use the real ones (P7).
valuation_calculator_server <- get("valuation_calculator_server", envir = .GlobalEnv)
valuation_calculator_ui <- get("valuation_calculator_ui", envir = .GlobalEnv)

test_that("UI returns namespaced tags with the inputs, disclaimer and download button", {
  ui <- as.character(valuation_calculator_ui("vc", make_test_i18n()))
  for (id in c("vc-area_ha", "vc-services", "vc-horizon", "vc-discount_rate", "vc-restoration_area",
               "vc-cost_bound", "vc-download_xlsx", "vc-results"))
    expect_match(ui, id, fixed = TRUE)
  expect_match(ui, "modules.valuation_calculator.disclaimer", fixed = TRUE)
})

test_that("server has the conventional signature", {
  expect_equal(names(formals(valuation_calculator_server)),
               c("id", "project_data_reactive", "i18n", "event_bus"))
  expect_null(formals(valuation_calculator_server)$event_bus)
})

srv_args <- list(project_data_reactive = shiny::reactiveVal(list()), i18n = make_test_i18n(), event_bus = NULL)
set_defaults <- function(session, ...) {
  vals <- utils::modifyList(list(area_ha = 1, services = WP5_VALUATION_SERVICES, horizon = 20,
                                 discount_rate = NA, restoration_area = NA, cost_bound = "low"), list(...))
  do.call(session$setInputs, vals)
}

test_that("changing the area updates the total and the rendered results", {
  testServer(valuation_calculator_server, args = srv_args, {
    set_defaults(session)
    expect_equal(unname(valuation()$total[c("low", "high")]), c(4440, 25840))
    expect_match(as.character(output$results$html), "€88\u00a0800", fixed = TRUE)
    session$setInputs(area_ha = 2)
    expect_equal(unname(valuation()$total[c("low", "high")]), c(8880, 51680))
    expect_match(as.character(output$results$html), "€177\u00a0600", fixed = TRUE)
  })
})

test_that("the secondary block carries the toolbox_extension badge and the NPV table", {
  testServer(valuation_calculator_server, args = srv_args, {
    set_defaults(session, discount_rate = 4, restoration_area = 1)
    html <- as.character(output$results$html)
    expect_match(html, "modules.wp5_mechanisms.provenance.toolbox_extension", fixed = TRUE)
    for (p in c("0%", "3%", "4%", "5%", "7%")) expect_match(html, p, fixed = TRUE)
    expect_match(html, "modules.valuation_calculator.break_even_heading", fixed = TRUE)
  })
})

test_that("invalid area shows the message and computes nothing", {
  testServer(valuation_calculator_server, args = srv_args, {
    set_defaults(session, area_ha = -3)
    expect_false(valuation()$ok)
    html <- as.character(output$results$html)
    expect_match(html, "modules.valuation_calculator.error.invalid_area", fixed = TRUE)
    expect_false(grepl("€", html, fixed = TRUE))
  })
})

test_that("no services ticked shows the warning and zero totals", {
  testServer(valuation_calculator_server, args = srv_args, {
    set_defaults(session, services = character(0))
    expect_equal(unname(valuation()$total), c(0, 0, 0))
    expect_match(as.character(output$results$html), "modules.valuation_calculator.warn.no_services", fixed = TRUE)
  })
})

test_that("unavailable data shows the message instead of crashing", {
  old <- .wp5_kb_env$db; on.exit({ .wp5_kb_env$db <- old; .wp5_kb_env$loaded <- TRUE })
  .wp5_kb_env$db <- NULL; .wp5_kb_env$loaded <- FALSE
  testServer(valuation_calculator_server, args = srv_args, {
    set_defaults(session)
    expect_match(as.character(output$results$html), "modules.valuation_calculator.error.data_unavailable",
                 fixed = TRUE)
  })
})

test_that("build_valuation_excel writes one sheet with inputs, outputs and provenance", {
  r <- compute_valuation(area_ha = 1, services = WP5_VALUATION_SERVICES, horizon = 20, restoration_area = 1)
  f <- tempfile(fileext = ".xlsx")
  build_valuation_excel(r, data.frame(parameter = "area_ha", value = "1"), f)
  expect_true(file.exists(f))
  expect_equal(openxlsx::getSheetNames(f), "Valuation")
  x <- openxlsx::read.xlsx(f, colNames = FALSE)
  flat <- unlist(x)
  expect_true("provenance" %in% flat)
  expect_true("area_ha" %in% flat)
  expect_true("wp5_source" %in% flat && "toolbox_extension" %in% flat)
})

test_that("a forced saver failure propagates and leaves no file", {
  r <- compute_valuation(area_ha = 1, services = WP5_VALUATION_SERVICES, horizon = 20)
  f <- tempfile(fileext = ".xlsx")
  expect_error(build_valuation_excel(r, data.frame(parameter = "area_ha", value = "1"), f,
                                     saver = function(...) stop("disk full")), "disk full")
  expect_false(file.exists(f))
})

test_that("the download handler wraps the builder in tryCatch and stops on error (hardening pattern)", {
  s <- paste(readLines(file.path(PROJECT_ROOT, "modules", "valuation_calculator_module.R"), warn = FALSE),
             collapse = "\n")
  expect_match(s, "build_valuation_excel(", fixed = TRUE)
  expect_match(s, "stop(e)", fixed = TRUE)
  expect_match(s, "common.messages.excel_export_failed", fixed = TRUE)
})

test_that("the app wires the module under the Response menu", {
  app <- paste(readLines(file.path(PROJECT_ROOT, "app.R"), warn = FALSE), collapse = "\n")
  expect_match(app, "modules/valuation_calculator_module.R", fixed = TRUE)
  expect_match(app, 'bs4TabItem(tabName = "response_valuation", valuation_calculator_ui("valuation_calc", i18n))',
               fixed = TRUE)
  expect_match(app, 'valuation_calculator_server("valuation_calc", project_data, session_i18n)', fixed = TRUE)
  sb <- paste(readLines(file.path(PROJECT_ROOT, "functions", "ui_sidebar.R"), warn = FALSE), collapse = "\n")
  expect_match(sb, 'tabName = "response_valuation"', fixed = TRUE)
})
```

- [ ] **Step 2: Run to see it fail**

Run: `"/c/Program Files/R/R-4.4.1/bin/Rscript.exe" -e "testthat::test_file('tests/testthat/test-valuation-calculator-module.R')"`
Expected: an error at `get("valuation_calculator_server", envir = .GlobalEnv)` (object not found), because the module file does not exist yet.

- [ ] **Step 3: Implement `modules/valuation_calculator_module.R`**

```r
# modules/valuation_calculator_module.R
# WS-5 valuation calculator (spec 2026-10-11 WS-5): Posidonia oceanica
# benefit-transfer values from D5.2 Table 19, with toolbox additions (central
# midpoint, NPV table, break-even, survival-adjusted cost) badged separately.
# Arithmetic lives in functions/valuation_calculations.R.

valuation_calculator_ui <- function(id, i18n) {
  tryCatch(shiny.i18n::usei18n(i18n$translator %||% i18n), error = function(e) NULL)
  ns <- NS(id)
  # i18n-ref: modules.valuation_calculator.service.coastal_protection
  # i18n-ref: modules.valuation_calculator.service.carbon_sequestration
  # i18n-ref: modules.valuation_calculator.service.recreation_tourism
  # i18n-ref: modules.valuation_calculator.service.food_provision
  # i18n-ref: modules.valuation_calculator.service.water_purification
  service_choices <- stats::setNames(WP5_VALUATION_SERVICES,
                                     vapply(WP5_VALUATION_SERVICES, function(s) i18n$t(paste0("modules.valuation_calculator.service.", s)),
                                            character(1)))
  tagList(
    fluidRow(column(12,
      create_module_header(ns, "modules.valuation_calculator.title", "modules.valuation_calculator.subtitle",
                           "help_valuation", i18n),
      div(class = "alert alert-warning py-2", icon("info-circle"), " ", i18n$t("modules.valuation_calculator.disclaimer"))
    )),
    fluidRow(
      column(4, wellPanel(
        p(strong(i18n$t("modules.valuation_calculator.habitat_label")), " ", i18n$t("modules.valuation_calculator.habitat_posidonia")),
        numericInput(ns("area_ha"), i18n$t("modules.valuation_calculator.area_label"), value = 1, min = 0, step = 0.1),
        checkboxGroupInput(ns("services"), i18n$t("modules.valuation_calculator.services_label"), choices = service_choices,
                           selected = WP5_VALUATION_SERVICES),
        numericInput(ns("horizon"), i18n$t("modules.valuation_calculator.horizon_label"), value = WP5_DEFAULT_TIME_HORIZON, min = 0,
                     max = WP5_VALUATION_MAX_HORIZON, step = 1),
        numericInput(ns("discount_rate"), i18n$t("modules.valuation_calculator.discount_rate_label"), value = NA, min = 0,
                     max = WP5_VALUATION_MAX_RATE_PCT, step = 0.5),
        tags$small(class = "text-muted", i18n$t("modules.valuation_calculator.discount_rate_help")),
        hr(),
        h5(i18n$t("modules.valuation_calculator.restoration_heading")),
        numericInput(ns("restoration_area"), i18n$t("modules.valuation_calculator.restoration_area_label"), value = NA, min = 0, step = 0.1),
        radioButtons(ns("cost_bound"), i18n$t("modules.valuation_calculator.cost_bound_label"),
                     choices = stats::setNames(c("low", "high"), c(i18n$t("modules.valuation_calculator.cost_bound_low"), i18n$t("modules.valuation_calculator.cost_bound_high"))),
                     selected = "low"),
        hr(),
        downloadButton(ns("download_xlsx"), i18n$t("modules.valuation_calculator.download_xlsx"))
      )),
      column(8, uiOutput(ns("results")))
    )
  )
}

valuation_calculator_server <- function(id, project_data_reactive, i18n, event_bus = NULL) {
  moduleServer(id, function(input, output, session) {
    # Formatted strings; keys listed as sentinels so the i18n audit sees them.
    # i18n-ref: modules.valuation_calculator.cumulative_label
    # i18n-ref: modules.valuation_calculator.central_cumulative
    # i18n-ref: modules.valuation_calculator.years_value
    # i18n-ref: modules.valuation_calculator.break_even_rate_note
    tfmt <- function(key, ...) {
      fmt <- i18n$t(key)
      if (grepl("%1$", fmt, fixed = TRUE)) tryCatch(sprintf(fmt, ...), error = function(e) fmt) else fmt
    }
    pct <- function(r) paste0(formatC(100 * r, format = "fg", digits = 3), "%")

    valuation <- reactive({
      compute_valuation(area_ha = input$area_ha, services = input$services, horizon = input$horizon,
                        discount_rate_pct = input$discount_rate, restoration_area = input$restoration_area,
                        cost_bound = input$cost_bound %||% "low")
    })

    primary_block <- function(r) {
      ps <- r$per_service
      # i18n-ref: modules.valuation_calculator.method.avoided_cost
      # i18n-ref: modules.valuation_calculator.method.social_cost_of_carbon
      # i18n-ref: modules.valuation_calculator.method.travel_cost_or_WTP
      # i18n-ref: modules.valuation_calculator.method.market_pricing
      # i18n-ref: modules.valuation_calculator.method.replacement_cost
      rows <- lapply(seq_len(nrow(ps)), function(i) tags$tr(
        tags$td(i18n$t(paste0("modules.valuation_calculator.service.", ps$service[i]))), tags$td(i18n$t(paste0("modules.valuation_calculator.method.", ps$method[i]))),
        tags$td(format_eur(ps$annual_low[i])), tags$td(format_eur(ps$annual_high[i]))))
      tagList(
        h4(i18n$t("modules.valuation_calculator.primary_heading")),
        tags$table(class = "table table-sm",
          tags$thead(tags$tr(tags$th(i18n$t("modules.valuation_calculator.col_service")), tags$th(i18n$t("modules.valuation_calculator.col_method")),
                             tags$th(i18n$t("modules.valuation_calculator.col_annual_low")), tags$th(i18n$t("modules.valuation_calculator.col_annual_high")))),
          tags$tbody(rows,
            tags$tr(class = "fw-bold", tags$td(i18n$t("modules.valuation_calculator.row_total")), tags$td(""),
                    tags$td(format_eur(r$total[["low"]])), tags$td(format_eur(r$total[["high"]]))),
            tags$tr(class = "fw-bold", tags$td(tfmt("modules.valuation_calculator.cumulative_label", as.integer(r$horizon))), tags$td(""),
                    tags$td(format_eur(r$cumulative[["low"]])), tags$td(format_eur(r$cumulative[["high"]]))))),
        tags$small(class = "text-muted", i18n$t("modules.valuation_calculator.source_note")))
    }

    secondary_block <- function(r) {
      npv_rows <- lapply(seq_len(nrow(r$npv)), function(i) tags$tr(
        class = if (r$npv$user[i]) "table-info" else NULL,
        tags$td(pct(r$npv$rate[i]), if (r$npv$user[i]) tags$em(paste0(" (", i18n$t("modules.valuation_calculator.your_rate"), ")"))),
        tags$td(format_eur(r$npv$low[i])), tags$td(format_eur(r$npv$central[i])),
        tags$td(format_eur(r$npv$high[i]))))
      rest <- r$restoration
      rest_ui <- if (!is.null(rest)) {
        yrs <- function(v) if (is.na(v)) i18n$t("modules.valuation_calculator.never_breaks_even") else tfmt("modules.valuation_calculator.years_value", format_years(v))
        tagList(
          h5(i18n$t("modules.valuation_calculator.break_even_heading")),
          tags$table(class = "table table-sm", tags$tbody(
            tags$tr(tags$td(i18n$t("modules.valuation_calculator.restoration_cost")), tags$td(format_eur(rest$cost))),
            tags$tr(tags$td(i18n$t("modules.valuation_calculator.survival_adjusted")),
                    tags$td(paste(format_eur(rest$survival_adjusted[["low"]]), "–",
                                  format_eur(rest$survival_adjusted[["high"]])))),
            tags$tr(tags$td(i18n$t("modules.valuation_calculator.break_even_low")), tags$td(yrs(rest$break_even_low))),
            tags$tr(tags$td(i18n$t("modules.valuation_calculator.break_even_high")), tags$td(yrs(rest$break_even_high))))),
          tags$small(class = "text-muted",
                     if (isTRUE(rest$rate_is_fallback)) i18n$t("modules.valuation_calculator.break_even_rate_fallback")
                     else tfmt("modules.valuation_calculator.break_even_rate_note", pct(rest$rate))))
      }
      tagList(
        h4(i18n$t("modules.valuation_calculator.secondary_heading"), provenance_badge("toolbox_extension", i18n)),
        p(i18n$t("modules.valuation_calculator.secondary_explain")),
        tags$table(class = "table table-sm", tags$tbody(
          tags$tr(tags$td(i18n$t("modules.valuation_calculator.central_annual")), tags$td(format_eur(r$total[["central"]]))),
          tags$tr(tags$td(tfmt("modules.valuation_calculator.central_cumulative", as.integer(r$horizon))),
                  tags$td(format_eur(r$cumulative[["central"]]))))),
        h5(i18n$t("modules.valuation_calculator.npv_heading")),
        tags$table(class = "table table-sm",
          tags$thead(tags$tr(tags$th(i18n$t("modules.valuation_calculator.col_rate")), tags$th(i18n$t("modules.valuation_calculator.col_npv_low")), tags$th(i18n$t("modules.valuation_calculator.col_npv_central")),
                             tags$th(i18n$t("modules.valuation_calculator.col_npv_high")))),
          tags$tbody(npv_rows)),
        rest_ui)
    }

    output$results <- renderUI({
      r <- valuation()
      if (!isTRUE(r$ok)) {
        # i18n-ref: modules.valuation_calculator.error.invalid_area
        # i18n-ref: modules.valuation_calculator.error.invalid_horizon
        # i18n-ref: modules.valuation_calculator.error.invalid_rate
        # i18n-ref: modules.valuation_calculator.error.invalid_restoration_area
        # i18n-ref: modules.valuation_calculator.error.data_unavailable
        return(div(class = "alert alert-danger",
                   tags$ul(lapply(r$errors, function(e) tags$li(i18n$t(paste0("modules.valuation_calculator.error.", e)))))))
      }
      tagList(
        # i18n-ref: modules.valuation_calculator.warn.no_services
        if (length(r$warnings)) div(class = "alert alert-info",
                                     lapply(r$warnings, function(w) p(i18n$t(paste0("modules.valuation_calculator.warn.", w))))),
        primary_block(r), hr(), secondary_block(r))
    })

    output$download_xlsx <- downloadHandler(
      filename = function() generate_export_filename("Valuation_Posidonia", ".xlsx"),
      content = function(file) {
        r <- valuation()
        req(isTRUE(r$ok))
        inputs <- data.frame(
          parameter = c("habitat", "area_ha", "services", "horizon_years", "discount_rate_pct",
                        "restoration_area_ha", "cost_bound"),
          value = c(WP5_VALUATION_HABITAT, as.character(input$area_ha),
                    paste(input$services %||% character(0), collapse = "; "), as.character(input$horizon),
                    if (is.null(input$discount_rate) || is.na(input$discount_rate)) "" else as.character(input$discount_rate),
                    if (is.null(input$restoration_area) || is.na(input$restoration_area)) "" else as.character(input$restoration_area),
                    input$cost_bound %||% "low"),
          stringsAsFactors = FALSE)
        tryCatch({
          build_valuation_excel(r, inputs, file)
        }, error = function(e) {
          debug_log(paste("Valuation Excel export failed:", e$message), "EXPORT")
          showNotification(paste0(i18n$t("common.messages.excel_export_failed"), " (", e$message, ")"),
                           type = "error", duration = NULL)
          stop(e)  # do not serve a partial file
        })
      }
    )

    create_help_observer(input, "help_valuation", "modules.valuation_calculator.help_title",
      tagList(p(i18n$t("modules.valuation_calculator.help_body_1")), p(i18n$t("modules.valuation_calculator.help_body_2")), p(i18n$t("modules.valuation_calculator.help_body_3"))), i18n)

    invisible(valuation)
  })
}

#' One-sheet xlsx: inputs, a blank row, then the long-format outputs with a
#' provenance column. Raises on failure; the caller's tryCatch notifies.
#' @param saver Function(wb, file, overwrite); override in tests to force failures.
build_valuation_excel <- function(result, inputs, file, saver = openxlsx::saveWorkbook) {
  wb <- openxlsx::createWorkbook()
  openxlsx::addWorksheet(wb, "Valuation")
  openxlsx::writeData(wb, "Valuation", inputs, startRow = 1)
  openxlsx::writeData(wb, "Valuation", valuation_export_rows(result), startRow = nrow(inputs) + 3)
  saver(wb, file, overwrite = TRUE)
  invisible(file)
}
```

Note: `create_help_observer()` takes `title_key` and translates it itself; pass the full key as shown.

- [ ] **Step 4: Wire the app and the sidebar**

`app.R`:
1. In `OPTIONAL_MODULES`, after `"modules/response_module.R",` add `  "modules/valuation_calculator_module.R",  # WP5 WS-5 valuation calculator`.
2. After `bs4TabItem(tabName = "response_measures", response_measures_ui("resp_meas", i18n)),` add `      bs4TabItem(tabName = "response_valuation", valuation_calculator_ui("valuation_calc", i18n)),`.
3. After `response_measures_server("resp_meas", project_data, session_i18n)` add `  valuation_calculator_server("valuation_calc", project_data, session_i18n)`.

`functions/ui_sidebar.R`, inside the "Response & Validation" item, after the `response_measures` sub-item add:

```r
        bs4SidebarMenuSubItem(safe_t("ui.sidebar.valuation_calculator", i18n_obj = i18n), tabName = "response_valuation"),
```

- [ ] **Step 5: Run the tests**

Run: `"/c/Program Files/R/R-4.4.1/bin/Rscript.exe" -e "for (f in c('test-valuation-calculator-module','test-valuation-calculations','test-download-handler-hardening','test-functions-sourced-in-app')) testthat::test_file(file.path('tests/testthat', paste0(f, '.R')))"`
Expected: all `[ FAIL 0 | … ]`. If `output$results$html` is not the rendered HTML in this Shiny version, read `output$results` the way `test-isa-data-entry-module.R` or `test-indicator-snapshot.R` (WS-4 drift bar) does and keep the assertions.

- [ ] **Step 6: Commit**

```bash
git -C /c/Users/arturas.baziukas/wt-ws5 add MarineSABRES_SES_Shiny/modules/valuation_calculator_module.R MarineSABRES_SES_Shiny/app.R MarineSABRES_SES_Shiny/functions/ui_sidebar.R MarineSABRES_SES_Shiny/tests/testthat/test-valuation-calculator-module.R
git -C /c/Users/arturas.baziukas/wt-ws5 commit -m "feat(wp5): valuation calculator module under Response, with provenance-badged outputs and xlsx export (WS-5)"
```

---

### Task 4: Translations, sidebar label, CHANGELOG

**Files:**
- Create: `translations/modules/valuation_calculator.json`
- Modify: `translations/ui/sidebar.json`, `CHANGELOG.md`
- Test: `tests/testthat/test-valuation-calculator-module.R` (append), i18n gates

**Interfaces:**
- Consumes: every `modules.valuation_calculator.*` key used in Task 3; `ui.sidebar.valuation_calculator`.
- Produces: the translation file (layout as `translations/modules/wp5_vocabulary.json`: `languages` array + `translation` object).

- [ ] **Step 1: Append the failing test**

```r
test_that("every valuation-calculator key used in code exists in all 9 languages", {
  langs <- c("en","es","fr","de","lt","pt","it","no","el")
  tr <- jsonlite::fromJSON(file.path(PROJECT_ROOT, "translations", "modules", "valuation_calculator.json"),
                           simplifyVector = FALSE)$translation
  src <- paste(readLines(file.path(PROJECT_ROOT, "modules", "valuation_calculator_module.R"), warn = FALSE),
               collapse = "\n")
  found <- regmatches(src, gregexpr("modules\\.valuation_calculator\\.[A-Za-z0-9_.]*[A-Za-z0-9_]", src))[[1]]
  found <- sub("^modules\\.valuation_calculator\\.", "", found)
  found <- found[!grepl("\\.$", found) & !found %in% c("service", "method", "error", "warn")]  # paste0 prefixes
  keys <- unique(c(found, "title", "subtitle", "help_title", "disclaimer"))
  for (k in paste0("modules.valuation_calculator.", keys)) {
    expect_false(is.null(tr[[k]]), info = k)
    for (l in langs) expect_true(nzchar(tr[[k]][[l]] %||% ""), info = paste(k, l))
  }
  for (k in c("cumulative_label", "central_cumulative", "years_value", "break_even_rate_note"))
    for (l in langs)
      expect_true(grepl("%1$", tr[[paste0("modules.valuation_calculator.", k)]][[l]], fixed = TRUE),
                  info = paste(k, l))
  sb <- jsonlite::fromJSON(file.path(PROJECT_ROOT, "translations", "ui", "sidebar.json"),
                           simplifyVector = FALSE)$translation
  for (l in langs) expect_true(nzchar(sb[["ui.sidebar.valuation_calculator"]][[l]] %||% ""), info = l)
})
```

- [ ] **Step 2: Run to see it fail**

Run: `"/c/Program Files/R/R-4.4.1/bin/Rscript.exe" -e "testthat::test_file('tests/testthat/test-valuation-calculator-module.R')"`
Expected: a `lexical error` from `fromJSON()` on the missing `valuation_calculator.json`.

- [ ] **Step 3: Write `translations/modules/valuation_calculator.json`**

English source strings below. Translate each into es, fr, de, lt, pt, it, no, el as genuine translations (never English copies; `test-i18n-english-fallback.R` fails on English sentences ≥30 chars in other slots). Keep `%1$d` / `%1$s` placeholders. Write the file with the Write tool, mirroring `translations/modules/wp5_vocabulary.json`. Keys are `modules.valuation_calculator.<key>`:

| key | en |
|---|---|
| title | Valuation calculator |
| subtitle | Benefit-transfer value of Posidonia oceanica meadows (WP5, D5.2) |
| disclaimer | Benefit-transfer estimate; not a site valuation. |
| help_title | About the valuation calculator |
| help_body_1 | The calculator multiplies the meadow area by the per-hectare values for each ecosystem service reported in D5.2 (Table 19), giving an annual value range and its total over the chosen number of years. |
| help_body_2 | These are benefit-transfer values from other Mediterranean studies. They indicate an order of magnitude for preliminary cost-benefit discussions and do not replace a valuation of your site. |
| help_body_3 | The central value, the discounted values (NPV), the break-even horizon and the survival-adjusted restoration cost are additions made by the toolbox; D5.2 does not publish them. |
| habitat_label | Habitat: |
| habitat_posidonia | Posidonia oceanica meadows |
| area_label | Meadow area (ha) |
| services_label | Ecosystem services included |
| horizon_label | Time horizon (years) |
| discount_rate_label | Your discount rate (%, optional) |
| discount_rate_help | The table below always shows 0%, 3%, 5% and 7%; your rate is added and highlighted. |
| restoration_heading | Restoration (optional) |
| restoration_area_label | Area to restore (ha) |
| cost_bound_label | Restoration cost per hectare (D5.2) |
| cost_bound_low | Lower bound: €100 000 per ha |
| cost_bound_high | Upper bound: €500 000 per ha |
| download_xlsx | Download Excel |
| service.coastal_protection | Coastal protection |
| service.carbon_sequestration | Carbon sequestration |
| service.recreation_tourism | Recreation and tourism |
| service.food_provision | Food provision |
| service.water_purification | Water purification |
| method.avoided_cost | Avoided cost |
| method.social_cost_of_carbon | Market price / social cost of carbon |
| method.travel_cost_or_WTP | Travel cost, willingness to pay |
| method.market_pricing | Market pricing |
| method.replacement_cost | Replacement cost |
| primary_heading | Value reported in D5.2 |
| col_service | Ecosystem service |
| col_method | Valuation method |
| col_annual_low | Per year, low |
| col_annual_high | Per year, high |
| row_total | Total per year |
| cumulative_label | Total over %1$d years (undiscounted) |
| source_note | Source: D5.2 Table 19 (Stamatiadou et al. 2025; Pascal et al. 2014; Luisetti et al. 2013) and §4.8. |
| secondary_heading | Additional estimates |
| secondary_explain | These figures are calculated by the toolbox from the D5.2 values; D5.2 does not publish them. |
| central_annual | Central value per year (midpoint) |
| central_cumulative | Central value over %1$d years (undiscounted) |
| npv_heading | Discounted value (NPV) at several discount rates |
| col_rate | Discount rate |
| col_npv_low | Low |
| col_npv_central | Central |
| col_npv_high | High |
| your_rate | your rate |
| break_even_heading | Restoration cost and break-even |
| restoration_cost | Restoration cost |
| survival_adjusted | Cost adjusted for early survival (38–60%) |
| break_even_low | Years to recover the cost (low values) |
| break_even_high | Years to recover the cost (high values) |
| years_value | %1$s years |
| never_breaks_even | Does not recover the cost |
| break_even_rate_note | Calculated at a discount rate of %1$s. |
| break_even_rate_fallback | Calculated without discounting (0%), because no discount rate was entered. |
| error.invalid_area | Enter a meadow area of 0 ha or more. |
| error.invalid_horizon | Enter a whole number of years between 0 and 100. |
| error.invalid_rate | Enter a discount rate between 0% and 20%, or leave it empty. |
| error.invalid_restoration_area | Enter a restoration area of 0 ha or more, or leave it empty. |
| error.data_unavailable | Valuation data are not available. |
| warn.no_services | No ecosystem service is selected, so all values are zero. |

`translations/ui/sidebar.json`: add, after `"ui.sidebar.scenario_builder"`, the key `"ui.sidebar.valuation_calculator"` with en "Valuation calculator" and genuine translations in the other 8 languages (confirm first with `grep -rn "ui.sidebar.valuation_calculator" translations/` that it is defined nowhere else).

- [ ] **Step 4: CHANGELOG**

Under `## [Unreleased]`, above the WS-4 entry, add:

```markdown
### Added (WP5 valuation calculator — spec 2026-10-11 WS-5)
- New page under Response & Validation: a Posidonia oceanica valuation calculator. It multiplies a meadow area by the D5.2 Table 19 benefit-transfer values (five ecosystem services) and shows the annual value range and its undiscounted total over a chosen horizon; 1 ha over 20 years reproduces D5.2's €88,800 to €516,800.
- Badged as toolbox additions: a central midpoint, the discounted value at 0/3/5/7% (plus your own rate), the restoration cost against D5.2's €100,000–500,000 per ha, a cost adjusted for 38–60% early survival, and the break-even horizon.
- Excel export with the inputs, every value and its provenance. The valuation figures in the mechanism catalogue are now checked against the D5.2 text in tests.
```

- [ ] **Step 5: Run the i18n gates**

Run: `"/c/Program Files/R/R-4.4.1/bin/Rscript.exe" -e "for (f in c('test-valuation-calculator-module','test-i18n-duplicate-keys','test-i18n-enforcement','test-i18n-english-fallback')) testthat::test_file(file.path('tests/testthat', paste0(f, '.R')))"` and `micromamba run -n shiny python -I scripts/_i18n_audit.py`
Expected: all `[ FAIL 0 | … ]`; audit `missing=0 … hardcoded=0`.

- [ ] **Step 6: Commit**

```bash
git -C /c/Users/arturas.baziukas/wt-ws5 add MarineSABRES_SES_Shiny/translations/modules/valuation_calculator.json MarineSABRES_SES_Shiny/translations/ui/sidebar.json MarineSABRES_SES_Shiny/CHANGELOG.md MarineSABRES_SES_Shiny/tests/testthat/test-valuation-calculator-module.R
git -C /c/Users/arturas.baziukas/wt-ws5 commit -m "feat(i18n): valuation calculator strings in 9 languages; changelog (WS-5)"
```

---

## Partner gate (carried into the final report, not a task)

- Tuscan WP5 lead signs off the disclaimer "Benefit-transfer estimate; not a site valuation" and the help text.
- Tuscan partner confirms the unit values match D5.2 Table 19 (now test-enforced against the extract) and is shown the toolbox additions (central midpoint, NPV table, break-even, survival-adjusted cost) and the break-even framing (restored area's benefits vs its cost; 0% when no rate is given).
- Follow-ups: other habitats; saving calculator inputs in the project (ruling 6); a .docx summary (roadmap §6.7 mentions .docx; the spec asks only for xlsx).
