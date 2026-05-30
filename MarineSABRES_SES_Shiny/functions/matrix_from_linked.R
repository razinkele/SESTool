# functions/matrix_from_linked.R
# Pure helpers for the N:M LinkedX representation used by Standard Entry.
# - parse_linked(x):   "GB001|GB002" -> c("GB001","GB002") with NULL/NA/"" -> character(0)
# - serialize_linked(): inverse, filtering empty strings before paste
# - assert_matrices_aligned(): dim+dimname sanity check between adjacency and user_edited
# - rebuild_matrix_from_linked(): the main rebuilder, returns a 4-element list
#
# All functions are dependency-free (no Shiny / no i18n). Used by the form
# validate/collect step and by save_ex* observers in isa_data_entry_module.R.

#' Split a '|'-delimited string of IDs into a character vector
#' @param x scalar character (or NULL/NA). "" / NULL / NA -> character(0).
#' @return character vector with empty segments filtered.
parse_linked <- function(x) {
  if (is.null(x) || length(x) == 0) return(character(0))
  if (is.na(x[1])) return(character(0))
  s <- as.character(x[1])
  if (!nzchar(s)) return(character(0))
  Filter(nzchar, strsplit(s, "|", fixed = TRUE)[[1]])
}

#' Join a character vector of IDs into a '|'-delimited string
#' @param ids character vector (or NULL/character(0)).
#' @return single character string. Empty input -> "". Filters empty strings.
serialize_linked <- function(ids) {
  if (is.null(ids) || length(ids) == 0) return("")
  paste(Filter(nzchar, as.character(ids)), collapse = "|")
}

#' Normalize an ISA "Linked to..." select value to bare element IDs
#'
#' The ISA dropdowns historically stored the LABEL form "GB001: Food" as their
#' value; the reconciler needs bare IDs ("GB001"). This strips a ": Label"
#' suffix from each segment, so it accepts BOTH the legacy label form and an
#' already-bare/pipe-delimited id list — keeping previously-saved projects'
#' links valid (see feedback #4).
#' @param x select value: "", "GB001", "GB001: Food", or "GB001|GB002: Tourism"
#' @return single '|'-delimited string of bare IDs ("" when empty).
linked_select_to_ids <- function(x) {
  parts <- parse_linked(x)
  ids <- trimws(sub(":.*$", "", parts))
  serialize_linked(ids)
}

#' Assert two matrices have identical dims and dimnames
#' @param adj character matrix or NULL
#' @param edited logical matrix or NULL
#' @return invisible NULL on success; stop() on mismatch.
assert_matrices_aligned <- function(adj, edited) {
  if (is.null(adj) || is.null(edited)) return(invisible(NULL))
  if (!identical(dim(adj), dim(edited))) {
    stop(sprintf(
      "assert_matrices_aligned: dim mismatch — adj %dx%d, edited %dx%d",
      nrow(adj), ncol(adj), nrow(edited), ncol(edited)
    ))
  }
  if (!identical(dimnames(adj), dimnames(edited))) {
    stop("assert_matrices_aligned: dimnames mismatch")
  }
  invisible(NULL)
}

#' Rebuild a source x target adjacency matrix from a delimited LinkedX column
#'
#' Always defaults missing confidence to "Medium" — never proxies from a
#' semantically-unrelated column (e.g. Activities' Frequency would produce
#' '+Medium:Continuous' which downstream consumers misinterpret).
#'
#' @return list(matrix, user_edited, stale_linked_ids, dropped_user_edits).
#'   `stale_linked_ids`: character vector of IDs that were in LinkedX but
#'     not in target_ids — caller surfaces in a notification.
#'   `dropped_user_edits`: character vector of "<src>:<tgt>" cell coords
#'     that were user_edited but whose row/col was removed from source_ids
#'     or target_ids — caller surfaces as a warning.
rebuild_matrix_from_linked <- function(element_df, linked_col,
                                       source_ids, target_ids,
                                       element_confidence_col = "Confidence",
                                       existing_matrix = NULL,
                                       user_edited_matrix = NULL,
                                       default_polarity = "+",
                                       default_strength = "Medium",
                                       default_confidence = "Medium") {
  if (!is.null(existing_matrix) && !is.null(user_edited_matrix)) {
    assert_matrices_aligned(existing_matrix, user_edited_matrix)
  }

  n_src <- length(source_ids); n_tgt <- length(target_ids)
  out <- matrix("", nrow = n_src, ncol = n_tgt,
                dimnames = list(source_ids, target_ids))
  out_edited <- matrix(FALSE, nrow = n_src, ncol = n_tgt,
                       dimnames = list(source_ids, target_ids))
  stale <- character(0)
  dropped <- character(0)

  # Project existing values into the new dims (handles size changes).
  # Track cells we DROPPED (user-edited cell whose row/col is gone).
  if (!is.null(existing_matrix)) {
    common_rows <- intersect(rownames(existing_matrix), source_ids)
    common_cols <- intersect(colnames(existing_matrix), target_ids)
    if (length(common_rows) > 0 && length(common_cols) > 0) {
      out[common_rows, common_cols] <- existing_matrix[common_rows, common_cols]
    }
    if (!is.null(user_edited_matrix)) {
      if (length(common_rows) > 0 && length(common_cols) > 0) {
        out_edited[common_rows, common_cols] <-
          user_edited_matrix[common_rows, common_cols]
      }
      # Detect dropped user-edited cells (cells whose row or col was removed)
      gone_rows <- setdiff(rownames(user_edited_matrix), source_ids)
      gone_cols <- setdiff(colnames(user_edited_matrix), target_ids)
      if (length(gone_rows) > 0) {
        sub <- user_edited_matrix[gone_rows, , drop = FALSE]
        idx <- which(sub, arr.ind = TRUE)
        if (nrow(idx) > 0) {
          for (k in seq_len(nrow(idx))) {
            dropped <- c(dropped, sprintf("%s:%s",
              rownames(sub)[idx[k,1]], colnames(sub)[idx[k,2]]))
          }
        }
      }
      if (length(gone_cols) > 0) {
        sub <- user_edited_matrix[, gone_cols, drop = FALSE]
        idx <- which(sub, arr.ind = TRUE)
        if (nrow(idx) > 0) {
          for (k in seq_len(nrow(idx))) {
            dropped <- c(dropped, sprintf("%s:%s",
              rownames(sub)[idx[k,1]], colnames(sub)[idx[k,2]]))
          }
        }
      }
    }
  }

  has_conf_col <- element_confidence_col %in% colnames(element_df)

  for (i in seq_len(nrow(element_df))) {
    src_id <- as.character(element_df$ID[i])
    if (!(src_id %in% source_ids)) {
      # Caller invariant violation; warn loudly via debug_log if available
      if (exists("debug_log", mode = "function")) {
        debug_log(sprintf("rebuild: element ID '%s' not in source_ids — caller bug",
                          src_id), "WARN")
      }
      next
    }

    linked_ids <- parse_linked(element_df[[linked_col]][i])
    confidence <- if (has_conf_col) {
      val <- element_df[[element_confidence_col]][i]
      if (is.null(val) || is.na(val) || !nzchar(val)) default_confidence else as.character(val)
    } else {
      default_confidence
    }
    cell_default <- paste0(default_polarity, default_strength, ":", confidence)

    declared <- intersect(linked_ids, target_ids)
    bad <- setdiff(linked_ids, target_ids)
    if (length(bad) > 0) stale <- unique(c(stale, bad))

    for (tgt_id in declared) {
      if (!out_edited[src_id, tgt_id]) {
        out[src_id, tgt_id] <- cell_default
      }
    }
    # Cells previously set, NOT declared, NOT user_edited -> clear
    for (tgt_id in target_ids) {
      if (tgt_id %in% declared) next
      if (out_edited[src_id, tgt_id]) next
      if (nzchar(out[src_id, tgt_id])) {
        out[src_id, tgt_id] <- ""
      }
    }
  }

  list(
    matrix = out,
    user_edited = out_edited,
    stale_linked_ids = stale,
    dropped_user_edits = dropped
  )
}
