resource "azurerm_public_ip" "pip" {
  name                = "${var.sftp_deployment.prefix}-PIP"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_firewall_policy" "fwPolicy" {
  name                = "${var.sftp_deployment.prefix}-fwPolicy"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}

resource "azurerm_firewall" "firewall" {
  name                = "${var.sftp_deployment.prefix}-firewall"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Premium"
  firewall_policy_id  = azurerm_firewall_policy.fwPolicy.id

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.subnets["AzureFirewallSubnet"].id
    public_ip_address_id = azurerm_public_ip.pip.id
  }
}

resource "azurerm_firewall_policy_rule_collection_group" "rule_collection_group" {
  name               = "testcollection"
  firewall_policy_id = azurerm_firewall_policy.fwPolicy.id
  priority           = 100

  nat_rule_collection {
    name     = "nat_rule_collection1"
    priority = 300
    action   = "Dnat"
    rule {
      name = "testrule"
      destination_address = azurerm_public_ip.pip.ip_address
      translated_port = 22
      translated_address = azurerm_container_group.container_group.ip_address

      source_addresses = [
        var.sftp_deployment.firewall_nat_source_ip,
      ]
      destination_ports = [
        "22",
      ]
      protocols = [
        "TCP",
      ]
    }
  }
}