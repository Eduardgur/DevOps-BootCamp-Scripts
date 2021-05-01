
data "azurerm_virtual_machine" "main_vm" {
  name = module.main_vm.name.*
  resource_group_name = var.rg_name
  depends_on = [module.main_vm]
}

data "azurerm_virtual_machine" "agent_vm" {
  name = module.agent_vm.*.name
  resource_group_name = var.rg_name
}

output "main_public_ip" {
  value = azurerm_public_ip.public_ip.ip_address
}

output "main_public_ip_name" {
  value = azurerm_public_ip.public_ip.name
}

<<<<<<< HEAD
output "subnet_id" {
  value = module.network.subnet_id
}

output "nsg_id" {
  value = module.network.nsg_id
=======
output "main_private_ip" {
  value = data.azurerm_virtual_machine.main_vm.private_ip
}

 output "agent_private_ip" {
  value = ["${data.azurerm_virtual_machine.agent_vm.*.private_ip}"]
>>>>>>> parent of 23344ce (more fixes)
}



// output "main_private_ip" {
//   value = [for vm in module.agent_vm : vm.private_ip]
// }

// output "agent_private_ip" {
//   // value = ["${data.azurerm_virtual_machine.agent_vm.*.private_ip}"]
//   value = [for vm in module.agent_vm : vm.private_ip]
// }
