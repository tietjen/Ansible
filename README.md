# Ansible DevOps Project - Proxmox Debian 12.x Infrastructure

This project provides a complete Infrastructure-as-Code solution for managing Debian 12.x Virtual Machines on a Proxmox Server Cluster with automated installation, configuration, and security hardening.

## Architecture Overview

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Terraform     │    │     Ansible     │    │   Proxmox       │
│   (VM Creation) │───▶│  (Configuration)│───▶│   Cluster       │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## Project Structure

```
├── terraform/                 # Terraform configuration for VM provisioning
│   ├── main.tf               # Main Terraform configuration
│   ├── variables.tf          # Variable definitions
│   ├── outputs.tf            # Output values
│   └── terraform.tfvars      # Variable values
├── ansible/                   # Ansible configuration and playbooks
│   ├── inventory/            # Dynamic inventory and host groups
│   ├── group_vars/          # Group-specific variables
│   ├── host_vars/           # Host-specific variables
│   ├── roles/               # Reusable Ansible roles
│   ├── playbooks/           # Main playbooks
│   └── ansible.cfg          # Ansible configuration
├── configs/                  # Configuration templates
│   ├── network/             # Network configuration templates
│   └── security/            # Security configuration templates
└── scripts/                  # Utility scripts
    ├── setup.sh             # Initial setup script
    └── deploy.sh            # Deployment script
```

## Features

- **Automated VM Provisioning**: Terraform creates VMs on Proxmox with static IPs
- **Configuration Management**: Ansible handles all post-installation configuration
- **Security Hardening**: CIS benchmark compliance for Debian 12.x
- **Docker Integration**: Latest Docker and Docker Compose installation
- **Network Management**: Static IPv4 configuration with IPv6 disabled
- **Infrastructure as Code**: Complete IaC approach with version control

## Prerequisites

- Proxmox VE 8.x cluster
- Terraform >= 1.5
- Ansible >= 8.0
- Python 3.8+
- SSH access to Proxmox nodes

## Quick Start

1. **Clone and Setup**:
   ```bash
   git clone <repository>
   cd Ansible
   ./scripts/setup.sh
   ```

2. **Configure Variables**:
   ```bash
   cp terraform/terraform.tfvars.example terraform/terraform.tfvars
   # Edit terraform.tfvars with your Proxmox details
   ```

3. **Deploy Infrastructure**:
   ```bash
   ./scripts/deploy.sh
   ```

## Configuration

### Network Configuration

The project supports configurable IP pools. Edit `ansible/group_vars/all.yml` to configure:

- IP address ranges
- Gateway and DNS settings
- Network interface configuration

### Security Hardening

CIS benchmark compliance is implemented through Ansible roles:

- System hardening
- User management
- Service configuration
- Audit logging
- Network security

## Usage

### Creating New VMs

1. Add VM configuration to `terraform/main.tf`
2. Run `terraform plan` and `terraform apply`
3. Ansible will automatically configure the new VMs

### Updating Existing VMs

```bash
ansible-playbook -i ansible/inventory/proxmox.yml ansible/playbooks/update.yml
```

### Security Audits

```bash
ansible-playbook -i ansible/inventory/proxmox.yml ansible/playbooks/security-audit.yml
```

## Monitoring and Maintenance

- Regular security updates via Ansible
- Automated backup verification
- Health checks and monitoring
- Log aggregation and analysis

## Contributing

1. Follow the established project structure
2. Use meaningful commit messages
3. Test changes in a staging environment
4. Update documentation as needed

## License

This project is licensed under the MIT License - see the LICENSE file for details. 