variable "location" {
  description = "Location"
  type = string
}

variable "rg_name" {
  description = "Resource group Name"
  type = string
}

variable "name" {
  description = "Name"
  type = string
}

variable "create_public_ip" {
  description = "If set to true, create public ip"
  type        = bool
}

variable "lb_nat_rule_count" {
  description = "Number of nat rules to create"
  type = number
}

// #Number of nat rules to create
// variable "nic_id" {
//   type = number
// }


