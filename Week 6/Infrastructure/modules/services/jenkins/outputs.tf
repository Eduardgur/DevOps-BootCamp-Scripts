
output "main_public_ip" {
  value = azurerm_public_ip.public_ip.ip_address
}

output "main_public_ip_name" {
  value = azurerm_public_ip.public_ip.name
}

output "main_private_ip" {
  value = [for vm in module.agent_vm : vm.private_ip]
}

output "agent_private_ip" {
  // value = ["${data.azurerm_virtual_machine.agent_vm.*.private_ip}"]
  value = [for vm in module.agent_vm : vm.private_ip]
}
