## Main ##
#Global name
variable "name" {
  type = string
}

#location
variable "location" {
  type = string
}

variable "vnet_cidr" {
  type = string
}

variable "vault_name" {
    type = string
    description = "Vault name that contains the admin password"
}

variable "vault_rg_name" {
    type = string
    description = "Name of the resource group containing the vault"
}

variable "frontend_subnet_cidr" {
  type = string
}

variable "backend_subnet_cidr" {
  type = string
}

variable "jenkins_subnet_cidr" {
  type = string
}

# VM size (sku)
variable "vm_size" {
  type = string
}

variable "public_ssh_key" {
  type = string
}

variable "private_ssh_key" {
  type = string
}

variable "frontend_provision_sript" {
  type = list(string)
}

variable "frontend_provision_sript_source" {
  type = string
}

variable "frontend_provision_sript_destination" {
  type = string
}

variable "jenkins_provision_sript" {
  type = list(string)
}

variable "jenkins_provision_sript_source" {
  type = string
}

variable "jenkins_provision_sript_destination" {
  type = string
}

variable "provision_custom_data_script_absolute_path" {
  type = string
}
