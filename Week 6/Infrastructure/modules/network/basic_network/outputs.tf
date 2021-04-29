data "azurerm_subnet" "subnet" {
  name = azurerm_subnet.subnet.name
  resource_group_name = var.rg_name
  virtual_network_name = var.vnet_name
}

data "azurerm_network_security_group" "nsg" {
  name = azurerm_network_security_group.nsg.name
  resource_group_name = var.rg_name
}

#Outputs NSG name
 output "nsg_name" {
  value = data.azurerm_network_security_group.nsg.name
}

#Outputs NSG id
 output "nsg_id" {
  value = data.azurerm_network_security_group.nsg.id
}

#Outputs subnet id
 output "subnet_id" {
  value = data.azurerm_subnet.subnet.id
}
