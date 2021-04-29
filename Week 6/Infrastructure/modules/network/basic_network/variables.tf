variable "location" {
  description = "Location"
  type = string
}

variable "rg_name" {
  description = "Resource group name"
  type = string
}

variable "name" {
  description = "Name"
  type = string
}

variable "subnet_cidr" {
  description = "Subnet CIDR"
  type = string
}

variable "vnet_name" {
  description = "Name of the VNet to associate with the new subnet"
  type = string
}

variable "nic_service_endpoints" {
  description = "List of service endpoints"
  type = list(string)
  default = []
}

variable "nic_enforce_private_link_endpoint_network_policies" {
  description = "Enable enforcment fot private link endpoint network policies"
  type = bool
  default = false
}
