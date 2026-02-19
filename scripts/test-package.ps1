#Requires -Version 7.2

<#
.SYNOPSIS
    Tests a Machine Configuration package locally.

.DESCRIPTION
    Runs compliance check and optionally applies remediation against
    the local machine. Must be run as root on Linux.

.PARAMETER PackagePath
    Path to the .zip package file.

.PARAMETER Remediate
    If set, applies the configuration (Set) instead of just checking compliance.

.EXAMPLE
    sudo pwsh -File scripts/test-package.ps1 -PackagePath ./output/LinuxFileConfig/LinuxFileConfig.zip
    sudo pwsh -File scripts/test-package.ps1 -PackagePath ./output/LinuxFileConfig/LinuxFileConfig.zip -Remediate
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$PackagePath,

    [switch]$Remediate
)

$ErrorActionPreference = 'Stop'

# Check running as root (required for accurate testing)
if ($IsLinux -and (id -u) -ne 0) {
    Write-Warning "Testing should be run as root for accurate results. Use: sudo pwsh -File ..."
}

if (-not (Test-Path $PackagePath)) {
    Write-Error "Package not found: $PackagePath"
    exit 1
}

Write-Host "=== Testing Machine Configuration Package ===" -ForegroundColor Cyan
Write-Host "  Package: $PackagePath"
Write-Host ""

# Compliance check
Write-Host "[Test] Checking compliance status..." -ForegroundColor Yellow
$compliance = Get-GuestConfigurationPackageComplianceStatus -Path $PackagePath -Verbose
Write-Host ""

foreach ($resource in $compliance.Resources) {
    $color = if ($resource.ComplianceStatus -eq $true) { 'Green' } else { 'Red' }
    $status = if ($resource.ComplianceStatus -eq $true) { 'Compliant' } else { 'Non-Compliant' }
    Write-Host "  $($resource.ResourceName): $status" -ForegroundColor $color
}

Write-Host ""
$overallColor = if ($compliance.ComplianceStatus -eq 'Compliant') { 'Green' } else { 'Yellow' }
Write-Host "  Overall: $($compliance.ComplianceStatus)" -ForegroundColor $overallColor

# Remediation
if ($Remediate) {
    Write-Host ""
    Write-Host "[Remediate] Applying configuration..." -ForegroundColor Yellow
    Start-GuestConfigurationPackageRemediation -Path $PackagePath -Verbose

    Write-Host ""
    Write-Host "[Verify] Re-checking compliance after remediation..." -ForegroundColor Yellow
    $postCheck = Get-GuestConfigurationPackageComplianceStatus -Path $PackagePath
    $postColor = if ($postCheck.ComplianceStatus -eq 'Compliant') { 'Green' } else { 'Red' }
    Write-Host "  Overall: $($postCheck.ComplianceStatus)" -ForegroundColor $postColor
}
