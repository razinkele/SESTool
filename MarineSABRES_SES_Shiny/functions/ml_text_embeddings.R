# functions/ml_text_embeddings.R
# Advanced Text Embeddings Module
# ==============================================================================
#
# Provides multiple text embedding strategies for element names:
# 1. Vocabulary-based (current default): Marine-specific vocab matching
# 2. FastText: Pre-trained word embeddings (when available)
# 3. Custom: Domain-specific trained embeddings
#
# Benefits of FastText over vocabulary matching:
# - Handles out-of-vocabulary words via subword embeddings
# - Captures semantic similarity (e.g., "fish" ~ "fishing")
# - Pre-trained on large corpora (300-dim vectors)
#
# ==============================================================================

# ==============================================================================
# Embedding Strategy Registry
# ==============================================================================

.embedding_env <- new.env(parent = emptyenv())
.embedding_env$strategy <- "vocabulary"  # Default strategy
.embedding_env$fasttext_model <- NULL
.embedding_env$custom_embeddings <- NULL
.embedding_env$cache <- new.env(hash = TRUE, parent = emptyenv())

#' Available embedding strategies
EMBEDDING_STRATEGIES <- c("vocabulary", "fasttext", "custom", "hybrid")

# ==============================================================================
# Strategy Selection
# ==============================================================================

#' Set the text embedding strategy
#'
#' @param strategy One of "vocabulary", "fasttext", "custom", "hybrid"
#' @return Previous strategy setting
#' @export
set_embedding_strategy <- function(strategy) {
  if (!strategy %in% EMBEDDING_STRATEGIES) {
    stop(sprintf("Invalid strategy '%s'. Choose from: %s",
                 strategy, paste(EMBEDDING_STRATEGIES, collapse = ", ")))
  }

  old <- .embedding_env$strategy
  .embedding_env$strategy <- strategy

  debug_log(sprintf("Embedding strategy changed: %s -> %s", old, strategy), "EMBEDDINGS")

  invisible(old)
}

#' Get current embedding strategy
#'
#' @return Current embedding strategy name
#' @export
get_embedding_strategy <- function() {
  .embedding_env$strategy
}

#' Check if FastText is available
#'
#' @return TRUE if FastText can be used
#' @export
fasttext_available <- function() {
  !is.null(.embedding_env$fasttext_model) ||
    requireNamespace("fastrtext", quietly = TRUE) ||
    requireNamespace("word2vec", quietly = TRUE)
}

# ==============================================================================
# FastText Integration
# ==============================================================================

#' Load FastText model
#'
#' @param model_path Path to FastText .bin or .vec file
#' @return TRUE if load succeeded
#' @export
load_fasttext_model <- function(model_path) {
  if (!file.exists(model_path)) {
    debug_log(sprintf("FastText model not found: %s", model_path), "EMBEDDINGS_ERROR")
    return(FALSE)
  }

  # Try fastrtext package first
  if (requireNamespace("fastrtext", quietly = TRUE)) {
    tryCatch({
      .embedding_env$fasttext_model <- fastrtext::load_model(model_path)
      .embedding_env$fasttext_dim <- fastrtext::get_word_vectors_dim(.embedding_env$fasttext_model)
      debug_log(sprintf("Loaded FastText model (fastrtext): %s, dim=%d",
                        model_path, .embedding_env$fasttext_dim), "EMBEDDINGS")
      return(TRUE)
    }, error = function(e) {
      debug_log(sprintf("fastrtext load failed: %s", e$message), "EMBEDDINGS_ERROR")
    })
  }

  # Try word2vec package as fallback
  if (requireNamespace("word2vec", quietly = TRUE)) {
    tryCatch({
      .embedding_env$fasttext_model <- word2vec::read.wordvectors(model_path)
      .embedding_env$fasttext_dim <- ncol(.embedding_env$fasttext_model)
      debug_log(sprintf("Loaded FastText model (word2vec): %s, dim=%d",
                        model_path, .embedding_env$fasttext_dim), "EMBEDDINGS")
      return(TRUE)
    }, error = function(e) {
      debug_log(sprintf("word2vec load failed: %s", e$message), "EMBEDDINGS_ERROR")
    })
  }

  debug_log("No FastText package available (fastrtext or word2vec)", "EMBEDDINGS_ERROR")
  FALSE
}

#' Unload FastText model to free memory
#'
#' @export
unload_fasttext_model <- function() {
  .embedding_env$fasttext_model <- NULL
  .embedding_env$fasttext_dim <- NULL
  gc()
  debug_log("Unloaded FastText model", "EMBEDDINGS")
}

#' Get FastText embedding for a word
#'
#' @param word Word to embed
#' @return Numeric vector (FastText dimension) or NULL
#' @keywords internal
get_fasttext_vector <- function(word) {
  if (is.null(.embedding_env$fasttext_model)) {
    return(NULL)
  }

  word <- tolower(trimws(word))

  # Handle fastrtext model
  if (inherits(.embedding_env$fasttext_model, "fasttext")) {
    tryCatch({
      vec <- fastrtext::get_word_vectors(.embedding_env$fasttext_model, word)
      return(as.numeric(vec))
    }, error = function(e) NULL)
  }

  # Handle word2vec matrix format
  if (is.matrix(.embedding_env$fasttext_model)) {
    if (word %in% rownames(.embedding_env$fasttext_model)) {
      return(.embedding_env$fasttext_model[word, ])
    }
  }

  NULL
}

#' Get FastText embedding for text (average of word vectors)
#'
#' @param text Text to embed
#' @param dim Target dimension (default: model dimension)
#' @return Numeric vector of embeddings
#' @export
get_fasttext_embedding <- function(text, dim = NULL) {
  if (is.null(.embedding_env$fasttext_model)) {
    stop("FastText model not loaded. Call load_fasttext_model() first.")
  }

  if (is.null(dim)) {
    dim <- .embedding_env$fasttext_dim %||% 300
  }

  # Tokenize text
  words <- tokenize_text(text)

  if (length(words) == 0) {
    return(rep(0, dim))
  }

  # Get embeddings for each word
  embeddings <- lapply(words, get_fasttext_vector)
  embeddings <- Filter(Negate(is.null), embeddings)

  if (length(embeddings) == 0) {
    return(rep(0, dim))
  }

  # Average embeddings
  avg_embedding <- Reduce(`+`, embeddings) / length(embeddings)

  # Ensure correct dimension (truncate or pad)
  if (length(avg_embedding) > dim) {
    avg_embedding <- avg_embedding[1:dim]
  } else if (length(avg_embedding) < dim) {
    avg_embedding <- c(avg_embedding, rep(0, dim - length(avg_embedding)))
  }

  avg_embedding
}

# ==============================================================================
# Custom Embeddings
# ==============================================================================

#' Load custom domain-specific embeddings
#'
#' @param embeddings Named list or matrix where names are words/phrases
#' @return TRUE if load succeeded
#' @export
load_custom_embeddings <- function(embeddings) {
  if (is.matrix(embeddings) && !is.null(rownames(embeddings))) {
    .embedding_env$custom_embeddings <- embeddings
    .embedding_env$custom_dim <- ncol(embeddings)
  } else if (is.list(embeddings)) {
    # Convert list to matrix
    .embedding_env$custom_embeddings <- do.call(rbind, embeddings)
    .embedding_env$custom_dim <- length(embeddings[[1]])
  } else {
    stop("Embeddings must be a named matrix or list of vectors")
  }

  debug_log(sprintf("Loaded custom embeddings: %d terms, dim=%d",
                    nrow(.embedding_env$custom_embeddings),
                    .embedding_env$custom_dim), "EMBEDDINGS")
  TRUE
}

#' Get custom embedding for text
#'
#' @param text Text to embed
#' @param dim Target dimension
#' @return Numeric vector
#' @keywords internal
get_custom_embedding <- function(text, dim = 128) {
  if (is.null(.embedding_env$custom_embeddings)) {
    return(rep(0, dim))
  }

  text_lower <- tolower(trimws(text))
  embeddings <- .embedding_env$custom_embeddings

  # Try exact match first
  if (text_lower %in% rownames(embeddings)) {
    vec <- embeddings[text_lower, ]
    return(ensure_dimension(vec, dim))
  }

  # Try word-by-word matching
  words <- tokenize_text(text)
  matched <- sapply(words, function(w) {
    if (w %in% rownames(embeddings)) embeddings[w, ] else NULL
  }, simplify = FALSE)

  matched <- Filter(Negate(is.null), matched)

  if (length(matched) == 0) {
    return(rep(0, dim))
  }

  avg <- Reduce(`+`, matched) / length(matched)
  ensure_dimension(avg, dim)
}

# ==============================================================================
# Main Embedding Interface
# ==============================================================================

#' Create text embedding using current strategy
#'
#' This is the main function for getting text embeddings. It uses the
#' currently configured strategy (vocabulary, fasttext, custom, or hybrid).
#'
#' @param text Text to embed (element name, description, etc.)
#' @param dim Target dimension (default 128)
#' @return Numeric vector of specified dimension
#' @export
create_text_embedding <- function(text, dim = 128) {
  if (is.null(text) || text == "") {
    return(rep(0, dim))
  }

  # Check cache first
  cache_key <- paste(text, dim, .embedding_env$strategy, sep = "|")
  cached <- get0(cache_key, envir = .embedding_env$cache, ifnotfound = NULL)
  if (!is.null(cached)) {
    return(cached)
  }

  # Get embedding based on strategy
  embedding <- switch(.embedding_env$strategy,
    "vocabulary" = create_vocabulary_embedding(text, dim),
    "fasttext" = {
      if (!is.null(.embedding_env$fasttext_model)) {
        get_fasttext_embedding(text, dim)
      } else {
        create_vocabulary_embedding(text, dim)
      }
    },
    "custom" = get_custom_embedding(text, dim),
    "hybrid" = create_hybrid_embedding(text, dim),
    create_vocabulary_embedding(text, dim)  # Default fallback
  )

  # Cache result
  assign(cache_key, embedding, envir = .embedding_env$cache)

  embedding
}

#' Create vocabulary-based embedding
#'
#' Uses marine-specific vocabulary matching from ml_feature_engineering.R
#'
#' @param text Text to embed
#' @param dim Target dimension
#' @return Numeric vector
#' @keywords internal
create_vocabulary_embedding <- function(text, dim = 128) {
  # Use existing implementation from ml_feature_engineering.R
  if (exists("create_element_embedding", mode = "function")) {
    return(create_element_embedding(text, dim))
  }

  # Fallback: simple bag-of-words
  words <- tokenize_text(text)
  features <- numeric(dim)

  # Hash words into feature space
  for (word in words) {
    idx <- (digest::digest(word, algo = "xxhash32", serialize = FALSE) %% dim) + 1
    features[idx] <- features[idx] + 1
  }

  # Normalize
  norm <- sqrt(sum(features^2))
  if (norm > 0) features <- features / norm

  features
}

#' Create hybrid embedding (vocabulary + FastText weighted average)
#'
#' @param text Text to embed
#' @param dim Target dimension
#' @param vocab_weight Weight for vocabulary embedding (0-1)
#' @return Numeric vector
#' @keywords internal
create_hybrid_embedding <- function(text, dim = 128, vocab_weight = 0.3) {
  vocab_emb <- create_vocabulary_embedding(text, dim)

  if (!is.null(.embedding_env$fasttext_model)) {
    ft_emb <- get_fasttext_embedding(text, dim)
    # Weighted combination
    embedding <- vocab_weight * vocab_emb + (1 - vocab_weight) * ft_emb
    # Re-normalize
    norm <- sqrt(sum(embedding^2))
    if (norm > 0) embedding <- embedding / norm
    return(embedding)
  }

  vocab_emb
}

# ==============================================================================
# Helper Functions
# ==============================================================================

#' Tokenize text into words
#'
#' @param text Text to tokenize
#' @return Character vector of words
#' @keywords internal
tokenize_text <- function(text) {
  if (is.null(text) || text == "") return(character())

  text <- tolower(text)
  text <- gsub("[^a-z0-9\\s-]", " ", text)  # Keep alphanumeric, spaces, hyphens
  words <- strsplit(text, "\\s+")[[1]]
  words <- words[nchar(words) > 1]  # Filter single characters

  words
}

#' Ensure vector has specified dimension
#'
#' @param vec Numeric vector
#' @param dim Target dimension
#' @return Vector of exactly dim length
#' @keywords internal
ensure_dimension <- function(vec, dim) {
  if (length(vec) > dim) {
    vec[1:dim]
  } else if (length(vec) < dim) {
    c(vec, rep(0, dim - length(vec)))
  } else {
    vec
  }
}

#' Clear embedding cache
#'
#' @export
clear_embedding_cache <- function() {
  rm(list = ls(.embedding_env$cache), envir = .embedding_env$cache)
  debug_log("Cleared embedding cache", "EMBEDDINGS")
}

#' Get embedding statistics
#'
#' @return List with strategy, dimensions, cache size
#' @export
get_embedding_stats <- function() {
  list(
    strategy = .embedding_env$strategy,
    fasttext_loaded = !is.null(.embedding_env$fasttext_model),
    fasttext_dim = .embedding_env$fasttext_dim %||% NA,
    custom_loaded = !is.null(.embedding_env$custom_embeddings),
    custom_terms = if (!is.null(.embedding_env$custom_embeddings))
                     nrow(.embedding_env$custom_embeddings) else 0,
    cache_size = length(ls(.embedding_env$cache))
  )
}

# Null coalescing operator
`%||%` <- function(x, y) if (is.null(x)) y else x
