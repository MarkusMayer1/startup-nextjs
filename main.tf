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

variable "container_image_tag" {
  description = "The tag of the container image"
  type        = string
  default     = "latest"
}

resource "azurerm_resource_group" "resource_group" {
  name     = "devOps"
  location = "West Europe"
}

resource "azurerm_container_app_environment" "container_app_environment" {
  name                = "devOps"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
}

resource "azurerm_container_app" "container_app" {
  name                         = "startup-nextjs"
  resource_group_name          = azurerm_resource_group.resource_group.name
  container_app_environment_id = azurerm_container_app_environment.container_app_environment.id
  revision_mode                = "Multiple"

  template {
    container {
      name   = "startup-nextjs"
      image  = "markusmayer1/startup-nextjs:${var.container_image_tag}"
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

output "container_app_fqdn" {
  value = azurerm_container_app.container_app.latest_revision_fqdn
}
