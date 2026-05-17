# ==============================================================================
# Element Classifier (BERT chunk-classification head)
# ==============================================================================
#
# A small classification head trained on top of the existing
# sentence-transformer / vocabulary text embedding to predict which
# DAPSI(W)R(M) category a piece of free text belongs to.
#
# Architecture:
#   text → embed (128 or 384 dims) → linear(emb_dim, 128) → ReLU → dropout
#        → linear(128, 7) → softmax
#
# Why "BERT chunk-classification" in the abstract:
#   The text-encoder backbone is a pretrained sentence-transformer (a
#   BERT-family model — MiniLM is a distilled BERT). The classification
#   head sits on top of that fixed encoder. This is the standard
#   "BERT for sequence classification" pattern, just with a frozen
#   encoder so we don't need to fine-tune the whole transformer on
#   1300+ examples (which would overfit).
# ==============================================================================

if (!requireNamespace("torch", quietly = TRUE)) {
  stop("Package 'torch' is required.")
}

ELEMENT_CLASSIFIER_CATEGORIES <- c(
  "Drivers",
  "Activities",
  "Pressures",
  "Marine Processes & Functioning",
  "Ecosystem Services",
  "Goods & Benefits",
  "Responses"
)

ELEMENT_CLASSIFIER_EMBED_DIM <- 128L  # matches create_text_embedding default

#' Multi-layer perceptron classification head
#'
#' Sits on top of a frozen text embedding to predict DAPSI(W)R(M) category.
#'
#' @param embed_dim Integer. Input embedding dim (default 128).
#' @param hidden_dim Integer. Hidden layer dim (default 128).
#' @param n_classes Integer. Number of output classes (default 7).
#' @param dropout Numeric. Dropout rate (default 0.3).
#' @return torch nn_module
#' @export
element_classifier_head <- nn_module(
  "ElementClassifierHead",

  initialize = function(embed_dim = ELEMENT_CLASSIFIER_EMBED_DIM,
                        hidden_dim = 128L,
                        n_classes = length(ELEMENT_CLASSIFIER_CATEGORIES),
                        dropout = 0.3) {
    self$fc1 <- nn_linear(embed_dim, hidden_dim)
    self$drop <- nn_dropout(dropout)
    self$fc2 <- nn_linear(hidden_dim, n_classes)
  },

  forward = function(x) {
    x %>% self$fc1() %>% nnf_relu() %>% self$drop() %>% self$fc2()
  }
)

#' Predict DAPSI(W)R(M) category for free text
#'
#' Convenience function that runs the full pipeline:
#'   text → create_text_embedding → element_classifier_head → softmax
#'
#' Loads the trained classifier from models/element_classifier_best.pt
#' on first call; subsequent calls reuse the cached model.
#'
#' @param text Character. Free-text input (e.g., element name, sentence).
#' @param top_k Integer. Return top K predictions (default 3).
#' @return data.frame with columns: category, probability. Ordered by probability descending.
#' @export
predict_element_category <- function(text, top_k = 3L) {
  if (is.null(text) || nchar(trimws(as.character(text))) == 0L) {
    return(NULL)
  }

  if (!exists("create_text_embedding", mode = "function")) {
    stop("create_text_embedding not available. Source functions/ml_text_embeddings.R first.")
  }

  if (!exists(".element_classifier_cache", envir = globalenv())) {
    assign(".element_classifier_cache", new.env(parent = emptyenv()), envir = globalenv())
  }
  cache <- get(".element_classifier_cache", envir = globalenv())

  if (is.null(cache$model)) {
    model_path <- "models/element_classifier_best.pt"
    if (!file.exists(model_path)) {
      stop(sprintf("Trained classifier not found at %s. Run scripts/train_element_classifier.R first.", model_path))
    }
    cache$model <- torch_load(model_path)
    cache$model[["eval"]]()
  }

  emb <- as.numeric(create_text_embedding(text, dim = ELEMENT_CLASSIFIER_EMBED_DIM))
  x <- torch_tensor(matrix(emb, nrow = 1L), dtype = torch_float())
  with_no_grad({
    logits <- cache$model(x)
    probs <- as.numeric(nnf_softmax(logits, dim = 2L)$squeeze())
  })

  o <- order(probs, decreasing = TRUE)
  top <- head(o, top_k)
  data.frame(
    category    = ELEMENT_CLASSIFIER_CATEGORIES[top],
    probability = probs[top],
    stringsAsFactors = FALSE
  )
}

debug_log("Element classifier module loaded", "ML_CLASSIFIER")
