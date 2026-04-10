---
name: pre-deploy
description: Run pre-deployment validation — checks code quality, translations, tests, dependencies, and walks through the deployment checklist before pushing to production
disable-model-invocation: true
---

# Pre-Deployment Validation

Run a comprehensive pre-deployment audit for the MarineSABRES SES Toolbox.

## Workflow

### 1. Run automated checks

Execute the pre-deploy check script and capture results:

```bash
Rscript deployment/pre-deploy-check.R
```

Report any failures. If the script is missing or errors, fall back to manual checks in step 2.

### 2. Validate translations

```bash
Rscript scripts/generate_translations.R
```

Verify:
- All 9 languages present (en, es, fr, de, lt, pt, it, no, el)
- No duplicate keys
- `translations/_merged_translations.json` is valid JSON
- No missing translations for any key

### 3. Run test suite

```bash
Rscript -e "testthat::test_dir('tests/testthat')"
```

Report test count, passes, failures, and skips. If testthat is not installed, note this and skip.

### 4. Check for uncommitted changes

```bash
git status --short
```

Warn if there are uncommitted changes — these won't be in the deployment.

### 5. Check for temporary/debug artifacts

Search for files that should not be deployed:

- `*.tmp`, `*.log` files in project root
- `.RData`, `.Rhistory` files
- `*.backup`, `*_old.R` files
- Screenshot PNGs in project root (test artifacts)
- Debug mode enabled: check if `MARINESABRES_DEBUG` is set to TRUE in any committed file

Report any found artifacts with recommendation to clean up.

### 6. Validate dependencies

Check that `DESCRIPTION` lists all packages actually used:

```bash
grep -roh 'library([^)]*)\|require([^)]*)' *.R modules/*.R functions/*.R server/*.R | sort -u
```

Compare against DESCRIPTION Imports. Flag any missing.

### 7. Version check

Read VERSION or DESCRIPTION for current version. Compare with the latest git tag:

```bash
git describe --tags --abbrev=0 2>/dev/null
```

Warn if the version in DESCRIPTION doesn't match or exceed the latest tag.

### 8. Deployment checklist walkthrough

Present the key checklist items from `deployment/DEPLOYMENT_CHECKLIST.md` as a summary:

```
## Pre-Deploy Summary

### Automated Checks
- [ ] pre-deploy-check.R: PASS/FAIL
- [ ] Translation validation: PASS/FAIL  
- [ ] Test suite: X passed, Y failed, Z skipped
- [ ] Uncommitted changes: YES/NO
- [ ] Temp artifacts: N found
- [ ] Dependency check: PASS/FAIL
- [ ] Version: X.Y.Z (tag: vA.B.C)

### Manual Steps Required
- [ ] Docker build tested locally (if using Docker)
- [ ] Firewall/SSL configured (production)
- [ ] Backup of current deployment taken
```

### 9. Go/No-Go recommendation

Based on results:
- **GO**: All automated checks pass, no uncommitted changes, no temp artifacts
- **CAUTION**: Minor issues found (temp files, version mismatch) — list them
- **NO-GO**: Test failures, translation errors, or missing dependencies — must fix first

## Rules

- Do NOT deploy or push anything — this skill only validates and reports
- Do NOT fix issues automatically — report them for the user to decide
- If a check command is unavailable (e.g., testthat not installed), note it and continue
- Always run checks from the project root directory
