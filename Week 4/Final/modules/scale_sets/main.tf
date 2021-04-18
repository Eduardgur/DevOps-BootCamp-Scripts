data "azurerm_key_vault" "Vault" {
  name                = var.vault_name
  resource_group_name =  var.vault_group_name
}

data "azurerm_key_vault_secret" "VMPass" {
  name = "VmPass"
  key_vault_id = data.azurerm_key_vault.Vault.id
}


# Creates a new windows scaleset for the frontend
resource "azurerm_windows_virtual_machine_scale_set" "AppVmScaleSet" {
  name                = "App-Vm-Scale-Set"
  resource_group_name = var.resource_group_name
  location            = var.resource_group_location

  sku                  = var.windows_vmss_size
  instances            = var.windows_vmss_instances_count
  computer_name_prefix = "App-VM"

  admin_username = var.vmss_admin_username
  admin_password = data.azurerm_key_vault_secret.VMPass.value

  upgrade_mode    = "Automatic"
  health_probe_id = var.windows_vmss_healthprobe_id

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = var.windows_vmss_image_sku
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
      subnet_id                              = var.windows_vmss_subnet_id
      load_balancer_backend_address_pool_ids = var.windows_vmss_lb_backend_pool_ids
    }
  }
  winrm_listener {
    protocol = "Http"
  }
}

# Creates a new linux scaleset for the backend
resource "azurerm_linux_virtual_machine_scale_set" "DbVmScaleSet" {
  name                = "Db-Vm-Scale-Set"
  resource_group_name = var.resource_group_name
  location            = var.resource_group_location

  sku                  = var.linux_vmss_size
  instances            = var.linux_vmss_instances_count
  computer_name_prefix = "Db-VM"

  admin_username                  = var.vmss_admin_username
  admin_password                  = data.azurerm_key_vault_secret.VMPass.value
  disable_password_authentication = "false"

  upgrade_mode    = "Automatic"
  health_probe_id = var.linux_vmss_healthprobe_id

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = var.linux_vmss_image_sku
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
      subnet_id                              = var.linux_vmss_subnet_id
      load_balancer_backend_address_pool_ids = var.linux_vmss_lb_backend_pool_ids
    }

  }
}
