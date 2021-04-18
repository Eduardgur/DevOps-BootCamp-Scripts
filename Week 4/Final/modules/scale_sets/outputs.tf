#Outputs the VMs admin password
output "AdminPass" {
    sensitive = true
    value = data.azurerm_key_vault_secret.VMPass.value
  }