####################################################################
# Mandatory variables
####################################################################

# Global 
variable "resource_group_name" {
    type = string
    description = "Resource Group name"
}

variable "resource_group_location" {
    type = string
    description = "Resource Group location"
}

variable "vmss_admin_username" {
    type = string
    description = "VM Scaleset admin username"
}

variable "vault_name" {
    type = string
    description = "Vault name that contains the admin password"
}

variable "vault_group_name" {
    type = string
    description = "Name of the resource group containing the vault"
}

variable "vault_uri" {
    type = string
    description = "Vault uri that contains the admin password"
}


# Windows VMSS
variable "windows_vmss_healthprobe_id" {
    type = string
    description = "Windows VM Scaleset loadbalancer health probe"
}

variable "windows_vmss_instances_count" {
    type = number
    description = "Number of Widnows VM Scaleset instances to create"
}

variable "windows_vmss_subnet_id" {
    type = string
    description = "Frontend subnet id"
}

variable "windows_vmss_lb_backend_pool_ids" {
    type = list(string)
    description = "Frontend loadbalancer backend address pool ids"
}

variable "windows_vmss_size" {
    type = string
    description = "Windows VM Scaleset size"
}


# Linux VMSS
variable "linux_vmss_healthprobe_id" {
    type = string
    description = "Linux VM Scaleset loadbalancer health probe"
}

variable "linux_vmss_instances_count" {
    type = number
    description = "Number of Linux VM Scaleset instances to create"
}

variable "linux_vmss_subnet_id" {
    type = string
    description = "Backend subnet id"
}

variable "linux_vmss_lb_backend_pool_ids" {
    type = list(string)
    description = "Backend loadbalancer backend address pool ids"
}

variable "linux_vmss_size" {
    type = string
    description = "Linux VM Scaleset size"
}


####################################################################
# Optional variables
####################################################################

# Windows VMSS
variable "windows_vmss_image_sku" {
    type = string
    description = "Image sku for the windows vmss (publisher: MicrosoftWindowsServer, offer: WindowsServer)"
    default = "2019-Datacenter"
}


# Linux VMSS
variable "linux_vmss_image_sku" {
    type = string
    description = "Image sku for the linux vmss (publisher: Canonical, offer: UbuntuServer)"
    default = "18.04-LTS"
}