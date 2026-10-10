# tests/testthat/test-load-path-normalize.R
# Review 2026-10-07 N74: this used to be a source-grep that passed even with
# the normalisation call commented out of the load path. It now checks what the
# normaliser does to a legacy-shaped project, and that each load path applies
# it BEFORE the project reaches the app.

legacy_project <- function() {
  list(
    project_id = "p1", project_name = "legacy",
    data = list(isa_data = list(
      drivers    = data.frame(id = c("D1", "D2"), name = c("Food demand", "Jobs"),
                              stringsAsFactors = FALSE),
      activities = data.frame(ID = c("A1", "A1"), Name = c("Fishing", "Tourism"),
                              stringsAsFactors = FALSE),          # duplicate ID, different names
      responses  = data.frame(id = "R1", name = "Quota", stringsAsFactors = FALSE)
    ))
  )
}

test_that("N74: load normalisation gives every element frame an ID column, incl. responses", {
  # normalize_and_reconcile_project() lowercases columns and reconciles IDs
  # (ID upper-case); the remaining canonical case is applied when the ISA
  # module imports the saved project via recover_isa_data() (N24).
  isa <- normalize_and_reconcile_project(legacy_project())$data$isa_data
  for (k in c("drivers", "activities", "responses")) {
    expect_true("ID" %in% names(isa[[k]]), info = k)
    expect_false("id" %in% names(isa[[k]]), info = k)
  }
})

test_that("N74: the full load chain (normalise -> ISA import) yields canonical columns", {
  isa <- normalize_and_reconcile_project(legacy_project())$data$isa_data
  rec <- recover_isa_data(isa)
  for (k in c("drivers", "activities", "responses")) {
    df <- rec$elements[[k]]
    expect_true(all(c("ID", "Name") %in% names(df)), info = k)
    expect_false(any(c("id", "name") %in% names(df)), info = k)
  }
  expect_setequal(rec$elements$drivers$Name, c("Food demand", "Jobs"))
  expect_identical(rec$elements$responses$Name, "Quota")
})

test_that("N74: duplicate IDs with different names become distinct elements", {
  isa <- normalize_and_reconcile_project(legacy_project())$data$isa_data
  expect_equal(nrow(isa$activities), 2L)
  expect_false(anyDuplicated(isa$activities$ID) > 0)
  expect_setequal(isa$activities$name, c("Fishing", "Tourism"))   # lowercase until ISA import
})

test_that("N74: non-list input is returned unchanged", {
  expect_null(normalize_and_reconcile_project(NULL))
  expect_identical(normalize_and_reconcile_project("x"), "x")
})

test_that("N74: each load path normalises before handing the project to the app", {
  check_order <- function(rel, normalise_pat, publish_pat) {
    src <- readLines(testthat::test_path("..", "..", rel), warn = FALSE)
    code <- sub("#.*$", "", src)
    n_at <- grep(normalise_pat, code, fixed = TRUE)
    p_at <- grep(publish_pat, code, fixed = TRUE)
    expect_gt(length(n_at), 0)
    expect_gt(length(p_at), 0)
    # every publish has a normalisation call shortly before it
    for (p in p_at) expect_true(any(n_at < p & n_at > p - 15), info = paste(rel, "line", p))
  }
  check_order("server/project_io.R",
              "loaded_data <- normalize_and_reconcile_project(loaded_data)",
              "project_data(loaded_data)")
  check_order("modules/auto_save_module.R",
              "recovered_data <- normalize_and_reconcile_project(recovered_data)",
              "project_data_reactive(recovered_data)")
})
