# VM Module

This module creates a Linux Virtual Machine with network interface and optional public IP.

## Features

- Linux VM with SSH key authentication
- Optional public IP for direct access
- System-assigned managed identity support
- Configurable VM size and OS image
- Availability zone support
- Boot diagnostics enabled by default
- Consistent naming using the naming module

## Usage

```hcl
module "vm" {
  source = "../modules/vm"

  # Naming
  resource_type = "vm"
  workload      = "web"
  environment   = "dev"
  location      = "westeurope"
  instance      = "001"
  common_tags   = var.tags

  # Resource Configuration
  resource_group_name = azurerm_resource_group.example.name
  subnet_id           = azurerm_subnet.example.id

  # VM Configuration
  vm_size                = "Standard_B2s"
  admin_username         = "azureuser"
  admin_ssh_public_key   = file("~/.ssh/id_rsa.pub")
  availability_zones     = ["1"]

  # Network Configuration
  enable_public_ip = true

  # Optional: OS Image (defaults to Ubuntu 22.04 LTS)
  source_image_publisher = "Canonical"
  source_image_offer     = "0001-com-ubuntu-server-jammy"
  source_image_sku       = "22_04-lts-gen2"
  source_image_version   = "latest"
}
```

## VM Sizes

Common VM sizes:
- `Standard_B1s` - 1 vCPU, 1 GB RAM (cheapest)
- `Standard_B2s` - 2 vCPU, 4 GB RAM (good for testing)
- `Standard_D2s_v3` - 2 vCPU, 8 GB RAM (general purpose)
- `Standard_D4s_v3` - 4 vCPU, 16 GB RAM (production)

## OS Images

Default: Ubuntu 22.04 LTS

Other common images:
- **Ubuntu 20.04 LTS**:
  - Publisher: `Canonical`
  - Offer: `0001-com-ubuntu-server-focal`
  - SKU: `20_04-lts-gen2`

- **Debian 11**:
  - Publisher: `Debian`
  - Offer: `debian-11`
  - SKU: `11-gen2`

- **RHEL 8**:
  - Publisher: `RedHat`
  - Offer: `RHEL`
  - SKU: `8-lvm-gen2`

## Inputs

See `variables.tf` for all available inputs.

## Outputs

- `vm_id` - VM resource ID
- `vm_name` - VM name
- `vm_private_ip` - Private IP address
- `vm_public_ip` - Public IP address (if enabled)
- `network_interface_id` - Network interface ID
- `vm_identity_principal_id` - Managed identity principal ID (if enabled)

## Notes

- Password authentication is disabled (SSH key only)
- Boot diagnostics use managed storage account
- Public IP uses Standard SKU (required for availability zones)
- OS disk defaults to 30 GB Premium_LRS
