# Environment-Specific Configuration

This folder contains environment-specific Terraform variable files (tfvars) for different deployment environments.

## Available Environments

| Environment | File | Description |
|-------------|------|-------------|
| **Production** | `prod.tfvars.example` | Production environment with Standard Bastion, 3 zones, full features |
| **Staging** | `staging.tfvars.example` | Staging environment with Basic Bastion, cost-optimized |
| **Development** | `dev.tfvars.example` | Development environment with minimal resources for testing |
| **Generic** | `terraform.tfvars.example` | Generic template for custom configurations |

## Quick Start

### 1. Copy the appropriate example file

```bash
# For production
cp environments/prod.tfvars.example environments/prod.tfvars

# For development
cp environments/dev.tfvars.example environments/dev.tfvars

# For staging
cp environments/staging.tfvars.example environments/staging.tfvars
```

### 2. Customize your values

Edit the copied `.tfvars` file with your specific configuration:
- Azure subscription details
- Region/location
- CIDR blocks (if different from defaults)
- Resource tags
- Feature flags

### 3. Deploy with the environment file

```bash
# Initialize Terraform (first time only)
terraform init

# Plan deployment
terraform plan -var-file="environments/prod.tfvars"

# Apply deployment
terraform apply -var-file="environments/prod.tfvars"
```

## Key Differences Between Environments

### Production (`prod.tfvars`)
- **Bastion**: Standard SKU with all features (file copy, tunneling, IP connect)
- **Availability**: 3 zones for maximum redundancy
- **Firewall**: Standard tier with threat intelligence
- **Monitoring**: 90-day log retention, geo-redundant storage
- **Cost**: ~€1,060/month (with firewall + bastion)
- **Resource Locks**: Enabled to prevent accidental deletion

### Staging (`staging.tfvars`)
- **Bastion**: Basic SKU (cost-optimized)
- **Availability**: 2 zones
- **Firewall**: Standard tier (matches production for testing)
- **Monitoring**: 30-day log retention, locally redundant storage
- **Cost**: ~€300/month
- **Resource Locks**: Disabled for easier updates

### Development (`dev.tfvars`)
- **Bastion**: Basic SKU
- **Availability**: 1 zone
- **Firewall**: Optional (can be disabled to save ~€800/month)
- **Monitoring**: Minimal (flow logs disabled)
- **Cost**: ~€110/month (bastion only, no firewall)
- **Resource Locks**: Disabled

## Security Best Practices

⚠️ **IMPORTANT**: Never commit actual `.tfvars` files to version control!

- ✅ **DO** commit `.tfvars.example` files (they're templates)
- ❌ **DON'T** commit `.tfvars` files (they contain sensitive data)
- ✅ **DO** use different Azure subscriptions for prod/dev/staging
- ✅ **DO** use Azure Key Vault for secrets
- ✅ **DO** use remote state (Azure Storage) for team collaboration

## File Structure

```
environments/
├── README.md                    # This file
├── prod.tfvars.example          # Production template
├── dev.tfvars.example           # Development template
├── staging.tfvars.example       # Staging template
└── terraform.tfvars.example     # Generic template
```

When you copy the examples, you'll have:
```
environments/
├── prod.tfvars         # ← Gitignored (your actual config)
├── dev.tfvars          # ← Gitignored (your actual config)
└── staging.tfvars      # ← Gitignored (your actual config)
```

## Multiple Workspaces (Alternative Approach)

Instead of `-var-file`, you can also use Terraform workspaces:

```bash
# Create workspaces
terraform workspace new prod
terraform workspace new dev
terraform workspace new staging

# Switch and deploy
terraform workspace select prod
terraform apply -var-file="environments/prod.tfvars"
```

## Troubleshooting

### Issue: "File not found" error
Make sure you're running terraform from the project root, not from the `environments/` folder:
```bash
# ✅ Correct (from project root)
terraform apply -var-file="environments/prod.tfvars"

# ❌ Wrong (from environments folder)
cd environments && terraform apply -var-file="prod.tfvars"
```

### Issue: Variables not being applied
Check that you specified the `-var-file` flag:
```bash
terraform apply -var-file="environments/prod.tfvars"
```

### Issue: Want to override a single variable
You can combine var-file with individual var flags:
```bash
terraform apply \
  -var-file="environments/prod.tfvars" \
  -var="location=northeurope"
```
