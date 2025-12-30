# modules/bastion/main.tf
# Azure Bastion module for secure RDP/SSH access without exposing VMs to the internet

# ============================================================================
# Internal Naming Modules
# ============================================================================

module "bastion_naming" {
  source = "../naming"

  resource_type = var.resource_type
  workload      = var.workload
  environment   = var.environment
  location      = var.location
  instance      = var.instance
  common_tags   = var.common_tags
}

module "bastion_pip_naming" {
  source = "../naming"

  resource_type = "pip"
  workload      = "bastion"
  environment   = var.environment
  location      = var.location
  instance      = var.instance
  common_tags   = var.common_tags
}

# ============================================================================
# Azure Bastion Resources
# ============================================================================

# Public IP for Azure Bastion (required)
# Must be Static and Standard SKU for Bastion compatibility
resource "azurerm_public_ip" "bastion" {
  name                = module.bastion_pip_naming.name
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"              # Required for Bastion
  sku                 = "Standard"            # Required for Bastion
  zones               = var.availability_zones # Optional zone redundancy for HA
  tags                = module.bastion_pip_naming.tags

  # Prevent accidental deletion in production
  lifecycle {
    prevent_destroy = false # Set to true for production
  }
}

# Azure Bastion Host
# Provides secure browser-based RDP/SSH access to VMs without public IPs
resource "azurerm_bastion_host" "bastion" {
  name                = module.bastion_naming.name
  location            = var.location
  resource_group_name = var.resource_group_name

  # SKU: Basic (fixed 2 scale units) or Standard (scalable, more features)
  sku = var.sku

  # Standard SKU features (ignored if Basic SKU)
  copy_paste_enabled     = var.copy_paste_enabled      # Enable clipboard between local/remote
  file_copy_enabled      = var.file_copy_enabled       # Upload/download files (Standard only)
  ip_connect_enabled     = var.ip_connect_enabled      # Connect via private IP instead of VM name
  scale_units            = var.sku == "Standard" ? var.scale_units : 2 # 2-50 units (Standard), Basic=2 fixed
  shareable_link_enabled = var.shareable_link_enabled  # Generate shareable links (Standard only)
  tunneling_enabled      = var.tunneling_enabled       # Native client support (Standard only)

  tags = module.bastion_naming.tags

  # IP configuration - connects Bastion to AzureBastionSubnet
  ip_configuration {
    name                 = "bastion-ipconfig"
    subnet_id            = var.subnet_id            # Must be AzureBastionSubnet
    public_ip_address_id = azurerm_public_ip.bastion.id
  }

  # Prevent accidental deletion in production
  lifecycle {
    prevent_destroy = false # Set to true for production
  }

  depends_on = [
    azurerm_public_ip.bastion
  ]
}

# Optional: Diagnostic Settings for monitoring and logging
resource "azurerm_monitor_diagnostic_setting" "bastion" {
  count = var.enable_diagnostic_settings ? 1 : 0

  name                       = "${module.bastion_naming.name}-diag"
  target_resource_id         = azurerm_bastion_host.bastion.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  # Bastion Access Logs - Track who accessed which VM and when
  enabled_log {
    category = "BastionAuditLogs"
  }

  # Metrics for monitoring performance and usage
  metric {
    category = "AllMetrics"
    enabled  = true
  }
}
