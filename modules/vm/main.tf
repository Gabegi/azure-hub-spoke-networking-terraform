# modules/vm/main.tf
# Reusable VM module for test VMs

# ============================================================================
# Network Interface
# ============================================================================

resource "azurerm_network_interface" "vm" {
  name                = var.nic_name
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
  }

  tags = var.tags
}

# ============================================================================
# Linux Virtual Machine
# ============================================================================

resource "azurerm_linux_virtual_machine" "vm" {
  name                = var.vm_name
  location            = var.location
  resource_group_name = var.resource_group_name
  size                = var.vm_size
  admin_username      = var.admin_username

  network_interface_ids = [
    azurerm_network_interface.vm.id
  ]

  # SSH Authentication
  admin_ssh_key {
    username   = var.admin_username
    public_key = var.admin_ssh_public_key
  }

  # OS Disk
  os_disk {
    name                 = "osdisk-${var.vm_name}"
    caching              = "ReadWrite"
    storage_account_type = var.os_disk_storage_account_type
  }

  # OS Image
  source_image_reference {
    publisher = var.image_publisher
    offer     = var.image_offer
    sku       = var.image_sku
    version   = var.image_version
  }

  # Custom initialization script
  custom_data = var.custom_data != null ? base64encode(var.custom_data) : null

  # Boot diagnostics
  boot_diagnostics {}

  tags = var.tags

  depends_on = [
    azurerm_network_interface.vm
  ]
}
