# monitoring.tf
# Shared monitoring infrastructure for Hub-Spoke topology

# ============================================================================
# Naming Modules
# ============================================================================

module "log_analytics_naming" {
  source = "./modules/naming"

  resource_type = "log"
  workload      = "networking"
  environment   = var.environment
  location      = var.location
  instance      = "001"
  common_tags   = var.tags
}

module "storage_account_naming" {
  source = "./modules/naming"

  resource_type = "st"
  workload      = "flowlogs"
  environment   = var.environment
  location      = var.location
  instance      = "001"
  common_tags   = var.tags
}

# ============================================================================
# Resource Group for Monitoring
# ============================================================================

module "rg_monitoring_naming" {
  source = "./modules/naming"

  resource_type = "rg"
  workload      = "monitoring"
  environment   = var.environment
  location      = var.location
  instance      = "001"
  common_tags   = var.tags
}

module "rg_monitoring" {
  source = "./modules/resource-group"

  rg_name  = module.rg_monitoring_naming.name
  location = var.location
  tags     = module.rg_monitoring_naming.tags

  enable_resource_lock = var.environment == "prod" ? var.enable_resource_lock : false
  lock_level           = "CanNotDelete"
}

# ============================================================================
# Log Analytics Workspace
# ============================================================================

resource "azurerm_log_analytics_workspace" "main" {
  name                = module.log_analytics_naming.name
  location            = var.location
  resource_group_name = module.rg_monitoring.rg_name
  sku                 = var.log_analytics_sku
  retention_in_days   = var.log_analytics_retention_days

  tags = module.log_analytics_naming.tags

  depends_on = [module.rg_monitoring]
}

# ============================================================================
# Storage Account for NSG Flow Logs
# ============================================================================

resource "azurerm_storage_account" "flow_logs" {
  # Storage account names must be lowercase and cannot contain hyphens
  # Use a sanitized version of the naming module output
  name                     = lower(replace(module.storage_account_naming.name, "-", ""))
  location                 = var.location
  resource_group_name      = module.rg_monitoring.rg_name
  account_tier             = "Standard"
  account_replication_type = var.storage_replication_type

  # Security
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  enable_https_traffic_only       = true

  # Network Rules
  network_rules {
    default_action = "Deny"
    bypass         = ["AzureServices"]
  }

  tags = module.storage_account_naming.tags

  depends_on = [module.rg_monitoring]
}
