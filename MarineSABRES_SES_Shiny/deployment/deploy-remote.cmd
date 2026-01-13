@echo off
REM ============================================================================
REM MarineSABRES Remote Deployment - Windows Command File
REM ============================================================================
REM
REM Usage:
REM   deploy-remote.cmd                    - Interactive deployment
REM   deploy-remote.cmd --dry-run          - Test without deploying
REM   deploy-remote.cmd --exclude-models   - Skip SESModels directory
REM   deploy-remote.cmd --force            - Skip confirmation prompts
REM   deploy-remote.cmd --use-gitbash      - Force Git Bash (skip WSL)
REM   deploy-remote.cmd --help             - Show help
REM
REM Target: http://laguna.ku.lt:3838/marinesabres/
REM ============================================================================

setlocal EnableDelayedExpansion

REM Get the directory where this script is located
set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

REM Path to the PowerShell script
set "PS_SCRIPT=%SCRIPT_DIR%\deploy-remote.ps1"

REM Check if PowerShell script exists
if not exist "%PS_SCRIPT%" (
    echo [ERROR] deploy-remote.ps1 not found at:
    echo   %PS_SCRIPT%
    exit /b 1
)

REM Build PowerShell arguments
set "PS_ARGS="

:parse_args
if "%~1"=="" goto run_script

if /i "%~1"=="--dry-run" set "PS_ARGS=!PS_ARGS! -DryRun" & shift & goto parse_args
if /i "%~1"=="-d" set "PS_ARGS=!PS_ARGS! -DryRun" & shift & goto parse_args
if /i "%~1"=="--exclude-models" set "PS_ARGS=!PS_ARGS! -ExcludeModels" & shift & goto parse_args
if /i "%~1"=="-e" set "PS_ARGS=!PS_ARGS! -ExcludeModels" & shift & goto parse_args
if /i "%~1"=="--force" set "PS_ARGS=!PS_ARGS! -Force" & shift & goto parse_args
if /i "%~1"=="-f" set "PS_ARGS=!PS_ARGS! -Force" & shift & goto parse_args
if /i "%~1"=="--use-wsl" set "PS_ARGS=!PS_ARGS! -UseWSL" & shift & goto parse_args
if /i "%~1"=="--use-gitbash" set "PS_ARGS=!PS_ARGS! -UseGitBash" & shift & goto parse_args
if /i "%~1"=="--help" goto show_help
if /i "%~1"=="-h" goto show_help
if /i "%~1"=="/?" goto show_help

echo [WARN] Unknown argument: %~1
shift
goto parse_args

:show_help
echo.
echo ================================================================================
echo  MarineSABRES Remote Deployment
echo ================================================================================
echo.
echo Usage: deploy-remote.cmd [OPTIONS]
echo.
echo Options:
echo   --dry-run, -d         Test without deploying
echo   --exclude-models, -e  Skip SESModels directory
echo   --force, -f           Skip confirmation prompts
echo   --use-wsl             Force WSL (requires Linux distro installed)
echo   --use-gitbash         Force Git Bash (recommended if WSL not configured)
echo   --help, -h            Show this help
echo.
echo Examples:
echo   deploy-remote.cmd                         Interactive deployment
echo   deploy-remote.cmd --dry-run               Test run
echo   deploy-remote.cmd --use-gitbash           Use Git Bash instead of WSL
echo   deploy-remote.cmd --force --dry-run       Non-interactive test
echo.
echo Target: http://laguna.ku.lt:3838/marinesabres/
echo.
exit /b 0

:run_script
echo.
echo ================================================================================
echo  MarineSABRES Remote Deployment
echo ================================================================================
echo.

REM Run PowerShell script
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%" %PS_ARGS%
set "EXIT_CODE=%ERRORLEVEL%"

echo.
if %EXIT_CODE%==0 (
    echo [OK] Deployment completed successfully
    echo.
    echo URL: http://laguna.ku.lt:3838/marinesabres/
) else (
    echo [ERROR] Deployment failed with exit code: %EXIT_CODE%
)

echo.
echo Press any key to exit...
pause >nul
exit /b %EXIT_CODE%
