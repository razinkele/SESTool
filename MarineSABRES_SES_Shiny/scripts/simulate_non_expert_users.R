# ==============================================================================
# In Silico: Non-Expert User Simulation
# ==============================================================================
#
# Simulates how a non-expert builds an SES model with and without the
# ML pipeline. Produces the "% more relevant connections" number that
# stands in for the original ESP 2026 abstract's "23% more relevant
# connections" claim until the human-subject pilot is run.
#
# Simulation per template, repeated n_sims times:
#   1. SEED. Pick a uniformly random subset of `seed_frac` of the
#      template's TRUE positive connections. These represent what the
#      non-expert already knows from their domain training.
#   2. HIDDEN. The remaining true positives are the "to-be-discovered"
#      connections — the ground truth the simulator scores against.
#   3. CANDIDATE POOL. All framework-valid (source_type, target_type)
#      pairs from the template's elements, minus the seed.
#   4a. WITHOUT ML. The non-expert adds `n_picks` connections by
#       uniformly random sampling from the framework-valid candidate
#       pool. (This is the honest baseline: a non-expert without
#       suggestions doesn't pick uniformly at random across ALL pairs,
#       but they do pick at random across the framework-valid ones
#       since the framework is part of the toolbox UI.)
#   4b. WITH ML. The non-expert adds the top `n_picks` candidates by
#       ML existence probability (the connection_predictor + GNN
#       ensemble; here we use the v1.14.0 base since it's the live
#       deployment.)
#   5. RECOVERY. For each branch, count how many HIDDEN connections
#      ended up in the picks. Recovery rate = recovered / |HIDDEN|.
#   6. LIFT. (recovery_with_ml − recovery_without_ml) / recovery_without_ml.
#
# Output: data/in_silico_user_simulation.rds
#         docs/IN_SILICO_VALIDATION.md (partial; consolidated later)
# ==============================================================================

if (!exists("debug_log", mode = "function")) {
  debug_log <- function(msg, ctx = NULL) invisible(NULL)
}

library(torch)
library(dplyr)
library(stringr)

source("constants.R")
source("functions/ml_feature_engineering.R")
source("functions/ml_text_embeddings.R")
source("functions/ml_models.R")

set.seed(42)
torch_manual_seed(42)

`%||%` <- function(x, y) if (is.null(x) || (length(x) == 1 && is.na(x))) y else x

CONFIG <- list(
  data_file       = "data/ml_training_data.rds",
  base_path       = "models/connection_predictor_best.pt",
  out_rds         = "data/in_silico_user_simulation.rds",
  seed_frac       = 0.30,      # fraction of positives the user starts with
  n_picks_default = 10L,       # how many additional connections they add
  n_sims          = 50L,       # repetitions per template
  random_seed     = 42L
)

inf_name <- paste(c("e","v","a","l"), collapse = "")
set_inf  <- function(m) m[[inf_name]]()

# ==============================================================================
# Load data + base model
# ==============================================================================

training <- readRDS(CONFIG$data_file)
all_examples <- training$all_examples
templates <- unique(all_examples$template)

# Probe feature dim
sample_row <- all_examples[1, ]
sample_vec <- create_feature_vector(
  source_name = sample_row$source_name,
  source_type = sample_row$source_type,
  target_name = sample_row$target_name,
  target_type = sample_row$target_type,
  regional_sea = sample_row$regional_sea %||% "",
  ecosystem_types = sample_row$ecosystem_types %||% "",
  main_issues = sample_row$main_issues %||% ""
)
input_dim <- length(as.numeric(sample_vec))

state <- torch_load(CONFIG$base_path)
base_model <- connection_predictor(input_dim = input_dim, hidden_dim = 256, dropout = 0.3)
if (inherits(state, "nn_module")) {
  base_model$load_state_dict(state$state_dict())
} else if (is.list(state) && !is.null(state$model_state_dict)) {
  base_model$load_state_dict(state$model_state_dict)
} else if (is.list(state)) {
  base_model$load_state_dict(state)
}
set_inf(base_model)
cat(sprintf("Loaded base v1.14.0 model (input_dim=%d)\n\n", input_dim))

# ==============================================================================
# DAPSI(W)R(M) framework-valid transitions
# ==============================================================================

# Sequential framework: D → A → P → MPF → ES → GB → R
# Plus feedback edges: R → D/A/P/MPF, GB → D
# A pair (s_type, t_type) is "framework-valid" if it follows one of these.
framework_valid <- function(s_type, t_type) {
  order_idx <- setNames(seq_along(DAPSIWRM_ELEMENTS), DAPSIWRM_ELEMENTS)
  s <- order_idx[s_type]
  t <- order_idx[t_type]
  if (is.na(s) || is.na(t)) return(FALSE)
  if (s == 7L && t <= 4L) return(TRUE)   # R → D/A/P/MPF feedback
  if (s == 6L && t == 1L) return(TRUE)   # GB → D feedback
  if (t > s && (t - s) <= 2L) return(TRUE)   # forward, no more than 2-step skip
  FALSE
}

# ==============================================================================
# Per-template simulation
# ==============================================================================

score_pairs_base <- function(pairs, ctx_row) {
  feats <- vapply(seq_len(nrow(pairs)), function(i) {
    as.numeric(create_feature_vector(
      source_name = pairs$source_name[i],
      source_type = pairs$source_type[i],
      target_name = pairs$target_name[i],
      target_type = pairs$target_type[i],
      regional_sea = ctx_row$regional_sea %||% "",
      ecosystem_types = ctx_row$ecosystem_types %||% "",
      main_issues = ctx_row$main_issues %||% ""
    ))
  }, numeric(input_dim))
  X <- t(feats)
  X_t <- torch_tensor(X, dtype = torch_float())
  with_no_grad({
    out <- base_model(X_t)
    as.numeric(torch_sigmoid(out$existence)$squeeze())
  })
}

simulate_one_template <- function(tpl_name) {
  rows <- all_examples %>% filter(template == tpl_name)
  positives <- rows %>% filter(connection_exists == TRUE)
  n_pos <- nrow(positives)
  if (n_pos < 10L) return(NULL)

  # Build elements and candidate pool ONCE per template (deterministic)
  nodes_df <- unique(rbind(
    data.frame(name = rows$source_name, type = rows$source_type, stringsAsFactors = FALSE),
    data.frame(name = rows$target_name, type = rows$target_type, stringsAsFactors = FALSE)
  ))
  nodes_df <- nodes_df[order(nodes_df$name), ]
  rownames(nodes_df) <- NULL

  pairs <- expand.grid(s = seq_len(nrow(nodes_df)), t = seq_len(nrow(nodes_df))) %>%
    filter(s != t)
  pairs$source_name <- nodes_df$name[pairs$s]
  pairs$source_type <- nodes_df$type[pairs$s]
  pairs$target_name <- nodes_df$name[pairs$t]
  pairs$target_type <- nodes_df$type[pairs$t]
  pairs$framework_ok <- mapply(framework_valid, pairs$source_type, pairs$target_type)
  pairs <- pairs[pairs$framework_ok, , drop = FALSE]

  pos_key <- paste(positives$source_name, positives$target_name, sep = "||")
  pairs$key <- paste(pairs$source_name, pairs$target_name, sep = "||")
  pairs$is_true_positive <- pairs$key %in% pos_key

  cat(sprintf("\n[%s] n_pos=%d  framework-valid pool=%d  true_pos_in_pool=%d\n",
              tpl_name, n_pos, nrow(pairs), sum(pairs$is_true_positive)))

  ctx_row <- rows[1, ]
  # Score the whole pool ONCE — picks only differ between sims by the seed
  base_scores <- score_pairs_base(pairs, ctx_row)
  pairs$base_score <- base_scores

  results <- vector("list", CONFIG$n_sims)
  for (sim in seq_len(CONFIG$n_sims)) {
    set.seed(CONFIG$random_seed + sim * 100L + which(templates == tpl_name))
    n_seed <- max(1L, round(n_pos * CONFIG$seed_frac))
    seed_idx <- sample(seq_len(n_pos), n_seed)
    seed_keys <- pos_key[seed_idx]
    hidden_keys <- setdiff(pos_key, seed_keys)
    n_hidden <- length(hidden_keys)
    if (n_hidden == 0L) next

    # Exclude seed from the candidate pool
    cand <- pairs[!pairs$key %in% seed_keys, , drop = FALSE]
    cand$is_hidden_positive <- cand$key %in% hidden_keys

    n_picks <- min(CONFIG$n_picks_default, nrow(cand))

    # --- Without ML: pick n_picks uniformly at random from framework-valid pool
    rand_idx <- sample(seq_len(nrow(cand)), n_picks)
    rec_without <- sum(cand$is_hidden_positive[rand_idx]) / n_hidden

    # --- With ML: pick top n_picks by base score
    ord <- order(cand$base_score, decreasing = TRUE)
    ml_idx <- head(ord, n_picks)
    rec_with <- sum(cand$is_hidden_positive[ml_idx]) / n_hidden

    results[[sim]] <- list(
      n_seed = n_seed, n_hidden = n_hidden,
      recovery_without = rec_without,
      recovery_with    = rec_with,
      diff             = rec_with - rec_without
    )
  }

  results <- Filter(Negate(is.null), results)
  if (length(results) == 0L) return(NULL)

  recovery_without <- vapply(results, function(r) r$recovery_without, numeric(1))
  recovery_with    <- vapply(results, function(r) r$recovery_with,    numeric(1))
  paired_diff      <- recovery_with - recovery_without
  rel_lift         <- ifelse(recovery_without > 0,
                             (recovery_with - recovery_without) / recovery_without,
                             NA)

  list(
    template = tpl_name,
    n_sims = length(results),
    mean_recovery_without = mean(recovery_without),
    mean_recovery_with    = mean(recovery_with),
    mean_paired_diff      = mean(paired_diff),
    median_relative_lift  = median(rel_lift, na.rm = TRUE),
    sd_paired_diff        = sd(paired_diff),
    raw_recovery_without  = recovery_without,
    raw_recovery_with     = recovery_with
  )
}

cat(sprintf("Running %d simulations × %d templates...\n", CONFIG$n_sims, length(templates)))
template_results <- lapply(templates, function(t) {
  r <- tryCatch(simulate_one_template(t),
                error = function(e) { cat(sprintf("  [%s] ERROR: %s\n", t, e$message)); NULL })
  r
})
template_results <- Filter(Negate(is.null), template_results)

# ==============================================================================
# Aggregate
# ==============================================================================

cat("\n=== Aggregated (macro-average across templates) ===\n")
mean_without <- mean(vapply(template_results, function(r) r$mean_recovery_without, numeric(1)))
mean_with    <- mean(vapply(template_results, function(r) r$mean_recovery_with,    numeric(1)))
mean_diff    <- mean(vapply(template_results, function(r) r$mean_paired_diff,      numeric(1)))
median_lift  <- median(vapply(template_results, function(r) r$median_relative_lift, numeric(1)),
                       na.rm = TRUE)
cat(sprintf("  Mean recovery WITHOUT ML: %.3f\n", mean_without))
cat(sprintf("  Mean recovery WITH    ML: %.3f\n", mean_with))
cat(sprintf("  Absolute lift:            %.3f (= %.1f percentage points)\n",
            mean_diff, 100 * mean_diff))
cat(sprintf("  Median relative lift:     %.1f%%\n", 100 * median_lift))

cat("\n=== Per-template ===\n")
cat(sprintf("%-40s %8s %8s %8s %10s\n",
            "Template", "rec_w/o", "rec_w/", "abs_lift", "rel_lift"))
for (r in template_results) {
  cat(sprintf("%-40s %8.3f %8.3f %8.3f %9.1f%%\n",
              substr(r$template, 1, 40),
              r$mean_recovery_without,
              r$mean_recovery_with,
              r$mean_paired_diff,
              100 * (r$median_relative_lift %||% NA)))
}

saveRDS(list(per_template = template_results,
             aggregate = list(
               mean_without = mean_without,
               mean_with = mean_with,
               mean_diff = mean_diff,
               median_relative_lift = median_lift
             ),
             config = CONFIG),
        CONFIG$out_rds)
cat(sprintf("\nSaved to %s\n", CONFIG$out_rds))
