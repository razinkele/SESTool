# functions/report_render.R
# Safe rendering + serving of generated reports (review 2026-10-07 N11, N14, N41)
#
# generate_report_content() (functions/report_generation.R) returns Markdown
# that embeds user-influenced text: project name, demonstration area, focal
# issue, element / stakeholder names, loop paths. Until v1.19.1 that Markdown
# was written to a .Rmd and knitted with rmarkdown::render(), so a focal issue
# or element name containing `r ...` or a ```{r} fence executed R code on the
# server as the shiny user. This file replaces that path:
#
#   * the only Rmd that is ever knitted is the static, user-text-free shell
#     templates/report_template.Rmd, which emits the body with results='asis'
#     (knitr never evaluates the body);
#   * pandoc runs with md_extensions = "-raw_html" so raw HTML in the body is
#     rendered as text (no stored XSS in the report window), and YAML delimiter
#     lines inside the body are escaped so an in-body metadata block cannot
#     hijack title / header-includes;
#   * HTML reports are served through session$registerDataObj() (a URL that is
#     only valid for the generating session) instead of being copied into the
#     statically served, process-wide www/reports directory under a
#     timestamp-only name.
# ============================================================================

#' Path of the static report template shipped with the app
#' @return character(1)
report_template_path <- function() {
  root <- if (exists("PROJECT_ROOT") && is.character(PROJECT_ROOT) && nzchar(PROJECT_ROOT[1])) {
    PROJECT_ROOT[1]
  } else {
    getwd()
  }
  file.path(root, "templates", "report_template.Rmd")
}

#' Split generated report Markdown into its YAML front matter and body
#'
#' generate_report_content() prepends a constant YAML header (title, subtitle,
#' date, output). The safe renderer passes those as template params instead of
#' letting pandoc read them from the document, so the header is stripped here.
#' Pure.
#'
#' @param report_md character: a single string or a character vector of lines
#' @return list(meta = list(title, subtitle, date) (NULL when absent),
#'   body = character vector of body lines)
split_report_markdown <- function(report_md) {
  lines <- unlist(strsplit(paste(report_md, collapse = "\n"), "\n", fixed = TRUE))
  meta <- list(title = NULL, subtitle = NULL, date = NULL)
  if (length(lines) == 0 || trimws(lines[1]) != "---") {
    return(list(meta = meta, body = lines))
  }
  end <- which(trimws(lines[-1]) %in% c("---", "..."))
  if (length(end) == 0) return(list(meta = meta, body = lines))
  end <- end[1] + 1L                      # index in `lines` of the closing delimiter
  header <- lines[2:(end - 1L)]
  grab <- function(key) {
    m <- grep(paste0("^", key, ":\\s*"), header, value = TRUE)
    if (length(m) == 0) return(NULL)
    v <- sub(paste0("^", key, ":\\s*"), "", m[1])
    v <- sub("^['\"]", "", v); v <- sub("['\"]\\s*$", "", v)
    if (nzchar(v)) v else NULL
  }
  meta$title    <- grab("title")
  meta$subtitle <- grab("subtitle")
  meta$date     <- grab("date")
  body <- if (end < length(lines)) lines[(end + 1L):length(lines)] else character(0)
  while (length(body) > 0 && !nzchar(trimws(body[1]))) body <- body[-1]
  list(meta = meta, body = body)
}

#' Escape YAML metadata-block delimiter lines inside a Markdown body
#'
#' pandoc accepts a YAML metadata block anywhere in the document, so a body
#' line consisting of `---` (or the closing `...`) lets user text redefine
#' title / header-includes. Prefixing the delimiter with a Markdown backslash
#' escape turns it into literal text. Pure.
#'
#' @param lines character vector of body lines
#' @return character vector of the same length
escape_metadata_delimiters <- function(lines) {
  sub("^([[:space:]]*)(---|[.][.][.])([[:space:]]*)$", "\\1\\\\\\2\\3", lines)
}

#' Is a LaTeX engine usable for PDF rendering?
#'
#' Replaces the probes that treated `tinytex::tinytex_root()` returning "" and a
#' failing `system("pdflatex --version")` as success (review 2026-10-07 N41).
#'
#' @param engine executable name (default "lualatex", the engine used for PDFs)
#' @return logical(1)
latex_engine_available <- function(engine = "lualatex") {
  if (nzchar(Sys.which(engine))) return(TRUE)
  root <- tryCatch(
    if (requireNamespace("tinytex", quietly = TRUE)) tinytex::tinytex_root() else "",
    error = function(e) ""
  )
  is.character(root) && length(root) == 1 && nzchar(root)
}

#' Render generated report Markdown without ever knitting user text
#'
#' @param report_md Markdown returned by generate_report_content()
#' @param output_file destination path (.html / .pdf / .docx)
#' @param format "html", "pdf" or "docx"
#' @param pdf_engine LaTeX engine for PDF output
#' @param template path of the static Rmd shell
#' @param pandoc_available override for tests
#' @param quiet passed to rmarkdown::render()
#' @return invisible(output_file). Errors: class "pandoc_missing" when pandoc
#'   is unavailable, "latex_missing" when a PDF is requested without an engine.
render_report_safely <- function(report_md, output_file,
                                 format = c("html", "pdf", "docx"),
                                 pdf_engine = "lualatex",
                                 template = report_template_path(),
                                 pandoc_available = rmarkdown::pandoc_available(),
                                 quiet = TRUE,
                                 i18n = NULL) {
  format <- match.arg(format)
  # Messages are user-facing (modules surface them via format_user_error), so
  # translate when a translator is supplied; the keys exist x9 languages.
  # i18n-ref: common.messages.pandoc_required
  # i18n-ref: common.messages.latex_required
  msg <- function(key, fallback) {
    if (!is.null(i18n) && is.function(i18n$t)) {
      out <- tryCatch(i18n$t(key), error = function(e) NULL)
      if (is.character(out) && length(out) == 1 && nzchar(out) && out != key) return(out)
    }
    fallback
  }
  if (!isTRUE(pandoc_available)) {
    stop(structure(class = c("pandoc_missing", "error", "condition"),
                   list(message = msg("common.messages.pandoc_required",
                                      "pandoc is not available on this server"),
                        call = NULL)))
  }
  if (format == "pdf" && !latex_engine_available(pdf_engine)) {
    stop(structure(class = c("latex_missing", "error", "condition"),
                   list(message = msg("common.messages.latex_required",
                                      paste("LaTeX engine not available:", pdf_engine)),
                        call = NULL)))
  }
  if (!file.exists(template)) stop("Report template not found: ", template)

  parts <- split_report_markdown(report_md)
  body  <- escape_metadata_delimiters(parts$body)

  work_dir  <- tempfile("report_render_"); dir.create(work_dir)
  on.exit(unlink(work_dir, recursive = TRUE), add = TRUE)
  body_file <- file.path(work_dir, "body.md")
  writeLines(enc2utf8(body), body_file, useBytes = TRUE)
  tpl <- file.path(work_dir, "report_template.Rmd")
  file.copy(template, tpl, overwrite = TRUE)

  ext <- "-raw_html"
  output_format <- switch(format,
    html = rmarkdown::html_document(toc = TRUE, toc_float = TRUE, md_extensions = ext),
    pdf  = rmarkdown::pdf_document(latex_engine = pdf_engine, md_extensions = ext),
    docx = rmarkdown::word_document(md_extensions = ext)
  )

  output_file <- normalizePath(output_file, winslash = "/", mustWork = FALSE)
  rmarkdown::render(
    input         = tpl,
    output_format = output_format,
    output_file   = basename(output_file),
    output_dir    = dirname(output_file),
    params = list(
      title     = parts$meta$title    %||% "MarineSABRES SES Analysis Report",
      subtitle  = parts$meta$subtitle %||% "",
      date      = parts$meta$date     %||% format(Sys.Date(), "%B %d, %Y"),
      body_file = body_file
    ),
    envir = new.env(parent = globalenv()),
    quiet = quiet
  )
  invisible(output_file)
}

#' Serve a rendered HTML report through a session-scoped URL
#'
#' The URL returned by session$registerDataObj() is bound to the generating
#' session (and stops working when that session ends), so no report is ever
#' written into the shared www/ tree where any client could enumerate it.
#'
#' @param session Shiny session (must support registerDataObj)
#' @param html_path path of the rendered HTML file
#' @param name optional object name (random by default)
#' @return the relative URL to open in the browser
register_session_report <- function(session, html_path, name = NULL) {
  if (is.null(session) || !is.function(session$registerDataObj)) {
    stop("session does not support registerDataObj()")
  }
  if (is.null(name)) {
    name <- paste0("report_", paste(sample(c(letters, 0:9), 16, replace = TRUE), collapse = ""))
  }
  session$registerDataObj(name, html_path, function(data, req) {
    if (!file.exists(data)) {
      return(shiny::httpResponse(404, "text/plain; charset=utf-8", "Report no longer available"))
    }
    shiny::httpResponse(200, "text/html; charset=utf-8",
                        readBin(data, what = "raw", n = file.info(data)$size))
  })
}
