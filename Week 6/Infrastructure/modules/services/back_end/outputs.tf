#Outputs db server private Ip
 output "postgresql_private_ip_address" {
  value = postgresql.private_ip_address
}

#Outputs db server name
 output "postgresql_server_name" {
  value = postgresql.server_name
}

#Outputs db name
 output "postgresql_db_name" {
  value = postgresql.db_name
}