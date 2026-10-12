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
    adj <- survival_adjusted_cost(cost, as.numeric(restoration$early_survival_low),
                                  as.numeric(restoration$early_survival_high))
    # Break-even is measured against the survival-adjusted cost, so it agrees with
    # the adjusted-cost row: slowest case = lower service values vs cost / worst
    # survival; fastest = higher values vs cost / best survival. Benefits are the
    # mature-meadow values from year 1 (stated in the UI).
    be_low <- calculate_break_even_horizon(benefit_low, adj[["high"]], rate)
    be_high <- calculate_break_even_horizon(benefit_high, adj[["low"]], rate)
    rest <- list(area = restoration_area, cost_bound = bound, cost_per_ha = per_ha, cost = cost,
                 survival_adjusted = adj, rate = rate, rate_is_fallback = is.na(user_rate),
                 benefit_low = benefit_low, benefit_high = benefit_high,
                 break_even_low = be_low, break_even_high = be_high,
                 beyond_horizon_low = !is.na(be_low) && be_low > horizon,
                 beyond_horizon_high = !is.na(be_high) && be_high > horizon)
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
                                  provenance = "toolbox_extension", source = "survival-adjusted cost vs full annual value from year 1; annuity formula (not in D5.2)")
  }
  do.call(rbind, out)
}
