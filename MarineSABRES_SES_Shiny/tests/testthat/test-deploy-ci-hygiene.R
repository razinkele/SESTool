# tests/testthat/test-deploy-ci-hygiene.R
# Review 2026-10-07 batch 6 (docs/code-review-2026-10-07.md):
#   N44 per-file CI runner passed files with zero passing expectations
#   N8  remote-deploy.sh shipped a working-tree tar and wiped the feedback log
#   N42 deploys reset data/ to 755 (shiny user could not write there)
#   N43 root-run scripts killed every app's R processes / overwrote the global conf
#   N80 git-archive deploy shipped tests/, .claude/, DTU/, Documents/, deployment/

app_root <- function() {
  wd <- getwd()
  if (basename(wd) == "testthat") dirname(dirname(wd)) else wd
}
rscript <- function() file.path(R.home("bin"), "Rscript")
read_src <- function(rel) paste(readLines(file.path(app_root(), rel), warn = FALSE), collapse = "\n")

run_ci_file <- function(test_body, allow = character(0), name = "test-zz-probe.R") {
  d <- tempfile("ci_probe_"); dir.create(d)
  f <- file.path(d, name)
  writeLines(c("library(testthat)", test_body), f)
  allow_file <- file.path(d, "allow.txt"); writeLines(allow, allow_file)
  # withr rather than system2(env=): on Windows system2 prepends env to the
  # command line instead of setting it.
  out <- withr::with_envvar(c(CI_ALLOW_ZERO_PASS_FILE = allow_file, CI = "false"),
    suppressWarnings(system2(rscript(), c(shQuote(file.path(app_root(), "tests", "ci_run_file.R")), shQuote(f)),
                             stdout = TRUE, stderr = TRUE)))
  status <- attr(out, "status") %||% 0L
  list(status = status, out = paste(out, collapse = "\n"))
}

# ---------------------------------------------------------------------------
# N44 — CI runner semantics (spawns the real runner on throwaway files)
# ---------------------------------------------------------------------------
test_that("N44: a file whose every test skips fails the CI runner", {
  r <- run_ci_file('test_that("x", { skip("nope"); expect_true(TRUE) })')
  expect_equal(r$status, 1L, info = r$out)
  expect_match(r$out, "ZERO PASSING EXPECTATIONS")
})

test_that("N44: the same file passes when it is allowlisted", {
  r <- run_ci_file('test_that("x", { skip("nope"); expect_true(TRUE) })', allow = c("# reason", "test-zz-probe.R"))
  expect_equal(r$status, 0L, info = r$out)
})

test_that("N44: ordinary passing and failing files keep their exit codes", {
  ok <- run_ci_file('test_that("x", expect_true(TRUE))')
  expect_equal(ok$status, 0L, info = ok$out)
  bad <- run_ci_file('test_that("x", expect_true(FALSE))')
  expect_equal(bad$status, 1L, info = bad$out)
})

test_that("N44: every allowlisted file exists and carries a reason comment block", {
  lines <- readLines(file.path(app_root(), "tests", "ci_allow_zero_pass.txt"), warn = FALSE)
  entries <- trimws(sub("#.*$", "", lines)); entries <- entries[nzchar(entries)]
  expect_gt(length(entries), 0)
  for (e in entries) expect_true(file.exists(file.path(app_root(), "tests", "testthat", e)), info = e)
})

test_that("N44: template versioning is loaded even without torch (was torch-gated, so CI skipped all of it)", {
  expect_true(exists("create_template_version", mode = "function"))
  src <- readLines(file.path(app_root(), "global.R"), warn = FALSE)
  ml_start <- grep("^if \\(ML_ENABLED\\) \\{", src)[1]
  tv_line  <- grep('source\\("functions/template_versioning.R"', src)
  expect_length(tv_line, 1)
  # the source() must come after the ML if/else, at top level (no indentation)
  expect_gt(tv_line, ml_start)
  expect_true(grepl("^source\\(", src[tv_line]))
})

# ---------------------------------------------------------------------------
# N80 — what the git-archive deploy actually ships
# ---------------------------------------------------------------------------
test_that("N80: the deploy archive excludes non-runtime trees but keeps runtime files", {
  git <- Sys.which("git")
  skip_if(!nzchar(git), "git not available")
  root <- app_root()
  top <- suppressWarnings(system2(git, c("-C", shQuote(root), "rev-parse", "--show-toplevel"), stdout = TRUE, stderr = FALSE))
  skip_if(length(top) == 0 || !nzchar(top[1]), "not a git checkout")
  prefix <- suppressWarnings(system2(git, c("-C", shQuote(root), "rev-parse", "--show-prefix"), stdout = TRUE, stderr = FALSE))
  prefix <- sub("/$", "", prefix[1] %||% "")
  attr_path <- if (nzchar(prefix)) paste0("HEAD:", prefix, "/.gitattributes") else "HEAD:.gitattributes"
  has_attr <- suppressWarnings(system2(git, c("-C", shQuote(top[1]), "cat-file", "-e", attr_path),
                                       stdout = FALSE, stderr = FALSE))
  skip_if(!identical(as.integer(has_attr), 0L), ".gitattributes not committed in HEAD yet")
  # Same command shape as the deploy scripts: HEAD restricted to the app path
  # (a HEAD:<prefix> subtree archive ignores the app .gitattributes).
  zip <- tempfile(fileext = ".zip")
  args <- c("-C", shQuote(top[1]), "archive", "--format=zip", "-o", shQuote(zip), "HEAD")
  if (nzchar(prefix)) args <- c(args, "--", prefix)
  st <- system2(git, args)
  expect_equal(as.integer(st), 0L)
  files <- utils::unzip(zip, list = TRUE)$Name
  if (nzchar(prefix)) files <- sub(paste0("^", prefix, "/"), "", files)
  files <- files[!grepl("/$", files)]          # directory stubs left by export-ignore
  expect_false(any(startsWith(files, "tests/")))
  expect_false(any(startsWith(files, ".claude/")))
  expect_false(any(startsWith(files, "DTU/")))
  expect_false(any(startsWith(files, "SESModels/.claude/")))
  expect_equal(grep("^deployment/.+[^/]$", files, value = TRUE), "deployment/required_packages.R")
  expect_equal(grep("^Documents/.+[^/]$", files, value = TRUE), "Documents/MarineSABRES_Simple_SES_DRAFT_Guidance.pdf")
  expect_true("docs/MarineSABRES_User_Manual_EN.html" %in% files)   # served via addResourcePath
  expect_true(all(c("app.R", "global.R", "VERSION") %in% files))
})

test_that("N8: remote-deploy.sh --dry-run builds the archive from committed files without SSH", {
  skip_on_os("windows")   # Windows 'bash' may resolve to WSL; the script targets Linux/Mac
  bash <- Sys.which("bash"); skip_if(!nzchar(bash), "bash not available")
  out <- suppressWarnings(system2(bash, c(shQuote(file.path(app_root(), "deployment", "remote-deploy.sh")), "--dry-run"),
                                  stdout = TRUE, stderr = TRUE))
  status <- attr(out, "status") %||% 0L
  skip_if(any(grepl("not inside a git repository", out)), "not a git checkout")
  expect_equal(status, 0L, info = paste(tail(out, 20), collapse = "\n"))
  listing <- out[grepl("^[A-Za-z0-9_.]", out) & !grepl("/$", out)]
  listing <- sub("^[^/]*MarineSABRES_SES_Shiny/", "", listing)   # entries keep the repo prefix
  expect_true("app.R" %in% listing)
  expect_false(any(startsWith(listing, "tests/")))
  # untracked user exports / archived bundles in the working tree never ship
  expect_false(any(grepl("naujausias|ISA_Export|phase-c-bundle|\\.v1\\.13", listing)))
})

# ---------------------------------------------------------------------------
# N8 / N42 / N43 — static guards on the shell/PowerShell deploy scripts
# (labelled: these are source checks for scripts that cannot run in CI)
# ---------------------------------------------------------------------------
test_that("N8/N42 (static): both deploy paths preserve the feedback log and keep data/ group-writable", {
  for (rel in c("deployment/deploy-remote.ps1", "deployment/remote-deploy.sh")) {
    src <- read_src(rel)
    expect_match(src, "user_feedback_log\\*\\.ndjson", info = rel)
    expect_match(src, "chmod 775 \\$\\{?REMOTE_?TARGET\\}?/data|chmod 775 \\$\\{RemoteTarget\\}/data/", info = rel)
    expect_match(src, "restart\\.txt", info = rel)
  }
  sh <- read_src("deployment/remote-deploy.sh")
  expect_match(sh, "git -C \"\\$REPO_ROOT\" archive")
  expect_false(grepl("--exclude=", sh, fixed = TRUE))   # no hand-maintained working-tree tar any more
})

test_that("N43 (static): no deploy script kills every Shiny R process, wipes shared caches or silently replaces the global conf", {
  sh_files <- list.files(file.path(app_root(), "deployment"), pattern = "\\.sh$", full.names = TRUE)
  for (f in sh_files) {
    src <- readLines(f, warn = FALSE)
    code <- src[!grepl("^\\s*#", src)]
    expect_false(any(grepl("pkill[^\n]*'shiny\\.\\*R'", code)), info = basename(f))
    expect_false(any(grepl("rm -rf[^\n]*/var/lib/shiny-server/bookmarks", code)), info = basename(f))
    expect_false(any(grepl("rm -rf[^\n]*/tmp/shiny-server", code)), info = basename(f))
    conf_copies <- grep("cp [^\n]*shiny-server\\.conf\"? /etc/shiny-server/shiny-server\\.conf$", code)
    for (i in conf_copies) {
      window <- paste(code[max(1, i - 12):i], collapse = "\n")
      expect_true(grepl("FORCE_SHINY_CONF|! -f /etc/shiny-server/shiny-server.conf", window), info = paste(basename(f), i))
    }
  }
})
