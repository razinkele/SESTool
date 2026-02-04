#!/bin/bash
# ============================================================================
# MarineSABRES SES Tool - Direct Shiny Server Deployment Script
# ============================================================================
#
# This is a standalone script that deploys directly to Shiny Server
# with built-in pre-checks. No parameters required.
#
# Usage:
#   sudo ./deploy-shiny-server.sh
#
# Version: 1.3
# App Version: 1.6.1
# Last Updated: 2026-01-07
#
# ============================================================================

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Get the absolute path to the deployment directory and app root
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DEPLOY_TARGET="/srv/shiny-server/marinesabres"

# Counters for pre-checks
pre_errors=0
pre_warnings=0
pre_passed=0

# ============================================================================
# Helper Functions
# ============================================================================

print_header() {
    echo ""
    echo -e "${CYAN}================================================================================${NC}"
    echo -e "${CYAN} $1${NC}"
    echo -e "${CYAN}================================================================================${NC}"
    echo ""
}

print_status() {
    echo -e "${BLUE}==>${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

pre_check() {
    local name=$1
    local status=$2
    local message=$3

    if [ "$status" == "PASS" ]; then
        echo -e "${GREEN}✓${NC} $name"
        pre_passed=$((pre_passed + 1))
    elif [ "$status" == "WARN" ]; then
        echo -e "${YELLOW}⚠${NC} $name: $message"
        pre_warnings=$((pre_warnings + 1))
    else
        echo -e "${RED}✗${NC} $name: $message"
        pre_errors=$((pre_errors + 1))
    fi
}

# ============================================================================
# Script Start
# ============================================================================

clear
echo ""
echo -e "${CYAN}================================================================================${NC}"
echo -e "${CYAN}     MarineSABRES SES Tool - Direct Shiny Server Deployment${NC}"
echo -e "${CYAN}================================================================================${NC}"
echo ""
echo "  App Directory:    $APP_DIR"
echo "  Deploy Target:    $DEPLOY_TARGET"
echo "  App Version:      $(cat "$APP_DIR/VERSION" 2>/dev/null || echo 'Unknown')"
echo ""

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    print_error "This script must be run as root (sudo)"
    echo ""
    echo "Usage: sudo ./deploy-shiny-server.sh"
    exit 1
fi

# ============================================================================
# PHASE 1: PRE-DEPLOYMENT CHECKS
# ============================================================================

print_header "PHASE 1: Pre-Deployment Checks"

# --- Check 1.1: Required Files ---
print_status "Checking required files..."

required_files=(
    "app.R"
    "global.R"
    "run_app.R"
    "constants.R"
    "io.R"
    "utils.R"
    "VERSION"
    "VERSION_INFO.json"
    "version_manager.R"
    "functions/translation_loader.R"
)

all_files_exist=true
for file in "${required_files[@]}"; do
    if [ -f "$APP_DIR/$file" ]; then
        :  # File exists, continue
    else
        pre_check "File: $file" "ERROR" "Not found"
        all_files_exist=false
    fi
done

if $all_files_exist; then
    pre_check "All required files present (${#required_files[@]} files)" "PASS"
fi

# --- Check 1.2: Required Directories ---
print_status "Checking required directories..."

required_dirs=("modules" "functions" "server" "www" "data" "translations")

all_dirs_exist=true
for dir in "${required_dirs[@]}"; do
    if [ -d "$APP_DIR/$dir" ]; then
        :  # Directory exists
    else
        pre_check "Directory: $dir" "ERROR" "Not found"
        all_dirs_exist=false
    fi
done

if $all_dirs_exist; then
    pre_check "All required directories present (${#required_dirs[@]} dirs)" "PASS"
fi

# --- Check 1.3: Translation System ---
print_status "Checking modular translation system..."

translation_subdirs=("common" "modules" "ui" "data")
all_trans_dirs=true

for subdir in "${translation_subdirs[@]}"; do
    if [ ! -d "$APP_DIR/translations/$subdir" ]; then
        pre_check "Translation subdir: $subdir" "ERROR" "Not found"
        all_trans_dirs=false
    fi
done

if $all_trans_dirs; then
    trans_count=$(find "$APP_DIR/translations" -type f -name "*.json" ! -name "*backup*" ! -name "_merged*" 2>/dev/null | wc -l)
    pre_check "Modular translation system ($trans_count JSON files)" "PASS"
fi

# --- Check 1.4: SES Templates ---
print_status "Checking SES template files..."

template_count=$(find "$APP_DIR/data" -name "*_SES_Template.json" 2>/dev/null | wc -l)
if [ "$template_count" -gt 0 ]; then
    pre_check "SES templates found ($template_count templates)" "PASS"
else
    pre_check "SES templates" "ERROR" "No template files found"
fi

# --- Check 1.5: R Syntax Validation ---
print_status "Validating R syntax..."

if command -v Rscript &> /dev/null; then
    syntax_errors=0
    r_files=("app.R" "global.R" "constants.R" "io.R" "utils.R")

    for file in "${r_files[@]}"; do
        if [ -f "$APP_DIR/$file" ]; then
            if ! Rscript -e "parse('$APP_DIR/$file')" &>/dev/null; then
                pre_check "Syntax: $file" "ERROR" "Parse error"
                syntax_errors=$((syntax_errors + 1))
            fi
        fi
    done

    if [ $syntax_errors -eq 0 ]; then
        pre_check "R syntax validation (${#r_files[@]} files)" "PASS"
    fi
else
    pre_check "R syntax validation" "WARN" "Rscript not available"
fi

# --- Check 1.6: Shiny Server Status ---
print_status "Checking Shiny Server..."

if systemctl is-active --quiet shiny-server 2>/dev/null; then
    pre_check "Shiny Server is running" "PASS"
else
    pre_check "Shiny Server" "WARN" "Not running (will attempt to start)"
fi

# --- Check 1.7: Disk Space ---
print_status "Checking disk space..."

if [ -d "/srv/shiny-server" ]; then
    disk_usage=$(df -h /srv/shiny-server | tail -1 | awk '{print $5}' | sed 's/%//')
    if [ "$disk_usage" -lt 90 ]; then
        pre_check "Disk space (${disk_usage}% used)" "PASS"
    else
        pre_check "Disk space" "WARN" "${disk_usage}% used"
    fi
else
    pre_check "Disk space" "WARN" "Target directory parent doesn't exist"
fi

# --- Pre-Check Summary ---
echo ""
echo "--------------------------------------------------------------------------------"
echo "Pre-Check Summary: $pre_passed passed, $pre_warnings warnings, $pre_errors errors"
echo "--------------------------------------------------------------------------------"

if [ $pre_errors -gt 0 ]; then
    echo ""
    print_error "Pre-deployment checks failed with $pre_errors error(s)"
    echo "Please fix the errors above before deploying."
    exit 1
fi

if [ $pre_warnings -gt 0 ]; then
    echo ""
    print_warning "Pre-deployment checks passed with $pre_warnings warning(s)"
    read -p "Continue with deployment? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_error "Deployment cancelled by user"
        exit 1
    fi
else
    echo ""
    print_success "All pre-deployment checks passed!"
fi

# ============================================================================
# PHASE 2: STOP SERVICES AND CLEAR CACHE
# ============================================================================

print_header "PHASE 2: Preparing for Deployment"

# --- Stop Shiny Server ---
print_status "Stopping Shiny Server..."
systemctl stop shiny-server 2>/dev/null || true
sleep 2
print_success "Shiny Server stopped"

# --- Kill any running R processes ---
print_status "Killing any running Shiny R processes..."
pkill -9 -f 'marinesabres.*R' 2>/dev/null || true
pkill -9 -f 'shiny.*R' 2>/dev/null || true
sleep 2
print_success "R processes terminated"

# --- Clear caches ---
print_status "Clearing Shiny Server caches..."
rm -rf /var/lib/shiny-server/bookmarks/* 2>/dev/null || true
rm -rf /tmp/shiny-server/* 2>/dev/null || true
print_success "Caches cleared"

# ============================================================================
# PHASE 3: DEPLOY APPLICATION FILES
# ============================================================================

print_header "PHASE 3: Deploying Application Files"

# --- Backup existing data ---
if [ -d "$DEPLOY_TARGET/data" ]; then
    print_status "Backing up existing user data..."
    mkdir -p /tmp/marinesabres-backup
    cp -r "$DEPLOY_TARGET/data" /tmp/marinesabres-backup/ 2>/dev/null || true
    print_success "Data backed up to /tmp/marinesabres-backup"
fi

# --- Create/clean deployment directory ---
print_status "Preparing deployment directory..."
mkdir -p "$DEPLOY_TARGET"
rm -rf "$DEPLOY_TARGET"/* 2>/dev/null || true
print_success "Deployment directory ready"

# --- Copy core files ---
print_status "Copying core R files..."
core_files=("app.R" "global.R" "run_app.R" "constants.R" "io.R" "utils.R" "VERSION" "VERSION_INFO.json" "version_manager.R")
for file in "${core_files[@]}"; do
    if [ -f "$APP_DIR/$file" ]; then
        cp "$APP_DIR/$file" "$DEPLOY_TARGET/"
    fi
done
print_success "Core files copied (${#core_files[@]} files)"

# --- Copy directories ---
print_status "Copying application directories..."
directories=("modules" "functions" "server" "www" "translations" "scripts" "SESModels")
for dir in "${directories[@]}"; do
    if [ -d "$APP_DIR/$dir" ]; then
        cp -r "$APP_DIR/$dir" "$DEPLOY_TARGET/"
        echo "   - $dir/"
    fi
done
print_success "Directories copied"

# --- Copy docs if exists ---
if [ -d "$APP_DIR/docs" ]; then
    print_status "Copying documentation..."
    cp -r "$APP_DIR/docs" "$DEPLOY_TARGET/"
    print_success "Documentation copied"
fi

# --- Restore or copy data ---
if [ -d "/tmp/marinesabres-backup/data" ]; then
    print_status "Restoring user data from backup..."
    cp -r /tmp/marinesabres-backup/data "$DEPLOY_TARGET/"
    rm -rf /tmp/marinesabres-backup
    print_success "User data restored"
else
    print_status "Copying data directory..."
    cp -r "$APP_DIR/data" "$DEPLOY_TARGET/"
    print_success "Data directory copied"
fi

# --- Remove any stale translation cache ---
print_status "Clearing translation cache..."
rm -f "$DEPLOY_TARGET/translations/_merged_translations.json" 2>/dev/null || true
print_success "Translation cache cleared"

# --- Set permissions ---
print_status "Setting file permissions..."
chown -R shiny:shiny "$DEPLOY_TARGET"
chmod -R 755 "$DEPLOY_TARGET"
print_success "Permissions set (owner: shiny)"

# ============================================================================
# PHASE 4: CONFIGURE AND START SHINY SERVER
# ============================================================================

print_header "PHASE 4: Starting Shiny Server"

# --- Update Shiny Server config if needed ---
if [ -f "$SCRIPT_DIR/shiny-server.conf" ]; then
    print_status "Updating Shiny Server configuration..."
    cp /etc/shiny-server/shiny-server.conf /etc/shiny-server/shiny-server.conf.backup 2>/dev/null || true
    cp "$SCRIPT_DIR/shiny-server.conf" /etc/shiny-server/shiny-server.conf
    print_success "Configuration updated (backup saved)"
fi

# --- Start Shiny Server ---
print_status "Starting Shiny Server..."
systemctl start shiny-server

# Wait for server to start
sleep 5

# --- Verify server is running ---
if systemctl is-active --quiet shiny-server; then
    print_success "Shiny Server started successfully"
else
    print_error "Shiny Server failed to start"
    echo "Check logs: sudo journalctl -u shiny-server -n 50"
    exit 1
fi

# ============================================================================
# PHASE 5: POST-DEPLOYMENT VALIDATION
# ============================================================================

print_header "PHASE 5: Post-Deployment Validation"

# --- Verify files deployed ---
print_status "Verifying deployed files..."

verify_files=("app.R" "global.R" "VERSION")
verify_pass=true
for file in "${verify_files[@]}"; do
    if [ ! -f "$DEPLOY_TARGET/$file" ]; then
        print_error "Missing: $file"
        verify_pass=false
    fi
done

if $verify_pass; then
    print_success "Core files verified"
fi

# --- Verify directories ---
verify_dirs=("modules" "functions" "server" "www" "data" "translations")
for dir in "${verify_dirs[@]}"; do
    if [ ! -d "$DEPLOY_TARGET/$dir" ]; then
        print_error "Missing directory: $dir"
        verify_pass=false
    fi
done

if $verify_pass; then
    print_success "All directories verified"
fi

# --- Check version ---
if [ -f "$DEPLOY_TARGET/VERSION" ]; then
    deployed_version=$(cat "$DEPLOY_TARGET/VERSION")
    source_version=$(cat "$APP_DIR/VERSION")
    if [ "$deployed_version" == "$source_version" ]; then
        print_success "Version verified: $deployed_version"
    else
        print_warning "Version mismatch: deployed=$deployed_version, source=$source_version"
    fi
fi

# --- Test HTTP access ---
print_status "Testing HTTP access..."
sleep 3
if command -v curl &> /dev/null; then
    response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3838/marinesabres/ 2>/dev/null || echo "000")
    if [ "$response" == "200" ]; then
        print_success "HTTP access working (status: 200)"
    elif [ "$response" == "000" ]; then
        print_warning "Could not connect (app may still be loading)"
    else
        print_warning "HTTP status: $response (app may still be initializing)"
    fi
else
    print_warning "curl not available, skipping HTTP test"
fi

# ============================================================================
# DEPLOYMENT COMPLETE
# ============================================================================

print_header "DEPLOYMENT COMPLETE"

# Get server IP
SERVER_IP=$(hostname -I 2>/dev/null | awk '{print $1}' || echo "localhost")

echo -e "${GREEN}Application deployed successfully!${NC}"
echo ""
echo "  Version:     $(cat "$DEPLOY_TARGET/VERSION" 2>/dev/null || echo 'Unknown')"
echo "  Location:    $DEPLOY_TARGET"
echo "  URL:         http://${SERVER_IP}:3838/marinesabres"
echo ""
echo -e "${YELLOW}IMPORTANT:${NC} Clear your browser cache to see the new version!"
echo "  - Chrome/Firefox: Ctrl+Shift+R (or Cmd+Shift+R on Mac)"
echo "  - Or use Incognito/Private browsing mode"
echo ""
echo "Useful commands:"
echo "  - Check status:    sudo systemctl status shiny-server"
echo "  - View logs:       sudo tail -f /var/log/shiny-server/marinesabres.log"
echo "  - Force restart:   sudo $SCRIPT_DIR/force-restart-shiny.sh"
echo "  - Validate:        sudo $SCRIPT_DIR/validate-deployment.sh"
echo ""
