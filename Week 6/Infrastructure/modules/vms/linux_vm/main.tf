locals { 
    nic_name_suffix = "NIC"
    nic_ip_configuration_name = "private"
    nic_ip_configuration_private_ip_address_allocation = "Dynamic"
    nic_primary = "true"
    vm_name = "VM"
    vm_os_disk_caching = "ReadWrite"
    vm_os_disk_storage_account_type = "Standard_LRS"
    vm_source_image_reference_publisher = "Canonical"
    vm_source_image_reference_offer = "UbuntuServer"
    vm_source_image_reference_sku = "18.04-LTS"
    vm_source_image_reference_version = "latest"
    vm_connection_type = "ssh"
    vm_connection_agent = "false"
    vm_connection_user = ""
    vm_connection_host = ""
    port_prefix = "6500"
}

#VM Nic
resource "azurerm_network_interface" "nic" {
  count = var.vm_count
  name                 = "${var.name}-${local.nic_name_suffix}-${count.index}"
  resource_group_name = var.rg_name
  location            = var.location

  ip_configuration {
    name                          = local.nic_ip_configuration_name
    subnet_id                     = var.nic_subnet_id
    public_ip_address_id          = var.public_ip_id
    private_ip_address_allocation = local.nic_ip_configuration_private_ip_address_allocation
    primary                       = local.nic_primary
  }
}

// data "azurerm_network_security_group" "nsg" {
//   name = var.nsg_name
//   resource_group_name = var.rg_name
// }

#Associate VM nic to NSG
resource "azurerm_network_interface_security_group_association" "nic_nsg_association" {
  count                     = var.vm_count
  network_interface_id      = azurerm_network_interface.nic[count.index].id
  network_security_group_id = var.nic_nsg_id
  // network_security_group_id = data.azurerm_network_security_group.nsg.id
}

<<<<<<< HEAD
#Associate VM to lb nat rule
resource "azurerm_network_interface_nat_rule_association" "nic_to_lb_nat_rule_association" {
  // count = var.lb_nat_rule_id[0] != "" ? var.vm_count : 0
  count = var.lb_nat_rule_count


  network_interface_id  = azurerm_network_interface.nic[count.index].id
  ip_configuration_name   =  azurerm_network_interface.nic[count.index].ip_configuration[0].name
  nat_rule_id           = var.lb_nat_rule_id[count.index]
  depends_on            = [azurerm_network_interface.nic]
}

#Create VMs
=======
#Create VMs for the frontend app
>>>>>>> parent of 23344ce (more fixes)
resource "azurerm_linux_virtual_machine" "vm" {
  count = var.vm_count
  name                = "${var.name}-${local.vm_name}-${count.index}"
  resource_group_name = var.rg_name
  location            = var.location
  size                = var.vm_size
  admin_username      = var.admin_username

  network_interface_ids = [
<<<<<<< HEAD
    azurerm_network_interface.nic[count.index].id
=======
    azurerm_network_interface.nic[count.index].id,
>>>>>>> parent of 23344ce (more fixes)
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = file(var.vm_public_ssh_key)
  }

  os_disk {
    caching              = local.vm_os_disk_caching
    storage_account_type = local.vm_os_disk_storage_account_type
  }

  source_image_reference {
    publisher = local.vm_source_image_reference_publisher
    offer     = local.vm_source_image_reference_offer
    sku       = local.vm_source_image_reference_sku
    version   = local.vm_source_image_reference_version
  }

  custom_data = filebase64(var.provision_custom_data_script_path)

  provisioner "file" {
    source      = var.provision_script_source
    destination = var.provision_script_destination

    connection {
      host        = var.vm_host_ip != "" ? var.vm_host_ip : azurerm_network_interface.nic[count.index].private_ip_address
      type        = local.vm_connection_type
      agent       = local.vm_connection_agent
      user        = var.admin_username
    //   host        = azurerm_public_ip.AppPublicIp.ip_address
      port        = "${local.port_prefix}${count.index}"
      private_key = file(var.vm_private_ssh_key)
    }
  }

  provisioner "remote-exec" {
    # Parameters: VM IP , Port ,Public IP , Postgres Server IP , Okta Url  including https:# , Okta Id , Okta Code , DB Port , DB User , DB name , DB pass
    inline = var.provision_script

    connection {
      host        = var.vm_host_ip != "" ? var.vm_host_ip : azurerm_network_interface.nic[count.index].private_ip_address
      type        = local.vm_connection_type
      agent       = local.vm_connection_agent
      user        = var.admin_username
    //   host        = azurerm_public_ip.AppPublicIp.ip_address
      port        = "${local.port_prefix}${count.index}"
      private_key = file(var.vm_private_ssh_key)
    }
  }
}