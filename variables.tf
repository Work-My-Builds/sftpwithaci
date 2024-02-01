variable "sftp_deployment" {
  type = object({
    prefix                = string
    location              = string
    address_space         = list(string)
    container_subnet_name = string
    firewall_nat_source_ip = string
    stfp_credential = object({
      user     = string
      password = string
    })

    subnets = list(object({
      subnet_name      = string
      address_prefixes = list(string)
      delegation       = optional(any, {})
    }))
  })
}