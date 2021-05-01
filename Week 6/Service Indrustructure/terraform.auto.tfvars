#Global name
name = "Service-WeightTracker"

#VM Credentials
vault_name = "WT-Vault"
vault_rg_name = "TFState"

#Main config 
location = "eastus"


### Network ###
dev_remote_vnet_name = "DEV-WeightTracker-VNet"
dev_remote_vnet_rg_name = "DEV-WeightTracker-ResourceGroup"
prod_remote_vnet_name = "PROD-WeightTracker-VNet"
prod_remote_vnet_rg_name = "PROD-WeightTracker-ResourceGroup"
#Vnet CIDR
vnet_cidr = "192.167.0.0/16"
#Jenkins subnet CIDR
jenkins_subnet_cidr = "192.167.0.0/24"


### VMs ###
#VM sizes
vm_size = "Standard_B1ms"
#Public SSH key path
public_ssh_key = "~/.ssh/id_rsa.pub"
#Private SSH key path
private_ssh_key = "~/.ssh/id_rsa"

jenkins_agent_count = 2

#Jenkins provision script path
// jenkins_provision_sript = []
#Jenkins provision script source path
// jenkins_provision_sript_source = "../Provisioning/dummy"
#Jenkins provision script destinations path
// jenkins_provision_sript_destination = "/home/eduardgu/dummy"

// provision_custom_data_script_absolute_path = "../Provisioning/cert_provision.txt"

// agent_provision_custom_data_script_path = "../Provisioning/jenkins_agent_provision.txt"