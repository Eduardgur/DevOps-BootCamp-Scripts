#Azure storage blol as backend for saving state
terraform {
  backend "azurerm" {
    resource_group_name  = "TFState"
    storage_account_name = "wtterratest"
    container_name       = "seek5state"
    key                  = "prod.terraform.tfstate"
  }
}