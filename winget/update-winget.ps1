# Winget Auto-Updater Script
# This script runs winget update and lists all updateable package IDs

Write-Host "====================================" -ForegroundColor Cyan
Write-Host "  Winget Package Update Checker" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan
Write-Host ""

# Check if winget is available
try {
    $wingetVersion = winget --version
    Write-Host "Winget version: $wingetVersion" -ForegroundColor Green
    Write-Host ""
} catch {
    Write-Host "Error: Winget is not installed or not available in PATH" -ForegroundColor Red
    exit 1
}

Write-Host "Checking for available updates..." -ForegroundColor Yellow
Write-Host ""

# Run winget upgrade to get list of available updates
# Using --include-unknown to also show packages that might have updates from unknown sources
try {
    $updateOutput = winget upgrade --include-unknown 2>&1
    
    # Display the full output
    Write-Host $updateOutput
    Write-Host ""
    
    # Parse the output to extract package IDs
    Write-Host "====================================" -ForegroundColor Cyan
    Write-Host "  Updateable Package IDs" -ForegroundColor Cyan
    Write-Host "====================================" -ForegroundColor Cyan
    Write-Host ""
    
    # Split output into lines and look for lines with package information
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
                    Write-Host "  - $packageId" -ForegroundColor Green
                }
            }
        }
    }
    
    Write-Host ""
    if ($packageIds.Count -gt 0) {
        Write-Host "Total updateable packages: $($packageIds.Count)" -ForegroundColor Yellow
    } else {
        Write-Host "No packages need updating or unable to parse package list." -ForegroundColor Green
    }
    
} catch {
    Write-Host "Error running winget upgrade: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "====================================" -ForegroundColor Cyan
Write-Host "Done!" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan
