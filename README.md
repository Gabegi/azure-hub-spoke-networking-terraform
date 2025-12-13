# Azure Hub-Spoke Networking with Terraform

Production-ready Azure hub-spoke network topology implemented using Terraform, following Microsoft best practices for enterprise networking.

## Table of Contents
- [Overview](#overview)
- [Architecture](#architecture)
- [IP Address Planning](#ip-address-planning)
- [Naming and Tagging Strategy](#naming-and-tagging-strategy)
- [Project Structure](#project-structure)
- [Modules](#modules)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Module Usage Examples](#module-usage-examples)
- [Security](#security)
- [Cost Considerations](#cost-considerations)
- [References](#references)

## Overview

This Terraform project implements a **hub-spoke network topology** in Azure, designed for medium-sized organizations with room for 3-5 years of growth. The architecture supports up to 10 spoke networks and follows Azure's Well-Architected Framework principles.

### Key Features
- ✅ Hub-spoke topology with centralized network management
- ✅ Non-overlapping CIDR blocks for all VNets
- ✅ Microsoft naming conventions and tagging standards
- ✅ Modular Terraform design for maximum reusability
- ✅ Network Security Groups (NSGs) for all subnets
- ✅ Azure Firewall for centralized security
- ✅ Azure Bastion for secure VM access
- ✅ Custom routing with route tables
- ✅ Reserved IP space for future expansion

## Architecture

```
                    ┌─────────────────────────────┐
                    │       Hub VNet              │
                    │     10.0.0.0/16             │
                    │                             │
                    │  ┌──────────────────────┐   │
                    │  │ Azure Firewall       │   │
                    │  │ 10.0.1.0/24          │   │
                    │  └──────────────────────┘   │
                    │                             │
                    │  ┌──────────────────────┐   │
                    │  │ VPN Gateway          │   │
                    │  │ 10.0.0.0/24          │   │
                    │  └──────────────────────┘   │
                    │                             │
                    │  ┌──────────────────────┐   │
                    │  │ Azure Bastion        │   │
                    │  │ 10.0.2.0/24          │   │
                    │  └──────────────────────┘   │
                    └─────────────┬───────────────┘
                                  │
                    ┌─────────────┴───────────────┐
                    │                             │
        ┌───────────▼──────────┐      ┌──────────▼───────────┐
        │  Staging Spoke       │      │  Production Spoke    │
        │  10.1.0.0/16         │      │  10.2.0.0/16         │
        │                      │      │                      │
        │  ┌────────────────┐  │      │  ┌────────────────┐  │
        │  │ Web (10.1.0.0) │  │      │  │ Web (10.2.0.0) │  │
        │  ├────────────────┤  │      │  ├────────────────┤  │
        │  │ App (10.1.1.0) │  │      │  │ App (10.2.1.0) │  │
        │  ├────────────────┤  │      │  ├────────────────┤  │
        │  │ Data(10.1.2.0) │  │      │  │ Data(10.2.2.0) │  │
        │  └────────────────┘  │      │  └────────────────┘  │
        └──────────────────────┘      └──────────────────────┘
```

## IP Address Planning

### Private IP Selection

We use the **10.x.x.x** range for maximum flexibility:

| Range           | Size      | Use Case                    |
|-----------------|-----------|------------------------------|
| 10.x.x.x        | 16.7M IPs | ✅ **Selected** - Maximum flexibility |
| 172.16-31.x.x   | 1M IPs    | Medium networks              |
| 192.168.x.x     | 65K IPs   | Small networks               |

### VNet Address Space

Non-overlapping /16 CIDR blocks for each VNet (65,536 IPs each):

| VNet         | CIDR Block     | Purpose                    | Status      |
|--------------|----------------|----------------------------|-------------|
| Hub          | 10.0.0.0/16    | Central connectivity hub   | ✅ Active   |
| Staging      | 10.1.0.0/16    | Staging environment        | ✅ Active   |
| Production   | 10.2.0.0/16    | Production workloads       | ✅ Active   |
| DevTest      | 10.3.0.0/16    | Development/Testing        | 📋 Reserved |
| Shared Svcs  | 10.4.0.0/16    | Shared services            | 📋 Reserved |
| DMZ          | 10.5.0.0/16    | DMZ/Partner access         | 📋 Reserved |
| Future 1-5   | 10.6-10.10.0.0/16 | Future expansion        | 📋 Reserved |

### Why /16 per VNet?

- **Too Small (/24)**: Only 256 IPs → Exhausted quickly
- **Too Large (/8)**: Wasteful → Limits future spokes
- **Just Right (/16)**: 65,536 IPs per VNet → Room to grow

### Hub VNet Subnets (10.0.0.0/16)

| Subnet             | CIDR Block     | IPs   | Purpose                          |
|--------------------|----------------|-------|----------------------------------|
| GatewaySubnet      | 10.0.0.0/24    | 256   | VPN/ExpressRoute Gateway         |
| AzureFirewallSubnet| 10.0.1.0/24    | 256   | Azure Firewall                   |
| AzureBastionSubnet | 10.0.2.0/24    | 256   | Bastion host (secure RDP/SSH)    |
| Management         | 10.0.10.0/24   | 256   | Jump boxes, monitoring tools     |
| Shared Services    | 10.0.20.0/24   | 256   | DNS, Active Directory, NTP       |
| Reserved           | 10.0.30.0/20   | 4,096 | Future hub services              |

**Note**: Azure reserves 5 IPs per subnet (.0, .1, .2, .3, and .255), leaving 251 usable IPs per /24 subnet.

### Spoke VNet Subnets (10.1+.0.0/16)

Each spoke follows a consistent 3-tier pattern:

| Tier | CIDR Block    | IPs | Purpose                           |
|------|---------------|-----|-----------------------------------|
| Web  | 10.X.0.0/24   | 256 | Web tier (load balancers, APIM)   |
| App  | 10.X.1.0/24   | 256 | Application tier (compute)        |
| Data | 10.X.2.0/24   | 256 | Data tier (databases, storage)    |

**Example for Staging (10.1.0.0/16)**:
- Web tier: 10.1.0.0/24
- App tier: 10.1.1.0/24
- Data tier: 10.1.2.0/24

**Example for Production (10.2.0.0/16)**:
- Web tier: 10.2.0.0/24
- App tier: 10.2.1.0/24
- Data tier: 10.2.2.0/24

### Growth Capacity

This design supports:
- ✅ Up to **10 spoke networks**
- ✅ **65,536 IPs per VNet** (251 usable per /24 subnet)
- ✅ **3-5 years of growth** for medium companies
- ✅ **Consistent subnet patterns** across environments

## Naming and Tagging Strategy

### Naming Convention

Following [Microsoft's recommended best practices](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-naming):

**Format**: `{resource-type}-{workload}-{environment}-{region}-{instance}`

### Microsoft Guidelines
- ✅ Use **lowercase** only
- ✅ Use **hyphens** (not underscores)
- ✅ Keep names **under 63 characters**
- ✅ Use **consistent abbreviations**
- ✅ Include **region** for global resources

### Resource Type Abbreviations

Following [Microsoft abbreviation standards](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-abbreviations):

| Resource Type          | Abbreviation | Example                              |
|------------------------|--------------|--------------------------------------|
| Virtual Network        | `vnet`       | vnet-hub-prod-westeurope-001         |
| Subnet                 | `snet`       | snet-web-prod-westeurope-001         |
| Network Security Group | `nsg`        | nsg-web-prod-westeurope-001          |
| Azure Firewall         | `afw`        | afw-hub-prod-westeurope-001          |
| Bastion Host           | `bas`        | bas-hub-prod-westeurope-001          |
| Route Table            | `route`      | route-spoke-prod-westeurope-001      |
| Public IP              | `pip`        | pip-firewall-prod-westeurope-001     |
| Log Analytics          | `log`        | log-hub-prod-westeurope-001          |
| Resource Group         | `rg`         | rg-networking-prod-westeurope-001    |
| VNet Peering           | `peer`       | peer-hub-to-staging-001              |

### Tagging Strategy

Following [Azure tagging best practices](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-tagging):

**Mandatory Tags**:
```hcl
{
  Environment = "Production"      # Prod, Staging, Dev
  Location    = "westeurope"      # Azure region
  ManagedBy   = "Terraform"       # Infrastructure as Code tool
  Project     = "HubSpokeNetwork" # Project identifier
  CostCenter  = "IT-Network"      # Billing/chargeback
  CreatedDate = "2025-12-10"      # Resource creation date
}
```

## Project Structure

```
azure-hub-spoke-networking-terraform/
├── provider.tf                    # Terraform and Azure provider configuration
├── variables.tf                   # Root variables (CIDR blocks, regions, etc.)
├── terraform.tfvars.example       # Example variable values
├── LICENSE                        # MIT License
├── README.md                      # This file
├── .gitignore                     # Git ignore rules
│
├── hub/                           # ⭐ Hub VNet configuration
│   ├── locals.tf                  # CIDR calculations and feature flags
│   ├── variables.tf               # Hub-specific input variables
│   ├── 01-foundation.tf           # Resource group
│   ├── 02-networking.tf           # VNet and subnets
│   ├── 03-firewall.tf             # Azure Firewall
│   ├── 04-bastion.tf              # Azure Bastion
│   ├── 05-nsg.tf                  # Network Security Groups
│   ├── 06-firewall-rules.tf       # Firewall policy rules
│   └── 99-outputs.tf              # Hub outputs
│
├── spoke-staging/                 # ⭐ Staging Spoke configuration
│   ├── locals.tf                  # CIDR calculations
│   ├── variables.tf               # Staging-specific variables
│   ├── 01-foundation.tf           # Resource group
│   ├── 02-networking.tf           # VNet and subnets
│   ├── 03-nsg.tf                  # Network Security Groups
│   ├── 04-route-table.tf          # Route tables (forced tunneling)
│   ├── 05-peering.tf              # VNet peering to hub
│   └── 99-outputs.tf              # Staging outputs
│
├── spoke-production/              # ⭐ Production Spoke configuration
│   ├── locals.tf                  # CIDR calculations
│   ├── variables.tf               # Production-specific variables
│   ├── 01-foundation.tf           # Resource group
│   ├── 02-networking.tf           # VNet and subnets
│   ├── 03-nsg.tf                  # Network Security Groups
│   ├── 04-route-table.tf          # Route tables (forced tunneling)
│   ├── 05-peering.tf              # VNet peering to hub
│   └── 99-outputs.tf              # Production outputs
│
└── modules/                       # Reusable Terraform modules
    ├── naming/                    # ⭐ Naming convention module
    │   ├── main.tf                # Naming logic and tag generation
    │   ├── variables.tf           # Naming variables
    │   └── outputs.tf             # Name and tag outputs
    │
    ├── resource-group/            # ⭐ Resource Group module
    │   ├── main.tf                # Resource group with locks
    │   ├── variables.tf           # RG variables
    │   └── outputs.tf             # RG outputs
    │
    ├── vnet/                      # ⭐ Generic VNet module
    │   ├── main.tf                # Virtual network resource
    │   ├── variables.tf           # VNet variables
    │   └── outputs.tf             # VNet outputs
    │
    ├── subnet/                    # ⭐ Generic Subnet module
    │   ├── main.tf                # Subnet resource with delegations
    │   ├── variables.tf           # Subnet variables
    │   └── outputs.tf             # Subnet outputs
    │
    ├── nsg/                       # ⭐ Network Security Group module
    │   ├── main.tf                # NSG with flow logs & Traffic Analytics
    │   ├── variables.tf           # NSG and rule variables
    │   └── outputs.tf             # NSG outputs
    │
    ├── firewall/                  # ⭐ Azure Firewall module
    │   ├── main.tf                # Firewall (Standard/Premium SKU)
    │   ├── variables.tf           # Firewall configuration
    │   └── outputs.tf             # Firewall outputs
    │
    ├── bastion/                   # ⭐ Azure Bastion module
    │   ├── main.tf                # Bastion host (Basic/Standard SKU)
    │   ├── variables.tf           # Bastion configuration
    │   └── outputs.tf             # Bastion outputs
    │
    └── route-table/               # ⭐ Route Table module
        ├── main.tf                # Route table and routes
        ├── variables.tf           # Routing configuration
        └── outputs.tf             # Route table outputs
```

## Modules

### 1. Naming Module (`modules/naming/`)

**Purpose**: Generate consistent resource names and tags following Microsoft conventions.

**Features**:
- Standard naming pattern: `{type}-{workload}-{env}-{region}-{instance}`
- Input validation for all fields
- Automatic tag generation with common Azure tags
- Support for custom tags

**Outputs**:
- `name` - Generated resource name
- `tags` - Standard tags merged with custom tags

---

### 2. VNet Module (`modules/vnet/`)

**Purpose**: Create Azure Virtual Networks with optional DDoS protection.

**Features**:
- Customizable address space
- Custom DNS servers support
- Optional DDoS protection plan
- Lifecycle protection against accidental deletion

**Example**:
```hcl
module "hub_vnet" {
  source = "./modules/vnet"

  vnet_name           = "vnet-hub-prod-westeurope-001"
  location            = "westeurope"
  resource_group_name = "rg-networking-prod"
  address_space       = ["10.0.0.0/16"]
  tags                = { Environment = "Production" }
}
```

---

### 3. Subnet Module (`modules/subnet/`)

**Purpose**: Create subnets with service endpoints and delegations.

**Features**:
- Multiple address prefixes support
- Service endpoints (Storage, SQL, etc.)
- Subnet delegation for Azure services
- Private endpoint policies

**Example**:
```hcl
module "web_subnet" {
  source = "./modules/subnet"

  subnet_name          = "snet-web-prod-westeurope-001"
  resource_group_name  = "rg-networking-prod"
  virtual_network_name = module.hub_vnet.vnet_name
  address_prefixes     = ["10.0.10.0/24"]

  service_endpoints = [
    "Microsoft.Storage",
    "Microsoft.Sql"
  ]
}
```

---

### 4. NSG Module (`modules/nsg/`)

**Purpose**: Create Network Security Groups with flexible security rules.

**Features**:
- Dynamic security rule creation
- Input validation for priorities, protocols, directions
- Optional subnet association
- Support for port ranges and address prefixes

**Example**:
```hcl
module "web_nsg" {
  source = "./modules/nsg"

  nsg_name            = "nsg-web-prod-westeurope-001"
  location            = "westeurope"
  resource_group_name = "rg-networking-prod"

  security_rules = [
    {
      name                       = "AllowHTTPS"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "Internet"
      destination_address_prefix = "*"
    }
  ]

  subnet_id = module.web_subnet.subnet_id
  tags      = { Tier = "Web" }
}
```

---

### 5. Firewall Module (`modules/firewall/`)

**Purpose**: Deploy Azure Firewall with public IP and policies.

**Features**:
- Standard, Premium, or Basic SKU
- Availability zones support
- Threat intelligence (Off/Alert/Deny)
- DNS proxy capability
- Optional firewall policy creation

**Example**:
```hcl
module "firewall" {
  source = "./modules/firewall"

  firewall_name       = "afw-hub-prod-westeurope-001"
  public_ip_name      = "pip-firewall-prod-westeurope-001"
  location            = "westeurope"
  resource_group_name = "rg-networking-prod"
  subnet_id           = module.firewall_subnet.subnet_id

  sku_tier          = "Standard"
  threat_intel_mode = "Alert"
  dns_proxy_enabled = true

  tags = { Role = "Security" }
}
```

**Outputs**:
- Firewall private IP (for route tables)
- Firewall public IP
- Firewall policy ID

---

### 6. Bastion Module (`modules/bastion/`)

**Purpose**: Deploy Azure Bastion for secure RDP/SSH access.

**Features**:
- Basic or Standard SKU
- Scalable (2-50 scale units)
- Copy/paste support
- File copy (Standard SKU)
- IP-based connection (Standard SKU)
- Tunneling support (Standard SKU)

**Example**:
```hcl
module "bastion" {
  source = "./modules/bastion"

  bastion_name        = "bas-hub-prod-westeurope-001"
  public_ip_name      = "pip-bastion-prod-westeurope-001"
  location            = "westeurope"
  resource_group_name = "rg-networking-prod"
  subnet_id           = module.bastion_subnet.subnet_id

  sku                 = "Standard"
  copy_paste_enabled  = true
  file_copy_enabled   = true

  tags = { Purpose = "SecureAccess" }
}
```

---

### 7. Route Table Module (`modules/route-table/`)

**Purpose**: Create route tables with custom routes.

**Features**:
- Multiple route support
- BGP route propagation control
- Support for all next hop types
- Optional subnet association

**Example**:
```hcl
module "spoke_route_table" {
  source = "./modules/route-table"

  route_table_name    = "route-spoke-prod-westeurope-001"
  location            = "westeurope"
  resource_group_name = "rg-networking-prod"

  routes = [
    {
      name                   = "ToFirewall"
      address_prefix         = "0.0.0.0/0"
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = "10.0.1.4" # Firewall private IP
    }
  ]

  subnet_id = module.app_subnet.subnet_id
  tags      = { Purpose = "ForceFirewall" }
}
```

## Prerequisites

### Required Tools
- [Terraform](https://www.terraform.io/downloads.html) >= 1.0
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) >= 2.30
- Azure subscription with appropriate permissions

### Azure Permissions Required
- **Contributor** role on the subscription or resource group
- Ability to create:
  - Virtual Networks
  - Subnets
  - Network Security Groups
  - Azure Firewall
  - Azure Bastion
  - VNet Peerings
  - Route Tables

### Azure Service Quotas
Ensure sufficient quotas for:
- Virtual Networks: 1000 per subscription (default)
- VNet Peerings: 500 per VNet (default)
- Public IPs: 1000 per region (default)

## Quick Start

### 1. Clone and Initialize

```bash
# Clone the repository
git clone <repository-url>
cd azure-hub-spoke-networking-terraform

# Login to Azure
az login

# Set your subscription
az account set --subscription "<your-subscription-id>"

# Initialize Terraform
terraform init
```

### 2. Configure Variables

```bash
# Copy example variables (when available)
cp terraform.tfvars.example terraform.tfvars

# Edit with your values
# Customize: region, environment, tags, etc.
```

### 3. Review and Deploy

```bash
# Format code
terraform fmt -recursive

# Validate configuration
terraform validate

# Review the execution plan
terraform plan -out=tfplan

# Deploy the infrastructure
terraform apply tfplan
```

### 4. Verify Deployment

```bash
# List created VNets
az network vnet list --output table

# View VNet peerings
az network vnet peering list \
  --resource-group rg-networking-prod-westeurope-001 \
  --vnet-name vnet-hub-prod-westeurope-001 \
  --output table

# Check firewall status
az network firewall show \
  --resource-group rg-networking-prod-westeurope-001 \
  --name afw-hub-prod-westeurope-001
```

## Module Usage Examples

### Complete Hub VNet with Firewall and Bastion

```hcl
# Naming for Hub VNet
module "hub_vnet_naming" {
  source = "./modules/naming"

  resource_type = "vnet"
  workload      = "hub"
  environment   = "prod"
  location      = "westeurope"
  instance      = "001"
}

# Hub Virtual Network
module "hub_vnet" {
  source = "./modules/vnet"

  vnet_name           = module.hub_vnet_naming.name
  location            = "westeurope"
  resource_group_name = azurerm_resource_group.networking.name
  address_space       = ["10.0.0.0/16"]
  tags                = module.hub_vnet_naming.tags
}

# Firewall Subnet
module "firewall_subnet" {
  source = "./modules/subnet"

  subnet_name          = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.networking.name
  virtual_network_name = module.hub_vnet.vnet_name
  address_prefixes     = ["10.0.1.0/24"]
}

# Azure Firewall
module "firewall" {
  source = "./modules/firewall"

  firewall_name       = "afw-hub-prod-westeurope-001"
  public_ip_name      = "pip-firewall-prod-westeurope-001"
  location            = "westeurope"
  resource_group_name = azurerm_resource_group.networking.name
  subnet_id           = module.firewall_subnet.subnet_id
  sku_tier            = "Standard"
  threat_intel_mode   = "Alert"
  tags                = module.hub_vnet_naming.tags
}

# Bastion Subnet
module "bastion_subnet" {
  source = "./modules/subnet"

  subnet_name          = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.networking.name
  virtual_network_name = module.hub_vnet.vnet_name
  address_prefixes     = ["10.0.2.0/24"]
}

# Azure Bastion
module "bastion" {
  source = "./modules/bastion"

  bastion_name        = "bas-hub-prod-westeurope-001"
  public_ip_name      = "pip-bastion-prod-westeurope-001"
  location            = "westeurope"
  resource_group_name = azurerm_resource_group.networking.name
  subnet_id           = module.bastion_subnet.subnet_id
  sku                 = "Standard"
  tags                = module.hub_vnet_naming.tags
}
```

### Spoke VNet with 3-Tier Architecture

```hcl
# Production Spoke VNet
module "prod_vnet" {
  source = "./modules/vnet"

  vnet_name           = "vnet-spoke-prod-westeurope-001"
  location            = "westeurope"
  resource_group_name = azurerm_resource_group.networking.name
  address_space       = ["10.2.0.0/16"]
  tags                = { Environment = "Production" }
}

# Web Tier Subnet
module "prod_web_subnet" {
  source = "./modules/subnet"

  subnet_name          = "snet-web-prod-westeurope-001"
  resource_group_name  = azurerm_resource_group.networking.name
  virtual_network_name = module.prod_vnet.vnet_name
  address_prefixes     = ["10.2.0.0/24"]
}

# Web Tier NSG
module "prod_web_nsg" {
  source = "./modules/nsg"

  nsg_name            = "nsg-web-prod-westeurope-001"
  location            = "westeurope"
  resource_group_name = azurerm_resource_group.networking.name
  subnet_id           = module.prod_web_subnet.subnet_id

  security_rules = [
    {
      name                       = "AllowHTTPS"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "Internet"
      destination_address_prefix = "*"
    },
    {
      name                       = "DenyAllInbound"
      priority                   = 4096
      direction                  = "Inbound"
      access                     = "Deny"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }
  ]

  tags = { Tier = "Web" }
}

# App Tier Subnet + NSG (similar pattern)
# Data Tier Subnet + NSG (similar pattern)
```

## Security

### Network Security Groups (NSGs)

Each subnet is protected by an NSG with the principle of **least privilege**:

**Management Subnet NSG**:
- ✅ Allow SSH/RDP from Azure Bastion only
- ❌ Deny all other inbound traffic

**Web Tier NSG**:
- ✅ Allow HTTP/HTTPS from Internet or Azure Firewall
- ✅ Allow health probe traffic
- ❌ Deny all other inbound traffic

**App Tier NSG**:
- ✅ Allow traffic from Web tier only
- ❌ Deny all other inbound traffic

**Data Tier NSG**:
- ✅ Allow traffic from App tier only
- ❌ Deny all other inbound traffic

### Azure Firewall

Centralized network security with:
- Layer 3-4 filtering rules
- Layer 7 application rules
- Threat intelligence-based filtering
- Forced tunneling support

### Azure Bastion

Secure RDP/SSH access without exposing VMs to the internet:
- No public IPs on VMs
- SSL/TLS encrypted connections
- Integrated with Azure AD
- Session recording support

### Security Best Practices

1. **Zero Trust Network Access**
   - Default deny all traffic
   - Explicitly allow required flows
   - Micro-segmentation with NSGs

2. **Encryption**
   - Enable VPN Gateway encryption
   - Use ExpressRoute with MACsec
   - TLS 1.2+ for all services

3. **Monitoring**
   - Enable Network Watcher
   - Configure NSG flow logs
   - Send logs to Log Analytics

4. **Access Control**
   - Use Azure Bastion (no public IPs)
   - Implement JIT VM access
   - Azure AD authentication

## Cost Considerations

### Monthly Cost Estimates (West Europe)

| Component                | Cost/Month | Notes                           |
|--------------------------|------------|---------------------------------|
| Hub VNet                 | €0         | VNets are free                  |
| Spoke VNets (2x)         | €0         | VNets are free                  |
| VNet Peering (2x)        | ~€7-15     | Based on data transfer          |
| Azure Firewall (Standard)| ~€800      | Standard tier + data processing |
| Azure Bastion (Standard) | ~€130      | Standard SKU                    |
| VPN Gateway (VpnGw1)     | ~€125      | If needed for hybrid connectivity |
| **Total (full hub config)** | **~€1,060-1,070** | With all services |
| **Minimal (VNets + peering)** | **~€7-15** | Just networking |

### Cost Optimization Tips

1. **Start Minimal**
   - Deploy VNets and peering first (~€7-15/month)
   - Add Firewall/Bastion only when needed
   - Use VPN Gateway only if hybrid connectivity required

2. **Right-Size Resources**
   - Start with Basic SKUs, upgrade as needed
   - Use Firewall Basic for dev/test (~€6/month vs €800)
   - Bastion Basic for simple scenarios (~€110 vs €130)

3. **Monitor Usage**
   - Track inter-VNet data transfer
   - Review NSG flow logs for optimization
   - Use Azure Cost Management + Budgets

4. **Reserved Instances**
   - 1-year or 3-year reservations for production
   - Can save up to 72% on VPN Gateway
   - Firewall reservations save 40-60%

5. **Shut Down Non-Production**
   - Stop dev/test environments after hours
   - Use Azure DevTest Labs for dev environments
   - Automation with Azure Automation or Logic Apps

## References

### Microsoft Documentation
- [Azure Naming Conventions](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-naming)
- [Resource Abbreviations](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-abbreviations)
- [Tagging Best Practices](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-tagging)
- [Hub-Spoke Network Topology](https://learn.microsoft.com/en-us/azure/architecture/reference-architectures/hybrid-networking/hub-spoke)
- [Azure Virtual Network](https://learn.microsoft.com/en-us/azure/virtual-network/)
- [Network Security Groups](https://learn.microsoft.com/en-us/azure/virtual-network/network-security-groups-overview)
- [Azure Firewall](https://learn.microsoft.com/en-us/azure/firewall/)
- [Azure Bastion](https://learn.microsoft.com/en-us/azure/bastion/)

### Terraform Documentation
- [Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [azurerm_virtual_network](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network)
- [azurerm_subnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet)
- [azurerm_network_security_group](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_group)
- [azurerm_firewall](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/firewall)
- [azurerm_bastion_host](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/bastion_host)
- [azurerm_route_table](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/route_table)

### Additional Resources
- [CIDR Calculator](https://www.ipaddressguide.com/cidr)
- [Subnet Calculator](https://www.calculator.net/ip-subnet-calculator.html)
- [Azure Pricing Calculator](https://azure.microsoft.com/en-us/pricing/calculator/)
- [Azure Speed Test](https://azurespeedtest.azurewebsites.net/) - Test latency between regions

---

## Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Follow existing naming conventions
4. Add tests for new modules
5. Update documentation
6. Submit a pull request

## License

MIT License - See LICENSE file for details

## Support

For issues, questions, or contributions:
- Open an issue on GitHub
- Review existing modules before creating new ones
- Follow Microsoft Azure and Terraform best practices

---

**Last Updated**: 2025-12-10
**Version**: 1.0.0
**Terraform Version**: >= 1.0
**Azure Provider Version**: ~> 3.0
**Maintained By**: Network Engineering Team
