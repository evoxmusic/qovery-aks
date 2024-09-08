terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.1.0"
    }
  }
}

resource "random_pet" "prefix" {}

provider "azurerm" {
  subscription_id = var.subscription_id
  features {}
}

resource "azurerm_resource_group" "production" {
  name     = "production-rg"
  location = "West US 2"
}

resource "azurerm_kubernetes_cluster" "production" {
  name                = "production"
  location            = azurerm_resource_group.production.location
  resource_group_name = azurerm_resource_group.production.name
  dns_prefix          = "production-aks-k8s"
  kubernetes_version  = var.kubernetes_version

  default_node_pool {
    name                 = "production"
    vm_size              = "Standard_D2_v2"
    auto_scaling_enabled = true
    min_count            = 3
    max_count            = 5
    os_disk_size_gb      = 30
    temporary_name_for_rotation = "productionr"
  }

  service_principal {
    client_id     = var.app_id
    client_secret = var.password
  }

  role_based_access_control_enabled = true
}

resource "azurerm_container_registry" "production" {
  location            = azurerm_resource_group.production.location
  name = replace("production-${random_pet.prefix.id}-acr", "-", "")
  resource_group_name = azurerm_resource_group.production.name
  sku                 = "Standard"
}