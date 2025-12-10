# Azure Bastion Module

Production-ready Terraform module for deploying Azure Bastion with comprehensive features, monitoring, and best practices.

## Overview

Azure Bastion is a fully managed PaaS service that provides secure RDP/SSH connectivity to your virtual machines directly through the Azure portal, without exposing VMs to the public internet.

### Key Features
- ✅ Secure RDP/SSH without public IPs on VMs
- ✅ Browser-based access (no client needed)
- ✅ SSL/TLS encryption (port 443)
- ✅ Protection against port scanning
- ✅ Integrated with Azure AD for authentication
- ✅ Optional diagnostic logging for compliance
- ✅ High availability with zone redundancy

## Architecture

```
┌─────────────────────────────────────────────────┐
│  Hub VNet (10.0.0.0/16)                         │
│                                                  │
│  ┌─────────────────────────────────────────┐    │
│  │ AzureBastionSubnet (10.0.2.0/26)        │    │
│  │                                          │    │
│  │  ┌────────────────────────────────┐     │    │
│  │  │ Azure Bastion Host             │     │    │
│  │  │ - Public IP: x.x.x.x           │     │    │
│  │  │ - SKU: Standard                │     │    │
│  │  │ - Scale Units: 2-50            │     │    │
│  │  └────────────────────────────────┘     │    │
│  └─────────────────────────────────────────┘    │
│                                                  │
│  ┌─────────────────────────────────────────┐    │
│  │ Application Subnet (10.0.10.0/24)       │    │
│  │                                          │    │
│  │  ┌──────────┐  ┌──────────┐             │    │
│  │  │ VM (RDP) │  │ VM (SSH) │ ← No Public IPs!
│  │  └──────────┘  └──────────┘             │    │
│  └─────────────────────────────────────────┘    │
└─────────────────────────────────────────────────┘
          ▲
          │ HTTPS (port 443)
          │
    ┌───────────┐
    │   Users   │
    │  Browser  │
    └───────────┘
```

## Usage Examples

### Basic Deployment (Minimal Configuration)

```hcl
module "bastion" {
  source = "./modules/bastion"

  bastion_name        = "bas-hub-prod-westeurope-001"
  public_ip_name      = "pip-bastion-prod-westeurope-001"
  location            = "westeurope"
  resource_group_name = "rg-networking-prod"
  subnet_id           = azurerm_subnet.bastion_subnet.id

  tags = {
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}
```

### Standard SKU with All Features

```hcl
module "bastion_standard" {
  source = "./modules/bastion"

  # Basic configuration
  bastion_name        = "bas-hub-prod-westeurope-001"
  public_ip_name      = "pip-bastion-prod-westeurope-001"
  location            = "westeurope"
  resource_group_name = "rg-networking-prod"
  subnet_id           = azurerm_subnet.bastion_subnet.id

  # Standard SKU with scaling
  sku         = "Standard"
  scale_units = 4  # Supports 8 RDP + 40 SSH concurrent sessions

  # Enable all Standard features
  copy_paste_enabled     = true
  file_copy_enabled      = true   # Upload/download files
  ip_connect_enabled     = true   # Connect via IP address
  tunneling_enabled      = true   # Native RDP/SSH client support
  shareable_link_enabled = false  # Security: keep disabled in production

  # High availability
  availability_zones = ["1", "2", "3"]

  # Monitoring and compliance
  enable_diagnostic_settings  = true
  log_analytics_workspace_id  = azurerm_log_analytics_workspace.main.id

  tags = {
    Environment = "Production"
    CostCenter  = "IT-Security"
    Owner       = "NetworkTeam"
    ManagedBy   = "Terraform"
  }
}
```

### Basic SKU (Cost-Optimized)

```hcl
module "bastion_basic" {
  source = "./modules/bastion"

  bastion_name        = "bas-hub-dev-westeurope-001"
  public_ip_name      = "pip-bastion-dev-westeurope-001"
  location            = "westeurope"
  resource_group_name = "rg-networking-dev"
  subnet_id           = azurerm_subnet.bastion_subnet.id

  # Basic SKU (fixed 2 scale units, lower cost)
  sku         = "Basic"

  # Basic SKU only supports copy/paste
  copy_paste_enabled = true

  tags = {
    Environment = "Development"
    ManagedBy   = "Terraform"
  }
}
```

### High Availability Setup

```hcl
module "bastion_ha" {
  source = "./modules/bastion"

  bastion_name        = "bas-hub-prod-westeurope-001"
  public_ip_name      = "pip-bastion-prod-westeurope-001"
  location            = "westeurope"
  resource_group_name = "rg-networking-prod"
  subnet_id           = azurerm_subnet.bastion_subnet.id

  # Standard SKU required for zone redundancy
  sku         = "Standard"
  scale_units = 6  # Scale for higher load

  # Zone redundancy for 99.99% SLA
  availability_zones = ["1", "2", "3"]

  # Enable features
  copy_paste_enabled = true
  ip_connect_enabled = true
  tunneling_enabled  = true

  # Comprehensive monitoring
  enable_diagnostic_settings = true
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  tags = {
    Environment = "Production"
    Criticality = "High"
    ManagedBy   = "Terraform"
  }
}
```

## Requirements

### Subnet Requirements

Azure Bastion **requires** a dedicated subnet:
- **Name**: Must be exactly `AzureBastionSubnet` (case-sensitive)
- **Size**: Minimum /26 (64 IPs), recommended /24 (256 IPs)
- **Network Security Group**: Optional, but if used, must allow specific traffic

**Example Subnet Creation**:
```hcl
resource "azurerm_subnet" "bastion" {
  name                 = "AzureBastionSubnet"  # Required name!
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = ["10.0.2.0/26"]       # Minimum /26
}
```

### NSG Rules (if using NSG on Bastion subnet)

If you attach an NSG to `AzureBastionSubnet`, ensure these rules:

**Inbound**:
```hcl
# Allow HTTPS from Internet
priority: 100 | source: Internet | dest: * | port: 443 | allow

# Allow GatewayManager
priority: 110 | source: GatewayManager | dest: * | port: 443 | allow

# Allow AzureLoadBalancer
priority: 120 | source: AzureLoadBalancer | dest: * | port: 443 | allow

# Allow Bastion Host Communication
priority: 130 | source: VirtualNetwork | dest: VirtualNetwork | port: 8080,5701 | allow
```

**Outbound**:
```hcl
# Allow RDP/SSH to VMs
priority: 100 | source: * | dest: VirtualNetwork | port: 3389,22 | allow

# Allow Azure Cloud Communication
priority: 110 | source: * | dest: AzureCloud | port: 443 | allow

# Allow Bastion Host Communication
priority: 120 | source: VirtualNetwork | dest: VirtualNetwork | port: 8080,5701 | allow

# Allow Internet for session info
priority: 130 | source: * | dest: Internet | port: 80 | allow
```

## SKU Comparison

| Feature                    | Basic SKU | Standard SKU |
|----------------------------|-----------|--------------|
| **Price (approx.)**        | ~€110/mo  | ~€130/mo     |
| **Scale Units**            | 2 (fixed) | 2-50 (variable) |
| **Max Concurrent Sessions**| 4 RDP + 20 SSH | 100 RDP + 500 SSH (at 50 units) |
| **Copy/Paste**             | ✅        | ✅           |
| **File Upload/Download**   | ❌        | ✅           |
| **IP-based Connection**    | ❌        | ✅           |
| **Native Client Tunneling**| ❌        | ✅           |
| **Shareable Links**        | ❌        | ✅           |
| **Availability Zones**     | ✅        | ✅           |
| **Custom Ports**           | ❌        | ✅           |
| **Kerberos Auth**          | ❌        | ✅           |

### Scale Unit Capacity

Each scale unit supports:
- **2 concurrent RDP connections**
- **10 concurrent SSH connections**

**Examples**:
- 2 units (Basic or Standard default) = 4 RDP + 20 SSH
- 10 units (Standard) = 20 RDP + 100 SSH
- 50 units (Standard max) = 100 RDP + 500 SSH

## Inputs

| Name | Type | Default | Required | Description |
|------|------|---------|----------|-------------|
| `bastion_name` | string | - | Yes | Name of the Bastion host (1-80 chars) |
| `public_ip_name` | string | - | Yes | Name of the public IP |
| `location` | string | - | Yes | Azure region |
| `resource_group_name` | string | - | Yes | Resource group name |
| `subnet_id` | string | - | Yes | ID of AzureBastionSubnet |
| `sku` | string | `"Standard"` | No | SKU: Basic or Standard |
| `scale_units` | number | `2` | No | Scale units (2-50, Standard only) |
| `copy_paste_enabled` | bool | `true` | No | Enable copy/paste |
| `file_copy_enabled` | bool | `false` | No | Enable file copy (Standard) |
| `ip_connect_enabled` | bool | `false` | No | Enable IP connect (Standard) |
| `shareable_link_enabled` | bool | `false` | No | Enable shareable links (Standard) |
| `tunneling_enabled` | bool | `false` | No | Enable tunneling (Standard) |
| `availability_zones` | list(string) | `null` | No | Availability zones for HA |
| `enable_diagnostic_settings` | bool | `false` | No | Enable diagnostic logging |
| `log_analytics_workspace_id` | string | `null` | No | Log Analytics workspace ID |
| `tags` | map(string) | `{}` | No | Resource tags |

## Outputs

| Name | Description |
|------|-------------|
| `bastion_id` | Full resource ID of the Bastion host |
| `bastion_name` | Name of the Bastion host |
| `bastion_dns_name` | FQDN of the Bastion host |
| `bastion_sku` | SKU of the Bastion host |
| `bastion_scale_units` | Number of scale units |
| `public_ip_id` | Resource ID of the public IP |
| `public_ip_address` | Public IP address |
| `public_ip_fqdn` | FQDN of the public IP |
| `connection_info` | Comprehensive connection info (object) |
| `resource_group_name` | Resource group name |
| `location` | Azure region |

## Cost Optimization

### Pricing (West Europe, approximate)

| Configuration | Monthly Cost | Use Case |
|---------------|--------------|----------|
| Basic (2 units) | ~€110 | Dev/test, small teams |
| Standard (2 units) | ~€130 | Production, small teams |
| Standard (10 units) | ~€650 | Production, medium teams |
| Standard (50 units) | ~€3,250 | Large enterprises |

**Additional Costs**:
- Data transfer: ~€0.05/GB outbound
- Public IP: Included in Bastion price

### Cost Saving Tips

1. **Use Basic for Non-Production**
   - Dev/test environments don't need advanced features
   - Save ~€20/month per Bastion

2. **Right-Size Scale Units**
   - Monitor concurrent session usage
   - Scale down during off-peak hours (not automated)

3. **Share Bastion Across Environments**
   - One Bastion can connect to VMs in peered VNets
   - Reduces number of Bastion deployments

4. **Disable Unused Features**
   - Shareable links consume resources
   - File copy increases data transfer

## Security Best Practices

### 1. Disable Shareable Links in Production
```hcl
shareable_link_enabled = false  # Security risk if enabled
```

### 2. Enable Diagnostic Logging
```hcl
enable_diagnostic_settings = true
log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
```

**Audit logs include**:
- Who accessed which VM
- When the session started/ended
- Source IP address
- Session duration

### 3. Use Azure AD Conditional Access
- Require MFA for Bastion access
- Restrict by location/device
- Configure session policies

### 4. Implement RBAC
Grant minimum permissions:
```
"Microsoft.Network/bastionHosts/read"
"Microsoft.Compute/virtualMachines/read"
"Microsoft.Network/networkInterfaces/read"
```

### 5. Network Isolation
- Keep Bastion in dedicated subnet
- Use NSG rules to restrict traffic
- Never expose VMs directly to internet

## Monitoring and Alerts

### Key Metrics to Monitor

1. **Session Count**
   - Alert if approaching scale unit capacity
   - Metric: `Sessions`

2. **Used Data**
   - Monitor data transfer for cost optimization
   - Metric: `DataProcessed`

3. **Health Status**
   - Alert on health probe failures
   - Metric: `Health`

### Sample Alert (Azure CLI)

```bash
az monitor metrics alert create \
  --name "bastion-high-sessions" \
  --resource-group rg-networking-prod \
  --scopes /subscriptions/.../bastionHosts/bas-hub-prod \
  --condition "avg Sessions > 80" \
  --description "Bastion session count above 80% capacity"
```

## Troubleshooting

### Common Issues

**1. "Cannot create Bastion - subnet name invalid"**
- Solution: Subnet must be named exactly `AzureBastionSubnet`

**2. "Subnet too small"**
- Solution: Use at least /26 (64 IPs), recommend /24

**3. "Cannot connect to VM"**
- Check VM is running
- Verify NSG allows traffic from Bastion subnet
- Ensure VM has private IP

**4. "File copy not working"**
- Requires Standard SKU
- Check `file_copy_enabled = true`
- Verify browser supports feature

**5. "High latency"**
- Increase scale units
- Check VM performance
- Verify network paths

## Migration Guide

### From Azure VM Jump Box to Bastion

**Before (Jump Box)**:
```
Cost: €100/month (VM) + €5/month (Public IP)
Security: Public IP exposed, requires patching
Access: RDP/SSH client required
```

**After (Bastion)**:
```
Cost: €110-130/month
Security: No public IPs on VMs, fully managed
Access: Browser-based, no client needed
```

**Migration Steps**:
1. Deploy Bastion using this module
2. Test connectivity to VMs via Bastion
3. Remove public IPs from VMs
4. Update NSG rules
5. Decommission jump box VM

## References

### Official Documentation
- [Azure Bastion Overview](https://learn.microsoft.com/en-us/azure/bastion/bastion-overview)
- [Bastion SKU Comparison](https://learn.microsoft.com/en-us/azure/bastion/configuration-settings)
- [Bastion Architecture](https://learn.microsoft.com/en-us/azure/bastion/bastion-faq)
- [Pricing Calculator](https://azure.microsoft.com/en-us/pricing/details/azure-bastion/)

### Terraform Resources
- [azurerm_bastion_host](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/bastion_host)
- [azurerm_public_ip](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip)

---

**Module Version**: 1.0.0
**Last Updated**: 2025-12-10
**Terraform Version**: >= 1.0
**Azure Provider**: ~> 3.0
