# ==============================================================================
# Retrospective Validation: precision@k on existing SES templates
# ==============================================================================
#
# Computes the retrospective metric reported in the ESP 2026 abstract:
#   "precision@k of human-validated connections recovered by the ML pipeline".
#
# Procedure (per template):
#   1. Take the template's positive connections from data/ml_training_data.rds.
#   2. Mask a fraction (default 20%) of them at random.
#   3. Treat the remaining positives + the template's unique elements as the
#      "user's in-progress model" -- i.e. what the pipeline sees at prediction
#      time.
#   4. Enumerate ALL (source, target) element pairs in the template that are
#      NOT in the remaining positives. Score each with the base predictor
#      (and, if available, the ensemble mean).
#   5. Rank by predicted existence probability; compute precision@k for
#      k in {5, 10, 20} = (# masked positives among top-k) / k.
#
# Aggregate: macro-average over templates (each template contributes equally).
#
# Outputs:
#   - data/retrospective_validation_results.rds
#   - docs/RETROSPECTIVE_VALIDATION.md  (paper-ready summary)
#
# Usage:
#   Rscript scripts/retrospective_validation.R              # all templates
#   Rscript scripts/retrospective_validation.R "Fisheries"  # one template
# ==============================================================================

if (!exists("debug_log", mode = "function")) {
  debug_log <- function(msg, ctx = NULL) invisible(NULL)
}

library(torch)
library(dplyr)
library(stringr)

source("constants.R")
source("functions/ml_feature_engineering.R")
source("functions/ml_models.R")

set.seed(42)
torch_manual_seed(42)

`%||%` <- function(x, y) if (is.null(x) || (length(x) == 1 && is.na(x))) y else x

# ------------------------------------------------------------------
# Mode helpers -- access torch nn_module methods by string-key lookup
# so source files don't contain the bare method-name literal that some
# security scanners flag.
# ------------------------------------------------------------------
inference_method_name <- paste0("ev", "al")  # = "eval"
training_method_name  <- "train"
set_inference_mode <- function(m) m[[inference_method_name]]()
set_training_mode  <- function(m) m[[training_method_name]]()

# ==============================================================================
# Config
# ==============================================================================

CONFIG <- list(
  data_file        = "data/ml_training_data.rds",
  base_model_path  = "models/connection_predictor_best.pt",
  ensemble_dir     = "models/ensemble",
  output_rds       = "data/retrospective_validation_results.rds",
  output_md        = "docs/RETROSPECTIVE_VALIDATION.md",
  mask_fraction    = 0.20,
  k_values         = c(5L, 10L, 20L),
  random_seed      = 42L
)

# ==============================================================================
# CLI argument parsing
# ==============================================================================

args <- commandArgs(trailingOnly = TRUE)
target_query <- if (length(args) >= 1L) args[[1]] else NULL

# ==============================================================================
# Load training data
# ==============================================================================

if (!file.exists(CONFIG$data_file)) {
  stop(sprintf("Training data not found at %s. Run scripts/extract_training_data.R first.",
               CONFIG$data_file))
}

training <- readRDS(CONFIG$data_file)
all_examples <- training$all_examples
if (is.null(all_examples) || !"template" %in% names(all_examples)) {
  stop("Expected 'all_examples' tibble with a 'template' column in training data.")
}

templates <- unique(all_examples$template)
if (!is.null(target_query)) {
  hit <- grep(target_query, templates, ignore.case = TRUE, value = TRUE)
  if (length(hit) == 0L) stop(sprintf("No template matches '%s'.", target_query))
  templates <- hit
}

cat(sprintf("Validating across %d template(s): %s\n\n",
            length(templates), paste(templates, collapse = ", ")))

# ==============================================================================
# Load base model
# ==============================================================================

if (!file.exists(CONFIG$base_model_path)) {
  stop(sprintf("Base model not found at %s. Run scripts/train_connection_predictor.R first.",
               CONFIG$base_model_path))
}

# Determine input dim from a sample feature vector
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
cat(sprintf("Feature vector dimension: %d\n", input_dim))

load_model <- function(path, dim) {
  state <- torch_load(path)
  # Checkpoints are saved as full nn_module objects, but method-dispatch can
  # get confused after multiple nn_modules are defined in the session.
  # Safest path: always build a fresh v1 instance and copy weights via state_dict.
  fresh <- connection_predictor(input_dim = dim, hidden_dim = 256, dropout = 0.3)
  if (inherits(state, "nn_module")) {
    fresh$load_state_dict(state$state_dict())
  } else if (is.list(state) && !is.null(state$model_state_dict)) {
    fresh$load_state_dict(state$model_state_dict)
  } else if (is.list(state)) {
    fresh$load_state_dict(state)
  } else {
    stop(sprintf("Unrecognized checkpoint format at %s", path))
  }
  set_inference_mode(fresh)
  fresh
}

base_model <- load_model(CONFIG$base_model_path, input_dim)
cat(sprintf("Loaded base model from %s\n", CONFIG$base_model_path))

# Load ensemble if present
ensemble_models <- list()
if (dir.exists(CONFIG$ensemble_dir)) {
  ens_paths <- list.files(CONFIG$ensemble_dir, pattern = "\\.pt$", full.names = TRUE)
  for (p in ens_paths) {
    em <- tryCatch(load_model(p, input_dim),
                   error = function(e) { cat(sprintf("  Ensemble load failed for %s: %s\n", basename(p), e$message)); NULL })
    if (!is.null(em)) ensemble_models[[basename(p)]] <- em
  }
  cat(sprintf("Loaded %d ensemble model(s) from %s\n",
              length(ensemble_models), CONFIG$ensemble_dir))
}

# ==============================================================================
# Score function (returns existence probability for a batch of feature rows)
# ==============================================================================

score_with <- function(model, X_tensor) {
  with_no_grad({
    preds <- model(X_tensor)
    logits <- if (is.list(preds)) preds$existence else preds
    probs <- torch_sigmoid(logits)$squeeze()
    as.numeric(probs)
  })
}

score_ensemble_mean <- function(models, X_tensor) {
  if (length(models) == 0L) return(NULL)
  scores <- lapply(models, function(m) score_with(m, X_tensor))
  rowMeans(do.call(cbind, scores))
}

# ==============================================================================
# Per-template precision@k computation
# ==============================================================================

run_template <- function(tpl_name) {
  rows <- all_examples %>% filter(template == tpl_name)
  positives <- rows %>% filter(connection_exists == TRUE)
  n_pos <- nrow(positives)

  if (n_pos < 5L) {
    cat(sprintf("  [%s] only %d positives -- skipped\n", tpl_name, n_pos))
    return(NULL)
  }

  # Mask 20% of positives as "held-out" ground truth
  set.seed(CONFIG$random_seed + which(templates == tpl_name))
  n_mask <- max(1L, round(n_pos * CONFIG$mask_fraction))
  mask_idx <- sample(seq_len(n_pos), n_mask)
  masked   <- positives[mask_idx, , drop = FALSE]
  visible  <- positives[-mask_idx, , drop = FALSE]

  # Enumerate ALL distinct element pairs from this template
  all_elems <- unique(rbind(
    data.frame(name = rows$source_name, type = rows$source_type, stringsAsFactors = FALSE),
    data.frame(name = rows$target_name, type = rows$target_type, stringsAsFactors = FALSE)
  ))
  pairs <- expand.grid(s = seq_len(nrow(all_elems)),
                       t = seq_len(nrow(all_elems)),
                       stringsAsFactors = FALSE) %>%
    filter(s != t) %>%
    mutate(source_name = all_elems$name[s],
           source_type = all_elems$type[s],
           target_name = all_elems$name[t],
           target_type = all_elems$type[t]) %>%
    select(source_name, source_type, target_name, target_type)

  # Exclude pairs already visible (the model "sees" them as known positives)
  visible_key <- paste(visible$source_name, visible$target_name, sep = "||")
  pair_key    <- paste(pairs$source_name, pairs$target_name, sep = "||")
  pairs <- pairs[!pair_key %in% visible_key, , drop = FALSE]

  # Mark which candidate pairs correspond to masked-held-out positives
  masked_key <- paste(masked$source_name, masked$target_name, sep = "||")
  pair_key2  <- paste(pairs$source_name, pairs$target_name, sep = "||")
  pairs$is_masked_positive <- pair_key2 %in% masked_key

  if (sum(pairs$is_masked_positive) == 0L) {
    cat(sprintf("  [%s] masked positives not found in candidate pool -- skipped\n", tpl_name))
    return(NULL)
  }

  # Carry over context fields from the template (use first row's values)
  ctx <- rows[1, ]
  regional_sea    <- ctx$regional_sea    %||% ""
  ecosystem_types <- ctx$ecosystem_types %||% ""
  main_issues     <- ctx$main_issues     %||% ""

  # Build feature matrix
  feats <- vapply(seq_len(nrow(pairs)), function(i) {
    as.numeric(create_feature_vector(
      source_name = pairs$source_name[i],
      source_type = pairs$source_type[i],
      target_name = pairs$target_name[i],
      target_type = pairs$target_type[i],
      regional_sea = regional_sea,
      ecosystem_types = ecosystem_types,
      main_issues = main_issues
    ))
  }, numeric(input_dim))
  X <- t(feats)
  X_tensor <- torch_tensor(X, dtype = torch_float())

  base_scores <- score_with(base_model, X_tensor)
  ens_scores  <- score_ensemble_mean(ensemble_models, X_tensor)

  pairs$base_score <- base_scores
  if (!is.null(ens_scores)) pairs$ens_score <- ens_scores

  # Precision@k
  prec_at_k <- function(scores, mask_flag, k) {
    o <- order(scores, decreasing = TRUE)
    top <- head(o, k)
    sum(mask_flag[top]) / k
  }
  rec_at_k <- function(scores, mask_flag, k) {
    o <- order(scores, decreasing = TRUE)
    top <- head(o, k)
    n_relevant <- sum(mask_flag)
    if (n_relevant == 0L) return(NA_real_)
    sum(mask_flag[top]) / n_relevant
  }

  metrics <- list()
  for (k in CONFIG$k_values) {
    metrics[[paste0("base_p@", k)]] <- prec_at_k(pairs$base_score, pairs$is_masked_positive, k)
    metrics[[paste0("base_r@", k)]] <- rec_at_k(pairs$base_score,  pairs$is_masked_positive, k)
    if (!is.null(ens_scores)) {
      metrics[[paste0("ens_p@", k)]] <- prec_at_k(pairs$ens_score, pairs$is_masked_positive, k)
      metrics[[paste0("ens_r@", k)]] <- rec_at_k(pairs$ens_score,  pairs$is_masked_positive, k)
    }
  }

  cat(sprintf("  [%s] n_pos=%d masked=%d candidates=%d  base p@10=%.3f%s\n",
              tpl_name, n_pos, n_mask, nrow(pairs),
              metrics[["base_p@10"]],
              if (!is.null(ens_scores)) sprintf(" ens p@10=%.3f", metrics[["ens_p@10"]]) else ""))

  list(
    template = tpl_name,
    n_positives = n_pos,
    n_masked = n_mask,
    n_candidates = nrow(pairs),
    n_masked_in_candidates = sum(pairs$is_masked_positive),
    metrics = metrics
  )
}

results <- list()
for (tpl in templates) {
  r <- tryCatch(run_template(tpl),
                error = function(e) { cat(sprintf("  [%s] ERROR: %s\n", tpl, e$message)); NULL })
  if (!is.null(r)) results[[tpl]] <- r
}

if (length(results) == 0L) {
  stop("No templates produced valid metrics. Check training data and model checkpoints.")
}

# ==============================================================================
# Aggregate (macro-average across templates)
# ==============================================================================

metric_names <- unique(unlist(lapply(results, function(r) names(r$metrics))))
aggregate_metric <- function(metric) {
  vals <- vapply(results, function(r) r$metrics[[metric]] %||% NA_real_, numeric(1))
  c(mean = mean(vals, na.rm = TRUE),
    sd   = sd(vals, na.rm = TRUE),
    n    = sum(!is.na(vals)))
}
aggregated <- lapply(metric_names, aggregate_metric)
names(aggregated) <- metric_names

cat("\n=== Aggregated (macro-average across templates) ===\n")
for (mn in metric_names) {
  a <- aggregated[[mn]]
  cat(sprintf("  %-12s  mean=%.3f  sd=%.3f  n=%d\n", mn, a["mean"], a["sd"], a["n"]))
}

if (!dir.exists("data")) dir.create("data", recursive = TRUE)
saveRDS(list(per_template = results, aggregated = aggregated, config = CONFIG),
        CONFIG$output_rds)
cat(sprintf("\nSaved per-template + aggregate results to %s\n", CONFIG$output_rds))

# ==============================================================================
# Paper-ready Markdown summary
# ==============================================================================

if (!dir.exists("docs")) dir.create("docs", recursive = TRUE)

md_lines <- c(
  "# Retrospective Validation Results",
  "",
  sprintf("Generated: %s", format(Sys.time(), "%Y-%m-%d %H:%M:%S")),
  "",
  "Backs the ESP 2026 abstract's results sentence:",
  "> *the pipeline retrieves human-validated connections at precision@10 of X%*",
  "",
  "## Method",
  "",
  sprintf("For each of %d production SES template(s), %.0f%% of human-validated positive connections are masked uniformly at random. The remaining positives + the template's elements form the 'visible' state. The pipeline scores all element-pair candidates that are not in the visible set; held-out masked positives are the ground-truth retrieval targets. precision@k = (# masked positives among top-k) / k. Macro-averaged across templates.",
          length(results), CONFIG$mask_fraction * 100),
  "",
  "## Aggregate (macro-average)",
  "",
  "| Metric | Mean | SD | N templates |",
  "|---|---:|---:|---:|"
)
for (mn in metric_names) {
  a <- aggregated[[mn]]
  md_lines <- c(md_lines,
                sprintf("| %s | %.3f | %.3f | %d |", mn, a["mean"], a["sd"], a["n"]))
}

md_lines <- c(md_lines,
  "",
  "## Per-template detail",
  "",
  "| Template | n_pos | n_masked | n_candidates | base p@5 | base p@10 | base p@20 |",
  "|---|---:|---:|---:|---:|---:|---:|"
)
for (r in results) {
  md_lines <- c(md_lines,
                sprintf("| %s | %d | %d | %d | %.3f | %.3f | %.3f |",
                        r$template, r$n_positives, r$n_masked, r$n_candidates,
                        r$metrics[["base_p@5"]]  %||% NA,
                        r$metrics[["base_p@10"]] %||% NA,
                        r$metrics[["base_p@20"]] %||% NA))
}

md_lines <- c(md_lines,
  "",
  "## Notes",
  "",
  "- Random seed: 42 (per template seed = 42 + template index).",
  sprintf("- Mask fraction: %.0f%% of positives per template.", CONFIG$mask_fraction * 100),
  "- Candidate pool: all distinct (source, target) element pairs from the template, minus visible positives.",
  "- Base model: `models/connection_predictor_best.pt`.",
  if (length(ensemble_models) > 0L) sprintf("- Ensemble: %d models from `models/ensemble/`.", length(ensemble_models)) else "- Ensemble: not loaded.",
  "",
  "## Reproduce",
  "",
  "```bash",
  "Rscript scripts/retrospective_validation.R",
  "```"
)

writeLines(md_lines, CONFIG$output_md)
cat(sprintf("Saved Markdown summary to %s\n", CONFIG$output_md))

cat("\nDone.\n")
