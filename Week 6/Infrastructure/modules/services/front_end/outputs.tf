#Outputs loadbalancer public Ip
 output "public_ip" {
  value = module.loadbalancer.public_ip
}

output "public_ip_name" {
    value = module.loadbalancer.public_ip_name
}

output "subnet_address_prefixes" {
  value = module.network.subnet_address_prefixes
}