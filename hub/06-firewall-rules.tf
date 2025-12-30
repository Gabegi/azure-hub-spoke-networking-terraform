# hub/06-firewall-rules.tf
# Azure Firewall Policy Rules - Zero Trust Architecture
#
# Security Model:
# - Development: Full internet access (development environment)
# - Production: Restricted to essential services only
# - Cross-environment: API calls only (no direct database access)
# - Default: Deny all, allow explicitly

# ============================================================================
# Firewall Policy Rule Collection Group
# ============================================================================

resource "azurerm_firewall_policy_rule_collection_group" "hub_rules" {
  count = local.deploy_firewall ? 1 : 0

  name               = "DefaultRuleCollectionGroup"
  firewall_policy_id = module.firewall[0].firewall_policy_id
  priority           = 100

  # ============================================================================
  # Network Rule Collections (Layer 4 - IP + Port filtering)
  # ============================================================================

  # Collection 1: Infrastructure Services (MUST HAVE)
  network_rule_collection {
    name     = "AllowInfrastructure"
    priority = 100
    action   = "Allow"

    # DNS - Critical for all name resolution
    rule {
      name                  = "AllowDNS"
      protocols             = ["UDP"]
      source_addresses      = ["10.0.0.0/8"] # All internal networks
      destination_addresses = ["*"]
      destination_ports     = ["53"]
    }

    # NTP - Time synchronization (important for logs, certs, Kerberos)
    rule {
      name                  = "AllowNTP"
      protocols             = ["UDP"]
      source_addresses      = ["10.0.0.0/8"]
      destination_addresses = ["*"]
      destination_ports     = ["123"]
    }

    # Azure Monitor - Required for VM agents and diagnostics
    rule {
      name                  = "AllowAzureMonitor"
      protocols             = ["TCP"]
      source_addresses      = ["10.0.0.0/8"]
      destination_addresses = ["AzureMonitor"] # Service Tag
      destination_ports     = ["443"]
    }

    # Azure Backup - Recommended for DR
    rule {
      name                  = "AllowAzureBackup"
      protocols             = ["TCP"]
      source_addresses      = ["10.0.0.0/8"]
      destination_addresses = ["AzureBackup"] # Service Tag
      destination_ports     = ["443"]
    }
  }

  # Collection 2: Cross-Environment Communication (API Calls Only)
  network_rule_collection {
    name     = "AllowCrossEnvironment"
    priority = 200
    action   = "Allow"

    # Development → Production: HTTPS API calls ONLY (no direct database!)
    rule {
      name                  = "DevelopmentToProdAPIs"
      protocols             = ["TCP"]
      source_addresses      = ["10.1.0.0/16"] # Development spoke
      destination_addresses = ["10.2.0.0/16"] # Production spoke
      destination_ports     = ["443"]         # HTTPS only
    }

    # ❌ REMOVED: Development → Production SQL (no direct DB access!)
    # ❌ REMOVED: Production → Development (no reverse access!)
  }

  # Collection 3: Management Access (via Bastion)
  network_rule_collection {
    name     = "AllowManagement"
    priority = 300
    action   = "Allow"

    # Spokes → Hub Management Subnet (SSH, RDP via Bastion)
    rule {
      name                  = "SpokesToManagement"
      protocols             = ["TCP"]
      source_addresses      = ["10.1.0.0/16", "10.2.0.0/16"]
      destination_addresses = ["10.0.3.0/24"] # Management subnet
      destination_ports     = ["22", "3389"]
    }
  }

  # ============================================================================
  # Application Rule Collections (Layer 7 - FQDN filtering)
  # ============================================================================

  # Collection 1: Critical Services - ALL ENVIRONMENTS
  application_rule_collection {
    name     = "AllowCriticalServices"
    priority = 400
    action   = "Allow"

    # Windows Update - MUST HAVE for security patches
    rule {
      name             = "AllowWindowsUpdate"
      source_addresses = ["10.0.0.0/8"]

      protocols {
        type = "Https"
        port = 443
      }

      protocols {
        type = "Http"
        port = 80
      }

      destination_fqdns = [
        "*.windowsupdate.microsoft.com",
        "*.windowsupdate.com",
        "*.update.microsoft.com",
        "*.microsoft.com",
        "download.microsoft.com",
        "*.download.windowsupdate.com",
        "wustat.windows.com",
        "ntservicepack.microsoft.com",
        "*.ws.microsoft.com",
        "*.mp.microsoft.com",
        "*.dl.delivery.mp.microsoft.com"
      ]
    }

    # Microsoft Authentication - MUST HAVE for Azure AD
    rule {
      name             = "AllowMicrosoftAuth"
      source_addresses = ["10.0.0.0/8"]

      protocols {
        type = "Https"
        port = 443
      }

      destination_fqdns = [
        "login.microsoftonline.com",
        "login.windows.net",
        "login.live.com",
        "*.login.microsoftonline.com",
        "*.login.microsoft.com"
      ]
    }

    # Azure Monitor - Telemetry and diagnostics
    rule {
      name             = "AllowAzureMonitorFQDN"
      source_addresses = ["10.0.0.0/8"]

      protocols {
        type = "Https"
        port = 443
      }

      destination_fqdns = [
        "*.ods.opinsights.azure.com",
        "*.oms.opinsights.azure.com",
        "*.monitoring.azure.com",
        "*.applicationinsights.azure.com",
        "dc.services.visualstudio.com",
        "rt.services.visualstudio.com"
      ]
    }
  }

  # Collection 2: DEVELOPMENT ENVIRONMENT - Full Azure + Internet Access
  application_rule_collection {
    name     = "AllowDevelopmentEnvironment"
    priority = 500
    action   = "Allow"

    # Development → Full Azure Services
    rule {
      name             = "DevelopmentToAzureFull"
      source_addresses = ["10.1.0.0/16"] # Development only

      protocols {
        type = "Https"
        port = 443
      }

      destination_fqdns = [
        # Core Azure
        "*.azure.com",
        "*.azure.net",
        "*.azurewebsites.net",
        "management.azure.com",

        # Storage
        "*.blob.core.windows.net",
        "*.queue.core.windows.net",
        "*.table.core.windows.net",
        "*.file.core.windows.net",

        # Security & Identity
        "*.vault.azure.net",
        "*.azurecr.io",

        # Databases
        "*.database.windows.net",
        "*.documents.azure.com",
        "*.redis.cache.windows.net",

        # Messaging & Events
        "*.servicebus.windows.net",
        "*.eventgrid.azure.net",
        "*.eventhub.windows.net",

        # AI & Analytics
        "*.cognitiveservices.azure.com",
        "*.search.windows.net"
      ]
    }

    # Development → GitHub (for CI/CD)
    rule {
      name             = "DevelopmentToGitHub"
      source_addresses = ["10.1.0.0/16"]

      protocols {
        type = "Https"
        port = 443
      }

      destination_fqdns = [
        "github.com",
        "*.github.com",
        "*.githubusercontent.com",
        "api.github.com",
        "raw.githubusercontent.com",
        "codeload.github.com"
      ]
    }

    # Development → General Internet HTTPS (for development)
    rule {
      name             = "DevelopmentToInternetHTTPS"
      source_addresses = ["10.1.0.0/16"]

      protocols {
        type = "Https"
        port = 443
      }

      destination_fqdns = [
        # NPM / Package managers
        "registry.npmjs.org",
        "*.npmjs.org",
        "pypi.org",
        "*.pypi.org",
        "files.pythonhosted.org",
        "rubygems.org",
        "*.rubygems.org",

        # Docker
        "*.docker.com",
        "*.docker.io",
        "registry.hub.docker.com",

        # CDNs
        "*.cloudflare.com",
        "*.cloudfront.net",
        "*.akamaiedge.net",

        # Common APIs for testing
        "httpbin.org",
        "*.httpbin.org",
        "jsonplaceholder.typicode.com",
        "api.ipify.org"
      ]
    }
  }

  # Collection 3: PRODUCTION ENVIRONMENT - RESTRICTED (Essential Only)
  application_rule_collection {
    name     = "AllowProductionEnvironment"
    priority = 600
    action   = "Allow"

    # Production → Essential Azure Services ONLY
    rule {
      name             = "ProductionToAzureEssential"
      source_addresses = ["10.2.0.0/16"] # Production only

      protocols {
        type = "Https"
        port = 443
      }

      destination_fqdns = [
        # Core Azure management
        "management.azure.com",
        "*.azure.com",
        "*.azure.net",

        # Storage (essential)
        "*.blob.core.windows.net",
        "*.file.core.windows.net",

        # Key Vault (secrets management)
        "*.vault.azure.net",

        # SQL Database (managed service)
        "*.database.windows.net",

        # Container Registry (if using containers)
        "*.azurecr.io"
      ]
    }

    # Production → Limited External HTTPS (Whitelist approach)
    # Uncomment and add approved domains when needed:
    # rule {
    #   name             = "ProductionToApprovedDomains"
    #   source_addresses = ["10.2.0.0/16"]
    #
    #   protocols {
    #     type = "Https"
    #     port = 443
    #   }
    #
    #   destination_fqdns = [
    #     # Example: Payment gateways, partner APIs
    #     # "api.stripe.com",
    #     # "api.sendgrid.com"
    #   ]
    # }

    # ❌ REMOVED: GitHub access (production should NOT pull code directly)
    # ❌ REMOVED: General internet access (production locked down)
  }

  depends_on = [
    module.firewall
  ]
}
