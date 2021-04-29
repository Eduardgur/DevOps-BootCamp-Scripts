#Outputs loadbalancer public Ip
 output "public_ip" {
  value = azurerm_public_ip.public_ip.ip_address
}

#Outputs loadbalancer public Ip name
 output "public_ip_name" {
  value = azurerm_public_ip.public_ip.name
}

#Outputs backend address pool id
output "lb_backend_address_pool_id" {
  value = azurerm_lb_backend_address_pool.app_lb_backend_pool.id
}

#Outputs lb nat rule id 
output "lb_nat_rule_id" {
  value = azurerm_lb_nat_rule.app_lb_nat_rule.*.id
}