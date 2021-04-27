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

variable "server_admin_username" {
  description = "Admin username for the server"
  type = string
}

variable "server_admin_password" {
  description = "Admin password for the server"
  type = string
}

variable "server_subnet_id" {
  description = "Subnet ID to associate server nic with"
  type = string
}







variable "vm_public_ssh_key" {
  description = "Path to the public ssh cert file"
  type = string
}

variable "vm_private_ssh_key" {
  description = "Path to the private ssh cert file"
  type = string
}

variable "provision_script_source" {
  description = "Path to copy provision scrip from"
  type = string
}

variable "provision_script_destination" {
  description = "Path to copy provision scrip to"
  type = string
}

