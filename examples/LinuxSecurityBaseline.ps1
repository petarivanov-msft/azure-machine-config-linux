<#
.SYNOPSIS
    Example: Linux security baseline checks via Machine Configuration.

.DESCRIPTION
    Audits and enforces basic security hardening on Linux VMs:
    - SSH config: disable root login, disable password auth
    - Ensure unattended-upgrades is configured
    - Ensure audit log directory exists

.NOTES
    Uses nxFile and nxFileLine resources from the nxtools module.
    Compile: pwsh -File examples/LinuxSecurityBaseline.ps1
#>

Configuration LinuxSecurityBaseline {
    Import-DscResource -ModuleName 'nxtools'

    Node localhost {
        # Ensure SSH does not permit root login
        nxFileLine SSHDisableRootLogin {
            FilePath              = '/etc/ssh/sshd_config'
            DoesNotContainPattern = '^PermitRootLogin\s+yes'
            ContainsLine          = 'PermitRootLogin no'
        }

        # Ensure password authentication is disabled (key-only)
        nxFileLine SSHDisablePasswordAuth {
            FilePath              = '/etc/ssh/sshd_config'
            DoesNotContainPattern = '^PasswordAuthentication\s+yes'
            ContainsLine          = 'PasswordAuthentication no'
        }

        # Ensure MaxAuthTries is set to 4
        nxFileLine SSHMaxAuthTries {
            FilePath              = '/etc/ssh/sshd_config'
            DoesNotContainPattern = '^MaxAuthTries\s+[5-9]|^MaxAuthTries\s+[0-9]{2,}'
            ContainsLine          = 'MaxAuthTries 4'
        }

        # Ensure unattended-upgrades config exists
        nxFile UnattendedUpgradesConfig {
            Ensure          = 'Present'
            DestinationPath = '/etc/apt/apt.conf.d/20auto-upgrades'
            Contents        = @"
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
"@
            Mode            = '0644'
            Type            = 'File'
        }

        # Ensure audit log directory exists with restricted permissions
        nxFile AuditLogDir {
            Ensure          = 'Present'
            DestinationPath = '/var/log/audit'
            Type            = 'Directory'
            Mode            = '0750'
        }
    }
}

LinuxSecurityBaseline
Write-Host "MOF compiled to ./LinuxSecurityBaseline/localhost.mof" -ForegroundColor Green
