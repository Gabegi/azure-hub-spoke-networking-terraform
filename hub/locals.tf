# hub/locals.tf
# Local values for Hub VNet configuration

locals {
  # Hub CIDR calculations
  hub_address_space = var.hub_address_space # 10.0.0.0/16

  # Subnet CIDR blocks
  firewall_subnet     = "10.0.0.0/26"   # 64 IPs - AzureFirewallSubnet (required name)
  app_gateway_subnet  = "10.0.1.0/24"   # 256 IPs - Application Gateway subnet
  gateway_subnet      = "10.0.2.0/26"   # 64 IPs - GatewaySubnet (for VPN/ExpressRoute)
  management_subnet   = "10.0.3.0/27"   # 32 IPs - Management subnet (optional, future use)

  # Feature toggles
  deploy_firewall     = var.deploy_firewall
  deploy_app_gateway  = var.deploy_app_gateway
  deploy_gateway      = var.deploy_gateway
  deploy_mgmt         = var.deploy_management_subnet

  # Monitoring
  enable_diagnostics      = var.enable_diagnostics
  enable_flow_logs        = var.enable_flow_logs
  enable_traffic_analytics = var.enable_traffic_analytics

  # Tags
  hub_tags = merge(
    var.tags,
    {
      Component = "Hub"
      Tier      = "Infrastructure"
    }
  )
}
