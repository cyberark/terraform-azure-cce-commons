variable "entra_id" {
  description = "The Azure Entra ID (tenant ID)"
  type        = string
}

variable "subscription_id" {
  description = "Azure subscription ID for the provider (must have permissions to create apps and role definitions)"
  type        = string
}

variable "sca" {
  description = "SCA configuration"
  type = object({
    enable = optional(bool, true)
    parameters = optional(object({
      sca_entra_onboarding              = optional(bool, true)
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
      sca_entra_onboarding              = true
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
