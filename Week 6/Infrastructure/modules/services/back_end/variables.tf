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

variable "admin_username" {
  description = "Admin username for database"
  type = string
}

variable "admin_password" {
  description = "Admin password for vm database"
  type = string
}

variable "inbound_address_prefixes" {
  description = "List of inbound adress prefixes to allow access from"
  type = string
} 