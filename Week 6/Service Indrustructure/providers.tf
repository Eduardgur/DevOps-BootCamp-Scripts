terraform {
  required_version = ">= 0.14.9 "

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.56.0"
    }
  }
}


#Azure provider for all resources
provider "azurerm" {
  features {}


}
