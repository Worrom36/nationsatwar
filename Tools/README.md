# Development Tools

This folder contains utility scripts for managing the Territorial Conquest development environment.

## MOOSE Installation

### Automatic Installation
**`install_moose.ps1`** - Automatically downloads and installs MOOSE framework
- Downloads latest MOOSE from GitHub
- Extracts to `Scripts/MOOSE/`
- Verifies installation
- Handles existing installations (prompts before overwriting)

**Usage:**
```powershell
cd Tools
.\install_moose.ps1
```

### Manual Installation Helper
**`install_moose_manual.bat`** - Opens browser and provides manual installation instructions
- Opens MOOSE GitHub page
- Provides step-by-step instructions
- Verifies installation after completion

**Usage:**
```batch
cd Tools
install_moose_manual.bat
```

### Verification
**`verify_moose.bat`** - Verifies MOOSE installation
- Checks for required files
- Verifies directory structure
- Reports installation status

**Usage:**
```batch
cd Tools
verify_moose.bat
```

## Notes

- Batch files (.bat) work in Command Prompt
- PowerShell scripts (.ps1) require PowerShell
- All scripts should be run from the `Tools/` directory or with proper paths

