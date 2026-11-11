# tests/testthat/test-ai-isa-suggestion-wording.R
# User feedback 2026-10-13 "Ai - assisted SES building problem with some
# wording" (workshop participant): activities framed as issues, a fishing vs
# shipping wording bias, outcomes suggested as activities, and terms repeated
# across categories. The code-level causes (no science decision needed) are
# guarded here; label wording in the knowledge base awaits expert review.

source_for_test("modules/ai_isa_knowledge_base.R")

categories <- c("drivers", "activities", "pressures", "states", "impacts", "welfare", "responses")
contexts <- list(
  c("baltic", "Coastal lagoon"), c("mediterranean", "Seagrass meadow"),
  c("north_sea", "Offshore waters"), c("caribbean", "Coral reef"), c("arctic", "Fjord")
)

suggest <- function(category, ctx, issue) {
  get_context_suggestions(category, regional_sea = ctx[1], ecosystem_type = ctx[2],
                          main_issue = issue)
}

test_that("the chosen focus topic does not change any suggestions (no fishing-only lists)", {
  for (cat in categories) for (ctx in contexts) {
    none <- suggest(cat, ctx, character(0))
    expect_identical(suggest(cat, ctx, c("Overfishing", "Illegal fishing")), none,
                     info = paste(cat, ctx[1], "fishing topics"))
    expect_identical(suggest(cat, ctx, "Shipping"), none, info = paste(cat, ctx[1], "Shipping"))
    expect_identical(suggest(cat, ctx, c("Eutrophication", "Tourism pressure", "Climate change")), none,
                     info = paste(cat, ctx[1], "other topics"))
  }
})

test_that("the removed topic-triggered labels never appear", {
  removed <- c("Livelihood loss", "Economic decline", "Fisher income loss",
               "Protein source loss", "Traditional livelihoods decline",
               "Plastic disposal", "Ship emissions", "Purse seining", "Stock depletion")
  for (cat in categories) for (ctx in contexts) {
    s <- suggest(cat, ctx, c("Overfishing", "Marine litter", "Climate change", "Tourism pressure"))
    expect_false(any(s %in% removed), info = paste(cat, ctx[1], paste(intersect(s, removed), collapse = ", ")))
  }
})

test_that("activities and sectors are not suggested as Drivers", {
  sectors <- c("Maritime transport", "Resource extraction", "Renewable energy",
               "Beach tourism", "Diving and snorkeling", "Heritage tourism",
               "Indigenous subsistence", "Resource exploration", "Shipping routes")
  for (ctx in contexts) {
    s <- suggest("drivers", ctx, character(0))
    expect_false(any(s %in% sectors), info = paste(ctx[1], paste(intersect(s, sectors), collapse = ", ")))
  }
})

test_that("'Marine debris disposal' (an outcome) is not suggested as an Activity", {
  for (sea in c("mediterranean", "caribbean")) {
    s <- get_context_suggestions("activities", sea, "Open coast", character(0))
    expect_false("Marine debris disposal" %in% s, info = sea)
  }
})

test_that("deduplication never drops a knowledge-base label for a generic one", {
  kb <- "Bottom trawling for demersal fish"
  expect_identical(deduplicate_suggestions(c("Trawling", kb), protected = kb), kb)
  expect_identical(deduplicate_suggestions(c(kb, "Trawling"), protected = kb), kb)
  # two curated labels are both kept
  kb2 <- c("Trawling for shrimp", "Trawling for demersal fish")
  expect_identical(deduplicate_suggestions(kb2, protected = kb2), kb2)
  # without protected labels the old rule stands (label with fewer words kept)
  expect_identical(deduplicate_suggestions(c("Trawl fishing", "Trawling")), "Trawling")
})
