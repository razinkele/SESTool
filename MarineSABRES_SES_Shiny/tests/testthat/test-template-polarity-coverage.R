# Evidenced polarity (Task 9): a shipped template's signs are evidence, so every
# template connection must carry an explicit +/-; the loader no longer invents a "+".

.tpl_root <- function() {
  wd <- getwd()
  if (basename(wd) == "testthat") return(dirname(dirname(wd)))
  wd
}
.tpl_root_dir <- .tpl_root()

if (!exists("load_all_templates", mode = "function")) {
  if (!exists("debug_log", mode = "function")) debug_log <- function(...) invisible(NULL)
  if (!exists("log_warning", mode = "function")) log_warning <- function(...) invisible(NULL)
  source(file.path(.tpl_root_dir, "functions", "template_loader.R"), local = FALSE)
}

test_that("every connection in every shipped template has an explicit sign", {
  files <- list.files(file.path(.tpl_root_dir, "data"), pattern = "_SES_Template[.]json$",
                      full.names = TRUE)
  expect_gt(length(files), 0)
  for (f in files) {
    cons <- jsonlite::fromJSON(f, simplifyVector = FALSE)$connections
    for (i in seq_along(cons)) {
      p <- cons[[i]]$polarity
      expect_true(is.character(p) && length(p) == 1 && p %in% c("+", "-"),
                  info = sprintf("%s connection %d (%s -> %s) has no +/- sign",
                                 basename(f), i, cons[[i]]$from_id, cons[[i]]$to_id))
    }
  }
})

test_that("every non-empty matrix cell of every loaded template starts with + or -", {
  old <- setwd(.tpl_root_dir); on.exit(setwd(old), add = TRUE)
  tpls <- load_all_templates("data")
  expect_gt(length(tpls), 0)
  for (nm in names(tpls)) {
    for (mn in names(tpls[[nm]]$adjacency_matrices)) {
      m <- tpls[[nm]]$adjacency_matrices[[mn]]
      cells <- m[!is.na(m) & nzchar(m)]
      expect_true(all(grepl("^[+-]", cells)), info = paste(nm, mn))
    }
  }
})

test_that("a template connection without a sign is a load error, not a silent '+'", {
  src <- readLines(file.path(.tpl_root_dir, "functions", "template_loader.R"), warn = FALSE)
  expect_false(any(grepl('polarity %||% "+"', src, fixed = TRUE)))

  tmp <- tempfile(fileext = "_SES_Template.json")
  on.exit(unlink(tmp), add = TRUE)
  good <- list.files(file.path(.tpl_root_dir, "data"), pattern = "_SES_Template[.]json$",
                     full.names = TRUE)[1]
  j <- jsonlite::fromJSON(good, simplifyVector = FALSE)
  j$connections[[1]]$polarity <- NULL
  writeLines(jsonlite::toJSON(j, auto_unbox = TRUE), tmp)
  msgs <- character(0)
  assign("log_warning", function(ctx, msg, ...) msgs <<- c(msgs, msg), envir = .GlobalEnv)
  on.exit(rm("log_warning", envir = .GlobalEnv), add = TRUE)
  res <- load_template_from_json(tmp, use_cache = FALSE)
  expect_null(res)
  expect_true(any(grepl("sign", msgs)))
})
