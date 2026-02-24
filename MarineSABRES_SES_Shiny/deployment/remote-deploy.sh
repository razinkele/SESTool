#!/bin/bash
# ============================================================================
# MarineSABRES Remote Deployment v3.0 (tar + scp)
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

echo -e "${CYAN}=== MarineSABRES Remote Deployment v3.0 (tar + scp) ===${NC}"
echo "Local:     $APP_DIR"
echo "Remote:    $REMOTE_USER@$REMOTE_HOST:$REMOTE_TARGET"
echo "Ownership: $REMOTE_OWNER:$REMOTE_GROUP"
echo "Version:   $(cat "$APP_DIR/VERSION" 2>/dev/null || echo 'unknown')"
echo ""

# Test SSH
echo -e "${BLUE}==>${NC} Testing SSH..."
if ssh -o ConnectTimeout=10 -o BatchMode=yes "$REMOTE_USER@$REMOTE_HOST" "echo OK" >/dev/null 2>&1; then
    echo -e "${GREEN}[OK]${NC} SSH connected"
else
    echo -e "${RED}[ERROR]${NC} SSH failed. Check your SSH key for $REMOTE_USER@$REMOTE_HOST"
    exit 1
fi

# Build tar excludes
EXCLUDES=(
    --exclude=.git
    --exclude=.claude
    --exclude=.playwright-mcp
    --exclude=.Rhistory
    --exclude=.Rproj.user
    --exclude=.gitignore
    --exclude=.dockerignore
    --exclude='*.Rproj'
    --exclude='*.log'
    --exclude='*.tmp'
    --exclude=deployment
    --exclude=tests
    --exclude=DTU
    --exclude=Documents
    --exclude=CLEANUP_SCRIPT.R
    --exclude=run_ui_tests.R
    --exclude=fixture_list.txt
    --exclude=abstract.docx
    --exclude='*.png'
)

if [ "$EXCLUDE_MODELS" = true ]; then
    EXCLUDES+=(--exclude=SESModels)
    echo -e "${YELLOW}[NOTE]${NC} SESModels directory will be excluded"
fi

# Create tar archive
echo -e "${BLUE}==>${NC} Creating deployment archive..."
rm -f "$TAR_PATH"
tar -czf "$TAR_PATH" "${EXCLUDES[@]}" -C "$APP_DIR" .

TAR_SIZE=$(du -h "$TAR_PATH" | cut -f1)
echo -e "${GREEN}[OK]${NC} Archive created: $TAR_PATH ($TAR_SIZE)"

# Dry run — list contents and exit
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
scp "$TAR_PATH" "$REMOTE_USER@$REMOTE_HOST:/tmp/$TAR_FILENAME"
echo -e "${GREEN}[OK]${NC} Archive uploaded"

# Deploy on remote server
echo ""
echo -e "${BLUE}==>${NC} Deploying on remote server..."
ssh -t "$REMOTE_USER@$REMOTE_HOST" "\
    set -e && \
    echo '==> Clearing target directory...' && \
    rm -rf $REMOTE_TARGET/* && \
    echo '==> Extracting archive...' && \
    tar -xzf /tmp/$TAR_FILENAME -C $REMOTE_TARGET/ && \
    echo '==> Setting ownership ($REMOTE_OWNER:$REMOTE_GROUP)...' && \
    chown -R $REMOTE_OWNER:$REMOTE_GROUP $REMOTE_TARGET && \
    chmod -R 755 $REMOTE_TARGET && \
    rm -f $REMOTE_TARGET/translations/_merged_translations.json 2>/dev/null; \
    echo '==> Cleaning up...' && \
    rm -f /tmp/$TAR_FILENAME && \
    echo '==> Restarting Shiny Server...' && \
    sudo systemctl restart shiny-server && \
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
