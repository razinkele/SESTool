# functions/wp5_typing_lint.R
# WS-3b typing lint: report (never fix) likely mistyped interventions.
#   L1: Driver / Activity / Ecosystem Service named like a policy instrument or
#       management measure (data/wp5_rm_synonyms.json, toolbox-authored).
#   L2: Response with no incoming link from a Marine Process, Ecosystem Service
#       or Goods & Benefit ("no feedback", D5.3).

.wp5_lint_env <- new.env(parent = emptyenv())
WP5_LINT_L1_GROUPS <- c("Drivers", "Activities", "Ecosystem Services")
WP5_LINT_FEEDBACK_GROUPS <- c("Marine Processes & Functioning", "Ecosystem Services", "Goods & Benefits")

.empty_lint <- function() data.frame(node_id = character(), name = character(), group = character(),
                                     rule = character(), matched = character(), stringsAsFactors = FALSE)

load_wp5_rm_synonyms <- function(path = NULL) {
  if (is.null(path) && !is.null(.wp5_lint_env$patterns)) return(.wp5_lint_env$patterns)
  if (is.null(path)) {
    path <- if (exists("get_project_file", mode = "function")) get_project_file("data", "wp5_rm_synonyms.json")
            else file.path("data", "wp5_rm_synonyms.json")
  }
  if (!file.exists(path)) {
    warning(sprintf("[WP5 lint] synonym file not found: %s", path))
    return(character(0))
  }
  syn <- tryCatch(jsonlite::fromJSON(path, simplifyVector = FALSE), error = function(e) NULL)
  pats <- as.character(unlist(syn$patterns))
  .wp5_lint_env$patterns <- pats
  pats
}

wp5_typing_lint <- function(nodes, edges, patterns = load_wp5_rm_synonyms()) {
  if (!is.data.frame(nodes) || nrow(nodes) == 0 || !all(c("id", "group") %in% names(nodes))) return(.empty_lint())
  name <- as.character(if ("name_raw" %in% names(nodes)) nodes$name_raw else nodes$label)
  name[is.na(name)] <- ""
  out <- list()
  if (length(patterns) > 0) {
    rx <- paste0("(*UCP)(?<!\\p{L})(", paste(patterns, collapse = "|"), ")(?!\\p{L})")
    cand <- which(nodes$group %in% WP5_LINT_L1_GROUPS)
    if (length(cand) > 0) {
      pos <- regexpr(rx, name[cand], perl = TRUE, ignore.case = TRUE)   # one compile, vectorised
      hit <- pos > 0
      if (any(hit)) {
        idx <- cand[hit]
        out[[length(out) + 1]] <- data.frame(node_id = nodes$id[idx], name = name[idx],
          group = nodes$group[idx], rule = "L1", matched = regmatches(name[cand], pos),
          stringsAsFactors = FALSE)
      }
    }
  }
  resp <- which(nodes$group == "Responses")
  if (length(resp) > 0) {
    fb_ids <- nodes$id[nodes$group %in% WP5_LINT_FEEDBACK_GROUPS]
    has_fb <- if (is.data.frame(edges) && nrow(edges) > 0) unique(edges$to[edges$from %in% fb_ids]) else character(0)
    for (i in resp) if (!(nodes$id[i] %in% has_fb)) out[[length(out) + 1]] <- data.frame(node_id = nodes$id[i],
      name = name[i], group = nodes$group[i], rule = "L2", matched = "", stringsAsFactors = FALSE)
  }
  if (length(out) == 0) return(.empty_lint())
  res <- do.call(rbind, out)
  res[order(res$rule, res$name), , drop = FALSE]
}

# ISA element category -> CLD group name and matrix prefix (SOURCE x TARGET naming)
.WP5_LINT_CATEGORIES <- list(
  drivers = c("Drivers", "d"), activities = c("Activities", "a"), pressures = c("Pressures", "p"),
  marine_processes = c("Marine Processes & Functioning", "mpf"), ecosystem_services = c("Ecosystem Services", "es"),
  goods_benefits = c("Goods & Benefits", "gb"), responses = c("Responses", "r"))

.lint_col <- function(df, opts) {
  for (o in opts) if (o %in% names(df)) return(as.character(df[[o]]))
  rep(NA_character_, nrow(df))
}

#' Lint ISA data directly (O(elements + matrix cells); no CLD build — review I3).
#' Node ids are stable element IDs (fallback: category_row), so dedup keys survive
#' unrelated inserts/deletes (review I2).
typing_lint_from_isa <- function(isa_data) {
  tryCatch({
    if (!is.list(isa_data) || length(isa_data) == 0) return(.empty_lint())
    node_parts <- list()
    for (cat in names(.WP5_LINT_CATEGORIES)) {
      df <- isa_data[[cat]]
      if (!is.data.frame(df) || nrow(df) == 0) next
      ids <- .lint_col(df, c("ID", "id"))
      ids[is.na(ids) | !nzchar(ids)] <- paste0(cat, "_", which(is.na(ids) | !nzchar(ids)))
      nm <- .lint_col(df, c("Name", "name"))
      node_parts[[cat]] <- data.frame(id = ids, label = nm, name_raw = nm, group = .WP5_LINT_CATEGORIES[[cat]][1],
                                      cat = cat, stringsAsFactors = FALSE)
    }
    if (length(node_parts) == 0) return(.empty_lint())
    nodes <- do.call(rbind, node_parts)
    # Feedback edges into Responses from MPF/ES/GB matrices (rows = source, cols = target)
    edges <- data.frame(from = character(), to = character(), stringsAsFactors = FALSE)
    mats <- isa_data$adjacency_matrices
    resp <- nodes[nodes$cat == "responses", , drop = FALSE]
    if (is.list(mats) && nrow(resp) > 0) {
      for (src in c("marine_processes", "ecosystem_services", "goods_benefits")) {
        m <- mats[[paste0(.WP5_LINT_CATEGORIES[[src]][2], "_r")]]
        if (is.null(m) || length(dim(m)) != 2 || ncol(m) == 0) next
        filled <- apply(m, 2, function(col) any(!is.na(col) & nzchar(trimws(as.character(col)))))
        cn <- colnames(m)
        tgt <- if (!is.null(cn) && all(cn %in% c(resp$id, resp$label))) {
          vapply(cn, function(x) if (x %in% resp$id) x else resp$id[match(x, resp$label)], character(1))
        } else resp$id[seq_len(min(ncol(m), nrow(resp)))]          # positional, as the CLD reads cells
        n <- min(length(tgt), length(filled))
        tgt <- unname(tgt[seq_len(n)][filled[seq_len(n)]])
        if (length(tgt)) edges <- rbind(edges, data.frame(from = paste0(src, "*"), to = tgt, stringsAsFactors = FALSE))
      }
    }
    if (nrow(edges) > 0) {   # pseudo source nodes; data.frame() with 0 ids and scalar "" would error
      src_ids <- unique(edges$from)
      nodes <- rbind(nodes, data.frame(id = src_ids, label = "", name_raw = "", group = "Goods & Benefits",
                                       cat = "", stringsAsFactors = FALSE))
    }
    wp5_typing_lint(nodes, edges)
  }, error = function(e) {
    if (exists("debug_log", mode = "function")) debug_log(paste("typing lint failed:", e$message), "WARN")
    .empty_lint()
  })
}
