# utils
Personal automation scripts

## Tools

### Winget Updater (Work in Progress)
Located in `winget/update-winget.ps1` - PowerShell script that checks for available winget package updates and lists updateable package IDs.

**Usage:**
```powershell
.\winget\update-winget.ps1
```

This script will:
- Check if winget is installed
- Run `winget upgrade` to find available updates
- Display all packages that have updates available
- List the package IDs of updateable packages
