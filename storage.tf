resource "random_id" "sa" {
  byte_length = 8
}

resource "azurerm_storage_account" "sa" {
  name                     = "${var.sftp_deployment.prefix}${lower(random_id.sa.hex)}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_share" "share" {
  name                 = "${var.sftp_deployment.prefix}share"
  storage_account_name = azurerm_storage_account.sa.name
  quota                = 50
}

resource "azurerm_private_endpoint" "sa_private_endpoint" {
  name                = "${azurerm_storage_account.sa.name}endpoint"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.subnets["privateendpoint"].id

  private_service_connection {
    name                           = "privateserviceconnection"
    private_connection_resource_id = azurerm_storage_account.sa.id
    subresource_names              = ["file"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "file-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.private_dns_zone.id]
  }
}