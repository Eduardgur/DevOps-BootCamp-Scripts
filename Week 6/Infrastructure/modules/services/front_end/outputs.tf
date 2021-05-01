#Outputs loadbalancer public Ip
 output "public_ip" {
  value = -module.loadbalancer.public_ip
}

output "public_ip_name" {
    value = module.loadbalancer.public_ip_name
}