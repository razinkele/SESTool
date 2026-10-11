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
    for (i in cand) {
      m <- regmatches(name[i], regexpr(rx, name[i], perl = TRUE, ignore.case = TRUE))
      if (length(m) == 1) out[[length(out) + 1]] <- data.frame(node_id = nodes$id[i], name = name[i],
        group = nodes$group[i], rule = "L1", matched = m, stringsAsFactors = FALSE)
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

typing_lint_from_isa <- function(isa_data) {
  tryCatch({
    if (!is.list(isa_data) || length(isa_data) == 0) return(.empty_lint())
    nodes <- create_nodes_df(isa_data)
    edges <- create_edges_df(isa_data, isa_data$adjacency_matrices)
    wp5_typing_lint(nodes, edges)
  }, error = function(e) {
    if (exists("debug_log", mode = "function")) debug_log(paste("typing lint failed:", e$message), "WARN")
    .empty_lint()
  })
}
