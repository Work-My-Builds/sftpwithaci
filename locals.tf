locals {
  subnets = flatten(
    [for key, data in var.sftp_deployment.subnets :
      {
        name             = data.subnet_name
        address_prefixes = data.address_prefixes
        delegation       = data.delegation
      }
    ]
  )
}