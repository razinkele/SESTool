# ============================================================================
# MarineSABRES Remote Deployment - Native Windows (tar + scp + ssh)
# ============================================================================
#
# Deploys directly to laguna.ku.lt using native Windows OpenSSH tools.
# No WSL or Git Bash required.
#
# Prerequisites:
#   1. Windows 10/11 with OpenSSH client (built-in)
#   2. SSH key-based access to razinka@laguna.ku.lt configured
#
# Ownership model: razinka:shiny
#   - razinka owns the files (can deploy without sudo)
#   - shiny group gives Shiny Server read access
#   - Only systemctl restart requires sudo
#
# Usage:
#   .\deploy-remote.ps1 [-DryRun] [-ExcludeModels] [-Force]
#
# Version: 2.0
# Created: 2026-01-12
# Updated: 2026-02-24
#
# ============================================================================

param(
    [switch]$DryRun,           # Show what would be deployed without deploying
    [switch]$ExcludeModels,    # Exclude SESModels directory
    [switch]$Force,            # Skip confirmation prompts
    [switch]$Help              # Show help
)

# ============================================================================
# Configuration
# ============================================================================

$RemoteHost = "laguna.ku.lt"
$RemoteUser = "razinka"
$RemoteTarget = "/srv/shiny-server/marinesabres"
$RemoteOwner = "razinka"
$RemoteGroup = "shiny"
$TarFilename = "marinesabres-deploy.tar.gz"

# ============================================================================
# Helper Functions
# ============================================================================

function Write-Header($message) {
    Write-Host ""
    Write-Host "================================================================================" -ForegroundColor Cyan
    Write-Host " $message" -ForegroundColor Cyan
    Write-Host "================================================================================" -ForegroundColor Cyan
    Write-Host ""
}

function Write-Success($message) {
    Write-Host "[OK] $message" -ForegroundColor Green
}

function Write-Err($message) {
    Write-Host "[ERROR] $message" -ForegroundColor Red
}

function Write-Warn($message) {
    Write-Host "[WARN] $message" -ForegroundColor Yellow
}

function Write-Status($message) {
    Write-Host "==> $message" -ForegroundColor Blue
}

# ============================================================================
# Help
# ============================================================================

if ($Help) {
    Write-Host "MarineSABRES Remote Deployment for Windows"
    Write-Host ""
    Write-Host "Usage: .\deploy-remote.ps1 [OPTIONS]"
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  -DryRun         Show what would be deployed (list files, no upload)"
    Write-Host "  -ExcludeModels  Exclude SESModels directory from deployment"
    Write-Host "  -Force          Skip confirmation prompts"
    Write-Host "  -Help           Show this help message"
    Write-Host ""
    Write-Host "Prerequisites:"
    Write-Host "  1. Windows 10/11 with OpenSSH (built-in)"
    Write-Host "  2. SSH key access to razinka@laguna.ku.lt"
    Write-Host ""
    Write-Host "Target: http://laguna.ku.lt:3838/marinesabres/"
    exit 0
}

# ============================================================================
# Initialization
# ============================================================================

Clear-Host
Write-Header "MarineSABRES Remote Deployment v2.0 - Native Windows"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$AppDir = Split-Path -Parent $ScriptDir
$TarPath = Join-Path $env:TEMP $TarFilename

Write-Host "  App Directory:  $AppDir"
Write-Host "  Remote Target:  ${RemoteUser}@${RemoteHost}:${RemoteTarget}"
Write-Host "  Ownership:      ${RemoteOwner}:${RemoteGroup}"
Write-Host ""

# Verify app.R exists
if (-not (Test-Path (Join-Path $AppDir "app.R"))) {
    Write-Err "app.R not found in $AppDir"
    exit 1
}
Write-Success "Found MarineSABRES application files"

# ============================================================================
# Check Prerequisites
# ============================================================================

Write-Header "Checking Prerequisites"

# Check for native Windows tools
$toolsOk = $true
foreach ($tool in @("ssh", "scp", "tar")) {
    $cmd = Get-Command $tool -ErrorAction SilentlyContinue
    if ($cmd) {
        Write-Success "$tool found: $($cmd.Source)"
    } else {
        Write-Err "$tool not found in PATH"
        $toolsOk = $false
    }
}

if (-not $toolsOk) {
    Write-Host ""
    Write-Err "Missing required tools. Windows OpenSSH should be enabled:"
    Write-Host "  Settings > Apps > Optional Features > OpenSSH Client"
    exit 1
}

# Test SSH connectivity
Write-Status "Testing SSH connection..."
ssh -o ConnectTimeout=10 -o BatchMode=yes "${RemoteUser}@${RemoteHost}" "echo OK" 2>$null | Out-Null
if ($LASTEXITCODE -eq 0) {
    Write-Success "SSH connection to ${RemoteHost} successful"
} else {
    Write-Err "SSH connection failed. Check your SSH key configuration."
    Write-Host "  Try: ssh ${RemoteUser}@${RemoteHost}"
    exit 1
}

# ============================================================================
# Pre-Deployment R Validation
# ============================================================================

Write-Header "Pre-Deployment Validation"

$RCheckScript = Join-Path $ScriptDir "pre-deploy-check-remote.R"

if (Test-Path $RCheckScript) {
    Write-Status "Running R validation script..."
    try {
        Push-Location $AppDir
        & Rscript $RCheckScript
        $rCheckExitCode = $LASTEXITCODE
        Pop-Location
        Write-Host ""

        if ($rCheckExitCode -eq 0) {
            Write-Success "All R validation checks passed"
        } elseif ($rCheckExitCode -eq 2) {
            Write-Warn "R validation has warnings (see above)"
            if (-not $Force) {
                $continue = Read-Host "Continue despite warnings? (y/N)"
                if ($continue -ne "y" -and $continue -ne "Y") {
                    Write-Err "Deployment cancelled"
                    exit 1
                }
            }
        } else {
            Write-Err "R validation failed with critical errors"
            exit 1
        }
    } catch {
        Write-Warn "Could not run R validation: $($_.Exception.Message)"
    }
} else {
    Write-Warn "R validation script not found, skipping"
}

# ============================================================================
# Create Tar Archive
# ============================================================================

Write-Header "Creating Deployment Archive"

# Build tar exclude arguments
$excludes = @(
    "--exclude=.git",
    "--exclude=.claude",
    "--exclude=.playwright-mcp",
    "--exclude=.Rhistory",
    "--exclude=.Rproj.user",
    "--exclude=.gitignore",
    "--exclude=.dockerignore",
    "--exclude=*.Rproj",
    "--exclude=*.log",
    "--exclude=*.tmp",
    "--exclude=deployment",
    "--exclude=tests",
    "--exclude=DTU",
    "--exclude=Documents",
    "--exclude=CLEANUP_SCRIPT.R",
    "--exclude=run_ui_tests.R",
    "--exclude=fixture_list.txt",
    "--exclude=abstract.docx",
    "--exclude=*.png"
)

if ($ExcludeModels) {
    $excludes += "--exclude=SESModels"
    Write-Status "SESModels directory will be excluded"
}

Write-Status "Archiving application files..."

# Remove old tar if exists
if (Test-Path $TarPath) {
    Remove-Item $TarPath -Force
}

# Create tar.gz from the app directory
$tarArgs = @("-czf", $TarPath) + $excludes + @("-C", $AppDir, ".")
& tar @tarArgs

if ($LASTEXITCODE -ne 0) {
    Write-Err "Failed to create tar archive"
    exit 1
}

$tarSize = [math]::Round((Get-Item $TarPath).Length / 1MB, 1)
Write-Success "Archive created: $TarPath ($tarSize MB)"

# ============================================================================
# Dry Run — just list contents
# ============================================================================

if ($DryRun) {
    Write-Header "DRY RUN - Archive Contents"
    & tar -tzf $TarPath
    Write-Host ""
    Write-Warn "DRY RUN - no files were uploaded"
    Write-Host "  Archive size: $tarSize MB"
    Write-Host "  Run without -DryRun to deploy"

    # Cleanup
    Remove-Item $TarPath -Force -ErrorAction SilentlyContinue
    exit 0
}

# ============================================================================
# Confirmation
# ============================================================================

if (-not $Force) {
    Write-Host ""
    Write-Warn "Ready to deploy to ${RemoteHost}"
    Write-Host ""
    Write-Host "This will:"
    Write-Host "  1. Upload $tarSize MB archive via scp"
    Write-Host "  2. Clear existing app files on server"
    Write-Host "  3. Extract new files"
    Write-Host "  4. Set ownership to ${RemoteOwner}:${RemoteGroup}"
    Write-Host "  5. Restart Shiny Server (requires sudo)"
    Write-Host ""

    $proceed = Read-Host "Continue? (y/N)"
    if ($proceed -ne "y" -and $proceed -ne "Y") {
        Write-Err "Deployment cancelled"
        Remove-Item $TarPath -Force -ErrorAction SilentlyContinue
        exit 1
    }
}

# ============================================================================
# Upload via SCP
# ============================================================================

Write-Header "Uploading to ${RemoteHost}"

Write-Status "Uploading archive via scp..."
& scp $TarPath "${RemoteUser}@${RemoteHost}:/tmp/${TarFilename}"

if ($LASTEXITCODE -ne 0) {
    Write-Err "scp upload failed"
    Remove-Item $TarPath -Force -ErrorAction SilentlyContinue
    exit 1
}
Write-Success "Archive uploaded to /tmp/${TarFilename}"

# ============================================================================
# Deploy on Remote Server
# ============================================================================

Write-Header "Deploying on Remote Server"

Write-Status "Extracting files and restarting Shiny Server..."

# Remote commands:
#   1. Clear target directory contents (razinka owns it, no sudo needed)
#   2. Extract tar archive into target
#   3. Set ownership razinka:shiny
#   4. Set permissions 755
#   5. Clean up stale translation cache
#   6. Remove uploaded tar
#   7. Restart Shiny Server (sudo)
#   8. Report status
$remoteScript = @"
set -e
echo '==> Clearing target directory...'
rm -rf ${RemoteTarget}/*
echo '==> Extracting archive...'
tar -xzf /tmp/${TarFilename} -C ${RemoteTarget}/
echo '==> Setting ownership (${RemoteOwner}:${RemoteGroup})...'
chown -R ${RemoteOwner}:${RemoteGroup} ${RemoteTarget}
chmod -R 755 ${RemoteTarget}
rm -f ${RemoteTarget}/translations/_merged_translations.json 2>/dev/null || true
echo '==> Cleaning up...'
rm -f /tmp/${TarFilename}
echo '==> Restarting Shiny Server...'
sudo systemctl restart shiny-server
sleep 2
echo ''
echo 'Version:' && cat ${RemoteTarget}/VERSION 2>/dev/null || echo 'unknown'
echo 'Ownership:' && stat -c '%U:%G' ${RemoteTarget}
echo 'Shiny Server:' && systemctl is-active shiny-server
"@

# Write remote script to temp file, scp it, execute it
$remoteScriptPath = Join-Path $env:TEMP "marinesabres-deploy-remote.sh"
$remoteScript | Set-Content -Path $remoteScriptPath -Encoding UTF8 -NoNewline

& scp $remoteScriptPath "${RemoteUser}@${RemoteHost}:/tmp/marinesabres-deploy-remote.sh"
& ssh -t "${RemoteUser}@${RemoteHost}" "bash /tmp/marinesabres-deploy-remote.sh && rm -f /tmp/marinesabres-deploy-remote.sh"
$deployExitCode = $LASTEXITCODE

# ============================================================================
# Cleanup and Report
# ============================================================================

Remove-Item $TarPath -Force -ErrorAction SilentlyContinue
Remove-Item $remoteScriptPath -Force -ErrorAction SilentlyContinue

if ($deployExitCode -eq 0) {
    Write-Header "Deployment Complete"
    Write-Success "Remote deployment successful!"
    Write-Host ""
    Write-Host "  Application URL: http://laguna.ku.lt:3838/marinesabres/"
    Write-Host ""
    Write-Host "Next steps:"
    Write-Host "  1. Open the URL in your browser"
    Write-Host "  2. Clear browser cache (Ctrl+Shift+R)"
    Write-Host "  3. Test application functionality"
    Write-Host ""

    $openBrowser = Read-Host "Open application in browser? (y/N)"
    if ($openBrowser -eq "y" -or $openBrowser -eq "Y") {
        Start-Process "http://laguna.ku.lt:3838/marinesabres/"
    }
} else {
    Write-Err "Deployment failed with exit code: $deployExitCode"
    Write-Host ""
    Write-Host "Troubleshooting:"
    Write-Host "  ssh ${RemoteUser}@${RemoteHost} 'sudo journalctl -u shiny-server -n 50'"
    exit $deployExitCode
}

Write-Host ""
