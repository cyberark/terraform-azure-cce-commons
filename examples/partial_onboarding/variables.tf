variable "entra_id" {
  description = "The Azure Entra ID (tenant ID)"
  type        = string
}

variable "subscription_id" {
  description = "Azure subscription ID (for provider and Subscription module)"
  type        = string
}

variable "identity_cloud_tenant_num" {
  description = "Optional cloud tenant number for SCA WIF usernames"
  type        = string
  default     = null
}

variable "sca" {
  description = "SCA configuration for Commons (and enable/disable for MG and Subscription)"
  type = object({
    enable = optional(bool, true)
    parameters = optional(object({
      sca_entra_onboarding        = optional(bool, true)
      sca_entra_app_id            = optional(string)
      sca_entra_custom_role_id    = optional(string)
      sca_entra_wif_username      = optional(string)
      sca_resource_app_id         = optional(string)
      sca_resource_custom_role_id = optional(string)
      sca_resource_wif_username   = optional(string)
    }), {})
  })
  default = {
    enable = true
    parameters = {
      sca_entra_onboarding        = true
      sca_entra_app_id            = null
      sca_entra_custom_role_id    = null
      sca_entra_wif_username      = null
      sca_resource_app_id         = null
      sca_resource_custom_role_id = null
      sca_resource_wif_username   = null
    }
  }
}
