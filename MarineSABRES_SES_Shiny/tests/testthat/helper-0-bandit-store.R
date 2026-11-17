# tests/testthat/helper-0-bandit-store.R
# Loaded before helper-00-load-functions.R, so BANDIT_CONFIG (and every
# re-source of functions/ml_response_bandit.R) picks this up. Adding a response
# measure saves the bandit state; under testthat the default relative path
# resolved to tests/testthat/data/ and left a stray file in the repo.
options(marinesabres.bandit_store_path = file.path(tempdir(), "ml_response_bandit_state.rds"))
