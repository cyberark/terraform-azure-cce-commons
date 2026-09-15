variable "entra_id" {
  description = "The Azure Entra ID"
  type        = string
}

variable "sca" {
  description = "Configuration for SCA service. parameters.add_permissions_to_manage_cluster enables optional AKS cluster RBAC; parameters.sca_resource_k8s_custom_role_id is created in commons when null and the flag is true, or pass an existing role definition id to reuse."
  type = object({
    enable = optional(bool, false)
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
  default = { enable = false, parameters = {} }
}
