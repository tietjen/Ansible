#!/bin/bash

# Ansible DevOps Project Setup Script
# This script sets up the initial environment for the Ansible DevOps project

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

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        error "This script should not be run as root"
        exit 1
    fi
}

# Check prerequisites
check_prerequisites() {
    log "Checking prerequisites..."
    
    # Check for required commands
    local required_commands=("terraform" "ansible" "python3" "git")
    
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            error "$cmd is not installed. Please install it first."
            exit 1
        fi
    done
    
    # Check Terraform version
    local tf_version=$(terraform version -json | jq -r '.terraform_version' 2>/dev/null || echo "unknown")
    if [[ "$tf_version" == "unknown" ]]; then
        warn "Could not determine Terraform version"
    else
        log "Terraform version: $tf_version"
    fi
    
    # Check Ansible version
    local ansible_version=$(ansible --version 2>/dev/null | head -n1 || echo "unknown")
    log "Ansible version: $ansible_version"
}

# Create necessary directories
create_directories() {
    log "Creating necessary directories..."
    
    local dirs=(
        "terraform"
        "ansible/inventory"
        "ansible/group_vars"
        "ansible/host_vars"
        "ansible/roles"
        "ansible/playbooks"
        "ansible/templates"
        "configs/network"
        "configs/security"
        "configs/docker"
        "scripts"
        "logs"
        "backups"
    )
    
    for dir in "${dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            mkdir -p "$dir"
            log "Created directory: $dir"
        fi
    done
}

# Setup SSH keys
setup_ssh() {
    log "Setting up SSH configuration..."
    
    local ssh_dir="$HOME/.ssh"
    local key_file="$ssh_dir/id_rsa"
    
    if [[ ! -d "$ssh_dir" ]]; then
        mkdir -p "$ssh_dir"
        chmod 700 "$ssh_dir"
        log "Created SSH directory"
    fi
    
    if [[ ! -f "$key_file" ]]; then
        log "Generating SSH key pair..."
        ssh-keygen -t rsa -b 4096 -f "$key_file" -N "" -C "ansible-devops@$(hostname)"
        log "SSH key pair generated"
    else
        log "SSH key pair already exists"
    fi
    
    # Set proper permissions
    chmod 600 "$key_file"
    chmod 644 "$key_file.pub"
}

# Setup Ansible configuration
setup_ansible() {
    log "Setting up Ansible configuration..."
    
    # Create ansible.cfg if it doesn't exist
    if [[ ! -f "ansible/ansible.cfg" ]]; then
        log "Creating ansible.cfg..."
        cat > ansible/ansible.cfg << 'EOF'
[defaults]
inventory = inventory/
host_key_checking = False
remote_user = debian
private_key_file = ~/.ssh/id_rsa
ssh_common_args = -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null
forks = 10
timeout = 30
gathering = smart
fact_caching = jsonfile
fact_caching_connection = /tmp/ansible_facts
fact_caching_timeout = 86400
log_path = /var/log/ansible.log
display_skipped_hosts = False
display_ok_hosts = False
stdout_callback = yaml
become = True
become_method = sudo
become_user = root
become_ask_pass = False
strategy = free
retry_files_enabled = False
retry_files_save_path = ~/.ansible-retry
vault_password_file = ~/.vault_pass
callback_whitelist = timer, profile_tasks, profile_roles
ssh_args = -o ControlMaster=auto -o ControlPersist=60s -o UserKnownHostsFile=/dev/null -o IdentitiesOnly=yes

[ssh_connection]
ssh_args = -o ControlMaster=auto -o ControlPersist=60s -o UserKnownHostsFile=/dev/null -o IdentitiesOnly=yes
control_path = ~/.ansible/cp/%%h-%%p-%%r
pipelining = True
scp_if_ssh = True

[privilege_escalation]
become = True
become_method = sudo
become_user = root
become_ask_pass = False

[colors]
ok = green
changed = yellow
unreachable = red
failed = red
skipped = blue
EOF
    fi
}

# Setup Terraform configuration
setup_terraform() {
    log "Setting up Terraform configuration..."
    
    # Create terraform.tfvars if it doesn't exist
    if [[ ! -f "terraform/terraform.tfvars" ]]; then
        log "Creating terraform.tfvars from example..."
        if [[ -f "terraform/terraform.tfvars.example" ]]; then
            cp terraform/terraform.tfvars.example terraform/terraform.tfvars
            warn "Please edit terraform/terraform.tfvars with your Proxmox configuration"
        else
            warn "terraform.tfvars.example not found. Please create terraform/terraform.tfvars manually"
        fi
    fi
}

# Create deployment script
create_deploy_script() {
    log "Creating deployment script..."
    
    cat > scripts/deploy.sh << 'EOF'
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
EOF

    chmod +x scripts/deploy.sh
}

# Main function
main() {
    log "Starting Ansible DevOps project setup..."
    
    check_root
    check_prerequisites
    create_directories
    setup_ssh
    setup_ansible
    setup_terraform
    create_deploy_script
    
    log "Setup completed successfully!"
    log "Next steps:"
    log "1. Edit terraform/terraform.tfvars with your Proxmox configuration"
    log "2. Run ./scripts/deploy.sh to deploy the infrastructure"
    log "3. Check the README.md for detailed documentation"
}

# Run main function
main "$@" 