locals {
    name = "Jenkins",
    nsg_rule_http_name                        = "Allow-HTTP-All",
    nsg_rule_http_priority                    = 101,
    nsg_rule_http_direction                   = "Inbound",
    nsg_rule_http_access                      = "Allow",
    nsg_rule_http_protocol                    = "Tcp",
    nsg_rule_http_source_address_prefix       = "Internet",
    nsg_rule_http_source_port_range           = "*",
    nsg_rule_http_destination_port_range      = "8080",
    nsg_rule_ssh_name                        = "Allow-SSH-All",
    nsg_rule_ssh_priority                    = 102,
    nsg_rule_ssh_direction                   = "Inbound",
    nsg_rule_ssh_access                      = "Allow",
    nsg_rule_ssh_protocol                    = "Tcp",
    nsg_rule_ssh_source_address_prefix       = "Internet",
    nsg_rule_ssh_source_port_range           = "*",
    nsg_rule_ssh_destination_port_range      = "22",
    public_ip_name_suffix = "Public-Ip"
    public_ip_allocation_method = "Static",
    public_ip_allocation_sku = "standard",
    main_vm_name_suffix = "VM-Main",
    agent_vm_name_suffix = "VM-Agent"
}

#Create nework for jenkins vms
module "network" {
    source = "../../network/basic_network"

    location = var.location
    rg_name = var.rg_name
    name = "${var.name}-${local.name}"
    subnet_cidr = var.subnet_cidr
}


#Creates NSG rule for jenkins - allow tcp 8080 from internet to jenkins subnet
resource "azurerm_network_security_rule" "nsg_rule_http" {
  name                        = local.nsg_rule_http_name
  resource_group_name         = var.rg_name
  network_security_group_name = basic_network.network.nsg_name
  priority                    = local.nsg_rule_http_priority
  direction                   = local.nsg_rule_http_direction
  access                      = local.nsg_rule_http_access
  protocol                    = local.nsg_rule_http_protocol
  source_address_prefix       = local.nsg_rule_http_source_address_prefix
  source_port_range           = local.nsg_rule_http_source_port_range
  destination_address_prefix  = var.jenkins_subnet_cidr
  destination_port_range      = local.nsg_rule_http_destination_port_range
  network_security_group_name = basic_network.network.nsg_name
}

#Creates NSG rule for jenkins - allow tcp 22 from internet to jenkins subnet
resource "azurerm_network_security_rule" "nsg_rule_ssh" {
  name                        = local.nsg_rule_ssh_name 
  resource_group_name         = var.rg_name 
  network_security_group_name = basic_network.network.nsg_name
  priority                    = local.nsg_rule_ssh_priority 
  direction                   = local.nsg_rule_ssh_direction
  access                      = local.nsg_rule_ssh_access 
  protocol                    = local.nsg_rule_ssh_protocol 
  source_address_prefix       = local.nsg_rule_ssh_source_address_prefix 
  source_port_range           = local.nsg_rule_ssh_source_port_range 
  destination_address_prefix  = var.jenkins_subnet_cidr 
  destination_port_range      = local.nsg_rule_ssh_destination_port_range 
  network_security_group_name = basic_network.network.nsg_name 
}

#Create public ip for jenkins
resource "azurerm_public_ip" "JenkinsPublicIp" {
  name                = "${var.name}-${local.public_ip_name_suffix} " 
  location            = local.location
  resource_group_name = local.rg_name
  allocation_method   = public_ip_allocation_method
  sku                 = public_ip_allocation_sku
}

#Create jenkins master vm
module "master_vm" {
    source = "../../vms/linux_vm"

    name = "${var.name}-${local.main_vm_name_suffix}"
    location = var.location
    rg_name = var.rg_name 
    count = 1
    nic_subnet = basic_network.network.subnet_id
    nic_nsg_id = basic_network.network.nsg_id
    vm_admin_username = var.vm_admin_username
    vm_size = var.vm_size
    vm_public_ssh_key = var.vm_public_ssh_key
    vm_private_ssh_key = var.vm_private_ssh_key
    provision_script_source = var.provision_script_source
    provision_script_destination = var.provision_script_destination
    provision_script = var.main_provision_script
}

#Create jenkins agent vm
module "agent_vm" {
    source = "../../vms/linux_vm"
    
    cout = var.agent_count
    name = "${var.name}-${local.agent_vm_name_suffix}"
    local = var.local
    rg_name = var.rg_name 
    count = var.agent_count
    nic_subnet = basic_network.network.subnet_id
    nic_nsg_id = basic_network.network.nsg_id
    vm_admin_username = var.vm_admin_username
    vm_size = var.vm_size
    vm_public_ssh_key = var.vm_public_ssh_key
    vm_private_ssh_key = var.vm_private_ssh_key
    provision_script_source = var.provision_script_source
    provision_script_destination = var.provision_script_destination
    provision_script = var.agent_provision_custom_data_script_path
}

