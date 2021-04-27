#Outputs db server private Ip
 output "private_ip_address" {
  value = azurerm_private_endpoint.server_private_endpoint.private_service_connection.0.private_ip_address
}

#Outputs db server name
 output "server_name" {
  value = azurerm_postgresql_server.server.name
}

#Outputs db name
 output "db_name" {
  value = azurerm_postgresql_database.database.name
}

