<#
.SYNOPSIS
    Windows security baseline: audit and enforce registry-based security settings.

.DESCRIPTION
    Uses the built-in Registry DSC resource to check and remediate common
    Windows hardening settings:
    - Disable SMBv1
    - Enable NLA for RDP
    - Disable autorun on all drives
    - Configure audit policy for logon events

.NOTES
    Compile: pwsh -File windows-examples/WindowsSecurityBaseline.ps1
    Output:  ./WindowsSecurityBaseline/localhost.mof
#>

Configuration WindowsSecurityBaseline {
    Import-DscResource -ModuleName 'PSDscResources'

    Node localhost {
        # Disable SMBv1 (WannaCry mitigation)
        Registry DisableSMBv1 {
            Key       = 'HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters'
            ValueName = 'SMB1'
            ValueType = 'Dword'
            ValueData = '0'
            Ensure    = 'Present'
        }

        # Require NLA for Remote Desktop
        Registry RequireNLA {
            Key       = 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp'
            ValueName = 'UserAuthentication'
            ValueType = 'Dword'
            ValueData = '1'
            Ensure    = 'Present'
        }

        # Disable autorun on all drives
        Registry DisableAutorun {
            Key       = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer'
            ValueName = 'NoDriveTypeAutoRun'
            ValueType = 'Dword'
            ValueData = '255'
            Ensure    = 'Present'
        }

        # Enable audit of logon events (success + failure)
        Registry AuditLogonEvents {
            Key       = 'HKLM:\SYSTEM\CurrentControlSet\Services\EventLog\Security'
            ValueName = 'AuditLogonEvents'
            ValueType = 'Dword'
            ValueData = '3'
            Ensure    = 'Present'
        }

        # Restrict anonymous access to named pipes and shares
        Registry RestrictAnonymous {
            Key       = 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa'
            ValueName = 'RestrictAnonymous'
            ValueType = 'Dword'
            ValueData = '1'
            Ensure    = 'Present'
        }
    }
}

WindowsSecurityBaseline
Write-Host "MOF compiled to ./WindowsSecurityBaseline/localhost.mof" -ForegroundColor Green
