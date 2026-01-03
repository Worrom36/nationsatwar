@echo off
REM ============================================
REM MOOSE Verification Script
REM Checks if MOOSE is properly installed
REM ============================================

echo ============================================
echo MOOSE Installation Verification
echo ============================================
echo.

set "MOOSE_DIR=Scripts\MOOSE"
set "MOOSE_LUA=%MOOSE_DIR%\MOOSE.lua"
set "MOOSE_CORE=%MOOSE_DIR%\Core"

echo Checking MOOSE installation...
echo.

REM Check if directory exists
if not exist "%MOOSE_DIR%" (
    echo [FAIL] MOOSE directory not found: %MOOSE_DIR%
    echo.
    echo Please install MOOSE first using install_moose.ps1
    echo.
    pause
    exit /b 1
)

echo [OK] MOOSE directory exists: %MOOSE_DIR%

REM Check for MOOSE.lua
if exist "%MOOSE_LUA%" (
    echo [OK] MOOSE.lua found
) else (
    echo [FAIL] MOOSE.lua not found at: %MOOSE_LUA%
    echo.
    echo MOOSE installation appears incomplete.
    echo Please reinstall MOOSE.
    echo.
    pause
    exit /b 1
)

REM Check for Core directory
if exist "%MOOSE_CORE%" (
    echo [OK] Core directory found
) else (
    echo [WARNING] Core directory not found: %MOOSE_CORE%
    echo Some MOOSE features may not work.
)

REM Check for other important directories
if exist "%MOOSE_DIR%\Missions" (
    echo [OK] Missions directory found
) else (
    echo [INFO] Missions directory not found (optional)
)

echo.
echo ============================================
echo Verification Summary
echo ============================================
echo.
echo MOOSE appears to be properly installed!
echo Location: %CD%\%MOOSE_DIR%
echo.
echo You can now use MOOSE in your DCS missions.
echo.
pause

