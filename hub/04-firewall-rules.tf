# hub/06-firewall-rules.tf
# Azure Firewall Policy Rules
#
# Rules are defined in tfvars for easy environment-specific configuration

# ============================================================================
# Firewall Policy Rule Collection Group
# ============================================================================

resource "azurerm_firewall_policy_rule_collection_group" "hub_rules" {
  count = var.deploy_firewall ? 1 : 0

  name               = "NetworkRuleCollectionGroup"
  firewall_policy_id = module.firewall[0].firewall_policy_id
  priority           = 100

  # ============================================================================
  # Network Rule Collection - Configured via tfvars
  # ============================================================================

  network_rule_collection {
    name     = "AllowRules"
    priority = 100
    action   = "Allow"

    dynamic "rule" {
      for_each = var.firewall_network_rules
      content {
        name                  = rule.value.name
        protocols             = rule.value.protocols
        source_addresses      = rule.value.source_addresses
        destination_addresses = rule.value.destination_addresses
        destination_ports     = rule.value.destination_ports
      }
    }
  }

  lifecycle {
    prevent_destroy = false
  }

  depends_on = [
    module.firewall
  ]
}
