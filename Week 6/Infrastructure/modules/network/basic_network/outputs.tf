#Outputs NSG name
 output "nsg_name" {
  value = azurerm_network_security_group.nsg.name
}

#Outputs NSG id
 output "nsg_id" {
  value = azurerm_network_security_group.nsg.id
}

#Outputs subnet id
 output "subent_id" {
  value = azurerm_subnet.subnet.id
}

