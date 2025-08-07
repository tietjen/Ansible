#!/bin/bash

# Ansible DevOps Project Deployment Script
# This script deploys the infrastructure using Terraform and configures it with Ansible

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}" >&2
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

# Check if terraform.tfvars exists
if [[ ! -f "terraform/terraform.tfvars" ]]; then
    error "terraform/terraform.tfvars not found. Please run setup.sh first."
    exit 1
fi

# Change to terraform directory
cd terraform

# Initialize Terraform
log "Initializing Terraform..."
terraform init

# Plan Terraform deployment
log "Planning Terraform deployment..."
terraform plan -out=tfplan

# Apply Terraform deployment
log "Applying Terraform deployment..."
terraform apply tfplan

# Get VM IPs from Terraform output
log "Getting VM information from Terraform..."
terraform output -json vm_ips > ../ansible/inventory/vm_ips.json

# Wait for VMs to be ready
log "Waiting for VMs to be ready..."
sleep 60

# Change to ansible directory
cd ../ansible

# Run initial setup playbook
log "Running initial setup playbook..."
ansible-playbook -i inventory/proxmox.yml playbooks/initial-setup.yml

# Run security hardening playbook
log "Running security hardening playbook..."
ansible-playbook -i inventory/proxmox.yml playbooks/security-harden.yml

# Run Docker setup playbook
log "Running Docker setup playbook..."
ansible-playbook -i inventory/proxmox.yml playbooks/docker-setup.yml

log "Deployment completed successfully!"
log "You can now access your VMs using the IP addresses from Terraform output."
