#Outputs the linux VM admin password
output "LinuxPass" {
    sensitive = true
    value = var.AdminPassword
  }

#Outputs APP public Ip
 output "PublicIp" {
  value = data.azurerm_public_ip.AppPublicIp
}