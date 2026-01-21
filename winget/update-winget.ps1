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
        # Capture stdout only, suppress stderr which contains progress indicators
        $updateOutput = winget upgrade --include-unknown --accept-source-agreements 2>$null
        
        # Filter out any remaining spinner/progress characters
        $cleanOutput = $updateOutput | Where-Object {
            $_ -and
            $_ -notmatch '^\s*[-\\|/]\s*$' -and
            $_ -notmatch '^[\s─━│┃┌┐└┘├┤┬┴┼╔╗╚╝╠╣╦╩╬═║╒╓╕╖╘╙╛╜╞╟╡╢╤╥╧╨╪╫■▪●◆◇○◌▫▬▭▮▯▰▱▲△▴▵▶▷▸▹►▻▼▽▾▿◀◁◂◃◄◅]+' -and
            $_ -notmatch '^\s*\d+\s*(KB|MB|GB)\s*/\s*[\d.]+\s*(KB|MB|GB)\s*$' -and
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
    $headerLine = $null
    $idColumnStart = -1
    $idColumnEnd = -1
    $inTableSection = $false
    
    foreach ($line in $lines) {
        # Find the header line to determine column positions
        if ($line -match "^Name\s+Id\s+Version\s+Available") {
            $headerLine = $line
            # Find the "Id" column position
            $idColumnStart = $headerLine.IndexOf("Id")
            # Find where the "Version" column starts (end of Id column)
            $versionIndex = $headerLine.IndexOf("Version")
            if ($versionIndex -gt $idColumnStart) {
                $idColumnEnd = $versionIndex
            }
            $inTableSection = $true
            continue
        }
        
        # Skip the separator line
        if ($line -match "^-{3,}") {
            continue
        }
        
        # Check if we've left the table section (empty line or footer text)
        if ($inTableSection -and $line.Trim() -eq "") {
            $inTableSection = $false
            continue
        }
        
        # Parse data lines using column positions
        if ($inTableSection -and $line.Trim() -ne "" -and 
            -not ($line -match "^\d+\s+upgrades? available") -and
            -not ($line -match "^No upgrades available") -and
            -not ($line -match "^To upgrade") -and
            -not ($line -match "^winget upgrade") -and
            $idColumnStart -ge 0) {
            
            # Extract the Id column value based on detected positions
            if ($line.Length -gt $idColumnStart) {
                $packageId = ""
                if ($idColumnEnd -gt $idColumnStart -and $line.Length -gt $idColumnEnd) {
                    # Extract substring between Id column start and Version column start
                    $packageId = $line.Substring($idColumnStart, $idColumnEnd - $idColumnStart).Trim()
                } else {
                    # If we can't find the end, try to extract the Id more carefully
                    $remainder = $line.Substring($idColumnStart).Trim()
                    # Take the first word that looks like a package ID
                    if ($remainder -match '^([\w-]+\.[\w.-]+|[\w][\w-]*)') {
                        $packageId = $matches[1]
                    }
                }
                
                # Validate that what we extracted looks like a valid package ID
                # Package IDs should contain dots (like VideoLAN.VLC) or be simple alphanumeric
                # They should NOT contain spaces or be version numbers
                if ($packageId -ne "" -and 
                    $packageId -ne "Id" -and 
                    -not ($packageId -match '^\d+\.\d+(\.\d+)*$') -and  # Not a version like "3.0.22" or "1.2.3.4"
                    -not ($packageId -match '\s') -and  # No spaces
                    ($packageId -match '^[\w-]+\.[\w.-]+$' -or $packageId -match '^[\w][\w-]*$')) {
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
