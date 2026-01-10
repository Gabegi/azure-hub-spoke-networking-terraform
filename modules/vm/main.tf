# modules/vm/main.tf
# Virtual Machine module for Linux VMs

# ============================================================================
# Internal Naming Module
# ============================================================================

module "vm_naming" {
  source = "../naming"

  resource_type = var.resource_type
  workload      = var.workload
  environment   = var.environment
  location      = var.location
  instance      = var.instance
  common_tags   = var.common_tags
}

# ============================================================================
# Public IP (Optional)
# ============================================================================

resource "azurerm_public_ip" "vm_public_ip" {
  count = var.enable_public_ip ? 1 : 0

  name                = "${module.vm_naming.name}-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = var.availability_zones

  tags = module.vm_naming.tags

  lifecycle {
    prevent_destroy = false
    ignore_changes  = [tags]
  }
}

# ============================================================================
# Network Interface
# ============================================================================

resource "azurerm_network_interface" "vm_nic" {
  name                = "${module.vm_naming.name}-nic"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = var.private_ip_address_allocation
    private_ip_address            = var.private_ip_address_allocation == "Static" ? var.private_ip_address : null
    public_ip_address_id          = var.enable_public_ip ? azurerm_public_ip.vm_public_ip[0].id : null
  }

  tags = module.vm_naming.tags

  lifecycle {
    prevent_destroy = false
    ignore_changes  = [tags]
  }
}

# ============================================================================
# Linux Virtual Machine
# ============================================================================

resource "azurerm_linux_virtual_machine" "vm" {
  name                = module.vm_naming.name
  location            = var.location
  resource_group_name = var.resource_group_name
  size                = var.vm_size
  admin_username      = var.admin_username
  zone                = length(var.availability_zones) > 0 ? var.availability_zones[0] : null

  network_interface_ids = [
    azurerm_network_interface.vm_nic.id
  ]

  # SSH Authentication
  admin_ssh_key {
    username   = var.admin_username
    public_key = var.admin_ssh_public_key
  }

  # OS Disk
  os_disk {
    name                 = "${module.vm_naming.name}-osdisk"
    caching              = var.os_disk_caching
    storage_account_type = var.os_disk_storage_account_type
    disk_size_gb         = var.os_disk_size_gb
  }

  # OS Image
  source_image_reference {
    publisher = var.source_image_publisher
    offer     = var.source_image_offer
    sku       = var.source_image_sku
    version   = var.source_image_version
  }

  # Boot Diagnostics
  boot_diagnostics {
    storage_account_uri = null # Uses managed storage account
  }

  # Disable password authentication (SSH key only)
  disable_password_authentication = true

  # Identity (optional)
  dynamic "identity" {
    for_each = var.enable_system_assigned_identity ? [1] : []
    content {
      type = "SystemAssigned"
    }
  }

  tags = module.vm_naming.tags

  lifecycle {
    prevent_destroy = false
    ignore_changes  = [tags]
  }
}
