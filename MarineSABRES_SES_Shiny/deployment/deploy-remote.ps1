# ============================================================================
# MarineSABRES Remote Deployment - PowerShell Wrapper for Windows
# ============================================================================
#
# This PowerShell script provides a Windows-native wrapper for remote
# deployment to laguna.ku.lt Shiny server
#
# Prerequisites:
#   1. Windows Subsystem for Linux (WSL) OR Git Bash
#   2. SSH access to laguna.ku.lt configured
#   3. rsync available (via WSL or Git Bash)
#
# Usage:
#   .\deploy-remote.ps1 [-DryRun] [-ExcludeModels] [-Force] [-UseWSL] [-UseGitBash]
#
# Examples:
#   .\deploy-remote.ps1                    # Interactive deployment via WSL
#   .\deploy-remote.ps1 -DryRun            # Test run without actual deployment
#   .\deploy-remote.ps1 -UseGitBash        # Use Git Bash instead of WSL
#   .\deploy-remote.ps1 -ExcludeModels     # Skip SESModels directory
#
# Version: 1.1
# Created: 2026-01-12
#
# ============================================================================

param(
    [switch]$DryRun,           # Show what would be deployed without deploying
    [switch]$ExcludeModels,    # Exclude SESModels directory
    [switch]$Force,            # Skip confirmation prompts
    [switch]$UseWSL,           # Force use of WSL
    [switch]$UseGitBash,       # Force use of Git Bash
    [switch]$Help              # Show help
)

# Color output functions
function Write-ColorOutput($ForegroundColor) {
    $fc = $host.UI.RawUI.ForegroundColor
    $bc = $host.UI.RawUI.BackgroundColor
    try {
        $host.UI.RawUI.ForegroundColor = $ForegroundColor
        if ($args) {
            Write-Output $args
        } else {
            $input | Write-Output
        }
    } finally {
        $host.UI.RawUI.ForegroundColor = $fc
        $host.UI.RawUI.BackgroundColor = $bc
    }
}

function Write-Header($message) {
    Write-Host ""
    Write-ColorOutput "Cyan" "================================================================================"
    Write-ColorOutput "Cyan" " $message"
    Write-ColorOutput "Cyan" "================================================================================"
    Write-Host ""
}

function Write-Success($message) {
    Write-ColorOutput "Green" "[OK] $message"
}

function Write-Error($message) {
    Write-ColorOutput "Red" "[ERROR] $message"
}

function Write-Warning($message) {
    Write-ColorOutput "Yellow" "[WARN] $message"
}

function Write-Status($message) {
    Write-ColorOutput "Blue" "==> $message"
}

# Show help
if ($Help) {
    Write-Host "MarineSABRES Remote Deployment for Windows"
    Write-Host ""
    Write-Host "Usage: .\deploy-remote.ps1 [OPTIONS]"
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  -DryRun         Show what would be deployed without actually deploying"
    Write-Host "  -ExcludeModels  Exclude SESModels directory from deployment"
    Write-Host "  -Force          Skip confirmation prompts"
    Write-Host "  -UseWSL         Force use of Windows Subsystem for Linux"
    Write-Host "  -UseGitBash     Force use of Git Bash"
    Write-Host "  -Help           Show this help message"
    Write-Host ""
    Write-Host "Prerequisites:"
    Write-Host "  1. SSH access to laguna.ku.lt configured"
    Write-Host "  2. Either WSL or Git Bash installed"
    Write-Host "  3. rsync available in chosen environment"
    Write-Host ""
    Write-Host "Examples:"
    Write-Host "  .\deploy-remote.ps1                    # Interactive deployment"
    Write-Host "  .\deploy-remote.ps1 -DryRun            # Test without deploying"
    Write-Host "  .\deploy-remote.ps1 -UseGitBash        # Use Git Bash"
    exit 0
}

# Clear screen and show header
Clear-Host
Write-Header "MarineSABRES Remote Deployment - Windows to laguna.ku.lt"

# Get script directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$AppDir = Split-Path -Parent $ScriptDir

Write-Host "  Script Directory: $ScriptDir"
Write-Host "  App Directory:    $AppDir"
Write-Host ""

# Check if we're in the right directory
if (-not (Test-Path (Join-Path $AppDir "app.R"))) {
    Write-Error "app.R not found in $AppDir"
    Write-Host "Please run this script from the deployment directory of your MarineSABRES project."
    exit 1
}

Write-Success "Found MarineSABRES application files"

# ============================================================================
# Environment Detection and Selection
# ============================================================================

Write-Status "Detecting available environments..."

# Check for WSL by actually testing if it can run commands
$WSLAvailable = $false
try {
    $wslPath = Get-Command wsl.exe -ErrorAction SilentlyContinue
    if ($wslPath) {
        # Try to run a simple command in WSL to verify it works
        $testResult = wsl echo "WSL_OK" 2>&1
        if ($LASTEXITCODE -eq 0 -and $testResult -match "WSL_OK") {
            $WSLAvailable = $true
            Write-Success "Windows Subsystem for Linux (WSL) is available and working"
        } else {
            Write-Warning "WSL installed but no Linux distribution configured"
            Write-Host "    To install Ubuntu: wsl --install -d Ubuntu"
            Write-Host "    Will try Git Bash instead..."
        }
    }
} catch {
    # WSL not available
}

# Check for Git Bash
$GitBashAvailable = $false
$GitBashPath = $null
$GitBashPaths = @(
    "$env:ProgramFiles\Git\bin\bash.exe",
    "${env:ProgramFiles(x86)}\Git\bin\bash.exe",
    "$env:USERPROFILE\AppData\Local\Programs\Git\bin\bash.exe"
)

foreach ($path in $GitBashPaths) {
    if (Test-Path $path) {
        $GitBashPath = $path
        $GitBashAvailable = $true
        Write-Success "Git Bash detected at: $path"
        break
    }
}

# Determine which environment to use
$UseEnvironment = $null

if ($UseWSL -and $WSLAvailable) {
    $UseEnvironment = "WSL"
} elseif ($UseGitBash -and $GitBashAvailable) {
    $UseEnvironment = "GitBash"
} elseif ($WSLAvailable) {
    $UseEnvironment = "WSL"
} elseif ($GitBashAvailable) {
    $UseEnvironment = "GitBash"
} else {
    Write-Error "Neither WSL nor Git Bash is available!"
    Write-Host ""
    Write-Host "Please install one of the following:"
    Write-Host "  1. Windows Subsystem for Linux (WSL): https://docs.microsoft.com/en-us/windows/wsl/install"
    Write-Host "  2. Git for Windows (includes Git Bash): https://git-scm.com/download/win"
    Write-Host ""
    exit 1
}

Write-Status "Using environment: $UseEnvironment"

# ============================================================================
# Pre-deployment Checks
# ============================================================================

Write-Header "Pre-Deployment Validation"

Write-Status "Running R validation script..."

# Run R pre-deployment checks
$RCheckScript = Join-Path $ScriptDir "pre-deploy-check-remote.R"

if (Test-Path $RCheckScript) {
    try {
        Push-Location $AppDir
        Write-Host ""
        # Run Rscript and let output display directly to console (don't capture)
        & Rscript $RCheckScript
        $rCheckExitCode = $LASTEXITCODE
        Pop-Location
        Write-Host ""

        if ($rCheckExitCode -eq 0) {
            Write-Success "All R validation checks passed"
        } elseif ($rCheckExitCode -eq 2) {
            Write-Warning "R validation has warnings (see details above)"
            if (-not $Force) {
                $continue = Read-Host "Continue with deployment despite warnings? (y/N)"
                if ($continue -ne "y" -and $continue -ne "Y") {
                    Write-Error "Deployment cancelled by user"
                    exit 1
                }
            }
        } else {
            Write-Error "R validation failed with critical errors (see above)"
            Write-Host "Please fix the errors before proceeding."
            exit 1
        }
    } catch {
        Write-Warning "Could not run R validation - Rscript may not be in PATH"
        Write-Host "Error: $($_.Exception.Message)"
    }
} else {
    Write-Warning "R validation script not found at: $RCheckScript"
}

# ============================================================================
# Build Deployment Command
# ============================================================================

Write-Header "Preparing Deployment Command"

# Convert PowerShell paths to Unix-style for bash
# WSL uses /mnt/c/..., Git Bash uses /c/...
function Convert-ToUnixPath {
    param([string]$WinPath, [string]$Environment)

    $unixPath = $WinPath -replace "\\", "/"

    if ($Environment -eq "WSL") {
        # WSL format: /mnt/c/Users/... (lowercase drive letter)
        if ($unixPath -match "^([A-Za-z]):(.*)") {
            $drive = $Matches[1].ToLower()
            $rest = $Matches[2]
            $unixPath = "/mnt/$drive$rest"
        }
    } else {
        # Git Bash format: /c/Users/... (lowercase drive letter)
        if ($unixPath -match "^([A-Za-z]):(.*)") {
            $drive = $Matches[1].ToLower()
            $rest = $Matches[2]
            $unixPath = "/$drive$rest"
        }
    }

    return $unixPath
}

$UnixAppDir = Convert-ToUnixPath -WinPath $AppDir -Environment $UseEnvironment
$UnixScriptDir = Convert-ToUnixPath -WinPath $ScriptDir -Environment $UseEnvironment

# Build command arguments
$deployArgs = @()

if ($DryRun) {
    $deployArgs += "--dry-run"
    Write-Status "DRY RUN MODE enabled"
}

if ($ExcludeModels) {
    $deployArgs += "--exclude-models"
    Write-Status "SESModels directory will be excluded"
}

if ($Force) {
    $deployArgs += "--force"
    Write-Status "Force mode enabled - skipping confirmations"
}

$argsString = $deployArgs -join " "
$deployCommand = "cd '$UnixAppDir' && ./deployment/remote-deploy.sh $argsString"

Write-Status "Deployment command prepared"
Write-Host "  Environment: $UseEnvironment"
Write-Host "  Command: $deployCommand"

# ============================================================================
# Execute Deployment
# ============================================================================

if (-not $Force) {
    Write-Host ""
    Write-Warning "Ready to deploy to laguna.ku.lt"
    Write-Host ""
    Write-Host "This will:"
    Write-Host "  1. Connect to laguna.ku.lt via SSH"
    Write-Host "  2. Stop Shiny Server"
    Write-Host "  3. Backup existing application"
    Write-Host "  4. Upload new files via rsync"
    Write-Host "  5. Restart Shiny Server"
    Write-Host ""

    if ($DryRun) {
        Write-Host "DRY RUN: No actual changes will be made"
        Write-Host ""
    }

    $proceed = Read-Host "Continue? (y/N)"
    if ($proceed -ne "y" -and $proceed -ne "Y") {
        Write-Error "Deployment cancelled by user"
        exit 1
    }
}

Write-Header "Executing Remote Deployment"

$deployExitCode = 1

try {
    if ($UseEnvironment -eq "WSL") {
        Write-Status "Executing via WSL..."
        wsl bash -c $deployCommand
        $deployExitCode = $LASTEXITCODE
    } else {
        Write-Status "Executing via Git Bash..."
        & $GitBashPath -c $deployCommand
        $deployExitCode = $LASTEXITCODE
    }

    if ($deployExitCode -eq 0) {
        Write-Header "Deployment Complete"
        Write-Success "Remote deployment successful!"
        Write-Host ""

        if (-not $DryRun) {
            Write-Host "Application URL: http://laguna.ku.lt:3838/marinesabres/"
            Write-Host ""
            Write-Host "Next steps:"
            Write-Host "  1. Open the application URL in your browser"
            Write-Host "  2. Clear browser cache if needed (Ctrl+Shift+R)"
            Write-Host "  3. Test application functionality"
            Write-Host ""
            Write-Warning "Remember to clear your browser cache if you see old content!"
        } else {
            Write-Host "Dry run completed successfully"
            Write-Host "  Run without -DryRun to perform actual deployment"
        }
    } else {
        Write-Error "Deployment failed with exit code: $deployExitCode"
        exit $deployExitCode
    }

} catch {
    Write-Error "Deployment execution failed: $($_.Exception.Message)"
    exit 1
}

# ============================================================================
# Optional: Open browser
# ============================================================================

if ((-not $DryRun) -and ($deployExitCode -eq 0)) {
    Write-Host ""
    $openBrowser = Read-Host "Open application in browser? (y/N)"
    if (($openBrowser -eq "y") -or ($openBrowser -eq "Y")) {
        $appUrl = "http://laguna.ku.lt:3838/marinesabres/"
        Start-Process $appUrl
    }
}

Write-Host ""
