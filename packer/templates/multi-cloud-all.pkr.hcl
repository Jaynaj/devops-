# Comprehensive Multi-cloud Packer template
# Builds Linux and Windows images for both AWS and Azure
packer {
  required_plugins {
    amazon = {
      version = ">= 1.2.0"
      source  = "github.com/hashicorp/amazon"
    }
    azure = {
      version = ">= 2.0.0"
      source  = "github.com/hashicorp/azure"
    }
  }
}

# ============================================
# AWS Data Sources
# ============================================

# AWS Linux AMI
data "amazon-ami" "aws_linux" {
  filters = {
    name                = var.source_ami_filter
    root-device-type    = "ebs"
    virtualization-type = "hvm"
  }
  most_recent = true
  owners      = [var.source_ami_owner]
  region      = var.aws_region
}

# AWS Windows AMI
data "amazon-ami" "aws_windows" {
  filters = {
    name                = var.source_windows_ami_filter
    root-device-type    = "ebs"
    virtualization-type = "hvm"
  }
  most_recent = true
  owners      = [var.source_windows_ami_owner]
  region      = var.aws_region
}

# ============================================
# AWS Source Configurations
# ============================================

# AWS Linux Source
source "amazon-ebs" "aws_linux" {
  ami_name      = "${var.image_name_prefix}-aws-linux-${var.environment}-{{timestamp}}"
  instance_type = var.aws_instance_type
  region        = var.aws_region
  source_ami    = data.amazon-ami.aws_linux.id
  ssh_username  = var.aws_ssh_username

  tags = {
    Name        = "${var.image_name_prefix}-aws-linux-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
    BuildDate   = "{{timestamp}}"
    ManagedBy   = "Packer"
    Cloud       = "AWS"
    OS          = "Linux"
    OSVersion   = "AmazonLinux2"
  }

  run_tags = {
    Name      = "Packer Builder - ${var.project_name} - AWS Linux"
    ManagedBy = "Packer"
  }
}

# AWS Windows Source
source "amazon-ebs" "aws_windows" {
  ami_name      = "${var.image_name_prefix}-aws-windows-${var.environment}-{{timestamp}}"
  instance_type = var.aws_windows_instance_type
  region        = var.aws_region
  source_ami    = data.amazon-ami.aws_windows.id

  communicator   = "winrm"
  winrm_username = var.aws_winrm_username
  winrm_insecure = true
  winrm_use_ssl  = true

  user_data_file = "../scripts/enable-winrm.ps1"

  tags = {
    Name        = "${var.image_name_prefix}-aws-windows-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
    BuildDate   = "{{timestamp}}"
    ManagedBy   = "Packer"
    Cloud       = "AWS"
    OS          = "Windows"
    OSVersion   = "2022"
  }

  run_tags = {
    Name      = "Packer Builder - ${var.project_name} - AWS Windows"
    ManagedBy = "Packer"
  }
}

# ============================================
# Azure Source Configurations
# ============================================

# Azure Linux Source
source "azure-arm" "azure_linux" {
  subscription_id = var.azure_subscription_id
  client_id       = var.azure_client_id
  client_secret   = var.azure_client_secret
  tenant_id       = var.azure_tenant_id

  managed_image_resource_group_name = var.azure_resource_group
  location                          = var.azure_location
  managed_image_name                = "${var.image_name_prefix}-azure-linux-${var.environment}-{{timestamp}}"

  image_publisher = var.azure_image_publisher
  image_offer     = var.azure_image_offer
  image_sku       = var.azure_image_sku

  vm_size         = var.azure_vm_size
  os_type         = "Linux"
  os_disk_size_gb = 30

  azure_tags = {
    Name        = "${var.image_name_prefix}-azure-linux-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
    BuildDate   = "{{timestamp}}"
    ManagedBy   = "Packer"
    Cloud       = "Azure"
    OS          = "Linux"
    OSVersion   = "Ubuntu2204"
  }
}

# Azure Windows Source
source "azure-arm" "azure_windows" {
  subscription_id = var.azure_subscription_id
  client_id       = var.azure_client_id
  client_secret   = var.azure_client_secret
  tenant_id       = var.azure_tenant_id

  managed_image_resource_group_name = var.azure_resource_group
  location                          = var.azure_location
  managed_image_name                = "${var.image_name_prefix}-azure-windows-${var.environment}-{{timestamp}}"

  image_publisher = var.azure_windows_image_publisher
  image_offer     = var.azure_windows_image_offer
  image_sku       = var.azure_windows_image_sku

  vm_size         = var.azure_windows_vm_size
  os_type         = "Windows"
  os_disk_size_gb = 128

  communicator   = "winrm"
  winrm_use_ssl  = true
  winrm_insecure = true
  winrm_timeout  = "5m"
  winrm_username = var.azure_winrm_username

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

# ============================================
# Build: AWS Linux
# ============================================

build {
  name = "aws-linux"
  sources = ["source.amazon-ebs.aws_linux"]

  provisioner "shell" {
    inline = [
      "echo 'Updating system packages...'",
      "sudo yum update -y",
      "sudo yum install -y wget curl git"
    ]
  }

  provisioner "shell" {
    script = "../scripts/provision.sh"
  }

  provisioner "shell" {
    inline = [
      "echo 'Cleaning up...'",
      "sudo yum clean all",
      "sudo rm -rf /tmp/*"
    ]
  }

  post-processor "manifest" {
    output     = "manifest-aws-linux.json"
    strip_path = true
  }
}

# ============================================
# Build: AWS Windows
# ============================================

build {
  name = "aws-windows"
  sources = ["source.amazon-ebs.aws_windows"]

  provisioner "powershell" {
    inline = [
      "Write-Host 'Waiting for WinRM to be fully ready...'",
      "Start-Sleep -Seconds 30"
    ]
  }

  provisioner "powershell" {
    inline = [
      "Write-Host 'Installing Windows Updates...'",
      "Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force",
      "Install-Module PSWindowsUpdate -Force",
      "Import-Module PSWindowsUpdate",
      "Get-WindowsUpdate -AcceptAll -Install -IgnoreReboot"
    ]
  }

  provisioner "powershell" {
    inline = [
      "Write-Host 'Installing Chocolatey...'",
      "Set-ExecutionPolicy Bypass -Scope Process -Force",
      "[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072",
      "iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))",
      "choco install -y git 7zip curl"
    ]
  }

  provisioner "powershell" {
    scripts = ["../scripts/provision-windows.ps1"]
  }

  provisioner "powershell" {
    inline = [
      "Write-Host 'Cleaning up...'",
      "Remove-Item -Path $env:TEMP\\* -Recurse -Force -ErrorAction SilentlyContinue",
      "Optimize-Volume -DriveLetter C -Defrag -Verbose"
    ]
  }

  provisioner "powershell" {
    inline = [
      "C:\\ProgramData\\Amazon\\EC2-Windows\\Launch\\Scripts\\InitializeInstance.ps1 -Schedule",
      "C:\\ProgramData\\Amazon\\EC2-Windows\\Launch\\Scripts\\SysprepInstance.ps1 -NoShutdown"
    ]
  }

  post-processor "manifest" {
    output     = "manifest-aws-windows.json"
    strip_path = true
  }
}

# ============================================
# Build: Azure Linux
# ============================================

build {
  name = "azure-linux"
  sources = ["source.azure-arm.azure_linux"]

  provisioner "shell" {
    inline = [
      "echo 'Waiting for cloud-init...'",
      "cloud-init status --wait",
      "echo 'Updating system packages...'",
      "sudo apt-get update",
      "sudo apt-get upgrade -y",
      "sudo apt-get install -y wget curl git"
    ]
  }

  provisioner "shell" {
    script = "../scripts/provision-azure.sh"
  }

  provisioner "shell" {
    inline = [
      "echo 'Cleaning up...'",
      "sudo apt-get clean",
      "sudo rm -rf /tmp/*",
      "sudo rm -rf /var/tmp/*"
    ]
  }

  provisioner "shell" {
    execute_command = "chmod +x {{ .Path }}; {{ .Vars }} sudo -E sh '{{ .Path }}'"
    inline = [
      "/usr/sbin/waagent -force -deprovision+user && export HISTSIZE=0 && sync"
    ]
    inline_shebang = "/bin/sh -x"
  }

  post-processor "manifest" {
    output     = "manifest-azure-linux.json"
    strip_path = true
  }
}

# ============================================
# Build: Azure Windows
# ============================================

build {
  name = "azure-windows"
  sources = ["source.azure-arm.azure_windows"]

  provisioner "powershell" {
    inline = [
      "Write-Host 'Waiting for system to be ready...'",
      "Start-Sleep -Seconds 30"
    ]
  }

  provisioner "powershell" {
    inline = [
      "Write-Host 'Installing Windows Updates...'",
      "Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force",
      "Install-Module PSWindowsUpdate -Force",
      "Import-Module PSWindowsUpdate",
      "Get-WindowsUpdate -AcceptAll -Install -IgnoreReboot"
    ]
  }

  provisioner "powershell" {
    inline = [
      "Write-Host 'Installing Chocolatey...'",
      "Set-ExecutionPolicy Bypass -Scope Process -Force",
      "[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072",
      "iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))",
      "choco install -y git 7zip curl"
    ]
  }

  provisioner "powershell" {
    scripts = ["../scripts/provision-windows-azure.ps1"]
  }

  provisioner "powershell" {
    inline = [
      "Write-Host 'Cleaning up...'",
      "Remove-Item -Path $env:TEMP\\* -Recurse -Force -ErrorAction SilentlyContinue",
      "Remove-Item -Path C:\\Windows\\Temp\\* -Recurse -Force -ErrorAction SilentlyContinue",
      "Optimize-Volume -DriveLetter C -Defrag -Verbose"
    ]
  }

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

  post-processor "manifest" {
    output     = "manifest-azure-windows.json"
    strip_path = true
  }
}
