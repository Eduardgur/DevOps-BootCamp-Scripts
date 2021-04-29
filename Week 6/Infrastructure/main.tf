locals {
  user_secret_name = "VmName"
  pass_secret_name = "VmPass"
  rg_name_suffix = "ResourceGroup"
  vnet_suffis = "VNet"
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
  name                = "${azurerm_resource_group.rg.name}-${local.vnet_suffis}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  address_space       = [var.vnet_cidr]
}

#Create frontend environment
module "frontend" {
  source = "./modules/services/front_end"

  location = var.location
  rg_name = azurerm_resource_group.rg.name
  vnet_name = azurerm_virtual_network.vnet.name
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
  rg_name = azurerm_resource_group.rg.name
  name = var.name
  vnet_name = azurerm_virtual_network.vnet.name
  subnet_cidr = var.backend_subnet_cidr
  admin_username = data.azurerm_key_vault_secret.vm_user
  admin_password = data.azurerm_key_vault_secret.vm_pass
  inbound_address_prefixes = var.frontend_subnet_cidr
}

#Create jenkins environment
module "jenkins" {
  source = "./modules/services/jenkins"

  location = var.location
  rg_name = azurerm_resource_group.rg.name
  name = var.name
  vnet_name = azurerm_virtual_network.vnet.name
  subnet_cidr = var.jenkins_subnet_cidr
  vm_size = var.vm_size
  vm_admin_username = data.azurerm_key_vault_secret.vm_user
  vm_public_ssh_key = var.public_ssh_key
  vm_private_ssh_key = var.private_ssh_key
  provision_script_source = var.jenkins_provision_sript_source
  provision_script_destination = var.jenkins_provision_sript_destination
  main_provision_script = var.jenkins_provision_sript
}


data "azurerm_public_ip" "fronend_public_ip" {
  name = module.frontend.public_ip_name
  resource_group_name = azurerm_resource_group.rg.name
}

data "azurerm_private_endpoint_connection" "backend_private_ip" {
  name = module.backend.postgresql_server_name
  resource_group_name = azurerm_resource_group.rg.name
}

data "azurerm_public_ip" "jenkins_public_ip" {
  name = module.jenkins.public_ip_name
  resource_group_name = azurerm_resource_group.rg.name
  depends_on = [module.jenkins]
}

data "azurerm_public_ip" "jenkins_agent_private_ip" {
  name = module.jenkins.agent_private_ip
  resource_group_name = azurerm_resource_group.rg.name
  depends_on = [module.jenkins]
}