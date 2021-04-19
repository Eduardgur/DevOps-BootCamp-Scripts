#Outputs the linux VM admin password
output "LinuxPass" {
    sensitive = true
    value = module.scale_sets.AdminPass
  }

#Outputs APP public Ip
 output "AppPublicIp" {
  value = azurerm_public_ip.AppPublicIp.ip_address
}

#Outputs backend nat gateway public Ip
 output "DbPublicIp" {
  value = azurerm_public_ip.DbPublicIp.ip_address
}

#Outputs backend loadbalancer frontend Ip
 output "PrivateDbIp" {
  value = azurerm_lb.DbLoadbalancer.private_ip_address
}