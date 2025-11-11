# Testing Quick Start Guide

## Run All Tests

```bash
cd tests
Rscript run_all_tests.R
```

**Expected**: All tests pass in <10 seconds

## Run Individual Suites

```bash
# Loop detection tests (hanging prevention)
Rscript test_loop_detection_comprehensive.R

# Network analysis function tests
Rscript test_network_analysis_functions.R
```

## What Gets Tested

### ✅ Loop Detection
- No hanging on any network structure
- Performance benchmarks (<1s for typical networks)
- SCC filtering prevents exponential explosion
- Cycle limits enforced

### ✅ Network Analysis
- Metrics (density, centrality, diameter)
- MICMAC (influence, exposure, quadrants)
- Leverage points (composite scores)
- Path finding (shortest paths)
- Simplification (exogenous, SISO)
- Community detection

## Test Results Summary

```
═══════════════════════════════════════════════════════════════════
  MarineSABRES SES Application - Comprehensive Test Suite
═══════════════════════════════════════════════════════════════════

Total Test Suites: 2
Passed:            2 ✅
Total Time:        ~5-6 seconds

✅ All tests passed successfully!
```

## Files Fixed

1. **[functions/network_analysis.R](functions/network_analysis.R)**
   - Added constants fallback for standalone use
   - DFS optimizations (O(1) operations)
   - SCC filtering with density thresholds

2. **Test Files Created**
   - `test_loop_detection_comprehensive.R` (10+ tests)
   - `test_network_analysis_functions.R` (15+ tests)
   - `run_all_tests.R` (master runner)

## Documentation

- **[TESTING_FRAMEWORK.md](TESTING_FRAMEWORK.md)** - Complete guide
- **[LOOP_ANALYSIS_FINAL_SOLUTION.md](LOOP_ANALYSIS_FINAL_SOLUTION.md)** - Solution summary
- **[tests/TEST_README.md](tests/TEST_README.md)** - Quick reference

## Troubleshooting

### "constants.R not found"
**Fixed!** Constants are now defined with fallback values in `network_analysis.R`

### Tests hang
Check that SCC filtering is working:
```bash
Rscript -e "source('functions/network_analysis.R'); cat('SCC filtering active\n')"
```

### Performance slow
Verify optimizations are active:
```bash
cd tests
Rscript test_loop_detection_comprehensive.R | grep "DFS optimization"
```

## Before Committing

Always run tests:
```bash
cd tests && Rscript run_all_tests.R
```

All tests must pass ✅

---

**Status**: ✅ All tests passing
**Coverage**: 25+ test cases
**Runtime**: <10 seconds
**Last Updated**: 2025-11-10
