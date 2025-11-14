# Packer template for building AWS Windows AMI
packer {
  required_plugins {
    amazon = {
      version = ">= 1.2.0"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

# Data source to get the latest Windows Server AMI
data "amazon-ami" "windows_base" {
  filters = {
    name                = var.source_windows_ami_filter
    root-device-type    = "ebs"
    virtualization-type = "hvm"
  }
  most_recent = true
  owners      = [var.source_windows_ami_owner]
  region      = var.aws_region
}

# Build configuration for Windows
source "amazon-ebs" "windows" {
  ami_name      = "${var.image_name_prefix}-aws-windows-${var.environment}-{{timestamp}}"
  instance_type = var.aws_windows_instance_type
  region        = var.aws_region
  source_ami    = data.amazon-ami.windows_base.id

  # WinRM communicator for Windows
  communicator = "winrm"
  winrm_username = var.aws_winrm_username
  winrm_insecure = true
  winrm_use_ssl = true

  # User data to enable WinRM
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
    Name      = "Packer Builder - ${var.project_name} - Windows"
    ManagedBy = "Packer"
  }
}

# Build steps
build {
  name = "aws-windows"
  sources = [
    "source.amazon-ebs.windows"
  ]

  # Wait for WinRM to be ready
  provisioner "powershell" {
    inline = [
      "Write-Host 'Waiting for WinRM to be fully ready...'",
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

  # Run custom provisioning script
  provisioner "powershell" {
    scripts = [
      "../scripts/provision-windows.ps1"
    ]
  }

  # Cleanup
  provisioner "powershell" {
    inline = [
      "Write-Host 'Cleaning up temporary files...'",
      "Remove-Item -Path $env:TEMP\\* -Recurse -Force -ErrorAction SilentlyContinue",
      "Write-Host 'Optimizing disk...'",
      "Optimize-Volume -DriveLetter C -Defrag -Verbose"
    ]
  }

  # Sysprep and shutdown
  provisioner "powershell" {
    inline = [
      "Write-Host 'Running EC2Launch...'",
      "C:\\ProgramData\\Amazon\\EC2-Windows\\Launch\\Scripts\\InitializeInstance.ps1 -Schedule",
      "C:\\ProgramData\\Amazon\\EC2-Windows\\Launch\\Scripts\\SysprepInstance.ps1 -NoShutdown"
    ]
  }

  # Post-processor to manifest the AMI ID
  post-processor "manifest" {
    output     = "manifest-aws-windows.json"
    strip_path = true
  }
}
