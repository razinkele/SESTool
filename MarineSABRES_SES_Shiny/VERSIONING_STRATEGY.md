# Versioning Strategy

## Overview

MarineSABRES SES Shiny Application follows **Semantic Versioning 2.0.0** ([semver.org](https://semver.org/)) with a stable/development branch strategy.

---

## Version Number Format

### Semantic Versioning: `MAJOR.MINOR.PATCH`

```
1.1.0
│ │ │
│ │ └─ PATCH: Backwards-compatible bug fixes
│ └─── MINOR: New features (backwards-compatible)
└───── MAJOR: Breaking changes (not backwards-compatible)
```

### Examples
- `1.0.0` → `1.0.1`: Bug fix release
- `1.0.1` → `1.1.0`: New feature release
- `1.1.0` → `2.0.0`: Breaking change release

---

## Version Files

### 1. VERSION (Plain Text)
**Location:** `/VERSION`
**Format:** Single line with version number
**Purpose:** Machine-readable version identifier
**Example:**
```
1.1.0
```

### 2. VERSION_INFO.json (Detailed Metadata)
**Location:** `/VERSION_INFO.json`
**Format:** JSON with complete version metadata
**Purpose:** Human and machine-readable detailed version information
**Example:**
```json
{
  "version": "1.1.0",
  "version_name": "Create SES Release",
  "release_date": "2025-01-25",
  "release_type": "minor",
  "status": "stable"
}
```

### 3. CHANGELOG.md (Release History)
**Location:** `/CHANGELOG.md`
**Format:** Markdown following [Keep a Changelog](https://keepachangelog.com/)
**Purpose:** Human-readable release notes and history

---

## Branch Strategy

### Main Branches

#### 1. `main` (Stable/Production)
- **Purpose:** Stable, production-ready code
- **Version:** Stable releases only (1.0.0, 1.1.0, 2.0.0)
- **Protection:** Protected branch, requires PR approval
- **Deployment:** Auto-deploys to production
- **Status Badge:** [![Version](https://img.shields.io/badge/version-1.1.0-blue.svg)](VERSION)

#### 2. `develop` (Development)
- **Purpose:** Integration branch for features
- **Version:** Development versions (1.1.0-dev, 1.2.0-dev)
- **Protection:** Semi-protected, requires PR from features
- **Deployment:** Auto-deploys to staging
- **Status:** Latest development code

### Supporting Branches

#### 3. `feature/*` (Feature Development)
- **Naming:** `feature/[issue-number]-[short-description]`
- **Examples:**
  - `feature/123-add-export-pdf`
  - `feature/456-improve-performance`
- **Lifetime:** Temporary, deleted after merge
- **Merge to:** `develop` branch
- **Version:** No version change in feature branch

#### 4. `hotfix/*` (Emergency Fixes)
- **Naming:** `hotfix/[version]-[issue]`
- **Examples:**
  - `hotfix/1.1.1-critical-bug`
  - `hotfix/1.0.2-security-fix`
- **Lifetime:** Temporary, deleted after merge
- **Merge to:** Both `main` and `develop`
- **Version:** PATCH increment (1.1.0 → 1.1.1)

#### 5. `release/*` (Release Preparation)
- **Naming:** `release/[version]`
- **Examples:**
  - `release/1.2.0`
  - `release/2.0.0`
- **Lifetime:** Temporary, until release
- **Merge to:** `main` and `develop`
- **Version:** Final version finalized here

---

## Release Workflow

### For Minor/Major Releases

```
1. Create release branch from develop
   git checkout develop
   git pull origin develop
   git checkout -b release/1.2.0

2. Update version files
   - VERSION: 1.2.0
   - VERSION_INFO.json: Update all fields
   - CHANGELOG.md: Finalize unreleased section
   - global.R: Update APP_VERSION constant

3. Run full test suite
   Rscript run_tests.R

4. Update documentation
   - README.md version badges
   - Deployment guides
   - User guides

5. Create PR to main
   - PR title: "Release v1.2.0"
   - Description: Link to CHANGELOG
   - Reviewers: Team lead

6. After approval, merge to main
   git checkout main
   git merge --no-ff release/1.2.0
   git tag -a v1.2.0 -m "Release version 1.2.0"
   git push origin main --tags

7. Merge back to develop
   git checkout develop
   git merge --no-ff release/1.2.0
   git push origin develop

8. Delete release branch
   git branch -d release/1.2.0
```

### For Hotfixes

```
1. Create hotfix branch from main
   git checkout main
   git checkout -b hotfix/1.1.1-critical-bug

2. Fix the bug and update version
   - VERSION: 1.1.1
   - VERSION_INFO.json
   - CHANGELOG.md

3. Test thoroughly
   Rscript run_tests.R

4. Merge to main
   git checkout main
   git merge --no-ff hotfix/1.1.1-critical-bug
   git tag -a v1.1.1 -m "Hotfix version 1.1.1"
   git push origin main --tags

5. Merge to develop
   git checkout develop
   git merge --no-ff hotfix/1.1.1-critical-bug
   git push origin develop

6. Delete hotfix branch
   git branch -d hotfix/1.1.1-critical-bug
```

---

## Version Incrementing Rules

### When to Increment MAJOR (x.0.0)
- Breaking changes to API
- Incompatible data format changes
- Major UI/UX overhaul requiring retraining
- Removal of deprecated features
- R version requirement change (major)

**Examples:**
- Change from shiny to other framework
- Complete data structure redesign
- Breaking changes to saved project format

### When to Increment MINOR (0.x.0)
- New features (backwards-compatible)
- New modules or major enhancements
- New templates or analysis tools
- Significant performance improvements
- New language support

**Examples:**
- Add Create SES feature (1.0.0 → 1.1.0) ✅
- Add new analysis module
- Add template library
- Add 3 new languages

### When to Increment PATCH (0.0.x)
- Bug fixes
- Documentation updates
- Translation corrections
- Minor UI tweaks
- Security patches (non-breaking)
- Performance optimizations

**Examples:**
- Fix calculation error
- Correct translation typo
- Fix UI alignment issue
- Security patch

---

## Development Version Naming

### Format
`MAJOR.MINOR.PATCH-dev[.BUILD]`

### Examples
- `1.2.0-dev`: Development version for next 1.2.0 release
- `1.2.0-dev.1`: First development build
- `1.2.0-dev.42`: 42nd development build
- `2.0.0-alpha.1`: Alpha version
- `2.0.0-beta.1`: Beta version
- `2.0.0-rc.1`: Release candidate

### Pre-release Identifiers
- `-dev`: Active development
- `-alpha`: Feature complete, unstable
- `-beta`: Feature complete, testing phase
- `-rc`: Release candidate, final testing

---

## Version in Code

### Reading VERSION File

**In global.R:**
```r
# Read version from VERSION file
APP_VERSION <- tryCatch({
  readLines("VERSION", warn = FALSE)[1]
}, error = function(e) {
  "1.0.0-unknown"
})

# Read detailed version info
VERSION_INFO <- tryCatch({
  jsonlite::fromJSON("VERSION_INFO.json")
}, error = function(e) {
  list(version = APP_VERSION, status = "unknown")
})

# Log version on startup
log_message(paste("Application version:", APP_VERSION))
log_message(paste("Version status:", VERSION_INFO$status))
```

### Using Version in UI

**In app.R:**
```r
# Header
dashboardHeader(
  title = paste("MarineSABRES SES", APP_VERSION)
)

# Footer
div(class = "footer",
    paste("Version", APP_VERSION, "|", VERSION_INFO$version_name)
)
```

---

## CHANGELOG.md Format

### Structure

```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- New features in development

### Changed
- Changes in existing functionality

### Deprecated
- Soon-to-be removed features

### Removed
- Now removed features

### Fixed
- Bug fixes

### Security
- Vulnerability fixes

## [1.1.0] - 2025-01-25

### Added
- Create SES interface with 3 entry methods
- Template library with 5 pre-built SES templates
- Complete internationalization (7 languages)
- Comprehensive testing framework (2417 tests)
- Entry point guidance system

### Changed
- Consolidated ISA entry into Create SES menu
- Reorganized menu structure

### Fixed
- Translation consistency issues
- Module navigation bugs

## [1.0.0] - 2025-01-15

### Added
- Initial release
- Core DAPSI(W)R(M) framework
- Network visualization
- Basic export functionality
```

---

## Tagging Strategy

### Git Tags

**Format:** `v[VERSION]`

**Examples:**
```bash
git tag -a v1.1.0 -m "Release version 1.1.0 - Create SES"
git tag -a v1.0.1 -m "Hotfix version 1.0.1 - Critical bug fix"
git tag -a v2.0.0-beta.1 -m "Beta version 2.0.0-beta.1"
```

**List tags:**
```bash
git tag -l "v*"
```

**Push tags:**
```bash
git push origin --tags
```

---

## Automated Version Management

### version_manager.R Script

Create helper script for version management:

```r
#!/usr/bin/env Rscript
# version_manager.R
# Automated version management script

library(jsonlite)

# Read current version
get_version <- function() {
  readLines("VERSION", warn = FALSE)[1]
}

# Update version files
update_version <- function(new_version, version_name, release_type) {
  # Update VERSION file
  writeLines(new_version, "VERSION")

  # Update VERSION_INFO.json
  info <- fromJSON("VERSION_INFO.json")
  info$version <- new_version
  info$version_name <- version_name
  info$release_date <- as.character(Sys.Date())
  info$release_type <- release_type
  write_json(info, "VERSION_INFO.json", pretty = TRUE, auto_unbox = TRUE)

  cat("✓ Updated VERSION to", new_version, "\n")
  cat("✓ Updated VERSION_INFO.json\n")
}

# Increment version
increment_version <- function(type = c("major", "minor", "patch")) {
  type <- match.arg(type)
  current <- get_version()
  parts <- as.integer(strsplit(current, "\\.")[[1]])

  if (type == "major") {
    parts[1] <- parts[1] + 1
    parts[2] <- 0
    parts[3] <- 0
  } else if (type == "minor") {
    parts[2] <- parts[2] + 1
    parts[3] <- 0
  } else {
    parts[3] <- parts[3] + 1
  }

  paste(parts, collapse = ".")
}

# CLI interface
args <- commandArgs(trailingOnly = TRUE)
if (length(args) == 0) {
  cat("Current version:", get_version(), "\n")
} else if (args[1] == "bump") {
  type <- ifelse(length(args) > 1, args[2], "patch")
  new_ver <- increment_version(type)
  version_name <- ifelse(length(args) > 2, args[3], paste(type, "update"))
  update_version(new_ver, version_name, type)
} else if (args[1] == "set") {
  update_version(args[2], args[3], args[4])
}
```

**Usage:**
```bash
# Check current version
Rscript version_manager.R

# Bump patch version
Rscript version_manager.R bump patch "Bug fixes"

# Bump minor version
Rscript version_manager.R bump minor "New features"

# Bump major version
Rscript version_manager.R bump major "Breaking changes"

# Set specific version
Rscript version_manager.R set 2.0.0 "Major release" major
```

---

## Release Checklist

### Pre-Release
- [ ] All tests passing (2417/2417)
- [ ] Documentation updated
- [ ] CHANGELOG.md updated
- [ ] VERSION files updated
- [ ] Translation keys complete
- [ ] No TODO/FIXME in code
- [ ] Performance tested
- [ ] Security audit done

### Release
- [ ] Create release branch
- [ ] Final version bump
- [ ] Create PR to main
- [ ] Code review completed
- [ ] Merge to main
- [ ] Create git tag
- [ ] Build deployment artifacts
- [ ] Deploy to production

### Post-Release
- [ ] Merge back to develop
- [ ] Announce release
- [ ] Update documentation site
- [ ] Archive old versions
- [ ] Plan next release

---

## Version Support Policy

### Long-Term Support (LTS)

**Major versions:** Supported for 12 months after next major release

**Example:**
- v1.x.x: Supported until v2.0.0 + 12 months
- v2.x.x: Supported until v3.0.0 + 12 months

### Security Updates

**Critical security fixes:** Backported to all supported versions
**Non-critical updates:** Next minor/major release only

### Bug Fixes

**Critical bugs:** Hotfix to latest stable version
**Non-critical bugs:** Next minor release

---

## Deprecation Policy

### Deprecation Timeline

1. **Announce deprecation** in CHANGELOG (minimum 1 minor version)
2. **Add deprecation warnings** in code
3. **Remove in next major version**

**Example:**
- v1.5.0: Announce feature X deprecated
- v1.6.0 - v1.9.x: Deprecation warnings active
- v2.0.0: Feature X removed

---

## Version Badge

### README.md Badge

```markdown
![Version](https://img.shields.io/badge/version-1.1.0-blue.svg)
![Status](https://img.shields.io/badge/status-stable-green.svg)
![R Version](https://img.shields.io/badge/R-%E2%89%A54.4.1-blue.svg)
```

---

## Conclusion

This versioning strategy ensures:
✅ **Clear version identification** via semantic versioning
✅ **Stable production releases** via branch protection
✅ **Controlled development** via feature branches
✅ **Emergency response** via hotfix workflow
✅ **Complete history** via CHANGELOG and git tags
✅ **Automated management** via version_manager.R script

---

**Document Version:** 1.0
**Last Updated:** 2025-01-25
**Maintained By:** Development Team
