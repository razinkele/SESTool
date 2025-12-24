# CI/CD Monitoring Guide - GitHub Actions Workflow

**Purpose**: Step-by-step guide to trigger, monitor, and interpret GitHub Actions test workflow
**Audience**: Developers, QA, Project managers
**Last Updated**: 2024-12-24

---

## 🚀 Quick Start - Triggering the Workflow

### Method 1: Push to Main Branch (Recommended)

```bash
# 1. Check status
git status

# 2. Stage all changes
git add .

# 3. Commit with descriptive message
git commit -m "Add E2E tests and coverage tracking infrastructure

- Implement 5 comprehensive E2E tests using shinytest2
- Add coverage baseline and tracking system
- Enhance CI/CD with automated coverage reporting
- Set 70% minimum coverage threshold
- Create comprehensive testing documentation"

# 4. Push to trigger CI/CD
git push origin main
```

### Method 2: Create Pull Request

```bash
# 1. Create feature branch
git checkout -b testing-improvements

# 2. Stage and commit
git add .
git commit -m "Add E2E tests and coverage tracking"

# 3. Push branch
git push origin testing-improvements

# 4. Go to GitHub and create PR
# CI/CD will run automatically on the PR
```

### Method 3: Manual Trigger (if configured)

1. Go to GitHub repository
2. Click "Actions" tab
3. Select "R Tests" workflow
4. Click "Run workflow" button
5. Choose branch and click "Run workflow"

---

## 📊 Monitoring Workflow Execution

### Step 1: Navigate to GitHub Actions

1. Open your repository on GitHub
2. Click the **"Actions"** tab at the top
3. You'll see a list of workflow runs

### Step 2: Find Your Workflow Run

**Latest Run** will be at the top:
- ⚙️ Yellow circle = Running
- ✅ Green checkmark = Passed
- ❌ Red X = Failed
- ⏸️ Gray circle = Pending

**Click on the workflow run** to see details.

### Step 3: View Job Matrix

You'll see a matrix of jobs:

```
Test (ubuntu-latest, 4.2)    ⚙️ Running... or ✅ Complete
Test (ubuntu-latest, 4.3)    ⚙️ Running... or ✅ Complete
Test (ubuntu-latest, 4.4)    ⚙️ Running... or ✅ Complete
Test (windows-latest, 4.2)   ⚙️ Running... or ✅ Complete
Test (windows-latest, 4.3)   ⚙️ Running... or ✅ Complete
Test (windows-latest, 4.4)   ⚙️ Running... or ✅ Complete
Test (macos-latest, 4.2)     ⚙️ Running... or ✅ Complete
Test (macos-latest, 4.3)     ⚙️ Running... or ✅ Complete
Test (macos-latest, 4.4)     ⚙️ Running... or ✅ Complete
```

**Click on any job** to see detailed steps.

---

## 🔍 Step-by-Step Execution Guide

### Phase 1: Setup (Steps 1-6)

**Expected Duration**: 2-3 minutes

| Step | Name | What to Watch For |
|------|------|-------------------|
| 1 | Checkout repository | ✅ Code downloaded |
| 2 | Setup R | ✅ R version installed |
| 3 | Setup Pandoc | ✅ Pandoc installed |
| 4 | Query dependencies | ✅ Dependencies listed |
| 5 | Cache R packages | ✅ Cache restored or created |
| 6 | Install system deps | ✅ System libraries installed (Linux only) |

**What Success Looks Like**:
- All steps show green checkmarks
- No error messages in logs
- Dependencies cached for faster runs

### Phase 2: Installation (Step 7)

**Expected Duration**: 5-7 minutes (first run), 1-2 min (cached)

| Step | Name | What to Watch For |
|------|------|-------------------|
| 7 | Install R dependencies | ✅ All packages installed successfully |

**Packages Being Installed**:
- testthat, shiny, shinydashboard, shinyWidgets, shinyjs, shinyBS, shinytest2
- tidyverse, DT, openxlsx, jsonlite
- igraph, visNetwork, ggraph, tidygraph
- ggplot2, plotly, dygraphs, xts
- timevis, rmarkdown, htmlwidgets, shiny.i18n
- covr, R6

**What Success Looks Like**:
```
* DONE (testthat)
* DONE (shiny)
* DONE (shinytest2)
...all packages...
* DONE (covr)
```

### Phase 3: Test Fixtures (Steps 8-11)

**Expected Duration**: 1 minute

| Step | Name | What to Watch For |
|------|------|-------------------|
| 8 | Session info | ✅ Package versions listed |
| 9 | Prepare test fixtures | ✅ Fixtures copied to data/ |
| 10 | Report fixture count | ✅ "Fixtures present in data/: 7" |
| 11 | Persist fixture list | ✅ Fixture list created |

**What Success Looks Like**:
```
Copied 7 fixture(s) into data/
Fixtures present in data/: 7
Files: aquaculture.json, caribbean.json, climatechange.json, ...
```

### Phase 4: Unit & Integration Tests (Step 12)

**Expected Duration**: 2-4 minutes

| Step | Name | What to Watch For |
|------|------|-------------------|
| 12 | Run tests | ✅ All tests pass |

**What Success Looks Like**:
```
Loading MarineSABRES SES Toolbox
═══ Testing MarineSABRES SES Toolbox ═══
✓ | 102 | global-utils
✓ |  48 | data-structure
✓ |  67 | network-analysis
...
✓ | 348+ | Total tests passed
```

**What Failure Looks Like**:
```
✗ | 1 | Some test failed
Error: Test failures
```

### Phase 5: E2E Browser Tests (Steps 13-16) **R 4.3 ONLY**

**Expected Duration**: 5-6 minutes

| Step | Name | Platform | Duration |
|------|------|----------|----------|
| 13 | Setup Chrome (Linux) | Linux | ~30s |
| 14 | Setup Chrome (macOS) | macOS | ~30s |
| 15 | Setup Chrome (Windows) | Windows | ~30s |
| 16 | Run shinytest2 E2E tests | All | ~5min |

**What Success Looks Like**:
```
✓ | 1 | E2E: App launches successfully
✓ | 1 | E2E: Language switching updates UI
✓ | 1 | E2E: Create SES method selection works
✓ | 1 | E2E: CLD visualization renders
✓ | 1 | E2E: Navigation across all major sections
✓ | 5 | Total E2E tests passed
```

**What Failure Looks Like**:
```
✗ | 1 | E2E: App launches successfully
Error: App failed to start within timeout
Screenshot saved to: screenshots/app-launch-test.png
```

**If E2E Tests Fail**:
1. Download "e2e-screenshots" artifact
2. View screenshots to see what happened
3. Check logs for timeout/error messages

### Phase 6: Coverage Generation (Steps 17-21) **Linux + R 4.3 ONLY**

**Expected Duration**: 3-5 minutes

| Step | Name | What to Watch For |
|------|------|-------------------|
| 17 | Test coverage | ✅ Coverage percentage calculated |
| 18 | Generate coverage summary | ✅ Summary created |
| 19 | Add coverage to step summary | ✅ Appears in GitHub UI |
| 20 | Upload coverage report | ✅ Artifacts uploaded |

#### Step 17: Test Coverage

**What to Watch For**:
```
Generating test coverage...
Overall Coverage: 75.23%

Coverage for global.R: 87.3%
Coverage for data_structure.R: 73.1%
...

✓ Coverage meets minimum threshold (70%)
```

**Success Indicators**:
- ✅ Coverage percentage shown
- ✅ "Coverage meets minimum threshold"
- ✅ No threshold violation error

**Failure Indicators**:
```
ERROR: Coverage 65.2% is below threshold of 70%
```
This will **fail the build** - intentional!

#### Step 18: Generate Coverage Summary

**What to Watch For**:
```
Creating markdown summary...
Top 10 files by coverage calculated
Threshold status: ✅ PASS
```

#### Step 19: Add Coverage to Step Summary

**This is the GitHub UI display**

Look for coverage summary at the top of the job:

```
## Test Coverage Report

**Overall Coverage**: 75.23%

![Coverage](https://img.shields.io/badge/coverage-75.2%25-yellow)

### Coverage by File (Top 10)

| File | Coverage |
|------|----------|
| global.R | 87.3% |
| data_structure.R | 73.1% |
...

### Coverage Threshold

- **Required**: 70%
- **Actual**: 75.23%
- **Status**: ✅ PASS
```

#### Step 20: Upload Coverage Report

**Artifacts uploaded**:
- coverage-report.html
- coverage-details.csv
- coverage-summary.md
- coverage.rds

**How to Access**:
1. Scroll to bottom of workflow run page
2. Find "Artifacts" section
3. Click "coverage-report" to download

---

## 📈 Interpreting Results

### All Tests Passed ✅

**What This Means**:
- ✅ Code works on all platforms (Linux, macOS, Windows)
- ✅ Code works on all R versions (4.2, 4.3, 4.4)
- ✅ E2E tests confirm UI workflows work
- ✅ Coverage meets minimum threshold (70%)

**Next Steps**:
1. Download coverage report artifact
2. Review coverage details
3. Identify areas for improvement
4. Merge PR or continue development

### Some Tests Failed ❌

**Common Failure Scenarios**:

#### Scenario 1: Platform-Specific Failure

```
✅ ubuntu-latest, R 4.3: Passed
✅ windows-latest, R 4.3: Passed
❌ macos-latest, R 4.3: Failed
```

**What to Do**:
1. Click on failed job
2. Review error message
3. Likely a path or package issue
4. Fix platform-specific code
5. Re-run

#### Scenario 2: E2E Timeout

```
✗ | 1 | E2E: App launches successfully
Error: Timed out waiting for app to start
```

**What to Do**:
1. Download e2e-screenshots artifact
2. View screenshot (may show error)
3. Increase timeout if app is slow
4. Fix app startup issue

#### Scenario 3: Coverage Below Threshold

```
ERROR: Coverage 65.2% is below threshold of 70%
Process completed with exit code 1.
```

**This is INTENTIONAL** - build should fail!

**What to Do**:
1. Download coverage report
2. Identify files with low coverage
3. Write more tests
4. Push again
5. Repeat until ≥70%

**DO NOT**: Lower the 70% threshold

---

## 📥 Downloading and Using Artifacts

### Step 1: Locate Artifacts

After workflow completes:
1. Scroll to bottom of workflow run page
2. Find **"Artifacts"** section
3. You'll see:
   - coverage-report
   - e2e-screenshots-ubuntu (if E2E failed)
   - e2e-screenshots-windows (if E2E failed)
   - e2e-screenshots-macos (if E2E failed)
   - test-results-* (if tests failed)

### Step 2: Download Artifacts

1. Click on artifact name (e.g., "coverage-report")
2. ZIP file downloads automatically
3. Unzip on your computer

### Step 3: Use Coverage Report

**coverage-report.html**:
1. Open in web browser
2. Click any file to see line-by-line coverage
3. Red lines = not covered by tests
4. Green lines = covered by tests
5. Identify gaps and write tests

**coverage-details.csv**:
1. Open in Excel or Google Sheets
2. Sort by coverage value (lowest first)
3. Filter to files with <70% coverage
4. Prioritize improvement efforts

**coverage-summary.md**:
1. Copy content
2. Add to project documentation
3. Track over time

### Step 4: Use E2E Screenshots (if tests failed)

1. Unzip e2e-screenshots artifact
2. Open PNG files in image viewer
3. See exactly what the browser saw when test failed
4. Debug based on visual state

---

## ⏱️ Expected Timeline

### Full Workflow Duration

**Total Time**: ~18-26 minutes

| Phase | Duration | Notes |
|-------|----------|-------|
| Setup | 2-3 min | Faster with cache |
| Installation | 5-7 min | Much faster if cached |
| Fixtures | 1 min | Always quick |
| Unit/Integration Tests | 2-4 min | Depends on test count |
| E2E Tests | 5-6 min | Only R 4.3 |
| Coverage | 3-5 min | Only Linux + R 4.3 |
| Upload | 1 min | Depends on artifact size |

**Matrix of 9 Jobs**:
- 3 platforms × 3 R versions = 9 jobs
- Run in parallel
- Total time ≈ longest job

### Why So Long?

- **Platform diversity**: Testing on 3 different OS
- **R version compatibility**: Testing 3 R versions
- **E2E tests**: Browser automation is slower
- **Coverage analysis**: Analyzing all code paths

### How to Speed Up

✅ **Already optimized**:
- Caching R packages (saves 5-7 min)
- Only E2E on R 4.3 (saves ~10 min on other versions)
- Only coverage on Linux + R 4.3 (saves ~8 min on others)

⚠️ **Don't do** (will reduce quality):
- Skip platforms
- Skip R versions
- Skip E2E tests
- Skip coverage

---

## 🚨 Common Issues and Solutions

### Issue 1: Workflow Doesn't Start

**Symptom**: No workflow run appears after push

**Causes**:
- Pushed to wrong branch
- Workflow file has syntax error
- GitHub Actions disabled

**Solutions**:
```bash
# Check current branch
git branch

# Ensure on main or develop
git checkout main
git push origin main

# Verify workflow file exists
ls .github/workflows/test.yml
```

### Issue 2: All Jobs Fail Immediately

**Symptom**: Every job shows red X within seconds

**Cause**: Workflow configuration error

**Solution**:
1. Click any job
2. Look at first step error
3. Likely YAML syntax error
4. Validate with: https://www.yamllint.com/

### Issue 3: "No Fixture JSON Files Found"

**Symptom**: Prepare test fixtures step fails

**Cause**: Fixtures not committed to repository

**Solution**:
```bash
# Ensure fixtures exist
ls tests/fixtures/templates/*.json

# Add to git if missing
git add tests/fixtures/templates/
git commit -m "Add test fixtures"
git push
```

### Issue 4: E2E Tests Timeout

**Symptom**: E2E tests fail with timeout error

**Causes**:
- App takes too long to start
- Chrome not installed properly
- Slow CI/CD runner

**Solutions**:
1. Check E2E logs for specific error
2. Increase timeout in test-app-e2e.R:
   ```r
   E2E_TIMEOUT <- 20000  # Increase from 10000
   ```
3. Simplify app startup
4. Re-run workflow (sometimes runner is just slow)

### Issue 5: Coverage Below Threshold

**Symptom**: Build fails at coverage step

**This is WORKING AS DESIGNED**

**Solution**:
1. Download coverage report
2. Write more tests
3. Push again
4. Repeat until ≥70%

---

## 📊 Success Criteria Checklist

### Before Merging PR

Use this checklist:

- [ ] All 9 jobs passed (3 OS × 3 R versions)
- [ ] Unit tests: 348+ passed, 0 failed
- [ ] E2E tests: 5 passed, 0 failed
- [ ] Coverage: ≥70%
- [ ] No timeout errors
- [ ] Artifacts generated successfully
- [ ] Coverage report downloaded and reviewed
- [ ] No security vulnerabilities reported

### Red Flags (Don't Merge)

- ❌ Any job failed
- ❌ Tests skipped unexpectedly
- ❌ Coverage <70%
- ❌ E2E tests timed out
- ❌ Missing artifacts
- ❌ Unexplained warnings

---

## 📚 Additional Resources

### GitHub Actions Documentation
- [Workflow syntax](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions)
- [Artifacts](https://docs.github.com/en/actions/using-workflows/storing-workflow-data-as-artifacts)
- [Matrix builds](https://docs.github.com/en/actions/using-jobs/using-a-matrix-for-your-jobs)

### Project Documentation
- [E2E Testing Guide](tests/E2E_TESTING.md)
- [Coverage Tracking](COVERAGE_TRACKING.md)
- [Testing README](tests/README.md)
- [Baseline Assessment](BASELINE_ESTABLISHED.md)

### Quick Commands

```bash
# View workflow status
gh workflow view

# List recent runs
gh run list

# View specific run
gh run view <run-id>

# Download artifacts
gh run download <run-id>

# Re-run failed jobs
gh run rerun <run-id> --failed
```

---

## 🎯 Next Steps After First Successful Run

1. **Document Baseline**
   - Update BASELINE_ESTABLISHED.md
   - Add actual coverage percentage
   - List low-coverage files

2. **Review Coverage Report**
   - Open coverage-report.html
   - Identify improvement opportunities
   - Create action plan

3. **Set Up Monitoring**
   - Track coverage over time
   - Monitor test failures
   - Review E2E screenshots periodically

4. **Share Results**
   - Post coverage summary in PR
   - Share with team
   - Update project documentation

---

**Last Updated**: 2024-12-24
**Workflow Version**: 1.5.2
**Status**: ✅ Ready for first run
