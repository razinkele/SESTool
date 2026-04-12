# modules/guidebook_module.R
# Guidebook module - displays the user guidebook in-app and provides download links

# Resolve language-specific guidebook path with English fallback
resolve_guidebook_rmd <- function(i18n) {
  lang <- tryCatch(i18n$get_translation_language(), error = function(e) "en")
  rmd_file <- file.path("guidebook", paste0("guidebook_", lang, ".Rmd"))
  if (!file.exists(rmd_file)) {
    rmd_file <- file.path("guidebook", "guidebook_en.Rmd")
  }
  rmd_file
}

guidebook_ui <- function(id, i18n) {
  ns <- NS(id)
  shiny.i18n::usei18n(i18n)

  fluidPage(
    fluidRow(
      column(12,
        tags$div(
          class = "guidebook-header",
          style = "padding: 20px; background: linear-gradient(135deg, #2c3e50, #3498db); color: white; border-radius: 10px; margin-bottom: 20px;",
          h3(icon("book"), " ", i18n$t("modules.guidebook.title")),
          p(i18n$t("modules.guidebook.subtitle")),
          downloadButton(ns("download_pdf"), i18n$t("modules.guidebook.download_pdf"),
                        class = "btn btn-light"),
          downloadButton(ns("download_html"), i18n$t("modules.guidebook.download_html"),
                        class = "btn btn-outline-light")
        )
      )
    ),
    fluidRow(
      column(12,
        uiOutput(ns("guidebook_content"))
      )
    )
  )
}

guidebook_server <- function(id, project_data_reactive, i18n, event_bus = NULL) {
  moduleServer(id, function(input, output, session) {

    # Render guidebook content as HTML from the language-specific Rmd file.
    # Uses markdown::markdownToHTML (instant) instead of rmarkdown::render
    # (which blocks session init for 10-30s on cold starts). The Rmd files
    # are pure prose — no R code chunks — so markdown rendering is equivalent.
    # YAML front matter is stripped before rendering.
    output$guidebook_content <- renderUI({
      rmd_path <- resolve_guidebook_rmd(i18n)
      tryCatch({
        if (!file.exists(rmd_path)) stop("File not found")
        lines <- readLines(rmd_path, encoding = "UTF-8", warn = FALSE)
        yaml_markers <- which(lines == "---")
        if (length(yaml_markers) >= 2) {
          lines <- lines[(yaml_markers[2] + 1):length(lines)]
        }
        html <- markdown::markdownToHTML(
          text = paste(lines, collapse = "\n"),
          fragment.only = TRUE,
          encoding = "UTF-8"
        )
        tags$div(class = "guidebook-body", HTML(html))
      }, error = function(e) {
        debug_log(paste("Guidebook render failed:", e$message), "ERROR")
        tags$div(class = "alert alert-info",
                i18n$t("modules.guidebook.fallback_message"))
      })
    })

    output$download_pdf <- downloadHandler(
      filename = function() paste0("SES_Toolbox_Guidebook_", Sys.Date(), ".pdf"),
      content = function(file) {
        withProgress(message = i18n$t("modules.guidebook.generating_pdf"), {
          rmarkdown::render(resolve_guidebook_rmd(i18n),
                           output_format = rmarkdown::pdf_document(latex_engine = "xelatex"),
                           output_file = file,
                           intermediates_dir = tempdir(),
                           encoding = "UTF-8",
                           quiet = TRUE)
        })
      }
    )

    output$download_html <- downloadHandler(
      filename = function() paste0("SES_Toolbox_Guidebook_", Sys.Date(), ".html"),
      content = function(file) {
        withProgress(message = i18n$t("modules.guidebook.generating_html"), {
          rmarkdown::render(resolve_guidebook_rmd(i18n),
                           output_format = "html_document",
                           output_file = file,
                           intermediates_dir = tempdir(),
                           encoding = "UTF-8",
                           quiet = TRUE)
        })
      }
    )
  })
}
