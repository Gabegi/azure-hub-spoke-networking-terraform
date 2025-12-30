# hub/06-firewall-rules.tf
# Azure Firewall Policy Rules - MINIMAL TEST RULES
#
# Purpose: Test hub-spoke architecture with ACI containers
# Rules: Just allow spoke-to-spoke communication for testing

# ============================================================================
# Firewall Policy Rule Collection Group
# ============================================================================

resource "azurerm_firewall_policy_rule_collection_group" "hub_rules" {
  count = local.deploy_firewall ? 1 : 0

  name               = "TestRuleCollectionGroup"
  firewall_policy_id = module.firewall[0].firewall_policy_id
  priority           = 100

  # ============================================================================
  # Network Rule Collection - Spoke-to-Spoke Testing
  # ============================================================================

  network_rule_collection {
    name     = "AllowSpokeToSpokeTest"
    priority = 100
    action   = "Allow"

    # ICMP - Ping testing between spokes
    rule {
      name                  = "AllowICMP"
      protocols             = ["ICMP"]
      source_addresses      = ["10.1.0.0/16", "10.2.0.0/16"]
      destination_addresses = ["10.1.0.0/16", "10.2.0.0/16"]
      destination_ports     = ["*"]
    }

    # HTTP/HTTPS - Web traffic testing between spokes
    rule {
      name                  = "AllowHTTP"
      protocols             = ["TCP"]
      source_addresses      = ["10.1.0.0/16", "10.2.0.0/16"]
      destination_addresses = ["10.1.0.0/16", "10.2.0.0/16"]
      destination_ports     = ["80", "443", "8080"]
    }

    # DNS - For name resolution (if needed)
    rule {
      name                  = "AllowDNS"
      protocols             = ["UDP"]
      source_addresses      = ["10.1.0.0/16", "10.2.0.0/16"]
      destination_addresses = ["*"]
      destination_ports     = ["53"]
    }
  }

  depends_on = [
    module.firewall
  ]
}
