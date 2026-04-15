variable "entra_id" {
  description = "The Azure Entra ID"
  type        = string
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
}
