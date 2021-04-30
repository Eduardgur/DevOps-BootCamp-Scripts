data "azurerm_public_ip" "fronend_public_ip" {
  name = module.frontend.public_ip_name
  resource_group_name = azurerm_resource_group.rg.name
}

// data "azurerm_private_endpoint_connection" "backend_private_ip" {
//   name = module.backend.postgresql_server_name
//   resource_group_name = azurerm_resource_group.rg.name
// }

// data "azurerm_public_ip" "jenkins_public_ip" {
//   name = module.jenkins.main_public_ip
//   resource_group_name = azurerm_resource_group.rg.name
//   depends_on = [module.jenkins]
// }



output "fronend_public_ip" {
  value = module.frontend.public_ip
}

output "backend_private_ip" {
  value = module.backend.postgresql_private_ip_address
}

output "db_name" {
  value = "Servername: ${module.backend.postgresql_server_name} DBname:${module.backend.postgresql_db_name}}"
}


 output "jenkins_main_public_ip" {
  value = module.jenkins.main_public_ip
}

 output "jenkins_agents_private_ip" {
  value = module.jenkins.agent_private_ip
}

