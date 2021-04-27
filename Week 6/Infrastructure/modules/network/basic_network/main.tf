#Naming locals
locals {
    vnet_suffis = "VNet",
    subnet_sufix = "Subnet",
    nsg_suffix = "NSG",
}

#Create subnet for the frontend
resource "azurerm_subnet" "subnet" {
  name                 = "${var.name}-${local.subnet_suffix}"
  resource_group_name   = var.rg_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.subnet_cidr]
  service_endpoints                              = local.nic_service_endpoints
  enforce_private_link_endpoint_network_policies = local.nic_enforce_private_link_endpoint_network_policies
}

#Create NSG for the frontend
resource "azurerm_network_security_group" "nsg" {
  name                 = "${var.name}-${local.nsg_suffix}"
  resource_group_name = var.rg_name
  location            = var.location
}

#Associats subnet to its NSG
resource "azurerm_subnet_network_security_group_association" "subnet_nsg_association" {
  subnet_id                 = azurerm_subnet.subnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

