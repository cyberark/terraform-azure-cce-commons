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

# Both Azure providers use the tenant being onboarded, not the default tenant of the Azure CLI login
provider "azurerm" {
  subscription_id = var.subscription_id
  tenant_id       = var.entra_id
  features {}
}

provider "azuread" {
  tenant_id = var.entra_id
}

provider "idsec" {
  # Configure with your Idira tenant credentials
  # See: https://registry.terraform.io/providers/cyberark/idsec/latest/docs
}

# Commons: Cloud Discovery shared resources, once per Microsoft Entra tenant
module "cce_azure_shared" {
  source   = "cyberark/cce-commons/azure"
  version  = "0.7.0"
  entra_id = var.entra_id

  cds = {
    enable = var.cloud_discovery_commons_enable
  }
}

# Entra: Cloud Discovery onboarding at Microsoft Entra tenant scope using shared_resources from Commons
module "cce_entra" {
  source   = "cyberark/cce-entra/azure"
  version  = "0.6.0"
  entra_id = var.entra_id
  cds = {
    enable           = var.cloud_discovery_entra_enable
    shared_resources = module.cce_azure_shared.cds
  }
}

# Partial onboarding: to onboard specific management groups or subscriptions instead of the whole
# Microsoft Entra tenant, set cloud_discovery_entra_enable = false and enable the modules below.

# Management Group: Cloud Discovery onboarding at management group scope using the same shared_resources
module "cce_management_group" {
  source              = "cyberark/cce-management-group/azure"
  version             = "0.6.0"
  entra_id            = var.entra_id
  management_group_id = var.management_group_id
  cds = {
    enable           = var.cloud_discovery_management_group_enable
    shared_resources = module.cce_azure_shared.cds
  }
}

# Subscription: Cloud Discovery onboarding at subscription scope using the same shared_resources.
# var.subscription_id is also the azurerm provider's subscription. To onboard another subscription,
# add a module block per subscription with its own subscription_id, subscription_name and enable flag.
module "cce_subscription" {
  source            = "cyberark/cce-subscription/azure"
  version           = "0.6.0"
  entra_id          = var.entra_id
  entra_tenant_name = var.entra_tenant_name
  subscription_id   = var.subscription_id
  subscription_name = var.subscription_name
  cds = {
    enable           = var.cloud_discovery_subscription_enable
    shared_resources = module.cce_azure_shared.cds
  }
}
