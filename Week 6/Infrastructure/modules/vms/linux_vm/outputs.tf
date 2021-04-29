data "azurerm_network_interface" "nic" {
  name = azurerm_network_interface.nic.*.name
  resource_group_name = var.rg_name
}

data "azurerm_virtual_machine" "vm" {
  name = azurerm_linux_virtual_machine.vm.*.name
  resource_group_name = var.rg_name
}

#Outputs Nics Id
output "nic_id" {
  value = data.azurerm_network_interface.nic.*.id
}

output "nic_ip_configuration_name" {
  value = local.nic_ip_configuration_name
}

output "private_ip" {
  value = ["${data.azurerm_network_interface.nic.*.private_ip_address}"]
}

output "name" {
  value = data.azurerm_virtual_machine.vm.*.name
}
