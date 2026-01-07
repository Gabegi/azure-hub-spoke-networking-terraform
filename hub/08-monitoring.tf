# hub/08-monitoring.tf
# Log Analytics Workspace for monitoring and diagnostics

# Log Analytics Workspace
# Central repository for logs, metrics, and diagnostics from all Azure resources
resource "azurerm_log_analytics_workspace" "hub" {
  name                = "log-hub-${var.environment}-${var.location}-001"
  location            = var.location
  resource_group_name = module.rg_networking.rg_name
  sku                 = "PerGB2018"
  retention_in_days   = var.log_retention_days

  tags = var.tags

  lifecycle {
    prevent_destroy = false # Set to true for production
  }
}

# Storage Account for NSG Flow Logs (optional)
resource "azurerm_storage_account" "flow_logs" {
  count = var.enable_flow_logs ? 1 : 0

  name                     = "stflowlogs${var.environment}${replace(var.location, "-", "")}001"
  resource_group_name      = module.rg_networking.rg_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"

  tags = var.tags

  lifecycle {
    prevent_destroy = false
  }
}
