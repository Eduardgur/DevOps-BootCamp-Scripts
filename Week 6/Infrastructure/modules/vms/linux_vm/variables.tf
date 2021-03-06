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

<<<<<<< HEAD
// variable "nsg_name" {
//   description = "NSG name"
//   type = string
// }

variable "lb_nat_rule_id" {
  description = "Nat rule id to associate"
  type = list(string)
  default = [""]
}

variable "lb_nat_rule_count" {
  description = "Number of NAT rules to associate"
  type = number
  default = 0
}

=======
>>>>>>> parent of 23344ce (more fixes)
variable "nic_subnet_id" {
  description = "Subnet ID to associate nic to "
  type = string
}

variable "nic_nsg_id" {
  description = "Id of the NSG to associate nic to "
  type = string
}


variable "admin_username" {
  description = "Admin username for vm instances"
  type = string
}

variable "vm_host_ip" {
  description = "Host ip for provision defaults to private"
  type = string
  default = ""
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

// variable "provision_script_source" {
//   description = "Path to copy provision scrip from"
//   type = string
// }

// variable "provision_script_destination" {
//   description = "Path to copy provision scrip to"
//   type = string
// }

// variable "provision_script" {
//   description = "Script to run on provision"
//   type = list(string)
// }

variable "vm_count" {
  description = "Number of vms to create"
  type = number
  default = 1
}

<<<<<<< HEAD
// variable "provision_custom_data_script_absolute_path" {
//   description = "Absolute path to the custome data script "
//   type = string
//   // default = "E:/source/repos/DevOps/Week 6/Provisioning/dummy"
//   // filebase64()
// }

variable "public_ip_id" {
  description = "Public ip id to associate to"
=======
variable "provision_custom_data_script_path" {
  description = "Custome data to run on provision"
>>>>>>> parent of 23344ce (more fixes)
  type = string
  default = ""
}