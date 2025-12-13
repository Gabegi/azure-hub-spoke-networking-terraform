# hub/locals.tf
# Local values for Hub VNet configuration

locals {
  # Hub CIDR calculations
  hub_address_space = var.hub_address_space # 10.0.0.0/16

  # Subnet CIDR blocks (calculated from hub address space)
  firewall_subnet = "10.0.0.0/26"   # 64 IPs - AzureFirewallSubnet (required name)
  bastion_subnet  = "10.0.1.0/26"   # 64 IPs - AzureBastionSubnet (required name)
  gateway_subnet  = "10.0.2.0/27"   # 32 IPs - GatewaySubnet (required name)
  management_subnet = "10.0.3.0/24" # 256 IPs - Management subnet

  # Feature toggles
  deploy_firewall = var.deploy_firewall
  deploy_bastion  = var.deploy_bastion
  deploy_gateway  = var.deploy_gateway
  deploy_mgmt     = var.deploy_management_subnet

  # Monitoring
  enable_diagnostics      = var.enable_diagnostics
  enable_flow_logs        = var.enable_flow_logs
  enable_traffic_analytics = var.enable_traffic_analytics

  # Environment-specific Bastion configuration
  # Automatically selects config based on environment, with optional overrides
  bastion_config = {
    sku                = coalesce(var.bastion_sku_override, var.bastion_config[var.environment].sku)
    scale_units        = coalesce(var.bastion_scale_units_override, var.bastion_config[var.environment].scale_units)
    copy_paste_enabled = var.bastion_config[var.environment].copy_paste_enabled
    file_copy_enabled  = var.bastion_config[var.environment].file_copy_enabled
    ip_connect_enabled = var.bastion_config[var.environment].ip_connect_enabled
    tunneling_enabled  = var.bastion_config[var.environment].tunneling_enabled
    zones              = coalesce(var.bastion_zones_override, var.bastion_config[var.environment].zones)
  }

  # Tags
  hub_tags = merge(
    var.tags,
    {
      Component = "Hub"
      Tier      = "Infrastructure"
      Environment = var.environment
    }
  )
}
