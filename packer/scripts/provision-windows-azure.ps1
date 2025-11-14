# Windows provisioning script for Azure
Write-Host "Starting Windows custom provisioning for Azure..."

# Set timezone to UTC
Write-Host "Setting timezone to UTC..."
Set-TimeZone -Id "UTC"

# Install .NET Framework (if needed)
# Write-Host "Installing .NET Framework..."
# choco install -y dotnetfx

# Install PowerShell modules
Write-Host "Installing useful PowerShell modules..."
Install-Module -Name Az -Repository PSGallery -Force -AllowClobber

# Configure Windows Firewall
Write-Host "Configuring Windows Firewall..."
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True

# Disable IE Enhanced Security Configuration
Write-Host "Disabling IE Enhanced Security Configuration..."
$AdminKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"
$UserKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"
Set-ItemProperty -Path $AdminKey -Name "IsInstalled" -Value 0 -Force
Set-ItemProperty -Path $UserKey -Name "IsInstalled" -Value 0 -Force

# Enable Remote Desktop (optional)
# Write-Host "Enabling Remote Desktop..."
# Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -name "fDenyTSConnections" -value 0
# Enable-NetFirewallRule -DisplayGroup "Remote Desktop"

# Install Azure VM Agent extensions prerequisites
Write-Host "Configuring Azure VM Agent..."
# The Azure VM Agent is pre-installed on Azure marketplace images

# Install additional tools (customize as needed)
# Write-Host "Installing additional tools..."
# choco install -y notepadplusplus
# choco install -y sysinternals
# choco install -y vscode

# Set execution policy
Write-Host "Setting execution policy..."
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force

# Optimize performance
Write-Host "Optimizing performance settings..."
# Disable unnecessary services
# Set-Service -Name "DiagTrack" -StartupType Disabled
# Set-Service -Name "dmwappushservice" -StartupType Disabled

# Configure Windows Update settings
Write-Host "Configuring Windows Update..."
# Install-Module PSWindowsUpdate -Force
# Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "NoAutoUpdate" -Value 0

# Azure-specific configurations
Write-Host "Applying Azure-specific configurations..."
# Ensure Azure VM Agent is running
$service = Get-Service -Name "WindowsAzureGuestAgent" -ErrorAction SilentlyContinue
if ($service) {
    Set-Service -Name "WindowsAzureGuestAgent" -StartupType Automatic
    if ($service.Status -ne 'Running') {
        Start-Service -Name "WindowsAzureGuestAgent"
    }
}

Write-Host "Windows custom provisioning for Azure completed successfully!"
