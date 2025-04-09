# Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.network_prefix}-vnet-${var.vnet_name}-${var.environment}"
  address_space       = var.vnet_address_space
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = local.common_tags
}

# Subnets
resource "azurerm_subnet" "subnets" {
  for_each             = var.subnets
  name                 = "${var.network_prefix}-subnet-${each.key}-${var.vnet_name}-${var.environment}"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [each.value.address_prefix]
}

# Network Security Group (one per subnet)
resource "azurerm_network_security_group" "nsg" {
  for_each            = var.subnets
  name                = "${var.network_prefix}-nsg-${each.key}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = local.common_tags
}

# Inbound NSG Rules (applied to each NSG)
resource "azurerm_network_security_rule" "inbound" {
  for_each = { for rule in flatten([
    for subnet_key, subnet in var.subnets : [
      for rule_key, rule in var.nsg_inbound_rules : {
        subnet_key = subnet_key
        rule_key   = rule_key
        rule       = rule
      }
    ]
  ]) : "${rule.subnet_key}-${rule.rule_key}" => rule }

  name                        = "${var.network_prefix}-inbound-${each.value.rule_key}-${each.value.subnet_key}-${var.environment}"
  priority                    = each.value.rule.priority
  direction                   = "Inbound"
  access                      = each.value.rule.access
  protocol                    = each.value.rule.protocol
  source_port_range           = each.value.rule.source_port_range
  destination_port_range      = each.value.rule.destination_port_range
  source_address_prefix       = each.value.rule.source_address_prefix
  destination_address_prefix  = each.value.rule.destination_address_prefix
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.nsg[each.value.subnet_key].name
}

# Outbound NSG Rules (applied to each NSG)
resource "azurerm_network_security_rule" "outbound" {
  for_each = { for rule in flatten([
    for subnet_key, subnet in var.subnets : [
      for rule_key, rule in var.nsg_outbound_rules : {
        subnet_key = subnet_key
        rule_key   = rule_key
        rule       = rule
      }
    ]
  ]) : "${rule.subnet_key}-${rule.rule_key}" => rule }

  name                        = "${var.network_prefix}-outbound-${each.value.rule_key}-${each.value.subnet_key}-${var.environment}"
  priority                    = each.value.rule.priority
  direction                   = "Outbound"
  access                      = each.value.rule.access
  protocol                    = each.value.rule.protocol
  source_port_range           = each.value.rule.source_port_range
  destination_port_range      = each.value.rule.destination_port_range
  source_address_prefix       = each.value.rule.source_address_prefix
  destination_address_prefix  = each.value.rule.destination_address_prefix
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.nsg[each.value.subnet_key].name
}

# Subnet-NSG Association (one per subnet, if attach_nsg is true)
resource "azurerm_subnet_network_security_group_association" "nsg_association" {
  for_each                  = { for k, v in var.subnets : k => v if lookup(v, "attach_nsg", true) }
  subnet_id                 = azurerm_subnet.subnets[each.key].id
  network_security_group_id = azurerm_network_security_group.nsg[each.key].id
}
