terraform {
  required_version = ">= 1.8.5"
  required_providers {
    idsec = {
      source  = "cyberark/idsec"
      version = "~> 0.2.1"
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
  # Configure with your CyberArk tenant credentials
  # See: https://registry.terraform.io/providers/cyberark/idsec/latest/docs
}

# Commons: SCA shared resources (Entra app, Resource app, roles, etc.)
module "cce_azure_shared" {
  source   = "cyberark/cce-commons/azure"
  version  = "0.1.0"
  entra_id = var.entra_id

  sca = {
    enable = var.sca.enable
    parameters = {
      sca_entra_onboarding        = var.sca.parameters.sca_entra_onboarding
      sca_entra_app_id            = var.sca.parameters.sca_entra_app_id
      sca_entra_custom_role_id    = var.sca.parameters.sca_entra_custom_role_id
      sca_entra_wif_username      = var.sca.parameters.sca_entra_wif_username
      sca_resource_app_id         = var.sca.parameters.sca_resource_app_id
      sca_resource_custom_role_id = var.sca.parameters.sca_resource_custom_role_id
      sca_resource_wif_username   = var.sca.parameters.sca_resource_wif_username
    }
  }
}

# Management Group: partial SCA onboarding using shared_resources from Commons
module "cce_management_group" {
  source              = "cyberark/cce-management-group/azure"
  version             = "0.1.0"
  entra_id            = var.entra_id
  management_group_id = var.management_group_id
  sca = {
    enable           = var.sca.enable
    shared_resources = module.cce_azure_shared.sca
  }
}

# Subscription: partial SCA onboarding using shared_resources from Commons
module "cce_subscription" {
  source            = "cyberark/cce-subscription/azure"
  version           = "0.1.0"
  entra_id          = var.entra_id
  entra_tenant_name = var.entra_tenant_name
  subscription_id   = var.subscription_id
  subscription_name = var.subscription_name
  sia               = { enable = false }
  sca = {
    enable           = var.sca.enable
    shared_resources = module.cce_azure_shared.sca
  }
}
