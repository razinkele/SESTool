#!/bin/bash
# ============================================================================
# MarineSABRES SES Tool - Deployment Status Checker
# ============================================================================
#
# This script checks if deployment actually updated the files on the server
# and helps diagnose why old versions might be served
#
# Usage:
#   sudo ./check-deployment-status.sh
#
# ============================================================================

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "================================================================================"
echo " MarineSABRES Deployment Status Check"
echo "================================================================================"
echo ""

# Get paths
SOURCE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DEPLOY_DIR="/srv/shiny-server/marinesabres"

echo "Source directory: $SOURCE_DIR"
echo "Deploy directory: $DEPLOY_DIR"
echo ""

# Check 1: Shiny Server Status
echo "================================================================================"
echo "[1] Shiny Server Status"
echo "================================================================================"

if systemctl is-active --quiet shiny-server; then
    echo -e "${GREEN}✓${NC} Shiny Server is running"
else
    echo -e "${RED}✗${NC} Shiny Server is NOT running"
    echo "   Run: sudo systemctl start shiny-server"
fi

# Check for running R processes
echo ""
echo "Active Shiny R processes:"
ps aux | grep -E "shiny.*[R]script" | grep -v grep || echo "   No active R processes found"

echo ""

# Check 2: File Timestamps
echo "================================================================================"
echo "[2] File Modification Times"
echo "================================================================================"

key_files=("app.R" "global.R" "functions/translation_loader.R" "scripts/reverse_key_mapping.json")

for file in "${key_files[@]}"; do
    echo ""
    echo "File: $file"

    if [ -f "$SOURCE_DIR/$file" ]; then
        source_time=$(stat -c '%y' "$SOURCE_DIR/$file" 2>/dev/null || stat -f '%Sm' "$SOURCE_DIR/$file" 2>/dev/null)
        echo "   Source:   $source_time"
    else
        echo -e "   Source:   ${RED}NOT FOUND${NC}"
    fi

    if [ -f "$DEPLOY_DIR/$file" ]; then
        deploy_time=$(stat -c '%y' "$DEPLOY_DIR/$file" 2>/dev/null || stat -f '%Sm' "$DEPLOY_DIR/$file" 2>/dev/null)
        echo "   Deployed: $deploy_time"

        # Compare modification times
        if [ -f "$SOURCE_DIR/$file" ]; then
            source_epoch=$(stat -c '%Y' "$SOURCE_DIR/$file" 2>/dev/null || stat -f '%m' "$SOURCE_DIR/$file" 2>/dev/null)
            deploy_epoch=$(stat -c '%Y' "$DEPLOY_DIR/$file" 2>/dev/null || stat -f '%m' "$DEPLOY_DIR/$file" 2>/dev/null)

            if [ "$deploy_epoch" -lt "$source_epoch" ]; then
                echo -e "   ${YELLOW}⚠ Deployed version is OLDER than source${NC}"
            elif [ "$deploy_epoch" -gt "$source_epoch" ]; then
                echo -e "   ${GREEN}✓ Deployed version is newer${NC}"
            else
                echo -e "   ${GREEN}✓ Timestamps match${NC}"
            fi
        fi
    else
        echo -e "   Deployed: ${RED}NOT FOUND${NC}"
    fi
done

# Check 3: Translation System
echo ""
echo "================================================================================"
echo "[3] Translation System"
echo "================================================================================"

echo ""
echo "Source translation files:"
source_count=$(find "$SOURCE_DIR/translations" -type f -name "*.json" ! -name "*backup*" ! -name "translation.json" 2>/dev/null | wc -l)
echo "   Found $source_count modular translation files"

echo ""
echo "Deployed translation files:"
if [ -d "$DEPLOY_DIR/translations" ]; then
    deploy_count=$(find "$DEPLOY_DIR/translations" -type f -name "*.json" ! -name "*backup*" ! -name "translation.json" 2>/dev/null | wc -l)
    echo "   Found $deploy_count modular translation files"

    if [ "$deploy_count" -ne "$source_count" ]; then
        echo -e "   ${YELLOW}⚠ File count mismatch!${NC}"
    fi
else
    echo -e "   ${RED}✗ Translations directory not found${NC}"
fi

# Check 4: Scripts Directory
echo ""
echo "================================================================================"
echo "[4] Scripts Directory (Required for Translation System)"
echo "================================================================================"

if [ -d "$DEPLOY_DIR/scripts" ]; then
    echo -e "${GREEN}✓${NC} Scripts directory exists"
    if [ -f "$DEPLOY_DIR/scripts/reverse_key_mapping.json" ]; then
        echo -e "${GREEN}✓${NC} reverse_key_mapping.json exists (deprecated but present)"
    else
        echo -e "${GREEN}✓${NC} reverse_key_mapping.json not present (deprecated feature removed)"
    fi
else
    echo -e "${YELLOW}⚠${NC} Scripts directory not found"
    echo "   This may cause issues if deployment expects it"
fi

# Check 5: Shiny Server Cache
echo ""
echo "================================================================================"
echo "[5] Shiny Server Cache"
echo "================================================================================"

cache_locations=(
    "/var/lib/shiny-server/bookmarks"
    "/tmp/shiny-server"
    "$HOME/.cache/shiny"
)

for cache_dir in "${cache_locations[@]}"; do
    if [ -d "$cache_dir" ]; then
        cache_size=$(du -sh "$cache_dir" 2>/dev/null | cut -f1)
        echo "   $cache_dir: $cache_size"
    fi
done

# Check 6: Application Logs
echo ""
echo "================================================================================"
echo "[6] Recent Application Logs (Last 20 lines)"
echo "================================================================================"

if [ -f "/var/log/shiny-server/marinesabres.log" ]; then
    echo ""
    tail -20 "/var/log/shiny-server/marinesabres.log"
elif [ -f "/var/log/shiny-server.log" ]; then
    echo ""
    echo "Looking for marinesabres entries in main log:"
    grep -i "marinesabres" "/var/log/shiny-server.log" | tail -20
else
    echo -e "${YELLOW}⚠${NC} No log files found"
fi

# Check 7: VERSION comparison
echo ""
echo "================================================================================"
echo "[7] Version Information"
echo "================================================================================"

echo ""
if [ -f "$SOURCE_DIR/VERSION" ]; then
    source_version=$(cat "$SOURCE_DIR/VERSION")
    echo "Source VERSION: $source_version"
else
    echo "Source VERSION: NOT FOUND"
fi

if [ -f "$DEPLOY_DIR/VERSION" ]; then
    deploy_version=$(cat "$DEPLOY_DIR/VERSION")
    echo "Deployed VERSION: $deploy_version"

    if [ -f "$SOURCE_DIR/VERSION" ] && [ "$source_version" != "$deploy_version" ]; then
        echo -e "${YELLOW}⚠ VERSION MISMATCH!${NC}"
    fi
else
    echo "Deployed VERSION: NOT FOUND"
fi

# Summary and Recommendations
echo ""
echo "================================================================================"
echo " Recommendations"
echo "================================================================================"
echo ""

echo "If the server is still serving old version, try these steps in order:"
echo ""
echo "1. Force kill all Shiny R processes:"
echo "   sudo pkill -9 -f 'shiny.*R'"
echo ""
echo "2. Clear Shiny Server cache:"
echo "   sudo rm -rf /var/lib/shiny-server/bookmarks/*"
echo "   sudo rm -rf /tmp/shiny-server/*"
echo ""
echo "3. Restart Shiny Server completely:"
echo "   sudo systemctl stop shiny-server"
echo "   sleep 5"
echo "   sudo systemctl start shiny-server"
echo ""
echo "4. Clear browser cache (Ctrl+Shift+R or Cmd+Shift+R)"
echo ""
echo "5. If still not working, check application logs:"
echo "   sudo tail -f /var/log/shiny-server/marinesabres.log"
echo ""
