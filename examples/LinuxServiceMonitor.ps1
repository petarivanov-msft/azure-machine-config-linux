<#
.SYNOPSIS
    Example: Ensure critical services are running and enabled.

.DESCRIPTION
    Machine Configuration policy that audits whether key services
    (sshd, auditd, fail2ban) are enabled and running on Linux VMs.
    Uses nxService resource from nxtools.

.NOTES
    Compile: pwsh -File examples/LinuxServiceMonitor.ps1
#>

Configuration LinuxServiceMonitor {
    Import-DscResource -ModuleName 'nxtools'

    Node localhost {
        nxService SSHDRunning {
            Name       = 'sshd'
            Enabled    = $true
            State      = 'Running'
            Controller = 'systemd'
        }

        nxService AuditdRunning {
            Name       = 'auditd'
            Enabled    = $true
            State      = 'Running'
            Controller = 'systemd'
        }

        # fail2ban — common intrusion prevention
        nxService Fail2BanRunning {
            Name       = 'fail2ban'
            Enabled    = $true
            State      = 'Running'
            Controller = 'systemd'
        }
    }
}

LinuxServiceMonitor
Write-Host "MOF compiled to ./LinuxServiceMonitor/localhost.mof" -ForegroundColor Green
