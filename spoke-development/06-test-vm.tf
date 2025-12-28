# spoke-development/06-test-vm.tf
# Test VM for connectivity testing in Development spoke

# ============================================================================
# Naming Modules
# ============================================================================

module "test_vm_naming" {
  source = "../modules/naming"

  resource_type = "vm"
  workload      = "test"
  environment   = var.environment
  location      = var.location
  instance      = "001"
  common_tags   = var.tags
}

module "test_vm_nic_naming" {
  source = "../modules/naming"

  resource_type = "nic"
  workload      = "test"
  environment   = var.environment
  location      = var.location
  instance      = "001"
  common_tags   = var.tags
}

# ============================================================================
# Test VM
# ============================================================================

module "test_vm" {
  count  = local.deploy_workload_subnet ? 1 : 0
  source = "../modules/vm"

  vm_name             = module.test_vm_naming.name
  nic_name            = module.test_vm_nic_naming.name
  location            = var.location
  resource_group_name = module.rg_spoke.rg_name
  subnet_id           = module.workload_subnet[0].subnet_id

  vm_size                = "Standard_DS1_v2"
  admin_username         = "azureuser"
  admin_ssh_public_key   = var.vm_admin_ssh_public_key

  # Install connectivity testing tools
  custom_data = <<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y curl netcat-traditional dnsutils traceroute nginx

    # Create test page
    echo "Development Spoke Test VM - $(hostname)" > /var/www/html/index.html
    systemctl enable nginx
    systemctl start nginx

    # Create test script
    cat > /home/azureuser/test-connectivity.sh <<'SCRIPT'
    #!/bin/bash
    echo "=== Connectivity Tests ==="
    echo ""
    echo "1. Test Internet (google.com):"
    curl -I https://www.google.com --max-time 5
    echo ""
    echo "2. Test Production Spoke (10.2.0.0/16):"
    echo "   Run: curl http://<prod-vm-ip>:80"
    echo ""
    echo "3. Test DNS:"
    nslookup google.com
    SCRIPT

    chmod +x /home/azureuser/test-connectivity.sh
    chown azureuser:azureuser /home/azureuser/test-connectivity.sh
  EOF

  tags = merge(
    module.test_vm_naming.tags,
    {
      Purpose = "Connectivity Testing"
      Usage   = "Test spoke-to-spoke and internet connectivity"
    }
  )

  depends_on = [
    module.workload_subnet
  ]
}
