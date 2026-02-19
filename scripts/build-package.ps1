#Requires -Version 7.2

<#
.SYNOPSIS
    Compiles a DSC configuration and creates a Machine Configuration package.

.PARAMETER ConfigName
    Name of the configuration (must match the Configuration block name).

.PARAMETER ConfigPath
    Path to the .ps1 file containing the DSC configuration.

.PARAMETER PackageType
    Package type: Audit or AuditAndSet. Default: AuditAndSet.

.PARAMETER OutputPath
    Output directory for the package. Default: ./output

.EXAMPLE
    pwsh -File scripts/build-package.ps1 -ConfigName LinuxFileConfig -ConfigPath examples/LinuxFileConfig.ps1
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$ConfigName,

    [Parameter(Mandatory)]
    [string]$ConfigPath,

    [ValidateSet('Audit', 'AuditAndSet')]
    [string]$PackageType = 'AuditAndSet',

    [string]$OutputPath = './output'
)

$ErrorActionPreference = 'Stop'

Write-Host "=== Building Machine Configuration Package ===" -ForegroundColor Cyan
Write-Host "  Config:  $ConfigName"
Write-Host "  Source:  $ConfigPath"
Write-Host "  Type:    $PackageType"
Write-Host ""

# Step 1: Compile the MOF
Write-Host "[1/3] Compiling DSC configuration..." -ForegroundColor Yellow
Push-Location (Split-Path $ConfigPath -Parent)
. (Resolve-Path $ConfigPath)
Pop-Location

$mofPath = Join-Path $ConfigName "localhost.mof"
if (-not (Test-Path $mofPath)) {
    Write-Error "MOF not found at $mofPath — check Configuration block name matches ConfigName"
    exit 1
}

# Rename localhost.mof to match config name
$renamedMof = Join-Path $ConfigName "$ConfigName.mof"
Rename-Item -Path $mofPath -NewName "$ConfigName.mof" -Force
Write-Host "  MOF: $renamedMof" -ForegroundColor Green

# Step 2: Create the package
Write-Host "[2/3] Creating package artifact..." -ForegroundColor Yellow
$null = New-Item -Path $OutputPath -ItemType Directory -Force

$packageParams = @{
    Name          = $ConfigName
    Configuration = (Resolve-Path $renamedMof)
    Path          = $OutputPath
    Type          = $PackageType
    Force         = $true
}
$result = New-GuestConfigurationPackage @packageParams
Write-Host "  Package: $($result.Path)" -ForegroundColor Green

# Step 3: Verify
Write-Host "[3/3] Verifying package..." -ForegroundColor Yellow
$zipPath = Join-Path $OutputPath "$ConfigName" "$ConfigName.zip"
if (Test-Path $zipPath) {
    $size = (Get-Item $zipPath).Length / 1KB
    Write-Host "  Size: $([math]::Round($size, 1)) KB" -ForegroundColor Green
} else {
    # Try alternate path
    $zipPath = Join-Path $OutputPath "$ConfigName.zip"
    if (Test-Path $zipPath) {
        $size = (Get-Item $zipPath).Length / 1KB
        Write-Host "  Size: $([math]::Round($size, 1)) KB" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "Package built successfully." -ForegroundColor Green
Write-Host "Next: test locally with scripts/test-package.ps1" -ForegroundColor Cyan
