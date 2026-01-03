@echo off
REM ============================================
REM MOOSE Manual Installation Helper
REM Opens browser and provides instructions
REM ============================================

echo ============================================
echo MOOSE Manual Installation Helper
echo ============================================
echo.

set "MOOSE_DIR=Scripts\MOOSE"
set "MOOSE_URL=https://github.com/FlightControl-Master/MOOSE"

echo This script will help you install MOOSE manually.
echo.
echo Installation steps:
echo 1. Opening MOOSE GitHub page in your browser...
echo 2. Download the latest release or clone the repository
echo 3. Extract/copy MOOSE files to: %CD%\%MOOSE_DIR%
echo.

REM Create directory if it doesn't exist
if not exist "Scripts" mkdir "Scripts"
if not exist "%MOOSE_DIR%" mkdir "%MOOSE_DIR%"

echo Opening GitHub page...
start "" "%MOOSE_URL%"

echo.
echo ============================================
echo Manual Installation Instructions
echo ============================================
echo.
echo Option 1 - Download ZIP:
echo   1. Click "Code" ^> "Download ZIP" on GitHub
echo   2. Extract the ZIP file
echo   3. Copy all files from MOOSE-master folder to:
echo      %CD%\%MOOSE_DIR%
echo.
echo Option 2 - Clone with Git:
echo   git clone %MOOSE_URL%.git %MOOSE_DIR%
echo.
echo After installation, verify MOOSE.lua exists at:
echo   %CD%\%MOOSE_DIR%\MOOSE.lua
echo.
echo Press any key when installation is complete...
pause >nul

REM Verify installation
if exist "%MOOSE_DIR%\MOOSE.lua" (
    echo.
    echo ============================================
    echo Installation verified!
    echo MOOSE.lua found at: %MOOSE_DIR%\MOOSE.lua
    echo ============================================
) else (
    echo.
    echo ============================================
    echo Installation not verified!
    echo MOOSE.lua not found at: %MOOSE_DIR%\MOOSE.lua
    echo Please check your installation.
    echo ============================================
)

echo.
pause

