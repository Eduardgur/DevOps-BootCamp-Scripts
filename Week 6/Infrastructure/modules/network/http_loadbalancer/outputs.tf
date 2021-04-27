#Outputs loadbalancer public Ip
 output "lb_public_ip" {
  value = azurerm_public_ip.public_ip.ip_address
}

#Outputs backend address pool id
output "lb_backend_address_pool_id" {
  value = azurerm_lb_backend_address_pool.app_lb_backend_pool.id
}

