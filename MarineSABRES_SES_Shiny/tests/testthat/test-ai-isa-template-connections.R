# test-ai-isa-template-connections.R
# Regression tests: an AI-assistant project built from a template saved all
# its connections under legacy matrix names (a_d, p_a, mpf_p, es_mpf, gb_es)
# next to empty forward matrices, and create_edges_df() read only the forward
# ones, so the diagram had no links at all (found 2026-10-19 while tracing the
# swapped-connection follow-up from PR #123).

library(testthat)
library(shiny)

local({
  td   <- getwd()
  root <- if (basename(td) == "testthat") dirname(dirname(td)) else td
  old_wd <- setwd(root)
  on.exit(setwd(old_wd), add = TRUE)
  for (sm in c("connection_generator", "ui_components", "question_flow", "data_persistence",
               "ui_renderers", "template_handlers", "action_handlers", "step_navigation")) {
    tryCatch(sys.source(file.path(root, "modules/ai_isa", paste0(sm, ".R")), envir = .GlobalEnv),
             error = function(e) message("could not source ", sm, ": ", e$message))
  }
  tryCatch(sys.source(file.path(root, "modules/ai_isa_assistant_module.R"), envir = .GlobalEnv),
           error = function(e) message("could not source ai_isa_assistant_module.R: ", e$message))
})

ai_isa_assistant_server <- get("ai_isa_assistant_server", envir = .GlobalEnv)
i18n <- list(t = function(key, ...) key, get_translation_language = function() "en")

# "from -> to" names of every CLD edge built from the saved project
cld_links <- function(isa) {
  e <- create_edges_df(isa, isa$adjacency_matrices)
  if (!nrow(e)) return(character(0))
  nodes <- create_nodes_df(isa)            # same node ids the diagram uses
  label <- gsub("\\s+", " ", nodes$label)  # labels are word-wrapped for display
  paste(label[match(e$from, nodes$id)], "->", label[match(e$to, nodes$id)])
}

for (tpl in c("template_overfishing", "template_pollution", "template_tourism", "template_climate")) {
  test_that(paste(tpl, ": every approved connection appears in the diagram"), {
    skip_if_not(exists("ai_isa_assistant_server", envir = .GlobalEnv, mode = "function"),
                "ai_isa_assistant_server not available")
    pd <- reactiveVal(list(project_id = "p", data = list(isa_data = list(), metadata = list())))
    want <- NULL
    testServer(ai_isa_assistant_server, args = list(project_data_reactive = pd, i18n = i18n), {
      session$flushReact()
      do.call(session$setInputs, setNames(list(1), tpl))
      rv$approved_connections <- seq_along(rv$suggested_connections)
      want <<- vapply(rv$suggested_connections, function(x) paste(x$from, "->", x$to), "")
      session$setInputs(save_to_isa = 1)
    })
    got <- cld_links(pd()$data$isa_data)
    expect_gt(length(want), 0)
    expect_setequal(got, want)
  })
}

test_that("a forward connection under a legacy matrix name lands in the forward matrix (non-square)", {
  elements <- list(drivers = list(list(name = "D1"), list(name = "D2"), list(name = "D3")),
                   activities = list(list(name = "A1"), list(name = "A2")))
  conns <- list(list(from = "D3", to = "A2", from_category = "drivers", to_category = "activities",
                     polarity = "+", strength = "medium", matrix = "a_d", from_index = 3, to_index = 2))
  m <- build_adjacency_matrices(elements, conns, 1L, 3)
  expect_equal(dim(m$d_a), c(3L, 2L))
  expect_equal(sum(!is.na(m$d_a) & m$d_a != ""), 1L)
  expect_true(nzchar(m$d_a[3, 2]))
  expect_null(m$a_d)
})
