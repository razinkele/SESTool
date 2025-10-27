# testthat.R
# Main test runner for MarineSABRES SES Shiny Application
# Run all tests with: testthat::test_dir("tests/testthat")

library(testthat)
library(shiny)

# Source global environment before running tests
source("../../global.R", local = TRUE)

# Run all tests
test_check("MarineSABRES")
