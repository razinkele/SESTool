# tests/testthat/helper-01-i18n-stub.R
# Minimal i18n object for testServer/unit tests: t() is identity so assertions
# can match the literal key. Mirrors the i18n$t() surface the modules use.
if (!exists("make_test_i18n")) {
  make_test_i18n <- function() {
    structure(list(t = function(key, ...) key, translator = NULL),
              class = "i18n_stub")
  }
}
