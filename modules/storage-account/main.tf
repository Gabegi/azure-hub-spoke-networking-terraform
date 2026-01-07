# modules/storage-account/main.tf
# Storage Account module for Azure Function Apps

# ============================================================================
# Internal Naming Module
# ============================================================================

module "storage_naming" {
  source = "../naming"

  resource_type = var.resource_type
  workload      = var.workload
  environment   = var.environment
  location      = var.location
  instance      = var.instance
  common_tags   = var.common_tags
}

# ============================================================================
# Storage Account
# ============================================================================

resource "azurerm_storage_account" "storage" {
  name                     = module.storage_naming.name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = var.account_tier
  account_replication_type = var.replication_type
  account_kind             = var.account_kind
  min_tls_version          = var.min_tls_version

  # Security settings
  https_traffic_only_enabled       = var.https_only
  allow_nested_items_to_be_public  = var.allow_public_access
  shared_access_key_enabled        = var.enable_shared_access_key

  # Network rules
  public_network_access_enabled = var.public_network_access_enabled

  dynamic "network_rules" {
    for_each = var.network_rules_enabled ? [1] : []
    content {
      default_action             = var.network_rules_default_action
      ip_rules                   = var.network_rules_ip_rules
      virtual_network_subnet_ids = var.network_rules_subnet_ids
      bypass                     = var.network_rules_bypass
    }
  }

  tags = module.storage_naming.tags

  lifecycle {
    prevent_destroy = false
    ignore_changes  = [tags]
  }
}
