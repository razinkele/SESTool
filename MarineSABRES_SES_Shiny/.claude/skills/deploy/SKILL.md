---
name: deploy
description: Deploy the MarineSABRES app to production (laguna.ku.lt) with checks before and live verification after, using deployment/deploy-and-verify.sh. Use when the user says "deploy", asks to ship/release to laguna, or after a release PR is merged and the user agrees to deploy. Never deploy without the user's explicit go-ahead in the current conversation.
---

# Deploy to laguna (checked + verified)

**Standing rule (user, 2026-11-10): ask first.** Claude runs the deploy itself, but only after
the user has explicitly said to deploy *in the current conversation*. A merged or green
release is not permission. If unsure, ask: "1.x.y is merged, tagged and green — deploy now?"

## 1. Check (read-only, any time)
From the app directory (`MarineSABRES_SES_Shiny/`), run exactly:

    bash deployment/deploy-and-verify.sh --check

It refuses (exit 1) unless: on `main`, in sync with `origin/main`, `VERSION` has a pushed
`v<VERSION>` tag on HEAD (or HEAD differs from the tag only in deployment/, .claude/,
.github/, tests/, docs/), CI `R Tests` and `i18n validation` passed on HEAD, laguna reachable.
Uncommitted edits only warn (the deploy ships the committed tree via `git archive`).
If it fails, report the [FAIL] line; fix the cause (release, wait for CI, pull) — never bypass.

## 2. Deploy (only after the user's go-ahead)

    bash deployment/deploy-and-verify.sh

Runs the checks again, then `deploy-remote.ps1 -Force` (stdin closed), then verifies:
HTTP 200 on https://laguna.ku.lt/marinesabres/, laguna `VERSION` matches, a worker log newer
than the deploy start reports the same `Application version`, and no `Error in` /
`Execution halted` lines in it. Takes ~2–4 min — run it in the background and wait for the
notification. Exit codes: 0 deployed+verified · 1 check failed (nothing deployed) ·
2 deploy-remote.ps1 failed · 3 deployed but live verification failed (report the lines,
check `/var/log/shiny-server/marinesabres-shiny-*.log`; do not redeploy blindly).

`--verify` re-runs only the live checks (read-only).

## 3. After a verified deploy
- Browser-check what the release changed on the live site (the 1.34.2 lesson: tests miss
  host wrappers), e.g. `?language=de` for i18n releases.
- Feedback entries fixed by this release: re-run the feedback-triage marker with the same
  match_title/match_timestamp/status/fix_ref plus `"fix_deployed": "<VERSION>"` (re-pull the
  log first for a fresh `expect_total_lines`). See `.claude/skills/feedback-triage/SKILL.md`.
- Update the project memory (deployed version, main commit).

## Permissions (one-time, set by the user — Claude cannot grant itself these)
`.claude/settings.local.json` needs `Bash(bash deployment/deploy-and-verify.sh)`,
`… --check` and `… --verify` in `permissions.allow`, plus an `autoMode.allow` entry
(with `"$defaults"`) stating the ask-first rule. Without them the auto-mode classifier
blocks the production deploy; then hand the command to the user to run with `!`.
