locals { 
    nic_name_suffix = "NIC"
    nic_ip_configuration_name = ""
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
  count = local.vm_count
  name                 = "${var.name}-${local.nic_name_suffix}"
  resource_group_name = local.rg_name
  location            = local.location

  ip_configuration {
    name                          = local.nic_ip_configuration_name
    subnet_id                     = var.nic_subnet_id
    private_ip_address_allocation = local.nic_ip_configuration_private_ip_address_allocation
    primary                       = local.nic_primary
  }
}

#Associate VM nic to NSG
resource "azurerm_network_interface_security_group_association" "nic_nsg_association" {
  count = local.vm_count
  network_interface_id      = azurerm_network_interface.nic[count.index].id
  network_security_group_id = var.nic_nsg_id
}

#Create VMs for the frontend app
resource "azurerm_linux_virtual_machine" "AppVm" {
  count = local.vm_count
  name                = "${local.name}-${local.vm_name}-${count.index}"
  resource_group_name = local.rg_name
  location            = local.location
  size                = var.vm_size
  admin_username      = var.vm_admin_username

  network_interface_ids = [
    azurerm_network_interface.nic[count.index].id,
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = file(local.vm_public_ssh_key)
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
    source      = local.provision_script_source
    destination = local.provision_script_destination

    connection {
      type        = local.vm_connection_type
      agent       = local.vm_connection_agent
      user        = var.vm_admin_username
    //   host        = azurerm_public_ip.AppPublicIp.ip_address
      port        = "${local.port_prefix}${count.index}"
      private_key = file(var.vm_private_ssh_key)
    }
  }

  provisioner "remote-exec" {
    # Parameters: VM IP , Port ,Public IP , Postgres Server IP , Okta Url  including https:# , Okta Id , Okta Code , DB Port , DB User , DB name , DB pass
    inline = var.provision_script

    connection {
      type        = local.vm_connection_type
      agent       = local.vm_connection_agent
      user        = var.vm_admin_username
    //   host        = azurerm_public_ip.AppPublicIp.ip_address
      port        = "${local.port_prefix}${count.index}"
      private_key = file(var.vm_private_ssh_key)
    }
  }
}