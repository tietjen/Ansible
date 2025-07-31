#!/bin/bash

# Ansible DevOps Project Test Script
# This script validates the project structure and configuration

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $1${NC}"
}

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0

# Test function
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    if eval "$test_command" >/dev/null 2>&1; then
        log "✓ $test_name"
        ((TESTS_PASSED++))
    else
        error "✗ $test_name"
        ((TESTS_FAILED++))
    fi
}

# Check file exists
file_exists() {
    local file="$1"
    [[ -f "$file" ]]
}

# Check directory exists
dir_exists() {
    local dir="$1"
    [[ -d "$dir" ]]
}

# Check YAML syntax
check_yaml() {
    local file="$1"
    python3 -c "import yaml; yaml.safe_load(open('$file', 'r'))" >/dev/null 2>&1
}

# Check JSON syntax
check_json() {
    local file="$1"
    python3 -c "import json; json.load(open('$file', 'r'))" >/dev/null 2>&1
}

# Main test function
main() {
    log "Starting project validation tests..."
    
    # Test 1: Check project structure
    run_test "Project structure - terraform directory" "dir_exists terraform"
    run_test "Project structure - ansible directory" "dir_exists ansible"
    run_test "Project structure - configs directory" "dir_exists configs"
    run_test "Project structure - scripts directory" "dir_exists scripts"
    
    # Test 2: Check Terraform files
    run_test "Terraform main.tf exists" "file_exists terraform/main.tf"
    run_test "Terraform variables.tf exists" "file_exists terraform/variables.tf"
    run_test "Terraform outputs.tf exists" "file_exists terraform/outputs.tf"
    run_test "Terraform terraform.tfvars.example exists" "file_exists terraform/terraform.tfvars.example"
    
    # Test 3: Check Ansible files
    run_test "Ansible ansible.cfg exists" "file_exists ansible/ansible.cfg"
    run_test "Ansible inventory exists" "file_exists ansible/inventory/proxmox.yml"
    run_test "Ansible group_vars exists" "file_exists ansible/group_vars/all.yml"
    
    # Test 4: Check playbooks
    run_test "Initial setup playbook exists" "file_exists ansible/playbooks/initial-setup.yml"
    run_test "Security hardening playbook exists" "file_exists ansible/playbooks/security-harden.yml"
    run_test "Docker setup playbook exists" "file_exists ansible/playbooks/docker-setup.yml"
    
    # Test 5: Check templates
    run_test "NTP template exists" "file_exists ansible/templates/ntp.conf.j2"
    run_test "Interfaces template exists" "file_exists ansible/templates/interfaces.j2"
    run_test "Resolv template exists" "file_exists ansible/templates/resolv.conf.j2"
    run_test "Limits template exists" "file_exists ansible/templates/limits.conf.j2"
    run_test "Logrotate template exists" "file_exists ansible/templates/logrotate.conf.j2"
    run_test "Fail2ban template exists" "file_exists ansible/templates/fail2ban.conf.j2"
    run_test "Audit rules template exists" "file_exists ansible/templates/audit.rules.j2"
    run_test "Docker daemon template exists" "file_exists ansible/templates/daemon.json.j2"
    run_test "Docker logrotate template exists" "file_exists ansible/templates/logrotate.docker.j2"
    run_test "Docker storage driver template exists" "file_exists ansible/templates/storage-driver.conf.j2"
    run_test "Docker network template exists" "file_exists ansible/templates/network.conf.j2"
    run_test "Docker service template exists" "file_exists ansible/templates/docker.service.j2"
    run_test "Docker compose template exists" "file_exists ansible/templates/docker-compose.yml.j2"
    run_test "Docker env template exists" "file_exists ansible/templates/env.j2"
    run_test "Docker compose service template exists" "file_exists ansible/templates/docker-compose.service.j2"
    run_test "Docker monitoring template exists" "file_exists ansible/templates/docker-monitoring.conf.j2"
    
    # Test 6: Check configuration files
    run_test "Network interfaces template exists" "file_exists configs/network/interfaces.j2"
    run_test "Network resolv template exists" "file_exists configs/network/resolv.conf.j2"
    run_test "Security fail2ban template exists" "file_exists configs/security/fail2ban.conf.j2"
    
    # Test 7: Check scripts
    run_test "Setup script exists" "file_exists scripts/setup.sh"
    run_test "Setup script is executable" "[[ -x scripts/setup.sh ]]"
    
    # Test 8: Check YAML syntax
    run_test "Ansible inventory YAML syntax" "check_yaml ansible/inventory/proxmox.yml"
    run_test "Ansible group_vars YAML syntax" "check_yaml ansible/group_vars/all.yml"
    run_test "Initial setup playbook YAML syntax" "check_yaml ansible/playbooks/initial-setup.yml"
    run_test "Security hardening playbook YAML syntax" "check_yaml ansible/playbooks/security-harden.yml"
    run_test "Docker setup playbook YAML syntax" "check_yaml ansible/playbooks/docker-setup.yml"
    
    # Test 9: Check JSON syntax (Terraform outputs)
    run_test "Terraform outputs JSON syntax" "check_json terraform/outputs.tf" 2>/dev/null || true
    
    # Test 10: Check README
    run_test "README.md exists" "file_exists README.md"
    
    # Test 11: Check .gitignore
    run_test ".gitignore exists" "file_exists .gitignore"
    
    # Summary
    echo
    log "Test Summary:"
    log "Tests passed: $TESTS_PASSED"
    if [[ $TESTS_FAILED -gt 0 ]]; then
        error "Tests failed: $TESTS_FAILED"
    else
        log "Tests failed: $TESTS_FAILED"
    fi
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        log "All tests passed! Project structure is valid."
        exit 0
    else
        error "Some tests failed. Please fix the issues above."
        exit 1
    fi
}

# Run main function
main "$@" 