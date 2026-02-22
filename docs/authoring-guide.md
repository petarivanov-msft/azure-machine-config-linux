# Machine Configuration Authoring Guide — Linux

Step-by-step guide for creating, testing, and deploying custom Azure Machine Configuration policies on Linux.

## Background

Azure Machine Configuration (formerly Guest Configuration) extends Azure Policy to audit and enforce settings *inside* virtual machines and Arc-enabled servers. On Linux, it uses PowerShell DSC with the `nxtools` module for resource management.

> **Naming note:** The service was rebranded from "Guest Configuration" to "Machine Configuration" under Azure Automanage. The PowerShell module is still called `GuestConfiguration` for backwards compatibility.

## Prerequisites

| Requirement | Version |
|-------------|---------|
| Ubuntu | 20.04+ |
| PowerShell | 7.2.4+ |
| GuestConfiguration module | 4.7.0+ |
| PSDesiredStateConfiguration | 3.0.0-beta1 |
| nxtools module | latest |
| Az.Accounts | latest |
| Az.Storage | latest |
| Az.Resources | latest |

Run `scripts/setup-authoring-env.ps1` to install everything.

## Step 1: Author the Configuration

Create a `.ps1` file with a `Configuration` block. Example:

```powershell
Configuration MyLinuxConfig {
    Import-DscResource -ModuleName 'nxtools'

    Node localhost {
        nxFile ExampleFile {
            Ensure          = 'Present'
            DestinationPath = '/tmp/example.txt'
            Contents        = 'Hello from Machine Configuration'
            Mode            = '0644'
            Type            = 'File'
        }
    }
}

MyLinuxConfig
```

### Key Rules

1. **Node name must be `localhost`** — Machine Configuration always targets the local machine.
2. **Use `nxtools` resources** for Linux (nxFile, nxFileLine, nxService, nxUser, nxGroup, etc.).
3. **Don't include secrets** in the configuration — use Azure Policy parameters instead.
4. **One configuration per package** — each package maps to one policy definition.

### Available nxtools Resources

| Resource | Purpose |
|----------|---------|
| `nxFile` | Manage files and directories (content, permissions, ownership) |
| `nxFileLine` | Ensure lines exist/don't exist in config files |
| `nxService` | Manage systemd services (running, enabled) |
| `nxUser` | Manage local user accounts |
| `nxGroup` | Manage local groups |
| `nxPackage` | Manage apt/yum packages |

## Step 2: Compile the MOF

```bash
pwsh -File examples/LinuxFileConfig.ps1
```

This creates `./LinuxFileConfig/localhost.mof`. The build script handles renaming automatically.

## Step 3: Build the Package

```bash
pwsh -File scripts/build-package.ps1 \
    -ConfigName LinuxFileConfig \
    -ConfigPath examples/LinuxFileConfig.ps1 \
    -PackageType AuditAndSet
```

Output: `./output/LinuxFileConfig/LinuxFileConfig.zip`

### Package Types

| Type | Behaviour |
|------|-----------|
| `Audit` | Reports non-compliance only; no changes made |
| `AuditAndSet` | Reports and can remediate (depends on policy assignment mode) |

## Step 4: Test Locally

```bash
# Check compliance (read-only)
sudo pwsh -File scripts/test-package.ps1 \
    -PackagePath ./output/LinuxFileConfig/LinuxFileConfig.zip

# Apply remediation
sudo pwsh -File scripts/test-package.ps1 \
    -PackagePath ./output/LinuxFileConfig/LinuxFileConfig.zip \
    -Remediate
```

> Run as `root` — the Machine Configuration agent runs as root in Azure, so local testing should match.

## Step 5: Publish and Create Policy

```bash
pwsh -File scripts/publish-and-assign.ps1 \
    -PackagePath ./output/LinuxFileConfig/LinuxFileConfig.zip \
    -ConfigName LinuxFileConfig \
    -StorageAccountName mystorageacct \
    -ResourceGroupName myRG \
    -PolicyDisplayName "Ensure compliance marker file exists" \
    -PolicyMode ApplyAndAutoCorrect
```

This will:
1. Upload the `.zip` to Azure Blob Storage
2. Generate a SAS URI (5-year expiry)
3. Create an Azure Policy definition
4. Output the assignment command

## Step 6: Assign the Policy

Via Azure Portal:
1. Go to **Azure Policy** → **Definitions**
2. Find your custom definition
3. Click **Assign** → select scope → configure parameters

Via PowerShell:
```powershell
$definition = Get-AzPolicyDefinition -Name 'LinuxFileConfig'
New-AzPolicyAssignment `
    -Name 'LinuxFileConfig' `
    -PolicyDefinition $definition `
    -Scope '/subscriptions/<subscription-id>'
```

## Using Policy Parameters

For reusable configs, define parameters at the policy level:

```powershell
$paramInfo = @(
    @{
        ResourceType         = 'nxFile'
        ResourceId           = 'ComplianceMarkerInstanceName'
        ResourcePropertyName = 'Contents'
        Name                 = 'FileContents'
        DisplayName          = 'File Contents'
        Description          = 'Content to write to the compliance marker file'
        DefaultValue         = 'Default content'
    }
)

New-GuestConfigurationPolicy @policyParams -Parameter $paramInfo
```

This allows different assignments to use different values without rebuilding the package.

## Troubleshooting

| Issue | Fix |
|-------|-----|
| `MOF not found` | Check Configuration block name matches `-ConfigName` |
| `Module not found` during compile | Run `setup-authoring-env.ps1` again |
| Compliance always non-compliant | Test locally first; check file paths and permissions |
| Package too large | Minimize included module dependencies |
| Policy not evaluating | Allow 15-30 minutes; check VM extension status |

## Useful Links

- [Machine Configuration overview](https://learn.microsoft.com/en-us/azure/governance/machine-configuration/overview)
- [Custom package development](https://learn.microsoft.com/en-us/azure/governance/machine-configuration/how-to/develop-custom-package/overview)
- [nxtools module](https://www.powershellgallery.com/packages/nxtools)
- [GuestConfiguration module](https://www.powershellgallery.com/packages/GuestConfiguration)
