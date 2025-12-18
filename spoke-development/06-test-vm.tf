# spoke-development/06-test-vm.tf
# Test VM for connectivity testing in Development spoke

# ============================================================================
# Naming Module
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
# Network Interface
# ============================================================================

resource "azurerm_network_interface" "test_vm" {
  count = local.deploy_workload_subnet ? 1 : 0

  name                = module.test_vm_nic_naming.name
  location            = var.location
  resource_group_name = module.rg_spoke.rg_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = module.workload_subnet[0].subnet_id
    private_ip_address_allocation = "Dynamic"
  }

  tags = module.test_vm_nic_naming.tags

  depends_on = [
    module.workload_subnet
  ]
}

# ============================================================================
# Virtual Machine
# ============================================================================

resource "azurerm_linux_virtual_machine" "test_vm" {
  count = local.deploy_workload_subnet ? 1 : 0

  name                = module.test_vm_naming.name
  location            = var.location
  resource_group_name = module.rg_spoke.rg_name
  size                = "Standard_B2s"  # Cost-effective size for testing
  admin_username      = "azureuser"

  network_interface_ids = [
    azurerm_network_interface.test_vm[0].id
  ]

  # SSH Authentication
  admin_ssh_key {
    username   = "azureuser"
    public_key = var.vm_admin_ssh_public_key
  }

  # OS Disk
  os_disk {
    name                 = "osdisk-${module.test_vm_naming.name}"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  # Ubuntu 22.04 LTS
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  # Install basic connectivity testing tools
  custom_data = base64encode(<<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y curl netcat-traditional dnsutils traceroute

    # Create a test file for web server
    mkdir -p /var/www/html
    echo "Development Spoke Test VM - $(hostname)" > /var/www/html/index.html

    # Simple Python HTTP server on port 443 (for testing)
    # Note: In production, you'd use proper certificates
    cat > /usr/local/bin/test-server.sh <<'SCRIPT'
    #!/bin/bash
    cd /var/www/html
    python3 -m http.server 8080
    SCRIPT

    chmod +x /usr/local/bin/test-server.sh

    # Create systemd service for test server
    cat > /etc/systemd/system/test-server.service <<'SERVICE'
    [Unit]
    Description=Test HTTP Server
    After=network.target

    [Service]
    Type=simple
    User=root
    ExecStart=/usr/local/bin/test-server.sh
    Restart=on-failure

    [Install]
    WantedBy=multi-user.target
    SERVICE

    systemctl daemon-reload
    systemctl enable test-server.service
    systemctl start test-server.service
    EOF
  )

  # Disable boot diagnostics to reduce costs
  boot_diagnostics {}

  tags = merge(
    module.test_vm_naming.tags,
    {
      Purpose = "Connectivity Testing"
      Usage   = "Test spoke-to-spoke and internet connectivity"
    }
  )

  depends_on = [
    azurerm_network_interface.test_vm
  ]
}
