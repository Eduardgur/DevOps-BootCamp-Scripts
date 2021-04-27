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

variable "frontend_subnet_cidr" {
  type = string
}

variable "backend_subnet_cidr" {
  type = string
}

variable "jenkins_subnet_cidr" {
  type = string
}

variable "vault_name" {
    type = vault_name
    description = "Vault name that contains the admin password"
}

variable "VaultResourceGroupName" {
    type = string
    description = "Name of the resource group containing the vault"
}

variable "VaultUri" {
    type = string
    description = "Vault uri that contains the admin password"
}

# VM size (sku)
variable "VmSize" {
  type = string
}