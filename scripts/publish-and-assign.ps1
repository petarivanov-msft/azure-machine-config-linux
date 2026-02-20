#Requires -Version 7.2

<#
.SYNOPSIS
    Publishes a Machine Configuration package to Azure Storage and creates a policy definition.

.PARAMETER PackagePath
    Path to the .zip package file.

.PARAMETER ConfigName
    Configuration name (used for policy naming).

.PARAMETER StorageAccountName
    Azure Storage account name (must exist, lowercase, 3-24 chars).

.PARAMETER StorageContainerName
    Blob container name. Default: guestconfiguration.

.PARAMETER ResourceGroupName
    Resource group containing the storage account.

.PARAMETER PolicyDisplayName
    Friendly name for the Azure Policy definition.

.PARAMETER PolicyDescription
    Description for the Azure Policy definition.

.PARAMETER PolicyMode
    Policy enforcement mode. Default: ApplyAndAutoCorrect.

.EXAMPLE
    pwsh -File scripts/publish-and-assign.ps1 `
        -PackagePath ./output/LinuxFileConfig/LinuxFileConfig.zip `
        -ConfigName LinuxFileConfig `
        -StorageAccountName mystorageacct `
        -ResourceGroupName myRG `
        -PolicyDisplayName "Ensure compliance marker file exists"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$PackagePath,

    [Parameter(Mandatory)]
    [string]$ConfigName,

    [Parameter(Mandatory)]
    [string]$StorageAccountName,

    [string]$StorageContainerName = 'guestconfiguration',

    [Parameter(Mandatory)]
    [string]$ResourceGroupName,

    [string]$PolicyDisplayName = "Machine Config - $ConfigName",

    [string]$PolicyDescription = "Custom Machine Configuration policy: $ConfigName",

    [ValidateSet('Audit', 'ApplyAndMonitor', 'ApplyAndAutoCorrect')]
    [string]$PolicyMode = 'ApplyAndAutoCorrect'
)

$ErrorActionPreference = 'Stop'

Write-Host "=== Publishing Machine Configuration Package ===" -ForegroundColor Cyan

# Step 1: Authenticate
Write-Host "[1/4] Authenticating to Azure..." -ForegroundColor Yellow
$context = Get-AzContext
if (-not $context) {
    Connect-AzAccount -UseDeviceAuthentication
}
Write-Host "  Subscription: $((Get-AzContext).Subscription.Name)" -ForegroundColor Green

# Step 2: Upload to blob storage
Write-Host "[2/4] Uploading package to Azure Storage..." -ForegroundColor Yellow
$storageKey = (Get-AzStorageAccountKey -ResourceGroupName $ResourceGroupName -Name $StorageAccountName)[0].Value
$storageContext = New-AzStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $storageKey

# Ensure container exists
$null = Get-AzStorageContainer -Name $StorageContainerName -Context $storageContext -ErrorAction SilentlyContinue
if (-not $?) {
    New-AzStorageContainer -Name $StorageContainerName -Context $storageContext -Permission Blob | Out-Null
    Write-Host "  Created container: $StorageContainerName" -ForegroundColor Green
}

Set-AzStorageBlobContent -Container $StorageContainerName `
    -File $PackagePath `
    -Blob "$ConfigName.zip" `
    -Context $storageContext `
    -Force | Out-Null
Write-Host "  Uploaded: $ConfigName.zip" -ForegroundColor Green

# Generate SAS token (5-year expiry)
$sasParams = @{
    ExpiryTime = (Get-Date).AddYears(5)
    Container  = $StorageContainerName
    Blob       = "$ConfigName.zip"
    Permission = 'r'
    Context    = $storageContext
    FullUri    = $true
    StartTime  = (Get-Date)
}
$contentUri = New-AzStorageBlobSASToken @sasParams
Write-Host "  SAS URI generated (5-year expiry)" -ForegroundColor Green

# Step 3: Create policy definition
Write-Host "[3/4] Creating Azure Policy definition..." -ForegroundColor Yellow
$policyId = (New-Guid).Guid
$policyPath = "./output/$ConfigName/policies"

$policyParams = @{
    PolicyId    = $policyId
    ContentUri  = $contentUri
    DisplayName = $PolicyDisplayName
    Description = "$PolicyDescription — $(Get-Date -Format 'yyyy-MM-dd')"
    Path        = $policyPath
    Platform    = 'Linux'
    PolicyVersion = '1.0.0'
    Mode        = $PolicyMode
    Verbose     = $true
}
$policy = New-GuestConfigurationPolicy @policyParams
Write-Host "  Policy JSON: $($policy.Path)" -ForegroundColor Green

# Step 4: Publish the policy definition
Write-Host "[4/4] Publishing policy definition to Azure..." -ForegroundColor Yellow
New-AzPolicyDefinition -Name $ConfigName -Policy $policy.Path | Out-Null
Write-Host "  Published: $ConfigName" -ForegroundColor Green

Write-Host ""
Write-Host "Done! Assign the policy in the Azure Portal or via:" -ForegroundColor Cyan
Write-Host "  New-AzPolicyAssignment -Name '$ConfigName' -PolicyDefinition (Get-AzPolicyDefinition -Name '$ConfigName') -Scope '/subscriptions/<sub-id>'" -ForegroundColor White
