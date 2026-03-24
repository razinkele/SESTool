# functions/feedback_analyzer.R
# Feedback Log Analysis Utilities
# Purpose: Load the local NDJSON feedback log, compute text similarity for
#          duplicate detection, and mark entries as duplicates.
#
# Public API:
#   load_feedback_log(path)                             - parse NDJSON log
#   compute_text_similarity(texts)                      - TF-IDF cosine matrix
#   find_duplicate_pairs(df, threshold)                 - candidate duplicates
#   mark_as_duplicate(log_path, line_num, dup_of_line)  - write duplicate_of field


# ============================================================================
# load_feedback_log
# ============================================================================

#' Read and parse the NDJSON feedback log
#'
#' Reads line-by-line, skipping malformed lines.  Records physical line numbers
#' (1-based).  When GitHub succeeds the reporter appends a corrected entry with
#' the same title+timestamp; `load_feedback_log` deduplicates those by keeping
#' the last entry per (title, timestamp) pair.
#'
#' @param path  Path to the NDJSON file.
#' @return A data.frame with columns:
#'   line_num, type, title, description, steps, timestamp,
#'   github_url, duplicate_of
#'   Returns an empty data.frame (with those columns) when the file is absent
#'   or contains no parseable lines.
load_feedback_log <- function(path = "data/user_feedback_log.ndjson") {
  empty_df <- function() {
    data.frame(
      line_num     = integer(0),
      type         = character(0),
      title        = character(0),
      description  = character(0),
      steps        = character(0),
      timestamp    = character(0),
      github_url   = character(0),
      duplicate_of = character(0),
      stringsAsFactors = FALSE
    )
  }

  if (!file.exists(path)) {
    debug_log(paste("load_feedback_log: file not found:", path), "INFO")
    return(empty_df())
  }

  raw_lines <- tryCatch(
    readLines(path, warn = FALSE, encoding = "UTF-8"),
    error = function(e) {
      debug_log(paste("load_feedback_log: read error:", e$message), "ERROR")
      character(0)
    }
  )

  if (length(raw_lines) == 0L) return(empty_df())

  rows <- list()

  for (i in seq_along(raw_lines)) {
    line <- trimws(raw_lines[[i]])
    if (nchar(line) == 0L) next

    parsed <- tryCatch(
      jsonlite::fromJSON(line, simplifyVector = TRUE),
      error = function(e) NULL
    )

    if (is.null(parsed) || !is.list(parsed)) {
      debug_log(paste("load_feedback_log: skipping malformed line", i), "WARN")
      next
    }

    row <- list(
      line_num     = i,
      type         = as.character(parsed$type         %||% NA_character_),
      title        = as.character(parsed$title        %||% NA_character_),
      description  = as.character(parsed$description  %||% NA_character_),
      steps        = as.character(parsed$steps        %||% NA_character_),
      timestamp    = as.character(parsed$timestamp    %||% NA_character_),
      github_url   = as.character(parsed$github_url   %||% NA_character_),
      duplicate_of = as.character(parsed$duplicate_of %||% NA_character_)
    )
    rows[[length(rows) + 1L]] <- row
  }

  if (length(rows) == 0L) return(empty_df())

  df <- do.call(rbind, lapply(rows, as.data.frame,
                              stringsAsFactors = FALSE))

  # Deduplicate: when the reporter appends a corrected entry (same title +
  # timestamp, github_url filled in), keep the LAST occurrence.
  key <- paste(df$title, df$timestamp, sep = "\x01")
  # Work backwards so duplicated(..., fromLast=TRUE) keeps the last entry
  keep <- !duplicated(key, fromLast = TRUE)
  df   <- df[keep, , drop = FALSE]

  # Reset rownames
  rownames(df) <- NULL

  df
}


# ============================================================================
# compute_text_similarity
# ============================================================================

#' Compute pairwise TF-IDF cosine similarity for a character vector
#'
#' Pure base-R implementation; no external NLP packages required.
#'
#' @param texts  Character vector of documents.
#' @return An NxN numeric matrix of cosine similarities in [0, 1].
#'         Returns a 0-matrix when `length(texts) < 2` or all documents are
#'         empty / consist entirely of stopwords.
compute_text_similarity <- function(texts) {
  n <- length(texts)

  zero_matrix <- function(size) {
    m <- matrix(0.0, nrow = size, ncol = size)
    m
  }

  if (n < 2L) return(zero_matrix(n))

  # --- Stopwords (English, compact set) -------------------------------------
  stopwords <- c(
    "a", "an", "the", "and", "or", "but", "in", "on", "at", "to", "for",
    "of", "with", "by", "from", "is", "are", "was", "were", "be", "been",
    "being", "have", "has", "had", "do", "does", "did", "will", "would",
    "could", "should", "may", "might", "shall", "can", "not", "no", "nor",
    "so", "yet", "both", "either", "neither", "each", "few", "more",
    "most", "other", "some", "such", "than", "too", "very", "just",
    "that", "this", "these", "those", "i", "me", "my", "we", "our",
    "you", "your", "he", "she", "it", "its", "they", "them", "their",
    "what", "which", "who", "whom", "when", "where", "why", "how",
    "all", "any", "both", "if", "then", "because", "as", "until",
    "while", "about", "up", "out", "into", "through", "during",
    "before", "after", "above", "below", "between", "own", "same",
    "only", "also", "here", "there", "s", "t"
  )

  # --- Tokenise -------------------------------------------------------------
  tokenise <- function(text) {
    text  <- tolower(as.character(text))
    text  <- gsub("[^a-z0-9 ]", " ", text)
    tokens <- strsplit(trimws(text), "\\s+")[[1L]]
    tokens <- tokens[nchar(tokens) > 0L]
    tokens <- tokens[!tokens %in% stopwords]
    tokens
  }

  token_lists <- lapply(texts, tokenise)

  # Vocabulary
  vocab <- sort(unique(unlist(token_lists)))

  if (length(vocab) == 0L) return(zero_matrix(n))

  # --- TF matrix (rows = docs, cols = terms) --------------------------------
  tf_mat <- matrix(0.0, nrow = n, ncol = length(vocab))
  colnames(tf_mat) <- vocab

  for (i in seq_len(n)) {
    toks <- token_lists[[i]]
    if (length(toks) == 0L) next
    counts <- table(toks)
    idx    <- match(names(counts), vocab)
    valid  <- !is.na(idx)
    tf_mat[i, idx[valid]] <- as.numeric(counts[valid]) / length(toks)
  }

  # --- IDF (log(N / df) with +1 smoothing on df) ----------------------------
  df_vec <- colSums(tf_mat > 0)
  idf    <- log(n / (df_vec + 1L)) + 1.0   # add 1 to avoid negative idf

  # --- TF-IDF ---------------------------------------------------------------
  tfidf_mat <- tf_mat * matrix(idf, nrow = n, ncol = length(vocab), byrow = TRUE)

  # --- Cosine similarity ----------------------------------------------------
  norms <- sqrt(rowSums(tfidf_mat^2))

  sim_mat <- matrix(0.0, nrow = n, ncol = n)

  for (i in seq_len(n)) {
    for (j in seq_len(n)) {
      ni <- norms[i]
      nj <- norms[j]
      if (ni == 0 || nj == 0) {
        sim_mat[i, j] <- 0.0
      } else {
        sim_mat[i, j] <- sum(tfidf_mat[i, ] * tfidf_mat[j, ]) / (ni * nj)
      }
    }
  }

  sim_mat
}


# ============================================================================
# find_duplicate_pairs
# ============================================================================

#' Identify candidate duplicate feedback entries
#'
#' Filters out entries already marked as duplicates, computes TF-IDF cosine
#' similarity on title + description, and returns pairs above `threshold`.
#'
#' @param df         data.frame as returned by `load_feedback_log()`.
#' @param threshold  Numeric in [0, 1]; pairs with similarity >= threshold
#'                   are returned. Default 0.7.
#' @return data.frame with columns: line_num_a, line_num_b, similarity
#'         (sorted by descending similarity). Empty data.frame if fewer than
#'         2 un-marked entries remain.
find_duplicate_pairs <- function(df, threshold = 0.7) {
  empty_pairs <- data.frame(
    line_num_a = integer(0),
    line_num_b = integer(0),
    similarity = numeric(0),
    stringsAsFactors = FALSE
  )

  if (is.null(df) || nrow(df) < 2L) return(empty_pairs)

  # Filter out entries already marked as duplicates
  not_marked <- is.na(df$duplicate_of) | df$duplicate_of == "NA" |
                df$duplicate_of == ""
  df_clean <- df[not_marked, , drop = FALSE]

  if (nrow(df_clean) < 2L) return(empty_pairs)

  # Cap to 500 entries to avoid O(n^2) memory explosion
  if (nrow(df_clean) > 500L) {
    debug_log("find_duplicate_pairs: capping to 500 most recent entries", "WARN")
    df_clean <- df_clean[seq(nrow(df_clean) - 499L, nrow(df_clean)), , drop = FALSE]
  }

  texts <- paste(
    ifelse(is.na(df_clean$title), "", as.character(df_clean$title)),
    ifelse(is.na(df_clean$description), "", as.character(df_clean$description)),
    sep = " "
  )

  sim_mat <- compute_text_similarity(texts)

  m <- nrow(df_clean)
  pairs <- list()

  for (i in seq_len(m - 1L)) {
    for (j in seq(i + 1L, m)) {
      s <- sim_mat[i, j]
      if (s >= threshold) {
        pairs[[length(pairs) + 1L]] <- list(
          line_num_a = df_clean$line_num[i],
          line_num_b = df_clean$line_num[j],
          similarity = s
        )
      }
    }
  }

  if (length(pairs) == 0L) return(empty_pairs)

  result <- do.call(rbind, lapply(pairs, as.data.frame,
                                  stringsAsFactors = FALSE))
  result <- result[order(-result$similarity), , drop = FALSE]
  rownames(result) <- NULL
  result
}


# ============================================================================
# mark_as_duplicate
# ============================================================================

#' Add or update the `duplicate_of` field on a specific log line
#'
#' Reads all raw lines from `log_path`, parses the target line (identified by
#' its 1-based physical line number), sets `duplicate_of` to the URL / line
#' reference provided, serialises back to JSON, and atomically replaces the
#' file.
#'
#' @param log_path          Path to the NDJSON log file.
#' @param line_num          1-based physical line number to modify.
#' @param duplicate_of_line Character string; typically a GitHub URL or a
#'                          description of the original entry.
#' @return TRUE on success, FALSE on any error or out-of-range line_num.
mark_as_duplicate <- function(log_path, line_num, duplicate_of_line) {
  tryCatch({
    if (!file.exists(log_path)) {
      debug_log("mark_as_duplicate: file not found", "ERROR")
      return(FALSE)
    }

    raw_lines <- readLines(log_path, warn = FALSE, encoding = "UTF-8")

    if (line_num < 1L || line_num > length(raw_lines)) {
      debug_log(paste("mark_as_duplicate: line_num", line_num,
                      "out of range (1 -", length(raw_lines), ")"), "ERROR")
      return(FALSE)
    }

    target_raw <- trimws(raw_lines[[line_num]])
    if (nchar(target_raw) == 0L) {
      debug_log(paste("mark_as_duplicate: line", line_num, "is empty"), "ERROR")
      return(FALSE)
    }

    parsed <- tryCatch(
      jsonlite::fromJSON(target_raw, simplifyVector = TRUE),
      error = function(e) NULL
    )

    if (is.null(parsed) || !is.list(parsed)) {
      debug_log(paste("mark_as_duplicate: line", line_num, "is not valid JSON"),
                "ERROR")
      return(FALSE)
    }

    parsed$duplicate_of <- as.character(duplicate_of_line)

    raw_lines[[line_num]] <- jsonlite::toJSON(parsed, auto_unbox = TRUE)

    # Atomic write: write to temp file, then rename
    tmp_path <- paste0(log_path, ".tmp.", Sys.getpid())
    writeLines(raw_lines, con = tmp_path, useBytes = FALSE)
    rename_ok <- file.rename(tmp_path, log_path)
    if (!isTRUE(rename_ok)) {
      debug_log(paste("mark_as_duplicate: file.rename failed for line", line_num), "ERROR")
      try(file.remove(tmp_path), silent = TRUE)
      return(FALSE)
    }

    TRUE
  }, error = function(e) {
    debug_log(paste("mark_as_duplicate error:", e$message), "ERROR")
    FALSE
  })
}
