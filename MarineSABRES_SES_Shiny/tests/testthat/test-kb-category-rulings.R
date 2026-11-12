# tests/testthat/test-kb-category-rulings.R
# Marine-science expert rulings 2026-11-11 on the category questions left open in
# PR #149 (see DAPSIWRM_FRAMEWORK_RULES.md, "Classification Rulings"):
#  1 climate change = Pressure          2 discharge act = Activity, substance = Pressure
#  3 hypoxia / algal blooms / coastal erosion = Pressure
#  4 policies = Responses, not Drivers  5 research and monitoring = Activities

source_for_test("modules/ai_isa_knowledge_base.R")
app_root_dir <- function() {
  d <- getwd()
  if (basename(d) == "testthat") dirname(dirname(d)) else d
}
# Load only the app's own transition validator (a trusted repo file) if the
# helpers have not already; eval() runs that one parsed function definition.
if (!exists("is_valid_dapsirwrm_transition")) local({
  exprs <- parse(file.path(app_root_dir(), "functions", "network_analysis.R"))
  for (e in exprs) {
    if (is.call(e) && identical(e[[1]], as.name("<-")) &&
        identical(as.character(e[[2]]), "is_valid_dapsirwrm_transition")) eval(e, globalenv())
  }
})

CATS <- c("drivers", "activities", "pressures", "states", "impacts", "welfare", "responses")
kb <- jsonlite::fromJSON(file.path(app_root_dir(), "data", "ses_knowledge_db.json"),
                         simplifyVector = FALSE)$contexts
names_in <- function(ctx, cat) vapply(kb[[ctx]][[cat]], function(e) e$name, character(1))
all_names <- function(cat) unlist(lapply(names(kb), function(ctx) names_in(ctx, cat)))

test_that("main KB places the ruled elements in the expert's categories", {
  # 1 climate change
  expect_false(any(grepl("^Climate change and (ocean warming|deep-ocean warming|shifting ocean currents)$",
                         all_names("drivers"))))
  expect_true("Climate change and ocean warming" %in% names_in("macaronesia_island", "pressures"))
  # 3 hypoxia and coastal erosion
  expect_false(any(grepl("hypoxi", all_names("states"), ignore.case = TRUE)))
  expect_true("Deep-water hypoxia (dead zones)" %in% names_in("baltic_offshore", "pressures"))
  expect_true("Coastal erosion and sediment deficit" %in% names_in("atlantic_open_coast", "pressures"))
  # 4 policies
  expect_false(any(grepl("Common Fisheries Policy|policy targets|deep-sea access regulation",
                         all_names("drivers"))))
  expect_true("Offshore wind energy policy targets (EU, UK)" %in% names_in("north_sea_offshore", "responses"))
  expect_false("EU deep-sea access regulations" %in% unlist(lapply(CATS, function(c) names_in("macaronesia_seamount", c))))
  # 5 research and monitoring
  expect_true("Shellfish sanitary monitoring programmes" %in% names_in("mediterranean_lagoon", "activities"))
  # 2 a pressure names the substance, not the act of discharging
  expect_false(any(grepl("\\bdischarge\\b", all_names("pressures"), ignore.case = TRUE)),
               info = paste(grep("discharge", all_names("pressures"), value = TRUE), collapse = "; "))
})

test_that("fuller answers 2026-11-12: a directive is a Response; removal, not monitoring, is the Measure", {
  expect_false("Water Framework Directive compliance pressure" %in% names_in("north_sea_estuary", "drivers"))
  expect_true("Water Framework Directive improvement measures" %in% names_in("north_sea_estuary", "responses"))
  expect_false(any(grepl("monitoring", names_in("macaronesia_island", "responses"), ignore.case = TRUE)))
  expect_true("Invasive species removal programmes" %in% names_in("macaronesia_island", "responses"))
})

test_that("links whose own rationale rejects the relationship are gone", {
  bad <- list(
    c("pacific_island_atoll", "Copra production and coconut palm cultivation", "Climate change and ocean warming"),
    c("indian_ocean_island", "Invasive mammalian predators (rats, cats, tenrecs) on native wildlife", "Climate change and ocean warming"),
    c("baltic_offshore", "Overfishing of Eastern Baltic cod", "Deep-water hypoxia (dead zones)"),
    c("baltic_island", "Grey seal haul-out colony sizes", "Coastal erosion of limestone and glacial till shores"),
    c("arctic_island", "Arctic Council AMAP contaminant monitoring programme", "Arctic shipping route access (Northern Sea Route)"),
    c("arctic_sea_ice", "Arctic oil and gas seismic exploration", "Accelerating sea ice extent and thickness loss"),
    c("arctic_fjord", "Arctic cruise tourism growth", "Kelp harvesting (Laminaria hyperborea)"),
    c("pacific_island_atoll", "Coral bleaching from ocean warming", "Ocean acidification reducing coral calcification"))
  for (b in bad) {
    cs <- kb[[b[1]]]$connections
    hit <- vapply(cs, function(e) identical(e$from, b[2]) && identical(e$to, b[3]), logical(1))
    expect_false(any(hit), info = paste(b, collapse = " | "))
    # removing it left neither element without links
    for (n in b[2:3]) {
      expect_true(any(vapply(cs, function(e) n %in% c(e$from, e$to), logical(1))), info = paste(b[1], n))
    }
  }
})

test_that("every KB connection still has valid endpoints and a valid DAPSIWRM transition", {
  # the validator is the real one (not a stub): it rejects transitions the moves could create
  expect_false(is_valid_dapsirwrm_transition("activities", "states"))
  expect_false(is_valid_dapsirwrm_transition("states", "pressures"))
  expect_true(is_valid_dapsirwrm_transition("pressures", "pressures"))
  for (ctx in names(kb)) {
    typed <- unlist(lapply(CATS, function(cat) setNames(rep(cat, length(names_in(ctx, cat))), names_in(ctx, cat))))
    for (e in kb[[ctx]]$connections) {
      lbl <- sprintf("%s: %s -> %s", ctx, e$from, e$to)
      expect_identical(unname(typed[e$from]), e$from_type, info = lbl)
      expect_identical(unname(typed[e$to]), e$to_type, info = lbl)
      expect_true(is_valid_dapsirwrm_transition(e$from_type, e$to_type), info = lbl)
    }
  }
})

test_that("the hardcoded habitat suggestions follow the rulings", {
  hs <- function(cat, sea, eco) get_habitat_specific_suggestions(cat, sea, eco)
  # 5 research/monitoring are activities, not drivers or responses
  expect_false(any(c("Scientific research", "Climate monitoring") %in% hs("drivers", "arctic", "Sea ice")))
  expect_true("Climate monitoring" %in% hs("activities", "arctic", "Sea ice"))
  expect_false("Scientific exploration" %in% hs("drivers", "arctic", "Offshore waters"))
  expect_true("Scientific exploration" %in% hs("activities", "arctic", "Offshore waters"))
  expect_false("Water quality monitoring" %in% hs("responses", "mediterranean", "Seagrass meadow"))
  expect_true("Water quality monitoring" %in% hs("activities", "mediterranean", "Seagrass meadow"))
  expect_false("Shellfish water quality monitoring" %in% hs("responses", "baltic", "Estuary"))
  expect_true("Shellfish water quality monitoring" %in% hs("activities", "baltic", "Estuary"))
  # 1 a climate-driven pressure is not offered as a driver
  expect_false("Coastal squeeze from sea level rise" %in% hs("drivers", "north_sea", "Tidal flat"))
  expect_true("Coastal squeeze from sea level rise" %in% hs("pressures", "north_sea", "Tidal flat"))
  # 2 estuary pressures name the substance
  for (sea in c("baltic", "mediterranean")) {
    expect_false(any(grepl("discharge", hs("pressures", sea, "Estuary"), ignore.case = TRUE)), info = sea)
  }
})

test_that("the generic fallback lists follow the rulings (hypoxia is a pressure, monitoring an activity)", {
  src <- paste(readLines(file.path(app_root_dir(), "modules", "ai_isa_knowledge_base.R"), warn = FALSE),
               collapse = "\n")
  expect_false(grepl('"Hypoxic zones expansion"', src, fixed = TRUE))   # was a Baltic state
  expect_false(grepl('"Monitoring programs"', src, fixed = TRUE))       # was a universal response
  expect_match(src, '"Environmental monitoring"', fixed = TRUE)         # now a universal activity
})
