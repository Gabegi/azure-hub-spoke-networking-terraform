# Terragrunt Deployment Guide

## Prerequisites

1. **Install Terragrunt**:

   ```bash
   # Windows (using Chocolatey)
   choco install terragrunt

   # Or download from: https://github.com/gruntwork-io/terragrunt/releases
   ```

2. **Install Terraform** (>= 1.5.0):

   ```bash
   choco install terraform
   ```

3. **Azure CLI** (authenticated):

   ```bash
   az login
   az account set --subscription "YOUR-SUBSCRIPTION-ID"
   ```

4. **Create Azure Storage Account for Remote State** (one-time setup):

   ```bash
   # Create resource group for state
   az group create --name rg-terraform-state-dev-westeurope --location westeurope

   # Create storage account (must be globally unique)
   az storage account create \
     --name sttfstatedevwesteurope \
     --resource-group rg-terraform-state-dev-westeurope \
     --location westeurope \
     --sku Standard_LRS \
     --encryption-services blob

   # Create container
   az storage container create \
     --name tfstate \
     --account-name sttfstatedevwesteurope
   ```

## Repository Structure

```
azure-hub-spoke-networking-terraform/
├── terragrunt.hcl                    # Root config (common settings)
├── env.hcl                           # Environment selector (dev/prod)
│
├── hub/
│   ├── terragrunt.hcl               # Hub-specific config
│   └── *.tf                         # Hub Terraform code
│
├── spoke-development/
│   ├── terragrunt.hcl               # Dev spoke config (depends on hub)
│   └── *.tf                         # Spoke Terraform code
│
└── spoke-production/
    ├── terragrunt.hcl               # Prod spoke config (depends on hub)
    └── *.tf                         # Spoke Terraform code
```

## Configuration

### 1. Update Subscription ID

Edit the `subscription_id` in each `terragrunt.hcl` file:

- `hub/terragrunt.hcl`
- `spoke-development/terragrunt.hcl`
- `spoke-production/terragrunt.hcl`

Replace with your actual subscription ID (get it with `az account show --query id -o tsv`).

### 2. Update SSH Public Key

In spoke terragrunt.hcl files, update:

```hcl
vm_admin_ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC..."
```

Generate one with:

```bash
ssh-keygen -t rsa -b 4096 -C "azure-hub-spoke-admin"
cat ~/.ssh/id_rsa.pub
```

### 3. Set Environment

Edit `env.hcl` to set the environment:

```hcl
locals {
  environment = "dev"  # or "prod"
}
```

## Deployment Commands

### Deploy Everything (Recommended)

Deploy all components in the correct order with automatic dependency resolution:

```bash
# From repository root
terragrunt run-all plan    # Preview all changes
terragrunt run-all apply   # Deploy hub + both spokes
```

Terragrunt will:

1. Deploy `hub/` first
2. Wait for hub outputs
3. Deploy `spoke-development/` and `spoke-production/` in parallel
4. Automatically pass hub outputs to spokes

### Deploy Individual Components

#### Hub Only

```bash
cd hub
terragrunt plan
terragrunt apply
```

#### Development Spoke Only

```bash
cd spoke-development
terragrunt plan    # Will read hub outputs automatically
terragrunt apply
```

#### Production Spoke Only

```bash
cd spoke-production
terragrunt plan
terragrunt apply
```

### Validate Configuration

```bash
# Validate all modules
terragrunt run-all validate

# Validate specific module
cd hub
terragrunt validate
```

### View Outputs

```bash
# From any module directory
terragrunt output

# Specific output
terragrunt output hub_vnet_id
```

### Destroy Infrastructure

```bash
# Destroy everything (in reverse dependency order)
terragrunt run-all destroy

# Destroy specific component
cd spoke-development
terragrunt destroy
```

## How Terragrunt Works Here

### Automatic Dependency Management

The spokes have dependency blocks in their `terragrunt.hcl`:

```hcl
dependency "hub" {
  config_path = "../hub"
}

inputs = {
  hub_vnet_id = dependency.hub.outputs.hub_vnet_id
  # ... other hub outputs
}
```

This means:

- ✅ Hub is **always deployed before spokes**
- ✅ Spokes **automatically get hub outputs**
- ✅ No manual copying of values needed
- ✅ Terraform dependencies are enforced

### Remote State Management

Terragrunt automatically configures Azure Storage backend:

- State files: `tfstate/hub/terraform.tfstate`, `tfstate/spoke-development/terraform.tfstate`, etc.
- **State locking** enabled via Azure Storage
- Each component has **isolated state**

### Generated Files

Terragrunt auto-generates in each module:

- `backend.tf` - Remote state configuration
- `provider.tf` - Azure provider configuration

These are in `.gitignore` - never commit them.

## Common Workflows

### Deploy Development Environment

```bash
# Set environment to dev
# Edit env.hcl: environment = "dev"

# Deploy hub + dev spoke only
cd spoke-development
terragrunt run-all apply
```

### Deploy Production Environment

```bash
# Set environment to prod
# Edit env.hcl: environment = "prod"

# Deploy everything including production spoke
terragrunt run-all apply
```

### Update Single Resource

```bash
# Make changes to Terraform files
cd hub

# Preview changes
terragrunt plan

# Apply changes
terragrunt apply
```

### Troubleshooting

**Clear Terragrunt cache:**

```bash
find . -type d -name ".terragrunt-cache" -exec rm -rf {} +
```

**Force refresh state:**

```bash
terragrunt refresh
```

**View dependency graph:**

```bash
terragrunt graph-dependencies
```

## Comparison: Terragrunt vs Plain Terraform

| Task         | Plain Terraform                                               | Terragrunt                                 |
| ------------ | ------------------------------------------------------------- | ------------------------------------------ |
| Deploy hub   | `cd hub && terraform apply`                                   | `cd hub && terragrunt apply`               |
| Deploy spoke | `cd spoke && terraform apply -var="hub_vnet_id=..."` (manual) | `cd spoke && terragrunt apply` (automatic) |
| Deploy all   | Run each separately, manually pass outputs                    | `terragrunt run-all apply`                 |
| State files  | 3 separate states (manual management)                         | 3 separate states (automatic management)   |
| Dependencies | Manual ordering                                               | Automatic resolution                       |

## Benefits of This Setup

✅ **Isolated State Files**: Each component (hub, spoke-dev, spoke-prod) has its own state
✅ **Automatic Dependencies**: Terragrunt handles deployment order
✅ **No Manual Output Passing**: Hub outputs automatically flow to spokes
✅ **DRY Configuration**: Common settings in root `terragrunt.hcl`
✅ **Environment Switching**: Change `env.hcl` to switch between dev/prod
✅ **Parallel Deployment**: Both spokes deploy simultaneously after hub
✅ **Remote State**: Azure Storage backend configured automatically

## Next Steps

1. Update subscription IDs in all `terragrunt.hcl` files
2. Update SSH public keys in spoke `terragrunt.hcl` files
3. Create Azure Storage account for remote state
4. Run `terragrunt run-all plan` to preview
5. Run `terragrunt run-all apply` to deploy

For more Terragrunt documentation: https://terragrunt.gruntwork.io/
