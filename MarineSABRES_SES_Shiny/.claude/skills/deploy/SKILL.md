---
name: deploy
description: Deploy the SES Toolbox to laguna.ku.lt — runs pre-deploy checks, SCPs changed files, and verifies the deployment is live
disable-model-invocation: true
---

# Deploy to Production

Deploy the MarineSABRES SES Toolbox to the Shiny Server at laguna.ku.lt.

## Arguments

- `--full` — Deploy all app files (default: only changed files since last commit)
- `--data-only` — Deploy only data/ directory (KB files, templates)
- `--skip-checks` — Skip pre-deploy validation (use with caution)
- `--dry-run` — Show what would be deployed without actually deploying

## Workflow

### 1. Pre-deploy validation (unless --skip-checks)

Run the pre-deploy check:

```bash
Rscript deployment/pre-deploy-check.R
```

If it fails, stop and report. Do NOT proceed with deployment.

Also check for uncommitted changes:

```bash
git status --short
```

Warn if uncommitted changes exist — they won't be deployed.

### 2. Determine files to deploy

**If `--full`**: Deploy the entire app:
```
app.R global.R constants.R DESCRIPTION
modules/*.R functions/*.R server/*.R
data/*.json data/*.R
translations/**/*.json
```

**If `--data-only`**: Deploy only:
```
data/*.json data/*.R
```

**Default** (changed files): Use git to find what changed:
```bash
git diff --name-only HEAD~1 -- . | grep -v '^\.'
```

Filter to deployable files only (R, JSON, CSV — not tests, scripts, docs, screenshots).

### 3. Deploy via SCP

The server target is: `razinka@laguna.ku.lt:/srv/shiny-server/marinesabres/`

For each file, preserve the directory structure:

```bash
scp <local-path> razinka@laguna.ku.lt:/srv/shiny-server/marinesabres/<relative-path>
```

Report each file as it's deployed.

### 4. Verify deployment

Check the server is responding:

```bash
ssh razinka@laguna.ku.lt "ls -la /srv/shiny-server/marinesabres/app.R && curl -s -o /dev/null -w '%{http_code}' http://localhost:3838/marinesabres/"
```

Report:
- File timestamps on server
- HTTP status code
- Any errors

### 5. Summary

```
## Deployment Summary

- Files deployed: N
- Target: razinka@laguna.ku.lt:/srv/shiny-server/marinesabres/
- Pre-deploy check: PASS/FAIL
- Server status: HTTP XXX
- Uncommitted changes: YES/NO
```

## Rules

- Always confirm the file list with the user before deploying (unless --dry-run)
- Never deploy .claude/, .git/, tests/, scripts/, docs/, *.png, *.md files
- Never deploy .RData, .Rhistory, or credential files
- If SCP fails for any file, report the error and continue with remaining files
- If SSH is unavailable, report the connection error and stop
