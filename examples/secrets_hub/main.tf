terraform {
  required_version = ">= 1.8.5"
  required_providers {
    idsec = {
      source  = "cyberark/idsec"
      version = "0.12.1"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  subscription_id = var.subscription_id
  features {}
}

provider "azuread" {}

provider "idsec" {
  # Configure with your Idira tenant credentials
  # See: https://registry.terraform.io/providers/cyberark/idsec/latest/docs
}

# Commons: Create the shared Secrets Hub identity (app, service principal, federated credential, custom role)
module "cce_azure_shared" {
  source      = "cyberark/cce-commons/azure"
  version     = "0.8.2"
  entra_id    = var.entra_id
  secrets_hub = { enable = true }
}

# Entra: Use the Commons output to assign the roles at the root management group and register Secrets Hub in CCE
module "cce_entra" {
  source   = "cyberark/cce-entra/azure"
  version  = "0.7.0"
  entra_id = var.entra_id
  secrets_hub = {
    enable           = true
    shared_resources = module.cce_azure_shared.secrets_hub
  }
}
