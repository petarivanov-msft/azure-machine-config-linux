# Azure Machine Configuration — Linux Authoring Environment

[![Test Configs](https://github.com/petarivanov-msft/azure-machine-config-linux/actions/workflows/test-configs.yml/badge.svg)](https://github.com/petarivanov-msft/azure-machine-config-linux/actions/workflows/test-configs.yml)
[![Docker Image](https://img.shields.io/docker/v/petariv/azure-machine-config-linux?label=Docker%20Hub&logo=docker)](https://hub.docker.com/r/petariv/azure-machine-config-linux)

A practical toolkit for authoring custom **Azure Machine Configuration** (formerly Guest Configuration) policies for **Linux** VMs. Includes example DSC configurations, a CI/CD pipeline with full lifecycle testing, and scripts to package, test, and publish custom policies. Uses a pre-built Docker container for the authoring environment — see [azure-machine-config-container](https://github.com/petarivanov-msft/azure-machine-config-container).

> **Looking for Windows?** See [azure-machine-config-windows](https://github.com/petarivanov-msft/azure-machine-config-windows) — native PowerShell setup, no Docker needed.
>
> **Container image:** See [azure-machine-config-container](https://github.com/petarivanov-msft/azure-machine-config-container) for the Dockerfile and container docs.

## Overview

Azure Machine Configuration uses PowerShell Desired State Configuration (DSC) to audit and enforce settings on Azure VMs and Arc-enabled servers. This repo walks through setting up the authoring environment on Linux (Ubuntu 20+) and creating a custom policy that:

1. Ensures a specific file exists with required content
2. Packages the configuration as a `.zip` artifact
3. Tests compliance locally before deploying
4. Publishes to Azure Storage and creates a policy definition

## Prerequisites

- Ubuntu 20.04 or later (authoring machine)
- Azure subscription with Contributor access
- PowerShell 7.2.4 or later

## Quick Start

```bash
# 1. Install PowerShell 7 (if not already installed)
sudo apt-get update
sudo apt-get install -y powershell

# 2. Run the setup script to install required modules
pwsh -File scripts/setup-authoring-env.ps1

# 3. Author your configuration (see examples/)
# 4. Package, test, and publish (see scripts/)
```

## Repository Structure

```
.
├── README.md
├── examples/
│   ├── LinuxFileConfig.ps1          # Example: ensure file exists with content
│   └── LinuxSecurityBaseline.ps1    # Example: basic security hardening checks
├── scripts/
│   ├── setup-authoring-env.ps1      # Install all required PowerShell modules
│   ├── build-package.ps1            # Compile MOF and create .zip package
│   ├── test-package.ps1             # Test compliance locally
│   └── publish-and-assign.ps1       # Publish to Azure Storage + create policy
├── .gitignore
└── docs/
    └── authoring-guide.md           # Detailed walkthrough
```

## Key Concepts

### Machine Configuration vs Guest Configuration

Azure **Guest Configuration** was renamed to **Azure Machine Configuration** as part of the Azure Automanage rebranding. The PowerShell module is still called `GuestConfiguration` for backwards compatibility, but the service name in the portal and documentation is "Machine Configuration".

### How It Works

1. **Author** a DSC configuration using PowerShell classes or DSC resources
2. **Compile** the configuration into a MOF file
3. **Package** the MOF and dependencies into a `.zip` using `New-GuestConfigurationPackage`
4. **Test** locally with `Get-GuestConfigurationPackageComplianceStatus`
5. **Publish** the package to Azure Blob Storage
6. **Create** an Azure Policy definition referencing the package
7. **Assign** the policy to a scope (subscription, resource group, management group)

### Policy Modes

| Mode | Behaviour |
|------|-----------|
| `Audit` | Reports compliance without making changes |
| `ApplyAndMonitor` | Applies configuration once, then monitors for drift |
| `ApplyAndAutoCorrect` | Applies configuration and automatically remediates drift |

## Module Versions

| Module | Version | Notes |
|--------|---------|-------|
| PowerShell | 7.2.4+ | Required for Linux authoring |
| GuestConfiguration | 4.7.0 | Latest stable |
| PSDesiredStateConfiguration | 3.0.0-beta1 | Required for Linux (prerelease) |
| nxtools | latest | Linux DSC resources (file, service, user, etc.) |
| Az.Accounts | latest | Azure authentication |
| Az.Storage | latest | Blob upload for packages |
| Az.Resources | latest | Policy definition management |

## References

- [Machine Configuration overview](https://learn.microsoft.com/en-us/azure/governance/machine-configuration/overview)
- [Develop custom packages](https://learn.microsoft.com/en-us/azure/governance/machine-configuration/how-to/develop-custom-package/overview)
- [Set up authoring environment](https://learn.microsoft.com/en-us/azure/governance/machine-configuration/how-to/develop-custom-package/1-set-up-authoring-environment)
- [Create policy definitions](https://learn.microsoft.com/en-us/azure/governance/machine-configuration/how-to/create-policy-definition)
- [GuestConfiguration PowerShell module](https://www.powershellgallery.com/packages/GuestConfiguration)

## License

MIT

## Docker — Ready-to-Use Authoring Environment

[![Docker Image](https://img.shields.io/docker/v/petariv/azure-machine-config-linux?label=Docker%20Hub&logo=docker)](https://hub.docker.com/r/petariv/azure-machine-config-linux)

A pre-built Docker image is available on Docker Hub — PowerShell 7, OMI, and all required modules pre-installed:

```bash
docker pull petariv/azure-machine-config-linux
docker run -it --rm petariv/azure-machine-config-linux
```

The Dockerfile and full container documentation (including a guide for setting up the authoring environment without Docker) live in the dedicated container repo:

**[azure-machine-config-container](https://github.com/petarivanov-msft/azure-machine-config-container)**

## CI/CD Pipeline

Every push to `main` automatically runs a **matrix build** on Linux:

```
Compile → Package → Audit (non-compliant) → Remediate → Audit (compliant) ✓
```

Tests the **full lifecycle** inside the Docker container — no host dependencies needed.

### Optional: Deploy to Azure

A separate **manual workflow** (`Deploy to Azure`) can publish packages to Azure Storage and assign them as policies. To use it:

1. **Create a service principal:**
   ```bash
   az ad sp create-for-rbac --name "mc-github-deploy" \
     --role "Resource Policy Contributor" \
     --scopes /subscriptions/<subscription-id> \
     --sdk-auth
   ```

2. **Add the JSON output as a GitHub secret** named `AZURE_CREDENTIALS`

3. **Create a storage account** for package hosting (update `STORAGE_ACCOUNT` in the workflow)

4. **Trigger the workflow** from the Actions tab — pick your config, mode, and target resource group

The pipeline will compile, package, upload to blob storage, create the policy definition, and assign it.
