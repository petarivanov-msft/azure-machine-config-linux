<#
.SYNOPSIS
    Example DSC configuration for Azure Machine Configuration.
    Ensures a file exists at the specified path with the required content.

.DESCRIPTION
    This is a basic Machine Configuration example that demonstrates the
    Audit + Remediate pattern on Linux. It uses the nxFile resource from
    the nxtools module to manage file state.

.NOTES
    Compile: pwsh -File examples/LinuxFileConfig.ps1
    Output:  ./LinuxFileConfig/localhost.mof
#>

Configuration LinuxFileConfig {
    Import-DscResource -ModuleName 'nxtools'

    Node localhost {
        nxFile ComplianceMarker {
            Ensure          = 'Present'
            DestinationPath = '/etc/machine-config/compliance-marker.txt'
            Contents        = 'Managed by Azure Machine Configuration'
            Mode            = '0644'
            Type            = 'File'
        }

        nxFile ComplianceDir {
            Ensure          = 'Present'
            DestinationPath = '/etc/machine-config'
            Type            = 'Directory'
            Mode            = '0755'
        }
    }
}

# Compile the configuration
LinuxFileConfig
Write-Host "MOF compiled to ./LinuxFileConfig/localhost.mof" -ForegroundColor Green
