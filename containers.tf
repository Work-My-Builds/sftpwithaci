resource "azurerm_container_registry" "container_registry" {
  name                = "${var.sftp_deployment.prefix}rg"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Premium"
  admin_enabled       = false
}

resource "terraform_data" "acr_import" {
  triggers_replace = [
    azurerm_container_registry.container_registry.admin_password
  ]

  provisioner "local-exec" {
    command = <<-EOT
      az acr import --name ${azurerm_container_registry.container_registry.name} --source docker.io/atmoz/sftp:latest --image sftp:latest
    EOT
  }
}

resource "azurerm_user_assigned_identity" "user_assigned_identity" {
  name                = "${var.sftp_deployment.prefix}msi"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_role_assignment" "role_assignment_container" {
  scope                = azurerm_container_registry.container_registry.id
  role_definition_name = "acrpull"
  principal_id         = azurerm_user_assigned_identity.user_assigned_identity.principal_id
}

resource "azurerm_container_group" "container_group" {
  name                = "${var.sftp_deployment.prefix}cg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  ip_address_type     = "Private"
  os_type             = "Linux"
  restart_policy      = "OnFailure"
  subnet_ids          = [azurerm_subnet.subnets[var.sftp_deployment.container_subnet_name].id]

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.user_assigned_identity.id]
  }

  image_registry_credential {
    user_assigned_identity_id = azurerm_user_assigned_identity.user_assigned_identity.id
    server                    = azurerm_container_registry.container_registry.login_server
  }

  container {
    name   = "stfp"
    image  = "${azurerm_container_registry.container_registry.login_server}/sftp:latest"
    cpu    = "2"
    memory = "1"

    ports {
      port     = 22
      protocol = "TCP"
    }

    environment_variables = {
      SFTP_USERS = "${var.sftp_deployment.stfp_credential.user}:${var.sftp_deployment.stfp_credential.password}:1001"
    }

    volume {
      name                 = "sftpvolume"
      mount_path           = "/home/${var.sftp_deployment.stfp_credential.user}/upload"
      storage_account_name = azurerm_storage_account.sa.name
      storage_account_key  = azurerm_storage_account.sa.primary_access_key
      share_name           = azurerm_storage_share.share.name
    }
  }

  exposed_port = [{
    port     = 22
    protocol = "TCP"
  }]

  depends_on = [ 
    azurerm_role_assignment.role_assignment_container
   ]
}