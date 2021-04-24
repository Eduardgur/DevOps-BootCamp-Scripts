data "azurerm_key_vault" "Vault" {
  name                = var.VaultName
  resource_group_name = var.VaultResourceGroupName
}

data "azurerm_key_vault_secret" "VMPass" {
  name         = "VmPass"
  key_vault_id = data.azurerm_key_vault.Vault.id
}


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
  address_space       = [var.VnetCidr]
}

#Creates subnet for the frontend
resource "azurerm_subnet" "AppSubnet" {
  name                 = "App-Subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["192.168.0.0/24"]
}


## Security ##
#Creates NSG for the frontend
resource "azurerm_network_security_group" "AppNsg" {
  name                = "App-NSG"
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
  destination_port_range      = "8080"
  network_security_group_name = azurerm_network_security_group.AppNsg.name
}

#Creates NSG rule for the frontend - allow tcp 22 from internet to frontend subnet
resource "azurerm_network_security_rule" "SshNsgRule" {
  name                        = "Allow-SSH-All"
  resource_group_name         = azurerm_resource_group.rg.name
  priority                    = 101
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_address_prefix       = "Internet"
  source_port_range           = "*"
  destination_address_prefix  = "192.168.0.0/24"
  destination_port_range      = "22"
  network_security_group_name = azurerm_network_security_group.AppNsg.name
}

#Associats frontend subnet to its NSG
resource "azurerm_subnet_network_security_group_association" "AppNsgSubnet" {
  subnet_id                 = azurerm_subnet.AppSubnet.id
  network_security_group_id = azurerm_network_security_group.AppNsg.id
}


###### Front module
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
  loadbalancer_id = azurerm_lb.AppLoadbalancer.id
  name            = "App-LB-BeckEnd-Pool"
}

#Creates loadbalancer rule for the frontend - tcp 80
resource "azurerm_lb_rule" "AppHttpLbRule" {
  resource_group_name            = azurerm_resource_group.rg.name
  loadbalancer_id                = azurerm_lb.AppLoadbalancer.id
  name                           = "HTTP-LB-Rule"
  protocol                       = "Tcp"
  frontend_ip_configuration_name = "App-LB-Public-Ip"
  frontend_port                  = 80
  backend_port                   = 8080
  backend_address_pool_id        = azurerm_lb_backend_address_pool.AppLbBackEndPool.id
  probe_id                       = azurerm_lb_probe.AppHttpProb.id
}

#Creates loadbalancer prob for the frontend - 80
resource "azurerm_lb_probe" "AppHttpProb" {
  resource_group_name = azurerm_resource_group.rg.name
  loadbalancer_id     = azurerm_lb.AppLoadbalancer.id
  name                = "HTTP-Probe"
  protocol            = "Http"
  port                = 8080
  request_path        = "/"
  number_of_probes    = 5
}





###### VMs module #####

## Front End ##

#VM Nic
resource "azurerm_network_interface" "AppVmNic" {
  count = 3

  name                = "App-VM-Nic-${count.index}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  ip_configuration {
    name                          = "local"
    subnet_id                     = azurerm_subnet.AppSubnet.id
    private_ip_address_allocation = "Dynamic"
    primary                       = "true"
  }
}

#Associate VM nics to NSG
resource "azurerm_network_interface_security_group_association" "AppVmNicToNSG" {
  count = 3

  network_interface_id      = azurerm_network_interface.AppVmNic[count.index].id
  network_security_group_id = azurerm_network_security_group.AppNsg.id
}

#Assiciate VM nics to LB address pool
resource "azurerm_network_interface_backend_address_pool_association" "AppVmNicToAddressPool" {
  count = 3

  network_interface_id    = azurerm_network_interface.AppVmNic[count.index].id
  ip_configuration_name   = "local"
  backend_address_pool_id = azurerm_lb_backend_address_pool.AppLbBackEndPool.id
  depends_on              = [azurerm_network_interface.AppVmNic]
}

#Create lb nat rule to allow ssh
resource "azurerm_lb_nat_rule" "AppLbNatRule" {
  count = 3

  resource_group_name            = azurerm_resource_group.rg.name
  loadbalancer_id                = azurerm_lb.AppLoadbalancer.id
  name                           = "SSH-LB-NAT-Rule-${count.index}"
  protocol                       = "Tcp"
  frontend_port                  = "6500${count.index}"
  backend_port                   = 22
  frontend_ip_configuration_name = "App-LB-Public-Ip"
  depends_on                     = [azurerm_network_interface.AppVmNic]
}

#Associate VM to lb nat rule
resource "azurerm_network_interface_nat_rule_association" "AppVmNicToLbNatRule" {
  count = 3

  network_interface_id  = azurerm_network_interface.AppVmNic[count.index].id
  ip_configuration_name = azurerm_network_interface.AppVmNic[count.index].ip_configuration[0].name
  nat_rule_id           = azurerm_lb_nat_rule.AppLbNatRule[count.index].id
  depends_on            = [azurerm_network_interface.AppVmNic]
}

#Create VMs for the frontend app
locals{
  CertPath = "c:/users/PCEG/.ssh/id_rsa.pub"
  // ProvisionerVars = { 
  //   ExternalIp = azurerm_network_interface.AppVmNic[count.index].private_ip_address,
  //   Port = 8080,
  //   PublicIp = azurerm_public_ip.AppPublicIp.ip_address,
  //   DpIp = azurerm_private_endpoint.DbServerPrivateEndpoint.private_service_connection.0.private_ip_address,
  //   OktaUrl = https://dev-91725987.okta.com,
  //   OktaId = 0oac29sg1MnlaSgsu5d6,
  //   OctaSec = tyM1Gtw1rGwXVscTZ1uTBjPj6ZzvazWVTehyuCex,
  //   DbPort = 5432,
  //   DbUser = var.AdminUserName"@"azurerm_postgresql_database.DB.name,
  //   DbName = azurerm_postgresql_database.DB.name,
  //   DbPass = data.azurerm_key_vault_secret.VMPass.value, 
  //   LogPath = /home/{var.AdminUserName/provision.log 
  // }
  
  // ProvisionerScript=<<-SCRIPT
  //   sudobash/home/var.AdminUserName/provision.shProvisionerVars.ExternalIpProvisionerVars.PortProvisionerVars.PublicIp \
  //     && ProvisionerVars.DpIpProvisionerVars.OktaUrlProvisionerVars.OktaIdProvisionerVars.OktaSec \
  //     && ProvisionerVars.DpPortProvisionerVars.DbUserProvisionerVars.NameProvisionerVars.Pass>ProvisionerVars.LogPath \
  // SCRIPT
  // }
}

resource "azurerm_linux_virtual_machine" "AppVm" {
  count = 3

  name                = "App-VM-${count.index}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = var.VmSize
  admin_username      = var.AdminUserName

  network_interface_ids = [
    azurerm_network_interface.AppVmNic[count.index].id,
  ]

  admin_ssh_key {
    username   = var.AdminUserName
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  provisioner "file" {
    source      = "../Provisioning/app_provision.sh"
    destination = "/home/${var.AdminUserName}/provision.sh"

    connection {
      type        = "ssh"
      agent       = false
      user        = var.AdminUserName
      host        = azurerm_public_ip.AppPublicIp.ip_address
      port        = "6500${count.index}"
      private_key = file("~/.ssh/id_rsa")
    }
  }

  provisioner "remote-exec" {
    # Parameters: VM IP , Port ,Public IP , Postgres Server IP , Okta Url  including https:# , Okta Id , Okta Code , DB Port , DB User , DB name , DB pass
    inline = [
      "sudo chmod +x /home/${var.AdminUserName}/provision.sh",
      "sudo bash /home/${var.AdminUserName}/provision.sh '${azurerm_network_interface.AppVmNic[count.index].private_ip_address}' '8080' '${azurerm_public_ip.AppPublicIp.ip_address}' '${azurerm_private_endpoint.DbServerPrivateEndpoint.private_service_connection.0.private_ip_address}' 'https://dev-91725987.okta.com' '0oac29sg1MnlaSgsu5d6' 'tyM1Gtw1rGwXVscTZ1uTBjPj6ZzvazWVTehyuCex' '5432' '${var.AdminUserName}@${azurerm_postgresql_server.DbServer.name}' '${azurerm_postgresql_database.DB.name}' '${data.azurerm_key_vault_secret.VMPass.value}' > '/home/${var.AdminUserName}/provision.log'" ,
    ]

    connection {
      type        = "ssh"
      agent       = false
      user        = var.AdminUserName
      host        = azurerm_public_ip.AppPublicIp.ip_address
      port        = "6500${count.index}"
      private_key = file("~/.ssh/id_rsa")
    }
  }
}


## Back End ##

#Creates subnet for the backend
resource "azurerm_subnet" "DbSubnet" {
  name                                           = "DB-Subnet"
  resource_group_name                            = azurerm_resource_group.rg.name
  virtual_network_name                           = azurerm_virtual_network.vnet.name
  address_prefixes                               = ["192.168.1.0/24"]
  service_endpoints                              = ["Microsoft.Sql"]
  enforce_private_link_endpoint_network_policies = true
}

#Creates NSG for the backend
resource "azurerm_network_security_group" "DbNsg" {
  name                = "DB-NSG"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}

#Associats backend subnet to its NSG
resource "azurerm_subnet_network_security_group_association" "DbNsgSubnet" {
  subnet_id                 = azurerm_subnet.DbSubnet.id
  network_security_group_id = azurerm_network_security_group.DbNsg.id
}

#Creates NSG rule for the backend - allow tcp 5432 from frontend subnet to backend subnet
resource "azurerm_network_security_rule" "PostgresNsgRule" {
  name                        = "Allow-Postgres-All"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.DbNsg.name

  priority  = 103
  direction = "Inbound"
  access    = "Allow"

  protocol                     = "Tcp"
  source_address_prefixes      = azurerm_subnet.AppSubnet.address_prefixes
  source_port_range            = "5432"
  destination_address_prefixes = azurerm_subnet.DbSubnet.address_prefixes
  destination_port_range       = "5432"
}


## Postgres server ##
resource "azurerm_postgresql_server" "DbServer" {
  name                = "weighttracker-postgers-server"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  administrator_login          = var.AdminUserName
  administrator_login_password = data.azurerm_key_vault_secret.VMPass.value

  sku_name   = "GP_Gen5_2"
  version    = "11"
  storage_mb = 5120

  ssl_enforcement_enabled = false
}

resource "azurerm_postgresql_database" "DB" {
  name                = "wighttracker_db"
  resource_group_name = azurerm_resource_group.rg.name

  server_name = azurerm_postgresql_server.DbServer.name
  charset     = "UTF8"
  collation   = "English_United States.1252"
}


resource "azurerm_postgresql_virtual_network_rule" "DbServerVnetConf" {
  name                = "Postgres-VNet-Rule"
  resource_group_name = azurerm_resource_group.rg.name

  server_name                          = azurerm_postgresql_server.DbServer.name
  subnet_id                            = azurerm_subnet.DbSubnet.id
  ignore_missing_vnet_service_endpoint = true
}


resource "azurerm_private_endpoint" "DbServerPrivateEndpoint" {
  name                = "Db-Server-Private-Endpoint"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  subnet_id = azurerm_subnet.DbSubnet.id

  private_service_connection {
    name                           = "Db-Server-Private-Service-Connection"
    private_connection_resource_id = azurerm_postgresql_server.DbServer.id
    subresource_names              = ["postgresqlServer"]
    is_manual_connection           = false
  }
}






### Jenkins ###
#Creates subnet for jenkins
resource "azurerm_subnet" "JenkinsSubnet" {
  name                 = "Jenkins-Subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["192.168.2.0/24"]
}

#Creates NSG for Jenkins
resource "azurerm_network_security_group" "JenkinsNsg" {
  name                = "Jenkins-NSG"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}

#Associats jenkins subnet to its NSG
resource "azurerm_subnet_network_security_group_association" "JenkinsNsgSubnet" {
  subnet_id                 = azurerm_subnet.JenkinsSubnet.id
  network_security_group_id = azurerm_network_security_group.JenkinsNsg.id
}

#Associate VM nics to NSG
resource "azurerm_network_interface_security_group_association" "JenkinsVmNicToNSG" {
  network_interface_id      = azurerm_network_interface.JenkinsVmNic.id
  network_security_group_id = azurerm_network_security_group.JenkinsNsg.id
}

#Creates NSG rule for jenkins - allow tcp 2020 from internet to frontend subnet
resource "azurerm_network_security_rule" "JenkinsNsgRule" {
  name                        = "Allow-Jenkins-All"
  resource_group_name         = azurerm_resource_group.rg.name
  priority                    = 204
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_address_prefix       = "Internet"
  source_port_range           = "*"
  destination_address_prefix  = "192.168.2.0/24"
  destination_port_range      = "8080"
  network_security_group_name = azurerm_network_security_group.JenkinsNsg.name
}

resource "azurerm_network_security_rule" "SshNsgRuleJenkins" {
  name                        = "Allow-SSH-All"
  resource_group_name         = azurerm_resource_group.rg.name
  priority                    = 211
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_address_prefix       = "Internet"
  source_port_range           = "*"
  destination_address_prefix  = "192.168.2.0/24"
  destination_port_range      = "22"
  network_security_group_name = azurerm_network_security_group.JenkinsNsg.name
}

#Create public ip for jenkins
resource "azurerm_public_ip" "JenkinsPublicIp" {
  name                = "Jenkins-Public-Ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "standard"
}

#VM Nic
resource "azurerm_network_interface" "JenkinsVmNic" {
  name                = "Jenkins-VM-Nic-Master"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  ip_configuration {
    name                          = "public"
    subnet_id                     = azurerm_subnet.JenkinsSubnet.id
    public_ip_address_id          = azurerm_public_ip.JenkinsPublicIp.id
    primary                       = "true"
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "JenkinsMaster" {
  name                = "Jenkins-VM-Master"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = var.VmSize
  admin_username      = var.AdminUserName

  network_interface_ids = [
    azurerm_network_interface.JenkinsVmNic.id,
  ]

  admin_ssh_key {
    username   = var.AdminUserName
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  provisioner "file" {
    source      = "../Provisioning/jenkins_provision.sh"
    destination = "/home/${var.AdminUserName}/jenkins_provision.sh"
    connection {
      type        = "ssh"
      agent       = false
      user        = var.AdminUserName
      host        = azurerm_public_ip.JenkinsPublicIp.ip_address
      port        = "22"
      private_key = file("~/.ssh/id_rsa")
    }
  }

  provisioner "remote-exec" {
  	inline = [
      "sudo add-apt-repository universe",
  	  "sudo chmod +x /home/${var.AdminUserName}/jenkins_provision.sh",
      "sudo bash /home/${var.AdminUserName}/jenkins_provision.sh -y"
  	]

    connection {
      type        = "ssh"
      agent       = false
      user        = var.AdminUserName
      host        = azurerm_public_ip.JenkinsPublicIp.ip_address
      port        = "22"
      private_key = file("~/.ssh/id_rsa")
    }
  }
}



                                                                            ### Slave ###


#VM Nic
resource "azurerm_network_interface" "JenkinsSlaveVmNic" {
  name                = "Jenkins-VM-Nic-Slave"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  ip_configuration {
    name                          = "local"
    subnet_id                     = azurerm_subnet.JenkinsSubnet.id
    primary                       = "true"
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "JenkinsSlave" {
  name                = "Jenkins-VM-Slave"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = var.VmSize
  
  admin_username      = var.AdminUserName
  disable_password_authentication = false
  admin_password = data.azurerm_key_vault_secret.VMPass.value
  custom_data = filebase64("../Provisioning/jenkins_agent_provision.txt")

  network_interface_ids = [
    azurerm_network_interface.JenkinsSlaveVmNic.id,
  ]

   admin_ssh_key {
    username   = var.AdminUserName
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

}
