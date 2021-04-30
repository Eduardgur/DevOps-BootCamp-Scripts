#Outputs Nics Id
output "nic_id" {
  value = [for nic in azurerm_network_interface.nic : nic.id]
}

output "nic_ip_configuration_name" {
  value = local.nic_ip_configuration_name
}

output "private_ip" {
  value = [for nic in azurerm_network_interface.nic : nic.private_ip_address]
}

output "name" {
  value = [for vm in azurerm_linux_virtual_machine.vm : vm.name]
}
