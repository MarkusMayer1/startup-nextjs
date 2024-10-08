terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
  }

  backend "azurerm" {
      resource_group_name  = "devOpsMain"
      storage_account_name = "startupnextjstfstate"
      container_name       = "startupnextjstfstate"
      key                  = "terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "startup_nextjs" {
  name     = "devOps"
  location = "West Europe"
}

resource "azurerm_container_app_environment" "startup_nextjs" {
  name                = "devOps"
  location            = azurerm_resource_group.startup_nextjs.location
  resource_group_name = azurerm_resource_group.startup_nextjs.name
}

resource "azurerm_container_app" "startup_nextjs" {
  name                         = "startup-nextjs"
  resource_group_name          = azurerm_resource_group.startup_nextjs.name
  container_app_environment_id = azurerm_container_app_environment.startup_nextjs.id
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
