# shiny::showNotification() accepts only these types; any other value makes
# match.arg() throw, which ends the session when it happens in an observer
# (browser recheck after bd0b0bb: "Restore Original Network" disconnected).

test_that("every showNotification call uses a type shiny accepts", {
  root <- if (basename(getwd()) == "testthat") dirname(dirname(getwd())) else getwd()
  files <- list.files(file.path(root, c("modules", "functions", "server")),
                      pattern = "[.]R$", full.names = TRUE, recursive = TRUE)
  files <- c(files, file.path(root, c("app.R", "global.R")))
  files <- files[file.exists(files)]
  bad <- character(0)
  for (f in files) {
    src <- paste(readLines(f, warn = FALSE), collapse = "\n")
    calls <- regmatches(src, gregexpr(r"(showNotification\((?:[^()]|\([^()]*\))*\))", src, perl = TRUE))[[1]]
    for (cl in calls) {
      m <- regmatches(cl, regexpr(r"(type\s*=\s*"[^"]+")", cl, perl = TRUE))
      if (length(m)) {
        ty <- sub(r"{.*"([^"]+)"}", r"{\1}", m, perl = TRUE)
        if (!ty %in% c("default", "message", "warning", "error"))
          bad <- c(bad, sprintf("%s: type = \"%s\"", basename(f), ty))
      }
    }
  }
  expect_equal(bad, character(0))
})
