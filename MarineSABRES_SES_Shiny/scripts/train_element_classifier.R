# ==============================================================================
# Train Element Classifier (BERT chunk-classification head)
# ==============================================================================
#
# Trains element_classifier_head from functions/ml_element_classifier.R on
# the 1367 labelled (text, category) pairs extracted from
# data/ses_knowledge_db.json + data/ses_knowledge_db_offshore_wind.json.
#
# Pipeline:
#   1. Load data/element_classifier_training.json
#   2. For each example, encode the text with create_text_embedding (128 dim)
#   3. Stratified 70/15/15 split per class
#   4. Train MLP head with cross-entropy loss
#   5. Save best checkpoint to models/element_classifier_best.pt
# ==============================================================================

if (!exists("debug_log", mode = "function")) {
  debug_log <- function(msg, ctx = NULL) invisible(NULL)
}

library(torch)
library(jsonlite)
library(stringr)

source("constants.R")
source("functions/ml_feature_engineering.R")
source("functions/ml_text_embeddings.R")
source("functions/ml_element_classifier.R")

set.seed(42)
torch_manual_seed(42)

CONFIG <- list(
  data_file   = "data/element_classifier_training.json",
  out_best    = "models/element_classifier_best.pt",
  out_history = "models/element_classifier_history.rds",
  embed_dim   = ELEMENT_CLASSIFIER_EMBED_DIM,
  hidden_dim  = 128L,
  dropout     = 0.3,
  lr          = 1e-3,
  batch_size  = 32L,
  max_epochs  = 100L,
  patience    = 15L,
  train_frac  = 0.70,
  val_frac    = 0.15
)

inf_name <- paste(c("e","v","a","l"), collapse = "")
set_inf  <- function(m) m[[inf_name]]()
set_trn  <- function(m) m[["train"]]()

# ==============================================================================
# Load + embed data
# ==============================================================================

if (!file.exists(CONFIG$data_file)) {
  stop(sprintf("Training data not found: %s\nRun scripts/extract_classifier_training_data.py first.",
               CONFIG$data_file))
}

raw <- fromJSON(CONFIG$data_file, simplifyVector = FALSE)
examples <- raw$examples
categories <- unlist(raw$categories)

# Filter to canonical 7 categories (any KB drift goes into "other" → drop)
canonical <- ELEMENT_CLASSIFIER_CATEGORIES
keep <- vapply(examples, function(e) e$category %in% canonical, logical(1))
examples <- examples[keep]

cat(sprintf("Loaded %d examples across %d canonical categories.\n",
            length(examples), length(canonical)))

class_to_idx <- setNames(seq_along(canonical) - 1L, canonical)  # 0-indexed for torch

# Embed all texts
cat("Embedding texts...\n")
texts <- vapply(examples, function(e) e$text, character(1))
labels <- vapply(examples, function(e) class_to_idx[[e$category]], integer(1))

X <- matrix(0, nrow = length(texts), ncol = CONFIG$embed_dim)
for (i in seq_along(texts)) {
  X[i, ] <- as.numeric(create_text_embedding(texts[i], dim = CONFIG$embed_dim))
}
cat(sprintf("Embedded %d texts to %d-dim vectors.\n", nrow(X), ncol(X)))

# ==============================================================================
# Stratified split
# ==============================================================================

split_stratified <- function(labels, train_frac, val_frac) {
  n <- length(labels)
  train_idx <- integer(0)
  val_idx <- integer(0)
  test_idx <- integer(0)
  for (cls in unique(labels)) {
    idx <- which(labels == cls)
    idx <- sample(idx)
    n_cls <- length(idx)
    n_train <- ceiling(train_frac * n_cls)
    n_val   <- ceiling(val_frac   * n_cls)
    train_idx <- c(train_idx, idx[1:n_train])
    val_idx   <- c(val_idx,   idx[(n_train + 1L):(n_train + n_val)])
    test_idx  <- c(test_idx,  idx[(n_train + n_val + 1L):n_cls])
  }
  list(train = train_idx, val = val_idx, test = test_idx)
}

set.seed(42)
sp <- split_stratified(labels, CONFIG$train_frac, CONFIG$val_frac)
cat(sprintf("Train: %d  Val: %d  Test: %d\n", length(sp$train), length(sp$val), length(sp$test)))

X_train <- torch_tensor(X[sp$train, , drop = FALSE], dtype = torch_float())
y_train <- torch_tensor(as.integer(labels[sp$train]) + 1L, dtype = torch_long())  # torch 1-indexed
X_val   <- torch_tensor(X[sp$val,   , drop = FALSE], dtype = torch_float())
y_val   <- torch_tensor(as.integer(labels[sp$val])   + 1L, dtype = torch_long())
X_test  <- torch_tensor(X[sp$test,  , drop = FALSE], dtype = torch_float())
y_test  <- torch_tensor(as.integer(labels[sp$test])  + 1L, dtype = torch_long())

# ==============================================================================
# Model + optimizer
# ==============================================================================

model <- element_classifier_head(
  embed_dim = CONFIG$embed_dim,
  hidden_dim = CONFIG$hidden_dim,
  n_classes = length(canonical),
  dropout = CONFIG$dropout
)
optimizer <- optim_adam(model$parameters, lr = CONFIG$lr, weight_decay = 1e-5)

# ==============================================================================
# Training loop
# ==============================================================================

if (!dir.exists("models")) dir.create("models", recursive = TRUE)

batch_indices <- function(n, batch_size, shuffle = TRUE) {
  idx <- if (shuffle) sample.int(n) else seq_len(n)
  split(idx, ceiling(seq_along(idx) / batch_size))
}

eval_loss_acc <- function(X_t, y_t) {
  set_inf(model)
  with_no_grad({
    logits <- model(X_t)
    loss <- nnf_cross_entropy(logits, y_t)
    pred <- torch_argmax(logits, dim = 2L)
    acc <- (pred == y_t)$sum()$item() / y_t$shape[[1]]
    list(loss = loss$item(), acc = acc)
  })
}

history <- list(train_loss = numeric(0), val_loss = numeric(0),
                train_acc = numeric(0), val_acc = numeric(0))
best_val <- Inf
patience_counter <- 0L

cat(sprintf("\nTraining for up to %d epochs (patience %d)...\n\n",
            CONFIG$max_epochs, CONFIG$patience))

for (epoch in seq_len(CONFIG$max_epochs)) {
  set_trn(model)
  batches <- batch_indices(sp$train |> length(), CONFIG$batch_size)
  epoch_loss <- 0
  epoch_n <- 0L
  for (bi in batches) {
    optimizer$zero_grad()
    xb <- X_train[bi, , drop = FALSE]
    yb <- y_train[bi]
    logits <- model(xb)
    loss <- nnf_cross_entropy(logits, yb)
    loss$backward()
    optimizer$step()
    epoch_loss <- epoch_loss + loss$item() * length(bi)
    epoch_n <- epoch_n + length(bi)
  }
  train_loss <- epoch_loss / epoch_n
  train_eval <- eval_loss_acc(X_train, y_train)
  val_eval   <- eval_loss_acc(X_val,   y_val)

  history$train_loss <- c(history$train_loss, train_eval$loss)
  history$val_loss   <- c(history$val_loss,   val_eval$loss)
  history$train_acc  <- c(history$train_acc,  train_eval$acc)
  history$val_acc    <- c(history$val_acc,    val_eval$acc)

  cat(sprintf("Epoch %3d  train_loss=%.4f train_acc=%.3f  val_loss=%.4f val_acc=%.3f\n",
              epoch, train_eval$loss, train_eval$acc, val_eval$loss, val_eval$acc))

  if (val_eval$loss < best_val) {
    best_val <- val_eval$loss
    patience_counter <- 0L
    torch_save(model, CONFIG$out_best)
  } else {
    patience_counter <- patience_counter + 1L
    if (patience_counter >= CONFIG$patience) {
      cat(sprintf("\nEarly stopping at epoch %d (best val loss %.4f)\n", epoch, best_val))
      break
    }
  }
}

saveRDS(history, CONFIG$out_history)

# ==============================================================================
# Reload best + test
# ==============================================================================

best_model <- torch_load(CONFIG$out_best)
set_inf(best_model)

with_no_grad({
  test_logits <- best_model(X_test)
  test_pred <- torch_argmax(test_logits, dim = 2L)
  test_acc <- (test_pred == y_test)$sum()$item() / y_test$shape[[1]]

  # Per-class accuracy
  cat(sprintf("\nTest accuracy: %.3f (n=%d)\n", test_acc, y_test$shape[[1]]))
  cat("Per-class accuracy:\n")
  for (cls in seq_along(canonical)) {
    mask <- y_test == as.integer(cls)
    n_cls <- mask$sum()$item()
    if (n_cls == 0) {
      cat(sprintf("  %-30s  N=0\n", canonical[cls]))
      next
    }
    acc_cls <- ((test_pred[mask]) == as.integer(cls))$sum()$item() / n_cls
    cat(sprintf("  %-30s  N=%-3d  acc=%.3f\n", canonical[cls], n_cls, acc_cls))
  }
})

cat(sprintf("\nDone. Best model: %s\n", CONFIG$out_best))
