terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
  }
}

variable "azure_subscription_id" {
  type = string
}

provider "azurerm" {
  features {}

  subscription_id = var.azure_subscription_id
}

resource "azurerm_resource_group" "rg" {
  name     = "devOps"
  location = "West Europe"
}

resource "azurerm_container_app_environment" "env" {
  name                = "devOps"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_container_app" "app" {
  name                         = "startup-nextjs"
  resource_group_name          = azurerm_resource_group.rg.name
  container_app_environment_id = azurerm_container_app_environment.env.id
  revision_mode                = "Single"

  template {
    container {
      name   = "startup-nextjs"
      image  = "markusmayer1/startup-nextjs:latest"
      cpu    = 0.25
      memory = "0.5Gi"
    }
  }

  ingress {
    external_enabled = true
    target_port      = 3000

    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }
}
