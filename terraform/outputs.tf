# VM Information Outputs
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

# Network Information
output "network_config" {
  description = "Network configuration summary"
  value = {
    gateway     = var.network_gateway
    cidr        = var.network_cidr
    bridge      = var.network_bridge
    ip_pool     = var.vm_ip_pool
    total_ips   = length(var.vm_ip_pool)
    used_ips    = var.vm_count
  }
}

# Infrastructure Summary
output "infrastructure_summary" {
  description = "Complete infrastructure deployment summary"
  value = {
    total_vms           = var.vm_count
    vm_specs = {
      cores   = var.vm_cores
      memory  = "${var.vm_memory}MB"
      disk    = var.vm_disk_size
      storage = var.storage_pool
    }
    network = {
      gateway = var.network_gateway
      bridge  = var.network_bridge
      cidr    = var.network_cidr
    }
    template = var.debian_template_name
    node     = var.proxmox_node
  }
}

# Ansible Inventory Output
output "ansible_inventory" {
  description = "Ansible inventory format for created VMs"
  value = {
    all = {
      hosts = {
        for i, vm in proxmox_vm_qemu.debian_template : vm.name => {
          ansible_host = vm.default_ipv4_address
          ansible_user = var.vm_user
          vm_id       = vm.vmid
          vm_ip       = vm.default_ipv4_address
        }
      }
      vars = {
        ansible_ssh_private_key_file = var.vm_ssh_private_key
        ansible_ssh_common_args      = "-o StrictHostKeyChecking=no"
      }
    }
  }
}

# Connection Information
output "ssh_connection_info" {
  description = "SSH connection information for VMs"
  value = {
    for i, vm in proxmox_vm_qemu.debian_template : vm.name => {
      ssh_command = "ssh -i ${var.vm_ssh_private_key} ${var.vm_user}@${vm.default_ipv4_address}"
      ip_address  = vm.default_ipv4_address
      user        = var.vm_user
    }
  }
}

# Next Steps
output "next_steps" {
  description = "Next steps after Terraform deployment"
  value = [
    "1. Wait for VMs to fully boot (usually 2-3 minutes)",
    "2. Run Ansible playbooks to configure VMs:",
    "   ansible-playbook -i ansible/inventory/proxmox.yml ansible/playbooks/initial-setup.yml",
    "3. Verify network connectivity to all VMs",
    "4. Run security hardening playbook:",
    "   ansible-playbook -i ansible/inventory/proxmox.yml ansible/playbooks/security-harden.yml",
    "5. Install Docker and Docker Compose:",
    "   ansible-playbook -i ansible/inventory/proxmox.yml ansible/playbooks/docker-setup.yml"
  ]
} 