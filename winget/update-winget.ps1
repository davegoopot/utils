# Winget Auto-Updater Script
# This script runs winget update and lists all updateable package IDs

function Show-Header {
    Write-Host "====================================" -ForegroundColor Cyan
    Write-Host "  Winget Package Update Checker" -ForegroundColor Cyan
    Write-Host "====================================" -ForegroundColor Cyan
    Write-Host ""
}

function Test-WingetInstalled {
    try {
        $wingetVersion = winget --version
        Write-Host "Winget version: $wingetVersion" -ForegroundColor Green
        Write-Host ""
        return $true
    } catch {
        Write-Host "Error: Winget is not installed or not available in PATH" -ForegroundColor Red
        return $false
    }
}

function Get-WingetUpdateOutput {
    Write-Host "Checking for available updates..." -ForegroundColor Yellow
    Write-Host ""
    
    try {
        $updateOutput = winget upgrade --include-unknown 2>&1
        Write-Host $updateOutput
        Write-Host ""
        return $updateOutput
    } catch {
        Write-Host "Error running winget upgrade: $_" -ForegroundColor Red
        return $null
    }
}

function Parse-PackageIds {
    param (
        [string]$updateOutput
    )
    
    $lines = $updateOutput -split "`r?`n"
    $packageIds = @()
    $inTableSection = $false
    
    foreach ($line in $lines) {
        # Skip header lines and detect when we're in the table section
        if ($line -match "^Name\s+Id\s+Version\s+Available" -or 
            $line -match "^-{3,}\s+-{3,}") {
            $inTableSection = $true
            continue
        }
        
        # Once in table section, extract package IDs
        if ($inTableSection -and $line.Trim() -ne "" -and 
            -not ($line -match "^\d+\s+upgrades? available") -and
            -not ($line -match "^To upgrade") -and
            -not ($line -match "^winget upgrade")) {
            
            # Split by whitespace and look for the ID column (typically second column)
            $parts = $line -split "\s{2,}" # Split by 2+ spaces
            if ($parts.Count -ge 2) {
                $packageId = $parts[1].Trim()
                # Validate that this looks like a package ID (has at least one dot or is all alphanumeric with dashes)
                if ($packageId -ne "" -and $packageId -ne "Id" -and 
                    ($packageId -match '[\w-]+\.[\w-]+' -or $packageId -match '^[\w][\w-]*$')) {
                    $packageIds += $packageId
                }
            }
        }
    }
    
    return $packageIds
}

function Show-PackageIds {
    param (
        [array]$packageIds
    )
    
    Write-Host "====================================" -ForegroundColor Cyan
    Write-Host "  Updateable Package IDs" -ForegroundColor Cyan
    Write-Host "====================================" -ForegroundColor Cyan
    Write-Host ""
    
    foreach ($packageId in $packageIds) {
        Write-Host "  - $packageId" -ForegroundColor Green
    }
    
    Write-Host ""
    if ($packageIds.Count -gt 0) {
        Write-Host "Total updateable packages: $($packageIds.Count)" -ForegroundColor Yellow
    } else {
        Write-Host "No packages need updating or unable to parse package list." -ForegroundColor Green
    }
}

function Show-Footer {
    Write-Host ""
    Write-Host "====================================" -ForegroundColor Cyan
    Write-Host "Done!" -ForegroundColor Cyan
    Write-Host "====================================" -ForegroundColor Cyan
}

function Main {
    # Step 1: Display header
    Show-Header
    
    # Step 2: Check if winget is installed
    if (-not (Test-WingetInstalled)) {
        exit 1
    }
    
    # Step 3: Get winget update output
    $updateOutput = Get-WingetUpdateOutput
    if ($null -eq $updateOutput) {
        exit 1
    }
    
    # Step 4: Parse package IDs from output
    $packageIds = Parse-PackageIds -updateOutput $updateOutput
    
    # Step 5: Display package IDs
    Show-PackageIds -packageIds $packageIds
    
    # Step 6: Display footer
    Show-Footer
}

# Execute main function
Main
