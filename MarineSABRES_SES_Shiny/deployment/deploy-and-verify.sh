#!/usr/bin/env bash
# ============================================================================
# deploy-and-verify.sh — checked, verified production deploy to laguna.ku.lt
#
# Wraps deployment/deploy-remote.ps1 (which ships git HEAD via `git archive`)
# with checks before and after, so a deploy can be run non-interactively by a
# person or by Claude Code (after the user says "deploy" — see
# .claude/skills/deploy/SKILL.md). Every check either passes or stops the run.
#
# Usage (from anywhere; Git Bash on Windows):
#   bash deployment/deploy-and-verify.sh            # checks, deploy, verify
#   bash deployment/deploy-and-verify.sh --check    # checks only, no deploy
#   bash deployment/deploy-and-verify.sh --verify   # verify the live site only
#
# Exit codes: 0 = deployed and verified (or checks passed with --check)
#             1 = a check before deploying failed (nothing was deployed)
#             2 = deploy-remote.ps1 failed
#             3 = deployed, but verification of the live site failed
#
# Requires: git, gh (logged in), ssh key access to razinka@laguna.ku.lt, pwsh,
# curl. Does NOT use jq (not installed here) — JSON goes through `gh --jq`.
# ============================================================================
set -uo pipefail

REMOTE="razinka@laguna.ku.lt"
TARGET="/srv/shiny-server/marinesabres"
URL="https://laguna.ku.lt/marinesabres/"
GH_REPO="razinkele/SESTool"
REQUIRED_WORKFLOWS=("R Tests" "i18n validation")

MODE="deploy"
case "${1:-}" in
  --check)  MODE="check" ;;
  --verify) MODE="verify" ;;
  "")       ;;
  *) echo "Unknown option: $1 (use --check or --verify)"; exit 1 ;;
esac

APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO="$(git -C "$APP_DIR" rev-parse --show-toplevel)"
SSH=(ssh -n -o BatchMode=yes -o ConnectTimeout=15 "$REMOTE")

ok()   { echo "[OK]   $*"; }
warn() { echo "[WARN] $*"; }
die()  { echo "[FAIL] $1"; exit "${2:-1}"; }
step() { echo; echo "== $*"; }

VERSION="$(tr -d '[:space:]' < "$APP_DIR/VERSION")"
SHA="$(git -C "$REPO" rev-parse HEAD)"
SHORT="${SHA:0:7}"

# ---------------------------------------------------------------------------
preflight() {
  step "Checks before deploying (version $VERSION, commit $SHORT)"

  local branch
  branch="$(git -C "$REPO" branch --show-current)"
  [[ "$branch" == "main" ]] || die "on branch '$branch' — deploys ship main only"
  ok "on main"

  git -C "$REPO" fetch -q origin main --tags || die "git fetch failed"
  [[ "$SHA" == "$(git -C "$REPO" rev-parse origin/main)" ]] \
    || die "local main ($SHORT) differs from origin/main — pull or push first"
  ok "in sync with origin/main"

  # deploy-remote.ps1 ships the committed tree, so local edits are NOT deployed.
  # Only warn: an uncommitted edit may be unrelated (or work someone forgot).
  local dirty
  dirty="$(git -C "$REPO" status --porcelain --untracked-files=no -- "$APP_DIR")"
  if [[ -n "$dirty" ]]; then
    warn "uncommitted changes (not deployed):"; echo "$dirty" | sed 's/^/         /'
  else
    ok "no uncommitted changes to tracked files"
  fi

  local tag_sha
  tag_sha="$(git -C "$REPO" rev-parse -q --verify "refs/tags/v$VERSION^{commit}" 2>/dev/null || true)"
  [[ -n "$tag_sha" ]] || die "tag v$VERSION does not exist — release first (bump VERSION, tag, push)"
  git -C "$REPO" ls-remote --exit-code --tags origin "refs/tags/v$VERSION" > /dev/null \
    || die "tag v$VERSION is not pushed to origin"
  if [[ "$tag_sha" == "$SHA" ]]; then
    ok "HEAD is tagged v$VERSION (pushed)"
  else
    # Commits after the tag are allowed only if they change nothing that ships
    # (tooling, tests, docs); otherwise laguna would run unreleased code under
    # the old version number.
    local app_rel shipped
    app_rel="${APP_DIR#"$REPO"/}"
    shipped="$(git -C "$REPO" diff --name-only "$tag_sha" "$SHA" -- "$app_rel" \
      | grep -v -E "^$app_rel/(deployment|\.claude|\.github|tests|docs)/" || true)"
    [[ -z "$shipped" ]] || {
      echo "$shipped" | sed 's/^/         /'
      die "main has unreleased app changes since v$VERSION (above) — release them first"
    }
    ok "HEAD is v$VERSION plus commits that change only tooling/tests/docs"
  fi

  local wf res
  for wf in "${REQUIRED_WORKFLOWS[@]}"; do
    res="$(gh run list --repo "$GH_REPO" --commit "$SHA" --workflow "$wf" --limit 1 \
            --json status,conclusion --jq '.[0] | "\(.status) \(.conclusion)"' 2>/dev/null)"
    [[ "$res" == "completed success" ]] || die "CI '$wf' on $SHORT is '${res:-not found}' — need completed success"
    ok "CI '$wf' passed on $SHORT"
  done

  "${SSH[@]}" true 2>/dev/null || die "cannot reach $REMOTE over ssh (key auth)"
  PREV_VERSION="$("${SSH[@]}" "cat $TARGET/VERSION" 2>/dev/null | tr -d '[:space:]')"
  ok "laguna reachable; currently running ${PREV_VERSION:-unknown}"
  [[ "$PREV_VERSION" == "$VERSION" ]] && warn "laguna already reports $VERSION — this redeploys the same version"
  return 0
}

# ---------------------------------------------------------------------------
verify() {
  local since_epoch="${1:-0}"
  step "Verifying the live site"

  local code="" i
  for i in $(seq 1 12); do      # cold start after restart.txt can take ~20 s
    code="$(curl -sSL -o /dev/null -w '%{http_code}' --max-time 60 "$URL" 2>/dev/null || true)"
    [[ "$code" == "200" ]] && break
    sleep 10
  done
  [[ "$code" == "200" ]] || die "$URL returned HTTP ${code:-none} after ~2 min" 3
  ok "HTTP 200 from $URL"

  local live
  live="$("${SSH[@]}" "cat $TARGET/VERSION" 2>/dev/null | tr -d '[:space:]')"
  [[ "$live" == "$VERSION" ]] || die "laguna VERSION is '$live', expected $VERSION" 3
  ok "laguna VERSION is $VERSION"

  # Newest worker log; after a deploy it must be newer than the deploy start
  # (otherwise the app did not restart onto the new code).
  local log mtime
  log="$("${SSH[@]}" 'ls -t /var/log/shiny-server/marinesabres-shiny-*.log 2>/dev/null | head -1')"
  [[ -n "$log" ]] || die "no marinesabres worker log found on laguna" 3
  mtime="$("${SSH[@]}" "stat -c %Y '$log'")"
  if (( since_epoch > 0 && mtime < since_epoch )); then
    die "newest worker log ($log) predates this deploy — the app did not restart" 3
  fi
  ok "worker log: $log"

  local logver errors
  logver="$("${SSH[@]}" "grep -m1 -o 'Application version: [0-9.]*' '$log'" 2>/dev/null)"
  if [[ -n "$logver" ]]; then
    [[ "$logver" == "Application version: $VERSION" ]] || die "worker started '$logver', expected $VERSION" 3
    ok "worker reports $logver"
  else
    warn "worker log has no 'Application version' line yet"
  fi
  errors="$("${SSH[@]}" "grep -n -E 'Error in |Execution halted|^Error|Warning: Error|segfault' '$log' | head -20")"
  [[ -z "$errors" ]] || { echo "$errors" | sed 's/^/         /'; die "errors in the worker log" 3; }
  ok "no errors in the worker log"
}

# ---------------------------------------------------------------------------
case "$MODE" in
  verify)
    verify 0
    echo; echo "VERIFY OK — laguna runs $VERSION"; exit 0 ;;
  check)
    preflight
    echo; echo "CHECKS OK — ready to deploy $VERSION ($SHORT)"; exit 0 ;;
esac

preflight
step "Deploying $VERSION ($SHORT) with deploy-remote.ps1"
START_EPOCH="$("${SSH[@]}" 'date +%s')"
DEPLOY_LOG="$(mktemp -t marinesabres-deploy.XXXXXX)"
( cd "$APP_DIR" && pwsh -NonInteractive -File deployment/deploy-remote.ps1 -Force ) < /dev/null 2>&1 | tee "$DEPLOY_LOG"
rc=${PIPESTATUS[0]}
[[ $rc -eq 0 ]] || die "deploy-remote.ps1 exited $rc (log: $DEPLOY_LOG)" 2
grep -q "Remote deployment successful" "$DEPLOY_LOG" \
  || die "deploy-remote.ps1 exited 0 but did not report success (log: $DEPLOY_LOG)" 2
ok "deploy-remote.ps1 finished (log: $DEPLOY_LOG)"

verify "$START_EPOCH"
echo
echo "DEPLOY OK — laguna runs $VERSION (commit $SHORT, was ${PREV_VERSION:-unknown})"
