#Requires -Version 7.2

<#
.SYNOPSIS
    Sets up the authoring environment for Azure Machine Configuration on Linux.

.DESCRIPTION
    Installs all required PowerShell modules for authoring, packaging, testing,
    and publishing custom Machine Configuration policies for Linux systems.

.NOTES
    Run from PowerShell 7: pwsh -File setup-authoring-env.ps1
    Requires internet access for module downloads from PSGallery.
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

Write-Host "=== Azure Machine Configuration — Authoring Environment Setup ===" -ForegroundColor Cyan
Write-Host ""

# Check PowerShell version
$minVersion = [Version]"7.2.4"
if ($PSVersionTable.PSVersion -lt $minVersion) {
    Write-Error "PowerShell $minVersion or later is required. Current: $($PSVersionTable.PSVersion)"
    exit 1
}
Write-Host "[OK] PowerShell $($PSVersionTable.PSVersion)" -ForegroundColor Green

# Install PSDesiredStateConfiguration (prerelease for Linux)
Write-Host ""
Write-Host "Installing PSDesiredStateConfiguration 3.0.0-beta1 (required for Linux)..." -ForegroundColor Yellow
Install-Module -Name PSDesiredStateConfiguration `
    -RequiredVersion 3.0.0-beta1 `
    -Repository PSGallery `
    -AllowPrerelease `
    -AllowClobber `
    -Force `
    -Scope CurrentUser

# Install GuestConfiguration module
Write-Host "Installing GuestConfiguration module..." -ForegroundColor Yellow
Install-Module -Name GuestConfiguration `
    -Repository PSGallery `
    -AllowClobber `
    -Force `
    -Scope CurrentUser

# Install nxtools (Linux DSC resources)
Write-Host "Installing nxtools (Linux DSC resources)..." -ForegroundColor Yellow
Install-Module -Name nxtools `
    -Repository PSGallery `
    -Force `
    -Scope CurrentUser

# Install Az modules for publishing
Write-Host "Installing Az modules (Accounts, Storage, Resources)..." -ForegroundColor Yellow
Install-Module -Name Az.Accounts -AllowClobber -Force -Scope CurrentUser
Install-Module -Name Az.Storage -AllowClobber -Force -Scope CurrentUser
Install-Module -Name Az.Resources -AllowClobber -Force -Scope CurrentUser

# Verify installation
Write-Host ""
Write-Host "=== Installed Module Versions ===" -ForegroundColor Cyan
$modules = @('PSDesiredStateConfiguration', 'GuestConfiguration', 'nxtools', 'Az.Accounts', 'Az.Storage', 'Az.Resources')
foreach ($mod in $modules) {
    $installed = Get-Module -ListAvailable -Name $mod | Sort-Object Version -Descending | Select-Object -First 1
    if ($installed) {
        Write-Host "  $($mod): $($installed.Version)" -ForegroundColor Green
    } else {
        Write-Host "  $($mod): NOT FOUND" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Setup complete. You can now author Machine Configuration packages." -ForegroundColor Green
