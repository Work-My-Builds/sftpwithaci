sftp_deployment = {
  prefix                = "sftptest"
  location              = "CentralUS"
  address_space         = ["10.200.0.0/16"]
  container_subnet_name = "containerinstance"
  firewall_nat_source_ip = "140.186.97.142"

  stfp_credential = {
    user     = "mfalowo"
    password = "School123$123$"
  }

  subnets = [
    {
      subnet_name      = "AzureFirewallSubnet"
      address_prefixes = ["10.200.1.0/24"]
    },
    {
      subnet_name      = "privateendpoint"
      address_prefixes = ["10.200.2.0/24"]
    },
    {
      subnet_name      = "compute"
      address_prefixes = ["10.200.3.0/24"]
    },
    {
      subnet_name      = "containerinstance"
      address_prefixes = ["10.200.4.0/28"]
      delegation = {
        "delegation" = {
          service_delegation = {
            name    = "Microsoft.ContainerInstance/containerGroups"
            actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
          }
        }
      }
    }
  ]
}