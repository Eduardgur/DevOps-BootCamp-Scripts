#Azure storage blob as backend for saving state
terraform {
  backend "azurerm" {
    // client_id = ""
    // subsription_id = ""
    // tenant_id = ""
    // client secret = ""

    resource_group_name  = "TFState"
    storage_account_name = "wtstatestore"
    container_name       = "week6state"
    key                  = "stage.terraform.tfservicestate"
  }
}