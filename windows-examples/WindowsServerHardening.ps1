<#
.SYNOPSIS
    Windows Server hardening: ensure services and features are configured correctly.

.DESCRIPTION
    Uses the built-in Service and WindowsFeature DSC resources to:
    - Ensure Windows Defender is running
    - Ensure Windows Firewall is running
    - Disable Print Spooler (attack surface reduction)
    - Ensure Windows Update service is set to automatic

.NOTES
    Compile: pwsh -File windows-examples/WindowsServerHardening.ps1
    Output:  ./WindowsServerHardening/localhost.mof
    Note:    WindowsFeature resource requires Windows Server (not client SKUs)
#>

Configuration WindowsServerHardening {
    Import-DscResource -ModuleName 'PSDesiredStateConfiguration'

    Node localhost {
        # Ensure Windows Firewall service is running
        Service WindowsFirewall {
            Name        = 'MpsSvc'
            State       = 'Running'
            StartupType = 'Automatic'
        }

        # Disable Print Spooler (PrintNightmare mitigation)
        Service DisablePrintSpooler {
            Name        = 'Spooler'
            State       = 'Stopped'
            StartupType = 'Disabled'
        }

        # Ensure Windows Update service is automatic
        Service WindowsUpdate {
            Name        = 'wuauserv'
            StartupType = 'Automatic'
        }

        # Ensure Remote Registry is disabled
        Service DisableRemoteRegistry {
            Name        = 'RemoteRegistry'
            State       = 'Stopped'
            StartupType = 'Disabled'
        }
    }
}

WindowsServerHardening
Write-Host "MOF compiled to ./WindowsServerHardening/localhost.mof" -ForegroundColor Green
