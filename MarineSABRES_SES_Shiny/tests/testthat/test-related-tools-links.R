# tests/testthat/test-related-tools-links.R
# Issue #162: the Dashboard links to the two companion tools of the Marine
# SABRES DSS (D6.1 sitemap; D6.2 Section 5.5), each with a help text:
#  - Demonstration Area Viewer (spatial tool, D6.1 R37-R41)
#  - LifeWatch ERIC HG&OG tool (horrendograms & organigrams, D6.1 R32-R36)

app_root <- function() {
  d <- getwd()
  if (basename(d) == "testthat") dirname(dirname(d)) else d
}
LANGS <- c("en", "es", "fr", "de", "lt", "pt", "it", "no", "el")
read_src <- function(rel) paste(readLines(file.path(app_root(), rel), warn = FALSE),
                                collapse = "\n")

test_that("the companion tool addresses are defined once, as https URLs", {
  const <- read_src("constants.R")
  expect_match(const, "DSS_COMPANION_TOOLS <- list(", fixed = TRUE)
  expect_match(const, 'url = "https://laguna.ku.lt/DA/"', fixed = TRUE)
  expect_match(const, 'url = "https://marinesabres.lifewatch.eu/marine-sabres-graph/"',
               fixed = TRUE)
  if (exists("DSS_COMPANION_TOOLS")) {
    expect_setequal(names(DSS_COMPANION_TOOLS), c("da_viewer", "governance"))
    for (tool in DSS_COMPANION_TOOLS) expect_match(tool$url, "^https://[^ ]+/$")
  }
  # app.R takes the addresses from the constant, not from literals.
  app <- read_src("app.R")
  expect_false(grepl("laguna.ku.lt/DA", app, fixed = TRUE))
  expect_false(grepl("lifewatch.eu", app, fixed = TRUE))
})

test_that("the Dashboard has a related-tools card with both links and their help", {
  app <- read_src("app.R")
  expect_match(app, 'id = "related_tools_card"', fixed = TRUE)
  for (tool in c("da_viewer", "governance")) {
    expect_match(app, sprintf("DSS_COMPANION_TOOLS$%s$url", tool), fixed = TRUE)
    for (part in c("name", "desc", "help")) {
      expect_match(app, sprintf('i18n$t("ui.dashboard.related_tool_%s_%s")', tool, part),
                   fixed = TRUE)
    }
  }
  # External links open in a new tab and do not hand over the opener.
  expect_match(app, 'target = "_blank", rel = "noopener noreferrer"', fixed = TRUE)
})

test_that("every related-tools text exists in all 9 languages", {
  tr <- jsonlite::fromJSON(file.path(app_root(), "translations", "ui", "dashboard.json"),
                           simplifyVector = FALSE)$translation
  keys <- c("related_tools_title", "related_tools_intro", "related_tools_open",
            "related_tools_help_label",
            "related_tool_da_viewer_name", "related_tool_da_viewer_desc",
            "related_tool_da_viewer_help",
            "related_tool_governance_name", "related_tool_governance_desc",
            "related_tool_governance_help", "related_tool_governance_help_2",
            "related_tool_governance_help_3", "related_tool_governance_help_4")
  for (k in keys) {
    entry <- tr[[paste0("ui.dashboard.", k)]]
    expect_false(is.null(entry), info = k)
    for (l in LANGS) {
      expect_true(is.character(entry[[l]]) && nzchar(trimws(entry[[l]])), info = paste(k, l))
    }
  }
  # The help texts carry the two caveats users need.
  expect_match(tr[["ui.dashboard.related_tool_da_viewer_help"]]$en, "EMODnet", fixed = TRUE)
  expect_match(tr[["ui.dashboard.related_tool_governance_desc"]]$en, "LifeWatch ERIC",
               fixed = TRUE)
  # The governance tool carries LifeWatch's own name, so users recognise it there.
  for (l in LANGS) {
    expect_match(tr[["ui.dashboard.related_tool_governance_name"]][[l]], "HG&OG",
                 fixed = TRUE, info = l)
  }
  # Every help paragraph is shown in the card.
  app <- read_src("app.R")
  for (n in 2:4) {
    expect_match(app, sprintf('i18n$t("ui.dashboard.related_tool_governance_help_%d")', n),
                 fixed = TRUE)
  }
})

test_that("the companion tools are linked where users need them", {
  # DA Viewer: project setup (next to the case-study selector) and Getting Started.
  # HG&OG tool: the D5.4 governance context and the AI assistant's country step.
  places <- list(
    "modules/pims_module.R"                    = "da_viewer",
    "modules/entry_point_module.R"             = "da_viewer",
    "modules/wp5_governance_context_module.R"  = "governance",
    "modules/ai_isa_assistant_module.R"        = "governance"
  )
  for (f in names(places)) {
    expect_match(read_src(f), sprintf('companion_tool_hint("%s", i18n)', places[[f]]),
                 fixed = TRUE, info = f)
  }
  # The About box lists both tools from the same constant.
  modals <- read_src("server/modals.R")
  expect_match(modals, 'id = "about_related_tools"', fixed = TRUE)
  expect_match(modals, "DSS_COMPANION_TOOLS[[tool]]", fixed = TRUE)
  expect_false(grepl("lifewatch.eu", modals, fixed = TRUE))
  expect_false(grepl("laguna.ku.lt/DA", modals, fixed = TRUE))
})

test_that("companion_tool_hint renders a translated hint and a safe new-tab link", {
  if (!exists("companion_tool_hint", mode = "function")) {
    source(file.path(app_root(), "functions", "ui_components.R"), local = TRUE)
  }
  i18n_stub <- list(t = function(k) paste0("<", k, ">"))
  for (tool in c("da_viewer", "governance")) {
    html <- as.character(companion_tool_hint(tool, i18n_stub))
    expect_match(html, sprintf("ui.dashboard.related_tool_%s_hint", tool), fixed = TRUE)
    expect_match(html, sprintf('href="%s"', DSS_COMPANION_TOOLS[[tool]]$url), fixed = TRUE)
    expect_match(html, 'target="_blank"', fixed = TRUE)
    expect_match(html, 'rel="noopener noreferrer"', fixed = TRUE)
  }
  expect_null(companion_tool_hint("no_such_tool", i18n_stub))

  tr <- jsonlite::fromJSON(file.path(app_root(), "translations", "ui", "dashboard.json"),
                           simplifyVector = FALSE)$translation
  for (tool in c("da_viewer", "governance")) {
    entry <- tr[[sprintf("ui.dashboard.related_tool_%s_hint", tool)]]
    for (l in LANGS) {
      expect_true(is.character(entry[[l]]) && nzchar(trimws(entry[[l]])), info = paste(tool, l))
    }
  }
})
