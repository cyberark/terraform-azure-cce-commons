variable "entra_id" {
  description = "The Azure Entra ID (tenant ID)"
  type        = string
}

variable "entra_tenant_name" {
  description = "The Azure Entra tenant name (for Subscription module)"
  type        = string
}

variable "subscription_id" {
  description = "Azure subscription ID (for provider and Subscription module)"
  type        = string
}

variable "subscription_name" {
  description = "Azure subscription display name (for Subscription module)"
  type        = string
}

variable "management_group_id" {
  description = "The Azure Management Group ID to onboard for SCA"
  type        = string
}

variable "sca" {
  description = "SCA configuration for Commons (and enable/disable for MG and Subscription)"
  type = object({
    enable = optional(bool, true)
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
  default = {
    enable = true
    parameters = {
      sca_entra_onboarding        = false
      sca_entra_app_id            = null
      sca_entra_custom_role_id    = null
      sca_entra_wif_username      = null
      sca_resource_app_id         = null
      sca_resource_custom_role_id = null
      sca_resource_wif_username   = null
    }
  }
}
