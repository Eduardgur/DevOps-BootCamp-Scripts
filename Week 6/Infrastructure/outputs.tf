 output "fronend_public_ip" {
  value = data.azurerm_public_ip.fronend_public_ip
}

output "backend_private_ip" {
  value = data.azurerm_private_endpoint_connection.backend_private_ip
}

output "db_name" {
  value = "Servername: ${module.backend.postgresql_server_name} DBname:${module.backend.postgresql_db_name}}"
}


 output "jenkins_main_public_ip" {
  value = data.azurerm_public_ip.jenkins_public_ip
}

 output "jenkins_agents_private_ip" {
  value = ["${data.azurerm_public_ip.jenkins_agent_private_ip}"]
}

