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

# Admin password for vm instances
variable "AdminPassword" {
  type = string
}

# VM size (sku)
variable "VmSize" {
  type = string
}