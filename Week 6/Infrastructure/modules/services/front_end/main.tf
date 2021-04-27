locals{
    name= "FrontEnd"
    vm_name_suffix = "Linux-VM"
    nsg_rule_http_name                        = "Allow-HTTP-All"
    nsg_rule_http_priority                    = 101
    nsg_rule_http_direction                   = "Inbound"
    nsg_rule_http_access                      = "Allow"
    nsg_rule_http_protocol                    = "Tcp"
    nsg_rule_http_source_address_prefix       = "Internet"
    nsg_rule_http_source_port_range           = "*"
    nsg_rule_http_destination_port_range      = "80"
    nsg_rule_ssh_name                        = "Allow-SSH-All"
    nsg_rule_ssh_priority                    = 102
    nsg_rule_ssh_direction                   = "Inbound"
    nsg_rule_ssh_access                      = "Allow"
    nsg_rule_ssh_protocol                    = "Tcp"
    nsg_rule_ssh_source_address_prefix       = "Internet"
    nsg_rule_ssh_source_port_range           = "*"
    nsg_rule_ssh_destination_port_range      = "22"
}

#Create nework for the front end
module "network" {
    source = "../../network/basic_network"

    location = var.location
    rg_name = var.rg_name
    name = "${var.name}-${local.name}"
    subnet_cidr = var.subnet_cidr
}

#Create loadbalancer for the front end
module "loadbalancer" {
    source = "../../network/http_loadbalancer"

    location = var.location
    rg_name = var.rg_name
    name = "${var.name}-${local.name}"
    create_public_ip = true
    lb_nat_rule_count = var.vm_count
}

#Create jenkins master vm
module "vms" {
    source = "../../vms/linux_vm"
    count = var.vm_count

    name = "${var.name}-${local.name}"
    location = var.location
    rg_name = var.rg_name 
    nic_subnet_id = basic_network.network.subnet_id
    nic_nsg_id = basic_network.network.nsg_id
    vm_admin_username = var.vm_admin_username
    vm_size = var.vm_size
    vm_public_ssh_key = var.vm_public_ssh_key
    vm_private_ssh_key = var.vm_private_ssh_key
    provision_script_source = var.provision_script_source
    provision_script_destination = var.provision_script_destination
    provision_script = var.provision_script
}


#Creates NSG rule for app - allow tcp 80 from internet to frontend subnet
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
  destination_address_prefix  = var.nsg_rule_http_destination_address_prefix
  destination_port_range      = local.nsg_rule_http_destination_port_range
}

#Creates NSG rule for jenkins - allow tcp 22 from internet to frontend subnet
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
  destination_address_prefix  = var.nsg_rule_ssh_destination_address_prefix 
  destination_port_range      = local.nsg_rule_ssh_destination_port_range 
}

#Assiciate VM nic to LB address pool
resource "azurerm_network_interface_backend_address_pool_association" "AppVmNicToAddressPool" {
  count = var.vm_count

  network_interface_id    = linux_vm.vms.nic_id
  ip_configuration_name   = linux_vm.nic_ip_configuration_name
  backend_address_pool_id = http_loadbalancer.loadbalancer.lb_backend_address_pool_id
  depends_on              = [linux_vm.vms]
}

#Associate VM to lb nat rule
resource "azurerm_network_interface_nat_rule_association" "AppVmNicToLbNatRule" {
  count = vm_count

  network_interface_id  = linux_vm.vms.nic_id
  ip_configuration_name   = linux_vm.nic_ip_configuration_name
  nat_rule_id           = azurerm_lb_nat_rule.AppLbNatRule[count.index].id
  depends_on            = [linux_vm.vms]
}