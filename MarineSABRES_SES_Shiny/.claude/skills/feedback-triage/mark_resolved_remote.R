# .claude/skills/feedback-triage/mark_resolved_remote.R
# Rewrites ONE NDJSON entry's resolution fields atomically. Takes ONE arg: the
# path to a JSON params file (so NO untrusted text touches a shell word).
# Matches by (title,timestamp); aborts if the file grew (concurrent append) so
# nothing is lost. Run UNDER flock. jsonlite only. Exit 0 = OK, 1 = fail.
`%||%` <- function(a, b) if (is.null(a)) b else a
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 1L) { cat("ERR usage: <params.json>\n"); quit(status = 2) }
ok <- tryCatch({
  P <- jsonlite::fromJSON(args[1], simplifyVector = TRUE)
  if (!P$status %in% c("open","addressed","wont_fix","duplicate")) stop("bad status")
  log <- P$log
  L <- readLines(log, warn = FALSE, encoding = "UTF-8")
  if (!is.null(P$expect_total_lines) && length(L) != P$expect_total_lines)
    stop(sprintf("file grew (%d != %d) - re-pull and retry", length(L), P$expect_total_lines))
  idx <- which(vapply(L, function(ln) {
    e <- tryCatch(jsonlite::fromJSON(trimws(ln), simplifyVector = TRUE), error = function(x) NULL)
    !is.null(e) &&
      identical(as.character(e$title), as.character(P$match_title)) &&
      identical(as.character(e$timestamp %||% ""), as.character(P$match_timestamp %||% ""))
  }, logical(1L)))
  if (length(idx) != 1L) stop(sprintf("expected 1 (title,timestamp) match, found %d", length(idx)))
  p <- jsonlite::fromJSON(trimws(L[[idx]]), simplifyVector = TRUE)
  p$status          <- P$status
  p$resolved_at     <- format(as.POSIXct(Sys.time(), tz = "UTC"), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
  p$resolved_by     <- P$resolved_by %||% "feedback-triage"
  p$resolution_note <- P$note %||% ""
  if (!is.null(P$fix_ref) && nzchar(P$fix_ref))           p$fix_ref      <- P$fix_ref
  if (!is.null(P$fix_deployed) && nzchar(P$fix_deployed)) p$fix_deployed <- P$fix_deployed
  L[[idx]] <- jsonlite::toJSON(p, auto_unbox = TRUE)
  tmp <- paste0(log, ".tmp.", Sys.getpid())
  on.exit(if (file.exists(tmp)) try(file.remove(tmp), silent = TRUE), add = TRUE)
  writeLines(L, tmp, useBytes = TRUE)
  if (!isTRUE(file.rename(tmp, log))) stop("rename failed")
  cat(sprintf("OK matched line %d\n", idx)); TRUE
}, error = function(e) { cat("ERR", conditionMessage(e), "\n"); FALSE })
if (isTRUE(ok)) quit(status = 0) else { cat("FAIL\n"); quit(status = 1) }
