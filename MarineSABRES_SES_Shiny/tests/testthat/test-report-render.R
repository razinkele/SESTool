# tests/testthat/test-report-render.R
# Review 2026-10-07 N11 (user text knitted as R Markdown = server-side code
# execution), N14 (reports served from the shared www/reports tree) and N41
# (LaTeX probe false positive). Red before functions/report_render.R existed.
source_for_test("functions/report_render.R")

# A body shaped like generate_report_content() output, carrying every payload
# class the review named: inline R, an R chunk, raw HTML, an in-body YAML block.
injected_report <- function() paste(c(
  "---",
  "title: 'MarineSABRES SES Analysis Report'",
  "subtitle: 'full Report'",
  "date: 'October 09, 2026'",
  "output:", "  html_document:", "    toc: true", "---", "",
  "# Project Overview", "",
  "**Project:** Fishing `r system('echo PWNED-INLINE', intern = TRUE)` fleet", "",
  "**Focal Issue:** Overfishing", "", "```{r}", "stop('PWNED-CHUNK')", "```", "",
  "Cod <script>alert('PWNED-XSS')</script> & <b>bold</b> stock", "",
  "---", "title: HIJACKED", "header-includes: '<script>alert(2)</script>'", "---", "",
  "```{=html}", "<script>alert('PWNED-RAWATTR')</script>", "```", "",
  "Species \\input{PWNED-RAWTEX} list", "",
  "## Section two", "", "- a & b < c"
), collapse = "\n")

test_that("split_report_markdown separates the generator's YAML header from the body", {
  p <- split_report_markdown(injected_report())
  expect_equal(p$meta$title, "MarineSABRES SES Analysis Report")
  expect_equal(p$meta$subtitle, "full Report")
  expect_equal(p$meta$date, "October 09, 2026")
  expect_equal(p$body[1], "# Project Overview")
  expect_false(any(grepl("^output:", p$body)))
  # no header at all -> whole text is body
  q <- split_report_markdown(c("# Title", "", "text"))
  expect_null(q$meta$title)
  expect_equal(q$body, c("# Title", "", "text"))
})

test_that("escape_metadata_delimiters neutralises --- and ... lines only", {
  out <- escape_metadata_delimiters(c("---", "  ...  ", "a --- b", "----", "text"))
  expect_equal(out, c("\\---", "  \\...  ", "a --- b", "----", "text"))
})

test_that("latex_engine_available returns a single logical and is FALSE for a bogus engine", {
  r <- latex_engine_available("definitely-not-a-latex-engine-xyz")
  expect_type(r, "logical"); expect_length(r, 1)
  # Only FALSE when tinytex is absent too; otherwise tinytex root counts.
  if (!requireNamespace("tinytex", quietly = TRUE) || !nzchar(tryCatch(tinytex::tinytex_root(), error = function(e) "")))
    expect_false(r)
})

test_that("render_report_safely fails with class pandoc_missing when pandoc is unavailable", {
  out <- tempfile(fileext = ".html")
  expect_error(render_report_safely(injected_report(), out, "html", pandoc_available = FALSE),
               class = "pandoc_missing")
  expect_false(file.exists(out))
})

test_that("N11: render_report_safely never evaluates user text and escapes raw HTML", {
  skip_if_not(rmarkdown::pandoc_available(), "pandoc not available")
  out <- tempfile(fileext = ".html")
  expect_silent(render_report_safely(injected_report(), out, "html"))
  expect_true(file.exists(out))
  h <- paste(readLines(out, warn = FALSE, encoding = "UTF-8"), collapse = "\n")

  # inline R shown literally, never run
  expect_true(grepl("<code>r system(&#39;echo PWNED-INLINE&#39;", h, fixed = TRUE))
  # the R chunk did not execute (render would have errored on stop()) and is shown as code
  expect_true(grepl("PWNED-CHUNK", h, fixed = TRUE))
  # raw HTML is escaped, not injected
  # (html_document ships its own <script> tags, so test the payload specifically)
  expect_false(grepl("<script>alert(", h, fixed = TRUE))
  expect_true(grepl("&lt;script&gt;alert(", h, fixed = TRUE))
  expect_true(grepl("PWNED-XSS", h, fixed = TRUE))
  # in-body YAML block cannot hijack the document metadata
  expect_true(grepl("<title>MarineSABRES SES Analysis Report</title>", h, fixed = TRUE))
  expect_false(grepl("alert(2)</script>", h, fixed = TRUE))
  # fenced raw blocks ({=html}) are not passed through (raw_attribute disabled)
  expect_false(grepl("<script>alert('PWNED-RAWATTR')", h, fixed = TRUE))
  expect_false(grepl("<script>alert(&#39;PWNED-RAWATTR", h, fixed = TRUE))
  # raw TeX is not interpreted: with raw_tex on, pandoc silently DROPS raw TeX
  # from HTML output, so literal survival is the discriminator
  expect_true(grepl("PWNED-RAWTEX", h, fixed = TRUE))
  # ordinary content still renders
  expect_true(grepl("Section two", h, fixed = TRUE))
  expect_true(grepl("full Report", h, fixed = TRUE))
})

test_that("N14: register_session_report serves the file through the session and writes nothing to www/reports", {
  html <- tempfile(fileext = ".html"); writeLines("<html><body>hi</body></html>", html)
  captured <- new.env()
  fake_session <- list(registerDataObj = function(name, data, filterFunc) {
    captured$name <- name; captured$data <- data; captured$filter <- filterFunc
    paste0("session/abc123/dataobj/", name, "?w=")
  })
  www_before <- if (dir.exists("www/reports")) list.files("www/reports") else character(0)

  url <- register_session_report(fake_session, html)
  expect_true(startsWith(url, "session/abc123/dataobj/report_"))
  expect_equal(captured$data, html)

  resp <- captured$filter(captured$data, list())
  expect_equal(resp$status, 200L)
  expect_true(grepl("text/html", resp$content_type))
  expect_equal(trimws(rawToChar(resp$content)), "<html><body>hi</body></html>")

  unlink(html)
  expect_equal(captured$filter(captured$data, list())$status, 404L)

  www_after <- if (dir.exists("www/reports")) list.files("www/reports") else character(0)
  expect_equal(www_after, www_before)
  expect_error(register_session_report(list(), html), "registerDataObj")
})
