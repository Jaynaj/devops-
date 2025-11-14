# Packer template for building Azure Windows Managed Image
packer {
  required_plugins {
    azure = {
      version = ">= 2.0.0"
      source  = "github.com/hashicorp/azure"
    }
  }
}

# Build configuration for Azure Windows
source "azure-arm" "windows" {
  # Authentication
  subscription_id = var.azure_subscription_id
  client_id       = var.azure_client_id
  client_secret   = var.azure_client_secret
  tenant_id       = var.azure_tenant_id

  # Resource group and location
  managed_image_resource_group_name = var.azure_resource_group
  location                          = var.azure_location

  # Image details
  managed_image_name = "${var.image_name_prefix}-azure-windows-${var.environment}-{{timestamp}}"

  # Source image - Windows Server 2022
  image_publisher = var.azure_windows_image_publisher
  image_offer     = var.azure_windows_image_offer
  image_sku       = var.azure_windows_image_sku

  # VM configuration
  vm_size = var.azure_windows_vm_size

  # OS disk
  os_type         = "Windows"
  os_disk_size_gb = 128

  # WinRM communicator
  communicator   = "winrm"
  winrm_use_ssl  = true
  winrm_insecure = true
  winrm_timeout  = "5m"
  winrm_username = var.azure_winrm_username

  # Tags
  azure_tags = {
    Name        = "${var.image_name_prefix}-azure-windows-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
    BuildDate   = "{{timestamp}}"
    ManagedBy   = "Packer"
    Cloud       = "Azure"
    OS          = "Windows"
    OSVersion   = "2022"
  }
}

# Build steps
build {
  name = "azure-windows"
  sources = [
    "source.azure-arm.windows"
  ]

  # Wait for system to be ready
  provisioner "powershell" {
    inline = [
      "Write-Host 'Waiting for system to be ready...'",
      "Start-Sleep -Seconds 30"
    ]
  }

  # Update Windows
  provisioner "powershell" {
    inline = [
      "Write-Host 'Installing Windows Updates...'",
      "Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force",
      "Install-Module PSWindowsUpdate -Force",
      "Import-Module PSWindowsUpdate",
      "Get-WindowsUpdate -AcceptAll -Install -IgnoreReboot"
    ]
  }

  # Install common software
  provisioner "powershell" {
    inline = [
      "Write-Host 'Installing Chocolatey...'",
      "Set-ExecutionPolicy Bypass -Scope Process -Force",
      "[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072",
      "iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))",
      "Write-Host 'Installing common packages...'",
      "choco install -y git",
      "choco install -y 7zip",
      "choco install -y curl"
    ]
  }

  # Install Azure CLI (optional)
  # provisioner "powershell" {
  #   inline = [
  #     "Write-Host 'Installing Azure CLI...'",
  #     "choco install -y azure-cli"
  #   ]
  # }

  # Run custom provisioning script
  provisioner "powershell" {
    scripts = [
      "../scripts/provision-windows-azure.ps1"
    ]
  }

  # Cleanup
  provisioner "powershell" {
    inline = [
      "Write-Host 'Cleaning up temporary files...'",
      "Remove-Item -Path $env:TEMP\\* -Recurse -Force -ErrorAction SilentlyContinue",
      "Remove-Item -Path C:\\Windows\\Temp\\* -Recurse -Force -ErrorAction SilentlyContinue",
      "Write-Host 'Optimizing disk...'",
      "Optimize-Volume -DriveLetter C -Defrag -Verbose"
    ]
  }

  # Azure deprovision
  provisioner "powershell" {
    inline = [
      "Write-Host 'Deprovisioning VM...'",
      "if (Test-Path C:\\DeprovisioningScript.ps1) { & C:\\DeprovisioningScript.ps1 }",
      "while ((Get-Service RdAgent).Status -ne 'Running') { Start-Sleep -s 5 }",
      "while ((Get-Service WindowsAzureGuestAgent).Status -ne 'Running') { Start-Sleep -s 5 }",
      "& $env:SystemRoot\\System32\\Sysprep\\Sysprep.exe /oobe /generalize /quiet /quit /mode:vm",
      "while ($true) { $imageState = Get-ItemProperty HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Setup\\State | Select-Object ImageState; if ($imageState.ImageState -ne 'IMAGE_STATE_GENERALIZE_RESEAL_TO_OOBE') { Write-Output $imageState.ImageState; Start-Sleep -s 10 } else { break } }"
    ]
  }

  # Post-processor to manifest the Image ID
  post-processor "manifest" {
    output     = "manifest-azure-windows.json"
    strip_path = true
  }
}
