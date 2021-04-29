#Outputs db server private Ip
 output "postgresql_private_ip_address" {
  value = module.postgresql.private_ip_address
}

#Outputs db server name
 output "postgresql_server_name" {
  value = module.postgresql.server_name
}

#Outputs db name
 output "postgresql_db_name" {
  value = module.postgresql.db_name
}