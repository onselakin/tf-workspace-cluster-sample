terraform {
  required_providers {
    databricks = {
      source  = "databricks/databricks"
      version = "1.0.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0.0"
    }
    random = "~> 3.3.2"
  }
}

provider "azurerm" {
  features {}
}

resource "random_string" "naming" {
  special = false
  upper   = false
  length  = 6
}

data "azurerm_client_config" "current" {}

locals {
  prefix = "databricksdemo${random_string.naming.result}"
}

resource "azurerm_resource_group" "this" {
  name     = "${local.prefix}-rg"
  location = "westeurope"
}

resource "azurerm_databricks_workspace" "this" {
  name                        = "${local.prefix}-workspace"
  resource_group_name         = azurerm_resource_group.this.name
  location                    = azurerm_resource_group.this.location
  sku                         = "premium"
  managed_resource_group_name = "${local.prefix}-workspace-rg"
}

# Create a configured provider for cluster creation
provider "databricks" {
  alias = "created_workspace"
  host  = azurerm_databricks_workspace.this.workspace_url
}

module "cluster" {
  source     = "./modules/cluster"
  depends_on = [azurerm_databricks_workspace.this]

  # Pass the provider config to the module
  providers = {
    databricks = databricks.created_workspace
  }
}