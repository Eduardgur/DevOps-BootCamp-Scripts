#Global name
name = "PROD-WeightTracker"

#VM Credentials
vault_name = "WT-Vault"
vault_rg_name = "TFState"

#Main config 
location = "eastus"


### Network ###
#Vnet CIDR
vnet_cidr = "192.169.0.0/16"
#Frontend subnet CIDR
frontend_subnet_cidr = "192.169.0.0/24"
#Backend subnet CIDR
backend_subnet_cidr = "192.169.1.0/24"
#Jenkins subnet CIDR
jenkins_subnet_cidr = "192.169.2.0/24"


### VMs ###
# Number of vms to create int he frontend
frontend_vm_count = 3
#VM sizes
vm_size = "Standard_B1ms"
#Public SSH key path
public_ssh_key = "~/.ssh/id_rsa.pub"
#Private SSH key path
private_ssh_key = "~/.ssh/id_rsa"

#Frontend provision script path
frontend_provision_sript = []
#Frontend provision script source path
frontend_provision_sript_source = "../Provisioning/app_provision.sh"
#Frontend provision script destinations path
frontend_provision_sript_destination = "/home/eduardgu/provision.sh"

#Jenkins provision script path
jenkins_provision_sript = []
#Jenkins provision script source path
jenkins_provision_sript_source = "../Provisioning/jenkins_provision.sh"
#Jenkins provision script destinations path
jenkins_provision_sript_destination = "/home/eduardgu/jenkins_provision.sh"

provision_custom_data_script_absolute_path = "../Provisioning/cert_provision.txt"

