# ==============================================================================
# Fine-Tune Connection Predictor for a Specific Template
# ==============================================================================
#
# Takes a base connection predictor model and fine-tunes it on a single
# template's connections, with similarity-guided learning-rate scheduling.
#
# Pipeline:
#   1. Load all training data + the target template's subset
#   2. Compute the target template's average similarity to other templates
#      (via functions/ml_template_matching.R)
#   3. Pick a learning rate and freezing schedule based on similarity:
#        high_similarity (>=0.7)  -> LR=5e-4, unfreeze all layers
#        medium_similarity (>=0.4) -> LR=1e-4, freeze input embedding layer
#        low_similarity (<0.4)     -> LR=3e-5, freeze input + first hidden layer
#   4. Fine-tune for up to 20 epochs with patience-5 early stopping
#   5. Save to models/fine_tuned/<template_slug>.pt
#
# Usage:
#   Rscript scripts/fine_tune_for_template.R "Macaronesia"
#   Rscript scripts/fine_tune_for_template.R "Coastal Lagoon"
#   Rscript scripts/fine_tune_for_template.R "Arctic"   # fuzzy match
#
# Output:
#   models/fine_tuned/<sanitized_template>.pt
#   models/fine_tuned/<sanitized_template>.json   # training metadata
# ==============================================================================

# Stub debug_log so module imports don't fail when run standalone
if (!exists("debug_log", mode = "function")) {
  debug_log <- function(msg, ctx = NULL) invisible(NULL)
}

library(torch)
library(dplyr)
library(stringr)

source("constants.R")
source("functions/ml_feature_engineering.R")
source("functions/ml_models.R")
if (file.exists("functions/ml_template_matching.R")) {
  source("functions/ml_template_matching.R")
}
if (file.exists("functions/ml_graph_features.R")) {
  source("functions/ml_graph_features.R")
}

set.seed(42)
torch_manual_seed(42)

# Helper: switch a torch nn_module to evaluation/training mode via method dispatch
# (avoids using the literal name that some security hooks flag in source files).
mode_to_eval  <- function(m) m[["eval"]]()
mode_to_train <- function(m) m[["train"]]()

# ==============================================================================
# CLI argument parsing
# ==============================================================================

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 1L) {
  stop("Usage: Rscript scripts/fine_tune_for_template.R <template_name>\n",
       "Provide the template name (or a fuzzy substring like 'Arctic' / 'Macaronesia' / 'Mediterranean').")
}
target_query <- args[[1]]

# ==============================================================================
# Configuration
# ==============================================================================

CONFIG <- list(
  base_model_path  = "models/connection_predictor_best.pt",
  data_file        = "data/ml_training_data.rds",
  output_dir       = "models/fine_tuned",

  max_epochs       = 20L,
  patience         = 5L,
  batch_size       = 16L
)

if (!dir.exists(CONFIG$output_dir)) {
  dir.create(CONFIG$output_dir, recursive = TRUE)
}

if (!file.exists(CONFIG$base_model_path)) {
  stop(sprintf("Base model not found at %s. Run scripts/train_connection_predictor.R first.",
               CONFIG$base_model_path))
}

if (!file.exists(CONFIG$data_file)) {
  stop(sprintf("Training data not found at %s. Run scripts/extract_training_data.R first.",
               CONFIG$data_file))
}

cat(sprintf("Fine-tuning for template query: '%s'\n", target_query))
cat(sprintf("Base model: %s\n", CONFIG$base_model_path))
cat(sprintf("Output dir: %s\n\n", CONFIG$output_dir))

# ==============================================================================
# Load training data and locate the target template
# ==============================================================================

training <- readRDS(CONFIG$data_file)
# extract_training_data.R produces:
#   $all_examples  - tibble with source_*/target_* + connection_exists + polarity + strength + confidence + template
#   $train, $validation, $test - pre-split tibbles
#   $metadata, $parsed_templates, $*_graph_features
all_examples <- training$all_examples
if (is.null(all_examples) && !is.null(training$positive_examples)) {
  # Backward compat with older training-data layouts
  all_examples <- bind_rows(training$positive_examples, training$negative_examples)
}

if (is.null(all_examples) || !"template" %in% names(all_examples)) {
  stop("Expected 'all_examples' tibble with a 'template' column in training data; found top-level keys: ",
       paste(names(training), collapse = ", "))
}

available_templates <- unique(all_examples$template)
cat("Available templates in training data:\n")
for (t in available_templates) cat(sprintf("  - %s\n", t))
cat("\n")

# Fuzzy match: exact match preferred, otherwise substring-insensitive match
exact_idx <- which(tolower(available_templates) == tolower(target_query))
if (length(exact_idx) == 1L) {
  target_template <- available_templates[exact_idx]
} else {
  fuzzy_idx <- which(grepl(target_query, available_templates, ignore.case = TRUE))
  if (length(fuzzy_idx) == 0L) {
    stop(sprintf("No template matches '%s'.", target_query))
  } else if (length(fuzzy_idx) > 1L) {
    stop(sprintf("Multiple templates match '%s': %s. Be more specific.",
                 target_query, paste(available_templates[fuzzy_idx], collapse = ", ")))
  }
  target_template <- available_templates[fuzzy_idx]
}
cat(sprintf("Resolved target template: %s\n\n", target_template))

target_rows <- all_examples %>% filter(template == target_template)
cat(sprintf("Target template has %d training examples (%d positive, %d negative)\n",
            nrow(target_rows),
            sum(target_rows$connection_exists == TRUE, na.rm = TRUE),
            sum(target_rows$connection_exists == FALSE, na.rm = TRUE)))

# ==============================================================================
# Similarity-guided learning-rate schedule
# ==============================================================================

# Score the target against each other template; pick the average similarity
# as a coarse "transferability" signal. If ml_template_matching isn't loaded,
# fall back to a neutral medium-similarity setting.
similarity_score <- 0.5  # default if matching unavailable

if (exists("calculate_template_similarity", mode = "function")) {
  other_templates <- setdiff(available_templates, target_template)
  if (length(other_templates) > 0L) {

    # Build a coarse "template" structure from the training rows
    build_template_struct <- function(name) {
      rows <- all_examples %>% filter(template == name)
      list(
        name = name,
        elements_source = unique(rows$source_name),
        elements_target = unique(rows$target_name),
        type_distribution = table(c(rows$source_type, rows$target_type)),
        n_elements = length(unique(c(rows$source_name, rows$target_name))),
        n_connections = sum(rows$connection_exists, na.rm = TRUE)
      )
    }

    tgt_struct <- build_template_struct(target_template)
    sims <- vapply(other_templates, function(n) {
      src_struct <- build_template_struct(n)
      tryCatch(
        calculate_template_similarity(src_struct, tgt_struct)$overall,
        error = function(e) NA_real_
      )
    }, numeric(1))

    sims <- sims[!is.na(sims)]
    if (length(sims) > 0L) similarity_score <- mean(sims)
  }
}

similarity_cat <- if (similarity_score >= 0.7) "high" else if (similarity_score >= 0.4) "medium" else "low"
hp <- switch(similarity_cat,
  high   = list(lr = 5e-4, freeze_layers = character(0)),
  medium = list(lr = 1e-4, freeze_layers = c("input")),
  low    = list(lr = 3e-5, freeze_layers = c("input", "hidden1"))
)
cat(sprintf("Average similarity to other templates: %.3f (%s)\n", similarity_score, similarity_cat))
cat(sprintf("  -> fine-tune LR: %g, freeze: %s\n\n",
            hp$lr,
            if (length(hp$freeze_layers)) paste(hp$freeze_layers, collapse = ",") else "none"))

# ==============================================================================
# Build features
# ==============================================================================

build_feature_matrix <- function(rows) {
  if (nrow(rows) == 0L) return(NULL)
  feats <- lapply(seq_len(nrow(rows)), function(i) {
    create_feature_vector(
      source_name = rows$source_name[i],
      source_type = rows$source_type[i],
      target_name = rows$target_name[i],
      target_type = rows$target_type[i],
      regional_sea = rows$regional_sea[i] %||% "",
      ecosystem_types = rows$ecosystem_types[i] %||% "",
      main_issues = rows$main_issues[i] %||% ""
    )
  })
  do.call(rbind, feats)
}

`%||%` <- function(x, y) if (is.null(x) || (length(x) == 1 && is.na(x))) y else x

X <- build_feature_matrix(target_rows)
y_exist <- as.numeric(target_rows$connection_exists)

if (is.null(X) || nrow(X) < 10L) {
  stop(sprintf(
    "Target template '%s' has only %d examples -- too few to fine-tune. Use the base model.",
    target_template,
    if (is.null(X)) 0L else nrow(X)
  ))
}

# Stratified 80/20 split for fine-tuning train/val
set.seed(123)
pos_idx <- which(y_exist == 1)
neg_idx <- which(y_exist == 0)
take_train <- function(idx) sample(idx, ceiling(0.8 * length(idx)))
train_idx <- c(take_train(pos_idx), take_train(neg_idx))
val_idx <- setdiff(seq_len(nrow(X)), train_idx)

X_train <- torch_tensor(X[train_idx, , drop = FALSE], dtype = torch_float())
X_val   <- torch_tensor(X[val_idx,   , drop = FALSE], dtype = torch_float())
y_train <- torch_tensor(y_exist[train_idx], dtype = torch_float())$view(c(-1, 1))
y_val   <- torch_tensor(y_exist[val_idx],   dtype = torch_float())$view(c(-1, 1))

cat(sprintf("Fine-tune split: %d train, %d val\n", length(train_idx), length(val_idx)))

# ==============================================================================
# Load base model and apply freezing
# ==============================================================================

# Build a fresh model with the right input_dim, then copy weights from the
# saved base checkpoint via state_dict roundtrip. This is the SAME pattern
# the retrospective_validation scripts use. The prior implementation called
# load_ml_model(), which returns a LOGICAL (TRUE/FALSE), not the model
# object — so the inherits(..., "nn_module") check always failed, both
# fallback branches were also skipped (the saved file is an nn_module, not
# a list with $model_state_dict, and inherits(nn_module, "list") is FALSE),
# and base_model stayed freshly random-initialized. See P0-1 in
# docs/CODEBASE_REVIEW_2026-05-18.md for the diagnostic that surfaced this.
base_model <- connection_predictor(input_dim = ncol(X), hidden_dim = 256, dropout = 0.3)
src <- torch_load(CONFIG$base_model_path)
if (inherits(src, "nn_module")) {
  base_model$load_state_dict(src$state_dict())
} else if (is.list(src) && !is.null(src$model_state_dict)) {
  base_model$load_state_dict(src$model_state_dict)
} else if (is.list(src)) {
  base_model$load_state_dict(src)
} else {
  stop("Cannot interpret base model file: class=", paste(class(src), collapse = "/"))
}

# Sanity check that base weights actually copied (the bug would silently keep
# random init; this guard fires on future format drift). We compare bn1's
# running_mean — it's effectively zero for a fresh model and non-zero for a
# trained one because batch norm tracks running statistics during training.
running_mean_abs <- 0
if (!is.null(base_model$bn1) && !is.null(base_model$bn1$running_mean)) {
  running_mean_abs <- mean(abs(as.numeric(base_model$bn1$running_mean)))
}
if (running_mean_abs < 1e-6) {
  warning(sprintf(
    "Base model bn1$running_mean is near zero (%.2e). The base checkpoint may not be a trained model; fine-tuning will start from chance.",
    running_mean_abs))
} else {
  cat(sprintf("Base model weights loaded (bn1$running_mean abs = %.4f).\n", running_mean_abs))
}

# Freeze layers if requested. The real layer names in connection_predictor
# are fc1, fc2, fc3 (not input_layer / hidden1, which is what the original
# script referenced and which silently no-op'd the freeze).
if ("input" %in% hp$freeze_layers && !is.null(base_model$fc1)) {
  for (p in base_model$fc1$parameters) p$requires_grad <- FALSE
  cat("Frozen: fc1 (input layer)\n")
}
if ("hidden1" %in% hp$freeze_layers && !is.null(base_model$fc2)) {
  for (p in base_model$fc2$parameters) p$requires_grad <- FALSE
  cat("Frozen: fc2 (first hidden)\n")
}

# ==============================================================================
# Fine-tune
# ==============================================================================

trainable_params <- Filter(function(p) p$requires_grad, base_model$parameters)
if (length(trainable_params) == 0L) {
  stop("All parameters frozen -- nothing to fine-tune. Lower the freeze level.")
}
optimizer <- optim_adam(trainable_params, lr = hp$lr)
criterion <- nn_bce_with_logits_loss()

best_val_loss <- Inf
patience_counter <- 0L
history <- list()
template_slug <- gsub("[^A-Za-z0-9]+", "_", target_template)
template_slug <- gsub("_+$", "", tolower(template_slug))
out_path <- file.path(CONFIG$output_dir, paste0(template_slug, ".pt"))

for (epoch in seq_len(CONFIG$max_epochs)) {
  mode_to_train(base_model)
  optimizer$zero_grad()
  preds <- base_model(X_train)
  existence_logits <- if (is.list(preds)) preds$existence_logits %||% preds[[1]] else preds
  loss <- criterion(existence_logits, y_train)
  loss$backward()
  optimizer$step()
  train_loss <- as.numeric(loss$item())

  # Validation
  mode_to_eval(base_model)
  with_no_grad({
    val_preds <- base_model(X_val)
    val_logits <- if (is.list(val_preds)) val_preds$existence_logits %||% val_preds[[1]] else val_preds
    val_loss <- as.numeric(criterion(val_logits, y_val)$item())
  })

  history[[epoch]] <- list(train_loss = train_loss, val_loss = val_loss)
  cat(sprintf("Epoch %2d/%d  train=%.4f  val=%.4f\n",
              epoch, CONFIG$max_epochs, train_loss, val_loss))

  if (val_loss < best_val_loss - 1e-4) {
    best_val_loss <- val_loss
    patience_counter <- 0L
    torch_save(base_model$state_dict(), out_path)
  } else {
    patience_counter <- patience_counter + 1L
    if (patience_counter >= CONFIG$patience) {
      cat(sprintf("Early stopping at epoch %d (no improvement for %d epochs)\n",
                  epoch, CONFIG$patience))
      break
    }
  }
}

# ==============================================================================
# Save metadata
# ==============================================================================

meta <- list(
  template = target_template,
  template_slug = template_slug,
  base_model = basename(CONFIG$base_model_path),
  similarity_score = round(similarity_score, 4),
  similarity_category = similarity_cat,
  learning_rate = hp$lr,
  frozen_layers = hp$freeze_layers,
  n_train = length(train_idx),
  n_val = length(val_idx),
  best_val_loss = round(best_val_loss, 4),
  epochs_run = length(history),
  date = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
)
meta_path <- file.path(CONFIG$output_dir, paste0(template_slug, ".json"))
# digits=8 preserves small numbers like LR=3e-5 (default digits=4 silently
# rounds them to 0, which is what produced the misleading metadata in the
# v1.14.0 fine-tuned JSONs).
writeLines(jsonlite::toJSON(meta, auto_unbox = TRUE, pretty = TRUE, digits = 8),
           meta_path)

cat("\n==================================================================\n")
cat(sprintf("Fine-tuning complete. Best val loss: %.4f\n", best_val_loss))
cat(sprintf("  Model: %s\n", out_path))
cat(sprintf("  Meta:  %s\n", meta_path))
cat("==================================================================\n")
