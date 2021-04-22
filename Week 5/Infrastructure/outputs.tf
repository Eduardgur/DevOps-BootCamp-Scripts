#Outputs the linux VM admin password

#Outputs APP public Ip
 output "AppPublicIp" {
  value = azurerm_public_ip.AppPublicIp.ip_address
}

output "DbIp" {
  value = azurerm_private_endpoint.DbServerPrivateEndpoint.private_service_connection.0.private_ip_address
}

output "DbName" {
  value = "Servername: ${azurerm_postgresql_server.DbServer.name} DBname:${azurerm_postgresql_database.DB.name}"
}

 output "JenkinsPublicIp" {
  value = azurerm_public_ip.JenkinsPublicIp.ip_address
}


