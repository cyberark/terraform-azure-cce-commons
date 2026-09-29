variable "entra_id" {
  description = "The Microsoft Entra tenant ID (tenant ID)."
  type        = string
}

variable "entra_tenant_name" {
  description = "The Microsoft Entra tenant name (for subscription module)."
  type        = string
}

variable "subscription_id" {
  description = "The Azure subscription ID (for provider and subscription module)."
  type        = string
}

variable "subscription_name" {
  description = "The Azure subscription display name (for subscription module)."
  type        = string
}

variable "management_group_id" {
  description = "The Azure management group ID."
  type        = string
}

variable "sca" {
  description = "The SCA configuration for Commons (and enable/disable for management group and subscription)."
  type = object({
    enable = optional(bool, true)
    parameters = optional(object({
      sca_entra_onboarding              = optional(bool, false)
      sca_entra_app_id                  = optional(string)
      sca_entra_custom_role_id          = optional(string)
      sca_entra_wif_username            = optional(string)
      sca_resource_app_id               = optional(string)
      sca_resource_custom_role_id       = optional(string)
      sca_resource_wif_username         = optional(string)
      add_permissions_to_manage_cluster = optional(bool, false)
      sca_resource_k8s_custom_role_id   = optional(string)
    }), {})
  })
  default = {
    enable = true
    parameters = {
      sca_entra_onboarding              = false
      sca_entra_app_id                  = null
      sca_entra_custom_role_id          = null
      sca_entra_wif_username            = null
      sca_resource_app_id               = null
      sca_resource_custom_role_id       = null
      sca_resource_wif_username         = null
      add_permissions_to_manage_cluster = false
      sca_resource_k8s_custom_role_id   = null
    }
  }
}
