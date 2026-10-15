# tests/testthat/test-intervention-designer-job.R
source_for_test(c("functions/intervention_designer.R", "functions/intervention_designer_job.R"))

app_root <- function() { td <- getwd(); if (basename(td) == "testthat") dirname(dirname(td)) else td }
LV <- c(-1, -0.5, -0.25, 0, 0.25, 0.5, 1)
tiny_payload <- function(objectives = "b") {
  m <- matrix(c(0, 0.5, 0, 0), 2, 2, dimnames = rep(list(c("a", "b")), 2))
  list(base = m, design = list(new_node = "IV", edges = data.frame(
         from = c("IV", "b"), to = c("a", "IV"), kind = "intervention",
         min_level = -1, max_level = 1, stringsAsFactors = FALSE)),
       levels = LV, objectives = objectives, sustain = character(0), seed = 1L,
       steps = 200L, window = 50L, cap = 65536, chunk = 2048L, top_k = 5L, max_boolean_nodes = 20L)
}
# 4 variable edges x 7 levels = 2,401 configs at 1000 steps: far too slow to finish
# before a poll, so the worker is certainly alive when the timeout/cancel is exercised.
slow_payload <- function() {
  p <- tiny_payload(); p$steps <- 1000L
  p$design$edges <- data.frame(from = c("IV", "IV", "b", "a"), to = c("a", "b", "IV", "IV"),
    kind = "intervention", min_level = -1, max_level = 1, stringsAsFactors = FALSE)
  p
}
wait_for <- function(job, secs = 120) {
  t_end <- Sys.time() + secs
  repeat {
    st <- designer_job_poll(job, timeout_s = secs)
    if (st$state != "running" || Sys.time() > t_end) return(st)
    Sys.sleep(0.2)
  }
}

test_that("engine files resolve to existing absolute paths", {
  f <- designer_engine_files(app_root())
  expect_length(f, 2L)
  expect_true(all(file.exists(f)))
})

test_that("a background job runs a tiny design to a result", {
  skip_if_not_installed("callr")
  job <- designer_job_start(tiny_payload(), designer_engine_files(app_root()))
  st <- wait_for(job)
  expect_equal(st$state, "done")
  expect_equal(st$result$n_eval, 49)
  expect_false(file.exists(job$progress_file))
})

test_that("an engine error comes back as an error state (review focus 5)", {
  skip_if_not_installed("callr")
  job <- designer_job_start(tiny_payload(objectives = "no such node"), designer_engine_files(app_root()))
  st <- wait_for(job)
  expect_equal(st$state, "error")
  expect_identical(st$reason, "engine")
  expect_match(st$message, "objective nodes not found")
})

test_that("cancel kills the worker", {
  skip_if_not_installed("callr")
  job <- designer_job_start(slow_payload(), designer_engine_files(app_root()))
  expect_true(job$process$is_alive())
  designer_job_cancel(job)
  Sys.sleep(0.5)
  expect_false(job$process$is_alive())
  expect_false(file.exists(job$progress_file))
})

test_that("a job past its timeout is killed and reported", {
  skip_if_not_installed("callr")
  job <- designer_job_start(slow_payload(), designer_engine_files(app_root()))
  withr::defer(designer_job_cancel(job))
  expect_true(job$process$is_alive())            # certainly still running: no race
  job$started <- Sys.time() - 1000
  st <- designer_job_poll(job, timeout_s = 1)
  expect_equal(st$state, "error")
  expect_identical(st$reason, "timeout")
  expect_match(st$message, "timed out")
  Sys.sleep(0.5)
  expect_false(job$process$is_alive())
})

test_that("a running poll reports the pre-check status from the progress file (spec §4.6)", {
  skip_if_not_installed("callr")
  job <- list(process = callr::r_bg(function() Sys.sleep(30)),
              progress_file = tempfile("designer_progress_", fileext = ".txt"), started = Sys.time())
  withr::defer(designer_job_cancel(job))
  writeLines("0 1000 topology_change_needed", job$progress_file)
  st <- designer_job_poll(job, timeout_s = 600)
  expect_equal(st$state, "running")
  expect_equal(st$done, 0); expect_equal(st$total, 1000)
  expect_equal(st$precheck, "topology_change_needed")
  writeLines("450 1000", job$progress_file)                  # no status token: precheck is NULL
  expect_null(designer_job_poll(job, timeout_s = 600)$precheck)
})

# -- Final review items 3 and 4 -------------------------------------------------
test_that("worker env pins BLAS/OpenMP to one thread and reaches the worker", {
  env <- .designer_worker_env()
  expect_identical(unname(env["OPENBLAS_NUM_THREADS"]), "1")
  expect_identical(unname(env["OMP_NUM_THREADS"]), "1")
  expect_true(all(names(callr::rcmd_safe_env()) %in% names(env)))
  skip_if_not_installed("callr")
  got <- callr::r(function() Sys.getenv(c("OPENBLAS_NUM_THREADS", "OMP_NUM_THREADS")),
                  env = .designer_worker_env())
  expect_equal(unname(got), c("1", "1"))
})

test_that("a designer job has no unread stdout/stderr pipes", {
  skip_if_not_installed("callr")
  job <- designer_job_start(tiny_payload(), designer_engine_files(app_root()))
  withr::defer(designer_job_cancel(job))
  expect_false(job$process$has_output_connection())
  expect_false(job$process$has_error_connection())
  expect_equal(wait_for(job)$state, "done")
})

test_that("the timeout branch writes a debug_log line", {
  skip_if_not_installed("callr")
  logged <- character(0)
  had <- exists("debug_log", envir = globalenv(), inherits = FALSE)
  old <- if (had) get("debug_log", envir = globalenv()) else NULL
  assign("debug_log", function(msg, ctx = "") logged <<- c(logged, paste(ctx, msg)), envir = globalenv())
  withr::defer(if (had) assign("debug_log", old, envir = globalenv()) else rm("debug_log", envir = globalenv()))
  job <- list(process = callr::r_bg(function() Sys.sleep(30)),
              progress_file = tempfile("designer_progress_", fileext = ".txt"), started = Sys.time() - 1000)
  withr::defer(designer_job_cancel(job))
  st <- designer_job_poll(job, timeout_s = 1)
  expect_identical(st$reason, "timeout")
  expect_true(any(grepl("timed out", logged)))
})
