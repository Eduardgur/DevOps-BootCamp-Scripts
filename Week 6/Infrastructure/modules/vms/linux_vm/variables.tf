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

variable "count" {
  description = "Numbet of instances to create"
  type = string
}

variable "nic_subnet_id" {
  description = "Subnet ID to associate nic to "
  type = string
}

variable "nic_nsg_id" {
  description = "Id of the NSG to associate nic to "
  type = string
}


variable "vm_admin_username" {
  description = "Admin username for vm instances"
  type = string
}

variable "vm_size" {
  description = "VM SKU (size)"
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
  default = [
      "sudo chmod +x /home/${var.admin_username}/provision.sh",
      "sudo bash /home/${var.admin_username}/provision.sh '${azurerm_network_interface.nic[count.index].private_ip_address}' '8080' '${azurerm_public_ip.AppPublicIp.ip_address}' '${azurerm_private_endpoint.DbServerPrivateEndpoint.private_service_connection.0.private_ip_address}' 'https://dev-91725987.okta.com' '0oac29sg1MnlaSgsu5d6' 'tyM1Gtw1rGwXVscTZ1uTBjPj6ZzvazWVTehyuCex' '5432' '${var.admin_username}@${azurerm_postgresql_server.DbServer.name}' '${azurerm_postgresql_database.DB.name}' '${data.azurerm_key_vault_secret.VMPass.value}' > '/home/${var.admin_username}/provision.log'" ,
    ]
}

variable "count" {
  description = "Number of vms to create"
  type = number
  default = 1
}

variable "provision_custom_data_script_path" {
  description = "Custome data to run on provision"
  type = string
  default = ""
}