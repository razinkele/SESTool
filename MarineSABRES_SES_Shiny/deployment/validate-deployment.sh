#!/bin/bash
# ============================================================================
# MarineSABRES SES Tool - Post-Deployment Validation Script
# ============================================================================
#
# This script validates the Shiny Server deployment
# Run this after deploying to verify everything is working
#
# Usage:
#   sudo ./validate-deployment.sh
#
# ============================================================================

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "================================================================================"
echo " MarineSABRES SES Tool - Deployment Validation"
echo "================================================================================"
echo ""

# Counters
checks_passed=0
checks_failed=0
checks_warning=0

# Helper functions
print_check() {
    local name=$1
    local status=$2
    local message=$3
    
    if [ "$status" == "PASS" ]; then
        echo -e "${GREEN}✓${NC} $name"
        checks_passed=$((checks_passed + 1))
    elif [ "$status" == "WARN" ]; then
        echo -e "${YELLOW}⚠${NC} $name: $message"
        checks_warning=$((checks_warning + 1))
    else
        echo -e "${RED}✗${NC} $name: $message"
        checks_failed=$((checks_failed + 1))
    fi
}

# ============================================================================
# Check 1: Shiny Server Status
# ============================================================================
echo "[1] Checking Shiny Server Status..."

if systemctl is-active --quiet shiny-server; then
    print_check "Shiny Server running" "PASS"
else
    print_check "Shiny Server running" "FAIL" "Service not running"
fi

if systemctl is-enabled --quiet shiny-server; then
    print_check "Shiny Server enabled on boot" "PASS"
else
    print_check "Shiny Server enabled on boot" "WARN" "Service not enabled"
fi

# ============================================================================
# Check 2: Application Files
# ============================================================================
echo ""
echo "[2] Checking Application Files..."

app_dir="/srv/shiny-server/marinesabres"

if [ -d "$app_dir" ]; then
    print_check "Application directory exists" "PASS"
else
    print_check "Application directory exists" "FAIL" "Directory not found"
fi

# Core files
files=("app.R" "global.R" "run_app.R" "constants.R" "io.R" "utils.R" "VERSION" "VERSION_INFO.json" "version_manager.R")
for file in "${files[@]}"; do
    if [ -f "$app_dir/$file" ]; then
        # Don't print individual success to reduce noise
        :
    else
        print_check "File: $file" "FAIL" "File not found"
    fi
done

# Check if all files exist
all_files_exist=true
for file in "${files[@]}"; do
    if [ ! -f "$app_dir/$file" ]; then
        all_files_exist=false
        break
    fi
done

if $all_files_exist; then
    print_check "All core files present" "PASS"
fi

# Directories
dirs=("modules" "functions" "server" "www" "data" "translations" "scripts")
all_dirs_exist=true
for dir in "${dirs[@]}"; do
    if [ ! -d "$app_dir/$dir" ]; then
        print_check "Directory: $dir" "FAIL" "Directory not found"
        all_dirs_exist=false
    fi
done

if $all_dirs_exist; then
    print_check "All required directories present" "PASS"
fi

# Check translation subdirectories (modular structure)
echo ""
echo "[2c] Checking Modular Translation Structure..."

translation_subdirs=("common" "modules" "ui" "data")
all_translation_subdirs_exist=true
for subdir in "${translation_subdirs[@]}"; do
    if [ -d "$app_dir/translations/$subdir" ]; then
        print_check "Translation subdir: $subdir" "PASS"
    else
        print_check "Translation subdir: $subdir" "FAIL" "Directory not found"
        all_translation_subdirs_exist=false
    fi
done

# Check for reverse key mapping file (DEPRECATED - now optional)
if [ -f "$app_dir/scripts/reverse_key_mapping.json" ]; then
    print_check "Reverse key mapping file (deprecated)" "PASS"
    echo "   File is deprecated but still present"
else
    print_check "Reverse key mapping file (deprecated)" "PASS"
    echo "   File not present (deprecated feature removed)"
fi

# Check for modular translation files
if $all_translation_subdirs_exist; then
    translation_file_count=$(find "$app_dir/translations" -type f -name "*.json" ! -name "*backup*" ! -name "translation.json" | wc -l)
    if [ "$translation_file_count" -gt 0 ]; then
        print_check "Modular translation files" "PASS"
        echo "   Found $translation_file_count translation files"
    else
        print_check "Modular translation files" "FAIL" "No modular translation files found"
    fi
fi

# Optional directories

# Check for required SES template JSON files
echo ""
echo "[2b] Checking SES Template JSON files..."

# List of required template files (update as needed)
required_templates=(
    "Fisheries_SES_Template.json"
    "Tourism_SES_Template.json"
    "Aquaculture_SES_Template.json"
    "Pollution_SES_Template.json"
    "ClimateChange_SES_Template.json"
    "Caribbean_SES_Template.json"
    "OffshoreWind_SES_Template.json"
)

all_templates_exist=true
for template in "${required_templates[@]}"; do
    if [ -f "$app_dir/data/$template" ]; then
        print_check "Template: $template" "PASS"
    else
        print_check "Template: $template" "FAIL" "File not found"
        all_templates_exist=false
    fi
done

if $all_templates_exist; then
    print_check "All SES template JSON files present" "PASS"
else
    print_check "All SES template JSON files present" "FAIL" "One or more template files missing"
fi

# Optional directories
if [ -d "$app_dir/docs" ]; then
    print_check "Documentation directory" "PASS"
else
    print_check "Documentation directory" "WARN" "Not present (optional)"
fi

# ============================================================================
# Check 3: Permissions
# ============================================================================
echo ""
echo "[3] Checking Permissions..."

owner=$(stat -c '%U' "$app_dir")
if [ "$owner" == "shiny" ]; then
    print_check "Application directory ownership" "PASS"
else
    print_check "Application directory ownership" "WARN" "Owner is $owner, should be shiny"
fi

# Check if shiny user can read files
if sudo -u shiny test -r "$app_dir/app.R"; then
    print_check "Shiny user can read files" "PASS"
else
    print_check "Shiny user can read files" "FAIL" "Permission denied"
fi

# ============================================================================
# Check 4: Shiny Server Configuration
# ============================================================================
echo ""
echo "[4] Checking Shiny Server Configuration..."

config_file="/etc/shiny-server/shiny-server.conf"
if [ -f "$config_file" ]; then
    print_check "Configuration file exists" "PASS"
    
    if grep -q "marinesabres" "$config_file"; then
        print_check "MarineSABRES configuration present" "PASS"
    else
        print_check "MarineSABRES configuration present" "WARN" "Not found in config"
    fi
else
    print_check "Configuration file exists" "FAIL" "File not found"
fi

# ============================================================================
# Check 5: Logs
# ============================================================================
echo ""
echo "[5] Checking Logs..."

log_dir="/var/log/shiny-server"
if [ -d "$log_dir" ]; then
    print_check "Log directory exists" "PASS"
    
    # Check for recent errors
    if [ -f "$log_dir/marinesabres.log" ]; then
        error_count=$(grep -c "ERROR" "$log_dir/marinesabres.log" 2>/dev/null || echo "0")
        if [ "$error_count" -gt 0 ]; then
            print_check "Application errors" "WARN" "$error_count errors found in log"
        else
            print_check "Application errors" "PASS"
        fi
    fi
else
    print_check "Log directory exists" "FAIL" "Directory not found"
fi

# ============================================================================
# Check 6: Network Access
# ============================================================================
echo ""
echo "[6] Checking Network Access..."

# Check if port 3838 is listening
if netstat -tuln 2>/dev/null | grep -q ":3838"; then
    print_check "Port 3838 listening" "PASS"
elif ss -tuln 2>/dev/null | grep -q ":3838"; then
    print_check "Port 3838 listening" "PASS"
else
    print_check "Port 3838 listening" "FAIL" "Port not listening"
fi

# Try to access the application
echo ""
echo "Testing HTTP access..."
if command -v curl &> /dev/null; then
    response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3838/marinesabres/ 2>/dev/null || echo "000")
    if [ "$response" == "200" ]; then
        print_check "HTTP access to application" "PASS"
    else
        print_check "HTTP access to application" "WARN" "HTTP status: $response"
    fi
else
    print_check "HTTP access test" "WARN" "curl not available"
fi

# ============================================================================
# Check 7: R Package Dependencies
# ============================================================================
echo ""
echo "[7] Checking R Package Dependencies..."

required_packages=("shiny" "shinydashboard" "shinyWidgets" "shinyjs" "shinyBS" "shiny.i18n" "igraph" "visNetwork" "DT" "jsonlite")

missing_packages=()
for pkg in "${required_packages[@]}"; do
    if ! Rscript -e "if (!requireNamespace('$pkg', quietly=TRUE)) quit(status=1)" 2>/dev/null; then
        missing_packages+=("$pkg")
    fi
done

if [ ${#missing_packages[@]} -eq 0 ]; then
    print_check "All required R packages installed" "PASS"
else
    print_check "R packages" "WARN" "Missing: ${missing_packages[*]}"
fi

# ============================================================================
# Check 8: Disk Space
# ============================================================================
echo ""
echo "[8] Checking System Resources..."

# Check disk space in app directory
disk_usage=$(df -h "$app_dir" | tail -1 | awk '{print $5}' | sed 's/%//')
if [ "$disk_usage" -lt 90 ]; then
    print_check "Disk space" "PASS"
else
    print_check "Disk space" "WARN" "Usage at ${disk_usage}%"
fi

# Check available memory
if command -v free &> /dev/null; then
    mem_available=$(free -m | awk '/^Mem:/{print $7}')
    if [ "$mem_available" -gt 512 ]; then
        print_check "Available memory" "PASS"
    else
        print_check "Available memory" "WARN" "Only ${mem_available}MB available"
    fi
fi

# ============================================================================
# Summary
# ============================================================================
echo ""
echo "================================================================================"
echo " Validation Summary"
echo "================================================================================"
echo ""

total_checks=$((checks_passed + checks_warning + checks_failed))

echo "Total Checks: $total_checks"
echo -e "${GREEN}✓ Passed: $checks_passed${NC}"
if [ $checks_warning -gt 0 ]; then
    echo -e "${YELLOW}⚠ Warnings: $checks_warning${NC}"
fi
if [ $checks_failed -gt 0 ]; then
    echo -e "${RED}✗ Failed: $checks_failed${NC}"
fi

echo ""

if [ $checks_failed -gt 0 ]; then
    echo "❌ DEPLOYMENT HAS ERRORS"
    echo "   Please fix the errors above."
    echo ""
    echo "Useful commands:"
    echo "  - Check status: sudo systemctl status shiny-server"
    echo "  - View logs: sudo tail -f /var/log/shiny-server/marinesabres.log"
    echo "  - Restart: sudo systemctl restart shiny-server"
    echo ""
    exit 1
elif [ $checks_warning -gt 0 ]; then
    echo "⚠️  DEPLOYMENT COMPLETE WITH WARNINGS"
    echo "   Review warnings above."
    echo ""
    echo "Application URL: http://$(hostname -I | awk '{print $1}'):3838/marinesabres"
    echo ""
    exit 0
else
    echo "✅ DEPLOYMENT VALIDATED SUCCESSFULLY"
    echo ""
    echo "Application URL: http://$(hostname -I | awk '{print $1}'):3838/marinesabres"
    echo ""
    echo "Useful commands:"
    echo "  - Check status: sudo systemctl status shiny-server"
    echo "  - View logs: sudo tail -f /var/log/shiny-server/marinesabres.log"
    echo "  - Restart: sudo systemctl restart shiny-server"
    echo ""
    exit 0
fi
