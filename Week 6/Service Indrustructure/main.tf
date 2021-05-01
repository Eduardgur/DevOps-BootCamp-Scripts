locals {
  user_secret_name = "VmName"
  pass_secret_name = "VmPass"
  rg_name_suffix = "ResourceGroup"
  vnet_suffis = "VNet"
  vnet_peering_suffix_service_to_dev = "vnet_peering_service_to_frontend_dev"
  vnet_peering_suffix_dev_to_service = "vnet_peering_frontend_to_service_dev"
  vnet_peering_suffix_service_to_prod = "vnet_peering_service_to_frontend_prod"
  vnet_peering_suffix_prod_to_service = "vnet_peering_frontend_to_service_prod"
  public_ip_name_suffix = "Public-Ip"
  public_ip_allocation_method = "Static"
  public_ip_allocation_sku = "standard"
  ansible_suffix = "Ansible"
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
  name                = "${var.name}-${local.vnet_suffis}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  address_space       = [var.vnet_cidr]
}

#Create jenkins environment
module "jenkins" {
  source = "../Infrastructure/modules/services/jenkins"
  // agent_count = var.jenkins_agent_count

  location = var.location
  rg_name = azurerm_resource_group.rg.name
  name = var.name
  vnet_name = azurerm_virtual_network.vnet.name
  subnet_cidr = var.jenkins_subnet_cidr
  vm_size = var.vm_size
  vm_admin_username = data.azurerm_key_vault_secret.vm_user.value
  vm_public_ssh_key = var.public_ssh_key
  vm_private_ssh_key = var.private_ssh_key
  // provision_script_source = var.jenkins_provision_sript_source
  // provision_script_destination = var.jenkins_provision_sript_destination
  // main_provision_script = var.jenkins_provision_sript
  // agent_provision_custom_data_script_path = [var.agent_provision_custom_data_script_path]
  // provision_custom_data_script_absolute_path = var.provision_custom_data_script_absolute_path
}

## Ansible ##
#Create public ip for ansible
resource "azurerm_public_ip" "ansible_public_ip" {
  name                = "${var.name}-${local.ansible_suffix}-${local.public_ip_name_suffix}" 
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = local.public_ip_allocation_method
  sku                 = local.public_ip_allocation_sku
}

#Create vm
module "ansible" {
    source = "../Infrastructure/modules/vms/linux_vm"

    name = "${var.name}-${local.ansible_suffix}"
    location = var.location
    rg_name = azurerm_resource_group.rg.name 
    nic_subnet_id = module.jenkins.subnet_id
    nic_nsg_id = module.jenkins.nsg_id
    admin_username = data.azurerm_key_vault_secret.vm_user.value
    vm_size = var.vm_size
    vm_host_ip = azurerm_public_ip.ansible_public_ip.ip_address
    vm_public_ssh_key = var.public_ssh_key
    vm_private_ssh_key = var.private_ssh_key
    public_ip_id = azurerm_public_ip.ansible_public_ip.id
}


## Vnet peering ##


data "azurerm_virtual_network" "dev_vnet" {
  name = var.dev_remote_vnet_name
  resource_group_name = var.dev_remote_vnet_rg_name
}

resource "azurerm_virtual_network_peering" "vnet_peering_dev" {
  name                      = "${var.name}-${local.vnet_peering_suffix_service_to_dev}"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.vnet.name
  remote_virtual_network_id = data.azurerm_virtual_network.dev_vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = false
  allow_gateway_transit = false
}

resource "azurerm_virtual_network_peering" "dev_peering_vnet" {
  name                      = "${var.name}-${local.vnet_peering_suffix_dev_to_service}"
  resource_group_name       = data.azurerm_virtual_network.dev_vnet.resource_group_name
  virtual_network_name      = data.azurerm_virtual_network.dev_vnet.name
  remote_virtual_network_id = azurerm_virtual_network.vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = false
  allow_gateway_transit = false
}


data "azurerm_virtual_network" "prod_vnet" {
  name = var.prod_remote_vnet_name
  resource_group_name = var.prod_remote_vnet_rg_name
}

resource "azurerm_virtual_network_peering" "vnet_peering_prod" {
  name                      = "${var.name}-${local.vnet_peering_suffix_service_to_prod}"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.vnet.name
  remote_virtual_network_id = data.azurerm_virtual_network.prod_vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = false
  allow_gateway_transit = false
}

resource "azurerm_virtual_network_peering" "prod_peering_vnet" {
  name                      = "${var.name}-${local.vnet_peering_suffix_prod_to_service}"
  resource_group_name       = data.azurerm_virtual_network.prod_vnet.resource_group_name
  virtual_network_name      = data.azurerm_virtual_network.prod_vnet.name
  remote_virtual_network_id = azurerm_virtual_network.vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = false
  allow_gateway_transit = false
}
