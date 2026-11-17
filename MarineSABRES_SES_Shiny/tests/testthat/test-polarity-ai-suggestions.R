# AI suggestions and ML results carry only evidenced signs (evidenced polarity, Task 3)
# stub_kb() lives in helper-kb-stub.R.

source_for_test("modules/ai_isa/connection_generator.R")
source_for_test("functions/ml_inference.R")

two <- function() list(
  from = list(list(name = "Trawling")),
  to   = list(list(name = "Seabed damage"))
)
suggest_one <- function() {
  e <- two()
  generate_smart_connections(e$from, e$to, "activities", "pressures", "a_p",
                             max_count = 5, min_relevance = 0)[[1]]
}

test_that("detect_polarity returns NA without exact KB evidence", {
  stub_kb(NULL)
  expect_identical(detect_polarity("Pollution reduction", "Water quality", "responses", "pressures"),
                   NA_character_)
  expect_identical(detect_polarity("Fishing", "Fish stocks", "activities", "states"), NA_character_)
})

test_that("detect_polarity returns the sourced exact KB sign", {
  stub_kb(list(polarity = "-", match_quality = "exact", source = "Smith 2020"))
  expect_identical(detect_polarity("a", "b", "activities", "pressures"), "-")
})

test_that("generated suggestion keeps KB sign and source on exact match", {
  stub_kb(list(polarity = "-", match_quality = "exact", source = "Smith 2020", strength = "strong"))
  s <- suggest_one()
  expect_equal(s$polarity, "-")
  expect_equal(s$polarity_source, "Smith 2020")
  expect_equal(s$confidence, 4)
})

test_that("synonym match scores but leaves the sign unset", {
  stub_kb(list(polarity = "+", match_quality = "synonym", source = "X", strength = "medium"))
  s <- suggest_one()
  expect_identical(s$polarity, NA_character_)
  expect_identical(s$polarity_source, NA_character_)
  expect_equal(s$confidence, 3)
  expect_match(s$rationale, "affects", fixed = TRUE)
})

test_that("no KB match gives an unset sign with a neutral rationale", {
  stub_kb(NULL)
  s <- suggest_one()
  expect_identical(s$polarity, NA_character_)
  expect_identical(s$polarity_source, NA_character_)
  expect_identical(s$rationale, "Trawling affects Seabed damage")
})

fake_tensor <- function(x) list(item = function() x)
fake_predictions <- function(pol_logit) list(
  existence  = fake_tensor(2),
  strength   = c(0.1, 0.2, 0.7),
  confidence = fake_tensor(3.2),
  polarity   = fake_tensor(pol_logit)
)

test_that("ML result has no polarity, only predicted_polarity", {
  r <- .process_predictions(fake_predictions(log(0.9 / 0.1)), "a", "activities", "b", "pressures",
                            threshold = 0.5, return_uncertainty = FALSE)
  expect_identical(r$polarity, NA_character_)
  expect_equal(r$predicted_polarity, "+")
  r2 <- .process_predictions(fake_predictions(log(0.1 / 0.9)), "a", "activities", "b", "pressures",
                             threshold = 0.5, return_uncertainty = FALSE)
  expect_identical(r2$polarity, NA_character_)
  expect_equal(r2$predicted_polarity, "-")
})

test_that("blend_predictions never emits a sign", {
  ml <- list(existence_probability = 0.9, strength = "medium", confidence = 4,
             polarity = NA_character_, predicted_polarity = "-")
  rule <- list(confidence = 0.6, strength = "weak", polarity = "+")
  for (p in c(0.9, 0.0)) {
    ml$existence_probability <- p
    r <- blend_predictions(ml, rule)
    expect_identical(r$polarity, NA_character_)
  }
})

test_that("ghost edge colouring handles an unset sign", {
  mk <- function(pol) list(connection_polarity = pol, connection_strength = "medium",
                           connection_confidence = 3, from_node = "a")
  unset <- create_ghost_edge_data(mk(NA_character_), 1)
  expect_true(is.na(unset$polarity))
  expect_false(unset$color %in% c(adjustcolor(EDGE_COLORS$reinforcing, alpha.f = GHOST_EDGE_OPACITY),
                                  adjustcolor(EDGE_COLORS$opposing, alpha.f = GHOST_EDGE_OPACITY)))
  expect_match(unset$title, "unset", fixed = TRUE)
  expect_equal(create_ghost_edge_data(mk("-"), 1)$color,
               adjustcolor(EDGE_COLORS$opposing, alpha.f = GHOST_EDGE_OPACITY))
})

# ---- KB seeding branch of generate_connections() ---------------------------
stub_global <- function(name, value, env = parent.frame()) {
  had <- exists(name, envir = globalenv(), inherits = FALSE)
  orig <- if (had) get(name, envir = globalenv())
  assign(name, value, envir = globalenv())
  withr::defer({
    if (had) assign(name, orig, envir = globalenv())
    else rm(list = name, envir = globalenv())
  }, envir = env)
}

test_that("KB seeding signs only exact, referenced matches", {
  kbc <- function(from, to, refs) list(from = from, from_type = "drivers", to = to,
                                       to_type = "activities", polarity = "-",
                                       strength = "strong", confidence = 5,
                                       rationale = "r", references = refs)
  stub_kb(NULL)
  stub_global("ses_knowledge_db_available", function() TRUE)
  stub_global("get_context_connections", function(regional_sea, habitat) list(
    kbc("Farm demand", "Drainage", list("HELCOM 2018", "Halpern 2008")),   # exact + sourced
    kbc("Tourism", "Beach visits", list("HELCOM 2018")),                   # partial name
    kbc("Fish demand", "Landings", list())                                 # no references
  ))
  els <- list(
    drivers = list(list(name = "Farm demand"), list(name = "Tourism growth"), list(name = "Fish demand")),
    activities = list(list(name = "Drainage"), list(name = "Beach visits"), list(name = "Landings"))
  )
  res <- generate_connections(els, "baltic", "Coastal lagoon")
  seeded <- Filter(function(c) identical(c$scoring_method, "knowledge_db"), res)
  by_from <- setNames(seeded, vapply(seeded, function(c) c$from_name, ""))
  expect_setequal(names(by_from), c("Farm demand", "Tourism growth", "Fish demand"))
  expect_identical(by_from[["Farm demand"]]$polarity, "-")
  expect_identical(by_from[["Farm demand"]]$polarity_source, "HELCOM 2018; Halpern 2008")
  expect_identical(by_from[["Tourism growth"]]$polarity, NA_character_)
  expect_identical(by_from[["Tourism growth"]]$polarity_source, NA_character_)
  expect_identical(by_from[["Fish demand"]]$polarity, NA_character_)
  expect_identical(by_from[["Fish demand"]]$polarity_source, NA_character_)
})

test_that("neutral rationale verb and unset tooltip use the translator when given", {
  stub_kb(NULL)
  tr <- list(t = function(key, ...) paste0("T:", key))
  e <- two()
  s <- generate_smart_connections(e$from, e$to, "activities", "pressures", "a_p",
                                  max_count = 5, min_relevance = 0, i18n = tr)[[1]]
  expect_identical(s$rationale, "Trawling T:common.polarity.affects Seabed damage")
  sg <- list(connection_polarity = NA_character_, connection_strength = "medium",
             connection_confidence = 3, from_node = "a", name = "n", type = "Pressures",
             reasoning = "r")
  expect_match(create_ghost_edge_data(sg, 1, i18n = tr)$title, "T:common.polarity.unset", fixed = TRUE)
  # helper-stubs.R replaces create_ghost_node_data globally; load the real one privately
  real <- new.env(parent = globalenv())
  td <- getwd(); root <- if (basename(td) == "testthat") dirname(dirname(td)) else td
  sys.source(file.path(root, "functions", "visnetwork_helpers.R"), envir = real)
  expect_match(real$create_ghost_node_data(sg, 1, i18n = tr)$title, "T:common.polarity.unset", fixed = TRUE)
})
