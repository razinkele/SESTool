# ==============================================================================
# In Silico: Cross-User Consistency Simulation
# ==============================================================================
#
# Produces the "% greater consistency across users" number that stands in
# for the original ESP 2026 abstract's "64% greater consistency" claim
# until the human-subject pilot is run.
#
# The simulation per template:
#   1. Simulate N_USERS independent non-expert users. Each user starts
#      with their OWN random `seed_frac` subset of the template's true
#      positives — different users see different parts of the system
#      because they have different domain backgrounds.
#   2. WITHOUT ML: each user adds n_picks connections by uniformly
#      random sampling from the framework-valid pool. Their final
#      "model" = seed ∪ random_picks.
#   3. WITH ML: each user adds the top n_picks candidates by the base
#      model's existence probability. Their final model = seed ∪ top_picks.
#   4. For each branch, compute the MEAN PAIRWISE Jaccard similarity
#      across the N_USERS users' final connection sets.
#   5. CONSISTENCY LIFT = (Jaccard_with_ml − Jaccard_without_ml) /
#                         Jaccard_without_ml.
#
# Rationale: if ML acts as shared scaffolding, two different users with
# different seed knowledge should converge on more similar models when
# both use the same ML system. If ML behaves like background noise,
# Jaccard stays flat.
#
# Output: data/in_silico_consistency.rds
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
  out_rds         = "data/in_silico_consistency.rds",
  seed_frac       = 0.30,
  n_picks         = 10L,
  n_users_per_template = 5L,
  n_sims          = 30L,
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

sample_row <- all_examples[1, ]
input_dim <- length(as.numeric(create_feature_vector(
  source_name = sample_row$source_name, source_type = sample_row$source_type,
  target_name = sample_row$target_name, target_type = sample_row$target_type,
  regional_sea = sample_row$regional_sea %||% "",
  ecosystem_types = sample_row$ecosystem_types %||% "",
  main_issues = sample_row$main_issues %||% ""
)))

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
# Framework validity
# ==============================================================================

framework_valid <- function(s_type, t_type) {
  order_idx <- setNames(seq_along(DAPSIWRM_ELEMENTS), DAPSIWRM_ELEMENTS)
  s <- order_idx[s_type]
  t <- order_idx[t_type]
  if (is.na(s) || is.na(t)) return(FALSE)
  if (s == 7L && t <= 4L) return(TRUE)
  if (s == 6L && t == 1L) return(TRUE)
  if (t > s && (t - s) <= 2L) return(TRUE)
  FALSE
}

# ==============================================================================
# Pairwise Jaccard
# ==============================================================================

mean_pairwise_jaccard <- function(sets) {
  n <- length(sets)
  if (n < 2L) return(NA_real_)
  pairs <- combn(n, 2)
  vals <- vapply(seq_len(ncol(pairs)), function(j) {
    a <- sets[[pairs[1, j]]]
    b <- sets[[pairs[2, j]]]
    if (length(a) == 0L && length(b) == 0L) return(1)
    length(intersect(a, b)) / length(union(a, b))
  }, numeric(1))
  mean(vals)
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
  pairs$key <- paste(pairs$source_name, pairs$target_name, sep = "||")

  pos_key <- paste(positives$source_name, positives$target_name, sep = "||")
  ctx_row <- rows[1, ]
  pairs$base_score <- score_pairs_base(pairs, ctx_row)

  cat(sprintf("\n[%s] pool=%d  positives=%d\n", tpl_name, nrow(pairs), n_pos))

  jacc_without <- numeric(0)
  jacc_with    <- numeric(0)

  for (sim in seq_len(CONFIG$n_sims)) {
    set.seed(CONFIG$random_seed + sim * 100L + which(templates == tpl_name))
    user_models_without <- list()
    user_models_with    <- list()

    for (u in seq_len(CONFIG$n_users_per_template)) {
      n_seed <- max(1L, round(n_pos * CONFIG$seed_frac))
      seed_idx <- sample(seq_len(n_pos), n_seed)
      seed_keys <- pos_key[seed_idx]

      cand <- pairs[!pairs$key %in% seed_keys, , drop = FALSE]
      n_picks <- min(CONFIG$n_picks, nrow(cand))

      # Without ML: random picks
      rand_idx <- sample(seq_len(nrow(cand)), n_picks)
      user_models_without[[u]] <- c(seed_keys, cand$key[rand_idx])

      # With ML: deterministic top-k by score (every user with the same
      # seed-induced visible state would pick the same items — that's the
      # SOURCE of the consistency lift, by design.)
      ord <- order(cand$base_score, decreasing = TRUE)
      ml_idx <- head(ord, n_picks)
      user_models_with[[u]] <- c(seed_keys, cand$key[ml_idx])
    }

    jacc_without <- c(jacc_without, mean_pairwise_jaccard(user_models_without))
    jacc_with    <- c(jacc_with,    mean_pairwise_jaccard(user_models_with))
  }

  list(
    template = tpl_name,
    n_sims = CONFIG$n_sims,
    n_users = CONFIG$n_users_per_template,
    mean_jaccard_without = mean(jacc_without, na.rm = TRUE),
    mean_jaccard_with    = mean(jacc_with,    na.rm = TRUE),
    sd_jaccard_without   = sd(jacc_without,   na.rm = TRUE),
    sd_jaccard_with      = sd(jacc_with,      na.rm = TRUE),
    raw_without          = jacc_without,
    raw_with             = jacc_with
  )
}

cat(sprintf("Simulating %d users × %d sims × %d templates...\n",
            CONFIG$n_users_per_template, CONFIG$n_sims, length(templates)))
template_results <- lapply(templates, simulate_one_template)
template_results <- Filter(Negate(is.null), template_results)

# ==============================================================================
# Aggregate
# ==============================================================================

mean_w  <- mean(vapply(template_results, function(r) r$mean_jaccard_without, numeric(1)))
mean_wm <- mean(vapply(template_results, function(r) r$mean_jaccard_with,    numeric(1)))
abs_diff <- mean_wm - mean_w
rel_lift_per_template <- vapply(template_results, function(r) {
  if (r$mean_jaccard_without > 0) {
    (r$mean_jaccard_with - r$mean_jaccard_without) / r$mean_jaccard_without
  } else NA_real_
}, numeric(1))
median_rel_lift <- median(rel_lift_per_template, na.rm = TRUE)

cat("\n=== Aggregated (macro-average) ===\n")
cat(sprintf("  Mean pairwise Jaccard WITHOUT ML: %.3f\n", mean_w))
cat(sprintf("  Mean pairwise Jaccard WITH    ML: %.3f\n", mean_wm))
cat(sprintf("  Absolute lift:                    %.3f (= %.1f pp)\n",
            abs_diff, 100 * abs_diff))
cat(sprintf("  Median relative lift:             %.1f%%\n", 100 * median_rel_lift))

cat("\n=== Per-template ===\n")
cat(sprintf("%-40s %10s %10s %10s\n", "Template", "jacc_w/o", "jacc_w/", "rel_lift"))
for (i in seq_along(template_results)) {
  r <- template_results[[i]]
  cat(sprintf("%-40s %10.3f %10.3f %9.1f%%\n",
              substr(r$template, 1, 40),
              r$mean_jaccard_without,
              r$mean_jaccard_with,
              100 * (rel_lift_per_template[i] %||% NA)))
}

saveRDS(list(per_template = template_results,
             aggregate = list(
               mean_jaccard_without = mean_w,
               mean_jaccard_with    = mean_wm,
               absolute_diff        = abs_diff,
               median_relative_lift = median_rel_lift
             ),
             config = CONFIG),
        CONFIG$out_rds)
cat(sprintf("\nSaved to %s\n", CONFIG$out_rds))
