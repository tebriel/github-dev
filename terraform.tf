terraform {
  required_version = ">= 1.1.4"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "2.92.0"
    }
  }

  cloud {
    organization = "tebriel"
    workspaces {
      name = "github-dev"
    }
  }
}

# Configure the Azure Provider
provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "github-dev" {
  name     = "github-dev"
  location = "East US"
}
