<#
.SYNOPSIS
    Windows file compliance: ensure required files and directories exist.

.DESCRIPTION
    Basic audit and remediate example for Windows using the File resource.
    Ensures a compliance marker directory and file exist — mirrors the Linux
    LinuxFileConfig example for comparison.

.NOTES
    Compile: pwsh -File windows-examples/WindowsFileCompliance.ps1
    Output:  ./WindowsFileCompliance/localhost.mof
#>

Configuration WindowsFileCompliance {
    Import-DscResource -ModuleName 'PSDesiredStateConfiguration'

    Node localhost {
        # Ensure compliance directory exists
        File ComplianceDir {
            Ensure          = 'Present'
            DestinationPath = 'C:\ProgramData\MachineConfig'
            Type            = 'Directory'
        }

        # Ensure compliance marker file exists with expected content
        File ComplianceMarker {
            Ensure          = 'Present'
            DestinationPath = 'C:\ProgramData\MachineConfig\compliance-marker.txt'
            Contents        = 'Managed by Azure Machine Configuration'
            Type            = 'File'
            DependsOn       = '[File]ComplianceDir'
        }
    }
}

WindowsFileCompliance
Write-Host "MOF compiled to ./WindowsFileCompliance/localhost.mof" -ForegroundColor Green
