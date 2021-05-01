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

variable "vm_count" {
  description = "Number of vms to create in the frontend"
  type = number
  default = 1
}

variable "vm_size" {
  description = "VM SKU (size)"
  type = string
} 

variable "vm_admin_username" {
  description = "Admin username for vm instances"
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

variable "provision_script" {
  description = "Script to run on provision"
  type = list(string)
}

variable "provision_custom_data_script_absolute_path" {
  description = "Absolute path to the custome data script "
  type = string
}

