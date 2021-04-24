## Main ##
#Location
variable "Location" {
  type = string
}

#Resource group Name
variable "RgName" {
  type = string
}

variable "VnetCidr" {
  type = string
}


## VM ##
# Admin username for vm instances
variable "AdminUserName" {
  type = string
}

# Vault details to retrive admin pass
variable "VaultName" {
    type = string
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