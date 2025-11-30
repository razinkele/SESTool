# MarineSABRES SES Tests

Quick reference for running tests.

## Quick Start

```bash
# Run all tests (includes testthat suite with connection review tests)
Rscript run_all_tests.R

# Run specific test suite
Rscript test_loop_detection_comprehensive.R
Rscript test_network_analysis_functions.R

# Run testthat suite only
Rscript -e "testthat::test_dir('testthat')"

# Run connection review tests only
Rscript -e "testthat::test_file('testthat/test-connection-review.R')"
```

## Test Files

| File | Purpose | Test Count |
|------|---------|------------|
| `run_all_tests.R` | Master test runner | - |
| `test_loop_detection_comprehensive.R` | Loop detection & performance | 10+ |
| `test_network_analysis_functions.R` | All network analysis functions | 15+ |
| `testthat/test-connection-review.R` | Connection review bug fixes (v1.5.2) | 14 |
| `testthat/test-*.R` | Other testthat suites | 160+ |

## Expected Results

All tests should pass in <10 seconds total.

If tests fail:
1. Check error messages in output
2. Review recent code changes
3. See `../TESTING_FRAMEWORK.md` for troubleshooting

## Adding Tests

See `../TESTING_FRAMEWORK.md` for:
- Test templates
- Best practices
- Performance guidelines

## Critical Tests

### Loop Detection Hanging Prevention

The most important tests validate that loop detection **never hangs**:

- ✅ Large dense components are skipped
- ✅ DFS uses O(1) data structures
- ✅ Cycle limits are enforced
- ✅ Timeouts prevent infinite loops

These tests protect against the bugs documented in:
- `LOOP_ANALYSIS_HANG_FIX.md`
- `LOOP_ANALYSIS_HANG_FIX_V2.md`

### Connection Review Bug Fixes (v1.5.2)

Critical regression tests for connection review amendments:

- ✅ Bug #1: Amend saves both strength AND confidence
- ✅ Bug #2: on_approve callback works correctly
- ✅ Bug #3: Amendments persist to finalization
- ✅ Bug #4: Auto-navigation is disabled

These tests protect against the bugs documented in:
- `CONNECTION_REVIEW_BUGFIX_SUMMARY.md`
- `docs/CONNECTION_REVIEW_MODULE.md`
- `docs/CHANGELOG.md` (v1.5.2 section)

## More Information

Full documentation: `../TESTING_FRAMEWORK.md`
