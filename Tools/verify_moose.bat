@echo off
REM ============================================
REM MOOSE Verification Script
REM Checks if MOOSE is properly installed
REM Run from repo root or from Tools/ - script cd's to repo root
REM ============================================

cd /d "%~dp0.."

echo ============================================
echo MOOSE Installation Verification
echo ============================================
echo.

set "MOOSE_DIR=Scripts\MOOSE"
set "MOOSE_LOADER=%MOOSE_DIR%\Moose Setup\Moose Templates\Moose_Dynamic_Loader.lua"
set "MOOSE_MODULES=%MOOSE_DIR%\Moose Development\Moose\Modules.lua"

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

REM Check for Dynamic Loader (used by Init.lua)
if exist "%MOOSE_LOADER%" (
    echo [OK] Moose_Dynamic_Loader.lua found
) else (
    echo [FAIL] Dynamic Loader not found: %MOOSE_LOADER%
    echo.
    echo MOOSE installation appears incomplete.
    echo Please reinstall MOOSE.
    echo.
    pause
    exit /b 1
)

REM Check for Moose Development / Modules
if exist "%MOOSE_MODULES%" (
    echo [OK] Moose Development\Modules.lua found
) else (
    echo [WARNING] Moose Development\Modules.lua not found
    echo Some MOOSE features may not work.
)

REM Optional: MOOSE framework Missions (inside Scripts\MOOSE)
if exist "%MOOSE_DIR%\Missions" (
    echo [OK] MOOSE framework Missions folder found
) else (
    echo [INFO] MOOSE framework Missions not found (optional)
)

REM Project Missions folder (nationsatwar\Missions)
if exist "Missions" (
    echo [OK] Project Missions folder found: Missions\
) else (
    echo [INFO] Project Missions folder not found: Missions\
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

