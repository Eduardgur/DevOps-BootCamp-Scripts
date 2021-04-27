#Outputs Nics Id
output "nic_id" {
  value = azurerm_network_interface.nic.id
}

output "vm_ip_configuration_name" {
  value = local.nic_ip_configuration_name
}

output "public_ip" {
  value = azurerm_public_ip.ip_address
}

output "agent_private_ip" {
  value = ["${azurerm_network_interface.nic.*.private_ip_address}"]
}
