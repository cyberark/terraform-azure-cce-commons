terraform {
  required_version = ">= 1.8.5"
}

module "sca" {
  source                    = "./services_modules/sca"
  count                     = var.sca.enable ? 1 : 0
  entra_id                  = var.entra_id
  tenant_id                 = var.tenant_id
  identity_issuer           = var.identity_issuer
  identity_user_id          = var.identity_user_id
  identity_audience         = var.identity_audience
  identity_cloud_tenant_num = var.identity_cloud_tenant_num
  parameters                = var.sca.parameters
}
