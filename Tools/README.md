# Tools

Scripts for installing and verifying MOOSE in this project.

## MOOSE installation

| Script | Description |
|--------|-------------|
| **install_moose.ps1** | Downloads MOOSE from GitHub and installs to `Scripts/MOOSE/` |
| **install_moose_manual.bat** | Opens the MOOSE repo and prints manual install steps |
| **verify_moose.bat** | Checks that MOOSE is present and correctly laid out |

**Run from repo root or from `Tools/`:**

```powershell
cd Tools
.\install_moose.ps1
```

```batch
cd Tools
verify_moose.bat
```

- `.ps1` requires PowerShell.
- `.bat` runs in Command Prompt.
