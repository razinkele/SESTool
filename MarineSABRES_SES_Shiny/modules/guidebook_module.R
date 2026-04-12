# modules/guidebook_module.R
# Guidebook module - displays the user guidebook in-app and provides download links

# Resolve language-specific guidebook Rmd path with English fallback
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

    # Cache: render once per session, reuse on subsequent tab visits
    cached_html_path <- reactiveVal(NULL)

    output$guidebook_content <- renderUI({
      # Use includeMarkdown (instant) instead of rmarkdown::render (slow).
      # bs4Dash renders ALL tabs eagerly at session start, so any blocking
      # call here hangs the entire session initialization — even if the user
      # never visits the Guidebook tab. rmarkdown::render took 10-30s on
      # cold server starts with new language files, causing the language-switch
      # hang that broke production on 2026-04-12.
      rmd_path <- resolve_guidebook_rmd(i18n)
      if (file.exists(rmd_path)) {
        tags$div(class = "guidebook-body",
                shiny::includeMarkdown(rmd_path))
      } else {
        tags$div(class = "alert alert-info",
                i18n$t("modules.guidebook.fallback_message"))
      }
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
