# Proxmox Provider Variables
variable "proxmox_api_url" {
  description = "Proxmox API URL"
  type        = string
  default     = "https://proxmox.example.com:8006/api2/json"
}

variable "proxmox_token_id" {
  description = "Proxmox API token ID"
  type        = string
  sensitive   = true
}

variable "proxmox_token_secret" {
  description = "Proxmox API token secret"
  type        = string
  sensitive   = true
}

variable "proxmox_tls_insecure" {
  description = "Skip TLS verification for Proxmox API"
  type        = bool
  default     = false
}

variable "proxmox_debug" {
  description = "Enable debug mode for Proxmox provider"
  type        = bool
  default     = false
}

variable "proxmox_node" {
  description = "Proxmox node to deploy VMs on"
  type        = string
  default     = "pve"
}

# VM Configuration Variables
variable "vm_count" {
  description = "Number of VMs to create"
  type        = number
  default     = 3
}

variable "vm_name_prefix" {
  description = "Prefix for VM names"
  type        = string
  default     = "debian12"
}

variable "debian_template_name" {
  description = "Name of the Debian 12.x template in Proxmox"
  type        = string
  default     = "debian-12-template"
}

variable "vm_cores" {
  description = "Number of CPU cores per VM"
  type        = number
  default     = 2
}

variable "vm_sockets" {
  description = "Number of CPU sockets per VM"
  type        = number
  default     = 1
}

variable "vm_memory" {
  description = "Memory in MB per VM"
  type        = number
  default     = 4096
}

variable "vm_disk_size" {
  description = "Disk size in GB per VM"
  type        = string
  default     = "20G"
}

variable "vm_ssd" {
  description = "Use SSD for VM disks"
  type        = bool
  default     = true
}

variable "storage_pool" {
  description = "Proxmox storage pool for VM disks"
  type        = string
  default     = "local-lvm"
}

# Network Configuration Variables
variable "network_bridge" {
  description = "Network bridge to use for VMs"
  type        = string
  default     = "vmbr0"
}

variable "network_cidr" {
  description = "Network CIDR notation (e.g., 24 for /24)"
  type        = number
  default     = 24
}

variable "network_gateway" {
  description = "Network gateway IP address"
  type        = string
  default     = "192.168.1.1"
}

variable "vm_ip_pool" {
  description = "List of static IP addresses for VMs"
  type        = list(string)
  default     = [
    "192.168.1.10",
    "192.168.1.11", 
    "192.168.1.12",
    "192.168.1.13",
    "192.168.1.14",
    "192.168.1.15"
  ]
}

# VM User Configuration
variable "vm_user" {
  description = "Default user for VMs"
  type        = string
  default     = "debian"
}

variable "vm_password" {
  description = "Default password for VMs"
  type        = string
  sensitive   = true
  default     = "ChangeMe123!"
}

variable "vm_ssh_keys" {
  description = "SSH public keys for VM access"
  type        = string
  default     = ""
}

variable "vm_ssh_private_key" {
  description = "Path to SSH private key for VM access"
  type        = string
  default     = "~/.ssh/id_rsa"
}

# Validation
locals {
  # Ensure we have enough IP addresses
  ip_count = length(var.vm_ip_pool)
  vm_count = var.vm_count
}

# Validation rules
resource "null_resource" "validation" {
  lifecycle {
    precondition {
      condition     = var.vm_count <= var.ip_count
      error_message = "VM count (${var.vm_count}) cannot exceed available IP addresses (${var.ip_count})"
    }
    
    precondition {
      condition     = var.vm_count > 0
      error_message = "VM count must be greater than 0"
    }
    
    precondition {
      condition     = var.vm_cores > 0
      error_message = "VM cores must be greater than 0"
    }
    
    precondition {
      condition     = var.vm_memory > 0
      error_message = "VM memory must be greater than 0"
    }
  }
} 