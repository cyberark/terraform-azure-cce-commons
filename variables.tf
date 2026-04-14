variable "entra_id" {
  description = "The Azure Entra ID"
  type        = string
}

variable "tenant_id" {
  description = "The Azure Tenant ID"
  type        = string
}

variable "identity_issuer" {
  description = "The identity issuer URL for federated credentials"
  type        = string
  default     = null
}

variable "identity_user_id" {
  description = "The identity user ID for federated credentials"
  type        = string
  default     = null
}

variable "identity_audience" {
  description = "The identity audience for federated credentials"
  type        = string
  default     = null
}

variable "identity_cloud_tenant_num" {
  description = "Optional cloud tenant number for SCA username (e.g. IDENTITY_SUFFIX from sca.sh). When set, commons SCA usernames match shell script."
  type        = string
  default     = null
}

variable "sca" {
  description = "Configuration for SCA service"
  type = object({
    enable = optional(bool, false)
    parameters = optional(object({
      sca_entra_onboarding        = optional(bool, false)
      sca_entra_app_id            = optional(string)
      sca_entra_custom_role_id    = optional(string)
      sca_entra_wif_username      = optional(string)
      sca_resource_app_id         = optional(string)
      sca_resource_custom_role_id = optional(string)
      sca_resource_wif_username   = optional(string)
    }), {})
  })
  default = { enable = false, parameters = {} }

  validation {
    condition = (
      var.sca.parameters.sca_entra_wif_username == null ||
      !can(regex(":\\*$", var.sca.parameters.sca_entra_wif_username))
    )
    error_message = "SCA Entra WIF username must follow the format 'repo:org/repo:ref:refs/heads/main' to ensure secure OIDC trust policy."
  }

  validation {
    condition = (
      var.sca.parameters.sca_resource_wif_username == null ||
      !can(regex(":\\*$", var.sca.parameters.sca_resource_wif_username))
    )
    error_message = "SCA Resource WIF username must follow the format 'repo:org/repo:ref:refs/heads/main' to ensure secure OIDC trust policy."
  }
}
