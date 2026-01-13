#!/bin/bash
# MarineSABRES Remote Deployment v2.0

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

REMOTE_HOST="laguna.ku.lt"
REMOTE_USER="razinka"
REMOTE_TARGET="/srv/shiny-server/marinesabres"
STAGING_DIR="marinesabres-deploy-staging"

DRY_RUN=false
EXCLUDE_MODELS=false
FORCE_DEPLOY=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run) DRY_RUN=true; shift ;;
        --exclude-models) EXCLUDE_MODELS=true; shift ;;
        --force) FORCE_DEPLOY=true; shift ;;
        *) shift ;;
    esac
done

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo -e "${CYAN}=== MarineSABRES Remote Deployment v2.0 ===${NC}"
echo "Local: $APP_DIR"
echo "Remote: $REMOTE_USER@$REMOTE_HOST:$REMOTE_TARGET"
echo "Version: $(cat "$APP_DIR/VERSION" 2>/dev/null)"
echo ""

# Test SSH
echo -e "${BLUE}==>${NC} Testing SSH..."
if ssh -o ConnectTimeout=10 -o BatchMode=yes "$REMOTE_USER@$REMOTE_HOST" "echo OK" >/dev/null 2>&1; then
    echo -e "${GREEN}[OK]${NC} SSH connected"
else
    echo -e "${RED}[ERROR]${NC} SSH failed"
    exit 1
fi

# Create staging
echo -e "${BLUE}==>${NC} Creating staging directory..."
ssh "$REMOTE_USER@$REMOTE_HOST" "rm -rf ~/$STAGING_DIR && mkdir -p ~/$STAGING_DIR"

# Upload files
echo -e "${BLUE}==>${NC} Uploading files..."
EXCLUDES="--exclude=.git/ --exclude=.claude/ --exclude=.Rhistory --exclude=*.log --exclude=*.tmp --exclude=.Rproj.user/ --exclude=*.Rproj"
if [ "$EXCLUDE_MODELS" = true ]; then
    EXCLUDES="$EXCLUDES --exclude=SESModels/"
fi

if [ "$DRY_RUN" = true ]; then
    rsync -avz --dry-run --delete $EXCLUDES "$APP_DIR/" "$REMOTE_USER@$REMOTE_HOST:~/$STAGING_DIR/"
    echo -e "${YELLOW}DRY RUN - no changes made${NC}"
    exit 0
fi

rsync -avz --delete $EXCLUDES "$APP_DIR/" "$REMOTE_USER@$REMOTE_HOST:~/$STAGING_DIR/"

# Deploy with sudo
echo ""
echo -e "${BLUE}==>${NC} Deploying (sudo password required)..."
ssh -t "$REMOTE_USER@$REMOTE_HOST" "sudo rm -rf $REMOTE_TARGET/* && sudo cp -r ~/$STAGING_DIR/* $REMOTE_TARGET/ && sudo chown -R shiny:shiny $REMOTE_TARGET && sudo chmod -R 755 $REMOTE_TARGET && sudo systemctl restart shiny-server && sleep 2 && rm -rf ~/$STAGING_DIR && echo '' && echo 'Version:' && cat $REMOTE_TARGET/VERSION && echo 'Status:' && systemctl is-active shiny-server"

echo ""
echo -e "${GREEN}=== Deployment Complete ===${NC}"
echo "URL: http://$REMOTE_HOST:3838/marinesabres/"
