# WORKFLOW.md — Daily Driver Cheatsheet

Personal cheatsheet for working on this repo. For contribution policy (i18n requirements, testing standards, PR review process), see [CONTRIBUTING.md](CONTRIBUTING.md). For AI-agent guidance, see [CLAUDE.md](CLAUDE.md).

---

## Where the repo lives

```
C:\Users\arturas.baziukas\projects\SESTool\           ← repo root
└── MarineSABRES_SES_Shiny\                           ← app subdirectory (work here)
```

**Do not move this repo into OneDrive, Dropbox, Google Drive, or any other cloud-sync folder.** Git stores files like `.git/index`, `.git/HEAD`, and `.git/objects/` that must be written atomically. When two devices sync the same `.git/` simultaneously, cloud-sync conflict resolution renames files with suffixes like `-laguna-safeBackup-XXXX`, which destroys git's internal consistency. The previous `SESToolbox/.git/` under OneDrive was destroyed exactly this way (14 safeBackup artifacts, zero working git files).

If you need cross-device access, push to GitHub and pull on the other device.

---

## Day-to-day commands

All commands assume you are in `C:\Users\arturas.baziukas\projects\SESTool\MarineSABRES_SES_Shiny\` unless noted. Many `git` examples include `-C <path>` so they work from anywhere — drop the flag when you're already in the repo.

### Start a new piece of work

```bash
git checkout main
git pull
git checkout -b fix/short-descriptive-slug          # or feat/, docs/, refactor/, chore/, test/
```

Branch prefixes match the existing convention in the repo (see `git branch -r`):

| Prefix     | When to use                                                  |
|------------|--------------------------------------------------------------|
| `fix/`     | Bug fix that changes runtime behavior                        |
| `feat/`    | New user-facing functionality                                |
| `refactor/`| Internal cleanup with no behavior change                     |
| `docs/`    | Documentation-only                                           |
| `chore/`   | Releases, dependency bumps, infrastructure                   |
| `test/`    | Tests only                                                   |

### Commit and push

```bash
git add <specific files>                            # prefer over `git add -A`
git commit -m "type(scope): summary"
git push -u origin <branch>                         # -u sets upstream on first push
```

Commit-message format (matches existing log):

```
type(scope): short summary in present tense

Optional body explaining the WHY, not the WHAT.
The diff already shows what changed.
```

### Open a PR

```bash
gh pr create --fill                                 # uses commit message
# or with full body:
gh pr create --title "..." --body "..."
```

Reviewers expect:
- Tests pass (see "Before opening a PR" below)
- CHANGELOG entry if user-facing
- Translation keys for any new user-facing strings (all 9 languages)

### Update your branch with latest `main`

```bash
git fetch origin
git rebase origin/main                              # preferred over merge for feature branches
git push --force-with-lease                         # safer than --force
```

**Never** `git push --force` (or `--force-with-lease`) to `main` itself. Only to your own feature branches.

---

## Before opening a PR

Run from the app subdirectory (`MarineSABRES_SES_Shiny\`):

```bash
# 1. Pre-deployment validation
Rscript deployment/pre-deploy-check.R

# 2. Translation validation
Rscript scripts/translation_workflow.R check

# 3. Full test suite
Rscript -e "testthat::test_dir('tests/testthat')"

# 4. Smoke-run the app
Rscript run_app.R
# Click around in the browser, then Ctrl+C
```

If any of these fail, fix before pushing.

For quick iteration during development, run only the test file affected:

```bash
Rscript -e "testthat::test_file('tests/testthat/test-pims-module.R')"
```

---

## Red flags to avoid

| Pattern                                              | Why it bites you                                                                 |
|------------------------------------------------------|----------------------------------------------------------------------------------|
| `git push --force` to `main`                         | Destroys remote history; loses other people's commits; cannot be undone          |
| `git commit --no-verify`                             | Skips pre-commit hooks that catch i18n + lint issues before CI does              |
| Editing `translations/_merged_translations.json`     | Auto-generated; edits get overwritten on next merge step. Edit the source files in `translations/common/` or `translations/modules/` |
| Working in OneDrive-synced folder                    | Corrupts `.git/` on multi-device sync                                            |
| `git add -A` without reviewing                       | Easily commits secrets (`.env`, `credentials.json`) or large binaries           |
| Storing translated text as `selectInput` values      | Silent classification bugs in non-English sessions (see ADR-11 in [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)) |
| Calling `ns(...)` in server scope without `ns <- session$ns` first | Runtime error when the observer fires (see `analysis_leverage.R:129` fix in v1.11.3) |
| Reading a `reactiveVal` inside `emit_*` without `isolate()` | Function becomes uncallable outside reactive contexts; observers self-fire (see ADR-13) |

---

## Standard module conventions (cheat-sheet form)

Full reference: [CLAUDE.md](CLAUDE.md) § Module Conventions.

```r
# UI function — usei18n FIRST, then ns
my_module_ui <- function(id, i18n) {
  tryCatch(shiny.i18n::usei18n(i18n$translator %||% i18n), error = function(e) NULL)
  ns <- NS(id)
  # ...
}

# Server function — conventional parameter order
my_module_server <- function(id, project_data_reactive, i18n, ..., event_bus = NULL) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns                                   # IMPORTANT — needed if ns() used in server
    # ...
  })
}
```

User-facing text always uses `i18n$t(...)`. Internal IDs, file paths, and log messages do not.

Error handling uses the canonical pattern:

```r
tryCatch({
  # risky operation
}, error = function(e) {
  debug_log(paste("Operation failed:", e$message), "ERROR")
  showNotification(
    format_user_error(e, i18n = i18n, context_key = "common.messages.context_saving_project"),
    type = "error"
  )
})
```

`context_key` (i18n key, gets translated) is preferred over the deprecated raw-English `context` parameter.

---

## Working with Claude Code in this repo

- Always launch Claude Code from `C:\Users\arturas.baziukas\projects\SESTool\MarineSABRES_SES_Shiny\`, not from the repo root. The app subdirectory is where `CLAUDE.md` lives and where most edits happen.
- Local Claude settings (`.claude/settings.local.json`) accumulate permissions over time. They are gitignored and local to your machine.
- If you ever see "Failed with non-blocking status code" hook errors about `.remember/logs/hook-errors.log`, that directory has been deleted; recreate with `mkdir -p .remember/logs && touch .remember/logs/hook-errors.log` (see also the upstream note in the v1.11.3 commit log).
- The `superpowers:dispatching-parallel-agents` skill makes per-module fan-out audits cheap — useful for any sweep across many modules.

---

## Cross-device sync (without OneDrive)

If you need this repo on multiple machines:

1. Push your branch from device A: `git push -u origin <branch>`
2. On device B, in a separate clone: `git fetch && git checkout <branch>`
3. After merging the PR: `git checkout main && git pull` on each device

The remote at `github.com/razinkele/SESTool` is the source of truth. Both devices have their own `.git/` directories and never collide.

---

## When things go wrong

| Symptom                                                            | First thing to try                                                              |
|--------------------------------------------------------------------|---------------------------------------------------------------------------------|
| `fatal: not a git repository`                                      | You're in the wrong directory. `cd` to repo root.                                |
| Files renamed with `-laguna-safeBackup-XXXX` suffixes in `.git/`   | OneDrive corrupted the repo. Clone fresh elsewhere; don't try to repair.        |
| Tests fail after pulling main                                      | Re-source `global.R` or restart R. Could be stale package state.                |
| `Rscript run_app.R` hangs                                          | `Sys.setenv(MARINESABRES_DEBUG = "TRUE")` then re-run to see where.             |
| Translation validation fails on a key you didn't touch             | Someone else added a key. Pull main first.                                      |
| Merge conflict in `_merged_translations.json`                      | Delete the file. It regenerates from sources via `translation_loader.R`.        |

---

*Last updated: v1.11.3 — 2026-05-16*
