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
        # Use --disable-interactivity to suppress progress bars
        $updateOutput = winget upgrade --include-unknown --disable-interactivity 2>&1
        
        # Filter out any remaining progress indicators or spinner characters
        $cleanOutput = $updateOutput | Where-Object { 
            $_ -notmatch '^\s*[-\\|/]\s*$' -and 
            $_ -notmatch '^[\s─━│┃┌┐└┘├┤┬┴┼╔╗╚╝╠╣╦╩╬═║╒╓╕╖╘╙╛╜╞╟╡╢╤╥╧╨╪╫■▪●◆◇○◌▫▬▭▮▯▰▱▲△▴▵▶▷▸▹►▻▼▽▾▿◀◁◂◃◄◅]' -and
            $_ -notmatch '^\s*\d+\s*(KB|MB|GB)\s*/\s*\d+' -and
            $_ -notmatch '^\s*\d+%\s*$'
        }
        
        $cleanOutputString = $cleanOutput -join "`n"
        Write-Host $cleanOutputString
        Write-Host ""
        return $cleanOutputString
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
        if ($line -match "^Name\s+Id\s+Version\s+Available" -or 
            $line -match "^-{3,}\s+-{3,}") {
            $inTableSection = $true
            continue
        }
        
        if ($inTableSection -and $line.Trim() -ne "" -and 
            -not ($line -match "^\d+\s+upgrades? available") -and
            -not ($line -match "^To upgrade") -and
            -not ($line -match "^winget upgrade")) {
            
            $parts = $line -split "\s{2,}"
            if ($parts.Count -ge 2) {
                $packageId = $parts[1].Trim()
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
    Show-Header
    
    if (-not (Test-WingetInstalled)) {
        exit 1
    }
    
    $updateOutput = Get-WingetUpdateOutput
    if ($null -eq $updateOutput) {
        exit 1
    }
    
    $packageIds = Parse-PackageIds -updateOutput $updateOutput
    Show-PackageIds -packageIds $packageIds
    Show-Footer
}

Main
