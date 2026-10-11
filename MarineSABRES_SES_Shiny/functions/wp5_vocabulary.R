# functions/wp5_vocabulary.R
# WP5 shared vocabulary helpers (spec 2026-10-11 WS-1).
# Codes are stored in project data; labels resolve via i18n at render time.

.wp5_vocab_table <- function() {
  list(
    criteria           = WP5_CRITERIA$code,
    subdimension       = unique(unlist(WP5_CRITERION_SUBDIMENSIONS, use.names = FALSE)),
    direction          = WP5_RUBRIC$direction,
    magnitude          = WP5_RUBRIC$magnitude,
    timing             = WP5_RUBRIC$timing,
    confidence         = WP5_RUBRIC$confidence,
    evidence           = WP5_RUBRIC$evidence,
    uncertainty_driver = WP5_RUBRIC$uncertainty_driver,
    indicator_role     = WP5_RUBRIC$indicator_role,
    pathway_segment    = WP5_RUBRIC$pathway_segment,
    instrument         = EBM_POLICY_INSTRUMENTS$code,
    measure            = EBM_MANAGEMENT_MEASURES$code,
    tenet              = EBM_TENETS$code,
    npg                = NPG_DIMENSIONS,
    graph_op           = GRAPH_EDIT_OPS
  )
}

#' All codes of a WP5 vocabulary
#' @param vocab Vocabulary name (see .wp5_vocab_table())
#' @return Character vector of codes
wp5_vocab_codes <- function(vocab) {
  tbl <- .wp5_vocab_table()
  if (!is.character(vocab) || length(vocab) != 1 || !vocab %in% names(tbl)) {
    stop("Unknown WP5 vocabulary: ", paste(vocab, collapse = ","))
  }
  tbl[[vocab]]
}

#' Normalise criterion codes, resolving D5.2 aliases (PO -> PI, FI -> FF)
#' @param x Character vector
#' @return Character vector of canonical codes, NA for unknown/empty
wp5_criterion_code <- function(x) {
  x <- toupper(trimws(as.character(x)))
  lookup <- setNames(WP5_CRITERIA$code, WP5_CRITERIA$code)
  for (i in seq_len(nrow(WP5_CRITERIA))) {
    for (a in WP5_CRITERIA$aliases[[i]]) lookup[[a]] <- WP5_CRITERIA$code[i]
  }
  out <- unname(lookup[x])
  out[is.na(x) | x == ""] <- NA_character_
  as.character(out)
}

#' i18n key for a vocabulary code
#' @return Character vector of keys
wp5_vocab_key <- function(vocab, code) {
  paste0("modules.wp5_vocabulary.", vocab, ".", gsub(".", "_", code, fixed = TRUE))
}

#' Translated label for vocabulary codes; falls back to the code itself
#' @param vocab Vocabulary name
#' @param code Character vector of codes
#' @param i18n Translator with $t(key)
#' @return Character vector of labels ("" for NA codes)
wp5_vocab_label <- function(vocab, code, i18n) {
  vapply(as.character(code), function(cd) {
    if (is.na(cd) || cd == "") return("")
    key <- wp5_vocab_key(vocab, cd)
    lbl <- tryCatch(as.character(i18n$t(key)), error = function(e) NA_character_)
    if (length(lbl) != 1 || is.na(lbl) || lbl == "" || identical(lbl, key)) cd else lbl
  }, character(1), USE.NAMES = FALSE)
}
