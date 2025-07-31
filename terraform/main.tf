terraform {
  required_version = ">= 1.5"
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "~> 2.9"
    }
  }
}

provider "proxmox" {
  pm_api_url          = var.proxmox_api_url
  pm_api_token_id     = var.proxmox_token_id
  pm_api_token_secret = var.proxmox_token_secret
  pm_tls_insecure     = var.proxmox_tls_insecure
  pm_debug            = var.proxmox_debug
}

# VM Template for Debian 12.x
resource "proxmox_vm_qemu" "debian_template" {
  count       = var.vm_count
  name        = "${var.vm_name_prefix}-${count.index + 1}"
  target_node = var.proxmox_node
  clone       = var.debian_template_name
  full_clone  = true
  cores       = var.vm_cores
  sockets     = var.vm_sockets
  memory      = var.vm_memory
  agent       = 1
  qemu_os     = "l26"
  
  # Network configuration
  network {
    bridge = var.network_bridge
    model  = "virtio"
  }

  # Disk configuration
  disk {
    type    = "scsi"
    storage = var.storage_pool
    size    = var.vm_disk_size
    ssd     = var.vm_ssd
  }

  # Cloud-init configuration for static IP
  ciuser = var.vm_user
  sshkeys = var.vm_ssh_keys

  # Cloud-init network configuration
  ipconfig0 = "ip=${var.vm_ip_pool[count.index]}/${var.network_cidr},gw=${var.network_gateway}"

  # Additional cloud-init configuration
  cipassword = var.vm_password

  # Tags for organization
  tags = "debian12,managed,terraform"

  # Lifecycle hooks
  lifecycle {
    create_before_destroy = true
  }

  # Wait for VM to be ready
  provisioner "remote-exec" {
    inline = [
      "echo 'VM is ready'",
      "sleep 30"
    ]

    connection {
      type        = "ssh"
      user        = var.vm_user
      private_key = file(var.vm_ssh_private_key)
      host        = var.vm_ip_pool[count.index]
    }
  }
}

# Output VM information
output "vm_ips" {
  description = "IP addresses of created VMs"
  value       = proxmox_vm_qemu.debian_template[*].default_ipv4_address
}

output "vm_names" {
  description = "Names of created VMs"
  value       = proxmox_vm_qemu.debian_template[*].name
}

output "vm_ids" {
  description = "VM IDs in Proxmox"
  value       = proxmox_vm_qemu.debian_template[*].vmid
} 