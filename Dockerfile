FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV DOTNET_CLI_TELEMETRY_OPTOUT=1

# Install system dependencies + PowerShell 7 + OMI
RUN apt-get update && \
    apt-get install -y curl apt-transport-https software-properties-common && \
    curl -sSL https://packages.microsoft.com/keys/microsoft.asc | apt-key add - && \
    echo "deb [arch=amd64] https://packages.microsoft.com/repos/microsoft-ubuntu-jammy-prod jammy main" > /etc/apt/sources.list.d/microsoft.list && \
    apt-get update && \
    apt-get install -y powershell && \
    # Install OMI (provides libmi.so for PSDesiredStateConfiguration on Linux)
    curl -sL "https://github.com/microsoft/omi/releases/download/v1.9.1-0/omi-1.9.1-0.ssl_300.ulinux.s.x64.deb" -o /tmp/omi.deb && \
    dpkg -i /tmp/omi.deb && \
    rm /tmp/omi.deb && \
    ln -sf /opt/omi/lib/libmi.so /opt/microsoft/powershell/7/libmi.so 2>/dev/null || true && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Install PowerShell modules
RUN pwsh -Command " \
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted; \
    Install-Module -Name PSDesiredStateConfiguration -RequiredVersion 3.0.0-beta1 -AllowPrerelease -AllowClobber -Force -Scope AllUsers; \
    Install-Module -Name GuestConfiguration -AllowClobber -Force -Scope AllUsers; \
    Install-Module -Name nxtools -Force -Scope AllUsers; \
    Install-Module -Name Az.Accounts -AllowClobber -Force -Scope AllUsers; \
    Install-Module -Name Az.Storage -AllowClobber -Force -Scope AllUsers; \
    Install-Module -Name Az.Resources -AllowClobber -Force -Scope AllUsers"

# Copy DSC BaseRegistration schemas to where the Configuration keyword expects them
# PSDesiredStateConfiguration 3.x ships these files but the DSC parser looks in /etc/opt/omi/
RUN PSDSC_BASE="/usr/local/share/powershell/Modules/PSDesiredStateConfiguration/3.0.0/Configuration/BaseRegistration" && \
    mkdir -p /etc/opt/omi/conf/dsc/configuration/BaseRegistration && \
    cp -r "$PSDSC_BASE"/* /etc/opt/omi/conf/dsc/configuration/BaseRegistration/

WORKDIR /workspace
COPY examples/ ./examples/
COPY scripts/ ./scripts/
COPY docs/ ./docs/
COPY README.md .

CMD ["pwsh"]
