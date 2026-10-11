# tests/testthat/test-template-signs.R
# Template link signs corrected 2026-10-11 after a polarity review of all 305
# template links (user approved the five high-confidence fixes). Same-direction
# convention: "+" = more source, more target; "-" = more source, less target.
tpl <- function(name) {
  for (root in c(file.path(getwd(), "../.."), getwd())) {
    p <- file.path(root, "data", paste0(name, "_SES_Template.json"))
    if (file.exists(p)) return(jsonlite::fromJSON(p, simplifyVector = FALSE))
  }
  stop("template not found: ", name)
}
sign_of <- function(d, from, to) {
  hit <- Filter(function(x) x$from_id == from && x$to_id == to, d$connections)
  if (length(hit) != 1) stop(sprintf("expected one link %s -> %s, found %d", from, to, length(hit)))
  hit[[1]]$polarity
}

test_that("corrected pressure -> state signs", {
  expect_identical(sign_of(tpl("OffshoreWind"), "P002", "MPF001"), "-")   # pile-driving noise -> sandeel
  expect_identical(sign_of(tpl("ClimateChange"), "P003", "MPF002"), "-")  # oil spill risk -> seals
  expect_identical(sign_of(tpl("Pollution"), "P002", "MPF002"), "-")      # heavy metals -> dissolved O2
  expect_identical(sign_of(tpl("Pollution"), "P006", "MPF002"), "-")      # dredging -> dissolved O2
})

test_that("Baltic cod and herring recruitment move together (via sprat)", {
  # cod collapse -> more sprat -> sprat outcompete herring larvae -> less herring
  expect_identical(sign_of(tpl("Fisheries"), "MPF001", "MPF002"), "+")
})

test_that("the corrected links no longer carry placeholder 'connects to' descriptions", {
  for (x in list(c("OffshoreWind", "P002", "MPF001"), c("ClimateChange", "P003", "MPF002"),
                 c("Pollution", "P002", "MPF002"), c("Pollution", "P006", "MPF002"))) {
    d <- tpl(x[1])
    link <- Filter(function(l) l$from_id == x[2] && l$to_id == x[3], d$connections)[[1]]
    expect_false(grepl(" connects to ", link$description, fixed = TRUE), info = paste(x, collapse = " "))
  }
})
