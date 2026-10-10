# CI workflows live at the repository root

GitHub Actions only reads workflows from `<repo-root>/.github/workflows/`
(one level above this app directory): `test.yml` (per-file testthat suite,
incl. E2E) and `i18n-validation.yml`.

Copies that used to sit here were never executed and had drifted (outdated
action versions, a coverage threshold and gating the live workflows do not
have), so they were removed (review 2026-10-07 N78). Edit the root files.
