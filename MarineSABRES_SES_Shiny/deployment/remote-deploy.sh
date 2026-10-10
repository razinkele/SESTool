#!/bin/bash
# ============================================================================
# MarineSABRES Remote Deployment v3.1 (git archive + scp)
# ============================================================================
#
# Deploys to laguna.ku.lt using tar + scp (no rsync dependency).
# This is the bash version for Linux/Mac. Windows users: use deploy-remote.ps1
#
# Ownership model: razinka:shiny
#   - razinka owns the files (can deploy without sudo)
#   - shiny group gives Shiny Server read access
#   - Only systemctl restart requires sudo
#
# Usage:
#   ./remote-deploy.sh [--dry-run] [--exclude-models] [--force]
#
# Version: 3.0
# Updated: 2026-02-24
#
# ============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

REMOTE_HOST="laguna.ku.lt"
REMOTE_USER="razinka"
REMOTE_TARGET="/srv/shiny-server/marinesabres"
REMOTE_OWNER="razinka"
REMOTE_GROUP="shiny"
TAR_FILENAME="marinesabres-deploy.tar.gz"

DRY_RUN=false
EXCLUDE_MODELS=false
FORCE_DEPLOY=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run) DRY_RUN=true; shift ;;
        --exclude-models) EXCLUDE_MODELS=true; shift ;;
        --force) FORCE_DEPLOY=true; shift ;;
        --help|-h)
            echo "Usage: ./remote-deploy.sh [--dry-run] [--exclude-models] [--force]"
            echo ""
            echo "Options:"
            echo "  --dry-run         List files without uploading"
            echo "  --exclude-models  Exclude SESModels directory"
            echo "  --force           Skip confirmation prompts"
            exit 0
            ;;
        *) shift ;;
    esac
done

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TAR_PATH="/tmp/$TAR_FILENAME"

echo -e "${CYAN}=== MarineSABRES Remote Deployment v3.1 (git archive + scp) ===${NC}"
echo "Local:     $APP_DIR"
echo "Remote:    $REMOTE_USER@$REMOTE_HOST:$REMOTE_TARGET"
echo "Ownership: $REMOTE_OWNER:$REMOTE_GROUP"
echo "Version:   $(cat "$APP_DIR/VERSION" 2>/dev/null || echo 'unknown')"
echo ""

# Archive ONLY committed (tracked) files via `git archive`, exactly like
# deploy-remote.ps1 (review 2026-10-07 N8). The old working-tree tar with a
# hand-maintained exclude list shipped untracked user exports, bundles and
# scratch files -- the failure class behind the 2026-05-30 outage. Paths that
# must not reach the server are excluded via .gitattributes export-ignore.
REPO_ROOT="$(git -C "$APP_DIR" rev-parse --show-toplevel 2>/dev/null || true)"
if [ -z "$REPO_ROOT" ]; then
    echo -e "${RED}[ERROR]${NC} $APP_DIR is not inside a git repository; this deploy ships committed files via git archive"
    exit 1
fi
APP_PREFIX="$(git -C "$APP_DIR" rev-parse --show-prefix 2>/dev/null || true)"
APP_PREFIX="${APP_PREFIX%/}"
TREEISH="HEAD${APP_PREFIX:+:$APP_PREFIX}"
# Archive HEAD restricted to the app PATH (not the HEAD:<prefix> subtree): git
# only honours the app's .gitattributes export-ignore rules when entries keep
# their repo-relative prefix; it is stripped again on extraction.
if [ -n "$APP_PREFIX" ]; then STRIP=$(echo "$APP_PREFIX" | awk -F/ '{print NF}'); else STRIP=0; fi

echo -e "${BLUE}==>${NC} Creating deployment archive from committed files ($TREEISH)..."
rm -f "$TAR_PATH"
if [ "$EXCLUDE_MODELS" = true ]; then
    echo -e "${YELLOW}[NOTE]${NC} SESModels directory will be excluded"
    TOPS=$(git -C "$REPO_ROOT" ls-tree --name-only "$TREEISH" | grep -vx 'SESModels' | sed "s|^|${APP_PREFIX:+$APP_PREFIX/}|")
    # shellcheck disable=SC2086
    git -C "$REPO_ROOT" archive --format=tar.gz -o "$TAR_PATH" HEAD -- $TOPS
elif [ -n "$APP_PREFIX" ]; then
    git -C "$REPO_ROOT" archive --format=tar.gz -o "$TAR_PATH" HEAD -- "$APP_PREFIX"
else
    git -C "$REPO_ROOT" archive --format=tar.gz -o "$TAR_PATH" HEAD
fi

TAR_SIZE=$(du -h "$TAR_PATH" | cut -f1)
echo -e "${GREEN}[OK]${NC} Archive created: $TAR_PATH ($TAR_SIZE, tracked files only)"

# Dry run — list contents and exit (no SSH needed, so it works offline)
if [ "$DRY_RUN" = true ]; then
    echo ""
    echo -e "${BLUE}==>${NC} Archive contents (DRY RUN):"
    tar -tzf "$TAR_PATH"
    echo ""
    echo -e "${YELLOW}DRY RUN - no files uploaded${NC}"
    echo "  Archive size: $TAR_SIZE"
    rm -f "$TAR_PATH"
    exit 0
fi

# Test SSH
echo -e "${BLUE}==>${NC} Testing SSH..."
if ssh -o ConnectTimeout=10 -o BatchMode=yes "$REMOTE_USER@$REMOTE_HOST" "echo OK" >/dev/null 2>&1; then
    echo -e "${GREEN}[OK]${NC} SSH connected"
else
    echo -e "${RED}[ERROR]${NC} SSH failed. Check your SSH key for $REMOTE_USER@$REMOTE_HOST"
    rm -f "$TAR_PATH"
    exit 1
fi

# Confirmation
if [ "$FORCE_DEPLOY" != true ]; then
    echo ""
    echo -e "${YELLOW}Ready to deploy $TAR_SIZE to $REMOTE_HOST${NC}"
    read -p "Continue? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${RED}Deployment cancelled${NC}"
        rm -f "$TAR_PATH"
        exit 1
    fi
fi

# Upload via scp
echo -e "${BLUE}==>${NC} Uploading archive via scp..."
if ! scp "$TAR_PATH" "$REMOTE_USER@$REMOTE_HOST:/tmp/$TAR_FILENAME"; then
    echo -e "${RED}[FAIL]${NC} scp upload failed — aborting deploy"
    rm -f "$TAR_PATH"
    exit 1
fi
echo -e "${GREEN}[OK]${NC} Archive uploaded"

# Deploy on remote server
echo ""
echo -e "${BLUE}==>${NC} Deploying on remote server..."
PRESERVE_TGZ="/tmp/marinesabres-preserve-$$.tgz"
ssh -t "$REMOTE_USER@$REMOTE_HOST" "\
    set -e && \
    echo '==> Preserving accumulated user data (ml_*, *_backup.json, user_feedback_log*.ndjson)...' && \
    (cd $REMOTE_TARGET && \
       tar czf $PRESERVE_TGZ \
         \$(find data -maxdepth 2 \\( -name 'ml_*' -o -name '*_backup.json' -o -name 'user_feedback_log*.ndjson' \\) 2>/dev/null | tr '\\n' ' ') \
         2>/dev/null) || echo '   (no preserve files found, continuing)' && \
    echo '==> Clearing target directory...' && \
    rm -rf $REMOTE_TARGET/* && \
    echo '==> Extracting archive...' && \
    tar -xzf /tmp/$TAR_FILENAME --strip-components=$STRIP -C $REMOTE_TARGET/ && \
    ( (cd $REMOTE_TARGET && find tests .claude DTU -depth -type d -empty -delete 2>/dev/null) || true ) && \
    echo '==> Verifying extraction...' && \
    EXTRACTED_COUNT=\$(find $REMOTE_TARGET -type f | wc -l) && \
    if [ \$EXTRACTED_COUNT -lt 100 ]; then echo 'FAIL: only' \$EXTRACTED_COUNT 'files extracted (expected >=100)'; exit 1; fi && \
    echo '==> Extracted' \$EXTRACTED_COUNT 'files' && \
    echo '==> Restoring preserved user data...' && \
    (test -s $PRESERVE_TGZ && tar xzf $PRESERVE_TGZ -C $REMOTE_TARGET/ && \
       echo '   Restored:' && tar tzf $PRESERVE_TGZ) || echo '   (nothing to restore)' && \
    rm -f $PRESERVE_TGZ && \
    echo '==> Setting ownership ($REMOTE_OWNER:$REMOTE_GROUP)...' && \
    chown -R $REMOTE_OWNER:$REMOTE_GROUP $REMOTE_TARGET && \
    chmod -R 755 $REMOTE_TARGET && \
    (rm -f $REMOTE_TARGET/translations/_merged_translations.json 2>/dev/null || true) && \
    chmod g+w $REMOTE_TARGET/translations && \
    mkdir -p $REMOTE_TARGET/www/reports && chmod g+w $REMOTE_TARGET/www/reports && \
    chmod 775 $REMOTE_TARGET/data && \
    (find $REMOTE_TARGET/data -maxdepth 1 -type f \\( -name 'ml_*' -o -name 'user_feedback_log*.ndjson' \\) -exec chmod g+w {} + 2>/dev/null || true) && \
    echo '==> Cleaning up...' && \
    rm -f /tmp/$TAR_FILENAME && \
    echo '==> Restarting Shiny Server...' && \
    (sudo systemctl restart shiny-server || (touch $REMOTE_TARGET/restart.txt && echo '  sudo restart unavailable -- touched restart.txt (app respawns on next request)')) && \
    sleep 2 && \
    echo '' && \
    echo 'Version:' && cat $REMOTE_TARGET/VERSION 2>/dev/null && \
    echo 'Ownership:' && stat -c '%U:%G' $REMOTE_TARGET && \
    echo 'Shiny Server:' && systemctl is-active shiny-server"

# Cleanup local tar
rm -f "$TAR_PATH"

echo ""
echo -e "${GREEN}=== Deployment Complete ===${NC}"
echo "URL: http://$REMOTE_HOST:3838/marinesabres/"
