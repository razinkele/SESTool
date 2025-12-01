#!/bin/bash
# ============================================================================
# MarineSABRES SES Tool - Force Restart Shiny Server
# ============================================================================
#
# This script forcefully restarts Shiny Server and clears all caches
# Use this when the server is serving old versions of the app
#
# Usage:
#   sudo ./force-restart-shiny.sh
#
# ============================================================================

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}ERROR: This script must be run as root${NC}"
   echo "Please run: sudo ./force-restart-shiny.sh"
   exit 1
fi

echo "================================================================================"
echo " MarineSABRES - Force Restart Shiny Server"
echo "================================================================================"
echo ""

# Step 1: Kill all Shiny R processes
echo -e "${BLUE}==>${NC} Killing all Shiny R processes..."
pkill -9 -f 'shiny.*R' 2>/dev/null || echo "   No processes to kill"
sleep 2
echo -e "${GREEN}✓${NC} Done"

# Step 2: Stop Shiny Server service
echo ""
echo -e "${BLUE}==>${NC} Stopping Shiny Server service..."
systemctl stop shiny-server
sleep 3
echo -e "${GREEN}✓${NC} Done"

# Step 3: Clear Shiny Server cache
echo ""
echo -e "${BLUE}==>${NC} Clearing Shiny Server cache..."

cache_locations=(
    "/var/lib/shiny-server/bookmarks"
    "/tmp/shiny-server"
)

for cache_dir in "${cache_locations[@]}"; do
    if [ -d "$cache_dir" ]; then
        echo "   Clearing $cache_dir..."
        rm -rf "$cache_dir"/*
    fi
done
echo -e "${GREEN}✓${NC} Done"

# Step 4: Clear app-specific temporary files
echo ""
echo -e "${BLUE}==>${NC} Clearing app-specific temporary files..."
app_dir="/srv/shiny-server/marinesabres"
if [ -d "$app_dir" ]; then
    # Remove any .Rdata or .RDS temp files
    find "$app_dir" -name ".Rdata" -delete 2>/dev/null || true
    find "$app_dir" -name "*.rds" -path "*/tmp/*" -delete 2>/dev/null || true

    # Remove any _merged_translations.json if it's stale
    if [ -f "$app_dir/translations/_merged_translations.json" ]; then
        echo "   Removing potentially stale merged translations..."
        rm -f "$app_dir/translations/_merged_translations.json"
    fi
fi
echo -e "${GREEN}✓${NC} Done"

# Step 5: Start Shiny Server service
echo ""
echo -e "${BLUE}==>${NC} Starting Shiny Server service..."
systemctl start shiny-server
sleep 5
echo -e "${GREEN}✓${NC} Done"

# Step 6: Check status
echo ""
echo -e "${BLUE}==>${NC} Checking Shiny Server status..."
if systemctl is-active --quiet shiny-server; then
    echo -e "${GREEN}✓${NC} Shiny Server is running"
else
    echo -e "${RED}✗${NC} Shiny Server failed to start"
    echo ""
    echo "Check logs with:"
    echo "  sudo journalctl -u shiny-server -n 50"
    exit 1
fi

# Step 7: Verify no old R processes
echo ""
echo -e "${BLUE}==>${NC} Verifying no old R processes..."
old_processes=$(ps aux | grep -E "shiny.*[R]" | grep -v grep | wc -l)
if [ "$old_processes" -eq 0 ]; then
    echo -e "${GREEN}✓${NC} No old R processes found"
else
    echo -e "${YELLOW}⚠${NC} Warning: Found $old_processes R processes still running"
fi

# Success message
echo ""
echo "================================================================================"
echo -e "${GREEN}✓${NC} Shiny Server has been forcefully restarted"
echo "================================================================================"
echo ""
echo "Next steps:"
echo "  1. Clear your browser cache (Ctrl+Shift+R or Cmd+Shift+R)"
echo "  2. Access the application: http://$(hostname -I | awk '{print $1}'):3838/marinesabres"
echo "  3. If still seeing old version, check logs:"
echo "     sudo tail -f /var/log/shiny-server/marinesabres.log"
echo ""
