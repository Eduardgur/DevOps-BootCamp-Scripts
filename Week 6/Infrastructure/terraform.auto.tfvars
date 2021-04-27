#Global name
name = "WeightTracker"

#VM Credentials
vault_name = "WR-Terraform-Vault"
vault_rg_name = "TFState"

#Main config 
location = "eastus"


### Network ###
#Vnet CIDR
vnet_cidr = "192.168.0.0/16"
#Frontend subnet CIDR
frontend_subnet_cidr = "192.168.0.0/24"
#Backend subnet CIDR
backend_subnet_cidr = "192.168.1.0/24"
#Jenkins subnet CIDR
jenkins_subnet_cidr = "192.168.2.0/24"


### VMs ###
#VM sizes
vm_size = "Standard_B1ms"
#Public SSH key path
public_ssh_key = "~/.ssh/id_rsa.pub"
#Private SSH key path
private_ssh_key = "~/.ssh/id_rsa"

#Frontend provision script path
frontend_provision_sript = [
     "sudo chmod +x /home/${var.AdminUserName}/provision.sh",
      "sudo bash /home/${var.AdminUserName}/provision.sh '${azurerm_network_interface.AppVmNic[count.index].private_ip_address}' '8080' '${azurerm_public_ip.AppPublicIp.ip_address}' '${azurerm_private_endpoint.DbServerPrivateEndpoint.private_service_connection.0.private_ip_address}' 'https://dev-91725987.okta.com' '0oac29sg1MnlaSgsu5d6' 'tyM1Gtw1rGwXVscTZ1uTBjPj6ZzvazWVTehyuCex' '5432' '${var.AdminUserName}@${azurerm_postgresql_server.DbServer.name}' '${azurerm_postgresql_database.DB.name}' '${data.azurerm_key_vault_secret.VMPass.value}' > '/home/${var.AdminUserName}/provision.log'" ,
]
#Frontend provision script source path
frontend_provision_sript_source = "../Provisioning/app_provision.sh"
#Frontend provision script destinations path
frontend_provision_sript_destination = "/home/${var.AdminUserName}/provision.sh"

#Jenkins provision script path
jenkins_provision_sript = [
     "sudo chmod +x /home/${var.AdminUserName}/jenkins_provision.sh",
      "sudo bash /home/${var.AdminUserName}/jenkins_provision.sh",
]
#Jenkins provision script source path
jenkins_provision_sript_source = "../Provisioning/jenkins_provision.sh"
#Jenkins provision script destinations path
jenkins_provision_sript_destination = "/home/${var.AdminUserName}/jenkins_provision.sh"


