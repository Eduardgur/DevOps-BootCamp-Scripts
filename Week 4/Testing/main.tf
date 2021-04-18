# Creates the Resource Group
resource "azurerm_resource_group" "rg" {
  name     = var.RgName
  location = var.Location
}


## Networking
#Creates Virtual network
resource "azurerm_virtual_network" "vnet" {
  name                = "${azurerm_resource_group.rg.name}-VNet"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = [var.VnetCidr ]
}

#Creates subnet for the frontend
resource "azurerm_subnet" "AppSubnet" {
  name                 = "App-Subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["192.168.0.0/24"]
  depends_on           = [azurerm_virtual_network.vnet]
}

#Creates subnet for the backend
resource "azurerm_subnet" "DbSubnet" {
  name                 = "DB-Subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["192.168.1.0/24"]
  depends_on           = [azurerm_virtual_network.vnet]
}

#Creates subnet for Bastion
resource "azurerm_subnet" "AzureBastionSubnet" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["192.168.2.0/24"]
  depends_on           = [azurerm_virtual_network.vnet]
}


## Security ##
#Creates NSG for the frontend
resource "azurerm_network_security_group" "PublicNsg" {
  name                = "App-NSG"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}

#Creates NSG for the backend
resource "azurerm_network_security_group" "PrivateNsg" {
  name                = "DB-NSG"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}

#Creates NSG rule for the frontend - allow tcp 80 from internet to frontend subnet
resource "azurerm_network_security_rule" "HttpNsgRule" {
  name                        = "Allow-HTTP-All"
  resource_group_name         = azurerm_resource_group.rg.name
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_address_prefix       = "Internet"
  source_port_range           = "*"
  destination_address_prefix  = "192.168.0.0/24"
  destination_port_range      = "80"
  network_security_group_name = azurerm_network_security_group.PublicNsg.name
}

// resource "azurerm_network_security_rule" "RdpNsgRule" {
//   name                        = "Allow-RDP-All"
//   resource_group_name = azurerm_resource_group.rg.name
//   priority                    = 101
//   direction                   = "Inbound"
//   access                      = "Allow"
//   protocol                    = "Tcp"
//   source_address_prefix       = "*"
//   source_port_range           = "*"
//   destination_address_prefix  = "192.168.0.0/24"
//   destination_port_range      = "3389"
//   network_security_group_name = azurerm_network_security_group.PublicNsg.name
// }

// resource "azurerm_network_security_rule" "SshNsgRule" {
//   name                        = "Allow-SSH-All"
//   resource_group_name = azurerm_resource_group.rg.name
//   priority                    = 102
//   direction                   = "Inbound"
//   access                      = "Allow"
//   protocol                    = "Tcp"
//   source_address_prefix       = "*"
//   source_port_range           = "*"
//     destination_address_prefix  = "192.168.1.0/24"
//   destination_port_range      = "22"
//   network_security_group_name = azurerm_network_security_group.PrivateNsg.name
// }

#Creates NSG rule for the backend - allow tcp 5432 from loadbalancer to backend subnet
resource "azurerm_network_security_rule" "PostgresNsgRule" {
  name                        = "Allow-Postgres-All"
  resource_group_name         = azurerm_resource_group.rg.name
  priority                    = 103
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_address_prefix       = "AzureLoadBalancer" 
  source_port_range           = "*"
  destination_address_prefix  = "192.168.1.0/24"
  destination_port_range      = "5432"
  network_security_group_name = azurerm_network_security_group.PrivateNsg.name
}

#Associats frontend subnet to its NSG
resource "azurerm_subnet_network_security_group_association" "PublicNsgSubnet" {
  subnet_id                 = azurerm_subnet.AppSubnet.id
  network_security_group_id = azurerm_network_security_group.PublicNsg.id
}

#Associats backend subnet to its NSG
resource "azurerm_subnet_network_security_group_association" "PrivateNsgSubnet" {
  subnet_id                 = azurerm_subnet.DbSubnet.id
  network_security_group_id = azurerm_network_security_group.PrivateNsg.id
}


######
#Creates public ip for the frontend loadbalancer 
resource "azurerm_public_ip" "AppPublicIp" {
  name                = "App-Public-Ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "standard"
}

#Creates loadbalancer for the frontend
resource "azurerm_lb" "AppLoadbalancer" {
  name                = "App-LoadBalancer"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "App-LB-Public-Ip"
    public_ip_address_id = azurerm_public_ip.AppPublicIp.id
  }
}

#Creates backend ip pool for the frontend loadbalancer 
resource "azurerm_lb_backend_address_pool" "AppLbBackEndPool" {
  resource_group_name = azurerm_resource_group.rg.name
  loadbalancer_id     = azurerm_lb.AppLoadbalancer.id
  name                = "App-LB-BeckEnd-Pool"
}

#Creates loadbalancer rule for the frontend - tcp 80
resource "azurerm_lb_rule" "AppHttpLbRule" {
  resource_group_name            = azurerm_resource_group.rg.name
  loadbalancer_id                = azurerm_lb.AppLoadbalancer.id
  name                           = "HTTP-LB-Rule"
  protocol                       = "Tcp"
  frontend_ip_configuration_name = "App-LB-Public-Ip"
  frontend_port                  = 80
  backend_port                   = 80
  backend_address_pool_id        = azurerm_lb_backend_address_pool.AppLbBackEndPool.id
  probe_id                       = azurerm_lb_probe.AppHttpProb.id
  depends_on                     = [azurerm_lb_probe.AppHttpProb]
}

// resource "azurerm_lb_rule" "AppRdpLbRule" {
//   resource_group_name            = azurerm_resource_group.rg.name
//   loadbalancer_id                = azurerm_lb.AppLoadbalancer.id
//   name                           = "RDP-LB-Rule"
//   protocol                       = "Tcp"
//   frontend_ip_configuration_name = "App-LB-Public-Ip"
//   frontend_port                  = 3389
//   backend_port                   = 3389
//   backend_address_pool_id        = azurerm_lb_backend_address_pool.AppLbBackEndPool.id
//   probe_id                       = azurerm_lb_probe.AppRdpProb.id
//   depends_on = [azurerm_lb_probe.AppRdpProb]
// }

#Creates loadbalancer prob for the frontend - 80
resource "azurerm_lb_probe" "AppHttpProb" {
  resource_group_name = azurerm_resource_group.rg.name
  loadbalancer_id     = azurerm_lb.AppLoadbalancer.id
  name                = "HTTP-Probe"
  protocol            = "Http"
  port                = 80
  request_path        = "/"
  number_of_probes    = 5
}

// resource "azurerm_lb_probe" "AppRdpProb" {
//   resource_group_name = azurerm_resource_group.rg.name
//   loadbalancer_id     = azurerm_lb.AppLoadbalancer.id
//   name                = "RPD-Probe"
//   port                = 3389
//   number_of_probes    = 5
// }


###########
#Creates loadbalancer for the backend
resource "azurerm_lb" "DbLoadbalancer" {
  name                = "DB-LoadBalancer"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "standard"
  
  frontend_ip_configuration {
    name      = "DB-LB-Public-Ip"
    subnet_id = azurerm_subnet.DbSubnet.id
  }
}

#Creates backend ip pool for the backend loadbalancer 
resource "azurerm_lb_backend_address_pool" "DbLbBackEndPool" {
  resource_group_name = azurerm_resource_group.rg.name
  loadbalancer_id     = azurerm_lb.DbLoadbalancer.id
  name                = "DB-LB-BackEnd-Pool"
}

// resource "azurerm_lb_backend_address_pool_address" "DbLbBackEndIp" {
//   name                    = "DB-LoadBalancer-Private-Ip"
//   backend_address_pool_id = azurerm_lb_backend_address_pool.DbLbBackEndPool.id
//   virtual_network_id      = azurerm_virtual_network.vnet.id
//   ip_address              = "192.168.1.250"
// }

#Creates loadbalancer rule for the backend - tcp 5432
resource "azurerm_lb_rule" "AppDbPostgresLbRule" {
  resource_group_name            = azurerm_resource_group.rg.name
  loadbalancer_id                = azurerm_lb.DbLoadbalancer.id
  name                           = "App-DB-Postgres-LB-Rule"
  protocol                       = "Tcp"
  frontend_ip_configuration_name = "DB-LB-Public-Ip"
  frontend_port                  = 5432
  backend_port                   = 5432
  backend_address_pool_id        = azurerm_lb_backend_address_pool.DbLbBackEndPool.id
  probe_id                       = azurerm_lb_probe.DbPostgresProb.id
  depends_on                     = [azurerm_lb_probe.DbPostgresProb]
}

// resource "azurerm_lb_rule" "DbSshLbRule" {
//   resource_group_name            = azurerm_resource_group.rg.name
//   loadbalancer_id                = azurerm_lb.DbLoadbalancer.id
//   name                           = "SSH-LB-Rule"
//   protocol                       = "Tcp"
//   frontend_ip_configuration_name = "DB-LB-Public-Ip" 
//   frontend_port                  = 22
//   backend_port                   = 22
//   backend_address_pool_id        = azurerm_lb_backend_address_pool.DbLbBackEndPool.id
//   probe_id                       = azurerm_lb_probe.DbSshProb.id
//   depends_on = [azurerm_lb_probe.DbSshProb]
// }

#Creates loadbalancer prob for the backend - 5432
resource "azurerm_lb_probe" "DbPostgresProb" {
  resource_group_name = azurerm_resource_group.rg.name
  loadbalancer_id     = azurerm_lb.DbLoadbalancer.id
  name                = "Postgres-Probe"
  port                = 5432
  number_of_probes    = 5
}

// resource "azurerm_lb_probe" "DbSshProb" {
//   resource_group_name = azurerm_resource_group.rg.name
//   loadbalancer_id     = azurerm_lb.DbLoadbalancer.id
//   name                = "Postgres-Probe"
//   port                = 22
//   number_of_probes    = 5
// }


#Creates public ip for the backend nat gateway
resource "azurerm_public_ip" "DbPublicIp" {
  name                = "Db-GW-Public-Ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "standard"
}

#Creates nat gatway for the backend 
resource "azurerm_nat_gateway" "DbGateWay" {
  name                    = "nat-Gateway"
  location                = azurerm_resource_group.rg.location
  resource_group_name     = azurerm_resource_group.rg.name
  sku_name                = "Standard"
  idle_timeout_in_minutes = 10
}

#Associats backend nat gateway with its public ip
resource "azurerm_nat_gateway_public_ip_association" "DbGateWayIpAssociate" {
  nat_gateway_id       = azurerm_nat_gateway.DbGateWay.id
  public_ip_address_id = azurerm_public_ip.DbPublicIp.id
}

#Associats backend nat gateway with its subnet
resource "azurerm_subnet_nat_gateway_association" "DbGateWaySubnetAssociate" {
  subnet_id      = azurerm_subnet.DbSubnet.id
  nat_gateway_id = azurerm_nat_gateway.DbGateWay.id
}


#Creates public ip for Bastion
resource "azurerm_public_ip" "BastionPublicIp" {
  name                = "Bastion-Public-Ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "standard"
}

#Create Bastion service to allow control over the vms
resource "azurerm_bastion_host" "WeightTrackerBastion" {
  name                = "WeightTracker-Bastion"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  ip_configuration {
    name                 = "public"
    subnet_id            = azurerm_subnet.AzureBastionSubnet.id
    public_ip_address_id = azurerm_public_ip.BastionPublicIp.id
  }
}

#App Scale Set
resource "azurerm_windows_virtual_machine_scale_set" "AppVmScaleSet" {
  name                 = "App-Vm-Scale-Set"
  resource_group_name  = azurerm_resource_group.rg.name
  location             = azurerm_resource_group.rg.location
  sku                  = var.VmSize
  upgrade_mode         = "Automatic"
  health_probe_id      = azurerm_lb_probe.AppHttpProb.id
  instances            = 3
  computer_name_prefix = "App-VM"
  admin_username       = var.AdminUserName
  admin_password       = var.AdminPassword


  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  network_interface {
    name    = "App-VM-NIC"
    primary = true

    ip_configuration {
      name                                   = "internal"
      primary                                = true
      subnet_id                              = azurerm_subnet.AppSubnet.id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.AppLbBackEndPool.id]
    }
  }
  winrm_listener {
    protocol = "Http"
  }
}

// DB Scale Set
resource "azurerm_linux_virtual_machine_scale_set" "DbVmScaleSet" {
  name                            = "Db-Vm-Scale-Set"
  resource_group_name             = azurerm_resource_group.rg.name
  location                        = azurerm_resource_group.rg.location
  sku                             = var.VmSize
  upgrade_mode                    = "Automatic"
  health_probe_id                 = azurerm_lb_probe.DbPostgresProb.id
  instances                       = 3
  computer_name_prefix            = "Db-VM"
  disable_password_authentication = "false"
  admin_username                  = var.AdminUserName
  admin_password                  = var.AdminPassword


  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  network_interface {
    name    = "Db-VM-NIC"
    primary = true

    ip_configuration {
      name                                   = "internal"
      primary                                = true
      subnet_id                              = azurerm_subnet.DbSubnet.id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.DbLbBackEndPool.id]
    }

  }
}



