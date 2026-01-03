# ============================================
# MOOSE Installation Script (PowerShell)
# Downloads and installs MOOSE framework
# ============================================

Write-Host "============================================"
Write-Host "MOOSE Framework Installer"
Write-Host "============================================"
Write-Host ""

# Get workspace root (parent of Tools directory)
$workspaceRoot = Split-Path -Parent $PSScriptRoot
Set-Location $workspaceRoot

$mooseDir = Join-Path $workspaceRoot "Scripts\MOOSE"
$mooseUrl = "https://github.com/FlightControl-Master/MOOSE/archive/refs/heads/master.zip"
$tempZip = Join-Path $workspaceRoot "moose_temp.zip"
$tempDir = Join-Path $workspaceRoot "moose_temp"

# Check if MOOSE already exists
if (Test-Path (Join-Path $mooseDir "MOOSE.lua")) {
    Write-Host "MOOSE already installed at $mooseDir"
    Write-Host ""
    $overwrite = Read-Host "Do you want to reinstall? (Y/N)"
    if ($overwrite -ne "Y" -and $overwrite -ne "y") {
        Write-Host "Installation cancelled."
        exit 0
    }
    Write-Host "Removing existing MOOSE installation..."
    Remove-Item -Path $mooseDir -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host ""
}

# Create Scripts directory if it doesn't exist
$scriptsDir = Join-Path $workspaceRoot "Scripts"
if (-not (Test-Path $scriptsDir)) {
    Write-Host "Creating Scripts directory..."
    New-Item -ItemType Directory -Path $scriptsDir -Force | Out-Null
}

# Create MOOSE directory
Write-Host "Creating MOOSE directory..."
if (-not (Test-Path $mooseDir)) {
    New-Item -ItemType Directory -Path $mooseDir -Force | Out-Null
}

try {
    Write-Host ""
    Write-Host "Downloading MOOSE from GitHub..."
    Write-Host "This may take a few moments..."
    Write-Host ""
    
    # Download
    $ProgressPreference = 'SilentlyContinue'
    Invoke-WebRequest -Uri $mooseUrl -OutFile $tempZip -UseBasicParsing
    Write-Host "Download complete."
    
    # Extract
    Write-Host "Extracting..."
    if (Test-Path $tempDir) {
        Remove-Item -Path $tempDir -Recurse -Force
    }
    Expand-Archive -Path $tempZip -DestinationPath $tempDir -Force
    Write-Host "Extraction complete."
    
    # Find MOOSE folder in extracted archive
    $mooseFolder = Get-ChildItem -Path $tempDir -Directory | Select-Object -First 1
    
    if ($mooseFolder) {
        Write-Host "Copying files..."
        Copy-Item -Path (Join-Path $mooseFolder.FullName "*") -Destination $mooseDir -Recurse -Force
        Write-Host "Installation complete!"
        
        # Cleanup
        Remove-Item -Path $tempZip -Force
        Remove-Item -Path $tempDir -Recurse -Force
        
        Write-Host ""
        Write-Host "============================================"
        Write-Host "MOOSE installed successfully!"
        Write-Host "Location: $mooseDir"
        Write-Host "============================================"
        Write-Host ""
        
        # Verify installation
        $mooseModules = Join-Path $mooseDir "Moose Development\Moose\Modules.lua"
        $mooseLoader = Join-Path $mooseDir "Moose Setup\Moose Templates\Moose_Dynamic_Loader.lua"
        
        if (Test-Path $mooseModules) {
            Write-Host "Verification: MOOSE Modules.lua found - Installation successful!"
            if (Test-Path $mooseLoader) {
                Write-Host "Verification: MOOSE Dynamic Loader found - Installation complete!"
            } else {
                Write-Host "Warning: Dynamic Loader not found, but core files are present."
            }
        } else {
            Write-Host "Warning: MOOSE Modules.lua not found. Installation may have failed."
            Write-Host "Please check the directory manually."
        }
    } else {
        Write-Host ""
        Write-Host "============================================"
        Write-Host "Installation failed!"
        Write-Host "Error: Could not find MOOSE folder in archive"
        Write-Host "============================================"
        Write-Host ""
        exit 1
    }
} catch {
    Write-Host ""
    Write-Host "============================================"
    Write-Host "Installation failed!"
    Write-Host "Error: $($_.Exception.Message)"
    Write-Host "============================================"
    Write-Host ""
    Write-Host "Please try manual installation:"
    Write-Host "1. Download MOOSE from: https://github.com/FlightControl-Master/MOOSE"
    Write-Host "2. Extract to: $mooseDir"
    Write-Host ""
    exit 1
}

Write-Host ""
Write-Host "Press any key to continue..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

