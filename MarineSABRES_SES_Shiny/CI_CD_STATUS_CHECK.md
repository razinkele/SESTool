# CI/CD Status Check Guide

**Date**: 2024-12-24
**Repository**: https://github.com/razinkele/SESTool
**Last Push**: Successfully completed
**Status**: Workflow should be running or completed

---

## 🔍 How to Check CI/CD Status

### Method 1: Web Browser (Recommended)

1. **Open GitHub Actions**:
   ```
   https://github.com/razinkele/SESTool/actions
   ```

2. **Find Latest Workflow Run**:
   - Look for "R Tests" workflow
   - Commit message: "Major testing infrastructure overhaul"
   - Should be at the top of the list

3. **Check Status**:
   - ⚙️ **Yellow circle** = Still running
   - ✅ **Green checkmark** = Success
   - ❌ **Red X** = Failed
   - ⏸️ **Gray circle** = Pending/Queued

### Method 2: Direct Link

If you have the run URL, go directly to it:
```
https://github.com/razinkele/SESTool/actions/runs/[RUN_ID]
```

### Method 3: GitHub CLI (if installed)

```bash
# List recent runs
gh run list --repo razinkele/SESTool --limit 5

# View specific run
gh run view --repo razinkele/SESTool

# Watch in real-time
gh run watch --repo razinkele/SESTool
```

---

## 📊 What You Should See

### If Workflow is Still Running ⚙️

**Timeline**:
- **0-3 min**: Setup and installation
- **3-10 min**: Installing dependencies (can take longer first time)
- **10-14 min**: Running unit/integration tests
- **14-20 min**: Running E2E tests (R 4.3 only)
- **20-26 min**: Generating coverage (Linux + R 4.3 only)

**Current Status Indicators**:
- Yellow spinning icon = Running
- Some jobs may complete before others
- Check individual job logs for progress

**What to Do**:
- ⏰ Wait for completion (typical: 18-26 minutes)
- ☕ Can check back in 10-15 minutes
- 📧 GitHub will email you when done

### If Workflow Completed Successfully ✅

**You'll see**:
```
✅ All 9 jobs passed
   ✓ ubuntu-latest (4.2, 4.3, 4.4)
   ✓ windows-latest (4.2, 4.3, 4.4)
   ✓ macos-latest (4.2, 4.3, 4.4)
```

**In the logs, look for**:
```
✓ | 348+ | Unit and integration tests passed
✓ | 5 | E2E tests passed
Overall Coverage: XX.XX%
✓ Coverage meets minimum threshold (70%)
```

**Next Steps**:
1. ✅ Download coverage-report artifact
2. ✅ Review coverage HTML report
3. ✅ Update BASELINE_ESTABLISHED.md
4. ✅ Commit baseline update
5. 🎉 Celebrate - Testing framework is now Grade A-!

### If Workflow Failed ❌

**Common Failure Scenarios**:

#### Scenario 1: Test Failures
```
✗ | X | Some test(s) failed
```

**What to do**:
1. Click on failed job
2. Scroll to "Run tests" step
3. Read error messages
4. Fix the failing tests
5. Commit and push again

#### Scenario 2: E2E Timeout
```
✗ | 1 | E2E: App launches successfully
Error: Timed out waiting for app
```

**What to do**:
1. Download "e2e-screenshots" artifact
2. View screenshot to see what happened
3. Check if app has startup issues
4. Increase timeout if needed
5. Fix and push again

#### Scenario 3: Coverage Below Threshold
```
ERROR: Coverage 65.2% is below threshold of 70%
Process completed with exit code 1.
```

**This is EXPECTED if coverage is actually low!**

**What to do**:
1. ✅ This is working as designed
2. Download coverage-report artifact
3. Open coverage-report.html
4. Identify files with <70% coverage
5. Write tests for uncovered code
6. Push again
7. Repeat until ≥70%

**DO NOT**: Lower the 70% threshold

#### Scenario 4: Installation Failures
```
Error: Package 'shinytest2' installation failed
```

**What to do**:
1. Check if package name is correct
2. Check CRAN availability
3. May need to retry (transient CRAN issues)
4. Re-run workflow from GitHub UI

---

## 📥 Downloading Artifacts

### Step 1: Navigate to Artifacts

After workflow completes (success or failure):

1. **Go to workflow run page**
2. **Scroll to bottom**
3. **Find "Artifacts" section**

### Step 2: Available Artifacts

Depending on outcome:

**If Successful**:
- ✅ **coverage-report** (4 files)
  - coverage-report.html
  - coverage-details.csv
  - coverage-summary.md
  - coverage.rds

**If E2E Tests Failed**:
- 📸 **e2e-screenshots-ubuntu**
- 📸 **e2e-screenshots-windows**
- 📸 **e2e-screenshots-macos**

**If Any Tests Failed**:
- 📄 **test-results-[os]-[version]**

### Step 3: Download and Extract

1. **Click artifact name** (e.g., "coverage-report")
2. **ZIP file downloads automatically**
3. **Unzip on your computer**
4. **Open files**:
   - HTML: Use web browser
   - CSV: Use Excel/Google Sheets
   - RDS: Use R (`readRDS()`)

---

## 📈 Interpreting Coverage Report

### Opening the HTML Report

1. **Unzip coverage-report.zip**
2. **Double-click `coverage-report.html`**
3. **Opens in default browser**

### What You'll See

**Overall Summary**:
```
MarineSABRES SES Shiny Coverage Report
Overall: XX.XX%

Files Covered:
[List of all R files with coverage percentages]
```

**Color Coding**:
- 🟢 **Green**: 80-100% coverage (excellent)
- 🟡 **Yellow**: 70-79% coverage (acceptable)
- 🟠 **Orange**: 60-69% coverage (needs work)
- 🔴 **Red**: <60% coverage (critical)

### Detailed File View

**Click any file** to see line-by-line coverage:

- **Green lines**: Covered by tests ✅
- **Red lines**: Not covered by tests ❌
- **Gray lines**: Non-executable (comments, blank)

**Example**:
```r
1  function calculate_total(data) {    # Green - covered
2    if (is.null(data)) {              # Green - covered
3      stop("Data is NULL")            # Red - not covered
4    }
5    sum(data$values)                  # Green - covered
6  }
```

Line 3 is red = This error path is not tested!

### Finding Low Coverage Files

**In coverage-details.csv**:

1. Open in Excel
2. Sort by coverage column (ascending)
3. Files at top have lowest coverage
4. These need more tests

**In coverage-report.html**:

1. Scroll through file list
2. Look for red/orange files
3. Click to see uncovered lines
4. Write tests for those lines

---

## 🎯 What to Do Based on Results

### Result 1: All Passed, Coverage ≥70% ✅

**Congratulations!** 🎉

**Action Plan**:

1. **Document Baseline** (5 min):
   ```bash
   # Edit BASELINE_ESTABLISHED.md
   # Add actual coverage: XX.XX%
   # List files needing improvement

   git add BASELINE_ESTABLISHED.md
   git commit -m "Document coverage baseline: XX.XX%"
   git push origin main
   ```

2. **Review Coverage Report** (10 min):
   - Download and open coverage-report.html
   - Note overall percentage
   - Identify improvement opportunities
   - Plan next testing priorities

3. **Share Success** (optional):
   - Post results to team
   - Update project documentation
   - Celebrate the upgrade to Grade A-!

4. **Set Up Monitoring**:
   - Track coverage over time
   - Monitor test failures
   - Review E2E screenshots periodically

### Result 2: All Passed, Coverage <70% ❌

**Build Failed - As Designed**

**Action Plan**:

1. **Download Coverage Report**:
   - Get coverage-report artifact
   - Open coverage-report.html

2. **Identify Gaps**:
   - Find files with <70% coverage
   - List uncovered lines in each file
   - Prioritize by importance

3. **Write Tests**:
   - Focus on critical files first
   - Write tests for uncovered code paths
   - Test error handling
   - Test edge cases

4. **Re-run**:
   ```bash
   # After adding tests
   git add tests/
   git commit -m "Add tests to improve coverage"
   git push origin main
   # CI/CD runs again
   ```

5. **Repeat** until coverage ≥70%

### Result 3: Tests Failed ❌

**Action Plan**:

1. **Identify Failure**:
   - Click on failed job
   - Find which test failed
   - Read error message

2. **Fix Issue**:
   - Fix the failing test
   - Or fix the code causing failure
   - Test locally first

3. **Push Fix**:
   ```bash
   git add .
   git commit -m "Fix test failure: [description]"
   git push origin main
   ```

4. **Monitor**: CI/CD runs again automatically

### Result 4: E2E Tests Failed ❌

**Action Plan**:

1. **Download Screenshots**:
   - Get e2e-screenshots artifact
   - Unzip and view PNG files

2. **Analyze Screenshots**:
   - What did the browser show?
   - Did app fail to load?
   - Did elements not appear?
   - Was there an error message?

3. **Fix Root Cause**:
   - If app startup issue: Fix app.R
   - If timeout: Increase timeout in test
   - If element not found: Check selectors
   - If test logic issue: Fix test

4. **Test Locally** (optional):
   ```r
   library(testthat)
   test_file("tests/testthat/test-app-e2e.R")
   ```

5. **Push Fix** and monitor

---

## 📊 Expected Coverage Baseline

Based on the test suite structure, we expect:

### Optimistic Estimate (Best Case)
- **Overall**: 75-80%
- **Global utilities**: 90%+
- **Data structures**: 80-85%
- **Network analysis**: 75-80%
- **Modules**: 60-70%
- **UI helpers**: 50-60%

### Realistic Estimate (Likely)
- **Overall**: 70-75%
- **Global utilities**: 85-90%
- **Data structures**: 75-80%
- **Network analysis**: 70-75%
- **Modules**: 55-65%
- **UI helpers**: 45-55%

### Pessimistic Estimate (Worst Case)
- **Overall**: 65-70%
- Would require additional testing
- Build would fail (intentional)
- Need to write more tests

**Target**: ≥70% to pass CI/CD

---

## 🔄 Re-running the Workflow

### Method 1: Push New Commit

```bash
# Make any change
git add .
git commit -m "Improve test coverage"
git push origin main
# Workflow runs automatically
```

### Method 2: Manual Re-run (GitHub UI)

1. Go to failed workflow run
2. Click "Re-run all jobs" button (top right)
3. Workflow starts again

### Method 3: Re-run Failed Jobs Only

1. Go to workflow run
2. Click "Re-run failed jobs"
3. Only failed jobs run (faster)

---

## 📝 Updating Baseline Documentation

Once you have actual coverage numbers:

### Edit BASELINE_ESTABLISHED.md

Replace the template section with actual data:

```markdown
## ACTUAL COVERAGE BASELINE

**Date**: 2024-12-24
**Workflow Run**: https://github.com/razinkele/SESTool/actions/runs/[RUN_ID]
**Platform**: Linux, R 4.3

### Overall Coverage

- **Actual Coverage**: 74.52%
- **Threshold**: 70%
- **Status**: ✅ PASS
- **Gap to Target (80%)**: 5.48%

### Coverage by Component

| Component | Coverage | Status |
|-----------|----------|--------|
| Global utilities | 87.3% | ✅ |
| Data structure | 76.8% | ✅ |
| Network analysis | 72.1% | ✅ |
| Modules | 58.4% | ⚠️ |
| UI helpers | 51.2% | ⚠️ |
| Export functions | 79.6% | ✅ |

### Files Needing Attention (<70%)

1. modules/some_module.R - 58.4%
2. functions/ui_helpers.R - 51.2%
3. ... (list others)

### Coverage Improvement Plan

1. Add module tests for uncovered paths
2. Write UI helper tests
3. Test error scenarios
4. Target: 80% overall by next sprint
```

### Commit the Update

```bash
git add BASELINE_ESTABLISHED.md
git commit -m "Document actual coverage baseline: 74.52%"
git push origin main
```

---

## 🎓 Quick Reference

### Check Status
```
https://github.com/razinkele/SESTool/actions
```

### Expected Timeline
- **First run**: 18-26 minutes
- **Cached runs**: 12-18 minutes (faster)

### Success Criteria
- [ ] All 9 jobs pass
- [ ] 348+ unit/integration tests pass
- [ ] 5 E2E tests pass
- [ ] Coverage ≥70%
- [ ] Artifacts uploaded

### If Failed
1. Read error messages
2. Download artifacts
3. Fix issues
4. Push again
5. Repeat until green

---

## 📞 Getting Help

### Workflow Issues
- Check GitHub Actions logs
- Look for specific error messages
- Search GitHub Actions documentation

### Test Failures
- Review test error messages
- Run tests locally first
- Check test-specific documentation

### Coverage Issues
- Download HTML report
- Review uncovered lines
- Write tests for those lines

### E2E Issues
- Download screenshots
- Check app startup logs
- Review E2E_TESTING.md guide

---

## ✅ Final Checklist

After CI/CD completes:

- [ ] Checked workflow status (pass/fail)
- [ ] Downloaded coverage-report artifact
- [ ] Opened coverage-report.html
- [ ] Noted overall coverage percentage
- [ ] Identified low-coverage files
- [ ] Updated BASELINE_ESTABLISHED.md
- [ ] Committed baseline update
- [ ] Created improvement plan (if needed)
- [ ] Shared results (if working with team)

---

**Current Status**: Waiting for CI/CD completion
**Check At**: https://github.com/razinkele/SESTool/actions
**Expected Result**: All tests pass, coverage ≥70%

**Good luck!** 🚀
