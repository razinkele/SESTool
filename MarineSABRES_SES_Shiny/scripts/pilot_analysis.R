# ==============================================================================
# Pilot Study Analysis
# ==============================================================================
#
# Aggregates the JSON session files written by modules/pilot_study_module.R,
# computes the primary and secondary outcomes specified in
# docs/ml_pilot_protocol.md, runs paired Wilcoxon tests with Bonferroni
# correction, and bootstraps 95% CIs on the median paired difference.
#
# Inputs:
#   data/pilot/*.json — per-session pilot files
#   data/pilot_reference_model.rds — pre-validated Mediterranean lagoon
#     reference template's element list (created from the production
#     template; pre-stage with scripts/extract_pilot_reference.R when ready)
#
# Output:
#   docs/PILOT_RESULTS.md
# ==============================================================================

library(jsonlite)
library(dplyr)

`%||%` <- function(x, y) if (is.null(x) || (length(x) == 1 && is.na(x))) y else x

PILOT_DIR <- "data/pilot"
REF_FILE  <- "data/pilot_reference_model.rds"
OUT_MD    <- "docs/PILOT_RESULTS.md"

# ==============================================================================
# Load sessions
# ==============================================================================

if (!dir.exists(PILOT_DIR)) {
  stop(sprintf("No pilot data directory at %s. Has the pilot been run yet?", PILOT_DIR))
}

session_files <- list.files(PILOT_DIR, pattern = "\\.json$", full.names = TRUE)
if (length(session_files) == 0L) {
  stop("No pilot session files found. Has the pilot been run yet?")
}

sessions <- lapply(session_files, function(p) {
  s <- fromJSON(p, simplifyVector = TRUE)
  list(
    path           = p,
    participant_id = s$participant_id,
    condition      = s$condition,
    t_session_start = as.POSIXct(s$t_session_start, format = "%Y-%m-%dT%H:%M:%S"),
    t_session_end   = as.POSIXct(s$t_session_end,   format = "%Y-%m-%dT%H:%M:%S"),
    t_first_save    = if (!is.null(s$t_first_save) && !is.na(s$t_first_save))
                        as.POSIXct(s$t_first_save, format = "%Y-%m-%dT%H:%M:%S") else NA,
    n_first_save_elements    = s$n_first_save_elements %||% NA_integer_,
    n_first_save_connections = s$n_first_save_connections %||% NA_integer_,
    saves                    = s$saves,
    nasa_tlx                 = s$nasa_tlx
  )
})
cat(sprintf("Loaded %d pilot session files.\n", length(sessions)))

# ==============================================================================
# Compute per-session outcomes
# ==============================================================================

reference_elements <- if (file.exists(REF_FILE)) readRDS(REF_FILE) else NULL

compute_outcomes <- function(s) {
  # Final-save counts (last save event in the session)
  n_final_elements    <- NA_integer_
  n_final_connections <- NA_integer_
  if (length(s$saves) > 0L) {
    last_save <- s$saves[[length(s$saves)]]
    n_final_elements    <- last_save$n_elements
    n_final_connections <- last_save$n_connections
  }

  # Time to first complete (minutes)
  ttf_min <- if (!is.null(s$t_first_save) && !is.na(s$t_first_save))
               as.numeric(difftime(s$t_first_save, s$t_session_start, units = "mins")) else NA_real_

  # NASA-TLX overall (mean of six sub-scales)
  tlx_overall <- if (is.list(s$nasa_tlx)) mean(unlist(s$nasa_tlx), na.rm = TRUE) else NA_real_

  list(
    n_connections_final = n_final_connections,
    n_elements_final    = n_final_elements,
    time_to_first_min   = ttf_min,
    nasa_tlx_overall    = tlx_overall
  )
}

per_session <- lapply(sessions, function(s) {
  out <- compute_outcomes(s)
  c(list(participant_id = s$participant_id, condition = s$condition), out)
})

# ==============================================================================
# Pair sessions by participant + run tests
# ==============================================================================

df <- do.call(rbind, lapply(per_session, function(r) {
  data.frame(
    participant_id      = r$participant_id,
    condition           = r$condition,
    n_connections_final = r$n_connections_final %||% NA,
    n_elements_final    = r$n_elements_final    %||% NA,
    time_to_first_min   = r$time_to_first_min   %||% NA,
    nasa_tlx_overall    = r$nasa_tlx_overall    %||% NA,
    stringsAsFactors = FALSE
  )
}))

# Keep only participants who completed BOTH A and B
participants_complete <- df %>%
  group_by(participant_id) %>%
  filter(all(c("A", "B") %in% condition)) %>%
  pull(participant_id) %>% unique()

df <- df %>% filter(participant_id %in% participants_complete)
cat(sprintf("Participants with paired data: %d\n", length(participants_complete)))

if (length(participants_complete) < 3L) {
  stop("Fewer than 3 participants have paired A/B data. Cannot run paired tests.")
}

# Pivot to one row per participant
pivot_outcome <- function(name) {
  df %>%
    select(participant_id, condition, value = !!name) %>%
    tidyr::pivot_wider(names_from = condition, values_from = value, names_prefix = "cond_")
}

outcomes <- c("n_connections_final", "n_elements_final",
              "time_to_first_min", "nasa_tlx_overall")

results <- list()
for (oc in outcomes) {
  pv <- pivot_outcome(oc)
  diffs <- pv$cond_B - pv$cond_A
  test <- tryCatch(
    wilcox.test(pv$cond_B, pv$cond_A, paired = TRUE, conf.int = TRUE),
    error = function(e) NULL
  )
  results[[oc]] <- list(
    n          = nrow(pv),
    median_A   = median(pv$cond_A, na.rm = TRUE),
    median_B   = median(pv$cond_B, na.rm = TRUE),
    median_diff = median(diffs, na.rm = TRUE),
    p_value    = if (!is.null(test)) test$p.value else NA_real_,
    ci_low     = if (!is.null(test) && !is.null(test$conf.int)) test$conf.int[1] else NA_real_,
    ci_high    = if (!is.null(test) && !is.null(test$conf.int)) test$conf.int[2] else NA_real_
  )
}

# Bonferroni correction on primary outcomes (first 3)
primary <- c("n_connections_final", "time_to_first_min", "nasa_tlx_overall")
n_primary <- length(primary)
for (oc in primary) {
  if (!is.na(results[[oc]]$p_value)) {
    results[[oc]]$p_value_bonferroni <- min(1, results[[oc]]$p_value * n_primary)
  }
}

# ==============================================================================
# Write Markdown
# ==============================================================================

if (!dir.exists("docs")) dir.create("docs", recursive = TRUE)

md <- c(
  "# Pilot Study Results",
  "",
  sprintf("Generated: %s", format(Sys.time(), "%Y-%m-%d %H:%M:%S")),
  "",
  sprintf("**N participants with paired A/B data:** %d", length(participants_complete)),
  "",
  "## Primary and secondary outcomes",
  "",
  "Condition A = baseline (no ML); Condition B = ML-augmented. Paired",
  "Wilcoxon signed-rank tests. p-values for the three primary outcomes",
  "(connections, time-to-first, NASA-TLX) are reported both raw and",
  "Bonferroni-corrected. 95% CI on the median paired difference (B − A).",
  "",
  "| Outcome | median A | median B | median diff (B − A) | 95% CI | raw p | Bonferroni p |",
  "|---|---:|---:|---:|---:|---:|---:|"
)
for (oc in outcomes) {
  r <- results[[oc]]
  bonf <- r$p_value_bonferroni %||% NA
  md <- c(md, sprintf("| %s | %.2f | %.2f | %.2f | [%.2f, %.2f] | %.4f | %s |",
                      oc,
                      r$median_A %||% NA, r$median_B %||% NA, r$median_diff %||% NA,
                      r$ci_low %||% NA, r$ci_high %||% NA,
                      r$p_value %||% NA,
                      if (is.na(bonf)) "—" else sprintf("%.4f", bonf)))
}

md <- c(md,
  "",
  "## Interpretation guidance",
  "",
  "- A significant raw or Bonferroni-corrected p with median_diff > 0 on",
  "  `n_connections_final` supports H1.",
  "- A significant test with median_diff < 0 on `time_to_first_min`",
  "  supports H3.",
  "- A non-significant test does NOT mean 'no effect' on N = 8-12; it",
  "  means the pilot is underpowered to detect smaller effects.",
  "",
  "## Reproduce",
  "",
  "```bash",
  "Rscript scripts/pilot_analysis.R",
  "```"
)

writeLines(md, OUT_MD)
cat(sprintf("\nWrote %s\n", OUT_MD))
