# Azure Hub-Spoke Networking with Terraform

Production-ready Azure hub-spoke network topology implemented using Terraform, following Microsoft best practices for enterprise networking with Zero Trust security model.

This repository uses **Terragrunt** to manage the Hub-Spoke infrastructure deployment with automatic dependency management and state orchestration.

---

## 🎯 Hub-Spoke Architecture: How It Works

The hub-spoke architecture enforces **centralized traffic inspection and control** through three critical components working together:

### The Three Pillars

1. **Route Tables** - Force all spoke traffic through the hub firewall
2. **Firewall Network Rules** - Control what traffic is allowed between spokes and to the internet
3. **NSG (Network Security Groups)** - Provide subnet-level security as the first line of defense

**Traffic Flow Example:**
```
Dev VM (10.1.0.5) → Dev NSG (allow) → Route Table (send to 10.0.0.4) →
Hub Firewall (10.0.0.4) (inspect & allow) → Route Table (to prod) →
Prod NSG (allow) → Prod VM (10.2.0.5)
```

Without ANY ONE of these components, spoke-to-spoke communication would fail or bypass security controls.

---

## 📋 Complete Rule Set Reference

### 🔥 Firewall Network Rules (Hub - 10.0.0.4)

**Purpose:** Centralized policy enforcement for all spoke-to-spoke and spoke-to-internet traffic.

| Rule Name | Protocol | Source | Destination | Ports | Purpose |
|-----------|----------|--------|-------------|-------|---------|
| **AllowDevToProdSSH** | TCP | 10.1.0.0/24 | 10.2.0.0/24 | 22 | Dev VM → Prod VM SSH |
| **AllowProdToDevSSH** | TCP | 10.2.0.0/24 | 10.1.0.0/24 | 22 | Prod VM → Dev VM SSH |
| **AllowDevToProdICMP** | ICMP | 10.1.0.0/24 | 10.2.0.0/24 | * | Dev VM → Prod VM ping |
| **AllowProdToDevICMP** | ICMP | 10.2.0.0/24 | 10.1.0.0/24 | * | Prod VM → Dev VM ping |
| **AllowDevVMInternet** | TCP | 10.1.0.0/24 | * | 80, 443 | Dev VM → Internet (updates) |
| **AllowProdVMInternet** | TCP | 10.2.0.0/24 | * | 80, 443 | Prod VM → Internet (updates) |
| **AllowDNS** | UDP | 10.1.0.0/24<br>10.2.0.0/24 | * | 53 | DNS resolution |

**Default Action:** Deny all traffic not explicitly allowed ⛔

---

### 🛣️ Route Tables (Spoke Subnets)

**Purpose:** Override Azure's default routing to force traffic through the hub firewall for inspection.

#### Development Spoke (10.1.0.0/16)

| Route Name | Destination | Next Hop Type | Next Hop IP | Purpose |
|------------|-------------|---------------|-------------|---------|
| **InternetViaFirewall** | 0.0.0.0/0 | VirtualAppliance | 10.0.0.4 | All internet traffic → Firewall |
| **ProductionSpokeViaFirewall** | 10.2.0.0/16 | VirtualAppliance | 10.0.0.4 | All prod traffic → Firewall |

#### Production Spoke (10.2.0.0/16)

| Route Name | Destination | Next Hop Type | Next Hop IP | Purpose |
|------------|-------------|---------------|-------------|---------|
| **InternetViaFirewall** | 0.0.0.0/0 | VirtualAppliance | 10.0.0.4 | All internet traffic → Firewall |
| **DevelopmentSpokeViaFirewall** | 10.1.0.0/16 | VirtualAppliance | 10.0.0.4 | All dev traffic → Firewall |

**⚠️ Critical:** `bgp_route_propagation_enabled = false` prevents on-premises routes from bypassing the firewall.

---

### 🛡️ NSG Rules (Subnet-Level Security)

**Purpose:** First line of defense before traffic reaches the route table. Defense in depth.

#### Development VM Subnet NSG (10.1.0.0/24)

**Inbound Rules:**

| Priority | Name | Direction | Protocol | Source | Destination | Ports | Action |
|----------|------|-----------|----------|--------|-------------|-------|--------|
| 100 | AllowProdVMSSHInbound | Inbound | TCP | 10.2.0.0/24 | 10.1.0.0/24 | 22 | Allow ✅ |
| 110 | AllowProdVMICMPInbound | Inbound | ICMP | 10.2.0.0/24 | 10.1.0.0/24 | * | Allow ✅ |
| 4095 | AllowAzureLoadBalancer | Inbound | * | AzureLoadBalancer | * | * | Allow ✅ |
| 4096 | DenyAllInbound | Inbound | * | * | * | * | Deny ⛔ |

**Outbound Rules:**

| Priority | Name | Direction | Protocol | Source | Destination | Ports | Action |
|----------|------|-----------|----------|--------|-------------|-------|--------|
| 100 | AllowToProdVMSSH | Outbound | TCP | 10.1.0.0/24 | 10.2.0.0/24 | 22 | Allow ✅ |
| 110 | AllowToProdVMICMP | Outbound | ICMP | 10.1.0.0/24 | 10.2.0.0/24 | * | Allow ✅ |
| 200 | AllowInternetHTTPS | Outbound | TCP | 10.1.0.0/24 | Internet | 443 | Allow ✅ |
| 210 | AllowInternetHTTP | Outbound | TCP | 10.1.0.0/24 | Internet | 80 | Allow ✅ |
| 300 | AllowDNS | Outbound | UDP | 10.1.0.0/24 | Internet | 53 | Allow ✅ |
| 4096 | DenyAllOutbound | Outbound | * | * | * | * | Deny ⛔ |

#### Production VM Subnet NSG (10.2.0.0/24)

**Inbound Rules:**

| Priority | Name | Direction | Protocol | Source | Destination | Ports | Action |
|----------|------|-----------|----------|--------|-------------|-------|--------|
| 100 | AllowDevVMSSHInbound | Inbound | TCP | 10.1.0.0/24 | 10.2.0.0/24 | 22 | Allow ✅ |
| 110 | AllowDevVMICMPInbound | Inbound | ICMP | 10.1.0.0/24 | 10.2.0.0/24 | * | Allow ✅ |
| 4095 | AllowAzureLoadBalancer | Inbound | * | AzureLoadBalancer | * | * | Allow ✅ |
| 4096 | DenyAllInbound | Inbound | * | * | * | * | Deny ⛔ |

**Outbound Rules:**

| Priority | Name | Direction | Protocol | Source | Destination | Ports | Action |
|----------|------|-----------|----------|--------|-------------|-------|--------|
| 100 | AllowToDevVMSSH | Outbound | TCP | 10.2.0.0/24 | 10.1.0.0/24 | 22 | Allow ✅ |
| 110 | AllowToDevVMICMP | Outbound | ICMP | 10.2.0.0/24 | 10.1.0.0/24 | * | Allow ✅ |
| 200 | AllowInternetHTTPS | Outbound | TCP | 10.2.0.0/24 | Internet | 443 | Allow ✅ |
| 210 | AllowInternetHTTP | Outbound | TCP | 10.2.0.0/24 | Internet | 80 | Allow ✅ |
| 300 | AllowDNS | Outbound | UDP | 10.2.0.0/24 | Internet | 53 | Allow ✅ |
| 4096 | DenyAllOutbound | Outbound | * | * | * | * | Deny ⛔ |

**Default NSG Behavior:** Explicit deny-all rules ensure Zero Trust - nothing is allowed unless explicitly permitted.

---

### 🔗 VNet Peering Configuration

**Purpose:** Establish connectivity between hub and spokes while preventing direct spoke-to-spoke communication.

| Peering | From | To | allow_virtual_network_access | allow_forwarded_traffic | use_remote_gateways |
|---------|------|-----|------------------------------|-------------------------|---------------------|
| spoke-to-hub | Dev/Prod | Hub | ✅ true | ✅ true | ❌ false |
| hub-to-spoke | Hub | Dev/Prod | ✅ true | ✅ true | ❌ false |

**Key Points:**
- `allow_forwarded_traffic = true` - Critical for hub firewall to forward spoke-to-spoke traffic
- No direct spoke-to-spoke peering exists - forces traffic through hub
- Gateway transit disabled (we're using firewall, not VPN/ExpressRoute gateway)

---

## 🚦 What Would Break Without Each Component?

| Missing Component | Result | Why |
|------------------|--------|-----|
| **Route Tables** | Spokes communicate directly via VNet peering | Azure's default routing bypasses the firewall |
| **Firewall Rules** | All spoke-to-spoke traffic blocked | Firewall defaults to deny-all |
| **NSG Rules** | Traffic would reach firewall but might bypass subnet restrictions | Defense-in-depth broken |
| **VNet Peering** | Complete network isolation | No connectivity between hub and spokes |
| **allow_forwarded_traffic** | Firewall can't forward spoke-to-spoke traffic | Peering doesn't allow transit |

**All components must work together** - this is defense-in-depth and Zero Trust in action.

---

## ⚠️ IMPORTANT: Use Terragrunt Commands, NOT Terraform

**DO NOT run `terraform init`, `terraform plan`, or `terraform apply`**

Instead, use Terragrunt commands:

- ❌ `terraform init` → ✅ `terragrunt init` or `terragrunt run-all init`
- ❌ `terraform plan` → ✅ `terragrunt plan` or `terragrunt run-all plan`
- ❌ `terraform apply` → ✅ `terragrunt apply` or `terragrunt run-all apply`

In our case, we only need two
Deploy all (hub first, then spokes automatically)
terragrunt run-all apply

Destroy all (spokes first, then hub automatically)
terragrunt run-all destroy

Terragrunt wraps Terraform and adds automatic dependency management, remote state configuration, and DRY principles.

with Terragrunt, you don't run terraform init at all. You use Terragrunt commands instead.

From Root Directory:

# Initialize all modules (hub + both spokes)

terragrunt run-all init

# Plan all modules

terragrunt run-all plan

# Apply all modules (deploys everything in correct order)

terragrunt run-all apply

Or Initialize Individual Modules:

# Initialize just the hub

cd hub
terragrunt init

# Initialize just dev spoke

cd spoke-development
terragrunt init

What Terragrunt Does

When you run terragrunt init, it:

1. Auto-generates backend.tf (Azure Storage state config)
2. Auto-generates provider.tf (Azure provider)
3. Runs terraform init for you automatically
4. Configures remote state

# Destroy everything

From root folder run terragrunt run-all destroy

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Key Features](#key-features)
- [IP Address Planning](#ip-address-planning)
- [Security Model](#security-model)
- [Project Structure](#project-structure)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Testing Connectivity](#testing-connectivity)
- [Cost Considerations](#cost-considerations)
- [References](#references)

## Overview

This Terraform project implements a **hub-spoke network topology** in Azure with **two environments**:

- **Development** (10.1.0.0/16) - Full internet access for development
- **Production** (10.2.0.0/16) - Restricted access with Zero Trust principles

All infrastructure is **fully variable-driven**, making it easy to customize and extend.

### Key Features

✅ **Hub-Spoke Architecture**

- Centralized hub VNet (10.0.0.0/16) with Azure Firewall and Bastion
- Two spoke VNets (Development and Production)
- VNet peering with forced tunneling through hub firewall

✅ **Security**

- Azure Firewall with Zero Trust policies
- NSG rules fully configurable via variables
- Route tables with explicit spoke-to-spoke routes
- Azure Bastion for secure VM access (no public IPs)

✅ **Network Services**

- Application Gateway (mandatory, always deployed)
- Azure Firewall (Standard/Premium SKU)
- Azure Bastion (Basic/Standard SKU)
- Management subnet (ready for jumpboxes)

✅ **Infrastructure as Code**

- Fully modular Terraform design
- Variable-driven configuration
- Microsoft naming conventions
- Comprehensive tagging strategy

✅ **Testing**

- Test VMs in each spoke (Ubuntu 22.04 with nginx)
- Pre-configured connectivity test scripts
- Ready for spoke-to-spoke communication testing

## Architecture

```
                    ┌─────────────────────────────────────┐
                    │       Hub VNet (10.0.0.0/16)        │
                    │                                     │
                    │  ┌───────────────────────────────┐  │
                    │  │ Azure Firewall (10.0.0.0/26)  │  │
                    │  │ Zero Trust Policy Engine      │  │
                    │  └───────────────────────────────┘  │
                    │                                     │
                    │  ┌───────────────────────────────┐  │
                    │  │ Azure Bastion (10.0.1.0/26)   │  │
                    │  │ Secure VM Access              │  │
                    │  └───────────────────────────────┘  │
                    │                                     │
                    │  ┌───────────────────────────────┐  │
                    │  │ App Gateway (10.0.4.0/24)     │  │
                    │  │ Application Load Balancer     │  │
                    │  └───────────────────────────────┘  │
                    │                                     │
                    │  ┌───────────────────────────────┐  │
                    │  │ Management (10.0.3.0/24)      │  │
                    │  │ Empty (for jumpboxes)         │  │
                    │  └───────────────────────────────┘  │
                    └────────────┬────────────────────────┘
                                 │
                    ┌────────────┴────────────┐
                    │                         │
        ┌───────────▼──────────┐  ┌──────────▼───────────┐
        │  Development Spoke   │  │  Production Spoke    │
        │  10.1.0.0/16         │  │  10.2.0.0/16         │
        │                      │  │                      │
        │  ┌────────────────┐  │  │  ┌────────────────┐  │
        │  │ Workload       │  │  │  │ Workload       │  │
        │  │ (10.1.1.0/24)  │  │  │  │ (10.2.1.0/24)  │  │
        │  │ ✅ Test VM      │  │  │  │ ✅ Test VM      │  │
        │  ├────────────────┤  │  │  ├────────────────┤  │
        │  │ Data           │  │  │  │ Data           │  │
        │  │ (10.1.2.0/24)  │  │  │  │ (10.2.2.0/24)  │  │
        │  ├────────────────┤  │  │  ├────────────────┤  │
        │  │ App            │  │  │  │ App            │  │
        │  │ (10.1.3.0/24)  │  │  │  │ (10.2.3.0/24)  │  │
        │  └────────────────┘  │  │  └────────────────┘  │
        └──────────────────────┘  └──────────────────────┘

Traffic Flow:
- All spoke traffic → Hub Firewall → Destination
- Development → Production: HTTPS (443) ALLOWED
- Production → Development: BLOCKED (one-way only)
```

## IP Address Planning

### VNet Address Spaces

| VNet        | CIDR Block        | Purpose                  | Status       |
| ----------- | ----------------- | ------------------------ | ------------ |
| Hub         | 10.0.0.0/16       | Central connectivity hub | ✅ Active    |
| Development | 10.1.0.0/16       | Development environment  | ✅ Active    |
| Production  | 10.2.0.0/16       | Production workloads     | ✅ Active    |
| Reserved    | 10.3-10.10.0.0/16 | Future expansion         | 📋 Available |

### Hub VNet Subnets (10.0.0.0/16)

| Subnet              | CIDR Block  | IPs | Purpose                        |
| ------------------- | ----------- | --- | ------------------------------ |
| AzureFirewallSubnet | 10.0.0.0/26 | 64  | Azure Firewall (required name) |
| AzureBastionSubnet  | 10.0.1.0/26 | 64  | Azure Bastion (required name)  |
| Management          | 10.0.3.0/24 | 256 | Jumpboxes, DevOps agents       |
| App Gateway         | 10.0.4.0/24 | 256 | Application Gateway            |

### Spoke VNet Subnets

Each spoke follows a consistent 3-tier pattern:

**Development (10.1.0.0/16)**:

- Workload: 10.1.1.0/24 (256 IPs) - Contains test VM
- Data: 10.1.2.0/24 (256 IPs)
- App: 10.1.3.0/24 (256 IPs)

**Production (10.2.0.0/16)**:

- Workload: 10.2.1.0/24 (256 IPs) - Contains test VM
- Data: 10.2.2.0/24 (256 IPs)
- App: 10.2.3.0/24 (256 IPs)

## Security Model

### Zero Trust Architecture

**Firewall Rules**:

- ✅ Development → Full Azure services + Internet (GitHub, npm, Docker, etc.)
- ✅ Development → Production: **HTTPS (443) ONLY** for API calls
- ✅ Production → Essential Azure services only (whitelist approach)
- ❌ Production → Development: **BLOCKED** (no reverse access)
- ❌ Production → General Internet: **BLOCKED** (essential services only)

**Network Security Groups** (Fully Variable-Driven):

- Management subnet: SSH/RDP from Bastion only
- App Gateway subnet: Required ports for Gateway Manager + HTTPS from internet
- All rules configurable via tfvars files

**Route Tables** (Fully Variable-Driven):

- All spoke traffic forced through hub firewall
- Explicit routes for spoke-to-spoke communication
- Routes prevent VNet peering bypass
- All routes configurable via tfvars files

### Traffic Flow Examples

```bash
# Dev → Internet (ALLOWED)
Dev VM (10.1.1.5) → Firewall → Internet ✅

# Dev → Prod API (ALLOWED)
Dev VM (10.1.1.5) → Firewall → Prod VM (10.2.1.10):443 ✅

# Prod → Dev (BLOCKED)
Prod VM (10.2.1.10) → Firewall → DENIED ❌

# Prod → Internet (RESTRICTED)
Prod VM (10.2.1.10) → Firewall → Whitelist check → DENIED (unless approved) ❌
```

## Project Structure

```
azure-hub-spoke-networking-terraform/
├── provider.tf                    # Terraform and Azure provider config
├── README.md                      # This file
├── .gitignore                     # Git ignore rules
│
├── hub/                           # ⭐ Hub VNet (standalone module)
│   ├── variables.tf               # Hub input variables
│   ├── locals.tf                  # CIDR calculations and feature flags
│   ├── 01-foundation.tf           # Resource group
│   ├── 02-networking.tf           # VNet and subnets
│   ├── 03-firewall.tf             # Azure Firewall
│   ├── 04-bastion.tf              # Azure Bastion
│   ├── 05-nsg.tf                  # Network Security Groups (variable-driven)
│   ├── 06-firewall-rules.tf       # Firewall policy rules (Zero Trust)
│   ├── 07-app-gateway.tf          # Application Gateway
│   └── 99-outputs.tf              # Hub outputs
│
├── spoke-development/             # ⭐ Development Spoke (standalone module)
│   ├── variables.tf               # Development-specific variables
│   ├── locals.tf                  # CIDR calculations
│   ├── 01-foundation.tf           # Resource group
│   ├── 02-networking.tf           # VNet and subnets
│   ├── 03-nsg.tf                  # Network Security Groups
│   ├── 04-route-table.tf          # Route tables (variable-driven)
│   ├── 05-peering.tf              # VNet peering to hub
│   ├── 06-test-vm.tf              # Test VM (Ubuntu + nginx)
│   └── 99-outputs.tf              # Development outputs
│
├── spoke-production/              # ⭐ Production Spoke (standalone module)
│   ├── variables.tf               # Production-specific variables
│   ├── locals.tf                  # CIDR calculations
│   ├── 01-foundation.tf           # Resource group
│   ├── 02-networking.tf           # VNet and subnets
│   ├── 03-nsg.tf                  # Network Security Groups
│   ├── 04-route-table.tf          # Route tables (variable-driven)
│   ├── 05-peering.tf              # VNet peering to hub
│   ├── 06-test-vm.tf              # Test VM (Ubuntu + nginx)
│   └── 99-outputs.tf              # Production outputs
│
├── vars/                          # Configuration files
│   ├── dev.tfvars                 # Development environment config
│   ├── prod.tfvars                # Production environment config (gitignored)
│   ├── example/
│   │   └── prod.tfvars.example    # Production config template
│   └── README.md                  # Vars documentation
│
└── modules/                       # Reusable Terraform modules
    ├── naming/                    # Naming convention module
    ├── resource-group/            # Resource group module
    ├── vnet/                      # Virtual network module
    ├── subnet/                    # Subnet module
    ├── nsg/                       # Network security group module
    ├── firewall/                  # Azure Firewall module
    ├── bastion/                   # Azure Bastion module
    ├── app-gateway/               # Application Gateway module
    ├── route-table/               # Route table module
    └── vm/                        # Virtual machine module
```

## Prerequisites

### Required Tools

- [Terraform](https://www.terraform.io/downloads.html) >= 1.0
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) >= 2.30
- Azure subscription with Contributor permissions

### Required Configuration

**1. SSH Key for Test VMs**

Generate an SSH key pair:

```bash
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"
```

Get your public key:

```bash
cat ~/.ssh/id_rsa.pub
```

Add it to your tfvars files (see Quick Start below).

## Quick Start

### 1. Clone and Configure

```bash
# Clone the repository
git clone <repository-url>
cd azure-hub-spoke-networking-terraform

# Login to Azure
az login

# Set your subscription
az account set --subscription "<your-subscription-id>"
```

### 2. Add Your SSH Public Key

Edit **vars/dev.tfvars** and **vars/prod.tfvars**, replace this line:

```hcl
vm_admin_ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC... (REPLACE_WITH_YOUR_PUBLIC_KEY)"
```

With your actual SSH public key from `cat ~/.ssh/id_rsa.pub`

### 3. Deploy Hub

```bash
cd hub
terraform init
terraform plan -var-file="../vars/prod.tfvars"
terraform apply -var-file="../vars/prod.tfvars"
```

This deploys:

- Hub VNet (10.0.0.0/16)
- Azure Firewall with Zero Trust policies
- Azure Bastion for secure access
- Application Gateway
- NSGs for Management and App Gateway subnets

### 4. Deploy Development Spoke

```bash
cd ../spoke-development
terraform init
terraform plan -var-file="../vars/dev.tfvars"
terraform apply -var-file="../vars/dev.tfvars"
```

This deploys:

- Development VNet (10.1.0.0/16)
- 3 subnets (workload, data, app)
- VNet peering to hub
- Route tables with explicit routes
- Test VM in workload subnet

### 5. Deploy Production Spoke

```bash
cd ../spoke-production
terraform init
terraform plan -var-file="../vars/prod.tfvars"
terraform apply -var-file="../vars/prod.tfvars"
```

This deploys:

- Production VNet (10.2.0.0/16)
- 3 subnets (workload, data, app)
- VNet peering to hub
- Route tables with explicit routes
- Test VM in workload subnet

## Testing Connectivity

### Access Test VMs via Bastion

1. Go to Azure Portal → Bastion
2. Connect to Development Test VM
3. Username: `azureuser`
4. Use SSH private key authentication

### Run Connectivity Tests

**On Development VM**:

```bash
# Run pre-configured test script
~/test-connectivity.sh

# Manual tests:
# 1. Test internet access (should work)
curl -I https://www.google.com

# 2. Test access to Production VM (should work on port 80)
curl http://<prod-vm-private-ip>:80

# Should see: "Production Spoke Test VM - <hostname>"
```

**On Production VM**:

```bash
# Run pre-configured test script
~/test-connectivity.sh

# Manual test:
# Test access to Development VM (should FAIL - blocked by firewall)
curl http://<dev-vm-private-ip>:80 --max-time 5

# Should timeout (connection blocked by firewall)
```

### Expected Results

| Test        | Source  | Destination    | Expected Result         |
| ----------- | ------- | -------------- | ----------------------- |
| Internet    | Dev VM  | google.com:443 | ✅ SUCCESS              |
| Internet    | Prod VM | google.com:443 | ✅ SUCCESS (restricted) |
| Spoke→Spoke | Dev VM  | Prod VM:80     | ✅ SUCCESS              |
| Spoke→Spoke | Prod VM | Dev VM:80      | ❌ BLOCKED              |

## Cost Considerations

### Monthly Cost Estimates (West Europe)

| Component                 | Cost/Month  | Notes                               |
| ------------------------- | ----------- | ----------------------------------- |
| Hub VNet                  | €0          | VNets are free                      |
| Development VNet          | €0          | VNets are free                      |
| Production VNet           | €0          | VNets are free                      |
| VNet Peering (2x)         | ~€7-15      | Based on data transfer              |
| Azure Firewall (Standard) | ~€800       | Can disable for dev (~€800 savings) |
| Azure Bastion (Standard)  | ~€130       | Required for VM access              |
| Application Gateway v2    | ~€200       | Mandatory component                 |
| Test VMs (2x B2s)         | ~€60        | Can be stopped when not in use      |
| **Total (all services)**  | **~€1,200** | Full production setup               |
| **Dev-optimized**         | **~€400**   | Firewall disabled in dev            |

### Cost Optimization Tips

1. **Development Environment**

   - Set `deploy_firewall = false` in dev.tfvars (saves ~€800/month)
   - Stop test VMs when not in use (saves ~€30/month)
   - Use Basic Bastion SKU instead of Standard (saves ~€20/month)

2. **Production Environment**

   - Use Azure Firewall reservations (save 40-60%)
   - Monitor and optimize data transfer costs
   - Use autoscaling for Application Gateway

3. **General**
   - Delete non-production environments when not needed
   - Use Azure Cost Management + Budgets
   - Set up budget alerts

## Naming Convention

Following [Microsoft's recommended best practices](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-naming):

**Format**: `{resource-type}-{workload}-{environment}-{region}-{instance}`

**Examples**:

- `vnet-hub-prod-westeurope-001`
- `afw-hub-prod-westeurope-001`
- `vm-test-dev-westeurope-001`

## References

### Microsoft Documentation

- [Hub-Spoke Network Topology](https://learn.microsoft.com/en-us/azure/architecture/reference-architectures/hybrid-networking/hub-spoke)
- [Azure Firewall](https://learn.microsoft.com/en-us/azure/firewall/)
- [Azure Bastion](https://learn.microsoft.com/en-us/azure/bastion/)
- [Application Gateway](https://learn.microsoft.com/en-us/azure/application-gateway/)
- [Azure Naming Conventions](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-naming)

### Terraform Documentation

- [Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [azurerm_virtual_network](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network)
- [azurerm_firewall](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/firewall)

---

**Last Updated**: 2025-12-25
**Version**: 2.0.0
**Terraform Version**: >= 1.0
**Azure Provider Version**: ~> 3.0

**License**: MIT
