# Evidence lookup and shared sign picker (evidenced polarity, Task 1)

# local_mocked_bindings() needs a pkgload package, which this suite is not, so
# stub the global lookup by assignment and restore it when the test ends.
stub_kb <- function(value, env = parent.frame()) {
  had <- exists("lookup_knowledge_base", envir = globalenv(), inherits = FALSE)
  orig <- if (had) get("lookup_knowledge_base", envir = globalenv())
  assign("lookup_knowledge_base", function(...) value, envir = globalenv())
  withr::defer({
    if (had) assign("lookup_knowledge_base", orig, envir = globalenv())
    else rm("lookup_knowledge_base", envir = globalenv())
  }, envir = env)
}

test_that("exact KB match with a source is evidence", {
  stub_kb(list(polarity = "-", match_quality = "exact", source = "Smith 2020"))
  expect_equal(evidenced_polarity("Trawling", "Activities", "Seabed", "Pressures"),
               list(polarity = "-", source = "Smith 2020"))
})

test_that("synonym match, missing source and no match are not evidence", {
  for (kb in list(list(polarity = "+", match_quality = "synonym", source = "X"),
                  list(polarity = "+", match_quality = "exact", source = ""),
                  NULL)) {
    stub_kb(kb)
    res <- evidenced_polarity("a", "Drivers", "b", "Activities")
    expect_identical(res$polarity, NA_character_)
    expect_identical(res$source, NA_character_)
  }
})

test_that("read_polarity_pick maps every unset form to NA", {
  for (x in list(NULL, character(0), "", NA)) expect_identical(read_polarity_pick(x), NA_character_)
  expect_identical(read_polarity_pick("+"), "+")
  expect_identical(read_polarity_pick("-"), "-")
})

test_that("picker renders unset with prompt, and a from: line only with evidence", {
  # make_test_i18n() is identity, so assertions match the i18n keys
  i18n <- make_test_i18n()
  html <- as.character(polarity_picker_input("p", i18n))
  expect_match(html, "common.polarity.choose_sign", fixed = TRUE)
  expect_match(html, "common.choices.polarity_reinforcing", fixed = TRUE)
  expect_match(html, "common.choices.polarity_opposing", fixed = TRUE)
  expect_false(grepl("common.polarity.from_source", html, fixed = TRUE))
  expect_false(grepl("active", html, fixed = TRUE))   # nothing selected
  html2 <- as.character(polarity_picker_input("p", i18n, selected = "-", evidence_source = "Smith 2020"))
  expect_match(html2, "Smith 2020", fixed = TRUE)
  expect_match(html2, "common.polarity.from_source", fixed = TRUE)
  expect_false(grepl("common.polarity.choose_sign", html2, fixed = TRUE))
})
