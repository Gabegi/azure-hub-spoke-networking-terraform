# spoke-production/06-vm.tf
# Virtual Machine for Production Spoke

# ============================================================================
# VM
# ============================================================================

module "vm" {
  source = "../modules/vm"

  # Naming (module handles naming internally)
  resource_type = "vm"
  workload      = "app"
  environment   = var.environment
  location      = var.location
  instance      = "001"
  common_tags   = var.tags

  # Resource Configuration
  resource_group_name = module.rg_spoke.rg_name
  subnet_id           = module.vm_subnet.subnet_id

  # VM Configuration
  vm_size              = "Standard_B1s"
  admin_username       = "azureuser"
  admin_ssh_public_key = var.vm_admin_ssh_public_key
  availability_zones   = []  # Standard_B1s does not support availability zones

  # Network Configuration
  enable_public_ip = false  # Private IP only - no public IP

  # Identity - Enable system-assigned managed identity for Azure CLI access
  enable_system_assigned_identity = true

  depends_on = [
    module.vm_subnet,
    module.vm_nsg,
    module.vm_route_table
  ]
}
