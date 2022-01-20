terraform {
  required_version = ">= 1.1.4"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "2.92.0"
    }
  }
}

# Configure the Azure Provider
provider "azurerm" {
  features {}
}

terraform {
  backend "azurerm" {
    resource_group_name  = "terraform"
    storage_account_name = "tebrielterraformstate"
    container_name       = "state"
    key                  = "github-dev.tfstate"
  }
}

resource "azurerm_resource_group" "github-dev" {
  name     = "github-dev"
  location = "East US"
}
