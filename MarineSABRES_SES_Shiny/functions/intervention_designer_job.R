# functions/intervention_designer_job.R
# =============================================================================
# Background execution for the WS-7a intervention designer (spec §2.4, §5).
# laguna runs open-source Shiny Server: one R process serves every user, so
# grids (about 1-2 min at the 65,536 cap) run in a separate R process via callr.
# =============================================================================

#' Absolute paths of the engine files the worker sources.
designer_engine_files <- function(root = NULL) {
  if (is.null(root)) {
    root <- if (exists("PROJECT_ROOT", inherits = TRUE)) get("PROJECT_ROOT", inherits = TRUE) else getwd()
  }
  normalizePath(file.path(root, "functions", c("ses_dynamics.R", "intervention_designer.R")),
                winslash = "/", mustWork = TRUE)
}

# Remove a job's progress file (and its atomic-write temp file).
.designer_job_cleanup <- function(job) {
  if (!is.null(job) && !is.null(job$progress_file)) {
    unlink(c(job$progress_file, paste0(job$progress_file, ".tmp")))
  }
  invisible(NULL)
}

#' Environment of the worker: callr's safe defaults with BLAS/OpenMP pinned to one
#' thread, so eigen() and matrix products do not take every core of the shared server.
.designer_worker_env <- function() {
  c(callr::rcmd_safe_env(), OPENBLAS_NUM_THREADS = "1", OMP_NUM_THREADS = "1")
}

#' Start a designer run in a background R process.
designer_job_start <- function(payload, engine_files = designer_engine_files()) {
  progress_file <- tempfile("designer_progress_", fileext = ".txt")
  proc <- callr::r_bg(
    function(payload, engine_files, progress_file) {
      suppressMessages(library(Matrix))
      for (f in engine_files) source(f, local = FALSE)
      pc_state <- ""                       # pre-check status, repeated on every write
      progress <- function(done, total, precheck = NULL) {
        if (!is.null(precheck)) pc_state <<- precheck
        tmp <- paste0(progress_file, ".tmp")
        writeLines(trimws(sprintf("%.0f %.0f %s", done, total, pc_state)), tmp)
        file.rename(tmp, progress_file)
      }
      ses_run_design(payload, progress = progress)
    },
    args = list(payload = payload, engine_files = engine_files, progress_file = progress_file),
    # Nobody reads the worker's output: no pipes that could fill up and stall it
    stdout = NULL, stderr = NULL,
    env = .designer_worker_env(),
    supervise = TRUE
  )
  # Lower the worker's priority where the OS supports it (no-op elsewhere)
  tryCatch(tools::psnice(proc$get_pid(), 10L), error = function(e) NULL, warning = function(w) NULL)
  list(process = proc, progress_file = progress_file, started = Sys.time())
}

#' Poll a designer job.
designer_job_poll <- function(job, timeout_s = INTERVENTION_JOB_TIMEOUT_S) {
  p <- job$process
  if (p$is_alive()) {
    if (as.numeric(difftime(Sys.time(), job$started, units = "secs")) > timeout_s) {
      designer_job_cancel(job)
      msg <- sprintf("designer run timed out after %.0f s", timeout_s)
      if (exists("debug_log", mode = "function")) debug_log(paste("Designer job failed:", msg), "INTERVENTION")
      return(list(state = "error", reason = "timeout", message = msg))
    }
    # "<done> <total> [<precheck>]": the third token is text, so no scan()
    tok <- tryCatch(strsplit(trimws(readLines(job$progress_file, warn = FALSE)[1]), "[[:space:]]+")[[1]],
                    error = function(e) character(0), warning = function(w) character(0))
    tok <- tok[!is.na(tok) & nzchar(tok)]
    return(list(state = "running",
                done = if (length(tok) >= 1) as.numeric(tok[1]) else 0,
                total = if (length(tok) >= 2) as.numeric(tok[2]) else NA_real_,
                precheck = if (length(tok) >= 3) tok[3] else NULL))
  }
  res <- tryCatch(p$get_result(), error = function(e) e)
  .designer_job_cleanup(job)
  if (inherits(res, "error")) {
    msg <- if (!is.null(res$parent)) conditionMessage(res$parent) else conditionMessage(res)
    if (exists("debug_log", mode = "function")) debug_log(paste("Designer job failed:", msg), "INTERVENTION")
    return(list(state = "error", reason = "engine", message = msg))
  }
  list(state = "done", result = res)
}

#' Kill a designer job and remove its progress file.
designer_job_cancel <- function(job) {
  if (!is.null(job) && !is.null(job$process) && job$process$is_alive()) job$process$kill()
  .designer_job_cleanup(job)
  invisible(TRUE)
}

#' The job functions the designer module uses (tests pass a fake).
designer_job_api <- function() {
  list(start = function(payload) designer_job_start(payload),
       poll = designer_job_poll,
       cancel = designer_job_cancel)
}
