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
#' A multi-select widget hands this a character VECTOR of label-form values
#' ("ES001: Fish", "ES002: Energy"); a legacy/stored value is a single,
#' possibly '|'-delimited string. Splitting each element on '|' flattens both
#' shapes to one id list. IDs are de-duplicated (first pick wins) so a node's
#' repeated selection never inflates the link list — one element can carry many
#' forward edges without duplicating the node (N:M).
#' @param x select value(s): "", "GB001", "GB001: Food", "GB001|GB002: Tourism",
#'   or c("GB001: Food", "GB002: Tourism") from a multi-select.
#' @return single '|'-delimited string of bare IDs ("" when empty).
linked_select_to_ids <- function(x) {
  if (is.null(x) || length(x) == 0) return("")
  parts <- unlist(lapply(as.character(x), parse_linked), use.names = FALSE)
  ids <- unique(trimws(sub(":.*$", "", parts)))
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
#' Signs are evidence-only (evidenced polarity): a NEW declared cell is written
#' only when `chosen_signs` holds a sign for it; otherwise it stays empty and
#' is reported in `unsigned_links` so the caller can ask the user. An existing
#' signed cell keeps its sign (old saves carry all-FALSE user_edited flags).
#'
#' @param chosen_signs named chr vector, names "<src_id>|<tgt_id>", values
#'   "+"/"-".
#' @return list(matrix, user_edited, stale_linked_ids, dropped_user_edits,
#'   unsigned_links). `unsigned_links`: data.frame (see new_unsigned_links())
#'   with matrix_key NA — the caller fills it in.
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
                                       chosen_signs = character(0),
                                       default_strength = "medium",
                                       default_confidence = "3") {
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
  uns_src <- character(0); uns_tgt <- character(0); uns_suffix <- character(0)

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
      normalize_confidence_level(val, default_confidence)
    } else {
      default_confidence
    }
    suffix <- paste0(default_strength, ":", confidence)

    declared <- intersect(linked_ids, target_ids)
    bad <- setdiff(linked_ids, target_ids)
    if (length(bad) > 0) stale <- unique(c(stale, bad))

    for (tgt_id in declared) {
      if (!out_edited[src_id, tgt_id]) {
        # An edge that already exists (saved project, template, import) keeps
        # its sign even when not flagged user_edited — old saves carry
        # all-FALSE flags (N26). A NEW cell takes only a chosen sign; without
        # one it stays empty and is reported unsigned.
        prev <- out[src_id, tgt_id]
        prev_pol <- if (!is.na(prev) && nzchar(prev)) substr(prev, 1, 1) else ""
        if (prev_pol %in% c("+", "-")) {
          out[src_id, tgt_id] <- paste0(prev_pol, suffix)
        } else {
          pick <- chosen_sign_for(chosen_signs, src_id, tgt_id)
          if (!is.na(pick)) {
            out[src_id, tgt_id] <- paste0(pick, suffix)
          } else {
            out[src_id, tgt_id] <- ""
            uns_src <- c(uns_src, src_id); uns_tgt <- c(uns_tgt, tgt_id)
            uns_suffix <- c(uns_suffix, suffix)
          }
        }
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
    # A user-edited cell is kept as is — unless it carries no sign (legacy
    # data such as "medium:3"): saved data never holds a missing sign, so it
    # takes a chosen sign or is blanked and reported like any unsigned link,
    # keeping its own strength/confidence as the suffix.
    for (tgt_id in target_ids) {
      if (!out_edited[src_id, tgt_id]) next
      prev <- out[src_id, tgt_id]
      if (is.na(prev) || !nzchar(prev) || substr(prev, 1, 1) %in% c("+", "-")) next
      pick <- chosen_sign_for(chosen_signs, src_id, tgt_id)
      if (!is.na(pick)) {
        out[src_id, tgt_id] <- paste0(pick, prev)
      } else {
        out[src_id, tgt_id] <- ""
        uns_src <- c(uns_src, src_id); uns_tgt <- c(uns_tgt, tgt_id)
        uns_suffix <- c(uns_suffix, prev)
      }
    }
  }

  list(
    matrix = out,
    user_edited = out_edited,
    stale_linked_ids = stale,
    dropped_user_edits = dropped,
    unsigned_links = new_unsigned_links(uns_src, uns_tgt, linked_col, uns_suffix)
  )
}

# ---------------------------------------------------------------------------
# Unsigned links (evidenced polarity): links declared in LinkedX that have no
# sign yet. The caller asks the user (sign_choice_server) and then writes the
# chosen signs with apply_chosen_signs() or removes the ticks with
# untick_linked().
# ---------------------------------------------------------------------------

#' Matrix key -> where its links live: source element key + LinkedX column
#' (the column owner is the rebuild source), target element key, the Standard
#' Entry panel prefix/field of the LinkedX select, and whether the matrix is
#' stored transposed (gb_r is stored GB x R but declared on the responses).
SIGN_LINK_SPECS <- list(
  es_gb  = list(src = "ecosystem_services", col = "LinkedGB",  tgt = "goods_benefits",     prefix = "es",  field = "linkedgb"),
  mpf_es = list(src = "marine_processes",   col = "LinkedES",  tgt = "ecosystem_services", prefix = "mpf", field = "linkedes"),
  p_mpf  = list(src = "pressures",          col = "LinkedMPF", tgt = "marine_processes",   prefix = "p",   field = "linkedmpf"),
  a_p    = list(src = "activities",         col = "LinkedP",   tgt = "pressures",          prefix = "a",   field = "linkedp"),
  d_a    = list(src = "drivers",            col = "LinkedA",   tgt = "activities",         prefix = "d",   field = "linkeda"),
  r_d    = list(src = "responses",          col = "LinkedD",   tgt = "drivers",            prefix = "r",   field = "linkedd"),
  r_a    = list(src = "responses",          col = "LinkedA",   tgt = "activities",         prefix = "r",   field = "linkeda"),
  r_p    = list(src = "responses",          col = "LinkedP",   tgt = "pressures",          prefix = "r",   field = "linkedp"),
  r_mpf  = list(src = "responses",          col = "LinkedMPF", tgt = "marine_processes",   prefix = "r",   field = "linkedmpf"),
  r_r    = list(src = "responses",          col = "LinkedR",   tgt = "responses",          prefix = "r",   field = "linkedr"),
  gb_r   = list(src = "responses",          col = "LinkedGB",  tgt = "goods_benefits",     prefix = "r",   field = "linkedgb",
                transposed = TRUE)
)

#' Build an unsigned-link record (one row per link)
#' @return data.frame(matrix_key, src_id, tgt_id, linked_col, suffix,
#'   transposed). src_id owns the LinkedX column (rebuild orientation);
#'   transposed is TRUE when the matrix is stored tgt x src (gb_r).
new_unsigned_links <- function(src_id = character(0), tgt_id = character(0),
                               linked_col = character(0), suffix = character(0),
                               matrix_key = NA_character_, transposed = FALSE) {
  n <- length(src_id)
  if (n == 0) {
    return(data.frame(matrix_key = character(0), src_id = character(0),
                      tgt_id = character(0), linked_col = character(0),
                      suffix = character(0), transposed = logical(0),
                      stringsAsFactors = FALSE))
  }
  data.frame(matrix_key = rep(as.character(matrix_key), length.out = n),
             src_id = as.character(src_id), tgt_id = as.character(tgt_id),
             linked_col = rep(as.character(linked_col), length.out = n),
             suffix = as.character(suffix),
             transposed = rep(as.logical(transposed), length.out = n),
             stringsAsFactors = FALSE)
}

#' Stamp a matrix key (and orientation) on an unsigned-link record
tag_unsigned_links <- function(links, matrix_key, transposed = FALSE) {
  if (!is.data.frame(links) || nrow(links) == 0) return(new_unsigned_links())
  links$matrix_key <- matrix_key
  links$transposed <- transposed
  links
}

# Chosen sign for one pair, or NA when none / not "+"/"-".
chosen_sign_for <- function(chosen_signs, src_id, tgt_id) {
  if (length(chosen_signs) == 0 || is.null(names(chosen_signs))) return(NA_character_)
  key <- paste0(src_id, "|", tgt_id)
  if (!(key %in% names(chosen_signs))) return(NA_character_)
  v <- as.character(chosen_signs[[key]])
  if (length(v) == 1 && !is.na(v) && v %in% c("+", "-")) v else NA_character_
}

#' Write chosen signs for unsigned links into the adjacency matrices
#'
#' @param adjacency_matrices named list of character matrices
#' @param links unsigned-link record with matrix_key filled in
#' @param signs named chr vector "<src_id>|<tgt_id>" -> "+"/"-"
#' @return adjacency_matrices with paste0(sign, suffix) written at
#'   [src_id, tgt_id] (or [tgt_id, src_id] when transposed). Links without a
#'   sign, or whose matrix/row/column is missing, are skipped.
apply_chosen_signs <- function(adjacency_matrices, links, signs) {
  if (!is.data.frame(links) || nrow(links) == 0) return(adjacency_matrices)
  for (k in seq_len(nrow(links))) {
    s <- chosen_sign_for(signs, links$src_id[k], links$tgt_id[k])
    if (is.na(s)) next
    mk <- links$matrix_key[k]
    m <- adjacency_matrices[[mk]]
    if (!is.matrix(m)) next
    r <- links$src_id[k]; cc <- links$tgt_id[k]
    if (isTRUE(links$transposed[k])) { r <- links$tgt_id[k]; cc <- links$src_id[k] }
    if (!(r %in% rownames(m)) || !(cc %in% colnames(m))) next
    m[r, cc] <- paste0(s, links$suffix[k])
    adjacency_matrices[[mk]] <- m
  }
  adjacency_matrices
}

#' Remove one target from an element row's LinkedX value
#'
#' Segments may be bare ids or label form ("A001: Fishing"). A segment is
#' removed when its bare id equals `tgt_id`, or — when `target_df` is given —
#' when it resolves to `tgt_id` by name-then-id (the recovery resolution).
#' The LinkedX and ID columns are matched case-insensitively (normalised
#' projects carry lowercase element columns).
#' @return element_df with that row's LinkedX value updated.
untick_linked <- function(element_df, src_id, linked_col, tgt_id, target_df = NULL) {
  if (!is.data.frame(element_df) || nrow(element_df) == 0) return(element_df)
  pick_col <- function(nm) {
    if (nm %in% names(element_df)) nm else names(element_df)[match(tolower(nm), tolower(names(element_df)))]
  }
  col <- pick_col(linked_col); id_col <- pick_col("ID")
  if (is.na(col) || is.na(id_col)) return(element_df)
  for (i in which(as.character(element_df[[id_col]]) == src_id)) {
    segs <- parse_linked(element_df[[col]][i])
    if (length(segs) == 0) next
    keep <- vapply(segs, function(seg) {
      if (identical(trimws(sub(":.*$", "", seg)), tgt_id)) return(FALSE)
      if (is.data.frame(target_df) &&
          identical(resolve_linked_to_target_ids(seg, target_df), tgt_id)) return(FALSE)
      TRUE
    }, logical(1), USE.NAMES = FALSE)
    element_df[[col]][i] <- serialize_linked(segs[keep])
  }
  element_df
}

# ---------------------------------------------------------------------------
# Name-based recovery of legacy LinkedX values
# ---------------------------------------------------------------------------
# Legacy (v1.13.x) Standard Entry exports store forward connections in the
# LinkedX columns in LABEL form ("MPF005: Biodiversity richness"), and may carry
# DUPLICATE element IDs (the old positional-ID bug). After reconcile repairs the
# duplicates, the stale numeric IDs in the labels no longer identify the right
# element — but the NAME still does. These helpers resolve each link by NAME
# first (robust to duplicate-ID repair), falling back to a bare-ID match.

# Light normalization for name comparison (trim, collapse internal whitespace,
# lowercase). Deliberately simple — element names are user text, not metachars.
.linked_norm_name <- function(x) tolower(trimws(gsub("\\s+", " ", as.character(x))))

#' Resolve a (possibly label-form, possibly pipe-delimited) LinkedX value to
#' target element IDs, preferring NAME match over a stale ID.
#'
#' @param linked_value scalar LinkedX cell, e.g. "MPF005: Biodiversity richness"
#'   or "GB001" or "GB001: Food|GB002: Energy". NULL/NA/"" -> character(0).
#' @param target_df data frame of candidate targets with `ID` and (ideally)
#'   `Name` columns (already reconciled to unique IDs).
#' @return unique character vector of matched target IDs (order preserved).
resolve_linked_to_target_ids <- function(linked_value, target_df) {
  segs <- parse_linked(linked_value)
  if (length(segs) == 0) return(character(0))
  if (!is.data.frame(target_df) || nrow(target_df) == 0 || !("ID" %in% names(target_df)))
    return(character(0))

  tgt_ids   <- as.character(target_df$ID)
  tgt_names <- if ("Name" %in% names(target_df)) .linked_norm_name(target_df$Name) else rep(NA_character_, length(tgt_ids))

  out <- character(0)
  for (seg in segs) {
    has_colon <- grepl(":", seg, fixed = TRUE)
    id_part   <- trimws(sub(":.*$", "", seg))
    name_part <- if (has_colon) trimws(sub("^[^:]*:\\s*", "", seg)) else ""
    resolved  <- NA_character_

    # 0) exact ID whose row also carries the label's name (review N51: with two
    #    same-name rows the label's own ID must win over the first name hit)
    if (nzchar(id_part) && id_part %in% tgt_ids && nzchar(name_part)) {
      j <- match(id_part, tgt_ids)
      if (!is.na(tgt_names[j]) && tgt_names[j] == .linked_norm_name(name_part)) resolved <- id_part
    }
    # 1) NAME match (the legacy label carries it; robust to duplicate-ID repair)
    if (is.na(resolved) && nzchar(name_part)) {
      hit <- which(tgt_names == .linked_norm_name(name_part))
      if (length(hit) >= 1) resolved <- tgt_ids[hit[1]]
    }
    # 2) fall back to bare-ID match
    if (is.na(resolved) && nzchar(id_part) && id_part %in% tgt_ids) resolved <- id_part

    if (!is.na(resolved)) out <- c(out, resolved)
  }
  unique(out)
}

#' Inverse of the Linked->Matrix build: for one element ID, collect the IDs of
#' the cells it connects to and return them as a single '|'-delimited string
#' (the Linked* column format). orientation="row" for R x target matrices
#' (r_d/r_a/r_p: scan the row named element_id, collect column names);
#' orientation="col" for gb_r (GB x R: scan the column named element_id,
#' collect row names). Returns "" when absent or no edges.
#' @param mat character adjacency matrix with dimnames; cells "" = no edge.
#' @param element_id the response ID whose links to recover.
#' @param orientation "row" or "col".
rederive_linked_from_matrix <- function(mat, element_id, orientation = c("row", "col")) {
  orientation <- match.arg(orientation)
  if (is.null(mat) || !is.matrix(mat)) return("")
  if (orientation == "row") {
    if (!(element_id %in% rownames(mat))) return("")
    cells <- mat[element_id, ]
    ids <- colnames(mat)[nzchar(cells) & !is.na(cells)]
  } else {
    if (!(element_id %in% colnames(mat))) return("")
    cells <- mat[, element_id]
    ids <- rownames(mat)[nzchar(cells) & !is.na(cells)]
  }
  serialize_linked(ids)
}

#' Rebuild a source x target adjacency matrix from a label-form LinkedX column,
#' resolving each link by NAME-then-ID. A link is written as
#' "<sign><strength>:<confidence>" only when `chosen_signs` holds its sign
#' (confidence taken from the source row's Confidence column when present,
#' else the default); the rest stay empty and are listed in
#' attr(, "unsigned_links") (matrix_key NA, filled by the caller). Edges are written at the
#' resolved (reconciled) target ID, so duplicate-ID corruption in the source
#' file does not misplace them.
#'
#' @return a character matrix (rows = source_df$ID, cols = target_df$ID) with
#'   attr(, "unsigned_links").
rebuild_forward_matrix_by_name <- function(source_df, linked_col, target_df,
                                           element_confidence_col = "Confidence",
                                           chosen_signs = character(0),
                                           default_strength = "medium",
                                           default_confidence = "3") {
  src_ids <- as.character(source_df$ID)
  tgt_ids <- as.character(target_df$ID)
  out <- matrix("", nrow = length(src_ids), ncol = length(tgt_ids),
                dimnames = list(src_ids, tgt_ids))
  has_conf <- element_confidence_col %in% names(source_df)
  attr(out, "unsigned_links") <- new_unsigned_links()
  if (!(linked_col %in% names(source_df))) return(out)
  uns_src <- character(0); uns_tgt <- character(0); uns_suffix <- character(0)

  for (i in seq_len(nrow(source_df))) {
    sid <- as.character(source_df$ID[i])
    if (!(sid %in% src_ids)) next
    confidence <- if (has_conf) {
      v <- source_df[[element_confidence_col]][i]
      normalize_confidence_level(v, default_confidence)
    } else default_confidence
    suffix <- paste0(default_strength, ":", confidence)
    for (tid in resolve_linked_to_target_ids(source_df[[linked_col]][i], target_df)) {
      pick <- chosen_sign_for(chosen_signs, sid, tid)
      if (!is.na(pick)) {
        out[sid, tid] <- paste0(pick, suffix)
      } else if (!nzchar(out[sid, tid]) &&
                 !any(uns_src == sid & uns_tgt == tid)) {
        uns_src <- c(uns_src, sid); uns_tgt <- c(uns_tgt, tid); uns_suffix <- c(uns_suffix, suffix)
      }
    }
  }
  attr(out, "unsigned_links") <- new_unsigned_links(uns_src, uns_tgt, linked_col, uns_suffix)
  out
}

#' Map an element confidence to the integer grammar of matrix cells
#'
#' Cells are parsed as '<polarity><strength>:<integer 1-5>' (utils.R
#' parse_connection_value); the forward chain used to write the form label
#' ('High'), which parses as NA and silently fell back to the default
#' (review 2026-10-07 N25). High/Medium/Low map to 5/3/1; integers 1-5 pass.
#' @param x confidence value (label, number or empty)
#' @param default value used when x is empty or unrecognised
#' @return character(1)
normalize_confidence_level <- function(x, default = "3") {
  if (is.null(x) || length(x) == 0 || is.na(x[1])) return(as.character(default))
  v <- tolower(trimws(as.character(x[1])))
  if (!nzchar(v)) return(as.character(default))
  map <- c("very high" = "5", "high" = "5", "medium" = "3", "moderate" = "3", "low" = "1", "very low" = "1")
  if (v %in% names(map)) return(unname(map[v]))
  n <- suppressWarnings(as.integer(v))
  if (!is.na(n) && n >= 1 && n <= 5) return(as.character(n))
  as.character(default)
}
