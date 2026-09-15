variable "entra_id" {
  description = "The Azure Entra ID"
  type        = string
}

variable "tenant_id" {
  description = "The tenant ID from idsec provider"
  type        = string
}

variable "identity_issuer" {
  description = "Identity issuer for federated credentials"
  type        = string
}

variable "identity_audience" {
  description = "Identity audience for federated credentials"
  type        = string
}

variable "parameters" {
  description = "SCA service parameters. When an ID/username is null, commons creates it; otherwise reuses and passes through. Entra and Resource params must each be either all null (create) or all set (reuse). add_permissions_to_manage_cluster enables AKS-related custom role creation and assignment; sca_resource_k8s_custom_role_id is created when null and the flag is true."
  type = object({
    sca_entra_onboarding              = optional(bool, false)
    sca_entra_app_id                  = optional(string)
    sca_entra_custom_role_id          = optional(string)
    sca_entra_wif_username            = optional(string)
    sca_resource_app_id               = optional(string)
    sca_resource_custom_role_id       = optional(string)
    sca_resource_wif_username         = optional(string)
    add_permissions_to_manage_cluster = optional(bool, false)
    sca_resource_k8s_custom_role_id   = optional(string)
  })
  default = {}

  validation {
    condition = (
      (var.parameters.sca_entra_app_id == null && var.parameters.sca_entra_custom_role_id == null && var.parameters.sca_entra_wif_username == null) ||
      (var.parameters.sca_entra_app_id != null && var.parameters.sca_entra_custom_role_id != null && var.parameters.sca_entra_wif_username != null)
    )
    error_message = "SCA Entra params (sca_entra_app_id, sca_entra_custom_role_id, sca_entra_wif_username) must be either all null (commons will create) or all set (commons will reuse). No mixed values."
  }

  validation {
    condition = (
      (var.parameters.sca_resource_app_id == null && var.parameters.sca_resource_custom_role_id == null && var.parameters.sca_resource_wif_username == null) ||
      (var.parameters.sca_resource_app_id != null && var.parameters.sca_resource_custom_role_id != null && var.parameters.sca_resource_wif_username != null)
    )
    error_message = "SCA Resource params (sca_resource_app_id, sca_resource_custom_role_id, sca_resource_wif_username) must be either all null (commons will create) or all set (commons will reuse). No mixed values."
  }

  validation {
    condition = try(var.parameters.sca_entra_wif_username, null) == null || (
      can(regex("^SCA_ISOLATED_SYSTEM_USER_FOR_AZURE_[A-F0-9]{12}_[A-F0-9]{12}_ENTRA$", var.parameters.sca_entra_wif_username)) ||
      can(regex("^SCA_ISOLATED_SYSTEM_USER_FOR_AZURE_[A-F0-9]{12}_[A-F0-9]{12}_ENTRA@CYBERARK\\.CLOUD\\.[0-9]+$", var.parameters.sca_entra_wif_username))
    )
    error_message = "SCA Entra WIF username must follow the format 'SCA_ISOLATED_SYSTEM_USER_FOR_AZURE_<TENANT_HEX>_<ENTRA_HEX>_ENTRA' to ensure secure OIDC trust policy."
  }

  validation {
    condition = try(var.parameters.sca_resource_wif_username, null) == null || (
      can(regex("^SCA_ISOLATED_SYSTEM_USER_FOR_AZURE_[A-F0-9]{12}_[A-F0-9]{12}_RESOURCE$", var.parameters.sca_resource_wif_username)) ||
      can(regex("^SCA_ISOLATED_SYSTEM_USER_FOR_AZURE_[A-F0-9]{12}_[A-F0-9]{12}_RESOURCE@CYBERARK\\.CLOUD\\.[0-9]+$", var.parameters.sca_resource_wif_username))
    )
    error_message = "SCA Resource WIF username must follow the format 'SCA_ISOLATED_SYSTEM_USER_FOR_AZURE_<TENANT_HEX>_<ENTRA_HEX>_RESOURCE' to ensure secure OIDC trust policy."
  }
}
