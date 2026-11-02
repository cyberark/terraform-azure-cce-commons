terraform {
  required_version = ">= 1.8.5"
  required_providers {
    idsec = {
      source  = "cyberark/idsec"
      version = "0.12.1"
    }
  }
}

# Fetch workload identity federation data from idsec provider
data "idsec_cce_azure_identity_params" "get_wif_data" {}

locals {
  sca_wif_data         = try(data.idsec_cce_azure_identity_params.get_wif_data.identity_params["sca"], null)
  secrets_hub_wif_data = try(data.idsec_cce_azure_identity_params.get_wif_data.identity_params["secrets_hub"], null)
  cds_wif_data         = try(data.idsec_cce_azure_identity_params.get_wif_data.identity_params["cds"], null)
  tenant_id            = data.idsec_cce_azure_identity_params.get_wif_data.tenant_id
}

module "sca" {
  source            = "./modules/sca"
  count             = var.sca.enable ? 1 : 0
  entra_id          = var.entra_id
  tenant_id         = local.tenant_id
  identity_issuer   = try(local.sca_wif_data["identity_app_issuer"], "")
  identity_audience = try(local.sca_wif_data["identity_app_audience"], "")
  parameters        = var.sca.parameters
}

module "secrets_hub" {
  source            = "./modules/secrets_hub"
  count             = var.secrets_hub.enable ? 1 : 0
  entra_id          = var.entra_id
  tenant_id         = local.tenant_id
  identity_issuer   = try(local.secrets_hub_wif_data["identity_app_issuer"], null)
  identity_audience = try(local.secrets_hub_wif_data["identity_app_audience"], null)
}

module "cds" {
  source            = "./modules/cds"
  count             = var.cds.enable ? 1 : 0
  entra_id          = var.entra_id
  tenant_id         = local.tenant_id
  identity_issuer   = try(local.cds_wif_data["identity_app_issuer"], "")
  identity_audience = try(local.cds_wif_data["identity_app_audience"], "")
}
