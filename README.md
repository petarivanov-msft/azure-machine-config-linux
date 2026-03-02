# Azure Machine Configuration — Authoring Environment

[![Test Configs](https://github.com/petarivanov-msft/azure-machine-config-linux/actions/workflows/test-configs.yml/badge.svg)](https://github.com/petarivanov-msft/azure-machine-config-linux/actions/workflows/test-configs.yml)
[![Docker Image](https://img.shields.io/docker/v/petariv/azure-machine-config-linux?label=Docker%20Hub&logo=docker)](https://hub.docker.com/r/petariv/azure-machine-config-linux)

A practical toolkit for authoring custom **Azure Machine Configuration** (formerly Guest Configuration) policies for **Linux and Windows** VMs. Includes environment setup, example DSC configurations, CI/CD pipelines, and end-to-end scripts to package, test, and publish custom policies.

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

The fastest way to get started — pull the pre-built image from Docker Hub:

```bash
docker pull petariv/azure-machine-config-linux
docker run -it --rm petariv/azure-machine-config-linux
```

Or build locally:

Skip all the setup steps. The included Dockerfile builds a container with PowerShell 7, OMI, and all required modules pre-installed.

### Build

```bash
docker build -t mc-authoring .
```

### Use

```bash
# Interactive shell
docker run -it --rm mc-authoring

# Compile an example
docker run --rm mc-authoring pwsh -File examples/LinuxFileConfig.ps1

# Mount your own configs
docker run -it --rm -v $(pwd)/my-configs:/workspace/configs mc-authoring
```

### What's Included

| Component | Version |
|-----------|---------|
| Ubuntu | 22.04 |
| PowerShell | 7.5.x |
| OMI | 1.9.1 (provides libmi.so) |
| GuestConfiguration | 4.11.0 |
| PSDesiredStateConfiguration | 3.0.0-beta1 |
| nxtools | 1.6.0 |
| Az.Accounts | latest |
| Az.Storage | latest |
| Az.Resources | latest |

> **Note:** OMI and the DSC BaseRegistration schemas are pre-configured — the `Configuration` keyword works out of the box, which is the tricky part of setting up Linux authoring manually.

## Windows Examples

| Example | Description |
|---------|-------------|
| `WindowsSecurityBaseline` | Registry hardening: disable SMBv1, require NLA for RDP, disable autorun, audit logon events |
| `WindowsServerHardening` | Service management: firewall, Print Spooler (PrintNightmare), Windows Update, Remote Registry |
| `WindowsFileCompliance` | File/directory compliance marker — mirrors LinuxFileConfig for cross-platform comparison |

## CI/CD Pipeline

Every push to `main` automatically runs a **matrix build** across Linux and Windows:

```
┌─────────────────────────────────────────────────┐
│               GitHub Actions                     │
│                                                  │
│  ┌──────────────┐       ┌──────────────────┐    │
│  │ Linux Job     │       │ Windows Job       │    │
│  │ (container:   │       │ (windows-latest)  │    │
│  │  Docker image)│       │                   │    │
│  │              │       │                   │    │
│  │ 1. Compile   │       │ 1. Install modules│    │
│  │ 2. Package   │       │ 2. Compile        │    │
│  │ 3. Audit     │       │ 3. Package        │    │
│  │ 4. Remediate │       │ 4. Audit          │    │
│  │ 5. Re-audit  │       │ 5. Remediate      │    │
│  │    ✓ Pass    │       │ 6. Re-audit       │    │
│  └──────────────┘       │    ✓ Pass         │    │
│                         └──────────────────┘    │
└─────────────────────────────────────────────────┘
```

Both jobs test the **full lifecycle**: compile → package → audit (non-compliant) → remediate → audit (compliant).

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
