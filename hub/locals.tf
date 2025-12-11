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

  # Tags
  hub_tags = merge(
    var.tags,
    {
      Component = "Hub"
      Tier      = "Infrastructure"
    }
  )
}
