# Version Management Quick Reference

## Current Version

![Version](https://img.shields.io/badge/version-1.1.0-blue.svg)
![Status](https://img.shields.io/badge/status-stable-green.svg)
![R Version](https://img.shields.io/badge/R-%E2%89%A54.4.1-blue.svg)
![Tests](https://img.shields.io/badge/tests-2417%20passing-success.svg)

**Version:** 1.1.0
**Name:** Create SES Release
**Date:** 2025-01-25
**Status:** Stable

---

## Quick Commands

### Check Version
```bash
Rscript version_manager.R
```

### Bump Versions
```bash
# Patch (1.1.0 → 1.1.1) - Bug fixes
Rscript version_manager.R bump patch "Description"

# Minor (1.1.0 → 1.2.0) - New features
Rscript version_manager.R bump minor "Description"

# Major (1.1.0 → 2.0.0) - Breaking changes
Rscript version_manager.R bump major "Description"
```

### Development Versions
```bash
# Set to development (1.1.0 → 1.2.0-dev)
Rscript version_manager.R dev

# Set to stable (1.2.0-dev → 1.2.0)
Rscript version_manager.R stable
```

### Set Specific Version
```bash
Rscript version_manager.R set 2.0.0 "Release name" major
```

---

## Workflow Cheat Sheet

### Feature Release (Minor)

```bash
# 1. Create release branch
git checkout develop
git pull
git checkout -b release/1.2.0

# 2. Bump version
Rscript version_manager.R bump minor "New features"

# 3. Update CHANGELOG.md
# (Edit manually)

# 4. Test
Rscript run_tests.R

# 5. Merge to main
git checkout main
git merge --no-ff release/1.2.0

# 6. Tag
git tag -a v1.2.0 -m "Release 1.2.0"
git push origin main --tags

# 7. Merge back to develop
git checkout develop
git merge --no-ff release/1.2.0
git push
```

### Hotfix (Patch)

```bash
# 1. Create hotfix branch
git checkout main
git checkout -b hotfix/1.1.1-fix

# 2. Bump version
Rscript version_manager.R bump patch "Critical fix"

# 3. Fix and test
Rscript run_tests.R

# 4. Merge to main
git checkout main
git merge --no-ff hotfix/1.1.1-fix
git tag -a v1.1.1 -m "Hotfix 1.1.1"
git push origin main --tags

# 5. Merge to develop
git checkout develop
git merge --no-ff hotfix/1.1.1-fix
git push
```

---

## Version Files

### VERSION
Plain text file with version number
```
1.1.0
```

### VERSION_INFO.json
Detailed JSON metadata
```json
{
  "version": "1.1.0",
  "version_name": "Create SES Release",
  "status": "stable"
}
```

---

## Semantic Versioning Rules

### MAJOR (x.0.0)
- Breaking API changes
- Incompatible data formats
- Major UI redesign
- R version requirement change

### MINOR (0.x.0)
- New features (backwards-compatible)
- New modules
- New templates
- New languages

### PATCH (0.0.x)
- Bug fixes
- Documentation updates
- Translation corrections
- Minor UI tweaks
- Security patches

---

## Branch Types

| Branch | Purpose | Lifetime | Merges To |
|--------|---------|----------|-----------|
| `main` | Production | Permanent | - |
| `develop` | Integration | Permanent | - |
| `feature/*` | Features | Temporary | develop |
| `hotfix/*` | Fixes | Temporary | main, develop |
| `release/*` | Prep | Temporary | main, develop |

---

## Help

### Show All Commands
```bash
Rscript version_manager.R help
```

### Documentation
- Full guide: `VERSIONING_STRATEGY.md`
- Complete summary: `VERSIONING_AND_ANALYSIS_COMPLETE.md`

---

**Last Updated:** 2025-01-25
**Current Stable:** v1.1.0
**Next Planned:** v1.2.0
