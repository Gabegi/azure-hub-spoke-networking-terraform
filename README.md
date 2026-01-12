# Azure Hub-Spoke Networking with Terraform

Production-ready Azure hub-spoke network topology with Zero Trust security, managed via Terragrunt for automatic dependency orchestration.

---

## 📋 Complete Security Reference

**🔐 [VIEW ALL SECURITY RULES →](./SECURITY-RULES.md)**

All firewall rules, NSG rules, route tables, and network policies are documented in [SECURITY-RULES.md](./SECURITY-RULES.md):
- 7 Firewall Network Rules
- 10 NSG Rules per Spoke (Dev + Prod)
- Route Tables for forced tunneling
- VNet Peering configuration
- Traffic flow examples

---

## 🚀 Quick Start

### Prerequisites

- [Terragrunt](https://terragrunt.gruntwork.io/docs/getting-started/install/) >= 0.48
- [Terraform](https://www.terraform.io/downloads.html) >= 1.0
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) >= 2.30
- Azure subscription with Contributor permissions

### Deploy Everything

```bash
# 1. Login to Azure
az login
az account set --subscription "<your-subscription-id>"

# 2. Add your SSH public key to tfvars files
# Edit vars/dev.auto.tfvars.hcl and vars/prod.auto.tfvars.hcl
# Replace vm_admin_ssh_public_key with your public key from:
cat ~/.ssh/id_rsa.pub

# 3. Deploy all infrastructure (hub + spokes)
terragrunt run-all init
terragrunt run-all plan
terragrunt run-all apply
```

**Terragrunt automatically:**
- Deploys hub first (firewall, bastion, app gateway)
- Deploys both spokes in parallel after hub is ready
- Configures Azure Storage backend for state files

### Destroy Everything

```bash
# Destroy all resources (spokes → hub)
terragrunt run-all destroy
```

---

## 🏗️ Architecture

```
                    ┌─────────────────────────────────────┐
                    │       Hub VNet (10.0.0.0/16)        │
                    │                                     │
                    │  ┌───────────────────────────────┐  │
                    │  │ Azure Firewall (10.0.0.4)     │  │
                    │  │ ← All Traffic Routes Here     │  │
                    │  └───────────────────────────────┘  │
                    │                                     │
                    │  App Gateway (10.0.4.0/24)          │
                    └────────────┬────────────────────────┘
                                 │
                    ┌────────────┴────────────┐
                    │                         │
        ┌───────────▼──────────┐  ┌──────────▼───────────┐
        │  Dev Spoke           │  │  Prod Spoke          │
        │  10.1.0.0/16         │  │  10.2.0.0/16         │
        │  ✅ VM (10.1.0.0/24) │  │  ✅ VM (10.2.0.0/24) │
        └──────────────────────┘  └──────────────────────┘

Traffic Flow: Spoke → Route Table → Firewall → NSG → Destination
```

### Key Components

- **Hub VNet (10.0.0.0/16)**: Centralized connectivity hub with Azure Firewall, Bastion, and Application Gateway
- **Dev Spoke (10.1.0.0/16)**: Development environment with full internet access
- **Prod Spoke (10.2.0.0/16)**: Production environment with restricted access
- **Forced Tunneling**: All spoke traffic routed through hub firewall (10.0.0.4) for inspection
- **Zero Trust**: Explicit deny-all + allow-list approach for all traffic

---

## 🔒 Security Model

### The Three Pillars

The hub-spoke architecture works through three components that **must work together**:

1. **Route Tables** → Force all spoke traffic through the hub firewall (10.0.0.4)
2. **Firewall Rules** → Control what traffic is allowed between spokes and internet
3. **NSG Rules** → Subnet-level security as first line of defense

**Traffic Example:**
```
Dev VM → Dev NSG ✅ → Route Table (→ 10.0.0.4) → Firewall ✅ → Prod NSG ✅ → Prod VM
```

**Without any ONE component:**
- No Route Tables → Traffic bypasses firewall via direct VNet peering ❌
- No Firewall Rules → All traffic blocked (default deny) ❌
- No NSG Rules → No defense-in-depth, single point of failure ❌

### Allowed Traffic

| Source | Destination | Ports | Status |
|--------|-------------|-------|--------|
| Dev VM | Prod VM | 22 (SSH), ICMP | ✅ Allowed |
| Prod VM | Dev VM | 22 (SSH), ICMP | ✅ Allowed |
| Dev VM | Internet | 80, 443, 53 | ✅ Allowed |
| Prod VM | Internet | 80, 443, 53 | ✅ Allowed |
| All Other Traffic | Any | Any | ❌ Denied |

**📋 [Complete security rules reference →](./SECURITY-RULES.md)**

---

## ⚠️ Use Terragrunt, NOT Terraform

This project uses **Terragrunt** for automatic dependency management and state orchestration.

### Why Terragrunt?

- **Automatic dependency management** - Deploys hub before spokes, destroys spokes before hub
- **Remote state configuration** - Auto-configures Azure Storage backend
- **DRY principles** - Eliminates duplicate backend/provider configuration
- **Module orchestration** - Runs multiple modules in correct order

### Command Reference

| Task | ❌ Don't Use | ✅ Use Instead |
|------|--------------|----------------|
| Initialize | `terraform init` | `terragrunt run-all init` |
| Plan | `terraform plan` | `terragrunt run-all plan` |
| Apply | `terraform apply` | `terragrunt run-all apply` |
| Destroy | `terraform destroy` | `terragrunt run-all destroy` |

**Deploy individual module:**
```bash
cd hub
terragrunt init
terragrunt apply
```

**Deploy all modules:**
```bash
# From root directory
terragrunt run-all apply
```

---

## 🧪 Testing Connectivity

### Access VMs via Azure Portal

1. Navigate to Azure Portal → Virtual Machines
2. Select VM → Connect → Serial Console
3. Login with username: `azureuser`

### Test SSH Between VMs

**From Dev VM:**
```bash
# SSH to Prod VM (should work)
ssh azureuser@10.2.0.x

# Ping Prod VM (should work)
ping 10.2.0.x
```

**From Prod VM:**
```bash
# SSH to Dev VM (should work)
ssh azureuser@10.1.0.x

# Ping Dev VM (should work)
ping 10.1.0.x
```

### Test Internet Access

```bash
# Test HTTPS (should work)
curl -I https://www.google.com

# Update packages (should work via firewall)
sudo apt update
```

### Expected Results

| Test | Source | Destination | Expected |
|------|--------|-------------|----------|
| SSH | Dev VM | Prod VM | ✅ Success |
| SSH | Prod VM | Dev VM | ✅ Success |
| Ping | Dev VM | Prod VM | ✅ Success |
| Internet | Dev VM | google.com | ✅ Success |
| Internet | Prod VM | google.com | ✅ Success |

All traffic flows through the hub firewall at 10.0.0.4 for inspection.

---

## 💰 Cost Considerations

### Monthly Estimates (East US)

| Component | Cost/Month | Notes |
|-----------|------------|-------|
| Azure Firewall (Standard) | ~$800 | Largest cost, required for hub-spoke |
| Application Gateway v2 | ~$200 | Layer 7 load balancer |
| VNet Peering (2x) | ~$10 | Minimal data transfer costs |
| VMs (2x Standard_D2s_v3) | ~$140 | Stop when not in use to save costs |
| **Total** | **~$1,150** | Full production setup |

### Cost Optimization

- **Stop VMs** when not in use (saves ~$140/month)
- **Use Azure Firewall reservations** (save 40-60%)
- **Use Basic SKU** for non-production environments
- **Delete non-production environments** when not needed

---

## 📁 Project Structure

```
azure-hub-spoke-networking-terraform/
├── README.md                      # This file
├── SECURITY-RULES.md             # Complete security reference
│
├── hub/                          # Hub infrastructure
│   ├── 01-foundation.tf          # Resource group
│   ├── 02-networking.tf          # VNet and subnets
│   ├── 03-firewall.tf            # Azure Firewall
│   ├── 04-app-gateway.tf         # Application Gateway
│   ├── 05-nsg.tf                 # Network Security Groups
│   ├── 06-route-table.tf         # Route tables
│   └── 99-outputs.tf             # Outputs
│
├── spoke-development/            # Development spoke
│   ├── 01-foundation.tf          # Resource group
│   ├── 02-networking.tf          # VNet and subnet
│   ├── 03-nsg.tf                 # NSG rules
│   ├── 04-route-table.tf         # Route table
│   ├── 05-peering.tf             # VNet peering to hub
│   ├── 06-vm.tf                  # Test VM
│   └── 99-outputs.tf             # Outputs
│
├── spoke-production/             # Production spoke
│   └── (same structure as dev)
│
├── vars/                         # Configuration files
│   ├── hub.auto.tfvars.hcl       # Hub configuration
│   ├── dev.auto.tfvars.hcl       # Dev spoke configuration
│   └── prod.auto.tfvars.hcl      # Prod spoke configuration
│
└── modules/                      # Reusable modules
    ├── naming/                   # Naming convention
    ├── vnet/                     # Virtual network
    ├── subnet/                   # Subnet
    ├── nsg/                      # Network security group
    ├── firewall/                 # Azure Firewall
    ├── app-gateway/              # Application Gateway
    ├── route-table/              # Route table
    └── vm/                       # Virtual machine
```

---

## 📚 IP Address Plan

### VNet Address Spaces

| VNet | CIDR | Purpose |
|------|------|---------|
| Hub | 10.0.0.0/16 | Central connectivity hub |
| Development | 10.1.0.0/16 | Development environment |
| Production | 10.2.0.0/16 | Production workloads |

### Hub Subnets (10.0.0.0/16)

| Subnet | CIDR | Purpose |
|--------|------|---------|
| AzureFirewallSubnet | 10.0.0.0/26 | Azure Firewall (required name) |
| App Gateway | 10.0.4.0/24 | Application Gateway |

### Spoke Subnets

| Environment | Subnet | CIDR | Purpose |
|-------------|--------|------|---------|
| Development | VM Subnet | 10.1.0.0/24 | Virtual machines |
| Production | VM Subnet | 10.2.0.0/24 | Virtual machines |

---

## 🔧 Common Operations

### View All Outputs

```bash
# All modules
terragrunt run-all output

# Specific module
cd hub
terragrunt output
```

### Update Security Rules

1. Edit `vars/hub.auto.tfvars.hcl` (firewall rules)
2. Edit `vars/dev.auto.tfvars.hcl` or `vars/prod.auto.tfvars.hcl` (NSG rules)
3. Apply changes:
```bash
cd hub  # or spoke-development / spoke-production
terragrunt apply
```

### Add New Spoke

1. Copy `spoke-development/` directory
2. Update `environment` variable
3. Update address space in `locals.tf`
4. Add to Terragrunt dependency chain
5. Run `terragrunt apply`

---

## 📖 References

### Microsoft Documentation

- [Hub-Spoke Network Topology](https://learn.microsoft.com/en-us/azure/architecture/reference-architectures/hybrid-networking/hub-spoke)
- [Azure Firewall](https://learn.microsoft.com/en-us/azure/firewall/)
- [Application Gateway](https://learn.microsoft.com/en-us/azure/application-gateway/)
- [Azure Naming Conventions](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-naming)

### Terraform Documentation

- [Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Terragrunt](https://terragrunt.gruntwork.io/)

### Security Reference

- **📋 [Complete Security Rules →](./SECURITY-RULES.md)** - All firewall rules, NSG rules, route tables

---

**Last Updated:** 2025-01-12
**Terraform Version:** >= 1.0
**Terragrunt Version:** >= 0.48
**Azure Provider:** ~> 3.0
**License:** MIT
