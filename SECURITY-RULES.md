# Security Rules Reference

Complete reference for all security rules, route tables, and network policies that make the hub-spoke architecture work.

---

## 🎯 The Three Pillars

The hub-spoke architecture enforces **centralized traffic inspection and control** through three critical components:

1. **Route Tables** - Force all spoke traffic through the hub firewall (10.0.0.4)
2. **Firewall Network Rules** - Control what traffic is allowed between spokes and to the internet
3. **NSG (Network Security Groups)** - Provide subnet-level security as the first line of defense

**Without ANY ONE of these components, spoke-to-spoke communication would fail or bypass security controls.**

### Traffic Flow Example

```
Dev VM (10.1.0.5) → Dev NSG (allow) → Route Table (send to 10.0.0.4) →
Hub Firewall (10.0.0.4) (inspect & allow) → Route Table (to prod) →
Prod NSG (allow) → Prod VM (10.2.0.5)
```

---

## 🔥 Hub Firewall Network Rules (10.0.0.4)

**Purpose:** Centralized policy enforcement for all spoke-to-spoke and spoke-to-internet traffic.

| Rule Name | Protocol | Source | Destination | Ports | Purpose |
|-----------|----------|--------|-------------|-------|---------|
| **AllowDevToProdSSH** | TCP | 10.1.0.0/24 | 10.2.0.0/24 | 22 | Enable SSH connectivity from Dev VMs to Prod VMs |
| **AllowProdToDevSSH** | TCP | 10.2.0.0/24 | 10.1.0.0/24 | 22 | Enable SSH connectivity from Prod VMs to Dev VMs |
| **AllowDevToProdICMP** | ICMP | 10.1.0.0/24 | 10.2.0.0/24 | * | Enable ping/network diagnostics from Dev to Prod |
| **AllowProdToDevICMP** | ICMP | 10.2.0.0/24 | 10.1.0.0/24 | * | Enable ping/network diagnostics from Prod to Dev |
| **AllowDevVMInternet** | TCP | 10.1.0.0/24 | * | 80, 443 | Allow Dev VMs to download packages and updates from Internet |
| **AllowProdVMInternet** | TCP | 10.2.0.0/24 | * | 80, 443 | Allow Prod VMs to download packages and updates from Internet |
| **AllowDNS** | UDP | 10.1.0.0/24<br>10.2.0.0/24 | * | 53 | Enable DNS resolution for both Dev and Prod VMs |

**Default Action:** Deny all traffic not explicitly allowed ⛔

**Configuration File:** `vars/hub.auto.tfvars.hcl` (lines 125-179)

---

## 🛡️ Development Spoke NSG Rules (10.1.0.0/24)

**Purpose:** First line of defense before traffic reaches the route table. Defense in depth.

### Complete Rule Set

| Priority | Direction | Rule Name | Protocol | Source | Source Port | Destination | Dest Port | Access | Purpose |
|----------|-----------|-----------|----------|--------|-------------|-------------|-----------|--------|---------|
| **100** | Inbound | AllowProdVMSSHInbound | TCP | 10.2.0.0/24 | * | 10.1.0.0/24 | 22 | Allow | Accept SSH connections from Prod VMs |
| **110** | Inbound | AllowProdVMICMPInbound | ICMP | 10.2.0.0/24 | * | 10.1.0.0/24 | * | Allow | Accept ping from Prod VMs for network diagnostics |
| **4095** | Inbound | AllowAzureLoadBalancer | * | AzureLoadBalancer | * | * | * | Allow | Allow Azure health probes (required for platform) |
| **4096** | Inbound | DenyAllInbound | * | * | * | * | * | Deny | Explicitly deny all other inbound traffic (Zero Trust) |
| **100** | Outbound | AllowToProdVMSSH | TCP | 10.1.0.0/24 | * | 10.2.0.0/24 | 22 | Allow | Initiate SSH connections to Prod VMs |
| **110** | Outbound | AllowToProdVMICMP | ICMP | 10.1.0.0/24 | * | 10.2.0.0/24 | * | Allow | Initiate ping to Prod VMs for network diagnostics |
| **200** | Outbound | AllowInternetHTTPS | TCP | 10.1.0.0/24 | * | Internet | 443 | Allow | Download packages via HTTPS (apt update, curl, wget) |
| **210** | Outbound | AllowInternetHTTP | TCP | 10.1.0.0/24 | * | Internet | 80 | Allow | Download packages via HTTP (apt repositories) |
| **300** | Outbound | AllowDNS | UDP | 10.1.0.0/24 | * | Internet | 53 | Allow | Resolve domain names via DNS |
| **4096** | Outbound | DenyAllOutbound | * | * | * | * | * | Deny | Explicitly deny all other outbound traffic (Zero Trust) |

**Total Rules:** 10 (4 Inbound + 6 Outbound)
**Allow Rules:** 8
**Deny Rules:** 2

**Configuration File:** `vars/dev.auto.tfvars.hcl` (lines 61-185)

---

## 🛡️ Production Spoke NSG Rules (10.2.0.0/24)

**Purpose:** First line of defense before traffic reaches the route table. Defense in depth.

### Complete Rule Set

| Priority | Direction | Rule Name | Protocol | Source | Source Port | Destination | Dest Port | Access | Purpose |
|----------|-----------|-----------|----------|--------|-------------|-------------|-----------|--------|---------|
| **100** | Inbound | AllowDevVMSSHInbound | TCP | 10.1.0.0/24 | * | 10.2.0.0/24 | 22 | Allow | Accept SSH connections from Dev VMs |
| **110** | Inbound | AllowDevVMICMPInbound | ICMP | 10.1.0.0/24 | * | 10.2.0.0/24 | * | Allow | Accept ping from Dev VMs for network diagnostics |
| **4095** | Inbound | AllowAzureLoadBalancer | * | AzureLoadBalancer | * | * | * | Allow | Allow Azure health probes (required for platform) |
| **4096** | Inbound | DenyAllInbound | * | * | * | * | * | Deny | Explicitly deny all other inbound traffic (Zero Trust) |
| **100** | Outbound | AllowToDevVMSSH | TCP | 10.2.0.0/24 | * | 10.1.0.0/24 | 22 | Allow | Initiate SSH connections to Dev VMs |
| **110** | Outbound | AllowToDevVMICMP | ICMP | 10.2.0.0/24 | * | 10.1.0.0/24 | * | Allow | Initiate ping to Dev VMs for network diagnostics |
| **200** | Outbound | AllowInternetHTTPS | TCP | 10.2.0.0/24 | * | Internet | 443 | Allow | Download packages via HTTPS (apt update, curl, wget) |
| **210** | Outbound | AllowInternetHTTP | TCP | 10.2.0.0/24 | * | Internet | 80 | Allow | Download packages via HTTP (apt repositories) |
| **300** | Outbound | AllowDNS | UDP | 10.2.0.0/24 | * | Internet | 53 | Allow | Resolve domain names via DNS |
| **4096** | Outbound | DenyAllOutbound | * | * | * | * | * | Deny | Explicitly deny all other outbound traffic (Zero Trust) |

**Total Rules:** 10 (4 Inbound + 6 Outbound)
**Allow Rules:** 8
**Deny Rules:** 2

**Configuration File:** `vars/prod.auto.tfvars.hcl` (lines 61-185)

---

## 🗺️ Route Tables

**Purpose:** Override Azure's default routing to force traffic through the hub firewall for inspection.

### Development Spoke Route Table (10.1.0.0/16)

| Route Name | Destination CIDR | Next Hop Type | Next Hop IP | Purpose |
|------------|------------------|---------------|-------------|---------|
| **InternetViaFirewall** | 0.0.0.0/0 | VirtualAppliance | 10.0.0.4 | Force all Internet-bound traffic through hub firewall (forced tunneling) |
| **ProductionSpokeViaFirewall** | 10.2.0.0/16 | VirtualAppliance | 10.0.0.4 | Route all traffic to Prod spoke through hub firewall for inspection |

**BGP Route Propagation:** Disabled - Prevents on-premises routes from bypassing firewall

**Configuration File:** `vars/dev.auto.tfvars.hcl` (lines 42-55)

### Production Spoke Route Table (10.2.0.0/16)

| Route Name | Destination CIDR | Next Hop Type | Next Hop IP | Purpose |
|------------|------------------|---------------|-------------|---------|
| **InternetViaFirewall** | 0.0.0.0/0 | VirtualAppliance | 10.0.0.4 | Force all Internet-bound traffic through hub firewall (forced tunneling) |
| **DevelopmentSpokeViaFirewall** | 10.1.0.0/16 | VirtualAppliance | 10.0.0.4 | Route all traffic to Dev spoke through hub firewall for inspection |

**BGP Route Propagation:** Disabled - Prevents on-premises routes from bypassing firewall

**Configuration File:** `vars/prod.auto.tfvars.hcl` (lines 42-55)

### Hub Application Gateway Route Table (10.0.4.0/24)

| Route Name | Destination CIDR | Next Hop Type | Next Hop IP | Purpose |
|------------|------------------|---------------|-------------|---------|
| **DevelopmentSpokeViaFirewall** | 10.1.0.0/16 | VirtualAppliance | 10.0.0.4 | Route traffic from App Gateway to Dev spoke VMs through firewall |
| **ProductionSpokeViaFirewall** | 10.2.0.0/16 | VirtualAppliance | 10.0.0.4 | Route traffic from App Gateway to Prod spoke VMs through firewall |

**BGP Route Propagation:** Disabled - Prevents route conflicts

**Configuration File:** `vars/hub.auto.tfvars.hcl` (lines 186-199)

---

## 🔗 VNet Peering Configuration

**Purpose:** Establish connectivity between hub and spokes while preventing direct spoke-to-spoke communication.

| Peering | From | To | allow_virtual_network_access | allow_forwarded_traffic | use_remote_gateways |
|---------|------|-----|------------------------------|-------------------------|---------------------|
| **spoke-to-hub** | Dev/Prod | Hub | ✅ true | ✅ true | ❌ false |
| **hub-to-spoke** | Hub | Dev/Prod | ✅ true | ✅ true | ❌ false |

**Key Points:**
- `allow_forwarded_traffic = true` - **Critical** for hub firewall to forward spoke-to-spoke traffic
- No direct spoke-to-spoke peering exists - forces traffic through hub
- Gateway transit disabled (we're using firewall, not VPN/ExpressRoute gateway)

**Configuration Files:**
- Dev Spoke: `spoke-development/05-peering.tf`
- Prod Spoke: `spoke-production/05-peering.tf`

---

## 🚦 What Would Break Without Each Component?

| Missing Component | Result | Why |
|------------------|--------|-----|
| **Route Tables** | Spokes communicate directly via VNet peering | Azure's default routing bypasses the firewall |
| **Firewall Rules** | All spoke-to-spoke traffic blocked | Firewall defaults to deny-all |
| **NSG Rules** | Traffic might bypass subnet restrictions | Defense-in-depth broken, single point of failure |
| **VNet Peering** | Complete network isolation | No connectivity between hub and spokes |
| **allow_forwarded_traffic** | Firewall can't forward spoke-to-spoke traffic | Peering doesn't allow transit |

**All components must work together** - this is defense-in-depth and Zero Trust in action.

---

## 📊 Summary Statistics

| Component | Total Rules | Allow Rules | Deny Rules | Purpose |
|-----------|-------------|-------------|------------|---------|
| **Hub Firewall** | 7 | 7 | 0 | Centralized traffic inspection and control |
| **Dev NSG** | 10 | 8 | 2 | Subnet-level security for Dev VMs |
| **Prod NSG** | 10 | 8 | 2 | Subnet-level security for Prod VMs |
| **Dev Routes** | 2 | N/A | N/A | Force all traffic through firewall |
| **Prod Routes** | 2 | N/A | N/A | Force all traffic through firewall |
| **Hub App GW Routes** | 2 | N/A | N/A | Route App Gateway traffic through firewall |

---

## 🔒 Security Architecture Principles

1. **Defense in Depth**: NSG (Layer 1) → Firewall (Layer 2) → Route Tables (Layer 3)
2. **Zero Trust Model**: Explicit deny-all rules + allow-list specific traffic only
3. **Forced Tunneling**: All spoke traffic routed through hub firewall (10.0.0.4)
4. **Centralized Control**: Single firewall manages all inter-spoke and Internet traffic
5. **Least Privilege**: Only necessary ports/protocols allowed (SSH 22, HTTP 80, HTTPS 443, DNS 53, ICMP)

---

## 🧪 Traffic Flow Examples

### Example 1: Dev VM → Prod VM (SSH)

```
1. Dev VM (10.1.0.5) initiates SSH to Prod VM (10.2.0.5)
2. Dev NSG checks outbound rule "AllowToProdVMSSH" (Priority 100) → ✅ ALLOW
3. Route table matches destination 10.2.0.0/16 → Redirect to 10.0.0.4 (firewall)
4. Firewall inspects traffic, matches rule "AllowDevToProdSSH" → ✅ ALLOW
5. Traffic forwarded to Prod spoke
6. Prod NSG checks inbound rule "AllowDevVMSSHInbound" (Priority 100) → ✅ ALLOW
7. SSH connection established ✅
```

### Example 2: Prod VM → Dev VM (SSH)

```
1. Prod VM (10.2.0.5) initiates SSH to Dev VM (10.1.0.5)
2. Prod NSG checks outbound rule "AllowToDevVMSSH" (Priority 100) → ✅ ALLOW
3. Route table matches destination 10.1.0.0/16 → Redirect to 10.0.0.4 (firewall)
4. Firewall inspects traffic, matches rule "AllowProdToDevSSH" → ✅ ALLOW
5. Traffic forwarded to Dev spoke
6. Dev NSG checks inbound rule "AllowProdVMSSHInbound" (Priority 100) → ✅ ALLOW
7. SSH connection established ✅
```

### Example 3: Dev VM → Internet (HTTPS)

```
1. Dev VM (10.1.0.5) initiates HTTPS to google.com
2. Dev NSG checks outbound rule "AllowInternetHTTPS" (Priority 200) → ✅ ALLOW
3. Route table matches destination 0.0.0.0/0 → Redirect to 10.0.0.4 (firewall)
4. Firewall inspects traffic, matches rule "AllowDevVMInternet" → ✅ ALLOW
5. Traffic forwarded to Internet
6. Connection established ✅
```

### Example 4: Direct Spoke-to-Spoke Without Firewall (What Would Happen)

```
1. Dev VM tries to reach Prod VM directly
2. Dev NSG checks outbound rule → ✅ ALLOW
3. WITHOUT ROUTE TABLE: Azure default routing would route directly via VNet peering
   ❌ PROBLEM: Bypasses firewall completely, no centralized control
4. WITH ROUTE TABLE: Traffic redirected to firewall → Centralized inspection ✅
```

---

## 📝 Modification Guide

### Adding a New Firewall Rule

1. Edit `vars/hub.auto.tfvars.hcl`
2. Add rule to `firewall_network_rules` array:
```hcl
{
  name                  = "AllowMyNewRule"
  protocols             = ["TCP"]
  source_addresses      = ["10.1.0.0/24"]
  destination_addresses = ["10.2.0.0/24"]
  destination_ports     = ["8080"]
}
```
3. Run `terragrunt apply` from hub directory

### Adding a New NSG Rule

1. Edit `vars/dev.auto.tfvars.hcl` or `vars/prod.auto.tfvars.hcl`
2. Add rule to `vm_nsg_rules` array:
```hcl
{
  name                       = "AllowMyNewRule"
  priority                   = 150
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "8080"
  source_address_prefix      = "10.2.0.0/24"
  destination_address_prefix = "10.1.0.0/24"
  description                = "Allow traffic on port 8080"
}
```
3. Run `terragrunt apply` from spoke directory

### Adding a New Route

1. Edit `vars/dev.auto.tfvars.hcl` or `vars/prod.auto.tfvars.hcl`
2. Add route to `vm_route_table_routes` array:
```hcl
{
  name                   = "MyNewRoute"
  address_prefix         = "10.3.0.0/16"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = "10.0.0.4"
}
```
3. Run `terragrunt apply` from spoke directory

---

**Last Updated:** 2025-01-12
**For README:** [README.md](./README.md)
