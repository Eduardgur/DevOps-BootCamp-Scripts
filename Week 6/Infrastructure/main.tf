locals {
  user_secret_name = "VmName",
  pass_secret_name = "VmPass",
  rg_name_suffix = "ResourceGroup",
}

#Retrieve credentials
data "azurerm_key_vault" "vault" {
  name                = var.vault_name
  resource_group_name = var.vault_rg_name
}

data "azurerm_key_vault_secret" "vm_user" {
  name         = local.user_secret_name
  key_vault_id = data.azurerm_key_vault.vault.id
}

data "azurerm_key_vault_secret" "vm_pass" {
  name         = local.pass_secret_name
  key_vault_id = data.azurerm_key_vault.vault.id
}



# Creates the Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "${var.name}-${local.rg_name_suffix}"
  location = var.location
}

#Creates Virtual network
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.rg_name}-${local.vnet_suffis}"
  resource_group_name = var.azurerm_resource_group.rg.name
  location            = var.location
  address_space       = [var.vnet_cidr]
}

#Create frontend environment
module "frontend" {
  source = "./modules/services/front_end"

  location = var.location
  rg_name = var.azurerm_resource_group.rg.name
  name = var.name
  subnet_cidr = var.frontend_subnet_cidr
  vm_size = var.vm_size
  vm_admin_username = data.azurerm_key_vault_secret.vm_user
  vm_public_ssh_key = var.public_ssh_key
  vm_private_ssh_key = var.private_ssh_key
  provision_script_source = var.frontend_provision_sript_source
  provision_script_destination = var.frontend_provision_sript_destination
  provision_script = var.frontend_provision_sript
}

#Create backend db environment
module "backend" {
  source = "./modules/services/back_end"

  location = var.location
  rg_name = var.azurerm_resource_group.rg.name
  name = var.name
  subnet_cidr = var.backend_subnet_cidr
  vm_size = var.vm_size
  vm_admin_username = data.azurerm_key_vault_secret.vm_user
  admin_password = data.azurerm_key_vault_secret.vm_pass
  inbound_address_prefixes = var.frontend_subnet_cidr
}

#Create jenkins environment
module "jenkins" {
  source = "./modules/services/jenkins"

  location = var.location
  rg_name = vvar.azurerm_resource_group.rg.name
  name = var.name
  subnet_cidr = var.jenkins_subnet_cidr
  vm_size = var.vm_size
  vm_admin_username = data.azurerm_key_vault_secret.vm_user
  vm_public_ssh_key = var.public_ssh_key
  vm_private_ssh_key = var.private_ssh_key
  provision_script_source = var.backend_provision_sript_source
  provision_script_destination = var.backend_provision_sript_destination
  provision_script = var.backend_provision_sript
}
